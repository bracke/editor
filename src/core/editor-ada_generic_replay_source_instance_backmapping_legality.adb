with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality is


   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Replay_CPD.Generic_Replay_Representation_Row_Id;
   use type Overload_Edge.Overload_Type_Edge_Row_Id;
   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16#1003# + Right * 97 + 17) mod 2_147_483_647;
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

   function Replay_Is_Legal (Status : Replay.Replay_Status) return Boolean is
   begin
      case Status is
         when Replay.Replay_Legal_Substituted_Declaration |
              Replay.Replay_Legal_Substituted_Statement |
              Replay.Replay_Legal_Substituted_Expression |
              Replay.Replay_Legal_Call |
              Replay.Replay_Legal_Flow_Effect |
              Replay.Replay_Legal_Predicate_Invariant |
              Replay.Replay_Legal_Accessibility |
              Replay.Replay_Legal_Representation_Freezing |
              Replay.Replay_Legal_Nested_Instance =>
            return True;
         when others =>
            return False;
      end case;
   end Replay_Is_Legal;

   function Legal_Status_For_Kind (Kind : Generic_Backmap_Context_Kind) return Generic_Backmap_Status is
   begin
      case Kind is
         when Generic_Backmap_Declaration_Replay =>
            return Generic_Backmap_Legal_Declaration_Backmapped;
         when Generic_Backmap_Statement_Replay =>
            return Generic_Backmap_Legal_Statement_Backmapped;
         when Generic_Backmap_Expression_Replay =>
            return Generic_Backmap_Legal_Expression_Backmapped;
         when Generic_Backmap_Call_Replay =>
            return Generic_Backmap_Legal_Call_Backmapped;
         when Generic_Backmap_Return_Replay =>
            return Generic_Backmap_Legal_Return_Backmapped;
         when Generic_Backmap_Assignment_Replay =>
            return Generic_Backmap_Legal_Assignment_Backmapped;
         when Generic_Backmap_Representation_Replay =>
            return Generic_Backmap_Legal_Representation_Backmapped;
         when Generic_Backmap_Flow_Replay =>
            return Generic_Backmap_Legal_Flow_Backmapped;
         when Generic_Backmap_Predicate_Replay =>
            return Generic_Backmap_Legal_Predicate_Backmapped;
         when Generic_Backmap_Accessibility_Replay =>
            return Generic_Backmap_Legal_Accessibility_Backmapped;
         when Generic_Backmap_Nested_Instance_Replay =>
            return Generic_Backmap_Legal_Nested_Instance_Backmapped;
         when others =>
            return Generic_Backmap_Indeterminate;
      end case;
   end Legal_Status_For_Kind;

   function Status_From_Replay (Status : Replay.Replay_Status) return Generic_Backmap_Status is
   begin
      case Status is
         when Replay.Replay_Source_Instance_Mapping_Missing =>
            return Generic_Backmap_Missing_Source_Instance_Map;
         when Replay.Replay_Formal_Actual_Mapping_Missing =>
            return Generic_Backmap_Missing_Formal_Actual_Map;
         when Replay.Replay_Diagnostic_Backmap_Missing =>
            return Generic_Backmap_Missing_Diagnostic_Backmap;
         when Replay.Replay_Not_Checked | Replay.Replay_Indeterminate =>
            return Generic_Backmap_Indeterminate;
         when others =>
            return Generic_Backmap_Base_Replay_Error;
      end case;
   end Status_From_Replay;

   function Status_From_Replay_CPD
     (Status : Replay_CPD.Generic_Replay_Representation_Status) return Generic_Backmap_Status is
   begin
      if Replay_CPD.Is_Legal (Status) then
         return Generic_Backmap_Not_Checked;
      end if;

      case Status is
         when Replay_CPD.Generic_Replay_Representation_Not_Checked |
              Replay_CPD.Generic_Replay_Representation_Missing_Representation_CPD_Row =>
            return Generic_Backmap_Missing_Replay_CPD_Row;
         when Replay_CPD.Generic_Replay_Representation_Representation_CPD_Indeterminate |
              Replay_CPD.Generic_Replay_Representation_Indeterminate =>
            return Generic_Backmap_Replay_CPD_Indeterminate;
         when others =>
            return Generic_Backmap_Replay_CPD_Blocker;
      end case;
   end Status_From_Replay_CPD;

   function Status_From_Overload
     (Status : Overload_Edge.Overload_Type_Edge_Status) return Generic_Backmap_Status is
   begin
      if Overload_Edge.Is_Legal (Status) then
         return Generic_Backmap_Not_Checked;
      elsif Overload_Edge.Is_Ambiguous (Status) then
         return Generic_Backmap_Overload_Type_Edge_Ambiguous;
      end if;

      case Status is
         when Overload_Edge.Overload_Type_Edge_Not_Checked |
              Overload_Edge.Overload_Type_Edge_Missing_Generic_Replay_CPD_Row =>
            return Generic_Backmap_Missing_Overload_Type_Edge_Row;
         when Overload_Edge.Overload_Type_Edge_Generic_Replay_CPD_Indeterminate |
              Overload_Edge.Overload_Type_Edge_Indeterminate =>
            return Generic_Backmap_Overload_Type_Edge_Indeterminate;
         when others =>
            return Generic_Backmap_Overload_Type_Edge_Blocker;
      end case;
   end Status_From_Overload;

   function Status_For (Info : Generic_Backmap_Context_Info) return Generic_Backmap_Status is
   begin
      if Info.Generic_Source_Node = Editor.Ada_Syntax_Tree.No_Node then
         return Generic_Backmap_Missing_Generic_Source_Node;
      elsif Info.Instance_Node = Editor.Ada_Syntax_Tree.No_Node then
         return Generic_Backmap_Missing_Instance_Node;
      elsif Info.Formal_Node = Editor.Ada_Syntax_Tree.No_Node then
         return Generic_Backmap_Missing_Formal_Node;
      elsif Info.Actual_Node = Editor.Ada_Syntax_Tree.No_Node then
         return Generic_Backmap_Missing_Actual_Node;
      elsif Info.Body_Node = Editor.Ada_Syntax_Tree.No_Node then
         return Generic_Backmap_Missing_Body_Node;
      elsif not Info.Source_Instance_Map_Present then
         return Generic_Backmap_Missing_Source_Instance_Map;
      elsif not Info.Formal_Actual_Map_Present then
         return Generic_Backmap_Missing_Formal_Actual_Map;
      elsif not Info.Diagnostic_Backmap_Present then
         return Generic_Backmap_Missing_Diagnostic_Backmap;
      elsif Info.Expected_Source_Fingerprint /= 0
        and then Info.Source_Fingerprint /= Info.Expected_Source_Fingerprint
      then
         return Generic_Backmap_Source_Instance_Fingerprint_Mismatch;
      elsif Info.Expected_Substitution_Fingerprint /= 0
        and then Info.Substitution_Fingerprint /= Info.Expected_Substitution_Fingerprint
      then
         return Generic_Backmap_Substitution_Fingerprint_Mismatch;
      elsif not Replay_Is_Legal (Info.Replay_Status) then
         return Status_From_Replay (Info.Replay_Status);
      elsif Info.Replay_CPD_Matches > 1 then
         return Generic_Backmap_Multiple_Matching_Replay_CPD_Rows;
      elsif Info.Replay_CPD_Row = Replay_CPD.No_Generic_Replay_Representation_Row then
         return Generic_Backmap_Missing_Replay_CPD_Row;
      elsif not Replay_CPD.Is_Legal (Info.Replay_CPD_Status) then
         return Status_From_Replay_CPD (Info.Replay_CPD_Status);
      elsif Info.Overload_Matches > 1 then
         return Generic_Backmap_Multiple_Matching_Overload_Rows;
      elsif Info.Overload_Row = Overload_Edge.No_Overload_Type_Edge_Row then
         return Generic_Backmap_Missing_Overload_Type_Edge_Row;
      elsif not Overload_Edge.Is_Legal (Info.Overload_Status) then
         return Status_From_Overload (Info.Overload_Status);
      else
         return Legal_Status_For_Kind (Info.Kind);
      end if;
   end Status_For;

   function Row_Fingerprint (Info : Generic_Backmap_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Generic_Backmap_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Generic_Backmap_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Generic_Source_Node) + 1);
      H := Mix (H, Natural (Info.Instance_Node) + 1);
      H := Mix (H, Natural (Info.Formal_Node) + 1);
      H := Mix (H, Natural (Info.Actual_Node) + 1);
      H := Mix (H, Natural (Info.Body_Node) + 1);
      H := Mix (H, Natural (Info.Substituted_Node) + 1);
      H := Mix (H, Text_Hash (Info.Generic_Unit_Name));
      H := Mix (H, Text_Hash (Info.Instance_Name));
      H := Mix (H, Text_Hash (Info.Formal_Name));
      H := Mix (H, Text_Hash (Info.Actual_Name));
      H := Mix (H, Natural (Info.Replay_Row) + 1);
      H := Mix (H, Replay.Replay_Status'Pos (Info.Replay_Status) + 1);
      H := Mix (H, Natural (Info.Replay_CPD_Row) + 1);
      H := Mix (H, Replay_CPD.Generic_Replay_Representation_Status'Pos (Info.Replay_CPD_Status) + 1);
      H := Mix (H, Natural (Info.Overload_Row) + 1);
      H := Mix (H, Overload_Edge.Overload_Type_Edge_Status'Pos (Info.Overload_Status) + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Generic_Backmap_Status) return Unbounded_String is
   begin
      case Status is
         when Generic_Backmap_Missing_Generic_Source_Node =>
            return To_Unbounded_String ("generic replay backmap is missing the generic body source node");
         when Generic_Backmap_Missing_Instance_Node =>
            return To_Unbounded_String ("generic replay backmap is missing the instantiation node");
         when Generic_Backmap_Missing_Formal_Node =>
            return To_Unbounded_String ("generic replay backmap is missing the formal declaration node");
         when Generic_Backmap_Missing_Actual_Node =>
            return To_Unbounded_String ("generic replay backmap is missing the actual node");
         when Generic_Backmap_Missing_Body_Node =>
            return To_Unbounded_String ("generic replay backmap is missing the substituted body node");
         when Generic_Backmap_Missing_Source_Instance_Map =>
            return To_Unbounded_String ("generic replay source-to-instance map is incomplete");
         when Generic_Backmap_Missing_Formal_Actual_Map =>
            return To_Unbounded_String ("generic replay formal-to-actual map is incomplete");
         when Generic_Backmap_Missing_Diagnostic_Backmap =>
            return To_Unbounded_String ("generic replay diagnostic backmap is incomplete");
         when Generic_Backmap_Source_Instance_Fingerprint_Mismatch =>
            return To_Unbounded_String ("generic replay source/instance fingerprint does not match");
         when Generic_Backmap_Substitution_Fingerprint_Mismatch =>
            return To_Unbounded_String ("generic replay substitution fingerprint does not match");
         when Generic_Backmap_Base_Replay_Error | Generic_Backmap_Replay_Mapping_Error =>
            return To_Unbounded_String ("generic replay row is already blocked before backmapping");
         when Generic_Backmap_Missing_Replay_CPD_Row =>
            return To_Unbounded_String ("generic replay backmap is missing replay CPD consumer evidence");
         when Generic_Backmap_Replay_CPD_Blocker =>
            return To_Unbounded_String ("generic replay CPD consumer evidence blocks source/instance backmapping");
         when Generic_Backmap_Missing_Overload_Type_Edge_Row =>
            return To_Unbounded_String ("generic replay backmap is missing overload/type edge evidence");
         when Generic_Backmap_Overload_Type_Edge_Blocker =>
            return To_Unbounded_String ("overload/type edge evidence blocks generic replay backmapping");
         when Generic_Backmap_Overload_Type_Edge_Ambiguous =>
            return To_Unbounded_String ("overload/type edge evidence remains ambiguous in generic replay backmapping");
         when Generic_Backmap_Indeterminate | Generic_Backmap_Replay_CPD_Indeterminate |
              Generic_Backmap_Overload_Type_Edge_Indeterminate =>
            return To_Unbounded_String ("generic replay source/instance backmapping is indeterminate");
         when others =>
            return To_Unbounded_String ("generic replay source/instance backmapping accepted");
      end case;
   end Message_For;

   procedure Clear (Model : in out Generic_Backmap_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Generic_Backmap_Context_Model;
      Info  : Generic_Backmap_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id) + Info.Source_Fingerprint + Info.Substitution_Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Generic_Backmap_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Generic_Backmap_Context_Model;
      Index : Positive) return Generic_Backmap_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Generic_Backmap_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Is_Legal (Status : Generic_Backmap_Status) return Boolean is
   begin
      case Status is
         when Generic_Backmap_Legal_Declaration_Backmapped |
              Generic_Backmap_Legal_Statement_Backmapped |
              Generic_Backmap_Legal_Expression_Backmapped |
              Generic_Backmap_Legal_Call_Backmapped |
              Generic_Backmap_Legal_Return_Backmapped |
              Generic_Backmap_Legal_Assignment_Backmapped |
              Generic_Backmap_Legal_Representation_Backmapped |
              Generic_Backmap_Legal_Flow_Backmapped |
              Generic_Backmap_Legal_Predicate_Backmapped |
              Generic_Backmap_Legal_Accessibility_Backmapped |
              Generic_Backmap_Legal_Nested_Instance_Backmapped =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Legal;

   function Is_Mapping_Error (Status : Generic_Backmap_Status) return Boolean is
   begin
      case Status is
         when Generic_Backmap_Missing_Generic_Source_Node |
              Generic_Backmap_Missing_Instance_Node |
              Generic_Backmap_Missing_Formal_Node |
              Generic_Backmap_Missing_Actual_Node |
              Generic_Backmap_Missing_Body_Node |
              Generic_Backmap_Missing_Source_Instance_Map |
              Generic_Backmap_Missing_Formal_Actual_Map |
              Generic_Backmap_Missing_Diagnostic_Backmap |
              Generic_Backmap_Source_Instance_Fingerprint_Mismatch |
              Generic_Backmap_Substitution_Fingerprint_Mismatch =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Mapping_Error;

   function Is_Replay_CPD_Error (Status : Generic_Backmap_Status) return Boolean is
   begin
      case Status is
         when Generic_Backmap_Missing_Replay_CPD_Row |
              Generic_Backmap_Replay_CPD_Blocker |
              Generic_Backmap_Replay_CPD_Indeterminate |
              Generic_Backmap_Multiple_Matching_Replay_CPD_Rows =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Replay_CPD_Error;

   function Is_Overload_Error (Status : Generic_Backmap_Status) return Boolean is
   begin
      case Status is
         when Generic_Backmap_Missing_Overload_Type_Edge_Row |
              Generic_Backmap_Overload_Type_Edge_Blocker |
              Generic_Backmap_Overload_Type_Edge_Ambiguous |
              Generic_Backmap_Overload_Type_Edge_Indeterminate |
              Generic_Backmap_Multiple_Matching_Overload_Rows =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Overload_Error;

   function Build (Contexts : Generic_Backmap_Context_Model) return Generic_Backmap_Model is
      Result : Generic_Backmap_Model;
   begin
      for C of Contexts.Contexts loop
         declare
            Row : Generic_Backmap_Info;
         begin
            Row.Id := C.Id;
            Row.Context := C.Id;
            Row.Kind := C.Kind;
            Row.Status := Status_For (C);
            Row.Node := C.Node;
            Row.Generic_Source_Node := C.Generic_Source_Node;
            Row.Instance_Node := C.Instance_Node;
            Row.Formal_Node := C.Formal_Node;
            Row.Actual_Node := C.Actual_Node;
            Row.Body_Node := C.Body_Node;
            Row.Substituted_Node := C.Substituted_Node;
            Row.Generic_Unit_Name := C.Generic_Unit_Name;
            Row.Instance_Name := C.Instance_Name;
            Row.Formal_Name := C.Formal_Name;
            Row.Actual_Name := C.Actual_Name;
            Row.Replay_Row := C.Replay_Row;
            Row.Replay_Status := C.Replay_Status;
            Row.Replay_CPD_Row := C.Replay_CPD_Row;
            Row.Replay_CPD_Status := C.Replay_CPD_Status;
            Row.Overload_Row := C.Overload_Row;
            Row.Overload_Status := C.Overload_Status;
            Row.Message := Message_For (Row.Status);
            Row.Detail := To_Unbounded_String ("generic source/instance/formal/actual/substitution backmap legality row");
            Row.Fingerprint := Row_Fingerprint (Row);
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);

            if Is_Legal (Row.Status) then
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               Result.Error_Total := Result.Error_Total + 1;
            end if;
            if Is_Mapping_Error (Row.Status) then
               Result.Mapping_Error_Total := Result.Mapping_Error_Total + 1;
            end if;
            if Row.Status = Generic_Backmap_Base_Replay_Error or else Row.Status = Generic_Backmap_Replay_Mapping_Error then
               Result.Replay_Error_Total := Result.Replay_Error_Total + 1;
            end if;
            if Is_Replay_CPD_Error (Row.Status) then
               Result.Replay_CPD_Error_Total := Result.Replay_CPD_Error_Total + 1;
            end if;
            if Is_Overload_Error (Row.Status) then
               Result.Overload_Error_Total := Result.Overload_Error_Total + 1;
            end if;
            if Row.Status = Generic_Backmap_Overload_Type_Edge_Ambiguous then
               Result.Ambiguous_Total := Result.Ambiguous_Total + 1;
            end if;
            if Row.Status = Generic_Backmap_Indeterminate or else
               Row.Status = Generic_Backmap_Replay_CPD_Indeterminate or else
               Row.Status = Generic_Backmap_Overload_Type_Edge_Indeterminate
            then
               Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Generic_Backmap_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Generic_Backmap_Model; Index : Positive) return Generic_Backmap_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function First_For_Node (Model : Generic_Backmap_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Backmap_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status (Model : Generic_Backmap_Model; Status : Generic_Backmap_Status) return Generic_Backmap_Set is
      Result : Generic_Backmap_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Instance (Model : Generic_Backmap_Model; Name : String) return Generic_Backmap_Set is
      Result : Generic_Backmap_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Instance_Name) = Name then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Result;
   end Rows_For_Instance;

   function Rows_For_Generic_Unit (Model : Generic_Backmap_Model; Name : String) return Generic_Backmap_Set is
      Result : Generic_Backmap_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Generic_Unit_Name) = Name then
            Result.Items.Append (Row);
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint + 1);
         end if;
      end loop;
      return Result;
   end Rows_For_Generic_Unit;

   function Set_Count (Set : Generic_Backmap_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Generic_Backmap_Set; Index : Positive) return Generic_Backmap_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Generic_Backmap_Model; Status : Generic_Backmap_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Generic_Backmap_Model) return Natural is (Model.Legal_Total);
   function Error_Count (Model : Generic_Backmap_Model) return Natural is (Model.Error_Total);
   function Mapping_Error_Count (Model : Generic_Backmap_Model) return Natural is (Model.Mapping_Error_Total);
   function Replay_Error_Count (Model : Generic_Backmap_Model) return Natural is (Model.Replay_Error_Total);
   function Replay_CPD_Error_Count (Model : Generic_Backmap_Model) return Natural is (Model.Replay_CPD_Error_Total);
   function Overload_Error_Count (Model : Generic_Backmap_Model) return Natural is (Model.Overload_Error_Total);
   function Ambiguous_Count (Model : Generic_Backmap_Model) return Natural is (Model.Ambiguous_Total);
   function Indeterminate_Count (Model : Generic_Backmap_Model) return Natural is (Model.Indeterminate_Total);
   function Fingerprint (Model : Generic_Backmap_Model) return Natural is (Model.Result_Fingerprint);

end Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
