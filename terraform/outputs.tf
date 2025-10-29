output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}
