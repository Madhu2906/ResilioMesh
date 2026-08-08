package com.resiliomesh.repository;

import com.resiliomesh.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface UserRepository extends JpaRepository<User, Long> {

    // Upsert user device token and location using PostGIS ST_SetSRID and ST_MakePoint
    @Modifying
    @Transactional
    @Query(value = "INSERT INTO users (fcm_token, last_location, updated_at) " +
                   "VALUES (:token, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), CURRENT_TIMESTAMP) " +
                   "ON CONFLICT (fcm_token) DO UPDATE " +
                   "SET last_location = ST_SetSRID(ST_MakePoint(:lon, :lat), 4326), updated_at = CURRENT_TIMESTAMP", 
           nativeQuery = true)
    void upsertUserDevice(@Param("token") String token, @Param("lat") double lat, @Param("lon") double lon);

    // Find device tokens located within radiusMeters of a disaster center point
    @Query(value = "SELECT fcm_token FROM users WHERE ST_DWithin(last_location::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, :radiusMeters)", nativeQuery = true)
    List<String> findTokensInDisasterZone(@Param("lat") double lat, @Param("lon") double lon, @Param("radiusMeters") double radiusMeters);
}