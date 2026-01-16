#!/bin/bash
# SessionStart: 세션 시작 시 기존 메모리 파일 복구 및 누락 파일 자동 생성
# Memory Loop Plugin - oh-my-claude-code

set -euo pipefail

# ============================================
# Config 로드
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# config.json에서 설정 읽기
MEMORY_DIR_NAME=$(jq -r '.memoryDirectory // ".memory"' "$CONFIG_FILE" 2>/dev/null || echo ".memory")

# ============================================
# 환경 설정
# ============================================
MEMORY_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/$MEMORY_DIR_NAME"
STATE_FILE="$MEMORY_DIR/.state.json"

# ============================================
# 템플릿 복사 함수 (누락된 파일만)
# ============================================
copy_missing_templates() {
  if [ -d "$TEMPLATE_DIR" ]; then
    local copied=0
    for template in "$TEMPLATE_DIR"/*.md; do
      if [ -f "$template" ]; then
        filename=$(basename "$template")
        target="$MEMORY_DIR/$filename"
        if [ ! -f "$target" ]; then
          cp "$template" "$target"
          copied=$((copied + 1))
        fi
      fi
    done
    echo "$copied"
  else
    echo "0"
  fi
}

# ============================================
# 기존 메모리 파일 확인 및 복구
# ============================================
if [ -d "$MEMORY_DIR" ]; then
  # 파일 존재 여부 확인
  HAS_CONTEXT=$([ -f "$MEMORY_DIR/context.md" ] && echo "O" || echo "X")
  HAS_TODOS=$([ -f "$MEMORY_DIR/todos.md" ] && echo "O" || echo "X")
  HAS_INSIGHTS=$([ -f "$MEMORY_DIR/insights.md" ] && echo "O" || echo "X")

  # 누락된 파일 자동 생성
  COPIED=$(copy_missing_templates)

  # 상태 파일 업데이트
  if [ -f "$STATE_FILE" ]; then
    TIMESTAMP=$(date -Iseconds)
    UPDATED_STATE=$(jq --arg ts "$TIMESTAMP" '. + {last_session_start: $ts, session_recovered: true}' "$STATE_FILE" 2>/dev/null)
    if [ -n "$UPDATED_STATE" ]; then
      echo "$UPDATED_STATE" > "$STATE_FILE"
    fi
  fi

  echo ""
  echo "======================================"
  echo "  Memory Loop: 세션 복구"
  echo "======================================"
  echo ""
  echo "  기존 메모리 파일:"
  echo "    - context.md:  $HAS_CONTEXT"
  echo "    - todos.md:    $HAS_TODOS"
  echo "    - insights.md: $HAS_INSIGHTS"

  if [ "$COPIED" -gt 0 ]; then
    echo ""
    echo "  [자동 생성] 누락된 ${COPIED}개 파일이 생성되었습니다."
  fi

  echo ""
  echo "  [중요] $MEMORY_DIR_NAME/ 파일들을 읽고"
  echo "        중단점부터 작업을 재개하세요."
  echo ""
  echo "======================================"
  echo ""
fi

exit 0
