output "cluster_name" {
  description = "생성된 EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "쿠버네티스 마스터 서버(API Server) 주소"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "EKS가 생성된 VPC ID"
  value       = module.vpc.vpc_id
}

output "kubectl_connect_command" {
  description = "WSL에서 이 클러스터에 접속하기 위한 명령어"
  value       = "aws eks update-kubeconfig --region ap-northeast-2 --name ${module.eks.cluster_name}"
}

output "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel 접속을 위한 인증 토큰"
  value       = cloudflare_zero_trust_tunnel_cloudflared.eks_tunnel.tunnel_token
  sensitive   = true
}