package com.resiliomesh.dto;

import com.resiliomesh.entity.SosAlert;
import java.time.LocalDateTime;

public record SosAlertResponse(Long id, Double latitude, Double longitude, String category,
                               LocalDateTime createdAt, String status, Integer etaMinutes,
                               LocalDateTime estimatedArrivalAt) {
    public static SosAlertResponse from(SosAlert alert) {
        return new SosAlertResponse(alert.getId(), alert.getLatitude(), alert.getLongitude(), alert.getCategory(),
                alert.getCreatedAt(), alert.getStatus(), alert.getEtaMinutes(), alert.getEstimatedArrivalAt());
    }
}
