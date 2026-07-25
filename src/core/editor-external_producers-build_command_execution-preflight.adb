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
with Editor.External_Producers.Build_Command_Execution.Fixture_Gates; use Editor.External_Producers.Build_Command_Execution.Fixture_Gates;
with Editor.External_Producers.Build_Command_Execution.Real_Process; use Editor.External_Producers.Build_Command_Execution.Real_Process;
with Editor.External_Producers.Build_Command_Execution.Results; use Editor.External_Producers.Build_Command_Execution.Results;

package body Editor.External_Producers.Build_Command_Execution.Preflight is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Runner_Policy.Build_Cancellation_State;
   use Editor.External_Producers.Request_Policies;
   use Editor.External_Producers.Execution_Policy;

   function Contains_Control_Character (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Control_Character;

   function Preflight_Build_Run_Request
     (Request : Build_Run_Request;
      Policy  : Process_Execution_Policy) return Build_Preflight_Result
   is
      Build_Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);

      if Policy.Mode = Process_Execution_Disabled then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      elsif Policy.Allow_Shell then
         Process_Status := Process_Request_Rejected_Shell_Disallowed;
      elsif not Validate_Process_Execution_Policy (Policy) then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      elsif Ada.Strings.Fixed.Trim
        (To_String (Process_Request.Program_Label), Both)'Length = 0
      then
         Process_Status := Process_Request_Rejected_Empty_Program;
      elsif Policy.Mode = Process_Execution_Test_Fixture then
         Process_Status := Process_Request_Valid;
      elsif Policy.Mode = Process_Execution_Real_Fixture_Allowed then
         Process_Status := Process_Request_Rejected_Execution_Disabled;
      else
         Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
           (Process_Request, Policy);
      end if;

      return
        (Build_Request_Status   => Build_Status,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Build_Run_Request;

   function Preflight_Real_Build_Tool_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Build_Status : Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Build_Status := Validate_Build_Request_Provenance (Request, Gate);
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Request.Provenance = Build_Request_From_User_Opt_In
        and then Gate.Consent /= Build_Consent_User_Confirmed
      then
         return
           (Build_Request_Status   => Build_Request_Rejected_Consent,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Request.Tool = Custom_Build_Tool then
         return
           (Build_Request_Status   => Build_Request_Rejected_Unsupported_Tool,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if not Validate_Build_Execution_Gate (Gate)
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
      then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Status := Validate_Build_Working_Context (Request, Gate);
      if Process_Status /= Process_Request_Valid then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
        (Process_Request, Gate.Process_Policy);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_Real_Build_Tool_Request;

   function Preflight_User_Opt_In_Build_Request
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Preflight_Result
   is
      Build_Status : Build_Request_Validation_Status :=
        Validate_User_Opt_In_Build_Request (Request);
      Process_Request : Process_Run_Request;
      Process_Status  : Process_Request_Validation_Status :=
        Process_Request_Rejected_Execution_Disabled;
   begin
      if Build_Status /= Build_Request_Valid then
         return
           (Build_Request_Status   => Build_Status,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Gate.Consent /= Build_Consent_User_Confirmed then
         return
           (Build_Request_Status   => Build_Request_Rejected_Consent,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Validate_Build_Execution_Gate (Gate)
        or else not Gate.Allow_Build_Run
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Allow_Shell
        or else Gate.Process_Policy.Max_Output_Bytes = 0
      then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Request_Rejected_Execution_Disabled,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      case Request.Tool is
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
         when Custom_Build_Tool =>
            return
              (Build_Request_Status   => Build_Request_Rejected_Unsupported_Tool,
               Process_Request_Status => Process_Status,
               Has_Process_Request    => False,
               Process_Request        => Process_Request);
         when No_Build_Tool =>
            return
              (Build_Request_Status   => Build_Request_Rejected_No_Tool,
               Process_Request_Status => Process_Status,
               Has_Process_Request    => False,
               Process_Request        => Process_Request);
      end case;

      Process_Status := Validate_Build_Working_Context (Request, Gate);
      if Process_Status /= Process_Request_Valid then
         return
           (Build_Request_Status   => Build_Request_Valid,
            Process_Request_Status => Process_Status,
            Has_Process_Request    => False,
            Process_Request        => Process_Request);
      end if;

      Process_Request := Prepare_Process_Request (Request);
      Process_Status := Validate_Process_Run_Request_For_Real_Execution_Status
        (Process_Request, Gate.Process_Policy);

      return
        (Build_Request_Status   => Build_Request_Valid,
         Process_Request_Status => Process_Status,
         Has_Process_Request    => Process_Status = Process_Request_Valid,
         Process_Request        => Process_Request);
   end Preflight_User_Opt_In_Build_Request;

   function Empty_User_Opt_In_Build_Command_Context
     return User_Opt_In_Build_Command_Context
   is
   begin
      return
        (Has_Request => False,
         Request     => (Tool => No_Build_Tool,
                         Provenance => Build_Request_Unknown,
                         Working_Label => Null_Unbounded_String,
                         Command_Label => Null_Unbounded_String,
                         Arguments => Null_Unbounded_String,
                         Structured_Arguments => Empty_Process_Arguments),
         Gate        => Build_Default_Execution_Gate);
   end Empty_User_Opt_In_Build_Command_Context;

   function Build_User_Opt_In_Command_Context
     (Tool              : Build_Tool_Kind;
      Program_Label     : String;
      Working_Label     : String;
      Arguments         : Process_Argument_Vector;
      Consent           : Build_Execution_Consent;
      Allow_Diagnostics : Boolean;
      Show_Diagnostics  : Boolean)
      return User_Opt_In_Build_Command_Context
   is
   begin
      return
        (Has_Request => True,
         Request     => Build_User_Opt_In_Request
           (Tool, Program_Label, Working_Label, Arguments),
         Gate        => Build_Real_Execution_Gate
           (Allow_Diagnostics_Ingestion => Allow_Diagnostics,
            Show_Diagnostics            => Show_Diagnostics,
            Consent                     => Consent));
   end Build_User_Opt_In_Command_Context;

   function Validate_User_Opt_In_Build_Command_Context
     (Context : User_Opt_In_Build_Command_Context)
      return User_Opt_In_Build_Command_Context_Status
   is
      Request : constant Build_Run_Request := Context.Request;
      Gate    : constant Build_Execution_Gate := Context.Gate;
      Clean_Command : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Command_Label), Both);
   begin
      if not Context.Has_Request then
         return User_Build_Context_Rejected_Missing_Context;
      end if;

      if Request.Provenance = Build_Request_Unknown
        and then Request.Tool = No_Build_Tool
        and then Clean_Command'Length = 0
        and then Request.Structured_Arguments.Is_Empty
      then
         return User_Build_Context_Rejected_Missing_Request;
      end if;

      if not Gate.Allow_Build_Run
        and then Gate.Process_Policy.Mode = Process_Execution_Disabled
        and then not Gate.Process_Policy.Allow_Real_Execution
      then
         return User_Build_Context_Rejected_Missing_Gate;
      end if;

      if Gate.Consent = Build_Consent_Not_Provided then
         return User_Build_Context_Rejected_Missing_Consent;
      elsif Gate.Consent /= Build_Consent_User_Confirmed then
         return User_Build_Context_Rejected_Missing_Consent;
      end if;

      case Request.Provenance is
         when Build_Request_From_User_Opt_In =>
            null;
         when Build_Request_From_Implicit_Source =>
            return User_Build_Context_Rejected_Implicit_Source;
         when Build_Request_From_Test
            | Build_Request_From_Fixture
            | Build_Request_From_Internal_Command
            | Build_Request_Unknown =>
            return User_Build_Context_Rejected_Provenance;
      end case;

      case Request.Tool is
         when No_Build_Tool | Custom_Build_Tool =>
            return User_Build_Context_Rejected_Custom_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
      end case;

      if Length (Request.Arguments) > 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Request.Structured_Arguments.Is_Empty or else Clean_Command'Length = 0 then
         return User_Build_Context_Rejected_Opaque_Arguments;
      end if;

      if Gate.Process_Policy.Allow_Shell then
         return User_Build_Context_Rejected_Shell;
      end if;

      if Ada.Strings.Fixed.Trim
          (To_String (Request.Working_Label), Both)'Length > 0
      then
         return User_Build_Context_Rejected_Working_Context;
      end if;

      if Gate.Allow_Real_Build_Tool_Fixture
        or else not Gate.Allow_Real_Build_Tool_Execution
        or else Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
        or else not Gate.Process_Policy.Allow_Real_Execution
        or else Gate.Process_Policy.Max_Output_Bytes = 0
        or else not Validate_Build_Execution_Gate (Gate)
      then
         return User_Build_Context_Rejected_Ambiguous_Execution_Path;
      end if;

      return User_Build_Context_Valid;
   end Validate_User_Opt_In_Build_Command_Context;

   function User_Opt_In_Build_Command_Context_Is_Available
     (Context : User_Opt_In_Build_Command_Context) return Boolean
   is
   begin
      return Context.Has_Request;
   end User_Opt_In_Build_Command_Context_Is_Available;

   function User_Opt_In_Build_Preflight_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid
        or else Result.Process_Request_Status /= Process_Request_Valid
      then
         return not Result.Has_Process_Request;
      end if;

      return Result.Has_Process_Request
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Program_Label), Both)'Length > 0
        and then Ada.Strings.Fixed.Trim
          (To_String (Result.Process_Request.Arguments), Both)'Length = 0
        and then not Result.Process_Request.Structured_Arguments.Is_Empty;
   end User_Opt_In_Build_Preflight_Is_Consistent;

   procedure Assert_User_Opt_In_Build_Preflight_Consistent
     (Result : Build_Preflight_Result)
   is
   begin
      pragma Assert (User_Opt_In_Build_Preflight_Is_Consistent (Result));
   end Assert_User_Opt_In_Build_Preflight_Consistent;

   function Build_Preflight_Result_Is_Consistent
     (Result : Build_Preflight_Result) return Boolean
   is
   begin
      if Result.Build_Request_Status /= Build_Request_Valid then
         return not Result.Has_Process_Request
           and then Result.Process_Request_Status /= Process_Request_Valid;
      end if;

      if Result.Process_Request_Status = Process_Request_Valid then
         return Result.Has_Process_Request;
      end if;

      return not Result.Has_Process_Request;
   end Build_Preflight_Result_Is_Consistent;


end Editor.External_Producers.Build_Command_Execution.Preflight;
