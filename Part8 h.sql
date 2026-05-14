-- PART 8: SAMPLE DATA INSERTION
INSERT INTO cities (city_name, region, latitude, longitude, population, surge_multiplier_default) VALUES
('Addis Ababa','addis_ababa',9.03,38.74,3500000,1.00),
('Adama','adama',8.54,39.27,350000,1.00),
('Hawassa','hawassa',7.06,38.48,350000,1.00),
('Dire Dawa','dire_dawa',9.59,41.87,440000,1.00),
('Bahir Dar','bahir_dar',11.59,37.38,350000,1.00),
('Mekelle','mekelle',13.50,39.47,310000,1.00);

INSERT INTO zones (city_id, zone_name, zone_code, center_lat, center_lon, radius_meters, base_fare, per_km_rate, per_minute_rate, is_airport_zone) VALUES
(1,'Bole International Airport','ADD-AIRPORT',8.978,38.799,3000,80.00,18.00,4.00,1),
(1,'Bole Medhanialem','ADD-BOLE',9.010,38.791,2000,35.00,16.00,3.50,0),
(1,'Megenagna','ADD-MEGEN',9.024,38.803,2000,30.00,15.00,3.00,0),
(1,'Mexico Square','ADD-MEXICO',9.018,38.756,2000,30.00,15.00,3.00,0),
(1,'Piassa','ADD-PIASSA',9.027,38.745,2500,30.00,15.00,3.00,0),
(1,'Mercato','ADD-MERCATO',9.021,38.731,3000,30.00,15.00,3.00,0),
(1,'Kazanchis','ADD-KAZANCHIS',9.016,38.770,2000,35.00,16.00,3.50,0),
(2,'Adama City Center','ADM-CENTER',8.541,39.270,3000,25.00,13.00,2.50,0),
(3,'Hawassa Tabor','HAW-TABOR',7.062,38.482,2500,25.00,13.00,2.50,0),
(3,'Hawassa Lake Area','HAW-LAKE',7.046,38.468,3000,30.00,14.00,3.00,0);

INSERT INTO vehicles (make, model, year, color, plate_number_hash, plate_number_encrypted, vehicle_type, capacity, is_ac_available, insurance_expiry, inspection_expiry) VALUES
('Toyota','Vitz',2019,'White',SHA2('AA-12345-A',256),AES_ENCRYPT('AA-12345-A','12345678'),'sedan',4,0,'2026-12-31','2026-06-30'),
('Suzuki','Alto',2020,'Silver',SHA2('AA-67890-B',256),AES_ENCRYPT('AA-67890-B','12345678'),'sedan',4,0,'2026-11-30','2026-05-31'),
('Toyota','Corolla',2021,'Blue',SHA2('OR-33221-C',256),AES_ENCRYPT('OR-33221-C','12345678'),'sedan',4,1,'2026-09-30','2026-03-31'),
('Hyundai','Elantra',2022,'Black',SHA2('AA-55443-D',256),AES_ENCRYPT('AA-55443-D','12345678'),'sedan',4,1,'2027-01-31','2026-07-31'),
('Toyota','HiAce',2018,'White',SHA2('AA-99887-E',256),AES_ENCRYPT('AA-99887-E','12345678'),'minivan',12,0,'2026-08-31','2026-02-28');

INSERT INTO users (full_name, phone_hash, phone_encrypted, city_id, status, rating, preferred_payment) VALUES
('Abel Tesfaye',SHA2('+251911234567',256),AES_ENCRYPT('+251911234567','12345678'),1,'active',4.80,'telebirr'),
('Sara Alemu',SHA2('+251922345678',256),AES_ENCRYPT('+251922345678','12345678'),2,'active',4.90,'cbe_birr'),
('Dawit Haile',SHA2('+251933456789',256),AES_ENCRYPT('+251933456789','12345678'),3,'active',4.70,'cash'),
('Meron Bekele',SHA2('+251944567890',256),AES_ENCRYPT('+251944567890','12345678'),1,'active',5.00,'telebirr'),
('Yonas Tadesse',SHA2('+251955678901',256),AES_ENCRYPT('+251955678901','12345678'),1,'active',4.60,'cash'),
('Hana Girma',SHA2('+251966789012',256),AES_ENCRYPT('+251966789012','12345678'),4,'active',4.85,'awash_pay'),
('Samuel Worku',SHA2('+251977890123',256),AES_ENCRYPT('+251977890123','12345678'),1,'active',4.50,'cash'),
('Tigist Mengesha',SHA2('+251988901234',256),AES_ENCRYPT('+251988901234','12345678'),5,'active',4.75,'telebirr'),
('Abrham Kebede',SHA2('+251999012345',256),AES_ENCRYPT('+251999012345','12345678'),1,'suspended',2.30,'cash'),
('Rahel Solomon',SHA2('+251900123456',256),AES_ENCRYPT('+251900123456','12345678'),3,'active',4.95,'cbe_birr');

INSERT INTO drivers (full_name, phone_hash, phone_encrypted, license_number_hash, license_number_encrypted, license_expiry, city_id, vehicle_id, status, current_lat, current_lon, heading_degrees, speed_kmh, location_updated_at, rating, total_rides, total_earnings, acceptance_rate, cancellation_rate, is_background_verified, background_verified_at) VALUES
('Bekele Chala',SHA2('+251901111111',256),AES_ENCRYPT('+251901111111','12345678'),SHA2('ETH-DRV-2019-0001',256),AES_ENCRYPT('ETH-DRV-2019-0001','12345678'),'2027-03-31',1,1,'available',9.022,38.790,90,0.00,DATE_SUB(NOW(),INTERVAL 2 MINUTE),4.85,520,145000.00,94.50,2.30,1,'2024-01-15 09:00:00'),
('Tesfaye Lemma',SHA2('+251902222222',256),AES_ENCRYPT('+251902222222','12345678'),SHA2('ETH-DRV-20

20-0002',256),AES_ENCRYPT('ETH-DRV-2020-0002','12345678'),'2026-09-30',1,2,'busy',9.010,38.760,180,25.50,DATE_SUB(NOW(),INTERVAL 30 SECOND),4.70,310,88000.00,89.00,5.10,1,'2024-02-20 10:00:00'),
('Girma Tadele',SHA2('+251903333333',256),AES_ENCRYPT('+251903333333','12345678'),SHA2('ETH-DRV-2021-0003',256),AES_ENCRYPT('ETH-DRV-2021-0003','12345678'),'2027-06-30',1,3,'available',9.030,38.800,270,0.00,DATE_SUB(NOW(),INTERVAL 1 MINUTE),4.92,780,220000.00,97.20,1.50,1,'2024-01-10 08:00:00'),
('Worku Hailu',SHA2('+251904444444',256),AES_ENCRYPT('+251904444444','12345678'),SHA2('ETH-DRV-2022-0004',256),AES_ENCRYPT('ETH-DRV-2022-0004','12345678'),'2026-12-31',2,3,'available',8.543,39.272,45,0.00,DATE_SUB(NOW(),INTERVAL 5 MINUTE),4.55,190,52000.00,85.00,8.40,1,'2024-03-05 09:30:00'),
('Abebe Negash',SHA2('+251905555555',256),AES_ENCRYPT('+251905555555','12345678'),SHA2('ETH-DRV-2023-0005',256),AES_ENCRYPT('ETH-DRV-2023-0005','12345678'),'2027-01-31',3,NULL,'offline',7.063,38.483,0,0.00,DATE_SUB(NOW(),INTERVAL 2 HOUR),4.40,95,26000.00,80.00,12.60,0,NULL),
('Lema Fekadu',SHA2('+251906666666',256),AES_ENCRYPT('+251906666666','12345678'),SHA2('ETH-DRV-2020-0006',256),AES_ENCRYPT('ETH-DRV-2020-0006','12345678'),'2026-07-31',1,4,'available',9.015,38.755,135,0.00,DATE_SUB(NOW(),INTERVAL 3 MINUTE),4.78,640,182000.00,93.10,3.00,1,'2024-01-22 11:00:00'),
('Dawit Tesfaye',SHA2('+251907777777',256),AES_ENCRYPT('+251907777777','12345678'),SHA2('ETH-DRV-2021-0007',256),AES_ENCRYPT('ETH-DRV-2021-0007','12345678'),'2027-04-30',1,5,'on_break',9.020,38.732,0,0.00,DATE_SUB(NOW(),INTERVAL 15 MINUTE),4.65,430,125000.00,91.00,4.20,1,'2024-02-01 10:00:00');

INSERT INTO rides (user_id,driver_id,vehicle_id,city_id,pickup_zone_id,dropoff_zone_id,status,pickup_lat,pickup_lon,dropoff_lat,dropoff_lon,estimated_distance_km,actual_distance_km,estimated_duration_minutes,actual_duration_minutes,base_fare,surge_multiplier,distance_fare,time_fare,total_fare,driver_earnings,platform_commission,payment_method,requested_at,accepted_at,started_at,completed_at,user_rating,driver_rating,ride_year) VALUES
(1,1,1,1,3,2,'completed',9.024,38.803,9.010,38.791,3.5,3.8,12,14,35.00,1.00,57.00,42.00,134.00,107.20,26.80,'telebirr',DATE_SUB(NOW(),INTERVAL 3 DAY),DATE_SUB(NOW(),INTERVAL 3 DAY),DATE_SUB(NOW(),INTERVAL 3 DAY),DATE_SUB(NOW(),INTERVAL 3 DAY),5,4,YEAR(NOW())),
(2,4,3,2,8,8,'completed',8.541,39.270,8.548,39.277,1.2,1.3,6,7,25.00,1.00,16.90,17.50,59.40,47.52,11.88,'cbe_birr',DATE_SUB(NOW(),INTERVAL 2 DAY),DATE_SUB(NOW(),INTERVAL 2 DAY),DATE_SUB(NOW(),INTERVAL 2 DAY),DATE_SUB(NOW(),INTERVAL 2 DAY),5,5,YEAR(NOW())),
(3,5,NULL,3,9,10,'cancelled',7.062,38.482,7.046,38.468,0.8,NULL,5,NULL,25.00,1.00,NULL,NULL,NULL,NULL,NULL,'cash',DATE_SUB(NOW(),INTERVAL 1 DAY),NULL,NULL,NULL,NULL,NULL,YEAR(NOW())),
(1,3,3,1,5,7,'completed',9.027,38.745,9.016,38.770,4.1,4.3,15,17,35.00,1.20,68.80,59.50,245.70,196.56,49.14,'telebirr',DATE_SUB(NOW(),INTERVAL 1 DAY),DATE_SUB(NOW(),INTERVAL 1 DAY),DATE_SUB(NOW(),INTERVAL 1 DAY),DATE_SUB(NOW(),INTERVAL 1 DAY),4,5,YEAR(NOW())),
(4,1,1,1,2,1,'completed',9.010,38.791,8.978,38.799,4.8,5.1,18,21,80.00,1.00,91.80,84.00,255.80,204.64,51.16,'cash',DATE_SUB(NOW(),INTERVAL 12 HOUR),DATE_SUB(NOW(),INTERVAL 12 HOUR),DATE_SUB(NOW(),INTERVAL 12 HOUR),DATE_SUB(NOW(),INTERVAL 12 HOUR),5,5,YEAR(NOW())),
(5,6,4,1,4,3,'completed',9.018,38.756,9.024,38.803,2.1,2.2,9,10,30.00,1.50,52.80,35.00,162.80,130.24,32.56,'cash',DATE_SUB(NOW(),INTERVAL 8 HOUR),DATE_SUB(NOW(),INTERVAL 8 HOUR),DATE_SUB(NOW(),INTERVAL 8 HOUR),DATE_SUB(NOW(),INTERVAL 8 HOUR),4,4,YEAR(NOW())),
(1,2,2,1,3,6,'in_progress',9.024,38.803,9.021,38.731,5.2,NULL,20,NULL,30.00,2.00,NULL,NULL,NULL,NULL,NULL,'telebirr',DATE_SUB(NOW(),INTERVAL 25 MINUTE),DATE_SUB(NOW(),INTERVAL 22 MINUTE),DATE_SUB(NOW(),INTERVAL 12 MINUTE),NULL,NULL,NULL,YEAR(NOW())),
(7,3,3,1,7,5,'completed',9.040,38.810,9.027,38.745,4.7,4.9,17,19,30.00,1.00,73.50,57.00,160.50,128.40,32.10,'cash',DATE_SUB(NOW(),INTERVAL 5 HOUR),DATE_SUB(NOW(),INTERVAL 5 HOUR),DATE_SUB(NOW(),INTERVAL 5 HOUR),DATE_SUB(NOW(),INTERVAL 5 HOUR),5,5,YEAR(NOW()));

IN

SERT INTO payments (ride_id,user_id,driver_id,amount,payment_method,status,gateway_reference_encrypted,initiated_at,completed_at,idempotency_key) VALUES
(1,1,1,134.00,'telebirr','completed',AES_ENCRYPT('TBIRR-REF-001','12345678'),DATE_SUB(NOW(),INTERVAL 3 DAY),DATE_SUB(NOW(),INTERVAL 3 DAY),CONCAT('idem-r1-u1-',UUID())),
(2,2,4,59.40,'cbe_birr','completed',AES_ENCRYPT('CBEBIRR-REF-002','12345678'),DATE_SUB(NOW(),INTERVAL 2 DAY),DATE_SUB(NOW(),INTERVAL 2 DAY),CONCAT('idem-r2-u2-',UUID())),
(4,1,3,245.70,'telebirr','completed',AES_ENCRYPT('TBIRR-REF-004','12345678'),DATE_SUB(NOW(),INTERVAL 1 DAY),DATE_SUB(NOW(),INTERVAL 1 DAY),CONCAT('idem-r4-u1-',UUID())),
(5,4,1,255.80,'cash','completed',NULL,DATE_SUB(NOW(),INTERVAL 12 HOUR),DATE_SUB(NOW(),INTERVAL 12 HOUR),CONCAT('idem-r5-u4-',UUID())),
(6,5,6,162.80,'cash','completed',NULL,DATE_SUB(NOW(),INTERVAL 8 HOUR),DATE_SUB(NOW(),INTERVAL 8 HOUR),CONCAT('idem-r6-u5-',UUID())),
(8,7,3,160.50,'cash','completed',NULL,DATE_SUB(NOW(),INTERVAL 5 HOUR),DATE_SUB(NOW(),INTERVAL 5 HOUR),CONCAT('idem-r8-u7-',UUID()));

INSERT INTO driver_earnings (driver_id,ride_id,gross_amount,commission_rate,commission_amount,net_amount,payout_status) VALUES
(1,1,134.00,0.2000,26.80,107.20,'paid'),(4,2,59.40,0.2000,11.88,47.52,'paid'),
(3,4,245.70,0.2000,49.14,196.56,'paid'),(1,5,255.80,0.2000,51.16,204.64,'paid'),
(6,6,162.80,0.2000,32.56,130.24,'paid'),(3,8,160.50,0.2000,32.10,128.40,'paid');

INSERT INTO surge_pricing_events (zone_id,city_id,multiplier,reason,active_from,active_until,demand_count,supply_count) VALUES
(1,1,1.80,'Airport peak hours',DATE_SUB(NOW(),INTERVAL 1 HOUR),DATE_ADD(NOW(),INTERVAL 2 HOUR),45,12),
(3,1,2.00,'Morning rush Megenagna',DATE_SUB(NOW(),INTERVAL 30 MINUTE),DATE_ADD(NOW(),INTERVAL 90 MINUTE),78,15),
(4,1,1.50,'Mexico Square spike',DATE_SUB(NOW(),INTERVAL 15 MINUTE),DATE_ADD(NOW(),INTERVAL 165 MINUTE),30,10),
(8,2,1.30,'Adama market day',DATE_SUB(NOW(),INTERVAL 2 HOUR),DATE_ADD(NOW(),INTERVAL 3 HOUR),20,8);

INSERT INTO fraud_flags (entity_type,entity_id,flag_type,severity,description,evidence) VALUES
('user',9,'fake_gps','high','User GPS coordinates inconsistent with travel speed','{"anomaly_count":5,"max_speed_kmh":450}'),
('driver',5,'rating_manipulation','medium','Unusual 5-star pattern from same device','{"suspicious_ratings":12}'),
('user',9,'payment_chargeback','critical','Multiple chargebacks detected','{"chargeback_count":3,"total_amount_etb":890.50}');

INSERT INTO roles (role_name,description,is_system_role) VALUES
('super_admin','Full system access',1),('city_admin','City-level admin',1),
('support_agent','Customer support',1),('driver','Driver access',1),
('passenger','Passenger access',1),('analytics_viewer','Read-only analytics',1),
('fraud_investigator','Fraud investigation',1);

INSERT INTO permissions (permission_key,description,resource,action) VALUES
('rides.read.all','Read all rides','rides','read'),('rides.read.own','Read own rides','rides','read'),
('rides.write','Create/update rides','rides','write'),('rides.cancel.any','Cancel any ride','rides','cancel'),
('rides.cancel.own','Cancel own rides','rides','cancel'),('drivers.read.all','Read all drivers','drivers','read'),
('drivers.write','Create/update drivers','drivers','write'),('drivers.suspend','Suspend drivers','drivers','suspend'),
('users.read.all','Read all users','users','read'),('users.read.own','Read own profile','users','read'),
('users.write','Create/update users','users','write'),('users.suspend','Suspend users','users','suspend'),
('payments.read.all','Read all payments','payments','read'),('payments.read.own','Read own payments','payments','read'),
('payments.refund','Issue refunds','payments','refund'),('audit.read','Read audit logs','audit','read'),
('fraud.read','Read fraud flags','fraud','read'),('fraud.write','Manage fraud flags','fraud','write'),
('reporting.read','Access reports','reporting','read'),('surge.write','Manage surge pricing','surge','write'),
('drivers.location.read','Read driver locations','drivers','location_read'),
('drivers.earnings.read.own','Read own earnings','

drivers','read');

INSERT INTO role_permissions (role_id, permission_id, granted_by)
SELECT r.role_id, p.permission_id, 'system' FROM roles r, permissions p WHERE r.role_name = 'super_admin';
INSERT INTO role_permissions (role_id, permission_id, granted_by)
SELECT r.role_id, p.permission_id, 'system' FROM roles r JOIN permissions p
ON p.permission_key IN ('rides.read.all','rides.write','rides.cancel.any','drivers.read.all','drivers.write','drivers.suspend','users.read.all','users.write','users.suspend','payments.read.all','payments.refund','audit.read','reporting.read','surge.write','drivers.location.read')
WHERE r.role_name = 'city_admin';
INSERT INTO role_permissions (role_id, permission_id, granted_by)
SELECT r.role_id, p.permission_id, 'system' FROM roles r JOIN permissions p
ON p.permission_key IN ('rides.read.own','rides.cancel.own','users.read.own','payments.read.own','drivers.earnings.read.own')
WHERE r.role_name = 'passenger';
INSERT INTO role_permissions (role_id, permission_id, granted_by)
SELECT r.role_id, p.permission_id, 'system' FROM roles r JOIN permissions p
ON p.permission_key IN ('rides.read.own','drivers.earnings.read.own','drivers.location.read','payments.read.own')
WHERE r.role_name = 'driver';
INSERT INTO role_permissions (role_id, permission_id, granted_by)
SELECT r.role_id, p.permission_id, 'system' FROM roles r JOIN permissions p
ON p.permission_key IN ('audit.read','fraud.read','fraud.write','users.read.all','users.suspend','drivers.read.all','drivers.suspend')
WHERE r.role_name = 'fraud_investigator';

INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.user_id, r.role_id, 'system' FROM users u, roles r WHERE u.full_name='Abel Tesfaye' AND r.role_name='passenger';
INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.user_id, r.role_id, 'system' FROM users u, roles r WHERE u.full_name='Sara Alemu' AND r.role_name='passenger';
INSERT INTO user_roles (user_id, role_id, granted_by)
SELECT u.user_id, r.role_id, 'system' FROM users u, roles r WHERE u.full_name='Dawit Haile' AND r.role_name='passenger';
INSERT INTO user_roles (driver_id, role_id, granted_by)
SELECT d.driver_id, r.role_id, 'system' FROM drivers d, roles r WHERE d.full_name='Bekele Chala' AND r.role_name='driver';
INSERT INTO user_roles (driver_id, role_id, granted_by)
SELECT d.driver_id, r.role_id, 'system' FROM drivers d, roles r WHERE d.full_name='Tesfaye Lemma' AND r.role_name='driver';

INSERT INTO shards (shard_name,shard_key,city_region,host,port,database_name,is_primary) VALUES
('shard-addis-01-primary','addis_ababa','addis_ababa','db-addis-01.ridehail.et',3306,'ridehail_addis',1),
('shard-addis-01-replica','addis_ababa','addis_ababa','db-addis-02.ridehail.et',3306,'ridehail_addis',0),
('shard-adama-01-primary','adama','adama','db-adama-01.ridehail.et',3306,'ridehail_adama',1),
('shard-adama-01-replica','adama','adama','db-adama-02.ridehail.et',3306,'ridehail_adama',0),
('shard-hawassa-01-primary','hawassa','hawassa','db-hawassa-01.ridehail.et',3306,'ridehail_hawassa',1),
('shard-diredawa-01-primary','dire_dawa','dire_dawa','db-diredawa-01.ridehail.et',3306,'ridehail_diredawa',1),
('shard-bahirdar-01-primary','bahir_dar','bahir_dar','db-bahirdar-01.ridehail.et',3306,'ridehail_bahirdar',1);

INSERT INTO event_log (event_type,entity_type,entity_id,actor_type,actor_id,city_id,payload,severity,log_year,log_quarter) VALUES
('login','user',1,'user',1,1,'{"method":"telebirr_otp","device":"android"}','info',YEAR(NOW()),QUARTER(NOW())),
('login','driver',1,'driver',1,1,'{"method":"phone_otp","device":"android"}','info',YEAR(NOW()),QUARTER(NOW())),
('login','user',9,'user',9,1,'{"method":"phone_otp","suspicious":true}','warning',YEAR(NOW()),QUARTER(NOW())),
('ride_request','ride',7,'user',1,1,'{"status":"requested","pickup_zone":3}','info',YEAR(NOW()),QUARTER(NOW())),
('ride_accept','ride',7,'driver',2,1,'{"surge_multiplier":2.00}','info',YEAR(NOW()),QUARTER(NOW())),
('fraud_flag','user',9,'system',NULL,1,'{"flag_type":"fake_gps","severity":"high"}','warning',YEAR(NOW()),QUARTER(NOW())),
('payment','payment',1,'user'

,1,1,'{"amount":134.00,"method":"telebirr"}','info',YEAR(NOW()),QUARTER(NOW())),
('admin_action','user',9,'user',NULL,1,'{"action":"suspend","reason":"fraud"}','warning',YEAR(NOW()),QUARTER(NOW()));

INSERT INTO sync_checkpoints (shard_id, last_synced_at, records_synced, sync_status)
SELECT shard_id, NOW(), 0, 'completed' FROM shards;

UPDATE shards SET last_health_check = NOW(), replication_lag_seconds = ROUND(RAND() * 2, 3) WHERE is_active = 1;
