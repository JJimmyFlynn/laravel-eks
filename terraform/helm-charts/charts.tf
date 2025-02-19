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
      cluster_name = data.terraform_remote_state.cluster.outputs.eks_cluster_name
    })
  ]
}

/*========== Load Balancer Controller ==========*/
resource "helm_release" "aws_load_balancer_controller" {
  name            = "aws-elb-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
  cleanup_on_fail = true
  values = [
    templatefile("${path.module}/values/alb-controller.yaml", {
      cluster_name = data.terraform_remote_state.cluster.outputs.eks_cluster_name,
      region = var.region,
      vpc_id =  data.terraform_remote_state.cluster.outputs.vpc_id,
      service_account_role_arn = data.terraform_remote_state.cluster.outputs.alb_controller_role_arn
    })
  ]

  depends_on = [
    helm_release.external_secrets_operator
  ]
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
}

/*========== Laravel Application ==========*/
resource "helm_release" "laravel_application" {
  name            = "laravel-app"
  chart           = "../../k8s/helm/laravel-app"
  cleanup_on_fail = true
  values = [
    templatefile("${path.module}/values/laravel-app.yaml", {
      domain = var.domain
      alb_domain = var.alb_domain
      secrets_provider_controller_service_account_role = data.terraform_remote_state.cluster.outputs.secrets_provider_role_arn,
      nginx_image = data.terraform_remote_state.cluster.outputs.nginx_image,
      php_fpm_image = data.terraform_remote_state.cluster.outputs.php_fpm_image
      alb_security_group_ids = data.terraform_remote_state.cluster.outputs.security_group_allow_cloudfront_inbound_id
    })
  ]
  depends_on = [
    helm_release.cluster_init,
    helm_release.aws_load_balancer_controller,
    helm_release.external_secrets_operator
  ]
}
