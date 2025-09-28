

SET search_path = public, pg_temp;

-- ===== Users =====
INSERT INTO users (user_id,email,phone,first_name,last_name,citizen_id,password)
VALUES
 ('a39b6135-22bf-4b06-b4b7-e34daa460258','doctor@example.com','0800000001','Alice','Smith','1234567890123','hashed_password1'),
 ('0e01abb3-da7e-4aaf-8b10-4834625f19bb','patient@example.com','0800000002','Bob','Johnson','2345678901234','hashed_password2'),
 ('bc78e582-1318-4fb6-b2a2-38c1d4e74fc0','admin@example.com','0800000003','Charlie','Admin','3456789012345','hashed_password3')
ON CONFLICT (user_id) DO NOTHING;

-- ===== Roles =====
INSERT INTO user_roles (user_id,role) VALUES
 ('a39b6135-22bf-4b06-b4b7-e34daa460258','DOCTOR'),
 ('0e01abb3-da7e-4aaf-8b10-4834625f19bb','PATIENT'),
 ('bc78e582-1318-4fb6-b2a2-38c1d4e74fc0','ADMIN')
ON CONFLICT DO NOTHING;

-- ===== Profiles =====
INSERT INTO doctor_profile (user_id,mln,department,position)
VALUES ('a39b6135-22bf-4b06-b4b7-e34daa460258','MLN123456','Cardiology','Senior Cardiologist')
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO patient_profile (user_id,hn)
VALUES ('0e01abb3-da7e-4aaf-8b10-4834625f19bb',100001)
ON CONFLICT (user_id) DO NOTHING;

-- ===== Time slots (Mon 09–12, Wed 14–17) =====
INSERT INTO time_slots (doctor_id,day_of_weeks,start_time,end_time,place_name)
SELECT 'a39b6135-22bf-4b06-b4b7-e34daa460258',1,'09:00'::time,'12:00'::time,'Clinic 1'
WHERE NOT EXISTS (
  SELECT 1 FROM time_slots
  WHERE doctor_id='a39b6135-22bf-4b06-b4b7-e34daa460258' AND day_of_weeks=1
    AND start_time='09:00' AND end_time='12:00'
);

INSERT INTO time_slots (doctor_id,day_of_weeks,start_time,end_time,place_name)
SELECT 'a39b6135-22bf-4b06-b4b7-e34daa460258',3,'14:00'::time,'17:00'::time,'Clinic 1'
WHERE NOT EXISTS (
  SELECT 1 FROM time_slots
  WHERE doctor_id='a39b6135-22bf-4b06-b4b7-e34daa460258' AND day_of_weeks=3
    AND start_time='14:00' AND end_time='17:00'
);

-- ===== Appointment =====
INSERT INTO appointments (patient_id,timeslot_id,date,status)
SELECT '0e01abb3-da7e-4aaf-8b10-4834625f19bb', ts.timeslot_id, DATE '2025-09-23', 'ACCEPTED'
FROM time_slots ts
WHERE ts.doctor_id='a39b6135-22bf-4b06-b4b7-e34daa460258' AND ts.day_of_weeks=1 AND ts.start_time='09:00'
ON CONFLICT (patient_id,timeslot_id,date) DO NOTHING;

-- ===== Diagnosis =====
INSERT INTO diagnoses (appointment_id,patient_id,doctor_id,symptom)
SELECT a.appointment_id,
       '0e01abb3-da7e-4aaf-8b10-4834625f19bb',
       'a39b6135-22bf-4b06-b4b7-e34daa460258',
       'เจ็บคอ และเป็นไข้เล็กน้อย'
FROM appointments a
JOIN time_slots ts ON ts.timeslot_id=a.timeslot_id
WHERE a.patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb'
  AND a.date=DATE '2025-09-23'
  AND ts.day_of_weeks=1 AND ts.start_time='09:00'
  AND NOT EXISTS (SELECT 1 FROM diagnoses d WHERE d.appointment_id=a.appointment_id);

-- ===== Medicines =====
INSERT INTO medicines (medicine_name,details,unit_price,image_url)
SELECT 'Paracetamol 500 mg tablets','ยาแก้ปวดและลดไข้',50,
       'https://assets.sainsburys-groceries.co.uk/gol/8075006/1/640x640.jpg'
WHERE NOT EXISTS (SELECT 1 FROM medicines WHERE medicine_name='Paracetamol 500 mg tablets');

INSERT INTO medicines (medicine_name,details,unit_price,image_url)
SELECT 'Ibuprofen 200 mg tablets','ยาต้านการอักเสบที่ไม่ใช่สเตียรอยด์',100,
       'https://tmanpharmaceutical.com/wp-content/uploads/2024/01/206A1A1.jpg'
WHERE NOT EXISTS (SELECT 1 FROM medicines WHERE medicine_name='Ibuprofen 200 mg tablets');

INSERT INTO medicines (medicine_name,details,unit_price,image_url)
SELECT 'Amoxicillin 500 mg capsules','ยาปฏิชีวนะเพนิซิลลินสำหรับการติดเชื้อแบคทีเรีย',200,
       'https://5.imimg.com/data5/SELLER/Default/2025/4/501570426/QD/SO/KM/6695503/amoxicillin-500mg-capsule.png'
WHERE NOT EXISTS (SELECT 1 FROM medicines WHERE medicine_name='Amoxicillin 500 mg capsules');

-- ===== Prescription (Ibuprofen) =====
INSERT INTO prescriptions (patient_id,medicine_id,dosage,amount,on_going,doctor_comment)
SELECT '0e01abb3-da7e-4aaf-8b10-4834625f19bb', m.medicine_id, '1 เม็ด วันละ 3 ครั้ง', 30, false, 'รับประทานหลังมื้ออาหาร'
FROM medicines m
WHERE m.medicine_name='Ibuprofen 200 mg tablets'
  AND NOT EXISTS (
    SELECT 1 FROM prescriptions p
    WHERE p.patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND p.medicine_id=m.medicine_id
  );

-- ===== Medical rights & assignment =====
INSERT INTO medical_rights (name,details,img_url)
SELECT 'สำนักงานหลักประกันสุขภาพแห่งชาติ','บัตรทอง 30 บาทรักษาทุกโรค สำหรับประชาชนทั่วไป',
       'https://songkhla.nhso.go.th/files/Content/1868/134006650103856250_icon-nhso.jpg'
WHERE NOT EXISTS (SELECT 1 FROM medical_rights WHERE name='สำนักงานหลักประกันสุขภาพแห่งชาติ');

INSERT INTO medical_rights (name,details,img_url)
SELECT 'ประกันสังคม','สำหรับลูกจ้างและนายจ้างที่จ่ายเงินสมทบประกันสังคม',
       'https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Logo_of_the_Social_Security_Office.svg/1943px-Logo_of_the_Social_Security_Office.svg.png'
WHERE NOT EXISTS (SELECT 1 FROM medical_rights WHERE name='ประกันสังคม');

INSERT INTO medical_rights (name,details,img_url)
SELECT 'กรมบัญชีกลาง','สำหรับข้าราชการ ลูกจ้างประจำ และครอบครัว',
       'https://agritech.doae.go.th/wp-content/uploads/2022/07/L24-65.png'
WHERE NOT EXISTS (SELECT 1 FROM medical_rights WHERE name='กรมบัญชีกลาง');

INSERT INTO user_mr (patient_id,mr_id)
SELECT '0e01abb3-da7e-4aaf-8b10-4834625f19bb', mr.mr_id
FROM medical_rights mr
WHERE mr.name='ประกันสังคม'
ON CONFLICT DO NOTHING;

-- ===== One “SHIPPING” order with an image =====
INSERT INTO orders (patient_id,status,shipping_platform,payment_platform,image_url)
SELECT '0e01abb3-da7e-4aaf-8b10-4834625f19bb','SHIPPING','DHL','Credit Card',
       'https://upload.wikimedia.org/wikipedia/commons/7/77/Cardboard_box_with_office_supplies.jpg'
WHERE NOT EXISTS (
  SELECT 1 FROM orders WHERE patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND status='SHIPPING'
);

-- ===== Order items =====
INSERT INTO order_items (order_id,medicine_id,quantity,unit_price)
SELECT ord.order_id, med.medicine_id, 2, med.unit_price
FROM (SELECT order_id
      FROM orders
      WHERE patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND status='SHIPPING'
      ORDER BY created_at DESC LIMIT 1) ord,
     (SELECT medicine_id, unit_price
      FROM medicines
      WHERE medicine_name='Paracetamol 500 mg tablets') med
WHERE NOT EXISTS (
  SELECT 1 FROM order_items oi WHERE oi.order_id=ord.order_id AND oi.medicine_id=med.medicine_id
);

-- Ibuprofen x1
INSERT INTO order_items (order_id,medicine_id,quantity,unit_price)
SELECT ord.order_id, med.medicine_id, 1, med.unit_price
FROM (SELECT order_id
      FROM orders
      WHERE patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND status='SHIPPING'
      ORDER BY created_at DESC LIMIT 1) ord,
     (SELECT medicine_id, unit_price
      FROM medicines
      WHERE medicine_name='Ibuprofen 200 mg tablets') med
WHERE NOT EXISTS (
  SELECT 1 FROM order_items oi WHERE oi.order_id=ord.order_id AND oi.medicine_id=med.medicine_id
);

-- ===== Shipping address =====
INSERT INTO shipping_address (patient_id,first_name,last_name,address,postal_code,phone,lat,lon)
VALUES ('0e01abb3-da7e-4aaf-8b10-4834625f19bb','Bob','Johnson',
        '123 Sukhumvit Road, Bangkok','10110','0812345678',13.7563,100.5018)
ON CONFLICT (patient_id) DO NOTHING;

-- ===== Shipping status (TIMESTAMPTZ with +07) =====
INSERT INTO shipping_status (order_id,details,lat,lon,at)
SELECT ord.order_id,'พัสดุถึงคลังสินค้าแล้ว',13.7000,100.5000,'2025-09-21 10:00:00+07'::timestamptz
FROM (SELECT order_id FROM orders
      WHERE patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND status='SHIPPING'
      ORDER BY created_at DESC LIMIT 1) ord
WHERE NOT EXISTS (
  SELECT 1 FROM shipping_status s WHERE s.order_id=ord.order_id AND s.details='พัสดุถึงคลังสินค้าแล้ว'
);

INSERT INTO shipping_status (order_id,details,lat,lon,at)
SELECT ord.order_id,'พัสดุกำลังจัดส่ง',13.7400,100.5200,'2025-09-22 08:30:00+07'::timestamptz
FROM (SELECT order_id FROM orders
      WHERE patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND status='SHIPPING'
      ORDER BY created_at DESC LIMIT 1) ord
WHERE NOT EXISTS (
  SELECT 1 FROM shipping_status s WHERE s.order_id=ord.order_id AND s.details='พัสดุกำลังจัดส่งy'
);

INSERT INTO shipping_status (order_id,details,lat,lon,at)
SELECT ord.order_id,'จัดส่งสำเร็จ ',13.7563,100.5018,'2025-09-23 15:45:00+07'::timestamptz
FROM (SELECT order_id FROM orders
      WHERE patient_id='0e01abb3-da7e-4aaf-8b10-4834625f19bb' AND status='SHIPPING'
      ORDER BY created_at DESC LIMIT 1) ord
WHERE NOT EXISTS (
  SELECT 1 FROM shipping_status s WHERE s.order_id=ord.order_id AND s.details='จัดส่งสำเร็จ '
);

-- ===== Patient health profile =====
INSERT INTO patient_health_info (patient_id,age,gender,height_cm,weight_kg,medical_conditions,drug_allergies)
VALUES ('0e01abb3-da7e-4aaf-8b10-4834625f19bb',35,'ชาย',175.0,70.0,'ความดันโลหิตสูง','Penicillin')
ON CONFLICT (patient_id) DO NOTHING;
