𝓶𝓮𝓼𝓼𝓪𝔂 𝓶𝓮𝓼𝓯𝓲𝓷:
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
