from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.dependencies import get_current_user, require_role
from app.models import Customer, Order, OrderItem, Product, User
from app.schemas.order import (
    OrderCreate,
    OrderResponse,
    OrderStatusUpdate,
)

router = APIRouter(prefix="/api/orders", tags=["Orders"])


# Create Order
@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(
    order_data: OrderCreate,
    db: Session = Depends(get_db),
    current_user=Depends(require_role("salesman")),
):
    customer = (
        db.query(Customer)
        .filter(Customer.id == order_data.customer_id)
        .first()
    )

    if customer is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found",
        )

    if not order_data.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Order must contain at least one product",
        )

    product_ids = [item.product_id for item in order_data.items]

    # Prevent duplicate products in the same order
    if len(product_ids) != len(set(product_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duplicate products are not allowed in an order",
        )

    total = Decimal("0.00")
    order_items = []

    for item_data in order_data.items:
        product = (
            db.query(Product)
            .filter(
                Product.id == item_data.product_id,
                Product.is_active == True,
            )
            .first()
        )

        if product is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product {item_data.product_id} not found",
            )

        if product.stock_quantity < item_data.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for product {product.name}",
            )

        unit_price = Decimal(product.price)
        subtotal = unit_price * item_data.quantity

        total += subtotal

        order_items.append(
            OrderItem(
                product_id=product.id,
                quantity=item_data.quantity,
                unit_price=unit_price,
                subtotal=subtotal,
            )
        )

        product.stock_quantity -= item_data.quantity

    order = Order(
        customer_id=customer.id,
        salesman_id=current_user.id,
        status="pending",
        total_amount=total,
    )

    db.add(order)
    db.flush()

    for item in order_items:
        item.order_id = order.id
        db.add(item)

    db.commit()

    db.refresh(order)

    # Load relationships
    order = (
        db.query(Order)
        .options(
            joinedload(Order.items)
        )
        .filter(Order.id == order.id)
        .first()
    )

    return build_order_response(db, order)


# Salesman's own orders
@router.get("", response_model=list[OrderResponse])
def get_orders(
    db: Session = Depends(get_db),
    current_user=Depends(require_role("salesman")),
):
    orders = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.salesman_id == current_user.id)
        .order_by(Order.created_at.desc())
        .all()
    )

    return [
        build_order_response(db, order)
        for order in orders
    ]


# Admin: Get all orders
@router.get("/admin/all", response_model=list[OrderResponse])
def get_all_orders(
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin")),
):
    query = (
        db.query(Order)
        .options(joinedload(Order.items))
    )

    if status_filter:
        query = query.filter(Order.status == status_filter)

    orders = (
        query
        .order_by(Order.created_at.desc())
        .all()
    )

    return [
        build_order_response(db, order)
        for order in orders
    ]


# Admin: Update order status
@router.patch(
    "/admin/{order_id}/status",
    response_model=OrderResponse,
)
def update_order_status(
    order_id: int,
    status_data: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin")),
):
    allowed_statuses = {
        "pending",
        "confirmed",
        "shipped",
        "delivered",
        "cancelled",
    }

    if status_data.status not in allowed_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid order status",
        )

    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )

    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    order.status = status_data.status

    db.commit()
    db.refresh(order)

    return build_order_response(db, order)


# Get single order
@router.get("/{order_id}", response_model=OrderResponse)
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )

    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    # Salesmen can only see their own orders
    if current_user.role == "salesman":
        if order.salesman_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to access this order",
            )

    return build_order_response(db, order)


# Build response with names
def build_order_response(db: Session, order: Order):
    customer = (
        db.query(Customer)
        .filter(Customer.id == order.customer_id)
        .first()
    )

    salesman = (
        db.query(User)
        .filter(User.id == order.salesman_id)
        .first()
    )

    items = []

    for item in order.items:
        product = (
            db.query(Product)
            .filter(Product.id == item.product_id)
            .first()
        )

        items.append(
            {
                "id": item.id,
                "product_id": item.product_id,
                "product_name": product.name if product else "Unknown Product",
                "quantity": item.quantity,
                "unit_price": item.unit_price,
                "subtotal": item.subtotal,
            }
        )

    return {
        "id": order.id,
        "customer_id": order.customer_id,
        "customer_name": customer.name if customer else "Unknown Customer",
        "salesman_id": order.salesman_id,
        "salesman_name": salesman.name if salesman else "Unknown Salesman",
        "status": order.status,
        "total_amount": order.total_amount,
        "created_at": order.created_at,
        "items": items,
    }