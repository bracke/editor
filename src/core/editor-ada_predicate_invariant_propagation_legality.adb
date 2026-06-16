with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Predicate_Invariant_Propagation_Legality is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Flow_Effect_Graph_Legality.Flow_Effect_Graph_Status;
   use type Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Status;

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Left) * 151 + Long_Long_Integer (Right) * 37 + 1139)
        mod 2_147_483_647;
   begin
      return Natural (Hash);
   end Mix;

   function Node_Slot (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node);
   exception
      when Constraint_Error =>
         return 0;
   end Node_Slot;

   function Is_Legal (Status : Propagation_Status) return Boolean is
   begin
      return Status in
        Propagation_Legal_Static_Predicate_Preserved |
        Propagation_Legal_Dynamic_Predicate_Propagated |
        Propagation_Legal_Invariant_Preserved |
        Propagation_Legal_Dynamic_Invariant_Propagated |
        Propagation_Legal_Generic_Substitution_Propagated |
        Propagation_Legal_Derived_Invariant_Propagated |
        Propagation_Legal_Private_Full_View_Propagated |
        Propagation_Legal_Flow_Effect_Propagated;
   end Is_Legal;

   function Is_Error (Status : Propagation_Status) return Boolean is
   begin
      return Status not in Propagation_Not_Checked | Propagation_Indeterminate
        and then not Is_Legal (Status);
   end Is_Error;

   function Predicate_Error (Status : Propagation_Status) return Boolean is
   begin
      return Status in
        Propagation_Static_Predicate_Lost |
        Propagation_Dynamic_Predicate_Lost |
        Propagation_Call_Chain_Check_Missing |
        Propagation_Generic_Actual_Check_Missing |
        Propagation_Linked_Predicate_Use_Error;
   end Predicate_Error;

   function Invariant_Error (Status : Propagation_Status) return Boolean is
   begin
      return Status in
        Propagation_Invariant_Lost |
        Propagation_Invariant_Violated_After_State_Update |
        Propagation_Derived_Type_Invariant_Missing |
        Propagation_Private_View_Barrier |
        Propagation_Private_Full_View_Mismatch;
   end Invariant_Error;

   function PIU_Legal (Status : PIU.Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        PIU.Predicate_Use_Legality_Legal_Static_Predicate |
        PIU.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check |
        PIU.Predicate_Use_Legality_Legal_Invariant_Preserved |
        PIU.Predicate_Use_Legality_Legal_Dynamic_Invariant_Check |
        PIU.Predicate_Use_Legality_Legal_Static_Range_And_Predicate |
        PIU.Predicate_Use_Legality_Legal_Linked_Assignment |
        PIU.Predicate_Use_Legality_Legal_Linked_Return |
        PIU.Predicate_Use_Legality_Legal_Linked_Semantic |
        PIU.Predicate_Use_Legality_Legal_Linked_Overload |
        PIU.Predicate_Use_Legality_Legal_Linked_Generic_Actual;
   end PIU_Legal;

   function PIU_Error (Status : PIU.Predicate_Use_Legality_Status) return Boolean is
   begin
      return Status in
        PIU.Predicate_Use_Legality_Static_Predicate_Failure |
        PIU.Predicate_Use_Legality_Predicate_Unresolved |
        PIU.Predicate_Use_Legality_Predicate_Non_Static_Where_Static_Required |
        PIU.Predicate_Use_Legality_Invariant_Violation |
        PIU.Predicate_Use_Legality_Invariant_Unresolved |
        PIU.Predicate_Use_Legality_Invariant_Private_View_Barrier |
        PIU.Predicate_Use_Legality_Missing_Check_At_Assignment |
        PIU.Predicate_Use_Legality_Missing_Check_At_Return |
        PIU.Predicate_Use_Legality_Missing_Check_At_Conversion |
        PIU.Predicate_Use_Legality_Missing_Check_At_Aggregate |
        PIU.Predicate_Use_Legality_Missing_Check_At_Call |
        PIU.Predicate_Use_Legality_Missing_Check_At_Generic_Actual |
        PIU.Predicate_Use_Legality_Linked_Staticness_Error |
        PIU.Predicate_Use_Legality_Linked_Assignment_Error |
        PIU.Predicate_Use_Legality_Linked_Return_Error |
        PIU.Predicate_Use_Legality_Linked_Semantic_Error |
        PIU.Predicate_Use_Legality_Linked_Overload_Error |
        PIU.Predicate_Use_Legality_Linked_Generic_Actual_Error |
        PIU.Predicate_Use_Legality_Universal_Numeric_Unresolved |
        PIU.Predicate_Use_Legality_Cross_Unit_Unresolved_View;
   end PIU_Error;

   function Flow_Legal (Status : FEG.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        FEG.Flow_Graph_Legal_Read_Edge |
        FEG.Flow_Graph_Legal_Write_Edge |
        FEG.Flow_Graph_Legal_Read_Write_Edge |
        FEG.Flow_Graph_Legal_Depends_Edge |
        FEG.Flow_Graph_Legal_Call_Propagation |
        FEG.Flow_Graph_Legal_Generic_Substitution |
        FEG.Flow_Graph_Legal_Protected_State_Effect |
        FEG.Flow_Graph_Legal_Task_Activation_Effect |
        FEG.Flow_Graph_Legal_Refined_Global |
        FEG.Flow_Graph_Legal_Refined_Depends |
        FEG.Flow_Graph_Legal_Null_Effect;
   end Flow_Legal;

   function Flow_Error (Status : FEG.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status not in FEG.Flow_Graph_Not_Checked | FEG.Flow_Graph_Indeterminate
        and then not Flow_Legal (Status);
   end Flow_Error;

   function Gate_Blocks (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status in
        Gates.Enforcement_Legal_Result_Suppressed |
        Gates.Enforcement_Derived_Result_Suppressed |
        Gates.Enforcement_Parser_AST_Blocker |
        Gates.Enforcement_Metadata_Blocker |
        Gates.Enforcement_Consumer_Integration_Blocker |
        Gates.Enforcement_Unsafe_Result_Blocked;
   end Gate_Blocks;

   function Context_Fingerprint (Info : Propagation_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Propagation_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Propagation_Obligation_Kind'Pos (Info.Obligation) + 1);
      H := Mix (H, Node_Slot (Info.Node) + 1);
      H := Mix (H, Node_Slot (Info.Source_Node) + 1);
      H := Mix (H, Node_Slot (Info.Target_Node) + 1);
      H := Mix (H, Length (Info.Subtype_Name) + 1);
      H := Mix (H, Length (Info.Object_Name) + 1);
      H := Mix (H, Length (Info.Caller_Name) + Length (Info.Callee_Name) + 1);
      H := Mix (H, Length (Info.Generic_Formal_Name) + Length (Info.Generic_Actual_Name) + 1);
      H := Mix (H, PIU.Predicate_Use_Legality_Status'Pos (Info.Predicate_Use_Status) + 1);
      H := Mix (H, FEG.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Check_Propagated)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.State_Was_Updated)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.State_Covered_By_Flow)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Generic_Substitution_Preserves_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Derived_View_Preserves_Invariant)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Private_View_Resolved)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Dynamic_Check)) + 1);
      H := Mix (H, Info.Start_Line + Info.End_Line + Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Propagation_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Propagation_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Propagation_Obligation_Kind'Pos (Info.Obligation) + 1);
      H := Mix (H, Propagation_Status'Pos (Info.Status) + 1);
      H := Mix (H, Node_Slot (Info.Node) + 1);
      H := Mix (H, Length (Info.Subtype_Name) + Length (Info.Object_Name) + 1);
      H := Mix (H, Length (Info.Caller_Name) + Length (Info.Callee_Name) + 1);
      H := Mix (H, PIU.Predicate_Use_Legality_Status'Pos (Info.Predicate_Use_Status) + 1);
      H := Mix (H, FEG.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Propagation_Status) return String is
   begin
      case Status is
         when Propagation_Legal_Static_Predicate_Preserved =>
            return "static predicate obligation is preserved across the semantic edge";
         when Propagation_Legal_Dynamic_Predicate_Propagated =>
            return "dynamic predicate check is propagated to the downstream semantic edge";
         when Propagation_Legal_Invariant_Preserved =>
            return "type invariant is preserved across the semantic edge";
         when Propagation_Legal_Dynamic_Invariant_Propagated =>
            return "dynamic invariant check is propagated to the downstream semantic edge";
         when Propagation_Legal_Generic_Substitution_Propagated =>
            return "generic actual/formal substitution preserves predicate and invariant checks";
         when Propagation_Legal_Derived_Invariant_Propagated =>
            return "derived type preserves inherited invariant obligations";
         when Propagation_Legal_Private_Full_View_Propagated =>
            return "private and full views preserve the same predicate or invariant obligation";
         when Propagation_Legal_Flow_Effect_Propagated =>
            return "flow-effect graph preserves the predicate or invariant obligation";
         when Propagation_Static_Predicate_Lost =>
            return "static predicate obligation is lost before the downstream semantic use";
         when Propagation_Dynamic_Predicate_Lost =>
            return "dynamic predicate check is not propagated to the downstream semantic use";
         when Propagation_Invariant_Lost =>
            return "type invariant obligation is lost before the downstream semantic use";
         when Propagation_Invariant_Violated_After_State_Update =>
            return "visible state update may violate the type invariant";
         when Propagation_Call_Chain_Check_Missing =>
            return "call chain does not propagate the predicate or invariant check";
         when Propagation_Generic_Actual_Check_Missing =>
            return "generic actual/formal substitution does not preserve the check";
         when Propagation_Derived_Type_Invariant_Missing =>
            return "derived type does not preserve the inherited invariant";
         when Propagation_Private_View_Barrier =>
            return "private view prevents proving predicate or invariant propagation";
         when Propagation_Private_Full_View_Mismatch =>
            return "private and full views disagree on predicate or invariant propagation";
         when Propagation_Flow_Effect_Uncovered_State_Update =>
            return "flow-effect graph does not cover a state update requiring invariant recheck";
         when Propagation_Linked_Predicate_Use_Error =>
            return "linked predicate use-site legality already failed";
         when Propagation_Linked_Flow_Effect_Error =>
            return "linked flow-effect graph legality already failed";
         when Propagation_Coverage_Gate_Blocker =>
            return "coverage gate blocks a confident predicate or invariant propagation conclusion";
         when Propagation_Indeterminate =>
            return "predicate or invariant propagation is indeterminate";
         when Propagation_Not_Checked =>
            return "predicate or invariant propagation was not checked";
      end case;
   end Message_For;

   function Classify (Info : Propagation_Context_Info) return Propagation_Status is
   begin
      if Gate_Blocks (Info.Gate_Status) then
         return Propagation_Coverage_Gate_Blocker;
      elsif PIU_Error (Info.Predicate_Use_Status) then
         return Propagation_Linked_Predicate_Use_Error;
      elsif Flow_Error (Info.Flow_Status) then
         return Propagation_Linked_Flow_Effect_Error;
      elsif not Info.Private_View_Resolved then
         return Propagation_Private_View_Barrier;
      elsif Info.Kind = Propagation_Context_Private_View
        and then not Info.Derived_View_Preserves_Invariant
      then
         return Propagation_Private_Full_View_Mismatch;
      elsif Info.Kind = Propagation_Context_Generic_Instance
        and then not Info.Generic_Substitution_Preserves_Check
      then
         return Propagation_Generic_Actual_Check_Missing;
      elsif Info.Kind = Propagation_Context_Derived_Type
        and then not Info.Derived_View_Preserves_Invariant
      then
         return Propagation_Derived_Type_Invariant_Missing;
      elsif Info.State_Was_Updated
        and then Info.Obligation in Obligation_Type_Invariant | Obligation_Dynamic_Invariant |
                                Obligation_State_Update_Invariant
        and then not Info.State_Covered_By_Flow
      then
         return Propagation_Flow_Effect_Uncovered_State_Update;
      elsif Info.State_Was_Updated
        and then Info.Obligation in Obligation_Type_Invariant | Obligation_Dynamic_Invariant |
                                Obligation_State_Update_Invariant
        and then not Info.Check_Propagated
      then
         return Propagation_Invariant_Violated_After_State_Update;
      elsif Info.Requires_Check and then not Info.Check_Propagated then
         case Info.Kind is
            when Propagation_Context_Call_Source | Propagation_Context_Call_Result =>
               return Propagation_Call_Chain_Check_Missing;
            when Propagation_Context_Generic_Instance =>
               return Propagation_Generic_Actual_Check_Missing;
            when Propagation_Context_Derived_Type =>
               return Propagation_Derived_Type_Invariant_Missing;
            when others =>
               case Info.Obligation is
                  when Obligation_Static_Predicate =>
                     return Propagation_Static_Predicate_Lost;
                  when Obligation_Dynamic_Predicate |
                       Obligation_Generic_Actual_Predicate |
                       Obligation_Call_Chain_Predicate =>
                     return Propagation_Dynamic_Predicate_Lost;
                  when Obligation_Type_Invariant |
                       Obligation_Dynamic_Invariant |
                       Obligation_Private_View_Invariant |
                       Obligation_Derived_Type_Invariant |
                       Obligation_State_Update_Invariant =>
                     return Propagation_Invariant_Lost;
                  when Obligation_Unknown =>
                     return Propagation_Indeterminate;
               end case;
         end case;
      elsif Info.Flow_Status /= FEG.Flow_Graph_Not_Checked and then Flow_Legal (Info.Flow_Status) then
         return Propagation_Legal_Flow_Effect_Propagated;
      elsif Info.Kind = Propagation_Context_Generic_Instance then
         return Propagation_Legal_Generic_Substitution_Propagated;
      elsif Info.Kind = Propagation_Context_Derived_Type then
         return Propagation_Legal_Derived_Invariant_Propagated;
      elsif Info.Kind = Propagation_Context_Private_View then
         return Propagation_Legal_Private_Full_View_Propagated;
      elsif Info.Obligation = Obligation_Static_Predicate then
         return Propagation_Legal_Static_Predicate_Preserved;
      elsif Info.Obligation in Obligation_Dynamic_Predicate | Obligation_Call_Chain_Predicate |
                              Obligation_Generic_Actual_Predicate
      then
         return Propagation_Legal_Dynamic_Predicate_Propagated;
      elsif Info.Obligation = Obligation_Dynamic_Invariant or else Info.Dynamic_Check then
         return Propagation_Legal_Dynamic_Invariant_Propagated;
      elsif Info.Obligation in Obligation_Type_Invariant | Obligation_Private_View_Invariant |
                              Obligation_Derived_Type_Invariant | Obligation_State_Update_Invariant
      then
         return Propagation_Legal_Invariant_Preserved;
      elsif PIU_Legal (Info.Predicate_Use_Status) then
         return Propagation_Legal_Dynamic_Predicate_Propagated;
      else
         return Propagation_Indeterminate;
      end if;
   end Classify;

   procedure Clear (Model : in out Propagation_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Propagation_Context_Model;
      Info  : Propagation_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   procedure Add_From_Predicate_Use_Row
     (Model : in out Propagation_Context_Model;
      Row   : PIU.Predicate_Use_Legality_Info) is
      Info : Propagation_Context_Info;
   begin
      Info.Id := Propagation_Row_Id (Row.Id);
      Info.Node := Row.Node;
      Info.Source_Node := Row.Expression_Node;
      Info.Target_Node := Row.Target_Node;
      Info.Subtype_Name := Row.Subtype_Name;
      Info.Predicate_Use_Status := Row.Status;
      Info.Requires_Check := True;
      Info.Check_Propagated := PIU_Legal (Row.Status);
      Info.Start_Line := Row.Start_Line;
      Info.Start_Column := Row.Start_Column;
      Info.End_Line := Row.End_Line;
      Info.End_Column := Row.End_Column;
      Info.Source_Fingerprint := Row.Fingerprint;

      case Row.Kind is
         when PIU.Predicate_Use_Assignment | PIU.Predicate_Use_Object_Initialization =>
            Info.Kind := Propagation_Context_Assignment;
         when PIU.Predicate_Use_Return =>
            Info.Kind := Propagation_Context_Return;
         when PIU.Predicate_Use_Conversion | PIU.Predicate_Use_Qualified_Expression =>
            Info.Kind := Propagation_Context_Conversion;
         when PIU.Predicate_Use_Call_Actual | PIU.Predicate_Use_Default_Expression =>
            Info.Kind := Propagation_Context_Call_Source;
         when PIU.Predicate_Use_Generic_Actual =>
            Info.Kind := Propagation_Context_Generic_Instance;
         when others =>
            Info.Kind := Propagation_Context_Flow_Effect;
      end case;

      if Row.Status in PIU.Predicate_Use_Legality_Legal_Invariant_Preserved |
                       PIU.Predicate_Use_Legality_Legal_Dynamic_Invariant_Check |
                       PIU.Predicate_Use_Legality_Invariant_Violation |
                       PIU.Predicate_Use_Legality_Invariant_Unresolved |
                       PIU.Predicate_Use_Legality_Invariant_Private_View_Barrier
      then
         Info.Obligation := Obligation_Type_Invariant;
      elsif Row.Status = PIU.Predicate_Use_Legality_Legal_Static_Predicate or else
            Row.Status = PIU.Predicate_Use_Legality_Legal_Static_Range_And_Predicate
      then
         Info.Obligation := Obligation_Static_Predicate;
      else
         Info.Obligation := Obligation_Dynamic_Predicate;
      end if;

      Add_Context (Model, Info);
   end Add_From_Predicate_Use_Row;

   procedure Add_From_Flow_Effect_Row
     (Model : in out Propagation_Context_Model;
      Row   : FEG.Flow_Effect_Info) is
      Info : Propagation_Context_Info;
   begin
      Info.Id := Propagation_Row_Id (Row.Id);
      Info.Kind := Propagation_Context_Flow_Effect;
      Info.Obligation := Obligation_State_Update_Invariant;
      Info.Node := Row.Node;
      Info.Source_Node := Row.Source_Node;
      Info.Target_Node := Row.Target_Node;
      Info.Object_Name := Row.Object_Name;
      Info.Caller_Name := Row.Caller_Name;
      Info.Callee_Name := Row.Callee_Name;
      Info.Flow_Status := Row.Status;
      Info.Requires_Check := True;
      Info.Check_Propagated := Flow_Legal (Row.Status);
      Info.State_Was_Updated := Row.Edge in FEG.Flow_Edge_Object_Write |
                                      FEG.Flow_Edge_Object_Read_Write |
                                      FEG.Flow_Edge_Protected_State;
      Info.State_Covered_By_Flow := Flow_Legal (Row.Status);
      Info.Start_Line := Row.Start_Line;
      Info.Start_Column := Row.Start_Column;
      Info.End_Line := Row.End_Line;
      Info.End_Column := Row.End_Column;
      Info.Source_Fingerprint := Row.Fingerprint;
      Add_Context (Model, Info);
   end Add_From_Flow_Effect_Row;

   function Context_Count (Model : Propagation_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Propagation_Context_Model;
      Index : Positive) return Propagation_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Propagation_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Propagation_Context_Model) return Propagation_Model is
      Result : Propagation_Model;
      Id     : Propagation_Row_Id := 0;
   begin
      for C of Contexts.Items loop
         declare
            Row : Propagation_Info;
         begin
            Id := Id + 1;
            Row.Id := Id;
            Row.Kind := C.Kind;
            Row.Obligation := C.Obligation;
            Row.Status := Classify (C);
            Row.Node := C.Node;
            Row.Source_Node := C.Source_Node;
            Row.Target_Node := C.Target_Node;
            Row.Subtype_Name := C.Subtype_Name;
            Row.Object_Name := C.Object_Name;
            Row.Caller_Name := C.Caller_Name;
            Row.Callee_Name := C.Callee_Name;
            Row.Generic_Formal_Name := C.Generic_Formal_Name;
            Row.Generic_Actual_Name := C.Generic_Actual_Name;
            Row.Predicate_Use_Status := C.Predicate_Use_Status;
            Row.Flow_Status := C.Flow_Status;
            Row.Gate_Status := C.Gate_Status;
            Row.Message := To_Unbounded_String (Message_For (Row.Status));
            Row.Detail := To_Unbounded_String
              ("predicate/invariant propagation keeps local use-site checks, flow effects, generics, views, and visible state updates coherent");
            Row.Start_Line := C.Start_Line;
            Row.Start_Column := C.Start_Column;
            Row.End_Line := C.End_Line;
            Row.End_Column := C.End_Column;
            Row.Source_Fingerprint := C.Source_Fingerprint;
            Row.Fingerprint := Row_Fingerprint (Row);
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Build_From_Predicate_Uses
     (Uses : PIU.Predicate_Use_Legality_Model) return Propagation_Model is
      Contexts : Propagation_Context_Model;
   begin
      for Index in 1 .. PIU.Row_Count (Uses) loop
         Add_From_Predicate_Use_Row (Contexts, PIU.Row_At (Uses, Index));
      end loop;
      return Build (Contexts);
   end Build_From_Predicate_Uses;

   function Row_Count (Model : Propagation_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Propagation_Model;
      Index : Positive) return Propagation_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Propagation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Propagation_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Propagation_Model;
      Status : Propagation_Status) return Propagation_Set is
      Set : Propagation_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Propagation_Model;
      Kind  : Propagation_Context_Kind) return Propagation_Set is
      Set : Propagation_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Subtype
     (Model        : Propagation_Model;
      Subtype_Name : String) return Propagation_Set is
      Set : Propagation_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Subtype_Name) = Subtype_Name then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Subtype;

   function Rows_For_Object
     (Model : Propagation_Model;
      Name  : String) return Propagation_Set is
      Set : Propagation_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Object_Name) = Name then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Object;

   function Set_Count (Set : Propagation_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Propagation_Set;
      Index : Positive) return Propagation_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Propagation_Model;
      Status : Propagation_Status) return Natural is
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
     (Model : Propagation_Model;
      Kind  : Propagation_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Propagation_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Propagation_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Is_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Predicate_Error_Count (Model : Propagation_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Predicate_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Predicate_Error_Count;

   function Invariant_Error_Count (Model : Propagation_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Invariant_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Invariant_Error_Count;

   function Generic_Error_Count (Model : Propagation_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Propagation_Generic_Actual_Check_Missing then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Generic_Error_Count;

   function Flow_Error_Count (Model : Propagation_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status in Propagation_Linked_Flow_Effect_Error |
                          Propagation_Flow_Effect_Uncovered_State_Update
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Flow_Error_Count;

   function Coverage_Gate_Error_Count (Model : Propagation_Model) return Natural is
   begin
      return Count_Status (Model, Propagation_Coverage_Gate_Blocker);
   end Coverage_Gate_Error_Count;

   function Indeterminate_Count (Model : Propagation_Model) return Natural is
   begin
      return Count_Status (Model, Propagation_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Propagation_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Predicate_Invariant_Propagation_Legality;
