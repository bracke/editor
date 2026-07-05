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

package body Editor.Syntax_Semantics.Semantic_Colour_Tests is




   procedure Test_Analysis_Binding_Semantic_Colouring_Precision
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Map      : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Call_Target, "Run");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Select_Entry_Call, "Ready");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Qualified_Expression_Target, "Packet");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Accept_Parameter, "Item");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Entry_Family_Index, "Index");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Label_Declaration, "Retry");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Selected_Component, "Field");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Attribute_Prefix, "Prefix");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Run") =
           Editor.Syntax.Subprogram_Identifier,
         "unresolved call targets should colour as callable syntax roles");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Ready") =
           Editor.Syntax.Subprogram_Identifier,
         "entry-call alternatives should colour as callable syntax roles");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Packet") =
           Editor.Syntax.Type_Identifier,
         "qualified-expression targets should colour as type-like syntax roles");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Item") =
           Editor.Syntax.Parameter_Identifier,
         "accept parameters should colour as value-like local bindings");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Index") =
           Editor.Syntax.Parameter_Identifier,
         "entry-family indexes should colour as value-like local bindings");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Retry") =
           Editor.Syntax.Parameter_Identifier,
         "label declarations should colour only as bounded local bindings");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Field") =
           Editor.Syntax.Identifier,
         "unresolved selected components must not become global semantic symbols");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Prefix") =
           Editor.Syntax.Identifier,
         "unresolved attribute prefixes must degrade to ordinary identifiers");
   end Test_Analysis_Binding_Semantic_Colouring_Precision;





   procedure Test_Semantic_Colouring_Expanded_Grammar_Precision
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Map      : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Assignment_Target, "Target");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Call_Target, "Target_Call");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Return_Object_Defining_Name, "Result_Object");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Named_Actual, "Param");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Generic_Actual_Selector, "Formal_Type");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Aggregate_Component_Selector, "Field");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Delta_Aggregate_Component, "Delta_Field");
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Label_Declaration, "Loop_Label");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Target") =
           Editor.Syntax.Parameter_Identifier,
         "assignment targets should remain value-like local semantic roles");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Target_Call") =
           Editor.Syntax.Subprogram_Identifier,
         "call targets should remain callable semantic roles");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Result_Object") =
           Editor.Syntax.Parameter_Identifier,
         "extended-return object defining names should colour as local values");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Param") =
           Editor.Syntax.Identifier,
         "call named-actual selectors should not become value-like globals");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Formal_Type") =
           Editor.Syntax.Identifier,
         "generic actual selectors should remain selector syntax without resolver targets");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Field") =
           Editor.Syntax.Identifier,
         "aggregate component selectors should not colour as expression values");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Delta_Field") =
           Editor.Syntax.Identifier,
         "delta aggregate component selectors should not colour as expression values");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Loop_Label") =
           Editor.Syntax.Parameter_Identifier,
         "labels should continue to use the bounded local-value semantic bucket");
   end Test_Semantic_Colouring_Expanded_Grammar_Precision;



   procedure Test_Ada_Semantic_Colour_Diagnostics_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Semantic_Colour_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word'Bit_Order use Low_Order_First;" & ASCII.LF &
        "   for Word'Scalar_Storage_Order use High_Order_First;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word'Atomic use True;" & ASCII.LF &
        "   for Word'Atomic use False;" & ASCII.LF &
        "end Semantic_Colour_Checks;";
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
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generics_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generics_Base);
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
      First : constant Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_Entry :=
        Editor.Ada_Semantic_Colour_Projection.Entry_At (Colours, 1);
   begin
      Assert
        (Editor.Ada_Semantic_Colour_Projection.Entry_Count (Colours) >=
           Editor.Ada_Representation_Diagnostics.Diagnostic_Count (Representation_Diags),
         "semantic colour projection must retain representation diagnostic overlays");
      Assert
        (Editor.Ada_Semantic_Colour_Projection.Count_Source
           (Colours, Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation) >= 1,
         "semantic colour projection must retain the diagnostic source family");
      Assert
        (Editor.Ada_Semantic_Colour_Projection.Count_Token
           (Colours, Editor.Syntax.Diagnostic_Error) +
         Editor.Ada_Semantic_Colour_Projection.Count_Token
           (Colours, Editor.Syntax.Diagnostic_Warning) >= 1,
         "semantic colour projection must map severities to diagnostic token buckets");
      Assert
        (First.Token = Editor.Syntax.Diagnostic_Error
         or else First.Token = Editor.Syntax.Diagnostic_Warning
         or else First.Token = Editor.Syntax.Identifier,
         "semantic colour projection must expose render-safe syntax token kinds");
      Assert
        (Editor.Ada_Semantic_Colour_Projection.Fingerprint (Colours) /= 0,
         "semantic colour projection must retain deterministic fingerprints");
   end Test_Ada_Semantic_Colour_Diagnostics_Projection;



   procedure Test_Syntax_Semantics_New_Metadata_Consumers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Source_Span : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
      Target_Id : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Target_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         Name => "Packet",
         Kind => Editor.Ada_Language_Model.Symbol_Type,
         Source_Span => Source_Span);

      Editor.Ada_Language_Model.Add_Visibility_Clause
        (Analysis,
         Kind => Editor.Ada_Language_Model.Visibility_Limited_With_Clause,
         Name => "Ada.Text_IO",
         Source_Span => Source_Span,
         Is_Context_Clause => True,
         Has_Limited_Modifier => True);
      Editor.Ada_Language_Model.Add_Visibility_Clause
        (Analysis,
         Kind => Editor.Ada_Language_Model.Visibility_Private_With_Clause,
         Name => "Shared.Hidden",
         Source_Span => Source_Span,
         Is_Context_Clause => True,
         Has_Private_Modifier => True);
      Editor.Ada_Language_Model.Add_Visibility_Clause
        (Analysis,
         Kind => Editor.Ada_Language_Model.Visibility_Use_Package_Clause,
         Name => "Shared.Helpers",
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Visibility_Clause
        (Analysis,
         Kind => Editor.Ada_Language_Model.Visibility_Use_All_Type_Clause,
         Name => "Shared.Count",
         Source_Span => Source_Span);

      Editor.Ada_Language_Model.Add_Generic_Formal_Type_Metadata
        (Analysis,
         Formal_Symbol => Editor.Ada_Language_Model.No_Symbol,
         Name => "Element_Type",
         Family => Editor.Ada_Language_Model.Generic_Formal_Type_Private,
         Has_Private => True,
         Source_Span => Source_Span);

      Editor.Ada_Language_Model.Add_Profile_Parameter_Metadata
        (Analysis,
         Owner_Symbol => Editor.Ada_Language_Model.No_Symbol,
         Parameter_Symbol => Editor.Ada_Language_Model.No_Symbol,
         Name => "Mode",
         Mode => Editor.Ada_Language_Model.Profile_Parameter_In_Out,
         Type_Text => "Integer",
         Group_Index => 1,
         Group_Position => 1,
         Group_Name_Count => 1,
         Source_Span => Source_Span);

      Editor.Ada_Language_Model.Add_Pragma_Metadata
        (Analysis,
         Name => "Inline",
         Placement => Editor.Ada_Language_Model.Pragma_Placement_Declaration,
         Target_Name => "Run",
         Argument_Count => 1,
         Source_Span => Source_Span);

      Editor.Ada_Language_Model.Add_Representation_Clause
        (Analysis,
         Target_Symbol => Target_Id,
         Target_Name => "Packet",
         Kind => Editor.Ada_Language_Model.Representation_Size_Clause,
         Attribute_Name => "Size",
         Item_Text => "32",
         Source_Form => Editor.Ada_Language_Model.Representation_Source_Attribute_Definition,
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Representation_Clause
        (Analysis,
         Target_Symbol => Target_Id,
         Target_Name => "Packet",
         Kind => Editor.Ada_Language_Model.Representation_Other_Clause,
         Attribute_Name => "Volatile",
         Item_Text => "True",
         Source_Form => Editor.Ada_Language_Model.Representation_Source_Aspect,
         Source_Span => Source_Span);

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);

      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Ada.Text_IO") =
              Editor.Syntax.Package_Identifier,
              "context-clause package names should feed semantic colouring");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Hidden") =
              Editor.Syntax.Package_Identifier,
              "context-clause leaves should feed semantic colouring");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Helpers") =
              Editor.Syntax.Package_Identifier,
              "use package names should feed semantic colouring");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Count") =
              Editor.Syntax.Type_Identifier,
              "use all type names should feed semantic colouring as type-like names");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Element_Type") =
              Editor.Syntax.Generic_Formal,
              "generic formal type detail metadata should feed semantic colouring");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Mode") =
              Editor.Syntax.Parameter_Identifier,
              "profile parameter mode metadata should feed semantic colouring");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Inline") =
              Editor.Syntax.Pragma_Name,
              "pragma metadata identifiers should feed semantic colouring");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Run") =
              Editor.Syntax.Parameter_Identifier,
              "pragma target metadata should feed semantic colouring conservatively");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Packet") =
              Editor.Syntax.Type_Identifier,
              "representation targets with symbols should keep their resolved semantic kind");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Size") =
              Editor.Syntax.Attribute,
              "attribute-definition representation metadata should feed the attribute colouring bucket");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Volatile") =
              Editor.Syntax.Aspect_Name,
              "aspect-source representation metadata should feed the aspect colouring bucket");
   end Test_Syntax_Semantics_New_Metadata_Consumers;



   procedure Test_Syntax_Semantics_Metadata_Does_Not_Downgrade_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Source_Span : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
      Ready_Id : Editor.Ada_Language_Model.Symbol_Id;
      Count_Id : Editor.Ada_Language_Model.Symbol_Id;
      Inline_Id : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Ready_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         Name => "Ready",
         Kind => Editor.Ada_Language_Model.Symbol_Function,
         Source_Span => Source_Span);
      Count_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         Name => "Shared.Count",
         Kind => Editor.Ada_Language_Model.Symbol_Type,
         Source_Span => Source_Span);
      Inline_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         Name => "Inline",
         Kind => Editor.Ada_Language_Model.Symbol_Procedure,
         Source_Span => Source_Span);

      pragma Assert (Ready_Id /= Editor.Ada_Language_Model.No_Symbol);
      pragma Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol);
      pragma Assert (Inline_Id /= Editor.Ada_Language_Model.No_Symbol);

      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis, Editor.Ada_Language_Model.Binding_Assignment_Target, "Ready");
      Editor.Ada_Language_Model.Add_Visibility_Clause
        (Analysis,
         Kind => Editor.Ada_Language_Model.Visibility_Use_All_Type_Clause,
         Name => "Shared.Count",
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Pragma_Metadata
        (Analysis,
         Name => "Inline",
         Placement => Editor.Ada_Language_Model.Pragma_Placement_Declaration,
         Target_Name => "Ready",
         Argument_Count => 1,
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Profile_Parameter_Metadata
        (Analysis,
         Owner_Symbol => Editor.Ada_Language_Model.No_Symbol,
         Parameter_Symbol => Editor.Ada_Language_Model.No_Symbol,
         Name => "Ready",
         Mode => Editor.Ada_Language_Model.Profile_Parameter_In,
         Type_Text => "Boolean",
         Source_Span => Source_Span);

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Ready") =
           Editor.Syntax.Subprogram_Identifier,
         "metadata-only executable/profile/pragma fallbacks must not downgrade a concrete callable symbol");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Shared.Count") =
           Editor.Syntax.Type_Identifier,
         "use-clause metadata must preserve a concrete selected type symbol");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Count") =
           Editor.Syntax.Type_Identifier,
         "qualified-leaf lookup must remain available for the concrete selected type symbol");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Inline") =
           Editor.Syntax.Subprogram_Identifier,
         "pragma-name metadata must not replace an existing subprogram symbol with a pragma bucket");
   end Test_Syntax_Semantics_Metadata_Does_Not_Downgrade_Symbols;


   overriding function Name (T : Semantic_Colour_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Semantic_Colour");
   end Name;

   overriding procedure Register_Tests (T : in out Semantic_Colour_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Analysis_Binding_Semantic_Colouring_Precision'Access, Name => "analysis executable bindings colour precise syntax roles conservatively");
      Add_Test (Routine => Test_Semantic_Colouring_Expanded_Grammar_Precision'Access, Name => "semantic colouring keeps expanded grammar selectors conservative");
      Add_Test (Routine => Test_Ada_Semantic_Colour_Diagnostics_Projection'Access, Name => "Ada semantic colour projection maps semantic diagnostics to render-safe overlays");
      Add_Test (Routine => Test_Syntax_Semantics_New_Metadata_Consumers'Access, Name => "semantic colouring consumes newer Ada language-model metadata families");
      Add_Test (Routine => Test_Syntax_Semantics_Metadata_Does_Not_Downgrade_Symbols'Access, Name => "semantic colouring preserves concrete symbol kinds over metadata fallbacks");
   end Register_Tests;

end Editor.Syntax_Semantics.Semantic_Colour_Tests;
