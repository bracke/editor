with Ada.Directories;
with Editor.Missing_Stale_Recovery.File_Lifecycle_Policies;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Project_Workspace_Policies is

   function Trim (Text : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Trim;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Exists (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Exists;

   function Is_Directory (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Directory;

   function Is_Inside_Project
     (Project_Root : String; Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Inside_Project;

   function Recent_Missing_Marker_Is_Snapshot_Derived return Boolean is
   begin
      return True;
   end Recent_Missing_Marker_Is_Snapshot_Derived;

   function Recent_Missing_Marker_May_Delete_Files return Boolean is
   begin
      return False;
   end Recent_Missing_Marker_May_Delete_Files;

   function Recent_Missing_Marker_May_Clear_Workspace return Boolean is
   begin
      return False;
   end Recent_Missing_Marker_May_Clear_Workspace;

   function File_Tree_Expanded_Path_Restore_State
     (Path : String) return Target_Availability_State
   is
   begin
      if Trim (Path)'Length = 0 or else not Exists (Path) then
         return Target_Missing;
      elsif not Is_Directory (Path) then
         return Target_Stale;
      else
         return Target_Available;
      end if;
   end File_Tree_Expanded_Path_Restore_State;

   function Validate_File_Tree_Node_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (File_Tree_Surface, Target_Outside_Project, Path);
      elsif not Exists (Path) then
         return Make (File_Tree_Surface, Target_Missing, Path);
      end if;
      Result := Make (File_Tree_Surface, Target_Available, Path);
      return Result;
   end Validate_File_Tree_Node_Target;

   function Validate_File_Tree_Mutation_Target
     (Kind         : File_Tree_Mutation_Kind;
      Path         : String;
      Project_Root : String := "";
      Parent_Path  : String := "") return Target_Validation_Result
   is
      Parent : constant String := (if Trim (Parent_Path)'Length > 0
                                   then Parent_Path
                                   else (if Trim (Path)'Length = 0
                                         then ""
                                         else Ada.Directories.Containing_Directory (Path)));
   begin
      case Kind is
         when File_Tree_Activate_Node
            | File_Tree_Rename_Node
            | File_Tree_Delete_Node =>
            return Validate_File_Tree_Node_Target (Path, Project_Root);

         when File_Tree_Create_File =>
            if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
               return Make (File_Tree_Surface, Target_Outside_Project, Path);
            elsif Trim (Parent)'Length = 0 or else not Is_Directory (Parent) then
               return Make (File_Tree_Surface, Target_Parent_Directory_Missing, Path);
            else
               return Make (File_Tree_Surface, Target_Available, Path);
            end if;
      end case;
   exception
      when others =>
         return Make (File_Tree_Surface, Target_Parent_Directory_Missing, Path);
   end Validate_File_Tree_Mutation_Target;

   function Workspace_Active_File_Fallback_Policy
     (Active_File_Missing      : Boolean;
      Reopened_File_Count      : Natural) return Workspace_Active_File_Fallback
   is
   begin
      if not Active_File_Missing then
         return Workspace_Use_Restored_Active_File;
      elsif Reopened_File_Count > 0 then
         return Workspace_Use_First_Reopened_File;
      else
         return Workspace_No_Active_File;
      end if;
   end Workspace_Active_File_Fallback_Policy;

   function Workspace_Active_File_Fallback_Label
     (Fallback : Workspace_Active_File_Fallback) return String
   is
   begin
      case Fallback is
         when Workspace_Use_Restored_Active_File =>
            return "restore requested active file";
         when Workspace_Use_First_Reopened_File =>
            return "fallback to first reopened file";
         when Workspace_No_Active_File =>
            return "no active file restored";
      end case;
   end Workspace_Active_File_Fallback_Label;

   function File_Tree_Mutation_Requires_Execution_Validation
     (Kind : File_Tree_Mutation_Kind) return Boolean
   is
      pragma Unreferenced (Kind);
   begin
      return True;
   end File_Tree_Mutation_Requires_Execution_Validation;

   function Project_Transition_Clears_Build_Transient
     (Field : Transient_Surface_Field) return Boolean
   is
   begin
      case Field is
         when Transient_Build_Candidates
            | Transient_Build_Request
            | Transient_Build_Consent
            | Transient_Build_Result
            | Transient_Build_Output =>
            return True;
         when others =>
            return False;
      end case;
   end Project_Transition_Clears_Build_Transient;

   function Validate_Project_Target
     (Project_Path : String;
      Require_Directory : Boolean := True) return Target_Validation_Result
   is
   begin
      if Trim (Project_Path)'Length = 0 or else not Exists (Project_Path) then
         return Make (Workspace_Surface, Target_Missing, Project_Path);
      elsif Require_Directory and then not Is_Directory (Project_Path) then
         return Make (Workspace_Surface, Target_Unreadable, Project_Path);
      else
         return Make (Workspace_Surface, Target_Available, Project_Path);
      end if;
   end Validate_Project_Target;

   function Validate_Workspace_Project_Target
     (Project_Path : String) return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_Project_Target (Project_Path);
   begin
      Result.Surface := Workspace_Surface;
      return Result;
   end Validate_Workspace_Project_Target;

   function Validate_Workspace_File_Target
     (Path : String) return Target_Validation_Result
   is
      Result : Target_Validation_Result :=
        Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_File_Target (Path);
   begin
      Result.Surface := Workspace_Surface;
      return Result;
   end Validate_Workspace_File_Target;

   function Validate_Recent_Project_Target
     (Project_Path : String) return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_Project_Target (Project_Path);
   begin
      Result.Surface := Recent_Project_Surface;
      return Result;
   end Validate_Recent_Project_Target;

end Editor.Missing_Stale_Recovery.Project_Workspace_Policies;
