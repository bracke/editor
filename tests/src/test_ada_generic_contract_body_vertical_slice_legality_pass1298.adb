with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Contract_Body_Vertical_Slice_Legality_Pass1298 is

   package GCL renames Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality;
   use type GCL.Instance_Id;
   use type GCL.Formal_Id;
   use type GCL.Actual_Id;
   use type GCL.Result_Id;
   use type GCL.Formal_Kind;
   use type GCL.Actual_Kind;
   use type GCL.Formal_Mode;
   use type GCL.Generic_Status;
   use type GCL.Instance_Info;
   use type GCL.Formal_Info;
   use type GCL.Actual_Info;
   use type GCL.Result_Info;
   use type GCL.Instance_Model;
   use type GCL.Formal_Model;
   use type GCL.Actual_Model;
   use type GCL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Generic_Contract_Body_Vertical_Slice_Legality_Pass1298");
   end Name;

   procedure Add_Instance
     (Instances : in out GCL.Instance_Model;
      Id        : Natural;
      Node      : Natural;
      Generic_Name : String;
      Requires_Body : Boolean := False;
      Body_Available : Boolean := True;
      Body_Accepted : Boolean := True;
      Nested : Boolean := False;
      Cycle  : Boolean := False;
      Private_Allowed : Boolean := False;
      Formal_FP : Natural := 100;
      Actual_FP : Natural := 200;
      Subst_FP  : Natural := 300)
   is
      I : GCL.Instance_Info;
   begin
      I.Id := GCL.Instance_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (Node);
      I.Generic_Name := To_Unbounded_String (Generic_Name);
      I.Instance_Name := To_Unbounded_String (Generic_Name & "_Instance");
      I.Requires_Body_Replay := Requires_Body;
      I.Body_Available := Body_Available;
      I.Body_Replay_Accepted := Body_Accepted;
      I.Nested_Instance := Nested;
      I.Nested_Cycle := Cycle;
      I.Private_View_Allowed := Private_Allowed;
      I.Formal_Fingerprint := (if Formal_FP = 0 then 0 else Formal_FP + Id);
      I.Actual_Fingerprint := (if Actual_FP = 0 then 0 else Actual_FP + Id);
      I.Substitution_Fingerprint := (if Subst_FP = 0 then 0 else Subst_FP + Id);
      I.Source_Fingerprint := Node * 17 + Id;
      GCL.Add_Instance (Instances, I);
   end Add_Instance;

   procedure Add_Formal
     (Formals : in out GCL.Formal_Model;
      Id      : Natural;
      Inst    : Natural;
      Name    : String;
      Kind    : GCL.Formal_Kind;
      Class   : String := "";
      Mode    : GCL.Formal_Mode := GCL.Mode_None;
      Profile : String := "";
      Package_Contract : String := "";
      Required : Boolean := True;
      Default  : Boolean := False;
      Private_View : Boolean := False)
   is
      F : GCL.Formal_Info;
   begin
      F.Id := GCL.Formal_Id (Id);
      F.Instance := GCL.Instance_Id (Inst);
      F.Name := To_Unbounded_String (Name);
      F.Kind := Kind;
      F.Type_Class := To_Unbounded_String (Class);
      F.Mode := Mode;
      F.Profile := To_Unbounded_String (Profile);
      F.Package_Contract := To_Unbounded_String (Package_Contract);
      F.Required := Required;
      F.Has_Default := Default;
      F.Requires_Private_View := Private_View;
      F.Formal_Fingerprint := Id * 19;
      GCL.Add_Formal (Formals, F);
   end Add_Formal;

   procedure Add_Actual
     (Actuals : in out GCL.Actual_Model;
      Id      : Natural;
      Inst    : Natural;
      Formal  : String;
      Kind    : GCL.Actual_Kind;
      Class   : String := "";
      Mode    : GCL.Formal_Mode := GCL.Mode_None;
      Profile : String := "";
      Package_Contract : String := "";
      Private_View : Boolean := False)
   is
      A : GCL.Actual_Info;
   begin
      A.Id := GCL.Actual_Id (Id);
      A.Instance := GCL.Instance_Id (Inst);
      A.Formal_Name := To_Unbounded_String (Formal);
      A.Kind := Kind;
      A.Type_Class := To_Unbounded_String (Class);
      A.Mode := Mode;
      A.Profile := To_Unbounded_String (Profile);
      A.Package_Contract := To_Unbounded_String (Package_Contract);
      A.Uses_Private_View := Private_View;
      A.Actual_Fingerprint := Id * 23;
      GCL.Add_Actual (Actuals, A);
   end Add_Actual;

   procedure Accepts_Formal_Type_Object_Subprogram_And_Package_Contracts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Instances : GCL.Instance_Model;
      Formals : GCL.Formal_Model;
      Actuals : GCL.Actual_Model;
   begin
      --  package G is
      --     type T is private;
      --     with procedure Put (X : T);
      --     Initial : in T := Default_T;
      --     with package Helpers is new Helper_G (...);
      --  package I is new G (Integer, Put_Integer, Helpers_Integer);
      Add_Instance (Instances, 1, 129801, "G", Requires_Body => True);
      Add_Formal (Formals, 1, 1, "T", GCL.Formal_Type, Class => "private");
      Add_Formal (Formals, 2, 1, "Initial", GCL.Formal_Object,
                  Class => "integer", Mode => GCL.Mode_In,
                  Required => False, Default => True);
      Add_Formal (Formals, 3, 1, "Put", GCL.Formal_Subprogram,
                  Profile => "procedure(integer)");
      Add_Formal (Formals, 4, 1, "Helpers", GCL.Formal_Package,
                  Package_Contract => "Helper_G(Integer)");
      Add_Actual (Actuals, 1, 1, "T", GCL.Actual_Type, Class => "private");
      Add_Actual (Actuals, 2, 1, "Put", GCL.Actual_Subprogram,
                  Profile => "procedure(integer)");
      Add_Actual (Actuals, 3, 1, "Helpers", GCL.Actual_Package,
                  Package_Contract => "Helper_G(Integer)");

      --  Nested instantiation remains a distinct accepted outcome when the
      --  contract, actual substitution, and body replay all agree.
      Add_Instance (Instances, 2, 129802, "Outer.Inner", Requires_Body => True,
                    Nested => True);
      Add_Formal (Formals, 5, 2, "Element", GCL.Formal_Type, Class => "discrete");
      Add_Actual (Actuals, 4, 2, "Element", GCL.Actual_Type, Class => "enumeration");

      declare
         Model : constant GCL.Result_Model := GCL.Build (Instances, Formals, Actuals);
      begin
         Assert (GCL.Result_Count (Model) = 2,
                 "each generic instantiation should produce one contract/body result");
         Assert (GCL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129801)).Status =
                 GCL.Generic_Legal_Formal_Package_Contract,
                 "formal package and formal subprogram contracts should match under substitution");
         Assert (GCL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129801)).Defaulted_Formals = 1,
                 "defaulted formal object should be counted rather than treated as missing");
         Assert (GCL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (129802)).Status =
                 GCL.Generic_Legal_Nested_Instance,
                 "nested instantiation should be accepted when replay evidence is acyclic");
         Assert (GCL.Legal_Count (Model) = 2,
                 "both vertical generic instances should be legal");
      end;
   end Accepts_Formal_Type_Object_Subprogram_And_Package_Contracts;

   procedure Reports_Concrete_Generic_Contract_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Instances : GCL.Instance_Model;
      Formals : GCL.Formal_Model;
      Actuals : GCL.Actual_Model;
   begin
      Add_Instance (Instances, 1, 129811, "Missing_Actual_G");
      Add_Formal (Formals, 1, 1, "T", GCL.Formal_Type, Class => "integer");

      Add_Instance (Instances, 2, 129812, "Kind_Mismatch_G");
      Add_Formal (Formals, 2, 2, "Op", GCL.Formal_Subprogram, Profile => "function(integer)return integer");
      Add_Actual (Actuals, 1, 2, "Op", GCL.Actual_Object, Class => "integer");

      Add_Instance (Instances, 3, 129813, "Profile_G");
      Add_Formal (Formals, 3, 3, "Op", GCL.Formal_Subprogram, Profile => "procedure(integer)");
      Add_Actual (Actuals, 2, 3, "Op", GCL.Actual_Subprogram, Profile => "procedure(float)");

      Add_Instance (Instances, 4, 129814, "Package_G");
      Add_Formal (Formals, 4, 4, "P", GCL.Formal_Package, Package_Contract => "Helper_G(Integer)");
      Add_Actual (Actuals, 3, 4, "P", GCL.Actual_Package, Package_Contract => "Helper_G(Float)");

      Add_Instance (Instances, 5, 129815, "Private_G");
      Add_Formal (Formals, 5, 5, "T", GCL.Formal_Type, Class => "private", Private_View => True);
      Add_Actual (Actuals, 4, 5, "T", GCL.Actual_Type, Class => "private", Private_View => True);

      Add_Instance (Instances, 6, 129816, "Body_G", Requires_Body => True, Body_Available => False);

      Add_Instance (Instances, 7, 129817, "Cycle_G", Nested => True, Cycle => True);

      Add_Instance (Instances, 8, 129818, "Fingerprint_G", Subst_FP => 0);

      declare
         Model : constant GCL.Result_Model := GCL.Build (Instances, Formals, Actuals);
      begin
         Assert (GCL.Count_Status (Model, GCL.Generic_Missing_Actual) = 1,
                 "missing required actual should be explicit");
         Assert (GCL.Count_Status (Model, GCL.Generic_Formal_Actual_Kind_Mismatch) = 1,
                 "formal/actual kind mismatch should be explicit");
         Assert (GCL.Count_Status (Model, GCL.Generic_Subprogram_Profile_Mismatch) = 1,
                 "formal subprogram profile mismatch should be explicit");
         Assert (GCL.Count_Status (Model, GCL.Generic_Package_Contract_Mismatch) = 1,
                 "formal package contract mismatch should be explicit");
         Assert (GCL.Count_Status (Model, GCL.Generic_Private_View_Barrier) = 1,
                 "private-view barriers should block contract acceptance");
         Assert (GCL.Count_Status (Model, GCL.Generic_Body_Unavailable) = 1,
                 "generic body replay should require body availability when requested");
         Assert (GCL.Count_Status (Model, GCL.Generic_Nested_Instance_Cycle) = 1,
                 "nested instantiation cycles should block replay");
         Assert (GCL.Count_Status (Model, GCL.Generic_Substitution_Fingerprint_Mismatch) = 1,
                 "missing substitution fingerprint should block stale generic evidence");
         Assert (GCL.Error_Count (Model) = 8,
                 "all concrete generic contract blockers should be counted");
      end;
   end Reports_Concrete_Generic_Contract_Blockers;

   procedure Empty_Inputs_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Instances : GCL.Instance_Model;
      Formals : GCL.Formal_Model;
      Actuals : GCL.Actual_Model;
      Model : constant GCL.Result_Model := GCL.Build (Instances, Formals, Actuals);
   begin
      Assert (GCL.Result_Count (Model) = 0,
              "empty generic vertical-slice input should produce no rows");
      Assert (not GCL.Has_Result
                (GCL.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (77))),
              "absent node lookup should return no result row");
   end Empty_Inputs_Are_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Formal_Type_Object_Subprogram_And_Package_Contracts'Access,
         "Pass1298 accepts concrete generic formal/actual and body-replay contracts");
      Register_Routine
        (T, Reports_Concrete_Generic_Contract_Blockers'Access,
         "Pass1298 reports concrete generic contract/body blockers");
      Register_Routine
        (T, Empty_Inputs_Are_Deterministic'Access,
         "Pass1298 keeps empty generic vertical-slice inputs deterministic");
   end Register_Tests;

end Test_Ada_Generic_Contract_Body_Vertical_Slice_Legality_Pass1298;
