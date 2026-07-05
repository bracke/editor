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

package body Editor.Syntax_Semantics.Expression_Inference_Tests is





   procedure Test_Resolver_Expression_Aware_Operator_Expressions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Pkg_Id : Editor.Ada_Language_Model.Symbol_Id;
      Integer_Type_Id : Editor.Ada_Language_Model.Symbol_Id;
      Boolean_Type_Id : Editor.Ada_Language_Model.Symbol_Id;
      I_Id : Editor.Ada_Language_Model.Symbol_Id;
      Use_Integer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Use_Boolean_Id : Editor.Ada_Language_Model.Symbol_Id;
      Plus_Id : Editor.Ada_Language_Model.Symbol_Id;
      From_Parenthesized_Signed : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Comparison : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Unknown_Operator : Editor.Ada_Symbol_Resolver.Resolution_Result;
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
      Use_Integer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Use_Value",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Value : Integer)");
      Use_Boolean_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Use_Value",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Value : Boolean)");
      Plus_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         """" & "+" & """",
         Editor.Ada_Language_Model.Symbol_Operator_Function,
         (Start_Line => 7, Start_Column => 4, End_Line => 7, End_Column => 7),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id,
         Profile_Summary => "(Left, Right : Integer) return Integer");

      Assert (Integer_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Boolean_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then I_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Plus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain operator-expression overload symbols");

      From_Parenthesized_Signed :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Use_Value", Pkg_Id, "(I + -1)");
      Assert (Natural (From_Parenthesized_Signed.Matches.Length) = 1
              and then From_Parenthesized_Signed.Matches.First_Element = Use_Integer_Id,
              "expression-aware overload resolution should infer parenthesized signed operator expressions");

      From_Comparison := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "(I + 1) = I");
      Assert (Natural (From_Comparison.Matches.Length) = 1
              and then From_Comparison.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should infer top-level comparison expressions as Boolean");

      From_Unknown_Operator := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "Missing + 1");
      Assert (Natural (From_Unknown_Operator.Matches.Length) = 0,
              "unknown operator operands must not become wildcard overload actuals");
   end Test_Resolver_Expression_Aware_Operator_Expressions;



   procedure Test_Resolver_Expression_Aware_Unary_And_Membership
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
      From_Not : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Abs : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_In : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Not_In : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Power : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Unknown_Not : Editor.Ada_Symbol_Resolver.Resolution_Result;
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

      Assert (Integer_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Boolean_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then I_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain unary and membership overload symbols");

      From_Not := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "not B");
      Assert (Natural (From_Not.Matches.Length) = 1
              and then From_Not.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should infer unary not as Boolean");

      From_Abs := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "abs I");
      Assert (Natural (From_Abs.Matches.Length) = 1
              and then From_Abs.Matches.First_Element = Use_Integer_Id,
              "expression-aware overload resolution should infer unary abs as the operand type");

      From_In := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "I in Integer");
      Assert (Natural (From_In.Matches.Length) = 1
              and then From_In.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should infer membership tests as Boolean");

      From_Not_In := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "I not in Integer");
      Assert (Natural (From_Not_In.Matches.Length) = 1
              and then From_Not_In.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should infer negative membership tests as Boolean");

      From_Power := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "2 ** 3");
      Assert (Natural (From_Power.Matches.Length) = 1
              and then From_Power.Matches.First_Element = Use_Integer_Id,
              "expression-aware overload resolution should infer exponentiation of integer literals");

      From_Unknown_Not := Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
        (Analysis, "Use_Value", Pkg_Id, "not Missing");
      Assert (Natural (From_Unknown_Not.Matches.Length) = 0,
              "unknown unary operands must not become wildcard overload actuals");
   end Test_Resolver_Expression_Aware_Unary_And_Membership;



   procedure Test_Resolver_Expression_Aware_Conditional_Expressions
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
      From_Integer_Conditional : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Boolean_Conditional : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Unknown_Condition : Editor.Ada_Symbol_Resolver.Resolution_Result;
      From_Mismatched_Branches : Editor.Ada_Symbol_Resolver.Resolution_Result;
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

      Assert (Integer_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Boolean_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then I_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Integer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Use_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain conditional-expression overload symbols");

      From_Integer_Conditional :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Use_Value", Pkg_Id, "if B then I else 1");
      Assert (Natural (From_Integer_Conditional.Matches.Length) = 1
              and then From_Integer_Conditional.Matches.First_Element = Use_Integer_Id,
              "expression-aware overload resolution should infer compatible conditional branches");

      From_Boolean_Conditional :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Use_Value", Pkg_Id, "if B then True else False");
      Assert (Natural (From_Boolean_Conditional.Matches.Length) = 1
              and then From_Boolean_Conditional.Matches.First_Element = Use_Boolean_Id,
              "expression-aware overload resolution should infer Boolean conditional expressions");

      From_Unknown_Condition :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Use_Value", Pkg_Id, "if Missing then I else 1");
      Assert (Natural (From_Unknown_Condition.Matches.Length) = 0,
              "unknown conditional-expression conditions must not become wildcard overload actuals");

      From_Mismatched_Branches :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Use_Value", Pkg_Id, "if B then I else B");
      Assert (Natural (From_Mismatched_Branches.Matches.Length) = 0,
              "incompatible conditional-expression branches must not select an overload");
   end Test_Resolver_Expression_Aware_Conditional_Expressions;




   procedure Test_Language_Model_Executable_Deep_Expression_Name_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Int_Array is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Values : Int_Array (1 .. 10);" & ASCII.LF &
        "   Ptr : access Integer;" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   R : Rec;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   X := Values (1);" & ASCII.LF &
        "   X := Values (1 .. 3) (1);" & ASCII.LF &
        "   X := Ptr.all;" & ASCII.LF &
        "   R := Rec'(A => Values (1), B => Integer'(2));" & ASCII.LF &
        "   Ptr := new Integer'(4);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_deep_expression_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Array_Index) >= 2,
         "array indexing expressions should be retained as executable name bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Array_Slice) >= 1,
         "array slice expressions should be retained separately from indexing");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Dereference) = 1,
         "explicit dereferences should be retained as executable name bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Allocator) = 1,
         "allocator target names should be retained as executable name bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Aggregate_Component) >= 2,
         "named aggregate associations should be retained as component bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Qualified_Expression_Target) >= 2,
         "qualified expression target names should be retained for semantic binding");
   end Test_Language_Model_Executable_Deep_Expression_Name_Bindings;





   procedure Test_Language_Model_Executable_Type_Conversion_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Count_Type is new Integer;" & ASCII.LF &
        "   subtype Small_Count is Count_Type range 0 .. 10;" & ASCII.LF &
        "   Raw : Integer := 1;" & ASCII.LF &
        "   Count : Count_Type := 0;" & ASCII.LF &
        "   Small : Small_Count := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Count := Count_Type (Raw);" & ASCII.LF &
        "   Small := Small_Count (Count);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_type_conversion_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Type_Conversion_Target) = 2,
         "type conversion targets should be retained separately from calls and indexing");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Array_Index) = 0,
         "type conversions should not be misclassified as array indexing");
   end Test_Language_Model_Executable_Type_Conversion_Bindings;





   procedure Test_Language_Model_Executable_Case_Expression_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type State_Kind is (Ready, Done, Other);" & ASCII.LF &
        "   State : State_Kind := Ready;" & ASCII.LF &
        "   Count : Integer := 1;" & ASCII.LF &
        "   Last : Integer := 2;" & ASCII.LF &
        "   X : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   X := (case State is when Ready => Count, when Done => Last, when others => 0);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_case_expression_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Case_Expression_Selector) = 1,
         "case-expression selectors should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Case_Expression_Choice) = 2,
         "case-expression choices should be retained separately from statement case choices");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Case_Choice) = 0,
         "case-expression choices should not be misclassified as statement case alternatives");
   end Test_Language_Model_Executable_Case_Expression_Bindings;




   procedure Test_Language_Model_Executable_Conditional_Expression_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   Count : Integer := 1;" & ASCII.LF &
        "   Last : Integer := 2;" & ASCII.LF &
        "   X : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   X := (if Ready then Count else Last);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_conditional_expression_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Conditional_Expression_Condition) = 1,
         "conditional-expression conditions should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Conditional_Expression_Branch) = 2,
         "conditional-expression branches should be retained separately from statement conditions");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Condition_Target) = 0,
         "conditional-expression conditions should not be misclassified as statement conditions");
   end Test_Language_Model_Executable_Conditional_Expression_Bindings;




   procedure Test_Language_Model_Executable_Raise_Expression_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "   Ready : Boolean := False;" & ASCII.LF &
        "   Count : Integer := 1;" & ASCII.LF &
        "   X : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   X := (if Ready then Count else raise E);" & ASCII.LF &
        "   Ready := Check (raise E);" & ASCII.LF &
        "   raise E;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_raise_expression_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Raise_Expression_Target) = 2,
         "raise-expression targets should be retained separately from statement raises");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Raise_Target) = 1,
         "statement-level raise targets should remain distinct from raise expressions");
   end Test_Language_Model_Executable_Raise_Expression_Bindings;





   procedure Test_Language_Model_Executable_Quantified_Expression_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Int_Array is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Items : Int_Array (1 .. 10);" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean is (Value > 0);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Ready := (for all I in Items'Range => Check (Items (I)));" & ASCII.LF &
        "   pragma Assert (for some Item of Items => Item > 0);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_quantified_expression_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Quantified_Parameter) = 2,
         "quantified expression parameters should be retained as executable local bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Quantified_Source) = 2,
         "quantified expression domains should be retained as executable source bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Call_Target) >= 1,
         "nested calls inside quantified expressions should remain visible to call binding extraction");
   end Test_Language_Model_Executable_Quantified_Expression_Bindings;



   procedure Test_Language_Model_Executable_Transfer_And_Tasking_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      entry Start (Value : in Integer; Flag, Other : Boolean);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Start (Value : in Integer; Flag, Other : Boolean) do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Start;" & ASCII.LF &
        "      requeue Start;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise E;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_transfer_tasking_targets.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Raise_Target) = 1,
         "raise exception targets should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Requeue_Target) = 1,
         "requeue entry targets should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Accept_Entry) = 1,
         "accept entry targets should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Accept_Parameter) = 3,
         "accept statement parameters should be retained as executable local bindings");
   end Test_Language_Model_Executable_Transfer_And_Tasking_Targets;



   procedure Test_Language_Model_Executable_Return_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Saved : Rec;" & ASCII.LF &
        "   function Make return Rec is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Saved;" & ASCII.LF &
        "   end Make;" & ASCII.LF &
        "   function Build return Rec is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Result : Rec := Saved do" & ASCII.LF &
        "         Result.Value := 1;" & ASCII.LF &
        "      end return;" & ASCII.LF &
        "   end Build;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_return_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Return_Target) = 1,
         "ordinary return expression targets should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Return_Object) = 1,
         "extended return objects should be retained as executable bindings");
   end Test_Language_Model_Executable_Return_Bindings;





   procedure Test_Ada_Expression_Expected_Type_Propagation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Obj  : Editor.Ada_Syntax_Tree.Node_Id;
      Def  : Editor.Ada_Syntax_Tree.Node_Id;
      Lit  : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Info : Editor.Ada_Expression_Types.Expression_Type_Info;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 3, End_Column => 1),
         Label => "package Expected_Expression is");
      Obj := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 25),
         Parent => Root, Depth => 1, Label => "Count : Integer := 1");
      Def := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Default,
         (Start_Line => 2, Start_Column => 22, End_Line => 2, End_Column => 22),
         Parent => Obj, Depth => 2, Label => "1");
      Lit := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 2, Start_Column => 22, End_Line => 2, End_Column => 22),
         Parent => Def, Depth => 3, Label => "1");

      Exprs := Editor.Ada_Expression_Types.Build_With_Expected_Contexts
        (Tree, Regions, Visibility, Types, Static, Calls, Expected);
      Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Lit);

      Assert
        (Info.Status = Editor.Ada_Expression_Types.Expression_Type_Static_Integer,
         "literal remains classified as a static integer expression");
      Assert
        (Info.Expected_Status = Editor.Ada_Expression_Types.Expected_Type_Compatible or else
         Info.Expected_Status = Editor.Ada_Expression_Types.Expected_Type_Propagated,
         "object default literal receives the expected Integer subtype context");
      Assert
        (To_String (Info.Normalized_Expected_Subtype) = "integer",
         "expected subtype propagation records a normalized declaration-default subtype");
      Assert
        (Editor.Ada_Expression_Types.Expected_Propagated_Count (Exprs) >= 1,
         "expression-type model exposes deterministic expected-type propagation counters");
   end Test_Ada_Expression_Expected_Type_Propagation;




   procedure Test_Ada_Expression_Operator_Operand_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Operator_Type_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Good : Editor.Ada_Syntax_Tree.Node_Id;
      Good_Left : Editor.Ada_Syntax_Tree.Node_Id;
      Good_Right : Editor.Ada_Syntax_Tree.Node_Id;
      Bad : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Left : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Right : Editor.Ada_Syntax_Tree.Node_Id;
      Bool_Op : Editor.Ada_Syntax_Tree.Node_Id;
      Bool_Left : Editor.Ada_Syntax_Tree.Node_Id;
      Bool_Right : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
            Good_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bad_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bool_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 5, End_Column => 1),
         Label => "package Operator_Expressions is");
      Good := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Operator_Expression,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 8),
         Parent => Root, Depth => 1, Label => "1 + 2");
      Good_Left := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 4),
         Parent => Good, Depth => 2, Label => "1");
      Good_Right := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 2, Start_Column => 8, End_Line => 2, End_Column => 8),
         Parent => Good, Depth => 2, Label => "2");
      Bad := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Operator_Expression,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 14),
         Parent => Root, Depth => 1, Label => "1 + True");
      Bad_Left := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 4),
         Parent => Bad, Depth => 2, Label => "1");
      Bad_Right := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 3, Start_Column => 8, End_Line => 3, End_Column => 11),
         Parent => Bad, Depth => 2, Label => "True");
      Bool_Op := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 24),
         Parent => Root, Depth => 1, Label => "True and then False");
      Bool_Left := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 7),
         Parent => Bool_Op, Depth => 2, Label => "True");
      Bool_Right := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 4, Start_Column => 18, End_Line => 4, End_Column => 22),
         Parent => Bool_Op, Depth => 2, Label => "False");
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);
      Good_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Good);
      Bad_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bad);
      Bool_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bool_Op);

      Assert
        (Good_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Operator_Numeric
         and then Good_Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Resolved_Predefined
         and then To_String (Good_Info.Normalized_Operator_Result_Subtype) = "universal_integer",
         "numeric operator inference must resolve compatible predefined integer operands");
      Assert
        (Bad_Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Operand_Mismatch
         and then Bad_Info.Operator_Mismatched_Operand_Count = 1,
         "operator inference must preserve incompatible operand metadata instead of broad numeric acceptance");
      Assert
        (Bool_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Operator_Boolean
         and then Bool_Info.Operator_Status = Editor.Ada_Expression_Types.Operator_Type_Resolved_Predefined
         and then To_String (Bool_Info.Normalized_Operator_Result_Subtype) = "boolean",
         "short-circuit Boolean operators must infer Boolean result shape");
      Assert
        (Editor.Ada_Expression_Types.Operator_Resolved_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Operator_Operand_Mismatch_Count (Exprs) >= 1,
         "operator inference exposes deterministic resolved and mismatch counters");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "operator operand/result inference contributes to expression-type fingerprints");
   end Test_Ada_Expression_Operator_Operand_Inference;




   procedure Test_Ada_Expression_Aggregate_Context_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Aggregate_Type_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Array_Obj : Editor.Ada_Syntax_Tree.Node_Id;
      Array_Def : Editor.Ada_Syntax_Tree.Node_Id;
      Array_Agg : Editor.Ada_Syntax_Tree.Node_Id;
      Array_Left : Editor.Ada_Syntax_Tree.Node_Id;
      Array_Right : Editor.Ada_Syntax_Tree.Node_Id;
      Record_Obj : Editor.Ada_Syntax_Tree.Node_Id;
      Record_Def : Editor.Ada_Syntax_Tree.Node_Id;
      Record_Agg : Editor.Ada_Syntax_Tree.Node_Id;
      Record_Assoc : Editor.Ada_Syntax_Tree.Node_Id;
      Container_Obj : Editor.Ada_Syntax_Tree.Node_Id;
      Container_Def : Editor.Ada_Syntax_Tree.Node_Id;
      Container_Agg : Editor.Ada_Syntax_Tree.Node_Id;
      Bare_Agg : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Array_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Record_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Container_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bare_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 8, End_Column => 1),
         Label => "package Aggregate_Expressions is");

      Array_Obj := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 41),
         Parent => Root, Depth => 1, Label => "Values : Integer_Array := (1, 2)");
      Array_Def := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Default,
         (Start_Line => 2, Start_Column => 29, End_Line => 2, End_Column => 34),
         Parent => Array_Obj, Depth => 2, Label => "(1, 2)");
      Array_Agg := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Aggregate,
         (Start_Line => 2, Start_Column => 29, End_Line => 2, End_Column => 34),
         Parent => Array_Def, Depth => 3, Label => "(1, 2)");
      Array_Left := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
         (Start_Line => 2, Start_Column => 30, End_Line => 2, End_Column => 30),
         Parent => Array_Agg, Depth => 4, Label => "1");
      Array_Right := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
         (Start_Line => 2, Start_Column => 33, End_Line => 2, End_Column => 33),
         Parent => Array_Agg, Depth => 4, Label => "2");

      Record_Obj := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 41),
         Parent => Root, Depth => 1, Label => "Origin : Point := (X => 0)");
      Record_Def := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Default,
         (Start_Line => 3, Start_Column => 22, End_Line => 3, End_Column => 29),
         Parent => Record_Obj, Depth => 2, Label => "(X => 0)");
      Record_Agg := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Aggregate,
         (Start_Line => 3, Start_Column => 22, End_Line => 3, End_Column => 29),
         Parent => Record_Def, Depth => 3, Label => "(X => 0)");
      Record_Assoc := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Named_Association,
         (Start_Line => 3, Start_Column => 23, End_Line => 3, End_Column => 28),
         Parent => Record_Agg, Depth => 4, Label => "X => 0");

      Container_Obj := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 60),
         Parent => Root, Depth => 1, Label => "Bag : Integer_Vector := [for Item of Source => Item]");
      Container_Def := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Default,
         (Start_Line => 4, Start_Column => 28, End_Line => 4, End_Column => 58),
         Parent => Container_Obj, Depth => 2, Label => "[for Item of Source => Item]");
      Container_Agg := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Container_Aggregate,
         (Start_Line => 4, Start_Column => 28, End_Line => 4, End_Column => 58),
         Parent => Container_Def, Depth => 3, Label => "[for Item of Source => Item]");

      Bare_Agg := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Aggregate,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 9),
         Parent => Root, Depth => 1, Label => "(1, 2)");

      Exprs := Editor.Ada_Expression_Types.Build_With_Expected_Contexts
        (Tree, Regions, Visibility, Types, Static, Calls, Expected);
      Array_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Array_Agg);
      Record_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Record_Agg);
      Container_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Container_Agg);
      Bare_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bare_Agg);

      Assert
        (Array_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Aggregate
         and then Array_Info.Aggregate_Status = Editor.Ada_Expression_Types.Aggregate_Type_Compatible
         and then To_String (Array_Info.Normalized_Subtype) = "integer_array"
         and then Array_Info.Aggregate_Positional_Association_Count = 2,
         "array aggregate inference must propagate expected array subtype and retain positional component shape");
      Assert
        (Record_Info.Aggregate_Status = Editor.Ada_Expression_Types.Aggregate_Type_Compatible
         and then To_String (Record_Info.Normalized_Subtype) = "point"
         and then Record_Info.Aggregate_Named_Association_Count = 1,
         "record aggregate inference must retain named association shape under an expected record subtype");
      Assert
        (Container_Info.Aggregate_Status = Editor.Ada_Expression_Types.Aggregate_Type_Compatible
         and then To_String (Container_Info.Normalized_Subtype) = "integer_vector",
         "container aggregate inference must consume expected container subtype context");
      Assert
        (Bare_Info.Aggregate_Status = Editor.Ada_Expression_Types.Aggregate_Type_Context_Required
         and then Bare_Info.Aggregate_Unknown_Count = 1,
         "aggregate expressions without an expected subtype remain explicitly context-required");
      Assert
        (Editor.Ada_Expression_Types.Aggregate_Context_Resolved_Count (Exprs) >= 3
         and then Editor.Ada_Expression_Types.Aggregate_Context_Required_Count (Exprs) >= 1,
         "aggregate inference exposes deterministic resolved and context-required counters");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "aggregate context inference contributes to deterministic expression-type fingerprints");
   end Test_Ada_Expression_Aggregate_Context_Inference;




   procedure Test_Ada_Expression_Conversion_Qualified_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Conversion_Type_Inference_Status;
      use type Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Small_Type : Editor.Ada_Syntax_Tree.Node_Id;
      Float_Type : Editor.Ada_Syntax_Tree.Node_Id;
      Conv_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Explicit_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Mismatch_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Qualified_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
            Conv_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Explicit_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Mismatch_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Qualified_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Conversion_Contexts : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Context_Model;
      Conversion_Legality : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 8, End_Column => 1),
         Label => "package Conversion_Expressions is");

      Small_Type := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Type_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 34),
         Parent => Root, Depth => 1, Label => "type Small is range 0 .. 10");
      Float_Type := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Type_Declaration,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 26),
         Parent => Root, Depth => 1, Label => "type Floaty is digits 6");

      Conv_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Function_Call,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 12),
         Parent => Root, Depth => 1, Label => "Small (1)");
      Explicit_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Function_Call,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 16),
         Parent => Root, Depth => 1, Label => "Floaty (1)");
      Mismatch_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Function_Call,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 17),
         Parent => Root, Depth => 1, Label => "Small (True)");
      Qualified_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Qualified_Expression,
         (Start_Line => 7, Start_Column => 4, End_Line => 7, End_Column => 13),
         Parent => Root, Depth => 1, Label => "Small'(1)");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      Conv_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Conv_Node);
      Explicit_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Explicit_Node);
      Mismatch_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Mismatch_Node);
      Qualified_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Qualified_Node);

      Assert
        (Conv_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Conversion
         and then Conv_Info.Conversion_Status = Editor.Ada_Expression_Types.Conversion_Type_Operand_Compatible
         and then To_String (Conv_Info.Normalized_Conversion_Target_Subtype) = "small"
         and then To_String (Conv_Info.Normalized_Conversion_Operand_Subtype) = "universal_integer",
         "type conversion inference must resolve target subtype and compatible operand subtype");
      Assert
        (Explicit_Info.Conversion_Status = Editor.Ada_Expression_Types.Conversion_Type_Operand_Compatible
         or else Explicit_Info.Conversion_Status = Editor.Ada_Expression_Types.Conversion_Type_Operand_Requires_Explicit_Conversion,
         "numeric conversion inference must retain explicit-conversion metadata for cross-family operands");
      Assert
        (Mismatch_Info.Conversion_Status = Editor.Ada_Expression_Types.Conversion_Type_Operand_Mismatch
         and then Mismatch_Info.Conversion_Mismatched_Operand_Count = 1,
         "conversion inference must classify incompatible nonnumeric operand types separately");
      Assert
        (Qualified_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Qualified
         and then Qualified_Info.Conversion_Status = Editor.Ada_Expression_Types.Conversion_Type_Operand_Compatible,
         "qualified expression inference must reuse target-subtype and operand compatibility metadata");
      Assert
        (Editor.Ada_Expression_Types.Conversion_Target_Resolved_Count (Exprs) >= 4
         and then Editor.Ada_Expression_Types.Conversion_Compatible_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Conversion_Mismatch_Count (Exprs) >= 1,
         "conversion inference exposes deterministic resolved/compatible/mismatch counters");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "conversion and qualified-expression inference contributes to deterministic expression-type fingerprints");
      Conversion_Contexts :=
        Editor.Ada_Conversion_Access_Aggregate_Legality
          .Build_Contexts_From_Expression_Types (Exprs);
      Conversion_Legality :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Build
          (Conversion_Contexts);
      Assert
        (Editor.Ada_Conversion_Access_Aggregate_Legality.Context_Count
           (Conversion_Contexts) >= 4,
         "conversion legality adapter must retain conversion and qualified-expression contexts");
      Assert
        (Editor.Ada_Conversion_Access_Aggregate_Legality.Conversion_Count
           (Conversion_Legality) >= 4,
         "conversion legality adapter must produce conversion-family legality rows");
      Assert
        (Editor.Ada_Conversion_Access_Aggregate_Legality.Count_Status
           (Conversion_Legality,
            Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Incompatible_Type) >= 1,
         "conversion legality adapter must preserve incompatible conversion rows");
      Assert
        (Editor.Ada_Conversion_Access_Aggregate_Legality.Fingerprint
           (Conversion_Legality) /= 0,
         "conversion legality adapter must feed deterministic legality fingerprints");
   end Test_Ada_Expression_Conversion_Qualified_Inference;




   procedure Test_Ada_Expression_Attribute_Reference_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Attribute_Type_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Small_Type : Editor.Ada_Syntax_Tree.Node_Id;
      First_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Image_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Size_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Unknown_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      pragma Unreferenced (Small_Type);
      First_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Image_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Size_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Unknown_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Attribute_Expressions is");

      Small_Type := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Type_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 34),
         Parent => Root, Depth => 1, Label => "type Small is range 0 .. 10");

      First_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Attribute_Reference,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 15),
         Parent => Root, Depth => 1, Label => "Small'First");
      Image_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Attribute_Reference,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 17),
         Parent => Root, Depth => 1, Label => "Small'Image (1)");
      Size_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Attribute_Reference,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 13),
         Parent => Root, Depth => 1, Label => "Small'Size");
      Unknown_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Attribute_Reference,
         (Start_Line => 6, Start_Column => 4, End_Line => 6, End_Column => 22),
         Parent => Root, Depth => 1, Label => "Missing'First");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      First_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, First_Node);
      Image_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Image_Node);
      Size_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Size_Node);
      Unknown_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Unknown_Node);

      Assert
        (First_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Attribute
         and then First_Info.Attribute_Status = Editor.Ada_Expression_Types.Attribute_Type_Scalar_Bound
         and then To_String (First_Info.Normalized_Attribute_Result_Subtype) = "small",
         "attribute inference must preserve scalar bound result subtype metadata");
      Assert
        (Image_Info.Attribute_Status = Editor.Ada_Expression_Types.Attribute_Type_String_Result
         and then To_String (Image_Info.Normalized_Subtype) = "string",
         "attribute inference must classify image attributes as string-valued");
      Assert
        (Size_Info.Attribute_Status = Editor.Ada_Expression_Types.Attribute_Type_Size_Result
         and then To_String (Size_Info.Normalized_Subtype) = "universal_integer",
         "attribute inference must classify size/alignment-style attributes as integer-valued");
      Assert
        (Unknown_Info.Attribute_Status = Editor.Ada_Expression_Types.Attribute_Type_Prefix_Unresolved
         and then Unknown_Info.Attribute_Unknown_Count = 1,
         "attribute inference must preserve unresolved prefix metadata explicitly");
      Assert
        (Editor.Ada_Expression_Types.Attribute_Resolved_Count (Exprs) >= 3
         and then Editor.Ada_Expression_Types.Attribute_Static_Result_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Attribute_String_Result_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Attribute_Prefix_Unresolved_Count (Exprs) >= 1,
         "attribute inference exposes deterministic resolved/static/string/unresolved counters");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "attribute-reference inference contributes to deterministic expression-type fingerprints");
   end Test_Ada_Expression_Attribute_Reference_Inference;




   procedure Test_Ada_Expression_Conditional_Declare_Reduction_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Conditional_Type_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      If_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Quant_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Declare_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Reduction_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Dummy : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      If_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Quant_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Declare_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Reduction_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Dummy);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Conditional_Expressions is");

      If_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Conditional_Expression,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 35),
         Parent => Root, Depth => 1, Label => "if Flag then 1 else 2");
      Dummy := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 2, Start_Column => 17, End_Line => 2, End_Column => 17),
         Parent => If_Node, Depth => 2, Label => "1");
      Dummy := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 2, Start_Column => 24, End_Line => 2, End_Column => 24),
         Parent => If_Node, Depth => 2, Label => "2");

      Quant_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Quantified_Expression,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 45),
         Parent => Root, Depth => 1, Label => "for all I in 1 .. 10 => I > 0");
      Declare_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declare_Expression,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 51),
         Parent => Root, Depth => 1, Label => "declare X : constant Integer := 1; begin X end");
      Reduction_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Reduction_Expression,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 41),
         Parent => Root, Depth => 1, Label => "Items'Reduce (""+"", 0)");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      If_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, If_Node);
      Quant_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Quant_Node);
      Declare_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Declare_Node);
      Reduction_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Reduction_Node);

      Assert
        (If_Info.Conditional_Status = Editor.Ada_Expression_Types.Conditional_Type_Branches_Compatible
         and then To_String (If_Info.Normalized_Conditional_Result_Subtype) = "universal_integer"
         and then If_Info.Conditional_Compatible_Branch_Count = 2,
         "conditional expression inference must merge compatible branch subtype metadata");
      Assert
        (Quant_Info.Conditional_Status = Editor.Ada_Expression_Types.Conditional_Type_Boolean_Result
         and then To_String (Quant_Info.Normalized_Subtype) = "boolean",
         "quantified expression inference must classify Boolean result expressions explicitly");
      Assert
        (Declare_Info.Conditional_Status = Editor.Ada_Expression_Types.Conditional_Type_Declare_Result
         and then Declare_Info.Conditional_Unknown_Branch_Count = 1,
         "declare expression inference must preserve result-unknown metadata when no expected context exists");
      Assert
        (Reduction_Info.Conditional_Status = Editor.Ada_Expression_Types.Conditional_Type_Reduction_Result
         and then Reduction_Info.Conditional_Unknown_Branch_Count = 1,
         "reduction expression inference must stage reduction-result metadata separately");
      Assert
        (Editor.Ada_Expression_Types.Conditional_Resolved_Count (Exprs) >= 3
         and then Editor.Ada_Expression_Types.Conditional_Reduction_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Conditional_Declare_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Conditional_Branch_Unknown_Count (Exprs) >= 1,
         "conditional expression inference exposes deterministic resolved/reduction/declare/unknown counters");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "conditional, declare, and reduction inference contributes to deterministic expression-type fingerprints");
   end Test_Ada_Expression_Conditional_Declare_Reduction_Inference;




   procedure Test_Ada_Expression_Membership_Range_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Membership_Range_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Membership_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Range_Node : Editor.Ada_Syntax_Tree.Node_Id;
      M_Left : Editor.Ada_Syntax_Tree.Node_Id;
      M_Right : Editor.Ada_Syntax_Tree.Node_Id;
      R_Left : Editor.Ada_Syntax_Tree.Node_Id;
      R_Right : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Membership_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Range_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (M_Left, M_Right, R_Left, R_Right);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 6, End_Column => 1),
         Label => "package Membership_Ranges is");

      Membership_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Membership_Expression,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 22),
         Parent => Root, Depth => 1, Label => "5 in 1 .. 10");
      M_Left := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 4),
         Parent => Membership_Node, Depth => 2, Label => "5");
      M_Right := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Range_Expression,
         (Start_Line => 2, Start_Column => 9, End_Line => 2, End_Column => 15),
         Parent => Membership_Node, Depth => 2, Label => "1 .. 10");

      Range_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Range_Expression,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 12),
         Parent => Root, Depth => 1, Label => "1 .. 10");
      R_Left := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 4),
         Parent => Range_Node, Depth => 2, Label => "1");
      R_Right := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Literal,
         (Start_Line => 3, Start_Column => 9, End_Line => 3, End_Column => 10),
         Parent => Range_Node, Depth => 2, Label => "10");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      Membership_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Membership_Node);
      Range_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Range_Node);

      Assert
        (Membership_Info.Membership_Range_Status = Editor.Ada_Expression_Types.Membership_Range_Membership_Compatible
         and then Membership_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Operator_Boolean
         and then To_String (Membership_Info.Normalized_Subtype) = "boolean"
         and then Membership_Info.Membership_Compatible_Count = 1,
         "membership inference must classify compatible membership choices as Boolean results");
      Assert
        (Range_Info.Membership_Range_Status = Editor.Ada_Expression_Types.Membership_Range_Range_Compatible
         and then To_String (Range_Info.Normalized_Subtype) = "universal_integer"
         and then Range_Info.Range_Compatible_Count = 1,
         "range inference must preserve compatible bound subtype metadata");
      Assert
        (Editor.Ada_Expression_Types.Membership_Resolved_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Range_Resolved_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "membership and range inference expose deterministic counters and fingerprints");
   end Test_Ada_Expression_Membership_Range_Inference;




   procedure Test_Ada_Expression_Target_Name_Update_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Target_Name_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Point_Type : Editor.Ada_Syntax_Tree.Node_Id;
      Object_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Default_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Delta_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Source_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Target_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Bare_Target : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Delta_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Target_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bare_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Point_Type, Source_Node);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Target_Name_Updates is");

      Point_Type := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Type_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 45),
         Parent => Root, Depth => 1, Label => "type Point is record X : Integer; end record");

      Object_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 48),
         Parent => Root, Depth => 1, Label => "Current : Point := (Current with X => @)");
      Default_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Default,
         (Start_Line => 3, Start_Column => 21, End_Line => 3, End_Column => 42),
         Parent => Object_Node, Depth => 2, Label => "(Current with X => @)");
      Delta_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Delta_Aggregate,
         (Start_Line => 3, Start_Column => 21, End_Line => 3, End_Column => 42),
         Parent => Default_Node, Depth => 3, Label => "(Current with X => @)");
      Source_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Name,
         (Start_Line => 3, Start_Column => 22, End_Line => 3, End_Column => 28),
         Parent => Delta_Node, Depth => 4, Label => "Current");
      Target_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Target_Name,
         (Start_Line => 3, Start_Column => 40, End_Line => 3, End_Column => 40),
         Parent => Delta_Node, Depth => 4, Label => "@");

      Bare_Target := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Target_Name,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 4),
         Parent => Root, Depth => 1, Label => "@");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build_With_Expected_Contexts
        (Tree, Regions, Visibility, Types, Static, Calls, Expected);

      Delta_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Delta_Node);
      Target_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Target_Node);
      Bare_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bare_Target);

      Assert
        (Delta_Info.Target_Name_Status = Editor.Ada_Expression_Types.Target_Name_Delta_Update_Compatible
         and then To_String (Delta_Info.Normalized_Target_Name_Expected_Subtype) = "point"
         and then Delta_Info.Delta_Update_Count = 1,
         "delta aggregate inference must use declaration expected subtype and compatible source subtype metadata");
      Assert
        (Target_Info.Target_Name_Status = Editor.Ada_Expression_Types.Target_Name_Context_Propagated
         and then To_String (Target_Info.Normalized_Subtype) = "point"
         and then Target_Info.Target_Name_Compatible_Count = 1,
         "target-name @ inference must propagate the enclosing update expression expected subtype");
      Assert
        (Bare_Info.Target_Name_Status = Editor.Ada_Expression_Types.Target_Name_Context_Required
         and then Bare_Info.Target_Name_Unknown_Count = 1,
         "bare target-name expressions without an expected update context remain explicitly context-required");
      Assert
        (Editor.Ada_Expression_Types.Target_Name_Context_Propagated_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Target_Name_Update_Compatible_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Target_Name_Context_Required_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "target-name/update inference exposes deterministic counters and fingerprints");
   end Test_Ada_Expression_Target_Name_Update_Inference;






   procedure Test_Ada_Expression_Indexed_Slice_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Indexed_Slice_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Object_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Indexed_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Slice_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Indexed_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Slice_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Object_Node);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 6, End_Column => 1),
         Label => "package Indexed_Slices is");

      Object_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 67),
         Parent => Root, Depth => 1,
         Label => "Values : array (Positive range 1 .. 10) of Integer");

      Indexed_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Indexed_Component,
         (Start_Line => 3, Start_Column => 9, End_Line => 3, End_Column => 18),
         Parent => Root, Depth => 1, Label => "Values (1)");

      Slice_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Slice,
         (Start_Line => 4, Start_Column => 9, End_Line => 4, End_Column => 24),
         Parent => Root, Depth => 1, Label => "Values (1 .. 3)");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      Indexed_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Indexed_Node);
      Slice_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Slice_Node);

      Assert
        (Indexed_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Indexed_Component
         and then Indexed_Info.Indexed_Slice_Status = Editor.Ada_Expression_Types.Indexed_Slice_Index_Compatible
         and then To_String (Indexed_Info.Normalized_Indexed_Slice_Result_Subtype) = "integer"
         and then Indexed_Info.Indexed_Slice_Compatible_Index_Count >= 1,
         "indexed component inference must derive element subtype and compatible index metadata");
      Assert
        (Slice_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Slice
         and then Slice_Info.Indexed_Slice_Status = Editor.Ada_Expression_Types.Indexed_Slice_Index_Compatible
         and then To_String (Slice_Info.Normalized_Indexed_Slice_Result_Subtype) =
           "array (positive range 1 .. 10) of integer",
         "slice inference must preserve the array subtype as the slice result");
      Assert
        (Editor.Ada_Expression_Types.Indexed_Slice_Prefix_Resolved_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Indexed_Slice_Index_Compatible_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Indexed_Slice_Result_Element_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Indexed_Slice_Result_Array_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "indexed/slice inference exposes deterministic counters and fingerprints");
   end Test_Ada_Expression_Indexed_Slice_Inference;







   procedure Test_Ada_Expression_Dereference_Access_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Dereference_Access_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Access_Type : Editor.Ada_Syntax_Tree.Node_Id;
      Access_Def : Editor.Ada_Syntax_Tree.Node_Id;
      Pointer_Object : Editor.Ada_Syntax_Tree.Node_Id;
      Integer_Object : Editor.Ada_Syntax_Tree.Node_Id;
      Deref_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Access_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Deref_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Deref_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Access_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bad_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Access_Def, Pointer_Object, Integer_Object);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 7, End_Column => 1),
         Label => "package Dereference_Access is");

      Access_Type := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Type_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 36),
         Parent => Root, Depth => 1, Label => "type Int_Access is access Integer");
      Access_Def := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype,
         (Start_Line => 2, Start_Column => 23, End_Line => 2, End_Column => 36),
         Parent => Access_Type, Depth => 2, Label => "access Integer");

      Pointer_Object := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 22),
         Parent => Root, Depth => 1, Label => "P : Int_Access");
      Integer_Object := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 15),
         Parent => Root, Depth => 1, Label => "I : Integer");

      Deref_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Explicit_Dereference,
         (Start_Line => 5, Start_Column => 7, End_Line => 5, End_Column => 11),
         Parent => Root, Depth => 1, Label => "P.all");
      Access_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Attribute_Reference,
         (Start_Line => 6, Start_Column => 7, End_Line => 6, End_Column => 14),
         Parent => Root, Depth => 1, Label => "I'Access");
      Bad_Deref_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Explicit_Dereference,
         (Start_Line => 7, Start_Column => 7, End_Line => 7, End_Column => 11),
         Parent => Root, Depth => 1, Label => "I.all");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build
        (Tree, Regions, Visibility, Types, Static, Calls);

      Deref_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Deref_Node);
      Access_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Access_Node);
      Bad_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bad_Deref_Node);

      Assert
        (Deref_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Dereference
         and then Deref_Info.Dereference_Access_Status =
           Editor.Ada_Expression_Types.Dereference_Designated_Subtype_Known
         and then To_String (Deref_Info.Normalized_Dereference_Prefix_Subtype) = "int_access"
         and then To_String (Deref_Info.Normalized_Dereference_Designated_Subtype) = "integer"
         and then To_String (Deref_Info.Normalized_Subtype) = "integer",
         "explicit dereference inference must derive the designated subtype from the access type");
      Assert
        (Access_Info.Dereference_Access_Status =
           Editor.Ada_Expression_Types.Access_Attribute_Result_Known
         and then To_String (Access_Info.Normalized_Access_Target_Subtype) = "integer"
         and then To_String (Access_Info.Normalized_Access_Result_Subtype) = "access integer",
         "Access attribute inference must classify object targets and access result subtypes");
      Assert
        (Bad_Info.Dereference_Access_Status =
           Editor.Ada_Expression_Types.Dereference_Prefix_Not_Access_Type,
         "dereference inference must reject non-access prefixes explicitly");
      Assert
        (Editor.Ada_Expression_Types.Dereference_Resolved_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Dereference_Target_Error_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Access_Result_Resolved_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "dereference/access inference exposes deterministic counters and fingerprints");
   end Test_Ada_Expression_Dereference_Access_Inference;





   procedure Test_Ada_Expression_Allocator_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Expression_Type_Status;
      use type Editor.Ada_Expression_Types.Allocator_Type_Inference_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Access_Type : Editor.Ada_Syntax_Tree.Node_Id;
      Access_Def : Editor.Ada_Syntax_Tree.Node_Id;
      Alloc_Object : Editor.Ada_Syntax_Tree.Node_Id;
      Alloc_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Free_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Object : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Alloc_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Free_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bad_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Access_Def);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 5, End_Column => 1),
         Label => "package Allocator_Expressions is");

      Access_Type := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Type_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 36),
         Parent => Root, Depth => 1, Label => "type Int_Access is access Integer");
      Access_Def := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Declaration_Subtype,
         (Start_Line => 2, Start_Column => 23, End_Line => 2, End_Column => 36),
         Parent => Access_Type, Depth => 2, Label => "access Integer");

      Alloc_Object := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 39),
         Parent => Root, Depth => 1, Label => "P : Int_Access := new Integer");
      Alloc_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Allocator,
         (Start_Line => 3, Start_Column => 22, End_Line => 3, End_Column => 32),
         Parent => Alloc_Object, Depth => 2, Label => "new Integer");

      Free_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Allocator,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 14),
         Parent => Root, Depth => 1, Label => "new Integer");

      Bad_Object := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 5, Start_Column => 4, End_Line => 5, End_Column => 36),
         Parent => Root, Depth => 1, Label => "Q : Integer := new Boolean");
      Bad_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Allocator,
         (Start_Line => 5, Start_Column => 17, End_Line => 5, End_Column => 27),
         Parent => Bad_Object, Depth => 2, Label => "new Boolean");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build_With_Expected_Contexts
        (Tree, Regions, Visibility, Types, Static, Calls, Expected);

      Alloc_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Alloc_Node);
      Free_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Free_Node);
      Bad_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bad_Node);

      Assert
        (Alloc_Info.Status = Editor.Ada_Expression_Types.Expression_Type_Allocator
         and then Alloc_Info.Allocator_Status =
           Editor.Ada_Expression_Types.Allocator_Type_Designated_Compatible
         and then To_String (Alloc_Info.Normalized_Allocator_Target_Subtype) = "integer"
         and then To_String (Alloc_Info.Normalized_Allocator_Expected_Access_Subtype) = "int_access"
         and then To_String (Alloc_Info.Normalized_Allocator_Designated_Subtype) = "integer"
         and then To_String (Alloc_Info.Normalized_Subtype) = "int_access",
         "allocator inference must propagate an expected access type and match its designated subtype");
      Assert
        (Free_Info.Allocator_Status = Editor.Ada_Expression_Types.Allocator_Type_Result_Known
         and then To_String (Free_Info.Normalized_Allocator_Result_Subtype) = "access integer",
         "allocator inference must retain anonymous access result metadata without an expected context");
      Assert
        (Bad_Info.Allocator_Status = Editor.Ada_Expression_Types.Allocator_Type_Expected_Not_Access,
         "allocator inference must reject non-access expected contexts explicitly");
      Assert
        (Editor.Ada_Expression_Types.Allocator_Resolved_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Allocator_Designated_Resolved_Count (Exprs) >= 2
         and then Editor.Ada_Expression_Types.Allocator_Target_Error_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "allocator inference exposes deterministic counters and fingerprints");
   end Test_Ada_Expression_Allocator_Inference;




   procedure Test_Ada_Expression_Parameter_Association_Propagation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Parameter_Association_Inference_Status;
      use type Editor.Ada_Expression_Types.Expected_Type_Propagation_Status;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Proc_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Call_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Pos_Actual : Editor.Ada_Syntax_Tree.Node_Id;
      Named_Actual : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Actual : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Pos_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Named_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      Bad_Info : Editor.Ada_Expression_Types.Expression_Type_Info;
      pragma Unreferenced (Proc_Node);
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 6, End_Column => 1),
         Label => "package Parameter_Actuals is");

      Proc_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 55),
         Parent => Root, Depth => 1,
         Label => "procedure Take (X : Integer; Flag : Boolean; Name : String)");

      Call_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Call_Statement,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 49),
         Parent => Root, Depth => 1,
         Label => "Take (42, Flag => True, Name => 99)");
      Pos_Actual := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Positional_Association,
         (Start_Line => 4, Start_Column => 10, End_Line => 4, End_Column => 11),
         Parent => Call_Node, Depth => 2, Label => "42");
      Named_Actual := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Named_Association,
         (Start_Line => 4, Start_Column => 14, End_Line => 4, End_Column => 25),
         Parent => Call_Node, Depth => 2, Label => "Flag => True");
      Bad_Actual := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Named_Association,
         (Start_Line => 4, Start_Column => 28, End_Line => 4, End_Column => 37),
         Parent => Call_Node, Depth => 2, Label => "Name => 99");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build_With_Expected_Contexts
        (Tree, Regions, Visibility, Types, Static, Calls, Expected);

      Pos_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Pos_Actual);
      Named_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Named_Actual);
      Bad_Info := Editor.Ada_Expression_Types.Expression_Type_For_Node (Exprs, Bad_Actual);

      Assert
        (Pos_Info.Parameter_Association_Status =
           Editor.Ada_Expression_Types.Parameter_Association_Compatible
         and then To_String (Pos_Info.Normalized_Parameter_Association_Formal_Subtype) = "integer"
         and then To_String (Pos_Info.Normalized_Parameter_Association_Actual_Subtype) = "universal_integer",
         "positional actuals must receive formal expected-type metadata");
      Assert
        (Named_Info.Parameter_Association_Status =
           Editor.Ada_Expression_Types.Parameter_Association_Compatible
         and then To_String (Named_Info.Normalized_Parameter_Association_Formal_Name) = "flag"
         and then To_String (Named_Info.Normalized_Parameter_Association_Formal_Subtype) = "boolean",
         "named actuals must resolve their target formal and expected subtype");
      Assert
        (Bad_Info.Parameter_Association_Status =
           Editor.Ada_Expression_Types.Parameter_Association_Mismatch
         and then Bad_Info.Expected_Status = Editor.Ada_Expression_Types.Expected_Type_Mismatch
         and then To_String (Bad_Info.Normalized_Parameter_Association_Formal_Subtype) = "string"
         and then To_String (Bad_Info.Normalized_Parameter_Association_Actual_Subtype) = "universal_integer",
         "parameter expected-type propagation must preserve actual/formal mismatches");
      Assert
        (Editor.Ada_Expression_Types.Parameter_Association_Context_Count (Exprs) >= 3
         and then Editor.Ada_Expression_Types.Parameter_Association_Mismatch_Count (Exprs) >= 1
         and then Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "parameter-association propagation exposes deterministic counters and fingerprints");
   end Test_Ada_Expression_Parameter_Association_Propagation;




   procedure Test_Ada_Expression_Universal_Numeric_Final_Resolution
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Numeric_Context is" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 10;" & ASCII.LF &
        "   type Mod8 is mod 8;" & ASCII.LF &
        "   type Fixed is delta 0.25 range -4.0 .. 4.0;" & ASCII.LF &
        "   A : Small := 5;" & ASCII.LF &
        "   B : Small := 99;" & ASCII.LF &
        "   C : Float := 1.5;" & ASCII.LF &
        "   D : Mod8 := 12;" & ASCII.LF &
        "   E : Fixed := 2.0;" & ASCII.LF &
        "end Numeric_Context;";
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
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build (Tree, Regions, Calls);
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Expected_Contexts
          (Tree, Regions, Visibility, Types, Static, Calls, Expected);

      function Has_Status
        (Status : Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status)
         return Boolean
      is
      begin
         for Index in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Exprs) loop
            declare
               Info : constant Editor.Ada_Expression_Types.Expression_Type_Info :=
                 Editor.Ada_Expression_Types.Expression_Type_At (Exprs, Index);
            begin
               if Info.Universal_Numeric_Status = Status then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Status;
   begin
      Assert
        (Has_Status (Editor.Ada_Expression_Types.Universal_Numeric_Integer_Resolved)
         or else Has_Status (Editor.Ada_Expression_Types.Universal_Numeric_Range_Compatible)
         or else Editor.Ada_Expression_Types.Universal_Numeric_Resolved_Count (Exprs) >= 1,
         "universal integer expressions must resolve into expected integer subtype contexts");
      Assert
        (Has_Status (Editor.Ada_Expression_Types.Universal_Numeric_Real_Resolved)
         or else Has_Status (Editor.Ada_Expression_Types.Universal_Numeric_Fixed_Resolved)
         or else Editor.Ada_Expression_Types.Universal_Numeric_Resolved_Count (Exprs) >= 2,
         "universal real expressions must resolve into expected real or fixed subtype contexts");
      Assert
        (Has_Status (Editor.Ada_Expression_Types.Universal_Numeric_Range_Error)
         or else Editor.Ada_Expression_Types.Universal_Numeric_Range_Error_Count (Exprs) >= 1,
         "universal integer final resolution must preserve static range violations");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "universal numeric final resolution contributes deterministic fingerprints");
   end Test_Ada_Expression_Universal_Numeric_Final_Resolution;



   procedure Test_Ada_Expression_Aggregate_Type_Graph_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aggregate_Context is" & ASCII.LF &
        "   type Point is record" & ASCII.LF &
        "      X : Integer;" & ASCII.LF &
        "      Y : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   P1 : Point := (X => 1, Y => 2);" & ASCII.LF &
        "   P2 : Point := (X => 1, Z => 2);" & ASCII.LF &
        "   P3 : Point := (X => 1, X => 2);" & ASCII.LF &
        "   V1 : Vector := (1, 2, 3);" & ASCII.LF &
        "   V2 : Vector := (1, True);" & ASCII.LF &
        "end Aggregate_Context;";
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
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build (Tree, Regions, Calls);
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Expected_Contexts
          (Tree, Regions, Visibility, Types, Static, Calls, Expected);
   begin
      Assert
        (Editor.Ada_Expression_Types.Aggregate_Context_Resolved_Count (Exprs) >= 1,
         "aggregate inference must retain context-resolved aggregate metadata");
      Assert
        (Editor.Ada_Expression_Types.Aggregate_Record_Component_Compatible_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Aggregate_Array_Element_Compatible_Count (Exprs) >= 1,
         "aggregate validation must count compatible record components or array elements");
      Assert
        (Editor.Ada_Expression_Types.Aggregate_Record_Component_Missing_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Aggregate_Record_Component_Duplicate_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Aggregate_Array_Element_Mismatch_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Aggregate_Mismatch_Count (Exprs) >= 1,
         "aggregate validation must preserve component/element mismatch metadata");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "aggregate type-graph validation contributes deterministic fingerprints");
   end Test_Ada_Expression_Aggregate_Type_Graph_Validation;





   procedure Test_Ada_Expression_Raise_No_Return_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Raise_Context is" & ASCII.LF &
        "   type Small is range 1 .. 10;" & ASCII.LF &
        "   procedure Stop with No_Return;" & ASCII.LF &
        "   X : Small := raise Constraint_Error with ""bad"";" & ASCII.LF &
        "   procedure Body_Test is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      raise Program_Error with ""bad"";" & ASCII.LF &
        "      Stop;" & ASCII.LF &
        "   end Body_Test;" & ASCII.LF &
        "end Raise_Context;";
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
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build (Tree, Regions, Calls);
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Expected_Contexts
          (Tree, Regions, Visibility, Types, Static, Calls, Expected);
   begin
      Assert
        (Editor.Ada_Expression_Types.Raise_Expression_Count (Exprs) >= 1,
         "raise expression/statement inference must retain raise metadata");
      Assert
        (Editor.Ada_Expression_Types.Raise_No_Return_Count (Exprs) >= 1,
         "raise expressions and No_Return calls must contribute no-return metadata");
      Assert
        (Editor.Ada_Expression_Types.Raise_Message_Count (Exprs) >= 1,
         "raise expressions with messages must preserve message-shape metadata");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "raise/no-return inference contributes deterministic fingerprints");
   end Test_Ada_Expression_Raise_No_Return_Inference;




   procedure Test_Ada_Expression_Boolean_Context_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Boolean_Context is" & ASCII.LF &
        "   Flag : Boolean := True;" & ASCII.LF &
        "   Count : Integer := 1;" & ASCII.LF &
        "   Ok : Boolean := Flag and then not False;" & ASCII.LF &
        "   Bad : Boolean := Count and then Flag;" & ASCII.LF &
        "   procedure Body_Test is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if Flag then" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "      while Flag loop" & ASCII.LF &
        "         exit when Count;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "   end Body_Test;" & ASCII.LF &
        "end Boolean_Context;";
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
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build (Tree, Regions, Calls);
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Expected_Contexts
          (Tree, Regions, Visibility, Types, Static, Calls, Expected);
   begin
      Assert
        (Editor.Ada_Expression_Types.Boolean_Context_Count (Exprs) >= 1,
         "Boolean-context inference must retain short-circuit and condition metadata");
      Assert
        (Editor.Ada_Expression_Types.Boolean_Context_Compatible_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Boolean_Context_Unknown_Count (Exprs) >= 1,
         "Boolean-context inference must classify compatible or unknown Boolean operands");
      Assert
        (Editor.Ada_Expression_Types.Boolean_Context_Mismatch_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Boolean_Context_Unknown_Count (Exprs) >= 1,
         "Boolean-context inference must preserve non-Boolean condition metadata");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "Boolean-context inference contributes deterministic fingerprints");
   end Test_Ada_Expression_Boolean_Context_Inference;




   procedure Test_Ada_Expression_Concatenation_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Concatenation_Context is" & ASCII.LF &
        "   type Chars is array (Positive range <>) of Character;" & ASCII.LF &
        "   Left  : String := ""ab"";" & ASCII.LF &
        "   Right : String := ""cd"";" & ASCII.LF &
        "   Text  : String := Left & Right;" & ASCII.LF &
        "   More  : String := Text & 'x';" & ASCII.LF &
        "   Bad   : String := 1 & Text;" & ASCII.LF &
        "end Concatenation_Context;";
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
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build (Tree, Regions, Calls);
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Expected_Contexts
          (Tree, Regions, Visibility, Types, Static, Calls, Expected);
   begin
      Assert
        (Editor.Ada_Expression_Types.Concatenation_Resolved_Count (Exprs) >= 1,
         "concatenation inference must resolve string/array-compatible operands");
      Assert
        (Editor.Ada_Expression_Types.Concatenation_String_Result_Count (Exprs) >= 1,
         "concatenation inference must infer string-family results");
      Assert
        (Editor.Ada_Expression_Types.Concatenation_Mismatch_Count (Exprs) >= 1
         or else Editor.Ada_Expression_Types.Concatenation_Unknown_Count (Exprs) >= 1,
         "concatenation inference must preserve mismatched or unknown operands");
      Assert
        (Editor.Ada_Expression_Types.Fingerprint (Exprs) /= 0,
         "concatenation inference contributes deterministic fingerprints");
   end Test_Ada_Expression_Concatenation_Inference;




   procedure Test_Ada_Expression_Diagnostics_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Kind;
      use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Severity;
      pragma Unreferenced (T);
      Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Root : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Object : Editor.Ada_Syntax_Tree.Node_Id;
      Bad_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Exprs : Editor.Ada_Expression_Types.Expression_Type_Model;
      Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Diag : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Info;
   begin
      Root := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
         (Start_Line => 1, Start_Column => 1, End_Line => 3, End_Column => 1),
         Label => "package Expression_Diagnostics is");

      Bad_Object := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Object_Declaration,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 36),
         Parent => Root, Depth => 1, Label => "Q : Integer := new Boolean");
      Bad_Node := Editor.Ada_Syntax_Tree.Add_Node
        (Tree, Editor.Ada_Syntax_Tree.Node_Allocator,
         (Start_Line => 2, Start_Column => 17, End_Line => 2, End_Column => 27),
         Parent => Bad_Object, Depth => 2, Label => "new Boolean");

      Regions := Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility := Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types := Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static := Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Exprs := Editor.Ada_Expression_Types.Build_With_Expected_Contexts
        (Tree, Regions, Visibility, Types, Static, Calls, Expected);
      Diags := Editor.Ada_Expression_Diagnostics.Build (Exprs);
      Diag := Editor.Ada_Expression_Diagnostics.Diagnostic_For_Node (Diags, Bad_Node);

      Assert
        (Editor.Ada_Expression_Diagnostics.Has_Diagnostics (Diags)
         and then Editor.Ada_Expression_Diagnostics.Error_Count (Diags) >= 1,
         "expression diagnostics projection must emit error diagnostics for staged expression mismatches");
      Assert
        (Diag.Kind = Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Allocator_Target_Error
         and then Diag.Severity = Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Error
         and then Diag.Start_Line = 2
         and then Diag.End_Line = 2,
         "expression diagnostics must retain stable kind, severity, and source span metadata");
      Assert
        (Editor.Ada_Expression_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Allocator_Target_Error) >= 1
         and then Editor.Ada_Expression_Diagnostics.Fingerprint (Diags) /= 0,
         "expression diagnostics must expose deterministic counters and fingerprints");
   end Test_Ada_Expression_Diagnostics_Projection;



   procedure Test_Ada_Expression_Selected_Name_Operator_Expected_Combined_Inference
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
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
        "   Sum : Integer := 1 + 2;" & ASCII.LF &
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
      Primitive_Uses : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Model :=
        Editor.Ada_Use_Type_Operators.Build (Tree, Regions, Visibility, Uses);
      Candidates : constant Editor.Ada_Call_Candidates.Call_Candidate_Model :=
        Editor.Ada_Call_Candidates.Build
          (Tree, Regions, Visibility, Uses, Primitive_Uses);
      Profile_Shapes : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Profile_Filters : constant Editor.Ada_Call_Profile_Filters.Profile_Filter_Model :=
        Editor.Ada_Call_Profile_Filters.Build
          (Candidates, Profile_Shapes, Visibility);
      Calls : constant Editor.Ada_Call_Resolution.Call_Resolution_Model :=
        Editor.Ada_Call_Resolution.Build (Candidates, Profile_Filters);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Expected : constant Editor.Ada_Expected_Type_Contexts.Expected_Context_Model :=
        Editor.Ada_Expected_Type_Contexts.Build
          (Tree, Regions, Visibility, Profile_Shapes, Calls);
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Model : Editor.Ada_Expression_Types.Expression_Type_Model;
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
      Model :=
        Editor.Ada_Expression_Types
          .Build_With_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
            (Tree, Regions, Visibility, Types, Static, Calls, Selected,
             Primitive_Uses, Expected);

      Assert
        (Editor.Ada_Expression_Types.Cross_Unit_Selected_Name_Resolved_Count (Model) >= 1,
         "combined expression builder should preserve cross-unit selected-name inference");
      Assert
        (Editor.Ada_Expression_Types.Expected_Context_Count (Model) >= 1,
         "combined expression builder should preserve expected-context propagation");
      Assert
        (Editor.Ada_Expression_Types.Operator_Resolved_Count (Model) +
         Editor.Ada_Expression_Types.Operator_Operand_Unknown_Count (Model) +
         Editor.Ada_Expression_Types.Operator_Overload_Resolved_Count (Model) +
         Editor.Ada_Expression_Types.Operator_Overload_Unknown_Count (Model) >= 1,
         "combined expression builder should preserve operator inference evidence");
   end Test_Ada_Expression_Selected_Name_Operator_Expected_Combined_Inference;




   procedure Test_Ada_Expression_Diagnostics_View_Compatibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id;
      Library_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Library is" & ASCII.LF &
           "   Exported : Integer;" & ASCII.LF &
           "end Library;" & ASCII.LF,
           "library.ads");
      Client_Source : constant String :=
        "private with Library;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   Value : Integer := Library.Exported;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.ads");
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
      Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Diags : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      First : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Info;
   begin
      Editor.Ada_Project_Index.Clear (Index);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/library.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Library_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Cross_Lookup := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Cross_Visibility, Source_Unit_Name => "Client");
      Selected := Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
        (Tree, Regions, Visibility, Uses, Cross_Lookup);
      Expressions := Editor.Ada_Expression_Types.Build_With_Cross_Unit_Selected_Names
        (Tree, Regions, Visibility, Types, Static, Calls, Selected);
      Views := Editor.Ada_View_Aware_Compatibility.Build (Expressions);
      Diags := Editor.Ada_Expression_Diagnostics.Build_With_View_Compatibility
        (Expressions, Views);
      First := Editor.Ada_Expression_Diagnostics.Diagnostic_At
        (Diags, Editor.Ada_Expression_Diagnostics.Diagnostic_Count (Diags));

      Assert
        (Editor.Ada_Expression_Diagnostics.View_Compatibility_Diagnostic_Count (Diags) >= 1,
         "expression diagnostics must project private/limited view compatibility barriers");
      Assert
        (First.From_View_Compatibility
         and then First.View_Compatibility /= Editor.Ada_View_Aware_Compatibility.No_View_Compatibility
         and then First.View_Fingerprint /= 0
         and then Length (First.Detail) > 0,
         "view-aware diagnostics must preserve source view identity, fingerprint, and detail");
      Assert
        (Editor.Ada_Expression_Diagnostics.Private_View_Diagnostic_Count (Diags) +
         Editor.Ada_Expression_Diagnostics.Limited_View_Diagnostic_Count (Diags) +
         Editor.Ada_Expression_Diagnostics.View_Unresolved_Diagnostic_Count (Diags) >= 1,
         "view-aware diagnostics must expose private, limited, or unresolved visibility counters");
      Assert
        (Editor.Ada_Expression_Diagnostics.Fingerprint (Diags) /= 0,
         "view-aware expression diagnostics projection must produce a deterministic fingerprint");
   end Test_Ada_Expression_Diagnostics_View_Compatibility;


   overriding function Name (T : Expression_Inference_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Expression.Inference");
   end Name;

   overriding procedure Register_Tests (T : in out Expression_Inference_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Resolver_Expression_Aware_Operator_Expressions'Access, Name => "resolver call overload resolution infers operator expressions");
      Add_Test (Routine => Test_Resolver_Expression_Aware_Unary_And_Membership'Access, Name => "resolver call overload resolution infers unary and membership expressions");
      Add_Test (Routine => Test_Resolver_Expression_Aware_Conditional_Expressions'Access, Name => "resolver call overload resolution infers conditional expressions");
      Add_Test (Routine => Test_Language_Model_Executable_Deep_Expression_Name_Bindings'Access, Name => "language model retains deep executable expression name bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Type_Conversion_Bindings'Access, Name => "language model retains executable type conversion targets");
      Add_Test (Routine => Test_Language_Model_Executable_Case_Expression_Bindings'Access, Name => "language model retains executable case expression bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Conditional_Expression_Bindings'Access, Name => "language model retains executable conditional expression bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Raise_Expression_Bindings'Access, Name => "language model retains executable raise expression bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Quantified_Expression_Bindings'Access, Name => "language model retains executable quantified expression bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Transfer_And_Tasking_Targets'Access, Name => "language model retains executable transfer and tasking targets");
      Add_Test (Routine => Test_Language_Model_Executable_Return_Bindings'Access, Name => "language model retains executable return bindings");
      Add_Test (Routine => Test_Ada_Expression_Expected_Type_Propagation'Access, Name => "Ada expression type model propagates expected types beyond calls");
      Add_Test (Routine => Test_Ada_Expression_Operator_Operand_Inference'Access, Name => "Ada expression type model infers operator operand and result types");
      Add_Test (Routine => Test_Ada_Expression_Aggregate_Context_Inference'Access, Name => "Ada expression type model infers aggregate context and component shape");
      Add_Test (Routine => Test_Ada_Expression_Conversion_Qualified_Inference'Access, Name => "Ada expression type model infers conversions and qualified expressions");
      Add_Test (Routine => Test_Ada_Expression_Attribute_Reference_Inference'Access, Name => "Ada expression type model infers attribute references");
      Add_Test (Routine => Test_Ada_Expression_Conditional_Declare_Reduction_Inference'Access, Name => "Ada expression type model infers conditional declare and reduction expressions");
      Add_Test (Routine => Test_Ada_Expression_Membership_Range_Inference'Access, Name => "Ada expression type model infers membership and range expressions");
      Add_Test (Routine => Test_Ada_Expression_Target_Name_Update_Inference'Access, Name => "Ada expression type model infers target-name and update expressions");
      Add_Test (Routine => Test_Ada_Expression_Indexed_Slice_Inference'Access, Name => "Ada expression type model infers indexed components and slices");
      Add_Test (Routine => Test_Ada_Expression_Dereference_Access_Inference'Access, Name => "Ada expression type model infers dereference and access attributes");
      Add_Test (Routine => Test_Ada_Expression_Allocator_Inference'Access, Name => "Ada expression type model infers allocator expressions");
      Add_Test (Routine => Test_Ada_Expression_Parameter_Association_Propagation'Access, Name => "Ada expression type model propagates parameter association expected types");
      Add_Test (Routine => Test_Ada_Expression_Universal_Numeric_Final_Resolution'Access, Name => "Ada expression type model resolves universal numeric expressions into expected contexts");
      Add_Test (Routine => Test_Ada_Expression_Aggregate_Type_Graph_Validation'Access, Name => "Ada expression type model validates aggregates against type graph context");
      Add_Test (Routine => Test_Ada_Expression_Raise_No_Return_Inference'Access, Name => "Ada expression type model infers raise expressions and no-return calls");
      Add_Test (Routine => Test_Ada_Expression_Boolean_Context_Inference'Access, Name => "Ada expression type model propagates Boolean contexts into conditions");
      Add_Test (Routine => Test_Ada_Expression_Concatenation_Inference'Access, Name => "Ada expression type model infers string and array concatenation results");
      Add_Test (Routine => Test_Ada_Expression_Diagnostics_Projection'Access, Name => "Ada expression diagnostics project expression type metadata into stable diagnostics");
      Add_Test (Routine => Test_Ada_Expression_Selected_Name_Operator_Expected_Combined_Inference'Access, Name => "Ada expression inference combines selected names, operators, and expected contexts");
      Add_Test (Routine => Test_Ada_Expression_Diagnostics_View_Compatibility'Access, Name => "Ada expression diagnostics project private and limited view compatibility barriers");
   end Register_Tests;

end Editor.Syntax_Semantics.Expression_Inference_Tests;
