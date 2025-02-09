terraform {
  backend "s3" {
    bucket         = "flynn-tfstate-php-infra-poc"
    key            = "laravel-k8s/cluster-init"
    region         = "us-east-1"
    dynamodb_table = "php-infra-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.role_arn
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket = "flynn-tfstate-php-infra-poc"
    key    = "laravel-k8s"
    region = "us-east-1"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.cluster.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.cluster.outputs.eks_cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.cluster.outputs.eks_cluster_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "cluster_init" {
  chart = "../../k8s/helm/cluster-init"
  name  = "cluster-init"
}

resource "helm_release" "aws_load_balancer_controller" {
  name            = "aws-elb-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  cleanup_on_fail = true

  depends_on = [helm_release.cluster_init]

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.cluster.outputs.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.namespace"
    value = "kube-system"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = data.terraform_remote_state.cluster.outputs.vpc_id
  }
}

resource "helm_release" "secrets_store_csi_driver" {
  name            = "csi-secrets-store"
  repository      = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart           = "secrets-store-csi-driver"
  namespace       = "kube-system"
  cleanup_on_fail = true
  depends_on      = [helm_release.cluster_init]
}

resource "helm_release" "secrets_store_driver_aws_provider" {
  name            = "secrets-provider-aws"
  repository      = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart           = "secrets-store-csi-driver-provider-aws"
  namespace       = "kube-system"
  cleanup_on_fail = true
  depends_on      = [helm_release.cluster_init]
}
