---
name: codex-agent
description: |
  OpenAI Codex CLI를 서브 에이전트로 활용하는 코드 생성 전문 스킬.

  ## 트리거 키워드
  다음 표현이 사용자 요청에 포함되면 이 스킬이 자동 활성화됩니다:
  - "codex로", "codex를 활용해", "codex한테", "codex 써서"
  - "codex에게 시켜", "codex가 해줘", "codex로 만들어"
  - "OpenAI codex", "코덱스로", "코덱스 활용"

  ## 주요 역할
  - 코드 생성 및 완성
  - 코드 변환 및 리팩토링
  - 테스트 코드 자동 생성
  - 보일러플레이트 코드 생성

  ## 적합한 작업
  - 새로운 함수/클래스 작성
  - 반복적인 코드 패턴 생성
  - 언어 간 코드 변환
allowed-tools: Bash, Read, Write, Glob, Grep
---

# Codex CLI Agent

OpenAI Codex CLI를 서브 에이전트로 호출하여 코드 생성 작업을 수행합니다.

---

## 1. 컨텍스트 수집 (호출 전 필수)

### 1.1 프로젝트 분석 체크리스트
Codex 호출 전 다음 정보를 수집합니다:

| 항목 | 수집 방법 | 필수 |
|------|----------|------|
| 언어/버전 | `package.json`, `pyproject.toml`, `go.mod` 등 | ✓ |
| 프레임워크 | 의존성 목록에서 추출 | ✓ |
| 코딩 컨벤션 | `.eslintrc`, `.prettierrc`, `ruff.toml` 등 | ✓ |
| 기존 패턴 | 동일 디렉토리의 유사 파일에서 샘플링 | ✓ |
| 관련 코드 | import/require 관계 추적 | 권장 |
| 테스트 패턴 | `*.test.ts`, `*_test.go` 등에서 추출 | 권장 |

### 1.2 패턴 추출 방법
```bash
# 동일 디렉토리에서 최근 수정된 파일의 패턴 추출
find . -name "*.ts" -type f -mtime -30 | head -3 | \
  xargs grep -E "^(export )?(async )?function|^(export )?class"

# 에러 핸들링 패턴 추출
grep -r "throw new" --include="*.ts" | head -5

# 로깅 패턴 추출
grep -r "console\.|logger\." --include="*.ts" | head -5
```

### 1.3 관련 코드 선별 기준
1. **직접 참조**: import/require로 연결된 파일 → 전체 포함
2. **간접 참조**: 타입 정의, 인터페이스 → 시그니처만 포함
3. **유사 구현**: 동일 패턴의 다른 구현 → 예시로 1개 포함

---

## 2. 요청 프롬프트 구성

### 2.1 향상된 프롬프트 템플릿
Codex CLI 호출 시 다음 형식으로 프롬프트를 구성합니다:

```
[ROLE]
당신은 {project_name} 프로젝트의 핵심 개발자입니다.

[PROJECT CONTEXT]
- 언어: {language} ({version})
- 프레임워크: {framework} ({framework_version})
- 패키지 매니저: {package_manager}
- 테스트 프레임워크: {test_framework}

[CODING CONVENTIONS]
{coding_conventions}

[EXISTING PATTERNS]
다음은 이 프로젝트의 기존 코드 패턴입니다:
```{language}
{existing_pattern_example}
```

[RELATED CODE]
{related_code_with_signatures}

[TASK]
{user_request}

[CONSTRAINTS]
- 위의 코딩 컨벤션 준수 필수
- 기존 패턴과 일관성 유지
- 에러 핸들링: {error_handling_pattern}
- 로깅: {logging_pattern}

[OUTPUT REQUIREMENTS]
- 완전한 구현 코드
- 주요 설계 결정에 대한 간단한 설명
- 필요시 테스트 코드 포함
- 잠재적 엣지 케이스 언급

[VERIFICATION]
생성된 코드가 다음을 만족하는지 확인:
- [ ] 기존 패턴과 일관성
- [ ] 타입 안전성
- [ ] 에러 핸들링 완비
- [ ] 테스트 가능성
```

### 2.2 프롬프트 구성 단계
1. **컨텍스트 수집**: 섹션 1의 체크리스트에 따라 정보 수집
2. **패턴 샘플링**: 기존 코드에서 관련 패턴 추출
3. **요청 정제**: 사용자 요청을 명확한 태스크로 변환
4. **제약 조건 구체화**: 프로젝트 특화된 제약 조건 추가
5. **검증 항목 설정**: 생성 코드 품질 체크리스트 포함

---

## 3. CLI 호출 방법

### 기본 호출 (비대화형)
```bash
codex exec "${prompt}"
```

### 전체 자동화 모드 (기본 설정)
```bash
codex exec \
  --model gpt-5.2-codex \
  --dangerously-bypass-approvals-and-sandbox \
  "${prompt}"
```

### 전체 옵션 (config/default.jsonc 기반)
```bash
codex exec \
  --model "${config.model.name}" \
  --sandbox "${config.execution.sandbox}" \
  --ask-for-approval "${config.execution.approval}" \
  "${PROMPT}"
```

### CLI 옵션 참조
| 옵션 | 설명 | 기본값 |
|-----|------|--------|
| `exec` | 비대화형 실행 (서브커맨드) | - |
| `--model, -m` | 모델 지정 | gpt-5.2-codex |
| `--sandbox, -s` | 샌드박스 정책 | danger-full-access |
| `--ask-for-approval, -a` | 승인 정책 | never |
| `--full-auto` | 편의 옵션 (workspace-write + on-request) | - |
| `--dangerously-bypass-approvals-and-sandbox` | 모든 승인/샌드박스 우회 | ✓ |

### 모델 옵션 (--model)
| 모델 | 설명 |
|-----|------|
| `gpt-5.2-codex` | 최신 최상위 코딩 모델 (기본) |
| `gpt-5.1-codex-max` | 장기 에이전틱 작업 최적화 |
| `gpt-5.1-codex-mini` | 비용 효율적인 소형 모델 |

### 샌드박스 옵션 (--sandbox)
| 값 | 설명 |
|-----|------|
| `read-only` | 읽기 전용 (가장 안전) |
| `workspace-write` | 프로젝트만 쓰기 허용 |
| `danger-full-access` | 무제한 접근 (기본) |

### 승인 정책 옵션 (--ask-for-approval)
| 값 | 설명 |
|-----|------|
| `untrusted` | 모든 명령 승인 필요 |
| `on-failure` | 실패 시에만 승인 |
| `on-request` | 모델 판단에 따름 |
| `never` | 승인 없이 실행 (기본) |

### 보안 주의사항

> **경고**: `--dangerously-bypass-approvals-and-sandbox` 옵션은 모든 보안 검증을 우회합니다.

1. **프롬프트 입력 검증**: 사용자 입력을 직접 `${prompt}`로 전달하기 전에 반드시 검증하세요.
2. **신뢰할 수 있는 환경에서만 사용**: 이 옵션은 통제된 환경에서만 사용하는 것을 권장합니다.
3. **셸 메타문자 이스케이프**: 외부 입력이 포함된 경우 셸 명령어 주입을 방지하기 위해 적절한 이스케이프 처리가 필요합니다.

```bash
# 안전하지 않은 예시 (주의)
codex exec "${untrusted_input}"

# 보다 안전한 접근 방식
# 1. 입력 검증 후 사용
# 2. 허용된 문자만 포함하는지 확인
# 3. 필요시 샌드박스 옵션 활성화
codex exec --sandbox workspace-write "${validated_input}"
```

---

## 4. 응답 형식 처리

### 4.1 확장된 응답 스키마
Codex에게 다음 형식의 응답을 요청합니다:

```json
{
  "status": "success",
  "code": "생성된 코드 내용",
  "language": "typescript",
  "design_decisions": [
    {
      "decision": "무엇을 결정했는지",
      "rationale": "왜 이렇게 결정했는지",
      "alternatives": ["고려했던 대안들"]
    }
  ],
  "edge_cases": [
    {
      "scenario": "엣지 케이스 설명",
      "handling": "처리 방법"
    }
  ],
  "test_suggestions": ["테스트해야 할 케이스들"],
  "confidence": 0.95,
  "warnings": ["주의사항"]
}
```

### 4.2 응답 파싱 로직
1. JSON 응답인 경우: 전체 구조 파싱
2. 순수 텍스트인 경우: 코드 블록 추출 (```로 감싸진 부분)
3. 에러 응답인 경우: 에러 메시지 추출 후 재시도 또는 사용자에게 알림

### 4.3 에러 처리
```
if response.status == "error":
    - 프롬프트 재구성 시도 (컨텍스트 조정)
    - 컨텍스트 축소 후 재시도 (토큰 제한 시)
    - 최종 실패 시 사용자에게 원인 설명 + Claude 폴백 제안
```

---

## 5. 응답 프롬프트 처리 (사용자에게 전달)

### 성공 시 응답 형식
```
✅ Codex가 코드를 생성했습니다.

[설계 결정]
- {decision}: {rationale}

[생성된 코드]
```{language}
{generated_code}
```

[엣지 케이스 처리]
- {scenario}: {handling}

[테스트 제안]
- {test_suggestion}

📁 적용할 파일: {target_file}

선택하세요:
1. 파일에 바로 적용
2. 코드 수정 후 적용
3. 취소
```

### 부분 성공 시 응답 형식
```
⚠️ Codex가 코드를 생성했지만 검토가 필요합니다.

[주의 사항]
- {warning_message}

[신뢰도]: {confidence}%

[생성된 코드]
```{language}
{generated_code}
```

수동으로 검토 후 적용하시겠습니까?
```

### 실패 시 응답 형식
```
❌ Codex 호출 실패

[원인]
{error_message}

[대안]
- Claude가 직접 코드를 작성할까요?
- 요청을 다시 정리해서 시도할까요?
```

---

## 6. 워크플로우 예시

### 예시 1: 플러그인 캐싱 기능

**사용자**: "codex로 LRU 캐시 기반 플러그인 캐싱 기능 만들어줘"

**1단계: 컨텍스트 수집**
```
- 언어: TypeScript (ES2022)
- 프레임워크: Node.js CLI
- 코딩 컨벤션: camelCase 함수, PascalCase 클래스
- 기존 패턴: async/await, 커스텀 Error 클래스
```

**2단계: 프롬프트 구성**
```
[ROLE]
당신은 oh-my-claude-code 프로젝트의 핵심 개발자입니다.

[PROJECT CONTEXT]
- 언어: TypeScript (ES2022)
- 프레임워크: Node.js CLI
- 패키지 매니저: npm
- 테스트 프레임워크: Jest

[CODING CONVENTIONS]
- 함수명: camelCase (예: parseConfig, fetchData)
- 클래스명: PascalCase (예: PluginManager)
- 상수: UPPER_SNAKE_CASE (예: MAX_RETRIES)
- 에러 처리: 커스텀 Error 클래스 사용
- 비동기: async/await 패턴

[EXISTING PATTERNS]
```typescript
// 기존 설정 로딩 패턴
export async function loadConfig(configPath: string): Promise<Config> {
  const raw = await fs.readFile(configPath, 'utf-8');
  const parsed = JSON.parse(raw);
  return validateConfig(parsed);
}
```

[RELATED CODE]
// PluginManager 클래스 시그니처
class PluginManager {
  private plugins: Map<string, Plugin>;
  async load(name: string): Promise<Plugin>;
  async unload(name: string): Promise<void>;
}

[TASK]
새로운 플러그인 캐싱 기능을 추가해주세요. LRU 캐시로 최근 5개 플러그인만 메모리에 유지합니다.

[CONSTRAINTS]
- 위의 async/await 패턴 준수
- 기존 PluginManager와 호환
- 캐시 미스 시 자동 로딩

[OUTPUT REQUIREMENTS]
- 완전한 LRUCache 클래스 구현
- PluginManager에 통합하는 방법 설명
- 엣지 케이스 (캐시 풀, 동시 접근) 처리

[VERIFICATION]
- [ ] 기존 load/unload 인터페이스 유지
- [ ] 타입 안전성 (제네릭 사용)
- [ ] 에러 핸들링 포함
```

**3단계: Codex 응답 (예시)**
```json
{
  "status": "success",
  "code": "export class LRUCache<K, V> {\n  private cache: Map<K, V>;\n  private readonly maxSize: number;\n\n  constructor(maxSize: number = 5) {\n    this.cache = new Map();\n    this.maxSize = maxSize;\n  }\n\n  get(key: K): V | undefined {\n    const value = this.cache.get(key);\n    if (value !== undefined) {\n      // 접근 시 순서 갱신 (LRU)\n      this.cache.delete(key);\n      this.cache.set(key, value);\n    }\n    return value;\n  }\n\n  set(key: K, value: V): void {\n    if (this.cache.has(key)) {\n      this.cache.delete(key);\n    } else if (this.cache.size >= this.maxSize) {\n      // 가장 오래된 항목 제거\n      const oldestKey = this.cache.keys().next().value;\n      this.cache.delete(oldestKey);\n    }\n    this.cache.set(key, value);\n  }\n\n  has(key: K): boolean {\n    return this.cache.has(key);\n  }\n\n  delete(key: K): boolean {\n    return this.cache.delete(key);\n  }\n\n  clear(): void {\n    this.cache.clear();\n  }\n\n  get size(): number {\n    return this.cache.size;\n  }\n}",
  "language": "typescript",
  "design_decisions": [
    {
      "decision": "Map 기반 LRU 구현",
      "rationale": "Map의 삽입 순서 보장을 활용하여 O(1) 접근과 갱신 가능",
      "alternatives": ["Array 기반 (O(n))", "Doubly Linked List (복잡성 증가)"]
    },
    {
      "decision": "제네릭 타입 사용",
      "rationale": "다양한 키-값 타입에 재사용 가능",
      "alternatives": ["Plugin 전용 타입 고정"]
    }
  ],
  "edge_cases": [
    {
      "scenario": "캐시 용량 초과 시 가장 오래된 항목 제거",
      "handling": "Map.keys().next()로 첫 항목(가장 오래된) 삭제"
    },
    {
      "scenario": "동시 로딩 요청",
      "handling": "loadingPromises Map으로 중복 요청 방지 (PluginManager에서 구현)"
    },
    {
      "scenario": "존재하지 않는 키 접근",
      "handling": "undefined 반환 (호출자가 처리)"
    }
  ],
  "test_suggestions": [
    "캐시 히트/미스 시나리오",
    "용량 초과 시 LRU 제거 확인",
    "동시 접근 시 레이스 컨디션 테스트",
    "clear() 후 상태 확인"
  ],
  "confidence": 0.92,
  "warnings": ["동시성이 높은 환경에서는 락 메커니즘 고려 필요"]
}
```

**4단계: 사용자에게 결과 제시**
```
✅ Codex가 코드를 생성했습니다.

[설계 결정]
- Map 기반 LRU 구현: Map의 삽입 순서 보장을 활용하여 O(1) 접근과 갱신 가능
- 제네릭 타입 사용: 다양한 키-값 타입에 재사용 가능

[생성된 코드]
```typescript
export class LRUCache<K, V> {
  private cache: Map<K, V>;
  private readonly maxSize: number;
  // ... (전체 코드)
}
```

[엣지 케이스 처리]
- 캐시 용량 초과: Map.keys().next()로 첫 항목 삭제
- 동시 로딩 요청: loadingPromises Map으로 중복 방지

[테스트 제안]
- 캐시 히트/미스 시나리오
- 용량 초과 시 LRU 제거 확인

[주의사항]
- 동시성이 높은 환경에서는 락 메커니즘 고려 필요

📁 적용할 파일: src/cache/LRUCache.ts

선택하세요:
1. 파일에 바로 적용
2. 코드 수정 후 적용
3. 취소
```

---

## 7. 품질 검증 체크리스트

Codex 응답 후 다음 항목을 검증합니다:

| 항목 | 검증 방법 | 실패 시 조치 |
|------|----------|-------------|
| 기존 패턴 일관성 | 프로젝트 패턴과 비교 | 스타일 수정 요청 |
| 타입 안전성 | TypeScript 컴파일 | 타입 오류 수정 |
| 에러 핸들링 | try-catch 패턴 확인 | 에러 처리 추가 요청 |
| 엣지 케이스 | 응답의 edge_cases 검토 | 누락된 케이스 추가 |
| 테스트 가능성 | 의존성 주입 패턴 확인 | 리팩토링 제안 |
