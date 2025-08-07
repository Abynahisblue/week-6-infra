#!/bin/bash

# Deployment script for the containerized web application infrastructure

set -e

# Configuration
PROJECT_NAME="productsapp"
ENVIRONMENT="prod"
AWS_REGION="us-east-1"

echo "Starting deployment of ${PROJECT_NAME} infrastructure..."

# Deploy VPC Infrastructure
echo "Deploying VPC infrastructure..."
aws cloudformation deploy \
    --template-file Vpc.yaml \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        EnvironmentName=${ENVIRONMENT} \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION}

echo "VPC infrastructure deployed successfully!"

# Deploy CI/CD Pipeline
echo "Deploying CI/CD pipeline..."
aws cloudformation deploy \
    --template-file CICD-Pipeline.yaml \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-cicd" \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        EnvironmentName=${ENVIRONMENT} \
        GitHubRepo="your-username/your-repo" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION}

echo "CI/CD pipeline deployed successfully!"

# Get ECR Repository URI
ECR_URI=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-cicd" \
    --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
    --output text \
    --region ${AWS_REGION})

echo "ECR Repository URI: ${ECR_URI}"

# Deploy ECS Infrastructure
echo "Deploying ECS infrastructure..."
aws cloudformation deploy \
    --template-file ECS-Infrastructure.yaml \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-ecs" \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        EnvironmentName=${ENVIRONMENT} \
        ImageUri="${ECR_URI}:latest" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION}

echo "ECS infrastructure deployed successfully!"

# Get Application URL
ALB_DNS=$(aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-vpc" \
    --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
    --output text \
    --region ${AWS_REGION})

echo ""
echo "=== Deployment Complete ==="
echo "Application URL: http://${ALB_DNS}"
echo "ECR Repository: ${ECR_URI}"
echo ""
echo "Next steps:"
echo "1. Push your application code to the ECR repository"
echo "2. Update the ECS service to use the new image"
echo "3. Configure GitHub Actions with AWS credentials"
echo ""
echo "GitHub Connection ARN (needs manual activation):"
aws cloudformation describe-stacks \
    --stack-name "${PROJECT_NAME}-${ENVIRONMENT}-cicd" \
    --query 'Stacks[0].Outputs[?OutputKey==`GitHubConnectionArn`].OutputValue' \
    --output text \
    --region ${AWS_REGION}