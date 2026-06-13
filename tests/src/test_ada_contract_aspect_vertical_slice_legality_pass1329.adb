with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Contract_Aspect_Vertical_Slice_Legality;

package body Test_Ada_Contract_Aspect_Vertical_Slice_Legality_Pass1329 is

   package CAL renames Editor.Ada_Contract_Aspect_Vertical_Slice_Legality;
   use type CAL.Entity_Id;
   use type CAL.Type_Id;
   use type CAL.Aspect_Id;
   use type CAL.Result_Id;
   use type CAL.Subject_Kind;
   use type CAL.Type_Kind;
   use type CAL.View_Kind;
   use type CAL.Aspect_Kind;
   use type CAL.Global_Mode;
   use type CAL.Legality_Status;
   use type CAL.Subject_Info;
   use type CAL.Type_Info;
   use type CAL.Aspect_Info;
   use type CAL.Result_Info;
   use type CAL.Subject_Model;
   use type CAL.Type_Model;
   use type CAL.Aspect_Model;
   use type CAL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Contract_Aspect_Vertical_Slice_Legality_Pass1329");
   end Name;

   procedure Add_Type
     (Model : in out CAL.Type_Model;
      Id : Natural;
      Name_Text : String;
      Kind : CAL.Type_Kind;
      View : CAL.View_Kind := CAL.View_Full;
      Base : Natural := 0;
      Boolean_Flag : Boolean := False;
      Controlled_Component : Boolean := False;
      Task_Component : Boolean := False;
      Protected_Component : Boolean := False;
      Access_Component : Boolean := False;
      Predicate_Runtime : Boolean := False;
      Source_FP : Natural := 132900;
      Type_FP : Natural := 232900;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      T : CAL.Type_Info;
   begin
      T.Id := CAL.Type_Id (Id);
      T.Name := To_Unbounded_String (Name_Text);
      T.Node := Editor.Ada_Syntax_Tree.Node_Id (132900 + Id);
      T.Kind := Kind;
      T.View := View;
      T.Base_Type := CAL.Type_Id (Base);
      T.Is_Boolean := Boolean_Flag;
      T.Has_Controlled_Component := Controlled_Component;
      T.Has_Task_Component := Task_Component;
      T.Has_Protected_Component := Protected_Component;
      T.Has_Access_Component := Access_Component;
      T.Predicate_Runtime_Check := Predicate_Runtime;
      T.Source_Fingerprint := Source_FP + Id;
      T.Type_Fingerprint := Type_FP + Id;
      T.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      T.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      CAL.Add_Type (Model, T);
   end Add_Type;

   procedure Add_Subject
     (Model : in out CAL.Subject_Model;
      Id : Natural;
      Name_Text : String;
      Kind : CAL.Subject_Kind;
      Typ : Natural := 0;
      View : CAL.View_Kind := CAL.View_Full;
      Preelaborable : Boolean := True;
      Imported : Boolean := False;
      Body_Present : Boolean := True;
      Abstract_State : Boolean := False;
      Refinement : Boolean := False;
      May_Return : Boolean := True;
      Convention_OK : Boolean := True;
      Global : CAL.Global_Mode := CAL.Global_Unspecified;
      Source_FP : Natural := 332900;
      Type_FP : Natural := 432900;
      Profile_FP : Natural := 532900;
      State_FP : Natural := 632900;
      Effect_FP : Natural := 732900;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_State_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      S : CAL.Subject_Info;
   begin
      S.Id := CAL.Entity_Id (Id);
      S.Name := To_Unbounded_String (Name_Text);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (232900 + Id);
      S.Kind := Kind;
      S.Typ := CAL.Type_Id (Typ);
      S.View := View;
      S.Is_Preelaborable := Preelaborable;
      S.Is_Imported := Imported;
      S.Has_Body := Body_Present;
      S.Has_Abstract_State := Abstract_State;
      S.Has_Refinement := Refinement;
      S.Callable_May_Return := May_Return;
      S.Profile_Convention_OK := Convention_OK;
      S.Global_Mode := Global;
      S.Source_Fingerprint := Source_FP + Id;
      S.Type_Fingerprint := Type_FP + Id;
      S.Profile_Fingerprint := Profile_FP + Id;
      S.State_Fingerprint := State_FP + Id;
      S.Effect_Fingerprint := Effect_FP + Id;
      S.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      S.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      S.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      S.Expected_State_Fingerprint :=
        (if Expected_State_FP = 0 then State_FP + Id else Expected_State_FP);
      S.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      CAL.Add_Subject (Model, S);
   end Add_Subject;

   procedure Add_Aspect
     (Model : in out CAL.Aspect_Model;
      Id : Natural;
      Name_Text : String;
      Kind : CAL.Aspect_Kind;
      Target : Natural := 0;
      Expr_Type : Natural := 0;
      State_Target : Natural := 0;
      State_Source : Natural := 0;
      Constituent : Natural := 0;
      Required_Global : CAL.Global_Mode := CAL.Global_Unspecified;
      Actual_Global : CAL.Global_Mode := CAL.Global_Unspecified;
      Static_Expr : Boolean := True;
      Boolean_OK : Boolean := True;
      Depends_Target_Present : Boolean := True;
      Depends_Source_Present : Boolean := True;
      Cycle : Boolean := False;
      Has_Abstract_State : Boolean := True;
      Constituent_Present : Boolean := True;
      Extra_Constituent : Boolean := False;
      Mode_OK : Boolean := True;
      Preelab_OK : Boolean := True;
      No_Return_OK : Boolean := True;
      Fallthrough : Boolean := False;
      Convention_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Source_FP : Natural := 832900;
      AST_FP : Natural := 932900;
      Type_FP : Natural := 142900;
      Profile_FP : Natural := 242900;
      State_FP : Natural := 342900;
      Effect_FP : Natural := 442900;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_State_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0)
   is
      A : CAL.Aspect_Info;
   begin
      A.Id := CAL.Aspect_Id (Id);
      A.Name := To_Unbounded_String (Name_Text);
      A.Node := Editor.Ada_Syntax_Tree.Node_Id (332900 + Id);
      A.Kind := Kind;
      A.Target := CAL.Entity_Id (Target);
      A.Expression_Type := CAL.Type_Id (Expr_Type);
      A.State_Target := CAL.Entity_Id (State_Target);
      A.State_Source := CAL.Entity_Id (State_Source);
      A.Constituent := CAL.Entity_Id (Constituent);
      A.Required_Global_Mode := Required_Global;
      A.Actual_Global_Mode := Actual_Global;
      A.Is_Static_Expression := Static_Expr;
      A.Boolean_Expression_OK := Boolean_OK;
      A.Depends_Target_Present := Depends_Target_Present;
      A.Depends_Source_Present := Depends_Source_Present;
      A.Depends_Cycle := Cycle;
      A.Refinement_Has_Abstract_State := Has_Abstract_State;
      A.Constituent_Present := Constituent_Present;
      A.Extra_Constituent := Extra_Constituent;
      A.Constituent_Mode_OK := Mode_OK;
      A.Preelaborable_Init_OK := Preelab_OK;
      A.No_Return_Target_OK := No_Return_OK;
      A.No_Return_Fallthrough := Fallthrough;
      A.Convention_Profile_OK := Convention_OK;
      A.Runtime_Check_Required := Runtime_Check;
      A.Source_Fingerprint := Source_FP + Id;
      A.AST_Fingerprint := AST_FP + Id;
      A.Type_Fingerprint := Type_FP + Id;
      A.Profile_Fingerprint := Profile_FP + Id;
      A.State_Fingerprint := State_FP + Id;
      A.Effect_Fingerprint := Effect_FP + Id;
      A.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      A.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      A.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      A.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      A.Expected_State_Fingerprint :=
        (if Expected_State_FP = 0 then State_FP + Id else Expected_State_FP);
      A.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      CAL.Add_Aspect (Model, A);
   end Add_Aspect;

   procedure Test_Pre_Post_And_Boolean_Contracts

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Subjects : CAL.Subject_Model;
      Types : CAL.Type_Model;
      Aspects : CAL.Aspect_Model;
      Results : CAL.Result_Model;
   begin
      Add_Type (Types, 1, "Boolean", CAL.Type_Boolean, Boolean_Flag => True);
      Add_Type (Types, 2, "Integer", CAL.Type_Scalar);
      Add_Subject (Subjects, 1, "P", CAL.Subject_Procedure);
      Add_Aspect (Aspects, 1, "with Pre => X > 0", CAL.Aspect_Pre,
                  Target => 1, Expr_Type => 1, Runtime_Check => True);
      Add_Aspect (Aspects, 2, "with Post => 42", CAL.Aspect_Post,
                  Target => 1, Expr_Type => 2);
      Results := CAL.Build (Subjects, Types, Aspects);
      Assert (CAL.Result_At (Results, 1).Status = CAL.Legality_Legal_With_Runtime_Check,
              "Pre aspect with Boolean expression is legal with runtime assertion check");
      Assert (CAL.Result_At (Results, 2).Status = CAL.Legality_Boolean_Expression_Required,
              "Post aspect expression must resolve to Boolean");
   end Test_Pre_Post_And_Boolean_Contracts;

   procedure Test_Predicates_Invariants_And_Preelaboration

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Subjects : CAL.Subject_Model;
      Types : CAL.Type_Model;
      Aspects : CAL.Aspect_Model;
      Results : CAL.Result_Model;
   begin
      Add_Type (Types, 1, "Boolean", CAL.Type_Boolean, Boolean_Flag => True);
      Add_Type (Types, 2, "Controlled_Record", CAL.Type_Record,
                Controlled_Component => True);
      Add_Subject (Subjects, 1, "T", CAL.Subject_Type, Typ => 2);
      Add_Aspect (Aspects, 1, "Static_Predicate", CAL.Aspect_Static_Predicate,
                  Target => 1, Expr_Type => 1, Static_Expr => False);
      Add_Aspect (Aspects, 2, "Preelaborable_Initialization",
                  CAL.Aspect_Preelaborable_Initialization,
                  Target => 1);
      Results := CAL.Build (Subjects, Types, Aspects);
      Assert (CAL.Result_At (Results, 1).Status = CAL.Legality_Static_Expression_Required,
              "Static_Predicate requires a static Boolean expression");
      Assert (CAL.Result_At (Results, 2).Status =
                CAL.Legality_Preelaborable_Initialization_Blocker,
              "controlled/task/protected/access components block preelaborable initialization");
   end Test_Predicates_Invariants_And_Preelaboration;

   procedure Test_Global_Depends_And_Refinement

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Subjects : CAL.Subject_Model;
      Types : CAL.Type_Model;
      Aspects : CAL.Aspect_Model;
      Results : CAL.Result_Model;
   begin
      Add_Type (Types, 1, "Boolean", CAL.Type_Boolean, Boolean_Flag => True);
      Add_Subject (Subjects, 1, "Update", CAL.Subject_Procedure,
                   Global => CAL.Global_In);
      Add_Subject (Subjects, 2, "State", CAL.Subject_Abstract_State);
      Add_Subject (Subjects, 3, "Input", CAL.Subject_Object);
      Add_Aspect (Aspects, 1, "Global => null", CAL.Aspect_Global,
                  Target => 1,
                  Required_Global => CAL.Global_Null,
                  Actual_Global => CAL.Global_In_Out);
      Add_Aspect (Aspects, 2, "Depends => (State => Input)", CAL.Aspect_Depends,
                  Target => 1, State_Target => 2, State_Source => 3);
      Add_Aspect (Aspects, 3, "Refined_Depends", CAL.Aspect_Refined_Depends,
                  Target => 1, State_Target => 2, State_Source => 3,
                  Has_Abstract_State => False);
      Results := CAL.Build (Subjects, Types, Aspects);
      Assert (CAL.Result_At (Results, 1).Status = CAL.Legality_Global_Mode_Mismatch,
              "Global aspect modes must be compatible with subject effects");
      Assert (CAL.Result_At (Results, 2).Status = CAL.Legality_Legal,
              "Depends with present target/source state is legal");
      Assert (CAL.Result_At (Results, 3).Status =
                CAL.Legality_Refinement_Without_Abstract_State,
              "Refined_Depends requires abstract-state evidence");
   end Test_Global_Depends_And_Refinement;

   procedure Test_Refined_State_Constituents

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Subjects : CAL.Subject_Model;
      Types : CAL.Type_Model;
      Aspects : CAL.Aspect_Model;
      Results : CAL.Result_Model;
   begin
      Add_Subject (Subjects, 1, "Pkg", CAL.Subject_Package,
                   Abstract_State => True);
      Add_Subject (Subjects, 2, "Hidden_State", CAL.Subject_Object);
      Add_Aspect (Aspects, 1, "Refined_State", CAL.Aspect_Refined_State,
                  Target => 1, Constituent => 2);
      Add_Aspect (Aspects, 2, "Refined_State extra", CAL.Aspect_Refined_State,
                  Target => 1, Constituent => 2, Extra_Constituent => True);
      Add_Aspect (Aspects, 3, "Refined_State mode", CAL.Aspect_Refined_State,
                  Target => 1, Constituent => 2, Mode_OK => False);
      Results := CAL.Build (Subjects, Types, Aspects);
      Assert (CAL.Result_At (Results, 1).Status = CAL.Legality_Legal,
              "Refined_State accepts a present constituent for an abstract state");
      Assert (CAL.Result_At (Results, 2).Status =
                CAL.Legality_Refinement_Extra_Constituent,
              "extra refined-state constituents are rejected");
      Assert (CAL.Result_At (Results, 3).Status =
                CAL.Legality_Refinement_Mode_Mismatch,
              "refined-state constituent modes must match abstract state contract");
   end Test_Refined_State_Constituents;

   procedure Test_No_Return_Inline_Convention

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Subjects : CAL.Subject_Model;
      Types : CAL.Type_Model;
      Aspects : CAL.Aspect_Model;
      Results : CAL.Result_Model;
   begin
      Add_Subject (Subjects, 1, "Stop", CAL.Subject_Procedure,
                   May_Return => False);
      Add_Subject (Subjects, 2, "F", CAL.Subject_Function,
                   May_Return => False);
      Add_Subject (Subjects, 3, "C_P", CAL.Subject_Procedure,
                   Convention_OK => False);
      Add_Aspect (Aspects, 1, "No_Return", CAL.Aspect_No_Return,
                  Target => 1);
      Add_Aspect (Aspects, 2, "No_Return on function", CAL.Aspect_No_Return,
                  Target => 2, No_Return_OK => True);
      Add_Aspect (Aspects, 3, "Convention => C", CAL.Aspect_Convention,
                  Target => 3);
      Results := CAL.Build (Subjects, Types, Aspects);
      Assert (CAL.Result_At (Results, 1).Status = CAL.Legality_Legal,
              "No_Return accepts non-returning procedures");
      Assert (CAL.Result_At (Results, 2).Status = CAL.Legality_No_Return_Target_Invalid,
              "No_Return is not valid for functions");
      Assert (CAL.Result_At (Results, 3).Status = CAL.Legality_Convention_Profile_Mismatch,
              "Convention requires compatible callable profile evidence");
   end Test_No_Return_Inline_Convention;

   procedure Test_View_And_Fingerprint_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Subjects : CAL.Subject_Model;
      Types : CAL.Type_Model;
      Aspects : CAL.Aspect_Model;
      Results : CAL.Result_Model;
   begin
      Add_Type (Types, 1, "Boolean", CAL.Type_Boolean,
                View => CAL.View_Private, Boolean_Flag => True);
      Add_Subject (Subjects, 1, "P", CAL.Subject_Procedure);
      Add_Aspect (Aspects, 1, "Pre stale", CAL.Aspect_Pre,
                  Target => 1, Expr_Type => 1, Expected_AST_FP => 99);
      Results := CAL.Build (Subjects, Types, Aspects);
      Assert (CAL.Result_At (Results, 1).Status = CAL.Legality_Multiple_Blockers,
              "private view and stale AST fingerprint are both preserved");
      Assert (CAL.Result_At (Results, 1).Private_View_Blockers = 1,
              "private view blocker recorded");
      Assert (CAL.Result_At (Results, 1).AST_Fingerprint_Blockers = 1,
              "stale AST fingerprint blocker recorded");
   end Test_View_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Pre_Post_And_Boolean_Contracts'Access,
         "Pre/Post Boolean contract legality");
      Register_Routine
        (T, Test_Predicates_Invariants_And_Preelaboration'Access,
         "predicate invariant and preelaboration legality");
      Register_Routine
        (T, Test_Global_Depends_And_Refinement'Access,
         "Global Depends and refinement legality");
      Register_Routine
        (T, Test_Refined_State_Constituents'Access,
         "Refined_State constituent legality");
      Register_Routine
        (T, Test_No_Return_Inline_Convention'Access,
         "No_Return Inline and Convention legality");
      Register_Routine
        (T, Test_View_And_Fingerprint_Blockers'Access,
         "view barriers and stale fingerprints");
   end Register_Tests;

end Test_Ada_Contract_Aspect_Vertical_Slice_Legality_Pass1329;
