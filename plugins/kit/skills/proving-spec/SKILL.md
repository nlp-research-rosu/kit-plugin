---
name: proving-spec
description: 'Use when spec.k exists and its claims must be proved — from the first proof submission through making a stuck proof pass: hangs, divergence, memory exhaustion, WarnStuckClaimState, or a non-zero exit.'
---

## Artifact contract

This stage produces the proof-extension layer: additions to the
`VERIFICATION` module of `verification.k`, `prove.sh` with the exact
commands used, and a passing `#Top` run.

`spec.k` is a set of K reachability claims. `kprove` attempts to prove each
claim by symbolically executing from the LHS and checking it reaches the RHS
under the given conditions. When the proof fails, `kprove` exits non-zero and
prints a residual configuration — the state it reached but could not close. This
skill provides the tools to read that residual and extend `verification.k` until
the proof closes.

Use `writing-spec` before this skill if `spec.k` is not yet written.

For EVM targets, read [EVM specification patterns](../shared/evm-spec-patterns.md)
before drafting or repairing the claims.

---

## Why proofs get stuck

`kprove` closes a claim by rewriting the LHS to the RHS. It gets stuck when:

- **Symbolic arithmetic does not reduce.** The backend cannot discharge the
  remaining obligation as written. Express the result through a summary whose
  defining equations or lemmas fit a theory the prover can use.
- **The loop-invariant circularity does not fire.** The recurring symbolic
  configuration does not match the invariant claim's left-hand side closely
  enough for the claim to apply, so the prover expands another iteration. See
  [circularity debugging](../shared/circularity-not-applying.md).
- **A helper rule is in the spec module instead of `verification.k`.** Plain
  `rule` statements in the spec module are a K compiler error; only `claim`s and
  `[simplification]` rules are allowed there.

The repair loop below addresses each of these systematically.

---

## Before adding a proof extension

Before adding any proof extension, work through the
[soundness contract](../shared/proof-extension-soundness.md) and
[Gate A obligations](../shared/gate-a-soundness.md). For the proposed
change, answer these questions from the residual:

1. What fixed-semantics step or mathematical obligation is missing?
2. Which extension class applies?
3. **Does this replace execution?** If yes, identify the exact binding, body,
   evaluation steps, control behavior, and state footprint being replaced.
4. What is the complete matched context, including the active continuation,
   control stack, bindings, guards, and framed cells?
5. Is every frame, wildcard, or omitted cell equally general in the theorem or
   assumption that supplies the justification domain?
6. Does the extension introduce abrupt control such as return, frame popping,
   an exception, or loop control? If so, what proves the same continuation is
   discarded, preserved, or unwound under fixed semantics?
7. Does the extension's value affect a branch, result, observable state,
   exception, or postcondition? If so, what machine-checked connection theorem
   proves that fixed semantics produces that value over the complete domain?
8. Does the same fresh or opaque symbol occur in both an operational bridge and
   a summary or postcondition? That dependency is circular unless independently
   connected to fixed execution.
9. What guard makes every new equation true, and do its cases overlap existing
   equations consistently?
10. Which claim depends on the extension, and what theorem or named trust
   assumption justifies it?

Complete the contract's extension record before editing `verification.k`. If a
program-defined operation cannot be connected to execution, strengthen the
invariant, add an auxiliary execution claim, route a genuine language-model gap
to `writing-semantics`, or continue the same-session repair loop below.

Do not introduce a result-bearing oracle to make a residual disappear,
and never widen a bridge beyond what its supporting theorem proves. The
admission preconditions and containment obligations live in the
[Gate A obligations](../shared/gate-a-soundness.md).

## Gate A repair

When the proof audit fails Gate A with TARGET `proving-spec`, you are
responsible for repairing the finding recorded in the audit artifact.
Preserve the current solution and artifacts and repair in place:

1. **First, remove or disable the offending extension.** Do not treat `#Top`
   obtained through that extension as a usable proof state.
2. Resubmit with the edited verification source, then inspect the genuine
   residual produced by fixed semantics and the remaining justified theory.
3. **Prefer fixed-semantics execution** and address the residual without an
   execution-bypassing rewrite.
4. **Prove an exact auxiliary execution theorem** before any operational bridge,
   covering every configuration in the proposed bridge's match domain without
   importing that bridge.
5. Strengthen the invariant or use a truthful definitional summary when that
   expresses the source computation exactly.
6. If the original intent is broader than the sound theorem currently
   available, preserve the narrower theorem honestly as partial progress and
   allow Gate B to report `SOUND-BUT-LIMITED`. When the task requires the full
   source contract, do not treat finitely many sizes, examples, or bounded
   unrollings as completion of the required target proof; keep repairing the
   symbolic theorem, or leave the required target unresolved.
7. Produce terminal `Incomplete work` only when repair attempts expose an
   evidenced hard blocker under the shared contract.

After the repaired construction reaches `#Top`, rerun the
proof audit. A rollback is part of the same run,
not a retry or a fresh attempt.

---

## Summary functions

The summary functions already exist: the spec stage wrote them in the
`VERIFICATION-SUMMARIES` module of `verification.k`, and the spec
audit approved their faithfulness. Your edits go in the `VERIFICATION`
module. If closing the proof requires changing a definitional equation,
that is a spec defect, not a proof extension: return to `writing-spec`,
then repeat the spec audit and all affected downstream checks.

**Choose the simplest faithful form the prover can use.** Prefer an equivalent
closed form when it lies in a solver-supported theory. If no faithful closed
form exists, keep the recursive definition; do not replace it with an
inaccurate formula merely to make the proof close. Use explicit base/step
equations plus targeted induction, folding, or summary lemmas. A recursive
evaluator can still unfold indefinitely on a symbolic argument, so diagnose
that mechanism rather than rejecting recursion itself. See
[deriving-invariants.md](../shared/deriving-invariants.md) and
[symbolic-recursion debugging](../shared/symbolic-recursion.md).

**Add `[simplification]` lemmas** for algebraic facts the prover cannot derive
on its own. A `[simplification]` rule fires during symbolic simplification, not
during normal rewriting. Keep them in `verification.k` (or, if they apply only
to a specific proof, in the spec module):

```k
rule (X +Int Y) ==Int X +Int Z => Y ==Int Z  [simplification]
```

---

## Invariants and lemmas

The loop-invariant claim in `spec.k` is the loop invariant. When the proof is
stuck on the invariant's inductive step, you have two options:

1. **Strengthen the invariant.** Add a conjunct to the `requires` or express a
   tighter postcondition.
2. **Add a lemma.** Add a `[simplification]` rule to `verification.k` that lets
   the prover discharge the residual algebraic obligation.

Keep the invariant and the summary function consistent: the invariant
postcondition (`s |-> S +Int sumTo(N)`) and the summary function definition
(`sumTo(N) = N*(N+1)/2`) must describe the same quantity.

---

## The repair loop

```text
submit proof → read the residual → add one lemma or strengthen invariant → re-run
```

**Step 1: submit a proof task.** Use `kprover prove --help` for submission
details and [running-k.md](../shared/running-k.md) for workflow and evidence
rules. Record the command in `prove.sh`.

An outcome of `proved` with tool exit 0 means the claim closed with a
`#Top` KAST under the supplied theory; it is necessary but
insufficient for validation. For `notProved`, read the structured
residual and downloaded logs. Always submit under the resource caps
below.

**Step 2: read the residual.** The residual is the symbolic configuration
`kprove` reached but could not match against the claim's RHS. Compare its term
shape to the RHS. The mismatch locates what is missing.

**Step 3: bound and compare the trace.** Isolate one claim, choose a
depth that returns promptly, and compare residual configurations at
nearby increasing bounds using the symptom router below.

**Step 4: add one classified change.** Complete the extension checkpoint, then
add the narrowest guarded lemma, summary equation, auxiliary claim, or invariant
strengthening that addresses the residual. Resubmit the focused claim.

Record the extension even when the proof reaches `#Top`; prover success does not
validate the added theory.

After editing `verification.k`, submit another attempt under the
[proof submission rules](../shared/running-k.md#proof-submission).

**Important hygiene:**

- Prove claims in order: loop invariants first, innermost loop first,
  then all claims together — the
  final run is unfiltered, so the invariant circularities stay
  available. A passing loop invariant makes the whole-program proof
  fast.

---

## Resource caps

Choose a time cap before submitting proof tasks; use `kprover config --help`
for settings and cancellation behavior.
The cap matters because the failure modes that matter — a circularity
that fails to re-match, a symbolic helper that keeps unfolding — do not
terminate on their own, and a running task gives no signal of either.

Use the configured timeout. A cap bounds how
long you will wait on a task that may never return: the prover cannot
tell you it is hung, so pick a time beyond which stuck is a better
explanation than slow. A cap confines the run's cost; it does not grade
its speed — so err generous: a healthy proof must never be the thing a
cap kills. Memory is Prover-side and not yours to size; a task that
dies of resources surfaces as `failed` or `inconclusive`, and the same
reading applies.

A generous cap firing — `inconclusive` at the timeout, or the client's
cancellation — is therefore strong evidence the task is stuck in one of
those non-terminating modes, not under-provisioned. Go to the symptom
router below; raise the timeout only when bounded inspection shows new
program points at increasing depths — genuinely slow, still moving.

Bounded inspection still needs a time cap. Use the diagnostic controls in
`kprover prove --help` for the inspection below.

---

## Symptom router and bounded inspection

Match the observed symptom, then open only the owning reference.

| Symptom | Open |
|---|---|
| Prover or the Kit client is unavailable | [running-k.md — Shell setup](../shared/running-k.md#shell-setup) |
| Backend or kompiled-definition mismatch | [running-k.md — Backends](../shared/running-k.md#backends) |
| K cannot find the requested main syntax module | [running-k.md — Backends](../shared/running-k.md#backends) |
| Unsure whether `#Top` means success | [running-k.md — Reading the result](../shared/running-k.md#reading-the-result) |
| Proof module rejects an ordinary rule | [k-claims.md — Functions and simplification](../shared/k-claims.md#functions-and-simplification) |
| `Unused filtering labels` | `kprover prove --help` |
| A symbolic helper keeps expanding | [symbolic-recursion.md](../shared/symbolic-recursion.md) |
| A loop repeats and the invariant is never applied | [circularity-not-applying.md](../shared/circularity-not-applying.md) |
| An external operation has no faithful equations | [opaque-primitives.md](../shared/opaque-primitives.md) |
| Fixed rules stay stuck on a supersort variable while `isS(V)` holds | [sort-refinement.md](../shared/sort-refinement.md) |
| Stuck within the first few steps, e.g. on a plain variable lookup | [stuck-in-first-steps.md](../shared/stuck-in-first-steps.md) |
| A nested container claim stalls on constructor alternatives | [nested-sequences.md](../shared/nested-sequences.md) |
| The proof runs without revealing where progress stops | Bounded inspection below |

If a timed-out task leaves no residual, isolate one claim and inspect it with
a depth bound using `kprover prove --help`, under the
[proof submission rules](../shared/running-k.md#proof-submission).

Choose the bound from the scale of the observed trace, not from a universal
fixed number. Compare the residual configuration at nearby increasing
bounds:

- New program points indicate continued symbolic progress.
- The same non-reducing subterm indicates a missing rule, undecidable
  guard, or helper that cannot simplify.
- Repeated loop-head shapes without claim application indicate a
  circularity matching problem.
- Rapidly growing helper terms indicate symbolic recursion.

A depth-limited result is diagnostic, not a proof result. Fix one
identified mechanism, rebuild if needed, and rerun the isolated claim
without the bound.

---

## References

- [Proof-extension soundness contract](../shared/proof-extension-soundness.md) —
  construction-time classification and extension-record requirements.
- [K functions, claims, and proof modules](../shared/k-claims.md) —
  `[function]`/`[simplification]`, claim syntax, and labels.
- [Running K through Prover](../shared/running-k.md) — command discovery and
  evidence rules.
- `writing-spec` — precedes this skill; produces `spec.k`.
- `validating-proof` — follows this skill; it rebuilds the
  extension inventory from the proof files rather than trusting the construction
  record, then applies Gate A — real-program soundness, Gate B — intent
  adequacy,
  and Gate C — trust and evidence auditability.

## Dispatch contract

- Inputs: the session ID; paths to `spec.k`,
  `verification.k`, `SCOPE.md`,
  and the task statement; on a redo, the failing audit artifact path.
- Produces: proof extensions in the `VERIFICATION` module, `prove.sh`
  with the exact commands used, and a `#Top` run.
- Record: two sentences — what closed and what theory was added
  — plus the artifact paths. Do not restate residuals or reasoning;
  the audit works from the files.
