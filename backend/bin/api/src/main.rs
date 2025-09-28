use axum::Router;
use common::config::AppConfig;
use db::{connect, migrate};
use tower_http::{cors::CorsLayer, trace::TraceLayer};
use tracing_subscriber::{EnvFilter, fmt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    fmt()
        .with_env_filter(
            EnvFilter::builder()
                .with_default_directive(tracing::level_filters::LevelFilter::INFO.into())
                .from_env_lossy(),
        )
        .init();
    let cfg = AppConfig::from_env();

    let pool = connect(&cfg).await?;
    migrate(&pool).await?;

    // Service routers
    let appt = appointment_service::router(pool.clone());
    //let auth = auth_service::router(pool.clone());
    //let profiles = profile_service::router(pool.clone());
    //let catalog = catalog_service::router(pool.clone());
    //let diag = diagnosis_service::router(pool.clone());
    //let rx = prescription_service::router(pool.clone());
    //let order = order_service::router(pool.clone());
    //let ship = shipping_service::router(pool.clone());

    // OpenAPI/Swagger
    let openapi = openapi::router::<openapi::ApiDoc>();

    let app = Router::new()
        .nest(
            "/api",
            appt, //.merge(profiles)
                 //.merge(catalog)
                 //.merge(auth)
                 //.merge(diag)
                 //.merge(rx)
                 //.merge(order)
                 //.merge(ship),
        )
        .nest("/docs", openapi)
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive());

    tracing::info!("listening on {}", cfg.bind_addr);
    axum_server::bind(cfg.bind_addr.parse()?)
        .serve(app.into_make_service())
        .await?;
    Ok(())
}
