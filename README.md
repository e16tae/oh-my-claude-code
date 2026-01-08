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
│   │   │   └── default.json
│   │   ├── commands/
│   │   ├── skills/
│   │   ├── agents/
│   │   └── hooks/
│   └── gemini-cli/               # Google Gemini CLI 서브 에이전트
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── config/
│       │   └── default.json
│       ├── commands/
│       ├── skills/
│       ├── agents/
│       └── hooks/
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

모든 플러그인은 다음 기본 설정을 사용합니다:

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

## 기여 방법

1. Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.
