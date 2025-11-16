use crate::api::AppState;
use super::error::AuthError;
use super::types::{AuthClaims, AuthUser};
use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use axum_extra::headers::authorization::Bearer;
use axum_extra::headers::{Authorization, HeaderMapExt};
use jsonwebtoken::{decode, DecodingKey, Validation};

/// Automatically extracts and verifies an `AuthUser` from a request.
impl FromRequestParts<AppState> for AuthUser
{
    type Rejection = AuthError;

    async fn from_request_parts(parts: &mut Parts, app_state: &AppState) -> Result<Self, Self::Rejection> {
        let jwt_secret = &app_state.config.jwt_secret;

        // Extract the token from the authorization header
        let Authorization(bearer) = parts.headers
            .typed_get::<Authorization<Bearer>>()
            .ok_or_else(|| {
                tracing::debug!("failed to extract Bearer token; headers: {:?}", parts.headers);
                AuthError::Auth
            })?;
        tracing::trace!("Successfully extracted bearer token");

        // HACK: set aud validation to false for now
        let mut validation = Validation::default();
        validation.validate_aud = false;

        // Decode the token
        let token_data = decode::<AuthClaims>(
            bearer.token(),
            &DecodingKey::from_secret(jwt_secret.as_bytes()),
            &validation,
        ).map_err(|e| {
            tracing::debug!("Failed to decode auth claims: {:?}", e.kind());
            AuthError::InvalidToken
        })?;
        tracing::trace!("Successfully decoded auth claims");

        // Extract user data from claims
        let claims = token_data.claims;

        // Obtain user's Azure refresh token
        let azure_refresh_token = parts.headers
            .get("Azure-Refresh-Token")
            .filter(|h| !h.is_empty())
            .ok_or(AuthError::MissingOrInvalidAzureRefreshToken)?
            .to_str()
            .map_err(|_| AuthError::MissingOrInvalidAzureRefreshToken)?
            .to_owned();
        tracing::trace!("Successfully extracted Azure refresh token");
        
        Ok(AuthUser {
            id: claims.sub,
            email: claims.email,
            name: claims.name,
            picture: claims.picture,
            azure_refresh_token
        })
    }
}