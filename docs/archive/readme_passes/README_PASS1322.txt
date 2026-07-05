Pass1322 - record layout / representation vertical slice

This pass adds Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality.

The pass is a vertical semantic slice, not diagnostic/provenance/recheck scaffolding.
It models concrete record representation clauses and component clauses with bit ranges,
position/order checks, overlap checks, record size overflow, alignment compatibility,
storage-order evidence, discriminant-dependent components, variant-dependent layout,
controlled/finalized component layout barriers, private/limited/incomplete/generic-formal
view barriers, late-after-freezing rejection, duplicate component clauses, and stale
source/record/clause fingerprint rejection.

Added AUnit coverage in Test_Ada_Record_Layout_Representation_Vertical_Slice_Legality_Pass1322.
