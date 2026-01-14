# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2025-01-14

### Removed
- github 플러그인 제거 (외부 참조)
- greptile 플러그인 제거 (외부 참조)

### Changed
- 외부 플러그인 참조 22개 → 20개로 변경

## [1.2.0] - 2025-01-14

### Added
- claude-plugins-official 외부 플러그인 참조 (22개)
  - Anthropic 공식 플러그인 17개: code-review, code-simplifier, commit-commands, example-plugin, explanatory-output-style, feature-dev, frontend-design, hookify, kotlin-lsp, plugin-dev, pr-review-toolkit, pyright-lsp, ralph-loop, rust-analyzer-lsp, security-guidance, swift-lsp, typescript-lsp
  - 커뮤니티 관리 플러그인 5개: context7, github, greptile, playwright, serena
- marketplace.json에 $schema 참조 추가
- 플러그인 tags 시스템 (local, external, official, community-managed)

## [1.1.1] - 2025-01-13

### Added
- 릴리스 워크플로우 가이드 (CONTRIBUTING.md)

## [1.1.0] - 2025-01-13

### Added
- Codex/Gemini 암시적 트리거 (작업 패턴 기반 자동 제안)
- 안티패턴 섹션 (도구 경계 명확화)
- 핸드오프 패턴 (Gemini↔Codex 협업 워크플로우)
- Architect-Builder 프로토콜 (Gemini 설계 → Codex 구현)

### Changed
- PR 생성(Codex) / PR 리뷰(Gemini) 역할 분리
- 내부/외부 검색 구분 명확화

## [1.0.0] - 2025-01-12

### Added
- 초기 릴리스
- Codex CLI 통합 스킬
- Gemini CLI 통합 스킬
- 자연어 트리거 지원
