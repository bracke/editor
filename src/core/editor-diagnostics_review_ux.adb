with Ada.Strings.Fixed;
with Editor.State;
with Editor.Workspace_Persistence;
with Editor.Build_Diagnostics;
with Editor.Build_Diagnostics_Review;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Commands;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;

package body Editor.Diagnostics_Review_UX is

   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Id;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Assert_Diagnostics_Display_Labels_Are_User_Readable
     (State : Editor.State.State_Type) return Boolean
   is
      Diagnostics : Editor.Feature_Diagnostics.Diagnostics_Feature_State
        renames State.Feature_Diagnostics;
   begin
      if Editor.Feature_Diagnostics.Row_Count (Diagnostics) = 0 then
         return Editor.Feature_Diagnostics.Header_Text (Diagnostics) =
           "No diagnostics.";
      end if;

      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (Diagnostics) loop
         declare
            Label    : constant String :=
              Editor.Feature_Diagnostics.Item_Display_Label (Diagnostics, I);
            Source   : constant String :=
              Editor.Feature_Diagnostics.Item_Source_Display_Label (Diagnostics, I);
            Producer : constant String :=
              Editor.Feature_Diagnostics.Producer_Label_For_Display (Diagnostics, I);
            Message  : constant String :=
              Editor.Feature_Diagnostics.Item_Message (Diagnostics, I);
         begin
            if Label'Length = 0
              or else Message'Length = 0
              or else Source'Length = 0
              or else Producer'Length = 0
              or else not Contains (Label, Message)
              or else not Contains (Label, Source)
              or else not Contains (Label, Producer)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Assert_Diagnostics_Display_Labels_Are_User_Readable;

   function Assert_Diagnostics_Counts_Are_Correct
     (State : Editor.State.State_Type) return Boolean
   is
      Counts : constant Editor.Feature_Diagnostics.Diagnostics_Severity_Counts :=
        Editor.Feature_Diagnostics.Count_By_Severity (State.Feature_Diagnostics);
      Manual_Total : constant Natural :=
        Counts.Errors + Counts.Warnings + Counts.Info + Counts.Notes + Counts.Unknown;
      Manual_Visible_Total : constant Natural :=
        Counts.Visible_Errors + Counts.Visible_Warnings + Counts.Visible_Info +
        Counts.Visible_Notes + Counts.Visible_Unknown;
      Header : constant String :=
        Editor.Feature_Diagnostics.Header_Text (State.Feature_Diagnostics);
   begin
      return Counts.Total =
          Editor.Feature_Diagnostics.Row_Count (State.Feature_Diagnostics)
        and then Manual_Total = Counts.Total
        and then Counts.Visible =
          Editor.Feature_Diagnostics.Visible_Row_Count (State.Feature_Diagnostics)
        and then Manual_Visible_Total = Counts.Visible
        and then Contains (Editor.Feature_Diagnostics.Count_Label (Counts), "Errors:")
        and then Contains (Editor.Feature_Diagnostics.Count_Label (Counts), "Warnings:")
        and then Contains (Editor.Feature_Diagnostics.Count_Label (Counts), "Total:")
        and then Contains (Editor.Feature_Diagnostics.Visible_Count_Label (Counts), "Visible Total:")
        and then (Counts.Total = 0 or else Contains (Header, "Total:"));
   end Assert_Diagnostics_Counts_Are_Correct;

   function Assert_Diagnostics_Message_Text_Is_Bounded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Feature_Diagnostics.Diagnostic_Message_Text_Is_Bounded
          (State.Feature_Diagnostics);
   end Assert_Diagnostics_Message_Text_Is_Bounded;

   function Assert_Diagnostics_Source_Label_Text_Is_Bounded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Feature_Diagnostics.Diagnostic_Source_Label_Text_Is_Bounded
          (State.Feature_Diagnostics);
   end Assert_Diagnostics_Source_Label_Text_Is_Bounded;


   function Assert_Diagnostics_Filter_Does_Not_Delete_Rows
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.Feature_Diagnostics.Diagnostics_Feature_State :=
        State.Feature_Diagnostics;
      Before : constant Natural := Editor.Feature_Diagnostics.Row_Count (Copy);
   begin
      Editor.Feature_Diagnostics.Filter_Errors_Only (Copy);
      if Editor.Feature_Diagnostics.Row_Count (Copy) /= Before then
         return False;
      end if;
      Editor.Feature_Diagnostics.Filter_Warnings_Only (Copy);
      if Editor.Feature_Diagnostics.Row_Count (Copy) /= Before then
         return False;
      end if;
      Editor.Feature_Diagnostics.Filter_Build_Produced (Copy);
      if Editor.Feature_Diagnostics.Row_Count (Copy) /= Before then
         return False;
      end if;
      Editor.Feature_Diagnostics.Show_All (Copy);
      return Editor.Feature_Diagnostics.Row_Count (Copy) = Before;
   end Assert_Diagnostics_Filter_Does_Not_Delete_Rows;



   function Assert_Diagnostics_Source_Filter_Does_Not_Delete_Rows
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.Feature_Diagnostics.Diagnostics_Feature_State :=
        State.Feature_Diagnostics;
      Before : constant Natural := Editor.Feature_Diagnostics.Row_Count (Copy);
   begin
      Editor.Feature_Diagnostics.Filter_Source_Label (Copy, "src");
      return Editor.Feature_Diagnostics.Row_Count (Copy) = Before
        and then Editor.Feature_Diagnostics.Filter_Active (Copy);
   end Assert_Diagnostics_Source_Filter_Does_Not_Delete_Rows;

   function Assert_Diagnostics_File_Grouping_Is_Projection_Only
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.Feature_Diagnostics.Diagnostics_Feature_State :=
        State.Feature_Diagnostics;
      Before : constant Natural := Editor.Feature_Diagnostics.Row_Count (Copy);
      Groups_Before : constant Natural :=
        Editor.Feature_Diagnostics.File_Group_Count (Copy);
      Groups_After : Natural := 0;
   begin
      Editor.Feature_Diagnostics.Filter_Errors_Only (Copy);
      Groups_After := Editor.Feature_Diagnostics.File_Group_Count (Copy);
      return Editor.Feature_Diagnostics.Row_Count (Copy) = Before
        and then (Before = 0 or else Groups_Before > 0)
        and then Groups_After <= Groups_Before;
   end Assert_Diagnostics_File_Grouping_Is_Projection_Only;

   function Assert_Diagnostics_Build_Filter_Uses_Producer_Predicate
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.Feature_Diagnostics.Diagnostics_Feature_State :=
        State.Feature_Diagnostics;
      Before : constant Natural := Editor.Feature_Diagnostics.Row_Count (Copy);
   begin
      Editor.Feature_Diagnostics.Filter_Build_Produced (Copy);
      declare
         Text : constant String := Editor.Feature_Diagnostics.Filter_Text (Copy);
      begin
         return Editor.Feature_Diagnostics.Row_Count (Copy) = Before
           and then Editor.Feature_Diagnostics.Filter_Active (Copy)
           and then Text'Length = 0;
      end;
   end Assert_Diagnostics_Build_Filter_Uses_Producer_Predicate;

   function Assert_Diagnostics_Navigation_Uses_File_Lifecycle
     (State : Editor.State.State_Type) return Boolean
   is
      pragma Unreferenced (State);
      Found : Boolean := False;
   begin
      return Editor.Commands.Descriptor
          (Editor.Commands.Command_Diagnostics_Open_Selected).Category =
          Editor.Commands.Panel_Category
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Open_Selected) =
          "diagnostics.open-selected"
        and then Editor.Commands.Command_Id_From_Stable_Name
          ("diagnostics.open-selected", Found) =
          Editor.Commands.Command_Diagnostics_Open_Selected
        and then Found
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Filter_Errors) =
          "diagnostics.filter-errors"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Filter_Warnings) =
          "diagnostics.filter-warnings"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Filter_Source) =
          "diagnostics.filter-source"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Filter_Build) =
          "diagnostics.filter-producer-build"
        and then Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Diagnostics_Clear_Build) =
          "diagnostics.clear-build"
        and then Editor.Build_Diagnostics_Review.Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes;
   end Assert_Diagnostics_Navigation_Uses_File_Lifecycle;

   function Assert_Diagnostics_Source_Less_Rows_Do_Not_Navigate_Silently
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count
        (State.Feature_Diagnostics)
      loop
         if not Editor.Feature_Diagnostics.Item_Has_Target
             (State.Feature_Diagnostics, I)
           and then Editor.Feature_Diagnostics.Item_Target_Unavailable_Label
             (State.Feature_Diagnostics, I)'Length = 0
         then
            return False;
         end if;
      end loop;
      return String'(Editor.Feature_Diagnostics.Message_No_Target)'Length > 0
        and then String'(Editor.Feature_Diagnostics.Message_Target_Unavailable)'Length > 0;
   end Assert_Diagnostics_Source_Less_Rows_Do_Not_Navigate_Silently;


   function Assert_Diagnostics_Edit_Marks_Stale_Rather_Than_Clears
     (State : Editor.State.State_Type) return Boolean
   is
      Copy   : Editor.State.State_Type := State;
      Token  : Natural := Copy.Active_Buffer_Token;
      Before : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (Copy.Feature_Diagnostics);
      Added  : constant Positive := Positive (Before + 1);
   begin
      if Token = Editor.Feature_Diagnostics.No_Buffer then
         Token := 1;
         Copy.Active_Buffer_Token := Token;
      end if;

      Editor.Feature_Diagnostics.Add_Diagnostic
        (Copy.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "stale edit target",
         Source_Label  => "src/main.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Token,
         Target_Line   => 1,
         Target_Column => 1);

      Editor.State.Rebuild_After_Buffer_Change (Copy);

      return Editor.Feature_Diagnostics.Row_Count (Copy.Feature_Diagnostics) = Before + 1
        and then Editor.Feature_Diagnostics.Item_Is_Stale
          (Copy.Feature_Diagnostics, Added)
        and then Contains
          (Editor.Feature_Diagnostics.Item_Display_Label
             (Copy.Feature_Diagnostics, Added),
           "stale");
   end Assert_Diagnostics_Edit_Marks_Stale_Rather_Than_Clears;

   function Assert_Diagnostics_Clear_Does_Not_Mutate_Build_Output
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.State.State_Type := State;
   begin
      Editor.Feature_Diagnostics.Clear_Diagnostics (Copy.Feature_Diagnostics);
      return Editor.Build_Diagnostics_Review.Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
          (Copy.Latest_Build_Output_Details)
        and then Editor.Build_Diagnostics_Review.Assert_Build_Summary_Stores_No_Diagnostics_Rows
          (Copy.Latest_Build_Result);
   end Assert_Diagnostics_Clear_Does_Not_Mutate_Build_Output;

   function Assert_Build_UI_Diagnostics_Display_Is_Scalar_Only
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return not Editor.Build_UI.Has_Raw_Shell_Command_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Remembered_Consent_Field (State.Build_UI)
        and then not Editor.Build_UI.Has_Candidate_Execution_Field (State.Build_UI)
        and then Editor.Build_Diagnostics_Review.Assert_Build_Diagnostics_Not_Build_Owned
          (State);
   end Assert_Build_UI_Diagnostics_Display_Is_Scalar_Only;

   function Assert_Output_Details_Do_Not_Own_Diagnostics
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_Diagnostics_Review.Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
          (State.Latest_Build_Output_Details);
   end Assert_Output_Details_Do_Not_Own_Diagnostics;

   function Assert_Diagnostics_Render_Is_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return Editor.Build_Diagnostics.Assert_Build_Diagnostics_Render_Not_Parsing;
   end Assert_Diagnostics_Render_Is_Side_Effect_Free;

   function Assert_Diagnostics_Filter_Selection_Not_Persisted
     (State : Editor.State.State_Type) return Boolean
   is
      Snapshot : constant Editor.Workspace_Persistence.Workspace_Snapshot :=
        Editor.State.Build_Workspace_Snapshot (State);
      Summary : constant String :=
        Editor.Workspace_Persistence.Debug_Summary (Snapshot);
   begin
      return Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) = 0
        and then not Contains (Summary, "diagnostics-filter")
        and then not Contains (Summary, "diagnostics-selection")
        and then not Contains (Summary, "diagnostics-projection")
        and then not Contains (Summary, "build-diagnostics")
        and then Contains (Summary, "diagnostics=0");
   end Assert_Diagnostics_Filter_Selection_Not_Persisted;

   function Run_Diagnostics_Review_UX_Audit
     (State : Editor.State.State_Type) return Diagnostics_Review_UX_Result
   is
      Result : Diagnostics_Review_UX_Result;
   begin
      Result.Rows_Have_Readable_Labels :=
        Assert_Diagnostics_Display_Labels_Are_User_Readable (State);
      Result.Row_Message_Text_Is_Bounded :=
        Assert_Diagnostics_Message_Text_Is_Bounded (State);
      Result.Row_Source_Label_Text_Is_Bounded :=
        Assert_Diagnostics_Source_Label_Text_Is_Bounded (State);
      Result.Severity_Counts_Are_Useful :=
        Assert_Diagnostics_Counts_Are_Correct (State);
      Result.Filters_Are_Projection_Only :=
        Assert_Diagnostics_Filter_Does_Not_Delete_Rows (State);
      Result.Source_Filter_Is_Projection_Only :=
        Assert_Diagnostics_Source_Filter_Does_Not_Delete_Rows (State);
      Result.File_Grouping_Is_Projection_Only :=
        Assert_Diagnostics_File_Grouping_Is_Projection_Only (State);
      Result.Build_Filter_Uses_Producer_Predicate :=
        Assert_Diagnostics_Build_Filter_Uses_Producer_Predicate (State);
      Result.Navigation_Routes_Are_Diagnostics :=
        Assert_Diagnostics_Navigation_Uses_File_Lifecycle (State);
      Result.Missing_Source_Targets_Are_Clear :=
        Assert_Diagnostics_Source_Less_Rows_Do_Not_Navigate_Silently (State);
      Result.Edit_Stale_Lifecycle_Is_Clear :=
        Assert_Diagnostics_Edit_Marks_Stale_Rather_Than_Clears (State);
      declare
         Build_Cleared : constant String :=
           Editor.Feature_Diagnostics.Message_Build_Diagnostics_Cleared;
         No_Build : constant String :=
           Editor.Feature_Diagnostics.Message_No_Build_Diagnostics;
      begin
         Result.Build_Producer_Boundary_Is_Clear :=
           Build_Cleared'Length > 0
           and then No_Build'Length > 0
           and then Editor.Commands.Has_Descriptor
             (Editor.Commands.Command_Diagnostics_Clear_Build);
      end;
      Result.Build_UI_Is_Scalar_Only :=
        Assert_Build_UI_Diagnostics_Display_Is_Scalar_Only (State);
      Result.Output_Details_Are_Output_Only :=
        Assert_Output_Details_Do_Not_Own_Diagnostics (State);
      Result.Render_Is_Observational :=
        Assert_Diagnostics_Render_Is_Side_Effect_Free (State);
      Result.Command_Frontdoors_Carry_No_Payload :=
        Editor.Build_Diagnostics_Review.Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload (State);
      Result.Persistence_Excludes_Review_State :=
        Assert_Diagnostics_Filter_Selection_Not_Persisted (State);
      Result.Coherent :=
        Result.Rows_Have_Readable_Labels
        and then Result.Row_Message_Text_Is_Bounded
        and then Result.Row_Source_Label_Text_Is_Bounded
        and then Result.Severity_Counts_Are_Useful
        and then Result.Filters_Are_Projection_Only
        and then Result.Source_Filter_Is_Projection_Only
        and then Result.File_Grouping_Is_Projection_Only
        and then Result.Build_Filter_Uses_Producer_Predicate
        and then Result.Navigation_Routes_Are_Diagnostics
        and then Result.Missing_Source_Targets_Are_Clear
        and then Result.Edit_Stale_Lifecycle_Is_Clear
        and then Result.Build_Producer_Boundary_Is_Clear
        and then Result.Build_UI_Is_Scalar_Only
        and then Result.Output_Details_Are_Output_Only
        and then Result.Render_Is_Observational
        and then Result.Command_Frontdoors_Carry_No_Payload
        and then Result.Persistence_Excludes_Review_State;
      return Result;
   end Run_Diagnostics_Review_UX_Audit;

   function Assert_Diagnostics_Review_UX_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Run_Diagnostics_Review_UX_Audit (State).Coherent;
   end Assert_Diagnostics_Review_UX_Coherent;

end Editor.Diagnostics_Review_UX;
