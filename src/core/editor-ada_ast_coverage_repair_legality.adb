with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_AST_Coverage_Repair_Legality is

   use type Audit.Coverage_Status;
   use type Gates.Gate_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Audit.Ada_Construct_Kind;
   use type Audit.Semantic_Consumer_Family;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Is_Repaired (Status : Repair_Status) return Boolean is
   begin
      return Status in
        Repair_Complete .. Repair_Audit_Already_Complete;
   end Is_Repaired;

   function Missing_Status (Status : Repair_Status) return Boolean is
   begin
      return Status in
        Repair_Parser_Node_Still_Missing |
        Repair_Structural_AST_Still_Missing |
        Repair_Source_Span_Still_Missing |
        Repair_Metadata_Still_Missing |
        Repair_Cross_Unit_Metadata_Still_Missing |
        Repair_Consumer_Still_Missing |
        Repair_Consumer_Still_Not_Integrated |
        Repair_Token_Only_Still_Present |
        Repair_Degradation_Still_Only_Path |
        Repair_Gate_Still_Blocking |
        Repair_Inconsistent_Repair;
   end Missing_Status;

   function Metadata_Kind (Kind : Repair_Kind) return Boolean is
   begin
      return Kind in
        Repair_Name_Binding_Metadata |
        Repair_Type_Metadata |
        Repair_Staticness_Metadata |
        Repair_Contract_Metadata |
        Repair_Flow_Metadata |
        Repair_Representation_Metadata |
        Repair_Cross_Unit_Metadata;
   end Metadata_Kind;

   function Classify (Info : Repair_Context_Info) return Repair_Status is
      Metadata_Repaired : constant Boolean :=
        Info.Name_Binding_Repaired or else
        Info.Type_Metadata_Repaired or else
        Info.Staticness_Metadata_Repaired or else
        Info.Contract_Metadata_Repaired or else
        Info.Flow_Metadata_Repaired or else
        Info.Representation_Metadata_Repaired;
   begin
      if Info.Before_Coverage = Audit.Coverage_Complete
        and then Info.Before_Gate = Gates.Gate_Open
      then
         return Repair_Audit_Already_Complete;
      end if;

      if Info.Gate_Cleared then
         return Repair_Gate_Cleared;
      end if;

      case Info.Kind is
         when Repair_Parser_Node =>
            if Info.Parser_Node_Repaired then
               return Repair_Parser_Node_Repaired;
            else
               return Repair_Parser_Node_Still_Missing;
            end if;
         when Repair_Structural_AST =>
            if Info.Structural_AST_Repaired then
               return Repair_Structural_AST_Repaired;
            else
               return Repair_Structural_AST_Still_Missing;
            end if;
         when Repair_Source_Span =>
            if Info.Source_Span_Repaired then
               return Repair_Source_Span_Repaired;
            else
               return Repair_Source_Span_Still_Missing;
            end if;
         when Repair_Name_Binding_Metadata |
              Repair_Type_Metadata |
              Repair_Staticness_Metadata |
              Repair_Contract_Metadata |
              Repair_Flow_Metadata |
              Repair_Representation_Metadata =>
            if Metadata_Repaired then
               return Repair_Metadata_Repaired;
            else
               return Repair_Metadata_Still_Missing;
            end if;
         when Repair_Cross_Unit_Metadata =>
            if Info.Cross_Unit_Metadata_Repaired then
               return Repair_Cross_Unit_Metadata_Repaired;
            else
               return Repair_Cross_Unit_Metadata_Still_Missing;
            end if;
         when Repair_Semantic_Consumer =>
            if Info.Consumer_Repaired then
               return Repair_Consumer_Repaired;
            else
               return Repair_Consumer_Still_Missing;
            end if;
         when Repair_Consumer_Integration =>
            if Info.Consumer_Integrated then
               return Repair_Consumer_Integrated;
            else
               return Repair_Consumer_Still_Not_Integrated;
            end if;
         when Repair_Token_Only_Replacement =>
            if Info.Token_Only_Replaced then
               return Repair_Token_Only_Replaced;
            else
               return Repair_Token_Only_Still_Present;
            end if;
         when Repair_Degradation_Replacement =>
            if Info.Degradation_Replaced then
               return Repair_Degradation_Replaced;
            else
               return Repair_Degradation_Still_Only_Path;
            end if;
         when Repair_Combined_Construct_Coverage =>
            if Info.Parser_Node_Repaired
              and then Info.Structural_AST_Repaired
              and then Info.Source_Span_Repaired
              and then Metadata_Repaired
              and then Info.Consumer_Integrated
            then
               return Repair_Complete;
            elsif Info.Parser_Node_Repaired or else Info.Structural_AST_Repaired
              or else Info.Source_Span_Repaired or else Metadata_Repaired
              or else Info.Consumer_Repaired or else Info.Consumer_Integrated
            then
               return Repair_Inconsistent_Repair;
            else
               return Repair_Indeterminate;
            end if;
         when Repair_Unknown =>
            return Repair_Indeterminate;
      end case;
   end Classify;

   function Message_For (Status : Repair_Status) return String is
   begin
      case Status is
         when Repair_Complete => return "construct coverage is fully repaired";
         when Repair_Parser_Node_Repaired => return "parser node coverage repaired";
         when Repair_Structural_AST_Repaired => return "structural AST coverage repaired";
         when Repair_Source_Span_Repaired => return "source span coverage repaired";
         when Repair_Metadata_Repaired => return "semantic metadata coverage repaired";
         when Repair_Cross_Unit_Metadata_Repaired => return "cross-unit metadata coverage repaired";
         when Repair_Consumer_Repaired => return "semantic consumer coverage repaired";
         when Repair_Consumer_Integrated => return "semantic consumer is integrated";
         when Repair_Token_Only_Replaced => return "token-only parse replaced with structural AST";
         when Repair_Degradation_Replaced => return "graceful-degradation-only path replaced";
         when Repair_Gate_Cleared => return "coverage gate cleared by repair";
         when Repair_Audit_Already_Complete => return "coverage audit was already complete";
         when Repair_Parser_Node_Still_Missing => return "parser node is still missing";
         when Repair_Structural_AST_Still_Missing => return "structural AST is still missing";
         when Repair_Source_Span_Still_Missing => return "source span is still missing";
         when Repair_Metadata_Still_Missing => return "semantic metadata is still missing";
         when Repair_Cross_Unit_Metadata_Still_Missing => return "cross-unit metadata is still missing";
         when Repair_Consumer_Still_Missing => return "semantic consumer is still missing";
         when Repair_Consumer_Still_Not_Integrated => return "semantic consumer is still not integrated";
         when Repair_Token_Only_Still_Present => return "token-only parse is still present";
         when Repair_Degradation_Still_Only_Path => return "only graceful degradation is still available";
         when Repair_Gate_Still_Blocking => return "coverage gate is still blocking";
         when Repair_Inconsistent_Repair => return "coverage repair is partial or inconsistent";
         when Repair_Indeterminate => return "coverage repair is indeterminate";
         when Repair_Not_Checked => return "coverage repair not checked";
      end case;
   end Message_For;

   function Make_Row (Info : Repair_Context_Info) return Repair_Info is
      Status : constant Repair_Status := Classify (Info);
      Row    : Repair_Info;
      FP     : Natural := Info.Source_Fingerprint;
   begin
      FP := Mix (FP, Repair_Kind'Pos (Info.Kind));
      FP := Mix (FP, Repair_Status'Pos (Status));
      FP := Mix (FP, Audit.Ada_Construct_Kind'Pos (Info.Construct));
      FP := Mix (FP, Audit.Semantic_Consumer_Family'Pos (Info.Consumer));
      FP := Mix (FP, Natural (Info.Node));

      Row.Id := Info.Id;
      Row.Kind := Info.Kind;
      Row.Construct := Info.Construct;
      Row.Consumer := Info.Consumer;
      Row.Node := Info.Node;
      Row.Parent_Node := Info.Parent_Node;
      Row.Status := Status;
      Row.Construct_Name := Info.Construct_Name;
      Row.Normalized_Construct_Name := Info.Normalized_Construct_Name;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String
        ("construct=" & To_String (Info.Construct_Name) &
         "; normalized=" & To_String (Info.Normalized_Construct_Name));
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Fingerprint := FP;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      return Row;
   end Make_Row;

   function Has_Error (Info : Repair_Info) return Boolean is
   begin
      return Missing_Status (Info.Status)
        or else Info.Status = Repair_Indeterminate;
   end Has_Error;

   procedure Clear (Model : in out Repair_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Repair_Context_Model;
      Context : Repair_Context_Info) is
   begin
      Model.Contexts.Append (Context);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   procedure Add_From_Audit
     (Model     : in out Repair_Context_Model;
      Coverage  : Audit.Coverage_Info;
      Gate      : Gates.Gate_Info;
      Kind      : Repair_Kind) is
      C : Repair_Context_Info;
   begin
      C.Id := Repair_Item_Id (Coverage.Id);
      C.Kind := Kind;
      C.Construct := Coverage.Construct;
      C.Consumer := Coverage.Consumer;
      C.Node := Coverage.Node;
      C.Parent_Node := Coverage.Parent_Node;
      C.Construct_Name := Coverage.Construct_Name;
      C.Normalized_Construct_Name := Coverage.Normalized_Construct_Name;
      C.Before_Coverage := Coverage.Status;
      C.Before_Gate := Gate.Status;
      C.Source_Fingerprint := Mix (Coverage.Fingerprint, Gate.Fingerprint);
      C.Start_Line := Coverage.Start_Line;
      C.Start_Column := Coverage.Start_Column;
      C.End_Line := Coverage.End_Line;
      C.End_Column := Coverage.End_Column;
      C.Parser_Node_Repaired := Coverage.Status = Audit.Coverage_Parser_Node_Missing;
      C.Structural_AST_Repaired := Coverage.Status = Audit.Coverage_AST_Shape_Missing;
      C.Source_Span_Repaired := Coverage.Status = Audit.Coverage_Span_Missing;
      C.Name_Binding_Repaired := Coverage.Status = Audit.Coverage_Name_Binding_Missing;
      C.Type_Metadata_Repaired := Coverage.Status = Audit.Coverage_Type_Metadata_Missing;
      C.Staticness_Metadata_Repaired := Coverage.Status = Audit.Coverage_Staticness_Metadata_Missing;
      C.Contract_Metadata_Repaired := Coverage.Status = Audit.Coverage_Contract_Metadata_Missing;
      C.Flow_Metadata_Repaired := Coverage.Status = Audit.Coverage_Flow_Metadata_Missing;
      C.Representation_Metadata_Repaired := Coverage.Status = Audit.Coverage_Representation_Metadata_Missing;
      C.Cross_Unit_Metadata_Repaired := Coverage.Status = Audit.Coverage_Cross_Unit_Metadata_Missing;
      C.Consumer_Repaired := Coverage.Status = Audit.Coverage_Consumer_Missing;
      C.Consumer_Integrated := Coverage.Status = Audit.Coverage_Consumer_Not_Integrated;
      C.Token_Only_Replaced := Coverage.Status = Audit.Coverage_Token_Only_Parse;
      C.Degradation_Replaced := Coverage.Status = Audit.Coverage_Graceful_Degradation_Only;
      C.Gate_Cleared := Gate.Status /= Gates.Gate_Not_Checked
        and then Gate.Status /= Gates.Gate_Open;
      Add_Context (Model, C);
   end Add_From_Audit;

   function Build (Contexts : Repair_Context_Model) return Repair_Model is
      Result : Repair_Model;
      Row    : Repair_Info;
   begin
      for I in 1 .. Natural (Contexts.Contexts.Length) loop
         Row := Make_Row (Contexts.Contexts.Element (I));
         Result.Items.Append (Row);
         Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
         if Is_Repaired (Row.Status) then
            Result.Repaired_Total := Result.Repaired_Total + 1;
         end if;
         if Missing_Status (Row.Status) then
            Result.Still_Missing_Total := Result.Still_Missing_Total + 1;
         end if;
         if Metadata_Kind (Row.Kind) or else Row.Status = Repair_Metadata_Repaired then
            Result.Metadata_Repair_Total := Result.Metadata_Repair_Total + 1;
         end if;
         if Row.Status in Repair_Consumer_Repaired | Repair_Consumer_Integrated then
            Result.Consumer_Repair_Total := Result.Consumer_Repair_Total + 1;
         end if;
         if Row.Status = Repair_Gate_Cleared then
            Result.Gate_Cleared_Total := Result.Gate_Cleared_Total + 1;
         end if;
         if Row.Status = Repair_Indeterminate then
            Result.Indeterminate_Total := Result.Indeterminate_Total + 1;
         end if;
      end loop;
      return Result;
   end Build;

   function Kind_For_Coverage (Status : Audit.Coverage_Status) return Repair_Kind is
   begin
      case Status is
         when Audit.Coverage_Parser_Node_Missing => return Repair_Parser_Node;
         when Audit.Coverage_AST_Shape_Missing => return Repair_Structural_AST;
         when Audit.Coverage_Token_Only_Parse => return Repair_Token_Only_Replacement;
         when Audit.Coverage_Span_Missing => return Repair_Source_Span;
         when Audit.Coverage_Name_Binding_Missing => return Repair_Name_Binding_Metadata;
         when Audit.Coverage_Type_Metadata_Missing => return Repair_Type_Metadata;
         when Audit.Coverage_Staticness_Metadata_Missing => return Repair_Staticness_Metadata;
         when Audit.Coverage_Contract_Metadata_Missing => return Repair_Contract_Metadata;
         when Audit.Coverage_Flow_Metadata_Missing => return Repair_Flow_Metadata;
         when Audit.Coverage_Representation_Metadata_Missing => return Repair_Representation_Metadata;
         when Audit.Coverage_Cross_Unit_Metadata_Missing => return Repair_Cross_Unit_Metadata;
         when Audit.Coverage_Consumer_Missing => return Repair_Semantic_Consumer;
         when Audit.Coverage_Consumer_Not_Integrated => return Repair_Consumer_Integration;
         when Audit.Coverage_Graceful_Degradation_Only => return Repair_Degradation_Replacement;
         when Audit.Coverage_Complete => return Repair_Combined_Construct_Coverage;
         when others => return Repair_Unknown;
      end case;
   end Kind_For_Coverage;

   function Build_From_Audit
     (Coverage : Audit.Coverage_Model;
      Gate_Data : Gates.Gate_Model) return Repair_Model is
      Contexts : Repair_Context_Model;
      Cov      : Audit.Coverage_Info;
      Gate     : Gates.Gate_Info;
   begin
      for I in 1 .. Audit.Coverage_Count (Coverage) loop
         Cov := Audit.Coverage_At (Coverage, I);
         Gate := Gates.First_For_Node (Gate_Data, Cov.Node);
         Add_From_Audit (Contexts, Cov, Gate, Kind_For_Coverage (Cov.Status));
      end loop;
      return Build (Contexts);
   end Build_From_Audit;

   function Context_Count (Model : Repair_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Repair_Count (Model : Repair_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Repair_Count;

   function Repair_At (Model : Repair_Model; Index : Positive) return Repair_Info is
   begin
      return Model.Items.Element (Index);
   end Repair_At;

   function First_For_Node
     (Model : Repair_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Repair_Info is
   begin
      for Item of Model.Items loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Repair_Model;
      Status : Repair_Status) return Repair_Result_Set is
      Set : Repair_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Set.Items.Append (Item);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Status;

   function Rows_For_Construct
     (Model     : Repair_Model;
      Construct : Audit.Ada_Construct_Kind) return Repair_Result_Set is
      Set : Repair_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Construct = Construct then
            Set.Items.Append (Item);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Construct;

   function Rows_For_Consumer
     (Model    : Repair_Model;
      Consumer : Audit.Semantic_Consumer_Family) return Repair_Result_Set is
      Set : Repair_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Consumer = Consumer then
            Set.Items.Append (Item);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Consumer;

   function Rows_For_Kind
     (Model : Repair_Model;
      Kind  : Repair_Kind) return Repair_Result_Set is
      Set : Repair_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Kind = Kind then
            Set.Items.Append (Item);
            Set.Result_Fingerprint := Mix (Set.Result_Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Set;
   end Rows_For_Kind;

   function Result_Count (Results : Repair_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Repair_Result_Set;
      Index   : Positive) return Repair_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Repair_Model; Status : Repair_Status) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind (Model : Repair_Model; Kind : Repair_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Construct
     (Model : Repair_Model; Construct : Audit.Ada_Construct_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Construct = Construct then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Construct;

   function Count_Consumer
     (Model : Repair_Model; Consumer : Audit.Semantic_Consumer_Family) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Items loop
         if Item.Consumer = Consumer then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Consumer;

   function Repaired_Count (Model : Repair_Model) return Natural is
   begin
      return Model.Repaired_Total;
   end Repaired_Count;

   function Still_Missing_Count (Model : Repair_Model) return Natural is
   begin
      return Model.Still_Missing_Total;
   end Still_Missing_Count;

   function Metadata_Repair_Count (Model : Repair_Model) return Natural is
   begin
      return Model.Metadata_Repair_Total;
   end Metadata_Repair_Count;

   function Consumer_Repair_Count (Model : Repair_Model) return Natural is
   begin
      return Model.Consumer_Repair_Total;
   end Consumer_Repair_Count;

   function Gate_Cleared_Count (Model : Repair_Model) return Natural is
   begin
      return Model.Gate_Cleared_Total;
   end Gate_Cleared_Count;

   function Indeterminate_Count (Model : Repair_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Repair_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_AST_Coverage_Repair_Legality;
