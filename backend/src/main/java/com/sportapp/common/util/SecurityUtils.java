package com.sportapp.common.util;

import com.sportapp.common.enums.RoleType;
import com.sportapp.common.exception.UnauthorizedException;
import com.sportapp.security.user.UserPrincipal;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

public final class SecurityUtils {

    private SecurityUtils() {
    }

    public static Optional<UserPrincipal> getCurrentUserPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserPrincipal principal) {
            return Optional.of(principal);
        }
        return Optional.empty();
    }

    public static Long getCurrentUserId() {
        return getCurrentUserPrincipal()
                .map(UserPrincipal::getId)
                .orElseThrow(() -> new UnauthorizedException("User is not authenticated"));
    }

    public static String getCurrentUserEmail() {
        return getCurrentUserPrincipal()
                .map(UserPrincipal::getEmail)
                .orElseThrow(() -> new UnauthorizedException("User is not authenticated"));
    }

    public static RoleType getCurrentUserRole() {
        return getCurrentUserPrincipal()
                .map(UserPrincipal::getRole)
                .orElseThrow(() -> new UnauthorizedException("User is not authenticated"));
    }
}
