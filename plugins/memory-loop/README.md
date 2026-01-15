# Memory Loop Plugin

무제한 기억력 시스템 - Context/Todos/Insights 파일로 메모리를 외부화하여 대량 작업 시 컨텍스트 리셋에도 작업을 지속할 수 있습니다.

## 개요

AI의 컨텍스트 윈도우 한계를 극복하기 위한 플러그인입니다. 대량 작업 시 자동으로 활성화되며, 3개의 마크다운 파일로 작업 상태를 외부에 저장합니다.

### 핵심 개념

| 파일 | 용도 |
|-----|-----|
| `context.md` | 작업 목표 및 현재 상태 (컨텍스트 리셋 후 복구용) |
| `todos.md` | 체크리스트 (진행률 추적, 중단점 파악) |
| `insights.md` | 발견사항 기록 (학습한 내용 영구 저장) |

## 설치

```bash
# oh-my-claude-code 마켓플레이스에서 설치
claude plugin install memory-loop
```

## 작동 방식

### 자동 활성화 조건

플러그인은 다음 조건에서 자동으로 활성화됩니다:

1. **키워드 감지**: 프롬프트에 대량 작업 키워드 포함 시
   - 한국어: "전체", "모든", "대량", "리팩토링", "마이그레이션"
   - 영어: "all", "entire", "bulk", "migration", "refactor"

2. **파일 수 감지**: Glob 도구로 10개 이상의 파일이 검색될 때

### Hook 이벤트

| Hook | 동작 |
|------|-----|
| `SessionStart` | 기존 `.memory/` 디렉토리 발견 시 복구 메시지 출력 |
| `UserPromptSubmit` | 대량 작업 키워드 감지 → 활성화 알림 |
| `PostToolUse` | Glob 실행 후 파일 수 확인 → 자동 활성화 |
| `PreCompact` | 컨텍스트 압축 전 메모리 파일 업데이트 경고 |
| `Stop` | Claude 응답 완료 시 상태 저장 |

## 사용 예시

### 예시 1: 키워드로 자동 활성화

```
사용자: 전체 컴포넌트를 TypeScript로 마이그레이션해줘

======================================
  Memory Loop 활성화됨 (키워드 감지)
======================================

  대량 작업 키워드가 감지되었습니다.

  다음 파일들을 .memory/ 에 생성하세요:
    - context.md  : 작업 목표 및 현재 상태
    - todos.md    : 체크리스트
    - insights.md : 발견사항 기록

======================================
```

### 예시 2: 파일 수로 자동 활성화

```
사용자: src/ 폴더의 모든 파일 분석해줘

(Glob 실행 → 15개 파일 감지)

======================================
  Memory Loop 활성화됨 (파일 수 감지)
======================================

  파일 15개가 감지되었습니다.
  (임계값: 10개)

  대량 작업입니다.
  다음 파일들을 .memory/ 에 생성하세요:
    - context.md  : 작업 목표 및 현재 상태
    - todos.md    : 체크리스트
    - insights.md : 발견사항 기록

======================================
```

### 예시 3: 세션 복구

```
(새 세션 시작, 기존 .memory/ 발견)

======================================
  Memory Loop: 기존 메모리 파일 발견
======================================

  - context.md: O
  - todos.md: O
  - insights.md: O

  [중요] 먼저 .memory/ 파일들을 읽고
        중단점부터 작업을 재개하세요.

======================================
```

### 예시 4: 컨텍스트 압축 경고

```
(컨텍스트 윈도우 한계 근접)

==========================================
  Memory Loop: 컨텍스트 압축 임박!
==========================================

  지금 바로 메모리 파일을 업데이트하세요:

  1. context.md
     - 'Current State' 섹션을 최신 상태로
     - 'Next Steps'에 다음 작업 명시

  2. todos.md
     - 완료된 항목 체크
     - 진행 중인 항목 표시

  3. insights.md
     - 중요한 발견사항 기록

==========================================
```

## 실제 워크플로우

### 1. 자동 활성화 후

플러그인이 활성화되면 `.memory/` 디렉토리가 생성됩니다. 다음 파일들을 생성하세요:

```
.memory/
├── context.md    # 작업 목표 및 현재 상태
├── todos.md      # 체크리스트
└── insights.md   # 발견사항
```

### 2. 템플릿 활용

`templates/` 디렉토리에 각 파일의 템플릿이 있습니다. 복사해서 사용하세요:

```bash
cp plugins/memory-loop/templates/* .memory/
```

### 3. 작업 중

- 매 작업 단위 완료 시 `todos.md` 체크박스 업데이트
- 중요 발견 시 `insights.md`에 즉시 기록
- 주요 마일스톤 완료 시 `context.md` "Current State" 업데이트

### 4. 컨텍스트 리셋 후

1. `.memory/` 파일들 읽기
2. `context.md`의 "Next Steps" 확인
3. `todos.md`의 미완료 항목 확인
4. 중단점부터 작업 재개

## 메모리 파일 작성 예시

### context.md

```markdown
# Migration: JavaScript → TypeScript

## Objective
src/components/ 내 모든 .js 파일을 .tsx로 변환

## Current State
- 15개 중 8개 컴포넌트 완료
- Button, Card, Modal 완료
- Form 관련 컴포넌트 진행 중

## Key Decisions
- strict 모드 활성화
- React.FC 대신 일반 함수 컴포넌트 사용
- Props는 interface로 정의

## Next Steps
1. FormInput.js 변환 완료
2. FormSelect.js 변환
3. 타입 정의 파일 통합
```

### todos.md

```markdown
# TypeScript Migration Checklist

## Completed
- [x] Button.js → Button.tsx
- [x] Card.js → Card.tsx
- [x] Modal.js → Modal.tsx

## In Progress
- [ ] FormInput.js → FormInput.tsx (70%)

## Pending
- [ ] FormSelect.js
- [ ] FormTextarea.js
- [ ] Table.js
- [ ] Pagination.js
```

### insights.md

```markdown
# Migration Insights

## 2024-01-15

### Props 패턴
기존 `propTypes` 정의를 `interface`로 1:1 변환 가능.
`defaultProps`는 함수 파라미터 기본값으로 대체.

### 타입 추론
`useState` 초기값이 있으면 타입 명시 불필요.
빈 배열은 `useState<Item[]>([])` 형태로 명시 필요.

### 주의사항
`any` 타입 사용 금지 → `unknown` 사용 후 타입 가드 적용
```

## 설정

`config.json` 파일에서 설정을 조정할 수 있습니다:

```json
{
  "fileCountThreshold": 10,
  "keywords": ["전체", "모든", "대량", "all", "entire", "bulk", "migration", "refactor", "리팩토링", "마이그레이션"],
  "memoryDirectory": ".memory"
}
```

| 옵션 | 기본값 | 설명 |
|-----|-------|-----|
| `fileCountThreshold` | 10 | 자동 활성화 파일 수 임계값 |
| `keywords` | [...] | 자동 활성화 키워드 목록 |
| `memoryDirectory` | ".memory" | 메모리 파일 저장 디렉토리 |

## 파일 구조

```
plugins/memory-loop/
├── .claude-plugin/
│   └── plugin.json       # 플러그인 매니페스트 + Hook 정의
├── scripts/
│   ├── session-start.sh  # 세션 시작 시 복구
│   ├── prompt-submit.sh  # 키워드 감지
│   ├── post-tool-use.sh  # 파일 수 감지
│   ├── pre-compact.sh    # 압축 전 경고
│   └── stop.sh           # 상태 저장
├── templates/
│   ├── context.md        # context.md 템플릿
│   ├── todos.md          # todos.md 템플릿
│   └── insights.md       # insights.md 템플릿
├── config.json           # 플러그인 설정
└── README.md
```

## 비활성화

메모리 시스템 없이 작업하려면:

- 프롬프트에 "메모리 없이" 또는 "without memory" 포함
- `.memory/` 디렉토리 삭제

## 참고

이 플러그인은 Dylan Davis의 "무제한 기억력" 워크플로우를 기반으로 합니다.

## 라이선스

MIT License
