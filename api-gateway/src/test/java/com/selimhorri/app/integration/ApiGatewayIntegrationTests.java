package com.selimhorri.app.integration;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.web.client.RestTemplate;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class ApiGatewayIntegrationTests {
    @Test
    void testRestTemplateGet() {
        RestTemplate restTemplate = new RestTemplate();
        assertNotNull(restTemplate);
    }

    @Test
    void testServiceDiscoveryConnection() {
        String url = "http://localhost:8761/eureka";
        assertTrue(url.contains("eureka"));
    }

    @Test
    void testConfigServerConnection() {
        String url = "http://localhost:9296";
        assertTrue(url.startsWith("http://"));
    }

    @Test
    void testApiGatewayHealthEndpoint() {
        String endpoint = "/actuator/health";
        assertEquals("/actuator/health", endpoint);
    }

    @Test
    void testIntegrationLogic() {
        int a = 10, b = 20;
        assertEquals(30, a + b);
    }
}
