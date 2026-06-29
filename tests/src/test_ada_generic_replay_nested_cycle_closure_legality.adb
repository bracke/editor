with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Replay_Nested_Cycle_Closure_Legality is

   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;
   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   use type Cross_Final.Cross_Unit_Final_Row_Id;
   use type Cross_Final.Cross_Unit_Final_Context_Kind;
   use type Cross_Final.Cross_Unit_Dependency_State;
   use type Cross_Final.Cross_Unit_Final_Status;
   use type Cross_Final.Cross_Unit_Final_Context_Info;
   use type Cross_Final.Cross_Unit_Final_Info;
   use type Cross_Final.Cross_Unit_Final_Context_Model;
   use type Cross_Final.Cross_Unit_Final_Set;
   use type Cross_Final.Cross_Unit_Final_Model;
   package Final_RM renames Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
   use type Final_RM.Final_RM_Row_Id;
   use type Final_RM.Final_RM_Context_Kind;
   use type Final_RM.Final_RM_Status;
   use type Final_RM.Final_RM_Context_Info;
   use type Final_RM.Final_RM_Info;
   use type Final_RM.Final_RM_Context_Model;
   use type Final_RM.Final_RM_Model;
   use type Final_RM.Final_RM_Result_Set;
   package Nested renames Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
   use type Nested.Nested_Generic_Closure_Row_Id;
   use type Nested.Nested_Generic_Closure_Kind;
   use type Nested.Nested_Generic_Closure_Status;
   use type Nested.Nested_Generic_Closure_Context_Info;
   use type Nested.Nested_Generic_Closure_Info;
   use type Nested.Nested_Generic_Closure_Context_Model;
   use type Nested.Nested_Generic_Closure_Model;
   use type Nested.Nested_Generic_Closure_Result_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Generic_Replay_Nested_Cycle_Closure_Legality");
   end Name;

   function Complete_Context
     (Id   : Nested.Nested_Generic_Closure_Row_Id;
      Kind : Nested.Nested_Generic_Closure_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Nested.Nested_Generic_Closure_Context_Info is
      C : Nested.Nested_Generic_Closure_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Generic_Unit_Name := To_Unbounded_String ("Gen");
      C.Instance_Name := To_Unbounded_String ("Gen_Inst" & Natural'Image (Natural (Id)));
      C.Parent_Instance_Name := To_Unbounded_String ("Parent");
      C.Backmap_Row := Backmap.Generic_Backmap_Row_Id (Natural (Id));
      C.Backmap_Status := Backmap.Generic_Backmap_Legal_Nested_Instance_Backmapped;
      C.Final_RM_Row := Final_RM.Final_RM_Row_Id (Natural (Id));
      C.Final_RM_Status := Final_RM.Final_RM_Legal_Nested_Generic_Prefixed_Call_Accepted;
      C.Cross_Unit_Row := Cross_Final.Cross_Unit_Final_Row_Id (Natural (Id));
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Generic_Instance_Accepted;
      C.Requires_Final_RM := True;
      C.Requires_Cross_Unit := True;
      C.Dependency_Count := 2;
      C.Source_Fingerprint := Natural (Id) * 1190;
      C.Expected_Source_Fingerprint := Natural (Id) * 1190;
      C.Substitution_Fingerprint := Natural (Id) * 11900;
      C.Expected_Substitution_Fingerprint := Natural (Id) * 11900;
      return C;
   end Complete_Context;

   procedure Accepted_Nested_Generic_Replay_Requires_All_Final_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Nested.Nested_Generic_Closure_Context_Model;
      Local_Row : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (1,
           Nested.Nested_Generic_Local_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119001));
      Cross_Row : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (2,
           Nested.Nested_Generic_Cross_Unit_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119002));
      Replay_Row : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (3,
           Nested.Nested_Generic_Body_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119003));
   begin
      Local_Row.Requires_Cross_Unit := False;
      Local_Row.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Replay_Row.Backmap_Status := Backmap.Generic_Backmap_Legal_Statement_Backmapped;

      Nested.Add_Context (Contexts, Local_Row);
      Nested.Add_Context (Contexts, Cross_Row);
      Nested.Add_Context (Contexts, Replay_Row);

      declare
         Model : constant Nested.Nested_Generic_Closure_Model := Nested.Build (Contexts);
      begin
         Assert (Nested.Row_Count (Model) = 3, "three nested generic closure rows expected");
         Assert (Nested.Legal_Count (Model) = 3, "complete final evidence should keep nested replay legal");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119001)).Status =
            Nested.Nested_Generic_Legal_Local_Instance_Closed,
            "local instance should close without cross-unit evidence");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119002)).Status =
            Nested.Nested_Generic_Legal_Cross_Unit_Instance_Closed,
            "cross-unit instance should close with final closure evidence");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119003)).Status =
            Nested.Nested_Generic_Legal_Body_Replay_Closed,
            "body replay should close with backmapping/final evidence");
         Assert (Nested.Fingerprint (Model) /= 0, "model fingerprint must be deterministic");
      end;
   end Accepted_Nested_Generic_Replay_Requires_All_Final_Evidence;

   procedure Cycles_And_Recursive_Instantiations_Are_First_Class_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Nested.Nested_Generic_Closure_Context_Model;
      Nested_Cycle : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (1,
           Nested.Nested_Generic_Nested_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119021));
      Recursive_Cycle : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (2,
           Nested.Nested_Generic_Nested_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119022));
      Depth_Overflow : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (3,
           Nested.Nested_Generic_Nested_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119023));
   begin
      Nested_Cycle.Nested_Dependency_Cycle := True;
      Recursive_Cycle.Recursive_Instantiation_Cycle := True;
      Depth_Overflow.Cycle_Depth := 33;
      Depth_Overflow.Max_Cycle_Depth := 32;

      Nested.Add_Context (Contexts, Nested_Cycle);
      Nested.Add_Context (Contexts, Recursive_Cycle);
      Nested.Add_Context (Contexts, Depth_Overflow);

      declare
         Model : constant Nested.Nested_Generic_Closure_Model := Nested.Build (Contexts);
      begin
         Assert (Nested.Legal_Count (Model) = 0, "cycle rows must not remain legal");
         Assert (Nested.Cycle_Blocker_Count (Model) = 3, "cycle blockers should be counted explicitly");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119021)).Status =
            Nested.Nested_Generic_Nested_Dependency_Cycle,
            "nested dependency cycle should be preserved");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119022)).Status =
            Nested.Nested_Generic_Recursive_Instantiation_Cycle,
            "recursive instantiation cycle should be preserved");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119023)).Status =
            Nested.Nested_Generic_Cycle_Depth_Overflow,
            "cycle depth overflow should be preserved");
      end;
   end Cycles_And_Recursive_Instantiations_Are_First_Class_Blockers;

   procedure Missing_Backmap_Final_RM_And_Cross_Unit_Evidence_Block_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Nested.Nested_Generic_Closure_Context_Model;
      Missing_Backmap : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (1,
           Nested.Nested_Generic_Nested_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119041));
      Missing_Final_RM : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (2,
           Nested.Nested_Generic_Subprogram_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (119042));
      Missing_Cross : Nested.Nested_Generic_Closure_Context_Info :=
        Complete_Context
          (3,
           Nested.Nested_Generic_Cross_Unit_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (119043));
   begin
      Missing_Backmap.Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      Missing_Final_RM.Final_RM_Status := Final_RM.Final_RM_Not_Checked;
      Missing_Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Not_Checked;

      Nested.Add_Context (Contexts, Missing_Backmap);
      Nested.Add_Context (Contexts, Missing_Final_RM);
      Nested.Add_Context (Contexts, Missing_Cross);

      declare
         Model : constant Nested.Nested_Generic_Closure_Model := Nested.Build (Contexts);
      begin
         Assert (Nested.Legal_Count (Model) = 0, "missing evidence should block nested closure");
         Assert (Nested.Backmap_Blocker_Count (Model) = 1, "backmap blocker should be counted");
         Assert (Nested.Final_RM_Blocker_Count (Model) = 1, "final RM blocker should be counted");
         Assert (Nested.Cross_Unit_Blocker_Count (Model) = 1, "cross-unit blocker should be counted");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119041)).Status =
            Nested.Nested_Generic_Missing_Generic_Backmap,
            "backmapping evidence should be required");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119042)).Status =
            Nested.Nested_Generic_Missing_Final_RM_Consumer,
            "final overload/type consumer evidence should be required");
         Assert
           (Nested.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119043)).Status =
            Nested.Nested_Generic_Missing_Cross_Unit_Final_Closure,
            "cross-unit final closure evidence should be required");
      end;
   end Missing_Backmap_Final_RM_And_Cross_Unit_Evidence_Block_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Nested_Generic_Replay_Requires_All_Final_Evidence'Access,
         "accepted nested generic replay requires all final evidence");
      Register_Routine
        (T,
         Cycles_And_Recursive_Instantiations_Are_First_Class_Blockers'Access,
         "cycles and recursive instantiations are first-class blockers");
      Register_Routine
        (T,
         Missing_Backmap_Final_RM_And_Cross_Unit_Evidence_Block_Closure'Access,
         "missing backmap/final RM/cross-unit evidence blocks nested closure");
   end Register_Tests;

end Test_Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
