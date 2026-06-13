with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446;

package body Test_Ada_Phase579_Legacy_Cleanup_Closure_Pass1446 is
   package Closure renames Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446;
   use type Closure.Cleanup_Item;
   use type Closure.Evidence_Status;
   use type Closure.Evidence_Class;
   use type Closure.Closure_Row;
   use type Closure.Closure_Input;
   use type Closure.Closure_Result;
   use type Closure.Closure_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Legacy_Cleanup_Closure_Pass1446");
   end Name;

   function Base_Row
     (Id : Natural;
      Item : Closure.Cleanup_Item;
      Name : String;
      Owner : String;
      Reason : String) return Closure.Closure_Row is
      Row : Closure.Closure_Row;
   begin
      Row.Id := Id;
      Row.Item := Item;
      Row.Name := To_Unbounded_String (Name);
      Row.Canonical_Owner := To_Unbounded_String (Owner);
      Row.Reason := To_Unbounded_String (Reason);
      Row.Blocker_Family :=
        To_Unbounded_String ("Phase579.LegacyCleanupClosure.Pass1446");
      Row.Has_Source := True;
      Row.Has_Test := True;
      Row.Has_Readme := True;
      Row.Has_Release_Document := True;
      Row.Has_Core_Suite_Registration := True;
      Row.Inventory_Classified := True;
      Row.Removed_Surface_References_Absent := True;
      Row.Reopened_Remaining_Gap_Absent := True;
      Row.Speculative_Cleanup_Absent := True;
      Row.Production_Surface_Canonical := True;
      Row.Source_Fingerprint := Id * 90 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.Test_Fingerprint := Id * 90 + 2;
      Row.Expected_Test_Fingerprint := Row.Test_Fingerprint;
      Row.Document_Fingerprint := Id * 90 + 3;
      Row.Expected_Document_Fingerprint := Row.Document_Fingerprint;
      Row.Cleanup_Fingerprint := Id * 90 + 4;
      Row.Expected_Cleanup_Fingerprint := Row.Cleanup_Fingerprint;
      return Row;
   end Base_Row;

   procedure Add_Clean_Closure (Input : in out Closure.Closure_Input) is
   begin
      Closure.Add_Row
        (Input,
         Base_Row
           (1, Closure.Item_Inventory,
            "legacy scaffold inventory",
            "Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440",
            "all remaining historical scaffolds are classified"));
      Closure.Add_Row
        (Input,
         Base_Row
           (2, Closure.Item_Removal,
            "legacy projection tower removal",
            "Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441",
            "obsolete projection tower sources and tests are removed"));
      Closure.Add_Row
        (Input,
         Base_Row
           (3, Closure.Item_API_Consolidation,
            "canonical API consolidation",
            "Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442",
            "production surfaces are canonical and legacy surfaces are not production APIs"));
      Closure.Add_Row
        (Input,
         Base_Row
           (4, Closure.Item_Core_Suite_Pruning,
            "Core_Suite pruning",
            "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
            "superseded legacy tests are removed from active suite registration"));
      Closure.Add_Row
        (Input,
         Base_Row
           (5, Closure.Item_Documentation_Cleanup,
            "documentation cleanup",
            "Editor.Ada_Phase579_Documentation_Cleanup_Pass1444",
            "canonical architecture map supersedes historical pass README guidance"));
      Closure.Add_Row
        (Input,
         Base_Row
           (6, Closure.Item_Dead_Code_Sweep,
            "final dead-code sweep",
            "Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445",
            "orphan off-suite legacy tests are removed and retained dependencies are justified"));
      Closure.Add_Row
        (Input,
         Base_Row
           (7, Closure.Item_Closure,
            "legacy cleanup closure",
            "Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446",
            "cleanup campaign has an explicit endpoint and no new speculative cleanup backlog"));
   end Add_Clean_Closure;

   procedure Assert_Status
     (Model : Closure.Closure_Model;
      Id : Natural;
      Expected : Closure.Evidence_Status;
      Message : String) is
      Result : constant Closure.Closure_Result := Closure.Result_For (Model, Id);
   begin
      Assert (Result.Status = Expected, Message);
   end Assert_Status;

   procedure Test_Legacy_Cleanup_Closure_Is_Complete

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Closure.Closure_Input;
      Model : Closure.Closure_Model;
   begin
      Add_Clean_Closure (Input);
      Model := Closure.Build (Input);

      Assert (Closure.Legacy_Cleanup_Closed (Model),
              "seven cleanup items should be closed");
      Assert (Closure.Ready_For_Next_Project_Phase (Model),
              "legacy cleanup closure should unblock the next project phase");
      Assert (Model.Total_Rows = 7, "closure ledger should be finite");
      Assert (Model.Accepted_Count = 7, "all closure rows should be accepted");
      Assert (Model.Rejected_Count = 0, "no closure row should be rejected");
      Assert (Model.Indeterminate_Count = 0,
              "no closure row should be indeterminate");
      Assert_Status
        (Model, 7, Closure.Status_Accepted,
         "pass1446 closure row should be accepted");
   end Test_Legacy_Cleanup_Closure_Is_Complete;

   procedure Test_Reopened_Or_Speculative_Cleanup_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Closure.Closure_Input;
      Row : Closure.Closure_Row;
      Model : Closure.Closure_Model;
   begin
      Row := Base_Row
        (10, Closure.Item_Closure,
         "reopened semantic gap",
         "Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446",
         "new Remaining_* work cannot be introduced by cleanup closure");
      Row.Reopened_Remaining_Gap_Absent := False;
      Closure.Add_Row (Input, Row);

      Row := Base_Row
        (11, Closure.Item_Closure,
         "speculative cleanup",
         "Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446",
         "new cleanup work must be based on inventory evidence");
      Row.Speculative_Cleanup_Absent := False;
      Closure.Add_Row (Input, Row);

      Row := Base_Row
        (12, Closure.Item_Removal,
         "removed surface reference",
         "Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441",
         "removed legacy surfaces cannot be reintroduced as dependencies");
      Row.Removed_Surface_References_Absent := False;
      Closure.Add_Row (Input, Row);

      Model := Closure.Build (Input);
      Assert_Status
        (Model, 10, Closure.Status_Rejected_Reopened_Remaining_Gap,
         "reopened Remaining_* gaps should be rejected");
      Assert_Status
        (Model, 11, Closure.Status_Rejected_Speculative_Cleanup,
         "speculative cleanup should be rejected");
      Assert_Status
        (Model, 12, Closure.Status_Rejected_Removed_Surface_Reference,
         "references to removed surfaces should be rejected");
      Assert (not Closure.Legacy_Cleanup_Closed (Model),
              "rejected rows cannot close the cleanup campaign");
   end Test_Reopened_Or_Speculative_Cleanup_Is_Rejected;

   procedure Test_Missing_Evidence_Or_Stale_Fingerprint_Is_Rejected

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Closure.Closure_Input;
      Row : Closure.Closure_Row;
      Model : Closure.Closure_Model;
   begin
      Row := Base_Row
        (20, Closure.Item_Documentation_Cleanup,
         "missing documentation",
         "Editor.Ada_Phase579_Documentation_Cleanup_Pass1444",
         "cleanup closure requires release documentation evidence");
      Row.Has_Release_Document := False;
      Closure.Add_Row (Input, Row);

      Row := Base_Row
        (21, Closure.Item_Core_Suite_Pruning,
         "missing test",
         "Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443",
         "cleanup closure requires test and suite evidence");
      Row.Has_Core_Suite_Registration := False;
      Closure.Add_Row (Input, Row);

      Row := Base_Row
        (22, Closure.Item_Inventory,
         "stale inventory",
         "Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440",
         "stale cleanup evidence cannot close the ledger");
      Row.Expected_Cleanup_Fingerprint := Row.Cleanup_Fingerprint + 1;
      Closure.Add_Row (Input, Row);

      Model := Closure.Build (Input);
      Assert_Status
        (Model, 20, Closure.Status_Rejected_Missing_Documentation,
         "missing release docs should be rejected");
      Assert_Status
        (Model, 21, Closure.Status_Rejected_Missing_Test,
         "missing test or suite registration should be rejected");
      Assert_Status
        (Model, 22, Closure.Status_Rejected_Fingerprint_Mismatch,
         "stale cleanup fingerprints should be rejected");
   end Test_Missing_Evidence_Or_Stale_Fingerprint_Is_Rejected;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Legacy_Cleanup_Closure_Is_Complete'Access,
         "pass1446 closes the legacy-cleanup ledger");
      Register_Routine
        (T, Test_Reopened_Or_Speculative_Cleanup_Is_Rejected'Access,
         "pass1446 rejects reopened or speculative cleanup work");
      Register_Routine
        (T, Test_Missing_Evidence_Or_Stale_Fingerprint_Is_Rejected'Access,
         "pass1446 rejects missing or stale closure evidence");
   end Register_Tests;

end Test_Ada_Phase579_Legacy_Cleanup_Closure_Pass1446;
