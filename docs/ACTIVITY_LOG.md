# SkyCAD 전장설계 프로젝트 작업 이력 (Activity Log)

이 문서는 프로젝트 진행 과정에서 수행한 주요 작업, 환경 설정, 회로 설계 및 변경 사항을 시간순으로 기록하는 이력 관리 파일입니다. 나중에 작업을 재개하더라도 이전 진행 상황을 즉시 파악할 수 있도록 항상 누적 업데이트합니다.

---

## 📅 작업 이력 (Chronological History)

### [2026-08-22]
* **[07:20] SkyCAD 전장제어 전문 가이드 체계 정의**
  * SkyCAD 기반 전장 회로 설계, 라이브러리 표준화, 보고서(BOM/단자대) 자동화 및 안전 규격(IEC 60204-1) 가이드 영역 수립.
* **[07:43] SkyCAD 환경 경로 설정 검증**
  * `SkyCAD Explorer`의 `Current Environments Path`는 `Standard Environment`의 상위 부모 폴더인 `C:\Workspaces\study\SkyCAD_Env`로 지정해야 함을 확인 및 설정 완료.
* **[07:46] AI 규칙 및 스킬 구조 수립**
  * `.agents/rules/skycad-guidelines.md`: 자동 로드되는 전역 설계 및 환경 설정 규칙 정의.
  * `.agents/skills/skycad-workflow/SKILL.md`: SkyCAD 표준 전장설계 워크플로우 가이드 스킬 생성.
* **[07:53] 지식 문서 보관소 구축**
  * `docs/` 디렉터리 생성 및 네이밍 규칙(`YYMMDD-NN_파일이름.md`) 정의.
  * 초기 설정 문서 `docs/260822-01_SkyCAD_환경설정_및_초기작업가이드.md` 작성.
* **[07:56] 작업 이력 관리 체계(`ACTIVITY_LOG.md`) 구축**
  * 불필요한 `README.md` 정리 및 규칙 파일에 '작업 이력 누적 관리' 의무화 규칙 반영.
* **[07:59] IEC 표준 장치 태그 및 접두사 표준 명명 규칙 정립**
  * IEC 81346-1/2 및 IEC 60204-1 기준 장치 태그 분류 체계 수립 및 문서(`docs/260822-02_IEC_장치태그_및_접두사_표준명명규칙.md`) 작성.
* **[08:03] 전장설계, BOM 및 케이블 스케줄 산업 표준 설계 규칙 수립**
  * IEC 60204-1 배선 색상 표준, 강전/약전 분리, 단자대 중계 원칙, BOM 서브파트 관리 및 쉴드선 접지 규칙 문서(`docs/260822-03_전장설계_BOM_케이블_산업표준_설계규칙.md`) 작성.


### [2026-10-31]
* **[11:50] 워크스페이스 이전 및 원격 저장소 클론**
  * `git@github.com:ykkim-temaat/SkyCAD_Env.git` 저장소를 `C:\Workspaces\SkyCAD` 루트 디렉토리에 클론 및 SSH 인증 설정 완료.
* **[12:00] SkyCAD 환경 경로(Current Environments Path) 기준 업데이트**
  * `.agents/rules/skycad-guidelines.md`, `.agents/skills/skycad-workflow/SKILL.md`, `docs/260822-01_SkyCAD_환경설정_및_초기작업가이드.md` 내 환경 경로를 `C:\Workspaces\SkyCAD`로 갱신.

### [2026-11-06]
* **[09:19] NAS 원격 저장소(`nas`) 등록 및 단방향 강제 미러링/미연결 예외 처리 구성**
  * 네트워크 드라이브 경로 `Y:\3. 전장설계\SkyCAD_Library`를 `nas` 리모트로 등록하고, Git `safe.directory` 예외 등록 및 NAS 저장소 `receive.denyCurrentBranch=updateInstead` 설정 적용.
  * 정기 자동 동기화 스크립트(`scripts/auto-git-sync.ps1`) 및 가이드라인(`.agents/rules/skycad-guidelines.md`) 업데이트:
    1. NAS 미연결 시(`Test-Path` False) 오류 없이 건너뛰고 다음 연결 시 자동 동기화.
    2. NAS 내 임의 변경 사항은 무시/초기화(`reset --hard`, `clean -fd`)하고 `git push --force nas main`으로 항상 `origin`과 100% 동일하게 유지(백업 및 공유 전용).
    3. 타 개발자가 `origin`에 푸시한 내역을 로컬로 Pull 받은 경우에도 로컬 `HEAD`와 NAS `HEAD`를 비교하여 NAS까지 자동 반영되도록 구성.
