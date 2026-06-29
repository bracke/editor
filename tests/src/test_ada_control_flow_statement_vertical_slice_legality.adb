with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Control_Flow_Statement_Vertical_Slice_Legality is

   package CF renames Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality;
   use type CF.Flow_Id;
   use type CF.Result_Id;
   use type CF.Control_Construct_Kind;
   use type CF.Type_Class;
   use type CF.Legality_Status;
   use type CF.Flow_Info;
   use type CF.Result_Info;
   use type CF.Flow_Model;
   use type CF.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Control_Flow_Statement_Vertical_Slice_Legality");
   end Name;

   procedure Add_Flow
     (Model : in out CF.Flow_Model;
      Id    : Natural;
      Kind  : CF.Control_Construct_Kind;
      Text  : String;
      AST : Boolean := True;
      Context : Boolean := True;
      In_Function : Boolean := False;
      In_Procedure : Boolean := False;
      Expected : CF.Type_Class := CF.Type_Unknown;
      Actual   : CF.Type_Class := CF.Type_Unknown;
      Has_Return : Boolean := False;
      Return_Required : Boolean := False;
      Return_Access_OK : Boolean := True;
      Return_Assignment_OK : Boolean := True;
      Has_Exception : Boolean := True;
      Exception_Visible : Boolean := True;
      Has_Exit_Target : Boolean := True;
      Exit_Is_Loop : Boolean := True;
      Loop_Has_Exit : Boolean := True;
      Has_Goto_Target : Boolean := True;
      Goto_Deeper : Boolean := False;
      Goto_Protected : Boolean := False;
      Condition : CF.Type_Class := CF.Type_Boolean;
      Case_Type : CF.Type_Class := CF.Type_Unknown;
      Case_Alt_Type : CF.Type_Class := CF.Type_Unknown;
      Case_Complete : Boolean := True;
      Case_Overlap : Boolean := False;
      No_Return_Expected : Boolean := False;
      Falls_Through : Boolean := False;
      Reachable : Boolean := True;
      Predicate_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Universal_OK : Boolean := True;
      Source_FP : Natural := 130800;
      AST_FP : Natural := 230800;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0)
   is
      F : CF.Flow_Info;
   begin
      F.Id := CF.Flow_Id (Id);
      F.Node := Editor.Ada_Syntax_Tree.Node_Id (130800 + Id);
      F.Kind := Kind;
      F.Source_Name := To_Unbounded_String (Text);
      F.Has_AST_Coverage := AST;
      F.Has_Context := Context;
      F.In_Function := In_Function;
      F.In_Procedure := In_Procedure;
      F.Expected_Result_Type := Expected;
      F.Actual_Result_Type := Actual;
      F.Has_Return_Expression := Has_Return;
      F.Return_Expression_Required := Return_Required;
      F.Return_Accessibility_Legal := Return_Access_OK;
      F.Return_Definite_Assignment_Legal := Return_Assignment_OK;
      F.Has_Exception_Entity := Has_Exception;
      F.Exception_Visible := Exception_Visible;
      F.Has_Exit_Target := Has_Exit_Target;
      F.Exit_Target_Is_Loop := Exit_Is_Loop;
      F.Loop_Has_Exit_Path := Loop_Has_Exit;
      F.Has_Goto_Target := Has_Goto_Target;
      F.Goto_Enters_Deeper_Scope := Goto_Deeper;
      F.Goto_Enters_Protected_Action := Goto_Protected;
      F.Condition_Type := Condition;
      F.Case_Expression_Type := Case_Type;
      F.Case_Alternative_Type := Case_Alt_Type;
      F.Case_Alternatives_Complete := Case_Complete;
      F.Case_Alternatives_Overlap := Case_Overlap;
      F.No_Return_Expected := No_Return_Expected;
      F.May_Fall_Through := Falls_Through;
      F.Statement_Reachable := Reachable;
      F.Predicate_Legal := Predicate_OK;
      F.Runtime_Check_Required := Runtime_Check;
      F.Universal_Compatible := Universal_OK;
      F.Source_Fingerprint := Source_FP + Id;
      F.AST_Fingerprint := AST_FP + Id;
      F.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      F.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      CF.Add_Flow (Model, F);
   end Add_Flow;

   procedure Accepts_Concrete_Control_Flow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Flows : CF.Flow_Model;
      Results : CF.Result_Model;
   begin
      Add_Flow (Flows, 1, CF.Construct_Return_Statement,
                "function F return Integer is begin return 1; end",
                In_Function => True, Expected => CF.Type_Integer,
                Actual => CF.Type_Universal_Integer, Has_Return => True,
                Return_Required => True);
      Add_Flow (Flows, 2, CF.Construct_Raise_Statement,
                "raise Constraint_Error", Has_Exception => True,
                Exception_Visible => True);
      Add_Flow (Flows, 3, CF.Construct_Exit_Statement,
                "exit Loop_1", Has_Exit_Target => True, Exit_Is_Loop => True);
      Add_Flow (Flows, 4, CF.Construct_If_Expression,
                "if Flag then 1 else 2", Expected => CF.Type_Integer,
                Actual => CF.Type_Universal_Integer, Has_Return => True,
                Condition => CF.Type_Boolean);
      Add_Flow (Flows, 5, CF.Construct_Case_Statement,
                "case K is when A => null; when B => null; end case",
                Case_Type => CF.Type_Enumeration,
                Case_Alt_Type => CF.Type_Enumeration);
      Add_Flow (Flows, 6, CF.Construct_Block_Statement,
                "declare X : Predicated := Runtime_Checked; begin null; end",
                Runtime_Check => True);

      Results := CF.Build (Flows);

      Assert (CF.Result_Count (Results) = 6, "expected six control-flow rows");
      Assert (CF.Count_Status (Results, CF.Legality_Legal) = 5,
              "concrete control-flow rows should be legal");
      Assert (CF.Count_Status (Results, CF.Legality_Legal_With_Runtime_Check) = 1,
              "runtime predicate check should remain legal with check");
      Assert (CF.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Concrete_Control_Flow;

   procedure Rejects_Return_Raise_Exit_And_Goto_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Flows : CF.Flow_Model;
      Results : CF.Result_Model;
   begin
      Add_Flow (Flows, 1, CF.Construct_Return_Statement,
                "function F return Integer is begin return; end",
                In_Function => True, Expected => CF.Type_Integer,
                Return_Required => True, Has_Return => False);
      Add_Flow (Flows, 2, CF.Construct_Return_Statement,
                "procedure P is begin return 1; end",
                In_Procedure => True, Expected => CF.Type_Void,
                Actual => CF.Type_Integer, Has_Return => True);
      Add_Flow (Flows, 3, CF.Construct_Return_Statement,
                "function F return Integer is begin return True; end",
                In_Function => True, Expected => CF.Type_Integer,
                Actual => CF.Type_Boolean, Has_Return => True,
                Return_Required => True);
      Add_Flow (Flows, 4, CF.Construct_Raise_Statement,
                "raise Missing_Exception", Has_Exception => False);
      Add_Flow (Flows, 5, CF.Construct_Raise_Statement,
                "raise Private_Exception", Exception_Visible => False);
      Add_Flow (Flows, 6, CF.Construct_Exit_Statement,
                "exit Missing_Loop", Has_Exit_Target => False);
      Add_Flow (Flows, 7, CF.Construct_Goto_Statement,
                "goto Inner_Label", Goto_Deeper => True);
      Add_Flow (Flows, 8, CF.Construct_Goto_Statement,
                "goto Protected_Label", Goto_Protected => True);

      Results := CF.Build (Flows);

      Assert (CF.Error_Count (Results) = 8, "all invalid control transfers should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Return_Missing_Expression) = 1,
              "function return without expression should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Return_Unexpected_Expression) = 1,
              "procedure return with expression should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Return_Type_Mismatch) = 1,
              "return type mismatch should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Raise_Missing_Exception) = 1,
              "raise without exception entity should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Raise_Exception_Not_Visible) = 1,
              "raise of invisible exception should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Exit_Target_Missing) = 1,
              "missing exit target should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Goto_Enters_Deeper_Scope) = 1,
              "goto into deeper scope should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Goto_Enters_Protected_Action) = 1,
              "goto into protected action should reject");
   end Rejects_Return_Raise_Exit_And_Goto_Errors;

   procedure Rejects_Case_If_Loop_No_Return_And_Lifetime_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Flows : CF.Flow_Model;
      Results : CF.Result_Model;
   begin
      Add_Flow (Flows, 1, CF.Construct_If_Statement,
                "if Integer_Value then null; end if",
                Condition => CF.Type_Integer);
      Add_Flow (Flows, 2, CF.Construct_Case_Statement,
                "case K is when True => null; end case",
                Case_Type => CF.Type_Integer,
                Case_Alt_Type => CF.Type_Boolean);
      Add_Flow (Flows, 3, CF.Construct_Case_Statement,
                "case K is when A => null; end case",
                Case_Type => CF.Type_Enumeration,
                Case_Alt_Type => CF.Type_Enumeration,
                Case_Complete => False);
      Add_Flow (Flows, 4, CF.Construct_Case_Statement,
                "case K is when A | A => null; end case",
                Case_Type => CF.Type_Enumeration,
                Case_Alt_Type => CF.Type_Enumeration,
                Case_Overlap => True);
      Add_Flow (Flows, 5, CF.Construct_Loop_Statement,
                "loop null; end loop", Loop_Has_Exit => False);
      Add_Flow (Flows, 6, CF.Construct_No_Return_Call,
                "No_Return_Call; Next_Statement;",
                No_Return_Expected => True, Falls_Through => True);
      Add_Flow (Flows, 7, CF.Construct_Return_Statement,
                "return Local'Access",
                In_Function => True, Expected => CF.Type_Access,
                Actual => CF.Type_Access, Has_Return => True,
                Return_Required => True, Return_Access_OK => False);
      Add_Flow (Flows, 8, CF.Construct_Return_Statement,
                "return Partially_Initialized_Record",
                In_Function => True, Expected => CF.Type_Record,
                Actual => CF.Type_Record, Has_Return => True,
                Return_Required => True, Return_Assignment_OK => False);
      Add_Flow (Flows, 9, CF.Construct_Block_Statement,
                "unreachable statement after raise", Reachable => False);
      Add_Flow (Flows, 10, CF.Construct_Block_Statement,
                "predicate check rejected", Predicate_OK => False);

      Results := CF.Build (Flows);

      Assert (CF.Count_Status (Results, CF.Legality_Condition_Not_Boolean) = 1,
              "if/case condition must be Boolean where required");
      Assert (CF.Count_Status (Results, CF.Legality_Case_Expression_Type_Mismatch) = 1,
              "case alternative type mismatch should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Case_Alternatives_Incomplete) = 1,
              "incomplete case alternatives should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Case_Alternatives_Overlap) = 1,
              "overlapping case alternatives should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Loop_Exit_Path_Missing) = 1,
              "loop without known exit path should reject");
      Assert (CF.Count_Status (Results, CF.Legality_No_Return_Falls_Through) = 1,
              "No_Return call that falls through should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Return_Accessibility_Blocked) = 1,
              "return accessibility escape should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Return_Definite_Assignment_Blocked) = 1,
              "return of not-definitely-assigned value should reject");
      Assert (CF.Count_Status (Results, CF.Legality_Unreachable_Statement) = 1,
              "unreachable statement should be classified");
      Assert (CF.Count_Status (Results, CF.Legality_Predicate_Blocked) = 1,
              "predicate blocker should reject");
   end Rejects_Case_If_Loop_No_Return_And_Lifetime_Blockers;

   procedure Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Flows : CF.Flow_Model;
      Results : CF.Result_Model;
   begin
      Add_Flow (Flows, 1, CF.Construct_Return_Statement,
                "missing AST return", AST => False);
      Add_Flow (Flows, 2, CF.Construct_Return_Statement,
                "missing flow context", Context => False);
      Add_Flow (Flows, 3, CF.Construct_Return_Statement,
                "stale source fingerprint", Expected_Source_FP => 99_999);
      Add_Flow (Flows, 4, CF.Construct_Return_Statement,
                "stale AST fingerprint", Expected_AST_FP => 88_888);
      Add_Flow (Flows, 5, CF.Construct_Return_Statement,
                "many blockers", AST => False, Context => False);
      Add_Flow (Flows, 6, CF.Construct_Unknown,
                "unknown control-flow shape");

      Results := CF.Build (Flows);

      Assert (CF.Count_Status (Results, CF.Legality_Missing_AST_Coverage) = 1,
              "missing AST coverage should be classified");
      Assert (CF.Count_Status (Results, CF.Legality_Missing_Context) = 1,
              "missing context should be classified");
      Assert (CF.Count_Status (Results, CF.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be classified");
      Assert (CF.Count_Status (Results, CF.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be classified");
      Assert (CF.Count_Status (Results, CF.Legality_Multiple_Blockers) = 1,
              "multiple blockers should be preserved");
      Assert (CF.Count_Status (Results, CF.Legality_Indeterminate) = 1,
              "unknown flow shape should stay indeterminate");
      Assert (CF.Has_Result (CF.Result_At (Results, 1)), "first result should be present");
   end Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Concrete_Control_Flow'Access,
         "accepts concrete control flow");
      Register_Routine
        (T, Rejects_Return_Raise_Exit_And_Goto_Errors'Access,
         "rejects return, raise, exit, and goto errors");
      Register_Routine
        (T, Rejects_Case_If_Loop_No_Return_And_Lifetime_Blockers'Access,
         "rejects case, if, loop, no-return, and lifetime blockers");
      Register_Routine
        (T, Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers'Access,
         "preserves AST, fingerprint, multiple, and indeterminate blockers");
   end Register_Tests;

end Test_Ada_Control_Flow_Statement_Vertical_Slice_Legality;
