---
name: codex
description: |
  Codex CLI 호출 스킬.
  트리거: "codex로", "codex 써서", "codex한테", "with codex", "use codex"

  암시적 트리거 (자동 제안):
  - PR/GitHub: "PR 만들어", "커밋하고 푸시", "create PR", "commit and push"
  - 실행/테스트: "테스트 돌려", "빌드해", "run tests", "build"
  - 완료 지향: "끝까지 해", "완성해", "finish it", "complete this"
  - 리팩터링: "리팩터", "성능 개선", "최적화", "refactor", "optimize"
  - 디버깅: "버그 잡아", "재현해봐", "fix bug", "debug"
  - 마이그레이션: "버전 올려", "의존성 업데이트", "upgrade", "migrate"
  - CI: "GitHub Actions", "CI 깨짐", "파이프라인 고쳐"

  비권장 상황 (→ Gemini 사용):
  - 이미지/동영상/PDF 분석
  - 대규모 파일/변경 범위 (100K+ 토큰)
  - 외부 출처/웹 검색 필요
  - PR 리뷰 (읽기 전용 분석)
allowed-tools: Bash
---

# Codex Skill

OpenAI Codex CLI를 비인터랙티브 모드로 호출합니다.

## 기본 설정

| 설정 | 값 | CLI 옵션 | 설명 |
|------|-----|----------|------|
| model | `gpt-5.2-codex` | `--model` | 가장 진보된 에이전틱 코딩 모델 |
| sandbox | `danger-full-access` | `--sandbox` | 전체 시스템 접근 (최대 자율성) |
| approval | `never` | `-c approval=` | 승인 없이 자동 실행 |
| reasoningEffort | `xhigh` | `-c reasoningEffort=` | 최대 추론 깊이 |
| search | `false` | `--search` | 웹 검색 (필요시만 활성화) |

## 실행 명령어

```bash
codex exec \
  --model gpt-5.2-codex \
  --sandbox danger-full-access \
  -c approval=never \
  -c reasoningEffort=xhigh \
  "<프롬프트>"
```

## 자동 제안 트리거

Codex는 다음 상황에서 자동으로 제안됩니다:

### PR/GitHub 워크플로우 (HIGH CONFIDENCE)
| 한국어 | English |
|--------|---------|
| PR 만들어, PR 생성 | create PR, pull request |
| 커밋하고 푸시 | commit and push |

> **참고**: PR 리뷰(읽기 전용 분석)는 Gemini가 Long Context Window로 더 적합

### 실행/테스트 (HIGH CONFIDENCE)
| 한국어 | English |
|--------|---------|
| 테스트 돌려, 테스트 실행 | run tests, execute tests |
| 빌드해, 컴파일 | build, compile |
| 린트 수정, 타입체크 | fix lint, typecheck |

### 완료 지향 작업 (HIGH CONFIDENCE)
| 한국어 | English |
|--------|---------|
| 끝까지 해, 완성해 | finish it, complete this |
| 알아서 처리, 자동으로 다 | get it done, all the way |

### 리팩터링/성능 (Codex 추가 제안)
| 한국어 | English |
|--------|---------|
| 리팩터, 성능 개선 | refactor, optimize |
| 최적화, 메모리/속도 이슈 | performance, memory issue |

### 디버깅/재현 (Codex 추가 제안)
| 한국어 | English |
|--------|---------|
| 버그 잡아, 재현해봐 | fix bug, debug |
| 스택트레이스 보고 수정 | fix from stacktrace |

### 마이그레이션/CI (Codex 추가 제안)
| 한국어 | English |
|--------|---------|
| 버전 올려, 의존성 업데이트 | upgrade, update dependencies |
| GitHub Actions, CI 깨짐 | fix CI, pipeline broken |
| 릴리스 준비, 버전 태그 | release prep, version tag |

## 비권장 상황 (안티패턴)

| 작업 유형 | 권장 도구 | 이유 |
|----------|----------|------|
| 이미지/PDF 분석 | Gemini | Codex는 멀티모달 미지원 |
| 대규모 파일/변경 범위 | Gemini | Gemini 1M 토큰 지원 |
| **외부** 출처/웹 검색 | Gemini | Google Search 그라운딩 (내부 리포 검색은 Codex 가능) |
| **PR 리뷰 (읽기 분석)** | Gemini | Long Context Window 강점 |
| 단순 설명/질문 | Claude | 실행 불필요 |
| 설명/보고서 중심 요청 | Gemini | Codex는 실행에 집중 |

## 사용 가능 모델

| 모델 | 설명 |
|------|------|
| gpt-5.2-codex | 가장 진보된 에이전틱 코딩 모델 (권장) |
| gpt-5.1-codex-max | 장기 에이전틱 코딩 최적화 |
| gpt-5.1-codex-mini | 비용 효율적 소형 모델 |

## 옵션 참조

| 옵션 | 값 | 설명 |
|------|-----|------|
| `-m, --model` | string | 사용할 모델 |
| `-s, --sandbox` | read-only, workspace-write, danger-full-access | 샌드박스 정책 |
| `-c approval=` | untrusted, on-failure, on-request, never | 승인 정책 |
| `-c reasoningEffort=` | none, low, medium, high, xhigh | 추론 깊이 |
| `--search` | - | 웹 검색 활성화 |

## 사용 예시

```bash
# 기본 실행
codex exec \
  --model gpt-5.2-codex \
  --sandbox danger-full-access \
  -c approval=never \
  -c reasoningEffort=xhigh \
  "Create a REST API for user management"

# 웹 검색 활성화 (최신 문서/API 정보 필요 시)
codex exec \
  --model gpt-5.2-codex \
  --sandbox danger-full-access \
  -c approval=never \
  -c reasoningEffort=xhigh \
  --search \
  "Integrate the latest Stripe API"
```

## 핸드오프 패턴

> **역할 정의**: Codex = "Builder(구현자)" - 실행-수정-검증 중심

### Codex → Gemini
- 구현 후 문서화가 필요할 때
- 실행 후 대용량 로그 분석이 필요할 때
- 실행-수정-검증 루프에서 막혔을 때 (실패 회복)

### Gemini → Codex
- 분석/설계 후 구현이 필요할 때
- 이미지/PDF 디자인을 코드로 구현할 때
- 검색 조사 후 개발이 필요할 때

### 실패 회복 흐름
Codex 실행 실패 → 에러 로그 수집 → Gemini 로그 분석 → 원인 진단 → Codex 재시도

## 에러 처리

| 에러 | 대응 |
|------|------|
| CLI 미설치 | 설치 안내: `npm install -g @openai/codex` |
| API 오류 | 오류 내용 사용자에게 전달 |
| 타임아웃 | 재시도 또는 프롬프트 단순화 제안 |
