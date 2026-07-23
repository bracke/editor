with Editor.Ada_Diagnostic_Command_Projection;

package Editor.Feature_Diagnostics.Item_Accessors is

   function Row_Count
     (Diagnostics : Diagnostics_Feature_State) return Natural;

   function Is_Empty
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Item_Id
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Id;

   function Item_Severity
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Severity;

   function Item_Message
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Diagnostic_Message_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Diagnostic_Source_Label_Text_Is_Bounded
     (Diagnostics : Diagnostics_Feature_State) return Boolean;

   function Item_Source_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Source_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Diagnostic_Source_Kind;

   function Item_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Producer_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Source_Display_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Target_Unavailable_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Row_State_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Is_Stale
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Stale_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Is_Build_Produced
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Primary_Action_Kind
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   function Item_Has_Edit
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Boolean;

   function Item_Edit_Start_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Edit_Start_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Edit_End_Line
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Edit_End_Column
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Replacement_Text
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Label
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Detail
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Action_Count
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return Natural;

   function Item_Quick_Fix_Action_Label_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String;

   function Item_Quick_Fix_Action_Detail_For_Display
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String;

   function Item_Quick_Fix_Action_Kind
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive)
      return Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;

   function Item_Quick_Fix_Action_Model
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Diagnostic_Quick_Fix_Action_Model;

   function Item_Quick_Fix_Action_Has_Edit
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Boolean;

   function Item_Quick_Fix_Action_Edit_Start_Line
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Edit_Start_Column
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Edit_End_Line
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Edit_End_Column
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return Natural;

   function Item_Quick_Fix_Action_Replacement_Text
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Positive) return String;

   function Quick_Fix_Action_Is_Intrinsically_Available
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Natural) return Boolean;

   function Quick_Fix_Action_Intrinsic_Unavailable_Reason
     (Diagnostics  : Diagnostics_Feature_State;
      Index        : Positive;
      Action_Index : Natural) return String;

   function Item_Quick_Fix_Label_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

   function Item_Quick_Fix_Detail_For_Display
     (Diagnostics : Diagnostics_Feature_State;
      Index       : Positive) return String;

end Editor.Feature_Diagnostics.Item_Accessors;
