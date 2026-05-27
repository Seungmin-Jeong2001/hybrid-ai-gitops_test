module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "hybrid-gitops-eks"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # 로그 그룹 충돌 방지: 테라폼이 직접 생성하지 않도록 설정
  create_cloudwatch_log_group = false

  authentication_mode = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    web_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2 # KServe 및 시스템 Pod들의 안정적 운영을 위해 2대 유지

      # t3.micro보다 메모리가 2배 많은 t3.small 사용 (2vCPU, 2GiB RAM)
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"

      # 비용 절감을 위해 스팟 인스턴스 유지
      capacity_type = "SPOT"

      # ECR 이미지 풀 권한을 명시적으로 추가
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
}