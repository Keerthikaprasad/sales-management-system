from app.database import SessionLocal
from app.models import User
from app.services.auth_service import hash_password


db = SessionLocal()

user = User(
    name="Test Salesman",
    email="salesman@example.com",
    password_hash=hash_password("test123"),
    role="salesman",
    is_active=True
)

db.add(user)
db.commit()
db.refresh(user)

print("User created successfully!")
print("ID:", user.id)
print("Email:", user.email)
print("Role:", user.role)

db.close()