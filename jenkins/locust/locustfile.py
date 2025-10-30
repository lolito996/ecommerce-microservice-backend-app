from locust import HttpUser, task, between


class WebsiteUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def list_products(self):
        self.client.get('/api/products')

    @task(2)
    def get_user(self):
        self.client.get('/api/users/1')

    @task(1)
    def create_order(self):
        self.client.post('/api/orders', json={"userId":1, "items": [{"productId":1, "qty":1}]})
