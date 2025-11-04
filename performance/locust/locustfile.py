from locust import HttpUser, task, between


class WebsiteUser(HttpUser):
    wait_time = between(1, 3)

    @task(5)
    def list_products(self):
        self.client.get("/products")

    @task(3)
    def list_users(self):
        self.client.get("/users")

    @task(1)
    def create_order(self):
        payload = {"userId": 1, "items": [{"productId": 1, "quantity": 1}]}
        self.client.post("/orders", json=payload)
