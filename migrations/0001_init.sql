
CREATE EXTENSION IF NOT EXISTS pgcrypto;    
CREATE EXTENSION IF NOT EXISTS btree_gist;    


-- Enum Types
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'appointment_status') THEN
    CREATE TYPE appointment_status AS ENUM ('PENDING','ACCEPTED','REJECTED','CANCELED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    CREATE TYPE order_status AS ENUM ('PENDING','SHIPPING','CANCELED','SUCCESS');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'role_type') THEN
    CREATE TYPE role_type AS ENUM ('PATIENT','DOCTOR','ADMIN');
  END IF;
END$$;


-- Utility
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END$$;


-- Core
CREATE TABLE IF NOT EXISTS users (
  user_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email       varchar UNIQUE,
  phone       varchar UNIQUE NOT NULL,
  first_name  varchar NOT NULL,
  last_name   varchar NOT NULL,
  citizen_id  varchar UNIQUE NOT NULL, -- National ID / license number
  password    text NOT NULL,           -- store hash
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role    role_type NOT NULL,
  PRIMARY KEY (user_id, role)
);

-- Doctor-only
CREATE TABLE IF NOT EXISTS doctor_profile (
  user_id    uuid PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  mln        varchar UNIQUE NOT NULL,     -- Hospital staff/doctor ID
  department varchar,
  position   varchar
);

-- Patient-only
CREATE TABLE IF NOT EXISTS patient_profile (
  user_id uuid PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  hn      int UNIQUE NOT NULL             -- Hospital number / MRN
);


-- Availability & Appointments
CREATE TABLE IF NOT EXISTS time_slots (
  timeslot_id   int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doctor_id     uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  day_of_weeks  int  NOT NULL,       -- 0=Sun ... 6=Sat
  start_time    time NOT NULL,
  end_time      time NOT NULL,
  place_name    varchar NOT NULL,
  CONSTRAINT time_slots_day_ck CHECK (day_of_weeks BETWEEN 0 AND 6),
  CONSTRAINT time_slots_range_ck CHECK (start_time < end_time),
  start_minute int GENERATED ALWAYS AS ((extract(epoch from start_time)/60)::int) STORED,
  end_minute   int GENERATED ALWAYS AS ((extract(epoch from end_time)/60)::int) STORED
);


ALTER TABLE time_slots
  ADD CONSTRAINT time_slots_no_overlap
  EXCLUDE USING gist (
    doctor_id WITH =,
    day_of_weeks WITH =,
    int4range(start_minute, end_minute) WITH &&
  );

CREATE INDEX IF NOT EXISTS idx_time_slots_doctor_day ON time_slots(doctor_id, day_of_weeks);

CREATE TABLE IF NOT EXISTS appointments (
  appointment_id  int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id      uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  timeslot_id     int  NOT NULL REFERENCES time_slots(timeslot_id) ON DELETE RESTRICT,
  date            date NOT NULL,
  status          appointment_status NOT NULL DEFAULT 'PENDING',
  created_at      timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT uniq_patient_timeslot_date UNIQUE (patient_id, timeslot_id, date)
);

CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_timeslot_date ON appointments(timeslot_id, date);


-- Clinical
CREATE TABLE IF NOT EXISTS diagnoses (
  diagnosis_id   int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  appointment_id int  NOT NULL REFERENCES appointments(appointment_id) ON DELETE RESTRICT,
  patient_id     uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  doctor_id      uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  symptom        text NOT NULL,
  recorded_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_diagnoses_patient ON diagnoses(patient_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_doctor ON diagnoses(doctor_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_appointment ON diagnoses(appointment_id);

CREATE TABLE IF NOT EXISTS medicines (
  medicine_id   int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  medicine_name varchar NOT NULL,
  details       text,
  unit_price    numeric(10,2) NOT NULL CHECK (unit_price >= 0),
  image_url     text
);

-- Prescription 
CREATE TABLE IF NOT EXISTS prescriptions (
  prescription_id  int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id       uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  medicine_id      int  NOT NULL REFERENCES medicines(medicine_id) ON DELETE RESTRICT,
  dosage           text NOT NULL,     
  amount           int  NOT NULL CHECK (amount > 0),
  on_going         boolean NOT NULL DEFAULT false,
  doctor_comment   text
);

CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_medicine ON prescriptions(medicine_id);


-- Rights / Insurance
CREATE TABLE IF NOT EXISTS medical_rights (
  mr_id    int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name     varchar NOT NULL,
  details  text,
  img_url  text
);

CREATE TABLE IF NOT EXISTS user_mr (
  patient_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  mr_id      int  NOT NULL REFERENCES medical_rights(mr_id) ON DELETE CASCADE,
  PRIMARY KEY (patient_id, mr_id)
);


-- Commerce (Orders)
CREATE TABLE IF NOT EXISTS orders (
  order_id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id        uuid NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT, 
  status            order_status NOT NULL DEFAULT 'PENDING',
  shipping_platform varchar,
  payment_platform  varchar,
  image_url         text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX IF NOT EXISTS idx_orders_patient ON orders(patient_id);

CREATE TABLE IF NOT EXISTS order_items (
  order_item_id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id      int NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  medicine_id   int NOT NULL REFERENCES medicines(medicine_id) ON DELETE RESTRICT,
  quantity      int NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price    numeric(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

CREATE TABLE IF NOT EXISTS shipping_address (
  patient_id  uuid PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  first_name  varchar NOT NULL,
  last_name   varchar NOT NULL,
  address     text NOT NULL,
  postal_code varchar NOT NULL,
  phone       varchar NOT NULL,
  lat         double precision,
  lon         double precision
);

CREATE TABLE IF NOT EXISTS shipping_status (
  shipping_status_id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id           int NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  details            text,
  lat                double precision,
  lon                double precision,
  at                 timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shipping_status_order ON shipping_status(order_id);



-- Patient health profile
CREATE TABLE IF NOT EXISTS patient_health_info (
  patient_id        uuid PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  age               int CHECK (age IS NULL OR age BETWEEN 0 AND 130),
  gender            varchar,
  height_cm         numeric(5,2) CHECK (height_cm IS NULL OR height_cm > 0),
  weight_kg         numeric(5,2) CHECK (weight_kg IS NULL OR weight_kg > 0),
  medical_conditions text,
  drug_allergies     text,
  updated_at         timestamptz NOT NULL DEFAULT now()
);


CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_patient_health_info_updated_at
BEFORE UPDATE ON patient_health_info
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

