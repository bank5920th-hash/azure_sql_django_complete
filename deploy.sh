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

# Run standard Oryx build
builtInCommand=$KUDU_SYNC_COMMAND
if [ -z "$builtInCommand" ]; then
    # Use the default oryx build
    echo "Running standard Python build..."
    /opt/buildsys/bin/oryx build /home/site/wwwroot --platform python --platform-version 3.14 -o /tmp/8de6a1f4e9e8dcc
fi

echo "Deployment script complete!"
