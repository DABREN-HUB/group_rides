
-- PART 1: DATABASE, USER AND INITIAL SETUP
CREATE DATABASE IF NOT EXISTS ridehail_ethiopia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'ridehail_admin'@'localhost' IDENTIFIED BY '12345678';
GRANT ALL PRIVILEGES ON ridehail_ethiopia.* TO 'ridehail_admin'@'localhost';
FLUSH PRIVILEGES;
USE ridehail_ethiopia;
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE TABLE IF NOT EXISTS cities (
    city_id INT NOT NULL AUTO_INCREMENT,
    city_name VARCHAR(100) NOT NULL,
    region ENUM('addis_ababa','adama','hawassa','dire_dawa','bahir_dar','mekelle','gondar','jimma','dessie','debre_birhan') NOT NULL,
    country_code CHAR(2) NOT NULL DEFAULT 'ET',
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'Africa/Addis_Ababa',
    population INT DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    surge_multiplier_default DECIMAL(4,2) NOT NULL DEFAULT 1.00,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (city_id),
    UNIQUE KEY uq_city_name (city_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS zones (
    zone_id INT NOT NULL AUTO_INCREMENT,
    city_id INT NOT NULL,
    zone_name VARCHAR(150) NOT NULL,
    zone_code VARCHAR(20) NOT NULL,
    center_lat DECIMAL(10,8) NOT NULL,
    center_lon DECIMAL(11,8) NOT NULL,
    radius_meters INT NOT NULL DEFAULT 2000,
    base_fare DECIMAL(10,2) NOT NULL DEFAULT 30.00,
    per_km_rate DECIMAL(10,2) NOT NULL DEFAULT 15.00,
    per_minute_rate DECIMAL(10,2) NOT NULL DEFAULT 3.00,
    is_airport_zone TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (zone_id),
    CONSTRAINT fk_zone_city FOREIGN KEY (city_id) REFERENCES cities(city_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS vehicles (
    vehicle_id BIGINT NOT NULL AUTO_INCREMENT,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year SMALLINT NOT NULL,
    color VARCHAR(50) NOT NULL,
    plate_number_hash VARCHAR(64) NOT NULL,
    plate_number_encrypted BLOB NOT NULL,
    vehicle_type ENUM('sedan','minivan','suv','motorcycle','tuk_tuk') NOT NULL DEFAULT 'sedan',
    capacity SMALLINT NOT NULL DEFAULT 4,
    is_ac_available TINYINT(1) NOT NULL DEFAULT 0,
    insurance_expiry DATE NOT NULL,
    inspection_expiry DATE NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (vehicle_id),
    UNIQUE KEY uq_plate_hash (plate_number_hash)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS promo_codes (
    promo_id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL DEFAULT 'percentage',
    discount_value DECIMAL(10,2) NOT NULL,
    max_discount_etb DECIMAL(10,2) DEFAULT NULL,
    min_ride_fare DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    usage_limit INT DEFAULT NULL,
    usage_count INT NOT NULL DEFAULT 0,
    per_user_limit INT NOT NULL DEFAULT 1,
    city_id INT DEFAULT NULL,
    valid_from DATETIME NOT NULL,
    valid_until DATETIME NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (promo_id),
    UNIQUE KEY uq_promo_code (code),
    CONSTRAINT fk_promo_city FOREIGN KEY (city_id) REFERENCES cities(city_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- PART 2: USER AND PHONE TABLES
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT NOT NULL AUTO_INCREMENT,
    external_id CHAR(36) NOT NULL DEFAULT (UUID()),
    full_name VARCHAR(255) NOT NULL,
    phone_hash VARCHAR(64) NOT NULL,
    phone_encrypted BLOB NOT NULL,
    email_hash VARCHAR(64) DEFAULT NULL,
    email_encrypted BLOB DEFAULT NULL,
    city_id INT NOT NULL,
    national_id_hash VARCHAR(64) DEFAULT NULL,
    national_id_encrypted BLOB DEFAULT NULL,
    status ENUM('active','suspended','banned','pending_verification') NOT NULL DEFAULT 'pending_verification',
    rating DECIMAL(3,2) NOT NULL DEFAULT 5.00,
    total_rides INT NOT NULL DEFAULT 0,
    preferred_payment ENUM('cash','telebirr','cbe_birr','awash_pay','amole','card') NOT NULL DEFAULT 'cash',
    language_preference VARCHAR(10) NOT NULL DEFAULT 'am',
    last_known_lat DECIMAL(10,8) DEFAULT NULL,
    last_known_lon DECIMAL(11,8) DEFAULT NULL,
    last_location_updated DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_user_external (external_id),
    UNIQUE KEY uq_user_phone (phone_hash),
    CONSTRAINT fk_user_city FOREIGN KEY (city_id) REFERENCES cities(city_id),
    CONSTRAINT chk_user_rating CHECK (rating >= 1.0 AND rating <= 5.0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_phones (
    phone_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    phone_hash VARCHAR(64) NOT NULL,
    phone_encrypted BLOB NOT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    verified_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (phone_id),
    CONSTRAINT fk_uphone_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS drivers (
    driver_id BIGINT NOT NULL AUTO_INCREMENT,
    external_id CHAR(36) NOT NULL DEFAULT (UUID()),
    full_name VARCHAR(255) NOT NULL,
    phone_hash VARCHAR(64) NOT NULL,
    phone_encrypted BLOB NOT NULL,
    license_number_hash VARCHAR(64) NOT NULL,
    license_number_encrypted BLOB NOT NULL,
    license_expiry DATE NOT NULL,
    city_id INT NOT NULL,
    vehicle_id BIGINT DEFAULT NULL,
    status ENUM('available','busy','offline','on_break') NOT NULL DEFAULT 'offline',
    current_lat DECIMAL(10,8) DEFAULT NULL,
    current_lon DECIMAL(11,8) DEFAULT NULL,
    heading_degrees SMALLINT DEFAULT NULL,
    speed_kmh DECIMAL(5,2) DEFAULT NULL,
    location_updated_at DATETIME DEFAULT NULL,
    rating DECIMAL(3,2) NOT NULL DEFAULT 5.00,
    total_rides INT NOT NULL DEFAULT 0,
    total_earnings DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    acceptance_rate DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    cancellation_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    is_background_verified TINYINT(1) NOT NULL DEFAULT 0,
    background_verified_at DATETIME DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME DEFAULT NULL,
    PRIMARY KEY (driver_id),
    UNIQUE KEY uq_driver_external (external_id),
    UNIQUE KEY uq_driver_phone (phone_hash),
    UNIQUE KEY uq_driver_license (license_number_hash),
    CONSTRAINT fk_driver_city FOREIGN KEY (city_id) REFERENCES cities(city_id),
    CONSTRAINT fk_driver_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE SET NULL,
    CONSTRAINT chk_driver_rating CHECK (rating >= 1.0 AND rating <= 5.0)
) ENGINE=InnoDB;

-- PART 3: DRIVER LOCATION HISTORY TABLE WITH PARTITIONING
CREATE TABLE IF NOT EXISTS driver_location_history (
    location_id BIGINT NOT NULL AUTO_INCREMENT,
    driver_id BIGINT NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    heading_degrees SMALLINT DEFAULT NULL,
    speed_kmh DECIMAL(5,2) DEFAULT NULL,
    accuracy_meters DECIMAL(8,2) DEFAULT NULL,
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ride_id BIGINT DEFAULT NULL,
    record_year SMALLINT NOT NULL,
    record_quarter TINYINT NOT NULL,
    PRIMARY KEY (location_id, record_year, record_quarter),
    KEY idx_dlh_driver_time (driver_id, recorded_at),
    KEY idx_dlh_coords (latitude, longitude),
    KEY idx_dlh_ride (ride_id)
) ENGINE=InnoDB
PARTITION BY RANGE COLUMNS(record_year, record_quarter) (
    PARTITION p2024_q1 VALUES LESS THAN (2024, 2),
    PARTITION p2024_q2 VALUES LESS THAN (2024, 3),
    PARTITION p2024_q3 VALUES LESS THAN (2024, 4),
    PARTITION p2024_q4 VALUES LESS THAN (2025, 1),
    PARTITION p2025_q1 VALUES LESS THAN (2025, 2),
    PARTITION p2025_q2 VALUES LESS THAN (2025, 3),
    PARTITION p2025_q3 VALUES LESS THAN (2025, 4),
    PARTITION p2025_q4 VALUES LESS THAN (2026, 1),
    PARTITION p2026_q1 VALUES LESS THAN (2026, 2),
    PARTITION p2026_q2 VALUES LESS THAN (2026, 3),
    PARTITION p2026_q3 VALUES LESS THAN (2026, 4),
    PARTITION p2026_q4 VALUES LESS THAN (2027, 1),
    PARTITION p_future VALUES LESS THAN (MAXVALUE, MAXVALUE)
);

CREATE TABLE IF NOT EXISTS ride_status_history (
    history_id BIGINT NOT NULL AUTO_INCREMENT,
    ride_id BIGINT NOT NULL,
    from_status ENUM('requested','accepted','driver_en_route','in_progress','completed','cancelled','disputed') DEFAULT NULL,
    to_status ENUM('requested','accepted','driver_en_route','in_progress','completed','cancelled','disputed') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by_user_id BIGINT DEFAULT NULL,
    changed_by_driver_id BIGINT DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    latitude DECIMAL(10,8) DEFAULT NULL,
    longitude DECIMAL(11,8) DEFAULT NULL,
    PRIMARY KEY (history_id),
    KEY idx_rsh_ride (ride_id, changed_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fraud_flags (
    flag_id BIGINT NOT NULL AUTO_INCREMENT,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    flag_type VARCHAR(100) NOT NULL,
    severity ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
    description TEXT NOT NULL,
    evidence JSON DEFAULT NULL,
    flagged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    flagged_by VARCHAR(100) NOT NULL DEFAULT 'system',
    resolved_at DATETIME DEFAULT NULL,
    resolved_by VARCHAR(100) DEFAULT NULL,
    resolution_notes TEXT DEFAULT NULL,
    is_resolved TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (flag_id),
    KEY idx_ff_entity (entity_type, entity_id),
    KEY idx_ff_severity (severity, flagged_at)
) ENGINE=InnoDB;

-- PART 4: RIDES TABLE WITH YEAR-BASED PARTITIONING
CREATE TABLE IF NOT EXISTS rides (
    ride_id BIGINT NOT NULL AUTO_INCREMENT,
    external_id CHAR(36) NOT NULL DEFAULT (UUID()),
    user_id BIGINT NOT NULL,
    driver_id BIGINT DEFAULT NULL,
    vehicle_id BIGINT DEFAULT NULL,
    city_id INT NOT NULL,
    pickup_zone_id INT DEFAULT NULL,
    dropoff_zone_id INT DEFAULT NULL,
    status ENUM('requested','accepted','driver_en_route','in_progress','completed','cancelled','disputed') NOT NULL DEFAULT 'requested',
    pickup_lat DECIMAL(10,8) NOT NULL,
    pickup_lon DECIMAL(11,8) NOT NULL,
    pickup_address_encrypted BLOB DEFAULT NULL,
    dropoff_lat DECIMAL(10,8) NOT NULL,
    dropoff_lon DECIMAL(11,8) NOT NULL,
    dropoff_address_encrypted BLOB DEFAULT NULL,
    estimated_distance_km DECIMAL(8,3) DEFAULT NULL,
    actual_distance_km DECIMAL(8,3) DEFAULT NULL,
    estimated_duration_minutes SMALLINT DEFAULT NULL,
    actual_duration_minutes SMALLINT DEFAULT NULL,
    base_fare DECIMAL(10,2) DEFAULT NULL,
    surge_multiplier DECIMAL(4,2) NOT NULL DEFAULT 1.00,
    distance_fare DECIMAL(10,2) DEFAULT NULL,
    time_fare DECIMAL(10,2) DEFAULT NULL,
    total_fare DECIMAL(10,2) DEFAULT NULL,
    driver_earnings DECIMAL(10,2) DEFAULT NULL,
    platform_commission DECIMAL(10,2) DEFAULT NULL,
    payment_method ENUM('cash','telebirr','cbe_birr','awash_pay','amole','card') NOT NULL DEFAULT 'cash',
    requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at DATETIME DEFAULT NULL,
    driver_arrived_at DATETIME DEFAULT NULL,
    started_at DATETIME DEFAULT NULL,
    completed_at DATETIME DEFAULT NULL,
    cancelled_at DATETIME DEFAULT NULL,
    cancellation_reason VARCHAR(255) DEFAULT NULL,
    cancelled_by VARCHAR(50) DEFAULT NULL,
    user_rating TINYINT DEFAULT NULL,
    driver_rating TINYINT DEFAULT NULL,
    user_feedback TEXT DEFAULT NULL,
    is_scheduled TINYINT(1) NOT NULL DEFAULT 0,
    scheduled_for DATETIME DEFAULT NULL,
    version INT NOT NULL DEFAULT 1,
    ride_year SMALLINT NOT NULL,
    PRIMARY KEY (ride_id, ride_year),
    UNIQUE KEY uq_ride_external (external_id, ride_year),
    KEY idx_ride_user (user_id, requested_at),
    KEY idx_ride_driver (driver_id, requested_at),
    KEY idx_ride_city (city_id, requested_at),
    KEY idx_ride_status (status),
    KEY idx_ride_pickup (pickup_lat, pickup_lon),
    KEY idx_ride_completed (completed_at),
    CONSTRAINT chk_user_rating CHECK (user_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_driver_rating_val CHECK (driver_rating BETWEEN 1 AND 5),
    CONSTRAINT chk_surge CHECK (surge_multiplier >= 1.00 AND surge_multiplier <= 10.00)
) ENGINE=InnoDB
PARTITION BY RANGE (ride_year) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- PART 5: PAYMENT, EARNINGS AND SURGE PRICING TABLES
CREATE TABLE IF NOT EXISTS payments (
    payment_id BIGINT NOT NULL AUTO_INCREMENT,
    external_id CHAR(36) NOT NULL DEFAULT (UUID()),
    ride_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    driver_id BIGINT DEFAULT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'ETB',
    payment_method ENUM('cash','telebirr','cbe_birr','awash_pay','amole','card') NOT NULL,
    status ENUM('pending','processing','completed','failed','refunded','disputed') NOT NULL DEFAULT 'pending',
    gateway_reference_encrypted BLOB DEFAULT NULL,
    gateway_response JSON DEFAULT NULL,
    initiated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME DEFAULT NULL,
    failed_at DATETIME DEFAULT NULL,
    refunded_at DATETIME DEFAULT NULL,
    refund_amount DECIMAL(12,2) DEFAULT NULL,
    refund_reason TEXT DEFAULT NULL,
    idempotency_key VARCHAR(255) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    PRIMARY KEY (payment_id),
    UNIQUE KEY uq_payment_external (external_id),
    UNIQUE KEY uq_idempotency (idempotency_key),
    KEY idx_pay_ride (ride_id),
    KEY idx_pay_user (user_id, initiated_at),
    KEY idx_pay_status (status),
    CONSTRAINT fk_pay_user FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS driver_earnings (
    earning_id BIGINT NOT NULL AUTO_INCREMENT,
    driver_id BIGINT NOT NULL,
    ride_id BIGINT NOT NULL,
    gross_amount DECIMAL(12,2) NOT NULL,
    commission_rate DECIMAL(5,4) NOT NULL,
    commission_amount DECIMAL(12,2) NOT NULL,
    net_amount DECIMAL(12,2) NOT NULL,
    bonus_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    deductions DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    payout_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    payout_date DATE DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (earning_id),
    KEY idx_de_driver (driver_id),
    KEY idx_de_ride (ride_id),
    CONSTRAINT fk_de_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS surge_pricing_events (
    event_id BIGINT NOT NULL AUTO_INCREMENT,
    zone_id INT NOT NULL,
    city_id INT NOT NULL,
    multiplier DECIMAL(4,2) NOT NULL,
    reason VARCHAR(255) DEFAULT NULL,
    active_from DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active_until DATETIME NOT NULL,
    demand_count INT NOT NULL DEFAULT 0,
    supply_count INT NOT NULL DEFAULT 0,
    created_by VARCHAR(100) NOT NULL DEFAULT 'system',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (event_id),
    KEY idx_surge_zone (zone_id, is_active, active_from, active_until),
    KEY idx_surge_city (city_id, is_active),
    CONSTRAINT fk_surge_zone FOREIGN KEY (zone_id) REFERENCES zones(zone_id),
    CONSTRAINT fk_surge_city FOREIGN KEY (city_id) REFERENCES cities(city_id)
) ENGINE=InnoDB;

-- PART 6: AUDIT EVENT LOG TABLE WITH QUARTERLY PARTITIONING
CREATE TABLE IF NOT EXISTS event_log (
    log_id BIGINT NOT NULL AUTO_INCREMENT,
    event_type ENUM('login','logout','ride_request','ride_accept','ride_cancel','payment','profile_update','location_update','admin_action','fraud_flag','system_error') NOT NULL,
    entity_type VARCHAR(50) DEFAULT NULL,
    entity_id BIGINT DEFAULT NULL,
    actor_type VARCHAR(50) DEFAULT NULL,
    actor_id BIGINT DEFAULT NULL,
    actor_ip_encrypted BLOB DEFAULT NULL,
    actor_device_hash VARCHAR(64) DEFAULT NULL,
    city_id INT DEFAULT NULL,
    payload JSON DEFAULT NULL,
    old_values JSON DEFAULT NULL,
    new_values JSON DEFAULT NULL,
    session_id CHAR(36) DEFAULT NULL,
    occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    severity ENUM('info','warning','error','critical') NOT NULL DEFAULT 'info',
    log_year SMALLINT NOT NULL,
    log_quarter TINYINT NOT NULL,
    PRIMARY KEY (log_id, log_year, log_quarter),
    KEY idx_log_event_type (event_type, occurred_at),
    KEY idx_log_actor (actor_type, actor_id, occurred_at),
    KEY idx_log_entity (entity_type, entity_id, occurred_at),
    KEY idx_log_severity (severity, occurred_at)
) ENGINE=InnoDB
PARTITION BY RANGE COLUMNS(log_year, log_quarter) (
    PARTITION p2025_q1 VALUES LESS THAN (2025, 2),
    PARTITION p2025_q2 VALUES LESS THAN (2025, 3),
    PARTITION p2025_q3 VALUES LESS THAN (2025, 4),
    PARTITION p2025_q4 VALUES LESS THAN (2026, 1),
    PARTITION p2026_q1 VALUES LESS THAN (2026, 2),
    PARTITION p2026_q2 VALUES LESS THAN (2026, 3),
    PARTITION p2026_q3 VALUES LESS THAN (2026, 4),
    PARTITION p2026_q4 VALUES LESS THAN (2027, 1),
    PARTITION p_future VALUES LESS THAN (MAXVALUE, MAXVALUE)
);

-- PART 7: SECURITY, ROLES, PERMISSIONS AND DISTRIBUTED TABLES
CREATE TABLE IF NOT EXISTS roles (
    role_id INT NOT NULL AUTO_INCREMENT,
    role_name ENUM('super_admin','city_admin','support_agent','driver','passenger','analytics_viewer','fraud_investigator') NOT NULL,
    description TEXT DEFAULT NULL,
    is_system_role TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_role_name (role_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS permissions (
    permission_id INT NOT NULL AUTO_INCREMENT,
    permission_key VARCHAR(200) NOT NULL,
    description TEXT DEFAULT NULL,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (permission_id),
    UNIQUE KEY uq_perm_key (permission_key)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by VARCHAR(100) NOT NULL DEFAULT 'system',
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_perm FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_roles (
    user_role_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT DEFAULT NULL,
    driver_id BIGINT DEFAULT NULL,
    role_id INT NOT NULL,
    city_id INT DEFAULT NULL,
    granted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    granted_by VARCHAR(100) NOT NULL,
    expires_at DATETIME DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (user_role_id),
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS encryption_keys (
    key_id INT NOT NULL AUTO_INCREMENT,
    key_version INT NOT NULL,
    key_purpose VARCHAR(100) NOT NULL,
    key_hash VARCHAR(64) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rotated_at DATETIME DEFAULT NULL,
    expires_at DATETIME DEFAULT NULL,
    PRIMARY KEY (key_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS shards (
    shard_id INT NOT NULL AUTO_INCREMENT,
    shard_name VARCHAR(100) NOT NULL,
    shard_key VARCHAR(100) NOT NULL,
    city_region ENUM('addis_ababa','adama','hawassa','dire_dawa','bahir_dar','mekelle','gondar','jimma','dessie','debre_birhan') NOT NULL,
    host VARCHAR(255) NOT NULL,
    port INT NOT NULL DEFAULT 3306,
    database_name VARCHAR(100) NOT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 1,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    replication_lag_seconds DECIMAL(8,3) DEFAULT NULL,
    last_health_check DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (shard_id),
    UNIQUE KEY uq_shard_name (shard_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS replication_log (
    replication_id BIGINT NOT NULL AUTO_INCREMENT,
    shard_id INT NOT NULL,
    operation VARCHAR(20) NOT NULL,
    table_name VARCHAR(200) NOT NULL,
    record_id BIGINT DEFAULT NULL,
    payload JSON DEFAULT NULL,
    replicated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_applied TINYINT(1) NOT NULL DEFAULT 0,
    retry_count SMALLINT NOT NULL DEFAULT 0,
    error_message TEXT DEFAULT NULL,
    PRIMARY KEY (replication_id),
    CONSTRAINT fk_rl_shard FOREIGN KEY (shard_id) REFERENCES shards(shard_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sync_checkpoints (
    checkpoint_id BIGINT NOT NULL AUTO_INCREMENT,
    shard_id INT NOT NULL,
    last_synced_position VARCHAR(100) DEFAULT NULL,
    last_synced_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    records_synced BIGINT NOT NULL DEFAULT 0,
    sync_status VARCHAR(50) NOT NULL DEFAULT 'completed',
    PRIMARY KEY (checkpoint_id),
    CONSTRAINT fk_sc_shard FOREIGN KEY (shard_id) REFERENCES shards(shard_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS daily_city_metrics (
    metric_id BIGINT NOT NULL AUTO_INCREMENT,
    city_id INT NOT NULL,
    metric_date DATE NOT NULL,
    total_rides INT NOT NULL DEFAULT 0,
    completed_rides INT NOT NULL DEFAULT 0,
    cancelled_rides INT NOT NULL DEFAULT 0,
    total_revenue DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    total_driver_earnings DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    total_platform_revenue DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    avg_ride_duration_minutes DECIMAL(8,2) DEFAULT NULL,
    avg_ride_distance_km DECIMAL(8,3) DEFAULT NULL,
    avg_fare_etb DECIMAL(10,2) DEFAULT NULL,
    avg_surge_multiplier DECIMAL(4,2) DEFAULT NULL,
    peak_hour TINYINT DEFAULT NULL,
    active_drivers INT NOT NULL DEFAULT 0,
    new_users INT NOT NULL DEFAULT 0,
    fraud_flags_raised INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (metric_id),
    UNIQUE KEY uq_metric_city_date (city_id, metric_date),
    KEY idx_metric_date (metric_date),
    CONSTRAINT fk_metric_city FOREIGN KEY (city_id) REFERENCES cities(city_id)
) ENGINE=InnoDB;

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
('Tesfaye Lemma',SHA2('+251902222222',256),AES_ENCRYPT('+251902222222','12345678'),SHA2('ETH-DRV-2020-0002',256),AES_ENCRYPT('ETH-DRV-2020-0002','12345678'),'2026-09-30',1,2,'busy',9.010,38.760,180,25.50,DATE_SUB(NOW(),INTERVAL 30 SECOND),4.70,310,88000.00,89.00,5.10,1,'2024-02-20 10:00:00'),
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

INSERT INTO payments (ride_id,user_id,driver_id,amount,payment_method,status,gateway_reference_encrypted,initiated_at,completed_at,idempotency_key) VALUES
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
('drivers.earnings.read.own','Read own earnings','drivers','read');

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
('payment','payment',1,'user',1,1,'{"amount":134.00,"method":"telebirr"}','info',YEAR(NOW()),QUARTER(NOW())),
('admin_action','user',9,'user',NULL,1,'{"action":"suspend","reason":"fraud"}','warning',YEAR(NOW()),QUARTER(NOW()));

INSERT INTO sync_checkpoints (shard_id, last_synced_at, records_synced, sync_status)
SELECT shard_id, NOW(), 0, 'completed' FROM shards;

UPDATE shards SET last_health_check = NOW(), replication_lag_seconds = ROUND(RAND() * 2, 3) WHERE is_active = 1;

-- PART 9: STORED FUNCTIONS AND PROCEDURES
DELIMITER //

CREATE FUNCTION IF NOT EXISTS fn_haversine_distance_km(lat1 DECIMAL(10,8), lon1 DECIMAL(11,8), lat2 DECIMAL(10,8), lon2 DECIMAL(11,8))
RETURNS DECIMAL(10,4) DETERMINISTIC
BEGIN
    DECLARE R DECIMAL(10,4) DEFAULT 6371.0;
    DECLARE dlat DECIMAL(20,15);
    DECLARE dlon DECIMAL(20,15);
    DECLARE a DECIMAL(20,15);
    DECLARE c DECIMAL(20,15);
    SET dlat = RADIANS(lat2 - lat1);
    SET dlon = RADIANS(lon2 - lon1);
    SET a = SIN(dlat/2)*SIN(dlat/2) + COS(RADIANS(lat1))*COS(RADIANS(lat2))*SIN(dlon/2)*SIN(dlon/2);
    SET c = 2 * ATAN2(SQRT(a), SQRT(1-a));
    RETURN ROUND(R * c, 4);
END //

CREATE FUNCTION IF NOT EXISTS fn_get_active_surge(p_zone_id INT)
RETURNS DECIMAL(4,2) DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_multiplier DECIMAL(4,2) DEFAULT 1.00;
    SELECT COALESCE(MAX(multiplier),1.00) INTO v_multiplier FROM surge_pricing_events
    WHERE zone_id=p_zone_id AND is_active=1 AND active_from<=NOW() AND active_until>=NOW();
    RETURN v_multiplier;
END //

CREATE FUNCTION IF NOT EXISTS fn_user_has_permission(p_user_id BIGINT, p_permission_key VARCHAR(200))
RETURNS TINYINT(1) DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_has INT DEFAULT 0;
    SELECT COUNT(*) INTO v_has FROM user_roles ur
    JOIN roles r ON ur.role_id=r.role_id JOIN role_permissions rp ON r.role_id=rp.role_id
    JOIN permissions p ON rp.permission_id=p.permission_id
    WHERE ur.user_id=p_user_id AND p.permission_key=p_permission_key AND ur.is_active=1
    AND (ur.expires_at IS NULL OR ur.expires_at > NOW());
    RETURN IF(v_has > 0, 1, 0);
END //

CREATE PROCEDURE IF NOT EXISTS sp_find_nearest_drivers(IN p_lat DECIMAL(10,8), IN p_lon DECIMAL(11,8), IN p_city_id INT, IN p_radius_km DECIMAL(8,3), IN p_limit INT)
BEGIN
    SELECT d.driver_id, d.full_name, v.make, v.model, v.vehicle_type, d.current_lat, d.current_lon,
        ROUND(fn_haversine_distance_km(p_lat, p_lon, d.current_lat, d.current_lon), 3) AS distance_km,
        d.rating, d.total_rides, d.location_updated_at
    FROM drivers d JOIN vehicles v ON d.vehicle_id=v.vehicle_id
    WHERE d.city_id=p_city_id AND d.status='available' AND d.is_active=1 AND d.deleted_at IS NULL
        AND d.current_lat IS NOT NULL AND d.location_updated_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE)
        AND fn_haversine_distance_km(p_lat, p_lon, d.current_lat, d.current_lon) <= p_radius_km
    ORDER BY distance_km ASC, d.rating DESC LIMIT p_limit;
END //

CREATE PROCEDURE IF NOT EXISTS sp_book_ride_atomic(IN p_user_id BIGINT, IN p_driver_id BIGINT, IN p_city_id INT, IN p_pickup_lat DECIMAL(10,8), IN p_pickup_lon DECIMAL(11,8), IN p_dropoff_lat DECIMAL(10,8), IN p_dropoff_lon DECIMAL(11,8), IN p_pickup_zone_id INT, IN p_dropoff_zone_id INT, IN p_payment_method VARCHAR(20), IN p_idempotency_key VARCHAR(255), OUT p_ride_id BIGINT, OUT p_success TINYINT, OUT p_message VARCHAR(255))
BEGIN
    DECLARE v_driver_status VARCHAR(20);
    DECLARE v_vehicle_id BIGINT;
    DECLARE v_base_fare DECIMAL(10,2);
    DECLARE v_per_km DECIMAL(10,2);
    DECLARE v_per_min DECIMAL(10,2);
    DECLARE v_surge DECIMAL(4,2);
    DECLARE v_dist DECIMAL(8,3);
    DECLARE v_dur INT;
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_existing INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET p_success=0; SET p_message='Transaction error'; ROLLBACK; END;
    SELECT COUNT(*) INTO v_existing FROM payments WHERE idempotency_key=p_idempotency_key;
    IF v_existing > 0 THEN SET p_success=0; SET p_message='Duplicate idempotency key'; LEAVE sp_book_ride_atomic; END IF;
    START TRANSACTION;
    SELECT status, vehicle_id INTO v_driver_status, v_vehicle_id FROM drivers WHERE driver_id=p_driver_id FOR UPDATE;
    IF v_driver_status != 'available' THEN
        SET p_success=0; SET p_message=CONCAT('Driver not available: ', v_driver_status); ROLLBACK; LEAVE sp_book_ride_atomic;
    END IF;
    SELECT COALESCE(base_fare,30.00), COALESCE(per_km_rate,15.00), COALESCE(per_minute_rate,3.00)
    INTO v_base_fare, v_per_km, v_per_min FROM zones WHERE zone_id=p_pickup_zone_id;
    SET v_surge = fn_get_active_surge(p_pickup_zone_id);
    SET v_dist = ROUND(fn_haversine_distance_km(p_pickup_lat,p_pickup_lon,p_dropoff_lat,p_dropoff_lon)*1.3, 3);
    SET v_dur = GREATEST(5, ROUND(v_dist/25.0*60));
    SET v_total = ROUND((v_base_fare + v_dist*v_per_km + v_dur*v_per_min) * v_surge, 2);
    INSERT INTO rides (user_id,driver_id,vehicle_id,city_id,pickup_zone_id,dropoff_zone_id,status,pickup_lat,pickup_lon,dropoff_lat,dropoff_lon,estimated_distance_km,estimated_duration_minutes,base_fare,surge_multiplier,total_fare,driver_earnings,platform_commission,payment_method,accepted_at,ride_year)
    VALUES (p_user_id,p_driver_id,v_vehicle_id,p_city_id,p_pickup_zone_id,p_dropoff_zone_id,'accepted',p_pickup_lat,p_pickup_lon,p_dropoff_lat,p_dropoff_lon,v_dist,v_dur,v_base_fare,v_surge,v_total,ROUND(v_total*0.80,2),ROUND(v_total*0.20,2),p_payment_method,NOW(),YEAR(NOW()));
    SET p_ride_id = LAST_INSERT_ID();
    UPDATE drivers SET status='busy', updated_at=NOW() WHERE driver_id=p_driver_id;
    INSERT INTO ride_status_history (ride_id,from_status,to_status,changed_by_driver_id) VALUES (p_ride_id,'requested','accepted',p_driver_id);
    INSERT INTO event_log (event_type,entity_type,entity_id,actor_type,actor_id,city_id,payload,log_year,log_quarter)
    VALUES ('ride_accept','ride',p_ride_id,'driver',p_driver_id,p_city_id,JSON_OBJECT('surge',v_surge,'fare',v_total),YEAR(NOW()),QUARTER(NOW()));
    COMMIT;
    SET p_success=1; SET p_message='Ride booked successfully';
END //

CREATE PROCEDURE IF NOT EXISTS sp_complete_ride(IN p_ride_id BIGINT, IN p_driver_id BIGINT, IN p_actual_dist DECIMAL(8,3), IN p_actual_dur INT, IN p_final_lat DECIMAL(10,8), IN p_final_lon DECIMAL(11,8), OUT p_success TINYINT, OUT p_final_fare DECIMAL(10,2))
BEGIN
    DECLARE v_user_id BIGINT;
    DECLARE v_city_id INT;
    DECLARE v_base_fare DECIMAL(10,2);
    DECLARE v_per_km DECIMAL(10,2);
    DECLARE v_per_min DECIMAL(10,2);
    DECLARE v_surge DECIMAL(4,2);
    DECLARE v_zone_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET p_success=0; ROLLBACK; END;
    START TRANSACTION;
    SELECT user_id, city_id, pickup_zone_id, surge_multiplier INTO v_user_id, v_city_id, v_zone_id, v_surge
    FROM rides WHERE ride_id=p_ride_id AND driver_id=p_driver_id AND status='in_progress' FOR UPDATE;
    IF v_user_id IS NULL THEN SET p_success=0; ROLLBACK; LEAVE sp_complete_ride; END IF;
    SELECT COALESCE(base_fare,30.00), COALESCE(per_km_rate,15.00), COALESCE(per_minute_rate,3.00)
    INTO v_base_fare, v_per_km, v_per_min FROM zones WHERE zone_id=v_zone_id;
    SET p_final_fare = ROUND((v_base_fare + p_actual_dist*v_per_km + p_actual_dur*v_per_min)*v_surge, 2);
    UPDATE rides SET status='completed', actual_distance_km=p_actual_dist, actual_duration_minutes=p_actual_dur,
        total_fare=p_final_fare, driver_earnings=ROUND(p_final_fare*0.80,2), platform_commission=ROUND(p_final_fare*0.20,2),
        completed_at=NOW(), version=version+1 WHERE ride_id=p_ride_id;
    UPDATE drivers SET status='available', total_rides=total_rides+1, total_earnings=total_earnings+ROUND(p_final_fare*0.80,2),
        current_lat=p_final_lat, current_lon=p_final_lon, location_updated_at=NOW() WHERE driver_id=p_driver_id;
    UPDATE users SET total_rides=total_rides+1 WHERE user_id=v_user_id;
    INSERT INTO driver_earnings (driver_id,ride_id,gross_amount,commission_rate,commission_amount,net_amount)
    VALUES (p_driver_id,p_ride_id,p_final_fare,0.20,ROUND(p_final_fare*0.20,2),ROUND(p_final_fare*0.80,2));
    INSERT INTO ride_status_history (ride_id,from_status,to_status,changed_by_driver_id,latitude,longitude)
    VALUES (p_ride_id,'in_progress','completed',p_driver_id,p_final_lat,p_final_lon);
    COMMIT;
    SET p_success=1;
END //

CREATE PROCEDURE IF NOT EXISTS sp_update_driver_location(IN p_driver_id BIGINT, IN p_lat DECIMAL(10,8), IN p_lon DECIMAL(11,8), IN p_heading SMALLINT, IN p_speed DECIMAL(5,2), IN p_accuracy DECIMAL(8,2))
BEGIN
    DECLARE v_ride_id BIGINT DEFAULT NULL;
    UPDATE drivers SET current_lat=p_lat, current_lon=p_lon, heading_degrees=p_heading, speed_kmh=p_speed, location_updated_at=NOW()
    WHERE driver_id=p_driver_id AND is_active=1 AND deleted_at IS NULL;
    SELECT ride_id INTO v_ride_id FROM rides WHERE driver_id=p_driver_id AND status IN ('accepted','driver_en_route','in_progress')
    ORDER BY requested_at DESC LIMIT 1;
    INSERT INTO driver_location_history (driver_id,latitude,longitude,heading_degrees,speed_kmh,accuracy_meters,recorded_at,ride_id,record_year,record_quarter)
    VALUES (p_driver_id,p_lat,p_lon,p_heading,p_speed,p_accuracy,NOW(),v_ride_id,YEAR(NOW()),QUARTER(NOW()));
END //

CREATE PROCEDURE IF NOT EXISTS sp_refresh_daily_metrics(IN p_date DATE)
BEGIN
    INSERT INTO daily_city_metrics (city_id,metric_date,total_rides,completed_rides,cancelled_rides,total_revenue,total_driver_earnings,total_platform_revenue,avg_ride_duration_minutes,avg_ride_distance_km,avg_fare_etb,avg_surge_multiplier)
    SELECT city_id, p_date, COUNT(*),
        SUM(CASE WHEN status='completed' THEN 1 ELSE 0 END),
        SUM(CASE WHEN status='cancelled' THEN 1 ELSE 0 END),
        COALESCE(SUM(CASE WHEN status='completed' THEN total_fare ELSE 0 END),0),
        COALESCE(SUM(CASE WHEN status='completed' THEN driver_earnings ELSE 0 END),0),
        COALESCE(SUM(CASE WHEN status='completed' THEN platform_commission ELSE 0 END),0),
        AVG(CASE WHEN status='completed' THEN actual_duration_minutes END),
        AVG(CASE WHEN status='completed' THEN actual_distance_km END),
        AVG(CASE WHEN status='completed' THEN total_fare END),
        AVG(CASE WHEN status='completed' THEN surge_multiplier END)
    FROM rides WHERE DATE(requested_at) = p_date GROUP BY city_id
    ON DUPLICATE KEY UPDATE total_rides=VALUES(total_rides), completed_rides=VALUES(completed_rides),
        cancelled_rides=VALUES(cancelled_rides), total_revenue=VALUES(total_revenue),
        total_driver_earnings=VALUES(total_driver_earnings), total_platform_revenue=VALUES(total_platform_revenue),
        avg_ride_duration_minutes=VALUES(avg_ride_duration_minutes), avg_ride_distance_km=VALUES(avg_ride_distance_km),
        avg_fare_etb=VALUES(avg_fare_etb), avg_surge_multiplier=VALUES(avg_surge_multiplier);
END //

DELIMITER ;

-- PART 10: VIEWS AND SAMPLE QUERIES
CREATE OR REPLACE VIEW v_available_drivers AS
SELECT d.driver_id, d.external_id, d.full_name, d.city_id, c.city_name, d.current_lat, d.current_lon,
    d.heading_degrees, d.rating, d.total_rides, d.acceptance_rate, d.location_updated_at,
    v.make AS vehicle_make, v.model AS vehicle_model, v.vehicle_type, v.capacity, v.is_ac_available,
    TIMESTAMPDIFF(SECOND, d.location_updated_at, NOW()) AS seconds_since_update
FROM drivers d JOIN cities c ON d.city_id=c.city_id LEFT JOIN vehicles v ON d.vehicle_id=v.vehicle_id
WHERE d.status='available' AND d.is_active=1 AND d.deleted_at IS NULL AND d.location_updated_at > DATE_SUB(NOW(), INTERVAL 10 MINUTE);

CREATE OR REPLACE VIEW v_active_rides AS
SELECT r.ride_id, r.external_id, r.status, c.city_name, r.user_id, r.driver_id,
    r.pickup_lat, r.pickup_lon, r.dropoff_lat, r.dropoff_lon, r.total_fare, r.surge_multiplier,
    r.payment_method, r.requested_at, r.accepted_at,
    TIMESTAMPDIFF(MINUTE, r.requested_at, NOW()) AS minutes_since_request,
    d.current_lat AS driver_lat, d.current_lon AS driver_lon, d.full_name AS driver_name, d.rating AS driver_rating
FROM rides r JOIN cities c ON r.city_id=c.city_id LEFT JOIN drivers d ON r.driver_id=d.driver_id
WHERE r.status IN ('requested','accepted','driver_en_route','in_progress');

CREATE OR REPLACE VIEW v_active_surge_zones AS
SELECT s.event_id, s.zone_id, z.zone_name, c.city_name, s.multiplier, s.reason,
    s.demand_count, s.supply_count,
    IF(s.supply_count>0, ROUND(s.demand_count/s.supply_count,2), NULL) AS demand_supply_ratio,
    s.active_from, s.active_until,
    TIMESTAMPDIFF(MINUTE, NOW(), s.active_until) AS minutes_remaining
FROM surge_pricing_events s JOIN zones z ON s.zone_id=z.zone_id JOIN cities c ON s.city_id=c.city_id
WHERE s.is_active=1 AND s.active_until > NOW();

CREATE OR REPLACE VIEW v_daily_revenue AS
SELECT m.metric_date, c.city_name, m.total_rides, m.completed_rides, m.cancelled_rides,
    ROUND(m.completed_rides/NULLIF(m.total_rides,0)*100,2) AS completion_rate_pct,
    m.total_revenue, m.total_driver_earnings, m.total_platform_revenue,
    ROUND(m.avg_fare_etb,2) AS avg_fare_etb, ROUND(m.avg_ride_distance_km,2) AS avg_distance_km,
    ROUND(m.avg_ride_duration_minutes,1) AS avg_duration_min, ROUND(m.avg_surge_multiplier,2) AS avg_surge
FROM daily_city_metrics m JOIN cities c ON m.city_id=c.city_id ORDER BY m.metric_date DESC, m.total_revenue DESC;

CALL sp_find_nearest_drivers(9.024, 38.803, 1, 5.0, 10);
CALL sp_update_driver_location(1, 9.023, 38.792, 90, 0.00, 10.0);
CALL sp_update_driver_location(3, 9.031, 38.801, 270, 0.00, 8.0);
CALL sp_refresh_daily_metrics(DATE_SUB(CURDATE(), INTERVAL 1 DAY));
CALL sp_refresh_daily_metrics(DATE_SUB(CURDATE(), INTERVAL 2 DAY));

SELECT d.driver_id, d.full_name, CONCAT(v.make,' ',v.model) AS vehicle,
    ROUND(fn_haversine_distance_km(9.024,38.803,d.current_lat,d.current_lon),3) AS distance_km,
    d.rating, d.acceptance_rate
FROM drivers d JOIN vehicles v ON d.vehicle_id=v.vehicle_id
WHERE d.city_id=1 AND d.status='available' AND d.is_active=1 AND d.location_updated_at > DATE_SUB(NOW(),INTERVAL 10 MINUTE)
    AND fn_haversine_distance_km(9.024,38.803,d.current_lat,d.current_lon) <= 5.0
ORDER BY distance_km ASC, d.rating DESC LIMIT 10;

SELECT DATE(r.requested_at) AS report_date, c.city_name, COUNT(*) AS total_rides,
    SUM(r.status='completed') AS completed, SUM(r.status='cancelled') AS cancelled,
    ROUND(SUM(r.status='completed')/COUNT(*)*100,2) AS completion_pct,
    ROUND(SUM(CASE WHEN r.status='completed' THEN r.total_fare ELSE 0 END),2) AS gross_revenue_etb,
    ROUND(SUM(CASE WHEN r.status='completed' THEN r.driver_earnings ELSE 0 END),2) AS driver_earnings_etb,
    ROUND(SUM(CASE WHEN r.status='completed' THEN r.platform_commission ELSE 0 END),2) AS platform_revenue_etb,
    ROUND(AVG(CASE WHEN r.status='completed' THEN r.total_fare END),2) AS avg_fare_etb,
    ROUND(AVG(CASE WHEN r.status='completed' THEN r.surge_multiplier END),2) AS avg_surge,
    COUNT(DISTINCT r.user_id) AS unique_users
FROM rides r JOIN cities c ON r.city_id=c.city_id
WHERE r.requested_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(r.requested_at), r.city_id, c.city_name ORDER BY report_date DESC, gross_revenue_etb DESC;

WITH zone_demand AS (
    SELECT z.zone_id, z.zone_name, c.city_name,
        COUNT(CASE WHEN r.status='requested' AND r.requested_at > DATE_SUB(NOW(),INTERVAL 15 MINUTE) THEN 1 END) AS pending_requests,
        COUNT(CASE WHEN d.status='available' AND d.location_updated_at > DATE_SUB(NOW(),INTERVAL 10 MINUTE) THEN 1 END) AS available_drivers
    FROM zones z JOIN cities c ON z.city_id=c.city_id
    LEFT JOIN rides r ON r.city_id=z.city_id AND fn_haversine_distance_km(r.pickup_lat,r.pickup_lon,z.center_lat,z.center_lon) <= (z.radius_meters/1000.0)
    LEFT JOIN drivers d ON d.city_id=z.city_id AND fn_haversine_distance_km(d.current_lat,d.current_lon,z.center_lat,z.center_lon) <= (z.radius_meters/1000.0)
    WHERE z.is_active=1 GROUP BY z.zone_id, z.zone_name, c.city_name
)
SELECT zone_id, zone_name, city_name, pending_requests, available_drivers,
    IF(available_drivers>0, ROUND(pending_requests/available_drivers,2), NULL) AS demand_supply_ratio
FROM zone_demand ORDER BY demand_supply_ratio DESC;

SELECT ff.flag_id, ff.entity_type, ff.entity_id,
    CASE WHEN ff.entity_type='user' THEN u.full_name WHEN ff.entity_type='driver' THEN d.full_name END AS entity_name,
    ff.flag_type, ff.severity, ff.description, ff.flagged_at, ff.is_resolved
FROM fraud_flags ff LEFT JOIN users u ON ff.entity_type='user' AND ff.entity_id=u.user_id
LEFT JOIN drivers d ON ff.entity_type='driver' AND ff.entity_id=d.driver_id
ORDER BY FIELD(ff.severity,'critical','high','medium','low'), ff.flagged_at DESC;

SELECT el.log_id, el.event_type, el.entity_type, el.entity_id, el.actor_type, el.actor_id, el.severity, el.occurred_at, el.payload
FROM event_log el WHERE el.occurred_at > DATE_SUB(NOW(), INTERVAL 24 HOUR) ORDER BY el.occurred_at DESC LIMIT 100;

SELECT fn_user_has_permission(1, 'rides.read.own') AS can_read_own_rides;
SELECT fn_user_has_permission(1, 'rides.read.all') AS can_read_all_rides;

SELECT * FROM v_available_drivers ORDER BY city_id, rating DESC;
SELECT * FROM v_active_surge_zones;
SELECT * FROM v_active_rides;
SELECT * FROM v_daily_revenue LIMIT 20;

-- PART 11: GRANTS, VERIFICATION QUERIES AND CLEANUP
CREATE USER IF NOT EXISTS 'ridehail_app'@'localhost' IDENTIFIED BY '12345678';
GRANT SELECT, INSERT, UPDATE ON ridehail_ethiopia.rides TO 'ridehail_app'@'localhost';
GRANT SELECT, UPDATE ON ridehail_ethiopia.drivers TO 'ridehail_app'@'localhost';
GRANT SELECT, UPDATE ON ridehail_ethiopia.users TO 'ridehail_app'@'localhost';
GRANT SELECT, INSERT ON ridehail_ethiopia.payments TO 'ridehail_app'@'localhost';
GRANT SELECT, INSERT ON ridehail_ethiopia.driver_location_history TO 'ridehail_app'@'localhost';
GRANT SELECT, INSERT ON ridehail_ethiopia.ride_status_history TO 'ridehail_app'@'localhost';
GRANT INSERT ON ridehail_ethiopia.event_log TO 'ridehail_app'@'localhost';
GRANT SELECT ON ridehail_ethiopia.zones TO 'ridehail_app'@'localhost';
GRANT SELECT ON ridehail_ethiopia.cities TO 'ridehail_app'@'localhost';
GRANT SELECT ON ridehail_ethiopia.surge_pricing_events TO 'ridehail_app'@'localhost';
GRANT SELECT ON ridehail_ethiopia.vehicles TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON PROCEDURE ridehail_ethiopia.sp_book_ride_atomic TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON PROCEDURE ridehail_ethiopia.sp_complete_ride TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON PROCEDURE ridehail_ethiopia.sp_update_driver_location TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON PROCEDURE ridehail_ethiopia.sp_find_nearest_drivers TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON FUNCTION ridehail_ethiopia.fn_haversine_distance_km TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON FUNCTION ridehail_ethiopia.fn_get_active_surge TO 'ridehail_app'@'localhost';
GRANT EXECUTE ON FUNCTION ridehail_ethiopia.fn_user_has_permission TO 'ridehail_app'@'localhost';

CREATE USER IF NOT EXISTS 'ridehail_readonly'@'localhost' IDENTIFIED BY '12345678';
GRANT SELECT ON ridehail_ethiopia.cities TO 'ridehail_readonly'@'localhost';
GRANT SELECT ON ridehail_ethiopia.zones TO 'ridehail_readonly'@'localhost';
GRANT SELECT ON ridehail_ethiopia.daily_city_metrics TO 'ridehail_readonly'@'localhost';
GRANT SELECT ON ridehail_ethiopia.v_daily_revenue TO 'ridehail_readonly'@'localhost';
GRANT SELECT ON ridehail_ethiopia.v_active_surge_zones TO 'ridehail_readonly'@'localhost';

CREATE USER IF NOT EXISTS 'ridehail_fraud'@'localhost' IDENTIFIED BY '12345678';
GRANT SELECT, INSERT, UPDATE ON ridehail_ethiopia.fraud_flags TO 'ridehail_fraud'@'localhost';
GRANT SELECT ON ridehail_ethiopia.event_log TO 'ridehail_fraud'@'localhost';
GRANT SELECT ON ridehail_ethiopia.users TO 'ridehail_fraud'@'localhost';
GRANT SELECT ON ridehail_ethiopia.drivers TO 'ridehail_fraud'@'localhost';

FLUSH PRIVILEGES;

SELECT table_name, engine, table_rows,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb,
    partition_name
FROM information_schema.partitions
WHERE table_schema = 'ridehail_ethiopia'
ORDER BY table_name, partition_name;

SELECT status, COUNT(*) AS count, ROUND(AVG(rating),2) AS avg_rating
FROM drivers WHERE is_active=1 AND deleted_at IS NULL GROUP BY status;

SELECT s.status AS ride_status, COUNT(*) AS count,
    ROUND(AVG(total_fare),2) AS avg_fare, ROUND(AVG(surge_multiplier),2) AS avg_surge
FROM rides s GROUP BY s.status ORDER BY count DESC;

SELECT c.city_name, COUNT(r.ride_id) AS total_rides,
    SUM(r.status='completed') AS completed,
    ROUND(SUM(CASE WHEN r.status='completed' THEN r.total_fare ELSE 0 END),2) AS revenue_etb,
    COUNT(DISTINCT r.driver_id) AS unique_drivers, COUNT(DISTINCT r.user_id) AS unique_passengers
FROM cities c LEFT JOIN rides r ON c.city_id=r.city_id GROUP BY c.city_id, c.city_name ORDER BY revenue_etb DESC;

SELECT ff.severity, ff.flag_type, COUNT(*) AS total,
    SUM(ff.is_resolved=0) AS open_flags, SUM(ff.is_resolved=1) AS resolved_flags
FROM fraud_flags ff GROUP BY ff.severity, ff.flag_type ORDER BY FIELD(ff.severity,'critical','high','medium','low');

SELECT s.shard_name, s.city_region, s.host, s.is_primary, s.is_active,
    s.replication_lag_seconds, s.last_health_check, sc.last_synced_at, sc.records_synced
FROM shards s LEFT JOIN sync_checkpoints sc ON s.shard_id=sc.shard_id ORDER BY s.city_region, s.is_primary DESC;

SELECT p.status, p.payment_method, COUNT(*) AS count,
    ROUND(SUM(p.amount),2) AS total_etb FROM payments p GROUP BY p.status, p.payment_method ORDER BY total_etb DESC;

SELECT permission_key, resource, action FROM permissions p
JOIN role_permissions rp ON p.permission_id=rp.permission_id
JOIN roles r ON rp.role_id=r.role_id WHERE r.role_name='city_admin' ORDER BY resource, action;

SHOW TABLE STATUS FROM ridehail_ethiopia;
SET FOREIGN_KEY_CHECKS = 1;
