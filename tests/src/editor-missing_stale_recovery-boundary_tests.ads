with AUnit.Test_Cases;

package Editor.Missing_Stale_Recovery.Boundary_Tests is

   procedure Test_Render_Persistence_And_Command_Payload_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Project_Transition_And_Explicit_Recovery_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Stale_Targets_Block_Actions_Until_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Workspace_Action_Caret_And_Selection_Policies
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Dirty_Guards_And_Parent_Directory_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Command_Route_Payload_Outcome_And_Snapshot_Label_Gates
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end Editor.Missing_Stale_Recovery.Boundary_Tests;
