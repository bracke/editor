with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
with Editor.Ada_Accessibility_Scope_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Object_Flow_Accessibility_Consumer_Legality_Pass1163 is

   package Obj_Flow renames Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
   use type Obj_Flow.Object_Flow_Row_Id;
   use type Obj_Flow.Object_Flow_Context_Kind;
   use type Obj_Flow.Object_Flow_Status;
   use type Obj_Flow.Object_Flow_Context_Info;
   use type Obj_Flow.Object_Flow_Info;
   use type Obj_Flow.Object_Flow_Context_Model;
   use type Obj_Flow.Object_Flow_Set;
   use type Obj_Flow.Object_Flow_Model;
   package AC renames Editor.Ada_Accessibility_Scope_Consumer_Legality;
   use type AC.Accessibility_Consumer_Row_Id;
   use type AC.Accessibility_Consumer_Context_Kind;
   use type AC.Accessibility_Consumer_Status;
   use type AC.Accessibility_Consumer_Context_Info;
   use type AC.Accessibility_Consumer_Info;
   use type AC.Accessibility_Consumer_Context_Model;
   use type AC.Accessibility_Consumer_Set;
   use type AC.Accessibility_Consumer_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Object_Flow_Accessibility_Consumer_Legality_Pass1163");
   end Name;

   function Sample_Context_Model return Obj_Flow.Object_Flow_Context_Model is
      Contexts : Obj_Flow.Object_Flow_Context_Model;
      C        : Obj_Flow.Object_Flow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Obj_Flow.Object_Flow_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116301);
      C.Object_Name := To_Unbounded_String ("Target");
      C.Target_Type := To_Unbounded_String ("T");
      C.Source_Type := To_Unbounded_String ("T");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (1);
      C.Accessibility_Status := AC.Accessibility_Consumer_Legal_Assignment_Accepted;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Assignment;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1301;
      C.Accessibility_Fingerprint := 2301;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Obj_Flow.Object_Flow_Return_Access;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116302);
      C.Object_Name := To_Unbounded_String ("Result_Access");
      C.Target_Type := To_Unbounded_String ("access T");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (2);
      C.Accessibility_Status := AC.Accessibility_Consumer_Return_Access_Master_Too_Short;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Return_Access;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1302;
      C.Accessibility_Fingerprint := 2302;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Obj_Flow.Object_Flow_Allocator;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116303);
      C.Object_Name := To_Unbounded_String ("New_Node");
      C.Target_Type := To_Unbounded_String ("Node_Access");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (3);
      C.Accessibility_Status := AC.Accessibility_Consumer_Allocator_Master_Too_Short;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Allocator;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1303;
      C.Accessibility_Fingerprint := 2303;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Obj_Flow.Object_Flow_Access_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116304);
      C.Object_Name := To_Unbounded_String ("View");
      C.Target_Type := To_Unbounded_String ("access Root'Class");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (4);
      C.Accessibility_Status := AC.Accessibility_Consumer_Access_Conversion_Level_Too_Deep;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Access_Conversion;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1304;
      C.Accessibility_Fingerprint := 2304;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Obj_Flow.Object_Flow_Generic_Replay;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116305);
      C.Object_Name := To_Unbounded_String ("Formal_Access");
      C.Generic_Unit_Name := To_Unbounded_String ("Generic_Vector");
      C.Instance_Name := To_Unbounded_String ("Vector_Instance");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (5);
      C.Accessibility_Status := AC.Accessibility_Consumer_Generic_Substitution_Master_Mismatch;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Generic_Replay;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1305;
      C.Accessibility_Fingerprint := 2305;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Obj_Flow.Object_Flow_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116306);
      C.Object_Name := To_Unbounded_String ("Variant_Aggregate");
      C.Target_Type := To_Unbounded_String ("Discriminated_Record");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (6);
      C.Accessibility_Status := AC.Accessibility_Consumer_Discriminant_Variant_Error;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Record_Aggregate;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1306;
      C.Accessibility_Fingerprint := 2306;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Obj_Flow.Object_Flow_Return_Object;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116307);
      C.Object_Name := To_Unbounded_String ("Result");
      C.Target_Type := To_Unbounded_String ("Limited_Controlled");
      C.Accessibility_Row := AC.No_Accessibility_Consumer_Row;
      C.Accessibility_Status := AC.Accessibility_Consumer_Not_Checked;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Return_Object;
      C.Accessibility_Matches := 0;
      C.Source_Fingerprint := 1307;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Obj_Flow.Object_Flow_Conversion;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116308);
      C.Object_Name := To_Unbounded_String ("Cast");
      C.Target_Type := To_Unbounded_String ("Target_Access");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (8);
      C.Accessibility_Status := AC.Accessibility_Consumer_Legal_Conversion_Accepted;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Access_Conversion;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1308;
      C.Accessibility_Fingerprint := 2308;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := Obj_Flow.Object_Flow_Finalization;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116309);
      C.Object_Name := To_Unbounded_String ("Controlled_Object");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (9);
      C.Accessibility_Status := AC.Accessibility_Consumer_Finalization_Uses_Expired_Master;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Finalization;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1309;
      C.Accessibility_Fingerprint := 2309;
      Obj_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := Obj_Flow.Object_Flow_Renaming;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116310);
      C.Object_Name := To_Unbounded_String ("Alias");
      C.Accessibility_Row := AC.Accessibility_Consumer_Row_Id (10);
      C.Accessibility_Status := AC.Accessibility_Consumer_Dangling_Renaming_Risk;
      C.Accessibility_Kind := AC.Accessibility_Consumer_Renaming;
      C.Accessibility_Matches := 1;
      C.Source_Fingerprint := 1310;
      C.Accessibility_Fingerprint := 2310;
      Obj_Flow.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Obj_Flow.Object_Flow_Model := Obj_Flow.Build (Sample_Context_Model);
   begin
      Assert (Obj_Flow.Row_Count (Model) = 10, "expected ten object-flow rows");
      Assert (Obj_Flow.Legal_Count (Model) = 1, "only the assignment row should remain confident");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Return_Access_Master_Too_Short) = 1,
              "return access lifetime must block object-flow return legality");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Allocator_Master_Too_Short) = 1,
              "allocator lifetime must block allocator object-flow legality");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Access_Conversion_Level_Too_Deep) = 1,
              "access conversion level must block conversion object-flow legality");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Generic_Substitution_Master_Mismatch) = 1,
              "generic substitution lifetime must block replay object-flow legality");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Discriminant_Variant_Blocker) = 1,
              "discriminant variant blockers must stop aggregate object-flow legality");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Missing_Accessibility_Consumer_Row) = 1,
              "missing accessibility evidence must not remain confident");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Mismatched_Accessibility_Consumer_Kind) = 1,
              "mismatched consumer kind must be explicit");
      Assert (Obj_Flow.Count_Status (Model, Obj_Flow.Object_Flow_Finalization_Uses_Expired_Master) = 1,
              "expired finalization master must block finalization flow");
      Assert (Obj_Flow.Return_Error_Count (Model) = 1, "expected one return lifetime blocker");
      Assert (Obj_Flow.Allocator_Error_Count (Model) = 1, "expected one allocator blocker");
      Assert (Obj_Flow.Access_Error_Count (Model) = 1, "expected one access conversion blocker");
      Assert (Obj_Flow.Generic_Error_Count (Model) = 1, "expected one generic replay blocker");
      Assert (Obj_Flow.Representation_Error_Count (Model) = 1, "expected one discriminant/representation blocker");
      Assert (Obj_Flow.Error_Count (Model) = 9, "nine object-flow rows should be blocked");
      Assert (Obj_Flow.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Obj_Flow.Object_Flow_Model := Obj_Flow.Build (Sample_Context_Model);
      Row   : constant Obj_Flow.Object_Flow_Info :=
        Obj_Flow.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116305));
      Set   : constant Obj_Flow.Object_Flow_Set := Obj_Flow.Rows_For_Instance (Model, "Vector_Instance");
   begin
      Assert (Row.Status = Obj_Flow.Object_Flow_Generic_Substitution_Master_Mismatch,
              "node lookup must preserve generic replay accessibility blocker");
      Assert (Obj_Flow.Set_Count (Set) = 1, "one sample row belongs to Vector_Instance");
      Assert (Obj_Flow.Count_Kind (Model, Obj_Flow.Object_Flow_Renaming) = 1,
              "kind lookup must preserve renaming object-flow row");
      Assert (Obj_Flow.Set_Count (Obj_Flow.Rows_For_Object (Model, "Alias")) = 1,
              "object-name lookup must preserve dangling renaming row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "accessibility scope feeds object-flow consumers");
      Register_Routine (T, Test_Queries'Access, "object-flow accessibility lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Object_Flow_Accessibility_Consumer_Legality_Pass1163;
