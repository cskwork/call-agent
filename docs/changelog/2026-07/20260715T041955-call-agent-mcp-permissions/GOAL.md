# GOAL - Claude MCP 자동 허용

## Original Request

> 추가로 저런 mcp 호출에 다시는 call agent로 저런 이슈 발생 안하게 /Users/danny/Documents/PARA/Resource/call-agent 업데이트 commit push always allow all usage of mcps tools

## Spec

Claude 위임 래퍼가 실행 시점에 연결된 MCP 서버를 찾고, 각 서버의 모든 도구를
`--allowedTools`에 추가한다. 기존 파일·셸 권한 경계는 유지하며 전역 권한 우회는 사용하지 않는다.

## Success Criteria

- [x] plan/review/implement 래퍼 모두 연결된 MCP 서버의 모든 도구를 자동 허용한다. - verify: `RUN_L3_MCP=1 bash skills/call-agent/reference/claude/tests/smoke.sh`
- [x] MCP 서버 목록을 읽지 못해도 기존 Claude 호출은 유지된다. - verify: `bash skills/call-agent/reference/claude/tests/smoke.sh`
- [x] 기존 권한 우회 방지와 전체 skill 회귀 검증이 통과한다. - verify: `bash tests/run-all.sh`
- [x] skill 구조 검증이 통과한다. - verify: `python3 /Users/danny/.agents/skills/.system/skill-creator/scripts/quick_validate.py skills/call-agent`

## QA Cases (web apps only)

해당 없음.

## Decision Gates

| ID | Action | Status | Finding | Decision | Recheck |
|---|---|---|---|---|---|
| d1 | no-op | resolved | Claude는 MCP 전역 glob을 지원하지 않는다. | 연결된 서버 이름을 동적으로 정확히 허용한다. | smoke test |
| d2 | no-op | resolved | `bypassPermissions`는 MCP 외 권한도 해제한다. | 기존 금지 규칙을 유지한다. | smoke test |
