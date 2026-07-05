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

package body Editor.Syntax_Semantics.Generic_Contract_Tests is





   procedure Test_Language_Model_Generic_Formal_Type_Discriminants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element (Size : Natural; Flag : Boolean) is private;" & ASCII.LF &
        "   type Node" & ASCII.LF &
        "     (Index : Positive)" & ASCII.LF &
        "   is private;" & ASCII.LF &
        "package Formal_Discriminants is" & ASCII.LF &
        "end Formal_Discriminants;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "formal_discriminants.ads");
      Element_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element");
      Size_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Size", Element_Id);
      Flag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Flag", Element_Id);
      Node_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Node");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Index", Node_Id);
      Element_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Id);
      Size_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Size_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
   begin
      Assert (Element_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "formal discriminated type should keep generic formal type kind");
      Assert (Element_Info.Flags.Is_Generic,
              "formal discriminated type should retain generic metadata");
      Assert (Size_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Flag_Id /= Editor.Ada_Language_Model.No_Symbol,
              "same-line generic formal discriminants should be parsed");
      Assert (Size_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Size_Info.Parent_Symbol = Element_Id,
              "same-line formal discriminants should be parented to the formal type");
      Assert (Node_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal type discriminants should be parsed");
      Assert (Index_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Index_Info.Parent_Symbol = Node_Id,
              "split formal discriminants should be parented to the pending formal type");
   end Test_Language_Model_Generic_Formal_Type_Discriminants;





   procedure Test_Language_Model_Generic_Formal_Derived_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Root is tagged private;" & ASCII.LF &
        "   type Child is new Root with private;" & ASCII.LF &
        "   type Plain is private;" & ASCII.LF &
        "package Formal_Derived is" & ASCII.LF &
        "end Formal_Derived;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "formal_derived.ads");
      Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Root_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
   begin
      Assert (Root_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "generic formal derived declarations should remain formal type symbols");
      Assert (Child_Info.Flags.Is_Generic
              and then Child_Info.Flags.Is_Private
              and then not Child_Info.Flags.Is_Instantiation,
              "generic formal derived types should keep generic/private metadata without instantiation flags");
      Assert (To_String (Child_Info.Target_Name) = "Root",
              "generic formal derived type should retain parent subtype target metadata");
      Assert (To_String (Plain_Info.Target_Name) = "",
              "ordinary formal private types should not invent target metadata");
   end Test_Language_Model_Generic_Formal_Derived_Type_Target_Metadata;



   procedure Test_Language_Model_Generic_Formal_Composite_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   type Element_Array is array (Positive range <>) of Element;" & ASCII.LF &
        "   type Element_Ref is access all Element;" & ASCII.LF &
        "   type Callback is access procedure (Item : Element);" & ASCII.LF &
        "   type Child_Interface is interface and Root_Interface;" & ASCII.LF &
        "package Formal_Composite is" & ASCII.LF &
        "end Formal_Composite;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "formal_composite.ads");
      Array_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element_Array");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element_Ref");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback");
      Interface_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child_Interface");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Item", Callback_Id);
      Array_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Array_Id);
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Interface_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Interface_Id);
   begin
      Assert (Array_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Ref_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "generic formal composite declarations should remain formal type symbols");
      Assert (Array_Info.Flags.Is_Generic and then Ref_Info.Flags.Is_Generic
              and then Interface_Info.Flags.Is_Generic,
              "generic formal composite types should retain generic metadata");
      Assert (To_String (Array_Info.Target_Name) = "Element",
              "generic formal array type should retain element subtype target metadata");
      Assert (To_String (Ref_Info.Target_Name) = "Element",
              "generic formal access type should retain designated subtype target metadata");
      Assert (To_String (Callback_Info.Target_Name) = "",
              "generic formal access-to-subprogram type should not invent procedure/function target metadata");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol,
              "generic formal access-to-subprogram profile names should not become child symbols");
      Assert (To_String (Interface_Info.Target_Name) = "Root_Interface",
              "generic formal interface extension should retain parent interface target metadata");
   end Test_Language_Model_Generic_Formal_Composite_Target_Metadata;



   procedure Test_Language_Model_Generic_Formal_Type_Detail_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   type Choice is (<>);" & ASCII.LF &
        "   type Count is range <>;" & ASCII.LF &
        "   type Mask is mod <>;" & ASCII.LF &
        "   type Real is digits <>;" & ASCII.LF &
        "   type Ord_Fixed is delta <>;" & ASCII.LF &
        "   type Dec_Fixed is delta <> digits <>;" & ASCII.LF &
        "   type Table is array (Positive range <>) of Element;" & ASCII.LF &
        "   type Ref is access all Element;" & ASCII.LF &
        "   type Callback is access protected procedure (Item : Element);" & ASCII.LF &
        "   type View is limited interface and Root_Interface;" & ASCII.LF &
        "package Formal_Type_Details is" & ASCII.LF &
        "end Formal_Type_Details;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "formal_type_details.ads");

      function Info_For
        (Name : String) return Editor.Ada_Language_Model.Generic_Formal_Type_Info
      is
         Id : constant Editor.Ada_Language_Model.Symbol_Id :=
           Editor.Ada_Symbol_Resolver.First_Match (Analysis, Name);
      begin
         return Editor.Ada_Language_Model.Generic_Formal_Type_Metadata_At
           (Analysis, Id, 1);
      end Info_For;

      Element_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Element");
      Choice_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Choice");
      Count_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Count");
      Mask_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Mask");
      Real_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Real");
      Ord_Fixed_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Ord_Fixed");
      Dec_Fixed_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Dec_Fixed");
      Table_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Table");
      Ref_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Ref");
      Callback_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("Callback");
      View_Info : constant Editor.Ada_Language_Model.Generic_Formal_Type_Info :=
        Info_For ("View");
   begin
      Assert (Editor.Ada_Language_Model.Generic_Formal_Type_Metadata_Count
                (Analysis) = 11,
              "formal type detail metadata should project one row per formal type");
      Assert (Element_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Private
              and then Element_Info.Has_Private,
              "formal private type should retain private-family metadata");
      Assert (Choice_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Discrete
              and then Choice_Info.Has_Box,
              "formal discrete type should retain box metadata");
      Assert (Count_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Signed_Integer
              and then Mask_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Modular_Integer,
              "formal integer type families should be distinguished");
      Assert (Real_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Floating_Point
              and then Ord_Fixed_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Ordinary_Fixed_Point
              and then Dec_Fixed_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Decimal_Fixed_Point,
              "formal real/fixed type families should be distinguished");
      Assert (Table_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Array
              and then To_String (Table_Info.Target_Type_Text) = "Element",
              "formal array type should retain element subtype metadata");
      Assert (Ref_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Access_Object
              and then To_String (Ref_Info.Target_Type_Text) = "Element",
              "formal access-object type should retain designated subtype metadata");
      Assert (Callback_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Access_Subprogram
              and then To_String (Callback_Info.Profile_Text) /= "",
              "formal access-to-subprogram type should retain profile metadata");
      Assert (View_Info.Family =
                Editor.Ada_Language_Model.Generic_Formal_Type_Interface
              and then View_Info.Has_Limited
              and then View_Info.Has_Interface
              and then To_String (View_Info.Target_Type_Text) = "Root_Interface",
              "formal interface type should retain qualifier and parent metadata");
   end Test_Language_Model_Generic_Formal_Type_Detail_Metadata;




   procedure Test_Language_Model_Split_Generic_Formal_Object_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with Default : in" & ASCII.LF &
        "      Root'Class;" & ASCII.LF &
        "   with Shared : in out" & ASCII.LF &
        "      Element;" & ASCII.LF &
        "package Split_Formal_Objects is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Element is tagged null record;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Formal_Objects;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "split_formal_objects.ads");
      Default_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Default");
      Shared_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Shared");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Default_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Default_Id);
      Shared_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Shared_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Default_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal object should be parsed from the formal header");
      Assert (Default_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Default_Info.Flags.Is_Generic
              and then To_String (Default_Info.Target_Name) = "Root'Class",
              "split formal object should retain generic kind/flag and class-wide target metadata");
      Assert (Shared_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split in out generic formal object should be parsed");
      Assert (Shared_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Shared_Info.Flags.Is_Generic
              and then To_String (Shared_Info.Target_Name) = "Element",
              "split formal object target metadata should skip mode keywords");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "formal-object continuation lines must not corrupt later ordinary declarations");
   end Test_Language_Model_Split_Generic_Formal_Object_Target_Metadata;




   procedure Test_Project_Index_Generic_Package_Spec_Body_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "package G is" & ASCII.LF &
           "end G;" & ASCII.LF,
           "g.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package body G is" & ASCII.LF &
           "end G;" & ASCII.LF,
           "g.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Res   : Editor.Ada_Project_Index.Index_Resolution_Result;
      Saw_Generic_Spec : Boolean := False;
      Saw_Body         : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/g.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/g.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);

      Res := Editor.Ada_Project_Index.Resolve (Index, "G");
      if not Res.Matches.Is_Empty then
         for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
            if Res.Matches (I).Symbol.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package then
               Saw_Generic_Spec := True;
            elsif Res.Matches (I).Symbol.Kind = Editor.Ada_Language_Model.Symbol_Package_Body then
               Saw_Body := True;
            end if;
         end loop;
      end if;

      Assert (Saw_Generic_Spec,
              "project index should retain generic package spec targets for goto-spec");
      Assert (Saw_Body,
              "project index should retain package body targets for goto-body");
   end Test_Project_Index_Generic_Package_Spec_Body_Targets;




   procedure Test_Project_Index_Generic_Subprogram_Spec_Body_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Spec_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "procedure Visit (Item : Element);" & ASCII.LF,
           "visit.ads");
      Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "procedure Visit (Item : Element) is" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end Visit;" & ASCII.LF,
           "visit.adb");
      Index : Editor.Ada_Project_Index.Index_State;
      Res   : Editor.Ada_Project_Index.Index_Resolution_Result;
      Saw_Generic_Spec : Boolean := False;
      Saw_Generic_Body : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/visit.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Spec_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/visit.adb", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Body_Analysis);

      Res := Editor.Ada_Project_Index.Resolve (Index, "Visit");
      if not Res.Matches.Is_Empty then
         for I in Res.Matches.First_Index .. Res.Matches.Last_Index loop
            if Res.Matches (I).Symbol.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram then
               if Res.Matches (I).Symbol.Flags.Is_Body then
                  Saw_Generic_Body := True;
               else
                  Saw_Generic_Spec := True;
               end if;
            end if;
         end loop;
      end if;

      Assert (Saw_Generic_Spec,
              "project index should retain generic subprogram spec targets for goto-spec");
      Assert (Saw_Generic_Body,
              "project index should retain generic subprogram body targets for goto-body");
   end Test_Project_Index_Generic_Subprogram_Spec_Body_Targets;




   procedure Test_Language_Model_Generic_Formal_Object_And_Profiles
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   Capacity : Positive := 16;" & ASCII.LF &
        "   with procedure Visit (Item : in out Element);" & ASCII.LF &
        "package Containers is" & ASCII.LF &
        "   procedure Append (Item : Element);" & ASCII.LF &
        "   function ""+"" (Left, Right : Element) return Element;" & ASCII.LF &
        "end Containers;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "containers.ads");
      Capacity_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Capacity");
      Visit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Visit");
      Append_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Append");
      Plus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """+""");
      Capacity_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Capacity_Id);
      Visit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Visit_Id);
      Append_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Append_Id);
      Plus_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plus_Id);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Assert (Capacity_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "generic formal object declarations should be modeled directly");
      Assert (Capacity_Info.Flags.Is_Generic,
              "generic formal objects should carry generic metadata");
      Assert (Visit_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram,
              "generic formal subprogram declarations should remain modeled as formals");
      Assert (To_String (Visit_Info.Profile_Summary) = "(Item : in out Element)",
              "generic formal subprogram profile summaries should be retained");
      Assert (To_String (Append_Info.Profile_Summary) = "(Item : Element)",
              "ordinary subprogram profile summaries should be retained");
      Assert (To_String (Plus_Info.Profile_Summary) = "(Left, Right : Element) return Element",
              "operator function profile summaries should be retained without flattening the operator name");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Capacity") =
              Editor.Syntax.Generic_Formal,
              "semantic colouring should classify generic formal objects from analysis data");
   end Test_Language_Model_Generic_Formal_Object_And_Profiles;





   procedure Test_Language_Model_Multiple_Generic_Formal_Objects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   First, Second : Positive;" & ASCII.LF &
        "   with Left, Right : Natural;" & ASCII.LF &
        "package Multiple_Formals is" & ASCII.LF &
        "end Multiple_Formals;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "multiple_formals.ads");
      First_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "First");
      Second_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Second");
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Left");
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right");
      First_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, First_Id);
      Second_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Second_Id);
      Left_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Left_Id);
      Right_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Right_Id);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Assert (First_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "first object in a multi-name generic formal declaration should be modeled");
      Assert (Second_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "second object in a multi-name generic formal declaration should be modeled");
      Assert (Left_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "first object after 'with' should be modeled as a generic formal object");
      Assert (Right_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "second object after 'with' should be modeled as a generic formal object");
      Assert (First_Info.Flags.Is_Generic and then Second_Info.Flags.Is_Generic
              and then Left_Info.Flags.Is_Generic and then Right_Info.Flags.Is_Generic,
              "all multi-name generic formal objects should carry generic metadata");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Second") =
              Editor.Syntax.Generic_Formal,
              "semantic map should classify non-leading generic formal object names");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Right") =
              Editor.Syntax.Generic_Formal,
              "semantic map should classify non-leading 'with' generic formal object names");
   end Test_Language_Model_Multiple_Generic_Formal_Objects;




   procedure Test_Language_Model_Generic_Formal_Access_Subprogram_Object_Profile_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with Handler : access procedure (Item : Element);" & ASCII.LF &
        "   with Predicate : constant access" & ASCII.LF &
        "      protected function (Value : Element) return Boolean;" & ASCII.LF &
        "package Formal_Callbacks is" & ASCII.LF &
        "   type Element is tagged null record;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Formal_Callbacks;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "formal_callbacks.ads");
      Handler_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Handler");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Handler_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Handler_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Handler_Id /= Editor.Ada_Language_Model.No_Symbol,
              "same-line generic formal access-to-subprogram object should be parsed");
      Assert (Handler_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Handler_Info.Flags.Is_Generic
              and then To_String (Handler_Info.Target_Name) = ""
              and then To_String (Handler_Info.Profile_Summary) =
                "procedure (Item : Element)",
              "generic formal access-to-subprogram object should retain generic kind and procedure profile metadata");

      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal access-to-subprogram object should be parsed");
      Assert (Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Predicate_Info.Flags.Is_Generic
              and then To_String (Predicate_Info.Target_Name) = ""
              and then To_String (Predicate_Info.Profile_Summary) =
                "protected function (Value : Element) return Boolean",
              "split generic formal access-to-subprogram object should retain protected function profile metadata");

      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "generic formal access-to-subprogram profile parameters must remain metadata-only");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "continuation profile lines must not corrupt later ordinary declarations");
   end Test_Language_Model_Generic_Formal_Access_Subprogram_Object_Profile_Metadata;




   procedure Test_Language_Model_Generic_Formal_Object_Group_Profile_Semicolons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Formal_Object_Group_Profile_Semicolons is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Formal_Filter : access function (Left : Integer; Right : Integer) return Boolean; Formal_Callback : access procedure (A : Integer; B : Integer); Formal_Next : in Integer;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "end Generic_Formal_Object_Group_Profile_Semicolons;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_formal_object_group_profile_semicolons.ads");
      Formal_Filter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Filter");
      Formal_Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Callback");
      Formal_Next_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Next");
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right");
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "B");
      Formal_Filter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Filter_Id);
      Formal_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Callback_Id);
      Formal_Next_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Next_Id);
   begin
      Assert (Formal_Filter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Filter_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "formal access-to-function object should remain one generic formal object");
      Assert (Formal_Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Formal_Callback_Info.Declaration_Column > Formal_Filter_Info.Declaration_Column,
              "top-level semicolon after formal function profile should split callback formal");
      Assert (Formal_Next_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Next_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Formal_Next_Info.Declaration_Column > Formal_Callback_Info.Declaration_Column,
              "top-level semicolon after formal procedure profile should split next formal");
      Assert (Right_Id = Editor.Ada_Language_Model.No_Symbol
              and then B_Id = Editor.Ada_Language_Model.No_Symbol,
              "formal object profiles must not leak profile parameters as symbols");
   end Test_Language_Model_Generic_Formal_Object_Group_Profile_Semicolons;




   procedure Test_Language_Model_Same_Line_Generic_Formal_Type_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Generic_Formal_Types is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private; type Index is range <>; type Ref is access Element;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "end Same_Line_Generic_Formal_Types;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_generic_formal_types.ads");
      Element_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ref");
      G_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "G");
      Element_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
      G_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, G_Id);
   begin
      Assert (Element_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Element_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Element_Info.Flags.Is_Generic
              and then Element_Info.Flags.Is_Private,
              "first same-line generic formal type should stay formal/private");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Index_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Index_Info.Flags.Is_Generic,
              "later same-line generic formal type should not become ordinary type");
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Ref_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Ref_Info.Flags.Is_Generic
              and then To_String (Ref_Info.Target_Name) = "Element",
              "same-line generic formal access type should retain designated target metadata");
      Assert (G_Id /= Editor.Ada_Language_Model.No_Symbol
              and then G_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then G_Info.Flags.Is_Generic,
              "generic package after same-line formal type group should remain generic");
   end Test_Language_Model_Same_Line_Generic_Formal_Type_Groups;



   procedure Test_Language_Model_Same_Line_Generic_Unit_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Generic_Marker is" & ASCII.LF &
        "   generic; package Compact_Package is end Compact_Package;" & ASCII.LF &
        "   generic; procedure Compact_Procedure;" & ASCII.LF &
        "   generic; function Compact_Function return Natural;" & ASCII.LF &
        "end Same_Line_Generic_Marker;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_generic_marker.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Package");
      Procedure_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Procedure");
      Function_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Function");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Procedure_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Procedure_Id);
      Function_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Function_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Package_Info.Flags.Is_Generic
              and then Package_Info.Declaration_Column > 10,
              "same-line generic marker should apply to following package and preserve tail column");
      Assert (Procedure_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Procedure_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram
              and then Procedure_Info.Flags.Is_Generic,
              "same-line generic marker should apply to following procedure");
      Assert (Function_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Function_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram
              and then Function_Info.Flags.Is_Generic
              and then To_String (Function_Info.Target_Name) = "Natural",
              "same-line generic marker should apply to following function and retain return target");
   end Test_Language_Model_Same_Line_Generic_Unit_Marker;





   procedure Test_Language_Model_Generic_Actual_Part_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Actual_Metadata is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   package Vectors is end Vectors;" & ASCII.LF &
        "   package Int_Vectors is new Vectors (Integer);" & ASCII.LF &
        "   package Default_Vectors is new Vectors;" & ASCII.LF &
        "   type Child is new Root (Disc);" & ASCII.LF &
        "end Generic_Actual_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_actual_part_metadata.ads");
      Int_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Int_Vectors");
      Default_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Default_Vectors");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Int_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Int_Id);
      Default_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Default_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
   begin
      Assert (Int_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Int_Info.Flags.Is_Instantiation
              and then Int_Info.Flags.Has_Generic_Actual_Part_Metadata,
              "generic instantiations with actual parts should retain metadata");
      Assert (Default_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Default_Info.Flags.Is_Instantiation
              and then not Default_Info.Flags.Has_Generic_Actual_Part_Metadata,
              "generic instantiations without actual parts should not be marked");
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_Info.Flags.Has_Derived_Metadata
              and then not Child_Info.Flags.Has_Generic_Actual_Part_Metadata,
              "derived type constraints must not be reported as generic actuals");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Integer") =
                Editor.Ada_Language_Model.No_Symbol,
              "generic actual expressions must not become declaration symbols");
   end Test_Language_Model_Generic_Actual_Part_Metadata;





   procedure Test_Ada_Generic_Formal_Type_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Formal_Type_Checks is" & ASCII.LF &
        "   type Root is range 0 .. 100;" & ASCII.LF &
        "   type Child is new Root;" & ASCII.LF &
        "   type Ref is access Root;" & ASCII.LF &
        "   type Iface is interface;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Priv is private;" & ASCII.LF &
        "      type Der is new Root;" & ASCII.LF &
        "      type Intf is interface;" & ASCII.LF &
        "      type Acc is access Root;" & ASCII.LF &
        "   package G is" & ASCII.LF &
        "   end G;" & ASCII.LF &
        "   package Good is new G (Root, Child, Iface, Ref);" & ASCII.LF &
        "   package Bad is new G (Root, Root, Root, Root);" & ASCII.LF &
        "end Generic_Formal_Type_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Conformance : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model :=
        Editor.Ada_Generic_Formal_Type_Conformance.Build (Tree, Contracts, Types);
      Saw_Private : Boolean := False;
      Saw_Derived : Boolean := False;
      Saw_Access : Boolean := False;
      Saw_Mismatch : Boolean := False;
   begin
      Assert (Editor.Ada_Generic_Formal_Type_Conformance.Check_Count (Conformance) >= 4,
              "generic formal type conformance must stage formal type actual checks");

      for Index in 1 .. Editor.Ada_Generic_Formal_Type_Conformance.Check_Count (Conformance) loop
         declare
            Info : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Info :=
              Editor.Ada_Generic_Formal_Type_Conformance.Check_At (Conformance, Index);
         begin
            if Info.Status = Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Private_Compatible then
               Saw_Private := True;
            elsif Info.Status = Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Derived_Compatible then
               Saw_Derived := True;
            elsif Info.Status = Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Access_Compatible then
               Saw_Access := True;
            elsif Info.Status in
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Category_Mismatch |
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Base_Mismatch
            then
               Saw_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Saw_Private,
              "private formal type actuals must be classified separately");
      Assert (Saw_Derived,
              "formal derived type actuals must use type-graph ancestry");
      Assert (Saw_Access,
              "formal access type actuals must require access-type targets");
      Assert (Saw_Mismatch,
              "nonconforming formal type actuals must be retained as mismatches");
      Assert (Editor.Ada_Generic_Formal_Type_Conformance.Compatible_Count (Conformance) >= 3,
              "formal type conformance must expose compatible counters");
      Assert (Editor.Ada_Generic_Formal_Type_Conformance.Mismatch_Count (Conformance) >= 1,
              "formal type conformance must expose mismatch counters");
      Assert (Editor.Ada_Generic_Formal_Type_Conformance.Fingerprint (Conformance) /= 0,
              "formal type conformance must retain deterministic fingerprints");
   end Test_Ada_Generic_Formal_Type_Conformance;




   procedure Test_Ada_Generic_Renaming_Nested_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Status;
      use type Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Renaming_Nested_Checks is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   package Template is" & ASCII.LF &
        "   end Template;" & ASCII.LF &
        "   package Alias renames Template;" & ASCII.LF &
        "   package Direct_Int is new Template (Integer);" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Local_Element is private;" & ASCII.LF &
        "   package Outer is" & ASCII.LF &
        "      package Nested_By_Alias is new Alias (Local_Element);" & ASCII.LF &
        "      package Nested_Direct is new Template (Local_Element);" & ASCII.LF &
        "   end Outer;" & ASCII.LF &
        "   package Broken renames Missing_Generic;" & ASCII.LF &
        "   package Bad_Instance is new Broken (Integer);" & ASCII.LF &
        "end Generic_Renaming_Nested_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Renaming : constant Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model :=
        Editor.Ada_Generic_Renaming_Visibility.Build
          (Tree, Regions, Visibility, Contracts);
      Saw_Resolved_Renaming : Boolean := False;
      Saw_Error_Renaming : Boolean := False;
      Saw_Renamed_Instance : Boolean := False;
      Saw_Direct_Instance : Boolean := False;
      Saw_Error_Instance : Boolean := False;
   begin
      Assert (Editor.Ada_Generic_Renaming_Visibility.Renaming_Count (Renaming) >= 2,
              "generic renaming visibility must stage generic renaming declarations");
      Assert (Editor.Ada_Generic_Renaming_Visibility.Nested_Instantiation_Count (Renaming) >= 3,
              "generic renaming visibility must stage nested and renamed generic instances");

      for Index in 1 .. Editor.Ada_Generic_Renaming_Visibility.Renaming_Count (Renaming) loop
         declare
            Info : constant Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Info :=
              Editor.Ada_Generic_Renaming_Visibility.Renaming_At (Renaming, Index);
         begin
            if Info.Status = Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Target_Resolved then
               Saw_Resolved_Renaming := True;
            elsif Info.Status = Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Target_Unresolved then
               Saw_Error_Renaming := True;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Renaming_Visibility.Nested_Instantiation_Count (Renaming) loop
         declare
            Info : constant Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Info :=
              Editor.Ada_Generic_Renaming_Visibility.Nested_Instantiation_At (Renaming, Index);
         begin
            if Info.Status = Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Renamed_Target then
               Saw_Renamed_Instance := True;
            elsif Info.Status = Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Direct_Target
              and then Info.Is_Nested
            then
               Saw_Direct_Instance := True;
            elsif Info.Status = Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Target_Not_Generic
              or else Info.Status = Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Target_Unresolved
            then
               Saw_Error_Instance := True;
            end if;
         end;
      end loop;

      Assert (Saw_Resolved_Renaming,
              "generic renaming visibility must resolve aliases of generic declarations");
      Assert (Saw_Error_Renaming,
              "generic renaming visibility must retain unresolved renamed generic targets");
      Assert (Saw_Renamed_Instance,
              "generic instantiations through renamed generics must resolve to the original generic");
      Assert (Saw_Direct_Instance,
              "nested direct generic instantiations must remain visible as nested contract users");
      Assert (Saw_Error_Instance,
              "generic instantiation through invalid renaming must remain diagnostic metadata");
      Assert (Editor.Ada_Generic_Renaming_Visibility.Renaming_Resolved_Count (Renaming) >= 1,
              "generic renaming visibility must expose resolved counters");
      Assert (Editor.Ada_Generic_Renaming_Visibility.Nested_Renamed_Instance_Count (Renaming) >= 1,
              "generic renaming visibility must expose renamed-instance counters");
      Assert (Editor.Ada_Generic_Renaming_Visibility.Nested_Direct_Instance_Count (Renaming) >= 1,
              "generic renaming visibility must expose direct nested-instance counters");
      Assert (Editor.Ada_Generic_Renaming_Visibility.Fingerprint (Renaming) /= 0,
              "generic renaming visibility must retain deterministic fingerprints");
   end Test_Ada_Generic_Renaming_Nested_Visibility;




   procedure Test_Ada_Generic_Object_Default_Type_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Object_Default_Type_Checks is" & ASCII.LF &
        "   subtype Small is Integer range 0 .. 10;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Count : Small := 4;" & ASCII.LF &
        "      Scale : Float := 1.5;" & ASCII.LF &
        "   package Template is" & ASCII.LF &
        "   end Template;" & ASCII.LF &
        "   package Uses_Default is new Template;" & ASCII.LF &
        "   package Good_Actual is new Template (8, 2.5);" & ASCII.LF &
        "   package Bad_Range is new Template (99, 2.5);" & ASCII.LF &
        "   package Bad_Type is new Template (1.25, 3);" & ASCII.LF &
        "end Generic_Object_Default_Type_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Static
          (Tree, Regions, Visibility,
           Editor.Ada_Static_Expressions.Build (Tree, Regions));
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Defaults : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Contracts, Static, Types);
      Saw_Default_Compatible : Boolean := False;
      Saw_Actual_Compatible : Boolean := False;
      Saw_Range_Error : Boolean := False;
      Saw_Type_Mismatch : Boolean := False;
   begin
      Assert (Editor.Ada_Generic_Object_Default_Type_Conformance.Check_Count (Defaults) >= 4,
              "generic object default type conformance must stage defaults and explicit actuals");

      for Index in 1 .. Editor.Ada_Generic_Object_Default_Type_Conformance.Check_Count (Defaults) loop
         declare
            Info : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Info :=
              Editor.Ada_Generic_Object_Default_Type_Conformance.Check_At (Defaults, Index);
         begin
            if Info.Status = Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Compatible then
               Saw_Default_Compatible := True;
            elsif Info.Status = Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Compatible then
               Saw_Actual_Compatible := True;
            elsif Info.Status = Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Static_Range_Error then
               Saw_Range_Error := True;
            elsif Info.Status = Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Type_Mismatch
              or else Info.Status = Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Type_Mismatch
            then
               Saw_Type_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Saw_Default_Compatible,
              "defaulted formal object expressions must be checked against their formal subtype");
      Assert (Saw_Actual_Compatible,
              "explicit generic object actuals must be checked against their formal subtype");
      Assert (Saw_Range_Error,
              "static object actuals outside formal subtype bounds must be retained as range errors");
      Assert (Saw_Type_Mismatch,
              "generic object actual type mismatches must be retained explicitly");
      Assert (Editor.Ada_Generic_Object_Default_Type_Conformance.Compatible_Count (Defaults) >= 2,
              "generic object default type conformance must expose compatible counters");
      Assert (Editor.Ada_Generic_Object_Default_Type_Conformance.Range_Error_Count (Defaults) >= 1,
              "generic object default type conformance must expose range-error counters");
      Assert (Editor.Ada_Generic_Object_Default_Type_Conformance.Fingerprint (Defaults) /= 0,
              "generic object default type conformance must retain deterministic fingerprints");
   end Test_Ada_Generic_Object_Default_Type_Conformance;





   procedure Test_Ada_Generic_Contract_Diagnostics_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Kind;
      use type Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Severity;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Contract_Diagnostics_Checks is" & ASCII.LF &
        "   subtype Small is Integer range 0 .. 10;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Count : Small := 4;" & ASCII.LF &
        "      Scale : Float := 1.5;" & ASCII.LF &
        "   package Template is" & ASCII.LF &
        "   end Template;" & ASCII.LF &
        "   package Bad_Range is new Template (99, 2.5);" & ASCII.LF &
        "   package Bad_Type is new Template (1.25, 3);" & ASCII.LF &
        "end Generic_Contract_Diagnostics_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Static_And_Type_Graph
          (Tree, Regions, Visibility, Static, Types);
      Formal_Types : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model :=
        Editor.Ada_Generic_Formal_Type_Conformance.Build (Tree, Contracts, Types);
      Nested : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build (Tree, Contracts);
      Renamings : constant Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model :=
        Editor.Ada_Generic_Renaming_Visibility.Build (Tree, Regions, Visibility, Contracts);
      Defaults : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Contracts, Static, Types);
      Diags : constant Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model :=
        Editor.Ada_Generic_Contract_Diagnostics.Build
          (Formal_Types, Nested, Renamings, Defaults);
      First : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Info;
   begin
      First := Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_At (Diags, 1);

      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Has_Diagnostics (Diags)
         and then Editor.Ada_Generic_Contract_Diagnostics.Error_Count (Diags) >= 2,
         "generic contract diagnostics must project conformance mismatches into errors");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Generic_Contract_Diagnostics.Generic_Diagnostic_Object_Default_Range_Error) >= 1,
         "generic contract diagnostics must expose static range errors as stable diagnostics");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Generic_Contract_Diagnostics.Generic_Diagnostic_Object_Default_Type_Mismatch) >= 1,
         "generic contract diagnostics must expose object actual type mismatches as stable diagnostics");
      Assert
        (First.Severity = Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Error
         and then First.Start_Line >= 1
         and then First.End_Line >= First.Start_Line,
         "generic contract diagnostics must retain severity and source spans");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Fingerprint (Diags) /= 0,
         "generic contract diagnostics must retain deterministic fingerprints");
   end Test_Ada_Generic_Contract_Diagnostics_Projection;



   procedure Test_Resolver_Generic_Instance_Expansion_Uses_Actuals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Expansion is" & ASCII.LF &
        "   type Count is range 0 .. 10;" & ASCII.LF &
        "   type Name is range 0 .. 10;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   package Holder is" & ASCII.LF &
        "      function Make (Value : Element) return Element;" & ASCII.LF &
        "      function Identity return Element;" & ASCII.LF &
        "   end Holder;" & ASCII.LF &
        "   package Count_Holder is new Holder (Count);" & ASCII.LF &
        "   C : Count;" & ASCII.LF &
        "   N : Name;" & ASCII.LF &
        "end Generic_Expansion;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "generic_expansion.ads");
      Instance_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count_Holder");
      Make_Result : constant Editor.Ada_Symbol_Resolver.Resolution_Result :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Count_Holder.Make", Editor.Ada_Language_Model.No_Symbol, "C");
      Wrong_Result : constant Editor.Ada_Symbol_Resolver.Resolution_Result :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Count_Holder.Make", Editor.Ada_Language_Model.No_Symbol, "N");
      Identity_Result : constant Editor.Ada_Symbol_Resolver.Resolution_Result :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Count_Holder.Identity", Editor.Ada_Language_Model.No_Symbol,
           "", "C");
      Instance_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Instance_Id);
   begin
      Assert (Instance_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Instance_Info.Kind = Editor.Ada_Language_Model.Symbol_Instantiation,
              "generic package instantiation should be retained");
      Assert (Editor.Ada_Language_Model.Generic_Actual_Count (Analysis, Instance_Id) = 1,
              "generic actual associations should be projected into the language model");
      Assert (Natural (Make_Result.Matches.Length) = 1,
              "selected calls through a generic instance should expose expanded template children");
      Assert (Wrong_Result.Matches.Is_Empty,
              "generic actual substitution must reject mismatched instance actual types");
      Assert (Natural (Identity_Result.Matches.Length) = 1,
              "expected result filtering should substitute generic formal result types");
   end Test_Resolver_Generic_Instance_Expansion_Uses_Actuals;



   procedure Test_Resolver_Generic_Instance_Expression_Inference_Substitutes_Actuals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Expression_Inference is" & ASCII.LF &
        "   type Count is range 0 .. 10;" & ASCII.LF &
        "   type Name is range 0 .. 10;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   package Holder is" & ASCII.LF &
        "      Current : Element;" & ASCII.LF &
        "      function Identity return Element;" & ASCII.LF &
        "   end Holder;" & ASCII.LF &
        "   package Count_Holder is new Holder (Count);" & ASCII.LF &
        "   procedure Take (Value : Count);" & ASCII.LF &
        "   procedure Take (Value : Name);" & ASCII.LF &
        "end Generic_Expression_Inference;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "generic_expression_inference.ads");
      Object_Type : constant String :=
        Editor.Ada_Symbol_Resolver.Infer_Expression_Type_In_Scope
          (Analysis, "Count_Holder.Current", Editor.Ada_Language_Model.No_Symbol);
      Call_Type : constant String :=
        Editor.Ada_Symbol_Resolver.Infer_Expression_Type_In_Scope
          (Analysis, "Count_Holder.Identity", Editor.Ada_Language_Model.No_Symbol);
      Object_Actual : constant Editor.Ada_Symbol_Resolver.Resolution_Result :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Take", Editor.Ada_Language_Model.No_Symbol, "Count_Holder.Current");
      Call_Actual : constant Editor.Ada_Symbol_Resolver.Resolution_Result :=
        Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope
          (Analysis, "Take", Editor.Ada_Language_Model.No_Symbol, "Count_Holder.Identity");
   begin
      Assert (Editor.Ada_Language_Model.Normalize_Name (Object_Type) = "count",
              "selected generic instance object expression should substitute the actual type");
      Assert (Editor.Ada_Language_Model.Normalize_Name (Call_Type) = "count",
              "selected generic instance function expression should substitute the actual result type");
      Assert (Natural (Object_Actual.Matches.Length) = 1,
              "overload resolution should use substituted instance object expression type");
      Assert (Natural (Call_Actual.Matches.Length) = 1,
              "overload resolution should use substituted instance call expression type");
   end Test_Resolver_Generic_Instance_Expression_Inference_Substitutes_Actuals;





   procedure Test_Language_Model_Legality_Generic_Actual_Association_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      Initial : Integer := 0;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   package Duplicate is new G (Element => Integer, Element => Boolean);" & ASCII.LF &
        "   package Mixed is new G (Element => Integer, 1);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Formal : Boolean := False;
      Seen_Positional_After_Named : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "generic actual legality should add diagnostics for invalid association lists");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Generic_Actual_Formal =>
                  Seen_Duplicate_Formal := True;
               when Editor.Ada_Language_Model.Legality_Positional_Generic_Actual_After_Named =>
                  Seen_Positional_After_Named := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Duplicate_Formal,
              "legality checking should flag duplicate named generic actual formals");
      Assert (Seen_Positional_After_Named,
              "legality checking should flag positional generic actuals after named actuals");
   end Test_Language_Model_Legality_Generic_Actual_Association_Pass;





   procedure Test_Language_Model_Legality_Generic_Others_Association_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      Default_Count : Integer := 0;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with package Bad_Order is new G (others => <>, Default_Count => 1);" & ASCII.LF &
        "      with package Bad_Value is new G (others => 1);" & ASCII.LF &
        "   package Host is end Host;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Not_Last : Boolean := False;
      Seen_Not_Box  : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "generic others association legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Generic_Others_Actual_Not_Last =>
                  Seen_Not_Last := True;
               when Editor.Ada_Language_Model.Legality_Generic_Others_Actual_Must_Be_Box =>
                  Seen_Not_Box := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Not_Last,
              "legality checking should flag others generic actuals before later actuals");
      Assert (Seen_Not_Box,
              "legality checking should flag non-box others generic actuals");
   end Test_Language_Model_Legality_Generic_Others_Association_Pass;




   procedure Test_Ada_Generic_Contract_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      use type Editor.Ada_Generic_Contracts.Generic_Instance_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   Initial : in Element;" & ASCII.LF &
        "   with function Image (Value : Element) return String is <>;" & ASCII.LF &
        "   with package Helper is new Ada.Containers.Vectors (<>);" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "   procedure Put (Value : Element := Initial);" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package Integer_Box is new Generic_Box (Integer, Initial => 0, Image => Integer'Image, Helper => Int_Vectors);";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Seen_Type : Boolean := False;
      Seen_Object : Boolean := False;
      Seen_Subprogram_Default : Boolean := False;
      Seen_Package_Default : Boolean := False;
      Seen_Instance : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
         declare
            Info : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Editor.Ada_Generic_Contracts.Formal_At (Contracts, Index);
            Name : constant String := To_String (Info.Normalized_Name);
         begin
            if Name = "element" and then Info.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Type then
               Seen_Type := True;
            elsif Name = "initial" and then Info.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Object then
               Seen_Object := True;
            elsif Name = "image" and then Info.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Subprogram
              and then Info.Has_Default
            then
               Seen_Subprogram_Default := True;
            elsif Name = "helper" and then Info.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Package
              and then Info.Has_Default
            then
               Seen_Package_Default := True;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Info : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
         begin
            if To_String (Info.Normalized_Name) = "integer_box"
              and then To_String (Info.Normalized_Generic) = "generic_box"
              and then Info.Positional_Actuals = 1
              and then Info.Named_Actuals = 3
              and then Info.Total_Actuals = 4
              and then Info.Status = Editor.Ada_Generic_Contracts.Generic_Instance_Record_Valid
            then
               Seen_Instance := True;
            end if;
         end;
      end loop;

      Assert (Seen_Type and then Seen_Object,
              "generic contract model must record formal type and object declarations");
      Assert (Seen_Subprogram_Default and then Seen_Package_Default,
              "generic contract model must preserve formal subprogram/package defaults");
      Assert (Seen_Instance,
              "generic contract model must stage positional and named instantiation actuals");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic contract model must retain deterministic fingerprints");
   end Test_Ada_Generic_Contract_Foundation;




   procedure Test_Ada_Generic_Actual_Matching_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   Initial : in Element;" & ASCII.LF &
        "   with function Image (Value : Element) return String is <>;" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "   procedure Put (Value : Element := Initial);" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package Valid_Box is new Generic_Box (Integer, Initial => 0, Image => Integer'Image);" & ASCII.LF &
        "package Missing_Box is new Generic_Box (Integer);" & ASCII.LF &
        "package Unknown_Box is new Generic_Box (Integer, Initial => 0, Bogus => 1);";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Valid : Boolean := False;
      Saw_Missing : Boolean := False;
      Saw_Unknown : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance (Contracts, Instance.Id);
            Name : constant String := To_String (Instance.Normalized_Name);
         begin
            if Name = "valid_box" then
               Saw_Valid :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Formal_Count = 3
                 and then Match.Required_Formals = 2
                 and then Match.Matched_Formals = 3
                 and then Match.Defaulted_Formals = 1;
            elsif Name = "missing_box" then
               Saw_Missing :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Missing_Required_Formal
                 and then Match.Missing_Required_Formals = 1;
            elsif Name = "unknown_box" then
               Saw_Unknown :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Unknown_Named_Actual
                 and then Match.Unknown_Named_Actuals = 1;
            end if;
         end;
      end loop;

      Assert (Editor.Ada_Generic_Contracts.Actual_Match_Count (Contracts) >= 3,
              "generic contract model must classify actual/formal matching for staged instantiations");
      Assert (Saw_Valid,
              "valid generic instances must match required/defaulted formal shape");
      Assert (Saw_Missing,
              "instances missing non-defaulted formals must retain deterministic mismatch metadata");
      Assert (Saw_Unknown,
              "unknown named generic actuals must be classified before deeper conformance checks");
   end Test_Ada_Generic_Actual_Matching_Foundation;



   procedure Test_Ada_Generic_Formal_Actual_Kind_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Item is private;" & ASCII.LF &
        "package Generic_Helper is" & ASCII.LF &
        "end Generic_Helper;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   Initial : in Element;" & ASCII.LF &
        "   with function Image (Value : Element) return String is <>;" & ASCII.LF &
        "   with package Helper is new Generic_Helper (<>);" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "   procedure Put (Value : Element := Initial);" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package Good_Box is new Generic_Box " &
        "(Integer, Initial => 0, Image => Integer'Image, Helper => new Generic_Helper (Integer));" & ASCII.LF &
        "package Bad_Box is new Generic_Box " &
        "(42, Initial => Integer, Image => 0, Helper => 1);";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good : Boolean := False;
      Saw_Bad : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance (Contracts, Instance.Id);
            Name : constant String := To_String (Instance.Normalized_Name);
         begin
            if Name = "good_box" then
               Saw_Good :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Kind_Compatible_Formals >= 4
                 and then Match.Kind_Mismatched_Formals = 0;
            elsif Name = "bad_box" then
               Saw_Bad :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Kind_Mismatch
                 and then Match.Kind_Mismatched_Formals >= 3
                 and then Editor.Ada_Generic_Contracts.Kind_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = Match.Kind_Mismatched_Formals;
            end if;
         end;
      end loop;

      Assert (Saw_Good,
              "generic actual kind conformance must accept type/object/subprogram/package actual shapes");
      Assert (Saw_Bad,
              "generic actual kind conformance must classify formal-kind mismatches deterministically");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic formal-kind conformance must retain deterministic fingerprints");
   end Test_Ada_Generic_Formal_Actual_Kind_Conformance;





   procedure Test_Ada_Generic_Body_Contract_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Status;
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Item is private;" & ASCII.LF &
        "package Generic_Helper is" & ASCII.LF &
        "end Generic_Helper;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   Initial : in Element;" & ASCII.LF &
        "   with procedure Visit (Value : Element);" & ASCII.LF &
        "   with package Helper is new Generic_Helper (<>);" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "   procedure Spec_Use (Item : Element);" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package body Generic_Box is" & ASCII.LF &
        "   Stored : Element := Initial;" & ASCII.LF &
        "   procedure Body_Use (Value : Element) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Visit (Value);" & ASCII.LF &
        "   end Body_Use;" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Missing_Element is private;" & ASCII.LF &
        "package Bodyless_Generic is" & ASCII.LF &
        "end Bodyless_Generic;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Box_Body : Boolean := False;
      Saw_Bodyless : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Body_Contract_Visibility_Count (Contracts) loop
         declare
            Body_Info : constant Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info :=
              Editor.Ada_Generic_Contracts.Body_Contract_Visibility_At (Contracts, Index);
            Name : constant String := To_String (Body_Info.Normalized_Name);
         begin
            if Name = "generic_box" then
               declare
                  Element_Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                    Editor.Ada_Generic_Contracts.Body_Formal
                      (Contracts, Body_Info.Body_Region, "Element");
                  Initial_Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                    Editor.Ada_Generic_Contracts.Body_Formal
                      (Contracts, Body_Info.Body_Region, "Initial");
                  Visit_Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                    Editor.Ada_Generic_Contracts.Body_Formal
                      (Contracts, Body_Info.Body_Region, "Visit");
                  Helper_Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                    Editor.Ada_Generic_Contracts.Body_Formal
                      (Contracts, Body_Info.Body_Region, "Helper");
               begin
                  Saw_Box_Body :=
                    Body_Info.Status = Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visible
                    and then Body_Info.Formal_Count = 4
                    and then Body_Info.Visible_Formals = 4
                    and then Body_Info.Shadowed_Formals = 0
                    and then Editor.Ada_Generic_Contracts.Body_Formal_Visible
                      (Contracts, Body_Info.Body_Region, "Element")
                    and then Element_Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Type
                    and then Initial_Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Object
                    and then Visit_Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Subprogram
                    and then Helper_Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Package;
               end;
            elsif Name = "bodyless_generic" then
               Saw_Bodyless :=
                 Body_Info.Status = Editor.Ada_Generic_Contracts.Generic_Body_Contract_Body_Not_Found
                 and then Body_Info.Formal_Count = 1
                 and then Body_Info.Visible_Formals = 0;
            end if;
         end;
      end loop;

      Assert (Saw_Box_Body,
              "generic body contract visibility must expose formal types, objects, subprograms, and packages inside the matching body region");
      Assert (Saw_Bodyless,
              "generic body contract visibility must retain body-not-found metadata deterministically");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic body contract visibility must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Body_Contract_Visibility;




   procedure Test_Ada_Generic_Default_Expression_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "Scale : constant := 4;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   Left  : in Integer := Scale + 1;" & ASCII.LF &
        "   Right : in Integer := 10 / 2;" & ASCII.LF &
        "package Generic_Defaults is" & ASCII.LF &
        "end Generic_Defaults;" & ASCII.LF &
        "package Good_Defaults is new Generic_Defaults;" & ASCII.LF &
        "package Bad_Defaults is new Generic_Defaults (Left => 1 / 0);" & ASCII.LF &
        "package Unknown_Defaults is new Generic_Defaults (Left => Missing_Value);";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Static
          (Tree, Regions, Visibility, Static);
      Saw_Good : Boolean := False;
      Saw_Bad : Boolean := False;
      Saw_Unknown : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance
                (Contracts, Instance.Id);
            Name : constant String := To_String (Instance.Normalized_Name);
         begin
            if Name = "good_defaults" then
               Saw_Good :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Default_Expression_Checked_Formals = 2
                 and then Match.Default_Expression_Static_Formals = 2
                 and then Editor.Ada_Generic_Contracts.Default_Expression_Static_Count_For_Instance
                   (Contracts, Instance.Id) = 2;
            elsif Name = "bad_defaults" then
               Saw_Bad :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Object_Default_Illegal
                 and then Match.Default_Expression_Illegal_Formals = 1
                 and then Match.Default_Expression_Division_By_Zero_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Default_Expression_Illegal_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "unknown_defaults" then
               Saw_Unknown :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Object_Default_Unknown
                 and then Match.Default_Expression_Unknown_Formals = 1
                 and then Match.Default_Expression_Unresolved_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Default_Expression_Unknown_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good,
              "generic default-expression legality must accept static defaulted formal object expressions");
      Assert (Saw_Bad,
              "generic default-expression legality must classify illegal explicit object actual expressions");
      Assert (Saw_Unknown,
              "generic default-expression legality must retain unresolved object actual metadata");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic default-expression legality must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Default_Expression_Legality;



   procedure Test_Ada_Generic_View_Compatibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Generic_View_Compatibility.Generic_View_Status;
      Library_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Library is" & ASCII.LF &
           "   Exported : Integer;" & ASCII.LF &
           "end Library;" & ASCII.LF,
           "library.ads");
      Client_Source : constant String :=
        "private with Library;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   package I is new G (Library.Exported);" & ASCII.LF &
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
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions);
      Object_Defaults : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Contracts, Static, Types);
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Model : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
      First : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info;
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
      Model := Editor.Ada_Generic_View_Compatibility.Build (Object_Defaults, Views);

      Assert
        (Editor.Ada_Generic_View_Compatibility.Entry_Count (Model) >= 1,
         "generic view compatibility must classify generic actual/default checks");
      First := Editor.Ada_Generic_View_Compatibility.Entry_At (Model, 1);
      Assert
        (First.Status in
           Editor.Ada_Generic_View_Compatibility.Generic_View_Private_Barrier |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Limited_Barrier |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Cross_Unit_Unresolved |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Unknown |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Mismatch,
         "generic view compatibility must distinguish view barriers from ordinary generic mismatches");
      Assert
        (Editor.Ada_Generic_View_Compatibility.Private_Barrier_Count (Model) +
         Editor.Ada_Generic_View_Compatibility.Limited_Barrier_Count (Model) +
         Editor.Ada_Generic_View_Compatibility.Unresolved_Count (Model) +
         Editor.Ada_Generic_View_Compatibility.Object_Mismatch_Count (Model) +
         Editor.Ada_Generic_View_Compatibility.Unknown_Count (Model) >= 1,
         "generic view compatibility must expose deterministic barrier/mismatch counters");
      Assert
        (Editor.Ada_Generic_View_Compatibility.Fingerprint (Model) /= 0,
         "generic view compatibility must preserve deterministic fingerprints");
   end Test_Ada_Generic_View_Compatibility;



   procedure Test_Ada_Generic_Contract_Diagnostics_View_Compatibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Id;
      use type Editor.Ada_Generic_View_Compatibility.Generic_View_Status;
      Library_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Library is" & ASCII.LF &
           "   Exported : Integer;" & ASCII.LF &
           "end Library;" & ASCII.LF,
           "library.ads");
      Client_Source : constant String :=
        "private with Library;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   package I is new G (Library.Exported);" & ASCII.LF &
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
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions);
      Formal_Types : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model :=
        Editor.Ada_Generic_Formal_Type_Conformance.Build (Tree, Contracts, Types);
      Nested : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build (Tree, Contracts);
      Renamings : constant Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model :=
        Editor.Ada_Generic_Renaming_Visibility.Build (Tree, Regions, Visibility, Contracts);
      Object_Defaults : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Contracts, Static, Types);
      Calls : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
      Diags : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model;
      First : Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Info;
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
      Generic_Views := Editor.Ada_Generic_View_Compatibility.Build (Object_Defaults, Views);
      Diags := Editor.Ada_Generic_Contract_Diagnostics.Build_With_View_Compatibility
        (Formal_Types, Nested, Renamings, Object_Defaults, Generic_Views);

      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Generic_View_Diagnostic_Count (Diags) >= 1,
         "generic contract diagnostics must project generic view compatibility barriers");
      First := Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_At
        (Diags, Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_Count (Diags));
      Assert
        (First.From_Generic_View
         and then First.Generic_View /= Editor.Ada_Generic_View_Compatibility.No_Generic_View_Compatibility
         and then First.Generic_View_Status in
           Editor.Ada_Generic_View_Compatibility.Generic_View_Private_Barrier |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Limited_Barrier |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Cross_Unit_Unresolved |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Mismatch |
           Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Unknown
         and then First.Generic_View_Fingerprint /= 0
         and then Length (First.Detail) > 0,
         "generic view diagnostics must retain view identity, status, fingerprint, and detail");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Private_View_Diagnostic_Count (Diags) +
         Editor.Ada_Generic_Contract_Diagnostics.Limited_View_Diagnostic_Count (Diags) +
         Editor.Ada_Generic_Contract_Diagnostics.View_Unresolved_Diagnostic_Count (Diags) >= 0,
         "generic contract diagnostics must expose view-specific counters deterministically");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Fingerprint (Diags) /= 0,
         "generic view diagnostic projection must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Contract_Diagnostics_View_Compatibility;





   procedure Test_Ada_Generic_Instantiated_Body_Analysis
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status;
      use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id;
      use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id;
      Source : constant String :=
        "generic" & ASCII.LF &
        "   Value : in Integer;" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "   procedure Touch;" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package body Generic_Box is" & ASCII.LF &
        "   Stored : Integer := Value;" & ASCII.LF &
        "   procedure Touch is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Touch;" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   package I is new Generic_Box (1);" & ASCII.LF &
        "end Client;" & ASCII.LF;
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
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Object_Defaults : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Contracts, Static, Types);
      Empty_Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Generic_Views : constant Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model :=
        Editor.Ada_Generic_View_Compatibility.Build (Object_Defaults, Empty_Views);
      Bodies : constant Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Build (Contracts, Generic_Views);
      First : constant Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Info :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Substitution_At (Bodies, 1);
      Again : constant Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Info :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.First_For_Formal
          (Bodies, First.Instance, First.Formal);
   begin
      Assert
        (Editor.Ada_Generic_Instantiated_Body_Analysis.Substitution_Count (Bodies) >= 1,
         "generic instantiated body analysis must project generic actuals into body substitutions");
      Assert
        (First.Status in
           Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substituted |
           Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Default_Substituted |
           Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Unknown |
           Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Mismatch,
         "instantiated body analysis must classify body substitutions with contract/view-aware status");
      Assert
        (Again.Id /= Editor.Ada_Generic_Instantiated_Body_Analysis.No_Instantiated_Body_Substitution
         and then First.Body_Contract /= Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility
         and then First.Fingerprint /= 0,
         "instantiated body substitutions must preserve lookup identity, body contract identity, and fingerprints");
      Assert
        (Editor.Ada_Generic_Instantiated_Body_Analysis.Substituted_Count (Bodies) +
         Editor.Ada_Generic_Instantiated_Body_Analysis.Default_Substituted_Count (Bodies) +
         Editor.Ada_Generic_Instantiated_Body_Analysis.Object_Mismatch_Count (Bodies) +
         Editor.Ada_Generic_Instantiated_Body_Analysis.Unknown_Count (Bodies) >= 1,
         "instantiated body analysis must expose deterministic substitution counters");
      Assert
        (Editor.Ada_Generic_Instantiated_Body_Analysis.Fingerprint (Bodies) /= 0,
         "instantiated body analysis must produce a deterministic fingerprint");
   end Test_Ada_Generic_Instantiated_Body_Analysis;




   procedure Test_Ada_Generic_Contract_Diagnostics_Instantiated_Body
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id;
      use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id;
      Source : constant String :=
        "generic" & ASCII.LF &
        "   Value : in Integer;" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "   procedure Touch;" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   package I is new Generic_Box (1);" & ASCII.LF &
        "end Client;" & ASCII.LF;
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
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Formal_Types : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model :=
        Editor.Ada_Generic_Formal_Type_Conformance.Build (Tree, Contracts, Types);
      Nested : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build (Tree, Contracts);
      Renamings : constant Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model :=
        Editor.Ada_Generic_Renaming_Visibility.Build (Tree, Contracts);
      Object_Defaults : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Build
          (Tree, Contracts, Static, Types);
      Empty_Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Generic_Views : constant Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model :=
        Editor.Ada_Generic_View_Compatibility.Build (Object_Defaults, Empty_Views);
      Bodies : constant Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Build (Contracts, Generic_Views);
      Diags : constant Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Model :=
        Editor.Ada_Generic_Contract_Diagnostics.Build_With_View_Compatibility_And_Body_Analysis
          (Formal_Types, Nested, Renamings, Object_Defaults, Generic_Views, Bodies);
      First : constant Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Info :=
        Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_At
          (Diags, Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_Count (Diags));
   begin
      Assert
        (Editor.Ada_Generic_Instantiated_Body_Analysis.Missing_Body_Count (Bodies) >= 1,
         "instantiated body analysis fixture must expose a missing body contract");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Instantiated_Body_Diagnostic_Count (Diags) >= 1,
         "generic contract diagnostics must project instantiated-body substitution diagnostics");
      Assert
        (First.From_Instantiated_Body
         and then First.Instantiated_Body /=
           Editor.Ada_Generic_Instantiated_Body_Analysis.No_Instantiated_Body_Substitution
         and then First.Body_Contract =
           Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility
         and then First.Instantiated_Body_Fingerprint /= 0
         and then Length (First.Detail) > 0,
         "instantiated body diagnostics must preserve substitution identity, body contract identity, fingerprints, and detail");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Body_Missing_Contract_Diagnostic_Count (Diags) >= 1
         and then Editor.Ada_Generic_Contract_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Generic_Contract_Diagnostics.Generic_Diagnostic_Instantiated_Body_Missing_Body_Contract) >= 1,
         "instantiated body diagnostics must expose missing-body counters and diagnostic kind counts");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Fingerprint (Diags) /= 0,
         "instantiated body diagnostics must contribute to deterministic diagnostic fingerprints");
   end Test_Ada_Generic_Contract_Diagnostics_Instantiated_Body;


   overriding function Name (T : Generic_Contract_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Generic.Contract");
   end Name;

   overriding procedure Register_Tests (T : in out Generic_Contract_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Type_Discriminants'Access, Name => "language model parser retains generic formal type discriminants");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Derived_Type_Target_Metadata'Access, Name => "language model parser records generic formal derived type parent targets");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Composite_Target_Metadata'Access, Name => "language model parser records generic formal composite type targets");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Type_Detail_Metadata'Access, Name => "language model parser projects generic formal type detail metadata");
      Add_Test (Routine => Test_Language_Model_Split_Generic_Formal_Object_Target_Metadata'Access, Name => "language model parser retains split generic formal object target metadata");
      Add_Test (Routine => Test_Project_Index_Generic_Package_Spec_Body_Targets'Access, Name => "project index retains generic package spec/body targets");
      Add_Test (Routine => Test_Project_Index_Generic_Subprogram_Spec_Body_Targets'Access, Name => "project index retains generic subprogram spec/body targets");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Object_And_Profiles'Access, Name => "language model parser records generic formal objects and profiles");
      Add_Test (Routine => Test_Language_Model_Multiple_Generic_Formal_Objects'Access, Name => "language model parser retains multiple generic formal objects per declaration");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Access_Subprogram_Object_Profile_Metadata'Access, Name => "language model parser retains generic formal access-subprogram object profile metadata");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Object_Group_Profile_Semicolons'Access, Name => "language model keeps formal object profile semicolons inside grouped declarations");
      Add_Test (Routine => Test_Language_Model_Same_Line_Generic_Formal_Type_Groups'Access, Name => "language model parser retains same-line generic formal type groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Generic_Unit_Marker'Access, Name => "language model parser retains same-line generic unit markers");
      Add_Test (Routine => Test_Language_Model_Generic_Actual_Part_Metadata'Access, Name => "language model retains generic actual part metadata");
      Add_Test (Routine => Test_Ada_Generic_Formal_Type_Conformance'Access, Name => "Ada generic formal type conformance checks formal derived private interface and access actuals");
      Add_Test (Routine => Test_Ada_Generic_Renaming_Nested_Visibility'Access, Name => "Ada generic renaming visibility resolves nested generic instantiations");
      Add_Test (Routine => Test_Ada_Generic_Object_Default_Type_Conformance'Access, Name => "Ada generic object default type conformance checks expression compatibility");
      Add_Test (Routine => Test_Ada_Generic_Contract_Diagnostics_Projection'Access, Name => "Ada generic contract diagnostics project generic conformance metadata into stable diagnostics");
      Add_Test (Routine => Test_Resolver_Generic_Instance_Expansion_Uses_Actuals'Access, Name => "resolver expands generic instance children and substitutes actuals");
      Add_Test (Routine => Test_Resolver_Generic_Instance_Expression_Inference_Substitutes_Actuals'Access, Name => "resolver substitutes generic actuals during instance expression inference");
      Add_Test (Routine => Test_Language_Model_Legality_Generic_Actual_Association_Pass'Access, Name => "language model checks generic actual association legality");
      Add_Test (Routine => Test_Language_Model_Legality_Generic_Others_Association_Pass'Access, Name => "language model checks generic others association legality");
      Add_Test (Routine => Test_Ada_Generic_Contract_Foundation'Access, Name => "Ada generic contract model records formals defaults and instantiation actual shape");
      Add_Test (Routine => Test_Ada_Generic_Actual_Matching_Foundation'Access, Name => "Ada generic contract model classifies formal actual matching");
      Add_Test (Routine => Test_Ada_Generic_Formal_Actual_Kind_Conformance'Access, Name => "Ada generic contract model checks formal actual kind conformance");
      Add_Test (Routine => Test_Ada_Generic_Body_Contract_Visibility'Access, Name => "Ada generic contract model exposes formal contract visibility in generic bodies");
      Add_Test (Routine => Test_Ada_Generic_Default_Expression_Legality'Access, Name => "Ada generic contract model checks default-expression legality for object formals");
      Add_Test (Routine => Test_Ada_Generic_View_Compatibility'Access, Name => "Ada generic view compatibility distinguishes private and limited barriers");
      Add_Test (Routine => Test_Ada_Generic_Contract_Diagnostics_View_Compatibility'Access, Name => "Ada generic contract diagnostics project private and limited generic view barriers");
      Add_Test (Routine => Test_Ada_Generic_Instantiated_Body_Analysis'Access, Name => "Ada generic instantiated body analysis projects formal substitutions into body contexts");
      Add_Test (Routine => Test_Ada_Generic_Contract_Diagnostics_Instantiated_Body'Access, Name => "Ada generic contract diagnostics project instantiated-body substitution issues");
   end Register_Tests;

end Editor.Syntax_Semantics.Generic_Contract_Tests;
