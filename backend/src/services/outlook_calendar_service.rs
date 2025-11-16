use chrono::{Datelike, TimeZone, Utc};
use icalendar::{Calendar, Component, Event, EventLike};
use uuid::Uuid;

use crate::{api::error::ApiResult, repositories::Repositories};


/// Handles business logic for interacting with Outlook calendar.
#[derive(Clone, Debug)]
pub struct OutlookCalendarService {
    repositories: Repositories,
}

impl OutlookCalendarService {
    pub fn new(repositories: Repositories) -> Self {
        Self { repositories }
    }

    pub async fn sync_with_outlook(&self, user_id: Uuid) -> ApiResult<()> {
        todo!()
    }

    pub async fn get_ics_string(&self, user_id: Uuid) -> ApiResult<String> {
        let start = Utc.with_ymd_and_hms(0, 1, 1, 1, 1, 1).unwrap();
        let end = Utc.with_ymd_and_hms(5000, 1, 1, 1, 1, 1).unwrap();
        let normal_events = self.repositories.calendar_events
            .get_events_by_user_and_date_range(user_id, start, end)
            .await?;
        let recurring_events = self.repositories.recurring_events
            .fetch_active_events_in_period(user_id, start, end)
            .await?;

        let mut calendar = Calendar::new();
        
        normal_events
            .into_iter()
            .map(|event| {
                let mut ics_event = Event::with_uid(&event.id.to_string());
                if let Some(desc) = event.description {
                    ics_event.description(&desc);
                }
                if let Some(location) = event.location {
                    ics_event.location(&location);
                }
                ics_event
                    .summary(&event.title)
                    .starts(event.start_time)
                    .ends(event.end_time);
                ics_event
            })
            .for_each(|event| { 
                calendar.push(event); 
            });
        recurring_events
            .into_iter()
            .map(|event| {
                let mut ics_event = Event::with_uid(&event.id.to_string());
                if let Some(desc) = event.description {
                    ics_event.description(&desc);
                }
                if let Some(location) = event.location {
                    ics_event.location(&location);
                }
                if let Some(end_time) = event.recurrence_end {
                    ics_event.ends(end_time);
                }
                ics_event
                    .summary(&event.title)
                    .starts(event.recurrence_start)
                    .add_property("RRULE", &event.rrule.to_string());
                ics_event
            })
            .for_each(|event| { 
                calendar.push(event); 
            });
            
        Ok(calendar.to_string())
    }
}