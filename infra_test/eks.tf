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
      desired_size = 1 # 비용 절감을 위해 기본 1대로 축소
      
      # 가성비가 좋은 Graviton(ARM) 인스턴스 사용 (t3.small 대비 약 20% 저렴)
      instance_types = ["t4g.small"]
      ami_type       = "AL2023_ARM_64_STANDARD"
      
      # 스팟 인스턴스 사용 (온디맨드 대비 최대 70-90% 저렴)
      capacity_type = "SPOT"

      # ECR 이미지 풀 권한을 명시적으로 추가
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
}