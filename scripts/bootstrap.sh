#!/usr/bin/env bash
# Prepara Docker, a rede e o NGINX. Pode rodar de novo sem derrubar uma release boa.
set -euo pipefail

ROOT="${PILOTO_ROOT:-/opt/piloto-esteira}"
HTTP_PORT="${PILOTO_HTTP_PORT:-80}"

if ! command -v docker >/dev/null 2>&1; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Docker não está instalado e não há sudo para instalar." >&2
    exit 1
  fi
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "${USER}" || true
fi

if ! docker info >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1 && sudo docker info >/dev/null 2>&1; then
    echo "O usuário ${USER} ainda não usa o grupo docker nesta sessão. Rode o deploy com sudo ou entre de novo." >&2
    exit 1
  fi
  echo "O Docker não respondeu." >&2
  exit 1
fi

mkdir -p "${ROOT}/nginx/upstreams" "${ROOT}/scripts"
docker network create piloto >/dev/null 2>&1 || true

if [[ ! -f "${ROOT}/nginx/upstreams/web.conf" ]]; then
  printf 'server 127.0.0.1:9;\n' > "${ROOT}/nginx/upstreams/web.conf"
fi
if [[ ! -f "${ROOT}/nginx/upstreams/api.conf" ]]; then
  printf 'server 127.0.0.1:9;\n' > "${ROOT}/nginx/upstreams/api.conf"
fi

if docker ps -a --format '{{.Names}}' | grep -qx piloto-nginx; then
  docker start piloto-nginx >/dev/null
else
  docker run -d \
    --name piloto-nginx \
    --network piloto \
    -p "${HTTP_PORT}:80" \
    --restart unless-stopped \
    -v "${ROOT}/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
    -v "${ROOT}/nginx/upstreams:/etc/nginx/upstreams:ro" \
    nginx:1.27-alpine >/dev/null
fi

echo "NGINX no ar. A publicação entra pelo porto ${HTTP_PORT}."
