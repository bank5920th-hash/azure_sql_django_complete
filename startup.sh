#!/bin/bash

# Update package manager
apt-get update

# Install ODBC driver dependencies
apt-get install -y curl gnupg lsb-release

# Add Microsoft's repository key
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

# Add Microsoft's repository
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Update again
apt-get update

# Install ODBC Driver 18 for SQL Server (set license acceptance)
ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Install unixODBC for additional compatibility
apt-get install -y unixodbc-dev

# Run Django migrations
python manage.py migrate

# Collect static files for production
python manage.py collectstatic --noinput

# Start gunicorn
gunicorn --bind=0.0.0.0 --timeout 600 azure_project.wsgi
