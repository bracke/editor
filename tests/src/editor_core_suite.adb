with Editor.Active_Find.Tests;
with Editor.Bookmarks.Tests;
with Editor.Bridge.Tests;
with Editor.Buffer_Switcher.Tests;
with Editor.Buffers.Tests;
with Editor.Clipboard.Tests;
with Editor.Core_Editing_Workflow.Tests;
with Editor.Dirty_Lines.Tests;
with Editor.Files.Tests;
with Editor.Go_To_Line.Tests;
with Editor.History.Tests;
with Editor.Instance.Tests;
with Editor.Line_Edit.Tests;
with Editor.Missing_Stale_Recovery.Tests;
with Editor.Navigation.Tests;
with Editor.Navigation_History.Tests;
with Editor.Quick_Open.Tests;
with Editor.Recent_Buffers.Tests;
with Editor.Search.Tests;
with Editor.Selection.Tests;
with Editor.Settings.Tests;
with Editor.Settings_Management.Tests;
with Editor.Smoke_Tests;
with Editor.State.Tests;

package body Editor_Core_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Instance.Tests.Instance_Test_Case);
      Ret.Add_Test (new Editor.State.Tests.State_Test_Case);
      Ret.Add_Test (new Editor.Search.Tests.Search_Test_Case);
      Ret.Add_Test (new Editor.Active_Find.Tests.Active_Find_Test_Case);
      Ret.Add_Test (new Editor.Go_To_Line.Tests.Go_To_Line_Test_Case);
      Ret.Add_Test (new Editor.Quick_Open.Tests.Quick_Open_Test_Case);
      Ret.Add_Test (new Editor.Buffer_Switcher.Tests.Buffer_Switcher_Test_Case);
      Ret.Add_Test (new Editor.Bookmarks.Tests.Bookmarks_Test_Case);
      Ret.Add_Test (new Editor.Recent_Buffers.Tests.Recent_Buffers_Test_Case);
      Ret.Add_Test (new Editor.History.Tests.History_Test_Case);
      Ret.Add_Test (new Editor.Selection.Tests.Selection_Test_Case);
      Ret.Add_Test (new Editor.Line_Edit.Tests.Line_Edit_Test_Case);
      Ret.Add_Test (new Editor.Smoke_Tests.Smoke_Test_Case);
      Ret.Add_Test (new Editor.Bridge.Tests.Bridge_Test_Case);
      Ret.Add_Test (new Editor.Buffers.Tests.Buffers_Test_Case);
      Ret.Add_Test (new Editor.Clipboard.Tests.Clipboard_Test_Case);
      Ret.Add_Test (new Editor.Files.Tests.Files_Test_Case);
      Ret.Add_Test (new Editor.Settings.Tests.Settings_Test_Case);
      Ret.Add_Test (new Editor.Settings_Management.Tests.Settings_Management_Test_Case);
      Ret.Add_Test (new Editor.Dirty_Lines.Tests.Dirty_Lines_Test_Case);
      Ret.Add_Test (new Editor.Navigation.Tests.Navigation_Test_Case);
      Ret.Add_Test (new Editor.Navigation_History.Tests.Navigation_History_Test_Case);
      Ret.Add_Test (new Editor.Core_Editing_Workflow.Tests.Core_Editing_Workflow_Test_Case);
      Ret.Add_Test (new Editor.Missing_Stale_Recovery.Tests.Missing_Stale_Recovery_Test_Case);
      return Ret;
   end Suite;

end Editor_Core_Suite;
