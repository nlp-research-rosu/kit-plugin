# EVM specification patterns

Use these patterns when the selected semantics is KEVM. Read the session's
pinned sources first; helper names and imports must match that revision.

## ABI inputs and outputs

Prefer the typed helpers in the selected `abi.md` for canonical ABI calls:

```k
<callData> #abiCallData("creditOf", #address(OWNER)) </callData>
```

`#abiCallData` takes the function name without a signature, followed by typed
arguments in Solidity parameter order. It generates the four-byte selector
and ABI-encoded arguments. For `sendCredit(address,uint256)`, write:

```k
#abiCallData("sendCredit", #address(TO), #uint256(AMOUNT))
```

Match the declared types and constrain their symbolic values, for example
`#rangeAddress(TO)` and `#rangeUInt(256, AMOUNT)`. For argument encoding alone,
use `#encodeArgs(#address(TO), #uint256(AMOUNT))`; it adds no selector.
For a single unsigned return word, require `#buf(32, VALUE)` in `<output>`.
These helpers are supplied by the selected semantics, not a separate plugin.

Manual bytes are appropriate when testing malformed or noncanonical input.
For canonical calls, reuse the helpers before inventing encoding equations or
adding length and selector assumptions merely to make execution advance.

## Execution state and proof support

Load the generic EVM helpers and simplification lemmas in `verification.k`:

```k
requires "edsl.md"
requires "lemmas/lemmas.k"

module VERIFICATION
  imports EDSL
  imports LEMMAS
endmodule
```

If `VERIFICATION` already imports candidate definitions, retain those imports
and add `LEMMAS` there. `requires` loads files; `imports` makes their modules
available. `EDSL` exposes ABI and storage helpers; `LEMMAS` supplies byte,
integer and storage simplifications. Both come from the pinned semantics;
do not upload or duplicate them in the candidate bundle. Use these existing
simplifications before writing replacements.

- For runtime-bytecode entry, initialize the program, jump destinations,
  program counter, empty stack and memory, and memory usage. Match the
  selected semantics' entry convention; do not assume a setup command runs
  under every imported module. Leave the final internal stack unconstrained
  when it is outside the property; an empty initial stack need not end empty.
- Record the schedule, gas model, call value and call context in `SCOPE.md`.
  Choose them from the requested execution environment; disabling gas or
  changing a fork changes the theorem. State required success and failure
  cases separately, including their status and output.
- Validate the complete source bundle before proving. Inspect residuals for
  missing initialization or simplification; retain the original observable
  postcondition while following the [proof workflow](running-k.md).
