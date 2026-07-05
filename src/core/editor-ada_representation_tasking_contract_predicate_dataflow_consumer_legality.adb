with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Freezing.Freezing_Propagation_Id;
   use type Freezing.Freezing_Propagation_Status;
   use type Tasking_CPD.Tasking_Contract_Predicate_Row_Id;

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

   function Is_Legal (Status : Representation_Tasking_CPD_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_CPD_Legal_Representation_Clause_Accepted |
        Representation_Tasking_CPD_Legal_Operational_Attribute_Accepted |
        Representation_Tasking_CPD_Legal_Stream_Attribute_Accepted |
        Representation_Tasking_CPD_Legal_Record_Layout_Accepted |
        Representation_Tasking_CPD_Legal_Generic_Instance_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Private_Full_View_Accepted |
        Representation_Tasking_CPD_Legal_Task_Activation_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Task_Termination_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Protected_Read_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Protected_Write_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Protected_Call_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Entry_Barrier_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Accept_Body_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Requeue_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Select_Effect_Accepted |
        Representation_Tasking_CPD_Legal_Abortable_Finalization_Effect_Accepted;
   end Is_Legal;

   function Is_Initialization_Error (Status : Representation_Tasking_CPD_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_CPD_Read_Before_Write_Blocker |
        Representation_Tasking_CPD_Component_Read_Before_Write_Blocker |
        Representation_Tasking_CPD_Partial_Initialization_Blocker |
        Representation_Tasking_CPD_Missing_Out_Assignment_Blocker |
        Representation_Tasking_CPD_Conditional_In_Out_Blocker |
        Representation_Tasking_CPD_Return_Object_Initialization_Blocker |
        Representation_Tasking_CPD_Branch_Loop_Merge_Blocker |
        Representation_Tasking_CPD_Exception_Finalization_Path_Blocker |
        Representation_Tasking_CPD_Use_After_Finalization_Blocker;
   end Is_Initialization_Error;

   function Is_Predicate_Error (Status : Representation_Tasking_CPD_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_CPD_Predicate_Propagation_Blocker |
        Representation_Tasking_CPD_Discriminant_Variant_Blocker |
        Representation_Tasking_CPD_Representation_Freezing_Blocker;
   end Is_Predicate_Error;

   function Is_Dataflow_Error (Status : Representation_Tasking_CPD_Status) return Boolean is
   begin
      return Status in
        Representation_Tasking_CPD_Global_Depends_Blocker |
        Representation_Tasking_CPD_Call_Propagation_Blocker |
        Representation_Tasking_CPD_Generic_Flow_Blocker |
        Representation_Tasking_CPD_Tasking_Protected_Flow_Blocker;
   end Is_Dataflow_Error;

   function Legal_Status_For_Kind
     (Kind : Representation_Tasking_CPD_Context_Kind) return Representation_Tasking_CPD_Status is
   begin
      case Kind is
         when Representation_Tasking_CPD_Representation_Clause =>
            return Representation_Tasking_CPD_Legal_Representation_Clause_Accepted;
         when Representation_Tasking_CPD_Operational_Attribute =>
            return Representation_Tasking_CPD_Legal_Operational_Attribute_Accepted;
         when Representation_Tasking_CPD_Stream_Attribute =>
            return Representation_Tasking_CPD_Legal_Stream_Attribute_Accepted;
         when Representation_Tasking_CPD_Record_Layout =>
            return Representation_Tasking_CPD_Legal_Record_Layout_Accepted;
         when Representation_Tasking_CPD_Generic_Instance_Effect =>
            return Representation_Tasking_CPD_Legal_Generic_Instance_Effect_Accepted;
         when Representation_Tasking_CPD_Private_Full_View =>
            return Representation_Tasking_CPD_Legal_Private_Full_View_Accepted;
         when Representation_Tasking_CPD_Task_Activation_Effect =>
            return Representation_Tasking_CPD_Legal_Task_Activation_Effect_Accepted;
         when Representation_Tasking_CPD_Task_Termination_Effect =>
            return Representation_Tasking_CPD_Legal_Task_Termination_Effect_Accepted;
         when Representation_Tasking_CPD_Protected_Read_Effect =>
            return Representation_Tasking_CPD_Legal_Protected_Read_Effect_Accepted;
         when Representation_Tasking_CPD_Protected_Write_Effect =>
            return Representation_Tasking_CPD_Legal_Protected_Write_Effect_Accepted;
         when Representation_Tasking_CPD_Protected_Call_Effect =>
            return Representation_Tasking_CPD_Legal_Protected_Call_Effect_Accepted;
         when Representation_Tasking_CPD_Entry_Barrier_Effect =>
            return Representation_Tasking_CPD_Legal_Entry_Barrier_Effect_Accepted;
         when Representation_Tasking_CPD_Accept_Body_Effect =>
            return Representation_Tasking_CPD_Legal_Accept_Body_Effect_Accepted;
         when Representation_Tasking_CPD_Requeue_Effect =>
            return Representation_Tasking_CPD_Legal_Requeue_Effect_Accepted;
         when Representation_Tasking_CPD_Select_Effect =>
            return Representation_Tasking_CPD_Legal_Select_Effect_Accepted;
         when Representation_Tasking_CPD_Abortable_Finalization_Effect =>
            return Representation_Tasking_CPD_Legal_Abortable_Finalization_Effect_Accepted;
         when others =>
            return Representation_Tasking_CPD_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Tasking_CPD
     (Status : Tasking_CPD.Tasking_Contract_Predicate_Status) return Representation_Tasking_CPD_Status is
   begin
      case Status is
         when Tasking_CPD.Tasking_Contract_Predicate_Missing_Elaboration_Predicate_Row =>
            return Representation_Tasking_CPD_Missing_Elaboration_Predicate_Row;
         when Tasking_CPD.Tasking_Contract_Predicate_Missing_Contract_Predicate_Row |
              Tasking_CPD.Tasking_Contract_Predicate_Not_Checked =>
            return Representation_Tasking_CPD_Missing_Contract_Predicate_Row;
         when Tasking_CPD.Tasking_Contract_Predicate_Base_Contract_Error =>
            return Representation_Tasking_CPD_Base_Contract_Error;
         when Tasking_CPD.Tasking_Contract_Predicate_Base_Elaboration_Error =>
            return Representation_Tasking_CPD_Base_Elaboration_Error;
         when Tasking_CPD.Tasking_Contract_Predicate_Base_Tasking_Effect_Error =>
            return Representation_Tasking_CPD_Base_Tasking_Effect_Error;
         when Tasking_CPD.Tasking_Contract_Predicate_Predicate_Propagation_Blocker =>
            return Representation_Tasking_CPD_Predicate_Propagation_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Read_Before_Write_Blocker =>
            return Representation_Tasking_CPD_Read_Before_Write_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Component_Read_Before_Write_Blocker =>
            return Representation_Tasking_CPD_Component_Read_Before_Write_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Partial_Initialization_Blocker =>
            return Representation_Tasking_CPD_Partial_Initialization_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Missing_Out_Assignment_Blocker =>
            return Representation_Tasking_CPD_Missing_Out_Assignment_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Conditional_In_Out_Blocker =>
            return Representation_Tasking_CPD_Conditional_In_Out_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Return_Object_Initialization_Blocker =>
            return Representation_Tasking_CPD_Return_Object_Initialization_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Branch_Loop_Merge_Blocker =>
            return Representation_Tasking_CPD_Branch_Loop_Merge_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Exception_Finalization_Path_Blocker =>
            return Representation_Tasking_CPD_Exception_Finalization_Path_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Use_After_Finalization_Blocker =>
            return Representation_Tasking_CPD_Use_After_Finalization_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Lifetime_Accessibility_Blocker =>
            return Representation_Tasking_CPD_Lifetime_Accessibility_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Discriminant_Variant_Blocker =>
            return Representation_Tasking_CPD_Discriminant_Variant_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Representation_Freezing_Blocker =>
            return Representation_Tasking_CPD_Representation_Freezing_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Global_Depends_Blocker =>
            return Representation_Tasking_CPD_Global_Depends_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Call_Propagation_Blocker =>
            return Representation_Tasking_CPD_Call_Propagation_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Generic_Flow_Blocker =>
            return Representation_Tasking_CPD_Generic_Flow_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Tasking_Protected_Flow_Blocker =>
            return Representation_Tasking_CPD_Tasking_Protected_Flow_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Coverage_Blocker =>
            return Representation_Tasking_CPD_Coverage_Blocker;
         when Tasking_CPD.Tasking_Contract_Predicate_Multiple_Matching_Blockers =>
            return Representation_Tasking_CPD_Multiple_Tasking_CPD_Blockers;
         when Tasking_CPD.Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate |
              Tasking_CPD.Tasking_Contract_Predicate_Indeterminate =>
            return Representation_Tasking_CPD_Tasking_CPD_Indeterminate;
         when others =>
            if Tasking_CPD.Is_Legal (Status) then
               return Representation_Tasking_CPD_Not_Checked;
            else
               return Representation_Tasking_CPD_Indeterminate;
            end if;
      end case;
   end Status_From_Tasking_CPD;

   function Status_For (Info : Representation_Tasking_CPD_Context_Info) return Representation_Tasking_CPD_Status is
   begin
      if not Freezing.Is_Legal (Info.Freezing_Status) then
         if Info.Freezing_Status = Freezing.Freezing_Propagation_Indeterminate then
            return Representation_Tasking_CPD_Indeterminate;
         else
            return Representation_Tasking_CPD_Base_Freezing_Error;
         end if;
      elsif Info.Tasking_CPD_Matches > 1 then
         return Representation_Tasking_CPD_Multiple_Tasking_CPD_Blockers;
      elsif Info.Tasking_CPD_Row = Tasking_CPD.No_Tasking_Contract_Predicate_Row then
         return Representation_Tasking_CPD_Missing_Tasking_CPD_Row;
      elsif Tasking_CPD.Is_Legal (Info.Tasking_CPD_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Tasking_CPD (Info.Tasking_CPD_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Representation_Tasking_CPD_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Representation_Tasking_CPD_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Representation_Tasking_CPD_Status'Pos (Info.Status) + 1);
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
      H := Mix (H, Natural (Info.Tasking_CPD_Row) + 1);
      H := Mix (H, Tasking_CPD.Tasking_Contract_Predicate_Status'Pos (Info.Tasking_CPD_Status) + 1);
      H := Mix (H, Info.Tasking_CPD_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Representation_Tasking_CPD_Status) return Unbounded_String is
   begin
      case Status is
         when Representation_Tasking_CPD_Base_Freezing_Error =>
            return To_Unbounded_String ("base representation/freezing propagation legality failed");
         when Representation_Tasking_CPD_Missing_Tasking_CPD_Row =>
            return To_Unbounded_String
              ("representation/freezing item is missing tasking CPD evidence");
         when Representation_Tasking_CPD_Missing_Elaboration_Predicate_Row |
              Representation_Tasking_CPD_Missing_Contract_Predicate_Row =>
            return To_Unbounded_String
              ("representation/freezing item is missing elaboration CPD evidence");
         when Representation_Tasking_CPD_Base_Contract_Error =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking contract legality");
         when Representation_Tasking_CPD_Base_Elaboration_Error =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking elaboration legality");
         when Representation_Tasking_CPD_Base_Tasking_Effect_Error =>
            return To_Unbounded_String ("representation/freezing item is blocked by tasking/protected effect legality");
         when Representation_Tasking_CPD_Predicate_Propagation_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking predicate evidence");
         when Representation_Tasking_CPD_Read_Before_Write_Blocker |
              Representation_Tasking_CPD_Component_Read_Before_Write_Blocker |
              Representation_Tasking_CPD_Partial_Initialization_Blocker |
              Representation_Tasking_CPD_Missing_Out_Assignment_Blocker |
              Representation_Tasking_CPD_Conditional_In_Out_Blocker |
              Representation_Tasking_CPD_Return_Object_Initialization_Blocker |
              Representation_Tasking_CPD_Branch_Loop_Merge_Blocker |
              Representation_Tasking_CPD_Exception_Finalization_Path_Blocker |
              Representation_Tasking_CPD_Use_After_Finalization_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking object state");
         when Representation_Tasking_CPD_Lifetime_Accessibility_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking lifetime evidence");
         when Representation_Tasking_CPD_Discriminant_Variant_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking discriminants");
         when Representation_Tasking_CPD_Representation_Freezing_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by nested representation evidence");
         when Representation_Tasking_CPD_Global_Depends_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking flow evidence");
         when Representation_Tasking_CPD_Call_Propagation_Blocker =>
            return To_Unbounded_String ("representation/freezing item is blocked by unpropagated tasking call effects");
         when Representation_Tasking_CPD_Generic_Flow_Blocker =>
            return To_Unbounded_String ("representation/freezing item is blocked by tasking generic-flow evidence");
         when Representation_Tasking_CPD_Tasking_Protected_Flow_Blocker =>
            return To_Unbounded_String ("representation/freezing item is blocked by tasking/protected flow evidence");
         when Representation_Tasking_CPD_Coverage_Blocker =>
            return To_Unbounded_String
              ("representation/freezing item is blocked by tasking coverage feedback");
         when Representation_Tasking_CPD_Multiple_Tasking_CPD_Blockers =>
            return To_Unbounded_String
              ("representation/freezing item has multiple matching tasking blockers");
         when Representation_Tasking_CPD_Tasking_CPD_Indeterminate |
              Representation_Tasking_CPD_Indeterminate =>
            return To_Unbounded_String
              ("representation/freezing tasking CPD result is indeterminate");
         when others =>
            return To_Unbounded_String ("representation/freezing tasking contract predicate/dataflow accepted");
      end case;
   end Message_For;

   procedure Clear (Model : in out Representation_Tasking_CPD_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Representation_Tasking_CPD_Context_Model;
      Info  : Representation_Tasking_CPD_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Representation_Tasking_CPD_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Representation_Tasking_CPD_Context_Model;
      Index : Positive) return Representation_Tasking_CPD_Context_Info is
   begin
      if Index > Natural (Model.Contexts.Length) then
         return (others => <>);
      end if;
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Representation_Tasking_CPD_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Representation_Tasking_CPD_Context_Model) return Representation_Tasking_CPD_Model is
      Result : Representation_Tasking_CPD_Model;
      Row    : Representation_Tasking_CPD_Info;
      Status : Representation_Tasking_CPD_Status;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Representation_Tasking_CPD_Context_Info := Contexts.Contexts.Element (I);
         begin
            Status := Status_For (C);
            Row :=
              (Id => Representation_Tasking_CPD_Row_Id (I),
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
               Detail => To_Unbounded_String
                 ("Case 1170 representation/freezing consumed tasking CPD legality"),
               Freezing_Row => C.Freezing_Row,
               Freezing_Status => C.Freezing_Status,
               Tasking_CPD_Row => C.Tasking_CPD_Row,
               Tasking_CPD_Status => C.Tasking_CPD_Status,
               Tasking_CPD_Matches => C.Tasking_CPD_Matches,
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
            if Status = Representation_Tasking_CPD_Base_Freezing_Error then
               Result.Freezing_Error_Total := Result.Freezing_Error_Total + 1;
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
            if Status = Representation_Tasking_CPD_Coverage_Blocker then
               Result.Coverage_Error_Total := Result.Coverage_Error_Total + 1;
            end if;
            if Status = Representation_Tasking_CPD_Base_Tasking_Effect_Error then
               Result.Tasking_Error_Total := Result.Tasking_Error_Total + 1;
            end if;
            if Status in Representation_Tasking_CPD_Tasking_CPD_Indeterminate |
                         Representation_Tasking_CPD_Indeterminate then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Representation_Tasking_CPD_Model;
      Index : Positive) return Representation_Tasking_CPD_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Representation_Tasking_CPD_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Tasking_CPD_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Representation_Tasking_CPD_Model;
      Status : Representation_Tasking_CPD_Status) return Representation_Tasking_CPD_Set is
      Result : Representation_Tasking_CPD_Set;
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
     (Model : Representation_Tasking_CPD_Model;
      Kind  : Representation_Tasking_CPD_Context_Kind) return Representation_Tasking_CPD_Set is
      Result : Representation_Tasking_CPD_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Set_Count (Set : Representation_Tasking_CPD_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Representation_Tasking_CPD_Set;
      Index : Positive) return Representation_Tasking_CPD_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Representation_Tasking_CPD_Model;
      Status : Representation_Tasking_CPD_Status) return Natural is
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
     (Model : Representation_Tasking_CPD_Model;
      Kind  : Representation_Tasking_CPD_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Freezing_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Freezing_Error_Total;
   end Freezing_Error_Count;

   function Initialization_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Initialization_Error_Total;
   end Initialization_Error_Count;

   function Predicate_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Predicate_Error_Total;
   end Predicate_Error_Count;

   function Dataflow_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Dataflow_Error_Total;
   end Dataflow_Error_Count;

   function Coverage_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Tasking_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Tasking_Error_Total;
   end Tasking_Error_Count;

   function Indeterminate_Count (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Representation_Tasking_CPD_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
