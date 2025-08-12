use reqwest::Client;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use base64::prelude::*;
use types::{Content, GenerationConfig, InlineData, LLMRequest, LLMResponse, Part, PartData};
use schema::GeminiSchema;
use crate::llm::error::LLMError;

pub(crate) mod types;
mod schema;

static API_PREFIX: &str = "https://generativelanguage.googleapis.com/v1beta";

/// Used for requesting the Gemini API.
#[derive(Clone, Debug)]
pub struct GeminiLLM {
    endpoint: String,
    client: Client
}

impl GeminiLLM {
    /// Instantiate the struct.
    pub fn new(api_key: &String, model: &String) -> Self {
        Self {
            endpoint: Self::build_api_string(model, api_key),
            client: Client::new()
        }
    }

    /// Send a simple text query, decoding the response as `Res`.
    pub async fn request_text<Res>(
        &self, 
        text: String, 
        system_instruction: Option<String>
    ) -> Result<Res, LLMError>
    where Res: GeminiSchema 
    {
        let request = self.build_text_request::<Res>(text, system_instruction);
        self.handle_request(request).await
    }

    /// Send a JPEG image and a text query, decoding the response as `Res`.
    pub async fn request_image<Res>(
        &self, 
        image_bytes: &[u8], 
        system_instruction: Option<String>,
        request_text: String
    ) -> Result<Res, LLMError>
    where Res: GeminiSchema
    {
        self.request_inline_data(image_bytes, "image/jpeg", request_text, system_instruction).await
    }

    /// Send an MP3 audio and a text query, decoding the response as `Res`.
    pub async fn request_audio<Res>(
        &self, 
        audio_bytes: &[u8], 
        system_instruction: Option<String>,
        request_text: String
    ) -> Result<Res, LLMError>
    where Res: GeminiSchema
    {
        self.request_inline_data(audio_bytes, "audio/mp3", request_text, system_instruction).await
    }

    /// Send inline data and a text query, decoding the response as `Res`.
    async fn request_inline_data<Res>(
        &self, 
        inline_bytes: &[u8], 
        mime_type: &'static str, 
        request_text: String,
        system_instruction: Option<String>
    ) -> Result<Res, LLMError>
    where Res: GeminiSchema
    {
        let request = self.build_inline_data_request::<Res>(
            inline_bytes, 
            mime_type, 
            request_text, 
            system_instruction
        );
        self.handle_request(request).await
    }

    /// Handles running and decoding a query to the LLM.
    async fn handle_request<Res>(&self, request: LLMRequest) -> Result<Res, LLMError>
    where Res: GeminiSchema
    {
        match self.client
            .post(&self.endpoint)
            .json(&request)
            .send()
            .await
        {
            Ok(res) => {
                match res.error_for_status() {
                    Ok(res) => {
                        match res.json::<LLMResponse>().await {
                            Ok(res) => {
                                if res.candidates.len() == 0 || res.candidates[0].content.parts.len() == 0 {
                                    return Err(LLMError::NoOrWrongContent { reason: "No candidates, or candidate had no part".into() });
                                }
                                match &res.candidates[0].content.parts[0].data {
                                    PartData::Text { text } =>  {
                                        let res = serde_json::from_str::<Res>(&text)?;
                                        return Ok(res);
                                    },
                                    other => return Err(LLMError::NoOrWrongContent { reason: format!("Received unexpected PartData: {other:?}") })
                                }
                            },
                            Err(err) => return Err(LLMError::ParseIntoGeminiResponse(err))
                        }
                    },
                    Err(err) => return Err(LLMError::BadStatus(err))
                }
            },  
            Err(err) => return Err(LLMError::FailedRequest(err))
        }
    }

    /// Builds a text query's request.
    fn build_text_request<Res>(&self, text: String, system_instruction: Option<String>) -> LLMRequest
    where 
        Res: Serialize + for<'a> Deserialize<'a> + JsonSchema
    {
        let contents = self.build_text_content(text);
        let system_instruction = self.build_system_instruction(system_instruction);
        let generation_config = self.build_generation_config::<Res>();
        LLMRequest {
            contents,
            system_instruction,
            generation_config
        }
    }

    /// Builds an inline data + text request.
    fn build_inline_data_request<Res>(
        &self, 
        inline_bytes: &[u8], 
        mime_type: &'static str, 
        request_text: String,
        system_instruction: Option<String>
    ) -> LLMRequest
    where Res: GeminiSchema 
    {
        let contents = self.build_inline_data_content(&inline_bytes, mime_type, request_text);
        let system_instruction = self.build_system_instruction(system_instruction);
        let generation_config = self.build_generation_config::<Res>();
        LLMRequest {
            contents,
            system_instruction,
            generation_config
        }
    }

    /// Builds the content for a text query.
    fn build_text_content(&self, text: String) -> Vec<Content> {
        let parts = vec![Part { 
            thought: None, 
            thought_signature: None, 
            data: PartData::Text { text }
        }];
        vec![Content { parts, role: None }]
    }

    /// Builds the content for an inline data + text request.
    fn build_inline_data_content(
        &self, 
        bytes: &[u8], 
        mime_type: &'static str,
        request_text: String
    ) -> Vec<Content> {
        let encoded_bytes = BASE64_STANDARD.encode(bytes);
        let inline_data = InlineData { mime_type: mime_type.into(), data: encoded_bytes };
        let parts = vec![
            Part { 
                thought: None, 
                thought_signature: None, 
                data: PartData::InlineData { inline_data }
            },
            Part { 
                thought: None, 
                thought_signature: None, 
                data: PartData::Text { text: request_text }
            }
        ];
        vec![Content { parts, role: None }]
    }

    /// Builds an optional system instruction for a request.
    fn build_system_instruction(&self, system_instruction: Option<String>) -> Option<Content> {
        if let Some(instruction) = system_instruction {
            Some(
                Content {
                    parts: vec![Part { 
                        thought: None, 
                        thought_signature: None, 
                        data: PartData::Text { text: instruction }
                    }],
                    role: None
                }
            )
        }
        else {
            None
        }
    }

    /// Builds an optional generation config for a request.
    fn build_generation_config<Res>(&self) -> Option<GenerationConfig>
    where Res: GeminiSchema
    {
        Some(
            GenerationConfig { 
                response_mime_type: Some("application/json".into()),
                response_schema: Res::generate_gemini_schema() 
            }
        )
    }

    /// Builds the API string.
    fn build_api_string(model: &String, api_key: &String) -> String {
        format!("{API_PREFIX}/models/{model}:generateContent?key={api_key}")
    }
}