---
name: gemini
description: |
  Gemini CLI 호출 스킬.
  트리거: "gemini로", "gemini 써서", "gemini한테"
allowed-tools: Bash
---

# Gemini Skill

Google Gemini CLI를 비인터랙티브 모드로 호출합니다.

## 기본 설정

| 설정 | 값 | CLI 옵션 | 설명 |
|------|-----|----------|------|
| model | `gemini-3-pro-preview` | `--model` | 고도로 복잡한 추론 모델 |
| outputFormat | `text` | `--output-format` | 자연어 텍스트 출력 |
| yolo | `true` | `--yolo` | 권한 프롬프트 우회 |
| thinkingLevel | `high` | (CLI 미지원) | 최대 추론 깊이 |

## 실행 명령어

```bash
gemini \
  --model gemini-3-pro-preview \
  --output-format text \
  --yolo \
  "<프롬프트>"
```

## 사용 가능 모델

| 모델 | 설명 |
|------|------|
| gemini-3-pro-preview | 고도로 복잡한 추론 (권장) |
| gemini-2.5-pro | 1M 토큰 컨텍스트 |
| gemini-2.5-flash | 하이브리드 추론 모델 |
| gemini-2.0-flash | 빠른 응답 모델 |

## 옵션 참조

| 옵션 | 값 | 설명 |
|------|-----|------|
| `-m, --model` | string | 사용할 모델 |
| `-o, --output-format` | text, json, stream-json | 출력 형식 |
| `--yolo` | - | 권한 프롬프트 우회 |
| `--include-directories` | path,path,... | 포함할 디렉토리 |

## Thinking Level (참고)

| 값 | 설명 |
|----|------|
| minimal | 거의 추론 없음 (Flash 전용) |
| low | 최소 지연/비용 |
| medium | 균형 (Flash 전용) |
| high | 최대 추론 깊이 (기본, 권장) |

## 사용 예시

```bash
# 권장: 모든 설정 적용
gemini \
  --model gemini-3-pro-preview \
  --output-format text \
  --yolo \
  "Review this code for potential issues"

# 특정 디렉토리 포함
gemini \
  --model gemini-3-pro-preview \
  --include-directories /path/to/project \
  --yolo \
  "Analyze the architecture"

# JSON 출력 (파싱 필요 시)
gemini \
  --model gemini-3-pro-preview \
  --output-format json \
  --yolo \
  "List all functions in this file"
```

## 에러 처리

| 에러 | 대응 |
|------|------|
| CLI 미설치 | 설치 안내: `npm install -g @google/gemini-cli` |
| API 오류 | 오류 내용 사용자에게 전달 |
| 타임아웃 | 재시도 또는 프롬프트 단순화 제안 |
