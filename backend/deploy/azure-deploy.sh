#!/usr/bin/env bash
# =====================================================================
# La Salle Foods — despliegue del backend Java + MySQL en Azure.
#
# Crea (o reutiliza) toda la infraestructura:
#   - Resource Group
#   - Azure Container Registry (ACR) + build de la imagen en la nube
#   - Azure Database for MySQL Flexible Server + base + esquema
#   - Container Apps Environment + Container App (ingress público :8080)
#
# Requisitos: az CLI con sesión iniciada (az login) y la suscripción correcta
# seleccionada (az account set -s <id>).
#
# Uso:
#   cd backend
#   # 1) edita las variables de abajo (sobre todo MYSQL_ADMIN_PASSWORD y JWT_SECRET)
#   # 2) ejecuta:
#   bash deploy/azure-deploy.sh
# =====================================================================
set -euo pipefail

# --------- Variables a revisar ---------
LOCATION="westus2"
RG="lasallefoods-rg"
ACR_NAME="lasallefoods$RANDOM"          # debe ser único global; ajusta si quieres uno fijo
IMAGE="lasallefoods-backend:latest"
ENV_NAME="lasallefoods-env"
APP_NAME="lasallefoods-backend"

MYSQL_SERVER="lasallefoods-db-$RANDOM"   # debe ser único global
MYSQL_ADMIN="lsfadmin"
# Los secretos se pueden pasar por variable de entorno para no dejarlos en el repo:
#   MYSQL_ADMIN_PASSWORD='...' JWT_SECRET='...' bash deploy/azure-deploy.sh
MYSQL_ADMIN_PASSWORD="${MYSQL_ADMIN_PASSWORD:-CAMBIA_ESTA_PASSWORD_Segura123!}"   # <-- CAMBIAR
MYSQL_DB="lasallefoods"

JWT_SECRET="${JWT_SECRET:-CAMBIA_ESTE_SECRETO_largo_y_aleatorio_0123456789abcdef}"  # <-- CAMBIAR
# ---------------------------------------

echo "==> Registrando proveedores (puede tardar unos minutos)…"
az provider register -n Microsoft.App --wait
az provider register -n Microsoft.ContainerRegistry --wait
az provider register -n Microsoft.DBforMySQL --wait
az provider register -n Microsoft.OperationalInsights --wait

echo "==> Resource group…"
az group create -n "$RG" -l "$LOCATION" -o none

echo "==> Azure Container Registry…"
az acr create -n "$ACR_NAME" -g "$RG" --sku Basic --admin-enabled true -o none
echo "==> Build de la imagen en ACR (usa el Dockerfile, no requiere Docker local)…"
az acr build -r "$ACR_NAME" -t "$IMAGE" . 

ACR_SERVER=$(az acr show -n "$ACR_NAME" -g "$RG" --query loginServer -o tsv)
ACR_USER=$(az acr credential show -n "$ACR_NAME" --query username -o tsv)
ACR_PASS=$(az acr credential show -n "$ACR_NAME" --query "passwords[0].value" -o tsv)

echo "==> MySQL Flexible Server (Burstable B1ms)…"
az mysql flexible-server create \
  --name "$MYSQL_SERVER" --resource-group "$RG" --location "$LOCATION" \
  --admin-user "$MYSQL_ADMIN" --admin-password "$MYSQL_ADMIN_PASSWORD" \
  --sku-name Standard_B1ms --tier Burstable --version 8.0.21 \
  --storage-size 20 --public-access 0.0.0.0 --yes -o none

echo "==> Desactivando require_secure_transport (simplifica la conexión JDBC en demo)…"
az mysql flexible-server parameter set \
  --resource-group "$RG" --server-name "$MYSQL_SERVER" \
  --name require_secure_transport --value OFF -o none

echo "==> Aplicando esquema…"
az extension add -n rdbms-connect --yes 2>/dev/null || true
az mysql flexible-server execute \
  --name "$MYSQL_SERVER" --admin-user "$MYSQL_ADMIN" --admin-password "$MYSQL_ADMIN_PASSWORD" \
  --file-path "db/schema.sql"

MYSQL_FQDN=$(az mysql flexible-server show -n "$MYSQL_SERVER" -g "$RG" --query fullyQualifiedDomainName -o tsv)
DB_URL="jdbc:mysql://${MYSQL_FQDN}:3306/${MYSQL_DB}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=utf8"

echo "==> Container Apps environment…"
az containerapp env create -n "$ENV_NAME" -g "$RG" -l "$LOCATION" -o none

echo "==> Container App…"
az containerapp create \
  --name "$APP_NAME" --resource-group "$RG" --environment "$ENV_NAME" \
  --image "${ACR_SERVER}/${IMAGE}" \
  --registry-server "$ACR_SERVER" --registry-username "$ACR_USER" --registry-password "$ACR_PASS" \
  --target-port 8080 --ingress external --min-replicas 1 --max-replicas 2 \
  --env-vars "DB_URL=$DB_URL" "DB_USER=$MYSQL_ADMIN" "DB_PASSWORD=$MYSQL_ADMIN_PASSWORD" "JWT_SECRET=$JWT_SECRET" "SEED_ON_STARTUP=true" \
  -o none

FQDN=$(az containerapp show -n "$APP_NAME" -g "$RG" --query properties.configuration.ingress.fqdn -o tsv)
echo "============================================================"
echo "  Backend desplegado: https://${FQDN}/api"
echo "  Health:             https://${FQDN}/api/health"
echo ""
echo "  En la app SwiftUI define API_BASE_URL=https://${FQDN}/api"
echo "  (o actualiza el valor por defecto en APIClient.swift)."
echo "============================================================"
