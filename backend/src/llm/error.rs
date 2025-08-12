use thiserror::Error;

/// Errors that may arise from the Gemini API.
#[derive(Error, Debug)]
pub enum LLMError {
    #[error("Failed to parse into the provided final response type: {0}")]
    ParseIntoFinalResponse(#[from] serde_json::Error),
    #[error("Content received in the response is missing or not of the expected type: {reason}")]
    NoOrWrongContent { reason: String },
    #[error("Failed to parse into Gemini's response type (did the format change?): {0}")]
    ParseIntoGeminiResponse(reqwest::Error),
    #[error("Got a bad status error from request: {0}")]
    BadStatus(reqwest::Error),
    #[error("Failed to request Gemini API: {0}")]
    FailedRequest(reqwest::Error)
}