Pass1317 - Visibility / use-clause / name-resolution vertical slice

This pass adds Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality.

It is a vertical semantic slice, not another diagnostic/provenance/recheck loop.  It
models concrete Ada name visibility and lookup mechanics needed by overload
resolution and selected-name/attribute legality:

* direct visibility for simple names and generic formal names;
* selected and expanded-name visibility;
* use-package and use-type visibility;
* use-visible operator sets that remain legal ambiguity input for overload filtering;
* hiding by inner declarations;
* homograph conflicts;
* ambiguous use visibility outside overloadable contexts;
* child-unit with-clause requirements;
* private-child visibility barriers;
* private, limited, incomplete, and generic-formal view barriers;
* renaming target visibility;
* declaration-kind compatibility;
* source, symbol, visibility, and view fingerprint freshness.

The AUnit regression uses source-shaped direct/use/selected/operator/child/private-child
lookup rows and checks accepted resolution, overloadable ambiguous use-visible
operator sets, hiding, homographs, view barriers, renamings, kind mismatch, and stale
symbol evidence.
