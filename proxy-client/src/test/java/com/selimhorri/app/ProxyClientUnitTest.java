package com.selimhorri.app;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class ProxyClientUnitTest {

    @Test
    void basicAssertion_shouldPass() {
        assertThat("hello".toUpperCase()).isEqualTo("HELLO");
    }
}
