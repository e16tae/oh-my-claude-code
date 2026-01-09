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

| 플러그인 | 설명 | 버전 | 카테고리 |
|---------|------|-----|----------|
| claude-code | Claude Code 자체 기능 확장 | 1.0.0 | orchestration, utility |
| codex-cli | OpenAI Codex CLI 서브 에이전트 | 1.0.0 | ai-agent, code-generation |
| gemini-cli | Google Gemini CLI 서브 에이전트 | 1.0.0 | ai-agent, code-review |

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

## 명령어

### claude-code (오케스트레이션)
| 명령어 | 설명 |
|-------|------|
| `/orchestrate` | 여러 AI CLI를 조합하여 복합 작업 수행 |
| `/status` | 서브 에이전트 상태 및 설정 확인 |
| `/update` | AI CLI 도구 설치 및 업데이트 |

### 마켓플레이스 (v2.0)
| 명령어 | 설명 |
|-------|------|
| `/plugin:install` | 원격 소스에서 플러그인 설치 |
| `/plugin:version` | 플러그인 버전 관리 |
| `/plugin:deps` | 플러그인 의존성 관리 |
| `/plugin:search` | 레지스트리에서 플러그인 검색 |
| `/plugin:validate` | 플러그인 구조 및 무결성 검증 |

### codex-cli
| 명령어 | 설명 |
|-------|------|
| `/codex:generate` | Codex CLI로 코드 생성 |
| `/codex:complete` | Codex CLI로 코드 완성 |

### gemini-cli
| 명령어 | 설명 |
|-------|------|
| `/gemini:review` | Gemini CLI로 코드 리뷰 |
| `/gemini:analyze` | Gemini CLI로 코드 분석 |

## 설치 방법

### 1. Marketplace 등록
```bash
/plugin marketplace add your-username/oh-my-claude-code
```

### 2. 플러그인 설치

#### 레지스트리에서 설치
```bash
/plugin:install codex-cli
/plugin:install gemini-cli
```

#### GitHub에서 설치
```bash
/plugin:install github:username/my-plugin@v1.0.0
```

#### 로컬 테스트
```bash
/plugin marketplace add ./
/plugin install codex-cli@oh-my-claude-code
```

### 3. 바로 사용
설치 후 자연어로 바로 사용할 수 있습니다:
```
"codex로 피보나치 함수 만들어줘"
"gemini로 이 코드 리뷰해줘"
```

## 디렉토리 구조

```
oh-my-claude-code/
├── .claude-plugin/
│   └── marketplace.json          # 마켓플레이스 메타데이터 (v2.0)
├── schemas/                      # JSON 스키마 정의
│   ├── plugin-v2.schema.json
│   ├── marketplace-v2.schema.json
│   ├── lock-v1.schema.json
│   └── registry-v1.schema.json
├── plugins/
│   ├── claude-code/              # Claude Code 관련 플러그인
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── config/
│   │   ├── commands/
│   │   ├── skills/
│   │   ├── agents/
│   │   └── hooks/
│   ├── codex-cli/                # OpenAI Codex CLI 서브 에이전트
│   ├── gemini-cli/               # Google Gemini CLI 서브 에이전트
│   └── shared/                   # 공유 유틸리티
│       └── utils/
│           ├── collect-context.sh    # 프로젝트 컨텍스트 수집
│           ├── integrity-checker.sh  # 무결성 검증
│           ├── plugin-validator.sh   # 플러그인 검증
│           ├── version-resolver.sh   # Semver 버전 해석
│           ├── registry-client.sh    # 레지스트리 클라이언트
│           ├── github-handler.sh     # GitHub 소스 처리
│           └── dep-resolver.sh       # 의존성 해결
├── README.md
├── LICENSE
└── .gitignore
```

## 플러그인 스키마 (v2.0)

### plugin.json
```json
{
  "$schema": "../../../schemas/plugin-v2.schema.json",
  "schemaVersion": "2.0.0",
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "플러그인 설명",
  "author": {
    "name": "username",
    "url": "https://github.com/username"
  },
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "categories": ["ai-agent", "code-generation"],
  "dependencies": {
    "claude-code": "^1.0.0"
  },
  "permissions": {
    "required": ["Bash", "Read", "Write"],
    "optional": ["WebSearch"]
  }
}
```

### 지원 카테고리
- `ai-agent` - AI CLI 통합
- `code-generation` - 코드 생성 도구
- `code-review` - 코드 리뷰 및 분석
- `orchestration` - 멀티 에이전트 오케스트레이션
- `testing` - 테스트 자동화
- `documentation` - 문서 생성
- `security` - 보안 검사
- `utility` - 유틸리티 도구

## Shared 유틸리티

`plugins/shared/utils/` 디렉토리에 공유 유틸리티가 포함되어 있습니다.

### collect-context.sh
프로젝트 컨텍스트를 자동으로 수집합니다.

```bash
./plugins/shared/utils/collect-context.sh [PROJECT_ROOT] [OUTPUT_FILE]
```

### integrity-checker.sh
플러그인 무결성을 검증합니다.

```bash
source plugins/shared/utils/integrity-checker.sh
generate_hash /path/to/file
verify_hash /path/to/file expected_hash
```

### version-resolver.sh
Semver 버전을 해석하고 비교합니다.

```bash
source plugins/shared/utils/version-resolver.sh
semver_compare "1.2.0" "1.10.0"   # -1
semver_satisfies "1.5.0" "^1.0.0" # 0 (true)
```

### plugin-validator.sh
플러그인 구조와 보안을 검증합니다.

```bash
source plugins/shared/utils/plugin-validator.sh
validate_plugin ./plugins/codex-cli --strict
```

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

## Hooks 메커니즘

각 플러그인은 `hooks/hooks.json`을 통해 도구 호출 전후에 커스텀 동작을 정의할 수 있습니다.

### Hook 타입

| Hook | 설명 | 트리거 시점 |
|------|------|------------|
| `PreToolUse` | 도구 호출 전 실행 | 도구 실행 직전 |
| `PostToolUse` | 도구 호출 후 실행 | 도구 실행 완료 후 |

### 환경 변수

Hooks에서 사용 가능한 환경 변수:
- `$TOOL_INPUT`: 도구에 전달된 입력 데이터
- `$CLAUDE_PLUGIN_ROOT`: 플러그인 루트 디렉토리

## 보안

### 무결성 검증
- 모든 원격 플러그인은 SHA256 해시로 검증됩니다
- `plugin.json`의 `integrity` 필드로 해시를 지정할 수 있습니다

### 서명 검증
- GPG 서명을 통한 플러그인 인증 지원
- `--verify` 옵션으로 서명 검증 후 설치

### 보안 스캔
- `/plugin:validate`로 보안 검사 수행
- 위험한 쉘 명령, 하드코딩된 자격증명 탐지

## 기여 방법

1. Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
