# cc-agent-call

**한국어** · [English](./README.md)

> 한 줄 요약: 사용 중인 AI CLI(예: Claude Code)가 못 하는 일을 다른 AI CLI(Codex, Antigravity, Kiro, NotebookLM)에게 **자동으로 떠넘기게** 해주는 "위임 스킬" 모음입니다.

---

## 0. 이 문서를 읽기 전에 — 용어 미리보기

처음 보는 단어가 많을 수 있어 먼저 정리합니다.

| 용어 | 풀어쓰면 |
|---|---|
| **Agentic CLI** | 터미널에서 도는 AI 도구. 사람이 "이거 해줘" 하면 스스로 파일을 읽고/고치고/명령을 실행함. 대표 예: Claude Code, OpenAI Codex CLI, Google Antigravity(`agy`), AWS Kiro CLI(`kiro-cli`). |
| **Host (호스트)** | 지금 당신이 켜놓고 대화 중인 CLI. 보통 Claude Code 또는 Codex. |
| **Skill (스킬)** | Claude Code / Codex가 "특정 상황에서 어떻게 행동할지"를 적어둔 폴더. `SKILL.md` 한 장 + 부속 스크립트로 구성. 호스트가 자동으로 발견·로드. |
| **Delegation (위임)** | 호스트가 직접 처리하지 않고 **다른 CLI를 셸에서 실행**시켜 결과를 받아오는 행동. 이 저장소가 제공하는 핵심 동작. |
| **MCP** | Model Context Protocol. 여러 AI 도구가 공통으로 외부 서버(파일·DB·웹 등)에 접근하기 위한 규약. `kiro-call`의 cross-registry 기능에서 등장. |
| **RAG** | Retrieval-Augmented Generation. 모델이 답하기 전에 외부 문서를 먼저 검색해 근거로 사용하는 방식. NotebookLM이 잘하는 일. |

---

## 1. 왜 만들었나요?

요즘 비슷한 시기에 여러 회사가 "내 AI CLI"를 내놓았습니다. 다 똑같아 보이지만 **각자 잘하는 게 다릅니다.**

- **Claude Code** — 코드 편집·기획·1M 토큰 컨텍스트로 큰 코드베이스 분석에 강함. 이미지 생성은 못 함.
- **OpenAI Codex CLI** — 이미지 생성(`gpt-image-2`)이 가능하고, `codex review`로 PR 단위 리뷰가 강함.
- **Google Antigravity (`agy`)** — Google Search를 모델 추론 단계에 끼워주는 grounding 기능, gnomAD/UniProt 같은 과학 DB 직결.
- **AWS Kiro CLI (`kiro-cli`)** — 헤드리스 자동화에 강하고, "자연어 → 셸 명령" 번역 기능이 있으며, AWS Bedrock 계열 모델로 2차 의견을 받음.
- **NotebookLM** — PDF·웹·유튜브를 통째로 넣고 정확한 RAG 답변, 오디오 개요 생성.

이 상황에서 흔히 일어나는 불편:

> "지금 Claude Code로 작업 중인데 다이어그램 이미지가 하나 필요해. 일일이 다른 터미널 열어서 Codex 켜고… 귀찮네."

**cc-agent-call**은 그 귀찮음을 없앱니다. Claude Code 안에서 "이미지 하나 만들어줘" 라고 하면, Claude Code가 알아서 `codex-call` 스킬을 통해 Codex를 실행해 이미지를 받아옵니다. 사용자는 CLI를 갈아탈 필요가 없습니다.

---

## 2. 어떤 경우에 자동으로 호출되나요?

각 스킬은 두 가지 조건 중 하나일 때만 발동합니다. 의도치 않게 외부 CLI가 호출되면 비용·시간 낭비라서 일부러 좁게 잡았습니다.

1. **사용자가 도구 이름을 명시한 경우** — "agy로 검색해줘", "kiro한테 물어봐", "ask codex", "NotebookLM에 넣어줘" 등.
2. **호스트 CLI가 native로 못 하는 기능을 요청한 경우** — 예: Claude Code 사용 중에 "이 도식 이미지로 그려줘" → Claude Code는 이미지 생성을 못 하므로 `codex-call` 발동.

루틴한 작업(`이 코드 리뷰해줘`, `이 기능 계획 짜줘`)에는 발동하지 않습니다. 호스트 본인이 충분히 잘하기 때문입니다.

---

## 3. 들어있는 스킬 5개

| 스킬 | 어디서 동작? | 어떤 능력을 빌려오나? | 자주 쓰는 사례 |
|---|---|---|---|
| [`agy-call`](skills/agy-call/) | Claude Code | Google Antigravity | 최신 웹 정보 grounding, 이미지 생성, gnomAD/UniProt/PubMed 같은 생명과학 DB 조회, 2차 의견 |
| [`kiro-call`](skills/kiro-call/) | Claude Code | AWS Kiro CLI(`kiro-cli`) | "이거 하는 셸 명령 알려줘"식 자연어 → 셸 번역, MCP 서버 교차 등록, AWS Bedrock 모델로 2차 의견 |
| [`codex-call`](skills/codex-call/) | Claude Code | OpenAI Codex | 고품질 이미지 생성(`gpt-image-2`), `codex review`로 명시적 코드 리뷰 |
| [`notebooklm-call`](skills/notebooklm-call/) | Claude Code + Codex | Google NotebookLM | PDF/URL/YouTube 문서 묶음에 대한 RAG QA, 오디오 개요 |
| [`claude-call`](skills/claude-call/) | Codex CLI | Claude Code | Codex 사용자가 1M 컨텍스트 기획(plan-mode), 대형 코드베이스 심층 리뷰가 필요할 때 |

> "Host"는 **당신이 현재 켜놓고 대화 중인 CLI**입니다. 예를 들어 `claude-call`은 Codex 사용자가 설치하는 스킬입니다(거꾸로!).

각 스킬 폴더 안 `SKILL.md`를 열어보면 정확한 트리거 키워드와 호출 예시가 적혀 있습니다.

---

## 4. 설치

### 4-1. 사전 준비 (스킬마다 다름)

본인이 **실제로 쓸 스킬만** 준비하면 됩니다. 전부 설치할 필요 없음.

| 스킬 | 필요한 바이너리 | 인증 방법 |
|---|---|---|
| `agy-call` | `agy` (Antigravity CLI) | `agy install` → Google 계정 로그인 |
| `kiro-call` | `kiro-cli` (AWS Kiro CLI) | `kiro-cli login` |
| `codex-call` | `codex` | `codex login` (ChatGPT) 또는 `OPENAI_API_KEY` 환경변수 |
| `notebooklm-call` | Python 3.10+, `notebooklm` CLI | `notebooklm login` (브라우저 1회) |
| `claude-call` | `claude` (Claude Code) | `claude auth login` 또는 `ANTHROPIC_API_KEY` 환경변수 |

### 4-2. 저장소 클론

```bash
# GitHub에서
git clone https://github.com/cskwork/cc-agent-call
# 또는 사내 Gitea에서
git clone https://gitea.agentic-worker.store/Donga-AX/cc-agent-call.git

cd cc-agent-call
```

### 4-3. 스킬 심볼릭 링크 생성

`install.sh`는 이 저장소의 `skills/<name>` 폴더를 호스트 CLI가 보는 위치(`~/.claude/skills/<name>` 또는 `~/.codex/skills/<name>`)로 **symlink** 해줍니다. 복사가 아니라 링크라 저장소를 `git pull` 하면 호스트도 즉시 새 버전을 봅니다.

```bash
./install.sh                # 5개 전부 설치
./install.sh agy-call       # 하나만 설치
./install.sh --dry-run      # 실제로는 안 하고 어디에 무엇이 연결될지만 미리보기
./install.sh --uninstall    # 만들어둔 symlink 전부 제거
```

설치 후 호스트 CLI(Claude Code 등)를 새 세션으로 열면 스킬이 자동 로드됩니다.

> 참고: `notebooklm-call`은 Claude Code와 Codex 양쪽에서 모두 동작하므로 두 디렉터리 모두에 링크됩니다.

---

## 5. 처음 써보기 — 5분 워크스루

상황: **Claude Code로 작업 중인데 README용 일러스트가 필요하다.**

```text
> README 상단에 들어갈 추상적 일러스트 하나 만들어줘. 1:1 비율.
```

Claude Code는 이미지 생성을 native로 못 합니다. 설치된 `codex-call` 스킬이 트리거되어 다음을 자동 수행합니다:

1. 프롬프트를 Codex 형식으로 다듬어 셸에서 `codex` 실행
2. Codex가 `gpt-image-2`로 이미지 생성
3. 결과 파일 경로를 받아 Claude Code 대화창에 보고

당신은 CLI를 갈아타지 않았습니다.

다른 예:

- "agy로 'gpt-image-2 가격' 검색해줘" → `agy-call`이 Google Search grounding으로 응답
- "이 PDF 5개에 대해 NotebookLM에 묶고 'Section 3 결론' 물어봐" → `notebooklm-call`이 corpus 생성 후 질의

---

## 6. 트리거 정책 상세

각 `SKILL.md`에는 다음과 비슷한 정책이 들어 있습니다:

> Use ONLY when the user explicitly says "codex" / "kiro" / "agy" / "notebooklm", OR the task is image generation / NL-to-shell / scientific DB / document RAG. Do NOT use for routine code edits, planning, or analysis that the host can do natively.

**왜 이렇게 보수적으로 잡았나?**

- 외부 CLI 호출은 보통 별도 토큰/크레딧을 소비합니다.
- 호스트가 스스로 잘하는 일을 굳이 외주 보내면 응답 속도가 느려집니다.
- 자동 호출이 폭주하면 사용자가 "이 도구가 지금 뭘 하고 있는지" 추적하기 어려워집니다.

따라서 "확실히 필요할 때만" 발동하도록 키워드를 좁게 잡았습니다.

---

## 7. 테스트

설치 후 동작 확인:

```bash
./tests/run-all.sh                 # L0 + L1: 바이너리 존재 & --help 동작 확인
RUN_L2=1 ./tests/run-all.sh        # L2 추가: 실제 round-trip 프롬프트 (크레딧 소모)
RUN_L3=1 ./tests/run-all.sh        # L3 추가: 핵심 기능(이미지 생성 등) 실행 (크레딧 소모)
```

각 스킬별 개별 스모크 테스트:

```bash
./skills/agy-call/tests/smoke.sh
./skills/codex-call/tests/smoke.sh
# ... 등
```

L2/L3은 실제로 외부 모델을 호출하므로 비용이 발생할 수 있습니다. CI에 거는 경우 L0/L1만 켜두는 것을 권장합니다.

---

## 8. 자주 묻는 질문

**Q. 호스트 CLI를 안 쓰는데 그냥 외부 CLI만 쓰면 안 되나요?**
됩니다. 이 저장소는 **호스트 안에서 흐름을 끊지 않고 외부 CLI를 부르는 경우**에만 의미가 있습니다. 단독 사용이라면 그냥 해당 CLI를 직접 쓰는 게 빠릅니다.

**Q. 스킬이 자동 호출되는 게 싫어요.**
호스트 CLI 측에서 스킬을 비활성화하거나, `install.sh --uninstall`로 symlink만 제거하면 됩니다. 저장소 자체는 그대로 둬도 무방합니다.

**Q. 새 CLI(예: 차세대 도구)도 추가할 수 있나요?**
가능합니다. `skills/<new-name>/SKILL.md`를 만들고 `install.sh`의 `declare_targets()` 케이스에 호스트 위치를 추가하면 됩니다.

**Q. 보안은?**
이 저장소는 토큰을 보관하지 않습니다. 각 CLI의 인증은 해당 도구의 표준 방식(설정 파일 / 환경변수)을 그대로 사용합니다.

---

## 9. License

MIT
