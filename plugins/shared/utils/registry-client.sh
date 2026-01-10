#!/bin/bash
# registry-client.sh - 플러그인 레지스트리 클라이언트
#
# 플러그인 레지스트리와 통신하여 플러그인 검색, 다운로드, 메타데이터 조회
#
# 사용법:
#   source registry-client.sh
#   registry_search "code generator"
#   registry_get_plugin "codex-cli"
#   registry_download "codex-cli" "1.2.0" "/tmp/download"

set -e

# 환경 변수로 설정 가능
REGISTRY_URL="${OMCC_REGISTRY_URL:-https://registry.oh-my-claude-code.dev}"
CACHE_DIR="${OMCC_CACHE_DIR:-$HOME/.cache/oh-my-claude-code}"
CACHE_TTL="${OMCC_CACHE_TTL:-3600}"  # 1시간

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[REGISTRY]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[REGISTRY]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[REGISTRY]${NC} $1" >&2
}

log_debug() {
    if [[ "${OMCC_DEBUG:-}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" >&2
    fi
}

# 캐시 디렉토리 초기화
init_cache() {
    mkdir -p "$CACHE_DIR"
    mkdir -p "$CACHE_DIR/plugins"
    mkdir -p "$CACHE_DIR/downloads"
}

# 캐시에서 읽기
# @param $1 - 캐시 키
# @return - 캐시된 내용 또는 빈 문자열
cache_get() {
    local key="$1"
    local cache_file="$CACHE_DIR/$key"

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)))

        if [[ $file_age -lt $CACHE_TTL ]]; then
            log_debug "Cache hit: $key"
            cat "$cache_file"
            return 0
        else
            log_debug "Cache expired: $key"
        fi
    fi
    return 1
}

# 캐시에 저장 (원자적 쓰기 + JSON 검증)
# @param $1 - 캐시 키
# @param $2 - 내용
cache_set() {
    local key="$1"
    local content="$2"
    local cache_file="$CACHE_DIR/$key"

    # JSON 파일인 경우 유효성 검증
    if [[ "$key" == *.json ]]; then
        if ! echo "$content" | jq empty 2>/dev/null; then
            log_error "Invalid JSON content, refusing to cache: $key"
            return 1
        fi
    fi

    mkdir -p "$(dirname "$cache_file")"

    # 원자적 쓰기: 임시 파일에 쓰고 이동
    local temp_file
    temp_file=$(mktemp "${cache_file}.XXXXXX") || {
        log_error "Failed to create temp file for cache"
        return 1
    }

    if echo "$content" > "$temp_file"; then
        mv -f "$temp_file" "$cache_file"
        log_debug "Cache set: $key"
        return 0
    else
        rm -f "$temp_file"
        log_error "Failed to write cache: $key"
        return 1
    fi
}

# 캐시 무효화
# @param $1 - 캐시 키 패턴 (glob)
cache_invalidate() {
    local pattern="${1:-*}"
    rm -f "$CACHE_DIR"/$pattern 2>/dev/null || true
    log_debug "Cache invalidated: $pattern"
}

# 레지스트리 상태 확인
# @return - 0 (온라인), 1 (오프라인)
registry_ping() {
    if curl -s --connect-timeout 5 "$REGISTRY_URL/health" > /dev/null 2>&1; then
        log_info "Registry online: $REGISTRY_URL"
        return 0
    else
        log_warn "Registry offline or unreachable: $REGISTRY_URL"
        return 1
    fi
}

# 레지스트리 인덱스 가져오기
# @return - JSON 인덱스
registry_get_index() {
    init_cache

    local cached
    if cached=$(cache_get "registry-index.json"); then
        echo "$cached"
        return 0
    fi

    log_info "Fetching registry index..."

    local response
    response=$(curl -s --connect-timeout 10 "$REGISTRY_URL/index.json" 2>/dev/null)

    if [[ -n "$response" ]] && echo "$response" | jq empty 2>/dev/null; then
        cache_set "registry-index.json" "$response"
        echo "$response"
        return 0
    else
        log_error "Failed to fetch registry index"
        return 1
    fi
}

# 문자열 이스케이프 (jq 인젝션 방지)
# @param $1 - 이스케이프할 문자열
escape_jq_string() {
    local str="$1"
    # 백슬래시, 따옴표, 제어문자 이스케이프
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# 플러그인 검색
# @param $1 - 검색어
# @param $2 - (선택) 카테고리 필터
# @param $3 - (선택) 결과 제한
# @return - JSON 검색 결과
registry_search() {
    local query="$1"
    local category="${2:-}"
    local limit="${3:-20}"

    log_info "Searching: $query"

    local index
    index=$(registry_get_index) || return 1

    # 검색어 이스케이프 (jq 인젝션 방지)
    local safe_query
    safe_query=$(escape_jq_string "$query")
    local safe_category
    safe_category=$(escape_jq_string "$category")

    # jq로 검색 수행
    local filter=".plugins | to_entries | map(select("
    filter+=".value.name | test(\"$safe_query\"; \"i\")"
    filter+=" or .value.description | test(\"$safe_query\"; \"i\")"
    filter+=" or (.value.keywords // [] | any(. | test(\"$safe_query\"; \"i\")))"
    filter+="))"

    if [[ -n "$category" ]]; then
        filter+=" | map(select(.value.categories // [] | any(. == \"$safe_category\")))"
    fi

    filter+=" | .[0:$limit] | map(.value)"

    local results
    results=$(echo "$index" | jq -r "$filter" 2>/dev/null)

    if [[ "$results" == "null" ]] || [[ "$results" == "[]" ]]; then
        log_warn "No plugins found for: $query"
        echo "[]"
        return 0
    fi

    echo "$results"
}

# 플러그인 정보 가져오기
# @param $1 - 플러그인 이름
# @return - JSON 플러그인 정보
registry_get_plugin() {
    local plugin_name="$1"

    init_cache

    local cached
    if cached=$(cache_get "plugins/$plugin_name.json"); then
        echo "$cached"
        return 0
    fi

    log_info "Fetching plugin info: $plugin_name"

    # 먼저 인덱스에서 찾기
    local index
    index=$(registry_get_index) || return 1

    local plugin_info
    plugin_info=$(echo "$index" | jq -r ".plugins[\"$plugin_name\"] // empty" 2>/dev/null)

    if [[ -n "$plugin_info" ]] && [[ "$plugin_info" != "null" ]]; then
        cache_set "plugins/$plugin_name.json" "$plugin_info"
        echo "$plugin_info"
        return 0
    fi

    # 직접 API 호출
    local response
    response=$(curl -s --connect-timeout 10 "$REGISTRY_URL/plugins/$plugin_name.json" 2>/dev/null)

    if [[ -n "$response" ]] && echo "$response" | jq empty 2>/dev/null; then
        cache_set "plugins/$plugin_name.json" "$response"
        echo "$response"
        return 0
    else
        log_error "Plugin not found: $plugin_name"
        return 1
    fi
}

# 플러그인 버전 목록 가져오기
# @param $1 - 플러그인 이름
# @return - 버전 목록 (공백 구분)
registry_get_versions() {
    local plugin_name="$1"

    local plugin_info
    plugin_info=$(registry_get_plugin "$plugin_name") || return 1

    local versions
    versions=$(echo "$plugin_info" | jq -r '.versions | keys | .[]' 2>/dev/null | tr '\n' ' ')

    echo "$versions"
}

# 플러그인 최신 버전 가져오기
# @param $1 - 플러그인 이름
# @return - 최신 버전
registry_get_latest() {
    local plugin_name="$1"

    local plugin_info
    plugin_info=$(registry_get_plugin "$plugin_name") || return 1

    local latest
    latest=$(echo "$plugin_info" | jq -r '.latest // empty' 2>/dev/null)

    if [[ -n "$latest" ]]; then
        echo "$latest"
        return 0
    else
        log_error "Latest version not found for: $plugin_name"
        return 1
    fi
}

# 플러그인 다운로드 URL 가져오기
# @param $1 - 플러그인 이름
# @param $2 - 버전 (latest 또는 특정 버전)
# @return - 다운로드 URL
registry_get_download_url() {
    local plugin_name="$1"
    local version="${2:-latest}"

    local plugin_info
    plugin_info=$(registry_get_plugin "$plugin_name") || return 1

    # latest인 경우 실제 버전 해석
    if [[ "$version" == "latest" ]]; then
        version=$(echo "$plugin_info" | jq -r '.latest' 2>/dev/null)
    fi

    local tarball
    tarball=$(echo "$plugin_info" | jq -r ".versions[\"$version\"].tarball // empty" 2>/dev/null)

    if [[ -n "$tarball" ]]; then
        echo "$tarball"
        return 0
    else
        log_error "Download URL not found for $plugin_name@$version"
        return 1
    fi
}

# 플러그인 무결성 해시 가져오기
# @param $1 - 플러그인 이름
# @param $2 - 버전
# @return - 무결성 해시
registry_get_integrity() {
    local plugin_name="$1"
    local version="$2"

    local plugin_info
    plugin_info=$(registry_get_plugin "$plugin_name") || return 1

    local integrity
    integrity=$(echo "$plugin_info" | jq -r ".versions[\"$version\"].integrity // empty" 2>/dev/null)

    if [[ -n "$integrity" ]]; then
        echo "$integrity"
        return 0
    else
        return 1
    fi
}

# 플러그인 다운로드
# @param $1 - 플러그인 이름
# @param $2 - 버전
# @param $3 - 출력 경로
# @return - 다운로드된 파일 경로
registry_download() {
    local plugin_name="$1"
    local version="${2:-latest}"
    local output_dir="${3:-$CACHE_DIR/downloads}"

    init_cache

    # 버전 해석
    if [[ "$version" == "latest" ]]; then
        version=$(registry_get_latest "$plugin_name") || return 1
    fi

    local output_file="$output_dir/${plugin_name}-${version}.tar.gz"

    # 캐시 확인
    if [[ -f "$output_file" ]]; then
        log_info "Using cached download: $output_file"
        echo "$output_file"
        return 0
    fi

    # 다운로드 URL 가져오기
    local url
    url=$(registry_get_download_url "$plugin_name" "$version") || return 1

    log_info "Downloading $plugin_name@$version..."
    log_debug "URL: $url"

    mkdir -p "$output_dir"

    # 다운로드 (타임아웃 설정: 연결 10초, 전체 5분)
    if curl -L -o "$output_file" --progress-bar --connect-timeout 10 --max-time 300 "$url" 2>/dev/null; then
        # 무결성 검증
        local expected_hash
        expected_hash=$(registry_get_integrity "$plugin_name" "$version")

        if [[ -n "$expected_hash" ]]; then
            local actual_hash
            actual_hash=$(shasum -a 256 "$output_file" | cut -d' ' -f1)

            # SRI 형식 처리
            if [[ "$expected_hash" =~ ^sha256- ]]; then
                local expected_base64="${expected_hash#sha256-}"
                local actual_base64=$(echo "$actual_hash" | xxd -r -p | base64)
                if [[ "$actual_base64" != "$expected_base64" ]]; then
                    log_error "Integrity check failed!"
                    rm -f "$output_file"
                    return 1
                fi
            elif [[ "$actual_hash" != "$expected_hash" ]]; then
                log_error "Integrity check failed!"
                rm -f "$output_file"
                return 1
            fi

            log_info "Integrity verified"
        fi

        log_info "Downloaded: $output_file"
        echo "$output_file"
        return 0
    else
        log_error "Download failed: $url"
        return 1
    fi
}

# 카테고리 목록 가져오기
# @return - JSON 카테고리 목록
registry_get_categories() {
    local index
    index=$(registry_get_index) || return 1

    echo "$index" | jq -r '.categories // {}' 2>/dev/null
}

# 검색 결과 포맷팅 (테이블)
format_search_results() {
    local results="$1"

    if [[ "$results" == "[]" ]]; then
        echo "No plugins found."
        return
    fi

    echo ""
    echo "| Plugin | Description | Version | Downloads |"
    echo "|--------|-------------|---------|-----------|"

    echo "$results" | jq -r '.[] | "| \(.name) | \(.description // "-" | .[0:40]) | \(.latest // "-") | \(.downloads.total // "-") |"' 2>/dev/null

    echo ""
}

# 직접 실행시 테스트
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "registry-client.sh - Plugin Registry Client"
    echo ""
    echo "Configuration:"
    echo "  REGISTRY_URL: $REGISTRY_URL"
    echo "  CACHE_DIR:    $CACHE_DIR"
    echo "  CACHE_TTL:    $CACHE_TTL seconds"
    echo ""
    echo "Functions available:"
    echo "  registry_ping                     - Check registry status"
    echo "  registry_search <query>           - Search plugins"
    echo "  registry_get_plugin <name>        - Get plugin info"
    echo "  registry_get_versions <name>      - List available versions"
    echo "  registry_get_latest <name>        - Get latest version"
    echo "  registry_download <name> [ver]    - Download plugin"
    echo "  registry_get_categories           - List categories"
    echo ""
    echo "Example:"
    echo "  source $0"
    echo "  registry_search 'code generator'"
    echo "  registry_download 'codex-cli' '1.2.0'"
fi
