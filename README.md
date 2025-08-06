# Highly Available Containerized Web Application

This project deploys a highly available containerized web application on AWS using CloudFormation, ECS Fargate, RDS PostgreSQL, and S3.

## Architecture

- **VPC**: Custom VPC with public and private subnets across 3 AZs
- **ECS Fargate**: Containerized application with auto-scaling
- **RDS PostgreSQL**: Multi-AZ database for image metadata
- **S3**: Image storage bucket
- **ALB**: Application Load Balancer for high availability
- **CI/CD**: GitHub Actions or CodePipeline for automated deployment

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed (for local testing)
- GitHub repository for your application code

## Deployment Steps

### 1. Deploy Infrastructure

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

Or deploy manually:

```bash
# Deploy VPC
aws cloudformation deploy \
    --template-file Vpc.yaml \
    --stack-name productsapp-prod-vpc \
    --capabilities CAPABILITY_NAMED_IAM

# Deploy CI/CD Pipeline
aws cloudformation deploy \
    --template-file CICD-Pipeline.yaml \
    --stack-name productsapp-prod-cicd \
    --parameter-overrides GitHubRepo="your-username/your-repo" \
    --capabilities CAPABILITY_NAMED_IAM

# Deploy ECS Infrastructure
aws cloudformation deploy \
    --template-file ECS-Infrastructure.yaml \
    --stack-name productsapp-prod-ecs \
    --capabilities CAPABILITY_NAMED_IAM
```

### 2. Configure GitHub Actions

Add the following secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

### 3. Database Setup

The RDS PostgreSQL database is automatically created with:
- **Database Name**: `imageapp`
- **Username**: Stored in Parameter Store at `/{ProjectName}/{Environment}/db/username`
- **Password**: Stored in Parameter Store at `/{ProjectName}/{Environment}/db/password`

### 4. Application Requirements

Your application should:

1. **Environment Variables**:
   - `DB_HOST`: Database endpoint
   - `DB_PORT`: Database port (5432)
   - `DB_NAME`: Database name (imageapp)
   - `DB_USERNAME`: Database username (from Parameter Store)
   - `DB_PASSWORD`: Database password (from Parameter Store)
   - `S3_BUCKET`: S3 bucket name for images
   - `AWS_DEFAULT_REGION`: AWS region

2. **Health Check Endpoint**: `/health` (returns 200 OK)

3. **Port**: Application should listen on port 80

## File Structure

```
week-6/
├── Vpc.yaml                    # VPC infrastructure template
├── ECS-Infrastructure.yaml     # ECS and application infrastructure
├── CICD-Pipeline.yaml         # CI/CD pipeline with CodePipeline
├── .github/
│   └── workflows/
│       └── deploy.yml         # GitHub Actions workflow
├── deploy.sh                  # Deployment script
└── README.md                  # This file
```

## Key Features

### Security
- Private subnets for application and database
- Security groups with least privilege access
- VPC endpoints for AWS services
- Database credentials in Parameter Store

### High Availability
- Multi-AZ deployment across 3 availability zones
- Auto-scaling based on CPU utilization (2-10 instances)
- Multi-AZ RDS for database failover
- Application Load Balancer with health checks

### CI/CD
- Automated build and deployment on code push
- Blue/green deployment with ECS
- ECR for container image storage
- GitHub Actions or CodePipeline integration

## Monitoring and Logging

- CloudWatch logs for application containers
- ECS service metrics and alarms
- RDS monitoring and backups (7-day retention)

## Cleanup

To remove all resources:

```bash
aws cloudformation delete-stack --stack-name productsapp-prod-ecs
aws cloudformation delete-stack --stack-name productsapp-prod-cicd
aws cloudformation delete-stack --stack-name productsapp-prod-vpc
```

## Troubleshooting

1. **GitHub Connection**: The CodeStar connection needs manual activation in the AWS Console
2. **ECR Push**: Ensure Docker is logged in to ECR before pushing images
3. **Database Connection**: Check security groups and Parameter Store values
4. **Health Checks**: Ensure your application responds to `/health` endpoint

## Cost Optimization

- Uses Fargate Spot for cost savings
- T3.micro RDS instance for development
- Lifecycle policies for ECR images
- 7-day log retention