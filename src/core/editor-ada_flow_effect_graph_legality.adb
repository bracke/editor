with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Flow_Effect_Graph_Legality is

   use type DGL.Global_Mode;
   use type Editor.Ada_Syntax_Tree.Node_Id;

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

   function Context_Fingerprint (Info : Flow_Effect_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Flow_Graph_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Flow_Edge_Kind'Pos (Info.Edge) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Text_Hash (Info.Caller_Name));
      H := Mix (H, Text_Hash (Info.Callee_Name));
      H := Mix (H, Text_Hash (Info.Formal_Name));
      H := Mix (H, Text_Hash (Info.Actual_Name));
      H := Mix (H, DGL.Global_Mode'Pos (Info.Spec_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Body_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Source_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Target_Global_Mode) + 1);
      if Info.Reads_Object then H := Mix (H, 3); end if;
      if Info.Writes_Object then H := Mix (H, 5); end if;
      if Info.Effect_Propagated then H := Mix (H, 7); end if;
      if Info.Refined_Global_Present then H := Mix (H, 11); end if;
      if Info.Refined_Depends_Present then H := Mix (H, 13); end if;
      if Info.Duplicate_Edge then H := Mix (H, 17); end if;
      if Info.Dependency_Cycle then H := Mix (H, 19); end if;
      H := Mix (H, DGL.Dataflow_Legality_Status'Pos (Info.Base_Dataflow_Status) + 1);
      H := Mix (H, Gate_Enforcement.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Flow_Effect_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Flow_Graph_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Flow_Edge_Kind'Pos (Info.Edge) + 1);
      H := Mix (H, Flow_Effect_Graph_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, DGL.Global_Mode'Pos (Info.Spec_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Body_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Source_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Target_Global_Mode) + 1);
      H := Mix (H, DGL.Dataflow_Legality_Status'Pos (Info.Base_Dataflow_Status) + 1);
      H := Mix (H, Gate_Enforcement.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Allows_Read (Mode : DGL.Global_Mode) return Boolean is
   begin
      return Mode in DGL.Global_Mode_In | DGL.Global_Mode_In_Out | DGL.Global_Mode_Proof_In;
   end Allows_Read;

   function Allows_Write (Mode : DGL.Global_Mode) return Boolean is
   begin
      return Mode in DGL.Global_Mode_Out | DGL.Global_Mode_In_Out;
   end Allows_Write;

   function Base_Dataflow_Error (Status : DGL.Dataflow_Legality_Status) return Boolean is
   begin
      return Status not in
        DGL.Dataflow_Legality_Not_Checked |
        DGL.Dataflow_Legality_Legal_Read |
        DGL.Dataflow_Legality_Legal_Write |
        DGL.Dataflow_Legality_Legal_Read_Write |
        DGL.Dataflow_Legality_Legal_Null_Effect |
        DGL.Dataflow_Legality_Legal_Depends_Edge |
        DGL.Dataflow_Legality_Legal_Refinement;
   end Base_Dataflow_Error;

   function Gate_Blocks (Status : Gate_Enforcement.Enforcement_Status) return Boolean is
   begin
      return Status in
        Gate_Enforcement.Enforcement_Degraded_To_Indeterminate |
        Gate_Enforcement.Enforcement_Cross_Unit_Closure_Required |
        Gate_Enforcement.Enforcement_Legal_Result_Suppressed |
        Gate_Enforcement.Enforcement_Derived_Result_Suppressed |
        Gate_Enforcement.Enforcement_Parser_AST_Blocker |
        Gate_Enforcement.Enforcement_Metadata_Blocker |
        Gate_Enforcement.Enforcement_Consumer_Integration_Blocker |
        Gate_Enforcement.Enforcement_Unsafe_Result_Blocked;
   end Gate_Blocks;

   function Legal_Status (Status : Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        Flow_Graph_Legal_Read_Edge |
        Flow_Graph_Legal_Write_Edge |
        Flow_Graph_Legal_Read_Write_Edge |
        Flow_Graph_Legal_Depends_Edge |
        Flow_Graph_Legal_Call_Propagation |
        Flow_Graph_Legal_Generic_Substitution |
        Flow_Graph_Legal_Protected_State_Effect |
        Flow_Graph_Legal_Task_Activation_Effect |
        Flow_Graph_Legal_Refined_Global |
        Flow_Graph_Legal_Refined_Depends |
        Flow_Graph_Legal_Null_Effect;
   end Legal_Status;

   function Global_Error (Status : Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        Flow_Graph_Read_Not_In_Global |
        Flow_Graph_Write_Not_In_Global |
        Flow_Graph_Write_To_In_Global |
        Flow_Graph_Read_From_Out_Global |
        Flow_Graph_Null_Global_Violated |
        Flow_Graph_Body_Spec_Global_Mismatch |
        Flow_Graph_Refined_Global_Missing_Item |
        Flow_Graph_Refined_Global_Extra_Item;
   end Global_Error;

   function Depends_Error (Status : Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        Flow_Graph_Body_Spec_Depends_Mismatch |
        Flow_Graph_Refined_Depends_Missing_Source |
        Flow_Graph_Refined_Depends_Target_Not_Output |
        Flow_Graph_Refined_Depends_Source_Not_Input |
        Flow_Graph_Dependency_Cycle;
   end Depends_Error;

   function Propagation_Error (Status : Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status = Flow_Graph_Call_Effect_Not_Propagated;
   end Propagation_Error;

   function Generic_Error (Status : Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        Flow_Graph_Generic_Actual_Missing_Effect |
        Flow_Graph_Generic_Actual_Mode_Mismatch;
   end Generic_Error;

   function Tasking_Protected_Error (Status : Flow_Effect_Graph_Status) return Boolean is
   begin
      return Status in
        Flow_Graph_Protected_Function_Writes_State |
        Flow_Graph_Protected_Barrier_Reads_Uncovered_State |
        Flow_Graph_Task_Activation_Effect_Missing_Global;
   end Tasking_Protected_Error;

   function Status_For (Info : Flow_Effect_Context_Info) return Flow_Effect_Graph_Status is
   begin
      if Gate_Blocks (Info.Gate_Status) then
         return Flow_Graph_Coverage_Gate_Blocker;
      elsif Base_Dataflow_Error (Info.Base_Dataflow_Status) then
         return Flow_Graph_Linked_Dataflow_Error;
      elsif Info.Duplicate_Edge then
         return Flow_Graph_Duplicate_Edge;
      elsif Info.Dependency_Cycle then
         return Flow_Graph_Dependency_Cycle;
      elsif Info.Spec_Global_Mode = DGL.Global_Mode_Null and then
        (Info.Reads_Object or else Info.Writes_Object)
      then
         return Flow_Graph_Null_Global_Violated;
      elsif Info.Writes_Object and then Info.Spec_Global_Mode = DGL.Global_Mode_Not_Declared then
         return Flow_Graph_Write_Not_In_Global;
      elsif Info.Writes_Object and then not Allows_Write (Info.Spec_Global_Mode) then
         return Flow_Graph_Write_To_In_Global;
      elsif Info.Reads_Object and then Info.Spec_Global_Mode = DGL.Global_Mode_Not_Declared then
         return Flow_Graph_Read_Not_In_Global;
      elsif Info.Reads_Object and then not Allows_Read (Info.Spec_Global_Mode) then
         return Flow_Graph_Read_From_Out_Global;
      elsif Info.Kind = Flow_Context_Subprogram_Body and then
        Info.Body_Global_Mode /= DGL.Global_Mode_Not_Declared and then
        Info.Spec_Global_Mode /= DGL.Global_Mode_Not_Declared and then
        Info.Body_Global_Mode /= Info.Spec_Global_Mode
      then
         return Flow_Graph_Body_Spec_Global_Mismatch;
      elsif Info.Kind = Flow_Context_Refined_Global and then not Info.Refined_Global_Present then
         return Flow_Graph_Refined_Global_Missing_Item;
      elsif Info.Kind = Flow_Context_Refined_Depends and then not Info.Refined_Depends_Present then
         return Flow_Graph_Body_Spec_Depends_Mismatch;
      elsif Info.Edge = Flow_Edge_Depends and then not Allows_Read (Info.Source_Global_Mode) then
         return Flow_Graph_Refined_Depends_Source_Not_Input;
      elsif Info.Edge = Flow_Edge_Depends and then not Allows_Write (Info.Target_Global_Mode) then
         return Flow_Graph_Refined_Depends_Target_Not_Output;
      elsif Info.Edge = Flow_Edge_Call_Propagation and then not Info.Effect_Propagated then
         return Flow_Graph_Call_Effect_Not_Propagated;
      elsif Info.Edge = Flow_Edge_Generic_Substitution and then
        Info.Spec_Global_Mode /= DGL.Global_Mode_Not_Declared and then
        Info.Body_Global_Mode /= DGL.Global_Mode_Not_Declared and then
        Info.Spec_Global_Mode /= Info.Body_Global_Mode
      then
         return Flow_Graph_Generic_Actual_Mode_Mismatch;
      elsif Info.Edge = Flow_Edge_Generic_Substitution and then not Info.Effect_Propagated then
         return Flow_Graph_Generic_Actual_Missing_Effect;
      elsif Info.Protected_Function and then Info.Writes_Object then
         return Flow_Graph_Protected_Function_Writes_State;
      elsif Info.Protected_Barrier and then Info.Reads_Object and then not Allows_Read (Info.Spec_Global_Mode) then
         return Flow_Graph_Protected_Barrier_Reads_Uncovered_State;
      elsif Info.Task_Activation and then (Info.Reads_Object or else Info.Writes_Object) and then
        Info.Spec_Global_Mode = DGL.Global_Mode_Not_Declared
      then
         return Flow_Graph_Task_Activation_Effect_Missing_Global;
      end if;

      case Info.Edge is
         when Flow_Edge_Object_Read =>
            return Flow_Graph_Legal_Read_Edge;
         when Flow_Edge_Object_Write =>
            return Flow_Graph_Legal_Write_Edge;
         when Flow_Edge_Object_Read_Write =>
            return Flow_Graph_Legal_Read_Write_Edge;
         when Flow_Edge_Depends =>
            return Flow_Graph_Legal_Depends_Edge;
         when Flow_Edge_Call_Propagation =>
            return Flow_Graph_Legal_Call_Propagation;
         when Flow_Edge_Generic_Substitution =>
            return Flow_Graph_Legal_Generic_Substitution;
         when Flow_Edge_Protected_State =>
            return Flow_Graph_Legal_Protected_State_Effect;
         when Flow_Edge_Task_Activation =>
            return Flow_Graph_Legal_Task_Activation_Effect;
         when Flow_Edge_Refined_Global =>
            return Flow_Graph_Legal_Refined_Global;
         when Flow_Edge_Refined_Depends =>
            return Flow_Graph_Legal_Refined_Depends;
         when Flow_Edge_Null =>
            return Flow_Graph_Legal_Null_Effect;
         when Flow_Edge_Initialization | Flow_Edge_Finalization =>
            return Flow_Graph_Legal_Write_Edge;
         when Flow_Edge_Unknown =>
            return Flow_Graph_Indeterminate;
      end case;
   end Status_For;

   function Message_For (Status : Flow_Effect_Graph_Status) return Unbounded_String is
   begin
      case Status is
         when Flow_Graph_Legal_Read_Edge =>
            return To_Unbounded_String ("object read effect is covered by the flow graph");
         when Flow_Graph_Legal_Write_Edge =>
            return To_Unbounded_String ("object write effect is covered by the flow graph");
         when Flow_Graph_Legal_Read_Write_Edge =>
            return To_Unbounded_String ("read/write effect is covered by the flow graph");
         when Flow_Graph_Legal_Depends_Edge =>
            return To_Unbounded_String ("Depends edge is covered by input/output modes");
         when Flow_Graph_Legal_Call_Propagation =>
            return To_Unbounded_String ("callee effects are propagated to caller Global/Depends effects");
         when Flow_Graph_Legal_Generic_Substitution =>
            return To_Unbounded_String ("generic formal/actual flow effects are substituted");
         when Flow_Graph_Legal_Protected_State_Effect =>
            return To_Unbounded_String ("protected state effect is legal");
         when Flow_Graph_Legal_Task_Activation_Effect =>
            return To_Unbounded_String ("task activation effect is covered by Global effects");
         when Flow_Graph_Legal_Refined_Global =>
            return To_Unbounded_String ("Refined_Global covers the body effect");
         when Flow_Graph_Legal_Refined_Depends =>
            return To_Unbounded_String ("Refined_Depends covers the body dependency edge");
         when Flow_Graph_Coverage_Gate_Blocker =>
            return To_Unbounded_String ("coverage gate blocks confident flow-effect conclusion");
         when Flow_Graph_Linked_Dataflow_Error =>
            return To_Unbounded_String ("linked Global/Depends legality error blocks the flow graph");
         when Flow_Graph_Call_Effect_Not_Propagated =>
            return To_Unbounded_String ("callee effect is not propagated to caller effects");
         when Flow_Graph_Generic_Actual_Mode_Mismatch =>
            return To_Unbounded_String ("generic actual effect mode does not satisfy formal effect mode");
         when Flow_Graph_Protected_Function_Writes_State =>
            return To_Unbounded_String ("protected function writes protected state");
         when Flow_Graph_Task_Activation_Effect_Missing_Global =>
            return To_Unbounded_String ("task activation effect is missing from Global effects");
         when Flow_Graph_Indeterminate =>
            return To_Unbounded_String ("flow-effect graph legality is indeterminate");
         when others =>
            return To_Unbounded_String ("flow-effect graph legality error");
      end case;
   end Message_For;

   procedure Add_Row (Model : in out Flow_Effect_Graph_Model; Row : Flow_Effect_Info) is
   begin
      Model.Items.Append (Row);
      if Legal_Status (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Global_Error (Row.Status) then
         Model.Global_Error_Total := Model.Global_Error_Total + 1;
      end if;
      if Depends_Error (Row.Status) then
         Model.Depends_Error_Total := Model.Depends_Error_Total + 1;
      end if;
      if Propagation_Error (Row.Status) then
         Model.Propagation_Error_Total := Model.Propagation_Error_Total + 1;
      end if;
      if Generic_Error (Row.Status) then
         Model.Generic_Error_Total := Model.Generic_Error_Total + 1;
      end if;
      if Tasking_Protected_Error (Row.Status) then
         Model.Tasking_Protected_Error_Total := Model.Tasking_Protected_Error_Total + 1;
      end if;
      if Row.Status = Flow_Graph_Linked_Dataflow_Error then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      end if;
      if Row.Status = Flow_Graph_Coverage_Gate_Blocker then
         Model.Coverage_Gate_Error_Total := Model.Coverage_Gate_Error_Total + 1;
      end if;
      if Row.Status = Flow_Graph_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Add_Row;

   procedure Clear (Model : in out Flow_Effect_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Flow_Effect_Context_Model; Info : Flow_Effect_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   procedure Add_From_Dataflow_Row
     (Model : in out Flow_Effect_Context_Model;
      Row   : DGL.Dataflow_Legality_Info)
   is
      C : Flow_Effect_Context_Info;
   begin
      C.Id := Flow_Edge_Id (Natural (Row.Id));
      C.Kind := Flow_Context_Subprogram_Body;
      C.Node := Row.Node;
      C.Source_Node := Row.Source_Node;
      C.Target_Node := Row.Target_Node;
      C.Object_Name := Row.Object_Name;
      C.Source_Name := Row.Source_Name;
      C.Target_Name := Row.Target_Name;
      C.Spec_Global_Mode := Row.Declared_Global_Mode;
      C.Source_Global_Mode := Row.Source_Global_Mode;
      C.Target_Global_Mode := Row.Target_Global_Mode;
      C.Reads_Object := Row.Effect in DGL.Dataflow_Effect_Read | DGL.Dataflow_Effect_Read_Write;
      C.Writes_Object := Row.Effect in DGL.Dataflow_Effect_Write | DGL.Dataflow_Effect_Read_Write;
      C.Base_Dataflow_Status := Row.Status;
      C.Start_Line := Row.Start_Line;
      C.Start_Column := Row.Start_Column;
      C.End_Line := Row.End_Line;
      C.End_Column := Row.End_Column;
      C.Source_Fingerprint := Row.Fingerprint;
      case Row.Effect is
         when DGL.Dataflow_Effect_Read =>
            C.Edge := Flow_Edge_Object_Read;
         when DGL.Dataflow_Effect_Write =>
            C.Edge := Flow_Edge_Object_Write;
         when DGL.Dataflow_Effect_Read_Write =>
            C.Edge := Flow_Edge_Object_Read_Write;
         when DGL.Dataflow_Effect_Depends_Edge =>
            C.Edge := Flow_Edge_Depends;
         when DGL.Dataflow_Effect_Refinement =>
            C.Edge := Flow_Edge_Refined_Global;
            C.Kind := Flow_Context_Refined_Global;
         when DGL.Dataflow_Effect_Null =>
            C.Edge := Flow_Edge_Null;
         when DGL.Dataflow_Effect_Unknown =>
            C.Edge := Flow_Edge_Unknown;
      end case;
      Add_Context (Model, C);
   end Add_From_Dataflow_Row;

   function Context_Count (Model : Flow_Effect_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Flow_Effect_Context_Model;
      Index : Positive) return Flow_Effect_Context_Info is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Flow_Effect_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Flow_Effect_Context_Model) return Flow_Effect_Graph_Model is
      Model : Flow_Effect_Graph_Model;
      Next  : Flow_Edge_Id := 1;
   begin
      for C of Contexts.Items loop
         declare
            R : Flow_Effect_Info;
         begin
            R.Id := Next;
            R.Kind := C.Kind;
            R.Edge := C.Edge;
            R.Status := Status_For (C);
            R.Node := C.Node;
            R.Source_Node := C.Source_Node;
            R.Target_Node := C.Target_Node;
            R.Object_Name := C.Object_Name;
            R.Source_Name := C.Source_Name;
            R.Target_Name := C.Target_Name;
            R.Caller_Name := C.Caller_Name;
            R.Callee_Name := C.Callee_Name;
            R.Formal_Name := C.Formal_Name;
            R.Actual_Name := C.Actual_Name;
            R.Spec_Global_Mode := C.Spec_Global_Mode;
            R.Body_Global_Mode := C.Body_Global_Mode;
            R.Source_Global_Mode := C.Source_Global_Mode;
            R.Target_Global_Mode := C.Target_Global_Mode;
            R.Base_Dataflow_Status := C.Base_Dataflow_Status;
            R.Gate_Status := C.Gate_Status;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Message := Message_For (R.Status);
            R.Detail := To_Unbounded_String (Flow_Edge_Kind'Image (R.Edge));
            R.Fingerprint := Row_Fingerprint (R);
            Add_Row (Model, R);
            Next := Next + 1;
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Fingerprint (Contexts));
      return Model;
   end Build;

   function Build_From_Dataflow
     (Dataflow : DGL.Dataflow_Legality_Model) return Flow_Effect_Graph_Model
   is
      Contexts : Flow_Effect_Context_Model;
   begin
      for I in 1 .. DGL.Row_Count (Dataflow) loop
         Add_From_Dataflow_Row (Contexts, DGL.Row_At (Dataflow, I));
      end loop;
      return Build (Contexts);
   end Build_From_Dataflow;

   function Row_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Flow_Effect_Graph_Model;
      Index : Positive) return Flow_Effect_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Flow_Effect_Graph_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Flow_Effect_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Flow_Effect_Graph_Model;
      Status : Flow_Effect_Graph_Status) return Flow_Effect_Set is
      Set : Flow_Effect_Set;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Flow_Effect_Graph_Model;
      Kind  : Flow_Graph_Context_Kind) return Flow_Effect_Set is
      Set : Flow_Effect_Set;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Edge
     (Model : Flow_Effect_Graph_Model;
      Edge  : Flow_Edge_Kind) return Flow_Effect_Set is
      Set : Flow_Effect_Set;
   begin
      for R of Model.Items loop
         if R.Edge = Edge then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Edge;

   function Rows_For_Object
     (Model : Flow_Effect_Graph_Model;
      Name  : String) return Flow_Effect_Set is
      Set : Flow_Effect_Set;
   begin
      for R of Model.Items loop
         if To_String (R.Object_Name) = Name then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Object;

   function Set_Count (Set : Flow_Effect_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Flow_Effect_Set;
      Index : Positive) return Flow_Effect_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Flow_Effect_Graph_Model;
      Status : Flow_Effect_Graph_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Flow_Effect_Graph_Model;
      Kind  : Flow_Graph_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Edge
     (Model : Flow_Effect_Graph_Model;
      Edge  : Flow_Edge_Kind) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Edge = Edge then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Edge;

   function Legal_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Global_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Propagation_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Propagation_Error_Total;
   end Propagation_Error_Count;

   function Generic_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Generic_Error_Total;
   end Generic_Error_Count;

   function Tasking_Protected_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Tasking_Protected_Error_Total;
   end Tasking_Protected_Error_Count;

   function Linked_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Coverage_Gate_Error_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Coverage_Gate_Error_Total;
   end Coverage_Gate_Error_Count;

   function Indeterminate_Count (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Flow_Effect_Graph_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Flow_Effect_Graph_Legality;
