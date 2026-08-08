package com.resiliomesh.controller;

import com.resiliomesh.entity.SosAlert;
import com.resiliomesh.repository.SosAlertRepository;
import com.resiliomesh.service.FcmService;
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
    public ResponseEntity<SosAlert> triggerSos(@RequestBody Map<String, Object> payload) {
        Double lat = Double.parseDouble(payload.get("latitude").toString());
        Double lon = Double.parseDouble(payload.get("longitude").toString());
        String category = payload.get("category") != null ? payload.get("category").toString() : "GENERAL";
        String token = payload.get("fcmToken") != null ? payload.get("fcmToken").toString() : "sample_token";

        SosAlert alert = new SosAlert(lat, lon, category, token);
        alert.setStatus("PENDING");
        alert.setCreatedAt(LocalDateTime.now());
        
        sosRepository.save(alert);
        return ResponseEntity.ok(alert);
    }

    // Get all pending SOS alerts for Admin Portal
    @GetMapping("/active")
    public List<SosAlert> getActiveAlerts() {
        return sosRepository.findByStatus("PENDING");
    }

    // Admin accepts emergency & assigns dispatch ETA
    @PostMapping("/accept/{id}")
    public ResponseEntity<SosAlert> acceptAlert(@PathVariable Long id, @RequestParam Integer etaMinutes) {
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

        return ResponseEntity.ok(alert);
    }

    // Get live status & ETA of a specific SOS alert for Flutter Polling
    @GetMapping("/status/{id}")
    public ResponseEntity<SosAlert> getAlertStatus(@PathVariable Long id) {
        return sosRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}