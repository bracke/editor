with Ada.Containers.Vectors;
with Text_Buffer;
with Editor.Cursors;
with Editor.Selection;

package Editor.State is

   Max_Carets : constant Positive := 100;

   type State_Type is record
      Buffer      : Text_Buffer.Buffer_Type;
      Carets      : Editor.Cursors.Cursors_Vector.Vector;
      Anchor      : Editor.Cursors.Cursor_Index := 0;
      Selection   : Editor.Selection.Selection_State;
   end record;

   ------------------------------------------------------------------------
   -- Constructor
   ------------------------------------------------------------------------
   procedure Init (S : out State_Type);

   ------------------------------------------------------------------------
   -- Invariant enforcement
   ------------------------------------------------------------------------
   procedure Normalize_Carets (S : in out State_Type);

end Editor.State;