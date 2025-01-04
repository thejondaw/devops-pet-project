# DevOps Pet Project: Three-tier Architecture on AWS

Enterprise-grade deployment of a three-tier architecture using modern DevOps practices and tools.

---

## Architecture Overview

<div align="center">

```
┌──────────────────────────────────────────────────────────┐
│                            VPC                           │
│ ┌──────────────────────────────────────────────────────┐ │
│ │                 (2x PRIVATE SUBNETS)                 │ │
│ │   ┌──────────────────────────────────────────────┐   │ │
│ │   │               TIER I - DATABASE              │   │ │
│ │   └───┐ ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌───┘   │ │
│ │        │           │            │           │        │ │
│ │     DB_NAME     DB_PORT      DB_USER     DB_PASS     │ │
│ │        │           │            │           │        │ │
│ │        ▼           ▼            ▼           ▼        │ │
│ │ ╔═════╣ ╠═════════╣ ╠══════════╣ ╠═════════╣ ╠═════╗ │ │
│ │ ║                                                  ║ │ │
│ │ ║                   (EKS CLUSTER)                  ║ │ │
│ │ ║                                                  ║ │ │
│ │ ║  ┌──┘ └─────────┘ └──────────┘ └─────────┘ └──┐  ║ │ │
│ │ ║  │               TIER II - API                │  ║ │ │
│ │ ║  └─────────┐ ┌────────────────────┐ ┌─────────┘  ║ │ │
│ │ ║             ▲                      ▲             ║ │ │
│ │ ║             │                      │             ║ │ │
│ └─║───────────┤ │ ├──────────────────┤ │ ├───────────║─┘ │
│   ║             │                      │             ║   │
│   ║          API_HOST               API_PORT         ║   │
│   ║             │                      │             ║   │
│ ┌─║───────────┤ │ ├──────────────────┤ │ ├───────────║─┐ │
│ │ ║             │ (2x PUBLIC  SUBNETS) │             ║ │ │
│ │ ║  ┌─────────┘ └────────────────────┘ └─────────┐  ║ │ │
│ │ ║  │                TIER III - WEB              │  ║ │ │
│ │ ║  └─────────────────────┐ ┌────────────────────┘  ║ │ │
│ │ ║                                                  ║ │ │
│ │ ╚══════════════════════╣  ▲  ╠═════════════════════╝ │ │
│ └────────────────────────┐  │  ┌───────────────────────┘ │
│                          │  │  │                         │
└──────────────────────────┘  │  └─────────────────────────┘
                              │
                            CLIENT
```

</div>

---

## Summary

> 1. First of all, local tests.
>
> - Setting up a _Linux_ environment through **Docker**/**QEMU/KVM**
> - Installing **PostgreSQL**
> - Running applications within this setup

> 2. **CI** (*Continuous Integration*) via **GitHub Actions**. Applications are check by *linters*, *tests*, *scanners* and built into an *image*.
> - **ESLint**           *(Code linter)*
> - **Prettier**         *(Code formatter)*
> - **Tests**            *(Unit, integration)*
> - **SonarQube**        *(Static Code Analys)*
> - **Build via Docker** *(Alpine: minimal secure base)*
> - **Trivy**            *(Container security scanner)*

> 2. **CD** (*Continious Delivery/Deployment*) via **GitHub Actions**. Create a *Three-tier* architecture on *AWS* and deploy applications using *GitOps* practices.
> - **VPC** Module
> - **RDS** Module
>   - *Aurora PostgreSQL 15.3 (Serverless v2)*
> - **EKS** Module
>   - **Helm**         *(Package manager)*
>   - **ArgoCD**       *(GitOps delivery)*
>     - **API** Application
>     - **WEB** Application
>     - **NGINX Ingress Controller**
>     - **EBS CSI Driver**
>     - **Grafana**    *(Visualization)*
>     - **Prometheus** *(Nodes metrics)*
>     - **Loki**       *(Storage for Loggs)*
>     - **Promtail**   *(Loggs)*
>     - **Falco**      *(Security monitoring)*
>     - **Velero**     *(Snapshots)*
>     - **HashiCorp Vault** *(Secrets manager)*

---

### Map of Project

```markdown
devops─project/
├── .github/workflows/                # GitHub Actions Workflow files
│   ├── ci─api.yaml                   # CI for API
│   ├── ci─web.yaml                   # CI for WEB
│   ├── cd─infrastructure.yaml        # Create infrastructure
│   ├── post─install.yaml             # Bash script
│   └── cd─destroy.yaml               # Just for destroy infrastructure
│
├── apps/
│   ├── api/                          # API Application
│   │   ├── src/                      # Source code of API
│   │   ├── tests/                    # Tests for API
│   │   └── Dockerfile                # Dockerfile for API
│   │
│   └── web/                          # WEB Application
│       ├── src/                      # Source code of WEB
│       ├── tests/                    # Tests for WEB
│       └── Dockerfile                # Dockerfile for WEB
│
├── helm/                             # Helm
│   ├── charts/
│   │   ├── api/                      # API Chart
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── templates/configmap.yaml
│   │   │   ├── templates/deployment.yaml
│   │   │   ├── templates/secret.yaml
│   │   │   └── templates/service.yaml
│   │   │
│   │   ├── web/                      # WEB Chart
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── templates/configmap.yaml
│   │   │   ├── templates/deployment.yaml
│   │   │   ├── templates/ingress.yaml
│   │   │   └── templates/service.yaml
│   │   │
│   │   └── monitoring/               # Grafana & Prometheus Chart
│   │       ├── Chart.yaml
│   │       └── values.yaml
│   │
│   └── environments/                 # Configs Environments
│       ├── develop/
│       │   └── values.yaml
│       ├── stage/
│       │   └── values.yaml
│       └── prod/
│           └── values.yaml
│
├── terraform/                        # Terraform configs
│   ├── modules/
│   │   ├── backend/                  # Module S3 Backend
│   │   ├── vpc/                      # Module VPC
│   │   ├── eks/                      # Module EKS
│   │   ├── rds/                      # Module RDS
│   │   └── tools/                    # Module TOOLS
│   │
│   └── environments/                 # Configurations of Environments
│       ├── develop/
│       │   ├── main.tf
│       │   └── terraform.tfvars
│       ├── stage/
│       └── prod/
│
├── k8s
│   ├── infra/
│   │   ├── namespaces.yaml           # Namespaces manifest
│   │   └── monitoring─ingress.yaml   # Grafana & Prometheus manifest
│   │
│   └── argocd/applications           # Apps manifests for ArgoCD dashboard
│              └── develop/
│                  ├── api.yaml
│                  ├── web.yaml
│                  └── monitoring.yaml
│
├── ansible/                          # Ansible configurations
│   ├── inventory/                    # Inventory files
│   ├── playbooks/                    # Playbook files
│   └── roles/                        # Ansible roles
│
├── scripts/                          # Automatization Scripts
│   └── post─install.sh               # Post install of Tools
│
├── docs/                             # Documentation of Project
│
├── .gitignore
├── Makefile
├── README.md
└── sonar─project.properties          # Configuration of SonarQube
```

---

### Variables for .TFVars

```shell
# Set - AWS Region
region         = "your-region-number"

# Set - S3 Bucket Name
backend_bucket = "your-bucket-name"

# Set - Environment - Name
environment    = "develop"

# Set - IP Range of VPC & Subnets
vpc_configuration = {
  cidr = "10.0.0.0/16"
  subnets = {
    web = {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-2a"
    }
    alb = {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-2b"
    }
    api = {
      cidr_block = "10.0.3.0/24"
      az         = "us-east-2a"
    }
    db = {
      cidr_block = "10.0.4.0/24"
      az         = "us-east-2c"
    }
  }
}

# Set - Database - Configuration
db_configuration = {
  name     = "name-of-db"
  username = "username"
  password = "password"
  port     = 5432
}
```

---

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project═thejondaw_devops─project&metric═alert_status)](https://sonarcloud.io/summary/new_code?id═thejondaw_devops─project)
