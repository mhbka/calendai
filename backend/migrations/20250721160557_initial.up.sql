CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    title VARCHAR NOT NULL,
    description VARCHAR,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    
    -- Ensure valid time ordering
    CONSTRAINT check_calendar_event_time_order 
        CHECK (start_time < end_time)
);

CREATE TABLE recurring_event_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    group_name VARCHAR NOT NULL,
    description VARCHAR,
    color INT NOT NULL,
    group_is_active BOOLEAN,
    group_recurrence_start TIMESTAMPTZ,
    group_recurrence_end TIMESTAMPTZ,
    
    -- Ensure valid recurrence period ordering if both dates are provided
    CONSTRAINT check_group_recurrence_order
        CHECK (
            group_recurrence_start IS NULL OR 
            group_recurrence_end IS NULL OR 
            group_recurrence_start < group_recurrence_end
        )
);

CREATE TABLE recurring_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES recurring_event_groups(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    title VARCHAR NOT NULL,
    description VARCHAR,
    event_duration_seconds INT NOT NULL,
    recurrence_start TIMESTAMPTZ NOT NULL,
    recurrence_end TIMESTAMPTZ,
    rrule VARCHAR NOT NULL,

    -- Ensure valid time values
    CONSTRAINT check_duration CHECK (event_duration_seconds >= 0),
    
    -- Ensure valid recurrence period ordering if end date is provided
    CONSTRAINT check_recurrence_period_order
        CHECK (
            recurrence_end IS NULL OR 
            recurrence_start < recurrence_end
        )
);

CREATE TABLE recurring_event_exceptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recurring_event_id UUID NOT NULL REFERENCES recurring_events(id),
    exception_date TIMESTAMPTZ NOT NULL,
    exception_type VARCHAR NOT NULL CHECK (exception_type IN ('cancelled', 'modified')),
    
    -- Modified event fields (only populated when exception_type = 'modified')
    modified_title VARCHAR,
    modified_description VARCHAR,
    modified_start_time TIMESTAMPTZ,
    modified_end_time TIMESTAMPTZ,
    
    -- Ensure modified events have required fields populated
    CONSTRAINT check_modified_fields 
        CHECK (
            exception_type != 'modified' OR (
                modified_title IS NOT NULL AND 
                modified_start_time IS NOT NULL AND 
                modified_end_time IS NOT NULL
            )
        ),
    
    -- Ensure cancelled events don't have modification fields
    CONSTRAINT check_cancelled_fields
        CHECK (
            exception_type != 'cancelled' OR (
                modified_title IS NULL AND
                modified_description IS NULL AND
                modified_start_time IS NULL AND
                modified_end_time IS NULL
            )
        ),
    
    -- Ensure modified events have valid time ordering
    CONSTRAINT check_modified_time_order
        CHECK (
            exception_type != 'modified' OR 
            modified_start_time < modified_end_time
        )
);