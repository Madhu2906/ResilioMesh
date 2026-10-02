package com.resiliomesh.controller;

import com.resiliomesh.entity.SosAlert;
import com.resiliomesh.repository.SosAlertRepository;
import com.resiliomesh.service.FcmService;
import com.resiliomesh.dto.SosAlertResponse;
import com.resiliomesh.config.FirebaseAuthFilter;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/sos")
@CrossOrigin(origins = "*")
public class SosAdminController {

    @Autowired
    private SosAlertRepository sosRepository;

    @Autowired
    private FcmService fcmService;

    // Trigger incoming SOS from user app
    @PostMapping("/trigger")
    public ResponseEntity<SosAlertResponse> triggerSos(@RequestBody Map<String, Object> payload, HttpServletRequest request) {
        Double lat = payload.get("latitude") instanceof Number n ? n.doubleValue() : null;
        Double lon = payload.get("longitude") instanceof Number n ? n.doubleValue() : null;
        if ((lat != null && (lat < -90 || lat > 90)) || (lon != null && (lon < -180 || lon > 180)))
            return ResponseEntity.badRequest().build();
        String category = payload.get("category") != null ? payload.get("category").toString() : "GENERAL";
        String token = payload.get("fcmToken") != null ? payload.get("fcmToken").toString() : null;

        SosAlert alert = new SosAlert(lat, lon, category, token);
        alert.setStatus("PENDING");
        alert.setCreatedAt(LocalDateTime.now());
        alert.setFirebaseUid((String) request.getAttribute(FirebaseAuthFilter.UID_ATTRIBUTE));
        
        sosRepository.save(alert);
        return ResponseEntity.ok(SosAlertResponse.from(alert));
    }

    // Get all pending SOS alerts for Admin Portal
    @GetMapping("/active")
    public List<SosAlertResponse> getActiveAlerts() {
        return sosRepository.findByStatus("PENDING").stream().map(SosAlertResponse::from).toList();
    }

    // Admin accepts emergency & assigns dispatch ETA
    @PostMapping("/accept/{id}")
    public ResponseEntity<SosAlertResponse> acceptAlert(@PathVariable Long id, @RequestParam Integer etaMinutes) {
        if (etaMinutes == null || etaMinutes < 1 || etaMinutes > 1440) return ResponseEntity.badRequest().build();
        SosAlert alert = sosRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Alert not found with id: " + id));

        alert.setStatus("ACCEPTED");
        alert.setEtaMinutes(etaMinutes);
        alert.setEstimatedArrivalAt(LocalDateTime.now().plusMinutes(etaMinutes));

        sosRepository.save(alert);

        try {
            fcmService.sendEtaNotificationToUser(
                    alert.getUserFcmToken(),
                    etaMinutes,
                    alert.getCategory()
            );
        } catch (Exception e) {
            System.err.println("FCM Notification failed to send: " + e.getMessage());
        }

        return ResponseEntity.ok(SosAlertResponse.from(alert));
    }

    // Get live status & ETA of a specific SOS alert for Flutter Polling
    @GetMapping("/status/{id}")
    public ResponseEntity<SosAlertResponse> getAlertStatus(@PathVariable Long id, HttpServletRequest request) {
        return sosRepository.findById(id).map(alert -> {
            String uid = (String) request.getAttribute(FirebaseAuthFilter.UID_ATTRIBUTE);
            if (!uid.equals(alert.getFirebaseUid())) return ResponseEntity.status(403).<SosAlertResponse>build();
            return ResponseEntity.ok(SosAlertResponse.from(alert));
        }).orElse(ResponseEntity.notFound().build());
    }
}
