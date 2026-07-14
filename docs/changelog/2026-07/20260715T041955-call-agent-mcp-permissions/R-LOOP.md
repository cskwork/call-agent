# R-LOOP - verifier -> implementer loop channel

검증 실패 시 최신 섹션을 추가한다.

## 2026-07-15T04:37:57+09:00 - verifier iteration 1

- [ ] Criterion 1: MCP 서버 이름 정규화를 Claude의 실제 도구 이름과 정확히 맞춘다.
  - Expected: 현재와 향후 구성된 모든 유효한 서버 이름이 Claude가 노출하는
    `mcp__<server-name>` 접두사와 동일한 허용 규칙으로 변환된다.
  - Actual: `한글.server`를 공통 함수는 `mcp__한글_server`로 변환하지만,
    Claude 2.1.209는 같은 연결된 서버의 도구를 `mcp_____server__<tool>`로 노출한다.
    로케일 의존 `[:alnum:]`이 비 ASCII 문자를 보존해 해당 서버 도구가 자동 허용되지 않는다.
  - Evidence: `/bin/bash` 3.2에서 현재 치환식을 실행한 결과 `HELPER=한글_server`;
    동일 이름을 가진 일회성 `--strict-mcp-config` 서버의 실제 init 이벤트 결과
    `MCP_PREFIXES=["mcp_____server"]`, `status=connected`.
  - Smallest next fix: 정규화 허용 집합을 Claude와 같은 ASCII
    `A-Za-z0-9_-`로 제한하고, 점·공백·콜론·비 ASCII 이름을 함께 검증하는 smoke
    회귀 테스트를 추가한 뒤 전체 proof set을 다시 실행한다.

## 2026-07-15T04:48:20+09:00 - verifier iteration 2

- [ ] Criterion 1: 호출자의 로케일과 무관하게 Claude의 MCP 서버 이름 정규화와 일치시킨다.
  - Expected: macOS Bash 3.2 래퍼를 `LC_ALL=C`에서 실행해도 Unicode 서버 이름이
    Claude가 노출하는 접두사와 동일하게 변환된다.
  - Actual: 수정된 ASCII 허용 집합은 UTF-8 로케일에서는 정확하지만, `LC_ALL=C`의
    Bash 3.2가 Unicode를 바이트 단위로 치환해 `한글.server`를
    `mcp_________server`로 만든다. 같은 `LC_ALL=C`에서 Claude 2.1.209는 연결된
    서버 도구를 계속 `mcp_____server__<tool>`로 노출한다.
  - Evidence: `LC_ALL=C /bin/bash` 치환 결과 `C_LOCALE=mcp_________server`;
    일회성 strict MCP config의 실제 init 결과
    `MCP_SERVERS=[{"name":"한글.server","status":"connected"}]` 및
    `MCP_PREFIXES=["mcp_____server"]`.
  - Smallest next fix: 정규화 구간만 사용 가능한 UTF-8 문자 로케일로 고정해 호출자의
    `LC_ALL`을 격리하고, `LC_ALL=C /bin/bash`에서 helper와 세 래퍼를 검증하는 smoke
    회귀 테스트를 추가한 뒤 전체 proof set을 다시 실행한다.

## 2026-07-15T05:04:20+09:00 - verifier iteration 3

- [ ] Criterion 1: plan/review 래퍼가 허용한 MCP 도구를 실제로 실행하면서 built-in
  read-only 경계를 유지한다.
  - Expected: 구성된 서버의 `mcp__<server>` 규칙이 실제 MCP tool call을 승인하고,
    plan/review의 파일 수정 built-in은 실행할 수 없다.
  - Actual: installed helper가 정확한 `mcp__codebase-memory-mcp`를 전달했지만
    `--permission-mode plan`이 `mcp__codebase-memory-mcp__list_projects`를 거부했다.
    Claude 2.1.209 직접 재현에서도 tool result가
    `Cannot call mcp__codebase-memory-mcp__list_projects while in plan mode.`였고
    `permission_denials`에 같은 도구가 기록됐다.
  - Evidence: post-release session `2e14cd21-529a-4d10-9097-f6e617f34245`;
    직접 재현은 MCP 도구 14개가 init에 노출되고 정확한 도구를 선택했지만 실행 단계에서
    plan mode 거부. 반대로 `--permission-mode dontAsk --tools Read,Grep,Glob
    --allowedTools mcp__codebase-memory-mcp`에서는 `list_projects`가 실행되고
    `permission_denials=[]`; init built-in 목록은 `Glob`, `Grep`, `Read`뿐이었다.
  - Smallest next fix: plan/review의 `plan` mode를 headless 제한 모드인 `dontAsk`로 바꾸고,
    plan은 `--tools Read,Grep,Glob`, review는 `--tools Read,Grep,Glob,Bash`로 built-in
    가용성을 제한한다. 기존 `--allowedTools`의 MCP server 규칙과 review의 read-only
    `Bash(git diff|log|show|status:*)` 규칙만 사전 승인해 나머지 built-in 요청은 자동
    거부한다. smoke는 argv뿐 아니라 tool allowlist를 확인하고, live 회귀는 MCP result가
    non-error이며 `permission_denials=[]`임을 확인한다.
  - Verification note: 이 관리 환경에서는 허용된 review Bash도
    `~/.claude/session-env` 생성 EPERM으로 실행 전 차단되므로, scoped Bash 실행 증명은
    정상 호스트에서 재확인한다. 이는 MCP 권한 거부와 별개의 기존 host-policy 제약이다.
