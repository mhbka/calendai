use sqlx::PgPool;
use crate::repositories::{calendar_events_repo::CalendarEventsRepository, recurring_event_groups_repo::RecurringEventGroupsRepository, recurring_events_repo::RecurringEventsRepository};

pub mod calendar_events_repo;
pub mod recurring_event_groups_repo;
pub mod recurring_events_repo;

/// Repositories, or abstractions over the database.
#[derive(Clone, Debug)]
pub struct Repositories {
    pub calendar_events: CalendarEventsRepository,
    pub recurring_event_groups: RecurringEventGroupsRepository,
    pub recurring_events: RecurringEventsRepository
}

impl Repositories {
    pub fn new(db: PgPool) -> Self {
        Self {
            calendar_events: CalendarEventsRepository::new(db.clone()),
            recurring_event_groups: RecurringEventGroupsRepository::new(db.clone()),
            recurring_events: RecurringEventsRepository::new(db.clone())
        }
    }
}

/// The result returned from a repository.
pub type RepoResult<T> = Result<T, sqlx::Error>;