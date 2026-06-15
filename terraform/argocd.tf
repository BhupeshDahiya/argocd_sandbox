# deploy argocd via helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.0.0"
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]

  depends_on = [aws_eks_node_group.argocd_sandbox]
}

data "kubernetes_secret" "argocd_password" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }

  depends_on = [helm_release.argocd]
}

output "argocd_username" {
  value = "admin"
}

output "argocd_password" {
  value     = data.kubernetes_secret.argocd_password.data["password"]
  sensitive = true
}

output "pass_output_cmd" {
  value = "terraform output -raw argocd_password"
}