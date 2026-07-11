resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  version          = "7.8.23"

  # Si el despliegue falla, Helm hace rollback automático
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = [file("values/argocd.yaml")]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.10.1"

  atomic          = true
  cleanup_on_fail = true
  timeout         = 300

  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "90Mi"
  }
}

# Bitnami Sealed Secrets Controller
# Permite almacenar Secrets cifrados en Git de forma segura.
# El controller descifra los SealedSecrets en tiempo real usando su clave privada.
# Documentación: https://github.com/bitnami-labs/sealed-secrets
resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  namespace  = "kube-system"
  version    = "2.16.1"

  atomic          = true
  cleanup_on_fail = true
  timeout         = 180

  set {
    name = "fullnameOverride"
    # Nombre fijo para que kubeseal pueda encontrarlo sin flags adicionales
    value = "sealed-secrets-controller"
  }
}
