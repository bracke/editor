with Editor.State;

package Editor.Diagnostics_Review_UX is

   --  Phase 557 Diagnostics review UX coherence helpers.  This package is
   --  observational: it does not run builds, parse output, open files, move
   --  carets, mutate Diagnostics rows, mutate filters/selection, render, or
   --  persist anything.  It asserts that the retained Diagnostics feature is a
   --  practical Problems-style review surface while Build UI and Output
   --  Details remain scalar/output-only boundaries.

   type Diagnostics_Review_UX_Result is record
      Rows_Have_Readable_Labels             : Boolean := False;
      Row_Message_Text_Is_Bounded           : Boolean := False;
      Row_Source_Label_Text_Is_Bounded      : Boolean := False;
      Severity_Counts_Are_Useful            : Boolean := False;
      Filters_Are_Projection_Only           : Boolean := False;
      Source_Filter_Is_Projection_Only      : Boolean := False;
      File_Grouping_Is_Projection_Only      : Boolean := False;
      Build_Filter_Uses_Producer_Predicate  : Boolean := False;
      Navigation_Routes_Are_Diagnostics     : Boolean := False;
      Missing_Source_Targets_Are_Clear      : Boolean := False;
      Edit_Stale_Lifecycle_Is_Clear         : Boolean := False;
      Build_Producer_Boundary_Is_Clear      : Boolean := False;
      Build_UI_Is_Scalar_Only               : Boolean := False;
      Output_Details_Are_Output_Only        : Boolean := False;
      Render_Is_Observational               : Boolean := False;
      Command_Frontdoors_Carry_No_Payload   : Boolean := False;
      Persistence_Excludes_Review_State     : Boolean := False;
      Coherent                              : Boolean := False;
   end record;

   function Run_Diagnostics_Review_UX_Audit
     (State : Editor.State.State_Type) return Diagnostics_Review_UX_Result;

   function Assert_Diagnostics_Display_Labels_Are_User_Readable
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Counts_Are_Correct
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Message_Text_Is_Bounded
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Source_Label_Text_Is_Bounded
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Filter_Does_Not_Delete_Rows
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Source_Filter_Does_Not_Delete_Rows
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_File_Grouping_Is_Projection_Only
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Build_Filter_Uses_Producer_Predicate
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Navigation_Uses_File_Lifecycle
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Source_Less_Rows_Do_Not_Navigate_Silently
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Edit_Marks_Stale_Rather_Than_Clears
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Clear_Does_Not_Mutate_Build_Output
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_UI_Diagnostics_Display_Is_Scalar_Only
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Output_Details_Do_Not_Own_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Render_Is_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Filter_Selection_Not_Persisted
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Diagnostics_Review_UX_Coherent
     (State : Editor.State.State_Type) return Boolean;

end Editor.Diagnostics_Review_UX;
