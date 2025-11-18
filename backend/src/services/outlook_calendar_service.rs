use std::{sync::OnceLock, time::Duration};
use reqwest::Client;
use chrono::{Datelike, SecondsFormat, TimeZone, Utc};
use graph_rs_sdk::Graph;
use icalendar::{Calendar, Component, Event, EventLike};
use uuid::Uuid;
use crate::{api::error::ApiResult, config::Config, models::{outlook::{OutlookCalendar, OutlookCalendarResponse, OutlookDeltaEvent}, recurring_event_exception::ExceptionType}, repositories::Repositories, services::azure_token_service::AzureTokenService};

static CLIENT: OnceLock<Client> = OnceLock::new();

/// Handles business logic for interacting with Outlook calendar.
#[derive(Clone, Debug)]
pub struct OutlookCalendarService {
    azure_token_service: AzureTokenService,
    repositories: Repositories,
}

impl OutlookCalendarService {
    pub fn new(azure_token_service: AzureTokenService, repositories: Repositories) -> Self {
        Self { 
            azure_token_service,
            repositories 
        }
    }

    pub async fn sync_with_outlook(&self, user_id: Uuid, config: &Config) -> ApiResult<()> {
        let access_token = self.azure_token_service
            .get_valid_access_token(user_id, config)
            .await?;
        let client = CLIENT.get_or_init(|| {
            Client::builder()
                .timeout(Duration::from_secs(10))
                .build()
                .expect("Failed to create client")
        });

        let sync_state = self.repositories.outlook_calendar
            .get_sync_state(user_id)
            .await?;
        
        let mut link = match &sync_state {
            Some(state) => state.delta_link.clone(),
            None => {
                let start = Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true);
                let end = Utc.with_ymd_and_hms(2040, 1, 1, 1, 1, 1).unwrap().to_rfc3339_opts(SecondsFormat::Secs, true);
                format!("https://graph.microsoft.com/v1.0/me/calendar/calendarView/delta?startDateTime={start}&endDateTime={end}")
            }
        };

        let mut total_updates = Vec::new();
        loop {
            let mut updates: OutlookCalendarResponse = client.get(&link)
                .bearer_auth(&access_token)
                .send()
                .await?
                .error_for_status()?
                .json()
                .await?;
            total_updates.append(&mut updates.value);
            if let Some(next_link) = updates.next_link {
                link = next_link;
                continue;
            } 
            else if let Some(delta_link) = updates.delta_link {
                // TODO: make this an upsert?
                if sync_state.is_some() {
                    self.repositories.outlook_calendar
                        .update_sync_state(user_id, delta_link)
                        .await?;
                } else {
                    self.repositories.outlook_calendar
                        .add_sync_state(user_id, delta_link)
                        .await?;
                }
                
            } else {
                tracing::warn!("Didn't find a next link or delta link for user {user_id}'s Outlook sync!");
            }
            break;
        }

        for update in total_updates {
            match update {
                OutlookDeltaEvent::Event(event) => {
                    self.repositories.outlook_calendar
                        .add_or_update_outlook_event(user_id, event)
                        .await?;
                },
                OutlookDeltaEvent::Deleted { id, removed } => {
                    self.repositories.outlook_calendar
                        .delete_mapped_calendar_event(id)
                        .await?;
                }
            }
        }
        
        Ok(())
    }

    pub async fn get_ics_string(&self, user_id: Uuid) -> ApiResult<String> {
        let start = Utc.with_ymd_and_hms(0, 1, 1, 1, 1, 1).unwrap();
        let end = Utc.with_ymd_and_hms(5000, 1, 1, 1, 1, 1).unwrap();
        let normal_events = self.repositories.calendar_events
            .get_events_by_user_and_date_range(user_id, start, end)
            .await?;
        let mut recurring_events = self.repositories.recurring_events
            .fetch_active_events_in_period(user_id, start, end)
            .await?;
        let recurring_event_ids = recurring_events
            .iter()
            .map(|e| e.id)
            .collect::<Vec<_>>();
        let recurring_event_exceptions = self.repositories.recurring_events
            .fetch_exceptions_for_events(&recurring_event_ids)
            .await?;

        let mut calendar = Calendar::new();
        
        // add normal events
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

        // add EXDATES for deleted recurring event instances
        recurring_events
            .iter_mut()
            .for_each(|event| {
                let deleted_exceptions = recurring_event_exceptions
                    .iter()
                    .filter(|e| e.exception_type == ExceptionType::Cancelled)
                    .map(|e| e.exception_date)
                    .collect::<Vec<_>>();
                event.rrule.set_exdates(&deleted_exceptions);
            });
        
        // add separate events for modified recurring event instances
        recurring_event_exceptions
            .iter()
            .filter(|e| e.exception_type == ExceptionType::Modified)
            .map(|exception| {
                let mut ics_event = Event::with_uid(&exception.recurring_event_id.to_string());
                if let Some(desc) = &exception.modified_description {
                    match desc {
                        Some(desc) => ics_event.description(&desc),
                        None => ics_event.description("")
                    };
                }
                if let Some(location) = &exception.modified_location {
                    match location {
                        Some(location) => ics_event.location(&location),
                        None => ics_event.location("")
                    };
                }
                if let Some(title) = &exception.modified_title {
                    ics_event.summary(&title);
                }
                if let Some(start_time) = exception.modified_start_time {
                    ics_event.starts(start_time);
                }
                if let Some(end_time) = exception.modified_end_time {
                    ics_event.ends(end_time);
                }
                ics_event.recurrence_id(exception.exception_date);
                ics_event
            })
            .for_each(|e| {
                calendar.push(e);
            });

        // add recurring events
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