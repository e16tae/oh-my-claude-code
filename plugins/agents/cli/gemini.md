---
name: gemini
description: Gemini CLI 호출 방법
tools: Bash
config: config/gemini.jsonc
---

# Gemini CLI

Google Gemini CLI를 비인터랙티브 모드로 호출합니다.

## 호출 형식

```bash
gemini -p "<prompt>" \
  -m <model> \
  --output-format <format>
```

## 사용 가능 모델

| 모델 | 설명 |
|------|------|
| gemini-3-pro-preview | 고도로 복잡한 추론 (권장) |
| gemini-2.5-pro | 1M 토큰 컨텍스트 |
| gemini-2.5-flash | 하이브리드 추론 모델 |
| gemini-2.0-flash | 빠른 응답 모델 |

## 옵션 설명

| 옵션 | 값 | 설명 | config 키 |
|------|-----|------|-----------|
| -p | string | 프롬프트 (필수, 비인터랙티브) | - |
| -m | string | 사용할 모델 | model |
| --output-format | text, json, stream-json | 출력 형식 | outputFormat |
| --include-directories | path,path,... | 포함할 디렉토리 | - |
| --yolo | - | 권한 프롬프트 우회 | yolo |

## Thinking Level (Gemini 3)

| 값 | 설명 |
|----|------|
| minimal | 거의 추론 없음 (Flash 전용) |
| low | 최소 지연/비용 |
| medium | 균형 (Flash 전용) |
| high | 최대 추론 깊이 (기본, 권장) |

## 사용 예시

```bash
# 최고 추론 모델로 실행
gemini -p "Review this code for potential issues" \
  -m gemini-3-pro-preview

# JSON 출력
gemini -p "Analyze the architecture" \
  --output-format json

# 권한 프롬프트 우회
gemini -p "Refactor the codebase" --yolo

# 파이프 입력
cat file.py | gemini -p "Explain this code"
```
