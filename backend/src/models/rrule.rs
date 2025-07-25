use std::str::FromStr;
use chrono::{DateTime, TimeZone, Utc};
use rrule::{RRuleError, RRuleResult, RRuleSet, Tz};
use serde::{Deserialize, Serialize};
use sqlx::{postgres::PgHasArrayType, Database, Decode, Encode, Type};

static INSTANCE_LIMIT: u16 = 100;

/// A wrapper around a `RRuleSet`, with serde + deserialization-time validation + sqlx support.
#[derive(Debug, Clone, Serialize)]
pub struct ValidatedRRule {
    rrule: RRuleSet
}

impl ValidatedRRule {
    /// Returns all instances of the reccurence rule within the start/end dates.
    /// 
    /// **Note**: The maximum number of instances is set to 100 (for now).
    pub fn all_within_period(&self, start: DateTime<Utc>, end: DateTime<Utc>) -> RRuleResult {
        // 
        let start = Tz::from_utc_datetime(&Tz::UTC, &start.naive_utc());
        let end = Tz::from_utc_datetime(&Tz::UTC, &end.naive_utc());
        let restricted_rrule = self.rrule
            .clone()
            .after(start)
            .before(end);
        restricted_rrule.all(INSTANCE_LIMIT)
    }   
}

// For inputting into sqlx as a string
impl<'q, DB: Database> Encode<'q, DB> for ValidatedRRule
where 
    String: sqlx::Encode<'q, DB>
{
    fn encode_by_ref(
        &self,
        buf: &mut <DB as sqlx::Database>::ArgumentBuffer<'q>,
    ) -> Result<sqlx::encode::IsNull, sqlx::error::BoxDynError> {
        let s = self.to_string();
        <String as sqlx::Encode<'_, DB> >::encode_by_ref(&s, buf)
    }
}

// For fetching from sqlx as a string
impl<'r, DB: Database> Decode<'r, DB> for ValidatedRRule
where
    &'r str: Decode<'r, DB>
{
    fn decode(value: <DB as sqlx::Database>::ValueRef<'r>) -> Result<Self, sqlx::error::BoxDynError> {
        let value = <&str as Decode<DB>>::decode(value)?;
        let rrule = ValidatedRRule::from_str(value)?;
        Ok(rrule)
    }
}

// Represent it as a string in sqlx
impl<DB: Database> Type<DB> for ValidatedRRule
where 
    String: Type<DB>  {
    fn type_info() -> DB::TypeInfo {
        <String as Type<DB>>::type_info()
    }
}

// allows to insert arrays of it
impl PgHasArrayType for ValidatedRRule {
    fn array_type_info() -> sqlx::postgres::PgTypeInfo {
        <&str as PgHasArrayType>::array_type_info()
    }
}

// Shift validation into the deserialization
impl<'de> Deserialize<'de> for ValidatedRRule {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de> 
    {
        let s = String::deserialize(deserializer)?;
        let rrule: RRuleSet = s
            .parse()
            .map_err(|e| serde::de::Error::custom(format!("Failed to parse into RRuleSet: {}", e)))?;
        Ok(Self { rrule })
    }
}

impl FromStr for ValidatedRRule {
    type Err = RRuleError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let rrule: RRuleSet = s.parse()?;
        Ok(Self { rrule })
    }
}

impl ToString for ValidatedRRule {
    fn to_string(&self) -> String {
        self.rrule.to_string()
    }
}