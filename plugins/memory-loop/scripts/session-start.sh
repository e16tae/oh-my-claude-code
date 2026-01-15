#!/bin/bash
# SessionStart: 세션 시작 시 기존 메모리 파일 복구
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

# ============================================
# 기존 메모리 파일 확인
# ============================================
if [ -d "$MEMORY_DIR" ]; then
  # 기존 메모리 파일 발견 → 복구 메시지 출력
  echo ""
  echo "======================================"
  echo "  Memory Loop: 기존 메모리 파일 발견"
  echo "======================================"
  echo ""
  echo "  - context.md: $([ -f "$MEMORY_DIR/context.md" ] && echo "O" || echo "X")"
  echo "  - todos.md: $([ -f "$MEMORY_DIR/todos.md" ] && echo "O" || echo "X")"
  echo "  - insights.md: $([ -f "$MEMORY_DIR/insights.md" ] && echo "O" || echo "X")"
  echo ""
  echo "  [중요] 먼저 $MEMORY_DIR_NAME/ 파일들을 읽고"
  echo "        중단점부터 작업을 재개하세요."
  echo ""
  echo "======================================"
  echo ""
fi

exit 0
