#!/bin/bash
# plugin-validator.sh - 플러그인 구조 및 보안 검증
#
# 플러그인의 구조, 스키마, 보안을 검증합니다.
#
# 사용법:
#   source plugin-validator.sh
#   validate_structure /path/to/plugin
#   validate_security /path/to/plugin
#   validate_plugin /path/to/plugin --strict

set -e

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_DIR="${SCRIPT_DIR}/../../../schemas"

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[PASS]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" >&2
}

log_section() {
    echo -e "${BLUE}[CHECK]${NC} $1" >&2
}

# 검증 결과 카운터
declare -g ERRORS=0
declare -g WARNINGS=0

reset_counters() {
    ERRORS=0
    WARNINGS=0
}

# 플러그인 구조 검증
# @param $1 - 플러그인 디렉토리
# @return - 에러 목록 (없으면 빈 문자열)
validate_structure() {
    local plugin_dir="$1"
    local errors=()

    log_section "Validating plugin structure..."

    if [[ ! -d "$plugin_dir" ]]; then
        log_error "Plugin directory not found: $plugin_dir"
        ((ERRORS++))
        return 1
    fi

    # 필수 파일 검사
    local plugin_json="$plugin_dir/.claude-plugin/plugin.json"
    if [[ ! -f "$plugin_json" ]]; then
        log_error "Missing required file: .claude-plugin/plugin.json"
        ((ERRORS++))
    else
        log_info "plugin.json found"
    fi

    # 필수 디렉토리 검사
    local required_dirs=("commands" "skills" "agents" "hooks" "config")
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$plugin_dir/$dir" ]]; then
            log_info "Directory exists: $dir/"
        else
            log_warn "Missing directory: $dir/ (optional but recommended)"
            ((WARNINGS++))
        fi
    done

    # 최소 하나의 기능 파일 검사
    local has_content=false

    if [[ -d "$plugin_dir/commands" ]] && [[ -n "$(ls -A "$plugin_dir/commands" 2>/dev/null)" ]]; then
        local cmd_count=$(find "$plugin_dir/commands" -name "*.md" | wc -l | tr -d ' ')
        log_info "Commands found: $cmd_count"
        has_content=true
    fi

    if [[ -d "$plugin_dir/skills" ]] && [[ -n "$(ls -A "$plugin_dir/skills" 2>/dev/null)" ]]; then
        local skill_count=$(find "$plugin_dir/skills" -name "SKILL.md" | wc -l | tr -d ' ')
        log_info "Skills found: $skill_count"
        has_content=true
    fi

    if [[ -d "$plugin_dir/agents" ]] && [[ -n "$(ls -A "$plugin_dir/agents" 2>/dev/null)" ]]; then
        local agent_count=$(find "$plugin_dir/agents" -name "*.md" | wc -l | tr -d ' ')
        log_info "Agents found: $agent_count"
        has_content=true
    fi

    if [[ "$has_content" == "false" ]]; then
        log_warn "Plugin has no commands, skills, or agents"
        ((WARNINGS++))
    fi

    return 0
}

# JSON 스키마 검증
# @param $1 - JSON 파일 경로
# @param $2 - 스키마 URL 또는 경로
# @return - 0 (유효), 1 (무효)
validate_json_schema() {
    local json_file="$1"
    local schema="$2"

    if [[ ! -f "$json_file" ]]; then
        log_error "JSON file not found: $json_file"
        return 1
    fi

    # JSON 파싱 검증
    if ! jq empty "$json_file" 2>/dev/null; then
        log_error "Invalid JSON syntax: $json_file"
        ((ERRORS++))
        return 1
    fi

    log_info "Valid JSON syntax: $(basename "$json_file")"

    # 필수 필드 검증 (plugin.json)
    if [[ "$(basename "$json_file")" == "plugin.json" ]]; then
        local name version description

        name=$(jq -r '.name // empty' "$json_file")
        version=$(jq -r '.version // empty' "$json_file")
        description=$(jq -r '.description // empty' "$json_file")

        if [[ -z "$name" ]]; then
            log_error "Missing required field: name"
            ((ERRORS++))
        else
            # 이름 형식 검증
            if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
                log_error "Invalid name format (must be lowercase alphanumeric with hyphens): $name"
                ((ERRORS++))
            else
                log_info "Valid plugin name: $name"
            fi
        fi

        if [[ -z "$version" ]]; then
            log_error "Missing required field: version"
            ((ERRORS++))
        else
            # semver 형식 검증
            if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                log_error "Invalid version format (must be semver): $version"
                ((ERRORS++))
            else
                log_info "Valid version: $version"
            fi
        fi

        if [[ -z "$description" ]]; then
            log_warn "Missing recommended field: description"
            ((WARNINGS++))
        else
            log_info "Description present"
        fi
    fi

    return 0
}

# 명령어 파일 검증
# @param $1 - 명령어 마크다운 파일
validate_command_file() {
    local cmd_file="$1"

    if [[ ! -f "$cmd_file" ]]; then
        return 1
    fi

    local filename=$(basename "$cmd_file")

    # frontmatter 검증
    if head -1 "$cmd_file" | grep -q "^---$"; then
        log_info "Valid frontmatter: $filename"
    else
        log_warn "Missing frontmatter in: $filename"
        ((WARNINGS++))
    fi

    # description 필드 확인
    if grep -q "^description:" "$cmd_file"; then
        log_info "Description field present: $filename"
    else
        log_warn "Missing description field: $filename"
        ((WARNINGS++))
    fi

    return 0
}

# 스킬 파일 검증
# @param $1 - 스킬 디렉토리
validate_skill_directory() {
    local skill_dir="$1"

    if [[ ! -d "$skill_dir" ]]; then
        return 1
    fi

    local skill_name=$(basename "$skill_dir")

    # SKILL.md 존재 확인
    if [[ -f "$skill_dir/SKILL.md" ]]; then
        log_info "SKILL.md found: $skill_name"

        # 필수 섹션 확인
        if grep -q "^## Trigger" "$skill_dir/SKILL.md" || grep -q "trigger:" "$skill_dir/SKILL.md"; then
            log_info "Trigger section found: $skill_name"
        else
            log_warn "Missing trigger section: $skill_name"
            ((WARNINGS++))
        fi
    else
        log_error "Missing SKILL.md: $skill_dir"
        ((ERRORS++))
    fi

    return 0
}

# 보안 검사
# @param $1 - 플러그인 디렉토리
# @return - 경고/에러 목록
validate_security() {
    local plugin_dir="$1"
    local findings=()

    log_section "Running security checks..."

    # 위험한 패턴 검색
    local dangerous_patterns=(
        "eval\s*\("
        "exec\s*\("
        "system\s*\("
        "curl.*\|.*bash"
        "wget.*\|.*sh"
        "rm\s+-rf\s+/"
        "rm\s+-rf\s+\*"
        ">\s*/dev/sd"
        "mkfs\."
        "dd\s+if="
    )

    for pattern in "${dangerous_patterns[@]}"; do
        local matches
        matches=$(grep -rE "$pattern" "$plugin_dir" \
            --include="*.sh" \
            --include="*.js" \
            --include="*.py" \
            2>/dev/null | head -5)

        if [[ -n "$matches" ]]; then
            log_warn "Potentially dangerous pattern found: $pattern"
            echo "$matches" | while read -r line; do
                echo "    $line" >&2
            done
            ((WARNINGS++))
        fi
    done

    # 하드코딩된 비밀 검색
    local secret_patterns=(
        "password\s*=\s*['\"][^'\"]+['\"]"
        "api_key\s*=\s*['\"][^'\"]+['\"]"
        "secret\s*=\s*['\"][^'\"]+['\"]"
        "token\s*=\s*['\"][^'\"]+['\"]"
        "AKIA[0-9A-Z]{16}"  # AWS Access Key
        "-----BEGIN.*PRIVATE KEY-----"
    )

    for pattern in "${secret_patterns[@]}"; do
        local matches
        matches=$(grep -rEi "$pattern" "$plugin_dir" \
            --include="*.sh" \
            --include="*.js" \
            --include="*.py" \
            --include="*.json" \
            --include="*.md" \
            2>/dev/null | head -3)

        if [[ -n "$matches" ]]; then
            log_error "Potential secret/credential found:"
            echo "$matches" | while read -r line; do
                echo "    $line" >&2
            done
            ((ERRORS++))
        fi
    done

    # 외부 네트워크 호출 검색
    local network_patterns=(
        "curl\s+"
        "wget\s+"
        "fetch\s*\("
        "requests\.(get|post)"
        "http\.Get"
    )

    for pattern in "${network_patterns[@]}"; do
        local matches
        matches=$(grep -rE "$pattern" "$plugin_dir" \
            --include="*.sh" \
            --include="*.js" \
            --include="*.py" \
            2>/dev/null | wc -l | tr -d ' ')

        if [[ "$matches" -gt 0 ]]; then
            log_warn "Network calls detected ($matches occurrences): $pattern"
            ((WARNINGS++))
        fi
    done

    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        log_info "No security issues found"
    fi

    return 0
}

# hooks.json 검증
# @param $1 - hooks.json 파일 경로
validate_hooks() {
    local hooks_file="$1"

    if [[ ! -f "$hooks_file" ]]; then
        return 0
    fi

    log_section "Validating hooks configuration..."

    # JSON 유효성
    if ! jq empty "$hooks_file" 2>/dev/null; then
        log_error "Invalid JSON in hooks.json"
        ((ERRORS++))
        return 1
    fi

    log_info "Valid hooks.json syntax"

    # hooks 배열 확인
    local hooks_count
    hooks_count=$(jq '.hooks | length' "$hooks_file" 2>/dev/null)

    if [[ "$hooks_count" -gt 0 ]]; then
        log_info "Hooks defined: $hooks_count"

        # 각 훅 검증
        jq -r '.hooks[] | .matcher' "$hooks_file" 2>/dev/null | while read -r matcher; do
            if [[ -n "$matcher" ]]; then
                log_info "Hook matcher: $matcher"
            fi
        done
    fi

    return 0
}

# 기본 plugin.json 템플릿 생성
# @param $1 - 플러그인 디렉토리
create_default_plugin_json() {
    local plugin_dir="$1"
    local plugin_name
    plugin_name=$(basename "$plugin_dir")
    local plugin_json="$plugin_dir/.claude-plugin/plugin.json"

    mkdir -p "$plugin_dir/.claude-plugin"

    cat > "$plugin_json" << EOF
{
  "\$schema": "../../../schemas/plugin-v2.schema.json",
  "schemaVersion": "2.0.0",
  "name": "$plugin_name",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": {
    "name": "your-name",
    "url": "https://github.com/your-username"
  },
  "license": "MIT",
  "keywords": [],
  "categories": ["utility"],
  "permissions": {
    "required": ["Read"],
    "optional": []
  },
  "exports": {
    "commands": ["commands/*.md"],
    "skills": ["skills/*/SKILL.md"],
    "agents": ["agents/*.md"],
    "hooks": ["hooks/hooks.json"],
    "config": ["config/default.json"]
  }
}
EOF
    log_info "Created default plugin.json"
}

# Markdown 파일에 frontmatter 추가
# @param $1 - 마크다운 파일 경로
add_frontmatter() {
    local file_path="$1"
    local filename
    filename=$(basename "$file_path" .md)

    # 이미 frontmatter가 있으면 스킵
    if head -1 "$file_path" | grep -q "^---$"; then
        return 0
    fi

    local temp_file
    temp_file=$(mktemp)

    cat > "$temp_file" << EOF
---
name: $filename
description: Description for $filename
---

EOF
    cat "$file_path" >> "$temp_file"
    mv "$temp_file" "$file_path"
    log_info "Added frontmatter to: $file_path"
}

# 플러그인 자동 수정
# @param $1 - 플러그인 디렉토리
# @return - 수정된 항목 수
fix_plugin() {
    local plugin_dir="$1"
    local fixed=0

    echo ""
    echo "========================================"
    echo "  Auto-fixing Plugin"
    echo "  Path: $plugin_dir"
    echo "========================================"
    echo ""

    # 1. 필수 디렉토리 생성
    for dir in commands skills agents hooks config; do
        if [[ ! -d "$plugin_dir/$dir" ]]; then
            mkdir -p "$plugin_dir/$dir"
            log_info "Created directory: $dir/"
            ((fixed++))
        fi
    done

    # 2. .claude-plugin 디렉토리 생성
    if [[ ! -d "$plugin_dir/.claude-plugin" ]]; then
        mkdir -p "$plugin_dir/.claude-plugin"
        log_info "Created directory: .claude-plugin/"
        ((fixed++))
    fi

    # 3. plugin.json 없으면 기본 템플릿 생성
    if [[ ! -f "$plugin_dir/.claude-plugin/plugin.json" ]]; then
        create_default_plugin_json "$plugin_dir"
        ((fixed++))
    fi

    # 4. hooks.json 없으면 기본 생성
    if [[ ! -f "$plugin_dir/hooks/hooks.json" ]]; then
        echo '{"hooks": []}' > "$plugin_dir/hooks/hooks.json"
        log_info "Created default hooks/hooks.json"
        ((fixed++))
    fi

    # 5. 명령어 파일에 frontmatter 없으면 추가
    if [[ -d "$plugin_dir/commands" ]]; then
        for cmd_file in "$plugin_dir/commands"/*.md 2>/dev/null; do
            if [[ -f "$cmd_file" ]]; then
                if ! head -1 "$cmd_file" | grep -q "^---$"; then
                    add_frontmatter "$cmd_file"
                    ((fixed++))
                fi
            fi
        done
    fi

    echo ""
    echo "========================================"
    echo "  Fix Summary: $fixed items fixed"
    echo "========================================"
    echo ""

    return 0
}

# 전체 플러그인 검증
# @param $1 - 플러그인 디렉토리
# @param $2 - 옵션 (--strict, --report, --fix)
validate_plugin() {
    local plugin_dir="$1"
    local option="${2:-}"

    # --fix 모드: 먼저 자동 수정 후 검증
    if [[ "$option" == "--fix" ]]; then
        fix_plugin "$plugin_dir"
        option=""  # 수정 후 일반 검증
    fi

    reset_counters

    echo ""
    echo "========================================"
    echo "  Plugin Validation Report"
    echo "  Path: $plugin_dir"
    echo "========================================"
    echo ""

    # 1. 구조 검증
    validate_structure "$plugin_dir"
    echo ""

    # 2. 스키마 검증
    log_section "Validating schemas..."
    local plugin_json="$plugin_dir/.claude-plugin/plugin.json"
    if [[ -f "$plugin_json" ]]; then
        validate_json_schema "$plugin_json"
    fi
    echo ""

    # 3. 명령어 검증
    if [[ -d "$plugin_dir/commands" ]]; then
        log_section "Validating commands..."
        for cmd_file in "$plugin_dir/commands"/*.md; do
            if [[ -f "$cmd_file" ]]; then
                validate_command_file "$cmd_file"
            fi
        done
        echo ""
    fi

    # 4. 스킬 검증
    if [[ -d "$plugin_dir/skills" ]]; then
        log_section "Validating skills..."
        for skill_dir in "$plugin_dir/skills"/*/; do
            if [[ -d "$skill_dir" ]]; then
                validate_skill_directory "$skill_dir"
            fi
        done
        echo ""
    fi

    # 5. 훅 검증
    local hooks_file="$plugin_dir/hooks/hooks.json"
    if [[ -f "$hooks_file" ]]; then
        validate_hooks "$hooks_file"
        echo ""
    fi

    # 6. 보안 검증
    validate_security "$plugin_dir"
    echo ""

    # 결과 요약
    echo "========================================"
    echo "  Validation Summary"
    echo "========================================"
    echo ""

    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}[PASS]${NC} All checks passed!"
        echo ""
        return 0
    else
        echo -e "Errors:   ${RED}$ERRORS${NC}"
        echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
        echo ""

        if [[ "$option" == "--strict" ]] && [[ $WARNINGS -gt 0 ]]; then
            log_error "Strict mode: warnings treated as errors"
            return 1
        fi

        if [[ $ERRORS -gt 0 ]]; then
            return 1
        fi

        return 0
    fi
}

# 직접 실행시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <plugin-directory> [--strict|--report|--fix]"
        echo ""
        echo "Options:"
        echo "  --strict    Treat warnings as errors"
        echo "  --report    Generate detailed report"
        echo "  --fix       Auto-fix common issues before validation"
        echo ""
        echo "Example:"
        echo "  $0 ./plugins/codex-cli"
        echo "  $0 ./plugins/codex-cli --strict"
        echo "  $0 ./plugins/codex-cli --fix"
        exit 1
    fi

    validate_plugin "$@"
    exit $?
fi
