package com.selimhorri.app.service;

import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import com.selimhorri.app.helper.UserMappingHelper;
import com.selimhorri.app.repository.UserRepository;
import com.selimhorri.app.service.impl.UserServiceImpl;
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
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserServiceImpl userService;

    private UserDto sampleDto;
    private User sampleEntity;
    private RoleBasedAuthority roleBasedAuthority;

    @BeforeEach
    void setup() {
        sampleDto = UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john@example.com")
                .phone("1234567890")
                .credentialDto(CredentialDto.builder()
                        .credentialId(10)
                        .username("john")
                        .password("secret")
                        .roleBasedAuthority(roleBasedAuthority)
                        .isEnabled(true)
                        .isAccountNonExpired(true)
                        .isAccountNonLocked(true)
                        .isCredentialsNonExpired(true)
                        .build())
                .build();
        sampleEntity = UserMappingHelper.map(sampleDto);
    }

    @Test
    void findById_found_ok() {
        when(userRepository.findById(1)).thenReturn(Optional.of(sampleEntity));

        UserDto result = userService.findById(1);

        assertThat(result.getFirstName()).isEqualTo("John");
        assertThat(result.getCredentialDto().getUsername()).isEqualTo("john");
    }

    @Test
    void findById_missing_throws() {
        when(userRepository.findById(999)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.findById(999))
                .isInstanceOf(UserObjectNotFoundException.class)
                .hasMessageContaining("999");
    }

    @Test
    void findAll_returnsMappedDtos() {
        when(userRepository.findAll()).thenReturn(List.of(sampleEntity));

        List<UserDto> result = userService.findAll();

        assertThat(result)
                .hasSize(1)
                .first()
                .extracting(UserDto::getEmail)
                .isEqualTo("john@example.com");
    }

    @Test
    void save_persistsAndMapsBack() {
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UserDto saved = userService.save(sampleDto);

        assertThat(saved.getCredentialDto().getUsername()).isEqualTo("john");
        verify(userRepository).save(any(User.class));
    }

    @Test
    void findByUsername_returnsDto() {
        when(userRepository.findByCredentialUsername("john")).thenReturn(Optional.of(sampleEntity));

        UserDto result = userService.findByUsername("john");

        assertThat(result.getEmail()).isEqualTo("john@example.com");
    }

    @Test
    void findByUsername_missing_throws() {
        when(userRepository.findByCredentialUsername("ghost")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.findByUsername("ghost"))
                .isInstanceOf(UserObjectNotFoundException.class)
                .hasMessageContaining("ghost");
    }

    @Test
    void deleteById_delegatesRepository() {
        userService.deleteById(1);

        verify(userRepository, times(1)).deleteById(1);
    }

}


