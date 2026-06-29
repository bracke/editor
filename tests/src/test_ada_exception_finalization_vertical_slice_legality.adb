with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Exception_Finalization_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Exception_Finalization_Vertical_Slice_Legality is

   package EF renames Editor.Ada_Exception_Finalization_Vertical_Slice_Legality;
   use type EF.Event_Id;
   use type EF.Result_Id;
   use type EF.Event_Kind;
   use type EF.Entity_Kind;
   use type EF.Type_Class;
   use type EF.Propagation_Mode;
   use type EF.Legality_Status;
   use type EF.Event_Info;
   use type EF.Result_Info;
   use type EF.Event_Model;
   use type EF.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Exception_Finalization_Vertical_Slice_Legality");
   end Name;

   procedure Add_Event
     (Model : in out EF.Event_Model;
      Id    : Natural;
      Kind  : EF.Event_Kind;
      Text  : String;
      AST : Boolean := True;
      Context : Boolean := True;
      Has_Exception : Boolean := True;
      Exception_Visible : Boolean := True;
      Expected_Exception_Kind : EF.Entity_Kind := EF.Entity_Exception;
      Actual_Exception_Kind : EF.Entity_Kind := EF.Entity_Exception;
      Exception_Type : EF.Type_Class := EF.Type_Exception;
      Handler_Present : Boolean := True;
      Handler_Duplicate : Boolean := False;
      Handler_Reachable : Boolean := True;
      In_Handler : Boolean := False;
      Propagation : EF.Propagation_Mode := EF.Propagation_None;
      Requires_Handler : Boolean := False;
      Has_Finalize : Boolean := True;
      Final_Order_OK : Boolean := True;
      Adjust_Finalize_OK : Boolean := True;
      Limited_Finalization_OK : Boolean := True;
      Abort_Finalization_OK : Boolean := True;
      Task_Termination_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Renaming_OK : Boolean := True;
      Shared_State_OK : Boolean := True;
      Representation_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Elaboration_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Source_FP : Natural := 131000;
      AST_FP : Natural := 231000;
      Effect_FP : Natural := 331000;
      Subst_FP : Natural := 431000;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0)
   is
      E : EF.Event_Info;
   begin
      E.Id := EF.Event_Id (Id);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (131000 + Id);
      E.Kind := Kind;
      E.Source_Name := To_Unbounded_String (Text);
      E.Has_AST_Coverage := AST;
      E.Has_Context := Context;
      E.Has_Exception_Entity := Has_Exception;
      E.Exception_Visible := Exception_Visible;
      E.Expected_Exception_Kind := Expected_Exception_Kind;
      E.Actual_Exception_Kind := Actual_Exception_Kind;
      E.Exception_Type := Exception_Type;
      E.Handler_Choice_Present := Handler_Present;
      E.Handler_Choice_Duplicate := Handler_Duplicate;
      E.Handler_Choice_Reachable := Handler_Reachable;
      E.In_Exception_Handler := In_Handler;
      E.Propagation := Propagation;
      E.Requires_Local_Handler := Requires_Handler;
      E.Has_Finalization_Procedure := Has_Finalize;
      E.Finalization_Order_Legal := Final_Order_OK;
      E.Adjust_Finalize_Profile_Matches := Adjust_Finalize_OK;
      E.Limited_Finalization_Legal := Limited_Finalization_OK;
      E.Abort_Finalization_Safe := Abort_Finalization_OK;
      E.Task_Termination_Finalization_Legal := Task_Termination_OK;
      E.Accessibility_Legal := Accessibility_OK;
      E.Renaming_Legal := Renaming_OK;
      E.Shared_State_Legal := Shared_State_OK;
      E.Representation_Legal := Representation_OK;
      E.Predicate_Legal := Predicate_OK;
      E.Elaboration_Legal := Elaboration_OK;
      E.Runtime_Check_Required := Runtime_Check;
      E.Source_Fingerprint := Source_FP + Id;
      E.AST_Fingerprint := AST_FP + Id;
      E.Effect_Fingerprint := Effect_FP + Id;
      E.Substitution_Fingerprint := Subst_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      E.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Effect_FP + Id else Expected_Effect_FP);
      E.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      EF.Add_Event (Model, E);
   end Add_Event;

   procedure Accepts_Source_Shaped_Exception_And_Finalization_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : EF.Event_Model;
      Results : EF.Result_Model;
   begin
      Add_Event (Model, 1, EF.Event_Raise_Statement,
                 "raise Constraint_Error",
                 Propagation => EF.Propagation_Handled_Locally);
      Add_Event (Model, 2, EF.Event_Exception_Handler,
                 "when Constraint_Error => Recover",
                 Handler_Present => True,
                 Handler_Reachable => True);
      Add_Event (Model, 3, EF.Event_Controlled_Object_Finalization,
                 "Finalize controlled object on scope exit",
                 Has_Finalize => True,
                 Final_Order_OK => True,
                 Adjust_Finalize_OK => True);
      Add_Event (Model, 4, EF.Event_Task_Termination_Finalization,
                 "Finalize task object during termination",
                 Task_Termination_OK => True);
      Add_Event (Model, 5, EF.Event_Raise_Expression,
                 "raise Program_Error with runtime predicate evidence",
                 Propagation => EF.Propagation_Handled_Locally,
                 Runtime_Check => True);

      Results := EF.Build (Model);

      Assert (EF.Result_Count (Results) = 5, "expected five event rows");
      Assert (EF.Count_Status (Results, EF.Legality_Legal) = 4,
              "source-shaped exception/finalization rows should be legal");
      Assert (EF.Count_Status (Results, EF.Legality_Legal_With_Runtime_Check) = 1,
              "runtime predicate evidence should preserve legal-with-check");
      Assert (EF.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Source_Shaped_Exception_And_Finalization_Cases;

   procedure Rejects_Exception_And_Handler_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : EF.Event_Model;
      Results : EF.Result_Model;
   begin
      Add_Event (Model, 1, EF.Event_Raise_Statement,
                 "raise Missing_Exception", Has_Exception => False);
      Add_Event (Model, 2, EF.Event_Raise_Statement,
                 "raise Hidden.E", Exception_Visible => False);
      Add_Event (Model, 3, EF.Event_Raise_Statement,
                 "raise Not_An_Exception", Actual_Exception_Kind => EF.Entity_Object);
      Add_Event (Model, 4, EF.Event_Exception_Handler,
                 "when => Recover", Handler_Present => False);
      Add_Event (Model, 5, EF.Event_Exception_Handler,
                 "when E | E => Recover", Handler_Duplicate => True);
      Add_Event (Model, 6, EF.Event_Exception_Handler,
                 "when Already_Covered => Recover", Handler_Reachable => False);
      Add_Event (Model, 7, EF.Event_Exception_Propagation,
                 "unhandled exception escapes local protected action",
                 Propagation => EF.Propagation_Propagates,
                 Requires_Handler => True);
      Add_Event (Model, 8, EF.Event_Exception_Propagation,
                 "raise; outside handler",
                 Propagation => EF.Propagation_Reraises,
                 In_Handler => False);

      Results := EF.Build (Model);

      Assert (EF.Count_Status (Results, EF.Legality_Exception_Missing) = 1,
              "missing exception entity should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Exception_Not_Visible) = 1,
              "invisible exception should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Exception_Kind_Mismatch) = 1,
              "wrong exception kind should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Handler_Choice_Missing) = 1,
              "missing handler choice should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Handler_Choice_Duplicate) = 1,
              "duplicate handler choice should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Handler_Choice_Unreachable) = 1,
              "unreachable handler choice should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Propagation_Unhandled) = 1,
              "required local handler should block propagation");
      Assert (EF.Count_Status (Results, EF.Legality_Reraise_Outside_Handler) = 1,
              "reraise outside a handler should be rejected");
   end Rejects_Exception_And_Handler_Errors;

   procedure Rejects_Finalization_Lifetime_And_Effect_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : EF.Event_Model;
      Results : EF.Result_Model;
   begin
      Add_Event (Model, 1, EF.Event_Controlled_Object_Finalization,
                 "missing Finalize primitive", Has_Finalize => False);
      Add_Event (Model, 2, EF.Event_Controlled_Object_Finalization,
                 "wrong finalization order", Final_Order_OK => False);
      Add_Event (Model, 3, EF.Event_Controlled_Object_Finalization,
                 "Adjust/Finalize profile mismatch", Adjust_Finalize_OK => False);
      Add_Event (Model, 4, EF.Event_Limited_Controlled_Finalization,
                 "illegal limited finalization", Limited_Finalization_OK => False);
      Add_Event (Model, 5, EF.Event_Abort_Finalization,
                 "unsafe finalization during abort", Abort_Finalization_OK => False);
      Add_Event (Model, 6, EF.Event_Task_Termination_Finalization,
                 "blocked task termination finalization", Task_Termination_OK => False);
      Add_Event (Model, 7, EF.Event_Controlled_Object_Finalization,
                 "access value outlives finalized object", Accessibility_OK => False);
      Add_Event (Model, 8, EF.Event_Exception_Renaming,
                 "renamed exception target blocked", Renaming_OK => False);
      Add_Event (Model, 9, EF.Event_Controlled_Object_Finalization,
                 "shared-state finalization blocked", Shared_State_OK => False);
      Add_Event (Model, 10, EF.Event_Controlled_Object_Finalization,
                 "representation-sensitive finalization blocked", Representation_OK => False);

      Results := EF.Build (Model);

      Assert (EF.Count_Status (Results, EF.Legality_Finalization_Missing) = 1,
              "missing finalization primitive should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Finalization_Order_Mismatch) = 1,
              "wrong finalization order should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Controlled_Adjust_Finalize_Mismatch) = 1,
              "Adjust/Finalize mismatch should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Limited_Finalization_Blocked) = 1,
              "limited finalization blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Abort_Finalization_Unsafe) = 1,
              "unsafe abort finalization should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Task_Termination_Finalization_Blocked) = 1,
              "task termination finalization blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Accessibility_Blocked) = 1,
              "accessibility blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Renaming_Blocked) = 1,
              "renaming blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Shared_State_Blocked) = 1,
              "shared-state blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Representation_Blocked) = 1,
              "representation blocker should be preserved");
   end Rejects_Finalization_Lifetime_And_Effect_Errors;

   procedure Rejects_Context_And_Fingerprint_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : EF.Event_Model;
      Results : EF.Result_Model;
   begin
      Add_Event (Model, 1, EF.Event_Raise_Statement,
                 "token-only raise statement", AST => False);
      Add_Event (Model, 2, EF.Event_Exception_Handler,
                 "handler without enclosing context", Context => False);
      Add_Event (Model, 3, EF.Event_Raise_Expression,
                 "predicate blocked raise expression", Predicate_OK => False);
      Add_Event (Model, 4, EF.Event_Raise_Statement,
                 "elaboration blocked exception raise", Elaboration_OK => False);
      Add_Event (Model, 5, EF.Event_Raise_Statement,
                 "stale source", Expected_Source_FP => 1);
      Add_Event (Model, 6, EF.Event_Exception_Handler,
                 "stale AST", Expected_AST_FP => 1);
      Add_Event (Model, 7, EF.Event_Controlled_Object_Finalization,
                 "stale effect graph", Expected_Effect_FP => 1);
      Add_Event (Model, 8, EF.Event_Exception_Renaming,
                 "stale generic substitution", Expected_Subst_FP => 1);
      Add_Event (Model, 9, EF.Event_Controlled_Object_Finalization,
                 "multiple blockers", AST => False, Accessibility_OK => False);

      Results := EF.Build (Model);

      Assert (EF.Count_Status (Results, EF.Legality_Missing_AST_Coverage) = 1,
              "missing AST coverage should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Missing_Context) = 1,
              "missing context should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Predicate_Blocked) = 1,
              "predicate blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Elaboration_Blocked) = 1,
              "elaboration blocker should be preserved");
      Assert (EF.Count_Status (Results, EF.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Effect_Fingerprint_Mismatch) = 1,
              "effect fingerprint mismatch should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Substitution_Fingerprint_Mismatch) = 1,
              "substitution fingerprint mismatch should be rejected");
      Assert (EF.Count_Status (Results, EF.Legality_Multiple_Blockers) = 1,
              "multiple blocker identity should be preserved");
   end Rejects_Context_And_Fingerprint_Errors;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Accepts_Source_Shaped_Exception_And_Finalization_Cases'Access,
                        "accepts source-shaped exception and finalization cases");
      Register_Routine (T, Rejects_Exception_And_Handler_Errors'Access,
                        "rejects exception and handler errors");
      Register_Routine (T, Rejects_Finalization_Lifetime_And_Effect_Errors'Access,
                        "rejects finalization lifetime and effect errors");
      Register_Routine (T, Rejects_Context_And_Fingerprint_Errors'Access,
                        "rejects context and fingerprint errors");
   end Register_Tests;

end Test_Ada_Exception_Finalization_Vertical_Slice_Legality;
