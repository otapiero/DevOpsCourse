# GitHub Actions CI/CD Setup Guide

This document provides comprehensive setup instructions for the GitHub Actions CI/CD pipeline for the Notes application.

## Required GitHub Secrets

The following secrets must be configured in your GitHub repository settings (Settings → Secrets and variables → Actions):

### Docker Hub Configuration

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `DOCKER_HUB_USERNAME` | Your Docker Hub username | `your-username` | ✅ Yes |
| `DOCKER_HUB_ACCESS_TOKEN` | Docker Hub access token (not password) | `dckr_pat_...` | ✅ Yes |

**How to create Docker Hub Access Token:**
1. Log in to Docker Hub
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Give it a descriptive name (e.g., "GitHub Actions CI/CD")
5. Select appropriate permissions (Read, Write, Delete)
6. Copy the generated token immediately (it won't be shown again)

### VM Deployment Configuration

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `VM_HOST` | Target VM IP address or hostname | `192.168.1.100` or `myserver.com` | ✅ Yes |
| `VM_USERNAME` | SSH username for VM access | `ubuntu` or `deploy` | ✅ Yes |
| `VM_SSH_KEY` | Private SSH key for VM authentication | `-----BEGIN OPENSSH PRIVATE KEY-----...` | ✅ Yes |

**How to set up SSH key authentication:**
1. Generate SSH key pair on your local machine:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions-deploy"
   ```
2. Copy the public key to your VM:
   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa.pub username@your-vm-host
   ```
3. Copy the **private key** content to the `VM_SSH_KEY` secret
4. Test the connection:
   ```bash
   ssh -i ~/.ssh/id_rsa username@your-vm-host
   ```

### Optional Notification Secrets

| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `SLACK_WEBHOOK_URL` | Slack webhook for deployment notifications | `https://hooks.slack.com/...` | ❌ No |
| `TEAMS_WEBHOOK_URL` | Microsoft Teams webhook URL | `https://outlook.office.com/...` | ❌ No |

## Environment Variables Configuration

The following environment variables are configured in the workflow files and can be customized:

### Global Environment Variables

```yaml
env:
  NODE_VERSION: '18'                    # Node.js version for builds
  DOCKER_BUILDKIT: '1'                  # Enable Docker BuildKit
  COMPOSE_DOCKER_CLI_BUILD: '1'         # Use Docker CLI for compose builds
  ARTIFACT_RETENTION_DAYS: 7            # How long to keep build artifacts
```

### Docker Image Configuration

```yaml
env:
  REGISTRY: docker.io                   # Docker registry (Docker Hub)
  FRONTEND_IMAGE: ${{ secrets.DOCKER_HUB_USERNAME }}/notes-frontend
  BACKEND_IMAGE: ${{ secrets.DOCKER_HUB_USERNAME }}/notes-backend
```

**Important:** The image names are automatically constructed using your Docker Hub username. Ensure your Docker Hub username is set correctly in the secrets.

## VM Prerequisites and Preparation

Your target VM must meet the following requirements and be properly configured:

### System Requirements

| Requirement | Minimum | Recommended | Notes |
|-------------|---------|-------------|-------|
| **OS** | Ubuntu 18.04+ / CentOS 7+ | Ubuntu 22.04 LTS | Other Linux distributions supported |
| **RAM** | 2GB | 4GB+ | For running both frontend and backend containers |
| **Storage** | 10GB free | 20GB+ free | For Docker images and application data |
| **CPU** | 1 vCPU | 2+ vCPUs | Better performance for builds and deployments |
| **Network** | Public IP | Static IP preferred | Required for GitHub Actions access |

### Step-by-Step VM Preparation

#### 1. Initial System Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common

# Create deployment user (optional but recommended)
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG sudo deploy

# Switch to deployment user
sudo su - deploy
```

#### 2. Docker Installation

**For Ubuntu/Debian:**
```bash
# Remove old Docker versions
sudo apt remove docker docker-engine docker.io containerd runc

# Install Docker using official script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
docker run hello-world
```

**For CentOS/RHEL:**
```bash
# Install Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### 3. Docker Compose Installation

```bash
# Install Docker Compose v2 (recommended)
mkdir -p ~/.docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

# Verify installation
docker compose version

# Alternative: Install as standalone binary
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 4. SSH Configuration

```bash
# Ensure SSH service is running
sudo systemctl status ssh
sudo systemctl enable ssh

# Configure SSH for key-based authentication
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key to authorized_keys
# (Replace with your actual public key)
echo "ssh-rsa AAAAB3NzaC1yc2EAAAA... your-public-key" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Test SSH connection from your local machine
# ssh -i ~/.ssh/your-private-key username@your-vm-ip
```

#### 5. Directory Structure Setup

```bash
# Create application directory
mkdir -p ~/app
cd ~/app

# Create logs directory for persistent storage
mkdir -p ~/app/logs

# Set proper permissions
chmod 755 ~/app
chmod 755 ~/app/logs
```

### Required Software

1. **Docker Engine** (version 20.10 or later)
2. **Docker Compose** (version 2.0 or later)
3. **SSH Server** (OpenSSH 7.0 or later)
4. **curl/wget** (for health checks)
5. **Git** (optional, for manual deployments)

### Network Configuration

Ensure the following ports are open on your VM:

| Port | Service | Protocol | Required |
|------|---------|----------|----------|
| 22 | SSH | TCP | ✅ Yes (for deployment) |
| 3000 | Frontend | TCP | ✅ Yes |
| 5000 | Backend | TCP | ✅ Yes |
| 80 | HTTP (optional) | TCP | ❌ No |
| 443 | HTTPS (optional) | TCP | ❌ No |

### Firewall Configuration

```bash
# Ubuntu/Debian with ufw
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # Frontend
sudo ufw allow 5000/tcp  # Backend
sudo ufw enable
```

### Directory Structure

The deployment process will create the following structure on your VM:

```
~/
├── docker-compose.yml          # Production compose file (auto-generated)
├── docker-compose.prod.yml     # Backup of compose file
└── logs/                       # Application logs (if volume mounted)
```

## Security Best Practices

### SSH Key Management

1. **Use dedicated SSH keys** for GitHub Actions (don't reuse personal keys)
2. **Restrict SSH key permissions** on the VM:
   ```bash
   # In ~/.ssh/authorized_keys, prefix the key with restrictions:
   command="docker-compose up -d",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-rsa AAAAB3...
   ```
3. **Regularly rotate SSH keys** (recommended: every 90 days)
4. **Monitor SSH access logs** on your VM

### Docker Hub Security

1. **Use access tokens** instead of passwords
2. **Limit token permissions** to only what's needed (Read, Write)
3. **Regularly rotate access tokens** (recommended: every 6 months)
4. **Enable 2FA** on your Docker Hub account

### VM Security

1. **Keep the VM updated**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. **Configure automatic security updates**
3. **Use a firewall** (ufw, iptables, or cloud provider security groups)
4. **Monitor deployment logs** for suspicious activity
5. **Limit sudo access** for the deployment user

## Troubleshooting

### Common Issues and Solutions

#### 1. GitHub Actions Workflow Issues

##### CI Workflow Fails to Start
```
Error: Workflow not triggered on push to main
```
**Possible Causes:**
- Workflow file syntax errors
- Branch protection rules blocking workflow
- Repository permissions issues

**Solutions:**
1. Validate YAML syntax in workflow files
2. Check branch protection settings in repository settings
3. Verify Actions are enabled for the repository
4. Check if workflow file is in correct path (`.github/workflows/`)

##### Build Failures in CI
```
Error: npm ERR! code ELIFECYCLE
```
**Solutions:**
1. Check Node.js version compatibility
2. Clear npm cache: Add `npm ci --cache .npm --prefer-offline` to workflow
3. Verify package.json dependencies are correct
4. Check for platform-specific build issues

#### 2. Docker Hub Issues

##### Authentication Failed
```
Error: denied: requested access to the resource is denied
```
**Solutions:**
1. Verify `DOCKER_HUB_USERNAME` matches your Docker Hub username exactly
2. Regenerate `DOCKER_HUB_ACCESS_TOKEN` with proper permissions
3. Check token hasn't expired
4. Ensure token has Read, Write, Delete permissions

##### Image Push Failures
```
Error: failed to push image: denied: repository does not exist
```
**Solutions:**
1. Create repositories on Docker Hub first, or enable auto-creation
2. Verify image naming convention: `username/repository-name`
3. Check Docker Hub rate limits
4. Verify network connectivity from GitHub Actions

#### 3. SSH and VM Connection Issues

##### SSH Connection Failed
```
Permission denied (publickey)
```
**Detailed Solutions:**
1. **Verify SSH Key Format:**
   ```bash
   # Private key should start with:
   -----BEGIN OPENSSH PRIVATE KEY-----
   # or
   -----BEGIN RSA PRIVATE KEY-----
   ```

2. **Test SSH Connection Manually:**
   ```bash
   # From your local machine
   ssh -i ~/.ssh/your-key -v username@vm-host
   ```

3. **Check SSH Service on VM:**
   ```bash
   sudo systemctl status ssh
   sudo systemctl restart ssh
   ```

4. **Verify authorized_keys File:**
   ```bash
   # On VM
   ls -la ~/.ssh/
   cat ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   ```

##### SSH Connection Timeout
```
Error: ssh: connect to host timeout
```
**Solutions:**
1. Check VM is running and accessible
2. Verify firewall allows SSH (port 22)
3. Check security group rules (cloud providers)
4. Verify VM_HOST is correct (IP or hostname)

#### 4. Container and Application Issues

##### Container Startup Failed
```
Container exited with code 1
```
**Diagnostic Steps:**
1. **Check Container Logs:**
   ```bash
   docker logs notes-frontend --tail 50
   docker logs notes-backend --tail 50
   ```

2. **Verify Port Availability:**
   ```bash
   sudo netstat -tlnp | grep -E ':(3000|5000)'
   sudo lsof -i :3000
   sudo lsof -i :5000
   ```

3. **Check Docker Images:**
   ```bash
   docker images | grep notes
   docker inspect notes-frontend:latest
   ```

##### Port Already in Use
```
Error: bind: address already in use
```
**Solutions:**
1. **Stop Conflicting Processes:**
   ```bash
   sudo lsof -ti:3000 | xargs sudo kill -9
   sudo lsof -ti:5000 | xargs sudo kill -9
   ```

2. **Stop Old Containers:**
   ```bash
   docker stop $(docker ps -q)
   docker container prune -f
   ```

##### Health Checks Failed
```
Health check failed after 5 attempts
```
**Diagnostic Steps:**
1. **Test Application Endpoints:**
   ```bash
   curl -v http://localhost:3000
   curl -v http://localhost:5000/api/notes
   ```

2. **Check Application Logs:**
   ```bash
   docker logs notes-frontend --follow
   docker logs notes-backend --follow
   ```

3. **Verify Network Connectivity:**
   ```bash
   docker network ls
   docker network inspect bridge
   ```

#### 5. Deployment-Specific Issues

##### Docker Compose File Not Found
```
Error: no such file or directory: docker-compose.yml
```
**Solutions:**
1. Check file transfer completed successfully
2. Verify SSH user has proper permissions
3. Check working directory in deployment script

##### Image Pull Failures on VM
```
Error: pull access denied for image
```
**Solutions:**
1. **Login to Docker Hub on VM:**
   ```bash
   docker login
   # Enter Docker Hub credentials
   ```

2. **Check Image Names:**
   ```bash
   # Verify image names match Docker Hub repositories
   docker images
   ```

3. **Manual Image Pull Test:**
   ```bash
   docker pull your-username/notes-frontend:latest
   docker pull your-username/notes-backend:latest
   ```

### Advanced Debugging

#### Workflow Debug Mode
Enable debug logging in GitHub Actions:
1. Go to repository Settings → Secrets
2. Add secret: `ACTIONS_STEP_DEBUG` = `true`
3. Add secret: `ACTIONS_RUNNER_DEBUG` = `true`

#### VM System Diagnostics

```bash
# System resource usage
df -h                    # Disk space
free -h                  # Memory usage
top                      # CPU usage

# Docker system info
docker system df         # Docker disk usage
docker system info      # Docker system information

# Network diagnostics
ss -tlnp                 # Active network connections
iptables -L              # Firewall rules (if using iptables)

# System logs
sudo journalctl -u docker --since "1 hour ago"
sudo tail -f /var/log/syslog
```

#### Container Deep Dive

```bash
# Inspect container configuration
docker inspect notes-frontend
docker inspect notes-backend

# Execute commands inside containers
docker exec -it notes-frontend /bin/sh
docker exec -it notes-backend /bin/bash

# Check container resource usage
docker stats

# View container filesystem
docker exec notes-frontend ls -la /
docker exec notes-backend ls -la /app
```

### Emergency Recovery Procedures

#### Rollback to Previous Version
```bash
# Stop current containers
docker compose down

# Pull previous image tags
docker pull your-username/notes-frontend:previous
docker pull your-username/notes-backend:previous

# Update compose file to use previous tags
sed -i 's/:latest/:previous/g' docker-compose.yml

# Start with previous version
docker compose up -d
```

#### Complete Environment Reset
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Clean up system
docker system prune -af

# Re-run deployment
# (This will pull fresh images)
```

### Getting Help

#### Log Collection for Support
```bash
# Collect system information
echo "=== System Info ===" > debug-info.txt
uname -a >> debug-info.txt
docker --version >> debug-info.txt
docker compose version >> debug-info.txt

echo "=== Container Status ===" >> debug-info.txt
docker ps -a >> debug-info.txt

echo "=== Container Logs ===" >> debug-info.txt
docker logs notes-frontend >> debug-info.txt 2>&1
docker logs notes-backend >> debug-info.txt 2>&1

echo "=== System Resources ===" >> debug-info.txt
df -h >> debug-info.txt
free -h >> debug-info.txt
```

#### Useful Resources
- [GitHub Actions Troubleshooting](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)
- [Docker Troubleshooting](https://docs.docker.com/config/troubleshooting/)
- [SSH Troubleshooting Guide](https://www.ssh.com/academy/ssh/troubleshoot)

### Debug Commands Reference

Quick reference for debugging deployment issues:

```bash
# Container Management
docker ps -a                           # List all containers
docker logs <container-name>            # View container logs
docker exec -it <container> /bin/bash   # Access container shell
docker inspect <container>              # Detailed container info

# Network Debugging
netstat -tlnp | grep -E ':(3000|5000)' # Check port usage
curl -v http://localhost:3000           # Test frontend
curl -v http://localhost:5000/api/notes # Test backend API

# System Monitoring
htop                                    # System resource monitor
docker stats                           # Container resource usage
df -h                                   # Disk space
free -h                                 # Memory usage

# Docker System
docker system df                        # Docker disk usage
docker system prune                     # Clean up unused resources
docker images                           # List Docker images
docker network ls                       # List Docker networks
```

## Manual Deployment

For emergency deployments or testing, you can trigger the CD workflow manually:

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "CD - Continuous Deployment" workflow
4. Click "Run workflow"
5. Configure options:
   - **Environment**: production or staging
   - **Force deploy**: Check to bypass CI failure (emergency only)
   - **Skip health checks**: Check to skip health verification (emergency only)

## Workflow Monitoring and Maintenance

### Workflow Status Monitoring Procedures

#### 1. GitHub Actions Dashboard Monitoring

**Daily Monitoring Tasks:**
- Check Actions tab for failed workflows
- Review workflow run times for performance degradation
- Monitor artifact storage usage
- Verify scheduled workflows are running

**Monitoring Locations:**
- **Repository Actions Tab**: `https://github.com/your-username/your-repo/actions`
- **Workflow Status API**: Use GitHub API for automated monitoring
- **Commit Status Checks**: Green checkmarks on commits indicate successful pipelines

**Setting Up Automated Monitoring:**
```bash
# Example script to check workflow status via GitHub API
#!/bin/bash
REPO="your-username/your-repo"
TOKEN="your-github-token"

curl -H "Authorization: token $TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO/actions/runs?status=failure" \
     | jq '.workflow_runs[] | {id: .id, name: .name, status: .status, conclusion: .conclusion}'
```

#### 2. Application Health Monitoring

**Automated Health Checks:**
- Frontend availability: `http://your-vm-ip:3000`
- Backend API health: `http://your-vm-ip:5000/api/notes`
- Container status monitoring
- Resource usage tracking

**Health Check Script:**
```bash
#!/bin/bash
# health-check.sh - Run on VM or external monitoring system

FRONTEND_URL="http://localhost:3000"
BACKEND_URL="http://localhost:5000/api/notes"

# Check frontend
if curl -f -s $FRONTEND_URL > /dev/null; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend is down"
    # Send alert notification
fi

# Check backend
if curl -f -s $BACKEND_URL > /dev/null; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend is down"
    # Send alert notification
fi

# Check container status
if docker ps | grep -q "notes-frontend.*Up"; then
    echo "✅ Frontend container is running"
else
    echo "❌ Frontend container is not running"
fi

if docker ps | grep -q "notes-backend.*Up"; then
    echo "✅ Backend container is running"
else
    echo "❌ Backend container is not running"
fi
```

#### 3. Performance Monitoring

**Key Metrics to Track:**
- Workflow execution time trends
- Docker image build times
- Deployment duration
- Application response times
- Resource utilization (CPU, memory, disk)

**Performance Monitoring Setup:**
```bash
# Create monitoring script for VM resources
#!/bin/bash
# vm-metrics.sh

echo "=== $(date) ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo "Memory Usage:"
free -h | awk 'NR==2{printf "%.2f%%\n", $3*100/$2}'

echo "Disk Usage:"
df -h | awk '$NF=="/"{printf "%s\n", $5}'

echo "Container Stats:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo "---"
```

### Maintenance Checklists

#### Daily Maintenance (5 minutes)
- [ ] Check GitHub Actions dashboard for failed workflows
- [ ] Verify application is accessible (frontend and backend)
- [ ] Review any error notifications or alerts
- [ ] Check VM disk space if automated monitoring isn't set up

#### Weekly Maintenance (30 minutes)
- [ ] Review workflow execution logs for errors or warnings
- [ ] Check Docker Hub for image vulnerabilities
- [ ] Verify backup procedures are working
- [ ] Review VM system logs for security issues
- [ ] Update workflow dependencies if security patches available
- [ ] Check SSL certificate expiration (if using HTTPS)
- [ ] Review resource usage trends

**Weekly Maintenance Script:**
```bash
#!/bin/bash
# weekly-maintenance.sh

echo "=== Weekly Maintenance Report $(date) ==="

# Check disk space
echo "Disk Space:"
df -h

# Check Docker system usage
echo "Docker System Usage:"
docker system df

# Clean up old Docker resources
echo "Cleaning up Docker resources..."
docker system prune -f

# Check for security updates
echo "Security Updates:"
sudo apt list --upgradable | grep -i security

# Check container logs for errors
echo "Recent Container Errors:"
docker logs notes-frontend --since 168h 2>&1 | grep -i error | tail -10
docker logs notes-backend --since 168h 2>&1 | grep -i error | tail -10

echo "=== End Report ==="
```

#### Monthly Maintenance (2 hours)
- [ ] Update base Docker images and rebuild
- [ ] Review and rotate Docker Hub access tokens
- [ ] Update VM security patches and reboot if necessary
- [ ] Review GitHub Actions usage and costs
- [ ] Audit SSH access logs
- [ ] Update workflow Node.js versions if new LTS available
- [ ] Performance testing and optimization review
- [ ] Review and update firewall rules
- [ ] Backup configuration files and secrets documentation

#### Quarterly Maintenance (4 hours)
- [ ] Rotate SSH keys used for deployment
- [ ] Comprehensive security audit of the entire pipeline
- [ ] Review and update all documentation
- [ ] Performance benchmarking and optimization
- [ ] Disaster recovery testing
- [ ] Review and update monitoring and alerting systems
- [ ] Update GitHub Actions workflow versions
- [ ] Review Docker security best practices compliance

### Security Best Practices for Secrets and Access Management

#### 1. GitHub Secrets Management

**Secret Rotation Schedule:**
- **Docker Hub Access Tokens**: Every 6 months
- **SSH Keys**: Every 3 months
- **API Keys/Webhooks**: Every 6 months

**Secret Security Practices:**
```yaml
# Best practices for secret management
Secrets Management:
  - Use least privilege principle
  - Never log secret values
  - Rotate secrets regularly
  - Use environment-specific secrets
  - Monitor secret usage in audit logs
```

**Secret Audit Checklist:**
- [ ] All secrets have descriptive names
- [ ] No hardcoded secrets in workflow files
- [ ] Secrets are scoped to minimum required repositories
- [ ] Regular rotation schedule is followed
- [ ] Unused secrets are removed promptly

#### 2. SSH Key Security

**SSH Key Management:**
```bash
# Generate new SSH key for deployment
ssh-keygen -t ed25519 -C "github-actions-$(date +%Y%m%d)" -f ~/.ssh/github-actions-deploy

# Set proper permissions
chmod 600 ~/.ssh/github-actions-deploy
chmod 644 ~/.ssh/github-actions-deploy.pub

# Add to VM authorized_keys with restrictions
echo 'command="cd ~/app && docker compose up -d",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3...' >> ~/.ssh/authorized_keys
```

**SSH Security Checklist:**
- [ ] Use Ed25519 keys (preferred) or RSA 4096-bit minimum
- [ ] Implement command restrictions in authorized_keys
- [ ] Disable password authentication on VM
- [ ] Use fail2ban or similar for brute force protection
- [ ] Monitor SSH access logs regularly
- [ ] Rotate keys according to schedule

#### 3. Docker Hub Security

**Access Token Best Practices:**
- Create tokens with minimal required permissions
- Use separate tokens for different environments
- Set token expiration dates where possible
- Monitor token usage through Docker Hub audit logs

**Docker Security Checklist:**
- [ ] Use official base images only
- [ ] Regularly scan images for vulnerabilities
- [ ] Keep base images updated
- [ ] Use multi-stage builds to minimize attack surface
- [ ] Run containers as non-root users
- [ ] Implement image signing (Docker Content Trust)

#### 4. VM Security Hardening

**Security Configuration:**
```bash
# Disable password authentication
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 5000/tcp
sudo ufw enable

# Install and configure fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

**VM Security Checklist:**
- [ ] Automatic security updates enabled
- [ ] Firewall properly configured
- [ ] SSH hardened (key-only, no root login)
- [ ] Fail2ban or similar intrusion prevention active
- [ ] Regular security patches applied
- [ ] Minimal software installed (attack surface reduction)
- [ ] Log monitoring and alerting configured

### Alerting and Notification Setup

#### 1. GitHub Actions Notifications

**Email Notifications:**
- Configure in GitHub account settings
- Set up for workflow failures only to avoid spam

**Slack Integration:**
```yaml
# Add to workflow file for Slack notifications
- name: Notify Slack on Failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    channel: '#deployments'
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

#### 2. Application Monitoring Alerts

**Simple Monitoring with Cron:**
```bash
# Add to crontab: crontab -e
# Check every 5 minutes
*/5 * * * * /home/deploy/health-check.sh >> /var/log/health-check.log 2>&1

# Daily maintenance report
0 9 * * * /home/deploy/weekly-maintenance.sh | mail -s "Daily Maintenance Report" admin@yourcompany.com
```

### Disaster Recovery Procedures

#### 1. Backup Strategy

**What to Backup:**
- Application data (if any persistent data)
- Docker compose files
- Configuration files
- SSH keys (securely)
- Documentation

**Backup Script:**
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup compose files
cp docker-compose.yml $BACKUP_DIR/
cp docker-compose.prod.yml $BACKUP_DIR/ 2>/dev/null || true

# Backup application data (if volumes exist)
docker run --rm -v app_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/app-data.tar.gz -C /data .

# Backup logs
cp -r logs/ $BACKUP_DIR/ 2>/dev/null || true

echo "Backup completed: $BACKUP_DIR"
```

#### 2. Recovery Procedures

**Complete System Recovery:**
1. Provision new VM with same specifications
2. Install Docker and Docker Compose
3. Configure SSH access
4. Restore configuration files
5. Run deployment workflow
6. Verify application functionality

**Partial Recovery (Application Only):**
1. Stop current containers: `docker compose down`
2. Pull known-good images: `docker pull image:tag`
3. Start with previous version: `docker compose up -d`
4. Verify functionality

### Performance Optimization Monitoring

#### 1. Workflow Performance Metrics

**Key Performance Indicators:**
- CI workflow duration (target: < 10 minutes)
- CD workflow duration (target: < 15 minutes)
- Docker build time trends
- Deployment success rate (target: > 95%)

**Performance Monitoring Query:**
```bash
# GitHub API query for workflow performance
curl -H "Authorization: token $GITHUB_TOKEN" \
     "https://api.github.com/repos/$REPO/actions/runs?per_page=50" \
     | jq '.workflow_runs[] | {name: .name, duration: (.updated_at | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime) - (.created_at | strptime("%Y-%m-%dT%H:%M:%SZ") | mktime)}'
```

#### 2. Application Performance Monitoring

**Response Time Monitoring:**
```bash
# Simple response time check
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000

# curl-format.txt content:
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#    time_pretransfer:  %{time_pretransfer}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#                     ----------\n
#          time_total:  %{time_total}\n
```

This comprehensive monitoring and maintenance documentation ensures reliable operation of the CI/CD pipeline and provides clear procedures for ongoing management.

## Support

If you encounter issues not covered in this guide:

1. Check the GitHub Actions logs for detailed error messages
2. Review the VM logs (`/var/log/syslog`, `/var/log/auth.log`)
3. Verify all prerequisites are met
4. Test manual deployment steps on the VM
5. Check network connectivity and firewall settings

For additional help, refer to:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)