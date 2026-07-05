with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Dirty_Guards;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Shared_Services;
with Editor.Files;
with Editor.File_Tree;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.State;
with Editor.Workspace_Persistence;

package body Editor.Executor.Pending_Transition_Policy is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;

   function Check_Dirty_Transition
     (State : Editor.State.State_Type;
      Kind  : Editor.Dirty_Guards.Dirty_Transition_Kind)
      return Editor.Dirty_Guards.Dirty_Transition_Result
   is
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        Editor.Buffers.Global_Categorized_Dirty_Buffer_Summary (State.Project);
   begin
      if Editor.Buffers.Global_Count = 0 then
         Summary :=
           (Dirty_Count       => (if State.File_Info.Dirty then 1 else 0),
            Untitled_Count    =>
              (if State.File_Info.Dirty and then not State.File_Info.Has_Path
               then 1 else 0),
            File_Backed_Count =>
              (if State.File_Info.Dirty and then State.File_Info.Has_Path
               then 1 else 0));
      end if;

      return Editor.Dirty_Guards.Guard_Transition (Kind, Summary);
   end Check_Dirty_Transition;

   procedure Report_Dirty_Block
     (S      : in out Editor.State.State_Type;
      Result : Editor.Dirty_Guards.Dirty_Transition_Result)
   is
   begin
      Editor.Executor.Shared_Services.Report_Warning_Raw (S, Editor.Dirty_Guards.Reason (Result));
   end Report_Dirty_Block;



   function Pending_Target_For
     (Kind      : Editor.Pending_Transitions.Pending_Transition_Kind;
      Path      : String := "";
      Display   : String := "";
      Buffer_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer)
      return Editor.Pending_Transitions.Pending_Transition_Target
   is
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Normalized : Unbounded_String := Null_Unbounded_String;
   begin
      Target.Kind := Kind;
      if Path'Length > 0 then
         declare
            Canonical : constant String :=
              Editor.Recent_Projects.Normalized_Root_Path (Path);
         begin
            if Canonical'Length > 0 then
               Normalized := To_Unbounded_String (Canonical);
            else
               Normalized := To_Unbounded_String (Path);
            end if;
         end;
         Target.Path := Normalized;
         Target.Has_Path := True;
      end if;
      if Display'Length > 0 then
         Target.Display := To_Unbounded_String (Display);
      end if;
      if Buffer_Id /= Editor.Buffers.No_Buffer then
         Target.Buffer_Id := Natural (Buffer_Id);
         Target.Has_Buffer := True;
      end if;
      return Target;
   end Pending_Target_For;

   procedure Set_Pending_Dirty_Transition
     (S      : in out Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Guard  : Editor.Dirty_Guards.Dirty_Transition_Result)
   is
      Captured_Target : Editor.Pending_Transitions.Pending_Transition_Target := Target;
   begin
      --  a dirty lifecycle command may create one transient
      --  confirmation payload, but a later conflicting lifecycle command must
      --  not overwrite that payload.  The user must explicitly cancel or retry
      --  the pending operation first.

      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      --  completeness: dirty reload/revert confirmations are
      --  destructive file reads.  Capture the command-boundary disk state
      --  that the user is being asked to accept, so retry can reject the
      --  prompt if the backing file changes again before confirmation.
      if Captured_Target.Kind in Editor.Pending_Transitions.Pending_Reload_Active_Buffer
          | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
        and then Captured_Target.Has_Path
      then
         declare
            Status : constant Editor.Files.File_External_Change_Status :=
              Editor.Executor.File_Lifecycle_Commands.Active_File_External_Status (S);
            Found  : Boolean := False;
            Label  : constant String :=
              Editor.Files.Current_Token_Label
                (To_String (Captured_Target.Path), Found);
         begin
            Captured_Target.Observed_File_Status_Code :=
              Editor.Executor.File_Lifecycle_Commands.External_Status_Code (Status);
            Captured_Target.Has_Observed_File_Status := True;
            if Found then
               Captured_Target.Observed_File_Token_Label :=
                 To_Unbounded_String (Label);
               Captured_Target.Has_Observed_File_Token := True;
            end if;
         end;
      end if;

      --  completeness: project switch/close confirmations must be
      --  bound to the project context that produced them.  If another route
      --  changes the active project before retry, the stale confirmation is
      --  rejected rather than closing/switching a different project.
      if Captured_Target.Kind in Editor.Pending_Transitions.Pending_Switch_Project
          | Editor.Pending_Transitions.Pending_Close_Project
          | Editor.Pending_Transitions.Pending_Clear_Project
          | Editor.Pending_Transitions.Pending_Clear_Workspace_State
        and then Editor.Project.Has_Project (S.Project)
      then
         Captured_Target.Source_Path :=
           To_Unbounded_String
             (Editor.Recent_Projects.Normalized_Root_Path
                (Editor.Project.Root_Path (S.Project)));
         Captured_Target.Has_Source_Path := True;
      end if;

      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Captured_Target, Guard.Summary);
      Report_Dirty_Block (S, Guard);
   end Set_Pending_Dirty_Transition;

   function Recent_Project_List_Contains
     (S    : Editor.State.State_Type;
      Path : String) return Boolean
   is
      Normalized : constant String :=
        Editor.Recent_Projects.Normalized_Root_Path (Path);
   begin
      if Normalized'Length = 0 then
         return False;
      end if;

      for Index in 1 .. Editor.Recent_Projects.Count (S.Recent_Projects) loop
         declare
            Item : constant Editor.Recent_Projects.Recent_Project_Entry :=
              Editor.Recent_Projects.Item (S.Recent_Projects, Index);
         begin
            if Editor.Recent_Projects.Normalized_Root_Path
                 (To_String (Item.Root_Path)) = Normalized
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Recent_Project_List_Contains;

   function Project_Switch_Target_Is_Usable
     (Path : String) return Boolean
   is
      Result      : constant Editor.Project.Project_Open_Result :=
        Editor.Project.Open_Project (Path);
      Tree        : Editor.File_Tree.File_Tree_State;
      Tree_Result : Editor.File_Tree.File_Tree_Scan_Result;
   begin
      if not Editor.Project.Is_Success (Result) then
         return False;
      end if;

      --  completeness: pending switch retry must apply the same
      --  target-tree preflight as the first switch attempt.  A target that is
      --  still a directory but no longer scannable is stale/unusable and must
      --  not survive into the mutating switch path.
      Tree := Editor.File_Tree.Scan_Project (To_String (Result.Root_Path));
      Tree_Result := Editor.File_Tree.Scan_Status (Tree);
      return Tree_Result.Status = Editor.File_Tree.File_Tree_Scan_Ok;
   end Project_Switch_Target_Is_Usable;

   function Pending_Target_Is_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target) return Boolean
   is
      Path : constant String := To_String (Target.Path);
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return False;
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return Target.Has_Buffer
              and then Editor.Buffers.Global_Contains
                (Editor.Buffers.Buffer_Id (Target.Buffer_Id));
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer
            | Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            if not Target.Has_Buffer
              or else not Editor.Buffers.Global_Contains
                (Editor.Buffers.Buffer_Id (Target.Buffer_Id))
            then
               return False;
            end if;

            declare
               Buffer_State : constant Editor.State.State_Type :=
                 Editor.Buffers.Buffer
                   (Editor.Buffers.Global_Registry_For_UI,
                    Editor.Buffers.Buffer_Id (Target.Buffer_Id));
            begin
               --  completeness: dirty reload/revert confirmations
               --  are bound to the buffer association that produced the
               --  prompt.  A later Save As, file association change, or
               --  dirty resolution must make the transient confirmation stale
               --  rather than reloading/reverting a different backing file.
               if Target.Has_Path then
                  return Buffer_State.File_Info.Has_Path
                    and then Editor.Recent_Projects.Normalized_Root_Path
                      (To_String (Buffer_State.File_Info.Path)) =
                        To_String (Target.Path)
                    and then Buffer_State.File_Info.Dirty
                    and then Editor.Executor.File_Lifecycle_Commands.Pending_File_State_Still_Current (Target);
               else
                  return Buffer_State.File_Info.Has_Path
                    and then Buffer_State.File_Info.Dirty
                    and then Editor.Executor.File_Lifecycle_Commands.Pending_File_State_Still_Current (Target);
               end if;
            end;
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            return Editor.Buffers.Global_Count > 0;
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return Target.Has_Buffer
              and then Editor.Buffers.Global_Contains
                (Editor.Buffers.Buffer_Id (Target.Buffer_Id));
         when Editor.Pending_Transitions.Pending_Open_Project =>
            return Target.Has_Path
              and then Path'Length > 0
              and then Editor.Project.Is_Success
                (Editor.Project.Open_Project (Path));
         when Editor.Pending_Transitions.Pending_Switch_Project =>
            return Target.Has_Path
              and then Path'Length > 0
              and then (not Target.Has_Source_Path
                or else (Editor.Project.Has_Project (S.Project)
                  and then Editor.Recent_Projects.Normalized_Root_Path
                    (Editor.Project.Root_Path (S.Project)) =
                      To_String (Target.Source_Path)))
              and then Project_Switch_Target_Is_Usable (Path);
         when Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return Target.Has_Path
              and then Path'Length > 0
              and then Recent_Project_List_Contains (S, Path)
              and then Editor.Project.Is_Success
                (Editor.Project.Open_Project (Path));
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return Target.Has_Path
              and then Path'Length > 0
              and then Editor.Project.Has_Project (S.Project)
              and then Editor.Recent_Projects.Normalized_Root_Path
                (Editor.Project.Root_Path (S.Project)) =
                  Editor.Recent_Projects.Normalized_Root_Path (Path)
              and then Ada.Directories.Exists
               (Editor.Workspace_Persistence.Session_File_Path (Path));
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return Target.Has_Path
              and then Path'Length > 0
              and then Editor.Project.Has_Project (S.Project)
              and then (not Target.Has_Source_Path
                or else Editor.Recent_Projects.Normalized_Root_Path
                  (Editor.Project.Root_Path (S.Project)) =
                    To_String (Target.Source_Path))
              and then Editor.Recent_Projects.Normalized_Root_Path
                (Editor.Project.Root_Path (S.Project)) =
                  Editor.Recent_Projects.Normalized_Root_Path (Path)
              and then Ada.Directories.Exists
                (Editor.Workspace_Persistence.Session_File_Path (Path));
         when Editor.Pending_Transitions.Pending_Close_Project
            | Editor.Pending_Transitions.Pending_Clear_Project =>
            if not Editor.Project.Has_Project (S.Project) then
               return False;
            elsif Target.Has_Source_Path then
               return Editor.Recent_Projects.Normalized_Root_Path
                   (Editor.Project.Root_Path (S.Project)) = To_String (Target.Source_Path);
            elsif Target.Has_Path then
               return Editor.Recent_Projects.Normalized_Root_Path
                   (Editor.Project.Root_Path (S.Project)) =
                 Editor.Recent_Projects.Normalized_Root_Path (Path);
            else
               return True;
            end if;
      end case;
   end Pending_Target_Is_Valid;

   function Pending_Transition_Is_Still_Valid
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Pending_Transitions.Has_Pending (State.Pending_Transitions)
        and then Pending_Target_Is_Valid
          (State, Editor.Pending_Transitions.Target (State.Pending_Transitions));
   end Pending_Transition_Is_Still_Valid;

   function Same_Pending_Project_Path
     (Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Path   : String) return Boolean
   is
   begin
      return Target.Has_Path
        and then Editor.Recent_Projects.Normalized_Root_Path
          (To_String (Target.Path)) = Editor.Recent_Projects.Normalized_Root_Path (Path);
   end Same_Pending_Project_Path;

   function Pending_Project_Open_Command_Matches
     (S                   : Editor.State.State_Type;
      Path                : String;
      Recent_Project_Open : Boolean;
      Explicit_Switch     : Boolean) return Boolean
   is
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        Editor.Pending_Transitions.Target (S.Pending_Transitions);
   begin
      if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         return True;
      end if;

      if Explicit_Switch then
         return Target.Kind = Editor.Pending_Transitions.Pending_Switch_Project
           and then Same_Pending_Project_Path (Target, Path);
      elsif Recent_Project_Open then
         return Target.Kind = Editor.Pending_Transitions.Pending_Open_Recent_Project
           and then Same_Pending_Project_Path (Target, Path);
      else
         return Target.Kind = Editor.Pending_Transitions.Pending_Open_Project
           and then Same_Pending_Project_Path (Target, Path);
      end if;
   end Pending_Project_Open_Command_Matches;

   function Pending_Project_Close_Command_Matches
     (S : Editor.State.State_Type) return Boolean
   is
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        Editor.Pending_Transitions.Target (S.Pending_Transitions);
   begin
      return not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions)
        or else Target.Kind in Editor.Pending_Transitions.Pending_Close_Project
          | Editor.Pending_Transitions.Pending_Clear_Project;
   end Pending_Project_Close_Command_Matches;

   procedure Invalidate_Pending_Transition_If_Stale
     (State : in out Editor.State.State_Type)
   is
   begin
      if Editor.Pending_Transitions.Has_Pending (State.Pending_Transitions)
        and then not Pending_Transition_Is_Still_Valid (State)
      then
         Editor.Pending_Transitions.Clear (State.Pending_Transitions);
      end if;
   end Invalidate_Pending_Transition_If_Stale;

   function Guard_For_Pending_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Editor.Dirty_Guards.Dirty_Transition_Kind
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Close_Buffer
            | Editor.Pending_Transitions.Pending_Reload_Active_Buffer
            | Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return Editor.Dirty_Guards.Close_Buffer_Transition;
         when Editor.Pending_Transitions.Pending_Close_All_Buffers
            | Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return Editor.Dirty_Guards.Close_All_Buffers_Transition;
         when Editor.Pending_Transitions.Pending_Open_Project =>
            return Editor.Dirty_Guards.Open_Project_Transition;
         when Editor.Pending_Transitions.Pending_Switch_Project =>
            return Editor.Dirty_Guards.Switch_Project_Transition;
         when Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return Editor.Dirty_Guards.Open_Recent_Project_Transition;
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return Editor.Dirty_Guards.Restore_Workspace_Transition;
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return Editor.Dirty_Guards.Clear_Project_Transition;
         when Editor.Pending_Transitions.Pending_Close_Project =>
            return Editor.Dirty_Guards.Close_Project_Transition;
         when Editor.Pending_Transitions.Pending_Clear_Project
            | Editor.Pending_Transitions.No_Pending_Transition =>
            return Editor.Dirty_Guards.Clear_Project_Transition;
      end case;
   end Guard_For_Pending_Target;

   function Pending_Close_Buffer_Guard
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Editor.Dirty_Guards.Dirty_Transition_Result
   is
      Buffer_State : Editor.State.State_Type;
      Summary      : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   begin
      if not Target.Has_Buffer
        or else not Editor.Buffers.Global_Contains
          (Editor.Buffers.Buffer_Id (Target.Buffer_Id))
      then
         return Editor.Dirty_Guards.Allowed
           ((Dirty_Count       => 0,
             Untitled_Count    => 0,
             File_Backed_Count => 0));
      end if;

      Buffer_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI,
         Editor.Buffers.Buffer_Id (Target.Buffer_Id));

      Summary :=
        (Dirty_Count       => (if Buffer_State.File_Info.Dirty then 1 else 0),
         Untitled_Count    =>
           (if Buffer_State.File_Info.Dirty
             and then not Buffer_State.File_Info.Has_Path
            then 1 else 0),
         File_Backed_Count =>
           (if Buffer_State.File_Info.Dirty
             and then Buffer_State.File_Info.Has_Path
            then 1 else 0));

      return Editor.Dirty_Guards.Guard_Transition
        (Editor.Dirty_Guards.Close_Buffer_Transition, Summary);
   end Pending_Close_Buffer_Guard;

   function Check_Pending_Transition
     (S      : Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Editor.Dirty_Guards.Dirty_Transition_Result
   is
   begin
      if Target.Kind = Editor.Pending_Transitions.Pending_Close_Buffer then
         return Pending_Close_Buffer_Guard (Target);
      end if;

      if Target.Kind = Editor.Pending_Transitions.Pending_Clear_Workspace_State then
         return Editor.Dirty_Guards.Allowed
           ((Dirty_Count       => 0,
             Untitled_Count    => 0,
             File_Backed_Count => 0));
      end if;

      --  completeness: switch/close retry must re-check the same
      --  project-owned dirty-buffer scope that created the pending
      --  confirmation.  Outside-project dirty buffers are retained across
      --  project switch/close and must not keep a resolved project transition
      --  blocked on retry.
      if Target.Kind in Editor.Pending_Transitions.Pending_Switch_Project
          | Editor.Pending_Transitions.Pending_Close_Project
          | Editor.Pending_Transitions.Pending_Clear_Project
      then
         return Editor.Dirty_Guards.Guard_Transition
           (Guard_For_Pending_Target (Target),
            Editor.Executor.Project_Lifecycle_Commands.Project_Dirty_Buffer_Summary (S));
      end if;

      return Check_Dirty_Transition (S, Guard_For_Pending_Target (Target));
   end Check_Pending_Transition;


end Editor.Executor.Pending_Transition_Policy;
