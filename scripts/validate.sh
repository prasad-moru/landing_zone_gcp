#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get cluster details from Terraform outputs
echo -e "${YELLOW}Getting cluster details from Terraform outputs...${NC}"
CLUSTER_NAME=$(terraform output -raw cluster_name)
CLUSTER_REGION=$(terraform output -raw region 2>/dev/null || echo "us-central1")
PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || gcloud config get-value project)

echo -e "${BLUE}Cluster: ${CLUSTER_NAME}${NC}"
echo -e "${BLUE}Region: ${CLUSTER_REGION}${NC}"
echo -e "${BLUE}Project: ${PROJECT_ID}${NC}"

# Configure kubectl to connect to the cluster
echo -e "${YELLOW}Configuring kubectl to connect to the cluster...${NC}"
gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${CLUSTER_REGION} --project ${PROJECT_ID}

# Check if kubectl is properly configured
if ! kubectl cluster-info &>/dev/null; then
  echo -e "${RED}Failed to connect to the cluster. Please check your credentials.${NC}"
  exit 1
fi

echo -e "${GREEN}Successfully connected to the cluster.${NC}"

# Validate cluster components
echo -e "${YELLOW}Validating cluster components...${NC}"

# Check node pools
echo -e "${BLUE}Checking node pools...${NC}"
kubectl get nodes -o wide
echo ""

# Check namespaces
echo -e "${BLUE}Checking namespaces...${NC}"
kubectl get namespaces
echo ""

# Check storage classes
echo -e "${BLUE}Checking storage classes...${NC}"
kubectl get storageclasses
echo ""

# Check ingress controller
echo -e "${BLUE}Checking ingress controller...${NC}"
kubectl get pods -n ingress-system
echo ""
kubectl get svc -n ingress-system
echo ""

# Check if HashiCorp Vault is deployed
if kubectl get namespace vault &>/dev/null; then
  echo -e "${BLUE}Checking HashiCorp Vault...${NC}"
  kubectl get pods -n vault
  echo ""
  kubectl get svc -n vault
  echo ""
  
  # Check Vault status
  echo -e "${BLUE}Checking Vault status...${NC}"
  kubectl exec -it vault-0 -n vault -- vault status || echo -e "${YELLOW}Vault might not be initialized or unsealed yet.${NC}"
  echo ""
fi

# Check microservices namespace
if kubectl get namespace microservices &>/dev/null; then
  echo -e "${BLUE}Checking microservices namespace...${NC}"
  kubectl get pods -n microservices
  echo ""
  kubectl get svc -n microservices
  echo ""
fi

# Check PostgreSQL instance
echo -e "${BLUE}Checking PostgreSQL instance...${NC}"
gcloud sql instances list --project ${PROJECT_ID}
echo ""

# Check network policies
echo -e "${BLUE}Checking network policies...${NC}"
kubectl get networkpolicies --all-namespaces
echo ""

# Validate workload identity
echo -e "${BLUE}Checking workload identity...${NC}"
SERVICE_ACCOUNT=$(gcloud iam service-accounts list --filter="displayName:GKE" --format="value(email)" --project ${PROJECT_ID} | head -1)
if [ -n "$SERVICE_ACCOUNT" ]; then
  gcloud iam service-accounts get-iam-policy ${SERVICE_ACCOUNT} --project ${PROJECT_ID}
else
  echo -e "${YELLOW}No GKE service accounts found.${NC}"
fi
echo ""

# Check cluster autoscaling
echo -e "${BLUE}Checking cluster autoscaling...${NC}"
kubectl get hpa --all-namespaces
echo ""

# Provide summary
echo -e "${GREEN}===== Cluster Validation Summary =====${NC}"
echo -e "${GREEN}✅ Cluster connection: Successful${NC}"
echo -e "${GREEN}✅ Node pools: $(kubectl get nodes -o name | wc -l) nodes running${NC}"
echo -e "${GREEN}✅ Storage classes: $(kubectl get storageclasses -o name | wc -l) available${NC}"
echo -e "${GREEN}✅ Namespaces: $(kubectl get namespaces -o name | wc -l) configured${NC}"

# Check the ingress IP is assigned
INGRESS_IP=$(kubectl get svc -n ingress-system ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$INGRESS_IP" ]; then
  echo -e "${GREEN}✅ Ingress controller: Running with IP ${INGRESS_IP}${NC}"
else
  echo -e "${YELLOW}⚠️ Ingress controller: No IP assigned yet${NC}"
fi

# Check if Vault is running
VAULT_PODS=$(kubectl get pods -n vault -o name 2>/dev/null | wc -l)
if [ "$VAULT_PODS" -gt 0 ]; then
  echo -e "${GREEN}✅ HashiCorp Vault: $VAULT_PODS pods running${NC}"
else
  echo -e "${YELLOW}⚠️ HashiCorp Vault: Not deployed or still initializing${NC}"
fi

echo -e "${GREEN}====================================${NC}"
echo -e "${GREEN}Cluster validation completed successfully!${NC}"
echo -e "${YELLOW}If any components show warnings, they may still be initializing or require additional configuration.${NC}"