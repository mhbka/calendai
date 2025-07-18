

use crate::api::AppState;
use super::error::AuthError;
use super::types::{AuthClaims, AuthUser};
use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use axum::Extension;
use axum_extra::headers::authorization::Bearer;
use axum_extra::headers::{Authorization, HeaderMapExt};
use jsonwebtoken::{decode, DecodingKey, Validation};

/// Automatically extracts and verifies an `AuthUser` from a request.
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AuthError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let app_state: Extension<AppState> = Extension::from_request_parts(parts, _state)
            .await
            .expect("AppState should be added as an extension");
        let jwt_secret = &app_state.config.jwt_secret;

        // Extract the token from the authorization header
        let Authorization(bearer) = parts.headers
            .typed_get::<Authorization<Bearer>>()
            .ok_or_else(|| AuthError::Auth)?;

        // HACK: set aud validation to false for now
        let mut validation = Validation::default();
        validation.validate_aud = false;

        // Decode the token
        let token_data = decode::<AuthClaims>(
            bearer.token(),
            &DecodingKey::from_secret(jwt_secret.as_bytes()),
            &validation,
        ).map_err(|e| {
            tracing::info!("Failed to decode auth claims: {:?}", e.kind());
            AuthError::InvalidToken
        })?;

        // Extract user data from claims
        let claims = token_data.claims;
        
        Ok(AuthUser {
            id: claims.sub,
            email: claims.email,
            name: claims.name,
            picture: claims.picture,
        })
    }
}