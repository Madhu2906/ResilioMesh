package com.resiliomesh.dto;

import lombok.Data;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
@Data
public class SyncReportRequest {
    private String reportId;
    private String senderName;
    private String mobileNumber;
    private String title;
    private String description;
    private Double latitude;
    private Double longitude;
    private Double priority;
    private Object timestamp; // Accepts both Epoch milliseconds (Long) and String formats
    private String status;
    private String mediaPaths; // Maps media files attached during P2P sync
}