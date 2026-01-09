---
description: 원격 소스에서 플러그인 설치
---

# /plugin:install

레지스트리, GitHub, URL에서 플러그인을 설치합니다.

## 사용법
```
/plugin:install <소스> [옵션]
```

## 소스 형식

| 형식 | 예시 |
|-----|------|
| 레지스트리 | `/plugin:install codex-cli` |
| 버전 지정 | `/plugin:install codex-cli@1.2.0` |
| 버전 범위 | `/plugin:install codex-cli@^1.0.0` |
| GitHub | `/plugin:install github:user/repo` |
| GitHub 태그 | `/plugin:install github:user/repo@v1.0.0` |
| 직접 URL | `/plugin:install https://example.com/plugin.tar.gz` |
| 로컬 경로 | `/plugin:install ./path/to/plugin` |

## 옵션

| 옵션 | 설명 |
|-----|------|
| `--force` | 이미 설치된 경우에도 강제 재설치 |
| `--no-deps` | 의존성 설치 건너뛰기 |
| `--dry-run` | 실제 설치 없이 미리보기 |
| `--verify` | 서명 검증 후 설치 |

## 예시
```
/plugin:install codex-cli
/plugin:install codex-cli@^1.0.0
/plugin:install github:username/my-plugin
/plugin:install github:username/my-plugin@v2.0.0
/plugin:install https://registry.example.com/plugins/my-plugin-1.0.0.tar.gz
/plugin:install ./my-local-plugin --no-deps
```

## 설치 프로세스

```
1. 소스 파싱 및 검증
        |
        v
2. 플러그인 메타데이터 가져오기
        |
        v
3. 버전 해석 (범위인 경우)
        |
        v
4. 의존성 해결
        |
        v
5. 다운로드
        |
        v
6. 무결성 검증 (SHA256)
        |
        v
7. 서명 검증 (선택)
        |
        v
8. 보안 스캔
        |
        v
9. 추출 및 설치
        |
        v
10. 의존성 설치 (재귀)
        |
        v
11. post-install 훅 실행
```

## 실행 명령어

### 레지스트리에서 설치
```bash
source plugins/shared/utils/registry-client.sh
source plugins/shared/utils/integrity-checker.sh

# 플러그인 다운로드
tarball=$(registry_download "codex-cli" "1.2.0" "/tmp")

# 무결성 검증
verify_hash "$tarball" "expected-hash"

# 추출
tar -xzf "$tarball" -C ./plugins/
```

### GitHub에서 설치
```bash
source plugins/shared/utils/github-handler.sh

# GitHub에서 설치
github_install_plugin "github:user/my-plugin@v1.0.0" "./plugins"
```

## 출력 예시

### 성공
```
📦 Installing codex-cli@1.2.0

[1/5] Resolving dependencies...
      └── claude-code@^1.0.0 (satisfied by 1.0.0)

[2/5] Downloading codex-cli@1.2.0...
      https://registry.oh-my-claude-code.dev/codex-cli/1.2.0/codex-cli-1.2.0.tar.gz
      Downloaded: 45.2 KB

[3/5] Verifying integrity...
      SHA256: a1b2c3d4e5...
      ✅ Verified

[4/5] Extracting...
      → ./plugins/codex-cli

[5/5] Running post-install hooks...
      ✅ Completed

✅ Successfully installed codex-cli@1.2.0

Installed to: ./plugins/codex-cli
Commands: /codex:generate, /codex:complete
Skills: codex-agent
```

### Dry Run
```
📦 Dry run: codex-cli@1.2.0

Would install:
  1. codex-cli@1.2.0
     - Source: registry
     - Size: ~45 KB
     - Dependencies: claude-code@^1.0.0

  2. claude-code@1.0.0 (already installed)
     - Satisfies: ^1.0.0
     - Status: ✅ Compatible

No changes made (dry run).
Run without --dry-run to install.
```

### 실패
```
📦 Installing broken-plugin@1.0.0

[1/5] Resolving dependencies...
      └── missing-dep@^2.0.0 (not found)

❌ Installation failed

Error: Dependency not found: missing-dep@^2.0.0
       This dependency is not available in the registry.

Suggestions:
  - Check if the dependency name is correct
  - Try installing the dependency manually
  - Use --no-deps to skip dependency installation
```

## 보안

### 무결성 검증
- 모든 다운로드는 SHA256 해시로 검증됩니다
- 해시 불일치 시 설치가 중단됩니다

### 서명 검증 (`--verify`)
- GPG 서명이 있는 플러그인은 서명을 검증합니다
- 신뢰할 수 있는 키로 서명된 경우에만 설치됩니다

### 보안 스캔
- 위험한 쉘 명령 패턴 검사
- 하드코딩된 자격증명 탐지
- 의심스러운 네트워크 호출 경고

## 관련 명령어

- `/plugin:validate` - 플러그인 검증
- `/plugin:version` - 버전 관리
- `/plugin:deps` - 의존성 관리
- `/plugin:search` - 플러그인 검색
