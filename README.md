# landing-demo-iac

What is this?
* Infrastructure-as-Code to create AWS resources
* In addition, bootstraps the created EKS cluster with ArgoCD and the Root Application (following App-of-Apps pattern) - see eks_bootstrap.tf file

Note - since the Root Application ("kubernetes_manifest") depends on the EKS cluster available + ArgoCD installed. It will error out during plan phase.
Therefore, we need the `param__post_eks_apply` to determine whether the root application is deployed or not

Running sequence are as follows
```
1. Apply all resources excluding the Root Application

terraform plan -var-file=env/???.tfvars -var='param__post_eks_apply=false'
terraform apply -var-file=env/???.tfvars -var='param__post_eks_apply=false'

2. Afterwards, apply the Root Application to complete the bootstrapping

terraform plan -var-file=env/???.tfvars -var='param__post_eks_apply=true'
terraform apply -var-file=env/???.tfvars -var='param__post_eks_apply=true'
```

* References
    * https://github.com/hashicorp/terraform-provider-kubernetes/issues/1775
    * https://stackoverflow.com/questions/74861532/targeting-all-resources-exept-one-in-terraformthe-opposite-of-target-paramet