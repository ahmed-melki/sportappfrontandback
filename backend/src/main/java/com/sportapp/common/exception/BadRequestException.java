package com.sportapp.common.exception;

import org.springframework.http.HttpStatus;

public class BadRequestException extends BaseApiException {

    public BadRequestException(String message) {
        super(message, HttpStatus.BAD_REQUEST, "BAD_REQUEST");
    }
}
