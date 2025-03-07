# 🌐 GCP Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?style=for-the-badge&logo=terraform)
![GCP](https://img.shields.io/badge/GCP-Infrastructure-4285F4?style=for-the-badge&logo=google-cloud)

This repository contains Terraform configurations for deploying and managing infrastructure on Google Cloud Platform (GCP).

## 📋 Repository Structure

```
│   backend.tf       # 💾 Terraform state configuration
│   main.tf          # 🏗️ Main infrastructure entrypoint
│   outputs.tf       # 📤 Output variables definition
│   provider.tf      # ☁️ Provider configuration
│   variables.tf     # 🔧 Input variables definition
│   terrform.tfvars  # 🔐 Variable values for deployment
│   
├───modules          # 📦 Reusable infrastructure components
│   │
│   ├───gke-cluster  # 🚢 Google Kubernetes Engine module
│   │
│   ├───iam          # 🔑 Identity and Access Management
│   │
│   ├───ingress      # 🚪 Ingress configuration
│   │
│   ├───network      # 🔌 VPC and networking components
│   │
│   ├───node-pools   # 💻 GKE node pools configuration
│   │
│   ├───storage      # 💾 Cloud Storage buckets
│   │
│   └───vault        # 🔒 HashiCorp Vault configuration
│
└───scripts          # 📜 Utility scripts
        setup.sh     # 🚀 Environment setup script
        validate.sh  # ✅ Configuration validation script
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- GCP Project with required APIs enabled
- Appropriate GCP credentials configured

### Setup

1. Clone this repository
```bash
git clone https://github.com/prasad-moru/landing_zone_gcp.git
cd landing_zone_gcp
```

2. Run the setup script
```bash
./scripts/setup.sh
```

3. Update variables in `terraform.tfvars` to match your environment

4. Initialize Terraform
```bash
terraform init
```

5. Validate your configuration
```bash
./scripts/validate.sh
```

6. Create an execution plan
```bash
terraform plan
```

7. Apply the configuration
```bash
terraform apply
```

## 🏗️ Module Overview

### 🚢 GKE Cluster
Deploys a Google Kubernetes Engine cluster with customized settings.

### 🔑 IAM
Manages Identity and Access Management resources including service accounts and role bindings.

### 🚪 Ingress
Configures ingress controllers and related resources for external access.

### 🔌 Network
Sets up VPC networks, subnets, firewalls, and related networking components.

### 💻 Node Pools
Manages GKE node pools with various machine types and configurations.

### 💾 Storage
Provisions Cloud Storage buckets and related storage resources.

### 🔒 Vault
Deploys and configures HashiCorp Vault for secrets management.

## 📤 Outputs

After a successful deployment, the following outputs will be available:

- GKE cluster endpoint
- Kubernetes cluster credentials
- VPC network details
- Storage bucket access information
- Other service endpoints

## 🔧 Customization

Modify `terraform.tfvars` to customize the deployment for your specific needs. Each module has its own set of variables documented in their respective `variables.tf` files.

## 🛠️ Maintenance

- Run `terraform plan` after modifying any configurations to review changes
- Use `terraform apply` to apply changes
- For complete teardown, use `terraform destroy` (use with caution)

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

⭐ Star this repository if you find it useful!

📧 For questions and support, please open an issue or contact the infrastructure team.
