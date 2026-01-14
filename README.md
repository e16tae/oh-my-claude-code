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
│      └── skills/    → 스킬 정의 (설정 + CLI 통합)        │
└─────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
   [Codex CLI]                   [Gemini CLI]
    Bash로 호출                    Bash로 호출
```

## 플러그인 목록

### 로컬 플러그인

| 플러그인 | 설명 | 버전 |
|---------|------|-----|
| agents | Codex, Gemini CLI 통합 플러그인 | 1.2.0 |

### 외부 플러그인 참조 (claude-plugins-official)

이 마켓플레이스는 [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)에서 22개 플러그인을 참조합니다.

#### Anthropic 공식 플러그인 (17개)

| 플러그인 | 설명 | 카테고리 |
|---------|------|---------|
| code-review | PR 자동 리뷰 (신뢰도 기반 스코어링) | development |
| code-simplifier | 코드 단순화 및 리팩토링 | development |
| commit-commands | Git 커밋 워크플로우 자동화 | development |
| example-plugin | 플러그인 구조 예시 | development |
| explanatory-output-style | 교육적 설명 출력 스타일 | productivity |
| feature-dev | 4단계 기능 개발 워크플로우 | development |
| frontend-design | 고품질 프론트엔드 UI 생성 | development |
| hookify | 마크다운 기반 커스텀 훅 생성 | development |
| kotlin-lsp | Kotlin 언어 서버 | development |
| plugin-dev | 플러그인 개발 도구 | development |
| pr-review-toolkit | 6개 전문 PR 리뷰 에이전트 | development |
| pyright-lsp | Python 언어 서버 (Pyright) | development |
| ralph-loop | 자율 반복 개발 루프 | development |
| rust-analyzer-lsp | Rust 언어 서버 | development |
| security-guidance | 실시간 보안 취약점 탐지 | security |
| swift-lsp | Swift 언어 서버 | development |
| typescript-lsp | TypeScript/JavaScript 언어 서버 | development |

#### 커뮤니티 관리 플러그인 (5개)

| 플러그인 | 설명 | 제공 |
|---------|------|-----|
| context7 | 버전별 문서 조회 | Upstash |
| github | GitHub 통합 (이슈, PR 관리) | GitHub |
| greptile | AI 코드베이스 검색 | Greptile |
| playwright | 브라우저 자동화/E2E 테스트 | Microsoft |
| serena | LSP 기반 시맨틱 코드 분석 | Serena |

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

**로컬 플러그인:**
```bash
claude plugin install agents
```

**외부 플러그인 (claude-plugins-official 참조):**
```bash
claude plugin install code-review
claude plugin install security-guidance
claude plugin install typescript-lsp
# ... 등 22개 외부 플러그인
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
│   └── agents/                   # 통합 AI CLI 플러그인
│       ├── .claude-plugin/
│       │   └── plugin.json       # 플러그인 매니페스트
│       └── skills/
│           ├── codex/SKILL.md    # Codex 스킬 (설정 + CLI 통합)
│           └── gemini/SKILL.md   # Gemini 스킬 (설정 + CLI 통합)
├── README.md
└── LICENSE
```

## 플러그인 스키마

### plugin.json (공식 스키마)
```json
{
  "name": "agents",
  "version": "1.1.0",
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
      "version": "1.1.0",
      "author": { "name": "...", "email": "..." },
      "source": "./plugins/agents",
      "category": "development"
    }
  ]
}
```

## 기본 설정

각 스킬의 설정은 SKILL.md에 통합되어 있습니다.

### Codex CLI

| 설정 | 값 | CLI 옵션 |
|------|-----|----------|
| model | `gpt-5.2-codex` | `--model` |
| sandbox | `danger-full-access` | `--sandbox` |
| approval | `never` | `-c approval=` |
| reasoningEffort | `xhigh` | `-c reasoningEffort=` |

### Gemini CLI

| 설정 | 값 | CLI 옵션 |
|------|-----|----------|
| model | `gemini-3-pro-preview` | `--model` |
| outputFormat | `text` | `--output-format` |
| yolo | `true` | `--yolo` |

## 기여 방법

1. Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
