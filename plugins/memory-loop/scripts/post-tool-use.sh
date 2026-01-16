#!/bin/bash
# PostToolUse: Read/Glob/Grep 실행 후 파일 수 카운트
# Memory Loop Plugin - oh-my-claude-code

set -euo pipefail

# ============================================
# Config 로드
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# config.json에서 설정 읽기
THRESHOLD=$(jq -r '.fileCountThreshold // 10' "$CONFIG_FILE" 2>/dev/null || echo "10")
MEMORY_DIR_NAME=$(jq -r '.memoryDirectory // ".memory"' "$CONFIG_FILE" 2>/dev/null || echo ".memory")

# ============================================
# 환경 설정
# ============================================
MEMORY_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/$MEMORY_DIR_NAME"
STATE_FILE="$MEMORY_DIR/.state.json"

# ============================================
# 템플릿 복사 함수
# ============================================
copy_templates() {
  if [ -d "$TEMPLATE_DIR" ]; then
    for template in "$TEMPLATE_DIR"/*.md; do
      if [ -f "$template" ]; then
        filename=$(basename "$template")
        target="$MEMORY_DIR/$filename"
        # 이미 존재하면 덮어쓰지 않음
        if [ ! -f "$target" ]; then
          cp "$template" "$target"
        fi
      fi
    done
  fi
}

# ============================================
# stdin에서 JSON 입력 읽기
# ============================================
INPUT=$(cat)

# 도구 이름 추출
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

# 이미 활성화되어 있으면 스킵
if [ -d "$MEMORY_DIR" ]; then
  exit 0
fi

# ============================================
# Glob 결과에서 파일 수 추출
# ============================================
if [ "$TOOL_NAME" = "Glob" ]; then
  # jq로 파일 수 계산 (tool_output의 타입에 따라)
  FILE_COUNT=$(echo "$INPUT" | jq -r '
    if .tool_output then
      if (.tool_output | type) == "array" then (.tool_output | length)
      elif (.tool_output | type) == "string" then (.tool_output | split("\n") | map(select(length > 0)) | length)
      else 0
      end
    else 0
    end
  ' 2>/dev/null || echo "0")

  # 숫자 검증
  if ! [[ "$FILE_COUNT" =~ ^[0-9]+$ ]]; then
    FILE_COUNT=0
  fi

  if [ "$FILE_COUNT" -ge "$THRESHOLD" ]; then
    # 메모리 시스템 활성화
    mkdir -p "$MEMORY_DIR"

    # 템플릿 파일 자동 복사
    copy_templates

    # 상태 파일 생성
    jq -n \
      --arg trigger "file_count" \
      --argjson count "$FILE_COUNT" \
      --argjson threshold "$THRESHOLD" \
      --arg ts "$(date -Iseconds)" \
      '{activated: true, trigger: $trigger, file_count: $count, threshold: $threshold, timestamp: $ts}' \
      > "$STATE_FILE"

    echo ""
    echo "======================================"
    echo "  Memory Loop 활성화됨 (파일 수 감지)"
    echo "======================================"
    echo ""
    echo "  파일 ${FILE_COUNT}개가 감지되었습니다."
    echo "  (임계값: ${THRESHOLD}개)"
    echo ""
    echo "  $MEMORY_DIR_NAME/ 에 다음 파일들이 자동 생성되었습니다:"
    echo "    - context.md  : 작업 목표 및 현재 상태"
    echo "    - todos.md    : 체크리스트"
    echo "    - insights.md : 발견사항 기록"
    echo ""
    echo "  [중요] 작업 시작 전 context.md의 Mission을 작성하세요."
    echo ""
    echo "======================================"
    echo ""
  fi
fi

exit 0
