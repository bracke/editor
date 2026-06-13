with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality;

package body Test_Ada_Context_Clause_With_Use_Vertical_Slice_Legality_Pass1330 is

   package CCL renames Editor.Ada_Context_Clause_With_Use_Vertical_Slice_Legality;
   use type CCL.Unit_Id;
   use type CCL.Type_Id;
   use type CCL.Clause_Id;
   use type CCL.Result_Id;
   use type CCL.Unit_Kind;
   use type CCL.Type_Kind;
   use type CCL.View_Kind;
   use type CCL.Clause_Kind;
   use type CCL.Legality_Status;
   use type CCL.Unit_Info;
   use type CCL.Unit_Model;
   use type CCL.Type_Info;
   use type CCL.Type_Model;
   use type CCL.Clause_Info;
   use type CCL.Clause_Model;
   use type CCL.Result_Info;
   use type CCL.Result_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada context clause with/use vertical slice legality pass1330");
   end Name;

   procedure Add_Unit
     (Model : in out CCL.Unit_Model;
      Id : Natural;
      Name_Text : String;
      Kind : CCL.Unit_Kind;
      Parent : Natural := 0;
      View : CCL.View_Kind := CCL.View_Full;
      Private_Child : Boolean := False;
      Generic_Unit : Boolean := False;
      Body_Context : Boolean := True;
      Generic_Context : Boolean := True;
      Source_FP : Natural := 133000;
      Unit_FP : Natural := 233000;
      View_FP : Natural := 333000;
      Closure_FP : Natural := 433000;
      Expected_Source_FP : Natural := 0;
      Expected_Unit_FP : Natural := 0;
      Expected_View_FP : Natural := 0;
      Expected_Closure_FP : Natural := 0)
   is
      U : CCL.Unit_Info;
   begin
      U.Id := CCL.Unit_Id (Id);
      U.Name := To_Unbounded_String (Name_Text);
      U.Node := Editor.Ada_Syntax_Tree.Node_Id (133000 + Id);
      U.Kind := Kind;
      U.Parent := CCL.Unit_Id (Parent);
      U.View := View;
      U.Is_Private_Child := Private_Child;
      U.Is_Generic := Generic_Unit;
      U.Context_Propagated_To_Body := Body_Context;
      U.Generic_Contract_Context_Present := Generic_Context;
      U.Source_Fingerprint := Source_FP + Id;
      U.Unit_Fingerprint := Unit_FP + Id;
      U.View_Fingerprint := View_FP + Id;
      U.Closure_Fingerprint := Closure_FP + Id;
      U.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      U.Expected_Unit_Fingerprint :=
        (if Expected_Unit_FP = 0 then Unit_FP + Id else Expected_Unit_FP);
      U.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then View_FP + Id else Expected_View_FP);
      U.Expected_Closure_Fingerprint :=
        (if Expected_Closure_FP = 0 then Closure_FP + Id else Expected_Closure_FP);
      CCL.Add_Unit (Model, U);
   end Add_Unit;

   procedure Add_Type
     (Model : in out CCL.Type_Model;
      Id : Natural;
      Name_Text : String;
      Kind : CCL.Type_Kind;
      View : CCL.View_Kind := CCL.View_Full;
      Source_FP : Natural := 533000;
      View_FP : Natural := 633000;
      Expected_Source_FP : Natural := 0;
      Expected_View_FP : Natural := 0)
   is
      T : CCL.Type_Info;
   begin
      T.Id := CCL.Type_Id (Id);
      T.Name := To_Unbounded_String (Name_Text);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (233000 + Id);
      T.Kind := Kind;
      T.View := View;
      T.Source_Fingerprint := Source_FP + Id;
      T.View_Fingerprint := View_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then View_FP + Id else Expected_View_FP);
      CCL.Add_Type (Model, T);
   end Add_Type;

   procedure Add_Clause
     (Model : in out CCL.Clause_Model;
      Id : Natural;
      Name_Text : String;
      Kind : CCL.Clause_Kind;
      Context : Natural := 0;
      Target_Unit : Natural := 0;
      Target_Type : Natural := 0;
      Name_Matches : Boolean := True;
      Duplicate_With : Boolean := False;
      Duplicate_Use : Boolean := False;
      Cycle : Boolean := False;
      Private_With_OK : Boolean := True;
      Private_Child_Visible : Boolean := True;
      Requires_Full : Boolean := False;
      Use_Has_With : Boolean := True;
      Use_Package_OK : Boolean := True;
      Use_Type_OK : Boolean := True;
      Body_Context : Boolean := True;
      Generic_Context : Boolean := True;
      Ambiguous_Use : Boolean := False;
      Source_FP : Natural := 733000;
      Unit_FP : Natural := 833000;
      View_FP : Natural := 933000;
      Closure_FP : Natural := 143000;
      Expected_Source_FP : Natural := 0;
      Expected_Unit_FP : Natural := 0;
      Expected_View_FP : Natural := 0;
      Expected_Closure_FP : Natural := 0)
   is
      C : CCL.Clause_Info;
   begin
      C.Id := CCL.Clause_Id (Id);
      C.Name := To_Unbounded_String (Name_Text);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (333000 + Id);
      C.Kind := Kind;
      C.Context_Unit := CCL.Unit_Id (Context);
      C.Target_Unit := CCL.Unit_Id (Target_Unit);
      C.Target_Type := CCL.Type_Id (Target_Type);
      C.Target_Name_Matches := Name_Matches;
      C.Duplicate_With := Duplicate_With;
      C.Duplicate_Use := Duplicate_Use;
      C.Dependency_Cycle := Cycle;
      C.Private_With_Allowed := Private_With_OK;
      C.Private_Child_Visible := Private_Child_Visible;
      C.Consumer_Requires_Full_View := Requires_Full;
      C.Use_Has_With := Use_Has_With;
      C.Use_Target_Is_Package := Use_Package_OK;
      C.Use_Type_Target_Is_Type := Use_Type_OK;
      C.Body_Context_Propagated := Body_Context;
      C.Generic_Context_Present := Generic_Context;
      C.Ambiguous_Use_Homograph := Ambiguous_Use;
      C.Source_Fingerprint := Source_FP + Id;
      C.Unit_Fingerprint := Unit_FP + Id;
      C.View_Fingerprint := View_FP + Id;
      C.Closure_Fingerprint := Closure_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_Unit_Fingerprint :=
        (if Expected_Unit_FP = 0 then Unit_FP + Id else Expected_Unit_FP);
      C.Expected_View_Fingerprint :=
        (if Expected_View_FP = 0 then View_FP + Id else Expected_View_FP);
      C.Expected_Closure_Fingerprint :=
        (if Expected_Closure_FP = 0 then Closure_FP + Id else Expected_Closure_FP);
      CCL.Add_Clause (Model, C);
   end Add_Clause;

   procedure Test_With_Use_And_Use_Type_Targets

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : CCL.Unit_Model;
      Types : CCL.Type_Model;
      Clauses : CCL.Clause_Model;
      Results : CCL.Result_Model;
   begin
      Add_Unit (Units, 1, "Client", CCL.Unit_Package_Spec);
      Add_Unit (Units, 2, "Ada.Text_IO", CCL.Unit_Package_Spec);
      Add_Unit (Units, 3, "Worker", CCL.Unit_Subprogram_Spec);
      Add_Type (Types, 1, "Flags", CCL.Type_Discrete);
      Add_Clause (Clauses, 1, "with Ada.Text_IO", CCL.Clause_With,
                  Context => 1, Target_Unit => 2);
      Add_Clause (Clauses, 2, "use Ada.Text_IO", CCL.Clause_Use_Package,
                  Context => 1, Target_Unit => 2);
      Add_Clause (Clauses, 3, "use Worker", CCL.Clause_Use_Package,
                  Context => 1, Target_Unit => 3);
      Add_Clause (Clauses, 4, "use type Flags", CCL.Clause_Use_Type,
                  Context => 1, Target_Type => 1);
      Results := CCL.Build (Units, Types, Clauses);
      Assert (CCL.Result_At (Results, 1).Status = CCL.Legality_Legal,
              "ordinary with clause resolves its library unit");
      Assert (CCL.Result_At (Results, 2).Status = CCL.Legality_Legal,
              "use package is legal for a visible package target");
      Assert (CCL.Result_At (Results, 3).Status = CCL.Legality_Use_Target_Not_Package,
              "use package rejects non-package targets");
      Assert (CCL.Result_At (Results, 4).Status = CCL.Legality_Legal,
              "use type is legal for a resolved type target");
   end Test_With_Use_And_Use_Type_Targets;

   procedure Test_Limited_With_Cycles_And_Full_View_Use

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : CCL.Unit_Model;
      Types : CCL.Type_Model;
      Clauses : CCL.Clause_Model;
      Results : CCL.Result_Model;
   begin
      Add_Unit (Units, 1, "A", CCL.Unit_Package_Spec);
      Add_Unit (Units, 2, "B", CCL.Unit_Package_Spec,
                View => CCL.View_Limited);
      Add_Clause (Clauses, 1, "limited with B", CCL.Clause_Limited_With,
                  Context => 1, Target_Unit => 2, Cycle => True);
      Add_Clause (Clauses, 2, "limited with B; B.X", CCL.Clause_Limited_With,
                  Context => 1, Target_Unit => 2, Cycle => True,
                  Requires_Full => True);
      Add_Clause (Clauses, 3, "with B", CCL.Clause_With,
                  Context => 1, Target_Unit => 2, Cycle => True);
      Results := CCL.Build (Units, Types, Clauses);
      Assert (CCL.Result_At (Results, 1).Status =
                CCL.Legality_Legal_With_Limited_View,
              "limited with accepts circular limited-view dependency evidence");
      Assert (CCL.Result_At (Results, 2).Status = CCL.Legality_Limited_View_Barrier,
              "full-view use through limited with is blocked by limited-view evidence");
      Assert (CCL.Result_At (Results, 2).Limited_View_Blockers = 1,
              "limited-view barrier recorded when consumer needs full view");
      Assert (CCL.Result_At (Results, 3).Status = CCL.Legality_Multiple_Blockers,
              "nonlimited with cycle and limited target view are both blockers");
   end Test_Limited_With_Cycles_And_Full_View_Use;

   procedure Test_Private_With_And_Private_Child_Visibility

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : CCL.Unit_Model;
      Types : CCL.Type_Model;
      Clauses : CCL.Clause_Model;
      Results : CCL.Result_Model;
   begin
      Add_Unit (Units, 1, "Parent.Client", CCL.Unit_Child_Package);
      Add_Unit (Units, 2, "Parent.Secret", CCL.Unit_Private_Child_Package,
                Private_Child => True);
      Add_Clause (Clauses, 1, "private with Parent.Secret", CCL.Clause_Private_With,
                  Context => 1, Target_Unit => 2, Private_With_OK => False);
      Add_Clause (Clauses, 2, "with Parent.Secret", CCL.Clause_With,
                  Context => 1, Target_Unit => 2, Private_Child_Visible => False);
      Results := CCL.Build (Units, Types, Clauses);
      Assert (CCL.Result_At (Results, 1).Status = CCL.Legality_Multiple_Blockers,
              "private with outside its allowed context and invisible private child both block");
      Assert (CCL.Result_At (Results, 1).Private_With_Blockers = 1,
              "private-with placement blocker recorded");
      Assert (CCL.Result_At (Results, 2).Status = CCL.Legality_Private_Child_Not_Visible,
              "ordinary with cannot see an inaccessible private child");
   end Test_Private_With_And_Private_Child_Visibility;

   procedure Test_Body_Context_And_Generic_Context_Propagation

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : CCL.Unit_Model;
      Types : CCL.Type_Model;
      Clauses : CCL.Clause_Model;
      Results : CCL.Result_Model;
   begin
      Add_Unit (Units, 1, "Pkg", CCL.Unit_Package_Body,
                Body_Context => False);
      Add_Unit (Units, 2, "Support", CCL.Unit_Package_Spec);
      Add_Unit (Units, 3, "Gen", CCL.Unit_Generic_Package,
                Generic_Unit => True, Generic_Context => False);
      Add_Clause (Clauses, 1, "with Support in body", CCL.Clause_With,
                  Context => 1, Target_Unit => 2, Body_Context => False);
      Add_Clause (Clauses, 2, "generic with Support", CCL.Clause_With,
                  Context => 3, Target_Unit => 2, Generic_Context => False);
      Results := CCL.Build (Units, Types, Clauses);
      Assert (CCL.Result_At (Results, 1).Status = CCL.Legality_Body_Context_Not_Propagated,
              "package body must receive the relevant spec/body context evidence");
      Assert (CCL.Result_At (Results, 2).Status = CCL.Legality_Generic_Context_Missing,
              "generic units require contract context evidence for visible units");
   end Test_Body_Context_And_Generic_Context_Propagation;

   procedure Test_Duplicates_Ambiguous_Use_And_Fingerprints

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Units : CCL.Unit_Model;
      Types : CCL.Type_Model;
      Clauses : CCL.Clause_Model;
      Results : CCL.Result_Model;
   begin
      Add_Unit (Units, 1, "Client", CCL.Unit_Package_Spec);
      Add_Unit (Units, 2, "Pkg", CCL.Unit_Package_Spec);
      Add_Clause (Clauses, 1, "with Pkg", CCL.Clause_With,
                  Context => 1, Target_Unit => 2, Duplicate_With => True);
      Add_Clause (Clauses, 2, "use Pkg", CCL.Clause_Use_Package,
                  Context => 1, Target_Unit => 2, Ambiguous_Use => True);
      Add_Clause (Clauses, 3, "with Pkg stale", CCL.Clause_With,
                  Context => 1, Target_Unit => 2, Expected_Source_FP => 42,
                  Expected_Closure_FP => 43);
      Results := CCL.Build (Units, Types, Clauses);
      Assert (CCL.Result_At (Results, 1).Status = CCL.Legality_Duplicate_With,
              "duplicate with clauses are rejected deterministically");
      Assert (CCL.Result_At (Results, 2).Status = CCL.Legality_Ambiguous_Use_Homograph,
              "ambiguous use-visible homographs remain blockers outside overload filtering");
      Assert (CCL.Result_At (Results, 3).Status = CCL.Legality_Multiple_Blockers,
              "stale source and closure fingerprints are preserved together");
      Assert (CCL.Result_At (Results, 3).Source_Fingerprint_Blockers = 1,
              "source fingerprint blocker recorded");
      Assert (CCL.Result_At (Results, 3).Closure_Fingerprint_Blockers = 1,
              "closure fingerprint blocker recorded");
   end Test_Duplicates_Ambiguous_Use_And_Fingerprints;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_With_Use_And_Use_Type_Targets'Access,
         "with/use/use type target legality");
      Register_Routine
        (T, Test_Limited_With_Cycles_And_Full_View_Use'Access,
         "limited with cycles and full-view barriers");
      Register_Routine
        (T, Test_Private_With_And_Private_Child_Visibility'Access,
         "private with and private child visibility");
      Register_Routine
        (T, Test_Body_Context_And_Generic_Context_Propagation'Access,
         "body and generic context propagation");
      Register_Routine
        (T, Test_Duplicates_Ambiguous_Use_And_Fingerprints'Access,
         "duplicate clauses, ambiguous use, and fingerprints");
   end Register_Tests;

end Test_Ada_Context_Clause_With_Use_Vertical_Slice_Legality_Pass1330;
