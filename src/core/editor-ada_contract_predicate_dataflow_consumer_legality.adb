with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality is

   use type Contract.Contract_Context_Kind;
   use type Contract.Contract_Legality_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Pred_Flow.Predicate_Dataflow_Row_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 16_777_619 + B + 211) mod 2_147_483_647;
   end Mix;

   function Text (Value : Unbounded_String) return String is
   begin
      return To_String (Value);
   end Text;

   function Is_Contract_Legal
     (Status : Contract.Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contract.Contract_Legality_Legal_Precondition |
        Contract.Contract_Legality_Legal_Postcondition |
        Contract.Contract_Legality_Legal_Invariant |
        Contract.Contract_Legality_Legal_Predicate |
        Contract.Contract_Legality_Legal_Assertion |
        Contract.Contract_Legality_Legal_Contract_Case |
        Contract.Contract_Legality_Legal_Flow_Aspect;
   end Is_Contract_Legal;

   function Is_Predicate_Dataflow_Legal
     (Status : Pred_Flow.Predicate_Dataflow_Status) return Boolean is
   begin
      return Status in
        Pred_Flow.Predicate_Dataflow_Legal_Static_Predicate_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Dynamic_Predicate_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Invariant_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Dynamic_Invariant_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Generic_Substitution_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Derived_Invariant_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Private_Full_View_Accepted |
        Pred_Flow.Predicate_Dataflow_Legal_Flow_Effect_Accepted;
   end Is_Predicate_Dataflow_Legal;

   function Needs_Predicate_Dataflow
     (Info : Contract_Predicate_Context_Info) return Boolean is
   begin
      return Info.Requires_Predicate_Evidence or else
        Info.Requires_Invariant_Evidence or else
        Info.Requires_Flow_Evidence or else
        Info.Requires_Initialization_Evidence or else
        Info.Kind in
          Contract.Contract_Context_Precondition |
          Contract.Contract_Context_Postcondition |
          Contract.Contract_Context_Type_Invariant |
          Contract.Contract_Context_Default_Initial_Condition |
          Contract.Contract_Context_Static_Predicate |
          Contract.Contract_Context_Dynamic_Predicate |
          Contract.Contract_Context_Assertion |
          Contract.Contract_Context_Contract_Case |
          Contract.Contract_Context_Global_Aspect |
          Contract.Contract_Context_Depends_Aspect |
          Contract.Contract_Context_Refined_Global |
          Contract.Contract_Context_Refined_Depends;
   end Needs_Predicate_Dataflow;

   function Legal_Status_For
     (Info : Contract_Predicate_Context_Info) return Contract_Predicate_Status is
   begin
      case Info.Kind is
         when Contract.Contract_Context_Precondition =>
            return Contract_Predicate_Legal_Precondition_Accepted;
         when Contract.Contract_Context_Postcondition =>
            return Contract_Predicate_Legal_Postcondition_Accepted;
         when Contract.Contract_Context_Type_Invariant |
              Contract.Contract_Context_Default_Initial_Condition |
              Contract.Contract_Context_Initial_Condition =>
            return Contract_Predicate_Legal_Invariant_Accepted;
         when Contract.Contract_Context_Static_Predicate =>
            return Contract_Predicate_Legal_Static_Predicate_Accepted;
         when Contract.Contract_Context_Dynamic_Predicate =>
            return Contract_Predicate_Legal_Dynamic_Predicate_Accepted;
         when Contract.Contract_Context_Assertion =>
            return Contract_Predicate_Legal_Assertion_Accepted;
         when Contract.Contract_Context_Contract_Case =>
            return Contract_Predicate_Legal_Contract_Case_Accepted;
         when Contract.Contract_Context_Global_Aspect =>
            return Contract_Predicate_Legal_Global_Aspect_Accepted;
         when Contract.Contract_Context_Depends_Aspect =>
            return Contract_Predicate_Legal_Depends_Aspect_Accepted;
         when Contract.Contract_Context_Refined_Global =>
            return Contract_Predicate_Legal_Refined_Global_Accepted;
         when Contract.Contract_Context_Refined_Depends =>
            return Contract_Predicate_Legal_Refined_Depends_Accepted;
         when others =>
            if Info.Contract_Status = Contract.Contract_Legality_Legal_Flow_Aspect then
               return Contract_Predicate_Legal_Global_Aspect_Accepted;
            elsif Info.Contract_Status = Contract.Contract_Legality_Legal_Invariant then
               return Contract_Predicate_Legal_Invariant_Accepted;
            elsif Info.Contract_Status = Contract.Contract_Legality_Legal_Predicate then
               return Contract_Predicate_Legal_Dynamic_Predicate_Accepted;
            else
               return Contract_Predicate_Indeterminate;
            end if;
      end case;
   end Legal_Status_For;

   function Status_From_Predicate_Dataflow
     (Status : Pred_Flow.Predicate_Dataflow_Status) return Contract_Predicate_Status is
   begin
      case Status is
         when Pred_Flow.Predicate_Dataflow_Base_Predicate_Propagation_Error =>
            return Contract_Predicate_Base_Predicate_Propagation_Error;
         when Pred_Flow.Predicate_Dataflow_Missing_Dataflow_Init_Row |
              Pred_Flow.Predicate_Dataflow_Mismatched_Object =>
            return Contract_Predicate_Missing_Predicate_Dataflow_Row;
         when Pred_Flow.Predicate_Dataflow_Read_Before_Write_Blocker =>
            return Contract_Predicate_Read_Before_Write_Blocker;
         when Pred_Flow.Predicate_Dataflow_Component_Read_Before_Write_Blocker =>
            return Contract_Predicate_Component_Read_Before_Write_Blocker;
         when Pred_Flow.Predicate_Dataflow_Partial_Component_Init_Blocker =>
            return Contract_Predicate_Partial_Component_Init_Blocker;
         when Pred_Flow.Predicate_Dataflow_Out_Parameter_Not_Assigned_Blocker =>
            return Contract_Predicate_Out_Parameter_Not_Assigned_Blocker;
         when Pred_Flow.Predicate_Dataflow_In_Out_Conditional_Assignment_Blocker =>
            return Contract_Predicate_In_Out_Conditional_Assignment_Blocker;
         when Pred_Flow.Predicate_Dataflow_Return_Object_Not_Initialized_Blocker =>
            return Contract_Predicate_Return_Object_Not_Initialized_Blocker;
         when Pred_Flow.Predicate_Dataflow_Branch_Loop_Merge_Blocker =>
            return Contract_Predicate_Branch_Loop_Merge_Blocker;
         when Pred_Flow.Predicate_Dataflow_Exception_Path_Loss_Blocker =>
            return Contract_Predicate_Exception_Path_Loss_Blocker;
         when Pred_Flow.Predicate_Dataflow_Finalization_Uses_Uninitialized_Blocker =>
            return Contract_Predicate_Finalization_Uses_Uninitialized_Blocker;
         when Pred_Flow.Predicate_Dataflow_Use_After_Finalization_Blocker =>
            return Contract_Predicate_Use_After_Finalization_Blocker;
         when Pred_Flow.Predicate_Dataflow_Lifetime_Blocker =>
            return Contract_Predicate_Lifetime_Blocker;
         when Pred_Flow.Predicate_Dataflow_Discriminant_Representation_Blocker =>
            return Contract_Predicate_Discriminant_Representation_Blocker;
         when Pred_Flow.Predicate_Dataflow_Coverage_Blocker =>
            return Contract_Predicate_Coverage_Blocker;
         when Pred_Flow.Predicate_Dataflow_Global_Blocker =>
            return Contract_Predicate_Global_Blocker;
         when Pred_Flow.Predicate_Dataflow_Depends_Blocker =>
            return Contract_Predicate_Depends_Blocker;
         when Pred_Flow.Predicate_Dataflow_Call_Propagation_Blocker =>
            return Contract_Predicate_Call_Propagation_Blocker;
         when Pred_Flow.Predicate_Dataflow_Generic_Effect_Blocker =>
            return Contract_Predicate_Generic_Effect_Blocker;
         when Pred_Flow.Predicate_Dataflow_Tasking_Protected_Blocker =>
            return Contract_Predicate_Tasking_Protected_Blocker;
         when Pred_Flow.Predicate_Dataflow_Linked_Dataflow_Blocker =>
            return Contract_Predicate_Linked_Dataflow_Blocker;
         when Pred_Flow.Predicate_Dataflow_Multiple_Blockers =>
            return Contract_Predicate_Multiple_Blockers;
         when Pred_Flow.Predicate_Dataflow_Indeterminate |
              Pred_Flow.Predicate_Dataflow_Not_Checked =>
            return Contract_Predicate_Indeterminate;
         when others =>
            if Is_Predicate_Dataflow_Legal (Status) then
               return Contract_Predicate_Not_Checked;
            else
               return Contract_Predicate_Linked_Dataflow_Blocker;
            end if;
      end case;
   end Status_From_Predicate_Dataflow;

   function Status_For
     (Info : Contract_Predicate_Context_Info) return Contract_Predicate_Status is
      Pred_Status : Contract_Predicate_Status;
   begin
      if not Is_Contract_Legal (Info.Contract_Status) then
         if Info.Contract_Status = Contract.Contract_Legality_Not_Checked or else
           Info.Contract_Status = Contract.Contract_Legality_Indeterminate
         then
            return Contract_Predicate_Indeterminate;
         else
            return Contract_Predicate_Base_Contract_Error;
         end if;
      end if;

      if Needs_Predicate_Dataflow (Info) then
         if Info.Predicate_Dataflow_Row = Pred_Flow.No_Predicate_Dataflow_Row or else
           Info.Predicate_Dataflow_Matches = 0
         then
            return Contract_Predicate_Missing_Predicate_Dataflow_Row;
         end if;

         Pred_Status := Status_From_Predicate_Dataflow (Info.Predicate_Dataflow_Status);
         if Pred_Status /= Contract_Predicate_Not_Checked then
            return Pred_Status;
         end if;
      end if;

      return Legal_Status_For (Info);
   end Status_For;

   function Message_For (Status : Contract_Predicate_Status) return String is
   begin
      case Status is
         when Contract_Predicate_Legal_Precondition_Accepted => return "Precondition accepted with predicate/dataflow evidence";
         when Contract_Predicate_Legal_Postcondition_Accepted => return "Postcondition accepted with initialized predicate/dataflow evidence";
         when Contract_Predicate_Legal_Invariant_Accepted => return "Invariant contract accepted with propagated invariant evidence";
         when Contract_Predicate_Legal_Static_Predicate_Accepted => return "Static predicate aspect accepted with dataflow evidence";
         when Contract_Predicate_Legal_Dynamic_Predicate_Accepted => return "Dynamic predicate aspect accepted with dataflow evidence";
         when Contract_Predicate_Legal_Assertion_Accepted => return "Assertion contract accepted with predicate/dataflow evidence";
         when Contract_Predicate_Legal_Contract_Case_Accepted => return "Contract case accepted with predicate/dataflow evidence";
         when Contract_Predicate_Legal_Global_Aspect_Accepted => return "Global aspect accepted with initialized flow evidence";
         when Contract_Predicate_Legal_Depends_Aspect_Accepted => return "Depends aspect accepted with initialized flow evidence";
         when Contract_Predicate_Legal_Refined_Global_Accepted => return "Refined_Global accepted with initialized predicate/dataflow evidence";
         when Contract_Predicate_Legal_Refined_Depends_Accepted => return "Refined_Depends accepted with initialized predicate/dataflow evidence";
         when Contract_Predicate_Base_Contract_Error => return "Base contract/aspect error preserved";
         when Contract_Predicate_Missing_Predicate_Dataflow_Row => return "Missing predicate/dataflow initialization evidence for contract";
         when Contract_Predicate_Mismatched_Contract_Kind => return "Predicate/dataflow evidence is for a different contract kind";
         when Contract_Predicate_Base_Predicate_Propagation_Error => return "Predicate/invariant propagation error blocks contract";
         when Contract_Predicate_Read_Before_Write_Blocker => return "Read-before-write blocks contract";
         when Contract_Predicate_Component_Read_Before_Write_Blocker => return "Component read-before-write blocks contract";
         when Contract_Predicate_Partial_Component_Init_Blocker => return "Partial component initialization blocks contract";
         when Contract_Predicate_Out_Parameter_Not_Assigned_Blocker => return "Out parameter assignment obligation blocks contract";
         when Contract_Predicate_In_Out_Conditional_Assignment_Blocker => return "Conditional in out assignment blocks contract";
         when Contract_Predicate_Return_Object_Not_Initialized_Blocker => return "Return-object initialization blocks contract";
         when Contract_Predicate_Branch_Loop_Merge_Blocker => return "Branch/loop initialization merge blocks contract";
         when Contract_Predicate_Exception_Path_Loss_Blocker => return "Exception-path initialization loss blocks contract";
         when Contract_Predicate_Finalization_Uses_Uninitialized_Blocker => return "Finalization using uninitialized state blocks contract";
         when Contract_Predicate_Use_After_Finalization_Blocker => return "Use-after-finalization blocks contract";
         when Contract_Predicate_Lifetime_Blocker => return "Exact lifetime/accessibility evidence blocks contract";
         when Contract_Predicate_Discriminant_Representation_Blocker => return "Discriminant or representation evidence blocks contract";
         when Contract_Predicate_Coverage_Blocker => return "Coverage repair gate blocks contract";
         when Contract_Predicate_Global_Blocker => return "Global flow blocker prevents contract acceptance";
         when Contract_Predicate_Depends_Blocker => return "Depends flow blocker prevents contract acceptance";
         when Contract_Predicate_Call_Propagation_Blocker => return "Call-propagation blocker prevents contract acceptance";
         when Contract_Predicate_Generic_Effect_Blocker => return "Generic flow effect blocker prevents contract acceptance";
         when Contract_Predicate_Tasking_Protected_Blocker => return "Tasking/protected flow blocker prevents contract acceptance";
         when Contract_Predicate_Linked_Dataflow_Blocker => return "Linked dataflow blocker prevents contract acceptance";
         when Contract_Predicate_Multiple_Blockers => return "Multiple predicate/dataflow blockers prevent contract acceptance";
         when Contract_Predicate_Indeterminate => return "Contract predicate/dataflow consumer state is indeterminate";
         when Contract_Predicate_Not_Checked => return "Contract predicate/dataflow consumer not checked";
      end case;
   end Message_For;

   function Fingerprint_For (Info : Contract_Predicate_Info) return Natural is
      F : Natural := Natural (Info.Id);
   begin
      F := Mix (F, Contract_Predicate_Status'Pos (Info.Status) + 1);
      F := Mix (F, Contract.Contract_Context_Kind'Pos (Info.Kind) + 1);
      F := Mix (F, Contract.Contract_Subject_Kind'Pos (Info.Subject) + 1);
      F := Mix (F, Natural (Info.Node));
      F := Mix (F, Natural (Info.Contract_Row));
      F := Mix (F, Contract.Contract_Legality_Status'Pos (Info.Contract_Status) + 1);
      F := Mix (F, Natural (Info.Predicate_Dataflow_Row));
      F := Mix (F, Pred_Flow.Predicate_Dataflow_Status'Pos (Info.Predicate_Dataflow_Status) + 1);
      F := Mix (F, Info.Source_Fingerprint);
      F := Mix (F, Info.Contract_Fingerprint);
      F := Mix (F, Info.Predicate_Dataflow_Fingerprint);
      return F;
   end Fingerprint_For;

   function To_Row
     (Info : Contract_Predicate_Context_Info;
      Id   : Contract_Predicate_Row_Id) return Contract_Predicate_Info is
      Status : constant Contract_Predicate_Status := Status_For (Info);
      Row    : Contract_Predicate_Info;
   begin
      Row.Id := Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Subject := Info.Subject;
      Row.Placement := Info.Placement;
      Row.Status := Status;
      Row.Node := Info.Node;
      Row.Subject_Node := Info.Subject_Node;
      Row.Expression_Node := Info.Expression_Node;
      Row.Name := Info.Name;
      Row.Object_Name := Info.Object_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("Contract=" & Contract.Contract_Legality_Status'Image (Info.Contract_Status) &
         "; Predicate_Dataflow=" & Pred_Flow.Predicate_Dataflow_Status'Image (Info.Predicate_Dataflow_Status));
      Row.Contract_Row := Info.Contract_Row;
      Row.Contract_Status := Info.Contract_Status;
      Row.Predicate_Dataflow_Row := Info.Predicate_Dataflow_Row;
      Row.Predicate_Dataflow_Status := Info.Predicate_Dataflow_Status;
      Row.Predicate_Dataflow_Matches := Info.Predicate_Dataflow_Matches;
      Row.Requires_Predicate_Evidence := Info.Requires_Predicate_Evidence;
      Row.Requires_Invariant_Evidence := Info.Requires_Invariant_Evidence;
      Row.Requires_Flow_Evidence := Info.Requires_Flow_Evidence;
      Row.Requires_Initialization_Evidence := Info.Requires_Initialization_Evidence;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Contract_Fingerprint := Info.Contract_Fingerprint;
      Row.Predicate_Dataflow_Fingerprint := Info.Predicate_Dataflow_Fingerprint;
      Row.Fingerprint := Fingerprint_For (Row);
      return Row;
   end To_Row;

   procedure Clear (Model : in out Contract_Predicate_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Contract_Predicate_Context_Model;
      Info  : Contract_Predicate_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Contract.Contract_Legality_Status'Pos (Info.Contract_Status) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Pred_Flow.Predicate_Dataflow_Status'Pos (Info.Predicate_Dataflow_Status) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Contract_Predicate_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Contract_Predicate_Context_Model;
      Index : Positive) return Contract_Predicate_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Contract_Predicate_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Contract_Predicate_Context_Model) return Contract_Predicate_Model is
      Model : Contract_Predicate_Model;
      Next  : Contract_Predicate_Row_Id := 1;
      Row   : Contract_Predicate_Info;
   begin
      for C of Contexts.Contexts loop
         Row := To_Row (C, Next);
         Model.Rows.Append (Row);
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Contract_Predicate_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Contract_Predicate_Model;
      Index : Positive) return Contract_Predicate_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Contract_Predicate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Contract_Predicate_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Contract_Predicate_Model;
      Status : Contract_Predicate_Status) return Contract_Predicate_Set is
      Results : Contract_Predicate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Contract_Predicate_Model;
      Kind  : Contract.Contract_Context_Kind) return Contract_Predicate_Set is
      Results : Contract_Predicate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Name
     (Model : Contract_Predicate_Model;
      Name  : String) return Contract_Predicate_Set is
      Results : Contract_Predicate_Set;
   begin
      for Row of Model.Rows loop
         if Text (Row.Name) = Name or else Text (Row.Object_Name) = Name then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Name;

   function Set_Count (Results : Contract_Predicate_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Set_Count;

   function Set_At
     (Results : Contract_Predicate_Set;
      Index   : Positive) return Contract_Predicate_Info is
   begin
      return Results.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Contract_Predicate_Model;
      Status : Contract_Predicate_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Contract_Predicate_Model;
      Kind  : Contract.Contract_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Is_Legal (Status : Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Contract_Predicate_Legal_Precondition_Accepted |
        Contract_Predicate_Legal_Postcondition_Accepted |
        Contract_Predicate_Legal_Invariant_Accepted |
        Contract_Predicate_Legal_Static_Predicate_Accepted |
        Contract_Predicate_Legal_Dynamic_Predicate_Accepted |
        Contract_Predicate_Legal_Assertion_Accepted |
        Contract_Predicate_Legal_Contract_Case_Accepted |
        Contract_Predicate_Legal_Global_Aspect_Accepted |
        Contract_Predicate_Legal_Depends_Aspect_Accepted |
        Contract_Predicate_Legal_Refined_Global_Accepted |
        Contract_Predicate_Legal_Refined_Depends_Accepted;
   end Is_Legal;

   function Is_Initialization_Error (Status : Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Contract_Predicate_Read_Before_Write_Blocker |
        Contract_Predicate_Component_Read_Before_Write_Blocker |
        Contract_Predicate_Partial_Component_Init_Blocker |
        Contract_Predicate_Out_Parameter_Not_Assigned_Blocker |
        Contract_Predicate_In_Out_Conditional_Assignment_Blocker |
        Contract_Predicate_Return_Object_Not_Initialized_Blocker |
        Contract_Predicate_Branch_Loop_Merge_Blocker |
        Contract_Predicate_Exception_Path_Loss_Blocker |
        Contract_Predicate_Finalization_Uses_Uninitialized_Blocker |
        Contract_Predicate_Use_After_Finalization_Blocker;
   end Is_Initialization_Error;

   function Is_Dataflow_Error (Status : Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Contract_Predicate_Missing_Predicate_Dataflow_Row |
        Contract_Predicate_Global_Blocker |
        Contract_Predicate_Depends_Blocker |
        Contract_Predicate_Call_Propagation_Blocker |
        Contract_Predicate_Generic_Effect_Blocker |
        Contract_Predicate_Tasking_Protected_Blocker |
        Contract_Predicate_Linked_Dataflow_Blocker |
        Contract_Predicate_Multiple_Blockers;
   end Is_Dataflow_Error;

   function Legal_Count (Model : Contract_Predicate_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Contract_Predicate_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status) and then Row.Status /= Contract_Predicate_Indeterminate and then
           Row.Status /= Contract_Predicate_Not_Checked
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Predicate_Error_Count (Model : Contract_Predicate_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Contract_Predicate_Base_Predicate_Propagation_Error then Count := Count + 1; end if;
      end loop;
      return Count;
   end Predicate_Error_Count;

   function Initialization_Error_Count (Model : Contract_Predicate_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Initialization_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Initialization_Error_Count;

   function Dataflow_Error_Count (Model : Contract_Predicate_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dataflow_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Dataflow_Error_Count;

   function Coverage_Error_Count (Model : Contract_Predicate_Model) return Natural is
   begin
      return Count_Status (Model, Contract_Predicate_Coverage_Blocker);
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Contract_Predicate_Model) return Natural is
   begin
      return Count_Status (Model, Contract_Predicate_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Contract_Predicate_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
