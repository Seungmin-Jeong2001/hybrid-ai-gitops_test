variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for bucheongoyangijanggun.com"
  type        = string
}

resource "random_password" "tunnel_secret" {
  length  = 32
  special = false
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "eks_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "eks-gitops-tunnel"
  secret     = base64encode(random_password.tunnel_secret.result)
}

# DNS 레코드 설정: argocd.bucheongoyangijanggun.com
resource "cloudflare_record" "argocd" {
  zone_id = var.cloudflare_zone_id
  name    = "argocd"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.eks_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# DNS 레코드 설정: app.bucheongoyangijanggun.com
resource "cloudflare_record" "python_app" {
  zone_id = var.cloudflare_zone_id
  name    = "app"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.eks_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# 터널 구성 (Ingress Rules)
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "eks_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.eks_tunnel.id

  config {
    ingress_rule {
      hostname = "argocd.bucheongoyangijanggun.com"
      service  = "https://argocd-server.argocd.svc.cluster.local:443"
      origin_request {
        no_tls_verify = true # ArgoCD 자체 서명 인증서 허용
      }
    }
    ingress_rule {
      hostname = "app.bucheongoyangijanggun.com"
      service  = "http://hybrid-ai-app-service.default.svc.cluster.local:5000"
    }
    # 매치되지 않는 모든 요청은 404
    ingress_rule {
      service = "http_status:404"
    }
  }
}
