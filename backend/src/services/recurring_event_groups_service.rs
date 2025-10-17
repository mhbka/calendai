use std::collections::HashMap;
use uuid::Uuid;
use serde::Serialize;
use crate::{
    api::error::ApiError,
    models::{
        recurring_event::RecurringEvent,
        recurring_event_group::{NewRecurringEventGroup, RecurringEventGroup, UpdatedRecurringEventGroup}
    }, repositories::Repositories
};

/// Used for bulk creating events, optionally under a group.
#[derive(serde::Deserialize)]
pub struct GroupWithEvents {
    pub recurring_events: Vec<RecurringEvent>,
    pub recurring_event_group: Option<NewRecurringEventGroup>
}

/// The response for a group (includes the number of events under the group).
#[derive(Serialize)]
pub struct RecurringEventGroupResponse {
    #[serde(flatten)]
    pub group: RecurringEventGroup,
    #[serde(rename(serialize = "recurringEvents"))]
    pub recurring_events: usize
}

/// Service for recurring event groups.
#[derive(Clone, Debug)]
pub struct RecurringEventGroupsService {
    repositories: Repositories,
}

impl RecurringEventGroupsService {
    pub fn new(repositories: Repositories) -> Self {
        Self { repositories }
    }

    pub async fn fetch_all_groups(&self, user_id: Uuid) -> Result<Vec<RecurringEventGroupResponse>, ApiError> {
        let groups_with_counts = self.repositories
            .recurring_event_groups
            .fetch_all_groups_with_counts(user_id)
            .await
            .map_err(ApiError::from)?;

        let mut response: Vec<RecurringEventGroupResponse> = groups_with_counts
            .into_iter()
            .map(|group_count| RecurringEventGroupResponse {
                group: group_count.group,
                recurring_events: group_count.event_count,
            })
            .collect();

        let groupless_event_count = self.repositories
            .recurring_event_groups
            .fetch_ungrouped_event_count(user_id)
            .await
            .map_err(ApiError::from)?;

        let ungrouped_group = RecurringEventGroup {
            id: Uuid::nil(),
            user_id,
            name: "Ungrouped".to_string(),
            description: Some("Events that don't belong to any group".to_string()),
            color: u32::MAX as i64,
            group_is_active: None,
            group_recurrence_start: None,
            group_recurrence_end: None
        };

        response.push(RecurringEventGroupResponse {
            group: ungrouped_group,
            recurring_events: groupless_event_count as usize
        });

        Ok(response)
    }

    pub async fn fetch_group(&self, user_id: Uuid, group_id: Uuid) -> Result<RecurringEventGroupResponse, ApiError> {
        let group_with_count = self.repositories
            .recurring_event_groups
            .fetch_group_with_count(user_id, group_id)
            .await
            .map_err(ApiError::from)?;

        Ok(RecurringEventGroupResponse {
            group: group_with_count.group,
            recurring_events: group_with_count.event_count,
        })
    }

    pub async fn add_group(&self, user_id: Uuid, new_group: NewRecurringEventGroup) -> Result<(), ApiError> {
        self.validate_new_group(&new_group)?;

        self.repositories
            .recurring_event_groups
            .create_group(user_id, &new_group)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    pub async fn update_group(&self, user_id: Uuid, updated_group: UpdatedRecurringEventGroup) -> Result<(), ApiError> {
        let exists = self.repositories
            .recurring_event_groups
            .group_exists(user_id, updated_group.id)
            .await
            .map_err(ApiError::from)?;

        if !exists {
            return Err(ApiError::Forbidden);
        }

        self.repositories
            .recurring_event_groups
            .update_group(&updated_group)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    pub async fn delete_group(&self, user_id: Uuid, group_id: Uuid) -> Result<(), ApiError> {
        let exists = self.repositories
            .recurring_event_groups
            .group_exists(user_id, group_id)
            .await
            .map_err(ApiError::from)?;
        if !exists {
            return Err(ApiError::Forbidden);
        }

        // Delete events first, then the group
        self.repositories
            .recurring_event_groups
            .delete_group_events(group_id)
            .await
            .map_err(ApiError::from)?;

        self.repositories
            .recurring_event_groups
            .delete_group(user_id, group_id)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    pub async fn add_with_events(&self, user_id: Uuid, events: GroupWithEvents) -> Result<(), ApiError> {
        let _group_id = match events.recurring_event_group {
            Some(new_group) => {
                let id = self.repositories
                    .recurring_event_groups
                    .create_group_returning_id(user_id, &new_group)
                    .await
                    .map_err(ApiError::from)?;
                Some(id)
            },
            None => None
        };

        // TODO: finish this - add the recurring events
        Ok(())
    }

    pub async fn fetch_events_for_group(&self, user_id: Uuid, group_id: Uuid) -> Result<Vec<RecurringEvent>, ApiError> {
        let exists = self.repositories
            .recurring_event_groups
            .group_exists(user_id, group_id)
            .await
            .map_err(ApiError::from)?;

        if !exists {
            return Err(ApiError::Forbidden);
        }

        let events = self.repositories
            .recurring_event_groups
            .fetch_events_for_group(group_id)
            .await
            .map_err(ApiError::from)?;

        Ok(events)
    }

    pub async fn fetch_ungrouped_events(&self, user_id: Uuid) -> Result<Vec<RecurringEvent>, ApiError> {
        let events = self.repositories
            .recurring_event_groups
            .fetch_ungrouped_events(user_id)
            .await
            .map_err(ApiError::from)?;

        Ok(events)
    }

    pub async fn move_event_between_groups(&self, user_id: Uuid, new_group_id: Uuid, event_id: Uuid) -> Result<(), ApiError> {
        // Check if target group exists and belongs to user
        let target_exists = self.repositories
            .recurring_event_groups
            .group_exists(user_id, new_group_id)
            .await
            .map_err(ApiError::from)?;

        if !target_exists {
            return Err(ApiError::Forbidden);
        }

        // Get event info and verify ownership
        let event_info = self.repositories
            .recurring_event_groups
            .get_event_info(event_id, user_id)
            .await
            .map_err(ApiError::from)?;

        match event_info {
            None => return Err(ApiError::Forbidden),
            Some(event) => {
                if event.group_id == Some(new_group_id) {
                    return Err(ApiError::Forbidden);
                }
            }
        }

        self.repositories
            .recurring_event_groups
            .move_event_to_group(event_id, new_group_id)
            .await
            .map_err(ApiError::from)?;

        Ok(())
    }

    fn validate_new_group(&self, new_group: &NewRecurringEventGroup) -> Result<(), ApiError> {
        let mut errors = HashMap::new();

        if new_group.name.trim().is_empty() {
            errors.insert("name", "is empty");
        }

        if new_group.color <= 0 {
            errors.insert("color", "is less than 0");
        }

        if let (Some(start), Some(end)) = (new_group.group_recurrence_start, new_group.group_recurrence_end) {
            if start >= end {
                errors.insert("start/end time", "start time is later than end time");
            }
        }

        if !errors.is_empty() {
            return Err(ApiError::unprocessable_entity(errors));
        }

        Ok(())
    }
}