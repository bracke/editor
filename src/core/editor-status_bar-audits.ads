with Ada.Strings.Unbounded;

package Editor.Status_Bar.Audits is

   function Assert_Status_Snapshot_Is_Observational
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Active_Buffer_And_Dirty_State
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Caret_And_Selection
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Command_Outcome
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Does_Not_Copy_Feature_Rows
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_Feature_Summaries
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_State_Not_Persisted
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Summarizes_Main_Context
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Shows_File_State_Markers
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Does_Not_Copy_Rows_Or_Output
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Does_Not_Duplicate_Priority_Segments
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Command_Outcome_Uses_Public_Classes
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Layout_Is_Bounded
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return Boolean;

   function Assert_Status_Layout_Preserves_Priority
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Segment_Builders_Are_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Is_Single_Line
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Config_Is_Display_Only
     (Config : Status_Bar_Config) return Boolean;

   function Assert_Status_Carries_No_Command_Payloads
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Status_Line_Context_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean;

   function Assert_Editing_Status_And_Feedback_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean;

end Editor.Status_Bar.Audits;
