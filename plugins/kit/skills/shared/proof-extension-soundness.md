# Proof-extension soundness contract

Use this contract whenever a proof adds a function, equation, claim, or rewrite
that contributes to closing a reachability claim. A successful kprove run
establishes closure under the supplied theory; validate that theory before
claiming a proof of the program.

## Classify every proof extension

| Class | Meaning | Required justification |
|---|---|---|
| Definitional summary | Names a mathematical value without replacing program execution | Truthful, guarded, terminating equations covering every use |
| Derived lemma | States a consequence of fixed semantics or established mathematics | A derivation valid over the lemma's complete guard |
| Operational bridge | Replaces or accelerates a term fixed semantics would execute | Equivalence to the exact execution, binding, control, and state transition |
| Trusted primitive | Represents a fixed operation intentionally outside the theorem | An explicit conditional trust boundary and independent evidence where available |

Classify by behavior, not by the symbol's name. A rule called a summary is an
operational bridge when it rewrites a program term before fixed semantics can
execute it. Program-defined code belongs to the program under verification; do
not reclassify it as an external primitive because proving it is difficult.

**A derived lemma must be derived.** A simplification whose conclusion is the
requested postcondition itself — the aggregate value, ordering, primality,
membership, or any other human-facing property of the program's own result —
installed with only an informal or on-paper justification is not a lemma; it
is the theorem assumed as an axiom, and no amount of reconstruction,
non-vacuity, or finite differential evidence legitimizes it. The test:
delete the rule — if the target becomes unprovable and the rule's statement
is (or directly entails) the target's postcondition, prove that statement as
a K claim (a loop-invariant circularity or auxiliary theorem over the same
fixed semantics) or the extension is an illegitimate material assumption.
Result-characterizing invariants are provable the same way the loop computes
them: thread the property through the loop claim (running product, running
order bound, divisor-exhaustion witness) instead of asserting it about the
finished result.

Operational bridges carry a heavy admission precondition; see the
[Gate A obligations](gate-a-soundness.md) before proposing one.

## The three gates

- **Gate A — Real-program soundness.** The proof's extensions must be
  sound about the real program: program-defined code executes or is
  connected by exact auxiliary theorems, bridges preserve state,
  binding, and control, equations are true wherever their guards
  apply, and the final claim constrains the result non-vacuously.
  Full obligations: [gate-a-soundness.md](gate-a-soundness.md).
- **Gate B — Intent adequacy.** A sound theorem must match the
  intended property: the formal domain covers the source contract,
  the language model is adequate and its boundaries witnessed, and
  summaries mean what the contract means. Full obligations:
  [gate-b-adequacy.md](gate-b-adequacy.md).
- **Gate C — Trust and evidence auditability.** Every unproved
  component is ledgered, every claimed test is reproducible, and the
  result language separates proved, conditional, empirical, and
  excluded. Full obligations: [gate-c-evidence.md](gate-c-evidence.md).

## Gate A repair transition

Gate A PASS continues to Gates B and C. Gate A failure is a repair
signal, not a terminal result. Every Gate A failure takes this
back-edge unless an enumerated, evidenced hard blocker prevents
further repair. Within the one orchestrated run:

1. the proof audit reports FAIL naming the owning stage;
2. the construction agent must remove or disable every offending extension
   and rerun without them to recover the genuine residual — `#Top`
   obtained through an offending extension is not a usable proof
   state; and
3. the construction is repaired and rebuilt, `#Top` recovered, and
   the proof audit rerun.

A rollback is part of the one orchestrated run, not a retry or a
fresh attempt.

Only after repair attempts encounter an evidenced hard blocker may the workflow
produce terminal `Incomplete work`. Hard blockers are unavailable required tools
or inputs, an out-of-scope fixed-semantics language gap, repeated external
backend or resource failure, or inconsistent requirements. Record the evidence
and the repair attempts that exposed the blocker.

A difficult proof is not a hard blocker. A slower safe encoding is not a hard
blocker. Repair that requires redesign is not a hard blocker. `#Top` obtained
only through an unsound shortcut is not a hard blocker and is not a usable proof
state.

## Proof-extension record

Record each extension during construction. Validation must rebuild this
inventory
from the actual proof files rather than trusting the construction record.

| Field | Required content |
|---|---|
| Extension | Exact symbol, rule, or claim |
| Class | One of the four classes above |
| Semantic role | Whether it reasons about or replaces execution |
| Domain | Complete guard and assumptions |
| Matched context | Complete term, continuation, control stack, bindings, and framed cells accepted by the extension |
| Justification scope | Exact configurations established by the derivation, auxiliary theorem, or trust assumption |
| Context containment | Why every matched configuration lies within the justification scope |
| State footprint | Cells read, written, preserved, or abstracted |
| Value influence | Branches, results, state, exceptions, and postconditions affected by the extension's value |
| Value justification | Defining equations, connection theorem, or external contract that fixes each result-bearing value |
| Justification | Derivation, auxiliary theorem, or named trust assumption |
| Dependents | Claims whose closure relies on it |
| Control validation | Fixed-versus-extended comparison and operational-sensitivity evidence for control-affecting bridges |
| Value validation | Fixed-versus-extended witnesses and rejected opposite interpretations for result-bearing abstractions |
| Validation | Gate checks and reproducible evidence |

## Decide the report status

Record PASS or FAIL for every completed gate. Choose the headline status only
after the Gate A repair transition reaches PASS or an evidenced hard blocker:

| Result | Status |
|---|---|
| Gate A remains blocked after evidenced repair attempts | Incomplete work; do not issue a successful proof report |
| Gate A passes and Gate B fails | SOUND-BUT-LIMITED |
| Gates A and B pass and Gate C fails | FORMALLY-SOUND-UNVALIDATED |
| Gates A, B, and C pass | VALIDATED |

Always report later-gate failures even when an earlier gate determines the
headline status.

## Red flags — stop before reporting success

| Rationalization | Required response |
|---|---|
| “The shortcut is only an optimization.” | Classify it by the execution it replaces and prove full equivalence. |
| “The false case is unreachable.” | Narrow the guard so the rule is true wherever it applies. |
| “Differential tests prove the abstraction.” | Report finite evidence; provide a theorem for universal equivalence. |
| “The source helper is trusted.” | Execute program-defined code or prove an exact auxiliary execution claim. |
| “The return value is right.” | Compare binding, control, exceptions, and every observable state cell. |
| “The same symbol appears in execution and the spec.” | That is circular unless fixed execution is independently connected to the symbol's value. |
