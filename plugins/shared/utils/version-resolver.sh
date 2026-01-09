#!/bin/bash
# version-resolver.sh - Semver 버전 해석 및 비교
#
# Semantic Versioning (semver) 버전 파싱, 비교, 범위 해석
#
# 사용법:
#   source version-resolver.sh
#   semver_compare "1.2.3" "1.10.0"
#   semver_satisfies "1.5.0" "^1.0.0"
#   semver_resolve "^1.0.0" '["1.0.0", "1.5.0", "2.0.0"]'

set -e

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[VERSION]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[VERSION]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[VERSION]${NC} $1" >&2
}

# Semver 파싱
# @param $1 - 버전 문자열
# @return - "major minor patch prerelease build" 형식
semver_parse() {
    local version="$1"

    # 선행 v 제거
    version="${version#v}"

    # 정규식으로 파싱
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z.-]+))?(\+([0-9A-Za-z.-]+))?$ ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        local prerelease="${BASH_REMATCH[5]:-}"
        local build="${BASH_REMATCH[7]:-}"

        echo "$major $minor $patch $prerelease $build"
        return 0
    else
        log_error "Invalid semver: $version"
        return 1
    fi
}

# 버전 비교
# @param $1 - 버전 1
# @param $2 - 버전 2
# @return - -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
semver_compare() {
    local v1="$1"
    local v2="$2"

    # 선행 v 제거
    v1="${v1#v}"
    v2="${v2#v}"

    # 동일하면 0
    if [[ "$v1" == "$v2" ]]; then
        echo 0
        return 0
    fi

    # 파싱
    local parsed1 parsed2
    parsed1=$(semver_parse "$v1") || return 1
    parsed2=$(semver_parse "$v2") || return 1

    read -r major1 minor1 patch1 pre1 build1 <<< "$parsed1"
    read -r major2 minor2 patch2 pre2 build2 <<< "$parsed2"

    # major 비교
    if [[ $major1 -lt $major2 ]]; then
        echo -1
        return 0
    elif [[ $major1 -gt $major2 ]]; then
        echo 1
        return 0
    fi

    # minor 비교
    if [[ $minor1 -lt $minor2 ]]; then
        echo -1
        return 0
    elif [[ $minor1 -gt $minor2 ]]; then
        echo 1
        return 0
    fi

    # patch 비교
    if [[ $patch1 -lt $patch2 ]]; then
        echo -1
        return 0
    elif [[ $patch1 -gt $patch2 ]]; then
        echo 1
        return 0
    fi

    # prerelease 비교 (없는 것이 더 높음)
    if [[ -z "$pre1" ]] && [[ -n "$pre2" ]]; then
        echo 1
        return 0
    elif [[ -n "$pre1" ]] && [[ -z "$pre2" ]]; then
        echo -1
        return 0
    elif [[ -n "$pre1" ]] && [[ -n "$pre2" ]]; then
        # 문자열 비교
        if [[ "$pre1" < "$pre2" ]]; then
            echo -1
        elif [[ "$pre1" > "$pre2" ]]; then
            echo 1
        else
            echo 0
        fi
        return 0
    fi

    echo 0
    return 0
}

# 버전이 범위를 만족하는지 검사
# @param $1 - 버전
# @param $2 - 범위 (예: ^1.0.0, ~1.2.0, >=1.0.0 <2.0.0)
# @return - 0 (만족), 1 (불만족)
semver_satisfies() {
    local version="$1"
    local range="$2"

    version="${version#v}"

    # 정확한 버전
    if [[ "$range" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] && [[ ! "$range" =~ [~^<>=] ]]; then
        if [[ "$version" == "$range" ]]; then
            return 0
        else
            return 1
        fi
    fi

    # ^ (caret) 범위 - major 버전 호환
    if [[ "$range" =~ ^\^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        local range_major="${BASH_REMATCH[1]}"
        local range_minor="${BASH_REMATCH[2]}"
        local range_patch="${BASH_REMATCH[3]}"

        local parsed
        parsed=$(semver_parse "$version") || return 1
        read -r v_major v_minor v_patch _ _ <<< "$parsed"

        # ^0.0.x: 정확한 버전만
        if [[ $range_major -eq 0 ]] && [[ $range_minor -eq 0 ]]; then
            if [[ $v_major -eq 0 ]] && [[ $v_minor -eq 0 ]] && [[ $v_patch -eq $range_patch ]]; then
                return 0
            fi
            return 1
        fi

        # ^0.y.z: 0.y.* 범위
        if [[ $range_major -eq 0 ]]; then
            if [[ $v_major -eq 0 ]] && [[ $v_minor -eq $range_minor ]] && [[ $v_patch -ge $range_patch ]]; then
                return 0
            fi
            return 1
        fi

        # ^x.y.z: x.*.* 범위 (x >= range_major의 최신)
        if [[ $v_major -eq $range_major ]]; then
            if [[ $v_minor -gt $range_minor ]]; then
                return 0
            elif [[ $v_minor -eq $range_minor ]] && [[ $v_patch -ge $range_patch ]]; then
                return 0
            fi
        fi
        return 1
    fi

    # ~ (tilde) 범위 - minor 버전 호환
    if [[ "$range" =~ ^~([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        local range_major="${BASH_REMATCH[1]}"
        local range_minor="${BASH_REMATCH[2]}"
        local range_patch="${BASH_REMATCH[3]}"

        local parsed
        parsed=$(semver_parse "$version") || return 1
        read -r v_major v_minor v_patch _ _ <<< "$parsed"

        if [[ $v_major -eq $range_major ]] && [[ $v_minor -eq $range_minor ]] && [[ $v_patch -ge $range_patch ]]; then
            return 0
        fi
        return 1
    fi

    # >= 범위
    if [[ "$range" =~ ^\>=([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        local min_ver="${BASH_REMATCH[1]}"
        local cmp
        cmp=$(semver_compare "$version" "$min_ver")
        if [[ $cmp -ge 0 ]]; then
            return 0
        fi
        return 1
    fi

    # > 범위
    if [[ "$range" =~ ^\>([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        local min_ver="${BASH_REMATCH[1]}"
        local cmp
        cmp=$(semver_compare "$version" "$min_ver")
        if [[ $cmp -gt 0 ]]; then
            return 0
        fi
        return 1
    fi

    # <= 범위
    if [[ "$range" =~ ^\<=([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        local max_ver="${BASH_REMATCH[1]}"
        local cmp
        cmp=$(semver_compare "$version" "$max_ver")
        if [[ $cmp -le 0 ]]; then
            return 0
        fi
        return 1
    fi

    # < 범위
    if [[ "$range" =~ ^\<([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        local max_ver="${BASH_REMATCH[1]}"
        local cmp
        cmp=$(semver_compare "$version" "$max_ver")
        if [[ $cmp -lt 0 ]]; then
            return 0
        fi
        return 1
    fi

    # * 또는 x (any version)
    if [[ "$range" == "*" ]] || [[ "$range" == "x" ]]; then
        return 0
    fi

    log_warn "Unknown range format: $range"
    return 1
}

# 복합 범위 검사 (>=1.0.0 <2.0.0)
# @param $1 - 버전
# @param $2 - 복합 범위
semver_satisfies_range() {
    local version="$1"
    local range="$2"

    # 공백으로 분리된 조건들을 모두 만족해야 함
    for condition in $range; do
        if ! semver_satisfies "$version" "$condition"; then
            return 1
        fi
    done
    return 0
}

# 버전 목록에서 범위를 만족하는 최신 버전 찾기
# @param $1 - 범위
# @param $2 - 버전 목록 (JSON 배열 또는 공백 구분)
# @return - 최적 버전
semver_resolve() {
    local range="$1"
    local versions="$2"

    # JSON 배열인 경우 파싱
    if [[ "$versions" == \[* ]]; then
        versions=$(echo "$versions" | jq -r '.[]' 2>/dev/null | tr '\n' ' ')
    fi

    local best_version=""
    local best_cmp=-2

    for ver in $versions; do
        ver="${ver#v}"
        ver="${ver//\"/}"  # 따옴표 제거

        if semver_satisfies "$ver" "$range"; then
            if [[ -z "$best_version" ]]; then
                best_version="$ver"
            else
                local cmp
                cmp=$(semver_compare "$ver" "$best_version")
                if [[ $cmp -gt 0 ]]; then
                    best_version="$ver"
                fi
            fi
        fi
    done

    if [[ -n "$best_version" ]]; then
        echo "$best_version"
        return 0
    else
        log_error "No version satisfies range: $range"
        return 1
    fi
}

# 버전 목록 정렬 (오름차순)
# @param $1 - 버전 목록 (공백 구분)
# @return - 정렬된 목록
semver_sort() {
    local versions="$1"

    # 버전들을 배열로 변환
    local -a ver_array=($versions)

    # 버블 정렬 (작은 목록용)
    local n=${#ver_array[@]}
    for ((i = 0; i < n-1; i++)); do
        for ((j = 0; j < n-i-1; j++)); do
            local cmp
            cmp=$(semver_compare "${ver_array[j]}" "${ver_array[j+1]}")
            if [[ $cmp -gt 0 ]]; then
                # 스왑
                local tmp="${ver_array[j]}"
                ver_array[j]="${ver_array[j+1]}"
                ver_array[j+1]="$tmp"
            fi
        done
    done

    echo "${ver_array[*]}"
}

# 버전 증가
# @param $1 - 버전
# @param $2 - 타입 (major, minor, patch)
# @return - 새 버전
semver_increment() {
    local version="$1"
    local type="$2"

    version="${version#v}"

    local parsed
    parsed=$(semver_parse "$version") || return 1
    read -r major minor patch pre build <<< "$parsed"

    case "$type" in
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        *)
            log_error "Unknown increment type: $type"
            return 1
            ;;
    esac

    echo "${major}.${minor}.${patch}"
}

# 버전 유효성 검사
# @param $1 - 버전
# @return - 0 (유효), 1 (무효)
semver_valid() {
    local version="$1"
    version="${version#v}"

    if semver_parse "$version" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 두 버전 중 더 높은 버전 반환
# @param $1 - 버전 1
# @param $2 - 버전 2
# @return - 더 높은 버전
semver_max() {
    local v1="$1"
    local v2="$2"

    local cmp
    cmp=$(semver_compare "$v1" "$v2")

    if [[ $cmp -ge 0 ]]; then
        echo "$v1"
    else
        echo "$v2"
    fi
}

# 두 버전 중 더 낮은 버전 반환
# @param $1 - 버전 1
# @param $2 - 버전 2
# @return - 더 낮은 버전
semver_min() {
    local v1="$1"
    local v2="$2"

    local cmp
    cmp=$(semver_compare "$v1" "$v2")

    if [[ $cmp -le 0 ]]; then
        echo "$v1"
    else
        echo "$v2"
    fi
}

# 직접 실행시 테스트
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "version-resolver.sh - Semver Utilities"
    echo ""
    echo "Functions available:"
    echo "  semver_parse <version>            - Parse semver components"
    echo "  semver_compare <v1> <v2>          - Compare versions (-1, 0, 1)"
    echo "  semver_satisfies <ver> <range>    - Check if version matches range"
    echo "  semver_resolve <range> <versions> - Find best matching version"
    echo "  semver_sort <versions>            - Sort version list"
    echo "  semver_increment <ver> <type>     - Increment version"
    echo "  semver_valid <version>            - Check if valid semver"
    echo "  semver_max <v1> <v2>              - Return higher version"
    echo "  semver_min <v1> <v2>              - Return lower version"
    echo ""
    echo "Examples:"
    echo "  semver_compare '1.2.0' '1.10.0'   # Returns: -1"
    echo "  semver_satisfies '1.5.0' '^1.0.0' # Returns: 0 (true)"
    echo "  semver_resolve '^1.0.0' '1.0.0 1.5.0 2.0.0'  # Returns: 1.5.0"

    if [[ $# -ge 2 ]]; then
        echo ""
        echo "--- Running: semver_compare $1 $2 ---"
        result=$(semver_compare "$1" "$2")
        echo "Result: $result"

        if [[ $result -lt 0 ]]; then
            echo "$1 < $2"
        elif [[ $result -gt 0 ]]; then
            echo "$1 > $2"
        else
            echo "$1 == $2"
        fi
    fi
fi
