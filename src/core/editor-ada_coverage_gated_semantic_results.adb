with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Coverage_Gated_Semantic_Results is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Gates.Semantic_Conclusion_Kind;
   use type Audit.Semantic_Consumer_Family;

   function Mix (Left, Right : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Left) * 137 + Long_Long_Integer (Right) * 23 + 1136)
        mod 2_147_483_647;
   begin
      return Natural (Hash);
   end Mix;

   function Node_Slot (Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural is
   begin
      return Natural (Node);
   exception
      when Constraint_Error => return 0;
   end Node_Slot;

   function Status_For
     (Original_State : Original_Result_State;
      Action         : Gates.Gate_Action) return Gated_Result_Status is
   begin
      if Original_State = Original_Result_Error then
         return Gated_Result_Original_Error_Preserved;
      end if;

      case Action is
         when Gates.Gate_Allow_Confident_Result =>
            return Gated_Result_Confident;
         when Gates.Gate_Degrade_To_Indeterminate =>
            return Gated_Result_Degraded_Indeterminate;
         when Gates.Gate_Suppress_Legal_Result =>
            return Gated_Result_Legal_Suppressed;
         when Gates.Gate_Suppress_Derived_Result =>
            return Gated_Result_Derived_Suppressed;
         when Gates.Gate_Require_Cross_Unit_Closure =>
            return Gated_Result_Cross_Unit_Required;
         when Gates.Gate_Require_Parser_AST_Repair =>
            return Gated_Result_Parser_AST_Repair_Required;
         when Gates.Gate_Require_Metadata_Repair =>
            return Gated_Result_Metadata_Repair_Required;
         when Gates.Gate_Require_Consumer_Integration =>
            return Gated_Result_Consumer_Integration_Required;
         when Gates.Gate_Block_Unsafe_Result =>
            return Gated_Result_Blocked_Unsafe;
      end case;
   end Status_For;

   function Message_For (Status : Gated_Result_Status) return String is
   begin
      case Status is
         when Gated_Result_Not_Checked =>
            return "semantic conclusion has not been coverage-gated";
         when Gated_Result_Confident =>
            return "semantic conclusion is coverage-complete and may remain confident";
         when Gated_Result_Degraded_Indeterminate =>
            return "semantic conclusion is degraded to indeterminate by coverage gate";
         when Gated_Result_Legal_Suppressed =>
            return "legal semantic conclusion is suppressed by incomplete coverage";
         when Gated_Result_Derived_Suppressed =>
            return "derived semantic conclusion is suppressed by incomplete coverage";
         when Gated_Result_Cross_Unit_Required =>
            return "semantic conclusion requires cross-unit coverage closure";
         when Gated_Result_Parser_AST_Repair_Required =>
            return "semantic conclusion requires parser or AST coverage repair";
         when Gated_Result_Metadata_Repair_Required =>
            return "semantic conclusion requires semantic metadata repair";
         when Gated_Result_Consumer_Integration_Required =>
            return "semantic conclusion requires consumer integration";
         when Gated_Result_Blocked_Unsafe =>
            return "unsafe semantic conclusion is blocked by coverage gate";
         when Gated_Result_Original_Error_Preserved =>
            return "original semantic error is preserved despite coverage gate";
      end case;
   end Message_For;

   function Detail_For (Context : Gated_Result_Context_Info; Status : Gated_Result_Status) return String is
   begin
      return "status=" & Gated_Result_Status'Image (Status) &
        "; conclusion=" & Gates.Semantic_Conclusion_Kind'Image (Context.Conclusion) &
        "; original=" & Original_Result_State'Image (Context.Original_State) &
        "; construct=" & Audit.Ada_Construct_Kind'Image (Context.Construct) &
        "; consumer=" & Audit.Semantic_Consumer_Family'Image (Context.Consumer) &
        "; gate_status=" & Gates.Gate_Status'Image (Context.Gate_Status) &
        "; gate_action=" & Gates.Gate_Action'Image (Context.Gate_Action) &
        "; semantic_row=" & Natural'Image (Context.Semantic_Row_Id);
   end Detail_For;

   function Row_Fingerprint (Row : Gated_Result_Info) return Natural is
      H : Natural := Row.Source_Fingerprint;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Gates.Semantic_Conclusion_Kind'Pos (Row.Conclusion) + 1);
      H := Mix (H, Original_Result_State'Pos (Row.Original_State) + 1);
      H := Mix (H, Audit.Ada_Construct_Kind'Pos (Row.Construct) + 1);
      H := Mix (H, Audit.Semantic_Consumer_Family'Pos (Row.Consumer) + 1);
      H := Mix (H, Gated_Result_Status'Pos (Row.Status) + 1);
      H := Mix (H, Gates.Gate_Status'Pos (Row.Gate_Status) + 1);
      H := Mix (H, Gates.Gate_Action'Pos (Row.Gate_Action) + 1);
      H := Mix (H, Node_Slot (Row.Node));
      H := Mix (H, Row.Semantic_Row_Id);
      H := Mix (H, Row.Start_Line);
      H := Mix (H, Row.Start_Column);
      return H;
   end Row_Fingerprint;

   function Build_Info (Context : Gated_Result_Context_Info) return Gated_Result_Info is
      Status : constant Gated_Result_Status :=
        Status_For (Context.Original_State, Context.Gate_Action);
      Row    : Gated_Result_Info;
   begin
      Row.Id := Context.Id;
      Row.Conclusion := Context.Conclusion;
      Row.Original_State := Context.Original_State;
      Row.Construct := Context.Construct;
      Row.Consumer := Context.Consumer;
      Row.Status := Status;
      Row.Gate_Status := Context.Gate_Status;
      Row.Gate_Action := Context.Gate_Action;
      Row.Gate_Id := Context.Gate_Id;
      Row.Node := Context.Node;
      Row.Parent_Node := Context.Parent_Node;
      Row.Semantic_Row_Id := Context.Semantic_Row_Id;
      Row.Construct_Name := Context.Construct_Name;
      Row.Normalized_Name := Context.Normalized_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Detail_For (Context, Status));
      if Length (Context.Gate_Message) > 0 then
         Row.Detail := Row.Detail & To_Unbounded_String ("; gate_message=") & Context.Gate_Message;
      end if;
      if Length (Context.Gate_Detail) > 0 then
         Row.Detail := Row.Detail & To_Unbounded_String ("; gate_detail=") & Context.Gate_Detail;
      end if;
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Info;

   procedure Clear (Model : in out Gated_Result_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Gated_Result_Context_Model;
      Context : Gated_Result_Context_Info) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Gates.Semantic_Conclusion_Kind'Pos (Context.Conclusion) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Original_Result_State'Pos (Context.Original_State) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Audit.Ada_Construct_Kind'Pos (Context.Construct) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Audit.Semantic_Consumer_Family'Pos (Context.Consumer) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Gates.Gate_Action'Pos (Context.Gate_Action) + 1);
      Model.Fingerprint := Mix (Model.Fingerprint, Node_Slot (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   procedure Add_From_Gate
     (Model           : in out Gated_Result_Context_Model;
      Gate            : Gates.Gate_Info;
      Original_State  : Original_Result_State := Original_Result_Legal;
      Semantic_Row_Id : Natural := 0)
   is
      Context : Gated_Result_Context_Info;
   begin
      Context.Id := Gated_Result_Id (Natural (Gate.Id));
      Context.Conclusion := Gate.Conclusion;
      Context.Original_State := Original_State;
      Context.Construct := Gate.Construct;
      Context.Consumer := Gate.Consumer;
      Context.Gate_Status := Gate.Status;
      Context.Gate_Action := Gate.Action;
      Context.Gate_Id := Gate.Id;
      Context.Node := Gate.Node;
      Context.Parent_Node := Gate.Parent_Node;
      Context.Semantic_Row_Id := Semantic_Row_Id;
      Context.Construct_Name := Gate.Construct_Name;
      Context.Normalized_Name := Gate.Normalized_Name;
      Context.Gate_Message := Gate.Message;
      Context.Gate_Detail := Gate.Detail;
      Context.Source_Fingerprint := Gate.Fingerprint;
      Context.Start_Line := Gate.Start_Line;
      Context.Start_Column := Gate.Start_Column;
      Context.End_Line := Gate.End_Line;
      Context.End_Column := Gate.End_Column;
      Add_Context (Model, Context);
   end Add_From_Gate;

   function Build (Contexts : Gated_Result_Context_Model) return Gated_Result_Model is
      Model : Gated_Result_Model;
   begin
      Model.Fingerprint := Mix (Contexts.Fingerprint, Natural (Contexts.Items.Length));
      for Context of Contexts.Items loop
         declare
            Row : constant Gated_Result_Info := Build_Info (Context);
         begin
            Model.Items.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Build_From_Gates
     (Gate_Model      : Gates.Gate_Model;
      Original_State  : Original_Result_State := Original_Result_Legal)
      return Gated_Result_Model
   is
      Contexts : Gated_Result_Context_Model;
   begin
      for Index in 1 .. Gates.Gate_Count (Gate_Model) loop
         Add_From_Gate
           (Contexts,
            Gates.Gate_At (Gate_Model, Index),
            Original_State,
            Index);
      end loop;
      return Build (Contexts);
   end Build_From_Gates;

   function Result_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At
     (Model : Gated_Result_Model;
      Index : Positive) return Gated_Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function First_For_Node
     (Model : Gated_Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Gated_Result_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Gated_Result_Model;
      Status : Gated_Result_Status) return Gated_Result_Set
   is
      Set : Gated_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Conclusion
     (Model      : Gated_Result_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Gated_Result_Set
   is
      Set : Gated_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Conclusion = Conclusion then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Conclusion;

   function Rows_For_Consumer
     (Model    : Gated_Result_Model;
      Consumer : Audit.Semantic_Consumer_Family) return Gated_Result_Set
   is
      Set : Gated_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Consumer = Consumer then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Consumer;

   function Set_Count (Set : Gated_Result_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At
     (Set   : Gated_Result_Set;
      Index : Positive) return Gated_Result_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Gated_Result_Model;
      Status : Gated_Result_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Conclusion
     (Model      : Gated_Result_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Conclusion = Conclusion then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Conclusion;

   function Count_Consumer
     (Model    : Gated_Result_Model;
      Consumer : Audit.Semantic_Consumer_Family) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Consumer = Consumer then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Consumer;

   function Confident_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Count_Status (Model, Gated_Result_Confident);
   end Confident_Count;

   function Suppressed_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Count_Status (Model, Gated_Result_Legal_Suppressed) +
             Count_Status (Model, Gated_Result_Derived_Suppressed);
   end Suppressed_Count;

   function Degraded_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Count_Status (Model, Gated_Result_Degraded_Indeterminate);
   end Degraded_Count;

   function Repair_Required_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Count_Status (Model, Gated_Result_Parser_AST_Repair_Required) +
             Count_Status (Model, Gated_Result_Metadata_Repair_Required) +
             Count_Status (Model, Gated_Result_Consumer_Integration_Required);
   end Repair_Required_Count;

   function Cross_Unit_Required_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Count_Status (Model, Gated_Result_Cross_Unit_Required);
   end Cross_Unit_Required_Count;

   function Unsafe_Blocker_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Suppressed_Count (Model) +
             Repair_Required_Count (Model) +
             Cross_Unit_Required_Count (Model) +
             Count_Status (Model, Gated_Result_Blocked_Unsafe);
   end Unsafe_Blocker_Count;

   function Original_Error_Count (Model : Gated_Result_Model) return Natural is
   begin
      return Count_Status (Model, Gated_Result_Original_Error_Preserved);
   end Original_Error_Count;

   function Fingerprint (Model : Gated_Result_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Coverage_Gated_Semantic_Results;
