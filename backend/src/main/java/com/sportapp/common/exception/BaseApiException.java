package com.sportapp.common.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class BaseApiException extends RuntimeException {

    private final HttpStatus status;
    private final String errorCode;

    public BaseApiException(String message, HttpStatus status, String errorCode) {
        super(message);
        this.status = status;
        this.errorCode = errorCode;
    }
}
