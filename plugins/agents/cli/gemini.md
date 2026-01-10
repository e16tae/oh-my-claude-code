---
name: gemini
description: Gemini CLI 호출 방법
tools: Bash
config: config/gemini.jsonc
---

# Gemini CLI

## 호출 형식

```bash
gemini \
  --model <model> \
  --sandbox \
  "<prompt>"
```

## 옵션 설명

| 옵션 | 설명 | config 키 |
|------|------|-----------|
| --model | 사용할 모델 | model |
| --sandbox | 샌드박스 활성화 | sandbox |

## 사용 예시

```bash
gemini \
  --model gemini-2.5-pro \
  --sandbox \
  "Review this code for potential issues"
```
