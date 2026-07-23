package body Editor.Feature_Diagnostics.Messages is

   function Message_Diagnostics_Shown return String is
   begin
      return "Diagnostics shown.";
   end Message_Diagnostics_Shown;

   function Message_Diagnostics_Cleared return String is
   begin
      return "Diagnostics cleared.";
   end Message_Diagnostics_Cleared;

   function Message_No_Diagnostics return String is
   begin
      return "No diagnostics.";
   end Message_No_Diagnostics;

   function Message_No_Target return String is
   begin
      return "Selected diagnostic has no source target.";
   end Message_No_Target;

   function Message_Target_Unavailable return String is
   begin
      return "Diagnostic target file is unavailable.";
   end Message_Target_Unavailable;

   function Message_Diagnostic_Added return String is
   begin
      return "Diagnostic added.";
   end Message_Diagnostic_Added;

   function Message_No_Selected_Diagnostic return String is
   begin
      return "No diagnostic selected";
   end Message_No_Selected_Diagnostic;

   function Message_No_Visible_Diagnostic return String is
   begin
      return "No diagnostics match the current filter.";
   end Message_No_Visible_Diagnostic;

   function Message_Selected_Diagnostic_Cleared return String is
   begin
      return "Selected diagnostic cleared.";
   end Message_Selected_Diagnostic_Cleared;

   function Message_Selected_Diagnostic_Copied return String is
   begin
      return "Selected diagnostic copied.";
   end Message_Selected_Diagnostic_Copied;

   function Message_Info_Cleared return String is
   begin
      return "Diagnostic info/note rows cleared.";
   end Message_Info_Cleared;

   function Message_Warnings_Cleared return String is
   begin
      return "Diagnostics: warnings cleared";
   end Message_Warnings_Cleared;

   function Message_Errors_Cleared return String is
   begin
      return "Diagnostics: errors cleared";
   end Message_Errors_Cleared;

   function Message_Filter_Cleared return String is
   begin
      return "Diagnostics: filter cleared";
   end Message_Filter_Cleared;

   function Message_No_Filter_Active return String is
   begin
      return "No filter is active";
   end Message_No_Filter_Active;

   function Message_All_Diagnostics_Shown return String is
   begin
      return "Diagnostics: all diagnostics shown";
   end Message_All_Diagnostics_Shown;

   function Message_Info_Hidden return String is
   begin
      return "Diagnostics: info hidden";
   end Message_Info_Hidden;

   function Message_Info_Shown return String is
   begin
      return "Diagnostics: info shown";
   end Message_Info_Shown;

   function Message_Warnings_Hidden return String is
   begin
      return "Diagnostics: warnings hidden";
   end Message_Warnings_Hidden;

   function Message_Warnings_Shown return String is
   begin
      return "Diagnostics: warnings shown";
   end Message_Warnings_Shown;

   function Message_Errors_Hidden return String is
   begin
      return "Diagnostics: errors hidden";
   end Message_Errors_Hidden;

   function Message_Errors_Shown return String is
   begin
      return "Diagnostics: errors shown";
   end Message_Errors_Shown;

   function Message_No_Info_Diagnostics return String is
   begin
      return "No info or note diagnostics.";
   end Message_No_Info_Diagnostics;

   function Message_No_Warning_Diagnostics return String is
   begin
      return "No warning diagnostics.";
   end Message_No_Warning_Diagnostics;

   function Message_No_Error_Diagnostics return String is
   begin
      return "No error diagnostics.";
   end Message_No_Error_Diagnostics;

   function Message_No_Build_Diagnostics return String is
   begin
      return "No build diagnostics.";
   end Message_No_Build_Diagnostics;

   function Message_Build_Diagnostics_Cleared return String is
   begin
      return "Diagnostics: build diagnostics cleared";
   end Message_Build_Diagnostics_Cleared;

   function Message_Filter_Errors return String is
   begin
      return "Diagnostics: errors only";
   end Message_Filter_Errors;

   function Message_Filter_Warnings return String is
   begin
      return "Diagnostics: warnings only";
   end Message_Filter_Warnings;

   function Message_Filter_Info_Notes return String is
   begin
      return "Diagnostics: info and notes only";
   end Message_Filter_Info_Notes;

   function Message_Filter_Selected_Source return String is
   begin
      return "Diagnostics: selected source only";
   end Message_Filter_Selected_Source;

   function Message_Filter_Selected_Source_Unavailable return String is
   begin
      return "Selected diagnostic has no source label";
   end Message_Filter_Selected_Source_Unavailable;

   function Message_Filter_Build return String is
   begin
      return "Diagnostics: build producer only";
   end Message_Filter_Build;

   function Message_Source_Hidden
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return "Diagnostics: " & Source_Kind_Label_For_Display (Source_Kind) & " hidden";
   end Message_Source_Hidden;

   function Message_Source_Shown
     (Source_Kind : Diagnostic_Source_Kind) return String
   is
   begin
      return "Diagnostics: " & Source_Kind_Label_For_Display (Source_Kind) & " shown";
   end Message_Source_Shown;

end Editor.Feature_Diagnostics.Messages;
