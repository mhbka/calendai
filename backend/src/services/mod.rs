use crate::{llm::LLM, repositories::Repositories, services::{ai_add_events_service::AIAddEventsService, azure_token_service::AzureTokenService, calendar_events_service::CalendarEventsService, outlook_calendar_service::OutlookCalendarService, recurring_event_groups_service::RecurringEventGroupsService, recurring_events_service::RecurringEventsService}};

pub mod ai_add_events_service;
pub mod calendar_events_service;
pub mod recurring_event_groups_service;
pub mod recurring_events_service;
pub mod azure_token_service;
pub mod outlook_calendar_service;

/// An abstraction over the business logic.
#[derive(Clone, Debug)]
pub struct Services {
    pub calendar_events: CalendarEventsService,
    pub recurring_event_groups: RecurringEventGroupsService,
    pub recurring_events: RecurringEventsService,
    pub ai_add_events: AIAddEventsService,
    pub azure_token: AzureTokenService,
    pub outlook_calendar: OutlookCalendarService
}

impl Services {
    pub fn new(repositories: Repositories, llm: LLM) -> Self {
        let azure_token_service = AzureTokenService::new(llm.clone(), repositories.clone());
        Self {
            calendar_events: CalendarEventsService::new(repositories.clone()),
            recurring_event_groups: RecurringEventGroupsService::new(repositories.clone()),
            recurring_events: RecurringEventsService::new(repositories.clone()),
            ai_add_events: AIAddEventsService::new(llm.clone()),
            azure_token: azure_token_service.clone(),
            outlook_calendar: OutlookCalendarService::new(azure_token_service, repositories.clone())
        }
    }
}