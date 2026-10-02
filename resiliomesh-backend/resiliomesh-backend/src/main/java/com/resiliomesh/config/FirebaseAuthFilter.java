package com.resiliomesh.config;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {
    public static final String UID_ATTRIBUTE = "firebaseUid";

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return !path.startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            reject(response, HttpServletResponse.SC_UNAUTHORIZED, "Firebase sign-in is required.");
            return;
        }

        final FirebaseToken token;
        try {
            token = FirebaseAuth.getInstance().verifyIdToken(header.substring(7));
            request.setAttribute(UID_ATTRIBUTE, token.getUid());
        } catch (Exception e) {
            reject(response, HttpServletResponse.SC_UNAUTHORIZED, "Firebase token is invalid or expired.");
            return;
        }
        if (requiresAdmin(request) && !Boolean.TRUE.equals(token.getClaims().get("admin"))) {
            reject(response, HttpServletResponse.SC_FORBIDDEN, "Administrator access is required.");
            return;
        }
        chain.doFilter(request, response);
    }

    private boolean requiresAdmin(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (path.equals("/api/admin/sos/trigger") || path.matches("/api/admin/sos/status/\\d+")) return false;
        return path.startsWith("/api/admin/") || path.startsWith("/api/alerts/") || path.startsWith("/api/sos/");
    }

    private void reject(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.getWriter().write("{\"error\":\"" + message + "\"}");
    }
}
