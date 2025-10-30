package com.selimhorri.app.resource;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.ProductServiceApplication;
import com.selimhorri.app.dto.ProductDto;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(classes = ProductServiceApplication.class)
@AutoConfigureMockMvc
class ProductResourceIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void getAllProducts_ok() throws Exception {
        mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk());
    }

    @Test
    void createAndFetchProduct_ok() throws Exception {
        ProductDto dto = new ProductDto();
        dto.setProductTitle("IT Product");
        dto.setPriceUnit(20.0);

        String body = objectMapper.writeValueAsString(dto);

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.productTitle").value("IT Product"));
    }

    @Test
    void getById_notFound_returns404() throws Exception {
        mockMvc.perform(get("/api/products/999999"))
                .andExpect(status().is4xxClientError());
    }
}


