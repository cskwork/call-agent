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
