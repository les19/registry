# GitHub Secrets Configuration

This document explains how to configure GitHub secrets for automated deployment.

## Setting Up GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

## Required Secrets

### 1. SSH Connection Secrets

These secrets are needed to connect to your server:

```bash
HOST=your-server-ip-or-hostname
USERNAME=your-ssh-username
PASSWORD=your-ssh-password
PORT=22
DEPLOY_PATH=/opt/docker-registry
```

### 2. Registry Configuration Secrets

#### Required Secrets

These **must** be configured:

```bash
# Your domain name
REGISTRY_DOMAIN=registry.example.com

# Email for Let's Encrypt SSL certificates
ACME_EMAIL=admin@example.com

# Generate a random secret (run this command):
# openssl rand -hex 32
REGISTRY_HTTP_SECRET=<paste-output-of-openssl-command>
```

#### Optional Secrets

These have default values and only need to be set if you want to override them:

```bash
# Storage configuration
REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
REGISTRY_STORAGE_DELETE_ENABLED=true
REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=inmemory

# Logging
REGISTRY_LOG_LEVEL=info

# Performance
REGISTRY_HTTP_MAXCONCURRENTUPLOADS=5
REGISTRY_HTTP_TIMEOUT_READ=5m
REGISTRY_HTTP_TIMEOUT_WRITE=10m

# Health checks
REGISTRY_HEALTH_STORAGEDRIVER_ENABLED=true
REGISTRY_HEALTH_STORAGEDRIVER_INTERVAL=10s
REGISTRY_HEALTH_STORAGEDRIVER_THRESHOLD=3
```

## Quick Setup Script

You can use this script to generate the values you need:

```bash
#!/bin/bash

echo "=== Docker Registry GitHub Secrets Configuration ==="
echo ""
echo "Copy these values to your GitHub repository secrets:"
echo ""

echo "# Required SSH Configuration"
echo "HOST=your-server-ip"
echo "USERNAME=your-ssh-username"
echo "PASSWORD=your-ssh-password"
echo "PORT=22"
echo "DEPLOY_PATH=/opt/docker-registry"
echo ""

echo "# Required Registry Configuration"
read -p "Enter your registry domain (e.g., registry.example.com): " DOMAIN
echo "REGISTRY_DOMAIN=$DOMAIN"

read -p "Enter your email for Let's Encrypt: " EMAIL
echo "ACME_EMAIL=$EMAIL"

SECRET=$(openssl rand -hex 32)
echo "REGISTRY_HTTP_SECRET=$SECRET"
echo ""

echo "# Optional (you can skip these to use defaults)"
echo "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data"
echo "REGISTRY_STORAGE_DELETE_ENABLED=true"
echo "REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=inmemory"
echo "REGISTRY_LOG_LEVEL=info"
echo "REGISTRY_HTTP_MAXCONCURRENTUPLOADS=5"
echo "REGISTRY_HTTP_TIMEOUT_READ=5m"
echo "REGISTRY_HTTP_TIMEOUT_WRITE=10m"
echo "REGISTRY_HEALTH_STORAGEDRIVER_ENABLED=true"
echo "REGISTRY_HEALTH_STORAGEDRIVER_INTERVAL=10s"
echo "REGISTRY_HEALTH_STORAGEDRIVER_THRESHOLD=3"
```

Save this as `generate-secrets.sh` and run it to get your configuration values.

## Creating Registry Authentication

Before the first deployment, you need to create the registry password file on your server:

```bash
# SSH to your server
ssh your-username@your-server

# Go to deployment directory
cd /opt/docker-registry

# Create registry directory
mkdir -p registry

# Create password file (replace 'username' and 'password')
htpasswd -Bbn username password > registry/registry.password

# If htpasswd is not installed:
# Ubuntu/Debian:
sudo apt-get install apache2-utils

# RHEL/CentOS:
sudo yum install httpd-tools
```

## Verifying Configuration

After setting up all secrets, you can:

1. Go to **Actions** tab in your GitHub repository
2. Click on **Deploy Registry** workflow
3. Click **Run workflow** → **Run workflow** button
4. Watch the deployment logs to verify everything works

## Security Best Practices

1. **Use Strong Passwords**: Generate complex passwords for SSH and registry
2. **Consider SSH Keys**: Instead of password, use SSH key-based authentication
3. **Rotate Secrets**: Periodically update your secrets, especially `REGISTRY_HTTP_SECRET`
4. **Limit Access**: Only give necessary people access to repository secrets
5. **Use Environment Protection**: Configure GitHub environment protection rules for production

## Troubleshooting

### Deployment Fails with "registry.password not found"

Create the file on your server first:
```bash
ssh your-username@your-server
mkdir -p /opt/docker-registry/registry
htpasswd -Bbn myuser mypassword > /opt/docker-registry/registry/registry.password
```

### Invalid Secret Values

Make sure:
- Secrets don't have quotes around them
- No extra spaces before/after values
- Domain names are lowercase
- Timeouts include units (5m, 10s, etc.)

### SSL Certificate Issues

Verify:
- `REGISTRY_DOMAIN` points to your server's IP
- Ports 80 and 443 are open
- `ACME_EMAIL` is a valid email address
