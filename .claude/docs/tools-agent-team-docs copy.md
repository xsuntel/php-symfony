# Tools Agent Team 구성

> 상태: **설계 문서(배경·근거)** — 저장소의 **인프라·데이터·배포 자산** 판정을 한 오케스트레이터로
> 묶는 구조와, `tools-agent-team`의 로스터·라우팅·팬아웃 근거를 정의한다.
>
> **판정 SoT가 아니다.** `utility-claude-code-rule.md`의 `## 참조 문서 전용 규칙`에 따라
> `.claude/docs/**`는 언제나 참조이며, 규칙과 충돌하면 규칙이 우선한다. 이 문서의 짝이 되는
> 판정 SoT는 **`rules/tools-agent-team-rule.md`**(오케스트레이션 불변식)와 **도메인 규칙 5종**
> (코드·설정 판정)이다.
>
> 작성일: 2026-08-30
>
> **2026-08-30 신설 — 이 문서는 앞선 판단의 번복이다.** 2026-08-29 팀을 만들 때는 "Review 단독
> 팀이라 역할 축 설계가 없으므로 짝 문서를 두지 않는다"고 결정하고, 설계 SoT 자리를
> `abstract-orchestrator-contract-docs.md`가 겸하게 했다. 그 결정을 되돌린 근거는 5.3절에 있다.

@see .claude/agents/tools-agent-team.md — 이 문서와 짝을 이루는 오케스트레이터(실행 지시)
@see .claude/rules/tools-agent-team-rule.md — 오케스트레이션 불변식 판정 SoT
@see .claude/docs/app-agent-team-docs.md — 앱 본체·운영 축 설계(SoT)
@see .claude/docs/api-agent-team-docs.md — API Platform 노출 계층 축 설계(SoT)
@see .claude/docs/abstract-orchestrator-contract-docs.md — 세 팀 공통 운영 계약의 근거·측정값
@see .claude/skills/tools-app-deploy-skill/SKILL.md — 배포 전 게이트(go/no-go 소유자)
@see .claude/rules/abstract-structure-rule.md — 규칙 인덱스(SoT)
@see .claude/output-styles/abstract-korean-style.md — 문서 스타일(ADR·트레이드오프·인용)

---

## 1. 개요 및 전제

### 목적

이 문서는 **인프라 설정·데이터 매핑·배포 자산**의 판정을 담당하는 리뷰어 5종을 하나의
오케스트레이터로 묶은 구성을 정의한다. 형제 문서 둘과 달리 **역할 축이 하나뿐**이라 팀 정의가
짧고, 대신 **로스터 확정 방식**과 **과매칭 억제**에 지면을 쓴다 — 그 둘이 이 팀의 실제 실패
지점이기 때문이다.

**범위 밖:** 앱 본체 코드(PHP·JS·Twig)·외부 provider 소비·셸·다이어그램·커밋·`.claude` 설정은
`app-agent-team`, API Platform 노출 계층은 `api-agent-team` 소관이다.

### 전제 사실 (검증됨)

`[검증됨]` 2026-08-30, `.claude/**` 실측:

| 항목 | 값 | 근거 |
| --- | --- | --- |
| 저장소 오케스트레이터 수 | **3** | `agents/{app,api,tools}-agent-team.md` |
| 이 팀의 로스터 해석값 | **5종** | `ls .claude/agents/{cache,database,server,tools-aws,tools-gcp}-*.md` |
| 로스터 5종 공통 스펙 | `model: sonnet` · `tools: Read, Grep, Glob, Bash` · `maxTurns: 30` · `memory: project` · `color: blue` | 각 `*-reviewer.md` 프론트매터 |
| 오케스트레이터 스펙 | `model: opus` · `maxTurns: 40` · `tools: Agent, Bash, Read, Grep, Glob, Write, Skill` | `agents/tools-agent-team.md` |
| 전용 리뷰 커맨드 | **3종**(`/cache-redis-review`·`/database-postgresql-review`·`/server-nginx-review`) | `commands/` |
| 전용 리뷰 커맨드가 **없는** 축 | GCP Cloud Run · AWS ECS | 같은 위치 |

**`maxTurns: 40`은 형제 오케스트레이터(80)의 절반이다.** 팬아웃 1회 + 취합이 전부이고
author→reviewer 루프가 없으므로 턴 예산이 그만큼 덜 든다.

### 3계층 협업 원칙

저장소 공통 구조를 이 팀에 적용하면 다음과 같다.

```text
오케스트레이터(agents/tools-agent-team.md)  = 라우팅·팬아웃·취합만 소유. 판정 기준 미보유
리뷰어(agents/{5종}.md)                     = 자기 도메인 규칙(SoT)을 대조해 판정
규칙(rules/{5종}-rule.md)                   = 판정 기준의 단일 출처
```

**오케스트레이터가 판정 기준을 갖지 않는 것이 핵심이다.** 기준을 여기 복제하면 규칙과 두 벌이
되고, 규칙만 고쳤을 때 조용히 갈라진다.

---

## 2. 에이전트 인벤토리

### 2.1 로스터 (프리픽스 5종)

| 도메인 | 리뷰어 | 근거 규칙(SoT) | 주 대상 경로 |
| --- | --- | --- | --- |
| Redis·캐시·락·세션 | `cache-redis-reviewer` | `cache-redis-rule.md` | `app/config/packages/{cache,lock}.yaml` · 캐시와 **실제로 관련된** PHP |
| PostgreSQL·Doctrine | `database-postgresql-reviewer` | `database-postgresql-rule.md` | `app/src/{Entity,Repository}/**/*.php` · `app/migrations/**` |
| Nginx | `server-nginx-reviewer` | `server-nginx-rule.md` | `scripts/**/nginx/**` |
| GCP Cloud Run | `tools-gcp-cloudrun-reviewer` | `tools-gcp-cloudrun-rule.md` | `scripts/containers/prod/**` · `**/*.tf` · `**/cloudbuild.yaml` · `**/Dockerfile` |
| AWS ECS | `tools-aws-ecs-reviewer` | `tools-aws-ecs-rule.md` | `scripts/containers/prod/**` · `**/*.tf` · `**/taskdef*.json` · `**/buildspec.yml` · `**/Dockerfile` |

**로스터는 이 표가 아니라 다섯 접두사가 정의한다** — 표는 2026-08-30 시점의 프리플라이트
해석값이다. 판정 규약은 `rules/tools-agent-team-rule.md`의 `## 불변식 — 로스터는 프리플라이트로
확정한다`가 SoT다.

### 2.2 로스터에 없는 것 (착각하기 쉬운 둘)

- **`message-rabbitmq-reviewer`** — 저장소에 실재하는 여섯 번째 인프라 리뷰어지만 다섯 접두사
  어디에도 걸리지 않는다. Messenger·RabbitMQ 판정은 `app-agent-team`의
  `/message-rabbitmq-review` 커맨드 소관이다. **이름이 비슷하다는 이유로 끌어오지 않는다.**
- **셸 스크립트 리뷰어** — 에이전트가 **존재하지 않는다**(2026-08-16 커맨드로 병합).
  `/utility-shell-script-review` 커맨드가 기존 파일 리뷰와 초안 셀프 검증 기준을 함께 보유한다.

### 2.3 모델·도구 축

- **로스터 전원이 `sonnet` + 읽기 전용 4도구**다. 인프라 판정은 규칙 대조가 대부분이라 상위
  모델이 필요하지 않고, 오케스트레이터만 `opus`로 라우팅·취합을 맡는다.
- **읽기 전용은 하네스로 강제되지 않는다.** 5종 모두 `memory: project`라 하네스가 `tools` 목록과
  무관하게 `Read`·`Write`·`Edit`를 자동 부여한다 — 위반이 아니라 하네스 동작이므로 리뷰에서
  지적하지 않는다. 실제로 막으려면 `memory:`를 떼거나 `permissions.deny`로 통제해야 한다.

---

## 3. 팀 정의 — Review 단독

### 3.1 Review 팀 (이 팀의 전부)

- **트리거:** 인프라·데이터·배포 자산 변경 후, 또는 "인프라 점검"·"캐시 리뷰"·"Doctrine 매핑
  점검"·"nginx 설정 리뷰"·"Cloud Run 설정 검토"·"ECS taskdef 리뷰" 같은 의도.
- **진입점:** `tools-agent-team` 오케스트레이터(다도메인) 또는 해당 `/…-review` 커맨드(단일 도메인).
- **절차:** 프리플라이트 → 범위 선별 → 라우팅(과매칭 억제) → 병렬 팬아웃 → 중복 병합 → 취합 보고.
- **산출물:** `[MUST]`/`[SHOULD]`/`[CONSIDER]` 심각도 리포트. `[MUST]`만 머지 차단.

### 3.2 없는 축과 그 결과

| 축 | 상태 | 대체 경로 |
| --- | --- | --- |
| **Build**(생성) | 없음 | 판정만 내고 수정은 사용자 또는 `app-agent-team`(PHP·셸) |
| **Security**(보안 진단) | 없음 | 도메인 규칙의 보안 절이 Review 안에서 함께 판정된다 |
| **Debug**(근본 원인) | 없음 | `app-php-symfony-debugger`(런타임)·해당 배포 스킬(운영) |
| **Test**(회귀 방지) | 없음 | 인프라 도메인에 tester 축이 없다 |

**따라서 이 팀은 author→reviewer 루프도, REDO 재시도 사이클도 돌리지 않는다.** 판정은 1회이며
재스폰은 부분 실패 처리에서만 한다.

### 3.3 Deploy — 소유하지 않는 역할

배포 go/no-go는 `tools-app-deploy-skill` **게이트가 소유**한다. 그 스킬은 이 로스터의 3종
(`server-nginx-reviewer`·`tools-gcp-cloudrun-reviewer`·`tools-aws-ecs-reviewer`)과
`/utility-shell-script-review` 커맨드로 **자체 팬아웃**해 PASS/BLOCK을 낸다.

```text
"배포해도 되나"        → Skill 도구로 tools-app-deploy-skill 위임 (리뷰어 직접 스폰 금지)
"nginx 설정만 봐줘"    → server-nginx-reviewer 직접 스폰
"Cloud Run 설정 검토"  → tools-gcp-cloudrun-reviewer 직접 스폰 (배포 범위 밖)
```

**두 go/no-go를 혼동하지 않는다** — 이 팀의 판정은 **인프라 설정 품질**이고, 게이트의 PASS/BLOCK은
**배포 승인**이다.

---

## 4. 오케스트레이션 참조 패턴

### 4.1 팬아웃 1회 + 취합 (루프 없음)

```text
0. 로스터 프리플라이트 — 다섯 접두사 해석 → 스폰 허용 집합 확정
1~3. 범위 확정 → 선별(핸드오프 분리) → 라우팅(과매칭 억제 선적용)
4. 스폰 계획   — 해석된 리뷰어는 서로 의존이 없으므로 전부 병렬 (최대 5)
5. 위임 실행   — 스폰 페이로드 7필드
6. 취합·병합   — 중복 지적 1건으로, 심각도순 정렬
7. 판정·보고   — [MUST] 1건 이상 → no-go / 0건 → go / 판정 불가 축 있으면 보류
```

형제 팀의 "동시 6종 이하" 팬아웃 기준 안이므로 **배치 분할이 필요 없다.**

### 4.2 프리플라이트가 0단계인 이유

운영 계약 8절(라우팅 대상은 확인 전까지 미검증)의 이 팀 적용이다. 로스터를 산문 기억으로 고정하면
에이전트 파일이 트리보다 먼저 낡고, 그 드리프트는 **조용하다** — 없는 에이전트를 스폰하려다
실패하거나, 새로 생긴 리뷰어를 영영 부르지 않는다. 프리픽스 해석은 두 경우를 모두 드러낸다.

### 4.3 중복 지적 병합 (3건)

| 충돌 | 처리 |
| --- | --- |
| `cache-redis-rule.md`의 `paths`가 `app/src/**/*.php`로 광범위 | 무관한 PHP 변경이면 **스폰하지 않는다**. 이미 스폰했으면 무관 지적을 **제거**(병합 아님) |
| GCP·AWS가 `scripts/containers/prod/**`·`*.tf`·`Dockerfile` 공유 | **배포 타깃을 확정해 한쪽만** 스폰. 부득이 둘 다면 동일 사안 1건으로 병합 |
| `database-postgresql-rule.md` ↔ `app-php-symfony-05-doctrine-rule.md` 동일 `paths` | 이 팀은 매핑·쿼리·인덱스만. 도메인 로직 지적은 `app-agent-team` 몫으로 표시 후 병합 |

### 4.4 tmp 산출물 규약

| 용도 | 경로 |
| --- | --- |
| 도메인별 리뷰 | `./.claude/tmp/tools/<domain>-review.md` |
| 취합 리포트 | `./.claude/tmp/tools/agent-team-report.md` |

`tmp/app/**`은 `app-agent-team`, `tmp/api/**`는 `api-agent-team` 전용이다. 하위 디렉토리가 없으면
`mkdir -p`를 먼저 실행한다.

---

## 5. 트레이드오프

### 5.1 세 번째 오케스트레이터 분리 (2026-08-29)

#### Context

2026-08-28 분리 시점에 오케스트레이터는 둘이었고, 인프라·데이터 리뷰어 6종은 `app-agent-team`이
직접 스폰했다(로스터 21종). 그 결과 한 팀이 **두 성격의 축을 동시에** 지휘했다 — 앱 본체 코드
생성-검증 루프(5역할 × 3도메인)와, 루프가 없는 인프라 단발 판정. 스폰 대상이 `app-*`과
인프라 접두사로 갈려 라우팅 오판이 잦았고, 팬아웃 폭도 예측하기 어려웠다.

#### Decision

**인프라·데이터·배포 축을 별도 오케스트레이터로 분리한다.** 로스터는 다섯 접두사
(`cache-`·`database-`·`server-`·`tools-aws-`·`tools-gcp-`)로 정의하고, `app-agent-team`의 직접
스폰 대상은 `app-*-*` 15종으로 좁힌다.

#### Consequences

- **확장성** (+) 각 팀의 스폰 대상이 한 접두사 계열로 수렴해 팬아웃 폭이 로스터 크기로 결정된다.
  (−) 오케스트레이터가 셋이 되어 **경계 서술을 세 파일에서 함께** 유지해야 한다 —
  각 규칙의 `## 변경 시 동반 갱신`이 그 비용을 명시적으로 관리한다.
- **유지보수성** (+) 인프라 판정을 찾을 때 진입점이 하나로 확정된다.
  (−) `message-rabbitmq-reviewer`가 접두사 밖이라 **여섯 중 다섯만** 옮겨졌다 —
  인프라 리뷰어가 두 팀에 걸치는 비대칭이 남았다(6.1절).
- **성능** (+) `maxTurns`를 40으로 낮춰 인프라 호출의 예산을 절반으로 줄였다.
  (=) 리뷰어 스펙은 그대로라 판정 지연은 변하지 않는다.

#### 기각한 대안

- **`app-agent-team`에 그대로 두기** — 라우팅 오판의 원인을 그대로 남긴다.
- **6종 전부를 옮기고 `message-`를 접두사에 추가** — 로스터 정의가 "인프라 리뷰어 전부"라는
  열거형으로 되돌아가, 프리픽스 규칙의 자기 검증 성질(5.2절)을 잃는다.

### 5.2 로스터 정의 — 프리픽스 프리플라이트 vs 고정 목록 (2026-08-30)

#### Context

신설 시점의 로스터 제약은 **고정 이름 5개를 박은 산문**이었다. 실행 절차에 대상 확인 단계가 없어
운영 계약 8절(프리플라이트)과 연결되지 않았고, 로스터가 바뀌면 문서가 조용히 낡았다.

#### Decision

**로스터를 다섯 접두사로 정의하고 매 호출 0단계에서 Glob으로 해석한다.** 문서의 5종 표는
판정 근거가 아니라 시점 스냅샷으로 격하하고, 해석값과 표가 다르면 **해석값이 우선**한다.

#### Consequences

- (+) 같은 접두사의 리뷰어가 추가되면 **자동 편입**되고, 사라지면 "판정 불가(대상 부재)"로
  드러난다. 어느 쪽도 조용히 지나가지 않는다.
- (+) 자기 자신·형제 오케스트레이터 제외가 **glob 수준에서 성립**한다 — `tools-agent-team`은
  `tools-`로 시작하지만 `tools-aws-`·`tools-gcp-`에 걸리지 않아 별도 예외 조항이 필요 없다.
- (−) 신규 매칭 에이전트에 **근거 규칙(SoT)이 없을 수 있다.** 이때 SoT를 임의 배정하면 담당
  아닌 기준으로 판정하므로, 규칙이 확인될 때만 스폰하고 아니면 "라우팅 미매칭"으로 보고한다.
- (−) 매 호출 1회의 파일 조회 비용이 든다 — `ls` 한 번이라 무시할 수준이다.

#### 하네스 강제와의 관계

이 제약은 **문서 수준이며 하네스가 강제하지 않는다.** `PreToolUse` 훅 페이로드에
`agent_id`·`agent_type`이 있어 호출 주체 식별은 가능하지만
`[검증됨]` [WebFetch: <https://code.claude.com/docs/en/hooks>], 스폰 도구명이 `Task`인지 `Agent`인지가
문서에 명시돼 있지 않아 matcher 설계에 실측이 선행돼야 한다 `[불확실]`. 6.3절 후속 과제다.

### 5.3 짝 문서 신설 — 앞선 결정의 번복 (2026-08-30)

#### Context

신설 당시에는 "Review 단독 팀이라 역할 축 설계가 없다"는 이유로 짝 문서를 두지 않기로 하고,
설계 SoT 자리를 `abstract-orchestrator-contract-docs.md`가 겸하게 했다. 그 결정은
`abstract-structure-rule.md`·`workflows/README.md`·`app-agent-team-docs.md`·운영 계약 문서 넷에
명시적 예외로 기록됐다.

#### Decision

**짝 문서를 신설해 세 축의 대칭을 회복한다.** 운영 계약 문서는 다시 **세 팀 공통 근거**로만
쓰고, 이 팀 고유의 인벤토리·트레이드오프·공백은 이 문서가 갖는다.

#### Consequences

- (+) 슬러그 공유 관례(`agents/`·`rules/`·`docs/`가 같은 슬러그)가 세 팀 모두에서 성립해
  `@see`가 예외 없이 서로를 찾아간다.
- (+) 공통 계약 문서에서 이 팀 고유 서술이 빠져 **세 팀 공통**이라는 성격이 선명해진다.
- (−) 유지 대상 문서가 하나 늘었다. 위 넷의 "짝 문서 없음" 예외 서술을 **같은 변경에서 함께**
  제거해야 했다 — 하나라도 남으면 서술이 갈라진다.

---

## 6. 현황 공백 및 후속 과제

### 6.1 GCP·AWS 전용 리뷰 커맨드가 없다

`/cache-redis-review`·`/database-postgresql-review`·`/server-nginx-review`는 있으나
Cloud Run·ECS는 없다. 따라서 두 축의 단독 판정 진입점은 **리뷰어 직접 스폰 또는 이 오케스트레이터**
뿐이며, 배포 범위 안이면 게이트 스킬이 받는다. **없는 커맨드를 지어내지 않는다.**
커맨드 2종 신설은 구조 변경이므로 `[CONSIDER]`이며 승인 대상이다.

### 6.2 인프라 리뷰어가 두 팀에 걸친다

`message-rabbitmq-reviewer` 하나만 접두사 밖이라 `app-agent-team` 소관으로 남았다. 사용자가
"인프라 점검"이라 말했을 때 Messenger가 함께 검토되지 않을 수 있으므로, 이 팀은 그 축이 범위에
걸리면 **핸드오프로 명시**해야 한다(조용히 빠뜨리지 않는다).

### 6.3 로스터 제약이 하네스로 강제되지 않는다

`tools: Agent`는 스폰 대상을 제한하지 않으므로 로스터 위반은 모델 준수에 의존한다.
`PreToolUse` 훅(`.claude/hooks/pre-tool-use/`는 현재 비어 있다)으로 `agent_type`을 보고 차단하는
설계가 가능하지만, 스폰 도구명 확정이 선행돼야 한다(5.2절). 도입 시
`.claude/hooks/README.md`의 `## 현재 활성 hook` 표와 `settings.json` 배선을 함께 갱신한다.

### 6.4 `app/vendor` 부재 시 설정 검증이 조용히 건너뛰어진다

`bin/console` 기반 검증(`lint:yaml`·`lint:container`)은 vendor 트리에 의존한다. 부재·불완전이면
깨지거나 건너뛰어지며 **어느 쪽도 "설정이 정상"을 뜻하지 않는다.** 취합 리포트는 이를 **미검사**로
집계하고 해소 방법(`cd app && composer install`)을 함께 낸다.

---

## 부록: 참조 자산

| 유형 | 경로 |
| --- | --- |
| 오케스트레이터 | `.claude/agents/tools-agent-team.md` |
| 오케스트레이션 판정 SoT | `.claude/rules/tools-agent-team-rule.md` |
| 에이전트 메모리 | `.claude/agent-memory/tools-agent-team/MEMORY.md` |
| 로스터 5종 | `.claude/agents/{cache-redis,database-postgresql,server-nginx,tools-aws-ecs,tools-gcp-cloudrun}-reviewer.md` |
| 도메인 판정 SoT 5종 | `.claude/rules/{cache-redis,database-postgresql,server-nginx,tools-aws-ecs,tools-gcp-cloudrun}-rule.md` |
| 도메인 참조 문서 | `.claude/docs/{cache-redis,database-postgresql,server-nginx,tools-aws-ecs,tools-gcp-cloudrun}-docs.md` |
| 단독 리뷰 커맨드 3종 | `.claude/commands/{cache-redis,database-postgresql,server-nginx}-review.md` |
| 배포 게이트 | `.claude/skills/tools-app-deploy-skill/SKILL.md` |
| 배포 실행 스킬 | `.claude/skills/tools-{gcp-cloudrun,aws-ecs}-skill/SKILL.md` |
| 공통 운영 계약 | `.claude/docs/abstract-orchestrator-contract-docs.md` |
| 형제 팀 설계 | `.claude/docs/{app,api}-agent-team-docs.md` |
