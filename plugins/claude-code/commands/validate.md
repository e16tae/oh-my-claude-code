---
description: 플러그인 구조 및 무결성 검증
---

# /plugin:validate

플러그인의 구조, 스키마, 보안을 검증합니다.

## 사용법
```
/plugin:validate [경로] [옵션]
```

## 옵션

| 옵션 | 설명 |
|-----|------|
| `--strict` | 경고를 에러로 처리 |
| `--report` | 상세 리포트 생성 |
| `--fix` | 자동 수정 가능한 문제 해결 |
| `--json` | JSON 형식으로 출력 |

## 검증 항목

### 1. 구조 검증
- `.claude-plugin/plugin.json` 존재 여부
- 필수 디렉토리 구조 (commands/, skills/, agents/, hooks/, config/)
- 최소 하나의 기능 파일 존재

### 2. 스키마 검증
- plugin.json JSON 문법 검사
- 필수 필드 확인 (name, version, description)
- 버전 형식 (semver) 검증
- 플러그인 이름 형식 검증

### 3. 명령어/스킬 검증
- 마크다운 frontmatter 존재
- description 필드 확인
- SKILL.md 파일 존재 (스킬)

### 4. 보안 검증
- 위험한 쉘 명령 패턴 검사
- 하드코딩된 비밀/자격증명 탐지
- 외부 네트워크 호출 감지

### 5. 무결성 검증
- SHA256 해시 검증 (integrity 필드)
- GPG 서명 검증 (선택)

## 예시
```
/plugin:validate                           # 현재 디렉토리 검증
/plugin:validate ./plugins/codex-cli       # 특정 플러그인 검증
/plugin:validate ./plugins/codex-cli --strict  # 엄격 모드
/plugin:validate . --json                  # JSON 출력
```

## 실행 명령어

### 플러그인 검증
```bash
# 검증 스크립트 사용
source plugins/shared/utils/plugin-validator.sh
validate_plugin ./plugins/codex-cli

# 엄격 모드
validate_plugin ./plugins/codex-cli --strict
```

### 무결성 검증
```bash
# 해시 검증
source plugins/shared/utils/integrity-checker.sh
verify_plugin_integrity ./plugins/codex-cli
```

## 출력 예시

### 성공
```
========================================
  Plugin Validation Report
  Path: ./plugins/codex-cli
========================================

[CHECK] Validating plugin structure...
[PASS] plugin.json found
[PASS] Directory exists: commands/
[PASS] Directory exists: skills/
[PASS] Directory exists: agents/
[PASS] Directory exists: hooks/
[PASS] Directory exists: config/
[PASS] Commands found: 2
[PASS] Skills found: 1
[PASS] Agents found: 1

[CHECK] Validating schemas...
[PASS] Valid JSON syntax: plugin.json
[PASS] Valid plugin name: codex-cli
[PASS] Valid version: 1.0.0
[PASS] Description present

[CHECK] Running security checks...
[PASS] No security issues found

========================================
  Validation Summary
========================================

[PASS] All checks passed!
```

### 실패
```
========================================
  Plugin Validation Report
  Path: ./plugins/broken-plugin
========================================

[CHECK] Validating plugin structure...
[FAIL] Missing required file: .claude-plugin/plugin.json
[WARN] Missing directory: skills/ (optional but recommended)

[CHECK] Running security checks...
[WARN] Network calls detected (3 occurrences): curl\s+
[FAIL] Potential secret/credential found:
    config/settings.json:5:  "api_key": "sk-1234567890abcdef"

========================================
  Validation Summary
========================================

Errors:   2
Warnings: 2
```

## 검증 레벨

| 레벨 | 설명 |
|-----|------|
| PASS | 검증 통과 |
| WARN | 경고 (권장 사항 미준수) |
| FAIL | 실패 (필수 요건 미충족) |

## 자동 수정 (`--fix`)

`--fix` 옵션으로 자동 수정 가능한 항목:
- 빈 디렉토리 생성 (commands/, skills/, agents/, hooks/, config/)
- 기본 plugin.json 템플릿 생성
- frontmatter 추가

## JSON 출력 형식

```json
{
  "plugin": "./plugins/codex-cli",
  "valid": true,
  "errors": 0,
  "warnings": 1,
  "checks": {
    "structure": { "status": "pass", "details": [...] },
    "schema": { "status": "pass", "details": [...] },
    "security": { "status": "warn", "details": [...] },
    "integrity": { "status": "pass", "details": [...] }
  }
}
```

## 관련 명령어

- `/plugin:install` - 플러그인 설치
- `/plugin:version` - 버전 관리
- `/plugin:deps` - 의존성 관리
