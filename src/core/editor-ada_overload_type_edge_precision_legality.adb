with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Type_Edge_Precision_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Expr_AST.Expression_Construct_AST_Repair_Row_Id;
   use type Expr_AST.Expression_Construct_AST_Repair_Status;
   use type Replay_CPD.Generic_Replay_Representation_Row_Id;
   use type Replay_CPD.Generic_Replay_Representation_Status;
   use type RM_Edge.RM_Edge_Legality_Id;
   use type RM_Edge.RM_Edge_Legality_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Status_Slot (Status : Overload_Type_Edge_Status) return Natural is
   begin
      return Overload_Type_Edge_Status'Pos (Status) + 1;
   end Status_Slot;

   function Kind_Slot (Kind : Overload_Type_Edge_Context_Kind) return Natural is
   begin
      return Overload_Type_Edge_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function RM_Is_Legal (Status : RM_Edge.RM_Edge_Legality_Status) return Boolean is
   begin
      return Status in
        RM_Edge.RM_Edge_Legality_Legal_Universal_Integer |
        RM_Edge.RM_Edge_Legality_Legal_Universal_Real |
        RM_Edge.RM_Edge_Legality_Legal_Universal_Fixed |
        RM_Edge.RM_Edge_Legality_Legal_Root_Numeric_Preferred |
        RM_Edge.RM_Edge_Legality_Legal_Inherited_Primitive_Visible |
        RM_Edge.RM_Edge_Legality_Legal_Homograph_Hidden |
        RM_Edge.RM_Edge_Legality_Legal_Dispatching_Selected |
        RM_Edge.RM_Edge_Legality_Legal_Nondispatching_Selected |
        RM_Edge.RM_Edge_Legality_Legal_Access_Subprogram_Profile |
        RM_Edge.RM_Edge_Legality_Legal_Generic_Formal_Subprogram |
        RM_Edge.RM_Edge_Legality_Legal_Nested_Generic_Selected;
   end RM_Is_Legal;

   function RM_Is_Ambiguous (Status : RM_Edge.RM_Edge_Legality_Status) return Boolean is
   begin
      return Status in
        RM_Edge.RM_Edge_Legality_Universal_Fixed_Ambiguous |
        RM_Edge.RM_Edge_Legality_Root_Numeric_Ambiguous |
        RM_Edge.RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous |
        RM_Edge.RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous |
        RM_Edge.RM_Edge_Legality_Generic_Formal_Subprogram_Ambiguous |
        RM_Edge.RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous |
        RM_Edge.RM_Edge_Legality_Nested_Generic_Named_Actual_Ambiguous;
   end RM_Is_Ambiguous;

   function Expr_Is_Blocker
     (Status : Expr_AST.Expression_Construct_AST_Repair_Status) return Boolean is
   begin
      return Status /= Expr_AST.Expression_Construct_AST_Not_Checked
        and then not Expr_AST.Is_Accepted (Status);
   end Expr_Is_Blocker;

   function Replay_CPD_Is_Legal
     (Status : Replay_CPD.Generic_Replay_Representation_Status) return Boolean is
   begin
      return Replay_CPD.Is_Legal (Status);
   end Replay_CPD_Is_Legal;

   function Replay_CPD_Is_Blocker
     (Status : Replay_CPD.Generic_Replay_Representation_Status) return Boolean is
   begin
      return Status /= Replay_CPD.Generic_Replay_Representation_Not_Checked
        and then not Replay_CPD_Is_Legal (Status)
        and then Status /= Replay_CPD.Generic_Replay_Representation_Indeterminate
        and then Status /= Replay_CPD.Generic_Replay_Representation_Representation_CPD_Indeterminate;
   end Replay_CPD_Is_Blocker;

   function Needed_Expression_AST (Kind : Overload_Type_Edge_Context_Kind) return Boolean is
   begin
      return Kind in
        Overload_Type_Edge_Access_To_Subprogram |
        Overload_Type_Edge_Universal_Fixed |
        Overload_Type_Edge_Root_Numeric |
        Overload_Type_Edge_Dispatching_Operation |
        Overload_Type_Edge_Class_Wide_Controlling |
        Overload_Type_Edge_Nested_Generic_Call;
   end Needed_Expression_AST;

   function Needed_Generic_Replay_CPD (Kind : Overload_Type_Edge_Context_Kind) return Boolean is
   begin
      return Kind in
        Overload_Type_Edge_Generic_Formal_Subprogram |
        Overload_Type_Edge_Nested_Generic_Call |
        Overload_Type_Edge_Inherited_Primitive |
        Overload_Type_Edge_Class_Wide_Controlling;
   end Needed_Generic_Replay_CPD;

   function Is_Legal (Status : Overload_Type_Edge_Status) return Boolean is
   begin
      return Status in
        Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted |
        Overload_Type_Edge_Legal_Universal_Fixed_Preferred |
        Overload_Type_Edge_Legal_Root_Numeric_Preferred |
        Overload_Type_Edge_Legal_Inherited_Primitive_Selected |
        Overload_Type_Edge_Legal_Dispatching_Selected |
        Overload_Type_Edge_Legal_Nondispatching_Selected |
        Overload_Type_Edge_Legal_Generic_Formal_Subprogram_Accepted |
        Overload_Type_Edge_Legal_Nested_Generic_Selected |
        Overload_Type_Edge_Legal_Class_Wide_Controlling_Accepted;
   end Is_Legal;

   function Is_Ambiguous (Status : Overload_Type_Edge_Status) return Boolean is
   begin
      return Status in
        Overload_Type_Edge_RM_Edge_Ambiguous |
        Overload_Type_Edge_Universal_Fixed_Ambiguous |
        Overload_Type_Edge_Root_Numeric_Ambiguous |
        Overload_Type_Edge_Inherited_Primitive_Hiding_Ambiguous |
        Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous |
        Overload_Type_Edge_Generic_Formal_Subprogram_Ambiguous |
        Overload_Type_Edge_Nested_Defaulted_Formal_Ambiguous |
        Overload_Type_Edge_Nested_Named_Actual_Ambiguous |
        Overload_Type_Edge_Class_Wide_Controlling_Ambiguous;
   end Is_Ambiguous;

   function Classify (Info : Overload_Type_Edge_Context_Info) return Overload_Type_Edge_Status is
      Blockers : Natural := 0;
   begin
      if Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Indeterminate then
         Blockers := Blockers + 1;
      elsif RM_Is_Ambiguous (Info.RM_Edge_Status) then
         Blockers := Blockers + 1;
      elsif Info.RM_Edge_Status /= RM_Edge.RM_Edge_Legality_Not_Checked
        and then not RM_Is_Legal (Info.RM_Edge_Status)
      then
         Blockers := Blockers + 1;
      end if;

      if Needed_Expression_AST (Info.Kind)
        and then Info.Expression_AST_Status = Expr_AST.Expression_Construct_AST_Not_Checked
      then
         Blockers := Blockers + 1;
      elsif Expr_Is_Blocker (Info.Expression_AST_Status) then
         Blockers := Blockers + 1;
      end if;

      if Needed_Generic_Replay_CPD (Info.Kind)
        and then Info.Generic_Replay_CPD_Status = Replay_CPD.Generic_Replay_Representation_Not_Checked
      then
         Blockers := Blockers + 1;
      elsif Replay_CPD_Is_Blocker (Info.Generic_Replay_CPD_Status) then
         Blockers := Blockers + 1;
      elsif Info.Generic_Replay_CPD_Status in
        Replay_CPD.Generic_Replay_Representation_Indeterminate |
        Replay_CPD.Generic_Replay_Representation_Representation_CPD_Indeterminate
      then
         Blockers := Blockers + 1;
      end if;

      if Blockers > 1 then
         return Overload_Type_Edge_Multiple_Blockers;
      end if;

      if Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Indeterminate then
         return Overload_Type_Edge_Indeterminate;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Access_Subprogram_Profile_Mismatch
        or else Info.Access_Profile_Mismatch_Count > 0
      then
         return Overload_Type_Edge_Access_Profile_Mismatch;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Access_Subprogram_Mode_Mismatch
        or else Info.Access_Mode_Mismatch_Count > 0
      then
         return Overload_Type_Edge_Access_Mode_Mismatch;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Access_Subprogram_Result_Mismatch
        or else Info.Access_Result_Mismatch_Count > 0
      then
         return Overload_Type_Edge_Access_Result_Mismatch;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Universal_Fixed_Ambiguous then
         return Overload_Type_Edge_Universal_Fixed_Ambiguous;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Root_Numeric_Ambiguous then
         return Overload_Type_Edge_Root_Numeric_Ambiguous;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Inherited_Primitive_Hiding_Ambiguous then
         return Overload_Type_Edge_Inherited_Primitive_Hiding_Ambiguous;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Dispatching_Nondispatching_Ambiguous then
         return Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Generic_Formal_Subprogram_Ambiguous then
         return Overload_Type_Edge_Generic_Formal_Subprogram_Ambiguous;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Nested_Generic_Defaulted_Formal_Ambiguous
        or else Info.Defaulted_Formal_Tie_Count > 1
      then
         return Overload_Type_Edge_Nested_Defaulted_Formal_Ambiguous;
      elsif Info.RM_Edge_Status = RM_Edge.RM_Edge_Legality_Nested_Generic_Named_Actual_Ambiguous
        or else Info.Named_Actual_Tie_Count > 1
      then
         return Overload_Type_Edge_Nested_Named_Actual_Ambiguous;
      elsif RM_Is_Ambiguous (Info.RM_Edge_Status) then
         return Overload_Type_Edge_RM_Edge_Ambiguous;
      elsif Info.RM_Edge_Status /= RM_Edge.RM_Edge_Legality_Not_Checked
        and then not RM_Is_Legal (Info.RM_Edge_Status)
      then
         return Overload_Type_Edge_Base_RM_Edge_Error;
      end if;

      if Needed_Expression_AST (Info.Kind)
        and then Info.Expression_AST_Status = Expr_AST.Expression_Construct_AST_Not_Checked
      then
         return Overload_Type_Edge_Missing_Expression_AST_Repair;
      elsif Expr_Is_Blocker (Info.Expression_AST_Status) then
         return Overload_Type_Edge_Expression_AST_Repair_Blocker;
      end if;

      if Needed_Generic_Replay_CPD (Info.Kind)
        and then Info.Generic_Replay_CPD_Status = Replay_CPD.Generic_Replay_Representation_Not_Checked
      then
         return Overload_Type_Edge_Missing_Generic_Replay_CPD_Row;
      elsif Replay_CPD_Is_Blocker (Info.Generic_Replay_CPD_Status) then
         return Overload_Type_Edge_Generic_Replay_CPD_Blocker;
      elsif Info.Generic_Replay_CPD_Status in
        Replay_CPD.Generic_Replay_Representation_Indeterminate |
        Replay_CPD.Generic_Replay_Representation_Representation_CPD_Indeterminate
      then
         return Overload_Type_Edge_Generic_Replay_CPD_Indeterminate;
      end if;

      case Info.Kind is
         when Overload_Type_Edge_Access_To_Subprogram =>
            return Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted;
         when Overload_Type_Edge_Universal_Fixed =>
            return Overload_Type_Edge_Legal_Universal_Fixed_Preferred;
         when Overload_Type_Edge_Root_Numeric =>
            return Overload_Type_Edge_Legal_Root_Numeric_Preferred;
         when Overload_Type_Edge_Inherited_Primitive =>
            return Overload_Type_Edge_Legal_Inherited_Primitive_Selected;
         when Overload_Type_Edge_Dispatching_Operation =>
            if Info.Dispatching_Candidate_Count > 0
              and then Info.Nondispatching_Candidate_Count = 0
            then
               return Overload_Type_Edge_Legal_Dispatching_Selected;
            elsif Info.Nondispatching_Candidate_Count > 0
              and then Info.Dispatching_Candidate_Count = 0
            then
               return Overload_Type_Edge_Legal_Nondispatching_Selected;
            elsif Info.Dispatching_Candidate_Count > 0
              and then Info.Nondispatching_Candidate_Count > 0
            then
               return Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous;
            else
               return Overload_Type_Edge_Legal_Dispatching_Selected;
            end if;
         when Overload_Type_Edge_Generic_Formal_Subprogram =>
            return Overload_Type_Edge_Legal_Generic_Formal_Subprogram_Accepted;
         when Overload_Type_Edge_Nested_Generic_Call =>
            return Overload_Type_Edge_Legal_Nested_Generic_Selected;
         when Overload_Type_Edge_Class_Wide_Controlling =>
            if Info.Class_Wide_Controlling_Count > 1 then
               return Overload_Type_Edge_Class_Wide_Controlling_Ambiguous;
            else
               return Overload_Type_Edge_Legal_Class_Wide_Controlling_Accepted;
            end if;
         when Overload_Type_Edge_Unknown =>
            return Overload_Type_Edge_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Overload_Type_Edge_Status) return String is
   begin
      case Status is
         when Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted =>
            return "access-to-subprogram overload profile accepted with repaired expression and type evidence";
         when Overload_Type_Edge_Legal_Universal_Fixed_Preferred =>
            return "universal fixed overload preference accepted";
         when Overload_Type_Edge_Legal_Root_Numeric_Preferred =>
            return "root numeric overload preference accepted";
         when Overload_Type_Edge_Legal_Inherited_Primitive_Selected =>
            return "inherited primitive overload selected after hiding checks";
         when Overload_Type_Edge_Legal_Dispatching_Selected =>
            return "dispatching operation overload selected";
         when Overload_Type_Edge_Legal_Nondispatching_Selected =>
            return "nondispatching operation overload selected";
         when Overload_Type_Edge_Legal_Generic_Formal_Subprogram_Accepted =>
            return "generic formal subprogram overload accepted with replay evidence";
         when Overload_Type_Edge_Legal_Nested_Generic_Selected =>
            return "nested generic overload selected after named/defaulted formal checks";
         when Overload_Type_Edge_Legal_Class_Wide_Controlling_Accepted =>
            return "class-wide controlling overload evidence accepted";
         when Overload_Type_Edge_Base_RM_Edge_Error =>
            return "base RM overload edge error blocks precision result";
         when Overload_Type_Edge_RM_Edge_Ambiguous =>
            return "base RM overload edge remains ambiguous";
         when Overload_Type_Edge_Access_Profile_Mismatch =>
            return "access-to-subprogram overload profile mismatch";
         when Overload_Type_Edge_Access_Mode_Mismatch =>
            return "access-to-subprogram overload mode mismatch";
         when Overload_Type_Edge_Access_Result_Mismatch =>
            return "access-to-subprogram overload result mismatch";
         when Overload_Type_Edge_Universal_Fixed_Ambiguous =>
            return "universal fixed overload preference remains ambiguous";
         when Overload_Type_Edge_Root_Numeric_Ambiguous =>
            return "root numeric overload preference remains ambiguous";
         when Overload_Type_Edge_Inherited_Primitive_Hiding_Ambiguous =>
            return "inherited primitive hiding leaves ambiguous overloads";
         when Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous =>
            return "dispatching and nondispatching overload candidates remain ambiguous";
         when Overload_Type_Edge_Generic_Formal_Subprogram_Ambiguous =>
            return "generic formal subprogram overload remains ambiguous";
         when Overload_Type_Edge_Nested_Defaulted_Formal_Ambiguous =>
            return "nested generic defaulted formal overload remains ambiguous";
         when Overload_Type_Edge_Nested_Named_Actual_Ambiguous =>
            return "nested generic named actual overload remains ambiguous";
         when Overload_Type_Edge_Class_Wide_Controlling_Ambiguous =>
            return "class-wide controlling overload remains ambiguous";
         when Overload_Type_Edge_Missing_Expression_AST_Repair =>
            return "expression construct AST repair evidence is missing";
         when Overload_Type_Edge_Expression_AST_Repair_Blocker =>
            return "expression construct AST repair blocks overload/type precision";
         when Overload_Type_Edge_Missing_Generic_Replay_CPD_Row =>
            return "generic replay representation contract-predicate/dataflow evidence is missing";
         when Overload_Type_Edge_Generic_Replay_CPD_Blocker =>
            return "generic replay representation contract-predicate/dataflow evidence blocks overload/type precision";
         when Overload_Type_Edge_Generic_Replay_CPD_Indeterminate =>
            return "generic replay representation contract-predicate/dataflow evidence is indeterminate";
         when Overload_Type_Edge_Multiple_Blockers =>
            return "multiple overload/type precision blockers are present";
         when Overload_Type_Edge_Indeterminate =>
            return "overload/type edge precision is indeterminate";
         when Overload_Type_Edge_Not_Checked =>
            return "overload/type edge precision not checked";
      end case;
   end Message_For;

   function Row_Fingerprint (Info : Overload_Type_Edge_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.RM_Edge_Row) + 1);
      H := Mix (H, RM_Edge.RM_Edge_Legality_Status'Pos (Info.RM_Edge_Status) + 1);
      H := Mix (H, Expr_AST.Expression_Construct_AST_Repair_Status'Pos (Info.Expression_AST_Status) + 1);
      H := Mix (H, Replay_CPD.Generic_Replay_Representation_Status'Pos (Info.Generic_Replay_CPD_Status) + 1);
      H := Mix (H, Info.Selected_Candidate_Count + 1);
      H := Mix (H, Info.Ambiguous_Candidate_Count + 1);
      H := Mix (H, Info.Blocker_Count + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Length (Info.Expected_Type_Name) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Make_Row (Info : Overload_Type_Edge_Context_Info) return Overload_Type_Edge_Info is
      Status : constant Overload_Type_Edge_Status := Classify (Info);
      Row : Overload_Type_Edge_Info;
   begin
      Row.Id := Info.Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Node := Info.Node;
      Row.Status := Status;
      Row.Designator := Info.Designator;
      Row.Target_Type_Name := Info.Target_Type_Name;
      Row.Expected_Type_Name := Info.Expected_Type_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String ("Case 1179 overload/type precision consumer row");
      Row.RM_Edge_Row := Info.RM_Edge_Row;
      Row.RM_Edge_Status := Info.RM_Edge_Status;
      Row.Expression_AST_Row := Info.Expression_AST_Row;
      Row.Expression_AST_Status := Info.Expression_AST_Status;
      Row.Generic_Replay_CPD_Row := Info.Generic_Replay_CPD_Row;
      Row.Generic_Replay_CPD_Status := Info.Generic_Replay_CPD_Status;
      Row.Selected_Candidate_Count := Info.Selected_Candidate_Count;
      Row.Ambiguous_Candidate_Count := Info.Ambiguous_Candidate_Count;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      if not Is_Legal (Status) then
         Row.Blocker_Count := 1;
      end if;
      if Status = Overload_Type_Edge_Multiple_Blockers then
         Row.Blocker_Count := 2;
      end if;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Overload_Type_Edge_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Overload_Type_Edge_Context_Model;
      Info  : Overload_Type_Edge_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Kind_Slot (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Overload_Type_Edge_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Overload_Type_Edge_Context_Model;
      Index : Positive) return Overload_Type_Edge_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Overload_Type_Edge_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Overload_Type_Edge_Context_Model) return Overload_Type_Edge_Model is
      Model : Overload_Type_Edge_Model;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            Row : constant Overload_Type_Edge_Info := Make_Row (Contexts.Contexts.Element (I));
         begin
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint + 1);
            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;
            if Is_Ambiguous (Row.Status) then
               Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
            end if;
            if Row.Status in Overload_Type_Edge_Missing_Expression_AST_Repair |
              Overload_Type_Edge_Expression_AST_Repair_Blocker
            then
               Model.AST_Blocker_Total := Model.AST_Blocker_Total + 1;
            end if;
            if Row.Status in Overload_Type_Edge_Missing_Generic_Replay_CPD_Row |
              Overload_Type_Edge_Generic_Replay_CPD_Blocker |
              Overload_Type_Edge_Generic_Replay_CPD_Indeterminate
            then
               Model.Generic_Replay_Blocker_Total := Model.Generic_Replay_Blocker_Total + 1;
            end if;
            if Row.Status = Overload_Type_Edge_Multiple_Blockers then
               Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
            end if;
            if Row.Status = Overload_Type_Edge_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Overload_Type_Edge_Model;
      Index : Positive) return Overload_Type_Edge_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Overload_Type_Edge_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Type_Edge_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Overload_Type_Edge_Model;
      Status : Overload_Type_Edge_Status) return Overload_Type_Edge_Result_Set is
      Results : Overload_Type_Edge_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Overload_Type_Edge_Model;
      Kind  : Overload_Type_Edge_Context_Kind) return Overload_Type_Edge_Result_Set is
      Results : Overload_Type_Edge_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Designator
     (Model      : Overload_Type_Edge_Model;
      Designator : String) return Overload_Type_Edge_Result_Set is
      Results : Overload_Type_Edge_Result_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Designator) = Designator then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Designator;

   function Result_Count (Results : Overload_Type_Edge_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Overload_Type_Edge_Result_Set;
      Index   : Positive) return Overload_Type_Edge_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Overload_Type_Edge_Model;
      Status : Overload_Type_Edge_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Overload_Type_Edge_Model;
      Kind  : Overload_Type_Edge_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Ambiguous_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function AST_Blocker_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.AST_Blocker_Total;
   end AST_Blocker_Count;

   function Generic_Replay_Blocker_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Generic_Replay_Blocker_Total;
   end Generic_Replay_Blocker_Count;

   function Multiple_Blocker_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Indeterminate_Count (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Overload_Type_Edge_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Error (Info : Overload_Type_Edge_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status);
   end Has_Error;

end Editor.Ada_Overload_Type_Edge_Precision_Legality;
