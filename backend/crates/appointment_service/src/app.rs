use crate::domain::*;
use common::error::AppResult;
use db::PgTx;

pub trait AppointmentRepo: Send + Sync {
    #[expect(async_fn_in_trait)]
    async fn create(&self, tx: &mut PgTx<'_>, cmd: NewAppointment) -> AppResult<Appointment>;
    #[expect(async_fn_in_trait)]
    async fn by_id(&self, id: i32) -> AppResult<Option<Appointment>>;
    #[expect(async_fn_in_trait)]
    async fn accept(&self, tx: &mut PgTx<'_>, id: i32) -> AppResult<()>;
}

#[derive(Clone)]
pub struct AppointmentService<R: AppointmentRepo> {
    pub repo: R,
}

impl<R: AppointmentRepo> AppointmentService<R> {
    pub fn new(repo: R) -> Self {
        Self { repo }
    }

    pub async fn book(&self, tx: &mut PgTx<'_>, cmd: NewAppointment) -> AppResult<Appointment> {
        // DB uniqueness & exclusion constraints already enforce conflicts.
        self.repo.create(tx, cmd).await
    }

    pub async fn accept(&self, tx: &mut PgTx<'_>, id: i32) -> AppResult<()> {
        self.repo.accept(tx, id).await
    }
}
