package body Editor.Ada_End_To_End_Semantic_Scenario_Audit_Pass1337 is

   pragma Suppress (Overflow_Check);

   procedure Add_Scenario (Model : in out Scenario_Model; Scenario : End_To_End_Scenario) is
   begin
      Model.Items.Append (Scenario);
   end Add_Scenario;

   procedure Add_Evidence (Model : in out Evidence_Model; Evidence : Slice_Evidence) is
   begin
      Model.Items.Append (Evidence);
   end Add_Evidence;

   function Count (Results : Audit_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Audit_Model; Index : Positive) return Audit_Result is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function End_To_End_Audit_Ready (Results : Audit_Model) return Boolean is
   begin
      return Results.Blocked_Count = 0 and then Results.Ready_Count = Count (Results);
   end End_To_End_Audit_Ready;

   procedure Add_Blocker
     (Result : in out Audit_Result;
      Status : Audit_Status;
      Slice : Slice_Result) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status = Status_Ready then
         Result.Status := Status;
         Result.Blocking_Slice := Slice;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
         if Result.Blocking_Slice = Slice_Unknown then
            Result.Blocking_Slice := Slice;
         end if;
      end if;
   end Add_Blocker;

   function Requires (Kind : Scenario_Kind; Slice : Slice_Result) return Boolean is
   begin
      case Kind is
         when Scenario_Private_Type_Full_View =>
            return Slice in Slice_Aggregate
              | Slice_Assignment_Conversion
              | Slice_Contract_Aspect
              | Slice_Representation_Freezing
              | Slice_Visibility_Name_Resolution
              | Slice_Accessibility_Lifetime;
         when Scenario_Generic_Instantiation =>
            return Slice in Slice_Aggregate
              | Slice_Assignment_Conversion
              | Slice_Contract_Aspect
              | Slice_Flow_Refinement
              | Slice_Callable_Profile
              | Slice_Generic_Contract_Body
              | Slice_Generic_Body_Replay
              | Slice_Overload_Resolution;
         when Scenario_Tagged_Interface_Dispatch =>
            return Slice in Slice_Assignment_Conversion
              | Slice_Contract_Aspect
              | Slice_Interface_Synchronized
              | Slice_Flow_Refinement
              | Slice_Callable_Profile
              | Slice_Tagged_Dispatching
              | Slice_Overload_Resolution;
         when Scenario_Library_Separate_Body =>
            return Slice in Slice_Context_Clause_With_Use
              | Slice_Library_Unit_Subunit
              | Slice_Interfacing_Import_Export
              | Slice_Callable_Profile
              | Slice_Elaboration
              | Slice_Visibility_Name_Resolution;
         when Scenario_Task_Protected_Parallel =>
            return Slice in Slice_Iterator_Loop_Parallel
              | Slice_Contract_Aspect
              | Slice_Interface_Synchronized
              | Slice_Flow_Refinement
              | Slice_Callable_Profile;
         when Scenario_Representation_Interfacing =>
            return Slice in Slice_Interfacing_Import_Export
              | Slice_Representation_Freezing
              | Slice_Record_Layout
              | Slice_Enumeration_Representation
              | Slice_Callable_Profile;
         when Scenario_Unknown =>
            return False;
      end case;
   end Requires;

   function Has_Evidence
     (Evidence : Evidence_Model;
      Scenario_Id : Natural;
      Slice : Slice_Result) return Boolean
   is
   begin
      for E of Evidence.Items loop
         if E.Scenario_Id = Scenario_Id and then E.Slice = Slice and then E.Present then
            return True;
         end if;
      end loop;
      return False;
   end Has_Evidence;

   procedure Check_Scenario_Evidence
     (Scenario : End_To_End_Scenario;
      Result : in out Audit_Result) is
   begin
      if not Scenario.Source_Shaped then
         Add_Blocker (Result, Status_Not_Source_Shaped, Slice_Unknown);
      end if;
      if not Scenario.Has_Source_Evidence then
         Add_Blocker (Result, Status_Missing_Source_Evidence, Slice_Unknown);
      end if;
      if not Scenario.Has_AST_Evidence then
         Add_Blocker (Result, Status_Missing_AST_Evidence, Slice_Unknown);
      end if;
      if not Scenario.Canonical_Model_Agrees then
         Add_Blocker (Result, Status_Canonical_Model_Disagreement, Slice_Unknown);
      end if;
      if not Scenario.Cross_Unit_Evidence_Fresh then
         Add_Blocker (Result, Status_Cross_Unit_Evidence_Stale, Slice_Context_Clause_With_Use);
      end if;
      if not Scenario.Generic_Substitution_Propagated then
         Add_Blocker (Result, Status_Generic_Substitution_Not_Propagated, Slice_Generic_Body_Replay);
      end if;
      if not Scenario.View_Model_Agrees then
         Add_Blocker (Result, Status_View_Model_Disagreement, Slice_Visibility_Name_Resolution);
      end if;
      if not Scenario.Overload_Profile_Agrees then
         Add_Blocker (Result, Status_Overload_Profile_Disagreement, Slice_Callable_Profile);
      end if;
      if not Scenario.Flow_Effect_Consumed then
         Add_Blocker (Result, Status_Flow_Effect_Not_Consumed, Slice_Flow_Refinement);
      end if;
      if not Scenario.Representation_Freezing_Consistent then
         Add_Blocker (Result, Status_Representation_Freezing_Inconsistent, Slice_Representation_Freezing);
      end if;
      if not Scenario.Runtime_Check_Preserved then
         Add_Blocker (Result, Status_Runtime_Check_Not_Preserved, Slice_Contract_Aspect);
      end if;
      if not Scenario.Blocker_Family_Stable then
         Add_Blocker (Result, Status_Blocker_Family_Unstable, Slice_Unknown);
      end if;
      if Scenario.Source_Fingerprint /= Scenario.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch, Slice_Unknown);
      end if;
      if Scenario.AST_Fingerprint /= Scenario.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch, Slice_Unknown);
      end if;
      if Scenario.Canonical_Fingerprint /= Scenario.Expected_Canonical_Fingerprint then
         Add_Blocker (Result, Status_Canonical_Fingerprint_Mismatch, Slice_Unknown);
      end if;
      if Scenario.Consumer_Fingerprint /= Scenario.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch, Slice_Unknown);
      end if;
   end Check_Scenario_Evidence;

   procedure Check_Slice_Evidence
     (Evidence : Slice_Evidence;
      Result : in out Audit_Result) is
   begin
      if not Evidence.Source_Shaped then
         Add_Blocker (Result, Status_Not_Source_Shaped, Evidence.Slice);
      end if;
      if not Evidence.Has_Source_Evidence then
         Add_Blocker (Result, Status_Missing_Source_Evidence, Evidence.Slice);
      end if;
      if not Evidence.Has_AST_Evidence then
         Add_Blocker (Result, Status_Missing_AST_Evidence, Evidence.Slice);
      end if;
      if not Evidence.Consumed then
         Add_Blocker (Result, Status_Unconsumed_Semantic_Result, Evidence.Slice);
      end if;
      if Evidence.Result_Fingerprint /= Evidence.Expected_Result_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch, Evidence.Slice);
      end if;
   end Check_Slice_Evidence;

   procedure Check_Required_Slices
     (Scenario : End_To_End_Scenario;
      Evidence : Evidence_Model;
      Result : in out Audit_Result) is
   begin
      for S in Slice_Result loop
         if S /= Slice_Unknown
           and then Requires (Scenario.Kind, S)
           and then not Has_Evidence (Evidence, Scenario.Id, S)
         then
            Add_Blocker (Result, Status_Missing_Required_Slice_Result, S);
         end if;
      end loop;
   end Check_Required_Slices;

   function Build (Scenarios : Scenario_Model; Evidence : Evidence_Model) return Audit_Model is
      Results : Audit_Model;
   begin
      for S of Scenarios.Items loop
         declare
            R : Audit_Result;
         begin
            R.Id := S.Id;
            R.Kind := S.Kind;
            R.Name := S.Name;
            R.Node := S.Node;
            R.Status := Status_Ready;
            R.Blocking_Slice := Slice_Unknown;
            R.Scenario_Fingerprint := S.Id + Scenario_Kind'Pos (S.Kind) + 1;

            Check_Scenario_Evidence (S, R);
            Check_Required_Slices (S, Evidence, R);

            for E of Evidence.Items loop
               if E.Scenario_Id = S.Id and then Requires (S.Kind, E.Slice) then
                  Check_Slice_Evidence (E, R);
                  R.Scenario_Fingerprint :=
                    R.Scenario_Fingerprint
                    + Slice_Result'Pos (E.Slice)
                    + E.Result_Fingerprint
                    + E.Expected_Result_Fingerprint;
               end if;
            end loop;

            if R.Blocker_Count = 0 then
               Results.Ready_Count := Results.Ready_Count + 1;
            else
               Results.Blocked_Count := Results.Blocked_Count + 1;
            end if;

            Results.Audit_Fingerprint :=
              Results.Audit_Fingerprint + R.Scenario_Fingerprint + R.Blocker_Count;
            Results.Items.Append (R);
         end;
      end loop;
      return Results;
   end Build;

end Editor.Ada_End_To_End_Semantic_Scenario_Audit_Pass1337;
