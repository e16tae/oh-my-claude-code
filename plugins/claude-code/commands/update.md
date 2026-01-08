---
description: AI CLI 도구 설치 및 업데이트
---

# /update

서브 에이전트로 사용되는 AI CLI 도구들을 설치하거나 최신 버전으로 업데이트합니다.

## 사용법
```
/update [대상] [--check]
```

## 옵션

| 옵션 | 설명 |
|-----|------|
| `--check` | 설치 여부 및 버전만 확인 (업데이트 없이) |

## 대상

| 대상 | 설명 |
|-----|------|
| `all` | 모든 CLI 도구 업데이트 (기본값) |
| `codex` | Codex CLI만 업데이트 |
| `gemini` | Gemini CLI만 업데이트 |
| `claude` | Claude Code만 업데이트 |

## 예시
```
/update                    # 모든 도구 업데이트
/update --check            # 버전 확인만
/update codex              # Codex CLI만 업데이트
/update gemini --check     # Gemini CLI 버전 확인
```

## 실행 명령어

### 전체 업데이트
```bash
npm install -g @anthropic-ai/claude-code @openai/codex @google/gemini-cli
```

### 개별 업데이트
```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# Codex CLI
npm install -g @openai/codex

# Gemini CLI
npm install -g @google/gemini-cli
```

### 버전 확인
```bash
claude --version
codex --version
gemini --version
```

## 출력 예시

### 업데이트 성공
```
🔄 AI CLI 도구 업데이트

| 도구 | 이전 버전 | 현재 버전 | 상태 |
|-----|----------|----------|------|
| claude-code | 1.0.0 | 1.0.1 | ✅ 업데이트됨 |
| codex-cli | 0.9.0 | 0.9.0 | ⏸️ 최신 |
| gemini-cli | 2.0.0 | 2.1.0 | ✅ 업데이트됨 |

✅ 업데이트 완료
```

### 버전 확인
```
📊 AI CLI 도구 상태

| 도구 | 설치 상태 | 버전 |
|-----|----------|------|
| claude-code | ✅ 설치됨 | 1.0.1 |
| codex-cli | ✅ 설치됨 | 0.9.0 |
| gemini-cli | ❌ 미설치 | - |

💡 미설치 도구는 `/update` 명령으로 설치할 수 있습니다.
```

## 주의사항

- 전역 설치(`-g`)를 사용하므로 관리자 권한이 필요할 수 있습니다
- macOS/Linux에서 권한 오류 시: `sudo npm install -g ...`
- 패키지 이름은 실제 CLI 배포 이름에 따라 달라질 수 있습니다

## 패키지 이름 참고

실제 npm 패키지 이름은 공식 문서를 확인하세요:
- Claude Code: https://www.npmjs.com/package/@anthropic-ai/claude-code
- Codex CLI: https://www.npmjs.com/package/@openai/codex
- Gemini CLI: https://www.npmjs.com/package/@google/gemini-cli
