use serde::{Deserialize, Deserializer, Serialize};
use sqlx::{postgres::{PgArgumentBuffer, PgHasArrayType, PgTypeInfo, PgValueRef}, Decode, Encode, Postgres};

/// A u8 between 0-23.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize)]
pub struct Hour(u8);

impl Hour {
    pub fn new(value: u8) -> Result<Self, ()> {
        if value <= 23 {
            Ok(Hour(value))
        } else {
            Err(())
        }
    }

    pub fn value(self) -> u8 {
        self.0
    }
}

/// A u8 between 0-59.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize)]
pub struct Minute(u8);

impl Minute {
    pub fn new(value: u8) -> Result<Self, ()> {
        if value <= 59 {
            Ok(Minute(value))
        } else {
            Err(())
        }
    }

    pub fn value(self) -> u8 {
        self.0
    }
}

/// A u32 wrapper.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct Second(pub u32);

//
// deserialization
//

impl<'de> Deserialize<'de> for Hour {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = u8::deserialize(deserializer)?;
        Hour::new(value)
            .map_err(|e| "Value is outside of 0-23")
            .map_err(serde::de::Error::custom)
    }
}

impl<'de> Deserialize<'de> for Minute {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = u8::deserialize(deserializer)?;
        Minute::new(value)
            .map_err(|e| "Value is outside of 0-59")
            .map_err(serde::de::Error::custom)
    }
}

//
// sqlx
//

impl sqlx::Type<Postgres> for Hour {
    fn type_info() -> PgTypeInfo {
        <i16 as sqlx::Type<Postgres>>::type_info()
    }
}

impl Encode<'_, Postgres> for Hour {
    fn encode_by_ref(&self, buf: &mut PgArgumentBuffer) -> Result<sqlx::encode::IsNull, sqlx::error::BoxDynError> {
        <i16 as Encode<Postgres>>::encode_by_ref(&(self.0 as i16), buf)
    }
}

impl Decode<'_, Postgres> for Hour {
    fn decode(value: PgValueRef<'_>) -> Result<Self, sqlx::error::BoxDynError> {
        let raw_value = <i16 as Decode<Postgres>>::decode(value)?;
        if raw_value < 0 || raw_value > 23 {
            return Err(format!("Hour value {} is out of range (0-23)", raw_value).into());
        }
        Ok(Hour(raw_value as u8))
    }
}

impl sqlx::Type<Postgres> for Minute {
    fn type_info() -> PgTypeInfo {
        <i16 as sqlx::Type<Postgres>>::type_info()
    }
}

impl Encode<'_, Postgres> for Minute {
    fn encode_by_ref(&self, buf: &mut PgArgumentBuffer) -> Result<sqlx::encode::IsNull, sqlx::error::BoxDynError> {
        <i16 as Encode<Postgres>>::encode_by_ref(&(self.0 as i16), buf)
    }
}

impl Decode<'_, Postgres> for Minute {
    fn decode(value: PgValueRef<'_>) -> Result<Self, sqlx::error::BoxDynError> {
        let raw_value = <i16 as Decode<Postgres>>::decode(value)?;
        if raw_value < 0 || raw_value > 59 {
            return Err(format!("Minute value {} is out of range (0-59)", raw_value).into());
        }
        Ok(Minute(raw_value as u8))
    }
}

impl sqlx::Type<Postgres> for Second {
    fn type_info() -> PgTypeInfo {
        <i32 as sqlx::Type<Postgres>>::type_info()
    }
}

impl Encode<'_, Postgres> for Second {
    fn encode_by_ref(&self, buf: &mut PgArgumentBuffer) -> Result<sqlx::encode::IsNull, sqlx::error::BoxDynError> {
        <i32 as Encode<Postgres>>::encode_by_ref(&(self.0 as i32), buf)
    }
}

impl Decode<'_, Postgres> for Second {
    fn decode(value: PgValueRef<'_>) -> Result<Self, sqlx::error::BoxDynError> {
        let raw_value = <i32 as Decode<Postgres>>::decode(value)?;
        Ok(Second(raw_value as u32))
    }
}

impl PgHasArrayType for Second {
    fn array_type_info() -> PgTypeInfo {
        <i32 as sqlx::Type<Postgres>>::type_info()
    }
}

