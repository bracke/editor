with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Command_Execution;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Quick_Open_Input_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Quick_Open_Create_Commands is

   function Last_Slash (Text : String) return Natural is
   begin
      for I in reverse Text'Range loop
         if Text (I) = '/' then
            return I;
         end if;
      end loop;
      return 0;
   end Last_Slash;

   function Open_Failure_Text
     (Result : Editor.Files.File_Open_Result) return String is
   begin
      case Result.Status is
         when Editor.Files.File_Open_Not_Found =>
            return "file not found";
         when Editor.Files.File_Open_Permission_Denied =>
            return "permission denied";
         when others =>
            return Editor.Files.Status_Message (Result);
      end case;
   end Open_Failure_Text;

   procedure Execute_Quick_Open_Create_From_Query
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Quick_Open.Quick_Open_Create_Target_Result;
      Rule_Check : Editor.Project.Project_Create_Path_Validation_Result;
      Rel_Path : Unbounded_String := Null_Unbounded_String;
      Abs_Path : Unbounded_String := Null_Unbounded_String;
      Parent_Rel : Unbounded_String := Null_Unbounded_String;
      Parent_Abs : Unbounded_String := Null_Unbounded_String;
      Created_File : Ada.Text_IO.File_Type;
      Created_File_Open : Boolean := False;
      Open_Check : Editor.Files.File_Open_Result;
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project.Root_Path (S.Project)'Length = 0 then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Target := Editor.Quick_Open.Create_Target_From_Query (S.Quick_Open);
      case Target.Status is
         when Editor.Quick_Open.Quick_Open_Create_Target_No_Query =>
            Editor.Executor.Shared_Services.Report_Warning (S, "No Quick Open query");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path =>
            Editor.Executor.Shared_Services.Report_Warning (S, "Invalid project file path");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Ok =>
            null;
      end case;

      Rel_Path := Target.Project_Relative_Path;
      Abs_Path := To_Unbounded_String
        (Editor.Project.Absolute_Project_File_Path (S.Project, To_String (Rel_Path)));

      Rule_Check := Editor.Project.Validate_Project_Create_Path_Rules
        (S.Project, To_String (Rel_Path));
      case Rule_Check.Status is
         when Editor.Project.Project_Create_Path_Ok =>
            null;
         when Editor.Project.Project_Create_Path_No_Project =>
            Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Invalid_Root =>
            Editor.Executor.Shared_Services.Report_Warning (S, "No project open.");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignored =>
            Editor.Executor.Shared_Services.Report_Warning (S, "Path is ignored by project rules: " & To_String (Rel_Path));
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignore_Read_Error =>
            Editor.Executor.Shared_Services.Report_Warning (S, To_String (Rule_Check.Failure_Reason));
            Editor.Render_Cache.Invalidate_All;
            return;
      end case;

      if Editor.Project.Has_Known_File (S.Project, To_String (Rel_Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Project file already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Ada.Directories.Exists (To_String (Abs_Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "File already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Rel : constant String := To_String (Rel_Path);
         Slash : constant Natural := Last_Slash (Rel);
      begin
         if Slash = 0 then
            Parent_Abs := To_Unbounded_String (Editor.Project.Root_Path (S.Project));
            Parent_Rel := Null_Unbounded_String;
         else
            Parent_Rel := To_Unbounded_String (Rel (Rel'First .. Slash));
            Parent_Abs := To_Unbounded_String
              (Editor.Project.Absolute_Project_File_Path
                 (S.Project, Rel (Rel'First .. Slash - 1)));
         end if;
      end;

      if not Ada.Directories.Exists (To_String (Parent_Abs))
        or else Ada.Directories.Kind (To_String (Parent_Abs)) /= Ada.Directories.Directory
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Parent directory does not exist: " & To_String (Parent_Rel));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      begin
         Ada.Text_IO.Create
           (File => Created_File,
            Mode => Ada.Text_IO.Out_File,
            Name => To_String (Abs_Path));
         Created_File_Open := True;
         Ada.Text_IO.Close (Created_File);
         Created_File_Open := False;
      exception
         when Ada.IO_Exceptions.Use_Error =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Shared_Services.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": permission denied");
            Editor.Render_Cache.Invalidate_All;
            return;
         when others =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Shared_Services.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": filesystem error");
            Editor.Render_Cache.Invalidate_All;
            return;
      end;

      Editor.Project.Add_Known_File
        (S.Project, To_String (Rel_Path), To_String (Abs_Path));
      Editor.Executor.Quick_Open_Input_Commands.Recompute_Quick_Open (S);
      declare
         Selected : Boolean := False;
      begin
         Editor.Quick_Open.Select_Path (S.Quick_Open, To_String (Rel_Path), Selected);
      end;

      Open_Check := Editor.Files.Open_File (To_String (Abs_Path));
      if not Editor.Files.Is_Success (Open_Check) then
         Editor.Executor.Shared_Services.Report_Error (S, "Created " & To_String (Rel_Path)
            & " but could not open it: " & Open_Failure_Text (Open_Check));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Before_Location : constant Editor.Navigation_History.Navigation_Location :=
           Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Unknown);
      begin
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, To_String (Abs_Path));
         if S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Abs_Path)
         then
            Editor.Executor.Record_Navigation_If_Target_Changed (S, Before_Location,
               Editor.Executor.Structured_File_Navigation_Target (To_String (Abs_Path)));
         end if;
      end;
      Editor.Messages.Dismiss_Latest (S.Messages);
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
      end if;
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Created " & To_String (Rel_Path));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Create_From_Query;

   procedure Execute_Quick_Open_Create_With_Parents_From_Query
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Quick_Open.Quick_Open_Create_Target_Result;
      Rule_Check : Editor.Project.Project_Create_Path_Validation_Result;
      Rel_Path : Unbounded_String := Null_Unbounded_String;
      Abs_Path : Unbounded_String := Null_Unbounded_String;
      Created_File : Ada.Text_IO.File_Type;
      Created_File_Open : Boolean := False;
      Open_Check : Editor.Files.File_Open_Result;
      Created_Parent_Directory_Count : Natural := 0;

      function Last_Slash (Text : String) return Natural is
      begin
         for I in reverse Text'Range loop
            if Text (I) = '/' then
               return I;
            end if;
         end loop;
         return 0;
      end Last_Slash;

      function Open_Failure_Text
        (Result : Editor.Files.File_Open_Result) return String is
      begin
         case Result.Status is
            when Editor.Files.File_Open_Not_Found =>
               return "file not found";
            when Editor.Files.File_Open_Permission_Denied =>
               return "permission denied";
            when others =>
               return Editor.Files.Status_Message (Result);
         end case;
      end Open_Failure_Text;

      procedure Ensure_Parent_Directories
        (Relative_File_Path : String;
         Failed             : out Boolean;
         Failure_Message    : out Unbounded_String)
      is
         Slash : constant Natural := Last_Slash (Relative_File_Path);
         Parent_Rel : constant String :=
           (if Slash = 0 then ""
            else Relative_File_Path (Relative_File_Path'First .. Slash - 1));
         Component_Start : Positive := Parent_Rel'First;

         procedure Check_Or_Create (Dir_Rel : String) is
            Dir_Abs : constant String :=
              Editor.Project.Absolute_Project_File_Path (S.Project, Dir_Rel);
            Display : constant String := Dir_Rel & "/";

            function Directory_Remains_Under_Project return Boolean is
            begin
               return Editor.Project.Is_Under_Project
                 (S.Project, Ada.Directories.Full_Name (Dir_Abs));
            exception
               when others =>
                  return False;
            end Directory_Remains_Under_Project;
         begin
            if Failed then
               return;
            end if;

            if Ada.Directories.Exists (Dir_Abs) then
               if Ada.Directories.Kind (Dir_Abs) /= Ada.Directories.Directory then
                  Failed := True;
                  Failure_Message := To_Unbounded_String
                    ("Parent path is not a directory: " & Dir_Rel);
               elsif not Directory_Remains_Under_Project then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Invalid project file path");
               end if;
               return;
            end if;

            begin
               Ada.Directories.Create_Directory (Dir_Abs);
               Created_Parent_Directory_Count := Created_Parent_Directory_Count + 1;
               if not Directory_Remains_Under_Project then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Invalid project file path");
               end if;
            exception
               when Ada.IO_Exceptions.Use_Error =>
                  Failed := True;
                  Failure_Message := To_Unbounded_String
                    ("Could not create parent directory " & Display & ": permission denied");
               when others =>
                  Failed := True;
                  Failure_Message := To_Unbounded_String
                    ("Could not create parent directory " & Display & ": filesystem error");
            end;
         end Check_Or_Create;
      begin
         Failed := False;
         Failure_Message := Null_Unbounded_String;

         if Parent_Rel'Length = 0 then
            return;
         end if;

         for I in Parent_Rel'Range loop
            if Parent_Rel (I) = '/' then
               if I > Component_Start then
                  Check_Or_Create (Parent_Rel (Parent_Rel'First .. I - 1));
               end if;
               Component_Start := I + 1;
            end if;
         end loop;

         if not Failed then
            Check_Or_Create (Parent_Rel);
         end if;
      end Ensure_Parent_Directories;
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project.Root_Path (S.Project)'Length = 0 then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Target := Editor.Quick_Open.Create_Target_From_Query (S.Quick_Open);
      case Target.Status is
         when Editor.Quick_Open.Quick_Open_Create_Target_No_Query =>
            Editor.Executor.Shared_Services.Report_Warning (S, "No Quick Open query");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path =>
            Editor.Executor.Shared_Services.Report_Warning (S, "Invalid project file path");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Quick_Open.Quick_Open_Create_Target_Ok =>
            null;
      end case;

      Rel_Path := Target.Project_Relative_Path;
      Abs_Path := To_Unbounded_String
        (Editor.Project.Absolute_Project_File_Path (S.Project, To_String (Rel_Path)));

      Rule_Check := Editor.Project.Validate_Project_Create_Path_Rules
        (S.Project, To_String (Rel_Path));
      case Rule_Check.Status is
         when Editor.Project.Project_Create_Path_Ok =>
            null;
         when Editor.Project.Project_Create_Path_No_Project =>
            Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Invalid_Root =>
            Editor.Executor.Shared_Services.Report_Warning (S, "No project open.");
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignored =>
            Editor.Executor.Shared_Services.Report_Warning (S, "Path is ignored by project rules: " & To_String (Rel_Path));
            Editor.Render_Cache.Invalidate_All;
            return;
         when Editor.Project.Project_Create_Path_Ignore_Read_Error =>
            Editor.Executor.Shared_Services.Report_Warning (S, To_String (Rule_Check.Failure_Reason));
            Editor.Render_Cache.Invalidate_All;
            return;
      end case;

      if Editor.Project.Has_Known_File (S.Project, To_String (Rel_Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Project file already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Ada.Directories.Exists (To_String (Abs_Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "File already exists: " & To_String (Rel_Path));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Failed : Boolean := False;
         Failure_Message : Unbounded_String := Null_Unbounded_String;
      begin
         Ensure_Parent_Directories
           (To_String (Rel_Path), Failed, Failure_Message);
         if Failed then
            Editor.Executor.Shared_Services.Report_Error (S, To_String (Failure_Message));
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;
      end;

      begin
         Ada.Text_IO.Create
           (File => Created_File,
            Mode => Ada.Text_IO.Out_File,
            Name => To_String (Abs_Path));
         Created_File_Open := True;
         Ada.Text_IO.Close (Created_File);
         Created_File_Open := False;
      exception
         when Ada.IO_Exceptions.Use_Error =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Shared_Services.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": permission denied");
            Editor.Render_Cache.Invalidate_All;
            return;
         when others =>
            if Created_File_Open then
               begin
                  Ada.Text_IO.Close (Created_File);
               exception
                  when others =>
                     null;
               end;
            end if;
            Editor.Executor.Shared_Services.Report_Error (S, "Could not create " & To_String (Rel_Path) & ": filesystem error");
            Editor.Render_Cache.Invalidate_All;
            return;
      end;

      Editor.Project.Add_Known_File
        (S.Project, To_String (Rel_Path), To_String (Abs_Path));
      Editor.Executor.Quick_Open_Input_Commands.Recompute_Quick_Open (S);
      declare
         Selected : Boolean := False;
      begin
         Editor.Quick_Open.Select_Path (S.Quick_Open, To_String (Rel_Path), Selected);
      end;

      Open_Check := Editor.Files.Open_File (To_String (Abs_Path));
      if not Editor.Files.Is_Success (Open_Check) then
         Editor.Executor.Shared_Services.Report_Error (S, "Created " & To_String (Rel_Path)
            & " but could not open it: " & Open_Failure_Text (Open_Check));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         Before_Location : constant Editor.Navigation_History.Navigation_Location :=
           Editor.Executor.Current_Navigation_Location (S, Editor.Navigation_History.Navigation_Reason_Unknown);
      begin
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, To_String (Abs_Path));
         if S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Abs_Path)
         then
            Editor.Executor.Record_Navigation_If_Target_Changed (S, Before_Location,
               Editor.Executor.Structured_File_Navigation_Target (To_String (Abs_Path)));
         end if;
      end;
      Editor.Messages.Dismiss_Latest (S.Messages);
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
      then
         Editor.Executor.Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Accept);
      else
         Editor.Quick_Open.Close (S.Quick_Open);
      end if;
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Created " & To_String (Rel_Path));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Create_With_Parents_From_Query;

end Editor.Executor.Quick_Open_Create_Commands;
