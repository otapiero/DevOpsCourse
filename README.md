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

---

## 🖥️ VM Deployment

### Prerequisites
- VM with Ubuntu 20.04+ or similar Linux distribution
- SSH access to the VM
- VM with at least 2GB RAM and 10GB storage

### Step 1: Prepare the VM
```bash
# Update package manager
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to the docker group (optional, avoid using sudo with docker)
sudo usermod -aG docker ec2-user
newgrp docker  # Apply group changes without logout

# Install Docker Compose v2
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Test Docker & Compose
docker --version
docker compose version

```

### Step 2: Deploy the Docker-compose file
```bash
nano docker-compose.yml

past the docker-compose file

docker compose pull        # Pulls latest images from Docker Hub
docker compose up -d       # Runs in detached mode

```


### Step 3: Access Your Application
- **Frontend**: http://YOUR_VM_IP:3000
- **Backend API**: http://YOUR_VM_IP:5000/api/notes
