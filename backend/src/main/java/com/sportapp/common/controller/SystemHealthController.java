package com.sportapp.common.controller;

import com.sportapp.common.dto.ApiResponse;
import com.sportapp.common.util.SecurityUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Arrays;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/system")
@Tag(name = "System", description = "System health, infrastructure status, and verification endpoints")
@RequiredArgsConstructor
public class SystemHealthController {

    private final Environment environment;

    @GetMapping("/health")
    @Operation(summary = "System Health Check", description = "Returns system status, active profiles, and current UTC time")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHealth() {
        Map<String, Object> data = Map.of(
                "status", "UP",
                "timestamp", Instant.now(),
                "activeProfiles", Arrays.asList(environment.getActiveProfiles()),
                "appName", "Smart Sports Management App"
        );
        return ResponseEntity.ok(ApiResponse.success(data, "System is healthy"));
    }

    @GetMapping("/secured-ping")
    @SecurityRequirement(name = "BearerAuth")
    @Operation(summary = "Secured Ping", description = "Verifies authentication filter and context for the caller")
    public ResponseEntity<ApiResponse<Map<String, Object>>> securedPing() {
        Long userId = SecurityUtils.getCurrentUserId();
        String email = SecurityUtils.getCurrentUserEmail();
        String role = SecurityUtils.getCurrentUserRole().name();

        Map<String, Object> data = Map.of(
                "authenticated", true,
                "userId", userId,
                "email", email,
                "role", role,
                "serverTimeUtc", Instant.now()
        );
        return ResponseEntity.ok(ApiResponse.success(data, "Authentication successful"));
    }
}
