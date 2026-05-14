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
