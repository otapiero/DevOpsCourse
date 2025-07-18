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

---

## 🔄 CI/CD Pipeline

This project includes a complete CI/CD pipeline using GitHub Actions that automatically builds, tests, and deploys the application to a virtual machine using Docker containers.

### 🏗️ Pipeline Architecture

The CI/CD pipeline consists of two main workflows:

#### CI Workflow (`.github/workflows/ci.yml`)
**Automatic Triggers:**
- Push to `main` branch
- Pull requests targeting `main` branch

**Manual Trigger:**
- Go to Actions → "CI - Continuous Integration" → "Run workflow"

**Pipeline Steps:**
1. **Environment Setup**: Node.js 18 with dependency caching
2. **Build Applications**: 
   - Frontend React application build
   - Backend Node.js application build
   - Build artifact storage for CD pipeline
3. **Code Quality Checks** (if configured):
   - ESLint validation for frontend and backend
   - Code formatting verification
4. **Test Execution** (if available):
   - Backend unit tests with Jest
   - Frontend component tests with React Testing Library
   - Test result reporting and coverage analysis
5. **Failure Handling**: 
   - Immediate pipeline termination on any failure
   - Detailed error reporting and GitHub status checks

#### CD Workflow (`.github/workflows/cd.yml`)
**Automatic Triggers:**
- Successful completion of CI workflow on `main` branch

**Manual Trigger:**
- Go to Actions → "CD - Continuous Deployment" → "Run workflow"
- Options available:
  - **Environment**: Select target environment (production/staging)
  - **Force deploy**: Bypass CI failure check (emergency use only)
  - **Skip health checks**: Skip post-deployment verification (emergency use only)

**Pipeline Steps:**
1. **Docker Image Building**:
   - Multi-platform builds (linux/amd64, linux/arm64)
   - Frontend image with optimized nginx serving
   - Backend image with Node.js runtime
   - Image tagging with commit SHA and 'latest'
2. **Registry Operations**:
   - Docker Hub authentication using secrets
   - Image push with retry logic for reliability
   - Image digest verification
3. **VM Deployment**:
   - SSH connection to target VM using key-based authentication
   - Secure transfer of docker-compose.yml (no source code transfer)
   - Container orchestration: stop old → pull new → start new
   - Health check verification with automatic rollback on failure
4. **Post-Deployment**:
   - Application availability verification
   - Deployment status reporting
   - Artifact storage for troubleshooting

### 🔧 Workflow Dependencies

The workflows are designed with proper dependency management:

- **CI → CD**: CD only triggers after successful CI completion
- **Build → Deploy**: Deployment uses images built in the same workflow run
- **Health Checks**: Deployment marked successful only after health verification
- **Rollback**: Automatic rollback to previous version on deployment failure

### ⚙️ Quick Setup

1. **Configure GitHub Secrets** (required):
   ```
   DOCKER_HUB_USERNAME      # Your Docker Hub username
   DOCKER_HUB_ACCESS_TOKEN  # Docker Hub access token (not password)
   VM_HOST                  # Target VM IP address or hostname
   VM_USERNAME              # SSH username for VM access
   VM_SSH_KEY               # Private SSH key for VM authentication
   ```

2. **Validate Configuration**:
   - Go to Actions tab → "Validate Secrets Configuration" → "Run workflow"
   - This verifies all secrets are properly configured

3. **First Deployment**:
   - Push code to `main` branch
   - CI will run automatically
   - CD will trigger after successful CI
   - Monitor progress in Actions tab

### 📋 Manual Workflow Execution

#### Running CI Manually
1. Navigate to Actions tab in your GitHub repository
2. Select "CI - Continuous Integration" workflow
3. Click "Run workflow" button
4. Choose branch (default: main)
5. Click "Run workflow" to start

#### Running CD Manually
1. Navigate to Actions tab in your GitHub repository
2. Select "CD - Continuous Deployment" workflow
3. Click "Run workflow" button
4. Configure deployment options:
   - **Environment**: Choose target environment
   - **Force deploy**: Check only for emergency deployments
   - **Skip health checks**: Check only if health checks are failing incorrectly
5. Click "Run workflow" to start

#### Emergency Deployment Procedure
For critical hotfixes or emergency deployments:
1. Use manual CD workflow execution
2. Enable "Force deploy" to bypass CI failure
3. Monitor deployment closely
4. Verify application functionality manually
5. Run full CI/CD pipeline for next deployment

### 🔍 Monitoring and Status

#### Workflow Status Monitoring
- **GitHub Actions Tab**: Real-time workflow execution status
- **Commit Status Checks**: Green checkmarks indicate successful pipelines
- **Pull Request Checks**: CI status visible on PR pages
- **Email Notifications**: GitHub sends notifications on workflow failures

#### Application Health Monitoring
- **Frontend Health**: http://YOUR_VM_IP:3000
- **Backend Health**: http://YOUR_VM_IP:5000/api/notes
- **Container Status**: SSH to VM and run `docker compose ps`
- **Application Logs**: SSH to VM and run `docker compose logs`

#### Troubleshooting Quick Checks
1. **Workflow Failures**: Check Actions tab for detailed logs
2. **Deployment Issues**: Review CD workflow logs and SSH to VM
3. **Application Not Responding**: Check container status and logs
4. **Build Failures**: Review CI workflow logs for specific error messages

### 📚 Additional Documentation

For comprehensive setup, troubleshooting, and maintenance information:
- [📖 Complete Setup Guide](.github/DEPLOYMENT_SETUP.md) - Detailed configuration instructions
- [🔧 Troubleshooting Guide](.github/DEPLOYMENT_SETUP.md#troubleshooting) - Common issues and solutions
- [🔒 Security Best Practices](.github/DEPLOYMENT_SETUP.md#security) - Secrets and access management
