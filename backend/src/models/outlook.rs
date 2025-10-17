//! API reference: https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0
//! 
//! Types only contain fields we need.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Represents an Outlook email message.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookMailMessage {
    pub id: String,
    pub subject: String,
    pub from: OutlookMailRecipient,
    pub body_preview: String,
    pub body: String,
    pub sent_date_time: DateTime<Utc>
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutlookMailRecipient {
    pub email_address: OutlookEmail
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OutlookEmail {
    pub address: String,
    pub name: String
}