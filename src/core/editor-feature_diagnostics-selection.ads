with Editor.Commands;
with Editor.Feature_Panel;

package Editor.Feature_Diagnostics.Selection is

   procedure Project_Rows
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   function Index_For_Id
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural;

   function Selected_Diagnostic_Source_Index
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Natural;

   function Has_Selected_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Selected_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Diagnostic_Id;

   function Selected_Diagnostic_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return Boolean;

   function Selected_Diagnostic_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Selected_Diagnostic_Open_Unavailable_Reason
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Format_Diagnostic_For_Copy
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Selected_Diagnostic_Text
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Selected_Diagnostic_Source_Filter_Label
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State) return String;

   function Row_Is_Live_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : Editor.Feature_Panel.Feature_Panel_State;
      Row         : Natural) return Boolean;

   procedure Select_Next_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   procedure Select_Previous_Diagnostic
     (Diagnostics : Diagnostics_Feature_State;
      Panel       : in out Editor.Feature_Panel.Feature_Panel_State);

   function Next_Diagnostic_Id
     (Diagnostics : Diagnostics_Feature_State) return Diagnostic_Id;

   function Item_Has_Target
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Target_Buffer
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Target_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Target_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Map_Diagnostic_Id_To_Item
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Natural;

   function Diagnostic_Id_Is_Live
     (Diagnostics : Diagnostics_Feature_State;
      Id          : Diagnostic_Id) return Boolean;

end Editor.Feature_Diagnostics.Selection;
