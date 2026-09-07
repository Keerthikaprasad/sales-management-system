# Sales Management System

A full-stack Sales Management System developed as a technical assessment.

## Project Architecture

Flutter Salesman App
        |
        v
FastAPI REST API
        |
        v
PostgreSQL Database
        ^
        |
React Admin Dashboard

## Technology Stack

- Flutter / Dart
- Python / FastAPI
- SQLAlchemy
- PostgreSQL
- Alembic
- JWT Authentication
- React / Vite
- Axios
- Recharts
- Pytest

## Features

### Salesman App

- Secure login
- Persistent authentication session
- Logout
- Customer list and search
- Customer details
- Product list and search
- Product details
- Create orders
- Multiple products per order
- Quantity management
- Automatic subtotal and total calculation
- Stock validation
- Order submission
- Order history
- Order details
- Order status

### Backend

- JWT authentication
- Role-based authorization
- Customer APIs
- Product APIs
- Order APIs
- Order item APIs
- Request validation
- Error handling
- PostgreSQL database integration
- Alembic database migrations
- Automatic API documentation

### Admin Dashboard

- Admin login
- Dashboard metrics
- Total sales
- Total orders
- Total customers
- Total salesmen
- Sales over time
- Orders over time
- Sales by salesman
- Top products
- Recent orders
- Order search
- Status filtering
- Amount filtering
- Order details
- Order status management

## Database

The system uses PostgreSQL with the following main tables:

- users
- customers
- products
- orders
- order_items

Order items store the product price at the time of purchase to preserve historical order values.

## Backend Setup

```bash
cd backend

python -m venv venv
venv\Scripts\activate

pip install -r requirements.txt