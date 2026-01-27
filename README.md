## Project Overview

- 멀티 노드 Kubernetes 클러스터 구성
- 애플리케이션 컨테이너화
- 이미지 빌드 및 레지스트리 푸시 자동화
- Kubernetes Deployment를 통한 롤링 업데이트

---

## Architecture & Flow

### 전체 구성 흐름

![스크린샷 2026-01-27 19.39.25.png](attachment:edac945e-b953-4b24-be52-3e8a6ab6be92:스크린샷_2026-01-27_19.39.25.png)

---

## CI/CD Flow Detail

1. **코드 변경**
   - React(Vite) 애플리케이션 소스 수정
   - `main` 브랜치에 push 또는 태그(`v*`) 생성
2. **CI (Build & Push)**
   - GitHub Actions 워크플로우 트리거
   - Dockerfile을 기반으로 이미지 빌드
   - Docker Hub에 이미지 자동 push
3. **CD (Deploy to Kubernetes)**
   - Self-hosted Runner에서 `kubectl` 실행
   - 기존 Deployment의 이미지 업데이트
   - Kubernetes가 Rolling Update 수행
4. **Service Exposure**
   - Deployment → Pod 생성
   - NodePort Service를 통해 외부 접근 가능
   - 브라우저에서 React 애플리케이션 확인

---

## 구조

- **Deployment 사용**
  - Pod 자동 복구(Self-healing)
  - 무중단 롤링 업데이트 지원
  - Replica 확장 가능
- **Nginx 기반 정적 서빙**
  - React 빌드 결과물에 최적화
  - 가볍고 안정적인 런타임
- **Self-hosted GitHub Actions Runner**
  - Kubernetes 클러스터 내부 접근 필요
  - `kubectl`, Docker 데몬 직접 제어 가능
