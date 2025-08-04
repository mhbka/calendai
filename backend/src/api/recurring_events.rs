use std::collections::HashSet;
use axum::{extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::{DateTime, Duration, Utc};
use serde::Deserialize;
use uuid::Uuid;
use crate::models::{recurring_event::UpdatedRecurringEvent, recurring_event_group::RecurringEventGroup};
use crate::models::time::Second;
use crate::{api::{auth::types::AuthUser, error::{ApiError, ApiResult}, AppState}, models::{recurring_event::{NewRecurringEvent, RecurringCalendarEvent, RecurringEvent}, recurring_event_exception::ExceptionType}};
use crate::models::rrule::ValidatedRRule;
use crate::models::recurring_event_exception::RecurringEventException;

/// The query params for querying events.
#[derive(Deserialize)]
struct EventsQuery {
    start: DateTime<Utc>,
    end: DateTime<Utc>
}

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_events))
        .route("/", get(get_events))
        .route("/", put(update_event))
        .route("/{event_id}", delete(delete_event))
}

async fn create_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(events): Json<Vec<NewRecurringEvent>>
) -> ApiResult<()> {
    let mut group_ids = Vec::with_capacity(events.len());
    let user_ids = vec![user.id; events.len()];
    let mut titles = Vec::with_capacity(events.len());
    let mut descriptions = Vec::with_capacity(events.len());
    let mut locations = Vec::with_capacity(events.len());
    let mut durations = Vec::with_capacity(events.len());
    let mut recurrence_starts = Vec::with_capacity(events.len());
    let mut recurrence_ends = Vec::with_capacity(events.len());
    let mut rrules = Vec::with_capacity(events.len());
    for event in events {
        group_ids.push(event.group_id);
        titles.push(event.title);
        descriptions.push(event.description);
        locations.push(event.location);
        durations.push(event.event_duration_seconds.0 as i32);
        recurrence_starts.push(event.recurrence_start);
        recurrence_ends.push(event.recurrence_end);
        rrules.push(event.rrule.to_string());
    }

    let all_groups_authorized = {
        let requested_group_ids: Vec<_> = group_ids
            .iter()
            .filter(|&g| g.is_some())
            .map(|g| g.clone())
            .collect();
        let authorized_groups = sqlx::query!(
            r#"
                select id from recurring_event_groups 
                where id = any($1) and user_id = $2
            "#,
            &requested_group_ids[..] as &[Option<Uuid>],
            user.id
        )
            .fetch_all(&app_state.db)
            .await?;
        authorized_groups.len() == requested_group_ids.len()
    };
    if !all_groups_authorized {
        return Err(ApiError::Forbidden);
    }
    
    sqlx::query!(
        r#"
            insert into recurring_events
            (group_id, user_id, title, description, location, event_duration_seconds, recurrence_start, recurrence_end, rrule)
            select * from unnest
            ($1::uuid[], $2::uuid[], $3::varchar[], $4::varchar[], $5::varchar[], $6::int[], $7::timestamptz[], $8::timestamptz[], $9::varchar[])
        "#,
        &group_ids[..] as &[Option<Uuid>],
        &user_ids[..],
        &titles[..],
        &descriptions[..] as &[Option<String>],
        &locations[..] as &[Option<String>],
        &durations[..],
        &recurrence_starts[..],
        &recurrence_ends[..] as &[Option<DateTime<Utc>>],
        &rrules[..]
    )
        .execute(&app_state.db)
        .await?;
    Ok(())
}

async fn get_events(
    State(app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<RecurringCalendarEvent>>> {
    // fetch active recurring events within start/end dates
    let recurring_events: Vec<RecurringEvent> = sqlx::query_as!(
        RecurringEvent,
        r#"
            SELECT 
                re.id, 
                re.group_id, 
                re.user_id,
                re.is_active, 
                re.title, 
                re.description, 
                re.location, 
                re.recurrence_start, 
                re.recurrence_end, 
                re.event_duration_seconds as "event_duration_seconds: _", 
                re.rrule as "rrule: _"
            FROM recurring_events re
            INNER JOIN recurring_event_groups reg ON reg.id = re.group_id
            WHERE reg.user_id = $1 AND re.recurrence_start > $2 AND re.recurrence_end < $3 AND re.is_active = true
        "#,
        user.id,
        params.start,
        params.end
    )
        .fetch_all(&app_state.db)
        .await?;

    // get actual event instances
    let mut events_and_instances: Vec<_> = recurring_events
        .into_iter()
        .map(|event| {
            let instances = event.rrule.all_within_period(params.start, params.end);
            (event, instances)
        })
        .collect();

    // get exceptions within start/end dates
    let mut event_exceptions: Vec<RecurringEventException> = {
        let event_ids: Vec<_> = events_and_instances.iter().map(|(e, _)| e.id).collect();
        sqlx::query_as!(
            RecurringEventException,
            r#"
                SELECT 
                    id, 
                    recurring_event_id, 
                    exception_date, 
                    exception_type as "exception_type: _",
                    modified_title,
                    modified_description,
                    modified_location,
                    modified_start_time,
                    modified_end_time
                FROM recurring_event_exceptions ree
                WHERE ree.recurring_event_id = ANY($1)
            "#,
            &event_ids
        )
            .fetch_all(&app_state.db)
            .await?      
    };

    // resolve events' instances and exceptions
    let mut instances_with_group_ids = Vec::new();
    for (event, instances) in &mut events_and_instances {
        // first, extract exceptions for this event
        let relevant_exceptions: Vec<_> = event_exceptions
            .extract_if(.., |exception| {
                if exception.recurring_event_id == event.id {
                    return instances.dates
                        .iter()
                        .any(|d| d.to_utc() == exception.exception_date);
                }
                false
            })
            .collect();

        // delete all "cancelled" instances
        instances.dates.retain(|date| relevant_exceptions
                .iter()
                .any(|e| e.exception_type == ExceptionType::Cancelled && e.exception_date == date.to_utc())
            );

        // create the actual calendar events
        let mut calendar_events: Vec<_> = instances.dates
            .iter()
            .map(|date| RecurringCalendarEvent {
                recurring_event_id: event.id,
                title: event.title.clone(),
                description: event.description.clone(),
                location: event.location.clone(),
                start_time: date.to_utc(),
                end_time: date.to_utc() + Duration::seconds(event.event_duration_seconds.0.into()),
                exception_id: None,
                group: None
            })
            .collect();

        // replace any "modified" exceptions' metadata
        for exception in relevant_exceptions {
            if let ExceptionType::Modified = exception.exception_type {
                if let Some(event) = calendar_events
                    .iter_mut()
                    .find(|e| e.start_time == exception.exception_date)
                {   
                    // **NOTE**: if more modifiable metadata is added to recurring events, they should be replaced here as well
                    if let Some(modified_title) = exception.modified_title { event.title = modified_title; }
                    if let Some(modified_description) = exception.modified_description { event.description = modified_description; }
                    if let Some(modified_start) = exception.modified_start_time { event.start_time = modified_start; }
                    if let Some(modified_end) = exception.modified_end_time { event.end_time = modified_end; }
                }
            }
        };

        // collect calendar events + group IDs
        instances_with_group_ids.push((event.group_id, calendar_events));
    }

    // don't query for groups whose events have 0 instances
    instances_with_group_ids.retain(|(g, i)| i.len() > 0);

    // get group data for remaining instances
    let group_ids: Vec<_> = instances_with_group_ids
        .iter()
        .map(|(g, _)| *g)
        .collect::<HashSet<_>>()
        .into_iter()
        .collect();
    let groups: Vec<RecurringEventGroup> = sqlx::query_as!(
        RecurringEventGroup,
        r#"
            SELECT *
            FROM recurring_event_groups
            WHERE id = ANY($1)
        "#,
        &group_ids as &[Option<Uuid>]
    )
        .fetch_all(&app_state.db)
        .await?;

    // fill in group data for instances
    for (group_id, events) in &mut instances_with_group_ids {
        if let Some(group) = groups.iter().find(|&g| Some(g.id) == *group_id) {
            for event in events {
                event.group = Some(group.clone());
            }
        }
    }   

    // concatenate all events and return
    let events: Vec<_> = instances_with_group_ids
        .into_iter()
        .map(|(_, events)| events)
        .flatten()
        .collect();

    Ok(Json(events))
}

async fn update_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_event): Json<UpdatedRecurringEvent>
) -> ApiResult<()> {
    let event_record = sqlx::query!(
        r#"
            SELECT recurring_event_groups.user_id
            FROM recurring_events 
            INNER JOIN recurring_event_groups ON recurring_events.group_id = recurring_event_groups.id
            WHERE recurring_events.id = $1
        "#,
        updated_event.id
    )
        .fetch_one(&app_state.db)
        .await?;
    if event_record.user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    else {
        sqlx::query!(
            r#"
                update recurring_events
                set 
                    title = $1,
                    group_id = $2,
                    description = $3,
                    location = $4,
                    event_duration_seconds = $5,
                    recurrence_start = $6,
                    recurrence_end = $7,
                    rrule = $8
                where id = $9
            "#,
            updated_event.title,
            updated_event.group_id,
            updated_event.description,
            updated_event.location,
            updated_event.event_duration_seconds as Second,
            updated_event.recurrence_start,
            updated_event.recurrence_end,
            updated_event.rrule as ValidatedRRule,
            updated_event.id
        )
            .execute(&app_state.db)
            .await?;
        Ok(())
    }
}

async fn delete_event(
    State(app_state): State<AppState>,
    Path(event_id): Path<Uuid>,
    user: AuthUser
) -> ApiResult<()> {
    let event_record = sqlx::query!(
        r#"
            select recurring_event_groups.user_id
            from recurring_events 
            inner join recurring_event_groups on recurring_events.group_id = recurring_event_groups.id
            where recurring_events.id = $1
        "#,
        event_id
    )
        .fetch_one(&app_state.db)
        .await?;
    if event_record.user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    else {
        sqlx::query!(
            r#"delete from recurring_events where id = $1"#,
            event_id
            )
            .execute(&app_state.db)
            .await?;
        Ok(())
    }
}