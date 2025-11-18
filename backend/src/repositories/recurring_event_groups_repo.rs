use sqlx::PgPool;
use uuid::Uuid;
use crate::{models::{
    recurring_event::RecurringEvent,
    recurring_event_group::{NewRecurringEventGroup, RecurringEventGroup, UpdatedRecurringEventGroup}
}, repositories::RepoResult};

#[derive(Clone, Debug)]
pub struct RecurringEventGroupsRepository {
    db: PgPool,
}

impl RecurringEventGroupsRepository {
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    pub async fn fetch_all_groups_with_counts(&self, user_id: Uuid) -> RepoResult<Vec<GroupWithCount>> {
        let groups_with_counts = sqlx::query!(
            r#"
                SELECT 
                    g.id,
                    g.user_id,
                    g.name,
                    g.description,
                    g.color,
                    g.group_is_active,
                    g.group_recurrence_start,
                    g.group_recurrence_end,
                    COALESCE(COUNT(e.id), 0) as event_count
                FROM recurring_event_groups g
                LEFT JOIN recurring_events e ON g.id = e.group_id
                WHERE g.user_id = $1
                GROUP BY g.id, g.user_id, g.name, g.description, g.color, g.group_is_active, g.group_recurrence_start, g.group_recurrence_end
                ORDER BY g.name
            "#,
            user_id
        )
        .fetch_all(&self.db)
        .await?;

        let result = groups_with_counts
            .into_iter()
            .map(|row| GroupWithCount {
                group: RecurringEventGroup {
                    id: row.id,
                    user_id: row.user_id,
                    name: row.name,
                    description: row.description,
                    color: row.color,
                    group_is_active: row.group_is_active,
                    group_recurrence_start: row.group_recurrence_start,
                    group_recurrence_end: row.group_recurrence_end,
                },
                event_count: row.event_count.unwrap_or(0) as usize,
            })
            .collect();

        Ok(result)
    }

    pub async fn fetch_ungrouped_event_count(&self, user_id: Uuid) -> RepoResult<i64> {
        let count = sqlx::query_scalar!(
            r#"
                SELECT COUNT(*)
                FROM recurring_events re
                WHERE group_id IS NULL AND user_id = $1
            "#,
            user_id
        )
        .fetch_one(&self.db)
        .await?
        .unwrap_or(0);

        Ok(count)
    }

    pub async fn fetch_group_with_count(&self, user_id: Uuid, group_id: Uuid) -> RepoResult<GroupWithCount> {
        let row = sqlx::query!(
            r#"
                SELECT 
                    g.id,
                    g.user_id,
                    g.name,
                    g.description,
                    g.color,
                    g.group_is_active,
                    g.group_recurrence_start,
                    g.group_recurrence_end,
                    COALESCE(COUNT(e.id), 0) as event_count
                FROM recurring_event_groups g
                LEFT JOIN recurring_events e ON g.id = e.group_id
                WHERE g.user_id = $1 AND g.id = $2 AND is_deleted = false
                GROUP BY g.id, g.user_id, g.name, g.description, g.color, g.group_is_active, g.group_recurrence_start, g.group_recurrence_end
            "#,
            user_id,
            group_id
        )
        .fetch_one(&self.db)
        .await?;

        Ok(GroupWithCount {
            group: RecurringEventGroup {
                id: row.id,
                user_id: row.user_id,
                name: row.name,
                description: row.description,
                color: row.color,
                group_is_active: row.group_is_active,
                group_recurrence_start: row.group_recurrence_start,
                group_recurrence_end: row.group_recurrence_end,
            },
            event_count: row.event_count.unwrap_or(0) as usize,
        })
    }

    pub async fn create_group(&self, user_id: Uuid, new_group: &NewRecurringEventGroup) -> RepoResult<()> {
        sqlx::query!(
            r#"
                INSERT INTO recurring_event_groups 
                (user_id, name, description, color, group_is_active, group_recurrence_start, group_recurrence_end)
                VALUES 
                ($1, $2, $3, $4, $5, $6, $7)
            "#,
            user_id,
            new_group.name,
            new_group.description,
            new_group.color as i64,
            new_group.group_is_active,
            new_group.group_recurrence_start,
            new_group.group_recurrence_end
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn create_group_returning_id(&self, user_id: Uuid, new_group: &NewRecurringEventGroup) -> RepoResult<Uuid> {
        let row = sqlx::query!(
            r#"
                INSERT INTO recurring_event_groups 
                (user_id, name, description, color, group_is_active, group_recurrence_start, group_recurrence_end)
                VALUES 
                ($1, $2, $3, $4, $5, $6, $7)
                RETURNING id
            "#,
            user_id,
            new_group.name,
            new_group.description,
            new_group.color as i64,
            new_group.group_is_active,
            new_group.group_recurrence_start,
            new_group.group_recurrence_end
        )
        .fetch_one(&self.db)
        .await?;

        Ok(row.id)
    }

    pub async fn group_exists(&self, user_id: Uuid, group_id: Uuid) -> RepoResult<bool> {
        let exists = sqlx::query!(
            "SELECT id FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
            group_id,
            user_id
        )
        .fetch_optional(&self.db)
        .await?
        .is_some();

        Ok(exists)
    }

    pub async fn update_group(&self, updated_group: &UpdatedRecurringEventGroup) -> RepoResult<()> {
        sqlx::query!(
            r#"
                UPDATE recurring_event_groups
                SET
                    name = $1,
                    description = $2,
                    color = $3,
                    group_is_active = $4,
                    group_recurrence_start = $5,
                    group_recurrence_end = $6
                WHERE id = $7
            "#,
            updated_group.name,
            updated_group.description,
            updated_group.color,
            updated_group.group_is_active,
            updated_group.group_recurrence_start,
            updated_group.group_recurrence_end,
            updated_group.id
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn delete_group_events(&self, group_id: Uuid) -> RepoResult<()> {
        sqlx::query!(
            "UPDATE recurring_events SET is_deleted = true WHERE group_id = $1",
            group_id
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn delete_group(&self, user_id: Uuid, group_id: Uuid) -> RepoResult<()> {
        sqlx::query!(
            "DELETE FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
            group_id,
            user_id
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }

    pub async fn fetch_events_for_group(&self, group_id: Uuid) -> RepoResult<Vec<RecurringEvent>> {
        let events = sqlx::query_as!(
            RecurringEvent,
            r#"
                SELECT 
                    id, 
                    group_id, 
                    user_id,
                    is_active, 
                    title, 
                    description, 
                    location, 
                    event_duration_seconds as "event_duration_seconds: _", 
                    recurrence_start, 
                    recurrence_end, 
                    rrule as "rrule: _",
                    created_at,
                    last_modified
                FROM recurring_events
                WHERE group_id = $1 and is_deleted = false
            "#,
            group_id
        )
        .fetch_all(&self.db)
        .await?;

        Ok(events)
    }

    pub async fn fetch_ungrouped_events(&self, user_id: Uuid) -> RepoResult<Vec<RecurringEvent>> {
        let events = sqlx::query_as!(
            RecurringEvent,
            r#"
                SELECT 
                    id, 
                    group_id, 
                    user_id,
                    is_active, 
                    title, 
                    description, 
                    location, 
                    event_duration_seconds as "event_duration_seconds: _", 
                    recurrence_start, 
                    recurrence_end, 
                    rrule as "rrule: _",
                    created_at,
                    last_modified
                FROM recurring_events
                WHERE user_id = $1 
                AND group_id IS NULL 
                AND is_deleted = false
            "#,
            user_id
        )
        .fetch_all(&self.db)
        .await?;

        Ok(events)
    }

    pub async fn get_event_info(&self, event_id: Uuid, user_id: Uuid) -> RepoResult<Option<EventInfo>> {
        let event_info = sqlx::query!(
            r#"
                SELECT e.id, e.group_id, g.user_id
                FROM recurring_events e
                JOIN recurring_event_groups g ON e.group_id = g.id
                WHERE e.id = $1 AND g.user_id = $2
            "#,
            event_id,
            user_id
        )
        .fetch_optional(&self.db)
        .await?;

        Ok(event_info.map(|row| EventInfo {
            id: row.id,
            group_id: row.group_id,
            user_id: row.user_id,
        }))
    }

    pub async fn move_event_to_group(&self, event_id: Uuid, new_group_id: Uuid) -> RepoResult<()> {
        sqlx::query!(
            "UPDATE recurring_events SET group_id = $1 WHERE id = $2",
            new_group_id,
            event_id
        )
        .execute(&self.db)
        .await?;

        Ok(())
    }
}

#[derive(Debug)]
pub struct GroupWithCount {
    pub group: RecurringEventGroup,
    pub event_count: usize,
}

#[derive(Debug)]
pub struct EventInfo {
    pub id: Uuid,
    pub group_id: Option<Uuid>,
    pub user_id: Uuid,
}