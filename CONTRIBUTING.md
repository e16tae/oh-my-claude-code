# Contributing to oh-my-claude-code

이 문서는 oh-my-claude-code 프로젝트의 기여 가이드 및 릴리스 워크플로우를 정의합니다.

## 브랜칭 전략

Simplified Git Flow를 사용합니다.

### 브랜치 구조

| 브랜치 | 용도 | 수명 |
|--------|------|------|
| `main` | 안정화된 릴리스 | 영구 |
| `develop` | 개발 통합 (기본 브랜치) | 영구 |
| `feature/*` | 기능 개발 | 임시 (PR 후 삭제) |
| `hotfix/*` | 긴급 버그 수정 | 임시 (PR 후 삭제) |

### 워크플로우 다이어그램

```
feature/* ──PR──▶ develop ──릴리스──▶ main
                                       │
                 hotfix/* ◀────────────┘
                    │
                    ├──PR──▶ main (태그)
                    └──역병합──▶ develop
```

## 커밋 컨벤션

[Conventional Commits](https://www.conventionalcommits.org/) 형식을 따릅니다.

### 형식

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### 타입

| 타입 | 설명 | 버전 영향 |
|------|------|----------|
| `feat` | 새로운 기능 | MINOR |
| `fix` | 버그 수정 | PATCH |
| `docs` | 문서 변경 | - |
| `style` | 코드 스타일 (포맷팅) | - |
| `refactor` | 리팩터링 | - |
| `test` | 테스트 추가/수정 | - |
| `chore` | 빌드, 의존성, 설정 | - |

### 예시

```bash
# 기능 추가
feat(codex): add implicit triggers for PR creation

# 버그 수정
fix(gemini): correct multimodal file extensions

# 문서 변경
docs: update README with new trigger examples

# 호환성 파괴 변경 (MAJOR)
feat!: redesign skill configuration format

BREAKING CHANGE: skill.yaml is now SKILL.md
```

## PR 가이드라인

### PR 생성 전

1. `develop` 브랜치에서 최신 변경사항 pull
2. feature 브랜치 생성: `git checkout -b feature/amazing-feature`
3. 변경사항 커밋 (Conventional Commits 형식)
4. 원격 저장소에 push

### PR 템플릿

```markdown
## Summary
- 변경사항 요약 (1-3줄)

## Changes
- [ ] 구체적인 변경 내용

## Test Plan
- [ ] 테스트 방법

## Checklist
- [ ] Conventional Commits 형식 준수
- [ ] 문서 업데이트 (필요시)
```

### 병합 규칙

- `develop` 병합: Squash and merge 권장
- `main` 병합: Create a merge commit (히스토리 보존)

## 릴리스 프로세스

### 정규 릴리스 (Minor/Major)

**1. 버전 결정**

| 변경 유형 | 버전 | 예시 |
|---------|------|------|
| 호환성 파괴 (BREAKING) | MAJOR | 1.0.0 → 2.0.0 |
| 새 기능 추가 | MINOR | 1.1.0 → 1.2.0 |
| 버그 수정만 | PATCH | 1.1.0 → 1.1.1 |

**2. 버전 업데이트 (3개 파일)**

```bash
# 업데이트 대상
plugins/agents/.claude-plugin/plugin.json    # "version": "X.Y.Z"
.claude-plugin/marketplace.json              # "version": "X.Y.Z"
README.md                                    # 버전 테이블
```

**3. CHANGELOG 업데이트**

`[Unreleased]` 섹션의 내용을 새 버전으로 이동:

```markdown
## [Unreleased]
(비움)

## [1.2.0] - 2025-01-15

### Added
- 새로운 기능들...

### Changed
- 변경된 기능들...
```

**4. develop → main 병합**

```bash
git checkout main
git merge develop
git push origin main
```

**5. 태그 및 GitHub Release**

```bash
# 태그 생성
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0

# GitHub Release 생성
gh release create v1.2.0 --title "v1.2.0" --notes "CHANGELOG 내용"
```

### 핫픽스 (Patch)

긴급한 버그 수정 시 사용합니다.

**1. main에서 hotfix 브랜치 생성**

```bash
git checkout main
git checkout -b hotfix/critical-bug-fix
```

**2. 버그 수정 + 버전 패치**

- 버그 수정 커밋
- 버전 업데이트 (PATCH): 1.1.0 → 1.1.1

**3. main 병합 + 태그**

```bash
git checkout main
git merge hotfix/critical-bug-fix
git tag -a v1.1.1 -m "Hotfix v1.1.1"
git push origin main --tags
```

**4. develop에 역병합**

```bash
git checkout develop
git merge hotfix/critical-bug-fix
git push origin develop
```

**5. hotfix 브랜치 삭제**

```bash
git branch -d hotfix/critical-bug-fix
git push origin --delete hotfix/critical-bug-fix
```

## CHANGELOG 관리

[Keep a Changelog](https://keepachangelog.com/) 형식을 따릅니다.

### 형식

```markdown
# Changelog

## [Unreleased]
### Added
- 아직 릴리스되지 않은 새 기능

## [1.1.0] - 2025-01-13
### Added
- 릴리스된 기능들
```

### 카테고리

| 카테고리 | 용도 |
|---------|------|
| `Added` | 새로운 기능 |
| `Changed` | 기존 기능 변경 |
| `Deprecated` | 곧 제거될 기능 |
| `Removed` | 제거된 기능 |
| `Fixed` | 버그 수정 |
| `Security` | 보안 취약점 수정 |

### 작성 규칙

- 각 변경사항은 사용자 관점에서 작성
- 기술적 세부사항보다 영향/가치 중심
- 한국어로 간결하게 작성

## 릴리스 체크리스트

릴리스 전 확인사항:

```markdown
### 사전 준비
- [ ] 모든 변경사항이 develop에 병합됨
- [ ] 로컬에서 기능 테스트 완료

### 버전 업데이트
- [ ] plugins/agents/.claude-plugin/plugin.json
- [ ] .claude-plugin/marketplace.json
- [ ] README.md (버전 테이블)

### CHANGELOG
- [ ] [Unreleased] → [X.Y.Z] 섹션 이동
- [ ] 릴리스 날짜 추가

### 병합 및 태그
- [ ] develop → main 병합
- [ ] 태그 생성 (vX.Y.Z)
- [ ] GitHub Release 생성

### 정리
- [ ] [Unreleased] 섹션 비우기
- [ ] feature/hotfix 브랜치 삭제 (해당시)
```

## 버전 관리 규칙 (SemVer)

[Semantic Versioning 2.0.0](https://semver.org/) 준수

### MAJOR.MINOR.PATCH

```
1.2.3
│ │ │
│ │ └── PATCH: 버그 수정 (하위 호환)
│ └──── MINOR: 기능 추가 (하위 호환)
└────── MAJOR: 호환성 파괴 변경
```

### 버전 증가 기준

| 상황 | 버전 | 예시 |
|------|------|------|
| SKILL.md 내 트리거/안티패턴 추가 | MINOR | 1.1.0 → 1.2.0 |
| 오타/문서 수정 | PATCH | 1.1.0 → 1.1.1 |
| 스킬 구조 변경 (호환성 파괴) | MAJOR | 1.1.0 → 2.0.0 |
| 새 스킬 추가 | MINOR | 1.1.0 → 1.2.0 |

## 예시: 전체 릴리스 플로우

```bash
# 1. 기능 개발
git checkout develop
git checkout -b feature/new-triggers
# ... 변경 작업 ...
git commit -m "feat(gemini): add translation triggers"

# 2. develop에 PR 생성 및 병합
gh pr create --base develop --title "feat(gemini): add translation triggers"
# (리뷰 후 병합)

# 3. 릴리스 준비 (develop에서)
git checkout develop
git pull origin develop
# 버전 업데이트 (3개 파일)
# CHANGELOG 업데이트
git commit -m "chore: bump version to 1.2.0"

# 4. main 병합
git checkout main
git merge develop
git push origin main

# 5. 태그 및 릴리스
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
gh release create v1.2.0 --title "v1.2.0" --notes-file RELEASE_NOTES.md

# 6. develop으로 돌아가서 [Unreleased] 준비
git checkout develop
git merge main  # 태그 반영
```

## 질문 및 지원

- Issues: [GitHub Issues](https://github.com/oh-my-claude-code/oh-my-claude-code/issues)
- Discussions: [GitHub Discussions](https://github.com/oh-my-claude-code/oh-my-claude-code/discussions)
