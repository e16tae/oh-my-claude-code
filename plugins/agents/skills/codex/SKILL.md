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

  Codex는 범용 에이전트로 분석, 설계, 구현, 리뷰 등 모든 작업을 수행할 수 있습니다.
  (단, 멀티모달 입력은 Gemini를 사용하세요)
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

## 작업 영역

Codex는 **범용 에이전트**로, 구현뿐만 아니라 분석/설계 작업도 수행할 수 있습니다.

**Codex의 강점:**
- 샌드박스 실행 환경
- GitHub 통합 (PR 생성, 커밋)
- 실행-수정-검증 루프
- 최대 추론 깊이 (xhigh)

> Codex는 특정 역할에 국한되지 않습니다. 사용자 요청에 따라 분석, 설계, 구현, 리뷰 등 모든 작업을 수행할 수 있습니다.

**참고**: 멀티모달 입력(이미지, PDF 등)은 Codex에서 지원하지 않으므로 Gemini를 사용하세요.

## 모델

**반드시 `gpt-5.2-codex` 모델을 사용합니다.** 다른 모델은 사용하지 않습니다.

## 옵션 참조

| 옵션 | 값 | 설명 |
|------|-----|------|
| `-m, --model` | string | 사용할 모델 |
| `-s, --sandbox` | read-only, workspace-write, danger-full-access | 샌드박스 정책 |
| `-c approval=` | untrusted, on-failure, on-request, never | 승인 정책 |
| `-c reasoningEffort=` | xhigh | 추론 깊이 (반드시 xhigh 사용) |
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

## 협업 패턴 (선택적 가이드라인)

두 에이전트는 **범용적으로 사용 가능**하며, 아래는 협업이 유용할 수 있는 상황입니다:

### Codex → Gemini (선택적)
- Codex가 처리할 수 없는 멀티모달 입력이 있을 때
- 100K+ 토큰 대용량 분석이 필요할 때

### Gemini → Codex (선택적)
- Gemini가 처리할 수 없는 샌드박스 실행이 필요할 때
- Codex의 GitHub 통합이 필요할 때

> **중요**: 두 에이전트 모두 분석, 설계, 구현, 리뷰 등 모든 작업을 수행할 수 있습니다. 특정 역할에 국한하지 마세요.

## 에러 처리

| 에러 | 대응 |
|------|------|
| CLI 미설치 | 설치 안내: `npm install -g @openai/codex` |
| API 오류 | 오류 내용 사용자에게 전달 |
| 타임아웃 | 재시도 또는 프롬프트 단순화 제안 |
