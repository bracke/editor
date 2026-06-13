with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Diagnostic_Index;

package body Test_Ada_Diagnostic_Action_Router_Pass1075 is

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Action_Router_Pass1075");
   end Name;

   procedure Test_Empty_Router_Is_Current_And_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Quick_Fixes : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
      Navigation  : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Panel       : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Provenance  : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
      Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model;
      Model       : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model;
   begin
      Model := Editor.Ada_Diagnostic_Action_Router.Build
        (Quick_Fixes, Navigation, Panel, Provenance, Status_Line);

      Assert
        (Editor.Ada_Diagnostic_Action_Router.Current (Model),
         "empty action router should remain current");
      Assert
        (Editor.Ada_Diagnostic_Action_Router.Route_Count (Model) = 0,
         "empty quick-fix model should produce no action routes");
      Assert
        (Editor.Ada_Diagnostic_Action_Router.Editable_Route_Count (Model) = 0,
         "projection-only router should not report editable actions");
      Assert
        (Editor.Ada_Diagnostic_Action_Router.Count_Target_Status
           (Model,
            Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route_Target_Complete) = 0,
         "empty model should not report complete targets");
   end Test_Empty_Router_Is_Current_And_Deterministic;

   procedure Test_Absent_Diagnostic_Route_Is_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Quick_Fixes : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
      Navigation  : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Panel       : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Provenance  : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
      Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model;
      Model       : constant Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model :=
        Editor.Ada_Diagnostic_Action_Router.Build
          (Quick_Fixes, Navigation, Panel, Provenance, Status_Line);
      Route       : Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Route;
   begin
      Route := Editor.Ada_Diagnostic_Action_Router.First_For_Diagnostic
        (Model,
         Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry);
      Assert
        (not Editor.Ada_Diagnostic_Action_Router.Has_Route (Route),
         "absent diagnostic lookup should return no routed action");
   end Test_Absent_Diagnostic_Route_Is_Empty;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Router_Is_Current_And_Deterministic'Access,
         "Pass1075 keeps empty diagnostic action routing deterministic");
      Register_Routine
        (T, Test_Absent_Diagnostic_Route_Is_Empty'Access,
         "Pass1075 absent diagnostic route lookup returns no route");
   end Register_Tests;

end Test_Ada_Diagnostic_Action_Router_Pass1075;
