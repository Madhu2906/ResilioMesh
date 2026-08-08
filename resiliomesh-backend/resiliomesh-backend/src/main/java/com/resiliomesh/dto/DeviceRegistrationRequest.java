package com.resiliomesh.dto;

import lombok.Data;

@Data
public class DeviceRegistrationRequest {
    private String fcmToken;
    private double latitude;
    private double longitude;
}