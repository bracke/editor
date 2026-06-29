with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Definite_Initialization_Object_Flow_Consumer_Legality is

   package DIF renames Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
   use type DIF.Initialization_Object_Flow_Row_Id;
   use type DIF.Initialization_Object_Flow_Status;
   use type DIF.Initialization_Object_Flow_Context_Info;
   use type DIF.Initialization_Object_Flow_Info;
   use type DIF.Initialization_Object_Flow_Context_Model;
   use type DIF.Initialization_Object_Flow_Set;
   use type DIF.Initialization_Object_Flow_Model;
   package Init renames Editor.Ada_Definite_Initialization_Flow_Legality;
   use type Init.Assignment_Legality_Id;
   use type Init.Assignment_Legality_Status;
   use type Init.Return_Legality_Id;
   use type Init.Return_Legality_Status;
   use type Init.Control_Flow_Legality_Id;
   use type Init.Control_Flow_Legality_Status;
   use type Init.Exception_Finalization_Legality_Id;
   use type Init.Exception_Finalization_Legality_Status;
   use type Init.Integrated_Closure_Id;
   use type Init.Integrated_Closure_Status;
   use type Init.Initialization_Context_Id;
   use type Init.Initialization_Legality_Id;
   use type Init.Initialization_Context_Kind;
   use type Init.Object_State;
   use type Init.Flow_State;
   use type Init.Initialization_Legality_Status;
   use type Init.Initialization_Context_Info;
   use type Init.Initialization_Legality_Info;
   use type Init.Initialization_Context_Model;
   use type Init.Initialization_Legality_Model;
   package Obj_Flow renames Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
   use type Obj_Flow.Object_Flow_Row_Id;
   use type Obj_Flow.Object_Flow_Context_Kind;
   use type Obj_Flow.Object_Flow_Status;
   use type Obj_Flow.Object_Flow_Context_Info;
   use type Obj_Flow.Object_Flow_Info;
   use type Obj_Flow.Object_Flow_Context_Model;
   use type Obj_Flow.Object_Flow_Set;
   use type Obj_Flow.Object_Flow_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Definite_Initialization_Object_Flow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return DIF.Initialization_Object_Flow_Context_Model is
      Contexts : DIF.Initialization_Object_Flow_Context_Model;
      C        : DIF.Initialization_Object_Flow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Init.Initialization_Context_Object_Declaration;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116401);
      C.Object_Name := To_Unbounded_String ("Clean_Object");
      C.Initialization_Row := Init.Initialization_Legality_Id (1);
      C.Initialization_Status := Init.Initialization_Legality_Explicitly_Initialized;
      C.Before_State := Init.Object_State_Uninitialized;
      C.After_State := Init.Object_State_Definitely_Initialized;
      C.Object_Flow_Row := Obj_Flow.Object_Flow_Row_Id (1);
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Legal_Initialization_Accepted;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Object_Initialization;
      C.Object_Flow_Matches := 1;
      C.Source_Fingerprint := 1401;
      C.Initialization_Fingerprint := 2401;
      C.Object_Flow_Fingerprint := 3401;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Init.Initialization_Context_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116402);
      C.Object_Name := To_Unbounded_String ("Result_Access");
      C.Initialization_Status := Init.Initialization_Legality_Return_Object_Initialized;
      C.Object_Flow_Row := Obj_Flow.Object_Flow_Row_Id (2);
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Return_Access_Master_Too_Short;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Return_Object;
      C.Object_Flow_Matches := 1;
      C.Source_Fingerprint := 1402;
      C.Initialization_Fingerprint := 2402;
      C.Object_Flow_Fingerprint := 3402;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Init.Initialization_Context_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116403);
      C.Object_Name := To_Unbounded_String ("Variant_Aggregate");
      C.Initialization_Status := Init.Initialization_Legality_Component_Initialized;
      C.Object_Flow_Row := Obj_Flow.Object_Flow_Row_Id (3);
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Discriminant_Variant_Blocker;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Record_Aggregate;
      C.Object_Flow_Matches := 1;
      C.Source_Fingerprint := 1403;
      C.Initialization_Fingerprint := 2403;
      C.Object_Flow_Fingerprint := 3403;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Init.Initialization_Context_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116404);
      C.Object_Name := To_Unbounded_String ("Before_Write");
      C.Initialization_Status := Init.Initialization_Legality_Read_Before_Write;
      C.Object_Flow_Row := Obj_Flow.No_Object_Flow_Row;
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Not_Checked;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Unknown;
      C.Source_Fingerprint := 1404;
      C.Initialization_Fingerprint := 2404;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Init.Initialization_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116405);
      C.Object_Name := To_Unbounded_String ("Missing_Evidence");
      C.Initialization_Status := Init.Initialization_Legality_Definitely_Initialized;
      C.Object_Flow_Row := Obj_Flow.No_Object_Flow_Row;
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Not_Checked;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Assignment;
      C.Object_Flow_Matches := 0;
      C.Source_Fingerprint := 1405;
      C.Initialization_Fingerprint := 2405;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Init.Initialization_Context_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116406);
      C.Object_Name := To_Unbounded_String ("Wrong_Evidence");
      C.Initialization_Status := Init.Initialization_Legality_Definitely_Initialized;
      C.Object_Flow_Row := Obj_Flow.Object_Flow_Row_Id (6);
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Legal_Assignment_Accepted;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Return_Object;
      C.Object_Flow_Matches := 1;
      C.Source_Fingerprint := 1406;
      C.Initialization_Fingerprint := 2406;
      C.Object_Flow_Fingerprint := 3406;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Init.Initialization_Context_Finalization_Path;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116407);
      C.Object_Name := To_Unbounded_String ("Controlled_Object");
      C.Initialization_Status := Init.Initialization_Legality_Finalization_Path_Preserved;
      C.Object_Flow_Row := Obj_Flow.Object_Flow_Row_Id (7);
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Finalization_Uses_Expired_Master;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Finalization;
      C.Object_Flow_Matches := 1;
      C.Source_Fingerprint := 1407;
      C.Initialization_Fingerprint := 2407;
      C.Object_Flow_Fingerprint := 3407;
      DIF.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Init.Initialization_Context_Extended_Return;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116408);
      C.Object_Name := To_Unbounded_String ("Indeterminate_Result");
      C.Initialization_Status := Init.Initialization_Legality_Indeterminate;
      C.Object_Flow_Row := Obj_Flow.Object_Flow_Row_Id (8);
      C.Object_Flow_Status := Obj_Flow.Object_Flow_Indeterminate;
      C.Object_Flow_Kind := Obj_Flow.Object_Flow_Return_Object;
      C.Object_Flow_Matches := 1;
      C.Source_Fingerprint := 1408;
      C.Initialization_Fingerprint := 2408;
      C.Object_Flow_Fingerprint := 3408;
      DIF.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant DIF.Initialization_Object_Flow_Model := DIF.Build (Sample_Context_Model);
   begin
      Assert (DIF.Row_Count (Model) = 8, "expected eight initialization object-flow rows");
      Assert (DIF.Legal_Count (Model) = 1, "only clean initialization should remain confident");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Object_Flow_Return_Lifetime_Blocker) = 1,
              "return lifetime blockers must stop confident initialization flow");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Object_Flow_Discriminant_Variant_Blocker) = 1,
              "discriminant blockers must stop aggregate initialization flow");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Object_Flow_Preserved_Read_Before_Write) = 1,
              "original read-before-write errors must be preserved");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Object_Flow_Missing_Object_Flow_Row) = 1,
              "missing object-flow evidence must be explicit");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Object_Flow_Mismatched_Object_Flow_Kind) = 1,
              "mismatched object-flow kind must be explicit");
      Assert (DIF.Count_Status (Model, DIF.Initialization_Object_Flow_Indeterminate) = 1,
              "indeterminate input must remain indeterminate");
      Assert (DIF.Lifetime_Error_Count (Model) = 2, "return and finalization lifetime blockers expected");
      Assert (DIF.Initialization_Error_Count (Model) = 1, "one preserved initialization error expected");
      Assert (DIF.Representation_Error_Count (Model) = 1, "one discriminant/representation blocker expected");
      Assert (DIF.Error_Count (Model) = 6, "six rows should be hard blocked");
      Assert (DIF.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant DIF.Initialization_Object_Flow_Model := DIF.Build (Sample_Context_Model);
      Row   : constant DIF.Initialization_Object_Flow_Info :=
        DIF.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116404));
      Set   : constant DIF.Initialization_Object_Flow_Set := DIF.Rows_For_Object (Model, "Before_Write");
   begin
      Assert (Row.Status = DIF.Initialization_Object_Flow_Preserved_Read_Before_Write,
              "node lookup must preserve read-before-write blocker");
      Assert (DIF.Set_Count (Set) = 1, "object lookup must preserve initialization row");
      Assert (DIF.Count_Kind (Model, Init.Initialization_Context_Assignment) = 2,
              "kind lookup must preserve both assignment rows");
      Assert (DIF.Set_Count (DIF.Rows_For_Status (Model, DIF.Initialization_Object_Flow_Missing_Object_Flow_Row)) = 1,
              "status lookup must preserve missing object-flow evidence");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "object-flow evidence gates definite initialization");
      Register_Routine (T, Test_Queries'Access, "initialization object-flow lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
