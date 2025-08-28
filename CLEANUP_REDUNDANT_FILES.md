# 🧹 중복 파일 정리 가이드

## 📋 현재 중복/정리 필요 파일 목록

### 1. 🐳 Docker 관련 파일들 (중복)
**루트 디렉토리:**
- `/docker-compose.yml` - 구버전, 제거 필요
- `/Dockerfile` - 구버전, 제거 필요

**실제 사용 중인 파일들 (유지):**
- `/olist-pipeline/docker/docker-compose.improved.yml` ✅ (현재 사용 중)
- `/olist-pipeline/docker/docker-compose.local.yml` (로컬 참조용)
- `/olist-pipeline/docker/docker-compose.aws.yml` (AWS 배포용)

### 2. 📦 Requirements 파일들
**루트 디렉토리:**
- `/requirements.txt` - 구버전, 제거 필요

**실제 사용 중인 파일들 (유지):**
- `/olist-pipeline/tests/requirements-test.txt` ✅ (테스트용)

### 3. 📚 문서 파일들
**루트 디렉토리 (유지):**
- `/README.md` ✅ - 프로젝트 메인 README
- `/README.ko.md` ✅ - 한국어 버전
- `/README-Roadmap.md` ✅ - 로드맵 문서
- `/SDS.md` ✅ - Software Design Specification
- `/SDS.ko.md` ✅ - SDS 한국어 버전

**olist-pipeline 디렉토리 (유지):**
- `/olist-pipeline/README.md` ✅ - 파이프라인 전용 문서
- 기타 모든 가이드 문서들 ✅

### 4. 🗑️ Cache 디렉토리들 (제거 가능)
- `/.pytest_cache/` - 루트의 pytest 캐시
- `/olist-pipeline/.pytest_cache/` - 파이프라인 pytest 캐시
- `/olist-pipeline/tests/.pytest_cache/` - 테스트 pytest 캐시

### 5. 🔧 기타 파일들
- `/mc` - MinIO 클라이언트 바이너리 (29MB), 필요없으면 제거 가능
- `/.DS_Store` - macOS 시스템 파일, .gitignore에 추가 필요

## 🧹 정리 명령어

### 1단계: 백업 생성 (선택사항)
```bash
# 백업 디렉토리 생성
mkdir -p ~/Desktop/e-commerce_backup
cp docker-compose.yml Dockerfile requirements.txt ~/Desktop/e-commerce_backup/
```

### 2단계: 중복 파일 제거
```bash
# 루트의 구버전 Docker 파일들 제거
rm -f docker-compose.yml
rm -f Dockerfile
rm -f requirements.txt

# pytest 캐시 제거
rm -rf .pytest_cache/
rm -rf olist-pipeline/.pytest_cache/
rm -rf olist-pipeline/tests/.pytest_cache/

# MinIO 클라이언트 제거 (필요없다면)
rm -f mc

# macOS 시스템 파일 제거
find . -name ".DS_Store" -type f -delete
```

### 3단계: .gitignore 업데이트
```bash
# .gitignore에 추가
echo ".DS_Store" >> .gitignore
echo ".pytest_cache/" >> .gitignore
echo "__pycache__/" >> .gitignore
echo "*.pyc" >> .gitignore
echo ".env" >> .gitignore
echo "mc" >> .gitignore
```

## 📁 정리 후 구조

```
e-commerce_data_project/
├── README.md                          ✅ (메인 프로젝트 문서)
├── README.ko.md                       ✅
├── README-Roadmap.md                  ✅
├── SDS.md                            ✅
├── SDS.ko.md                         ✅
├── .gitignore                        ✅ (업데이트됨)
├── data/                             ✅
├── docs/                             ✅
├── olist-pipeline/                   ✅
│   ├── README.md                     ✅ (파이프라인 문서)
│   ├── docker/                       ✅
│   │   ├── docker-compose.improved.yml ✅ (실제 사용)
│   │   ├── docker-compose.local.yml   ✅
│   │   └── docker-compose.aws.yml     ✅
│   ├── dag/                          ✅
│   ├── sql/                          ✅
│   ├── tests/                        ✅
│   └── 기타 문서들                    ✅
├── e-commerce/                       ✅ (가상환경)
├── infra/                            ✅
└── deploy/                           ✅
```

## ⚠️ 주의사항

1. **삭제 전 확인**: 정말로 필요없는 파일인지 확인
2. **백업 권장**: 중요한 파일은 백업 후 삭제
3. **팀 공유**: 다른 팀원이 사용 중일 수 있으니 확인
4. **.env 파일**: 절대 git에 커밋하지 마세요

## 🎯 정리 효과

- **디스크 공간 절약**: ~30MB (mc 파일 제거 시)
- **프로젝트 구조 명확화**: 중복 제거로 혼란 방지
- **유지보수 향상**: 실제 사용 파일만 관리

정리를 진행하시겠습니까?
