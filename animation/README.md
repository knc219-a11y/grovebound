# 멧돼지 관절 애니메이션

캡처 프로그램이나 매 동작별 이미지 재생성 없이, 부위 원화 한 장을 재사용합니다.
`boar_rig.gd`는 몸통·머리·네 다리·꼬리를 겹쳐 그립니다. 기존 `boar.png`는 메뉴 아이콘용으로 보존합니다.

- 실제 이동 거리로 발걸음 위상을 진행하고, 정지할 때 보행 가중치를 부드럽게 줄입니다.
- 대기는 호흡, 이동은 대각 다리 교차, 공격은 머리 들이받기, 공격 예고는 고개 숙이기입니다.
- 피격 색상/짧은 반응, 쓰러짐/소생, 좌우 반전을 지원합니다.
- 일반/아군/우두머리 멧돼지에 적용됩니다. 다른 종은 기존 방식입니다.
- 공격 판정과 피해 발생 시점은 기존 게임 로직을 유지합니다. 현재 짧은 공격 포즈는 피해 발생 직후 시작하는 피드백입니다. 긴 선행동작으로 변경하려면 전투 판정도 별도로 조정해야 합니다.
- 발 접지를 정밀하게 푸는 IK나 손으로 그린 프레임 방식은 아닙니다. 우선 동작과 외형을 검토할 수 있는 첫 관절 버전입니다.

Godot에서 `boar_preview.tscn`을 열고 F6으로 6가지 동작을 비교할 수 있습니다.
실제 게임은 평소처럼 `play.bat`으로 실행합니다.

## 원화

내장 이미지 생성 도구로 `assets/boar.png`를 참조해 `assets/boar-parts.png`를 새로 만들었습니다. 투명도는 원본 그대로 사용하며, 부위의 실제 픽셀 영역을 Godot에서 참조합니다. 정해진 격자 경계는 사용하지 않습니다.

사용 프롬프트: "Create a production 2D cutout animation parts atlas for the reference cute brown wild boar, same painted cartoon style, simple early-game beast, cream tusks, pink snout, dark brown outlines. Transparent background, facing right. Isolated torso, head, near front/hind legs, far front/hind legs, tail and optional forelock. No text, grid lines, ground or shadows. Rounded upper leg joints concealed by the torso; consistent identity and palette."

## 이음새 개선 v2

`boar-body-connected.png`는 목과 몸통을 이어 그린 상체 원화입니다. 동일한 삼각형 메시의 연속 가중치로 목을 휘게 하며, 다리 네 개의 윗부분은 이 상체 뒤에 숨깁니다. 머리를 별도 절단면으로 회전하던 v1은 `boar_rig_before.gd`에 비교용으로 남깁니다.

`boar_comparison.tscn`은 같은 속도와 크기로 v1/v2를 함께 보여줍니다. 원화도 수정했으므로 이 비교는 동일 원화에서 메시 기술만 비교하는 실험은 아닙니다. 메시를 그릴 때는 실제 렌더가 끝날 때까지 리소스 참조를 유지합니다.

내장 이미지 생성 도구 사용. 추가 프롬프트: "Make one connected upper-body game sprite of this exact cute brown wild boar, matching atlas identity, colors, outline and shading. Assemble torso and head seamlessly, no neck cut line or shoulder seam, head facing right. Remove all four legs completely, smooth furry belly at hip level, include attached tail. Separate legs will be placed behind the belly. Transparent background, no floor, no shadow or text."
