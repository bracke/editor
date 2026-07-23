with Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Feature_Panel;

package Editor.Feature_Diagnostics.Labels is

   function Severity_Label_For_Display
     (Severity : Editor.Feature_Diagnostics.Diagnostic_Severity) return String;

   function Source_Kind_Label_For_Display
     (Source_Kind : Editor.Feature_Diagnostics.Diagnostic_Source_Kind) return String;

   function Severity_Label (Severity : Editor.Feature_Diagnostics.Diagnostic_Severity) return String;
   function Source_Kind_Label (Source_Kind : Editor.Feature_Diagnostics.Diagnostic_Source_Kind) return String;
   function Is_Build_Produced_Item (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return Boolean;
   function Producer_Label (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Target_Unavailable_Label (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Source_Filter_Label_For (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Source_Display_Label (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Stale_Label (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Row_State_Label (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Label_For (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Detail_For (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   function Group_Label_For (Item : Editor.Feature_Diagnostics.Diagnostic_Item) return String;
   procedure Refresh_Filter_Active
     (Diagnostics : in out Editor.Feature_Diagnostics.Diagnostics_Feature_State);
   function Normalize_Diagnostics_Filter_Text (Text : String) return String;
   function Bounded_Text
     (Text        : String;
      Maximum     : Natural;
      Empty_Value : String) return String;
   function Normalize_Message (Message : String) return String;
   function Normalize_Source_Label (Source_Label : String) return String;
   function Normalize_Replacement_Text (Replacement_Text : String) return String;
   function Normalize_Quick_Fix_Metadata (Text : String) return String;
   function Quick_Fix_Action_Model_For
     (Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Has_Edit : Boolean)
      return Editor.Feature_Diagnostics.Diagnostic_Quick_Fix_Action_Model;
   function Diagnostic_Action_Kind_Label
     (Kind : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
      return String;
   function Panel_Severity
     (Severity : Editor.Feature_Diagnostics.Diagnostic_Severity)
      return Editor.Feature_Panel.Feature_Row_Severity;

end Editor.Feature_Diagnostics.Labels;
