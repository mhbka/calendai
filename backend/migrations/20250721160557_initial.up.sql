-- Add up migration script here
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    title VARCHAR NOT NULL,
    event_description VARCHAR,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL
);

CREATE TABLE recurring_event_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    group_name VARCHAR NOT NULL,
    group_description VARCHAR,
    color INT NOT NULL,
    group_is_active BOOLEAN,
    group_recurrence_start TIMESTAMP,
    group_recurrence_end TIMESTAMP
);

CREATE TABLE recurring_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES recurring_event_groups(id),
    is_active BOOLEAN NOT NULL,
    title VARCHAR NOT NULL,
    event_description VARCHAR,
    recurrence_start TIMESTAMP NOT NULL,
    recurrence_end TIMESTAMP,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    rrule VARCHAR NOT NULL
);

CREATE TABLE recurring_event_exceptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recurring_event_id UUID NOT NULL REFERENCES recurring_events(id),
    exception_date TIMESTAMP NOT NULL,
    exception_type VARCHAR NOT NULL CHECK (exception_type IN ('cancelled', 'modified')),
    modified_event_id UUID REFERENCES calendar_events(id)
);