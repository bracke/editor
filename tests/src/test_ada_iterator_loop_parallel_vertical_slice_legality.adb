with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality;

package body Test_Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality is

   package ILP renames Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality;
   use type ILP.Entity_Id;
   use type ILP.Type_Id;
   use type ILP.Check_Id;
   use type ILP.Result_Id;
   use type ILP.Type_Kind;
   use type ILP.View_Kind;
   use type ILP.Iteration_Kind;
   use type ILP.Legality_Status;
   use type ILP.Entity_Info;
   use type ILP.Type_Info;
   use type ILP.Check_Info;
   use type ILP.Result_Info;
   use type ILP.Entity_Model;
   use type ILP.Type_Model;
   use type ILP.Check_Model;
   use type ILP.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality");
   end Name;

   procedure Add_Type
     (Model : in out ILP.Type_Model;
      Id : Natural;
      Name_Text : String;
      Kind : ILP.Type_Kind;
      View : ILP.View_Kind := ILP.View_Full;
      Element : Natural := 0;
      Cursor : Natural := 0;
      Index_T : Natural := 0;
      Base : Natural := 0;
      Discrete : Boolean := False;
      Container : Boolean := False;
      Iterator : Boolean := False;
      Reversible : Boolean := False;
      First_Next : Boolean := False;
      Element_Profile : Boolean := False;
      Has_Element : Boolean := False;
      Parallel_Flag : Boolean := False;
      Tampering_Runtime : Boolean := False;
      Source_FP : Natural := 132800;
      Type_FP : Natural := 232800;
      Profile_FP : Natural := 332800;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0)
   is
      T : ILP.Type_Info;
   begin
      T.Id := ILP.Type_Id (Id);
      T.Name := To_Unbounded_String (Name_Text);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (132800 + Id);
      T.Kind := Kind;
      T.View := View;
      T.Element_Type := ILP.Type_Id (Element);
      T.Cursor_Type := ILP.Type_Id (Cursor);
      T.Index_Type := ILP.Type_Id (Index_T);
      T.Base_Type := ILP.Type_Id (Base);
      T.Is_Discrete := Discrete;
      T.Is_Container := Container;
      T.Is_Iterator := Iterator;
      T.Is_Reversible_Iterator := Reversible;
      T.Has_First_Next_Profile := First_Next;
      T.Has_Element_Profile := Element_Profile;
      T.Has_Has_Element_Profile := Has_Element;
      T.Allows_Parallel_Iteration := Parallel_Flag;
      T.Tampering_Check_Required := Tampering_Runtime;
      T.Source_Fingerprint := Source_FP + Id;
      T.Type_Fingerprint := Type_FP + Id;
      T.Profile_Fingerprint := Profile_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      T.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      ILP.Add_Type (Model, T);
   end Add_Type;

   procedure Add_Entity
     (Model : in out ILP.Entity_Model;
      Id : Natural;
      Name_Text : String;
      Typ : Natural;
      View : ILP.View_Kind := ILP.View_Full;
      Loop_Param : Boolean := False;
      Variable : Boolean := False;
      Constant_View : Boolean := True;
      Shared_Access : Boolean := False;
      Shared_Write : Boolean := False;
      Shared_Read : Boolean := False;
      Source_FP : Natural := 432800;
      Type_FP : Natural := 532800;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      E : ILP.Entity_Info;
   begin
      E.Id := ILP.Entity_Id (Id);
      E.Name := To_Unbounded_String (Name_Text);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (232800 + Id);
      E.Typ := ILP.Type_Id (Typ);
      E.View := View;
      E.Is_Loop_Parameter := Loop_Param;
      E.Is_Variable_View := Variable;
      E.Is_Constant_View := Constant_View;
      E.Has_Shared_State_Access := Shared_Access;
      E.Writes_Shared_State := Shared_Write;
      E.Reads_Shared_State := Shared_Read;
      E.Source_Fingerprint := Source_FP + Id;
      E.Type_Fingerprint := Type_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      ILP.Add_Entity (Model, E);
   end Add_Entity;

   procedure Add_Check
     (Model : in out ILP.Check_Model;
      Id : Natural;
      Name_Text : String;
      Kind : ILP.Iteration_Kind;
      Loop_Param : Natural := 0;
      Iterator_Entity : Natural := 0;
      Container_Entity : Natural := 0;
      Discrete_Subtype : Natural := 0;
      Expected_Element : Natural := 0;
      Actual_Element : Natural := 0;
      Cursor : Natural := 0;
      Reduction_Result : Natural := 0;
      Reduction_Seed : Natural := 0;
      Parallel_Flag : Boolean := False;
      Require_Reversible : Boolean := False;
      Bounds_Static : Boolean := True;
      Bounds_Compatible : Boolean := True;
      Loop_Mode_OK : Boolean := True;
      Iterator_OK : Boolean := True;
      Cursor_OK : Boolean := True;
      Element_OK : Boolean := True;
      Reduction_OK : Boolean := True;
      Seed_OK : Boolean := True;
      Parallel_OK : Boolean := True;
      Shared_OK : Boolean := True;
      Tampering_OK : Boolean := True;
      Runtime_Bounds : Boolean := False;
      Runtime_Tampering : Boolean := False;
      Source_FP : Natural := 632800;
      AST_FP : Natural := 732800;
      Type_FP : Natural := 832800;
      Profile_FP : Natural := 932800;
      Effect_FP : Natural := 1_032_800;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      C : ILP.Check_Info;
   begin
      C.Id := ILP.Check_Id (Id);
      C.Name := To_Unbounded_String (Name_Text);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (332800 + Id);
      C.Kind := Kind;
      C.Loop_Parameter := ILP.Entity_Id (Loop_Param);
      C.Iterator_Entity := ILP.Entity_Id (Iterator_Entity);
      C.Container_Entity := ILP.Entity_Id (Container_Entity);
      C.Discrete_Subtype := ILP.Type_Id (Discrete_Subtype);
      C.Expected_Element_Type := ILP.Type_Id (Expected_Element);
      C.Actual_Element_Type := ILP.Type_Id (Actual_Element);
      C.Cursor_Type := ILP.Type_Id (Cursor);
      C.Reduction_Result_Type := ILP.Type_Id (Reduction_Result);
      C.Reduction_Seed_Type := ILP.Type_Id (Reduction_Seed);
      C.Is_Parallel := Parallel_Flag;
      C.Requires_Reversible_Iterator := Require_Reversible;
      C.Range_Bounds_Static := Bounds_Static;
      C.Range_Bounds_Compatible := Bounds_Compatible;
      C.Loop_Parameter_Mode_OK := Loop_Mode_OK;
      C.Iterator_Profile_OK := Iterator_OK;
      C.Cursor_Profile_OK := Cursor_OK;
      C.Element_Type_OK := Element_OK;
      C.Reduction_Profile_OK := Reduction_OK;
      C.Reduction_Seed_OK := Seed_OK;
      C.Parallel_Allowed := Parallel_OK;
      C.Shared_State_OK := Shared_OK;
      C.Tampering_OK := Tampering_OK;
      C.Runtime_Bounds_Check_Required := Runtime_Bounds;
      C.Runtime_Tampering_Check_Required := Runtime_Tampering;
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
      ILP.Add_Check (Model, C);
   end Add_Check;

   procedure Test_Discrete_And_Array_Loops

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : ILP.Entity_Model;
      Types : ILP.Type_Model;
      Checks : ILP.Check_Model;
      Results : ILP.Result_Model;
   begin
      Add_Type (Types, 1, "Positive", ILP.Type_Integer, Discrete => True);
      Add_Type (Types, 2, "Element", ILP.Type_Element);
      Add_Entity (Entities, 1, "I", 1, Loop_Param => True);
      Add_Entity (Entities, 2, "E", 2, Loop_Param => True);
      Add_Check (Checks, 1, "for I in Positive loop", ILP.Iteration_Discrete_Subtype,
                 Loop_Param => 1, Discrete_Subtype => 1, Runtime_Bounds => True);
      Add_Check (Checks, 2, "for E of A loop", ILP.Iteration_Array_Component,
                 Loop_Param => 2, Discrete_Subtype => 1,
                 Expected_Element => 2, Actual_Element => 2);
      Results := ILP.Build (Entities, Types, Checks);
      Assert (ILP.Result_Count (Results) = 2, "two loop checks expected");
      Assert (ILP.Result_At (Results, 1).Status = ILP.Legality_Legal_With_Runtime_Check,
              "discrete loop with runtime bound check remains legal");
      Assert (ILP.Result_At (Results, 2).Status = ILP.Legality_Legal,
              "array component iterator is legal");
      Assert (ILP.Legal_Count (Results) = 2, "both source-shaped loops accepted");
   end Test_Discrete_And_Array_Loops;

   procedure Test_Container_Iterator_And_Tampering_Runtime

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : ILP.Entity_Model;
      Types : ILP.Type_Model;
      Checks : ILP.Check_Model;
      Results : ILP.Result_Model;
   begin
      Add_Type (Types, 1, "Item", ILP.Type_Element);
      Add_Type (Types, 2, "Cursor", ILP.Type_Cursor);
      Add_Type (Types, 3, "Vector", ILP.Type_Container,
                Element => 1, Cursor => 2, Container => True,
                Element_Profile => True, Has_Element => True,
                Parallel_Flag => True, Tampering_Runtime => True);
      Add_Entity (Entities, 1, "Item", 1, Loop_Param => True);
      Add_Entity (Entities, 2, "V", 3);
      Add_Check (Checks, 1, "for Item of V loop", ILP.Iteration_Container_Element,
                 Loop_Param => 1, Container_Entity => 2,
                 Expected_Element => 1, Parallel_Flag => False);
      Results := ILP.Build (Entities, Types, Checks);
      Assert (ILP.Result_At (Results, 1).Status = ILP.Legality_Legal_With_Runtime_Check,
              "container tampering evidence is represented as a runtime check");
      Assert (ILP.Result_At (Results, 1).Runtime_Check_Count = 1,
              "one tampering runtime check expected");
   end Test_Container_Iterator_And_Tampering_Runtime;

   procedure Test_Parallel_Shared_State_Blocker

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : ILP.Entity_Model;
      Types : ILP.Type_Model;
      Checks : ILP.Check_Model;
      Results : ILP.Result_Model;
   begin
      Add_Type (Types, 1, "Index", ILP.Type_Integer, Discrete => True);
      Add_Entity (Entities, 1, "I", 1, Loop_Param => True, Shared_Access => True);
      Add_Check (Checks, 1, "parallel for I in 1 .. 10 loop",
                 ILP.Iteration_Parallel_Discrete,
                 Loop_Param => 1, Discrete_Subtype => 1,
                 Parallel_Flag => True, Shared_OK => False);
      Results := ILP.Build (Entities, Types, Checks);
      Assert (ILP.Result_At (Results, 1).Status = ILP.Legality_Shared_State_Blocker,
              "parallel loop rejects shared state access");
      Assert (ILP.Error_Count (Results) = 1, "parallel blocker counted");
   end Test_Parallel_Shared_State_Blocker;

   procedure Test_Generalized_Iterator_Profile_And_Reversibility

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : ILP.Entity_Model;
      Types : ILP.Type_Model;
      Checks : ILP.Check_Model;
      Results : ILP.Result_Model;
   begin
      Add_Type (Types, 1, "Item", ILP.Type_Element);
      Add_Type (Types, 2, "Forward_Iterator", ILP.Type_Container,
                Element => 1, Iterator => True, Reversible => False,
                First_Next => True, Parallel_Flag => True);
      Add_Entity (Entities, 1, "X", 1, Loop_Param => True);
      Add_Entity (Entities, 2, "Iter", 2);
      Add_Check (Checks, 1, "for X of reverse Iter loop",
                 ILP.Iteration_Generalized_Iterator,
                 Loop_Param => 1, Iterator_Entity => 2,
                 Expected_Element => 1, Require_Reversible => True);
      Results := ILP.Build (Entities, Types, Checks);
      Assert (ILP.Result_At (Results, 1).Status = ILP.Legality_Reversible_Iterator_Required,
              "reverse generalized iterator requires reversible iterator profile");
   end Test_Generalized_Iterator_Profile_And_Reversibility;

   procedure Test_Reduction_Profile_And_Seed

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : ILP.Entity_Model;
      Types : ILP.Type_Model;
      Checks : ILP.Check_Model;
      Results : ILP.Result_Model;
   begin
      Add_Type (Types, 1, "Natural", ILP.Type_Integer, Discrete => True);
      Add_Type (Types, 2, "Float", ILP.Type_Element);
      Add_Entity (Entities, 1, "Value", 1, Loop_Param => True);
      Add_Check (Checks, 1, "[for Value of Values => Value]'Reduce",
                 ILP.Iteration_Reduction,
                 Loop_Param => 1, Reduction_Result => 1,
                 Reduction_Seed => 2, Seed_OK => False);
      Results := ILP.Build (Entities, Types, Checks);
      Assert (ILP.Result_At (Results, 1).Status = ILP.Legality_Reduction_Seed_Blocker,
              "reduction seed type must conform to reduction result context");
   end Test_Reduction_Profile_And_Seed;

   procedure Test_View_And_Fingerprint_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : ILP.Entity_Model;
      Types : ILP.Type_Model;
      Checks : ILP.Check_Model;
      Results : ILP.Result_Model;
   begin
      Add_Type (Types, 1, "Private_Index", ILP.Type_Integer,
                View => ILP.View_Private, Discrete => True);
      Add_Entity (Entities, 1, "I", 1, Loop_Param => True);
      Add_Check (Checks, 1, "for I in Private_Index loop",
                 ILP.Iteration_Discrete_Subtype,
                 Loop_Param => 1, Discrete_Subtype => 1,
                 Expected_AST_FP => 42);
      Results := ILP.Build (Entities, Types, Checks);
      Assert (ILP.Result_At (Results, 1).Status = ILP.Legality_Multiple_Blockers,
              "private view and stale AST evidence are both preserved");
      Assert (ILP.Result_At (Results, 1).Private_View_Blockers = 1,
              "private view blocker recorded");
      Assert (ILP.Result_At (Results, 1).AST_Fingerprint_Blockers = 1,
              "stale AST fingerprint blocker recorded");
   end Test_View_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Discrete_And_Array_Loops'Access,
         "discrete and array loop legality");
      Register_Routine
        (T, Test_Container_Iterator_And_Tampering_Runtime'Access,
         "container iterator tampering runtime check");
      Register_Routine
        (T, Test_Parallel_Shared_State_Blocker'Access,
         "parallel shared-state blocker");
      Register_Routine
        (T, Test_Generalized_Iterator_Profile_And_Reversibility'Access,
         "generalized iterator profile and reversibility");
      Register_Routine
        (T, Test_Reduction_Profile_And_Seed'Access,
         "reduction profile and seed legality");
      Register_Routine
        (T, Test_View_And_Fingerprint_Blockers'Access,
         "view barriers and stale fingerprints");
   end Register_Tests;

end Test_Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality;
