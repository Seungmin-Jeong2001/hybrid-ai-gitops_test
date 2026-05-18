module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "hybrid-gitops-eks"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # API 서버에 외부에서 접속 가능하도록 설정 (ArgoCD 설치를 위해 필요)
  cluster_endpoint_public_access = true

  authentication_mode = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    web_nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t3.small"]
      ami_type       = "AL2023_x86_64_STANDARD"
    }
  }

  enable_cluster_creator_admin_permissions = true
}