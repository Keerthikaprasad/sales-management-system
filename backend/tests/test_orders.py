def get_token(client, email, password):
    response = client.post(
        "/api/auth/login",
        data={
            "username": email,
            "password": password
        }
    )
    return response.json()["access_token"]


def test_create_order_success(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "customer_id": 1,
            "items": [
                {
                    "product_id": 1,
                    "quantity": 2
                }
            ]
        }
    )

    assert response.status_code == 201

    data = response.json()

    assert data["customer_id"] == 1
    assert data["salesman_id"] == 1
    assert data["total_amount"] == "2000.00"
    assert len(data["items"]) == 1
    assert data["items"][0]["quantity"] == 2


def test_order_total_calculation(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "customer_id": 1,
            "items": [
                {
                    "product_id": 1,
                    "quantity": 2
                }
            ]
        }
    )

    assert response.status_code == 201
    assert response.json()["total_amount"] == "2000.00"


def test_duplicate_products_rejected(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "customer_id": 1,
            "items": [
                {
                    "product_id": 1,
                    "quantity": 1
                },
                {
                    "product_id": 1,
                    "quantity": 2
                }
            ]
        }
    )

    assert response.status_code == 400


def test_invalid_product_rejected(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "customer_id": 1,
            "items": [
                {
                    "product_id": 999,
                    "quantity": 1
                }
            ]
        }
    )

    assert response.status_code == 404


def test_invalid_quantity_rejected(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "customer_id": 1,
            "items": [
                {
                    "product_id": 1,
                    "quantity": 0
                }
            ]
        }
    )

    assert response.status_code == 422


def test_insufficient_stock_rejected(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "customer_id": 1,
            "items": [
                {
                    "product_id": 1,
                    "quantity": 999
                }
            ]
        }
    )

    assert response.status_code == 400


def test_get_orders(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/orders",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    assert isinstance(response.json(), list)