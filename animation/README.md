# 멧돼지 애니메이션

## 현재 방식: 승인된 전체 원화의 연속 메시 변형

`boar_rig.gd`는 `assets/boar-stance-proposal.png` 한 장을 사용합니다. 사용자가 가장 자연스럽다고 평가한 정지 자세의 비율과 몸통/다리 연결을 그대로 유지합니다. 부위 이미지를 별도로 겹쳐 그리지 않습니다.

- 32×24 격자의 원래 정점·UV·다리 가중치는 초기화 시 준비합니다.
- 다리 뿌리는 거의 고정하고 발 쪽으로 갈수록 작은 수평 이동과 들어 올리기를 적용합니다.
- 네 다리의 위상을 달리하고, 64% 지지/36% 복귀 구간으로 움직입니다.
- 실제 이동 거리로 위상을 진행합니다. 정지 시 가중치를 줄여 승인된 정지 자세로 복귀합니다.
- 호흡은 상체에만 작게 적용해 발 전체가 위아래로 흔들리지 않게 합니다.
- 머리는 같은 메시 안에서 연속 가중치로 움직입니다. 좌우 반전, 공격 반응, 공격 예고, 쓰러짐/소생을 유지합니다.
- 렌더가 지연 실행되므로 액터가 현재 메시 참조를 유지합니다.

정밀한 지면 고정 IK는 아닙니다. 빠른 이동에서는 발 미끄러짐이 남을 수 있습니다. 별도 공격 원화와 다른 종의 개선은 아직 없습니다. 모바일 기기의 성능 검증도 별도 과제입니다.

## 검토와 반복 출력

- `boar_walk_review.tscn`: 승인된 정지 자세 / 작은 보폭 / 좌우 반전 / 정지 전환.
- `boar_preview.tscn`: 대기, 이동, 공격, 돌진 준비, 피격, 쓰러짐/소생.
- `boar_stance_review.tscn`: 이전 다리 조립과 승인된 정지 원화 비교.
- `boar_comparison.tscn`: 초기 분리 부위 버전과 현재 버전 비교.
- 출력: `docs/boar-small-step.gif`, `docs/boar-small-step.mp4`.
- `tools/preview.py`: 임포트 → 장면 녹화 → 오류 검사 → GIF/MP4 또는 PNG 출력. 사용법은 `tools/README.md`.

회귀 검사는 정지 자세 정점 일치, 12개 보행 위상에서 메시 삼각형 뒤집힘 없음, 거리 기반 위상, 정지 전환, 쓰러짐/소생 복귀를 확인합니다.

## 이전 버전과 원화 기록

- v1 `boar_rig_before.gd`: 부위별 컷아웃. 목/어깨 절단선이 부자연스럽다는 피드백.
- v2 `boar_rig_v2.gd`: 연결 상체 + 분리 다리. 머리는 개선됐지만 다리의 비율과 붙는 위치가 부자연스럽다는 피드백.
- v3 `boar_rig.gd`: 승인된 전체 정지 원화 재사용. 추가 이미지 생성 없이 코드로 보행 적용.
- 기존 `assets/boar.png`는 메뉴 아이콘으로 보존.

원화는 내장 이미지 생성 도구로 만들었습니다. 요약 프롬프트:

1. `boar-parts.png`: "A transparent right-facing cutout atlas matching the cute brown wild boar: isolated torso, head, near/far fore and hind legs, tail, optional forelock. Consistent palette and painted cartoon outlines, no ground, text or grid."
2. `boar-body-connected.png`: "Assemble matching torso and head seamlessly into one upper-body silhouette. No neck cut or shoulder seam; remove all legs and retain attached tail. Transparent background."
3. `boar-stance-proposal.png`: "Preserve face and connected upper body, add four short stout legs in a stable neutral standing pose. Straight forelegs under shoulders; hind thighs integrated into rump, compact knees/hocks, flat cloven hooves on a consistent perspective ground plane. No pasted seams, detached lobes, long arms or dangling feet. Transparent background."
