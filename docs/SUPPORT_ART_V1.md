# 사슴 회복·거북 방어 전용 원화

- 기존 `assets/party-pixel/deer.png`, `turtle.png`를 직접 참조해 built-in image generation으로 종별3포즈를 제작했다. 원본 `assets/attacks-v2/deer-turtle-source-v1.png`, 실행 시트 `deer.png`, `turtle.png`. 기존 대기2칸과 새 준비/발동/회수 자세를 조합한6셀, 발동2칸 유지.
- 프롬프트: 1536×1024 transparent3columns×2rows atlas; right-facing3/4side view, reference-identical muted pixel palette, no text/grid/VFX/background/shadows. Deer: lower head→raise head/antlers with planted feet→settle. Preserve four slender legs and body proportions. Turtle: retract neck/feet→low brace with rigid undistorted shell and planted feet→extend neck/feet toward neutral. Keep baseline/size stable.
- 생성 시트의 긴 사슴 다리가 명목상 중간 경계를 넘어 실제 빈 여백을 찾아 행·열을 자른다. `tools/pack_attack_art.gd -- res://assets/attacks-v2/deer-turtle-source-v1.png deer turtle`. nearest축소/알파 이진화/발 기준 정렬, 사슴64px/거북32px 최대높이. 다른4종 패킹의 기존 기본 격자는 보존한다.
- 회복과 방패는 기존 즉시 적용 시점을 유지하므로 실행은 발동 포즈부터0.6초 표시한다. 사슴 일반 회복과 광역 스킬이 같은 몸동작을 사용하고 광역은 기존 스킬 이름·이중 파동·회복빛으로 구분한다. 거북은 방패가 남아 있고 정지하면 버티기 자세를 유지하며 이동 중에는 기존 보행을 우선한다. 일반 공격 포즈와 카메라는 유지한다.
- 회복량/사거리/방패 지속5초/피해 경감/도발/쿨다운/세이브 형식은 변경하지 않는다. 별도 회복 준비 시간을 추가하지 않았다.
- 실제 재현 `animation/support_art_review.tscn`, `docs/support-art-gameplay.png`, `.gif`/`.mp4`; 제작 판독용 `support-art-detail.gif`/`.mp4`. 사용자 저장과 격리.
- `tools/test_action_events.gd`에 지원 원화 선택/이동 우선/정지 방패 유지/효과 종료/셀 경계·종별 높이 검증 추가. `test_skill_visual.gd`의 기존 회복/경감/쿨다운 규칙도 유지. 사용자 미적 평가/모바일 실기기 성능은 미검증이다.
