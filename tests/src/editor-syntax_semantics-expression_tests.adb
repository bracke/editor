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

package body Editor.Syntax_Semantics.Expression_Tests is



   procedure Test_Language_Model_Function_Return_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Function_Targets is" & ASCII.LF &
        "   function Make return Root'Class;" & ASCII.LF &
        "   function Is_Ready (Item : Root'Class) return Boolean with Inline;" & ASCII.LF &
        "   function ""+"" (Left, Right : Integer) return Integer renames Add;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with function Convert (Item : Element) return Root'Class;" & ASCII.LF &
        "   procedure Use_Convert;" & ASCII.LF &
        "end Function_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "function_targets.ads");
      Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make");
      Ready_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Is_Ready");
      Operator_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """+""");
      Convert_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Convert");
      Make_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Id);
      Ready_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ready_Id);
      Operator_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Operator_Id);
      Convert_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Convert_Id);
   begin
      Assert (Make_Id /= Editor.Ada_Language_Model.No_Symbol,
              "function declaration should parse for return target metadata");
      Assert (Ready_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aspected function declaration should parse for return target metadata");
      Assert (Convert_Id /= Editor.Ada_Language_Model.No_Symbol,
              "generic formal function should parse for return target metadata");
      Assert (To_String (Make_Info.Target_Name) = "Root'Class",
              "function return subtype should be retained as target metadata");
      Assert (To_String (Ready_Info.Target_Name) = "Boolean",
              "function return target should stop before aspect metadata");
      Assert (To_String (Operator_Info.Target_Name) = "Add",
              "renamed operator functions should keep rename target instead of return target");
      Assert (To_String (Convert_Info.Target_Name) = "Root'Class",
              "generic formal function return subtype should be retained as target metadata");
   end Test_Language_Model_Function_Return_Target_Metadata;



   procedure Test_Language_Model_Split_Function_Return_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Return_Targets is" & ASCII.LF &
        "   function Make" & ASCII.LF &
        "      return Root'Class;" & ASCII.LF &
        "   function Convert" & ASCII.LF &
        "     (Item : Element)" & ASCII.LF &
        "      return Result_Type;" & ASCII.LF &
        "   function Build" & ASCII.LF &
        "     (Input : Element)" & ASCII.LF &
        "      return Root'Class" & ASCII.LF &
        "   is" & ASCII.LF &
        "      Local : constant Boolean := True;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Input;" & ASCII.LF &
        "   end Build;" & ASCII.LF &
        "end Split_Return_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_return_targets.ads");
      Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make");
      Convert_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Convert");
      Build_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Build");
      Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Local");
      Make_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Id);
      Convert_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Convert_Id);
      Build_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Build_Id);
      Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Id);
   begin
      Assert (Make_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Convert_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Build_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split function declarations should parse");
      Assert (To_String (Make_Info.Target_Name) = "Root'Class",
              "function return target on a following line should be retained");
      Assert (To_String (Convert_Info.Target_Name) = "Result_Type",
              "split profile/function return target should be retained");
      Assert (To_String (Build_Info.Target_Name) = "Root'Class",
              "split function body return target before is should be retained");
      Assert (Local_Info.Parent_Symbol = Build_Id,
              "split function body local declarations should remain parented to the function");
   end Test_Language_Model_Split_Function_Return_Target_Metadata;






   procedure Test_Language_Model_Task_And_Protected_Interface_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Task_Protected_Interface_Metadata is" & ASCII.LF &
        "   type Worker_Interface is task interface;" & ASCII.LF &
        "   type Gate_Interface is protected interface;" & ASCII.LF &
        "   type Sync_Interface is synchronized interface;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Formal_Worker is task interface;" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Task_Protected_Interface_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "task_protected_interface_metadata.ads");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker_Interface");
      Gate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Gate_Interface");
      Sync_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Sync_Interface");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Worker");
      Worker_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Worker_Id);
      Gate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Gate_Id);
      Sync_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Sync_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Worker_Info.Flags.Has_Interface_Metadata
              and then Worker_Info.Flags.Has_Task_Interface_Metadata,
              "task interface should retain task-interface metadata");
      Assert (Gate_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Gate_Info.Flags.Has_Interface_Metadata
              and then Gate_Info.Flags.Has_Protected_Interface_Metadata,
              "protected interface should retain protected-interface metadata");
      Assert (Sync_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Sync_Info.Flags.Has_Interface_Metadata
              and then Sync_Info.Flags.Has_Synchronized_Metadata
              and then not Sync_Info.Flags.Has_Task_Interface_Metadata
              and then not Sync_Info.Flags.Has_Protected_Interface_Metadata,
              "synchronized interface should not be misclassified as task/protected interface");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Formal_Info.Flags.Has_Task_Interface_Metadata,
              "generic formal task interface should retain task-interface metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "task") =
                Editor.Ada_Language_Model.No_Symbol,
              "task keyword must not become a declaration symbol");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "protected") =
                Editor.Ada_Language_Model.No_Symbol,
              "protected keyword must not become a declaration symbol");
   end Test_Language_Model_Task_And_Protected_Interface_Metadata;



   procedure Test_Language_Model_Default_Expression_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Defaults is" & ASCII.LF &
        "   type Mode is (Fast, Slow);" & ASCII.LF &
        "   type Config (Kind : Mode := Fast) is record" & ASCII.LF &
        "      Count : Integer := 0;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Limit : constant Integer := 10;" & ASCII.LF &
        "   procedure Run (Count : Integer := Limit);" & ASCII.LF &
        "end Defaults;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "default_expression_metadata.ads");
      Config_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Config");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Limit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Limit");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      Config_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Config_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Limit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Limit_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
   begin
      Assert (Config_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Config_Info.Flags.Has_Default_Expression_Metadata,
              "discriminant defaults should remain declaration metadata");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Count_Info.Flags.Has_Default_Expression_Metadata,
              "record component defaults should remain declaration metadata");
      Assert (Limit_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Limit_Info.Flags.Has_Default_Expression_Metadata,
              "object/constant initializers should remain declaration metadata");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Flags.Has_Default_Expression_Metadata,
              "subprogram parameter defaults should remain declaration metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, ":=") =
                Editor.Ada_Language_Model.No_Symbol,
              "default-expression syntax must not become a declaration symbol");
   end Test_Language_Model_Default_Expression_Metadata;





   procedure Test_Language_Model_Task_And_Protected_Type_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Concurrent_Metadata is" & ASCII.LF &
        "   task Worker is" & ASCII.LF &
        "      entry Start (Value : in Integer; Flag, Other : Boolean);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task type Worker_Type is" & ASCII.LF &
        "      entry Start;" & ASCII.LF &
        "   end Worker_Type;" & ASCII.LF &
        "   protected Lock is" & ASCII.LF &
        "      procedure Touch;" & ASCII.LF &
        "   end Lock;" & ASCII.LF &
        "   protected type Lock_Type is" & ASCII.LF &
        "      procedure Touch;" & ASCII.LF &
        "   end Lock_Type;" & ASCII.LF &
        "end Concurrent_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "task_protected_type_metadata.ads");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Worker_Type_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker_Type");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Lock");
      Lock_Type_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Lock_Type");
      Worker_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Worker_Id);
      Worker_Type_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Worker_Type_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Lock_Type_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Type_Id);
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Worker_Info.Flags.Has_Task_Type_Metadata,
              "single task declarations should not be marked task-type");
      Assert (Worker_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Worker_Type_Info.Flags.Has_Task_Type_Metadata,
              "task type declarations should retain task-type metadata");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Lock_Info.Flags.Has_Protected_Type_Metadata,
              "single protected declarations should not be marked protected-type");
      Assert (Lock_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Type_Info.Flags.Has_Protected_Type_Metadata,
              "protected type declarations should retain protected-type metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "task") =
                Editor.Ada_Language_Model.No_Symbol,
              "task keyword must not become a declaration symbol");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "protected") =
                Editor.Ada_Language_Model.No_Symbol,
              "protected keyword must not become a declaration symbol");
   end Test_Language_Model_Task_And_Protected_Type_Metadata;



   procedure Test_Language_Model_One_Line_Package_Protected_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package One_Line_Protected_Tail is protected Lock_Box is procedure Enter; entry Leave (Code : Natural); end Lock_Box; After_Lock : Integer; end One_Line_Protected_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_package_protected_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Protected_Tail");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Lock_Box");
      Enter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Enter");
      Leave_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Leave");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Lock");
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Enter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Enter_Id);
      Leave_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Leave_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package should be emitted");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected
              and then Lock_Info.Parent_Symbol = Package_Id,
              "compact protected declaration should be parented to the package");
      Assert (Enter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enter_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Enter_Info.Parent_Symbol = Lock_Id,
              "protected operation should remain protected-scope local");
      Assert (Leave_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Leave_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Leave_Info.Parent_Symbol = Lock_Id,
              "protected entry should not be split into the package scope");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id
              and then After_Info.Declaration_Column > Leave_Info.Declaration_Column,
              "declarations after compact protected end should resume in package scope");
   end Test_Language_Model_One_Line_Package_Protected_Tail;



   procedure Test_Language_Model_One_Line_Package_Protected_Discriminant_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package One_Line_Protected_Discriminant_Tail is protected type Lock_Box (Left : Integer; Right : Integer) is procedure Enter; entry Leave; end Lock_Box; After_Lock : Integer; end One_Line_Protected_Discriminant_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_package_protected_discriminant_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Protected_Discriminant_Tail");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Lock_Box");
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Left", Lock_Id);
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Right", Lock_Id);
      Enter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enter", Lock_Id);
      Leave_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Leave", Lock_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Lock", Package_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Left_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Left_Id);
      Right_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Right_Id);
      Enter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Enter_Id);
      Leave_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Leave_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package should be emitted");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected
              and then Lock_Info.Parent_Symbol = Package_Id,
              "compact protected type with discriminants should be package-local");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Left_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Left_Info.Parent_Symbol = Lock_Id,
              "first protected-type discriminant should be protected-scope local");
      Assert (Right_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Right_Info.Parent_Symbol = Lock_Id,
              "second protected-type discriminant should not split the package tail");
      Assert (Enter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enter_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Enter_Info.Parent_Symbol = Lock_Id,
              "protected operation after discriminant profile should remain protected-local");
      Assert (Leave_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Leave_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Leave_Info.Parent_Symbol = Lock_Id,
              "protected entry after discriminant profile should remain protected-local");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after compact protected type end should resume in package scope");
   end Test_Language_Model_One_Line_Package_Protected_Discriminant_Tail;



   procedure Test_Language_Model_One_Line_Package_Protected_Body_Operation_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Protected_Body_Operation_Tail is protected body Lock_Box is procedure Enter is begin if True then null; end if; end Enter; entry Leave when True is begin null; end Leave; end Lock_Box; After_Lock : Integer; end One_Line_Protected_Body_Operation_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_package_protected_body_operation_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Protected_Body_Operation_Tail");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Lock_Box", Package_Id);
      Enter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enter", Lock_Id);
      Leave_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Leave", Lock_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Lock", Package_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Enter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Enter_Id);
      Leave_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Leave_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected
              and then Lock_Info.Parent_Symbol = Package_Id,
              "compact protected body should stay package-body local");
      Assert (Enter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enter_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Enter_Info.Parent_Symbol = Lock_Id,
              "protected operation body should not close the protected tail early");
      Assert (Leave_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Leave_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Leave_Info.Parent_Symbol = Lock_Id,
              "protected entry body should remain protected-body local after an operation end");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after compact protected body end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Protected_Body_Operation_Tail;



   procedure Test_Language_Model_One_Line_Package_Protected_Body_Bare_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Protected_Body_Bare_Block_Tail is protected body Lock_Box is procedure Enter is begin begin null; end; Local_After : Integer; end Enter; end Lock_Box; After_Lock : Integer; end One_Line_Protected_Body_Bare_Block_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_package_protected_body_bare_block_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Protected_Body_Bare_Block_Tail");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Lock_Box", Package_Id);
      Enter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enter", Lock_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Enter_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Lock", Package_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Enter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Enter_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected
              and then Lock_Info.Parent_Symbol = Package_Id,
              "compact protected body should stay package-body local");
      Assert (Enter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enter_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Enter_Info.Parent_Symbol = Lock_Id,
              "protected operation should remain protected-body local");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Enter_Id,
              "bare block end inside protected operation must not close the protected body");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after compact protected body end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Protected_Body_Bare_Block_Tail;



   procedure Test_Language_Model_One_Line_Selected_Protected_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Selected_Protected_Tail is protected body Parent_Unit.Lock_Box is procedure Enter is begin Parent_Unit : declare Block_Local : Integer; begin null; end Parent_Unit; end Enter; procedure Leave is begin null; end Leave; end Parent_Unit.Lock_Box; Outer_After : Integer; end One_Line_Selected_Protected_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_selected_protected_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Selected_Protected_Tail");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Parent_Unit.Lock_Box", Package_Id);
      Enter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enter", Lock_Id);
      Leave_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Leave", Lock_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Outer_After", Package_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Enter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Enter_Id);
      Leave_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Leave_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected
              and then Lock_Info.Parent_Symbol = Package_Id,
              "selected compact protected body should remain package-body local");
      Assert (Enter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enter_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Enter_Info.Parent_Symbol = Lock_Id,
              "protected operation should remain selected-protected-body local");
      Assert (Leave_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Leave_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Leave_Info.Parent_Symbol = Lock_Id,
              "inner same-prefix end must not close a selected compact protected body");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Package_Id,
              "declarations after the selected protected-body end should resume in package-body scope");
   end Test_Language_Model_One_Line_Selected_Protected_Tail;



   procedure Test_Language_Model_One_Line_Package_Expression_Function_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Expression_Function_Tail is function Compute (Left : Integer; Right : Integer) return Integer is (Left + Right); After_Compute : Integer; procedure Done is null; After_Done : Integer; end One_Line_Expression_Function_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_package_expression_function_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Expression_Function_Tail");
      Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Compute", Package_Id);
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Left", Compute_Id);
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Right", Compute_Id);
      After_Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Compute", Package_Id);
      Done_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Done", Package_Id);
      After_Done_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Done", Package_Id);
      Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compute_Id);
      After_Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Compute_Id);
      Done_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Done_Id);
      After_Done_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Done_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Compute_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Compute_Info.Kind = Editor.Ada_Language_Model.Symbol_Function
              and then Compute_Info.Parent_Symbol = Package_Id
              and then To_String (Compute_Info.Target_Name) = "Integer",
              "compact expression function should be package-body local and retain return target");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Id /= Editor.Ada_Language_Model.No_Symbol,
              "expression-function profile parameters should remain callable-local");
      Assert (After_Compute_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Compute_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Compute_Info.Parent_Symbol = Package_Id
              and then After_Compute_Info.Declaration_Column > Compute_Info.Declaration_Column,
              "declarations after compact expression function semicolon should resume in package scope");
      Assert (Done_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Done_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Done_Info.Parent_Symbol = Package_Id,
              "compact null procedure should be parsed as package-local callable, not as an open body scope");
      Assert (After_Done_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Done_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Done_Info.Parent_Symbol = Package_Id
              and then After_Done_Info.Declaration_Column > Done_Info.Declaration_Column,
              "declarations after compact null procedure should resume in package scope");
   end Test_Language_Model_One_Line_Package_Expression_Function_Tail;



   procedure Test_Language_Model_Null_Subprogram_And_Expression_Function_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Reset is null;" & Character'Val (10) &
        "function Ready return Boolean is (True);" & Character'Val (10) &
        "function Plain return Boolean;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Null_Procedure : Boolean := False;
      Seen_Expression_Function : Boolean := False;
      Plain_Function_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "reset" and then S.Flags.Has_Null_Subprogram_Metadata then
               Seen_Null_Procedure := True;
            elsif N = "ready" and then S.Flags.Has_Expression_Function_Metadata then
               Seen_Expression_Function := True;
            elsif N = "plain"
              and then (S.Flags.Has_Null_Subprogram_Metadata
                        or else S.Flags.Has_Expression_Function_Metadata)
            then
               Plain_Function_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Null_Procedure, "null procedure metadata must be retained on the owning callable");
      Assert (Seen_Expression_Function, "expression function metadata must be retained on the owning callable");
      Assert (not Plain_Function_Marked, "ordinary specs must not be marked as null/expression bodies");
   end Test_Language_Model_Null_Subprogram_And_Expression_Function_Metadata;



   procedure Test_Language_Model_Access_Protected_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "type Protected_Action is access protected procedure (Item : Integer);" & Character'Val (10) &
        "type Protected_Query is access protected function return Boolean;" & Character'Val (10) &
        "type Plain_Action is access procedure (Item : Integer);" & Character'Val (10) &
        "Handler : access protected procedure;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Protected_Type : Boolean := False;
      Seen_Protected_Function : Boolean := False;
      Seen_Protected_Object : Boolean := False;
      Plain_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "protected_action" and then S.Flags.Has_Access_Protected_Metadata then
               Seen_Protected_Type := True;
            elsif N = "protected_query" and then S.Flags.Has_Access_Protected_Metadata then
               Seen_Protected_Function := True;
            elsif N = "handler" and then S.Flags.Has_Access_Protected_Metadata then
               Seen_Protected_Object := True;
            elsif N = "plain_action" and then S.Flags.Has_Access_Protected_Metadata then
               Plain_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Protected_Type, "access protected procedure metadata must be retained on access types");
      Assert (Seen_Protected_Function, "access protected function metadata must be retained on access types");
      Assert (Seen_Protected_Object, "anonymous access protected objects must retain metadata");
      Assert (not Plain_Marked, "plain access-to-subprogram types must not be marked access-protected");
   end Test_Language_Model_Access_Protected_Metadata;




   procedure Test_Language_Model_Syntax_Tree_Expression_And_Name_Nodes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Obj.Field := Arr (First .. Last) + T'Base'Pos (Value);" & ASCII.LF &
        "      Access_Obj.all := new Item'(Value => 1);" & ASCII.LF &
        "      if X in 1 .. 10 and then not Done then" & ASCII.LF &
        "         Flush (A, B);" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "      if (if Ready then Count + 1 else 0) > 0 then" & ASCII.LF &
        "         Ada.Text_IO.Put_Line (Name => Item);" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "      case (case Mode is when A => 1, when others => 0) is" & ASCII.LF &
        "         when others => Instruction'(Opcode => 16#90#);" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "      return (for all E of Items => Valid (E));" & ASCII.LF &
        "      return (Value);" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);
      Expression_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Selected_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Attribute_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Slice_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Function_Call_Node  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operator_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Qualified_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Conditional_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Case_Expression_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Quantified_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Range_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Membership_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Short_Circuit_Node  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unary_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parenthesized_Node  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dereference_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Allocator_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Association_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Named_Assoc_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Positional_Assoc_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            case Info.Kind is
               when Editor.Ada_Syntax_Tree.Node_Expression =>
                  Expression_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Name =>
                  Name_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Selected_Name =>
                  Selected_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Attribute_Reference =>
                  Attribute_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Slice =>
                  Slice_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Function_Call =>
                  Function_Call_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Operator_Expression =>
                  Operator_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Qualified_Expression =>
                  Qualified_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Conditional_Expression =>
                  Conditional_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Case_Expression =>
                  Case_Expression_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Quantified_Expression =>
                  Quantified_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Range_Expression =>
                  Range_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Membership_Expression =>
                  Membership_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression =>
                  Short_Circuit_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Unary_Expression =>
                  Unary_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Parenthesized_Expression =>
                  Parenthesized_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Explicit_Dereference =>
                  Dereference_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Allocator =>
                  Allocator_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Association =>
                  Association_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Named_Association =>
                  Named_Assoc_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Positional_Association =>
                  Positional_Assoc_Node := Info.Id;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Expression_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain expression nodes under statement/declaration nodes");
      Assert (Name_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain identifier name nodes from expressions");
      Assert (Selected_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain selected-name expression nodes");
      Assert (Attribute_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain attribute-reference expression nodes");
      Assert (Slice_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain slice expression nodes");
      Assert (Function_Call_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain function-call/name-call expression nodes");
      Assert (Operator_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain operator-expression nodes");
      Assert (Qualified_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain qualified-expression nodes");
      Assert (Conditional_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain conditional-expression nodes");
      Assert (Case_Expression_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain case-expression nodes");
      Assert (Quantified_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain quantified-expression nodes");
      Assert (Range_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain range-expression nodes");
      Assert (Membership_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain membership-expression nodes");
      Assert (Short_Circuit_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain short-circuit-expression nodes");
      Assert (Unary_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain unary-expression nodes");
      Assert (Parenthesized_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain parenthesized-expression nodes");
      Assert (Dereference_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain explicit-dereference name nodes");
      Assert (Allocator_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain allocator-expression nodes");
      Assert (Association_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain association nodes");
      Assert (Named_Assoc_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain named association nodes");
      Assert (Positional_Assoc_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain positional association nodes");
   end Test_Language_Model_Syntax_Tree_Expression_And_Name_Nodes;



   procedure Test_Language_Model_Syntax_Tree_Constants_And_Assignment_Are_Separated
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Deferred : constant Integer;" & ASCII.LF &
        "   Limit : constant Integer := 10;" & ASCII.LF &
        "   Named : constant := 16;" & ASCII.LF &
        "   Value : Integer := Limit;" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "end Demo;" & ASCII.LF &
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Value := Value + 1;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      function Count_Kind (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            if Editor.Ada_Syntax_Tree.Node_At (Tree, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Kind;

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Deferred_Constant_Declaration) = 1,
              "deferred constants must be first-class declaration nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Constant_Declaration) = 1,
              "typed constant declarations with defaults must not be assignment statements");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Number_Declaration) = 1,
              "named-number declarations must remain distinct from typed constants");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Assignment_Statement) = 1,
              "ordinary assignments must still be statement nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "deferred constant"),
              "deferred constants must retain declaration-mode metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "constant"),
              "typed constants must retain declaration-mode metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "named number"),
              "named numbers must retain declaration-mode metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Default, "10"),
              "typed constants must retain default expressions as declaration metadata");
   end Test_Language_Model_Syntax_Tree_Constants_And_Assignment_Are_Separated;





   procedure Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Ada2022_Expression_Node_Coverage is" & ASCII.LF &
        "   type Count is range 0 .. 100;" & ASCII.LF &
        "   type Count_Access is access Count;" & ASCII.LF &
        "   Values : Count_Access := new Count'(1);" & ASCII.LF &
        "   Updated : Count := (Base with delta Field => @ + 1);" & ASCII.LF &
        "   Built : Count := (for Item of Values => Item);" & ASCII.LF &
        "   Reduced : Count := Values'Reduce (""+"", 0);" & ASCII.LF &
        "   Parallel_Reduced : Count := Values'Parallel_Reduce (""+"", 0);" & ASCII.LF &
        "   Declared : Count := (declare Local : Count := 1; begin Local + 1);" & ASCII.LF &
        "end Ada2022_Expression_Node_Coverage;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);

      function Count_Kind (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            if Editor.Ada_Syntax_Tree.Node_At (Tree, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Kind;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Delta_Aggregate) >= 1,
              "Ada 2022 delta aggregates must have syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Target_Name) >= 1,
              "Ada 2022 target-name expressions must have syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Container_Aggregate) >= 1,
              "Ada 2022 container aggregate iterator syntax must have syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Iterator_Specification) >= 1,
              "container aggregate iterators must retain iterator-specification child nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Reduction_Expression) >= 2,
              "Ada 2022 reduction attributes must have syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Declare_Expression) >= 1,
              "Ada 2022 declare expressions must have syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Expression) >= 6,
              "new grammar nodes must remain anchored under expression nodes");
   end Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage;



   procedure Test_Ada_Expected_Type_Context_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
      use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   function Make (X : Integer) return Integer is (X);" & ASCII.LF &
        "   procedure Need_Int (Y : Integer) is null;" & ASCII.LF &
        "   procedure Need_Pair (X : Boolean; Y : Integer) is null;" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Child is new Root with null record;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   package Box is" & ASCII.LF &
        "   end Box;" & ASCII.LF &
        "   package Int_Box is new Box (Integer);" & ASCII.LF &
        "   Value : Integer := Make (1);" & ASCII.LF &
        "   function Back (X : Integer) return Integer is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Make (X);" & ASCII.LF &
        "   end Back;" & ASCII.LF &
        "   task Worker is" & ASCII.LF &
        "      entry Ping;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Ping;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   procedure Touch is" & ASCII.LF &
        "      Local : Integer := Make (2);" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Local := Make (3);" & ASCII.LF &
        "      Need_Int (Make (4));" & ASCII.LF &
        "      Need_Pair (False, Make (5));" & ASCII.LF &
        "      Need_Pair (X => False, Y => Make (6));" & ASCII.LF &
        "      Missing_Context;" & ASCII.LF &
        "   end Touch;" & ASCII.LF &
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
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Representation : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Generic_Base : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Static_And_Type_Graph
          (Tree, Regions, Visibility, Static, Types);
      Generic_Nested : constant
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build
          (Tree, Generic_Base);
      Generic_Object_Defaults : constant
        Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Generic_Base, Static, Types);
      Generic_Substitutions : constant
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Build (Generic_Nested);
      Exprs : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Expected_Contexts
          (Tree, Regions, Visibility, Types, Static, Resolutions, Expected);
      Empty_Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Generic_Views : constant
        Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model :=
        Editor.Ada_Generic_View_Compatibility.Build
          (Generic_Object_Defaults, Empty_Views);
      Generic_Bodies : constant
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Build
          (Generic_Base, Generic_Views);
      Assignment_Contexts : constant
        Editor.Ada_Assignment_Legality.Assignment_Context_Model :=
        Editor.Ada_Assignment_Legality.Build_Contexts_From_Expected_Types
          (Expected, Exprs);
      Assignment_Legality : constant
        Editor.Ada_Assignment_Legality.Assignment_Legality_Model :=
        Editor.Ada_Assignment_Legality.Build (Assignment_Contexts, Exprs);
      Return_Contexts : constant
        Editor.Ada_Return_Legality.Return_Context_Model :=
        Editor.Ada_Return_Legality.Build_Contexts_From_Expected_Types
          (Expected, Assignment_Legality);
      Return_Legality : constant
        Editor.Ada_Return_Legality.Return_Legality_Model :=
        Editor.Ada_Return_Legality.Build (Return_Contexts, Assignment_Legality);
      Flow_Contexts : constant
        Editor.Ada_Control_Flow_Legality.Flow_Context_Model :=
        Editor.Ada_Control_Flow_Legality.Build_Contexts_From_Returns
          (Return_Legality);
      Flow_Legality : constant
        Editor.Ada_Control_Flow_Legality.Flow_Legality_Model :=
        Editor.Ada_Control_Flow_Legality.Build
          (Flow_Contexts, Return_Legality);
      Tasking_Contexts : constant
        Editor.Ada_Tasking_Protected_Legality.Tasking_Context_Model :=
        Editor.Ada_Tasking_Protected_Legality.Build_Contexts_From_Syntax
          (Tree, Flow_Legality);
      Tasking_Legality : constant
        Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model :=
        Editor.Ada_Tasking_Protected_Legality.Build
          (Tasking_Contexts, Flow_Legality);
      Dispatching : constant
        Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model :=
        Editor.Ada_Dispatching_Call_Legality.Build (Exprs);
      Tagged_Contexts : constant
        Editor.Ada_Tagged_Derived_Legality.Tagged_Context_Model :=
        Editor.Ada_Tagged_Derived_Legality.Build_Contexts_From_Syntax
          (Tree, Dispatching);
      Tagged_Legality : constant
        Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model :=
        Editor.Ada_Tagged_Derived_Legality.Build
          (Tagged_Contexts, Assignment_Legality, Return_Legality, Dispatching);
      Conversion_Contexts : constant
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Context_Model :=
        Editor.Ada_Conversion_Access_Aggregate_Legality
          .Build_Contexts_From_Expression_Types (Exprs);
      Conversion_Legality : constant
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Build
          (Conversion_Contexts);
      Instance_Contexts : constant
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Context_Model :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Build_Contexts_From_Models
          (Generic_Base,
           Generic_Bodies,
           Generic_Substitutions,
           Freezing,
           Representation);
      Instance_Legality : constant
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Build
          (Instance_Contexts,
           Generic_Bodies,
           Generic_Substitutions,
           Freezing,
           Representation,
           Assignment_Legality,
           Return_Legality,
           Conversion_Legality,
           Tagged_Legality);
   begin
      Assert (Editor.Ada_Expected_Type_Contexts.Has_Expected_Contexts (Expected),
              "expected-type context model must annotate call-shaped syntax nodes");
      Assert (Editor.Ada_Expected_Type_Contexts.Count_Status
                (Expected,
                 Editor.Ada_Expected_Type_Contexts.Expected_Context_Found) >= 1,
              "expected-type context model must find object/default expected subtypes");
      Assert (Editor.Ada_Expected_Type_Contexts.Count_Kind
                (Expected,
                 Editor.Ada_Expected_Type_Contexts.Expected_Context_Object_Default) >= 1,
              "expected-type context model must classify object default contexts");
      Assert (Editor.Ada_Expected_Type_Contexts.Count_Kind
                (Expected,
                 Editor.Ada_Expected_Type_Contexts.Expected_Context_Assignment_Target) >= 1,
              "expected-type context model must classify assignment-target contexts");
      Assert (Editor.Ada_Expected_Type_Contexts.Count_Kind
                (Expected,
                 Editor.Ada_Expected_Type_Contexts.Expected_Context_Return_Statement) >= 1,
              "expected-type context model must classify return-statement contexts");
      Assert (Editor.Ada_Expected_Type_Contexts.Count_Kind
                (Expected,
                 Editor.Ada_Expected_Type_Contexts.Expected_Context_Parameter_Actual) >= 1,
              "expected-type context model must classify parameter-actual contexts");
      Assert (Editor.Ada_Expected_Type_Contexts.Count_Status
                (Expected,
                 Editor.Ada_Expected_Type_Contexts.Expected_Context_No_Context) >= 1,
              "expected-type context model must leave context-free calls untyped");
      Assert (Editor.Ada_Expected_Type_Contexts.Fingerprint (Expected) /= 0,
              "expected-type context model must keep deterministic fingerprints");
      Assert (Editor.Ada_Assignment_Legality.Context_Count (Assignment_Contexts) >= 1,
              "assignment legality adapter must consume expected assignment-target contexts");
      Assert (Editor.Ada_Assignment_Legality.Legality_Count (Assignment_Legality) >= 1,
              "assignment legality adapter must produce assignment legality rows");
      Assert (Editor.Ada_Assignment_Legality.Compatible_Count (Assignment_Legality) >= 1,
              "assignment legality adapter must accept compatible assignment target/source pairs");
      Assert (Editor.Ada_Assignment_Legality.Fingerprint (Assignment_Legality) /= 0,
              "assignment legality adapter must keep deterministic fingerprints");
      Assert (Editor.Ada_Return_Legality.Context_Count (Return_Contexts) >= 1,
              "return legality adapter must consume expected return-statement contexts");
      Assert (Editor.Ada_Return_Legality.Legality_Count (Return_Legality) >= 1,
              "return legality adapter must produce return legality rows");
      Assert (Editor.Ada_Return_Legality.Compatible_Count (Return_Legality) >= 1,
              "return legality adapter must accept compatible function returns");
      Assert (Editor.Ada_Return_Legality.Fingerprint (Return_Legality) /= 0,
              "return legality adapter must keep deterministic fingerprints");
      Assert (Editor.Ada_Control_Flow_Legality.Context_Count (Flow_Contexts) >= 1,
              "control-flow legality adapter must consume return legality rows");
      Assert (Editor.Ada_Control_Flow_Legality.Legality_Count (Flow_Legality) >= 1,
              "control-flow legality adapter must produce return-path flow rows");
      Assert (Editor.Ada_Control_Flow_Legality.Compatible_Count (Flow_Legality) >= 1,
              "control-flow legality adapter must accept compatible return paths");
      Assert (Editor.Ada_Control_Flow_Legality.Fingerprint (Flow_Legality) /= 0,
              "control-flow legality adapter must keep deterministic fingerprints");
      Assert (Editor.Ada_Tasking_Protected_Legality.Context_Count (Tasking_Contexts) >= 3,
              "tasking legality adapter must consume tasking syntax nodes");
      Assert (Editor.Ada_Tasking_Protected_Legality.Legality_Count (Tasking_Legality) >= 3,
              "tasking legality adapter must produce tasking legality rows");
      Assert (Editor.Ada_Tasking_Protected_Legality.Compatible_Count (Tasking_Legality) >= 1,
              "tasking legality adapter must accept conservative tasking contexts");
      Assert (Editor.Ada_Tasking_Protected_Legality.Fingerprint (Tasking_Legality) /= 0,
              "tasking legality adapter must keep deterministic fingerprints");
      Assert (Editor.Ada_Tagged_Derived_Legality.Context_Count (Tagged_Contexts) >= 2,
              "tagged legality adapter must consume tagged and derived syntax nodes");
      Assert (Editor.Ada_Tagged_Derived_Legality.Legality_Count (Tagged_Legality) >= 2,
              "tagged legality adapter must produce tagged legality rows");
      Assert (Editor.Ada_Tagged_Derived_Legality.Compatible_Count (Tagged_Legality) >= 1,
              "tagged legality adapter must accept conservative tagged contexts");
      Assert (Editor.Ada_Tagged_Derived_Legality.Fingerprint (Tagged_Legality) /= 0,
              "tagged legality adapter must keep deterministic fingerprints");
      Assert
        (Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Context_Count
           (Instance_Contexts) >= 1,
         "generic instance legality adapter must consume generic instance semantic models");
      Assert
        (Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Legality_Count
           (Instance_Legality) >= 1,
         "generic instance legality adapter must produce instance legality rows");
      Assert
        (Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Legal_Count
           (Instance_Legality) >= 1,
         "generic instance legality adapter must accept conservative instance contexts");
      Assert
        (Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Fingerprint
           (Instance_Legality) /= 0,
         "generic instance legality adapter must keep deterministic fingerprints");
   end Test_Ada_Expected_Type_Context_Foundation;


   overriding function Name (T : Expression_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Expression");
   end Name;

   overriding procedure Register_Tests (T : in out Expression_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Function_Return_Target_Metadata'Access, Name => "language model parser retains function return subtype target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Function_Return_Target_Metadata'Access, Name => "language model parser retains split function return subtype target metadata");
      Add_Test (Routine => Test_Language_Model_Task_And_Protected_Interface_Metadata'Access, Name => "language model parser keeps task/protected interface qualifiers as metadata");
      Add_Test (Routine => Test_Language_Model_Default_Expression_Metadata'Access, Name => "language model parser keeps default expressions as declaration metadata");
      Add_Test (Routine => Test_Language_Model_Task_And_Protected_Type_Metadata'Access, Name => "language model retains task and protected type metadata");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Protected_Tail'Access, Name => "language model parser keeps compact protected tails protected-scope local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Protected_Discriminant_Tail'Access, Name => "language model parser keeps compact protected discriminant tails protected-scope local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Protected_Body_Operation_Tail'Access, Name => "language model parser keeps compact protected-body operations protected-scope local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Protected_Body_Bare_Block_Tail'Access, Name => "language model parser keeps bare begin/end blocks inside compact protected body tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Selected_Protected_Tail'Access, Name => "language model parser matches selected compact protected-body ends exactly");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Expression_Function_Tail'Access, Name => "language model parser keeps compact expression functions from capturing package tails");
      Add_Test (Routine => Test_Language_Model_Null_Subprogram_And_Expression_Function_Metadata'Access, Name => "language model retains null subprogram and expression function metadata");
      Add_Test (Routine => Test_Language_Model_Access_Protected_Metadata'Access, Name => "language model retains access protected metadata");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Expression_And_Name_Nodes'Access, Name => "syntax tree retains expression and name nodes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Constants_And_Assignment_Are_Separated'Access, Name => "syntax tree separates deferred constants, constants, numbers, and assignments");
      Add_Test (Routine => Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage'Access, Name => "Ada syntax tree retains Ada 2022 expression grammar nodes for compiler-grade grammar foundation");
      Add_Test (Routine => Test_Ada_Expected_Type_Context_Foundation'Access, Name => "Ada expected-type context model annotates call expression contexts");
   end Register_Tests;

end Editor.Syntax_Semantics.Expression_Tests;
