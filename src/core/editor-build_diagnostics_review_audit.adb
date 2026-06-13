with Editor.Build_Diagnostics_Review;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;

package body Editor.Build_Diagnostics_Review_Audit is

   function Run_Build_Diagnostics_Review_Audit
     (State : Editor.State.State_Type)
      return Build_Diagnostics_Review_Audit_Result
   is
      Before_Row_Count : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics);
      Before_Visible_Count : constant Natural :=
        Editor.Feature_Diagnostics.Visible_Row_Count (State.Feature_Diagnostics);
      Before_Selected_Row : constant Natural :=
        Editor.Feature_Panel.Selected_Row (State.Feature_Panel);
      Result : Build_Diagnostics_Review_Audit_Result;
   begin
      Result.Review :=
        Editor.Build_Diagnostics_Review.Run_Build_Diagnostics_Review (State);
      Result.Source_Labels_Practical :=
        Editor.Build_Diagnostics_Review.Assert_Build_Diagnostics_Source_Labels_Practical
          (State);
      Result.Command_Frontdoors_Carry_No_Payload :=
        Editor.Build_Diagnostics_Review.Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload
          (State);
      Result.Navigation_Workflow_Coherent :=
        Editor.Build_Diagnostics_Review.Assert_Public_Build_Diagnostics_Navigation_Workflow_Coherent
          (State);
      Result.Audit_Side_Effect_Free :=
        Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics) = Before_Row_Count
        and then Editor.Feature_Diagnostics.Visible_Row_Count (State.Feature_Diagnostics) = Before_Visible_Count
        and then Editor.Feature_Panel.Selected_Row (State.Feature_Panel) = Before_Selected_Row;
      Result.Coherent := Result.Review.Coherent
        and then Result.Source_Labels_Practical
        and then Result.Command_Frontdoors_Carry_No_Payload
        and then Result.Navigation_Workflow_Coherent
        and then Result.Audit_Side_Effect_Free;
      return Result;
   end Run_Build_Diagnostics_Review_Audit;

end Editor.Build_Diagnostics_Review_Audit;
