use super::super::app::AppointmentRepo;
use super::super::domain::*;
use common::error::{AppError, AppResult};
use db::PgTx;
use sqlx::PgPool;

#[derive(Clone)]
pub struct SqlxAppointmentRepo {
    pool: PgPool,
}
impl SqlxAppointmentRepo {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

impl AppointmentRepo for SqlxAppointmentRepo {
    async fn create(&self, tx: &mut PgTx<'_>, cmd: NewAppointment) -> AppResult<Appointment> {
        let rec = sqlx::query_as!(
            Appointment,
            r#"
            INSERT INTO appointments (patient_id, timeslot_id, date)
            VALUES ($1, $2, $3)
            RETURNING
              appointment_id,
              patient_id,
              timeslot_id,
              date,
              status as "status: _",
              created_at
            "#,
            cmd.patient_id,
            cmd.timeslot_id,
            cmd.date
        )
        .fetch_one(&mut **tx)
        .await?;
        Ok(rec)
    }

    async fn by_id(&self, id: i32) -> AppResult<Option<Appointment>> {
        let rec = sqlx::query_as!(
            Appointment,
            r#"
            SELECT appointment_id, patient_id, timeslot_id, date,
                   status as "status: _", created_at
            FROM appointments WHERE appointment_id = $1
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await?;
        Ok(rec)
    }

    async fn accept(&self, tx: &mut PgTx<'_>, id: i32) -> AppResult<()> {
        let rows = sqlx::query!(
            r#"UPDATE appointments SET status = 'ACCEPTED' WHERE appointment_id = $1"#,
            id
        )
        .execute(&mut **tx)
        .await?;
        if rows.rows_affected() == 0 {
            return Err(AppError::NotFound);
        }
        Ok(())
    }
}
