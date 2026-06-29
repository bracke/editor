with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Discriminant_Variant_Consumer_Integration_Legality is

   package Consumer renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   use type Consumer.Discriminant_Consumer_Row_Id;
   use type Consumer.Discriminant_Consumer_Context_Kind;
   use type Consumer.Discriminant_Consumer_Status;
   use type Consumer.Discriminant_Consumer_Context_Info;
   use type Consumer.Discriminant_Consumer_Info;
   use type Consumer.Discriminant_Consumer_Context_Model;
   use type Consumer.Discriminant_Consumer_Set;
   use type Consumer.Discriminant_Consumer_Model;
   package Disc_Generic renames Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
   use type Disc_Generic.Discriminant_Generic_Row_Id;
   use type Disc_Generic.Discriminant_Generic_Context_Kind;
   use type Disc_Generic.Discriminant_Generic_Status;
   use type Disc_Generic.Discriminant_Generic_Context_Info;
   use type Disc_Generic.Discriminant_Generic_Info;
   use type Disc_Generic.Discriminant_Generic_Context_Model;
   use type Disc_Generic.Discriminant_Generic_Set;
   use type Disc_Generic.Discriminant_Generic_Model;
   package Disc_AST renames Editor.Ada_Discriminant_Variant_AST_Repair_Legality;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Row_Id;
   use type Disc_AST.Discriminant_Variant_AST_Construct_Kind;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Status;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Context_Info;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Info;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Context_Model;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Model;
   use type Disc_AST.Discriminant_Variant_AST_Repair_Result_Set;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep_CPD.Representation_Tasking_CPD_Row_Id;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Kind;
   use type Rep_CPD.Representation_Tasking_CPD_Status;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Info;
   use type Rep_CPD.Representation_Tasking_CPD_Info;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Model;
   use type Rep_CPD.Representation_Tasking_CPD_Set;
   use type Rep_CPD.Representation_Tasking_CPD_Model;
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
      return AUnit.Format ("Test_Ada_Discriminant_Variant_Consumer_Integration_Legality");
   end Name;

   procedure Fill_Common (C : in out Consumer.Discriminant_Consumer_Context_Info; Id : Natural) is
   begin
      C.Id := Consumer.Discriminant_Consumer_Row_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118200 + Id);
      C.Type_Node := Editor.Ada_Syntax_Tree.Node_Id (118300 + Id);
      C.Discriminant_Node := Editor.Ada_Syntax_Tree.Node_Id (118400 + Id);
      C.Variant_Node := Editor.Ada_Syntax_Tree.Node_Id (118500 + Id);
      C.Consumer_Node := Editor.Ada_Syntax_Tree.Node_Id (118600 + Id);
      C.Type_Name := To_Unbounded_String ("R");
      C.Object_Name := To_Unbounded_String ("Obj");
      C.Unit_Name := To_Unbounded_String ("Pkg");
      C.Instance_Name := To_Unbounded_String ("Inst");
      C.Disc_Generic_Row := Disc_Generic.Discriminant_Generic_Row_Id (Id);
      C.Disc_Generic_Status := Disc_Generic.Discriminant_Generic_Legal_Record_Layout_Accepted;
      C.Disc_Generic_Matches := 1;
      C.AST_Repair_Row := Disc_AST.Discriminant_Variant_AST_Repair_Row_Id (Id);
      C.AST_Repair_Status := Disc_AST.Discriminant_Variant_AST_Legal_Variant_Part_Repaired;
      C.AST_Repair_Matches := 1;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (Id);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Legal_Record_Layout_Accepted;
      C.Representation_CPD_Matches := 1;
      C.Generic_Backmap_Row := Backmap.Generic_Backmap_Row_Id (Id);
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Legal_Representation_Backmapped;
      C.Generic_Backmap_Matches := 1;
      C.Source_Fingerprint := 9000 + Id;
      C.Consumer_Fingerprint := 10000 + Id;
   end Fill_Common;

   function Sample_Context_Model return Consumer.Discriminant_Consumer_Context_Model is
      Contexts : Consumer.Discriminant_Consumer_Context_Model;
      C        : Consumer.Discriminant_Consumer_Context_Info;
   begin
      Fill_Common (C, 1);
      C.Kind := Consumer.Discriminant_Consumer_Record_Layout;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 2);
      C.Kind := Consumer.Discriminant_Consumer_Record_Aggregate;
      C.Disc_Generic_Status := Disc_Generic.Discriminant_Generic_Variant_Choice_Coverage_Gap;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 3);
      C.Kind := Consumer.Discriminant_Consumer_Private_Full_View;
      C.Disc_Generic_Status := Disc_Generic.Discriminant_Generic_Private_Full_View_Mismatch;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Kind := Consumer.Discriminant_Consumer_Freezing_Effect;
      C.Disc_Generic_Status := Disc_Generic.Discriminant_Generic_Generic_Representation_Error;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Kind := Consumer.Discriminant_Consumer_Access_Discriminant;
      C.Disc_Generic_Row := Disc_Generic.No_Discriminant_Generic_Row;
      C.Disc_Generic_Status := Disc_Generic.Discriminant_Generic_Not_Checked;
      C.Disc_Generic_Matches := 0;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Kind := Consumer.Discriminant_Consumer_Record_Layout;
      C.AST_Repair_Status := Disc_AST.Discriminant_Variant_AST_Source_Span_Still_Missing;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Kind := Consumer.Discriminant_Consumer_Representation_Clause;
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Representation_Freezing_Blocker;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Kind := Consumer.Discriminant_Consumer_Generic_Replay;
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Missing_Formal_Actual_Map;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 9);
      C.Kind := Consumer.Discriminant_Consumer_Generic_Replay;
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Matches := 2;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 10);
      C.Kind := Consumer.Discriminant_Consumer_Allocator;
      C.Disc_Generic_Matches := 2;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 11);
      C.Kind := Consumer.Discriminant_Consumer_Return;
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Indeterminate;
      Consumer.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Consumer.Discriminant_Consumer_Model := Consumer.Build (Sample_Context_Model);
   begin
      Assert (Consumer.Row_Count (Model) = 11, "expected eleven discriminant consumer rows");
      Assert (Consumer.Legal_Count (Model) = 1, "only complete evidence should remain legal");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Variant_Coverage_Blocker) = 1,
              "variant coverage must block aggregate/layout consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Private_Full_View_Mismatch_Blocker) = 1,
              "private/full-view discriminant mismatch must be preserved");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Freezing_Discriminant_Blocker) = 1,
              "representation/freezing discriminant blockers must be preserved");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Missing_Discriminant_Generic_Row) = 1,
              "missing discriminant evidence must block consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_AST_Repair_Blocker) = 1,
              "unrepaired discriminant AST must block consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Representation_CPD_Blocker) = 1,
              "representation CPD blockers must be preserved");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Generic_Backmap_Blocker) = 1,
              "generic backmap blockers must be preserved");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Multiple_Generic_Backmap_Blockers) = 1,
              "multiple backmaps must block confident generic replay discriminant consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Discriminant_Consumer_Multiple_Discriminant_Generic_Blockers) = 1,
              "multiple discriminant rows must block confident consumers");
      Assert (Consumer.Indeterminate_Count (Model) = 1, "indeterminate representation evidence must remain indeterminate");
      Assert (Consumer.Discriminant_Error_Count (Model) = 5, "expected five discriminant-family errors");
      Assert (Consumer.AST_Repair_Error_Count (Model) = 1, "expected one AST repair blocker");
      Assert (Consumer.Representation_Error_Count (Model) = 2, "expected representation blocker plus freezing discriminant blocker");
      Assert (Consumer.Generic_Backmap_Error_Count (Model) = 2, "expected generic backmap blockers");
      Assert (Consumer.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Consumer.Discriminant_Consumer_Model := Consumer.Build (Sample_Context_Model);
      Row   : constant Consumer.Discriminant_Consumer_Info :=
        Consumer.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118208));
      By_Type : constant Consumer.Discriminant_Consumer_Set := Consumer.Rows_For_Type (Model, "R");
      By_Kind : constant Consumer.Discriminant_Consumer_Set :=
        Consumer.Rows_For_Kind (Model, Consumer.Discriminant_Consumer_Generic_Replay);
   begin
      Assert (Row.Status = Consumer.Discriminant_Consumer_Generic_Backmap_Blocker,
              "node lookup must preserve generic backmap blocker");
      Assert (Consumer.Set_Count (By_Type) = 11, "all sample rows are for type R");
      Assert (Consumer.Set_Count (By_Kind) = 2, "two sample rows are generic replay discriminant consumers");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "discriminant/variant consumer integration blockers");
      Register_Routine (T, Test_Queries'Access, "discriminant consumer integration lookups");
   end Register_Tests;

end Test_Ada_Discriminant_Variant_Consumer_Integration_Legality;
