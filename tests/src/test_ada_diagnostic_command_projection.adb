with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Command_Projection;
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

package body Test_Ada_Diagnostic_Command_Projection is

   package Router renames Editor.Ada_Diagnostic_Action_Router;
   package Commands renames Editor.Ada_Diagnostic_Command_Projection;
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

   use type Commands.Diagnostic_Command_Availability;
   use type Commands.Diagnostic_Command_Kind;
   use type Index.Semantic_Diagnostic_Index_Id;

   function Current_Guard return Guards.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant Guards.Diagnostic_Snapshot_Key :=
        Guards.Make_Key ("diagnostic-commands.adb", 1202, 2, 3, 5,
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
      C.Source_Fingerprint := Natural (Id) * 1202;
      C.Expected_Source_Fingerprint := Natural (Id) * 1202;
      C.Message := To_Unbounded_String ("diagnostic command workflow");
      C.Start_Line := Positive (Natural (Id) + 30);
      C.Start_Column := 5;
      C.End_Line := Positive (Natural (Id) + 30);
      C.End_Column := 22;
      return C;
   end Base_Context;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Cross : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (120201));
      Generic_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Generic_Replay,
           Editor.Ada_Syntax_Tree.Node_Id (120202));
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
           31, 5, 31, 22,
           "with Missing.Dependency;");
   begin
      return Index.Build (Edited_Feed);
   end Edited_Index_Model;

   function Command_Model return Commands.Diagnostic_Command_Projection_Model is
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
        Status_Line.Build (Indexed, 31, 5);
      Routes : constant Router.Diagnostic_Action_Router_Model :=
        Router.Build (Quick, Nav, Pan, Prov, Status);
   begin
      return Commands.Build (Routes);
   end Command_Model;

   function Edited_Command_Model return Commands.Diagnostic_Command_Projection_Model is
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
        Status_Line.Build (Indexed, 31, 5);
      Routes : constant Router.Diagnostic_Action_Router_Model :=
        Router.Build (Quick, Nav, Pan, Prov, Status);
   begin
      return Commands.Build (Routes);
   end Edited_Command_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Command_Projection");
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
         "empty command projection should not report editable commands");
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

   procedure Test_Command_Projection_Exposes_Available_Routed_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Commands.Diagnostic_Command_Projection_Model :=
        Command_Model;
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Index_Model;
      First_Index : constant Index.Semantic_Diagnostic_Index_Entry :=
        Index.Entry_At (Indexed, 1);
      Descriptor : constant Commands.Diagnostic_Command_Descriptor :=
        Commands.First_For_Diagnostic (Model, First_Index.Id);
      Descriptors : constant Commands.Diagnostic_Command_Descriptor_Set :=
        Commands.Descriptors_For_Diagnostic (Model, First_Index.Id);
   begin
      Assert (Commands.Current (Model),
              "non-empty diagnostic command projection should remain current");
      Assert (Commands.Descriptor_Count (Model) = Index.Entry_Count (Indexed) * 3,
              "each routed diagnostic action should become a command descriptor");
      Assert
        (Commands.Available_Command_Count (Model) =
         Commands.Descriptor_Count (Model),
         "complete routed diagnostic targets should become available commands");
      Assert
        (Commands.Missing_Target_Command_Count (Model) = 0
         and then Commands.Incomplete_Command_Count (Model) = 0
         and then Commands.Status_Only_Command_Count (Model) = 0,
         "fully routed diagnostic commands should not be degraded");
      Assert
        (Commands.Count_Kind
           (Model, Commands.Diagnostic_Command_Navigate_To_Diagnostic)
         = Index.Entry_Count (Indexed),
         "navigation routes should project to navigation commands");
      Assert
        (Commands.Count_Kind
           (Model, Commands.Diagnostic_Command_Explain_Diagnostic)
         = Index.Entry_Count (Indexed),
         "explanation routes should project to explanation commands");
      Assert
        (Commands.Count_Kind
           (Model, Commands.Diagnostic_Command_Review_Cross_Unit) = 1,
         "cross-unit review routes should project to cross-unit commands");
      Assert
        (Commands.Count_Kind
           (Model, Commands.Diagnostic_Command_Review_Generic) = 1,
         "generic review routes should project to generic commands");
      Assert (Commands.Has_Descriptor (Descriptor),
              "first diagnostic should have a command descriptor");
      Assert
        (Descriptor.Availability = Commands.Diagnostic_Command_Available
         and then Descriptor.Command_Kind =
           Commands.Diagnostic_Command_Navigate_To_Diagnostic
         and then To_String (Descriptor.Command_Name) =
           "ada.diagnostic.navigate",
         "first descriptor should be an available navigation command");
      Assert (Commands.Descriptor_Set_Count (Descriptors) = 3,
              "per-diagnostic command lookup should include all action descriptors");
      Assert (Commands.Fingerprint (Model) /= 0,
              "non-empty diagnostic command projection should have a fingerprint");
   end Test_Command_Projection_Exposes_Available_Routed_Actions;

   procedure Test_Command_Projection_Preserves_Feed_Edit_Hints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Commands.Diagnostic_Command_Projection_Model :=
        Edited_Command_Model;
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Edited_Index_Model;
      First_Index : constant Index.Semantic_Diagnostic_Index_Entry :=
        Index.Entry_At (Indexed, 1);
      Descriptor : constant Commands.Diagnostic_Command_Descriptor :=
        Commands.First_For_Diagnostic (Model, First_Index.Id);
   begin
      Assert (Commands.Current (Model),
              "edited diagnostic command projection should remain current");
      Assert (Commands.Editable_Command_Count (Model) = 3,
              "feed edit hints should project to all command descriptors for the diagnostic");
      Assert
        (Commands.Has_Descriptor (Descriptor)
         and then Descriptor.Has_Edit
         and then Descriptor.Edit_Start_Line = 31
         and then Descriptor.Edit_Start_Column = 5
         and then Descriptor.Edit_End_Line = 31
         and then Descriptor.Edit_End_Column = 22
         and then To_String (Descriptor.Replacement_Text) = "with Missing.Dependency;",
         "command projection should preserve explicit feed edit metadata");
   end Test_Command_Projection_Preserves_Feed_Edit_Hints;

   procedure Test_Diagnostic_Surface_Actions_Are_Normalized
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Commands.Diagnostic_Command_Projection_Model :=
        Edited_Command_Model;
      Indexed : constant Index.Semantic_Diagnostic_Index_Model := Edited_Index_Model;
      First_Index : constant Index.Semantic_Diagnostic_Index_Entry :=
        Index.Entry_At (Indexed, 1);
      Descriptor : constant Commands.Diagnostic_Command_Descriptor :=
        Commands.First_For_Diagnostic (Model, First_Index.Id);
      Missing : Commands.Diagnostic_Command_Descriptor := Descriptor;
      Stale : Commands.Diagnostic_Command_Descriptor := Descriptor;
   begin
      Assert
        (Commands.Surface_Action_Label
           (Commands.Diagnostic_Surface_Open_Source) = "Open Source",
         "diagnostic action label should be shared");
      Assert
        (Commands.Surface_Action_Label
           (Commands.Diagnostic_Surface_Reveal_Diagnostic) = "Reveal Diagnostic",
         "diagnostic reveal label should be shared");
      Assert
        (Commands.Surface_Action_Label
           (Commands.Diagnostic_Surface_Suppress_Diagnostic) = "Suppress Diagnostic",
         "diagnostic suppression label should be shared");
      Assert
        (Commands.Surface_Action_Label
           (Commands.Diagnostic_Surface_Apply_Quick_Fix) = "Apply Quick Fix",
         "diagnostic quick-fix label should be shared");
      Assert
        (Commands.Surface_Action_Command_Name
           (Commands.Diagnostic_Surface_Open_Source) =
         "ada.diagnostic.open-source",
         "diagnostic open-source command name should be shared");
      Assert
        (Commands.Surface_Action_Command_Name
           (Commands.Diagnostic_Surface_Reveal_Diagnostic) =
         "ada.diagnostic.reveal",
         "diagnostic reveal command name should be shared");
      Assert
        (Commands.Surface_Action_Command_Name
           (Commands.Diagnostic_Surface_Suppress_Diagnostic) =
         "ada.diagnostic.suppress",
         "diagnostic suppression command name should be shared");
      Assert
        (Commands.Surface_Action_Command_Name
           (Commands.Diagnostic_Surface_Apply_Quick_Fix) =
         "ada.diagnostic.apply-quick-fix",
         "diagnostic quick-fix command name should be shared");

      Assert
        (Commands.Descriptor_Supports_Surface_Action
           (Descriptor, Commands.Diagnostic_Surface_Open_Source),
         "available diagnostic descriptor should support open-source action");
      Assert
        (Commands.Descriptor_Supports_Surface_Action
           (Descriptor, Commands.Diagnostic_Surface_Reveal_Diagnostic),
         "available diagnostic descriptor should support reveal action");
      Assert
        (Commands.Descriptor_Supports_Surface_Action
           (Descriptor, Commands.Diagnostic_Surface_Suppress_Diagnostic),
         "current diagnostic descriptor should support suppression projection");
      Assert
        (Commands.Descriptor_Supports_Surface_Action
           (Descriptor, Commands.Diagnostic_Surface_Apply_Quick_Fix),
         "editable diagnostic descriptor should support quick-fix action");

      Missing.Availability := Commands.Diagnostic_Command_Missing_Target;
      Missing.Has_Edit := False;
      Assert
        (not Commands.Descriptor_Supports_Surface_Action
           (Missing, Commands.Diagnostic_Surface_Open_Source),
         "missing-target diagnostic should not support open-source action");
      Assert
        (not Commands.Descriptor_Supports_Surface_Action
           (Missing, Commands.Diagnostic_Surface_Apply_Quick_Fix),
         "missing-target diagnostic should not support quick-fix action");
      Assert
        (Commands.Unavailable_Target_Message (Missing.Availability) =
         "Diagnostic target is unavailable.",
         "missing-target diagnostic action wording should be canonical");

      Stale.Availability := Commands.Diagnostic_Command_Rejected_Stale;
      Assert
        (not Commands.Descriptor_Supports_Surface_Action
           (Stale, Commands.Diagnostic_Surface_Suppress_Diagnostic),
         "stale diagnostic descriptor should not support suppression projection");
      Assert
        (Commands.Unavailable_Target_Message (Stale.Availability) =
         "Diagnostic action is stale.",
         "stale diagnostic action wording should be canonical");
   end Test_Diagnostic_Surface_Actions_Are_Normalized;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Command_Projection_Is_Current'Access,
         "Case 1076 keeps empty diagnostic command projection deterministic");
      Register_Routine
        (T, Test_Absent_Diagnostic_Command_Is_Empty'Access,
         "Case 1076 absent diagnostic command lookup returns no descriptor");
      Register_Routine
        (T, Test_Command_Projection_Exposes_Available_Routed_Actions'Access,
         "Diagnostic command projection exposes available routed actions");
      Register_Routine
        (T, Test_Command_Projection_Preserves_Feed_Edit_Hints'Access,
         "Diagnostic command projection preserves feed edit hints");
      Register_Routine
        (T, Test_Diagnostic_Surface_Actions_Are_Normalized'Access,
         "Diagnostic surface actions are normalized");
   end Register_Tests;

end Test_Ada_Diagnostic_Command_Projection;
