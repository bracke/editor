with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
with Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
with Editor.Ada_Representation_Operational_AST_Repair_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;

package body Test_Ada_Representation_Freezing_Final_Hard_Cases_Legality is

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Access_Final.Master_Scope_Final_Context_Kind;
   use type Access_Final.Master_Scope_Final_Status;
   use type Access_Final.Master_Scope_Final_Context_Info;
   use type Access_Final.Master_Scope_Final_Info;
   use type Access_Final.Master_Scope_Final_Context_Model;
   use type Access_Final.Master_Scope_Final_Set;
   use type Access_Final.Master_Scope_Final_Model;
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
   package Disc_Consumer renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   use type Disc_Consumer.Discriminant_Consumer_Row_Id;
   use type Disc_Consumer.Discriminant_Consumer_Context_Kind;
   use type Disc_Consumer.Discriminant_Consumer_Status;
   use type Disc_Consumer.Discriminant_Consumer_Context_Info;
   use type Disc_Consumer.Discriminant_Consumer_Info;
   use type Disc_Consumer.Discriminant_Consumer_Context_Model;
   use type Disc_Consumer.Discriminant_Consumer_Set;
   use type Disc_Consumer.Discriminant_Consumer_Model;
   package Elab_Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   use type Elab_Final.Final_Elaboration_Row_Id;
   use type Elab_Final.Final_Elaboration_Context_Kind;
   use type Elab_Final.Final_Elaboration_Status;
   use type Elab_Final.Final_Elaboration_Context_Info;
   use type Elab_Final.Final_Elaboration_Info;
   use type Elab_Final.Final_Elaboration_Context_Model;
   use type Elab_Final.Final_Elaboration_Set;
   use type Elab_Final.Final_Elaboration_Model;
   package Generic_Cycles renames Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
   use type Generic_Cycles.Nested_Generic_Closure_Row_Id;
   use type Generic_Cycles.Nested_Generic_Closure_Kind;
   use type Generic_Cycles.Nested_Generic_Closure_Status;
   use type Generic_Cycles.Nested_Generic_Closure_Context_Info;
   use type Generic_Cycles.Nested_Generic_Closure_Info;
   use type Generic_Cycles.Nested_Generic_Closure_Context_Model;
   use type Generic_Cycles.Nested_Generic_Closure_Model;
   use type Generic_Cycles.Nested_Generic_Closure_Result_Set;
   package Final_Rep renames Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
   use type Final_Rep.Final_Representation_Row_Id;
   use type Final_Rep.Final_Representation_Context_Kind;
   use type Final_Rep.Final_Representation_Status;
   use type Final_Rep.Final_Representation_Context_Info;
   use type Final_Rep.Final_Representation_Info;
   use type Final_Rep.Final_Representation_Context_Model;
   use type Final_Rep.Final_Representation_Model;
   use type Final_Rep.Final_Representation_Set;
   package Rep_AST renames Editor.Ada_Representation_Operational_AST_Repair_Legality;
   use type Rep_AST.Representation_Operational_AST_Repair_Row_Id;
   use type Rep_AST.Representation_Operational_AST_Construct_Kind;
   use type Rep_AST.Representation_Operational_AST_Repair_Status;
   use type Rep_AST.Representation_Operational_AST_Repair_Context_Info;
   use type Rep_AST.Representation_Operational_AST_Repair_Info;
   use type Rep_AST.Representation_Operational_AST_Repair_Context_Model;
   use type Rep_AST.Representation_Operational_AST_Repair_Model;
   use type Rep_AST.Representation_Operational_AST_Repair_Result_Set;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep_CPD.Representation_Tasking_CPD_Row_Id;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Kind;
   use type Rep_CPD.Representation_Tasking_CPD_Status;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Info;
   use type Rep_CPD.Representation_Tasking_CPD_Info;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Model;
   use type Rep_CPD.Representation_Tasking_CPD_Set;
   use type Rep_CPD.Representation_Tasking_CPD_Model;
   package Task_Final renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;
   use type Task_Final.Final_Tasking_Row_Id;
   use type Task_Final.Final_Tasking_Context_Kind;
   use type Task_Final.Final_Tasking_Status;
   use type Task_Final.Final_Tasking_Context_Info;
   use type Task_Final.Final_Tasking_Info;
   use type Task_Final.Final_Tasking_Context_Model;
   use type Task_Final.Final_Tasking_Set;
   use type Task_Final.Final_Tasking_Model;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Representation_Freezing_Final_Hard_Cases_Legality");
   end Name;

   function Complete_Context
     (Id   : Final_Rep.Final_Representation_Row_Id;
      Kind : Final_Rep.Final_Representation_Context_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id)
      return Final_Rep.Final_Representation_Context_Info is
      C : Final_Rep.Final_Representation_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Target_Name := To_Unbounded_String ("T" & Natural'Image (Natural (Id)));
      C.Unit_Name := To_Unbounded_String ("Pkg");
      C.Component_Name := To_Unbounded_String ("C");
      C.Representation_Status := Rep_CPD.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted;
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Representation_Accepted;
      C.Generic_Cycle_Status := Generic_Cycles.Nested_Generic_Legal_Representation_Replay_Closed;
      C.AST_Repair_Status := Rep_AST.Representation_Operational_AST_Legal_Representation_Clause_Repaired;
      C.Discriminant_Status := Disc_Consumer.Discriminant_Consumer_Legal_Representation_Clause_Accepted;
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Controlled_Finalization_Accepted;
      C.Elaboration_Status := Elab_Final.Final_Elaboration_Legal_Representation_Item_Accepted;
      C.Tasking_Status := Task_Final.Final_Tasking_Legal_Protected_Read_Accepted;
      C.Requires_Cross_Unit := True;
      C.Requires_Generic_Cycle := True;
      C.Requires_AST_Repair := True;
      C.Requires_Discriminant := True;
      C.Requires_Accessibility := True;
      C.Requires_Elaboration := True;
      C.Requires_Tasking := True;
      C.Source_Fingerprint := Natural (Id) * 1191;
      C.Expected_Source_Fingerprint := Natural (Id) * 1191;
      return C;
   end Complete_Context;

   procedure Accepted_Final_Representation_Hard_Cases_Require_All_Final_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Final_Rep.Final_Representation_Context_Model;
      Private_View : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (1,
           Final_Rep.Final_Representation_Private_Full_View_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119101));
      Generic_Formal : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (2,
           Final_Rep.Final_Representation_Generic_Formal_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119102));
      Variant_Layout : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (3,
           Final_Rep.Final_Representation_Variant_Record_Layout,
           Editor.Ada_Syntax_Tree.Node_Id (119103));
   begin
      Generic_Formal.Representation_Status := Rep_CPD.Representation_Tasking_CPD_Legal_Generic_Instance_Effect_Accepted;
      Variant_Layout.Representation_Status := Rep_CPD.Representation_Tasking_CPD_Legal_Record_Layout_Accepted;
      Variant_Layout.Discriminant_Status := Disc_Consumer.Discriminant_Consumer_Legal_Record_Layout_Accepted;

      Final_Rep.Add_Context (Contexts, Private_View);
      Final_Rep.Add_Context (Contexts, Generic_Formal);
      Final_Rep.Add_Context (Contexts, Variant_Layout);

      declare
         Model : constant Final_Rep.Final_Representation_Model := Final_Rep.Build (Contexts);
      begin
         Assert (Final_Rep.Row_Count (Model) = 3, "three final representation rows expected");
         Assert (Final_Rep.Legal_Count (Model) = 3, "complete final evidence should keep hard cases legal");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119101)).Status =
            Final_Rep.Final_Representation_Legal_Private_Full_View_Freezing_Accepted,
            "private/full-view freezing should be accepted with final evidence");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119102)).Status =
            Final_Rep.Final_Representation_Legal_Generic_Formal_Freezing_Accepted,
            "generic formal freezing should be accepted with final evidence");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119103)).Status =
            Final_Rep.Final_Representation_Legal_Variant_Record_Layout_Accepted,
            "variant record layout should be accepted with discriminant evidence");
         Assert (Final_Rep.Fingerprint (Model) /= 0, "model fingerprint must be deterministic");
      end;
   end Accepted_Final_Representation_Hard_Cases_Require_All_Final_Evidence;

   procedure Missing_Cross_Generic_AST_And_Discriminant_Evidence_Block_Final_Representation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Final_Rep.Final_Representation_Context_Model;
      Missing_Cross : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (1,
           Final_Rep.Final_Representation_Private_Full_View_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119121));
      Missing_Generic : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (2,
           Final_Rep.Final_Representation_Generic_Instance_Representation,
           Editor.Ada_Syntax_Tree.Node_Id (119122));
      Missing_AST : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (3,
           Final_Rep.Final_Representation_Operational_Item,
           Editor.Ada_Syntax_Tree.Node_Id (119123));
      Missing_Discriminant : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (4,
           Final_Rep.Final_Representation_Record_Layout_Discriminant_Finalization,
           Editor.Ada_Syntax_Tree.Node_Id (119124));
   begin
      Missing_Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Missing_Generic.Generic_Cycle_Status := Generic_Cycles.Nested_Generic_Not_Checked;
      Missing_AST.AST_Repair_Status := Rep_AST.Representation_Operational_AST_Not_Checked;
      Missing_Discriminant.Discriminant_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;

      Final_Rep.Add_Context (Contexts, Missing_Cross);
      Final_Rep.Add_Context (Contexts, Missing_Generic);
      Final_Rep.Add_Context (Contexts, Missing_AST);
      Final_Rep.Add_Context (Contexts, Missing_Discriminant);

      declare
         Model : constant Final_Rep.Final_Representation_Model := Final_Rep.Build (Contexts);
      begin
         Assert (Final_Rep.Legal_Count (Model) = 0, "missing evidence should block final representation legality");
         Assert (Final_Rep.Cross_Unit_Error_Count (Model) = 1, "cross-unit blocker should be counted");
         Assert (Final_Rep.Generic_Error_Count (Model) = 1, "generic blocker should be counted");
         Assert (Final_Rep.AST_Repair_Error_Count (Model) = 1, "AST repair blocker should be counted");
         Assert (Final_Rep.Discriminant_Error_Count (Model) = 1, "discriminant blocker should be counted");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119121)).Status =
            Final_Rep.Final_Representation_Missing_Cross_Unit_Final_Row,
            "cross-unit closure evidence should be required");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119122)).Status =
            Final_Rep.Final_Representation_Missing_Generic_Cycle_Row,
            "nested generic cycle evidence should be required");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119123)).Status =
            Final_Rep.Final_Representation_Missing_AST_Repair_Row,
            "AST repair evidence should be required");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119124)).Status =
            Final_Rep.Final_Representation_Missing_Discriminant_Row,
            "discriminant evidence should be required");
      end;
   end Missing_Cross_Generic_AST_And_Discriminant_Evidence_Block_Final_Representation;

   procedure Explicit_Freezing_Hard_Cases_Are_Preserved_As_Blocker_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : Final_Rep.Final_Representation_Context_Model;
      Generic_Formal : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (1,
           Final_Rep.Final_Representation_Generic_Formal_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119141));
      Inherited_Operational : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (2,
           Final_Rep.Final_Representation_Inherited_Operational_Attribute,
           Editor.Ada_Syntax_Tree.Node_Id (119142));
      Stream_View : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (3,
           Final_Rep.Final_Representation_Stream_Attribute_Private_View,
           Editor.Ada_Syntax_Tree.Node_Id (119143));
      Freezing_Order : Final_Rep.Final_Representation_Context_Info :=
        Complete_Context
          (4,
           Final_Rep.Final_Representation_Implicit_Freezing_Order,
           Editor.Ada_Syntax_Tree.Node_Id (119144));
   begin
      Generic_Formal.Generic_Formal_Freezing_Error := True;
      Inherited_Operational.Inherited_Operational_Attribute_Error := True;
      Stream_View.Stream_Attribute_View_Error := True;
      Freezing_Order.Implicit_Freezing_Order_Error := True;

      Final_Rep.Add_Context (Contexts, Generic_Formal);
      Final_Rep.Add_Context (Contexts, Inherited_Operational);
      Final_Rep.Add_Context (Contexts, Stream_View);
      Final_Rep.Add_Context (Contexts, Freezing_Order);

      declare
         Model : constant Final_Rep.Final_Representation_Model := Final_Rep.Build (Contexts);
      begin
         Assert (Final_Rep.Legal_Count (Model) = 0, "explicit hard-case blockers must not remain legal");
         Assert (Final_Rep.Freezing_Order_Error_Count (Model) = 4, "hard freezing/order blockers should be counted");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119141)).Status =
            Final_Rep.Final_Representation_Generic_Formal_Freezing_Blocker,
            "generic formal freezing blocker should be preserved");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119142)).Status =
            Final_Rep.Final_Representation_Inherited_Operational_Attribute_Blocker,
            "inherited operational attribute blocker should be preserved");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119143)).Status =
            Final_Rep.Final_Representation_Stream_Attribute_View_Blocker,
            "stream attribute view blocker should be preserved");
         Assert
           (Final_Rep.First_For_Node
              (Model, Editor.Ada_Syntax_Tree.Node_Id (119144)).Status =
            Final_Rep.Final_Representation_Implicit_Freezing_Order_Blocker,
            "implicit freezing order blocker should be preserved");
      end;
   end Explicit_Freezing_Hard_Cases_Are_Preserved_As_Blocker_Families;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Accepted_Final_Representation_Hard_Cases_Require_All_Final_Evidence'Access,
         "accepted final representation hard cases require all final evidence");
      Register_Routine
        (T,
         Missing_Cross_Generic_AST_And_Discriminant_Evidence_Block_Final_Representation'Access,
         "missing cross/generic/AST/discriminant evidence blocks final representation");
      Register_Routine
        (T,
         Explicit_Freezing_Hard_Cases_Are_Preserved_As_Blocker_Families'Access,
         "explicit freezing hard cases are preserved as blocker families");
   end Register_Tests;

end Test_Ada_Representation_Freezing_Final_Hard_Cases_Legality;
