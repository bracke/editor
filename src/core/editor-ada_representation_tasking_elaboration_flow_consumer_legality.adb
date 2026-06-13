with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality is
   use type Freezing.Freezing_Propagation_Status;
   use type Tasking_Flow.Tasking_Elab_Contract_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (A) * 16_777_619 +
         Long_Long_Integer (B) +
         2_166_136_261) mod 2_147_483_647;
   begin
      return Natural (Hash);
   end Mix;

   function Text_Hash (Text : Unbounded_String) return Natural is
      S : constant String := To_String (Text);
      H : Natural := 0;
   begin
      for Ch of S loop
         H := Mix (H, Character'Pos (Ch) + 1);
      end loop;
      return H;
   end Text_Hash;

   function Is_Legal (Status : Representation_Tasking_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_Legal_Representation_Clause_Accepted ..
        Representation_Tasking_Legal_Abortable_Finalization_Effect_Accepted;
   end Is_Legal;

   function Is_Global_Error (Status : Representation_Tasking_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_Refined_Global_Missing_Read |
        Representation_Tasking_Refined_Global_Missing_Write |
        Representation_Tasking_Refined_Global_Mode_Mismatch |
        Representation_Tasking_Refined_Global_Extra_Item;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Representation_Tasking_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_Refined_Depends_Missing_Edge |
        Representation_Tasking_Refined_Depends_Extra_Edge |
        Representation_Tasking_Refined_Depends_Source_Mode_Error |
        Representation_Tasking_Refined_Depends_Target_Mode_Error;
   end Is_Depends_Error;

   function Is_Propagation_Error (Status : Representation_Tasking_Status) return Boolean is
   begin
      return Status = Representation_Tasking_Call_Effect_Not_Propagated;
   end Is_Propagation_Error;

   function Legal_Status_For_Kind
     (Kind : Representation_Tasking_Context_Kind) return Representation_Tasking_Status is
   begin
      case Kind is
         when Representation_Tasking_Representation_Clause =>
            return Representation_Tasking_Legal_Representation_Clause_Accepted;
         when Representation_Tasking_Operational_Attribute =>
            return Representation_Tasking_Legal_Operational_Attribute_Accepted;
         when Representation_Tasking_Stream_Attribute =>
            return Representation_Tasking_Legal_Stream_Attribute_Accepted;
         when Representation_Tasking_Record_Layout =>
            return Representation_Tasking_Legal_Record_Layout_Accepted;
         when Representation_Tasking_Generic_Instance_Effect =>
            return Representation_Tasking_Legal_Generic_Instance_Effect_Accepted;
         when Representation_Tasking_Private_Full_View =>
            return Representation_Tasking_Legal_Private_Full_View_Accepted;
         when Representation_Tasking_Task_Activation_Effect =>
            return Representation_Tasking_Legal_Task_Activation_Effect_Accepted;
         when Representation_Tasking_Task_Termination_Effect =>
            return Representation_Tasking_Legal_Task_Termination_Effect_Accepted;
         when Representation_Tasking_Protected_Read_Effect =>
            return Representation_Tasking_Legal_Protected_Read_Effect_Accepted;
         when Representation_Tasking_Protected_Write_Effect =>
            return Representation_Tasking_Legal_Protected_Write_Effect_Accepted;
         when Representation_Tasking_Protected_Call_Effect =>
            return Representation_Tasking_Legal_Protected_Call_Effect_Accepted;
         when Representation_Tasking_Entry_Barrier_Effect =>
            return Representation_Tasking_Legal_Entry_Barrier_Effect_Accepted;
         when Representation_Tasking_Accept_Body_Effect =>
            return Representation_Tasking_Legal_Accept_Body_Effect_Accepted;
         when Representation_Tasking_Requeue_Effect =>
            return Representation_Tasking_Legal_Requeue_Effect_Accepted;
         when Representation_Tasking_Select_Effect =>
            return Representation_Tasking_Legal_Select_Effect_Accepted;
         when Representation_Tasking_Abortable_Finalization_Effect =>
            return Representation_Tasking_Legal_Abortable_Finalization_Effect_Accepted;
         when others =>
            return Representation_Tasking_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Tasking_Flow
     (Status : Tasking_Flow.Tasking_Elab_Contract_Status) return Representation_Tasking_Status is
   begin
      case Status is
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Global_Missing_Read =>
            return Representation_Tasking_Refined_Global_Missing_Read;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Global_Missing_Write =>
            return Representation_Tasking_Refined_Global_Missing_Write;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Global_Mode_Mismatch =>
            return Representation_Tasking_Refined_Global_Mode_Mismatch;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Global_Extra_Item =>
            return Representation_Tasking_Refined_Global_Extra_Item;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Depends_Missing_Edge =>
            return Representation_Tasking_Refined_Depends_Missing_Edge;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Depends_Extra_Edge =>
            return Representation_Tasking_Refined_Depends_Extra_Edge;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Depends_Source_Mode_Error =>
            return Representation_Tasking_Refined_Depends_Source_Mode_Error;
         when Tasking_Flow.Tasking_Elab_Contract_Refined_Depends_Target_Mode_Error =>
            return Representation_Tasking_Refined_Depends_Target_Mode_Error;
         when Tasking_Flow.Tasking_Elab_Contract_Call_Effect_Not_Propagated =>
            return Representation_Tasking_Call_Effect_Not_Propagated;
         when Tasking_Flow.Tasking_Elab_Contract_Coverage_Feedback_Blocker =>
            return Representation_Tasking_Coverage_Feedback_Blocker;
         when Tasking_Flow.Tasking_Elab_Contract_Linked_Flow_Graph_Error =>
            return Representation_Tasking_Linked_Flow_Graph_Error;
         when Tasking_Flow.Tasking_Elab_Contract_Base_Contract_Flow_Error =>
            return Representation_Tasking_Base_Contract_Flow_Error;
         when Tasking_Flow.Tasking_Elab_Contract_Base_Elaboration_Error =>
            return Representation_Tasking_Base_Elaboration_Error;
         when Tasking_Flow.Tasking_Elab_Contract_Base_Tasking_Effect_Error =>
            return Representation_Tasking_Base_Tasking_Effect_Error;
         when Tasking_Flow.Tasking_Elab_Contract_Multiple_Elaboration_Contract_Blockers =>
            return Representation_Tasking_Multiple_Tasking_Flow_Blockers;
         when Tasking_Flow.Tasking_Elab_Contract_Elaboration_Contract_Indeterminate |
              Tasking_Flow.Tasking_Elab_Contract_Indeterminate =>
            return Representation_Tasking_Tasking_Flow_Indeterminate;
         when Tasking_Flow.Tasking_Elab_Contract_Missing_Elaboration_Contract_Row |
              Tasking_Flow.Tasking_Elab_Contract_Not_Checked =>
            return Representation_Tasking_Missing_Tasking_Flow_Row;
         when others =>
            return Representation_Tasking_Indeterminate;
      end case;
   end Status_From_Tasking_Flow;

   function Status_For (Info : Representation_Tasking_Context_Info) return Representation_Tasking_Status is
   begin
      if not Freezing.Is_Legal (Info.Freezing_Status) then
         if Info.Freezing_Status = Freezing.Freezing_Propagation_Indeterminate then
            return Representation_Tasking_Indeterminate;
         else
            return Representation_Tasking_Base_Freezing_Error;
         end if;
      elsif Info.Tasking_Flow_Matches > 1 then
         return Representation_Tasking_Multiple_Tasking_Flow_Blockers;
      elsif Info.Tasking_Flow_Row = Tasking_Flow.No_Tasking_Elab_Contract_Row then
         return Representation_Tasking_Missing_Tasking_Flow_Row;
      elsif Tasking_Flow.Is_Legal (Info.Tasking_Flow_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Tasking_Flow (Info.Tasking_Flow_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Representation_Tasking_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Representation_Tasking_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Representation_Tasking_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Natural (Info.Representation_Node) + 1);
      H := Mix (H, Natural (Info.Task_Node) + 1);
      H := Mix (H, Natural (Info.Protected_Node) + 1);
      H := Mix (H, Natural (Info.Entry_Node) + 1);
      H := Mix (H, Natural (Info.Select_Node) + 1);
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Text_Hash (Info.Unit_Name));
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Entry_Name));
      H := Mix (H, Natural (Info.Freezing_Row) + 1);
      H := Mix (H, Freezing.Freezing_Propagation_Status'Pos (Info.Freezing_Status) + 1);
      H := Mix (H, Natural (Info.Tasking_Flow_Row) + 1);
      H := Mix (H, Tasking_Flow.Tasking_Elab_Contract_Status'Pos (Info.Tasking_Flow_Status) + 1);
      H := Mix (H, Info.Tasking_Flow_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Representation_Tasking_Status) return Unbounded_String is
   begin
      case Status is
         when Representation_Tasking_Base_Freezing_Error =>
            return To_Unbounded_String ("base representation/freezing propagation legality failed");
         when Representation_Tasking_Missing_Tasking_Flow_Row =>
            return To_Unbounded_String ("representation/freezing item is missing tasking elaboration contract-flow evidence");
         when Representation_Tasking_Refined_Global_Missing_Read =>
            return To_Unbounded_String ("representation/freezing item depends on tasking read missing from Refined_Global");
         when Representation_Tasking_Refined_Global_Missing_Write =>
            return To_Unbounded_String ("representation/freezing item depends on tasking write missing from Refined_Global");
         when Representation_Tasking_Refined_Global_Mode_Mismatch =>
            return To_Unbounded_String ("representation/freezing item has tasking Refined_Global mode mismatch");
         when Representation_Tasking_Refined_Depends_Missing_Edge =>
            return To_Unbounded_String ("representation/freezing item is missing tasking Refined_Depends edge");
         when Representation_Tasking_Call_Effect_Not_Propagated =>
            return To_Unbounded_String ("representation/freezing item has unpropagated tasking call effect");
         when Representation_Tasking_Coverage_Feedback_Blocker =>
            return To_Unbounded_String ("representation/freezing item is blocked by repaired coverage feedback through tasking");
         when Representation_Tasking_Base_Elaboration_Error =>
            return To_Unbounded_String ("representation/freezing item is blocked by tasking elaboration legality");
         when Representation_Tasking_Base_Tasking_Effect_Error =>
            return To_Unbounded_String ("representation/freezing item is blocked by tasking/protected effect legality");
         when Representation_Tasking_Multiple_Tasking_Flow_Blockers =>
            return To_Unbounded_String ("representation/freezing item has multiple matching tasking elaboration-flow blockers");
         when Representation_Tasking_Tasking_Flow_Indeterminate |
              Representation_Tasking_Indeterminate =>
            return To_Unbounded_String ("representation/freezing tasking elaboration-flow result is indeterminate");
         when others =>
            return To_Unbounded_String ("representation/freezing tasking elaboration-flow accepted");
      end case;
   end Message_For;

   procedure Clear (Model : in out Representation_Tasking_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Representation_Tasking_Context_Model;
      Info  : Representation_Tasking_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Representation_Tasking_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Representation_Tasking_Context_Model;
      Index : Positive) return Representation_Tasking_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Representation_Tasking_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Representation_Tasking_Context_Model) return Representation_Tasking_Model is
      Result : Representation_Tasking_Model;
      Row    : Representation_Tasking_Info;
      Status : Representation_Tasking_Status;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Representation_Tasking_Context_Info := Contexts.Contexts.Element (I);
         begin
            Status := Status_For (C);
            Row :=
              (Id => Representation_Tasking_Row_Id (I),
               Context => C.Id,
               Kind => C.Kind,
               Status => Status,
               Node => C.Node,
               Target_Node => C.Target_Node,
               Representation_Node => C.Representation_Node,
               Task_Node => C.Task_Node,
               Protected_Node => C.Protected_Node,
               Entry_Node => C.Entry_Node,
               Select_Node => C.Select_Node,
               Target_Name => C.Target_Name,
               Unit_Name => C.Unit_Name,
               Object_Name => C.Object_Name,
               Entry_Name => C.Entry_Name,
               Message => Message_For (Status),
               Detail => To_Unbounded_String ("Pass1159 representation/freezing consumed tasking elaboration contract-flow legality"),
               Freezing_Row => C.Freezing_Row,
               Freezing_Status => C.Freezing_Status,
               Tasking_Flow_Row => C.Tasking_Flow_Row,
               Tasking_Flow_Status => C.Tasking_Flow_Status,
               Tasking_Flow_Matches => C.Tasking_Flow_Matches,
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
            if Status = Representation_Tasking_Base_Freezing_Error then
               Result.Freezing_Error_Total := Result.Freezing_Error_Total + 1;
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
            if Status = Representation_Tasking_Coverage_Feedback_Blocker then
               Result.Coverage_Error_Total := Result.Coverage_Error_Total + 1;
            end if;
            if Status = Representation_Tasking_Base_Elaboration_Error then
               Result.Elaboration_Error_Total := Result.Elaboration_Error_Total + 1;
            end if;
            if Status = Representation_Tasking_Base_Tasking_Effect_Error then
               Result.Tasking_Error_Total := Result.Tasking_Error_Total + 1;
            end if;
            if Status in Representation_Tasking_Tasking_Flow_Indeterminate |
                         Representation_Tasking_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Representation_Tasking_Model;
      Index : Positive) return Representation_Tasking_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Representation_Tasking_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Tasking_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Representation_Tasking_Model;
      Status : Representation_Tasking_Status) return Representation_Tasking_Set is
      Result : Representation_Tasking_Set;
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
     (Model : Representation_Tasking_Model;
      Kind  : Representation_Tasking_Context_Kind) return Representation_Tasking_Set is
      Result : Representation_Tasking_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Representation_Tasking_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Representation_Tasking_Set;
      Index : Positive) return Representation_Tasking_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Representation_Tasking_Model;
      Status : Representation_Tasking_Status) return Natural is
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
     (Model : Representation_Tasking_Model;
      Kind  : Representation_Tasking_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Freezing_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Freezing_Error_Total;
   end Freezing_Error_Count;

   function Global_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Propagation_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Propagation_Error_Total;
   end Propagation_Error_Count;

   function Coverage_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Elaboration_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Elaboration_Error_Total;
   end Elaboration_Error_Count;

   function Tasking_Error_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Tasking_Error_Total;
   end Tasking_Error_Count;

   function Indeterminate_Count (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Representation_Tasking_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;
