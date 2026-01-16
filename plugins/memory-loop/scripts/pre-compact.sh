#!/bin/bash
# PreCompact: 컨텍스트 압축 전 메모리 파일 자동 생성 및 업데이트 강제
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
# 템플릿 복사 함수
# ============================================
copy_templates() {
  if [ -d "$TEMPLATE_DIR" ]; then
    for template in "$TEMPLATE_DIR"/*.md; do
      if [ -f "$template" ]; then
        filename=$(basename "$template")
        target="$MEMORY_DIR/$filename"
        if [ ! -f "$target" ]; then
          cp "$template" "$target"
        fi
      fi
    done
  fi
}

# ============================================
# 메모리 디렉토리 없으면 자동 생성
# ============================================
if [ ! -d "$MEMORY_DIR" ]; then
  # 메모리 시스템 자동 활성화
  mkdir -p "$MEMORY_DIR"

  # 템플릿 파일 자동 복사
  copy_templates

  # 상태 파일 생성
  jq -n \
    --arg trigger "pre_compact" \
    --arg ts "$(date -Iseconds)" \
    '{activated: true, trigger: $trigger, auto_created_on_compact: true, timestamp: $ts}' \
    > "$STATE_FILE"

  echo ""
  echo "=========================================="
  echo "  Memory Loop: 컨텍스트 압축 임박!"
  echo "=========================================="
  echo ""
  echo "  [자동 생성] $MEMORY_DIR_NAME/ 디렉토리와 파일이"
  echo "              자동으로 생성되었습니다."
  echo ""
  echo "  지금 바로 메모리 파일을 작성하세요:"
  echo ""
  echo "  1. context.md"
  echo "     - 'Mission'에 작업 목표 작성"
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
else
  # 기존 메모리 디렉토리 존재 - 누락 파일 확인 및 생성
  copy_templates

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
