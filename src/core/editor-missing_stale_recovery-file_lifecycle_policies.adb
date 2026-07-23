with Ada.Directories;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.File_Lifecycle_Policies is

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

   function Is_Ordinary_File (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Ordinary_File;

   function Is_Inside_Project
     (Project_Root : String; Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Inside_Project;

   function Workspace_Load_May_Restore_Unsaved_Text return Boolean is
   begin
      return False;
   end Workspace_Load_May_Restore_Unsaved_Text;

   function Project_Transition_May_Discard_Dirty_Buffer return Boolean is
   begin
      return False;
   end Project_Transition_May_Discard_Dirty_Buffer;

   function Recovery_Command_Requires_Dirty_Guard
     (Command : Recovery_Command_Kind) return Boolean
   is
   begin
      return Command in Recovery_Workspace_Load
        | Recovery_File_Reload_From_Disk
        | Recovery_File_Revert_Buffer;
   end Recovery_Command_Requires_Dirty_Guard;

   function Buffer_Known_Missing_State_Allowed
     (Dirty : Boolean; State : Target_Availability_State) return Boolean
   is
   begin
      if Dirty then
         return State in Target_Missing
           | Target_Parent_Directory_Missing
           | Target_Unreadable
           | Target_Unwritable
           | Target_Reload_Required;
      else
         return State in Target_Missing
           | Target_Unreadable
           | Target_Reload_Required
           | Target_Available;
      end if;
   end Buffer_Known_Missing_State_Allowed;

   function Validate_Buffer_Access_State
     (Path           : String;
      Target_Exists  : Boolean;
      Ordinary_File  : Boolean;
      Readable       : Boolean;
      Writable       : Boolean;
      Require_Read   : Boolean := False;
      Require_Write  : Boolean := False) return Target_Validation_Result
   is
   begin
      if Trim (Path)'Length = 0 or else not Target_Exists then
         return Make (Buffer_Surface, Target_Missing, Path);
      elsif not Ordinary_File then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Read and then not Readable then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Write and then not Writable then
         return Make (Buffer_Surface, Target_Unwritable, Path);
      else
         return Make (Buffer_Surface, Target_Available, Path);
      end if;
   end Validate_Buffer_Access_State;

   function Validate_File_Target
     (Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result
   is
   begin
      if Trim (Path)'Length = 0 or else not Exists (Path) then
         return Make (Buffer_Surface, Target_Missing, Path);
      elsif not Is_Ordinary_File (Path) then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Read and then not Ada.Directories.Exists (Path) then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Write then
         declare
            Dir : constant String := Ada.Directories.Containing_Directory (Path);
         begin
            if not Exists (Dir) then
               return Make (Buffer_Surface, Target_Missing, Path);
            end if;
         exception
            when others =>
               return Make (Buffer_Surface, Target_Unwritable, Path);
         end;
      end if;
      return Make (Buffer_Surface, Target_Available, Path);
   exception
      when others =>
         return Make (Buffer_Surface, Target_Unreadable, Path);
   end Validate_File_Target;

   function Validate_Project_File_Target
     (Project_Root  : String;
      Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Buffer_Surface, Target_Outside_Project, Path);
      end if;
      Result := Validate_File_Target (Path, Require_Read, Require_Write);
      return Result;
   end Validate_Project_File_Target;

   function Validate_Buffer_Backing_File_Target
     (Path  : String;
      Dirty : Boolean := False) return Target_Validation_Result
   is
      pragma Unreferenced (Dirty);
      Result : Target_Validation_Result := Validate_File_Target (Path);
   begin
      Result.Surface := Buffer_Surface;
      return Result;
   end Validate_Buffer_Backing_File_Target;

   function Validate_Save_Target
     (Path : String) return Target_Validation_Result
   is
      Dir : constant String :=
        (if Trim (Path)'Length = 0 then "" else Ada.Directories.Containing_Directory (Path));
   begin
      if Trim (Path)'Length = 0 then
         return Make (Buffer_Surface, Target_Missing, Path);
      elsif Trim (Dir)'Length = 0 or else not Is_Directory (Dir) then
         return Make (Buffer_Surface, Target_Parent_Directory_Missing, Path);
      elsif Exists (Path) and then not Is_Ordinary_File (Path) then
         return Make (Buffer_Surface, Target_Unwritable, Path);
      else
         return Make (Buffer_Surface, Target_Available, Path);
      end if;
   exception
      when others =>
         return Make (Buffer_Surface, Target_Unwritable, Path);
   end Validate_Save_Target;

   function Validate_Reveal_Target
     (Path         : String;
      Project_Root : String := "") return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_Project_File_Target (Project_Root, Path);
   begin
      Result.Surface := File_Tree_Surface;
      return Result;
   end Validate_Reveal_Target;

   function Dirty_Buffer_Text_Preserved_On
     (State : Target_Availability_State) return Boolean
   is
   begin
      return State in Target_Missing
        | Target_Parent_Directory_Missing
        | Target_Unreadable
        | Target_Unwritable
        | Target_Reload_Required;
   end Dirty_Buffer_Text_Preserved_On;

   function Dirty_State_Preserved_On
     (State : Target_Availability_State) return Boolean
   is
   begin
      return Dirty_Buffer_Text_Preserved_On (State);
   end Dirty_State_Preserved_On;

   function Validate_Line_Column_Target
     (Line             : Natural;
      Column           : Natural;
      Last_Line        : Natural;
      Last_Line_Column : Natural) return Target_Validation_Result
   is
   begin
      if Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Buffer_Surface, Target_Line_Out_Of_Range, Line => Line, Column => Column);
      elsif Column = 0 or else Column > Last_Line_Column then
         return Make (Buffer_Surface, Target_Column_Out_Of_Range, Line => Line, Column => Column);
      else
         return Make (Buffer_Surface, Target_Available, Line => Line, Column => Column);
      end if;
   end Validate_Line_Column_Target;

end Editor.Missing_Stale_Recovery.File_Lifecycle_Policies;
