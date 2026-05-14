
  
PART 5: PAYMENT, EARNINGS AND SURGE PRICING TABLES
  
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
