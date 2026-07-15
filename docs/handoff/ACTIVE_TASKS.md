# Active Tasks

This file is the current coordination board for active task ownership, file locks, blockers, and short handoff state.

## Board Status

- **Status**: `ACTIVE`
- **Active tasks**: `1`
- **Locked files**: `1`
- **Pending handoffs**: `0`
- **Branch**: `main`
- **Board baseline**: `0cd1293` (AUI-03-03 close-out, pushed to `main`)
- **Last updated**: `2026-07-15`

## Active Tasks

### MAIN-MENU-01 - Title Screen Redesign (背景/导航/弹窗)

- Owner: `Claude Code`
- Reviewer: `User` (visual, direct)
- Final Approval: `User` — approved: "验收通过，提交推送，另外我用正式仓库做过测试" (also confirming testing was done directly against the real, uncommitted project — explains save-hash churn across this round, not agent-caused).
- Mode: `single owner`
- Status: `DONE`
- Branch: `main`
- Worktree: repository root
- Base commit: post-AUI-03-03-close-out (`0cd1293`, this session)
- Objective: Redesign the title/main-menu scene (`scripts/main.gd`, `_setup_main_menu()` and related helpers) per several rounds of User instruction:
  1. Replaced the hand-drawn `_draw()`-based starfield/earth/mountain-silhouette placeholder background with the User's real background art (`assets/ui/opening/backgrounds/opening_background.png`), aspect-fill (cover) scaled/centered via a small `TitleScreenBackground` Control.
  2. Rebuilt the 4 main-menu nav rows (开始新驻留/继续驻留/开发入口/退出) as icon+label+shortcut-hint components with a full Default/Hover/Focus/Pressed/Disabled state system (single parallel `Tween` per item driving background alpha, left accent-bar alpha, text/icon alpha, and a small hover shift — no glow/blink/bounce), using real icons from `assets/ui/opening/icons/` (`icon_menu_new_expedition`/`icon_menu_continue`/`icon_menu_developer`/`icon_menu_exit`).
  3. Added the shared institution icon (`assets/ui/common/icons/atlas/icon_institution.tres`) above the "国家深空生命科学中心" text (resized down after an initial property-order bug caused it to render oversized — see Errors below), and replaced the plain "广寒前哨" title Label with the User's real wordmark logo art (`assets/ui/opening/logos/`).
  4. Replaced the static background with a real video background: User's source MP4 (H.264, not natively playable in Godot 4 — no built-in MP4 decoder) was converted to Ogg Theora (`assets/ui/opening/backgrounds/opening_background.ogv`, the only natively-supported Godot 4 video format) via `ffmpeg` (installed this round with User's explicit permission, `winget install Gyan.FFmpeg`), played through a real `VideoStreamPlayer` (looping, muted, aspect-fill cover-scaled, same technique as the static image), with automatic fallback to the static PNG if the video resource fails to load.
  5. Redesigned the "开始新的驻留档案？/START NEW OUTPOST FILE?" confirmation dialog (`_show_new_game_confirmation()`) to match a User-supplied reference mockup: added a dimmed modal scrim, warning icon + bilingual title + close button header, a bordered info box with a document icon, and bilingual (CN+EN) Cancel/Confirm buttons — using 3 new icons the User cut and placed at `assets/ui/common/icons/add/` (`icon_dialog_warning`/`icon_dialog_document`/`icon_dialog_close`). Final adjustment: Cancel pinned to the far left of the footer (was clustered next to Confirm on the right), matching the established two-button-bookend pattern used elsewhere in the app.
- Real asset directories read directly (not guessed): `assets/ui/opening/backgrounds/`, `assets/ui/opening/icons/` (region names confirmed via `sprite.godot.json`), `assets/ui/opening/logos/`, `assets/ui/common/icons/add/` (region names confirmed via `sprite.godot.json`). New `.tres` AtlasTexture resources generated for the 3 dialog icons in `assets/ui/common/icons/add/atlas/`, following the same pattern as the existing `assets/ui/common/icons/atlas/` set.
- Errors found and fixed along the way (all disclosed to User in-round):
  - Property-assignment order bug: setting `TextureRect.size` before `expand_mode`/`stretch_mode` on a freely-positioned (non-Container) Control caused Godot to clamp the size up to the texture's native (large) minimum size at assignment time; fixed by reordering (`expand_mode`/`stretch_mode` set first).
  - The taller wordmark logo (vs. the plain text title it replaced) pushed `box`'s auto-computed height enough to make the last child (`InputHint`) collide with the separately-fixed-position footer/dev-hint labels at y=856; fixed by trimming the logo's `custom_minimum_size` and tightening `box`'s separation, re-verified via a temporary layout-diagnostic script (sandbox-only, deleted after use) until a clean ~12px gap was confirmed.
  - A screenshot-capture-only "snow"/block-artifact glitch during video-background verification was root-caused to the capture script reading `root.get_texture()` before the video decode thread finished writing a frame (not a real encoding or playback defect) — confirmed by obtaining a clean capture after adding more `process_frame` waits before capture, and by the User's own real-project playback test.
  - Also fixed the shared `_make_step_back_button`/`_make_step_next_button` component (used by AUI-03-01/02/03) in a related round: the two builders never set `size_flags_vertical`, so a button placed directly in an `EXPAND_FILL` row (as this dialog's/AUI-03-03's footer does) stretched to fill the row's full height instead of staying at the intended button height — fixed by adding `size_flags_vertical = Control.SIZE_SHRINK_CENTER` in the shared builders themselves so the fix travels with the component.
- New dependency added this round (with User's explicit permission before installing): `ffmpeg` (via `winget install Gyan.FFmpeg`), used only as a one-time local conversion tool for the background video; not a project/runtime dependency (no ffmpeg invocation happens at game runtime or in any committed script).
- Verification: Godot 4.7 headless parse EXIT 0 after every change; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified throughout (unrelated system, sanity-checked each round). All new binary/media assets required a `--headless --editor --quit` import pass before they could be `load()`ed (new pattern for `.ogv`/PNG dialog icons, not previously needed for GDScript-only changes). Screenshot verification ran in the same isolated sandbox project copy used throughout this session (copied project + unique `project.godot` `config/name`); real project save file SHA-256 was checked before/after every sandbox round and stayed consistent with whatever the User's own concurrent manual testing against the real (uncommitted) project produced — never altered by any agent-run script.
- Deliverables: `docs/screenshots/main_menu/01-07*.png` (background, nav default/focus states, video-background frames, confirmation dialog).
- Push/tag authorization: `yes / no` — User said "提交推送" this round. Not tagged.
- Next: no follow-up started automatically.

### AUI-03-03 - Appearance & Marking Page (外观与标识)

- Owner: `Claude Code`
- Reviewer: `User` (visual, direct)
- Final Approval: `User` — approved. User confirmed the button-height fix (Round 2 below) resolved the page 01/02/03 inconsistency and explicitly authorized commit + push this round: "存档是我试玩的，本轮同意验收，提交并上传吧" (also confirming the save-hash churn across this task's rounds was their own manual play-testing of the real, uncommitted project, not an agent-caused change).
- Mode: `single owner`
- Status: `DONE` (closes Round 1-2 below)
- Branch: `main`
- Worktree: repository root
- Base commit: post-AUI-03-02-close-out (this session)
- Objective: Rebuild the 03 Appearance & Marking page (`_show_appearance()`) per User's detailed spec: remove the body-type ("体型") selector entirely; gender becomes a read-only field sourced from page 01 (no re-selection); skin tone / hair style / hair color / suit ID color become button-based selectors (no `OptionButton` dropdowns); suit level ("一级任务宇航服 / LEVEL 01") is fixed and visually separated from the suit ID color so players don't mistake color for rank; armband number and name initials are read-only/system-derived identity fields, displayed under the suit preview on the right (not in the left configuration column); left column fills its full vertical height (no large dead space); right side shows two aligned preview panels (personnel portrait + Level 01 suit) using real pre-made character/suit art assets (no runtime hair-layer compositing — each full combination is its own asset); footer completion count changes from `x/3` to `x/4` (skin, hair style, hair color, suit color; gender/armband/initials don't count).
- Real asset directories confirmed present in the repo (not yet wired into code): `assets/characters/player_preview/{male,female}/{light,medium,dark}/...` (personnel portraits) and `assets/characters/suits/sprite.png` + `sprite.godot.json` (Level 01 suit atlas, color variants). Real filenames/region names to be read directly before wiring, not guessed.
- Reference material: User supplied 4 reference images this round (full 1920x1080 page mockup, male example, female example, component-state sheet) plus a written spec as the visual target — these are design references to build toward, not files to copy pixel-for-pixel from an existing implementation.
- Addendum from User: hair-style buttons are plain text/label buttons only, no per-style thumbnail preview inside the button; character/suit preview textures load from `assets/characters/`.
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard` (for any real-runtime screenshot capture touching `user://` saves).
- Allowed discovery scope: `scripts/application/application_flow_scene.gd` (`_show_appearance()` and its helpers only), `assets/characters/` (read-only asset discovery + wiring), governance docs.
- Forbidden: Header/step-nav/page-title/footer chrome redesign (reuse existing shared helpers); page 01/02; save schema changes; new character/suit artwork; showing all 3 suit colors simultaneously; body-type system in any form.
- Push/tag permission: `no / no` this round (deliverable is a design-target render for review, not yet approved for commit).
- Characterization (pre-edit baseline): `_show_appearance()` previously rendered 5 `OptionButton` dropdowns (body-type/skin/hair-style/hair-color/suit-color, using placeholder label sets like "预设 A/B/C/D" that did not match any real asset naming) plus 2 freely-editable `LineEdit`s (armband number, name initials), and a hand-drawn placeholder preview (`suit_preview_control.gd`, `draw_line`/`draw_ellipse` primitives, no real art). No test coverage existed for this page.
- Real asset directories confirmed and wired in: `assets/characters/player_preview/<gender>/<skin>/<hair_color>/sprite.png` (region-per-hairstyle atlas; male regions `buzz`/`short`/`long`, female regions `short`/`ponytail`/`long`; two leaf folders — `female/light/blond` and `male/light/blond` — ship `sprite.json` (Smart-Sprite-Sheet-Packer/Unity schema) instead of `sprite.godot.json`, handled by a schema-detecting loader) and `assets/characters/suits/sprite.png` + `sprite.godot.json` (regions `suit_level_01_red`/`_yellow`/`_blue`). No new `.tres` AtlasTexture resources were generated for these (unlike the profession-icon rounds) — a single runtime `_load_atlas_region()` helper reads the JSON and builds an in-memory `AtlasTexture` per selection, since 18 leaf folders × 3 hairstyles = 54 combinations made pre-generating individual `.tres` files impractical.
- Implemented: `_show_appearance()` rebuilt around `_style_identity_panel`/`_add_identity_panel_heading`/`_add_identity_section_heading`/`_add_identity_readonly` (reused from pages 01/02) plus new button-based selector groups (`_build_swatch_group` for skin/hair-color/suit-color with a small color swatch + checkmark-on-selected; `_build_style_button_group` for hair style as plain equal-width text buttons per User's addendum, no thumbnail). Gender is read-only (`_add_identity_readonly`, sourced from `profile.gender_display`, no control to edit it here). Suit level ("一级任务宇航服 LEVEL 01") is a fixed read-only row, visually separate from the suit-ID-color swatch row above it. Right side shows two equal-size, equal-height `PanelContainer` previews (`_build_preview_frame`) each holding a real `TextureRect` (`appearance_portrait_rect`/`appearance_suit_rect`) plus a compact read-only recap label; footer rebuilt (`_build_appearance_footer()`) with 返回上一步 pinned far-left, 完成度/校验状态 centered, 下一步 pinned far-right (all three built from the shared `_make_step_back_button`/`_make_step_next_button` used by pages 01/02, so button size/style/icon stay unified). Completion gating now counts exactly 4 fields (skin/hair-style/hair-color/suit-color; gender/armband/initials excluded) via `_refresh_appearance_state()`, disabling 下一步 until `4/4`.
- Removed as dead code (fully superseded, zero remaining callers): `scripts/application/suit_preview_control.gd` (+ `.gd.uid`) hand-drawn placeholder preview; `_body_options_for_gender()`, `_marking_color()`, `_add_field_to()`, `_add_line_edit_to()`, `_add_options_to()` (the last three were generic dropdown/line-edit layout helpers used only by the old appearance page). `appearance_preset`/`suit_marking`/`name_initials` profile fields and their JSON schema keys were **not** removed (save schema unchanged per scope) — this page just no longer writes `appearance_preset` (body type is gone) and no longer exposes `suit_marking`/`name_initials` as editable (both now display-only via the existing `_suit_id()`/`_name_initials()` helpers, unchanged logic).
- One disclosed interpretation call: the User's two spec messages disagreed on where "宇航服标识色" lives — the original spec put it in the left panel; a later refinement said armband/initials/level/color should all move to the right recap block. Resolved as: the interactive red/yellow/blue **selector buttons** stay on the left (it's a required, clickable field), while the plain identity **recap text** (level/color/armband/initials) lives only on the right under the suit preview — avoiding both a non-interactive left panel and a right panel with no visible current-selection confirmation.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified (pages 01/02 untouched). New `tools/capture_aui_03_03_appearance.gd` run in the isolated sandbox (full project copy + unique `project.godot` `config/name`, per the established recipe) after a fresh `--headless --editor --quit` import pass (the newly-copied character/suit PNGs needed one before the sandbox could load them). Real project save file SHA-256 checked before and after this round's sandbox work — unchanged at `ecd54d848de153cfe1dcc0c5d0d0e0b68c813b7c0ee12de687abe150ec3b4adf` (this baseline itself differs from the previous round's recorded hash because the User manually launched and played the real project between messages this round, as they described — not an agent-caused change).
- Deliverables: `docs/screenshots/aui_03_03_appearance_marking/01_full_page_default_state.png` (male, incidentally lands on a real `3/4` incomplete state — skin tone's stored default doesn't match any of the 3 new options — demonstrating the Next-disabled gating naturally), `02_male_medium_black_short_blue.png` (medium skin, black short hair, blue suit, `4/4`), `03_female_medium_auburn_ponytail_red.png` (medium skin, auburn ponytail, red suit, `4/4`), `04_component_states_default_vs_selected.png` (cropped/stacked composite of the left panel's Default vs Selected states, built with a one-off post-processing script then deleted — not a full Hover/Disabled state matrix, see limitation below).
- Known limitation (disclosed, not fixed this round): Hover and Disabled styleboxes exist in code (`_style_appearance_choice_button()` sets `hover`/`disabled` variants) but aren't demonstrated in a screenshot — Hover needs interactive mouse simulation (unreliable in scripted capture, per this session's prior experience on AUI-03-02); Disabled isn't triggered by any current data state (no "locked" appearance option exists in this design). The delivered state image shows Default vs Selected only.
- Not started: AUI-03-04 (if any). Not touched: page 01/02, Header/step-nav/footer chrome, save schema, character/suit source art.
- Push/tag: `no / no` — not pushed, not tagged this round; awaiting User visual review.

#### AUI-03-03 Round 2 — Shared Step-Button Height Regression Fix

- User feedback (via a real screenshot from their own launch of the uncommitted project, not the sandbox): page 03's 返回上一步/下一步 buttons looked visibly larger than pages 01/02's, despite all three using the same `_make_step_back_button`/`_make_step_next_button` component.
- Root cause: those two builders never set `size_flags_vertical` on the returned `Button`. On pages 01/02 the buttons happen to sit inside a `right_cluster` `HBoxContainer` that is itself `SIZE_SHRINK_CENTER` within the footer row, which incidentally constrains the buttons to their `56`px `custom_minimum_size`. Page 03's footer puts `back_button`/`next_button` directly in the main `row` (to pin them to the far left/right edges per this task's own footer spec), and that `row` is `SIZE_EXPAND_FILL` inside a `124`px-tall framed footer with `16`px top/bottom padding — with no shrink constraint, Godot's default `SIZE_FILL` vertical flag stretched the buttons to the row's full ~92px available height instead of 56px.
- Fix: added `button.size_flags_vertical = Control.SIZE_SHRINK_CENTER` inside both shared builders (`_make_step_back_button`/`_make_step_next_button`) so the constraint travels with the component itself rather than depending on whatever wrapper a given page happens to use — this prevents the same regression from recurring on any future page that reuses these builders in a different footer layout.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified. Re-ran all three pages' capture scripts in the isolated sandbox; visually confirmed page 03's buttons now render at the same 56px height as pages 01/02 (screenshots for 01/02 are byte-different from the committed versions after re-capture — non-deterministic PNG re-encoding, visually identical, not a regression). Real project save file SHA-256 checked before/after this round's sandbox work; the baseline itself changed again mid-round because the User was directly running the real (uncommitted) project to reproduce the bug — consistent with their own report, not agent-caused.
- Deliverables: `docs/screenshots/aui_03_03_appearance_marking/*.png` (all 4, re-captured with the fix) plus refreshed `aui_03_01_basic_information`/`aui_03_02_profession_cards` captures (visual re-verification only, no content change).
- Push/tag: `no / no` — still awaiting User visual sign-off before any commit.

#### AUI-03-03 Close-Out

- Status: `DONE`. Final Approval: `User`, confirmed both the button-height fix and the page as a whole ("本轮同意验收").
- Push/tag authorization: `yes / no` — User explicitly said "提交并上传吧" this round; this commit includes Round 1 (new appearance page: button-based skin/hair-style/hair-color/suit-color selectors, real character/suit art wiring, read-only gender/level/armband/initials, dual aligned previews, unified footer) and Round 2 (shared step-button height fix) together, plus the re-captured `aui_03_01`/`aui_03_02` screenshots (visual re-verification only, no functional change) and the real `assets/characters/` art assets (now in scope for the first time). Not tagged.
- Production lock on `scripts/application/application_flow_scene.gd` released.
- Next: AUI-03-04 (if any) not started.

### AUI-03-02 - Academic Background Page: Profession Selection Cards (Left Side Only)

- Owner: `Claude Code`
- Reviewer: `User` (visual, direct); engineering review not yet assigned
- Final Approval: `User` — approved. User verified against the real, formally-launched project (not just the sandbox) and confirmed the two pages now match in size/layout: "查看了实际游戏图，大小一样了，页面通过，请提交并push".
- Mode: `single owner`
- Status: `DONE` (closes Rounds 1-8 below)
- Branch: `main`
- Worktree: repository root
- Base commit: `fe00d37`
- Objective: Implement only the left "选择专业背景" profession-selection card list on the 02 Academic Background page (`_show_education()`), including the 4 profession cards with Default/Hover/Selected/Recommended/Locked states, real square icon integration, single-selection switching, and Next disabled/enabled gating. Right-side "专业档案" content, its small icons, and full page visual close-out are explicitly out of scope this round.
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard` (if any real-runtime screenshot capture touches `user://` saves).
- Allowed discovery scope: `scripts/application/application_flow_scene.gd` (`_show_education()` and its helpers only), the 4 pre-placed profession icon files under `assets/ui/common/icons/professions/`, governance docs.
- Out-of-scope resources explicitly flagged by User (do not touch, do not generate AtlasTexture beyond the 4 square icons this task needs, do not wire in, do not delete/rename, do not include in this task's commit): `assets/ui/common/icons/professions/` circle variants and the right-side small-icon set (not yet present), `assets/characters/suits/` (unrelated future-page asset, untouched).
- Real icon files read directly from the repository (not guessed): `assets/ui/common/icons/professions/sprite.png` + `sprite.godot.json`, region names `icon_profession_plant_science_square`, `icon_profession_mechanical_engineering_square`, `icon_profession_materials_science_square`, `icon_profession_medicine_square` (each with matching `_circle` variants also present but not used this round).
- Production locks: `scripts/application/application_flow_scene.gd` (Owner: Claude Code; primarily `_show_education()` and its new helpers; Round 7 additionally touched `_show_identity()`'s footer-button construction and `_refresh_identity_state()` under explicit User instruction to unify the shared step-navigation button component across page 01 and page 02 — see Round 7 note below; release at AUI-03-02 close-out).
- New AtlasTexture resources added (mechanical accessor step over the existing pre-placed `sprite.png`/`sprite.godot.json`, not new artwork, not a modification of those source files): `assets/ui/common/icons/professions/atlas/icon_profession_plant_science_square.tres`, `icon_profession_mechanical_engineering_square.tres`, `icon_profession_materials_science_square.tres`, `icon_profession_medicine_square.tres` — region coordinates copied exactly from the existing `sprite.godot.json` metadata.
- Forbidden: right-side "专业档案" full content and its small icons; header/step-nav/footer redesign; save-schema changes; new profession types; `assets/characters/suits/`; the `_circle` icon variants (reserved for a later right-side task).
- Push/tag permission: `no / no`.
- Characterization: `_show_education()` currently renders plain `Button` rows for each profession (`EDUCATION_OPTIONS`) plus a right-side detail panel (`education_detail_title`/`education_detail_body`) and an `ApplicationArtPanelScript` art panel; confirmation flows through a `ConfirmationDialog` before advancing to `appearance`. This task replaces only the left button list with the approved card component; the confirmation dialog, `_select_education()`/`_confirm_academic_background_selection()`/`_apply_academic_background_selection()` business logic, and `selected_academic_background_id`/`education_background` fields are unchanged.

### AUI-03-02 Round 2 — Right-Side "专业档案" (same task, continued under User instruction)

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS` (not closed; waiting for visual re-verification, not self-declared VISUAL_PASS).
- Scope expanded by User: implement the right-side dynamic professional-profile panel (previously explicitly out of scope in Round 1), reading real icon directories rather than guessing.
- Real directories/files read directly (not guessed), matching the task's own "预期语义" almost exactly except for real `icon_domain_`/`icon_profile_` prefixes:
  - `assets/ui/common/icons/professions/details/common/sprite.godot.json` → `icon_profile_focus`, `icon_profile_domain`, `icon_profile_hint`.
  - `assets/ui/common/icons/professions/details/plant_science/sprite.godot.json` → `icon_domain_plant_growth`, `icon_domain_plant_light`, `icon_domain_plant_water`, `icon_domain_plant_greenhouse`, `icon_domain_plant_ecology_risk`.
  - `assets/ui/common/icons/professions/details/materials_science/sprite.godot.json` → `icon_domain_material_fatigue`, `icon_domain_material_corrosion`, `icon_domain_material_seal`, `icon_domain_material_durability`, `icon_domain_material_extreme_environment`.
  - `assets/ui/common/icons/professions/details/medicine/sprite.godot.json` → `icon_domain_medicine_monitoring`, `icon_domain_medicine_trauma`, `icon_domain_medicine_exposure`, `icon_domain_medicine_life_support`, `icon_domain_medicine_risk`.
  - `assets/ui/common/icons/professions/details/mechanical_engineering/sprite.json` — **different JSON schema** than the other four (a raw "Smart Sprite Sheet Packer" export with a `frames` map and `.png`-suffixed keys, not the `regions`-keyed "Godot AtlasTexture JSON" the other four use) → `icon_domain_mechanical_repair`, `icon_domain_mechanical_fault`, `icon_domain_mechanical_structure`, `icon_domain_mechanical_maintenance`, `icon_domain_mechanical_hatch`. Handled by reading `frame.x/y/w/h` instead of `regions.*`.
  - Also read the main `professions/sprite.godot.json` again for the 4 `_circle` region variants (square variants already existed from Round 1).
- New AtlasTexture resources added (27 new `.tres`, mechanical accessor step over existing pre-placed sprite sheets, not new artwork, not a modification of any source `sprite.png`/`sprite.godot.json`/`sprite.json`): 4 `_circle` mains in `professions/atlas/`, 3 in `professions/details/common/atlas/`, and 5 each in `professions/details/{plant_science,mechanical_engineering,materials_science,medicine}/atlas/`. Region coordinates copied exactly from each directory's own real JSON metadata (bulk-generated via a PowerShell `ConvertFrom-Json` pass, not hand-typed, to avoid transcription errors across 27 files).
- Right-side implementation: single shared `_build_profession_profile_panel()` + `_refresh_profession_profile()` component, keyed entirely off the same `pending_academic_background_id` authoritative source as the left cards (no second selection state). Rebuilds (not hides) the 5 coverage-icon row on every selection change. Structure follows the task's Section 9 exactly: 专业档案/PROFESSIONAL PROFILE heading → current profession name (real circle icon + CN/EN name) → 重点关注 (icon + highlight line + body) → 专业领域 (icon + body) → 任务提示 (icon + body) → 专业判断覆盖领域 (5 real icons, each in a fixed 150px-wide `VBoxContainer` cell so label-length differences never break alignment). The 重点关注/专业领域/任务提示 body text was derived directly from the existing `EDUCATION_DESCRIPTIONS` copy (核心风险 → focus, 信息优势 list → domain) rather than inventing new copy, then that now-fully-superseded dict and its last remaining reader (`_update_education_detail()`) were removed as dead code, along with the now-unused `ApplicationArtPanelScript` art-panel preload (the new Section 9 structure has no slot for it).
- Per Section 9's explicit "统一说明" requirement, the two shared disclaimer lines ("专业背景仅影响...", "该背景将在本次申请提交后锁定...") were moved from the right panel to directly below the left card list; the old "第一版作用/属性加成/..." text was removed entirely (not just reworded) since Section 9 explicitly lists it for deletion.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified (page 01 untouched). All 4 professions' screenshots captured in the same isolated sandbox (config/name-based `user://` isolation); real project save data SHA-256 checked before and after this round and stayed byte-identical to the state User confirmed was their own manual testing between sessions.
- Deliverables: `docs/screenshots/aui_03_02_profession_cards/01_plant_science_selected.png`, `02_mechanical_engineering_selected.png`, `03_materials_science_selected.png`, `04_medicine_selected.png` (superseding Round 1's 3 screenshots); `tools/capture_aui_03_02_profession_cards.gd` updated to drive all 4 professions in one pass.
- Not started: AUI-03-03. Not touched: suit/character assets (`assets/characters/suits/`), the shared canvas-scaling policy from AUI-03-01, or page 01.
- Push/tag: `no / no`, unchanged — not pushed, not tagged this round.

### AUI-03-02 Round 3 — 美术总监修改意见 (Art-Director Feedback, "必须修改" items only)

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS` (not closed; waiting for visual re-verification, not self-declared VISUAL_PASS).
- Scope this round: only the 9 items the art director marked "必须修改（建议本轮完成）". The 8 items marked "建议优化（可以下一轮）" and the closing "以后可以重做" future right-panel-restructure direction note were read and acknowledged but explicitly **not implemented** this round (deferred to a future round per the art director's own framing).
- Implemented, all in `scripts/application/application_flow_scene.gd`:
  1. Card height reduced `86px → 74px` in `_add_profession_card_list()`.
  2. Per-card summary changed from a single prose sentence to a 3-keyword row (`PROFESSION_CARD_DATA` field renamed `"summary"` → `"keywords": [String, String, String]`), rendered as an `HBoxContainer` of `Label`s joined by "·" separators at 12px font.
  3. Card icon now sits in a dedicated 44x44 `icon_frame` `PanelContainer` (2px `#324a5c` border, `#0d1821` bg) with the icon itself at 36x36 inside, instead of a bare icon at card scale.
  4. `_build_recommended_tag()` restyled green (`bg #1a2e20`, `border #4d8b61`, label `modulate #7fc998`), resized to `56x21` with `9px` horizontal content margin.
  5. 24px selector-to-right-edge spacing guaranteed structurally via a non-expanding `trailing_slot` `Control` (20x20) as the row's last child plus `row.offset_right = -24`, rather than a manually-tuned margin (pixel-measurement script attempted but inconclusive; structural guarantee trusted instead — see report).
  6. New `_style_education_panel()` applies 32px left/right, 24px top/bottom padding to both the left card-list panel and the right profile panel (via their `PanelContainer` parents), replacing the tighter default `_add_panel()` padding for this page only.
  7. Right-panel title hierarchy increased: `profession_profile_name` 20px → 36px, `profession_profile_name_en` 12px → 16px, `profession_profile_icon` 40x40 → 48x48.
  8. Coverage-row icons (`_build_coverage_item()`) enlarged 32x32 → 40x40, item spacing 6px → 12px, each still in a fixed 150px-wide cell.
  9. "下一步" button gained a trailing arrow icon (`IconArrowRight`, `icon_alignment = RIGHT`, `expand_icon = true`, `icon_max_width = 16`).
- Also removed as dead code (no longer reachable after the keyword-row change and prior rounds' cleanup): none new this round beyond what Round 2 already removed.
- Not implemented this round (explicitly deferred, per art director's own "下一轮"/"以后" framing): card hover-state polish, profile-name icon treatment, focus-highlight color-coding, group separators between coverage icons, coverage-icon hover state, a fix for coverage row at exactly 5 columns, header-to-title gap tuning, further subduing the disclaimer notes, and the larger "重做右侧为卡片模块" future-restructure direction.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified. All 4 professions re-captured in the same isolated sandbox (config/name-based `user://` isolation, not the real project); real project save file SHA-256 confirmed unchanged before and after this round (`ed54eb299f18caa25eb2964263f20ca42651a4938c950d16c0d6f7156c20ef66`).
- Deliverables: `docs/screenshots/aui_03_02_profession_cards/01_plant_science_selected.png`, `02_mechanical_engineering_selected.png`, `03_materials_science_selected.png`, `04_medicine_selected.png` (overwritten in place with the art-director-revised state; same 4 filenames as Round 2).
- Not started: AUI-03-03. Not touched: suit/character assets, canvas-scaling policy, page 01, or any of the 8 "建议优化" / future-rework items above.
- Push/tag: `no / no` — not pushed, not tagged this round.

### AUI-03-02 Round 4 — Next-Button Consistency + Bottom Whitespace Fix

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS`.
- User feedback this round (2 items, both addressed):
  1. "下一步" button on page 02 looked inconsistent with page 01's. Root cause: `_show_education()` built its own `profession_next_button` at `Vector2(200, 42)` and used the generic `_add_footer_button()` (also `200x42`, no color styling) for "返回", while page 01's `identity_back_button`/`identity_next_button` are `Vector2(150, AUI_BUTTON_HEIGHT)` / `Vector2(220, AUI_BUTTON_HEIGHT)` (`AUI_BUTTON_HEIGHT = 50`). Fixed by giving page 02 its own back button matching `150x50` and resizing `profession_next_button` to `220x50`, matching page 01's dimensions exactly (the enabled/disabled color styling already matched, via the existing `_style_identity_next_button()` call in `_refresh_profession_next_button()` — only the size was off). Change scoped to `_show_education()` only; the shared `_add_footer_button()` helper (used by appearance/review pages, out of scope) was not touched.
  2. Large blank area below both the left profession-card list and the right professional-profile panel, worse after Round 3's card-height reduction (86→74px) freed up more vertical room. Root cause confirmed via a temporary read-only layout diagnostic (`tools/inspect_aui_03_02_layout.gd`, written and run only in the isolated sandbox project copy, then deleted — not part of this task's deliverables): both column `VBoxContainer`s already stretch to the panel's full available height, but their content is top-anchored with no expanding element, leaving ~120-150px of dead space at the bottom in both columns. Fixed by inserting one `Control` spacer with `size_flags_vertical = SIZE_EXPAND_FILL` into each column: in `_show_education()` between the card list and the two shared disclaimer notes (left column), and in `_build_profession_profile_panel()` between the "任务提示" section and the "专业判断覆盖领域" heading (right column). This anchors the disclaimer notes and the coverage-icon row to the bottom of their respective panels, eliminating the dead gap without touching any existing text, icon, or spacing values. Verified via the same diagnostic: both columns' last child now ends flush with the panel's bottom edge at 1920x1080.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified. All 4 professions re-captured in the same isolated sandbox; real project save file SHA-256 confirmed unchanged before and after (`ed54eb299f18caa25eb2964263f20ca42651a4938c950d16c0d6f7156c20ef66`).
- Deliverables: `docs/screenshots/aui_03_02_profession_cards/01_plant_science_selected.png` … `04_medicine_selected.png` overwritten in place with the fixed layout (same 4 filenames as Round 2/3).
- Not started: AUI-03-03. Not touched: suit/character assets, canvas-scaling policy, page 01, any "建议优化"/future-rework items from Round 3.
- Push/tag: `no / no` — not pushed, not tagged this round.

### AUI-03-02 Round 5 — Panel/Section Grammar Unified with AUI-03-01

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS`.
- Scope this round (per User's 10-item "UI Layout Refinement" spec): unify page 02's lower-half visual structure (Panel, Section, Spacing, Grid, Visual Hierarchy) with page 01's design language. Explicitly not touched, per the spec's own item 十: Header, step bar, LOGO, the 4 profession main icons, the 5 coverage-area icons, the color palette, the font family.
- Panel style unified: both columns now use the shared `_style_identity_panel()` (same `AUI_PANEL_PADDING`/`AUI_PANEL_RADIUS`/`AUI_BORDER_WIDTH`/`AUI_COLOR_PANEL_BG`/`BORDER` as page 01's Candidate Record / Mission Brief panels), replacing the ad-hoc `_style_education_panel()` (removed, now dead). Left panel gained its own Panel Header via the shared `_add_identity_panel_heading()` — "候选人专业选择 / PROFESSIONAL SELECTION" (a page-01-style panel label distinct from the outer page title "选择专业背景", mirroring how page 01's "候选人基础资料" panel label differs from its own outer page title "基础信息" — an interpretive naming choice since the spec's own ASCII mockup reused the outer title text verbatim, which would have been a literal duplicate).
- Left list converted from floating bordered cards to a true divided list: `HSeparator` between each of the 4 rows (not per-row boxes), 24px left/right and 16px top/bottom row padding (via anchor offsets), unified 76px row height. Selected state now reads via a left accent bar (3px, `AUI_COLOR_ACTIVE_ACCENT`) + a faint background tint instead of a full bordered box; hover is a faint tint only; locked/default rows are fully flat. The two shared disclaimer notes moved behind an `HSeparator` at the bottom of the panel (a "Panel Footer" region belonging to the panel, no longer floating on the page background), font bumped 13→14px per the spec's grid rule.
- Right panel restructured into explicit Sections matching page 01's "A. 候选人填写信息 / CANDIDATE INPUT" grammar (icon + title + muted English subtitle + divider): new "职业信息 / PROFESSION OVERVIEW" section wraps the profile icon+name block; "重点关注/KEY FOCUS", "专业领域/DOMAIN EXPERTISE", "任务提示/MISSION HINT" each gained an English subtitle + divider added to their existing real-icon header (`_build_profile_section()` signature extended); "专业判断覆盖领域" gained a proper Section header (replacing a bare label) plus a small bottom breathing-room pad so the coverage icon row no longer sits flush against the panel's bottom edge. Profile name font 36→32px and section body font 13→16px per the spec's grid rule (标题32/正文16/说明14).
- Per-profession keyword color: new `PROFESSION_ACCENT_COLORS` const (plant=green `#7fc998`, mechanical=blue-gray `#8ea3b8`, materials=silver-gray `#b7c0c7`, medicine=cyan-blue `#7fd3d9`), applied to each card's keyword row so professions read at a glance instead of uniform gray, replacing the previous locked/selected/default 3-way gray scheme (locked stays muted gray).
- Bottom Action Bar: new `_build_education_footer()` wraps 返回/下一步 in a bordered `PanelContainer` frame identical in style to page 01's `_build_identity_footer()` frame, with buttons right-aligned via a leading spacer (previously the two buttons were added directly to the shared `footer` row with no frame and no right-alignment, sitting at the bottom-left of the page — a real inconsistency with page 01's bottom-right action cluster, now fixed).
- **Real regression found and fixed during this round**: the added Section headers + an initial `separation=24` on both columns (a literal reading of the spec's "Section间距24px") pushed the right column's minimum content height (~890 design px) well past its available budget under AUI-03-01's fixed-1080-canvas architecture (`page_body`'s remaining budget after header/step-bar/footer is ~647 design px), which silently shoved the entire bottom action bar below the visible canvas (confirmed via a temporary read-only layout-diagnostic script, run only in the isolated sandbox and deleted afterward, not a deliverable). Fixed by reverting the blanket 24px separation override (back to the panels' existing default of 10, inherited from `_add_panel()`) and tightening each profile section's internal spacing (6→4px); the full Section-header/divider structure the spec asked for is preserved, only the literal "24px" gap number was not honored everywhere — disclosed here as the one deliberate deviation from the numbered spec, made to keep the page from overflowing its own canvas.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified; a temporary layout diagnostic (sandbox-only, deleted) confirmed the bottom action bar now renders fully on-screen at 1920x1080 with no overflow. All 4 professions re-captured in the isolated sandbox; real project save file SHA-256 confirmed unchanged before and after (`ed54eb299f18caa25eb2964263f20ca42651a4938c950d16c0d6f7156c20ef66`).
- Deliverables: `docs/screenshots/aui_03_02_profession_cards/01_plant_science_selected.png` … `04_medicine_selected.png` overwritten in place with the restructured panels (same 4 filenames as prior rounds).
- Not started: AUI-03-03. Not touched: suit/character assets, canvas-scaling policy, page 01, header/step-bar/LOGO, the 4 profession icons, the 5 coverage icons, color palette, font family.
- Push/tag: `no / no` — not pushed, not tagged this round.

### AUI-03-02 Round 6 — Art-Director Re-Review Fixes (VISUAL_REVISION_REQUIRED)

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS`. Prior round's re-verification verdict was `VISUAL_REVISION_REQUIRED` (structure approved, space allocation/hierarchy rhythm needed another pass) — this round addresses the 5 "必须修正" items from that review; the "建议优化" items (darker selected-card bg, keep recommended tag low-saturation, dim the English subtitles one more tier, keep coverage icons evenly spaced) were read but explicitly not implemented this round.
- **Left card list filled out**: card height 76→98px, list separation 0→14px (cards now have real gaps, not just hairline dividers), icon 36→44px in a 44→52px frame, title 16→18px, keyword text 12→13px, selector circle slot 20→22px, row padding 24px L/R / 21px T/B. Four taller, more spaced-out cards now occupy the panel's main body instead of clustering at the top with dead space below; the footer note block is unchanged (still a distinct Panel-Footer region below a divider).
- **Bottom action bar made symmetric**: `_build_education_footer()` rebuilt as back (pinned left) / step indicator (centered, new "步骤 2 / 4" label computed from `STEP_LABELS` order) / next (pinned right), both buttons now identical size `210×56` (previously `150×50` / `220×50`, asymmetric) — a deliberate page-02-specific divergence from page 01's button dimensions per this round's explicit ask, not an inconsistency.
- **Next-button arrow enlarged**: `icon_max_width` 16→22px, new `h_separation` 18px between text and icon, plus a new optional `icon_right_inset` param on the shared `_style_identity_next_button()` (default `0`, so page 01's identity button is untouched byte-for-byte) set to `20` only for `profession_next_button`, giving the arrow clearance from the button's right edge. Icon color now explicitly themed (`icon_normal/hover/pressed_color` = primary text color, `icon_disabled_color` = the same muted tone as disabled text) so the arrow dims together with the label in the disabled state instead of staying full-brightness.
- **Right panel divider count reduced from 5 to 2**: `_add_identity_section_heading()` gained an optional `with_divider` param (default `true`, so identity page's A/B headers are unaffected); the "职业信息" section header and the "专业判断覆盖领域" section header now pass `false`. `_build_profile_section()` (重点关注/专业领域/任务提示) no longer appends its own `HSeparator`. Only two dividers remain: the panel heading's own divider (unchanged, pre-existing), and one new `HSeparator` marking the boundary between the info block and the coverage block. The three info sections gained explicit 20px fixed spacers between them (not a blanket separation bump, to avoid re-triggering the Round 5 overflow bug) so they read as spaced apart rather than line-divided.
- **Coverage section bottom padding**: 8→28px so the coverage icon row no longer sits flush against the panel's bottom edge.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified; a temporary read-only layout diagnostic (sandbox-only, deleted after use) confirmed the footer stays fully on-screen (bottom edge at design-equivalent y≈903 of 1080) both at the default selection and at `materials_science` (the longest body text, worst case for wrap-related growth). All 4 professions re-captured in the isolated sandbox; real project save file SHA-256 confirmed unchanged before and after (`ed54eb299f18caa25eb2964263f20ca42651a4938c950d16c0d6f7156c20ef66`).
- Deliverables: `docs/screenshots/aui_03_02_profession_cards/01_plant_science_selected.png` … `04_medicine_selected.png` overwritten in place.
- Not started: AUI-03-03. Not touched: suit/character assets, canvas-scaling policy, page 01 (aside from the additive, opt-in `with_divider`/`icon_right_inset` default params which leave its existing calls behaviorally identical), header/step-bar/LOGO, profession/coverage icons, color palette, font family, page 02's existing content copy.
- Push/tag: `no / no` — not pushed, not tagged this round.

### AUI-03-02 Round 7 — Shared Step-Navigation Button Component (touches page 01 under explicit instruction)

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS`.
- User instruction this round: the 返回/下一步 button pair must be visually unified between page 01 and page 02, and page 01 should change too rather than page 02 diverging on its own — "最好能复用第一页的按钮" (best if the component is actually shared/reused). This explicitly authorizes touching `_show_identity()` (page 01), which prior rounds had kept out of scope.
- Extracted a new shared component in `application_flow_scene.gd`: `_make_step_back_button(text, callback)` and `_make_step_next_button(text, callback)`, both building a `STEP_BUTTON_SIZE = Vector2(210, 56)` button (next button also wires up `IconArrowRight`, `icon_max_width=22`, `h_separation=18`, and calls the existing `_style_identity_next_button(button, 20)` for the blue enabled/disabled styling with the icon inset/dimming added last round). Both `_show_identity()`'s footer-button construction and `_build_education_footer()` now call these two functions instead of each independently constructing a `Button`.
- Page 01 changes as a direct result: `identity_back_button`/`identity_next_button` grew from `150x50`/`220x50` (`AUI_BUTTON_HEIGHT` scale) to the shared `210x56`, gaining the same enlarged arrow + icon dimming as page 02's button. The now-unused `AUI_BUTTON_HEIGHT` constant was removed (nothing else referenced it). `_refresh_identity_state()`'s re-styling call (`_style_identity_next_button(identity_next_button)`, invoked whenever field-validity changes) was updated to pass the same `20` icon inset so the disabled-state re-style doesn't silently drop it.
- Page 01's overall footer layout (status badge + validation + completion-dots cluster on the left, back/next cluster on the right) was intentionally left as-is — only the button component itself was unified, not page 01's whole action-bar structure (which page 02 does not share, having no per-field validation state to show).
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified. Re-ran both `tools/capture_aui_03_01_basic_information.gd` and `tools/capture_aui_03_02_profession_cards.gd` in the isolated sandbox — all 5 + 4 screenshots captured, both pages' buttons confirmed visually identical in size/arrow treatment. real project save file SHA-256 confirmed unchanged before and after (`ed54eb299f18caa25eb2964263f20ca42651a4938c950d16c0d6f7156c20ef66`). Note: the sandbox's own (isolated, non-real) persisted save had `CurrentApplicationStep: "education"` left over from prior rounds' repeated education-page captures, which made the page-01 capture script skip identity-field construction; reset by deleting the sandbox's own save file (not the real project's) before re-capturing — a sandbox-local fix, no real data touched.
- Deliverables: `docs/screenshots/aui_03_01_basic_information/*.png` (all 5, updated for the new button size) and `docs/screenshots/aui_03_02_profession_cards/*.png` (all 4, updated) overwritten in place.
- Not started: AUI-03-03. Not touched: header/step-bar/LOGO, profession/coverage icons, color palette, font family, page 01's field inputs/mission-brief content, page 01's overall footer/status-cluster layout.
- Push/tag: `no / no` — not pushed, not tagged this round.

### AUI-03-02 Round 8 — Footer Cluster Layout Corrected to Match Page 01

- Owner: `Claude Code`. Same task ID; no duplicate task created. Status remains `IN_PROGRESS`.
- User feedback: after Round 7 unified the button *component* (both pages using the same `210x56` `_make_step_back_button`/`_make_step_next_button`), the two pages' footers still read as visually inconsistent when compared side by side — page 02's back/next were pinned to opposite far edges of the bar with a centered "步骤 2/4" label, spreading across the bar's full width, while page 01's cluster sits compactly on the right (occupying roughly half the bar). User confirmed the buttons themselves were already identical size; the complaint was the *layout/positioning*, and asked to match page 01's compact right-side cluster (offered 3 options via AskUserQuestion; user picked "match page 01's compact right cluster").
- Fixed `_build_education_footer()`: replaced the "back-left / step-label-center / next-right" row with the same structure page 01 uses — a leading `Control` spacer (`SIZE_EXPAND_FILL`) followed by a `right_cluster` `HBoxContainer` (`separation=12`, `SIZE_SHRINK_CENTER`) holding both buttons together. The "步骤 2 / 4" label was removed entirely (it only existed to fill the gap in the now-abandoned edge-to-edge layout).
- No change to button size/style/icon (still the shared `_make_step_back_button`/`_make_step_next_button`, `210x56`) — only the surrounding row structure changed.
- Verification: Godot 4.7 headless parse EXIT 0; existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified (page 01 untouched this round). Re-ran `tools/capture_aui_03_02_profession_cards.gd` in the isolated sandbox; real project save file SHA-256 confirmed unchanged (`ed54eb299f18caa25eb2964263f20ca42651a4938c950d16c0d6f7156c20ef66`).
- Deliverables: `docs/screenshots/aui_03_02_profession_cards/*.png` (all 4) overwritten in place with the corrected footer layout.
- Not started: AUI-03-03. Not touched this round: page 01 (identity), header/step-bar/LOGO, profession/coverage icons, color palette, font family.
- Push/tag: `no / no` — not pushed, not tagged this round.

### AUI-03-02 Close-Out

- Status: `DONE`. Final Approval: `User`, verified against the real formally-launched project (not just the isolated sandbox), confirming page 01/02 button parity and the overall page match the approved standard.
- Push/tag authorization: `yes / no` — User explicitly said "请提交并push" this round; this commit includes all of Rounds 1-8 (production script changes, new AtlasTexture resources, updated screenshots for both `aui_03_01_basic_information` and `aui_03_02_profession_cards`, and this documentation). Not tagged.
- Production lock on `scripts/application/application_flow_scene.gd` released.
- Next: AUI-03-03 (外观与标识 / Appearance & Marking) started this round under a new task entry below.

## Recently Closed

### AUI-03-01 - Basic Information Page Visual Sample Implementation

- Status: `DONE`
- Owner: `Claude Code`
- Previous owner: `Codex`
- Reviewer: none independent of Owner — role conflict flagged at transfer (Claude Code had been this task's Reviewer before becoming Owner); resolved by User's final acceptance, which User confirmed explicitly covers both visual match and engineering correctness for this task.
- Visual review: User reviewed real 1920x1080 screenshots directly across four iterative rounds (not routed through the registered `ChatGPT` Visual Reviewer for this particular task instance).
- Final Approval: `User` — approved.
- Base commit: `2671b23`
- Owner Transfer: Codex → Claude Code. Reason: Codex's implementation (business logic, pure-function tests, icon atlas) was complete, but the running screenshot did not meet the approved visual standard; User directed a full rebuild of `_show_identity()`'s visual node tree rather than incremental styling, preserving all business logic, bindings, and save behavior unchanged. Transfer accepted the then-current non-clean working tree as in-scope task changes; no duplicate task was created.
- Preserved unchanged (per transfer scope): `basic_information_state()`, `derive_candidate_display_id()` (`GHC-` prefix rule), name/gender/birth-year bindings, the existing next-step gating, `user://saves/application_profile.json` schema and save timing, and the existing 29-check `tests/aui_03_01_basic_information_test.gd`.
- Rebuilt by Claude Code: full `_show_identity()` visual node tree — Header (96px, real institution/assistant icons, vertically centered metadata block), StepNavigation (64px), PageHeading (80px), 52/48 dual-column body (636px; 24px panel padding; 20px column gap) with real `icon_lock` on system-generated fields and a real-Control Mission Brief diagram (real `icon_earth`/`icon_moon`/`icon_outpost`/`icon_terminal`, solid double-arrow and dashed single-arrow line connectors built from `ColorRect`/`Label` primitives, replacing the prior unicode-text placeholders), and a four-cluster BottomActionBar (124px: circular status badge using `icon_status_incomplete`/`icon_status_complete` with the `X/3` ratio overlaid, validation status + hint, a separate "必填项完成情况" block with per-field `○`/`●` radio-style indicators, and Back/Next with the arrow icon ordered after the button text). Page 01's `ScrollContainer` vertical scrolling is explicitly disabled only for this step; `_show_step()` resets it to `AUTO` before the step match so education/appearance/review/notice/withdrawn keep their prior scroll behavior unchanged. Removed dead code `_add_readonly_field_to()` (zero callers; contained a literal "锁定" string that would have violated the icon-only requirement had it ever been wired in).
- Iterative correction rounds (each verified against the approved reference/spec and against real save-file SHA-256 before/after): (1) canvas was rendering at the project's default 1600x900 instead of 1920x1080 — `root.size`/`content_scale_size` explicitly set in the capture tool, which pushed the BottomActionBar off-screen; (2) BottomActionBar restructured from 3 merged clusters to the approved 4-cluster layout with a real circular status badge and `○`/`●` radio-style field indicators; (3) Mission Brief Earth–Moon and Moon–Outpost connectors rebuilt as real solid/dashed line primitives instead of text-glyph dashes; (4) header metadata block and assistant icon vertically centered relative to each other; (5) Next-button arrow icon reordered to appear after (not before) the button text via `icon_alignment`.
- Verification: Godot 4.7 headless parse EXIT 0 after every change; the existing 29-check test passed unmodified throughout. Screenshot capture ran in an isolated sandbox project copy (full project copy excluding `.git`/`.godot`, with the sandbox's `project.godot` `config/name` changed to a unique value) — isolation is keyed by `config/name`, not by folder path or `--user-data-dir`, per the working recipe Codex provided. Real project save data (`application_profile.json`) was hashed (SHA-256) before the first capture attempt and re-checked after every subsequent round; it was byte-identical throughout every round reported here.
- Known incident (fully disclosed, no data loss): an early screenshot attempt assumed `--user-data-dir` would isolate `user://`; it did not, and two capture runs briefly wrote to the real save directory before this was caught. SHA-256 comparison confirmed both writes were no-op re-saves (same profile state reloaded and rewritten unchanged); no content was altered or lost. The correct sandbox recipe (copied project + renamed `config/name`) was then obtained from Codex and used for all screenshots delivered in this closure.
- Deliverables (superseded by the revision round below; kept for history): `docs/screenshots/aui_03_01_basic_information/01_initial_0_of_3.png`, `02_gender_dropdown_expanded.png`, `03_complete_3_of_3_next_enabled.png`; reusable capture tool `tools/capture_aui_03_01_basic_information.gd`.
- Scope discipline: no change to `scenes/application/ApplicationStartScene.tscn`, `02`/`03`/`04` page bodies, save schema, `PlayerProfileData`, global Theme, or unrelated systems.
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard` (real field evidence via the save-hash checks above); all formal Skills remain `TRIAL`, no maturity upgrade.

### AUI-03-01 Revision Round — Footer/Scaling/Polish (same task, continued under User instruction)

- Owner: `Claude Code`. Same task ID; no duplicate task created.
- Round 1 finding: `VISUAL_REVISION_REQUIRED`. Real running screenshots (not the capture-script-forced 1920x1080) showed the BottomActionBar completely off-screen. Root cause: `_show_identity()` had explicitly set `content_scroll.vertical_scroll_mode = SCROLL_MODE_DISABLED`; the project's actual default viewport is 1600x900 (`project.godot`), and the page's zero-slack 1920x1080 layout budget overflowed at that size with scrolling disabled, pushing the footer out of view. Fix: removed the disable; `_show_step()`'s existing reset to `AUTO` was sufficient. Verified defensively at the real 1600x900 default (not just the forced 1920x1080) — footer stayed visible with graceful internal scroll.
- Round 1 also fixed, per User detail list: unified 16px left padding across the LineEdit and both OptionButtons (`_style_identity_option` had no `content_margin_left/right` at all — this was the actual misalignment cause); real solid/dashed line connectors in the Mission Brief diagram (`_add_solid_double_arrow`/`_add_dashed_single_arrow`) replacing text-glyph dashes; header 3-zone stability (left institution / center title / right meta+assistant, all vertically centered on the same line); assistant icon +10% size and dimmed; Mission Brief diagram enlarged with more padding and fonts bumped to 13-14px minimum; page-heading description moved next to the title with higher contrast; read-only field visual distinction strengthened; focus-ring color desaturated.
- Round 2 (GPT explanation accepted): the project's `stretch/mode` is `disabled` (1 logical unit = 1 screen pixel; Godot does not auto-scale a 1920x1080-designed UI to a smaller window). Confirmed this is why a page sized only for 1920x1080 clips/loses content at any smaller real window. User confirmed the real save-hash change observed mid-round was their own manual testing, not a sandbox leak.
- User then asked about proportional/equal-ratio scaling instead of a scrollbar fallback. Clarified scope: a project-wide `project.godot` stretch-mode change would affect every scene and is out of this task's scope; User agreed a global stretch-mode change should be its own separate task (not started). The actual ask turned out to be scoped to this scene only.
- Round 3 — `VISUAL_REVISION_REQUIRED` (core fix, replacing the Round-1 scroll-fallback approach): implemented a single authoritative per-scene scaling scheme entirely inside `application_flow_scene.gd` (no `project.godot` change, no effect on other scenes). All page content lives under a fixed `aui_canvas` Control sized exactly 1920x1080; `_update_aui_canvas_scale()` computes `scale = min(available.x/1920, available.y/1080)`, applies it to `aui_canvas`, and centers it (letterbox/pillarbox on the non-binding axis) — recomputed on the scene's `resized` signal and defensively every `_process()` frame (cheap, deduplicated against the last known size). The `ScrollContainer` wrapper was removed entirely; `page_body` is now a direct child of `root`. Verified at 1920x1080 (no scrollbar, full footer), 1600x900 (exact 83.33% scale, no scrollbar, full footer), and 1440x900 non-16:9 (scale bound by the narrower axis, symmetric 45px top/bottom letterbox measured pixel-by-pixel, no stretch, no crop).
- Round 4 — `VISUAL_PASS_WITH_MINOR_ADJUSTMENTS` (final polish, ChatGPT visual summary relayed by User): added a per-frame `_process()` recompute as a defensive safeguard beyond the `resized` signal (precise pixel measurement of the delivered 1440x900 screenshot confirmed the letterbox was already exactly centered, but the extra safeguard costs nothing and covers real interactive resize timing this script-driven test can't fully exercise); bumped several minimum auxiliary font sizes (Header English 11→12, system-code/time meta row 12→13, read-only-section and panel-heading subtitles 11→12, footer validation hint 12→13, Mission Brief terminal-note label 12→13); shrank the Next-button arrow icon ~20% (`expand_icon` + `icon_max_width=16` against the native 20px asset); further dimmed the read-only lock icon; added `v_separation`/item padding to the OptionButton popup to enlarge perceived dropdown-item height (best-effort — Godot 4's `PopupMenu` has no direct per-item height property).
- Verification (every round): Godot 4.7 headless parse EXIT 0; the existing 29-check `tests/aui_03_01_basic_information_test.gd` passed unmodified throughout — `basic_information_state()`, `derive_candidate_display_id()`, 0/3-3/3, Next gating, education flow, and save schema were never touched. All screenshot capture ran in the isolated sandbox (copied project + unique `project.godot` `config/name`, per Codex's recipe); real project save data was SHA-256 checked before and after every round and stayed byte-identical to the state User confirmed was their own testing.
- Final deliverables: `docs/screenshots/aui_03_01_basic_information/01_1920x1080_initial_0_of_3.png`, `02_1600x900_initial_0_of_3.png`, `03_1440x900_non_16_9_letterboxed.png`, `04_1600x900_complete_3_of_3_next_enabled.png`, `05_gender_dropdown_expanded.png` (superseding the Round-0 filenames above).
- Known limitation (disclosed, not fixed this round): the `OptionButton` dropdown popup is a native `PopupMenu`/separate window layer, not a child of `aui_canvas` — at 1920x1080 (scale 1.0) it matches the rest of the UI, but at a non-1.0 scale its own text may not shrink proportionally with the rest of the page. Not addressed in this round; flagged for a future task if it needs to match.
- Visual conclusion (User, relaying ChatGPT's review): `VISUAL_PASS_WITH_MINOR_ADJUSTMENTS`. Explicitly noted: "第一页公共框架已经可以作为第二页的稳定基础继续使用" (informational, for future task planning — no action taken this round) and "当前视觉通过不代表工程逻辑已被验证" (visual PASS is not a claim of engineering/code correctness).
- Push authorization: User explicitly stated "通过，可以push" in the same message as the visual conclusion. This is treated as this round's specific push authorization (distinct from — and superseding, for this commit only — the earlier "no" recorded above).
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard`; all formal Skills remain `TRIAL`, no maturity upgrade.
- Next: no follow-up task started automatically. A separate task for project-wide `stretch/mode` scaling (if still wanted) has not been opened.

### AUI-DOC-01 - Register Basic Information Visual Reference

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `1a50d69`
- Result: Registered the approved AUI-03-01 Basic Information high-fidelity visual reference and written specification as tracked repository documentation before implementation.
- Verification: Reference PNG is readable; specification is non-empty and documents the approved fields, progress behavior, next-step states, visual-reference-only boundary, no-full-image-background rule, and 01-page-only scope.
- Next: AUI-03-01 not started.

### P6-02 - Application Step Active-State Highlight

- Owner: `Codex`
- Reviewer: `Claude Code`
- Visual Reviewer: `ChatGPT`
- Final Approval: `User`
- Mode: `A — single owner`
- Status: `DONE` (`P6-02` final result: `VERIFIED`)
- Branch: `main`
- Worktree: repository root
- Base commit: `e76db99`
- Objective: Add a clear visual Active state to the current step in the four-step Guanghan permanent-pioneer application interface without changing application flow or data behavior.
- Skills: `task-baseline-and-lock`, `characterization-first-refactor`
- Allowed discovery scope: application-system scene files, application-system scripts, directly related theme/style resources, directly related tests, governance documents.
- Initial locked governance files:
  - Path/resource: `docs/handoff/ACTIVE_TASKS.md`; Owner: `Codex`; Lock type: document lock; Reason: P6-02 task lifecycle; Release condition: P6-02 close-out.
  - Path/resource: `docs/handoff/CURRENT.md`; Owner: `Codex`; Lock type: document lock; Reason: P6-02 status and characterization record; Release condition: P6-02 close-out.
  - Path/resource: `docs/governance/CLEANUP_PLAN.md`; Owner: `Codex`; Lock type: document lock; Reason: P6-02 field-validation record; Release condition: P6-02 close-out.
- Production file locks:
  - Path/resource: `scripts/application/application_flow_scene.gd`; Owner: `Codex`; Lock type: file lock; Reason: P6-02 dynamic application step-bar active-state rendering; Release condition: P6-02 close-out.
  - Path/resource: `tests/p6_02_application_step_active_state_test.gd`; Owner: `Codex`; Lock type: file lock; Reason: P6-02 save-free characterization coverage; Release condition: P6-02 close-out.
  - Path/resource: `tests/p6_02_application_step_active_state_test.gd.uid`; Owner: `Codex`; Lock type: generated companion file lock; Reason: Godot script identity if generated; Release condition: P6-02 close-out.
- Forbidden: unrelated gameplay systems, save format, player profile data, training system, lunar-base runtime systems, assets unrelated to this screen, global theme changes affecting unrelated screens, project-wide UI redesign.
- Push/tag permission: `no / no`
- ### Approved Scope
  - Current page's corresponding top application step renders `Active`; all other steps render `Inactive`.
  - Exactly one step is Active at a time.
  - Initial page, forward navigation, and backward navigation remain synchronized with the authoritative `step` value.
  - User visual approval: `APPROVED` for the application step Active-state highlight only.
- ### Explicitly Out of Scope
  - Completed and Submitted navigation states; application-wide redesign; form-control restyling; fixed footer; global Theme; character preview; result/submit page redesign; and system-assistant positioning. These require separate tasks.
- Save Skill: `save-integrity-guard` added for blocker resolution.
- Protected user-data: `user://saves/application_profile.json`.
- Backup required / SHA verification required / restore authorization / automatic rollback: `yes / yes / User only / forbidden`.
- Confirmed User-Data Risk: Runtime entry calls `_ready()`; `_ready()` calls `_show_step()`; `_show_step()` unconditionally calls `_save_profile()`; `_save_profile()` writes `user://saves/application_profile.json`. Page entry and step navigation can refresh real application-profile data.
- Save baseline backup: `C:\Users\csw83\AppData\Local\Temp\saves_backup_before_p6_02_2026-07-14_140143` (`13/13` source/backup files; all SHA-256 values match).
- Save Forensics Resolution: `application_profile.json` and `door_state.json` are valid standard UTF-8 JSON. The prior corruption classification was a tooling false positive. The backup remains complete; the 13-file source/backup SHA baseline remains verified. User authorized runtime continuation under `save-integrity-guard`. No restore, delete, rebuild, or automatic rollback authorization was granted; restore remains User-only.
- Runtime Save Guard Result: `UNEXPECTED_WRITE` (historical formal-runtime incident). Before the first Godot command, source and backup each contained 13 matching files. After the save-free characterization test plus required editor/smoke, source contained 16 files. The three newly created files were absent before and are not in the backup: `backpack_state.json` (236 bytes, `FA5317D118650D439F3DD310529EAF127DA3C67091A1C6517836150579C43991`), `repair_state.json` (67 bytes, `960A42F28EEA110BB96C2F4C302AF9EDCC801A72672400E3B1608683E73055D3`), and `storage_state.json` (618 bytes, `82C3073E7CE6817E18239F9CECEEF151A781B085D6659A2B03A15B871E693DBD`). The original 13 files, including protected `application_profile.json` and `door_state.json`, retained their before-run SHA values. No automatic restore, deletion, retention, or cleanup was authorized. P6-02 subsequently switched to sandbox-only validation; the provenance limitation remains in scope for review.
- Known Save Provenance Limitation: `EXTERNAL_MUTATION_CONFIRMED_SOURCE_UNKNOWN`. The three previously-created state files are no longer present. `application_profile.json` differs from the runtime-before baseline, while `door_state.json` remains unchanged. User confirmed opening the application page; the profile's unchanged 20-field schema, no field loss, and value-only differences are classified as `APPLICATION_PROFILE_EXPECTED_WRITE` through `_ready() -> _show_step() -> _save_profile()`. Static code explains why the three missing manager-local files are created when absent and identifies a runtime demo-progress cleanup path that can remove all three, but no reliable provenance log proves that cleanup path executed. No restore, deletion, or real-runtime Godot run is authorized; subsequent validation is restricted to the isolated sandbox.
- Isolated Runtime Authorization: User authorized P6-02 runtime validation only in `C:\Users\csw83\AppData\Local\Temp\guanghan_p6_02_runtime_sandbox_20260714_144312`, using application name `Guanghan Outpost P6-02 Sandbox 20260714-144312` and its separate Godot user-data root. The sandbox contains no copied real save, `.git`, or `.godot` cache. Real user-data remains frozen and real-runtime validation remains prohibited; automatic restore remains forbidden.
- ### Skill Field Evidence
  - `task-baseline-and-lock`: one Owner was registered; the task remained blocked while save risks were investigated; no commit, push, tag, or premature reviewer verdict was made.
  - `characterization-first-refactor`: the existing authoritative `step` was retained; no duplicate step index was created; `_show_step()`'s save coupling was identified; form, submit, and save logic were not changed; the focused 16-check source-safe test was added.
  - `save-integrity-guard`: a verified 13-file backup was created; the prior JSON-corruption false positive was corrected; real-runtime effects were identified; subsequent validation used an isolated sandbox; unknown provenance was retained honestly.
  - All formal Skills remain `TRIAL`; no maturity upgrade is authorized.
- ### User-Data Findings
  - `application_profile.json`: `APPLICATION_PROFILE_EXPECTED_WRITE`. User opened the application page; schema and 20 top-level fields were unchanged, with no fields added or lost and only two existing string values changed, consistent with `_ready() -> _show_step() -> _save_profile()`.
  - `backpack_state.json`, `repair_state.json`, and `storage_state.json`: `EXTERNAL_MUTATION_CONFIRMED_SOURCE_UNKNOWN`. Creation and a possible demo-progress cleanup path were identified, but no reliable provenance log proves the deletion source. Real saves are currently back to 13 files. No save logic was changed.
- ### P6-02 Review Handoff
  - Engineering Reviewer: `Claude Code`; Reviewer verdict: `PASS`.
  - Reviewer scope: P6-02 Application Step Active-State Highlight only.
  - Reviewer caveat: This PASS does not validate the full application UI or historical save-file provenance.
  - F1: the focused test covers pure mapping; `_show_step() -> _refresh_step_bar()` wiring was confirmed by code review, not scene instantiation. Informational; optional future improvement; no required fix.
  - F2: `notice` and `withdrawn` do not highlight the four-step navigation. Outside the current four-step Active scope; not a P6-02 defect.
  - F3: manager-local save-file creation/deletion provenance remains unresolved. Pre-existing and out of scope; not introduced by this UI change.
  - User visual approval: `APPROVED`. Approved scope: the Active-step highlight is visually acceptable for P6-02. Not approved: full application UI redesign, Completed/Submitted states, form controls, academic list, character preview, or submission/result pages.
  - Result: Reused the authoritative `step`; `_show_step()` refreshes the bar; exactly one of the four application steps is Active; forward/back mappings remain correct; form, submit, save path, schema, and save timing were not changed.
  - Tests: 16 pure-logic checks passed; isolated-sandbox Godot 4.7 editor parse and smoke exited 0.
  - Skills: `task-baseline-and-lock`, `characterization-first-refactor`, `save-integrity-guard` — all remain `TRIAL` (with real field evidence; no registry maturity upgrade).
  - Next: P6-03 not started; no push or tag.

## File Locks

No file locks.

## Pending Handoffs

No pending handoffs.

## Earlier Recently Closed

### P6-01 - Agent Collaboration Bootstrap and First Field Validation

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `Claude Code`
- Reviewer verdict: `PASS_WITH_REQUIRED_GOVERNANCE_CORRECTION`
- Base commit: `0d1d423`; premature close-out commit preserved: `6c0dff9`
- Result: P6-01 was verified after a corrective governance close-out. The original `6c0dff9` commit preserved accurate field evidence but prematurely recorded Reviewer PASS and DONE before the real review occurred.
- Correction: User authorized a committed-range review of `0d1d423..6c0dff9`. Claude Code completed the real read-only review, and Codex applied the required governance corrections in this follow-up commit.
- Maturity: All five formal Skills remain `TRIAL`.
- Next: P6-02 READY, not started.


### P5-08 - Post-Tag Governance State Synchronization

- Status: `DONE`
- Owner: `Codex`
- Reviewer: `User`
- Base commit: `4de284f`
- Result: Governance documents synchronized with the completed Phase 5 push, completion tag, and successful Agent bootstrap validations.
- Verification: Documentation-only diff; Godot editor/smoke passed using `C:\Users\csw83\Documents\Codex\tools\Godot_v4.7-stable_win64_console.exe` (4.7.stable.official.5b4e0cb0f); user-data integrity remained stable; Phase 6 remains READY and not started.

### P5-07 - Phase 5 Skill Suite Validation and Closure

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `9e6e166`
- Result: The five-Skill suite was validated, session bootstrap guidance was established, controlled trial evidence and maturity boundaries were confirmed, and Phase 5 was formally closed. No new Skill was created; no Skill was upgraded from `TRIAL` to `VALIDATED`.
- Deliverables: `docs/governance/PHASE_5_CLOSURE_REPORT.md`, `docs/handoff/AGENT_SESSION_BOOTSTRAP.md`; updated `PHASE_5_SKILL_ARCHITECTURE_AUDIT.md`, `CLEANUP_PLAN.md`, `CURRENT.md`, `ACTIVE_TASKS.md`, `skills/SKILL_REGISTRY.md`.
- Verification: Registry/filesystem consistency (`REGISTRY_MATCH`, 5/5), metadata, responsibility boundaries, composition model, dry-run evidence, static checks (no `VALIDATED`, no local paths, no short-lived git state), and Godot editor/smoke (EXIT 0) all passed; no stray saves; all Skills remain `TRIAL`; diff limited to Markdown; no production code/tests/scenes/assets/JSON/`project.godot`/saves changed.
- Decision: Phase 5 = COMPLETE; Phase 6 (`Agent Collaboration and Skill Field Validation`) = READY, not started.
- Next: separately authorized after P5-07 — push `main`, create the Phase 5 completion tag, start fresh Codex/Claude Code sessions, run read-only bootstrap acceptance, then enter Phase 6. Not pushed, not tagged, no session started in P5-07.

### P5-06 - Build Guanghan Art Review and Godot Handoff Skill

- Status: `DONE`
- Owner: `Claude Code`
- Reviewer: `User`
- Base commit: `4f9359a`
- Result: Created the fifth formal repository Skill and second Guanghan Project layer Skill (review-side): `skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`, registered it, and exercised it through a controlled dry run. **ChatGPT is the primary visual reviewer** (compares approved target / specs / screenshots; judges style, scale, pixel density, layering, occlusion, readability, state feedback, and modular-asset use; writes structured tickets and verdicts; does NOT read/modify code or judge state-machine/save/signal/Manager/collision correctness). **Codex / Claude Code are implementation recipients**; **User retains final acceptance**.
- Skill: `skills/guanghan/guanghan-art-review-and-godot-handoff/SKILL.md`
- Registry: `skills/SKILL_REGISTRY.md` (now 5 rows)
- Trial: `docs/governance/P5_06_GUANGHAN_ART_REVIEW_SKILL_TRIAL.md`
- Verification: Skill/dry-run checks passed; formal SKILL.md count = 5; only Markdown changed (no images/code/scenes/assets/JSON/`project.godot`/saves); `git diff --check` PASS; Godot editor parse EXIT 0; Godot headless smoke EXIT 0; no stray saves after smoke; maturity remains `TRIAL`.
- Decision: The dry run reviewed a described "full concept image imported as one background sprite" screenshot and concluded `FAIL` (not `PASS`); full-image import = `REFERENCE_ONLY_MISUSE` (P0); path occlusion = `OCCLUSION_ERROR` (P1); unreadable terminal = `READABILITY_ISSUE` (P1); three structured tickets (ART-001..003) with a code-correctness disclaimer and no code judgement.
- Next: P5-07 (do not start automatically); do not push or tag.

### P5-05 - Build Guanghan Art Design and Production Skill

- Status: `DONE`
- Owner: `Claude Code`
- Previous owner: `Codex`
- Transfer reason: Codex usage limit reached; system prohibited further editing or workaround. Same task (P5-05), not a re-implementation. Base commit `8baa382`; non-clean working tree with approved P5-05 drafts taken over.
- Reviewer: `User`
- Result: a project-specific art design and modular asset-production Skill (`skills/guanghan/guanghan-art-design-and-production/SKILL.md`) was created and trialed, with **ChatGPT as primary creative agent**, **Codex/Claude Code as implementation consumers**, and **User as final approver**. Claude Code completed the takeover by adding the explicit `Agent Responsibilities` section (+ agents-metadata clarification) and one missing cable/pipe asset row in the dry run; forbids using a full concept image as the shipped interactive map; modular breakdown for the spacesuit preparation room.
- Verification: Skill + dry-run checks passed; formal SKILL.md count = 4; only Markdown changed (no images/code/scenes/assets/JSON/`project.godot`/saves); Godot editor/smoke EXIT 0; maturity remains `TRIAL`.
- Follow-up: P5-06 Guanghan Art Review and Godot Handoff Skill — do not start automatically.
