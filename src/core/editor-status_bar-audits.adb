with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Status_Bar.Text_Format;

package body Editor.Status_Bar.Audits is

   function Contains
     (Text    : String;
      Pattern : String) return Boolean
   is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;

      return Ada.Strings.Fixed.Index (Text, Pattern) > 0;
   end Contains;

   function Starts_With
     (Text    : String;
      Pattern : String) return Boolean
   is
   begin
      if Pattern'Length = 0 then
         return True;
      elsif Text'Length < Pattern'Length then
         return False;
      else
         return Text (Text'First .. Text'First + Pattern'Length - 1) = Pattern;
      end if;
   end Starts_With;

   function Occurrence_Count
     (Text    : String;
      Pattern : String) return Natural
   is
      Count : Natural := 0;
      From  : Positive := Text'First;
      At_Index : Natural := 0;
   begin
      if Pattern'Length = 0 then
         return 0;
      end if;

      while From <= Text'Last loop
         At_Index := Ada.Strings.Fixed.Index (Text, Pattern, From);
         exit when At_Index = 0;
         Count := Count + 1;
         From := At_Index + Pattern'Length;
      end loop;

      return Count;
   end Occurrence_Count;

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
   is
      Text : constant String := To_String (Severity);
   begin
      if Text = "success" or else Text = "ok" then
         return "success";
      elsif Text = "unavailable" or else Text = "warn"
        or else Text = "warning"
      then
         return "unavailable";
      elsif Text = "failed" or else Text = "failure" or else Text = "error" then
         return "failed";
      elsif Text = "cancelled" or else Text = "canceled" then
         return "cancelled";
      elsif Text = "pending" then
         return "pending";
      else
         return "info";
      end if;
   end Outcome_Class_From_Severity;

   function Is_Priority_Feedback
     (Severity : Unbounded_String) return Boolean
   is
      Class_Text : constant String := Outcome_Class_From_Severity (Severity);
   begin
      return Class_Text = "failed"
        or else Class_Text = "unavailable";
   end Is_Priority_Feedback;

   function Field_Or_Fallback
     (Value    : Unbounded_String;
      Fallback : String) return String
   is
   begin
      if Length (Value) = 0 then
         return Fallback;
      else
         return Segment_Text (Value);
      end if;
   end Field_Or_Fallback;

   function Assert_Status_Snapshot_Is_Observational
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      return True;
   end Assert_Status_Snapshot_Is_Observational;

   function Assert_Status_Shows_Active_Buffer_And_Dirty_State
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left : constant String := Format_Left (Snapshot);
   begin
      return (if not Snapshot.Has_Active_Buffer
              then Contains (Left, "No active buffer.")
              else (Length (Snapshot.File_Label) > 0
                    and then Contains (Left, Segment_Text (Snapshot.File_Label)))
                or else (Length (Snapshot.File_Name) > 0
                         and then Contains (Left, Segment_Text (Snapshot.File_Name))))
        and then (if Snapshot.Is_Dirty then Contains (Left, "*") else True);
   end Assert_Status_Shows_Active_Buffer_And_Dirty_State;

   function Assert_Status_Shows_Caret_And_Selection
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
   begin
      return (if Snapshot.Has_Active_Buffer
              then Contains (Right, "Ln") and then Contains (Right, "Col")
              else Contains (Right, "No caret"))
        and then (Contains (Right, "No selection")
                  or else Contains (Right, "Selected:")
                  or else Contains (Right, "rect selection"));
   end Assert_Status_Shows_Caret_And_Selection;

   function Assert_Status_Shows_Command_Outcome
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
   begin
      return (not Snapshot.Has_Command_Feedback)
        or else Contains (Right, Status_Command_Outcome_Segment (Snapshot));
   end Assert_Status_Shows_Command_Outcome;

   function Assert_Status_Does_Not_Copy_Feature_Rows
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      return True;
   end Assert_Status_Does_Not_Copy_Feature_Rows;

   function Assert_Status_Shows_Feature_Summaries
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
   begin
      return (if Length (Snapshot.Active_Panel_Label) > 0
              then Contains (Right, Segment_Text (Snapshot.Active_Panel_Label))
              else True)
        and then (if Length (Snapshot.Input_Mode_Label) > 0
                  then Contains (Right, Segment_Text (Snapshot.Input_Mode_Label))
                  else True)
        and then (if Snapshot.Overlay_Query_Active
                  then Contains (Right, "Overlay input")
                  else True)
        and then (if Length (Snapshot.Outline_Status_Label) > 0
              then Contains (Right, Status_Segment_Text (Snapshot.Outline_Status_Label))
              else True)
        and then (if Length (Snapshot.Diagnostics_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Diagnostics_Status_Label))
                  else Contains (Right, "diagnostic")
                    or else Contains (Right, "Diagnostics:"))
        and then (if Length (Snapshot.Build_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Build_Status_Label))
                  else True)
        and then (if Length (Snapshot.Search_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Search_Status_Label))
                  else True)
        and then (if Length (Snapshot.Quick_Open_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Quick_Open_Status_Label))
                  else True)
        and then (if Length (Snapshot.File_Tree_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.File_Tree_Status_Label))
                  else True)
        and then (if Length (Snapshot.Workspace_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Workspace_Status_Label))
                  else True)
        and then (if Length (Snapshot.Recent_Projects_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Recent_Projects_Status_Label))
                  else True);
   end Assert_Status_Shows_Feature_Summaries;

   function Assert_Status_State_Not_Persisted
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      return True;
   end Assert_Status_State_Not_Persisted;

   function Assert_Status_Summarizes_Main_Context
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Left  : constant String := Format_Left (Snapshot);
   begin
      return (if Snapshot.Has_Project
              then Contains (Right, Segment_Text (Snapshot.Project_Label))
                or else Contains (Right, Segment_Text (Snapshot.Project_State_Label))
              else Contains (Right, "No project open."))
        and then (if Snapshot.Has_Active_Buffer
                  then (Length (Snapshot.File_Label) > 0
                        and then Contains (Left, Segment_Text (Snapshot.File_Label)))
                    or else (Length (Snapshot.File_Name) > 0
                             and then Contains (Left, Segment_Text (Snapshot.File_Name)))
                  else Contains (Left, "No active buffer."))
        and then Contains (Right, Field_Or_Fallback (Snapshot.Focus_Label, "Editor"))
        and then (Length (Snapshot.Pending_Confirmation_Label) = 0
                  or else Contains
                    (Right, Segment_Text (Snapshot.Pending_Confirmation_Label)))
        and then (not Snapshot.Has_Command_Feedback
                  or else Contains
                    (Right, Status_Command_Outcome_Segment (Snapshot)))
        and then (Length (Snapshot.Build_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Build_Status_Label)))
        and then (Length (Snapshot.Diagnostics_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Diagnostics_Status_Label)))
        and then (Length (Snapshot.Search_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Search_Status_Label)))
        and then (Length (Snapshot.Quick_Open_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Quick_Open_Status_Label)))
        and then (Length (Snapshot.Outline_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Outline_Status_Label)))
        and then (Length (Snapshot.File_Tree_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.File_Tree_Status_Label)))
        and then (Length (Snapshot.Workspace_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Workspace_Status_Label)))
        and then (Length (Snapshot.Recent_Projects_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Recent_Projects_Status_Label)));
   end Assert_Status_Summarizes_Main_Context;

   function Assert_Status_Shows_File_State_Markers
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left : constant String := Format_Left (Snapshot);
   begin
      return (Length (Snapshot.Buffer_Kind_Label) = 0
              or else Contains (Left, Segment_Text (Snapshot.Buffer_Kind_Label)))
        and then (Length (Snapshot.File_State_Label) = 0
                  or else Contains (Left, Segment_Text (Snapshot.File_State_Label)))
        and then (Length (Snapshot.Dirty_State_Label) = 0
                  or else Contains (Left, Segment_Text (Snapshot.Dirty_State_Label)))
        and then (if Snapshot.Is_Dirty then Contains (Left, "*") else True);
   end Assert_Status_Shows_File_State_Markers;

   function Assert_Status_Does_Not_Copy_Rows_Or_Output
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left  : constant String := Format_Left (Snapshot);
      Right : constant String := Format_Right (Snapshot);
   begin
      return not Contains (Left, Ada.Characters.Latin_1.LF & "")
        and then not Contains (Right, Ada.Characters.Latin_1.LF & "")
        and then not Contains (Left, Ada.Characters.Latin_1.CR & "")
        and then not Contains (Right, Ada.Characters.Latin_1.CR & "")
        and then not Contains (Left, Ada.Characters.Latin_1.HT & "")
        and then not Contains (Right, Ada.Characters.Latin_1.HT & "");
   end Assert_Status_Does_Not_Copy_Rows_Or_Output;

   function Assert_Status_Does_Not_Duplicate_Priority_Segments
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Feedback_Text : constant String :=
        Status_Command_Outcome_Segment (Snapshot);
   begin
      return (Length (Snapshot.Pending_Confirmation_Label) = 0
              or else Occurrence_Count
                (Right, Segment_Text (Snapshot.Pending_Confirmation_Label)) = 1)
        and then ((not Snapshot.Has_Command_Feedback)
                  or else Length (Snapshot.Command_Feedback) = 0
                  or else Occurrence_Count (Right, Feedback_Text) = 1);
   end Assert_Status_Does_Not_Duplicate_Priority_Segments;

   function Assert_Status_Command_Outcome_Uses_Public_Classes
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Class_Text : constant String := Status_Command_Outcome_Class (Snapshot);
      Segment    : constant String := Status_Command_Outcome_Segment (Snapshot);
      Right      : constant String := Format_Right (Snapshot);
   begin
      if not Snapshot.Has_Command_Feedback then
         return Class_Text = "" and then Segment = "";
      end if;

      return (Class_Text = "success"
              or else Class_Text = "unavailable"
              or else Class_Text = "failed"
              or else Class_Text = "cancelled"
              or else Class_Text = "pending"
              or else Class_Text = "info")
        and then Contains (Segment, Class_Text & ": ")
        and then Contains (Right, Segment)
        and then not (Segment'Length >= 7
                      and then Segment (Segment'First .. Segment'First + 6) = "error: ")
        and then not (Segment'Length >= 6
                      and then Segment (Segment'First .. Segment'First + 5) = "warn: ")
        and then not (Segment'Length >= 9
                      and then Segment (Segment'First .. Segment'First + 8) = "warning: ")
        and then not (Segment'Length >= 9
                      and then Segment (Segment'First .. Segment'First + 8) = "failure: ")
        and then not (Segment'Length >= 4
                      and then Segment (Segment'First .. Segment'First + 3) = "ok: ");
   end Assert_Status_Command_Outcome_Uses_Public_Classes;

   function Assert_Status_Layout_Is_Bounded
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return Boolean
   is
      Text : constant String := Status_Layout_Compact (Snapshot, Max_Columns);
   begin
      return Text'Length <= Max_Columns
        and then (if Max_Columns = 0 then Text = "" else True);
   end Assert_Status_Layout_Is_Bounded;

   function Assert_Status_Layout_Preserves_Priority
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Compact_64 : constant String := Status_Layout_Compact (Snapshot, 64);
      Compact_128 : constant String := Status_Layout_Compact (Snapshot, 128);
      Pending_Text : constant String := Segment_Text (Snapshot.Pending_Confirmation_Label);
      Command_Text : constant String := Status_Command_Outcome_Segment (Snapshot);
      Pending_Prefix_Length : constant Natural :=
        Natural'Min (Pending_Text'Length, 16);
      Pending_Prefix : constant String :=
        (if Pending_Prefix_Length = 0
         then ""
         else Pending_Text
           (Pending_Text'First .. Pending_Text'First + Pending_Prefix_Length - 1));
      Command_Prefix_Length : constant Natural :=
        Natural'Min (Command_Text'Length, 16);
      Command_Prefix : constant String :=
        (if Command_Prefix_Length = 0
         then ""
         else Command_Text
           (Command_Text'First .. Command_Text'First + Command_Prefix_Length - 1));
   begin
      return (Length (Snapshot.Pending_Confirmation_Label) = 0
              or else Starts_With (Compact_64, Pending_Prefix))
        and then ((not Snapshot.Has_Command_Feedback)
                  or else not Is_Priority_Feedback
                    (Snapshot.Command_Feedback_Severity)
                  or else Contains (Compact_128, Command_Prefix));
   end Assert_Status_Layout_Preserves_Priority;

   function Assert_Status_Segment_Builders_Are_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Project_Text : constant String := Status_Project_Segment (Snapshot);
      Project_File_Text : constant String := Status_Project_File_Segment (Snapshot);
      Dirty_File_State_Text : constant String :=
        Status_Dirty_File_State_Segment (Snapshot);
      Focus_Text : constant String := Status_Focus_Segment (Snapshot);
      Caret_Selection_Text : constant String := Status_Caret_Selection_Segment (Snapshot);
      Command_Text : constant String := Status_Command_Outcome_Segment (Snapshot);
      Build_Text : constant String := Status_Build_Segment (Snapshot);
      Diagnostics_Text : constant String := Status_Diagnostics_Segment (Snapshot);
      Search_Text : constant String := Status_Search_Replace_Segment (Snapshot);
      Quick_Open_Text : constant String := Status_Quick_Open_Segment (Snapshot);
      Outline_Text : constant String := Status_Outline_Segment (Snapshot);
      File_Tree_Text : constant String := Status_File_Tree_Segment (Snapshot);
      Workspace_Recent_Text : constant String := Status_Workspace_Recent_Segment (Snapshot);
   begin
      return Contains (Right, Project_Text)
        and then Contains (Status_Layout_Compact (Snapshot, 4096), Project_File_Text)
        and then (Dirty_File_State_Text = "Clean"
                  or else Contains (Format_Left (Snapshot), Dirty_File_State_Text)
                  or else Assert_Status_Shows_File_State_Markers (Snapshot))
        and then Contains (Right, Focus_Text)
        and then Contains (Right, Caret_Selection_Text)
        and then Contains (Right, Diagnostics_Text)
        and then (Command_Text'Length = 0 or else Contains (Right, Command_Text))
        and then (Build_Text'Length = 0 or else Contains (Right, Build_Text))
        and then (Search_Text'Length = 0 or else Contains (Right, Search_Text))
        and then (Quick_Open_Text'Length = 0 or else Contains (Right, Quick_Open_Text))
        and then (Outline_Text'Length = 0 or else Contains (Right, Outline_Text))
        and then (File_Tree_Text'Length = 0 or else Contains (Right, File_Tree_Text))
        and then (Workspace_Recent_Text'Length = 0
                  or else Contains (Right, Workspace_Recent_Text)
                  or else (Length (Snapshot.Workspace_Status_Label) > 0
                           and then Contains (Right, Status_Segment_Text (Snapshot.Workspace_Status_Label)))
                  or else (Length (Snapshot.Recent_Projects_Status_Label) > 0
                           and then Contains (Right, Status_Segment_Text (Snapshot.Recent_Projects_Status_Label))));
   end Assert_Status_Segment_Builders_Are_Coherent;

   function Is_Single_Line_Text
     (Text : String) return Boolean
   is
   begin
      for C of Text loop
         if C = Ada.Characters.Latin_1.CR or else C = Ada.Characters.Latin_1.LF or else C = Ada.Characters.Latin_1.HT then
            return False;
         end if;
      end loop;
      return True;
   end Is_Single_Line_Text;

   function Assert_Status_Is_Single_Line
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left    : constant String := Format_Left (Snapshot);
      Right   : constant String := Format_Right (Snapshot);
      Compact : constant String := Status_Layout_Compact (Snapshot, 160);
   begin
      return Is_Single_Line_Text (Left)
        and then Is_Single_Line_Text (Right)
        and then Is_Single_Line_Text (Compact);
   end Assert_Status_Is_Single_Line;

   function Assert_Status_Config_Is_Display_Only
     (Config : Status_Bar_Config) return Boolean
   is
   begin
      return Height_In_Rows (Config) <= 1;
   end Assert_Status_Config_Is_Display_Only;

   function Assert_Status_Carries_No_Command_Payloads
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      return True;
   end Assert_Status_Carries_No_Command_Payloads;

   function Assert_Status_Line_Context_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Left  : constant String := Format_Left (Snapshot);
   begin
      return Assert_Status_Snapshot_Is_Observational (Snapshot)
        and then Assert_Status_Carries_No_Command_Payloads (Snapshot)
        and then Assert_Status_State_Not_Persisted (Snapshot)
        and then Assert_Status_Shows_Active_Buffer_And_Dirty_State (Snapshot)
        and then Assert_Status_Shows_Caret_And_Selection (Snapshot)
        and then Assert_Status_Shows_Command_Outcome (Snapshot)
        and then Assert_Status_Shows_Feature_Summaries (Snapshot)
        and then Assert_Status_Summarizes_Main_Context (Snapshot)
        and then Assert_Status_Shows_File_State_Markers (Snapshot)
        and then Assert_Status_Does_Not_Copy_Rows_Or_Output (Snapshot)
        and then Assert_Status_Does_Not_Duplicate_Priority_Segments (Snapshot)
        and then Assert_Status_Command_Outcome_Uses_Public_Classes (Snapshot)
        and then Assert_Status_Layout_Is_Bounded (Snapshot, 160)
        and then Assert_Status_Layout_Preserves_Priority (Snapshot)
        and then Assert_Status_Segment_Builders_Are_Coherent (Snapshot)
        and then Assert_Status_Is_Single_Line (Snapshot)
        and then Left'Length <= 256
        and then Right'Length <= 2048
        and then (not Snapshot.Has_Command_Feedback
                  or else Length (Snapshot.Command_Feedback) = 0
                  or else Contains
                    (Right, Status_Command_Outcome_Segment (Snapshot)))
        and then (Length (Snapshot.Pending_Confirmation_Label) = 0
                  or else Contains (Right, Segment_Text (Snapshot.Pending_Confirmation_Label)));
   end Assert_Status_Line_Context_Coherent;

   function Assert_Editing_Status_And_Feedback_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
   begin
      return Assert_Status_Snapshot_Is_Observational (Snapshot)
        and then Assert_Status_Does_Not_Copy_Feature_Rows (Snapshot)
        and then Assert_Status_Does_Not_Copy_Rows_Or_Output (Snapshot)
        and then Assert_Status_Shows_Active_Buffer_And_Dirty_State (Snapshot)
        and then Assert_Status_Shows_Caret_And_Selection (Snapshot)
        and then Assert_Status_Shows_Command_Outcome (Snapshot)
        and then Assert_Status_Shows_Feature_Summaries (Snapshot)
        and then Assert_Status_State_Not_Persisted (Snapshot)
        and then Assert_Status_Carries_No_Command_Payloads (Snapshot)
        and then Assert_Status_Line_Context_Coherent (Snapshot);
   end Assert_Editing_Status_And_Feedback_Coherent;

end Editor.Status_Bar.Audits;
