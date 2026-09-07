from typing import Optional
from pydantic import BaseModel, EmailStr


class CustomerCreate(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    phone: str
    address: Optional[str] = None


class CustomerResponse(BaseModel):
    id: int
    name: str
    email: Optional[EmailStr] = None
    phone: str
    address: Optional[str] = None

    class Config:
        from_attributes = True