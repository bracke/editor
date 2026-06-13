# Pass 666 - Package body internal grammar

This pass extends the Ada token-cursor grammar with structural package body internals.

## Changes

* Added package-body productions for:
  * package body names
  * package body declarative parts
  * package body statement sequences
  * package body exception parts
* Updated package body parsing so selected package body names such as `Parent.Child` are retained structurally before the `is` keyword.
* Added a bounded package-body scan that records the declarative part after `is`, the optional `begin` statement sequence, and the optional `exception` part without introducing whole-project analysis or semantic compiler checks.
* Preserved existing package body stub handling for `package body P is separate;`.
* Added AUnit regression coverage for selected package body names, nested declarations, package body begin/exception sections, nested raise messages, and recovery into a following declaration.

## Scope

This improves structural grammar coverage for Ada package body internals. It is not compiler-grade legality checking for package body/spec conformance, elaboration, declaration legality, exception-handler legality, or control-flow semantics.
