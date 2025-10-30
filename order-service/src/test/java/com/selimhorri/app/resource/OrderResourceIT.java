package com.selimhorri.app.resource;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.service.OrderService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(OrderResource.class)
class OrderResourceIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private OrderService orderService;

    private OrderDto sampleDto;

    @BeforeEach
    void init() {
        sampleDto = OrderDto.builder()
                .orderId(1)
                .orderDesc("Sample order")
                .orderFee(15.5)
                .orderDate(LocalDateTime.of(2025, 1, 1, 10, 0))
                .cartDto(CartDto.builder().cartId(7).build())
                .build();
    }

    @Test
    void findAll_returnsCollectionPayload() throws Exception {
        when(orderService.findAll()).thenReturn(List.of(sampleDto));

        mockMvc.perform(get("/api/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection[0].orderId").value(1))
                .andExpect(jsonPath("$.collection[0].orderDesc").value("Sample order"));
    }

    @Test
    void findById_returnsOrder() throws Exception {
        when(orderService.findById(1)).thenReturn(sampleDto);

        mockMvc.perform(get("/api/orders/{orderId}", 1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderFee").value(15.5));
    }

    @Test
    void create_persistsOrder() throws Exception {
        when(orderService.save(any(OrderDto.class))).thenReturn(sampleDto);

        mockMvc.perform(post("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderId").value(1));
    }

    @Test
    void update_replacesOrder() throws Exception {
        when(orderService.update(any(OrderDto.class))).thenReturn(sampleDto);

        mockMvc.perform(put("/api/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderDesc").value("Sample order"));
    }

    @Test
    void updateWithId_replacesOrder() throws Exception {
        when(orderService.update(1, sampleDto)).thenReturn(sampleDto);

        mockMvc.perform(put("/api/orders/{orderId}", 1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderId").value(1));
    }

    @Test
    void deleteById_returnsTrue() throws Exception {
    mockMvc.perform(delete("/api/orders/{orderId}", 1))
                .andExpect(status().isOk())
                .andExpect(content().string("true"));

        verify(orderService).deleteById(1);
    }
}


