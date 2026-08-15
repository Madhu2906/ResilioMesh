package com.resiliomesh.model;

import jakarta.persistence.*;
import org.locationtech.jts.geom.Point;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "fcm_token")
    private String fcmToken;

    // PostGIS Point geometry (SRID 4326 = WGS84 Standard GPS Coordinates)
    @Column(name = "location", columnDefinition = "GEOMETRY(Point, 4326)")
    private Point location;

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }

    public Point getLocation() { return location; }
    public void setLocation(Point location) { this.location = location; }
}