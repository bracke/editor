with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
use type Editor.Buffers.Buffer_Ownership_Kind;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Command;
with Editor.Build_Working_Context;
with Editor.Clipboard;
with Editor.Command_Execution;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Executor.Pending_Transition_Policy;
use Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.External_Producers;
with Editor.Feature_Messages;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Scan_Status;
with Editor.Focus_Management;
with Editor.History;
with Editor.Message_Producers;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;
with Editor.Recent_Buffers;
with Editor.Recent_Projects;
use type Editor.Recent_Projects.Recent_Project_Status;
with Editor.Render_Cache;
with Editor.State;
with Editor.Terminal_Tasks;
with Editor.Workspace_Persistence;
use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

package body Editor.Executor.Project_Lifecycle_Commands is

   use Editor.Commands;

   function Project_Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;
   begin
      case Id is
         when Command_Open_Project =>
            return Editor.Commands.Available;

         when Command_Switch_Project =>
            return Editor.Commands.Unavailable ("No target project selected");

         when Command_Close_Project
            | Command_Clear_Project =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Command_Show_Recent_Projects =>
            return Editor.Commands.Available;

         when Command_Clear_Recent_Projects =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent projects");
            end if;
            return Editor.Commands.Available;

         when Command_Open_Selected_Recent_Project =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent project selected");
            else
               declare
                  Total : constant Natural :=
                    Editor.Recent_Projects.Count (S.Recent_Projects);
                  Selected : constant Positive :=
                    (if S.Recent_Project_Selected_Index in 1 .. Total
                     then Positive (S.Recent_Project_Selected_Index)
                     else 1);
                  Item : constant Editor.Recent_Projects.Recent_Project_Entry :=
                    Editor.Recent_Projects.Item (S.Recent_Projects, Selected);
               begin
                  if not Editor.Recent_Projects.Is_Available (Item) then
                     return Editor.Commands.Unavailable
                       ("Selected recent project is unavailable");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Remove_Selected_Recent_Project =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent project selected");
            end if;
            return Editor.Commands.Available;

         when Command_Remove_Missing_Recent_Projects =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent projects");
            end if;
            for Index in 1 .. Editor.Recent_Projects.Count (S.Recent_Projects) loop
               if not Editor.Recent_Projects.Is_Available
                 (Editor.Recent_Projects.Item (S.Recent_Projects, Index))
               then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable ("No unavailable recent projects");

         when Command_Select_Next_Recent_Project
            | Command_Select_Previous_Recent_Project =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent projects");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a project lifecycle command");
      end case;
   end Project_Lifecycle_Command_Availability;

   function Result_After_Command
     (S               : Editor.State.State_Type;
      Command         : Editor.Commands.Command_Id;
      Before_Messages : Natural)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      if Editor.Messages.Count (S.Messages) > Before_Messages then
         Msg := Editor.Messages.Active_Message (S.Messages, Found);
         if Found then
            if Editor.Messages.Severity (Msg) =
              Editor.Messages.Error_Message
            then
               return Editor.Command_Execution.Failed (Command);
            elsif Editor.Messages.Severity (Msg) =
              Editor.Messages.Warning_Message
            then
               return Editor.Command_Execution.Unavailable (Command);
            end if;
         end if;
      end if;

      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   type Retained_Recent_Buffer_Snapshot is array (Natural range <>) of
     Editor.Recent_Buffers.Buffer_Key;

   function Active_Buffer_Retained_Outside_Project
     (S : in out Editor.State.State_Type) return Boolean;

   procedure Rebase_Active_Retained_History_After_Project_Reset
     (S                    : in out Editor.State.State_Type;
      Old_Generation       : Natural;
      Was_Retained_Outside : Boolean);

   function Capture_Retained_Outside_Recent_Buffers
     (S : in out Editor.State.State_Type) return Retained_Recent_Buffer_Snapshot;

   procedure Restore_Retained_Outside_Recent_Buffers
     (S        : in out Editor.State.State_Type;
      Snapshot : Retained_Recent_Buffer_Snapshot);

   procedure Clear_Project_Transition_State
     (S : in out Editor.State.State_Type)
   is
      Retained_Recent : constant Retained_Recent_Buffer_Snapshot :=
        Capture_Retained_Outside_Recent_Buffers (S);
      Old_Generation : constant Natural := S.Lifecycle_Generation;
      Active_Was_Retained_Outside : constant Boolean :=
        Active_Buffer_Retained_Outside_Project (S);
   begin
      Editor.State.Reset_Project_Scoped_State (S);
      Restore_Retained_Outside_Recent_Buffers (S, Retained_Recent);
      Rebase_Active_Retained_History_After_Project_Reset
        (S, Old_Generation, Active_Was_Retained_Outside);
      Editor.Clipboard.Clear;
      --  completeness pass 8: project switch/open cleanup must not
      --  erase retained outside-project buffer undo/redo history.  Project-owned
      --  clean buffers are closed before switch, and project-scoped surfaces are
      --  reset here; global edit history belongs to surviving buffers.
      --  completeness pass 9: retained outside-project buffers also
      --  keep their recent-buffer ordering.  Reset_Project_Scoped_State clears
      --  the project-scoped switcher/recent-buffer projections; restore only
      --  surviving outside-project recent-buffer entries after the reset.
      S.Has_Reopen_Candidate := False;
      S.Reopen_Candidate_Path := Null_Unbounded_String;
      S.Reopen_Candidate_Label := Null_Unbounded_String;
   end Clear_Project_Transition_State;

   procedure Apply_Project_Open_Workspace_Policy
     (S      : in out Editor.State.State_Type;
      Config : Editor.Workspace_Persistence.Workspace_Lifecycle_Config :=
        Editor.Workspace_Persistence.Default_Workspace_Lifecycle_Config)
   is
      Status         : Editor.Workspace_Persistence.Workspace_Session_File_Status;
      Snapshot       : Editor.Workspace_Persistence.Workspace_Snapshot;
      Load_Status    : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary        : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         return;
      end if;

      Status := Editor.Workspace_Persistence.Session_File_Status
        (Editor.Project.Root_Path (S.Project));

      case Status is
         when Editor.Workspace_Persistence.Session_File_Missing =>
            return;
         when Editor.Workspace_Persistence.Session_File_Unreadable =>
            Report_Error (S, "Workspace could not be restored.");
            return;
         when Editor.Workspace_Persistence.Session_File_Present =>
            null;
      end case;

      if Config.Auto_Restore_On_Project_Open then
         Editor.Workspace_Persistence.Load_From_File
           (Editor.Workspace_Persistence.Session_File_Path
              (Editor.Project.Root_Path (S.Project)),
            Snapshot,
            Load_Status);

         case Load_Status is
            when Editor.Workspace_Persistence.Workspace_Persistence_Ok
               | Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore =>
               if Editor.Workspace_Persistence.Has_Project_Root (Snapshot)
                 and then Editor.Workspace_Persistence.Project_Root (Snapshot) /=
                   Editor.Project.Root_Path (S.Project)
               then
                  Report_Error (S, "Workspace could not be restored.");
                  return;
               end if;

               Restore_Workspace_Snapshot (S, Snapshot, Restore_Status, Summary);
               if Load_Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
               or else Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
               then
                  Mark_Restore_Summary_Current (S, Summary);
                  Report_Restore_Warning (S, Restore_Summary_Message (Summary, True));
               elsif Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok then
                  Mark_Restore_Summary_Current (S, Summary);
                  Report_Restore_Success (S, Restore_Summary_Message (Summary, False));
               else
                  Report_Workspace_Load_Status (S, Restore_Status);
               end if;
            when others =>
               Report_Workspace_Load_Status (S, Load_Status);
         end case;
      elsif Config.Report_Available_Session_On_Project_Open then
         Report_Info (S, "Workspace available. Run Restore Workspace.");
      end if;
   end Apply_Project_Open_Workspace_Policy;

   procedure Save_Recent_Projects_Best_Effort
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Editor.Recent_Projects.Save_To_File
        (S.Recent_Projects,
         Editor.Recent_Projects.Recent_Projects_File_Path,
         Status);
      if Status /= Editor.Recent_Projects.Recent_Project_Ok then
         Report_Warning (S, "Save recent projects failed");
      end if;
   end Save_Recent_Projects_Best_Effort;

   procedure Promote_Open_Project_To_Recent
     (S      : in out Editor.State.State_Type;
      Result : Editor.Project.Project_Open_Result)
   is
   begin
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects,
         To_String (Result.Root_Path),
         To_String (Result.Display_Name),
         Current_Message_Time_Ms,
         Editor.Recent_Projects.Default_Config);
      Save_Recent_Projects_Best_Effort (S);
   end Promote_Open_Project_To_Recent;

   function Selected_Recent_Project_Index
     (S : Editor.State.State_Type) return Natural
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
   begin
      if Total = 0 then
         return 0;
      elsif S.Recent_Project_Selected_Index in 1 .. Total then
         return S.Recent_Project_Selected_Index;
      else
         return 1;
      end if;
   end Selected_Recent_Project_Index;

   procedure Ensure_Recent_Project_Selection
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
   begin
      if Total = 0 then
         S.Recent_Project_Selected_Index := 0;
      elsif S.Recent_Project_Selected_Index not in 1 .. Total then
         S.Recent_Project_Selected_Index := 1;
      end if;
   end Ensure_Recent_Project_Selection;

   procedure Report_Selected_Recent_Project
     (S      : in out Editor.State.State_Type;
      Prefix : String)
   is
      Item : Editor.Recent_Projects.Recent_Project_Entry;
   begin
      if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
         Report_Info (S, "No recent projects");
         return;
      end if;

      Ensure_Recent_Project_Selection (S);
      Item := Editor.Recent_Projects.Item
        (S.Recent_Projects, Selected_Recent_Project_Index (S));
      Report_Info
        (S,
         Prefix & ": " & To_String (Item.Display_Name)
         & " — " & Editor.Recent_Projects.Path_Label (Item)
         & (if Editor.Recent_Projects.Is_Available (Item)
            then " — " & Editor.Recent_Projects.Last_Opened_Label (Item)
            else " — " & Editor.Recent_Projects.Unavailable_Label (Item)));
   end Report_Selected_Recent_Project;

   procedure Execute_Select_Next_Recent_Project
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
   begin
      if Total = 0 then
         Report_Info (S, "No recent projects");
         S.Recent_Project_Selected_Index := 0;
         return;
      end if;

      if S.Recent_Project_Selected_Index not in 1 .. Total then
         S.Recent_Project_Selected_Index := 1;
      elsif S.Recent_Project_Selected_Index >= Total then
         S.Recent_Project_Selected_Index := 1;
      else
         S.Recent_Project_Selected_Index := S.Recent_Project_Selected_Index + 1;
      end if;
      Report_Selected_Recent_Project (S, "Selected recent project");
   end Execute_Select_Next_Recent_Project;

   procedure Execute_Select_Previous_Recent_Project
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
   begin
      if Total = 0 then
         Report_Info (S, "No recent projects");
         S.Recent_Project_Selected_Index := 0;
         return;
      end if;

      if S.Recent_Project_Selected_Index not in 1 .. Total then
         S.Recent_Project_Selected_Index := Total;
      elsif S.Recent_Project_Selected_Index <= 1 then
         S.Recent_Project_Selected_Index := Total;
      else
         S.Recent_Project_Selected_Index := S.Recent_Project_Selected_Index - 1;
      end if;
      Report_Selected_Recent_Project (S, "Selected recent project");
   end Execute_Select_Previous_Recent_Project;

   procedure Execute_Show_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      use Ada.Strings.Unbounded;
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
      Summary : Unbounded_String := Null_Unbounded_String;
      Selected : Natural := 0;
   begin
      if Total = 0 then
         Report_Info (S, "No recent projects");
         return;
      end if;

      --  Rebuilding the user-facing Recent Projects projection is the safe
      --  boundary for path checks: render and command availability consume the
      --  cached marker, while this explicit command may refresh it without
      --  opening projects, creating directories, or touching other domains.
      Editor.Recent_Projects.Refresh_Availability (S.Recent_Projects);
      Ensure_Recent_Project_Selection (S);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Recent_Projects);
      Selected := Selected_Recent_Project_Index (S);
      --  Rows are projection-only and intentionally exclude workspace state.
      Append
        (Summary,
         "Recent projects: "
         & Ada.Strings.Fixed.Trim (Natural'Image (Total), Ada.Strings.Both));
      if Editor.Recent_Projects.Available_Count (S.Recent_Projects) = 0 then
         Append (Summary, "; No available recent projects");
         if Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects) > 0 then
            Append (Summary, "; project path no longer exists");
         end if;
      elsif Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects) > 0 then
         Append
           (Summary,
            "; unavailable: "
            & Ada.Strings.Fixed.Trim
              (Natural'Image
                 (Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects)),
               Ada.Strings.Both));
      end if;
      for Index in 1 .. Total loop
         declare
            Item : constant Editor.Recent_Projects.Recent_Project_Entry :=
              Editor.Recent_Projects.Item (S.Recent_Projects, Index);
         begin
            Append
              (Summary,
               "; " & Editor.Recent_Projects.Row_Label
                 (Item, Is_Selected => Index = Selected));
         end;
      end loop;

      Report_Info (S, To_String (Summary));
   end Execute_Show_Recent_Projects;

   procedure Execute_Open_Selected_Recent_Project
     (S : in out Editor.State.State_Type)
   is
      Item   : Editor.Recent_Projects.Recent_Project_Entry;
      Path   : Unbounded_String;
      Guard  : Editor.Dirty_Guards.Dirty_Transition_Result;
   begin
      if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
         Report_Info (S, "No recent project selected");
         return;
      end if;

      --  Opening is an explicit Recent Projects workflow boundary, so it may
      --  refresh the cached unavailable marker before validating the selected
      --  target.  This keeps later render/availability projections
      --  observational while ensuring a failed open leaves a truthful in-memory
      --  row marker.
      Editor.Recent_Projects.Refresh_Availability (S.Recent_Projects);
      Ensure_Recent_Project_Selection (S);
      Item := Editor.Recent_Projects.Item
        (S.Recent_Projects, Selected_Recent_Project_Index (S));
      Path := Item.Root_Path;

      if not Editor.Recent_Projects.Is_Available (Item) then
         Report_Warning (S, "Project path no longer exists");
         return;
      end if;

      Guard := Check_Dirty_Transition
        (S, Editor.Dirty_Guards.Open_Recent_Project_Transition);
      if not Editor.Dirty_Guards.Is_Allowed (Guard) then
         Set_Pending_Dirty_Transition
           (S,
            Pending_Target_For
              (Editor.Pending_Transitions.Pending_Open_Recent_Project,
               Path    => To_String (Path),
               Display => To_String (Item.Display_Name)),
            Guard);
         return;
      end if;

      Execute_Open_Project
        (S,
         To_String (Path),
         Refresh_Build_Candidates => True,
         Apply_Workspace_Policy => False,
         Recent_Project_Open => True);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
   exception
      when others =>
         Report_Error (S, "Could not open recent project");
   end Execute_Open_Selected_Recent_Project;

   procedure Execute_Clear_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Editor.Recent_Projects.Clear (S.Recent_Projects);
      S.Recent_Project_Selected_Index := 0;
      Invalidate_Pending_Transition_If_Stale (S);
      Editor.Recent_Projects.Save_To_File
        (S.Recent_Projects,
         Editor.Recent_Projects.Recent_Projects_File_Path,
         Status);
      if Status /= Editor.Recent_Projects.Recent_Project_Ok then
         Report_Warning (S, "Save recent projects failed");
      end if;
      Report_Info (S, "Cleared recent projects");
   end Execute_Clear_Recent_Projects;

   procedure Execute_Remove_Selected_Recent_Project
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
         Report_Info (S, "No recent project selected");
         return;
      end if;

      Ensure_Recent_Project_Selection (S);
      Editor.Recent_Projects.Remove_At
        (S.Recent_Projects, Selected_Recent_Project_Index (S));
      Ensure_Recent_Project_Selection (S);
      Invalidate_Pending_Transition_If_Stale (S);
      Save_Recent_Projects_Best_Effort (S);
      Report_Info (S, "Removed recent project");
   end Execute_Remove_Selected_Recent_Project;

   procedure Execute_Remove_Missing_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Removed : Natural := 0;
   begin
      Removed := Editor.Recent_Projects.Remove_Missing (S.Recent_Projects);
      if Removed = 0 then
         Report_Info (S, "No unavailable recent projects");
         return;
      end if;

      Ensure_Recent_Project_Selection (S);
      Invalidate_Pending_Transition_If_Stale (S);
      Save_Recent_Projects_Best_Effort (S);
      Report_Info
        (S,
         "Removed " & Ada.Strings.Fixed.Trim (Natural'Image (Removed), Ada.Strings.Both)
         & (if Removed = 1 then " unavailable recent project"
            else " unavailable recent projects"));
   end Execute_Remove_Missing_Recent_Projects;

   function Execute_Project_Lifecycle_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      case Id is
         when Command_Show_Recent_Projects =>
            Execute_Show_Recent_Projects (S);

         when Command_Clear_Recent_Projects =>
            Execute_Clear_Recent_Projects (S);

         when Command_Open_Selected_Recent_Project =>
            Execute_Open_Selected_Recent_Project (S);

         when Command_Remove_Selected_Recent_Project =>
            Execute_Remove_Selected_Recent_Project (S);

         when Command_Remove_Missing_Recent_Projects =>
            Execute_Remove_Missing_Recent_Projects (S);

         when Command_Select_Next_Recent_Project =>
            Execute_Select_Next_Recent_Project (S);

         when Command_Select_Previous_Recent_Project =>
            Execute_Select_Previous_Recent_Project (S);

         when others =>
            raise Program_Error with
              "unsupported project lifecycle result command";
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (S, Id, Before_Messages);
   end Execute_Project_Lifecycle_Result_Command;

   function Is_Project_Owned_Buffer
     (S  : Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id) return Boolean
   is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      if Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Contains (Registry, Id)
      then
         return False;
      end if;

      Metadata := Editor.Buffers.Metadata_For (Registry, S.Project, Id);
      return Metadata.Ownership = Editor.Buffers.Buffer_Project_Owned;
   end Is_Project_Owned_Buffer;

   function Project_Lifecycle_Set_Contains
     (Ids : Editor.Buffers.Buffer_Id_Vectors.Vector;
      Id  : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer or else Ids.Is_Empty then
         return False;
      end if;

      for Index in Ids.First_Index .. Ids.Last_Index loop
         if Ids.Element (Index) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Project_Lifecycle_Set_Contains;

   function Current_Project_Lifecycle_Buffer_Sets
     (S : in out Editor.State.State_Type)
      return Editor.Buffers.Buffer_Project_Lifecycle_Sets
   is
   begin
      if Editor.Buffers.Global_Count = 0 then
         return Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      return Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
   end Current_Project_Lifecycle_Buffer_Sets;

   function Project_Dirty_Buffer_Summary
     (S : Editor.State.State_Type)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
      Result : Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        Editor.Buffers.Global_Project_Lifecycle_Dirty_Buffer_Summary (S.Project);
   begin
      if Editor.Buffers.Global_Count = 0
        and then S.File_Info.Dirty
        and then S.File_Info.Has_Path
        and then Editor.Buffers.Classify_Buffer_Ownership
          (S.File_Info.Has_Path, To_String (S.File_Info.Path), S.Project)
            = Editor.Buffers.Buffer_Project_Owned
      then
         Result.Dirty_Count := 1;
         Result.File_Backed_Count := 1;
         Result.Untitled_Count := 0;
      end if;

      return Result;
   end Project_Dirty_Buffer_Summary;

   function Capture_Retained_Outside_Recent_Buffers
     (S : in out Editor.State.State_Type) return Retained_Recent_Buffer_Snapshot
   is
      Count    : constant Natural := Editor.Recent_Buffers.Count (S.Recent_Buffers);
      Snapshot : Retained_Recent_Buffer_Snapshot (1 .. Count) :=
        (others => Editor.Recent_Buffers.No_Buffer_Key);
      Sets     : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
        Current_Project_Lifecycle_Buffer_Sets (S);
   begin

      for Index in 1 .. Count loop
         declare
            Key : constant Editor.Recent_Buffers.Buffer_Key :=
              Editor.Recent_Buffers.Id_At (S.Recent_Buffers, Index);
            Id  : constant Editor.Buffers.Buffer_Id := Editor.Buffers.Buffer_Id (Key);
         begin
            if Key /= Editor.Recent_Buffers.No_Buffer_Key
              and then Editor.Buffers.Global_Contains (Id)
              and then Project_Lifecycle_Set_Contains
                (Sets.Project_Close_Unaffected, Id)
            then
               Snapshot (Index) := Key;
            end if;
         end;
      end loop;

      return Snapshot;
   end Capture_Retained_Outside_Recent_Buffers;

   procedure Restore_Retained_Outside_Recent_Buffers
     (S        : in out Editor.State.State_Type;
      Snapshot : Retained_Recent_Buffer_Snapshot)
   is
   begin
      for Index in reverse Snapshot'Range loop
         if Snapshot (Index) /= Editor.Recent_Buffers.No_Buffer_Key
           and then Editor.Buffers.Global_Contains
             (Editor.Buffers.Buffer_Id (Snapshot (Index)))
         then
            Editor.Recent_Buffers.Mark_Activated
              (S.Recent_Buffers,
               Snapshot (Index),
               Preserve_Traversal => True);
         end if;
      end loop;
      Editor.Recent_Buffers.Clear_Traversal (S.Recent_Buffers);
   end Restore_Retained_Outside_Recent_Buffers;

   function Active_Buffer_Retained_Outside_Project
     (S : in out Editor.State.State_Type) return Boolean
   is
      Active : constant Editor.Buffers.Buffer_Id :=
        Editor.Buffers.Global_Active_Buffer;
      Sets   : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
        Current_Project_Lifecycle_Buffer_Sets (S);
   begin
      return Project_Lifecycle_Set_Contains
        (Sets.Project_Close_Unaffected, Active);
   end Active_Buffer_Retained_Outside_Project;

   procedure Rebase_History_Lifecycle
     (Stack          : in out Editor.History.History_Vector.Vector;
      Buffer_Token   : Natural;
      Old_Generation : Natural;
      New_Generation : Natural)
   is
      Hist_Entry : Editor.History.History_Entry;
   begin
      if Stack.Is_Empty or else Old_Generation = New_Generation then
         return;
      end if;

      for Index in Stack.First_Index .. Stack.Last_Index loop
         Hist_Entry := Stack.Element (Index);
         if Hist_Entry.Owner_Buffer_Token = Buffer_Token
           and then Hist_Entry.Owner_Lifecycle_Generation = Old_Generation
         then
            Hist_Entry.Owner_Lifecycle_Generation := New_Generation;
            Stack.Replace_Element (Index, Hist_Entry);
         end if;
      end loop;
   end Rebase_History_Lifecycle;

   procedure Rebase_Active_Retained_History_After_Project_Reset
     (S                    : in out Editor.State.State_Type;
      Old_Generation       : Natural;
      Was_Retained_Outside : Boolean)
   is
      Active : constant Editor.Buffers.Buffer_Id :=
        Editor.Buffers.Global_Active_Buffer;
   begin
      if not Was_Retained_Outside
        or else Active = Editor.Buffers.No_Buffer
        or else S.Active_Buffer_Token /= Natural (Active)
      then
         return;
      end if;

      Rebase_History_Lifecycle
        (Editor.History.Undo_Stack,
         Natural (Active),
         Old_Generation,
         S.Lifecycle_Generation);
      Rebase_History_Lifecycle
        (Editor.History.Redo_Stack,
         Natural (Active),
         Old_Generation,
         S.Lifecycle_Generation);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Rebase_Active_Retained_History_After_Project_Reset;

   function Close_All_Clean_Buffers_For_Project_Close
     (S : in out Editor.State.State_Type) return Natural
   is
      Closed_Total : Natural := 0;
      Closed       : Boolean := False;
      Sets         : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
        Current_Project_Lifecycle_Buffer_Sets (S);
   begin
      --  fix 9: project close/switch cleanup consumes the same
      --  deterministic lifecycle set projection used by audits and review
      --  summaries.  The set is a transient review snapshot only; every
      --  target is revalidated immediately before mutation.
      if not Sets.Project_Owned_Clean.Is_Empty then
         for Index in Sets.Project_Owned_Clean.First_Index
           .. Sets.Project_Owned_Clean.Last_Index
         loop
            declare
               Id : constant Editor.Buffers.Buffer_Id :=
                 Sets.Project_Owned_Clean.Element (Index);
            begin
               if Id /= Editor.Buffers.No_Buffer
                 and then Editor.Buffers.Global_Contains (Id)
                 and then Is_Project_Owned_Buffer (S, Id)
                 and then not Editor.Buffers.Global_Summary_For (Id).Is_Dirty
               then
                  Editor.Buffers.Global_Close_Buffer (Id, Closed);
                  if Closed then
                     Closed_Total := Closed_Total + 1;
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Editor.Buffers.Global_Count = 0
        or else Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
      then
         S.Active_Buffer_Token := 0;
      else
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;
      return Closed_Total;
   end Close_All_Clean_Buffers_For_Project_Close;

   function Request_Build_Shutdown_For_Lifecycle
     (S      : in out Editor.State.State_Type;
      Reason : String) return Boolean;

   procedure Execute_Guarded_Close_Project
     (S : in out Editor.State.State_Type)
   is
      Guard  : Editor.Dirty_Guards.Dirty_Transition_Result;
      Root   : constant String :=
        (if Editor.Project.Has_Project (S.Project)
         then Editor.Project.Root_Path (S.Project)
         else "");
   begin

      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         if not Pending_Project_Close_Command_Matches (S) then
            Report_Warning (S, "Command unavailable while confirmation is pending");
            return;
         elsif not Pending_Transition_Is_Still_Valid (S) then
            Editor.Pending_Transitions.Clear (S.Pending_Transitions);
            Report_Warning
              (S, Editor.Dirty_Guards.Pending_Transition_No_Longer_Valid_Message);
            return;
         end if;
      end if;

      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         return;
      end if;

      if Request_Build_Shutdown_For_Lifecycle (S, "closing project") then
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Guard := Editor.Dirty_Guards.Guard_Transition
        (Editor.Dirty_Guards.Close_Project_Transition,
         Project_Dirty_Buffer_Summary (S));
      if not Editor.Dirty_Guards.Is_Allowed (Guard) then
         Set_Pending_Dirty_Transition
           (S,
            Pending_Target_For
              (Editor.Pending_Transitions.Pending_Close_Project,
               Path    => Root,
               Display => Editor.Project.Display_Name (S.Project)),
            Guard);
         return;
      end if;

      declare
         Retained_Recent : constant Retained_Recent_Buffer_Snapshot :=
           Capture_Retained_Outside_Recent_Buffers (S);
         Old_Generation : constant Natural := S.Lifecycle_Generation;
         Active_Was_Retained_Outside : constant Boolean :=
           Active_Buffer_Retained_Outside_Project (S);
         Closed : constant Natural := Close_All_Clean_Buffers_For_Project_Close (S);
         pragma Unreferenced (Closed);
      begin
         Editor.State.Reset_Project_Scoped_State (S);
         Restore_Retained_Outside_Recent_Buffers (S, Retained_Recent);
         Rebase_Active_Retained_History_After_Project_Reset
           (S, Old_Generation, Active_Was_Retained_Outside);
      end;
      declare
         Refresh_Result : constant Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result :=
           Editor.Build_Candidate_Refresh.Clear_Build_Candidates_After_Project_Close
             (S.Build_UI);
         pragma Unreferenced (Refresh_Result);
      begin
         null;
      end;
      Editor.Clipboard.Clear;
      --  completeness pass 8: closing a project retains outside-project
      --  buffers under the selected policy, so their undo/redo stacks must remain
      --  intact.  Navigation history is still project-scoped and is cleared below.
      Editor.Navigation_History.Clear (S.Navigation_History);
      Report_Info (S, "Project closed");
      Editor.Message_Producers.Post_Message
        (S,
         Editor.Feature_Messages.Info_Message,
         "Project closed",
         "project",
         Editor.Feature_Messages.Project_Source);
   end Execute_Guarded_Close_Project;

   procedure Populate_Project_Known_Files_From_File_Tree
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project.Clear_Known_Files (S.Project);
      for I in 1 .. Editor.File_Tree.File_Node_Count (S.File_Tree) loop
         declare
            Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.File_Node_At (S.File_Tree, I);
         begin
            if Node.Id /= Editor.File_Tree.No_File_Tree_Node then
               Editor.Project.Add_Known_File
                 (S.Project,
                  To_String (Node.Relative_Path),
                  To_String (Node.Absolute_Path));
            end if;
         end;
      end loop;
   end Populate_Project_Known_Files_From_File_Tree;


   function Request_Build_Shutdown_For_Lifecycle
     (S      : in out Editor.State.State_Type;
      Reason : String) return Boolean
   is
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      if not Editor.Build_Command.Has_Active_Public_Build_Job (S) then
         return False;
      end if;

      Result := Editor.Build_Command.Request_Public_Build_Lifecycle_Shutdown
        (S, Reason);
      Report_Info (S, To_String (Result.Command_Message));
      Editor.Render_Cache.Invalidate_All;
      return True;
   end Request_Build_Shutdown_For_Lifecycle;

   procedure Execute_Open_Project
     (S                        : in out Editor.State.State_Type;
      Path                     : String;
      Refresh_Build_Candidates : Boolean := True;
      Apply_Workspace_Policy   : Boolean := True;
      Recent_Project_Open      : Boolean := False;
      Explicit_Switch          : Boolean := False)
   is
      Old_Had_Project : constant Boolean := Editor.Project.Has_Project (S.Project);
      Old_Project_Root : constant String :=
        (if Old_Had_Project then Editor.Project.Root_Path (S.Project) else "");
      Guard : Editor.Dirty_Guards.Dirty_Transition_Result;
      Result : Editor.Project.Project_Open_Result;
      Tree        : Editor.File_Tree.File_Tree_State;
      Tree_Result : Editor.File_Tree.File_Tree_Scan_Result;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = ""
           and then
             (Editor.Buffers.Global_Count = 0
              or else
                (Editor.Buffers.Global_Count = 1
                 and then Editor.Buffers.Global_Active_Buffer /=
                   Editor.Buffers.No_Buffer));
      end Current_State_Is_Disposable_Initial_Untitled;
   begin

      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         if not Pending_Project_Open_Command_Matches
           (S, Path, Recent_Project_Open, Explicit_Switch)
         then
            Report_Warning (S, "Command unavailable while confirmation is pending");
            return;
         elsif not Pending_Transition_Is_Still_Valid (S) then
            Editor.Pending_Transitions.Clear (S.Pending_Transitions);
            Report_Warning
              (S, Editor.Dirty_Guards.Pending_Transition_No_Longer_Valid_Message);
            return;
         end if;
      end if;

      if Request_Build_Shutdown_For_Lifecycle
        (S, (if Explicit_Switch then "switching project"
             elsif Recent_Project_Open then "opening recent project"
             else "opening project"))
      then
         return;
      end if;

      if Explicit_Switch then
         --  completeness pass 10: project.switch is not project.open.
         --  A structured switch payload without an active source project must
         --  not fabricate an open-project transition, update Recent Projects,
         --  or clear project-scoped state.  Use project.open for first open.
         if not Old_Had_Project then
            Report_Info (S, "No project open");
            return;
         end if;

         --  completeness pass 6: switching to the already-active
         --  project is a pure no-op even if the project directory has become
         --  temporarily unreadable.  It must be detected before target-open or
         --  File Tree preflight so the command cannot become a destructive
         --  validation path for the current project context.
         if Old_Had_Project
           and then Editor.Recent_Projects.Normalized_Root_Path
             (Old_Project_Root) = Editor.Recent_Projects.Normalized_Root_Path
               (Path)
         then
            Report_Info (S, "Project already open");
            Editor.Message_Producers.Post_Message
              (S,
               Editor.Feature_Messages.Info_Message,
               "Project already open",
               Editor.Project.Display_Name (S.Project),
               Editor.Feature_Messages.Project_Source);
            return;
         end if;

         Result := Editor.Project.Open_Project (Path);
         if not Editor.Project.Is_Success (Result) then
            Report_Error (S, "Target project unavailable");
            Editor.Message_Producers.Post_Message
              (S,
               Editor.Feature_Messages.Error_Message,
               "Could not switch project — " & Path,
               Path,
               Editor.Feature_Messages.Project_Source);
            return;
         end if;

         --  completeness: an explicit switch must validate the
         --  target project tree before any current project or surface state is
         --  reset.  A missing/unreadable target is therefore a failed
         --  transition, not a partial transition with an empty File Tree.
         Tree := Editor.File_Tree.Scan_Project (To_String (Result.Root_Path));
         Tree_Result := Editor.File_Tree.Scan_Status (Tree);
         if Tree_Result.Status /= Editor.File_Tree.File_Tree_Scan_Ok then
            Report_Error (S, "Target project unavailable");
            Editor.Message_Producers.Post_Message
              (S,
               Editor.Feature_Messages.Error_Message,
               "Could not switch project — " & Path,
               File_Tree_Status_Message (Tree_Result),
               Editor.Feature_Messages.Project_Source);
            return;
         end if;

      end if;

      if not Current_State_Is_Disposable_Initial_Untitled then
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;
      if Explicit_Switch then
         Guard := Editor.Dirty_Guards.Guard_Transition
           (Editor.Dirty_Guards.Switch_Project_Transition,
            Project_Dirty_Buffer_Summary (S));
      else
         Guard := Check_Dirty_Transition
           (S,
            (if Recent_Project_Open then Editor.Dirty_Guards.Open_Recent_Project_Transition
             else Editor.Dirty_Guards.Open_Project_Transition));
      end if;
      if not Editor.Dirty_Guards.Is_Allowed (Guard) then
         Set_Pending_Dirty_Transition
           (S,
            Pending_Target_For
              ((if Recent_Project_Open then Editor.Pending_Transitions.Pending_Open_Recent_Project
                elsif Explicit_Switch then Editor.Pending_Transitions.Pending_Switch_Project
                else Editor.Pending_Transitions.Pending_Open_Project),
               Path    => Path,
               Display => Path),
            Guard);
         return;
      end if;

      if not Explicit_Switch then
         Result := Editor.Project.Open_Project (Path);
      end if;
      --  Project opening remains non-destructive for buffers, the active
      --  buffer, dirty state, tab order, and history.  Project-scoped transient
      --  search, quick-open, file-tree, and panel view state is cleared before
      --  the new project tree is installed.
      if Editor.Project.Is_Success (Result) then
         Clear_Restore_Feedback_Current (S);
         if Explicit_Switch and then Old_Had_Project then
            declare
               Closed : constant Natural := Close_All_Clean_Buffers_For_Project_Close (S);
               pragma Unreferenced (Closed);
            begin
               null;
            end;
         end if;

         Editor.Pending_Transitions.Clear (S.Pending_Transitions);
         Clear_Project_Transition_State (S);
         Editor.Clipboard.Clear;
         Editor.Project.Apply_Open_Result (S.Project, Result);
         Editor.Terminal_Tasks.Ensure_Project_Default_Tasks
           (S.Terminal_Tasks, Editor.Project.Root_Path (S.Project));
         if Refresh_Build_Candidates then
            declare
               Context : constant Editor.Build_Working_Context.Build_Working_Context_Record :=
                 Editor.Build_Working_Context.Current_Project_Root
                   (Editor.Project.Root_Path (S.Project));
               Is_Switch : constant Boolean :=
                 Old_Had_Project and then Old_Project_Root /= Editor.Project.Root_Path (S.Project);
               Refresh_Result : constant Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result :=
                 (if Is_Switch then
                    Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Switch
                      (S.Build_UI, Context, True)
                  else
                    Editor.Build_Candidate_Refresh.Refresh_Build_Candidates_After_Project_Open
                      (S.Build_UI, Context, True));
               pragma Unreferenced (Refresh_Result);
            begin
               null;
            end;
         end if;
         Promote_Open_Project_To_Recent (S, Result);
         Editor.Project_Search.Clear (S.Project_Search);
         if Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
           or else Editor.Overlay_Focus.Is_Active
             (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
         then
            Dismiss_Active_Overlay
              (S, Editor.Overlay_Focus.Dismiss_Command);
         else
            Editor.Quick_Open.Close (S.Quick_Open);
            Editor.Project_Search_Bar.Close (S.Project_Search_Bar);
         end if;
         if not Explicit_Switch then
            Tree := Editor.File_Tree.Scan_Project (Editor.Project.Root_Path (S.Project));
            Tree_Result := Editor.File_Tree.Scan_Status (Tree);
         end if;
         if Tree_Result.Status = Editor.File_Tree.File_Tree_Scan_Ok then
            S.File_Tree := Tree;
            Populate_Project_Known_Files_From_File_Tree (S);
            Rebuild_Language_Index_After_File_Lifecycle (S);
            Validate_File_Tree_View (S);
            Editor.Project_Search.Clear (S.Project_Search);
            if Editor.Quick_Open.Is_Open (S.Quick_Open) then
               Recompute_Quick_Open (S);
            end if;
            Report_Success
              (S,
               (if Recent_Project_Open then "Recent project opened"
                elsif Explicit_Switch then "Project switched"
                else "Opened project " & To_String (Result.Display_Name)));
            Editor.Message_Producers.Post_Message
              (S,
               Editor.Feature_Messages.Info_Message,
               (if Recent_Project_Open then "Recent project opened"
                elsif Explicit_Switch then "Project switched"
                else "Opened project " & To_String (Result.Display_Name)),
               To_String (Result.Display_Name),
               Editor.Feature_Messages.Project_Source);
            if Apply_Workspace_Policy then
               Apply_Project_Open_Workspace_Policy (S);
            end if;
         else
            Editor.File_Tree.Clear (S.File_Tree);
            Editor.Project.Clear_Known_Files (S.Project);
            Editor.File_Tree_View.Clear_View (S.File_Tree_View);
            Editor.Project_Search.Clear (S.Project_Search);
            if Editor.Quick_Open.Is_Open (S.Quick_Open) then
               Recompute_Quick_Open (S);
            end if;
            Report_Warning
              (S,
               (if Explicit_Switch then "Project switched"
                else "Opened project " & To_String (Result.Display_Name))
               & "; file tree refresh failed: "
               & File_Tree_Status_Message (Tree_Result));
            if Apply_Workspace_Policy then
               Apply_Project_Open_Workspace_Policy (S);
            end if;
         end if;
      else
         Report_Error
           (S,
            (if Recent_Project_Open then "Could not open recent project"
             elsif Explicit_Switch then "Could not switch project: " & Editor.Project.Status_Message (Result)
             else "Open project failed: " & Editor.Project.Status_Message (Result)));
         Editor.Message_Producers.Post_Message
           (S,
            Editor.Feature_Messages.Error_Message,
            (if Recent_Project_Open then "Could not open recent project — " & Path
             elsif Explicit_Switch then "Could not switch project — " & Path
             else "Could not open project — " & Path),
            Path,
            Editor.Feature_Messages.Project_Source);
      end if;
   end Execute_Open_Project;

   procedure Execute_Project_Lifecycle_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
   begin
      case Cmd.Kind is
         when Open_Project =>
            if Length (Cmd.Path) = 0 then
               Report_Info (S, "Open Project requires a path");
            else
               Execute_Open_Project (S, To_String (Cmd.Path));
            end if;

         when Switch_Project =>
            if Length (Cmd.Path) = 0 then
               Report_Info (S, "Switch Project requires a target project");
            else
               Execute_Open_Project
                 (S,
                  To_String (Cmd.Path),
                  Refresh_Build_Candidates => True,
                  Apply_Workspace_Policy => False,
                  Explicit_Switch => True);
            end if;

         when Show_Recent_Projects =>
            Execute_Show_Recent_Projects (S);

         when Open_Selected_Recent_Project =>
            Execute_Open_Selected_Recent_Project (S);

         when Clear_Recent_Projects =>
            Execute_Clear_Recent_Projects (S);

         when Remove_Selected_Recent_Project =>
            Execute_Remove_Selected_Recent_Project (S);

         when Remove_Missing_Recent_Projects =>
            Execute_Remove_Missing_Recent_Projects (S);

         when Select_Next_Recent_Project =>
            Execute_Select_Next_Recent_Project (S);

         when Select_Previous_Recent_Project =>
            Execute_Select_Previous_Recent_Project (S);

         when Close_Project | Clear_Project =>
            Execute_Guarded_Close_Project (S);

         when others =>
            raise Program_Error with "unsupported project lifecycle command kind";
      end case;
   end Execute_Project_Lifecycle_Kind;

end Editor.Executor.Project_Lifecycle_Commands;
