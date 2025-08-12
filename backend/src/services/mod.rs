use crate::{llm::LLM, repositories::Repositories, services::{ai_add_events_service::AIAddEventsService, calendar_events_service::CalendarEventsService, recurring_event_groups_service::RecurringEventGroupsService, recurring_events_service::RecurringEventsService}};

pub mod ai_add_events_service;
pub mod calendar_events_service;
pub mod recurring_event_groups_service;
pub mod recurring_events_service;

/// An abstraction over the business logic.
#[derive(Clone, Debug)]
pub struct Services {
    pub calendar_events: CalendarEventsService,
    pub recurring_event_groups: RecurringEventGroupsService,
    pub recurring_events: RecurringEventsService,
    pub ai_add_events: AIAddEventsService
}

impl Services {
    pub fn new(repositories: Repositories, llm: LLM) -> Self {
        Self {
            calendar_events: CalendarEventsService::new(repositories.clone()),
            recurring_event_groups: RecurringEventGroupsService::new(repositories.clone()),
            recurring_events: RecurringEventsService::new(repositories.clone()),
            ai_add_events: AIAddEventsService::new(llm)
        }
    }
}