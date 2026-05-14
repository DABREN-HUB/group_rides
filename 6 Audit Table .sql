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
