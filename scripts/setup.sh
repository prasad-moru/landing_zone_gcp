#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project setup
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
BUCKET_NAME="tf-state-gke-prod-cluster-${PROJECT_ID}"

echo -e "${YELLOW}Setting up GKE Terraform infrastructure for project: ${PROJECT_ID}${NC}"

# Check if user is logged in
gcloud auth list --filter=status:ACTIVE --format="value(account)" || {
  echo -e "${RED}Please login to Google Cloud before running this script:${NC}"
  echo "gcloud auth login"
  exit 1
}

# Ensure the GCP project exists and we have access
echo -e "${YELLOW}Verifying project access...${NC}"
gcloud projects describe ${PROJECT_ID} >/dev/null 2>&1 || {
  echo -e "${RED}Cannot access project ${PROJECT_ID}. Please check permissions or create the project.${NC}"
  exit 1
}

# Enable required APIs
echo -e "${YELLOW}Enabling required GCP APIs...${NC}"
gcloud services enable container.googleapis.com \
  compute.googleapis.com \
  servicenetworking.googleapis.com \
  cloudkms.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  --project=${PROJECT_ID}

# Create GCS bucket for Terraform state if it doesn't exist
echo -e "${YELLOW}Setting up Terraform state bucket...${NC}"
if gsutil ls -b gs://${BUCKET_NAME} >/dev/null 2>&1; then
  echo -e "${GREEN}Terraform state bucket ${BUCKET_NAME} already exists.${NC}"
else
  echo -e "${YELLOW}Creating Terraform state bucket ${BUCKET_NAME}...${NC}"
  gsutil mb -l ${REGION} gs://${BUCKET_NAME}
  gsutil versioning set on gs://${BUCKET_NAME}
  
  # Enable bucket encryption
  gsutil kms encryption -k projects/${PROJECT_ID}/locations/${REGION}/keyRings/tf-keyring/cryptoKeys/tf-key gs://${BUCKET_NAME} || {
    echo -e "${YELLOW}Creating KMS key for bucket encryption...${NC}"
    gcloud kms keyrings create tf-keyring --location=${REGION}
    gcloud kms keys create tf-key --location=${REGION} --keyring=tf-keyring --purpose=encryption
    gsutil kms encryption -k projects/${PROJECT_ID}/locations/${REGION}/keyRings/tf-keyring/cryptoKeys/tf-key gs://${BUCKET_NAME}
  }
fi

# Update backend.tf with correct bucket name
echo -e "${YELLOW}Updating backend.tf with bucket information...${NC}"
sed -i "s/bucket  = \"tf-state-gke-prod-cluster\"/bucket  = \"${BUCKET_NAME}\"/g" ../backend.tf

# Update terraform.tfvars with project ID
echo -e "${YELLOW}Updating terraform.tfvars with project information...${NC}"
sed -i "s/project_id                = \"your-gcp-project-id\"/project_id                = \"${PROJECT_ID}\"/g" ../terraform.tfvars

# Verify terraform is installed
if ! command -v terraform &> /dev/null; then
  echo -e "${RED}Terraform is not installed. Please install Terraform before continuing.${NC}"
  exit 1
fi

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
cd ..
terraform init

echo -e "${GREEN}Setup complete! You can now run:${NC}"
echo -e "  terraform plan     # To see what resources will be created"
echo -e "  terraform apply    # To create the infrastructure"
echo -e "${YELLOW}Make sure to review and adjust terraform.tfvars for your specific requirements!${NC}"