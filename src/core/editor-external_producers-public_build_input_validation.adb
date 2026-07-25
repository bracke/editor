with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits;
with Editor.External_Producers.Request_Policies;


with Editor.External_Producers.Build_Types; use Editor.External_Producers.Build_Types;

with Editor.External_Producers.Public_Build_Types;
package body Editor.External_Producers.Public_Build_Input_Validation is

   use type Editor.Commands.Descriptors.Command_Visibility;
   use type Editor.Commands.Descriptors.Command_Category;
   use Editor.External_Producers.Request_Policies;

   function Contains_Control_Character (Value : String) return Boolean is
   begin
      for Ch of Value loop
         if Character'Pos (Ch) < 32 or else Character'Pos (Ch) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control_Character;

   function Contains_Shell_Syntax (Value : String) return Boolean is
   begin
      for Ch of Value loop
         case Ch is
            when ';' | '|' | '&' | '>' | '<' | '`' | '$' | '(' | ')' | '\' =>
               return True;
            when others =>
               null;
         end case;
      end loop;
      return False;
   end Contains_Shell_Syntax;

   function Contains_Path_Separator (Value : String) return Boolean is
   begin
      for Ch of Value loop
         if Ch = '/' or else Ch = '\' then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Path_Separator;

   function Looks_Project_Derived_Label (Value : String) return Boolean is
      Clean : constant String := Ada.Strings.Fixed.Trim (Value, Both);
   begin
      return Clean'Length >= 8
        and then (Clean (Clean'First .. Clean'First + 7) = "project:"
                  or else Clean (Clean'First .. Clean'First + 7) = "Project:");
   end Looks_Project_Derived_Label;

   function Looks_Path_Like_Label (Value : String) return Boolean is
      Clean : constant String := Ada.Strings.Fixed.Trim (Value, Both);
   begin
      if Contains_Path_Separator (Clean) then
         return True;
      end if;

      return Clean'Length >= 2
        and then Clean (Clean'First + 1) = ':';
   end Looks_Path_Like_Label;

   function Validate_Public_Build_Consent
     (Consent : Public_Build_Consent_Model)
      return Public_Build_Consent_Validation_Status
   is
   begin
      if Consent.Source = Public_Build_Consent_None then
         return Public_Build_Consent_Rejected_None;
      elsif not Consent.User_Acknowledged_Execution then
         return Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement;
      elsif not Consent.User_Acknowledged_No_Shell then
         return Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement;
      elsif not Consent.User_Acknowledged_External_Process then
         return Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement;
      elsif not Consent.User_Acknowledged_Diagnostics_Output then
         return Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement;
      end if;

      case Consent.Source is
         when Public_Build_Consent_Test_Context =>
            return Public_Build_Consent_Valid_For_Internal_Test;
         when Public_Build_Consent_User_Form_Acknowledged =>
            return Public_Build_Consent_Valid_But_Not_Public_UX;
         when Public_Build_Consent_None =>
            return Public_Build_Consent_Rejected_None;
      end case;
   end Validate_Public_Build_Consent;

   function Classify_Public_Build_Consent_Safety
     (Consent : Public_Build_Consent_Model) return Public_Build_Input_Safety
   is
   begin
      case Validate_Public_Build_Consent (Consent) is
         when Public_Build_Consent_Valid_For_Internal_Test =>
            return Public_Build_Input_Valid_For_Internal_Test;
         when Public_Build_Consent_Valid_But_Not_Public_UX =>
            return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
         when others =>
            return Public_Build_Input_Not_Valid;
      end case;
   end Classify_Public_Build_Consent_Safety;

   function Build_Execution_Consent_From_Public_Model
     (Consent : Public_Build_Consent_Model) return Build_Execution_Consent
   is
   begin
      case Validate_Public_Build_Consent (Consent) is
         when Public_Build_Consent_Valid_For_Internal_Test
            | Public_Build_Consent_Valid_But_Not_Public_UX =>
            return Build_Consent_User_Confirmed;
         when others =>
            return Build_Consent_Not_Provided;
      end case;
   end Build_Execution_Consent_From_Public_Model;

   function Build_Public_Build_Consent_Feedback
     (Status : Public_Build_Consent_Validation_Status) return String
   is
   begin
      case Status is
         when Public_Build_Consent_Valid_For_Internal_Test =>
            return "Build: public consent UX not ready";
         when Public_Build_Consent_Valid_But_Not_Public_UX =>
            return "Build: public consent UX not ready";
         when Public_Build_Consent_Rejected_None =>
            return "Build: execution consent required";
         when Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement =>
            return "Build: execution acknowledgement required";
         when Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement =>
            return "Build: no-shell acknowledgement required";
         when Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement =>
            return "Build: external process acknowledgement required";
         when Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement =>
            return "Build: diagnostics acknowledgement required";
      end case;
   end Build_Public_Build_Consent_Feedback;

   function Audit_Public_Build_Consent_Readiness return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits.Audit_Public_Build_Consent_Readiness;

   function Validate_Public_Build_Working_Context
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Working_Context_Validation_Status
   is
      Clean_Label : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Context.Label), Both);
   begin
      case Context.Source is
         when Public_Build_Working_Context_None =>
            return Public_Build_Working_Context_Rejected_None;

         when Public_Build_Working_Context_Project_Derived =>
            return Public_Build_Working_Context_Rejected_Project_Derived;

         when Public_Build_Working_Context_Test_Context =>
            return Public_Build_Working_Context_Valid_For_Internal_Test;

         when Public_Build_Working_Context_User_Form_Label =>
            if Clean_Label'Length = 0 then
               return Public_Build_Working_Context_Rejected_Missing_Label;
            elsif not Context.User_Acknowledged_Context then
               return Public_Build_Working_Context_Rejected_Missing_Acknowledgement;
            elsif Contains_Control_Character (Clean_Label)
              or else Contains_Shell_Syntax (Clean_Label)
              or else Looks_Project_Derived_Label (Clean_Label)
              or else Looks_Path_Like_Label (Clean_Label)
            then
               return Public_Build_Working_Context_Rejected_Unsafe_Label;
            elsif Clean_Label = "current-project-root"
              or else Clean_Label = "active-workspace-root"
              or else Clean_Label = "test-fixture-context"
            then
               return Public_Build_Working_Context_Valid_But_Not_Public_UX;
            else
               return Public_Build_Working_Context_Rejected_Unsafe_Label;
            end if;
      end case;
   end Validate_Public_Build_Working_Context;

   function Classify_Public_Build_Working_Context_Safety
     (Context : Public_Build_Working_Context_Model)
      return Public_Build_Input_Safety
   is
   begin
      case Validate_Public_Build_Working_Context (Context) is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return Public_Build_Input_Valid_For_Internal_Test;
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
         when others =>
            return Public_Build_Input_Not_Valid;
      end case;
   end Classify_Public_Build_Working_Context_Safety;

   function Build_Working_Context_From_Public_Model
     (Context : Public_Build_Working_Context_Model) return Build_Working_Context
   is
   begin
      case Validate_Public_Build_Working_Context (Context) is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return Build_Inherited_Test_Working_Context;
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return Build_Explicit_Label_Working_Context
              (Ada.Strings.Fixed.Trim (To_String (Context.Label), Both));
         when others =>
            return Build_Unsupported_Working_Context;
      end case;
   end Build_Working_Context_From_Public_Model;

   function Assert_Public_Build_Working_Context_Conversion_Consistent
     (Model   : Public_Build_Working_Context_Model;
      Context : Build_Working_Context) return Boolean
   is
      Status : constant Public_Build_Working_Context_Validation_Status :=
        Validate_Public_Build_Working_Context (Model);
   begin
      case Status is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return Context.Kind = Build_Working_Context_Inherited_Test_Context
              and then To_String (Context.Label)'Length = 0;
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return Context.Kind = Build_Working_Context_Explicit_Label
              and then Ada.Strings.Fixed.Trim
                (To_String (Context.Label), Both)'Length > 0;
         when others =>
            return Context.Kind = Build_Working_Context_Unsupported;
      end case;
   end Assert_Public_Build_Working_Context_Conversion_Consistent;

   function Build_Public_Build_Working_Context_Feedback
     (Status : Public_Build_Working_Context_Validation_Status) return String
   is
   begin
      case Status is
         when Public_Build_Working_Context_Valid_For_Internal_Test =>
            return "Build: accepted";
         when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
            return "Build: public working directory UX not ready";
         when Public_Build_Working_Context_Rejected_None =>
            return "Build: working context required";
         when Public_Build_Working_Context_Rejected_Project_Derived =>
            return "Build: project working context not supported";
         when Public_Build_Working_Context_Rejected_Missing_Label =>
            return "Build: working directory label required";
         when Public_Build_Working_Context_Rejected_Missing_Acknowledgement =>
            return "Build: working directory acknowledgement required";
         when Public_Build_Working_Context_Rejected_Unsafe_Label =>
            return "Build: working directory unsupported";
      end case;
   end Build_Public_Build_Working_Context_Feedback;

   function Audit_Public_Build_Working_Context_Readiness return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits.Audit_Public_Build_Working_Context_Readiness;

   function Validate_Public_Build_Program_Label
     (Program_Label : Unbounded_String)
      return Public_Build_Input_Validation_Status
   is
      Program : constant String :=
        Ada.Strings.Fixed.Trim (To_String (Program_Label), Both);
   begin
      if Program'Length = 0 then
         return Public_Build_Input_Rejected_Missing_Program;
      elsif Contains_Control_Character (Program) then
         return Public_Build_Input_Rejected_Missing_Program;
      elsif Contains_Shell_Syntax (Program) then
         return Public_Build_Input_Rejected_Shell;
      end if;

      return Public_Build_Input_Valid;
   end Validate_Public_Build_Program_Label;

   function Validate_Public_Build_Working_Context
     (Source  : Public_Build_Input_Source;
      Context : Build_Working_Context)
      return Public_Build_Input_Validation_Status
   is
      Label : constant String := To_String (Context.Label);
      Clean : constant String := Ada.Strings.Fixed.Trim (Label, Both);
   begin
      case Context.Kind is
         when Build_Working_Context_Unsupported =>
            return Public_Build_Input_Rejected_Unsupported_Working_Context;

         when Build_Working_Context_Inherited_Test_Context =>
            if Source = Public_Build_Input_Test_Context then
               return Public_Build_Input_Valid;
            end if;
            return Public_Build_Input_Rejected_Unsupported_Working_Context;

         when Build_Working_Context_Explicit_Label =>
            if Clean'Length = 0 then
               return Public_Build_Input_Rejected_Unsupported_Working_Context;
            elsif Contains_Control_Character (Label) then
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            elsif Looks_Project_Derived_Label (Label) then
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            elsif Source = Public_Build_Input_Test_Context then
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            else
               return Public_Build_Input_Valid;
            end if;
      end case;
   end Validate_Public_Build_Working_Context;

   function Validate_Public_Build_Arguments
     (Source    : Public_Build_Input_Source;
      Arguments : Process_Argument_Vector)
      return Public_Build_Input_Validation_Status
   is
      pragma Unreferenced (Source);
   begin
      if Arguments.Is_Empty then
         return Public_Build_Input_Rejected_Opaque_Arguments;
      end if;

      for Arg of Arguments loop
         declare
            Text : constant String := To_String (Arg);
         begin
            if Text'Length = 0 then
               return Public_Build_Input_Rejected_Empty_Argument;
            elsif Ada.Strings.Fixed.Trim (Text, Both)'Length = 0 then
               return Public_Build_Input_Rejected_Empty_Argument;
            elsif Contains_Control_Character (Text) then
               return Public_Build_Input_Rejected_Control_Argument;
            end if;
         end;
      end loop;

      return Public_Build_Input_Valid;
   end Validate_Public_Build_Arguments;

   function Validate_Public_Build_Command_Input
     (Input : Public_Build_Command_Input)
      return Public_Build_Input_Validation_Status
   is
      Status : Public_Build_Input_Validation_Status;
   begin
      if Input.Source = Public_Build_Input_None then
         return Public_Build_Input_Rejected_No_Input;
      end if;

      case Input.Tool is
         when No_Build_Tool =>
            return Public_Build_Input_Rejected_No_Tool;
         when Custom_Build_Tool =>
            return Public_Build_Input_Rejected_Custom_Tool;
         when GPRbuild_Tool | Alire_Build_Tool =>
            null;
      end case;

      Status := Validate_Public_Build_Program_Label (Input.Program_Label);
      if Status /= Public_Build_Input_Valid then
         return Status;
      end if;

      if Input.Consent = Build_Consent_Test_Only then
         return Public_Build_Input_Rejected_Test_Only_Consent;
      end if;

      declare
         Consent_Status : constant Public_Build_Consent_Validation_Status :=
           Validate_Public_Build_Consent (Input.Consent_Model);
      begin
         case Consent_Status is
            when Public_Build_Consent_Valid_For_Internal_Test =>
               if Input.Source /= Public_Build_Input_Test_Context then
                  return Public_Build_Input_Rejected_Public_Not_Ready;
               end if;
            when Public_Build_Consent_Valid_But_Not_Public_UX =>
               if Input.Source = Public_Build_Input_Test_Context then
                  return Public_Build_Input_Rejected_Missing_Consent;
               end if;
            when Public_Build_Consent_Rejected_None =>
               return Public_Build_Input_Rejected_Missing_Consent;
            when others =>
               return Public_Build_Input_Rejected_Missing_Consent;
         end case;
      end;

      if Input.Source = Public_Build_Input_Test_Context
        and then Input.Consent /=
          Build_Execution_Consent_From_Public_Model (Input.Consent_Model)
      then
         return Public_Build_Input_Rejected_Missing_Consent;
      end if;

      declare
         Working_Status : constant Public_Build_Working_Context_Validation_Status :=
           Validate_Public_Build_Working_Context (Input.Working_Context_Model);
      begin
         case Working_Status is
            when Public_Build_Working_Context_Valid_For_Internal_Test =>
               if Input.Source /= Public_Build_Input_Test_Context
                 or else Input.Working_Context.Kind /=
                   Build_Working_Context_Inherited_Test_Context
               then
                  return Public_Build_Input_Rejected_Unsupported_Working_Context;
               end if;
            when Public_Build_Working_Context_Valid_But_Not_Public_UX =>
               if Input.Source = Public_Build_Input_Test_Context then
                  return Public_Build_Input_Rejected_Unsupported_Working_Context;
               end if;
               null;
            when Public_Build_Working_Context_Rejected_None =>
               return Public_Build_Input_Rejected_Unsupported_Working_Context;
            when Public_Build_Working_Context_Rejected_Project_Derived =>
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
            when Public_Build_Working_Context_Rejected_Missing_Label =>
               return Public_Build_Input_Rejected_Unsupported_Working_Context;
            when Public_Build_Working_Context_Rejected_Missing_Acknowledgement
               | Public_Build_Working_Context_Rejected_Unsafe_Label =>
               return Public_Build_Input_Rejected_Unsafe_Working_Context;
         end case;
      end;

      Status := Validate_Public_Build_Arguments (Input.Source, Input.Arguments);
      if Status /= Public_Build_Input_Valid then
         return Status;
      end if;

      return Public_Build_Input_Valid;
   end Validate_Public_Build_Command_Input;

   function Classify_Public_Build_Input_Safety
     (Input : Public_Build_Command_Input) return Public_Build_Input_Safety
   is
      Status : constant Public_Build_Input_Validation_Status :=
        Validate_Public_Build_Command_Input (Input);
   begin
      if Status = Public_Build_Input_Valid then
         if Input.Source = Public_Build_Input_Test_Context then
            return Public_Build_Input_Valid_For_Internal_Test;
         else
            return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
         end if;
      end if;

      if Input.Source = Public_Build_Input_User_Form
        and then Status = Public_Build_Input_Rejected_Public_Not_Ready
      then
         return Public_Build_Input_Valid_But_Not_Publicly_Exposable;
      end if;

      return Public_Build_Input_Not_Valid;
   end Classify_Public_Build_Input_Safety;

   function Build_User_Opt_In_Request_From_Public_Input
     (Input : Public_Build_Command_Input) return Build_Run_Request
   is
      Status : constant Public_Build_Input_Validation_Status :=
        Validate_Public_Build_Command_Input (Input);
      Working_Label : constant String := "";
   begin
      if Status /= Public_Build_Input_Valid
        or else Input.Source /= Public_Build_Input_Test_Context
        or else Build_Execution_Consent_From_Public_Model (Input.Consent_Model) /=
          Build_Consent_User_Confirmed
        or else Build_Working_Context_From_Public_Model
          (Input.Working_Context_Model).Kind /=
          Build_Working_Context_Inherited_Test_Context
      then
         return
           (Tool                 => No_Build_Tool,
            Provenance           => Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Empty_Process_Arguments);
      end if;

      return Build_User_Opt_In_Request
        (Tool          => Input.Tool,
         Program_Label => To_String (Input.Program_Label),
         Working_Label => Working_Label,
         Arguments     => Input.Arguments);
   end Build_User_Opt_In_Request_From_Public_Input;

   function Build_Public_Build_Request_From_UI_State
     (Input : Public_Build_Command_Input) return Build_Run_Request
   is
      Status : constant Public_Build_Input_Validation_Status :=
        Validate_Public_Build_Command_Input (Input);
      Context : constant Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Input.Working_Context_Model);
      Working_Label : constant String :=
        (if Context.Kind = Build_Working_Context_Explicit_Label then
            To_String (Context.Label)
         else
            "");
   begin
      if Status /= Public_Build_Input_Valid
        or else Input.Source /= Public_Build_Input_User_Form
        or else Input.Consent /= Build_Consent_User_Confirmed
        or else Build_Execution_Consent_From_Public_Model (Input.Consent_Model) /=
          Build_Consent_User_Confirmed
        or else Context.Kind /= Build_Working_Context_Explicit_Label
      then
         return
           (Tool                 => No_Build_Tool,
            Provenance           => Build_Request_Unknown,
            Working_Label        => Null_Unbounded_String,
            Command_Label        => Null_Unbounded_String,
            Arguments            => Null_Unbounded_String,
            Structured_Arguments => Empty_Process_Arguments);
      end if;

      return Build_User_Opt_In_Request
        (Tool          => Input.Tool,
         Program_Label => To_String (Input.Program_Label),
         Working_Label => Working_Label,
         Arguments     => Input.Arguments);
   end Build_Public_Build_Request_From_UI_State;

   function Build_Public_Build_Input_Feedback
     (Status : Public_Build_Input_Validation_Status) return String
   is
   begin
      case Status is
         when Public_Build_Input_Valid =>
            return "Build: accepted";
         when Public_Build_Input_Rejected_No_Input =>
            return "Build: input required";
         when Public_Build_Input_Rejected_Public_Not_Ready =>
            return "Build: public build command not ready";
         when Public_Build_Input_Rejected_No_Tool =>
            return "Build: build tool required";
         when Public_Build_Input_Rejected_Custom_Tool =>
            return "Build: custom build tool not supported";
         when Public_Build_Input_Rejected_Missing_Program =>
            return "Build: program required";
         when Public_Build_Input_Rejected_Missing_Consent
            | Public_Build_Input_Rejected_Test_Only_Consent =>
            return "Build: execution consent required";
         when Public_Build_Input_Rejected_Unsupported_Working_Context
            | Public_Build_Input_Rejected_Unsafe_Working_Context =>
            return "Build: working directory unsupported";
         when Public_Build_Input_Rejected_Empty_Argument
            | Public_Build_Input_Rejected_Control_Argument
            | Public_Build_Input_Rejected_Opaque_Arguments =>
            return "Build: structured arguments required";
         when Public_Build_Input_Rejected_Shell =>
            return "Build: shell execution disabled";
      end case;
   end Build_Public_Build_Input_Feedback;

   function Audit_Public_Build_Input_Model_Readiness return Boolean
     renames Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits.Audit_Public_Build_Input_Model_Readiness;

   function Run_Public_Build_Command_Readiness_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Readiness_Audit_Result
     renames Editor.External_Producers.Public_Build_Input_Validation.Readiness_Audits.Run_Public_Build_Command_Readiness_Audit;

end Editor.External_Producers.Public_Build_Input_Validation;
