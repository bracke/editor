Pass1161 - Discriminant generic representation consumer legality

This pass adds one compiler-grade semantic building block for discriminant and variant dependent legality across generic replay and representation/freezing consumers.

New package:

  Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality

Purpose:

  Pass1142 introduced discriminant-dependent legality and Pass1160 connected generic body replay to representation/freezing tasking-elaboration-flow consumers. Pass1161 joins those two semantic paths so discriminant constraints, discriminant defaults, variant choices, private/full-view discriminant consistency, and discriminant-dependent use sites cannot remain confidently legal when they are replayed through an instantiated generic body or used by representation/freezing consumers.

Coverage:

  * discriminated record type contexts
  * discriminant constraints
  * discriminant defaults
  * variant parts and variant choices
  * record aggregates
  * assignment, conversion, return, allocator, and generic-actual discriminant use sites
  * private/full-view discriminant consistency
  * generic replay contexts
  * representation clauses
  * record layouts
  * freezing effects

The package consumes:

  * Editor.Ada_Discriminant_Dependent_Legality
  * Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality

It classifies:

  * accepted discriminant/variant generic representation consumers
  * missing discriminant legality evidence
  * missing generic replay representation-flow evidence
  * missing, duplicate, mismatched, non-static, out-of-range, and later-dependent discriminant information
  * constrained-object discriminant changes
  * assignment/conversion/return/allocator/generic-actual discriminant mismatches
  * missing/forbidden/overlapping/gapped variant choices
  * private/full-view discriminant mismatches
  * linked record aggregate, assignment, conversion, return, and generic replay blockers
  * generic replay and representation/freezing blockers
  * refined Global/Depends and call-propagation blockers that reach represented generic discriminant consumers
  * coverage blockers and indeterminate states

Regression:

  Test_Ada_Discriminant_Generic_Representation_Consumer_Legality_Pass1161

This is not a projection or diagnostic pass. It makes discriminant-dependent legality an active consumer in the generic replay plus representation/freezing semantic chain.
