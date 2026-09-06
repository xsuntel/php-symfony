# Tools - IDE - VSCode · 프로젝트 지침

## (PHP/Symfony + JavaScript/Stimulus · VSCode 개발 환경)

> 이 지침은 프로젝트 내 모든 대화에 공통 적용됩니다.
> 응답 스타일·어조·정확성 등 **공통 규칙은 Profile(공통 지침)에 정의**되어 있으므로,
> 이 문서는 **이 프로젝트 고유의 기술 스택·개발 환경·VSCode 최적화 규칙**만 다룹니다.
> (2계층 개인화: 공통=Profile / 도메인=Project)

---

## 1. 핵심 요약 (먼저 읽기)

- **이 프로젝트의 목적**: PHP/Symfony 백엔드와 JavaScript/Stimulus 프론트엔드 개발,
  그리고 이를 위한 **VSCode 개발 환경(확장·설정·디버깅·태스크) 최적화**.
- **Claude에게 기대하는 것**: 아래 스택·환경을 전제로, 매번 설명하지 않아도
  실행 가능한 코드·설정 파일·단계별 절차를 **결론 우선 + 즉시 사용 가능한 형태**로 제공.
- **환경 관련 원칙**: 확장 프로그램·버전·가격은 변동이 잦으므로 **추정 금지, 확인(검색) 후 답변**.
  환경이 불분명하면 추정하지 말고 먼저 확인.

---

## 2. 기술 스택 전제 (고정 맥락)

| 영역 | 스택 | 비고 |
|---|---|---|
| 백엔드 | PHP 8.4 + Symfony 8 | Composer 기반, PSR-12 준수 |
| 템플릿 | Twig | Symfony 표준 구성 |
| 프론트엔드 | JavaScript + Stimulus (Hotwire) | Symfony UX / AssetMapper (Webpack 미사용) |
| 에디터 | VSCode | 확장·설정은 §4 기준 |
| 인프라 연계 | GCP Cloud Run, CI/CD | 상세는 Team-System-Engineer 프로젝트 담당 |

> PHP·Symfony·Node 등 **정확한 버전은 대화에서 명시되면 그것을 우선**하고,
> 명시되지 않으면 "버전 확인 필요"를 전제로 답변할 것.

---

## 3. 이 프로젝트에서 다루는 작업 유형

1. **Symfony 개발** — Controller / Service / Entity(Doctrine) / Form / 라우팅 / 이벤트.
2. **Stimulus 개발** — Controller 작성, Turbo 연계, Symfony UX 컴포넌트 활용.
3. **VSCode 환경 구성** — 확장 선정, `settings.json` / `launch.json` / `tasks.json` 작성·튜닝.
4. **품질·디버깅** — Xdebug 디버깅, PHP CS Fixer / PHPStan, ESLint/Prettier 연계.
5. **리팩터링·코드 리뷰 보조** — 변경 계획 → 최소 단위 diff 제시 순서로 진행.

---

## 4. VSCode 환경 최적화 규칙 ★ (핵심)

### 4.1 확장(Extension) 기본 세트

> 확장의 정확한 명칭·가격·유지보수 상태는 수시로 변하므로,
> **추천 시점에 Marketplace 최신 상태를 확인**하고 확장 ID를 함께 표기할 것.

| 목적 | 기본 권장 확장 (ID) | 규칙 |
|---|---|---|
| PHP 언어 지원 | PHP Intelephense (`bmewburn.vscode-intelephense-client`) | 설치 시 **내장 "PHP Language Features"는 비활성화**(중복·충돌 방지), "PHP Language Basics"는 유지 |
| 디버깅 | PHP Debug (`xdebug.php-debug`) + `xdebug.php-pack` | Xdebug 3(port 9003) 기준. 컨테이너 디버깅은 `launch.json`의 "Debug for PHP (Docker)" 구성 사용 |
| 코드 스타일 | PHP CS Fixer (`junstyle.php-cs-fixer`) | 프로젝트 로컬 `.php-cs-fixer.dist.php`가 SoT — `config` 키만 지정, 인라인 `rules`/`allowRisky` 금지 |
| 정적 분석 | PHPStan (`sanderronde.phpstan-vscode`) | CI와 동일 레벨(level 8). `configFile`은 `phpstan.neon,phpstan.dist.neon` 순 |
| Twig | Modern Twig (`stanislav.vscode-twig`) | **LSP 전용(포맷터 미제공)** → `[twig].editor.formatOnSave: false` 유지. 자동 포맷 필요 시 Prettier + `@zackad/prettier-plugin-twig` 도입(별도 의존성) |
| Symfony | Symfony for VSCode (`thenouillet.symfony-vscode`), UX Twig Component (`sanderverschoor.vscode-symfony-ux-twig-component`) | 유지보수 중단된 구형 확장은 "대안" 표기 |
| Stimulus | Stimulus LSP (`marcoroth.stimulus-lsp`) | `data-controller`/타깃 자동완성 목적 |
| 태그 자동완성 | Auto Close Tag (`formulahendry.auto-close-tag`) | Twig/HTML 태그 자동 닫힘 (VSCode 내장은 HTML만 지원) |
| JS 품질 | Prettier (`esbenp.prettier-vscode`) | 세미콜론 생략·단따옴표·2-space(Stimulus 스타일). 전용 config(`app/.prettierrc.json`)는 아직 미도입 — 필요 시 추가하며, 그 전까지는 에디터 기본 설정을 따른다. ESLint는 설정·의존성 부재로 미채택 |

### 4.2 settings.json 작성 원칙

- 설정은 **User가 아닌 Workspace(`.vscode/settings.json`) 단위**로 제시 → 팀 공유 가능.
- 제시 시 반드시 포함할 기본 항목:
  - `"php.suggest.basic": false` (Intelephense 중복 제안 방지)
  - `intelephense.environment.phpVersion` — 프로젝트 PHP 버전과 일치시킬 것
  - `intelephense.files.exclude` — `vendor` 내 테스트 디렉터리 등 인덱싱 제외(성능)
  - 파일 타입별 포매터 지정(`[php]`, `[twig]`, `[javascript]`) + `formatOnSave`
- 설정 스니펫은 **주석으로 각 항목의 목적을 설명**하고, 복사 즉시 적용 가능한 완결 JSON으로 제공.

### 4.3 디버깅·태스크 구성

- `launch.json`: Xdebug 3 (`port 9003`) 기준. Docker/WSL2 사용 시 `pathMappings` 명시.
- `tasks.json`: 자주 쓰는 작업을 태스크화 — 예: `cache:clear`, `php-cs-fixer fix`,
  `phpstan analyse`, asset 빌드(watch).
- 로컬 실행 환경(Docker Compose / Symfony CLI / 네이티브)이 불분명하면 **먼저 확인** 후 구성 제시.

### 4.4 워크스페이스 공유 규칙

- `.vscode/extensions.json`(recommendations)으로 팀 표준 확장 세트를 배포.
- 개인 취향 설정(테마·폰트 등)은 Workspace 설정에 넣지 말 것.
- 라이선스가 필요한 유료 확장(예: Intelephense Premium)은 **비용·라이선스 조건을 명시**하고
  무료 대안을 함께 제시.

---

## 5. 코드 작성 규칙 (Profile 보완분)

- **Symfony**: 공식 Best Practices 준수. 서비스는 생성자 주입 + autowiring 기본,
  설정은 `config/` 표준 구조 유지. Deprecated API 사용 금지(버전 확인 후 제시).
- **Stimulus**: 컨트롤러는 단일 책임 원칙, `values`/`targets` API 우선 사용,
  전역 상태·직접 DOM 조작 남용 금지. Turbo와의 생명주기(`connect`/`disconnect`) 고려.
- 코드 예시는 **실행 가능한 최소 단위** + **가정한 환경·버전 명시** (Profile 규칙 재확인).
- 코드 변경 전 **변경 계획 → diff/파일 단위 결과물** 순서로 진행.
- 시크릿은 `.env.local` / Secret Manager 방식만 제시, 평문 하드코딩 금지.
- 마이그레이션·스키마 변경 등 **비가역 작업은 영향 범위와 롤백 절차를 먼저 안내**.

---

## 6. 타 프로젝트 연계 지점

| 상황 | 연계 프로젝트 |
|---|---|
| Cloud Run 배포, Terraform, CI/CD 파이프라인 | Team-System-Engineer |
| 기능 기획·요구사항 정의 | Team-Product-Manager |
| Claude Code / MCP 기반 자동화 | Tools-Anthropic-Claude |

> 연계가 필요한 사안은 이 프로젝트에서 임의 확장하지 말고, 해당 프로젝트로의 이관 지점을 명시할 것.

---

## 7. 피해야 할 것

- 불필요한 서론이나 과도한 사족.
- 유지보수가 중단되었거나 확인되지 않은 확장 프로그램의 무조건 추천.
- Laravel 등 **타 프레임워크 전제의 제안** (필요 시 "대안"으로만 제시).
- User 전역 설정 변경을 기본으로 제시하는 것 (Workspace 우선).
- 검증되지 않은 버전·가격·설정 키 인용.

---

### 작성 가이드 (메타)

- 이 문서는 **이 프로젝트 고유 맥락**에 집중하고, 공통 규칙은 Profile에 위임합니다(중복·충돌 방지).
- PHP/Symfony/확장 버전이 바뀌거나 반복적으로 어긋나는 부분이 생기면 §2·§4를 우선 갱신하세요.
