#!/bin/bash
# collect-context.sh - 프로젝트 컨텍스트 자동 수집
#
# Gemini/Codex CLI 호출 전 프로젝트 정보를 자동으로 수집하여
# 더 풍부한 컨텍스트를 제공합니다.
#
# 사용법:
#   ./collect-context.sh [PROJECT_ROOT] [OUTPUT_FILE]
#
# 예시:
#   ./collect-context.sh                          # 현재 디렉토리, context.json 출력
#   ./collect-context.sh /path/to/project         # 특정 디렉토리
#   ./collect-context.sh . /tmp/ctx.json          # 출력 파일 지정

set -e

PROJECT_ROOT="${1:-.}"
OUTPUT_FILE="${2:-context.json}"

# 색상 출력 (터미널용)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# JSON 문자열 이스케이프
# @param $1 - 이스케이프할 문자열
json_escape() {
    local str="$1"
    # jq를 사용하여 안전하게 JSON 문자열 생성
    if command -v jq &>/dev/null; then
        printf '%s' "$str" | jq -Rs '.'
    else
        # jq 없으면 수동 이스케이프
        str="${str//\\/\\\\}"      # 백슬래시
        str="${str//\"/\\\"}"      # 따옴표
        str="${str//$'\n'/\\n}"    # 줄바꿈
        str="${str//$'\r'/\\r}"    # 캐리지 리턴
        str="${str//$'\t'/\\t}"    # 탭
        echo "\"$str\""
    fi
}

# 1. 프로젝트 타입 감지
detect_project_type() {
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$PROJECT_ROOT/pyproject.toml" ]] || [[ -f "$PROJECT_ROOT/setup.py" ]] || [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        echo "python"
    elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        echo "go"
    elif [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$PROJECT_ROOT/pom.xml" ]] || [[ -f "$PROJECT_ROOT/build.gradle" ]]; then
        echo "java"
    elif [[ -f "$PROJECT_ROOT/Package.swift" ]]; then
        echo "swift"
    else
        echo "unknown"
    fi
}

# 2. 언어 버전 추출
get_language_version() {
    local project_type="$1"

    case "$project_type" in
        nodejs)
            if [[ -f "$PROJECT_ROOT/package.json" ]]; then
                local node_ver=$(jq -r '.engines.node // "not specified"' "$PROJECT_ROOT/package.json" 2>/dev/null)
                echo "$node_ver"
            fi
            ;;
        python)
            if [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
                grep -E "python.*=" "$PROJECT_ROOT/pyproject.toml" | head -1 | sed 's/.*"\([^"]*\)".*/\1/' 2>/dev/null || echo "not specified"
            elif [[ -f "$PROJECT_ROOT/.python-version" ]]; then
                cat "$PROJECT_ROOT/.python-version"
            else
                echo "not specified"
            fi
            ;;
        go)
            if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
                grep "^go " "$PROJECT_ROOT/go.mod" | awk '{print $2}' 2>/dev/null || echo "not specified"
            fi
            ;;
        rust)
            if [[ -f "$PROJECT_ROOT/rust-toolchain.toml" ]]; then
                grep "channel" "$PROJECT_ROOT/rust-toolchain.toml" | cut -d'"' -f2 2>/dev/null || echo "stable"
            else
                echo "stable"
            fi
            ;;
        *)
            echo "not specified"
            ;;
    esac
}

# 3. 프레임워크 감지
detect_framework() {
    local project_type="$1"
    local frameworks=""

    case "$project_type" in
        nodejs)
            if [[ -f "$PROJECT_ROOT/package.json" ]]; then
                local deps=$(jq -r '.dependencies // {} | keys[]' "$PROJECT_ROOT/package.json" 2>/dev/null)

                [[ "$deps" == *"react"* ]] && frameworks+="React, "
                [[ "$deps" == *"vue"* ]] && frameworks+="Vue, "
                [[ "$deps" == *"angular"* ]] && frameworks+="Angular, "
                [[ "$deps" == *"next"* ]] && frameworks+="Next.js, "
                [[ "$deps" == *"express"* ]] && frameworks+="Express, "
                [[ "$deps" == *"fastify"* ]] && frameworks+="Fastify, "
                [[ "$deps" == *"nest"* ]] && frameworks+="NestJS, "
            fi
            ;;
        python)
            if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
                local deps=$(cat "$PROJECT_ROOT/requirements.txt" 2>/dev/null)
            elif [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
                local deps=$(cat "$PROJECT_ROOT/pyproject.toml" 2>/dev/null)
            fi

            [[ "$deps" == *"django"* ]] && frameworks+="Django, "
            [[ "$deps" == *"flask"* ]] && frameworks+="Flask, "
            [[ "$deps" == *"fastapi"* ]] && frameworks+="FastAPI, "
            [[ "$deps" == *"pytest"* ]] && frameworks+="pytest, "
            ;;
        go)
            if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
                local deps=$(cat "$PROJECT_ROOT/go.mod" 2>/dev/null)

                [[ "$deps" == *"gin-gonic"* ]] && frameworks+="Gin, "
                [[ "$deps" == *"gorilla/mux"* ]] && frameworks+="Gorilla Mux, "
                [[ "$deps" == *"fiber"* ]] && frameworks+="Fiber, "
                [[ "$deps" == *"echo"* ]] && frameworks+="Echo, "
            fi
            ;;
    esac

    # 마지막 쉼표 제거
    echo "${frameworks%, }"
}

# 4. 코딩 컨벤션 수집
collect_conventions() {
    local conventions=""

    # ESLint
    if [[ -f "$PROJECT_ROOT/.eslintrc.json" ]] || [[ -f "$PROJECT_ROOT/.eslintrc.js" ]] || [[ -f "$PROJECT_ROOT/.eslintrc" ]]; then
        conventions+="ESLint configured, "
    fi

    # Prettier
    if [[ -f "$PROJECT_ROOT/.prettierrc" ]] || [[ -f "$PROJECT_ROOT/.prettierrc.json" ]] || [[ -f "$PROJECT_ROOT/prettier.config.js" ]]; then
        conventions+="Prettier configured, "
    fi

    # EditorConfig
    if [[ -f "$PROJECT_ROOT/.editorconfig" ]]; then
        conventions+="EditorConfig present, "
    fi

    # Python: ruff, black, flake8
    if [[ -f "$PROJECT_ROOT/ruff.toml" ]] || [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        if grep -q "ruff" "$PROJECT_ROOT/pyproject.toml" 2>/dev/null; then
            conventions+="Ruff configured, "
        fi
        if grep -q "black" "$PROJECT_ROOT/pyproject.toml" 2>/dev/null; then
            conventions+="Black configured, "
        fi
    fi

    # Go: gofmt (기본)
    if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        conventions+="gofmt (Go standard), "
    fi

    # TypeScript
    if [[ -f "$PROJECT_ROOT/tsconfig.json" ]]; then
        conventions+="TypeScript configured, "
    fi

    echo "${conventions%, }"
}

# 5. 기존 패턴 샘플링
sample_patterns() {
    local project_type="$1"
    local ext=""
    local patterns=""

    case "$project_type" in
        nodejs) ext="ts" ;;
        python) ext="py" ;;
        go) ext="go" ;;
        rust) ext="rs" ;;
        java) ext="java" ;;
        *) ext="*" ;;
    esac

    # 최근 수정된 파일에서 함수/클래스 시그니처 추출
    local files=$(find "$PROJECT_ROOT" -name "*.$ext" -type f \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/dist/*" \
        ! -path "*/__pycache__/*" \
        ! -path "*/target/*" \
        ! -path "*/vendor/*" \
        -mtime -30 2>/dev/null | head -5)

    for file in $files; do
        case "$project_type" in
            nodejs)
                patterns+=$(grep -E "^(export )?(async )?function|^(export )?(abstract )?class|^(export )?const .* = " "$file" 2>/dev/null | head -2)
                ;;
            python)
                patterns+=$(grep -E "^(async )?def |^class " "$file" 2>/dev/null | head -2)
                ;;
            go)
                patterns+=$(grep -E "^func |^type .* struct" "$file" 2>/dev/null | head -2)
                ;;
        esac
        patterns+=$'\n'
    done

    echo "$patterns" | head -10 | tr '\n' '|' | sed 's/|$//'
}

# 6. 테스트 프레임워크 감지
detect_test_framework() {
    local project_type="$1"
    local test_fw=""

    case "$project_type" in
        nodejs)
            if [[ -f "$PROJECT_ROOT/package.json" ]]; then
                local dev_deps=$(jq -r '.devDependencies // {} | keys[]' "$PROJECT_ROOT/package.json" 2>/dev/null)

                [[ "$dev_deps" == *"jest"* ]] && test_fw+="Jest, "
                [[ "$dev_deps" == *"mocha"* ]] && test_fw+="Mocha, "
                [[ "$dev_deps" == *"vitest"* ]] && test_fw+="Vitest, "
                [[ "$dev_deps" == *"cypress"* ]] && test_fw+="Cypress, "
                [[ "$dev_deps" == *"playwright"* ]] && test_fw+="Playwright, "
            fi
            ;;
        python)
            test_fw="pytest (assumed), "
            ;;
        go)
            test_fw="go test (built-in), "
            ;;
    esac

    echo "${test_fw%, }"
}

# 7. 의존성 정보 수집
collect_dependencies() {
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        jq '{
            dependencies: (.dependencies // {} | keys | .[0:10]),
            devDependencies: (.devDependencies // {} | keys | .[0:10])
        }' "$PROJECT_ROOT/package.json" 2>/dev/null || echo '{}'
    elif [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
        echo '{"note": "pyproject.toml detected, parse separately"}'
    elif [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        echo '{"note": "go.mod detected, parse separately"}'
    else
        echo '{}'
    fi
}

# 8. 디렉토리 구조 수집
collect_structure() {
    find "$PROJECT_ROOT" -type d -maxdepth 3 \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/dist/*" \
        ! -path "*/__pycache__/*" \
        ! -path "*/target/*" \
        ! -path "*/vendor/*" \
        ! -path "*/.next/*" \
        ! -path "*/.nuxt/*" \
        2>/dev/null | head -25 | \
        jq -R -s 'split("\n") | map(select(. != ""))'
}

# 9. 패키지 매니저 감지
detect_package_manager() {
    if [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
        echo "pnpm"
    elif [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then
        echo "yarn"
    elif [[ -f "$PROJECT_ROOT/package-lock.json" ]]; then
        echo "npm"
    elif [[ -f "$PROJECT_ROOT/bun.lockb" ]]; then
        echo "bun"
    elif [[ -f "$PROJECT_ROOT/poetry.lock" ]]; then
        echo "poetry"
    elif [[ -f "$PROJECT_ROOT/Pipfile.lock" ]]; then
        echo "pipenv"
    elif [[ -f "$PROJECT_ROOT/go.sum" ]]; then
        echo "go modules"
    elif [[ -f "$PROJECT_ROOT/Cargo.lock" ]]; then
        echo "cargo"
    else
        echo "unknown"
    fi
}

# 메인 실행
log_info "Collecting project context from: $PROJECT_ROOT"

PROJECT_TYPE=$(detect_project_type)
log_info "Detected project type: $PROJECT_TYPE"

LANGUAGE_VERSION=$(get_language_version "$PROJECT_TYPE")
FRAMEWORK=$(detect_framework "$PROJECT_TYPE")
CONVENTIONS=$(collect_conventions)
PATTERNS=$(sample_patterns "$PROJECT_TYPE")
TEST_FRAMEWORK=$(detect_test_framework "$PROJECT_TYPE")
PACKAGE_MANAGER=$(detect_package_manager)
DEPENDENCIES=$(collect_dependencies)
STRUCTURE=$(collect_structure)

# JSON 출력 생성 (jq를 사용한 안전한 생성)
if command -v jq &>/dev/null; then
    jq -n \
        --arg project_type "$PROJECT_TYPE" \
        --arg language_version "$LANGUAGE_VERSION" \
        --arg framework "$FRAMEWORK" \
        --arg package_manager "$PACKAGE_MANAGER" \
        --arg test_framework "$TEST_FRAMEWORK" \
        --arg conventions "$CONVENTIONS" \
        --arg patterns "$PATTERNS" \
        --argjson dependencies "$DEPENDENCIES" \
        --argjson structure "$STRUCTURE" \
        --arg collected_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{
            project_type: $project_type,
            language_version: $language_version,
            framework: $framework,
            package_manager: $package_manager,
            test_framework: $test_framework,
            conventions: $conventions,
            patterns: $patterns,
            dependencies: $dependencies,
            structure: $structure,
            collected_at: $collected_at
        }' > "$OUTPUT_FILE"
else
    # jq 없으면 수동 이스케이프 사용
    cat > "$OUTPUT_FILE" << EOF
{
  "project_type": $(json_escape "$PROJECT_TYPE"),
  "language_version": $(json_escape "$LANGUAGE_VERSION"),
  "framework": $(json_escape "$FRAMEWORK"),
  "package_manager": $(json_escape "$PACKAGE_MANAGER"),
  "test_framework": $(json_escape "$TEST_FRAMEWORK"),
  "conventions": $(json_escape "$CONVENTIONS"),
  "patterns": $(json_escape "$PATTERNS"),
  "dependencies": $DEPENDENCIES,
  "structure": $STRUCTURE,
  "collected_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
fi

log_info "Context saved to: $OUTPUT_FILE"

# 요약 출력
echo ""
echo "=== Context Summary ==="
echo "Project Type: $PROJECT_TYPE"
echo "Language Version: $LANGUAGE_VERSION"
echo "Framework: ${FRAMEWORK:-none detected}"
echo "Package Manager: $PACKAGE_MANAGER"
echo "Test Framework: ${TEST_FRAMEWORK:-none detected}"
echo "Conventions: ${CONVENTIONS:-none detected}"
echo "======================="
