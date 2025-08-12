use axum::body::Bytes;

use crate::{api::error::{ApiError, ApiResult}, llm::{GeneratedEvents, LLM}};

/// Handles business logic for generating events using AI/LLMs.
#[derive(Clone, Debug)]
pub struct AIAddEventsService {
    llm: LLM
}

impl AIAddEventsService {
    pub fn new(llm: LLM) -> Self {
        Self {
            llm
        }
    }

    pub async fn generate_from_text(&self, text: String) -> ApiResult<GeneratedEvents> {
        self.llm
            .events_from_text(text)
            .await
            .map_err(|err| {
                tracing::warn!("Failed to generate events from text: {err}");
                ApiError::Internal("Had an issue generating our AI service".into())
            })
    }

    pub async fn generate_from_audio(&self, audio_bytes: Bytes) -> ApiResult<GeneratedEvents> {
        self.llm
            .events_from_audio(&audio_bytes)
            .await
            .map_err(|err| {
                tracing::warn!("Failed to generate events from audio: {err}");
                ApiError::Internal("Had an issue generating our AI service".into())
            })
    }

    pub async fn generate_from_image(&self, image_bytes: Bytes) -> ApiResult<GeneratedEvents> {
        self.llm
            .events_from_image(&image_bytes)
            .await
            .map_err(|err| {
                tracing::warn!("Failed to generate events from image: {err}");
                ApiError::Internal("Had an issue generating our AI service".into())
            })
    }
}