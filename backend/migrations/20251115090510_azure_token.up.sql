CREATE TABLE azure_tokens (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    encrypted_refresh_token TEXT NOT NULL,
    encrypted_access_token TEXT NOT NULL
);