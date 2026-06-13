with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Build_Output_Details;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.State;

procedure Editor_Real_Build_Runner_Smoke is

   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Build_Output_Details.Build_Output_Stream_Selection;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.External_Producers.Process_Output_Capture_Mode;
   use type Editor.External_Producers.Process_Run_Status;

   package Stream_IO renames Ada.Streams.Stream_IO;

   Root : constant String := Ada.Directories.Current_Directory
     & "/phase579_real_build_runner_smoke_project";
   Src  : constant String := Root & "/src";
   Main_Path : constant String := Src & "/main.adb";
   Project_Path : constant String := Root & "/smoke_project.gpr";

   procedure Fail (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,
                            "editor_real_build_runner_smoke: " & Message);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error with Message;
   end Fail;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Fail (Message);
      end if;
   end Check;

   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Write_File (Path : String; Text : String) is
      F   : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Text'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;
      if Text'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_File;

   procedure Build_Fixture (Valid : Boolean) is
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
      Write_File
        (Project_Path,
         "project Smoke_Project is" & ASCII.LF &
         "   for Source_Dirs use (""src"");" & ASCII.LF &
         "   for Object_Dir use ""obj"";" & ASCII.LF &
         "   for Exec_Dir use ""bin"";" & ASCII.LF &
         "   for Main use (""main.adb"");" & ASCII.LF &
         "end Smoke_Project;" & ASCII.LF);
      if Valid then
         Write_File
           (Main_Path,
            "procedure Main is" & ASCII.LF &
            "begin" & ASCII.LF &
            "   null;" & ASCII.LF &
            "end Main;" & ASCII.LF);
      else
         Write_File
           (Main_Path,
            "procedure Main is" & ASCII.LF &
            "begin" & ASCII.LF &
            "   this is not Ada;" & ASCII.LF &
            "end Main;" & ASCII.LF);
      end if;
   end Build_Fixture;

   function Smoke_Request return Editor.External_Producers.Build_Run_Request is
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
   begin
      Editor.External_Producers.Append_Process_Argument (Args, "-q");
      Editor.External_Producers.Append_Process_Argument (Args, "-P");
      Editor.External_Producers.Append_Process_Argument (Args, Project_Path);
      return
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => To_Unbounded_String (Root),
         Command_Label => To_Unbounded_String ("gprbuild -q -P smoke_project.gpr"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);
   end Smoke_Request;

   function Runner_Status_For
     (Status : Editor.External_Producers.Build_Run_Status)
      return Editor.Build_Output_Details.Build_Output_Runner_Status
   is
   begin
      case Status is
         when Editor.External_Producers.Build_Run_Succeeded =>
            return Editor.Build_Output_Details.Build_Output_Runner_Succeeded;
         when Editor.External_Producers.Build_Run_Failed =>
            return Editor.Build_Output_Details.Build_Output_Runner_Failed;
         when Editor.External_Producers.Build_Run_Not_Available =>
            return Editor.Build_Output_Details.Build_Output_Runner_Not_Available;
         when Editor.External_Producers.Build_Run_Rejected =>
            return Editor.Build_Output_Details.Build_Output_Runner_Rejected;
         when Editor.External_Producers.Build_Run_Execution_Error =>
            return Editor.Build_Output_Details.Build_Output_Runner_Execution_Error;
         when Editor.External_Producers.Build_Run_Timed_Out =>
            return Editor.Build_Output_Details.Build_Output_Runner_Timed_Out;
         when Editor.External_Producers.Build_Run_Cancelled =>
            return Editor.Build_Output_Details.Build_Output_Runner_Cancelled;
         when Editor.External_Producers.Build_Run_Cancellation_Unsupported =>
            return Editor.Build_Output_Details.Build_Output_Runner_Cancellation_Unsupported;
         when Editor.External_Producers.Build_Run_Output_Truncated =>
            return Editor.Build_Output_Details.Build_Output_Runner_Output_Truncated;
      end case;
   end Runner_Status_For;

   procedure Check_Build_Output_Details
     (Result       : Editor.External_Producers.Build_Run_Result;
      Has_Output   : Boolean;
      Context      : String)
   is
      Expected_Stream : constant Editor.Build_Output_Details.Build_Output_Stream_Selection :=
        (if Editor.External_Producers.Build_Result_Output_Stream (Result) =
            Editor.External_Producers.Process_Output_Merged
         then Editor.Build_Output_Details.Build_Output_Stream_Merged
         elsif Editor.External_Producers.Build_Result_Output_Stream (Result) =
            Editor.External_Producers.Process_Output_Stderr
         then Editor.Build_Output_Details.Build_Output_Stream_Stderr
         else Editor.Build_Output_Details.Build_Output_Stream_Stdout);
      Details : Editor.Build_Output_Details.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Build_Output_Details_From_Captured_Output
          (Runner_Status    => Runner_Status_For (Result.Status),
           Stdout_Text      => Result.Stdout_Text,
           Stderr_Text      => Result.Stderr_Text,
           Stdout_Truncated => Result.Stdout_Truncated,
           Stderr_Truncated => Result.Stderr_Truncated,
           Output_Partial   => Result.Output_Partial,
           Exit_Code        => Result.Exit_Code,
           Has_Exit_Code    => Result.Has_Exit_Code,
           Output_Stream    => Expected_Stream);
      Snapshot : Editor.Build_Output_Details.Latest_Build_Output_Details_Render_Snapshot;
   begin
      Check (Details.Has_Output_Details,
             Context & ": build output details were not created");
      Check (Details.Selected_Output_Stream = Expected_Stream,
             Context & ": real-runner output stream selection did not match captured streams");
      if Has_Output then
         Check (Details.Kind in
                  Editor.Build_Output_Details.Build_Output_Details_Available |
                  Editor.Build_Output_Details.Build_Output_Details_Truncated,
                Context & ": build output details do not expose captured output");
         Check (Details.Stdout_Available or else Details.Stderr_Available,
                Context & ": build output details lost captured output text");
      end if;

      Editor.Build_Output_Details.Show_Output_Details (Details);
      Snapshot := Editor.Build_Output_Details.Render_Snapshot (Details);
      Check (Snapshot.Output_Details_Visible,
             Context & ": build output details are not visible after show action");
      Check (Snapshot.Selected_Output_Stream = Expected_Stream,
             Context & ": build output render snapshot lost separated stream selection");
   end Check_Build_Output_Details;

   procedure Check_Timeout_If_Available is
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
      Request : Editor.External_Producers.Process_Run_Request;
      Policy  : constant Editor.External_Producers.Process_Execution_Policy :=
        (Mode                     => Editor.External_Producers.Process_Execution_Real_Allowed,
         Allow_Real_Execution     => True,
         Allow_Shell              => False,
         Max_Output_Bytes         => 4_096,
         Require_Absolute_Program => True,
         Timeout_Milliseconds     => 1);
      Result : Editor.External_Producers.Process_Run_Result;
   begin
      if not Ada.Directories.Exists ("/bin/sleep") then
         Ada.Text_IO.Put_Line
           ("editor_real_build_runner_smoke: /bin/sleep not present; timeout branch skipped");
         return;
      end if;

      Editor.External_Producers.Append_Process_Argument (Args, "2");
      Request :=
        (Program_Label => To_Unbounded_String ("/bin/sleep"),
         Working_Label => To_Unbounded_String (Root),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);
      Result := Editor.External_Producers.Execute_Process_Request_Real_Gated
        (Request, Policy);
      Check (Result.Status = Editor.External_Producers.Process_Run_Timed_Out,
             "real process timeout did not map through the native runner supervisor");
      Check (Result.Has_Exit_Code and then Result.Exit_Code = 124,
             "timeout result did not preserve the canonical timeout exit code");
      Check (Result.Output_Capture_Mode =
               Editor.External_Producers.Process_Output_Capture_Separated,
             "timeout result did not retain separated stdout/stderr provenance");
   end Check_Timeout_If_Available;

   S : Editor.State.State_Type;
   Gate : constant Editor.External_Producers.Build_Execution_Gate :=
     Editor.External_Producers.Build_Real_Execution_Gate
       (Allow_Diagnostics_Ingestion => True,
        Show_Diagnostics            => False,
        Consent                     => Editor.External_Producers.Build_Consent_User_Confirmed);
   Success_Result : Editor.External_Producers.Build_Command_Result;
   Failure_Result : Editor.External_Producers.Build_Command_Result;

begin
   Editor.State.Init (S);

   Build_Fixture (Valid => True);
   Success_Result := Editor.External_Producers.Run_Build_Command_With_Gate
     (S, Smoke_Request, Gate);
   Check (Success_Result.Build_Result.Status =
            Editor.External_Producers.Build_Run_Succeeded,
          "real gprbuild runner did not report success for a valid fixture");
   Check (Success_Result.Build_Result.Has_Exit_Code
          and then Success_Result.Build_Result.Exit_Code = 0,
          "real gprbuild runner did not expose a zero exit code");
   Check (Success_Result.Build_Result.Output_Capture_Mode =
            Editor.External_Producers.Process_Output_Capture_Separated,
          "successful real gprbuild runner did not report separated capture provenance");
   Check_Build_Output_Details
     (Success_Result.Build_Result,
      Has_Output => Length (Success_Result.Build_Result.Stdout_Text) > 0 or else
                    Length (Success_Result.Build_Result.Stderr_Text) > 0,
      Context    => "successful real gprbuild run");

   Build_Fixture (Valid => False);
   Failure_Result := Editor.External_Producers.Run_Build_Command_With_Gate
     (S, Smoke_Request, Gate);
   Check (Failure_Result.Build_Result.Status =
            Editor.External_Producers.Build_Run_Failed,
          "real gprbuild runner did not report failure for an invalid fixture");
   Check (Failure_Result.Build_Result.Has_Exit_Code
          and then Failure_Result.Build_Result.Exit_Code /= 0,
          "real gprbuild runner did not expose a nonzero exit code");
   Check (Length (Failure_Result.Build_Result.Stdout_Text) > 0
          or else Length (Failure_Result.Build_Result.Stderr_Text) > 0,
          "real gprbuild runner did not capture compiler output");
   Check (Failure_Result.Build_Result.Output_Capture_Mode =
            Editor.External_Producers.Process_Output_Capture_Separated,
          "failing real gprbuild runner did not report separated capture provenance");
   Check_Build_Output_Details
     (Failure_Result.Build_Result,
      Has_Output => True,
      Context    => "failing real gprbuild run");
   Check (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1,
          "real gprbuild runner output was not ingested into Diagnostics");

   Check_Timeout_If_Available;

   Remove_Tree_If_Exists (Root);
   Ada.Text_IO.Put_Line ("editor_real_build_runner_smoke: PASS");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when E : others =>
      Remove_Tree_If_Exists (Root);
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "editor_real_build_runner_smoke: FAIL: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Editor_Real_Build_Runner_Smoke;
