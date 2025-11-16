use std::{error::Error, time::{Duration, SystemTime, UNIX_EPOCH}};
use serde::{Deserialize, Serialize};
use reqwest::Client;
use std::sync::OnceLock;
use jsonwebtoken::{decode, decode_header, Algorithm, DecodingKey, Validation};

static CLIENT: OnceLock<Client> = OnceLock::new();

#[derive(Serialize)]
struct AzureTokenRefreshRequest<'a> {
    client_id: &'a str,
    client_secret: &'a str,
    refresh_token: &'a str,
    grant_type: &'a str,
    scope: &'a str
}

#[derive(Deserialize)]
pub struct AzureTokenRefreshResponse {
    pub access_token: String,
    pub refresh_token: String
}

#[derive(Debug, Serialize, Deserialize)]
struct AccessTokenClaims {
    exp: usize,
    #[serde(default)]
    aud: Option<String>,
    #[serde(default)]
    iss: Option<String>,
}

/// Obtain a new access token and refresh token from an existing refresh token.
pub async fn refresh_azure_tokens(
    refresh_token: String, // old one is no longer valid after this
    azure_tenant_id: &str,
    azure_client_id: &str,
    azure_client_secret: &str
) -> Result<AzureTokenRefreshResponse, reqwest::Error> {
    let client = CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(Duration::from_secs(10))
            .build()
            .expect("Failed to create client")
    });
    let url = format!("https://login.microsoftonline.com/common/oauth2/v2.0/token");
    let request = AzureTokenRefreshRequest {
        client_id: azure_client_id,
        client_secret: azure_client_secret,
        refresh_token: &refresh_token,
        grant_type: "refresh_token",
        scope: "offline_access https://graph.microsoft.com/.default",
    };
    let response: AzureTokenRefreshResponse = client
        .post(url)
        .form(&request)
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;
    Ok(response)
}


/// Returns `true` if the access token hasn't expired. Errors if unable to parse the token (in which case you should also refresh it).
pub fn is_access_token_valid(access_token: &str) -> Result<bool, Box<dyn Error>> {
    // Decode without validation (we just want to read the claims)
    let mut validation = Validation::new(Algorithm::RS256);
    validation.insecure_disable_signature_validation();
    validation.validate_exp = false; 
    
    let token_data = decode::<AccessTokenClaims>(
        access_token,
        &DecodingKey::from_secret(&[]), // Dummy key since we're not validating
        &validation,
    )?;
    
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)?
        .as_secs() as usize;
    
    Ok(token_data.claims.exp < now)
}