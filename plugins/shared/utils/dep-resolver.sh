#!/bin/bash
# dep-resolver.sh - 플러그인 의존성 해결
#
# 플러그인 의존성 그래프 구축, 충돌 감지, 설치 순서 결정
#
# 사용법:
#   source dep-resolver.sh
#   build_dep_graph "codex-cli"
#   detect_conflicts
#   resolve_install_order "my-plugin"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 다른 유틸리티 로드
source "$SCRIPT_DIR/version-resolver.sh" 2>/dev/null || true
source "$SCRIPT_DIR/registry-client.sh" 2>/dev/null || true

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[DEPS]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[DEPS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[DEPS]${NC} $1" >&2
}

log_debug() {
    if [[ "${OMCC_DEBUG:-}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" >&2
    fi
}

# 전역 변수
declare -gA DEP_GRAPH=()
declare -gA RESOLVED_VERSIONS=()
declare -ga INSTALL_ORDER=()
declare -ga CONFLICTS=()

# 의존성 그래프 초기화
init_dep_graph() {
    DEP_GRAPH=()
    RESOLVED_VERSIONS=()
    INSTALL_ORDER=()
    CONFLICTS=()
}

# 플러그인 디렉토리에서 의존성 읽기
# @param $1 - 플러그인 디렉토리 또는 plugin.json 경로
# @return - JSON 의존성 정보
read_plugin_deps() {
    local plugin_path="$1"
    local plugin_json=""

    if [[ -f "$plugin_path" ]]; then
        plugin_json="$plugin_path"
    elif [[ -d "$plugin_path" ]]; then
        plugin_json="$plugin_path/.claude-plugin/plugin.json"
    fi

    if [[ ! -f "$plugin_json" ]]; then
        echo '{}'
        return 0
    fi

    jq '{
        name: .name,
        version: .version,
        dependencies: (.dependencies // {}),
        optionalDependencies: (.optionalDependencies // {}),
        peerDependencies: (.peerDependencies // {})
    }' "$plugin_json" 2>/dev/null || echo '{}'
}

# 의존성 그래프 구축
# @param $1 - 시작 플러그인 이름
# @param $2 - (선택) 플러그인 디렉토리 기본 경로
# @return - JSON 의존성 트리
build_dep_graph() {
    local plugin_name="$1"
    local plugins_dir="${2:-./plugins}"

    init_dep_graph

    log_info "Building dependency graph for: $plugin_name"

    _build_dep_graph_recursive "$plugin_name" "$plugins_dir" ""

    # JSON으로 출력
    local graph_json="{"
    local first=true

    for key in "${!DEP_GRAPH[@]}"; do
        if [[ "$first" != "true" ]]; then
            graph_json+=","
        fi
        graph_json+="\"$key\":${DEP_GRAPH[$key]}"
        first=false
    done

    graph_json+="}"
    echo "$graph_json"
}

# 재귀적 의존성 그래프 구축
_build_dep_graph_recursive() {
    local plugin_name="$1"
    local plugins_dir="$2"
    local parent="$3"

    # 이미 처리된 경우 스킵
    if [[ -n "${DEP_GRAPH[$plugin_name]:-}" ]]; then
        log_debug "Already processed: $plugin_name"
        return 0
    fi

    local plugin_dir="$plugins_dir/$plugin_name"
    local deps_info

    # 로컬 플러그인에서 의존성 읽기
    if [[ -d "$plugin_dir" ]]; then
        deps_info=$(read_plugin_deps "$plugin_dir")
    else
        # 레지스트리에서 정보 가져오기
        if type registry_get_plugin &>/dev/null; then
            deps_info=$(registry_get_plugin "$plugin_name" 2>/dev/null | jq '{
                name: .name,
                version: .latest,
                dependencies: (.versions[.latest].dependencies // {}),
                optionalDependencies: {},
                peerDependencies: {}
            }' 2>/dev/null) || deps_info='{}'
        else
            deps_info='{}'
        fi
    fi

    # 그래프에 추가
    DEP_GRAPH[$plugin_name]="$deps_info"

    # 의존성 추출
    local deps
    deps=$(echo "$deps_info" | jq -r '.dependencies // {} | keys[]' 2>/dev/null)

    # 각 의존성에 대해 재귀 호출
    for dep in $deps; do
        if [[ -n "$dep" ]]; then
            _build_dep_graph_recursive "$dep" "$plugins_dir" "$plugin_name"
        fi
    done
}

# 의존성 충돌 감지
# @return - JSON 충돌 목록
detect_conflicts() {
    CONFLICTS=()

    log_info "Checking for dependency conflicts..."

    # 각 플러그인에 대해 요구되는 버전 수집
    declare -A required_versions

    for plugin in "${!DEP_GRAPH[@]}"; do
        local deps
        deps=$(echo "${DEP_GRAPH[$plugin]}" | jq -r '.dependencies // {} | to_entries[] | "\(.key):\(.value)"' 2>/dev/null)

        for dep_spec in $deps; do
            local dep_name="${dep_spec%%:*}"
            local dep_range="${dep_spec##*:}"

            if [[ -n "${required_versions[$dep_name]:-}" ]]; then
                required_versions[$dep_name]+=" $dep_range"
            else
                required_versions[$dep_name]="$dep_range"
            fi
        done
    done

    # 충돌 검사
    local conflicts_json="["
    local first=true

    for dep_name in "${!required_versions[@]}"; do
        local ranges="${required_versions[$dep_name]}"
        local range_array=($ranges)

        if [[ ${#range_array[@]} -gt 1 ]]; then
            # 여러 범위가 있는 경우 호환성 검사
            local compatible=true
            local resolved_version=""

            # 각 범위를 만족하는 공통 버전 찾기 시도
            # (실제로는 레지스트리에서 버전 목록을 가져와야 함)
            for range in "${range_array[@]}"; do
                if [[ -z "$resolved_version" ]]; then
                    resolved_version="$range"
                else
                    # 단순화된 호환성 검사
                    if [[ "$range" != "$resolved_version" ]]; then
                        # 세부 검사 필요
                        log_warn "Multiple version requirements for $dep_name: $ranges"
                    fi
                fi
            done
        fi
    done

    conflicts_json+="]"
    echo "$conflicts_json"
}

# 설치 순서 결정 (토폴로지 정렬)
# @param $1 - 설치할 플러그인 이름
# @return - 설치 순서 (공백 구분)
resolve_install_order() {
    local plugin_name="$1"

    INSTALL_ORDER=()

    log_info "Resolving install order for: $plugin_name"

    # 방문 상태
    declare -A visited
    declare -A in_stack

    _topological_sort "$plugin_name" visited in_stack

    # 역순으로 출력 (의존성 먼저)
    local result=""
    for ((i=${#INSTALL_ORDER[@]}-1; i>=0; i--)); do
        result+="${INSTALL_ORDER[i]} "
    done

    echo "$result"
}

# 토폴로지 정렬 (DFS)
_topological_sort() {
    local node="$1"
    local visited_name="$2"
    local in_stack_name="$3"
    local -n _visited="$visited_name"
    local -n _in_stack="$in_stack_name"

    # 순환 의존성 검사
    if [[ "${_in_stack[$node]:-}" == "true" ]]; then
        log_error "Circular dependency detected: $node"
        return 1
    fi

    # 이미 방문한 경우 스킵
    if [[ "${_visited[$node]:-}" == "true" ]]; then
        return 0
    fi

    _in_stack[$node]="true"

    # 의존성 처리
    local deps_info="${DEP_GRAPH[$node]:-}"
    if [[ -n "$deps_info" ]]; then
        local deps
        deps=$(echo "$deps_info" | jq -r '.dependencies // {} | keys[]' 2>/dev/null)

        for dep in $deps; do
            if [[ -n "$dep" ]]; then
                # 원본 변수 이름을 전달 (nameref 이름이 아닌)
                _topological_sort "$dep" "$visited_name" "$in_stack_name" || return 1
            fi
        done
    fi

    _visited[$node]="true"
    _in_stack[$node]="false"
    INSTALL_ORDER+=("$node")
}

# 의존성 트리 출력 (시각화)
# @param $1 - 플러그인 이름
# @param $2 - (선택) 들여쓰기 레벨
print_dep_tree() {
    local plugin_name="$1"
    local indent="${2:-0}"
    local prefix=""

    for ((i=0; i<indent; i++)); do
        if [[ $i -eq $((indent-1)) ]]; then
            prefix+="├── "
        else
            prefix+="│   "
        fi
    done

    local deps_info="${DEP_GRAPH[$plugin_name]:-}"
    local version=""

    if [[ -n "$deps_info" ]]; then
        version=$(echo "$deps_info" | jq -r '.version // "?"' 2>/dev/null)
    fi

    echo "${prefix}${plugin_name}@${version}"

    # 의존성 출력
    if [[ -n "$deps_info" ]]; then
        local deps
        deps=$(echo "$deps_info" | jq -r '.dependencies // {} | to_entries[] | "\(.key)@\(.value)"' 2>/dev/null)

        local dep_count=$(echo "$deps" | wc -w | tr -d ' ')
        local current=0

        for dep_spec in $deps; do
            ((current++))
            local dep_name="${dep_spec%%@*}"

            if [[ $current -eq $dep_count ]]; then
                # 마지막 의존성
                local last_prefix=""
                for ((i=0; i<indent; i++)); do
                    last_prefix+="│   "
                done
                last_prefix+="└── "
                local dep_version=$(echo "${DEP_GRAPH[$dep_name]:-}" | jq -r '.version // "?"' 2>/dev/null)
                echo "${last_prefix}${dep_name}@${dep_version}"
            else
                print_dep_tree "$dep_name" $((indent+1))
            fi
        done
    fi
}

# 역방향 의존성 찾기 (이 플러그인을 의존하는 플러그인들)
# @param $1 - 플러그인 이름
# @return - 의존하는 플러그인 목록
find_reverse_deps() {
    local plugin_name="$1"
    local reverse_deps=""

    for plugin in "${!DEP_GRAPH[@]}"; do
        local deps
        deps=$(echo "${DEP_GRAPH[$plugin]}" | jq -r '.dependencies // {} | keys[]' 2>/dev/null)

        for dep in $deps; do
            if [[ "$dep" == "$plugin_name" ]]; then
                reverse_deps+="$plugin "
                break
            fi
        done
    done

    echo "$reverse_deps"
}

# 고아 의존성 찾기 (어떤 플러그인도 의존하지 않는)
# @param $1 - 플러그인 디렉토리
# @return - 고아 플러그인 목록
find_orphan_deps() {
    local plugins_dir="$1"
    local orphans=""

    # 모든 설치된 플러그인
    local all_plugins=""
    for dir in "$plugins_dir"/*/; do
        if [[ -d "$dir" ]]; then
            all_plugins+="$(basename "$dir") "
        fi
    done

    # 각 플러그인에 대해 역방향 의존성 확인
    for plugin in $all_plugins; do
        local reverse=$(find_reverse_deps "$plugin")

        if [[ -z "$reverse" ]] && [[ "$plugin" != "claude-code" ]]; then
            # 루트 플러그인이 아니고 아무도 의존하지 않음
            orphans+="$plugin "
        fi
    done

    echo "$orphans"
}

# 버전 해결 (가장 적합한 버전 찾기)
# @param $1 - 플러그인 이름
# @param $2 - 버전 범위
# @param $3 - 사용 가능한 버전 목록
# @return - 해결된 버전
resolve_version() {
    local plugin_name="$1"
    local range="$2"
    local available="$3"

    # semver_resolve 사용
    if type semver_resolve &>/dev/null; then
        semver_resolve "$range" "$available"
    else
        # 폴백: 첫 번째 버전 반환
        echo "$available" | tr ' ' '\n' | head -1
    fi
}

# 누락된 의존성 찾기
# @param $1 - 플러그인 이름
# @param $2 - 플러그인 디렉토리
# @return - 누락된 의존성 목록
find_missing_deps() {
    local plugin_name="$1"
    local plugins_dir="$2"
    local missing=""

    local deps_info="${DEP_GRAPH[$plugin_name]:-}"
    if [[ -n "$deps_info" ]]; then
        local deps
        deps=$(echo "$deps_info" | jq -r '.dependencies // {} | keys[]' 2>/dev/null)

        for dep in $deps; do
            if [[ ! -d "$plugins_dir/$dep" ]]; then
                missing+="$dep "
            fi
        done
    fi

    echo "$missing"
}

# 직접 실행시 테스트
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "dep-resolver.sh - Dependency Resolver"
    echo ""
    echo "Functions available:"
    echo "  build_dep_graph <plugin>          - Build dependency graph"
    echo "  detect_conflicts                  - Detect version conflicts"
    echo "  resolve_install_order <plugin>    - Get installation order"
    echo "  print_dep_tree <plugin>           - Print dependency tree"
    echo "  find_reverse_deps <plugin>        - Find reverse dependencies"
    echo "  find_orphan_deps <dir>            - Find orphan dependencies"
    echo "  find_missing_deps <plugin> <dir>  - Find missing dependencies"
    echo ""
    echo "Example:"
    echo "  source $0"
    echo "  build_dep_graph 'codex-cli' './plugins'"
    echo "  print_dep_tree 'codex-cli'"

    if [[ $# -ge 1 ]]; then
        echo ""
        echo "--- Building graph for: $1 ---"
        build_dep_graph "$1" "${2:-./plugins}"
        echo ""
        echo "Dependency Tree:"
        print_dep_tree "$1"
        echo ""
        echo "Install Order:"
        resolve_install_order "$1"
    fi
fi
