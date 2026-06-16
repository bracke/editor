with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Row_Id;
   use type Task_Effects.Tasking_Effect_Status;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 97) mod 2_147_483_647;
   end Mix;

   function Text_Hash (Text : Unbounded_String) return Natural is
      S : constant String := To_String (Text);
      H : Natural := 0;
   begin
      for C of S loop
         H := Mix (H, Character'Pos (C) + 1);
      end loop;
      return H;
   end Text_Hash;

   function Is_Legal (Status : Tasking_Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Tasking_Contract_Predicate_Legal_Task_Activation_Accepted |
        Tasking_Contract_Predicate_Legal_Task_Termination_Accepted |
        Tasking_Contract_Predicate_Legal_Protected_Read_Accepted |
        Tasking_Contract_Predicate_Legal_Protected_Write_Accepted |
        Tasking_Contract_Predicate_Legal_Protected_Function_Call_Accepted |
        Tasking_Contract_Predicate_Legal_Protected_Procedure_Call_Accepted |
        Tasking_Contract_Predicate_Legal_Protected_Entry_Call_Accepted |
        Tasking_Contract_Predicate_Legal_Entry_Queue_Accepted |
        Tasking_Contract_Predicate_Legal_Entry_Barrier_Accepted |
        Tasking_Contract_Predicate_Legal_Accept_Body_Accepted |
        Tasking_Contract_Predicate_Legal_Requeue_Accepted |
        Tasking_Contract_Predicate_Legal_Select_Guard_Accepted |
        Tasking_Contract_Predicate_Legal_Select_Alternative_Accepted |
        Tasking_Contract_Predicate_Legal_Abortable_Part_Accepted |
        Tasking_Contract_Predicate_Legal_Delay_Alternative_Accepted |
        Tasking_Contract_Predicate_Legal_Terminate_Alternative_Accepted;
   end Is_Legal;

   function Is_Initialization_Error (Status : Tasking_Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Tasking_Contract_Predicate_Read_Before_Write_Blocker |
        Tasking_Contract_Predicate_Component_Read_Before_Write_Blocker |
        Tasking_Contract_Predicate_Partial_Initialization_Blocker |
        Tasking_Contract_Predicate_Missing_Out_Assignment_Blocker |
        Tasking_Contract_Predicate_Conditional_In_Out_Blocker |
        Tasking_Contract_Predicate_Return_Object_Initialization_Blocker |
        Tasking_Contract_Predicate_Branch_Loop_Merge_Blocker |
        Tasking_Contract_Predicate_Exception_Finalization_Path_Blocker |
        Tasking_Contract_Predicate_Use_After_Finalization_Blocker;
   end Is_Initialization_Error;

   function Is_Predicate_Error (Status : Tasking_Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Tasking_Contract_Predicate_Predicate_Propagation_Blocker |
        Tasking_Contract_Predicate_Discriminant_Variant_Blocker |
        Tasking_Contract_Predicate_Representation_Freezing_Blocker;
   end Is_Predicate_Error;

   function Is_Dataflow_Error (Status : Tasking_Contract_Predicate_Status) return Boolean is
   begin
      return Status in
        Tasking_Contract_Predicate_Global_Depends_Blocker |
        Tasking_Contract_Predicate_Call_Propagation_Blocker |
        Tasking_Contract_Predicate_Generic_Flow_Blocker |
        Tasking_Contract_Predicate_Tasking_Protected_Flow_Blocker;
   end Is_Dataflow_Error;

   function Legal_Status_For_Kind
     (Kind : Tasking_Contract_Predicate_Context_Kind) return Tasking_Contract_Predicate_Status is
   begin
      case Kind is
         when Tasking_Contract_Predicate_Task_Activation =>
            return Tasking_Contract_Predicate_Legal_Task_Activation_Accepted;
         when Tasking_Contract_Predicate_Task_Termination =>
            return Tasking_Contract_Predicate_Legal_Task_Termination_Accepted;
         when Tasking_Contract_Predicate_Protected_Read =>
            return Tasking_Contract_Predicate_Legal_Protected_Read_Accepted;
         when Tasking_Contract_Predicate_Protected_Write =>
            return Tasking_Contract_Predicate_Legal_Protected_Write_Accepted;
         when Tasking_Contract_Predicate_Protected_Function_Call =>
            return Tasking_Contract_Predicate_Legal_Protected_Function_Call_Accepted;
         when Tasking_Contract_Predicate_Protected_Procedure_Call =>
            return Tasking_Contract_Predicate_Legal_Protected_Procedure_Call_Accepted;
         when Tasking_Contract_Predicate_Protected_Entry_Call =>
            return Tasking_Contract_Predicate_Legal_Protected_Entry_Call_Accepted;
         when Tasking_Contract_Predicate_Entry_Queue =>
            return Tasking_Contract_Predicate_Legal_Entry_Queue_Accepted;
         when Tasking_Contract_Predicate_Entry_Barrier =>
            return Tasking_Contract_Predicate_Legal_Entry_Barrier_Accepted;
         when Tasking_Contract_Predicate_Accept_Body =>
            return Tasking_Contract_Predicate_Legal_Accept_Body_Accepted;
         when Tasking_Contract_Predicate_Requeue =>
            return Tasking_Contract_Predicate_Legal_Requeue_Accepted;
         when Tasking_Contract_Predicate_Select_Guard =>
            return Tasking_Contract_Predicate_Legal_Select_Guard_Accepted;
         when Tasking_Contract_Predicate_Select_Alternative =>
            return Tasking_Contract_Predicate_Legal_Select_Alternative_Accepted;
         when Tasking_Contract_Predicate_Abortable_Part =>
            return Tasking_Contract_Predicate_Legal_Abortable_Part_Accepted;
         when Tasking_Contract_Predicate_Delay_Alternative =>
            return Tasking_Contract_Predicate_Legal_Delay_Alternative_Accepted;
         when Tasking_Contract_Predicate_Terminate_Alternative =>
            return Tasking_Contract_Predicate_Legal_Terminate_Alternative_Accepted;
         when others =>
            return Tasking_Contract_Predicate_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Elab_Predicate
     (Status : Elab_Predicate.Elaboration_Contract_Predicate_Status) return Tasking_Contract_Predicate_Status is
   begin
      case Status is
         when Elab_Predicate.Elaboration_Contract_Predicate_Missing_Contract_Predicate_Row |
              Elab_Predicate.Elaboration_Contract_Predicate_Not_Checked =>
            return Tasking_Contract_Predicate_Missing_Contract_Predicate_Row;
         when Elab_Predicate.Elaboration_Contract_Predicate_Base_Contract_Error =>
            return Tasking_Contract_Predicate_Base_Contract_Error;
         when Elab_Predicate.Elaboration_Contract_Predicate_Base_Elaboration_Error =>
            return Tasking_Contract_Predicate_Base_Elaboration_Error;
         when Elab_Predicate.Elaboration_Contract_Predicate_Base_Predicate_Propagation_Error =>
            return Tasking_Contract_Predicate_Predicate_Propagation_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Read_Before_Write_Blocker =>
            return Tasking_Contract_Predicate_Read_Before_Write_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Component_Read_Before_Write_Blocker =>
            return Tasking_Contract_Predicate_Component_Read_Before_Write_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Partial_Component_Init_Blocker =>
            return Tasking_Contract_Predicate_Partial_Initialization_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Out_Parameter_Not_Assigned_Blocker =>
            return Tasking_Contract_Predicate_Missing_Out_Assignment_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_In_Out_Conditional_Assignment_Blocker =>
            return Tasking_Contract_Predicate_Conditional_In_Out_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Return_Object_Not_Initialized_Blocker =>
            return Tasking_Contract_Predicate_Return_Object_Initialization_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Branch_Loop_Merge_Blocker =>
            return Tasking_Contract_Predicate_Branch_Loop_Merge_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Exception_Path_Loss_Blocker |
              Elab_Predicate.Elaboration_Contract_Predicate_Finalization_Uses_Uninitialized_Blocker =>
            return Tasking_Contract_Predicate_Exception_Finalization_Path_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Use_After_Finalization_Blocker =>
            return Tasking_Contract_Predicate_Use_After_Finalization_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Lifetime_Blocker =>
            return Tasking_Contract_Predicate_Lifetime_Accessibility_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Discriminant_Representation_Blocker =>
            return Tasking_Contract_Predicate_Discriminant_Variant_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Global_Blocker |
              Elab_Predicate.Elaboration_Contract_Predicate_Depends_Blocker |
              Elab_Predicate.Elaboration_Contract_Predicate_Linked_Dataflow_Blocker =>
            return Tasking_Contract_Predicate_Global_Depends_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Call_Propagation_Blocker =>
            return Tasking_Contract_Predicate_Call_Propagation_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Generic_Effect_Blocker =>
            return Tasking_Contract_Predicate_Generic_Flow_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Tasking_Protected_Blocker =>
            return Tasking_Contract_Predicate_Tasking_Protected_Flow_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Coverage_Blocker =>
            return Tasking_Contract_Predicate_Coverage_Blocker;
         when Elab_Predicate.Elaboration_Contract_Predicate_Multiple_Contract_Predicate_Blockers =>
            return Tasking_Contract_Predicate_Multiple_Matching_Blockers;
         when Elab_Predicate.Elaboration_Contract_Predicate_Contract_Predicate_Indeterminate |
              Elab_Predicate.Elaboration_Contract_Predicate_Indeterminate =>
            return Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate;
         when others =>
            if Elab_Predicate.Is_Legal (Status) then
               return Tasking_Contract_Predicate_Not_Checked;
            else
               return Tasking_Contract_Predicate_Indeterminate;
            end if;
      end case;
   end Status_From_Elab_Predicate;

   function Status_For (Info : Tasking_Contract_Predicate_Context_Info) return Tasking_Contract_Predicate_Status is
   begin
      if not Task_Effects.Is_Legal (Info.Tasking_Status) then
         if Info.Tasking_Status = Task_Effects.Tasking_Effect_Indeterminate then
            return Tasking_Contract_Predicate_Indeterminate;
         else
            return Tasking_Contract_Predicate_Base_Tasking_Effect_Error;
         end if;
      elsif Info.Elaboration_Predicate_Matches > 1 then
         return Tasking_Contract_Predicate_Multiple_Matching_Blockers;
      elsif Info.Elaboration_Predicate_Row = Elab_Predicate.No_Elaboration_Contract_Predicate_Row then
         return Tasking_Contract_Predicate_Missing_Elaboration_Predicate_Row;
      elsif Elab_Predicate.Is_Legal (Info.Elaboration_Predicate_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Elab_Predicate (Info.Elaboration_Predicate_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Tasking_Contract_Predicate_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Tasking_Contract_Predicate_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Tasking_Contract_Predicate_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Task_Node) + 1);
      H := Mix (H, Natural (Info.Protected_Node) + 1);
      H := Mix (H, Natural (Info.Entry_Node) + 1);
      H := Mix (H, Natural (Info.Select_Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Entry_Name));
      H := Mix (H, Text_Hash (Info.Caller_Name));
      H := Mix (H, Text_Hash (Info.Callee_Name));
      H := Mix (H, Natural (Info.Tasking_Row) + 1);
      H := Mix (H, Task_Effects.Tasking_Effect_Status'Pos (Info.Tasking_Status) + 1);
      H := Mix (H, Natural (Info.Elaboration_Predicate_Row) + 1);
      H := Mix (H, Elab_Predicate.Elaboration_Contract_Predicate_Status'Pos (Info.Elaboration_Predicate_Status) + 1);
      H := Mix (H, Info.Elaboration_Predicate_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Tasking_Contract_Predicate_Status) return Unbounded_String is
   begin
      case Status is
         when Tasking_Contract_Predicate_Base_Tasking_Effect_Error =>
            return To_Unbounded_String ("base tasking/protected effect legality failed");
         when Tasking_Contract_Predicate_Missing_Elaboration_Predicate_Row =>
            return To_Unbounded_String ("tasking/protected effect is missing elaboration contract predicate/dataflow evidence");
         when Tasking_Contract_Predicate_Missing_Contract_Predicate_Row =>
            return To_Unbounded_String ("tasking/protected effect is missing contract predicate/dataflow evidence");
         when Tasking_Contract_Predicate_Base_Contract_Error =>
            return To_Unbounded_String ("tasking/protected effect is blocked by base contract legality");
         when Tasking_Contract_Predicate_Base_Elaboration_Error =>
            return To_Unbounded_String ("tasking/protected effect is blocked by elaboration graph legality");
         when Tasking_Contract_Predicate_Predicate_Propagation_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by predicate or invariant propagation");
         when Tasking_Contract_Predicate_Read_Before_Write_Blocker |
              Tasking_Contract_Predicate_Component_Read_Before_Write_Blocker |
              Tasking_Contract_Predicate_Partial_Initialization_Blocker |
              Tasking_Contract_Predicate_Missing_Out_Assignment_Blocker |
              Tasking_Contract_Predicate_Conditional_In_Out_Blocker |
              Tasking_Contract_Predicate_Return_Object_Initialization_Blocker |
              Tasking_Contract_Predicate_Branch_Loop_Merge_Blocker |
              Tasking_Contract_Predicate_Exception_Finalization_Path_Blocker |
              Tasking_Contract_Predicate_Use_After_Finalization_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by definite-initialization or object-state evidence");
         when Tasking_Contract_Predicate_Lifetime_Accessibility_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by lifetime/accessibility evidence");
         when Tasking_Contract_Predicate_Discriminant_Variant_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by discriminant or variant evidence");
         when Tasking_Contract_Predicate_Representation_Freezing_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by representation/freezing evidence");
         when Tasking_Contract_Predicate_Global_Depends_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by Global/Depends or refined-flow evidence");
         when Tasking_Contract_Predicate_Call_Propagation_Blocker =>
            return To_Unbounded_String ("tasking/protected call effect was not propagated");
         when Tasking_Contract_Predicate_Generic_Flow_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by generic flow evidence");
         when Tasking_Contract_Predicate_Tasking_Protected_Flow_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by tasking/protected flow evidence");
         when Tasking_Contract_Predicate_Coverage_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by repaired coverage feedback");
         when Tasking_Contract_Predicate_Multiple_Matching_Blockers =>
            return To_Unbounded_String ("tasking/protected effect has multiple matching elaboration contract predicate/dataflow blockers");
         when Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate |
              Tasking_Contract_Predicate_Indeterminate =>
            return To_Unbounded_String ("tasking/protected elaboration contract predicate/dataflow result is indeterminate");
         when others =>
            return To_Unbounded_String ("tasking/protected elaboration contract predicate/dataflow accepted");
      end case;
   end Message_For;

   procedure Clear (Model : in out Tasking_Contract_Predicate_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Tasking_Contract_Predicate_Context_Model;
      Info  : Tasking_Contract_Predicate_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Tasking_Contract_Predicate_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Tasking_Contract_Predicate_Context_Model;
      Index : Positive) return Tasking_Contract_Predicate_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Contract_Predicate_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Tasking_Contract_Predicate_Context_Model) return Tasking_Contract_Predicate_Model is
      Result : Tasking_Contract_Predicate_Model;
      Row    : Tasking_Contract_Predicate_Info;
      Status : Tasking_Contract_Predicate_Status;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Tasking_Contract_Predicate_Context_Info := Contexts.Contexts.Element (I);
         begin
            Status := Status_For (C);
            Row :=
              (Id => Tasking_Contract_Predicate_Row_Id (I),
               Context => C.Id,
               Kind => C.Kind,
               Status => Status,
               Node => C.Node,
               Task_Node => C.Task_Node,
               Protected_Node => C.Protected_Node,
               Entry_Node => C.Entry_Node,
               Select_Node => C.Select_Node,
               Object_Name => C.Object_Name,
               Entry_Name => C.Entry_Name,
               Caller_Name => C.Caller_Name,
               Callee_Name => C.Callee_Name,
               Message => Message_For (Status),
               Detail => To_Unbounded_String ("Pass1169 tasking/protected effect consumed elaboration contract predicate/dataflow legality"),
               Tasking_Row => C.Tasking_Row,
               Tasking_Status => C.Tasking_Status,
               Elaboration_Predicate_Row => C.Elaboration_Predicate_Row,
               Elaboration_Predicate_Status => C.Elaboration_Predicate_Status,
               Elaboration_Predicate_Matches => C.Elaboration_Predicate_Matches,
               Start_Line => C.Start_Line,
               Start_Column => C.Start_Column,
               End_Line => C.End_Line,
               End_Column => C.End_Column,
               Source_Fingerprint => C.Source_Fingerprint,
               Fingerprint => 0);
            Row.Fingerprint := Row_Fingerprint (Row);
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);

            if Is_Legal (Status) then
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               Result.Error_Total := Result.Error_Total + 1;
            end if;
            if Is_Initialization_Error (Status) then
               Result.Initialization_Error_Total := Result.Initialization_Error_Total + 1;
            end if;
            if Is_Predicate_Error (Status) then
               Result.Predicate_Error_Total := Result.Predicate_Error_Total + 1;
            end if;
            if Is_Dataflow_Error (Status) then
               Result.Dataflow_Error_Total := Result.Dataflow_Error_Total + 1;
            end if;
            if Status = Tasking_Contract_Predicate_Coverage_Blocker then
               Result.Coverage_Error_Total := Result.Coverage_Error_Total + 1;
            end if;
            if Status = Tasking_Contract_Predicate_Base_Tasking_Effect_Error then
               Result.Tasking_Error_Total := Result.Tasking_Error_Total + 1;
            end if;
            if Status in Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate |
                         Tasking_Contract_Predicate_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Tasking_Contract_Predicate_Model;
      Index : Positive) return Tasking_Contract_Predicate_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Tasking_Contract_Predicate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Contract_Predicate_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tasking_Contract_Predicate_Model;
      Status : Tasking_Contract_Predicate_Status) return Tasking_Contract_Predicate_Set is
      Result : Tasking_Contract_Predicate_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Tasking_Contract_Predicate_Model;
      Kind  : Tasking_Contract_Predicate_Context_Kind) return Tasking_Contract_Predicate_Set is
      Result : Tasking_Contract_Predicate_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Tasking_Contract_Predicate_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Tasking_Contract_Predicate_Set;
      Index : Positive) return Tasking_Contract_Predicate_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Tasking_Contract_Predicate_Model;
      Status : Tasking_Contract_Predicate_Status) return Natural is
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
     (Model : Tasking_Contract_Predicate_Model;
      Kind  : Tasking_Contract_Predicate_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Initialization_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Initialization_Error_Total;
   end Initialization_Error_Count;

   function Predicate_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Predicate_Error_Total;
   end Predicate_Error_Count;

   function Dataflow_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Dataflow_Error_Total;
   end Dataflow_Error_Count;

   function Coverage_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Tasking_Error_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Tasking_Error_Total;
   end Tasking_Error_Count;

   function Indeterminate_Count (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Tasking_Contract_Predicate_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
