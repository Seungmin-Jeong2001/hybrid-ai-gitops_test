resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "6.7.11"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # EKS 클러스터가 완전히 준비된 후 설치되도록 보장
  depends_on = [module.eks]
}