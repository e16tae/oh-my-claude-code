#!/bin/bash
# Stop: Claude 응답 완료 시 상태 저장 및 작업 완료 감지
# Memory Loop Plugin - oh-my-claude-code

set -euo pipefail

# ============================================
# Config 로드
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# config.json에서 설정 읽기
MEMORY_DIR_NAME=$(jq -r '.memoryDirectory // ".memory"' "$CONFIG_FILE" 2>/dev/null || echo ".memory")
AUTO_ARCHIVE=$(jq -r '.autoArchive // false' "$CONFIG_FILE" 2>/dev/null || echo "false")
ARCHIVE_DIR_NAME=$(jq -r '.archiveDirectory // ".memory-archive"' "$CONFIG_FILE" 2>/dev/null || echo ".memory-archive")

# ============================================
# 환경 설정
# ============================================
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MEMORY_DIR="$PROJECT_DIR/$MEMORY_DIR_NAME"
ARCHIVE_DIR="$PROJECT_DIR/$ARCHIVE_DIR_NAME"
STATE_FILE="$MEMORY_DIR/.state.json"
TODOS_FILE="$MEMORY_DIR/todos.md"

# ============================================
# 작업 완료 감지 함수
# ============================================
check_completion() {
  if [ ! -f "$TODOS_FILE" ]; then
    echo "no_todos"
    return
  fi

  # 체크박스 카운트
  local total=$(grep -cE '^\s*-\s*\[[ x]\]' "$TODOS_FILE" 2>/dev/null || echo "0")
  local completed=$(grep -cE '^\s*-\s*\[x\]' "$TODOS_FILE" 2>/dev/null || echo "0")
  local pending=$(grep -cE '^\s*-\s*\[ \]' "$TODOS_FILE" 2>/dev/null || echo "0")

  if [ "$total" -eq 0 ]; then
    echo "no_todos"
  elif [ "$pending" -eq 0 ] && [ "$completed" -gt 0 ]; then
    echo "completed:$completed/$total"
  else
    echo "in_progress:$completed/$total"
  fi
}

# ============================================
# 아카이브 함수
# ============================================
archive_memory() {
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local archive_path="$ARCHIVE_DIR/$timestamp"

  mkdir -p "$archive_path"

  # 메모리 파일 복사
  cp -r "$MEMORY_DIR"/* "$archive_path/" 2>/dev/null || true

  # 아카이브 메타데이터 생성
  jq -n \
    --arg ts "$(date -Iseconds)" \
    --arg reason "auto_archive_on_completion" \
    '{archived_at: $ts, reason: $reason}' \
    > "$archive_path/.archive-meta.json"

  # 원본 삭제
  rm -rf "$MEMORY_DIR"

  echo "$archive_path"
}

# ============================================
# 메인 로직
# ============================================
if [ -d "$MEMORY_DIR" ]; then
  TIMESTAMP=$(date -Iseconds)

  # 작업 완료 상태 확인
  COMPLETION_STATUS=$(check_completion)

  # 상태 파일 업데이트
  if [ -f "$STATE_FILE" ]; then
    UPDATED_STATE=$(jq \
      --arg ts "$TIMESTAMP" \
      --arg status "$COMPLETION_STATUS" \
      '. + {last_stop: $ts, completion_status: $status}' "$STATE_FILE" 2>/dev/null)
    if [ -n "$UPDATED_STATE" ]; then
      echo "$UPDATED_STATE" > "$STATE_FILE"
    fi
  fi

  # 작업 완료 감지 시 처리
  if [[ "$COMPLETION_STATUS" == completed:* ]]; then
    if [ "$AUTO_ARCHIVE" = "true" ]; then
      # 자동 아카이브
      ARCHIVED_PATH=$(archive_memory)
      echo ""
      echo "======================================"
      echo "  Memory Loop: 작업 완료 & 자동 아카이브"
      echo "======================================"
      echo ""
      echo "  모든 할 일이 완료되었습니다!"
      echo "  (${COMPLETION_STATUS#completed:})"
      echo ""
      echo "  [아카이브 완료]"
      echo "  $ARCHIVED_PATH"
      echo ""
      echo "======================================"
      echo ""
    else
      # 완료 알림만 (아카이브는 수동)
      echo ""
      echo "======================================"
      echo "  Memory Loop: 작업 완료 감지"
      echo "======================================"
      echo ""
      echo "  모든 할 일이 완료되었습니다!"
      echo "  (${COMPLETION_STATUS#completed:})"
      echo ""
      echo "  정리하려면 $MEMORY_DIR_NAME/ 를 삭제하세요."
      echo "  또는 config.json에서 autoArchive: true 설정"
      echo ""
      echo "======================================"
      echo ""
    fi
  fi
fi

exit 0
