use std::collections::HashSet;
use sqlx::PgPool;
use chrono::{DateTime, Utc};
use uuid::Uuid;
use crate::{models::{
    recurring_event::{NewRecurringEvent, RecurringEvent, UpdatedRecurringEvent}, recurring_event_exception::{NewRecurringEventException, RecurringEventException}, recurring_event_group::RecurringEventGroup, rrule::ValidatedRRule, time::Second
}, repositories::RepoResult};

#[derive(Clone, Debug)]
pub struct RecurringEventsRepository {
    db: PgPool,
}

impl RecurringEventsRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    pub async fn validate_group_ownership(&self, user_id: Uuid, group_ids: &[Option<Uuid>]) -> RepoResult<bool> {
        let requested_group_ids: Vec<_> = group_ids
            .iter()
            .filter(|&g| g.is_some())
            .cloned()
            .collect();

        if requested_group_ids.is_empty() {
            return Ok(true);
        }

        let authorized_groups = sqlx::query!(
            r#"
                select id from recurring_event_groups 
                where id = any($1) and user_id = $2
            "#,
            &requested_group_ids[..] as &[Option<Uuid>],
            user_id
        )
        .fetch_all(&self.db)
        .await?;

        Ok(authorized_groups.len() == requested_group_ids.len())
    }

    pub async fn bulk_create_events(&self, events: &[NewRecurringEvent], user_id: Uuid) -> RepoResult<()> {
        let mut group_ids = Vec::with_capacity(events.len());
        let user_ids = vec![user_id; events.len()];
        let mut titles = Vec::with_capacity(events.len());
        let mut descriptions = Vec::with_capacity(events.len());
        let mut locations = Vec::with_capacity(events.len());
        let mut durations = Vec::with_capacity(events.len());
        let mut recurrence_starts = Vec::with_capacity(events.len());
        let mut recurrence_ends = Vec::with_capacity(events.len());
        let mut rrules = Vec::with_capacity(events.len());

        for event in events {
            group_ids.push(event.group_id);
            titles.push(event.title.clone());
            descriptions.push(event.description.clone());
            locations.push(event.location.clone());
            durations.push(event.event_duration_seconds.0 as i32);
            recurrence_starts.push(event.recurrence_start);
            recurrence_ends.push(event.recurrence_end);
            rrules.push(event.rrule.to_string());
        }

        sqlx::query!(
            r#"
                insert into recurring_events
                (group_id, user_id, title, description, location, event_duration_seconds, recurrence_start, recurrence_end, rrule)
                select * from unnest
                ($1::uuid[], $2::uuid[], $3::varchar[], $4::varchar[], $5::varchar[], $6::int[], $7::timestamptz[], $8::timestamptz[], $9::varchar[])
            "#,
            &group_ids[..] as &[Option<Uuid>],
            &user_ids[..],
            &titles[..],
            &descriptions[..] as &[Option<String>],
            &locations[..] as &[Option<String>],
            &durations[..],
            &recurrence_starts[..],
            &recurrence_ends[..] as &[Option<DateTime<Utc>>],
            &rrules[..]
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn fetch_active_events_in_period(
        &self,
        user_id: Uuid,
        start: DateTime<Utc>,
        end: DateTime<Utc>
    ) -> RepoResult<Vec<RecurringEvent>> {
        let events = sqlx::query_as!(
            RecurringEvent,
            r#"
                SELECT 
                    re.id, 
                    re.group_id, 
                    re.user_id,
                    re.is_active, 
                    re.title, 
                    re.description, 
                    re.location, 
                    re.recurrence_start, 
                    re.recurrence_end, 
                    re.event_duration_seconds as "event_duration_seconds: _", 
                    re.rrule as "rrule: _"
                FROM recurring_events re
                LEFT JOIN recurring_event_groups reg ON reg.id = re.group_id
                WHERE re.user_id = $1 
                AND re.is_active = true
                AND re.recurrence_start < $3 
                AND (re.recurrence_end IS NULL OR re.recurrence_end > $2)
            "#,
            user_id,
            start,
            end
        )
        .fetch_all(&self.db)
        .await?;

        Ok(events)
    }

    pub async fn fetch_exceptions_for_events(&self, event_ids: &[Uuid]) -> RepoResult<Vec<RecurringEventException>> {
        let exceptions = sqlx::query_as!(
            RecurringEventException,
            r#"
                SELECT 
                    id, 
                    recurring_event_id, 
                    exception_date, 
                    exception_type as "exception_type: _",
                    modified_title,
                    modified_description,
                    modified_location,
                    modified_start_time,
                    modified_end_time
                FROM recurring_event_exceptions ree
                WHERE ree.recurring_event_id = ANY($1)
            "#,
            event_ids
        )
        .fetch_all(&self.db)
        .await?;

        Ok(exceptions)
    }

    pub async fn fetch_groups_by_ids(&self, group_ids: &[Uuid]) -> RepoResult<Vec<RecurringEventGroup>> {
        let groups = sqlx::query_as!(
            RecurringEventGroup,
            r#"
                SELECT *
                FROM recurring_event_groups
                WHERE id = ANY($1)
            "#,
            group_ids
        )
        .fetch_all(&self.db)
        .await?;

        Ok(groups)
    }

    pub async fn verify_event_ownership(&self, event_id: Uuid, user_id: Uuid) -> RepoResult<bool> {
        let event_record = sqlx::query!(
            "SELECT user_id FROM recurring_events WHERE id = $1",
            event_id
        )
        .fetch_optional(&self.db)
        .await?;

        Ok(event_record.map_or(false, |record| record.user_id == user_id))
    }

    pub async fn update_event(&self, updated_event: UpdatedRecurringEvent) -> RepoResult<()> {
        sqlx::query!(
            r#"
                update recurring_events
                set 
                    title = $1,
                    group_id = $2,
                    description = $3,
                    location = $4,
                    event_duration_seconds = $5,
                    recurrence_start = $6,
                    recurrence_end = $7,
                    rrule = $8
                where id = $9
            "#,
            updated_event.title,
            updated_event.group_id,
            updated_event.description,
            updated_event.location,
            updated_event.event_duration_seconds as Second,
            updated_event.recurrence_start,
            updated_event.recurrence_end,
            updated_event.rrule as ValidatedRRule,
            updated_event.id
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn verify_event_ownership_via_group(&self, event_id: Uuid, user_id: Uuid) -> RepoResult<bool> {
        let event_record = sqlx::query!(
            r#"
                select recurring_event_groups.user_id
                from recurring_events 
                inner join recurring_event_groups on recurring_events.group_id = recurring_event_groups.id
                where recurring_events.id = $1
            "#,
            event_id
        )
        .fetch_optional(&self.db)
        .await?;

        Ok(event_record.map_or(false, |record| record.user_id == user_id))
    }

    pub async fn delete_event(&self, event_id: Uuid) -> RepoResult<()> {
        sqlx::query!(
            r#"delete from recurring_events where id = $1"#,
            event_id
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn verify_exception_event_ownership(&self, recurring_event_id: Uuid, user_id: Uuid) -> RepoResult<bool> {
        let event = sqlx::query!(
            r#"
                SELECT COUNT(*)
                FROM recurring_event_exceptions ree
                LEFT JOIN recurring_events re ON ree.recurring_event_id = re.id
                WHERE re.user_id = $1 AND re.id = $2
            "#,
            user_id,
            recurring_event_id
        )
        .fetch_optional(&self.db)
        .await?;

        Ok(event.is_some())
    }

    pub async fn create_event_exception(&self, exception: NewRecurringEventException) -> RepoResult<()> {
        sqlx::query!(
            r#"
                INSERT INTO recurring_event_exceptions (
                    recurring_event_id,
                    exception_date,
                    exception_type,
                    modified_title,
                    modified_description,
                    modified_location,
                    modified_start_time,
                    modified_end_time
                )
                VALUES ($1, $2, 'modified', $3, $4, $5, $6, $7)
            "#,
            exception.recurring_event_id,
            exception.exception_date,
            exception.modified_title,
            exception.modified_description,
            exception.modified_location as Option<Option<String>>,
            exception.modified_start_time,
            exception.modified_end_time
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn update_event_exception(&self, exception: RecurringEventException) -> RepoResult<()> {
        sqlx::query!(
            r#"
                UPDATE recurring_event_exceptions 
                SET 
                    exception_date = $2,
                    exception_type = $3,
                    modified_title = $4,
                    modified_description = $5,
                    modified_location = $6,
                    modified_start_time = $7,
                    modified_end_time = $8
                WHERE id = $1
            "#,
            exception.id,
            exception.exception_date,
            &exception.exception_type.to_string(),
            exception.modified_title,
            exception.modified_description as Option<Option<String>>,
            exception.modified_location as Option<Option<String>>,
            exception.modified_start_time,
            exception.modified_end_time
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }
}