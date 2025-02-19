/*========== Metrics Server ==========*/
resource "helm_release" "metrics_server" {
  name  = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart = "metrics-server"
}

/*========== Karpenter ==========*/
resource "helm_release" "karpenter" {
  name  = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart = "karpenter"
  version = "1.2.1"
  namespace = "kube-system"

  values = [
    templatefile("${path.module}/values/karpenter.yaml", {
      karpenter_controller_role_arn = data.terraform_remote_state.cluster.outputs.karpenter_controller_role_arn
    })
  ]

  set {
    name  = "settings.clusterName"
    value = data.terraform_remote_state.cluster.outputs.eks_cluster_name
  }

  set {
    name  = "interruptionQue"
    value = data.terraform_remote_state.cluster.outputs.eks_cluster_name
  }
}

/*========== Load Balancer Controller ==========*/
resource "helm_release" "aws_load_balancer_controller" {
  name            = "aws-elb-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
  cleanup_on_fail = true
  values = [
    file("${path.module}/values/alb-controller.yaml")
  ]

  depends_on = [
    helm_release.external_secrets_operator
  ]

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.cluster.outputs.eks_cluster_name
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

/*========== External Secrets Operator ==========*/
resource "helm_release" "external_secrets_operator" {
  name  = "external-secrets-operator"
  repository = "https://charts.external-secrets.io"
  chart = "external-secrets"
  namespace = "kube-system"
}

/*========== External DNS ==========*/
resource "helm_release" "external_dns" {
  name            = "external-dns"
  repository      = "https://kubernetes-sigs.github.io/external-dns/"
  chart           = "external-dns"
  version         = "1.15.0"
  namespace       = "kube-system"
  cleanup_on_fail = true
  values = [
    templatefile("${path.module}/values/external-dns.yaml", {
      secrets_provider_role_arn = data.terraform_remote_state.cluster.outputs.secrets_provider_role_arn
    })
  ]
  depends_on = [
    helm_release.external_secrets_operator
  ]
}

/*========== Cluster Init ==========*/
resource "helm_release" "cluster_init" {
  name  = "cluster-init"
  chart = "../../k8s/helm/cluster-init"

  depends_on = [
    helm_release.external_secrets_operator
  ]

  set {
    name  = "load_balancer_controller_service_account.role_arn"
    value = data.terraform_remote_state.cluster.outputs.alb_controller_role_arn
  }
}

/*========== Laravel Application ==========*/
resource "helm_release" "laravel_application" {
  name            = "laravel-app"
  chart           = "../../k8s/helm/laravel-app"
  cleanup_on_fail = true
  depends_on = [
    helm_release.cluster_init,
    helm_release.aws_load_balancer_controller,
    helm_release.external_secrets_operator
  ]

  set {
    name  = "domain"
    value = var.domain
  }

  set {
    name  = "alb_domain"
    value = var.alb_domain
  }

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

  set_list {
    name  = "ingress.loadBalancer.securityGroupIds"
    value = [data.terraform_remote_state.cluster.outputs.security_group_allow_cloudfront_inbound_id]
  }
}
