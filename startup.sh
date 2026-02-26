#!/bin/bash
echo "Starting Django app..."
gunicorn --bind=0.0.0.0:8000 --timeout 600 azure_project.wsgi:application