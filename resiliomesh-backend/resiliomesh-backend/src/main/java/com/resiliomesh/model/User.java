package com.resiliomesh.model;

import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "fcm_token", unique = true, nullable = false)
    private String fcmToken;

    // PostGIS Point geometry (SRID 4326 = WGS84 Standard GPS Coordinates)
    @Column(name = "last_location", columnDefinition = "geometry(Point, 4326)")
    private Point location;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }

    public Point getLocation() { return location; }
    public void setLocation(Point location) { this.location = location; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
