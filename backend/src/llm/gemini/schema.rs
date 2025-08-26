use schemars::{generate::SchemaSettings, transform::{transform_subschemas, AddNullable, RemoveRefSiblings, Transform}, JsonSchema, Schema, SchemaGenerator};
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Number, Value};

/// Trait for generating a Gemini API-compliant schema.
/// Used if we want the Gemini response to follow a certain schema.
pub trait GeminiSchema: Serialize + for<'a> Deserialize<'a> + JsonSchema {
    /// Generate the schema.
    fn generate_gemini_schema() -> Schema {
        let settings = SchemaSettings::openapi3()
            .with(|s| {
                s.meta_schema = None;
                s.inline_subschemas = true;
            })
            .with_transform(GeminiTransform {});
        let generator = SchemaGenerator::new(settings);
        let schema = generator.into_root_schema_for::<Self>();

        tracing::info!("Schema: {}", serde_json::to_string_pretty(&schema).unwrap());
        return schema;
    } 
}

/// Blanket implement it
impl<T: Serialize + for<'a> Deserialize<'a> + JsonSchema> GeminiSchema for T {}

/// Schema transforms required by the Gemini API.
#[derive(Clone, Debug)]
pub struct GeminiTransform {}

impl Transform for GeminiTransform {
    fn transform(&mut self, schema: &mut Schema) {
        //self.remove_ref(schema);
        self.convert_unsigned(schema);
        self.remove_uuid_format(schema);
        self.type_array_to_anyof(schema);
        transform_subschemas(self, schema);
    }
}

impl GeminiTransform {
    /// Converts unsigned ints to signed (somehow API doesn't support it).
    fn convert_unsigned(&self, schema: &mut Schema) {
        if let Some(value) = schema.get_mut("format") {
            if let Some("uint32") = value.as_str() {
                *value = Value::String("int32".into());
                schema.insert("minimum".into(), Value::Number(Number::from_i128(0).unwrap()));
            }
        }
    }

    /// Remove 'uuid' format.
    fn remove_uuid_format(&self, schema: &mut Schema) {
        if let Some(value) = schema.get("format") {
            if let Some("uuid") = value.as_str() {
                schema.remove("format");
            }
        }
    }

    /// If a type array is present, convert it to `anyOf`.
    fn type_array_to_anyof(&self, schema: &mut Schema) {  
    if let Some(type_value) = schema.get("type") {
        if let Value::Array(type_array) = type_value {
            // Create anyOf from type array
            let any_of: Vec<Value> = type_array.iter()
                .map(|t| {
                    let mut obj = Map::new();
                    obj.insert("type".to_string(), t.clone());
                    
                    // If one of the types is "null", mark as nullable
                    if t.as_str() == Some("null") {
                        obj.insert("nullable".to_string(), Value::Bool(true));
                        // Use the non-null type
                        if let Some(non_null_type) = type_array.iter().find(|&t| t.as_str() != Some("null")) {
                            obj.insert("type".to_string(), non_null_type.clone());
                        }
                    }
                    Value::Object(obj)
                })
                .collect();
            schema.remove("type");
            schema.insert("anyOf".to_string(), Value::Array(any_of));
            }
        }
    }

    fn remove_ref(&self, schema: &mut Schema) {
        if let Some(obj) = schema.as_object_mut().filter(|o| o.len() > 1) {
            if let Some(ref_value) = obj.remove("$ref") {
                if let Value::Array(all_of) = obj.entry("allOf").or_insert(Value::Array(Vec::new()))
                {
                    all_of.push(json!({
                        "$ref": ref_value
                    }));
                }
            }
        }
    }
}