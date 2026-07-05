with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);
   use type Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 1_181) + (B * 149) + 12_810) mod 1_000_000_007;
   end Mix;

   function Status_For
     (Status : RM_Closure_Consumer_Stabilized_Closure_Status)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Status is
   begin
      case Status is
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Not_Checked =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Accepted_Current =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Current;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Accepted_Not_Required =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Not_Required;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Stale_Or_Fingerprint =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_AST_Or_Coverage =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_AST_Or_Coverage_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Cross_Unit =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Generic_Substitution =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Dataflow =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Volatile_Atomic =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Overload_Type =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Representation =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Representation_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Tasking_Protected =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Elaboration =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Accessibility =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Discriminant_Variant =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Discriminant_Variant_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Exception_Finalization =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Renaming_Alias =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Renaming_Alias_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Predicate_Invariant =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant_Blocker;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Source_Fingerprint =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint_Mismatch;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint_Mismatch;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Blocker_Multiple_Prerequisites =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Multiple_Prerequisites;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Indeterminate =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate;
         when Closure.RM_Closure_Consumer_Stabilized_Closure_Recheck_Required =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required;
      end case;
   end Status_For;

   function Family_For
     (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Family is
   begin
      case Status is
         when RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Current |
              RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Not_Required =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Accepted;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint;
         when RM_Closure_Consumer_Stabilized_Diagnostic_AST_Or_Coverage_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_AST_Or_Coverage;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Representation_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Representation;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Discriminant_Variant_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Discriminant_Variant;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Renaming_Alias_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Renaming_Alias;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant_Blocker =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint_Mismatch =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Multiple_Prerequisites =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Multiple;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate |
              RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate;
      end case;
   end Family_For;

   function Severity_For
     (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Severity is
   begin
      case Status is
         when RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Current |
              RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Not_Required =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Info;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint_Blocker |
              RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint_Mismatch |
              RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint_Mismatch |
              RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate |
              RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required |
              RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Warning;
         when others =>
            return RM_Closure_Consumer_Stabilized_Diagnostic_Error;
      end case;
   end Severity_For;

   function Is_Withheld_Current
     (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Boolean is
   begin
      return Status = RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Current
        or else Status = RM_Closure_Consumer_Stabilized_Diagnostic_Withheld_Accepted_Not_Required;
   end Is_Withheld_Current;

   function Is_Emitted (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Boolean is
   begin
      return Status /= RM_Closure_Consumer_Stabilized_Diagnostic_Not_Checked
        and then not Is_Withheld_Current (Status);
   end Is_Emitted;

   function Message_For
     (Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family) return Unbounded_String is
   begin
      if Is_Withheld_Current (Status) then
         return To_Unbounded_String ("stabilized RM-completion closure consumer evidence is current");
      elsif Status = RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required then
         return To_Unbounded_String ("stabilized RM-completion closure consumer requires bounded recheck");
      elsif Status = RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate then
         return To_Unbounded_String ("stabilized RM-completion closure consumer remains indeterminate");
      else
         return To_Unbounded_String
           ("stabilized RM-completion closure consumer blocker: " &
            RM_Closure_Consumer_Stabilized_Diagnostic_Family'Image (Family));
      end if;
   end Message_For;

   function Make_Row
     (Source : Closure.RM_Closure_Consumer_Stabilized_Closure_Row;
      Index  : Positive) return RM_Closure_Consumer_Stabilized_Diagnostic_Row is
      Status : constant RM_Closure_Consumer_Stabilized_Diagnostic_Status := Status_For (Source.Status);
      Family : constant RM_Closure_Consumer_Stabilized_Diagnostic_Family := Family_For (Status);
      Row    : RM_Closure_Consumer_Stabilized_Diagnostic_Row;
   begin
      Row.Id := RM_Closure_Consumer_Stabilized_Diagnostic_Id (Index);
      Row.Closure_Id := Source.Id;
      Row.Stabilization_Id := Source.Stabilization_Id;
      Row.Convergence_Id := Source.Convergence_Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Closure_Status := Source.Status;
      Row.Closure_Action := Source.Action;
      Row.Status := Status;
      Row.Family := Family;
      Row.Closure_Family := Source.Family;
      Row.Severity := Severity_For (Status);
      Row.Node := Source.Node;
      Row.Message := Message_For (Status, Family);
      Row.Detail := To_Unbounded_String
        ("Case 1281 maps stabilized direct RM-completion closure consumer rows into the diagnostic/feed boundary without losing prerequisite family identity.");
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Semantic_Fingerprint := Source.Semantic_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Closure_Fingerprint := Source.Closure_Fingerprint;
      Row.Emitted := Is_Emitted (Status);
      Row.Withheld_Current := Is_Withheld_Current (Status);
      Row.Requires_Recheck := Status = RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required;
      Row.Blocks_Downstream := Row.Emitted or else Source.Blocks_Downstream;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Stabilized_Diagnostic_Fingerprint := Mix (12_810, Natural (Row.Id));
      Row.Stabilized_Diagnostic_Fingerprint := Mix
        (Row.Stabilized_Diagnostic_Fingerprint,
         RM_Closure_Consumer_Stabilized_Diagnostic_Status'Pos (Status) + 1);
      Row.Stabilized_Diagnostic_Fingerprint := Mix
        (Row.Stabilized_Diagnostic_Fingerprint,
         RM_Closure_Consumer_Stabilized_Diagnostic_Family'Pos (Family) + 1);
      Row.Stabilized_Diagnostic_Fingerprint := Mix
        (Row.Stabilized_Diagnostic_Fingerprint,
         Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Pos (Source.Family) + 1);
      Row.Stabilized_Diagnostic_Fingerprint := Mix
        (Row.Stabilized_Diagnostic_Fingerprint, Source.Closure_Fingerprint);
      return Row;
   end Make_Row;

   procedure Note
     (Model : in out RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Row   : RM_Closure_Consumer_Stabilized_Diagnostic_Row) is
   begin
      case Row.Severity is
         when RM_Closure_Consumer_Stabilized_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when RM_Closure_Consumer_Stabilized_Diagnostic_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      if Row.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      if Row.Withheld_Current then
         Model.Withheld_Current_Total := Model.Withheld_Current_Total + 1;
      end if;
      if Row.Requires_Recheck then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;
      if Row.Status = RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Stabilized_Diagnostic_Fingerprint);
   end Note;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Diagnostic_Model) is
   begin
      Model.Rows.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Emitted_Total := 0;
      Model.Withheld_Current_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Closure_Model : Closure.RM_Closure_Consumer_Stabilized_Closure_Model)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Model is
      Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
   begin
      for I in 1 .. Closure.Row_Count (Closure_Model) loop
         declare
            Row : constant RM_Closure_Consumer_Stabilized_Diagnostic_Row :=
              Make_Row (Closure.Row_At (Closure_Model, I), I);
         begin
            Model.Rows.Append (Row);
            Note (Model, Row);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Diagnostic_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Stabilized_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Diagnostic_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out RM_Closure_Consumer_Stabilized_Diagnostic_Set;
      Row : RM_Closure_Consumer_Stabilized_Diagnostic_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Stabilized_Diagnostic_Fingerprint);
   end Append;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set is
      Result : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set is
      Result : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Family;

   function Query_Closure_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Closure_Family)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set is
      Result : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Closure_Family = Family then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Closure_Family;

   function Query_Node
     (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Stabilized_Diagnostic_Set is
      Result : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Diagnostic_Set is
      Result : RM_Closure_Consumer_Stabilized_Diagnostic_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Closure_Family
     (Model  : RM_Closure_Consumer_Stabilized_Diagnostic_Model;
      Family : RM_Closure_Consumer_Closure_Family) return Natural is
   begin
      return Query_Count (Query_Closure_Family (Model, Family));
   end Count_Closure_Family;

   function Error_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Emitted_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Withheld_Current_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Current_Total;
   end Withheld_Current_Count;

   function Recheck_Required_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : RM_Closure_Consumer_Stabilized_Diagnostic_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Integration;
