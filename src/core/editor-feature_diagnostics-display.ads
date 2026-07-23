with Editor.Ada_Diagnostic_Command_Projection;

package Editor.Feature_Diagnostics.Display is

   function Severity_Label_For_Display
     (Severity : Diagnostic_Severity) return String;

   function Source_Kind_Label_For_Display
     (Source_Kind : Diagnostic_Source_Kind) return String;

   function Severity_Label (Severity : Diagnostic_Severity) return String;

   function Source_Kind_Label (Source_Kind : Diagnostic_Source_Kind) return String;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean;

   function Producer_Label (Item : Diagnostic_Item) return String;

   function Target_Unavailable_Label (Item : Diagnostic_Item) return String;

   function Source_Filter_Label_For (Item : Diagnostic_Item) return String;

   function Source_Display_Label (Item : Diagnostic_Item) return String;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State);

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
      Has_Edit : Boolean) return Diagnostic_Quick_Fix_Action_Model;

   function Diagnostic_Action_Kind_Label
     (Kind : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
      return String;

   function Panel_Severity
     (Severity : Diagnostic_Severity) return Editor.Feature_Panel.Feature_Row_Severity;

end Editor.Feature_Diagnostics.Display;
