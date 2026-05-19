resource "null_resource" "cleanup_k8s_resources" {
  # 이 리소스는 삭제될 때(destroy) 동작합니다.
  # Terraform destroy 명령 시 EKS 클러스터가 삭제되기 전에 실행되어
  # 쿠버네티스가 생성한 AWS 리소스(LoadBalancer, Security Groups 등)를 먼저 정리합니다.
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      echo "Starting cleanup of Kubernetes-managed resources..."

      # 1. EKS 접속 정보 갱신
      aws eks update-kubeconfig --region ap-northeast-2 --name hybrid-gitops-eks

      # 2. LoadBalancer 타입의 서비스 및 Ingress 삭제
      # 서비스(ELB/NLB) 및 인그레스(ALB)가 VPC 삭제를 차단하는 것을 방지합니다.
      echo "Deleting all Services of type LoadBalancer and all Ingresses..."
      if command -v jq &> /dev/null; then
        kubectl get svc --all-namespaces -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | .metadata.namespace + "/" + .metadata.name' | xargs -I {} kubectl delete svc {} --ignore-not-found=true
      else
        echo "jq not found, skipping specific LoadBalancer deletion."
      fi
      kubectl delete ingress --all-namespaces --all --ignore-not-found=true

      # 3. ArgoCD 네임스페이스 삭제
      echo "Deleting argocd namespace..."
      kubectl delete namespace argocd --ignore-not-found=true

      # 4. 로드밸런서 및 관련 리소스(ENI)가 AWS에서 완전히 제거될 때까지 대기
      # 보통 ELB 삭제에는 2-3분이 소요될 수 있습니다. 60초는 부족할 수 있어 120초로 연장합니다.
      echo "Waiting for AWS to release LoadBalancer resources (120s)..."
      sleep 120

      echo "Cleanup provisioner finished."
    EOT
  }

  # EKS 클러스터가 있어야 명령을 실행할 수 있으므로 의존성 설정
  # destroy 시에는 cleanup_k8s_resources -> module.eks -> module.vpc 순서로 삭제됩니다.
  depends_on = [module.eks]
}
