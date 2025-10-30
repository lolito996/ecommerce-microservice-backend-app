package com.selimhorri.app.service;

import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.domain.Favourite;
import com.selimhorri.app.domain.id.FavouriteId;
import com.selimhorri.app.dto.FavouriteDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.exception.wrapper.FavouriteNotFoundException;
import com.selimhorri.app.repository.FavouriteRepository;
import com.selimhorri.app.service.impl.FavouriteServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FavouriteServiceImplTest {

    @Mock
    private FavouriteRepository favouriteRepository;

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private FavouriteServiceImpl favouriteService;

    private LocalDateTime likeDate;
    private Favourite sampleEntity;
    private FavouriteDto sampleDto;
    private FavouriteId sampleId;

    @BeforeEach
    void setUp() {
        likeDate = LocalDateTime.of(2025, 1, 1, 12, 0, 0, 0);
        sampleEntity = Favourite.builder()
                .userId(1)
                .productId(2)
                .likeDate(likeDate)
                .build();
        sampleDto = FavouriteDto.builder()
                .userId(1)
                .productId(2)
                .likeDate(likeDate)
                .build();
        sampleId = new FavouriteId(1, 2, likeDate);
    }

    @Test
    void findAll_returnsDtosWithEnrichedReferences() {
        when(favouriteRepository.findAll()).thenReturn(List.of(sampleEntity));
        when(restTemplate.getForObject(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/1", UserDto.class))
                .thenReturn(UserDto.builder().userId(1).email("john@example.com").build());
        when(restTemplate.getForObject(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/2", ProductDto.class))
                .thenReturn(ProductDto.builder().productId(2).productTitle("Keyboard").build());

        List<FavouriteDto> result = favouriteService.findAll();

        assertThat(result).hasSize(1);
        FavouriteDto favouriteDto = result.get(0);
        assertThat(favouriteDto.getUserId()).isEqualTo(1);
        assertThat(favouriteDto.getProductDto()).isNotNull();
        assertThat(favouriteDto.getProductDto().getProductTitle()).isEqualTo("Keyboard");
        assertThat(favouriteDto.getUserDto()).isNotNull();
        assertThat(favouriteDto.getUserDto().getEmail()).isEqualTo("john@example.com");
    }

    @Test
    void findById_whenPresent_returnsDtoWithEnrichment() {
        when(favouriteRepository.findById(sampleId)).thenReturn(Optional.of(sampleEntity));
        when(restTemplate.getForObject(AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/1", UserDto.class))
                .thenReturn(UserDto.builder().userId(1).firstName("John").build());
        when(restTemplate.getForObject(AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/2", ProductDto.class))
                .thenReturn(ProductDto.builder().productId(2).productTitle("Keyboard").build());

        FavouriteDto result = favouriteService.findById(sampleId);

        assertThat(result.getLikeDate()).isEqualTo(likeDate);
        assertThat(result.getUserDto()).isNotNull();
        assertThat(result.getUserDto().getFirstName()).isEqualTo("John");
    }

    @Test
    void findById_whenMissing_throwsFavouriteNotFound() {
        when(favouriteRepository.findById(sampleId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> favouriteService.findById(sampleId))
                .isInstanceOf(FavouriteNotFoundException.class)
                .hasMessageContaining("Favourite with id");
    }

    @Test
    void save_persistsAndReturnsMappedDto() {
        when(favouriteRepository.save(any(Favourite.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FavouriteDto saved = favouriteService.save(sampleDto);

        assertThat(saved.getUserId()).isEqualTo(1);
        verify(favouriteRepository).save(any(Favourite.class));
    }

    @Test
    void update_persistsAndReturnsMappedDto() {
        when(favouriteRepository.save(any(Favourite.class))).thenAnswer(invocation -> invocation.getArgument(0));

        FavouriteDto updated = favouriteService.update(sampleDto);

        assertThat(updated.getProductId()).isEqualTo(2);
        verify(favouriteRepository).save(any(Favourite.class));
    }

    @Test
    void deleteById_delegatesToRepository() {
        favouriteService.deleteById(sampleId);

        verify(favouriteRepository).deleteById(sampleId);
    }
}
