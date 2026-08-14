# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-14 22:39 Europe/Warsaw

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
- new Career Skills are not gained automatically
- each later-Career Skill costs 100 XP/PD
- old Skills are retained
- purchase state belongs to the current Career offer instance, not global rulesId ownership
- Character snapshots current Career Skill offers
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

Read-only Foundry reference uses the same architectural principle: group owned Skill Items by stable rulesId and expose acquisition count rather than persisting a universal rank.

#10F PR:
- PR #4
- verified head: `069abf237e34620986fd1f06e6f6e6851d6e442e`
- merged commit: `33a4046cbab961a32d616fd5d91c712eadb501c5`

## 7. Standard Test data foundation (#10G PASS)

Rulebook boundary:
- named Standard Tests define a base characteristic/formula/procedure
- listed Skills are potentially relevant, not automatically applicable
- GM decides actual applicability
- multiple appropriate Skill modifiers can stack when rules allow it
- some combinations are mutually exclusive and require GM judgement

Verified implementation:
- `scripts/data_standard_tests_wfrp1e.lua` is descriptive/non-executable data
- stable language-neutral Standard Test IDs
- fields may include `characteristic`, `formula`, candidate `skills`, `defaultModifier`, and tags
- procedure-heavy tests remain intentionally unregistered until dedicated contracts exist
- no automatic Skill applicability
- no generic formula parser

Representative registered bases:
- direct characteristic: `fel`, `dex`, `int`, `cl`, `wp`, etc.
- `100 - target.wp`
- `i + cl - target.i`
- `dex - lockDifficulty`
- `t * 10`
- fixed `50`
- situational `noise`

Owned Skill tooltip exposes `Potential Standard Tests: ...` by stable test ID.

#10G PR:
- PR #5
- verified head: `6f7bd66bafe4bc4950a970c159a0896b00aea47b`
- merged commit: `adbfba1f306611ec8c9a5a6d009c30116829bc00`

## 8. Standard Test base-target resolver (#10H PASS)

Verified implementation:
- `scripts/manager_standard_test_wfrp1e.lua`
- reuses `CharacteristicManagerWFRP1E.calculateCurrent(...)`
- direct-characteristic tests resolve to Character Current
- `s * 10` => Current S × 10
- `t * 10` => Current T × 10
- fixed `50` => 50
- context-dependent formulas such as target WP/Initiative, lock difficulty and noise return `context-required`
- no generic formula parser
- no Skill modifier or roll in the #10H layer itself

Tooltip diagnostic shows:
- `Resolved base targets (no Skill bonus): ...`
- `Context required: ...`

Verified examples:
- Charm with Fel 42 => Bargain/Bluff/Gossip base 42
- Pick Pocket => Current Dex
- Immunity to Disease with T 4 => Disease base 40
- Pick Lock => context-required

#10H PR:
- PR #6
- verified head: `05437f824d6a4a0cf1db30405a87e48b6875d821`
- merged commit: `4b3d1fb0ab75415685c3d173262fb90ce1db6768`

## 9. Plain d100 Standard Test roll (#10I PASS)

Mechanics:
- Basic Test success is `D100 <= percentage chance`
- equality is success

Verified FGU implementation:
- `StandardTestManagerWFRP1E` owns the executable roll lifecycle/result
- temporary explicit launch surface: Ctrl+Double-click an owned Skill name
- launch only when the Skill maps to exactly one potential named Standard Test and its base target resolves locally
- ambiguous Skills such as Charm do not auto-select a test
- context-required Skills such as Pick Lock do not roll
- uses documented `Comm.throwDice`, keyed `onDiceLanded`, custom roll data, landed total, and chat delivery
- IMPORTANT percentile construction: pass only `{ "d100" }`; FGU adds the companion d10 automatically
- the rejected `{ "d100", "d10" }` form produced one extra d10 in runtime

#10I PR:
- PR #7
- corrected verified head: `51c5e704eb5afa56c5113a5ddeaba37b6e6d07d2`
- merged commit: `91ff79ec3a70a2ddd80574bae222b6a32b85f5bf`

## 10. Selected Skill modifier resolver (#10J PASS)

Frozen rule conclusions:
- there is NO universal `owned Skill = +10%` rule
- the clicked/selected owned Skill is the explicit applicability choice in the current UI slice
- Charm gives +10% to Bargain, Bluff and Gossip when applicable
- Immunity to Disease gives +10% to Disease
- Pick Lock/Pick Pocket gain +10% per ADDITIONAL acquisition; first acquisition contributes +0% through this effect
- Pick Pocket has a separate unskilled -30% rule not yet implemented
- Pick Lock possession gates the attempt; lock difficulty remains context-required

Verified implementation:
- `scripts/data_standard_test_skill_effects_wfrp1e.lua`
- audited context-free numeric Skill effects only
- `resolveSelectedSkillModifier(nodeChar, rulesId, testId)` validates candidacy and resolves fixed or repeated-acquisition numeric effects
- no automatic candidate Skill selection
- tooltip shows `Selected Skill modifiers: ...`
- conditional/choice/derived/target-side/procedure effects remain unsupported instead of approximated

#10J PR:
- PR #8
- verified head: `d4466fa0860da41b5e6af8b88b3325589bc05d28`
- merged commit: `7d05f1c5c5b3b54138638cc5fd3231b7a0240c4f`

## 11. Apply selected Skill modifier to roll (#10K PASS)

Verified mechanics boundary:
- clicked owned Skill remains the explicit applicability choice
- final executable target = locally resolved BASE target + the verified #10J selected Skill modifier
- selected Skill modifier is applied exactly once
- no automatic candidate Skill selection
- no clamping rule introduced
- no general situational/default modifier stack yet
- ambiguous named-test selection remains blocked
- context-required formulas remain blocked
- conditional/choice/derived/target-side/procedure Skill effects remain out of scope
- unskilled Pick Pocket -30 path remains out of scope

Verified runtime examples:
- Dex 25 + one `pickPocket`: base 25 + Skill +0 => target 25
- Dex 25 + two `pickPocket`: target 35
- Dex 25 + three `pickPocket`: target 45
- deleting one duplicate immediately reduces target by 10
- `immunityToDisease`, T 3: base 30 + Skill +10 => target 40
- Charm still does not roll from Skill row because Bargain/Bluff/Gossip selection is ambiguous
- Pick Lock remains context-required and non-rollable
- percentile construction remains `{ "d100" }` only and produces the normal FGU percentile pair
- result success/failure uses the FINAL target
- rolling mutates no Character/XP/Skill/Career persistence

Chat/result now reports the selected-Skill roll with Base, selected Skill modifier, final Target and SUCCESS/FAILURE.

Fallback remains:
- if an unambiguous locally-resolvable Skill has no audited numeric #10J effect, the BASE-only #10I path remains available and explicitly says there is no audited numeric Skill modifier

#10K PR:
- PR #9 `#10K Apply selected Skill modifier to Standard Test roll`
- verified head: `f3e27b1d91886c936e640fbb2b7e8cfd7180b62d`
- merged commit: `11a1510daa9dd027df9b474020da78ca1fc34f6e`

## 12. Explicit named Standard Test selector (#10L PASS)

Verified behavior:
- Ctrl+Double-click an owned Skill with exactly one locally rollable named Standard Test keeps the direct #10K roll path
- Ctrl+Double-click an owned Skill with multiple locally rollable candidate tests opens a transient selector instead of auto-choosing for the GM/player
- selector shows only candidate tests whose existing `resolveSelectedSkillTarget(...)` resolves locally
- clicking a selector choice calls the already-verified `performSelectedSkillTest(...)` path and closes the selector
- selector creates no persistent Character/Skill/XP/Career data
- Charm with Fel 42 exposes Bargain, Bluff and Gossip at 52% = base 42 + Charm +10 and rolls the explicitly chosen test
- Pick Pocket remains direct
- Immunity to Disease remains direct
- Pick Lock remains context-required and non-rollable

Final selector implementation:
- `campaign/record_standard_test_selector_wfrp1e.xml`
- transient unbound top-level window
- fixed three-button choice surface for the currently audited registry
- readable white text on the dark utility frame
- no `StandardTestManagerWFRP1E` mechanics changes in #10L

Rejected/fixed #10L attempts — DO NOT REINTRODUCE:
1. Dynamic unbound `windowlist` child creation using `createWindowWithClass(...)` produced runtime error `windowlist: Could not find windowclass()` in FGU. This implementation was removed completely.
2. Initial selector contrast was poor on the dark frame. Final selector explicitly uses white text.
3. Embedded Lua inside XML used raw `nCreated < #aControls`, causing XML parse failure because `<` is reserved in XML text. Final XML uses `nCreated &lt; #aControls`. When embedding Lua in XML, raw `<` comparisons must be escaped or otherwise avoided.

#10L PR:
- PR #10 `#10L Explicit Standard Test selector`
- final verified head: `a7d7e06fe78e711568b7cafc8b6eb1934b77a2f0`
- merged commit: `260b76785fbb3879c4a8c3daf2ee79475a80b250`

## 13. Verified checkpoint history

- #1 CoreRPG skeleton — PASS
- #2 WFRP init — PASS
- #3 characteristic registry — PASS
- #4A/#4B characteristic advance/current model — PASS
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
- #10J selected Skill modifier resolver — PASS
- #10K selected Skill modifier applied to roll — PASS
- #10L explicit named Standard Test selector — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — REMOVED; do not retry.

## 14. Rulebook conclusions already audited

Career changes / Skills:
- English Core Rulebook p. 92, “New Skills”
- Polish Core Rulebook p. 92, “Nowe Umiejętności”
- new Career Skills cost 100 XP/PD each and are not automatic

First-Career probability entries belong to character creation, not later-Career eligibility.

Repeated acquisition:
- Pick Lock and Pick Pocket: +10% for each additional acquisition
- Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisitions to add instruments/languages/weapon categories rather than receiving the same generic numeric rule

Standard Tests / Skill effects:
- named Standard Tests define the tested characteristic/base procedure
- listed Skills are candidates; GM determines actual applicability
- appropriate Skill bonuses may stack, subject to rule-specific/mutually-exclusive combinations
- there is no universal owned-Skill +10 rule
- Charm +10 applies to its audited Fellowship tests when selected/applicable
- Immunity to Disease +10 applies to Disease
- Pick Pocket has a separate unskilled -30 path not yet implemented
- Pick Lock requires possession and still needs lock-difficulty context
- Basic Test success is `D100 <= final percentage chance`
- no target clamping rule has been introduced without explicit source verification
- Standard Test identity/base data, Skill applicability/modification, situational modification and execution remain separate concerns

## 15. Current verified baseline

Current verified CODE baseline after #10L merge:
- `260b76785fbb3879c4a8c3daf2ee79475a80b250`

This context-document update is metadata only and may make `main` one commit newer than the verified mechanics merge. Do not treat the metadata commit as a mechanics checkpoint.

Important current files include:
- `base.xml`
- `campaign/record_char_main_wfrp1e.xml`
- `campaign/record_char_career_skills_wfrp1e.xml`
- `campaign/record_career_wfrp1e.xml`
- `campaign/record_career_skills_wfrp1e.xml`
- `campaign/record_skill_wfrp1e.xml`
- `campaign/record_standard_test_selector_wfrp1e.xml`
- `campaign/scripts/char_main_wfrp1e.lua`
- `campaign/scripts/char_characteristic_wfrp1e.lua`
- `campaign/scripts/char_experience_wfrp1e.lua`
- `campaign/scripts/char_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skills_layer_wfrp1e.lua`
- `scripts/data_standard_tests_wfrp1e.lua`
- `scripts/data_standard_test_skill_effects_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`
- `scripts/manager_character_advancement_wfrp1e.lua`
- `scripts/manager_character_skill_wfrp1e.lua`
- `scripts/manager_character_career_wfrp1e.lua`
- `scripts/manager_character_experience_wfrp1e.lua`

## 16. Next checkpoint

#10M is NOT frozen yet.

Before implementation:
1. re-audit the next rule slice in the WFRP 1e Core Rulebook;
2. inspect the read-only Foundry implementation only as architecture/reference;
3. inspect official FGU APIs if a new UI/interaction primitive is required;
4. preserve the explicit GM/player applicability boundary and one-checkpoint workflow.

Candidate next boundaries to evaluate source-first:
- one narrowly scoped Standard Test situational/default modifier path, or
- one context-required base formula with explicit input (for example Pick Lock lock difficulty) if it is the smaller prerequisite.

Do not jump to a full Standard Test dialog, opposed tests, margins/degrees, broad situational automation or procedure-heavy Skills until their individual mechanics and FGU interaction contracts are audited.