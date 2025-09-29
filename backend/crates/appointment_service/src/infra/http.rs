use super::repo_sqlx::SqlxAppointmentRepo;
use crate::{
    app::{AppointmentRepo, AppointmentService},
    domain::{Appointment, NewAppointment},
};
use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post},
};
use common::error::{AppError, AppResult};
use db::PgTx;
use serde::Deserialize;
use sqlx::PgPool;
use utoipa::{OpenApi, ToSchema};
use uuid::Uuid;

#[derive(Clone)]
pub struct Ctx {
    pool: PgPool,
    svc: AppointmentService<SqlxAppointmentRepo>,
}

impl Ctx {
    pub fn new(pool: PgPool) -> Self {
        let svc = AppointmentService::new(SqlxAppointmentRepo::new(pool.clone()));
        Self { pool, svc }
    }
}

#[derive(Deserialize, ToSchema)]
pub struct BookReq {
    pub patient_id: Uuid,
    pub timeslot_id: i32,
    pub date: time::Date,
}

#[utoipa::path(
    post,
    path = "/",
    request_body = BookReq,
    responses(
        (status = 200, description = "Book appointment successfully", body = Appointment),
        (status = 404, description = "Patient or timeslot not found"),
    ),
    tag = "appointments"
)]
async fn book(State(ctx): State<Ctx>, Json(req): Json<BookReq>) -> AppResult<Json<Appointment>> {
    let mut tx: PgTx<'_> = ctx.pool.begin().await?;
    let appt = ctx
        .svc
        .book(
            &mut tx,
            NewAppointment {
                patient_id: req.patient_id,
                timeslot_id: req.timeslot_id,
                date: req.date,
            },
        )
        .await?;
    tx.commit().await?;
    Ok(Json(appt))
}

#[utoipa::path(
    get,
    path = "/{id}",
    params(
        ("id" = i32, Path, description = "Appointment ID")
    ),
    responses(
        (status = 200, description = "Appointment found", body = Appointment),
        (status = 404, description = "Appointment not found"),
    ),
    tag = "appointments"
)]
async fn get_by_id(State(ctx): State<Ctx>, Path(id): Path<i32>) -> AppResult<Json<Appointment>> {
    let Some(a) = ctx.svc.repo.by_id(id).await? else {
        return Err(AppError::NotFound);
    };
    Ok(Json(a))
}

pub fn router(pool: PgPool) -> Router {
    let ctx = Ctx::new(pool);
    Router::new()
        .route("/appointments", post(book))
        .route("/appointments/{id}", get(get_by_id))
        .with_state(ctx)
}

#[derive(OpenApi, Default)]
#[openapi(
    paths(book, get_by_id),
    components(schemas(BookReq, Appointment)),
    tags((name = "appointments", description = "Appointment APIs"))
)]
pub struct ApiDoc;
