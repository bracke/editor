package Editor.Commands.Workflow_Messages is

   Reason_Target_Stale : constant String :=
     "Target is stale; refresh required.";
   Reason_Target_Missing : constant String :=
     "Target no longer exists.";
   Reason_Close_Review_Stale : constant String :=
     "Close review is stale";
   Reason_Project_Search_Result_Stale : constant String :=
     "Search result is stale; run Project Search again.";
   Reason_Search_Result_Stale_Rerun : constant String :=
     "Search result is stale; rerun search.";
   Reason_Replacement_Preview_Stale : constant String :=
     "Replacement preview is stale";
   Reason_Replacement_Preview_Stale_Rerun : constant String :=
     "Replacement preview is stale; rerun search.";
   Reason_Selected_Replacement_Stale : constant String :=
     "Selected replacement is stale";
   Reason_Diagnostic_Edit_Stale_Target : constant String :=
     "Diagnostic edit unavailable: stale edit target";
   Reason_File_Tree_Item_Stale : constant String :=
     "File Tree item is stale.";
   Reason_Target_Line_Unavailable : constant String :=
     "Target line is unavailable.";
   Reason_Diagnostic_Target_Line_Unavailable : constant String :=
     "Diagnostic target line is unavailable.";
   Reason_Diagnostic_Target_Line_Outside_Buffer : constant String :=
     "Diagnostic target line is outside the buffer";
   Reason_Diagnostic_Target_Column_Unavailable : constant String :=
     "Diagnostic target column is unavailable.";
   Reason_Diagnostic_Target_Column_Outside_Line : constant String :=
     "Diagnostic target column is outside the line";

   function Normalize_Workflow_Message
     (Text : String) return String;

end Editor.Commands.Workflow_Messages;
