# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-14 08:04 Europe/Warsaw

This is the single authoritative resume/checkpoint file for the Fantasy Grounds WFRP 1e project. Update this file in place instead of creating overlapping context documents.

## 1. Repository and authority

Writable Fantasy Grounds repository:
- `tuvielgaming/wfrp1e_FantsyGrounds`

Read-only reference repository — NEVER WRITE:
- `tuvielgaming/wfrp1ed_FoundryVTT`

Target:
- Fantasy Grounds Unity 5.1.13
- direct CoreRPG inheritance; no MoreCore

Authority order:
1. WFRP 1e Core Rulebooks = mechanics authority.
2. Foundry implementation = read-only architecture/spec/reference.
3. Fantasy Grounds implementation = project output.

Do not invent WFRP rules or FGU APIs. Inspect sources/docs first. Authentic WFRP 1e behavior takes precedence over modern convenience.

## 2. Required workflow

- Work one tested checkpoint at a time.
- User validates with `verified`, `next`, `continue`, or test feedback.
- `main` is the last verified state.
- New unverified work goes to a dedicated test branch + draft PR.
- Merge only after explicit FGU verification.
- Prefer GitHub changes over dumping replacement files into chat.
- If manual files are unavoidable: exact repository path + complete replacement file, never snippets.
- Never modify the Foundry repository.
- If context/source is missing, ask rather than hallucinate.

## 3. Frozen characteristic / Career / XP model

Characteristic order:
`M WS BS S T W I A Dex Ld Int Cl WP Fel`

Keys:
`m ws bs s t w i a dex ld int cl wp fel`

Advance step:
- `m s t w a` => +1
- all others => +10

Persistent characteristic fields:
- `initial`
- `purchased`
- `career`

Derived:
`current = initial + purchased * advanceStep`

Career semantics:
- purchased = total historical advances
- career = current Career ceiling
- purchased > career is valid
- buy only when purchased < career
- never clamp purchased on Career change
- assigning a Career copies all 14 career ceilings including zero

Character profile remains exactly three rows:
- STARTER PROFILE
- ADVANCE SCHEME
- CURRENT PROFILE

Current Career identity:
- `career.current.name`
- `career.current.link`

Experience persistence:
- `experience.totalAwarded`
- `experience.spent`
- Available = totalAwarded - spent

Visible Experience UI is Available-only. Manual edit of Available means:
`totalAwarded = spent + newAvailable`

Characteristic and later-Career Skill advances cost 100 XP.

## 4. Advancement edit transaction — frozen

One in-memory advancement transaction spans purchases while the same top-level Character sheet remains open.

Starts lazily on first successful purchase.

Characteristic refunds:
- Ctrl+Left refunds only advances bought during current transaction
- never below transaction baseline
- historical advances protected

Transaction survives tab switches.

Top-level Character close is the boundary, using:
```lua
Interface.addKeyedEventHandler(
    "onWindowClosing",
    "charsheet",
    onCharacterSheetClosing
)
```

After closing/reopening, persistent purchases remain but are no longer refundable.

Frozen characteristic header UX (#9F):
- no Career advance => plain abbreviation
- unfinished => `[+]`
- complete => custom check icon
- red marker = an action is possible now
- black marker = state present but no action possible
- green check = complete and refundable in current transaction
- black check = complete/static
- Left = buy
- Ctrl+Left = transaction refund
- whole 38x20 header is the hitbox

## 5. Skills domain — verified design

Skill record fields (#10A):
- `name`
- stable language-neutral `rulesId`
- `specialisation`
- `description`

Do NOT force all Skills into a generic characteristic/target/modifier schema. WFRP 1e Skills have rule-specific procedures.

Character-owned Skill acquisition (#10B):
- persistence: `skills.<unique id>`
- snapshot fields: name, rulesId, specialisation, description
- source link stored separately
- each acquisition is independent
- duplicate rulesId values are deliberate and valid
- later source edits do not rewrite the owned snapshot

Owned Skill removal (#10C):
- CoreRPG `<allowdelete />`
- removes only the selected acquisition
- source Skill and other duplicates remain

Career Skill Offers (#10D):
- Career has persistent SKILLS list
- each offer snapshots name, rulesId, specialisation and optional `chance`
- duplicate offers allowed
- source edits do not rewrite Career snapshot
- chance 0 displays blank
- chance is metadata only, not later-Career purchase eligibility

Later-Career Skill purchase (#10E):
- rulebooks confirm new Career Skills are not gained automatically
- each is acquired for 100 XP/PD
- old Skills are retained
- purchase state belongs to current Career offer instance, not global rulesId ownership
- current Character snapshots Career Skill offers
- successful purchase spends 100 XP and creates a normal owned Skill acquisition
- Ctrl+Left refunds only if bought in the current open Character transaction
- mixed Characteristic + Skill purchases share the same transaction accounting
- chance metadata never affects later-Career purchase eligibility

## 6. Repeated Skill acquisition foundation (#10F PASS)

Verified behavior:
- acquisition count is DERIVED from independent owned Skill rows grouped by stable `rulesId`
- no persistent rank/count field
- owned Skill tooltip exposes the derived acquisition count

Rule-specific repeated-acquisition modifier currently implemented only for:
- `pickLock`
- `pickPocket`

For those two Skills:
`repeat bonus = (acquisitions - 1) * 10%`

Verified examples:
- 1 acquisition => +0%
- 2 acquisitions => +10%
- 3 acquisitions => +20%
- deleting one owned copy decreases derived count/bonus immediately

Other repeated Skills such as Musicianship do NOT inherit that numeric modifier. Multiple acquisitions may instead broaden specialisations/coverage.

Read-only Foundry reference uses the same architectural principle: group owned Skill Items by stable rulesId and expose acquisition count to later rule resolution rather than persisting a universal rank.

#10F PR:
- PR #4 `#10F Skill acquisition-count foundation`
- verified head: `069abf237e34620986fd1f06e6f6e6851d6e442e`
- merged commit: `33a4046cbab961a32d616fd5d91c712eadb501c5`

## 7. Verified checkpoint history

- #1 CoreRPG skeleton — PASS
- #2 WFRP init — PASS
- #3 characteristic registry — PASS
- #4A/+4B characteristic advance/current model — PASS
- #5 first DB binding — PASS
- #6/#6B characteristic column + eligibility — PASS
- #7/#7A.2 full profile + final geometry — PASS
- #8A–#8D Career domain/persistence/assignment/link — PASS
- #9A–#9F Experience, advancement transaction, final inline advancement UX — PASS
- #10A Skill record — PASS
- #10B owned Skill acquisition — PASS
- #10C owned Skill removal — PASS
- #10D Career Skill Offer persistence — PASS
- #10E 100 XP current-Career Skill purchase/refund — PASS
- #10F repeated-acquisition count foundation — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — REMOVED; do not retry.

## 8. Rulebook conclusions already audited

Career changes / Skills:
- English Core Rulebook p. 92, “New Skills”
- Polish Core Rulebook p. 92, “Nowe Umiejętności”
- new Career Skills cost 100 XP/PD each and are not automatic

First-Career probability entries belong to character creation, not later-Career eligibility.

Repeated acquisition:
- Pick Lock and Pick Pocket: +10% for each additional acquisition
- Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisitions to add instruments/languages/weapon categories rather than receiving the same generic numeric rule

## 9. Current verified baseline

Current verified code baseline after #10F merge:
- `33a4046cbab961a32d616fd5d91c712eadb501c5`

This context-document update is metadata only and may make `main` one commit newer; code baseline above is the #10F merge.

Important current files include:
- `base.xml`
- `campaign/record_char_main_wfrp1e.xml`
- `campaign/record_char_career_skills_wfrp1e.xml`
- `campaign/record_career_wfrp1e.xml`
- `campaign/record_career_skills_wfrp1e.xml`
- `campaign/record_skill_wfrp1e.xml`
- `campaign/scripts/char_main_wfrp1e.lua`
- `campaign/scripts/char_characteristic_wfrp1e.lua`
- `campaign/scripts/char_experience_wfrp1e.lua`
- `campaign/scripts/char_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skills_layer_wfrp1e.lua`
- `scripts/manager_character_advancement_wfrp1e.lua`
- `scripts/manager_character_skill_wfrp1e.lua`
- `scripts/manager_character_career_wfrp1e.lua`
- `scripts/manager_character_experience_wfrp1e.lua`

## 10. Next checkpoint

#10G is NOT frozen yet.

Before implementing it:
1. inspect the WFRP 1e Standard Tests rules and Skill interactions in the English and Polish rulebooks;
2. inspect the read-only Foundry Standard Test data/resolver architecture;
3. choose one small testable foundation checkpoint rather than jumping directly to full Standard Test automation.

Likely direction: create the language-neutral Standard Test identity/data foundation that later Skill resolution can target, while keeping GM applicability decisions explicit and without adding a generic Skill-to-characteristic model.

Do not implement a full Standard Test roller, automatic universal Skill applicability, or broad rule registry in one step.
