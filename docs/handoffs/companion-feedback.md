# 동료 플레이 피드백 통합 인계

- 한국 날짜2026-10-22. 최초기준8405b7c1c365ee7388b01a85cb3d09efb8d05a2b, 열린PR없음/로컬수정없음(기존임시docs파일보존). 선행계약PR#16은CI성공 뒤 c860fd5606e99d80a693cc735584da7fb6986a53로병합. 제품은그계약main위통합브랜치다. 문서 내 개발/QA 커밋은 로컬검증시점이며 원격은 제품PRhead/최종main을 확인한다.
- 규모/위험: 조작·성장곡선·저장선택필드·전투시각을포함한중상위험. 기획사전→승인→계약선행→파일소유권별독립준비/개발→총괄공유연결→독립QA/기획사후. 소유 main/진형/저장·공통문서는총괄, 성장=evolution_rules/special_companions, UI=roster/evolution, 시각=special_visual/creature_visual/element_feedback, QA=독립test와증거. 별도worktree/브랜치사용.
- 호출 기획(승인경계/육성·조작·전투가치), 성장(새곡선과기존세이브보존), UI(동종식별·진형조작), 시각(속성/적타격), 독립QA(저장·공통전투경계). 순수캠페인/경제/원화생성/외부조사는범위아님·현소스로원인확인가능해생략. 총괄이main·저장·진형통합및전체검증.
- 승인: 새5성Lv1~60 선형110→130%·기존투자보존, 바람공속10%,최소역할가시화. 실제범위확대/적DPS·빈도/탱커수치상향/새동료·신규콘텐츠는제외. 6성유지. 계약과새표식·다운그레이드제약은SAVE/COMBAT계약,조작은UI계약참조.

## 검증과수정
- Godot4.7.stable.official.5b4e0cb0f import: Parse/SCRIPT ERROR없음. 신규성장146검사PASS. 독립QA최종275검사PASS: 구5성50~60보존/신규선택표식왕복/진형3종저장/실제저장실패불변/동종정확소비/4속성효과반경/7종기본행동/진형방향·벽·도발/최대5옵션두줄. QA원문 companion-feedback-qa.md/json.
- 초기전체회귀에서슬롯교체후동일ID다른슬롯클릭오해제발견→slot+surface+ID판정·성공배치초기화수정→기존roster361검사와독립반복교체PASS. 필터초기화후오해제도수정·독립재검증. 기획에서긴옵션잘림발견→두줄/행간격수정→최대5옵션275검사와새PNG검토PASS.
- 실제GodotUI6PNG: roster/materials/confirm/front/rear/surround. 최대5옵션최종확인포함. 실제전투5초30fps GIF/MP4·디코딩PASS. fixture는사용자load/persist를재정의해격리하고실제제품UI/전투메서드사용. 렌더llvmpipe/Xvfb,화면비율·원화·카메라유지. 기획사후적합(D1~D9)은 design-reviews/companion-feedback.md.
- 전체회귀52/52 PASS(최종UI제품,신규독립QA포함). 최종실행결과: companion-feedback-tests.json. 원격필수CI는제품PR최종head에서별도확인하며실패시병합금지.

## 제한과다음
- 독립QA최종에ObjectDB14개종료경고,기존특수전투12개경고,일부회귀종료경고가남는다. Parse/SCRIPT ERROR와검사실패는없다. GUI의V-Sync미지원경고.
- 사람재미/모바일실기기이중탭/장기5성육성시간/전체전종애니메이션/탱커유무의전략적필요성은미검증. 자동봇성공은사람난이도판정이아니다. 기존탱커역할을보이게한최소안이며탱커필수화나실제범위버프를구현했다고설명하지않는다.
- 다음은최신main갱신후더블탭·진형추종·탱커편성/비편성지원소모·새5성육성시간플레이확인. 추가수치변경은별도합의,심층/입장재화보류.
