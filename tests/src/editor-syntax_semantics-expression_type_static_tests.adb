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

package body Editor.Syntax_Semantics.Expression_Type_Static_Tests is





   procedure Test_Ada_Subtype_Compatibility_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
      use type Editor.Ada_Subtype_Compatibility.Numeric_Family;
      pragma Unreferenced (T);
      Exact : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
        Editor.Ada_Subtype_Compatibility.Check ("Integer", "integer");
      Universal_Int : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
        Editor.Ada_Subtype_Compatibility.Check ("Integer", "universal_integer");
      Universal_Real : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
        Editor.Ada_Subtype_Compatibility.Check ("Float", "universal_real");
      Universal_Int_To_Real : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
        Editor.Ada_Subtype_Compatibility.Check ("Float", "universal_integer");
      Known_Bad : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
        Editor.Ada_Subtype_Compatibility.Check ("Integer", "universal_real");
      Unknown : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
        Editor.Ada_Subtype_Compatibility.Check ("Client.Amount", "Other.Amount");
   begin
      Assert (Exact.Status = Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Exact_Match,
              "subtype compatibility must preserve exact normalized subtype matches");
      Assert (Universal_Int.Status =
                Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Integer_To_Integer,
              "subtype compatibility must accept universal_integer for integer families");
      Assert (Universal_Real.Status =
                Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Real_To_Real,
              "subtype compatibility must accept universal_real for real families");
      Assert (Universal_Int_To_Real.Status =
                Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Integer_To_Real,
              "subtype compatibility must accept universal_integer for real expected contexts");
      Assert (Known_Bad.Status =
                Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Known_Incompatible,
              "subtype compatibility must reject known numeric-family mismatches");
      Assert (Unknown.Status =
                Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Indeterminate,
              "subtype compatibility must leave unresolved user-defined relationships indeterminate");
      Assert (Editor.Ada_Subtype_Compatibility.Is_Compatible (Universal_Int),
              "universal integer compatibility must be reported as compatible");
      Assert (not Editor.Ada_Subtype_Compatibility.Is_Compatible (Known_Bad),
              "known incompatible numeric families must not be reported as compatible");
      Assert (Universal_Int.Expected_Family =
                Editor.Ada_Subtype_Compatibility.Numeric_Family_Discrete_Integer,
              "expected integer subtype must be classified as a discrete integer family");
      Assert (Universal_Int.Actual_Family =
                Editor.Ada_Subtype_Compatibility.Numeric_Family_Universal_Integer,
              "actual universal integer subtype must be classified separately");
      Assert (Exact.Fingerprint /= 0 and then Universal_Int.Fingerprint /= 0,
              "subtype compatibility entries must keep deterministic fingerprints");
   end Test_Ada_Subtype_Compatibility_Foundation;





   procedure Test_Ada_Type_Graph_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Type_Graph.Type_Category;
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_Relation_Status;
      use type Editor.Ada_Type_Graph.Compatibility_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Numeric_Model is" & ASCII.LF &
        "   type Amount is range 0 .. 100;" & ASCII.LF &
        "   type USD is new Amount;" & ASCII.LF &
        "   subtype Positive_USD is USD range 1 .. 100;" & ASCII.LF &
        "   type External is new Missing_Base;" & ASCII.LF &
        "end Numeric_Model;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);

      function Find_Type (Name : String) return Editor.Ada_Type_Graph.Type_Id is
      begin
         for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
            declare
               Info : constant Editor.Ada_Type_Graph.Type_Info :=
                 Editor.Ada_Type_Graph.Type_At (Types, Index);
            begin
               if To_String (Info.Normalized_Name) = Name then
                  return Info.Id;
               end if;
            end;
         end loop;
         return Editor.Ada_Type_Graph.No_Type;
      end Find_Type;

      Amount : constant Editor.Ada_Type_Graph.Type_Id := Find_Type ("amount");
      USD : constant Editor.Ada_Type_Graph.Type_Id := Find_Type ("usd");
      Positive_USD : constant Editor.Ada_Type_Graph.Type_Id := Find_Type ("positive_usd");
      External : constant Editor.Ada_Type_Graph.Type_Id := Find_Type ("external");
      Amount_Info : constant Editor.Ada_Type_Graph.Type_Info :=
        Editor.Ada_Type_Graph.Type_Node (Types, Amount);
      USD_Info : constant Editor.Ada_Type_Graph.Type_Info :=
        Editor.Ada_Type_Graph.Type_Node (Types, USD);
      Positive_Info : constant Editor.Ada_Type_Graph.Type_Info :=
        Editor.Ada_Type_Graph.Type_Node (Types, Positive_USD);
      External_Info : constant Editor.Ada_Type_Graph.Type_Info :=
        Editor.Ada_Type_Graph.Type_Node (Types, External);
   begin
      Assert (Editor.Ada_Type_Graph.Type_Count (Types) >= 4,
              "type graph must retain type and subtype declarations");
      Assert (Amount /= Editor.Ada_Type_Graph.No_Type
                and then USD /= Editor.Ada_Type_Graph.No_Type
                and then Positive_USD /= Editor.Ada_Type_Graph.No_Type,
              "type graph must allow deterministic lookup of declared type nodes");
      Assert (Amount_Info.Category = Editor.Ada_Type_Graph.Type_Category_Integer,
              "range type declarations must be classified as integer-family roots");
      Assert (USD_Info.Category = Editor.Ada_Type_Graph.Type_Category_Derived,
              "derived type declarations must be classified explicitly");
      Assert (USD_Info.Relation_Status = Editor.Ada_Type_Graph.Type_Relation_Base_Resolved
                and then USD_Info.Base_Type = Amount,
              "derived type declarations must resolve their parent type through direct visibility");
      Assert (Positive_Info.Category = Editor.Ada_Type_Graph.Type_Category_Subtype
                and then Positive_Info.Base_Type = USD,
              "subtype declarations must retain their constrained base subtype");
      Assert (External_Info.Relation_Status = Editor.Ada_Type_Graph.Type_Relation_Base_Unresolved,
              "unresolved derived type parents must be retained for diagnostics");
      Assert (Editor.Ada_Type_Graph.Compatibility (Types, Amount, USD) =
                Editor.Ada_Type_Graph.Type_Compatibility_Derived_From,
              "type graph compatibility must recognize declaration-derived ancestry");
      Assert (Editor.Ada_Type_Graph.Compatibility (Types, Amount, Positive_USD) =
                Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of,
              "type graph compatibility must recognize subtypes of derived descendants");
      Assert (Editor.Ada_Type_Graph.Fingerprint (Types) /= 0,
              "type graph must keep a deterministic semantic fingerprint");
   end Test_Ada_Type_Graph_Foundation;







   procedure Test_Ada_Type_Graph_Private_Classwide_Interface
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Type_Graph.Type_Category;
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_View_Status;
      use type Editor.Ada_Type_Graph.Compatibility_Status;
      use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
      use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Model is" & ASCII.LF &
        "   type Visible is tagged record null; end record;" & ASCII.LF &
        "   type Child is new Visible with null record;" & ASCII.LF &
        "   type Iface is interface;" & ASCII.LF &
        "   type Impl is new Iface with null record;" & ASCII.LF &
        "   function Make_Child return Child is (Child'(null record));" & ASCII.LF &
        "   A : Visible'Class := Make_Child;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Model;" & ASCII.LF &
        "package Private_Model is" & ASCII.LF &
        "   type Handle is private;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Handle is record null; end record;" & ASCII.LF &
        "end Private_Model;";
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
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Expected_Filters : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model :=
        Editor.Ada_Expected_Call_Filters.Build_With_Type_Graph
          (Expected, Resolutions, Filters, Shapes, Types);
      Seen_Interface : Boolean := False;
      Seen_Private_Partial : Boolean := False;
      Seen_Private_Full : Boolean := False;
      Seen_Classwide_Filter : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if To_String (Info.Normalized_Name) = "iface"
              and then Info.Category = Editor.Ada_Type_Graph.Type_Category_Interface
            then
               Seen_Interface := True;
            end if;
            if To_String (Info.Normalized_Name) = "handle"
              and then Info.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Partial
              and then Info.Full_View /= Editor.Ada_Type_Graph.No_Type
            then
               Seen_Private_Partial := True;
            elsif To_String (Info.Normalized_Name) = "handle"
              and then Info.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Full
              and then Info.Partial_View /= Editor.Ada_Type_Graph.No_Type
            then
               Seen_Private_Full := True;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Expected_Filters) loop
         declare
            Info : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info :=
              Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At (Expected_Filters, Index);
         begin
            if Info.Status = Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Result_Subtype_Compatible
              and then Info.Type_Compatibility = Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide
              and then Info.Compatibility = Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Class_Wide
            then
               Seen_Classwide_Filter := True;
            end if;
         end;
      end loop;

      Assert (Seen_Interface,
              "type graph must classify interface type declarations explicitly");
      Assert (Seen_Private_Partial and then Seen_Private_Full,
              "type graph must link private partial and full views in one declarative region");
      Assert (Seen_Classwide_Filter,
              "expected-call filtering must accept derived results for class-wide expected contexts");
      Assert (Editor.Ada_Type_Graph.Fingerprint (Types) /= 0,
              "private/class-wide/interface type graph pass must preserve deterministic fingerprints");
   end Test_Ada_Type_Graph_Private_Classwide_Interface;





   procedure Test_Ada_Private_View_Subtype_Compatibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_View_Status;
      use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Secret_Box is" & ASCII.LF &
        "   type Handle is private;" & ASCII.LF &
        "   function Make return Handle;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Handle is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Secret_Box;" & ASCII.LF &
        "package body Secret_Box is" & ASCII.LF &
        "   function Make return Handle is (Handle'(Value => 1));" & ASCII.LF &
        "end Secret_Box;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Partial : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Full : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Package_Spec : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Package_Body : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
   begin
      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if To_String (Info.Normalized_Name) = "handle" then
               if Info.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Partial then
                  Partial := Info.Id;
                  Full := Info.Full_View;
                  Package_Spec := Info.Region;
               elsif Info.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Full then
                  Full := Info.Id;
               end if;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
         begin
            if Info.Kind = Editor.Ada_Declarative_Regions.Region_Package_Body
              and then To_String (Info.Label) = "Secret_Box"
            then
               Package_Body := Info.Id;
            end if;
         end;
      end loop;

      Assert (Partial /= Editor.Ada_Type_Graph.No_Type and then Full /= Editor.Ada_Type_Graph.No_Type,
              "private-view subtype compatibility test must find both private views");

      Assert
        (Editor.Ada_Private_View_Visibility.Effective_Type_At_Line
           (Private_Views, Regions, Full, Package_Spec, 2) = Partial,
         "visible-part contexts must collapse an otherwise full private view to the partial view");
      Assert
        (Editor.Ada_Private_View_Visibility.Effective_Type_At_Line
           (Private_Views, Regions, Partial, Package_Body, 10) = Full,
         "package-body contexts must expose the effective full private view");

      declare
         Visible_Info : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
           Editor.Ada_Subtype_Compatibility.Check_With_Private_View
             (Types, Private_Views, Regions, Package_Spec, Package_Spec,
              Package_Spec, 2, "Handle", "Handle");
         Body_Info : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
           Editor.Ada_Subtype_Compatibility.Check_With_Private_View
             (Types, Private_Views, Regions, Package_Spec, Package_Spec,
              Package_Body, 10, "Handle", "Handle");
      begin
         Assert (Visible_Info.Status =
                 Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Partial_View,
                 "visible-part subtype compatibility must record partial private-view compatibility");
         Assert (Body_Info.Status =
                 Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Full_View,
                 "package-body subtype compatibility must record full private-view compatibility");
         Assert (Editor.Ada_Subtype_Compatibility.Is_Compatible (Visible_Info),
                 "partial private-view compatibility must be accepted as compatible");
         Assert (Editor.Ada_Subtype_Compatibility.Is_Compatible (Body_Info),
                 "full private-view compatibility must be accepted as compatible");
         Assert (Visible_Info.Fingerprint /= Body_Info.Fingerprint,
                 "private-view subtype compatibility must include context in deterministic fingerprints");
      end;
   end Test_Ada_Private_View_Subtype_Compatibility;






   procedure Test_Ada_Implicit_Conversion_Filter_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Status;
      use type Editor.Ada_Implicit_Conversions.Implicit_Conversion_Status;
      use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   type Amount is range 0 .. 100;" & ASCII.LF &
        "   type USD is new Amount;" & ASCII.LF &
        "   subtype Positive_USD is USD range 1 .. 100;" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Child is new Root with null record;" & ASCII.LF &
        "   function Make_USD (X : Integer) return USD is (USD (X));" & ASCII.LF &
        "   function Make_Positive (X : Integer) return Positive_USD is (Positive_USD (X));" & ASCII.LF &
        "   function Make_Child return Child is (Child'(null record));" & ASCII.LF &
        "   A : Amount := Make_USD (1);" & ASCII.LF &
        "   B : USD := Make_Positive (1);" & ASCII.LF &
        "   C : Root'Class := Make_Child;" & ASCII.LF &
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
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Expected_Filters : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Model :=
        Editor.Ada_Expected_Call_Filters.Build_With_Type_Graph
          (Expected, Resolutions, Filters, Shapes, Types);
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
      Expressions : constant Editor.Ada_Expression_Types.Expression_Type_Model :=
        Editor.Ada_Expression_Types.Build_With_Operator_Uses_And_Expected
          (Tree, Regions, Visibility, Types, Static, Resolutions,
           Primitive_Uses, Expected);
      Overload_Causes : constant
        Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model :=
        Editor.Ada_Overload_Ambiguity_Diagnostics.Build (Expressions);
      Overload_Rankings : constant
        Editor.Ada_Overload_Ranking.Overload_Ranking_Model :=
        Editor.Ada_Overload_Ranking.Build (Expressions, Overload_Causes);
      Views : constant
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model :=
        Editor.Ada_View_Aware_Compatibility.Build (Expressions);
      Dispatching : constant
        Editor.Ada_Dispatching_Call_Legality.Dispatching_Legality_Model :=
        Editor.Ada_Dispatching_Call_Legality.Build (Expressions);
      Expression_Diags : constant
        Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model :=
        Editor.Ada_Expression_Diagnostics
          .Build_With_All_Semantic_Causes_Ranking_And_Overload_Legality
            (Expressions,
             Overload_Causes,
             Views,
             Dispatching,
             Overload_Rankings,
             Overload_Legality);
      Seen_Derived_Requires_Explicit : Boolean := False;
      Seen_Subtype_Same_Type : Boolean := False;
      Seen_Classwide_Allowed : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Count (Expected_Filters) loop
         declare
            Info : constant Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_Info :=
              Editor.Ada_Expected_Call_Filters.Expected_Call_Filter_At (Expected_Filters, Index);
         begin
            if Info.Compatibility =
              Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Derived_From
              and then Info.Implicit_Conversion =
                Editor.Ada_Implicit_Conversions.Implicit_Conversion_No_Derived_Type_Conversion
              and then Info.Status =
                Editor.Ada_Expected_Call_Filters
                  .Expected_Call_Filter_Result_Subtype_Requires_Explicit_Conversion
            then
               Seen_Derived_Requires_Explicit := True;
            elsif Info.Compatibility =
              Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Subtype_Of
              and then Info.Implicit_Conversion =
                Editor.Ada_Implicit_Conversions.Implicit_Conversion_Same_Type
            then
               Seen_Subtype_Same_Type := True;
            elsif Info.Compatibility =
              Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Class_Wide
              and then Info.Implicit_Conversion =
                Editor.Ada_Implicit_Conversions.Implicit_Conversion_Class_Wide
            then
               Seen_Classwide_Allowed := True;
            end if;
         end;
      end loop;

      Assert (Seen_Derived_Requires_Explicit,
              "implicit conversion metadata must distinguish derived-type ancestry from implicit assignment compatibility");
      Assert (Seen_Subtype_Same_Type,
              "implicit conversion metadata must keep subtype results assignment-compatible with their base type");
      Assert (Seen_Classwide_Allowed,
              "implicit conversion metadata must allow class-wide expected contexts for descendants");
      Assert (Editor.Ada_Overload_Resolution_Legality.Count_Status
                (Overload_Legality,
                 Editor.Ada_Overload_Resolution_Legality
                   .Overload_Legality_Legal_Expected_Type_Preferred) = 2,
              "only subtype and class-wide implicit conversions should select overloads");
      Assert (Editor.Ada_Overload_Resolution_Legality.Count_Status
                (Overload_Legality,
                 Editor.Ada_Overload_Resolution_Legality
                   .Overload_Legality_Actual_Type_Mismatch) = 1,
              "derived-type ancestry must remain an explicit-conversion mismatch for overload legality");
      Assert (Editor.Ada_Expression_Diagnostics.Overload_Legality_Diagnostic_Count
                (Expression_Diags) >= 1,
              "expression diagnostics must project overload legality rows into IDE diagnostics");
      Assert (Editor.Ada_Expression_Diagnostics.Overload_Legality_Error_Count
                (Expression_Diags) >= 1,
              "expression diagnostics must preserve overload legality errors");
      Assert (Editor.Ada_Expected_Call_Filters.Fingerprint (Expected_Filters) /= 0,
              "implicit-conversion-aware expected-call filters must keep deterministic fingerprints");
   end Test_Ada_Implicit_Conversion_Filter_Foundation;



   procedure Test_Ada_Static_Expression_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Static_Client is" & ASCII.LF &
        "   Limit : constant := 10;" & ASCII.LF &
        "   Scale : constant Integer := Limit * 2 + 5;" & ASCII.LF &
        "   Offset : constant Integer := (Scale - Limit) / 3;" & ASCII.LF &
        "   Broken : constant Integer := Missing + 1;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Static_Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Statics : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Seen_Limit : Boolean := False;
      Seen_Scale : Boolean := False;
      Seen_Offset : Boolean := False;
      Seen_Broken_Unresolved : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Binding_Count (Statics) loop
         declare
            Info : constant Editor.Ada_Static_Expressions.Static_Binding_Info :=
              Editor.Ada_Static_Expressions.Static_Binding_At (Statics, Index);
            Name : constant String := To_String (Info.Normalized_Name);
         begin
            if Name = "limit" then
               Seen_Limit := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 10;
            elsif Name = "scale" then
               Seen_Scale := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 25;
            elsif Name = "offset" then
               Seen_Offset := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 5;
            elsif Name = "broken" then
               Seen_Broken_Unresolved :=
                 Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name;
            end if;
         end;
      end loop;

      Assert (Seen_Limit,
              "static expression model must evaluate named-number integer literals");
      Assert (Seen_Scale,
              "static expression model must evaluate constants referencing named numbers");
      Assert (Seen_Offset,
              "static expression model must evaluate parenthesized integer arithmetic");
      Assert (Seen_Broken_Unresolved,
              "static expression model must retain unresolved named static references for diagnostics");
      Assert (Editor.Ada_Static_Expressions.Fingerprint (Statics) /= 0,
              "static expression model must retain deterministic fingerprints");
   end Test_Ada_Static_Expression_Foundation;






   procedure Test_Ada_Static_Attribute_Expression_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Static_Attribute_Client is" & ASCII.LF &
        "   Low  : constant := 2;" & ASCII.LF &
        "   High : constant := 9;" & ASCII.LF &
        "   subtype Small is Integer range Low .. High;" & ASCII.LF &
        "   First_Value : constant Integer := Small'First;" & ASCII.LF &
        "   Last_Value  : constant Integer := Small'Last;" & ASCII.LF &
        "   Span        : constant Integer := Small'Last - Small'First;" & ASCII.LF &
        "   Position    : constant Integer := Integer'Pos (5);" & ASCII.LF &
        "   Unsupported : constant Integer := Small'Image (5);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Static_Attribute_Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Statics : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Seen_Bounds : Boolean := False;
      Seen_First : Boolean := False;
      Seen_Last : Boolean := False;
      Seen_Span : Boolean := False;
      Seen_Pos : Boolean := False;
      Seen_Unsupported : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Type_Bound_Count (Statics) loop
         declare
            Bound : constant Editor.Ada_Static_Expressions.Static_Type_Bound_Info :=
              Editor.Ada_Static_Expressions.Static_Type_Bound_At (Statics, Index);
         begin
            if To_String (Bound.Normalized_Name) = "small" then
               Seen_Bounds :=
                 Bound.First_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Bound.First_Value.Integer_Value = 2
                 and then Bound.Last_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Bound.Last_Value.Integer_Value = 9;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Binding_Count (Statics) loop
         declare
            Info : constant Editor.Ada_Static_Expressions.Static_Binding_Info :=
              Editor.Ada_Static_Expressions.Static_Binding_At (Statics, Index);
            Name : constant String := To_String (Info.Normalized_Name);
         begin
            if Name = "first_value" then
               Seen_First := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 2
                 and then To_String (Info.Value.Attribute_Name) = "first";
            elsif Name = "last_value" then
               Seen_Last := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 9
                 and then To_String (Info.Value.Attribute_Name) = "last";
            elsif Name = "span" then
               Seen_Span := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 7;
            elsif Name = "position" then
               Seen_Pos := Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 5
                 and then To_String (Info.Value.Attribute_Name) = "pos";
            elsif Name = "unsupported" then
               Seen_Unsupported :=
                 Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unsupported_Attribute
                 and then To_String (Info.Value.Attribute_Name) = "image";
            end if;
         end;
      end loop;

      Assert (Seen_Bounds,
              "static model must stage scalar subtype bounds from static range constraints");
      Assert (Seen_First,
              "static evaluator must resolve scalar subtype First attributes");
      Assert (Seen_Last,
              "static evaluator must resolve scalar subtype Last attributes");
      Assert (Seen_Span,
              "static evaluator must use static attributes inside arithmetic expressions");
      Assert (Seen_Pos,
              "static evaluator must stage static Pos attribute calls");
      Assert (Seen_Unsupported,
              "static evaluator must retain unsupported attributes without treating them as unresolved names");
      Assert (Editor.Ada_Static_Expressions.Fingerprint (Statics) /= 0,
              "static attribute model must retain deterministic fingerprints");
   end Test_Ada_Static_Attribute_Expression_Foundation;


   overriding function Name (T : Expression_Type_Static_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Expression.Type_Static");
   end Name;

   overriding procedure Register_Tests (T : in out Expression_Type_Static_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Subtype_Compatibility_Foundation'Access, Name => "Ada subtype compatibility classifies universal numeric expected-type cases");
      Add_Test (Routine => Test_Ada_Type_Graph_Foundation'Access, Name => "Ada type graph resolves declaration-derived subtype ancestry");
      Add_Test (Routine => Test_Ada_Type_Graph_Private_Classwide_Interface'Access, Name => "Ada type graph links private views and supports class-wide/interface compatibility");
      Add_Test (Routine => Test_Ada_Private_View_Subtype_Compatibility'Access, Name => "Ada subtype compatibility applies private-view visibility context");
      Add_Test (Routine => Test_Ada_Implicit_Conversion_Filter_Foundation'Access, Name => "Ada expected-call filters classify implicit conversion legality after type compatibility");
      Add_Test (Routine => Test_Ada_Static_Expression_Foundation'Access, Name => "Ada static expressions evaluate named numbers and integer constants");
      Add_Test (Routine => Test_Ada_Static_Attribute_Expression_Foundation'Access, Name => "Ada static expressions evaluate subtype attributes and static Pos/Val forms");
   end Register_Tests;

end Editor.Syntax_Semantics.Expression_Type_Static_Tests;
