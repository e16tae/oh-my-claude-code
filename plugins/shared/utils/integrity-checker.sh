#!/bin/bash
# integrity-checker.sh - 플러그인 무결성 검증
#
# SHA256 해시 및 GPG 서명을 통한 플러그인 무결성 검증
#
# 사용법:
#   source integrity-checker.sh
#   generate_hash /path/to/file
#   verify_hash /path/to/file expected_hash
#   verify_signature /path/to/file /path/to/signature

set -e

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INTEGRITY]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[INTEGRITY]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[INTEGRITY]${NC} $1" >&2
}

# SHA256 해시 생성
# @param $1 - 파일 경로
# @return - 해시 문자열 (64자 hex)
generate_hash() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        return 1
    fi

    if command -v shasum &> /dev/null; then
        shasum -a 256 "$file_path" | cut -d' ' -f1
    elif command -v sha256sum &> /dev/null; then
        sha256sum "$file_path" | cut -d' ' -f1
    else
        log_error "Neither shasum nor sha256sum found"
        return 1
    fi
}

# 디렉토리 전체 해시 생성 (tarball용)
# @param $1 - 디렉토리 경로
# @return - 해시 문자열
generate_directory_hash() {
    local dir_path="$1"

    if [[ ! -d "$dir_path" ]]; then
        log_error "Directory not found: $dir_path"
        return 1
    fi

    # 모든 파일의 해시를 정렬하여 결합
    find "$dir_path" -type f \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        -exec shasum -a 256 {} \; 2>/dev/null | \
        sort | \
        shasum -a 256 | \
        cut -d' ' -f1
}

# 해시 검증
# @param $1 - 파일 경로
# @param $2 - 예상 해시
# @return - 0 (일치), 1 (불일치)
verify_hash() {
    local file_path="$1"
    local expected_hash="$2"

    if [[ -z "$expected_hash" ]]; then
        log_error "Expected hash not provided"
        return 1
    fi

    local actual_hash
    actual_hash=$(generate_hash "$file_path")

    if [[ "$actual_hash" == "$expected_hash" ]]; then
        log_info "Hash verified: $file_path"
        return 0
    else
        log_error "Hash mismatch for $file_path"
        log_error "  Expected: $expected_hash"
        log_error "  Actual:   $actual_hash"
        return 1
    fi
}

# SRI (Subresource Integrity) 형식 해시 생성
# @param $1 - 파일 경로
# @param $2 - 알고리즘 (sha256, sha384, sha512)
# @return - SRI 형식 문자열 (예: sha256-base64hash)
generate_sri_hash() {
    local file_path="$1"
    local algorithm="${2:-sha256}"

    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        return 1
    fi

    local hash_binary
    case "$algorithm" in
        sha256)
            hash_binary=$(shasum -a 256 "$file_path" | cut -d' ' -f1 | xxd -r -p | base64)
            ;;
        sha384)
            hash_binary=$(shasum -a 384 "$file_path" | cut -d' ' -f1 | xxd -r -p | base64)
            ;;
        sha512)
            hash_binary=$(shasum -a 512 "$file_path" | cut -d' ' -f1 | xxd -r -p | base64)
            ;;
        *)
            log_error "Unsupported algorithm: $algorithm"
            return 1
            ;;
    esac

    echo "${algorithm}-${hash_binary}"
}

# SRI 형식 해시 검증
# @param $1 - 파일 경로
# @param $2 - SRI 해시 (예: sha256-base64hash)
# @return - 0 (일치), 1 (불일치)
verify_sri_hash() {
    local file_path="$1"
    local sri_hash="$2"

    # SRI 형식 파싱
    local algorithm="${sri_hash%%-*}"
    local expected_base64="${sri_hash#*-}"

    local actual_sri
    actual_sri=$(generate_sri_hash "$file_path" "$algorithm")

    if [[ "$actual_sri" == "$sri_hash" ]]; then
        log_info "SRI hash verified: $file_path"
        return 0
    else
        log_error "SRI hash mismatch for $file_path"
        return 1
    fi
}

# GPG 서명 검증
# @param $1 - 파일 경로
# @param $2 - 서명 파일 경로 (.sig 또는 .asc)
# @param $3 - (선택) 키링 경로
# @return - 0 (유효), 1 (무효)
verify_signature() {
    local file_path="$1"
    local sig_path="$2"
    local keyring="${3:-}"

    if ! command -v gpg &> /dev/null; then
        log_warn "GPG not installed, skipping signature verification"
        return 0
    fi

    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        return 1
    fi

    if [[ ! -f "$sig_path" ]]; then
        log_warn "Signature file not found: $sig_path"
        return 1
    fi

    local gpg_opts=()
    if [[ -n "$keyring" ]]; then
        gpg_opts+=("--keyring" "$keyring")
    fi

    if gpg "${gpg_opts[@]}" --verify "$sig_path" "$file_path" 2>/dev/null; then
        log_info "Signature verified: $file_path"
        return 0
    else
        log_error "Invalid signature for $file_path"
        return 1
    fi
}

# GPG 서명 생성
# @param $1 - 파일 경로
# @param $2 - (선택) 출력 서명 파일 경로
# @param $3 - (선택) 서명 키 ID
# @return - 서명 파일 경로
create_signature() {
    local file_path="$1"
    local sig_path="${2:-${file_path}.sig}"
    local key_id="${3:-}"

    if ! command -v gpg &> /dev/null; then
        log_error "GPG not installed"
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        return 1
    fi

    local gpg_opts=("--detach-sign" "--armor" "--output" "$sig_path")
    if [[ -n "$key_id" ]]; then
        gpg_opts+=("--local-user" "$key_id")
    fi

    if gpg "${gpg_opts[@]}" "$file_path" 2>/dev/null; then
        log_info "Signature created: $sig_path"
        echo "$sig_path"
        return 0
    else
        log_error "Failed to create signature"
        return 1
    fi
}

# 플러그인 디렉토리 무결성 검증
# @param $1 - 플러그인 디렉토리
# @param $2 - (선택) plugin.json 내 integrity 필드와 비교
# @return - 0 (유효), 1 (무효)
verify_plugin_integrity() {
    local plugin_dir="$1"
    local check_manifest="${2:-true}"

    if [[ ! -d "$plugin_dir" ]]; then
        log_error "Plugin directory not found: $plugin_dir"
        return 1
    fi

    local plugin_json="$plugin_dir/.claude-plugin/plugin.json"

    if [[ "$check_manifest" == "true" ]] && [[ -f "$plugin_json" ]]; then
        # plugin.json에서 integrity 필드 읽기
        local expected_hash
        expected_hash=$(jq -r '.integrity.hash // empty' "$plugin_json" 2>/dev/null)
        local algorithm
        algorithm=$(jq -r '.integrity.algorithm // "sha256"' "$plugin_json" 2>/dev/null)

        if [[ -n "$expected_hash" ]]; then
            log_info "Verifying plugin integrity against manifest..."

            # 현재 해시 계산 (plugin.json 자체는 제외)
            local actual_hash
            actual_hash=$(find "$plugin_dir" -type f \
                ! -path "*/.claude-plugin/plugin.json" \
                ! -path "*/.git/*" \
                -exec shasum -a 256 {} \; 2>/dev/null | \
                sort | \
                shasum -a 256 | \
                cut -d' ' -f1)

            if [[ "$actual_hash" == "$expected_hash" ]]; then
                log_info "Plugin integrity verified: $plugin_dir"
                return 0
            else
                log_error "Plugin integrity check failed"
                log_error "  Expected: $expected_hash"
                log_error "  Actual:   $actual_hash"
                return 1
            fi
        fi
    fi

    # integrity 필드가 없으면 구조만 검증
    log_warn "No integrity hash in manifest, skipping hash verification"
    return 0
}

# 체크섬 파일 생성 (배포용)
# @param $1 - 플러그인 디렉토리
# @param $2 - (선택) 출력 파일 경로
generate_checksums() {
    local plugin_dir="$1"
    local output="${2:-checksums.txt}"

    if [[ ! -d "$plugin_dir" ]]; then
        log_error "Plugin directory not found: $plugin_dir"
        return 1
    fi

    log_info "Generating checksums for $plugin_dir..."

    # 원자적 쓰기: 임시 파일에 먼저 쓰고 이동
    local temp_file
    temp_file=$(mktemp "${output}.XXXXXX") || {
        log_error "Failed to create temp file for checksums"
        return 1
    }

    if find "$plugin_dir" -type f \
        ! -path "*/.git/*" \
        ! -path "*/node_modules/*" \
        ! -name "checksums.txt" \
        -exec shasum -a 256 {} \; 2>/dev/null | \
        sort > "$temp_file"; then

        mv -f "$temp_file" "$output"
        log_info "Checksums saved to: $output"
    else
        rm -f "$temp_file"
        log_error "Failed to generate checksums"
        return 1
    fi
    echo "$output"
}

# 체크섬 파일 검증
# @param $1 - 체크섬 파일 경로
# @param $2 - (선택) 기준 디렉토리
# @return - 0 (모두 유효), 1 (불일치 있음)
verify_checksums() {
    local checksum_file="$1"
    local base_dir="${2:-.}"

    if [[ ! -f "$checksum_file" ]]; then
        log_error "Checksum file not found: $checksum_file"
        return 1
    fi

    local failed=0

    while IFS=' ' read -r expected_hash file_path; do
        # 경로에서 불필요한 문자 제거
        file_path="${file_path#\*}"

        if [[ ! -f "$file_path" ]]; then
            log_error "Missing file: $file_path"
            ((failed++))
            continue
        fi

        local actual_hash
        actual_hash=$(generate_hash "$file_path")

        if [[ "$actual_hash" != "$expected_hash" ]]; then
            log_error "Checksum mismatch: $file_path"
            ((failed++))
        fi
    done < "$checksum_file"

    if [[ $failed -eq 0 ]]; then
        log_info "All checksums verified successfully"
        return 0
    else
        log_error "$failed file(s) failed checksum verification"
        return 1
    fi
}

# 직접 실행시 테스트
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "integrity-checker.sh - Utility functions"
    echo ""
    echo "Functions available:"
    echo "  generate_hash <file>              - Generate SHA256 hash"
    echo "  verify_hash <file> <expected>     - Verify file hash"
    echo "  generate_sri_hash <file> [algo]   - Generate SRI format hash"
    echo "  verify_sri_hash <file> <sri>      - Verify SRI hash"
    echo "  verify_signature <file> <sig>     - Verify GPG signature"
    echo "  create_signature <file> [output]  - Create GPG signature"
    echo "  verify_plugin_integrity <dir>     - Verify plugin integrity"
    echo "  generate_checksums <dir>          - Generate checksum file"
    echo "  verify_checksums <file>           - Verify checksum file"
    echo ""
    echo "Example:"
    echo "  source $0"
    echo "  generate_hash /path/to/plugin.tar.gz"
fi
