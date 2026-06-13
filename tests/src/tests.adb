with AUnit.Reporter.Text;
with AUnit.Run;
with Ada.Directories;
with All_Suites;
with Editor.Recent_Projects;

procedure Tests is
   procedure Runner is new AUnit.Run.Test_Runner (All_Suites.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
   Runner (Reporter);
end Tests;