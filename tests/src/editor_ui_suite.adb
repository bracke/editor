with Editor.Command_Palette.Tests;
with Editor.Command_Surface.Tests;
with Editor.Contextual_Help.Tests;
with Editor.Dogfood_Workflow.Tests;
with Editor.Empty_State_Guidance.Tests;
with Editor.Executor.UI_Tests;
with Editor.Feature_Integration.Tests;
with Editor.Feature_Panel.Tests;
with Editor.Feature_Panel_Audit.Tests;
with Editor.Focus_Management.Tests;
with Editor.Folding.Tests;
with Editor.Gutter.Tests;
with Editor.Gutter_Markers.Tests;
with Editor.Input_Bridge.Tests;
with Editor.Input_Field.Tests;
with Editor.Keybindings.Tests;
with Editor.Line_Numbers.Tests;
with Editor.Messages.Tests;
with Editor.Overlay_Focus.Tests;
with Editor.Panel_Focus.Tests;
with Editor.Panels.Tests;
with Editor.Product_Surface_Cleanup.Tests;
with Editor.Render_Model.Tests;
with Editor.Scrollbars.Tests;
with Editor.Startup_Readiness.Tests;
with Editor.Status_Bar.Tests;
with Editor.Syntax_Overlays.Tests;
with Editor.Tab_Bar.Tests;

package body Editor_UI_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Render_Model.Tests.Render_Model_Test_Case);
      Ret.Add_Test (new Editor.Syntax_Overlays.Tests.Syntax_Overlays_Test_Case);
      Ret.Add_Test (new Editor.Command_Palette.Tests.Command_Palette_Test_Case);
      Ret.Add_Test (new Editor.Keybindings.Tests.Keybindings_Test_Case);
      Ret.Add_Test (new Editor.Line_Numbers.Tests.Line_Numbers_Test_Case);
      Ret.Add_Test (new Editor.Scrollbars.Tests.Scrollbars_Test_Case);
      Ret.Add_Test (new Editor.Folding.Tests.Folding_Test_Case);
      Ret.Add_Test (new Editor.Gutter.Tests.Gutter_Test_Case);
      Ret.Add_Test (new Editor.Gutter_Markers.Tests.Gutter_Markers_Test_Case);
      Ret.Add_Test (new Editor.Status_Bar.Tests.Status_Bar_Test_Case);
      Ret.Add_Test (new Editor.Messages.Tests.Messages_Test_Case);
      Ret.Add_Test (new Editor.Tab_Bar.Tests.Tab_Bar_Test_Case);
      Ret.Add_Test (new Editor.Panels.Tests.Panels_Test_Case);
      Ret.Add_Test (new Editor.Panel_Focus.Tests.Panel_Focus_Test_Case);
      Ret.Add_Test (new Editor.Overlay_Focus.Tests.Overlay_Focus_Test_Case);
      Ret.Add_Test (new Editor.Input_Bridge.Tests.Input_Bridge_Test_Case);
      Ret.Add_Test (new Editor.Input_Field.Tests.Input_Field_Test_Case);
      Ret.Add_Test (new Editor.Command_Surface.Tests.Command_Surface_Test_Case);
      Ret.Add_Test (new Editor.Contextual_Help.Tests.Contextual_Help_Test_Case);
      Ret.Add_Test (new Editor.Feature_Integration.Tests.Feature_Integration_Test_Case);
      Ret.Add_Test (new Editor.Feature_Panel.Tests.Feature_Panel_Test_Case);
      Ret.Add_Test (new Editor.Feature_Panel_Audit.Tests.Feature_Panel_Audit_Test_Case);
      Ret.Add_Test (new Editor.Focus_Management.Tests.Focus_Management_Test_Case);
      Ret.Add_Test (new Editor.Startup_Readiness.Tests.Startup_Readiness_Test_Case);
      Ret.Add_Test (new Editor.Empty_State_Guidance.Tests.Empty_State_Guidance_Test_Case);
      Ret.Add_Test (new Editor.Product_Surface_Cleanup.Tests.Product_Surface_Cleanup_Test_Case);
      Ret.Add_Test (new Editor.Dogfood_Workflow.Tests.Dogfood_Workflow_Test_Case);
      Ret.Add_Test (new Editor.Executor.UI_Tests.UI_Test_Case);
      return Ret;
   end Suite;

end Editor_UI_Suite;
