with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit; use AUnit;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Access_Definition_AST_Repair_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Overload_Type_Final_RM_Consumer_Legality is

   package Access_AST renames Editor.Ada_Access_Definition_AST_Repair_Legality;
   use type Access_AST.Access_Definition_AST_Repair_Row_Id;
   use type Access_AST.Access_Definition_AST_Construct_Kind;
   use type Access_AST.Access_Definition_AST_Repair_Status;
   use type Access_AST.Access_Definition_AST_Repair_Context_Info;
   use type Access_AST.Access_Definition_AST_Repair_Info;
   use type Access_AST.Access_Definition_AST_Repair_Context_Model;
   use type Access_AST.Access_Definition_AST_Repair_Model;
   use type Access_AST.Access_Definition_AST_Repair_Result_Set;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;
   package Edge renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   use type Edge.Overload_Type_Edge_Row_Id;
   use type Edge.Overload_Type_Edge_Context_Kind;
   use type Edge.Overload_Type_Edge_Status;
   use type Edge.Overload_Type_Edge_Context_Info;
   use type Edge.Overload_Type_Edge_Info;
   use type Edge.Overload_Type_Edge_Context_Model;
   use type Edge.Overload_Type_Edge_Result_Set;
   use type Edge.Overload_Type_Edge_Model;
   package Final_RM renames Editor.Ada_Overload_Type_Final_RM_Consumer_Legality;
   use type Final_RM.Final_RM_Row_Id;
   use type Final_RM.Final_RM_Context_Kind;
   use type Final_RM.Final_RM_Status;
   use type Final_RM.Final_RM_Context_Info;
   use type Final_RM.Final_RM_Info;
   use type Final_RM.Final_RM_Context_Model;
   use type Final_RM.Final_RM_Model;
   use type Final_RM.Final_RM_Result_Set;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Overload_Type_Final_RM_Consumer_Legality");
   end Name;

   function Complete_Context
     (Id   : Final_RM.Final_RM_Row_Id;
      Kind : Final_RM.Final_RM_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Final_RM.Final_RM_Context_Info is
      C : Final_RM.Final_RM_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Designator := To_Unbounded_String ("Call_Op");
      C.Prefix_Type_Name := To_Unbounded_String ("Prefix_Type");
      C.Expected_Type_Name := To_Unbounded_String ("Expected_Type");
      C.Selected_Profile := To_Unbounded_String ("procedure Call_Op (X : Prefix_Type)");
      C.Edge_Row := Edge.Overload_Type_Edge_Row_Id (Natural (Id));
      C.Edge_Status := Edge.Overload_Type_Edge_Legal_Dispatching_Selected;
      C.Access_AST_Row := Access_AST.Access_Definition_AST_Repair_Row_Id (Natural (Id));
      C.Access_AST_Status := Access_AST.Access_Definition_AST_Legal_Subprogram_Access_Repaired;
      C.Generic_Backmap_Row := Backmap.Generic_Backmap_Row_Id (Natural (Id));
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Legal_Call_Backmapped;
      C.Candidate_Count := 1;
      C.Selected_Candidate_Count := 1;
      C.Source_Fingerprint := Natural (Id) * 1189;
      return C;
   end Complete_Context;

   procedure Accepted_Final_RM_Edges_Require_All_Consumer_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Final_RM.Final_RM_Context_Model;
      Prefixed : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (1,
           Final_RM.Final_RM_Prefixed_Call_Primitive,
           Editor.Ada_Syntax_Tree.Node_Id (118901));
      Access_Profile : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (2,
           Final_RM.Final_RM_Access_Subprogram_Profile,
           Editor.Ada_Syntax_Tree.Node_Id (118902));
      Generic_Call : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (3,
           Final_RM.Final_RM_Nested_Generic_Prefixed_Call,
           Editor.Ada_Syntax_Tree.Node_Id (118903));
   begin
      Access_Profile.Edge_Status := Edge.Overload_Type_Edge_Legal_Access_Subprogram_Profile_Accepted;
      Generic_Call.Edge_Status := Edge.Overload_Type_Edge_Legal_Generic_Formal_Subprogram_Accepted;

      Final_RM.Add_Context (Contexts, Prefixed);
      Final_RM.Add_Context (Contexts, Access_Profile);
      Final_RM.Add_Context (Contexts, Generic_Call);

      declare
         Model : constant Final_RM.Final_RM_Model := Final_RM.Build (Contexts);
      begin
         Assert (Final_RM.Row_Count (Model) = 3, "three final RM rows expected");
         Assert (Final_RM.Legal_Count (Model) = 3, "complete consumer evidence should keep rows legal");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118901)).Status =
            Final_RM.Final_RM_Legal_Prefixed_Call_Primitive_Selected,
            "prefixed primitive should remain accepted");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118902)).Status =
            Final_RM.Final_RM_Legal_Access_Subprogram_Profile_Accepted,
            "access-to-subprogram profile should remain accepted");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118903)).Status =
            Final_RM.Final_RM_Legal_Nested_Generic_Prefixed_Call_Accepted,
            "nested generic prefixed call should remain accepted");
         Assert (Final_RM.Fingerprint (Model) /= 0, "model fingerprint must be deterministic");
      end;
   end Accepted_Final_RM_Edges_Require_All_Consumer_Evidence;

   procedure Ambiguous_RM_Edges_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Final_RM.Final_RM_Context_Model;
      Class_Wide : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (1,
           Final_RM.Final_RM_Class_Wide_Controlling_Result,
           Editor.Ada_Syntax_Tree.Node_Id (118921));
      Universal : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (2,
           Final_RM.Final_RM_Universal_Fixed_Root_Numeric_Mixed_Mode,
           Editor.Ada_Syntax_Tree.Node_Id (118922));
   begin
      Class_Wide.Class_Wide_Controlling_Count := 2;
      Universal.Universal_Root_Tie_Count := 2;

      Final_RM.Add_Context (Contexts, Class_Wide);
      Final_RM.Add_Context (Contexts, Universal);

      declare
         Model : constant Final_RM.Final_RM_Model := Final_RM.Build (Contexts);
      begin
         Assert (Final_RM.Legal_Count (Model) = 0, "ambiguous rows should not remain legal");
         Assert (Final_RM.Ambiguous_Count (Model) = 2, "ambiguous RM rows should be counted");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118921)).Status =
            Final_RM.Final_RM_Class_Wide_Controlling_Result_Ambiguous,
            "class-wide controlling result ambiguity should be preserved");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118922)).Status =
            Final_RM.Final_RM_Universal_Fixed_Root_Numeric_Ambiguous,
            "universal fixed/root numeric ambiguity should be preserved");
      end;
   end Ambiguous_RM_Edges_Are_Preserved;

   procedure Missing_AST_And_Backmap_Evidence_Block_Final_Conclusions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Final_RM.Final_RM_Context_Model;
      Access_Row : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (1,
           Final_RM.Final_RM_Access_Subprogram_Null_Exclusion,
           Editor.Ada_Syntax_Tree.Node_Id (118941));
      Generic_Row : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (2,
           Final_RM.Final_RM_Generic_Formal_Subprogram_Instance,
           Editor.Ada_Syntax_Tree.Node_Id (118942));
      View_Row : Final_RM.Final_RM_Context_Info :=
        Complete_Context
          (3,
           Final_RM.Final_RM_Inherited_Private_Extension_Primitive,
           Editor.Ada_Syntax_Tree.Node_Id (118943));
   begin
      Access_Row.Access_AST_Status := Access_AST.Access_Definition_AST_Not_Checked;
      Generic_Row.Generic_Backmap_Status := Backmap.Generic_Backmap_Not_Checked;
      View_Row.Cross_Unit_View_Barrier := True;

      Final_RM.Add_Context (Contexts, Access_Row);
      Final_RM.Add_Context (Contexts, Generic_Row);
      Final_RM.Add_Context (Contexts, View_Row);

      declare
         Model : constant Final_RM.Final_RM_Model := Final_RM.Build (Contexts);
      begin
         Assert (Final_RM.Legal_Count (Model) = 0, "missing evidence should block final conclusions");
         Assert (Final_RM.Access_AST_Blocker_Count (Model) = 1, "access AST blocker should be counted");
         Assert (Final_RM.Generic_Backmap_Blocker_Count (Model) = 1, "generic backmap blocker should be counted");
         Assert (Final_RM.Cross_Unit_Barrier_Count (Model) = 1, "cross-unit barrier should be counted");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118941)).Status =
            Final_RM.Final_RM_Missing_Access_Definition_AST,
            "access AST evidence should be required");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118942)).Status =
            Final_RM.Final_RM_Missing_Generic_Backmap,
            "generic backmapping evidence should be required");
         Assert
           (Final_RM.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (118943)).Status =
            Final_RM.Final_RM_Cross_Unit_View_Barrier,
            "cross-unit view barrier should be preserved");
      end;
   end Missing_AST_And_Backmap_Evidence_Block_Final_Conclusions;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Final_RM_Edges_Require_All_Consumer_Evidence'Access,
         "accepted final RM overload edges require all consumer evidence");
      Register_Routine
        (T,
         Ambiguous_RM_Edges_Are_Preserved'Access,
         "ambiguous final RM overload edges are preserved");
      Register_Routine
        (T,
         Missing_AST_And_Backmap_Evidence_Block_Final_Conclusions'Access,
         "missing AST/backmap/cross-unit evidence blocks final RM conclusions");
   end Register_Tests;

end Test_Ada_Overload_Type_Final_RM_Consumer_Legality;
