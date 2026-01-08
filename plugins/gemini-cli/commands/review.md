---
description: Gemini CLI로 코드 리뷰
---

# /gemini:review

Gemini CLI를 호출하여 코드를 리뷰합니다.

## 사용법
```
/gemini:review [파일/디렉토리] [--focus=보안|성능|품질]
```

## 예시
```
/gemini:review src/auth.ts --focus=보안
/gemini:review . --focus=품질
```

## 옵션

| 옵션 | 설명 | 기본값 |
|-----|------|-------|
| `--focus` | 리뷰 초점 (보안/성능/품질) | 전체 |

## 출력
- 심각도별 이슈 분류 (Critical, Warning, Info)
- 구체적인 개선 제안
- 자동 수정 가능 항목 표시
