use std::collections::HashSet;
use chrono::{DateTime, Duration, Utc};
use rrule::RRuleResult;
use serde::Deserialize;
use uuid::Uuid;
use crate::{
    api::error::ApiError,
    models::{
        recurring_event::{NewRecurringEvent, RecurringCalendarEvent, RecurringEvent, UpdatedRecurringEvent},
        recurring_event_exception::{ExceptionType, NewRecurringEventException, RecurringEventException},
    }, repositories::Repositories
};

/// The query params for querying events.
#[derive(Deserialize)]
pub struct EventsQuery {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>
}

/// Handles business logic for recurring events routes.
#[derive(Clone, Debug)]
pub struct RecurringEventsService {
    repositories: Repositories
}

impl RecurringEventsService {
    pub fn new(repositories: Repositories) -> Self {
        Self { repositories }
    }

    pub async fn create_events(&self, user_id: Uuid, mut events: Vec<NewRecurringEvent>) -> Result<(), ApiError> {
        // HACK: frontend is unable to set start/end datetimes in the rrule, so we must ensure they're set here
        for event in &mut events {
            event.rrule.set_start(event.recurrence_start);
            event.rrule.set_end(event.recurrence_end);
        }

        // Collect group IDs for authorization check
        let group_ids: Vec<_> = events.iter().map(|e| e.group_id).collect();

        // Verify all groups are authorized
        let all_groups_authorized = self.repositories
            .recurring_events
            .validate_group_ownership(user_id, &group_ids)
            .await
            .map_err(ApiError::from)?;

        if !all_groups_authorized {
            return Err(ApiError::Forbidden);
        }

        self.repositories
            .recurring_events
            .bulk_create_events(&events, user_id)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    pub async fn get_events(&self, user_id: Uuid, params: EventsQuery) -> Result<Vec<RecurringCalendarEvent>, ApiError> {
        // Fetch active recurring events within start/end dates
        let recurring_events = self.repositories
            .recurring_events
            .fetch_active_events_in_period(user_id, params.start, params.end)
            .await
            .map_err(ApiError::from)?;

        tracing::trace!("Obtained {} active recurring events", recurring_events.len());

        // Generate actual event instances
        let mut events_and_instances: Vec<_> = recurring_events
            .into_iter()
            .map(|event| {
                let instances = event.rrule.all_within_period(params.start, params.end);
                tracing::trace!(
                    "Generated {} instances for event {} for {} - {}",
                    instances.dates.len(), event.id, params.start, params.end
                );
                (event, instances)
            })
            .collect();

        // Get exceptions within start/end dates
        let mut event_exceptions = {
            let event_ids: Vec<_> = events_and_instances
                .iter()
                .map(|(e, _)| e.id)
                .collect();

            self.repositories
                .recurring_events
                .fetch_exceptions_for_events(&event_ids)
                .await
                .map_err(ApiError::from)?
        };

        tracing::trace!("Found {} event exceptions", event_exceptions.len());

        // Resolve events' instances and exceptions
        let mut instances_with_group_ids = Vec::new();
        for (event, instances) in &mut events_and_instances {
            let calendar_events = self.process_event_instances_and_exceptions(
                event,
                instances,
                &mut event_exceptions
            );
            instances_with_group_ids.push((event.group_id, calendar_events));
        }

        // Don't query for groups whose events have 0 instances
        instances_with_group_ids.retain(|(_, i)| !i.is_empty());
        tracing::trace!(
            "After resolving exceptions and removing 0-instance events, retained {} events",
            instances_with_group_ids.len()
        );

        // Get group data for remaining instances
        let group_ids: Vec<_> = instances_with_group_ids
            .iter()
            .filter_map(|(g, _)| *g)
            .collect::<HashSet<_>>()
            .into_iter()
            .collect();
        let groups = self.repositories
            .recurring_events
            .fetch_groups_by_ids(&group_ids)
            .await
            .map_err(ApiError::from)?;

        // Fill in group data for instances
        for (group_id, events) in &mut instances_with_group_ids {
            if let Some(group) = groups.iter().find(|&g| Some(g.id) == *group_id) {
                for event in events {
                    event.group = Some(group.clone());
                }
            }
        }

        // Concatenate all events and return
        let events: Vec<_> = instances_with_group_ids
            .into_iter()
            .flat_map(|(_, events)| events)
            .collect();

        tracing::trace!("Returning {} recurring event instances", events.len());

        Ok(events)
    }

    pub async fn update_event(&self, user_id: Uuid, updated_event: UpdatedRecurringEvent) -> Result<(), ApiError> {
        let is_authorized = self.repositories
            .recurring_events
            .verify_event_ownership(updated_event.id, user_id)
            .await
            .map_err(ApiError::from)?;

        if !is_authorized {
            return Err(ApiError::Forbidden);
        }

        self.repositories
            .recurring_events
            .update_event(updated_event)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    pub async fn delete_event(&self, user_id: Uuid, event_id: Uuid) -> Result<(), ApiError> {
        let is_authorized = self.repositories
            .recurring_events
            .verify_event_ownership_via_group(event_id, user_id)
            .await
            .map_err(ApiError::from)?;

        if !is_authorized {
            return Err(ApiError::Forbidden);
        }

        self.repositories
            .recurring_events
            .delete_event(event_id)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    pub async fn create_event_exception(
        &self,
        user_id: Uuid,
        exception: NewRecurringEventException
    ) -> Result<(), ApiError> {
        let user_authorized = self.repositories
            .recurring_events
            .verify_exception_event_ownership(exception.recurring_event_id, user_id)
            .await
            .map_err(ApiError::from)?;

        if !user_authorized {
            return Err(ApiError::Forbidden);
        }

        match self.repositories
            .recurring_events.create_event_exception(exception).await {
            Ok(_) => Ok(()),
            Err(sqlx::Error::Database(db_err)) if db_err.constraint() == Some("unique_exception_per_instance") => {
                Err(ApiError::unprocessable_entity(vec![("exception_date", "There's already an exception on this exception date")]))
            },
            Err(err) => Err(ApiError::from(err))
        }
    }

    pub async fn update_event_exception(
        &self,
        user_id: Uuid,
        exception: RecurringEventException
    ) -> Result<(), ApiError> {
        let user_authorized = self.repositories
            .recurring_events
            .verify_exception_event_ownership(exception.recurring_event_id, user_id)
            .await
            .map_err(ApiError::from)?;

        if !user_authorized {
            return Err(ApiError::Forbidden);
        }

        self.repositories
            .recurring_events
            .update_event_exception(exception)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    /// Process event instances and exceptions to generate calendar events
    fn process_event_instances_and_exceptions(
        &self,
        event: &RecurringEvent,
        instances: &mut RRuleResult,
        event_exceptions: &mut Vec<RecurringEventException>
    ) -> Vec<RecurringCalendarEvent> {
        // Extract exceptions for this event
        let relevant_exceptions: Vec<_> = event_exceptions
            .extract_if(.., |exception| {
                if exception.recurring_event_id == event.id {
                    return instances.dates
                        .iter()
                        .any(|d| d.to_utc() == exception.exception_date);
                }
                false
            })
            .collect();

        // Delete all "cancelled" instances
        instances.dates.retain(|date| {
            !relevant_exceptions
                .iter()
                .any(|e| e.exception_type == ExceptionType::Cancelled && e.exception_date == date.to_utc())
        });

        // Create the actual calendar events
        let mut calendar_events: Vec<_> = instances.dates
            .iter()
            .map(|date| RecurringCalendarEvent {
                recurring_event_id: event.id,
                title: event.title.clone(),
                description: event.description.clone(),
                location: event.location.clone(),
                start_time: date.to_utc(),
                end_time: date.to_utc() + Duration::seconds(event.event_duration_seconds.0.into()),
                exception_id: None,
                group: None
            })
            .collect();

        // Replace any "modified" exceptions' metadata
        for exception in relevant_exceptions {
            if let ExceptionType::Modified = exception.exception_type {
                if let Some(event) = calendar_events
                    .iter_mut()
                    .find(|e| e.start_time == exception.exception_date)
                {
                    // **NOTE**: if more modifiable metadata is added to recurring events, they should be replaced here as well
                    if let Some(modified_title) = exception.modified_title { event.title = modified_title; }
                    if let Some(modified_description) = exception.modified_description { event.description = modified_description; }
                    if let Some(modified_location) = exception.modified_location { event.location = modified_location; }
                    if let Some(modified_start) = exception.modified_start_time { event.start_time = modified_start; }
                    if let Some(modified_end) = exception.modified_end_time { event.end_time = modified_end; }
                    event.exception_id = Some(exception.id);
                }
            }
        }

        calendar_events
    }
}