use crate::{
    app::AuthRepo,
    domain::{
        DoctorLoginInput, DoctorProfileResp, DoctorSignupInput, MedicalRightItem,
        MedicalRightUpsert, PatientLoginInput, PatientProfileResp, PatientSignupInput,
    },
};
use common::{
    error::{AppError, AppResult},
    password::{hash_password, verify_password},
};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Clone)]
pub struct SqlxAuthRepo {
    pool: PgPool,
}
impl SqlxAuthRepo {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

impl AuthRepo for SqlxAuthRepo {
    async fn create_patient(&self, input: PatientSignupInput) -> AppResult<Uuid> {
        let PatientSignupInput {
            hn,
            citizen_id,
            first_name,
            last_name,
            email,
            phone,
            password,
        } = input;
        let password_hash = hash_password(&password)?;
        let mut tx = self.pool.begin().await?;
        let user_id = sqlx::query_scalar!(
            r#"INSERT INTO users (phone, first_name, last_name, citizen_id, password, email)
               VALUES ($1,$2,$3,$4,$5,$6) RETURNING user_id"#,
            phone,
            first_name,
            last_name,
            citizen_id,
            password_hash,
            email,
        )
        .fetch_one(&mut *tx)
        .await?;
        sqlx::query!(
            r#"INSERT INTO patient_profile (user_id, hn) VALUES ($1,$2)
               ON CONFLICT (user_id) DO UPDATE SET hn = EXCLUDED.hn"#,
            user_id,
            hn
        )
        .execute(&mut *tx)
        .await?;
        sqlx::query!(
            r#"INSERT INTO user_roles (user_id, role) VALUES ($1,'PATIENT') ON CONFLICT DO NOTHING"#,
            user_id
        ).execute(&mut *tx).await?;
        tx.commit().await?;
        Ok(user_id)
    }

    async fn login_patient(&self, input: PatientLoginInput) -> AppResult<Uuid> {
        let PatientLoginInput {
            hn,
            citizen_id,
            password,
        } = input;
        let row = sqlx::query!(
            r#"SELECT u.user_id, u.password
               FROM users u JOIN patient_profile p ON p.user_id = u.user_id
               WHERE p.hn=$1 AND u.citizen_id=$2"#,
            hn,
            citizen_id
        )
        .fetch_optional(&self.pool)
        .await?;
        let Some(r) = row else {
            return Err(AppError::Unauthorized);
        };
        // NOTE: password is stored as plaintext in migrations; in real code hash+verify
        if !verify_password(&password, &r.password)? {
            return Err(AppError::Unauthorized);
        }
        Ok(r.user_id)
    }

    async fn upsert_medical_rights(&self, items: Vec<MedicalRightUpsert>) -> AppResult<()> {
        let mut tx = self.pool.begin().await?;
        for item in items {
            let MedicalRightUpsert {
                mr_id,
                name,
                details,
                image_url,
            } = item;
            sqlx::query!(
                r#"INSERT INTO medical_rights (mr_id, name, details, img_url)
                   OVERRIDING SYSTEM VALUE VALUES ($1,$2,$3,$4)
                   ON CONFLICT (mr_id) DO UPDATE SET name=EXCLUDED.name, details=EXCLUDED.details, img_url=EXCLUDED.img_url"#,
                mr_id, name, details, image_url
            ).execute(&mut *tx).await?;
        }
        tx.commit().await?;
        Ok(())
    }

    async fn user_medical_rights(&self, user_id: Uuid) -> AppResult<Vec<MedicalRightItem>> {
        let rows = sqlx::query!(
            r#"
                SELECT mr.mr_id, mr.name, mr.details, mr.img_url
                FROM user_mr um
                JOIN medical_rights mr ON mr.mr_id = um.mr_id
                WHERE um.patient_id = $1
                ORDER BY mr.name
            "#,
            user_id
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|row| MedicalRightItem {
                mr_id: row.mr_id,
                name: row.name,
                details: row.details.unwrap_or_default(),
                image_url: row.img_url.unwrap_or_default(),
            })
            .collect())
    }

    async fn create_doctor(&self, input: DoctorSignupInput) -> AppResult<Uuid> {
        let DoctorSignupInput {
            mln,
            citizen_id,
            first_name,
            last_name,
            phone,
            password,
            email,
        } = input;
        let password_hash = hash_password(&password)?;
        let mut tx = self.pool.begin().await?;
        let user_id = sqlx::query_scalar!(
            r#"INSERT INTO users (phone, first_name, last_name, citizen_id, password, email)
               VALUES ($1,$2,$3,$4,$5,$6) RETURNING user_id"#,
            phone,
            first_name,
            last_name,
            citizen_id,
            password_hash,
            email,
        )
        .fetch_one(&mut *tx)
        .await?;
        sqlx::query!(
            r#"INSERT INTO doctor_profile (user_id, mln) VALUES ($1,$2)
               ON CONFLICT (user_id) DO UPDATE SET mln = EXCLUDED.mln"#,
            user_id,
            mln
        )
        .execute(&mut *tx)
        .await?;
        sqlx::query!(
            r#"INSERT INTO user_roles (user_id, role) VALUES ($1,'DOCTOR') ON CONFLICT DO NOTHING"#,
            user_id
        )
        .execute(&mut *tx)
        .await?;
        tx.commit().await?;
        Ok(user_id)
    }

    async fn login_doctor(&self, input: DoctorLoginInput) -> AppResult<Uuid> {
        let DoctorLoginInput {
            mln,
            citizen_id,
            password,
        } = input;
        let row = sqlx::query!(
            r#"SELECT u.user_id, u.password
               FROM users u JOIN doctor_profile d ON d.user_id = u.user_id
               WHERE d.mln=$1 AND u.citizen_id=$2"#,
            mln,
            citizen_id
        )
        .fetch_optional(&self.pool)
        .await?;
        let Some(r) = row else {
            return Err(AppError::Unauthorized);
        };
        if !verify_password(&password, &r.password)? {
            return Err(AppError::Unauthorized);
        }
        Ok(r.user_id)
    }

    async fn doctor_profile(&self, user_id: Uuid) -> AppResult<DoctorProfileResp> {
        let rec = sqlx::query!(
            r#"
                SELECT
                    u.first_name,
                    u.last_name,
                    COALESCE(u.email, '') AS email,
                    u.phone,
                    COALESCE(d.department, '') AS departments,
                    COALESCE(d.position, '') AS position
                FROM users u
                JOIN doctor_profile d ON d.user_id = u.user_id
                WHERE u.user_id = $1
            "#,
            user_id
        )
        .fetch_optional(&self.pool)
        .await?;

        let Some(rec) = rec else {
            return Err(AppError::NotFound);
        };

        Ok(DoctorProfileResp {
            first_name: rec.first_name,
            last_name: rec.last_name,
            email: rec.email.unwrap_or_default(),
            phone: rec.phone,
            departments: rec.departments.unwrap_or_default(),
            position: rec.position.unwrap_or_default(),
        })
    }

    async fn patient_profile(&self, user_id: Uuid) -> AppResult<PatientProfileResp> {
        let rec = sqlx::query!(
            r#"
                SELECT
                    first_name,
                    last_name,
                    COALESCE(email, '') AS email,
                    phone,
                    updated_at
                FROM users
                WHERE user_id = $1
            "#,
            user_id
        )
        .fetch_optional(&self.pool)
        .await?;

        let Some(rec) = rec else {
            return Err(AppError::NotFound);
        };

        Ok(PatientProfileResp {
            first_name: rec.first_name,
            last_name: rec.last_name,
            email: rec.email.unwrap_or_default(),
            phone: rec.phone,
            updated_at: rec.updated_at,
        })
    }
}
