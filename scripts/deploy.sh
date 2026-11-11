#!/usr/bin/env bash
# Sobe a tag pedida num slot livre, só troca o NGINX se /health passar nos dois serviços.
set -euo pipefail

ROOT="${PILOTO_ROOT:-/opt/piloto-esteira}"
OWNER="${PILOTO_OWNER:-paulofranciscos}"
STATE="${ROOT}/state.env"
REQUESTED="${1:?informe a tag, o SHA ou previous}"
HEALTH_MODE="${2:-ok}"

if [[ "${HEALTH_MODE}" != "ok" && "${HEALTH_MODE}" != "fail" ]]; then
  echo "O segundo argumento é ok ou fail." >&2
  exit 1
fi

cd "${ROOT}"
mkdir -p "${ROOT}/nginx/upstreams"

CURRENT_SLOT=""
CURRENT_TAG=""
PREVIOUS_SLOT=""
PREVIOUS_TAG=""
if [[ -f "${STATE}" ]]; then
  # shellcheck disable=SC1090
  source "${STATE}"
fi

if [[ "${REQUESTED}" == "previous" ]]; then
  if [[ -z "${PREVIOUS_TAG}" ]]; then
    echo "Não há release anterior para reverter." >&2
    exit 1
  fi
  TAG="${PREVIOUS_TAG}"
else
  TAG="${REQUESTED}"
fi

if [[ ! "${TAG}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Tag recusada: ${TAG}" >&2
  exit 1
fi

free_slot() {
  local slot
  for slot in a b c; do
    if [[ "${slot}" != "${CURRENT_SLOT}" && "${slot}" != "${PREVIOUS_SLOT}" ]]; then
      printf '%s\n' "${slot}"
      return 0
    fi
  done
  return 1
}

SLOT="$(free_slot)"
WEB_IMAGE="ghcr.io/${OWNER}/piloto-esteira-web:${TAG}"
API_IMAGE="ghcr.io/${OWNER}/piloto-esteira-api:${TAG}"
PROJECT="piloto-${SLOT}"

echo "Candidato ${TAG} no slot ${SLOT}. Tráfego atual: ${CURRENT_TAG:-nenhum}."

export WEB_IMAGE API_IMAGE HEALTH_MODE
export APP_VERSION="${TAG}"
export GIT_SHA="${TAG}"

docker compose -p "${PROJECT}" -f "${ROOT}/compose.yaml" pull
docker compose -p "${PROJECT}" -f "${ROOT}/compose.yaml" up -d --force-recreate
docker pull curlimages/curl:8.11.1 >/dev/null

healthy=0
for _ in $(seq 1 30); do
  if docker run --rm --network piloto curlimages/curl:8.11.1 -fsS "http://${PROJECT}-web-1:8080/health" >/dev/null \
    && docker run --rm --network piloto curlimages/curl:8.11.1 -fsS "http://${PROJECT}-api-1:8080/health" >/dev/null; then
    healthy=1
    break
  fi
  sleep 1
done

if [[ "${healthy}" -ne 1 ]]; then
  echo "Healthcheck falhou em ${TAG}. O NGINX continua em ${CURRENT_TAG:-nenhum}."
  docker compose -p "${PROJECT}" -f "${ROOT}/compose.yaml" down
  exit 1
fi

printf 'server %s-web-1:8080;\n' "${PROJECT}" > "${ROOT}/nginx/upstreams/web.conf"
printf 'server %s-api-1:8080;\n' "${PROJECT}" > "${ROOT}/nginx/upstreams/api.conf"
docker exec piloto-nginx nginx -s reload

OLD_PREVIOUS_SLOT="${PREVIOUS_SLOT}"
PREVIOUS_SLOT="${CURRENT_SLOT}"
PREVIOUS_TAG="${CURRENT_TAG}"
CURRENT_SLOT="${SLOT}"
CURRENT_TAG="${TAG}"

cat > "${STATE}" <<EOF
CURRENT_SLOT=${CURRENT_SLOT}
CURRENT_TAG=${CURRENT_TAG}
PREVIOUS_SLOT=${PREVIOUS_SLOT}
PREVIOUS_TAG=${PREVIOUS_TAG}
EOF

if [[ -n "${OLD_PREVIOUS_SLOT}" && "${OLD_PREVIOUS_SLOT}" != "${CURRENT_SLOT}" && "${OLD_PREVIOUS_SLOT}" != "${PREVIOUS_SLOT}" ]]; then
  docker compose -p "piloto-${OLD_PREVIOUS_SLOT}" -f "${ROOT}/compose.yaml" down
fi

echo "Tráfego em ${CURRENT_TAG}. Anterior: ${PREVIOUS_TAG:-nenhum}."
