with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Freezing_Exact_Propagation_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Name_Text (Name : Unbounded_String) return String is
   begin
      return To_String (Name);
   end Name_Text;

   function Is_Legal (Status : Freezing_Propagation_Status) return Boolean is
   begin
      return Status in
        Freezing_Propagation_Legal_No_Freezing ..
        Freezing_Propagation_Legal_Finalization_Effect;
   end Is_Legal;

   function Precision_Error
     (Status : Precision.Representation_Freezing_Precision_Status) return Boolean is
   begin
      return Status not in
        Precision.Representation_Freezing_Precision_Not_Checked |
        Precision.Representation_Freezing_Precision_Legal_Representation_Item |
        Precision.Representation_Freezing_Precision_Legal_Aspect |
        Precision.Representation_Freezing_Precision_Legal_Operational_Item |
        Precision.Representation_Freezing_Precision_Legal_Stream_Attribute |
        Precision.Representation_Freezing_Precision_Legal_Record_Layout |
        Precision.Representation_Freezing_Precision_Legal_Generic_Instance_Effect |
        Precision.Representation_Freezing_Precision_Legal_Private_Full_View |
        Precision.Representation_Freezing_Precision_Legal_Implicit_Freezing;
   end Precision_Error;

   function Replay_Error (Status : Replay.Replay_Status) return Boolean is
   begin
      return Status not in
        Replay.Replay_Not_Checked |
        Replay.Replay_Legal_Substituted_Declaration |
        Replay.Replay_Legal_Substituted_Statement |
        Replay.Replay_Legal_Substituted_Expression |
        Replay.Replay_Legal_Call |
        Replay.Replay_Legal_Flow_Effect |
        Replay.Replay_Legal_Predicate_Invariant |
        Replay.Replay_Legal_Accessibility |
        Replay.Replay_Legal_Representation_Freezing |
        Replay.Replay_Legal_Nested_Instance;
   end Replay_Error;

   function Discriminant_Error
     (Status : Discriminants.Discriminant_Legality_Status) return Boolean is
   begin
      return Status not in
        Discriminants.Discriminant_Legality_Not_Checked |
        Discriminants.Discriminant_Legality_Legal_Constrained_Record |
        Discriminants.Discriminant_Legality_Legal_Unconstrained_With_Defaults |
        Discriminants.Discriminant_Legality_Legal_Discriminant_Default |
        Discriminants.Discriminant_Legality_Legal_Variant_Presence |
        Discriminants.Discriminant_Legality_Legal_Aggregate_Discriminants |
        Discriminants.Discriminant_Legality_Legal_Assignment_Check |
        Discriminants.Discriminant_Legality_Legal_Conversion_Check |
        Discriminants.Discriminant_Legality_Legal_Return_Check |
        Discriminants.Discriminant_Legality_Legal_Allocator_Check |
        Discriminants.Discriminant_Legality_Legal_Generic_Actual_Check;
   end Discriminant_Error;

   function Flow_Error (Status : Flow.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status not in
        Flow.Flow_Graph_Not_Checked |
        Flow.Flow_Graph_Legal_Read_Edge |
        Flow.Flow_Graph_Legal_Write_Edge |
        Flow.Flow_Graph_Legal_Read_Write_Edge |
        Flow.Flow_Graph_Legal_Depends_Edge |
        Flow.Flow_Graph_Legal_Call_Propagation |
        Flow.Flow_Graph_Legal_Generic_Substitution |
        Flow.Flow_Graph_Legal_Protected_State_Effect |
        Flow.Flow_Graph_Legal_Task_Activation_Effect |
        Flow.Flow_Graph_Legal_Refined_Global |
        Flow.Flow_Graph_Legal_Refined_Depends |
        Flow.Flow_Graph_Legal_Null_Effect;
   end Flow_Error;

   function Predicate_Error (Status : Predicates.Propagation_Status) return Boolean is
   begin
      return Status not in
        Predicates.Propagation_Not_Checked |
        Predicates.Propagation_Legal_Static_Predicate_Preserved |
        Predicates.Propagation_Legal_Dynamic_Predicate_Propagated |
        Predicates.Propagation_Legal_Invariant_Preserved |
        Predicates.Propagation_Legal_Dynamic_Invariant_Propagated |
        Predicates.Propagation_Legal_Generic_Substitution_Propagated |
        Predicates.Propagation_Legal_Derived_Invariant_Propagated |
        Predicates.Propagation_Legal_Private_Full_View_Propagated |
        Predicates.Propagation_Legal_Flow_Effect_Propagated;
   end Predicate_Error;

   function Scope_Error (Status : Scope.Scope_Legality_Status) return Boolean is
   begin
      return Status not in
        Scope.Scope_Legality_Not_Checked |
        Scope.Scope_Legality_Legal_Master_Hierarchy |
        Scope.Scope_Legality_Legal_Static_Level |
        Scope.Scope_Legality_Legal_Dynamic_Check |
        Scope.Scope_Legality_Legal_Allocator_Master |
        Scope.Scope_Legality_Legal_Return_Object_Master |
        Scope.Scope_Legality_Legal_Return_Access_Master |
        Scope.Scope_Legality_Legal_Access_Discriminant_Master |
        Scope.Scope_Legality_Legal_Access_Conversion |
        Scope.Scope_Legality_Legal_Generic_Substitution |
        Scope.Scope_Legality_Legal_Discriminant_Aggregate;
   end Scope_Error;

   function Elab_Error (Status : Elab.Elaboration_Graph_Closure_Status) return Boolean is
   begin
      return Status not in
        Elab.Graph_Closure_Not_Checked |
        Elab.Graph_Closure_Legal_Library_Edge |
        Elab.Graph_Closure_Legal_Transitive_Elaborate_All |
        Elab.Graph_Closure_Legal_Body_Before_Use |
        Elab.Graph_Closure_Legal_Direct_Call_Order |
        Elab.Graph_Closure_Legal_Indirect_Call_Order |
        Elab.Graph_Closure_Legal_Dispatching_Call_Order |
        Elab.Graph_Closure_Legal_Access_Order |
        Elab.Graph_Closure_Legal_Generic_Instance_Order |
        Elab.Graph_Closure_Legal_Default_Expression_Order |
        Elab.Graph_Closure_Legal_Aspect_Expression_Order |
        Elab.Graph_Closure_Legal_Representation_Item_Order |
        Elab.Graph_Closure_Legal_Preelaboration_Policy |
        Elab.Graph_Closure_Legal_Pure_Policy;
   end Elab_Error;

   function Tasking_Error (Status : Tasking.Tasking_Effect_Status) return Boolean is
   begin
      return Status not in
        Tasking.Tasking_Effect_Not_Checked |
        Tasking.Tasking_Effect_Legal_Task_Activation |
        Tasking.Tasking_Effect_Legal_Task_Termination |
        Tasking.Tasking_Effect_Legal_Protected_Read |
        Tasking.Tasking_Effect_Legal_Protected_Write |
        Tasking.Tasking_Effect_Legal_Protected_Function_Call |
        Tasking.Tasking_Effect_Legal_Protected_Procedure_Call |
        Tasking.Tasking_Effect_Legal_Protected_Entry_Call |
        Tasking.Tasking_Effect_Legal_Entry_Queue |
        Tasking.Tasking_Effect_Legal_Entry_Barrier |
        Tasking.Tasking_Effect_Legal_Accept_Body |
        Tasking.Tasking_Effect_Legal_Requeue |
        Tasking.Tasking_Effect_Legal_Select_Guard |
        Tasking.Tasking_Effect_Legal_Select_Alternative |
        Tasking.Tasking_Effect_Legal_Delay_Alternative |
        Tasking.Tasking_Effect_Legal_Terminate_Alternative;
   end Tasking_Error;

   function Gate_Error (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status not in
        Gates.Enforcement_Not_Checked |
        Gates.Enforcement_Confident_Result_Allowed |
        Gates.Enforcement_Original_Error_Preserved;
   end Gate_Error;

   function Classify (Info : Freezing_Propagation_Context_Info)
      return Freezing_Propagation_Status is
      Blockers : Natural := 0;
      Result   : Freezing_Propagation_Status := Freezing_Propagation_Not_Checked;

      procedure Add_Blocker (Status : Freezing_Propagation_Status) is
      begin
         Blockers := Blockers + 1;
         if Result = Freezing_Propagation_Not_Checked then
            Result := Status;
         end if;
      end Add_Blocker;
   begin
      if not Info.Target_Resolved then
         Add_Blocker (Freezing_Propagation_Target_Unresolved);
      elsif Info.Target_Ambiguous then
         Add_Blocker (Freezing_Propagation_Target_Ambiguous);
      elsif not Info.Target_Freezable then
         Add_Blocker (Freezing_Propagation_Target_Not_Freezable);
      end if;

      if Info.Representation_After_Implicit_Use then
         Add_Blocker (Freezing_Propagation_Representation_After_Implicit_Use);
      end if;
      if Info.Representation_After_Generic_Instance then
         Add_Blocker (Freezing_Propagation_Representation_After_Generic_Instance);
      end if;
      if Info.Representation_After_Generic_Body_Replay then
         Add_Blocker (Freezing_Propagation_Representation_After_Generic_Body_Replay);
      end if;
      if Info.Representation_After_Private_View then
         Add_Blocker (Freezing_Propagation_Representation_After_Private_View);
      end if;
      if Info.Representation_After_Full_View_Completion then
         Add_Blocker (Freezing_Propagation_Representation_After_Full_View_Completion);
      end if;
      if Info.Representation_At_Freezing_Point then
         Add_Blocker (Freezing_Propagation_Representation_At_Freezing_Point);
      end if;
      if Info.Discriminant_Representation and then Discriminant_Error (Info.Discriminant_Status) then
         Add_Blocker (Freezing_Propagation_Discriminant_Representation_Error);
      end if;
      if Info.Variant_Representation and then Discriminant_Error (Info.Discriminant_Status) then
         Add_Blocker (Freezing_Propagation_Variant_Representation_Error);
      end if;
      if Info.Operational_Finalization_Effect and then Tasking_Error (Info.Tasking_Status) then
         Add_Blocker (Freezing_Propagation_Operational_Finalization_Error);
      end if;
      if Info.Stream_Effect and then Precision_Error (Info.Precision_Status) then
         Add_Blocker (Freezing_Propagation_Stream_Effect_Error);
      end if;
      if Info.Private_Full_View_Mismatch then
         Add_Blocker (Freezing_Propagation_Private_Full_View_Mismatch);
      end if;
      if Info.Implicit_Freezing_Order_Error then
         Add_Blocker (Freezing_Propagation_Implicit_Freezing_Order_Error);
      end if;
      if Precision_Error (Info.Precision_Status)
        and then not Info.Stream_Effect
      then
         Add_Blocker (Freezing_Propagation_Linked_Precision_Error);
      end if;
      if Replay_Error (Info.Replay_Status) then
         Add_Blocker (Freezing_Propagation_Linked_Generic_Replay_Error);
      end if;
      if Discriminant_Error (Info.Discriminant_Status)
        and then not (Info.Discriminant_Representation or else Info.Variant_Representation)
      then
         Add_Blocker (Freezing_Propagation_Linked_Discriminant_Error);
      end if;
      if Flow_Error (Info.Flow_Status) then
         Add_Blocker (Freezing_Propagation_Linked_Flow_Effect_Error);
      end if;
      if Predicate_Error (Info.Predicate_Status) then
         Add_Blocker (Freezing_Propagation_Linked_Predicate_Invariant_Error);
      end if;
      if Scope_Error (Info.Scope_Status) then
         Add_Blocker (Freezing_Propagation_Linked_Accessibility_Scope_Error);
      end if;
      if Elab_Error (Info.Elaboration_Status) then
         Add_Blocker (Freezing_Propagation_Linked_Elaboration_Graph_Error);
      end if;
      if Tasking_Error (Info.Tasking_Status)
        and then not Info.Operational_Finalization_Effect
      then
         Add_Blocker (Freezing_Propagation_Linked_Tasking_Effect_Error);
      end if;
      if Gate_Error (Info.Gate_Status) then
         Add_Blocker (Freezing_Propagation_Coverage_Gate_Blocker);
      end if;

      if Blockers > 1 then
         return Freezing_Propagation_Multiple_Blockers;
      elsif Blockers = 1 then
         return Result;
      elsif Info.Kind = Freezing_Propagation_Context_Unknown then
         return Freezing_Propagation_Indeterminate;
      elsif Info.Implicit_Use_Freezes then
         return Freezing_Propagation_Legal_Implicit_Freezing;
      elsif Info.Representation_Item then
         return Freezing_Propagation_Legal_Explicit_Representation_Before_Freezing;
      elsif Info.Kind = Freezing_Propagation_Context_Generic_Instance then
         return Freezing_Propagation_Legal_Generic_Instance_Freezing;
      elsif Info.Kind = Freezing_Propagation_Context_Generic_Body_Replay then
         return Freezing_Propagation_Legal_Generic_Instance_Freezing;
      elsif Info.Kind = Freezing_Propagation_Context_Private_Full_View then
         return Freezing_Propagation_Legal_Private_Full_View_Freezing;
      elsif Info.Discriminant_Representation or else Info.Variant_Representation then
         return Freezing_Propagation_Legal_Discriminant_Representation;
      elsif Info.Kind = Freezing_Propagation_Context_Operational_Attribute then
         return Freezing_Propagation_Legal_Operational_Effect;
      elsif Info.Kind = Freezing_Propagation_Context_Stream_Attribute then
         return Freezing_Propagation_Legal_Stream_Effect;
      elsif Info.Kind = Freezing_Propagation_Context_Finalization_Effect then
         return Freezing_Propagation_Legal_Finalization_Effect;
      else
         return Freezing_Propagation_Legal_No_Freezing;
      end if;
   end Classify;

   function Message_For (Status : Freezing_Propagation_Status) return String is
   begin
      case Status is
         when Freezing_Propagation_Legal_No_Freezing =>
            return "semantic use does not freeze representation target";
         when Freezing_Propagation_Legal_Implicit_Freezing =>
            return "implicit semantic use freezes representation target";
         when Freezing_Propagation_Legal_Explicit_Representation_Before_Freezing =>
            return "representation item appears before freezing";
         when Freezing_Propagation_Legal_Generic_Instance_Freezing =>
            return "generic instance freezing is propagated";
         when Freezing_Propagation_Legal_Private_Full_View_Freezing =>
            return "private/full-view freezing timing is preserved";
         when Freezing_Propagation_Legal_Discriminant_Representation =>
            return "discriminant/variant representation is compatible";
         when Freezing_Propagation_Legal_Operational_Effect =>
            return "operational effect is compatible with freezing";
         when Freezing_Propagation_Legal_Stream_Effect =>
            return "stream effect is compatible with freezing";
         when Freezing_Propagation_Legal_Finalization_Effect =>
            return "finalization effect is compatible with freezing";
         when Freezing_Propagation_Target_Unresolved =>
            return "representation/freezing target is unresolved";
         when Freezing_Propagation_Target_Ambiguous =>
            return "representation/freezing target is ambiguous";
         when Freezing_Propagation_Target_Not_Freezable =>
            return "representation/freezing target is not freezable";
         when Freezing_Propagation_Representation_After_Implicit_Use =>
            return "representation item appears after implicit semantic-use freezing";
         when Freezing_Propagation_Representation_After_Generic_Instance =>
            return "representation item appears after generic-instance freezing";
         when Freezing_Propagation_Representation_After_Generic_Body_Replay =>
            return "representation item appears after instantiated-body replay freezing";
         when Freezing_Propagation_Representation_After_Private_View =>
            return "representation item appears after private-view freezing";
         when Freezing_Propagation_Representation_After_Full_View_Completion =>
            return "representation item appears after full-view completion freezing";
         when Freezing_Propagation_Representation_At_Freezing_Point =>
            return "representation item appears at the freezing point";
         when Freezing_Propagation_Discriminant_Representation_Error =>
            return "discriminant representation is incompatible with freezing";
         when Freezing_Propagation_Variant_Representation_Error =>
            return "variant representation is incompatible with freezing";
         when Freezing_Propagation_Operational_Finalization_Error =>
            return "operational/finalization effect is incompatible with freezing";
         when Freezing_Propagation_Stream_Effect_Error =>
            return "streaming effect is incompatible with freezing";
         when Freezing_Propagation_Private_Full_View_Mismatch =>
            return "private and full views have inconsistent freezing state";
         when Freezing_Propagation_Implicit_Freezing_Order_Error =>
            return "implicit freezing order is inconsistent";
         when Freezing_Propagation_Linked_Precision_Error =>
            return "linked representation/freezing precision error";
         when Freezing_Propagation_Linked_Generic_Replay_Error =>
            return "linked generic replay error affects freezing";
         when Freezing_Propagation_Linked_Discriminant_Error =>
            return "linked discriminant legality error affects freezing";
         when Freezing_Propagation_Linked_Flow_Effect_Error =>
            return "linked flow-effect error affects freezing";
         when Freezing_Propagation_Linked_Predicate_Invariant_Error =>
            return "linked predicate/invariant error affects freezing";
         when Freezing_Propagation_Linked_Accessibility_Scope_Error =>
            return "linked accessibility scope error affects freezing";
         when Freezing_Propagation_Linked_Elaboration_Graph_Error =>
            return "linked elaboration graph error affects freezing";
         when Freezing_Propagation_Linked_Tasking_Effect_Error =>
            return "linked tasking/protected effect error affects freezing";
         when Freezing_Propagation_Coverage_Gate_Blocker =>
            return "coverage gate blocks confident freezing conclusion";
         when Freezing_Propagation_Multiple_Blockers =>
            return "multiple semantic blockers affect freezing propagation";
         when Freezing_Propagation_Indeterminate =>
            return "freezing propagation is indeterminate";
         when Freezing_Propagation_Not_Checked =>
            return "freezing propagation not checked";
      end case;
   end Message_For;

   function Make_Row (Info : Freezing_Propagation_Context_Info)
      return Freezing_Propagation_Info is
      Status : constant Freezing_Propagation_Status := Classify (Info);
      Row    : Freezing_Propagation_Info;
      FP     : Natural := Info.Source_Fingerprint;
   begin
      FP := Mix (FP, Freezing_Propagation_Context_Kind'Pos (Info.Kind));
      FP := Mix (FP, Freezing_Propagation_Status'Pos (Status));
      FP := Mix (FP, Natural (Info.Node));
      FP := Mix (FP, Natural (Info.Target_Node));
      FP := Mix (FP, Natural (Info.Freezing_Node));
      FP := Mix (FP, Info.Freezing_Line);
      FP := Mix (FP, Info.Representation_Line);

      Row.Id := Info.Id;
      Row.Kind := Info.Kind;
      Row.Node := Info.Node;
      Row.Target_Node := Info.Target_Node;
      Row.Freezing_Node := Info.Freezing_Node;
      Row.Representation_Node := Info.Representation_Node;
      Row.Status := Status;
      Row.Target_Name := Info.Target_Name;
      Row.Unit_Name := Info.Unit_Name;
      Row.Component_Name := Info.Component_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("target=" & Name_Text (Info.Target_Name) &
         "; unit=" & Name_Text (Info.Unit_Name) &
         "; component=" & Name_Text (Info.Component_Name));
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Fingerprint := FP;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      return Row;
   end Make_Row;

   function Has_Error (Info : Freezing_Propagation_Info) return Boolean is
   begin
      return not Is_Legal (Info.Status)
        and then Info.Status /= Freezing_Propagation_Not_Checked;
   end Has_Error;

   function Freezing_Order_Error (Status : Freezing_Propagation_Status) return Boolean is
   begin
      return Status in
        Freezing_Propagation_Representation_After_Implicit_Use |
        Freezing_Propagation_Representation_After_Generic_Instance |
        Freezing_Propagation_Representation_After_Generic_Body_Replay |
        Freezing_Propagation_Representation_After_Private_View |
        Freezing_Propagation_Representation_After_Full_View_Completion |
        Freezing_Propagation_Representation_At_Freezing_Point |
        Freezing_Propagation_Implicit_Freezing_Order_Error;
   end Freezing_Order_Error;

   function Representation_Error (Status : Freezing_Propagation_Status) return Boolean is
   begin
      return Status in
        Freezing_Propagation_Target_Unresolved |
        Freezing_Propagation_Target_Ambiguous |
        Freezing_Propagation_Target_Not_Freezable |
        Freezing_Propagation_Private_Full_View_Mismatch |
        Freezing_Propagation_Linked_Precision_Error;
   end Representation_Error;

   function Discriminant_Rep_Error (Status : Freezing_Propagation_Status) return Boolean is
   begin
      return Status in
        Freezing_Propagation_Discriminant_Representation_Error |
        Freezing_Propagation_Variant_Representation_Error |
        Freezing_Propagation_Linked_Discriminant_Error;
   end Discriminant_Rep_Error;

   function Operational_Stream_Error (Status : Freezing_Propagation_Status) return Boolean is
   begin
      return Status in
        Freezing_Propagation_Operational_Finalization_Error |
        Freezing_Propagation_Stream_Effect_Error;
   end Operational_Stream_Error;

   function Linked_Error (Status : Freezing_Propagation_Status) return Boolean is
   begin
      return Status in
        Freezing_Propagation_Linked_Generic_Replay_Error |
        Freezing_Propagation_Linked_Flow_Effect_Error |
        Freezing_Propagation_Linked_Predicate_Invariant_Error |
        Freezing_Propagation_Linked_Accessibility_Scope_Error |
        Freezing_Propagation_Linked_Elaboration_Graph_Error |
        Freezing_Propagation_Linked_Tasking_Effect_Error |
        Freezing_Propagation_Multiple_Blockers;
   end Linked_Error;

   procedure Add_Context
     (Model : in out Freezing_Propagation_Context_Model;
      Info  : Freezing_Propagation_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Context;

   function Build
     (Contexts : Freezing_Propagation_Context_Model) return Freezing_Propagation_Model is
      Model : Freezing_Propagation_Model;
   begin
      for C of Contexts.Contexts loop
         declare
            Row : constant Freezing_Propagation_Info := Make_Row (C);
         begin
            Model.Items.Append (Row);
            if Is_Legal (Row.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            elsif Row.Status = Freezing_Propagation_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;
            if Freezing_Order_Error (Row.Status) then
               Model.Freezing_Order_Error_Total := Model.Freezing_Order_Error_Total + 1;
            end if;
            if Representation_Error (Row.Status) then
               Model.Representation_Error_Total := Model.Representation_Error_Total + 1;
            end if;
            if Discriminant_Rep_Error (Row.Status) then
               Model.Discriminant_Error_Total := Model.Discriminant_Error_Total + 1;
            end if;
            if Operational_Stream_Error (Row.Status) then
               Model.Operational_Stream_Error_Total := Model.Operational_Stream_Error_Total + 1;
            end if;
            if Linked_Error (Row.Status) then
               Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
            end if;
            if Row.Status = Freezing_Propagation_Coverage_Gate_Blocker then
               Model.Coverage_Gate_Error_Total := Model.Coverage_Gate_Error_Total + 1;
            end if;
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Context_Count (Model : Freezing_Propagation_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Row_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Freezing_Propagation_Model;
      Index : Positive) return Freezing_Propagation_Info is
   begin
      if Index <= Natural (Model.Items.Length) then
         return Model.Items (Index);
      else
         return (others => <>);
      end if;
   end Row_At;

   function First_For_Node
     (Model : Freezing_Propagation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Freezing_Propagation_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Target
     (Model : Freezing_Propagation_Model;
      Name  : String) return Freezing_Propagation_Set is
      Set : Freezing_Propagation_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Target_Name) = Name then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Target;

   function Rows_For_Kind
     (Model : Freezing_Propagation_Model;
      Kind  : Freezing_Propagation_Context_Kind) return Freezing_Propagation_Set is
      Set : Freezing_Propagation_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Set.Items.Append (Row);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Result_Count (Set : Freezing_Propagation_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Result_Count;

   function Result_At
     (Set   : Freezing_Propagation_Set;
      Index : Positive) return Freezing_Propagation_Info is
   begin
      if Index <= Natural (Set.Items.Length) then
         return Set.Items (Index);
      else
         return (others => <>);
      end if;
   end Result_At;

   function Count_Status
     (Model  : Freezing_Propagation_Model;
      Status : Freezing_Propagation_Status) return Natural is
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
     (Model : Freezing_Propagation_Model;
      Kind  : Freezing_Propagation_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Freezing_Order_Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Freezing_Order_Error_Total;
   end Freezing_Order_Error_Count;

   function Representation_Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Representation_Error_Total;
   end Representation_Error_Count;

   function Discriminant_Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Discriminant_Error_Total;
   end Discriminant_Error_Count;

   function Operational_Stream_Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Operational_Stream_Error_Total;
   end Operational_Stream_Error_Count;

   function Linked_Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Coverage_Gate_Error_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Coverage_Gate_Error_Total;
   end Coverage_Gate_Error_Count;

   function Indeterminate_Count (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Freezing_Propagation_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
