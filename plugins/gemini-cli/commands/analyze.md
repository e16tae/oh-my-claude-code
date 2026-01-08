---
description: Gemini CLI로 코드 분석
---

# /gemini:analyze

Gemini CLI를 호출하여 코드를 심층 분석합니다.

## 사용법
```
/gemini:analyze [대상] [--type=아키텍처|의존성|복잡도]
```

## 예시
```
/gemini:analyze src/ --type=아키텍처
/gemini:analyze package.json --type=의존성
```

## 옵션

| 옵션 | 설명 | 기본값 |
|-----|------|-------|
| `--type` | 분석 유형 | 전체 |

## 분석 유형

### 아키텍처 분석
- 모듈 구조 파악
- 의존성 그래프 시각화
- 레이어 분리 상태

### 의존성 분석
- 외부 패키지 의존성
- 버전 호환성 검사
- 보안 취약점 탐지

### 복잡도 분석
- 순환 복잡도 측정
- 코드 중복 탐지
- 유지보수성 지표
