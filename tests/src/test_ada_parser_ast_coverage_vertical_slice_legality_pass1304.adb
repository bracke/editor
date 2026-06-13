with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Parser_AST_Coverage_Vertical_Slice_Legality_Pass1304 is

   package PC renames Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality;
   use type PC.Construct_Id;
   use type PC.Result_Id;
   use type PC.Construct_Kind;
   use type PC.Consumer_Kind;
   use type PC.Coverage_Status;
   use type PC.Construct_Info;
   use type PC.Result_Info;
   use type PC.Construct_Model;
   use type PC.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Parser_AST_Coverage_Vertical_Slice_Legality_Pass1304");
   end Name;

   procedure Add_Construct
     (Model : in out PC.Construct_Model;
      Id    : Natural;
      Kind  : PC.Construct_Kind;
      Name  : String;
      Consumer : PC.Consumer_Kind := PC.Consumer_Overload;
      Parser_Node : Boolean := True;
      Token_Only : Boolean := False;
      Degraded : Boolean := False;
      Span : Boolean := True;
      Primary : Boolean := True;
      Secondary : Boolean := True;
      Metadata : Boolean := True;
      Semantic_Consumer : Boolean := True;
      Expected_Kind : PC.Construct_Kind := PC.Construct_Unknown;
      Source_FP : Natural := 130400;
      AST_FP : Natural := 230400;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0)
   is
      C : PC.Construct_Info;
   begin
      C.Id := PC.Construct_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (130400 + Id);
      C.Kind := Kind;
      C.Consumer := Consumer;
      C.Source_Name := To_Unbounded_String (Name);
      C.Has_Parser_Node := Parser_Node;
      C.Is_Token_Only := Token_Only;
      C.Is_Degraded := Degraded;
      C.Has_Source_Span := Span;
      C.Has_Primary_Child := Primary;
      C.Has_Secondary_Child := Secondary;
      C.Has_Type_Metadata := Metadata;
      C.Has_Semantic_Consumer := Semantic_Consumer;
      C.Expected_Kind := Expected_Kind;
      C.Source_Fingerprint := Source_FP + Id;
      C.AST_Fingerprint := AST_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      PC.Add_Construct (Model, C);
   end Add_Construct;

   procedure Accepts_Ada_2022_Constructs_With_Complete_AST_And_Consumers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Constructs : PC.Construct_Model;
      Results    : PC.Result_Model;
   begin
      Add_Construct (Constructs, 1, PC.Construct_Quantified_Expression,
                     "for all X of A => X > 0", PC.Consumer_Overload);
      Add_Construct (Constructs, 2, PC.Construct_Reduction_Expression,
                     "A'Reduce (Integer'Max, 0)", PC.Consumer_Global_Depends);
      Add_Construct (Constructs, 3, PC.Construct_Delta_Aggregate,
                     "R with delta F => 1", PC.Consumer_Freezing_Representation);
      Add_Construct (Constructs, 4, PC.Construct_Target_Name_Update,
                     "(@ + 1)", PC.Consumer_Remaining_RM_Edge);

      Results := PC.Build (Constructs);

      Assert (PC.Result_Count (Results) = 4, "expected four coverage rows");
      Assert (PC.Legal_Count (Results) = 4, "all complete AST rows should be legal");
      Assert (PC.Count_Status (Results, PC.Coverage_Legal_Semantic_Consumer) = 4,
              "complete AST rows should be semantic-consumer-ready");
      Assert (PC.Has_Result (PC.Result_At (Results, 1)), "first result should be present");
      Assert (PC.Fingerprint (Results) /= 0, "coverage result fingerprint should be stable");
   end Accepts_Ada_2022_Constructs_With_Complete_AST_And_Consumers;

   procedure Rejects_Token_Only_And_Missing_AST_Structure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Constructs : PC.Construct_Model;
      Results    : PC.Result_Model;
   begin
      Add_Construct (Constructs, 1, PC.Construct_Declare_Expression,
                     "declare X : Integer := F; begin X end",
                     Parser_Node => False);
      Add_Construct (Constructs, 2, PC.Construct_Container_Aggregate,
                     "Vector'[1, 2, 3]",
                     Token_Only => True);
      Add_Construct (Constructs, 3, PC.Construct_Parallel_Loop,
                     "parallel for I in R loop null; end loop",
                     Primary => False);
      Add_Construct (Constructs, 4, PC.Construct_Delta_Aggregate,
                     "R with delta F => 1",
                     Secondary => False);

      Results := PC.Build (Constructs);

      Assert (PC.Error_Count (Results) = 4, "all structural gaps should be errors");
      Assert (PC.Count_Status (Results, PC.Coverage_Missing_Parser_Node) = 1,
              "missing parser node should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_Token_Only_Construct) = 1,
              "token-only construct should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_Missing_Primary_Child) = 1,
              "missing primary child should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_Missing_Secondary_Child) = 1,
              "missing secondary child should be classified");
   end Rejects_Token_Only_And_Missing_AST_Structure;

   procedure Rejects_Metadata_Consumer_Kind_And_Fingerprint_Gaps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Constructs : PC.Construct_Model;
      Results    : PC.Result_Model;
   begin
      Add_Construct (Constructs, 1, PC.Construct_Generalized_Indexing,
                     "Map (Key)", Metadata => False);
      Add_Construct (Constructs, 2, PC.Construct_Quantified_Expression,
                     "for some X of A => P (X)", Semantic_Consumer => False);
      Add_Construct (Constructs, 3, PC.Construct_Delta_Aggregate,
                     "R with delta F => 2",
                     Expected_Kind => PC.Construct_Reduction_Expression);
      Add_Construct (Constructs, 4, PC.Construct_Reduction_Expression,
                     "A'Reduce (""+"", 0)", Expected_Source_FP => 99_999);
      Add_Construct (Constructs, 5, PC.Construct_Target_Name_Update,
                     "(@ * 2)", Expected_AST_FP => 88_888);

      Results := PC.Build (Constructs);

      Assert (PC.Result_Count (Results) = 5, "expected five blocker rows");
      Assert (PC.Count_Status (Results, PC.Coverage_Missing_Type_Metadata) = 1,
              "metadata blocker should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_Missing_Semantic_Consumer) = 1,
              "consumer blocker should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_Wrong_Construct_Kind) = 1,
              "wrong construct kind should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be classified");
      Assert (PC.Count_Status (Results, PC.Coverage_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be classified");
   end Rejects_Metadata_Consumer_Kind_And_Fingerprint_Gaps;

   procedure Preserves_Multiple_Blockers_And_Indeterminate_Constructs
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Constructs : PC.Construct_Model;
      Results    : PC.Result_Model;
   begin
      Add_Construct (Constructs, 1, PC.Construct_Container_Aggregate,
                     "Vector'[others => <>]",
                     Token_Only => True,
                     Span => False,
                     Metadata => False);
      Add_Construct (Constructs, 2, PC.Construct_Unknown,
                     "unknown Ada construct", PC.Consumer_Unknown);

      Results := PC.Build (Constructs);

      Assert (PC.Count_Status (Results, PC.Coverage_Multiple_Blockers) = 1,
              "multiple parser/AST blockers should be preserved");
      Assert (PC.Count_Status (Results, PC.Coverage_Indeterminate) = 1,
              "unknown construct with no blocker should stay indeterminate");
   end Preserves_Multiple_Blockers_And_Indeterminate_Constructs;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Ada_2022_Constructs_With_Complete_AST_And_Consumers'Access,
         "accepts Ada 2022 constructs with complete AST and consumers");
      Register_Routine
        (T, Rejects_Token_Only_And_Missing_AST_Structure'Access,
         "rejects token-only and missing AST structure");
      Register_Routine
        (T, Rejects_Metadata_Consumer_Kind_And_Fingerprint_Gaps'Access,
         "rejects metadata, consumer, kind, and fingerprint gaps");
      Register_Routine
        (T, Preserves_Multiple_Blockers_And_Indeterminate_Constructs'Access,
         "preserves multiple blockers and indeterminate constructs");
   end Register_Tests;

end Test_Ada_Parser_AST_Coverage_Vertical_Slice_Legality_Pass1304;
