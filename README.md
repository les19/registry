# Self-Hosted Docker Registry with Caddy

A production-ready, self-hosted Docker registry with automatic HTTPS using Caddy server.

## Features

- 🔒 **Secure HTTPS** - Automatic SSL certificates via Let's Encrypt (Caddy)
- 🔐 **Authentication** - HTTP Basic Auth using htpasswd
- 🚀 **Production Ready** - Health checks, logging, resource limits
- 📦 **Docker Compose** - Easy deployment and management
- 🔄 **CI/CD Ready** - GitHub Actions workflow for automated deployments (no .env on server!)
- 📊 **Monitoring** - Health checks and structured JSON logging
- 🛡️ **Security Headers** - HSTS, XSS protection, and more
- ⚡ **HTTP/3** - Modern protocol support via QUIC

## Project Structure

```
.
├── compose.yml                    # Docker Compose configuration
├── Caddyfile                      # Caddy reverse proxy config
├── .env.example                   # Environment variables template (local development)
├── .gitignore                     # Git ignore rules
├── Makefile                       # Make commands for easy management
├── setup.sh                       # Interactive setup script
├── README.md                      # Main documentation
├── GITHUB_SECRETS.md             # GitHub Actions secrets guide
├── .github/
│   └── workflows/
│       └── deploy.yml             # CI/CD deployment workflow
├── registry/                      # Registry data (created during setup)
│   └── .gitkeep
└── scripts/                       # Helper scripts
    ├── backup.sh                  # Backup registry data
    ├── gc.sh                      # Garbage collection
    ├── generate-secrets.sh        # Generate GitHub secrets
    ├── logs.sh                    # View logs
    └── status.sh                  # Check status
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2+
- A domain name pointing to your server
- Ports 80 and 443 open on your firewall

## Quick Start

> **Note:** This project supports two deployment modes:
> - **Local/Manual Deployment**: Uses `.env` file (see below)
> - **Production CI/CD**: Uses GitHub Secrets (see [Production Deployment](#production-deployment))

### 1. Initial Setup

Run the setup script to configure your registry:

```bash
./setup.sh
```

This script will:
- Create a `.env` file with your configuration
- Generate authentication credentials
- Set up the registry directory structure

### 2. Start the Registry

```bash
docker compose up -d
```

### 3. Verify the Registry

```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f

# Test the registry endpoint
curl https://your-registry-domain.com/v2/
```

### 4. Login to Your Registry

```bash
docker login your-registry-domain.com
```

Enter the username and password you created during setup.

## Configuration

### Environment Variables

Key configuration options in `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `REGISTRY_DOMAIN` | Your registry domain | registry.example.com |
| `ACME_EMAIL` | Email for Let's Encrypt | admin@example.com |
| `REGISTRY_HTTP_SECRET` | Random secret for registry | (generated) |
| `REGISTRY_STORAGE_DELETE_ENABLED` | Allow image deletion | true |
| `REGISTRY_LOG_LEVEL` | Log level (error/warn/info/debug) | info |

See `.env.example` for all available options.

### Registry Authentication

Authentication is handled via htpasswd. To add/update users:

```bash
# Add a new user
htpasswd -Bb registry/registry.password newuser newpassword

# Update existing user password
htpasswd -Bb registry/registry.password existinguser newpassword

# Remove a user
htpasswd -D registry/registry.password username
```

After updating authentication, restart the registry:

```bash
docker compose restart registry
```

## Usage

### Pushing Images

```bash
# Tag your image
docker tag myimage:latest your-registry-domain.com/myimage:latest

# Push to registry
docker push your-registry-domain.com/myimage:latest
```

### Pulling Images

```bash
docker pull your-registry-domain.com/myimage:latest
```

### Listing Images

```bash
# List all repositories
curl -u username:password https://your-registry-domain.com/v2/_catalog

# List tags for a repository
curl -u username:password https://your-registry-domain.com/v2/myimage/tags/list
```

## Maintenance

### View Logs

```bash
# All services
./scripts/logs.sh

# Specific service
./scripts/logs.sh registry
./scripts/logs.sh caddy
```

### Check Status

```bash
./scripts/status.sh
```

### Backup

```bash
# Create a backup
./scripts/backup.sh

# Backup to specific directory
./scripts/backup.sh /path/to/backup
```

### Garbage Collection

Remove unreferenced layers to free up disk space:

```bash
./scripts/gc.sh
```

**Note:** The registry will be briefly unavailable during garbage collection.

### Delete Images

To delete an image, you need to:

1. Ensure `REGISTRY_STORAGE_DELETE_ENABLED=true` in `.env`
2. Delete the manifest:

```bash
# Get the digest
curl -I -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  -u username:password \
  https://your-registry-domain.com/v2/myimage/manifests/latest

# Delete using the digest from Docker-Content-Digest header
curl -X DELETE -u username:password \
  https://your-registry-domain.com/v2/myimage/manifests/sha256:...
```

3. Run garbage collection to actually free disk space:

```bash
./scripts/gc.sh
```

## Production Deployment

### GitHub Actions

The repository includes a GitHub Actions workflow for automated deployments.

**📖 For detailed setup instructions, see [GITHUB_SECRETS.md](GITHUB_SECRETS.md)**

**🔧 Quick secret generation:**
```bash
./scripts/generate-secrets.sh
```

#### Required Secrets

Configure these secrets in your GitHub repository (Settings → Secrets → Actions):

**SSH Connection:**
| Secret | Description | Example |
|--------|-------------|---------|
| `HOST` | Your server IP or hostname | 192.168.1.100 |
| `USERNAME` | SSH username | deploy |
| `PASSWORD` | SSH password (or use key-based auth) | your-password |
| `PORT` | SSH port | 22 |
| `DEPLOY_PATH` | Deployment directory | /opt/docker-registry |

**Registry Configuration:**
| Secret | Description | Example | Required |
|--------|-------------|---------|----------|
| `REGISTRY_DOMAIN` | Your registry domain | registry.example.com | ✅ Yes |
| `ACME_EMAIL` | Email for Let's Encrypt | admin@example.com | ✅ Yes |
| `REGISTRY_HTTP_SECRET` | Random secret (use `openssl rand -hex 32`) | abc123... | ✅ Yes |
| `REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY` | Storage directory | /data | No (default: /data) |
| `REGISTRY_STORAGE_DELETE_ENABLED` | Allow image deletion | true | No (default: true) |
| `REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR` | Cache type | inmemory | No (default: inmemory) |
| `REGISTRY_LOG_LEVEL` | Log level | info | No (default: info) |
| `REGISTRY_HTTP_MAXCONCURRENTUPLOADS` | Max concurrent uploads | 5 | No (default: 5) |
| `REGISTRY_HTTP_TIMEOUT_READ` | Read timeout | 5m | No (default: 5m) |
| `REGISTRY_HTTP_TIMEOUT_WRITE` | Write timeout | 10m | No (default: 10m) |
| `REGISTRY_HEALTH_STORAGEDRIVER_ENABLED` | Enable health checks | true | No (default: true) |
| `REGISTRY_HEALTH_STORAGEDRIVER_INTERVAL` | Health check interval | 10s | No (default: 10s) |
| `REGISTRY_HEALTH_STORAGEDRIVER_THRESHOLD` | Health check threshold | 3 | No (default: 3) |

**Note:** All configuration is stored as GitHub secrets. No `.env` file is created on the server.

#### Deployment Process

1. Push to `main` branch or manually trigger the workflow
2. The workflow will:
   - Checkout the code from GitHub
   - Backup existing registry password on server
   - Copy all necessary files to your server via SCP
   - Export environment variables from GitHub secrets
   - Update Docker images
   - Restart services with zero-downtime
   - Verify health of services

### Manual Deployment

On your server:

```bash
# Clone the repository
git clone your-repo-url /opt/docker-registry
cd /opt/docker-registry

# Run setup
./setup.sh

# Start services
docker compose up -d

# Check status
docker compose ps
```

## Monitoring

### Health Checks

Both services include health checks:

```bash
# Check registry health (will return 401 if auth is enabled - this is normal)
curl http://localhost:5000/v2/

# With authentication
curl -u username:password http://localhost:5000/v2/

# Check Caddy health
curl http://localhost:2019/metrics
```

**Note:** The registry healthcheck accepts both `200 OK` and `401 Unauthorized` as healthy states, since `401` indicates the service is running and responding correctly (just requiring authentication).

### Logs

Logs are in JSON format for easy parsing:

```bash
# View structured logs
docker compose logs registry | jq

# Filter by log level
docker compose logs registry | jq 'select(.level=="error")'
```

### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df -v
```

## Security Best Practices

1. **Use Strong Passwords**: Generate strong passwords for registry authentication
2. **Keep Updated**: Regularly update Docker images
3. **Firewall**: Only expose ports 80 and 443
4. **Backups**: Regular backups of registry data
5. **Monitoring**: Set up alerts for failed health checks
6. **HTTPS Only**: Never disable HTTPS in production
7. **Resource Limits**: Configure appropriate CPU/memory limits

## Troubleshooting

### Cannot Connect to Registry

1. Check if containers are running: `docker compose ps`
2. Check logs: `docker compose logs`
3. Verify DNS points to your server
4. Check firewall allows ports 80/443

### Authentication Fails

1. Verify credentials in `registry/registry.password`
2. Restart registry after updating passwords
3. Check for special characters that need escaping

### Out of Disk Space

1. Run garbage collection: `./scripts/gc.sh`
2. Check disk usage: `docker system df`
3. Clean up old images: `docker image prune -a`

### SSL Certificate Issues

1. Verify domain DNS is correct
2. Check Caddy logs: `docker compose logs caddy`
3. Ensure ports 80/443 are accessible
4. Verify email in `.env` is correct

### Push/Pull Timeouts

1. Increase timeouts in `.env`:
   ```
   REGISTRY_HTTP_TIMEOUT_READ=10m
   REGISTRY_HTTP_TIMEOUT_WRITE=15m
   ```
2. Restart services: `docker compose restart`

## Architecture

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │ HTTPS (443)
       │ HTTP (80→443)
       ▼
┌─────────────────┐
│  Caddy Server   │
│  - SSL/TLS      │
│  - Reverse Proxy│
└────────┬────────┘
         │
         │ HTTP (5000)
         ▼
┌─────────────────┐
│ Docker Registry │
│  - Authentication│
│  - Storage      │
└─────────────────┘
```

## Performance Tuning

### Registry

- **Max Concurrent Uploads**: Adjust `REGISTRY_HTTP_MAXCONCURRENTUPLOADS`
- **Cache**: Uses in-memory blob descriptor cache
- **Storage**: Local filesystem (can be changed to S3, Azure, etc.)

### Caddy

- **HTTP/3**: Enabled by default for better performance
- **Compression**: Gzip enabled
- **Resource Limits**: Adjust in `compose.yml`

## Advanced Configuration

### Using S3 Storage Backend

Edit `compose.yml` to add S3 configuration:

```yaml
REGISTRY_STORAGE: s3
REGISTRY_STORAGE_S3_ACCESSKEY: your-access-key
REGISTRY_STORAGE_S3_SECRETKEY: your-secret-key
REGISTRY_STORAGE_S3_REGION: us-east-1
REGISTRY_STORAGE_S3_BUCKET: your-bucket
```

### Custom Registry Configuration

For advanced configuration, you can mount a custom config file:

1. Create `config.yml` with your custom configuration
2. Mount it in `compose.yml`:
   ```yaml
   volumes:
     - ./config.yml:/etc/docker/registry/config.yml:ro
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Support

For issues and questions:
- Check the [Docker Registry documentation](https://docs.docker.com/registry/)
- Check the [Caddy documentation](https://caddyserver.com/docs/)
- Open an issue in this repository

## Acknowledgments

- [Docker Registry](https://github.com/distribution/distribution)
- [Caddy Server](https://github.com/caddyserver/caddy)
