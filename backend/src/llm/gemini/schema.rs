use schemars::{generate::SchemaSettings, JsonSchema, Schema, SchemaGenerator};
use serde::{Deserialize, Serialize};

/// Trait for generating a Gemini API-compliant schema.
/// Used if we want the Gemini response to follow a certain schema.
pub trait GeminiSchema: Serialize + for<'a> Deserialize<'a> + JsonSchema {
    /// Generate the schema.
    fn generate_gemini_schema() -> Schema {
        let settings = SchemaSettings::openapi3().with(|s| s.meta_schema = None);
        let generator = SchemaGenerator::new(settings);
        let schema = generator.into_root_schema_for::<Self>();
        return schema;
    } 
}

/// Blanket implement it
impl<T: Serialize + for<'a> Deserialize<'a> + JsonSchema> GeminiSchema for T {}