use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use utoipa::ToSchema;

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PatientSignupReq {
    pub hn: i32,
    pub citizen_id: String,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct LoginPatientReq {
    pub hn: i32,
    pub citizen_id: String,
    pub password: String,
}

#[derive(Debug, Clone)]
pub struct PatientLoginInput {
    pub hn: i32,
    pub citizen_id: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct MedicalRightItem {
    pub mr_id: i32,
    pub name: String,
    pub details: String,
    pub image_url: String,
}

#[derive(Debug, Clone)]
pub struct MedicalRightUpsert {
    pub mr_id: i32,
    pub name: String,
    pub details: String,
    pub image_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DoctorSignupReq {
    pub mln: String,
    pub citizen_id: String,
    pub first_name: String,
    pub last_name: String,
    pub phone: String,
    pub password: String,
    pub email: String,
}

#[derive(Debug, Clone)]
pub struct DoctorSignupInput {
    pub mln: String,
    pub citizen_id: String,
    pub first_name: String,
    pub last_name: String,
    pub phone: String,
    pub password: String,
    pub email: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct LoginDoctorReq {
    pub mln: String,
    pub citizen_id: String,
    pub password: String,
}

#[derive(Debug, Clone)]
pub struct DoctorLoginInput {
    pub mln: String,
    pub citizen_id: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct AccessTokenResp {
    pub access_token: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct DoctorProfileResp {
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub departments: String,
    pub position: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct PatientProfileResp {
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    #[serde(with = "time::serde::rfc3339")]
    #[schema(value_type = String, format = DateTime)]
    pub updated_at: OffsetDateTime,
}

#[derive(Debug, Clone)]
pub struct PatientSignupInput {
    pub hn: i32,
    pub citizen_id: String,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub password: String,
}

impl From<PatientSignupReq> for PatientSignupInput {
    fn from(value: PatientSignupReq) -> Self {
        Self {
            hn: value.hn,
            citizen_id: value.citizen_id,
            first_name: value.first_name,
            last_name: value.last_name,
            email: value.email,
            phone: value.phone,
            password: value.password,
        }
    }
}

impl From<LoginPatientReq> for PatientLoginInput {
    fn from(value: LoginPatientReq) -> Self {
        Self {
            hn: value.hn,
            citizen_id: value.citizen_id,
            password: value.password,
        }
    }
}

impl From<MedicalRightItem> for MedicalRightUpsert {
    fn from(value: MedicalRightItem) -> Self {
        Self {
            mr_id: value.mr_id,
            name: value.name,
            details: value.details,
            image_url: value.image_url,
        }
    }
}

impl From<DoctorSignupReq> for DoctorSignupInput {
    fn from(value: DoctorSignupReq) -> Self {
        Self {
            mln: value.mln,
            citizen_id: value.citizen_id,
            first_name: value.first_name,
            last_name: value.last_name,
            phone: value.phone,
            password: value.password,
            email: value.email,
        }
    }
}

impl From<LoginDoctorReq> for DoctorLoginInput {
    fn from(value: LoginDoctorReq) -> Self {
        Self {
            mln: value.mln,
            citizen_id: value.citizen_id,
            password: value.password,
        }
    }
}
