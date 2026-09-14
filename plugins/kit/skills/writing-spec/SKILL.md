---
name: writing-spec
description: 'Use when code and its K semantics exist and the theorem must be stated — drafting spec.k reachability claims, the summary functions they reference (VERIFICATION-SUMMARIES), and SCOPE.md. Triggered by "write a spec", "what should the preconditions be", or "draft spec.k".'
---

## Artifact contract

This stage states the theorem. It produces three artifacts: `spec.k`
(the reachability claims), the `VERIFICATION-SUMMARIES` module of
`verification.k` (the summary definitions the claims reference), and
`SCOPE.md` (the scope record the spec audit reads).

`spec.k` and `verification.k` compile against the immutable semantics selected
by the session ID. Inspect it with `kprover session show` first:

| State | Action |
|---|---|
| ID appears in the Prover registry and the target program runs | Proceed |
| ID appears, but the target program gets stuck | Record the model boundary |
| ID is absent | Stop as BLOCKED; do not author semantics inside live Kit |

Also confirm that concrete program identifiers used by the claims parse as
identifiers rather than K rule variables. See
[K syntax and operational semantics](../shared/k-syntax.md#grammar).

---

## What a spec is

A K spec states **partial correctness**: *if* the program terminates and the
precondition holds, then the postcondition holds at termination. It says nothing
about whether the program terminates; that is a separate liveness question.

Keep three activities distinct (see `using-kit`): **Verification** closes
reachability claims under the supplied theory; **Soundness audit** checks proof
extensions; and **Validation** checks theorem scope and evidence against the
intended property.

---

## Record the scope in SCOPE.md

Before drafting claims, write `SCOPE.md` beside `spec.k`. The spec
auditor reads it from disk — an unstated reading or silently omitted
cell is an audit finding, not a stylistic choice. Record five items:

| Item | Record |
|---|---|
| Program boundary | Exact entry computation and program-defined operations included in the theorem |
| Input domain | Types, guards, well-formedness conditions, and excluded inputs |
| Observable final state | Result and every state cell the intended property observes |
| Intended property | Plain-language result expected after termination |
| Chosen contract readings | Each underdetermined point, the reading chosen, and why |

The spec may frame cells that are intentionally irrelevant, but the scope record
must say why they are unobserved. Do not silently omit a cell whose change is
part of the intended behavior.

When the task requires the full source contract, the required entry claim or
claims must collectively cover that contract's input domain. Do not replace an
unbounded or symbolic domain with finitely many concrete sizes, examples, or
bounded unrollings. Such claims may be kept as diagnostic progress, but they are
not the required target theorem unless the source contract states the same
bound.

## Reading the contract

When the property arrives as a docstring-style natural-language
contract, resolve its stated meaning and its silences with
[reading-the-contract.md](../shared/reading-the-contract.md), and
record every chosen reading in `SCOPE.md`.

---

## Pre- and postconditions

Conditions are constraints on cell contents, written as `requires` and `ensures`
clauses on a `claim`:

- **`requires`** — the precondition: a Boolean expression over the LHS cell
  values. The claim is only attempted when this holds.
- **`ensures`** — the postcondition: a Boolean expression over the RHS cell
  values. May introduce existential variables written `?X` (e.g. `ensures ?R
  ==Int sumTo(N0)`). Any RHS variable not bound on the LHS must use `?`;
  omitting it is a hard K error.

Preconditions and postconditions are constraints on the full K configuration
(the `<k>` cell and every state cell) before and after the rewrite — not just
function inputs/outputs in the ordinary sense.

**Programs that produce a return value** — use `ensures` to constrain it.
Example shape for a claim where the computation leaves a result `?R` in `<k>`:

```k
claim [my-prog]:
      <k> myProgram(N0:Int) => ?R:Int </k>
      <state> S </state>
  requires N0 >=Int 0
  ensures  ?R ==Int sumTo(N0)
```

**Programs that terminate with a state** (no return value) — express the
postcondition as the RHS of the state cells directly, without `ensures`:

```k
<state> .Map => n |-> 0 s |-> sumTo(N0) </state>
```

---

## The two claims in `spec.k`

A complete spec contains one **entry claim** for the whole program plus one
**loop-invariant claim per loop**. The single-loop program used throughout this
kit therefore has exactly two claims; a program with two loops needs three, and
a nested loop needs its own invariant claim, which the outer loop's proof then
uses to step over the inner loop.

This works because all claims of a spec module are proved **together in one
`kprove` invocation**: after one rewrite step each claim is available as a
circularity to every claim's proof, so each loop claim applies to its own
back edge and the outer claims compose the inner ones. The prover does
not carry proven claims across invocations by itself; explicit trust can
re-import one as a recorded assumption
([running-k.md](../shared/running-k.md#proof-submission)). So keep
interdependent claims in one module — or trust across runs explicitly —
and never restate a proven claim as an installed rewrite rule to make
it "available": an installed operational rule stands outside the proof,
and if it is not
independently justified it smuggles the conclusion in as an axiom (the
[soundness contract](../shared/proof-extension-soundness.md) classifies
exactly this).

### 1. Entry (whole-program) claim

States what the full program does from its initial configuration to termination.

```k
claim [sum-prog]:
      <k> n = N0:Int ; s = 0 ;
          while (n > 0) { s = s + n ; n = n - 1 ; } => .K ...</k>
      <state> .Map => n |-> 0 s |-> sumTo(N0) </state>
  requires N0 >=Int 0
```

- LHS: the full program text in `<k>`; initial state (`.Map` = empty).
- RHS: `.K` in `<k>` means all computation is done; the final state maps are the
  postcondition.
- `...` in `<k>` is a frame variable for the rest of the continuation.
- The state uses a closed map (no `...`) when exactly those keys must be
  present.

### 2. Loop-invariant (circularity) claim

States what the loop does at the loop head, given symbolic accumulator values.
This is the coinductive hypothesis — kprove uses the claim to discharge the loop
by applying it to itself.

```k
claim [loop-inv]:
      <k> while (n > 0) { s = s + n ; n = n - 1 ; } => .K ...</k>
      <state> n |-> (N:Int => 0)
              s |-> (S:Int => S +Int sumTo(N)) </state>
  requires N >=Int 0
```

- Starting at the loop head with `n |-> N` and `s |-> S` (both symbolic), `N >=
  0`.
- The loop terminates with `n |-> 0` and `s |-> S + sumTo(N)`.
- The `=>` inside each cell maps old to new: `N:Int => 0` means `n` starts at
  `N` and ends at `0`.

Both claims live in a single spec module that only contains `claim`s (and
optionally `[simplification]` rules). Plain `rule` statements in a spec module
are a K compiler error.

```k
requires "verification.k"

module SPEC
  imports VERIFICATION

  claim [loop-inv]: ...
  claim [sum-prog]: ...
endmodule
```

---

## The loop invariant and its summary

The loop invariant ties the running accumulator to the postcondition
through a summary function, parametrized by the mid-loop state so it
covers every iteration. Derive invariant and summary together with
[deriving-invariants.md](../shared/deriving-invariants.md).

The summary function is part of the theorem's meaning: a claim stated
as `?R ==Int sumTo(N0)` says nothing until `sumTo`'s defining
equations say what it denotes. You own those definitions. Write them
in the `VERIFICATION-SUMMARIES` module of `verification.k`, which
`spec.k` imports; the later proving stage adds proof extensions to the
separate `VERIFICATION` module. If a repair changes summary definitions,
repeat the spec audit and all affected downstream checks.

```k
// verification.k — MiniPy example; use the selected registry entryFile
requires "semantics.k"

module VERIFICATION-SUMMARIES
  imports INT
  syntax Int ::= sumTo(Int) [function, total]
  rule sumTo(N) => (N +Int 1) *Int N /Int 2  requires N >=Int 0
  rule sumTo(N) => 0                          requires N  <Int 0
endmodule

module VERIFICATION
  imports VERIFICATION-SUMMARIES
  imports SEMANTICS
  imports BOOL
  // Proof extensions (lemmas, auxiliary claims) are added here by
  // the proving stage. The summaries module above is the theorem's
  // definitional layer; do not mix extensions into it.
endmodule
```

Definitional equations must be truthful, guarded, terminating, and
cover every use (the definitional summary class of the
[soundness contract](../shared/proof-extension-soundness.md)).

Judge the drafted domain and meaning against the
[Gate B obligations](../shared/gate-b-adequacy.md) before handing off:
the spec audit will apply them to the artifacts.

---

## Adequacy hand-off

Once `spec.k`, the `VERIFICATION-SUMMARIES` module, and `SCOPE.md` are
drafted, the spec audit judges adequacy and summary faithfulness
from the artifacts; do not duplicate those checks here.
Machine-check the structure with a focused `kprover validate` task
even before the proof is expected to close — early parser and module
errors are cheaper to fix before lemmas exist.

---

## References

- [K functions, claims, and proof modules](../shared/k-claims.md) — claim
  syntax, `requires`/`ensures`, labels, and proof-module restrictions.
- `proving-spec` — next step after the spec audit passes: adds proof
  extensions to the `VERIFICATION` module and makes the claims pass
  `kprove`.
- `validating-proof` — independently audits proof-extension soundness and
  validates intent, trust, and evidence for a passing proof.

## Dispatch contract

- Inputs: the session ID, the target program(s), and the
  original
  contract; the task statement; on a redo, the failing audit artifact path.
- Produces: `spec.k`, the `VERIFICATION-SUMMARIES` module of
  `verification.k`, and `SCOPE.md`.
- Record: two sentences — the theorem stated and each chosen
  contract reading — plus the artifact paths. Do not restate claim
  bodies; the audit works from the files.
