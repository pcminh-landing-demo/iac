# This runs after EKS is deployed to bootstrap K8s-native deployment tools

provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token = data.aws_eks_cluster_auth.cluster_auth.token

  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   command     = "aws"
  #   # This requires the awscli to be installed locally where Terraform is executed
  #   args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  # }

  # # The provider will use the "default" context if `config_context` is not specified
  # config_path = "~/.kube/config"
  # # The `aws eks get-token` does not allow specifying the context name but it uses the ClusterARN as the context name
  # config_context = module.eks.cluster_arn
}

provider "helm" {
  # kubernetes = provider.kubernetes
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token = data.aws_eks_cluster_auth.cluster_auth.token

    # exec = {
    #   api_version = "client.authentication.k8s.io/v1beta1"
    #   command     = "aws"
    #   # This requires the awscli to be installed locally where Terraform is executed
    #   args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    # }

    # # The provider will use the "default" context if `config_context` is not specified
    # config_path = "~/.kube/config"
    # # The `aws eks get-token` does not allow specifying the context name but it uses the ClusterARN as the context name
    # config_context = module.eks.cluster_arn
  }
}


resource "helm_release" "argocd" {
  name = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  namespace = "argocd"
  create_namespace = true

  values = [
    templatefile(
      "${path.module}/helm/argocd.values.yaml.tftpl",
      {}
    )
  ]
}

resource "kubernetes_manifest" "argocd_repository" {
  count = var.param__post_eks_apply ? 1 : 0

  manifest = yamldecode(
    templatefile(
      "${path.module}/helm/argocd-repo-secret.yaml.tftpl",
      {
        "gitops_ssh_private_key_indent_4" = indent(4, var.param__gitops_ssh_private_key)
      }
    )
  )

  # Ensure execution order
  depends_on = [ helm_release.argocd ]
}

resource "kubernetes_manifest" "argocd_root_application" {

  count = var.param__post_eks_apply ? 1 : 0

  # This is to bootstrap the Cluster with ArgoCD
  # by applying the Root Application manifest and following the App-of-Apps pattern
  # 

  manifest = yamldecode(
    templatefile(
      "${path.module}/helm/argocd-root-app.yaml.tftpl",
      {
        "environment" = var.env
      }
    )
  )

  # Ensure execution order
  depends_on = [ kubernetes_manifest.argocd_repository ]
}

