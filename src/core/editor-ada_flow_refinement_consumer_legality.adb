with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Flow_Refinement_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Refined.Refined_Conformance_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16_777_619 + Hash_Value (Right) + 2_166_136_261;
   begin
      return Natural (Mixed mod Hash_Value (Natural'Last));
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

   function Flow_Is_Legal (Status : Flow.Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
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
   end Flow_Is_Legal;

   function Is_Legal (Status : Consumer_Status) return Boolean is
   begin
      return Status in
        Consumer_Legal_Flow_Edge_Accepted |
        Consumer_Legal_Depends_Edge_Accepted |
        Consumer_Legal_Call_Propagation_Accepted |
        Consumer_Legal_Generic_Effect_Accepted |
        Consumer_Legal_Task_Protected_Effect_Accepted |
        Consumer_Legal_Null_Effect_Accepted;
   end Is_Legal;

   function Is_Global_Error (Status : Consumer_Status) return Boolean is
   begin
      return Status in
        Consumer_Refined_Global_Missing_Read |
        Consumer_Refined_Global_Missing_Write |
        Consumer_Refined_Global_Mode_Mismatch |
        Consumer_Refined_Global_Extra_Item;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Consumer_Status) return Boolean is
   begin
      return Status in
        Consumer_Refined_Depends_Missing_Edge |
        Consumer_Refined_Depends_Extra_Edge |
        Consumer_Refined_Depends_Source_Mode_Error |
        Consumer_Refined_Depends_Target_Mode_Error;
   end Is_Depends_Error;

   function Is_Propagation_Error (Status : Consumer_Status) return Boolean is
   begin
      return Status in Consumer_Call_Effect_Not_Propagated;
   end Is_Propagation_Error;

   function Effect_From_Flow (Edge : Flow.Flow_Edge_Kind) return Consumer_Effect_Kind is
   begin
      case Edge is
         when Flow.Flow_Edge_Object_Read =>
            return Consumer_Effect_Read;
         when Flow.Flow_Edge_Object_Write =>
            return Consumer_Effect_Write;
         when Flow.Flow_Edge_Object_Read_Write =>
            return Consumer_Effect_Read_Write;
         when Flow.Flow_Edge_Depends | Flow.Flow_Edge_Refined_Depends =>
            return Consumer_Effect_Depends;
         when Flow.Flow_Edge_Call_Propagation =>
            return Consumer_Effect_Call_Propagation;
         when Flow.Flow_Edge_Generic_Substitution =>
            return Consumer_Effect_Generic_Substitution;
         when Flow.Flow_Edge_Protected_State =>
            return Consumer_Effect_Protected_State;
         when Flow.Flow_Edge_Task_Activation =>
            return Consumer_Effect_Task_Activation;
         when Flow.Flow_Edge_Null =>
            return Consumer_Effect_Null;
         when others =>
            return Consumer_Effect_Unknown;
      end case;
   end Effect_From_Flow;

   function Consumer_From_Flow (Kind : Flow.Flow_Graph_Context_Kind) return Consumer_Kind is
   begin
      case Kind is
         when Flow.Flow_Context_Call =>
            return Consumer_Call;
         when Flow.Flow_Context_Generic_Formal_Actual =>
            return Consumer_Generic_Instance;
         when Flow.Flow_Context_Protected_Function |
              Flow.Flow_Context_Protected_Procedure |
              Flow.Flow_Context_Protected_Entry |
              Flow.Flow_Context_Task_Body =>
            return Consumer_Task_Protected;
         when Flow.Flow_Context_Package_Elaboration =>
            return Consumer_Elaboration;
         when Flow.Flow_Context_Refined_Global |
              Flow.Flow_Context_Refined_Depends |
              Flow.Flow_Context_Subprogram_Body |
              Flow.Flow_Context_Subprogram_Spec =>
            return Consumer_Integrated_Closure;
         when others =>
            return Consumer_Unknown;
      end case;
   end Consumer_From_Flow;

   function Context_Fingerprint (Info : Consumer_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Consumer_Kind'Pos (Info.Consumer) + 1);
      H := Mix (H, Consumer_Effect_Kind'Pos (Info.Effect) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Text_Hash (Info.Caller_Name));
      H := Mix (H, Text_Hash (Info.Callee_Name));
      H := Mix (H, Natural (Info.Flow_Row) + 1);
      H := Mix (H, Flow.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, Natural (Info.Refined_Row) + 1);
      H := Mix (H, Refined.Refined_Conformance_Status'Pos (Info.Refined_Status) + 1);
      H := Mix (H, Info.Refined_Match_Count + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Spec_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Body_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Refined_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Source_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Target_Global_Mode) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Consumer_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Consumer_Kind'Pos (Info.Consumer) + 1);
      H := Mix (H, Consumer_Effect_Kind'Pos (Info.Effect) + 1);
      H := Mix (H, Consumer_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Text_Hash (Info.Caller_Name));
      H := Mix (H, Text_Hash (Info.Callee_Name));
      H := Mix (H, Natural (Info.Flow_Row) + 1);
      H := Mix (H, Flow.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, Natural (Info.Refined_Row) + 1);
      H := Mix (H, Refined.Refined_Conformance_Status'Pos (Info.Refined_Status) + 1);
      H := Mix (H, Info.Refined_Match_Count + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Refined_Matches_Flow
     (R : Refined.Refined_Conformance_Info;
      F : Flow.Flow_Effect_Info) return Boolean
   is
   begin
      if R.Node /= Editor.Ada_Syntax_Tree.No_Node and then R.Node = F.Node then
         return True;
      elsif Length (R.Object_Name) > 0 and then R.Object_Name = F.Object_Name then
         return True;
      elsif Length (R.Source_Name) > 0 and then R.Source_Name = F.Source_Name and then
        Length (R.Target_Name) > 0 and then R.Target_Name = F.Target_Name
      then
         return True;
      else
         return False;
      end if;
   end Refined_Matches_Flow;

   function Best_Refinement
     (Row     : Flow.Flow_Effect_Info;
      Model   : Refined.Refined_Conformance_Model;
      Matches : out Natural) return Refined.Refined_Conformance_Info
   is
      Best : Refined.Refined_Conformance_Info;
   begin
      Matches := 0;
      for I in 1 .. Refined.Row_Count (Model) loop
         declare
            R : constant Refined.Refined_Conformance_Info := Refined.Row_At (Model, I);
         begin
            if Refined_Matches_Flow (R, Row) then
               Matches := Matches + 1;
               if Matches = 1 or else
                 (not Refined.Is_Legal (R.Status) and then Refined.Is_Legal (Best.Status))
               then
                  Best := R;
               end if;
            end if;
         end;
      end loop;
      return Best;
   end Best_Refinement;

   function Status_For (Info : Consumer_Context_Info) return Consumer_Status is
   begin
      if not Flow_Is_Legal (Info.Flow_Status) then
         return Consumer_Flow_Graph_Error;
      elsif Info.Refined_Match_Count > 1 then
         return Consumer_Multiple_Refinement_Blockers;
      elsif Info.Refined_Row = Refined.No_Refined_Conformance then
         return Consumer_Missing_Refinement_Row;
      end if;

      case Info.Refined_Status is
         when Refined.Refined_Conformance_Legal_Global_Refinement =>
            case Info.Effect is
               when Consumer_Effect_Generic_Substitution =>
                  return Consumer_Legal_Generic_Effect_Accepted;
               when Consumer_Effect_Protected_State | Consumer_Effect_Task_Activation =>
                  return Consumer_Legal_Task_Protected_Effect_Accepted;
               when Consumer_Effect_Null =>
                  return Consumer_Legal_Null_Effect_Accepted;
               when others =>
                  return Consumer_Legal_Flow_Edge_Accepted;
            end case;
         when Refined.Refined_Conformance_Legal_Depends_Refinement =>
            return Consumer_Legal_Depends_Edge_Accepted;
         when Refined.Refined_Conformance_Legal_Call_Effect_Propagation =>
            return Consumer_Legal_Call_Propagation_Accepted;
         when Refined.Refined_Conformance_Legal_Null_Refinement =>
            return Consumer_Legal_Null_Effect_Accepted;
         when Refined.Refined_Conformance_Body_Read_Missing_From_Spec_Global |
              Refined.Refined_Conformance_Body_Read_Missing_From_Refined_Global =>
            return Consumer_Refined_Global_Missing_Read;
         when Refined.Refined_Conformance_Body_Write_Missing_From_Spec_Global |
              Refined.Refined_Conformance_Body_Write_Missing_From_Refined_Global =>
            return Consumer_Refined_Global_Missing_Write;
         when Refined.Refined_Conformance_Refined_Global_Mode_Mismatch =>
            return Consumer_Refined_Global_Mode_Mismatch;
         when Refined.Refined_Conformance_Refined_Global_Extra_Item =>
            return Consumer_Refined_Global_Extra_Item;
         when Refined.Refined_Conformance_Refined_Depends_Missing_Edge |
              Refined.Refined_Conformance_Body_Depends_Not_Refined =>
            return Consumer_Refined_Depends_Missing_Edge;
         when Refined.Refined_Conformance_Refined_Depends_Extra_Edge =>
            return Consumer_Refined_Depends_Extra_Edge;
         when Refined.Refined_Conformance_Refined_Depends_Source_Not_Spec_Input =>
            return Consumer_Refined_Depends_Source_Mode_Error;
         when Refined.Refined_Conformance_Refined_Depends_Target_Not_Spec_Output =>
            return Consumer_Refined_Depends_Target_Mode_Error;
         when Refined.Refined_Conformance_Call_Effect_Not_Propagated =>
            return Consumer_Call_Effect_Not_Propagated;
         when Refined.Refined_Conformance_Coverage_Feedback_Blocker =>
            return Consumer_Coverage_Feedback_Blocker;
         when Refined.Refined_Conformance_Linked_Flow_Graph_Error =>
            return Consumer_Refinement_Linked_Flow_Error;
         when Refined.Refined_Conformance_Indeterminate =>
            return Consumer_Refinement_Indeterminate;
         when Refined.Refined_Conformance_Not_Checked =>
            return Consumer_Indeterminate;
      end case;
   end Status_For;

   function Message_For (Status : Consumer_Status) return Unbounded_String is
   begin
      case Status is
         when Consumer_Legal_Flow_Edge_Accepted =>
            return To_Unbounded_String ("flow edge accepted by refined body/spec conformance");
         when Consumer_Legal_Depends_Edge_Accepted =>
            return To_Unbounded_String ("Depends edge accepted by Refined_Depends conformance");
         when Consumer_Legal_Call_Propagation_Accepted =>
            return To_Unbounded_String ("call effect accepted after refined propagation check");
         when Consumer_Legal_Generic_Effect_Accepted =>
            return To_Unbounded_String ("generic flow effect accepted after refined conformance check");
         when Consumer_Legal_Task_Protected_Effect_Accepted =>
            return To_Unbounded_String ("task/protected flow effect accepted after refined conformance check");
         when Consumer_Legal_Null_Effect_Accepted =>
            return To_Unbounded_String ("null flow effect accepted after refined conformance check");
         when Consumer_Flow_Graph_Error =>
            return To_Unbounded_String ("flow-effect graph error blocks consumer result");
         when Consumer_Missing_Refinement_Row =>
            return To_Unbounded_String ("flow consumer has no matching Refined_Global/Depends conformance row");
         when Consumer_Refined_Global_Missing_Read =>
            return To_Unbounded_String ("body read is not admitted by refined Global conformance");
         when Consumer_Refined_Global_Missing_Write =>
            return To_Unbounded_String ("body write is not admitted by refined Global conformance");
         when Consumer_Refined_Global_Mode_Mismatch =>
            return To_Unbounded_String ("Refined_Global mode blocks flow consumer");
         when Consumer_Refined_Global_Extra_Item =>
            return To_Unbounded_String ("extra Refined_Global item blocks flow consumer");
         when Consumer_Refined_Depends_Missing_Edge =>
            return To_Unbounded_String ("missing Refined_Depends edge blocks flow consumer");
         when Consumer_Refined_Depends_Extra_Edge =>
            return To_Unbounded_String ("extra Refined_Depends edge blocks flow consumer");
         when Consumer_Refined_Depends_Source_Mode_Error =>
            return To_Unbounded_String ("Refined_Depends source mode blocks flow consumer");
         when Consumer_Refined_Depends_Target_Mode_Error =>
            return To_Unbounded_String ("Refined_Depends target mode blocks flow consumer");
         when Consumer_Call_Effect_Not_Propagated =>
            return To_Unbounded_String ("callee flow effects are not propagated through refined body");
         when Consumer_Coverage_Feedback_Blocker =>
            return To_Unbounded_String ("repaired coverage feedback blocks flow consumer");
         when Consumer_Refinement_Linked_Flow_Error =>
            return To_Unbounded_String ("refined conformance links back to a flow graph error");
         when Consumer_Refinement_Indeterminate =>
            return To_Unbounded_String ("refined conformance leaves flow consumer indeterminate");
         when Consumer_Multiple_Refinement_Blockers =>
            return To_Unbounded_String ("multiple refinement rows match one flow consumer");
         when Consumer_Indeterminate =>
            return To_Unbounded_String ("flow/refinement consumer legality is indeterminate");
         when Consumer_Not_Checked =>
            return To_Unbounded_String ("flow/refinement consumer legality not checked");
      end case;
   end Message_For;

   procedure Clear (Model : in out Consumer_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Consumer_Context_Model; Info : Consumer_Context_Info) is
      Item : Consumer_Context_Info := Info;
   begin
      if Item.Id = No_Consumer_Row then
         Item.Id := Consumer_Row_Id (Natural (Model.Items.Length) + 1);
      end if;
      Model.Items.Append (Item);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Item));
   end Add_Context;

   procedure Add_From_Flow_Row
     (Model   : in out Consumer_Context_Model;
      Row     : Flow.Flow_Effect_Info;
      Refined : Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Model)
   is
      Matches : Natural := 0;
      R       : constant Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Info :=
        Best_Refinement (Row, Refined, Matches);
      Info    : Consumer_Context_Info;
   begin
      Info.Id := Consumer_Row_Id (Natural (Model.Items.Length) + 1);
      Info.Consumer := Consumer_From_Flow (Row.Kind);
      Info.Effect := Effect_From_Flow (Row.Edge);
      Info.Node := Row.Node;
      Info.Source_Node := Row.Source_Node;
      Info.Target_Node := Row.Target_Node;
      Info.Object_Name := Row.Object_Name;
      Info.Source_Name := Row.Source_Name;
      Info.Target_Name := Row.Target_Name;
      Info.Caller_Name := Row.Caller_Name;
      Info.Callee_Name := Row.Callee_Name;
      Info.Flow_Row := Row.Id;
      Info.Flow_Status := Row.Status;
      Info.Refined_Row := R.Id;
      Info.Refined_Status := R.Status;
      Info.Refined_Match_Count := Matches;
      Info.Spec_Global_Mode := Row.Spec_Global_Mode;
      Info.Body_Global_Mode := Row.Body_Global_Mode;
      Info.Refined_Global_Mode := R.Refined_Global_Mode;
      Info.Source_Global_Mode := Row.Source_Global_Mode;
      Info.Target_Global_Mode := Row.Target_Global_Mode;
      Info.Start_Line := Row.Start_Line;
      Info.Start_Column := Row.Start_Column;
      Info.End_Line := Row.End_Line;
      Info.End_Column := Row.End_Column;
      Info.Source_Fingerprint := Mix (Row.Source_Fingerprint, R.Fingerprint);
      Add_Context (Model, Info);
   end Add_From_Flow_Row;

   function Context_Count (Model : Consumer_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Consumer_Context_Model; Index : Positive) return Consumer_Context_Info is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Consumer_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   procedure Append_Row (Model : in out Consumer_Model; Row : Consumer_Info) is
      Item : Consumer_Info := Row;
   begin
      Item.Fingerprint := Row_Fingerprint (Item);
      Model.Items.Append (Item);
      Model.Fingerprint := Mix (Model.Fingerprint, Item.Fingerprint);
      if Is_Legal (Item.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Is_Global_Error (Item.Status) then
         Model.Global_Error_Total := Model.Global_Error_Total + 1;
      end if;
      if Is_Depends_Error (Item.Status) then
         Model.Depends_Error_Total := Model.Depends_Error_Total + 1;
      end if;
      if Is_Propagation_Error (Item.Status) then
         Model.Propagation_Error_Total := Model.Propagation_Error_Total + 1;
      end if;
      if Item.Status = Consumer_Coverage_Feedback_Blocker then
         Model.Coverage_Error_Total := Model.Coverage_Error_Total + 1;
      end if;
      if Item.Status in Consumer_Indeterminate | Consumer_Refinement_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Append_Row;

   function Build (Contexts : Consumer_Context_Model) return Consumer_Model is
      Model : Consumer_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            C : constant Consumer_Context_Info := Context_At (Contexts, I);
            R : Consumer_Info;
         begin
            R.Id := Consumer_Row_Id (I);
            R.Context := C.Id;
            R.Consumer := C.Consumer;
            R.Effect := C.Effect;
            R.Status := Status_For (C);
            R.Node := C.Node;
            R.Source_Node := C.Source_Node;
            R.Target_Node := C.Target_Node;
            R.Object_Name := C.Object_Name;
            R.Source_Name := C.Source_Name;
            R.Target_Name := C.Target_Name;
            R.Caller_Name := C.Caller_Name;
            R.Callee_Name := C.Callee_Name;
            R.Message := Message_For (R.Status);
            R.Detail := To_Unbounded_String ("Case 1155 flow/refinement consumer row");
            R.Flow_Row := C.Flow_Row;
            R.Flow_Status := C.Flow_Status;
            R.Refined_Row := C.Refined_Row;
            R.Refined_Status := C.Refined_Status;
            R.Refined_Match_Count := C.Refined_Match_Count;
            R.Spec_Global_Mode := C.Spec_Global_Mode;
            R.Body_Global_Mode := C.Body_Global_Mode;
            R.Refined_Global_Mode := C.Refined_Global_Mode;
            R.Source_Global_Mode := C.Source_Global_Mode;
            R.Target_Global_Mode := C.Target_Global_Mode;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            Append_Row (Model, R);
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Contexts.Fingerprint);
      return Model;
   end Build;

   function Build_From_Flow_And_Refinement
     (Graph   : Flow.Flow_Effect_Graph_Model;
      Refined : Editor.Ada_Refined_Global_Depends_Conformance_Legality.Refined_Conformance_Model)
      return Consumer_Model
   is
      Contexts : Consumer_Context_Model;
   begin
      for I in 1 .. Flow.Row_Count (Graph) loop
         Add_From_Flow_Row (Contexts, Flow.Row_At (Graph, I), Refined);
      end loop;
      return Build (Contexts);
   end Build_From_Flow_And_Refinement;

   function Row_Count (Model : Consumer_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Consumer_Model; Index : Positive) return Consumer_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Consumer_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Consumer_Info is
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Node = Node then
            return Row_At (Model, I);
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Consumer_Model; Status : Consumer_Status) return Consumer_Set is
      Result : Consumer_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Status = Status then
            Result.Items.Append (Row_At (Model, I));
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Consumer (Model : Consumer_Model; Consumer : Consumer_Kind) return Consumer_Set is
      Result : Consumer_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Consumer = Consumer then
            Result.Items.Append (Row_At (Model, I));
         end if;
      end loop;
      return Result;
   end Rows_For_Consumer;

   function Rows_For_Object (Model : Consumer_Model; Name : String) return Consumer_Set is
      Result : Consumer_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         if To_String (Row_At (Model, I).Object_Name) = Name then
            Result.Items.Append (Row_At (Model, I));
         end if;
      end loop;
      return Result;
   end Rows_For_Object;

   function Set_Count (Set : Consumer_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Consumer_Set; Index : Positive) return Consumer_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Consumer_Model; Status : Consumer_Status) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Consumer (Model : Consumer_Model; Consumer : Consumer_Kind) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Row_Count (Model) loop
         if Row_At (Model, I).Consumer = Consumer then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Consumer;

   function Legal_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Global_Error_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Propagation_Error_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Propagation_Error_Total;
   end Propagation_Error_Count;

   function Coverage_Error_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Coverage_Error_Total;
   end Coverage_Error_Count;

   function Indeterminate_Count (Model : Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Consumer_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Flow_Refinement_Consumer_Legality;
