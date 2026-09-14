# Trusted-opaque primitives — isolating an external trust boundary

Use opacity only for a fixed operation intentionally outside the theorem and
outside the program-defined code being verified. Prove the surrounding structure
and state the value-level result conditionally on the primitive's contract.

One K-specific implementation uses a `[function, total]` wrapper with **no rule
that fires under `kprove`** plus a `[concrete]` rule that computes the real
value under `krun`:

```k
syntax Float ::= intFloatDiv(Int, Float) [function, total, no-evaluators]
rule intFloatDiv(I, F) => Int2Float(I, 53, 11) /Float F  [concrete]
```

- Under `kprove` the argument is symbolic, the `[concrete]` rule does not
  fire, and `intFloatDiv(I, F)` stays uninterpreted. The proof only *threads*
  that term — it never reasons about the float value — so what is verified is
  the surrounding shape (the map, the fold, the accumulator), position for
  position.
- Under `krun` the argument is ground, the `[concrete]` rule fires, and the
  smoke/differential test checks a real numeric answer (the LLVM backend has
  the float hooks).

**`[no-evaluators]` is metadata, not a switch.** It suppresses the LLVM
"non-exhaustive match" warning on an under-covered total function and
documents intent; it disables nothing. Opacity is an emergent property of the
*rules*: no `kprove`-firing rule ⇒ opaque everywhere; a `[simplification]`
rule with a guard ⇒ unfolds only where the guard is entailed; a `[concrete]`
rule ⇒ krun computes it, kprove applies it only on ground arguments.

One consequence that bites:

- A `[concrete]` rule **still fires on ground arguments under `kprove`** and
  hits the missing hook — `subF(0.0, 1.0)` crashes just like
  `0.0 -Float 1.0`. Keep every argument symbolic and emit any needed constant
  as a **literal** (`-1.0`), never as a computed expression.

An opaque term may be threaded without proving its value. Differential testing
can support the primitive's concrete implementation, but it does not replace an
auxiliary theorem for program-defined code and does not establish a universal
value property.
