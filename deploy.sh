#!/bin/bash
set -e

echo "Installing ODBC driver for SQL Server..."
apt-get update
apt-get install -y curl gnupg lsb-release apt-transport-https 2>&1 | tail -5

echo "Adding Microsoft repository..."
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null || true
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list 2>/dev/null || true

echo "Installing Microsoft ODBC Driver 18..."
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev 2>&1 | tail -10

echo "ODBC Driver installation complete!"
echo "Installed ODBC drivers:"
odbcinst -q -d

echo "Deployment script complete!"
```

So the **only change** is deleting the old lines 20-26 that had the broken Oryx build logic.

Then the **main fix** is still in **Azure Portal → Configuration → General Settings → Startup Command**:
```
gunicorn --bind=0.0.0.0:8000 --timeout 600 azure_project.wsgi:application