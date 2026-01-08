# oh-my-claude-code

Claude Code를 메인 오케스트레이터로, 다양한 AI CLI를 서브 에이전트로 활용하는 플러그인 마켓플레이스입니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code                          │
│                 (메인 오케스트레이터)                     │
├─────────────────────────────────────────────────────────┤
│  plugins/                                               │
│  ├── claude-code/    → Claude Code 자체 기능 확장        │
│  ├── codex-cli/      → Codex CLI를 서브 에이전트로 호출   │
│  └── gemini-cli/     → Gemini CLI를 서브 에이전트로 호출  │
└─────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   [Claude Code]        [Codex CLI]         [Gemini CLI]
    직접 실행            Bash로 호출          Bash로 호출
```

## 플러그인 목록

| 플러그인 | 설명 | 버전 |
|---------|------|-----|
| claude-code | Claude Code 자체 기능 확장 | 1.0.0 |
| codex-cli | OpenAI Codex CLI 서브 에이전트 | 1.0.0 |
| gemini-cli | Google Gemini CLI 서브 에이전트 | 1.0.0 |

## 자연어 트리거

서브 에이전트를 자연어로 호출할 수 있습니다:

### Codex CLI
- "codex로 코드 생성해줘"
- "codex를 활용해서 함수 작성해"
- "코덱스한테 시켜"

### Gemini CLI
- "gemini로 리뷰해줘"
- "gemini한테 분석 맡겨"
- "제미나이 활용해서 검토해"

## 디렉토리 구조

```
oh-my-claude-code/
├── .claude-plugin/
│   └── marketplace.json          # 마켓플레이스 메타데이터
├── plugins/
│   ├── claude-code/              # Claude Code 관련 플러그인
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── config/
│   │   │   └── default.json
│   │   ├── commands/
│   │   ├── skills/
│   │   ├── agents/
│   │   └── hooks/
│   ├── codex-cli/                # OpenAI Codex CLI 서브 에이전트
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── config/
│   │   │   └── default.jsonc     # JSONC 형식 (주석 지원)
│   │   ├── commands/
│   │   ├── skills/
│   │   ├── agents/
│   │   └── hooks/
│   ├── gemini-cli/               # Google Gemini CLI 서브 에이전트
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── config/
│   │   │   └── default.jsonc     # JSONC 형식 (주석 지원)
│   │   ├── commands/
│   │   ├── skills/
│   │   ├── agents/
│   │   └── hooks/
│   └── shared/                   # 공유 유틸리티
│       └── utils/
│           └── collect-context.sh  # 프로젝트 컨텍스트 자동 수집
├── README.md
├── LICENSE
└── .gitignore
```

## 설치 방법

1. 저장소 클론
```bash
git clone https://github.com/your-username/oh-my-claude-code.git
```

2. Claude Code에서 플러그인 디렉토리로 등록
```bash
# Claude Code 설정에서 플러그인 경로 추가
```

## 명령어

### claude-code
- `/orchestrate` - 여러 AI CLI를 조합하여 복합 작업 수행
- `/status` - 서브 에이전트 상태 및 설정 확인

### codex-cli
- `/codex:generate` - Codex CLI로 코드 생성
- `/codex:complete` - Codex CLI로 코드 완성

### gemini-cli
- `/gemini:review` - Gemini CLI로 코드 리뷰
- `/gemini:analyze` - Gemini CLI로 코드 분석

## 기본 설정

### claude-code (`config/default.json`)
```json
{
  "model": {
    "name": "latest",
    "reasoning": "max"
  },
  "sandbox": {
    "enabled": false
  },
  "permissions": {
    "allowAll": true
  }
}
```

### codex-cli (`config/default.jsonc`)
```jsonc
{
  "model": {
    "name": "gpt-5.2-codex"
  },
  "execution": {
    "mode": "dangerously-bypass-approvals-and-sandbox",
    "sandbox": "danger-full-access",
    "approval": "never"
  }
}
```

### gemini-cli (`config/default.jsonc`)
```jsonc
{
  "model": {
    "name": "gemini-3-pro-preview"
  },
  "execution": {
    "approvalMode": "yolo",
    "sandbox": false
  },
  "output": {
    "format": "json"
  }
}
```

> **참고**: 상세 설정 옵션은 각 플러그인의 `config/default.jsonc` 파일을 참조하세요.

## Shared 유틸리티

`plugins/shared/utils/` 디렉토리에 공유 유틸리티가 포함되어 있습니다.

### collect-context.sh

프로젝트 컨텍스트를 자동으로 수집하는 스크립트입니다. Codex/Gemini CLI 호출 전에 실행하여 더 풍부한 컨텍스트를 제공합니다.

```bash
# 사용법
./plugins/shared/utils/collect-context.sh [PROJECT_ROOT] [OUTPUT_FILE]

# 예시
./plugins/shared/utils/collect-context.sh              # 현재 디렉토리
./plugins/shared/utils/collect-context.sh /path/to/project
./plugins/shared/utils/collect-context.sh . context.json
```

수집 항목:
- 프로젝트 타입 (nodejs, python, go, rust, java, swift)
- 언어 버전
- 프레임워크 (React, Vue, Django, FastAPI 등)
- 패키지 매니저
- 테스트 프레임워크
- 코딩 컨벤션 (ESLint, Prettier, Ruff 등)
- 디렉토리 구조

## Hooks 메커니즘

각 플러그인은 `hooks/hooks.json`을 통해 도구 호출 전후에 커스텀 동작을 정의할 수 있습니다.

### Hook 타입

| Hook | 설명 | 트리거 시점 |
|------|------|------------|
| `PreToolUse` | 도구 호출 전 실행 | 도구 실행 직전 |
| `PostToolUse` | 도구 호출 후 실행 | 도구 실행 완료 후 |

### 구조

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",           // 대상 도구 (정규식 지원)
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Pre-hook 실행'"
          }
        ]
      }
    ],
    "PostToolUse": [...]
  }
}
```

### 플러그인별 Hooks 예시

#### claude-code
- `PreToolUse`: Bash 호출 시 로깅
- `PostToolUse`: CLI 호출 완료 로깅

#### codex-cli
- `PreToolUse`: `codex` 명령어 포함 여부 필터링
- `PostToolUse`: 호출 로그 기록 (`logs/codex.log`)

#### gemini-cli
- `PreToolUse`: `gemini` 명령어 포함 여부 필터링
- `PostToolUse`: `Write|Edit` 도구 사용 시 재리뷰 권장 메시지

### 환경 변수

Hooks에서 사용 가능한 환경 변수:
- `$TOOL_INPUT`: 도구에 전달된 입력 데이터
- `$CLAUDE_PLUGIN_ROOT`: 플러그인 루트 디렉토리

## 기여 방법

1. Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
