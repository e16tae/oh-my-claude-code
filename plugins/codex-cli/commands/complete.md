---
description: Codex CLI로 코드 완성
---

# /codex:complete

기존 코드의 빈 부분을 Codex CLI로 완성합니다.

## 사용법
```
/codex:complete [파일경로] [--context=추가컨텍스트]
```

## 예시
```
/codex:complete src/utils.ts
/codex:complete src/auth.ts --context="OAuth 2.0 플로우"
```

## 옵션

| 옵션 | 설명 | 기본값 |
|-----|------|-------|
| `--context` | 추가 컨텍스트 제공 | 없음 |

## 동작
1. 지정된 파일을 읽음
2. TODO, FIXME, 빈 함수 등 완성 필요 부분 탐지
3. Codex CLI로 코드 완성 요청
4. 결과 적용 여부 확인
