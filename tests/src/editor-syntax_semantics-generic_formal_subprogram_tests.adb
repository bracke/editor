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

package body Editor.Syntax_Semantics.Generic_Formal_Subprogram_Tests is








   procedure Test_Language_Model_Generic_Formal_Subprogram_Default_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with procedure Visit (Item : Element) is Default_Visit;" & ASCII.LF &
        "   with procedure Build" & ASCII.LF &
        "     (Item : Element) is" & ASCII.LF &
        "      Default_Build;" & ASCII.LF &
        "   with function Predicate (Item : Element) return Boolean is <>;" & ASCII.LF &
        "   with procedure Reset (Item : in out Element) is" & ASCII.LF &
        "      null;" & ASCII.LF &
        "package Formal_Subprogram_Defaults is" & ASCII.LF &
        "   type Element is tagged null record;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Formal_Subprogram_Defaults;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "formal_subprogram_defaults.ads");
      Visit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Visit");
      Build_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Build");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate");
      Reset_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Reset");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Visit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Visit_Id);
      Build_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Build_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Reset_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Reset_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Visit_Id /= Editor.Ada_Language_Model.No_Symbol,
              "generic formal subprogram with same-line default should parse");
      Assert (Visit_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Visit_Info.Flags.Is_Generic
              and then To_String (Visit_Info.Profile_Summary) = "(Item : Element)"
              and then To_String (Visit_Info.Target_Name) = "Default_Visit",
              "same-line formal subprogram default should be retained as target metadata");
      Assert (Build_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal subprogram with default should parse");
      Assert (Build_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Build_Info.Flags.Is_Generic
              and then To_String (Build_Info.Profile_Summary) = "(Item : Element)"
              and then To_String (Build_Info.Target_Name) = "Default_Build",
              "split formal subprogram default should be retained without opening a false body scope");
      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "generic formal function with box default should parse");
      Assert (Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Predicate_Info.Flags.Is_Generic
              and then To_String (Predicate_Info.Target_Name) = "<>",
              "box formal subprogram default should be retained as explicit target metadata");
      Assert (Reset_Id /= Editor.Ada_Language_Model.No_Symbol,
              "generic formal procedure with null default should parse");
      Assert (Reset_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Reset_Info.Flags.Is_Generic
              and then To_String (Reset_Info.Target_Name) = "null",
              "split null formal subprogram default should be retained as explicit target metadata");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol /= Build_Id,
              "formal-subprogram default continuation must not corrupt following declarations");
   end Test_Language_Model_Generic_Formal_Subprogram_Default_Target_Metadata;







   procedure Test_Ada_Generic_Formal_Subprogram_Profile_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "function Good_Image (Value : Integer) return String;" & ASCII.LF &
        "function Bad_Image (Left : Integer; Right : Integer) return String;" & ASCII.LF &
        "function Bad_Result (Value : Integer) return Integer;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   with function Image (Value : Element) return String;" & ASCII.LF &
        "package Generic_Printer is" & ASCII.LF &
        "end Generic_Printer;" & ASCII.LF &
        "package Good_Printer is new Generic_Printer (Integer, Good_Image);" & ASCII.LF &
        "package Bad_Arity_Printer is new Generic_Printer (Integer, Image => Bad_Image);" & ASCII.LF &
        "package Bad_Result_Printer is new Generic_Printer (Integer, Image => Bad_Result);";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good : Boolean := False;
      Saw_Bad_Arity : Boolean := False;
      Saw_Bad_Result : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance (Contracts, Instance.Id);
            Name : constant String := To_String (Instance.Normalized_Name);
         begin
            if Name = "good_printer" then
               Saw_Good :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1
                 and then Match.Subprogram_Profile_Mismatched_Formals = 0;
            elsif Name = "bad_arity_printer" then
               Saw_Bad_Arity :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Profile_Mismatch
                 and then Match.Subprogram_Profile_Mismatched_Formals = 1;
            elsif Name = "bad_result_printer" then
               Saw_Bad_Result :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Profile_Mismatch
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good,
              "generic formal subprogram conformance must accept matching actual profiles");
      Assert (Saw_Bad_Arity,
              "generic formal subprogram conformance must reject arity mismatches deterministically");
      Assert (Saw_Bad_Result,
              "generic formal subprogram conformance must reject result subtype mismatches deterministically");
   end Test_Ada_Generic_Formal_Subprogram_Profile_Conformance;





   procedure Test_Ada_Generic_Formal_Subprogram_Overload_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Overload_Generic_Actuals is" & ASCII.LF &
        "   procedure Convert (Value : Integer) is null;" & ASCII.LF &
        "   procedure Convert (Value : String) is null;" & ASCII.LF &
        "   procedure Ambiguous (Value : Integer) is null;" & ASCII.LF &
        "   procedure Ambiguous (Other : Integer) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      with procedure Visit (Value : Element);" & ASCII.LF &
        "   package Generic_Box is" & ASCII.LF &
        "   end Generic_Box;" & ASCII.LF &
        "   package Integer_Box is new Generic_Box (Integer, Convert);" & ASCII.LF &
        "   package String_Box is new Generic_Box (String, Convert);" & ASCII.LF &
        "   package Ambiguous_Box is new Generic_Box (Integer, Ambiguous);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Overload_Generic_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Integer : Boolean := False;
      Saw_String : Boolean := False;
      Saw_Ambiguous : Boolean := False;
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
            if Name = "integer_box" then
               Saw_Integer :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Overload_Candidates = 2
                 and then Match.Subprogram_Profile_Overload_Selected_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Overload_Selected_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "string_box" then
               Saw_String :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Overload_Candidates = 2
                 and then Match.Subprogram_Profile_Overload_Selected_Formals = 1;
            elsif Name = "ambiguous_box" then
               Saw_Ambiguous :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Profile_Ambiguous
                 and then Match.Subprogram_Profile_Overload_Candidates = 2
                 and then Match.Subprogram_Profile_Overload_Ambiguous_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Overload_Ambiguous_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Integer and then Saw_String,
              "generic subprogram actual matching must select the overload whose profile conforms to the formal profile");
      Assert (Saw_Ambiguous,
              "generic subprogram actual matching must preserve ambiguous conforming overload metadata deterministically");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic subprogram overload selection must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Overload_Selection;





   procedure Test_Ada_Generic_Formal_Subprogram_Mode_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Mode_Actuals is" & ASCII.LF &
        "   procedure Update (Value : in out Integer) is null;" & ASCII.LF &
        "   procedure Read_Only (Value : in Integer) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      with procedure Mutate (Value : in out Element);" & ASCII.LF &
        "   package Generic_Mutator is" & ASCII.LF &
        "   end Generic_Mutator;" & ASCII.LF &
        "   package Good_Mutator is new Generic_Mutator (Integer, Update);" & ASCII.LF &
        "   package Bad_Mutator is new Generic_Mutator (Integer, Read_Only);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Mode_Actuals;";
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
      Saw_Formal_Mode : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
         declare
            Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Editor.Ada_Generic_Contracts.Formal_At (Contracts, Index);
         begin
            if To_String (Formal.Normalized_Name) = "mutate" then
               Saw_Formal_Mode :=
                 To_String (Formal.Formal_Parameter_Modes) = "in out"
                 and then To_String (Formal.Formal_Parameter_Subtypes) = "element";
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance
                (Contracts, Instance.Id);
            Name : constant String := To_String (Instance.Normalized_Name);
         begin
            if Name = "good_mutator" then
               Saw_Good :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1
                 and then Match.Subprogram_Profile_Mode_Mismatched_Formals = 0;
            elsif Name = "bad_mutator" then
               Saw_Bad :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Mode_Mismatch
                 and then Match.Subprogram_Profile_Mode_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Mode_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Formal_Mode,
              "generic formal subprogram profiles must retain normalized parameter modes");
      Assert (Saw_Good,
              "generic formal subprogram mode conformance must accept matching modes");
      Assert (Saw_Bad,
              "generic formal subprogram mode conformance must reject same-subtype wrong-mode actuals");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "generic formal subprogram mode conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Mode_Conformance;





   procedure Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Type_Graph_Actuals is" & ASCII.LF &
        "   type Root is range 0 .. 100;" & ASCII.LF &
        "   subtype Small is Root range 0 .. 10;" & ASCII.LF &
        "   procedure Visit_Small (Value : Small) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "      with procedure Visit (Value : Element);" & ASCII.LF &
        "   package Generic_Visitor is" & ASCII.LF &
        "   end Generic_Visitor;" & ASCII.LF &
        "   package Raw_Text_Mismatch is new Generic_Visitor (Root, Visit_Small);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Type_Graph_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Text_Only : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Saw_Text_Mismatch : Boolean := False;
      Saw_Type_Graph_Compatible : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Text_Only) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Text_Only, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance
                (Text_Only, Instance.Id);
         begin
            if To_String (Instance.Normalized_Name) = "raw_text_mismatch" then
               Saw_Text_Mismatch :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Profile_Mismatch
                 and then Match.Subprogram_Profile_Mismatched_Formals = 1;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance
                (Contracts, Instance.Id);
         begin
            if To_String (Instance.Normalized_Name) = "raw_text_mismatch" then
               Saw_Type_Graph_Compatible :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1
                 and then Match.Subprogram_Profile_Type_Compatible_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Type_Compatible_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Text_Mismatch,
              "text-only generic subprogram profile conformance must still reject raw subtype-name mismatches");
      Assert (Saw_Type_Graph_Compatible,
              "type-graph generic subprogram profile conformance must accept known subtype relationships");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "type-graph generic profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance;






   procedure Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Null_Access_Actuals is" & ASCII.LF &
        "   procedure Target is null;" & ASCII.LF &
        "   procedure Accepts_Not_Null (Value : not null access procedure) is null;" & ASCII.LF &
        "   procedure Accepts_Nullable (Value : access procedure) is null;" & ASCII.LF &
        "   procedure Accepts_Int_Callback (Value : access procedure (X : Integer)) is null;" & ASCII.LF &
        "   procedure Accepts_Float_Callback (Value : access procedure (X : Float)) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : not null access procedure);" & ASCII.LF &
        "   package Needs_Not_Null is" & ASCII.LF &
        "   end Needs_Not_Null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : access procedure (X : Integer));" & ASCII.LF &
        "   package Needs_Int_Callback is" & ASCII.LF &
        "   end Needs_Int_Callback;" & ASCII.LF &
        "   package Good_Null is new Needs_Not_Null (Accepts_Not_Null);" & ASCII.LF &
        "   package Bad_Null is new Needs_Not_Null (Accepts_Nullable);" & ASCII.LF &
        "   package Good_Access is new Needs_Int_Callback (Accepts_Int_Callback);" & ASCII.LF &
        "   package Bad_Access is new Needs_Int_Callback (Accepts_Float_Callback);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Null_Access_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good_Null : Boolean := False;
      Saw_Bad_Null : Boolean := False;
      Saw_Good_Access : Boolean := False;
      Saw_Bad_Access : Boolean := False;
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
            if Name = "good_null" then
               Saw_Good_Null :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_null" then
               Saw_Bad_Null :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Null_Exclusion_Mismatch
                 and then Match.Subprogram_Profile_Null_Exclusion_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Null_Exclusion_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "good_access" then
               Saw_Good_Access :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_access" then
               Saw_Bad_Access :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Access_Profile_Mismatch
                 and then Match.Subprogram_Profile_Access_Profile_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Access_Profile_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good_Null,
              "generic formal subprogram conformance must accept matching null-exclusion profiles");
      Assert (Saw_Bad_Null,
              "generic formal subprogram conformance must separate null-exclusion mismatches from generic profile mismatches");
      Assert (Saw_Good_Access,
              "generic formal subprogram conformance must accept matching access-to-subprogram profiles");
      Assert (Saw_Bad_Access,
              "generic formal subprogram conformance must separate access-profile mismatches from generic profile mismatches");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "null/access profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance;






   procedure Test_Ada_Generic_Formal_Subprogram_Convention_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Convention_Actuals is" & ASCII.LF &
        "   procedure Ada_Proc (Value : Integer) is null;" & ASCII.LF &
        "   procedure C_Proc (Value : Integer) with Import, Convention => C;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : Integer) with Convention => C;" & ASCII.LF &
        "   package Needs_C is" & ASCII.LF &
        "   end Needs_C;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : Integer);" & ASCII.LF &
        "   package Needs_Ada is" & ASCII.LF &
        "   end Needs_Ada;" & ASCII.LF &
        "   package Good_C is new Needs_C (C_Proc);" & ASCII.LF &
        "   package Bad_C is new Needs_C (Ada_Proc);" & ASCII.LF &
        "   package Good_Ada is new Needs_Ada (Ada_Proc);" & ASCII.LF &
        "   package Bad_Ada is new Needs_Ada (C_Proc);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Convention_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good_C : Boolean := False;
      Saw_Bad_C : Boolean := False;
      Saw_Good_Ada : Boolean := False;
      Saw_Bad_Ada : Boolean := False;
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
            if Name = "good_c" then
               Saw_Good_C :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_c" then
               Saw_Bad_C :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Convention_Mismatch
                 and then Match.Subprogram_Profile_Convention_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Convention_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "good_ada" then
               Saw_Good_Ada :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_ada" then
               Saw_Bad_Ada :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Convention_Mismatch
                 and then Match.Subprogram_Profile_Convention_Mismatched_Formals = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good_C,
              "generic formal subprogram conformance must accept matching explicit C convention");
      Assert (Saw_Bad_C,
              "generic formal subprogram conformance must reject Ada actuals for C formals");
      Assert (Saw_Good_Ada,
              "generic formal subprogram conformance must accept default Ada convention");
      Assert (Saw_Bad_Ada,
              "generic formal subprogram conformance must reject C actuals for default-Ada formals");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "subprogram convention conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Convention_Conformance;






   procedure Test_Ada_Generic_Formal_Subprogram_Default_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Defaulted_Profile_Actuals is" & ASCII.LF &
        "   procedure Actual_With_Default (Value : Integer := 0) is null;" & ASCII.LF &
        "   procedure Actual_Required (Value : Integer) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : Integer := 0);" & ASCII.LF &
        "   package Needs_Default is" & ASCII.LF &
        "   end Needs_Default;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : Integer);" & ASCII.LF &
        "   package Allows_Required is" & ASCII.LF &
        "   end Allows_Required;" & ASCII.LF &
        "   package Good_Default is new Needs_Default (Actual_With_Default);" & ASCII.LF &
        "   package Bad_Default is new Needs_Default (Actual_Required);" & ASCII.LF &
        "   package Good_Required is new Allows_Required (Actual_Required);" & ASCII.LF &
        "   package Good_Required_Defaulted_Actual is new Allows_Required (Actual_With_Default);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Defaulted_Profile_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good_Default : Boolean := False;
      Saw_Bad_Default : Boolean := False;
      Saw_Good_Required : Boolean := False;
      Saw_Good_Required_Defaulted_Actual : Boolean := False;
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
            if Name = "good_default" then
               Saw_Good_Default :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_default" then
               Saw_Bad_Default :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Default_Mismatch
                 and then Match.Subprogram_Profile_Default_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Default_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "good_required" then
               Saw_Good_Required :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "good_required_defaulted_actual" then
               Saw_Good_Required_Defaulted_Actual :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good_Default,
              "generic formal subprogram conformance must accept matching defaulted parameters");
      Assert (Saw_Bad_Default,
              "generic formal subprogram conformance must reject required actual parameters where the formal contract exposes a default");
      Assert (Saw_Good_Required,
              "generic formal subprogram conformance must accept required actuals for required formal parameters");
      Assert (Saw_Good_Required_Defaulted_Actual,
              "generic formal subprogram conformance must accept defaulted actual parameters when the formal does not require a default");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "defaulted-parameter profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Default_Conformance;





   procedure Test_Ada_Generic_Formal_Subprogram_Class_Wide_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Class_Wide_Profile_Actuals is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   procedure Actual_Class (Value : Root'Class) is null;" & ASCII.LF &
        "   procedure Actual_Specific (Value : Root) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : Root'Class);" & ASCII.LF &
        "   package Needs_Class is" & ASCII.LF &
        "   end Needs_Class;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Value : Root);" & ASCII.LF &
        "   package Needs_Specific is" & ASCII.LF &
        "   end Needs_Specific;" & ASCII.LF &
        "   package Good_Class is new Needs_Class (Actual_Class);" & ASCII.LF &
        "   package Bad_Class is new Needs_Class (Actual_Specific);" & ASCII.LF &
        "   package Good_Specific is new Needs_Specific (Actual_Specific);" & ASCII.LF &
        "   package Bad_Specific is new Needs_Specific (Actual_Class);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Class_Wide_Profile_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good_Class : Boolean := False;
      Saw_Bad_Class : Boolean := False;
      Saw_Good_Specific : Boolean := False;
      Saw_Bad_Specific : Boolean := False;
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
            if Name = "good_class" then
               Saw_Good_Class :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_class" then
               Saw_Bad_Class :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch
                 and then Match.Subprogram_Profile_Class_Wide_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "good_specific" then
               Saw_Good_Specific :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_specific" then
               Saw_Bad_Specific :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch
                 and then Match.Subprogram_Profile_Class_Wide_Mismatched_Formals = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good_Class,
              "generic formal subprogram conformance must accept matching class-wide controlling profiles");
      Assert (Saw_Bad_Class,
              "generic formal subprogram conformance must reject specific actuals where the formal expects class-wide dispatching");
      Assert (Saw_Good_Specific,
              "generic formal subprogram conformance must accept matching specific profiles");
      Assert (Saw_Bad_Specific,
              "generic formal subprogram conformance must reject class-wide actuals where the formal expects specific controlling profiles");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "class-wide profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Class_Wide_Conformance;





   procedure Test_Ada_Generic_Formal_Subprogram_Name_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Named_Profile_Actuals is" & ASCII.LF &
        "   procedure Actual_Named (Left : Integer; Right : Integer) is null;" & ASCII.LF &
        "   procedure Actual_Renamed (X : Integer; Y : Integer) is null;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Combine (Left : Integer; Right : Integer);" & ASCII.LF &
        "   package Needs_Names is" & ASCII.LF &
        "   end Needs_Names;" & ASCII.LF &
        "   package Good_Names is new Needs_Names (Actual_Named);" & ASCII.LF &
        "   package Bad_Names is new Needs_Names (Actual_Renamed);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Named_Profile_Actuals;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Contracts : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Saw_Good_Names : Boolean := False;
      Saw_Bad_Names : Boolean := False;
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
            if Name = "good_names" then
               Saw_Good_Names :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1;
            elsif Name = "bad_names" then
               Saw_Bad_Names :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Name_Mismatch
                 and then Match.Subprogram_Profile_Name_Mismatched_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Name_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good_Names,
              "generic formal subprogram conformance must accept matching parameter names");
      Assert (Saw_Bad_Names,
              "generic formal subprogram conformance must reject same-shape actuals with nonconforming parameter names");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "parameter-name profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Name_Conformance;





   procedure Test_Ada_Generic_Formal_Subprogram_Result_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Generic_Result_Profile_Actuals is" & ASCII.LF &
        "   subtype Small_Int is Integer range 1 .. 10;" & ASCII.LF &
        "   function Make_Small return Small_Int is (1);" & ASCII.LF &
        "   function Make_Float return Float is (1.0);" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with function Make return Integer;" & ASCII.LF &
        "   package Needs_Result is" & ASCII.LF &
        "   end Needs_Result;" & ASCII.LF &
        "   package Good_Result is new Needs_Result (Make_Small);" & ASCII.LF &
        "   package Bad_Result is new Needs_Result (Make_Float);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Generic_Result_Profile_Actuals;";
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
      Saw_Good_Result : Boolean := False;
      Saw_Bad_Result : Boolean := False;
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
            if Name = "good_result" then
               Saw_Good_Result :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
                 and then Match.Subprogram_Profile_Compatible_Formals = 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Result_Compatible_Count_For_Instance
                   (Contracts, Instance.Id) = 1;
            elsif Name = "bad_result" then
               Saw_Bad_Result :=
                 Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Subprogram_Result_Mismatch
                 and then Match.Subprogram_Profile_Result_Mismatched_Formals >= 1
                 and then Editor.Ada_Generic_Contracts.Subprogram_Profile_Result_Mismatch_Count_For_Instance
                   (Contracts, Instance.Id) >= 1;
            end if;
         end;
      end loop;

      Assert (Saw_Good_Result,
              "generic formal subprogram result conformance must accept subtype-compatible function results through the type graph");
      Assert (Saw_Bad_Result,
              "generic formal subprogram result conformance must reject incompatible function result subtypes");
      Assert (Editor.Ada_Generic_Contracts.Fingerprint (Contracts) /= 0,
              "result-subtype profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Generic_Formal_Subprogram_Result_Conformance;


   overriding function Name (T : Generic_Formal_Subprogram_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Generic.Formal_Subprogram");
   end Name;

   overriding procedure Register_Tests (T : in out Generic_Formal_Subprogram_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Subprogram_Default_Target_Metadata'Access, Name => "language model parser retains generic formal subprogram default target/box/null metadata");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Profile_Conformance'Access, Name => "Ada generic contract model checks formal subprogram profile conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Overload_Selection'Access, Name => "Ada generic contract model selects overloaded subprogram actuals by formal profile");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Mode_Conformance'Access, Name => "Ada generic contract model checks formal subprogram parameter mode conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance'Access, Name => "Ada generic contract model checks type-graph subprogram profile conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance'Access, Name => "Ada generic contract model checks null-exclusion and access-profile subprogram conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Convention_Conformance'Access, Name => "Ada generic contract model checks formal subprogram convention conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Default_Conformance'Access, Name => "Ada generic contract model checks formal subprogram defaulted-parameter conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Class_Wide_Conformance'Access, Name => "Ada generic contract model checks formal subprogram class-wide profile conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Name_Conformance'Access, Name => "Ada generic contract model checks formal subprogram parameter-name conformance");
      Add_Test (Routine => Test_Ada_Generic_Formal_Subprogram_Result_Conformance'Access, Name => "Ada generic contract model checks formal subprogram result-subtype conformance");
   end Register_Tests;

end Editor.Syntax_Semantics.Generic_Formal_Subprogram_Tests;
