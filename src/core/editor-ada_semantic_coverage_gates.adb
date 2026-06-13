with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Semantic_Coverage_Gates is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Left) * 131 + Long_Long_Integer (Right) * 19 + 1134)
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

   function Conclusion_Slot (Conclusion : Semantic_Conclusion_Kind) return Natural is
   begin
      return Semantic_Conclusion_Kind'Pos (Conclusion) + 1;
   end Conclusion_Slot;

   function Construct_Slot (Construct : Audit.Ada_Construct_Kind) return Natural is
   begin
      return Audit.Ada_Construct_Kind'Pos (Construct) + 1;
   end Construct_Slot;

   function Consumer_Slot (Consumer : Audit.Semantic_Consumer_Family) return Natural is
   begin
      return Audit.Semantic_Consumer_Family'Pos (Consumer) + 1;
   end Consumer_Slot;

   function Status_Slot (Status : Gate_Status) return Natural is
   begin
      return Gate_Status'Pos (Status) + 1;
   end Status_Slot;

   function Action_Slot (Action : Gate_Action) return Natural is
   begin
      return Gate_Action'Pos (Action) + 1;
   end Action_Slot;

   function Gate_Status_For (Coverage : Audit.Coverage_Status) return Gate_Status is
   begin
      case Coverage is
         when Audit.Coverage_Not_Checked =>
            return Gate_Not_Checked;
         when Audit.Coverage_Complete =>
            return Gate_Open;
         when Audit.Coverage_Parser_Node_Missing =>
            return Gate_Parser_Node_Missing;
         when Audit.Coverage_Token_Only_Parse =>
            return Gate_Token_Only_Parse;
         when Audit.Coverage_AST_Shape_Missing =>
            return Gate_AST_Shape_Missing;
         when Audit.Coverage_Span_Missing =>
            return Gate_Source_Span_Missing;
         when Audit.Coverage_Name_Binding_Missing =>
            return Gate_Name_Binding_Missing;
         when Audit.Coverage_Type_Metadata_Missing =>
            return Gate_Type_Metadata_Missing;
         when Audit.Coverage_Staticness_Metadata_Missing =>
            return Gate_Staticness_Metadata_Missing;
         when Audit.Coverage_Contract_Metadata_Missing =>
            return Gate_Contract_Metadata_Missing;
         when Audit.Coverage_Flow_Metadata_Missing =>
            return Gate_Flow_Metadata_Missing;
         when Audit.Coverage_Representation_Metadata_Missing =>
            return Gate_Representation_Metadata_Missing;
         when Audit.Coverage_Cross_Unit_Metadata_Missing =>
            return Gate_Cross_Unit_Metadata_Missing;
         when Audit.Coverage_Consumer_Missing =>
            return Gate_Consumer_Missing;
         when Audit.Coverage_Consumer_Not_Integrated =>
            return Gate_Consumer_Not_Integrated;
         when Audit.Coverage_Graceful_Degradation_Only =>
            return Gate_Graceful_Degradation_Only;
         when Audit.Coverage_Indeterminate =>
            return Gate_Construct_Indeterminate;
      end case;
   end Gate_Status_For;

   function Action_For (Status : Gate_Status) return Gate_Action is
   begin
      case Status is
         when Gate_Open =>
            return Gate_Allow_Confident_Result;
         when Gate_Not_Checked |
              Gate_Construct_Indeterminate |
              Gate_Unknown =>
            return Gate_Degrade_To_Indeterminate;
         when Gate_Parser_Node_Missing |
              Gate_Token_Only_Parse |
              Gate_AST_Shape_Missing |
              Gate_Source_Span_Missing =>
            return Gate_Require_Parser_AST_Repair;
         when Gate_Name_Binding_Missing |
              Gate_Type_Metadata_Missing |
              Gate_Staticness_Metadata_Missing |
              Gate_Contract_Metadata_Missing |
              Gate_Flow_Metadata_Missing |
              Gate_Representation_Metadata_Missing =>
            return Gate_Require_Metadata_Repair;
         when Gate_Cross_Unit_Metadata_Missing =>
            return Gate_Require_Cross_Unit_Closure;
         when Gate_Consumer_Missing |
              Gate_Consumer_Not_Integrated =>
            return Gate_Require_Consumer_Integration;
         when Gate_Graceful_Degradation_Only =>
            return Gate_Suppress_Legal_Result;
      end case;
   end Action_For;

   function Message_For (Status : Gate_Status; Action : Gate_Action) return String is
   begin
      case Action is
         when Gate_Allow_Confident_Result =>
            return "semantic coverage is complete for this conclusion";
         when Gate_Degrade_To_Indeterminate =>
            return "semantic conclusion must be degraded to indeterminate";
         when Gate_Suppress_Legal_Result =>
            return "legal result must be suppressed because only graceful degradation is available";
         when Gate_Suppress_Derived_Result =>
            return "derived semantic result must be suppressed";
         when Gate_Require_Cross_Unit_Closure =>
            return "cross-unit metadata is required before this conclusion is safe";
         when Gate_Require_Parser_AST_Repair =>
            return "parser or AST structure must be repaired before this conclusion is safe";
         when Gate_Require_Metadata_Repair =>
            return "semantic metadata must be repaired before this conclusion is safe";
         when Gate_Require_Consumer_Integration =>
            return "semantic consumer integration is required before this conclusion is safe";
         when Gate_Block_Unsafe_Result =>
            return "unsafe semantic conclusion is blocked by coverage gate " & Gate_Status'Image (Status);
      end case;
   end Message_For;

   function Build_Info (Context : Gate_Context_Info) return Gate_Info is
      Result : Gate_Info;
      Status : constant Gate_Status := Gate_Status_For (Context.Coverage);
      Action : constant Gate_Action := Action_For (Status);
      FP     : Natural := Context.Source_Fingerprint;
   begin
      Result.Id := Context.Id;
      Result.Conclusion := Context.Conclusion;
      Result.Construct := Context.Construct;
      Result.Consumer := Context.Consumer;
      Result.Node := Context.Node;
      Result.Parent_Node := Context.Parent_Node;
      Result.Status := Status;
      Result.Action := Action;
      Result.Construct_Name := Context.Construct_Name;
      Result.Normalized_Name := Context.Normalized_Name;
      Result.Message := To_Unbounded_String (Message_For (Status, Action));
      Result.Detail := To_Unbounded_String
        ("coverage=" & Audit.Coverage_Status'Image (Context.Coverage) &
         "; conclusion=" & Semantic_Conclusion_Kind'Image (Context.Conclusion) &
         "; construct=" & Audit.Ada_Construct_Kind'Image (Context.Construct) &
         "; consumer=" & Audit.Semantic_Consumer_Family'Image (Context.Consumer));
      Result.Source_Fingerprint := Context.Source_Fingerprint;
      Result.Start_Line := Context.Start_Line;
      Result.Start_Column := Context.Start_Column;
      Result.End_Line := Context.End_Line;
      Result.End_Column := Context.End_Column;

      FP := Mix (FP, Natural (Context.Id));
      FP := Mix (FP, Conclusion_Slot (Context.Conclusion));
      FP := Mix (FP, Construct_Slot (Context.Construct));
      FP := Mix (FP, Consumer_Slot (Context.Consumer));
      FP := Mix (FP, Node_Slot (Context.Node));
      FP := Mix (FP, Status_Slot (Status));
      FP := Mix (FP, Action_Slot (Action));
      FP := Mix (FP, Context.Start_Line);
      FP := Mix (FP, Context.Start_Column);
      Result.Fingerprint := FP;
      return Result;
   end Build_Info;

   procedure Clear (Model : in out Gate_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Gate_Context_Model;
      Context : Gate_Context_Info) is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Conclusion_Slot (Context.Conclusion));
      Model.Fingerprint := Mix (Model.Fingerprint, Construct_Slot (Context.Construct));
      Model.Fingerprint := Mix (Model.Fingerprint, Consumer_Slot (Context.Consumer));
      Model.Fingerprint := Mix (Model.Fingerprint, Node_Slot (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   procedure Add_From_Coverage
     (Model      : in out Gate_Context_Model;
      Coverage   : Audit.Coverage_Info;
      Conclusion : Semantic_Conclusion_Kind := Conclusion_Unknown)
   is
      Context : Gate_Context_Info;
   begin
      Context.Id := Gate_Item_Id (Natural (Coverage.Id));
      Context.Conclusion := Conclusion;
      Context.Construct := Coverage.Construct;
      Context.Consumer := Coverage.Consumer;
      Context.Node := Coverage.Node;
      Context.Parent_Node := Coverage.Parent_Node;
      Context.Construct_Name := Coverage.Construct_Name;
      Context.Normalized_Name := Coverage.Normalized_Construct_Name;
      Context.Coverage := Coverage.Status;
      Context.Source_Fingerprint := Coverage.Fingerprint;
      Context.Start_Line := Coverage.Start_Line;
      Context.Start_Column := Coverage.Start_Column;
      Context.End_Line := Coverage.End_Line;
      Context.End_Column := Coverage.End_Column;
      Add_Context (Model, Context);
   end Add_From_Coverage;

   function Build (Contexts : Gate_Context_Model) return Gate_Model is
      Model : Gate_Model;
   begin
      Model.Fingerprint := Mix (Contexts.Fingerprint, Natural (Contexts.Items.Length));
      for Context of Contexts.Items loop
         declare
            Row : constant Gate_Info := Build_Info (Context);
         begin
            Model.Items.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Build_From_Coverage
     (Coverage   : Audit.Coverage_Model;
      Conclusion : Semantic_Conclusion_Kind := Conclusion_Unknown) return Gate_Model
   is
      Contexts : Gate_Context_Model;
   begin
      for Index in 1 .. Audit.Coverage_Count (Coverage) loop
         Add_From_Coverage (Contexts, Audit.Coverage_At (Coverage, Index), Conclusion);
      end loop;
      return Build (Contexts);
   end Build_From_Coverage;

   function Gate_Count (Model : Gate_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Gate_Count;

   function Gate_At
     (Model : Gate_Model;
      Index : Positive) return Gate_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Gate_At;

   function First_For_Node
     (Model : Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Gate_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Gate_Model;
      Status : Gate_Status) return Gate_Result_Set
   is
      Set : Gate_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Action
     (Model  : Gate_Model;
      Action : Gate_Action) return Gate_Result_Set
   is
      Set : Gate_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Action = Action then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Action;

   function Rows_For_Conclusion
     (Model      : Gate_Model;
      Conclusion : Semantic_Conclusion_Kind) return Gate_Result_Set
   is
      Set : Gate_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Conclusion = Conclusion then
            Set.Items.Append (Row);
         end if;
      end loop;
      return Set;
   end Rows_For_Conclusion;

   function Result_Count (Set : Gate_Result_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Result_Count;

   function Result_At
     (Set   : Gate_Result_Set;
      Index : Positive) return Gate_Info is
   begin
      if Index > Natural (Set.Items.Length) then
         return (others => <>);
      end if;
      return Set.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Gate_Model;
      Status : Gate_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Action
     (Model  : Gate_Model;
      Action : Gate_Action) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Action = Action then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Action;

   function Count_Conclusion
     (Model      : Gate_Model;
      Conclusion : Semantic_Conclusion_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Conclusion = Conclusion then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Conclusion;

   function Open_Count (Model : Gate_Model) return Natural is
   begin
      return Count_Action (Model, Gate_Allow_Confident_Result);
   end Open_Count;

   function Suppressed_Count (Model : Gate_Model) return Natural is
   begin
      return Count_Action (Model, Gate_Suppress_Legal_Result) +
             Count_Action (Model, Gate_Suppress_Derived_Result);
   end Suppressed_Count;

   function Degraded_Count (Model : Gate_Model) return Natural is
   begin
      return Count_Action (Model, Gate_Degrade_To_Indeterminate);
   end Degraded_Count;

   function Repair_Required_Count (Model : Gate_Model) return Natural is
   begin
      return Count_Action (Model, Gate_Require_Parser_AST_Repair) +
             Count_Action (Model, Gate_Require_Metadata_Repair) +
             Count_Action (Model, Gate_Require_Consumer_Integration);
   end Repair_Required_Count;

   function Cross_Unit_Required_Count (Model : Gate_Model) return Natural is
   begin
      return Count_Action (Model, Gate_Require_Cross_Unit_Closure);
   end Cross_Unit_Required_Count;

   function Unsafe_Blocker_Count (Model : Gate_Model) return Natural is
   begin
      return Gate_Count (Model) - Open_Count (Model);
   end Unsafe_Blocker_Count;

   function Fingerprint (Model : Gate_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Semantic_Coverage_Gates;
