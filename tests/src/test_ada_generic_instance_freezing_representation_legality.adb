with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Generic_Formal_Package_Substitutions;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Tagged_Derived_Legality;

package body Test_Ada_Generic_Instance_Freezing_Representation_Legality is

   package GI renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
   use type GI.Instance_Context_Id;
   use type GI.Instance_Legality_Id;
   use type GI.Instance_Context_Kind;
   use type GI.Instance_Legality_Status;
   use type GI.Instance_Context_Info;
   use type GI.Instance_Legality_Info;
   use type GI.Instance_Context_Model;
   use type GI.Instance_Result_Set;
   use type GI.Instance_Legality_Model;
   package AL renames Editor.Ada_Assignment_Legality;
   use type AL.Expression_Type_Id;
   use type AL.Assignment_Context_Id;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Context_Kind;
   use type AL.Assignment_Target_Mode;
   use type AL.Assignment_Legality_Status;
   use type AL.Assignment_Context_Info;
   use type AL.Assignment_Legality_Info;
   use type AL.Assignment_Context_Model;
   use type AL.Assignment_Legality_Result_Set;
   use type AL.Assignment_Legality_Model;
   package RL renames Editor.Ada_Return_Legality;
   use type RL.Assignment_Context_Id;
   use type RL.Assignment_Legality_Status;
   use type RL.Return_Context_Id;
   use type RL.Return_Legality_Id;
   use type RL.Return_Context_Kind;
   use type RL.Return_Legality_Status;
   use type RL.Return_Context_Info;
   use type RL.Return_Legality_Info;
   use type RL.Return_Context_Model;
   use type RL.Return_Legality_Result_Set;
   use type RL.Return_Legality_Model;
   package EL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type EL.Semantic_Context_Id;
   use type EL.Semantic_Legality_Id;
   use type EL.Semantic_Context_Kind;
   use type EL.Access_Kind;
   use type EL.Semantic_Legality_Status;
   use type EL.Semantic_Context_Info;
   use type EL.Semantic_Legality_Info;
   use type EL.Semantic_Context_Model;
   use type EL.Semantic_Legality_Result_Set;
   use type EL.Semantic_Legality_Model;
   package TD renames Editor.Ada_Tagged_Derived_Legality;
   use type TD.Tagged_Context_Id;
   use type TD.Tagged_Legality_Id;
   use type TD.Tagged_Context_Kind;
   use type TD.Tagged_Legality_Status;
   use type TD.Tagged_Context_Info;
   use type TD.Tagged_Legality_Info;
   use type TD.Tagged_Context_Model;
   use type TD.Tagged_Result_Set;
   use type TD.Tagged_Legality_Model;
   package GB renames Editor.Ada_Generic_Instantiated_Body_Analysis;
   use type GB.Instantiated_Body_Status;
   use type GB.Instantiated_Body_Substitution_Id;
   use type GB.Instantiated_Body_Substitution_Info;
   use type GB.Instantiated_Body_Model;
   package FP renames Editor.Ada_Generic_Formal_Package_Substitutions;
   use type FP.Formal_Package_Substitution_Status;
   use type FP.Formal_Package_Substitution_Id;
   use type FP.Formal_Package_Substitution_Info;
   use type FP.Formal_Package_Substitution_Model;
   package FR renames Editor.Ada_Freezing_Points;
   use type FR.Freezable_Kind;
   use type FR.Freezing_Cause;
   use type FR.Freezing_Status;
   use type FR.Representation_Freezing_Status;
   use type FR.Freezable_Id;
   use type FR.Freezable_Info;
   use type FR.Representation_Freeze_Info;
   use type FR.Freezing_Model;
   package RP renames Editor.Ada_Representation_Legality;
   use type RP.Representation_Legality_Status;
   use type RP.Address_Value_Status;
   use type RP.Interfacing_Value_Status;
   use type RP.Stream_Subprogram_Status;
   use type RP.Operational_Value_Status;
   use type RP.Representation_Value_Status;
   use type RP.Representation_Legality_Info;
   use type RP.Record_Component_Legality_Info;
   use type RP.Enumeration_Representation_Legality_Info;
   use type RP.Representation_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Generic_Instance_Freezing_Representation_Legality");
   end Name;

   function Build (Contexts : GI.Instance_Context_Model)
      return GI.Instance_Legality_Model
   is
      Bodies         : GB.Instantiated_Body_Model;
      Formal_Pkgs    : FP.Formal_Package_Substitution_Model;
      Freezing       : FR.Freezing_Model;
      Representation : RP.Representation_Legality_Model;
      Assignments    : AL.Assignment_Legality_Model;
      Returns        : RL.Return_Legality_Model;
      Expressions    : EL.Semantic_Legality_Model;
      Tagged_Model         : TD.Tagged_Legality_Model;
   begin
      return GI.Build
        (Contexts, Bodies, Formal_Pkgs, Freezing, Representation,
         Assignments, Returns, Expressions, Tagged_Model);
   end Build;

   procedure Test_Generic_Body_Formal_Package_And_View_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : GI.Instance_Context_Model;
      Context  : GI.Instance_Context_Info;
   begin
      Context.Id := 1;
      Context.Kind := GI.Instance_Context_Body_Substitution;
      Context.Instance_Name := To_Unbounded_String ("G_I");
      Context.Target_Name := To_Unbounded_String ("Formal_T");
      Context.Body_Status := GB.Instantiated_Body_Substituted;
      GI.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 2;
      Context.Kind := GI.Instance_Context_Body_Substitution;
      Context.Instance_Name := To_Unbounded_String ("G_I");
      Context.Target_Name := To_Unbounded_String ("Hidden_T");
      Context.Body_Status := GB.Instantiated_Body_Private_View_Barrier;
      GI.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 3;
      Context.Kind := GI.Instance_Context_Formal_Package_Substitution;
      Context.Instance_Name := To_Unbounded_String ("G_I");
      Context.Target_Name := To_Unbounded_String ("Nested_Formal");
      Context.Formal_Package_Status := FP.Formal_Package_Substitution_Missing;
      GI.Add_Context (Contexts, Context);

      declare
         Model : constant GI.Instance_Legality_Model := Build (Contexts);
         Rows  : constant GI.Instance_Result_Set :=
           GI.Rows_For_Target (Model, To_Unbounded_String ("formal_t"));
      begin
         Assert (GI.Legality_Count (Model) = 3,
                 "three generic instance legality rows expected");
         Assert (GI.Legal_Count (Model) = 1,
                 "one legal body substitution expected");
         Assert (GI.Generic_Body_Error_Count (Model) = 1,
                 "private view barrier should be counted as generic body error");
         Assert (GI.Formal_Package_Error_Count (Model) = 1,
                 "missing nested formal package actual should be counted");
         Assert (GI.Result_Count (Rows) = 1,
                 "target lookup should normalize names");
         Assert (GI.Count_Status
                   (Model, GI.Instance_Legality_Body_Private_View_Barrier) = 1,
                 "private view status should be counted");
         Assert (GI.Fingerprint (Model) /= 0,
                 "model should expose deterministic fingerprint");
      end;
   end Test_Generic_Body_Formal_Package_And_View_Closure;

   procedure Test_Freezing_Representation_And_Linked_Semantic_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : GI.Instance_Context_Model;
      Context  : GI.Instance_Context_Info;
   begin
      Context.Id := 10;
      Context.Kind := GI.Instance_Context_Instance_Freezing;
      Context.Instance_Name := To_Unbounded_String ("Make_T");
      Context.Target_Name := To_Unbounded_String ("T");
      Context.Instance_Freezes_Target := True;
      GI.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 20;
      Context.Kind := GI.Instance_Context_Representation_Item;
      Context.Instance_Name := To_Unbounded_String ("Make_T");
      Context.Target_Name := To_Unbounded_String ("T");
      Context.Representation_After_Instance_Freezing := True;
      Context.Representation_Status := RP.Representation_Legality_After_Freezing;
      GI.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 30;
      Context.Kind := GI.Instance_Context_Representation_Item;
      Context.Instance_Name := To_Unbounded_String ("Make_T");
      Context.Target_Name := To_Unbounded_String ("T'Stream_Size");
      Context.Representation_Status := RP.Representation_Legality_Stream_Subprogram_Profile_Mismatch;
      GI.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 40;
      Context.Kind := GI.Instance_Context_Representation_Item;
      Context.Instance_Name := To_Unbounded_String ("Make_T");
      Context.Target_Name := To_Unbounded_String ("T'Alignment");
      Context.Representation_Status := RP.Representation_Legality_Static_Value_Malformed;
      GI.Add_Context (Contexts, Context);

      declare
         Model : constant GI.Instance_Legality_Model := Build (Contexts);
      begin
         Assert (GI.Legality_Count (Model) = 4,
                 "four freezing/representation rows expected");
         Assert (GI.Warning_Count (Model) = 1,
                 "instance freeze should be preserved as warning metadata");
         Assert (GI.Freezing_Error_Count (Model) = 1,
                 "representation after instance freezing should be counted");
         Assert (GI.Representation_Error_Count (Model) = 2,
                 "stream profile and static representation errors should be counted");
         Assert (GI.Count_Kind
                   (Model, GI.Instance_Context_Representation_Item) = 3,
                 "representation item kind should be counted");
         Assert (GI.Count_Status
                   (Model, GI.Instance_Legality_Representation_Profile_Error) = 1,
                 "stream profile representation error should be classified");
         Assert (GI.First_For_Context (Model, 20).Status =
                   GI.Instance_Legality_Representation_After_Instance_Freezing,
                 "context lookup should expose post-freezing representation error");
      end;
   end Test_Freezing_Representation_And_Linked_Semantic_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Generic_Body_Formal_Package_And_View_Closure'Access,
         "generic body, formal package, and view closure");
      Register_Routine
        (T, Test_Freezing_Representation_And_Linked_Semantic_Closure'Access,
         "generic instance freezing and representation closure");
   end Register_Tests;

end Test_Ada_Generic_Instance_Freezing_Representation_Legality;
