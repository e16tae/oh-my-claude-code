#!/bin/bash
# PreCompact: 컨텍스트 압축 전 메모리 파일 업데이트 강제
# Memory Loop Plugin - oh-my-claude-code

set -euo pipefail

# ============================================
# Config 로드
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_JSON="$SCRIPT_DIR/../.claude-plugin/plugin.json"

# plugin.json에서 config 읽기
MEMORY_DIR_NAME=$(jq -r '.config.memoryDirectory // ".memory"' "$PLUGIN_JSON" 2>/dev/null || echo ".memory")

# ============================================
# 환경 설정
# ============================================
MEMORY_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/$MEMORY_DIR_NAME"
STATE_FILE="$MEMORY_DIR/.state.json"

# ============================================
# 압축 전 경고
# ============================================
if [ -d "$MEMORY_DIR" ]; then
  # 상태 파일 업데이트
  if [ -f "$STATE_FILE" ]; then
    TIMESTAMP=$(date -Iseconds)
    UPDATED_STATE=$(jq --arg ts "$TIMESTAMP" '. + {last_compact_warning: $ts}' "$STATE_FILE" 2>/dev/null)
    if [ -n "$UPDATED_STATE" ]; then
      echo "$UPDATED_STATE" > "$STATE_FILE"
    fi
  fi

  echo ""
  echo "=========================================="
  echo "  Memory Loop: 컨텍스트 압축 임박!"
  echo "=========================================="
  echo ""
  echo "  지금 바로 메모리 파일을 업데이트하세요:"
  echo ""
  echo "  1. context.md"
  echo "     - 'Current State' 섹션을 최신 상태로"
  echo "     - 'Next Steps'에 다음 작업 명시"
  echo ""
  echo "  2. todos.md"
  echo "     - 완료된 항목 체크"
  echo "     - 진행 중인 항목 표시"
  echo ""
  echo "  3. insights.md"
  echo "     - 중요한 발견사항 기록"
  echo ""
  echo "=========================================="
  echo ""
fi

exit 0
