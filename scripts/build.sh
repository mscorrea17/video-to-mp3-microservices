#!/bin/bash

# Script para construir todas las imágenes Docker

echo "Construyendo imágenes Docker..."

# Build Auth Service
echo "Construyendo Auth Service..."
docker build -t auth:latest ./src/auth

# Build Gateway Service
echo "Construyendo Gateway Service..."
docker build -t gateway:latest ./src/gateway

# Build Converter Service
echo "Construyendo Converter Service..."
docker build -t converter:latest ./src/converter

# Build Notification Service
echo "Construyendo Notification Service..."
docker build -t notification:latest ./src/notification

echo "Todas las imágenes han sido construidas exitosamente!"

# Para usar con Minikube, cargar las imágenes
if command -v minikube &> /dev/null; then
    echo "Cargando imágenes en Minikube..."
    minikube image load auth:latest
    minikube image load gateway:latest
    minikube image load converter:latest
    minikube image load notification:latest
    echo "Imágenes cargadas en Minikube!"
fi