package com.resiliomesh.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;


@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("🔥 Firebase Admin SDK initialized successfully!");
            }
        } catch (Exception e) {
            throw new IllegalStateException("Firebase credentials are required. Configure GOOGLE_APPLICATION_CREDENTIALS.", e);
        }
    }
}
