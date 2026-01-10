# oh-my-claude-code

Claude Code를 메인 오케스트레이터로, 다양한 AI CLI를 서브 에이전트로 활용하는 플러그인 마켓플레이스입니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code                          │
│                 (메인 오케스트레이터)                     │
├─────────────────────────────────────────────────────────┤
│  plugins/                                               │
│  └── agents/        → Codex, Gemini CLI 통합 플러그인    │
│      ├── skills/    → 스킬 정의 (트리거 기반 자동 활성화) │
│      ├── cli/       → CLI 호출 방법 문서                 │
│      └── config/    → CLI 설정 파일                     │
└─────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
   [Codex CLI]                   [Gemini CLI]
    Bash로 호출                    Bash로 호출
```

## 플러그인 목록

| 플러그인 | 설명 | 버전 |
|---------|------|-----|
| agents | Codex, Gemini CLI 통합 플러그인 | 1.0.0 |

## 자연어 트리거

서브 에이전트를 자연어로 호출할 수 있습니다:

### Codex CLI
- "codex로 코드 생성해줘"
- "codex 써서 함수 작성해"
- "codex한테 시켜"

### Gemini CLI
- "gemini로 리뷰해줘"
- "gemini한테 분석 맡겨"
- "gemini 써서 검토해"

## 설치 방법

### 1. Marketplace 등록
```bash
claude plugin marketplace add ./
```

### 2. 플러그인 설치
```bash
claude plugin install agents
```

### 3. 플러그인 검증 (선택)
```bash
claude plugin validate ./plugins/agents
```

### 4. 바로 사용
설치 후 자연어로 바로 사용할 수 있습니다:
```
"codex로 피보나치 함수 만들어줘"
"gemini로 이 코드 리뷰해줘"
```

## 플러그인 관리 명령어

| 명령어 | 설명 |
|-------|------|
| `claude plugin install <plugin>` | 플러그인 설치 |
| `claude plugin uninstall <plugin>` | 플러그인 제거 |
| `claude plugin enable <plugin>` | 플러그인 활성화 |
| `claude plugin disable <plugin>` | 플러그인 비활성화 |
| `claude plugin update <plugin>` | 플러그인 업데이트 |
| `claude plugin validate <path>` | 플러그인 검증 |
| `claude plugin marketplace add <source>` | 마켓플레이스 등록 |

## 디렉토리 구조

```
oh-my-claude-code/
├── .claude-plugin/
│   └── marketplace.json          # 마켓플레이스 매니페스트
├── plugins/
│   ├── agents/                   # 통합 AI CLI 플러그인
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # 플러그인 매니페스트
│   │   ├── skills/
│   │   │   ├── codex/SKILL.md    # Codex 스킬 정의
│   │   │   └── gemini/SKILL.md   # Gemini 스킬 정의
│   │   ├── cli/
│   │   │   ├── codex.md          # Codex CLI 호출 방법
│   │   │   └── gemini.md         # Gemini CLI 호출 방법
│   │   └── config/
│   │       ├── codex.jsonc       # Codex 설정
│   │       └── gemini.jsonc      # Gemini 설정
│   └── shared/
│       └── utils/                # 공유 유틸리티
├── README.md
└── LICENSE
```

## 플러그인 스키마

### plugin.json (공식 스키마)
```json
{
  "name": "agents",
  "version": "1.0.0",
  "description": "Claude Code에서 여러 AI CLI 도구를 통합하는 플러그인",
  "author": {
    "name": "oh-my-claude-code",
    "email": "oh-my-claude-code@github.com"
  }
}
```

### marketplace.json
```json
{
  "name": "oh-my-claude-code",
  "description": "AI CLI 통합 플러그인 마켓플레이스",
  "owner": {
    "name": "oh-my-claude-code",
    "email": "oh-my-claude-code@github.com"
  },
  "plugins": [
    {
      "name": "agents",
      "description": "Codex, Gemini CLI 통합 플러그인",
      "version": "1.0.0",
      "author": { "name": "...", "email": "..." },
      "source": "./plugins/agents",
      "category": "development"
    }
  ]
}
```

## 기본 설정

### Codex CLI (`config/codex.jsonc`)
```jsonc
{
  "model": "gpt-5.2-codex",
  "reasoningEffort": "xhigh",
  "sandbox": "danger-full-access",
  "approval": "never",
  "fullAuto": true,
  "search": false
}
```

### Gemini CLI (`config/gemini.jsonc`)
```jsonc
{
  "model": "gemini-3-pro-preview",
  "thinkingLevel": "high",
  "outputFormat": "text",
  "yolo": true
}
```

## Shared 유틸리티

`plugins/shared/utils/` 디렉토리에 공유 유틸리티가 포함되어 있습니다.

### plugin-validator.sh
플러그인 구조와 보안을 검증합니다.

```bash
source plugins/shared/utils/plugin-validator.sh
validate_plugin ./plugins/agents --strict
```

### version-resolver.sh
Semver 버전을 해석하고 비교합니다.

```bash
source plugins/shared/utils/version-resolver.sh
semver_compare "1.2.0" "1.10.0"   # -1
semver_satisfies "1.5.0" "^1.0.0" # 0 (true)
```

### integrity-checker.sh
플러그인 무결성을 검증합니다.

```bash
source plugins/shared/utils/integrity-checker.sh
generate_hash /path/to/file
verify_hash /path/to/file expected_hash
```

## 기여 방법

1. Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
