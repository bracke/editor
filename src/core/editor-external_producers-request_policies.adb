with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Working_Context;
with Editor.External_Producers.Public_Build_Input_Validation;

package body Editor.External_Producers.Request_Policies is

   use Editor.Build_Working_Context;

   function Contains_Control_Character (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Control_Character;

   function Contains_Shell_Syntax (Value : String) return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Contains_Shell_Syntax;

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status
   is
      Clean_Command : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Command_Label), Both);
   begin
      case Request.Tool is
         when No_Build_Tool =>
            return Build_Request_Rejected_No_Tool;
         when Custom_Build_Tool =>
            return Build_Request_Rejected_Unsupported_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            if Clean_Command'Length = 0 then
               return Build_Request_Rejected_Empty_Command;
            end if;

            return Build_Request_Valid;
      end case;
   exception
      when Constraint_Error =>
         return Build_Request_Rejected_Unsupported_Tool;
   end Validate_Build_Run_Request_Status;

   function Validate_Build_Run_Request
     (Request : Build_Run_Request) return Boolean
   is
   begin
      return Validate_Build_Run_Request_Status (Request) = Build_Request_Valid;
   end Validate_Build_Run_Request;

   function Validate_User_Opt_In_Build_Request
     (Request : Build_Run_Request) return Build_Request_Validation_Status
   is
      Status : constant Build_Request_Validation_Status :=
        Validate_Build_Run_Request_Status (Request);
   begin
      if Request.Provenance = Build_Request_From_Implicit_Source then
         return Build_Request_Rejected_Implicit_Source;
      elsif Request.Provenance = Build_Request_Unknown then
         return Build_Request_Rejected_Unknown_Provenance;
      elsif Request.Provenance /= Build_Request_From_User_Opt_In then
         return Build_Request_Rejected_Provenance;
      elsif Status /= Build_Request_Valid then
         return Status;
      else
         return Build_Request_Valid;
      end if;
   end Validate_User_Opt_In_Build_Request;

   function Build_Request_Rejection_Feedback
     (Status : Build_Request_Validation_Status) return String
   is
   begin
      case Status is
         when Build_Request_Valid =>
            return "Build: accepted";
         when Build_Request_Rejected_Unknown_Provenance
            | Build_Request_Rejected_Provenance =>
            return "Build: request provenance rejected";
         when Build_Request_Rejected_Implicit_Source =>
            return "Build: explicit build request required";
         when Build_Request_Rejected_Consent =>
            return "Build: execution consent required";
         when Build_Request_Rejected_Unsupported_Tool =>
            return "Build: custom build tool not supported";
         when Build_Request_Rejected_No_Tool
            | Build_Request_Rejected_Empty_Command =>
            return "Build: rejected";
      end case;
   end Build_Request_Rejection_Feedback;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      if First'Length > 0 or else Second'Length > 0 or else Third'Length > 0 then
         Append_Process_Argument (Args, First);
      end if;

      if Second'Length > 0 or else Third'Length > 0 then
         Append_Process_Argument (Args, Second);
      end if;

      if Third'Length > 0 then
         Append_Process_Argument (Args, Third);
      end if;

      return Args;
   end Build_Process_Argument_Vector;

   function Build_One_Process_Argument
     (Value : String) return Process_Argument_Vector
   is
      Args : Process_Argument_Vector := Empty_Process_Arguments;
   begin
      Append_Process_Argument (Args, Value);
      return Args;
   end Build_One_Process_Argument;

   function Build_Unsupported_Working_Context return Build_Working_Context
   is
   begin
      return
        (Kind  => Build_Working_Context_Unsupported,
         Label => Null_Unbounded_String);
   end Build_Unsupported_Working_Context;

   function Build_Inherited_Test_Working_Context return Build_Working_Context
   is
   begin
      return
        (Kind  => Build_Working_Context_Inherited_Test_Context,
         Label => Null_Unbounded_String);
   end Build_Inherited_Test_Working_Context;

   function Build_Explicit_Label_Working_Context
     (Label : String) return Build_Working_Context
   is
   begin
      return
        (Kind  => Build_Working_Context_Explicit_Label,
         Label => To_Unbounded_String (Label));
   end Build_Explicit_Label_Working_Context;

   function Validate_Build_Request_Provenance
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Build_Request_Validation_Status
   is
   begin
      case Request.Provenance is
         when Build_Request_Unknown =>
            return Build_Request_Rejected_Unknown_Provenance;
         when Build_Request_From_Implicit_Source =>
            return Build_Request_Rejected_Implicit_Source;
         when Build_Request_From_Test | Build_Request_From_Fixture =>
            if Gate.Process_Policy.Mode = Process_Execution_Test_Fixture
              or else Gate.Process_Policy.Mode = Process_Execution_Real_Fixture_Allowed
            then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_Internal_Command =>
            if Gate.Allow_Build_Run
              and then not Gate.Allow_Real_Build_Tool_Execution
              and then Gate.Process_Policy.Mode /= Process_Execution_Real_Allowed
            then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
         when Build_Request_From_User_Opt_In =>
            if Gate.Allow_Build_Run
              and then Gate.Allow_Real_Build_Tool_Execution
              and then Gate.Process_Policy.Mode = Process_Execution_Real_Allowed
            then
               return Build_Request_Valid;
            end if;
            return Build_Request_Rejected_Provenance;
      end case;
   end Validate_Build_Request_Provenance;

   function Validate_Build_Working_Context
     (Request : Build_Run_Request;
      Gate    : Build_Execution_Gate) return Process_Request_Validation_Status
   is
      Clean_Working : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Working_Label), Both);
   begin
      if Gate.Allow_Real_Build_Tool_Execution then
         if Clean_Working'Length > 0 then
            return Process_Request_Rejected_Unsupported_Working_Directory;
         end if;
      elsif Gate.Allow_Real_Build_Tool_Fixture
        and then Clean_Working'Length > 0
      then
         return Process_Request_Rejected_Unsupported_Working_Directory;
      end if;

      return Process_Request_Valid;
   end Validate_Build_Working_Context;

   function Prepare_Process_Request
     (Request : Build_Run_Request) return Process_Run_Request
   is
   begin
      case Request.Tool is
         when GPRbuild_Tool =>
            return
              (Program_Label        => To_Unbounded_String ("gprbuild"),
               Working_Label        => Request.Working_Label,
               Arguments            => Request.Arguments,
               Structured_Arguments => Request.Structured_Arguments);
         when Alire_Build_Tool =>
            return
              (Program_Label        => To_Unbounded_String ("alr"),
               Working_Label        => Request.Working_Label,
               Arguments            => Request.Arguments,
               Structured_Arguments => Request.Structured_Arguments);
         when No_Build_Tool | Custom_Build_Tool =>
            return
              (Program_Label        => Null_Unbounded_String,
               Working_Label        => Request.Working_Label,
               Arguments            => Null_Unbounded_String,
               Structured_Arguments => Empty_Process_Arguments);
      end case;
   end Prepare_Process_Request;

   function Build_Process_Run_Result
     (Status        : Process_Run_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False;
      Stdout_Text   : String := "";
      Stderr_Text   : String := "";
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Capture_Mode : Process_Output_Capture_Mode :=
        Process_Output_Capture_Separated) return Process_Run_Result
   is
   begin
      return
        (Status        => Status,
         Output_Capture_Mode =>
           (if Stdout_Text'Length = 0 and then Stderr_Text'Length = 0 then
               Process_Output_Capture_None
            else Output_Capture_Mode),
         Has_Exit_Code => Has_Exit_Code,
         Exit_Code     => Exit_Code,
         Stdout_Text   => To_Unbounded_String (Stdout_Text),
         Stderr_Text   => To_Unbounded_String (Stderr_Text),
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated);
   end Build_Process_Run_Result;

   function Execute_Process_Request_Default
     (Request : Process_Run_Request) return Process_Run_Result
   is
      pragma Unreferenced (Request);
   begin
      return Build_Process_Run_Result (Process_Run_Not_Available);
   end Execute_Process_Request_Default;

   function Empty_Process_Arguments return Process_Argument_Vector
   is
   begin
      return Process_Argument_Vectors.Empty_Vector;
   end Empty_Process_Arguments;

   procedure Append_Process_Argument
     (Arguments : in out Process_Argument_Vector;
      Value     : String)
   is
   begin
      Arguments.Append (To_Unbounded_String (Value));
   end Append_Process_Argument;

   function Process_Argument_Count
     (Arguments : Process_Argument_Vector) return Natural
   is
   begin
      return Natural (Arguments.Length);
   end Process_Argument_Count;

   function Build_Default_Timeout_Milliseconds return Natural is
   begin
      return 120_000;
   end Build_Default_Timeout_Milliseconds;

   function Build_Timeout_Policy_Is_Bounded
     (Policy : Process_Execution_Policy) return Boolean
   is
      Max_Build_Timeout_Milliseconds : constant Natural := 600_000;
   begin
      if Policy.Mode = Process_Execution_Disabled then
         return Policy.Timeout_Milliseconds = 0;
      end if;

      return Policy.Timeout_Milliseconds <= Max_Build_Timeout_Milliseconds;
   end Build_Timeout_Policy_Is_Bounded;

   function Validate_Process_Execution_Policy
     (Policy : Process_Execution_Policy) return Boolean
   is
   begin
      if Policy.Allow_Shell then
         return False;
      end if;

      if not Build_Timeout_Policy_Is_Bounded (Policy) then
         return False;
      end if;

      case Policy.Mode is
         when Process_Execution_Disabled =>
            return not Policy.Allow_Real_Execution;
         when Process_Execution_Test_Fixture =>
            return not Policy.Allow_Real_Execution;
         when Process_Execution_Real_Fixture_Allowed =>
            return Policy.Allow_Real_Execution;
         when Process_Execution_Real_Allowed =>
            return Policy.Allow_Real_Execution;
      end case;
   end Validate_Process_Execution_Policy;

   function Looks_Absolute_Program (Program : String) return Boolean
   is
   begin
      return Program'Length > 0
        and then (Program (Program'First) = '/'
          or else (Program'Length >= 3
            and then Program (Program'First + 1) = ':'
            and then (Program (Program'First + 2) = '\'
              or else Program (Program'First + 2) = '/')));
   end Looks_Absolute_Program;

   function Validate_Process_Run_Request_For_Real_Execution_Status
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy)
      return Process_Request_Validation_Status
   is
      Clean_Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Program_Label), Both);
      Opaque_Args : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Request.Arguments), Both);
   begin
      if Policy.Allow_Shell then
         return Process_Request_Rejected_Shell_Disallowed;
      end if;

      if not Validate_Process_Execution_Policy (Policy)
        or else Policy.Mode /= Process_Execution_Real_Allowed
        or else not Policy.Allow_Real_Execution
      then
         return Process_Request_Rejected_Execution_Disabled;
      end if;

      if Clean_Program'Length = 0 then
         return Process_Request_Rejected_Empty_Program;
      elsif Contains_Control_Character (Clean_Program)
        or else Contains_Shell_Syntax (Clean_Program)
      then
         return Process_Request_Rejected_Shell_Disallowed;
      elsif Clean_Program /= "gprbuild"
        and then Clean_Program /= "alr"
        and then not Looks_Absolute_Program (Clean_Program)
      then
         return Process_Request_Rejected_Empty_Program;
      end if;

      if Policy.Require_Absolute_Program
        and then not Looks_Absolute_Program (Clean_Program)
      then
         return Process_Request_Rejected_Relative_Program;
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
            elsif Contains_Shell_Syntax (Value) then
               return Process_Request_Rejected_Shell_Disallowed;
            end if;
         end;
      end loop;

      return Process_Request_Valid;
   end Validate_Process_Run_Request_For_Real_Execution_Status;

   function Validate_Process_Run_Request_For_Real_Execution
     (Request : Process_Run_Request;
      Policy  : Process_Execution_Policy) return Boolean
   is
   begin
      return Validate_Process_Run_Request_For_Real_Execution_Status
        (Request, Policy) = Process_Request_Valid;
   end Validate_Process_Run_Request_For_Real_Execution;

   function Process_Request_Rejection_Feedback
     (Status : Process_Request_Validation_Status) return String
   is
   begin
      case Status is
         when Process_Request_Valid =>
            return "Build: accepted";
         when Process_Request_Rejected_Execution_Disabled =>
            return "Build: execution disabled";
         when Process_Request_Rejected_Shell_Disallowed =>
            return "Build: shell execution disabled";
         when Process_Request_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Process_Request_Rejected_Unsupported_Working_Directory =>
            return "Build: working directory unsupported";
         when Process_Request_Rejected_Empty_Program
            | Process_Request_Rejected_Invalid_Argument
            | Process_Request_Rejected_Relative_Program =>
            return "Build: invalid process request";
      end case;
   end Process_Request_Rejection_Feedback;

end Editor.External_Producers.Request_Policies;
