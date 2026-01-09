---
description: 플러그인 의존성 관리
---

# /plugin:deps

플러그인 의존성을 확인하고 관리합니다.

## 사용법
```
/plugin:deps <하위명령> [옵션]
```

## 하위 명령

### tree - 의존성 트리 보기
```
/plugin:deps tree [플러그인명]
/plugin:deps tree                  # 모든 플러그인
/plugin:deps tree codex-cli        # 특정 플러그인
```

### check - 의존성 충돌 검사
```
/plugin:deps check
```

### install - 누락된 의존성 설치
```
/plugin:deps install [플러그인명]
```

### prune - 사용되지 않는 의존성 제거
```
/plugin:deps prune
/plugin:deps prune --dry-run       # 미리보기만
```

### why - 역방향 의존성 확인
```
/plugin:deps why <플러그인명>
```

## 예시
```
/plugin:deps tree
/plugin:deps tree codex-cli
/plugin:deps check
/plugin:deps install
/plugin:deps prune
/plugin:deps why claude-code
```

## 실행 명령어

### 의존성 트리 구축
```bash
source plugins/shared/utils/dep-resolver.sh

# 의존성 그래프 구축
build_dep_graph "codex-cli" "./plugins"

# 트리 출력
print_dep_tree "codex-cli"

# 설치 순서 확인
resolve_install_order "codex-cli"
```

### 충돌 검사
```bash
source plugins/shared/utils/dep-resolver.sh
source plugins/shared/utils/version-resolver.sh

# 그래프 구축
build_dep_graph "codex-cli" "./plugins"

# 충돌 검사
detect_conflicts
```

## 출력 예시

### 의존성 트리 (`tree`)
```
🌳 Dependency Tree

codex-cli@1.2.0
├── claude-code@1.0.0 (required)
└── gemini-cli@1.0.0 (optional, not installed)

gemini-cli@1.0.1
└── claude-code@1.0.0 (required)

claude-code@1.0.0
└── (no dependencies)

Legend:
  ├── Required dependency
  └── Optional dependency
  ❌  Not installed
```

### 충돌 검사 (`check`)
```
🔍 Checking dependency conflicts...

✅ No conflicts found.

All dependencies are compatible:
  - claude-code: ^1.0.0 (resolved to 1.0.0)
```

충돌이 있는 경우:
```
🔍 Checking dependency conflicts...

⚠️ Conflicts detected:

claude-code:
  - codex-cli requires: ^1.0.0
  - gemini-cli requires: ^2.0.0
  - Installed: 1.0.0

  Resolution options:
  1. Upgrade claude-code to 2.0.0 (may break codex-cli)
  2. Downgrade gemini-cli to 1.x.x
  3. Use --force to ignore conflicts

Run `/plugin:deps resolve` for automatic resolution.
```

### 누락 의존성 설치 (`install`)
```
📦 Installing missing dependencies...

Found missing dependencies:
  - helper-utils@^1.0.0 (required by codex-cli)

[1/1] Installing helper-utils@1.2.0...
      Downloaded: 12.5 KB
      ✅ Installed

✅ All dependencies installed.
```

### 의존성 정리 (`prune`)
```
🧹 Pruning unused dependencies...

Orphan plugins found:
  - old-plugin@0.9.0 (no dependents)
  - deprecated-helper@1.0.0 (no dependents)

Would remove:
  - ./plugins/old-plugin (45 KB)
  - ./plugins/deprecated-helper (12 KB)

Total: 57 KB

Run without --dry-run to remove.
```

### 역방향 의존성 (`why`)
```
🔍 Why is claude-code installed?

claude-code@1.0.0 is required by:
  ├── codex-cli@1.2.0
  │   └── dependencies: { "claude-code": "^1.0.0" }
  └── gemini-cli@1.0.1
      └── dependencies: { "claude-code": "^1.0.0" }

This plugin is a core dependency and cannot be removed.
```

## 의존성 유형

| 유형 | 설명 |
|-----|------|
| dependencies | 필수 의존성 - 없으면 플러그인이 동작하지 않음 |
| optionalDependencies | 선택 의존성 - 없어도 기본 기능은 동작 |
| peerDependencies | 피어 의존성 - 호환성을 위해 권장되는 버전 |

## plugin.json 의존성 선언

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "dependencies": {
    "claude-code": "^1.0.0",
    "helper-utils": "~2.0.0"
  },
  "optionalDependencies": {
    "extra-features": "^1.0.0"
  },
  "peerDependencies": {
    "shared-lib": ">=1.0.0 <3.0.0"
  }
}
```

## 의존성 해결 알고리즘

1. **그래프 구축**: 모든 의존성을 트리 구조로 구성
2. **버전 해결**: 각 의존성의 최적 버전 결정
3. **충돌 감지**: 호환되지 않는 버전 요구사항 식별
4. **토폴로지 정렬**: 설치 순서 결정 (의존성 먼저)

## 순환 의존성

순환 의존성이 감지되면 설치가 중단됩니다:

```
❌ Circular dependency detected!

plugin-a@1.0.0
└── plugin-b@1.0.0
    └── plugin-a@1.0.0 (circular!)

This is a packaging error. Please report to the plugin maintainer.
```

## 관련 명령어

- `/plugin:install` - 플러그인 설치
- `/plugin:version` - 버전 관리
- `/plugin:validate` - 플러그인 검증
