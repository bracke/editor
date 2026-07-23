with AUnit.Test_Cases;

package Editor.Missing_Stale_Recovery.Target_Validation_Tests is

   procedure Test_User_Readable_Labels_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Workspace_And_Recent_Recovery_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_File_Lifecycle_Missing_Backing_File_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_File_Project_And_Project_Boundary_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Surface_Specific_Stale_Target_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class);

   procedure Test_Outline_Diagnostics_And_Build_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class);

end Editor.Missing_Stale_Recovery.Target_Validation_Tests;
