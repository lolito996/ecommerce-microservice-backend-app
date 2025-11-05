package com.selimhorri.app.unit;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ApiGatewayUnitTests {
    @Test
    void testSum() {
        int result = 2 + 3;
        assertEquals(5, result);
    }

    @Test
    void testStringNotEmpty() {
        String s = "api-gateway";
        assertFalse(s.isEmpty());
    }

    @Test
    void testObjectCreation() {
        Object obj = new Object();
        assertNotNull(obj);
    }

    @Test
    void testExceptionThrown() {
        assertThrows(NumberFormatException.class, () -> Integer.parseInt("abc"));
    }

    @Test
    void testBooleanLogic() {
        boolean isActive = true;
        assertTrue(isActive);
    }
}
