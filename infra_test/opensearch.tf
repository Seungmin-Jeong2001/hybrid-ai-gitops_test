resource "aws_opensearch_domain" "low_cost_search" {
  domain_name    = "hybrid-gitops-search"
  engine_version = "OpenSearch_2.11" # 최신 버전 권장

  cluster_config {
    # 비용 최소화를 위해 인스턴스 1대만 사용 (Single-AZ)
    instance_type          = "t3.small.search"
    instance_count         = 1
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10 # 최소 용량으로 시작
    volume_type = "gp3" # gp2보다 저렴하고 성능 조정 가능
  }

  # 개발용이므로 공인 인터넷 접근 대신 VPC 내부에서만 접근하도록 설정하는 것이 보안/비용 면에서 좋으나,
  # 여기서는 기본 비용 최적화에 집중함
  
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # 액세스 정책 (VPC 내부 IP 등 실제 환경에 맞게 조정 필요)
  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/hybrid-gitops-search/*"
        }
    ]
}
CONFIG

  tags = {
    Environment = "test"
    CostCenter  = "dev"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
