package Editor.Feature_Diagnostics.Messages is

   function Message_Diagnostics_Shown return String;
   function Message_Diagnostics_Cleared return String;
   function Message_No_Diagnostics return String;
   function Message_No_Target return String;
   function Message_Target_Unavailable return String;
   function Message_Diagnostic_Added return String;
   function Message_No_Selected_Diagnostic return String;
   function Message_No_Visible_Diagnostic return String;
   function Message_Selected_Diagnostic_Cleared return String;
   function Message_Selected_Diagnostic_Copied return String;
   function Message_Info_Cleared return String;
   function Message_Warnings_Cleared return String;
   function Message_Errors_Cleared return String;
   function Message_Filter_Cleared return String;
   function Message_No_Filter_Active return String;
   function Message_All_Diagnostics_Shown return String;
   function Message_Info_Hidden return String;
   function Message_Info_Shown return String;
   function Message_Warnings_Hidden return String;
   function Message_Warnings_Shown return String;
   function Message_Errors_Hidden return String;
   function Message_Errors_Shown return String;
   function Message_No_Info_Diagnostics return String;
   function Message_No_Warning_Diagnostics return String;
   function Message_No_Error_Diagnostics return String;
   function Message_No_Build_Diagnostics return String;
   function Message_Build_Diagnostics_Cleared return String;
   function Message_Filter_Errors return String;
   function Message_Filter_Warnings return String;
   function Message_Filter_Info_Notes return String;
   function Message_Filter_Selected_Source return String;
   function Message_Filter_Selected_Source_Unavailable return String;
   function Message_Filter_Build return String;
   function Message_Source_Hidden
     (Source_Kind : Diagnostic_Source_Kind) return String;
   function Message_Source_Shown
     (Source_Kind : Diagnostic_Source_Kind) return String;

end Editor.Feature_Diagnostics.Messages;
