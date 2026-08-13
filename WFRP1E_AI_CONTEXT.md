# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-13 20:21 Europe/Warsaw

This is the single authoritative resume/checkpoint file for the Fantasy Grounds WFRP 1e project. Update this file in place at the end of future sessions instead of creating multiple overlapping context documents.

## 1. Repository and source authority

Fantasy Grounds repository (WRITE):
- `tuvielgaming/wfrp1e_FantsyGrounds`

Foundry reference repository (READ ONLY — NEVER WRITE):
- `tuvielgaming/wfrp1ed_FoundryVTT`

Fantasy Grounds target:
- Fantasy Grounds Unity 5.1.13
- Ruleset inherits CoreRPG directly; do not use MoreCore.
- Local test installation: `<Fantasy Grounds Data Folder>/rulesets/WFRP1E/`

Rules authority:
- WFRP 1e Core Rulebooks are the mechanics authority.
- Foundry implementation is architecture/spec/reference only.
- Do not invent WFRP rules or FGU APIs. Inspect rulebooks / official FGU docs / source before changing mechanics.
- Original/authentic WFRP 1e behavior takes precedence over modern convenience.

Rulebook archive supplied during this session:
- `WFRP Core RuleBooks(20260813-172815).zip`
- In a new chat the archive may need to be re-uploaded if not available.

## 2. Required working method

- Work incrementally, one tested checkpoint at a time.
- User validates with `verified`, `next`, `continue`, or test feedback.
- Do not jump multiple architecture stages.
- `main` should normally represent the last verified state.
- New/unverified work normally goes to a dedicated test branch and is merged only after FGU verification.
- Git pushes are preferred over dumping replacement files into chat.
- If a file must be returned manually, provide exact repository path and the COMPLETE replacement file, never a patch/snippet.
- Do not modify the Foundry repository.
- If context is missing, ask for the source/project files rather than hallucinating.
- Avoid multiple documents describing the same topic; this file is the authoritative resume document.

Important exception at end of this session:
- #10E was accidentally merged to `main` BEFORE FGU verification.
- Therefore the current `main` is NOT fully verified yet.
- Last fully verified code baseline is #10D commit `08de1e8969b18029e4dbe8e8ef3c46c5c04e3cd3`.
- Current code head before this context-document commit was `c10d2c6b5aaa83671ba4faafb581f629d6521709`.
- `c10d2...` contains #10E code plus removal of the accidental temporary `10E.patch` transport file.
- Do NOT treat #10E as PASS until the user tests it in FGU.

## 3. Frozen characteristic model

Characteristic order:
`M WS BS S T W I A Dex Ld Int Cl WP Fel`

Database keys:
`m ws bs s t w i a dex ld int cl wp fel`

Advance steps:
- `m s t w a` => +1 per purchased advance
- all others => +10 per purchased advance

Persistent per characteristic:
- `initial`
- `purchased`
- `career`

Derived:
- `current = initial + purchased * advanceStep`
- formatted Advance Scheme
- purchase availability

Career semantics:
- `purchased` = total historical advances
- `career` = current Career ceiling
- `purchased > career` is valid after Career changes
- can buy only when `purchased < career`
- never clamp purchased to current Career ceiling
- assigning Career copies all 14 values including zeros

Advance Scheme formatting:
- career=0 => blank
- step10: 1 => `+10`, 2 => `+20`, etc.
- step1: 1 => `+1`, 2 => `+2`, etc.

Wounds:
- characteristic W is maximum Wounds
- remaining Wounds/damage must be a separate later subsystem

Frozen characteristic UI geometry (#7A.2):
- row label x=15 width=145
- grid x=165
- characteristic column width=38
- 14 columns => 532 px
- grid edge x=697

Frozen character profile layout:
- exactly 3 rows: STARTER PROFILE / ADVANCE SCHEME / CURRENT PROFILE
- no permanent fourth advancement row

## 4. Career and Experience foundations

Career record persistent Advance Scheme:
- `advancescheme.<char>.steps`

Character current Career identity:
- `career.current.name`
- `career.current.link`

Experience ledger:
- `experience.totalAwarded`
- `experience.spent`
- derived `available = totalAwarded - spent`

Final visible Experience UI:
- Available-only
- manual edit of Available means `totalAwarded = spent + newAvailable`
- old TOTAL AWARDED/SPENT/AVAILABLE diagnostic layout rejected

Advance cost:
- 100 XP for both +1 and +10 characteristic advances

FGU focus behavior:
- before advancement actions, code clears `experience.subwindow.available` focus
- two full-window blur-overlay experiments were rejected; DO NOT retry them

## 5. Advancement edit transaction (verified)

A single in-memory transaction spans multiple advancement purchases while the same top-level Character sheet is open.

Starts lazily on first successful purchase.

Characteristic transaction state includes baseline spent/purchased values and per-characteristic deltas.

Ctrl+Left refunds only advances bought during the current transaction.
Historical advances are protected.

Transaction survives Character tab switches.

CoreRPG Character sheets soft-close, so `charsheet_main.onClose()` is NOT the transaction boundary.

Global boundary uses:
```lua
Interface.addKeyedEventHandler(
    "onWindowClosing",
    "charsheet",
    onCharacterSheetClosing
)
```

Closing the top-level Character sheet ends the transaction. Reopening leaves persistent purchases in place but they are no longer refundable.

## 6. Frozen inline advancement UX (#9F PASS)

Header states:
- `WS` = no advancement in current Career
- `WS [+]` = unfinished current-Career requirement
- `WS` + check icon = requirement satisfied

Color indicates current actionability, symbol indicates state:
- red `[+]` = unfinished and at least one current action (buy/refund) is possible
- black `[+]` = unfinished and no current action possible
- green check = complete but refundable during current transaction
- black check = complete/static, no current action

Special case:
- insufficient XP but refundable => red `[+]` because refund remains actionable

Interaction:
- whole 38x20 characteristic header is hitbox
- Left = buy
- Ctrl+Left = transaction refund
- no separate +/- buttons
- no right-click refund
- if completing during transaction, show completion check but remain logically Ctrl-refundable
- historically complete and not refundable => static/nonclickable

Completion check uses custom icon resource:
- `wfrp1e_char_advancement_complete_icon`
- explicit `<icon ... file="graphics/icons/wfrp1e_advancement_check.png" />`

Global Experience DB observers live at Character-sheet level and refresh all 14 characteristic headers. This was explicitly verified; do not regress to per-row-only XP refresh.

## 7. Verified checkpoint history through Skills

Earlier checkpoints #1–#9D.1: PASS except rejected #9C.1 focus-overlay experiment.

#9E: PASS
- inline characteristic advancement header states implemented

#9F: PASS
- final inline marker colors, spacing, and custom completion icon
- merged to main previously

#10A: PASS — Skill record data contract
Skill record fields:
- `name`
- stable `rulesId`
- `specialisation`
- `description`

Rules design:
- do NOT model every Skill as generic characteristic/target/modifier
- Skills can have individual procedures
- duplicate `rulesId` acquisitions are deliberately possible

#10B: PASS — Character-owned Skill acquisitions
Character path:
- `skills.<unique id>`

Snapshot fields:
- name
- rulesId
- specialisation
- description
- source link

Semantics:
- each acquisition is a separate instance
- duplicate rulesId values allowed
- source edits do not rewrite owned snapshot
- link opens current live source Skill

#10C: PASS — remove one owned Skill acquisition
- Character Skills windowlist uses CoreRPG-native `<allowdelete />`
- removes only selected owned acquisition
- source Skill remains
- other duplicate acquisitions remain

#10D: PASS — Career Skill Offers persistence
Last fully verified code baseline commit:
- `08de1e8969b18029e4dbe8e8ef3c46c5c04e3cd3`

Career gets SKILLS list.
Each Career Skill Offer stores/copies:
- name
- rulesId
- specialisation
- optional chance percentage metadata

Career Skill Offer UI:
- native `windowlist <acceptdrop>` copies Skill fields
- duplicate offers allowed
- source Skill changes do not rewrite Career snapshot
- chance 0 displays blank
- chance values such as 25/50 persist

`chance` is metadata only. It is NOT later-Career purchase eligibility.

## 8. Rulebook conclusions for Career Skills

Both English and Polish Core Rulebooks confirm:
- when changing Career, new Career Skills are NOT gained automatically
- each new Skill is acquired like a characteristic advance for 100 XP/PD
- old Skills are retained

Relevant section confirmed during session:
- English Core Rulebook p. 92, “New Skills”
- Polish Core Rulebook p. 92, “Nowe Umiejętności”

The percentage entries belong to first-Career character creation (e.g. English p. 19), not to later-Career purchase eligibility.

Repeated acquisition matters in WFRP 1e:
- Pick Lock / Pick Pocket can gain +10% per additional acquisition
- Musicianship / Speak Additional Language / Specialist Weapon can repeat to add specialisations/categories

Therefore do NOT globally block a Career Skill purchase just because the Character already owns the same rulesId historically. Purchase state must be associated with the current Career offer instance.

## 9. #10E — CURRENT STATE: IMPLEMENTED ON MAIN, NOT YET FGU-VERIFIED

This is the immediate next task when resuming.

Current `main` contains #10E code, but user ended the session before testing it.

#10E goal:
- Career Skill offered by current Career can be acquired for 100 XP
- later-Career Skills are not automatically granted
- purchase creates a normal owned Character Skill snapshot
- purchase/refund participates in the same Character-sheet edit transaction as characteristic advances

Files introduced/changed by #10E relative to verified #10D:
- `base.xml` (+ include)
- `campaign/record_career_skills_wfrp1e.xml` (+ description copied on Career Skill drop)
- `campaign/record_char_career_skills_wfrp1e.xml` (new)
- `campaign/scripts/char_career_skill_wfrp1e.lua` (new)
- `campaign/scripts/char_career_skills_layer_wfrp1e.lua` (new)

Temporary transport file `10E.patch` was accidentally committed by the user and then removed from main in cleanup commit:
- `c10d2c6b5aaa83671ba4faafb581f629d6521709`

Do not re-add `10E.patch`.

#10E Character-side model:
- current Career Skill offers are snapshotted for the Character
- current Career points to the active snapshot via `career.current.skillsPath`
- per-offer persistent state includes:
  - name
  - rulesId
  - specialisation
  - chance
  - description
  - purchased (0/1)
- Career source identity is recorded so reopening the sheet reuses the same snapshot instead of rewriting from later source edits
- old snapshots are preserved rather than destructively deleted

#10E interaction intent:
- `[+]` = not yet acquired from current Career offer
- Left click => acquire for 100 XP if available
- successful purchase:
  - spends 100 XP
  - creates owned Character Skill under `character.skills.<unique id>`
  - sets offer purchased=1
  - participates in current advancement edit transaction
- completion marker uses same custom check icon as characteristic advancement
- Ctrl+Left => refund only if this Skill was bought in the current still-open Character transaction
- closing/reopening Character sheet ends refundability while preserving purchase
- insufficient XP blocks buy
- chance metadata must not affect buy eligibility

Important transaction requirement:
- mixed purchases must remain coherent, e.g. Characteristic -> Skill -> Characteristic
- refunding current-transaction Skill must restore 100 XP and remove only the owned Skill created by that transaction purchase
- characteristic refund behavior must still work in same mixed transaction

## 10. #10E FGU TEST CHECKLIST — DO THIS FIRST NEXT SESSION

Before any new implementation, pull current `main` and test #10E.

Test at least:
1. No XML/Lua/console errors on ruleset load.
2. Assign a Career with Skill offers to a Character.
3. CURRENT CAREER SKILLS appears below normal owned Skills.
4. Career Skill offers show correct name/specialisation/chance metadata.
5. No Skill is automatically added to owned Character Skills merely by Career assignment.
6. With >=100 XP available, left-click `[+]` on one Career Skill:
   - Available XP decreases by 100
   - one owned Skill appears in normal Character Skills
   - offer becomes complete/check state
7. Try purchasing same current-Career offer again: must not create another copy.
8. If Character already had same rulesId historically before Career assignment, current Career offer must still be purchasable once.
9. With <100 available XP, pending offer must not be purchasable.
10. During same open Character sheet, Ctrl+Left the just-bought Skill:
   - owned acquisition created by this purchase disappears
   - 100 XP is restored
   - offer returns to pending
11. Buy again, close Character sheet, reopen:
   - purchase persists
   - it is no longer refundable
12. Mixed transaction regression:
   - buy a characteristic advance
   - buy a Career Skill
   - buy another characteristic advance
   - refund the current-transaction Skill and/or characteristics
   - XP ledger and characteristic purchased counts remain coherent
13. Re-test ordinary manual Character Skill drag/drop and deletion (#10B/#10C) still work.
14. Re-test Career assignment and characteristic headers (#9F) still work.

If all pass, mark #10E PASS. Because #10E is already on main, no merge is needed; simply record the verified main commit in this file.

If #10E fails:
- DO NOT treat main as verified.
- Last verified code rollback/reference point remains:
  `08de1e8969b18029e4dbe8e8ef3c46c5c04e3cd3` (#10D PASS)
- Fix #10E on a dedicated branch from the appropriate point; do not continue to #10F until #10E passes.

## 11. What NOT to implement yet

Until #10E is verified, do not continue into:
- repeated-acquisition mechanical bonuses (+10% etc.)
- Standard Test automation
- generic Skill characteristic mapping
- Skill test rolling
- first-Career random/probability generation mechanics
- final polished Skills sheet redesign

## 12. Current key source files

Core project files include:
- `base.xml`
- `campaign/record_char_main_wfrp1e.xml`
- `campaign/record_career_wfrp1e.xml`
- `campaign/record_career_skills_wfrp1e.xml`
- `campaign/record_skill_wfrp1e.xml`
- `campaign/record_char_career_skills_wfrp1e.xml`
- `campaign/scripts/char_main_wfrp1e.lua`
- `campaign/scripts/char_characteristic_wfrp1e.lua`
- `campaign/scripts/char_experience_wfrp1e.lua`
- `campaign/scripts/char_career_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skills_layer_wfrp1e.lua`
- `campaign/scripts/career_main_wfrp1e.lua`
- `scripts/manager_character_advancement_wfrp1e.lua`
- `scripts/manager_character_skill_wfrp1e.lua`
- `scripts/manager_character_career_wfrp1e.lua`
- `scripts/manager_character_experience_wfrp1e.lua`
- `scripts/manager_career_db_wfrp1e.lua`
- `graphics/graphics_wfrp1e.xml`
- `graphics/icons/wfrp1e_advancement_check.png`
- `strings/strings_wfrp1e.xml`

## 13. Resume instruction for next chat

Start by reading this entire file and inspecting current `main`.
Do not redesign already frozen mechanics.
Do not assume #10E passed: the first action is FGU verification using the checklist above.
Only after user says `verified` should #10E be frozen as PASS and the next checkpoint be planned.
