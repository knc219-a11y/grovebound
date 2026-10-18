# Slate and bronze UI v1

The shared theme in `ui/grove_ui.gd` uses dark slate, restrained bronze borders, square corners, warm paper text and muted role colors. It applies to combat HUD, camp, roster, starters and confirmation/results panels. Portrait textures use nearest filtering; text retains the existing Korean font.

Combat HUD now has separate player/boss health bars, a compact stage header, larger 148x112 companion skill cards with portraits/HP/cooldown/down states, and 160x112 heal/buff controls with simple native symbols. The interaction control is 300x80 with a separate revive progress bar. Main skill/control rectangles do not overlap. The joystick keeps its original input center/range while using a faceted visual. Top menu buttons are taller than before.

Camp groups inventory/resources/progress and the druid portrait, with distinct departure, companion-management and new-journey actions. New journey still opens the existing confirmation. The roster uses portraits and two-line identity/role/trait labels, taller rows and scrolling for reserve animals. Empty slots and empty ownership lists have explicit messages. The gameplay data, skill costs, save format and key/touch callbacks are retained.

Reusable components: `companion_card.gd` draws the live party state; `support_button.gd` draws heal/buff state. Progress bars set a small font override and their final size after joining the theme tree, preventing the hidden percentage font minimum from expanding the bar.

Review scenes: `ui_hud_review.tscn` shows cooldown, low HP and a downed ally; `ui_camp_review.tscn` and `ui_roster_review.tscn` use isolated preview data with six animals. Actual animated combat uses `full_gameplay_preview.tscn`. All review scenes disable player-save reading/writing through the existing preview base.

Validation: Godot 4.7 import, HUD values/states, thin bar bounds, main control minimum sizes/non-overlap, skill slot callbacks, heal callback, roster widths/portraits, camp navigation and empty slots. Gameplay, pixel motion, action events, combat feedback and save repair regressions passed. Native screenshots and gameplay MP4 were rendered and inspected. Physical phone touch testing remains outside these desktop checks.
