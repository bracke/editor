with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality is

   use type Contract_Flow.Contract_Flow_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Graph.Elaboration_Graph_Closure_Status;

   Modulus : constant Natural := 2_147_483_647;

   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 16_777_619 + B + 113) mod Modulus;
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

   function Is_Legal (Status : Elaboration_Contract_Flow_Status) return Boolean is
   begin
      return Status in
        Elaboration_Contract_Flow_Legal_Call_Accepted |
        Elaboration_Contract_Flow_Legal_Default_Expression_Accepted |
        Elaboration_Contract_Flow_Legal_Aspect_Expression_Accepted |
        Elaboration_Contract_Flow_Legal_Representation_Item_Accepted |
        Elaboration_Contract_Flow_Legal_Generic_Instance_Accepted |
        Elaboration_Contract_Flow_Legal_Task_Activation_Accepted |
        Elaboration_Contract_Flow_Legal_Preelaboration_Policy_Accepted |
        Elaboration_Contract_Flow_Legal_Pure_Policy_Accepted |
        Elaboration_Contract_Flow_Legal_Remote_Types_Policy_Accepted |
        Elaboration_Contract_Flow_Legal_Shared_Passive_Policy_Accepted;
   end Is_Legal;

   function Is_Global_Error (Status : Elaboration_Contract_Flow_Status) return Boolean is
   begin
      return Status in
        Elaboration_Contract_Flow_Refined_Global_Missing_Read |
        Elaboration_Contract_Flow_Refined_Global_Missing_Write |
        Elaboration_Contract_Flow_Refined_Global_Mode_Mismatch |
        Elaboration_Contract_Flow_Refined_Global_Extra_Item;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Elaboration_Contract_Flow_Status) return Boolean is
   begin
      return Status in
        Elaboration_Contract_Flow_Refined_Depends_Missing_Edge |
        Elaboration_Contract_Flow_Refined_Depends_Extra_Edge |
        Elaboration_Contract_Flow_Refined_Depends_Source_Mode_Error |
        Elaboration_Contract_Flow_Refined_Depends_Target_Mode_Error;
   end Is_Depends_Error;

   function Is_Propagation_Error (Status : Elaboration_Contract_Flow_Status) return Boolean is
   begin
      return Status = Elaboration_Contract_Flow_Call_Effect_Not_Propagated;
   end Is_Propagation_Error;

   function Graph_Is_Legal (Status : Elab_Graph.Elaboration_Graph_Closure_Status) return Boolean is
   begin
      return Status in
        Elab_Graph.Graph_Closure_Legal_Library_Edge |
        Elab_Graph.Graph_Closure_Legal_Transitive_Elaborate_All |
        Elab_Graph.Graph_Closure_Legal_Body_Before_Use |
        Elab_Graph.Graph_Closure_Legal_Direct_Call_Order |
        Elab_Graph.Graph_Closure_Legal_Indirect_Call_Order |
        Elab_Graph.Graph_Closure_Legal_Dispatching_Call_Order |
        Elab_Graph.Graph_Closure_Legal_Access_Order |
        Elab_Graph.Graph_Closure_Legal_Generic_Instance_Order |
        Elab_Graph.Graph_Closure_Legal_Default_Expression_Order |
        Elab_Graph.Graph_Closure_Legal_Aspect_Expression_Order |
        Elab_Graph.Graph_Closure_Legal_Representation_Item_Order |
        Elab_Graph.Graph_Closure_Legal_Preelaboration_Policy |
        Elab_Graph.Graph_Closure_Legal_Pure_Policy;
   end Graph_Is_Legal;

   function Context_Kind_From_Graph
     (Kind : Elab_Graph.Elaboration_Graph_Context_Kind) return Elaboration_Contract_Flow_Context_Kind is
   begin
      case Kind is
         when Elab_Graph.Graph_Context_Direct_Call_Edge =>
            return Elaboration_Contract_Flow_Direct_Call;
         when Elab_Graph.Graph_Context_Indirect_Call_Edge =>
            return Elaboration_Contract_Flow_Indirect_Call;
         when Elab_Graph.Graph_Context_Dispatching_Call_Edge =>
            return Elaboration_Contract_Flow_Dispatching_Call;
         when Elab_Graph.Graph_Context_Default_Expression_Edge =>
            return Elaboration_Contract_Flow_Default_Expression;
         when Elab_Graph.Graph_Context_Aspect_Expression_Edge =>
            return Elaboration_Contract_Flow_Aspect_Expression;
         when Elab_Graph.Graph_Context_Representation_Item_Edge =>
            return Elaboration_Contract_Flow_Representation_Item;
         when Elab_Graph.Graph_Context_Generic_Instance_Edge =>
            return Elaboration_Contract_Flow_Generic_Instance;
         when Elab_Graph.Graph_Context_Preelaborated_Unit =>
            return Elaboration_Contract_Flow_Preelaboration_Policy;
         when Elab_Graph.Graph_Context_Pure_Unit =>
            return Elaboration_Contract_Flow_Pure_Policy;
         when Elab_Graph.Graph_Context_Remote_Types_Unit =>
            return Elaboration_Contract_Flow_Remote_Types_Policy;
         when Elab_Graph.Graph_Context_Shared_Passive_Unit =>
            return Elaboration_Contract_Flow_Shared_Passive_Policy;
         when others =>
            return Elaboration_Contract_Flow_Unknown;
      end case;
   end Context_Kind_From_Graph;

   function Status_From_Contract_Flow
     (Status : Contract_Flow.Contract_Flow_Status) return Elaboration_Contract_Flow_Status is
   begin
      case Status is
         when Contract_Flow.Contract_Flow_Refined_Global_Missing_Read =>
            return Elaboration_Contract_Flow_Refined_Global_Missing_Read;
         when Contract_Flow.Contract_Flow_Refined_Global_Missing_Write =>
            return Elaboration_Contract_Flow_Refined_Global_Missing_Write;
         when Contract_Flow.Contract_Flow_Refined_Global_Mode_Mismatch =>
            return Elaboration_Contract_Flow_Refined_Global_Mode_Mismatch;
         when Contract_Flow.Contract_Flow_Refined_Global_Extra_Item =>
            return Elaboration_Contract_Flow_Refined_Global_Extra_Item;
         when Contract_Flow.Contract_Flow_Refined_Depends_Missing_Edge =>
            return Elaboration_Contract_Flow_Refined_Depends_Missing_Edge;
         when Contract_Flow.Contract_Flow_Refined_Depends_Extra_Edge =>
            return Elaboration_Contract_Flow_Refined_Depends_Extra_Edge;
         when Contract_Flow.Contract_Flow_Refined_Depends_Source_Mode_Error =>
            return Elaboration_Contract_Flow_Refined_Depends_Source_Mode_Error;
         when Contract_Flow.Contract_Flow_Refined_Depends_Target_Mode_Error =>
            return Elaboration_Contract_Flow_Refined_Depends_Target_Mode_Error;
         when Contract_Flow.Contract_Flow_Call_Effect_Not_Propagated =>
            return Elaboration_Contract_Flow_Call_Effect_Not_Propagated;
         when Contract_Flow.Contract_Flow_Coverage_Feedback_Blocker =>
            return Elaboration_Contract_Flow_Coverage_Feedback_Blocker;
         when Contract_Flow.Contract_Flow_Linked_Flow_Graph_Error =>
            return Elaboration_Contract_Flow_Linked_Flow_Graph_Error;
         when Contract_Flow.Contract_Flow_Base_Contract_Error =>
            return Elaboration_Contract_Flow_Contract_Base_Error;
         when Contract_Flow.Contract_Flow_Multiple_Consumer_Blockers =>
            return Elaboration_Contract_Flow_Multiple_Contract_Flow_Blockers;
         when Contract_Flow.Contract_Flow_Consumer_Indeterminate |
              Contract_Flow.Contract_Flow_Indeterminate =>
            return Elaboration_Contract_Flow_Contract_Flow_Indeterminate;
         when Contract_Flow.Contract_Flow_Missing_Consumer_Row |
              Contract_Flow.Contract_Flow_Not_Checked =>
            return Elaboration_Contract_Flow_Missing_Contract_Flow_Row;
         when others =>
            return Elaboration_Contract_Flow_Indeterminate;
      end case;
   end Status_From_Contract_Flow;

   function Legal_Status_For_Kind
     (Kind : Elaboration_Contract_Flow_Context_Kind) return Elaboration_Contract_Flow_Status is
   begin
      case Kind is
         when Elaboration_Contract_Flow_Direct_Call |
              Elaboration_Contract_Flow_Indirect_Call |
              Elaboration_Contract_Flow_Dispatching_Call =>
            return Elaboration_Contract_Flow_Legal_Call_Accepted;
         when Elaboration_Contract_Flow_Default_Expression =>
            return Elaboration_Contract_Flow_Legal_Default_Expression_Accepted;
         when Elaboration_Contract_Flow_Aspect_Expression =>
            return Elaboration_Contract_Flow_Legal_Aspect_Expression_Accepted;
         when Elaboration_Contract_Flow_Representation_Item =>
            return Elaboration_Contract_Flow_Legal_Representation_Item_Accepted;
         when Elaboration_Contract_Flow_Generic_Instance =>
            return Elaboration_Contract_Flow_Legal_Generic_Instance_Accepted;
         when Elaboration_Contract_Flow_Task_Activation =>
            return Elaboration_Contract_Flow_Legal_Task_Activation_Accepted;
         when Elaboration_Contract_Flow_Preelaboration_Policy =>
            return Elaboration_Contract_Flow_Legal_Preelaboration_Policy_Accepted;
         when Elaboration_Contract_Flow_Pure_Policy =>
            return Elaboration_Contract_Flow_Legal_Pure_Policy_Accepted;
         when Elaboration_Contract_Flow_Remote_Types_Policy =>
            return Elaboration_Contract_Flow_Legal_Remote_Types_Policy_Accepted;
         when Elaboration_Contract_Flow_Shared_Passive_Policy =>
            return Elaboration_Contract_Flow_Legal_Shared_Passive_Policy_Accepted;
         when others =>
            return Elaboration_Contract_Flow_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_For (Info : Elaboration_Contract_Flow_Context_Info) return Elaboration_Contract_Flow_Status is
   begin
      if not Graph_Is_Legal (Info.Graph_Status) then
         if Info.Graph_Status = Elab_Graph.Graph_Closure_Indeterminate then
            return Elaboration_Contract_Flow_Indeterminate;
         else
            return Elaboration_Contract_Flow_Base_Elaboration_Error;
         end if;
      elsif Info.Contract_Flow_Matches > 1 then
         return Elaboration_Contract_Flow_Multiple_Contract_Flow_Blockers;
      elsif Info.Contract_Flow_Row = Contract_Flow.No_Contract_Flow_Row then
         return Elaboration_Contract_Flow_Missing_Contract_Flow_Row;
      elsif Contract_Flow.Is_Legal (Info.Contract_Flow_Status) then
         return Legal_Status_For_Kind (Info.Kind);
      else
         return Status_From_Contract_Flow (Info.Contract_Flow_Status);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Elaboration_Contract_Flow_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Elaboration_Contract_Flow_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Elaboration_Contract_Flow_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Unit_Node) + 1);
      H := Mix (H, Natural (Info.Target_Unit_Node) + 1);
      H := Mix (H, Text_Hash (Info.Source_Unit_Name));
      H := Mix (H, Text_Hash (Info.Target_Unit_Name));
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Text_Hash (Info.Caller_Name));
      H := Mix (H, Text_Hash (Info.Callee_Name));
      H := Mix (H, Natural (Info.Graph_Row) + 1);
      H := Mix (H, Elab_Graph.Elaboration_Graph_Closure_Status'Pos (Info.Graph_Status) + 1);
      H := Mix (H, Natural (Info.Contract_Flow_Row) + 1);
      H := Mix (H, Contract_Flow.Contract_Flow_Status'Pos (Info.Contract_Flow_Status) + 1);
      H := Mix (H, Info.Contract_Flow_Matches + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Matches
     (C : Contract_Flow.Contract_Flow_Info;
      R : Elab_Graph.Elaboration_Graph_Closure_Info) return Boolean is
   begin
      if C.Node /= Editor.Ada_Syntax_Tree.No_Node and then C.Node = R.Node then
         return True;
           elsif C.Expression_Node /= Editor.Ada_Syntax_Tree.No_Node and then C.Expression_Node = R.Node then
         return True;
      elsif Length (C.Callee_Name) > 0 and then C.Callee_Name = R.Target_Unit_Name then
         return True;
      elsif Length (C.Caller_Name) > 0 and then C.Caller_Name = R.Source_Unit_Name then
         return True;
      else
         return False;
      end if;
   end Matches;

   function Best_Contract_Flow
     (Row   : Elab_Graph.Elaboration_Graph_Closure_Info;
      Flows : Contract_Flow.Contract_Flow_Model;
      Count : out Natural) return Contract_Flow.Contract_Flow_Info is
      Best : Contract_Flow.Contract_Flow_Info;
   begin
      Count := 0;
      for I in 1 .. Contract_Flow.Row_Count (Flows) loop
         declare
            C : constant Contract_Flow.Contract_Flow_Info := Contract_Flow.Row_At (Flows, I);
         begin
            if Matches (C, Row) then
               Count := Count + 1;
               if Count = 1 or else
                 (not Contract_Flow.Is_Legal (C.Status) and then Contract_Flow.Is_Legal (Best.Status))
               then
                  Best := C;
               end if;
            end if;
         end;
      end loop;
      return Best;
   end Best_Contract_Flow;

   procedure Clear (Model : in out Elaboration_Contract_Flow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Elaboration_Contract_Flow_Context_Model;
      Info  : Elaboration_Contract_Flow_Context_Info) is
      H : Natural := Model.Result_Fingerprint;
   begin
      Model.Contexts.Append (Info);
      H := Mix (H, Natural (Info.Id) + 1);
      H := Mix (H, Elaboration_Contract_Flow_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Elab_Graph.Elaboration_Graph_Closure_Status'Pos (Info.Graph_Status) + 1);
      H := Mix (H, Contract_Flow.Contract_Flow_Status'Pos (Info.Contract_Flow_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      Model.Result_Fingerprint := H;
   end Add_Context;

   procedure Add_From_Graph_Row
     (Model          : in out Elaboration_Contract_Flow_Context_Model;
      Row            : Elab_Graph.Elaboration_Graph_Closure_Info;
      Contract_Flows : Contract_Flow.Contract_Flow_Model) is
      Ctx : Elaboration_Contract_Flow_Context_Info;
      Best : Contract_Flow.Contract_Flow_Info;
      Count : Natural;
   begin
      if Row.Kind not in Elab_Graph.Graph_Context_Direct_Call_Edge |
                         Elab_Graph.Graph_Context_Indirect_Call_Edge |
                         Elab_Graph.Graph_Context_Dispatching_Call_Edge |
                         Elab_Graph.Graph_Context_Default_Expression_Edge |
                         Elab_Graph.Graph_Context_Aspect_Expression_Edge |
                         Elab_Graph.Graph_Context_Representation_Item_Edge |
                         Elab_Graph.Graph_Context_Generic_Instance_Edge |
                         Elab_Graph.Graph_Context_Preelaborated_Unit |
                         Elab_Graph.Graph_Context_Pure_Unit |
                         Elab_Graph.Graph_Context_Remote_Types_Unit |
                         Elab_Graph.Graph_Context_Shared_Passive_Unit
      then
         return;
      end if;

      Best := Best_Contract_Flow (Row, Contract_Flows, Count);
      Ctx.Id := Elaboration_Contract_Flow_Row_Id (Context_Count (Model) + 1);
      Ctx.Kind := Context_Kind_From_Graph (Row.Kind);
      Ctx.Node := Row.Node;
      Ctx.Source_Unit_Node := Row.Source_Unit_Node;
      Ctx.Target_Unit_Node := Row.Target_Unit_Node;
      Ctx.Source_Unit_Name := Row.Source_Unit_Name;
      Ctx.Target_Unit_Name := Row.Target_Unit_Name;
      Ctx.Graph_Row := Row.Id;
      Ctx.Graph_Status := Row.Status;
      Ctx.Contract_Flow_Row := Best.Id;
      Ctx.Contract_Flow_Status := Best.Status;
      Ctx.Contract_Flow_Matches := Count;
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
   end Add_From_Graph_Row;

   function Context_Count (Model : Elaboration_Contract_Flow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Elaboration_Contract_Flow_Context_Model;
      Index : Positive) return Elaboration_Contract_Flow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Elaboration_Contract_Flow_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Elaboration_Contract_Flow_Context_Model) return Elaboration_Contract_Flow_Model is
      Model : Elaboration_Contract_Flow_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            C : constant Elaboration_Contract_Flow_Context_Info := Context_At (Contexts, I);
            R : Elaboration_Contract_Flow_Info;
         begin
            R.Id := Elaboration_Contract_Flow_Row_Id (Natural (Model.Items.Length) + 1);
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Status := Status_For (C);
            R.Node := C.Node;
            R.Source_Unit_Node := C.Source_Unit_Node;
            R.Target_Unit_Node := C.Target_Unit_Node;
            R.Call_Node := C.Call_Node;
            R.Body_Node := C.Body_Node;
            R.Instance_Node := C.Instance_Node;
            R.Source_Unit_Name := C.Source_Unit_Name;
            R.Target_Unit_Name := C.Target_Unit_Name;
            R.Object_Name := C.Object_Name;
            R.Source_Name := C.Source_Name;
            R.Target_Name := C.Target_Name;
            R.Caller_Name := C.Caller_Name;
            R.Callee_Name := C.Callee_Name;
            R.Graph_Row := C.Graph_Row;
            R.Graph_Status := C.Graph_Status;
            R.Contract_Flow_Row := C.Contract_Flow_Row;
            R.Contract_Flow_Status := C.Contract_Flow_Status;
            R.Contract_Flow_Matches := C.Contract_Flow_Matches;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Message := To_Unbounded_String (Elaboration_Contract_Flow_Status'Image (R.Status));
            R.Detail := To_Unbounded_String ("elaboration contract-flow consumer status");
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
            if R.Status = Elaboration_Contract_Flow_Coverage_Feedback_Blocker then
               Model.Coverage_Error_Total := Model.Coverage_Error_Total + 1;
            end if;
            if R.Kind in Elaboration_Contract_Flow_Preelaboration_Policy |
                         Elaboration_Contract_Flow_Pure_Policy |
                         Elaboration_Contract_Flow_Remote_Types_Policy |
                         Elaboration_Contract_Flow_Shared_Passive_Policy
              and then not Is_Legal (R.Status)
            then
               Model.Policy_Error_Total := Model.Policy_Error_Total + 1;
            end if;
            if R.Status in Elaboration_Contract_Flow_Contract_Flow_Indeterminate |
                           Elaboration_Contract_Flow_Indeterminate
            then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Build_From_Elaboration_And_Contract_Flow
     (Graph_Model    : Elab_Graph.Elaboration_Graph_Closure_Model;
      Contract_Flows : Contract_Flow.Contract_Flow_Model) return Elaboration_Contract_Flow_Model is
      Contexts : Elaboration_Contract_Flow_Context_Model;
   begin
      for I in 1 .. Elab_Graph.Row_Count (Graph_Model) loop
         Add_From_Graph_Row (Contexts, Elab_Graph.Row_At (Graph_Model, I), Contract_Flows);
      end loop;
      return Build (Contexts);
   end Build_From_Elaboration_And_Contract_Flow;

   function Row_Count (Model : Elaboration_Contract_Flow_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Elaboration_Contract_Flow_Model;
      Index : Positive) return Elaboration_Contract_Flow_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Elaboration_Contract_Flow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_Contract_Flow_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Elaboration_Contract_Flow_Model;
      Status : Elaboration_Contract_Flow_Status) return Elaboration_Contract_Flow_Set is
      Set : Elaboration_Contract_Flow_Set;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Set.Items.Append (R);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Elaboration_Contract_Flow_Model;
      Kind  : Elaboration_Contract_Flow_Context_Kind) return Elaboration_Contract_Flow_Set is
      Set : Elaboration_Contract_Flow_Set;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Set.Items.Append (R);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Unit
     (Model : Elaboration_Contract_Flow_Model;
      Name  : String) return Elaboration_Contract_Flow_Set is
      Set : Elaboration_Contract_Flow_Set;
   begin
      for R of Model.Items loop
         if To_String (R.Source_Unit_Name) = Name or else To_String (R.Target_Unit_Name) = Name then
            Set.Items.Append (R);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, R.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Unit;

   function Set_Count (Set : Elaboration_Contract_Flow_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Elaboration_Contract_Flow_Set;
      Index : Positive) return Elaboration_Contract_Flow_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Elaboration_Contract_Flow_Model;
      Status : Elaboration_Contract_Flow_Status) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Status;

   function Count_Kind
     (Model : Elaboration_Contract_Flow_Model;
      Kind  : Elaboration_Contract_Flow_Context_Kind) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Kind;

   function Legal_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Legal_Total);
   function Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Error_Total);
   function Global_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Global_Error_Total);
   function Depends_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Depends_Error_Total);
   function Propagation_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Propagation_Error_Total);
   function Coverage_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Coverage_Error_Total);
   function Policy_Error_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Policy_Error_Total);
   function Indeterminate_Count (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Indeterminate_Total);
   function Fingerprint (Model : Elaboration_Contract_Flow_Model) return Natural is (Model.Result_Fingerprint);

end Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
