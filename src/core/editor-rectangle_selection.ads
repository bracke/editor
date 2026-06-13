with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Cursors;
with Editor.State;

package Editor.Rectangle_Selection is

   type Rectangle_Range is record
      First_Row : Natural;
      Last_Row  : Natural;
      First_Col : Natural;
      Last_Col  : Natural;
   end record;

   function Normalize
     (Anchor_Row : Natural;
      Anchor_Col : Natural;
      Cursor_Row : Natural;
      Cursor_Col : Natural) return Rectangle_Range;

   procedure Point_To_Row_Col
     (S   : Editor.State.State_Type;
      X   : Natural;
      Y   : Natural;
      Row : out Natural;
      Col : out Natural);

   procedure Build_Carets
     (S     : in out Editor.State.State_Type;
      Selection_Range : Rectangle_Range);

   function Has_Selection
     (C : Editor.Cursors.Caret_State) return Boolean;

   function Has_Rectangular_Selection
     (S : Editor.State.State_Type) return Boolean;

   function Selection_Left_Column
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Natural;

   function Selection_Right_Column
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Natural;

   function Selection_Start_Position
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Editor.Cursors.Cursor_Index;

   function Selection_End_Position
     (S : Editor.State.State_Type;
      C : Editor.Cursors.Caret_State) return Editor.Cursors.Cursor_Index;

   function Rectangular_Copy_Text
     (S : Editor.State.State_Type) return Ada.Strings.Unbounded.Unbounded_String;

   procedure Build_Delete_Command
     (S   : Editor.State.State_Type;
      Cmd : out Editor.Commands.Command);

   procedure Collapse_After_Delete
     (S           : in out Editor.State.State_Type;
      Old_Carets  : Editor.Cursors.Cursors_Vector.Vector;
      New_Caret   : out Editor.Cursors.Cursor_Index);

end Editor.Rectangle_Selection;
