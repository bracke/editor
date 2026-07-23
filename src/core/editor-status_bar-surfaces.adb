with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Status_Bar.Text_Format;

package body Editor.Status_Bar.Surfaces is

   function Plural
     (Count       : Natural;
      Singular    : String;
      Plural_Text : String) return String
     renames Editor.Status_Bar.Text_Format.Plural;

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

   function Field_Or_Fallback
     (Value    : Unbounded_String;
      Fallback : String) return String
     renames Editor.Status_Bar.Text_Format.Field_Or_Fallback;

   function Format_Left
     (Snapshot : Status_Bar_Snapshot) return String
     renames Editor.Status_Bar.Text_Format.Format_Left;

   function Workspace_Surface_Action_Label
     (Surface : Workspace_Status_Surface) return String
   is
   begin
      if Length (Surface.Summary_Label) = 0 then
         return "";
      end if;

      return " ["
        & To_String (Surface.Save_State_Command) & ", "
        & To_String (Surface.Restore_State_Command) & ", "
        & To_String (Surface.Clear_State_Command) & "]";
   end Workspace_Surface_Action_Label;

   function Workspace_Surface_Action_Count
     (Surface : Workspace_Status_Surface) return Natural
   is
   begin
      if Length (Surface.Summary_Label) = 0 then
         return 0;
      end if;
      return 3;
   end Workspace_Surface_Action_Count;

   function Quick_Open_Context_Action_Label
     (Surface : Quick_Open_Context_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Open_Command) & ", "
        & To_String (Surface.Clear_Scope_Command) & ", "
        & To_String (Surface.Clear_Filter_Command) & "]";
   end Quick_Open_Context_Action_Label;

   function Quick_Open_Context_Action_Count
     (Surface : Quick_Open_Context_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Quick_Open_Context_Action_Count;

   function Outline_Surface_Action_Label
     (Surface : Outline_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Refresh_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Reveal_Current_Command) & "]";
   end Outline_Surface_Action_Label;

   function Outline_Surface_Action_Count
     (Surface : Outline_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Outline_Surface_Action_Count;

   function Search_Replace_Surface_Action_Label
     (Surface : Search_Replace_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Run_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Clear_Query_Command) & "]";
   end Search_Replace_Surface_Action_Label;

   function Search_Replace_Surface_Action_Count
     (Surface : Search_Replace_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Search_Replace_Surface_Action_Count;

   function File_Tree_Surface_Action_Label
     (Surface : File_Tree_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Refresh_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Reveal_Active_Command) & "]";
   end File_Tree_Surface_Action_Label;

   function File_Tree_Surface_Action_Count
     (Surface : File_Tree_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end File_Tree_Surface_Action_Count;

   function Recent_Projects_Surface_Action_Label
     (Surface : Recent_Projects_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Show_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Remove_Missing_Command) & "]";
   end Recent_Projects_Surface_Action_Label;

   function Recent_Projects_Surface_Action_Count
     (Surface : Recent_Projects_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Recent_Projects_Surface_Action_Count;

   function Workspace_Surface
     (Snapshot : Status_Bar_Snapshot) return Workspace_Status_Surface
   is
      Summary : constant String := Editor.Status_Bar.Text_Format.Status_Segment_Text
        (Snapshot.Workspace_Status_Label);
      Result  : Workspace_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      if Summary'Length > 0 then
         Result.Has_Restore_Details := True;
         Result.Restore_Details_Label := To_Unbounded_String (Summary);
      end if;
      return Result;
   end Workspace_Surface;

   function Quick_Open_Context_Surface_For
     (Snapshot : Status_Bar_Snapshot) return Quick_Open_Context_Surface
   is
      Summary : constant String := Editor.Status_Bar.Text_Format.Status_Segment_Text
        (Snapshot.Quick_Open_Status_Label);
      Result  : Quick_Open_Context_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Quick_Open_Context_Surface_For;

   function Outline_Surface
     (Snapshot : Status_Bar_Snapshot) return Outline_Status_Surface
   is
      Summary : constant String := Editor.Status_Bar.Text_Format.Status_Segment_Text
        (Snapshot.Outline_Status_Label);
      Result  : Outline_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Outline_Surface;

   function Search_Replace_Surface
     (Snapshot : Status_Bar_Snapshot) return Search_Replace_Status_Surface
   is
      Summary : constant String := Editor.Status_Bar.Text_Format.Status_Segment_Text
        (Snapshot.Search_Status_Label);
      Result  : Search_Replace_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Search_Replace_Surface;

   function File_Tree_Surface
     (Snapshot : Status_Bar_Snapshot) return File_Tree_Status_Surface
   is
      Summary : constant String := Editor.Status_Bar.Text_Format.Status_Segment_Text
        (Snapshot.File_Tree_Status_Label);
      Result  : File_Tree_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end File_Tree_Surface;

   function Recent_Projects_Surface
     (Snapshot : Status_Bar_Snapshot) return Recent_Projects_Status_Surface
   is
      Summary : constant String := Editor.Status_Bar.Text_Format.Status_Segment_Text
        (Snapshot.Recent_Projects_Status_Label);
      Result  : Recent_Projects_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Recent_Projects_Surface;

   function Status_Project_File_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Project_Text : constant String := Status_Project_Segment (Snapshot);
      File_Text    : constant String := Format_Left (Snapshot);
   begin
      if File_Text'Length = 0 then
         return Project_Text;
      else
         return Project_Text & " | " & File_Text;
      end if;
   end Status_Project_File_Segment;

   function Status_Dirty_File_State_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Kind_Text : constant String := Segment_Text (Snapshot.Buffer_Kind_Label);
      State_Text : constant String := Status_Segment_Text (Snapshot.File_State_Label);
      Dirty_Text : constant String :=
        (if Length (Snapshot.Dirty_State_Label) > 0
         then Status_Segment_Text (Snapshot.Dirty_State_Label)
         elsif Snapshot.Is_Dirty
         then "Modified"
         else "");
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Append_Part (Part : String) is
      begin
         if Part'Length = 0 then
            return;
         elsif Length (Result) = 0 then
            Result := To_Unbounded_String (Part);
         else
            Append (Result, " | " & Part);
         end if;
      end Append_Part;
   begin
      if not Snapshot.Has_Active_Buffer then
         return "No active buffer.";
      end if;

      Append_Part (Kind_Text);
      Append_Part (State_Text);
      Append_Part (Dirty_Text);

      if Length (Result) = 0 then
         return (if Snapshot.Has_Active_Buffer then "Clean" else "No active buffer.");
      else
         return To_String (Result);
      end if;
   end Status_Dirty_File_State_Segment;

   function Status_Project_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      if Length (Snapshot.Project_State_Label) > 0 then
         return Segment_Text (Snapshot.Project_State_Label);
      elsif Snapshot.Has_Project then
         return "Project: " & Field_Or_Fallback (Snapshot.Project_Label, "?");
      else
         return "No project open.";
      end if;
   end Status_Project_Segment;

   function Status_Focus_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Focus_Text : constant String := Field_Or_Fallback (Snapshot.Focus_Label, "Editor");
      Panel_Text : constant String :=
        (if Length (Snapshot.Active_Panel_Label) = 0
         then ""
         else " | Panel: " & Segment_Text (Snapshot.Active_Panel_Label));
      Input_Mode_Text : constant String :=
        (if Length (Snapshot.Input_Mode_Label) = 0
         then ""
         else " | Mode: " & Segment_Text (Snapshot.Input_Mode_Label));
      Overlay_Text : constant String :=
        (if Snapshot.Overlay_Query_Active then " | Overlay input" else "");
      Feature_Text : constant String :=
        (if Length (Snapshot.Active_Feature_Label) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Active_Feature_Label));
   begin
      return "Focus: " & Focus_Text
        & Panel_Text
        & Input_Mode_Text
        & Overlay_Text
        & Feature_Text;
   end Status_Focus_Segment;

   function Status_Caret_Selection_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Row_Display : constant Natural := Snapshot.Cursor_Row + 1;
      Col_Display : constant Natural := Snapshot.Cursor_Column + 1;
      Caret_Text : constant String :=
        (if Snapshot.Has_Active_Buffer
         then "Ln" & Natural'Image (Row_Display)
           & ", Col" & Natural'Image (Col_Display)
           & " |" & Natural'Image (Snapshot.Caret_Count)
           & " " & Plural (Snapshot.Caret_Count, "caret", "carets")
         else "No caret");
      Selection_Text : constant String :=
        (if Snapshot.Rectangular_Selection_Active
         then "rect selection"
         elsif Snapshot.Selected_Character_Count > 0
         then "Selected:" & Natural'Image (Snapshot.Selected_Character_Count)
           & " " & Plural (Snapshot.Selected_Character_Count, "char", "chars")
           & "," & Natural'Image (Natural'Max (1, Snapshot.Selected_Line_Count))
           & " " & Plural (Natural'Max (1, Snapshot.Selected_Line_Count), "line", "lines")
         elsif Snapshot.Selection_Count = 0
         then "No selection"
         else "Selected:" & Natural'Image (Snapshot.Selection_Count)
           & " " & Plural (Snapshot.Selection_Count, "range", "ranges"));
   begin
      return Caret_Text & " | " & Selection_Text;
   end Status_Caret_Selection_Segment;

   function Status_Command_Outcome_Class
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      if Snapshot.Has_Command_Feedback then
         return Outcome_Class_From_Severity (Snapshot.Command_Feedback_Severity);
      else
         return "";
      end if;
   end Status_Command_Outcome_Class;

   function Status_Command_Outcome_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Class_Text : constant String := Status_Command_Outcome_Class (Snapshot);
   begin
      if Snapshot.Has_Command_Feedback then
         return Class_Text & ": "
           & Field_Or_Fallback (Snapshot.Command_Feedback, "");
      else
         return "";
      end if;
   end Status_Command_Outcome_Segment;

   function Status_Build_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Build_Status_Label);
   end Status_Build_Segment;

   function Status_Diagnostics_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      if Length (Snapshot.Diagnostics_Status_Label) > 0 then
         return Status_Segment_Text (Snapshot.Diagnostics_Status_Label);
      elsif Snapshot.Diagnostic_Count = 0 then
         return "No diagnostics.";
      else
         return "Diagnostics:" & Natural'Image (Snapshot.Diagnostic_Count) & " total";
      end if;
   end Status_Diagnostics_Segment;

   function Status_Search_Replace_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Search_Status_Label)
        & Search_Replace_Surface_Action_Label
            (Search_Replace_Surface (Snapshot));
   end Status_Search_Replace_Segment;

   function Status_Quick_Open_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Surface : constant Quick_Open_Context_Surface :=
        Quick_Open_Context_Surface_For (Snapshot);
   begin
      return Status_Segment_Text (Snapshot.Quick_Open_Status_Label)
        & Quick_Open_Context_Action_Label (Surface);
   end Status_Quick_Open_Segment;

   function Status_Outline_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Outline_Status_Label)
        & Outline_Surface_Action_Label (Outline_Surface (Snapshot));
   end Status_Outline_Segment;

   function Status_File_Tree_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.File_Tree_Status_Label)
        & File_Tree_Surface_Action_Label (File_Tree_Surface (Snapshot));
   end Status_File_Tree_Segment;

   function Status_Workspace_Recent_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Workspace_Text : constant String := Status_Segment_Text (Snapshot.Workspace_Status_Label);
      Recent_Text    : constant String := Status_Segment_Text (Snapshot.Recent_Projects_Status_Label);
      Workspace_Actions : constant String :=
        Workspace_Surface_Action_Label (Workspace_Surface (Snapshot));
      Recent_Actions : constant String :=
        Recent_Projects_Surface_Action_Label (Recent_Projects_Surface (Snapshot));
   begin
      if Workspace_Text'Length > 0 and then Recent_Text'Length > 0 then
         return Workspace_Text & Workspace_Actions & " | "
           & Recent_Text & Recent_Actions;
      elsif Workspace_Text'Length > 0 then
         return Workspace_Text & Workspace_Actions;
      else
         return Recent_Text & Recent_Actions;
      end if;
   end Status_Workspace_Recent_Segment;

   function Status_Startup_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Startup_Status_Label);
   end Status_Startup_Segment;

   function Format_Right
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Row_Display : constant Natural := Snapshot.Cursor_Row + 1;
      Col_Display : constant Natural := Snapshot.Cursor_Column + 1;
      Caret_Text : constant String :=
        (if Snapshot.Has_Active_Buffer
         then "Ln" & Natural'Image (Row_Display)
           & ", Col" & Natural'Image (Col_Display)
           & " |" & Natural'Image (Snapshot.Caret_Count)
           & " " & Plural (Snapshot.Caret_Count, "caret", "carets")
         else "No caret");
      Project_Text : constant String :=
        (if Length (Snapshot.Project_State_Label) > 0
         then Segment_Text (Snapshot.Project_State_Label)
         elsif Snapshot.Has_Project
         then "Project: " & Field_Or_Fallback (Snapshot.Project_Label, "?")
         else "No project open.");
      Focus_Text : constant String := Status_Focus_Segment (Snapshot);
      Hint_Text : constant String :=
        (if Length (Snapshot.Focus_Hint) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Focus_Hint));
      Lifecycle_Text : constant String :=
        (if Length (Snapshot.Lifecycle_Hint) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Lifecycle_Hint));
      Pending_Text : constant String :=
        "";
      Undo_Redo_Text : constant String :=
        (if Length (Snapshot.Undo_Redo_Label) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Undo_Redo_Label));
      Outline_Text : constant String :=
        (if Length (Snapshot.Outline_Status_Label) = 0
         then ""
         else " | " & Status_Outline_Segment (Snapshot));
      Diagnostics_Text : constant String :=
        " | " & Status_Diagnostics_Segment (Snapshot);
      Build_Text : constant String :=
        (if Length (Snapshot.Build_Status_Label) = 0
         then ""
         else " | " & Status_Segment_Text (Snapshot.Build_Status_Label));
      Search_Text : constant String :=
        (if Length (Snapshot.Search_Status_Label) = 0
         then ""
         else " | " & Status_Search_Replace_Segment (Snapshot));
      Quick_Open_Text : constant String :=
        (if Length (Snapshot.Quick_Open_Status_Label) = 0
         then ""
         else " | " & Status_Quick_Open_Segment (Snapshot));
      File_Tree_Text : constant String :=
        (if Length (Snapshot.File_Tree_Status_Label) = 0
         then ""
         else " | " & Status_File_Tree_Segment (Snapshot));
      Workspace_Text : constant String :=
        (if Length (Snapshot.Workspace_Status_Label) = 0
           and then Length (Snapshot.Recent_Projects_Status_Label) = 0
         then ""
         else " | " & Status_Workspace_Recent_Segment (Snapshot));
      Recent_Projects_Text : constant String :=
        "";
      Startup_Text : constant String :=
        (if Length (Snapshot.Startup_Status_Label) = 0
         then ""
         else " | " & Status_Segment_Text (Snapshot.Startup_Status_Label));
      Priority_Pending_Text : constant String :=
        (if Length (Snapshot.Pending_Confirmation_Label) = 0
         then ""
         else Segment_Text (Snapshot.Pending_Confirmation_Label) & " | ");
      Priority_Feedback_Text : constant String :=
        (if Snapshot.Has_Command_Feedback
           and then Is_Priority_Feedback (Snapshot.Command_Feedback_Severity)
         then Status_Command_Outcome_Segment (Snapshot) & " | "
         else "");
      Selection_Text : constant String :=
        (if Snapshot.Rectangular_Selection_Active
         then "rect selection"
         elsif Snapshot.Selected_Character_Count > 0
         then "Selected:" & Natural'Image (Snapshot.Selected_Character_Count)
           & " " & Plural (Snapshot.Selected_Character_Count, "char", "chars")
           & "," & Natural'Image (Natural'Max (1, Snapshot.Selected_Line_Count))
           & " " & Plural (Natural'Max (1, Snapshot.Selected_Line_Count), "line", "lines")
         elsif Snapshot.Selection_Count = 0
         then "No selection"
         else "Selected:" & Natural'Image (Snapshot.Selection_Count)
           & " " & Plural (Snapshot.Selection_Count, "range", "ranges"));
      Feedback_Text : constant String :=
        (if Snapshot.Has_Command_Feedback
           and then not Is_Priority_Feedback (Snapshot.Command_Feedback_Severity)
         then " | " & Status_Command_Outcome_Segment (Snapshot)
         else "");
   begin
      return Priority_Pending_Text
        & Priority_Feedback_Text
        & Project_Text
        & " | " & Focus_Text
        & " | " & Caret_Text
        & " | " & Selection_Text
        & " | " & Segment_Text (Snapshot.Line_Number_Mode)
        & " | "
        & (if Snapshot.Find_Input_Open and then not Snapshot.Find_Query_Present
           then "Find: No search query."
           elsif Snapshot.Find_Query_Present and then Snapshot.Active_Find_Match_Count = 0
           then "Find: No matches."
           elsif Snapshot.Find_Active_Match > 0
              and then Snapshot.Active_Find_Match_Count > 0
           then "Find:" & Natural'Image (Snapshot.Find_Active_Match)
                & " of" & Natural'Image (Snapshot.Active_Find_Match_Count)
                & (if Snapshot.Find_Wrapped then " wrapped" else "")
           else "Find:" & Natural'Image (Snapshot.Active_Find_Match_Count)
                & " " & Plural (Snapshot.Active_Find_Match_Count, "match", "matches"))
        & Undo_Redo_Text
        & Hint_Text
        & Lifecycle_Text
        & Pending_Text
        & Outline_Text
        & Diagnostics_Text
        & Build_Text
        & Search_Text
        & Quick_Open_Text
        & File_Tree_Text
        & Workspace_Text
        & Recent_Projects_Text
        & Startup_Text
        & Feedback_Text;
   end Format_Right;

   function Status_Layout_Should_Use_Compact
     (Snapshot          : Status_Bar_Snapshot;
      Available_Columns : Natural) return Boolean
   is
   begin
      return Available_Columns > 0
        and then (Available_Columns < 64
                  or else Length (Snapshot.Pending_Confirmation_Label) > 0
                  or else (Snapshot.Has_Command_Feedback
                            and then Is_Priority_Feedback
                              (Snapshot.Command_Feedback_Severity)));
   end Status_Layout_Should_Use_Compact;

   function Status_Layout_Compact
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Append_Segment (Text : String) is
      begin
         if Text'Length = 0 then
            return;
         elsif Length (Result) = 0 then
            Result := To_Unbounded_String (Text);
         else
            Append (Result, " | " & Text);
         end if;
      end Append_Segment;

      Pending_Text : constant String := Segment_Text (Snapshot.Pending_Confirmation_Label);
      Command_Text : constant String := Status_Command_Outcome_Segment (Snapshot);
      Priority_Command : constant Boolean :=
        Snapshot.Has_Command_Feedback
        and then Is_Priority_Feedback (Snapshot.Command_Feedback_Severity);
   begin
      Append_Segment (Pending_Text);
      if Priority_Command then
         Append_Segment (Command_Text);
      end if;

      Append_Segment (Status_Project_File_Segment (Snapshot));
      Append_Segment (Status_Caret_Selection_Segment (Snapshot));
      Append_Segment (Status_Focus_Segment (Snapshot));
      Append_Segment (Status_Diagnostics_Segment (Snapshot));
      Append_Segment (Status_Build_Segment (Snapshot));
      Append_Segment (Status_Search_Replace_Segment (Snapshot));
      Append_Segment (Status_Quick_Open_Segment (Snapshot));
      Append_Segment (Status_Outline_Segment (Snapshot));
      Append_Segment (Status_File_Tree_Segment (Snapshot));
      Append_Segment (Status_Workspace_Recent_Segment (Snapshot));
      Append_Segment (Status_Startup_Segment (Snapshot));

      if Snapshot.Has_Command_Feedback and then not Priority_Command then
         Append_Segment (Command_Text);
      end if;

      return Status_Truncate_Label (To_String (Result), Max_Columns);
   end Status_Layout_Compact;

end Editor.Status_Bar.Surfaces;
