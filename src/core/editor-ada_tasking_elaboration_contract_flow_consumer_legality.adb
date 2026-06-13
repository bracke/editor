with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality is

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

   function Is_Legal (Status : Tasking_Elab_Contract_Status) return Boolean is
   begin
      return Status in
        Tasking_Elab_Contract_Legal_Task_Activation_Accepted |
        Tasking_Elab_Contract_Legal_Task_Termination_Accepted |
        Tasking_Elab_Contract_Legal_Protected_Read_Accepted |
        Tasking_Elab_Contract_Legal_Protected_Write_Accepted |
        Tasking_Elab_Contract_Legal_Protected_Function_Call_Accepted |
        Tasking_Elab_Contract_Legal_Protected_Procedure_Call_Accepted |
        Tasking_Elab_Contract_Legal_Protected_Entry_Call_Accepted |
        Tasking_Elab_Contract_Legal_Entry_Queue_Accepted |
        Tasking_Elab_Contract_Legal_Entry_Barrier_Accepted |
        Tasking_Elab_Contract_Legal_Accept_Body_Accepted |
        Tasking_Elab_Contract_Legal_Requeue_Accepted |
        Tasking_Elab_Contract_Legal_Select_Guard_Accepted |
        Tasking_Elab_Contract_Legal_Select_Alternative_Accepted |
        Tasking_Elab_Contract_Legal_Abortable_Part_Accepted |
        Tasking_Elab_Contract_Legal_Delay_Alternative_Accepted |
        Tasking_Elab_Contract_Legal_Terminate_Alternative_Accepted;
   end Is_Legal;

   function Is_Global_Error (Status : Tasking_Elab_Contract_Status) return Boolean is
   begin
      return Status in
        Tasking_Elab_Contract_Refined_Global_Missing_Read |
        Tasking_Elab_Contract_Refined_Global_Missing_Write |
        Tasking_Elab_Contract_Refined_Global_Mode_Mismatch |
        Tasking_Elab_Contract_Refined_Global_Extra_Item;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Tasking_Elab_Contract_Status) return Boolean is
   begin
      return Status in
        Tasking_Elab_Contract_Refined_Depends_Missing_Edge |
        Tasking_Elab_Contract_Refined_Depends_Extra_Edge |
        Tasking_Elab_Contract_Refined_Depends_Source_Mode_Error |
        Tasking_Elab_Contract_Refined_Depends_Target_Mode_Error;
   end Is_Depends_Error;

   function Is_Propagation_Error (Status : Tasking_Elab_Contract_Status) return Boolean is
   begin
      return Status = Tasking_Elab_Contract_Call_Effect_Not_Propagated;
   end Is_Propagation_Error;

   function Legal_Status_For_Kind
     (Kind : Tasking_Elab_Contract_Context_Kind) return Tasking_Elab_Contract_Status is
   begin
      case Kind is
         when Tasking_Elab_Contract_Task_Activation =>
            return Tasking_Elab_Contract_Legal_Task_Activation_Accepted;
         when Tasking_Elab_Contract_Task_Termination =>
            return Tasking_Elab_Contract_Legal_Task_Termination_Accepted;
         when Tasking_Elab_Contract_Protected_Read =>
            return Tasking_Elab_Contract_Legal_Protected_Read_Accepted;
         when Tasking_Elab_Contract_Protected_Write =>
            return Tasking_Elab_Contract_Legal_Protected_Write_Accepted;
         when Tasking_Elab_Contract_Protected_Function_Call =>
            return Tasking_Elab_Contract_Legal_Protected_Function_Call_Accepted;
         when Tasking_Elab_Contract_Protected_Procedure_Call =>
            return Tasking_Elab_Contract_Legal_Protected_Procedure_Call_Accepted;
         when Tasking_Elab_Contract_Protected_Entry_Call =>
            return Tasking_Elab_Contract_Legal_Protected_Entry_Call_Accepted;
         when Tasking_Elab_Contract_Entry_Queue =>
            return Tasking_Elab_Contract_Legal_Entry_Queue_Accepted;
         when Tasking_Elab_Contract_Entry_Barrier =>
            return Tasking_Elab_Contract_Legal_Entry_Barrier_Accepted;
         when Tasking_Elab_Contract_Accept_Body =>
            return Tasking_Elab_Contract_Legal_Accept_Body_Accepted;
         when Tasking_Elab_Contract_Requeue =>
            return Tasking_Elab_Contract_Legal_Requeue_Accepted;
         when Tasking_Elab_Contract_Select_Guard =>
            return Tasking_Elab_Contract_Legal_Select_Guard_Accepted;
         when Tasking_Elab_Contract_Select_Alternative =>
            return Tasking_Elab_Contract_Legal_Select_Alternative_Accepted;
         when Tasking_Elab_Contract_Abortable_Part =>
            return Tasking_Elab_Contract_Legal_Abortable_Part_Accepted;
         when Tasking_Elab_Contract_Delay_Alternative =>
            return Tasking_Elab_Contract_Legal_Delay_Alternative_Accepted;
         when Tasking_Elab_Contract_Terminate_Alternative =>
            return Tasking_Elab_Contract_Legal_Terminate_Alternative_Accepted;
         when others =>
            return Tasking_Elab_Contract_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Elab_Contract
     (Status : Elab_Contract.Elaboration_Contract_Flow_Status) return Tasking_Elab_Contract_Status is
   begin
      case Status is
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Global_Missing_Read =>
            return Tasking_Elab_Contract_Refined_Global_Missing_Read;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Global_Missing_Write =>
            return Tasking_Elab_Contract_Refined_Global_Missing_Write;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Global_Mode_Mismatch =>
            return Tasking_Elab_Contract_Refined_Global_Mode_Mismatch;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Global_Extra_Item =>
            return Tasking_Elab_Contract_Refined_Global_Extra_Item;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Depends_Missing_Edge =>
            return Tasking_Elab_Contract_Refined_Depends_Missing_Edge;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Depends_Extra_Edge =>
            return Tasking_Elab_Contract_Refined_Depends_Extra_Edge;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Depends_Source_Mode_Error =>
            return Tasking_Elab_Contract_Refined_Depends_Source_Mode_Error;
         when Elab_Contract.Elaboration_Contract_Flow_Refined_Depends_Target_Mode_Error =>
            return Tasking_Elab_Contract_Refined_Depends_Target_Mode_Error;
         when Elab_Contract.Elaboration_Contract_Flow_Call_Effect_Not_Propagated =>
            return Tasking_Elab_Contract_Call_Effect_Not_Propagated;
         when Elab_Contract.Elaboration_Contract_Flow_Coverage_Feedback_Blocker =>
            return Tasking_Elab_Contract_Coverage_Feedback_Blocker;
         when Elab_Contract.Elaboration_Contract_Flow_Linked_Flow_Graph_Error =>
            return Tasking_Elab_Contract_Linked_Flow_Graph_Error;
         when Elab_Contract.Elaboration_Contract_Flow_Contract_Base_Error =>
            return Tasking_Elab_Contract_Base_Contract_Flow_Error;
         when Elab_Contract.Elaboration_Contract_Flow_Base_Elaboration_Error =>
            return Tasking_Elab_Contract_Base_Elaboration_Error;
         when Elab_Contract.Elaboration_Contract_Flow_Multiple_Contract_Flow_Blockers =>
            return Tasking_Elab_Contract_Multiple_Elaboration_Contract_Blockers;
         when Elab_Contract.Elaboration_Contract_Flow_Contract_Flow_Indeterminate |
              Elab_Contract.Elaboration_Contract_Flow_Indeterminate =>
            return Tasking_Elab_Contract_Elaboration_Contract_Indeterminate;
         when Elab_Contract.Elaboration_Contract_Flow_Missing_Contract_Flow_Row |
              Elab_Contract.Elaboration_Contract_Flow_Not_Checked =>
            return Tasking_Elab_Contract_Missing_Elaboration_Contract_Row;
         when others =>
            return Tasking_Elab_Contract_Indeterminate;
      end case;
   end Status_From_Elab_Contract;

   function Status_For (Info : Tasking_Elab_Contract_Context_Info) return Tasking_Elab_Contract_Status is
   begin
      if not Task_Effects.Is_Legal (Info.Tasking_Status) then
         if Info.Tasking_Status = Task_Effects.Tasking_Effect_Indeterminate then
            return Tasking_Elab_Contract_Indeterminate;
         else
            return Tasking_Elab_Contract_Base_Tasking_Effect_Error;
         end if;
      elsif Info.Elaboration_Contract_Matches > 1 then
         return Tasking_Elab_Contract_Multiple_Elaboration_Contract_Blockers;
      elsif Info.Elaboration_Contract_Row = Elab_Contract.No_Elaboration_Contract_Flow_Row then
         return Tasking_Elab_Contract_Missing_Elaboration_Contract_Row;
      elsif Elab_Contract.Is_Legal (Info.Elaboration_Contract_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Elab_Contract (Info.Elaboration_Contract_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Tasking_Elab_Contract_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Tasking_Elab_Contract_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Tasking_Elab_Contract_Status'Pos (Info.Status) + 1);
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
      H := Mix (H, Natural (Info.Elaboration_Contract_Row) + 1);
      H := Mix (H, Elab_Contract.Elaboration_Contract_Flow_Status'Pos (Info.Elaboration_Contract_Status) + 1);
      H := Mix (H, Info.Elaboration_Contract_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Tasking_Elab_Contract_Status) return Unbounded_String is
   begin
      case Status is
         when Tasking_Elab_Contract_Base_Tasking_Effect_Error =>
            return To_Unbounded_String ("base tasking/protected effect legality failed");
         when Tasking_Elab_Contract_Missing_Elaboration_Contract_Row =>
            return To_Unbounded_String ("tasking/protected effect is missing elaboration contract-flow evidence");
         when Tasking_Elab_Contract_Refined_Global_Missing_Read =>
            return To_Unbounded_String ("tasking/protected effect reads state missing from Refined_Global elaboration evidence");
         when Tasking_Elab_Contract_Refined_Global_Missing_Write =>
            return To_Unbounded_String ("tasking/protected effect writes state missing from Refined_Global elaboration evidence");
         when Tasking_Elab_Contract_Refined_Global_Mode_Mismatch =>
            return To_Unbounded_String ("tasking/protected effect has Refined_Global mode mismatch");
         when Tasking_Elab_Contract_Refined_Depends_Missing_Edge =>
            return To_Unbounded_String ("tasking/protected effect is missing Refined_Depends elaboration edge");
         when Tasking_Elab_Contract_Call_Effect_Not_Propagated =>
            return To_Unbounded_String ("tasking/protected call effect was not propagated through elaboration contract-flow");
         when Tasking_Elab_Contract_Coverage_Feedback_Blocker =>
            return To_Unbounded_String ("tasking/protected effect is blocked by repaired coverage feedback");
         when Tasking_Elab_Contract_Base_Elaboration_Error =>
            return To_Unbounded_String ("tasking/protected effect is blocked by elaboration graph legality");
         when Tasking_Elab_Contract_Multiple_Elaboration_Contract_Blockers =>
            return To_Unbounded_String ("tasking/protected effect has multiple matching elaboration contract-flow blockers");
         when Tasking_Elab_Contract_Elaboration_Contract_Indeterminate |
              Tasking_Elab_Contract_Indeterminate =>
            return To_Unbounded_String ("tasking/protected elaboration contract-flow result is indeterminate");
         when others =>
            return To_Unbounded_String ("tasking/protected elaboration contract-flow accepted");
      end case;
   end Message_For;

   procedure Clear (Model : in out Tasking_Elab_Contract_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Tasking_Elab_Contract_Context_Model;
      Info  : Tasking_Elab_Contract_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Tasking_Elab_Contract_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Tasking_Elab_Contract_Context_Model;
      Index : Positive) return Tasking_Elab_Contract_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Elab_Contract_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Tasking_Elab_Contract_Context_Model) return Tasking_Elab_Contract_Model is
      Result : Tasking_Elab_Contract_Model;
      Row    : Tasking_Elab_Contract_Info;
      Status : Tasking_Elab_Contract_Status;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Tasking_Elab_Contract_Context_Info := Contexts.Contexts.Element (I);
         begin
            Status := Status_For (C);
            Row :=
              (Id => Tasking_Elab_Contract_Row_Id (I),
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
               Detail => To_Unbounded_String ("Pass1158 tasking/protected effect consumed elaboration contract-flow legality"),
               Tasking_Row => C.Tasking_Row,
               Tasking_Status => C.Tasking_Status,
               Elaboration_Contract_Row => C.Elaboration_Contract_Row,
               Elaboration_Contract_Status => C.Elaboration_Contract_Status,
               Elaboration_Contract_Matches => C.Elaboration_Contract_Matches,
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
            if Is_Global_Error (Status) then
               Result.Global_Error_Total := Result.Global_Error_Total + 1;
            end if;
            if Is_Depends_Error (Status) then
               Result.Depends_Error_Total := Result.Depends_Error_Total + 1;
            end if;
            if Is_Propagation_Error (Status) then
               Result.Propagation_Error_Total := Result.Propagation_Error_Total + 1;
            end if;
            if Status = Tasking_Elab_Contract_Coverage_Feedback_Blocker then
               Result.Coverage_Error_Total := Result.Coverage_Error_Total + 1;
            end if;
            if Status = Tasking_Elab_Contract_Base_Tasking_Effect_Error then
               Result.Tasking_Error_Total := Result.Tasking_Error_Total + 1;
            end if;
            if Status in Tasking_Elab_Contract_Elaboration_Contract_Indeterminate |
                         Tasking_Elab_Contract_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Tasking_Elab_Contract_Model;
      Index : Positive) return Tasking_Elab_Contract_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Tasking_Elab_Contract_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Elab_Contract_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tasking_Elab_Contract_Model;
      Status : Tasking_Elab_Contract_Status) return Tasking_Elab_Contract_Set is
      Result : Tasking_Elab_Contract_Set;
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
     (Model : Tasking_Elab_Contract_Model;
      Kind  : Tasking_Elab_Contract_Context_Kind) return Tasking_Elab_Contract_Set is
      Result : Tasking_Elab_Contract_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Tasking_Elab_Contract_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Tasking_Elab_Contract_Set;
      Index : Positive) return Tasking_Elab_Contract_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Tasking_Elab_Contract_Model;
      Status : Tasking_Elab_Contract_Status) return Natural is
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
     (Model : Tasking_Elab_Contract_Model;
      Kind  : Tasking_Elab_Contract_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Global_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Propagation_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Propagation_Error_Total;
   end Propagation_Error_Count;

   function Coverage_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Tasking_Error_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Tasking_Error_Total;
   end Tasking_Error_Count;

   function Indeterminate_Count (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Tasking_Elab_Contract_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;
