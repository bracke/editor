with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Lifetime_Vertical_Slice_Legality_Pass1300 is

   package AL renames Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality;
   use type AL.Scope_Id;
   use type AL.Entity_Id;
   use type AL.Flow_Id;
   use type AL.Result_Id;
   use type AL.Scope_Kind;
   use type AL.Entity_Kind;
   use type AL.Operation_Kind;
   use type AL.Accessibility_Status;
   use type AL.Scope_Info;
   use type AL.Entity_Info;
   use type AL.Flow_Info;
   use type AL.Result_Info;
   use type AL.Scope_Model;
   use type AL.Entity_Model;
   use type AL.Flow_Model;
   use type AL.Result_Model;

   use type AL.Scope_Kind;
   use type AL.Entity_Kind;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Accessibility_Lifetime_Vertical_Slice_Legality_Pass1300");
   end Name;

   procedure Add_Scope
     (Scopes : in out AL.Scope_Model;
      Id     : Natural;
      Kind   : AL.Scope_Kind;
      Level  : Natural;
      Parent : Natural := 0;
      Name   : String := "S";
      Fingerprint : Natural := 1300)
   is
      S : AL.Scope_Info;
   begin
      S.Id := AL.Scope_Id (Id);
      S.Parent := AL.Scope_Id (Parent);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (130000 + Id);
      S.Kind := Kind;
      S.Name := To_Unbounded_String (Name);
      S.Master_Level := Level;
      S.Is_Library_Level := Level = 0;
      S.Is_Generic_Template := Kind = AL.Scope_Generic_Template;
      S.Is_Generic_Instance := Kind = AL.Scope_Generic_Instance;
      S.Source_Fingerprint := Fingerprint + Id;
      AL.Add_Scope (Scopes, S);
   end Add_Scope;

   procedure Add_Entity
     (Entities : in out AL.Entity_Model;
      Id       : Natural;
      Scope    : Natural;
      Kind     : AL.Entity_Kind;
      Level    : Natural;
      Name     : String := "E";
      Access_Subprogram : Boolean := False;
      Generic_Formal : Boolean := False;
      From_Renaming : Boolean := False;
      Discriminant : Boolean := False;
      Protected_Task : Boolean := False;
      Finalized : Boolean := False;
      Source_FP : Natural := 2100;
      Profile_FP : Natural := 3100;
      Subst_FP : Natural := 4100)
   is
      E : AL.Entity_Info;
   begin
      E.Id := AL.Entity_Id (Id);
      E.Scope := AL.Scope_Id (Scope);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (130100 + Id);
      E.Kind := Kind;
      E.Name := To_Unbounded_String (Name);
      E.Master_Level := Level;
      E.Is_Aliased := True;
      E.Is_Anonymous_Access := Kind = AL.Entity_Anonymous_Access;
      E.Is_Access_To_Subprogram := Access_Subprogram
        or else Kind = AL.Entity_Access_Subprogram;
      E.Is_Generic_Formal := Generic_Formal;
      E.Is_From_Renaming := From_Renaming;
      E.Is_Discriminant_Dependent := Discriminant;
      E.Is_Protected_Or_Task_State := Protected_Task;
      E.Has_Controlled_Finalization := Finalized;
      E.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Id);
      E.Profile_Fingerprint := (if Profile_FP = 0 then 0 else Profile_FP + Id);
      E.Substitution_Fingerprint := (if Subst_FP = 0 then 0 else Subst_FP + Id);
      AL.Add_Entity (Entities, E);
   end Add_Entity;

   procedure Add_Flow
     (Flows : in out AL.Flow_Model;
      Id    : Natural;
      Source : Natural;
      Target : Natural;
      Op     : AL.Operation_Kind;
      Runtime_Check : Boolean := False;
      Access_Profile : Boolean := False;
      Generic_Instance : Boolean := False;
      Renaming : Boolean := False;
      Discriminant : Boolean := False;
      Aggregate : Boolean := False;
      Return_Object : Boolean := False;
      Protected_Task : Boolean := False;
      Source_FP : Natural := 2100;
      Target_FP : Natural := 2100;
      Profile_FP : Natural := 3100;
      Subst_FP : Natural := 4100;
      Flow_FP : Natural := 5100)
   is
      F : AL.Flow_Info;
   begin
      F.Id := AL.Flow_Id (Id);
      F.Source := AL.Entity_Id (Source);
      F.Target := AL.Entity_Id (Target);
      F.Node := Editor.Ada_Syntax_Tree.Node_Id (130200 + Id);
      F.Operation := Op;
      F.Allows_Runtime_Accessibility_Check := Runtime_Check;
      F.Requires_Access_To_Subprogram_Profile := Access_Profile;
      F.In_Generic_Instance := Generic_Instance;
      F.Through_Renaming := Renaming;
      F.Through_Discriminant := Discriminant;
      F.Through_Aggregate := Aggregate;
      F.Through_Return_Object := Return_Object;
      F.Through_Protected_Or_Task_State := Protected_Task;
      F.Expected_Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Source);
      F.Expected_Target_Fingerprint := (if Target_FP = 0 then 0 else Target_FP + Target);
      F.Expected_Profile_Fingerprint := (if Profile_FP = 0 then 0 else Profile_FP + Source);
      F.Expected_Substitution_Fingerprint := (if Subst_FP = 0 then 0 else Subst_FP + Source);
      F.Source_Fingerprint := (if Source_FP = 0 then 0 else Source_FP + Source);
      F.Flow_Fingerprint := (if Flow_FP = 0 then 0 else Flow_FP + Id);
      AL.Add_Flow (Flows, F);
   end Add_Flow;

   procedure Accepts_Static_Runtime_Profile_And_Generic_Flows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Scopes : AL.Scope_Model;
      Entities : AL.Entity_Model;
      Flows : AL.Flow_Model;
   begin
      Add_Scope (Scopes, 1, AL.Scope_Library, 0, Name => "Library");
      Add_Scope (Scopes, 2, AL.Scope_Subprogram, 2, Parent => 1, Name => "P");
      Add_Scope (Scopes, 3, AL.Scope_Generic_Instance, 2, Parent => 1, Name => "G_I");

      --  Library-level aliased object stored in a local access object is statically safe.
      Add_Entity (Entities, 1, 1, AL.Entity_Object, 0, Name => "Global_Obj");
      Add_Entity (Entities, 2, 2, AL.Entity_Access_Object, 2, Name => "Local_Access");
      Add_Flow (Flows, 1, 1, 2, AL.Operation_Assignment);

      --  Anonymous access conversion requiring a dynamic accessibility check.
      Add_Entity (Entities, 3, 2, AL.Entity_Anonymous_Access, 3, Name => "Anon_Source");
      Add_Entity (Entities, 4, 1, AL.Entity_Access_Object, 0, Name => "Access_Param");
      Add_Flow (Flows, 2, 3, 4, AL.Operation_Assignment,
                Runtime_Check => True);

      --  Access-to-subprogram values with matching profile fingerprints.
      Add_Entity (Entities, 5, 1, AL.Entity_Access_Subprogram, 0,
                  Name => "Callback_A", Access_Subprogram => True,
                  Profile_FP => 9000);
      Add_Entity (Entities, 6, 1, AL.Entity_Access_Subprogram, 0,
                  Name => "Callback_B", Access_Subprogram => True,
                  Profile_FP => 8999);
      Add_Flow (Flows, 3, 5, 6, AL.Operation_Access_To_Subprogram,
                Access_Profile => True, Profile_FP => 9000);

      --  Generic formal object substitution with matching freshness evidence.
      Add_Entity (Entities, 7, 3, AL.Entity_Generic_Formal_Object, 2,
                  Name => "Formal_Obj", Generic_Formal => True,
                  Subst_FP => 7000);
      Add_Entity (Entities, 8, 3, AL.Entity_Access_Object, 2,
                  Name => "Formal_Target", Generic_Formal => True,
                  Subst_FP => 6999);
      Add_Flow (Flows, 4, 7, 8, AL.Operation_Generic_Actual,
                Generic_Instance => True, Subst_FP => 7000);

      declare
         Model : constant AL.Result_Model := AL.Build (Scopes, Entities, Flows);
      begin
         Assert (AL.Result_Count (Model) = 4,
                 "each concrete access flow should produce one result");
         Assert (AL.Count_Status (Model, AL.Accessibility_Legal_Static_Master) = 1,
                 "longer-lived source assigned to local target should be statically legal");
         Assert (AL.Count_Status (Model, AL.Accessibility_Legal_Runtime_Check) = 1,
                 "runtime accessibility check should accept explicitly dynamic flow");
         Assert (AL.Count_Status (Model, AL.Accessibility_Legal_Access_To_Subprogram_Profile) = 1,
                 "matching access-to-subprogram profile should be accepted");
         Assert (AL.Count_Status (Model, AL.Accessibility_Legal_Generic_Substitution) = 1,
                 "matching generic substitution evidence should be accepted");
         Assert (AL.Legal_Count (Model) = 4,
                 "all safe accessibility vertical-slice flows should be legal");
      end;
   end Accepts_Static_Runtime_Profile_And_Generic_Flows;

   procedure Rejects_Escapes_Through_Returns_Assignments_Aggregates_And_Generics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Scopes : AL.Scope_Model;
      Entities : AL.Entity_Model;
      Flows : AL.Flow_Model;
   begin
      Add_Scope (Scopes, 1, AL.Scope_Library, 0, Name => "Library");
      Add_Scope (Scopes, 2, AL.Scope_Subprogram, 4, Parent => 1, Name => "Function_Body");
      Add_Scope (Scopes, 3, AL.Scope_Block, 5, Parent => 2, Name => "Inner_Block");
      Add_Scope (Scopes, 4, AL.Scope_Generic_Instance, 1, Parent => 1, Name => "Instance");
      Add_Scope (Scopes, 5, AL.Scope_Protected, 1, Parent => 1, Name => "Protected_State");

      Add_Entity (Entities, 1, 3, AL.Entity_Object, 5, Name => "Local_Obj");
      Add_Entity (Entities, 2, 1, AL.Entity_Function_Result, 0, Name => "Result_Access");
      Add_Flow (Flows, 1, 1, 2, AL.Operation_Return,
                Return_Object => True);

      Add_Entity (Entities, 3, 3, AL.Entity_Object, 5, Name => "Block_Obj");
      Add_Entity (Entities, 4, 1, AL.Entity_Access_Object, 0, Name => "Global_Access");
      Add_Flow (Flows, 2, 3, 4, AL.Operation_Assignment);

      Add_Entity (Entities, 5, 3, AL.Entity_Object, 5, Name => "Aggregate_Component_Obj");
      Add_Entity (Entities, 6, 1, AL.Entity_Access_Object, 0, Name => "Aggregate_Target");
      Add_Flow (Flows, 3, 5, 6, AL.Operation_Aggregate_Component,
                Aggregate => True);

      Add_Entity (Entities, 7, 2, AL.Entity_Generic_Formal_Object, 4,
                  Name => "Actual_Local", Generic_Formal => True,
                  Subst_FP => 6000);
      Add_Entity (Entities, 8, 4, AL.Entity_Access_Object, 1,
                  Name => "Formal_Global", Generic_Formal => True,
                  Subst_FP => 5999);
      Add_Flow (Flows, 4, 7, 8, AL.Operation_Generic_Actual,
                Generic_Instance => True, Subst_FP => 6000);

      Add_Entity (Entities, 9, 3, AL.Entity_Renaming, 5,
                  Name => "R", From_Renaming => True);
      Add_Entity (Entities, 10, 1, AL.Entity_Access_Object, 0, Name => "Renamed_Global");
      Add_Flow (Flows, 5, 9, 10, AL.Operation_Renaming,
                Renaming => True);

      Add_Entity (Entities, 11, 3, AL.Entity_Discriminant_Component, 5,
                  Name => "D", Discriminant => True);
      Add_Entity (Entities, 12, 1, AL.Entity_Access_Object, 0, Name => "Disc_Target");
      Add_Flow (Flows, 6, 11, 12, AL.Operation_Discriminant_Component,
                Discriminant => True);

      Add_Entity (Entities, 13, 3, AL.Entity_Object, 5, Name => "Task_Local");
      Add_Entity (Entities, 14, 5, AL.Entity_Protected_Task_State, 1,
                  Name => "Shared_State", Protected_Task => True);
      Add_Flow (Flows, 7, 13, 14, AL.Operation_Protected_Task_Shared_State,
                Protected_Task => True);

      declare
         Model : constant AL.Result_Model := AL.Build (Scopes, Entities, Flows);
      begin
         Assert (AL.Count_Status (Model, AL.Accessibility_Return_Escape) = 1,
                 "returning access to an inner object should be rejected");
         Assert (AL.Count_Status (Model, AL.Accessibility_Assignment_Escape) = 1,
                 "assignment into a longer-lived access object should be rejected");
         Assert (AL.Count_Status (Model, AL.Accessibility_Aggregate_Component_Escape) = 1,
                 "aggregate component retaining an inner access value should be rejected");
         Assert (AL.Count_Status (Model, AL.Accessibility_Generic_Actual_Escape) = 1,
                 "generic actual substitution should reject shorter-lived actuals");
         Assert (AL.Count_Status (Model, AL.Accessibility_Renaming_Escape) = 1,
                 "renaming-mediated access escape should be rejected");
         Assert (AL.Count_Status (Model, AL.Accessibility_Discriminant_Dependent_Escape) = 1,
                 "discriminant-dependent access escape should be explicit");
         Assert (AL.Count_Status (Model, AL.Accessibility_Protected_Task_State_Escape) = 1,
                 "protected/task shared state should block shorter-lived access values");
         Assert (AL.Error_Count (Model) = 7,
                 "all concrete accessibility escape blockers should be counted");
      end;
   end Rejects_Escapes_Through_Returns_Assignments_Aggregates_And_Generics;

   procedure Reports_Profile_Fingerprint_Missing_And_Deterministic_Empty_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Scopes : AL.Scope_Model;
      Entities : AL.Entity_Model;
      Flows : AL.Flow_Model;
   begin
      Add_Scope (Scopes, 1, AL.Scope_Library, 0, Name => "Library");
      Add_Entity (Entities, 1, 1, AL.Entity_Access_Subprogram, 0,
                  Access_Subprogram => True, Profile_FP => 8000);
      Add_Entity (Entities, 2, 1, AL.Entity_Access_Subprogram, 0,
                  Access_Subprogram => True, Profile_FP => 8100);
      Add_Flow (Flows, 1, 1, 2, AL.Operation_Access_To_Subprogram,
                Access_Profile => True, Profile_FP => 8000);

      Add_Entity (Entities, 3, 1, AL.Entity_Object, 0, Source_FP => 0);
      Add_Entity (Entities, 4, 1, AL.Entity_Access_Object, 0);
      Add_Flow (Flows, 2, 3, 4, AL.Operation_Assignment, Source_FP => 0);

      Add_Flow (Flows, 3, 99, 4, AL.Operation_Assignment);
      Add_Flow (Flows, 4, 4, 99, AL.Operation_Assignment);

      declare
         Model : constant AL.Result_Model := AL.Build (Scopes, Entities, Flows);
         Empty_Scopes : AL.Scope_Model;
         Empty_Entities : AL.Entity_Model;
         Empty_Flows : AL.Flow_Model;
         Empty_Model : constant AL.Result_Model :=
           AL.Build (Empty_Scopes, Empty_Entities, Empty_Flows);
      begin
         Assert (AL.Count_Status (Model, AL.Accessibility_Subprogram_Profile_Mismatch) = 1,
                 "access-to-subprogram profile mismatch should be reported");
         Assert (AL.Count_Status (Model, AL.Accessibility_Source_Fingerprint_Mismatch) = 1,
                 "stale or missing source fingerprint should block accessibility evidence");
         Assert (AL.Count_Status (Model, AL.Accessibility_Missing_Source) = 1,
                 "missing source entity should be explicit");
         Assert (AL.Count_Status (Model, AL.Accessibility_Missing_Target) = 1,
                 "missing target entity should be explicit");
         Assert (AL.Result_Count (Empty_Model) = 0,
                 "empty accessibility evidence should be deterministic");
         Assert (AL.Fingerprint (Empty_Model) = 0,
                 "empty accessibility result fingerprint should be stable");
      end;
   end Reports_Profile_Fingerprint_Missing_And_Deterministic_Empty_Input;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Static_Runtime_Profile_And_Generic_Flows'Access,
         "accepts concrete safe static/runtime/profile/generic access flows");
      Register_Routine
        (T, Rejects_Escapes_Through_Returns_Assignments_Aggregates_And_Generics'Access,
         "rejects concrete master escapes through Ada access contexts");
      Register_Routine
        (T, Reports_Profile_Fingerprint_Missing_And_Deterministic_Empty_Input'Access,
         "reports profile/fingerprint/missing evidence and deterministic empty input");
   end Register_Tests;

end Test_Ada_Accessibility_Lifetime_Vertical_Slice_Legality_Pass1300;
