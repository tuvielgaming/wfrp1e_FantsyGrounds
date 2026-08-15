# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-15 12:44 Europe/Warsaw

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

### Skill record / ownership / Career progression
Persistent campaign/reference Skill fields:
- `name`
- stable language-neutral `rulesId`
- `specialisation`
- `description`

`rulesId` is mechanical identity and remains independent from localized/editable display name.
Do not force all Skills into a generic characteristic/target/modifier model; WFRP 1e procedures are rule-specific.

Character ownership:
- `skills.<unique acquisition id>`;
- each acquisition snapshots name/rulesId/specialisation/description;
- source link separate;
- duplicate rulesIds valid;
- source edits do not rewrite snapshots;
- `<allowdelete />` removes exactly one owned acquisition.

Career Skills:
- Career offers snapshot name/rulesId/specialisation/optional chance;
- chance is descriptive metadata only;
- later-Career Skills cost 100 XP and are not automatic;
- successful purchase creates a normal owned acquisition;
- Skill purchases share the Character advancement transaction/refund accounting.

## 4. Repeated acquisition / Standard Tests — verified through #10N

### Repeated acquisition
Derived acquisition count groups owned rows by stable `rulesId`; no persisted rank.

Numeric repeat rule only for:
- `pickLock`
- `pickPocket`

`repeat bonus = (acquisitions - 1) * 10%`

Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisitions to broaden coverage, not this numeric bonus.

### Standard Test foundation
`scripts/data_standard_tests_wfrp1e.lua` stores descriptive named Standard Test definitions:
- stable test ID;
- direct characteristic or audited formula;
- candidate Skill rulesIds;
- default modifier;
- tags/context requirements.

Candidate Skills are not automatic applicability; GM/player decides applicability.
No generic formula parser.

Locally resolved bases:
- direct characteristics;
- `s * 10`;
- `t * 10`;
- fixed 50.

Context-required formulas include:
- `100 - target.wp`;
- `i + cl - target.i`;
- `dex - lockDifficulty`;
- situational noise.

Basic Test success:
`D100 <= final target`; equality succeeds.

CRITICAL FGU percentile construction:
- pass only `{ "d100" }`;
- FGU adds companion d10 automatically;
- rejected `{ "d100", "d10" }` produced an extra d10.

### Selected Skill modifiers
There is NO universal `owned Skill = +10%` rule.
Audited numeric examples include:
- Charm +10 Bargain/Bluff/Gossip;
- Haggle +10 Bargain;
- Immunity to Disease +10 Disease;
- Immunity to Poison +10 Poison;
- Linguistics +10 Understand Language;
- Pick Lock / Pick Pocket repeated-acquisition modifier;
- Super Numerate +20 Estimate, +10 Gamble;
- Wit +10 Bluff/Gossip;
- Bribery +20 Bribe (#10N).

`final target = resolved base + explicitly selected Skill modifier`

No automatic Skill choice. No invented clamping or generic situational stack.
Conditional/choice/procedure effects remain unsupported rather than approximated.
Pick Pocket's separate unskilled -30 path is not yet implemented.

### Explicit Standard Test selection (#10L)
For an owned Skill with multiple locally rollable candidate tests, Ctrl+Double-click opens a transient selector instead of auto-choosing.
Charm with Fel 42 => Bargain/Bluff/Gossip each 52 when Charm +10 applies.

DO NOT REINTRODUCE rejected #10L approaches:
1. dynamic unbound `windowlist.createWindowWithClass(...)` caused `windowlist: Could not find windowclass()`;
2. dark utility frame required explicit readable white text;
3. raw `<` inside Lua embedded in XML caused parser failure; escape as `&lt;` or avoid raw comparison operators.

### Pick Lock runtime Lock Rating (#10M)
Rulebook-audited:
- requires Pick Lock Skill;
- Lock Rating 0–100;
- base = Current Dex - Lock Rating;
- repeat acquisitions add +10 each after first;
- one attempt = one round / 10 seconds;
- after three failed attempts by same character on same lock, further attempts automatically fail.

Implementation:
- Lock Rating transient runtime context only;
- explicit `dex - lockDifficulty` resolver, no generic formula parser;
- invalid ratings do not roll;
- no target clamp invented;
- no fake persistent lock identity/failure counter;
- chat carries procedure reminder.

#10M merge:
`c66bc383c9f5f13902f1b8c27d45b8250493645a`

### Bribery +20 Skill effect (#10N)
Rulebook-audited:
- English printed p.47: Bribery grants +20% to Bribe tests;
- Polish printed p.52: Przekupstwo grants +20% to tests of przekupstwo;
- Bribe base `100 - target.wp` remains separate runtime context.

Implementation:
- `bribery -> bribe -> fixed +20`;
- no manager/UI change;
- Bribe still context-required and does not roll yet.

#10N merge:
`0a1036f158c9e980d27ce1aec31fc72437d077d5`

## 5. Skill identity selector / popup UX (#10O PASS)

English Core Rulebook printed p.45 `INDEX TO THE SKILLS` provides 133 canonical English core Skill identities for creation UI.

Identity rules:
- stored `rulesId` remains stable/language-neutral;
- displayed identity label comes from string resources;
- future localization changes presentation only;
- established Foundry IDs are preserved where already used;
- compatibility exception: display `Jest`, persist `jester`;
- unknown/custom existing rulesIds are preserved unless explicitly changed;
- Unlinked clears the stored ID.

Verified Skill-record UX:
- raw editable Rules ID text field replaced with localization-ready selector display;
- selector is transient/unbound and persists only the selected source Skill `rulesId`;
- Unlinked + all 133 core English Skills;
- left-aligned rows;
- hover/pressed row highlight + hand cursor;
- CoreRPG `scrollbar_list` gives visible draggable scrollbar on the long Rules ID list;
- search field at top accepts localized label or stable rulesId and scrolls to first match as user types;
- explicit top-right X closes without changing data;
- older Standard Test selector received matching left-aligned/hover-highlighted rows and X close control; no mechanics changed.

FGU-specific lessons from #10O:
- avoid eager top-level Lua initialization that calls helpers such as `ipairs` in a global package script; FGU raised `attempt to call global 'ipairs' (a nil value)` during `DataSkillsWFRP1E` initialization;
- because package init failed, downstream calls such as `getDisplayText()` were nil; root fix was to remove eager lookup-table construction and use lazy numeric-index lookup;
- selector population also avoids `ipairs` for the same runtime-safety reason;
- use statically declared unbound list child class + `createWindow(nil)`; do not reuse rejected #10L `createWindowWithClass(...)` path.

PR #13:
- verified head `855879c0e42a9ba25e005236331fbfd18088fa67`
- merge `6b1a5c0facb31125d9779547f7343a359d31e20e`

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
- #10O Skill Rules ID selector + popup UX — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — removed; do not retry.

## 7. Current verified baseline

Current verified mechanics/UI merge after #10O:
- `6b1a5c0facb31125d9779547f7343a359d31e20e`

Context updates are metadata-only and may make `main` newer than the verified merge.

Important current files include:
- `base.xml`
- `strings/strings_wfrp1e.xml`
- `strings/strings_skill_identities_wfrp1e.xml`
- `scripts/data_skills_wfrp1e.lua`
- `scripts/data_standard_tests_wfrp1e.lua`
- `scripts/data_standard_test_skill_effects_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`
- `campaign/record_skill_wfrp1e.xml`
- `campaign/record_skill_rules_id_selector_wfrp1e.xml`
- `campaign/record_standard_test_selector_wfrp1e.xml`
- `campaign/record_pick_lock_context_wfrp1e.xml`
- `campaign/scripts/skill_main_wfrp1e.lua`
- `campaign/scripts/skill_rules_id_selector_wfrp1e.lua`
- `campaign/scripts/char_skill_wfrp1e.lua`
- Character/Career/Experience/Advancement managers.

## 8. Next checkpoint

#10P is NOT frozen yet.

Return to mechanics after the user-prioritized #10O UI detour.
Natural next dependency from the earlier source audit:
- explicit Bribe target-WP runtime context for the existing `100 - target.wp` named Standard Test;
- reuse verified #10N Bribery +20 effect and existing transient context/roll architecture;
- audit the Bribe procedure's separate situational modifiers before implementing;
- do not conflate target-WP context, Bribery Skill bonus, and procedure/situational modifiers.
