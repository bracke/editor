with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Tagged_Dispatching_Vertical_Slice_Legality_Pass1311 is

   package TD renames Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality;
   use type TD.Dispatch_Id;
   use type TD.Result_Id;
   use type TD.Dispatch_Kind;
   use type TD.Type_Class;
   use type TD.Primitive_Class;
   use type TD.Override_Mode;
   use type TD.Controlling_Mode;
   use type TD.Legality_Status;
   use type TD.Dispatch_Info;
   use type TD.Result_Info;
   use type TD.Dispatch_Model;
   use type TD.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tagged_Dispatching_Vertical_Slice_Legality_Pass1311");
   end Name;

   procedure Add_Dispatch
     (Model : in out TD.Dispatch_Model;
      Id    : Natural;
      Kind  : TD.Dispatch_Kind;
      Text  : String;
      AST : Boolean := True;
      Context : Boolean := True;
      Type_Kind : TD.Type_Class := TD.Type_Tagged;
      Parent_Type_Kind : TD.Type_Class := TD.Type_Tagged;
      Has_Parent : Boolean := True;
      Parent_Visible : Boolean := True;
      Private_View : Boolean := True;
      Limited_View : Boolean := True;
      Primitive_Kind : TD.Primitive_Class := TD.Primitive_Function;
      Override : TD.Override_Mode := TD.Override_Not_Specified;
      Has_Overridden : Boolean := True;
      Profile_OK : Boolean := True;
      Abstract_Overridden : Boolean := True;
      Concrete_Available : Boolean := True;
      Inherited_Visible : Boolean := True;
      Implements_Interface : Boolean := True;
      Required_Interface : Boolean := True;
      Interface_Profile_OK : Boolean := True;
      Null_Extension_OK : Boolean := True;
      Has_Target : Boolean := True;
      Controlling : TD.Controlling_Mode := TD.Controlling_Operand;
      Has_Controlling_Operand : Boolean := True;
      Operand_Class_Wide : Boolean := True;
      Result_OK : Boolean := True;
      Class_Wide_OK : Boolean := True;
      Candidate_Count : Natural := 1;
      Visible_Candidate_Count : Natural := 1;
      Dispatching_Expected : Boolean := True;
      Runtime_Check : Boolean := False;
      Accessibility_OK : Boolean := True;
      Generic_OK : Boolean := True;
      Renaming_OK : Boolean := True;
      Exception_Finalization_OK : Boolean := True;
      Source_FP : Natural := 131100;
      AST_FP : Natural := 231100;
      Profile_FP : Natural := 331100;
      Subst_FP : Natural := 431100;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0)
   is
      D : TD.Dispatch_Info;
   begin
      D.Id := TD.Dispatch_Id (Id);
      D.Node := Editor.Ada_Syntax_Tree.Node_Id (131100 + Id);
      D.Kind := Kind;
      D.Source_Name := To_Unbounded_String (Text);
      D.Has_AST_Coverage := AST;
      D.Has_Context := Context;
      D.Type_Kind := Type_Kind;
      D.Parent_Type_Kind := Parent_Type_Kind;
      D.Has_Parent_Type := Has_Parent;
      D.Parent_Visible := Parent_Visible;
      D.Private_View_Available := Private_View;
      D.Limited_View_Available := Limited_View;
      D.Primitive_Kind := Primitive_Kind;
      D.Override := Override;
      D.Has_Overridden_Primitive := Has_Overridden;
      D.Profile_Conformant := Profile_OK;
      D.Abstract_Primitive_Overridden := Abstract_Overridden;
      D.Concrete_Primitive_Available := Concrete_Available;
      D.Inherited_Primitive_Visible := Inherited_Visible;
      D.Implements_Interface := Implements_Interface;
      D.Required_Interface_Present := Required_Interface;
      D.Interface_Profile_Conformant := Interface_Profile_OK;
      D.Null_Extension_Legal := Null_Extension_OK;
      D.Has_Dispatching_Target := Has_Target;
      D.Controlling := Controlling;
      D.Has_Controlling_Operand := Has_Controlling_Operand;
      D.Controlling_Operand_Class_Wide := Operand_Class_Wide;
      D.Controlling_Result_Compatible := Result_OK;
      D.Class_Wide_Compatible := Class_Wide_OK;
      D.Candidate_Count := Candidate_Count;
      D.Visible_Candidate_Count := Visible_Candidate_Count;
      D.Dispatching_Call_Expected := Dispatching_Expected;
      D.Runtime_Tag_Check_Required := Runtime_Check;
      D.Accessibility_Legal := Accessibility_OK;
      D.Generic_Contract_Legal := Generic_OK;
      D.Renaming_Legal := Renaming_OK;
      D.Exception_Finalization_Legal := Exception_Finalization_OK;
      D.Source_Fingerprint := Source_FP + Id;
      D.AST_Fingerprint := AST_FP + Id;
      D.Profile_Fingerprint := Profile_FP + Id;
      D.Substitution_Fingerprint := Subst_FP + Id;
      D.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      D.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      D.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      D.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      TD.Add_Dispatch (Model, D);
   end Add_Dispatch;

   procedure Accepts_Source_Shaped_Tagged_And_Dispatching_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : TD.Dispatch_Model;
      Results : TD.Result_Model;
   begin
      Add_Dispatch (Model, 1, TD.Dispatch_Tagged_Type_Declaration,
                    "type Root is tagged record ... end record");
      Add_Dispatch (Model, 2, TD.Dispatch_Type_Extension,
                    "type Child is new Root with record ... end record",
                    Parent_Type_Kind => TD.Type_Tagged);
      Add_Dispatch (Model, 3, TD.Dispatch_Primitive_Override,
                    "overriding procedure P (X : Child)",
                    Override => TD.Override_Required,
                    Has_Overridden => True,
                    Profile_OK => True);
      Add_Dispatch (Model, 4, TD.Dispatch_Dispatching_Call,
                    "P (Root'Class (Obj))",
                    Has_Target => True,
                    Controlling => TD.Controlling_Operand,
                    Has_Controlling_Operand => True);
      Add_Dispatch (Model, 5, TD.Dispatch_Controlling_Result_Call,
                    "Make return Root'Class",
                    Controlling => TD.Controlling_Result,
                    Result_OK => True,
                    Runtime_Check => True);

      Results := TD.Build (Model);

      Assert (TD.Result_Count (Results) = 5, "expected five tagged/dispatching rows");
      Assert (TD.Count_Status (Results, TD.Legality_Legal) = 4,
              "source-shaped tagged and dispatching rows should be legal");
      Assert (TD.Count_Status (Results, TD.Legality_Legal_With_Runtime_Check) = 1,
              "runtime tag check should be preserved as legal-with-check");
      Assert (TD.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Source_Shaped_Tagged_And_Dispatching_Cases;

   procedure Rejects_Type_Extension_Interface_And_View_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : TD.Dispatch_Model;
      Results : TD.Result_Model;
   begin
      Add_Dispatch (Model, 1, TD.Dispatch_Tagged_Type_Declaration,
                    "type U is record ... end record",
                    Type_Kind => TD.Type_Untagged);
      Add_Dispatch (Model, 2, TD.Dispatch_Type_Extension,
                    "type C is new Missing with null record",
                    Has_Parent => False);
      Add_Dispatch (Model, 3, TD.Dispatch_Type_Extension,
                    "type C is new Untagged with null record",
                    Parent_Type_Kind => TD.Type_Untagged);
      Add_Dispatch (Model, 4, TD.Dispatch_Private_Extension,
                    "private extension before full view is visible",
                    Private_View => False);
      Add_Dispatch (Model, 5, TD.Dispatch_Interface_Implementation,
                    "type T implements synchronized interface with wrong profile",
                    Parent_Type_Kind => TD.Type_Synchronized_Interface,
                    Interface_Profile_OK => False);
      Add_Dispatch (Model, 6, TD.Dispatch_Interface_Implementation,
                    "type T misses required interface primitive",
                    Required_Interface => False);

      Results := TD.Build (Model);

      Assert (TD.Count_Status (Results, TD.Legality_Not_Tagged) = 1,
              "untagged type should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Parent_Missing) = 1,
              "missing parent should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Parent_Not_Tagged) = 1,
              "untagged parent should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Private_View_Barrier) = 1,
              "private view barrier should be preserved");
      Assert (TD.Count_Status (Results, TD.Legality_Interface_Mismatch) = 1,
              "interface profile mismatch should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Interface_Not_Implemented) = 1,
              "missing interface primitive should be rejected");
   end Rejects_Type_Extension_Interface_And_View_Errors;

   procedure Rejects_Primitive_Override_And_Inheritance_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : TD.Dispatch_Model;
      Results : TD.Result_Model;
   begin
      Add_Dispatch (Model, 1, TD.Dispatch_Primitive_Override,
                    "overriding P but no parent primitive",
                    Override => TD.Override_Required,
                    Has_Overridden => False);
      Add_Dispatch (Model, 2, TD.Dispatch_Primitive_Override,
                    "not overriding P but parent primitive exists",
                    Override => TD.Override_Forbidden,
                    Has_Overridden => True);
      Add_Dispatch (Model, 3, TD.Dispatch_Primitive_Override,
                    "overriding P with wrong profile",
                    Profile_OK => False);
      Add_Dispatch (Model, 4, TD.Dispatch_Abstract_Primitive,
                    "abstract primitive not overridden by concrete extension",
                    Abstract_Overridden => False);
      Add_Dispatch (Model, 5, TD.Dispatch_Primitive_Declaration,
                    "nonabstract primitive has no concrete body/evidence",
                    Primitive_Kind => TD.Primitive_Function,
                    Concrete_Available => False);
      Add_Dispatch (Model, 6, TD.Dispatch_Inherited_Primitive,
                    "inherited primitive hidden by private extension",
                    Inherited_Visible => False);

      Results := TD.Build (Model);

      Assert (TD.Count_Status (Results, TD.Legality_Overriding_Required) = 1,
              "required overriding without parent primitive should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Overriding_Forbidden) = 1,
              "forbidden overriding with parent primitive should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Primitive_Profile_Mismatch) = 1,
              "profile mismatch should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Abstract_Primitive_Not_Overridden) = 1,
              "unimplemented abstract primitive should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Concrete_Primitive_Required) = 1,
              "missing concrete primitive evidence should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Inherited_Primitive_Hidden) = 1,
              "hidden inherited primitive should be rejected");
   end Rejects_Primitive_Override_And_Inheritance_Errors;

   procedure Rejects_Dispatching_Call_And_Fingerprint_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : TD.Dispatch_Model;
      Results : TD.Result_Model;
   begin
      Add_Dispatch (Model, 1, TD.Dispatch_Dispatching_Call,
                    "dispatch call without target",
                    Has_Target => False);
      Add_Dispatch (Model, 2, TD.Dispatch_Dispatching_Call,
                    "dispatch call without controlling operand",
                    Has_Controlling_Operand => False);
      Add_Dispatch (Model, 3, TD.Dispatch_Controlling_Result_Call,
                    "controlling result mismatch",
                    Controlling => TD.Controlling_Result,
                    Result_OK => False);
      Add_Dispatch (Model, 4, TD.Dispatch_Class_Wide_Call,
                    "class-wide call with specific controlling operand",
                    Operand_Class_Wide => False);
      Add_Dispatch (Model, 5, TD.Dispatch_Dispatching_Call,
                    "ambiguous dispatching primitive",
                    Visible_Candidate_Count => 2);
      Add_Dispatch (Model, 6, TD.Dispatch_Dispatching_Call,
                    "call expected to be static non-dispatching",
                    Dispatching_Expected => False);
      Add_Dispatch (Model, 7, TD.Dispatch_Dispatching_Call,
                    "dispatching call stale profile fingerprint",
                    Expected_Profile_FP => 99);

      Results := TD.Build (Model);

      Assert (TD.Count_Status (Results, TD.Legality_Dispatching_Target_Missing) = 1,
              "missing dispatch target should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Controlling_Operand_Missing) = 1,
              "missing controlling operand should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Controlling_Result_Mismatch) = 1,
              "controlling result mismatch should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Class_Wide_Mismatch) = 1,
              "class-wide mismatch should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Ambiguous_Dispatching_Call) = 1,
              "ambiguous dispatching call should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Non_Dispatching_Call) = 1,
              "unexpected dispatching should be rejected");
      Assert (TD.Count_Status (Results, TD.Legality_Profile_Fingerprint_Mismatch) = 1,
              "stale profile fingerprint should be rejected");
   end Rejects_Dispatching_Call_And_Fingerprint_Errors;

   procedure Rejects_Cross_Consumer_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : TD.Dispatch_Model;
      Results : TD.Result_Model;
   begin
      Add_Dispatch (Model, 1, TD.Dispatch_Dispatching_Call,
                    "dispatching access result escapes master",
                    Accessibility_OK => False);
      Add_Dispatch (Model, 2, TD.Dispatch_Dispatching_Call,
                    "generic formal dispatching contract blocked",
                    Generic_OK => False);
      Add_Dispatch (Model, 3, TD.Dispatch_Dispatching_Call,
                    "renamed primitive dispatch target blocked",
                    Renaming_OK => False);
      Add_Dispatch (Model, 4, TD.Dispatch_Dispatching_Call,
                    "controlled dispatching result finalization blocked",
                    Exception_Finalization_OK => False);
      Add_Dispatch (Model, 5, TD.Dispatch_Dispatching_Call,
                    "multiple dispatch blockers",
                    Has_Target => False,
                    Accessibility_OK => False);

      Results := TD.Build (Model);

      Assert (TD.Count_Status (Results, TD.Legality_Accessibility_Blocked) = 1,
              "accessibility blocker should be preserved");
      Assert (TD.Count_Status (Results, TD.Legality_Generic_Contract_Blocked) = 1,
              "generic contract blocker should be preserved");
      Assert (TD.Count_Status (Results, TD.Legality_Renaming_Blocked) = 1,
              "renaming blocker should be preserved");
      Assert (TD.Count_Status (Results, TD.Legality_Exception_Finalization_Blocked) = 1,
              "exception/finalization blocker should be preserved");
      Assert (TD.Count_Status (Results, TD.Legality_Multiple_Blockers) = 1,
              "multiple blockers should not be flattened");
   end Rejects_Cross_Consumer_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Tagged_And_Dispatching_Cases'Access,
         "accepts source-shaped tagged type and dispatching cases");
      Register_Routine
        (T, Rejects_Type_Extension_Interface_And_View_Errors'Access,
         "rejects type-extension, interface, and view errors");
      Register_Routine
        (T, Rejects_Primitive_Override_And_Inheritance_Errors'Access,
         "rejects primitive overriding and inheritance errors");
      Register_Routine
        (T, Rejects_Dispatching_Call_And_Fingerprint_Errors'Access,
         "rejects dispatching call and fingerprint errors");
      Register_Routine
        (T, Rejects_Cross_Consumer_Blockers'Access,
         "preserves cross-consumer blockers");
   end Register_Tests;

end Test_Ada_Tagged_Dispatching_Vertical_Slice_Legality_Pass1311;
