package com.selimhorri.app.e2e;

import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

class ApiGatewayE2E {

    @BeforeAll
    static void setup() {
        String base = System.getenv().getOrDefault("TEST_BASE_URL", "http://localhost:8080");
        RestAssured.baseURI = base;
    }

    @Test
    void listProducts_returns200() {
        given()
                .when()
            .get("/app/api/products")
                .then()
                .statusCode(200);
    }

}
