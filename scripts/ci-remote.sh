#!/usr/bin/env bash
# Roda no GitHub Actions. Copia o modelo e publica ou reverte no VPS.
set -euo pipefail

: "${VPS_HOST:?VPS_HOST ausente}"
: "${VPS_USER:?VPS_USER ausente}"
: "${VPS_SSH_KEY:?VPS_SSH_KEY ausente}"
TAG="${1:?tag}"
HEALTH="${2:-ok}"
if [[ ! "${TAG}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Tag recusada: ${TAG}" >&2
  exit 1
fi
if [[ "${HEALTH}" != "ok" && "${HEALTH}" != "fail" ]]; then
  echo "Health recusado: ${HEALTH}" >&2
  exit 1
fi
PORT="${VPS_PORT:-22}"
OWNER="${PILOTO_OWNER:-paulofranciscos}"

install -d -m 700 "${HOME}/.ssh"
printf '%s\n' "${VPS_SSH_KEY}" > "${HOME}/.ssh/piloto"
chmod 600 "${HOME}/.ssh/piloto"
ssh-keyscan -p "${PORT}" -H "${VPS_HOST}" >> "${HOME}/.ssh/known_hosts"

SSH=(ssh -i "${HOME}/.ssh/piloto" -p "${PORT}" -o StrictHostKeyChecking=yes)
SCP=(scp -i "${HOME}/.ssh/piloto" -P "${PORT}" -o StrictHostKeyChecking=yes)
TARGET="${VPS_USER}@${VPS_HOST}"

"${SSH[@]}" "${TARGET}" "mkdir -p /opt/piloto-esteira"
"${SCP[@]}" -r compose.yaml nginx scripts "${TARGET}:/opt/piloto-esteira/"
"${SSH[@]}" "${TARGET}" "chmod +x /opt/piloto-esteira/scripts/*.sh && PILOTO_OWNER='${OWNER}' bash /opt/piloto-esteira/scripts/bootstrap.sh && PILOTO_OWNER='${OWNER}' bash /opt/piloto-esteira/scripts/deploy.sh '${TAG}' '${HEALTH}'"
