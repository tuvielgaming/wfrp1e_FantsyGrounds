# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-14 07:12 Europe/Warsaw

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

Rulebook archive supplied in conversation:
- `WFRP Core RuleBooks(20260813-172815).zip`
- In a new chat the archive may need to be re-uploaded if not available.

## 2. Required working method

- Work incrementally, one tested checkpoint at a time.
- User validates with `verified`, `next`, `continue`, or test feedback.
- Do not jump multiple architecture stages.
- `main` should represent the last verified state.
- New/unverified work normally goes to a dedicated test branch and is merged only after FGU verification.
- Git pushes are preferred over dumping replacement files into chat.
- If a file must be returned manually, provide exact repository path and the COMPLETE replacement file, never a snippet.
- Do not modify the Foundry repository.
- If context is missing, ask for the source/project files rather than hallucinating.
- Avoid multiple documents describing the same topic; this file is the authoritative resume document.

Historical workflow exception:
- #10E was accidentally merged to `main` before FGU verification.
- The user later completed the full #10E FGU verification and explicitly reported it verified on 2026-08-14.
- Therefore #10E is now PASS and `main` is again the verified baseline.
- Temporary transport file `10E.patch` was removed and must not be re-added.

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
- 100 XP for each later-Career Skill acquisition

FGU focus behavior:
- before advancement actions, code clears `experience.subwindow.available` focus
- two full-window blur-overlay experiments were rejected; DO NOT retry them

## 5. Advancement edit transaction (verified)

A single in-memory transaction spans multiple advancement purchases while the same top-level Character sheet is open.

Starts lazily on first successful purchase.

Characteristic and Career-Skill purchases share the same Experience ledger and transaction lifetime.

Ctrl+Left refunds only advances/Skills bought during the current transaction.
Historical purchases are protected.

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

Mixed characteristic + Career-Skill purchase/refund sequences were verified under #10E.

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
Career gets SKILLS list.
Each Career Skill Offer stores/copies:
- name
- rulesId
- specialisation
- description
- optional chance percentage metadata

Career Skill Offer UI:
- native `windowlist <acceptdrop>` copies Skill fields
- duplicate offers allowed
- source Skill changes do not rewrite Career snapshot
- chance 0 displays blank
- chance values such as 25/50 persist

`chance` is metadata only. It is NOT later-Career purchase eligibility.

#10E: PASS — Current Career Skill purchase for 100 XP
Verified by user in FGU on 2026-08-14.

Behavior verified:
- assigning Career does not automatically grant Skills
- CURRENT CAREER SKILLS shows current Career offers
- each current-Career offer can be purchased once for 100 XP
- purchase creates one normal owned Character Skill snapshot
- same `rulesId` already owned historically does not block a current-Career offer purchase
- insufficient XP blocks purchase
- Ctrl+Left refunds only a Skill bought during the current open Character-sheet transaction
- refund restores 100 XP and removes only the owned acquisition created by that purchase
- closing/reopening Character sheet preserves the purchase but ends refundability
- mixed characteristic + Career-Skill transactions remain coherent
- ordinary manual Skill drag/drop/deletion still works
- Career assignment and characteristic advancement headers still work

#10E files:
- `base.xml`
- `campaign/record_career_skills_wfrp1e.xml`
- `campaign/record_char_career_skills_wfrp1e.xml`
- `campaign/scripts/char_career_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skills_layer_wfrp1e.lua`

#10E Character-side model:
- current Career Skill offers are snapshotted for the Character
- current Career points to the active snapshot via `career.current.skillsPath`
- per-offer persistent state:
  - name
  - rulesId
  - specialisation
  - chance
  - description
  - purchased (0/1)
- source Career identity is recorded so reopening reuses the same snapshot instead of rewriting from later source edits
- old snapshots are preserved rather than destructively deleted

## 8. Rulebook conclusions for Career Skills and repetition

Both English and Polish Core Rulebooks confirm:
- when changing Career, new Career Skills are NOT gained automatically
- each new Skill is acquired like a characteristic advance for 100 XP/PD
- old Skills are retained

Relevant section confirmed:
- English Core Rulebook p. 92, “New Skills”
- Polish Core Rulebook p. 92, “Nowe Umiejętności”

The percentage entries belong to first-Career character creation (e.g. English p. 19), not to later-Career purchase eligibility.

Repeated acquisition matters in WFRP 1e:
- Pick Lock / Pick Pocket can gain +10% per additional acquisition
- Musicianship / Speak Additional Language / Specialist Weapon can repeat to add specialisations/categories

Therefore:
- do NOT globally block a Career Skill purchase because the Character already owns the same rulesId
- one owned acquisition instance must remain independently represented
- repeated-acquisition mechanics must be rule-specific, not one universal generic rank bonus

## 9. Current verified baseline

#10E is PASS.

Verified code state before context-only commits:
- `c10d2c6b5aaa83671ba4faafb581f629d6521709`

Context-only commits after that do not change ruleset behavior.

At the time this file was updated, `main` contains the verified #10E code and is the correct baseline for the next checkpoint.

Temporary transport file `10E.patch` was removed and must not be re-added.

## 10. Next checkpoint candidate — #10F

Do a source pass before implementation.

Primary candidate:
- repeated-acquisition mechanics / acquisition-count foundation

Do NOT assume one universal effect for every repeated Skill.

Likely smallest safe scope:
- provide a stable way to count owned acquisitions by `rulesId`
- expose that count to rule-specific Skill mechanics
- implement only the explicitly confirmed repeat-bonus Skills if the rulebook/source pass supports doing so cleanly

Need to inspect before coding:
- English and Polish Skill descriptions for repeated acquisition semantics
- read-only Foundry `StandardTestSkillResolver` and skill-rule identities/rules
- current Character Skill manager and any future Standard Test dependency

Do not jump directly into generic Skill test rolling.

## 11. Still deferred

Do not implement without a dedicated checkpoint/source pass:
- Standard Test automation
- generic Skill characteristic mapping
- full Skill test rolling
- first-Career random/probability generation mechanics
- final polished Skills sheet redesign
- remaining Wounds/damage subsystem

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
#10E is verified PASS.
Continue with a source-first #10F checkpoint from current verified `main`.
