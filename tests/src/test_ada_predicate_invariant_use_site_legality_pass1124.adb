with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Predicate_Invariant_Use_Site_Legality_Pass1124 is

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
   package SL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   use type SL.Semantic_Context_Id;
   use type SL.Semantic_Legality_Id;
   use type SL.Semantic_Context_Kind;
   use type SL.Access_Kind;
   use type SL.Semantic_Legality_Status;
   use type SL.Semantic_Context_Info;
   use type SL.Semantic_Legality_Info;
   use type SL.Semantic_Context_Model;
   use type SL.Semantic_Legality_Result_Set;
   use type SL.Semantic_Legality_Model;
   package GL renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
   use type GL.Instance_Context_Id;
   use type GL.Instance_Legality_Id;
   use type GL.Instance_Context_Kind;
   use type GL.Instance_Legality_Status;
   use type GL.Instance_Context_Info;
   use type GL.Instance_Legality_Info;
   use type GL.Instance_Context_Model;
   use type GL.Instance_Result_Set;
   use type GL.Instance_Legality_Model;
   package OL renames Editor.Ada_Overload_Resolution_Legality;
   use type OL.Overload_Context_Id;
   use type OL.Overload_Legality_Id;
   use type OL.Overload_Context_Kind;
   use type OL.Overload_Legality_Status;
   use type OL.Overload_Context_Info;
   use type OL.Overload_Legality_Info;
   use type OL.Overload_Context_Model;
   use type OL.Overload_Legality_Result_Set;
   use type OL.Overload_Legality_Model;
   package PI renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   use type PI.Predicate_Policy;
   use type PI.Static_Legality_Status;
   use type PI.Assignment_Legality_Status;
   use type PI.Return_Legality_Status;
   use type PI.Semantic_Legality_Status;
   use type PI.Overload_Legality_Status;
   use type PI.Instance_Legality_Status;
   use type PI.Predicate_Use_Context_Id;
   use type PI.Predicate_Use_Legality_Id;
   use type PI.Predicate_Use_Context_Kind;
   use type PI.Invariant_Policy;
   use type PI.Use_Site_Check_Point;
   use type PI.Predicate_Use_Legality_Status;
   use type PI.Predicate_Use_Context_Info;
   use type PI.Predicate_Use_Legality_Info;
   use type PI.Predicate_Use_Context_Model;
   use type PI.Predicate_Use_Result_Set;
   use type PI.Predicate_Use_Legality_Model;
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
   package SRP renames Editor.Ada_Staticness_Range_Predicate_Legality;
   use type SRP.Assignment_Legality_Id;
   use type SRP.Assignment_Legality_Status;
   use type SRP.Return_Legality_Id;
   use type SRP.Return_Legality_Status;
   use type SRP.Semantic_Legality_Id;
   use type SRP.Semantic_Legality_Status;
   use type SRP.Overload_Legality_Id;
   use type SRP.Overload_Legality_Status;
   use type SRP.Static_Context_Id;
   use type SRP.Static_Legality_Id;
   use type SRP.Static_Context_Kind;
   use type SRP.Predicate_Policy;
   use type SRP.Static_Legality_Status;
   use type SRP.Static_Legality_Context_Info;
   use type SRP.Static_Legality_Info;
   use type SRP.Static_Legality_Context_Model;
   use type SRP.Static_Legality_Result_Set;
   use type SRP.Static_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Predicate_Invariant_Use_Site_Legality_Pass1124");
   end Name;

   function Predicate_Model return PI.Predicate_Use_Legality_Model is
      Contexts : PI.Predicate_Use_Context_Model;
      C        : PI.Predicate_Use_Context_Info;
   begin
      C.Id := 1;
      C.Kind := PI.Predicate_Use_Assignment;
      C.Check_Point := PI.Check_Point_After_Assignment;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112401);
      C.Subtype_Name := To_Unbounded_String ("Positive_Count");
      C.Predicate := SRP.Predicate_Static_Known_True;
      C.Invariant := PI.Invariant_Known_Preserved;
      C.Requires_Predicate_Check := True;
      C.Check_Is_Inserted := True;
      C.Staticness_Status := SRP.Static_Legality_Static_Predicate_Compatible;
      C.Assignment_Status := AL.Assignment_Legality_Compatible;
      C.Source_Fingerprint := 401;
      PI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := PI.Predicate_Use_Return;
      C.Check_Point := PI.Check_Point_Return_Object;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112402);
      C.Subtype_Name := To_Unbounded_String ("Non_Empty_Name");
      C.Predicate := SRP.Predicate_Static_Known_False;
      C.Requires_Static_Predicate := True;
      C.Return_Status := RL.Return_Legality_Function_Return_Compatible;
      C.Source_Fingerprint := 402;
      PI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := PI.Predicate_Use_Conversion;
      C.Check_Point := PI.Check_Point_Conversion_Result;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112403);
      C.Subtype_Name := To_Unbounded_String ("Bounded_Index");
      C.Predicate := SRP.Predicate_Dynamic;
      C.Requires_Predicate_Check := True;
      C.Check_Is_Inserted := False;
      C.Semantic_Status := SL.Semantic_Legality_Legal_Conversion;
      C.Source_Fingerprint := 403;
      PI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := PI.Predicate_Use_Record_Aggregate;
      C.Check_Point := PI.Check_Point_Aggregate_Result;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112404);
      C.Subtype_Name := To_Unbounded_String ("Balanced_Record");
      C.Predicate := SRP.Predicate_Not_Present;
      C.Invariant := PI.Invariant_Known_Violated;
      C.Requires_Invariant_Check := True;
      C.Semantic_Status := SL.Semantic_Legality_Legal_Aggregate;
      C.Source_Fingerprint := 404;
      PI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := PI.Predicate_Use_Call_Actual;
      C.Check_Point := PI.Check_Point_Call_Entry;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112405);
      C.Subtype_Name := To_Unbounded_String ("Visible_Actual");
      C.Predicate := SRP.Predicate_Dynamic;
      C.Requires_Predicate_Check := True;
      C.Check_Is_Inserted := True;
      C.Overload_Status := OL.Overload_Legality_Legal_Exact;
      C.Source_Fingerprint := 405;
      PI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := PI.Predicate_Use_Generic_Actual;
      C.Check_Point := PI.Check_Point_Generic_Instantiation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112406);
      C.Subtype_Name := To_Unbounded_String ("Formal_Subtype_Actual");
      C.Predicate := SRP.Predicate_Unresolved;
      C.Instance_Status := GL.Instance_Legality_Legal_Instance;
      C.Source_Fingerprint := 406;
      PI.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := PI.Predicate_Use_Default_Expression;
      C.Check_Point := PI.Check_Point_Default_Evaluation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (112407);
      C.Subtype_Name := To_Unbounded_String ("Generic_Default");
      C.Cross_Unit_View_Resolved := False;
      C.Source_Fingerprint := 407;
      PI.Add_Context (Contexts, C);

      return PI.Build (Contexts);
   end Predicate_Model;

   procedure Predicates_And_Invariants_Are_Use_Site_Enforced
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant PI.Predicate_Use_Legality_Model := Predicate_Model;
      Assignment : constant PI.Predicate_Use_Legality_Info :=
        PI.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112401));
      Return_Row : constant PI.Predicate_Use_Legality_Info :=
        PI.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112402));
      Conversion : constant PI.Predicate_Use_Legality_Info :=
        PI.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112403));
      Aggregate : constant PI.Predicate_Use_Legality_Info :=
        PI.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112404));
      Call_Actual : constant PI.Predicate_Use_Legality_Info :=
        PI.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (112405));
   begin
      Assert (PI.Row_Count (Model) = 7, "all predicate/invariant use sites classified");
      Assert (Assignment.Status = PI.Predicate_Use_Legality_Legal_Static_Range_And_Predicate,
              "assignment use site accepts statically satisfied predicate and preserved invariant");
      Assert (Return_Row.Status = PI.Predicate_Use_Legality_Static_Predicate_Failure,
              "return use site rejects statically false predicate");
      Assert (Conversion.Status = PI.Predicate_Use_Legality_Missing_Check_At_Conversion,
              "conversion result must retain required dynamic predicate check");
      Assert (Aggregate.Status = PI.Predicate_Use_Legality_Invariant_Violation,
              "aggregate result enforces type invariant metadata");
      Assert (Call_Actual.Status = PI.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check,
              "call actual keeps dynamic predicate checks after overload resolution");
      Assert (PI.Predicate_Error_Count (Model) = 2,
              "static and unresolved predicate failures are counted");
      Assert (PI.Invariant_Error_Count (Model) = 1,
              "invariant violations are counted");
      Assert (PI.Missing_Check_Count (Model) = 1,
              "missing dynamic checks are counted by use site");
      Assert (PI.Count_Status (Model, PI.Predicate_Use_Legality_Cross_Unit_Unresolved_View) = 1,
              "cross-unit unresolved views block predicate use-site checking");
      Assert (PI.Fingerprint (Model) /= 0,
              "predicate/invariant use-site model has deterministic fingerprint");
   end Predicates_And_Invariants_Are_Use_Site_Enforced;

   procedure Lookups_Are_Bounded_And_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant PI.Predicate_Use_Legality_Model := Predicate_Model;
      Generic_Rows : constant PI.Predicate_Use_Result_Set :=
        PI.Rows_For_Kind (Model, PI.Predicate_Use_Generic_Actual);
      Subtype_Rows : constant PI.Predicate_Use_Result_Set :=
        PI.Rows_For_Subtype (Model, "balanced_record");
   begin
      Assert (PI.Result_Count (Generic_Rows) = 1,
              "generic actual predicate use site is searchable by kind");
      Assert (PI.Result_At (Generic_Rows, 1).Status =
              PI.Predicate_Use_Legality_Predicate_Unresolved,
              "generic actual unresolved predicates are preserved");
      Assert (PI.Result_Count (Subtype_Rows) = 1,
              "subtype lookup is normalized and deterministic");
      Assert (PI.Has_Legality (PI.Result_At (Subtype_Rows, 1)),
              "lookup result preserves row identity");
      Assert (PI.Legal_Count (Model) = 2,
              "legal static and dynamic use-site checks are counted");
      Assert (PI.Error_Count (Model) = 5,
              "all non-legal use-site checks are counted as errors/blockers");
   end Lookups_Are_Bounded_And_Deterministic;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Predicates_And_Invariants_Are_Use_Site_Enforced'Access,
         "Predicates and invariants are enforced at semantic use sites");
      Register_Routine
        (T, Lookups_Are_Bounded_And_Deterministic'Access,
         "Predicate/invariant use-site lookups remain deterministic and bounded");
   end Register_Tests;

end Test_Ada_Predicate_Invariant_Use_Site_Legality_Pass1124;
