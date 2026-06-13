with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Accessibility_Scope_Consumer_Legality;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Scope_Consumer_Legality_Pass1162 is

   package AC renames Editor.Ada_Accessibility_Scope_Consumer_Legality;
   use type AC.Accessibility_Consumer_Row_Id;
   use type AC.Accessibility_Consumer_Context_Kind;
   use type AC.Accessibility_Consumer_Status;
   use type AC.Accessibility_Consumer_Context_Info;
   use type AC.Accessibility_Consumer_Info;
   use type AC.Accessibility_Consumer_Context_Model;
   use type AC.Accessibility_Consumer_Set;
   use type AC.Accessibility_Consumer_Model;
   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   use type Scope.Scope_Context_Id;
   use type Scope.Scope_Legality_Id;
   use type Scope.Scope_Level;
   use type Scope.Scope_Context_Kind;
   use type Scope.Scope_Legality_Status;
   use type Scope.Scope_Context_Info;
   use type Scope.Scope_Legality_Info;
   use type Scope.Scope_Context_Model;
   use type Scope.Scope_Result_Set;
   use type Scope.Scope_Legality_Model;
   package Disc_Gen renames Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
   use type Disc_Gen.Discriminant_Generic_Row_Id;
   use type Disc_Gen.Discriminant_Generic_Context_Kind;
   use type Disc_Gen.Discriminant_Generic_Status;
   use type Disc_Gen.Discriminant_Generic_Context_Info;
   use type Disc_Gen.Discriminant_Generic_Info;
   use type Disc_Gen.Discriminant_Generic_Context_Model;
   use type Disc_Gen.Discriminant_Generic_Set;
   use type Disc_Gen.Discriminant_Generic_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Accessibility_Scope_Consumer_Legality_Pass1162");
   end Name;

   function Sample_Context_Model return AC.Accessibility_Consumer_Context_Model is
      Contexts : AC.Accessibility_Consumer_Context_Model;
      C        : AC.Accessibility_Consumer_Context_Info;
   begin
      C.Id := 1;
      C.Kind := AC.Accessibility_Consumer_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116201);
      C.Object_Name := To_Unbounded_String ("Target");
      C.Scope_Row := Scope.Scope_Legality_Id (1);
      C.Scope_Status := Scope.Scope_Legality_Legal_Static_Level;
      C.Scope_Matches := 1;
      C.Source_Fingerprint := 1201;
      C.Scope_Fingerprint := 2201;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := AC.Accessibility_Consumer_Return_Access;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116202);
      C.Object_Name := To_Unbounded_String ("Result_Access");
      C.Scope_Row := Scope.Scope_Legality_Id (2);
      C.Scope_Status := Scope.Scope_Legality_Return_Access_Master_Too_Short;
      C.Scope_Matches := 1;
      C.Source_Fingerprint := 1202;
      C.Scope_Fingerprint := 2202;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := AC.Accessibility_Consumer_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116203);
      C.Object_Name := To_Unbounded_String ("New_Node");
      C.Scope_Row := Scope.Scope_Legality_Id (3);
      C.Scope_Status := Scope.Scope_Legality_Allocator_Master_Too_Short;
      C.Scope_Matches := 1;
      C.Source_Fingerprint := 1203;
      C.Scope_Fingerprint := 2203;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := AC.Accessibility_Consumer_Access_Discriminant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116204);
      C.Object_Name := To_Unbounded_String ("Owner.D");
      C.Scope_Row := Scope.Scope_Legality_Id (4);
      C.Scope_Status := Scope.Scope_Legality_Legal_Access_Discriminant_Master;
      C.Scope_Matches := 1;
      C.Discriminant_Generic_Row := Disc_Gen.Discriminant_Generic_Row_Id (4);
      C.Discriminant_Generic_Status := Disc_Gen.Discriminant_Generic_Variant_Missing_For_Value;
      C.Discriminant_Generic_Matches := 1;
      C.Source_Fingerprint := 1204;
      C.Scope_Fingerprint := 2204;
      C.Consumer_Fingerprint := 3204;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := AC.Accessibility_Consumer_Generic_Replay;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116205);
      C.Object_Name := To_Unbounded_String ("Formal_Access");
      C.Instance_Name := To_Unbounded_String ("Vector_Instance");
      C.Scope_Row := Scope.Scope_Legality_Id (5);
      C.Scope_Status := Scope.Scope_Legality_Generic_Substitution_Master_Mismatch;
      C.Scope_Matches := 1;
      C.Discriminant_Generic_Row := Disc_Gen.Discriminant_Generic_Row_Id (5);
      C.Discriminant_Generic_Status := Disc_Gen.Discriminant_Generic_Legal_Generic_Replay_Accepted;
      C.Discriminant_Generic_Matches := 1;
      C.Source_Fingerprint := 1205;
      C.Scope_Fingerprint := 2205;
      C.Consumer_Fingerprint := 3205;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := AC.Accessibility_Consumer_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116206);
      C.Object_Name := To_Unbounded_String ("T");
      C.Instance_Name := To_Unbounded_String ("Vector_Instance");
      C.Scope_Row := Scope.Scope_Legality_Id (6);
      C.Scope_Status := Scope.Scope_Legality_Legal_Master_Hierarchy;
      C.Scope_Matches := 1;
      C.Discriminant_Generic_Row := Disc_Gen.Discriminant_Generic_Row_Id (6);
      C.Discriminant_Generic_Status := Disc_Gen.Discriminant_Generic_Representation_Flow_Global_Error;
      C.Discriminant_Generic_Matches := 1;
      C.Source_Fingerprint := 1206;
      C.Scope_Fingerprint := 2206;
      C.Consumer_Fingerprint := 3206;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := AC.Accessibility_Consumer_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116207);
      C.Object_Name := To_Unbounded_String ("T");
      C.Instance_Name := To_Unbounded_String ("Vector_Instance");
      C.Scope_Row := Scope.Scope_Legality_Id (7);
      C.Scope_Status := Scope.Scope_Legality_Legal_Master_Hierarchy;
      C.Scope_Matches := 1;
      C.Discriminant_Generic_Row := Disc_Gen.Discriminant_Generic_Row_Id (7);
      C.Discriminant_Generic_Status := Disc_Gen.Discriminant_Generic_Legal_Record_Layout_Accepted;
      C.Discriminant_Generic_Matches := 1;
      C.Source_Fingerprint := 1207;
      C.Scope_Fingerprint := 2207;
      C.Consumer_Fingerprint := 3207;
      AC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := AC.Accessibility_Consumer_Access_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116208);
      C.Object_Name := To_Unbounded_String ("View");
      C.Scope_Row := Scope.No_Scope_Legality;
      C.Scope_Status := Scope.Scope_Legality_Not_Checked;
      C.Scope_Matches := 0;
      C.Source_Fingerprint := 1208;
      AC.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant AC.Accessibility_Consumer_Model := AC.Build (Sample_Context_Model);
   begin
      Assert (AC.Row_Count (Model) = 8, "expected eight accessibility consumer rows");
      Assert (AC.Legal_Count (Model) = 2, "assignment and record layout should be accepted");
      Assert (AC.Count_Status (Model, AC.Accessibility_Consumer_Return_Access_Master_Too_Short) = 1,
              "return access lifetime must block return consumers");
      Assert (AC.Count_Status (Model, AC.Accessibility_Consumer_Allocator_Master_Too_Short) = 1,
              "allocator master lifetime must block allocator consumers");
      Assert (AC.Count_Status (Model, AC.Accessibility_Consumer_Discriminant_Variant_Error) = 1,
              "access discriminants must preserve variant/discriminant blockers");
      Assert (AC.Count_Status (Model, AC.Accessibility_Consumer_Generic_Substitution_Master_Mismatch) = 1,
              "generic actual lifetime substitutions must block replay consumers");
      Assert (AC.Count_Status (Model, AC.Accessibility_Consumer_Representation_Flow_Error) = 1,
              "representation-flow blockers must stop accessibility consumers");
      Assert (AC.Count_Status (Model, AC.Accessibility_Consumer_Missing_Scope_Row) = 1,
              "missing scope graph evidence must not produce confident access conversion legality");
      Assert (AC.Scope_Error_Count (Model) = 4, "expected four scope-graph blockers");
      Assert (AC.Return_Error_Count (Model) = 1, "expected one return lifetime blocker");
      Assert (AC.Allocator_Error_Count (Model) = 1, "expected one allocator lifetime blocker");
      Assert (AC.Access_Discriminant_Error_Count (Model) = 1, "expected one access discriminant blocker");
      Assert (AC.Generic_Error_Count (Model) = 1, "expected one generic scope blocker");
      Assert (AC.Representation_Error_Count (Model) = 1, "expected one representation-flow blocker");
      Assert (AC.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant AC.Accessibility_Consumer_Model := AC.Build (Sample_Context_Model);
      Row   : constant AC.Accessibility_Consumer_Info :=
        AC.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116206));
      Set   : constant AC.Accessibility_Consumer_Set := AC.Rows_For_Instance (Model, "Vector_Instance");
   begin
      Assert (Row.Status = AC.Accessibility_Consumer_Representation_Flow_Error,
              "node lookup must preserve representation-flow accessibility blocker");
      Assert (AC.Set_Count (Set) = 3, "three sample rows belong to Vector_Instance");
      Assert (AC.Count_Kind (Model, AC.Accessibility_Consumer_Record_Layout) = 1,
              "kind lookup must preserve record-layout consumer row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "scope graph feeds accessibility consumers");
      Register_Routine (T, Test_Queries'Access, "accessibility consumer lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Accessibility_Scope_Consumer_Legality_Pass1162;
