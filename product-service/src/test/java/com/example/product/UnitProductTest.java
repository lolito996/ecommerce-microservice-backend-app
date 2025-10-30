package com.example.product;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class UnitProductTest {

    @Test
    public void sampleProductUnit1() {
        assertEquals(3, 1+2);
    }

    @Test
    public void sampleProductUnit2() {
        assertTrue("product".contains("prod"));
    }
}
