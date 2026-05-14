𝓶𝓮𝓼𝓼𝓪𝔂 𝓶𝓮𝓼𝓯𝓲𝓷:
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
