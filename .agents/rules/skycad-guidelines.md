# SkyCAD 전기 도면 설계 프로젝트 규칙 (Workspace Guidelines)

## 1. 기본 작업 원칙
- **언어**: 모든 생각 과정, 작업 보고, 설명은 **한국어**로 작성합니다.
- **역할**: 전장제어 및 전기 CAD(SkyCAD) 전문가로서 실무 표준(IEC 60204-1, KS, 산업 안전 규격)에 맞춘 신뢰도 높은 설계를 가이드합니다.

## 2. SkyCAD 환경 설정 및 경로 관리 규칙 (중요)
- **Current Environments Path**: 
  - SkyCAD의 환경 경로(`Current Environments Path`)는 `Standard Environment` 폴더 자체가 아니라, **그 상위 부모 폴더**인 `C:\Workspaces\SkyCAD`로 항상 지정해야 합니다.
  - 이를 통해 `Standard Environment`, 커스텀 라이브러리, 카탈로그가 정상 로드됩니다.
- **버전 관리**:
  - `.SkyCadFile` 및 카탈로그 변경 내역은 항상 Git 버전 관리를 고려하여 정리합니다.

## 3. 전장 설계 표준 프로세스
1. **환경 로드**: `Current Environments Path` 확인 및 `IEC Symbol Library` 활성화
2. **시트 구성 표준**:
   - Cover & Index -> Main Power (AC 3상/단상) -> Control Power (SMPS DC 24V) -> Safety Circuit -> PLC I/O -> Drive/Motor -> Terminal Strip -> BOM
3. **카탈로그 매핑**:
   - 배치된 모든 심볼에는 실제 제조사 모델(LS Electric, Schneider, Mitsubishi 등)을 `Catalogue Tools -> Assign from Catalogue`로 매핑
4. **일괄 재정렬**:
   - 도면 완료 후 `Run Wire Renumbering`, `Run Component Renumbering` 필수 수행
5. **보고서 자동 생성**:
   - `Add BOM` 및 `Generate Terminal Strip Layout`으로 최종 산출물 완성

## 4. 문서 저장 및 기억 규칙 (Docs Directory)
- **저장 위치**: 프로젝트 루트의 `docs/` 디렉터리를 활용합니다.
- **문서 네이밍 규칙**: 사용자의 저장 요청 또는 영구 기억이 필요한 문서는 반드시 다음 형식을 준수합니다:
  - **`YYMMDD-NN_파일이름.md`** (예: `260822-01_SkyCAD_환경설정_및_초기작업가이드.md`)
  - `YYMMDD`: 연월일 6자리
  - `NN`: 당일 순번 2자리 (`01`, `02`, ...)
  - `파일이름`: 문서의 내용을 명확히 나타내는 이름

## 5. 작업 이력 관리 규칙 (Activity Log)
- **이력 파일**: [`docs/ACTIVITY_LOG.md`](file:///C:/Workspaces/SkyCAD/docs/ACTIVITY_LOG.md)에 주요 작업 내용, 설계 변경 사항, 환경 설정 내역을 시간순으로 누적 기록합니다.
- **기록 시점**: 새로운 작업 세션이 시작되거나 주요 설계/설정 작업이 완료될 때마다 이력을 업데이트하여 언제든지 이전 작업 내용을 이어받을 수 있도록 합니다.

## 6. 스킬 및 추가 지식 참조
- 상세 작업 절차와 노하우는 [SkyCAD 전장설계 스킬](file:///C:/Workspaces/SkyCAD/.agents/skills/skycad-workflow/SKILL.md)을 참조하여 점진적으로 로드 및 업데이트합니다.

## 7. 정기 자동 커밋 및 푸시 규칙 (Daily Auto Commit & Push)
- **실행 주기**: 매일 오전 9시 (`0 9 * * *`) 스케줄 트리거 시 수행합니다.
- **백그라운드 자동화 (Windows 작업 스케줄러)**:
  - Antigravity가 실행 중이지 않을 때도 동작하도록 Windows 작업 스케줄러에 **`SkyCAD_Daily_Git_Sync`** 작업이 등록되어 있습니다.
  - 실행 스크립트: [`scripts/auto-git-sync.ps1`](file:///C:/Workspaces/SkyCAD/scripts/auto-git-sync.ps1) (실행 로그: `scripts/auto-git-sync.log`, `.gitignore`에 의해 버전 관리 제외)
  - 이메일 알림 설정 스크립트: [`scripts/setup-email-config.ps1`](file:///C:/Workspaces/SkyCAD/scripts/setup-email-config.ps1) (DPAPI 암호화 설정 파일: `scripts/email-config.xml`, `.gitignore` 제외)
- **수행 절차**:
  1. `git fetch origin main`을 실행하여 원격 저장소(`origin/main`)의 최신 커밋 상태를 먼저 확인합니다.
  2. 원격 저장소에 로컬보다 앞선 커밋이 존재하는 경우:
     - 로컬 변경 사항이 없다면 즉시 `git pull --ff-only origin main`으로 로컬을 최신화합니다.
     - 로컬 변경 사항이 있다면 먼저 스테이징 및 커밋한 뒤 `git pull --rebase origin main`(동일 파일 충돌 시 원격 저장소 내용을 우선 반영하거나 안전하게 병합)으로 원격 저장소의 최신 내용을 반영합니다.
  3. 로컬 작업 트리의 변경 사항(`git status`)이 있는 경우, 추가/수정된 카탈로그 부품, 심볼, 도면, 문서 내역을 파악하여 프로젝트 커밋 컨벤션(`feat(skycad): ...`, `docs: ...`, `chore(skycad): ...`)에 맞는 명확한 한국어 커밋 메시지로 스테이징(`git add -A`) 및 커밋(`git commit`)합니다.
  4. 변경 사항 및 원격 동기화 내역이 모두 없다면 빈 커밋을 만들지 않고 대기하며, 새로운 로컬 커밋이 있는 경우 원격 저장소(`origin main`)로 푸시(`git push origin main`)하고 결과를 요약 보고합니다.
  5. **NAS 원격 저장소(`nas`) 단방향 미러링 및 예외 처리**:
     - NAS(`Y:\3. 전장설계\SkyCAD_Library`)는 **백업 및 타 엔지니어 조회/공유 전용(Read-Only Mirror)**으로만 운영하며, 단일 진실 공급원(SSOT)은 항상 `origin`(GitHub)입니다.
     - 푸시 전 반드시 `Test-Path "Y:\3. 전장설계\SkyCAD_Library"`로 NAS 네트워크 드라이브 연결 여부를 먼저 확인합니다.
     - **NAS가 연결되어 있는 경우**:
       - NAS 내부에 누군가 임의로 수정한 변경 사항(`git status --porcelain`)이나 커밋이 있더라도 이를 **무시하고 강제 초기화**(`git reset --hard`, `git clean -fd`)합니다.
       - 로컬이 `origin/main`과 동기화(Pull & Push)된 직후의 최종 `HEAD`와 NAS의 `HEAD`를 비교하여, 차이가 있으면(타 개발자가 `origin`에 올린 커밋을 로컬이 Pull 받은 경우 및 이전 미연결 기간 동안 밀린 커밋 포함) `git push --force nas main`으로 강제 푸시하여 `origin`과 100% 동일하게 유지합니다.
     - **NAS가 연결되지 않은 경우**: 에러로 중단하지 않고 `"NAS 서버 미연결 (건너뜀)"`으로 처리한 뒤, 추후 NAS가 연결된 시점에 일괄 동기화합니다.
