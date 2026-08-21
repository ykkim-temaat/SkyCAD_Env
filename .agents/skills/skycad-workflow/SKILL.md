---
name: skycad-workflow
description: >-
  SkyCAD를 사용한 전기 전장도면 설계, 환경 구성, 프로젝트 생성, 심볼 및 카탈로그 부품 등록,
  배선 및 넘버링, BOM 및 단자대 보고서 생성 등의 전장제어 표준 워크플로우 가이드.
---

# SkyCAD 전기 도면 설계 표준 워크플로우

이 스킬은 SkyCAD를 이용한 전기 전장 설계 시 환경 설정부터 납품용 도면 및 BOM 생성까지의 표준 작업 절차를 정의합니다.

---

## 1. 환경 설정 및 초기화 (Environment Setup)

### 1.1 환경 경로 설정
* **설정 경로**: `SkyCAD Explorer` -> `Current Environments Path`
* **지정 값**: `c:\Workspaces\study\SkyCAD_Env` (반드시 `Standard Environment`의 상위 폴더 지정)
* **이유**: SkyCAD가 하위의 `Standard Environment` 및 커스텀 환경 폴더들을 자동으로 탐색/로드할 수 있도록 부모 디렉토리를 지정해야 함.

### 1.2 표준 라이브러리 및 규격
* **도면 표준**: IEC (Metric mm)
* **심볼 라이브러리**: `IEC Symbol Library` 사용

---

## 2. 프로젝트 생성 및 관리 (Project Workflow)

1. **새 프로젝트 생성**:
   * 상단 메뉴: `Create/Add` 탭 -> `New Project`
   * 프로젝트 이름 입력 (예: `ProjectName_Rev0`)
2. **프로젝트 저장 (`Save As`)**:
   * 좌측 트리에서 프로젝트 선택 -> `Home` 탭 -> `Save As`
   * 관리 대상 프로젝트 폴더에 `.SkyCadFile` 형식으로 저장
3. **프로젝트 속성 입력 (Title Block)**:
   * 좌측 트리에서 프로젝트 더블클릭 -> `Description`, `Drawn By`, `Drawing Number`, `Date` 입력

---

## 3. 도면 시트 구성 표준 (Sheet Structure)

| 시트 번호 | 시트 명칭 | 주요 포함 내용 |
| :--- | :--- | :--- |
| **Page 01** | 표지 및 목차 (Cover & Index) | 프로젝트명, 개정 이력, 시트 인덱스 |
| **Page 02** | 주전원 계통도 (Main AC Power) | AC 3상 인입, 메인 MCCB, 노이즈 필터, 트랜스 |
| **Page 03** | 제어 전원 분배 (Control DC Power) | SMPS(DC 24V), MCB/Fuse, 접지(PE/FG) |
| **Page 04** | 안전 회로 (Safety Circuit) | E-Stop 비상정지, 안전 릴레이, 안전 도어 인터록 |
| **Page 05~08** | PLC CPU 및 I/O 회로 | PLC 전원, DI(센서), DO(릴레이/솔밸브), AI/AO 모듈 |
| **Page 09~11** | 모터 및 드라이브 회로 | 서보 드라이브, 인버터(VFD), 스텝 모터 배선 |
| **Page 12~** | 단자대 및 BOM | 단자대 결선도(TB Layout), 부품 목록표(BOM) |

---

## 4. 회로도 작성 및 카탈로그 부품 매핑

1. **와이어 배선**:
   * 전원 레일: 우측 라이브러리 `Connections` -> `Power Rails` 배치
   * 결선 연결: 단축키 `C` (Connection) -> 단자점 클릭 후 직각 배선
2. **카탈로그 매핑 (Assign Catalogue)**:
   * 배치된 심볼 더블클릭 -> `Catalogue tools` -> `Assign from Catalogue`
   * 실제 제조사(LS Electric, Schneider, Mitsubishi 등) 파트넘버 및 핀 사양 매핑
3. **단자대 지정 (Terminal Strip)**:
   * 중계 단자대 심볼 삽입 후 동일 그룹명(예: `TB1`, `TB_IO`)으로 묶어 관리

---

## 5. 일괄 자동 넘버링 및 보고서 생성

1. **넘버링 실행**:
   * 선번 부여: `Run Wire Renumbering`
   * 부품 태그 정렬: `Run Component Renumbering`
2. **산출물 생성**:
   * BOM 생성: `Create/Add` 탭 -> `Add BOM`
   * 단자대 결선도: `Terminal Strips` -> `Generate Terminal Strip Layout`
   * PDF 내보내기: `Home` 탭 -> `Print/Export` -> `PDF Export`
