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
    is_active BOOLEAN,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
);

CREATE TABLE recurring_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES recurring_event_groups(id),
    title VARCHAR NOT NULL,
    event_description VARCHAR,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    rrule VARCHAR --recurrence rule (check online for format)
);

CREATE TABLE recurring_event_exceptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recurring_event_id NOT NULL REFERENCES recurring_events(id),
);