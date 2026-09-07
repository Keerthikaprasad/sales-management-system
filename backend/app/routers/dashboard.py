from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_role
from app.models import Customer, Order, User, Product, OrderItem

router = APIRouter(
    prefix="/api/dashboard",
    tags=["Dashboard"]
)


# =========================================================
# DASHBOARD SUMMARY
# =========================================================

@router.get("/summary")
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin"))
):
    total_sales = db.query(
        func.coalesce(func.sum(Order.total_amount), 0)
    ).scalar()

    total_orders = db.query(
        func.count(Order.id)
    ).scalar()

    total_customers = db.query(
        func.count(Customer.id)
    ).scalar()

    total_salesmen = db.query(
        func.count(User.id)
    ).filter(
        User.role == "salesman"
    ).scalar()

    recent_orders = db.query(Order).order_by(
        Order.created_at.desc()
    ).limit(5).all()

    return {
        "total_sales": total_sales,
        "total_orders": total_orders,
        "total_customers": total_customers,
        "total_salesmen": total_salesmen,
        "recent_orders": [
            {
                "id": order.id,
                "customer_id": order.customer_id,
                "salesman_id": order.salesman_id,
                "status": order.status,
                "total_amount": order.total_amount,
                "created_at": order.created_at
            }
            for order in recent_orders
        ]
    }


# =========================================================
# SALES OVER TIME
# =========================================================

@router.get("/sales-over-time")
def get_sales_over_time(
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin"))
):
    results = db.query(
        func.date(Order.created_at).label("date"),
        func.sum(Order.total_amount).label("total_sales")
    ).group_by(
        func.date(Order.created_at)
    ).order_by(
        func.date(Order.created_at)
    ).all()

    return [
        {
            "date": str(row.date),
            "total_sales": row.total_sales
        }
        for row in results
    ]
@router.get("/orders-over-time")
def get_orders_over_time(
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin"))
):
    results = db.query(
        func.date(Order.created_at).label("date"),
        func.count(Order.id).label("total_orders")
    ).group_by(
        func.date(Order.created_at)
    ).order_by(
        func.date(Order.created_at)
    ).all()

    return [
        {
            "date": str(row.date),
            "total_orders": row.total_orders
        }
        for row in results
    ]
@router.get("/sales-by-salesman")
def get_sales_by_salesman(
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin"))
):
    results = db.query(
        User.id.label("salesman_id"),
        User.name.label("salesman_name"),
        func.coalesce(func.sum(Order.total_amount), 0).label("total_sales")
    ).join(
        Order, Order.salesman_id == User.id
    ).filter(
        User.role == "salesman"
    ).group_by(
        User.id, User.name
    ).order_by(
        func.sum(Order.total_amount).desc()
    ).all()

    return [
        {
            "salesman_id": row.salesman_id,
            "salesman_name": row.salesman_name,
            "total_sales": row.total_sales
        }
        for row in results
    ]
@router.get("/top-products")
def get_top_products(
    db: Session = Depends(get_db),
    current_user=Depends(require_role("admin"))
):
    results = db.query(
        Product.id.label("product_id"),
        Product.name.label("product_name"),
        func.sum(OrderItem.quantity).label("total_quantity"),
        func.sum(OrderItem.subtotal).label("total_sales")
    ).join(
        OrderItem, OrderItem.product_id == Product.id
    ).join(
        Order, Order.id == OrderItem.order_id
    ).group_by(
        Product.id, Product.name
    ).order_by(
        func.sum(OrderItem.quantity).desc()
    ).limit(10).all()

    return [
        {
            "product_id": row.product_id,
            "product_name": row.product_name,
            "total_quantity": row.total_quantity,
            "total_sales": row.total_sales
        }
        for row in results
    ]