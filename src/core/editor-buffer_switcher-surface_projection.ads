with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with Editor.Input_Field;
with Editor.State;
with Guikit.List_Panel;
with Editor.Layout;

package Editor.Buffer_Switcher.Surface_Projection is

   package Preview_Line_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   type Buffer_Switcher_Render_Projection is record
      Visible          : Boolean := False;
      Panel            : Editor.Layout.Rect;
      Text_Columns     : Natural := 0;
      Header_Text      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Hint_Text        : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Query_Snapshot   : Editor.Input_Field.Field_Snapshot;
      Rows             : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
      Preview_Visible   : Boolean := False;
      Preview_Header    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Preview_Empty     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Preview_Lines     : Preview_Line_Vectors.Vector;
      Field_Y          : Natural := 0;
      Rows_Y           : Natural := 0;
      Footer_Y         : Natural := 0;
      Row_Height       : Natural := 0;
   end record;

   function Project
     (S               : Editor.State.State_Type;
      Viewport_Width   : Natural;
      Viewport_Height  : Natural;
      Layout_Origin_X  : Natural;
      Layout_Origin_Y  : Natural;
      Cell_W           : Natural;
      Cell_H           : Positive)
      return Buffer_Switcher_Render_Projection;

end Editor.Buffer_Switcher.Surface_Projection;
