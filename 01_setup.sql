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
