package com.selimhorri.app.service;

import com.selimhorri.app.domain.Order;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.exception.wrapper.OrderNotFoundException;
import com.selimhorri.app.helper.OrderMappingHelper;
import com.selimhorri.app.repository.OrderRepository;
import com.selimhorri.app.service.impl.OrderServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrderServiceImplTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    private OrderDto sampleDto;
    private Order sampleEntity;

    @BeforeEach
    void setup() {
        sampleDto = OrderDto.builder()
                .orderId(1)
                .orderDesc("Test order")
                .orderFee(42.5)
                .orderDate(LocalDateTime.of(2025, 1, 1, 12, 0))
                .cartDto(CartDto.builder().cartId(5).build())
                .build();
        sampleEntity = OrderMappingHelper.map(sampleDto);
    }

    @Test
    void findAll_returnsMappedDtos() {
        when(orderRepository.findAll()).thenReturn(List.of(sampleEntity));

        var result = orderService.findAll();

        assertThat(result)
                .hasSize(1)
                .first()
                .extracting(OrderDto::getOrderDesc)
                .isEqualTo("Test order");
    }

    @Test
    void findById_returnsDtoWhenPresent() {
        when(orderRepository.findById(1)).thenReturn(Optional.of(sampleEntity));

        OrderDto result = orderService.findById(1);

        assertThat(result.getOrderFee()).isEqualTo(42.5);
    }

    @Test
    void findById_missingThrows() {
        when(orderRepository.findById(999)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.findById(999))
                .isInstanceOf(OrderNotFoundException.class)
                .hasMessageContaining("999");
    }

    @Test
    void save_persistsAndReturnsMappedDto() {
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        OrderDto saved = orderService.save(sampleDto);

        assertThat(saved.getOrderId()).isEqualTo(1);
        verify(orderRepository).save(any(Order.class));
    }

    @Test
    void update_overwritesExistingOrder() {
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        OrderDto updated = orderService.update(sampleDto);

        assertThat(updated.getOrderDesc()).isEqualTo("Test order");
        verify(orderRepository).save(any(Order.class));
    }

    @Test
    void updateWithId_usesExistingOrderForPersistence() {
        when(orderRepository.findById(1)).thenReturn(Optional.of(sampleEntity));
        when(orderRepository.save(any(Order.class))).thenAnswer(invocation -> invocation.getArgument(0));

        OrderDto updated = orderService.update(1, sampleDto);

        assertThat(updated.getOrderId()).isEqualTo(1);
        verify(orderRepository).findById(1);
        verify(orderRepository).save(any(Order.class));
    }

    @Test
    void deleteById_fetchesAndDeletesEntity() {
        when(orderRepository.findById(1)).thenReturn(Optional.of(sampleEntity));

        orderService.deleteById(1);

        verify(orderRepository).findById(1);
        verify(orderRepository, times(1)).delete(any(Order.class));
    }
}


