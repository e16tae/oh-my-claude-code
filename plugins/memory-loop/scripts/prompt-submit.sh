#!/bin/bash
# UserPromptSubmit: 대량 작업 키워드 감지
# Memory Loop Plugin - oh-my-claude-code

set -euo pipefail

# ============================================
# Config 로드
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# config.json에서 설정 읽기
KEYWORDS=$(jq -r '.keywords | join("|")' "$CONFIG_FILE" 2>/dev/null || echo "")
MEMORY_DIR_NAME=$(jq -r '.memoryDirectory // ".memory"' "$CONFIG_FILE" 2>/dev/null || echo ".memory")

# fallback 키워드
if [ -z "$KEYWORDS" ]; then
  KEYWORDS="전체|모든|대량|all|entire|bulk|migration|refactor"
fi

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

# 프롬프트 추출 (Claude Code Hook Input 구조)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // .arguments // empty' 2>/dev/null || echo "")

# 프롬프트가 없으면 종료
if [ -z "$PROMPT" ]; then
  exit 0
fi

# 이미 활성화되어 있으면 스킵
if [ -d "$MEMORY_DIR" ]; then
  exit 0
fi

# ============================================
# 키워드 감지
# ============================================
if echo "$PROMPT" | grep -qiE "$KEYWORDS"; then
  # 메모리 시스템 활성화
  mkdir -p "$MEMORY_DIR"

  # 템플릿 파일 자동 복사
  copy_templates

  # 상태 파일 생성
  jq -n \
    --arg trigger "keyword" \
    --arg ts "$(date -Iseconds)" \
    '{activated: true, trigger: $trigger, keyword_matched: true, timestamp: $ts}' \
    > "$STATE_FILE"

  echo ""
  echo "======================================"
  echo "  Memory Loop 활성화됨 (키워드 감지)"
  echo "======================================"
  echo ""
  echo "  대량 작업 키워드가 감지되었습니다."
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

exit 0
