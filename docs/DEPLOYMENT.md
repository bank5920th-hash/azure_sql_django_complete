# Azure Deployment Guide

This guide covers deploying the Django application to **Azure App Service** and **Azure Container Apps**.

## Prerequisites

1. **Production Server**: Install `gunicorn` (recommended for production).
   ```bash
   pip install gunicorn
   pip freeze > requirements.txt
   ```
2. **Settings**:
   - In `azure_project/settings.py`, set `DEBUG = False`.
   - Update `ALLOWED_HOSTS` with your production domain (e.g., `['myapp.azurewebsites.net']`).

---

## Option 1: Azure App Service (Code)

Deploy directly from your local Git repository or VS Code to Azure App Service (Linux).

### Configuration

#### Step 1: ODBC Driver Setup (Critical for SQL Server)
Azure App Service (Linux) requires the Microsoft ODBC Driver to connect to Azure SQL Server. A `startup.sh` file is already included in this project.

1. **Startup Command**:
   Configure the startup command in the Azure Portal > **Configuration** > **General Settings** > **Startup Command**:
   ```bash
   bash /home/site/wwwroot/startup.sh
   ```
   
   This script will:
   - Install ODBC Driver 18 for SQL Server
   - Run database migrations
   - Collect static files
   - Start Gunicorn

#### Step 2: Environment Variables

2.  **Environment Variables**:
    Set `App Settings` in the Azure Portal for your database credentials. **This is critical** for connecting to production databases:
    *   `DB_HOST`: `your-sql-server.database.windows.net`
    *   `DB_NAME`: `your-sql-db`
    *   `DB_USER`: `your-admin-user`
    *   `DB_PASSWORD`: `your-password`
    *   `MONGO_URI`: Your Azure Cosmos DB connection string
    *   `MONGO_DB_NAME`: `django_store_reviews`
    *   `DJANGO_SECRET_KEY`: A strong random string for production security
    *   `DEBUG`: `False` (for production security)

### Deployment Steps
1. **VS Code**: Use the "Azure Tools" extension to "Deploy to Web App...".
2. **CLI**:
   ```bash
   az webapp up --runtime "PYTHON:3.11" --sku B1 --logs
   ```

---

## Option 2: Azure Container Apps / App Service (Container)

Deploy using a Docker container. This is recommended for consistency and if you need specific system dependencies.

### 1. Create a `Dockerfile`
Create a file named `Dockerfile` in the project root:

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies (needed for ODBC driver)
RUN apt-get update && apt-get install -y \
    curl gnupg2 apt-transport-https unixodbc-dev \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && apt-get clean

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip
RUN pip install gunicorn
RUN pip install -r requirements.txt

# Copy project
COPY . /app/

# Expose port and run server
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "azure_project.wsgi"]
```

### 2. Build and Push to Azure Container Registry (ACR)
```bash
az acr build --registry <your-registry-name> --image django-app:latest .
```

### 3. Deploy
- **App Service**: Create a Web App for Containers and select the image from your ACR.
- **Container Apps**: Create a Container App and select the image from your ACR.
  - Ingress: Enabled (External)

---

## Option 3: Frontend Deployment (Azure App Service)

To deploy the React/Vite frontend to Azure App Service:

1.  **Create Resource**:
    *   Create a **Web App**.
    *   **Publish**: Code
    *   **Runtime Stack**: Node 20 LTS (or latest available).
    *   **OS**: Linux.

2.  **Deployment Center**:
    *   Connect your GitHub Fork of the **frontend** repository.
    *   **Build Provider**: GitHub Actions.
    *   **Workflow**: It will generate a workflow file. Ensure it runs `npm install` and `npm run build`.

3.  **Startup Command**:
    *   By default, Azure tries to run `npm start`. Ensure your `package.json` has a start script, or use a startup command like:
        ```bash
        pm2 serve /home/site/wwwroot/dist --no-daemon --spa
        ```
        *(This assumes a Vite build outputting to `dist`)*

4.  **Environment Variables**:
    *   Go to **Settings** > **Environment variables**.
    *   Add `VITE_API_URL` (or `REACT_APP_API_URL` depending on your code).
    *   Value: The URL of your **Backend** App Service (e.g., `https://my-backend.azurewebsites.net`).
    *   **Important**: Frontend needs to know where the Backend is to make API calls.

---

## Verifying Connections

Once both are deployed:

1.  **Backend**: Visit `https://your-backend.azurewebsites.net/api/connect-db/`.
    *   It should show **SQL: Connected** (to Azure SQL).
    *   It should show **Mongo** with a masked Azure Cosmos DB URI.
2.  **Frontend**: Open your Frontend App Service URL.
    *   Try to fetch data (e.g., view stores/products).
    *   If it fails, check the Browser Console (F12) for CORS errors or 404s.

