with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Repaired_Coverage_Semantic_Feedback is

   pragma Suppress (Overflow_Check);
   use type Diag.Repair_Gated_Diagnostic_Status;
   use type Diag.Repair_Gated_Diagnostic_Action;
   use type App.Application_Status;
   use type App.Application_Row_Id;
   use type Repair.Repair_Kind;
   use type Enforce.Widened_Legality_Engine;
   use type Audit.Ada_Construct_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 29) mod 2_147_483_647;
   end Mix;

   function Is_Restored (Status : Feedback_Status) return Boolean is
   begin
      return Status in
        Feedback_Construct_Structurally_Restored |
        Feedback_Metadata_Restored |
        Feedback_Consumer_Restored |
        Feedback_Cross_Unit_Metadata_Restored |
        Feedback_Already_Confident |
        Feedback_Eligible_For_Legality;
   end Is_Restored;

   function Is_Eligible (Info : Feedback_Info) return Boolean is
   begin
      return Is_Restored (Info.Feedback)
        and then Info.Feedback /= Feedback_Cross_Unit_Metadata_Restored;
   end Is_Eligible;

   function Has_Blocker (Info : Feedback_Info) return Boolean is
   begin
      return not Is_Restored (Info.Feedback)
        or else Info.Feedback in
          Feedback_Cross_Unit_Still_Required |
          Feedback_Original_Semantic_Error_Preserved |
          Feedback_Partial_Repair_Blocker |
          Feedback_Missing_Repair_Blocker |
          Feedback_Repair_Mismatch_Blocker |
          Feedback_Indeterminate |
          Feedback_Stale_Rejected;
   end Has_Blocker;

   function Classify
     (Application_Status : App.Application_Status;
      Diagnostic_Status  : Diag.Repair_Gated_Diagnostic_Status;
      Diagnostic_Action  : Diag.Repair_Gated_Diagnostic_Action;
      Repair_Kind        : Repair.Repair_Kind)
      return Feedback_Status is
   begin
      if Diagnostic_Status = Diag.Repair_Gated_Diagnostic_Stale_Rejected
        or else Diagnostic_Action = Diag.Repair_Gated_Action_Reject_Stale_Input
      then
         return Feedback_Stale_Rejected;
      elsif Diagnostic_Status = Diag.Repair_Gated_Diagnostic_Original_Error
        or else Diagnostic_Action = Diag.Repair_Gated_Action_Preserve_Original_Error
        or else Application_Status = App.Application_Original_Error_Preserved
      then
         return Feedback_Original_Semantic_Error_Preserved;
      elsif Diagnostic_Status = Diag.Repair_Gated_Diagnostic_Dependency_Failure
        or else Diagnostic_Action = Diag.Repair_Gated_Action_Require_Cross_Unit_Closure
        or else Application_Status = App.Application_Cross_Unit_Still_Required
      then
         return Feedback_Cross_Unit_Still_Required;
      elsif Diagnostic_Status = Diag.Repair_Gated_Diagnostic_Indeterminate
        or else Application_Status in
          App.Application_Repair_Indeterminate |
          App.Application_Enforcement_Still_Blocking
      then
         return Feedback_Indeterminate;
      end if;

      case Application_Status is
         when App.Application_Already_Confident =>
            return Feedback_Already_Confident;
         when App.Application_Repair_Clears_Parser_AST_Blocker |
              App.Application_Repair_Clears_Suppressed_Legal |
              App.Application_Repair_Clears_Suppressed_Derived |
              App.Application_Repair_Clears_Unsafe_Blocker =>
            return Feedback_Construct_Structurally_Restored;
         when App.Application_Repair_Clears_Metadata_Blocker =>
            if Repair_Kind = Repair.Repair_Cross_Unit_Metadata then
               return Feedback_Cross_Unit_Metadata_Restored;
            else
               return Feedback_Metadata_Restored;
            end if;
         when App.Application_Repair_Clears_Consumer_Blocker =>
            return Feedback_Consumer_Restored;
         when App.Application_Repair_Missing =>
            return Feedback_Missing_Repair_Blocker;
         when App.Application_Repair_Partial =>
            return Feedback_Partial_Repair_Blocker;
         when App.Application_Repair_Mismatch =>
            return Feedback_Repair_Mismatch_Blocker;
         when App.Application_Cross_Unit_Still_Required =>
            return Feedback_Cross_Unit_Still_Required;
         when App.Application_Original_Error_Preserved =>
            return Feedback_Original_Semantic_Error_Preserved;
         when App.Application_Not_Checked |
              App.Application_Repair_Indeterminate |
              App.Application_Enforcement_Still_Blocking =>
            return Feedback_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Feedback_Status) return String is
   begin
      case Status is
         when Feedback_Construct_Structurally_Restored =>
            return "repaired parser/AST coverage restores construct as semantic input";
         when Feedback_Metadata_Restored =>
            return "repaired semantic metadata restores construct as legality input";
         when Feedback_Consumer_Restored =>
            return "repaired consumer integration enables construct legality checking";
         when Feedback_Cross_Unit_Metadata_Restored =>
            return "cross-unit metadata repair is recorded for closure-aware consumers";
         when Feedback_Already_Confident =>
            return "construct was already a confident semantic input";
         when Feedback_Eligible_For_Legality =>
            return "construct is eligible for widened legality checking";
         when Feedback_Cross_Unit_Still_Required =>
            return "construct still requires cross-unit semantic closure";
         when Feedback_Original_Semantic_Error_Preserved =>
            return "original semantic error is preserved after repair";
         when Feedback_Partial_Repair_Blocker =>
            return "partial repair remains a semantic blocker";
         when Feedback_Missing_Repair_Blocker =>
            return "missing repair remains a semantic blocker";
         when Feedback_Repair_Mismatch_Blocker =>
            return "repair kind does not clear the gated semantic consumer";
         when Feedback_Indeterminate =>
            return "construct remains indeterminate after repair feedback";
         when Feedback_Stale_Rejected =>
            return "stale repaired coverage input is rejected";
         when Feedback_Not_Checked =>
            return "repaired coverage feedback not checked";
      end case;
   end Message_For;

   function Diagnostic_For
     (Diagnostics    : Diag.Repair_Gated_Diagnostic_Model;
      Application_Id : App.Application_Row_Id)
      return Diag.Repair_Gated_Diagnostic_Info is
      Row : Diag.Repair_Gated_Diagnostic_Info;
   begin
      for Index in 1 .. Diag.Row_Count (Diagnostics) loop
         Row := Diag.Row_At (Diagnostics, Index);
         if Row.Application_Id = Application_Id then
            return Row;
         end if;
      end loop;
      return Row;
   end Diagnostic_For;

   function Make_Row
     (App_Row  : App.Application_Info;
      Diag_Row : Diag.Repair_Gated_Diagnostic_Info)
      return Feedback_Info is
      Row : Feedback_Info;
      Status : constant Feedback_Status :=
        Classify (App_Row.Status,
                  Diag_Row.Status,
                  Diag_Row.Action,
                  App_Row.Repair_Kind);
      FP : Natural := App_Row.Source_Fingerprint;
   begin
      FP := Mix (FP, Feedback_Status'Pos (Status));
      FP := Mix (FP, App.Application_Status'Pos (App_Row.Status));
      FP := Mix (FP, Diag.Repair_Gated_Diagnostic_Status'Pos (Diag_Row.Status));
      FP := Mix (FP, Enforce.Widened_Legality_Engine'Pos (App_Row.Engine));
      FP := Mix (FP, Audit.Ada_Construct_Kind'Pos (App_Row.Construct));
      FP := Mix (FP, Natural (App_Row.Node));

      Row.Id := Feedback_Row_Id (Natural (App_Row.Id));
      Row.Application_Id := App_Row.Id;
      Row.Diagnostic_Id := Diag_Row.Id;
      Row.Application_Status := App_Row.Status;
      Row.Diagnostic_Status := Diag_Row.Status;
      Row.Diagnostic_Action := Diag_Row.Action;
      Row.Feedback := Status;
      Row.Engine := App_Row.Engine;
      Row.Conclusion := App_Row.Conclusion;
      Row.Construct := App_Row.Construct;
      Row.Consumer := App_Row.Consumer;
      Row.Repair_Kind := App_Row.Repair_Kind;
      Row.Repair_Status := App_Row.Repair_Status;
      Row.Node := App_Row.Node;
      Row.Parent_Node := App_Row.Parent_Node;
      Row.Semantic_Row_Id := App_Row.Semantic_Row_Id;
      Row.Construct_Name := App_Row.Construct_Name;
      Row.Normalized_Name := App_Row.Normalized_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("application=" & To_String (App_Row.Message) &
         "; diagnostic=" & To_String (Diag_Row.Message));
      Row.Source_Fingerprint := App_Row.Source_Fingerprint;
      Row.Start_Line := App_Row.Start_Line;
      Row.Start_Column := App_Row.Start_Column;
      Row.End_Line := App_Row.End_Line;
      Row.End_Column := App_Row.End_Column;
      Row.Fingerprint := FP;
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Feedback_Model;
      Row   : Feedback_Info) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
      if Is_Restored (Row.Feedback) then
         Model.Restored_Total := Model.Restored_Total + 1;
      end if;
      if Is_Eligible (Row) then
         Model.Eligible_Total := Model.Eligible_Total + 1;
      end if;
      if Has_Blocker (Row) then
         Model.Blocker_Total := Model.Blocker_Total + 1;
      end if;
      case Row.Feedback is
         when Feedback_Cross_Unit_Still_Required =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Feedback_Original_Semantic_Error_Preserved =>
            Model.Original_Total := Model.Original_Total + 1;
         when Feedback_Stale_Rejected =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Feedback_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;
   end Add_Row;

   function Build
     (Applications : App.Application_Model;
      Diagnostics  : Diag.Repair_Gated_Diagnostic_Model)
      return Feedback_Model is
      Model : Feedback_Model;
   begin
      for Index in 1 .. App.Row_Count (Applications) loop
         declare
            A : constant App.Application_Info := App.Row_At (Applications, Index);
            D : constant Diag.Repair_Gated_Diagnostic_Info :=
              Diagnostic_For (Diagnostics, A.Id);
         begin
            Add_Row (Model, Make_Row (A, D));
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Feedback_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Feedback_Model;
      Index : Positive) return Feedback_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Feedback_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Feedback_Info is
      Row : Feedback_Info;
   begin
      for Item of Model.Rows loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return Row;
   end First_For_Node;

   function Rows_For_Status
     (Model  : Feedback_Model;
      Status : Feedback_Status) return Feedback_Set is
      Set : Feedback_Set;
   begin
      for Row of Model.Rows loop
         if Row.Feedback = Status then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Engine
     (Model  : Feedback_Model;
      Engine : Enforce.Widened_Legality_Engine) return Feedback_Set is
      Set : Feedback_Set;
   begin
      for Row of Model.Rows loop
         if Row.Engine = Engine then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Engine;

   function Rows_For_Construct
     (Model     : Feedback_Model;
      Construct : Audit.Ada_Construct_Kind) return Feedback_Set is
      Set : Feedback_Set;
   begin
      for Row of Model.Rows loop
         if Row.Construct = Construct then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Construct;

   function Set_Count (Set : Feedback_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Feedback_Set;
      Index : Positive) return Feedback_Info is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Feedback_Model;
      Status : Feedback_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Feedback = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Engine
     (Model  : Feedback_Model;
      Engine : Enforce.Widened_Legality_Engine) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Engine = Engine then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Engine;

   function Count_Construct
     (Model     : Feedback_Model;
      Construct : Audit.Ada_Construct_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Construct = Construct then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Construct;

   function Restored_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Restored_Total;
   end Restored_Count;

   function Eligible_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Eligible_Total;
   end Eligible_Count;

   function Blocker_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Blocker_Total;
   end Blocker_Count;

   function Cross_Unit_Required_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Required_Count;

   function Original_Error_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Original_Total;
   end Original_Error_Count;

   function Stale_Rejected_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Rejected_Count;

   function Indeterminate_Count (Model : Feedback_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Feedback_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Is_Eligible_For_Engine
     (Model  : Feedback_Model;
      Node   : Editor.Ada_Syntax_Tree.Node_Id;
      Engine : Enforce.Widened_Legality_Engine) return Boolean is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node and then Row.Engine = Engine then
            return Is_Eligible (Row);
         end if;
      end loop;
      return False;
   end Is_Eligible_For_Engine;

end Editor.Ada_Repaired_Coverage_Semantic_Feedback;
