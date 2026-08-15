# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-15 06:42 Europe/Warsaw

This is the single authoritative resume/checkpoint file for the Fantasy Grounds WFRP 1e project. Update this file in place; do not create overlapping context documents.

## 1. Repository, authority and workflow

Writable repository:
- `tuvielgaming/wfrp1e_FantsyGrounds`

Read-only architecture/reference repository — NEVER WRITE:
- `tuvielgaming/wfrp1ed_FoundryVTT`

Target:
- Fantasy Grounds Unity 5.1.13
- direct CoreRPG inheritance
- no MoreCore

Authority order:
1. WFRP 1e Core Rulebooks = mechanics authority.
2. Foundry implementation = read-only architecture/spec/reference.
3. Fantasy Grounds implementation = project output.

Mandatory workflow:
- work one tested checkpoint at a time;
- `main` is the last FGU-verified state plus metadata-only context commits;
- unverified mechanics go to a dedicated branch + draft PR;
- never merge mechanics before explicit user `verified`;
- after verification, re-check exact PR head SHA, mark ready, merge with expected head SHA, then update this file;
- inspect English rulebook first, corresponding Polish rulebook second, Foundry only as read-only architecture/reference, and official FGU docs for unfamiliar APIs;
- do not invent WFRP mechanics or FGU APIs;
- if context/source is missing, ask instead of reconstructing from memory;
- prefer Git changes over full replacement files in chat;
- if manual files are unavoidable: exact repository path + complete replacement file, never snippets.

## 2. Frozen Character / Career / XP model

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

Derived current:
`current = initial + purchased * advanceStep`

Career semantics:
- `purchased` = total historical advances;
- `career` = current Career ceiling;
- `purchased > career` is valid;
- buy only when `purchased < career`;
- never clamp purchased on Career change;
- assigning a Career copies all 14 Career ceilings including zero.

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

Characteristic advances and later-Career Skill purchases cost 100 XP.

### Advancement transaction — frozen

One in-memory advancement transaction spans Characteristic and Skill purchases while the same top-level Character sheet remains open.

- starts lazily on first successful purchase;
- Ctrl+Left refunds only purchases made during the current transaction;
- never refunds below the transaction baseline;
- historical purchases are protected;
- transaction survives tab switches;
- top-level Character close ends the transaction via keyed `onWindowClosing` for `charsheet`;
- after close/reopen, persistent purchases remain but are no longer refundable.

Frozen characteristic header UX (#9F):
- no Career advance => plain abbreviation;
- unfinished => `[+]`;
- complete => custom check icon;
- red marker = action possible now;
- black marker = state present but no action possible;
- green check = complete and refundable in current transaction;
- black check = complete/static;
- Left = buy;
- Ctrl+Left = current-transaction refund;
- whole 38x20 header is clickable.

## 3. Skills / Career Skills — verified model

### #10A Skill record
Persistent campaign/reference Skill fields:
- `name`
- stable language-neutral `rulesId`
- `specialisation`
- `description`

Do not force all Skills into one generic characteristic/target/modifier schema; WFRP 1e Skill procedures are rule-specific.

### #10B Character-owned acquisitions
Persistence:
- `skills.<unique acquisition id>`

Snapshot fields:
- name
- rulesId
- specialisation
- description

Source link is stored separately.

Each acquisition is independent. Duplicate `rulesId` values are valid and intentional. Later source edits do not rewrite owned snapshots.

### #10C owned Skill removal
- CoreRPG `<allowdelete />` removes only the selected owned acquisition;
- source Skill and duplicate acquisitions remain intact.

### #10D Career Skill offers
Each Career can persist independent Skill offers with:
- name
- rulesId
- specialisation
- optional `chance`

Duplicates are valid. Chance 0 displays blank. `chance` is metadata from Career descriptions and is not later-Career purchase eligibility.

### #10E later-Career Skill purchase
Rulebook-confirmed:
- new Career Skills are not automatically gained;
- each later-Career Skill costs 100 XP/PD;
- old Skills are retained.

Implementation:
- Character snapshots current Career Skill offers;
- purchase state belongs to a Career offer instance, not global rulesId ownership;
- successful purchase creates a normal owned Skill acquisition and spends 100 XP;
- Ctrl+Left refunds only if bought in the current Character-sheet transaction;
- Skill and Characteristic purchases share the same transaction accounting.

## 4. Repeated acquisition and Standard Tests — verified through #10M

### #10F repeated acquisition foundation
Acquisition count is DERIVED from independent owned Skill rows grouped by stable `rulesId`; no persistent rank/count field.

Numeric repeated-acquisition rule currently applies only to:
- `pickLock`
- `pickPocket`

Formula:
`repeat bonus = (acquisitions - 1) * 10%`

Examples:
- 1 => +0%
- 2 => +10%
- 3 => +20%

Deleting one duplicate immediately lowers derived count/bonus.

Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisition to broaden instruments/languages/weapon categories instead of receiving this generic numeric bonus.

### #10G Standard Test data foundation
`scripts/data_standard_tests_wfrp1e.lua` stores descriptive/non-executable named Standard Test definitions with stable IDs.

Definitions may include:
- direct `characteristic`;
- `formula`;
- candidate Skill `rulesId` values;
- `defaultModifier`;
- tags/audit metadata.

Key boundary:
- listed Skills are candidates only;
- GM/player decides actual applicability;
- appropriate Skill modifiers may stack when rules allow;
- mutually exclusive/situational cases require explicit judgement;
- no automatic Skill selection.

Representative registered bases:
- direct characteristic (`fel`, `dex`, `int`, `cl`, `wp`, etc.);
- `100 - target.wp`;
- `i + cl - target.i`;
- `dex - lockDifficulty`;
- `t * 10`;
- fixed `50`;
- situational `noise`.

### #10H base-target resolver
`scripts/manager_standard_test_wfrp1e.lua` reuses `CharacteristicManagerWFRP1E.calculateCurrent(...)`.

Locally resolved bases:
- direct characteristic => Character Current;
- `s * 10`;
- `t * 10`;
- fixed `50`.

Other formulas return `context-required` until their explicit context contract is implemented.

### #10I percentile roll
Basic Test success:
`D100 <= final percentage chance`
Equality is success.

FGU roll path:
- `Comm.throwDice`;
- keyed `onDiceLanded` handler;
- custom roll data;
- result delivered to chat.

IMPORTANT FGU percentile construction:
- pass only `{ "d100" }`;
- FGU automatically adds the companion d10;
- rejected `{ "d100", "d10" }` produced an extra d10 in runtime.

### #10J selected Skill modifier resolver
There is NO universal `owned Skill = +10%` rule.

Verified audited numeric examples:
- Charm => +10% to Bargain/Bluff/Gossip when explicitly selected/applicable;
- Immunity to Disease => +10% to Disease;
- Pick Lock/Pick Pocket => +10% for each ADDITIONAL acquisition; first acquisition contributes +0 through this effect.

`resolveSelectedSkillModifier(nodeChar, rulesId, testId)` only resolves audited context-free numeric effects. Conditional/choice/derived/target-side/procedure effects remain unsupported instead of approximated.

Pick Pocket has a separate unskilled -30% rule not yet implemented.

### #10K selected Skill modifier applied to roll
Final executable target for the explicitly selected owned Skill:
`final target = resolved base + selected Skill modifier`

- selected Skill modifier is applied exactly once;
- no automatic candidate selection;
- no target clamping rule invented;
- no general situational/default modifier stack yet.

Verified examples:
- Dex 25 + one Pick Pocket => target 25;
- two Pick Pocket acquisitions => 35;
- three => 45;
- Immunity to Disease, T 3 => base 30 +10 = 40.

### #10L explicit named Standard Test selector
For owned Skills with multiple locally rollable named tests, Ctrl+Double-click opens a transient selector instead of auto-choosing.

Verified Charm example with Fel 42:
- Bargain 52
- Bluff 52
- Gossip 52

The chosen test uses the same verified #10K roll path.

Final selector implementation:
- `campaign/record_standard_test_selector_wfrp1e.xml`;
- transient unbound top-level window;
- fixed three-button choice surface for current audited registry;
- readable white text on dark utility frame;
- no Standard Test mechanics changes were needed for #10L.

DO NOT REINTRODUCE these rejected #10L approaches:
1. dynamic unbound `windowlist` child creation with `createWindowWithClass(...)` caused FGU runtime error `windowlist: Could not find windowclass()`;
2. dark-frame default text had poor contrast; final selector explicitly uses white text;
3. raw `<` inside embedded Lua in XML caused parser failure; XML-embedded Lua comparisons must escape `<` as `&lt;` or avoid it.

### #10M Pick Lock runtime Lock Rating context — PASS
Rulebook-audited mechanic:
- Pick Lock requires the Skill;
- Lock Rating / lock difficulty is 0-100%;
- base chance = Current Dex - Lock Rating;
- repeated Pick Lock acquisitions add the already-verified +10% each after the first;
- one attempt takes one round / 10 seconds;
- after three failed attempts by the same character on the same lock, further attempts automatically fail.

Verified implementation:
- Lock Rating is runtime test context only; it is not persisted on Character or Skill;
- `resolveBaseTarget(..., context)` has an explicit audited `dex - lockDifficulty` path; no generic formula parser;
- Ctrl+Double-click owned `pickLock` opens a transient Pick Lock context window;
- user enters Lock Rating 0-100 and rolls;
- values outside 0-100 do not roll;
- final target = Dex - Lock Rating + selected Pick Lock repeat modifier;
- target is not clamped because no clamping rule has been sourced;
- chat reports Dex, Lock Rating, base, Skill modifier, final target and success/failure;
- chat also reminds the one-round/10-second procedure and three-failure limit;
- no fake persistent lock identity/failure counter exists because the system does not yet model “this same physical lock”.

Verified #10M files:
- `base.xml`
- `campaign/record_pick_lock_context_wfrp1e.xml`
- `campaign/scripts/pick_lock_context_wfrp1e.lua`
- `campaign/scripts/char_skill_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`

#10M PR:
- PR #11 `#10M Pick Lock runtime Lock Rating context`
- verified head: `8eb5c25b449ecef6a9209aeb61c50c51b5f58be9`
- merged commit: `c66bc383c9f5f13902f1b8c27d45b8250493645a`

## 5. Rulebook conclusions already audited

Career changes / Skills:
- English Core Rulebook p.92, “New Skills”;
- Polish Core Rulebook p.92, “Nowe Umiejętności”;
- later-Career Skills cost 100 XP/PD each and are not automatic.

First-Career percentage entries belong to character creation, not later-Career purchase eligibility.

Repeated acquisition:
- Pick Lock and Pick Pocket: +10% per additional acquisition;
- Musicianship / Speak Additional Language / Specialist Weapon broaden coverage instead.

Standard Tests / Skill effects:
- named Standard Tests define the tested characteristic/base procedure;
- listed Skills are candidates, not automatic applicability;
- there is no universal owned-Skill +10 rule;
- Basic Test success is `D100 <= final percentage chance`;
- no target clamping rule has been introduced without explicit source verification;
- Standard Test identity/base data, Skill applicability/modification, runtime context and execution remain separate concerns.

Pick Lock:
- English printed p.70;
- Polish printed p.69;
- requires Skill;
- Dex - Lock Rating;
- Lock Rating 0-100%;
- one round/10 seconds per attempt;
- three failed attempts by same character on same lock => further attempts automatically fail.

## 6. Verified checkpoint history

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
- #10M Pick Lock runtime Lock Rating context — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — REMOVED; do not retry.

## 7. Current verified baseline

Current verified MECHANICS baseline after #10M merge:
- `c66bc383c9f5f13902f1b8c27d45b8250493645a`

This context-file update is metadata only and makes `main` one commit newer than the mechanics merge. Do not treat metadata commits as mechanics checkpoints.

Important current files include:
- `base.xml`
- `campaign/record_char_main_wfrp1e.xml`
- `campaign/record_char_career_skills_wfrp1e.xml`
- `campaign/record_career_wfrp1e.xml`
- `campaign/record_career_skills_wfrp1e.xml`
- `campaign/record_skill_wfrp1e.xml`
- `campaign/record_standard_test_selector_wfrp1e.xml`
- `campaign/record_pick_lock_context_wfrp1e.xml`
- `campaign/scripts/char_main_wfrp1e.lua`
- `campaign/scripts/char_characteristic_wfrp1e.lua`
- `campaign/scripts/char_experience_wfrp1e.lua`
- `campaign/scripts/char_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skill_wfrp1e.lua`
- `campaign/scripts/char_career_skills_layer_wfrp1e.lua`
- `campaign/scripts/pick_lock_context_wfrp1e.lua`
- `scripts/data_standard_tests_wfrp1e.lua`
- `scripts/data_standard_test_skill_effects_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`
- `scripts/manager_character_advancement_wfrp1e.lua`
- `scripts/manager_character_skill_wfrp1e.lua`
- `scripts/manager_character_career_wfrp1e.lua`
- `scripts/manager_character_experience_wfrp1e.lua`

## 8. Next checkpoint

#10N is NOT frozen yet.

Before implementing anything:
1. audit the next exact mechanic in the English Core Rulebook;
2. compare the corresponding Polish section;
3. inspect Foundry only as read-only architecture/reference;
4. inspect official FGU APIs if a new interaction primitive is needed;
5. keep the next slice dependency-small and preserve explicit GM/player choices.

Likely candidates to evaluate source-first:
- a target-characteristic runtime context formula such as `100 - target.wp` / `i + cl - target.i`, or
- the separate unskilled Pick Pocket -30 path if its required launch interaction is smaller.

Do not jump to a full Standard Test dialog, broad situational automation, opposed-test engine, degrees/margins, or procedure-heavy Skill automation before their individual rule/API contracts are audited.
