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
    records_synced BIGINT NOT NULL
