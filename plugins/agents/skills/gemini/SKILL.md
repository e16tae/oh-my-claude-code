---
name: gemini
description: |
  Gemini CLI 호출 스킬.
  트리거: "gemini로", "gemini 써서", "gemini한테", "with gemini", "use gemini"

  암시적 트리거 (자동 제안):
  - 멀티모달: "이미지 분석", "PDF 읽어", "analyze image", "analyze PDF"
  - 대용량 컨텍스트: "전체 코드베이스", "entire codebase"
  - 실시간 검색: "최신 정보", "출처 포함", "with sources"
  - 보안/아키텍처: "보안 점검", "아키텍처 리뷰", "취약점 찾아"
  - PR 리뷰: "PR 리뷰해", "코드 리뷰해", "review PR", "code review"
  - 번역/i18n: "번역해", "i18n 적용", "translate", "localize"

  Gemini는 범용 에이전트로 분석, 설계, 구현, 리뷰 등 모든 작업을 수행할 수 있습니다.
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

## 자동 제안 트리거

Gemini는 다음 상황에서 자동으로 제안됩니다:

### 멀티모달 입력 (HIGH CONFIDENCE - 자동 호출)
| 한국어 | English |
|--------|---------|
| 이미지 분석, 사진 분석 | analyze image, analyze photo |
| 스크린샷 분석 | analyze screenshot |
| 동영상/비디오 분석 | analyze video |
| PDF 분석, PDF 읽어 | analyze PDF, read PDF |
| 오디오 분석, 음성 분석 | analyze audio, transcribe |

**자동 감지 파일 확장자:**
- 이미지: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`
- 동영상: `.mp4`, `.mov`, `.avi`, `.webm`
- 오디오: `.mp3`, `.wav`, `.m4a`, `.ogg`
- 문서: `.pdf`

### 대용량 컨텍스트 (HIGH CONFIDENCE)
| 한국어 | English |
|--------|---------|
| 전체 코드베이스 | entire codebase |
| 대용량 파일, 긴 파일 | large file, very long file |
| 전체 로그 분석 | analyze full log |

**임계값:** 100KB 이상 파일 또는 100K+ 토큰

### 실시간 검색/그라운딩 (HIGH CONFIDENCE)
| 한국어 | English |
|--------|---------|
| 최신 정보, 최근 뉴스 | latest info, recent news |
| 출처 포함, 링크 포함 | with sources, include links |
| 실시간, 오늘 기준 | real-time, as of today |

### 보안/아키텍처 감사 (Gemini 추가 제안)
| 한국어 | English |
|--------|---------|
| 보안 점검해줘 | security audit |
| 아키텍처 리뷰해줘 | architecture review |
| 취약점 찾아줘 | find vulnerabilities |

> Gemini의 깊은 추론(thinkingLevel: high)으로 논리적 결함/구조적 문제 탐지에 최적

### PR 리뷰 (읽기 전용 분석) (Gemini 추가 제안)
| 한국어 | English |
|--------|---------|
| PR 리뷰해, 코드 리뷰해 | review PR, code review |
| 변경사항 분석 | analyze changes |

> Long Context Window로 변경된 파일 전체를 한번에 읽고 분석

### 번역/로컬라이제이션 (Gemini 추가 제안)
| 한국어 | English |
|--------|---------|
| 번역해줘, i18n 적용 | translate, localize |
| 영어로 번역 | translate to English |
| 한국어로 설명 | explain in Korean |

## 작업 영역

Gemini는 **범용 에이전트**로, 분석/설계뿐만 아니라 구현 작업도 수행할 수 있습니다.

**Gemini의 강점:**
- 멀티모달 입력 (이미지, PDF, 동영상, 오디오)
- 대용량 컨텍스트 처리 (1M 토큰)
- 실시간 웹 검색/그라운딩
- 깊은 추론이 필요한 복잡한 문제

> Gemini는 특정 역할에 국한되지 않습니다. 사용자 요청에 따라 분석, 설계, 구현, 리뷰 등 모든 작업을 수행할 수 있습니다.

## 모델

**반드시 `gemini-3-pro-preview` 모델을 사용합니다.** 다른 모델은 사용하지 않습니다.

## 옵션 참조

| 옵션 | 값 | 설명 |
|------|-----|------|
| `-m, --model` | string | 사용할 모델 |
| `-o, --output-format` | text, json, stream-json | 출력 형식 |
| `--yolo` | - | 권한 프롬프트 우회 |

## 추론 깊이

**반드시 `high` (최대 추론 깊이)를 사용합니다.** 낮은 추론 옵션은 사용하지 않습니다.

## 사용 예시

```bash
# 기본 실행
gemini \
  --model gemini-3-pro-preview \
  --output-format text \
  --yolo \
  "Review this code for potential issues"

# JSON 출력 (파싱 필요 시)
gemini \
  --model gemini-3-pro-preview \
  --output-format json \
  --yolo \
  "List all functions in this file"
```

## 협업 패턴 (선택적 가이드라인)

두 에이전트는 **범용적으로 사용 가능**하며, 아래는 협업이 유용할 수 있는 상황입니다:

### Gemini → Codex (선택적)
- Gemini가 처리할 수 없는 샌드박스 실행이 필요할 때
- Codex의 GitHub 통합이 필요할 때

### Codex → Gemini (선택적)
- Codex가 처리할 수 없는 멀티모달 입력이 있을 때
- 100K+ 토큰 대용량 분석이 필요할 때

> **중요**: 두 에이전트 모두 분석, 설계, 구현, 리뷰 등 모든 작업을 수행할 수 있습니다. 특정 역할에 국한하지 마세요.

## 에러 처리

| 에러 | 대응 |
|------|------|
| CLI 미설치 | 설치 안내: `npm install -g @google/gemini-cli` |
| API 오류 | 오류 내용 사용자에게 전달 |
| 타임아웃 | 재시도 또는 프롬프트 단순화 제안 |
