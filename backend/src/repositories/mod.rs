use sqlx::PgPool;
use crate::repositories::calendar_events_repo::CalendarEventsRepository;

pub mod calendar_events_repo;
pub mod recurring_event_groups_repo;
pub mod recurring_events_repo;

/// Repositories, or abstractions over the database.
#[derive(Clone, Debug)]
pub struct Repositories {
    pub calendar_events: CalendarEventsRepository
}

impl Repositories {
    pub fn new(db: PgPool) -> Self {
        Self {
            calendar_events: CalendarEventsRepository::new(db)
        }
    }
}

/// The result returned from a repository.
pub type RepoResult<T> = Result<T, sqlx::Error>;