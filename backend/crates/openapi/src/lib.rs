use axum::Router;
use utoipa::OpenApi;
use utoipa_rapidoc::RapiDoc;
use utoipa_redoc::{Redoc, Servable as _};
use utoipa_scalar::{Scalar, Servable as _};
use utoipa_swagger_ui::{Config, SwaggerUi};

#[derive(OpenApi, Default)]
#[openapi(
    servers((url = "/api")),
    nest(
        (path = "/appointments", api = appointment_service::ApiDoc),
        //(path = "/auth", api = auth_service::ApiDoc),
        //(path = "/catalog", api = catalog_service::ApiDoc),
        //(path = "/diagnosis", api = diagnosis_service::ApiDoc),
        //(path = "/prescription", api = prescription_service::ApiDoc),
        //(path = "/profile", api = profile_service::ApiDoc),
        //(path = "/order", api = order_service::ApiDoc),
        //(path = "/shipping", api = shipping_service::ApiDoc)
    )
)]
pub struct ApiDoc;

pub fn router<D>() -> Router
where
    D: OpenApi + Default + 'static,
{
    let doc = D::openapi();

    let json_path = "/docs/api-docs/openapi.json";
    Router::new()
        .merge(
            SwaggerUi::new("/swagger")
                .url("/api-docs/openapi.json", doc.clone())
                .config(Config::from(json_path)),
        )
        .merge(RapiDoc::new(json_path).path("/rapidoc"))
        // Redoc at /redoc
        .merge(Redoc::with_url("/redoc", doc.clone()))
        // Scalar at /scalar
        .merge(Scalar::with_url("/scalar", doc.clone()))
}
