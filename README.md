> [!Note]
> Documentation and project are works in progress

## EKS with Laravel App
This is an example infrastructure and deployment for a Laravel application on AWS EKS.

At a high level it consists of:
### Laravel Application
- A basic Laravel application slightly modified to run in a load balanced environment as per the [official docs](https://laravel.com/docs/11.x/requests#configuring-trusted-proxies)
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
- Application ingress ALB fronted by and locked down to CloudFront
- CloudWatch for EKS control plane node logs
### Kubernetes
- All deployed via [Helm](https://helm.sh) charts and [Open Tofu](https://opentofu.org)
- [AWS Loadbalancer controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/) to provision ALBs for ingress objects
- [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io) and [AWS Provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) to allow for creation and mounting of secrets pulled from SSM Parameter Store and Secrets Manager
- Service accounts configured with IAM roles to allow for AWS resources access
- [External DNS](https://kubernetes-sigs.github.io/external-dns/latest/) configured to update Cloudflare records when ingress objects are created
- Example Laravel application
  - Served via Nginx and PHP-fpm
  - Pulls its environment variables from SSM Parameter Store via the Secrets Store CSI Driver
### CI/CD
- Container images are built via Github actions and pushed to an ECR registry
