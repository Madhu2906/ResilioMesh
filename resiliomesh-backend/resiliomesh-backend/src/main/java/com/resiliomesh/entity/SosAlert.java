package com.resiliomesh.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sos_alerts")
public class SosAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Double latitude;
    private Double longitude;
    private String category;
    private String userFcmToken;
    private LocalDateTime createdAt = LocalDateTime.now();

    // Status: PENDING, ACCEPTED, RESOLVED
    private String status = "PENDING";

    // ETA set by Admin in minutes
    private Integer etaMinutes;
    private LocalDateTime estimatedArrivalAt;

    public SosAlert() {}

    public SosAlert(Double latitude, Double longitude, String category, String userFcmToken) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.category = category;
        this.userFcmToken = userFcmToken;
        this.createdAt = LocalDateTime.now();
        this.status = "PENDING";
    }

    // Getters and Setters
    public Long getId() { return id; }
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getUserFcmToken() { return userFcmToken; }
    public void setUserFcmToken(String userFcmToken) { this.userFcmToken = userFcmToken; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Integer getEtaMinutes() { return etaMinutes; }
    public void setEtaMinutes(Integer etaMinutes) { this.etaMinutes = etaMinutes; }
    public LocalDateTime getEstimatedArrivalAt() { return estimatedArrivalAt; }
    public void setEstimatedArrivalAt(LocalDateTime estimatedArrivalAt) { this.estimatedArrivalAt = estimatedArrivalAt; }
}