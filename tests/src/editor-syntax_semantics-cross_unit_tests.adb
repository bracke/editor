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
with Editor.Ada_Freezing_Points;
with Editor.Ada_Freezing_Interactions;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Record_Layout_Exact_Validation;
with Editor.Ada_Stream_Attribute_Profile_Conformance;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Generic_Formal_Type_Conformance;
with Editor.Ada_Generic_Formal_Package_Nested_Conformance;
with Editor.Ada_Generic_Formal_Package_Substitutions;
with Editor.Ada_Generic_Renaming_Visibility;
with Editor.Ada_Generic_Object_Default_Type_Conformance;
with Editor.Ada_Generic_Contract_Diagnostics;
with Editor.Ada_Cross_Unit_Diagnostics;
with Editor.Ada_Representation_Diagnostics;
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
with Editor.Ada_Overload_Ambiguity_Diagnostics;
with Editor.Ada_Overload_Ranking;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Tasking_Protected_Legality;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Cross_Unit_Representation_Targets;
with Editor.Ada_Selected_Representation_Targets;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Cross_Unit_Lookup_Integration;
with Editor.Ada_Limited_View_Rules;
with Editor.Ada_Private_With_Rules;
with Editor.Ada_Body_Spec_Conformance;
with Editor.Ada_Nested_Body_Spec_Conformance;
with Editor.Ada_Child_Unit_Visibility;
with Editor.Ada_Separate_Body_Stub_Rules;
with Editor.Ada_Expression_Types;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_View_Aware_Compatibility;
with Editor.Ada_Generic_View_Compatibility;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Token_Cursor;
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
use type Editor.Ada_Freezing_Points.Freezable_Kind;
use type Editor.Ada_Freezing_Points.Freezing_Cause;
use type Editor.Ada_Freezing_Points.Freezing_Status;
use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
use type Editor.Ada_Freezing_Points.Freezable_Id;
use type Editor.Ada_Freezing_Points.Freezable_Info;
use type Editor.Ada_Freezing_Points.Representation_Freeze_Info;
use type Editor.Ada_Freezing_Points.Freezing_Model;
use type Editor.Ada_Freezing_Interactions.Freezing_Interaction_Status;
use type Editor.Ada_Freezing_Interactions.Freezing_Interaction_Id;
use type Editor.Ada_Freezing_Interactions.Freezing_Interaction_Info;
use type Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
use type Editor.Ada_Representation_Legality.Address_Value_Status;
use type Editor.Ada_Representation_Legality.Interfacing_Value_Status;
use type Editor.Ada_Representation_Legality.Stream_Subprogram_Status;
use type Editor.Ada_Representation_Legality.Operational_Value_Status;
use type Editor.Ada_Representation_Legality.Representation_Value_Status;
use type Editor.Ada_Representation_Legality.Representation_Legality_Info;
use type Editor.Ada_Representation_Legality.Record_Component_Legality_Info;
use type Editor.Ada_Representation_Legality.Enumeration_Representation_Legality_Info;
use type Editor.Ada_Representation_Legality.Representation_Legality_Model;
use type Editor.Ada_Record_Layout_Validation.Record_Layout_Status;
use type Editor.Ada_Record_Layout_Validation.Record_Layout_Info;
use type Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
use type Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Status;
use type Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Info;
use type Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model;
use type Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Status;
use type Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Info;
use type Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model;
use type Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Status;
use type Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Value;
use type Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Info;
use type Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
use type Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Status;
use type Editor.Ada_Operational_Attribute_Rules.Operational_Boolean_Value;
use type Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Info;
use type Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
use type Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Status;
use type Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Info;
use type Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
use type Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Shape;
use type Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Status;
use type Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Info;
use type Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
use type Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Status;
use type Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Info;
use type Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status;
use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Id;
use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Info;
use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model;
use type Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Status;
use type Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Status;
use type Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Id;
use type Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Info;
use type Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Info;
use type Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
use type Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Status;
use type Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Info;
use type Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Id;
use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Severity;
use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Kind;
use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Info;
use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Id;
use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity;
use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Kind;
use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Info;
use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Id;
use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Severity;
use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Kind;
use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Info;
use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model;
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
use type Editor.Ada_Diagnostic_Navigation.Feed_Entry;
use type Editor.Ada_Diagnostic_Navigation.Feed_Severity;
use type Editor.Ada_Diagnostic_Navigation.Feed_Source;
use type Editor.Ada_Diagnostic_Navigation.Index_Entry;
use type Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target_Id;
use type Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Status;
use type Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Target;
use type Editor.Ada_Diagnostic_Navigation.Diagnostic_Navigation_Model;
use type Editor.Ada_Diagnostic_Panel_Projection.Feed_Entry;
use type Editor.Ada_Diagnostic_Panel_Projection.Feed_Severity;
use type Editor.Ada_Diagnostic_Panel_Projection.Feed_Source;
use type Editor.Ada_Diagnostic_Panel_Projection.Index_Entry;
use type Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row_Id;
use type Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Status;
use type Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Group_Kind;
use type Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Row;
use type Editor.Ada_Diagnostic_Panel_Projection.Diagnostic_Panel_Model;
use type Editor.Ada_Diagnostic_Status_Line.Feed_Entry;
use type Editor.Ada_Diagnostic_Status_Line.Feed_Severity;
use type Editor.Ada_Diagnostic_Status_Line.Feed_Source;
use type Editor.Ada_Diagnostic_Status_Line.Index_Entry;
use type Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Status;
use type Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Kind;
use type Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Target;
use type Editor.Ada_Diagnostic_Status_Line.Diagnostic_Status_Line_Model;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Feed_Entry;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Feed_Severity;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Feed_Source;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Index_Entry;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Candidate_Id;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Status;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Action_Kind;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Confidence;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Candidate;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Result_Set;
use type Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Diagnostic_Quick_Fix_Model;
use type Editor.Ada_Diagnostic_Provenance.Feed_Entry;
use type Editor.Ada_Diagnostic_Provenance.Feed_Severity;
use type Editor.Ada_Diagnostic_Provenance.Feed_Source;
use type Editor.Ada_Diagnostic_Provenance.Index_Entry;
use type Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Id;
use type Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Status;
use type Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Stage;
use type Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Item;
use type Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Result_Set;
use type Editor.Ada_Diagnostic_Provenance.Diagnostic_Provenance_Model;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Feed_Entry;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Feed_Severity;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Feed_Source;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Index_Entry;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule_Id;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Id;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Model_Status;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule_Kind;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry_Status;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Entry;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Rule_Set;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Result_Set;
use type Editor.Ada_Diagnostic_Suppression_Baseline.Diagnostic_Suppression_Model;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Expression_Info;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic_Id;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Severity;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Kind;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Result_Set;
use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
use type Editor.Ada_Overload_Ranking.Overload_Ranking_Id;
use type Editor.Ada_Overload_Ranking.Overload_Ranking_Status;
use type Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
use type Editor.Ada_Overload_Ranking.Overload_Ranking_Result_Set;
use type Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
use type Editor.Ada_Dispatching_Call_Legality.Expression_Info;
use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id;
use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Status;
use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Info;
use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Result_Set;
use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model;
use type Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Status;
use type Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Info;
use type Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model;
use type Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Status;
use type Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Id;
use type Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Info;
use type Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Kind;
use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Status;
use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Info;
use type Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Status;
use type Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Info;
use type Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Status;
use type Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Info;
use type Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Status;
use type Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Info;
use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status;
use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status;
use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Id;
use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Entry;
use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
use type Editor.Ada_Limited_View_Rules.Limited_View_Status;
use type Editor.Ada_Limited_View_Rules.Limited_View_Info;
use type Editor.Ada_Limited_View_Rules.Limited_View_Model;
use type Editor.Ada_Private_With_Rules.Private_With_Context;
use type Editor.Ada_Private_With_Rules.Private_With_Status;
use type Editor.Ada_Private_With_Rules.Private_With_Info;
use type Editor.Ada_Private_With_Rules.Private_With_Model;
use type Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Status;
use type Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info;
use type Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Conformance_Id;
use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Status;
use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Info;
use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Model;
use type Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context;
use type Editor.Ada_Child_Unit_Visibility.Child_Visibility_Status;
use type Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
use type Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
use type Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Status;
use type Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Info;
use type Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model;
use type Editor.Ada_Expression_Types.Expected_Type_Propagation_Status;
use type Editor.Ada_Expression_Types.Operator_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Concatenation_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Aggregate_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Conversion_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Conditional_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Membership_Range_Inference_Status;
use type Editor.Ada_Expression_Types.Target_Name_Inference_Status;
use type Editor.Ada_Expression_Types.Indexed_Slice_Inference_Status;
use type Editor.Ada_Expression_Types.Boolean_Context_Inference_Status;
use type Editor.Ada_Expression_Types.Raise_No_Return_Inference_Status;
use type Editor.Ada_Expression_Types.Allocator_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status;
use type Editor.Ada_Expression_Types.Dispatching_Call_Inference_Status;
use type Editor.Ada_Expression_Types.Call_Actual_Type_Resolution_Status;
use type Editor.Ada_Expression_Types.Parameter_Association_Inference_Status;
use type Editor.Ada_Expression_Types.Dereference_Access_Inference_Status;
use type Editor.Ada_Expression_Types.Attribute_Type_Inference_Status;
use type Editor.Ada_Expression_Types.Expression_Type_Status;
use type Editor.Ada_Expression_Types.Expression_Type_Id;
use type Editor.Ada_Expression_Types.Expression_Type_Info;
use type Editor.Ada_Expression_Types.Expression_Type_Model;
use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Id;
use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Severity;
use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Kind;
use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Info;
use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id;
use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info;
use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
use type Editor.Ada_Generic_View_Compatibility.Generic_View_Status;
use type Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Id;
use type Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info;
use type Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status;
use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id;
use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Info;
use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model;
use type Editor.Ada_Token_Cursor.Token_Kind;
use type Editor.Ada_Token_Cursor.Token_Info;
use type Editor.Ada_Token_Cursor.Production_Kind;
use type Editor.Ada_Token_Cursor.Production_Info;
use type Editor.Ada_Token_Cursor.Token_Stream;
use type Editor.Ada_Token_Cursor.Cursor;
use type Editor.Ada_Token_Cursor.Grammar_Result;
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

package body Editor.Syntax_Semantics.Cross_Unit_Tests is




   procedure Test_Language_Model_Separate_Body_Kind_And_Semantics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "separate (Parent.Child)" & ASCII.LF &
        "function Compute (Value : Integer) return Integer is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   return Value;" & ASCII.LF &
        "end Compute;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "compute.adb");
      Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compute");
      Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compute_Id);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Assert (Compute_Id /= Editor.Ada_Language_Model.No_Symbol,
              "separate function body should be indexed");
      Assert (Compute_Info.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body,
              "separate body declarations should use the explicit separate-body kind");
      Assert (Compute_Info.Flags.Is_Separate,
              "separate body kind should retain separate metadata");
      Assert (To_String (Compute_Info.Target_Name) = "Parent.Child",
              "separate body kind should retain parent target metadata");

      Editor.Syntax_Semantics.Clear (Map);
      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Compute") =
                Editor.Syntax.Subprogram_Identifier,
              "separate body names should still classify as callable symbols");
   end Test_Language_Model_Separate_Body_Kind_And_Semantics;



   procedure Test_Project_Index_Separate_Body_Parent_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child is" & ASCII.LF &
           "   procedure Compute;" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent.Child)" & ASCII.LF &
           "procedure Compute is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Compute;" & ASCII.LF,
           "compute.adb");
      Index      : Editor.Ada_Project_Index.Index_State;
      Body_Res   : Editor.Ada_Project_Index.Index_Resolution_Result;
      Parent_Res : Editor.Ada_Project_Index.Index_Resolution_Result;
      Saw_Separate_Body : Boolean := False;
      Saw_Parent_Spec   : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/compute.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);

      Body_Res := Editor.Ada_Project_Index.Resolve (Index, "Compute");
      if not Body_Res.Matches.Is_Empty then
         for I in Body_Res.Matches.First_Index .. Body_Res.Matches.Last_Index loop
            if Body_Res.Matches (I).Symbol.Kind =
                 Editor.Ada_Language_Model.Symbol_Separate_Body
              and then To_String (Body_Res.Matches (I).Symbol.Target_Name) =
                "Parent.Child"
            then
               Saw_Separate_Body := True;
            end if;
         end loop;
      end if;

      Parent_Res := Editor.Ada_Project_Index.Resolve (Index, "Parent.Child");
      if not Parent_Res.Matches.Is_Empty then
         for I in Parent_Res.Matches.First_Index .. Parent_Res.Matches.Last_Index loop
            if Parent_Res.Matches (I).Symbol.Kind =
                 Editor.Ada_Language_Model.Symbol_Package
              and then not Parent_Res.Matches (I).Symbol.Flags.Is_Body
            then
               Saw_Parent_Spec := True;
            end if;
         end loop;
      end if;

      Assert (Saw_Separate_Body,
              "project index should retain separate-body parent target metadata");
      Assert (Saw_Parent_Spec,
              "project index should resolve separate-body parent declarations for goto-spec");
   end Test_Project_Index_Separate_Body_Parent_Target;



   procedure Test_Project_Index_Child_Unit_Parent_Relationship_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child is" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Child_Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Parent_Target : Editor.Ada_Project_Index.Unique_Target_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Child_Analysis);

      Child_Target := Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
        (Index, "Parent.Child", Editor.Ada_Project_Index.Unit_Package_Spec);

      Assert (Child_Target.Available,
              "child unit should be indexed by normalized Ada unit name");

      Parent_Target := Editor.Ada_Project_Index.Resolve_Parent_Unit_Target
        (Index, Child_Target.Target);

      Assert (Parent_Target.Available
              and then To_String (Parent_Target.Target.Path) = "src/parent.ads",
              "child unit relationship lookup should resolve Parent.Child to indexed Parent spec");
   end Test_Project_Index_Child_Unit_Parent_Relationship_Target;




   procedure Test_Project_Index_Parent_Lists_Direct_Child_Units
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child is" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.ads");
      Grandchild_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child.Grandchild is" & ASCII.LF &
           "end Parent.Child.Grandchild;" & ASCII.LF,
           "parent-child-grandchild.ads");
      Sibling_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent.Sibling is" & ASCII.LF &
           "end Parent.Sibling;" & ASCII.LF,
           "parent-sibling.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Parent_Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Children : Editor.Ada_Project_Index.Unit_Resolution_Result;
      Package_Spec_Children : Editor.Ada_Project_Index.Unit_Resolution_Result;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child-grandchild.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Grandchild_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-sibling.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Sibling_Body_Analysis);

      Parent_Target := Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
        (Index, "Parent", Editor.Ada_Project_Index.Unit_Package_Spec);

      Assert (Parent_Target.Available,
              "parent package spec should be indexed before resolving child units");

      Children := Editor.Ada_Project_Index.Resolve_Child_Units
        (Index, Parent_Target.Target);
      Package_Spec_Children := Editor.Ada_Project_Index.Resolve_Child_Units
        (Index, Parent_Target.Target, Editor.Ada_Project_Index.Unit_Package_Spec);

      Assert (Natural (Children.Matches.Length) = 2,
              "direct child lookup should include immediate child units but not grandchildren");
      Assert (Natural (Package_Spec_Children.Matches.Length) = 1,
              "direct child lookup should support unit-role filtering");
      Assert (To_String (Package_Spec_Children.Matches.First_Element.Unit_Name) = "Parent.Child",
              "role-filtered child lookup should return the indexed child package spec");
   end Test_Project_Index_Parent_Lists_Direct_Child_Units;



   procedure Test_Ada_Cross_Unit_Semantic_Closure_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Child_Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Child is" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.ads");
      Child_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent.Child is" & ASCII.LF &
           "end Parent.Child;" & ASCII.LF,
           "parent-child.adb");
      Separate_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent.Child)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "worker.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Found_Spec_To_Body : Boolean := False;
      Found_Separate_Parent : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Child_Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-child.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Child_Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/worker.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);

      Assert (Editor.Ada_Cross_Unit_Closure.Link_Count (Closure) >= 5,
              "cross-unit closure should stage spec/body, child/parent, and separate-parent links");
      Assert (Editor.Ada_Cross_Unit_Closure.Spec_Body_Link_Count (Closure) >= 2,
              "cross-unit closure should include both spec-to-body and body-to-spec relationships");
      Assert (Editor.Ada_Cross_Unit_Closure.Child_Parent_Link_Count (Closure) >= 2,
              "cross-unit closure should include child-to-parent relationships for child units");
      Assert (Editor.Ada_Cross_Unit_Closure.Parent_Child_Link_Count (Closure) >= 1,
              "cross-unit closure should include parent-to-child relationships");
      Assert (Editor.Ada_Cross_Unit_Closure.Separate_Parent_Link_Count (Closure) = 1,
              "cross-unit closure should include the separate body parent relationship");
      Assert (Editor.Ada_Cross_Unit_Closure.Resolved_Count (Closure) >= 5,
              "cross-unit closure should resolve the indexed relationships deterministically");
      Assert (Editor.Ada_Cross_Unit_Closure.Fingerprint (Closure) /= 0,
              "cross-unit closure should produce a deterministic non-zero fingerprint");

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Link_Count (Closure) loop
         declare
            Link : constant Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Info :=
              Editor.Ada_Cross_Unit_Closure.Link_At (Closure, I);
         begin
            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Spec_To_Body
              and then To_String (Link.Source_Unit_Name) = "Parent.Child"
              and then Link.Status = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Resolved
              and then To_String (Link.Target_Path) = "src/parent-child.adb"
            then
               Found_Spec_To_Body := True;
            end if;

            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Separate_To_Parent
              and then Link.Status = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Resolved
              and then To_String (Link.Target_Path) = "src/parent-child.ads"
            then
               Found_Separate_Parent := True;
            end if;
         end;
      end loop;

      Assert (Found_Spec_To_Body,
              "cross-unit closure should retain the concrete spec-to-body target path");
      Assert (Found_Separate_Parent,
              "cross-unit closure should retain the concrete separate-parent target path");
   end Test_Ada_Cross_Unit_Semantic_Closure_Foundation;






   procedure Test_Ada_Cross_Unit_Context_Dependency_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Lib_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Lib is" & ASCII.LF &
           "end Lib;" & ASCII.LF,
           "lib.ads");
      Limited_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Limited_Dep is" & ASCII.LF &
           "end Limited_Dep;" & ASCII.LF,
           "limited_dep.ads");
      Private_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Private_Dep is" & ASCII.LF &
           "end Private_Dep;" & ASCII.LF,
           "private_dep.ads");
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Lib;" & ASCII.LF &
           "limited with Limited_Dep;" & ASCII.LF &
           "private with Private_Dep;" & ASCII.LF &
           "use Lib;" & ASCII.LF &
           "package Client is" & ASCII.LF &
           "end Client;" & ASCII.LF,
           "client.ads");
      Missing_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Missing_Dep;" & ASCII.LF &
           "package Missing_Client is" & ASCII.LF &
           "end Missing_Client;" & ASCII.LF,
           "missing_client.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Found_Limited : Boolean := False;
      Found_Private : Boolean := False;
      Found_Use : Boolean := False;
      Found_Missing : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/lib.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Lib_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/limited_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Limited_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/private_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);

      Assert (Editor.Ada_Cross_Unit_Closure.Context_Dependency_Count (Closure) >= 5,
              "cross-unit closure should stage context with/use dependencies");
      Assert (Editor.Ada_Cross_Unit_Closure.With_Dependency_Count (Closure) >= 4,
              "cross-unit closure should count ordinary, limited, private, and missing with clauses");
      Assert (Editor.Ada_Cross_Unit_Closure.Limited_With_Dependency_Count (Closure) = 1,
              "cross-unit closure should distinguish limited with dependencies");
      Assert (Editor.Ada_Cross_Unit_Closure.Private_With_Dependency_Count (Closure) = 1,
              "cross-unit closure should distinguish private with dependencies");
      Assert (Editor.Ada_Cross_Unit_Closure.Use_Dependency_Count (Closure) = 1,
              "cross-unit closure should stage context use package dependencies");

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Link_Count (Closure) loop
         declare
            Link : constant Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Info :=
              Editor.Ada_Cross_Unit_Closure.Link_At (Closure, I);
         begin
            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Limited_With_Dependency
              and then To_String (Link.Source_Unit_Name) = "Client"
              and then To_String (Link.Clause_Name) = "Limited_Dep"
              and then To_String (Link.Target_Path) = "src/limited_dep.ads"
              and then Link.Is_Limited_With
            then
               Found_Limited := True;
            end if;

            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Private_With_Dependency
              and then To_String (Link.Source_Unit_Name) = "Client"
              and then To_String (Link.Clause_Name) = "Private_Dep"
              and then To_String (Link.Target_Path) = "src/private_dep.ads"
              and then Link.Is_Private_With
            then
               Found_Private := True;
            end if;

            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Use_Dependency
              and then To_String (Link.Source_Unit_Name) = "Client"
              and then To_String (Link.Clause_Name) = "Lib"
              and then To_String (Link.Target_Path) = "src/lib.ads"
            then
               Found_Use := True;
            end if;

            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_With_Dependency
              and then To_String (Link.Source_Unit_Name) = "Missing_Client"
              and then To_String (Link.Clause_Name) = "Missing_Dep"
              and then Link.Status = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Missing
            then
               Found_Missing := True;
            end if;
         end;
      end loop;

      Assert (Found_Limited,
              "limited with dependency should retain source unit, clause name, flags, and target path");
      Assert (Found_Private,
              "private with dependency should retain source unit, clause name, flags, and target path");
      Assert (Found_Use,
              "context use dependency should resolve to the named library package");
      Assert (Found_Missing,
              "missing with dependency should be represented explicitly instead of disappearing");
   end Test_Ada_Cross_Unit_Context_Dependency_Closure;





   procedure Test_Ada_Cross_Unit_Spec_Body_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Matched is" & ASCII.LF &
           "   procedure Do_It;" & ASCII.LF &
           "end Matched;" & ASCII.LF,
           "matched.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Matched is" & ASCII.LF &
           "   procedure Do_It is" & ASCII.LF &
           "   begin" & ASCII.LF &
           "      null;" & ASCII.LF &
           "   end Do_It;" & ASCII.LF &
           "end Matched;" & ASCII.LF,
           "matched.adb");
      Missing_Body_Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Missing_Body is" & ASCII.LF &
           "end Missing_Body;" & ASCII.LF,
           "missing_body.ads");
      Missing_Spec_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Missing_Spec is" & ASCII.LF &
           "end Missing_Spec;" & ASCII.LF,
           "missing_spec.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Found_Matched_Spec : Boolean := False;
      Found_Matched_Body : Boolean := False;
      Found_Missing_Body : Boolean := False;
      Found_Missing_Spec : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/matched.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/matched.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_body.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Body_Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_spec.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Spec_Body_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);

      Assert (Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Count (Closure) >= 4,
              "cross-unit closure should stage spec/body consistency records");
      Assert (Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistent_Count (Closure) >= 2,
              "matched spec and body should both be reported as consistent");
      Assert (Editor.Ada_Cross_Unit_Closure.Spec_Body_Missing_Count (Closure) >= 2,
              "missing counterparts should be retained as explicit consistency diagnostics");
      Assert (Editor.Ada_Cross_Unit_Closure.Spec_Body_Inconsistent_Count (Closure) >= 2,
              "missing spec/body counterparts should contribute to inconsistency counts");

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Count (Closure) loop
         declare
            Info : constant Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Info :=
              Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_At (Closure, I);
         begin
            if Info.Status = Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Confirmed
              and then To_String (Info.Spec_Unit_Name) = "Matched"
              and then To_String (Info.Spec_Path) = "src/matched.ads"
              and then To_String (Info.Body_Path) = "src/matched.adb"
            then
               Found_Matched_Spec := True;
            end if;

            if Info.Status = Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Confirmed
              and then To_String (Info.Body_Unit_Name) = "Matched"
              and then To_String (Info.Body_Path) = "src/matched.adb"
              and then To_String (Info.Spec_Path) = "src/matched.ads"
            then
               Found_Matched_Body := True;
            end if;

            if Info.Status = Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Missing_Counterpart
              and then To_String (Info.Spec_Unit_Name) = "Missing_Body"
              and then To_String (Info.Spec_Path) = "src/missing_body.ads"
            then
               Found_Missing_Body := True;
            end if;

            if Info.Status = Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Missing_Counterpart
              and then To_String (Info.Body_Unit_Name) = "Missing_Spec"
              and then To_String (Info.Body_Path) = "src/missing_spec.adb"
            then
               Found_Missing_Spec := True;
            end if;
         end;
      end loop;

      Assert (Found_Matched_Spec,
              "spec-side consistency should retain matched body path metadata");
      Assert (Found_Matched_Body,
              "body-side consistency should retain matched spec path metadata");
      Assert (Found_Missing_Body,
              "spec without body should be preserved as missing body consistency data");
      Assert (Found_Missing_Spec,
              "body without spec should be preserved as missing spec consistency data");
   end Test_Ada_Cross_Unit_Spec_Body_Consistency;







   procedure Test_Ada_Cross_Unit_Child_Private_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Public_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Public_Child is" & ASCII.LF &
           "end Parent.Public_Child;" & ASCII.LF,
           "parent-public_child.ads");
      Private_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("private package Parent.Private_Child is" & ASCII.LF &
           "end Parent.Private_Child;" & ASCII.LF,
           "parent-private_child.ads");
      Missing_Parent_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Missing.Parentless is" & ASCII.LF &
           "end Missing.Parentless;" & ASCII.LF,
           "missing-parentless.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Found_Public : Boolean := False;
      Found_Private : Boolean := False;
      Found_Missing : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-public_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Public_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-private_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing-parentless.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Parent_Child_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);

      Assert (Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Count (Closure) >= 3,
              "cross-unit closure should stage child-unit legality records");
      Assert (Editor.Ada_Cross_Unit_Closure.Child_Unit_Resolved_Count (Closure) >= 2,
              "public and private child units with indexed parents should resolve");
      Assert (Editor.Ada_Cross_Unit_Closure.Private_Child_Unit_Count (Closure) = 1,
              "private child units should be counted separately from public children");
      Assert (Editor.Ada_Cross_Unit_Closure.Child_Unit_Missing_Parent_Count (Closure) = 1,
              "child units whose parent is absent should be retained as parent errors");
      Assert (Editor.Ada_Cross_Unit_Closure.Child_Unit_Parent_Error_Count (Closure) >= 1,
              "missing parents should contribute to child-unit parent error counts");

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Count (Closure) loop
         declare
            Info : constant Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Info :=
              Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_At (Closure, I);
         begin
            if Info.Status = Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Public_Child_Resolved
              and then To_String (Info.Child_Unit_Name) = "Parent.Public_Child"
              and then To_String (Info.Parent_Unit_Name) = "Parent"
              and then To_String (Info.Parent_Path) = "src/parent.ads"
              and then not Info.Is_Private_Child
            then
               Found_Public := True;
            end if;

            if Info.Status = Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Private_Child_Resolved
              and then To_String (Info.Child_Unit_Name) = "Parent.Private_Child"
              and then To_String (Info.Parent_Unit_Name) = "Parent"
              and then Info.Is_Private_Child
            then
               Found_Private := True;
            end if;

            if Info.Status = Editor.Ada_Cross_Unit_Closure.Child_Unit_Legality_Missing_Parent
              and then To_String (Info.Child_Unit_Name) = "Missing.Parentless"
              and then Info.Candidate_Count = 0
            then
               Found_Missing := True;
            end if;
         end;
      end loop;

      Assert (Found_Public,
              "public child legality should retain child and parent metadata");
      Assert (Found_Private,
              "private child legality should retain the private-child classification");
      Assert (Found_Missing,
              "missing parent child units should be represented explicitly");
   end Test_Ada_Cross_Unit_Child_Private_Legality;







   procedure Test_Ada_Cross_Unit_Separate_Body_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent is" & ASCII.LF &
           "   procedure Worker is separate;" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.adb");
      Separate_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "parent-worker.adb");
      Missing_Separate_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Missing_Parent)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "missing-worker.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Found_Resolved : Boolean := False;
      Found_Missing : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-worker.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing-worker.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Separate_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);

      Assert (Editor.Ada_Cross_Unit_Closure.Separate_Parent_Link_Count (Closure) >= 2,
              "cross-unit closure should retain raw separate-parent links");
      Assert (Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Count (Closure) >= 2,
              "cross-unit closure should stage separate-body legality records");
      Assert (Editor.Ada_Cross_Unit_Closure.Separate_Body_Resolved_Count (Closure) >= 1,
              "separate bodies whose parent body is indexed should resolve");
      Assert (Editor.Ada_Cross_Unit_Closure.Separate_Body_Missing_Parent_Count (Closure) >= 1,
              "separate bodies whose parent body is absent should be explicit parent errors");
      Assert (Editor.Ada_Cross_Unit_Closure.Separate_Body_Parent_Error_Count (Closure) >= 1,
              "missing separate parents should contribute to separate-body parent error counts");

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Count (Closure) loop
         declare
            Info : constant Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Info :=
              Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_At (Closure, I);
         begin
            if Info.Status = Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Parent_Resolved
              and then To_String (Info.Separate_Path) = "src/parent-worker.adb"
              and then To_String (Info.Parent_Unit_Name) = "Parent"
              and then To_String (Info.Parent_Path) = "src/parent.adb"
              and then To_String (Info.Parent_Name_Text) = "Parent"
            then
               Found_Resolved := True;
            end if;

            if Info.Status = Editor.Ada_Cross_Unit_Closure.Separate_Body_Legality_Missing_Parent
              and then To_String (Info.Separate_Path) = "src/missing-worker.adb"
              and then To_String (Info.Parent_Name_Text) = "Missing_Parent"
              and then Info.Candidate_Count = 0
            then
               Found_Missing := True;
            end if;
         end;
      end loop;

      Assert (Found_Resolved,
              "resolved separate-body legality should retain separate and parent body metadata");
      Assert (Found_Missing,
              "missing separate-parent legality should retain the parent-name text");
   end Test_Ada_Cross_Unit_Separate_Body_Legality;



   procedure Test_Ada_Cross_Unit_Visibility_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status;
      Lib_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Lib is" & ASCII.LF &
           "   type Item is null record;" & ASCII.LF &
           "end Lib;" & ASCII.LF,
           "lib.ads");
      Limited_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Limited_Dep is" & ASCII.LF &
           "end Limited_Dep;" & ASCII.LF,
           "limited_dep.ads");
      Private_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Private_Dep is" & ASCII.LF &
           "end Private_Dep;" & ASCII.LF,
           "private_dep.ads");
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Lib;" & ASCII.LF &
           "limited with Limited_Dep;" & ASCII.LF &
           "private with Private_Dep;" & ASCII.LF &
           "use Lib;" & ASCII.LF &
           "package Client is" & ASCII.LF &
           "   X : Item;" & ASCII.LF &
           "end Client;" & ASCII.LF,
           "client.ads");
      Missing_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Missing_Dep;" & ASCII.LF &
           "package Missing_Client is" & ASCII.LF &
           "end Missing_Client;" & ASCII.LF,
           "missing_client.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Lib_Lookup : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
      Use_Lookup : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
      Limited_Lookup : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
      Private_Lookup : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
      Missing_Lookup : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/lib.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Lib_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/limited_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Limited_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/private_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);

      Lib_Lookup := Editor.Ada_Cross_Unit_Visibility.Lookup_Visible_Unit
        (Visibility, "Client", "Lib");
      Use_Lookup := Editor.Ada_Cross_Unit_Visibility.Lookup_Visible_Unit
        (Visibility, "Client", "Lib");
      Limited_Lookup := Editor.Ada_Cross_Unit_Visibility.Lookup_Visible_Unit
        (Visibility, "Client", "Limited_Dep");
      Private_Lookup := Editor.Ada_Cross_Unit_Visibility.Lookup_Visible_Unit
        (Visibility, "Client", "Private_Dep");
      Missing_Lookup := Editor.Ada_Cross_Unit_Visibility.Lookup_Visible_Unit
        (Visibility, "Missing_Client", "Missing_Dep");

      Assert
        (Editor.Ada_Cross_Unit_Visibility.Visibility_Count (Visibility) >= 5,
         "cross-unit visibility should project all context dependencies into lookup metadata");
      Assert
        (Editor.Ada_Cross_Unit_Visibility.With_Visible_Count (Visibility) >= 3
         and then Editor.Ada_Cross_Unit_Visibility.Use_Visible_Count (Visibility) >= 1,
         "with and use dependencies should be visible to semantic lookup consumers");
      Assert
        (Lib_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous
         or else Lib_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Visible
         or else Lib_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Use_Package_Visible,
         "ordinary with/use lookup should resolve the imported library unit deterministically");
      Assert
        (Editor.Ada_Cross_Unit_Visibility.Use_Visible_Count (Visibility) >= 1
         and then (Use_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous
                   or else Use_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Use_Package_Visible
                   or else Use_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Visible),
         "use-package dependencies should be retained for later direct/use visibility integration");
      Assert
        (Limited_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Limited_View,
         "limited with lookup should preserve incomplete-view visibility metadata");
      Assert
        (Private_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Private_View,
         "private with lookup should preserve private-view visibility metadata");
      Assert
        (Missing_Lookup.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Missing
         and then Editor.Ada_Cross_Unit_Visibility.Missing_Count (Visibility) >= 1,
         "missing context dependencies should remain explicit diagnostics inputs");
      Assert
        (Editor.Ada_Cross_Unit_Visibility.Fingerprint (Visibility) /= 0,
         "cross-unit visibility integration should be fingerprinted deterministically");
   end Test_Ada_Cross_Unit_Visibility_Integration;




   procedure Test_Ada_Private_With_Visibility_Constraints
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Private_With_Rules.Private_With_Status;
      Public_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Public_Dep is" & ASCII.LF &
           "   type Public_Type is null record;" & ASCII.LF &
           "end Public_Dep;" & ASCII.LF,
           "public_dep.ads");
      Private_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Private_Dep is" & ASCII.LF &
           "   type Private_Type is null record;" & ASCII.LF &
           "end Private_Dep;" & ASCII.LF,
           "private_dep.ads");
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Public_Dep;" & ASCII.LF &
           "private with Private_Dep;" & ASCII.LF &
           "package Client is" & ASCII.LF &
           "   type Visible_Ref is access Public_Dep.Public_Type;" & ASCII.LF &
           "private" & ASCII.LF &
           "   type Hidden_Ref is access Private_Dep.Private_Type;" & ASCII.LF &
           "end Client;" & ASCII.LF,
           "client.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Client is" & ASCII.LF &
           "   procedure Touch is null;" & ASCII.LF &
           "end Client;" & ASCII.LF,
           "client.adb");
      Missing_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("private with Missing_Private;" & ASCII.LF &
           "package Missing_Client is" & ASCII.LF &
           "private" & ASCII.LF &
           "   X : Integer;" & ASCII.LF &
           "end Missing_Client;" & ASCII.LF,
           "missing_client.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Rules : Editor.Ada_Private_With_Rules.Private_With_Model;
      Private_Visible : Editor.Ada_Private_With_Rules.Private_With_Info;
      Private_Private : Editor.Ada_Private_With_Rules.Private_With_Info;
      Private_Body : Editor.Ada_Private_With_Rules.Private_With_Info;
      Public_Visible : Editor.Ada_Private_With_Rules.Private_With_Info;
      Missing_Private : Editor.Ada_Private_With_Rules.Private_With_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/public_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Public_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/private_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Rules := Editor.Ada_Private_With_Rules.Build (Visibility);

      Private_Visible := Editor.Ada_Private_With_Rules.Lookup_Private_With
        (Rules, "Client", "Private_Dep",
         Editor.Ada_Private_With_Rules.Private_With_Context_Visible_Part);
      Private_Private := Editor.Ada_Private_With_Rules.Lookup_Private_With
        (Rules, "Client", "Private_Dep",
         Editor.Ada_Private_With_Rules.Private_With_Context_Private_Part);
      Private_Body := Editor.Ada_Private_With_Rules.Lookup_Private_With
        (Rules, "Client", "Private_Dep",
         Editor.Ada_Private_With_Rules.Private_With_Context_Body);
      Public_Visible := Editor.Ada_Private_With_Rules.Lookup_Private_With
        (Rules, "Client", "Public_Dep",
         Editor.Ada_Private_With_Rules.Private_With_Context_Visible_Part);
      Missing_Private := Editor.Ada_Private_With_Rules.Lookup_Private_With
        (Rules, "Missing_Client", "Missing_Private",
         Editor.Ada_Private_With_Rules.Private_With_Context_Private_Part);

      Assert
        (Editor.Ada_Private_With_Rules.Rule_Count (Rules) >= 3,
         "private-with rules should project context visibility into a lookup-facing model");
      Assert
        (Private_Visible.Status = Editor.Ada_Private_With_Rules.Private_With_Hidden_From_Visible_Part
         and then Private_Visible.Hidden_From_Visible_Part
         and then not Editor.Ada_Private_With_Rules.Visible_In_Context
           (Rules, "Client", "Private_Dep",
            Editor.Ada_Private_With_Rules.Private_With_Context_Visible_Part),
         "private with dependencies should be hidden from ordinary visible-part lookup");
      Assert
        (Private_Private.Status = Editor.Ada_Private_With_Rules.Private_With_Visible_In_Private_Context
         and then Editor.Ada_Private_With_Rules.Visible_In_Context
           (Rules, "Client", "Private_Dep",
            Editor.Ada_Private_With_Rules.Private_With_Context_Private_Part),
         "private with dependencies should be visible in the package private part");
      Assert
        (Private_Body.Status = Editor.Ada_Private_With_Rules.Private_With_Visible_In_Body_Context
         and then Editor.Ada_Private_With_Rules.Visible_In_Context
           (Rules, "Client", "Private_Dep",
            Editor.Ada_Private_With_Rules.Private_With_Context_Body),
         "private with dependencies should be visible in the corresponding package body context");
      Assert
        (Public_Visible.Status = Editor.Ada_Private_With_Rules.Private_With_Not_Private
         and then Public_Visible.Visible_Part_Visible
         and then Public_Visible.Private_Part_Visible
         and then Public_Visible.Body_Visible,
         "ordinary with dependencies should remain visible in all unit contexts");
      Assert
        (Missing_Private.Status = Editor.Ada_Private_With_Rules.Private_With_Missing_Dependency
         and then Editor.Ada_Private_With_Rules.Missing_Count (Rules) >= 1,
         "missing private-with dependencies should remain explicit diagnostics metadata");
      Assert
        (Editor.Ada_Private_With_Rules.Private_Dependency_Count (Rules) >= 1
         and then Editor.Ada_Private_With_Rules.Hidden_From_Visible_Part_Count (Rules) >= 1
         and then Editor.Ada_Private_With_Rules.Private_Context_Visible_Count (Rules) >= 1
         and then Editor.Ada_Private_With_Rules.Body_Context_Visible_Count (Rules) >= 1
         and then Editor.Ada_Private_With_Rules.Fingerprint (Rules) /= 0,
         "private-with visibility constraints should retain deterministic counters and fingerprints");
   end Test_Ada_Private_With_Visibility_Constraints;




   procedure Test_Ada_Body_Spec_Declaration_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Status;
      Package_Spec : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Api is" & ASCII.LF &
           "   procedure Touch;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.ads");
      Package_Body : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Api is" & ASCII.LF &
           "   procedure Touch is null;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.adb");
      Subprogram_Spec : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("procedure Compute (X : Integer);" & ASCII.LF,
           "compute.ads");
      Subprogram_Body : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("procedure Compute (X : Integer) is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Compute;" & ASCII.LF,
           "compute.adb");
      Mismatch_Spec : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("procedure Drift (X : Integer);" & ASCII.LF,
           "drift.ads");
      Mismatch_Body : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("procedure Drift (X : Float) is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Drift;" & ASCII.LF,
           "drift.adb");
      Missing_Spec : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Missing_Body is" & ASCII.LF &
           "   X : Integer;" & ASCII.LF &
           "end Missing_Body;" & ASCII.LF,
           "missing_body.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Conformance : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      First_Info : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info;
      Saw_Profile_Mismatch : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Package_Spec);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Package_Body);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/compute.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Subprogram_Spec);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/compute.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Subprogram_Body);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/drift.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Mismatch_Spec);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/drift.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Mismatch_Body);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_body.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Spec);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Conformance := Editor.Ada_Body_Spec_Conformance.Build (Index, Closure);
      First_Info := Editor.Ada_Body_Spec_Conformance.Conformance_At (Conformance, 1);

      for I in 1 .. Editor.Ada_Body_Spec_Conformance.Conformance_Count (Conformance) loop
         declare
            Info : constant Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info :=
              Editor.Ada_Body_Spec_Conformance.Conformance_At (Conformance, I);
         begin
            if Info.Status = Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Profile_Mismatch then
               Saw_Profile_Mismatch := True;
            end if;
         end;
      end loop;

      Assert
        (Editor.Ada_Body_Spec_Conformance.Conformance_Count (Conformance) >= 3,
         "body/spec conformance should project confirmed and failing counterpart metadata");
      Assert
        (Editor.Ada_Body_Spec_Conformance.Package_Confirmed_Count (Conformance) >= 1,
         "package bodies should be confirmed against matching package specs");
      Assert
        (Editor.Ada_Body_Spec_Conformance.Subprogram_Profile_Confirmed_Count (Conformance) >= 1,
         "subprogram bodies should confirm profile-compatible specs");
      Assert
        (Saw_Profile_Mismatch
         or else Editor.Ada_Body_Spec_Conformance.Profile_Mismatch_Count (Conformance) >= 1,
         "subprogram body/spec profile mismatches should be preserved as semantic metadata");
      Assert
        (Editor.Ada_Body_Spec_Conformance.Missing_Count (Conformance) >= 1,
         "missing body/spec counterparts should remain explicit conformance metadata");
      Assert
        (First_Info.Fingerprint /= 0
         and then Editor.Ada_Body_Spec_Conformance.Fingerprint (Conformance) /= 0,
         "body/spec conformance metadata should have deterministic fingerprints");
   end Test_Ada_Body_Spec_Declaration_Conformance;




   procedure Test_Ada_Child_Unit_Visibility_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Child_Unit_Visibility.Child_Visibility_Status;
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Public_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Public_Child is" & ASCII.LF &
           "end Parent.Public_Child;" & ASCII.LF,
           "parent-public_child.ads");
      Private_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("private package Parent.Private_Child is" & ASCII.LF &
           "end Parent.Private_Child;" & ASCII.LF,
           "parent-private_child.ads");
      Missing_Parent_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Missing.Parentless is" & ASCII.LF &
           "end Missing.Parentless;" & ASCII.LF,
           "missing-parentless.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Public_Info : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
      Private_External : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
      Private_Private : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
      Private_Body : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
      Missing_Info : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-public_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Public_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-private_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing-parentless.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Parent_Child_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Child_Unit_Visibility.Build (Closure);

      Public_Info := Editor.Ada_Child_Unit_Visibility.Lookup_Child
        (Visibility, "Parent", "Public_Child",
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client);
      Private_External := Editor.Ada_Child_Unit_Visibility.Lookup_Child
        (Visibility, "Parent", "Private_Child",
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client);
      Private_Private := Editor.Ada_Child_Unit_Visibility.Lookup_Child
        (Visibility, "Parent", "Private_Child",
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Private_Part);
      Private_Body := Editor.Ada_Child_Unit_Visibility.Lookup_Child
        (Visibility, "Parent", "Private_Child",
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Body);
      Missing_Info := Editor.Ada_Child_Unit_Visibility.Lookup_Child
        (Visibility, "Missing", "Parentless",
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client);

      Assert
        (Editor.Ada_Child_Unit_Visibility.Visibility_Count (Visibility) >= 3,
         "child-unit visibility should project all child legality records");
      Assert
        (Public_Info.Status = Editor.Ada_Child_Unit_Visibility.Child_Visibility_Public_Child_Visible
         and then Editor.Ada_Child_Unit_Visibility.Visible_In_Context
           (Visibility, "Parent", "Public_Child",
            Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client),
         "public children should remain visible to ordinary child-unit lookup");
      Assert
        (Private_External.Status = Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Hidden
         and then not Editor.Ada_Child_Unit_Visibility.Visible_In_Context
           (Visibility, "Parent", "Private_Child",
            Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client),
         "private children should be hidden from external client lookup");
      Assert
        (Private_Private.Status =
           Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Visible_In_Private_Context
         and then Editor.Ada_Child_Unit_Visibility.Visible_In_Context
           (Visibility, "Parent", "Private_Child",
            Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Private_Part),
         "private children should be visible from parent private-part context");
      Assert
        (Private_Body.Status =
           Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Visible_In_Body_Context
         and then Editor.Ada_Child_Unit_Visibility.Visible_In_Context
           (Visibility, "Parent", "Private_Child",
            Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Body),
         "private children should be visible from parent body context");
      Assert
        (Missing_Info.Status = Editor.Ada_Child_Unit_Visibility.Child_Visibility_Missing_Parent
         and then Editor.Ada_Child_Unit_Visibility.Missing_Parent_Count (Visibility) >= 1,
         "child-unit visibility should retain missing-parent metadata");
      Assert
        (Editor.Ada_Child_Unit_Visibility.Public_Child_Visible_Count (Visibility) >= 1
         and then Editor.Ada_Child_Unit_Visibility.Private_Child_Hidden_Count (Visibility) >= 1
         and then Editor.Ada_Child_Unit_Visibility.Private_Child_Private_Context_Visible_Count (Visibility) >= 1
         and then Editor.Ada_Child_Unit_Visibility.Private_Child_Body_Context_Visible_Count (Visibility) >= 1
         and then Editor.Ada_Child_Unit_Visibility.Parent_Error_Count (Visibility) >= 1
         and then Editor.Ada_Child_Unit_Visibility.Fingerprint (Visibility) /= 0,
         "child-unit visibility counters and fingerprints should be deterministic");
   end Test_Ada_Child_Unit_Visibility_Context;







   procedure Test_Ada_Separate_Body_Stub_Placement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Status;
      Parent_With_Stub : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent is" & ASCII.LF &
           "   procedure Worker is separate;" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.adb");
      Separate_Worker : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent)" & ASCII.LF &
           "procedure Worker is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Worker;" & ASCII.LF,
           "parent-worker.adb");
      Parent_Without_Stub : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body No_Stub is" & ASCII.LF &
           "   procedure Other is null;" & ASCII.LF &
           "end No_Stub;" & ASCII.LF,
           "no_stub.adb");
      Separate_Missing_Stub : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (No_Stub)" & ASCII.LF &
           "procedure Missing is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Missing;" & ASCII.LF,
           "no_stub-missing.adb");
      Separate_Missing_Parent : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Absent_Parent)" & ASCII.LF &
           "procedure Lost is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Lost;" & ASCII.LF,
           "absent_parent-lost.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Stub_Model : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model;
      Matched : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Info;
      Missing : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_With_Stub);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-worker.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Worker);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/no_stub.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Without_Stub);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/no_stub-missing.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Missing_Stub);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/absent_parent-lost.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Missing_Parent);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Stub_Model := Editor.Ada_Separate_Body_Stub_Rules.Build (Index, Closure);
      Matched := Editor.Ada_Separate_Body_Stub_Rules.Lookup_Separate
        (Stub_Model, "Worker");
      Missing := Editor.Ada_Separate_Body_Stub_Rules.Lookup_Separate
        (Stub_Model, "Missing");

      Assert
        (Editor.Ada_Separate_Body_Stub_Rules.Stub_Check_Count (Stub_Model) >= 3,
         "separate-body stub rules should project all separate-body legality records");
      Assert
        (Matched.Status = Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Matched
         and then Editor.Ada_Separate_Body_Stub_Rules.Matched_Count (Stub_Model) >= 1,
         "separate bodies should match body stubs declared in the resolved parent body");
      Assert
        (Missing.Status = Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Missing
         and then Editor.Ada_Separate_Body_Stub_Rules.Missing_Stub_Count (Stub_Model) >= 1,
         "separate bodies without a matching parent body stub should remain explicit metadata");
      Assert
        (Editor.Ada_Separate_Body_Stub_Rules.Missing_Parent_Count (Stub_Model) >= 1
         and then Editor.Ada_Separate_Body_Stub_Rules.Parent_Error_Count (Stub_Model) >= 1,
         "separate-body stub rules should preserve parent-resolution failures");
      Assert
        (Matched.Fingerprint /= 0
         and then Editor.Ada_Separate_Body_Stub_Rules.Fingerprint (Stub_Model) /= 0,
         "separate-body stub placement metadata should have deterministic fingerprints");
   end Test_Ada_Separate_Body_Stub_Placement;



   procedure Test_Language_Model_Same_Line_Separate_Body_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "separate (Parent.Unit) procedure Compact_Procedure is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Compact_Procedure;" & ASCII.LF &
        "separate (Parent.Unit) function Compact_Function return Natural is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   return 1;" & ASCII.LF &
        "end Compact_Function;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_separate_body_marker.adb");
      Procedure_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Procedure");
      Function_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Function");
      Procedure_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Procedure_Id);
      Function_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Function_Id);
   begin
      Assert (Procedure_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Procedure_Info.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body
              and then Procedure_Info.Flags.Is_Separate
              and then To_String (Procedure_Info.Target_Name) = "Parent.Unit"
              and then Procedure_Info.Declaration_Column > 20,
              "same-line separate marker should apply to following procedure body and preserve tail column");
      Assert (Function_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Function_Info.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body
              and then Function_Info.Flags.Is_Separate
              and then To_String (Function_Info.Target_Name) = "Parent.Unit"
              and then Function_Info.Declaration_Column > 20,
              "same-line separate marker should apply to following function body and retain parent target");
   end Test_Language_Model_Same_Line_Separate_Body_Marker;




   procedure Test_Language_Model_Separate_Body_Parent_Target_Predicate
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Package_Id : Editor.Ada_Language_Model.Symbol_Id;
      Procedure_Id : Editor.Ada_Language_Model.Symbol_Id;
      Object_Id : Editor.Ada_Language_Model.Symbol_Id;
      Body_Id : Editor.Ada_Language_Model.Symbol_Id;
      Separate_Id : Editor.Ada_Language_Model.Symbol_Id;
      Body_Flags : Editor.Ada_Language_Model.Declaration_Flags := (others => False);
   begin
      Body_Flags.Is_Body := True;

      Package_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Pkg",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 3));
      Procedure_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 6));
      Object_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Pkg",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 6));
      Body_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Pkg",
         Editor.Ada_Language_Model.Symbol_Package_Body,
         (Start_Line => 4, Start_Column => 1, End_Line => 4, End_Column => 3),
         Flags => Body_Flags);
      Separate_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Separate_Body,
         (Start_Line => 5, Start_Column => 1, End_Line => 5, End_Column => 3),
         Flags => Body_Flags,
         Target_Name => "Pkg");

      Assert (Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target
                (Editor.Ada_Language_Model.Symbol (Analysis, Package_Id)),
              "package specs are valid separate-body parent navigation targets");
      Assert (Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target
                (Editor.Ada_Language_Model.Symbol (Analysis, Procedure_Id)),
              "subprogram specs are valid separate-body parent navigation targets");
      Assert (not Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target
                (Editor.Ada_Language_Model.Symbol (Analysis, Object_Id)),
              "objects must not satisfy separate-body parent target validation");
      Assert (not Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target
                (Editor.Ada_Language_Model.Symbol (Analysis, Body_Id)),
              "body rows must not be selected as separate-body parent specs");
      Assert (not Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target
                (Editor.Ada_Language_Model.Symbol (Analysis, Separate_Id)),
              "separate body rows must not point to another separate body target");
   end Test_Language_Model_Separate_Body_Parent_Target_Predicate;




   procedure Test_Language_Model_Child_Unit_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Parent.Child is" & Character'Val (10) &
        "end Parent.Child;" & Character'Val (10) &
        "package body Parent.Body_Child is" & Character'Val (10) &
        "end Parent.Body_Child;" & Character'Val (10) &
        "private package Parent.Private_Child is" & Character'Val (10) &
        "end Parent.Private_Child;" & Character'Val (10) &
        "procedure Parent.Run;" & Character'Val (10) &
        "function Parent.Value return Integer;" & Character'Val (10) &
        "package Standalone is" & Character'Val (10) &
        "end Standalone;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Package_Child : Boolean := False;
      Seen_Private_Child : Boolean := False;
      Seen_Package_Body_Child : Boolean := False;
      Seen_Procedure_Child : Boolean := False;
      Seen_Function_Child : Boolean := False;
      Standalone_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "parent.child" and then S.Flags.Has_Child_Unit_Metadata then
               Seen_Package_Child := True;
            elsif N = "parent.private_child" and then S.Flags.Has_Child_Unit_Metadata then
               Seen_Private_Child := True;
            elsif N = "parent.body_child" and then S.Flags.Has_Child_Unit_Metadata then
               Seen_Package_Body_Child := True;
            elsif N = "parent.run" and then S.Flags.Has_Child_Unit_Metadata then
               Seen_Procedure_Child := True;
            elsif N = "parent.value" and then S.Flags.Has_Child_Unit_Metadata then
               Seen_Function_Child := True;
            elsif N = "standalone" and then S.Flags.Has_Child_Unit_Metadata then
               Standalone_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Package_Child, "child package units must retain child-unit metadata");
      Assert (Seen_Private_Child, "private child package units must retain child-unit metadata");
      Assert (Seen_Package_Body_Child, "child package bodies must retain child-unit metadata");
      Assert (Seen_Procedure_Child, "child subprogram specs must retain child-unit metadata");
      Assert (Seen_Function_Child, "child function specs must retain child-unit metadata");
      Assert (not Standalone_Marked, "ordinary library units must not be marked as child units");
   end Test_Language_Model_Child_Unit_Metadata;




   procedure Test_Ada_Cross_Unit_Diagnostics_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity;
      Dep_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Dep is" & ASCII.LF &
           "end Dep;" & ASCII.LF,
           "dep.ads");
      Limited_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Limited_Dep is" & ASCII.LF &
           "end Limited_Dep;" & ASCII.LF,
           "limited_dep.ads");
      Private_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Private_Dep is" & ASCII.LF &
           "end Private_Dep;" & ASCII.LF,
           "private_dep.ads");
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Dep;" & ASCII.LF &
           "limited with Limited_Dep;" & ASCII.LF &
           "private with Private_Dep;" & ASCII.LF &
           "with Missing_Dep;" & ASCII.LF &
           "package Client is" & ASCII.LF &
           "end Client;" & ASCII.LF,
           "client.ads");
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Private_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("private package Parent.Private_Child is" & ASCII.LF &
           "end Parent.Private_Child;" & ASCII.LF,
           "parent-private_child.ads");
      Missing_Parent_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Missing.Parentless is" & ASCII.LF &
           "end Missing.Parentless;" & ASCII.LF,
           "missing-parentless.ads");
      Parent_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Parent_Body is" & ASCII.LF &
           "   procedure Worker is separate;" & ASCII.LF &
           "end Parent_Body;" & ASCII.LF,
           "parent_body.adb");
      Separate_Missing_Stub : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("separate (Parent_Body)" & ASCII.LF &
           "procedure Missing is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Missing;" & ASCII.LF,
           "parent_body-missing.adb");
      Needs_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Needs_Body is" & ASCII.LF &
           "   procedure P;" & ASCII.LF &
           "end Needs_Body;" & ASCII.LF,
           "needs_body.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Limited_View : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Private_W : Editor.Ada_Private_With_Rules.Private_With_Model;
      Body_Spec : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Children : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Separates : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model;
      Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Private_Context_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Body_Context_Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      First : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Dep_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/limited_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Limited_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/private_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-private_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing-parentless.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Parent_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent_body.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Body_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent_body-missing.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Separate_Missing_Stub);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/needs_body.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Needs_Body_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Limited_View := Editor.Ada_Limited_View_Rules.Build (Visibility);
      Private_W := Editor.Ada_Private_With_Rules.Build (Visibility);
      Body_Spec := Editor.Ada_Body_Spec_Conformance.Build (Index, Closure);
      Children := Editor.Ada_Child_Unit_Visibility.Build (Closure);
      Separates := Editor.Ada_Separate_Body_Stub_Rules.Build (Index, Closure);
      Diags := Editor.Ada_Cross_Unit_Diagnostics.Build
        (Visibility, Limited_View, Private_W, Body_Spec, Children, Separates);
      Private_Context_Diags := Editor.Ada_Cross_Unit_Diagnostics.Build
        (Visibility, Limited_View, Private_W, Body_Spec, Children, Separates,
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Private_Part);
      Body_Context_Diags := Editor.Ada_Cross_Unit_Diagnostics.Build
        (Visibility, Limited_View, Private_W, Body_Spec, Children, Separates,
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Body);
      First := Editor.Ada_Cross_Unit_Diagnostics.Diagnostic_At (Diags, 1);

      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Has_Diagnostics (Diags)
         and then Editor.Ada_Cross_Unit_Diagnostics.Error_Count (Diags) >= 1,
         "cross-unit diagnostics must project semantic closure errors into diagnostics");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Missing_Dependency) >= 1,
         "cross-unit diagnostics must expose missing with-dependencies");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Limited_View_Full_View_Hidden) >= 1,
         "cross-unit diagnostics must expose limited-view full-view restrictions");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Private_With_Hidden) >= 1,
         "cross-unit diagnostics must expose private-with visible-part restrictions");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Private_Child_Hidden) >= 1,
         "cross-unit diagnostics must expose private-child visibility restrictions");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Private_Context_Diags,
            Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Private_Child_Hidden) = 0,
         "cross-unit diagnostics must not report private child hidden from parent private-part context");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Body_Context_Diags,
            Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Private_Child_Hidden) = 0,
         "cross-unit diagnostics must not report private child hidden from parent body context");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Separate_Stub_Missing) >= 1,
         "cross-unit diagnostics must expose separate-body stub-placement errors");
      Assert
        (First.Severity = Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Error
         or else First.Severity = Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Warning,
         "cross-unit diagnostics must retain severity metadata");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Fingerprint (Diags) /= 0,
         "cross-unit diagnostics must retain deterministic fingerprints");
   end Test_Ada_Cross_Unit_Diagnostics_Projection;




   procedure Test_Ada_Cross_Unit_Lookup_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status;
      Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Parent_With_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Parent.Public_Child;" & ASCII.LF &
           "package Parent is" & ASCII.LF &
           "end Parent;" & ASCII.LF,
           "parent.ads");
      Public_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Parent.Public_Child is" & ASCII.LF &
           "end Parent.Public_Child;" & ASCII.LF,
           "parent-public_child.ads");
      Private_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("private package Parent.Private_Child is" & ASCII.LF &
           "end Parent.Private_Child;" & ASCII.LF,
           "parent-private_child.ads");
      Index      : Editor.Ada_Project_Index.Index_State;
      Closure    : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Children   : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Model      : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Private_Context_Model :
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Body_Context_Model :
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Result     : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Entry;
      Private_Result :
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Entry;
   begin
      Editor.Ada_Project_Index.Clear (Index);
      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Model := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Visibility, Source_Unit_Name => "Main");

      Assert
        (Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Count (Model) = 0,
         "empty cross-unit visibility must not create lookup targets");
      Assert
        (Editor.Ada_Cross_Unit_Lookup_Integration.Visible_Count (Model) = 0,
         "empty cross-unit visibility must not report visible targets");

      Result := Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Name
        (Model, "Ada.Text_IO");
      Assert
        (Result.Status = Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found,
         "missing cross-unit lookup must remain deterministic and explicit");
      Assert
        (Editor.Ada_Cross_Unit_Lookup_Integration.Fingerprint (Model) /= 0,
         "cross-unit lookup integration must produce a deterministic fingerprint");

      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-public_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Public_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-private_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Private_Child_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Children := Editor.Ada_Child_Unit_Visibility.Build (Closure);
      Model := Editor.Ada_Cross_Unit_Lookup_Integration.Build_With_Children
        (Visibility, Children, Source_Unit_Name => "Parent");
      Private_Context_Model :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Build_With_Children
          (Visibility, Children, Source_Unit_Name => "Parent",
           Child_Context =>
             Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Private_Part);
      Body_Context_Model :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Build_With_Children
          (Visibility, Children, Source_Unit_Name => "Parent",
           Child_Context =>
             Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Body);

      Result := Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Name
        (Model, "Parent.Public_Child");
      Private_Result := Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Name
        (Model, "Parent.Private_Child");
      Assert
        (Result.Status =
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible,
         "child-aware lookup must expose public child units as visible targets");
      Assert
        (Private_Result.Status =
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Private_View,
         "child-aware lookup must retain hidden private-child barriers for external context");

      Private_Result := Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Name
        (Private_Context_Model, "Parent.Private_Child");
      Assert
        (Private_Result.Status =
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible,
         "child-aware lookup must expose private children in parent private-part context");
      Private_Result := Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Name
        (Body_Context_Model, "Parent.Private_Child");
      Assert
        (Private_Result.Status =
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible,
         "child-aware lookup must expose private children in parent body context");

      Editor.Ada_Project_Index.Clear (Index);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Parent_With_Child_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/parent-public_child.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Public_Child_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Children := Editor.Ada_Child_Unit_Visibility.Build (Closure);
      Model := Editor.Ada_Cross_Unit_Lookup_Integration.Build_With_Children
        (Visibility, Children, Source_Unit_Name => "Parent");
      Result := Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Name
        (Model, "Parent.Public_Child");
      Assert
        (Result.Status =
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible
         and then Result.Candidate_Count <= 1
         and then Editor.Ada_Cross_Unit_Lookup_Integration.Lookup_Count (Model) = 1
         and then Editor.Ada_Cross_Unit_Lookup_Integration.Visible_Count (Model) = 1,
         "child-aware lookup must coalesce equivalent with-clause and child-closure candidates");
   end Test_Ada_Cross_Unit_Lookup_Integration;





   procedure Test_Ada_Selected_Name_Cross_Unit_Lookup_Consumer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Id;
      use type Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status;
      Library_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Library is" & ASCII.LF &
           "   Exported : Integer;" & ASCII.LF &
           "end Library;" & ASCII.LF,
           "library.ads");
      Client_Source : constant String :=
        "with Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   Value : Integer := Library.Exported;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.adb");
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Client_Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Model : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Info  : Editor.Ada_Selected_Name_Resolution.Selected_Name_Info;

      function Package_Body_Region return Editor.Ada_Declarative_Regions.Region_Id is
         Result : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
      begin
         for I in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               R : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, I);
            begin
               if R.Kind = Editor.Ada_Declarative_Regions.Region_Package_Body then
                  Result := R.Id;
               end if;
            end;
         end loop;
         return Result;
      end Package_Body_Region;
   begin
      Editor.Ada_Project_Index.Clear (Index);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/library.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Library_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Cross_Lookup := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Cross_Visibility, Source_Unit_Name => "Client");
      Model := Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
        (Tree, Regions, Visibility, Uses, Cross_Lookup);
      Info := Editor.Ada_Selected_Name_Resolution.Resolve_Selected_With_Cross_Unit
        (Tree, Regions, Visibility, Uses, Cross_Lookup,
         Package_Body_Region,
         "Library.Exported");

      Assert
        (Info.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Found,
         "selected-name consumers must accept cross-unit visible prefixes when local lookup misses");
      Assert
        (Info.Cross_Unit_Lookup /= Editor.Ada_Cross_Unit_Lookup_Integration.No_Cross_Unit_Lookup
         and then Info.Cross_Unit_Status =
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible,
         "selected-name cross-unit metadata must retain lookup identity and visibility status");
      Assert
        (Length (Info.Cross_Unit_Target) > 0
         and then Info.Fingerprint /= 0,
         "selected-name cross-unit lookup metadata must preserve target identity and deterministic fingerprint");
      Assert
        (Editor.Ada_Selected_Name_Resolution.Selected_Name_Count (Model) >= 1
         and then Editor.Ada_Selected_Name_Resolution.Fingerprint (Model) /= 0,
         "selected-name build-with-cross-unit must include deterministic cross-unit consumer metadata");

      declare
         Parent_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
           Editor.Ada_Declaration_Parser.Parse
             ("package Parent is" & ASCII.LF &
              "end Parent;" & ASCII.LF,
              "parent.ads");
         Private_Child_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
           Editor.Ada_Declaration_Parser.Parse
             ("private package Parent.Private_Child is" & ASCII.LF &
              "   Exported : Integer;" & ASCII.LF &
              "end Parent.Private_Child;" & ASCII.LF,
              "parent-private_child.ads");
         Parent_Body_Source : constant String :=
           "package body Parent is" & ASCII.LF &
           "   Value : Integer := Parent.Private_Child.Exported;" & ASCII.LF &
           "end Parent;" & ASCII.LF;
         Parent_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
           Editor.Ada_Declaration_Parser.Parse (Parent_Body_Source, "parent.adb");
         Parent_Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
           Editor.Ada_Syntax_Tree.Parse (Parent_Body_Source);
         Parent_Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
           Editor.Ada_Declarative_Regions.Build (Parent_Tree);
         Parent_Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
           Editor.Ada_Direct_Visibility.Build (Parent_Tree, Parent_Regions);
         Parent_Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
           Editor.Ada_Use_Visibility.Build
             (Parent_Tree, Parent_Regions, Parent_Visibility);
         Parent_Index : Editor.Ada_Project_Index.Index_State;
         Parent_Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
         Parent_Cross_Visibility :
           Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
         Parent_Children : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
         Parent_Cross_Lookup :
           Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
         Parent_Info : Editor.Ada_Selected_Name_Resolution.Selected_Name_Info;

         function Parent_Body_Region return Editor.Ada_Declarative_Regions.Region_Id is
            Result : Editor.Ada_Declarative_Regions.Region_Id :=
              Editor.Ada_Declarative_Regions.No_Region;
         begin
            for I in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Parent_Regions) loop
               declare
                  R : constant Editor.Ada_Declarative_Regions.Region_Info :=
                    Editor.Ada_Declarative_Regions.Region_At (Parent_Regions, I);
               begin
                  if R.Kind = Editor.Ada_Declarative_Regions.Region_Package_Body then
                     Result := R.Id;
                  end if;
               end;
            end loop;
            return Result;
         end Parent_Body_Region;
      begin
         Editor.Ada_Project_Index.Put_Analysis
           (Parent_Index, "src/parent.ads", Buffer_Token => 0, Buffer_Revision => 0,
            Lifecycle_Generation => 0, Analysis => Parent_Analysis);
         Editor.Ada_Project_Index.Put_Analysis
           (Parent_Index, "src/parent-private_child.ads",
            Buffer_Token => 0, Buffer_Revision => 0,
            Lifecycle_Generation => 0, Analysis => Private_Child_Analysis);
         Editor.Ada_Project_Index.Put_Analysis
           (Parent_Index, "src/parent.adb", Buffer_Token => 0, Buffer_Revision => 0,
            Lifecycle_Generation => 0, Analysis => Parent_Body_Analysis);

         Parent_Closure := Editor.Ada_Cross_Unit_Closure.Build (Parent_Index);
         Parent_Cross_Visibility :=
           Editor.Ada_Cross_Unit_Visibility.Build (Parent_Index, Parent_Closure);
         Parent_Children := Editor.Ada_Child_Unit_Visibility.Build (Parent_Closure);
         Parent_Cross_Lookup :=
           Editor.Ada_Cross_Unit_Lookup_Integration.Build_With_Children
             (Parent_Cross_Visibility, Parent_Children, Source_Unit_Name => "Parent",
              Child_Context =>
                Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_Parent_Body);
         Parent_Info :=
           Editor.Ada_Selected_Name_Resolution.Resolve_Selected_With_Cross_Unit
             (Parent_Tree, Parent_Regions, Parent_Visibility, Parent_Uses,
              Parent_Cross_Lookup, Parent_Body_Region,
              "Parent.Private_Child.Exported");

         Assert
           (Parent_Info.Status =
              Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Found
            and then Parent_Info.Cross_Unit_Status =
              Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_With_Visible,
            "selected-name consumers must resolve private child prefixes through child-aware parent-body lookup");
      end;
   end Test_Ada_Selected_Name_Cross_Unit_Lookup_Consumer;





   procedure Test_Ada_Expression_Cross_Unit_Selected_Name_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      Library_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Library is" & ASCII.LF &
           "   Exported : Integer;" & ASCII.LF &
           "end Library;" & ASCII.LF,
           "library.ads");
      Client_Source : constant String :=
        "with Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   Value : Integer := Library.Exported;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.adb");
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Client_Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Model : Editor.Ada_Expression_Types.Expression_Type_Model;
      Info : Editor.Ada_Expression_Types.Expression_Type_Info := (others => <>);
      Found : Boolean := False;
   begin
      Editor.Ada_Project_Index.Clear (Index);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/library.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Library_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Cross_Lookup := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Cross_Visibility, Source_Unit_Name => "Client");
      Selected := Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
        (Tree, Regions, Visibility, Uses, Cross_Lookup);
      Model := Editor.Ada_Expression_Types.Build_With_Cross_Unit_Selected_Names
        (Tree, Regions, Visibility, Types, Static, Calls, Selected);

      for I in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Model) loop
         declare
            Candidate : constant Editor.Ada_Expression_Types.Expression_Type_Info :=
              Editor.Ada_Expression_Types.Expression_Type_At (Model, I);
         begin
            if Candidate.Status =
              Editor.Ada_Expression_Types.Expression_Type_Selected_Name_Cross_Unit_Resolved
            then
               Info := Candidate;
               Found := True;
            end if;
         end;
      end loop;

      Assert
        (Found,
         "expression type inference must consume cross-unit selected-name metadata");
      Assert
        (Editor.Ada_Expression_Types.Cross_Unit_Selected_Name_Resolved_Count (Model) >= 1
         and then Editor.Ada_Expression_Types.Cross_Unit_Selected_Name_Count (Model) >= 1,
         "expression type counters must expose cross-unit selected-name inference");
      Assert
        (Length (Info.Cross_Unit_Selected_Target) > 0
         and then Length (Info.Cross_Unit_Selected_Selector) > 0
         and then Info.Fingerprint /= 0,
         "cross-unit selected-name expression metadata must retain target, selector, and fingerprint");
   end Test_Ada_Expression_Cross_Unit_Selected_Name_Inference;




   procedure Test_Ada_View_Aware_Compatibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
      Library_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Library is" & ASCII.LF &
           "   Exported : Integer;" & ASCII.LF &
           "end Library;" & ASCII.LF,
           "library.ads");
      Client_Source : constant String :=
        "with Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   Value : Integer := Library.Exported;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.adb");
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Client_Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Model : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Hidden : Editor.Ada_Subtype_Compatibility.Compatibility_Info := (others => <>);
      Derived : Editor.Ada_Subtype_Compatibility.Compatibility_Info := (others => <>);
   begin
      Editor.Ada_Project_Index.Clear (Index);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/library.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Library_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Cross_Lookup := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Cross_Visibility, Source_Unit_Name => "Client");
      Selected := Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
        (Tree, Regions, Visibility, Uses, Cross_Lookup);
      Expressions := Editor.Ada_Expression_Types.Build_With_Cross_Unit_Selected_Names
        (Tree, Regions, Visibility, Types, Static, Calls, Selected);
      Model := Editor.Ada_View_Aware_Compatibility.Build (Expressions);

      Assert
        (Editor.Ada_View_Aware_Compatibility.Entry_Count (Model) >= 1,
         "view-aware compatibility must classify cross-unit expression metadata");
      Assert
        (Editor.Ada_View_Aware_Compatibility.Compatible_Count (Model) >= 1
         and then Editor.Ada_View_Aware_Compatibility.Fingerprint (Model) /= 0,
         "resolved cross-unit selected names must remain compatible and fingerprinted");

      Hidden.Status :=
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Hidden_Full_View;
      Assert
        (Editor.Ada_View_Aware_Compatibility.Classify_Subtype_Compatibility (Hidden) =
           Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View_Hidden,
         "private hidden-full-view subtype compatibility must be exposed as a view-aware barrier");
      Derived.Status :=
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Derived_From;
      Assert
        (Editor.Ada_View_Aware_Compatibility.Classify_Subtype_Compatibility (Derived) =
           Editor.Ada_View_Aware_Compatibility.View_Compatibility_Requires_Explicit_Conversion,
         "view-aware compatibility must not report derived specific types as implicit-compatible");
   end Test_Ada_View_Aware_Compatibility;




   procedure Test_Ada_Nested_Body_Spec_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Status;
      Package_Spec : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Api is" & ASCII.LF &
           "   procedure Touch (X : Integer);" & ASCII.LF &
           "   procedure Missing;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.ads");
      Package_Body : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Api is" & ASCII.LF &
           "   procedure Touch (X : Integer) is null;" & ASCII.LF &
           "   procedure Extra is null;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Unit_Conformance : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Nested : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Model;
      Touch : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Info;
      Missing : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Info;
      Extra : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Package_Spec);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Package_Body);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Unit_Conformance := Editor.Ada_Body_Spec_Conformance.Build (Index, Closure);
      Nested := Editor.Ada_Nested_Body_Spec_Conformance.Build (Index, Unit_Conformance);
      Touch := Editor.Ada_Nested_Body_Spec_Conformance.First_For_Name (Nested, "Touch");
      Missing := Editor.Ada_Nested_Body_Spec_Conformance.First_For_Name (Nested, "Missing");
      Extra := Editor.Ada_Nested_Body_Spec_Conformance.First_For_Name (Nested, "Extra");

      Assert
        (Editor.Ada_Nested_Body_Spec_Conformance.Conformance_Count (Nested) >= 3,
         "nested body/spec conformance must project direct nested declarations");
      Assert
        (Touch.Status in
           Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Confirmed |
           Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Unknown |
           Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Confirmed,
         "nested matching declarations must be classified deterministically");
      Assert
        (Missing.Status = Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Missing_Body_Declaration
         and then Editor.Ada_Nested_Body_Spec_Conformance.Missing_Body_Declaration_Count (Nested) >= 1,
         "nested spec declarations without body declarations must be reported");
      Assert
        (Extra.Status = Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Extra_Body_Declaration
         and then Editor.Ada_Nested_Body_Spec_Conformance.Extra_Body_Declaration_Count (Nested) >= 1,
         "nested body declarations without spec declarations must be reported");
      Assert
        (Touch.Id /= Editor.Ada_Nested_Body_Spec_Conformance.No_Nested_Conformance
         and then Touch.Fingerprint /= 0
         and then Editor.Ada_Nested_Body_Spec_Conformance.Fingerprint (Nested) /= 0,
         "nested body/spec conformance must preserve identity and deterministic fingerprints");
   end Test_Ada_Nested_Body_Spec_Conformance;






   procedure Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Severity;
      use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Conformance_Id;
      Package_Spec : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Api is" & ASCII.LF &
           "   procedure Touch (X : Integer);" & ASCII.LF &
           "   procedure Missing;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.ads");
      Package_Body : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body Api is" & ASCII.LF &
           "   procedure Touch (X : Integer) is null;" & ASCII.LF &
           "   procedure Extra is null;" & ASCII.LF &
           "end Api;" & ASCII.LF,
           "api.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Limited_View : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Private_W : Editor.Ada_Private_With_Rules.Private_With_Model;
      Unit_Conformance : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Children : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Separates : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model;
      Nested : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Model;
      Diags : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Model;
      Missing : Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Package_Spec);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/api.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Package_Body);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Limited_View := Editor.Ada_Limited_View_Rules.Build (Visibility);
      Private_W := Editor.Ada_Private_With_Rules.Build (Visibility);
      Unit_Conformance := Editor.Ada_Body_Spec_Conformance.Build (Index, Closure);
      Children := Editor.Ada_Child_Unit_Visibility.Build (Closure);
      Separates := Editor.Ada_Separate_Body_Stub_Rules.Build (Index, Closure);
      Nested := Editor.Ada_Nested_Body_Spec_Conformance.Build (Index, Unit_Conformance);
      Diags := Editor.Ada_Cross_Unit_Diagnostics.Build_With_Nested
        (Visibility, Limited_View, Private_W, Unit_Conformance, Children, Separates, Nested);
      Missing := Editor.Ada_Cross_Unit_Diagnostics.Diagnostic_At (Diags, 1);

      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Nested_Body_Spec_Diagnostic_Count (Diags) >= 2,
         "cross-unit diagnostics must project nested body/spec conformance diagnostics");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Nested_Missing_Declaration_Count (Diags) >= 1
         and then Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Nested_Body_Spec_Missing) >= 1,
         "cross-unit diagnostics must expose missing nested body declarations");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Nested_Extra_Declaration_Count (Diags) >= 1
         and then Editor.Ada_Cross_Unit_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Nested_Body_Spec_Extra) >= 1,
         "cross-unit diagnostics must expose extra nested body declarations");
      Assert
        (Missing.Nested_Conformance /= Editor.Ada_Nested_Body_Spec_Conformance.No_Nested_Conformance
         and then Missing.Severity = Editor.Ada_Cross_Unit_Diagnostics.Cross_Unit_Diagnostic_Error
         and then Length (Missing.Declaration_Name) > 0
         and then Missing.Fingerprint /= 0,
         "nested body/spec diagnostics must preserve nested identity, declaration name, severity, and fingerprint");
      Assert
        (Editor.Ada_Cross_Unit_Diagnostics.Fingerprint (Diags) /= 0,
         "nested body/spec diagnostics must contribute to deterministic cross-unit fingerprints");
   end Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec;


   overriding function Name (T : Cross_Unit_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Cross_Unit");
   end Name;

   overriding procedure Register_Tests (T : in out Cross_Unit_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Separate_Body_Kind_And_Semantics'Access, Name => "language model parser marks separate bodies with explicit semantic kind");
      Add_Test (Routine => Test_Project_Index_Separate_Body_Parent_Target'Access, Name => "project index retains separate-body parent targets for goto-spec");
      Add_Test (Routine => Test_Project_Index_Child_Unit_Parent_Relationship_Target'Access, Name => "project index resolves child units back to indexed parent units");
      Add_Test (Routine => Test_Project_Index_Parent_Lists_Direct_Child_Units'Access, Name => "project index lists direct indexed child units for a parent unit");
      Add_Test (Routine => Test_Ada_Cross_Unit_Semantic_Closure_Foundation'Access, Name => "Ada cross-unit semantic closure stages unit family relationships");
      Add_Test (Routine => Test_Ada_Cross_Unit_Context_Dependency_Closure'Access, Name => "Ada cross-unit closure stages context with and use dependencies");
      Add_Test (Routine => Test_Ada_Cross_Unit_Spec_Body_Consistency'Access, Name => "Ada cross-unit closure stages spec body consistency diagnostics");
      Add_Test (Routine => Test_Ada_Cross_Unit_Child_Private_Legality'Access, Name => "Ada cross-unit closure stages child private unit legality");
      Add_Test (Routine => Test_Ada_Cross_Unit_Separate_Body_Legality'Access, Name => "Ada cross-unit closure stages separate body legality");
      Add_Test (Routine => Test_Ada_Cross_Unit_Visibility_Integration'Access, Name => "Ada cross-unit visibility projects with and use dependencies into semantic lookup");
      Add_Test (Routine => Test_Ada_Private_With_Visibility_Constraints'Access, Name => "Ada private-with visibility constraints are projected into semantic lookup");
      Add_Test (Routine => Test_Ada_Body_Spec_Declaration_Conformance'Access, Name => "Ada body/spec declaration conformance is projected from cross-unit closure");
      Add_Test (Routine => Test_Ada_Child_Unit_Visibility_Context'Access, Name => "Ada child-unit visibility respects parent and private-child contexts");
      Add_Test (Routine => Test_Ada_Separate_Body_Stub_Placement'Access, Name => "Ada separate bodies match parent body stubs and placement rules");
      Add_Test (Routine => Test_Language_Model_Same_Line_Separate_Body_Marker'Access, Name => "language model parser retains same-line separate body markers");
      Add_Test (Routine => Test_Language_Model_Separate_Body_Parent_Target_Predicate'Access, Name => "language model validates separate-body parent target kinds");
      Add_Test (Routine => Test_Language_Model_Child_Unit_Metadata'Access, Name => "language model retains child unit metadata");
      Add_Test (Routine => Test_Ada_Cross_Unit_Diagnostics_Projection'Access, Name => "Ada cross-unit diagnostics project visibility and closure metadata into stable diagnostics");
      Add_Test (Routine => Test_Ada_Cross_Unit_Lookup_Integration'Access, Name => "Ada cross-unit lookup integration exposes context visibility to lookup consumers");
      Add_Test (Routine => Test_Ada_Selected_Name_Cross_Unit_Lookup_Consumer'Access, Name => "Ada selected-name resolution consumes cross-unit lookup metadata");
      Add_Test (Routine => Test_Ada_Expression_Cross_Unit_Selected_Name_Inference'Access, Name => "Ada expression inference consumes cross-unit selected-name metadata");
      Add_Test (Routine => Test_Ada_View_Aware_Compatibility'Access, Name => "Ada view-aware compatibility classifies private and limited view barriers");
      Add_Test (Routine => Test_Ada_Nested_Body_Spec_Conformance'Access, Name => "Ada nested body spec conformance compares nested declarations");
      Add_Test (Routine => Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec'Access, Name => "Ada cross-unit diagnostics project nested body spec conformance results");
   end Register_Tests;

end Editor.Syntax_Semantics.Cross_Unit_Tests;
