𝓶𝓮𝓼𝓼𝓪𝔂 𝓶𝓮𝓼𝓯𝓲𝓷:
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
