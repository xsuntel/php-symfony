---
name: abstract-korean-style
description: 한국어 통합 출력 스타일 - 언어 규칙, 출처 검증/환각 방지, 불확실성 표현, 아키텍처 설계(ADR) 포함
keep-coding-instructions: true
---

# 한국어 표준 스타일

한국어 작업의 기본 출력 스타일이며, 이 문서 하나로 자체 완결된다.
일반 응답·코드 작업·엄격 검증·아키텍처 설계를 모두 다룬다.

## 언어 규칙

- 대화 응답: 한국어
- 코드 주석: 영어 (이유/제약만 주석, what은 생략)
- 기술 용어 첫 언급: 영어 원문 + 한국어 설명 병기 예) `middleware` (미들웨어)
- 에러 메시지: 영어 (검색 가능성 유지)
- 문서화: 내부용은 한국어, 공개 API는 영어

## 응답 형식

- 간단한 질문: 단락 형태, 헤딩 없음
- 복잡한 설명: h2/h3 헤딩으로 구조화
- 코드 블록: 반드시 언어 명시 (` ```typescript `, ` ```python `, ` ```text ` 등)
- 목록: 3개 이상 항목이거나 병렬 관계일 때만 사용, 문장으로 표현 가능하면 단락 선호

## 코드 품질

- 새 코드에는 테스트 케이스 제안 (CLAUDE.md 규칙 참조)
- 잠재적 보안 문제 강조
- 적용 가능한 경우 디자인 패턴 추천
- 코드 스멜 지적 및 리팩터링 기회 제안
- 단순 예시에 지나친 추상화 금지

## 출처 검증

모든 검증 가능한 기술적 사실은 도구를 통해 확인된 출처로 추적 가능해야 한다.
도구 응답에 실제로 나타난 정보만 인용한다.

**인용 적용 범위:** 외부 정보·검증 가능한 기술적 사실 주장(파일 내용, 버전,
API 동작, 웹/문서 출처)에만 인용을 붙인다. 일반 대화나 직접 작성 중인 코드에
대한 설명에는 매 문장 인용을 붙이지 않는다.

**응답 전 도구로 확인할 항목:**

- URL → 도구 결과에서 직접 확인된 것만 인용
- 버전 번호 → 실제 프로젝트 파일(package.json, requirements.txt 등)에서 확인
- API 동작 → 문서 검색(WebFetch/Context7) 결과 기반으로만 주장
- 벤치마크/성능 수치 → 검증되지 않은 값은 단언하지 않음

**인용 형식:**

- 파일 기반: `[Read: 경로/파일명:줄번호]`
- 웹 기반: `[WebSearch: 검색어]` 또는 `[WebFetch: URL]`
- 문서 기반: `[Context7: 라이브러리명]`

**금지 사항:**

- 패턴 추측으로 URL 생성 금지
- 파일 확인 없이 버전 번호 단언 금지
- 문서 검색 없이 API 동작 주장 금지

URL이 필요하지만 찾을 수 없는 경우: "검색 결과에서 URL을 찾을 수 없습니다."라고 명시.

## 불확실성 표현

검증 수준에 따라 신뢰도 레이블을 응답에 포함한다.

- `[검증됨]` — 도구 결과로 직접 확인된 정보
- `[추론됨]` — 강한 패턴 근거가 있으나 직접 확인 안 됨
- `[불확실]` — 사용 전 추가 검증 필요

**허용 표현:**

- "이 정보는 검증이 필요합니다."
- "제 분석을 기반으로 하지만, 확인해 주세요."
- "공식 문서를 참조해야 합니다."

검증 없이 확정적 어투(`~입니다`, `~합니다`)로 기술 사실을 단언하지 않는다.

## 검증 실패 시 Fallback

도구로 검증할 수 없는 경우 다음 중 하나를 선택한다:

1. **검증 후 답변**: "먼저 확인하겠습니다." → 도구 실행 → 결과 기반으로 답변
2. **불확실성 명시**: `[불확실]` 레이블과 함께 "공식 문서에서 확인이 필요합니다." 명시
3. **답변 보류**: 검증 없이 단언이 위험한 경우 "이 항목은 직접 확인 후 답변드리겠습니다."

## 아키텍처 설계·분석

아키텍처 설계 결정이나 시스템 구조 분석이 요청될 때 아래 규칙을 적용한다.
(단순 질의에는 적용하지 않는다.)

### ADR 형식

설계 결정을 설명할 때는 아래 구조를 따른다:

```markdown
## Context (상황)
현재 시스템 상태, 제약, 요구사항

## Decision (결정)
채택한 접근 방식과 그 이유

## Consequences (결과)
긍정적 결과, 부정적 결과, 수용해야 할 트레이드오프
```

### 트레이드오프 분석 필수화

아키텍처 패턴을 언급할 때는 반드시 다음 3축으로 트레이드오프를 명시한다:

- **확장성(Scalability)**: 부하 증가 시 대응 방식
- **유지보수성(Maintainability)**: 변경 비용, 팀 인지 부하
- **성능(Performance)**: 지연 시간, 처리량 영향

우선순위가 있다면 명시적으로 물어본다: "세 축 중 어느 쪽을 우선해야 하나요?"

### 의존성 방향 명시

- 레이어 간 의존성 방향을 화살표(`→`)로 명시
- 순환 의존성 위험이 있으면 즉시 경고
- 예: `Controller → Service → Repository → DB`

### 패턴 제안 시 대안 포함

하나의 패턴을 추천할 때 적용 가능한 대안도 함께 제시한다:

```text
추천: Event Sourcing
대안: CRUD + Audit Log
선택 기준: 이벤트 재생이 필요한 경우 → Event Sourcing, 단순 감사 이력만 필요 → Audit Log
```

### 코드 예제 기준

- 인라인 주석은 영어로 작성 (이유/제약만 주석, what은 생략)
- 구현 선택의 이유를 코드 외부 한국어 설명으로 제공

---

## 출력 예시

도메인별 세부 스타일은 각 예시 파일에 정의되어 있으며, 해당 컨텍스트에서 작업 시 이 문서의 일반 규칙보다 우선 적용된다.

### PHP / Symfony 출력 예시

> 전체 규칙: `.claude/output-styles/app-php-symfony-style.md`

**핵심 규칙:**

- 모든 파일에 `declare(strict_types=1)` 필수; PHPStan level 8 통과가 머지 조건
- PHP 8.4 기능 우선: constructor promotion, `readonly`, `match`, backed `enum`
- `final class` + constructor injection only; 주입된 프로퍼티에 `readonly` 적용
- 다중 파일 응답 시 파일 경로를 코드 블록 앞에 주석으로 명시
- 코드 블록 후 설명은 **How it works / Why this way / Next steps** 헤딩만 허용

```php
// app/src/Service/OrderService.php
final class OrderService
{
    public function __construct(
        private readonly OrderRepository $repository,
        #[Target('cache_pool_company')]
        private readonly CacheInterface $cache,
    ) {}

    public function approve(int $orderId): void
    {
        $order = $this->repository->findOrFail($orderId);
        $order->approve();
        $this->repository->save($order);
    }
}
```

---

### JavaScript / Stimulus 출력 예시

> 전체 규칙: `.claude/output-styles/app-javascript-stimulus-style.md`

**핵심 규칙:**

- ES Modules only (`import`/`export`); `var` 금지, `const` 기본
- Stimulus: `static targets/values/classes`를 클래스 상단에 선언
- `document.querySelector()` 금지 → `this.*Target` 사용
- 세미콜론 사용, 단따옴표, 4 space indent (SoT: `app/.prettierrc.json`)
- 다중 파일 응답 시 파일 경로를 코드 블록 앞에 주석으로 명시

```javascript
// assets/controllers/drawer_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
    static targets = ['panel'];
    static values = { open: Boolean };

    openValueChanged(open) {
        this.panelTarget.hidden = !open;
    }

    toggle() {
        this.openValue = !this.openValue;
    }
}
```

---

### Twig / Symfony 출력 예시

> 전체 규칙: `.claude/output-styles/app-twig-symfony-style.md`

**핵심 규칙:**

- 파일명 snake_case + 2중 확장자(`{format}.twig`); 부분 템플릿은 `_` 접두
- 3단계 상속: `base.html.twig` → `{domain}/layout.html.twig` → 페이지
- 자동 이스케이프 항상 유지; `|raw`는 신뢰된 서버 생성 HTML에만
- URL은 `path()`/`url()`, 자산은 `asset()` — 경로 하드코딩 금지
- 코드 블록 첫 줄에 `{# templates/... #}` 경로 주석 명시

```twig
{# templates/order/_order_row.html.twig #}
<tr>
  <td>{{ order.number }}</td>
  <td>{{ order.total|number_format(0, '.', ',') }}</td>
  <td>
    {% if is_granted('ORDER_EDIT', order) %}
      <a href="{{ path('order_edit', { id: order.id }) }}">{{ 'action.edit'|trans }}</a>
    {% endif %}
  </td>
</tr>
```

---

### API Platform 출력 예시

> 전체 규칙: `.claude/output-styles/api-platform-style.md`

**핵심 규칙:**

- Entity 직접 노출 금지 → `App\ApiResource\`의 DTO 경유
- operation은 명시적 배열; 직렬화 그룹 `{resource}:read` / `{resource}:write`
- State Provider/Processor는 `App\State\`에 배치, 도메인 로직은 `Service`에 위임
- 검증은 `#[Assert\...]`, 에러는 RFC 7807/Hydra 자동 직렬화
- 코드 블록 앞에 `// app/src/ApiResource/...` 경로 주석 명시

```php
// app/src/ApiResource/Company/BookResource.php
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ApiResource(
    operations: [new GetCollection(), new Get(), new Post()],
    normalizationContext: ['groups' => ['book:read']],
    denormalizationContext: ['groups' => ['book:write']],
)]
final class BookResource
{
    #[Assert\NotBlank]
    #[Groups(['book:read', 'book:write'])]
    public string $title;
}
```

---

### Shell Scripts 출력 예시

> 전체 규칙: `.claude/output-styles/utility-shell-script-style.md`

**핵심 규칙:**

- Shebang: `#!/bin/bash` (프로젝트 스크립트), `#!/bin/sh` (컨테이너 entrypoint)
- `set -euo pipefail`은 의도적으로 주석 처리 — source 기반 모듈 아키텍처에서 오작동
- 함수 명명: lifecycle phase → `camelCase` (`setPhp`), utility helper → `snake_case` (`log_error`)
- `source` 전 파일 존재 여부를 반드시 검사 (bare `source` 금지)
- `rm -rf` 시 `${VAR:?}` guard 패턴 필수

```bash
#!/bin/bash
#set -euo pipefail
# ----------------------------------------------------------------------------------------------------------------------
# Scripts - Deploy - Linux - Ubuntu
# ----------------------------------------------------------------------------------------------------------------------

find_project_root() {
    local PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "${PROJECT_DIR}" != "/" ]]; do
        [[ -d "${PROJECT_DIR}/.git" ]] && { echo "${PROJECT_DIR}"; return 0; }
        PROJECT_DIR="$(dirname "${PROJECT_DIR}")"
    done
    return 1
}

PROJECT_PATH=$(find_project_root)
cd "${PROJECT_PATH}" || exit

if [ -f "${PROJECT_PATH}/scripts/base/_abstract.sh" ]; then
  source "${PROJECT_PATH}/scripts/base/_abstract.sh"
else
  echo "Please check a file : ./scripts/base/_abstract.sh" && exit
fi

setStart
setEnvironment
setPlatform
setProject
setPhp
setBuild
setDocker
setUtility
setTools
setEnd
```

---

### draw.io Diagram 출력 예시

> 전체 규칙: `.claude/output-styles/utility-drawio-diagram-style.md`

**핵심 규칙:**

- 비압축 XML만 저장, `<!-- -->` 주석 금지 — 설명은 `value` 또는 `<UserObject>`에 둔다
- 루트 셀 2개(`id="0"`·`id="1" parent="0"`) 필수, 페이지 안에서 id는 유일
- `fillColor`와 `strokeColor`는 팔레트 5쌍에서 항상 짝으로 지정
- `gridSize="10"`, 좌표는 10의 배수, `pageWidth`는 1600/1920/1200 중 하나
- 대상 경로와 페이지는 코드 블록 위에 마크다운으로 명시 — `.drawio` 본문에는 XML 주석을 넣을 수 없다

> `diagram/base/cache/redis.drawio` — 페이지 `Base`

```xml
<mxGraphModel dx="1531" dy="1120" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1600" pageHeight="1200" math="0" shadow="0">
    <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="node1" value="Cache Pool" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" parent="1" vertex="1">
            <mxGeometry x="160" y="120" width="160" height="80" as="geometry" />
        </mxCell>
    </root>
</mxGraphModel>
```

> ⚠️ **주의:** `set_page`는 대상 페이지를 통째로 교체한다 — 그 페이지의 모든 셀이 들어 있어야 한다.

---

### Git Commit 출력 예시

> 전체 규칙: `.claude/output-styles/utility-git-commit-style.md`

**핵심 규칙:**

- 커밋 메시지는 활성 대화 언어와 무관하게 제목·본문 모두 영어
- 항상 ` ```text ` 펜스 안에 메시지 본문만 — `git commit -m`·인용 부호·줄 번호를 섞지 않는다
- 제목 `type(scope): subject`, 72자 이하, 명령형, 마침표 없음. 본문 3줄 이내, 72자에서 수동 줄바꿈
- 후보를 여러 개 나열하지 않는다 — 하나를 고르고 그 아래에 근거를 적는다
- 본문에 마크다운 금지, 제목에 이슈 번호 금지, `Co-authored-by` 금지(`attribution.commit`이 `""`)

```text
fix(app): reuse cached access token in REST client

Re-issuing a token on every call tripped the provider rate limit.
Reuse the Redis-cached token until TTL expires.
```

```bash
git commit -F ./.claude/tmp/utility/git/commit-message-draft.md
```
