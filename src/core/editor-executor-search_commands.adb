with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
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
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Project_Search_Replace_Commands;
with Editor.Executor.Project_Search_Surface_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Feature_Panel;
with Editor.Files;
with Editor.File_Tree;
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
   use type Editor.File_Tree.File_Tree_Node_Id;
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

      function Project_Search_File_Count return Natural is
      begin
         if Editor.File_Tree.File_Node_Count (S.File_Tree) > 0 then
            return Editor.File_Tree.File_Node_Count (S.File_Tree);
         elsif Editor.Project.Has_Project (S.Project) then
            return Editor.Project.Known_File_Count (S.Project);
         else
            return 0;
         end if;
      end Project_Search_File_Count;

      function Selected_Project_Search_Result_Still_Known return Boolean is
         Found  : Boolean := False;
         Result : constant Editor.Project_Search.Project_Search_Result :=
           Editor.Project_Search.Selected_Result (S.Project_Search, Found);
         Rel      : constant String := To_String (Result.Relative_Path);
         Abs_Path : constant String := To_String (Result.Absolute_Path);
      begin
         if not Found then
            return False;
         elsif Editor.File_Tree.File_Node_Count (S.File_Tree) > 0
           and then Result.File_Node_Id /= Editor.File_Tree.No_File_Tree_Node
         then
            return Editor.File_Tree.Contains (S.File_Tree, Result.File_Node_Id);
         elsif not Editor.Project.Has_Project (S.Project) then
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
            elsif Project_Search_File_Count = 0 then
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
            elsif Project_Search_File_Count = 0 then
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
            elsif Project_Search_File_Count = 0 then
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
            elsif Project_Search_File_Count = 0 then
               return Editor.Commands.Unavailable ("No project files.");
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
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Warning;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

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
      renames Editor.Executor.Search_Results_Commands
        .Search_Results_Visible_Row_Count;

   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Ensure_Search_Result_Visible;

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Run_Project_Search;

   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Rerun_Project_Search;

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Open_Project_Search_Bar;

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Close_Project_Search_Bar;

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Toggle_Project_Search_Bar;

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Run_Project_Search_From_Bar;

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Project_Search_Bar_Insert_Text;

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Project_Search_Bar_Backspace;

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Surface_Commands
        .Execute_Project_Search_Bar_Delete_Forward;

   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Project_Search_From_Selection;

   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Project_Search_From_Active_Word;

   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Project_Search_Active_Directory;

   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Clear_Project_Search;

   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Open_Project_Search_Result;

   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Move_Project_Search_Selection_Down;

   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Move_Project_Search_Selection_Up;

   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Open_Selected_Project_Search_Result;

   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Next_Project_Search_Result;

   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Previous_Project_Search_Result;

   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_First_Project_Search_Result;

   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Last_Project_Search_Result;

   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Result_Commands
        .Execute_Reveal_Active_Project_Search_Result;

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

   procedure Execute_Project_Search_Replace_Preview
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Preview;

   procedure Execute_Project_Search_Replace_Toggle_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Toggle_Selected;

   procedure Execute_Project_Search_Replace_Include_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Include_Selected;

   procedure Execute_Project_Search_Replace_Exclude_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Exclude_Selected;

   procedure Execute_Project_Search_Replace_Include_File
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Include_File;

   procedure Execute_Project_Search_Replace_Exclude_File
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Exclude_File;

   procedure Execute_Project_Search_Replace_Include_All
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Include_All;

   procedure Execute_Project_Search_Replace_Exclude_All
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Exclude_All;

   procedure Execute_Project_Search_Replace_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Selected;

   procedure Execute_Project_Search_Replace_All_Included
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_All_Included;

   procedure Execute_Project_Search_Replace_Clear_Preview
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Project_Search_Replace_Commands
        .Execute_Project_Search_Replace_Clear_Preview;

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
      renames Editor.Executor.Search_Results_Commands
        .Execute_Focus_Search_Results;

   procedure Execute_Search_Results_Move_Up
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Execute_Search_Results_Move_Up;

   procedure Execute_Search_Results_Move_Down
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Execute_Search_Results_Move_Down;

   procedure Execute_Search_Results_Page_Up
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Execute_Search_Results_Page_Up;

   procedure Execute_Search_Results_Page_Down
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Execute_Search_Results_Page_Down;

   procedure Execute_Search_Results_Open_Selected
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Execute_Search_Results_Open_Selected;

   procedure Execute_Search_Results_Close_Or_Hide
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Results_Commands
        .Execute_Search_Results_Close_Or_Hide;

end Editor.Executor.Search_Commands;
