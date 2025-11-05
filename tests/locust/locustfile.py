from locust import HttpUser, task, between
import os

# Variables de entorno para endpoints
PRODUCT_URL = os.getenv("PRODUCT_URL", "http://localhost:8500/product-service/api/products")
USER_URL = os.getenv("USER_URL", "http://localhost:8700/user-service/api/users")
SHIPPING_URL = os.getenv("SHIPPING_URL", "http://localhost:8600/shipping-service/api/shippings")
PAYMENT_URL = os.getenv("PAYMENT_URL", "http://localhost:8400/payment-service/api/payments")
ORDER_URL = os.getenv("ORDER_URL", "http://localhost:8300/order-service/api/orders")
FAVOURITE_URL = os.getenv("FAVOURITE_URL", "http://localhost:8800/favourite-service/api/favourites")

class EcommerceUser(HttpUser):
    wait_time = between(0.5, 1.5)

    @task(3)
    def get_products(self):
        self.client.get(PRODUCT_URL, name="GET /products")

    @task(3)
    def get_users(self):
        self.client.get(USER_URL, name="GET /users")

    @task(1)
    def get_shipping(self):
        try:
            self.client.get(SHIPPING_URL, name="GET /shippings", timeout=5)
        except Exception:
            pass

    @task(1)
    def get_payments(self):
        try:
            self.client.get(PAYMENT_URL, name="GET /payments", timeout=5)
        except Exception:
            pass

    @task(1)
    def get_orders(self):
        try:
            self.client.get(ORDER_URL, name="GET /orders", timeout=5)
        except Exception:
            pass

    @task(1)
    def get_favourites(self):
        try:
            self.client.get(FAVOURITE_URL, name="GET /favourites", timeout=5)
        except Exception:
            pass
