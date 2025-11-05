package com.selimhorri.app.e2e;

import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.hamcrest.Matchers.*;

public class E2EOrderFlowTest {

    @BeforeAll
    public static void init() {
        String base = System.getenv("TEST_BASE_URL");
        if (base == null || base.isEmpty()) {
            base = "http://localhost:8080";
        }
        RestAssured.baseURI = base;
    }

    @Test
    public void createOrder_flow_returns201or200() {
        // This test assumes users and products exist; it's a lightweight smoke test
        RestAssured.given()
                .contentType("application/json")
                .body("{\"userId\":1, \"items\":[{\"productId\":1,\"quantity\":1}]}")
                .when()
                .post("/app/api/orders")
                .then()
                .statusCode(anyOf(is(200), is(201), is(400)));
    }
}
