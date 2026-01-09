---
description: 플러그인 레지스트리 검색
---

# /plugin:search

레지스트리에서 플러그인을 검색합니다.

## 사용법
```
/plugin:search <검색어> [옵션]
```

## 옵션

| 옵션 | 설명 |
|-----|------|
| `--category=<카테고리>` | 카테고리로 필터링 |
| `--author=<이름>` | 작성자로 필터링 |
| `--keywords=<k1,k2>` | 키워드로 필터링 |
| `--sort=<필드>` | 정렬 기준: downloads, stars, updated |
| `--limit=<n>` | 결과 제한 (기본: 20) |

## 예시
```
/plugin:search code generator
/plugin:search --category=ai-agent
/plugin:search --author=username
/plugin:search codex --keywords=openai,gpt
/plugin:search ai --sort=downloads --limit=10
```

## 카테고리

| 카테고리 | 설명 |
|---------|------|
| ai-agent | AI CLI 통합 |
| code-generation | 코드 생성 도구 |
| code-review | 코드 리뷰 및 분석 |
| orchestration | 멀티 에이전트 오케스트레이션 |
| testing | 테스트 자동화 |
| documentation | 문서 생성 |
| security | 보안 검사 |
| performance | 성능 분석 |
| utility | 유틸리티 도구 |
| integration | 외부 서비스 통합 |

## 실행 명령어

### 레지스트리 검색
```bash
source plugins/shared/utils/registry-client.sh

# 키워드 검색
results=$(registry_search "code generator")

# 카테고리 필터
results=$(registry_search "" "ai-agent")

# 결과 포맷팅
format_search_results "$results"
```

## 출력 예시

### 검색 결과
```
🔍 Search Results for "code generator"

| Plugin | Description | Version | Downloads |
|--------|-------------|---------|-----------|
| codex-cli | OpenAI Codex integration for code generation | 1.2.0 | 1,234 |
| gemini-cli | Google Gemini integration for code review | 1.0.1 | 987 |
| aider-plugin | Aider AI pair programming assistant | 0.9.0 | 456 |
| cursor-adapter | Cursor IDE integration | 0.5.0 | 234 |

Found 4 plugins. Run `/plugin:install <name>` to install.
```

### 상세 정보
```
📦 codex-cli

OpenAI Codex CLI를 서브 에이전트로 호출하여 코드 생성/완성 수행

Version:    1.2.0
Author:     username
License:    MIT
Categories: ai-agent, code-generation
Keywords:   codex, openai, code-generation, ai-agent

Downloads:
  Total:    1,234
  Weekly:   156
  Monthly:  523

Commands:
  /codex:generate - Generate code using Codex CLI
  /codex:complete - Complete partial code sections

Skills:
  codex-agent - Advanced code generation with context

Repository: https://github.com/username/codex-cli
Homepage:   https://codex-cli.example.com

Run `/plugin:install codex-cli` to install.
```

### 카테고리 목록
```
📂 Available Categories

| Category | Description | Plugins |
|----------|-------------|---------|
| ai-agent | AI CLI integrations | 5 |
| code-generation | Code generation tools | 3 |
| code-review | Code review and analysis | 2 |
| orchestration | Multi-agent orchestration | 1 |
| testing | Test automation | 4 |
| documentation | Documentation generation | 2 |

Run `/plugin:search --category=<name>` to browse.
```

### 검색 결과 없음
```
🔍 Search Results for "nonexistent-plugin"

No plugins found matching "nonexistent-plugin".

Suggestions:
  - Check your spelling
  - Try different keywords
  - Browse by category: `/plugin:search --category=ai-agent`
  - View all plugins: `/plugin:search *`
```

## 검색 범위

검색은 다음 필드를 대상으로 합니다:
- 플러그인 이름
- 설명 (description)
- 키워드 (keywords)
- 작성자 (author)

## 레지스트리 설정

기본 레지스트리는 환경 변수로 변경할 수 있습니다:

```bash
# 기본값
export OMCC_REGISTRY_URL="https://registry.oh-my-claude-code.dev"

# 커스텀 레지스트리
export OMCC_REGISTRY_URL="https://my-registry.example.com"

# 캐시 디렉토리
export OMCC_CACHE_DIR="$HOME/.cache/oh-my-claude-code"

# 캐시 TTL (초)
export OMCC_CACHE_TTL="3600"
```

## 오프라인 모드

레지스트리에 연결할 수 없는 경우:
- 캐시된 검색 결과 사용
- 로컬에 설치된 플러그인만 표시
- 새 플러그인 검색 불가

```
⚠️ Registry offline

Using cached results (last updated: 2 hours ago).
Some plugins may not be shown.

Try again later or check your network connection.
```

## 관련 명령어

- `/plugin:install` - 플러그인 설치
- `/plugin:version` - 버전 관리
- `/plugin:validate` - 플러그인 검증
