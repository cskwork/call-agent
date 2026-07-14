# QA - Claude MCP 자동 허용

- Verdict: PASS

## Before

- [x] 세 Claude 래퍼의 `--allowedTools`에 MCP 서버 허용 항목이 없다. - evidence: `rg -n -- '--allowedTools|mcp__' skills/call-agent/reference/claude/scripts`
- [x] 기준 브랜치와 원격 `master`가 `8623126a3d19b45449b6caf4e88a88837251ef0f`로 일치한다. - evidence: `git rev-parse master origin/master HEAD && git ls-remote origin refs/heads/master`

## Results

- [x] plan/review가 Claude 2.1.209 `dontAsk`에서 구성된 MCP 도구를 실제 실행했고, non-error result와 `permission_denials=[]`를 반환했다. 각 호출은 4턴과 USD 0.10으로 제한했다. - `RUN_L3_MCP=1 /bin/bash skills/call-agent/reference/claude/tests/smoke.sh` (evaluator_owned)
- [x] 역할별 권한 표면이 정확하다. plan은 `Read,Grep,Glob` 노출과 MCP-only 사전 승인, review는 `Read,Grep,Glob,Bash` 노출과 네 read-only Git Bash 규칙 및 MCP만 사전 승인, implement는 기존 `acceptEdits`와 built-in 및 MCP 승인을 유지한다. - 기본 smoke argv 검사 및 live init event (frozen_repo/evaluator_owned)
- [x] macOS Bash 3.2 helper와 Claude 2.1.209가 UTF-8 및 `LC_ALL=C`에서 공백·콜론·점·하이픈·Unicode 서버의 동일한 실제 namespace를 생성한다. - 일회성 strict MCP config 비교 (evaluator_owned)
- [x] 전체 skill 회귀 suite가 실패 없이 완료됐다. NotebookLM은 바이너리 미설치로 명시적 SKIP이다. - `/bin/bash tests/run-all.sh` (frozen_repo)
- [x] skill 구조 검증, diff 공백 검사, 권한 우회 및 MCP glob 금지 검사가 모두 통과했다. - validator 및 정적 검사 (evaluator_owned)

Backward-trace: clean

## Commands

| Command | Source | Proves |
|---|---|---|
| `bash skills/call-agent/reference/claude/tests/smoke.sh` | frozen_repo | Claude 래퍼 계약 |
| `RUN_L3_MCP=1 /bin/bash skills/call-agent/reference/claude/tests/smoke.sh` | evaluator_owned | plan/review 실제 MCP 실행, 빈 permission denials, 정확한 built-in 노출 |
| `bash tests/run-all.sh` | frozen_repo | 전체 skill 회귀 |
| `/opt/anaconda3/bin/python /Users/danny/.agents/skills/.system/skill-creator/scripts/quick_validate.py skills/call-agent` | evaluator_owned | skill 구조 |
| `claude -p --strict-mcp-config --mcp-config=<disposable-config>` under UTF-8 and `LC_ALL=C` | evaluator_owned | 실제 MCP namespace와 Unicode/locale 동치성 |
| `claude -p --permission-mode plan --allowedTools mcp__codebase-memory-mcp` live `list_projects` | evaluator_owned | 정확한 MCP 규칙도 plan mode에서 실행 거부됨 |
| `git diff --check` 및 production script policy 검색 | evaluator_owned | diff 위생과 권한 경계 |

## QA

Tool: shell
UI-tier: 해당 없음
DB: 해당 없음
- CLI integration smoke: 세 래퍼의 정상·discovery 실패 경로와 실제 Claude MCP namespace 비교 PASS.
- Live regression: plan/review 모두 `mcp__codebase-memory-mcp__list_projects`를 실제 실행해
  non-error result와 `MCP_OK`, `permission_denials=[]`를 반환했다.
- Permission boundary: plan init에는 `Read`, `Grep`, `Glob`만, review init에는 여기에
  `Bash`만 추가 노출됐다. smoke가 review의 사전 승인 Bash를 `git diff`, `git log`,
  `git show`, `git status` 네 규칙으로 제한하고 plan에는 MCP 규칙만 전달함을 확인했다.

## Reproduction Fidelity

- Fidelity level: exact
- Residual risk from data gap: 없음
- Post-deploy confirmation plan: commit/push/release 후 활성 설치본을 동기화하고 실제 MCP 목록으로 최소 Claude 호출을 확인한다.

## Residual Risk

- Claude의 `dontAsk`는 원래부터 안전하다고 판단한 일부 unlisted Bash를 실행할 수 있다.
  이번 검증은 모든 unlisted Bash의 실행 거부를 주장하지 않는다. 대신 plan/review에
  `Edit`/`Write`가 노출되지 않고, review에 네 read-only Git 규칙 외 Bash가 사전 승인되지
  않았음을 확인했다.
- Delivery remains open: 이 verifier는 commit/push/tag/release 또는 활성 설치본 동기화를
  수행하지 않았다.
