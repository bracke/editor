with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Flow_Init.Dataflow_Init_Row_Id;
   use type Flow_Init.Dataflow_Init_Status;
   use type Prop.Propagation_Context_Kind;
   use type Prop.Propagation_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 16_777_619 + B + 197) mod 2_147_483_647;
   end Mix;

   function Text (Value : Unbounded_String) return String is
   begin
      return To_String (Value);
   end Text;

   function Is_Propagation_Legal (Status : Prop.Propagation_Status) return Boolean is
   begin
      return Status in
        Prop.Propagation_Legal_Static_Predicate_Preserved |
        Prop.Propagation_Legal_Dynamic_Predicate_Propagated |
        Prop.Propagation_Legal_Invariant_Preserved |
        Prop.Propagation_Legal_Dynamic_Invariant_Propagated |
        Prop.Propagation_Legal_Generic_Substitution_Propagated |
        Prop.Propagation_Legal_Derived_Invariant_Propagated |
        Prop.Propagation_Legal_Private_Full_View_Propagated |
        Prop.Propagation_Legal_Flow_Effect_Propagated;
   end Is_Propagation_Legal;

   function Is_Dataflow_Init_Legal
     (Status : Flow_Init.Dataflow_Init_Status) return Boolean is
   begin
      return Status in
        Flow_Init.Dataflow_Init_Legal_Read_Accepted |
        Flow_Init.Dataflow_Init_Legal_Write_Accepted |
        Flow_Init.Dataflow_Init_Legal_Read_Write_Accepted |
        Flow_Init.Dataflow_Init_Legal_Null_Effect_Accepted |
        Flow_Init.Dataflow_Init_Legal_Depends_Edge_Accepted |
        Flow_Init.Dataflow_Init_Legal_Refinement_Accepted |
        Flow_Init.Dataflow_Init_Legal_Call_Propagation_Accepted |
        Flow_Init.Dataflow_Init_Legal_Generic_Effect_Accepted |
        Flow_Init.Dataflow_Init_Legal_Task_Protected_Effect_Accepted;
   end Is_Dataflow_Init_Legal;

   function Legal_Status_For
     (Info : Predicate_Dataflow_Context_Info) return Predicate_Dataflow_Status is
   begin
      if Info.Generic_Obligation then
         return Predicate_Dataflow_Legal_Generic_Substitution_Accepted;
      elsif Info.Derived_Obligation then
         return Predicate_Dataflow_Legal_Derived_Invariant_Accepted;
      elsif Info.Private_View_Obligation then
         return Predicate_Dataflow_Legal_Private_Full_View_Accepted;
      elsif Info.Flow_Effect_Obligation then
         return Predicate_Dataflow_Legal_Flow_Effect_Accepted;
      end if;

      case Info.Propagation_Status is
         when Prop.Propagation_Legal_Static_Predicate_Preserved =>
            return Predicate_Dataflow_Legal_Static_Predicate_Accepted;
         when Prop.Propagation_Legal_Dynamic_Predicate_Propagated =>
            return Predicate_Dataflow_Legal_Dynamic_Predicate_Accepted;
         when Prop.Propagation_Legal_Invariant_Preserved =>
            return Predicate_Dataflow_Legal_Invariant_Accepted;
         when Prop.Propagation_Legal_Dynamic_Invariant_Propagated =>
            return Predicate_Dataflow_Legal_Dynamic_Invariant_Accepted;
         when Prop.Propagation_Legal_Generic_Substitution_Propagated =>
            return Predicate_Dataflow_Legal_Generic_Substitution_Accepted;
         when Prop.Propagation_Legal_Derived_Invariant_Propagated =>
            return Predicate_Dataflow_Legal_Derived_Invariant_Accepted;
         when Prop.Propagation_Legal_Private_Full_View_Propagated =>
            return Predicate_Dataflow_Legal_Private_Full_View_Accepted;
         when Prop.Propagation_Legal_Flow_Effect_Propagated =>
            return Predicate_Dataflow_Legal_Flow_Effect_Accepted;
         when others =>
            return Predicate_Dataflow_Indeterminate;
      end case;
   end Legal_Status_For;

   function Status_From_Dataflow_Init
     (Status : Flow_Init.Dataflow_Init_Status) return Predicate_Dataflow_Status is
   begin
      case Status is
         when Flow_Init.Dataflow_Init_Missing_Initialization_Object_Flow_Row =>
            return Predicate_Dataflow_Missing_Dataflow_Init_Row;
         when Flow_Init.Dataflow_Init_Mismatched_Initialization_Object =>
            return Predicate_Dataflow_Mismatched_Object;
         when Flow_Init.Dataflow_Init_Read_Before_Write_Blocker =>
            return Predicate_Dataflow_Read_Before_Write_Blocker;
         when Flow_Init.Dataflow_Init_Component_Read_Before_Write_Blocker =>
            return Predicate_Dataflow_Component_Read_Before_Write_Blocker;
         when Flow_Init.Dataflow_Init_Partial_Component_Init_Blocker =>
            return Predicate_Dataflow_Partial_Component_Init_Blocker;
         when Flow_Init.Dataflow_Init_Out_Parameter_Not_Assigned_Blocker =>
            return Predicate_Dataflow_Out_Parameter_Not_Assigned_Blocker;
         when Flow_Init.Dataflow_Init_In_Out_Conditional_Assignment_Blocker =>
            return Predicate_Dataflow_In_Out_Conditional_Assignment_Blocker;
         when Flow_Init.Dataflow_Init_Return_Object_Not_Initialized_Blocker =>
            return Predicate_Dataflow_Return_Object_Not_Initialized_Blocker;
         when Flow_Init.Dataflow_Init_Branch_Loop_Merge_Blocker =>
            return Predicate_Dataflow_Branch_Loop_Merge_Blocker;
         when Flow_Init.Dataflow_Init_Exception_Path_Loss_Blocker =>
            return Predicate_Dataflow_Exception_Path_Loss_Blocker;
         when Flow_Init.Dataflow_Init_Finalization_Uses_Uninitialized_Blocker =>
            return Predicate_Dataflow_Finalization_Uses_Uninitialized_Blocker;
         when Flow_Init.Dataflow_Init_Use_After_Finalization_Blocker =>
            return Predicate_Dataflow_Use_After_Finalization_Blocker;
         when Flow_Init.Dataflow_Init_Lifetime_Blocker =>
            return Predicate_Dataflow_Lifetime_Blocker;
         when Flow_Init.Dataflow_Init_Discriminant_Representation_Blocker =>
            return Predicate_Dataflow_Discriminant_Representation_Blocker;
         when Flow_Init.Dataflow_Init_Coverage_Blocker |
              Flow_Init.Dataflow_Init_Flow_Coverage_Blocker =>
            return Predicate_Dataflow_Coverage_Blocker;
         when Flow_Init.Dataflow_Init_Flow_Global_Blocker =>
            return Predicate_Dataflow_Global_Blocker;
         when Flow_Init.Dataflow_Init_Flow_Depends_Blocker =>
            return Predicate_Dataflow_Depends_Blocker;
         when Flow_Init.Dataflow_Init_Flow_Propagation_Blocker =>
            return Predicate_Dataflow_Call_Propagation_Blocker;
         when Flow_Init.Dataflow_Init_Flow_Generic_Blocker =>
            return Predicate_Dataflow_Generic_Effect_Blocker;
         when Flow_Init.Dataflow_Init_Flow_Tasking_Protected_Blocker =>
            return Predicate_Dataflow_Tasking_Protected_Blocker;
         when Flow_Init.Dataflow_Init_Flow_Linked_Dataflow_Blocker |
              Flow_Init.Dataflow_Init_Base_Dataflow_Error |
              Flow_Init.Dataflow_Init_Linked_Initialization_Blocker |
              Flow_Init.Dataflow_Init_Missing_Flow_Edge_Row =>
            return Predicate_Dataflow_Linked_Dataflow_Blocker;
         when Flow_Init.Dataflow_Init_Multiple_Blockers =>
            return Predicate_Dataflow_Multiple_Blockers;
         when Flow_Init.Dataflow_Init_Indeterminate |
              Flow_Init.Dataflow_Init_Not_Checked =>
            return Predicate_Dataflow_Indeterminate;
         when others =>
            if Is_Dataflow_Init_Legal (Status) then
               return Predicate_Dataflow_Not_Checked;
            else
               return Predicate_Dataflow_Linked_Dataflow_Blocker;
            end if;
      end case;
   end Status_From_Dataflow_Init;

   function Status_For
     (Info : Predicate_Dataflow_Context_Info) return Predicate_Dataflow_Status is
      DF_Status : Predicate_Dataflow_Status;
      Needs_DF  : constant Boolean :=
        Info.Requires_Dataflow_State or else Info.State_Was_Updated or else
        Info.Flow_Effect_Obligation or else
        Info.Propagation_Status = Prop.Propagation_Legal_Flow_Effect_Propagated;
   begin
      if not Is_Propagation_Legal (Info.Propagation_Status) then
         if Info.Propagation_Status = Prop.Propagation_Not_Checked or else
           Info.Propagation_Status = Prop.Propagation_Indeterminate
         then
            return Predicate_Dataflow_Indeterminate;
         else
            return Predicate_Dataflow_Base_Predicate_Propagation_Error;
         end if;
      end if;

      if Needs_DF then
         if Info.Dataflow_Init_Row = Flow_Init.No_Dataflow_Init_Row or else
           Info.Dataflow_Init_Matches = 0
         then
            return Predicate_Dataflow_Missing_Dataflow_Init_Row;
         end if;

         DF_Status := Status_From_Dataflow_Init (Info.Dataflow_Init_Status);
         if DF_Status /= Predicate_Dataflow_Not_Checked then
            return DF_Status;
         end if;
      end if;

      return Legal_Status_For (Info);
   end Status_For;

   function Message_For (Status : Predicate_Dataflow_Status) return String is
   begin
      case Status is
         when Predicate_Dataflow_Legal_Static_Predicate_Accepted => return "Static predicate propagation accepted with initialized dataflow evidence";
         when Predicate_Dataflow_Legal_Dynamic_Predicate_Accepted => return "Dynamic predicate propagation accepted with initialized dataflow evidence";
         when Predicate_Dataflow_Legal_Invariant_Accepted => return "Invariant preservation accepted with dataflow evidence";
         when Predicate_Dataflow_Legal_Dynamic_Invariant_Accepted => return "Dynamic invariant propagation accepted";
         when Predicate_Dataflow_Legal_Generic_Substitution_Accepted => return "Generic predicate/invariant substitution accepted";
         when Predicate_Dataflow_Legal_Derived_Invariant_Accepted => return "Derived invariant propagation accepted";
         when Predicate_Dataflow_Legal_Private_Full_View_Accepted => return "Private/full-view invariant propagation accepted";
         when Predicate_Dataflow_Legal_Flow_Effect_Accepted => return "Flow-effect predicate/invariant propagation accepted";
         when Predicate_Dataflow_Base_Predicate_Propagation_Error => return "Base predicate/invariant propagation error preserved";
         when Predicate_Dataflow_Missing_Dataflow_Init_Row => return "Missing dataflow definite-initialization consumer row";
         when Predicate_Dataflow_Mismatched_Object => return "Mismatched dataflow initialization object evidence";
         when Predicate_Dataflow_Read_Before_Write_Blocker => return "Read-before-write blocks predicate/invariant propagation";
         when Predicate_Dataflow_Component_Read_Before_Write_Blocker => return "Component read-before-write blocks predicate/invariant propagation";
         when Predicate_Dataflow_Partial_Component_Init_Blocker => return "Partial component initialization blocks predicate/invariant propagation";
         when Predicate_Dataflow_Out_Parameter_Not_Assigned_Blocker => return "Out parameter assignment obligation blocks predicate/invariant propagation";
         when Predicate_Dataflow_In_Out_Conditional_Assignment_Blocker => return "Conditional in out assignment blocks predicate/invariant propagation";
         when Predicate_Dataflow_Return_Object_Not_Initialized_Blocker => return "Return object initialization blocks predicate/invariant propagation";
         when Predicate_Dataflow_Branch_Loop_Merge_Blocker => return "Branch/loop merge proof blocks predicate/invariant propagation";
         when Predicate_Dataflow_Exception_Path_Loss_Blocker => return "Exception path initialization loss blocks predicate/invariant propagation";
         when Predicate_Dataflow_Finalization_Uses_Uninitialized_Blocker => return "Finalization using uninitialized state blocks predicate/invariant propagation";
         when Predicate_Dataflow_Use_After_Finalization_Blocker => return "Use after finalization blocks predicate/invariant propagation";
         when Predicate_Dataflow_Lifetime_Blocker => return "Exact lifetime/accessibility evidence blocks predicate/invariant propagation";
         when Predicate_Dataflow_Discriminant_Representation_Blocker => return "Discriminant or representation evidence blocks predicate/invariant propagation";
         when Predicate_Dataflow_Coverage_Blocker => return "Coverage repair gate blocks predicate/invariant propagation";
         when Predicate_Dataflow_Global_Blocker => return "Global flow blocker prevents predicate/invariant propagation";
         when Predicate_Dataflow_Depends_Blocker => return "Depends flow blocker prevents predicate/invariant propagation";
         when Predicate_Dataflow_Call_Propagation_Blocker => return "Call propagation blocker prevents predicate/invariant propagation";
         when Predicate_Dataflow_Generic_Effect_Blocker => return "Generic flow effect blocker prevents predicate/invariant propagation";
         when Predicate_Dataflow_Tasking_Protected_Blocker => return "Tasking/protected flow blocker prevents predicate/invariant propagation";
         when Predicate_Dataflow_Linked_Dataflow_Blocker => return "Linked dataflow blocker prevents predicate/invariant propagation";
         when Predicate_Dataflow_Multiple_Blockers => return "Multiple dataflow/initialization blockers prevent propagation";
         when Predicate_Dataflow_Indeterminate => return "Predicate/invariant dataflow state is indeterminate";
         when Predicate_Dataflow_Not_Checked => return "Predicate dataflow consumer not checked";
      end case;
   end Message_For;

   function Fingerprint_For (Info : Predicate_Dataflow_Info) return Natural is
      F : Natural := Natural (Info.Id);
   begin
      F := Mix (F, Predicate_Dataflow_Status'Pos (Info.Status) + 1);
      F := Mix (F, Prop.Propagation_Context_Kind'Pos (Info.Kind) + 1);
      F := Mix (F, Prop.Propagation_Obligation_Kind'Pos (Info.Obligation) + 1);
      F := Mix (F, Natural (Info.Node));
      F := Mix (F, Natural (Info.Propagation_Row));
      F := Mix (F, Prop.Propagation_Status'Pos (Info.Propagation_Status) + 1);
      F := Mix (F, Natural (Info.Dataflow_Init_Row));
      F := Mix (F, Flow_Init.Dataflow_Init_Status'Pos (Info.Dataflow_Init_Status) + 1);
      F := Mix (F, Info.Source_Fingerprint);
      F := Mix (F, Info.Propagation_Fingerprint);
      F := Mix (F, Info.Dataflow_Init_Fingerprint);
      return F;
   end Fingerprint_For;

   function To_Row
     (Info : Predicate_Dataflow_Context_Info;
      Id   : Predicate_Dataflow_Row_Id) return Predicate_Dataflow_Info is
      Status : constant Predicate_Dataflow_Status := Status_For (Info);
      Row    : Predicate_Dataflow_Info;
   begin
      Row.Id := Id;
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Obligation := Info.Obligation;
      Row.Status := Status;
      Row.Node := Info.Node;
      Row.Source_Node := Info.Source_Node;
      Row.Target_Node := Info.Target_Node;
      Row.Subtype_Name := Info.Subtype_Name;
      Row.Object_Name := Info.Object_Name;
      Row.Caller_Name := Info.Caller_Name;
      Row.Callee_Name := Info.Callee_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("Propagation=" & Prop.Propagation_Status'Image (Info.Propagation_Status) &
         "; Dataflow_Init=" & Flow_Init.Dataflow_Init_Status'Image (Info.Dataflow_Init_Status));
      Row.Propagation_Row := Info.Propagation_Row;
      Row.Propagation_Status := Info.Propagation_Status;
      Row.Dataflow_Init_Row := Info.Dataflow_Init_Row;
      Row.Dataflow_Init_Status := Info.Dataflow_Init_Status;
      Row.Dataflow_Init_Matches := Info.Dataflow_Init_Matches;
      Row.Requires_Dataflow_State := Info.Requires_Dataflow_State;
      Row.State_Was_Updated := Info.State_Was_Updated;
      Row.Dynamic_Check := Info.Dynamic_Check;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Propagation_Fingerprint := Info.Propagation_Fingerprint;
      Row.Dataflow_Init_Fingerprint := Info.Dataflow_Init_Fingerprint;
      Row.Fingerprint := Fingerprint_For (Row);
      return Row;
   end To_Row;

   procedure Clear (Model : in out Predicate_Dataflow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Predicate_Dataflow_Context_Model;
      Info  : Predicate_Dataflow_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Prop.Propagation_Status'Pos (Info.Propagation_Status) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Flow_Init.Dataflow_Init_Status'Pos (Info.Dataflow_Init_Status) + 1);
   end Add_Context;

   function Context_Count (Model : Predicate_Dataflow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Predicate_Dataflow_Context_Model;
      Index : Positive) return Predicate_Dataflow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Predicate_Dataflow_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Predicate_Dataflow_Context_Model) return Predicate_Dataflow_Model is
      Model : Predicate_Dataflow_Model;
      Next  : Predicate_Dataflow_Row_Id := 1;
      Row   : Predicate_Dataflow_Info;
   begin
      for C of Contexts.Contexts loop
         Row := To_Row (C, Next);
         Model.Rows.Append (Row);
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
         Next := Next + 1;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Predicate_Dataflow_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Predicate_Dataflow_Model;
      Index : Positive) return Predicate_Dataflow_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Predicate_Dataflow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_Dataflow_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Predicate_Dataflow_Model;
      Status : Predicate_Dataflow_Status) return Predicate_Dataflow_Set is
      Results : Predicate_Dataflow_Set;
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
     (Model : Predicate_Dataflow_Model;
      Kind  : Prop.Propagation_Context_Kind) return Predicate_Dataflow_Set is
      Results : Predicate_Dataflow_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model : Predicate_Dataflow_Model;
      Name  : String) return Predicate_Dataflow_Set is
      Results : Predicate_Dataflow_Set;
   begin
      for Row of Model.Rows loop
         if Text (Row.Object_Name) = Name or else Text (Row.Subtype_Name) = Name or else
           Text (Row.Caller_Name) = Name or else Text (Row.Callee_Name) = Name
         then
            Results.Items.Append (Row);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Object;

   function Set_Count (Results : Predicate_Dataflow_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Set_Count;

   function Set_At
     (Results : Predicate_Dataflow_Set;
      Index   : Positive) return Predicate_Dataflow_Info is
   begin
      return Results.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Predicate_Dataflow_Model;
      Status : Predicate_Dataflow_Status) return Natural is
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
     (Model : Predicate_Dataflow_Model;
      Kind  : Prop.Propagation_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Is_Legal (Status : Predicate_Dataflow_Status) return Boolean is
   begin
      return Status in
        Predicate_Dataflow_Legal_Static_Predicate_Accepted |
        Predicate_Dataflow_Legal_Dynamic_Predicate_Accepted |
        Predicate_Dataflow_Legal_Invariant_Accepted |
        Predicate_Dataflow_Legal_Dynamic_Invariant_Accepted |
        Predicate_Dataflow_Legal_Generic_Substitution_Accepted |
        Predicate_Dataflow_Legal_Derived_Invariant_Accepted |
        Predicate_Dataflow_Legal_Private_Full_View_Accepted |
        Predicate_Dataflow_Legal_Flow_Effect_Accepted;
   end Is_Legal;

   function Is_Predicate_Error (Status : Predicate_Dataflow_Status) return Boolean is
   begin
      return Status = Predicate_Dataflow_Base_Predicate_Propagation_Error;
   end Is_Predicate_Error;

   function Is_Invariant_Error (Status : Predicate_Dataflow_Status) return Boolean is
   begin
      return Status in
        Predicate_Dataflow_Read_Before_Write_Blocker |
        Predicate_Dataflow_Component_Read_Before_Write_Blocker |
        Predicate_Dataflow_Partial_Component_Init_Blocker |
        Predicate_Dataflow_Finalization_Uses_Uninitialized_Blocker |
        Predicate_Dataflow_Use_After_Finalization_Blocker |
        Predicate_Dataflow_Lifetime_Blocker |
        Predicate_Dataflow_Discriminant_Representation_Blocker;
   end Is_Invariant_Error;

   function Is_Dataflow_Error (Status : Predicate_Dataflow_Status) return Boolean is
   begin
      return Status in
        Predicate_Dataflow_Missing_Dataflow_Init_Row |
        Predicate_Dataflow_Mismatched_Object |
        Predicate_Dataflow_Global_Blocker |
        Predicate_Dataflow_Depends_Blocker |
        Predicate_Dataflow_Call_Propagation_Blocker |
        Predicate_Dataflow_Generic_Effect_Blocker |
        Predicate_Dataflow_Tasking_Protected_Blocker |
        Predicate_Dataflow_Linked_Dataflow_Blocker |
        Predicate_Dataflow_Multiple_Blockers;
   end Is_Dataflow_Error;

   function Is_Initialization_Error (Status : Predicate_Dataflow_Status) return Boolean is
   begin
      return Status in
        Predicate_Dataflow_Read_Before_Write_Blocker |
        Predicate_Dataflow_Component_Read_Before_Write_Blocker |
        Predicate_Dataflow_Partial_Component_Init_Blocker |
        Predicate_Dataflow_Out_Parameter_Not_Assigned_Blocker |
        Predicate_Dataflow_In_Out_Conditional_Assignment_Blocker |
        Predicate_Dataflow_Return_Object_Not_Initialized_Blocker |
        Predicate_Dataflow_Branch_Loop_Merge_Blocker |
        Predicate_Dataflow_Exception_Path_Loss_Blocker |
        Predicate_Dataflow_Finalization_Uses_Uninitialized_Blocker |
        Predicate_Dataflow_Use_After_Finalization_Blocker;
   end Is_Initialization_Error;

   function Is_Coverage_Error (Status : Predicate_Dataflow_Status) return Boolean is
   begin
      return Status = Predicate_Dataflow_Coverage_Blocker;
   end Is_Coverage_Error;

   function Legal_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status) and then Row.Status /= Predicate_Dataflow_Indeterminate and then
           Row.Status /= Predicate_Dataflow_Not_Checked
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Predicate_Error_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Predicate_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Predicate_Error_Count;

   function Invariant_Error_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Invariant_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Invariant_Error_Count;

   function Dataflow_Error_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Dataflow_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Dataflow_Error_Count;

   function Initialization_Error_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Initialization_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Initialization_Error_Count;

   function Coverage_Error_Count (Model : Predicate_Dataflow_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Coverage_Error (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Predicate_Dataflow_Model) return Natural is
   begin
      return Count_Status (Model, Predicate_Dataflow_Indeterminate);
   end Indeterminate_Count;

   function Fingerprint (Model : Predicate_Dataflow_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
