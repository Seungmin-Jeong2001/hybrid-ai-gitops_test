module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "gitops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # 비용 절감을 위해 NAT 게이트웨이 비활성화 (월 약 4.5만원 절감)
  enable_nat_gateway = false
  single_nat_gateway = false

  # 로드밸런서가 서브넷을 찾을 수 있게 해주는 필수 태그
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}
