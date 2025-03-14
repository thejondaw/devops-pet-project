> ### ⚠️ Disclaimer
>
>  This is a pet project focused on practical DevOps implementation using AWS services and modern CI/CD practices. The infrastructure prioritizes development experience and learning opportunities over enterprise-grade configurations and high availability. All cost-optimization decisions are intentional for educational purposes.

---

# 🏗️ Three-Tier Architecture on AWS

[![CI - Backend](https://github.com/thejondaw/devops-pet-project/actions/workflows/ci-backend.yaml/badge.svg)](https://github.com/thejondaw/devops-pet-project/actions/workflows/ci-backend.yaml)
[![CI - Frontend](https://github.com/thejondaw/devops-pet-project/actions/workflows/ci-frontend.yaml/badge.svg)](https://github.com/thejondaw/devops-pet-project/actions/workflows/ci-frontend.yaml)
[![Infrastructure](https://github.com/thejondaw/devops-pet-project/actions/workflows/infrastructure.yaml/badge.svg)](https://github.com/thejondaw/devops-pet-project/actions/workflows/infrastructure.yaml)
[![CD - Applications](https://github.com/thejondaw/devops-pet-project/actions/workflows/cd-applications.yaml/badge.svg)](https://github.com/thejondaw/devops-pet-project/actions/workflows/cd-applications.yaml)

CI/CD implementation of a three-tier architecture leveraging modern DevOps practices, Infrastructure as Code, and GitOps methodologies.

## 🏛️ Application Architecture

The project implements a classic three-tier architecture with modern cloud-native enhancements:

```mermaid
flowchart TB
    User([User]) --> |HTTPS| WebsiteExternal[External Website\n Entry point for clients]
    WebsiteExternal --> |TLS| AWSWAF[AWS WAF\n Filters malicious traffic\n and DDoS attacks]

    subgraph AWS ["AWS Cloud"]
        AWSWAF --> |Traffic filtering| ELB[AWS Load Balancer\n Distributes load\n across cluster nodes]

        subgraph VPC ["VPC - Virtual Private Cloud"]
            subgraph PublicSubnets ["Public Subnets - Accessible from the internet"]
                ELB --> |HTTPS| NACL1[Network ACL\n First level\n of network filtering]
                NACL1 --> |Filtering| SG1[Security Group\n Second level of access\n control at port level]

                subgraph IngressControllerNS ["Namespace: ingress-nginx"]
                    SG1 --> |443| IC_Service["Service: ingress-nginx (LoadBalancer)\n Proxies external traffic\n into the cluster and back"]
                    IC_Service --> IC_Pods["NGINX Ingress Controller Pods\n Manage routing rules\n for HTTP/HTTPS requests"]
                end
            end

            subgraph PrivateSubnets ["Private Subnets - Isolated from the internet"]
                subgraph EKSCluster ["EKS Kubernetes Cluster"]
                    IC_Pods --> |Applies rules| K8sIngress["Ingress Resources\n Declarative routing rules\n based on hosts/paths"]

                    subgraph CertManagerNS ["Namespace: cert-manager"]
                        CertManagerService["Service: cert-manager\n Internal service for\n managing certificates"]
                        CertManagerPods["cert-manager Pods\n Automatically request\n and renew TLS certificates"]
                        CertManagerService --- CertManagerPods
                    end

                    CertManagerPods --> |Creates| TLSSecrets[(TLS certificates\n Used for\n encrypting traffic)]
                    K8sIngress --> |Uses| TLSSecrets

                    subgraph LinkerdNS ["Namespace: linkerd"]
                        LinkerdService["Service: linkerd-control-plane\n Entry point for managing\n service mesh"]
                        LinkerdPods["Linkerd Pods\n Provide mTLS, load balancing,\n and metrics for services"]
                        LinkerdService --- LinkerdPods
                    end

                    subgraph VaultNS ["Namespace: vault"]
                        VaultService["Service: vault\n Service for accessing\n secrets"]
                        VaultPods["Vault Pods\n Secure storage\n for secrets and keys"]
                        VaultService --- VaultPods
                    end

                    subgraph MonitoringNS ["Namespace: monitoring"]
                        PrometheusService["Service: prometheus\n Service for collecting and storing\n metrics"]
                        GrafanaService["Service: grafana\n Service for visualizing\n metrics and alerting"]
                        LokiService["Service: loki\n Service for processing\n and storing logs"]
                        PromtailService["Service: promtail\n Service for collecting logs\n from nodes and pods"]
                        FalcoService["Service: falco\n Service for runtime security monitoring"]

                        PrometheusService --- PrometheusPods["Prometheus Pods\n Collect, store, and\n alert on metrics"]
                        GrafanaService --- GrafanaPods["Grafana Pods\n Visualize metrics\n and logs in dashboards"]
                        LokiService --- LokiPods["Loki Pods\n Storage and indexing\n of logs"]
                        PromtailService --- PromtailPods["Promtail Pods\n Agents on each node\n for log collection"]
                        FalcoService --- FalcoPods["Falco Pods\n Monitor and alert on suspicious activity"]
                    end

                    subgraph AppNS ["Namespace: application"]
                        K8sIngress --> |Routes to| FrontendService["Service: frontend (ClusterIP)\n Internal load balancer\n for frontend pods"]
                        K8sIngress --> |Routes to| BackendService["Service: backend (ClusterIP)\n Internal load balancer\n for backend pods"]

                        FrontendService --> FrontendPods["Frontend Pods\n SPA application\n for user interface"]
                        BackendService --> BackendPods["Backend Pods\n API and business logic\n of the application"]

                        FrontendPods --- |Sidecar injection| LinkerdPods
                        BackendPods --- |Sidecar injection| LinkerdPods

                        FrontendPods --> |mTLS via Linkerd| BackendPods

                        FrontendPods -.-> |Retrieves secrets| VaultPods
                        BackendPods -.-> |Retrieves secrets| VaultPods
                    end

                    PrometheusPods -.-> |Scrapes metrics| AppNS
                    PromtailPods -.-> |Collects logs| AppNS

                    BackendPods --> |DB Connections| SG2[Security Group DB\n Access control to database\n at port level]
                end

                subgraph RDSDB ["Amazon RDS"]
                    SG2 --> |5432| PostgreSQL[(PostgreSQL\n Relational database\n for data storage)]
                end

                subgraph Docker ["Docker Registry"]
                    DockerRegistry[(Private Docker Registry\n Storage for\n container images)]
                end

                EKSCluster -.-> |Pulls images| DockerRegistry
            end
        end

        subgraph AWSServices ["Other AWS Services"]
            subgraph Route53 ["Route53"]
                DNSRecords[DNS Records\n Management of DNS records]
            end

            WebsiteExternal -.-> |DNS| DNSRecords
        end
    end

    %% Catppuccin Mocha color palette
    classDef base fill:#1e1e2e,stroke:#cdd6f4,color:#cdd6f4;
    classDef flamingo fill:#f38ba8,stroke:#1e1e2e,color:#1e1e2e;
    classDef pink fill:#f5c2e7,stroke:#1e1e2e,color:#1e1e2e;
    classDef mauve fill:#cba6f7,stroke:#1e1e2e,color:#1e1e2e;
    classDef red fill:#f38ba8,stroke:#1e1e2e,color:#1e1e2e;
    classDef maroon fill:#eba0ac,stroke:#1e1e2e,color:#1e1e2e;
    classDef peach fill:#fab387,stroke:#1e1e2e,color:#1e1e2e;
    classDef yellow fill:#f9e2af,stroke:#1e1e2e,color:#1e1e2e;
    classDef green fill:#a6e3a1,stroke:#1e1e2e,color:#1e1e2e;
    classDef teal fill:#94e2d5,stroke:#1e1e2e,color:#1e1e2e;
    classDef sky fill:#89dceb,stroke:#1e1e2e,color:#1e1e2e;
    classDef sapphire fill:#74c7ec,stroke:#1e1e2e,color:#1e1e2e;
    classDef blue fill:#89b4fa,stroke:#1e1e2e,color:#1e1e2e;
    classDef lavender fill:#b4befe,stroke:#1e1e2e,color:#1e1e2e;
    classDef securityGroup fill:#fab387,stroke:#1e1e2e,color:#1e1e2e;

    %% Kubernetes services
    classDef k8sService fill:#f38ba8,stroke:#1e1e2e,color:#1e1e2e,stroke-width:2px,stroke-dasharray: 5 5;

    %% Apply classes to elements
    class WebsiteExternal,User yellow;
    class VPC,AWS,PublicSubnets,PrivateSubnets base;
    class ELB blue;
    class DockerRegistry maroon;
    class AWSWAF red;
    class NACL1 red;
    class SG1,SG2 securityGroup;
    class IngressControllerNS,EKSCluster,AppNS,CertManagerNS,LinkerdNS,VaultNS,MonitoringNS blue;
    class K8sIngress,IC_Pods,VaultPods,PrometheusPods,GrafanaPods,LokiPods,PromtailPods,FalcoPods,FrontendPods,BackendPods lavender;
    class CertManagerPods red;
    class LinkerdPods red;
    class TLSSecrets red;
    class IC_Service blue;
    class VaultService blue;
    class PrometheusService blue;
    class GrafanaService blue;
    class LokiService blue;
    class PromtailService blue;
    class FalcoService blue;
    class FrontendService blue;
    class BackendService blue;
    class CertManagerService red;
    class LinkerdService red;
    class PostgreSQL,RDSDB green;
    class Route53,AWSServices sapphire;
    class DNSRecords red;

```

Each tier is containerized and deployed to EKS with dedicated responsibilities:

1. **Frontend Tier (Web Service)**
   - Serves static content and UI
   - Handles user interactions
   - Proxies requests to API
   - Environment Variables:
     - `PORT`: 4000
     - `API_HOST`: API service endpoint

2. **Backend Tier (API Service)**
   - Processes business logic
   - Manages database interactions
   - Handles data validation
   - Environment Variables:
     - `PORT`: 3000
     - `DBUSER`: Database username
     - `DBPASS`: Database password
     - `DBHOST`: Database endpoint
     - `DBPORT`: 5432
     - `DB`: Database name

3. **Database Tier (PostgreSQL)**
   - Standalone PostgreSQL 17.2 on `t4g.micro` instance
   - Cost-effective GP2 storage configuration
   - Basic daily backup retention
   - Single-AZ deployment for development purposes
   - Custom parameter group for enhanced logging

## 🔄 CI/CD Pipeline Implementation

This project demonstrates a comprehensive CI/CD approach following best practices:

### 🔨 Continuous Integration (CI) Pipeline

This CI process ensures code quality and security before containerization

1. **Code Quality Gates**
   - ESLint (`.eslintrc`) validates code style
   - Prettier enforces consistent formatting
   - SonarQube performs deep code analysis
   - Unit & Integration test coverage

2. **Security Validation**
   - Dependencies audit
   - Trivy container scanning
   - SAST through SonarQube
   - Infrastructure code validation

3. **Artifact Generation**
   - Multi-stage Docker builds
   - Alpine-based images for minimal attack surface
   - Automated versioning and tagging
   - Container signing and verification

### 🚀 Continuous Delivery/Deployment (CD) Pipeline

This CD implementation consists of three major phases:

```mermaid
graph TD
    A[Infrastructure as Code] -->|terraform apply| B[AWS Resources]
    B -->|post-install| C[Platform Services]
    C -->|argocd sync| D[Applications]

    subgraph AWS Resources
        VPC[VPC & Networking]
        EKS[EKS Cluster]
        RDS[RDS Aurora]
    end

    subgraph Platform Services
        ArgoCd[ArgoCD]
        Monitor[Prometheus/Grafana]
        Logs[Loki/Promtail]
        Secrets[Vault]
    end

    subgraph Applications
        API[API Service]
        Web[Web UI]
    end
```

1. **Infrastructure Provisioning (IaC)**
   - TFLint validation for infrastructure code
   - AWS-specific rule checking
   - Deprecated resource detection
   - Best practices enforcement
   - Automated formatting and documentation

2. **Platform Tools**
   - GitOps with ArgoCD
   - Monitoring (Prometheus + Grafana)
   - Logging (Loki + Promtail)
   - Network (Falco)
   - Secrets (Vault)
   - Ingress (NGINX)

3. **Application Deployment**
   - Automated YAML formatting & syntax verification
   - Declarative configs in Git
   - Automatic sync via ArgoCD
   - Zero-touch deployment
   - Automated rollbacks

<div align="center">
  <img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png">
</div>

## 📋 Implementation Progress

### ⚙️ Local Development
- [x] Linux environment setup
- [x] PostgreSQL configuration
- [x] Application runtimes
- [x] Development workflow

### 🔄 CI Pipeline
- [x] Code quality automation
- [x] Test frameworks
- [x] Security scanning
- [x] Container builds

### 🏗️ AWS Infrastructure
- [x] VPC & Networking
- [x] EKS deployment
- [x] RDS configuration

### ⚡ Platform Services
- [x] ArgoCD installation
- [x] Monitoring stack
- [x] Logging pipeline
- [x] Secrets management
- [x] Security monitoring

### 🚀 Applications
- [x] API service deployment
- [x] Web UI deployment

## 📁 Project Structure

```
devops-pet-project/
├── .github/workflows/          # CI/CD pipeline definitions
├── apps/                       # Application source code
│   ├── api/                    # Backend service
│   └── web/                    # Frontend application
├── helm/                       # Kubernetes package configs
├── terraform/                  # Infrastructure as Code
│   ├── modules/                # Reusable IaC components
│   └── environments/           # Environment configurations
├── k8s/                        # Kubernetes resources & ArgoCD
└── scripts/                    # Automation utilities
```

## 🛠️ Environment Configuration

Required variables in `terraform.tfvars`:

```hcl
region         = "your-region"
backend_bucket = "your-bucket"
environment    = "dev" "stage" "prod"

db_configuration = {
  name     = "name-of-db"
  username = "username"
  password = "password"
  port     = 5432
}
```

## 📚 Documentation

- [Local Test Readme](docs/local-tests.md)
- [Applications Configuration Readme](docs/README.md)

<div align="center">
  <img src="https://raw.githubusercontent.com/andreasbm/readme/master/assets/lines/rainbow.png">
</div>
