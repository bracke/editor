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

package body Editor.Syntax_Semantics.Expression_Call_Overload_Tests is





   procedure Test_Resolver_Use_Type_Clause_Exposes_Primitive_Operators_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Shared is" & ASCII.LF &
        "   type Count is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   function ""+"" (Left, Right : Count) return Count;" & ASCII.LF &
        "end Shared;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   use type Shared.Count;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "use_type_visibility.ads");
      Client_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Client");
      Plus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, """+""", Client_Id);
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Value", Client_Id);
      Plus_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plus_Id);
   begin
      Assert (Client_Id /= Editor.Ada_Language_Model.No_Symbol,
              "use-type resolver regression should have a client scope");
      Assert (Plus_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Plus_Info.Kind = Editor.Ada_Language_Model.Symbol_Operator_Function,
              "use type should expose primitive operator functions for the selected type");
      Assert (Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "use type must not expose record components as directly visible names");
   end Test_Resolver_Use_Type_Clause_Exposes_Primitive_Operators_Only;






   procedure Test_Resolver_Call_Overload_Resolution_Uses_Profile_Actuals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Pkg_Id : Editor.Ada_Language_Model.Symbol_Id;
      Run_Integer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Run_Boolean_Id : Editor.Ada_Language_Model.Symbol_Id;
      Make_Integer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Make_Boolean_Id : Editor.Ada_Language_Model.Symbol_Id;
      Result : Editor.Ada_Symbol_Resolver.Resolution_Result;
      Named_Result : Editor.Ada_Symbol_Resolver.Resolution_Result;
      Return_Result : Editor.Ada_Symbol_Resolver.Resolution_Result;
   begin
      Pkg_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Demo",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 4));
      Run_Integer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 7),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left : Integer)");
      Run_Boolean_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 7),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Flag : Boolean)");
      Make_Integer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Make",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 8),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left : Integer) return Integer");
      Make_Boolean_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Make",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 8),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left : Integer) return Boolean");

      Assert (Pkg_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain overloaded subprogram rows");

      Result := Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope
        (Analysis, "Run", Pkg_Id, "Integer");
      Assert (Natural (Result.Matches.Length) = 1
              and then Result.Matches.First_Element = Run_Integer_Id,
              "overload resolution should select the profile whose positional actual type matches");

      Named_Result := Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope
        (Analysis, "Run", Pkg_Id, "Flag => Boolean");
      Assert (Natural (Named_Result.Matches.Length) = 1
              and then Named_Result.Matches.First_Element = Run_Boolean_Id,
              "overload resolution should match named actual associations by formal name and type");

      Return_Result := Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope
        (Analysis, "Make", Pkg_Id, "Integer", "Boolean");
      Assert (Natural (Return_Result.Matches.Length) = 1
              and then Return_Result.Matches.First_Element = Make_Boolean_Id,
              "overload resolution should use the expected function result type when supplied");
   end Test_Resolver_Call_Overload_Resolution_Uses_Profile_Actuals;




   procedure Test_Resolver_Call_Overload_Resolution_Uses_Defaulted_Formals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Pkg_Id : Editor.Ada_Language_Model.Symbol_Id;
      Required_Id : Editor.Ada_Language_Model.Symbol_Id;
      Defaulted_Id : Editor.Ada_Language_Model.Symbol_Id;
      Named_Defaulted_Id : Editor.Ada_Language_Model.Symbol_Id;
      One_Actual : Editor.Ada_Symbol_Resolver.Resolution_Result;
      Named_Actual : Editor.Ada_Symbol_Resolver.Resolution_Result;
   begin
      Pkg_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Demo",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 4));
      Required_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Configure",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left : Integer; Mode : Boolean)");
      Defaulted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Configure",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left : Integer; Mode : Boolean := False)");
      Named_Defaulted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Configure",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left : Integer := 0; Mode : Boolean)");

      Assert (Required_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Defaulted_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Named_Defaulted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain overloads with and without defaulted formals");

      One_Actual := Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope
        (Analysis, "Configure", Pkg_Id, "Integer");
      Assert (Natural (One_Actual.Matches.Length) = 1
              and then One_Actual.Matches.First_Element = Defaulted_Id,
              "overload resolution should accept omitted trailing formals only when they have defaults");

      Named_Actual := Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope
        (Analysis, "Configure", Pkg_Id, "Mode => Boolean");
      Assert (Natural (Named_Actual.Matches.Length) = 1
              and then Named_Actual.Matches.First_Element = Named_Defaulted_Id,
              "named actuals may skip earlier formals only when skipped formals have defaults");
   end Test_Resolver_Call_Overload_Resolution_Uses_Defaulted_Formals;




   procedure Test_Resolver_Expression_Aware_Overload_Resolution
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Pkg_Id : Editor.Ada_Language_Model.Symbol_Id;
      Integer_Type_Id : Editor.Ada_Language_Model.Symbol_Id;
      Boolean_Type_Id : Editor.Ada_Language_Model.Symbol_Id;
      I_Id : Editor.Ada_Language_Model.Symbol_Id;
      B_Id : Editor.Ada_Language_Model.Symbol_Id;
      Use_Integer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Use_Boolean_Id : Editor.Ada_Language_Model.Symbol_Id;
      Make_Integer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Make_Boolean_Id : Editor.Ada_Language_Model.Symbol_Id;
      Choose_Integer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Choose_Boolean_Id : Editor.Ada_Language_Model.Symbol_Id;
      From_Object : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Literal : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Named : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Nested_Call : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Expected_Result : Editor.Ada_Symbol_Resolver.Resolution_Result;
   begin
      Pkg_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Demo",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 4));
      Integer_Type_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Integer",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 11),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id);
      Boolean_Type_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Boolean",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 11),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id);
      I_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "I",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 5),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => ": Integer");
      B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "B",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 5),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => ": Boolean");
      Use_Integer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Use_Value",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Value : Integer)");
      Use_Boolean_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Use_Value",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 7, Start_Column => 4, End_Line => 7, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Value : Boolean)");
      Make_Integer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Make",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 8, Start_Column => 4, End_Line => 8, End_Column => 8),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "() return Integer");
      Make_Boolean_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Make_Flag",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 9, Start_Column => 4, End_Line => 9, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "() return Boolean");
      Choose_Integer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Choose",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 10, Start_Column => 4, End_Line => 10, End_Column => 10),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "() return Integer");
      Choose_Boolean_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Choose",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 11, Start_Column => 4, End_Line => 11, End_Column => 10),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "() return Boolean");

      Assert (Integer_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Boolean_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then I_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Choose_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Choose_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain expression-aware overload symbols");

      From_Object := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "I");
      Assert (Natural (From_Object.Matches.Length) = 1
              and then From_Object.Matches.First_Element = Use_Integer_Id,
              "expression-aware overload resolution should infer object subtype metadata");

      From_Literal := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "True");
      Assert (Natural (From_Literal.Matches.Length) = 1
              and then From_Literal.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should infer Boolean literal actuals");

      From_Named := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "Value => B");
      Assert (Natural (From_Named.Matches.Length) = 1
              and then From_Named.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should preserve named associations");

      From_Nested_Call := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "Make()");
      Assert (Natural (From_Nested_Call.Matches.Length) = 1
              and then From_Nested_Call.Matches.First_Element = Use_Integer_Id,
              "expression-aware overload resolution should use unique nested function result types");

      From_Expected_Result := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Choose", Pkg_Id, "", "I");
      Assert (Natural (From_Expected_Result.Matches.Length) = 1
              and then From_Expected_Result.Matches.First_Element = Choose_Integer_Id,
              "expression-aware overload resolution should infer expected result types from target expressions");
   end Test_Resolver_Expression_Aware_Overload_Resolution;




   procedure Test_Language_Model_Split_Function_Return_Body_Opens_Callable_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Function_Body is" & ASCII.LF &
        "   function Compute" & ASCII.LF &
        "     (Input : Integer)" & ASCII.LF &
        "      return Boolean" & ASCII.LF &
        "   is" & ASCII.LF &
        "      Accepted : constant Boolean := Input > 0;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Accepted;" & ASCII.LF &
        "   end Compute;" & ASCII.LF &
        "end Split_Function_Body;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "split_function_body.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "Split_Function_Body");
      Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Compute", Package_Id);
      Input_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Input", Compute_Id);
      Accepted_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Accepted", Compute_Id);
      Accepted_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Accepted_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Compute_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split-function body test should have package and function symbols");
      Assert (Input_Id /= Editor.Ada_Language_Model.No_Symbol,
              "function parameters should remain parented to the callable after a split profile");
      Assert (Accepted_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then Accepted_Info.Parent_Symbol = Compute_Id,
              "a split function return line before is should not lose the callable body scope");
   end Test_Language_Model_Split_Function_Return_Body_Opens_Callable_Scope;






   procedure Test_Language_Model_Exposes_Scoped_Overload_Sets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   procedure Run (Left : Integer);" & ASCII.LF &
        "   procedure Run (Left : Boolean);" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "      procedure Run;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "overloads.ads");
      Demo_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Demo");
      Nested_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Nested", Demo_Id);
      Demo_Scope : constant Editor.Ada_Language_Model.Scope_Id :=
        Editor.Ada_Language_Model.Scope_Id (Natural (Demo_Id));
      Nested_Scope : constant Editor.Ada_Language_Model.Scope_Id :=
        Editor.Ada_Language_Model.Scope_Id (Natural (Nested_Id));
      First_Run : Editor.Ada_Language_Model.Symbol_Id;
      Second_Run : Editor.Ada_Language_Model.Symbol_Id;
      Third_Run : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Assert (Demo_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Nested_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should parse the package and nested package scopes");

      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Demo_Scope, "Run") = 2,
              "language model should expose the same-scope overload set count");
      First_Run := Editor.Ada_Language_Model.Overload_At
        (Analysis, Demo_Scope, "Run", 1);
      Second_Run := Editor.Ada_Language_Model.Overload_At
        (Analysis, Demo_Scope, "Run", 2);
      Third_Run := Editor.Ada_Language_Model.Overload_At
        (Analysis, Demo_Scope, "Run", 3);
      Assert (First_Run /= Editor.Ada_Language_Model.No_Symbol
              and then Second_Run /= Editor.Ada_Language_Model.No_Symbol
              and then First_Run /= Second_Run,
              "overload access should preserve deterministic declaration order");
      Assert (Third_Run = Editor.Ada_Language_Model.No_Symbol,
              "out-of-range overload lookup should degrade to No_Symbol");

      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Nested_Scope, "Run") = 1,
              "nested scope overload count must not include same-name declarations from the parent scope");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Demo_Scope, "Missing") = 0,
              "missing overload set should report zero members");
   end Test_Language_Model_Exposes_Scoped_Overload_Sets;




   procedure Test_Language_Model_Invalid_Scope_Overload_Lookup_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Owner_Id : Editor.Ada_Language_Model.Symbol_Id;
      First_Id : Editor.Ada_Language_Model.Symbol_Id;
      Second_Id : Editor.Ada_Language_Model.Symbol_Id;
      Invalid_Scope : constant Editor.Ada_Language_Model.Scope_Id := 99;
   begin
      Owner_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Owner",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 5));
      First_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 7),
         Enclosing_Scope => Invalid_Scope);
      Second_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 7),
         Enclosing_Scope => Invalid_Scope);

      Assert (Owner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then First_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Second_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert owner plus malformed overload rows");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Invalid_Scope, "Run") = 0,
              "invalid overload scope ids must not expose malformed overload rows");
      Assert (Editor.Ada_Language_Model.Overload_At
                (Analysis, Invalid_Scope, "Run", 1)
              = Editor.Ada_Language_Model.No_Symbol,
              "invalid overload scope lookup should degrade to No_Symbol");
   end Test_Language_Model_Invalid_Scope_Overload_Lookup_Degrades;




   procedure Test_Language_Model_Non_Owner_Scope_Overload_Lookup_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Object_Id : Editor.Ada_Language_Model.Symbol_Id;
      Run_Id    : Editor.Ada_Language_Model.Symbol_Id;
      Object_Scope : Editor.Ada_Language_Model.Scope_Id;
   begin
      Object_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Counter",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 7));
      Object_Scope := Editor.Ada_Language_Model.Scope_Id (Natural (Object_Id));
      Run_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 7),
         Enclosing_Scope => Object_Scope,
         Parent_Symbol => Object_Id);

      Assert (Object_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain malformed object-owned overload rows");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Object_Scope, "Run") = 0,
              "object ids must not be accepted as declaration-owning overload scopes");
      Assert (Editor.Ada_Language_Model.Overload_At
                (Analysis, Object_Scope, "Run", 1)
              = Editor.Ada_Language_Model.No_Symbol,
              "non-owner overload scope lookup should degrade to No_Symbol");
   end Test_Language_Model_Non_Owner_Scope_Overload_Lookup_Degrades;




   procedure Test_Language_Model_Overload_Lookup_Requires_Matching_Parent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Package_A : Editor.Ada_Language_Model.Symbol_Id;
      Package_B : Editor.Ada_Language_Model.Symbol_Id;
      Mismatched_Run : Editor.Ada_Language_Model.Symbol_Id;
      Valid_Run : Editor.Ada_Language_Model.Symbol_Id;
      A_Scope : Editor.Ada_Language_Model.Scope_Id;
   begin
      Package_A := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "A",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      Package_B := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "B",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 2, Start_Column => 1, End_Line => 2, End_Column => 1));
      A_Scope := Editor.Ada_Language_Model.Scope_Id (Package_A);

      Mismatched_Run := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 7),
         Enclosing_Scope => A_Scope,
         Parent_Symbol   => Package_B,
         Depth           => 1);
      Valid_Run := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 7),
         Enclosing_Scope => A_Scope,
         Parent_Symbol   => Package_A,
         Depth           => 1);

      Assert (Package_A /= Editor.Ada_Language_Model.No_Symbol
                and then Package_B /= Editor.Ada_Language_Model.No_Symbol
                and then Mismatched_Run /= Editor.Ada_Language_Model.No_Symbol
                and then Valid_Run /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert package scopes and overload rows");
      Assert (Editor.Ada_Language_Model.Overload_Count (Analysis, A_Scope, "Run") = 1,
              "overload traversal must reject rows whose scope and parent stamps disagree");
      Assert (Editor.Ada_Language_Model.Overload_At (Analysis, A_Scope, "Run", 1) = Valid_Run,
              "valid direct overload remains visible after rejecting mismatched ownership");
      Assert (Editor.Ada_Language_Model.Overload_At
                (Analysis, A_Scope, "Run", 2) = Editor.Ada_Language_Model.No_Symbol,
              "mismatched ownership row is not exposed at a later overload index");
   end Test_Language_Model_Overload_Lookup_Requires_Matching_Parent;



   procedure Test_Ada_Use_Type_Operator_Visibility_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Use_Type_Operators.Primitive_Use_Kind;
      use type Editor.Ada_Use_Type_Operators.Primitive_Use_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Numeric_Library is" & ASCII.LF &
        "   type Amount is new Integer;" & ASCII.LF &
        "   function ""+"" (Left, Right : Amount) return Amount;" & ASCII.LF &
        "   function Image (Value : Amount) return Integer;" & ASCII.LF &
        "end Numeric_Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   use type Numeric_Library.Amount;" & ASCII.LF &
        "   use all type Numeric_Library.Amount;" & ASCII.LF &
        "   Value : Numeric_Library.Amount;" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);

      function Last_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
         Result : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
            begin
               if Info.Kind = Kind then
                  Result := Info.Id;
               end if;
            end;
         end loop;
         return Result;
      end Last_Region;

      function Count_Status
        (Status : Editor.Ada_Use_Type_Operators.Primitive_Use_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Use_Type_Operators.Primitive_Use_Count (Primitive_Uses) loop
            if Editor.Ada_Use_Type_Operators.Primitive_Use_At
                 (Primitive_Uses, Index).Status = Status
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Status;

      function Count_Kind
        (Kind : Editor.Ada_Use_Type_Operators.Primitive_Use_Kind)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Use_Type_Operators.Primitive_Use_Count (Primitive_Uses) loop
            if Editor.Ada_Use_Type_Operators.Primitive_Use_At
                 (Primitive_Uses, Index).Kind = Kind
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Kind;

      Client_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Last_Region (Editor.Ada_Declarative_Regions.Region_Package_Body);
      Plus_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Use_Type_Operators.Lookup_Operator
          (Primitive_Uses, Client_Body, "+");
   begin
      Assert (Editor.Ada_Use_Type_Operators.Has_Primitive_Uses (Primitive_Uses),
              "use-type operator model must retain primitive-use entries");
      Assert (Client_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "client package body region must exist for use-type visibility");
      Assert (Count_Status (Editor.Ada_Use_Type_Operators.Primitive_Use_Found) >= 2,
              "use type and use all type clauses must resolve the target type and primitive declarations");
      Assert (Count_Kind (Editor.Ada_Use_Type_Operators.Primitive_Use_Type_Operator) >= 1,
              "use type must expose primitive operator declarations as operator candidates");
      Assert (Count_Kind (Editor.Ada_Use_Type_Operators.Primitive_Use_All_Type_Subprogram) >= 1,
              "use all type must expose primitive subprogram declarations as candidates");
      Assert (Plus_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found
              or else Plus_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous,
              "operator lookup must find plus through use-type primitive visibility");
      Assert (Editor.Ada_Use_Type_Operators.Fingerprint (Primitive_Uses) /= 0,
              "use-type primitive model must expose deterministic non-zero fingerprints");
   end Test_Ada_Use_Type_Operator_Visibility_Foundation;



   procedure Test_Ada_Call_Profile_Shape_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
      use type Editor.Ada_Call_Profile_Shapes.Actual_Profile_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Profiles is" & ASCII.LF &
        "   function Convert (Left, Right : Integer) return Integer;" & ASCII.LF &
        "   procedure Log (Message : String; Count : Integer := 1);" & ASCII.LF &
        "end Profiles;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   A : Integer := Convert (1, Right => 2);" & ASCII.LF &
        "   B : Integer := Convert ();" & ASCII.LF &
        "   procedure Local (X, Y : Integer) is null;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Log (Message => ""done"", Count => 1);" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);

      function Count_Callable_Status
        (Status : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Callable_Profile_Count (Shapes) loop
            if Editor.Ada_Call_Profile_Shapes.Callable_Profile_At
                 (Shapes, Index).Status = Status
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Callable_Status;

      function Count_Actual_Status
        (Status : Editor.Ada_Call_Profile_Shapes.Actual_Profile_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Actual_Profile_Count (Shapes) loop
            if Editor.Ada_Call_Profile_Shapes.Actual_Profile_At
                 (Shapes, Index).Status = Status
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Actual_Status;

      function Has_Callable_Profile
        (Name : String;
         Parameters : Natural;
         Has_Result : Boolean) return Boolean
      is
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Callable_Profile_Count (Shapes) loop
            declare
               Info : constant Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info :=
                 Editor.Ada_Call_Profile_Shapes.Callable_Profile_At (Shapes, Index);
            begin
               if To_String (Info.Normalized_Name) = Name
                 and then Info.Parameter_Count = Parameters
                 and then Info.Has_Result = Has_Result
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Callable_Profile;

      function Has_Actual_Profile
        (Name : String;
         Positional : Natural;
         Named : Natural;
         Total : Natural) return Boolean
      is
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Actual_Profile_Count (Shapes) loop
            declare
               Info : constant Editor.Ada_Call_Profile_Shapes.Actual_Profile_Info :=
                 Editor.Ada_Call_Profile_Shapes.Actual_Profile_At (Shapes, Index);
            begin
               if To_String (Info.Normalized_Name) = Name
                 and then Info.Positional_Count = Positional
                 and then Info.Named_Count = Named
                 and then Info.Total_Actual_Count = Total
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Actual_Profile;
   begin
      Assert (Editor.Ada_Call_Profile_Shapes.Has_Callable_Profiles (Shapes),
              "call-profile shape model must retain callable declarations");
      Assert (Editor.Ada_Call_Profile_Shapes.Has_Actual_Profiles (Shapes),
              "call-profile shape model must retain actual argument shapes");
      Assert (Has_Callable_Profile ("convert", 2, True),
              "function profile shape must count formal parameters and result subtype");
      Assert (Has_Callable_Profile ("log", 2, False),
              "procedure profile shape must count semicolon-separated formal groups");
      Assert (Has_Callable_Profile ("local", 2, False),
              "null procedure profile shape must count comma-separated formal names");
      Assert (Has_Actual_Profile ("convert", 1, 1, 2),
              "actual shape must distinguish positional and named actuals");
      Assert (Has_Actual_Profile ("log", 0, 2, 2),
              "actual shape must count all named actual associations");
      Assert (Count_Callable_Status
                (Editor.Ada_Call_Profile_Shapes.Callable_Profile_Found) >= 3,
              "callable profile extraction must record found profile shapes");
      Assert (Count_Actual_Status
                (Editor.Ada_Call_Profile_Shapes.Actual_Profile_No_Arguments) >= 1,
              "actual profile extraction must distinguish nullary call syntax");
      Assert (Editor.Ada_Call_Profile_Shapes.Fingerprint (Shapes) /= 0,
              "call-profile shape model must expose deterministic non-zero fingerprints");
   end Test_Ada_Call_Profile_Shape_Foundation;




   procedure Test_Ada_Call_Profile_Filter_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   procedure Apply (Left, Right : Integer) is null;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Apply (1, 2);" & ASCII.LF &
        "   Apply (1, 2, 3);" & ASCII.LF &
        "   Apply (Left => 1, Right => 2);" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build (Candidates, Shapes, Visibility);

      function Count_Status
        (Status : Editor.Ada_Call_Profile_Filters.Profile_Filter_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Filters.Profile_Filter_Count (Filters) loop
            if Editor.Ada_Call_Profile_Filters.Profile_Filter_At
                 (Filters, Index).Status = Status
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Status;
   begin
      Assert (Editor.Ada_Call_Profile_Filters.Has_Profile_Filters (Filters),
              "profile-filter model must retain call candidate filter entries");
      Assert (Count_Status
                (Editor.Ada_Call_Profile_Filters.Profile_Filter_Arity_Compatible) >= 1,
              "profile filtering must preserve arity-compatible positional calls");
      Assert (Count_Status
                (Editor.Ada_Call_Profile_Filters.Profile_Filter_Too_Many_Actuals) >= 1,
              "profile filtering must reject calls with more actuals than formal parameters");
      Assert (Count_Status
                (Editor.Ada_Call_Profile_Filters.Profile_Filter_Formal_Name_Compatible) >= 1,
              "profile filtering must retain formal-name-compatible named actual calls");
      Assert (Editor.Ada_Call_Profile_Filters.Fingerprint (Filters) /= 0,
              "profile-filter model must expose deterministic non-zero fingerprints");
   end Test_Ada_Call_Profile_Filter_Foundation;




   procedure Test_Ada_Call_Profile_Formal_Name_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   procedure Apply (Left : Integer; Right : Integer := 0) is null;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Apply (Left => 1, Right => 2);" & ASCII.LF &
        "   Apply (Left => 1, Unknown => 2);" & ASCII.LF &
        "   Apply ();" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build (Candidates, Shapes, Visibility);

      function Count_Status
        (Status : Editor.Ada_Call_Profile_Filters.Profile_Filter_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Filters.Profile_Filter_Count (Filters) loop
            if Editor.Ada_Call_Profile_Filters.Profile_Filter_At
                 (Filters, Index).Status = Status
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Status;

      function Has_Defaulted_Formal return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Call_Profile_Shapes.Callable_Profile_Count (Shapes) loop
            declare
               Info : constant Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info :=
                 Editor.Ada_Call_Profile_Shapes.Callable_Profile_At (Shapes, Index);
            begin
               if To_String (Info.Normalized_Name) = "apply"
                 and then Info.Parameter_Count = 2
                 and then Info.Defaulted_Parameter_Count = 1
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Defaulted_Formal;
   begin
      Assert (Has_Defaulted_Formal,
              "callable shape metadata must retain defaulted formal counts");
      Assert (Count_Status
                (Editor.Ada_Call_Profile_Filters.Profile_Filter_Formal_Name_Compatible) >= 1,
              "profile filtering must accept named actuals whose names match formals");
      Assert (Count_Status
                (Editor.Ada_Call_Profile_Filters.Profile_Filter_Unknown_Named_Actual) >= 1,
              "profile filtering must reject named actuals that do not name a formal");
      Assert (Count_Status
                (Editor.Ada_Call_Profile_Filters.Profile_Filter_Missing_Required_Formal) >= 1,
              "profile filtering must reject calls that omit non-defaulted formals");
      Assert (Editor.Ada_Call_Profile_Filters.Fingerprint (Filters) /= 0,
              "formal-name filter model must keep deterministic fingerprints");
   end Test_Ada_Call_Profile_Formal_Name_Filter;




   procedure Test_Ada_Expected_Call_Filter_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   function Make_Integer (X : Integer) return Integer is (X);" & ASCII.LF &
        "   function Make_Flag (X : Integer) return Boolean is (True);" & ASCII.LF &
        "   procedure Touch (X : Integer) is null;" & ASCII.LF &
        "   A : Integer := Make_Integer (1);" & ASCII.LF &
        "   B : Integer := Make_Flag (2);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Touch (3);" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build (Candidates, Shapes, Visibility);
      Resolutions : constant Editor.Ada_Call_Resolution.Call_Resolution_Model :=
        Editor.Ada_Call_Resolution.Build (Candidates, Filters);
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build
          (Tree, Regions, Shapes, Resolutions);
      Expected_Filters : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model :=
        Editor.Ada_Expected_Call_Filters.Build
          (Expected, Resolutions, Filters, Shapes);
   begin
      Assert (Editor.Ada_Expected_Call_Filters.Has_Expected_Call_Filters (Expected_Filters),
              "expected-call filter model must retain expected-subtype filter entries");
      Assert (Editor.Ada_Expected_Call_Filters.Count_Status
                (Expected_Filters,
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Matches) >= 1,
              "expected-call filtering must retain result subtypes matching the expected context");
      Assert (Editor.Ada_Expected_Call_Filters.Count_Status
                (Expected_Filters,
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Mismatch) >= 1,
              "expected-call filtering must mark result subtypes mismatching the expected context");
      Assert (Editor.Ada_Expected_Call_Filters.Count_Status
                (Expected_Filters,
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Context_Not_Found) >= 1,
              "expected-call filtering must preserve context-free calls for later diagnostics");
      Assert (Editor.Ada_Expected_Call_Filters.Fingerprint (Expected_Filters) /= 0,
              "expected-call filter model must keep deterministic fingerprints");
   end Test_Ada_Expected_Call_Filter_Foundation;



   procedure Test_Ada_Expected_Call_Filter_Resolves_Result_Overloads
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
      use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
      use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id;
      use type Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   function Make (X : Integer) return Integer is (X);" & ASCII.LF &
        "   function Make (X : Integer) return Boolean is (True);" & ASCII.LF &
        "   procedure Need_Int (Y : Integer) is null;" & ASCII.LF &
        "   procedure Need_Bool (Y : Boolean) is null;" & ASCII.LF &
        "   procedure Need_Pair (X : Integer; Y : Boolean) is null;" & ASCII.LF &
        "   procedure Need_Named (Left : Integer; Right : Boolean) is null;" & ASCII.LF &
        "   A : Integer := Make (1);" & ASCII.LF &
        "   B : Boolean := Make (2);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   A := Make (3);" & ASCII.LF &
        "   B := Make (4);" & ASCII.LF &
        "   Need_Int (Make (5));" & ASCII.LF &
        "   Need_Bool (Make (6));" & ASCII.LF &
        "   Need_Pair (0, Make (7));" & ASCII.LF &
        "   Need_Named (Left => 1, Right => Make (8));" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build (Candidates, Shapes, Visibility);
      Resolutions : constant Editor.Ada_Call_Resolution.Call_Resolution_Model :=
        Editor.Ada_Call_Resolution.Build (Candidates, Filters);
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build
          (Tree, Regions, Visibility, Shapes, Resolutions);
      Expected_Filters : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model :=
        Editor.Ada_Expected_Call_Filters.Build
          (Expected, Resolutions, Filters, Shapes);
      Overload_Contexts :
        constant Editor.Ada_Overload_Resolution_Legality.Overload_Context_Model :=
          Editor.Ada_Overload_Resolution_Legality.Build_Contexts_From_Expected_Call_Filters
            (Expected_Filters);
      Rankings : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      Wide : Editor.Ada_Wide_Semantic_Legality_Diagnostics.Wide_Semantic_Diagnostic_Model;
      Overload_Legality :
        constant Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Model :=
          Editor.Ada_Overload_Resolution_Legality.Build
            (Overload_Contexts, Rankings, Wide);
      Ambiguous_Profile_Count : Natural := 0;
      Selected_By_Result_Count : Natural := 0;
      Ambiguous_Selected_Node_Count : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Call_Resolution.Call_Resolution_Count (Resolutions) loop
         declare
            Info : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
              Editor.Ada_Call_Resolution.Call_Resolution_At (Resolutions, Index);
         begin
            if Info.Status =
              Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
            then
               Ambiguous_Profile_Count := Ambiguous_Profile_Count + 1;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Expected_Filters) loop
         declare
            Info : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info :=
              Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At
                (Expected_Filters, Index);
         begin
            if Info.Status =
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Matches
              and then Info.Callable_Profile /=
                Editor.Ada_Call_Profile_Shapes.No_Callable_Profile
            then
               Selected_By_Result_Count := Selected_By_Result_Count + 1;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Overload_Resolution_Legality.Legality_Count (Overload_Legality) loop
         declare
            Row : constant Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Info :=
              Editor.Ada_Overload_Resolution_Legality.Legality_At
                (Overload_Legality, Index);
            Node_Has_Expected_Selection : Boolean := False;
         begin
            if Row.Status =
              Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Ambiguous_After_Preference
            then
               for Filter_Index in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Expected_Filters) loop
                  declare
                     Filter : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info :=
                       Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At
                         (Expected_Filters, Filter_Index);
                  begin
                     if Filter.Call_Node = Row.Node
                       and then Filter.Status =
                         Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Matches
                     then
                        Node_Has_Expected_Selection := True;
                     end if;
                  end;
               end loop;

               if Node_Has_Expected_Selection then
                  Ambiguous_Selected_Node_Count := Ambiguous_Selected_Node_Count + 1;
               end if;
            end if;
         end;
      end loop;

      Assert (Ambiguous_Profile_Count >= 2,
              "profile-only call resolution must expose result-overload ambiguity");
      Assert (Selected_By_Result_Count >= 8,
              "expected-call filtering must select result overloads by defaults, assignments, and positional/named parameter actuals");
      Assert (Editor.Ada_Overload_Resolution_Legality.Count_Status
                (Overload_Legality,
                 Editor.Ada_Overload_Resolution_Legality
                   .Overload_Legality_Legal_Expected_Type_Preferred) >= 4,
              "expected-call result selection must feed deduplicated overload legality contexts");
      Assert (Ambiguous_Selected_Node_Count = 0,
              "expected-call selected overload nodes must suppress stale ambiguity rows");
   end Test_Ada_Expected_Call_Filter_Resolves_Result_Overloads;




   procedure Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
      use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
      use type Editor.Ada_Type_Graph.Compatibility_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   type Amount is range 0 .. 100;" & ASCII.LF &
        "   type USD is new Amount;" & ASCII.LF &
        "   subtype Positive_USD is USD range 1 .. 100;" & ASCII.LF &
        "   type Count is range 0 .. 10;" & ASCII.LF &
        "   type Flag is new Count;" & ASCII.LF &
        "   function Make_USD (X : Integer) return USD is (USD (X));" & ASCII.LF &
        "   function Make_Positive (X : Integer) return Positive_USD is (Positive_USD (X));" & ASCII.LF &
        "   function Make_Flag (X : Integer) return Flag is (Flag (X));" & ASCII.LF &
        "   A : Amount := Make_USD (1);" & ASCII.LF &
        "   B : Amount := Make_Positive (1);" & ASCII.LF &
        "   C : USD := Make_Flag (1);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build (Candidates, Shapes, Visibility);
      Resolutions : constant Editor.Ada_Call_Resolution.Call_Resolution_Model :=
        Editor.Ada_Call_Resolution.Build (Candidates, Filters);
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build
          (Tree, Regions, Shapes, Resolutions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Expected_Filters : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model :=
        Editor.Ada_Expected_Call_Filters.Build_With_Type_Graph
          (Expected, Resolutions, Filters, Shapes, Types);
   begin
      Assert (Editor.Ada_Expected_Call_Filters.Count_Status
                (Expected_Filters,
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Compatible) >= 1,
              "expected-call filtering must accept subtype result compatibility");
      Assert (Editor.Ada_Expected_Call_Filters.Count_Status
                (Expected_Filters,
                 Editor.Ada_Expected_Call_Filters
                   .Expected_Call_Filter_Result_Subtype_Requires_Explicit_Conversion) >= 1,
              "expected-call filtering must require explicit conversions for derived specific types");
      Assert (Editor.Ada_Expected_Call_Filters.Count_Status
                (Expected_Filters,
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Mismatch) >= 1,
              "expected-call filtering must reject known different type-graph roots");
      declare
         Compatible : Natural := 0;
         Derived : Natural := 0;
         Subtype_Of : Natural := 0;
         Different_Root : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Expected_Filters) loop
            declare
               Info : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info :=
                 Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At (Expected_Filters, Index);
            begin
               if Info.Compatibility =
                 Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Derived_From
               then
                  Compatible := Compatible + 1;
                  Derived := Derived + 1;
               elsif Info.Compatibility =
                 Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Subtype_Of
               then
                  Compatible := Compatible + 1;
                  Subtype_Of := Subtype_Of + 1;
               end if;

               if Info.Type_Compatibility =
                 Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root
               then
                  Different_Root := Different_Root + 1;
               end if;
            end;
         end loop;
         Assert (Compatible >= 2 and then Derived >= 1 and then Subtype_Of >= 1,
                 "expected-call filters must retain type-graph derived/subtype compatibility metadata");
         Assert (Different_Root >= 1,
                 "expected-call filters must retain known-different-root type-graph metadata");
      end;
      Assert (Editor.Ada_Expected_Call_Filters.Fingerprint (Expected_Filters) /= 0,
              "type-graph-aware expected-call filters must keep deterministic fingerprints");
   end Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility;



   procedure Test_Ada_Call_Resolution_Profile_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   procedure Apply (Left : Integer; Right : Integer := 0) is null;" & ASCII.LF &
        "   procedure Needs_Two (Left : Integer; Right : Integer) is null;" & ASCII.LF &
        "   procedure Overloaded (Left : Integer) is null;" & ASCII.LF &
        "   procedure Overloaded (Left : Integer; Right : Integer) is null;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Apply (Left => 1);" & ASCII.LF &
        "   Needs_Two (1, 2, 3);" & ASCII.LF &
        "   Missing (1);" & ASCII.LF &
        "   Overloaded (1);" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build (Candidates, Shapes, Visibility);
      Resolutions : constant Editor.Ada_Call_Resolution.Call_Resolution_Model :=
        Editor.Ada_Call_Resolution.Build (Candidates, Filters);
   begin
      Assert (Editor.Ada_Call_Resolution.Has_Call_Resolutions (Resolutions),
              "call-resolution model must classify call-shaped syntax nodes");
      Assert (Editor.Ada_Call_Resolution.Count_Status
                (Resolutions,
                 Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match) >= 1,
              "call-resolution model must classify a single viable profile match");
      Assert (Editor.Ada_Call_Resolution.Count_Status
                (Resolutions,
                 Editor.Ada_Call_Resolution.Call_Resolution_No_Viable_Profile) >= 1,
              "call-resolution model must classify calls whose candidates fail profile filters");
      Assert (Editor.Ada_Call_Resolution.Count_Status
                (Resolutions,
                 Editor.Ada_Call_Resolution.Call_Resolution_Unresolved_Name) >= 1,
              "call-resolution model must classify unresolved call designators");
      Assert (Editor.Ada_Call_Resolution.Count_Status
                (Resolutions,
                 Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile) >= 1,
              "call-resolution model must retain pre-profile ambiguity for later overload work");
      Assert (Editor.Ada_Call_Resolution.Fingerprint (Resolutions) /= 0,
              "call-resolution model must keep deterministic fingerprints");
   end Test_Ada_Call_Resolution_Profile_Result;



   procedure Test_Ada_Call_Candidate_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      use type Editor.Ada_Call_Candidates.Call_Candidate_Status;
      use type Editor.Ada_Call_Candidates.Candidate_Source;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Tools is" & ASCII.LF &
        "   function Convert (Value : Integer) return Integer;" & ASCII.LF &
        "end Tools;" & ASCII.LF &
        "package Library is" & ASCII.LF &
        "   type Amount is new Integer;" & ASCII.LF &
        "   function ""+"" (Left, Right : Amount) return Amount;" & ASCII.LF &
        "end Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   use Tools;" & ASCII.LF &
        "   use type Library.Amount;" & ASCII.LF &
        "   A : Integer := Convert (1);" & ASCII.LF &
        "   B : Library.Amount := ""+"" (1, 2);" & ASCII.LF &
        "   C : Integer := Missing (3);" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);

      function Last_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
         Result : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
            begin
               if Info.Kind = Kind then
                  Result := Info.Id;
               end if;
            end;
         end loop;
         return Result;
      end Last_Region;

      function Count_Status
        (Status : Editor.Ada_Call_Candidates.Call_Candidate_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Call_Candidates.Call_Candidate_Count (Candidates) loop
            if Editor.Ada_Call_Candidates.Call_Candidate_At
                 (Candidates, Index).Status = Status
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Status;

      function Count_Source
        (Source : Editor.Ada_Call_Candidates.Candidate_Source)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Call_Candidates.Call_Candidate_Count (Candidates) loop
            if Editor.Ada_Call_Candidates.Call_Candidate_At
                 (Candidates, Index).Source = Source
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Source;

      Client_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Last_Region (Editor.Ada_Declarative_Regions.Region_Package_Body);
      Convert_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Call_Candidates.Lookup_Call
          (Visibility, Uses, Regions, Primitive_Uses, Client_Body, "Convert");
      Plus_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Call_Candidates.Lookup_Call
          (Visibility, Uses, Regions, Primitive_Uses, Client_Body, "+");
      Missing_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Call_Candidates.Lookup_Call
          (Visibility, Uses, Regions, Primitive_Uses, Client_Body, "Missing");
   begin
      Assert (Editor.Ada_Call_Candidates.Has_Call_Candidates (Candidates),
              "call-candidate model must retain call-shaped syntax nodes");
      Assert (Client_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "client package body region must exist for call lookup");
      Assert (Convert_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found
              or else Convert_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous,
              "call lookup must resolve a subprogram made visible through a package use clause");
      Assert (Plus_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found
              or else Plus_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous,
              "call lookup must include primitive operators made visible through use type");
      Assert (Missing_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found,
              "call lookup must preserve deterministic unresolved-call status");
      Assert (Count_Status (Editor.Ada_Call_Candidates.Call_Candidate_Found) >= 1
              or else Count_Status (Editor.Ada_Call_Candidates.Call_Candidate_Ambiguous) >= 1,
              "call-candidate model must record found or ambiguous callable candidates");
      Assert (Count_Source (Editor.Ada_Call_Candidates.Candidate_Use_Type_Primitive) >= 1,
              "call-candidate model must distinguish primitive candidates from use-type visibility");
      Assert (Editor.Ada_Call_Candidates.Fingerprint (Candidates) /= 0,
              "call-candidate model must expose deterministic non-zero fingerprints");
   end Test_Ada_Call_Candidate_Foundation;




   procedure Test_Language_Model_Executable_Expression_Call_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Counter : Integer := 0;" & ASCII.LF &
        "   function Ready (Value : Integer) return Boolean is (True);" & ASCII.LF &
        "   function Next (Value : Integer) return Integer is (Value + 1);" & ASCII.LF &
        "   procedure Sink (Value : Integer) is null;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready (Counter) then" & ASCII.LF &
        "      Counter := Next (Counter);" & ASCII.LF &
        "      Sink (Next (Counter));" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_expression_calls.adb");
      Call_Count : constant Natural :=
        Editor.Ada_Language_Model.Executable_Binding_Count
          (Analysis, Editor.Ada_Language_Model.Binding_Call_Target);
      Ready_Bindings : Natural := 0;
      Next_Bindings  : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Language_Model.Executable_Binding_Count (Analysis) loop
         declare
            B : constant Editor.Ada_Language_Model.Executable_Binding_Info :=
              Editor.Ada_Language_Model.Executable_Binding_At (Analysis, Index);
            N : constant String :=
              Editor.Ada_Language_Model.Normalize_Name
                (Ada.Strings.Unbounded.To_String (B.Name));
         begin
            if B.Kind = Editor.Ada_Language_Model.Binding_Call_Target
              and then N = "ready"
            then
               Ready_Bindings := Ready_Bindings + 1;
            elsif B.Kind = Editor.Ada_Language_Model.Binding_Call_Target
              and then N = "next"
            then
               Next_Bindings := Next_Bindings + 1;
            end if;
         end;
      end loop;

      Assert (Call_Count >= 4,
              "embedded executable expression calls should be retained as call-target bindings");
      Assert (Ready_Bindings = 1,
              "if-condition call target should be retained exactly once");
      Assert (Next_Bindings >= 2,
              "assignment RHS and nested actual call targets should be retained");
   end Test_Language_Model_Executable_Expression_Call_Bindings;




   procedure Test_Language_Model_Legality_Call_Named_Actual_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure P is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Configure (Mode => Fast, Count => 1, Mode => Slow);" & ASCII.LF &
        "   Configure (Mode => Fast);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Named_Actual : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "duplicate call named actuals should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Duplicate_Call_Named_Actual then
               Seen_Duplicate_Named_Actual := True;
            end if;
         end;
      end loop;

      Assert (Seen_Duplicate_Named_Actual,
              "legality checking should flag duplicate named actuals within a single call");
   end Test_Language_Model_Legality_Call_Named_Actual_Pass;






   procedure Test_Language_Model_Call_Ambiguity_Resolver_Hints
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Call_Ambiguity_Hints is" & ASCII.LF &
        "   type Table is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Store : Table (1 .. 10);" & ASCII.LF &
        "   procedure Start (Priority : Integer);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Worker.Start (Priority => 1);" & ASCII.LF &
        "   Obj.Op (Arg);" & ASCII.LF &
        "   Store (Index);" & ASCII.LF &
        "   Start (Priority => 2);" & ASCII.LF &
        "end Call_Ambiguity_Hints;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "call_ambiguity_hints.adb");

      function Count_Binding
        (Kind : Editor.Ada_Language_Model.Executable_Binding_Kind) return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Language_Model.Executable_Binding_Count (Analysis) loop
            if Editor.Ada_Language_Model.Executable_Binding_At (Analysis, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Binding;
   begin
      Assert
        (Count_Binding
           (Editor.Ada_Language_Model.Binding_Call_Selected_Prefix) >= 2,
         "selected call prefixes must be projected as resolver-facing hints");
      Assert
        (Count_Binding
           (Editor.Ada_Language_Model.Binding_Call_Selected_Operation) >= 2,
         "selected call operation leaves must be projected as resolver-facing hints");
      Assert
        (Count_Binding
           (Editor.Ada_Language_Model.Binding_Call_Dispatching_Prefix) >= 2,
         "dispatching-style prefixes must be projected without overload resolution");
      Assert
        (Count_Binding
           (Editor.Ada_Language_Model.Binding_Call_Indexed_Prefix) >= 1,
         "indexed call prefixes must be projected as call/index ambiguity hints");
      Assert
        (Count_Binding
           (Editor.Ada_Language_Model.Binding_Call_Entry_Family_Candidate) >= 1,
         "ordinary call-shaped names must remain entry-family candidate hints");
   end Test_Language_Model_Call_Ambiguity_Resolver_Hints;





   procedure Test_Language_Model_Legality_Call_Positional_After_Named
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Source : constant String :=
        "procedure P is" & Character'Val (10) &
        "   procedure Run (A, B, C : Integer) is null;" & Character'Val (10) &
        "begin" & Character'Val (10) &
        "   Run (A => 1, 2, C => 3);" & Character'Val (10) &
        "   Run (1, B => 2, C => 3);" & Character'Val (10) &
        "end P;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Seen : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind =
              Editor.Ada_Language_Model.Legality_Positional_Call_Actual_After_Named
            then
               Seen := True;
            end if;
         end;
      end loop;

      Assert (Seen,
              "calls with a positional actual after a named actual should produce a bounded local diagnostic");
   end Test_Language_Model_Legality_Call_Positional_After_Named;




   procedure Test_Ada_Expression_Call_Actual_Type_Resolution
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Call_Actual_Type_Resolution_Status;
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Proc_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Good_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Unknown_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Good_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bad_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Unknown_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Proc_Node);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Call_Actual_Types is");

      Proc_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 52),
         Parent => Root, Depth => 1,
         Label => "procedure Take (X : Integer; Flag : Boolean)");

      Good_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 23),
         Parent => Root, Depth => 1, Label => "Take (42, True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 4, Start_Column => 10, End_Line => 4, End_Column => 11),
            Parent => Good_Call, Depth => 2, Label => "42");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 4, Start_Column => 14, End_Line => 4, End_Column => 17),
            Parent => Good_Call, Depth => 2, Label => "True");
      end;

      Bad_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 26),
         Parent => Root, Depth => 1, Label => "Take (""bad"", True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 5, Start_Column => 10, End_Line => 5, End_Column => 14),
            Parent => Bad_Call, Depth => 2, Label => """bad""");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 5, Start_Column => 17, End_Line => 5, End_Column => 20),
            Parent => Bad_Call, Depth => 2, Label => "True");
      end;

      Unknown_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 21),
         Parent => Root, Depth => 1, Label => "Take (Value, True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 6, Start_Column => 10, End_Line => 6, End_Column => 14),
            Parent => Unknown_Call, Depth => 2, Label => "Value");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 6, Start_Column => 17, End_Line => 6, End_Column => 20),
            Parent => Unknown_Call, Depth => 2, Label => "True");
      end;

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      Good_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Good_Call);
      Bad_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bad_Call);
      Unknown_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Unknown_Call);

      Assert
        (Good_Info.Call_Actual_Type_Status =
           Editor.Ada_Expression_Types.Call_Actual_Type_All_Compatible
         and then Good_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Call_Resolved
         and then Good_Info.Call_Actual_Type_Compatible_Count = 2,
         "call actual type resolution must accept compatible actual expression subtypes");
      Assert
        (Bad_Info.Call_Actual_Type_Status =
           Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Mismatch
         and then Bad_Info.Call_Actual_Type_Mismatch_Count = 1,
         "call actual type resolution must preserve actual/formal subtype mismatches");
      Assert
        (Unknown_Info.Call_Actual_Type_Status =
           Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Unknown
         and then Unknown_Info.Call_Actual_Type_Unknown_Count = 1,
         "call actual type resolution must preserve unknown actual expression subtypes");
      Assert
        (Editor.Ada_Expression_Types.Call_Actual_Type_Compatible_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Call_Actual_Type_Mismatch_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Call_Actual_Type_Unknown_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "call actual type resolution exposes deterministic counters and fingerprints");
   end Test_Ada_Expression_Call_Actual_Type_Resolution;




   procedure Test_Ada_Expression_Operator_Overload_Resolution
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Operator_Type_Inference_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Numeric_Library is" & ASCII.LF &
        "   type Amount is new Integer;" & ASCII.LF &
        "   function ""+"" (Left, Right : Amount) return Amount;" & ASCII.LF &
        "end Numeric_Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   use type Numeric_Library.Amount;" & ASCII.LF &
        "   A : Numeric_Library.Amount;" & ASCII.LF &
        "   B : Numeric_Library.Amount;" & ASCII.LF &
        "   C : Numeric_Library.Amount := A + B;" & ASCII.LF &
        "   D : Numeric_Library.Amount := A + True;" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Operator_Uses
          (Tree, Regions, Visibility, Types, Static, Calls, Primitive_Uses);

      function Has_Overload_Status
        (Status : Editor.Ada_Expression_Types.Operator_Type_Inference_Status)
         return Boolean
      is
      begin
         for Index in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Exprs) loop
            declare
               Info : constant Editor.Ada_Expression_Types.Expression_Type_Info :=
                 Editor.Ada_Expression_Types.Expression_Type_At (Exprs, Index);
            begin
               if Info.Operator_Status = Status then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Overload_Status;
   begin
      Assert
        (Editor.Ada_Use_Type_Operators.Primitive_Use_Count (Primitive_Uses) >= 1,
         "test setup must expose a primitive operator through use type");
      Assert
        (Has_Overload_Status (Editor.Ada_Expression_Types.Operator_Type_Overload_Resolved)
         or else Editor.Ada_Expression_Types.Operator_Overload_Resolved_Count (Exprs) >= 1,
         "operator overload inference must resolve a visible primitive operator from operand types");
      Assert
        (Has_Overload_Status (Editor.Ada_Expression_Types.Operator_Type_Overload_Mismatch)
         or else Editor.Ada_Expression_Types.Operator_Overload_Mismatch_Count (Exprs) >= 1,
         "operator overload inference must preserve primitive-operator operand mismatches");
      Assert
        (Editor.Ada_Expression_Types.Operator_Resolved_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "operator overload inference contributes deterministic counters and fingerprints");
   end Test_Ada_Expression_Operator_Overload_Resolution;





   procedure Test_Ada_Expression_Dispatching_Call_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Dispatching_Context is" & ASCII.LF &
        "   type Root is tagged record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Touch (Obj : Root'Class);" & ASCII.LF &
        "   function Clone (Obj : Root) return Root'Class;" & ASCII.LF &
        "   Obj : Root;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Touch (Obj);" & ASCII.LF &
        "   Obj.Touch;" & ASCII.LF &
        "end Dispatching_Context;";
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
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build
          (Tree, Regions, Visibility, Types, Static, Calls);
   begin
      Assert
        (Editor.Ada_Expression_Types.Dispatching_Call_Resolved_Count (Exprs) >= 1,
         "dispatching-call inference must classify primitive/static/dynamic callable targets");
      Assert
        (Editor.Ada_Expression_Types.Dispatching_Call_Dynamic_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Dispatching_Call_Static_Count (Exprs) >= 1,
         "dispatching-call inference must retain controlling operand/result binding metadata");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "dispatching-call inference contributes deterministic fingerprints");
   end Test_Ada_Expression_Dispatching_Call_Inference;




   procedure Test_Ada_Overload_Ambiguity_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Proc_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Unknown_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Model : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      First : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic;
      Per_Node : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Result_Set;
      pragma Unreferenced (Proc_Node);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Overload_Diagnostics is");

      Proc_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 52),
         Parent => Root, Depth => 1,
         Label => "procedure Take (X : Integer; Flag : Boolean)");

      Bad_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 26),
         Parent => Root, Depth => 1, Label => "Take (""bad"", True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 5, Start_Column => 10, End_Line => 5, End_Column => 14),
            Parent => Bad_Call, Depth => 2, Label => """bad""");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 5, Start_Column => 17, End_Line => 5, End_Column => 20),
            Parent => Bad_Call, Depth => 2, Label => "True");
      end;

      Unknown_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 21),
         Parent => Root, Depth => 1, Label => "Take (Value, True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 6, Start_Column => 10, End_Line => 6, End_Column => 14),
            Parent => Unknown_Call, Depth => 2, Label => "Value");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 6, Start_Column => 17, End_Line => 6, End_Column => 20),
            Parent => Unknown_Call, Depth => 2, Label => "True");
      end;

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);
      Model := Editor.Ada_Overload_Ambiguity_Diagnostics.Build (Exprs);
      First := Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostic_At (Model, 1);
      Per_Node := Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostics_For_Node (Model, First.Node);

      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostic_Count (Model) >= 2,
         "overload ambiguity diagnostics must emit deterministic call cause records");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Has_Diagnostic (First),
         "overload ambiguity diagnostics must preserve stable diagnostic identity");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Call_Cause_Count (Model) >= 2,
         "overload ambiguity diagnostics must classify call actual mismatch and unknown causes");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Count_Kind
           (Model, Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Call_Actual_Mismatch) >= 1
         and then Editor.Ada_Overload_Ambiguity_Diagnostics.Count_Kind
           (Model, Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Call_Actual_Unknown) >= 1,
         "overload ambiguity diagnostics must retain precise call rejection reason kinds");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Mismatch_Cause_Count (Model) >= 1
         and then Editor.Ada_Overload_Ambiguity_Diagnostics.Unknown_Cause_Count (Model) >= 1,
         "overload ambiguity diagnostics must preserve mismatch and unknown counters");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Result_Count (Per_Node) >= 1
         and then Editor.Ada_Overload_Ambiguity_Diagnostics.Has_Diagnostic
           (Editor.Ada_Overload_Ambiguity_Diagnostics.First_For_Node (Model, First.Node)),
         "overload ambiguity diagnostics must support node-scoped lookup");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Error_Count (Model) +
         Editor.Ada_Overload_Ambiguity_Diagnostics.Warning_Count (Model) +
         Editor.Ada_Overload_Ambiguity_Diagnostics.Info_Count (Model) =
         Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostic_Count (Model),
         "overload ambiguity diagnostics must keep deterministic severity counters");
      Assert
        (Editor.Ada_Overload_Ambiguity_Diagnostics.Fingerprint (Model) /= 0,
         "overload ambiguity diagnostics must produce a deterministic fingerprint");
   end Test_Ada_Overload_Ambiguity_Diagnostics;






   procedure Test_Ada_Expression_Diagnostics_Overload_Cause_Integration
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Model : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      First : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Info;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 5, End_Column => 1),
         Label => "package Overload_Cause_Projection is");

      declare
         Proc_Node : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (Proc_Node);
      begin
         Proc_Node := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration,
            (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 52),
            Parent => Root, Depth => 1,
            Label => "procedure Take (X : Integer; Flag : Boolean)");
      end;

      Bad_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 26),
         Parent => Root, Depth => 1, Label => "Take (""bad"", True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 4, Start_Column => 10, End_Line => 4, End_Column => 14),
            Parent => Bad_Call, Depth => 2, Label => """bad""");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 4, Start_Column => 17, End_Line => 4, End_Column => 20),
            Parent => Bad_Call, Depth => 2, Label => "True");
      end;

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);
      Causes := Editor.Ada_Overload_Ambiguity_Diagnostics.Build (Exprs);
      Model := Editor.Ada_Expression_Diagnostics.Build_With_Overload_Causes (Exprs, Causes);
      First := Editor.Ada_Expression_Diagnostics.Diagnostic_At
        (Model, Editor.Ada_Expression_Diagnostics.Diagnostic_Count (Model));

      Assert
        (Editor.Ada_Expression_Diagnostics.Overload_Cause_Diagnostic_Count (Model) =
         Editor.Ada_Overload_Ambiguity_Diagnostics.Diagnostic_Count (Causes),
         "expression diagnostics must project overload-cause diagnostics into the unified expression model");
      Assert
        (First.From_Overload_Cause
         and then First.Cause_Fingerprint /= 0
         and then Length (First.Detail) > 0,
         "expression diagnostics must preserve overload provenance detail and cause fingerprint");
      Assert
        (Editor.Ada_Expression_Diagnostics.Count_Kind
           (Model, Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Call_Actual_Mismatch) >= 1,
         "expression diagnostics must retain precise overload call mismatch kind after projection");
      Assert
        (Editor.Ada_Expression_Diagnostics.Candidate_Rejection_Count (Model) >= 1,
         "expression diagnostics must expose overload candidate rejection totals");
      Assert
        (Editor.Ada_Expression_Diagnostics.Fingerprint (Model) /= 0,
         "expression diagnostics overload-cause projection must produce a deterministic fingerprint");
   end Test_Ada_Expression_Diagnostics_Overload_Cause_Integration;






   procedure Test_Ada_Dispatching_Call_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Id;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Dispatching_Legality_Context is" & ASCII.LF &
        "   type Root is tagged record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Touch (Obj : Root'Class);" & ASCII.LF &
        "   function Clone (Obj : Root) return Root'Class;" & ASCII.LF &
        "   Obj : Root;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Touch (Obj);" & ASCII.LF &
        "   Obj.Touch;" & ASCII.LF &
        "end Dispatching_Legality_Context;";
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
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build
          (Tree, Regions, Visibility, Types, Static, Calls);
      Dispatching : constant Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model :=
        Editor.Ada_Dispatching_Call_Legality.Build (Exprs);
      First : constant Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Info :=
        Editor.Ada_Dispatching_Call_Legality.Legality_At (Dispatching, 1);
      Diagnostics : constant Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model :=
        Editor.Ada_Expression_Diagnostics.Build_With_Dispatching_Legality
          (Exprs, Dispatching);
   begin
      Assert
        (Editor.Ada_Dispatching_Call_Legality.Legality_Count (Dispatching) >= 1,
         "dispatching-call legality must classify dispatching inference records");
      Assert
        (Editor.Ada_Dispatching_Call_Legality.Resolved_Count (Dispatching) >= 1,
         "dispatching-call legality must retain resolved static/dynamic/control-result cases");
      Assert
        (First.Id /= Editor.Ada_Dispatching_Call_Legality.No_Dispatching_Legality
         and then Editor.Ada_Dispatching_Call_Legality.First_For_Node
           (Dispatching, First.Node).Id = First.Id,
         "dispatching-call legality lookup must preserve node identity");
      Assert
        (Editor.Ada_Dispatching_Call_Legality.Fingerprint (Dispatching) /= 0,
         "dispatching-call legality must contribute deterministic fingerprints");
      Assert
        (Editor.Ada_Expression_Diagnostics.Fingerprint (Diagnostics) /= 0,
         "expression diagnostics must accept dispatching legality metadata as a deterministic input");
   end Test_Ada_Dispatching_Call_Legality;




   procedure Test_Ada_Overload_Ranking
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Overload_Ranking.Overload_Ranking_Id;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Proc_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Unknown_Call : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      First : Editor.Ada_Overload_Ranking.Overload_Ranking_Info;
      Results : Editor.Ada_Overload_Ranking.Overload_Ranking_Result_Set;
      Diagnostics : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      pragma Unreferenced (Proc_Node);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Overload_Ranking is");

      Proc_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 52),
         Parent => Root, Depth => 1,
         Label => "procedure Take (X : Integer; Flag : Boolean)");

      Bad_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 26),
         Parent => Root, Depth => 1, Label => "Take (""bad"", True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 5, Start_Column => 10, End_Line => 5, End_Column => 14),
            Parent => Bad_Call, Depth => 2, Label => """bad""");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 5, Start_Column => 17, End_Line => 5, End_Column => 20),
            Parent => Bad_Call, Depth => 2, Label => "True");
      end;

      Unknown_Call := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 21),
         Parent => Root, Depth => 1, Label => "Take (Value, True)");
      declare
         A : Editor.Ada_Syntax_Tree.Node_Id;
         B : Editor.Ada_Syntax_Tree.Node_Id;
         pragma Unreferenced (A, B);
      begin
         A := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 6, Start_Column => 10, End_Line => 6, End_Column => 14),
            Parent => Unknown_Call, Depth => 2, Label => "Value");
         B := Editor.Ada_Syntax_Tree.Add_Node
           (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
            (Start_Line => 6, Start_Column => 17, End_Line => 6, End_Column => 20),
            Parent => Unknown_Call, Depth => 2, Label => "True");
      end;

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);
      Causes := Editor.Ada_Overload_Ambiguity_Diagnostics.Build (Exprs);
      Ranking := Editor.Ada_Overload_Ranking.Build (Exprs, Causes);
      First := Editor.Ada_Overload_Ranking.Ranking_At (Ranking, 1);
      Results := Editor.Ada_Overload_Ranking.Rankings_For_Node (Ranking, First.Node);
      Diagnostics := Editor.Ada_Expression_Diagnostics.Build_With_Overload_Ranking
        (Exprs, Ranking);

      Assert
        (Editor.Ada_Overload_Ranking.Ranking_Count (Ranking) >= 2,
         "overload ranking must classify call/operator/universal numeric overload evidence");
      Assert
        (First.Id /= Editor.Ada_Overload_Ranking.No_Overload_Ranking
         and then Editor.Ada_Overload_Ranking.Has_Ranking (First),
         "overload ranking must preserve stable ranking identity");
      Assert
        (Editor.Ada_Overload_Ranking.No_Ranked_Candidate_Count (Ranking) >= 1
         and then Editor.Ada_Overload_Ranking.Unknown_Ranking_Count (Ranking) >= 1,
         "overload ranking must distinguish rejected and unknown candidate states");
      Assert
        (Editor.Ada_Overload_Ranking.Result_Count (Results) >= 1
         and then Editor.Ada_Overload_Ranking.First_For_Node (Ranking, First.Node).Id = First.Id,
         "overload ranking must support deterministic node-scoped lookup");
      Assert
        (Editor.Ada_Overload_Ranking.Candidate_Rejection_Count (Ranking) >= 1
         and then Editor.Ada_Overload_Ranking.Fingerprint (Ranking) /= 0,
         "overload ranking must preserve rejection totals and deterministic fingerprints");
      Assert
        (Editor.Ada_Expression_Diagnostics.Overload_Ranking_Diagnostic_Count (Diagnostics) >= 1
         and then Editor.Ada_Expression_Diagnostics.Overload_Ranking_Rejection_Diagnostic_Count (Diagnostics) >= 1,
         "expression diagnostics must project unresolved or rejected overload-ranking causes");
   end Test_Ada_Overload_Ranking;


   overriding function Name (T : Expression_Call_Overload_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Expression.Call_Overload");
   end Name;

   overriding procedure Register_Tests (T : in out Expression_Call_Overload_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Resolver_Use_Type_Clause_Exposes_Primitive_Operators_Only'Access, Name => "resolver use type exposes primitive operators only");
      Add_Test (Routine => Test_Resolver_Call_Overload_Resolution_Uses_Profile_Actuals'Access, Name => "resolver call overload resolution uses actual profiles and expected result types");
      Add_Test (Routine => Test_Resolver_Call_Overload_Resolution_Uses_Defaulted_Formals'Access, Name => "resolver call overload resolution honors defaulted formals");
      Add_Test (Routine => Test_Resolver_Expression_Aware_Overload_Resolution'Access, Name => "resolver call overload resolution infers simple expression types");
      Add_Test (Routine => Test_Language_Model_Split_Function_Return_Body_Opens_Callable_Scope'Access, Name => "language model parser opens callable scope after split function return line");
      Add_Test (Routine => Test_Language_Model_Exposes_Scoped_Overload_Sets'Access, Name => "language model exposes deterministic same-scope overload sets");
      Add_Test (Routine => Test_Language_Model_Invalid_Scope_Overload_Lookup_Degrades'Access, Name => "language model overload lookup rejects invalid scope ids");
      Add_Test (Routine => Test_Language_Model_Non_Owner_Scope_Overload_Lookup_Degrades'Access, Name => "language model overload lookup rejects non-owner scope ids");
      Add_Test (Routine => Test_Language_Model_Overload_Lookup_Requires_Matching_Parent'Access, Name => "language model overload lookup requires matching parent and scope stamps");
      Add_Test (Routine => Test_Ada_Use_Type_Operator_Visibility_Foundation'Access, Name => "Ada use-type operator visibility exposes primitive operator candidates");
      Add_Test (Routine => Test_Ada_Call_Profile_Shape_Foundation'Access, Name => "Ada call-profile shape model extracts callable and actual arity metadata");
      Add_Test (Routine => Test_Ada_Call_Profile_Filter_Foundation'Access, Name => "Ada call-profile filter applies arity and named-actual shape checks");
      Add_Test (Routine => Test_Ada_Call_Profile_Formal_Name_Filter'Access, Name => "Ada call-profile filter matches formal names and defaults");
      Add_Test (Routine => Test_Ada_Expected_Call_Filter_Foundation'Access, Name => "Ada expected-call filter applies expected subtype contexts to call results");
      Add_Test (Routine => Test_Ada_Expected_Call_Filter_Resolves_Result_Overloads'Access, Name => "Ada expected-call filter resolves result overloads by expected subtype");
      Add_Test (Routine => Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility'Access, Name => "Ada expected-call filters apply declaration-derived type graph compatibility");
      Add_Test (Routine => Test_Ada_Call_Resolution_Profile_Result'Access, Name => "Ada call-resolution model classifies profile-filter result sets");
      Add_Test (Routine => Test_Ada_Call_Candidate_Foundation'Access, Name => "Ada call-candidate model collects callable candidates before overload filtering");
      Add_Test (Routine => Test_Language_Model_Executable_Expression_Call_Bindings'Access, Name => "language model retains executable expression call bindings");
      Add_Test (Routine => Test_Language_Model_Legality_Call_Named_Actual_Pass'Access, Name => "language model checks duplicate call named actual legality");
      Add_Test (Routine => Test_Language_Model_Call_Ambiguity_Resolver_Hints'Access, Name => "language model projects call ambiguity resolver hints");
      Add_Test (Routine => Test_Language_Model_Legality_Call_Positional_After_Named'Access, Name => "language model checks positional call actuals after named associations");
      Add_Test (Routine => Test_Ada_Expression_Call_Actual_Type_Resolution'Access, Name => "Ada expression type model resolves calls with actual expression types");
      Add_Test (Routine => Test_Ada_Expression_Operator_Overload_Resolution'Access, Name => "Ada expression type model resolves overloaded operators with operand types");
      Add_Test (Routine => Test_Ada_Expression_Dispatching_Call_Inference'Access, Name => "Ada expression type model infers dispatching call metadata");
      Add_Test (Routine => Test_Ada_Overload_Ambiguity_Diagnostics'Access, Name => "Ada overload ambiguity diagnostics explain candidate rejection causes");
      Add_Test (Routine => Test_Ada_Expression_Diagnostics_Overload_Cause_Integration'Access, Name => "Ada expression diagnostics integrates overload ambiguity cause records");
      Add_Test (Routine => Test_Ada_Dispatching_Call_Legality'Access, Name => "Ada dispatching call legality classifies controlling operands and diagnostics");
      Add_Test (Routine => Test_Ada_Overload_Ranking'Access, Name => "Ada overload ranking classifies implicit conversion and universal numeric tie-breaks");
   end Register_Tests;

end Editor.Syntax_Semantics.Expression_Call_Overload_Tests;
