terraform {
  backend "s3" {
    bucket       = "arq3d-s3-backups-estado"
    key          = "terraform/k8s-argocd/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
