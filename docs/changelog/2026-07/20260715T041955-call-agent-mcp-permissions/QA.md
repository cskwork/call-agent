# QA - Claude MCP 자동 허용

- Verdict: PASS

## Before

- [x] 세 Claude 래퍼의 `--allowedTools`에 MCP 서버 허용 항목이 없다. - evidence: `rg -n -- '--allowedTools|mcp__' skills/call-agent/reference/claude/scripts`
- [x] 기준 브랜치와 원격 `master`가 `8623126a3d19b45449b6caf4e88a88837251ef0f`로 일치한다. - evidence: `git rev-parse master origin/master HEAD && git ls-remote origin refs/heads/master`

## Results

- [x] plan/review/implement 래퍼가 기존 도구와 구성된 MCP 서버 접두사를 함께 전달하고, 목록 조회 실패 시 기존 호출을 유지한다. - `/bin/bash skills/call-agent/reference/claude/tests/smoke.sh` (frozen_repo)
- [x] macOS Bash 3.2 helper와 Claude 2.1.209가 UTF-8 및 `LC_ALL=C`에서 공백·콜론·점·하이픈·Unicode 서버의 동일한 실제 namespace를 생성한다. - 일회성 strict MCP config 비교 (evaluator_owned)
- [x] 전체 skill 회귀 suite가 실패 없이 완료됐다. NotebookLM은 바이너리 미설치로 명시적 SKIP이다. - `/bin/bash tests/run-all.sh` (frozen_repo)
- [x] skill 구조 검증, diff 공백 검사, 권한 우회 및 MCP glob 금지 검사가 모두 통과했다. - validator 및 정적 검사 (evaluator_owned)

Backward-trace: clean

## Commands

| Command | Source | Proves |
|---|---|---|
| `bash skills/call-agent/reference/claude/tests/smoke.sh` | frozen_repo | Claude 래퍼 계약 |
| `bash tests/run-all.sh` | frozen_repo | 전체 skill 회귀 |
| `/opt/anaconda3/bin/python /Users/danny/.agents/skills/.system/skill-creator/scripts/quick_validate.py skills/call-agent` | evaluator_owned | skill 구조 |
| `claude -p --strict-mcp-config --mcp-config=<disposable-config>` under UTF-8 and `LC_ALL=C` | evaluator_owned | 실제 MCP namespace와 Unicode/locale 동치성 |
| `git diff --check` 및 production script policy 검색 | evaluator_owned | diff 위생과 권한 경계 |

## QA

Tool: shell
UI-tier: 해당 없음
DB: 해당 없음
- CLI integration smoke: 세 래퍼의 정상·discovery 실패 경로와 실제 Claude MCP namespace 비교 PASS.

## Reproduction Fidelity

- Fidelity level: exact
- Residual risk from data gap: 없음
- Post-deploy confirmation plan: 활성 설치본 동기화 후 실제 MCP 목록으로 최소 Claude 호출을 확인한다.

## Residual Risk

- Not proven: 활성 설치본 동기화, 원격 `master`, `v0.2.0` tag/release 반영은 post-commit Finalize 단계에서 확인한다.
- Follow-up: commit gate 이후 commit/push, 설치본 동기화, `v0.2.0` 발행 및 원격 확인.
