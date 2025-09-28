use serde::{Deserialize, Serialize};
use time::Date;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, sqlx::Type, ToSchema)]
#[sqlx(type_name = "appointment_status", rename_all = "SCREAMING_SNAKE_CASE")]
pub enum AppointmentStatus {
    PENDING,
    ACCEPTED,
    REJECTED,
    CANCELED,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct Appointment {
    pub appointment_id: i32,
    pub patient_id: Uuid,
    pub timeslot_id: i32,
    pub date: Date,
    pub status: AppointmentStatus,
    pub created_at: time::OffsetDateTime,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct TimeSlot {
    pub timeslot_id: i32,
    pub doctor_id: Uuid,
    pub day_of_weeks: i32,
    #[schema(value_type = String, format = "time", example = "09:30:00")]
    pub start_time: time::Time,
    #[schema(value_type = String, format = "time", example = "09:30:00")]
    pub end_time: time::Time,
    pub place_name: String,
}

pub struct NewAppointment {
    pub patient_id: Uuid,
    pub timeslot_id: i32,
    pub date: Date,
}
