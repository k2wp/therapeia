use common::config::AppConfig;
use sqlx::{PgPool, Postgres, Transaction, postgres::PgPoolOptions};

pub type PgTx<'a> = Transaction<'a, Postgres>;

pub async fn connect(cfg: &AppConfig) -> sqlx::Result<PgPool> {
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&cfg.db_url)
        .await?;
    Ok(pool)
}

// Optional: embed migrations with `sqlx::migrate!()`; point at /migrations
pub async fn migrate(pool: &PgPool) -> sqlx::Result<()> {
    sqlx::migrate!("../../../migrations").run(pool).await?;
    Ok(())
}
