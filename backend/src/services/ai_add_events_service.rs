use std::io::Cursor;

use axum::body::Bytes;
use image::{ImageFormat, ImageReader};

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

    pub async fn generate_from_text(&self, text: String, timezone_offset_minutes: i32) -> ApiResult<GeneratedEvents> {
        let events = self.llm
            .events_from_text(text, timezone_offset_minutes)
            .await?;
        Ok(events)
    }

    pub async fn generate_from_audio(&self, audio_bytes: Bytes, timezone_offset_minutes: i32) -> ApiResult<GeneratedEvents> {
        let events = self.llm
            .events_from_audio(&audio_bytes, timezone_offset_minutes)
            .await?;
        Ok(events)
    }

    pub async fn generate_from_image(&self, image_bytes: Bytes, timezone_offset_minutes: i32) -> ApiResult<GeneratedEvents> {
        // parse/validate the image and convert it to JPG
        let img = ImageReader::new(Cursor::new(image_bytes.clone()))
            .with_guessed_format()
            .map_err(|err|{
                tracing::warn!("Got an IO error guessing the image format: {err}");
                ApiError::Internal("Failed to process the image".into())
            })?
            .decode()
            .map_err(|err| {
                tracing::debug!("Failed to decode image (unsupported format or invalid data): {err:?}");
                ApiError::BadRequest("Invalid image format or data was requested".into())
            })?;
        let mut jpg_bytes = Vec::new();
        img.write_to(&mut Cursor::new(&mut jpg_bytes), ImageFormat::Jpeg)
            .map_err(|err| {
                tracing::debug!("Failed to write JPG image: {err:?}");
                ApiError::Internal("Failed to process the image".into())
            })?;
        
        // then request the LLM
        let events = self.llm
            .events_from_image(&jpg_bytes, timezone_offset_minutes)
            .await?;
        Ok(events)
    }
}