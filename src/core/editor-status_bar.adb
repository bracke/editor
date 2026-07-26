with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Workflow_Messages;
with Editor.Status_Bar.Audits;
with Editor.Status_Bar.Surfaces;
with Editor.Status_Bar.Text_Format;

package body Editor.Status_Bar is

   function Enabled
     (Config : Status_Bar_Config) return Boolean
     renames Editor.Status_Bar.Text_Format.Enabled;

   function Height_In_Rows
     (Config : Status_Bar_Config) return Natural
     renames Editor.Status_Bar.Text_Format.Height_In_Rows;

   function Plural
     (Count    : Natural;
      Singular : String;
      Plural_Text  : String) return String
     renames Editor.Status_Bar.Text_Format.Plural;

   function Status_Truncate_Label
     (Text        : String;
      Max_Columns : Natural := 64) return String
     renames Editor.Status_Bar.Text_Format.Status_Truncate_Label;

   function Segment_Text
     (Value : Unbounded_String) return String
     renames Editor.Status_Bar.Text_Format.Segment_Text;


   function Status_Segment_Text
     (Value : Unbounded_String) return String
     renames Editor.Status_Bar.Text_Format.Status_Segment_Text;

   function Outcome_Class_From_Severity
     (Severity : Unbounded_String) return String
     renames Editor.Status_Bar.Text_Format.Outcome_Class_From_Severity;

   function Is_Priority_Feedback
     (Severity : Unbounded_String) return Boolean
     renames Editor.Status_Bar.Text_Format.Is_Priority_Feedback;

   function Format_Left
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Text_Format.Format_Left;

   function Field_Or_Fallback
     (Value    : Unbounded_String;
      Fallback : String) return String
     renames Editor.Status_Bar.Text_Format.Field_Or_Fallback;





   function Status_Project_File_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Project_File_Segment;

   function Status_Dirty_File_State_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Dirty_File_State_Segment;

   function Status_Project_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Project_Segment;

   function Status_Focus_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Focus_Segment;

   function Status_Caret_Selection_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Caret_Selection_Segment;

   function Status_Command_Outcome_Class
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Command_Outcome_Class;

   function Status_Command_Outcome_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Command_Outcome_Segment;

   function Status_Build_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Build_Segment;

   function Status_Diagnostics_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Diagnostics_Segment;

   function Status_Search_Replace_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Search_Replace_Segment;

   function Status_Quick_Open_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Quick_Open_Segment;

   function Status_Outline_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Outline_Segment;

   function Status_File_Tree_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_File_Tree_Segment;

   function Status_Workspace_Recent_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Workspace_Recent_Segment;

   function Status_Startup_Segment
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Status_Startup_Segment;

   function Workspace_Surface_Action_Label
     (Surface : Workspace_Status_Surface) return String
     renames Editor.Status_Bar.Surfaces.Workspace_Surface_Action_Label;

   function Workspace_Surface_Action_Count
     (Surface : Workspace_Status_Surface) return Natural
     renames Editor.Status_Bar.Surfaces.Workspace_Surface_Action_Count;

   function Quick_Open_Context_Action_Label
     (Surface : Quick_Open_Context_Surface) return String
     renames Editor.Status_Bar.Surfaces.Quick_Open_Context_Action_Label;

   function Quick_Open_Context_Action_Count
     (Surface : Quick_Open_Context_Surface) return Natural
     renames Editor.Status_Bar.Surfaces.Quick_Open_Context_Action_Count;

   function Outline_Surface_Action_Label
     (Surface : Outline_Status_Surface) return String
     renames Editor.Status_Bar.Surfaces.Outline_Surface_Action_Label;

   function Outline_Surface_Action_Count
     (Surface : Outline_Status_Surface) return Natural
     renames Editor.Status_Bar.Surfaces.Outline_Surface_Action_Count;

   function Search_Replace_Surface_Action_Label
     (Surface : Search_Replace_Status_Surface) return String
     renames Editor.Status_Bar.Surfaces.Search_Replace_Surface_Action_Label;

   function Search_Replace_Surface_Action_Count
     (Surface : Search_Replace_Status_Surface) return Natural
     renames Editor.Status_Bar.Surfaces.Search_Replace_Surface_Action_Count;

   function File_Tree_Surface_Action_Label
     (Surface : File_Tree_Status_Surface) return String
     renames Editor.Status_Bar.Surfaces.File_Tree_Surface_Action_Label;

   function File_Tree_Surface_Action_Count
     (Surface : File_Tree_Status_Surface) return Natural
     renames Editor.Status_Bar.Surfaces.File_Tree_Surface_Action_Count;

   function Recent_Projects_Surface_Action_Label
     (Surface : Recent_Projects_Status_Surface) return String
     renames Editor.Status_Bar.Surfaces.Recent_Projects_Surface_Action_Label;

   function Recent_Projects_Surface_Action_Count
     (Surface : Recent_Projects_Status_Surface) return Natural
     renames Editor.Status_Bar.Surfaces.Recent_Projects_Surface_Action_Count;

   function Workspace_Surface
     (Snapshot : Status_Bar_Snapshot) return Workspace_Status_Surface
     renames Editor.Status_Bar.Surfaces.Workspace_Surface;

   function Quick_Open_Context_Surface_For
     (Snapshot : Status_Bar_Snapshot) return Quick_Open_Context_Surface
     renames Editor.Status_Bar.Surfaces.Quick_Open_Context_Surface_For;

   function Outline_Surface
     (Snapshot : Status_Bar_Snapshot) return Outline_Status_Surface
     renames Editor.Status_Bar.Surfaces.Outline_Surface;

   function Search_Replace_Surface
     (Snapshot : Status_Bar_Snapshot) return Search_Replace_Status_Surface
     renames Editor.Status_Bar.Surfaces.Search_Replace_Surface;

   function File_Tree_Surface
     (Snapshot : Status_Bar_Snapshot) return File_Tree_Status_Surface
     renames Editor.Status_Bar.Surfaces.File_Tree_Surface;

   function Recent_Projects_Surface
     (Snapshot : Status_Bar_Snapshot) return Recent_Projects_Status_Surface
     renames Editor.Status_Bar.Surfaces.Recent_Projects_Surface;

   function Status_Message_Kind_For
     (Label : Unbounded_String) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Message_Kind_For;

   function Status_Build_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Build_Message_Kind;

   function Status_Diagnostics_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Diagnostics_Message_Kind;

   function Status_Search_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Search_Message_Kind;

   function Status_Quick_Open_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Quick_Open_Message_Kind;

   function Status_File_Tree_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_File_Tree_Message_Kind;

   function Status_Workspace_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Workspace_Message_Kind;

   function Status_Outline_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Outline_Message_Kind;

   function Status_Recent_Projects_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
     renames Editor.Status_Bar.Text_Format.Status_Recent_Projects_Message_Kind;

   function Format_Right
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Surfaces.Format_Right;

   function Status_Layout_Should_Use_Compact
     (Snapshot          : Status_Bar_Snapshot;
      Available_Columns : Natural) return Boolean
     renames Editor.Status_Bar.Surfaces.Status_Layout_Should_Use_Compact;

   function Status_Layout_Compact
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return String
     renames Editor.Status_Bar.Surfaces.Status_Layout_Compact;


   function Assert_Status_Snapshot_Is_Observational
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Snapshot_Is_Observational;

   function Assert_Status_Shows_Active_Buffer_And_Dirty_State
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Shows_Active_Buffer_And_Dirty_State;

   function Assert_Status_Shows_Caret_And_Selection
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Shows_Caret_And_Selection;

   function Assert_Status_Shows_Command_Outcome
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Shows_Command_Outcome;

   function Assert_Status_Does_Not_Copy_Feature_Rows
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Does_Not_Copy_Feature_Rows;

   function Assert_Status_Shows_Feature_Summaries
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Shows_Feature_Summaries;

   function Assert_Status_State_Not_Persisted
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_State_Not_Persisted;

   function Assert_Status_Summarizes_Main_Context
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Summarizes_Main_Context;

   function Assert_Status_Shows_File_State_Markers
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Shows_File_State_Markers;

   function Assert_Status_Does_Not_Copy_Rows_Or_Output
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Does_Not_Copy_Rows_Or_Output;

   function Assert_Status_Does_Not_Duplicate_Priority_Segments
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Does_Not_Duplicate_Priority_Segments;

   function Assert_Status_Command_Outcome_Uses_Public_Classes
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Command_Outcome_Uses_Public_Classes;

   function Assert_Status_Layout_Is_Bounded
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Layout_Is_Bounded;

   function Assert_Status_Layout_Preserves_Priority
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Layout_Preserves_Priority;

   function Assert_Status_Segment_Builders_Are_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Segment_Builders_Are_Coherent;

   function Assert_Status_Is_Single_Line
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Is_Single_Line;

   function Assert_Status_Config_Is_Display_Only
     (Config : Status_Bar_Config) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Config_Is_Display_Only;

   function Assert_Status_Carries_No_Command_Payloads
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Carries_No_Command_Payloads;

   function Assert_Status_Line_Context_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Status_Line_Context_Coherent;

   function Assert_Editing_Status_And_Feedback_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
       renames Editor.Status_Bar.Audits.Assert_Editing_Status_And_Feedback_Coherent;

end Editor.Status_Bar;
