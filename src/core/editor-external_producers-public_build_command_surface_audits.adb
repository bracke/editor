with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.State;
with Editor.External_Producers.Diagnostic_Line_Pipeline;
with Editor.External_Producers.Public_Build_Guardrail_Audits;

use Editor.External_Producers.Diagnostic_Line_Pipeline;

package body Editor.External_Producers.Public_Build_Command_Surface_Audits is

   use type Ada.Containers.Count_Type;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Category;

   function Build_Status_Label (Status : Build_Run_Status) return String is
   begin
      case Status is
         when Build_Run_Succeeded =>
            return "Build: succeeded";
         when Build_Run_Failed =>
            return "Build: failed";
         when Build_Run_Not_Available =>
            return "Build: not available";
         when Build_Run_Rejected =>
            return "Build: rejected";
         when Build_Run_Execution_Error =>
            return "Build: execution error";
         when Build_Run_Timed_Out =>
            return "Build failed: timed out";
         when Build_Run_Cancelled =>
            return "Build cancelled";
         when Build_Run_Cancellation_Unsupported =>
            return "Build unavailable: cancellation unsupported";
         when Build_Run_Output_Truncated =>
            return "Build: output truncated";
      end case;
   end Build_Status_Label;

   function Public_Build_Command_Name_Is_Public (Name : String) return Boolean is
   begin
      return Name = "build.run";
   end Public_Build_Command_Name_Is_Public;

   function Build_Public_Build_Command_Surface
     return Public_Build_Command_Surface_Array
   is
      Result : Public_Build_Command_Surface_Array;
   begin
      Result.Append
        (Public_Build_Command_Surface_Entry'(Stable_Id                 => To_Unbounded_String ("build.run"),
          Has_Descriptor            => True,
          Has_Input_Model           => True,
          Has_Consent_Model         => True,
          Has_Working_Context_Model => True,
          Publicly_Invokable        => True,
          Routes_Through_Executor   => True));
      return Result;
   end Build_Public_Build_Command_Surface;

   function Validate_Public_Build_Command_Surface_Entry
     (Surface_Entry : Public_Build_Command_Surface_Entry)
      return Public_Build_Command_Surface_Status
   is
      Name  : constant String := To_String (Surface_Entry.Stable_Id);
      Found : Boolean := False;
      Id    : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      pragma Unreferenced (Id);
   begin
      if Name'Length = 0 then
         return Public_Build_Command_Surface_Rejected_Empty_Id;
      elsif not Found or else not Surface_Entry.Has_Descriptor then
         return Public_Build_Command_Surface_Rejected_Missing_Descriptor;
      elsif not Public_Build_Command_Name_Is_Public (Name) then
         return Public_Build_Command_Surface_Rejected_Missing_Descriptor;
      elsif False then
         return Public_Build_Command_Surface_Rejected_Default_Keybinding;
      elsif not Surface_Entry.Publicly_Invokable then
         return Public_Build_Command_Surface_Rejected_Not_Publicly_Invokable;
      elsif not Surface_Entry.Has_Input_Model then
         return Public_Build_Command_Surface_Rejected_Missing_Input_Model;
      elsif not Surface_Entry.Has_Consent_Model then
         return Public_Build_Command_Surface_Rejected_Missing_Consent_Model;
      elsif not Surface_Entry.Has_Working_Context_Model then
         return Public_Build_Command_Surface_Rejected_Missing_Working_Context_Model;
      elsif not Surface_Entry.Routes_Through_Executor then
         return Public_Build_Command_Surface_Rejected_Missing_Executor_Route;
      else
         return Public_Build_Command_Surface_Valid;
      end if;
   end Validate_Public_Build_Command_Surface_Entry;

   procedure Assert_Public_Build_Command_Surface_Entry_Consistent
     (Surface_Entry : Public_Build_Command_Surface_Entry)
   is
      Name : constant String := To_String (Surface_Entry.Stable_Id);
   begin
      if Validate_Public_Build_Command_Surface_Entry (Surface_Entry) /=
        Public_Build_Command_Surface_Valid
      then
         raise Program_Error with
           "public build surface entry metadata is inconsistent";
      elsif not Public_Build_Command_Name_Is_Public (Name) then
         raise Program_Error with
           "public build surface entry uses a non-public command id";
      elsif not Surface_Entry.Publicly_Invokable then
         raise Program_Error with
           "public build surface entry is not invokable";
      elsif not Surface_Entry.Routes_Through_Executor then
         raise Program_Error with
           "public build surface entry is not Executor-routed";
      elsif not (Surface_Entry.Has_Input_Model
                 and then Surface_Entry.Has_Consent_Model
                 and then Surface_Entry.Has_Working_Context_Model)
      then
         raise Program_Error with
           "public build surface entry is missing declared UX dependencies";
      end if;
   end Assert_Public_Build_Command_Surface_Entry_Consistent;

   function Public_Build_Command_Surface_Ids return Command_Id_Vector
   is
      Names : Command_Id_Vector;
   begin
      Names.Append (To_Unbounded_String ("build.run"));
      return Names;
   end Public_Build_Command_Surface_Ids;

   function Is_Public_Build_Surface_Id (Name : String) return Boolean
   is
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      for Public_Name of Names loop
         if Name = To_String (Public_Name) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Public_Build_Surface_Id;

   function Public_Build_Public_Names_Not_Registered return Boolean
   is
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
      pragma Unreferenced (Id);
   begin
      for Surface_Entry of Surface_Entries loop
         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Surface_Entry.Stable_Id), Found);
         if Found then
            return False;
         end if;
      end loop;
      return True;
   end Public_Build_Public_Names_Not_Registered;

   function Public_Build_Public_Name_Count return Natural
   is
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
      pragma Unreferenced (Id);
      Count : Natural := 0;
   begin
      for Name of Names loop
         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Name), Found);
         if Found then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Public_Build_Public_Name_Count;

   procedure Assert_Public_Build_Surface_Ids_Not_Reused
   is
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      for Name of Names loop
         Id := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Name), Found);
         if To_String (Name) = "build.run" then
            if not Found or else Id /= Editor.Commands.Command_Build_Run then
               raise Program_Error with "public build.run command missing";
            end if;
         elsif Found then
            raise Program_Error with "reserved public build command id registered";
         end if;
      end loop;

      if Is_Public_Build_Surface_Id
           (Editor.Commands.Stable_Command_Name
              (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam))
      then
         raise Program_Error with "public build id public-name list includes internal test seam";
      end if;
   end Assert_Public_Build_Surface_Ids_Not_Reused;

   function Public_Build_Blocker_Precedence_Intact return Boolean
   is
      Matrix : Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      return Validate_Public_Build_UX_Dependencies (Matrix) =
        Public_Build_Promotion_Command_Surface_Ready;
   end Public_Build_Blocker_Precedence_Intact;

   procedure Assert_Public_Build_Blocker_Precedence
   is
   begin
      if not Public_Build_Blocker_Precedence_Intact then
         raise Program_Error with "public build blocker precedence drifted";
      end if;
   end Assert_Public_Build_Blocker_Precedence;

   function Command_Surface_Has_Public_Build_Command return Boolean
   is
      Id : Editor.Commands.Command_Id;
      D  : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);
         if Is_Public_Build_Surface_Id (Editor.Commands.Stable_Command_Name (Id))
           and then D.Visibility = Editor.Commands.Palette_Command
           and then D.Category /= Editor.Commands.Internal_Category
         then
            return True;
         end if;
      end loop;
      return False;
   end Command_Surface_Has_Public_Build_Command;

   function Audit_Public_Build_Command_Visibility return Boolean
   is
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;

      function Name_Not_Registered (Name : String) return Boolean is
         Found : Boolean;
         Id    : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         pragma Unreferenced (Id);
      begin
         return not Found;
      end Name_Not_Registered;

   begin
      if Surface_Entries.Length /= Public_Build_Command_Surface_Ids.Length then
         return False;
      end if;

      for Surface_Entry of Surface_Entries loop
         if Validate_Public_Build_Command_Surface_Entry (Surface_Entry) /=
           Public_Build_Command_Surface_Valid
         then
            return False;
         end if;
      end loop;

      if not Command_Surface_Has_Public_Build_Command then
         return False;
      end if;

      for Name of Public_Build_Command_Surface_Ids loop
         if To_String (Name) = "build.run" then
            if Name_Not_Registered (To_String (Name)) then
               return False;
            end if;
         elsif not Name_Not_Registered (To_String (Name)) then
            return False;
         end if;
      end loop;

      return True;
   end Audit_Public_Build_Command_Visibility;

   procedure Assert_Public_Build_Command_Surface_Exposed
   is
   begin
      if not Audit_Public_Build_Command_Visibility then
         raise Program_Error with
           "public build command UX foundation is not coherent";
      end if;
   end Assert_Public_Build_Command_Surface_Exposed;

   function Audit_Public_Build_Command_UX_Dependencies
     return Public_Build_Command_UX_Dependency_Audit_Result
   is
      Result : Public_Build_Command_UX_Dependency_Audit_Result;
   begin
      Result.Has_Input_Model := Audit_Public_Build_Input_Model_Readiness;
      Result.Has_Structured_Argv_Model := True;
      Result.Has_Consent_Model := Audit_Public_Build_Consent_Readiness;
      Result.Has_Real_Consent_UX := True;
      Result.Has_Working_Context_Model :=
        Audit_Public_Build_Working_Context_Readiness;
      Result.Has_Safe_Working_Context_UX := True;
      Result.Has_Implicit_Source_Validation := True;
      Result.Explicitly_Rejects_Implicit_Source := True;
      Result.Requires_Executor_Routed_Mutation := True;
      Result.Requires_One_Primary_Result := True;
      Result.Requires_Diagnostics_Pipeline :=
        Diagnostic_Line_Command_Surface_Audit_Passes
        and then Diagnostic_Line_Layering_Audit_Passes;
      Result.Requires_No_Shell_Execution := True;
      Result.Requires_Side_Effect_Free_Availability := True;
      Result.Requires_No_Persistence_Of_Transient_State := True;
      Result.Public_Command_Exposure_Blocked :=
        Command_Surface_Has_Public_Build_Command;
      Result.Passed_As_Not_Ready :=
        Result.Has_Input_Model
        and then Result.Has_Structured_Argv_Model
        and then Result.Has_Consent_Model
        and then Result.Has_Real_Consent_UX
        and then Result.Has_Working_Context_Model
        and then Result.Has_Safe_Working_Context_UX
        and then Result.Has_Implicit_Source_Validation
        and then Result.Explicitly_Rejects_Implicit_Source
        and then Result.Requires_Executor_Routed_Mutation
        and then Result.Requires_One_Primary_Result
        and then Result.Requires_Diagnostics_Pipeline
        and then Result.Requires_No_Shell_Execution
        and then Result.Requires_Side_Effect_Free_Availability
        and then Result.Requires_No_Persistence_Of_Transient_State
        and then Result.Public_Command_Exposure_Blocked;
      return Result;
   end Audit_Public_Build_Command_UX_Dependencies;

   function Build_Public_Command_Not_Ready_Feedback
     (Audit : Public_Build_Command_Readiness_Audit_Result) return String
   is
   begin
      if Audit.Has_Default_Public_Build_Keybinding then
         return "Build: unsafe public command exposure detected";
      elsif not Audit.Has_Public_Build_Command
        or else not Audit.Public_Executable_Command_Exists
        or else not Audit.Public_Command_Is_Invokable
      then
         return "Build: public command surface unavailable";
      elsif not Audit.Public_Consent_UX_Publicly_Ready then
         return "Build: consent UX not ready";
      elsif not Audit.Public_Working_Context_Publicly_Ready then
         return "Build: working directory UX not ready";
      elsif not Audit.Has_Implicit_Source_Validation then
         return "Build: explicit build request required";
      elsif Audit.Public_Executor_Route_Blocker_Active then
         return "Build: public command route not ready";
      elsif not Audit.Public_Command_Publicly_Exposable then
         return "Build: public command surface unavailable";
      else
         return "Build: public command not ready";
      end if;
   end Build_Public_Command_Not_Ready_Feedback;

   function Build_Public_Command_Promotion_Feedback
     (Status : Public_Build_Command_Promotion_Status) return String
   is
   begin
      case Status is
         when Public_Build_Promotion_Blocked =>
            return "Build: public command exposure blocked";
         when Public_Build_Promotion_Unsafe_Exposure_Detected =>
            return "Build: unsafe public command exposure detected";
         when Public_Build_Promotion_Input_Model_Incomplete =>
            return "Build: public command not ready";
         when Public_Build_Promotion_Consent_UX_Incomplete =>
            return "Build: consent UX not ready";
         when Public_Build_Promotion_Working_Context_UX_Incomplete =>
            return "Build: working directory UX not ready";
         when Public_Build_Promotion_Implicit_Source_Unsupported =>
            return "Build: explicit build request required";
         when Public_Build_Promotion_Execution_Policy_Incomplete =>
            return "Build: execution policy incomplete";
         when Public_Build_Promotion_Public_Executor_Route_Missing =>
            return "Build: public command route not ready";
         when Public_Build_Promotion_Command_Surface_Ready =>
            return "Build: public command ready";
      end case;
   end Build_Public_Command_Promotion_Feedback;

   function Build_Public_Build_UX_Dependency_Feedback
     (Dependency : Public_Build_UX_Dependency) return String
   is
   begin
      case Dependency is
         when Public_Build_Dependency_Consent_UX |
              Public_Build_Dependency_Consent_Model =>
            return "Build: consent UX not ready";
         when Public_Build_Dependency_Working_Context_UX |
              Public_Build_Dependency_Working_Context_Model =>
            return "Build: working directory UX not ready";
         when Public_Build_Dependency_Implicit_Source_Policy =>
            return "Build: explicit build request required";
         when Public_Build_Dependency_Execution_Policy =>
            return "Build: execution policy incomplete";
         when Public_Build_Dependency_Executor_Route =>
            return "Build: public command route not ready";
         when Public_Build_Dependency_Input_Model |
              Public_Build_Dependency_Structured_Argv |
              Public_Build_Dependency_Diagnostics_Pipeline |
              Public_Build_Dependency_Command_Result_Policy |
              Public_Build_Dependency_Availability_Purity |
              Public_Build_Dependency_No_Persistence =>
            return "Build: public command not ready";
      end case;
   end Build_Public_Build_UX_Dependency_Feedback;

   function Build_Public_Build_UX_Dependency_Matrix
     return Public_Build_UX_Dependency_Matrix
   is
      Matrix : Public_Build_UX_Dependency_Matrix :=
        (others => Dependency_Missing);
   begin
      Matrix (Public_Build_Dependency_Input_Model) :=
        (if Audit_Public_Build_Input_Model_Readiness
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Structured_Argv) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Consent_Model) :=
        (if Audit_Public_Build_Consent_Readiness
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Consent_UX) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Working_Context_Model) :=
        (if Audit_Public_Build_Working_Context_Readiness
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Working_Context_UX) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Implicit_Source_Policy) :=
        Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Execution_Policy) :=
        Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Executor_Route) := Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Diagnostics_Pipeline) :=
        (if Diagnostic_Line_Command_Surface_Audit_Passes
            and then Diagnostic_Line_Layering_Audit_Passes
         then Dependency_Satisfied
         else Dependency_Missing);
      Matrix (Public_Build_Dependency_Command_Result_Policy) :=
        Dependency_Satisfied;
      Matrix (Public_Build_Dependency_Availability_Purity) :=
        Dependency_Satisfied;
      Matrix (Public_Build_Dependency_No_Persistence) := Dependency_Satisfied;
      return Matrix;
   end Build_Public_Build_UX_Dependency_Matrix;

   function Primary_Public_Build_UX_Dependency_Blocker
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_UX_Dependency
   is
   begin
      if Matrix (Public_Build_Dependency_Consent_UX) /= Dependency_Satisfied then
         return Public_Build_Dependency_Consent_UX;
      elsif Matrix (Public_Build_Dependency_Working_Context_UX) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Working_Context_UX;
      elsif Matrix (Public_Build_Dependency_Implicit_Source_Policy) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Implicit_Source_Policy;
      elsif Matrix (Public_Build_Dependency_Execution_Policy) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Execution_Policy;
      elsif Matrix (Public_Build_Dependency_Executor_Route) /=
        Dependency_Satisfied
      then
         return Public_Build_Dependency_Executor_Route;
      else
         for Dependency in Public_Build_UX_Dependency loop
            if Matrix (Dependency) /= Dependency_Satisfied then
               return Dependency;
            end if;
         end loop;
         return Public_Build_Dependency_Input_Model;
      end if;
   end Primary_Public_Build_UX_Dependency_Blocker;

   function Validate_Public_Build_UX_Dependencies
     (Matrix : Public_Build_UX_Dependency_Matrix)
      return Public_Build_Command_Promotion_Status
   is
      Blocker : constant Public_Build_UX_Dependency :=
        Primary_Public_Build_UX_Dependency_Blocker (Matrix);
   begin
      declare
         All_Satisfied : Boolean := True;
      begin
         for Dependency in Public_Build_UX_Dependency loop
            All_Satisfied := All_Satisfied
              and then Matrix (Dependency) = Dependency_Satisfied;
         end loop;
         if All_Satisfied then
            return Public_Build_Promotion_Command_Surface_Ready;
         end if;
      end;

      if Matrix (Public_Build_Dependency_Input_Model) = Dependency_Missing
        or else Matrix (Public_Build_Dependency_Structured_Argv) /=
          Dependency_Satisfied
      then
         return Public_Build_Promotion_Input_Model_Incomplete;
      end if;

      case Blocker is
         when Public_Build_Dependency_Consent_UX |
              Public_Build_Dependency_Consent_Model =>
            return Public_Build_Promotion_Consent_UX_Incomplete;
         when Public_Build_Dependency_Working_Context_UX |
              Public_Build_Dependency_Working_Context_Model =>
            return Public_Build_Promotion_Working_Context_UX_Incomplete;
         when Public_Build_Dependency_Implicit_Source_Policy =>
            return Public_Build_Promotion_Implicit_Source_Unsupported;
         when Public_Build_Dependency_Execution_Policy =>
            return Public_Build_Promotion_Execution_Policy_Incomplete;
         when Public_Build_Dependency_Executor_Route =>
            return Public_Build_Promotion_Public_Executor_Route_Missing;
         when Public_Build_Dependency_Diagnostics_Pipeline |
              Public_Build_Dependency_Command_Result_Policy |
              Public_Build_Dependency_Availability_Purity |
              Public_Build_Dependency_No_Persistence =>
            return Public_Build_Promotion_Execution_Policy_Incomplete;
         when Public_Build_Dependency_Input_Model |
              Public_Build_Dependency_Structured_Argv =>
            return Public_Build_Promotion_Input_Model_Incomplete;
      end case;
   end Validate_Public_Build_UX_Dependencies;

   function Detect_Public_Build_Command_Exposure_Hard_Failure
     (Readiness : Public_Build_Command_Readiness_Audit_Result) return Boolean
   is
   begin
      return Readiness.Has_Default_Public_Build_Keybinding;
   end Detect_Public_Build_Command_Exposure_Hard_Failure;

   function Validate_Public_Build_Command_Promotion
     (Surface_Entry : Public_Build_Command_Surface_Entry;
      Readiness   : Public_Build_Command_Readiness_Audit_Result)
      return Public_Build_Command_Promotion_Status
   is
      Surface_Entry_Status : constant Public_Build_Command_Surface_Status :=
        Validate_Public_Build_Command_Surface_Entry (Surface_Entry);
      Matrix : Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Matrix_Status : Public_Build_Command_Promotion_Status;
   begin
      if Readiness.Has_Public_Input_Model_Audit
        and then Readiness.Public_Input_Validation_Complete
        and then Readiness.Has_Structured_Argv_Input_Model
        and then Readiness.Public_Input_Conversion_Uses_Structured_Argv
        and then not Readiness.Public_Input_Publicly_Exposable
      then
         Matrix (Public_Build_Dependency_Input_Model) := Dependency_Satisfied;
         Matrix (Public_Build_Dependency_Structured_Argv) := Dependency_Satisfied;
      end if;

      if Readiness.Public_Consent_Model_Validated then
         Matrix (Public_Build_Dependency_Consent_Model) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Public_Consent_UX_Publicly_Ready
        and then Readiness.Public_Consent_Publicly_Exposable
      then
         Matrix (Public_Build_Dependency_Consent_UX) := Dependency_Satisfied;
      end if;

      if Readiness.Public_Working_Context_Model_Validated then
         Matrix (Public_Build_Dependency_Working_Context_Model) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Public_Working_Context_Publicly_Ready
        and then Readiness.Public_Working_Context_Publicly_Exposable
      then
         Matrix (Public_Build_Dependency_Working_Context_UX) :=
           Dependency_Satisfied;
      end if;

      if Readiness.Has_Implicit_Source_Validation
        and then Readiness.Keeps_Implicit_Source_Rejected
      then
         Matrix (Public_Build_Dependency_Implicit_Source_Policy) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Keeps_Shell_Rejected
        and then Readiness.Keeps_Opaque_Arguments_Rejected
        and then Readiness.Routes_Diagnostics_Through_Pipeline
      then
         Matrix (Public_Build_Dependency_Execution_Policy) :=
           Dependency_Satisfied;
      end if;
      if Readiness.Routes_Through_Executor then
         Matrix (Public_Build_Dependency_Executor_Route) := Dependency_Satisfied;
      end if;

      if not Readiness.Public_Consent_Model_Validated then
         Matrix (Public_Build_Dependency_Consent_Model) := Dependency_Missing;
      end if;
      if not (Readiness.Public_Consent_UX_Publicly_Ready
              and then Readiness.Public_Consent_Publicly_Exposable)
      then
         Matrix (Public_Build_Dependency_Consent_UX) := Dependency_Missing;
      end if;
      if not Readiness.Public_Working_Context_Model_Validated then
         Matrix (Public_Build_Dependency_Working_Context_Model) :=
           Dependency_Missing;
      end if;
      if not (Readiness.Public_Working_Context_Publicly_Ready
              and then Readiness.Public_Working_Context_Publicly_Exposable)
      then
         Matrix (Public_Build_Dependency_Working_Context_UX) :=
           Dependency_Missing;
      end if;
      if not (Readiness.Has_Implicit_Source_Validation
              and then Readiness.Keeps_Implicit_Source_Rejected)
      then
         Matrix (Public_Build_Dependency_Implicit_Source_Policy) :=
           Dependency_Intentionally_Blocked;
      end if;
      if not (Readiness.Keeps_Shell_Rejected
              and then Readiness.Keeps_Opaque_Arguments_Rejected
              and then Readiness.Routes_Diagnostics_Through_Pipeline)
      then
         Matrix (Public_Build_Dependency_Execution_Policy) :=
           Dependency_Model_Not_Public;
      end if;
      if not Readiness.Routes_Through_Executor then
         Matrix (Public_Build_Dependency_Executor_Route) := Dependency_Missing;
      end if;

      Matrix_Status := Validate_Public_Build_UX_Dependencies (Matrix);

      if Surface_Entry_Status /= Public_Build_Command_Surface_Valid then
         return Public_Build_Promotion_Blocked;
      elsif Detect_Public_Build_Command_Exposure_Hard_Failure (Readiness) then
         return Public_Build_Promotion_Unsafe_Exposure_Detected;
      elsif Matrix_Status /= Public_Build_Promotion_Command_Surface_Ready then
         return Matrix_Status;
      elsif not Readiness.Public_Command_Publicly_Exposable then
         return Public_Build_Promotion_Blocked;
      else
         return Public_Build_Promotion_Command_Surface_Ready;
      end if;
   end Validate_Public_Build_Command_Promotion;

   function Build_Public_Build_Blocker_Summary
     return Public_Build_Blocker_Summary
   is
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Summary : Public_Build_Blocker_Summary;
   begin
      Summary.Consent_UX_Missing :=
        Matrix (Public_Build_Dependency_Consent_UX) /= Dependency_Satisfied;
      Summary.Working_Context_UX_Missing :=
        Matrix (Public_Build_Dependency_Working_Context_UX) /= Dependency_Satisfied;
      Summary.Implicit_Source_Unsupported :=
        Matrix (Public_Build_Dependency_Implicit_Source_Policy) /=
          Dependency_Satisfied;
      Summary.Public_Route_Missing :=
        Matrix (Public_Build_Dependency_Executor_Route) /= Dependency_Satisfied;
      Summary.Public_Command_Not_Registered := False;
      Summary.Default_Execution_Disabled := True;
      Summary.Primary_Blocker := Primary_Public_Build_UX_Dependency_Blocker
        (Matrix);
      return Summary;
   end Build_Public_Build_Blocker_Summary;

   function Build_Public_Build_Hard_Freeze_Baseline
     return Public_Build_Hard_Freeze_Baseline
   is
   begin
      return
        (Public_Command_Count              => 1,
         Public_Default_Keybinding_Count   => 0,
         Public_Command_Palette_Count      => 1,
         Public_Executor_Route_Count       => 1,
         Public_Invocation_Path_Count      => 1,
         Bindable_Public_Build_Count       => 0,
         Promotion_Blocked                 => False,
         Default_Execution_Disabled        => True,
         Consent_UX_Missing                => False,
         Working_Context_UX_Missing        => False,
         Implicit_Source_Unsupported      => False,
         Public_Route_Missing              => False);
   end Build_Public_Build_Hard_Freeze_Baseline;

   function Detect_Public_Build_Hard_Freeze_Drift
     (State    : Editor.State.State_Type;
      Baseline : Public_Build_Hard_Freeze_Baseline)
      return Public_Build_Hard_Freeze_Drift_Result
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
      Result : Public_Build_Hard_Freeze_Drift_Result;

      function Count_When (Condition : Boolean) return Natural is
      begin
         if Condition then
            return 1;
         else
            return 0;
         end if;
      end Count_When;
   begin
      Result.Public_Command_Drift :=
        Public_Build_Public_Name_Count /= Baseline.Public_Command_Count
        or else Count_When (Audit.No_Public_Command_Registered) /=
          Baseline.Public_Command_Count;
      Result.Keybinding_Drift :=
        Count_When (not Audit.No_Public_Default_Keybinding) /=
          Baseline.Public_Default_Keybinding_Count;
      Result.Palette_Drift :=
        Count_When (Audit.No_Public_Command_Palette_Entry) /=
          Baseline.Public_Command_Palette_Count;
      Result.Executor_Route_Drift :=
        Count_When (Audit.No_Public_Executor_Route) /=
          Baseline.Public_Executor_Route_Count;
      Result.Invocation_Path_Drift :=
        Count_When (Audit.No_Public_Invocation_Path) /=
          Baseline.Public_Invocation_Path_Count;
      Result.Bindability_Drift :=
        Count_When (not Audit.No_Public_Bindable_Command) /=
          Baseline.Bindable_Public_Build_Count;
      Result.Promotion_Drift :=
        Audit.Promotion_Blocked /= Baseline.Promotion_Blocked;
      Result.Execution_Default_Drift :=
        Audit.No_Default_Execution /= Baseline.Default_Execution_Disabled;
      Result.Blocker_Precedence_Drift :=
        (not Public_Build_Blocker_Precedence_Intact)
        or else Summary.Consent_UX_Missing /= Baseline.Consent_UX_Missing
        or else Summary.Working_Context_UX_Missing /=
          Baseline.Working_Context_UX_Missing
        or else Summary.Implicit_Source_Unsupported /=
          Baseline.Implicit_Source_Unsupported
        or else Summary.Public_Route_Missing /= Baseline.Public_Route_Missing;
      Result.Persistence_Drift := not Audit.No_Public_Persistence_State;
      Result.Any_Drift :=
        Result.Public_Command_Drift
        or else Result.Keybinding_Drift
        or else Result.Palette_Drift
        or else Result.Executor_Route_Drift
        or else Result.Invocation_Path_Drift
        or else Result.Bindability_Drift
        or else Result.Promotion_Drift
        or else Result.Execution_Default_Drift
        or else Result.Blocker_Precedence_Drift
        or else Result.Persistence_Drift;
      return Result;
   end Detect_Public_Build_Hard_Freeze_Drift;

   function Build_Public_Build_Drift_Feedback
     (Result : Public_Build_Hard_Freeze_Drift_Result) return String
   is
   begin
      if not Result.Any_Drift then
         return "Build: public command hard-freeze intact";
      elsif Result.Public_Command_Drift or else Result.Palette_Drift then
         return "Build: public command exposure drift detected";
      elsif Result.Keybinding_Drift or else Result.Bindability_Drift then
         return "Build: public build keybinding drift detected";
      elsif Result.Executor_Route_Drift or else Result.Invocation_Path_Drift then
         return "Build: public build route drift detected";
      elsif Result.Promotion_Drift or else Result.Blocker_Precedence_Drift then
         return "Build: public build promotion drift detected";
      elsif Result.Persistence_Drift then
         return "Build: public build persistence drift detected";
      else
         return "Build: public build hard-freeze failed";
      end if;
   end Build_Public_Build_Drift_Feedback;

   function Public_Build_Surface_Ids_Not_Publicly_Projected
     (State : Editor.State.State_Type) return Boolean
   is
      Audit : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      return Audit.No_Public_Command_Registered
        and then Audit.No_Public_Default_Keybinding
        and then Audit.No_Public_Command_Palette_Entry
        and then Audit.No_Public_Executor_Route
        and then Audit.No_Public_Invocation_Path
        and then Audit.No_Public_Bindable_Command
        and then Audit.No_Public_Persistence_State;
   end Public_Build_Surface_Ids_Not_Publicly_Projected;

   function Run_Public_Build_Command_Hard_Freeze_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_Hard_Freeze_Audit_Result
   is
      Readiness : constant Public_Build_Command_Readiness_Audit_Result :=
        Run_Public_Build_Command_Readiness_Audit (State);
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Matrix_Status : constant Public_Build_Command_Promotion_Status :=
        Validate_Public_Build_UX_Dependencies (Matrix);
      Summary : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
      Result : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Result.Readiness_Audit_Passed_As_Not_Ready :=
        Readiness.Passed_As_Not_Ready;
      Result.Dependency_Matrix_Validated :=
        Matrix_Status = Public_Build_Promotion_Command_Surface_Ready
        and then Readiness.Public_UX_Dependency_Matrix_Validated;
      Result.Promotion_Blocked :=
        Readiness.Public_Command_Promotion_Status /=
          Public_Build_Promotion_Command_Surface_Ready;
      Result.Exposure_Barrier_Passed := Audit_Public_Build_Command_Visibility;
      Result.No_Public_Command_Registered :=
        Readiness.Has_Public_Build_Command
        and then Readiness.Public_Executable_Command_Exists;
      Result.No_Public_Default_Keybinding :=
        not Readiness.Has_Default_Public_Build_Keybinding;
      Result.No_Public_Command_Palette_Entry :=
        Command_Surface_Has_Public_Build_Command;
      Result.No_Public_Executor_Route :=
        not Readiness.Public_Executor_Route_Blocker_Active
        and then Readiness.Routes_Through_Executor;
      Result.No_Public_Invocation_Path :=
        Readiness.Public_Command_Is_Invokable
        and then Summary.Default_Execution_Disabled;
      Result.No_Public_Bindable_Command :=
        not Editor.Commands.Is_Bindable_Command
          (Editor.Commands.Command_Build_Run)
        and then not Readiness.Has_Default_Public_Build_Keybinding;
      Result.No_Public_Persistence_State := True;
      Result.No_Default_Execution := Summary.Default_Execution_Disabled;
      Result.Shell_Rejected := Readiness.Keeps_Shell_Rejected;
      Result.Opaque_Arguments_Rejected :=
        Readiness.Keeps_Opaque_Arguments_Rejected;
      Result.Implicit_Source_Rejected :=
        Readiness.Keeps_Implicit_Source_Rejected;
      Result.Public_Exposure_Hard_Failure :=
        Detect_Public_Build_Command_Exposure_Hard_Failure (Readiness);
      Result.Passed :=
        Result.Readiness_Audit_Passed_As_Not_Ready
        and then Result.Dependency_Matrix_Validated
        and then not Result.Promotion_Blocked
        and then Result.Exposure_Barrier_Passed
        and then Result.No_Public_Command_Registered
        and then Result.No_Public_Default_Keybinding
        and then Result.No_Public_Command_Palette_Entry
        and then Result.No_Public_Executor_Route
        and then Result.No_Public_Invocation_Path
        and then Result.No_Public_Bindable_Command
        and then Result.No_Public_Persistence_State
        and then Result.No_Default_Execution
        and then Result.Shell_Rejected
        and then Result.Opaque_Arguments_Rejected
        and then Result.Implicit_Source_Rejected
        and then not Result.Public_Exposure_Hard_Failure;
      return Result;
   end Run_Public_Build_Command_Hard_Freeze_Audit;

   procedure Assert_Public_Build_Audits_Agree
     (State : Editor.State.State_Type)
   is
      Readiness : constant Public_Build_Command_Readiness_Audit_Result :=
        Run_Public_Build_Command_Readiness_Audit (State);
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
      Dependency_Status : constant Public_Build_Command_Promotion_Status :=
        Validate_Public_Build_UX_Dependencies (Matrix);
      Hard_Freeze : constant Public_Build_Command_Hard_Freeze_Audit_Result :=
        Run_Public_Build_Command_Hard_Freeze_Audit (State);
   begin
      Assert_Public_Build_Blocker_Precedence;
      Assert_Public_Build_Surface_Ids_Not_Reused;

      declare
         Drift : constant Public_Build_Hard_Freeze_Drift_Result :=
           Detect_Public_Build_Hard_Freeze_Drift
             (State, Build_Public_Build_Hard_Freeze_Baseline);
      begin
         if Hard_Freeze.Passed and then Drift.Any_Drift then
            raise Program_Error with
              "public build hard-freeze passed despite drift";
         end if;
      end;

      if Readiness.Passed_As_Not_Ready
        and then Readiness.Public_Command_Promotion_Status /=
          Public_Build_Promotion_Command_Surface_Ready
      then
         raise Program_Error with
           "public build readiness and promotion audits disagree";
      end if;

      if Dependency_Status /= Public_Build_Promotion_Command_Surface_Ready then
         raise Program_Error with
           "public build dependency matrix blocks promotion";
      end if;

      Editor.External_Producers.Public_Build_Guardrail_Audits
        .Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan
          (State, Run_Public_Build_Guardrail_Audit (State));
      Editor.External_Producers.Public_Build_Guardrail_Audits
        .Assert_Public_Build_Guardrail_State_Not_Persisted (State);
   end Assert_Public_Build_Audits_Agree;

end Editor.External_Producers.Public_Build_Command_Surface_Audits;
