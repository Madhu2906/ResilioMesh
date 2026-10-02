package com.resiliomesh.dto;

import lombok.Data;

@Data
public class DeviceRegistrationRequest {
    private String fcmToken;
    private Double latitude;
    private Double longitude;
}
