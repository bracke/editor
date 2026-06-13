with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Contract_Flow_Refinement_Consumer_Legality is

   use type Contracts.Contract_Legality_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Flow_Consumers.Consumer_Row_Id;

   Modulus : constant Natural := 2_147_483_647;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 16_777_619 + B + 97) mod Modulus;
   end Mix;

   function Text_Hash (S : Unbounded_String) return Natural is
      H : Natural := 2_166_136_261 mod Modulus;
      T : constant String := To_String (S);
   begin
      for C of T loop
         H := Mix (H, Character'Pos (C) + 1);
      end loop;
      return H;
   end Text_Hash;

   function Is_Legal (Status : Contract_Flow_Status) return Boolean is
   begin
      return Status in
        Contract_Flow_Legal_Global_Aspect_Accepted |
        Contract_Flow_Legal_Depends_Aspect_Accepted |
        Contract_Flow_Legal_Refined_Global_Accepted |
        Contract_Flow_Legal_Refined_Depends_Accepted |
        Contract_Flow_Legal_Call_Propagation_Accepted |
        Contract_Flow_Legal_Generic_Effect_Accepted |
        Contract_Flow_Legal_Task_Protected_Effect_Accepted;
   end Is_Legal;

   function Is_Global_Error (Status : Contract_Flow_Status) return Boolean is
   begin
      return Status in
        Contract_Flow_Refined_Global_Missing_Read |
        Contract_Flow_Refined_Global_Missing_Write |
        Contract_Flow_Refined_Global_Mode_Mismatch |
        Contract_Flow_Refined_Global_Extra_Item;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Contract_Flow_Status) return Boolean is
   begin
      return Status in
        Contract_Flow_Refined_Depends_Missing_Edge |
        Contract_Flow_Refined_Depends_Extra_Edge |
        Contract_Flow_Refined_Depends_Source_Mode_Error |
        Contract_Flow_Refined_Depends_Target_Mode_Error;
   end Is_Depends_Error;

   function Is_Propagation_Error (Status : Contract_Flow_Status) return Boolean is
   begin
      return Status = Contract_Flow_Call_Effect_Not_Propagated;
   end Is_Propagation_Error;

   function Context_Kind_From_Contract
     (Kind : Contracts.Contract_Context_Kind) return Contract_Flow_Context_Kind is
   begin
      case Kind is
         when Contracts.Contract_Context_Global_Aspect =>
            return Contract_Flow_Global;
         when Contracts.Contract_Context_Depends_Aspect =>
            return Contract_Flow_Depends;
         when Contracts.Contract_Context_Refined_Global =>
            return Contract_Flow_Refined_Global;
         when Contracts.Contract_Context_Refined_Depends =>
            return Contract_Flow_Refined_Depends;
         when Contracts.Contract_Context_Generic_Formal_Contract =>
            return Contract_Flow_Generic_Instance;
         when others =>
            return Contract_Flow_Unknown;
      end case;
   end Context_Kind_From_Contract;

   function Contract_Is_Legal (Status : Contracts.Contract_Legality_Status) return Boolean is
   begin
      return Status in
        Contracts.Contract_Legality_Legal_Precondition |
        Contracts.Contract_Legality_Legal_Postcondition |
        Contracts.Contract_Legality_Legal_Invariant |
        Contracts.Contract_Legality_Legal_Predicate |
        Contracts.Contract_Legality_Legal_Assertion |
        Contracts.Contract_Legality_Legal_Contract_Case |
        Contracts.Contract_Legality_Legal_Flow_Aspect;
   end Contract_Is_Legal;

   function Status_For (Info : Contract_Flow_Context_Info) return Contract_Flow_Status is
   begin
      if not Contract_Is_Legal (Info.Contract_Status) then
         if Info.Contract_Status = Contracts.Contract_Legality_Indeterminate then
            return Contract_Flow_Indeterminate;
         else
            return Contract_Flow_Base_Contract_Error;
         end if;
      elsif Info.Consumer_Matches > 1 then
         return Contract_Flow_Multiple_Consumer_Blockers;
      elsif Info.Consumer_Row = Flow_Consumers.No_Consumer_Row then
         return Contract_Flow_Missing_Consumer_Row;
      end if;

      case Info.Consumer_Status is
         when Flow_Consumers.Consumer_Legal_Flow_Edge_Accepted =>
            case Info.Kind is
               when Contract_Flow_Refined_Global =>
                  return Contract_Flow_Legal_Refined_Global_Accepted;
               when Contract_Flow_Global =>
                  return Contract_Flow_Legal_Global_Aspect_Accepted;
               when others =>
                  return Contract_Flow_Legal_Global_Aspect_Accepted;
            end case;
         when Flow_Consumers.Consumer_Legal_Depends_Edge_Accepted =>
            if Info.Kind = Contract_Flow_Refined_Depends then
               return Contract_Flow_Legal_Refined_Depends_Accepted;
            else
               return Contract_Flow_Legal_Depends_Aspect_Accepted;
            end if;
         when Flow_Consumers.Consumer_Legal_Call_Propagation_Accepted =>
            return Contract_Flow_Legal_Call_Propagation_Accepted;
         when Flow_Consumers.Consumer_Legal_Generic_Effect_Accepted =>
            return Contract_Flow_Legal_Generic_Effect_Accepted;
         when Flow_Consumers.Consumer_Legal_Task_Protected_Effect_Accepted =>
            return Contract_Flow_Legal_Task_Protected_Effect_Accepted;
         when Flow_Consumers.Consumer_Refined_Global_Missing_Read =>
            return Contract_Flow_Refined_Global_Missing_Read;
         when Flow_Consumers.Consumer_Refined_Global_Missing_Write =>
            return Contract_Flow_Refined_Global_Missing_Write;
         when Flow_Consumers.Consumer_Refined_Global_Mode_Mismatch =>
            return Contract_Flow_Refined_Global_Mode_Mismatch;
         when Flow_Consumers.Consumer_Refined_Global_Extra_Item =>
            return Contract_Flow_Refined_Global_Extra_Item;
         when Flow_Consumers.Consumer_Refined_Depends_Missing_Edge =>
            return Contract_Flow_Refined_Depends_Missing_Edge;
         when Flow_Consumers.Consumer_Refined_Depends_Extra_Edge =>
            return Contract_Flow_Refined_Depends_Extra_Edge;
         when Flow_Consumers.Consumer_Refined_Depends_Source_Mode_Error =>
            return Contract_Flow_Refined_Depends_Source_Mode_Error;
         when Flow_Consumers.Consumer_Refined_Depends_Target_Mode_Error =>
            return Contract_Flow_Refined_Depends_Target_Mode_Error;
         when Flow_Consumers.Consumer_Call_Effect_Not_Propagated =>
            return Contract_Flow_Call_Effect_Not_Propagated;
         when Flow_Consumers.Consumer_Coverage_Feedback_Blocker =>
            return Contract_Flow_Coverage_Feedback_Blocker;
         when Flow_Consumers.Consumer_Flow_Graph_Error |
              Flow_Consumers.Consumer_Refinement_Linked_Flow_Error =>
            return Contract_Flow_Linked_Flow_Graph_Error;
         when Flow_Consumers.Consumer_Refinement_Indeterminate |
              Flow_Consumers.Consumer_Indeterminate =>
            return Contract_Flow_Consumer_Indeterminate;
         when Flow_Consumers.Consumer_Multiple_Refinement_Blockers =>
            return Contract_Flow_Multiple_Consumer_Blockers;
         when Flow_Consumers.Consumer_Missing_Refinement_Row |
              Flow_Consumers.Consumer_Not_Checked =>
            return Contract_Flow_Missing_Consumer_Row;
         when others =>
            return Contract_Flow_Indeterminate;
      end case;
   end Status_For;

   function Row_Fingerprint (Info : Contract_Flow_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Contract_Flow_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Contract_Flow_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Text_Hash (Info.Caller_Name));
      H := Mix (H, Text_Hash (Info.Callee_Name));
      H := Mix (H, Natural (Info.Contract_Row) + 1);
      H := Mix (H, Contracts.Contract_Legality_Status'Pos (Info.Contract_Status) + 1);
      H := Mix (H, Flow_Consumers.Consumer_Status'Pos (Info.Consumer_Status) + 1);
      H := Mix (H, Natural (Info.Consumer_Row) + 1);
      H := Mix (H, Info.Consumer_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Matches
     (C : Flow_Consumers.Consumer_Info;
      R : Contracts.Contract_Legality_Info) return Boolean is
   begin
      if C.Node /= Editor.Ada_Syntax_Tree.No_Node and then C.Node = R.Node then
         return True;
      elsif Length (C.Object_Name) > 0 and then C.Object_Name = R.Message then
         return False;
      elsif C.Node = R.Subject_Node and then C.Node /= Editor.Ada_Syntax_Tree.No_Node then
         return True;
      else
         return False;
      end if;
   end Matches;

   function Best_Consumer
     (Row       : Contracts.Contract_Legality_Info;
      Consumers : Flow_Consumers.Consumer_Model;
      Count     : out Natural) return Flow_Consumers.Consumer_Info is
      Best : Flow_Consumers.Consumer_Info;
   begin
      Count := 0;
      for I in 1 .. Flow_Consumers.Row_Count (Consumers) loop
         declare
            C : constant Flow_Consumers.Consumer_Info := Flow_Consumers.Row_At (Consumers, I);
         begin
            if Matches (C, Row) then
               Count := Count + 1;
               if Count = 1 or else
                 (not Flow_Consumers.Is_Legal (C.Status) and then Flow_Consumers.Is_Legal (Best.Status))
               then
                  Best := C;
               end if;
            end if;
         end;
      end loop;
      return Best;
   end Best_Consumer;

   procedure Clear (Model : in out Contract_Flow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Contract_Flow_Context_Model; Info : Contract_Flow_Context_Info) is
      H : Natural := Model.Result_Fingerprint;
   begin
      Model.Contexts.Append (Info);
      H := Mix (H, Natural (Info.Id) + 1);
      H := Mix (H, Contract_Flow_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Contracts.Contract_Legality_Status'Pos (Info.Contract_Status) + 1);
      H := Mix (H, Flow_Consumers.Consumer_Status'Pos (Info.Consumer_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      Model.Result_Fingerprint := H;
   end Add_Context;

   procedure Add_From_Contract_Row
     (Model     : in out Contract_Flow_Context_Model;
      Row       : Contracts.Contract_Legality_Info;
      Consumers : Flow_Consumers.Consumer_Model) is
      Ctx : Contract_Flow_Context_Info;
      Best : Flow_Consumers.Consumer_Info;
      Count : Natural;
   begin
      if Row.Kind not in Contracts.Contract_Context_Global_Aspect |
                         Contracts.Contract_Context_Depends_Aspect |
                         Contracts.Contract_Context_Refined_Global |
                         Contracts.Contract_Context_Refined_Depends |
                         Contracts.Contract_Context_Generic_Formal_Contract
      then
         return;
      end if;

      Best := Best_Consumer (Row, Consumers, Count);
      Ctx.Id := Contract_Flow_Row_Id (Context_Count (Model) + 1);
      Ctx.Kind := Context_Kind_From_Contract (Row.Kind);
      Ctx.Node := Row.Node;
      Ctx.Subject_Node := Row.Subject_Node;
      Ctx.Expression_Node := Row.Expression_Node;
      Ctx.Contract_Row := Row.Id;
      Ctx.Contract_Status := Row.Status;
      Ctx.Contract_Flow_State := Row.Flow_State;
      Ctx.Consumer_Row := Best.Id;
      Ctx.Consumer_Status := Best.Status;
      Ctx.Consumer_Matches := Count;
      Ctx.Object_Name := Best.Object_Name;
      Ctx.Source_Name := Best.Source_Name;
      Ctx.Target_Name := Best.Target_Name;
      Ctx.Caller_Name := Best.Caller_Name;
      Ctx.Callee_Name := Best.Callee_Name;
      Ctx.Start_Line := Row.Start_Line;
      Ctx.Start_Column := Row.Start_Column;
      Ctx.End_Line := Row.End_Line;
      Ctx.End_Column := Row.End_Column;
      Ctx.Source_Fingerprint := Mix (Row.Source_Fingerprint, Best.Fingerprint);
      Add_Context (Model, Ctx);
   end Add_From_Contract_Row;

   function Context_Count (Model : Contract_Flow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Contract_Flow_Context_Model; Index : Positive) return Contract_Flow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Contract_Flow_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Contract_Flow_Context_Model) return Contract_Flow_Model is
      Model : Contract_Flow_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            C : constant Contract_Flow_Context_Info := Context_At (Contexts, I);
            R : Contract_Flow_Info;
         begin
            R.Id := Contract_Flow_Row_Id (Natural (Model.Items.Length) + 1);
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Status := Status_For (C);
            R.Node := C.Node;
            R.Subject_Node := C.Subject_Node;
            R.Expression_Node := C.Expression_Node;
            R.Object_Name := C.Object_Name;
            R.Source_Name := C.Source_Name;
            R.Target_Name := C.Target_Name;
            R.Caller_Name := C.Caller_Name;
            R.Callee_Name := C.Callee_Name;
            R.Contract_Row := C.Contract_Row;
            R.Contract_Status := C.Contract_Status;
            R.Contract_Flow_State := C.Contract_Flow_State;
            R.Consumer_Row := C.Consumer_Row;
            R.Consumer_Status := C.Consumer_Status;
            R.Consumer_Matches := C.Consumer_Matches;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Message := To_Unbounded_String (Contract_Flow_Status'Image (R.Status));
            R.Detail := To_Unbounded_String ("contract flow refinement consumer status");
            R.Fingerprint := Row_Fingerprint (R);
            Model.Items.Append (R);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, R.Fingerprint);
            if Is_Legal (R.Status) then
               Model.Legal_Total := Model.Legal_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;
            if Is_Global_Error (R.Status) then
               Model.Global_Error_Total := Model.Global_Error_Total + 1;
            end if;
            if Is_Depends_Error (R.Status) then
               Model.Depends_Error_Total := Model.Depends_Error_Total + 1;
            end if;
            if Is_Propagation_Error (R.Status) then
               Model.Propagation_Error_Total := Model.Propagation_Error_Total + 1;
            end if;
            if R.Status = Contract_Flow_Coverage_Feedback_Blocker then
               Model.Coverage_Error_Total := Model.Coverage_Error_Total + 1;
            end if;
            if R.Status in Contract_Flow_Consumer_Indeterminate | Contract_Flow_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Build_From_Contracts_And_Flow_Consumers
     (Contract_Model : Contracts.Contract_Legality_Model;
      Consumers      : Flow_Consumers.Consumer_Model) return Contract_Flow_Model is
      Contexts : Contract_Flow_Context_Model;
   begin
      for I in 1 .. Contracts.Legality_Count (Contract_Model) loop
         Add_From_Contract_Row (Contexts, Contracts.Legality_At (Contract_Model, I), Consumers);
      end loop;
      return Build (Contexts);
   end Build_From_Contracts_And_Flow_Consumers;

   function Row_Count (Model : Contract_Flow_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Contract_Flow_Model; Index : Positive) return Contract_Flow_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Contract_Flow_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Contract_Flow_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Contract_Flow_Model; Status : Contract_Flow_Status) return Contract_Flow_Set is
      Set : Contract_Flow_Set;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Set.Items.Append (R);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Contract_Flow_Model; Kind : Contract_Flow_Context_Kind) return Contract_Flow_Set is
      Set : Contract_Flow_Set;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Set.Items.Append (R);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Object (Model : Contract_Flow_Model; Name : String) return Contract_Flow_Set is
      Set : Contract_Flow_Set;
   begin
      for R of Model.Items loop
         if To_String (R.Object_Name) = Name then
            Set.Items.Append (R);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Object;

   function Set_Count (Set : Contract_Flow_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Contract_Flow_Set; Index : Positive) return Contract_Flow_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Contract_Flow_Model; Status : Contract_Flow_Status) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Status;

   function Count_Kind (Model : Contract_Flow_Model; Kind : Contract_Flow_Context_Kind) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Kind;

   function Legal_Count (Model : Contract_Flow_Model) return Natural is (Model.Legal_Total);
   function Error_Count (Model : Contract_Flow_Model) return Natural is (Model.Error_Total);
   function Global_Error_Count (Model : Contract_Flow_Model) return Natural is (Model.Global_Error_Total);
   function Depends_Error_Count (Model : Contract_Flow_Model) return Natural is (Model.Depends_Error_Total);
   function Propagation_Error_Count (Model : Contract_Flow_Model) return Natural is (Model.Propagation_Error_Total);
   function Coverage_Error_Count (Model : Contract_Flow_Model) return Natural is (Model.Coverage_Error_Total);
   function Indeterminate_Count (Model : Contract_Flow_Model) return Natural is (Model.Indeterminate_Total);
   function Fingerprint (Model : Contract_Flow_Model) return Natural is (Model.Result_Fingerprint);

end Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
