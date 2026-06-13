with Ada.Strings.Unbounded;

package body Editor.Outline.Fixtures is

   use Ada.Strings.Unbounded;

   function To_Item
     (Kind   : Editor.Outline.Outline_Item_Kind;
      Label  : String;
      Detail : String;
      Depth  : Natural) return Editor.Outline.Outline_Item
   is
   begin
      return
        (Kind        => Kind,
         Label       => To_Unbounded_String (Label),
         Detail      => To_Unbounded_String (Detail),
         Depth       => Depth,
         Target_Kind  => Editor.Outline.No_Target,
         Buffer_Token => 0,
         Line         => 0,
         Column       => 0);
   end To_Item;

   function Populate_Synthetic_Outline
     (Outline : in out Editor.Outline.Outline_State)
      return Editor.Outline.Outline_Refresh_Result
   is
      Items : constant Editor.Outline.Outline_Item_Array :=
        (1 => To_Item
                (Editor.Outline.Outline_Header,
                 "Outline", "test fixture outline", 0),
         2 => To_Item
                (Editor.Outline.Outline_Package,
                 "Synthetic.Package", "package", 0),
         3 => To_Item
                (Editor.Outline.Outline_Type,
                 "Synthetic_Type", "type", 1),
         4 => To_Item
                (Editor.Outline.Outline_Subprogram,
                 "Synthetic_Procedure", "subprogram", 1),
         5 => To_Item
                (Editor.Outline.Outline_Field,
                 "Synthetic_Field", "field", 2));
   begin
      Editor.Outline.Replace_Items (Outline, Items);
      return
        (Status       => Editor.Outline.Outline_Refresh_Ok,
         Failure_Kind => Editor.Outline.No_Failure,
         Item_Count   => Editor.Outline.Item_Count (Outline),
         Source_Class => Editor.Outline.Source_Class (Outline));
   end Populate_Synthetic_Outline;

end Editor.Outline.Fixtures;
