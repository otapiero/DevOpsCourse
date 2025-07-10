# DevOps Course project

This is a playground project consisting of a frontend (React) and a backend (Node.js/Express) apps for deployment training.

---

## 🚀 Getting Started

### 🔧 Prerequisites

Make sure you have the following installed:

- [Node.js](https://nodejs.org/)
- npm (comes with Node.js)

---

## 📦 Install & Run

### ▶️ Frontend
```bash
cd frontend
npm install
npm start
```
### ▶️ Backend
```bash
cd backend
npm install
node index.js
```

---

## 🐳 Docker Setup

### Prerequisites
- [Docker](https://www.docker.com/) installed
- [Docker Compose](https://docs.docker.com/compose/) installed

### Build and Run with Docker Compose (Recommended)
```bash
# Build and start both services
docker-compose up --build -d

# View running containers
docker-compose ps

# Stop services
docker-compose down
```

### Individual Docker Commands

#### Backend
```bash
# Build backend image
cd backend
docker build -t notes-backend .

# Run backend container
docker run -d -p 5000:5000 --name backend-container notes-backend

# Test backend
curl http://localhost:5000/api/notes
```

#### Frontend
```bash
# Build frontend image
cd frontend
docker build -t notes-frontend .

# Run frontend container
docker run -d -p 3000:3000 --name frontend-container notes-frontend

# Test frontend
curl http://localhost:3000
```

### Access the Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000/api/notes
