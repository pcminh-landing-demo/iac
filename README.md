# landing-demo-iac

What is this?
* Infrastructure-as-Code to create AWS resources
* In addition, bootstraps the created EKS cluster with ArgoCD and the Root Application (following App-of-Apps pattern) - see eks_bootstrap.tf file

Note - since the Root Application ("kubernetes_manifest") depends on the EKS cluster available + ArgoCD installed. It will error out during plan phase.
Therefore, we need the `post_eks_apply` to determine whether the root application is deployed or not

Ensure the TF Variable `gitops_ssh_private_key` has the SSH Private Key that was whitelisted in the GitOps artifacts repository:

1. Using TFVARS file, do not commit
```
# privatekey.tfvars
gitops_ssh_private_key = <<EOT
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
EOT

# ^^^ Make sure to put trailing new line, TF has parsing bug
```

2. By setting as Environment Variable (or GitHub Actions secret)
```sh
export TF_VAR_gitops_ssh_private_key = <<EOT
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
EOT
```


The execution sequence are as follows

1. Apply all resources excluding the Root Application
```sh
terraform plan -var-file=env/dev.tfvars -var-file=env/privatekey.tfvars -var='post_eks_apply=false'
terraform apply -var-file=env/dev.tfvars -var-file=env/privatekey.tfvars -var='post_eks_apply=false'
```

2. Afterwards, apply the Root Application to complete the bootstrapping
```sh
terraform plan -var-file=env/dev.tfvars -var='post_eks_apply=true'
terraform apply -var-file=env/dev.tfvars -var='post_eks_apply=true'
```

3. Destroy only Bootstrap resources (Kubernetes manifests and secrets) - Note: to reapply Bootstrap resources --> Run Step 2 again
```sh
terraform destroy -var-file=env/dev.tfvars --var-file=env/privatekey.tfvars -var='post_eks_apply=true' -target='kubernetes_secret.argocd_repository' -target='kubernetes_manifest.argocd_root_application'
```

4. Destroy All
```sh
terraform destroy -var-file=env/dev.tfvars --var-file=env/privatekey.tfvars -var='post_eks_apply=true'
```

* References
    * https://github.com/hashicorp/terraform-provider-kubernetes/issues/1775
    * https://stackoverflow.com/questions/74861532/targeting-all-resources-exept-one-in-terraformthe-opposite-of-target-paramet