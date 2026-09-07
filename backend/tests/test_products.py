def get_token(client, email, password):
    response = client.post(
        "/api/auth/login",
        data={
            "username": email,
            "password": password
        }
    )
    return response.json()["access_token"]


def test_get_products(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/products",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["name"] == "Test Laptop"


def test_get_product_by_id(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/products/1",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    assert response.json()["id"] == 1
    assert response.json()["price"] == "1000.00"


def test_product_search(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/products?search=Laptop",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_product_not_found(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/products/999",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 404


def test_create_product_requires_admin(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/products",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "sku": "NEW001",
            "name": "New Product",
            "description": "Test product",
            "price": 500,
            "stock_quantity": 10
        }
    )

    assert response.status_code == 403


def test_create_product_admin(client):
    token = get_token(client, "admin@test.com", "admin123")

    response = client.post(
        "/api/products",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "sku": "NEW001",
            "name": "New Product",
            "description": "Test product",
            "price": 500,
            "stock_quantity": 10
        }
    )

    assert response.status_code == 201
    assert response.json()["sku"] == "NEW001"


def test_duplicate_product_sku_rejected(client):
    token = get_token(client, "admin@test.com", "admin123")

    response = client.post(
        "/api/products",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "sku": "TEST001",
            "name": "Duplicate Product",
            "description": "Duplicate SKU",
            "price": 500,
            "stock_quantity": 10
        }
    )

    assert response.status_code == 409


def test_invalid_product_price_rejected(client):
    token = get_token(client, "admin@test.com", "admin123")

    response = client.post(
        "/api/products",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "sku": "INVALID001",
            "name": "Invalid Product",
            "description": "Invalid price",
            "price": 0,
            "stock_quantity": 10
        }
    )

    assert response.status_code == 422