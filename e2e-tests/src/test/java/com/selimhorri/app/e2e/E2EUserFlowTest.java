package com.selimhorri.app.e2e;

import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static org.hamcrest.Matchers.*;

public class E2EUserFlowTest {

    @BeforeAll
    public static void init() {
        String base = System.getenv("TEST_BASE_URL");
        if (base == null || base.isEmpty()) {
            base = "http://localhost:8080";
        }
        RestAssured.baseURI = base;
    }

    @Test
    public void createUser_flow_returnsCreatedUser() {
    RestAssured.baseURI = "http://localhost:8080/user-service/api/users";
    RestAssured.given()
        .contentType("application/json")
        .body("{\"firstName\":\"Alejandro\",\"lastName\":\"Cordoba\",\"email\":\"e2e@example.com\"}")
        .when()
        .post("/user-service/api/users")
        .then()
        .statusCode(anyOf(is(200), is(201)));
    }
}
