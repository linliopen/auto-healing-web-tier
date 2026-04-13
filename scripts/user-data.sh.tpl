#!/bin/bash
set -euxo pipefail

# ---------------------------------------------------------------------------
# user-data script — runs as root on first boot (Amazon Linux 2023)
# Installs Docker, pulls the container image, and starts the web server.
# ---------------------------------------------------------------------------

# Log all output for debugging
exec > >(tee /var/log/user-data.log) 2>&1

# 1. Install Docker
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker

# 2. Pull and run the containerised NGINX welcome page
docker pull ${container_image}


# 3. dockerbuild
mkdir -p /var/www/html
echo "Hello nginx" >> /var/www/html/index.html


# 4. Create a simple health endpoint (in case the container doesn't have one)
echo '{"status":"healthy","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > /var/www/html/health

# 5. docker run
docker run -d \
  --name web-server \
  --restart unless-stopped \
  -p ${container_port}:${container_port} \
  -v /var/www/html:/usr/share/nginx/html:ro \
  ${container_image}


# Install a minimal HTTP server for the health endpoint
dnf install -y python3
nohup python3 -m http.server 8080 --directory /var/www/html &>/dev/null &

echo "user-data script completed successfully"
