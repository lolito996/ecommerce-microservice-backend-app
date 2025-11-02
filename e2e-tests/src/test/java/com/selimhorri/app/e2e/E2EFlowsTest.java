package com.selimhorri.app.e2e;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

class E2EFlowsTest {

    private static final ObjectMapper M = new ObjectMapper();
    private static final String DATE_PATTERN = "dd-MM-yyyy__HH:mm:ss:SSSSSS";

    @BeforeAll
    static void setup() {
        String base = System.getenv().getOrDefault("TEST_BASE_URL", "http://localhost:8080");
        RestAssured.baseURI = base;
    }

    @Test
    void createUser_flow_returnsCreatedUser() throws IOException {
        JsonNode user = readFixture("fixtures/user1.json");
        // remove optional id if present to let service assign it
        ((com.fasterxml.jackson.databind.node.ObjectNode) user).remove("userId");

        given()
                .contentType(ContentType.JSON)
                .body(user.toString())
        .when()
                .post("/api/users")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("email", equalTo(user.get("email").asText()))
                .body("userId", notNullValue());
    }

    @Test
    void createProduct_flow_returnsCreatedProduct() throws IOException {
        JsonNode product = readFixture("fixtures/product1.json");
        ((com.fasterxml.jackson.databind.node.ObjectNode) product).remove("productId");

        given()
                .contentType(ContentType.JSON)
                .body(product.toString())
        .when()
                .post("/api/products")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("productTitle", equalTo(product.get("productTitle").asText()))
                .body("productId", notNullValue());
    }

    @Test
    void createOrder_flow_canCreateOrderForUserAndProduct() throws IOException {
        // create user
        int userId = createUserForTest();
        // create product
        int productId = createProductForTest();

        Map<String, Object> item = new HashMap<>();
        item.put("productId", productId);
        item.put("quantity", 1);

        Map<String, Object> cart = new HashMap<>();
        cart.put("userId", userId);
        cart.put("orderDtos", null);

        Map<String, Object> order = new HashMap<>();
        order.put("cart", cart);
        order.put("orderDesc", "E2E test order");
        order.put("orderDate", LocalDateTime.now().format(DateTimeFormatter.ofPattern(DATE_PATTERN)));

        given()
                .contentType(ContentType.JSON)
                .body(order)
        .when()
                .post("/api/orders")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("orderDesc", equalTo("E2E test order"));
    }

    @Test
    void addFavourite_flow_canSaveAndRetrieveFavourite() throws IOException {
        int userId = createUserForTest();
        int productId = createProductForTest();

        String likeDate = LocalDateTime.now().format(DateTimeFormatter.ofPattern(DATE_PATTERN));

        Map<String, Object> fav = new HashMap<>();
        fav.put("userId", userId);
        fav.put("productId", productId);
        fav.put("likeDate", likeDate);

        // save
        given()
                .contentType(ContentType.JSON)
                .body(fav)
        .when()
                .post("/api/favourites")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .body("userId", equalTo(userId))
                .body("productId", equalTo(productId));

        // fetch via path-based id
        given()
                .when()
                .get(String.format("/api/favourites/%d/%d/%s", userId, productId, likeDate))
        .then()
                .statusCode(200)
                .body("userId", equalTo(userId))
                .body("productId", equalTo(productId));
    }

    @Test
    void crossService_query_returnsExpectedRelationships() throws IOException {
        int userId = createUserForTest();
        int productId = createProductForTest();

        // create favourite
        String likeDate = LocalDateTime.now().format(DateTimeFormatter.ofPattern(DATE_PATTERN));
        Map<String, Object> fav = new HashMap<>();
        fav.put("userId", userId);
        fav.put("productId", productId);
        fav.put("likeDate", likeDate);

        given()
                .contentType(ContentType.JSON)
                .body(fav)
        .when()
                .post("/api/favourites")
        .then()
                .statusCode(anyOf(is(200), is(201)));

        // get favourites list and verify there's at least one with our productId
        given()
                .when()
                .get("/api/favourites")
        .then()
                .statusCode(200)
                .body("content.productId", hasItem(productId));
    }

    // --- helpers ---

    private int createUserForTest() throws IOException {
        JsonNode user = readFixture("fixtures/user1.json");
        ((com.fasterxml.jackson.databind.node.ObjectNode) user).remove("userId");

        return given()
                .contentType(ContentType.JSON)
                .body(user.toString())
        .when()
                .post("/api/users")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract().path("userId");
    }

    private int createProductForTest() throws IOException {
        JsonNode product = readFixture("fixtures/product1.json");
        ((com.fasterxml.jackson.databind.node.ObjectNode) product).remove("productId");

        return given()
                .contentType(ContentType.JSON)
                .body(product.toString())
        .when()
                .post("/api/products")
        .then()
                .statusCode(anyOf(is(200), is(201)))
                .extract().path("productId");
    }

    private JsonNode readFixture(final String path) throws IOException {
        try (InputStream in = E2EFlowsTest.class.getClassLoader().getResourceAsStream(path)) {
            if (in == null) throw new IOException("Fixture not found: " + path);
            return M.readTree(in);
        }
    }

}
