package com.selimhorri.app.resource;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.UserServiceApplication;
import com.selimhorri.app.dto.UserDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = UserServiceApplication.class)
@AutoConfigureMockMvc
class UserResourceIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void getAll_ok() throws Exception {
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isOk());
    }

    @Test
    void create_ok() throws Exception {
        UserDto dto = new UserDto();
        dto.setFirstName("it-user");
        dto.setEmail("it@example.com");
        String body = objectMapper.writeValueAsString(dto);

        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("it-user"));
    }
}


