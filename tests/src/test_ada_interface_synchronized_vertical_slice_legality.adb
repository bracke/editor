with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality;

package body Test_Ada_Interface_Synchronized_Vertical_Slice_Legality is

   package ISL renames Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality;
   use type ISL.Type_Id;
   use type ISL.Primitive_Id;
   use type ISL.Check_Id;
   use type ISL.Result_Id;
   use type ISL.Type_Kind;
   use type ISL.Primitive_Kind;
   use type ISL.View_Kind;
   use type ISL.Check_Kind;
   use type ISL.Legality_Status;
   use type ISL.Interface_Type_Info;
   use type ISL.Type_Model;
   use type ISL.Primitive_Info;
   use type ISL.Primitive_Model;
   use type ISL.Check_Info;
   use type ISL.Check_Model;
   use type ISL.Result_Info;
   use type ISL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Interface_Synchronized_Vertical_Slice_Legality");
   end Name;

   procedure Add_Type
     (Model : in out ISL.Type_Model;
      Id : Natural;
      Name : String;
      Kind : ISL.Type_Kind;
      View : ISL.View_Kind := ISL.View_Full;
      Parent : Natural := 0;
      Interface_Flag : Boolean := True;
      Limited_Flag : Boolean := False;
      Task_Flag : Boolean := False;
      Protected_Flag : Boolean := False;
      Synchronized_Flag : Boolean := False;
      Inheritance_OK : Boolean := True;
      Source_FP : Natural := 133200;
      AST_FP : Natural := 233200;
      Type_FP : Natural := 333200;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      T : ISL.Interface_Type_Info;
   begin
      T.Id := ISL.Type_Id (Id);
      T.Name := To_Unbounded_String (Name);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (133200 + Id);
      T.Kind := Kind;
      T.View := View;
      T.Parent := ISL.Type_Id (Parent);
      T.Is_Interface := Interface_Flag;
      T.Is_Limited_Interface := Limited_Flag;
      T.Is_Task_Interface := Task_Flag;
      T.Is_Protected_Interface := Protected_Flag;
      T.Is_Synchronized_Interface := Synchronized_Flag;
      T.Inheritance_Compatible := Inheritance_OK;
      T.Source_Fingerprint := Source_FP + Id;
      T.AST_Fingerprint := AST_FP + Id;
      T.Type_Fingerprint := Type_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      T.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      ISL.Add_Type (Model, T);
   end Add_Type;

   procedure Add_Primitive
     (Model : in out ISL.Primitive_Model;
      Id : Natural;
      Name : String;
      Kind : ISL.Primitive_Kind;
      Owner : Natural;
      Parent_Primitive : Natural := 0;
      Abstract_Flag : Boolean := False;
      Null_Flag : Boolean := False;
      Overriding_Flag : Boolean := True;
      Profile_OK : Boolean := True;
      Mode_OK : Boolean := True;
      Result_OK : Boolean := True;
      Sync_OK : Boolean := True;
      Null_OK : Boolean := True;
      View : ISL.View_Kind := ISL.View_Full;
      Source_FP : Natural := 433200;
      Profile_FP : Natural := 533200;
      Effect_FP : Natural := 633200;
      Expected_Source_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      P : ISL.Primitive_Info;
   begin
      P.Id := ISL.Primitive_Id (Id);
      P.Name := To_Unbounded_String (Name);
      P.Node := Editor.Ada_Syntax_Tree.Node_Id (233200 + Id);
      P.Kind := Kind;
      P.Owner := ISL.Type_Id (Owner);
      P.Parent_Primitive := ISL.Primitive_Id (Parent_Primitive);
      P.Is_Abstract := Abstract_Flag;
      P.Is_Null_Procedure := Null_Flag;
      P.Is_Overriding := Overriding_Flag;
      P.Profile_Conformant := Profile_OK;
      P.Mode_Conformant := Mode_OK;
      P.Result_Conformant := Result_OK;
      P.Synchronized_Override_OK := Sync_OK;
      P.Null_Procedure_Allowed := Null_OK;
      P.View := View;
      P.Source_Fingerprint := Source_FP + Id;
      P.Profile_Fingerprint := Profile_FP + Id;
      P.Effect_Fingerprint := Effect_FP + Id;
      P.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      P.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      P.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      ISL.Add_Primitive (Model, P);
   end Add_Primitive;

   procedure Add_Check
     (Model : in out ISL.Check_Model;
      Id : Natural;
      Name : String;
      Kind : ISL.Check_Kind;
      Typ : Natural := 0;
      Parent_Typ : Natural := 0;
      Primitive : Natural := 0;
      Parent_Primitive : Natural := 0;
      Expected_Kind : ISL.Type_Kind := ISL.Type_Unknown;
      Requires_Limited : Boolean := False;
      Requires_Sync : Boolean := False;
      Inheritance_OK : Boolean := True;
      Profile_OK : Boolean := True;
      Mode_OK : Boolean := True;
      Result_OK : Boolean := True;
      Override_OK : Boolean := True;
      Abstract_Implemented : Boolean := True;
      Sync_OK : Boolean := True;
      Dispatch_Profile_OK : Boolean := True;
      Dispatch_Ambiguous : Boolean := False;
      Static_Interface_Call : Boolean := False;
      Null_OK : Boolean := True;
      Null_Profile_OK : Boolean := True;
      Source_FP : Natural := 733200;
      AST_FP : Natural := 833200;
      Type_FP : Natural := 933200;
      Profile_FP : Natural := 1_033_200;
      Effect_FP : Natural := 1_133_200;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      C : ISL.Check_Info;
   begin
      C.Id := ISL.Check_Id (Id);
      C.Name := To_Unbounded_String (Name);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (333200 + Id);
      C.Kind := Kind;
      C.Interface_Type := ISL.Type_Id (Typ);
      C.Parent_Interface := ISL.Type_Id (Parent_Typ);
      C.Primitive := ISL.Primitive_Id (Primitive);
      C.Parent_Primitive := ISL.Primitive_Id (Parent_Primitive);
      C.Expected_Interface_Kind := Expected_Kind;
      C.Requires_Limited_Interface := Requires_Limited;
      C.Requires_Synchronized_Interface := Requires_Sync;
      C.Inheritance_Compatible := Inheritance_OK;
      C.Profile_Conformant := Profile_OK;
      C.Mode_Conformant := Mode_OK;
      C.Result_Conformant := Result_OK;
      C.Overriding_Indicator_OK := Override_OK;
      C.Abstract_Primitive_Implemented := Abstract_Implemented;
      C.Synchronized_Override_OK := Sync_OK;
      C.Dispatching_Profile_OK := Dispatch_Profile_OK;
      C.Dispatching_Ambiguous := Dispatch_Ambiguous;
      C.Static_Call_To_Interface_Primitive := Static_Interface_Call;
      C.Null_Procedure_Allowed := Null_OK;
      C.Null_Procedure_Profile_OK := Null_Profile_OK;
      C.Source_Fingerprint := Source_FP + Id;
      C.AST_Fingerprint := AST_FP + Id;
      C.Type_Fingerprint := Type_FP + Id;
      C.Profile_Fingerprint := Profile_FP + Id;
      C.Effect_Fingerprint := Effect_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      C.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      C.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      C.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      ISL.Add_Check (Model, C);
   end Add_Check;

   procedure Expect_Status
     (Results : ISL.Result_Model;
      Index : Positive;
      Status : ISL.Legality_Status) is
   begin
      Assert
        (ISL.Result_At (Results, Index).Status = Status,
         "unexpected interface/synchronized legality status");
   end Expect_Status;

   procedure Test_Interface_Declarations_And_Inheritance

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Types : ISL.Type_Model;
      Prims : ISL.Primitive_Model;
      Checks : ISL.Check_Model;
      Results : ISL.Result_Model;
   begin
      Add_Type (Types, 1, "Root_Interface", ISL.Type_Interface);
      Add_Type
        (Types, 2, "Synchronized_Interface", ISL.Type_Synchronized_Interface,
         Limited_Flag => True, Synchronized_Flag => True);
      Add_Type
        (Types, 3, "Plain_Tagged", ISL.Type_Ordinary_Tagged,
         Interface_Flag => False);
      Add_Type
        (Types, 4, "Bad_Child", ISL.Type_Interface,
         Parent => 1, Inheritance_OK => False);

      Add_Check
        (Checks, 1, "ordinary interface declaration",
         ISL.Check_Interface_Declaration, Typ => 1,
         Expected_Kind => ISL.Type_Interface);
      Add_Check
        (Checks, 2, "non-interface rejected",
         ISL.Check_Interface_Declaration, Typ => 3,
         Expected_Kind => ISL.Type_Interface);
      Add_Check
        (Checks, 3, "sync interface declaration",
         ISL.Check_Interface_Declaration, Typ => 2,
         Expected_Kind => ISL.Type_Synchronized_Interface,
         Requires_Limited => True, Requires_Sync => True);
      Add_Check
        (Checks, 4, "bad interface inheritance",
         ISL.Check_Interface_Inheritance, Typ => 4, Parent_Typ => 1,
         Inheritance_OK => False);

      Results := ISL.Build (Types, Prims, Checks);
      Assert (ISL.Count (Results) = 4, "expected four interface checks");
      Expect_Status (Results, 1, ISL.Legality_Legal);
      Expect_Status (Results, 2, ISL.Legality_Multiple_Blockers);
      Expect_Status (Results, 3, ISL.Legality_Legal);
      Expect_Status (Results, 4, ISL.Legality_Inheritance_Incompatible);
   end Test_Interface_Declarations_And_Inheritance;

   procedure Test_Primitive_Override_And_Synchronized_Override

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Types : ISL.Type_Model;
      Prims : ISL.Primitive_Model;
      Checks : ISL.Check_Model;
      Results : ISL.Result_Model;
   begin
      Add_Type
        (Types, 1, "Sync", ISL.Type_Synchronized_Interface,
         Limited_Flag => True, Synchronized_Flag => True);
      Add_Primitive
        (Prims, 1, "Op", ISL.Primitive_Procedure, Owner => 1,
         Abstract_Flag => False, Overriding_Flag => True);
      Add_Primitive
        (Prims, 2, "Parent_Op", ISL.Primitive_Procedure, Owner => 1,
         Abstract_Flag => True, Overriding_Flag => True);
      Add_Primitive
        (Prims, 3, "Bad_Profile", ISL.Primitive_Procedure, Owner => 1,
         Profile_OK => False);
      Add_Primitive
        (Prims, 4, "Bad_Sync", ISL.Primitive_Procedure, Owner => 1,
         Sync_OK => False);

      Add_Check
        (Checks, 1, "override ok", ISL.Check_Primitive_Override,
         Typ => 1, Primitive => 1, Parent_Primitive => 2);
      Add_Check
        (Checks, 2, "profile mismatch", ISL.Check_Primitive_Override,
         Typ => 1, Primitive => 3, Parent_Primitive => 2);
      Add_Check
        (Checks, 3, "abstract not implemented", ISL.Check_Primitive_Override,
         Typ => 1, Primitive => 2, Parent_Primitive => 2,
         Abstract_Implemented => False);
      Add_Check
        (Checks, 4, "bad synchronized override", ISL.Check_Synchronized_Override,
         Typ => 1, Primitive => 4);

      Results := ISL.Build (Types, Prims, Checks);
      Assert (ISL.Count (Results) = 4, "expected four primitive checks");
      Expect_Status (Results, 1, ISL.Legality_Legal);
      Expect_Status (Results, 2, ISL.Legality_Primitive_Profile_Mismatch);
      Expect_Status (Results, 3, ISL.Legality_Abstract_Primitive_Not_Implemented);
      Expect_Status (Results, 4, ISL.Legality_Synchronized_Override_Mismatch);
   end Test_Primitive_Override_And_Synchronized_Override;

   procedure Test_Dispatching_Null_Procedure_Views_And_Freshness

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Types : ISL.Type_Model;
      Prims : ISL.Primitive_Model;
      Checks : ISL.Check_Model;
      Results : ISL.Result_Model;
   begin
      Add_Type (Types, 1, "Iface", ISL.Type_Interface);
      Add_Type
        (Types, 2, "Private_Iface", ISL.Type_Interface,
         View => ISL.View_Private);
      Add_Type
        (Types, 3, "Stale_Iface", ISL.Type_Interface,
         Expected_Type_FP => 123);
      Add_Primitive (Prims, 1, "Call", ISL.Primitive_Procedure, Owner => 1);
      Add_Primitive
        (Prims, 2, "Null_P", ISL.Primitive_Null_Procedure, Owner => 1,
         Null_Flag => True);
      Add_Primitive
        (Prims, 3, "Bad_Null", ISL.Primitive_Function, Owner => 1,
         Null_Flag => False);

      Add_Check
        (Checks, 1, "dispatching ok", ISL.Check_Dispatching_Interface_Call,
         Typ => 1, Primitive => 1);
      Add_Check
        (Checks, 2, "ambiguous dispatch", ISL.Check_Dispatching_Interface_Call,
         Typ => 1, Primitive => 1, Dispatch_Ambiguous => True);
      Add_Check
        (Checks, 3, "null proc ok", ISL.Check_Null_Procedure,
         Typ => 1, Primitive => 2);
      Add_Check
        (Checks, 4, "null proc bad kind", ISL.Check_Null_Procedure,
         Typ => 1, Primitive => 3);
      Add_Check
        (Checks, 5, "private interface view", ISL.Check_Interface_Declaration,
         Typ => 2);
      Add_Check
        (Checks, 6, "stale type fingerprint", ISL.Check_Interface_Declaration,
         Typ => 3);
      Add_Check
        (Checks, 7, "stale check source", ISL.Check_Interface_Declaration,
         Typ => 1, Expected_Source_FP => 999);

      Results := ISL.Build (Types, Prims, Checks);
      Assert (ISL.Count (Results) = 7, "expected seven dispatch/view checks");
      Expect_Status (Results, 1, ISL.Legality_Legal);
      Expect_Status (Results, 2, ISL.Legality_Ambiguous_Dispatching_Call);
      Expect_Status (Results, 3, ISL.Legality_Legal);
      Expect_Status (Results, 4, ISL.Legality_Null_Procedure_Not_Allowed);
      Expect_Status (Results, 5, ISL.Legality_Private_View_Barrier);
      Expect_Status (Results, 6, ISL.Legality_Type_Fingerprint_Mismatch);
      Expect_Status (Results, 7, ISL.Legality_Source_Fingerprint_Mismatch);
   end Test_Dispatching_Null_Procedure_Views_And_Freshness;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Interface_Declarations_And_Inheritance'Access,
         "interface declarations and inheritance");
      Register_Routine
        (T, Test_Primitive_Override_And_Synchronized_Override'Access,
         "primitive and synchronized overriding");
      Register_Routine
        (T, Test_Dispatching_Null_Procedure_Views_And_Freshness'Access,
         "dispatching null procedures views and freshness");
   end Register_Tests;

end Test_Ada_Interface_Synchronized_Vertical_Slice_Legality;
