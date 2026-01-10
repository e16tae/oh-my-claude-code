---
name: codex
description: |
  Codex CLI 호출 스킬.
  트리거: "codex로", "codex 써서", "codex한테"
allowed-tools: Bash, Read, Write, Glob, Grep
cli: cli/codex.md
---

# Codex Skill

사용자가 "codex로", "codex 써서" 등 명시적으로 요청할 때 활성화됩니다.

## 실행 흐름

1. cli/codex.md에서 호출 형식 확인
2. config/codex.jsonc에서 파라미터 로드
3. CLI 실행
4. 결과 반환

## 에러 처리

| 에러 | 대응 |
|------|------|
| CLI 미설치 | 설치 안내: `npm install -g @openai/codex` |
| API 오류 | 오류 내용 사용자에게 전달 |
| 타임아웃 | 재시도 또는 프롬프트 단순화 제안 |
