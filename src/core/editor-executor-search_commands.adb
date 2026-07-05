with Ada.Directories;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.History;
with Editor.Executor.Search_Results_Commands;
with Editor.Feature_Panel;
with Editor.Files;
with Editor.Folding;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Messages;
with Editor.Navigation; use Editor.Navigation;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Panels;
with Editor.Panel_Focus;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Recent_Buffers;
with Editor.Render_Cache;
with Editor.Search_Results;
with Editor.Selection;
with Editor.UTF8;
with Editor.View;

package body Editor.Executor.Search_Commands is

   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Project_Search.Project_Search_File_Kind_Filter;
   use type Editor.Project_Search.Project_Search_Result_Id;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Project_Search_Bar.Project_Search_Bar_Field;
   use type Ada.Directories.File_Kind;
   use type Ada.Containers.Count_Type;

   function Project_Search_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;

      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;

      function Has_Selection return Boolean is
      begin
         return Has_Buffer and then Editor.Selection.Has_Selection (S);
      end Has_Selection;

      function Has_Search_Results return Boolean is
      begin
         return Editor.Project_Search.Has_Results (S.Project_Search);
      end Has_Search_Results;

      function Has_Selected_Search_Result return Boolean is
      begin
         return Has_Search_Results
           and then Editor.Project_Search.Selected_Result_Index
             (S.Project_Search) /= 0;
      end Has_Selected_Search_Result;

      function Search_Results_Has_Focus return Boolean is
      begin
         return Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus;
      end Search_Results_Has_Focus;

      function Active_Overlay_Is
        (Overlay : Editor.Overlay_Focus.Overlay_Target) return Boolean is
      begin
         return Editor.Overlay_Focus.Is_Active (S.Overlay_Focus, Overlay);
      end Active_Overlay_Is;

      function Selected_Project_Search_Result_Still_Known return Boolean is
         Found  : Boolean := False;
         Result : constant Editor.Project_Search.Project_Search_Result :=
           Editor.Project_Search.Selected_Result (S.Project_Search, Found);
         Rel      : constant String := To_String (Result.Relative_Path);
         Abs_Path : constant String := To_String (Result.Absolute_Path);
      begin
         if not Found or else not Editor.Project.Has_Project (S.Project) then
            return False;
         end if;

         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            declare
               Item : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
            begin
               if To_String (Item.Relative_Path) = Rel
                 and then To_String (Item.Absolute_Path) = Abs_Path
               then
                  return True;
               end if;
            end;
         end loop;

         return False;
      end Selected_Project_Search_Result_Still_Known;
   begin
      case Id is
         when Command_Project_Search_From_Selection =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project.Known_File_Count (S.Project) = 0 then
               return Editor.Commands.Unavailable ("No project open.");
            elsif not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Has_Selection then
               return Editor.Commands.Unavailable ("No selected text");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_From_Active_Word
            | Command_Project_Search_Active_Directory =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project.Known_File_Count (S.Project) = 0 then
               return Editor.Commands.Unavailable ("No project open.");
            elsif not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Command_Open_Project_Search_Bar
            | Command_Toggle_Project_Search_Bar =>
            if not Editor.Project.Has_Project (S.Project) then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Command_Run_Project_Search_From_Bar =>
            if not Active_Overlay_Is
              (Editor.Overlay_Focus.Project_Search_Bar_Overlay)
              or else not Editor.Project_Search_Bar.Is_Open
                (S.Project_Search_Bar)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Project_Search_Bar.Query_Text
              (S.Project_Search_Bar)'Length = 0
            then
               return Editor.Commands.Unavailable ("No project search query");
            end if;
            return Editor.Commands.Available;

         when Command_Rerun_Project_Search | Command_Run_Project_Search =>
            if not Editor.Project.Has_Project (S.Project) then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project.Known_File_Count (S.Project) = 0 then
               return Editor.Commands.Unavailable ("No project open.");
            elsif Editor.Project_Search.Query (S.Project_Search)'Length = 0 then
               return Editor.Commands.Unavailable ("No project search query");
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Project_Search =>
            if not Has_Search_Results
              and then Editor.Project_Search.Query (S.Project_Search)'Length = 0
              and then not Editor.Project_Search_Bar.Is_Open
                (S.Project_Search_Bar)
            then
               return Editor.Commands.Unavailable ("No project search");
            end if;
            return Editor.Commands.Available;

         when Command_Open_Selected_Project_Search_Result =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Project_Search_Result_Stale);
            elsif not Has_Selected_Search_Result then
               return Editor.Commands.Unavailable ("No search result selected.");
            elsif not Selected_Project_Search_Result_Still_Known then
               return Editor.Commands.Unavailable
                 ("Search result target unavailable.");
            end if;
            return Editor.Commands.Available;

         when Command_Next_Project_Search_Result
            | Command_Previous_Project_Search_Result
            | Command_First_Project_Search_Result
            | Command_Last_Project_Search_Result =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Project_Search_Result_Stale);
            end if;
            return Editor.Commands.Available;

         when Command_Reveal_Active_Project_Search_Result =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            elsif not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Scope_Selected_Directory =>
            if not Has_Selected_Search_Result then
               return Editor.Commands.Unavailable ("No search result selected.");
            elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Project_Search_Result_Stale);
            elsif not Selected_Project_Search_Result_Still_Known then
               return Editor.Commands.Unavailable
                 ("Search result target unavailable.");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Kind_Next
            | Command_Project_Search_Kind_Previous
            | Command_Project_Search_Kind_Clear
            | Command_Project_Search_Scope_Clear
            | Command_Project_Search_Case_Toggle
            | Command_Project_Search_Case_Clear
            | Command_Project_Search_Whole_Word_Toggle
            | Command_Project_Search_Whole_Word_Clear
            | Command_Project_Search_Regex_Toggle
            | Command_Project_Search_Regex_Clear
            | Command_Project_Search_Include_Filter_Clear
            | Command_Project_Search_Exclude_Filter_Clear =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Scope_Set =>
            return Editor.Commands.Unavailable
              ("Command requires explicit search scope text");

         when Command_Project_Search_Include_Filter_Set
            | Command_Project_Search_Exclude_Filter_Set =>
            return Editor.Commands.Unavailable
              ("Command requires explicit search filter text");

         when Command_Project_Search_Replace_Preview =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Has_Search_Results then
               return Editor.Commands.Unavailable ("No search results");
            elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
               return Editor.Commands.Unavailable ("Search results are stale");
            elsif not Editor.Project_Search.Replace_Text_Is_Valid
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 ("Replacement text must be single-line");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Replace_Clear_Preview =>
            if Editor.Project_Search.Replace_Preview_Count
              (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No replacement preview");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Replace_Toggle_Selected
            | Command_Project_Search_Replace_Include_Selected
            | Command_Project_Search_Replace_Exclude_Selected
            | Command_Project_Search_Replace_Include_File
            | Command_Project_Search_Replace_Exclude_File
            | Command_Project_Search_Replace_Include_All
            | Command_Project_Search_Replace_Exclude_All =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project_Search.Replace_Preview_Count
              (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No replacement preview");
            elsif Editor.Project_Search.Replace_Preview_Is_Stale
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Replacement_Preview_Stale);
            elsif not Editor.Project_Search.Replace_Text_Is_Valid
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 ("Replacement text must be single-line");
            elsif Id = Command_Project_Search_Replace_Include_All
              and then Editor.Project_Search.Eligible_Replacement_Count
                (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No eligible replacements");
            elsif Editor.Project_Search.Selected_Replace_Preview_Index
              (S.Project_Search) = 0
              and then (Id = Command_Project_Search_Replace_Toggle_Selected
                        or else Id = Command_Project_Search_Replace_Include_Selected
                        or else Id = Command_Project_Search_Replace_Exclude_Selected
                        or else Id = Command_Project_Search_Replace_Include_File
                        or else Id = Command_Project_Search_Replace_Exclude_File)
            then
               return Editor.Commands.Unavailable ("No replacement selected");
            elsif Id = Command_Project_Search_Replace_Toggle_Selected
              or else Id = Command_Project_Search_Replace_Include_Selected
              or else Id = Command_Project_Search_Replace_Exclude_Selected
              or else Id = Command_Project_Search_Replace_Include_File
              or else Id = Command_Project_Search_Replace_Exclude_File
            then
               declare
                  Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
                    Editor.Project_Search.Replace_Preview_Row_At
                      (S.Project_Search,
                       Positive'Max
                         (1, Editor.Project_Search.Selected_Replace_Preview_Index
                               (S.Project_Search)));
               begin
                  if Row.Search_Result_Id =
                    Editor.Project_Search.No_Project_Search_Result
                  then
                     return Editor.Commands.Unavailable
                       ("No replacement selected");
                  elsif Row.Stale then
                     return Editor.Commands.Unavailable
                       (Editor.Commands.Reason_Selected_Replacement_Stale);
                  elsif Row.Invalid then
                     return Editor.Commands.Unavailable
                       ("Selected replacement is invalid");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Replace_Selected =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project_Search.Replace_Preview_Count
              (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No replacement preview");
            elsif Editor.Project_Search.Replace_Preview_Is_Stale
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Replacement_Preview_Stale);
            elsif not Editor.Project_Search.Replace_Text_Is_Valid
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 ("Replacement text must be single-line");
            elsif Editor.Project_Search.Selected_Replace_Preview_Index
              (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No replacement selected");
            else
               declare
                  Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
                    Editor.Project_Search.Replace_Preview_Row_At
                      (S.Project_Search,
                       Positive'Max
                         (1, Editor.Project_Search.Selected_Replace_Preview_Index
                               (S.Project_Search)));
               begin
                  if Row.Search_Result_Id =
                    Editor.Project_Search.No_Project_Search_Result
                  then
                     return Editor.Commands.Unavailable
                       ("No replacement selected");
                  elsif Row.Stale then
                     return Editor.Commands.Unavailable
                       (Editor.Commands.Reason_Selected_Replacement_Stale);
                  elsif Row.Invalid then
                     return Editor.Commands.Unavailable
                       ("Selected replacement is invalid");
                  elsif not Row.Included then
                     return Editor.Commands.Unavailable
                       ("Selected replacement is excluded");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Project_Search_Replace_All_Included =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.Project_Search.Replace_Preview_Count
              (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No replacement preview");
            elsif Editor.Project_Search.Replace_Preview_Is_Stale
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Replacement_Preview_Stale);
            elsif not Editor.Project_Search.Replace_Text_Is_Valid
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 ("Replacement text must be single-line");
            elsif Editor.Project_Search.Included_Replacement_Count
              (S.Project_Search) = 0
            then
               return Editor.Commands.Unavailable ("No included replacements");
            elsif Editor.Project_Search.Included_Replacements_Overlap
              (S.Project_Search)
            then
               return Editor.Commands.Unavailable
                 ("Replacement preview has overlapping matches");
            end if;
            return Editor.Commands.Available;

         when Command_Search_Results_Open_Selected =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
               return Editor.Commands.Unavailable
                 (Editor.Commands.Reason_Project_Search_Result_Stale);
            elsif not Search_Results_Has_Focus then
               return Editor.Commands.Unavailable ("Command not available here");
            elsif not Has_Selected_Search_Result then
               return Editor.Commands.Unavailable ("No search result selected.");
            elsif not Selected_Project_Search_Result_Still_Known then
               return Editor.Commands.Unavailable
                 ("Search result target unavailable.");
            end if;
            return Editor.Commands.Available;

         when Command_Focus_Search_Results
            | Command_Show_Search_Results_Panel =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            end if;
            return Editor.Commands.Available;

         when Command_Search_Results_Move_Up
            | Command_Search_Results_Move_Down
            | Command_Search_Results_Page_Up
            | Command_Search_Results_Page_Down =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            elsif not Search_Results_Has_Focus then
               return Editor.Commands.Unavailable ("Command not available here");
            end if;
            return Editor.Commands.Available;

         when Command_Close_Project_Search_Bar =>
            if not Active_Overlay_Is
              (Editor.Overlay_Focus.Project_Search_Bar_Overlay)
              or else not Editor.Project_Search_Bar.Is_Open
                (S.Project_Search_Bar)
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Move_Project_Search_Selection_Up
            | Command_Move_Project_Search_Selection_Down =>
            if not Has_Search_Results then
               return Editor.Commands.Unavailable ("No project search results");
            elsif not Has_Selected_Search_Result then
               return Editor.Commands.Unavailable ("No search result selected.");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a project-search command");
      end case;
   end Project_Search_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Success;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Warning;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      if Path'Length = 0 or else Line = 0 then
         return (others => <>);
      end if;

      return
        (Buffer_Id      => 0,
         Has_File_Path  => True,
         File_Path      => To_Unbounded_String (Path),
         Display_Path   => To_Unbounded_String (Path),
         Line           => Line,
         Column         => Column,
         Viewport_Row   => 0,
         Reason         => Reason);
   end Structured_File_Navigation_Target;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;

   function Read_Project_Search_File
     (Path : String;
      Text : out Unbounded_String) return Boolean
   is
      Result : constant Editor.Files.File_Open_Result := Editor.Files.Open_File (Path);
   begin
      if Editor.Files.Is_Success (Result) then
         Text := Result.Contents;
         return True;
      else
         Text := Null_Unbounded_String;
         return False;
      end if;
   end Read_Project_Search_File;

   procedure Show_Search_Results_Panel
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, True);
      if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Show_Search_Results_Panel;

   function Search_Results_Visible_Row_Count return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
   begin
      if Editor.Layout.Cell_H = 0 then
         return 1;
      else
         return Natural'Max (1, Panel.Height / Editor.Layout.Cell_H);
      end if;
   end Search_Results_Visible_Row_Count;

   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type)
   is
      Snapshot : constant Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot (S.Project_Search, (others => <>));
   begin
      Editor.Search_Results.Ensure_Selected_Row_Visible
        (S.Search_Results_View,
         Snapshot,
         Editor.Project_Search.Selected_Result_Index (S.Project_Search),
         Search_Results_Visible_Row_Count);
   end Ensure_Search_Result_Visible;

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String)
   is
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);

      function Search_Image (Value : Natural) return String is
      begin
         return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
      end Search_Image;

      function Search_Summary_Message return String is
         Matches : constant Natural := Editor.Project_Search.Result_Count (S.Project_Search);
         Files   : constant Natural := Editor.Project_Search.Files_With_Matches (S.Project_Search);
         Skipped : constant Natural := Editor.Project_Search.Skipped_File_Count (S.Project_Search);
         Text    : Unbounded_String;
      begin
         if Matches = 0 then
            Text := To_Unbounded_String ("Project search completed: no matches.");
         else
            Text := To_Unbounded_String
              ("Project search completed: " & Search_Image (Matches) &
               " matches in " & Search_Image (Files) & " files");
         end if;
         Append (Text, "; searched "
           & Search_Image (Editor.Project_Search.Files_Searched (S.Project_Search))
           & " files");

         if Skipped > 0 then
            Append (Text, "; skipped " & Search_Image (Skipped));
            if Editor.Project_Search.Skipped_Missing_Count (S.Project_Search) > 0 then
               Append (Text, " missing=" & Search_Image
                 (Editor.Project_Search.Skipped_Missing_Count (S.Project_Search)));
            end if;
            if Editor.Project_Search.Skipped_Large_Count (S.Project_Search) > 0 then
               Append (Text, " large=" & Search_Image
                 (Editor.Project_Search.Skipped_Large_Count (S.Project_Search)));
            end if;
            if Editor.Project_Search.Skipped_Binary_Count (S.Project_Search) > 0 then
               Append (Text, " binary=" & Search_Image
                 (Editor.Project_Search.Skipped_Binary_Count (S.Project_Search)));
            end if;
            if Editor.Project_Search.Read_Error_Count (S.Project_Search) > 0 then
               Append (Text, " unreadable=" & Search_Image
                 (Editor.Project_Search.Read_Error_Count (S.Project_Search)));
            end if;
         end if;
         if Editor.Project_Search.Was_Truncated (S.Project_Search) then
            Append (Text, "; result limit reached");
            if Editor.Project_Search.Matches_Truncated_Count (S.Project_Search) > 0 then
               Append (Text, ": truncated " & Search_Image
                 (Editor.Project_Search.Matches_Truncated_Count (S.Project_Search))
                 & " matches");
            end if;
         end if;
         return To_String (Text);
      end Search_Summary_Message;
   begin
      Editor.Project_Search.Set_Query (S.Project_Search, Query);
      Show_Search_Results_Panel (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_No_Project);
         Report_Warning (S, "No project open");
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_No_Files);
         Report_Warning (S, "No project files available.");
         return;
      elsif Query'Length = 0 then
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_Empty_Query);
         Report_Info (S, "No project search query");
         return;
      end if;

      for Ch of Query loop
         if Ch = ASCII.LF or else Ch = ASCII.CR then
            Editor.Project_Search.Set_Status
              (S.Project_Search, Editor.Project_Search.Project_Search_Empty_Query);
            Report_Warning (S, "No project search query");
            return;
         end if;
      end loop;

      Editor.Project_Search.Search_Known_Project_Files
        (State   => S.Project_Search,
         Project => S.Project,
         Options => Options);

      Ensure_Search_Result_Visible (S);
      if Editor.Project_Search.Status (S.Project_Search)
        = Editor.Project_Search.Project_Search_Invalid_Regex
      then
         Report_Warning
           (S, "Invalid regex"
            & (if Editor.Project_Search.Regex_Error (S.Project_Search)'Length > 0
               then ": " & Editor.Project_Search.Regex_Error (S.Project_Search)
               else ""));
      elsif Editor.Project_Search.Eligible_File_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project files match search scope");
      else
         Report_Info (S, Search_Summary_Message);
      end if;
   end Execute_Run_Project_Search;

   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type)
   is
      Query : constant String :=
        (if Editor.Project_Search.Has_Query (S.Project_Search) then
            Editor.Project_Search.Query (S.Project_Search)
         else
            Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar));
   begin
      if Query'Length = 0 then
         Report_Info (S, "No project search query");
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_Empty_Query);
         Show_Search_Results_Panel (S);
      else
         Execute_Run_Project_Search (S, Query);
         Editor.Project_Search.Clear_Stale (S.Project_Search);
      end if;
   end Execute_Rerun_Project_Search;

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      Activate_Overlay (S, Editor.Overlay_Focus.Project_Search_Bar_Overlay);
      Editor.Project_Search_Bar.Set_Query_Text
        (S.Project_Search_Bar, Editor.Project_Search.Query (S.Project_Search));
      Editor.Project_Search_Bar.Set_Replace_Text
        (S.Project_Search_Bar, Editor.Project_Search.Replace_Text (S.Project_Search));
      Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
      Editor.Render_Cache.Invalidate_All;
      Report_Info (S, "Project Search shown.");
   end Execute_Open_Project_Search_Bar;

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         Dismiss_Active_Overlay
           (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
         Editor.Render_Cache.Invalidate_All;
      end if;
      Report_Info (S, "Project Search hidden.");
   end Execute_Close_Project_Search_Bar;

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar)
        and then Editor.Overlay_Focus.Is_Active
          (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         Execute_Close_Project_Search_Bar (S);
      else
         Execute_Open_Project_Search_Bar (S);
      end if;
   end Execute_Toggle_Project_Search_Bar;

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Set_Replace_Text
        (S.Project_Search, Editor.Project_Search_Bar.Replace_Text (S.Project_Search_Bar));
      Execute_Run_Project_Search
        (S, Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar));
      Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
   end Execute_Run_Project_Search_From_Bar;

   procedure Sync_Project_Search_Bar_Input
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Set_Query
        (S.Project_Search, Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar));
      Editor.Project_Search.Set_Replace_Text
        (S.Project_Search, Editor.Project_Search_Bar.Replace_Text (S.Project_Search_Bar));
      if Editor.Project_Search_Bar.Active_Field (S.Project_Search_Bar)
        = Editor.Project_Search_Bar.Project_Search_Replace_Field
      then
         --  The replace field can be explicitly focused while still empty.
         --  Treat that as transient replace-mode intent so delete-match
         --  workflows and render/status state do not depend on text changing.
         Editor.Project_Search.Set_Replace_Mode_Active (S.Project_Search, True);
      end if;
   end Sync_Project_Search_Bar_Input;

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Insert_Text (S.Project_Search_Bar, Text);
         Sync_Project_Search_Bar_Input (S);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Project_Search_Bar_Insert_Text;

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Backspace (S.Project_Search_Bar);
         Sync_Project_Search_Bar_Input (S);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Project_Search_Bar_Backspace;

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Delete_Forward (S.Project_Search_Bar);
         Sync_Project_Search_Bar_Input (S);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Project_Search_Bar_Delete_Forward;

   Max_Context_Search_Query_Length : constant Natural := 256;

   type Context_Search_Query_Status is
     (Context_Query_Ready,
      Context_No_Active_Buffer,
      Context_No_Selected_Text,
      Context_No_Searchable_Text,
      Context_Selection_Multiline,
      Context_Query_Too_Long,
      Context_Active_Buffer_Not_Known_Project_File,
      Context_No_Project,
      Context_No_Known_Files);

   function Context_Search_Message
     (Status : Context_Search_Query_Status) return String
   is
   begin
      case Status is
         when Context_Query_Ready =>
            return "";
         when Context_No_Active_Buffer =>
            return "No active buffer.";
         when Context_No_Selected_Text =>
            return "No selected text";
         when Context_No_Searchable_Text =>
            return "No searchable text at cursor";
         when Context_Selection_Multiline =>
            return "Selected text is not a single-line search query";
         when Context_Query_Too_Long =>
            return "Selected text is too long";
         when Context_Active_Buffer_Not_Known_Project_File =>
            return "Active buffer is not a known project file";
         when Context_No_Project =>
            return "No project open";
         when Context_No_Known_Files =>
            return "No project open.";
      end case;
   end Context_Search_Message;

   function Is_Context_Word_Character (Ch : Character) return Boolean is
   begin
      return (Ch in 'A' .. 'Z')
        or else (Ch in 'a' .. 'z')
        or else (Ch in '0' .. '9')
        or else Ch = '_';
   end Is_Context_Word_Character;

   function Context_Query_From_Selection
     (S      : Editor.State.State_Type;
      Status : out Context_Search_Query_Status) return String
   is
      Selection_Range : Editor.Selection.Active_Selection_Range;
      Selection_Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Start_Row : Natural := 0;
      Start_Col : Natural := 0;
      End_Row   : Natural := 0;
      End_Col   : Natural := 0;
   begin
      case Selection_Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Status := Context_No_Active_Buffer;
            return "";
         when Editor.Selection.Selection_No_Caret
            | Editor.Selection.Selection_Empty
            | Editor.Selection.Selection_Invalid =>
            Status := Context_No_Selected_Text;
            return "";
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      Editor.State.Row_Col_For_Index (S, Selection_Range.Low, Start_Row, Start_Col);
      Editor.State.Row_Col_For_Index (S, Selection_Range.High, End_Row, End_Col);
      if Start_Row /= End_Row then
         Status := Context_Selection_Multiline;
         return "";
      end if;

      declare
         Text : constant String := Ada.Strings.Fixed.Trim
           (To_String (Editor.Selection.Extract_Selected_Text (S)),
            Ada.Strings.Both);
      begin
         if Text'Length = 0 then
            Status := Context_No_Selected_Text;
            return "";
         elsif Text'Length > Max_Context_Search_Query_Length then
            Status := Context_Query_Too_Long;
            return "";
         else
            Status := Context_Query_Ready;
            return Text;
         end if;
      end;
   end Context_Query_From_Selection;

   function Context_Query_From_Active_Word
     (S      : Editor.State.State_Type;
      Status : out Context_Search_Query_Status) return String
   is
      Length : Natural := 0;
      Probe  : Natural := Natural (Safe_Caret (S));
      First  : Natural := 0;
      Last   : Natural := 0;
   begin
      Status := Context_No_Searchable_Text;
      if not Editor.State.Has_Active_Buffer (S) then
         Status := Context_No_Active_Buffer;
         return "";
      end if;

      Length := Text_Buffer.Length (S.Buffer);
      if Length = 0 then
         return "";
      end if;

      if Probe >= Length then
         return "";
      end if;

      if not Is_Context_Word_Character
        (Text_Buffer.Character_At (S.Buffer, Probe))
      then
         return "";
      end if;

      First := Probe;
      while First > 0
        and then Is_Context_Word_Character
          (Text_Buffer.Character_At (S.Buffer, First - 1))
      loop
         First := First - 1;
      end loop;

      Last := Probe;
      while Last + 1 < Length
        and then Is_Context_Word_Character
          (Text_Buffer.Character_At (S.Buffer, Last + 1))
      loop
         Last := Last + 1;
      end loop;

      declare
         Text : constant String := To_String
           (Extract_Text (S.Buffer, First, Last - First + 1));
      begin
         if Text'Length = 0 then
            return "";
         elsif Text'Length > Max_Context_Search_Query_Length then
            Status := Context_Query_Too_Long;
            return "";
         else
            Status := Context_Query_Ready;
            return Text;
         end if;
      end;
   end Context_Query_From_Active_Word;

   function Context_Query_From_Selection_Or_Word
     (S      : Editor.State.State_Type;
      Status : out Context_Search_Query_Status) return String
   is
      Text : constant String := Context_Query_From_Selection (S, Status);
   begin
      if Status = Context_Query_Ready
        or else Status = Context_Selection_Multiline
        or else Status = Context_Query_Too_Long
      then
         return Text;
      end if;
      return Context_Query_From_Active_Word (S, Status);
   end Context_Query_From_Selection_Or_Word;

   function Directory_Scope_For_Project_File (Path : String) return String is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;
      if Last_Slash = 0 then
         return "";
      else
         return Path (Path'First .. Last_Slash);
      end if;
   end Directory_Scope_For_Project_File;

   procedure Run_Project_Search_From_Context
     (S          : in out Editor.State.State_Type;
      Query      : String;
      Set_Scope  : Boolean;
      Scope_Text : String := "")
   is
      Valid : Boolean := False;
   begin
      if Set_Scope then
         Editor.Project_Search.Set_Path_Scope
           (S.Project_Search, Scope_Text, Valid);
         if not Valid then
            Report_Warning (S, "Active buffer is not a known project file");
            return;
         end if;
      end if;

      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, Query);
      Execute_Run_Project_Search (S, Query);
      Editor.Project_Search.Clear_Stale (S.Project_Search);
   end Run_Project_Search_From_Context;

   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type)
   is
      Status : Context_Search_Query_Status := Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, Context_Search_Message (Context_No_Project));
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Report_Warning (S, Context_Search_Message (Context_No_Known_Files));
         return;
      end if;

      Query := To_Unbounded_String (Context_Query_From_Selection (S, Status));
      if Status /= Context_Query_Ready then
         Report_Info (S, Context_Search_Message (Status));
         return;
      end if;

      Run_Project_Search_From_Context
        (S, To_String (Query), Set_Scope => False);
   end Execute_Project_Search_From_Selection;

   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type)
   is
      Status : Context_Search_Query_Status := Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, Context_Search_Message (Context_No_Project));
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Report_Warning (S, Context_Search_Message (Context_No_Known_Files));
         return;
      end if;

      Query := To_Unbounded_String (Context_Query_From_Active_Word (S, Status));
      if Status /= Context_Query_Ready then
         Report_Info (S, Context_Search_Message (Status));
         return;
      end if;

      Run_Project_Search_From_Context
        (S, To_String (Query), Set_Scope => False);
   end Execute_Project_Search_From_Active_Word;

   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type)
   is
      Status : Context_Search_Query_Status := Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
      Found  : Boolean := False;
      Path   : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, Context_Search_Message (Context_No_Project));
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Report_Warning (S, Context_Search_Message (Context_No_Known_Files));
         return;
      elsif not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, Context_Search_Message (Context_No_Active_Buffer));
         return;
      end if;

      Path := To_Unbounded_String (Active_Buffer_Known_Project_File (S, Found));
      if not Found then
         Report_Info
           (S, Context_Search_Message
              (Context_Active_Buffer_Not_Known_Project_File));
         return;
      end if;

      Query := To_Unbounded_String (Context_Query_From_Selection_Or_Word (S, Status));
      if Status /= Context_Query_Ready then
         Report_Info (S, Context_Search_Message (Status));
         return;
      end if;

      Run_Project_Search_From_Context
        (S,
         To_String (Query),
         Set_Scope  => True,
         Scope_Text => Directory_Scope_For_Project_File (To_String (Path)));
   end Execute_Project_Search_Active_Directory;

   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Clear (S.Project_Search);
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "");
         Editor.Project_Search_Bar.Set_Replace_Text (S.Project_Search_Bar, "");
      end if;
      Show_Search_Results_Panel (S);
      Report_Info (S, "Project search query cleared");
      if Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
        Editor.Panel_Focus.Search_Results_Focus
      then
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
      end if;
   end Execute_Clear_Project_Search;

   procedure Jump_To_Project_Search_Result
     (S      : in out Editor.State.State_Type;
      Result : Editor.Project_Search.Project_Search_Result)
   is
      Target_Path   : constant String := To_String (Result.Absolute_Path);
      Relative_Path : constant String := To_String (Result.Relative_Path);
      Was_Open      : Boolean := False;
      Line_Available : Boolean := True;
      Target_Index  : Editor.Cursors.Cursor_Index := 0;
      End_Index     : Editor.Cursors.Cursor_Index := 0;
      Target_Row    : Natural := (if Result.Row = 0 then 0 else Result.Row - 1);
      Start_Column  : Natural := Result.Start_Column;
      End_Column    : Natural := Result.End_Column;
      Viewport_Rows : Natural := 1;
      Desired       : Natural := 0;
      Visible_Row   : Natural := 0;
      Visible_Found : Boolean := False;
      Visible_Count : Natural := 1;
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Before_Location : constant Editor.Navigation_History.Navigation_Location :=
        Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Unknown);

      function Result_Target_Is_Current_Project_File return Boolean is
      begin
         if not Editor.Project.Has_Project (S.Project) then
            return False;
         end if;

         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            declare
               Item : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
            begin
               if To_String (Item.Relative_Path) = Relative_Path
                 and then To_String (Item.Absolute_Path) = Target_Path
               then
                  return True;
               end if;
            end;
         end loop;

         return False;
      end Result_Target_Is_Current_Project_File;
   begin
      if Editor.Project_Search.Is_Stale (S.Project_Search) then
         Report_Warning (S, "Search result is stale; run Project Search again.");
         Show_Search_Results_Panel (S);
         return;
      elsif not Result_Target_Is_Current_Project_File then
         Report_Warning (S, "Search result target unavailable.");
         Show_Search_Results_Panel (S);
         return;
      elsif Target_Path'Length = 0 or else not Ada.Directories.Exists (Target_Path) then
         Report_Warning
           (S,
            "Could not open " & Relative_Path & ": file not found");
         Show_Search_Results_Panel (S);
         return;
      end if;

      declare
         Found_Open : Boolean := False;
         Found_Id   : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Find_By_Path (Target_Path, Found_Open);
      begin
         Was_Open := Found_Open and then Found_Id /= Editor.Buffers.No_Buffer;
      end;

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Target_Path);
      --  Execute_Open_File owns the shared open/activation side effects,
      --  including recent-buffer updates.  Project Search owns the user-visible
      --  result-location outcome for this command, so discard the generic open
      --  message before posting the single Phase 334 primary message.
      Editor.Messages.Dismiss_Latest (S.Messages);

      if not S.File_Info.Has_Path
        or else To_String (S.File_Info.Path) /= Target_Path
      then
         Report_Warning (S, "Could not open " & Relative_Path);
         Show_Search_Results_Panel (S);
         return;
      end if;

      if Target_Row >= Editor.State.Line_Count (S)
        or else End_Column > Editor.Navigation.Line_Length (S, Target_Row)
      then
         --  Phase 547 completeness: a retained result whose line or original
         --  match span no longer exists is an invalid target, not permission to
         --  clamp to an unrelated location.  The file may still have opened
         --  through the normal lifecycle path, but Project Search must not
         --  silently navigate to a different source location.
         Line_Available := False;
         Report_Warning
           (S,
            "Search result target unavailable: line "
            & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both)
            & " is no longer available in " & Relative_Path);
         Show_Search_Results_Panel (S);
         return;
      end if;

      Start_Column := Natural'Min
        (Start_Column, Editor.Navigation.Line_Length (S, Target_Row));
      End_Column := Natural'Min
        (Natural'Max (End_Column, Start_Column),
         Editor.Navigation.Line_Length (S, Target_Row));

      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Target_Row);
      Target_Index := Editor.Cursors.Cursor_Index
        (Index_For_Line_Column (S, Target_Row, Start_Column));
      End_Index := Editor.Cursors.Cursor_Index
        (Index_For_Line_Column (S, Target_Row, End_Column));

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => End_Index,
          Anchor                => Target_Index,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Preferred_Column := End_Column;

      Record_Navigation_If_Target_Changed
        (S, Before_Location,
         Structured_File_Navigation_Target
           (Target_Path, Result.Row, Start_Column));

      Visible_Row := Editor.Folding.Document_Row_To_Visible_Row
        (S.Folding, Target_Row, Visible_Found);
      if not Visible_Found then
         Visible_Row := Target_Row;
      end if;

      Viewport_Rows := Natural'Max
        (1, Editor.Layout.Visible_Row_Count (Layout, Editor.View.Viewport_Height));
      Visible_Count := Natural'Max
        (1, Editor.Folding.Visible_Row_Count (S.Folding, Editor.State.Line_Count (S)));

      if Visible_Row > Viewport_Rows / 2 then
         Desired := Visible_Row - Viewport_Rows / 2;
      else
         Desired := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Visible_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired);
      Editor.View.Clear_User_Scroll_Override;
      if Line_Available then
         Report_Info
           (S,
            (if Was_Open then "Activated " else "Opened ")
            & Relative_Path & ":" & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both));
      else
         Report_Info
           (S,
            (if Was_Open then "Activated " else "Opened ")
            & Relative_Path & "; line "
            & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both)
            & " is no longer available");
      end if;
      Show_Search_Results_Panel (S);
   end Jump_To_Project_Search_Result;

   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural)
   is
      Result : Editor.Project_Search.Project_Search_Result;
   begin
      if Result_Index = 0
        or else Result_Index > Editor.Project_Search.Result_Count (S.Project_Search)
      then
         Report_Warning (S, "No search result selected.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, Result_Index);
      Result := Editor.Project_Search.Result_At (S.Project_Search, Positive (Result_Index));
      Jump_To_Project_Search_Result (S, Result);
   end Execute_Open_Project_Search_Result;

   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Next_Result, True);
         Ensure_Search_Result_Visible (S);
         Show_Search_Results_Panel (S);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Move_Project_Search_Selection_Down;

   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Previous_Result, True);
         Ensure_Search_Result_Visible (S);
         Show_Search_Results_Panel (S);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Move_Project_Search_Selection_Up;

   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
      Found  : Boolean := False;
      Result : constant Editor.Project_Search.Project_Search_Result :=
        Editor.Project_Search.Selected_Result (S.Project_Search, Found);
   begin
      if Found then
         Jump_To_Project_Search_Result (S, Result);
      else
         Report_Warning (S, "No search result selected.");
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Open_Selected_Project_Search_Result;

   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;
      Editor.Project_Search.Move_Selected_Result
        (S.Project_Search, Editor.Project_Search.Next_Result, True);
      Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected next project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Next_Project_Search_Result;

   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;
      Editor.Project_Search.Move_Selected_Result
        (S.Project_Search, Editor.Project_Search.Previous_Result, True);
      Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected previous project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Previous_Project_Search_Result;

   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Select_First_Result (S.Project_Search);
      Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected first project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_First_Project_Search_Result;

   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Select_Last_Result (S.Project_Search);
      Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected last project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Last_Project_Search_Result;

   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
      Found_Path : Boolean := False;
      Path       : constant String := Active_Buffer_Known_Project_File (S, Found_Path);
      Selected   : Boolean := False;
      Result     : Editor.Project_Search.Project_Search_Result;
   begin
      if not Editor.State.Has_Active_Buffer (S)
        or else not Editor.State.Current_File (S).Has_Path
      then
         Report_Info (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found_Path then
         Report_Info (S, "Active buffer is not a known project file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Selected := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, Path);
      if not Selected then
         Report_Info (S, "No project search result for active file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Result := Editor.Project_Search.Result_At
        (S.Project_Search,
         Positive (Editor.Project_Search.Selected_Result_Index (S.Project_Search)));
      Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Selected project search result in active file: "
         & To_String (Result.Relative_Path) & ":"
         & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Reveal_Active_Project_Search_Result;

   procedure Execute_Project_Search_Scope_Selected_Directory
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Scope : constant String :=
        Editor.Project_Search.Selected_Result_Directory (S.Project_Search, Found);
      Valid : Boolean := False;
   begin
      if not Found then
         Report_Warning (S, "No search result selected.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Set_Path_Scope (S.Project_Search, Scope, Valid);
      if Valid and then Scope'Length = 0 then
         Editor.Project_Search.Clear_Results_Preserve_Query (S.Project_Search);
         Report_Info (S, "Project search scope cleared");
      elsif Valid then
         --  Set_Path_Scope applies the existing option-change cleanup when the
         --  scope changes. If the selected directory already matches the current
         --  scope, clear explicitly so this command never leaves stale results.
         Editor.Project_Search.Clear_Results_Preserve_Query (S.Project_Search);
         Report_Info (S, "Project search scope: " & Scope);
      else
         Report_Warning (S, "Invalid Project Search scope.");
      end if;
      Show_Search_Results_Panel (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Scope_Selected_Directory;

   procedure Execute_Project_Search_Kind_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Cycle_File_Kind_Filter (S.Project_Search, True);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Project search kind: "
         & Editor.Project_Search.File_Kind_Filter_Image
           (Editor.Project_Search.File_Kind_Filter (S.Project_Search)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Kind_Next;

   procedure Execute_Project_Search_Kind_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Cycle_File_Kind_Filter (S.Project_Search, False);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Project search kind: "
         & Editor.Project_Search.File_Kind_Filter_Image
           (Editor.Project_Search.File_Kind_Filter (S.Project_Search)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Kind_Previous;

   procedure Execute_Project_Search_Kind_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.File_Kind_Filter (S.Project_Search) =
        Editor.Project_Search.Project_Search_Kind_All
      then
         Report_Info (S, "No Project Search kind filter to clear.");
      else
         Editor.Project_Search.Clear_File_Kind_Filter (S.Project_Search);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search kind: all");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Kind_Clear;

   procedure Execute_Project_Search_Scope_Set
     (S     : in out Editor.State.State_Type;
      Scope : String)
   is
      Valid : Boolean := False;
   begin
      Editor.Project_Search.Set_Path_Scope (S.Project_Search, Scope, Valid);
      if Valid then
         Show_Search_Results_Panel (S);
         if Editor.Project_Search.Path_Scope (S.Project_Search)'Length = 0 then
            Report_Info (S, "Project search scope cleared");
         else
            Report_Info (S, "Project search scope: "
              & Editor.Project_Search.Path_Scope (S.Project_Search));
         end if;
      else
         Report_Warning (S, "Invalid Project Search scope.");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Scope_Set;

   procedure Execute_Project_Search_Scope_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Path_Scope (S.Project_Search)'Length = 0 then
         Report_Info (S, "No Project Search scope to clear.");
      else
         Editor.Project_Search.Clear_Path_Scope (S.Project_Search);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search scope cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Scope_Clear;

   procedure Execute_Project_Search_Case_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Toggle_Case_Sensitive (S.Project_Search);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Project search case: "
         & (if Editor.Project_Search.Case_Sensitive (S.Project_Search)
            then "sensitive" else "insensitive"));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Case_Toggle;

   procedure Execute_Project_Search_Case_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project_Search.Case_Sensitive (S.Project_Search) then
         Report_Info (S, "Project search case: insensitive");
      else
         Editor.Project_Search.Set_Case_Sensitive (S.Project_Search, False);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search case: insensitive");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Case_Clear;

   procedure Execute_Project_Search_Whole_Word_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Toggle_Whole_Word (S.Project_Search);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Project search whole word: "
         & (if Editor.Project_Search.Whole_Word (S.Project_Search)
            then "on" else "off"));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Whole_Word_Toggle;

   procedure Execute_Project_Search_Whole_Word_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project_Search.Whole_Word (S.Project_Search) then
         Report_Info (S, "Project search whole word: off");
      else
         Editor.Project_Search.Set_Whole_Word (S.Project_Search, False);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search whole word: off");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Whole_Word_Clear;

   procedure Execute_Project_Search_Regex_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Toggle_Regex (S.Project_Search);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Project search regex: "
         & (if Editor.Project_Search.Regex_Enabled (S.Project_Search)
            then "on" else "off"));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Regex_Toggle;

   procedure Execute_Project_Search_Regex_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project_Search.Regex_Enabled (S.Project_Search) then
         Report_Info (S, "Project search regex: off");
      else
         Editor.Project_Search.Set_Regex_Enabled (S.Project_Search, False);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search regex: off");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Regex_Clear;



   procedure Execute_Project_Search_Include_Filter_Set
     (S      : in out Editor.State.State_Type;
      Filter : String)
   is
      Valid : Boolean := False;
   begin
      Editor.Project_Search.Set_Include_Path_Filter
        (S.Project_Search, Filter, Valid);
      if Valid then
         Show_Search_Results_Panel (S);
         if Editor.Project_Search.Include_Path_Filter (S.Project_Search)'Length = 0 then
            Report_Info (S, "Project search include filter cleared");
         else
            Report_Info
              (S, "Project search include filter: "
               & Editor.Project_Search.Include_Path_Filter (S.Project_Search));
         end if;
      else
         Report_Warning (S, "Invalid Project Search include filter.");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Include_Filter_Set;

   procedure Execute_Project_Search_Exclude_Filter_Set
     (S      : in out Editor.State.State_Type;
      Filter : String)
   is
      Valid : Boolean := False;
   begin
      Editor.Project_Search.Set_Exclude_Path_Filter
        (S.Project_Search, Filter, Valid);
      if Valid then
         Show_Search_Results_Panel (S);
         if Editor.Project_Search.Exclude_Path_Filter (S.Project_Search)'Length = 0 then
            Report_Info (S, "Project search exclude filter cleared");
         else
            Report_Info
              (S, "Project search exclude filter: "
               & Editor.Project_Search.Exclude_Path_Filter (S.Project_Search));
         end if;
      else
         Report_Warning (S, "Invalid Project Search exclude filter.");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Exclude_Filter_Set;

   procedure Execute_Project_Search_Include_Filter_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Include_Path_Filter (S.Project_Search)'Length = 0 then
         Report_Info (S, "No Project Search include filter to clear.");
      else
         Editor.Project_Search.Clear_Include_Path_Filter (S.Project_Search);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search include filter cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Include_Filter_Clear;

   procedure Execute_Project_Search_Exclude_Filter_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Exclude_Path_Filter (S.Project_Search)'Length = 0 then
         Report_Info (S, "No Project Search exclude filter to clear");
      else
         Editor.Project_Search.Clear_Exclude_Path_Filter (S.Project_Search);
         Show_Search_Results_Panel (S);
         Report_Info (S, "Project search exclude filter cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Exclude_Filter_Clear;

   function Mark_Dirty_Open_Project_Replace_Targets_Stale
     (S : in out Editor.State.State_Type) return Natural
   is
      Row   : Editor.Project_Search.Project_Replace_Preview_Row;
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Row.Search_Result_Id /= Editor.Project_Search.No_Project_Search_Result
           and then not Row.Stale
           and then not Row.Invalid
           and then Editor.Buffers.Global_File_Is_Dirty
             (To_String (Row.Absolute_Path))
         then
            Editor.Project_Search.Mark_Replace_Preview_Stale_For_Absolute_File
              (S.Project_Search, To_String (Row.Absolute_Path));
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Mark_Dirty_Open_Project_Replace_Targets_Stale;

   function Project_Search_Replace_Pending_Blocked
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);
   end Project_Search_Replace_Pending_Blocked;

   procedure Report_Project_Search_Replace_Pending_Blocked
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Warning (S, "Command unavailable while confirmation is pending");
      Editor.Render_Cache.Invalidate_All;
   end Report_Project_Search_Replace_Pending_Blocked;

   procedure Execute_Project_Search_Replace_Preview
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Project_Search.Project_Replace_Preview_Status;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      end if;

      Editor.Project_Search.Generate_Replace_Preview (S.Project_Search, Status);
      if Status = Editor.Project_Search.Project_Replace_Preview_Ok
        and then Mark_Dirty_Open_Project_Replace_Targets_Stale (S) > 0
      then
         --  Project Search currently scans file text from the project file
         --  system.  If a target file is already open and dirty, replacement
         --  preview rows for that file are not based on the current buffer
         --  text and must fail before inclusion/apply can treat them as a
         --  valid edit script.
         Status := Editor.Project_Search.Project_Replace_Search_Stale;
      end if;
      Show_Search_Results_Panel (S);
      case Status is
         when Editor.Project_Search.Project_Replace_Preview_Ok =>
            Report_Info
              (S, "Preview: "
               & Natural'Image (Editor.Project_Search.Included_Replacement_Count (S.Project_Search))
               & " replacements in"
               & Natural'Image (Editor.Project_Search.Included_Replacement_File_Count (S.Project_Search))
               & " files.");
         when Editor.Project_Search.Project_Replace_No_Search_Results =>
            Report_Info (S, "No search results to replace.");
         when Editor.Project_Search.Project_Replace_Search_Stale =>
            Report_Warning (S, "Search results are stale; rerun search.");
         when Editor.Project_Search.Project_Replace_Overlapping_Matches =>
            Report_Warning (S, "Replacement preview has overlapping matches; refine search.");
         when Editor.Project_Search.Project_Replace_Invalid_Replacement_Text =>
            Report_Warning (S, "Replacement text must be single-line.");
         when Editor.Project_Search.Project_Replace_Invalid_Target =>
            Report_Warning (S, "Replacement preview contains invalid target ranges; rerun search.");
         when others =>
            Report_Warning (S, "Replacement preview unavailable.");
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Preview;

   procedure Execute_Project_Search_Replace_Toggle_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Toggle_Selected_Replacement (S.Project_Search);
               Report_Info (S, "Replacement selection toggled");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Toggle_Selected;

   procedure Execute_Project_Search_Replace_Include_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Include_Selected_Replacement (S.Project_Search);
               Report_Info (S, "Replacement included");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_Selected;

   procedure Execute_Project_Search_Replace_Exclude_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Exclude_Selected_Replacement (S.Project_Search);
               Report_Info (S, "Replacement excluded");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_Selected;

   procedure Execute_Project_Search_Replace_Include_File
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Index = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, Index);
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Include_File_Replacements
                 (S.Project_Search, To_String (Row.Relative_Path));
               Report_Info (S, "Replacement file included");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_File;

   procedure Execute_Project_Search_Replace_Exclude_File
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Index = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, Index);
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Exclude_File_Replacements
                 (S.Project_Search, To_String (Row.Relative_Path));
               Report_Info (S, "Replacement file excluded");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_File;

   procedure Execute_Project_Search_Replace_Include_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Eligible_Replacement_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No eligible replacements");
      else
         Editor.Project_Search.Include_All_Replacements (S.Project_Search);
         Report_Info (S, "All eligible replacement preview rows included");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_All;

   procedure Execute_Project_Search_Replace_Exclude_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      else
         Editor.Project_Search.Exclude_All_Replacements (S.Project_Search);
         Report_Info (S, "All replacement preview rows excluded");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_All;

   procedure Focus_Project_Replace_Target_File
     (S      : in out Editor.State.State_Type;
      Path   : String;
      Opened : out Boolean)
   is
      Result : Editor.Files.File_Open_Result;
      Found  : Boolean := False;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;

      function Same_File_Path (Left, Right : String) return Boolean is
      begin
         return Left = Right
           or else Editor.Files.Canonical_Path_For_Existing_File (Left) =
             Editor.Files.Canonical_Path_For_Existing_File (Right);
      end Same_File_Path;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;
   begin
      Opened := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if S.File_Info.Has_Path
        and then Same_File_Path (To_String (S.File_Info.Path), Path)
      then
         Opened := True;
         return;
      end if;

      Id := Editor.Buffers.Global_Find_By_Path (Path, Found);
      if Found then
         Editor.Buffers.Global_Set_Active_Buffer (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
         Opened := S.File_Info.Has_Path
           and then Same_File_Path (To_String (S.File_Info.Path), Path);
         return;
      end if;

      Result := Editor.Files.Open_File (Path);
      if not Editor.Files.Is_Success (Result) then
         return;
      end if;

      --  Replacement apply is the primary command outcome.  Loading a closed
      --  target file must therefore use the same buffer/file lifecycle model
      --  as explicit open, but without posting an additional "Opened ..."
      --  status message before the replacement summary.
      if not Current_State_Is_Disposable_Initial_Untitled then
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      Id := Editor.Buffers.Global_Find_By_Path (To_String (Result.Path), Found);
      if Found then
         Editor.Buffers.Global_Set_Active_Buffer (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
      else
         Editor.Buffers.Global_Add_File_Buffer
           (Path         => To_String (Result.Path),
            Display_Name => To_String (Result.Display_Name),
            Contents     => To_String (Result.Contents),
            New_Id       => Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
      end if;

      Opened := S.File_Info.Has_Path
        and then Same_File_Path (To_String (S.File_Info.Path), Path);
   end Focus_Project_Replace_Target_File;

   procedure Apply_Project_Search_Replacements_For_File
     (S             : in out Editor.State.State_Type;
      Relative_Path : String;
      Selected_Only    : Boolean;
      Selected_Id      : Editor.Project_Search.Project_Search_Result_Id;
      Changed          : out Boolean;
      Replaced      : out Natural;
      Failed        : out Boolean;
      Failure_Message : out Unbounded_String;
      Preserve_Project_Search_Preview : Boolean := False)
   is
      Before      : Editor.State.State_Type;
      Before_Text : Unbounded_String := Null_Unbounded_String;
      Project_Search_Before_Edit : Editor.Project_Search.Project_Search_State;
      Cmd         : Editor.Commands.Command;
      Row         : Editor.Project_Search.Project_Replace_Preview_Row;
      Path        : Unbounded_String := Null_Unbounded_String;
      Pos         : Natural := 0;
      Del         : Natural := 0;
      Current     : Unbounded_String := Null_Unbounded_String;
      Replacement : constant Unbounded_String :=
        To_Unbounded_String
          (Editor.Project_Search.Replace_Text (S.Project_Search));
      Candidate_Count : Natural := 0;
      Path_Mismatch    : Boolean := False;

      function Same_Target_Path (Left, Right : String) return Boolean is
      begin
         return Left = Right
           or else Editor.Files.Canonical_Path_For_Existing_File (Left) =
             Editor.Files.Canonical_Path_For_Existing_File (Right);
      end Same_Target_Path;

      function Row_Is_Candidate
        (R : Editor.Project_Search.Project_Replace_Preview_Row) return Boolean
      is
      begin
         return R.Included
           and then not R.Stale
           and then not R.Invalid
           and then To_String (R.Relative_Path) = Relative_Path
           and then ((not Selected_Only) or else R.Search_Result_Id = Selected_Id);
      end Row_Is_Candidate;

      function Current_Line_Text
        (Target_Row : Natural) return String
      is
         Start_Pos : Natural := 0;
         Len       : Natural := 0;
      begin
         if Target_Row >= Editor.State.Line_Count (S) then
            return "";
         end if;

         Start_Pos := Index_For_Line_Column (S, Target_Row, 0);
         Len := Line_Length (S, Target_Row);
         return To_String (Extract_Text (S.Buffer, Start_Pos, Len));
      end Current_Line_Text;

      function Is_UTF8_Boundary
        (Line        : String;
         Byte_Offset : Natural) return Boolean
      is
         Next_Index : Natural := 0;
         Next_Byte  : Natural := 0;
      begin
         if Byte_Offset = 0 or else Byte_Offset = Line'Length then
            return True;
         elsif Byte_Offset > Line'Length then
            return False;
         end if;

         Next_Index := Line'First + Byte_Offset;
         Next_Byte := Character'Pos (Line (Next_Index));
         return not (Next_Byte in 16#80# .. 16#BF#);
      end Is_UTF8_Boundary;

      function Code_Point_Column_For_Byte_Offset
        (Line        : String;
         Byte_Offset : Natural;
         Valid       : out Boolean) return Natural
      is
         Last_Byte : Natural := 0;
      begin
         Valid := Byte_Offset <= Line'Length
           and then Is_UTF8_Boundary (Line, Byte_Offset);
         if not Valid or else Byte_Offset = 0 then
            return 0;
         end if;

         Last_Byte := Line'First + Byte_Offset - 1;
         return Editor.UTF8.Code_Point_Count
           (Line (Line'First .. Last_Byte));
      end Code_Point_Column_For_Byte_Offset;
   begin
      Changed := False;
      Replaced := 0;
      Failed := False;
      Failure_Message := Null_Unbounded_String;
      Cmd.Kind := Apply_Replace_Batch;

      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Row_Is_Candidate (Row) then
            Candidate_Count := Candidate_Count + 1;
            if Length (Path) = 0 then
               Path := Row.Absolute_Path;
            elsif not Same_Target_Path (To_String (Path), To_String (Row.Absolute_Path)) then
               --  A replacement transaction is keyed by a project-relative
               --  file group, but mutation opens exactly one absolute file.
               --  If stale or malformed preview rows disagree about the
               --  backing absolute path, fail the whole file group instead
               --  of applying some rows to a different buffer than the row
               --  describes.
               Path_Mismatch := True;
            end if;
         end if;
      end loop;

      if not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Failed := True;
         Failure_Message := To_Unbounded_String ("Replacement text must be single-line.");
         return;
      elsif Candidate_Count = 0 then
         return;
      elsif Length (Path) = 0 or else Path_Mismatch then
         Failed := True;
         Failure_Message := To_Unbounded_String ("Replacement target changed; rerun search.");
         return;
      elsif not Editor.Project.Has_Project (S.Project)
        or else not Editor.Project.Is_Under_Project (S.Project, To_String (Path))
      then
         Failed := True;
         Failure_Message := To_Unbounded_String ("Replacement target is outside project.");
         return;
      end if;

      begin
         if not Ada.Directories.Exists (To_String (Path)) then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target no longer exists.");
            return;
         elsif Ada.Directories.Kind (To_String (Path)) /= Ada.Directories.Ordinary_File then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target is not a regular file.");
            return;
         elsif not Editor.Files.Existing_File_Is_Writable (To_String (Path)) then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target is read-only.");
            return;
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target path is invalid.");
            return;
         when Ada.Directories.Use_Error =>
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target is unavailable.");
            return;
      end;

      if Editor.Buffers.Global_File_Is_Dirty (To_String (Path)) then
         --  Project Search replacement rows are generated from the retained
         --  search result text.  If an already-open target buffer is dirty at
         --  apply time, the preview is no longer a valid edit script for the
         --  current in-memory file.  Fail before focusing/mutating the buffer
         --  rather than relying on later text-span validation or accidentally
         --  editing unsaved user changes.
         Failed := True;
         Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
         return;
      end if;

      declare
         Target_Opened : Boolean := False;
      begin
         Focus_Project_Replace_Target_File (S, To_String (Path), Target_Opened);
         if not Target_Opened then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Could not open file for replacement.");
            return;
         end if;
      end;

      --  Validate every candidate before applying any mutation to this file.
      --  This preserves the per-file transaction boundary: stale offsets or
      --  mismatched current text fail the whole file without partial edits.
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Row_Is_Candidate (Row) then
            if Row.Row = 0 or else Row.End_Column < Row.Start_Column then
               Failed := True;
               Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
               return;
            end if;

            declare
               Line_Text : constant String := Current_Line_Text (Row.Row - 1);
               Start_OK  : Boolean := False;
               End_OK    : Boolean := False;
               Start_CP  : constant Natural :=
                 Code_Point_Column_For_Byte_Offset
                   (Line_Text, Row.Start_Column, Start_OK);
               End_CP    : constant Natural :=
                 Code_Point_Column_For_Byte_Offset
                   (Line_Text, Row.End_Column, End_OK);
            begin
               if not Start_OK or else not End_OK or else End_CP < Start_CP then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
                  return;
               end if;

               Pos := Index_For_Line_Column (S, Row.Row - 1, Start_CP);
               Del := End_CP - Start_CP;
               Current := Extract_Text (S.Buffer, Pos, Del);
               if To_String (Current) /= To_String (Row.Match_Text) then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
                  return;
               end if;

               if To_String (Current) /= To_String (Replacement) then
                  Append_Replace_Op (Cmd, Cursor_Index (Pos), Del, Replacement);
               end if;
            end;
         end if;
      end loop;

      if Cmd.Positions.Length = 0 then
         return;
      end if;

      Before := S;
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      if Preserve_Project_Search_Preview then
         Project_Search_Before_Edit := S.Project_Search;
      end if;
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      if Preserve_Project_Search_Preview then
         S.Project_Search := Project_Search_Before_Edit;
      end if;
      if Editor.State.Current_Text (S) /= To_String (Before_Text) then
         Editor.Executor.History.Log_Edit (Before, S, Cmd);
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Changed := True;
         Replaced := Natural (Cmd.Positions.Length);
      end if;
   end Apply_Project_Search_Replacements_For_File;

   procedure Execute_Project_Search_Replace_Selected
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search);
      Row : Editor.Project_Search.Project_Replace_Preview_Row;
      Changed  : Boolean := False;
      Failed   : Boolean := False;
      Replaced : Natural := 0;
      Failure_Message : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      end if;

      if Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0
        or else Index = 0
      then
         Report_Warning (S, "No replacement selected");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, Positive'Max (1, Index));
      if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
         Report_Warning (S, "No replacement selected");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Row.Stale then
         Report_Warning (S, "Selected replacement is stale");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Row.Invalid then
         Report_Warning (S, "Selected replacement is invalid");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Row.Included then
         Report_Warning (S, "Selected replacement is excluded");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Apply_Project_Search_Replacements_For_File
        (S             => S,
         Relative_Path => To_String (Row.Relative_Path),
         Selected_Only    => True,
         Selected_Id      => Row.Search_Result_Id,
         Changed          => Changed,
         Replaced      => Replaced,
         Failed        => Failed,
         Failure_Message => Failure_Message);

      if Failed then
         Editor.Project_Search.Mark_Replace_Preview_Stale_For_File
           (S.Project_Search, To_String (Row.Relative_Path));
         if Length (Failure_Message) > 0 then
            Report_Warning (S, To_String (Failure_Message));
         else
            Report_Warning (S, "Project replacement failed.");
         end if;
      elsif Changed then
         Editor.Project_Search.Mark_Replace_Preview_Stale_For_File
           (S.Project_Search, To_String (Row.Relative_Path));
         Report_Success (S, "Replaced selected project match");
      else
         Report_Info (S, "Selected replacement made no text change");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Selected;

   procedure Execute_Project_Search_Replace_All_Included
     (S : in out Editor.State.State_Type)
   is
      Row             : Editor.Project_Search.Project_Replace_Preview_Row;
      Changed         : Boolean := False;
      File_Failed     : Boolean := False;
      File_Replaced   : Natural := 0;
      File_Failure_Message : Unbounded_String := Null_Unbounded_String;
      Last_Failure_Message : Unbounded_String := Null_Unbounded_String;
      Total_Replaced  : Natural := 0;
      Changed_Files   : Natural := 0;
      Failed_Files    : Natural := 0;
      Candidate_Files : Natural := 0;

      function Eligible_Apply_Row
        (R : Editor.Project_Search.Project_Replace_Preview_Row) return Boolean
      is
      begin
         return R.Included and then not R.Stale and then not R.Invalid;
      end Eligible_Apply_Row;

      function Path_Seen_Before
        (Limit : Positive;
         Path  : String) return Boolean
      is
         Prior : Editor.Project_Search.Project_Replace_Preview_Row;
      begin
         if Limit = 1 then
            return False;
         end if;

         for J in 1 .. Limit - 1 loop
            Prior := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, J);
            if Eligible_Apply_Row (Prior)
              and then To_String (Prior.Relative_Path) = Path
            then
               return True;
            end if;
         end loop;
         return False;
      end Path_Seen_Before;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Included_Replacement_Count (S.Project_Search) = 0 then
         Report_Info (S, "No included replacements");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Included_Replacements_Overlap (S.Project_Search) then
         Report_Warning (S, "Replacement preview has overlapping matches; refine search.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      ------------------------------------------------------------------
      -- Snapshot the file set before any mutation.
      --
      -- Applying one file may focus another buffer and may mark rows stale
      -- after a failed or successful mutation.  Replace-all must still be a
      -- deterministic operation over the explicitly included fresh candidate
      -- set that existed at command start, not over a live row list whose
      -- global stale flag changes during the same command.
      ------------------------------------------------------------------
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Eligible_Apply_Row (Row)
           and then not Path_Seen_Before (I, To_String (Row.Relative_Path))
         then
            Candidate_Files := Candidate_Files + 1;
         end if;
      end loop;

      if Candidate_Files = 0 then
         Report_Info (S, "No included replacements");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         type Path_Array is array (Positive range <>) of Unbounded_String;
         Paths : Path_Array (1 .. Candidate_Files);
         Next  : Natural := 0;
      begin
         for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
            Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
            if Eligible_Apply_Row (Row)
              and then not Path_Seen_Before (I, To_String (Row.Relative_Path))
            then
               Next := Next + 1;
               Paths (Next) := Row.Relative_Path;
            end if;
         end loop;

         for I in Paths'Range loop
            Apply_Project_Search_Replacements_For_File
              (S             => S,
               Relative_Path => To_String (Paths (I)),
               Selected_Only => False,
               Selected_Id   => Editor.Project_Search.No_Project_Search_Result,
               Changed       => Changed,
               Replaced      => File_Replaced,
               Failed        => File_Failed,
               Failure_Message => File_Failure_Message,
               Preserve_Project_Search_Preview => True);

            if File_Failed then
               Failed_Files := Failed_Files + 1;
               if Length (File_Failure_Message) > 0 then
                  Last_Failure_Message := File_Failure_Message;
               end if;
               Editor.Project_Search.Mark_Replace_Preview_Stale_For_File
                 (S.Project_Search, To_String (Paths (I)));
            elsif Changed then
               Changed_Files := Changed_Files + 1;
               Total_Replaced := Total_Replaced + File_Replaced;
            end if;
         end loop;
      end;

      if Changed_Files > 0 then
         Editor.Project_Search.Mark_Replace_Preview_Stale (S.Project_Search);
      end if;

      if Failed_Files > 0 and then Changed_Files > 0 then
         Report_Warning
           (S,
            "Replaced " & Image_Of (Total_Replaced) & " matches in"
            & Image_Of (Changed_Files) & " files;"
            & Image_Of (Failed_Files) & " files failed.");
      elsif Failed_Files > 0 then
         if Failed_Files = 1 and then Length (Last_Failure_Message) > 0 then
            Report_Warning (S, To_String (Last_Failure_Message));
         else
            Report_Warning (S, "Some replacements failed.");
         end if;
      elsif Total_Replaced = 0 then
         Report_Info (S, "Included replacements made no text changes");
      else
         Report_Success
           (S,
            "Replaced " & Image_Of (Total_Replaced) & " matches in"
            & Image_Of (Changed_Files) & " files");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_All_Included;

   procedure Execute_Project_Search_Replace_Clear_Preview
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Clear_Replace_Preview (S.Project_Search);
      Report_Info (S, "Replacement preview cleared");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Clear_Preview;

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
   begin
      case Cmd.Kind is
         when Run_Project_Search =>
            if Length (Cmd.Query) = 0 then
               Execute_Run_Project_Search (S, To_String (Cmd.Text));
            else
               Execute_Run_Project_Search (S, To_String (Cmd.Query));
            end if;

         when Rerun_Project_Search =>
            Execute_Rerun_Project_Search (S);

         when Open_Project_Search_Bar =>
            Execute_Open_Project_Search_Bar (S);

         when Toggle_Project_Search_Bar =>
            Execute_Toggle_Project_Search_Bar (S);

         when Close_Project_Search_Bar =>
            Execute_Close_Project_Search_Bar (S);

         when Run_Project_Search_From_Bar =>
            if Length (Cmd.Query) > 0 then
               Execute_Run_Project_Search (S, To_String (Cmd.Query));
            elsif Length (Cmd.Text) > 0 then
               Execute_Run_Project_Search (S, To_String (Cmd.Text));
            else
               Execute_Run_Project_Search_From_Bar (S);
            end if;

         when Project_Search_Bar_Insert_Text =>
            Execute_Project_Search_Bar_Insert_Text (S, To_String (Cmd.Text));

         when Project_Search_Bar_Backspace =>
            Execute_Project_Search_Bar_Backspace (S);

         when Project_Search_Bar_Delete_Forward =>
            Execute_Project_Search_Bar_Delete_Forward (S);

         when Project_Search_Bar_Move_Cursor_Left =>
            Editor.Project_Search_Bar.Move_Cursor_Left (S.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;

         when Project_Search_Bar_Move_Cursor_Right =>
            Editor.Project_Search_Bar.Move_Cursor_Right (S.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;

         when Project_Search_From_Selection =>
            Execute_Project_Search_From_Selection (S);

         when Project_Search_From_Active_Word =>
            Execute_Project_Search_From_Active_Word (S);

         when Project_Search_Active_Directory =>
            Execute_Project_Search_Active_Directory (S);

         when Clear_Project_Search =>
            Execute_Clear_Project_Search (S);

         when Show_Search_Results_Panel =>
            Show_Search_Results_Panel (S);

         when Open_Selected_Project_Search_Result =>
            Execute_Open_Selected_Project_Search_Result (S);

         when Move_Project_Search_Selection_Up =>
            Execute_Move_Project_Search_Selection_Up (S);

         when Move_Project_Search_Selection_Down =>
            Execute_Move_Project_Search_Selection_Down (S);

         when Next_Project_Search_Result =>
            Execute_Next_Project_Search_Result (S);

         when Previous_Project_Search_Result =>
            Execute_Previous_Project_Search_Result (S);

         when First_Project_Search_Result =>
            Execute_First_Project_Search_Result (S);

         when Last_Project_Search_Result =>
            Execute_Last_Project_Search_Result (S);

         when Reveal_Active_Project_Search_Result =>
            Execute_Reveal_Active_Project_Search_Result (S);

         when Project_Search_Scope_Selected_Directory =>
            Execute_Project_Search_Scope_Selected_Directory (S);

         when Project_Search_Kind_Next =>
            Execute_Project_Search_Kind_Next (S);

         when Project_Search_Kind_Previous =>
            Execute_Project_Search_Kind_Previous (S);

         when Project_Search_Kind_Clear =>
            Execute_Project_Search_Kind_Clear (S);

         when Project_Search_Scope_Set =>
            Execute_Project_Search_Scope_Set (S, To_String (Cmd.Text));

         when Project_Search_Scope_Clear =>
            Execute_Project_Search_Scope_Clear (S);

         when Project_Search_Case_Toggle =>
            Execute_Project_Search_Case_Toggle (S);

         when Project_Search_Case_Clear =>
            Execute_Project_Search_Case_Clear (S);

         when Project_Search_Whole_Word_Toggle =>
            Execute_Project_Search_Whole_Word_Toggle (S);

         when Project_Search_Whole_Word_Clear =>
            Execute_Project_Search_Whole_Word_Clear (S);

         when Project_Search_Regex_Toggle =>
            Execute_Project_Search_Regex_Toggle (S);

         when Project_Search_Regex_Clear =>
            Execute_Project_Search_Regex_Clear (S);

         when Project_Search_Include_Filter_Set =>
            Execute_Project_Search_Include_Filter_Set (S, To_String (Cmd.Text));

         when Project_Search_Exclude_Filter_Set =>
            Execute_Project_Search_Exclude_Filter_Set (S, To_String (Cmd.Text));

         when Project_Search_Include_Filter_Clear =>
            Execute_Project_Search_Include_Filter_Clear (S);

         when Project_Search_Exclude_Filter_Clear =>
            Execute_Project_Search_Exclude_Filter_Clear (S);

         when Project_Search_Replace_Preview =>
            if Length (Cmd.Text) > 0 then
               Editor.Project_Search.Set_Replace_Text
                 (S.Project_Search, To_String (Cmd.Text));
            end if;
            Execute_Project_Search_Replace_Preview (S);

         when Project_Search_Replace_Toggle_Selected =>
            Execute_Project_Search_Replace_Toggle_Selected (S);

         when Project_Search_Replace_Include_Selected =>
            Execute_Project_Search_Replace_Include_Selected (S);

         when Project_Search_Replace_Exclude_Selected =>
            Execute_Project_Search_Replace_Exclude_Selected (S);

         when Project_Search_Replace_Include_File =>
            Execute_Project_Search_Replace_Include_File (S);

         when Project_Search_Replace_Exclude_File =>
            Execute_Project_Search_Replace_Exclude_File (S);

         when Project_Search_Replace_Include_All =>
            Execute_Project_Search_Replace_Include_All (S);

         when Project_Search_Replace_Exclude_All =>
            Execute_Project_Search_Replace_Exclude_All (S);

         when Project_Search_Replace_Selected =>
            Execute_Project_Search_Replace_Selected (S);

         when Project_Search_Replace_All_Included =>
            Execute_Project_Search_Replace_All_Included (S);

         when Project_Search_Replace_Clear_Preview =>
            Execute_Project_Search_Replace_Clear_Preview (S);

         when others =>
            raise Program_Error with "unsupported project search command kind";
      end case;
   end Execute_Project_Search_Kind;

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        and then Editor.Panels.Active_Bottom_Content (S.Panels) =
          Editor.Panels.Search_Results_Content
      then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      elsif Editor.Project_Search.Result_Count (S.Project_Search) > 0 then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      else
         Editor.Executor.Report_Info (S, "No project search results");
      end if;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Search_Results;

   procedure Execute_Search_Results_Move_Up
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Editor.Executor.Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Previous_Result, False);
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Move_Up;

   procedure Execute_Search_Results_Move_Down
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Editor.Executor.Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Next_Result, False);
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Move_Down;

   procedure Execute_Search_Results_Page_Up
     (S : in out Editor.State.State_Type)
   is
      Steps : constant Natural := Search_Results_Visible_Row_Count;
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Editor.Executor.Report_Info (S, "No project search results");
      else
         for I in 1 .. Steps loop
            Editor.Project_Search.Move_Selected_Result
              (S.Project_Search, Editor.Project_Search.Previous_Result, False);
         end loop;
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Page_Up;

   procedure Execute_Search_Results_Page_Down
     (S : in out Editor.State.State_Type)
   is
      Steps : constant Natural := Search_Results_Visible_Row_Count;
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Editor.Executor.Report_Info (S, "No project search results");
      else
         for I in 1 .. Steps loop
            Editor.Project_Search.Move_Selected_Result
              (S.Project_Search, Editor.Project_Search.Next_Result, False);
         end loop;
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Page_Down;

   procedure Execute_Search_Results_Open_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
        Editor.Feature_Panel.Search_Results_Feature
        and then Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
      then
         declare
            Result : constant Editor.Executor.Command_Execution_Result :=
              Editor.Executor.Search_Results_Commands
                .Execute_Search_Result_Row_Activation
                (S, Editor.Feature_Panel.Selected_Row (S.Feature_Panel));
         begin
            if Result.Status = Editor.Executor.Command_Executed then
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;
         end;
      end if;

      Execute_Open_Selected_Project_Search_Result (S);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Open_Selected;

   procedure Execute_Search_Results_Close_Or_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Close_Or_Hide;

end Editor.Executor.Search_Commands;
