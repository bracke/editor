with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);
   use type Predicate.Predicate_RM_Closure_Consumer_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return A * 41 + B + 23;
   end Mix;

   function Is_Emitted (Status : RM_Closure_Consumer_Diagnostic_Status) return Boolean is
   begin
      return Status /= RM_Closure_Consumer_Diagnostic_Not_Checked
        and then Status /= RM_Closure_Consumer_Diagnostic_Withheld_Accepted_Current;
   end Is_Emitted;

   function Is_Withheld_Current (Status : RM_Closure_Consumer_Diagnostic_Status) return Boolean is
   begin
      return Status = RM_Closure_Consumer_Diagnostic_Withheld_Accepted_Current;
   end Is_Withheld_Current;

   function Has_Error (Row : RM_Closure_Consumer_Diagnostic_Row) return Boolean is
   begin
      return Row.Severity = RM_Closure_Consumer_Diagnostic_Error;
   end Has_Error;

   function Family_For
     (Family : Predicate.Predicate_RM_Closure_Consumer_Family)
      return RM_Closure_Consumer_Diagnostic_Family is
   begin
      case Family is
         when Predicate.Predicate_RM_Closure_Consumer_Family_None =>
            return RM_Closure_Consumer_Diagnostic_Accepted;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Predicate_RM =>
            return RM_Closure_Consumer_Diagnostic_Predicate_RM;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Stabilized_Closure =>
            return RM_Closure_Consumer_Diagnostic_Stabilized_Closure;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Stale_Or_Fingerprint =>
            return RM_Closure_Consumer_Diagnostic_Stale_Or_Fingerprint;
         when Predicate.Predicate_RM_Closure_Consumer_Family_AST_Or_Coverage =>
            return RM_Closure_Consumer_Diagnostic_AST_Or_Coverage;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Cross_Unit =>
            return RM_Closure_Consumer_Diagnostic_Cross_Unit;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Generic_Substitution =>
            return RM_Closure_Consumer_Diagnostic_Generic_Substitution;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Dataflow =>
            return RM_Closure_Consumer_Diagnostic_Dataflow;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Volatile_Atomic =>
            return RM_Closure_Consumer_Diagnostic_Volatile_Atomic;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Overload_Type =>
            return RM_Closure_Consumer_Diagnostic_Overload_Type;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Representation =>
            return RM_Closure_Consumer_Diagnostic_Representation;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Tasking_Protected =>
            return RM_Closure_Consumer_Diagnostic_Tasking_Protected;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Elaboration =>
            return RM_Closure_Consumer_Diagnostic_Elaboration;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Accessibility =>
            return RM_Closure_Consumer_Diagnostic_Accessibility;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Discriminant_Variant =>
            return RM_Closure_Consumer_Diagnostic_Discriminant_Variant;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Exception_Finalization =>
            return RM_Closure_Consumer_Diagnostic_Exception_Finalization;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Renaming_Alias =>
            return RM_Closure_Consumer_Diagnostic_Renaming_Alias;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Predicate_Invariant =>
            return RM_Closure_Consumer_Diagnostic_Predicate_Invariant;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Source_Fingerprint =>
            return RM_Closure_Consumer_Diagnostic_Source_Fingerprint;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Diagnostic_Substitution_Fingerprint;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Multiple =>
            return RM_Closure_Consumer_Diagnostic_Multiple;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Indeterminate =>
            return RM_Closure_Consumer_Diagnostic_Indeterminate;
      end case;
   end Family_For;

   function Status_For
     (Row : Predicate.Predicate_RM_Closure_Consumer_Row)
      return RM_Closure_Consumer_Diagnostic_Status is
   begin
      if Row.Status = Predicate.Predicate_RM_Closure_Consumer_Accepted then
         return RM_Closure_Consumer_Diagnostic_Withheld_Accepted_Current;
      end if;

      case Row.Family is
         when Predicate.Predicate_RM_Closure_Consumer_Family_Predicate_RM =>
            return RM_Closure_Consumer_Diagnostic_Predicate_RM_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Stabilized_Closure =>
            return RM_Closure_Consumer_Diagnostic_Stabilized_Closure_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Stale_Or_Fingerprint =>
            return RM_Closure_Consumer_Diagnostic_Stale_Or_Fingerprint_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_AST_Or_Coverage =>
            return RM_Closure_Consumer_Diagnostic_AST_Or_Coverage_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Cross_Unit =>
            return RM_Closure_Consumer_Diagnostic_Cross_Unit_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Generic_Substitution =>
            return RM_Closure_Consumer_Diagnostic_Generic_Substitution_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Dataflow =>
            return RM_Closure_Consumer_Diagnostic_Dataflow_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Volatile_Atomic =>
            return RM_Closure_Consumer_Diagnostic_Volatile_Atomic_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Overload_Type =>
            return RM_Closure_Consumer_Diagnostic_Overload_Type_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Representation =>
            return RM_Closure_Consumer_Diagnostic_Representation_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Tasking_Protected =>
            return RM_Closure_Consumer_Diagnostic_Tasking_Protected_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Elaboration =>
            return RM_Closure_Consumer_Diagnostic_Elaboration_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Accessibility =>
            return RM_Closure_Consumer_Diagnostic_Accessibility_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Discriminant_Variant =>
            return RM_Closure_Consumer_Diagnostic_Discriminant_Variant_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Exception_Finalization =>
            return RM_Closure_Consumer_Diagnostic_Exception_Finalization_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Renaming_Alias =>
            return RM_Closure_Consumer_Diagnostic_Renaming_Alias_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Predicate_Invariant =>
            return RM_Closure_Consumer_Diagnostic_Predicate_Invariant_Blocker;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Source_Fingerprint =>
            return RM_Closure_Consumer_Diagnostic_Source_Fingerprint_Mismatch;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Diagnostic_Substitution_Fingerprint_Mismatch;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Multiple =>
            return RM_Closure_Consumer_Diagnostic_Multiple_Blockers;
         when Predicate.Predicate_RM_Closure_Consumer_Family_Indeterminate =>
            return RM_Closure_Consumer_Diagnostic_Indeterminate;
         when Predicate.Predicate_RM_Closure_Consumer_Family_None =>
            return RM_Closure_Consumer_Diagnostic_Indeterminate;
      end case;
   end Status_For;

   function Severity_For
     (Family : RM_Closure_Consumer_Diagnostic_Family)
      return RM_Closure_Consumer_Diagnostic_Severity is
   begin
      case Family is
         when RM_Closure_Consumer_Diagnostic_Accepted =>
            return RM_Closure_Consumer_Diagnostic_Info;
         when RM_Closure_Consumer_Diagnostic_Stale_Or_Fingerprint |
              RM_Closure_Consumer_Diagnostic_Source_Fingerprint |
              RM_Closure_Consumer_Diagnostic_Substitution_Fingerprint |
              RM_Closure_Consumer_Diagnostic_Indeterminate =>
            return RM_Closure_Consumer_Diagnostic_Warning;
         when others =>
            return RM_Closure_Consumer_Diagnostic_Error;
      end case;
   end Severity_For;

   function Message_For
     (Family : RM_Closure_Consumer_Diagnostic_Family)
      return Unbounded_String is
   begin
      case Family is
         when RM_Closure_Consumer_Diagnostic_Accepted =>
            return To_Unbounded_String ("RM-completion closure consumer evidence is current");
         when RM_Closure_Consumer_Diagnostic_Cross_Unit =>
            return To_Unbounded_String ("cross-unit RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Elaboration =>
            return To_Unbounded_String ("elaboration RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Accessibility =>
            return To_Unbounded_String ("accessibility/lifetime RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Exception_Finalization =>
            return To_Unbounded_String ("exception/finalization RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Overload_Type =>
            return To_Unbounded_String ("overload/type RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Representation =>
            return To_Unbounded_String ("representation/freezing RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Tasking_Protected =>
            return To_Unbounded_String ("tasking/protected RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Dataflow =>
            return To_Unbounded_String ("dataflow RM-completion closure consumer blocks semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Multiple =>
            return To_Unbounded_String ("multiple RM-completion closure consumers block semantic conclusion");
         when RM_Closure_Consumer_Diagnostic_Indeterminate =>
            return To_Unbounded_String ("RM-completion closure consumer conclusion remains indeterminate");
         when others =>
            return To_Unbounded_String ("RM-completion closure consumer semantic blocker");
      end case;
   end Message_For;

   function Make_Row
     (Source : Predicate.Predicate_RM_Closure_Consumer_Row;
      Index  : Positive) return RM_Closure_Consumer_Diagnostic_Row is
      Family : constant RM_Closure_Consumer_Diagnostic_Family := Family_For (Source.Family);
      Status : constant RM_Closure_Consumer_Diagnostic_Status := Status_For (Source);
      FP : Natural := 1273;
   begin
      FP := Mix (FP, Natural (Source.Id));
      FP := Mix (FP, Predicate.Predicate_RM_Closure_Consumer_Status'Pos (Source.Status));
      FP := Mix (FP, RM_Closure_Consumer_Diagnostic_Status'Pos (Status));
      FP := Mix (FP, RM_Closure_Consumer_Diagnostic_Family'Pos (Family));
      FP := Mix (FP, Natural (Source.Node));
      FP := Mix (FP, Source.Source_Fingerprint);
      FP := Mix (FP, Source.Substitution_Fingerprint);

      return
        (Id => RM_Closure_Consumer_Diagnostic_Id (Index),
         Predicate_Row => Source.Id,
         Predicate_Status => Source.Status,
         Predicate_Family => Source.Family,
         Status => Status,
         Family => Family,
         Severity => Severity_For (Family),
         Node => Source.Node,
         Message => Message_For (Family),
         Detail => To_Unbounded_String ("Case 1273 preserves direct RM-completion closure consumer blocker-family identity at the diagnostic/feed boundary."),
         Source_Fingerprint => Source.Source_Fingerprint,
         Substitution_Fingerprint => Source.Substitution_Fingerprint,
         Semantic_Fingerprint => Source.Row_Fingerprint,
         Diagnostic_Fingerprint => FP,
         Emitted => Is_Emitted (Status),
         Withheld_Current => Is_Withheld_Current (Status),
         Blocks_Downstream => Is_Emitted (Status),
         Start_Line => Source.Start_Line,
         Start_Column => Source.Start_Column,
         End_Line => Source.End_Line,
         End_Column => Source.End_Column);
   end Make_Row;

   procedure Clear (Model : in out RM_Closure_Consumer_Diagnostic_Model) is
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
     (Predicate_Model : Predicate.Predicate_RM_Closure_Consumer_Model)
      return RM_Closure_Consumer_Diagnostic_Model is
      Result : RM_Closure_Consumer_Diagnostic_Model;
      FP : Natural := 1273;
   begin
      for I in 1 .. Predicate.Count (Predicate_Model) loop
         declare
            Row : constant RM_Closure_Consumer_Diagnostic_Row :=
              Make_Row (Predicate.Row_At (Predicate_Model, I), I);
         begin
            Result.Rows.Append (Row);
            if Row.Emitted then
               Result.Emitted_Total := Result.Emitted_Total + 1;
            end if;
            if Row.Withheld_Current then
               Result.Withheld_Current_Total := Result.Withheld_Current_Total + 1;
            end if;
            if Row.Status = RM_Closure_Consumer_Diagnostic_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
            case Row.Severity is
               when RM_Closure_Consumer_Diagnostic_Error =>
                  Result.Error_Total := Result.Error_Total + 1;
               when RM_Closure_Consumer_Diagnostic_Warning =>
                  Result.Warning_Total := Result.Warning_Total + 1;
               when RM_Closure_Consumer_Diagnostic_Info =>
                  Result.Info_Total := Result.Info_Total + 1;
            end case;
            FP := Mix (FP, Row.Diagnostic_Fingerprint);
         end;
      end loop;
      Result.Fingerprint := FP;
      return Result;
   end Build;

   function Row_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Closure_Consumer_Diagnostic_Model;
      Index : Positive) return RM_Closure_Consumer_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Diagnostic_Set;
      Index : Positive) return RM_Closure_Consumer_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Status : RM_Closure_Consumer_Diagnostic_Status)
      return RM_Closure_Consumer_Diagnostic_Set is
      Result : RM_Closure_Consumer_Diagnostic_Set;
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
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Family : RM_Closure_Consumer_Diagnostic_Family)
      return RM_Closure_Consumer_Diagnostic_Set is
      Result : RM_Closure_Consumer_Diagnostic_Set;
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
     (Model : RM_Closure_Consumer_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Diagnostic_Set is
      Result : RM_Closure_Consumer_Diagnostic_Set;
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
     (Model       : RM_Closure_Consumer_Diagnostic_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Diagnostic_Set is
      Result : RM_Closure_Consumer_Diagnostic_Set;
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
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Status : RM_Closure_Consumer_Diagnostic_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Family
     (Model  : RM_Closure_Consumer_Diagnostic_Model;
      Family : RM_Closure_Consumer_Diagnostic_Family) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Family = Family then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Family;

   function Error_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : RM_Closure_Consumer_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration;
