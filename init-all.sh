#!/bin/bash
# Script que automatiza TODO: crea BD y tablas en Floci

set -e

# Variables
DB_INSTANCE_ID="mydb"
DB_NAME="myappdb"
MASTER_USERNAME="admin"
MASTER_PASSWORD="password123"
AWS_REGION="us-east-1"
FLOCI_ENDPOINT="http://localhost:4566"
MAX_RETRIES=30
RETRY_DELAY=2

# Configurar AWS CLI para Floci
export AWS_ENDPOINT_URL=$FLOCI_ENDPOINT
export AWS_DEFAULT_REGION=$AWS_REGION
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo "============================================"
echo "Inicializando Floci + MySQL..."
echo "============================================"

# 1. ESPERAR A QUE FLOCI ESTÉ LISTO
echo ""
echo "[1/3] Esperando a que Floci esté disponible..."
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -s $FLOCI_ENDPOINT/health >/dev/null 2>&1 || \
     aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✓ Floci está listo"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "  Intento $RETRY_COUNT/$MAX_RETRIES... esperando $RETRY_DELAY segundos"
  sleep $RETRY_DELAY
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "✗ Floci no respondió después de $(($MAX_RETRIES * $RETRY_DELAY)) segundos"
  exit 1
fi

# 2. CREAR LA BD
echo ""
echo "[2/3] Creando instancia RDS MySQL..."

# Verificar si ya existe
if aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID >/dev/null 2>&1; then
  echo "✓ Instancia $DB_INSTANCE_ID ya existe"
else
  aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username $MASTER_USERNAME \
    --master-user-password $MASTER_PASSWORD \
    --allocated-storage 20 \
    --db-name $DB_NAME \
    >/dev/null 2>&1
  echo "✓ Instancia creada"
fi

sleep 3

# 3. CONECTAR E INICIALIZAR TABLAS
echo ""
echo "[3/3] Inicializando tablas..."

# Esperar a que MySQL esté listo
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if mysql -h localhost \
    -u $MASTER_USERNAME \
    -p$MASTER_PASSWORD \
    $DB_NAME -e "SELECT 1" >/dev/null 2>&1; then
    echo "✓ MySQL está listo"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "  Intento $RETRY_COUNT/$MAX_RETRIES... esperando $RETRY_DELAY segundos"
  sleep $RETRY_DELAY
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "✗ MySQL no respondió"
  exit 1
fi

# Ejecutar el SQL
mysql -h localhost \
  -u $MASTER_USERNAME \
  -p$MASTER_PASSWORD \
  $DB_NAME < init-db.sql

echo "✓ Tablas creadas"

echo ""
echo "============================================"
echo "✓ LISTO! Base de datos inicializada"
echo "============================================"
echo ""
echo "Detalles de conexión:"
echo "  Host: localhost"
echo "  Puerto: 3306"
echo "  Usuario: $MASTER_USERNAME"
echo "  Contraseña: $MASTER_PASSWORD"
echo "  Base de datos: $DB_NAME"
echo ""
echo "Tu app puede conectarse ahora mismo."
