package com.selimhorri.app.service;

import com.selimhorri.app.dto.CategoryDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.exception.wrapper.ProductNotFoundException;
import com.selimhorri.app.repository.ProductRepository;
import com.selimhorri.app.service.impl.ProductServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    private ProductDto sampleDto;

    @BeforeEach
    void setup() {
        sampleDto = new ProductDto();
        sampleDto.setProductId(1);
        sampleDto.setProductTitle("Sample");
        sampleDto.setPriceUnit(10.0);
        CategoryDto category = new CategoryDto();
        category.setCategoryId(100);
        category.setCategoryTitle("Technology");
        category.setImageUrl("n/a");
        sampleDto.setCategoryDto(category);
    }

    @Test
    void findAll_returnsList() {
        when(productRepository.findAll()).thenReturn(List.of());
        assertThat(productService.findAll()).isNotNull();
    }

    @Test
    void findById_whenFound_returnsDto() {
        when(productRepository.findById(1)).then(invocation -> Optional.of(com.selimhorri.app.helper.ProductMappingHelper.map(sampleDto)));
        ProductDto dto = productService.findById(1);
        assertThat(dto.getProductId()).isEqualTo(1);
    }

    @Test
    void findById_whenMissing_throwsNotFound() {
        when(productRepository.findById(999)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> productService.findById(999)).isInstanceOf(ProductNotFoundException.class);
    }

    @Test
    void save_persistsAndReturnsDto() {
        when(productRepository.save(any())).then(invocation -> invocation.getArgument(0));
        ProductDto saved = productService.save(sampleDto);
        assertThat(saved.getProductTitle()).isEqualTo("Sample");
    }

    @Test
    void update_persistsAndReturnsDto() {
        when(productRepository.save(any())).then(invocation -> invocation.getArgument(0));
        ProductDto updated = productService.update(sampleDto);
        assertThat(updated.getPriceUnit()).isEqualTo(10.0);
    }
}


