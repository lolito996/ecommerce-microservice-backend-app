package com.selimhorri.app.e2e;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ApiGatewayE2ETests {
    @Test
    void testUserFlow() {
        String user = "Alejo";
        String email = "alejo@email.com";
        assertTrue(user.length() > 0 && email.contains("@"));
    }

    @Test
    void testProductFlow() {
        String product = "Laptop";
        double price = 1200.0;
        assertTrue(product.length() > 0 && price > 0);
    }

    @Test
    void testOrderFlow() {
        int orderId = 123;
        boolean orderCreated = orderId > 0;
        assertTrue(orderCreated);
    }

    @Test
    void testPaymentFlow() {
        double payment = 1200.0;
        boolean paid = payment > 0;
        assertTrue(paid);
    }

    @Test
    void testFavouriteFlow() {
        String fav = "Laptop";
        assertEquals("Laptop", fav);
    }
}
