CREATE TABLE sync_state (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    delta_link TEXT NOT NULL,
    last_sync TIMESTAMPTZ NOT NULL
);

CREATE TABLE outlook_event_mappings (
    local_event_id UUID PRIMARY KEY,
    outlook_event_id TEXT NOT NULL
);