# PLAN - Claude MCP 자동 허용

## Approval

- Status: approved-by-user
- Record: 2026-07-15T04:19:55+09:00; 사용자가 업데이트, commit, push를 명시적으로 요청함

## Intent

- Goal / constraints / tradeoffs / rejected approaches: 모든 현재·향후 연결 MCP 서버 도구를 자동 허용한다. MCP glob은 공식적으로 미지원이므로 서버 목록을 동적으로 조회한다. MCP 외 권한까지 푸는 `bypassPermissions`는 제외한다.
- Completion promise: 세 래퍼에 공통 MCP 권한 계산을 적용하고, 실패·정상 경로를 smoke test와 전체 suite로 증명한 뒤 commit/push한다. `max_iterations=3`; 모든 검증과 원격 ref 확인 후 종료한다.

## Steps

1. `skills/call-agent/reference/claude/tests/smoke.sh`에 세 래퍼의 MCP 허용 인수와 목록 조회 실패 fallback을 검증하는 실패 테스트를 추가한다.
2. `skills/call-agent/reference/claude/scripts/claude-mcp-tools.sh`에 `claude mcp list` 결과를 MCP 서버 단위 허용 이름으로 변환하는 공통 함수를 구현한다.
3. `claude-plan.sh`, `claude-review.sh`, `claude-implement.sh`가 공통 허용 배열을 사용하도록 최소 수정한다.
4. `call.md`와 `docs/changelog/changelog-2026-07-15.md`에 동작 이유, 공식 제약, 제외한 대안을 기록한다.
5. smoke, 전체 suite, skill validator, diff/commit gate를 실행하고 독립 검증 후 commit 및 `origin/master`로 push한다.

## Acceptance checklist

- [ ] plan/review/implement 래퍼 모두 연결된 MCP 서버의 모든 도구를 자동 허용한다.
- [ ] MCP 서버 목록을 읽지 못해도 기존 Claude 호출은 유지된다.
- [ ] 기존 권한 우회 방지와 전체 skill 회귀 검증이 통과한다.
- [ ] skill 구조 검증이 통과한다.

## Tools & Skills

- `supergoal`, `skill-creator`, Bash smoke tests, `quick_validate.py`

## Verification strategy

- Before proof: 현재 세 래퍼에는 `mcp__<server>` 허용 항목이 없고 smoke에도 해당 계약이 없다.
- Step -> GOAL.md criterion: 1-3 -> 1,2; 4-5 -> 3,4
- Trusted commands: `bash skills/call-agent/reference/claude/tests/smoke.sh` (frozen_repo), `bash tests/run-all.sh` (frozen_repo), `python3 /Users/danny/.agents/skills/.system/skill-creator/scripts/quick_validate.py skills/call-agent` (evaluator_owned)

## Grounding ledger

- 모든 MCP를 한 glob으로 허용 가능한가 -> 공식 문서상 glob 미지원 -> 현재 서버 이름을 동적 열거
- 전역 permission bypass가 필요한가 -> MCP 외 도구도 해제 -> 사용하지 않음
- 어느 경로에 적용하는가 -> plan/review/implement 모두 비대화 호출 가능 -> 세 래퍼 공통 적용

## Amendment - 2026-07-15 minor release

- 사용자 추가 승인: 발견한 MCP 권한·Unicode/locale 결함을 모두 포함해 commit/push 후 minor release를 생성한다.
- 기존 최신 release `v0.1.0`의 다음 minor인 `v0.2.0`을 사용한다.
- release는 commit gate 이후 clean `master`에서 tag push, GitHub Release 발행, 원격 tag/release 확인 순서로 수행한다.
