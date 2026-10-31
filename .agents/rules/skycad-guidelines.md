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


