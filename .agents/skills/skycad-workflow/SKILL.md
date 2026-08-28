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

1. **와이어 배선 및 분기 방향 설정**:
   * 전원 레일: 우측 라이브러리 `Connections` -> `Power Rails` 배치
   * 결선 연결: 단축키 `C` (Connection) -> 단자점 클릭 후 직각 배선
   * **배선 분기 방향 변경 (T자 / Y자 코너 / 빗금 결선 전환)**:
     - 상단 리본 메뉴 **`Schematic tools`** 탭 ➔ **`Orient connections`** 기능 실행
     - 교차 분기점을 클릭하여 결선 방향(T자형 점 분기 ↔ Y자/사선/코너 방향성 분기)을 즉시 전환
2. **카탈로그 매핑 (Assign Catalogue)**:
   * 배치된 심볼 더블클릭 -> `Catalogue tools` -> `Assign from Catalogue`
   * 실제 제조사(LS Electric, Schneider, Mitsubishi 등) 파트넘버 및 핀 사양 매핑
3. **단자대 지정 (Terminal Strip)**:
   * 중계 단자대 심볼 삽입 후 동일 그룹명(예: `TB1`, `TB_IO`)으로 묶어 관리

---

## 5. BOM 무결성 보장을 위한 부품 블록 설계 표준 원칙 (BOM-First Modeling)

SkyCAD에서 자동 생성되는 BOM의 수량 오차 및 발주 누락(Discrepancy)을 원천 차단하기 위해 다음 모델링 원칙을 준수합니다.

1. **실물 1:1 매핑 원칙 (Single-Pole Modeling)**:
   * 모듈형 전원 분배기(예: 피닉스컨택트 PTFIX 시리즈), 모듈형 단자대 등은 도면 작도 편의를 위해 임의로 다극(Multi-pole)을 하나의 가상 블록으로 통합 생성하지 않습니다.
   * 실제 발주 및 물리적 설치 단위인 **단품(1-Pole) 블록으로 분리 생성**하여, 도면에 배치된 심볼 개수와 BOM 산출 수량이 100% 자동 일치하도록 모델링합니다.
   * *예시: 단상 AC 220V(L/N) 분배 시, 14핀 1개 통합 블록 대신 7핀 단품 블록 2개(`DB_L`, `DB_N`)로 분리 생성.*
2. **극성별 색상 및 주문용 파트넘버 분리 관리**:
   * 동일 시리즈라도 극성에 따른 전용 색상 및 공식 주문 코드(Order No)가 구분되는 경우(예: L상 회색 GY 3273082, N상 청색 BU 3273084, DC 24V 적색/회색, 0V 청색/흑색), 카탈로그에 각각의 파트넘버를 명확히 분리 등록하여 발주 시 혼선을 원천 방지합니다.
3. **단자 정의와 카탈로그 핀 정합성 (DRC 무결점)**:
   * 심볼의 단자 개수/명칭과 카탈로그 부품의 물리적 단자 정의를 1:1로 정확하게 일치시켜, DRC(Design Rule Check) 핀 매핑 오류를 방지합니다.

---

## 6. 서지보호기(SPD) 배치 및 결선 설계 표준 원칙 (IEC 60364-5-53 / KEC)

전기 안전 기준(KS C IEC 60364-5-53, KEC 제218절)에 따른 전장 제어반 내 SPD의 최적 보호 협조 및 결선 규칙입니다.

1. **보호 협조 시퀀스 (노이즈 필터 전단 배치 원칙)**:
   * SPD는 외부 고에너지 서지(낙뢰/스위칭 과전압)를 대지(`PE`)로 가장 먼저 방류해야 하므로, **반드시 노이즈 필터(`FLT`)의 전단(앞단)**에 병렬 배치합니다.
   * *표준 전원 계통 흐름:* `Main Inlet ➔ 메인 MCCB ➔ [SPD 병렬 분기 (1차 서지 방류)] ➔ 노이즈 필터(FLT, 고주파 필터링) ➔ 전원 분배기(DB) ➔ 보조 분기 MCB ➔ 부하`
   * *이유:* 서지가 노이즈 필터를 먼저 통과할 경우 필터 내부 초크 코일 및 커패시터 소손 방지.
2. **총 배선 길이 0.5m (50cm) 이하 준수 (Inductive Voltage Drop 최소화)**:
   * 전원선 분기점 ~ SPD 단자까지의 길이($L_1$) + SPD에서 접지 분배기(`DB_PE`)까지의 길이($L_2$)의 합이 **50cm 이하 ($L_1 + L_2 \le 0.5\,\text{m}$)**가 되도록 분배기 바로 인접 위치에 SPD를 배치합니다.
3. **서지 방류 전선 규격 (KEC 최소 단면적)**:
   * Type 2 (Class II) SPD 기준: L/N 상선 $\ge 4.0\,\text{mm}^2$, PE 접지 방류선 $\ge 6.0\,\text{mm}^2$ 적용.

---

## 7. 조립식 단자대(Modular Terminal Block) 및 점퍼 브릿지(Bridge) 설계 표준

피닉스컨택트 `XT 2,5` / `PT 2,5` 등 조립식 관통 단자대와 플러그인 점퍼 바(`FBS`)를 활용한 DC 전원 분배 단자대 스트립 모델링 표준입니다.

1. **표준 단자 심볼 선택**:
   * 라이브러리 `Terminals` ➔ **`Terminal referencing terminal strip position.`** (원 안에 단자 번호 1, 2, 3... 표기형) 사용.
2. **단자대 스트립 그룹화 (Terminal Strip Grouping)**:
   * 단자를 배치하고 `Terminal Strip` 이름(예: `TB2`)을 지정하여 단일 DIN 레일 스트립으로 자동 통합.
3. **점퍼 브릿지(Bridge / Jumper) 연결 메커니즘**:
   * 단자 심볼들의 상단 또는 하단을 와이어 결선 도구(**`C`** 키)로 가로로 연결하면, SkyCAD 엔진이 자동으로 내부 통전 점퍼(`FBS 5-5`, `FBS 10-5` 등)로 인식하여 단자대 배치도(Layout)와 BOM에 정확히 집계함.
4. **DC 전원 구역별 단자대 색상 표준**:
   * `+24V` 전원 구역: 적색 단자대 (`XT 2,5 RD` / `PT 2,5 RD`)
   * `0V (COM)` 공통 구역: 청색 단자대 (`XT 2,5 BU` / `PT 2,5 BU`)
   * `+12V / 0V12` 구역: 회색 단자대 (`XT 2,5 GY`)

---

## 8. 제어 회로 차단기(MCB) 선정 표준 (Isolator `BKD` vs MCB `BK63HU`)

1. **단로기(`BKD`)와 차단기(`BK63HU`)의 결정적 차이**:
   * **`BKD` (Isolator / 개폐기):** 트립 장치(바이메탈/마그네틱 코일)가 없는 순수 수동 ON/OFF 스위치로, 과부하/단락 시 차단되지 않으므로 제어 부하 보호용으로 단독 사용 불가.
   * **`BK63HU` (Miniature Circuit Breaker):** 과부하(Overload) 및 단락(Short-circuit) 시 0.01초 고속 자동 차단(Thermal-Magnetic Trip) 기능을 내장한 정식 산업용 소형 차단기.
2. **제어 DC 분기 회로의 표준 보호기**:
   * 산업용 PC(IPC), PLC I/O, 센서, 솔레노이드 밸브, 안전릴레이 등 정밀 제어 부하의 분기 보호기에는 반드시 **`BK63HU 1P` (UL 489 인증 10kA 고차단형)** 또는 `BK63N 1P`를 적용함.

---

## 9. IEC 81346 구조화 태깅 시스템 (`=Location+Tag`) 표준

대기업(반도체/배터리/디스플레이) 납품용 도면 및 상용 자동화 설비의 공식 부품 식별 태그 표준입니다.

* **`+` 기호 (Location / 물리적 설치 위치)**:
  * **`+CP` (Control Panel):** 메인 제어반 판넬 내부 (예: `=CP+PS1`, `=CP+MCB1`)
  * **`+OP` (Operator Panel):** 작업자 조작반/터치 콘솔 부 (예: `=OP+ES1`, `=OP+LP1`)
  * **`+MCH` (Machine Frame):** 설비 기구 프레임/챔버 현장 (예: `=MCH+PSN1`, `=MCH+SOL1`)
* **효과:** 유지보수 작업자가 도면만 보고 어느 판넬의 부품인지 1초 만에 식별 가능하며, SkyCAD Location 관리와 100% 자동 연동됨.

---

## 10. 일괄 자동 넘버링 및 보고서 생성

1. **넘버링 실행**:
   * 선번 부여: `Run Wire Renumbering`
   * 부품 태그 정렬: `Run Component Renumbering`
2. **산출물 생성**:
   * BOM 생성: `Create/Add` 탭 -> `Add BOM`
   * 단자대 결선도: `Terminal Strips` -> `Generate Terminal Strip Layout`
   * PDF 내보내기: `Home` 탭 -> `Print/Export` -> `PDF Export`



