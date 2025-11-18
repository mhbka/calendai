use sqlx::PgPool;
use uuid::Uuid;

use crate::{models::{calendar_event::{NewCalendarEvent, UpdatedCalendarEvent}, outlook::{OutlookCalendarEvent, OutlookSyncState}}, repositories::{RepoResult, calendar_events_repo::CalendarEventsRepository}};

/// Abstraction for interacting with the `azure_token` table.
#[derive(Clone, Debug)]
pub struct OutlookCalendarRepository {
    calendar_repo: CalendarEventsRepository,
    db: PgPool,
}

impl OutlookCalendarRepository {
    pub fn new(calendar_repo: CalendarEventsRepository, db: PgPool) -> Self {
        Self { calendar_repo, db }
    }

    pub async fn get_sync_state(&self, user_id: Uuid) -> RepoResult<Option<OutlookSyncState>> {
        sqlx::query_as!(
            OutlookSyncState,
            r#"select last_sync, delta_link from sync_state where user_id = $1"#,
            user_id
        )
            .fetch_optional(&self.db)
            .await
    }

    pub async fn add_sync_state(&self, user_id: Uuid, delta_link: String) -> RepoResult<()> {
        sqlx::query!(
            r#"
                INSERT INTO sync_state
                (user_id, delta_link, last_sync)
                VALUES
                ($1, $2, NOW())
            "#,
            user_id,
            delta_link,
        )
            .execute(&self.db)
            .await?;
        Ok(())
    }
    
    pub async fn update_sync_state(&self, user_id: Uuid, delta_link: String) -> RepoResult<()> {
        sqlx::query!(
            r#"
                UPDATE sync_state
                SET last_sync = NOW(), 
                delta_link = $1
                WHERE user_id = $2
            "#,
            delta_link,
            user_id
        )
            .execute(&self.db)
            .await?;
        Ok(())
    }

    pub async fn delete_mapped_calendar_event(&self, outlook_event_id: String) -> RepoResult<()> {
        sqlx::query!(
            r#"
                UPDATE calendar_events
                SET is_deleted = true
                WHERE id = (
                    SELECT local_event_id
                    FROM outlook_event_mappings
                    WHERE outlook_event_id = $1
                );
            "#,
            outlook_event_id    
        )
            .execute(&self.db)
            .await?;
        Ok(())
    }

    pub async fn add_or_update_outlook_event(&self, user_id: Uuid, event: OutlookCalendarEvent) -> RepoResult<()> {
        let res = sqlx::query!(
            r#"SELECT local_event_id FROM outlook_event_mappings WHERE outlook_event_id = $1"#,
            event.id
        )   
            .fetch_optional(&self.db)
            .await?;
        
        if let Some(res) = res {
            let local_event_id = res.local_event_id;
            let updated_event = UpdatedCalendarEvent {
                id: local_event_id,
                title: if let Some(s) = event.subject { s } else { "".into() },
                description: event.body_preview,
                location: if let Some(l) = event.location { l.display_name } else { None },
                start_time: event.start.to_utc(),
                end_time: event.end.to_utc(),
            };
            self.calendar_repo
                .update_event(updated_event)
                .await?;
        } 
        else {
            let local_event = NewCalendarEvent {
                title: if let Some(s) = event.subject { s } else { "".into() },
                description: event.body_preview,
                location: if let Some(l) = event.location { l.display_name } else { None },
                start_time: event.start.to_utc(),
                end_time: event.end.to_utc(),
            };
            let local_event_id = self.calendar_repo
                .create_events(user_id, vec![local_event])
                .await?[0];
            sqlx::query!(
                r#"
                    INSERT INTO outlook_event_mappings
                    (local_event_id, outlook_event_id)
                    VALUES
                    ($1, $2)
                "#,
                local_event_id,
                event.id
            )
                .execute(&self.db)
                .await?;
        } 
        
        Ok(())
    }
}