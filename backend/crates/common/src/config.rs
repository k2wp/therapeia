use dotenvy::dotenv;
use std::env;

#[derive(Clone)]
pub struct AppConfig {
    pub db_url: String,
    pub jwt_secret: String,
    pub bind_addr: String,
    pub env: String,
}

impl AppConfig {
    pub fn from_env() -> Self {
        let _ = dotenv();
        Self {
            db_url: env::var("DATABASE_URL").expect("DATABASE_URL"),
            jwt_secret: env::var("JWT_SECRET").expect("JWT_SECRET"),
            bind_addr: env::var("BIND_ADDR").unwrap_or_else(|_| "0.0.0.0:8080".into()),
            env: env::var("APP_ENV").unwrap_or_else(|_| "dev".into()),
        }
    }
}
