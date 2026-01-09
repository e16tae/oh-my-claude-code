#!/bin/bash
# github-handler.sh - GitHub 소스 플러그인 처리
#
# GitHub 저장소에서 플러그인을 다운로드하고 설치
#
# 사용법:
#   source github-handler.sh
#   github_parse_url "github:user/repo@v1.0.0"
#   github_download_release "user" "repo" "v1.0.0"
#   github_clone_plugin "user" "repo" "main" "/path/to/dest"

set -e

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[GITHUB]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[GITHUB]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[GITHUB]${NC} $1" >&2
}

log_debug() {
    if [[ "${OMCC_DEBUG:-}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" >&2
    fi
}

# GitHub CLI 확인
check_gh_cli() {
    if command -v gh &> /dev/null; then
        return 0
    else
        log_warn "GitHub CLI (gh) not found, falling back to curl"
        return 1
    fi
}

# GitHub URL 파싱
# @param $1 - URL (github:user/repo, github:user/repo@tag, https://github.com/user/repo)
# @return - "owner repo ref" 형식
github_parse_url() {
    local url="$1"
    local owner=""
    local repo=""
    local ref="main"

    # github:user/repo 또는 github:user/repo@tag 형식
    if [[ "$url" =~ ^github:([^/@]+)/([^@]+)(@(.+))?$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        ref="${BASH_REMATCH[4]:-main}"
        echo "$owner $repo $ref"
        return 0
    fi

    # https://github.com/user/repo 형식
    if [[ "$url" =~ ^https?://github\.com/([^/]+)/([^/@]+)(/tree/([^/]+))?.*$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        repo="${repo%.git}"  # .git 제거
        ref="${BASH_REMATCH[4]:-main}"
        echo "$owner $repo $ref"
        return 0
    fi

    # git@github.com:user/repo.git 형식
    if [[ "$url" =~ ^git@github\.com:([^/]+)/(.+)\.git$ ]]; then
        owner="${BASH_REMATCH[1]}"
        repo="${BASH_REMATCH[2]}"
        echo "$owner $repo $ref"
        return 0
    fi

    log_error "Invalid GitHub URL format: $url"
    return 1
}

# 저장소 정보 가져오기
# @param $1 - owner
# @param $2 - repo
# @return - JSON 저장소 정보
github_get_repo_info() {
    local owner="$1"
    local repo="$2"

    if check_gh_cli; then
        gh api "repos/$owner/$repo" 2>/dev/null
    else
        curl -s "https://api.github.com/repos/$owner/$repo" 2>/dev/null
    fi
}

# 릴리스 목록 가져오기
# @param $1 - owner
# @param $2 - repo
# @return - JSON 릴리스 목록
github_get_releases() {
    local owner="$1"
    local repo="$2"

    if check_gh_cli; then
        gh api "repos/$owner/$repo/releases" 2>/dev/null
    else
        curl -s "https://api.github.com/repos/$owner/$repo/releases" 2>/dev/null
    fi
}

# 최신 릴리스 태그 가져오기
# @param $1 - owner
# @param $2 - repo
# @return - 태그 이름
github_get_latest_release() {
    local owner="$1"
    local repo="$2"

    local releases
    releases=$(github_get_releases "$owner" "$repo") || return 1

    local latest
    latest=$(echo "$releases" | jq -r '.[0].tag_name // empty' 2>/dev/null)

    if [[ -n "$latest" ]]; then
        echo "$latest"
        return 0
    else
        log_warn "No releases found, using default branch"
        echo "main"
        return 0
    fi
}

# 릴리스 에셋 다운로드
# @param $1 - owner
# @param $2 - repo
# @param $3 - tag
# @param $4 - 출력 디렉토리
# @param $5 - (선택) 에셋 패턴 (기본: *.tar.gz)
# @return - 다운로드된 파일 경로
github_download_release() {
    local owner="$1"
    local repo="$2"
    local tag="$3"
    local output_dir="$4"
    local pattern="${5:-*.tar.gz}"

    mkdir -p "$output_dir"

    # tag가 latest면 실제 태그 조회
    if [[ "$tag" == "latest" ]]; then
        tag=$(github_get_latest_release "$owner" "$repo") || return 1
    fi

    log_info "Downloading release: $owner/$repo@$tag"

    local output_file="$output_dir/${repo}-${tag}.tar.gz"

    if check_gh_cli; then
        # gh CLI 사용
        if gh release download "$tag" \
            --repo "$owner/$repo" \
            --pattern "$pattern" \
            --output "$output_file" 2>/dev/null; then
            log_info "Downloaded: $output_file"
            echo "$output_file"
            return 0
        fi
    fi

    # 릴리스 에셋이 없는 경우 소스 tarball 다운로드
    log_info "Downloading source tarball..."
    local tarball_url="https://github.com/$owner/$repo/archive/refs/tags/$tag.tar.gz"

    if curl -L -o "$output_file" --progress-bar "$tarball_url" 2>/dev/null; then
        log_info "Downloaded: $output_file"
        echo "$output_file"
        return 0
    fi

    # 태그가 없는 경우 ref로 다운로드
    tarball_url="https://github.com/$owner/$repo/archive/$tag.tar.gz"

    if curl -L -o "$output_file" --progress-bar "$tarball_url" 2>/dev/null; then
        log_info "Downloaded: $output_file"
        echo "$output_file"
        return 0
    fi

    log_error "Failed to download release"
    return 1
}

# Git clone으로 플러그인 다운로드
# @param $1 - owner
# @param $2 - repo
# @param $3 - ref (branch, tag, commit)
# @param $4 - 출력 디렉토리
# @return - 클론된 디렉토리 경로
github_clone_plugin() {
    local owner="$1"
    local repo="$2"
    local ref="$3"
    local output_dir="$4"

    mkdir -p "$output_dir"

    local clone_url="https://github.com/$owner/$repo.git"
    local dest="$output_dir/$repo"

    log_info "Cloning: $owner/$repo@$ref"

    # 이미 존재하면 삭제
    rm -rf "$dest"

    # shallow clone
    if git clone --depth 1 --branch "$ref" "$clone_url" "$dest" 2>/dev/null; then
        log_info "Cloned: $dest"
        echo "$dest"
        return 0
    fi

    # 브랜치/태그가 없는 경우 기본 클론 후 체크아웃
    if git clone --depth 1 "$clone_url" "$dest" 2>/dev/null; then
        (cd "$dest" && git fetch --depth 1 origin "$ref" && git checkout FETCH_HEAD) 2>/dev/null
        log_info "Cloned: $dest"
        echo "$dest"
        return 0
    fi

    log_error "Failed to clone repository"
    return 1
}

# tarball 추출
# @param $1 - tarball 경로
# @param $2 - 출력 디렉토리
# @return - 추출된 디렉토리 경로
github_extract_tarball() {
    local tarball="$1"
    local output_dir="$2"

    mkdir -p "$output_dir"

    log_info "Extracting: $tarball"

    # 먼저 임시 디렉토리에 추출
    local temp_dir
    temp_dir=$(mktemp -d)

    if tar -xzf "$tarball" -C "$temp_dir" 2>/dev/null; then
        # 추출된 최상위 디렉토리 찾기 (보통 repo-version 형식)
        local extracted_dir
        extracted_dir=$(ls -d "$temp_dir"/*/ 2>/dev/null | head -1)

        if [[ -d "$extracted_dir" ]]; then
            # 내용물을 output_dir로 이동
            local plugin_name
            plugin_name=$(basename "$tarball" .tar.gz)
            local dest="$output_dir/$plugin_name"

            rm -rf "$dest"
            mv "$extracted_dir" "$dest"
            rm -rf "$temp_dir"

            log_info "Extracted: $dest"
            echo "$dest"
            return 0
        fi
    fi

    rm -rf "$temp_dir"
    log_error "Failed to extract tarball"
    return 1
}

# GitHub에서 플러그인 설치 (통합 함수)
# @param $1 - GitHub URL
# @param $2 - 출력 디렉토리
# @return - 설치된 플러그인 경로
github_install_plugin() {
    local url="$1"
    local output_dir="$2"

    # URL 파싱
    local parsed
    parsed=$(github_parse_url "$url") || return 1
    read -r owner repo ref <<< "$parsed"

    log_info "Installing from GitHub: $owner/$repo@$ref"

    # 먼저 릴리스 다운로드 시도
    local downloaded
    if downloaded=$(github_download_release "$owner" "$repo" "$ref" "$output_dir" 2>/dev/null); then
        # tarball 추출
        local extracted
        extracted=$(github_extract_tarball "$downloaded" "$output_dir") || return 1
        echo "$extracted"
        return 0
    fi

    # 릴리스가 없으면 git clone
    local cloned
    cloned=$(github_clone_plugin "$owner" "$repo" "$ref" "$output_dir") || return 1
    echo "$cloned"
    return 0
}

# 플러그인 plugin.json 읽기
# @param $1 - 플러그인 디렉토리
# @return - JSON 내용
github_read_plugin_json() {
    local plugin_dir="$1"

    local plugin_json="$plugin_dir/.claude-plugin/plugin.json"

    if [[ -f "$plugin_json" ]]; then
        cat "$plugin_json"
        return 0
    fi

    # 대체 위치 확인
    plugin_json="$plugin_dir/plugin.json"
    if [[ -f "$plugin_json" ]]; then
        cat "$plugin_json"
        return 0
    fi

    log_error "plugin.json not found in: $plugin_dir"
    return 1
}

# GitHub 저장소에서 버전 태그 목록 가져오기
# @param $1 - owner
# @param $2 - repo
# @return - 버전 목록 (공백 구분)
github_get_tags() {
    local owner="$1"
    local repo="$2"

    local tags

    if check_gh_cli; then
        tags=$(gh api "repos/$owner/$repo/tags" --jq '.[].name' 2>/dev/null | tr '\n' ' ')
    else
        tags=$(curl -s "https://api.github.com/repos/$owner/$repo/tags" | jq -r '.[].name' 2>/dev/null | tr '\n' ' ')
    fi

    echo "$tags"
}

# 직접 실행시 테스트
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "github-handler.sh - GitHub Plugin Handler"
    echo ""
    echo "Functions available:"
    echo "  github_parse_url <url>            - Parse GitHub URL"
    echo "  github_get_repo_info <owner> <repo>"
    echo "  github_get_releases <owner> <repo>"
    echo "  github_get_latest_release <owner> <repo>"
    echo "  github_download_release <owner> <repo> <tag> <dir>"
    echo "  github_clone_plugin <owner> <repo> <ref> <dir>"
    echo "  github_install_plugin <url> <dir>"
    echo "  github_get_tags <owner> <repo>"
    echo ""
    echo "URL formats supported:"
    echo "  github:user/repo"
    echo "  github:user/repo@v1.0.0"
    echo "  https://github.com/user/repo"
    echo "  https://github.com/user/repo/tree/branch"
    echo ""
    echo "Example:"
    echo "  source $0"
    echo "  github_install_plugin 'github:user/my-plugin@v1.0.0' './plugins'"

    if [[ $# -ge 1 ]]; then
        echo ""
        echo "--- Parsing: $1 ---"
        result=$(github_parse_url "$1")
        echo "Result: $result"
    fi
fi
