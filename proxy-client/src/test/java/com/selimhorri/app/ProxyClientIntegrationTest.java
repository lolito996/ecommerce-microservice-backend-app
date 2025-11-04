package com.selimhorri.app;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class ProxyClientIntegrationTest {

    @Test
    void contextLoadsIntegration() {
        assertThat(true).isTrue();
    }
}
