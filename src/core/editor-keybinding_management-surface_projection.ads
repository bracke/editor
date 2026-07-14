with Ada.Strings.Unbounded;

with Guikit.List_Panel;
with Guikit.Segmented;

package Editor.Keybinding_Management.Surface_Projection is

   type Keybinding_Surface_Render_Projection is record
      Filter_Index : Positive := 1;
      Segments     : Guikit.Segmented.Segment_Vectors.Vector;
      Command_Rows : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
      Chord_Rows   : Guikit.List_Panel.List_Panel_Row_Vectors.Vector;
      Status_Line  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   function Project
     (Surface      : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Text_Columns : Natural)
      return Keybinding_Surface_Render_Projection;

end Editor.Keybinding_Management.Surface_Projection;
