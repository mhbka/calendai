use axum::body::Bytes;

static GOOGLE_ENDPOINT: &str = "https://generativelanguage.googleapis.com/v1beta/";

pub struct LLM {

}

impl LLM {
    pub async fn events_from_text(text: String) -> GeneratedEvents {

    }

    pub async fn events_from_audio(blob: Bytes) -> GeneratedEvents {

    }

    pub async fn events_from_image() -> GeneratedEvents {
        
    }
}