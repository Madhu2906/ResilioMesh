package com.resiliomesh.controller;

import com.resiliomesh.dto.DeviceRegistrationRequest;
import com.resiliomesh.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    private static final Logger log = LoggerFactory.getLogger(UserController.class);
    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/update-device")
    public ResponseEntity<Map<String, Object>> updateDevice(@RequestBody DeviceRegistrationRequest request) {
        Map<String, Object> response = new HashMap<>();

        // 1. Validate FCM Token presence
        if (request == null || request.getFcmToken() == null || request.getFcmToken().isBlank()) {
            response.put("status", "ERROR");
            response.put("message", "FCM token is required.");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }

        // 2. Validate GPS coordinates
        if (request.getLatitude() < -90 || request.getLatitude() > 90 ||
            request.getLongitude() < -180 || request.getLongitude() > 180) {
            response.put("status", "ERROR");
            response.put("message", "Invalid latitude or longitude coordinates.");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }

        try {
            // 3. Upsert device token and location into PostgreSQL PostGIS
            userRepository.upsertUserDevice(
                request.getFcmToken(),
                request.getLatitude(),
                request.getLongitude()
            );

            log.info("Updated device location for token ending with: ...{}", 
                    request.getFcmToken().substring(Math.max(0, request.getFcmToken().length() - 8)));

            response.put("status", "SUCCESS");
            response.put("message", "Device updated successfully.");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to update user device: ", e);
            response.put("status", "ERROR");
            response.put("message", "Failed to update device location on server.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}