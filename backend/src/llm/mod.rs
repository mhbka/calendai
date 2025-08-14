use chrono::Utc;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use crate::config::Config;
use crate::llm::error::LLMError;
use crate::llm::gemini::GeminiLLM;
use crate::models::calendar_event::NewCalendarEvent;
use crate::models::recurring_event::NewRecurringEvent;
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
    pub async fn events_from_text(&self, text: String) -> Result<GeneratedEvents, LLMError> {
        self.gemini
            .request_text(text, Some(self.system_instruction().into()))
            .await
    }

    /// Generate events from an mp3 audio.
    pub async fn events_from_audio(&self, audio_bytes: &[u8]) -> Result<GeneratedEvents, LLMError> {
        self.gemini
            .request_audio(
                audio_bytes, 
                Some(self.system_instruction().into()), 
                "Return the events from this audio.".into()
            )
            .await
    }

    /// Generate events from a JPG image.
    pub async fn events_from_image(&self, image_bytes: &[u8]) -> Result<GeneratedEvents, LLMError> {
        self.gemini
            .request_image(
                image_bytes, 
                Some(self.system_instruction().into()), 
                "Return the events from this image.".into()
            )
            .await
    }

    fn system_instruction(&self) -> String {
        let now_string = Utc::now().format("%d/%m/%Y %H:%M");
        format!(r#"
            Today's date and time in UTC is {now_string}.
            You are a calendar event-generating AI. 
            You take an input of text/image/audio, and output events that are present within the input.
            There are 2 types of events:
            
            - Normal, one-off events. These have the expected metadata for a calendar event. 
            - Recurring events; which recur based on a set periodicity, between a start and (optional) end date.
            The *event duration* must be calculated by subtracting the event's intended start time from its end time.
            The *periodicity* of a recurring event is defined by its recurrence rule, or `rrule` string. For example,
            'RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=10' would mean an event repeats every two weeks for a total of 10 occurrences.

            Use your intuition to figure out whether an event should be normal or recurring. For example, a poster with a single date
            would be a normal event, while a class schedule would be several recurring events. Output all normal events into the `events` array,
            and all recurring events into the `recurring_events` array.   

            Recurring events can optionally be organized into "groups". A sensible group would be a "Class" group for all recurring events
            for a class schedule's classes. You can designate a group for your recurring events by filling out the metadata for `recurring_event_group` if:
            - You can decipher a sensible reason for the events to be together, and/or
            - The events all (should or do) start and/or end on the same date.

            Act conservatively yet precisely. If you are unsure if an event should be generated, do not generate it, allowing the user to add it themselves.
            Obtain all necessary details of each event within the input media.
        "#)
    }
}