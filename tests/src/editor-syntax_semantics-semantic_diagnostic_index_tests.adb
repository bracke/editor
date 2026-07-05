with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Syntax;
with Editor.Syntax_Semantics;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Use_Visibility;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Call_Candidates;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Call_Profile_Filters;
with Editor.Ada_Call_Resolution;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Expected_Call_Filters;
with Editor.Ada_Implicit_Conversions;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Type_Graph;
with Editor.Ada_Private_View_Visibility;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Limited_View_Rules;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Record_Layout_Validation;
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
with Editor.Ada_Symbol_Resolver;
with Editor.Ada_Project_Index;
with Editor.Outline;
with Editor.Outline_Extractor;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings;
with Ada.Strings.Maps; use Ada.Strings.Maps;
with Ada.Strings.Fixed;
with System.WCh_Con; use System.WCh_Con;


--  Generated use-type compatibility for activated full suite.
use type Editor.Ada_Limited_View_Rules.Limited_View_Status;
use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
use type Editor.Ada_Representation_Legality.Address_Value_Status;
use type Editor.Syntax.Syntax_Kind;
use type Editor.Syntax.Token_Kind;
use type Editor.Syntax.Lexical_State;
use type Editor.Syntax.Token_Span;
use type Editor.Syntax.Token_Span_Array;
use type Editor.Syntax_Semantics.Semantic_Map;
use type Editor.Ada_Language_Model.Symbol_Kind;
use type Editor.Ada_Language_Model.Statement_Kind;
use type Editor.Ada_Language_Model.Symbol_Id;
use type Editor.Ada_Language_Model.Scope_Id;
use type Editor.Ada_Language_Model.Source_Range;
use type Editor.Ada_Language_Model.Declaration_Flags;
use type Editor.Ada_Language_Model.Symbol_Info;
use type Editor.Ada_Language_Model.Executable_Binding_Kind;
use type Editor.Ada_Language_Model.Executable_Binding_Info;
use type Editor.Ada_Language_Model.Visibility_Clause_Kind;
use type Editor.Ada_Language_Model.Visibility_Clause_Info;
use type Editor.Ada_Language_Model.Generic_Actual_Info;
use type Editor.Ada_Language_Model.Profile_Parameter_Mode;
use type Editor.Ada_Language_Model.Profile_Parameter_Info;
use type Editor.Ada_Language_Model.Generic_Formal_Type_Family;
use type Editor.Ada_Language_Model.Generic_Formal_Type_Info;
use type Editor.Ada_Language_Model.Pragma_Placement_Kind;
use type Editor.Ada_Language_Model.Pragma_Info;
use type Editor.Ada_Language_Model.Representation_Source_Form;
use type Editor.Ada_Language_Model.Representation_Clause_Kind;
use type Editor.Ada_Language_Model.Representation_Clause_Info;
use type Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
use type Editor.Ada_Language_Model.Representation_Component_Info;
use type Editor.Ada_Language_Model.Legality_Diagnostic_Severity;
use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
use type Editor.Ada_Language_Model.Freezing_Point_Kind;
use type Editor.Ada_Language_Model.Freezing_Point_Info;
use type Editor.Ada_Language_Model.Legality_Diagnostic_Info;
use type Editor.Ada_Language_Model.Analysis_Result;
use type Editor.Ada_Syntax_Tree.Node_Kind;
use type Editor.Ada_Syntax_Tree.Node_Id;
use type Editor.Ada_Syntax_Tree.Source_Range;
use type Editor.Ada_Syntax_Tree.Node_Info;
use type Editor.Ada_Syntax_Tree.Tree_Type;
use type Editor.Ada_Declarative_Regions.Region_Kind;
use type Editor.Ada_Declarative_Regions.Region_Id;
use type Editor.Ada_Declarative_Regions.Region_Info;
use type Editor.Ada_Declarative_Regions.Region_Model;
use type Editor.Ada_Direct_Visibility.Declaration_Kind;
use type Editor.Ada_Direct_Visibility.Declaration_Id;
use type Editor.Ada_Direct_Visibility.Lookup_Status;
use type Editor.Ada_Direct_Visibility.Declaration_Info;
use type Editor.Ada_Direct_Visibility.Lookup_Result;
use type Editor.Ada_Direct_Visibility.Visibility_Model;
use type Editor.Ada_Use_Visibility.Use_Clause_Kind;
use type Editor.Ada_Use_Visibility.Use_Clause_Id;
use type Editor.Ada_Use_Visibility.Use_Clause_Info;
use type Editor.Ada_Use_Visibility.Use_Visibility_Model;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Id;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Info;
use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Kind;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Status;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Id;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Info;
use type Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
use type Editor.Ada_Call_Candidates.Candidate_Source;
use type Editor.Ada_Call_Candidates.Call_Candidate_Status;
use type Editor.Ada_Call_Candidates.Call_Candidate_Id;
use type Editor.Ada_Call_Candidates.Call_Candidate_Info;
use type Editor.Ada_Call_Candidates.Call_Candidate_Model;
use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Status;
use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id;
use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Id;
use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info;
use type Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Status;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Id;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Info;
use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
use type Editor.Ada_Call_Resolution.Call_Resolution_Info;
use type Editor.Ada_Call_Resolution.Call_Resolution_Model;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Kind;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Info;
use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Id;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info;
use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model;
use type Editor.Ada_Implicit_Conversions.Implicit_Conversion_Status;
use type Editor.Ada_Implicit_Conversions.Implicit_Conversion_Info;
use type Editor.Ada_Static_Expressions.Static_Value_Status;
use type Editor.Ada_Static_Expressions.Static_Value_Info;
use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Id;
use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Info;
use type Editor.Ada_Static_Expressions.Static_Modular_Type_Id;
use type Editor.Ada_Static_Expressions.Static_Modular_Type_Info;
use type Editor.Ada_Static_Expressions.Static_Enumeration_Literal_Id;
use type Editor.Ada_Static_Expressions.Static_Enumeration_Literal_Info;
use type Editor.Ada_Static_Expressions.Static_Type_Bound_Id;
use type Editor.Ada_Static_Expressions.Static_Type_Bound_Info;
use type Editor.Ada_Static_Expressions.Static_Binding_Id;
use type Editor.Ada_Static_Expressions.Static_Binding_Kind;
use type Editor.Ada_Static_Expressions.Static_Binding_Info;
use type Editor.Ada_Static_Expressions.Static_Model;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Kind;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Status;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Info;
use type Editor.Ada_Generic_Contracts.Generic_Instance_Status;
use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
use type Editor.Ada_Generic_Contracts.Generic_Instance_Info;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
use type Editor.Ada_Generic_Contracts.Generic_Formal_Actual_Kind_Match;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Id;
use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info;
use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Status;
use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id;
use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info;
use type Editor.Ada_Generic_Contracts.Generic_Contract_Model;
use type Editor.Ada_Subtype_Compatibility.Numeric_Family;
use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
use type Editor.Ada_Subtype_Compatibility.Compatibility_Info;
use type Editor.Ada_Type_Graph.Type_Category;
use type Editor.Ada_Type_Graph.Type_Relation_Status;
use type Editor.Ada_Type_Graph.Type_View_Status;
use type Editor.Ada_Type_Graph.Type_Id;
use type Editor.Ada_Type_Graph.Type_Info;
use type Editor.Ada_Type_Graph.Compatibility_Status;
use type Editor.Ada_Type_Graph.Type_Model;
use type Editor.Ada_Private_View_Visibility.Private_View_Status;
use type Editor.Ada_Private_View_Visibility.Private_View_Context_Status;
use type Editor.Ada_Private_View_Visibility.Private_View_Id;
use type Editor.Ada_Private_View_Visibility.Private_View_Info;
use type Editor.Ada_Private_View_Visibility.Private_View_Model;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry_Id;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Source;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Severity;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry;
use type Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Model;
use type Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key;
use type Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Status;
use type Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Id;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Status;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model;
use type Editor.Ada_Semantic_Diagnostic_Index.Feed_Entry;
use type Editor.Ada_Semantic_Diagnostic_Index.Feed_Severity;
use type Editor.Ada_Semantic_Diagnostic_Index.Feed_Source;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Status;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Result;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Set;
use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
use type Editor.Ada_Symbol_Resolver.Resolution_Result;
use type Editor.Ada_Project_Index.Indexed_File_Key;
use type Editor.Ada_Project_Index.Index_State;
use type Editor.Ada_Project_Index.Indexed_Unit_Role;
use type Editor.Ada_Project_Index.Indexed_Unit;
use type Editor.Ada_Project_Index.Unit_Resolution_Result;
use type Editor.Ada_Project_Index.Indexed_Symbol;
use type Editor.Ada_Project_Index.Index_Resolution_Result;
use type Editor.Ada_Project_Index.Unique_Target_Result;
use type Editor.Ada_Project_Index.Navigation_Target_Status;
use type Editor.Ada_Project_Index.Navigation_Candidate_Result;
use type Editor.Outline.Outline_Item_Kind;
use type Editor.Outline.Outline_Target_Kind;
use type Editor.Outline.Outline_Refresh_Source;
use type Editor.Outline.Outline_Refresh_Status;
use type Editor.Outline.Outline_Source_Class;
use type Editor.Outline.Outline_Freshness;
use type Editor.Outline.Outline_Snapshot_Identity;
use type Editor.Outline.Outline_Refresh_Failure_Kind;
use type Editor.Outline.Outline_Refresh_Result;
use type Editor.Outline.Outline_Item;
use type Editor.Outline.Outline_Item_Array;
use type Editor.Outline.Outline_State;
use type Editor.Outline.Outline_Summary;
use type Editor.Outline_Extractor.Extraction_Status;
use type Editor.Outline_Extractor.Extraction_Failure_Kind;
use type Editor.Outline_Extractor.Buffer_Text_Snapshot;
use type Editor.Outline_Extractor.Extraction_Result;

package body Editor.Syntax_Semantics.Semantic_Diagnostic_Index_Tests is

   procedure Test_Ada_Semantic_Diagnostic_Snapshot_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Snapshot_Guard_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Snapshot_Guard_Checks;";
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
          ("snapshot.ads", 10, 20, 30, 40,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("snapshot.ads", 10, 20, 30, 40,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale_Revision : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("snapshot.ads", 10, 21, 30, 40,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Accepted : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Current, Colours);
      Rejected : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Guarded_Semantic_Diagnostic_Model :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Build
          (Produced, Stale_Revision, Colours);
   begin
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Accepted (Accepted),
         "semantic diagnostic guards must accept matching snapshot keys");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Entry_Count (Accepted) =
         Editor.Ada_Semantic_Colour_Projection.Entry_Count (Colours),
         "accepted semantic diagnostic snapshots must retain projected entries");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Rejected (Rejected),
         "semantic diagnostic guards must reject stale snapshot keys");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Status (Rejected) =
         Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Revision_Mismatch,
         "semantic diagnostic guards must classify the stale revision reason");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Entry_Count (Rejected) = 0,
         "rejected semantic diagnostic snapshots must not expose stale entries");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Rejected_Entry_Count (Rejected) =
         Editor.Ada_Semantic_Colour_Projection.Entry_Count (Colours),
         "rejected semantic diagnostic snapshots must count withheld stale entries");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Fingerprint (Accepted) /= 0
         and then Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Fingerprint (Rejected) /= 0,
         "semantic diagnostic guards must retain deterministic fingerprints");
   end Test_Ada_Semantic_Diagnostic_Snapshot_Guards;

   procedure Test_Ada_Semantic_Diagnostic_Feed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Feed_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Feed_Checks;";
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
          ("feed.ads", 17, 18, 19, 20,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("feed.ads", 17, 18, 19, 20,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("feed.ads", 17, 18, 19, 21,
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
   begin
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Current (Accepted_Feed),
         "semantic diagnostic feed must accept current guarded projections");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Accepted_Feed) =
         Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Entry_Count (Accepted_Guarded),
         "semantic diagnostic feed must preserve accepted guarded entries");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Accepted_Feed) =
         Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Error_Count (Accepted_Guarded),
         "semantic diagnostic feed must preserve accepted error totals");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Count_Source
           (Accepted_Feed,
            Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) > 0,
         "semantic diagnostic feed must retain diagnostic source family metadata");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Fingerprint (Accepted_Feed) /= 0,
         "semantic diagnostic feed must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Rejected_Feed),
         "semantic diagnostic feed must preserve stale guarded rejection status");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Rejected_Feed) = 0,
         "semantic diagnostic feed must not expose stale rejected entries");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Rejected_Feed) =
         Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Rejected_Entry_Count (Rejected_Guarded),
         "semantic diagnostic feed must preserve rejected-entry totals");
   end Test_Ada_Semantic_Diagnostic_Feed;

   procedure Test_Ada_Semantic_Diagnostic_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Index_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Index_Checks;";
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
          ("index.ads", 21, 22, 23, 24,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Current : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("index.ads", 21, 22, 23, 24,
           Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours));
      Stale : constant Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Diagnostic_Snapshot_Key :=
        Editor.Ada_Semantic_Diagnostic_Snapshot_Guards.Make_Key
          ("index.ads", 21, 22, 24, 24,
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
      Error_Results : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Set :=
        Editor.Ada_Semantic_Diagnostic_Index.Query_Severity
          (Index, Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error);
      Representation_Results : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Set :=
        Editor.Ada_Semantic_Diagnostic_Index.Query_Source
          (Index, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation);
      Range_Results : constant Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Query_Set :=
        Editor.Ada_Semantic_Diagnostic_Index.Query_Range (Index, 6, 9);
   begin
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Current (Index),
         "semantic diagnostic index must accept current semantic feeds");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) =
         Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Accepted_Feed),
         "semantic diagnostic index must preserve feed entry count");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index) =
         Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Accepted_Feed),
         "semantic diagnostic index must preserve severity totals");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Query_Count (Error_Results) =
         Editor.Ada_Semantic_Diagnostic_Index.Error_Count (Index),
         "semantic diagnostic index must query diagnostics by severity");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Query_Count (Representation_Results) > 0,
         "semantic diagnostic index must query diagnostics by semantic source family");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Query_Count (Range_Results) > 0,
         "semantic diagnostic index must query diagnostics by source-line range");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index) /= 0,
         "semantic diagnostic index must produce a deterministic fingerprint");
      Assert
        (Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Rejected_Index)
         and then Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Rejected_Index) = 0,
         "semantic diagnostic index must withhold stale rejected feed entries");
   end Test_Ada_Semantic_Diagnostic_Index;

   overriding function Name (T : SemanticDiagnosticIndex_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Semantic-Diagnostic-Index-Tests");
   end Name;

   overriding procedure Register_Tests (T : in out SemanticDiagnosticIndex_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Semantic_Diagnostic_Snapshot_Guards'Access, Name => "Ada semantic diagnostic snapshot guards reject stale analysis overlays");
      Add_Test (Routine => Test_Ada_Semantic_Diagnostic_Feed'Access, Name => "Ada semantic diagnostic feed unifies guarded semantic diagnostics for IDE consumers");
      Add_Test (Routine => Test_Ada_Semantic_Diagnostic_Index'Access, Name => "Ada semantic diagnostic index queries guarded semantic diagnostics for IDE consumers");
   end Register_Tests;

end Editor.Syntax_Semantics.Semantic_Diagnostic_Index_Tests;
