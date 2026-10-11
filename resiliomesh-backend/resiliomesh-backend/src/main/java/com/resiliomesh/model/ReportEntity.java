package com.resiliomesh.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "reports")
@Data
public class ReportEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private String reportId;

    private String senderName;
    private String mobileNumber;
    private String title;

    @Column(name = "assigned_team")
    private String assignedTeam;

    @Column(length = 1000)
    private String description;

    private double latitude;
    private double longitude;
    private double priority;
    private String timestamp;
    private String status;

   @Column(name = "audit_timeline", length = 3000)
private String auditTimeline = "SOS Received via Mesh Relay"; 

    @Column(length = 1000)
    private String mediaUrls;

    // Explicit getter and setter for assignedTeam
    public String getAssignedTeam() {
        return assignedTeam;
    }

    public void setAssignedTeam(String assignedTeam) {
        this.assignedTeam = assignedTeam;
    }
}