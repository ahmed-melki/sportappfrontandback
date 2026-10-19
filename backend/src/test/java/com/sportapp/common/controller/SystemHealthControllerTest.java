package com.sportapp.common.controller;

import com.sportapp.BaseIntegrationTest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@AutoConfigureMockMvc
class SystemHealthControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("GET /api/v1/system/health - should return UP status and X-Request-Id header")
    void getHealth_shouldReturnSuccess() throws Exception {
        mockMvc.perform(get("/api/v1/system/health")
                        .header("X-Request-Id", "test-req-12345"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Request-Id", "test-req-12345"))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("UP"))
                .andExpect(jsonPath("$.data.appName").value("Smart Sports Management App"));
    }

    @Test
    @DisplayName("GET /api/v1/system/secured-ping - without token should return 401 Unauthorized")
    void securedPing_withoutToken_shouldReturn401() throws Exception {
        mockMvc.perform(get("/api/v1/system/secured-ping"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.requestId", notNullValue()));
    }
}
