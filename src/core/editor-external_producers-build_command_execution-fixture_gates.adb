with Ada.Calendar;
with Ada.Directories;
with Ada.Containers;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Hostkit.Process;
with Editor.Image_Helpers;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.Build_Runner_Policy;
with Editor.State;
with Editor.External_Producers.Diagnostics;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Execution_Policy;
with Editor.External_Producers.Public_Build_Input_Validation;
with Editor.External_Producers.Request_Policies;
with Editor.External_Producers.Source_Metadata;
with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;
with Editor.External_Producers.Build_Command_Execution.Output_Capture; use Editor.External_Producers.Build_Command_Execution.Output_Capture;
with Editor.External_Producers.Build_Command_Execution.Diagnostics; use Editor.External_Producers.Build_Command_Execution.Diagnostics;
with Editor.External_Producers.Build_Command_Execution.Feedback; use Editor.External_Producers.Build_Command_Execution.Feedback;
with Editor.External_Producers.Build_Command_Execution.Preflight; use Editor.External_Producers.Build_Command_Execution.Preflight;
with Editor.External_Producers.Build_Command_Execution.Real_Process; use Editor.External_Producers.Build_Command_Execution.Real_Process;
with Editor.External_Producers.Build_Command_Execution.Results; use Editor.External_Producers.Build_Command_Execution.Results;

package body Editor.External_Producers.Build_Command_Execution.Fixture_Gates is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

   function Build_One_Process_Argument
     (Value : String) return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_One_Process_Argument;

   function Contains_Control_Character (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Control_Character;

   function Real_Build_Tool_Fixture_Is_Approved
     (Fixture : Real_Build_Tool_Fixture_Kind) return Boolean
   is
   begin
      case Fixture is
         when No_Real_Build_Tool_Fixture =>
            return False;
         when GPRbuild_Version_Fixture
            | Alire_Version_Fixture
            | Diagnostic_Output_Fixture =>
            return True;
      end case;
   end Real_Build_Tool_Fixture_Is_Approved;

   function Validate_Real_Build_Tool_Fixture_Gate
     (Gate : Build_Execution_Gate) return Boolean
   is
   begin
      return Validate_Build_Execution_Gate (Gate)
        and then Gate.Allow_Build_Run
        and then Gate.Allow_Real_Build_Tool_Fixture
        and then not Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Process_Policy.Mode = Process_Execution_Real_Fixture_Allowed
        and then Gate.Process_Policy.Allow_Real_Execution
        and then not Gate.Process_Policy.Allow_Shell
        and then Gate.Process_Policy.Max_Output_Bytes > 0;
   end Validate_Real_Build_Tool_Fixture_Gate;

   function Validate_Real_Build_Tool_Fixture_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate)
      return Real_Build_Tool_Fixture_Validation_Status
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Working_Status : Process_Request_Validation_Status;
      Clean_Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Gate.Allow_Real_Build_Tool_Execution
        and then Gate.Allow_Real_Build_Tool_Fixture
      then
         return Real_Build_Fixture_Rejected_Ambiguous_Gate;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return Real_Build_Fixture_Rejected_Shell;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Real_Build_Fixture_Rejected_Disabled;
      end if;

      if not Real_Build_Tool_Fixture_Is_Approved (Fixture) then
         return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end if;

      case Request.Provenance is
         when Build_Request_From_Implicit_Source =>
            return Real_Build_Fixture_Rejected_Implicit_Source;
         when Build_Request_From_User_Opt_In
            | Build_Request_From_Test
            | Build_Request_From_Fixture =>
            null;
         when Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return Real_Build_Fixture_Rejected_Provenance;
      end case;

      if Build_Status = Build_Request_Rejected_Implicit_Source then
         return Real_Build_Fixture_Rejected_Implicit_Source;
      elsif Build_Status /= Build_Request_Valid then
         if Request.Tool = Custom_Build_Tool then
            return Real_Build_Fixture_Rejected_Custom_Tool;
         else
            return Real_Build_Fixture_Rejected_Provenance;
         end if;
      end if;

      if Request.Tool = Custom_Build_Tool then
         return Real_Build_Fixture_Rejected_Custom_Tool;
      end if;

      case Fixture is
         when GPRbuild_Version_Fixture =>
            if Request.Tool /= GPRbuild_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Alire_Version_Fixture =>
            if Request.Tool /= Alire_Build_Tool then
               return Real_Build_Fixture_Rejected_Custom_Tool;
            end if;
         when Diagnostic_Output_Fixture =>
            null;
         when No_Real_Build_Tool_Fixture =>
            return Real_Build_Fixture_Rejected_Unknown_Fixture;
      end case;

      Working_Status := Validate_Build_Working_Context (Request, Gate);
      if Working_Status /= Process_Request_Valid then
         return Real_Build_Fixture_Rejected_Working_Context;
      end if;

      if Clean_Opaque'Length > 0 or else not Request.Structured_Arguments.Is_Empty then
         return Real_Build_Fixture_Rejected_Opaque_Arguments;
      end if;

      return Real_Build_Fixture_Valid;
   end Validate_Real_Build_Tool_Fixture_Request;

   function Real_Build_Tool_Fixture_Status_To_Build_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Build_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Build_Request_Valid;
         when Real_Build_Fixture_Rejected_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Real_Build_Fixture_Rejected_Custom_Tool =>
            return Build_Request_Rejected_Unsupported_Tool;
         when Real_Build_Fixture_Rejected_Provenance =>
            return Build_Request_Rejected_Provenance;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Unknown_Fixture
            | Real_Build_Fixture_Rejected_Shell
            | Real_Build_Fixture_Rejected_Opaque_Arguments
            | Real_Build_Fixture_Rejected_Working_Context
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Build_Request_Valid;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Build_Status;

   function Real_Build_Tool_Fixture_Status_To_Process_Status
     (Status : Real_Build_Tool_Fixture_Validation_Status)
      return Process_Request_Validation_Status
   is
   begin
      case Status is
         when Real_Build_Fixture_Valid =>
            return Process_Request_Valid;
         when Real_Build_Fixture_Rejected_Disabled
            | Real_Build_Fixture_Rejected_Ambiguous_Gate
            | Real_Build_Fixture_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Real_Build_Fixture_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Real_Build_Fixture_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Real_Build_Fixture_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Real_Build_Fixture_Rejected_Working_Context =>
            return Process_Request_Rejected_Unsupported_Working_Directory;
         when Real_Build_Fixture_Rejected_Provenance
            | Real_Build_Fixture_Rejected_Implicit_Source
            | Real_Build_Fixture_Rejected_Custom_Tool =>
            return Process_Request_Rejected_Execution_Disabled;
      end case;
   end Real_Build_Tool_Fixture_Status_To_Process_Status;

   function Validate_Real_Build_Tool_Fixture_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
   is
   begin
      case Request.Provenance is
         when Build_Request_Unknown =>
            return Build_Request_Rejected_Unknown_Provenance;
         when Build_Request_From_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Build_Request_From_User_Opt_In =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Test | Build_Request_From_Fixture =>
            if Validate_Real_Build_Tool_Fixture_Gate (Gate) then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Internal_Command =>
            return Build_Request_Rejected_Provenance;
      end case;
   end Validate_Real_Build_Tool_Fixture_Provenance;

   function Prepare_Real_Build_Tool_Fixture_Process_Request
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind) return Process_Run_Request
   is
      pragma Unreferenced (Request);
   begin
      case Fixture is
         when GPRbuild_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("gprbuild"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Alire_Version_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("alr"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument ("--version"));
         when Diagnostic_Output_Fixture =>
            return
              (Program_Label        => To_Unbounded_String ("diagnostic-output-fixture"),
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Build_One_Process_Argument
                 ("--diagnostic-output-fixture"));
         when No_Real_Build_Tool_Fixture =>
            return
              (Program_Label        => Null_Unbounded_String,
               Working_Label        => Null_Unbounded_String,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Empty_Process_Arguments);
      end case;
   end Prepare_Real_Build_Tool_Fixture_Process_Request;

   function Validate_Real_Build_Tool_Fixture_Process_Request
     (Request : Process_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Opaque_Args : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Gate.Process_Policy.Allow_Shell then
         return Process_Request_Rejected_Shell_Disallowed;
      end if;

      if not Validate_Real_Build_Tool_Fixture_Gate (Gate) then
         return Process_Request_Rejected_Execution_Disabled;
      end if;

      if Gate.Process_Policy.Max_Output_Bytes = 0 then
         return Process_Request_Rejected_Invalid_Argument;
      end if;

      if Clean_Program'Length = 0 then
         return Process_Request_Rejected_Empty_Program;
      end if;

      if Opaque_Args'Length > 0 then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty then
         return Process_Request_Rejected_Opaque_Arguments;
      end if;

      for Arg of Request.Structured_Arguments loop
         declare
            Value : constant String := To_String (Arg);
         begin
            if Value'Length = 0 or else Contains_Control_Character (Value) then
               return Process_Request_Rejected_Invalid_Argument;
            end if;
         end;
      end loop;

      return Process_Request_Valid;
   end Validate_Real_Build_Tool_Fixture_Process_Request;

   function Preflight_Real_Build_Tool_Fixture
     (Request : Build_Run_Request;
      Fixture : Real_Build_Tool_Fixture_Kind;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Validation : constant Real_Build_Tool_Fixture_Validation_Status :=
        Validate_Real_Build_Tool_Fixture_Request (Request, Fixture, Gate);
      Build_Status : constant Build_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Build_Status (Validation);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Real_Build_Tool_Fixture_Status_To_Process_Status (Validation);
   begin
      if Validation /= Real_Build_Fixture_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Real_Build_Tool_Fixture_Process_Request
        (Request, Fixture);
      Process_Status := Validate_Real_Build_Tool_Fixture_Process_Request
        (Process_Request, Gate);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Fixture;

   function Real_Build_Tool_Fixture_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
      Program : constant String := To_String (Result.Process_Request.Program_Label);
      Opaque : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Result.Process_Request.Arguments), Both);
   begin
      if not Build_Preflight_Result_Is_Consistent (Result) then
         return False;
      end if;

      if Result.Build_Request_Status = Build_Request_Rejected_Implicit_Source
        and then Result.Has_Process_Request
      then
         return False;
      end if;

      if Result.Process_Request_Status /= Process_Request_Valid then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Program'Length > 0
        and then Opaque'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end Real_Build_Tool_Fixture_Preflight_Is_Consistent;

   function Real_Build_Tool_Fixture_Command_Result_Is_Consistent
     (Result : Build_Command_Result) return Boolean
   is
      Message : constant String := To_String (Result.Command_Message);
      Ingested : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count;
      Parsed : constant Natural :=
        Result.Diagnostic_Result.Ingestion.Parse_Input_Count;
   begin
      if Message'Length = 0 then
         return False;
      end if;

      case Result.Build_Result.Status is
         when Build_Run_Succeeded | Build_Run_Failed =>
            if not Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
         when Build_Run_Not_Available | Build_Run_Rejected
            | Build_Run_Execution_Error | Build_Run_Timed_Out
            | Build_Run_Cancelled | Build_Run_Cancellation_Unsupported
            | Build_Run_Output_Truncated =>
            if Result.Build_Result.Has_Exit_Code then
               return False;
            end if;
      end case;

      if Result.Build_Result.Status = Build_Run_Not_Available
        and then Message = "Build: succeeded"
      then
         return False;
      end if;

      if Result.Build_Result.Status = Build_Run_Execution_Error
        and then Ingested > 0
      then
         return False;
      end if;

      if Ingested = 0 and then Parsed = 0 then
         return Message'Length > 0;
      end if;

      return True;
   end Real_Build_Tool_Fixture_Command_Result_Is_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Preflight_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Preflight_Consistent;

   procedure Assert_Real_Build_Tool_Fixture_Command_Result_Consistent
     (Result : Build_Command_Result)
   is
   begin
      pragma Assert (Real_Build_Tool_Fixture_Command_Result_Is_Consistent (Result));
   end Assert_Real_Build_Tool_Fixture_Command_Result_Consistent;

   function Validate_Process_Fixture_Request
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Fixture_Validation_Status
   is
   begin
      if Policy.Allow_Shell then
         return Fixture_Request_Rejected_Shell;
      end if;

      if not Validate_Process_Execution_Policy (Policy)
        or else Policy.Mode /= Process_Execution_Real_Fixture_Allowed
        or else not Policy.Allow_Real_Execution
      then
         return Fixture_Request_Rejected_Disabled;
      end if;

      if Policy.Max_Output_Bytes = 0 then
         return Fixture_Request_Rejected_Output_Limit;
      end if;

      case Fixture.Kind is
         when No_Process_Fixture =>
            return Fixture_Request_Rejected_Unknown_Fixture;
         when Echo_Diagnostic_Fixture | Exit_Code_Fixture =>
            null;
      end case;

      for Arg of Fixture.Arguments loop
         if Contains_Control_Character (To_String (Arg)) then
            return Fixture_Request_Rejected_Invalid_Argument;
         end if;
      end loop;

      return Fixture_Request_Valid;
   end Validate_Process_Fixture_Request;

   function Validate_Process_Fixture_Request_Status
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
   is
      Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request (Fixture, Policy);
   begin
      case Status is
         when Fixture_Request_Valid =>
            return Process_Request_Valid;
         when Fixture_Request_Rejected_Disabled
            | Fixture_Request_Not_Available =>
            return Process_Request_Rejected_Execution_Disabled;
         when Fixture_Request_Rejected_Shell =>
            return Process_Request_Rejected_Shell_Disallowed;
         when Fixture_Request_Rejected_Unknown_Fixture =>
            return Process_Request_Rejected_Empty_Program;
         when Fixture_Request_Rejected_Opaque_Arguments =>
            return Process_Request_Rejected_Opaque_Arguments;
         when Fixture_Request_Rejected_Invalid_Argument
            | Fixture_Request_Rejected_Output_Limit =>
            return Process_Request_Rejected_Invalid_Argument;
      end case;
   end Validate_Process_Fixture_Request_Status;

   function Process_Fixture_Request_Is_Valid
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Boolean
   is
   begin
      return Validate_Process_Fixture_Request (Fixture, Policy) =
        Fixture_Request_Valid;
   end Process_Fixture_Request_Is_Valid;

   function Build_Process_Fixture_Request
     (Kind  : Process_Fixture_Kind;
      First : String := "";
      Second : String := "";
      Third : String := "") return Process_Fixture_Request
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, First);
      Append_Process_Argument (Args, Second);
      Append_Process_Argument (Args, Third);
      return (Kind => Kind, Arguments => Args);
   end Build_Process_Fixture_Request;

   procedure Append_With_Newline
     (Target : in out Unbounded_String;
      Value  : String)
   is
   begin
      if Length (Target) > 0 then
         Append (Target, ASCII.LF);
      end if;
      Append (Target, Value);
   end Append_With_Newline;

   procedure Append_Fixture_Output_Line
     (Target   : in out Unbounded_String;
      Has_Line : in out Boolean;
      Value    : String)
   is
   begin
      if Has_Line then
         Append (Target, ASCII.LF);
      end if;
      Append (Target, Value);
      Has_Line := True;
   end Append_Fixture_Output_Line;

   function Execute_Process_Request_Real_Fixture
     (Fixture : Process_Fixture_Request;
      Policy  : Process_Execution_Policy) return Process_Run_Result
   is
      Status : constant Process_Fixture_Validation_Status :=
        Validate_Process_Fixture_Request (Fixture, Policy);
      Out_Text : Unbounded_String := Null_Unbounded_String;
      Err_Text : Unbounded_String := Null_Unbounded_String;
      Out_Has_Line : Boolean := False;
      Err_Has_Line : Boolean := False;
      Use_Stderr : Boolean := False;
      Use_Mixed   : Boolean := False;
      First_Index : Natural := 0;
      Code : Integer := 0;
   begin
      if Status = Fixture_Request_Rejected_Disabled
        or else Status = Fixture_Request_Not_Available
      then
         return Build_Process_Run_Result (Process_Run_Not_Available);
      elsif Status /= Fixture_Request_Valid then
         return Build_Process_Run_Result (Process_Run_Rejected);
      end if;

      if Policy.Max_Output_Bytes = 0 then
         return Build_Process_Run_Result (Process_Run_Execution_Error);
      end if;

      case Fixture.Kind is
         when No_Process_Fixture =>
            return Build_Process_Run_Result (Process_Run_Rejected);

         when Echo_Diagnostic_Fixture =>
            if Fixture.Arguments.Length > 0 then
               declare
                  First : constant String :=
                    To_String (Fixture.Arguments.First_Element);
               begin
                  if First = "stderr" then
                     Use_Stderr := True;
                     First_Index := 1;
                  elsif First = "stdout" then
                     First_Index := 1;
                  elsif First = "mixed" then
                     Use_Mixed := True;
                     First_Index := Natural (Fixture.Arguments.Length);
                  end if;
               end;
            end if;

            if Use_Mixed and then Fixture.Arguments.Length > 1 then
               Append_Fixture_Output_Line
                 (Err_Text, Err_Has_Line,
                  To_String (Fixture.Arguments.Element (1)));
               if Fixture.Arguments.Length > 2 then
                  Append_Fixture_Output_Line
                    (Out_Text, Out_Has_Line,
                     To_String (Fixture.Arguments.Element (2)));
               end if;
            elsif Natural (Fixture.Arguments.Length) > First_Index then
               for I in First_Index .. Natural (Fixture.Arguments.Length) - 1 loop
                  declare
                     Value : constant String :=
                       To_String (Fixture.Arguments.Element (I));
                     Is_Trailing_Empty : constant Boolean :=
                       I = Natural (Fixture.Arguments.Length) - 1
                       and then Value'Length = 0;
                  begin
                     if not Is_Trailing_Empty then
                        if Use_Stderr then
                           Append_Fixture_Output_Line
                             (Err_Text, Err_Has_Line, Value);
                        else
                           Append_Fixture_Output_Line
                             (Out_Text, Out_Has_Line, Value);
                        end if;
                     end if;
                  end;
               end loop;
            end if;

            return Enforce_Process_Output_Bounds
              ((Status        => Process_Run_Succeeded,
                Output_Capture_Mode => Process_Output_Capture_Separated,
                Has_Exit_Code => True,
                Exit_Code     => 0,
                Stdout_Text   => Out_Text,
                Stderr_Text   => Err_Text,
                Stdout_Truncated => False,
                Stderr_Truncated => False),
               Policy);

         when Exit_Code_Fixture =>
            if Fixture.Arguments.Length > 0 then
               begin
                  Code := Integer'Value
                    (To_String (Fixture.Arguments.First_Element));
               exception
                  when Constraint_Error =>
                     return Build_Process_Run_Result (Process_Run_Rejected);
               end;
            end if;

            if Fixture.Arguments.Length > 1 then
               for I in 1 .. Natural (Fixture.Arguments.Length) - 1 loop
                  declare
                     Value : constant String :=
                       To_String (Fixture.Arguments.Element (I));
                     Is_Trailing_Empty : constant Boolean :=
                       I = Natural (Fixture.Arguments.Length) - 1
                       and then Value'Length = 0;
                  begin
                     if not Is_Trailing_Empty then
                        Append_Fixture_Output_Line
                          (Err_Text, Err_Has_Line, Value);
                     end if;
                  end;
               end loop;
            end if;

            return Enforce_Process_Output_Bounds
              ((Status        => (if Code = 0 then Process_Run_Succeeded else Process_Run_Failed),
                Output_Capture_Mode => Process_Output_Capture_Separated,
                Has_Exit_Code => True,
                Exit_Code     => Code,
                Stdout_Text   => Null_Unbounded_String,
                Stderr_Text   => Err_Text,
                Stdout_Truncated => False,
                Stderr_Truncated => False),
               Policy);
      end case;
   end Execute_Process_Request_Real_Fixture;


end Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
