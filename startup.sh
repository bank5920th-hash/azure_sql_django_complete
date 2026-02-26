#!/bin/bash
set -e

echo "Installing ODBC driver for SQL Server..."
apt-get update -qq
apt-get install -y curl gnupg lsb-release apt-transport-https > /dev/null 2>&1

echo "Adding Microsoft repository..."
curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null || true
curl -s https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list 2>/dev/null || true

echo "Installing Microsoft ODBC Driver 18..."
apt-get update -qq
ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev > /dev/null 2>&1

echo "ODBC Driver installed successfully!"

# Continue with Django app
exec gunicorn --bind=0.0.0.0 --timeout 600 --workers 4 azure_project.wsgi
