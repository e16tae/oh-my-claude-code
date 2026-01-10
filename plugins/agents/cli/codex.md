---
name: codex
description: Codex CLI 호출 방법
tools: Bash
config: config/codex.jsonc
---

# Codex CLI

OpenAI Codex CLI를 비인터랙티브 모드로 호출합니다.

## 호출 형식

```bash
codex exec \
  --model <model> \
  --sandbox <sandbox> \
  --ask-for-approval <approval> \
  "<prompt>"
```

## 사용 가능 모델

| 모델 | 설명 |
|------|------|
| gpt-5.2-codex | 가장 진보된 에이전틱 코딩 모델 (권장) |
| gpt-5.1-codex-max | 장기 에이전틱 코딩 최적화 |
| gpt-5.1-codex-mini | 비용 효율적 소형 모델 |

## 옵션 설명

| 옵션 | 값 | 설명 | config 키 |
|------|-----|------|-----------|
| -m, --model | string | 사용할 모델 | model |
| -s, --sandbox | read-only, workspace-write, danger-full-access | 샌드박스 정책 | sandbox |
| -a, --ask-for-approval | untrusted, on-failure, on-request, never | 승인 정책 | approval |
| -C, --cd | path | 작업 디렉토리 | - |
| --full-auto | - | 저마찰 자동화 프리셋 | fullAuto |
| --search | - | 웹 검색 활성화 | search |

## Reasoning Effort (config.toml)

| 값 | 설명 |
|----|------|
| none | 추론 없음 (최저 지연) |
| low | 낮은 추론 |
| medium | 중간 추론 |
| high | 높은 추론 (기본) |
| xhigh | 초고 추론 (복잡한 작업에 권장) |

## 사용 예시

```bash
# 최고 성능 모델로 실행
codex exec \
  --model gpt-5.2-codex \
  --sandbox workspace-write \
  "Create a REST API for user management"

# 전체 자동화 모드
codex exec --full-auto "Fix the failing tests"

# 웹 검색 활성화 (최신 문서/API 정보 필요 시)
codex exec --search "Integrate the latest Stripe API"
```
