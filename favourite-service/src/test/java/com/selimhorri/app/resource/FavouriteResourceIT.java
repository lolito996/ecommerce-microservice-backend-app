package com.selimhorri.app.resource;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.domain.id.FavouriteId;
import com.selimhorri.app.dto.FavouriteDto;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.service.FavouriteService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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

@WebMvcTest(FavouriteResource.class)
class FavouriteResourceIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private FavouriteService favouriteService;

    private FavouriteDto sampleDto;
    private FavouriteId sampleId;
    private String likeDateString;

    @BeforeEach
    void setUp() {
        LocalDateTime likeDate = LocalDateTime.of(2025, 1, 1, 11, 30, 0, 0);
        sampleDto = FavouriteDto.builder()
                .userId(1)
                .productId(2)
                .likeDate(likeDate)
                .userDto(UserDto.builder().userId(1).email("john@example.com").build())
                .productDto(ProductDto.builder().productId(2).productTitle("Keyboard").build())
                .build();
        sampleId = new FavouriteId(1, 2, likeDate);
        likeDateString = likeDate.format(DateTimeFormatter.ofPattern(AppConstant.LOCAL_DATE_TIME_FORMAT));
    }

    @Test
    void findAll_returnsCollectionResponse() throws Exception {
        when(favouriteService.findAll()).thenReturn(List.of(sampleDto));

        mockMvc.perform(get("/api/favourites"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection[0].userId").value(1))
                .andExpect(jsonPath("$.collection[0].product.productId").value(2));
    }

    @Test
    void findById_viaPathVariables_returnsFavourite() throws Exception {
        when(favouriteService.findById(sampleId)).thenReturn(sampleDto);

        mockMvc.perform(get("/api/favourites/{userId}/{productId}/{likeDate}", 1, 2, likeDateString))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(1))
                .andExpect(jsonPath("$.productId").value(2));
    }

    @Test
    void findById_viaBody_returnsFavourite() throws Exception {
        when(favouriteService.findById(sampleId)).thenReturn(sampleDto);

        mockMvc.perform(get("/api/favourites/find")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.product.productTitle").value("Keyboard"));
    }

    @Test
    void save_persistsFavourite() throws Exception {
        when(favouriteService.save(any(FavouriteDto.class))).thenReturn(sampleDto);

        mockMvc.perform(post("/api/favourites")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.userId").value(1));
    }

    @Test
    void update_replacesFavourite() throws Exception {
        when(favouriteService.update(any(FavouriteDto.class))).thenReturn(sampleDto);

        mockMvc.perform(put("/api/favourites")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.product.productId").value(2));
    }

    @Test
    void updateWithId_reusesUpdateMethod() throws Exception {
        when(favouriteService.update(any(FavouriteDto.class))).thenReturn(sampleDto);
        // Controller only exposes PUT at /api/favourites (body-based update). Use that endpoint here.
        mockMvc.perform(put("/api/favourites")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.productId").value(2))
                .andExpect(jsonPath("$.product.productId").value(2));

        // ensure service update was invoked
        verify(favouriteService).update(any(FavouriteDto.class));
    }

    @Test
    void deleteById_pathVariables_returnsTrue() throws Exception {
        mockMvc.perform(delete("/api/favourites/{userId}/{productId}/{likeDate}", 1, 2, likeDateString))
                .andExpect(status().isOk())
                .andExpect(content().string("true"));

        verify(favouriteService).deleteById(sampleId);
    }

    @Test
    void deleteById_requestBody_returnsTrue() throws Exception {
        mockMvc.perform(delete("/api/favourites/delete")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(sampleId)))
                .andExpect(status().isOk())
                .andExpect(content().string("true"));

        verify(favouriteService).deleteById(sampleId);
    }
}


