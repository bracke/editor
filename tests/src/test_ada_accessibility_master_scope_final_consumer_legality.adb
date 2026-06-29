with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Accessibility_Scope_Consumer_Legality;
with Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Master_Scope_Final_Consumer_Legality is

   package Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   use type Final.Master_Scope_Final_Row_Id;
   use type Final.Master_Scope_Final_Context_Kind;
   use type Final.Master_Scope_Final_Status;
   use type Final.Master_Scope_Final_Context_Info;
   use type Final.Master_Scope_Final_Info;
   use type Final.Master_Scope_Final_Context_Model;
   use type Final.Master_Scope_Final_Set;
   use type Final.Master_Scope_Final_Model;
   package Scope renames Editor.Ada_Accessibility_Scope_Consumer_Legality;
   use type Scope.Accessibility_Consumer_Row_Id;
   use type Scope.Accessibility_Consumer_Context_Kind;
   use type Scope.Accessibility_Consumer_Status;
   use type Scope.Accessibility_Consumer_Context_Info;
   use type Scope.Accessibility_Consumer_Info;
   use type Scope.Accessibility_Consumer_Context_Model;
   use type Scope.Accessibility_Consumer_Set;
   use type Scope.Accessibility_Consumer_Model;
   package Flow renames Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
   use type Flow.Object_Flow_Row_Id;
   use type Flow.Object_Flow_Context_Kind;
   use type Flow.Object_Flow_Status;
   use type Flow.Object_Flow_Context_Info;
   use type Flow.Object_Flow_Info;
   use type Flow.Object_Flow_Context_Model;
   use type Flow.Object_Flow_Set;
   use type Flow.Object_Flow_Model;
   package Disc renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   use type Disc.Discriminant_Consumer_Row_Id;
   use type Disc.Discriminant_Consumer_Context_Kind;
   use type Disc.Discriminant_Consumer_Status;
   use type Disc.Discriminant_Consumer_Context_Info;
   use type Disc.Discriminant_Consumer_Info;
   use type Disc.Discriminant_Consumer_Context_Model;
   use type Disc.Discriminant_Consumer_Set;
   use type Disc.Discriminant_Consumer_Model;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Accessibility_Master_Scope_Final_Consumer_Legality");
   end Name;

   procedure Fill_Common (C : in out Final.Master_Scope_Final_Context_Info; Id : Natural) is
   begin
      C.Id := Final.Master_Scope_Final_Row_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118300 + Id);
      C.Object_Name := To_Unbounded_String ("Obj");
      C.Type_Name := To_Unbounded_String ("T");
      C.Generic_Unit_Name := To_Unbounded_String ("Gen");
      C.Instance_Name := To_Unbounded_String ("Inst");
      C.Scope_Consumer_Row := Scope.Accessibility_Consumer_Row_Id (Id);
      C.Scope_Consumer_Status := Scope.Accessibility_Consumer_Legal_Return_Access_Accepted;
      C.Scope_Consumer_Matches := 1;
      C.Object_Flow_Row := Flow.Object_Flow_Row_Id (Id);
      C.Object_Flow_Status := Flow.Object_Flow_Legal_Return_Access_Accepted;
      C.Object_Flow_Matches := 1;
      C.Discriminant_Row := Disc.Discriminant_Consumer_Row_Id (Id);
      C.Discriminant_Status := Disc.Discriminant_Consumer_Legal_Access_Discriminant_Accepted;
      C.Discriminant_Matches := 1;
      C.Generic_Backmap_Row := Backmap.Generic_Backmap_Row_Id (Id);
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Legal_Accessibility_Backmapped;
      C.Generic_Backmap_Matches := 1;
      C.Source_Fingerprint := 1183000 + Id;
      C.Scope_Fingerprint := 1184000 + Id;
      C.Object_Flow_Fingerprint := 1185000 + Id;
      C.Consumer_Fingerprint := 1186000 + Id;
   end Fill_Common;

   function Sample_Context_Model return Final.Master_Scope_Final_Context_Model is
      Contexts : Final.Master_Scope_Final_Context_Model;
      C        : Final.Master_Scope_Final_Context_Info;
   begin
      Fill_Common (C, 1);
      C.Kind := Final.Master_Scope_Final_Return_Access;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 2);
      C.Kind := Final.Master_Scope_Final_Anonymous_Access_Result;
      C.Scope_Consumer_Status := Scope.Accessibility_Consumer_Access_Parameter_Escapes;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 3);
      C.Kind := Final.Master_Scope_Final_Access_Discriminant;
      C.Requires_Discriminant := True;
      C.Discriminant_Status := Disc.Discriminant_Consumer_Access_Discriminant_Lifetime_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Kind := Final.Master_Scope_Final_Allocator_Master;
      C.Object_Flow_Status := Flow.Object_Flow_Allocator_Master_Too_Short;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Kind := Final.Master_Scope_Final_Generic_Replay_Escape;
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Missing_Formal_Actual_Map;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Kind := Final.Master_Scope_Final_Renaming;
      C.Scope_Consumer_Status := Scope.Accessibility_Consumer_Dangling_Renaming_Risk;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Kind := Final.Master_Scope_Final_Controlled_Finalization;
      C.Object_Flow_Status := Flow.Object_Flow_Finalization_Uses_Expired_Master;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Kind := Final.Master_Scope_Final_Access_Conversion;
      C.Scope_Consumer_Row := Scope.No_Accessibility_Consumer_Row;
      C.Scope_Consumer_Matches := 0;
      C.Scope_Consumer_Status := Scope.Accessibility_Consumer_Not_Checked;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 9);
      C.Kind := Final.Master_Scope_Final_Aggregate_Access_Component;
      C.Object_Flow_Status := Flow.Object_Flow_Indeterminate;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 10);
      C.Kind := Final.Master_Scope_Final_Private_Full_View;
      C.Scope_Consumer_Status := Scope.Accessibility_Consumer_Master_Too_Short;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 11);
      C.Kind := Final.Master_Scope_Final_Generic_Access_Actual;
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Matches := 2;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 12);
      C.Kind := Final.Master_Scope_Final_Access_Discriminant;
      C.Requires_Discriminant := True;
      C.Discriminant_Matches := 2;
      Final.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final.Master_Scope_Final_Model := Final.Build (Sample_Context_Model);
   begin
      Assert (Final.Row_Count (Model) = 12, "expected twelve final accessibility rows");
      Assert (Final.Legal_Count (Model) = 1, "only complete master/scope evidence should remain legal");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Access_Parameter_Escapes) = 1,
              "anonymous access escape must block confident legality");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Discriminant_Consumer_Blocker) = 1,
              "access discriminant evidence must be consumed");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Allocator_Master_Blocker) = 1,
              "allocator master failures must be preserved");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Generic_Backmap_Blocker) = 1,
              "generic source/instance backmap failures must be preserved");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Renaming_Dangling_Blocker) = 1,
              "renaming lifetime blockers must be preserved");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Finalization_Master_Blocker) = 1,
              "controlled finalization lifetime blockers must be preserved");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Missing_Scope_Consumer_Row) = 1,
              "missing scope consumer rows must block consumers");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Object_Flow_Indeterminate) = 1,
              "indeterminate object-flow evidence must remain indeterminate");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Private_Full_View_Lifetime_Blocker) = 1,
              "private/full-view lifetime blockers must be preserved");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Multiple_Generic_Backmap_Blockers) = 1,
              "multiple generic backmaps must block confident generic lifetime consumers");
      Assert (Final.Count_Status (Model, Final.Master_Scope_Final_Multiple_Discriminant_Consumer_Blockers) = 1,
              "multiple discriminant rows must block access-discriminant consumers");
      Assert (Final.Lifetime_Error_Count (Model) = 5, "expected five lifetime-family blockers");
      Assert (Final.Scope_Error_Count (Model) = 1, "expected one direct scope evidence blocker");
      Assert (Final.Object_Flow_Error_Count (Model) = 0, "specific object-flow blockers are remapped into lifetime families");
      Assert (Final.Discriminant_Error_Count (Model) = 2, "expected discriminant blocker and duplicate blocker");
      Assert (Final.Generic_Backmap_Error_Count (Model) = 2, "expected generic backmap blocker and duplicate blocker");
      Assert (Final.Indeterminate_Count (Model) = 1, "expected one indeterminate row");
      Assert (Final.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model  : constant Final.Master_Scope_Final_Model := Final.Build (Sample_Context_Model);
      Row    : constant Final.Master_Scope_Final_Info :=
        Final.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118305));
      By_Obj : constant Final.Master_Scope_Final_Set := Final.Rows_For_Object (Model, "Obj");
      By_Kind : constant Final.Master_Scope_Final_Set :=
        Final.Rows_For_Kind (Model, Final.Master_Scope_Final_Generic_Replay_Escape);
   begin
      Assert (Row.Status = Final.Master_Scope_Final_Generic_Backmap_Blocker,
              "node lookup must preserve generic backmap blocker");
      Assert (Final.Set_Count (By_Obj) = 12, "all sample rows use Obj");
      Assert (Final.Set_Count (By_Kind) = 1, "one generic replay escape row expected");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "accessibility master/scope final consumer blockers");
      Register_Routine (T, Test_Queries'Access, "accessibility master/scope final consumer lookups");
   end Register_Tests;

end Test_Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
