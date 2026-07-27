with AUnit.Assertions; use AUnit.Assertions;
with Editor.Feature_Panel;

package body Editor.Feature_Diagnostics.Fixtures is

   procedure Select_Diagnostic_Item
     (S          : in out Editor.State.State_Type;
      Item_Index : Positive)
   is
      Mapped : Natural := 0;
   begin
      Project_Rows (S.Panel.Feature_Diagnostics, S.Panel.Feature_Panel);
      for Row in 1 .. Editor.Feature_Panel.Row_Count (S.Panel.Feature_Panel) loop
         Mapped := Map_Diagnostic_Row_To_Item
           (S.Panel.Feature_Diagnostics,
            S.Panel.Feature_Panel,
            Row,
            Editor.Feature_Panel.Projection_Generation (S.Panel.Feature_Panel));
         if Mapped = Natural (Item_Index) then
            Editor.Feature_Panel.Select_Row (S.Panel.Feature_Panel, Row);
            return;
         end if;
      end loop;
      Assert (False, "diagnostic item is projected and selectable");
   end Select_Diagnostic_Item;

   procedure Select_Diagnostic_By_Message
     (S       : in out Editor.State.State_Type;
      Message : String)
   is
   begin
      for Index in 1 .. Row_Count (S.Panel.Feature_Diagnostics) loop
         if Item_Message (S.Panel.Feature_Diagnostics, Positive (Index)) = Message then
            Select_Diagnostic_Item (S, Positive (Index));
            return;
         end if;
      end loop;
      Assert (False, "diagnostic message is present and selectable: " & Message);
   end Select_Diagnostic_By_Message;

end Editor.Feature_Diagnostics.Fixtures;
