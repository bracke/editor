with Editor.State;

package Editor.Feature_Diagnostics.Fixtures is

   procedure Select_Diagnostic_Item
     (S          : in out Editor.State.State_Type;
      Item_Index : Positive);

   procedure Select_Diagnostic_By_Message
     (S       : in out Editor.State.State_Type;
      Message : String);

end Editor.Feature_Diagnostics.Fixtures;
