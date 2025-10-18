use graph_rs_sdk::Graph;
use serde::{Deserialize, Serialize};
use crate::{api::error::ApiResult, llm::{GeneratedEvents, LLM}, models::outlook::OutlookMailMessage};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct OutlookListEmailsResponse {
    value: Vec<OutlookMailMessage>
}

/// Service for interacting with Outlook (or generally Microsoft Graph API).
#[derive(Clone, Debug)]
pub struct OutlookService {
    llm: LLM
}

impl OutlookService {
    pub fn new(llm: LLM) -> Self {
        Self {
            llm
        }
    }

    pub async fn fetch_user_emails(&self, access_token: &str) -> ApiResult<OutlookListEmailsResponse> {
        let client = Graph::new(access_token);

        let messages = client.me()
            .messages()
            .list_messages()
            .send()
            .await?
            .json::<OutlookListEmailsResponse>()
            .await?;

        Ok(messages)
    }

    pub async fn generate_events_from_user_email(&self, access_token: &str, mail_id: &str, timezone_offset_minutes: i32) -> ApiResult<GeneratedEvents> {
        let client = Graph::new(access_token);

        let chosen_email = client.me()
            .message(mail_id)
            .get_messages()
            .send()
            .await?
            .json::<OutlookMailMessage>()
            .await?;

        // TODO: we only parse the body and ignore any attachments and images; is this fine?
        let generated_events = self.llm
            .events_from_text(chosen_email.body, timezone_offset_minutes)
            .await?;
        
        Ok(generated_events)
    }
}