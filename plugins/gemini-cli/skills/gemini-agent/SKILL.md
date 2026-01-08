---
name: gemini-agent
description: |
  Google Gemini CLI를 서브 에이전트로 활용하는 코드 분석/리뷰 전문 스킬.

  ## 트리거 키워드
  다음 표현이 사용자 요청에 포함되면 이 스킬이 자동 활성화됩니다:
  - "gemini로", "gemini를 활용해", "gemini한테", "gemini 써서"
  - "gemini에게 물어봐", "gemini가 분석해", "gemini로 리뷰해"
  - "Google gemini", "제미나이로", "제미나이 활용"

  ## 주요 역할
  - 코드 리뷰 및 품질 분석
  - 보안 취약점 탐지
  - 성능 최적화 제안
  - 문서 및 주석 생성

  ## 적합한 작업
  - PR/코드 리뷰
  - 코드 품질 평가
  - 아키텍처 분석
  - 기술 문서 작성
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Gemini CLI Agent

Google Gemini CLI를 서브 에이전트로 호출하여 코드 분석 작업을 수행합니다.

---

## 1. 역할 전문화

### 1.1 분석 유형별 전문가 역할
분석 요청 유형에 따라 적절한 전문가 역할을 선택합니다:

| 분석 유형 | 역할 | 초점 영역 |
|----------|------|----------|
| 보안 분석 | 보안 분석 전문 시니어 엔지니어 | 취약점, 인증, 권한, 입력 검증 |
| 성능 분석 | 성능 엔지니어링 전문가 | 복잡도, 메모리, I/O, 병목 |
| 아키텍처 분석 | 소프트웨어 아키텍트 | 모듈화, 결합도, 확장성, 패턴 |
| 코드 품질 | 코드 품질 전문가 | 가독성, 유지보수성, 테스트 가능성 |
| 일반 리뷰 | 시니어 소프트웨어 엔지니어 | 종합적 관점 |

### 1.2 역할 선택 로직
```
function selectRole(request):
    keywords = extractKeywords(request)

    if matches(keywords, ["보안", "취약점", "security", "injection", "XSS"]):
        return "보안 분석 전문 시니어 엔지니어"

    if matches(keywords, ["성능", "최적화", "performance", "속도", "메모리"]):
        return "성능 엔지니어링 전문가"

    if matches(keywords, ["아키텍처", "구조", "설계", "architecture", "design"]):
        return "소프트웨어 아키텍트"

    if matches(keywords, ["품질", "리팩토링", "클린코드", "quality"]):
        return "코드 품질 전문가"

    return "시니어 소프트웨어 엔지니어"
```

---

## 2. 컨텍스트 수집 (호출 전 필수)

### 2.1 프로젝트 분석 체크리스트

| 항목 | 수집 방법 | 필수 |
|------|----------|------|
| 프로젝트 아키텍처 | 디렉토리 구조 분석 | ✓ |
| 주요 모듈 | 핵심 디렉토리 식별 | ✓ |
| 의존성 그래프 | import/require 관계 추적 | 권장 |
| 코딩 컨벤션 | 린터 설정 파일 확인 | 권장 |
| 테스트 커버리지 | 테스트 파일 존재 여부 | 권장 |

### 2.2 분석 깊이 수준

| 깊이 | 설명 | 적합한 상황 |
|------|------|------------|
| `surface` | 표면적 검토, 명확한 이슈만 | 빠른 피드백, 간단한 변경 |
| `standard` | 일반적인 분석 깊이 | 대부분의 리뷰 (기본값) |
| `deep` | 심층 분석, 모든 가능성 검토 | 보안 검토, 중요 모듈 |

---

## 3. 요청 프롬프트 구성

### 3.1 향상된 프롬프트 템플릿
Gemini CLI 호출 시 다음 형식으로 프롬프트를 구성합니다:

```
[ROLE]
당신은 {specialty} 전문 시니어 엔지니어입니다.

[PROJECT ARCHITECTURE]
- 프로젝트: {project_name}
- 아키텍처 패턴: {architecture_pattern}
- 주요 모듈: {main_modules}
- 의존성 그래프: {dependency_graph}

[ANALYSIS SCOPE]
- 분석 대상: {target_files}
- 분석 깊이: {depth}
- 초점 영역: {focus_areas}

[CODE TO ANALYZE]
--- {file_path}:{start_line}-{end_line} ---
{code_with_line_numbers}

[ANALYSIS FRAMEWORK]
다음 관점에서 분석해주세요:

1. **구조적 분석**
   - 모듈 응집도/결합도
   - 책임 분리 (SRP)
   - 추상화 수준 일관성

2. **{focus_area} 심층 분석**
   - 구체적 문제점
   - 영향 범위
   - 우선순위

3. **개선 제안**
   - 즉시 적용 가능한 수정
   - 리팩토링 제안
   - 장기적 개선 방향

[OUTPUT REQUIREMENTS]
각 발견사항에 대해:
- 문제 위치 (파일:라인)
- 심각도 (Critical/High/Medium/Low/Info)
- 근거와 추론 과정
- 수정 전/후 코드
- 예상 영향

[REASONING]
분석 과정에서 다음을 명시해주세요:
- 왜 이것이 문제인지
- 어떤 원칙/패턴을 위반하는지
- 수정하지 않으면 발생할 수 있는 결과
```

### 3.2 프롬프트 구성 단계
1. **역할 선택**: 분석 유형에 맞는 전문가 역할 결정
2. **컨텍스트 수집**: 프로젝트 아키텍처 및 관련 정보 수집
3. **범위 정의**: 분석 대상, 깊이, 초점 영역 명시
4. **코드 준비**: 라인 번호 포함한 코드 제공
5. **프레임워크 적용**: 분석 관점 및 출력 요구사항 명시

---

## 4. CLI 호출 방법

### 기본 호출
```bash
gemini "${prompt}"
```

### 전체 자동화 모드 (기본 설정)
```bash
gemini \
  --model gemini-3-pro-preview \
  --approval-mode yolo \
  --output-format json \
  "${prompt}"
```

### 전체 옵션 (config/default.jsonc 기반)
```bash
gemini \
  --model "${config.model.name}" \
  --approval-mode "${config.execution.approvalMode}" \
  --output-format "${config.output.format}" \
  "${PROMPT}"
```

### CLI 옵션 참조
| 옵션 | 설명 | 기본값 |
|-----|------|--------|
| `--model, -m` | 모델 지정 | gemini-3-pro-preview |
| `--approval-mode` | 승인 모드 | yolo |
| `--yolo, -y` | yolo 모드 단축 플래그 | - |
| `--sandbox, -s` | 샌드박스 모드 | false |
| `--output-format, -o` | 출력 형식 | text |
| `-i, --prompt-interactive` | 대화형 모드 유지 | - |

### 모델 옵션 (--model)
| 모델 | 설명 |
|-----|------|
| `gemini-3-pro-preview` | 최신 최상위 모델 (기본, 권장) |
| `gemini-3-flash-preview` | 최신 빠른 모델 (프리뷰) |
| `gemini-2.5-pro` | 고급 추론 모델 (안정) |
| `gemini-2.5-flash` | 빠른 성능 + thinking |
| `gemini-2.5-flash-lite` | 저비용 고속 모델 |

### 출력 형식 옵션 (--output-format)
| 값 | 설명 | 권장 상황 |
|-----|------|----------|
| `text` | 일반 텍스트 | 간단한 질의응답 |
| `json` | JSON 형식 | 구조화된 분석 (권장) |
| `stream-json` | 스트리밍 JSON | 대용량 분석 |

> **참고**: 분석 작업에는 `json` 형식을 권장합니다. 구조화된 응답으로 파싱이 용이합니다.

---

## 5. 응답 형식 처리

### 5.1 확장된 응답 스키마
Gemini에게 다음 형식의 응답을 요청합니다:

```json
{
  "summary": {
    "overall_score": 85,
    "key_findings": ["핵심 발견사항 3개"],
    "risk_level": "medium"
  },
  "detailed_analysis": {
    "structural": {
      "cohesion": "high",
      "coupling": "medium",
      "observations": ["관찰 사항"]
    },
    "focus_area": {
      "category": "security",
      "findings": ["세부 발견사항"]
    }
  },
  "issues": [
    {
      "id": "SEC-001",
      "severity": "critical",
      "category": "security",
      "location": "auth.ts:42-48",
      "title": "SQL Injection 취약점",
      "description": "상세 설명",
      "evidence": "문제가 되는 코드 조각",
      "reasoning": "왜 문제인지 설명",
      "impact": "영향 범위",
      "fix": {
        "before": "수정 전 코드",
        "after": "수정 후 코드",
        "explanation": "수정 이유"
      },
      "references": ["CWE-78", "OWASP Top 10"]
    }
  ],
  "recommendations": {
    "immediate": ["즉시 조치 항목"],
    "short_term": ["단기 개선"],
    "long_term": ["장기 개선"]
  }
}
```

### 5.2 응답 파싱 로직
1. JSON 응답: 전체 구조 파싱
2. 마크다운 응답: 섹션별 파싱 (## 헤더 기준)
3. 에러 응답: 재시도 로직 또는 폴백

### 5.3 에러 처리
```
if response.status == "error":
    - 코드 청크 분할 후 재시도 (토큰 제한)
    - 프롬프트 단순화 후 재시도
    - 최종 실패 시 Claude가 직접 분석 제안
```

---

## 6. 응답 프롬프트 처리 (사용자에게 전달)

### 코드 리뷰 결과 형식
```
📊 Gemini 코드 리뷰 결과

**전체 점수**: {score}/100 | **위험 수준**: {risk_level}

---

### 🔴 Critical Issues ({count})

**{id}. {title}** - `{location}`
> {description}

**근거**: {reasoning}

**영향**: {impact}

수정 전:
```{language}
{before_code}
```

수정 후:
```{language}
{after_code}
```

**참조**: {references}

---

### 🟡 High Priority ({count})
...

### 🟢 Improvements ({count})
...

---

### 권장 조치

**즉시 조치**:
- {immediate_actions}

**단기 개선**:
- {short_term_improvements}

**장기 개선**:
- {long_term_improvements}

---

🔧 **자동 수정 가능**: {auto_fixable_count}개 이슈
적용하시겠습니까? [Y/n]
```

### 분석 요약 형식
```
📋 Gemini 분석 요약

| 카테고리 | 상태 | 발견 사항 |
|---------|-----|----------|
| 보안 | {status} | {findings} |
| 성능 | {status} | {findings} |
| 코드 품질 | {status} | {findings} |
| 테스트 커버리지 | {status} | {findings} |

상세 분석을 보시겠습니까?
```

### 실패 시 응답 형식
```
❌ Gemini 분석 실패

[원인]
{error_message}

[대안]
- Claude가 직접 코드를 분석할까요?
- 분석 범위를 줄여서 다시 시도할까요?
```

---

## 7. 워크플로우 예시

### 예시 1: 보안 분석

**사용자**: "gemini로 인증 모듈 보안 분석해줘"

**1단계: 역할 및 컨텍스트**
```
- 역할: 보안 분석 전문 시니어 엔지니어
- 분석 깊이: deep
- 초점 영역: 인증, 권한, 입력 검증
```

**2단계: 프롬프트 구성**
```
[ROLE]
당신은 보안 분석 전문 시니어 엔지니어입니다.

[PROJECT ARCHITECTURE]
- 프로젝트: oh-my-claude-code
- 아키텍처: 플러그인 기반 CLI
- 주요 모듈: plugins/, skills/, agents/
- 외부 통신: OpenAI API, Google API

[ANALYSIS SCOPE]
- 분석 대상: plugins/codex-cli/skills/
- 분석 깊이: deep
- 초점 영역: 보안 (입력 검증, 명령어 주입)

[CODE TO ANALYZE]
--- plugins/codex-cli/skills/codex-agent/SKILL.md:66-85 ---
```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  "${prompt}"
```

[ANALYSIS FRAMEWORK]
1. **보안 관점**
   - 명령어 주입 가능성
   - 권한 상승 위험
   - 입력 검증 부재

2. **영향 분석**
   - 악용 시나리오
   - 영향 범위

[OUTPUT REQUIREMENTS]
- 발견된 각 취약점에 대해 CVSS 점수 수준의 심각도 평가
- 구체적인 공격 시나리오
- 수정 코드와 함께 상세 설명

[REASONING]
- 왜 이것이 보안 문제인지
- 어떤 보안 원칙을 위반하는지
- 수정하지 않으면 발생할 수 있는 결과
```

**3단계: Gemini 응답 (예시)**
```json
{
  "summary": {
    "overall_score": 45,
    "key_findings": [
      "명령어 주입 취약점 (Critical)",
      "샌드박스 우회 설정 (High)",
      "입력 검증 부재 (Medium)"
    ],
    "risk_level": "critical"
  },
  "issues": [
    {
      "id": "SEC-001",
      "severity": "critical",
      "category": "command_injection",
      "location": "SKILL.md:72",
      "title": "Shell Command Injection via ${prompt}",
      "description": "사용자 입력이 직접 셸 명령어로 전달되어 임의 코드 실행 가능",
      "evidence": "codex exec ... \"${prompt}\"",
      "reasoning": "${prompt}에 $(malicious_command) 형태의 입력이 들어오면 셸 확장으로 실행됨",
      "impact": "시스템 전체 권한으로 임의 명령 실행 가능",
      "fix": {
        "before": "codex exec ... \"${prompt}\"",
        "after": "codex exec ... \"$(printf '%s' \"$prompt\" | sed 's/[\"$`\\]/\\\\&/g')\"",
        "explanation": "셸 메타문자 이스케이프로 명령어 주입 방지"
      },
      "references": ["CWE-78", "OWASP Command Injection"]
    }
  ],
  "recommendations": {
    "immediate": ["입력 검증 함수 추가", "셸 메타문자 이스케이프"],
    "short_term": ["--dangerously 옵션 조건부 사용으로 변경"],
    "long_term": ["입력-출력 경계에 보안 레이어 추가"]
  }
}
```

**4단계: 사용자에게 결과 제시**
```
📊 Gemini 보안 분석 결과

**전체 점수**: 45/100 | **위험 수준**: Critical

---

### 🔴 Critical Issues (1)

**SEC-001. Shell Command Injection** - `SKILL.md:72`
> 사용자 입력이 직접 셸 명령어로 전달되어 임의 코드 실행 가능

**근거**: ${prompt}에 $(malicious_command) 형태의 입력이 들어오면 셸 확장으로 실행됨

**영향**: 시스템 전체 권한으로 임의 명령 실행 가능

수정 전:
```bash
codex exec ... "${prompt}"
```

수정 후:
```bash
codex exec ... "$(printf '%s' "$prompt" | sed 's/["$`\\]/\\\\&/g')"
```

**참조**: CWE-78, OWASP Command Injection

---

### 권장 조치

**즉시 조치**:
- 입력 검증 함수 추가
- 셸 메타문자 이스케이프

**단기 개선**:
- --dangerously 옵션 조건부 사용으로 변경

**장기 개선**:
- 입력-출력 경계에 보안 레이어 추가
```

---

## 8. 품질 검증 체크리스트

Gemini 응답 후 다음 항목을 검증합니다:

| 항목 | 검증 방법 | 실패 시 조치 |
|------|----------|-------------|
| 분석 완전성 | 모든 파일 분석 여부 | 누락 파일 추가 분석 |
| 근거 충분성 | 각 이슈에 reasoning 존재 | 근거 보완 요청 |
| 수정 코드 정확성 | 제안된 fix 검증 | 수정 코드 재검토 |
| 심각도 적절성 | CVSS 기준 대조 | 심각도 조정 |
| 참조 정확성 | CWE/OWASP 번호 확인 | 참조 수정 |

---

## 9. 분석 유형별 출력 포맷 가이드

| 분석 유형 | 출력 포맷 | 이유 |
|----------|----------|------|
| 보안 분석 | json | CVSS 점수, CWE 참조 등 구조화 필요 |
| 성능 분석 | json | 복잡도 수치, 병목 위치 등 정량화 |
| 아키텍처 분석 | json | 모듈 관계, 의존성 그래프 표현 |
| 일반 리뷰 | json | 일관된 파싱을 위해 권장 |
| 간단한 질문 | text | 빠른 응답 필요시 |
