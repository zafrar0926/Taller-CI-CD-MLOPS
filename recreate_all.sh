#!/bin/bash

echo "🧹 1. Deteniendo port-forwards activos en puertos comunes (3000, 8000, 8080)..."
for port in 3000 8000 8080; do
  pid=$(lsof -ti tcp:$port)
  if [ ! -z "$pid" ]; then
    kill -9 $pid && echo "✅ Puerto $port liberado (PID $pid)"
  else
    echo "ℹ️ Puerto $port libre"
  fi
done

echo "🧹 2. Deteniendo contenedores Docker anteriores..."
docker stop $(docker ps -q) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null
docker system prune -f

echo "🔁 3. Reiniciando Minikube..."
minikube stop
minikube delete
minikube start

echo "🐳 4. Reconstruyendo imágenes Docker dentro de Minikube..."
eval $(minikube docker-env)

echo "  🔨 Construyendo imagen API..."
docker build -t zafrar09/mlops_ci_cd:latest ./api

echo "  🔨 Construyendo imagen LoadTester..."
docker build -t loadtester ./loadtester

echo "🚀 5. Aplicando manifiestos de Kubernetes..."
kubectl apply -k manifests/

echo "📦 5.5 Instalando Argo CD si no existe..."
if ! kubectl get ns argocd >/dev/null 2>&1; then
  kubectl create namespace argocd
  kubectl apply -n argocd -f ./argocd/install.yaml
  echo "⏳ Esperando a que los pods de Argo CD estén listos..."
  kubectl wait --for=condition=available --timeout=120s deployment/argocd-server -n argocd
  echo "🔑 Contraseña inicial de Argo CD:"
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
else
  echo "✅ Argo CD ya está instalado."
fi

echo "📌 5.6 Aplicando app.yaml de Argo CD..."
kubectl apply -f manifests/argo-cd/app.yaml

echo "⏳ Esperando a que los pods estén listos..."
kubectl wait --for=condition=ready pod --all --timeout=90s

echo "🌐 6. Lanzando port-forwards (en segundo plano)..."
kubectl port-forward service/api 8000:8000 &
kubectl port-forward service/grafana 3000:3000 &
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
kubectl port-forward svc/prometheus 9090:9090 &

echo "✅ Proyecto reiniciado completamente."
echo "➡️  API:     http://localhost:8000/docs"
echo "➡️  Grafana: http://localhost:3000"
echo "➡️  ArgoCD:  http://localhost:8080"
echo "➡️  Prometheus:  http://localhost:9090"

