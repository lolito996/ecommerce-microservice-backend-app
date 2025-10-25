from locust import HttpUser, task, between

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def get_products(self):
        self.client.get("/api/products")

    @task
    def create_user(self):
        self.client.post("/api/users", json={"firstName": "Alejo", "lastName": "Munoz", "email": "alejo@email.com"})

    @task
    def create_order(self):
        self.client.post("/api/orders", json={"userId": 1, "productId": 2, "quantity": 1})

    @task
    def make_payment(self):
        self.client.post("/api/payments", json={"orderId": 1, "amount": 1200.0})

    @task
    def add_favourite(self):
        self.client.post("/api/favourites", json={"userId": 1, "productId": 2})
