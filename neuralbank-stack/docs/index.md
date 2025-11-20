# neuralbank-stack Helm Chart

A Helm chart to deploy the NeuralBank stack: PostgreSQL (configured via globals), backend, frontend and an NGINX proxy/gateway.

## Contents
- backend: API service (configurable image, port, replicas)
- frontend: static/web app (configurable image, port, replicas)
- proxy: nginx gateway (LoadBalancer/NodePort)
- global.postgresql: external or chart-provided PostgreSQL credentials

## Requirements
- Kubernetes cluster (v1.20+ recommended)
- Helm 3+
- A PostgreSQL instance or a PostgreSQL chart that sets:
  - global.postgresql.auth.postgresPassword
  - global.postgresql.auth.username
  - global.postgresql.auth.password
  - global.postgresql.auth.database

If you prefer an external DB, set those globals to point to your DB credentials.

## Values (high level)
Key values from values.yaml:

- global.postgresql.auth
  - postgresPassword, username, password, database
- backend
  - image.repository
  - image.tag
  - image.pullPolicy
  - service.port (default 8080)
  - replicaCount
- frontend
  - image.repository
  - image.tag
  - image.pullPolicy
  - service.port (default 80)
  - replicaCount
- proxy
  - image.repository
  - image.tag
  - service.type (LoadBalancer | NodePort)
  - service.port (default 80)

See values.yaml for the full defaults and comments.

## Installation

1. From the chart directory:
```bash
helm install neuralbank . \
  --namespace neuralbank \
  --create-namespace \
  -f values.yaml
```

2. To use a custom values file:
```bash
helm install neuralbank . -f my-values.yaml --namespace neuralbank --create-namespace
```

If using an existing PostgreSQL, ensure you set the globals in your values file:
```yaml
global:
  postgresql:
    auth:
      postgresPassword: "supersecretpassword"
      username: "neuralbank"
      password: "neuralbank123!"
      database: "neuralbank"
```

## Upgrading
```bash
helm upgrade neuralbank . -f values.yaml --namespace neuralbank
```

## Uninstall
```bash
helm uninstall neuralbank --namespace neuralbank
kubectl delete namespace neuralbank
```

## Accessing services
- Backend container port: 8080 (service listens on values.backend.service.port)
- Frontend container port: 80
- Proxy: default LoadBalancer on port 80 (or NodePort when configured)

Run:
```bash
kubectl get svc -n neuralbank
kubectl get pods -n neuralbank
```

## Notes
- Images default to quay.io/... with tag "latest". Set explicit tags in values.yaml for reproducible deployments.
- No persistent volumes are defined by default in values.yaml. Add persistence settings if required.
- For local testing without a LoadBalancer, switch proxy.service.type to NodePort.

## Maintainers
- Repository owner: Maximiliano Pizarro
