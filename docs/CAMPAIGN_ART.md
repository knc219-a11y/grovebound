# 채석장·묘역·새 생물 아트

2026-10-20. imagegen 스킬의 기본 내장 이미지 생성 도구 사용. CLI/API 키 경로는 사용하지 않았다. 참조 이미지는 기존 실제 게임 `docs/stage-pacing-layout.png`이며 스타일/비율 참조이고 편집 대상이 아니다.

최종 자산: `assets/campaign/quarry-v1.webp`, `graveyard-v1.webp`, `bat-v1.png`, `slime-v1.png`, `golem-v1.png`, `skeleton-v1.png`, `wraith-v1.png`, `guardian-v1.png`. 새 인간/주인공 원화는 만들지 않았다. PNG6종은448×104,4셀112×104, 발 기준(56,94). 종별 높이32/30/60/52/50/60px. 기존 캐릭터/카메라 비율을 보존한다.

배경은 생성 결과를 nearest로1450×825→2900×1650에 정규화한 lossless WebP다. 생물 원본은 `assets/campaign/creatures-source-v1.png`에 보존했다. 원본 행 간격이 정확한 등분이 아니므로 읽기 전용 연결 성분 분석으로24몸체+슬라임 발사체1을 확인하고, `tools/pack_campaign_art.gd`의 측정 사각형으로 패킹했다. 행별 동일 축척/공통 기준점을 적용하며 격자 경계로 머리/날개/무기를 자르지 않는다. 패킹 시 약한 반투명 외곽은 이진 알파로 정리했다.

재패킹: Godot headless의 `--script tools/pack_campaign_art.gd -- QUARRY_IMAGE GRAVEYARD_IMAGE CREATURE_SOURCE`에 입력3개를 준다. 현재 배경2개는2px 클러스터로 정규화돼 있어 해당 WebP를 배경 입력으로 다시 사용할 수 있다. 원화를 다시 생성하면 기존 측정 사각형을 맹목적으로 재사용하지 않는다.

## 최종 생성 프롬프트

### 채석장
```text
Use case: stylized-concept. Asset type: actual complete 2D RPG overworld background, wide 16:9 or 1792x1024. Style reference: the recent Grovebound game screenshot; match its crisp restrained olive/brown quarter-view pixel art, small-scale world props, no UI. Generate NEW abandoned quarry map with broad flat walkable ochre dirt and stone ground, sparse olive grass, small gray slate outcrops, scattered little broken wooden cart rails and mining tools. Overhead quarter-view orthographic camera, no horizon, no vanishing point. Continuous open travel corridor across the middle from left to right with four broad unobstructed battle clearings, a quiet little camp niche above center, larger open boss clearing at far right. All main playable ground between 20% and 70% image height must remain traversable, only tiny passable scattered rocks. Low stone quarry edges and rubble confined upper 15% and bottom 22%. Human character would be only 35px tall on this full map: props must be small in that scale, rocks 10-35px, no giant stairs or walls. Sharp visible pixel clusters, limited palette, upper-left daylight, no blur, no fog, no text, no UI, no characters or creatures, no labels, no watermarks. This must be a functional game map background, not a scenic illustration.
```

### 묘역
```text
Use case: stylized-concept. Asset type: actual complete 2D RPG overworld background, wide 16:9 or1792x1024. Style reference recent Grovebound screenshot only for crisp pixel style and tiny prop scale, no UI. Generate NEW forgotten graveyard map in restrained gray-olive, desaturated teal and earth brown. Flat walkable worn dirt path going left-to-right across middle, four unobstructed wide battle clearings, small quiet rest niche above center, open final clearing at far right with distant low crypt ruins along upper boundary. Camera orthographic quarter-view overhead, no horizon or perspective vanishing point. Tiny gravestones 12-25px high in this full map, broken low stone walls only along upper15% and bottom22%, scattered withered grass and small bare shrubs. Main playable band y20%-70% remains open and flat, all apparent props in this band small and passable. Human would be35px tall so no giant structures, staircases or gravestones. Match existing sharp pixel clusters, readable silhouettes, upper-left soft overcast lighting but ground bright enough to read. No bloom, blur or fog, no text, UI, people, monsters, logos or watermark. Functional game map, not cinematic artwork.
```

### 생물4자세 원본 시트
```text
Use case stylized-concept. Asset type: production 2D pixel RPG enemy sprite atlas on genuine transparent background. Exact regular grid FOUR COLUMNS by SIX ROWS, total24 distinct cells; no grid lines and no text. All six species face RIGHT in quarter-side view matching crisp low-resolution 16-bit Grovebound animals (muted olive/earth colors, dark outlines, upper-left light). Every cell same size, subject fully inside central70%, generous transparent padding, consistent baseline near80% cell height. Four columns per species: 1 idle,2 walk step A,3 walk step B visibly different limb positions,4 attack striking forward. Row1: small purple-brown bat with distinct wings and tiny body, wing poses down/open/up/forward swoop. Row2: moss green slime, squat round translucent jelly with two dark eyes, squish and stretch without large scale changes. Row3: small stocky gray stone golem assembled from rugged rocks, amber cracks, two arms and legs. Row4: ivory skeleton soldier with ragged charcoal cloth and short rusty sword, no gore. Row5: muted teal spectral wraith with hood and tattered floating hem, visible spectral hands, no large glow or soft transparency edges. Row6: armored skeletal grave guardian with worn dark iron helmet, bone chest and short broad sword, original design. Keep each species similar size across its own row, no weapons crossing cell edges, no shadows on floor, no props or background, no UI, no labels or decorative elements. Pixel art hard edges, not vector/cartoon/painted. All24 cells precisely aligned in four equal columns and six equal rows. Genuine RGBA transparency.
```

게임에는6종의 독립된4자세 시트를 적용했다. 생성 원본 미리보기와 실제 Godot 실행 영상을 구분한다.
