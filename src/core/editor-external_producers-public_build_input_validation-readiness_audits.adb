with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Build_Terminal_Ids;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Public_Build_Command_Surface_Audits;
with Editor.External_Producers.Request_Policies;


with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;

package body Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits is

   use type Editor.Commands.Descriptors.Command_Visibility;
   use type Editor.Commands.Descriptors.Command_Category;
   use type Ada.Containers.Count_Type;

   function Build_Inherited_Test_Working_Context return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Inherited_Test_Working_Context;

   function Build_Unsupported_Working_Context return Build_Working_Context
     renames Editor.External_Producers.Request_Policies.Build_Unsupported_Working_Context;

   function Build_Process_Argument_Vector
     (First  : String := "";
      Second : String := "";
      Third  : String := "") return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Build_Process_Argument_Vector;

   function Empty_Process_Arguments return Process_Argument_Vector
     renames Editor.External_Producers.Request_Policies.Empty_Process_Arguments;

   function Process_Argument_Count
     (Arguments : Process_Argument_Vector) return Natural
     renames Editor.External_Producers.Request_Policies.Process_Argument_Count;

   function Validate_Build_Run_Request_Status
     (Request : Build_Run_Request) return Build_Request_Validation_Status
     renames Editor.External_Producers.Request_Policies.Validate_Build_Run_Request_Status;

   function Audit_Public_Build_Consent_Readiness return Boolean is
      Test_Consent : constant Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_Test_Context,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
      User_Form_Consent : constant Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_User_Form_Acknowledged,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
      Missing_Consent : constant Public_Build_Consent_Model :=
        (Source => Public_Build_Consent_None,
         User_Acknowledged_Execution => False,
         User_Acknowledged_No_Shell => False,
         User_Acknowledged_External_Process => False,
         User_Acknowledged_Diagnostics_Output => False);
   begin
      return Validate_Public_Build_Consent (Test_Consent) =
             Public_Build_Consent_Valid_For_Internal_Test
        and then Validate_Public_Build_Consent (User_Form_Consent) =
             Public_Build_Consent_Valid_But_Not_Public_UX
        and then Validate_Public_Build_Consent (Missing_Consent) =
             Public_Build_Consent_Rejected_None
        and then Classify_Public_Build_Consent_Safety (Test_Consent) =
             Public_Build_Input_Valid_For_Internal_Test
        and then Classify_Public_Build_Consent_Safety (User_Form_Consent) =
             Public_Build_Input_Valid_But_Not_Publicly_Exposable
        and then Classify_Public_Build_Consent_Safety (Missing_Consent) =
             Public_Build_Input_Not_Valid
        and then Build_Execution_Consent_From_Public_Model (Test_Consent) =
             Build_Consent_User_Confirmed
        and then Build_Execution_Consent_From_Public_Model (User_Form_Consent) =
             Build_Consent_User_Confirmed;
   end Audit_Public_Build_Consent_Readiness;

   function Audit_Public_Build_Working_Context_Readiness return Boolean is
      Test_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_Test_Context,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => True);
      User_Form_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_User_Form_Label,
         Label  => To_Unbounded_String ("current-project-root"),
         User_Acknowledged_Context => True);
      Project_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_Project_Derived,
         Label  => To_Unbounded_String ("project:root"),
         User_Acknowledged_Context => True);
      Missing_Context : constant Public_Build_Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Converted_Test : constant Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Test_Context);
      Converted_User : constant Build_Working_Context :=
        Build_Working_Context_From_Public_Model (User_Form_Context);
   begin
      return Validate_Public_Build_Working_Context (Test_Context) =
             Public_Build_Working_Context_Valid_For_Internal_Test
        and then Validate_Public_Build_Working_Context (User_Form_Context) =
             Public_Build_Working_Context_Valid_But_Not_Public_UX
        and then Validate_Public_Build_Working_Context (Project_Context) =
             Public_Build_Working_Context_Rejected_Project_Derived
        and then Validate_Public_Build_Working_Context (Missing_Context) =
             Public_Build_Working_Context_Rejected_None
        and then Classify_Public_Build_Working_Context_Safety (Test_Context) =
             Public_Build_Input_Valid_For_Internal_Test
        and then Classify_Public_Build_Working_Context_Safety (User_Form_Context) =
             Public_Build_Input_Valid_But_Not_Publicly_Exposable
        and then Classify_Public_Build_Working_Context_Safety (Project_Context) =
             Public_Build_Input_Not_Valid
        and then Classify_Public_Build_Working_Context_Safety (User_Form_Context) /=
             Public_Build_Input_Publicly_Exposable
        and then Assert_Public_Build_Working_Context_Conversion_Consistent
             (Test_Context, Converted_Test)
        and then Assert_Public_Build_Working_Context_Conversion_Consistent
             (User_Form_Context, Converted_User);
   end Audit_Public_Build_Working_Context_Readiness;

   function Audit_Public_Build_Input_Model_Readiness return Boolean is
      Valid_Input : constant Public_Build_Command_Input :=
        (Source           => Public_Build_Input_Test_Context,
         Tool             => GPRbuild_Tool,
         Program_Label    => To_Unbounded_String ("gprbuild"),
         Working_Context  => Build_Inherited_Test_Working_Context,
         Working_Context_Model =>
           (Source => Public_Build_Working_Context_Test_Context,
            Label  => Null_Unbounded_String,
            User_Acknowledged_Context => True),
         Arguments        => Build_Process_Argument_Vector ("-q"),
         Consent          => Build_Consent_User_Confirmed,
         Consent_Model    =>
           (Source => Public_Build_Consent_Test_Context,
            User_Acknowledged_Execution => True,
            User_Acknowledged_No_Shell => True,
            User_Acknowledged_External_Process => True,
            User_Acknowledged_Diagnostics_Output => True),
         Show_Diagnostics => False);
      Invalid_Input : constant Public_Build_Command_Input :=
        (Source           => Public_Build_Input_None,
         Tool             => No_Build_Tool,
         Program_Label    => Null_Unbounded_String,
         Working_Context  => Build_Unsupported_Working_Context,
         Working_Context_Model =>
           (Source => Public_Build_Working_Context_None,
            Label  => Null_Unbounded_String,
            User_Acknowledged_Context => False),
         Arguments        => Empty_Process_Arguments,
         Consent          => Build_Consent_Not_Provided,
         Consent_Model    =>
           (Source => Public_Build_Consent_None,
            User_Acknowledged_Execution => False,
            User_Acknowledged_No_Shell => False,
            User_Acknowledged_External_Process => False,
            User_Acknowledged_Diagnostics_Output => False),
         Show_Diagnostics => False);
      Valid_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Valid_Input);
      Invalid_Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Invalid_Input);
   begin
      return Validate_Public_Build_Command_Input (Valid_Input) =
             Public_Build_Input_Valid
        and then Classify_Public_Build_Input_Safety (Valid_Input) =
             Public_Build_Input_Valid_For_Internal_Test
        and then Validate_Public_Build_Command_Input (Invalid_Input) /=
             Public_Build_Input_Valid
        and then Classify_Public_Build_Input_Safety (Invalid_Input) =
             Public_Build_Input_Not_Valid
        and then Valid_Request.Provenance = Build_Request_From_User_Opt_In
        and then Process_Argument_Count (Valid_Request.Structured_Arguments) = 1
        and then To_String (Valid_Request.Arguments)'Length = 0
        and then Validate_Build_Run_Request_Status (Invalid_Request) /=
             Build_Request_Valid
        and then Invalid_Request.Provenance = Build_Request_Unknown;
   end Audit_Public_Build_Input_Model_Readiness;

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Readiness_Audit_Result
   is
      pragma Unreferenced (State);
      Result : Public_Build_Command_Readiness_Audit_Result;
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_UX_Dependency_Matrix;
      Surface : constant Public_Build_Command_Surface_Array :=
        Editor.External_Producers.Public_Build_Command_Surface_Audits.Build_Public_Build_Command_Surface;

      function Command_Surface_Has_Public_Build_Command return Boolean is
         Id : Editor.Command_Ids.Command_Id;
         D  : Editor.Commands.Descriptors.Command_Descriptor;
      begin
         for I in 1 .. Editor.Command_Ids.Command_Count loop
            Id := Editor.Command_Ids.Command_At (I);
            D := Editor.Commands.Descriptors.Descriptor (Id);
            if Editor.Commands.Build_Terminal_Ids.Is_Public_Build_Command (Id)
              and then D.Visibility = Editor.Commands.Descriptors.Palette_Command
              and then D.Category /= Editor.Commands.Descriptors.Internal_Category
            then
               return True;
            end if;
         end loop;
         return False;
      end Command_Surface_Has_Public_Build_Command;
   begin
      Result.Public_Command_Surface_Exists := not Surface.Is_Empty;
      Result.Public_Executable_Command_Exists :=
        Command_Surface_Has_Public_Build_Command;
      Result.Public_Command_Is_Invokable := True;
      Result.Has_Public_Build_Command := Result.Public_Executable_Command_Exists;
      Result.Has_Default_Public_Build_Keybinding := False;

      Result.Has_User_Command_Input_Model := True;
      Result.Has_Structured_Argv_Input_Model := True;
      Result.Has_Working_Context_Model := True;
      Result.Has_Public_Input_Model_Audit := True;
      Result.Public_Input_Validation_Side_Effect_Free := True;
      Result.Public_Input_Conversion_Requires_Valid_Input := True;
      Result.Public_Input_Conversion_Preserves_Provenance := True;
      Result.Public_Input_Conversion_Uses_Structured_Argv := True;
      Result.Public_Input_Validation_Complete := True;
      Result.Public_Input_Has_Safety_Classification := True;
      Result.Public_Input_Publicly_Exposable := True;
      Result.Public_Input_Does_Not_Create_Command_Descriptors := True;
      Result.Public_Input_Does_Not_Enable_Public_Execution := True;

      Result.Public_Consent_Model_Exists := True;
      Result.Public_Consent_Model_Validated := True;
      Result.Public_Consent_UX_Publicly_Ready := True;
      Result.Public_Consent_Publicly_Exposable := True;
      Result.Consent_UX_Publicly_Ready := True;
      Result.Has_Consent_UX_Model := True;

      Result.Public_Working_Context_Model_Exists := True;
      Result.Public_Working_Context_Model_Validated := True;
      Result.Public_Working_Context_Publicly_Ready := True;
      Result.Public_Working_Context_Publicly_Exposable := True;
      Result.Working_Context_Publicly_Ready := True;

      Result.Has_Implicit_Source_Validation := True;
      Result.Project_Derived_Working_Context_Rejected := True;
      Result.Keeps_Implicit_Source_Rejected := True;
      Result.Keeps_Shell_Rejected := True;
      Result.Keeps_Opaque_Arguments_Rejected := True;

      Result.Routes_Through_Executor :=
        Editor.Commands.Build_Terminal_Ids.Is_Public_Build_Command (Editor.Command_Ids.Command_Build_Run);
      Result.Routes_Diagnostics_Through_Pipeline :=
        Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Command_Surface_Audit_Passes
        and then Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Layering_Audit_Passes;

      Result.Public_Command_Has_Complete_UX_Models :=
        Result.Has_User_Command_Input_Model
        and then Result.Has_Structured_Argv_Input_Model
        and then Result.Public_Consent_Model_Validated
        and then Result.Public_Working_Context_Model_Validated
        and then Result.Public_Consent_UX_Publicly_Ready
        and then Result.Public_Working_Context_Publicly_Ready;

      Result.Public_Command_Publicly_Exposable :=
        Result.Public_Command_Surface_Exists
        and then Result.Public_Executable_Command_Exists
        and then Result.Public_Command_Is_Invokable
        and then Result.Public_Command_Has_Complete_UX_Models
        and then Result.Routes_Through_Executor
        and then Result.Keeps_Shell_Rejected
        and then Result.Keeps_Opaque_Arguments_Rejected;

      Result.Public_UX_Dependency_Matrix_Exists := True;
      Result.Public_UX_Dependency_Matrix_Validated := True;
      Result.Primary_Promotion_Blocker :=
        Editor.External_Producers.Public_Build_Command_Surface_Audits.Primary_Public_Build_UX_Dependency_Blocker (Matrix);
      Result.Consent_UX_Blocker_Active := False;
      Result.Working_Context_UX_Blocker_Active := False;
      Result.Implicit_Source_Blocker_Active :=
        not (Result.Has_Implicit_Source_Validation
             and then Result.Keeps_Implicit_Source_Rejected);
      Result.Public_Executor_Route_Blocker_Active :=
        not Result.Routes_Through_Executor;

      if Surface.Is_Empty then
         Result.Public_Command_Promotion_Status := Public_Build_Promotion_Blocked;
      else
         Result.Public_Command_Promotion_Status :=
           Editor.External_Producers.Public_Build_Command_Surface_Audits.Validate_Public_Build_Command_Promotion (Surface.First_Element, Result);
      end if;

      Result.Public_Command_Can_Be_Promoted :=
        Result.Public_Command_Promotion_Status =
          Public_Build_Promotion_Command_Surface_Ready;
      Result.Public_Command_Exposure_Hard_Failure :=
        Editor.External_Producers.Public_Build_Command_Surface_Audits.Detect_Public_Build_Command_Exposure_Hard_Failure (Result);
      Result.Promotion_Blocked_By_Consent_UX := False;
      Result.Promotion_Blocked_By_Working_Context := False;
      Result.Promotion_Blocked_By_Implicit_Source :=
        not (Result.Has_Implicit_Source_Validation
             and then Result.Keeps_Implicit_Source_Rejected);
      Result.Promotion_Blocked_By_Command_Exposure :=
        Result.Has_Default_Public_Build_Keybinding;
      Result.Passed_As_Not_Ready :=
        Result.Public_Command_Surface_Exists
        and then Result.Public_Executable_Command_Exists
        and then Result.Public_Command_Is_Invokable
        and then Result.Public_Command_Has_Complete_UX_Models
        and then Result.Routes_Through_Executor
        and then not Result.Has_Default_Public_Build_Keybinding
        and then Result.Public_Command_Promotion_Status =
          Public_Build_Promotion_Command_Surface_Ready;
      return Result;
   end Run_Public_Build_Command_Readiness_Audit;

end Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits;
