with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Image_Helpers;
with Editor.Feature_Diagnostics.Labels;

package body Editor.Feature_Diagnostics.Display is

   package Diag_Labels renames Editor.Feature_Diagnostics.Labels;

   function Severity_Label_For_Display
     (Severity : Diagnostic_Severity) return String
   is
   begin
      return Diag_Labels.Severity_Label_For_Display (Severity);
   end Severity_Label_For_Display;

   function Source_Kind_Label_For_Display
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return Diag_Labels.Source_Kind_Label_For_Display (Source_Kind);
   end Source_Kind_Label_For_Display;

   function Severity_Label (Severity : Diagnostic_Severity) return String is
   begin
      return Diag_Labels.Severity_Label (Severity);
   end Severity_Label;

   function Source_Kind_Label (Source_Kind : Diagnostic_Source_Kind) return String is
   begin
      return Diag_Labels.Source_Kind_Label (Source_Kind);
   end Source_Kind_Label;

   function Is_Build_Produced_Item (Item : Diagnostic_Item) return Boolean is
   begin
      return Diag_Labels.Is_Build_Produced_Item (Item);
   end Is_Build_Produced_Item;

   function Producer_Label (Item : Diagnostic_Item) return String is
   begin
      return Diag_Labels.Producer_Label (Item);
   end Producer_Label;

   function Target_Unavailable_Label (Item : Diagnostic_Item) return String is
   begin
      return Diag_Labels.Target_Unavailable_Label (Item);
   end Target_Unavailable_Label;

   function Source_Filter_Label_For (Item : Diagnostic_Item) return String is
   begin
      return Diag_Labels.Source_Filter_Label_For (Item);
   end Source_Filter_Label_For;

   function Source_Display_Label (Item : Diagnostic_Item) return String is
   begin
      return Diag_Labels.Source_Display_Label (Item);
   end Source_Display_Label;

   procedure Refresh_Filter_Active
     (Diagnostics : in out Diagnostics_Feature_State) is
   begin
      Diag_Labels.Refresh_Filter_Active (Diagnostics);
   end Refresh_Filter_Active;

   function Normalize_Diagnostics_Filter_Text (Text : String) return String is
   begin
      return Diag_Labels.Normalize_Diagnostics_Filter_Text (Text);
   end Normalize_Diagnostics_Filter_Text;

   function Bounded_Text
     (Text        : String;
      Maximum     : Natural;
      Empty_Value : String) return String is
   begin
      return Diag_Labels.Bounded_Text (Text, Maximum, Empty_Value);
   end Bounded_Text;

   function Normalize_Message (Message : String) return String is
   begin
      return Diag_Labels.Normalize_Message (Message);
   end Normalize_Message;

   function Normalize_Source_Label (Source_Label : String) return String is
   begin
      return Diag_Labels.Normalize_Source_Label (Source_Label);
   end Normalize_Source_Label;

   function Normalize_Replacement_Text (Replacement_Text : String) return String is
   begin
      return Diag_Labels.Normalize_Replacement_Text (Replacement_Text);
   end Normalize_Replacement_Text;

   function Normalize_Quick_Fix_Metadata (Text : String) return String is
   begin
      return Diag_Labels.Normalize_Quick_Fix_Metadata (Text);
   end Normalize_Quick_Fix_Metadata;

   function Quick_Fix_Action_Model_For
     (Primary_Action_Kind :
        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
      Has_Edit : Boolean) return Diagnostic_Quick_Fix_Action_Model
   is
   begin
      return Diag_Labels.Quick_Fix_Action_Model_For
        (Primary_Action_Kind, Has_Edit);
   end Quick_Fix_Action_Model_For;

   function Diagnostic_Action_Kind_Label
     (Kind : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind)
      return String
   is
   begin
      return Diag_Labels.Diagnostic_Action_Kind_Label (Kind);
   end Diagnostic_Action_Kind_Label;

   function Panel_Severity
     (Severity : Diagnostic_Severity) return Editor.Feature_Panel.Feature_Row_Severity
   is
   begin
      return Diag_Labels.Panel_Severity (Severity);
   end Panel_Severity;

end Editor.Feature_Diagnostics.Display;
