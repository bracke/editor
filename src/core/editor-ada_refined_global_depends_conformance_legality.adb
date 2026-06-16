with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Editor.Ada_Refined_Global_Depends_Conformance_Legality is

   pragma Suppress (Overflow_Check);

   package Engines renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   use type DGL.Global_Mode;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Flow.Flow_Effect_Graph_Status;

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

   function Allows_Read (Mode : DGL.Global_Mode) return Boolean is
   begin
      return Mode in DGL.Global_Mode_In | DGL.Global_Mode_In_Out | DGL.Global_Mode_Proof_In;
   end Allows_Read;

   function Allows_Write (Mode : DGL.Global_Mode) return Boolean is
   begin
      return Mode in DGL.Global_Mode_Out | DGL.Global_Mode_In_Out;
   end Allows_Write;

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

   function Feedback_Blocks (Info : Refined_Context_Info) return Boolean is
   begin
      if not Info.Coverage_Eligible then
         return True;
      end if;
      return Info.Coverage_Feedback in
        Feedback.Feedback_Cross_Unit_Still_Required |
        Feedback.Feedback_Original_Semantic_Error_Preserved |
        Feedback.Feedback_Partial_Repair_Blocker |
        Feedback.Feedback_Missing_Repair_Blocker |
        Feedback.Feedback_Repair_Mismatch_Blocker |
        Feedback.Feedback_Indeterminate |
        Feedback.Feedback_Stale_Rejected;
   end Feedback_Blocks;

   function Context_Fingerprint (Info : Refined_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Refined_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Refined_Effect_Kind'Pos (Info.Effect) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Body_Node) + 1);
      H := Mix (H, Natural (Info.Spec_Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Subprogram_Name));
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, DGL.Global_Mode'Pos (Info.Spec_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Body_Effect_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Refined_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Source_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Target_Global_Mode) + 1);
      if Info.Reads_Object then H := Mix (H, 3); end if;
      if Info.Writes_Object then H := Mix (H, 5); end if;
      if Info.Spec_Global_Present then H := Mix (H, 7); end if;
      if Info.Body_Effect_Present then H := Mix (H, 11); end if;
      if Info.Refined_Global_Present then H := Mix (H, 13); end if;
      if Info.Spec_Depends_Present then H := Mix (H, 17); end if;
      if Info.Body_Depends_Present then H := Mix (H, 19); end if;
      if Info.Refined_Depends_Present then H := Mix (H, 23); end if;
      if Info.Refined_Item_Is_Extra then H := Mix (H, 29); end if;
      if Info.Refined_Depends_Is_Extra then H := Mix (H, 31); end if;
      if Info.Effect_Propagated then H := Mix (H, 37); end if;
      H := Mix (H, Flow.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, Feedback.Feedback_Status'Pos (Info.Coverage_Feedback) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Refined_Conformance_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Refined_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Refined_Effect_Kind'Pos (Info.Effect) + 1);
      H := Mix (H, Refined_Conformance_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Text_Hash (Info.Subprogram_Name));
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, DGL.Global_Mode'Pos (Info.Spec_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Body_Effect_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Refined_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Source_Global_Mode) + 1);
      H := Mix (H, DGL.Global_Mode'Pos (Info.Target_Global_Mode) + 1);
      H := Mix (H, Flow.Flow_Effect_Graph_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, Feedback.Feedback_Status'Pos (Info.Coverage_Feedback) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Is_Legal (Status : Refined_Conformance_Status) return Boolean is
   begin
      return Status in
        Refined_Conformance_Legal_Global_Refinement |
        Refined_Conformance_Legal_Depends_Refinement |
        Refined_Conformance_Legal_Null_Refinement |
        Refined_Conformance_Legal_Call_Effect_Propagation;
   end Is_Legal;

   function Is_Global_Error (Status : Refined_Conformance_Status) return Boolean is
   begin
      return Status in
        Refined_Conformance_Body_Read_Missing_From_Spec_Global |
        Refined_Conformance_Body_Write_Missing_From_Spec_Global |
        Refined_Conformance_Body_Read_Missing_From_Refined_Global |
        Refined_Conformance_Body_Write_Missing_From_Refined_Global |
        Refined_Conformance_Refined_Global_Extra_Item |
        Refined_Conformance_Refined_Global_Mode_Mismatch;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Refined_Conformance_Status) return Boolean is
   begin
      return Status in
        Refined_Conformance_Refined_Depends_Missing_Edge |
        Refined_Conformance_Refined_Depends_Extra_Edge |
        Refined_Conformance_Refined_Depends_Source_Not_Spec_Input |
        Refined_Conformance_Refined_Depends_Target_Not_Spec_Output |
        Refined_Conformance_Body_Depends_Not_Refined;
   end Is_Depends_Error;

   function Status_For (Info : Refined_Context_Info) return Refined_Conformance_Status is
   begin
      if Feedback_Blocks (Info) then
         return Refined_Conformance_Coverage_Feedback_Blocker;
      elsif not Flow_Is_Legal (Info.Flow_Status) then
         return Refined_Conformance_Linked_Flow_Graph_Error;
      elsif Info.Effect = Refined_Effect_Call_Propagation and then not Info.Effect_Propagated then
         return Refined_Conformance_Call_Effect_Not_Propagated;
      elsif Info.Effect = Refined_Effect_Null then
         if Info.Reads_Object or else Info.Writes_Object then
            return Refined_Conformance_Body_Read_Missing_From_Spec_Global;
         else
            return Refined_Conformance_Legal_Null_Refinement;
         end if;
      elsif Info.Effect = Refined_Effect_Depends_Edge then
         if Info.Refined_Depends_Is_Extra then
            return Refined_Conformance_Refined_Depends_Extra_Edge;
         elsif Info.Body_Depends_Present and then not Info.Refined_Depends_Present then
            return Refined_Conformance_Refined_Depends_Missing_Edge;
         elsif not Info.Body_Depends_Present and then Info.Refined_Depends_Present then
            return Refined_Conformance_Refined_Depends_Extra_Edge;
         elsif not Allows_Read (Info.Source_Global_Mode) then
            return Refined_Conformance_Refined_Depends_Source_Not_Spec_Input;
         elsif not Allows_Write (Info.Target_Global_Mode) then
            return Refined_Conformance_Refined_Depends_Target_Not_Spec_Output;
         elsif Info.Spec_Depends_Present and then not Info.Refined_Depends_Present then
            return Refined_Conformance_Body_Depends_Not_Refined;
         else
            return Refined_Conformance_Legal_Depends_Refinement;
         end if;
      elsif Info.Effect = Refined_Effect_Call_Propagation then
         return Refined_Conformance_Legal_Call_Effect_Propagation;
      end if;

      if Info.Refined_Item_Is_Extra then
         return Refined_Conformance_Refined_Global_Extra_Item;
      elsif Info.Reads_Object and then (not Info.Spec_Global_Present or else not Allows_Read (Info.Spec_Global_Mode)) then
         return Refined_Conformance_Body_Read_Missing_From_Spec_Global;
      elsif Info.Writes_Object and then (not Info.Spec_Global_Present or else not Allows_Write (Info.Spec_Global_Mode)) then
         return Refined_Conformance_Body_Write_Missing_From_Spec_Global;
      elsif Info.Reads_Object and then (not Info.Refined_Global_Present or else not Allows_Read (Info.Refined_Global_Mode)) then
         return Refined_Conformance_Body_Read_Missing_From_Refined_Global;
      elsif Info.Writes_Object and then (not Info.Refined_Global_Present or else not Allows_Write (Info.Refined_Global_Mode)) then
         return Refined_Conformance_Body_Write_Missing_From_Refined_Global;
      elsif Info.Refined_Global_Mode /= DGL.Global_Mode_Not_Declared and then
        Info.Spec_Global_Mode /= DGL.Global_Mode_Not_Declared and then
        Info.Refined_Global_Mode /= Info.Spec_Global_Mode
      then
         if (Allows_Read (Info.Refined_Global_Mode) and then not Allows_Read (Info.Spec_Global_Mode))
           or else (Allows_Write (Info.Refined_Global_Mode) and then not Allows_Write (Info.Spec_Global_Mode))
         then
            return Refined_Conformance_Refined_Global_Mode_Mismatch;
         end if;
      end if;

      if Info.Effect in Refined_Effect_Read | Refined_Effect_Write | Refined_Effect_Read_Write |
        Refined_Effect_Generic_Substitution | Refined_Effect_Task_Protected_State
      then
         return Refined_Conformance_Legal_Global_Refinement;
      end if;

      return Refined_Conformance_Indeterminate;
   end Status_For;

   function Message_For (Status : Refined_Conformance_Status) return Unbounded_String is
   begin
      case Status is
         when Refined_Conformance_Legal_Global_Refinement =>
            return To_Unbounded_String ("body Global effect conforms to spec and Refined_Global");
         when Refined_Conformance_Legal_Depends_Refinement =>
            return To_Unbounded_String ("body Depends edge conforms to spec and Refined_Depends");
         when Refined_Conformance_Legal_Null_Refinement =>
            return To_Unbounded_String ("null Global/Depends refinement has no body effect");
         when Refined_Conformance_Legal_Call_Effect_Propagation =>
            return To_Unbounded_String ("call effect is propagated through refined body contracts");
         when Refined_Conformance_Body_Read_Missing_From_Spec_Global =>
            return To_Unbounded_String ("body read is not covered by the spec Global contract");
         when Refined_Conformance_Body_Write_Missing_From_Spec_Global =>
            return To_Unbounded_String ("body write is not covered by the spec Global contract");
         when Refined_Conformance_Body_Read_Missing_From_Refined_Global =>
            return To_Unbounded_String ("body read is not covered by Refined_Global");
         when Refined_Conformance_Body_Write_Missing_From_Refined_Global =>
            return To_Unbounded_String ("body write is not covered by Refined_Global");
         when Refined_Conformance_Refined_Global_Extra_Item =>
            return To_Unbounded_String ("Refined_Global item has no matching body effect");
         when Refined_Conformance_Refined_Global_Mode_Mismatch =>
            return To_Unbounded_String ("Refined_Global mode is not permitted by the spec Global mode");
         when Refined_Conformance_Refined_Depends_Missing_Edge =>
            return To_Unbounded_String ("body dependency edge is missing from Refined_Depends");
         when Refined_Conformance_Refined_Depends_Extra_Edge =>
            return To_Unbounded_String ("Refined_Depends edge has no matching body dependency");
         when Refined_Conformance_Refined_Depends_Source_Not_Spec_Input =>
            return To_Unbounded_String ("Refined_Depends source is not a spec Global input");
         when Refined_Conformance_Refined_Depends_Target_Not_Spec_Output =>
            return To_Unbounded_String ("Refined_Depends target is not a spec Global output");
         when Refined_Conformance_Body_Depends_Not_Refined =>
            return To_Unbounded_String ("body dependency is not refined by Refined_Depends");
         when Refined_Conformance_Call_Effect_Not_Propagated =>
            return To_Unbounded_String ("callee effects are not propagated into refined body effects");
         when Refined_Conformance_Linked_Flow_Graph_Error =>
            return To_Unbounded_String ("linked flow-effect graph error blocks refinement conformance");
         when Refined_Conformance_Coverage_Feedback_Blocker =>
            return To_Unbounded_String ("repaired coverage feedback blocks refined Global/Depends conformance");
         when Refined_Conformance_Indeterminate =>
            return To_Unbounded_String ("refined Global/Depends conformance is indeterminate");
         when Refined_Conformance_Not_Checked =>
            return To_Unbounded_String ("refined Global/Depends conformance not checked");
      end case;
   end Message_For;

   procedure Add_Row (Model : in out Refined_Conformance_Model; Row : Refined_Conformance_Info) is
   begin
      Model.Items.Append (Row);
      if Is_Legal (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Is_Global_Error (Row.Status) then
         Model.Global_Error_Total := Model.Global_Error_Total + 1;
      end if;
      if Is_Depends_Error (Row.Status) then
         Model.Depends_Error_Total := Model.Depends_Error_Total + 1;
      end if;
      if Row.Status = Refined_Conformance_Linked_Flow_Graph_Error then
         Model.Flow_Linked_Error_Total := Model.Flow_Linked_Error_Total + 1;
      end if;
      if Row.Status = Refined_Conformance_Coverage_Feedback_Blocker then
         Model.Coverage_Feedback_Error_Total := Model.Coverage_Feedback_Error_Total + 1;
      end if;
      if Row.Status = Refined_Conformance_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Add_Row;

   procedure Clear (Model : in out Refined_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Refined_Context_Model;
      Info  : Refined_Context_Info) is
   begin
      Model.Items.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   procedure Add_From_Flow_Row
     (Model    : in out Refined_Context_Model;
      Row      : Flow.Flow_Effect_Info;
      Feedback : Editor.Ada_Repaired_Coverage_Semantic_Feedback.Feedback_Model)
   is
      C : Refined_Context_Info;
      FB : constant Editor.Ada_Repaired_Coverage_Semantic_Feedback.Feedback_Info :=
        Editor.Ada_Repaired_Coverage_Semantic_Feedback.First_For_Node (Feedback, Row.Node);
   begin
      C.Id := Refined_Conformance_Id (Natural (Row.Id));
      C.Node := Row.Node;
      C.Body_Node := Row.Node;
      C.Source_Node := Row.Source_Node;
      C.Target_Node := Row.Target_Node;
      C.Subprogram_Name := Row.Caller_Name;
      if Length (C.Subprogram_Name) = 0 then
         C.Subprogram_Name := Row.Callee_Name;
      end if;
      C.Object_Name := Row.Object_Name;
      C.Source_Name := Row.Source_Name;
      C.Target_Name := Row.Target_Name;
      C.Spec_Global_Mode := Row.Spec_Global_Mode;
      C.Body_Effect_Mode := Row.Body_Global_Mode;
      C.Refined_Global_Mode := Row.Spec_Global_Mode;
      C.Source_Global_Mode := Row.Source_Global_Mode;
      C.Target_Global_Mode := Row.Target_Global_Mode;
      C.Reads_Object := Row.Edge in Flow.Flow_Edge_Object_Read | Flow.Flow_Edge_Object_Read_Write;
      C.Writes_Object := Row.Edge in Flow.Flow_Edge_Object_Write | Flow.Flow_Edge_Object_Read_Write |
        Flow.Flow_Edge_Initialization | Flow.Flow_Edge_Finalization;
      C.Spec_Global_Present := Row.Spec_Global_Mode /= DGL.Global_Mode_Not_Declared;
      C.Refined_Global_Present := Row.Spec_Global_Mode /= DGL.Global_Mode_Not_Declared;
      C.Refined_Depends_Present := Row.Status /= Flow.Flow_Graph_Refined_Depends_Missing_Source;
      C.Effect_Propagated := Row.Status /= Flow.Flow_Graph_Call_Effect_Not_Propagated;
      C.Flow_Status := Row.Status;
      C.Coverage_Feedback := FB.Feedback;
      C.Coverage_Eligible :=
        Editor.Ada_Repaired_Coverage_Semantic_Feedback.Row_Count (Feedback) = 0
        or else Editor.Ada_Repaired_Coverage_Semantic_Feedback.Is_Eligible_For_Engine
          (Feedback, Row.Node, Engines.Engine_Dataflow_Global_Depends);
      C.Start_Line := Row.Start_Line;
      C.Start_Column := Row.Start_Column;
      C.End_Line := Row.End_Line;
      C.End_Column := Row.End_Column;
      C.Source_Fingerprint := Row.Fingerprint;

      case Row.Kind is
         when Flow.Flow_Context_Subprogram_Body =>
            C.Kind := Refined_Context_Subprogram_Body;
         when Flow.Flow_Context_Refined_Global =>
            C.Kind := Refined_Context_Refined_Global_Item;
         when Flow.Flow_Context_Refined_Depends =>
            C.Kind := Refined_Context_Refined_Depends_Edge;
         when Flow.Flow_Context_Call =>
            C.Kind := Refined_Context_Call_Propagation;
         when Flow.Flow_Context_Generic_Formal_Actual =>
            C.Kind := Refined_Context_Generic_Instance_Body;
         when Flow.Flow_Context_Protected_Function | Flow.Flow_Context_Protected_Procedure |
              Flow.Flow_Context_Protected_Entry | Flow.Flow_Context_Task_Body =>
            C.Kind := Refined_Context_Task_Protected_Body;
         when Flow.Flow_Context_Package_Elaboration =>
            C.Kind := Refined_Context_Package_Body;
         when others =>
            C.Kind := Refined_Context_Unknown;
      end case;

      case Row.Edge is
         when Flow.Flow_Edge_Object_Read =>
            C.Effect := Refined_Effect_Read;
         when Flow.Flow_Edge_Object_Write | Flow.Flow_Edge_Initialization | Flow.Flow_Edge_Finalization =>
            C.Effect := Refined_Effect_Write;
         when Flow.Flow_Edge_Object_Read_Write =>
            C.Effect := Refined_Effect_Read_Write;
         when Flow.Flow_Edge_Depends | Flow.Flow_Edge_Refined_Depends =>
            C.Effect := Refined_Effect_Depends_Edge;
         when Flow.Flow_Edge_Call_Propagation =>
            C.Effect := Refined_Effect_Call_Propagation;
         when Flow.Flow_Edge_Generic_Substitution =>
            C.Effect := Refined_Effect_Generic_Substitution;
         when Flow.Flow_Edge_Protected_State | Flow.Flow_Edge_Task_Activation =>
            C.Effect := Refined_Effect_Task_Protected_State;
         when Flow.Flow_Edge_Null =>
            C.Effect := Refined_Effect_Null;
         when others =>
            C.Effect := Refined_Effect_Unknown;
      end case;

      Add_Context (Model, C);
   end Add_From_Flow_Row;

   function Context_Count (Model : Refined_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Refined_Context_Model;
      Index : Positive) return Refined_Context_Info is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Refined_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Refined_Context_Model) return Refined_Conformance_Model is
      Model : Refined_Conformance_Model;
      Next  : Refined_Conformance_Id := 1;
   begin
      for C of Contexts.Items loop
         declare
            R : Refined_Conformance_Info;
         begin
            R.Id := Next;
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Effect := C.Effect;
            R.Status := Status_For (C);
            R.Node := C.Node;
            R.Body_Node := C.Body_Node;
            R.Spec_Node := C.Spec_Node;
            R.Source_Node := C.Source_Node;
            R.Target_Node := C.Target_Node;
            R.Subprogram_Name := C.Subprogram_Name;
            R.Object_Name := C.Object_Name;
            R.Source_Name := C.Source_Name;
            R.Target_Name := C.Target_Name;
            R.Spec_Global_Mode := C.Spec_Global_Mode;
            R.Body_Effect_Mode := C.Body_Effect_Mode;
            R.Refined_Global_Mode := C.Refined_Global_Mode;
            R.Source_Global_Mode := C.Source_Global_Mode;
            R.Target_Global_Mode := C.Target_Global_Mode;
            R.Flow_Status := C.Flow_Status;
            R.Coverage_Feedback := C.Coverage_Feedback;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Message := Message_For (R.Status);
            R.Detail := To_Unbounded_String
              (Refined_Effect_Kind'Image (R.Effect) & ":" & DGL.Global_Mode'Image (R.Spec_Global_Mode));
            R.Fingerprint := Row_Fingerprint (R);
            Add_Row (Model, R);
            Next := Next + 1;
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Fingerprint (Contexts));
      return Model;
   end Build;

   function Build_From_Flow_Graph
     (Graph    : Flow.Flow_Effect_Graph_Model;
      Feedback : Editor.Ada_Repaired_Coverage_Semantic_Feedback.Feedback_Model)
      return Refined_Conformance_Model
   is
      Contexts : Refined_Context_Model;
   begin
      for I in 1 .. Flow.Row_Count (Graph) loop
         Add_From_Flow_Row (Contexts, Flow.Row_At (Graph, I), Feedback);
      end loop;
      return Build (Contexts);
   end Build_From_Flow_Graph;

   function Row_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At
     (Model : Refined_Conformance_Model;
      Index : Positive) return Refined_Conformance_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Refined_Conformance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Refined_Conformance_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Refined_Conformance_Model;
      Status : Refined_Conformance_Status) return Refined_Conformance_Set is
      Set : Refined_Conformance_Set;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Refined_Conformance_Model;
      Kind  : Refined_Context_Kind) return Refined_Conformance_Set is
      Set : Refined_Conformance_Set;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model : Refined_Conformance_Model;
      Name  : String) return Refined_Conformance_Set is
      Set : Refined_Conformance_Set;
   begin
      for R of Model.Items loop
         if To_String (R.Object_Name) = Name
           or else To_String (R.Source_Name) = Name
           or else To_String (R.Target_Name) = Name
         then
            Set.Items.Append (R);
         end if;
      end loop;
      return Set;
   end Rows_For_Object;

   function Set_Count (Set : Refined_Conformance_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Refined_Conformance_Set;
      Index : Positive) return Refined_Conformance_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Refined_Conformance_Model;
      Status : Refined_Conformance_Status) return Natural is
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
     (Model : Refined_Conformance_Model;
      Kind  : Refined_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Global_Error_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Flow_Linked_Error_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Flow_Linked_Error_Total;
   end Flow_Linked_Error_Count;

   function Coverage_Feedback_Error_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Coverage_Feedback_Error_Total;
   end Coverage_Feedback_Error_Count;

   function Indeterminate_Count (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Refined_Conformance_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Refined_Global_Depends_Conformance_Legality;
