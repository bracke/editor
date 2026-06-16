with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_AST_Semantic_Coverage_Audit is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
      Hash : constant Long_Long_Integer :=
        (Long_Long_Integer (Left) * 131 + Long_Long_Integer (Right) * 17 + 1132)
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

   function Construct_Slot (Construct : Ada_Construct_Kind) return Natural is
   begin
      return Ada_Construct_Kind'Pos (Construct) + 1;
   end Construct_Slot;

   function Consumer_Slot (Consumer : Semantic_Consumer_Family) return Natural is
   begin
      return Semantic_Consumer_Family'Pos (Consumer) + 1;
   end Consumer_Slot;

   function Status_Slot (Status : Coverage_Status) return Natural is
   begin
      return Coverage_Status'Pos (Status) + 1;
   end Status_Slot;

   function Is_Complete (Status : Coverage_Status) return Boolean is
   begin
      return Status = Coverage_Complete;
   end Is_Complete;

   function Is_Metadata_Status (Status : Coverage_Status) return Boolean is
   begin
      return Status in
        Coverage_Name_Binding_Missing |
        Coverage_Type_Metadata_Missing |
        Coverage_Staticness_Metadata_Missing |
        Coverage_Contract_Metadata_Missing |
        Coverage_Flow_Metadata_Missing |
        Coverage_Representation_Metadata_Missing |
        Coverage_Cross_Unit_Metadata_Missing;
   end Is_Metadata_Status;

   function Is_Error (Status : Coverage_Status) return Boolean is
   begin
      return Status not in Coverage_Not_Checked | Coverage_Complete;
   end Is_Error;

   function Classify (Info : Coverage_Context_Info) return Coverage_Status is
   begin
      if not Info.Parser_Node_Present then
         return Coverage_Parser_Node_Missing;
      elsif Info.Token_Only_Parse then
         return Coverage_Token_Only_Parse;
      elsif not Info.Structural_AST_Present then
         return Coverage_AST_Shape_Missing;
      elsif not Info.Span_Present then
         return Coverage_Span_Missing;
      elsif not Info.Name_Binding_Present then
         return Coverage_Name_Binding_Missing;
      elsif not Info.Type_Metadata_Present then
         return Coverage_Type_Metadata_Missing;
      elsif not Info.Staticness_Metadata_Present then
         return Coverage_Staticness_Metadata_Missing;
      elsif not Info.Contract_Metadata_Present then
         return Coverage_Contract_Metadata_Missing;
      elsif not Info.Flow_Metadata_Present then
         return Coverage_Flow_Metadata_Missing;
      elsif not Info.Representation_Metadata_Present then
         return Coverage_Representation_Metadata_Missing;
      elsif not Info.Cross_Unit_Metadata_Present then
         return Coverage_Cross_Unit_Metadata_Missing;
      elsif not Info.Consumer_Present then
         return Coverage_Consumer_Missing;
      elsif not Info.Consumer_Integrated then
         return Coverage_Consumer_Not_Integrated;
      elsif Info.Graceful_Degradation_Only then
         return Coverage_Graceful_Degradation_Only;
      elsif Info.Construct = Construct_Unknown or else Info.Consumer = Consumer_None then
         return Coverage_Indeterminate;
      else
         return Coverage_Complete;
      end if;
   end Classify;

   function Status_Message (Status : Coverage_Status) return String is
   begin
      case Status is
         when Coverage_Not_Checked =>
            return "coverage item was not checked";
         when Coverage_Complete =>
            return "Ada construct has parser, AST, metadata, and semantic consumer coverage";
         when Coverage_Parser_Node_Missing =>
            return "Ada construct has no parser node coverage";
         when Coverage_AST_Shape_Missing =>
            return "Ada construct is missing structural AST shape coverage";
         when Coverage_Token_Only_Parse =>
            return "Ada construct is parsed only as tokens";
         when Coverage_Span_Missing =>
            return "Ada construct is missing source span coverage";
         when Coverage_Name_Binding_Missing =>
            return "Ada construct is missing name-binding metadata";
         when Coverage_Type_Metadata_Missing =>
            return "Ada construct is missing type metadata";
         when Coverage_Staticness_Metadata_Missing =>
            return "Ada construct is missing staticness metadata";
         when Coverage_Contract_Metadata_Missing =>
            return "Ada construct is missing contract/aspect metadata";
         when Coverage_Flow_Metadata_Missing =>
            return "Ada construct is missing flow/dataflow metadata";
         when Coverage_Representation_Metadata_Missing =>
            return "Ada construct is missing representation/freezing metadata";
         when Coverage_Cross_Unit_Metadata_Missing =>
            return "Ada construct is missing cross-unit metadata";
         when Coverage_Consumer_Missing =>
            return "Ada construct has no semantic legality consumer";
         when Coverage_Consumer_Not_Integrated =>
            return "Ada construct semantic consumer is not integrated into closure";
         when Coverage_Graceful_Degradation_Only =>
            return "Ada construct has graceful degradation but no compiler-grade coverage";
         when Coverage_Indeterminate =>
            return "Ada construct coverage is indeterminate";
      end case;
   end Status_Message;

   function Build_Info
     (Info   : Coverage_Context_Info;
      Status : Coverage_Status) return Coverage_Info
   is
      Result : Coverage_Info;
      FP     : Natural := Info.Source_Fingerprint;
   begin
      Result.Id := Info.Id;
      Result.Construct := Info.Construct;
      Result.Consumer := Info.Consumer;
      Result.Node := Info.Node;
      Result.Parent_Node := Info.Parent_Node;
      Result.Status := Status;
      Result.Construct_Name := Info.Construct_Name;
      Result.Normalized_Construct_Name := Info.Normalized_Construct_Name;
      Result.Message := To_Unbounded_String (Status_Message (Status));
      Result.Detail := To_Unbounded_String
        ("construct=" & Ada_Construct_Kind'Image (Info.Construct) &
         "; consumer=" & Semantic_Consumer_Family'Image (Info.Consumer));
      Result.Source_Fingerprint := Info.Source_Fingerprint;
      Result.Start_Line := Info.Start_Line;
      Result.Start_Column := Info.Start_Column;
      Result.End_Line := Info.End_Line;
      Result.End_Column := Info.End_Column;

      FP := Mix (FP, Natural (Info.Id));
      FP := Mix (FP, Construct_Slot (Info.Construct));
      FP := Mix (FP, Consumer_Slot (Info.Consumer));
      FP := Mix (FP, Node_Slot (Info.Node));
      FP := Mix (FP, Status_Slot (Status));
      FP := Mix (FP, Info.Start_Line);
      FP := Mix (FP, Info.Start_Column);
      Result.Fingerprint := FP;
      return Result;
   end Build_Info;

   procedure Clear (Model : in out Coverage_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Coverage_Context_Model;
      Context : Coverage_Context_Info)
   is
   begin
      Model.Items.Append (Context);
      Model.Fingerprint := Mix (Model.Fingerprint, Natural (Context.Id));
      Model.Fingerprint := Mix (Model.Fingerprint, Construct_Slot (Context.Construct));
      Model.Fingerprint := Mix (Model.Fingerprint, Consumer_Slot (Context.Consumer));
      Model.Fingerprint := Mix (Model.Fingerprint, Node_Slot (Context.Node));
      Model.Fingerprint := Mix (Model.Fingerprint, Context.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Coverage_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At
     (Model : Coverage_Context_Model;
      Index : Positive) return Coverage_Context_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Context_At;

   function Build (Contexts : Coverage_Context_Model) return Coverage_Model is
      Model : Coverage_Model;
   begin
      Model.Fingerprint := Mix (Contexts.Fingerprint, Context_Count (Contexts));
      for C of Contexts.Items loop
         declare
            Status : constant Coverage_Status := Classify (C);
            Row    : constant Coverage_Info := Build_Info (C, Status);
         begin
            Model.Items.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Coverage_Count (Model : Coverage_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Coverage_Count;

   function Coverage_At
     (Model : Coverage_Model;
      Index : Positive) return Coverage_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Coverage_At;

   function First_For_Node
     (Model : Coverage_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Coverage_Info is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Coverage_Model;
      Status : Coverage_Status) return Coverage_Result_Set
   is
      Results : Coverage_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Results.Items.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Construct
     (Model     : Coverage_Model;
      Construct : Ada_Construct_Kind) return Coverage_Result_Set
   is
      Results : Coverage_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Construct = Construct then
            Results.Items.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Construct;

   function Rows_For_Consumer
     (Model    : Coverage_Model;
      Consumer : Semantic_Consumer_Family) return Coverage_Result_Set
   is
      Results : Coverage_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Consumer = Consumer then
            Results.Items.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Consumer;

   function Result_Count (Results : Coverage_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Coverage_Result_Set;
      Index   : Positive) return Coverage_Info is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Coverage_Model;
      Status : Coverage_Status) return Natural
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

   function Count_Construct
     (Model     : Coverage_Model;
      Construct : Ada_Construct_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Construct = Construct then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Construct;

   function Count_Consumer
     (Model    : Coverage_Model;
      Consumer : Semantic_Consumer_Family) return Natural
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

   function Complete_Count (Model : Coverage_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Is_Complete (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Complete_Count;

   function Missing_Parser_Count (Model : Coverage_Model) return Natural is
   begin
      return Count_Status (Model, Coverage_Parser_Node_Missing)
        + Count_Status (Model, Coverage_Token_Only_Parse);
   end Missing_Parser_Count;

   function Missing_AST_Count (Model : Coverage_Model) return Natural is
   begin
      return Count_Status (Model, Coverage_AST_Shape_Missing)
        + Count_Status (Model, Coverage_Span_Missing);
   end Missing_AST_Count;

   function Missing_Metadata_Count (Model : Coverage_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Is_Metadata_Status (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Missing_Metadata_Count;

   function Missing_Consumer_Count (Model : Coverage_Model) return Natural is
   begin
      return Count_Status (Model, Coverage_Consumer_Missing)
        + Count_Status (Model, Coverage_Consumer_Not_Integrated);
   end Missing_Consumer_Count;

   function Degradation_Count (Model : Coverage_Model) return Natural is
   begin
      return Count_Status (Model, Coverage_Graceful_Degradation_Only)
        + Count_Status (Model, Coverage_Indeterminate);
   end Degradation_Count;

   function Error_Count (Model : Coverage_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Is_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Fingerprint (Model : Coverage_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_AST_Semantic_Coverage_Audit;
