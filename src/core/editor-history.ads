with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Cursors;

package Editor.History is

   package Caret_Vectors renames Editor.Cursors.Cursors_Vector;

   type History_Group_Kind is
     (No_Group,
      Typing_Group);

   type History_Entry is record
      Forward : Editor.Commands.Command;
      Inverse : Editor.Commands.Command;

      --  Phase 370 reliability: exact text snapshots are the authoritative
      --  undo/redo payload. Forward/Inverse remain available for command/span
      --  diagnostics and replay support, but undo/redo restoration must not
      --  re-run semantic edit commands or depend on rendered/search state.
      Before_Text : Ada.Strings.Unbounded.Unbounded_String;
      After_Text  : Ada.Strings.Unbounded.Unbounded_String;

      Before_Carets : Caret_Vectors.Vector;
      After_Carets  : Caret_Vectors.Vector;

      Before_Preferred_Column : Natural := 0;
      After_Preferred_Column  : Natural := 0;

      Before_Rect_Select_Active : Boolean := False;
      After_Rect_Select_Active  : Boolean := False;
      Before_Rect_Anchor_Row    : Natural := 0;
      Before_Rect_Anchor_Col    : Natural := 0;
      After_Rect_Anchor_Row     : Natural := 0;
      After_Rect_Anchor_Col     : Natural := 0;

      Before_Dirty : Boolean := False;
      After_Dirty  : Boolean := False;

      --  Phase 370 owner/lifecycle guard: entries are transient and
      --  may only be restored into the buffer/lifecycle that captured
      --  them.  Project and buffer lifecycle cleanup should normally clear
      --  history before this guard is needed; this is the defensive backstop
      --  that prevents a stale entry from applying to the wrong active buffer.
      Owner_Buffer_Token : Natural := 0;
      Owner_Lifecycle_Generation : Natural := 0;

      Group_Kind : History_Group_Kind := No_Group;
   end record;

   function "=" (L, R : History_Entry) return Boolean;

   package History_Vector is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => History_Entry,
      "="          => "=");

   Undo_Stack : History_Vector.Vector;
   Redo_Stack : History_Vector.Vector;

end Editor.History;
