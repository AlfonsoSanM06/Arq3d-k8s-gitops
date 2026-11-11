
# backend.tf — Configuración del backend de estado de Terraform.


terraform {
  backend "s3" {
    bucket       = "arq3d-s3-backups-estado"
    key          = "terraform/proxmox/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
