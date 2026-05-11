
---

# 🛠️ Hybrid AI Bridge: WSL2 Sandbox Setup Guide

---

## 📦 1. 필수 도구 및 설치 방법 (Prerequisites)

파이프라인 스크립트 실행 및 이미지 빌드/보안 검사에 필요한 핵심 도구들을 설치합니다.

### ① 시스템 업데이트 및 기본 도구
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install wget apt-transport-https gnupg lsb-release unzip -y
```

### ② yq (v4.x) - YAML 편집기
GitOps 파이프라인에서 Kubernetes 매니페스트의 이미지 태그를 자동 수정하기 위해 사용합니다.
```bash
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
yq --version # 설치 확인
```

### ③ Trivy (v0.49.1 이상) - 보안 스캔
컨테이너 이미지를 AWS ECR로 푸시하기 전, 취약점을 검사하여 보안 사고를 방지합니다.
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
```

### ④ AWS CLI (v2) - ECR 연동
AWS 리소스와 통신하고 자격 증명을 관리합니다.
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws --version
aws configure # IAM Access Key, Secret Key, Region 입력 필요
```

---

## 🏃 2. GitLab Runner 로컬 환경 구축 (WSL)

오픈스택 VM 내부에서 돌아갈 '작업 엔진'을 로컬에서 시뮬레이션하기 위해 프로젝트 폴더 내부에 설정을 구성합니다.

### ① 설정 디렉토리 생성 및 컨테이너 가동
```bash
# 1. 프로젝트 루트에서 설정 저장용 디렉토리 생성
mkdir -p ./runner-config

# 2. 러너 컨테이너 가동 (로컬 경로 바인딩 및 Docker 소켓 연결)
docker run -d --name gitlab-runner --restart always \
  -v $(pwd)/runner-config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
```

### ② 정보 보안 설정 (Git 유출 방지)
```bash
# .gitignore 파일에 설정 폴더 추가
echo "runner-config/" >> .gitignore
```

---

## 🔗 3. GitLab Runner 등록 (Registration)

GitLab(본부)과 Runner(일꾼)를 연결하는 작업입니다.

### ① 준비: Token 발급 (GitLab 웹)
1. GitLab 프로젝트 → `Settings` → `CI/CD` → `Runners` 이동
2. `New project runner` 버튼 클릭
3. **Tags**에 `wsl`, `kaniko`, `bridge` 등 입력 후 생성
4. 화면에 나타나는 **URL**과 **Registration Token** 복사

### ② 실행: 러너 등록 (터미널)
```bash
docker exec -it gitlab-runner gitlab-runner register
```
명령어 실행 시 나타나는 프롬프트에 아래와 같이 입력합니다:

| 질문 항목 | 입력 값 및 설명 |
| :--- | :--- |
| **GitLab instance URL** | `https://gitlab.com/`  |
| **Registration token** | 웹에서 복사한 토큰 입력 |
| **Description** | `wsl-bridge-worker` (식별용 이름) |
| **Tags** | `wsl, kaniko` 등을 적용(후에 실제 작업에는 태그 설정을 변경) |
| **Executor** | **`docker`**  |
| **Default Docker image** | `docker:24.0.5` 또는 `ubuntu:latest` |


---

## 🔑 4. CI/CD Variables 마스터 테이블 (비밀 열쇠 등록)

보안이 중요한 정보는 코드에 적지 않고 GitLab 웹 설정(`Settings > CI/CD > Variables`)에 등록하여 러너가 필요할 때만 꺼내 쓰도록 합니다. (모든 인증 정보는 **Masked** 처리 권장)

| Variable 명칭 | 설명 및 역할 | 획득 경로 / 비고 |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | AWS 계정 접근 아이디 | AWS IAM > 사용자 > 보안 자격 증명 |
| `AWS_SECRET_ACCESS_KEY` | AWS 계정 접근 비밀번호 | AWS IAM > 사용자 > 보안 자격 증명 |
| `AWS_DEFAULT_REGION` | ECR/SES 리전 (예: `ap-northeast-2`) | AWS 콘솔 확인 |
| `ECR_REPOSITORY_URI` | 이미지를 저장할 ECR의 전체 주소 | AWS ECR > 리포지토리 선택 > URI 복사 |
| `GITHUB_PAT` | GitHub 매니페스트 수정용 인증 토큰 | GitHub Settings > Developer settings > PAT |
| `SMTP_HOST` | AWS SES 엔드포인트 주소 | 예: `email-smtp.ap-northeast-2.amazonaws.com` |
| `SMTP_PORT` | 메일 서버 포트 | 보통 `587` 사용 |
| `SMTP_USER` | SES SMTP 발신용 아이디 | AWS SES SMTP 자격 증명 |
| `SMTP_PASSWORD` | SES SMTP 발신용 비밀번호 | AWS SES SMTP 자격 증명 |
| `MAIL_FROM` | 인증받은 발신용 이메일 주소 | AWS SES에서 인증 완료한 주소 |
| `MAIL_TO` | 알림을 받을 수신용 이메일 주소 | 수신 대상 (Sandbox 모드 시 인증 필수) |

---

## 📧 5. 이메일 알림 연동 가이드 (AWS SES)

AWS SES 사용을 위해 해야할 작업들은 현재
1. 이메일
2. DNS 설정(도메인) - Route53, Cloudflare record 설정
을 해줘야 하며

현재는 cloud flare record 로 작업 진행 중에 있습니다.

