with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Type_Graph;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Private_View_Visibility;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Freezing_Interactions;
with Editor.Ada_Representation_Diagnostics;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Generic_Contract_Diagnostics;
with Editor.Ada_Cross_Unit_Diagnostics;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Suppression_Baseline;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Syntax_Semantics.Diagnostics_Tests is

   use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   use type Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Group_Kind;
   use type Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Kind;
   use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Status;
   use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule_Id;

   procedure Test_Ada_Diagnostic_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Navigation_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Navigation_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Representation_Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      Empty_Expression_Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Empty_Generic_Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Empty_Cross_Unit_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Empty_Expression_Diags, Empty_Generic_Diags,
           Empty_Cross_Unit_Diags, Representation_Diags);
      Produced : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("navigation.ads", 31, 32, 33, 34,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("navigation.ads", 31, 32, 33, 34,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("navigation.ads", 31, 32, 35, 34,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale, Colours);
      Accepted_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Accepted_Guarded);
      Rejected_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Rejected_Guarded);
      Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Accepted_Feed);
      Rejected_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Rejected_Feed);
      Navigation : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model :=
        Editor.Ada_Diagnostic_Navigation.Build (Index);
      Rejected_Navigation : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model :=
        Editor.Ada_Diagnostic_Navigation.Build (Rejected_Index);
      First : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
        Editor.Ada_Diagnostic_Navigation.First_Diagnostic (Navigation);
      Last : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
        Editor.Ada_Diagnostic_Navigation.Last_Diagnostic (Navigation);
      Next : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
        Editor.Ada_Diagnostic_Navigation.Next_Diagnostic (Navigation, 1, 1);
      Previous : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
        Editor.Ada_Diagnostic_Navigation.Previous_Diagnostic (Navigation, 99, 1);
      Error_Next : constant Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target :=
        Editor.Ada_Diagnostic_Navigation.Next_Diagnostic
          (Navigation, 1, 1,
           Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error);
   begin
      Assert
        (Editor.Ada_Diagnostic_Navigation.Current (Navigation),
         "diagnostic navigation must accept current diagnostic indexes");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Navigation_Target_Count (Navigation) =
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
         "diagnostic navigation must preserve indexed diagnostic count");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Error_Target_Count (Navigation) =
         Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index),
         "diagnostic navigation must preserve severity target totals");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Has_Target (First)
         and then Editor.Ada_Diagnostic_Navigation.Has_Target (Last),
         "diagnostic navigation must expose first and last targets");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Has_Target (Next)
         and then Next.Fingerprint /= 0,
         "diagnostic navigation must expose next target from a source position");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Has_Target (Previous),
         "diagnostic navigation must expose previous target from a source position");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Has_Target (Error_Next)
         and then Error_Next.Severity =
           Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error,
         "diagnostic navigation must support severity-filtered next lookup");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Fingerprint (Navigation) /= 0,
         "diagnostic navigation must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Rejected_Stale (Rejected_Navigation)
         and then Editor.Ada_Diagnostic_Navigation.Navigation_Target_Count (Rejected_Navigation) = 0,
         "diagnostic navigation must withhold stale rejected index targets");
      Assert
        (Editor.Ada_Diagnostic_Navigation.Rejected_Target_Count (Rejected_Navigation) =
         Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Rejected_Index),
         "diagnostic navigation must preserve rejected target totals");
   end Test_Ada_Diagnostic_Navigation;


   procedure Test_Ada_Diagnostic_Panel_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Panel_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Panel_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Representation_Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      Empty_Expression_Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Empty_Generic_Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Empty_Cross_Unit_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Empty_Expression_Diags, Empty_Generic_Diags,
           Empty_Cross_Unit_Diags, Representation_Diags);
      Produced : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("panel.ads", 41, 42, 43, 44,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("panel.ads", 41, 42, 43, 44,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("panel.ads", 41, 42, 45, 44,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale, Colours);
      Accepted_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Accepted_Guarded);
      Rejected_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Rejected_Guarded);
      Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Accepted_Feed);
      Rejected_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Rejected_Feed);
      Panel : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model :=
        Editor.Ada_Diagnostic_Panel_Projection.Build
          (Index, "panel.ads", "Panel_Checks");
      Rejected_Panel : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model :=
        Editor.Ada_Diagnostic_Panel_Projection.Build
          (Rejected_Index, "panel.ads", "Panel_Checks");
      First_Error : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row :=
        Editor.Ada_Diagnostic_Panel_Projection.First_Row_For_Severity
          (Panel, Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error);
      Selected : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model :=
        Editor.Ada_Diagnostic_Panel_Projection.Select_Nearest (Panel, 1, 1);
      Selected_Row : constant Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row :=
        Editor.Ada_Diagnostic_Panel_Projection.Selected_Row (Selected);
   begin
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Current (Panel),
         "diagnostic panel projection must accept current diagnostic indexes");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Row_Count (Panel) =
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
         "diagnostic panel projection must preserve indexed diagnostic rows");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Error_Row_Count (Panel) =
         Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index),
         "diagnostic panel projection must preserve error row totals");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Source_Group_Count (Panel) > 0
         and then Editor.Ada_Diagnostic_Panel_Projection.File_Group_Count (Panel) = 1
         and then Editor.Ada_Diagnostic_Panel_Projection.Unit_Group_Count (Panel) = 1,
         "diagnostic panel projection must expose source, file, and unit grouping metadata");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Has_Row (First_Error)
         and then First_Error.Group_Kind =
           Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Group_Error,
         "diagnostic panel projection must expose severity grouped rows");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Has_Row (Selected_Row)
         and then Selected_Row.Fingerprint /= 0,
         "diagnostic panel projection must expose deterministic selected-row state");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Count_Source
           (Panel, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) > 0,
         "diagnostic panel projection must count rows by semantic source family");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Fingerprint (Panel) /= 0,
         "diagnostic panel projection must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Rejected_Stale (Rejected_Panel)
         and then Editor.Ada_Diagnostic_Panel_Projection.Row_Count (Rejected_Panel) = 0,
         "diagnostic panel projection must withhold stale rejected index rows");
      Assert
        (Editor.Ada_Diagnostic_Panel_Projection.Rejected_Row_Count (Rejected_Panel) =
         Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Rejected_Index),
         "diagnostic panel projection must preserve rejected row totals");
   end Test_Ada_Diagnostic_Panel_Projection;


   procedure Test_Ada_Diagnostic_Status_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Status_Line_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Status_Line_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Representation_Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      Empty_Expression_Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Empty_Generic_Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Empty_Cross_Unit_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Empty_Expression_Diags, Empty_Generic_Diags,
           Empty_Cross_Unit_Diags, Representation_Diags);
      Produced : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("status-line.ads", 51, 52, 53, 54,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("status-line.ads", 51, 52, 53, 54,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("status-line.ads", 51, 52, 54, 54,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale, Colours);
      Accepted_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Accepted_Guarded);
      Rejected_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Rejected_Guarded);
      Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Accepted_Feed);
      Rejected_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Rejected_Feed);
      Summary : constant Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model :=
        Editor.Ada_Diagnostic_Status_Line.Build (Index, 8, 10);
      Rejected_Summary : constant Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model :=
        Editor.Ada_Diagnostic_Status_Line.Build (Rejected_Index, 8, 10);
      Nearest : constant Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Target :=
        Editor.Ada_Diagnostic_Status_Line.Nearest_Diagnostic (Summary);
      Summary_Text : constant String :=
        Editor.Ada_Diagnostic_Status_Line.Summary_Text (Summary);
   begin
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Current (Summary),
         "diagnostic status-line summary must accept current diagnostic indexes");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Diagnostic_Count (Summary) =
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
         "diagnostic status-line summary must preserve indexed diagnostic totals");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Error_Count (Summary) =
         Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index),
         "diagnostic status-line summary must preserve error totals");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Summary_Kind (Summary) =
         Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Error,
         "diagnostic status-line summary must expose the highest severity state");
      Assert
        (Summary_Text'Length > 0,
         "diagnostic status-line summary must expose deterministic summary text");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Current_Line_Count (Summary) > 0,
         "diagnostic status-line summary must count diagnostics on the current line");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Has_Target (Nearest)
         and then Nearest.Fingerprint /= 0,
         "diagnostic status-line summary must expose nearest diagnostic metadata");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Count_Source
           (Summary, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) > 0,
         "diagnostic status-line summary must preserve source-family counters");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Fingerprint (Summary) /= 0,
         "diagnostic status-line summary must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Rejected_Stale (Rejected_Summary)
         and then Editor.Ada_Diagnostic_Status_Line.Diagnostic_Count (Rejected_Summary) = 0,
         "diagnostic status-line summary must withhold stale rejected diagnostics");
      Assert
        (Editor.Ada_Diagnostic_Status_Line.Rejected_Diagnostic_Count (Rejected_Summary) =
         Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Rejected_Index),
         "diagnostic status-line summary must preserve rejected diagnostic totals");
   end Test_Ada_Diagnostic_Status_Line;



   procedure Test_Ada_Diagnostic_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Provenance_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Provenance_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Representation_Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      Empty_Expression_Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Empty_Generic_Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Empty_Cross_Unit_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Empty_Expression_Diags, Empty_Generic_Diags,
           Empty_Cross_Unit_Diags, Representation_Diags);
      Produced : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("provenance.ads", 71, 72, 73, 74,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("provenance.ads", 71, 72, 73, 74,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("provenance.ads", 71, 72, 74, 74,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale, Colours);
      Accepted_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Accepted_Guarded);
      Rejected_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Rejected_Guarded);
      Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Accepted_Feed);
      Rejected_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Rejected_Feed);
      Provenance : constant Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model :=
        Editor.Ada_Diagnostic_Provenance.Build (Index);
      Rejected_Provenance : constant Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model :=
        Editor.Ada_Diagnostic_Provenance.Build (Rejected_Index);
      First_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry :=
        Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, 1);
      First_Item : constant Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Item :=
        Editor.Ada_Diagnostic_Provenance.First_For_Diagnostic (Provenance, First_Index.Id);
      Per_Diagnostic : constant Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Result_Set :=
        Editor.Ada_Diagnostic_Provenance.Items_For_Diagnostic (Provenance, First_Index.Id);
   begin
      Assert
        (Editor.Ada_Diagnostic_Provenance.Current (Provenance),
         "diagnostic provenance must accept current diagnostic indexes");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Item_Count (Provenance) =
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
         "diagnostic provenance must preserve indexed diagnostic totals");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Error_Item_Count (Provenance) =
         Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index),
         "diagnostic provenance must preserve error totals");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Has_Item (First_Item)
         and then First_Item.Fingerprint /= 0
         and then Length (First_Item.Explanation) > 0
         and then Length (First_Item.Chain_Summary) > 0,
         "diagnostic provenance must expose a stable explanation chain for each diagnostic");
      Assert
        (First_Item.Source_Fingerprint = First_Index.Diagnostic.Source_Fingerprint
         and then First_Item.Diagnostic_Fingerprint = First_Index.Diagnostic.Fingerprint,
         "diagnostic provenance must preserve source and diagnostic fingerprints");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Count_Source
           (Provenance, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) > 0,
         "diagnostic provenance must preserve source-family counters");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Count_Stage
           (Provenance, Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Snapshot_Guard) =
         Editor.Ada_Diagnostic_Provenance.Item_Count (Provenance),
         "diagnostic provenance must record snapshot-guard participation for each accepted item");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Result_Count (Per_Diagnostic) = 1,
         "diagnostic provenance must query provenance by diagnostic identity");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Fingerprint (Provenance) /= 0,
         "diagnostic provenance must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Rejected_Stale (Rejected_Provenance)
         and then Editor.Ada_Diagnostic_Provenance.Item_Count (Rejected_Provenance) = 0,
         "diagnostic provenance must withhold stale rejected provenance items");
      Assert
        (Editor.Ada_Diagnostic_Provenance.Rejected_Item_Count (Rejected_Provenance) =
         Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Rejected_Index),
         "diagnostic provenance must preserve rejected item totals");
   end Test_Ada_Diagnostic_Provenance;



   procedure Test_Ada_Diagnostic_Quick_Fix_Skeleton
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Quick_Fix_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Quick_Fix_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Representation_Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      Empty_Expression_Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Empty_Generic_Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Empty_Cross_Unit_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Empty_Expression_Diags, Empty_Generic_Diags,
           Empty_Cross_Unit_Diags, Representation_Diags);
      Produced : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("quick-fix.ads", 61, 62, 63, 64,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("quick-fix.ads", 61, 62, 63, 64,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("quick-fix.ads", 61, 62, 64, 64,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale, Colours);
      Accepted_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Accepted_Guarded);
      Rejected_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Rejected_Guarded);
      Edited_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.With_Edit_Hint
          (Accepted_Feed,
           Editor.Ada_Semantic_Diagnostic_Feed.Entry_At (Accepted_Feed, 1).Id,
           61, 7, 61, 7,
           "pragma Assert (False);");
      Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Edited_Feed);
      Rejected_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Rejected_Feed);
      Fixes : constant Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model :=
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build (Index);
      Rejected_Fixes : constant Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model :=
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build (Rejected_Index);
      First_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry :=
        Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, 1);
      First_Fix : constant Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Candidate :=
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.First_For_Diagnostic (Fixes, First_Index.Id);
      Per_Diagnostic : constant Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Result_Set :=
        Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Candidates_For_Diagnostic (Fixes, First_Index.Id);
   begin
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Current (Fixes),
         "diagnostic quick-fix skeleton must accept current diagnostic indexes");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Candidate_Count (Fixes) >=
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) * 3,
         "diagnostic quick-fix skeleton must expose deterministic candidates per diagnostic");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Count_Action
           (Fixes,
            Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Navigate_To_Diagnostic) =
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
         "diagnostic quick-fix skeleton must expose one navigation action per diagnostic");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Count_Action
           (Fixes,
            Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Show_Explanation) =
         Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
         "diagnostic quick-fix skeleton must expose one explanation action per diagnostic");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Count_Source
           (Fixes, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) > 0,
         "diagnostic quick-fix skeleton must preserve source-family action counters");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Editable_Candidate_Count (Fixes) >= 1,
         "diagnostic quick-fix skeleton exposes explicit feed edit hints");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Has_Candidate (First_Fix)
         and then First_Fix.Fingerprint /= 0
         and then First_Fix.Has_Edit
         and then To_String (First_Fix.Replacement_Text) = "pragma Assert (False);",
         "diagnostic quick-fix skeleton must preserve explicit edit metadata");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Result_Count (Per_Diagnostic) >= 3,
         "diagnostic quick-fix skeleton must query candidates by diagnostic identity");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Fingerprint (Fixes) /= 0,
         "diagnostic quick-fix skeleton must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Rejected_Stale (Rejected_Fixes)
         and then Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Candidate_Count (Rejected_Fixes) = 0,
         "diagnostic quick-fix skeleton must withhold stale rejected candidates");
      Assert
        (Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Rejected_Candidate_Count (Rejected_Fixes) =
         Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Rejected_Index),
         "diagnostic quick-fix skeleton must preserve rejected candidate totals");
   end Test_Ada_Diagnostic_Quick_Fix_Skeleton;


   procedure Test_Ada_Diagnostic_Suppression_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Suppression_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Suppression_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generic_Base);
      Representation_Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      Empty_Expression_Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Empty_Generic_Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      Empty_Cross_Unit_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Colours : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model :=
        Editor.Ada_Semantic_Colour_Projection.Build
          (Empty_Expression_Diags, Empty_Generic_Diags,
           Empty_Cross_Unit_Diags, Representation_Diags);
      Produced : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("suppression.ads", 81, 82, 83, 84,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("suppression.ads", 81, 82, 83, 84,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("suppression.ads", 81, 82, 84, 84,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected_Guarded : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale, Colours);
      Accepted_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Accepted_Guarded);
      Rejected_Feed : constant Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model :=
        Editor.Ada_Semantic_Diagnostic_Feed.Build (Rejected_Guarded);
      Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Accepted_Feed);
      Rejected_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model :=
        Editor.Ada_Semantic_Diagnostic_Index.Build (Rejected_Feed);
      First_Index : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry :=
        Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, 1);
      Suppress_Rules : Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule_Set;
      Baseline_Rules : Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule_Set;
   begin
      Editor.Ada_Diagnostic_Suppression_Baseline.Add_Rule
        (Suppress_Rules,
         Editor.Ada_Diagnostic_Suppression_Baseline.Make_Rule
           (Kind     => Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_By_Index_Id,
            Index_Id => First_Index.Id,
            Reason   => "intentional local suppression for deterministic regression"));
      Editor.Ada_Diagnostic_Suppression_Baseline.Add_Rule
        (Baseline_Rules,
         Editor.Ada_Diagnostic_Suppression_Baseline.Make_Rule
           (Kind                   => Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Baseline_By_Diagnostic_Fingerprint,
            Diagnostic_Fingerprint => First_Index.Diagnostic.Fingerprint,
            Reason                 => "baseline known representation diagnostic"));

      declare
         Model : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Model :=
           Editor.Ada_Diagnostic_Suppression_Baseline.Build (Index, Suppress_Rules);
         Baseline_Model : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Model :=
           Editor.Ada_Diagnostic_Suppression_Baseline.Build (Index, Baseline_Rules);
         Rejected_Model : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Model :=
           Editor.Ada_Diagnostic_Suppression_Baseline.Build (Rejected_Index, Suppress_Rules);
         First_Entry : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry :=
           Editor.Ada_Diagnostic_Suppression_Baseline.First_For_Diagnostic (Model, First_Index.Id);
         Baseline_Entry : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry :=
           Editor.Ada_Diagnostic_Suppression_Baseline.First_For_Diagnostic (Baseline_Model, First_Index.Id);
         Suppressed : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Result_Set :=
           Editor.Ada_Diagnostic_Suppression_Baseline.Entries_For_Status
             (Model, Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Suppressed);
         Baselined : constant Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Result_Set :=
           Editor.Ada_Diagnostic_Suppression_Baseline.Entries_For_Status
             (Baseline_Model, Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Baselined);
      begin
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Rule_Count (Suppress_Rules) = 1
            and then Editor.Ada_Diagnostic_Suppression_Baseline.Rule_Count (Baseline_Rules) = 1,
            "diagnostic suppression baseline must retain deterministic rule metadata");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Rule_Set_Fingerprint (Suppress_Rules) /= 0
            and then Editor.Ada_Diagnostic_Suppression_Baseline.Rule_Set_Fingerprint (Baseline_Rules) /= 0,
            "diagnostic suppression baseline rules must produce deterministic fingerprints");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Current (Model),
            "diagnostic suppression baseline must accept current diagnostic indexes");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Entry_Count (Model) =
            Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index),
            "diagnostic suppression baseline must preserve indexed diagnostic totals");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Has_Entry (First_Entry)
            and then First_Entry.Status =
              Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Suppressed
            and then First_Entry.Applied_Rule /=
              Editor.Ada_Diagnostic_Suppression_Baseline.No_Diagnostic_Suppression_Rule,
            "diagnostic suppression baseline must classify matched suppression rules");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Suppressed_Entry_Count (Model) >= 1
            and then Editor.Ada_Diagnostic_Suppression_Baseline.Result_Count (Suppressed) >= 1,
            "diagnostic suppression baseline must expose suppressed diagnostic entries");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Has_Entry (Baseline_Entry)
            and then Baseline_Entry.Status =
              Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Baselined
            and then Editor.Ada_Diagnostic_Suppression_Baseline.Baselined_Entry_Count (Baseline_Model) >= 1
            and then Editor.Ada_Diagnostic_Suppression_Baseline.Result_Count (Baselined) >= 1,
            "diagnostic suppression baseline must expose baselined diagnostic entries");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Count_Source
              (Model, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) > 0,
            "diagnostic suppression baseline must preserve source-family counters");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Count_Severity
              (Model, Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error) =
            Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index),
            "diagnostic suppression baseline must preserve severity counters");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Fingerprint (Model) /= 0,
            "diagnostic suppression baseline must produce a deterministic fingerprint");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Rejected_Stale (Rejected_Model)
            and then Editor.Ada_Diagnostic_Suppression_Baseline.Entry_Count (Rejected_Model) = 0,
            "diagnostic suppression baseline must withhold stale rejected entries");
         Assert
           (Editor.Ada_Diagnostic_Suppression_Baseline.Rejected_Entry_Count (Rejected_Model) =
            Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Rejected_Index),
            "diagnostic suppression baseline must preserve rejected entry totals");
      end;
   end Test_Ada_Diagnostic_Suppression_Baseline;




   overriding function Name (T : Diagnostics_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Diagnostics");
   end Name;

   overriding procedure Register_Tests (T : in out Diagnostics_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Diagnostic_Navigation'Access, Name => "Ada diagnostic navigation provides deterministic first next previous severity filtered targets");
      Add_Test (Routine => Test_Ada_Diagnostic_Panel_Projection'Access, Name => "Ada diagnostic panel projection groups guarded semantic diagnostics into stable rows");
      Add_Test
        (Routine => Test_Ada_Diagnostic_Status_Line'Access,
         Name => "Ada diagnostic status-line summary projects guarded semantic diagnostic totals");
      Add_Test
        (Routine => Test_Ada_Diagnostic_Quick_Fix_Skeleton'Access,
         Name => "Ada diagnostic quick-fix skeleton projects non-mutating semantic diagnostic actions");
      Add_Test
        (Routine => Test_Ada_Diagnostic_Provenance'Access,
         Name => "Ada diagnostic provenance explains guarded semantic diagnostic source chains");
      Add_Test
        (Routine => Test_Ada_Diagnostic_Suppression_Baseline'Access,
         Name => "Ada diagnostic suppression baseline classifies diagnostics without mutating buffers");
   end Register_Tests;

end Editor.Syntax_Semantics.Diagnostics_Tests;
