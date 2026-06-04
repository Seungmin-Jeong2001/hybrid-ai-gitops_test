module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "hybrid-gitops-eks"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access = true

  # OIDC 공급자 활성화 (IRSA 필수)
  enable_irsa = true

  # 로그 그룹 충돌 방지: 테라폼이 직접 생성하지 않도록 설정
  create_cloudwatch_log_group = false

  authentication_mode = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    web_nodes = {
      min_size     = 1
      max_size     = 5
      desired_size = 3 # t3.small 사용 시 Pod 수용량을 위해 3대 필수 (3대 x 11개 = 33개)

      # 이전에 성공했던 t3.small로 복구
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"

      # 스팟 에러 방지를 위해 온디맨드 사용
      capacity_type = "ON_DEMAND"

      # ECR 이미지 풀 권한을 명시적으로 추가
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }
    }
  }

  enable_cluster_creator_admin_permissions = true
}

# 1. ArgoCD Image Updater 전용 IAM Role 생성 (IRSA)
module "argocd_image_updater_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "argocd-image-updater-role"
  
  # Image Updater가 ECR의 태그 목록을 조회할 수 있는 권한 부여
  role_policy_arns = {
    policy = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["argocd:argocd-image-updater"]
    }
  }
}