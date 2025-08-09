use chrono::{DateTime, Utc};
use uuid::Uuid;
use crate::{
    api::error::{ApiError, ApiResult}, 
    models::calendar_event::{CalendarEvent, NewCalendarEvent, UpdatedCalendarEvent},
    repositories::Repositories
};

/// Handles business logic for calendar event routes.
#[derive(Clone, Debug)]
pub struct CalendarEventsService {
    repositories: Repositories,
}

impl CalendarEventsService {
    pub fn new(repositories: Repositories) -> Self {
        Self { repositories }
    }

    pub async fn create_events(&self, user_id: Uuid, events: Vec<NewCalendarEvent>) -> ApiResult<()> {
        self.repositories
            .calendar_events
            .create_events(user_id, events)
            .await?;
        Ok(())
    }

    pub async fn get_events(
        &self,
        user_id: Uuid,
        start: DateTime<Utc>,
        end: DateTime<Utc>
    ) -> ApiResult<Vec<CalendarEvent>> {
        let events = self.repositories
            .calendar_events
            .get_events_by_user_and_date_range(user_id, start, end)
            .await?;
        Ok(events)
    }

    pub async fn update_event(&self, user_id: Uuid, updated_event: UpdatedCalendarEvent) -> ApiResult<()> {
        let event_owner = self.repositories.calendar_events.get_event_owner(updated_event.id).await?;
        if event_owner != user_id {
            return Err(ApiError::Forbidden);
        }
        self.repositories
            .calendar_events
            .update_event(updated_event)
            .await?;
        Ok(())
    }

    pub async fn delete_event(&self, user_id: Uuid, event_id: Uuid) -> ApiResult<()> {
        let event_owner = self.repositories.calendar_events.get_event_owner(event_id).await?;
        if event_owner != user_id {
            return Err(ApiError::Forbidden);
        }
        self.repositories
            .calendar_events
            .delete_event(event_id)
            .await?;
        Ok(())
    }
}