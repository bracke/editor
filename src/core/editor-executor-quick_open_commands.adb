with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Ada.Containers;
use type Ada.Containers.Count_Type;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.IO_Exceptions;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Quick_Open_Context_Commands;
with Editor.Executor.Quick_Open_Create_Commands;
with Editor.Executor.Quick_Open_Scope_Commands;
with Editor.Executor.Quick_Open_Input_Commands;
with Editor.Files;
with Editor.File_Tree;
with Editor.Focus_Management;
with Editor.Feature_Panel;
with Editor.Guided_Prompts;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;
with Editor.Project;
with Editor.Go_To_Line;
with Editor.Quick_Open;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
use type Editor.Quick_Open.Quick_Open_Priority_Mode;
with Editor.Quick_Open_Markers;
with Editor.Rectangle_Selection;
with Editor.Render_Cache;
with Editor.State;
use Editor.Executor.Command_Surface_Commands;

package body Editor.Executor.Quick_Open_Commands is

   use type Editor.File_Tree.File_Tree_Node_Id;

   function Normalize_Path_Separators (Text : String) return String is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         if Text (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Text (I);
         end if;
      end loop;
      return Result;
   end Normalize_Path_Separators;

   function Quick_Open_File_Count
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if Editor.File_Tree.File_Node_Count (S.File_Tree) > 0 then
         return Editor.File_Tree.File_Node_Count (S.File_Tree);
      elsif Editor.Project.Has_Project (S.Project) then
         return Editor.Project.Known_File_Count (S.Project);
      else
         return 0;
      end if;
   end Quick_Open_File_Count;

   function Quick_Open_Selected_File_Is_Current
     (S : Editor.State.State_Type) return Boolean
   is
      Found  : Boolean := False;
      Result : constant Editor.Quick_Open.Quick_Open_Result :=
        Editor.Quick_Open.Selected_Result (S.Quick_Open, Found);
   begin
      if not Found then
         return False;
      elsif Editor.File_Tree.File_Node_Count (S.File_Tree) > 0
        and then Result.Node_Id /= Editor.File_Tree.No_File_Tree_Node
      then
         return Editor.File_Tree.Contains (S.File_Tree, Result.Node_Id);
      elsif not Editor.Project.Has_Project (S.Project) then
         return False;
      end if;

      for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
         declare
            File_Item : constant Editor.Project.Project_File_Entry :=
              Editor.Project.Known_File_At (S.Project, I);
         begin
            if Normalize_Path_Separators
              (To_String (File_Item.Relative_Path)) = To_String (Result.Display_Path)
              and then To_String (File_Item.Absolute_Path) = To_String (Result.Absolute_Path)
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Quick_Open_Selected_File_Is_Current;

   function Command_Surface_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;

      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;

      function Active_Overlay_Is
        (Overlay : Editor.Overlay_Focus.Overlay_Target) return Boolean is
      begin
         return Editor.Overlay_Focus.Is_Active (S.Overlay_Focus, Overlay);
      end Active_Overlay_Is;

      function Quick_Open_Has_Selected_Result return Boolean is
      begin
         return Editor.Quick_Open.Result_Count (S.Quick_Open) > 0
           and then Editor.Quick_Open.Selected_Result_Index (S.Quick_Open) /= 0;
      end Quick_Open_Has_Selected_Result;
   begin
      case Id is
         when Command_Goto_Line
            | Command_Goto_Line_Toggle
            | Command_Open_Command_Palette
            | Command_Cancel =>
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Goto_Line_Prefill_Current =>
            if not Has_Buffer then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active buffer.");
            elsif S.Carets.Length = 0
              or else Editor.State.Line_Count (S) = 0
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No current caret location");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Open_Quick_Open =>
            if not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open.");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Toggle_Quick_Open =>
            if not Has_Project
              and then not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open.");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Reveal_Active
            | Command_Quick_Open_Scope_Active_Directory =>
            if not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif not Has_Buffer then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active buffer.");
            elsif Quick_Open_File_Count (S) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project files.");
            else
               declare
                  Found   : Boolean := False;
                  Ignored : constant String :=
                    Editor.Executor.Active_Buffer_Known_Project_File
                      (S, Found);
                  pragma Unreferenced (Ignored);
               begin
                  if not Found then
                     return Editor.Commands.Availability_Metadata.Unavailable
                       ("Active buffer is not a known project file");
                  end if;
               end;
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Priority_Toggle
            | Command_Quick_Open_Priority_Clear =>
            if not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query =>
            if not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif Editor.Project.Root_Path (S.Project)'Length = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open.");
            elsif not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif Ada.Strings.Fixed.Trim
              (Editor.Quick_Open.Query_Text (S.Quick_Open),
               Ada.Strings.Both)'Length = 0
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No Quick Open query");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Palette_Show_Command_Help =>
            if not Editor.Command_Palette.Is_Open then
               return Editor.Commands.Availability_Metadata.Unavailable ("Command Palette closed");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Close_Quick_Open =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Accept_Quick_Open =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif not Quick_Open_Has_Selected_Result then
               return Editor.Commands.Availability_Metadata.Unavailable ("No Quick Open selection");
            elsif not Quick_Open_Selected_File_Is_Current (S) then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("Selected file is no longer in project");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Next_Result
            | Command_Quick_Open_Previous_Result =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
               if Quick_Open_File_Count (S) = 0 then
                  return Editor.Commands.Availability_Metadata.Unavailable ("No project files");
               else
                  return Editor.Commands.Availability_Metadata.Unavailable ("No Quick Open matches.");
               end if;
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Query_Set =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Query_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            elsif Editor.Quick_Open.Query_Text (S.Quick_Open)'Length = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("No Quick Open query to clear");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Kind_Next
            | Command_Quick_Open_Kind_Previous =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Kind_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif Editor.Quick_Open.File_Kind_Filter (S.Quick_Open) =
              Editor.Quick_Open.All_Files
            then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("No Quick Open file-kind filter to clear");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Scope_Set =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Scope_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif Editor.Quick_Open.Path_Scope (S.Quick_Open)'Length = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("No Quick Open scope to clear");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Scope_From_Selected =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif not Quick_Open_Has_Selected_Result then
               return Editor.Commands.Availability_Metadata.Unavailable ("No Quick Open selection");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Quick_Open_Scope_Parent =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Quick_Open_Overlay)
              or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("Quick Open is not visible");
            elsif not Has_Project then
               return Editor.Commands.Availability_Metadata.Unavailable ("No project open");
            elsif Editor.Quick_Open.Path_Scope (S.Quick_Open)'Length = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No Quick Open scope");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Goto_Line_Query_Set =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Go_To_Line_Overlay)
              or else not Editor.Go_To_Line.Is_Open (S.Go_To_Line)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Goto_Line_Query_Clear =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Go_To_Line_Overlay)
              or else not Editor.Go_To_Line.Is_Open (S.Go_To_Line)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            elsif Ada.Strings.Fixed.Trim
              (Editor.Go_To_Line.Text (S.Go_To_Line),
               Ada.Strings.Both)'Length = 0
              and then not Editor.Go_To_Line.Has_Error (S.Go_To_Line)
            then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("No go-to-line query to clear");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Close_Goto_Line
            | Command_Accept_Goto_Line =>
            if not Active_Overlay_Is (Editor.Overlay_Focus.Go_To_Line_Overlay)
              or else not Editor.Go_To_Line.Is_Open (S.Go_To_Line)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when others =>
            return Editor.Commands.Availability_Metadata.Unavailable
              ("Command is not a command-surface command");
      end case;
   end Command_Surface_Command_Availability;

   function Default_Quick_Open_Config return Editor.Quick_Open.Quick_Open_Config is
   begin
      return (others => <>);
   end Default_Quick_Open_Config;

   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Recompute_Quick_Open (S);
   end Recompute_Quick_Open;


   function Has_Primary_Selection
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      if S.Carets.Length = 0 then
         return False;
      else
         return Editor.Rectangle_Selection.Has_Selection
           (S.Carets (S.Carets.First_Index));
      end if;
   end Has_Primary_Selection;

   procedure Collapse_All_Selections
     (S : in out Editor.State.State_Type)
   is
      C : Editor.Cursors.Caret_State;
   begin
      if S.Carets.Length = 0 then
         return;
      end if;

      for I in S.Carets.First_Index .. S.Carets.Last_Index loop
         C := S.Carets (I);
         C.Anchor := C.Pos;
         S.Carets.Replace_Element (I, C);
      end loop;
   end Collapse_All_Selections;

   procedure Report_Quick_Open_Shown
     (S : in out Editor.State.State_Type)
   is
      Count : constant Natural := Editor.Quick_Open.Result_Count (S.Quick_Open);
   begin
      if Count = 0 then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
         elsif Quick_Open_File_Count (S) = 0 then
            Editor.Executor.Shared_Services.Report_Info (S, "No project files");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No Quick Open matches.");
         end if;
      else
         Editor.Executor.Shared_Services.Report_Info (S, "Quick Open shown");
      end if;
   end Report_Quick_Open_Shown;

   procedure Execute_Open_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Activate_Overlay (S, Editor.Overlay_Focus.Quick_Open_Overlay);
      Recompute_Quick_Open (S);
      Report_Quick_Open_Shown (S);
   end Execute_Open_Quick_Open;

   procedure Execute_Close_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
         Editor.Render_Cache.Invalidate_All;
      end if;
      Editor.Executor.Shared_Services.Report_Info (S, "Quick Open hidden");
   end Execute_Close_Quick_Open;

   procedure Execute_Toggle_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        and then Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Execute_Close_Quick_Open (S);
      else
         Execute_Open_Quick_Open (S);
      end if;
   end Execute_Toggle_Quick_Open;

   procedure Execute_Accept_Quick_Open
     (S : in out Editor.State.State_Type)
   is
      Found        : Boolean := False;
      Buffer_Found : Boolean := False;
      Existing_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      pragma Unreferenced (Existing_Id);
      Preflight    : Editor.Files.File_Open_Result;
      Result       : constant Editor.Quick_Open.Quick_Open_Result :=
        Editor.Quick_Open.Selected_Result (S.Quick_Open, Found);
      Path         : constant String := To_String (Result.Absolute_Path);
      Label        : constant String := To_String (Result.Display_Path);

      function Selected_File_Still_Known return Boolean is
      begin
         return Quick_Open_Selected_File_Is_Current (S);
      end Selected_File_Still_Known;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.Buffer_Lifecycle.File_Info.Has_Path
           and then not S.Buffer_Lifecycle.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;
   begin
      --  accepting a Quick Open result is an ordinary open/focus
      --  action and should replace restore-only current feedback.
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No Quick Open selection");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if not Selected_File_Still_Known then
         Editor.Executor.Shared_Services.Report_Error (S, "Selected file is no longer in project");
         Recompute_Quick_Open (S);
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Existing_Id := Editor.Buffers.Global_Find_By_Path (Path, Buffer_Found);
      if not Buffer_Found then
         --  Keep Quick Open visible and unchanged for open failures that the
         --  ordinary open path would report after attempting to read the file
         --  (missing, directory, unreadable, invalid encoding, and I/O errors).
         --  Existing open buffers skip this preflight so dirty/open state is
         --  never reloaded or inspected through the filesystem.
         Preflight := Editor.Files.Open_File (Path);
         if not Editor.Files.Is_Success (Preflight) then
            if Current_State_Is_Disposable_Initial_Untitled then
               S.Buffer_Lifecycle.Active_Buffer_Token := 0;
            end if;
            Editor.Executor.Shared_Services.Report_Error (S, "Could not open " & Label & ": "
               & (case Preflight.Status is
                    when Editor.Files.File_Open_Not_Found => "file not found",
                    when Editor.Files.File_Open_Permission_Denied => "permission denied",
                    when others => Editor.Files.Status_Message (Preflight)));
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;
      end if;

      declare
         Before_Location : constant Editor.Navigation_History.Navigation_Location :=
           Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Unknown);
      begin
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
         if S.Buffer_Lifecycle.File_Info.Has_Path
           and then To_String (S.Buffer_Lifecycle.File_Info.Path) = Path
         then
            Editor.Executor.Record_Navigation_If_Target_Changed (S, Before_Location,
               Editor.Executor.Structured_File_Navigation_Target (Path));
         end if;
      end;

      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
      end if;
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Accept_Quick_Open;

   procedure Move_Quick_Open_Selection_By_Snapshot
     (S       : in out Editor.State.State_Type;
      Forward : Boolean)
   is
      Snapshot : constant Editor.Quick_Open.Quick_Open_Snapshot :=
        Editor.Quick_Open_Markers.Build_Snapshot
          (State    => S.Quick_Open,
           Tree     => S.File_Tree,
           Project  => S.Project,
           Registry => Editor.Buffers.Global_Registry_For_UI,
           Recent   => S.Recent_Buffers);
      Count : constant Natural := Natural (Snapshot.Candidates.Length);
      Current : Natural := 0;
      Target  : Natural := 0;
      Found   : Boolean := False;
   begin
      if Count = 0 then
         return;
      end if;

      for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
         if Snapshot.Candidates (I).Is_Selected then
            Current := I;
            exit;
         end if;
      end loop;

      if Current = 0 and then not Snapshot.Candidates (Snapshot.Candidates.First_Index).Is_Selected then
         Target := Snapshot.Candidates.First_Index;
      elsif Forward then
         if Current = Snapshot.Candidates.Last_Index then
            Target := Snapshot.Candidates.First_Index;
         else
            Target := Current + 1;
         end if;
      else
         if Current = Snapshot.Candidates.First_Index then
            Target := Snapshot.Candidates.Last_Index;
         else
            Target := Current - 1;
         end if;
      end if;

      Editor.Quick_Open.Select_Path
        (S.Quick_Open,
         To_String (Snapshot.Candidates (Target).Project_Relative_Path),
         Found);
   end Move_Quick_Open_Selection_By_Snapshot;


   procedure Execute_Quick_Open_Next_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
         elsif Quick_Open_File_Count (S) = 0 then
            Editor.Executor.Shared_Services.Report_Info (S, "No project files");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No Quick Open matches.");
         end if;
      else
         Move_Quick_Open_Selection_By_Snapshot (S, Forward => True);
         Editor.Executor.Shared_Services.Report_Info (S, "Selected next Quick Open candidate");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Next_Result;

   procedure Execute_Quick_Open_Previous_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
         elsif Quick_Open_File_Count (S) = 0 then
            Editor.Executor.Shared_Services.Report_Info (S, "No project files");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No Quick Open matches.");
         end if;
      else
         Move_Quick_Open_Selection_By_Snapshot (S, Forward => False);
         Editor.Executor.Shared_Services.Report_Info (S, "Selected previous Quick Open candidate");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Previous_Result;

   procedure Execute_Quick_Open_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Set_Query
        (S, Text);
   end Execute_Quick_Open_Set_Query;

   procedure Execute_Quick_Open_Clear_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Clear_Query
        (S);
   end Execute_Quick_Open_Clear_Query;


   procedure Execute_Quick_Open_Kind_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Kind_Next
        (S);
   end Execute_Quick_Open_Kind_Next;

   procedure Execute_Quick_Open_Kind_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Kind_Previous
        (S);
   end Execute_Quick_Open_Kind_Previous;

   procedure Execute_Quick_Open_Kind_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Kind_Clear
        (S);
   end Execute_Quick_Open_Kind_Clear;

   procedure Execute_Quick_Open_Scope_Set
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Quick_Open_Scope_Commands.Execute_Quick_Open_Scope_Set
        (S, Text);
   end Execute_Quick_Open_Scope_Set;

   procedure Execute_Quick_Open_Scope_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Scope_Commands.Execute_Quick_Open_Scope_Clear
        (S);
   end Execute_Quick_Open_Scope_Clear;

   procedure Execute_Quick_Open_Scope_From_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Scope_Commands.Execute_Quick_Open_Scope_From_Selected
        (S);
   end Execute_Quick_Open_Scope_From_Selected;

   procedure Execute_Quick_Open_Scope_Parent
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Scope_Commands.Execute_Quick_Open_Scope_Parent
        (S);
   end Execute_Quick_Open_Scope_Parent;
   procedure Execute_Quick_Open_Reveal_Active
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Context_Commands.Execute_Quick_Open_Reveal_Active (S);
   end Execute_Quick_Open_Reveal_Active;

   procedure Execute_Quick_Open_Scope_Active_Directory
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Context_Commands.Execute_Quick_Open_Scope_Active_Directory
        (S);
   end Execute_Quick_Open_Scope_Active_Directory;


   procedure Execute_Quick_Open_Create_From_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Create_Commands.Execute_Quick_Open_Create_From_Query
        (S);
   end Execute_Quick_Open_Create_From_Query;


   procedure Execute_Quick_Open_Create_With_Parents_From_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Create_Commands.Execute_Quick_Open_Create_With_Parents_From_Query
        (S);
   end Execute_Quick_Open_Create_With_Parents_From_Query;

   procedure Execute_Quick_Open_Priority_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Priority_Toggle
        (S);
   end Execute_Quick_Open_Priority_Toggle;


   procedure Execute_Quick_Open_Priority_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Priority_Clear
        (S);
   end Execute_Quick_Open_Priority_Clear;


   procedure Execute_Quick_Open_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Insert_Text
        (S, Text);
   end Execute_Quick_Open_Insert_Text;

   procedure Execute_Quick_Open_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Backspace
        (S);
   end Execute_Quick_Open_Backspace;

   procedure Execute_Quick_Open_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Delete_Forward
        (S);
   end Execute_Quick_Open_Delete_Forward;

   procedure Execute_Quick_Open_Move_Cursor_Left
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Move_Cursor_Left
        (S);
   end Execute_Quick_Open_Move_Cursor_Left;

   procedure Execute_Quick_Open_Move_Cursor_Right
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Quick_Open_Input_Commands.Execute_Quick_Open_Move_Cursor_Right
        (S);
   end Execute_Quick_Open_Move_Cursor_Right;

end Editor.Executor.Quick_Open_Commands;
