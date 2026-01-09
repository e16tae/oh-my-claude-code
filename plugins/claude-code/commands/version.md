---
description: 플러그인 버전 관리
---

# /plugin:version

플러그인 버전을 확인하고 업그레이드/다운그레이드합니다.

## 사용법
```
/plugin:version <하위명령> [옵션]
```

## 하위 명령

### list - 설치된 버전 목록
```
/plugin:version list
```

### check - 업데이트 확인
```
/plugin:version check [플러그인명]
/plugin:version check                    # 모든 플러그인
/plugin:version check codex-cli          # 특정 플러그인
```

### upgrade - 업그레이드
```
/plugin:version upgrade <플러그인명> [버전]
/plugin:version upgrade codex-cli        # 최신 버전으로
/plugin:version upgrade codex-cli@1.3.0  # 특정 버전으로
/plugin:version upgrade --all            # 모든 플러그인
```

### downgrade - 다운그레이드
```
/plugin:version downgrade <플러그인명> <버전>
/plugin:version downgrade codex-cli@1.0.0
```

### pin - 버전 고정
```
/plugin:version pin <플러그인명>
/plugin:version unpin <플러그인명>
```

### history - 버전 히스토리
```
/plugin:version history <플러그인명>
```

## 예시
```
/plugin:version list
/plugin:version check
/plugin:version upgrade codex-cli
/plugin:version upgrade --all
/plugin:version downgrade codex-cli@1.0.0
/plugin:version pin codex-cli
/plugin:version history codex-cli
```

## 실행 명령어

### 버전 확인
```bash
source plugins/shared/utils/version-resolver.sh

# 버전 비교
semver_compare "1.2.0" "1.10.0"  # -1 (1.2.0 < 1.10.0)

# 버전 범위 확인
semver_satisfies "1.5.0" "^1.0.0"  # 0 (만족)
```

### 업데이트 확인
```bash
source plugins/shared/utils/registry-client.sh

# 최신 버전 조회
latest=$(registry_get_latest "codex-cli")
echo "Latest: $latest"

# 현재 버전과 비교
current=$(jq -r '.version' plugins/codex-cli/.claude-plugin/plugin.json)
if semver_compare "$current" "$latest" -lt 0; then
    echo "Update available: $current → $latest"
fi
```

## 출력 예시

### 버전 목록 (`list`)
```
📊 Installed Plugin Versions

| Plugin | Installed | Latest | Status |
|--------|-----------|--------|--------|
| claude-code | 1.0.0 | 1.0.0 | ✅ Up to date |
| codex-cli | 1.1.0 | 1.2.0 | ⬆️ Update available |
| gemini-cli | 1.0.0 | 1.0.1 | ⬆️ Update available |

💡 Run `/plugin:version upgrade --all` to update all plugins.
```

### 업데이트 확인 (`check`)
```
🔍 Checking for updates...

codex-cli:
  Installed: 1.1.0
  Latest:    1.2.0
  Changes:   Bug fixes, performance improvements

gemini-cli:
  Installed: 1.0.0
  Latest:    1.0.1
  Changes:   Security patch

📦 2 updates available.
Run `/plugin:version upgrade --all` to update.
```

### 업그레이드 (`upgrade`)
```
⬆️ Upgrading codex-cli: 1.1.0 → 1.2.0

[1/4] Downloading codex-cli@1.2.0...
[2/4] Verifying integrity...
[3/4] Backing up current version...
[4/4] Installing new version...

✅ Successfully upgraded codex-cli to 1.2.0

Changes in 1.2.0:
  - Fixed code generation for async functions
  - Improved context collection performance
  - Added support for TypeScript 5.x
```

### 버전 히스토리 (`history`)
```
📜 Version History: codex-cli

| Version | Release Date | Status |
|---------|--------------|--------|
| 1.2.0 | 2026-01-10 | Latest |
| 1.1.0 | 2025-12-15 | Installed |
| 1.0.1 | 2025-11-20 | |
| 1.0.0 | 2025-10-01 | |

View changelog: https://github.com/user/codex-cli/releases
```

### 버전 고정 (`pin`)
```
📌 Pinned codex-cli@1.1.0

This plugin will not be automatically updated.
Run `/plugin:version unpin codex-cli` to allow updates.
```

## Semver 버전 범위

| 형식 | 설명 | 예시 |
|-----|------|------|
| `1.2.3` | 정확한 버전 | 1.2.3만 |
| `^1.2.3` | Major 호환 | 1.2.3 ~ 1.x.x |
| `~1.2.3` | Minor 호환 | 1.2.3 ~ 1.2.x |
| `>=1.2.0` | 최소 버전 | 1.2.0 이상 |
| `<2.0.0` | 최대 버전 | 2.0.0 미만 |
| `*` | 모든 버전 | 전체 |

## lock.json

버전을 잠그면 `.claude-plugin/lock.json`에 기록됩니다:

```json
{
  "lockfileVersion": 1,
  "plugins": {
    "codex-cli": {
      "version": "1.2.0",
      "resolved": "registry",
      "integrity": "sha256-abc123..."
    }
  }
}
```

## 관련 명령어

- `/plugin:install` - 플러그인 설치
- `/plugin:deps` - 의존성 관리
- `/plugin:validate` - 플러그인 검증
