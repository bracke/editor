with Editor.Feature_Panel;
with Editor.State;

package Editor.Feature_Panel_Audit is

   type Feature_Panel_Audit_Result is record
      Descriptor_Count              : Natural := 0;
      Has_Missing_Descriptor         : Boolean := False;
      Has_Duplicate_Stable_Name      : Boolean := False;
      Has_Duplicate_Display_Label    : Boolean := False;
      Has_Missing_Projection_Handler : Boolean := False;
      Has_Missing_Clear_Handler      : Boolean := False;
      Has_Missing_Open_Handler       : Boolean := False;
      Has_Missing_Row_Action_Handler : Boolean := False;
      Has_Missing_Lifecycle_Handler  : Boolean := False;
      Has_Command_Registration_Gap   : Boolean := False;
      Has_Producer_Boundary_Gap      : Boolean := False;
      Has_Producer_Lifecycle_Gap     : Boolean := False;
      Has_Producer_Target_Gap        : Boolean := False;
      Passed                         : Boolean := False;
   end record;


   type Feature_Panel_Contract_Review is record
      Generic_State_Bounded         : Boolean := False;
      Active_Feature_Valid          : Boolean := False;
      Rows_Transient                : Boolean := False;
      Selection_Valid               : Boolean := False;
      Selection_Clamped             : Boolean := False;
      Activation_Routed             : Boolean := False;
      Targets_Validated            : Boolean := False;
      Lifecycle_Reset_Stable        : Boolean := False;
      Render_Snapshot_Pure          : Boolean := False;
      Persistence_Clean             : Boolean := False;
      Command_Surface_Intact        : Boolean := False;
      Public_Build_Guardrail_Intact : Boolean := False;
      Review_Passed                 : Boolean := False;
   end record;

   --  Compact review of the generic Feature Panel contract.
   --  This helper observes state and exercises only local copies when checking
   --  clamp/token/reset/render properties. It must not repair panel state,
   --  switch features, refresh features, post messages, execute commands,
   --  call process runners, or persist audit results.
   function Review_Feature_Panel_Contract
     (State : Editor.State.State_Type) return Feature_Panel_Contract_Review;

   --  Deterministic audit/test feedback. The returned text contains no argv,
   --  shell syntax, environment, filesystem path, PATH, run id, projection
   --  generation, or serialized row detail.
   function Build_Feature_Panel_Contract_Review_Feedback
     (Review : Feature_Panel_Contract_Review) return String;

   function Run_Feature_Panel_Audit return Feature_Panel_Audit_Result;

   function Audit_Feature_Descriptors return Feature_Panel_Audit_Result;

   function Summary (Result : Feature_Panel_Audit_Result) return String;

   function Feature_Command_Surface_Covers_All_Features return Boolean;

   function Producer_Boundary_Audit_Passes return Boolean;

   function Producer_Capable_Feature_Covers
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

   function Feature_Command_Surface_Covers
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean;

end Editor.Feature_Panel_Audit;
