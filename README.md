# Finance Dashboard Backend

A Rails API backend with JWT authentication for the Finance Dashboard application.

## Getting Started

### Prerequisites

* Ruby ~> 3.0
* PostgreSQL
* Bundler

### Installation

1. Install dependencies:
```bash
bundle install
```

2. Set up the database:
```bash
rails db:create db:migrate
```

3. Start the server:
```bash
bin/dev
```

The server will start on `http://localhost:3000`

## Authentication

This application uses Devise with JWT for authentication.

### Sign Up

Create a new user account:

```bash
POST /users
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

**Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Signed up successfully."
  },
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "created_at": "2025-10-31T11:00:00.000Z",
    "updated_at": "2025-10-31T11:00:00.000Z"
  }
}
```

### Sign In

Authenticate and receive a JWT token:

```bash
POST /users/sign_in
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Logged in successfully."
  },
  "data": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "created_at": "2025-10-31T11:00:00.000Z",
    "updated_at": "2025-10-31T11:00:00.000Z"
  }
}
```

The JWT token will be included in the `Authorization` header in the response.

### Making Authenticated Requests

Include the JWT token in subsequent requests:

```bash
Authorization: Bearer <your_jwt_token>
```

### Sign Out

Revoke the current JWT token:

```bash
DELETE /users/sign_out
Authorization: Bearer <your_jwt_token>
```

**Response:**
```json
{
  "status": 200,
  "message": "Logged out successfully."
}
```

## API Endpoints

* `POST /users` - Create a new user account
* `POST /users/sign_in` - Sign in and receive JWT token
* `DELETE /users/sign_out` - Sign out and revoke JWT token

## Testing

This application uses RSpec for testing. To run the test suite:

```bash
bundle exec rspec
```

To run specific test files:

```bash
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
```

## License

This project is proprietary software.
