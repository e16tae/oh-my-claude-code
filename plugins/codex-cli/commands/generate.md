---
description: Codex CLI로 코드 생성
---

# /codex:generate

Codex CLI를 호출하여 코드를 생성합니다.

## 사용법
```
/codex:generate [설명] [--lang=언어] [--profile=프로필]
```

## 예시
```
/codex:generate "JWT 인증 미들웨어" --lang=typescript
/codex:generate "정렬 알고리즘" --profile=quick
```

## 옵션

| 옵션 | 설명 | 기본값 |
|-----|------|-------|
| `--lang` | 생성할 코드 언어 | 프로젝트 감지 |
| `--profile` | 실행 프로필 | default |

## 출력
- 생성된 코드를 마크다운 코드 블록으로 표시
- 파일 적용 여부 확인
