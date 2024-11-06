# DevOps Project. CI/CD/CD Pipeline

> 1. CI via GitHub Actions with linter, scanners and containerization
>    - ESLint
>    - Docker
>    - Trivy
>    - SonarQube
> 2. Applications based on Node.js
>    - API
>    - WEB
> 3. CD/CD with Three-Tier Architecture on AWS, using Terraform
>    - VPC: 3 Public, 3 Private subnets
>    - EKS (Kubernetes)
>      - Helm Charts
>      - Prometheus + Grafana
>      - ArgoCD
>      - AWS Secret Manager
>    - RDS: Aurora PostgreSQL 15.3 (Serverless v2)
---

## Step I - Local tests

Developers gave me the code of applications without documentation:

- Applications require **PostgreSQL** database to function correctly
- Setting up a _Linux_ environment through **Docker**/**VirtualBox**
- Installing **PostgreSQL** and successfully running applications within this setup **LOCALLY**

## Step II - CI (Continuous Integration)

Workflows for **API** & **WEB** applications:

```shell
# For Linters. Locally:
cd apps/api

# Creating and configuring files:
touch .eslintignore .eslintrc.json .gitignore

# Installation of Linter:
npm install -D eslint eslint-config-airbnb-base eslint-plugin-import

# Installation of Prettier:
npm install -D prettier eslint-config-prettier eslint-plugin-prettier
```

- Run **ESLint** linter
- Run **Prettier**
- _Node.js_ **dependencies**
- Run **tests**
- Build via **Docker**
- **Trivy** vulnerability scann
- **SonarQube** code scan

## Step III - CD (Continuous Delivery)

1. Workflows for _creating/updating_ and _deleting_ of **VPC** module with Terraform
2. Workflows for _creating/updating_ and _deleting_ of **EKS** module with Terraform

```shell
# AWS Authorization:
aws configure
- AWS Access Key ID:
- AWS Secret Access Key:
- Default region name: us-east-2
- Default output format: json

# Configure kubectl for work with Cluster:
aws eks update-kubeconfig --name study-cluster --region us-east-2

# ==================================================== #

# Installing Helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Checking the installation
helm version

# Checking the current context
kubectl config current-context

# ==================================================== #

# Adding the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Installing ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Verifying the installation
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# ==================================================== #

# Adding the cert-manager repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Installing cert-manager with CRDs
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \a
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

# Verifying the installation
kubectl get pods -n cert-manager

# ==================================================== #

# Adding the metrics-server repository
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

# Installing with TLS verification disabled (for dev/test)
helm install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--kubelet-insecure-tls}

# Verifying the installation
kubectl get deployment metrics-server -n kube-system
```

3. Workflows for _creating/updating_ and _deleting_ of **RDS** module with Terraform

### Map of Project

```markdown
devops-project/
│
├── apps/                     # WEB Application
│   ├── api/                  # API Application
│   │   ├── src/              # Source code of API
│   │   ├── tests/            # Tests for API
│   │   └── Dockerfile        # Dockerfile for API
│   │
│   └── web/
│       ├── src/              # Source code of WEB
│       ├── tests/            # Tests for WEB
│       └── Dockerfile        # Dockerfile for WEB
│
├── terraform/                # Terraform configuration
│   ├── modules/              # Terraform modules
│   └── environments/         # Configuration for other envs
│
├── k8s/                      # Kubernetes manifests
│   ├── api/                  # Manifests для API
│   ├── web/                  # Manifests для WEB
│   └── infra/                # Manifests for infrastructure components
│
├── .github/workflows/        # GitHub Actions Workflow files
│
├── docs/                     # Documentation of Project
│
├── .gitignore
├── Makefile
├── README.md
└── sonar-project.properties  # Config file for SonarQube
```

### Diagram

```markdown
                +----------------------------------------------------+
                |                         VPC                        |
                | +------------------------------------------------+ |
                | |               (3 Private Subnets)              | |
                | |   +----------------------------------------+   | |
                | |   |             Tier 1: DATABASE           |   | |
                | |   +---+----------+----------+----------+---+   | |
                | |       |          |          |          |       | |
                | |       |          |          |          |       | |
                | |    DB_NAME    DB_PORT    DB_USER    DB_PASS    | |
                | |       |          |          |          |       | |
                | |       v          v          v          v       | |
                | |   +---+----------+----------+----------+---+   | |
                | |   |              Tier 2: API               |   | |
                | |   +-------+-----------------------+--------+   | |
                | |           ^                       ^            | |
                | |           |                       |            | |
                | +-----------|-----------------------|------------+ |
                |             |                       |              |
                |         API_HOST                API_PORT           |
                |             |                       |              |
                | +-----------|-----------------------|------------+ |
                | |           |  (3 Public Subnets)   |            | |
                | |   +-------+-----------------------+--------+   | |
                | |   |              Tier 3: WEB               |   | |
                | |   +-------------------+--------------------+   | |
                | |                       |                        | |
                | +---------------------+ | +----------------------+ |
                |                       | | |                        |
                +-----------------------+ | +------------------------+
                                          v
                                        CLIENT
```

### Variables for .TFVars

```shell
# Set "AWS Region"
region = "us-east-2" # Ohio

# Set "IP Range" of "VPC"
vpc_cidr = "10.0.0.0/16"

# Set "CIDR Blocks" for "Public Subnets"
subnet_web_1_cidr = "10.0.1.0/24"
subnet_web_2_cidr = "10.0.2.0/24"
subnet_web_3_cidr = "10.0.3.0/24"

# Set "CIDR Blocks" for "Private Subnets"
subnet_db_1_cidr = "10.0.11.0/24"
subnet_db_2_cidr = "10.0.12.0/24"
subnet_db_3_cidr = "10.0.13.0/24"

# Set details of "Database"
db_name            = "DB_NAME"
db_username        = "DB_USER"
db_password        = "DB_PASSWORD"
aurora_secret_name = "SECRET_NAME"
```

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=thejondaw_devops-project&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=thejondaw_devops-project)