# Grovebound 작업 인계

## 프로젝트
- 저장소: https://github.com/knc219-a11y/grovebound
- 엔진: Godot 4.7 Standard, 모바일 가로 화면 목표.
- 실행: Windows `update-and-play.bat`으로 업데이트와 실행. 첫 실행은 `play.bat`.
- 기획 기준: `DESIGN.md`, 기능/실행 안내: `README.md`, 검사 범위: `QA.md`.

## 합의된 핵심
- 주인공은 지원 역할. 동료 몬스터 4마리와 전투, 총 6마리를 데려가며 비전투 중 교체.
- 자동 전투에 주인공 이동·회복·강화·소생과 동료 스킬 개입.
- 중복 편성 허용, 포획 개체마다 고정 특성 하나. 남는 개체는 방생 재료로 활용.
- 드루이드/동물부터 검증. 마물 조련사·네크로맨서 및 진화·알은 후순위.
- 스테이지 방식. 초반은 단순한 동물, 화려한 기존 콘셉트는 후반 획득 대상으로 보관.

## 현재 작업: 멧돼지 애니메이션
- v1: 부위별 컷아웃 회전. 사용자가 목·어깨 이음새가 어색하다고 피드백.
- v2: 연결된 몸통/머리 원화 + 연속 메시 변형, 다리 뿌리는 몸통 뒤로 숨김.
- 구현: `animation/boar_rig.gd`, 이전 비교용: `animation/boar_rig_before.gd`.
- 비교 장면: `animation/boar_comparison.tscn`. 다양한 동작 확인: `animation/boar_preview.tscn`.
- GIF/영상: `docs/boar-seam-comparison.gif`, `docs/boar-seam-comparison.mp4`.
- v2 피드백: 머리는 개선됐지만 앞/뒷다리가 정지 화면에서도 부자연스럽다는 지적.
- 새 기준 원화 `assets/boar-stance-proposal.png`: 네 다리가 몸통에서 이어지는 정지 자세. 사용자가 가장 자연스럽다고 평가해 기본 자세로 채택.
- 정지 전후 비교: `animation/boar_stance_review.tscn`, `docs/boar-stance-review.png`. 이전 다리 조립 버전은 `boar_rig_v2.gd`로 고정해 비교를 보존함.
- v3: 승인된 전체 원화 한 장을 연속 메시로 변형하는 작은 보폭의 걷기를 실제 게임의 아군/적/우두머리 멧돼지에 연결. 분리 다리 그림을 겹쳐 그리지 않음.
- 검토 장면/녹화: `animation/boar_walk_review.tscn`, `docs/boar-small-step.gif`, `docs/boar-small-step.mp4`. 대기 → 오른쪽 걷기 → 정지 → 왼쪽 걷기.
- 검사: 영 가중치에서 승인된 기본 자세와 정점 일치, 12개 보행 위상에서 삼각형 뒤집힘 없음, 기존 기능 회귀 검사 통과. 녹화 도구는 렌더 오류와 MP4 디코딩 오류도 확인함.
- v3 피드백: 너무 살금살금 걷는 느낌. 사용자가 추가 생성 비용을 감수하고 프레임 원화 방식의 실험을 승인.
- v4: `assets/boar-walk-sheet.png` 걷기 8프레임을 생성, `animation/boar_walk_frames.json`으로 영역/바닥 정렬. 실제 보행은 `boar_rig.gd`에서 원화 프레임을 재생하고 대기/공격/쓰러짐은 기존 연결 메시를 유지.
- 이전 v3는 `boar_rig_v3.gd`에 보존. 비교 장면 `boar_walk_frames_review.tscn`, GIF/MP4 `docs/boar-walk-frames.*`.
- 사용자가 3D 애니메이션을 먼저 만들고 2D 프레임으로 출력하는 제작 방식의 시험을 승인.
- `experiments/boar3d/`: 절차적 3D 기본 모델 + 두 링크 다리 IK + 투명 16프레임 자동 출력. 본편 멧돼지 렌더러는 아직 v4 원화 프레임 방식.
- 비교: `experiments/boar3d/review.tscn`, `docs/boar3d-comparison.gif` / `.mp4`. 기존 2D 원화 / 실시간 3D / 3D 출력 2D 프레임을 같은 주기로 재생.
- 3D 외형은 움직임 검토용 기본 도형 모델이며 최종 그림체를 재현한 버전이 아님. `test_kinematics.gd`에서 발 지지 중 월드 위치 고정·뼈 길이·루프·투명 시트를 검사.
- 다음 작업: 3D 출력 방식과 v4 원화 프레임 보행에 대한 사용자 피드백. 기존 분리 다리를 그대로 재조립하는 방식으로 되돌리지 않기. 다른 동물로 확장하기 전에 보행을 확인받을 것.
- 공격 판정은 그대로 유지. 별도 공격 원화, 정밀 발 접지 IK, 다른 종 개선은 아직 구현하지 않음.

## 작업 방식
- 구현 후 의미 있는 기능 검사와 실제 Godot 화면 녹화로 확인.
- 움직임/전투 연출 수정은 짧은 GIF 미리보기와 MP4 링크를 함께 제공. MP4 인라인 재생은 사용자 앱에서 표시가 불안정했음.
- 정확한 토큰 소비량을 확인할 수 없으므로 녹화/생성 비용을 0이라고 단정하지 않음.
- 같은 파일을 여러 대화에서 동시에 수정하지 않기.
- 사용자가 요청한 원칙: 반복 작업을 프로그램으로 처리하는 편이 효율적이면 직접 도구를 만들어 재사용. 현재 `tools/preview.py`가 장면 실행·오류 확인·GIF/MP4/PNG 출력을 처리하고, `tools/inspect_sprite_sheet.gd`가 격자 또는 연결된 윤곽을 분석해 프레임 영역과 정렬 메타데이터를 생성함. 일회성 작업까지 불필요한 도구로 만들지는 않음.
- 작업이 끝날 때 이 문서에 변경점·검증 결과·남은 일 업데이트. 새 대화에서는 이 문서와 실제 최신 코드를 먼저 읽기.

## 이어갈 때 사용할 요청
"https://github.com/knc219-a11y/grovebound 의 STATUS.md와 관련 코드를 읽고 이어서 진행해줘. 현재 작업은 멧돼지 애니메이션 개선이며, 비교 영상 피드백을 반영하자."
