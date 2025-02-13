resource "helm_release" "cluster_init" {
  chart = "../../k8s/helm/cluster-init"
  name  = "cluster-init"

  set {
    name  = "load_balancer_controller_service_account.role_arn"
    value = data.terraform_remote_state.cluster.outputs.alb_controller_role_arn
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name            = "aws-elb-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
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

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
}

resource "helm_release" "secrets_store_driver_aws_provider" {
  name            = "secrets-provider-aws"
  repository      = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart           = "secrets-store-csi-driver-provider-aws"
  namespace       = "kube-system"
  cleanup_on_fail = true
  depends_on      = [helm_release.cluster_init]
}

resource "helm_release" "laravel_application" {
  name = "laravel-app"
  chart = "../../k8s/helm/laravel-app"
  cleanup_on_fail = true
  depends_on = [
    helm_release.cluster_init,
    helm_release.aws_load_balancer_controller,
    helm_release.secrets_store_csi_driver,
    helm_release.secrets_store_driver_aws_provider
  ]

  set {
    name  = "secrets_provider_controller_service_account.role_arn"
    value = data.terraform_remote_state.cluster.outputs.secrets_provider_role_arn
  }

  set {
    name  = "deployment.images.nginx"
    value = data.terraform_remote_state.cluster.outputs.nginx_image
  }

  set {
    name  = "deployment.images.php_fpm"
    value = data.terraform_remote_state.cluster.outputs.php_fpm_image
  }
}
