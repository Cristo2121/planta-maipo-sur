#!/usr/bin/env bash
# scripts/instalar.sh - instala una herramienta de seguridad con versión FIJA
# y verifica su huella SHA-256 antes de usarla (si no coincide, se detiene).
#
# Por qué: el caso tj-actions (2025) y la versión comprometida de Trivy (2026)
# mostraron que una etiqueta de versión puede ser reescrita. Un SHA-256 no.
#
# Uso:  bash scripts/instalar.sh gitleaks | trivy | osv-scanner | semgrep
# Destino: $RUNNER_TEMP/herramientas  (o /tmp/herramientas fuera de Actions)
set -euo pipefail

# ---- VERSIONES Y HUELLAS (actualizar juntas, verificando en la página oficial) ----
GITLEAKS_VERSION="8.30.1"
GITLEAKS_SHA256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"
TRIVY_VERSION="0.75.0"   # NUNCA usar v0.69.4 (comprometida el 19-03-2026)
TRIVY_SHA256="c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f"
OSV_VERSION="2.6.0"
OSV_SHA256="ca69b3d3cd08f889a49dc0a383122f71cc528b83803671df5fd874d97485b108"
SEMGREP_VERSION="1.180.0"
# -----------------------------------------------------------------------------------

DESTINO="${RUNNER_TEMP:-/tmp}/herramientas"
mkdir -p "$DESTINO"

descargar() {  # url  sha256  archivo
  curl -sSfL --retry 3 -o "$DESTINO/$3" "$1"
  echo "$2  $DESTINO/$3" | sha256sum -c -
}

case "${1:-}" in
  gitleaks)
    descargar "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" "$GITLEAKS_SHA256" gitleaks.tar.gz
    tar -xzf "$DESTINO/gitleaks.tar.gz" -C "$DESTINO" gitleaks
    ;;
  trivy)
    descargar "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" "$TRIVY_SHA256" trivy.tar.gz
    tar -xzf "$DESTINO/trivy.tar.gz" -C "$DESTINO" trivy
    ;;
  osv-scanner)
    descargar "https://github.com/google/osv-scanner/releases/download/v${OSV_VERSION}/osv-scanner_linux_amd64" "$OSV_SHA256" osv-scanner
    chmod +x "$DESTINO/osv-scanner"
    ;;
  semgrep)
    python3 -m venv "$DESTINO/semgrep-venv"
    "$DESTINO/semgrep-venv/bin/pip" install --quiet "semgrep==${SEMGREP_VERSION}"
    ln -sf "$DESTINO/semgrep-venv/bin/semgrep" "$DESTINO/semgrep"
    ;;
  *)
    echo "Uso: bash scripts/instalar.sh gitleaks | trivy | osv-scanner | semgrep" >&2
    exit 2
    ;;
esac
echo "Instalado: $1"
