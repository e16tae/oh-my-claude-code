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

## 사용법

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

## 설정

`plugin.json`의 `config` 섹션에서 설정을 조정할 수 있습니다:

```json
{
  "config": {
    "fileCountThreshold": 10,
    "keywords": ["전체", "모든", "대량", "all", "entire", "bulk"],
    "memoryDirectory": ".memory"
  }
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
├── lib/
│   └── memory-utils.sh   # 공통 유틸리티
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
