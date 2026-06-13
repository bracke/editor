with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality_Pass1305 is

   package ER renames Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality;
   use type ER.Expression_Id;
   use type ER.Result_Id;
   use type ER.Expression_Kind;
   use type ER.Type_Class;
   use type ER.Resolution_Status;
   use type ER.Expression_Info;
   use type ER.Result_Info;
   use type ER.Expression_Model;
   use type ER.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality_Pass1305");
   end Name;

   procedure Add_Expr
     (Model : in out ER.Expression_Model;
      Id    : Natural;
      Kind  : ER.Expression_Kind;
      Text  : String;
      Expected : ER.Type_Class := ER.Type_Boolean;
      Primary  : ER.Type_Class := ER.Type_Iterator;
      Secondary : ER.Type_Class := ER.Type_Unknown;
      Result : ER.Type_Class := ER.Type_Boolean;
      Element : ER.Type_Class := ER.Type_Integer;
      Accumulator : ER.Type_Class := ER.Type_Integer;
      AST : Boolean := True;
      Has_Expected : Boolean := True;
      Has_Primary : Boolean := True;
      Has_Secondary : Boolean := True;
      Predicate_Boolean : Boolean := True;
      Reducer_Profile : Boolean := True;
      Seed_Compatible : Boolean := True;
      Delta_Component : Boolean := True;
      Container_Element : Boolean := True;
      Declare_Elaborable : Boolean := True;
      Target_Context : Boolean := True;
      Indexing_Profile : Boolean := True;
      Parallel_Safe : Boolean := True;
      Runtime_Check : Boolean := False;
      Source_FP : Natural := 130500;
      AST_FP : Natural := 230500;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0)
   is
      E : ER.Expression_Info;
   begin
      E.Id := ER.Expression_Id (Id);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (130500 + Id);
      E.Kind := Kind;
      E.Source_Name := To_Unbounded_String (Text);
      E.Has_AST_Coverage := AST;
      E.Has_Expected_Type := Has_Expected;
      E.Has_Primary_Operand_Type := Has_Primary;
      E.Has_Secondary_Operand_Type := Has_Secondary;
      E.Expected_Type := Expected;
      E.Primary_Type := Primary;
      E.Secondary_Type := Secondary;
      E.Result_Type := Result;
      E.Element_Type := Element;
      E.Accumulator_Type := Accumulator;
      E.Predicate_Result_Is_Boolean := Predicate_Boolean;
      E.Reducer_Profile_Compatible := Reducer_Profile;
      E.Reduction_Seed_Compatible := Seed_Compatible;
      E.Delta_Component_Compatible := Delta_Component;
      E.Container_Element_Compatible := Container_Element;
      E.Declare_Declarations_Elaborable := Declare_Elaborable;
      E.Target_Name_In_Update_Context := Target_Context;
      E.Generalized_Indexing_Profile_Compatible := Indexing_Profile;
      E.Parallel_Shared_State_Safe := Parallel_Safe;
      E.Needs_Runtime_Accessibility_Check := Runtime_Check;
      E.Source_Fingerprint := Source_FP + Id;
      E.AST_Fingerprint := AST_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      ER.Add_Expression (Model, E);
   end Add_Expr;

   procedure Resolves_Ada_2022_Expression_Types
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Exprs : ER.Expression_Model;
      Results : ER.Result_Model;
   begin
      Add_Expr (Exprs, 1, ER.Expression_Quantified,
                "for all X of A => X > 0",
                Expected => ER.Type_Boolean,
                Primary => ER.Type_Array,
                Result => ER.Type_Boolean);
      Add_Expr (Exprs, 2, ER.Expression_Reduction,
                "A'Reduce (Integer'Max, 0)",
                Expected => ER.Type_Integer,
                Primary => ER.Type_Array,
                Secondary => ER.Type_Universal_Integer,
                Result => ER.Type_Integer,
                Accumulator => ER.Type_Integer);
      Add_Expr (Exprs, 3, ER.Expression_Delta_Aggregate,
                "R with delta F => 1",
                Expected => ER.Type_Record,
                Primary => ER.Type_Record,
                Result => ER.Type_Record);
      Add_Expr (Exprs, 4, ER.Expression_Generalized_Indexing,
                "Map (Key)",
                Expected => ER.Type_Integer,
                Primary => ER.Type_Container,
                Secondary => ER.Type_Integer,
                Result => ER.Type_Integer);

      Results := ER.Build (Exprs);

      Assert (ER.Result_Count (Results) = 4, "expected four expression rows");
      Assert (ER.Legal_Count (Results) = 4, "all complete expression rows should resolve");
      Assert (ER.Count_Status (Results, ER.Resolution_Legal) = 4,
              "complete expression rows should be legal");
      Assert (ER.Result_At (Results, 2).Resolved_Type = ER.Type_Integer,
              "reduction should resolve to accumulator type");
      Assert (ER.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Resolves_Ada_2022_Expression_Types;

   procedure Rejects_Construct_Specific_Type_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Exprs : ER.Expression_Model;
      Results : ER.Result_Model;
   begin
      Add_Expr (Exprs, 1, ER.Expression_Quantified,
                "for some X of A => X + 1",
                Predicate_Boolean => False);
      Add_Expr (Exprs, 2, ER.Expression_Reduction,
                "A'Reduce (Bad, 0)",
                Expected => ER.Type_Integer,
                Primary => ER.Type_Array,
                Secondary => ER.Type_Integer,
                Result => ER.Type_Integer,
                Reducer_Profile => False);
      Add_Expr (Exprs, 3, ER.Expression_Delta_Aggregate,
                "I with delta F => 1",
                Expected => ER.Type_Integer,
                Primary => ER.Type_Integer,
                Result => ER.Type_Integer);
      Add_Expr (Exprs, 4, ER.Expression_Target_Name_Update,
                "@ + 1", Target_Context => False);

      Results := ER.Build (Exprs);

      Assert (ER.Error_Count (Results) = 4, "all construct-specific errors should reject");
      Assert (ER.Count_Status (Results, ER.Resolution_Predicate_Not_Boolean) = 1,
              "quantified predicate mismatch should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_Reduction_Profile_Mismatch) = 1,
              "reduction profile mismatch should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_Delta_Base_Not_Composite) = 1,
              "delta base mismatch should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_Target_Name_Outside_Update) = 1,
              "target-name update context mismatch should be classified");
   end Rejects_Construct_Specific_Type_Errors;

   procedure Rejects_Container_Declare_Parallel_And_Fingerprint_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Exprs : ER.Expression_Model;
      Results : ER.Result_Model;
   begin
      Add_Expr (Exprs, 1, ER.Expression_Container_Aggregate,
                "Vector'[1, True]",
                Expected => ER.Type_Container,
                Primary => ER.Type_Container,
                Container_Element => False);
      Add_Expr (Exprs, 2, ER.Expression_Declare,
                "declare X : Integer := 1; begin Boolean'(X) end",
                Expected => ER.Type_Boolean,
                Result => ER.Type_Integer);
      Add_Expr (Exprs, 3, ER.Expression_Parallel_Loop,
                "parallel for I in R loop Shared := I; end loop",
                Expected => ER.Type_Void,
                Primary => ER.Type_Iterator,
                Result => ER.Type_Void,
                Parallel_Safe => False);
      Add_Expr (Exprs, 4, ER.Expression_Generalized_Indexing,
                "Map (Key)",
                Expected => ER.Type_Integer,
                Primary => ER.Type_Container,
                Secondary => ER.Type_Integer,
                Result => ER.Type_Integer,
                Expected_Source_FP => 99_999);
      Add_Expr (Exprs, 5, ER.Expression_Delta_Aggregate,
                "R with delta F => 1",
                Expected => ER.Type_Record,
                Primary => ER.Type_Record,
                Result => ER.Type_Record,
                Expected_AST_FP => 88_888);

      Results := ER.Build (Exprs);

      Assert (ER.Count_Status (Results, ER.Resolution_Container_Element_Mismatch) = 1,
              "container element mismatch should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_Declare_Result_Mismatch) = 1,
              "declare result mismatch should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_Parallel_Loop_Shared_State_Blocker) = 1,
              "parallel shared-state blocker should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be classified");
      Assert (ER.Count_Status (Results, ER.Resolution_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be classified");
   end Rejects_Container_Declare_Parallel_And_Fingerprint_Errors;

   procedure Preserves_Multiple_Blockers_Runtime_Checks_And_Indeterminate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Exprs : ER.Expression_Model;
      Results : ER.Result_Model;
   begin
      Add_Expr (Exprs, 1, ER.Expression_Reduction,
                "A'Reduce (Bad, Wrong_Seed)",
                Expected => ER.Type_Integer,
                Primary => ER.Type_Array,
                Secondary => ER.Type_Boolean,
                Accumulator => ER.Type_Integer,
                Reducer_Profile => False,
                Seed_Compatible => False);
      Add_Expr (Exprs, 2, ER.Expression_Generalized_Indexing,
                "Access_Table (Key)",
                Expected => ER.Type_Access,
                Primary => ER.Type_Container,
                Secondary => ER.Type_Integer,
                Result => ER.Type_Access,
                Runtime_Check => True);
      Add_Expr (Exprs, 3, ER.Expression_Unknown,
                "unknown expression",
                Expected => ER.Type_Unknown,
                Primary => ER.Type_Unknown,
                Result => ER.Type_Unknown);

      Results := ER.Build (Exprs);

      Assert (ER.Count_Status (Results, ER.Resolution_Multiple_Blockers) = 1,
              "multiple reduction blockers should be preserved");
      Assert (ER.Count_Status (Results, ER.Resolution_Legal_With_Runtime_Check) = 1,
              "runtime accessibility check contexts should remain legal with check");
      Assert (ER.Count_Status (Results, ER.Resolution_Indeterminate) = 1,
              "unknown expression should stay indeterminate");
      Assert (ER.Has_Result (ER.Result_At (Results, 2)), "runtime-check row should be present");
   end Preserves_Multiple_Blockers_Runtime_Checks_And_Indeterminate;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Resolves_Ada_2022_Expression_Types'Access,
         "resolves Ada 2022 expression types");
      Register_Routine
        (T, Rejects_Construct_Specific_Type_Errors'Access,
         "rejects construct-specific type errors");
      Register_Routine
        (T, Rejects_Container_Declare_Parallel_And_Fingerprint_Errors'Access,
         "rejects container, declare, parallel, and fingerprint errors");
      Register_Routine
        (T, Preserves_Multiple_Blockers_Runtime_Checks_And_Indeterminate'Access,
         "preserves multiple blockers, runtime checks, and indeterminate rows");
   end Register_Tests;

end Test_Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality_Pass1305;
