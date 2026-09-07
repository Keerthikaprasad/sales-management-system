from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field


class ProductCreate(BaseModel):
    sku: str
    name: str
    description: Optional[str] = None
    price: Decimal = Field(gt=0)
    stock_quantity: int = Field(ge=0)


class ProductResponse(BaseModel):
    id: int
    sku: str
    name: str
    description: Optional[str] = None
    price: Decimal
    stock_quantity: int
    is_active: bool

    class Config:
        from_attributes = True