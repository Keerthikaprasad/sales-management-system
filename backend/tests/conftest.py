import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

from app.config import settings
from app.database import Base, get_db
from app.main import app
from app.models import User, Customer, Product
from app.services.auth_service import hash_password


engine = create_engine(settings.TEST_DATABASE_URL)

TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


@pytest.fixture()
def db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = TestingSessionLocal()

    salesman = User(
        name="Test Salesman",
        email="salesman@test.com",
        password_hash=hash_password("test123"),
        role="salesman",
        is_active=True
    )

    admin = User(
        name="Test Admin",
        email="admin@test.com",
        password_hash=hash_password("admin123"),
        role="admin",
        is_active=True
    )

    customer = Customer(
        name="Test Customer",
        email="customer@test.com",
        phone="9876543210",
        address="Test Address"
    )

    product = Product(
        sku="TEST001",
        name="Test Laptop",
        description="Test Product",
        price=1000,
        stock_quantity=10,
        is_active=True
    )

    db.add_all([
        salesman,
        admin,
        customer,
        product
    ])

    db.commit()

    yield db

    db.close()


@pytest.fixture()
def client(db):
    def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()