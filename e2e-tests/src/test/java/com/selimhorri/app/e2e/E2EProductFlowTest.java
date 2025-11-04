package com.selimhorri.app.e2e;

import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.hamcrest.Matchers.*;

public class E2EProductFlowTest {

    @BeforeAll
    public static void init() {
        String base = System.getenv("TEST_BASE_URL");
        if (base == null || base.isEmpty()) {
            base = "http://localhost:8080";
        }
        RestAssured.baseURI = base;
    }

    @Test
    public void listProducts_returns200() {
    RestAssured.baseURI = "http://localhost:8080";
    RestAssured.given()
        .when()
        .get("/product-service/api/products")
        .then()
        .statusCode(200);
    }
}
