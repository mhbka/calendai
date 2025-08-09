use crate::{repositories::Repositories, services::calendar_events_service::CalendarEventsService};

pub mod ai_add_events_service;
pub mod calendar_events_service;
pub mod recurring_event_groups_service;
pub mod recurring_events_service;

/// An abstraction over the business logic.
#[derive(Clone, Debug)]
pub struct Services {
    pub calendar_events: CalendarEventsService
}

impl Services {
    pub fn new(repositories: Repositories) -> Self {
        Self {
            calendar_events: CalendarEventsService::new(repositories)
        }
    }
}