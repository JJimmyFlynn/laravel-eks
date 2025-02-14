> [!Note]
> Documentation is a work in progress

## EKS with Laravel App
This is an example infrastructure and deployment for a Laravel application on AWS EKS.

At a high level it consists of:
### Laravel Application
- A basic Laravel application slightly modifed to run in a load balanced environment as per the official docs
- Dockerfiles to build an nginx and php-fpm image from the application
### AWS
- All deployed via Open Tofu
- An EKS cluster deployed in private VPC subnets 
  - Configured with EKS access entries to allow an administrator role/user access via the AWS console
- An Elastic Container Registry to house the application images
- IAM policies to all K8s service accounts access to AWS resources
  - With a corresponding OIDC endpoint for authentication to AWS
- An Aurora serverless MYSQL RDS instance
- Systems Manager Parameter Store values to house environment variables for the Laravel App
- CloudWatch for EKS control plane node logs
### Kubernetes
- All deployed via Helm charts and Open Tofu
- AWS Loadbalancer controller to provision ALBs for ingress objects
- Secrets Store CSI Driver and AWS Provider to allow for creation and mounting of secrets pulled from SSM Parameter Store and Secrets Manager
- Service accounts configured with IAM roles to allow for AWS resources access
- External DNS configured to update Cloudflare records when ingress objects are created
- Example Laravel application
  - Served via Nginx and PHP-fpm
  - Pulls its environment variables from SSM Parameter Store via the Secrets Store CSI Driver
