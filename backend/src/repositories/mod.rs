use sqlx::PgPool;
use crate::repositories::{azure_token_repo::AzureTokensRepository, calendar_events_repo::CalendarEventsRepository, outlook_calendar_repo::OutlookCalendarRepository, recurring_event_groups_repo::RecurringEventGroupsRepository, recurring_events_repo::RecurringEventsRepository};

pub mod calendar_events_repo;
pub mod recurring_event_groups_repo;
pub mod recurring_events_repo;
pub mod azure_token_repo;
pub mod outlook_calendar_repo;

/// Repositories, or abstractions over the database.
#[derive(Clone, Debug)]
pub struct Repositories {
    pub calendar_events: CalendarEventsRepository,
    pub recurring_event_groups: RecurringEventGroupsRepository,
    pub recurring_events: RecurringEventsRepository,
    pub azure_tokens: AzureTokensRepository,
    pub outlook_calendar: OutlookCalendarRepository
}

impl Repositories {
    pub fn new(db: PgPool) -> Self {
        let calendar_events = CalendarEventsRepository::new(db.clone());
        Self {
            calendar_events: calendar_events.clone(),
            recurring_event_groups: RecurringEventGroupsRepository::new(db.clone()),
            recurring_events: RecurringEventsRepository::new(db.clone()),
            azure_tokens: AzureTokensRepository::new(db.clone()),
            outlook_calendar: OutlookCalendarRepository::new(calendar_events.clone(), db.clone())
        }
    }
}

/// The result returned from a repository.
pub type RepoResult<T> = Result<T, sqlx::Error>;