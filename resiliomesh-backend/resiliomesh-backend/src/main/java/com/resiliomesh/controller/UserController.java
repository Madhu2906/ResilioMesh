package com.resiliomesh.controller;

import com.resiliomesh.dto.DeviceRegistrationRequest;
import com.resiliomesh.repository.UserRepository;
//import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    
    private final UserRepository userRepository;

    // Use constructor injection instead of @Autowired field injection
    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/update-device")
    public ResponseEntity<String> updateDevice(@RequestBody DeviceRegistrationRequest request) {
        userRepository.upsertUserDevice(
            request.getFcmToken(), 
            request.getLatitude(), 
            request.getLongitude()
        );
        return ResponseEntity.ok("Device updated successfully.");
    }
}