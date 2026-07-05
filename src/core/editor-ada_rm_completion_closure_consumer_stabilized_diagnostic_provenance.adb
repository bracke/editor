with Editor.Ada_Syntax_Tree;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance is

   pragma Suppress (Overflow_Check);
   use type Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   use type Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Severity;
   use type Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   use type Diag.Closure.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type Diag.Closure.Gate.RM_Closure_Consumer_Stabilization_Gate_Id;
   use type Diag.Closure.Gate.Conv.RM_Closure_Consumer_Convergence_Id;
   use type Diag.Closure.Gate.Conv.Apply.RM_Closure_Consumer_Application_Id;
   use type Diag.Closure.Gate.Conv.Apply.Recheck.RM_Closure_Consumer_Recheck_Id;
   use type Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id;
   use type Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 257) + B + 1282) mod 2_147_483_647;
   end Mix;

   function Status_For
     (Row : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Row)
      return RM_Closure_Consumer_Stabilized_Provenance_Status is
   begin
      if Row.Withheld_Current then
         return RM_Closure_Consumer_Stabilized_Provenance_Withheld_Current_Evidence;
      elsif Row.Requires_Recheck then
         return RM_Closure_Consumer_Stabilized_Provenance_Recheck_Required;
      elsif Row.Status = Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate then
         return RM_Closure_Consumer_Stabilized_Provenance_Indeterminate;
      elsif Row.Status = Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Multiple_Prerequisites then
         return RM_Closure_Consumer_Stabilized_Provenance_Multiple_Prerequisites;
      elsif Row.Severity = Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Error then
         return RM_Closure_Consumer_Stabilized_Provenance_Emitted_Error;
      elsif Row.Severity = Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Warning
        and then Row.Emitted
      then
         return RM_Closure_Consumer_Stabilized_Provenance_Emitted_Warning;
      else
         return RM_Closure_Consumer_Stabilized_Provenance_Not_Checked;
      end if;
   end Status_For;

   function Stage_For
     (Row : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Row)
      return RM_Closure_Consumer_Stabilized_Provenance_Stage is
   begin
      if Row.Stabilization_Id /= Diag.Closure.Gate.No_RM_Closure_Consumer_Stabilization_Gate then
         return RM_Closure_Consumer_Stabilized_Stage_Stabilized_Diagnostic;
      elsif Row.Convergence_Id /= Diag.Closure.Gate.Conv.No_RM_Closure_Consumer_Convergence then
         return RM_Closure_Consumer_Stabilized_Stage_Recheck_Convergence;
      elsif Row.Application_Id /= Diag.Closure.Gate.Conv.Apply.No_RM_Closure_Consumer_Application then
         return RM_Closure_Consumer_Stabilized_Stage_Recheck_Application;
      elsif Row.Eligibility_Id /= Diag.Closure.Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck then
         return RM_Closure_Consumer_Stabilized_Stage_Recheck_Eligibility;
      elsif Row.Worklist_Item /= Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item then
         return RM_Closure_Consumer_Stabilized_Stage_Remediation_Worklist;
      elsif Row.Diagnostic_Row /= Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic then
         return RM_Closure_Consumer_Stabilized_Stage_Original_Diagnostic;
      else
         return RM_Closure_Consumer_Stabilized_Stage_None;
      end if;
   end Stage_For;

   function Blocker_For
     (Row : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Row)
      return RM_Closure_Consumer_Stabilized_Provenance_Blocker is
   begin
      case Row.Family is
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Accepted =>
            return RM_Closure_Consumer_Stabilized_Blocker_None;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Stale_Or_Fingerprint |
              Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Source_Fingerprint |
              Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Stabilized_Blocker_Stale_Or_Fingerprint;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_AST_Or_Coverage =>
            return RM_Closure_Consumer_Stabilized_Blocker_AST_Or_Coverage;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Cross_Unit =>
            return RM_Closure_Consumer_Stabilized_Blocker_Cross_Unit;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Generic_Substitution =>
            return RM_Closure_Consumer_Stabilized_Blocker_Generic_Substitution;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Dataflow =>
            return RM_Closure_Consumer_Stabilized_Blocker_Dataflow;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Volatile_Atomic =>
            return RM_Closure_Consumer_Stabilized_Blocker_Volatile_Atomic;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Overload_Type =>
            return RM_Closure_Consumer_Stabilized_Blocker_Overload_Type;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Representation =>
            return RM_Closure_Consumer_Stabilized_Blocker_Representation;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Tasking_Protected =>
            return RM_Closure_Consumer_Stabilized_Blocker_Tasking_Protected;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Elaboration =>
            return RM_Closure_Consumer_Stabilized_Blocker_Elaboration;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Accessibility =>
            return RM_Closure_Consumer_Stabilized_Blocker_Accessibility;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Discriminant_Variant =>
            return RM_Closure_Consumer_Stabilized_Blocker_Discriminant_Variant;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Exception_Finalization =>
            return RM_Closure_Consumer_Stabilized_Blocker_Exception_Finalization;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Renaming_Alias =>
            return RM_Closure_Consumer_Stabilized_Blocker_Renaming_Alias;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Predicate_Invariant =>
            return RM_Closure_Consumer_Stabilized_Blocker_Predicate_Invariant;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Multiple =>
            return RM_Closure_Consumer_Stabilized_Blocker_Multiple;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Indeterminate =>
            return RM_Closure_Consumer_Stabilized_Blocker_Indeterminate;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Recheck_Required =>
            return RM_Closure_Consumer_Stabilized_Blocker_Recheck_Required;
         when Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Unknown =>
            return RM_Closure_Consumer_Stabilized_Blocker_Unknown;
      end case;
   end Blocker_For;

   function Has_Full_Chain
     (Row : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Row) return Boolean is
   begin
      return Row.Closure_Id /= Diag.Closure.No_RM_Closure_Consumer_Stabilized_Closure
        and then Row.Stabilization_Id /= Diag.Closure.Gate.No_RM_Closure_Consumer_Stabilization_Gate
        and then Row.Convergence_Id /= Diag.Closure.Gate.Conv.No_RM_Closure_Consumer_Convergence
        and then Row.Application_Id /= Diag.Closure.Gate.Conv.Apply.No_RM_Closure_Consumer_Application
        and then Row.Eligibility_Id /= Diag.Closure.Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck
        and then Row.Worklist_Item /= Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item
        and then Row.Diagnostic_Row /= Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
   end Has_Full_Chain;

   function Make_Row
     (Source : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Row;
      Index  : Positive) return RM_Closure_Consumer_Stabilized_Provenance_Row is
      Row : RM_Closure_Consumer_Stabilized_Provenance_Row;
      Text : constant String := To_String (Source.Message);
   begin
      Row.Id := RM_Closure_Consumer_Stabilized_Provenance_Id (Index);
      Row.Stabilized_Diagnostic := Source.Id;
      Row.Closure_Id := Source.Closure_Id;
      Row.Stabilization_Id := Source.Stabilization_Id;
      Row.Convergence_Id := Source.Convergence_Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Original_Diagnostic := Source.Diagnostic_Row;
      Row.Diagnostic_Status := Source.Status;
      Row.Diagnostic_Family := Source.Family;
      Row.Closure_Family := Source.Closure_Family;
      Row.Status := Status_For (Source);
      Row.Stage := Stage_For (Source);
      Row.Blocker := Blocker_For (Source);
      Row.Node := Source.Node;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Semantic_Fingerprint := Source.Semantic_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Closure_Fingerprint := Source.Closure_Fingerprint;
      Row.Emitted := Source.Emitted;
      Row.Withheld_Current := Source.Withheld_Current;
      Row.Requires_Recheck := Source.Requires_Recheck;
      Row.Blocks_Downstream := Source.Blocks_Downstream;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Source.Message;
      Row.Chain_Summary := To_Unbounded_String
        ("Case 1282 provenance chain: stabilized diagnostic -> stabilized closure -> stabilization gate -> convergence -> recheck application -> eligibility -> remediation worklist -> original direct-consumer diagnostic.");
      Row.Provenance_Fingerprint := Mix (12_820, Natural (Row.Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Stabilized_Diagnostic));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Closure_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Stabilization_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Convergence_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Application_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Eligibility_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Worklist_Item));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Original_Diagnostic));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, RM_Closure_Consumer_Stabilized_Provenance_Status'Pos (Row.Status) + 1);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, RM_Closure_Consumer_Stabilized_Provenance_Blocker'Pos (Row.Blocker) + 1);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Row.Source_Fingerprint);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Row.Substitution_Fingerprint);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Row.Closure_Fingerprint);
      for C of Text loop
         Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Character'Pos (C));
      end loop;
      return Row;
   end Make_Row;

   procedure Note
     (Model : in out RM_Closure_Consumer_Stabilized_Provenance_Model;
      Row   : RM_Closure_Consumer_Stabilized_Provenance_Row) is
   begin
      if Row.Withheld_Current then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Row.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      case Row.Status is
         when RM_Closure_Consumer_Stabilized_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when RM_Closure_Consumer_Stabilized_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when RM_Closure_Consumer_Stabilized_Provenance_Recheck_Required =>
            Model.Recheck_Total := Model.Recheck_Total + 1;
         when RM_Closure_Consumer_Stabilized_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when RM_Closure_Consumer_Stabilized_Provenance_Multiple_Prerequisites =>
            Model.Multiple_Total := Model.Multiple_Total + 1;
         when others =>
            null;
      end case;
      if Row.Closure_Id /= Diag.Closure.No_RM_Closure_Consumer_Stabilized_Closure
        and then Row.Stabilization_Id /= Diag.Closure.Gate.No_RM_Closure_Consumer_Stabilization_Gate
        and then Row.Convergence_Id /= Diag.Closure.Gate.Conv.No_RM_Closure_Consumer_Convergence
        and then Row.Application_Id /= Diag.Closure.Gate.Conv.Apply.No_RM_Closure_Consumer_Application
        and then Row.Eligibility_Id /= Diag.Closure.Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck
        and then Row.Worklist_Item /= Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item
        and then Row.Original_Diagnostic /= Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic
      then
         Model.Full_Chain_Link_Total := Model.Full_Chain_Link_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Provenance_Fingerprint);
   end Note;

   procedure Append
     (Set : in out RM_Closure_Consumer_Stabilized_Provenance_Set;
      Row : RM_Closure_Consumer_Stabilized_Provenance_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Provenance_Fingerprint);
   end Append;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Provenance_Model) is
   begin
      Model.Rows.Clear;
      Model.Withheld_Total := 0;
      Model.Emitted_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Total := 0;
      Model.Full_Chain_Link_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Diagnostics : Diag.RM_Closure_Consumer_Stabilized_Diagnostic_Model)
      return RM_Closure_Consumer_Stabilized_Provenance_Model is
      Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Row   : RM_Closure_Consumer_Stabilized_Provenance_Row;
   begin
      for I in 1 .. Diag.Row_Count (Diagnostics) loop
         Row := Make_Row (Diag.Row_At (Diagnostics, I), I);
         Model.Rows.Append (Row);
         Note (Model, Row);
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Provenance_Row is
   begin
      if Index > Row_Count (Model) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Stabilized_Provenance_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Stabilized_Provenance_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Provenance_Row is
   begin
      if Index > Query_Count (Set) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status)
      return RM_Closure_Consumer_Stabilized_Provenance_Set is
      Result : RM_Closure_Consumer_Stabilized_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker)
      return RM_Closure_Consumer_Stabilized_Provenance_Set is
      Result : RM_Closure_Consumer_Stabilized_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker = Blocker then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Stage
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage)
      return RM_Closure_Consumer_Stabilized_Provenance_Set is
      Result : RM_Closure_Consumer_Stabilized_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Stage = Stage then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Stage;

   function Query_Node
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Stabilized_Provenance_Set is
      Result : RM_Closure_Consumer_Stabilized_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_Status
     (Model  : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Stage
     (Model : RM_Closure_Consumer_Stabilized_Provenance_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage) return Natural is
   begin
      return Query_Count (Query_Stage (Model, Stage));
   end Count_Stage;

   function Withheld_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Emitted_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Error_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Recheck_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Count;

   function Full_Chain_Link_Count (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Full_Chain_Link_Total;
   end Full_Chain_Link_Count;

   function Fingerprint (Model : RM_Closure_Consumer_Stabilized_Provenance_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance;
