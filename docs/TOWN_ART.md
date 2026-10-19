# 잎그늘 쉼터 아트 1차
2026-10-19. 기존 사냥터 `assets/maps/greenwater-beginner-v3.webp`를 직접 참조해 내장 이미지 생성 도구로 바닥/건물/소품을 제작했다. 생성 시안만이 아니라 실제 마을 렌더링에 연결했다.

## 적용
- 바닥 `assets/town/leafshade-ground-v1.webp`: 올리브 풀밭, 기존 사냥터와 같은 흙길 가장자리, 작은 나무/수풀/꽃. 별도1800×1100 마을 공간.
- 건물 `cottage-0/1/2-v1.webp`: 동료 쉼터/작은 오두막/보급 오두막 외형. 기능은 기존 동료 관리 지점만 제공. 새 상점/아이템/시설 경제를 추가하지 않았다.
- 소품 `prop-0/1/2-v1.webp`: 작은 모닥불/오른쪽 표지판/통나무 벤치.
- 원본 투명 시트 `cottages-source-v1.webp`, `props-source-v1.webp` 보존. 전경 건물은 분리된 알파 텍스처로 y 정렬하며 기존 충돌 발판과 상호작용 지점 유지. 건물 외형과 충돌은 타일 정밀 폴리곤 일치는 아니며 보수적인 사각 충돌이다.
- `tools/pack_town_art.gd`: 투명 3열 시트의 셀을 나누고 투명 여백 자르기, 표시 크기로 nearest 리사이즈, lossless WebP 색/알파 왕복 검사. 창작 수정이나 업스케일로 새 디테일을 만든 작업이 아니다.
- 캐릭터72px, 기존1440×810 논리 시야, 이동속도/메뉴/세이브/사냥터/성장·수집 규칙 유지.

## 생성 프롬프트 명세
내장 image_gen 사용. 아래는 재제작용 명세이며 생성 결과의 픽셀 단위 재현을 보장하지 않는다.

### 바닥
참조: greenwater-beginner-v3.webp. Production RPG terrain only, landscape18:11 for1800×1100 world, exact crisp pixel clusters/olive meadow/warm tan dirt/dark teal vegetation shadows/small yellow-white flowers/top-left light/three-quarter overhead view. No buildings, characters, UI, text. Broad dirt lane across y=.53; short connected branches at x=.30 up to y=.43, x=.63 up to y=.34, x=.67 down to y=.80; small gathering clearing(.47,.59). Empty building pads x.23-.37/y.18-.42, x.57-.70/y.14-.36, x.61-.74/y.59-.80. Sparse small trees/bushes/pebbles/flowers toward outer edges, quiet center, irregular grass-road transitions. No giant trees/stairs/ruins/water/blur/painterly smoothing/isometric diamond.

### 건물
참조: 같은 사냥터. Transparent production pixel-art sheet,3:1,three equal square cells in one row,isolated cottages,bottom aligned,clear gutters. Companion lodge with mossy dark-green shingles,warm timber,cream infill,dark front door,small window,leaf plaque without text; modest wooden cabin with olive roof/stone base; small supply hut with a pair of crates. Front doors face screen bottom and roughly1/4 building height,72px human beside250px cottage. Three-quarter front orthographic view,broad front wall,narrow right wall,top-left light. Logical128px cell art enlarged nearest,crisp restrained pixel clusters,staggered shingles,moss/ivy,warm wood,dark-green shadows. No ground tile/grass island/people/UI/text/checkerboard/smooth illustration.

### 소품
참조: 위 건물 시트. Transparent production pixel-art3:1 sheet,3equal cells: small dormant campfire ring with gray stones/charred logs/tiny amber embers; right-pointing wooden signboard without text; low split-timber bench on stump legs. Same three-quarter front view/top-left light/olive shadows/warm wood/pixel clusters. Logical64px cell art,nearest pixels. No grass island/background/characters/UI/letters.

## 확인 및 재생성
- 실제 Godot: `docs/town-art-hub.png`, `docs/town-art-flow.gif`/`.mp4`.
- `animation/town_review.tscn`은 사용자 저장 읽기/쓰기를 하지 않는다. `tools/preview.py`로 재캡처.
- Godot 임포트,아트 타입/UI/game_menu/town 회귀 검사. 패킹 시 PNG/WebP 색·알파 왕복 검사 통과.
- 모바일 실기기와 최종 미적 평가는 별도. 기존 코드 도형 초안 캡처는 과거 기록으로 보존하며 현재 적용은 이 문서의 에셋이다.
