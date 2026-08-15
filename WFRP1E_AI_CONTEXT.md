# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-15 07:06 Europe/Warsaw

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
- one tested checkpoint at a time;
- `main` is the last FGU-verified state plus metadata-only context commits;
- unverified mechanics/UI work goes to a dedicated branch + draft PR;
- never merge before explicit user `verified`;
- after verification, re-check exact PR head SHA, mark ready, merge with expected head SHA, then update this file;
- inspect English rulebook first, Polish rulebook second for mechanics/localization differences; use Foundry only as read-only architecture/reference;
- inspect official FGU docs for unfamiliar APIs;
- do not invent WFRP mechanics or FGU APIs;
- if source/context is missing, ask instead of reconstructing;
- prefer Git changes over replacement-file dumps in chat.

## 2. Frozen Character / Career / XP model

Characteristic order:
`M WS BS S T W I A Dex Ld Int Cl WP Fel`

Keys:
`m ws bs s t w i a dex ld int cl wp fel`

Advance steps:
- `m s t w a` => +1
- all others => +10

Persistent characteristic fields:
- `initial`
- `purchased`
- `career`

Derived current:
`current = initial + purchased * advanceStep`

Career semantics:
- purchased = total historical advances;
- career = current Career ceiling;
- purchased > career is valid;
- buy iff purchased < career;
- never clamp purchased on Career change;
- assigning a Career copies all 14 ceilings including zero.

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

Visible XP UI is Available-only. Manual Available edit means:
`totalAwarded = spent + newAvailable`

Characteristic advances and later-Career Skill purchases cost 100 XP.

### Advancement transaction
- one in-memory transaction spans Characteristic + Skill purchases while the same top-level Character sheet is open;
- starts lazily on first successful purchase;
- Ctrl+Left refunds only purchases from the current transaction;
- historical purchases are protected;
- transaction survives tab changes;
- closing top-level `charsheet` ends it;
- after reopen, persistent purchases remain but are no longer refundable.

Frozen characteristic header UX (#9F):
- no Career advance => plain abbreviation;
- unfinished => `[+]`;
- complete => custom check;
- red = action possible;
- black = no current action;
- green check = complete and refundable this transaction;
- black check = complete/static;
- Left buys, Ctrl+Left refunds current transaction;
- whole 38x20 header is clickable.

## 3. Skills / Career Skills — verified model

### #10A Skill record
Persistent campaign/reference fields:
- `name`
- stable language-neutral `rulesId`
- `specialisation`
- `description`

`rulesId` is mechanical identity and must remain independent from localized/editable display name.
Do not force all Skills into a generic characteristic/target/modifier model; WFRP 1e procedures are rule-specific.

### #10B–#10E ownership / Career progression
- Character ownership: `skills.<unique acquisition id>`;
- each owned acquisition snapshots name/rulesId/specialisation/description;
- source link is separate;
- duplicate rulesIds are valid;
- source edits do not rewrite owned snapshots;
- owned Skill removal uses CoreRPG `<allowdelete />` and removes only that acquisition;
- Career Skill offers snapshot name/rulesId/specialisation/optional chance;
- `chance` is descriptive metadata, not later-Career purchase eligibility;
- later-Career Skills cost 100 XP each and are not automatic;
- Career Skill purchase creates a normal owned Skill acquisition;
- Career Skill purchases share the advancement transaction/refund accounting.

## 4. Repeated acquisition / Standard Tests — verified through #10N

### #10F repeated acquisition
Derived acquisition count groups owned rows by stable `rulesId`; no persisted rank.

Numeric repeat rule only for:
- `pickLock`
- `pickPocket`

`repeat bonus = (acquisitions - 1) * 10%`

Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisitions to broaden coverage, not this generic numeric bonus.

### #10G Standard Test data
`scripts/data_standard_tests_wfrp1e.lua` contains descriptive named Standard Test definitions:
- stable test ID;
- direct characteristic or audited formula;
- candidate Skill rulesIds;
- default modifier;
- tags/context requirements.

Candidate Skills are not automatic applicability; GM/player decides applicability.
No generic formula parser.

Representative formulas:
- `100 - target.wp`
- `i + cl - target.i`
- `dex - lockDifficulty`
- `t * 10`
- `s * 10`
- fixed 50
- situational noise.

### #10H base-target resolver
Reuses `CharacteristicManagerWFRP1E.calculateCurrent(...)`.
Locally resolves direct characteristics, `s * 10`, `t * 10`, fixed 50.
Other formulas remain context-required until explicitly implemented.

### #10I percentile roll
Basic Test success: `D100 <= final target`; equality succeeds.
FGU roll uses `Comm.throwDice`, keyed `onDiceLanded`, custom data and chat result.

CRITICAL FGU percentile construction:
- pass only `{ "d100" }`;
- FGU adds companion d10 automatically;
- rejected `{ "d100", "d10" }` produced an extra d10.

### #10J selected Skill modifiers
There is NO universal `owned Skill = +10%` rule.
Audited numeric examples include:
- Charm +10 to Bargain/Bluff/Gossip;
- Haggle +10 Bargain;
- Immunity to Disease +10 Disease;
- Immunity to Poison +10 Poison;
- Linguistics +10 Understand Language;
- Pick Lock / Pick Pocket repeated-acquisition modifier;
- Super Numerate +20 Estimate, +10 Gamble;
- Wit +10 Bluff/Gossip;
- Bribery +20 Bribe (#10N).

Conditional/choice/procedure effects remain unsupported rather than approximated.
Pick Pocket has a separate unskilled -30 path not yet implemented.

### #10K selected Skill modifier applied to roll
`final target = resolved base + explicitly selected Skill modifier`

Modifier is applied exactly once. No automatic Skill choice. No invented target clamping or generic situational stack.

### #10L explicit named Standard Test selector
For an owned Skill with multiple locally rollable candidate tests, Ctrl+Double-click opens a transient selector instead of auto-choosing.
Charm with Fel 42 => Bargain/Bluff/Gossip each 52 when Charm +10 applies.

DO NOT REINTRODUCE rejected #10L approaches:
1. dynamic unbound `windowlist.createWindowWithClass(...)` caused runtime `windowlist: Could not find windowclass()`;
2. dark utility frame required explicit readable white text;
3. raw `<` inside Lua embedded in XML caused parser failure; escape as `&lt;` or avoid raw comparison operators.

### #10M Pick Lock runtime Lock Rating — PASS
Rulebook-audited:
- requires Pick Lock Skill;
- Lock Rating 0–100;
- base = Current Dex - Lock Rating;
- repeat acquisitions add already-verified +10 each after first;
- one attempt = one round / 10 seconds;
- after three failed attempts by same character on same lock, further attempts automatically fail.

Implementation:
- Lock Rating is transient runtime context only;
- explicit `dex - lockDifficulty` resolver path, no generic formula parser;
- Ctrl+Double-click Pick Lock opens transient context window;
- invalid ratings do not roll;
- no target clamp invented;
- no fake persistent lock identity/failure counter;
- chat carries procedure reminder.

PR #11:
- verified head `8eb5c25b449ecef6a9209aeb61c50c51b5f58be9`
- merge `c66bc383c9f5f13902f1b8c27d45b8250493645a`

### #10N Bribery +20 Skill effect — PASS
Rulebook audit:
- English Skill descriptions, printed p.47: Bribery grants +20% to Bribe tests;
- Polish Skill descriptions, printed p.52: Przekupstwo grants +20% to tests of przekupstwo;
- Bribe base `100 - target.wp` remains separate runtime context for a later checkpoint.

Implementation:
- `bribery -> bribe -> fixed +20` added to `DataStandardTestSkillEffectsWFRP1E`;
- no Standard Test manager/UI change;
- Bribe remains context-required and does not roll yet.

PR #12:
- verified head `0ef0f57292b2085e5efd5896b8346ea3382ed9ab`
- merge `0a1036f158c9e980d27ce1aec31fc72437d077d5`

## 5. Core Skill identity source for creation UI

English Core Rulebook printed p.45 `INDEX TO THE SKILLS` contains 133 core Skills. This English list is the canonical source for the first complete Fantasy Grounds Skill rulesId selector.

Rules IDs use stable language-neutral lower-camel identities. Existing established IDs from the read-only Foundry reference must be preserved where they already exist.

Important compatibility exception:
- English rulebook display name is `Jest`;
- established read-only Foundry mechanical identity is `jester`;
- keep stable `rulesId = jester` for compatibility, but display/localize the label as `Jest` in Fantasy Grounds.

Polish printed p.45 appears to contain 134 indexed entries versus 133 in English. Do not silently reconcile that discrepancy in the selector checkpoint; English is mechanics/data-identity authority and Polish localization mapping requires its own audit.

Localization architecture:
- persisted `rulesId` stays stable and language-neutral;
- displayed Skill identity label comes from string resources;
- future localization changes only strings, never stored rulesIds.

## 6. Verified checkpoint history

- #1–#9F Character/Career/XP foundation and advancement UX — PASS
- #10A Skill record — PASS
- #10B owned Skill acquisition — PASS
- #10C owned Skill removal — PASS
- #10D Career Skill offers — PASS
- #10E 100 XP later-Career Skill purchase/refund — PASS
- #10F repeated acquisition foundation — PASS
- #10G Standard Test data foundation — PASS
- #10H base-target resolver — PASS
- #10I d100 Standard Test roll — PASS
- #10J selected Skill modifier resolver — PASS
- #10K selected Skill modifier applied to roll — PASS
- #10L explicit named Standard Test selector — PASS
- #10M Pick Lock Lock-Rating context — PASS
- #10N Bribery +20 Skill effect — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — removed; do not retry.

## 7. Current verified baseline

Current verified MECHANICS baseline after #10N merge:
- `0a1036f158c9e980d27ce1aec31fc72437d077d5`

Context updates are metadata-only and may make `main` newer than the mechanics merge.

Important files:
- `base.xml`
- `strings/strings_wfrp1e.xml`
- `campaign/record_skill_wfrp1e.xml`
- `campaign/record_char_main_wfrp1e.xml`
- `campaign/record_char_career_skills_wfrp1e.xml`
- `campaign/record_career_wfrp1e.xml`
- `campaign/record_career_skills_wfrp1e.xml`
- `campaign/record_standard_test_selector_wfrp1e.xml`
- `campaign/record_pick_lock_context_wfrp1e.xml`
- `campaign/scripts/char_skill_wfrp1e.lua`
- `campaign/scripts/pick_lock_context_wfrp1e.lua`
- `scripts/data_standard_tests_wfrp1e.lua`
- `scripts/data_standard_test_skill_effects_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`
- Character/Career/Experience/Advancement managers.

## 8. CURRENT CHECKPOINT — #10O Skill Rules ID selector

User-prioritized UI/data-quality checkpoint.

Goal:
- replace raw editable `rulesId` text entry on campaign Skill records with a dropdown-like selector containing all 133 English core Skill identities;
- persistent DB value remains ONLY the stable language-neutral `rulesId`;
- displayed labels are string-resource based and localization-ready;
- existing unknown/custom rulesIds must be preserved unless user explicitly chooses a canonical value;
- selector must not create persistent choice/list records;
- no Standard Test mechanic changes in #10O.

FGU architecture constraints already checked:
- native CoreRPG combobox is not suitable for durable stored-ID vs localized-display separation without a custom layer;
- use a custom read-only button/display opening a transient selector;
- if an unbound `windowlist` is used, use statically declared `<class>` and `createWindow(nil)`; DO NOT use the rejected #10L `createWindowWithClass(...)` path;
- DB update handlers may refresh the display after selection;
- opening/closing selector without choosing must mutate nothing.

#10O is not yet FGU-verified and must remain on a dedicated branch/draft PR until user verification.
