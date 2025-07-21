use std::str::FromStr;
use chrono::{TimeZone, Utc};
use rrule::{RRule, RRuleError, Tz, Unvalidated, Validated};
use serde::{Deserialize, Serialize};
use serde_json::from_str;
use sqlx::{Database, Decode, Encode, Type};

/// A wrapper around `RRule`, with serde + deserialization-time validation + sqlx support.
#[derive(Debug, Clone, Serialize)]
pub struct ValidatedRRule {
    rrule: RRule<Validated>
}

impl ValidatedRRule {
    /// Validate the `RRule` with the current time. 
    /// 
    /// TODO: when will validation fail when using the current time?
    fn validate_with_now(unvalidated: RRule<Unvalidated>) -> Result<Self, RRuleError> {
        let tz: Tz = Tz::UTC;
        let now = tz.from_utc_datetime(&Utc::now().naive_utc());
        let validated = unvalidated.validate(now)?;
        Ok(ValidatedRRule { rrule: validated })
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

impl<DB: Database> Type<DB> for ValidatedRRule
where 
    String: Type<DB>  {
    fn type_info() -> DB::TypeInfo {
        <String as Type<DB>>::type_info()
    }
}

// This shifts the validation into the deserialization.
// However I'm not sure if it makes sense yet.
impl<'de> Deserialize<'de> for ValidatedRRule {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de> 
    {
        let s = String::deserialize(deserializer)?;
        let unvalidated: RRule<Unvalidated> = s
            .parse()
            .map_err(|e| serde::de::Error::custom(format!("Failed to parse RRule: {}", e)))?;
        let validated = ValidatedRRule::validate_with_now(unvalidated)
            .map_err(|e| serde::de::Error::custom(format!("Failed to validated RRule: {}", e)))?;
        Ok(validated)
    }
}

impl FromStr for ValidatedRRule {
    type Err = sqlx::error::BoxDynError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let unvalidated: RRule<Unvalidated> = from_str(s).map_err(|e| Box::new(e))?;
        Ok(ValidatedRRule::validate_with_now(unvalidated).map_err(|e| Box::new(e))?)
    }
}

impl ToString for ValidatedRRule {
    fn to_string(&self) -> String {
        self.rrule.to_string()
    }
}

impl From<String> for ValidatedRRule {
    
}