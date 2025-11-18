use std::str::FromStr;

use chrono::NaiveDateTime;
use serde::{self, Deserialize, Deserializer};
use windows_timezones::WindowsTimezone;

const FORMAT: &str = "%Y-%m-%dT%H:%M:%S%.f";

pub fn deserialize_naive_dt<'de, D>(deserializer: D) -> Result<NaiveDateTime, D::Error>
where
    D: Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?;
    NaiveDateTime::parse_from_str(&s, FORMAT)
        .map_err(serde::de::Error::custom)
}

pub fn deserialize_windows_tz<'de, D>(deserializer: D) -> Result<WindowsTimezone, D::Error>
where
    D: Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?;
    WindowsTimezone::from_str(&s)
        .map_err(serde::de::Error::custom)
}
