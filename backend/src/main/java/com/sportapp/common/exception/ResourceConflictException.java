package com.sportapp.common.exception;

import org.springframework.http.HttpStatus;

public class ResourceConflictException extends BaseApiException {

    public ResourceConflictException(String message) {
        super(message, HttpStatus.CONFLICT, "RESOURCE_CONFLICT");
    }
}
