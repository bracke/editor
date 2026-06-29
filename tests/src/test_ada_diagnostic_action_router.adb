with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Diagnostic_Action_Router is

   package Router renames Editor.Ada_Diagnostic_Action_Router;
   package Final_Diag renames Editor.Ada_Final_Semantic_Diagnostic_Integration;
   package Cross_Final renames Final_Diag.Cross_Final;
   package Generic_Final renames Final_Diag.Generic_Final;
   package Navigation renames Editor.Ada_Diagnostic_Navigation;
   package Panel renames Editor.Ada_Diagnostic_Panel_Projection;
   package Provenance renames Editor.Ada_Diagnostic_Provenance;
   package Quick_Fixes renames Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
   package Status_Line renames Editor.Ada_Diagnostic_Status_Line;
   package SC renames Editor.Ada_Semantic_Colour_Projection;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;
   package Index renames Editor.Ada_Semantic_Diagnostic_Index;
   package Guards renames Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;

   use type Router.Diagnostic_Action_Route_Kind;
   use type Router.Diagnostic_Action_Route_Target_Status;
   use type Navigation.Diagnostic_Navigation_Target_Id;
   use type Panel.Diagnostic_Panel_Row_Id;
   use type Provenance.Diagnostic_Provenance_Id;
   use type Index.Semantic_Diagnostic_Index_Id;

   function Current_Guard return Guards.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant Guards.Diagnostic_Snapshot_Key :=
        Guards.Make_Key ("diagnostic-actions.adb", 1201, 2, 3, 5,
                         SC.Fingerprint (Projection));
   begin
      return Guards.Build (Key, Key, Projection);
   end Current_Guard;

   function Base_Context
     (Id     : Final_Diag.Final_Diagnostic_Id;
      Family : Final_Diag.Final_Diagnostic_Source_Family;
      Node   : Editor.Ada_Syntax_Tree.Node_Id)
      return Final_Diag.Final_Diagnostic_Context_Info
   is
      C : Final_Diag.Final_Diagnostic_Context_Info;
   begin
      C.Id := Id;
      C.Family := Family;
      C.Node := Node;
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Accepted;
      C.Generic_Status := Generic_Final.Nested_Generic_Legal_Nested_Instance_Closed;
      C.Source_Fingerprint := Natural (Id) * 1201;
      C.Expected_Source_Fingerprint := Natural (Id) * 1201;
      C.Message := To_Unbounded_String ("diagnostic action workflow");
      C.Start_Line := Positive (Natural (Id) + 20);
      C.Start_Column := 4;
      C.End_Line := Positive (Natural (Id) + 20);
      C.End_Column := 18;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (120101));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (120102));
   begin
      Cross.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Generic_Ctx.Generic_Status :=
        Generic_Final.Nested_Generic_Recursive_Instantiation_Cycle;
      Final_Diag.Add_Context (Contexts, Cross);
      Final_Diag.Add_Context (Contexts, Generic_Ctx);
      return Final_Diag.Build (Contexts);
   end Final_Model;

   function Index_Model return Index.Semantic_Diagnostic_Index_Model is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant Feed.Semantic_Diagnostic_Feed_Model :=
        Feed.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
   begin
      return Index.Build (Feed_Model);
   end Index_Model;

   function Edited_Index_Model return Index.Semantic_Diagnostic_Index_Model is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant Feed.Semantic_Diagnostic_Feed_Model :=
        Feed.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Edited_Feed : constant Feed.Semantic_Diagnostic_Feed_Model :=
        Feed.With_Edit_Hint
          (Feed_Model,
           Feed.Entry_At (Feed_Model, 1).Id,
           21, 4, 21, 18,
           "with Missing.Dependency;");
   begin
      return Index.Build (Edited_Feed);
   end Edited_Index_Model;

   function Routed_Model return Router.Diagnostic_Action_Router_Model is
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Index_Model;
      Quick : constant Quick_Fixes.Diagnostic_Quick_Fix_Model :=
        Quick_Fixes.Build (Indexed);
      Nav : constant Navigation.Diagnostic_Navigation_Model :=
        Navigation.Build (Indexed);
      Pan : constant Panel.Diagnostic_Panel_Model :=
        Panel.Build (Indexed);
      Prov : constant Provenance.Diagnostic_Provenance_Model :=
        Provenance.Build (Indexed);
      Status : constant Status_Line.Diagnostic_Status_Line_Model :=
        Status_Line.Build (Indexed, 21, 4);
   begin
      return Router.Build (Quick, Nav, Pan, Prov, Status);
   end Routed_Model;

   function Edited_Routed_Model return Router.Diagnostic_Action_Router_Model is
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Edited_Index_Model;
      Quick : constant Quick_Fixes.Diagnostic_Quick_Fix_Model :=
        Quick_Fixes.Build (Indexed);
      Nav : constant Navigation.Diagnostic_Navigation_Model :=
        Navigation.Build (Indexed);
      Pan : constant Panel.Diagnostic_Panel_Model :=
        Panel.Build (Indexed);
      Prov : constant Provenance.Diagnostic_Provenance_Model :=
        Provenance.Build (Indexed);
      Status : constant Status_Line.Diagnostic_Status_Line_Model :=
        Status_Line.Build (Indexed, 21, 4);
   begin
      return Router.Build (Quick, Nav, Pan, Prov, Status);
   end Edited_Routed_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Action_Router");
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
         "empty router should not report editable actions");
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

   procedure Test_Router_Joins_Quick_Fixes_To_IDE_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Router.Diagnostic_Action_Router_Model := Routed_Model;
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Index_Model;
      First_Index : constant Index.Semantic_Diagnostic_Index_Entry :=
        Index.Entry_At (Indexed, 1);
      Route : constant Router.Diagnostic_Action_Route :=
        Router.First_For_Diagnostic (Model, First_Index.Id);
      Routes : constant Router.Diagnostic_Action_Route_Set :=
        Router.Routes_For_Diagnostic (Model, First_Index.Id);
   begin
      Assert (Router.Current (Model),
              "non-empty diagnostic action router should remain current");
      Assert (Router.Route_Count (Model) = Index.Entry_Count (Indexed) * 3,
              "each indexed diagnostic should expose navigate, explain, and review actions");
      Assert (Router.Navigate_Route_Count (Model) = Index.Entry_Count (Indexed),
              "each diagnostic should have one navigation route");
      Assert (Router.Explain_Route_Count (Model) = Index.Entry_Count (Indexed),
              "each diagnostic should have one explanation route");
      Assert
        (Router.Count_Kind
           (Model, Router.Diagnostic_Action_Route_Review_Cross_Unit) = 1,
         "cross-unit diagnostics should keep their source-specific review route");
      Assert
        (Router.Count_Kind
           (Model, Router.Diagnostic_Action_Route_Review_Generic) = 1,
         "generic diagnostics should keep their source-specific review route");
      Assert
        (Router.Complete_Route_Count (Model) = Router.Route_Count (Model),
         "routed actions should have navigation, panel, and provenance targets");
      Assert
        (Router.Count_Target_Status
           (Model, Router.Diagnostic_Action_Route_Target_Complete)
         = Router.Route_Count (Model),
         "target status counters should report complete routes");
      Assert (Router.Has_Route (Route), "first diagnostic should have a route");
      Assert
        (Route.Index_Id = First_Index.Id
         and then Route.Navigation_Target /= Navigation.No_Diagnostic_Navigation_Target
         and then Route.Panel_Row /= Panel.No_Diagnostic_Panel_Row
         and then Route.Provenance_Item /= Provenance.No_Diagnostic_Provenance,
         "route should preserve linked diagnostic targets");
      Assert (Router.Route_Set_Count (Routes) = 3,
              "per-diagnostic route lookup should include all quick-fix skeleton actions");
      Assert (Router.Fingerprint (Model) /= 0,
              "non-empty routed diagnostic actions should have a fingerprint");
   end Test_Router_Joins_Quick_Fixes_To_IDE_Targets;

   procedure Test_Router_Preserves_Feed_Edit_Hints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Router.Diagnostic_Action_Router_Model := Edited_Routed_Model;
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Edited_Index_Model;
      First_Index : constant Index.Semantic_Diagnostic_Index_Entry :=
        Index.Entry_At (Indexed, 1);
      Route : constant Router.Diagnostic_Action_Route :=
        Router.First_For_Diagnostic (Model, First_Index.Id);
   begin
      Assert (Router.Current (Model),
              "edited diagnostic action router should remain current");
      Assert (Router.Editable_Route_Count (Model) = 3,
              "feed edit hints should project to all routed candidates for the diagnostic");
      Assert
        (Router.Has_Route (Route)
         and then Route.Has_Edit
         and then Route.Edit_Start_Line = 21
         and then Route.Edit_Start_Column = 4
         and then Route.Edit_End_Line = 21
         and then Route.Edit_End_Column = 18
         and then To_String (Route.Replacement_Text) = "with Missing.Dependency;",
         "router should preserve explicit feed edit metadata");
   end Test_Router_Preserves_Feed_Edit_Hints;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Router_Is_Current_And_Deterministic'Access,
         "Pass1075 keeps empty diagnostic action routing deterministic");
      Register_Routine
        (T, Test_Absent_Diagnostic_Route_Is_Empty'Access,
         "Pass1075 absent diagnostic route lookup returns no route");
      Register_Routine
        (T, Test_Router_Joins_Quick_Fixes_To_IDE_Targets'Access,
         "Diagnostic action router joins quick fixes to IDE targets");
      Register_Routine
        (T, Test_Router_Preserves_Feed_Edit_Hints'Access,
         "Diagnostic action router preserves feed edit hints");
   end Register_Tests;

end Test_Ada_Diagnostic_Action_Router;
