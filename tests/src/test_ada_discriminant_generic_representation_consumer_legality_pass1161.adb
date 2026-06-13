with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Discriminant_Dependent_Legality;
with Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
with Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Discriminant_Generic_Representation_Consumer_Legality_Pass1161 is

   package Disc renames Editor.Ada_Discriminant_Dependent_Legality;
   use type Disc.Discriminant_Context_Id;
   use type Disc.Discriminant_Legality_Id;
   use type Disc.Discriminant_Context_Kind;
   use type Disc.Discriminant_Legality_Status;
   use type Disc.Discriminant_Context_Info;
   use type Disc.Discriminant_Legality_Info;
   use type Disc.Discriminant_Context_Model;
   use type Disc.Discriminant_Result_Set;
   use type Disc.Discriminant_Legality_Model;
   package DG renames Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality;
   use type DG.Discriminant_Generic_Row_Id;
   use type DG.Discriminant_Generic_Context_Kind;
   use type DG.Discriminant_Generic_Status;
   use type DG.Discriminant_Generic_Context_Info;
   use type DG.Discriminant_Generic_Info;
   use type DG.Discriminant_Generic_Context_Model;
   use type DG.Discriminant_Generic_Set;
   use type DG.Discriminant_Generic_Model;
   package Gen_Rep renames Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality;
   use type Gen_Rep.Generic_Replay_Representation_Row_Id;
   use type Gen_Rep.Generic_Replay_Representation_Context_Kind;
   use type Gen_Rep.Generic_Replay_Representation_Status;
   use type Gen_Rep.Generic_Replay_Representation_Context_Info;
   use type Gen_Rep.Generic_Replay_Representation_Info;
   use type Gen_Rep.Generic_Replay_Representation_Context_Model;
   use type Gen_Rep.Generic_Replay_Representation_Set;
   use type Gen_Rep.Generic_Replay_Representation_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Discriminant_Generic_Representation_Consumer_Legality_Pass1161");
   end Name;

   function Sample_Context_Model return DG.Discriminant_Generic_Context_Model is
      Contexts : DG.Discriminant_Generic_Context_Model;
      C        : DG.Discriminant_Generic_Context_Info;
   begin
      C.Id := 1;
      C.Kind := DG.Discriminant_Generic_Record_Aggregate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116101);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (1);
      C.Discriminant_Status := Disc.Discriminant_Legality_Legal_Aggregate_Discriminants;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (1);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Legal_Record_Layout_Accepted;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1101;
      C.Instance_Fingerprint := 2101;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := DG.Discriminant_Generic_Variant_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116102);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (2);
      C.Discriminant_Status := Disc.Discriminant_Legality_Variant_Missing_For_Value;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (2);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Legal_Record_Layout_Accepted;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1102;
      C.Instance_Fingerprint := 2102;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := DG.Discriminant_Generic_Discriminant_Default;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116103);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (3);
      C.Discriminant_Status := Disc.Discriminant_Legality_Default_Depends_On_Later_Discriminant;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (3);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Legal_Representation_Clause_Accepted;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1103;
      C.Instance_Fingerprint := 2103;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := DG.Discriminant_Generic_Generic_Replay;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116104);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (4);
      C.Discriminant_Status := Disc.Discriminant_Legality_Legal_Generic_Actual_Check;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (4);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Replay_Representation_Error;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1104;
      C.Instance_Fingerprint := 2104;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := DG.Discriminant_Generic_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116105);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (5);
      C.Discriminant_Status := Disc.Discriminant_Legality_Legal_Variant_Presence;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (5);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Refined_Global_Missing_Write;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1105;
      C.Instance_Fingerprint := 2105;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := DG.Discriminant_Generic_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116106);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (6);
      C.Discriminant_Status := Disc.Discriminant_Legality_Legal_Variant_Presence;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (6);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Refined_Depends_Missing_Edge;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1106;
      C.Instance_Fingerprint := 2106;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := DG.Discriminant_Generic_Freezing_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116107);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.Discriminant_Legality_Id (7);
      C.Discriminant_Status := Disc.Discriminant_Legality_Legal_Variant_Presence;
      C.Discriminant_Matches := 1;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (7);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Call_Effect_Not_Propagated;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1107;
      C.Instance_Fingerprint := 2107;
      DG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := DG.Discriminant_Generic_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116108);
      C.Type_Name := To_Unbounded_String ("Packet");
      C.Instance_Name := To_Unbounded_String ("Codec_Instance");
      C.Discriminant_Row := Disc.No_Discriminant_Legality;
      C.Discriminant_Status := Disc.Discriminant_Legality_Not_Checked;
      C.Discriminant_Matches := 0;
      C.Generic_Representation_Row := Gen_Rep.Generic_Replay_Representation_Row_Id (8);
      C.Generic_Representation_Status := Gen_Rep.Generic_Replay_Representation_Legal_Private_Full_View_Accepted;
      C.Generic_Representation_Matches := 1;
      C.Source_Fingerprint := 1108;
      C.Instance_Fingerprint := 2108;
      DG.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant DG.Discriminant_Generic_Model := DG.Build (Sample_Context_Model);
   begin
      Assert (DG.Row_Count (Model) = 8, "expected eight discriminant generic-representation rows");
      Assert (DG.Legal_Count (Model) = 1, "only the fully legal aggregate/record-layout consumer should be accepted");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Variant_Missing_For_Value) = 1,
              "variant absence must block generic representation consumers");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Default_Depends_On_Later_Discriminant) = 1,
              "invalid discriminant defaults must block represented generic replay");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Generic_Replay_Error) = 1,
              "base generic replay representation errors must be preserved");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Representation_Flow_Global_Error) = 1,
              "Refined_Global blockers must reach discriminant generic consumers");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Representation_Flow_Depends_Error) = 1,
              "Refined_Depends blockers must reach discriminant generic consumers");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Representation_Flow_Propagation_Error) = 1,
              "call propagation blockers must reach discriminant generic consumers");
      Assert (DG.Count_Status (Model, DG.Discriminant_Generic_Missing_Discriminant_Row) = 1,
              "missing discriminant evidence must not produce confident consumers");
      Assert (DG.Variant_Error_Count (Model) = 1, "expected one variant blocker");
      Assert (DG.Discriminant_Error_Count (Model) = 1, "expected one non-variant discriminant blocker");
      Assert (DG.Generic_Representation_Error_Count (Model) = 4, "expected four generic/representation-flow blockers");
      Assert (DG.Flow_Error_Count (Model) = 3, "expected three refined-flow blockers");
      Assert (DG.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant DG.Discriminant_Generic_Model := DG.Build (Sample_Context_Model);
      Row   : constant DG.Discriminant_Generic_Info :=
        DG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116105));
      Set   : constant DG.Discriminant_Generic_Set := DG.Rows_For_Instance (Model, "Codec_Instance");
   begin
      Assert (Row.Status = DG.Discriminant_Generic_Representation_Flow_Global_Error,
              "node lookup must preserve refined global representation-flow blocker");
      Assert (DG.Set_Count (Set) = 8, "all sample rows belong to Codec_Instance");
      Assert (DG.Count_Kind (Model, DG.Discriminant_Generic_Record_Layout) = 1,
              "kind count must preserve record-layout consumer row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "discriminants feed generic representation consumers");
      Register_Routine (T, Test_Queries'Access, "discriminant generic representation lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Discriminant_Generic_Representation_Consumer_Legality_Pass1161;
