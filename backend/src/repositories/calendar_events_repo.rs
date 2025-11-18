use chrono::{DateTime, Utc};
use sqlx::PgPool;
use uuid::Uuid;
use crate::{models::calendar_event::{CalendarEvent, NewCalendarEvent, UpdatedCalendarEvent}, repositories::RepoResult};

/// Abstraction for interacting with the `calendar_events` table.
#[derive(Clone, Debug)]
pub struct CalendarEventsRepository {
    db: PgPool,
}

impl CalendarEventsRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    pub async fn create_events(&self, user_id: Uuid, events: Vec<NewCalendarEvent>) -> RepoResult<Vec<Uuid>> {
        let user_ids = vec![user_id; events.len()];
        let mut titles = Vec::with_capacity(events.len());
        let mut descriptions = Vec::with_capacity(events.len());
        let mut start_times = Vec::with_capacity(events.len());
        let mut end_times = Vec::with_capacity(events.len());
        let mut locations = Vec::with_capacity(events.len());
        
        for event in events {
            titles.push(event.title);
            descriptions.push(event.description);
            start_times.push(event.start_time);
            end_times.push(event.end_time);
            locations.push(event.location);
        }
        
        let event_ids = sqlx::query_scalar!(
            r#"
                insert into calendar_events
                (user_id, title, description, start_time, end_time, location)
                select * from unnest
                ($1::uuid[], $2::varchar[], $3::varchar[], $4::timestamptz[], $5::timestamptz[], $6::varchar[])
                returning id
            "#,
            &user_ids[..],
            &titles[..],
            &descriptions[..] as &[Option<String>],
            &start_times[..],
            &end_times[..],
            &locations[..] as &[Option<String>]
        )
            .fetch_all(&self.db)
            .await?;

        Ok(event_ids)
    }

    pub async fn get_events_by_user_and_date_range(
        &self,
        user_id: Uuid,
        start: DateTime<Utc>,
        end: DateTime<Utc>
    ) -> RepoResult<Vec<CalendarEvent>> {
        let events = sqlx::query_as!(
            CalendarEvent,
            r#"
                select id, user_id, title, description, location, start_time, end_time, created_at, last_modified
                from calendar_events 
                where user_id = $1 
                and start_time >= $2 
                and end_time <= $3 
                and is_deleted = false
                order by start_time
            "#,
            user_id,
            start,
            end
        )
        .fetch_all(&self.db)
        .await?;
        
        Ok(events)
    }

    pub async fn get_event_owner(&self, event_id: Uuid) -> RepoResult<Uuid> {
        let event_record = sqlx::query!(
            r#"select user_id from calendar_events where id = $1"#,
            event_id
        )
        .fetch_one(&self.db)
        .await?;
        
        Ok(event_record.user_id)
    }

    pub async fn update_event(&self, updated_event: UpdatedCalendarEvent) -> RepoResult<()> {
        sqlx::query!(
            r#"
                update calendar_events
                set 
                    title = $1,
                    description = $2,
                    location = $3,
                    start_time = $4,
                    end_time = $5,
                    last_modified = NOW()
                where id = $6
            "#,
            updated_event.title,
            updated_event.description,
            updated_event.location,
            updated_event.start_time,
            updated_event.end_time,
            updated_event.id
        )
        .execute(&self.db)
        .await?;
        
        Ok(())
    }

    pub async fn delete_event(&self, event_id: Uuid) -> RepoResult<()> {
        sqlx::query!(
            r#"update calendar_events set is_deleted = true where id = $1"#,
            event_id
        )
        .execute(&self.db)
        .await?;
        
        Ok(())
    }
}