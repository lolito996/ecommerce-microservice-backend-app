package com.example.user;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class UnitUserTest {

    @Test
    public void sampleUnitTest1() {
        assertEquals(2, 1+1);
    }

    @Test
    public void sampleUnitTest2() {
        assertTrue("hello".startsWith("h"));
    }
}
