def get_token(client, email, password):
    response = client.post(
        "/api/auth/login",
        data={
            "username": email,
            "password": password
        }
    )
    return response.json()["access_token"]


def create_test_order(client):
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
                }
            ]
        }
    )

    assert response.status_code == 201

    return response.json()["id"]


def test_admin_can_get_all_orders(client):
    create_test_order(client)

    token = get_token(client, "admin@test.com", "admin123")

    response = client.get(
        "/api/orders/admin/all",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_salesman_cannot_get_all_orders(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/orders/admin/all",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 403


def test_admin_can_update_order_status(client):
    order_id = create_test_order(client)

    token = get_token(client, "admin@test.com", "admin123")

    response = client.patch(
        f"/api/orders/admin/{order_id}/status",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "status": "confirmed"
        }
    )

    assert response.status_code == 200
    assert response.json()["status"] == "confirmed"


def test_salesman_cannot_update_order_status(client):
    order_id = create_test_order(client)

    token = get_token(client, "salesman@test.com", "test123")

    response = client.patch(
        f"/api/orders/admin/{order_id}/status",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "status": "confirmed"
        }
    )

    assert response.status_code == 403


def test_invalid_order_status_rejected(client):
    order_id = create_test_order(client)

    token = get_token(client, "admin@test.com", "admin123")

    response = client.patch(
        f"/api/orders/admin/{order_id}/status",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "status": "invalid_status"
        }
    )

    assert response.status_code == 400


def test_admin_order_not_found(client):
    token = get_token(client, "admin@test.com", "admin123")

    response = client.patch(
        "/api/orders/admin/999/status",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "status": "confirmed"
        }
    )

    assert response.status_code == 404