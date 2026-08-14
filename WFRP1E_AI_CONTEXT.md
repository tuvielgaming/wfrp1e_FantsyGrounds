# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-14 11:53 Europe/Warsaw

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

## 7. Standard Test data foundation (#10G PASS)

Rulebook boundary audited before implementation:
- named Standard Tests use the same ordinary percentile-test principle, with their base characteristic/formula defined by the Standard Tests table/procedure
- Skills listed for a Standard Test are potentially relevant, not automatically applicable
- the GM decides which listed Skills make sense in the actual situation
- when more than one appropriate Skill applies, their modifiers can be cumulative
- some Skill combinations are mutually exclusive and still require GM judgement

Verified implementation:
- `scripts/data_standard_tests_wfrp1e.lua` is descriptive/non-executable data only
- stable language-neutral named Standard Test IDs
- each registered definition may expose:
  - `characteristic` for a direct percentage-characteristic base
  - `formula` for a formula/situational base requiring later resolution
  - `skills` as candidate Skill `rulesId` values only
  - `defaultModifier`
  - `tags` for runtime requirements/audit metadata
- procedure-heavy Standard Tests that do not fit this small contract remain intentionally unregistered until dedicated audited execution contracts exist
- no automatic Skill applicability
- no formula/target/noise/lock-difficulty evaluation
- no rolling

Public data helpers currently include:
- `getNamedStandardTestDefinition(testId)`
- `getNamedStandardTestIds()`
- `isPotentialSkillForTest(testId, rulesId)`
- `getPotentialStandardTestsForSkill(rulesId)`

Owned Skill tooltip exposes `Potential Standard Tests: ...` by stable test ID as a diagnostic validation surface while preserving #10F acquisition-count/repeat-bonus information.

Verified tooltip examples:
- `pickLock` => `pickLock`
- `pickPocket` => `pickPocket`
- `charm` => `bargain, bluff, gossip`
- `bribery` => `bribe, gossip, loyalty`
- `musicianship` => no Potential Standard Tests line in the current registry

Representative stored bases:
- direct characteristic: `fel`, `dex`, `int`, `cl`, `wp`, etc.
- `100 - target.wp`
- `i + cl - target.i`
- `dex - lockDifficulty`
- `t * 10`
- fixed `50`
- situational `noise`

#10G PR:
- PR #5 `#10G Standard Test data foundation`
- verified head: `6f7bd66bafe4bc4950a970c159a0896b00aea47b`
- merged commit: `adbfba1f306611ec8c9a5a6d009c30116829bc00`

## 8. Standard Test base-target resolver (#10H PASS)

Verified implementation:
- `scripts/manager_standard_test_wfrp1e.lua`
- resolves only a named Standard Test BASE target that can be derived from Character data without situational inputs
- reuses `CharacteristicManagerWFRP1E.calculateCurrent(...)`; does not create a second Current calculation path
- direct-characteristic tests resolve to that Character's Current characteristic
- audited non-percentage self-only bases resolve as:
  - `s * 10` => Current S × 10
  - `t * 10` => Current T × 10
- fixed `50` resolves directly to 50
- context-dependent formulas such as `100 - target.wp`, `i + cl - target.i`, `dex - lockDifficulty`, and `noise` explicitly return `context-required`
- no generic formula parser
- no Skill applicability decision
- no Skill modifiers
- no situational modifiers
- no dice roll

Owned Skill tooltip diagnostic additionally shows:
- `Resolved base targets (no Skill bonus): ...` for locally resolvable potential tests
- `Context required: ...` for potential tests that need external/situational input

Verified examples:
- `charm` with Current Fel 42 => bargain 42%, bluff 42%, gossip 42%
- `pickPocket` => Current Dex
- `immunityToDisease` with Current T 4 => disease 40%
- `pickLock` => context-required rather than guessing lock difficulty
- `bribery` => bribe context-required while gossip/loyalty resolve from Current Fel/Ld

#10H PR:
- PR #6 `#10H Standard Test base-target resolver`
- verified head: `05437f824d6a4a0cf1db30405a87e48b6875d821`
- merged commit: `4b3d1fb0ab75415685c3d173262fb90ce1db6768`

## 9. Plain d100 Standard Test roll (#10I PASS)

Mechanics audited from WFRP 1e Basic Test Procedure:
- roll D100
- success when roll is less than or equal to the percentage chance
- equality is therefore success

Verified implementation:
- `StandardTestManagerWFRP1E` owns the executable roll lifecycle/result
- only already-locally-resolved #10H BASE targets can be rolled
- temporary explicit launch surface: Ctrl+Double-click an owned Skill name
- launch is offered only when that Skill maps to exactly ONE potential named Standard Test and that test's BASE target resolves locally
- ambiguous Skills such as Charm do not auto-select Bargain/Bluff/Gossip
- context-required Skills such as Pick Lock do not roll
- no Skill modifier is applied yet, including no Pick Pocket repeated-acquisition bonus
- no situational modifiers, context-dependent formula resolution, margins/degrees, opposed tests or effects
- result chat reports Character, test ID, roll, target, success/failure, and explicitly says Skill modifiers are not applied

FGU API behavior verified in runtime:
- custom roll uses documented `Comm.throwDice`
- result is handled by keyed `onDiceLanded`
- custom data carries test ID/target/Character name
- landed dice total supplies the D100 result
- chat uses documented `Comm.deliverChatMessage`
- IMPORTANT percentile construction: pass only `{ "d100" }`
- FGU automatically adds the companion d10 for a percentile roll
- passing `{ "d100", "d10" }` produced an erroneous extra d10 and was rejected during testing
- corrected `{ "d100" }` behavior was verified: exactly the normal percentile pair and correct 1–100 result

Verified runtime boundaries:
- Pick Pocket rolls against BASE Current Dex only
- a second Pick Pocket acquisition can display #10F +10%, but #10I deliberately does not apply it yet
- Immunity to Disease uses T × 10 BASE target
- Pick Lock stays blocked because lock difficulty is context-required
- Charm stays blocked because its named Standard Test choice is ambiguous
- rolling does not alter XP, Skills, characteristics or Career data

#10I PR:
- PR #7 `#10I Plain d100 Standard Test roll`
- initial test head: `9962c3e39d214a68735f4cafc707c315e67b1fad`
- corrective percentile head: `51c5e704eb5afa56c5113a5ddeaba37b6e6d07d2`
- merged commit: `91ff79ec3a70a2ddd80574bae222b6a32b85f5bf`

## 10. Verified checkpoint history

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
- #10G Standard Test data foundation — PASS
- #10H Standard Test base-target resolver — PASS
- #10I plain d100 Standard Test roll — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — REMOVED; do not retry.

## 11. Rulebook conclusions already audited

Career changes / Skills:
- English Core Rulebook p. 92, “New Skills”
- Polish Core Rulebook p. 92, “Nowe Umiejętności”
- new Career Skills cost 100 XP/PD each and are not automatic

First-Career probability entries belong to character creation, not later-Career eligibility.

Repeated acquisition:
- Pick Lock and Pick Pocket: +10% for each additional acquisition
- Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisitions to add instruments/languages/weapon categories rather than receiving the same generic numeric rule

Standard Tests:
- English and Polish Standard Tests sections were audited before #10G
- named Standard Tests define the tested characteristic/base procedure
- listed Skills are candidates; GM determines actual applicability
- appropriate Skill bonuses may stack, subject to rule-specific/mutually-exclusive combinations
- Basic Test success is `D100 <= final percentage chance`
- therefore Standard Test identity/base data, Skill applicability/modification, situational modification and execution remain separate concerns

## 12. Current verified baseline

Current verified code baseline after #10I merge:
- `91ff79ec3a70a2ddd80574bae222b6a32b85f5bf`

This context-document update is metadata only and may make `main` one commit newer; code baseline above is the #10I merge.

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
- `scripts/data_standard_tests_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`
- `scripts/manager_character_advancement_wfrp1e.lua`
- `scripts/manager_character_skill_wfrp1e.lua`
- `scripts/manager_character_career_wfrp1e.lua`
- `scripts/manager_character_experience_wfrp1e.lua`

## 13. Next checkpoint

#10J is NOT frozen yet.

Before applying any Skill modifier to the executable Standard Test roll:
1. re-audit the relevant WFRP 1e Skill descriptions and Standard Test text for the exact modifier supplied by possession/acquisition of a Skill;
2. distinguish a Skill's ordinary modifier from repeated-acquisition effects such as Pick Lock/Pick Pocket additional +10%s;
3. inspect the read-only Foundry Skill-rule resolver for architecture only;
4. preserve the Core Rulebook rule that listed Skills are only potentially relevant and actual applicability is a GM/player decision.

Preferred next boundary:
- derive the modifier for one explicitly chosen owned Skill against one named Standard Test
- use the clicked Skill as the explicit applicability choice rather than auto-applying every candidate Skill
- keep ambiguous test selection, mutually-exclusive Skill combinations, situational modifiers and context-required formulas out of scope until separately audited
- only after that diagnostic/modifier resolution is verified should the modifier be fed into the actual #10I roll target
