#!/bin/bash

# Script para desplegar en Kubernetes

echo "Desplegando servicios en Kubernetes..."

# Aplicar manifests
echo "Aplicando RabbitMQ..."
kubectl apply -f k8s/rabbitmq-deploy.yaml

echo "Esperando a que RabbitMQ esté listo..."
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s

echo "Aplicando Auth Service..."
kubectl apply -f k8s/auth-deploy.yaml

echo "Aplicando Gateway Service..."
kubectl apply -f k8s/gateway-deploy.yaml

echo "Aplicando Converter Service..."
kubectl apply -f k8s/converter-deploy.yaml

echo "Aplicando Notification Service..."
kubectl apply -f k8s/notification-deploy.yaml

echo "Aplicando Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "Verificando el estado de los deployments..."
kubectl get deployments
kubectl get services
kubectl get pods

echo "Despliegue completado!"
echo "Puedes verificar el estado con: kubectl get pods"

cat >> scripts/deploy.sh << 'EOF'
k8s/auth-deploy.yaml

echo "Aplicando Gateway Service..."
kubectl apply -f k8s/gateway-deploy.yaml

echo "Aplicando Converter Service..."
kubectl apply -f k8s/converter-deploy.yaml

echo "Aplicando Notification Service..."
kubectl apply -f k8s/notification-deploy.yaml

echo "Aplicando Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "Verificando el estado de los deployments..."
kubectl get deployments
kubectl get services
kubectl get pods

echo "Despliegue completado!"
echo "Puedes verificar el estado con: kubectl get pods"
EOF