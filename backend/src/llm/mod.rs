use chrono::{Duration, FixedOffset, Utc};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use crate::config::Config;
use crate::llm::error::LLMError;
use crate::llm::gemini::GeminiLLM;
use crate::models::calendar_event::NewCalendarEvent;
use crate::models::recurring_event::{NewRecurringEvent, RecurringEvent};
use crate::models::recurring_event_group::NewRecurringEventGroup;

mod gemini;
pub mod error;

/// Events generated from the LLM.
#[derive(Serialize, Deserialize, JsonSchema)]
pub struct GeneratedEvents {
    pub events: Vec<NewCalendarEvent>,
    pub recurring_events: Vec<NewRecurringEvent>,
    pub recurring_event_group: Option<NewRecurringEventGroup>
}

impl GeneratedEvents {
    /// Since the backend deals in UTC, but the user's data is likely in their own timezone,
    /// we offset all datetimes in the generated events before returning.
    /// 
    /// **NOTE**: If any more datetimes are added to any of these types, they should be offset as well.
    pub fn offset_timezones(&mut self, timezone_offset_minutes: i32) {
        let offset = -Duration::minutes(timezone_offset_minutes.into());
        for event in &mut self.events {
            event.start_time += offset;
            event.end_time += offset;
        }
        for event in &mut self.recurring_events {
            event.recurrence_start += offset;
            if let Some(recurrence_end) = &mut event.recurrence_end {
                *recurrence_end += offset;
            }
        }
        if let Some(group) = &mut self.recurring_event_group {
            if let Some(start) = &mut group.group_recurrence_start {
                *start += offset;
            }
            if let Some(end) = &mut group.group_recurrence_end {
                *end += offset;
            }
        }
    }
}

/// Used for multimodally generating events.
#[derive(Clone, Debug)]
pub struct LLM {
    gemini: GeminiLLM
}

impl LLM {
    /// Instantiate the struct.
    pub fn new(config: &Config) -> Self {
        let gemini = GeminiLLM::new(&config.gemini_key, &config.gemini_model);
        Self {
            gemini
        }
    }
    
    /// Generate events from text.
    pub async fn events_from_text(&self, text: String, timezone_offset_minutes: i32) -> Result<GeneratedEvents, LLMError> {
        let mut generated_events: GeneratedEvents = self.gemini
            .request_text(text, Some(self.system_instruction().into()))
            .await?;
        generated_events.offset_timezones(timezone_offset_minutes);
        Ok(generated_events)
    }

    /// Generate events from an mp3 audio.
    pub async fn events_from_audio(&self, audio_bytes: &[u8], timezone_offset_minutes: i32) -> Result<GeneratedEvents, LLMError> {
        let mut generated_events: GeneratedEvents = self.gemini
            .request_audio(
                audio_bytes, 
                Some(self.system_instruction().into()), 
                "Return the events from this audio.".into()
            )
            .await?;
        generated_events.offset_timezones(timezone_offset_minutes);
        Ok(generated_events)
    }

    /// Generate events from a JPG image.
    pub async fn events_from_image(&self, image_bytes: &[u8], timezone_offset_minutes: i32) -> Result<GeneratedEvents, LLMError> {
        let (events, recurring_events, recurring_event_group) = tokio::join!(
            self.gemini.request_image(
                image_bytes,
                Some(self.system_instruction().into()),
                "Return the normal calendar events from this image, if any.".into()
            ),
            self.gemini.request_image(
                image_bytes,
                Some(self.system_instruction().into()),
                "Return the recurring calendar events from this image, if any.".into()
            ),
            self.gemini.request_image(
                image_bytes,
                Some(self.system_instruction().into()),
                "Generate a recurring event group from this image, if it makes sense.".into()
            )
        );
        let events: Vec<NewCalendarEvent> = events?;
        let recurring_events: Vec<NewRecurringEvent> = recurring_events?;
        let recurring_event_group: Option<NewRecurringEventGroup> = recurring_event_group?;

        let mut generated_events = GeneratedEvents { 
            events, 
            recurring_events, 
            recurring_event_group 
        };
        /*
        let mut generated_events: GeneratedEvents = self.gemini
            .request_image(
                image_bytes, 
                Some(self.system_instruction().into()), 
                "Return the events from this image.".into()
            )
            .await?;
         */
        generated_events.offset_timezones(timezone_offset_minutes);
        return Ok(generated_events)
    }

    fn system_instruction(&self) -> String {
        let now_string = Utc::now().format("%d/%m/%Y %H:%M");
        format!(r#"
            Today's date and time in UTC is {now_string}.

            You are a calendar event-generating AI. You take an input of text/image/audio, and output events that are present within the input.

            The output data shape consists of 3 fields:
            - `events`: This is a list of normal, one-off calendar events.
            For `start_time` and `end_time`, ENSURE THAT THE DATE AND TIME ALIGNS PERFECTLY with what is present in the input.

            - `recurring_events`: This is a list of recurring events. These are similar to normal events, but can occur periodically between a start and (optional) end datetime.
            Its periodicity is described by a recurrence rule string, `rrule`, such as "FREQ=WEEKLY;COUNT=5;BYDAY=MO,TU". `recurrence_start` denotes the starting date and time 
            for the recurring event. If no date is given, used the current date. ALWAYS USE THE EVENT'S EXACT GIVEN STARTING TIME. `recurrence_end` denotes the (optional) end date
            for the recurrence. It only needs to be date-accurate. 

            - `recurring_event_group`: This is an (optional) organized group of *recurring* events. If the extracted RECURRING events follow a sensible pattern, or one is obvious from
            the input, you can create a group. `group_recurrence_start` and `group_recurrence_end` should be set IF AND ONLY IF all the recurring events have the same start and end date
            respectively. DO NOT SET THIS IF THERE ARE NO RECURRING EVENTS.

            AIM FOR 100% ACCURACY IN EXTRACTING DATETIMES. Having absolute correctness in all extracted events' datetimes is the top priority. DO NOT PERFORM ANY TIMEZONE CONVERSIONS;
            extract datetimes exactly as they are in the input.

            For metadata such as title/description/location, summarize as succinctly as possible.
        "#)
    }
}