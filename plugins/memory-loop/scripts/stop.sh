#!/bin/bash
# Stop: Claude 응답 완료 시 상태 저장
# Memory Loop Plugin - oh-my-claude-code

set -euo pipefail

# ============================================
# Config 로드
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# config.json에서 설정 읽기
MEMORY_DIR_NAME=$(jq -r '.memoryDirectory // ".memory"' "$CONFIG_FILE" 2>/dev/null || echo ".memory")

# ============================================
# 환경 설정
# ============================================
MEMORY_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/$MEMORY_DIR_NAME"
STATE_FILE="$MEMORY_DIR/.state.json"

# ============================================
# 상태 저장
# ============================================
if [ -d "$MEMORY_DIR" ] && [ -f "$STATE_FILE" ]; then
  TIMESTAMP=$(date -Iseconds)
  UPDATED_STATE=$(jq --arg ts "$TIMESTAMP" '. + {last_stop: $ts}' "$STATE_FILE" 2>/dev/null)
  if [ -n "$UPDATED_STATE" ]; then
    echo "$UPDATED_STATE" > "$STATE_FILE"
  fi
fi

exit 0
