with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Diagnostic_Index;

package body Test_Ada_Diagnostic_Command_Projection_Pass1076 is

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Command_Projection_Pass1076");
   end Name;

   procedure Test_Empty_Command_Projection_Is_Current
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Quick_Fixes : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
      Navigation  : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Panel       : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Provenance  : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
      Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model;
      Routes      : constant Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model :=
        Editor.Ada_Diagnostic_Action_Router.Build
          (Quick_Fixes, Navigation, Panel, Provenance, Status_Line);
      Model       : constant Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Projection_Model :=
        Editor.Ada_Diagnostic_Command_Projection.Build (Routes);
   begin
      Assert
        (Editor.Ada_Diagnostic_Command_Projection.Current (Model),
         "empty command projection should remain current");
      Assert
        (Editor.Ada_Diagnostic_Command_Projection.Descriptor_Count (Model) = 0,
         "empty action routes should produce no command descriptors");
      Assert
        (Editor.Ada_Diagnostic_Command_Projection.Editable_Command_Count (Model) = 0,
         "diagnostic command projection must not report editable commands");
      Assert
        (Editor.Ada_Diagnostic_Command_Projection.Count_Availability
           (Model,
            Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Available) = 0,
         "empty command projection should not report available commands");
   end Test_Empty_Command_Projection_Is_Current;

   procedure Test_Absent_Diagnostic_Command_Is_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Quick_Fixes : Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
      Navigation  : Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
      Panel       : Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
      Provenance  : Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
      Status_Line : Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model;
      Routes      : constant Editor.Ada_Diagnostic_Action_Router.Diagnostic_Action_Router_Model :=
        Editor.Ada_Diagnostic_Action_Router.Build
          (Quick_Fixes, Navigation, Panel, Provenance, Status_Line);
      Model       : constant Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Projection_Model :=
        Editor.Ada_Diagnostic_Command_Projection.Build (Routes);
      Descriptor  : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Descriptor;
   begin
      Descriptor := Editor.Ada_Diagnostic_Command_Projection.First_For_Diagnostic
        (Model,
         Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry);
      Assert
        (not Editor.Ada_Diagnostic_Command_Projection.Has_Descriptor (Descriptor),
         "absent diagnostic lookup should return no command descriptor");
   end Test_Absent_Diagnostic_Command_Is_Empty;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Command_Projection_Is_Current'Access,
         "Pass1076 keeps empty diagnostic command projection deterministic");
      Register_Routine
        (T, Test_Absent_Diagnostic_Command_Is_Empty'Access,
         "Pass1076 absent diagnostic command lookup returns no descriptor");
   end Register_Tests;

end Test_Ada_Diagnostic_Command_Projection_Pass1076;
