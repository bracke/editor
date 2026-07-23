package Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits is

   function Audit_Real_Build_Execution_Gates return Boolean;

   function Audit_User_Opt_In_Build_Gates return Boolean;

   function Audit_Build_Execution_Gates return Boolean;

   function Audit_Gated_Runner_Command_Path return Boolean;

   function Audit_Process_Fixture_Gates return Boolean;

   function Build_Run_Test_Seam_Audit_Passes return Boolean;

end Editor.External_Producers.Build_Runner_Audits.Build_Path_Audits;
