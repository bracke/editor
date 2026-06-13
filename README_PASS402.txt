Pass 402 — iterator filter executable bindings

This pass extends parser-owned executable semantic binding with Ada iterator
filters such as:

   for Item of Items when Ready loop
   for I in First .. Last when Ready loop

The iteration source remains Binding_Iteration_Source, range endpoints remain
Binding_Range_Bound where applicable, and the filter expression leading name is
retained separately as Binding_Iteration_Filter.  This keeps filtered loops
useful for semantic colouring/navigation without conflating filter conditions
with the iteration domain or statement-level condition bindings.

No Python, shell scripts, parser generators, rendering-side parsing, external
compiler integration, or LSP integration were added.
