---
name: codex
description: Codex CLI 호출 방법
tools: Bash
config: config/codex.jsonc
---

# Codex CLI

## 호출 형식

```bash
codex exec \
  --model <model> \
  --sandbox <sandbox> \
  --ask-for-approval <approval> \
  "<prompt>"
```

## 옵션 설명

| 옵션 | 설명 | config 키 |
|------|------|-----------|
| --model | 사용할 모델 | model |
| --sandbox | 샌드박스 모드 | sandbox |
| --ask-for-approval | 승인 정책 | approval |

## 사용 예시

```bash
codex exec \
  --model gpt-5.2-codex \
  --sandbox workspace-write \
  "Create a REST API for user management"
```
