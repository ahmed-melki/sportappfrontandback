package com.sportapp.security.service;

import com.sportapp.security.entity.RevokedToken;
import com.sportapp.security.repository.RevokedTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenRevocationService {

    private final RevokedTokenRepository revokedTokenRepository;

    @Transactional
    public void revokeToken(String token, Long userId, Instant expiryDate) {
        String tokenHash = hashToken(token);
        if (!revokedTokenRepository.existsByTokenHash(tokenHash)) {
            RevokedToken revokedToken = RevokedToken.builder()
                    .tokenHash(tokenHash)
                    .userId(userId)
                    .expiryDate(expiryDate)
                    .createdAt(Instant.now())
                    .build();
            revokedTokenRepository.save(revokedToken);
            log.info("Revoked token for user ID: {}", userId);
        }
    }

    @Transactional(readOnly = true)
    public boolean isTokenRevoked(String token) {
        String tokenHash = hashToken(token);
        return revokedTokenRepository.existsByTokenHash(tokenHash);
    }

    @Scheduled(cron = "${app.jwt.cleanup-cron:0 0 * * * *}") // Every hour
    @Transactional
    public void purgeExpiredTokens() {
        Instant now = Instant.now();
        int deletedCount = revokedTokenRepository.deleteExpiredTokens(now);
        if (deletedCount > 0) {
            log.info("Purged {} expired revoked tokens at {}", deletedCount, now);
        }
    }

    public static String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm not available", e);
        }
    }
}
