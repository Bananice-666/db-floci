#!/bin/bash
# Script para conectarse a la BD y ejecutar el init-db.sql

# Variables (igual que en setup-floci-rds.sh)
MASTER_USERNAME="admin"
MASTER_PASSWORD="password123"
DB_HOST="localhost"
DB_NAME="myappdb"

echo "Conectando a MySQL en Floci y ejecutando init-db.sql..."

# Ejecutar el archivo SQL
mysql -h $DB_HOST \
  -u $MASTER_USERNAME \
  -p$MASTER_PASSWORD \
  $DB_NAME < init-db.sql

echo "Base de datos inicializada."
