# Editor Core Design Notes (Stage 1)

## Scope

Stage 1 defines the minimal editor core:

- single caret
- linear text buffer
- directional selection
- deterministic command execution
- snapshot-based undo/redo

No rendering, no multi-cursor, no CRDT behavior.

---

## Coordinate Systems

### Caret space

The editor uses **caret space** for cursor and selection positions.

Caret positions are 0-based boundary positions between characters.

Examples:

- empty buffer: valid carets are `0 .. 1`
- buffer `"a"`: valid carets are `0 .. 2`
- buffer `"abc"`: valid carets are `0 .. 4`

In general:

```text
0 <= Caret <= Length(Buffer) + 1
```

### Buffer space

The underlying storage is 1-based, but this is strictly an implementation detail.

All editor logic operates in caret space and converts only when calling the backend.

#### Single-caret invariant

S.Carets.Length = 1
Let:
C = current caret
L = Length(Buffer)

Then:
0 <= C <= L + 1

#### Selection Model

type Selection_State is record
   Active     : Boolean := False;
   Start_Pos  : Cursor_Index := 0;
   End_Pos    : Cursor_Index := 0;
end record;

#### Semantics

Start_Pos = anchor (fixed)
End_Pos = moving end
Active = selection exists

Selection is not normalized in state.

This means:
Start_Pos < End_Pos   valid
Start_Pos = End_Pos   valid
Start_Pos > End_Pos   valid

Reordering only happens when computing spans.

#### Inactive selection invariant

Active = False  =>  Start_Pos = End_Pos = Caret

#### Active selection invariant

Active = True =>
   Start_Pos = anchor (fixed)
   End_Pos   = caret (moves)

End_Pos may cross the anchor.

#### Derived selection range

When applying edits:

Sel_Min  = min(Start_Pos, End_Pos)
Sel_Max  = max(Start_Pos, End_Pos)
Sel_Span = Sel_Max - Sel_Min

The selected range is:

[Sel_Min, Sel_Max)

#### Command Semantics

All commands operate in caret space.

Movement
Move_Left
New_Caret = max(0, Old_Caret - 1)
Move_Right
New_Caret = min(L + 1, Old_Caret + 1)

#### Selection behavior

##### Shift movement

If selection was inactive:

Start_Pos = Old_Caret
End_Pos   = New_Caret
Active    = True

If selection was active:

Start_Pos unchanged
End_Pos   = New_Caret
Active    = True

##### Non-shift movement
Active    = False
Start_Pos = New_Caret
End_Pos   = New_Caret

#### Editing Semantics

#### Insert_Char

##### Without selection

Insert at Old_Caret.

New_Caret = Old_Caret + 1
Selection collapsed at New_Caret
With selection

Delete [Sel_Min, Sel_Max) first, then insert at Sel_Min.

New_Caret = Sel_Min + 1
Selection collapsed

Editing Semantics
Insert_Char
Without selection

Insert at Old_Caret.

New_Caret = Old_Caret + 1
Selection collapsed at New_Caret

##### With selection

Delete [Sel_Min, Sel_Max) first, then insert at Sel_Min.

New_Caret = Sel_Min + 1
Selection collapsed

#### Undo / Redo

Undo and redo operate on full state snapshots.

They must restore:

buffer
caret
selection (Active, Start_Pos, End_Pos)

No recomputation is allowed after restore.

#### Buffer Contract

##### Insert

Insert(B, Index, Ch)
Index is a caret position
valid: 0 <= Index <= Length


##### Delete

Delete(B, Index)
Index is a storage index
valid: 1 <= Index <= Length

Executor mapping:

delete at caret C => Delete(B, C + 1)

##### Delete_Range

Delete_Range(B, Start, Span)
Start is caret index
deletes [Start, Start + Span)

#### Invariants Summary

- Single caret
- Caret ∈ [0, Length + 1]
- Selection stored unnormalized
- Anchor never changes during shift-selection
- Insert/Delete operate at Old_Caret
- Selection collapse rules are explicit
- Undo restores exact prior state

#### Debugging Rule

All invariants must hold:

before command execution
after command execution

Violations indicate a bug in executor logic, not tests.