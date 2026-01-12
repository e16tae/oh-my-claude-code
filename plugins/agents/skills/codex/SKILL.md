---
name: codex
description: |
  Codex CLI 호출 스킬.
  트리거: "codex로", "codex 써서", "codex한테"
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

## 에러 처리

| 에러 | 대응 |
|------|------|
| CLI 미설치 | 설치 안내: `npm install -g @openai/codex` |
| API 오류 | 오류 내용 사용자에게 전달 |
| 타임아웃 | 재시도 또는 프롬프트 단순화 제안 |
