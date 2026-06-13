with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality_Pass1295 is

   package Repair renames Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality;
   use type Repair.Search_Entry;
   use type Repair.Search_Status;
   use type Repair.Search_Blocker;
   use type Repair.Remaining_RM_Edge_Kind;
   use type Repair.Remaining_RM_Edge_Blocker_Family;
   use type Repair.Remaining_RM_Edge_AST_Repair_Id;
   use type Repair.Remaining_RM_Edge_AST_Repair_Kind;
   use type Repair.Remaining_RM_Edge_AST_Repair_Blocker_Family;
   use type Repair.Remaining_RM_Edge_AST_Repair_Status;
   use type Repair.Remaining_RM_Edge_AST_Repair_Context;
   use type Repair.Remaining_RM_Edge_AST_Repair_Row;
   use type Repair.Remaining_RM_Edge_AST_Repair_Context_Model;
   use type Repair.Remaining_RM_Edge_AST_Repair_Model;
   use type Repair.Remaining_RM_Edge_AST_Repair_Set;
   package Search renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Provenance_Id;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Provenance_Status;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Family;
   use type Search.Remaining_RM_Edge_Kind;
   use type Search.Remaining_RM_Edge_Blocker_Family;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Search_Result;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
   use type Search.Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada remaining RM edge coverage-proven AST repair legality pass1295");
   end Name;

   function Blocking_Search_Entry
     (Id      : Natural;
      Kind    : Search.Remaining_RM_Edge_Kind;
      Blocker : Search.Remaining_RM_Edge_Blocker_Family;
      Node    : Editor.Ada_Syntax_Tree.Node_Id) return Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry is
      Feed_Item : Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
   begin
      Feed_Item.Id := Search.Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id (Id);
      Feed_Item.Status := Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Error;
      Feed_Item.Blocker := Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge;
      Feed_Item.Remaining_Edge_Kind := Kind;
      Feed_Item.Remaining_Edge_Blocker := Blocker;
      Feed_Item.Node := Node;
      Feed_Item.Source_Fingerprint := 1295 * Id;
      Feed_Item.Substitution_Fingerprint := 12_950 * Id;
      Feed_Item.Fingerprint := 129_500 + Id;
      Feed_Item.Emitted := True;
      Feed_Item.Blocks_Downstream := True;
      Feed_Item.Full_Chain_Linked := True;
      Feed_Item.Start_Line := 10 + Id;
      Feed_Item.Start_Column := 2;
      Feed_Item.End_Line := 10 + Id;
      Feed_Item.End_Column := 30;
      return Feed_Item;
   end Blocking_Search_Entry;

   function Non_Blocking_Search_Entry
     (Id   : Natural;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry is
      Feed_Item : Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
   begin
      Feed_Item.Id := Search.Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id (Id);
      Feed_Item.Status := Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Withheld_Current_Evidence;
      Feed_Item.Blocker := Search.Prov.Remaining_RM_Edge_Stabilized_Closure_Blocker_None;
      Feed_Item.Remaining_Edge_Kind := Search.Prov.Edge.Remaining_RM_Edge_Dispatching_Abstract_State_Effect;
      Feed_Item.Remaining_Edge_Blocker := Search.Prov.Edge.Remaining_RM_Edge_Blocker_None;
      Feed_Item.Node := Node;
      Feed_Item.Source_Fingerprint := 1295 * Id;
      Feed_Item.Substitution_Fingerprint := 12_950 * Id;
      Feed_Item.Fingerprint := 129_600 + Id;
      Feed_Item.Withheld_Current := True;
      return Feed_Item;
   end Non_Blocking_Search_Entry;

   function Context_For
     (Id       : Natural;
      Kind     : Repair.Remaining_RM_Edge_AST_Repair_Kind;
      Evidence : Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry) return Repair.Remaining_RM_Edge_AST_Repair_Context is
      Result : Repair.Remaining_RM_Edge_AST_Repair_Context;
   begin
      Result.Id := Repair.Remaining_RM_Edge_AST_Repair_Id (Id);
      Result.Kind := Kind;
      Result.Node := Evidence.Node;
      Result.Construct_Name := To_Unbounded_String ("remaining-rm-edge-ast-repair" & Natural'Image (Id));
      Result.Has_Stabilized_Search_Evidence := True;
      Result.Stabilized_Search_Entry := Evidence;
      Result.Coverage_Proves_Repair_Need := True;
      Result.Source_Fingerprint := Evidence.Source_Fingerprint;
      Result.Expected_Source_Fingerprint := Evidence.Source_Fingerprint;
      Result.Substitution_Fingerprint := Evidence.Substitution_Fingerprint;
      Result.Expected_Substitution_Fingerprint := Evidence.Substitution_Fingerprint;
      Result.Start_Line := Evidence.Start_Line;
      Result.Start_Column := Evidence.Start_Column;
      Result.End_Line := Evidence.End_Line;
      Result.End_Column := Evidence.End_Column;
      return Result;
   end Context_For;

   function Build_Model return Repair.Remaining_RM_Edge_AST_Repair_Model is
      Contexts : Repair.Remaining_RM_Edge_AST_Repair_Context_Model;
      Parser_Evidence : constant Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry :=
        Blocking_Search_Entry
          (1,
           Search.Prov.Edge.Remaining_RM_Edge_Dispatching_Abstract_State_Effect,
           Search.Prov.Edge.Remaining_RM_Edge_Blocker_Dispatching_Abstract_State,
           Editor.Ada_Syntax_Tree.Node_Id (129501));
      Token_Evidence : constant Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry :=
        Blocking_Search_Entry
          (2,
           Search.Prov.Edge.Remaining_RM_Edge_Protected_Action_Reentrancy,
           Search.Prov.Edge.Remaining_RM_Edge_Blocker_Protected_Reentrancy,
           Editor.Ada_Syntax_Tree.Node_Id (129502));
      Non_Blocking : constant Search.Remaining_RM_Edge_Stabilized_Closure_Search_Entry :=
        Non_Blocking_Search_Entry (3, Editor.Ada_Syntax_Tree.Node_Id (129503));
      Parser_Context : Repair.Remaining_RM_Edge_AST_Repair_Context :=
        Context_For (1, Repair.Remaining_RM_Edge_AST_Repair_Parser_Node, Parser_Evidence);
      Token_Context : Repair.Remaining_RM_Edge_AST_Repair_Context :=
        Context_For (2, Repair.Remaining_RM_Edge_AST_Repair_Token_Only_Parse, Token_Evidence);
      Accepted_Context : Repair.Remaining_RM_Edge_AST_Repair_Context :=
        Context_For (3, Repair.Remaining_RM_Edge_AST_Repair_Metadata, Parser_Evidence);
      Missing_Evidence : Repair.Remaining_RM_Edge_AST_Repair_Context;
      Non_Blocking_Context : Repair.Remaining_RM_Edge_AST_Repair_Context :=
        Context_For (5, Repair.Remaining_RM_Edge_AST_Repair_Source_Span, Non_Blocking);
   begin
      Parser_Context.Parser_Node_Still_Missing := True;
      Token_Context.Token_Only_Parse_Still_Present := True;
      Missing_Evidence.Id := Repair.Remaining_RM_Edge_AST_Repair_Id (4);
      Missing_Evidence.Kind := Repair.Remaining_RM_Edge_AST_Repair_Structural_AST;
      Missing_Evidence.Coverage_Proves_Repair_Need := True;
      Missing_Evidence.Structural_AST_Still_Missing := True;
      Non_Blocking_Context.Coverage_Proves_Repair_Need := False;
      Repair.Add_Context (Contexts, Parser_Context);
      Repair.Add_Context (Contexts, Token_Context);
      Repair.Add_Context (Contexts, Accepted_Context);
      Repair.Add_Context (Contexts, Missing_Evidence);
      Repair.Add_Context (Contexts, Non_Blocking_Context);
      return Repair.Build (Contexts);
   end Build_Model;

   procedure Classifies_Only_Coverage_Proven_AST_Gaps
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Repair.Remaining_RM_Edge_AST_Repair_Model := Build_Model;
   begin
      Assert (Repair.Count (Model) = 5,
              "repair model should preserve all candidate contexts");
      Assert (Repair.Count_By_Status (Model, Repair.Remaining_RM_Edge_AST_Repair_Parser_Node_Still_Missing) = 1,
              "parser-node blocker should remain explicit until repaired AST evidence exists");
      Assert (Repair.Count_By_Status (Model, Repair.Remaining_RM_Edge_AST_Repair_Token_Only_Parse_Still_Present) = 1,
              "token-only blocker should remain explicit until repaired AST evidence exists");
      Assert (Repair.Count_By_Status (Model, Repair.Remaining_RM_Edge_AST_Repair_Metadata_Repaired) = 1,
              "coverage-proven remaining-edge metadata repair should be accepted when no local gap remains");
      Assert (Repair.Count_By_Status (Model, Repair.Remaining_RM_Edge_AST_Repair_Missing_Stabilized_Search_Evidence) = 1,
              "repair must not be accepted without stabilized search evidence");
      Assert (Repair.Count_By_Status (Model, Repair.Remaining_RM_Edge_AST_Repair_Search_Evidence_Not_Blocking) = 1,
              "repair must not be accepted when search evidence is current non-blocking evidence");
      Assert (Repair.Coverage_Proven_Count (Model) = 4,
              "coverage-proof accounting should include only contexts with concrete local coverage evidence");
      Assert (Repair.Withheld_Count (Model) = 4,
              "blocked rows should stay withheld from downstream trust");
      Assert (Repair.Repaired_Count (Model) = 1,
              "only one repair row should be accepted");
      Assert (Repair.Stable_Fingerprint (Model) /= 0,
              "repair model should have deterministic fingerprint");
   end Classifies_Only_Coverage_Proven_AST_Gaps;

   procedure Queries_By_Blocker_And_Remaining_Edge
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Repair.Remaining_RM_Edge_AST_Repair_Model := Build_Model;
      Token_Set : constant Repair.Remaining_RM_Edge_AST_Repair_Set :=
        Repair.Query_Blocker_Family (Model, Repair.Remaining_RM_Edge_AST_Repair_Blocker_Token_Only_Parse);
      Dispatch_Set : constant Repair.Remaining_RM_Edge_AST_Repair_Set :=
        Repair.Query_Remaining_Edge_Kind (Model, Search.Prov.Edge.Remaining_RM_Edge_Dispatching_Abstract_State_Effect);
      Node_Set : constant Repair.Remaining_RM_Edge_AST_Repair_Set :=
        Repair.Query_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (129501));
   begin
      Assert (Repair.Query_Count (Token_Set) = 1,
              "token-only blocker should be queryable by blocker family");
      Assert (Repair.Query_Count (Dispatch_Set) = 3,
              "dispatching abstract-state edge repair rows should be queryable by RM edge kind");
      Assert (Repair.Query_Count (Node_Set) = 2,
              "rows should be queryable by concrete syntax node");
   end Queries_By_Blocker_And_Remaining_Edge;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Classifies_Only_Coverage_Proven_AST_Gaps'Access,
                        "classifies only coverage-proven AST repair blockers");
      Register_Routine (T, Queries_By_Blocker_And_Remaining_Edge'Access,
                        "indexes repair rows by blocker, edge kind, and node");
   end Register_Tests;

end Test_Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality_Pass1295;
