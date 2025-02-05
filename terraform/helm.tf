provider "helm" {
  kubernetes {
    host = aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.default.certificate_authority.0.data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.default.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "cluster_init" {
  chart = "../k8s/helm/cluster-init"
  name  = "cluster-init"
}

resource "helm_release" "aws_load_balancer_controller" {
  name  = "aws-elb-controller"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"

  depends_on = [
    aws_eks_node_group.app,
    aws_iam_openid_connect_provider.default,
    aws_eks_access_entry.laravel-eks-admin,
    helm_release.cluster_init
  ]

  set {
    name  = "clusterName"
    value = aws_eks_cluster.default.name
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
    value = aws_vpc.default.id
  }
}
