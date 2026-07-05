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

package body Editor.Syntax_Semantics.Generic_Formal_Package_Contract_Tests is

   procedure Test_Generic_Formal_Package_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Vectors is new Ada.Containers.Vectors (<>);" & ASCII.LF &
        "package Uses_Vectors is" & ASCII.LF &
        "end Uses_Vectors;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "uses_vectors.ads");
      Vectors_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Vectors");
      Vectors_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Vectors_Id);
   begin
      Assert (Vectors_Id /= Editor.Ada_Language_Model.No_Symbol,
              "generic formal package should be parsed as a symbol");
      Assert (Vectors_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
              "with package formal declarations should keep formal-package kind");
      Assert (Vectors_Info.Flags.Is_Generic,
              "generic formal package declarations should carry generic metadata");
      Assert (To_String (Vectors_Info.Target_Name) = "Ada.Containers.Vectors",
              "generic formal package declarations should retain the instantiated formal target");
   end Test_Generic_Formal_Package_Target_Metadata;

   procedure Test_Split_Generic_Formal_Package_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Maps is" & ASCII.LF &
        "      new Ada.Containers.Ordered_Maps (<>);" & ASCII.LF &
        "   with package Sets is new" & ASCII.LF &
        "      Ada.Containers.Ordered_Sets (<>);" & ASCII.LF &
        "package Uses_Containers is" & ASCII.LF &
        "end Uses_Containers;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "uses_containers.ads");
      Maps_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Maps");
      Sets_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Sets");
      Maps_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Maps_Id);
      Sets_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Sets_Id);
   begin
      Assert (Maps_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal package should be parsed as a symbol");
      Assert (Sets_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal package with trailing new should be parsed");
      Assert (Maps_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
              "split with package should keep formal-package kind");
      Assert (Sets_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
              "split with package is new should keep formal-package kind");
      Assert (Maps_Info.Flags.Is_Generic and then Maps_Info.Flags.Is_Instantiation,
              "split generic formal package should carry generic instantiation metadata");
      Assert (Sets_Info.Flags.Is_Generic and then Sets_Info.Flags.Is_Instantiation,
              "split generic formal package with trailing new should carry instantiation metadata");
      Assert (To_String (Maps_Info.Target_Name) = "Ada.Containers.Ordered_Maps",
              "split generic formal package should retain target after continuation new");
      Assert (To_String (Sets_Info.Target_Name) = "Ada.Containers.Ordered_Sets",
              "split generic formal package should retain target on following line");
   end Test_Split_Generic_Formal_Package_Target_Metadata;

   procedure Test_Language_Model_Generic_Formal_Package_Owns_Overload_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Formal_Id : Editor.Ada_Language_Model.Symbol_Id;
      Nested_A_Id : Editor.Ada_Language_Model.Symbol_Id;
      Nested_B_Id : Editor.Ada_Language_Model.Symbol_Id;
      Formal_Scope : Editor.Ada_Language_Model.Scope_Id;
   begin
      Formal_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Formal_IO",
         Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
         (Start_Line => 1, Start_Column => 9, End_Line => 1, End_Column => 18));
      Formal_Scope := Editor.Ada_Language_Model.Scope_Id (Natural (Formal_Id));
      Nested_A_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Create",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 2, Start_Column => 7, End_Line => 2, End_Column => 13),
         Enclosing_Scope => Formal_Scope,
         Parent_Symbol => Formal_Id);
      Nested_B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Create",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 3, Start_Column => 7, End_Line => 3, End_Column => 13),
         Enclosing_Scope => Formal_Scope,
         Parent_Symbol => Formal_Id);

      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Nested_A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Nested_B_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain a formal-package-owned overload set");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Formal_Scope, "Create") = 2,
              "generic formal packages should own scoped overload sets");
      Assert (Editor.Ada_Language_Model.Overload_At
                (Analysis, Formal_Scope, "Create", 1) = Nested_A_Id
              and then Editor.Ada_Language_Model.Overload_At
                (Analysis, Formal_Scope, "Create", 2) = Nested_B_Id,
              "formal-package overload enumeration should be deterministic");
   end Test_Language_Model_Generic_Formal_Package_Owns_Overload_Scope;

   procedure Test_Language_Model_Syntax_Tree_Generic_Formal_Part_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   with function Image (Value : Element) return String;" & ASCII.LF &
        "package Generic_Demo is" & ASCII.LF &
        "   procedure Put (Value : Element);" & ASCII.LF &
        "end Generic_Demo;";
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

      function Saw_Label_Fragment
        (Kind     : Editor.Ada_Syntax_Tree.Node_Kind;
         Fragment : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
               Label : constant String := To_String (Info.Label);
            begin
               if Info.Kind = Kind
                 and then Ada.Strings.Fixed.Index (Label, Fragment) /= 0
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label_Fragment;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Generic_Declaration) = 1,
              "generic formal part must remain represented as a structured generic node");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration) = 1,
              "generic formal type declarations must remain children of the generic formal part");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration) = 1,
              "generic formal subprogram declarations must remain children of the generic formal part");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Package_Declaration) = 1,
              "the generic unit declaration must still be parsed as a package declaration");
      Assert (Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Implicit_End, "generic formal part"),
              "starting the generic unit must implicitly close the generic formal part");
      Assert (not Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Missing_End, "generic formal"),
              "well-formed generic formal parts must not leave EOF missing-end diagnostics");
   end Test_Language_Model_Syntax_Tree_Generic_Formal_Part_Recovery;

   procedure Test_Ada_Generic_Formal_Package_Nested_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Formal_Package_Nested_Checks is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      with function Image (X : Element) return String is <>;" & ASCII.LF &
        "   package Element_G is" & ASCII.LF &
        "   end Element_G;" & ASCII.LF &
        "   function Int_Image (X : Integer) return String;" & ASCII.LF &
        "   function Bool_Image (X : Boolean) return String;" & ASCII.LF &
        "   package Int_Element is new Element_G (Integer, Int_Image);" & ASCII.LF &
        "   package Bool_Element is new Element_G (Boolean, Bool_Image);" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with package P is new Element_G (Integer, <>);" & ASCII.LF &
        "   package Outer is" & ASCII.LF &
        "   end Outer;" & ASCII.LF &
        "   package Good is new Outer (Int_Element);" & ASCII.LF &
        "   package Bad is new Outer (Bool_Element);" & ASCII.LF &
        "end Generic_Formal_Package_Nested_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Nested : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build (Tree, Contracts);
      Saw_Box_Compatible : Boolean := False;
      Saw_Mismatch : Boolean := False;
   begin
      Assert (Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_Count (Nested) >= 2,
              "formal package nested conformance must stage actual package checks");

      for Index in 1 .. Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_Count (Nested) loop
         declare
            Info : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Info :=
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_At (Nested, Index);
         begin
            if Info.Status = Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Box_Compatible then
               Saw_Box_Compatible := True;
            elsif Info.Status = Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Mismatch then
               Saw_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Saw_Box_Compatible,
              "formal package boxed nested actuals must allow matching actual package instances");
      Assert (Saw_Mismatch,
              "formal package nested actual mismatches must be retained explicitly");
      Assert (Editor.Ada_Generic_Formal_Package_Nested_Conformance.Compatible_Count (Nested) >= 1,
              "formal package nested conformance must expose compatible counters");
      Assert (Editor.Ada_Generic_Formal_Package_Nested_Conformance.Mismatch_Count (Nested) >= 1,
              "formal package nested conformance must expose mismatch counters");
      Assert (Editor.Ada_Generic_Formal_Package_Nested_Conformance.Fingerprint (Nested) /= 0,
              "formal package nested conformance must retain deterministic fingerprints");
   end Test_Ada_Generic_Formal_Package_Nested_Conformance;

   procedure Test_Ada_Generic_Formal_Package_Contract_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Item is private;" & ASCII.LF &
        "package Generic_Helper is" & ASCII.LF &
        "end Generic_Helper;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Other is private;" & ASCII.LF &
        "package Wrong_Helper is" & ASCII.LF &
        "end Wrong_Helper;" & ASCII.LF &
        "package Integer_Helper is new Generic_Helper (Integer);" & ASCII.LF &
        "package Integer_Wrong is new Wrong_Helper (Integer);" & ASCII.LF &
        "package Plain_Package is" & ASCII.LF &
        "end Plain_Package;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   with package Helper is new Generic_Helper (<>);" & ASCII.LF &
        "package Generic_Box is" & ASCII.LF &
        "end Generic_Box;" & ASCII.LF &
        "package Good_Box is new Generic_Box (Integer, Integer_Helper);" & ASCII.LF &
        "package Inline_Box is new Generic_Box (Integer, Helper => new Generic_Helper (Integer));" & ASCII.LF &
        "package Wrong_Box is new Generic_Box (Integer, Helper => Integer_Wrong);" & ASCII.LF &
        "package Plain_Box is new Generic_Box (Integer, Helper => Plain_Package);" & ASCII.LF &
        "package Unknown_Box is new Generic_Box (Integer, Helper => Missing_Helper);";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good : Boolean := False;
      Saw_Inline : Boolean := False;
      Saw_Wrong : Boolean := False;
      Saw_Plain : Boolean := False;
      Saw_Unknown : Boolean := False;
      Saw_Formal_Target : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
         declare
            Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Editor.Ada_Generic_Contracts.Formal_At (Contracts, Index);
         begin
            if To_String (Formal.Normalized_Name) = "helper" then
               Saw_Formal_Target :=
                 Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Package
                 and then To_String (Formal.Formal_Package_Normalized_Generic) = "generic_helper"
                 and then Formal.Formal_Package_Has_Box;
            end if;
         end;
      end loop;

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
                 and then Match.Formal_Package_Compatible_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Formal_Package_Compatible_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "inline_box" then
               Saw_Inline :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Formal_Package_Compatible_Formals = 1;
            elsif Name = "wrong_box" then
               Saw_Wrong :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Package_Contract_Mismatch
                 and then Match.Formal_Package_Wrong_Generic_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Formal_Package_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "plain_box" then
               Saw_Plain :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Package_Contract_Mismatch
                 and then Match.Formal_Package_Mismatched_Formals = 1
                 and then Match.Formal_Package_Not_Instance_Formals = 1;
            elsif Name = "unknown_box" then
               Saw_Unknown :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Package_Contract_Unknown
                 and then Match.Formal_Package_Unresolved_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Formal_Package_Unknown_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Formal_Target,
              "generic formal package contracts must retain the expected generic target and box state");
      Assert (Saw_Good and then Saw_Inline,
              "generic formal package contracts must accept matching named and inline package instances");
      Assert (Saw_Wrong and then Saw_Plain,
              "generic formal package contracts must reject wrong-generic and non-instance package actuals");
      Assert (Saw_Unknown,
              "generic formal package contracts must preserve unresolved actual metadata deterministically");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic formal package contract conformance must retain deterministic fingerprints");
   end Test_Ada_Generic_Formal_Package_Contract_Conformance;

   procedure Test_Ada_Generic_Formal_Package_Substitutions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status;
      use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Id;
      Source : constant String :=
        "package Generic_Formal_Package_Substitution_Checks is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      with function Image (X : Element) return String is <>;" & ASCII.LF &
        "   package Element_G is" & ASCII.LF &
        "   end Element_G;" & ASCII.LF &
        "   function Int_Image (X : Integer) return String;" & ASCII.LF &
        "   function Bool_Image (X : Boolean) return String;" & ASCII.LF &
        "   package Int_Element is new Element_G (Integer, Int_Image);" & ASCII.LF &
        "   package Bool_Element is new Element_G (Boolean, Bool_Image);" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with package P is new Element_G (Integer, <>);" & ASCII.LF &
        "   package Outer is" & ASCII.LF &
        "   end Outer;" & ASCII.LF &
        "   package Good is new Outer (Int_Element);" & ASCII.LF &
        "   package Bad is new Outer (Bool_Element);" & ASCII.LF &
        "end Generic_Formal_Package_Substitution_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Nested : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model :=
        Editor.Ada_Generic_Formal_Package_Nested_Conformance.Build (Tree, Contracts);
      Substitutions : constant Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Build (Nested);
      First : constant Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Info :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Substitution_At (Substitutions, 1);
      Again : constant Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Info :=
        Editor.Ada_Generic_Formal_Package_Substitutions.First_For_Formal
          (Substitutions, First.Instance, First.Formal);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Formal_Types : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model :=
        Editor.Ada_Generic_Formal_Type_Conformance.Build (Tree, Contracts, Types);
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
        Editor.Ada_Generic_Contract_Diagnostics.Build_With_Formal_Package_Substitutions
          (Formal_Types, Nested, Renamings, Object_Defaults, Generic_Views, Bodies, Substitutions);
      Last_Diag : constant Editor.Ada_Generic_Contract_Diagnostics.Generic_Contract_Diagnostic_Info :=
        Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_At
          (Diags, Editor.Ada_Generic_Contract_Diagnostics.Diagnostic_Count (Diags));
   begin
      Assert
        (Editor.Ada_Generic_Formal_Package_Substitutions.Substitution_Count (Substitutions) >= 4,
         "formal package substitutions must expand nested formal package checks into per-actual entries");
      Assert
        (Editor.Ada_Generic_Formal_Package_Substitutions.Substituted_Count (Substitutions) >= 1
         and then Editor.Ada_Generic_Formal_Package_Substitutions.Boxed_Count (Substitutions) >= 1
         and then Editor.Ada_Generic_Formal_Package_Substitutions.Mismatch_Count (Substitutions) >= 1,
         "formal package substitutions must classify substituted boxed and mismatched nested actuals");
      Assert
        (Again.Id /= Editor.Ada_Generic_Formal_Package_Substitutions.No_Formal_Package_Substitution
         and then First.Fingerprint /= 0
         and then Editor.Ada_Generic_Formal_Package_Substitutions.Fingerprint (Substitutions) /= 0,
         "formal package substitutions must preserve formal lookup identity and deterministic fingerprints");
      Assert
        (Editor.Ada_Generic_Contract_Diagnostics.Formal_Package_Substitution_Diagnostic_Count (Diags) >= 1
         and then Editor.Ada_Generic_Contract_Diagnostics.Formal_Package_Substitution_Mismatch_Count (Diags) >= 1,
         "generic contract diagnostics must project formal package substitution mismatches");
      Assert
        (Last_Diag.From_Formal_Package_Substitution
         and then Last_Diag.Formal_Package_Substitution /=
           Editor.Ada_Generic_Formal_Package_Substitutions.No_Formal_Package_Substitution
         and then Last_Diag.Formal_Package_Substitution_Fingerprint /= 0
         and then Length (Last_Diag.Detail) > 0,
         "formal package substitution diagnostics must preserve substitution identity fingerprint and detail");
   end Test_Ada_Generic_Formal_Package_Substitutions;

   overriding function Name (T : GenericFormalPackageContract_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Generic-Formal-Package-Contract");
   end Name;

   overriding procedure Register_Tests (T : in out GenericFormalPackageContract_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Generic_Formal_Package_Target_Metadata'Access, Name => "language model parser records generic formal package targets");
      Add_Test (Routine => Test_Split_Generic_Formal_Package_Target_Metadata'Access, Name => "language model parser records split generic formal package targets");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Package_Owns_Overload_Scope'Access, Name => "language model overload lookup accepts generic formal package scopes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Generic_Formal_Part_Recovery'Access, Name => "syntax tree implicitly closes generic formal parts before their generic unit");
      Add_Test (Routine => Test_Ada_Generic_Formal_Package_Nested_Conformance'Access, Name => "Ada generic formal package conformance checks nested formal actuals");
      Add_Test (Routine => Test_Ada_Generic_Formal_Package_Contract_Conformance'Access, Name => "Ada generic contract model checks formal package contract conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Package_Substitutions'Access, Name => "Ada generic formal package substitutions expand nested formal package contracts");
   end Register_Tests;

end Editor.Syntax_Semantics.Generic_Formal_Package_Contract_Tests;
