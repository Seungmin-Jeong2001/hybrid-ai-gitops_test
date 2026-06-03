terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    local      = { source = "hashicorp/local", version = "~> 2.0" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 4.0" }
    random     = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

provider "cloudflare" {
  # API Token은 환경 변수 CLOUDFLARE_API_TOKEN으로 주입받는 것을 권장합니다.
}
