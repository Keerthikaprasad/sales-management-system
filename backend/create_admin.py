from app.database import SessionLocal
from app.models import User
from app.services.auth_service import hash_password

db = SessionLocal()

admin = User(
    name="Admin User",
    email="admin@example.com",
    password_hash=hash_password("admin123"),
    role="admin",
    is_active=True
)

db.add(admin)
db.commit()
db.refresh(admin)

print("Admin created successfully!")
print("ID:", admin.id)
print("Email:", admin.email)
print("Role:", admin.role)

db.close()