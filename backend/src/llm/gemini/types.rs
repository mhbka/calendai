//! Types relevant to the Gemini API.
//! Dig around here to see what corresponds to what: https://ai.google.dev/api/generate-content
//! Unused field members are not included for simplicity.

use schemars::Schema;
use serde::{Deserialize, Serialize};
use serde_with::skip_serializing_none;

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Clone, Debug)]
/// A request to Gemini API.
pub struct LLMRequest {
    pub contents: Vec<Content>,
    pub system_instruction: Option<Content>,
    pub generation_config: Option<GenerationConfig>
}

#[derive(Serialize, Deserialize, Clone, Debug)]
/// A response from Gemini API.
pub struct LLMResponse {
    pub candidates: Vec<Candidate>
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct GenerationConfig {
    pub response_mime_type: Option<String>,
    pub response_schema: Schema
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Candidate {
    pub content: Content
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Content {
    pub parts: Vec<Part>,
    pub role: Option<String>
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Part {
    pub thought: Option<bool>,
    pub thought_signature: Option<String>,
    #[serde(flatten)]
    pub data: PartData
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(untagged)]
pub enum PartData {
    Text { text: String },
    InlineData { inline_data: InlineData }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct InlineData {
    pub mime_type: String, 
    pub data: String
}