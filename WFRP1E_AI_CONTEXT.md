# WFRP1E Fantasy Grounds — AI Resume Context

Last updated: 2026-08-15 15:56 Europe/Warsaw

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
- `main` = last FGU-verified state plus metadata-only context commits;
- unverified mechanics/UI work goes to a dedicated branch + draft PR;
- never merge before explicit user `verified`;
- after verification, re-check exact PR head SHA, mark ready, merge with expected head SHA, then update this file;
- inspect English rulebook first, Polish rulebook second; use Foundry only as read-only architecture/reference;
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

Persistent per characteristic:
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

Character profile remains exactly:
- STARTER PROFILE
- ADVANCE SCHEME
- CURRENT PROFILE

Current Career identity:
- `career.current.name`
- `career.current.link`

Experience:
- `experience.totalAwarded`
- `experience.spent`
- Available = totalAwarded - spent
- manual Available edit means `totalAwarded = spent + newAvailable`

Characteristic advances and later-Career Skill purchases cost 100 XP.

Advancement transaction:
- one in-memory transaction spans Characteristic + Skill purchases while same top-level Character sheet is open;
- starts lazily on first successful purchase;
- Ctrl+Left refunds only purchases from current transaction;
- historical purchases protected;
- transaction survives tabs and ends when top-level `charsheet` closes.

Frozen characteristic-header UX (#9F): unfinished `[+]`, complete check; red = action possible, black = static/no action, green check = complete but refundable this transaction; whole 38x20 header clickable.

## 3. Skills / Career Skills — verified model

Persistent campaign/reference Skill fields:
- `name`
- stable language-neutral `rulesId`
- `specialisation`
- `description`

Character ownership:
- `skills.<unique acquisition id>`;
- each acquisition snapshots name/rulesId/specialisation/description;
- source link separate;
- duplicate rulesIds valid;
- source edits do not rewrite snapshots;
- `<allowdelete />` removes exactly one acquisition.

Career Skills:
- Career offers snapshot name/rulesId/specialisation/optional chance;
- chance is descriptive metadata only;
- later-Career Skills cost 100 XP and are not automatic;
- successful purchase creates a normal owned acquisition;
- Skill purchases share Character advancement transaction/refund accounting.

Rules ID selector (#10O):
- raw editable Rules ID replaced by localization-ready selector;
- stored ID remains stable/language-neutral; labels come from strings;
- Unlinked + all 133 core English Skills;
- compatibility exception: display `Jest`, persist `jester`;
- unknown/custom IDs remain untouched unless explicitly changed;
- left-aligned hover-highlight rows, hand cursor, native `scrollbar_list`, search-to-first-match, explicit X close;
- Standard Test selector has matching hover rows and X close.

FGU #10O lesson: avoid eager top-level Lua package initialization using helpers such as `ipairs`; FGU produced `attempt to call global 'ipairs' (a nil value)`. Use lazy lookup/population. Do not reuse rejected #10L dynamic `windowlist.createWindowWithClass(...)` path.

## 4. Standard Tests — verified through #10R

### Repeated acquisition
Derived acquisition count groups owned Skills by stable `rulesId`; no persisted rank.

Numeric repeat rule only for:
- `pickLock`
- `pickPocket`

`repeat bonus = (acquisitions - 1) * 10%`

Musicianship / Speak Additional Language / Specialist Weapon use repeated acquisitions to broaden coverage, not this numeric bonus.

### Foundation
`scripts/data_standard_tests_wfrp1e.lua` stores stable named Standard Test IDs, characteristic/formula, candidate Skill rulesIds, default modifier and tags/context requirements.

Candidate Skills are not automatic applicability. No generic formula parser.

Locally resolved bases include direct characteristics, `s * 10`, `t * 10`, fixed 50.
Context formulas include `100 - target.wp`, `i + cl - target.i`, `dex - lockDifficulty`, and noise-dependent Listen.

Basic success:
`D100 <= final target`; equality succeeds.

CRITICAL FGU percentile construction:
- pass only `{ "d100" }`;
- FGU adds companion d10 automatically;
- rejected `{ "d100", "d10" }` produced an extra d10.

### Selected Skill modifiers
There is NO universal `owned Skill = +10%` rule.
Audited examples:
- Charm +10 Bargain/Bluff/Gossip;
- Haggle +10 Bargain;
- Immunity to Disease +10 Disease;
- Immunity to Poison +10 Poison;
- Linguistics +10 Understand Language;
- Pick Lock / Pick Pocket repeated-acquisition modifier;
- Super Numerate +20 Estimate, +10 Gamble;
- Wit +10 Bluff/Gossip;
- Bribery +20 Bribe.

`final target = resolved base + explicitly selected Skill modifier`

No automatic Skill choice, invented clamping, or generic situational stack. Pick Pocket's separate unskilled -30 path is still not implemented.

### Explicit Standard Test selector (#10L)
Ambiguous locally rollable Skills use Ctrl+Double-click selector rather than auto-choice. Charm with Fel 42 => Bargain/Bluff/Gossip 52 with Charm +10.

Rejected #10L approaches — do not reintroduce:
1. dynamic unbound `windowlist.createWindowWithClass(...)` caused `windowlist: Could not find windowclass()`;
2. dark utility frame needs explicit white/readable text;
3. raw `<` inside Lua embedded in XML caused parser failure; escape as `&lt;` or avoid it.

### Pick Lock (#10M)
Rulebook:
- requires Pick Lock Skill;
- Lock Rating 0–100;
- base = Current Dex - Lock Rating;
- repeat acquisitions +10 each after first;
- attempt = one round / 10 seconds;
- after three failed attempts by same character on same lock, further attempts automatically fail.

Implementation:
- Lock Rating transient context only;
- explicit `dex - lockDifficulty` resolver;
- invalid ratings do not roll;
- no clamp;
- no fake lock identity/failure counter;
- chat gives procedure reminder.

### Bribe (#10N–#10Q)
Rulebook procedure:
- base = `100 - target WP`;
- Bribery +20%;
- alignment: Chaos +20, Evil +10, Neutral 0, Good -10, Law -20;
- each additional 50% of original minimum acceptable bribe = +10%;
- GM may add other circumstance modifier;
- GM establishes minimum acceptable bribe externally.

Verified implementation:
- Bribery selector shows Bribe plus Gossip/Loyalty BASE-only choices;
- Bribe context inputs target WP, alignment, extra 50%-steps, Other GM modifier;
- CALCULATE preview and separate ROLL action use one authoritative resolver;
- invalid context launches no dice;
- no clamp/persistence;
- chat reports full breakdown and outcome;
- popup results are split into multiple lines to avoid clipping.

#10Q merge:
`0b774c1492d44db1d9618da55754e603f7d5815d`

### Hide base context (#10R PASS)
Rulebook-audited Hide base:
`Current Initiative + Current Cool - target Initiative`

Against a group, use the highest Initiative in that group.
Separate procedure modifiers exist: appropriate Silent Move may add +10, Concealment may add up to +20, plus GM situational modifiers. These are NOT automated in #10R.

Verified #10R implementation:
- owned `concealmentRural`, `concealmentUrban`, or `shadowing` has sole candidate `hide` and Ctrl+Double-click opens transient HIDE CONTEXT;
- target Initiative supplied manually; no target/group persistence;
- CALCULATE previews BASE only; no dice;
- no clamp;
- popup explicitly states Silent Move/Concealment/other modifiers are not applied yet;
- X closes without side effects.

Verified examples with I 35 / Cl 24:
- target I 40 => 19%;
- target I 20 => 39%;
- target I 70 => -11%.

#10R verified head:
`50b054a64c24f14b1b94f8b056fb031245dbb5ad`

#10R merge:
`fcb15c82c99975af711a49f6a54c42eb4c1cb442`

## 5. Verified checkpoint history

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
- #10P Bribe runtime-context preview — PASS
- #10Q executable Bribe roll — PASS
- #10R Hide target-Initiative BASE preview — PASS

Rejected experiment:
- #9C.1 full-window focus-overlay attempts — removed; do not retry.

## 6. Current verified baseline

Current verified mechanics/UI merge after #10R:
- `fcb15c82c99975af711a49f6a54c42eb4c1cb442`

Context updates are metadata-only and may make `main` newer than the verified merge.

Important current files include:
- `base.xml`
- `scripts/data_skills_wfrp1e.lua`
- `scripts/data_standard_tests_wfrp1e.lua`
- `scripts/data_standard_test_skill_effects_wfrp1e.lua`
- `scripts/manager_standard_test_wfrp1e.lua`
- `scripts/manager_bribe_context_wfrp1e.lua`
- `scripts/manager_hide_context_wfrp1e.lua`
- `campaign/record_standard_test_selector_wfrp1e.xml`
- `campaign/record_pick_lock_context_wfrp1e.xml`
- `campaign/record_bribe_context_wfrp1e.xml`
- `campaign/record_hide_context_wfrp1e.xml`
- `campaign/record_skill_rules_id_selector_wfrp1e.xml`
- `campaign/scripts/char_skill_wfrp1e.lua`
- Character/Career/Experience/Advancement managers.

## 7. Next checkpoint

#10S is NOT frozen yet.

Do a fresh source audit before implementation. Natural next dependency is Hide procedure modifiers/execution, but preserve the rule distinction: Silent Move, Concealment and GM circumstances are separate inputs/effects and must not be collapsed into one generic selected-Skill modifier. Prefer another preview/resolver checkpoint before dice if the complete Hide procedure contract is not yet independently verified.
