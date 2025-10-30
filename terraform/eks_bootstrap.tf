# This runs after EKS is deployed to bootstrap K8s-native deployment tools

provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token = data.aws_eks_cluster_auth.cluster_auth.token
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

resource "kubernetes_secret" "argocd_repository" {
  
  count = var.post_eks_apply ? 1 : 0
  depends_on = [ helm_release.argocd ]

  metadata {
    name = "argocd-repo-gitops-artifacts"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type": "repository"
    }
  }

  data = {
    "type" = "git"
    "url" = "${var.gitops_repo_url}"
    "sshPrivateKey": "${var.gitops_ssh_private_key}"
  }

}

resource "kubernetes_manifest" "argocd_root_application" {

  count = var.post_eks_apply ? 1 : 0
  depends_on = [ kubernetes_secret.argocd_repository ]

  # This is to bootstrap the Cluster with ArgoCD
  # by applying the Root Application manifest and following the App-of-Apps pattern
  # 

  manifest = yamldecode(
    templatefile(
      "${path.module}/helm/argocd-root-app.yaml.tftpl",
      {
        "environment" = var.env
        "gitops_repo_url" = var.gitops_repo_url
        "gitops_repo_path" = var.gitops_repo_path
      }
    )
  )

}

