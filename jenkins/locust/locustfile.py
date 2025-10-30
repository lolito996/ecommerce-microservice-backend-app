from locust import HttpUser, task, between, tag


class WebsiteUser(HttpUser):
    wait_time = between(0.5, 2.0)

    @tag("catalog")
    @task(3)
    def list_products(self):
        self.client.get('/api/products', name='GET /api/products')

    @tag("catalog")
    @task(2)
    def get_product_detail(self):
        # hit a common product id; in real runs this could be randomized
        self.client.get('/api/products/1', name='GET /api/products/{id}')

    @tag("user")
    @task(2)
    def get_user(self):
        self.client.get('/api/users/1', name='GET /api/users/{id}')

    @tag("order")
    @task(1)
    def create_order(self):
        payload = {"userId": 1, "items": [{"productId": 1, "qty": 1}]}
        self.client.post('/api/orders', json=payload, name='POST /api/orders')

    @tag("order")
    @task(1)
    def get_orders(self):
        self.client.get('/api/orders', name='GET /api/orders')
