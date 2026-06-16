with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return A * 37 + B + 17;
   end Mix;

   function Is_Emitted (Status : RM_Completion_Diagnostic_Status) return Boolean is
   begin
      return Status /= RM_Completion_Diagnostic_Not_Checked
        and then Status /= RM_Completion_Diagnostic_Withheld_Accepted_Current;
   end Is_Emitted;

   function Is_Withheld_Current (Status : RM_Completion_Diagnostic_Status) return Boolean is
   begin
      return Status = RM_Completion_Diagnostic_Withheld_Accepted_Current;
   end Is_Withheld_Current;

   function Has_Error (Row : RM_Completion_Diagnostic_Row) return Boolean is
   begin
      return Row.Severity = RM_Completion_Diagnostic_Error;
   end Has_Error;

   function Family_For
     (Family : Dataflow_RM.Dataflow_RM_Completion_Blocker_Family)
      return RM_Completion_Diagnostic_Family is
   begin
      case Family is
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_None => return RM_Completion_Diagnostic_Accepted;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Prior_Dataflow => return RM_Completion_Diagnostic_Prior_Dataflow;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion => return RM_Completion_Diagnostic_Cross_Unit_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Elaboration_RM_Completion => return RM_Completion_Diagnostic_Elaboration_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Accessibility_RM_Completion => return RM_Completion_Diagnostic_Accessibility_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Exception_Finalization_RM_Completion => return RM_Completion_Diagnostic_Exception_Finalization_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Predicate_RM_Completion => return RM_Completion_Diagnostic_Predicate_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Overload_RM_Completion => return RM_Completion_Diagnostic_Overload_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Representation_RM_Completion => return RM_Completion_Diagnostic_Representation_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Tasking_RM_Completion => return RM_Completion_Diagnostic_Tasking_RM_Completion;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_AST_Repair => return RM_Completion_Diagnostic_AST_Repair;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Read_Before_Write => return RM_Completion_Diagnostic_Dataflow_Read_Before_Write;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Partial_Component_Init => return RM_Completion_Diagnostic_Dataflow_Component_Init;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Out_Parameter => return RM_Completion_Diagnostic_Dataflow_Out_Parameter;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Return_Object => return RM_Completion_Diagnostic_Dataflow_Return_Object;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Branch_Loop_Merge => return RM_Completion_Diagnostic_Dataflow_Branch_Loop_Merge;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Exception_Path => return RM_Completion_Diagnostic_Exception_Path;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Finalization => return RM_Completion_Diagnostic_Finalization;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Access_Escape => return RM_Completion_Diagnostic_Access_Escape;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Variant_Component => return RM_Completion_Diagnostic_Variant_Component;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Volatile_Atomic_Effect => return RM_Completion_Diagnostic_Volatile_Atomic_Effect;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Generic_Substitution => return RM_Completion_Diagnostic_Generic_Substitution;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Dispatching_Effect => return RM_Completion_Diagnostic_Dispatching_Effect;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_View_Barrier => return RM_Completion_Diagnostic_View_Barrier;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Source_Fingerprint => return RM_Completion_Diagnostic_Source_Fingerprint;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Substitution_Fingerprint => return RM_Completion_Diagnostic_Substitution_Fingerprint;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Multiple => return RM_Completion_Diagnostic_Multiple;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Indeterminate => return RM_Completion_Diagnostic_Indeterminate;
      end case;
   end Family_For;

   function Status_For
     (Family : Dataflow_RM.Dataflow_RM_Completion_Blocker_Family)
      return RM_Completion_Diagnostic_Status is
   begin
      case Family is
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_None => return RM_Completion_Diagnostic_Withheld_Accepted_Current;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Prior_Dataflow => return RM_Completion_Diagnostic_Prior_Dataflow_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion => return RM_Completion_Diagnostic_Cross_Unit_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Elaboration_RM_Completion => return RM_Completion_Diagnostic_Elaboration_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Accessibility_RM_Completion => return RM_Completion_Diagnostic_Accessibility_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Exception_Finalization_RM_Completion => return RM_Completion_Diagnostic_Exception_Finalization_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Predicate_RM_Completion => return RM_Completion_Diagnostic_Predicate_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Overload_RM_Completion => return RM_Completion_Diagnostic_Overload_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Representation_RM_Completion => return RM_Completion_Diagnostic_Representation_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Tasking_RM_Completion => return RM_Completion_Diagnostic_Tasking_RM_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_AST_Repair => return RM_Completion_Diagnostic_AST_Repair_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Read_Before_Write => return RM_Completion_Diagnostic_Dataflow_Read_Before_Write_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Partial_Component_Init => return RM_Completion_Diagnostic_Dataflow_Component_Init_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Out_Parameter => return RM_Completion_Diagnostic_Dataflow_Out_Parameter_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Return_Object => return RM_Completion_Diagnostic_Dataflow_Return_Object_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Branch_Loop_Merge => return RM_Completion_Diagnostic_Dataflow_Branch_Loop_Merge_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Exception_Path => return RM_Completion_Diagnostic_Exception_Path_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Finalization => return RM_Completion_Diagnostic_Finalization_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Access_Escape => return RM_Completion_Diagnostic_Access_Escape_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Variant_Component => return RM_Completion_Diagnostic_Variant_Component_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Volatile_Atomic_Effect => return RM_Completion_Diagnostic_Volatile_Atomic_Effect_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Generic_Substitution => return RM_Completion_Diagnostic_Generic_Substitution_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Dispatching_Effect => return RM_Completion_Diagnostic_Dispatching_Effect_Blocker;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_View_Barrier => return RM_Completion_Diagnostic_View_Barrier;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Source_Fingerprint => return RM_Completion_Diagnostic_Source_Fingerprint_Mismatch;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Substitution_Fingerprint => return RM_Completion_Diagnostic_Substitution_Fingerprint_Mismatch;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Multiple => return RM_Completion_Diagnostic_Multiple_Blockers;
         when Dataflow_RM.Dataflow_RM_Completion_Blocker_Indeterminate => return RM_Completion_Diagnostic_Indeterminate;
      end case;
   end Status_For;

   function Severity_For
     (Family : RM_Completion_Diagnostic_Family)
      return RM_Completion_Diagnostic_Severity is
   begin
      case Family is
         when RM_Completion_Diagnostic_Accepted => return RM_Completion_Diagnostic_Info;
         when RM_Completion_Diagnostic_Source_Fingerprint |
              RM_Completion_Diagnostic_Substitution_Fingerprint |
              RM_Completion_Diagnostic_View_Barrier |
              RM_Completion_Diagnostic_Indeterminate => return RM_Completion_Diagnostic_Warning;
         when others => return RM_Completion_Diagnostic_Error;
      end case;
   end Severity_For;

   function Message_For
     (Family : RM_Completion_Diagnostic_Family)
      return Unbounded_String is
   begin
      case Family is
         when RM_Completion_Diagnostic_Accepted => return To_Unbounded_String ("RM-completed generic/shared-state evidence is current");
         when RM_Completion_Diagnostic_Cross_Unit_RM_Completion => return To_Unbounded_String ("cross-unit RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Elaboration_RM_Completion => return To_Unbounded_String ("elaboration RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Accessibility_RM_Completion => return To_Unbounded_String ("accessibility RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Exception_Finalization_RM_Completion => return To_Unbounded_String ("exception/finalization RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Predicate_RM_Completion => return To_Unbounded_String ("predicate/invariant RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Overload_RM_Completion => return To_Unbounded_String ("overload/type RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Representation_RM_Completion => return To_Unbounded_String ("representation/freezing RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Tasking_RM_Completion => return To_Unbounded_String ("tasking/protected RM-completion prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_AST_Repair => return To_Unbounded_String ("coverage-proven AST repair prerequisite blocks generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Multiple => return To_Unbounded_String ("multiple RM-completion prerequisites block generic/shared-state conclusion");
         when RM_Completion_Diagnostic_Indeterminate => return To_Unbounded_String ("RM-completed generic/shared-state conclusion remains indeterminate");
         when others => return To_Unbounded_String ("RM-completed generic/shared-state semantic blocker");
      end case;
   end Message_For;

   function Make_Row
     (Source : Dataflow_RM.Dataflow_RM_Completion_Row;
      Index  : Positive) return RM_Completion_Diagnostic_Row is
      Family : constant RM_Completion_Diagnostic_Family := Family_For (Source.Blocker_Family);
      Status : constant RM_Completion_Diagnostic_Status := Status_For (Source.Blocker_Family);
      Fingerprint : Natural := 1256;
   begin
      Fingerprint := Mix (Fingerprint, Natural (Source.Id));
      Fingerprint := Mix (Fingerprint, Dataflow_RM.Dataflow_RM_Completion_Status'Pos (Source.Status));
      Fingerprint := Mix (Fingerprint, RM_Completion_Diagnostic_Status'Pos (Status));
      Fingerprint := Mix (Fingerprint, RM_Completion_Diagnostic_Family'Pos (Family));
      Fingerprint := Mix (Fingerprint, Natural (Source.Node));
      Fingerprint := Mix (Fingerprint, Source.Source_Fingerprint);
      Fingerprint := Mix (Fingerprint, Source.Substitution_Fingerprint);

      return
        (Id => RM_Completion_Diagnostic_Id (Index),
         Dataflow_Row => Source.Id,
         Dataflow_Status => Source.Status,
         Status => Status,
         Family => Family,
         Severity => Severity_For (Family),
         Node => Source.Node,
         Message => Message_For (Family),
         Detail => To_Unbounded_String ("Pass1256 preserves RM-completion blocker-family identity at the diagnostic/feed boundary."),
         Source_Fingerprint => Source.Source_Fingerprint,
         Substitution_Fingerprint => Source.Substitution_Fingerprint,
         Semantic_Fingerprint => Source.Stable_Row_Fingerprint,
         Diagnostic_Fingerprint => Fingerprint,
         Emitted => Is_Emitted (Status),
         Withheld_Current => Is_Withheld_Current (Status),
         Blocks_Downstream => Is_Emitted (Status),
         Start_Line => 1,
         Start_Column => 1,
         End_Line => 1,
         End_Column => 1);
   end Make_Row;

   procedure Clear (Model : in out RM_Completion_Diagnostic_Model) is
   begin
      Model.Rows.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Emitted_Total := 0;
      Model.Withheld_Current_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Dataflow_Model : Dataflow_RM.Dataflow_RM_Completion_Model)
      return RM_Completion_Diagnostic_Model is
      Result : RM_Completion_Diagnostic_Model;
      FP : Natural := 1256;
   begin
      for I in 1 .. Dataflow_RM.Count (Dataflow_Model) loop
         declare
            Row : constant RM_Completion_Diagnostic_Row :=
              Make_Row (Dataflow_RM.Row_At (Dataflow_Model, I), I);
         begin
            Result.Rows.Append (Row);
            if Row.Emitted then
               Result.Emitted_Total := Result.Emitted_Total + 1;
            end if;
            if Row.Withheld_Current then
               Result.Withheld_Current_Total := Result.Withheld_Current_Total + 1;
            end if;
            if Row.Status = RM_Completion_Diagnostic_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
            case Row.Severity is
               when RM_Completion_Diagnostic_Error => Result.Error_Total := Result.Error_Total + 1;
               when RM_Completion_Diagnostic_Warning => Result.Warning_Total := Result.Warning_Total + 1;
               when RM_Completion_Diagnostic_Info => Result.Info_Total := Result.Info_Total + 1;
            end case;
            FP := Mix (FP, Row.Diagnostic_Fingerprint);
         end;
      end loop;
      Result.Fingerprint := FP;
      return Result;
   end Build;

   function Row_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Completion_Diagnostic_Model;
      Index : Positive) return RM_Completion_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Completion_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Completion_Diagnostic_Set;
      Index : Positive) return RM_Completion_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : RM_Completion_Diagnostic_Model;
      Status : RM_Completion_Diagnostic_Status)
      return RM_Completion_Diagnostic_Set is
      Result : RM_Completion_Diagnostic_Set;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Result.Rows.Append (R);
            Result.Fingerprint := Mix (Result.Fingerprint, R.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Family
     (Model  : RM_Completion_Diagnostic_Model;
      Family : RM_Completion_Diagnostic_Family)
      return RM_Completion_Diagnostic_Set is
      Result : RM_Completion_Diagnostic_Set;
   begin
      for R of Model.Rows loop
         if R.Family = Family then
            Result.Rows.Append (R);
            Result.Fingerprint := Mix (Result.Fingerprint, R.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Result;
   end Query_Family;

   function Query_Node
     (Model : RM_Completion_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Completion_Diagnostic_Set is
      Result : RM_Completion_Diagnostic_Set;
   begin
      for R of Model.Rows loop
         if R.Node = Node then
            Result.Rows.Append (R);
            Result.Fingerprint := Mix (Result.Fingerprint, R.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : RM_Completion_Diagnostic_Model;
      Fingerprint : Natural) return RM_Completion_Diagnostic_Set is
      Result : RM_Completion_Diagnostic_Set;
   begin
      for R of Model.Rows loop
         if R.Source_Fingerprint = Fingerprint then
            Result.Rows.Append (R);
            Result.Fingerprint := Mix (Result.Fingerprint, R.Diagnostic_Fingerprint);
         end if;
      end loop;
      return Result;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : RM_Completion_Diagnostic_Model;
      Status : RM_Completion_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : RM_Completion_Diagnostic_Model;
      Family : RM_Completion_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Error_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Indeterminate_Count (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : RM_Completion_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
