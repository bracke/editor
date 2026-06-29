with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Call_And_Operator_Overload_Resolution_Legality;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Call_And_Operator_Overload_Resolution_Legality is

   package ORL renames Editor.Ada_Call_And_Operator_Overload_Resolution_Legality;
   use type ORL.Overload_Context_Id;
   use type ORL.Candidate_Id;
   use type ORL.Resolution_Id;
   use type ORL.Context_Kind;
   use type ORL.Resolution_Status;
   use type ORL.Context_Info;
   use type ORL.Candidate_Info;
   use type ORL.Resolution_Info;
   use type ORL.Context_Model;
   use type ORL.Candidate_Model;
   use type ORL.Resolution_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Call_And_Operator_Overload_Resolution_Legality");
   end Name;

   procedure Add_Context
     (Contexts : in out ORL.Context_Model;
      Id       : Natural;
      Kind     : ORL.Context_Kind;
      Node     : Natural;
      Name     : String;
      Actuals  : String;
      Expected : String := "")
   is
      C : ORL.Context_Info;
   begin
      C.Id := ORL.Overload_Context_Id (Id);
      C.Kind := Kind;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (Node);
      C.Designator := To_Unbounded_String (Name);
      C.Actual_Profile := To_Unbounded_String (Actuals);
      C.Expected_Result_Type := To_Unbounded_String (Expected);
      C.Source_Fingerprint := Node * 13 + Natural (Id);
      ORL.Add_Context (Contexts, C);
   end Add_Context;

   procedure Add_Candidate
     (Candidates : in out ORL.Candidate_Model;
      Id         : Natural;
      Context    : Natural;
      Name       : String;
      Formals    : String;
      Result     : String := "";
      Visible    : Boolean := True;
      Primitive  : Boolean := False;
      Generic_Formal : Boolean := False;
      Access_Profile : Boolean := False;
      Class_Wide : Boolean := False;
      Private_Barrier : Boolean := False;
      Cross_Unit : Boolean := False)
   is
      C : ORL.Candidate_Info;
   begin
      C.Id := ORL.Candidate_Id (Id);
      C.Context := ORL.Overload_Context_Id (Context);
      C.Declaration := Editor.Ada_Direct_Visibility.Declaration_Id (Id + 10_000);
      C.Designator := To_Unbounded_String (Name);
      C.Formal_Profile := To_Unbounded_String (Formals);
      C.Result_Type := To_Unbounded_String (Result);
      C.Required_Actual_Count := 0;
      C.Is_Visible := Visible;
      C.Is_Primitive_Operator := Primitive;
      C.Is_Generic_Formal_Subprogram := Generic_Formal;
      C.Is_Access_To_Subprogram := Access_Profile;
      C.Has_Class_Wide_Result := Class_Wide;
      C.Private_View_Barrier := Private_Barrier;
      C.Cross_Unit_Blocker := Cross_Unit;
      C.Candidate_Fingerprint := Id * 17;
      ORL.Add_Candidate (Candidates, C);
   end Add_Candidate;

   procedure Resolves_Concrete_Call_And_Operator_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ORL.Context_Model;
      Candidates : ORL.Candidate_Model;
   begin
      --  F (1) in an Integer expected context chooses the Integer-returning
      --  interpretation over another arity-compatible interpretation.
      Add_Context (Contexts, 1, ORL.Context_Call, 129701, "F", "Integer", "Integer");
      Add_Candidate (Candidates, 1, 1, "F", "Integer", "Integer");
      Add_Candidate (Candidates, 2, 1, "F", "Integer", "Float");

      --  Universal integer operator actuals are resolved by primitive operator
      --  and integer compatibility rather than remaining token-level unknowns.
      Add_Context (Contexts, 2, ORL.Context_Operator, 129702, "+", "universal_integer|universal_integer", "Integer");
      Add_Candidate (Candidates, 3, 2, "+", "Integer|Integer", "Integer", Primitive => True);
      Add_Candidate (Candidates, 4, 2, "+", "Float|Float", "Float", Primitive => True);

      --  Access-to-subprogram profile matching is a distinct legal selection.
      Add_Context (Contexts, 3, ORL.Context_Access_To_Subprogram_Call, 129703, "Apply", "access procedure|Integer", "");
      Add_Candidate (Candidates, 5, 3, "Apply", "access procedure|Integer", "", Access_Profile => True);

      --  Generic formal subprogram actuals use profile compatibility, not only
      --  name presence.
      Add_Context (Contexts, 4, ORL.Context_Generic_Actual_Subprogram, 129704, "Action", "Integer", "");
      Add_Candidate (Candidates, 6, 4, "Action", "Integer", "", Generic_Formal => True);

      --  Same-score candidates remain ambiguous after real filtering.
      Add_Context (Contexts, 5, ORL.Context_Call, 129705, "Amb", "Integer", "");
      Add_Candidate (Candidates, 7, 5, "Amb", "Integer", "Integer");
      Add_Candidate (Candidates, 8, 5, "Amb", "Integer", "Integer");

      declare
         Model : constant ORL.Resolution_Model := ORL.Build (Contexts, Candidates);
      begin
         Assert (ORL.Resolution_Count (Model) = 5,
                 "each source-shaped overload context should produce one resolution row");
         Assert (ORL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129701)).Status =
                 ORL.Resolution_Legal_Expected_Result,
                 "expected result type should choose F(Integer) return Integer");
         Assert (ORL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129702)).Status =
                 ORL.Resolution_Legal_Expected_Result,
                 "universal integer operator should be resolved through integer expected type");
         Assert (ORL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129703)).Status =
                 ORL.Resolution_Legal_Access_Profile,
                 "access-to-subprogram profile should be a concrete legal overload selection");
         Assert (ORL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129704)).Status =
                 ORL.Resolution_Legal_Generic_Formal_Subprogram,
                 "generic formal subprogram actual should be selected by profile compatibility");
         Assert (ORL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129705)).Status =
                 ORL.Resolution_Ambiguous,
                 "equal viable candidates should remain ambiguous");
         Assert (ORL.Legal_Count (Model) = 4,
                 "four contexts should be legally resolved");
         Assert (ORL.Ambiguous_Count (Model) = 1,
                 "one context should remain ambiguous");
      end;
   end Resolves_Concrete_Call_And_Operator_Cases;

   procedure Reports_No_Visible_Arity_Type_And_View_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ORL.Context_Model;
      Candidates : ORL.Candidate_Model;
   begin
      Add_Context (Contexts, 1, ORL.Context_Call, 129711, "Hidden", "Integer");
      Add_Candidate (Candidates, 1, 1, "Hidden", "Integer", Visible => False);

      Add_Context (Contexts, 2, ORL.Context_Call, 129712, "Arity", "Integer|Integer");
      Add_Candidate (Candidates, 2, 2, "Arity", "Integer");

      Add_Context (Contexts, 3, ORL.Context_Call, 129713, "Types", "String");
      Add_Candidate (Candidates, 3, 3, "Types", "Integer");

      Add_Context (Contexts, 4, ORL.Context_Call, 129714, "Private_Op", "Integer");
      Add_Candidate (Candidates, 4, 4, "Private_Op", "Integer", Private_Barrier => True);

      Add_Context (Contexts, 5, ORL.Context_Call, 129715, "Remote", "Integer");
      Add_Candidate (Candidates, 5, 5, "Remote", "Integer", Cross_Unit => True);

      Add_Context (Contexts, 6, ORL.Context_Call, 129716, "Missing", "Integer");

      declare
         Model : constant ORL.Resolution_Model := ORL.Build (Contexts, Candidates);
      begin
         Assert (ORL.Count_Status (Model, ORL.Resolution_No_Visible_Candidate) = 1,
                 "invisible candidates should not be treated as unresolved names");
         Assert (ORL.Count_Status (Model, ORL.Resolution_Arity_Mismatch) = 1,
                 "arity mismatch should be reported before type mismatch");
         Assert (ORL.Count_Status (Model, ORL.Resolution_Actual_Type_Mismatch) = 1,
                 "actual/formal type mismatch should be explicit");
         Assert (ORL.Count_Status (Model, ORL.Resolution_Private_View_Barrier) = 1,
                 "private-view blockers should stop confident overload selection");
         Assert (ORL.Count_Status (Model, ORL.Resolution_Cross_Unit_Blocker) = 1,
                 "cross-unit blockers should remain separate from local mismatch");
         Assert (ORL.Count_Status (Model, ORL.Resolution_No_Candidate) = 1,
                 "missing designator candidates should be explicit");
         Assert (ORL.Error_Count (Model) = 6,
                 "all six blocker contexts should be counted as errors");
      end;
   end Reports_No_Visible_Arity_Type_And_View_Blockers;

   procedure Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ORL.Context_Model;
      Candidates : ORL.Candidate_Model;
      Model : constant ORL.Resolution_Model := ORL.Build (Contexts, Candidates);
   begin
      Assert (ORL.Resolution_Count (Model) = 0,
              "empty vertical overload input should produce no rows");
      Assert (not ORL.Has_Resolution
                (ORL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (42))),
              "absent node lookup should return no resolution row");
   end Empty_Inputs_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Resolves_Concrete_Call_And_Operator_Cases'Access,
         "Pass1297 resolves concrete call/operator overload vertical slices");
      Register_Routine
        (T, Reports_No_Visible_Arity_Type_And_View_Blockers'Access,
         "Pass1297 reports no-visible, arity, type, view, and cross-unit blockers");
      Register_Routine
        (T, Empty_Inputs_Are_Deterministic'Access,
         "Pass1297 keeps empty overload vertical-slice inputs deterministic");
   end Register_Tests;

end Test_Ada_Call_And_Operator_Overload_Resolution_Legality;
