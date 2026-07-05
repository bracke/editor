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

package body Editor.Syntax_Semantics.Generic_Tail_Tests is





   procedure Test_Language_Model_Same_Line_Generic_Formal_Marker_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Generic_Formal_Marker_Tail is" & ASCII.LF &
        "   generic; type Element is private; with procedure Visit (Item : Element); package Compact is end Compact;" & ASCII.LF &
        "   generic; type Index is range <>; with function Make return Element is Default_Element; function Compact_Function return Element;" & ASCII.LF &
        "end Same_Line_Generic_Formal_Marker_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_generic_formal_marker_tail.ads");
      Element_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element");
      Visit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Visit");
      Compact_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make");
      Compact_Function_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Function");
      Element_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Id);
      Visit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Visit_Id);
      Compact_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compact_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      Make_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Id);
      Compact_Function_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compact_Function_Id);
   begin
      Assert (Element_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Element_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Element_Info.Flags.Is_Generic
              and then Element_Info.Flags.Is_Private,
              "compact generic marker should retain same-line formal type");
      Assert (Visit_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Visit_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Visit_Info.Flags.Is_Generic,
              "compact generic marker should retain same-line formal procedure");
      Assert (Compact_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Compact_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Compact_Info.Flags.Is_Generic,
              "compact generic marker should still apply to the same-line package unit after formals");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Index_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Index_Info.Flags.Is_Generic,
              "second compact generic marker should retain same-line discrete formal type");
      Assert (Make_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Make_Info.Flags.Is_Generic
              and then To_String (Make_Info.Target_Name) = "Element",
              "same-line formal function should retain return target metadata");
      Assert (Compact_Function_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Compact_Function_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram
              and then Compact_Function_Info.Flags.Is_Generic
              and then To_String (Compact_Function_Info.Target_Name) = "Element",
              "compact generic marker should apply to same-line generic function after formals");
   end Test_Language_Model_Same_Line_Generic_Formal_Marker_Tail;





   procedure Test_Language_Model_Generic_One_Line_Package_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Compact is Inner_A : Integer; Inner_B : Boolean; end Generic_Compact;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_one_line_package_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Compact");
      Inner_A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_A");
      Inner_B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_B");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Inner_A_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_A_Id);
      Inner_B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_B_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Package_Info.Flags.Is_Generic,
              "compact generic package unit should retain generic package classification");
      Assert (Inner_A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_A_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Inner_A_Info.Parent_Symbol = Package_Id,
              "first declaration in compact generic package tail should be package-local");
      Assert (Inner_B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_B_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Inner_B_Info.Parent_Symbol = Package_Id
              and then Inner_B_Info.Declaration_Column > Inner_A_Info.Declaration_Column,
              "second declaration in compact generic package tail should not leak to the enclosing scope");
   end Test_Language_Model_Generic_One_Line_Package_Tail;





   procedure Test_Language_Model_Generic_Expression_Function_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; function Generic_Compute (Left : Integer; Right : Integer) return Integer is (Left + Right); After_Compute : Integer;" & ASCII.LF &
        "generic; procedure Generic_Done is null; After_Done : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_expression_function_tail.ads");
      Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Compute");
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Left", Compute_Id);
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Right", Compute_Id);
      After_Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Compute");
      Done_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Done");
      After_Done_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Done");
      Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compute_Id);
      After_Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Compute_Id);
      Done_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Done_Id);
      After_Done_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Done_Id);
   begin
      Assert (Compute_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Compute_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram
              and then Compute_Info.Flags.Is_Generic
              and then To_String (Compute_Info.Target_Name) = "Integer",
              "compact generic expression function should retain generic subprogram classification and return target");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Id /= Editor.Ada_Language_Model.No_Symbol,
              "generic expression-function profile parameters should remain callable-local");
      Assert (After_Compute_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Compute_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Compute_Info.Declaration_Column > Compute_Info.Declaration_Column,
              "declarations after compact generic expression function should not be swallowed by generic-unit nesting");
      Assert (Done_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Done_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Subprogram
              and then Done_Info.Flags.Is_Generic,
              "compact generic null procedure should parse as a complete generic subprogram");
      Assert (After_Done_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Done_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Done_Info.Declaration_Column > Done_Info.Declaration_Column,
              "declarations after compact generic null procedure should not wait for a synthetic end");
   end Test_Language_Model_Generic_Expression_Function_Tail;





   procedure Test_Language_Model_Generic_Package_Callable_Named_End_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Named_End_Tail is procedure Run is begin null; end Run; After_Run : Integer; end Generic_Named_End_Tail; Outside_Generic : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_package_callable_named_end_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Named_End_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outside_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outside_Generic");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outside_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outside_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Package_Info.Flags.Is_Generic,
              "compact generic package should keep generic package classification");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Package_Id,
              "nested callable body should remain under the compact generic package");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "end Run must not close the compact generic package tail before the package end");
      Assert (Outside_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outside_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outside_Info.Parent_Symbol = Editor.Ada_Language_Model.No_Symbol
              and then Outside_Info.Declaration_Column > After_Run_Info.Declaration_Column,
              "declarations after the exact compact generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Callable_Named_End_Tail;





   procedure Test_Language_Model_Generic_Package_Anonymous_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Anonymous_Block_Tail is procedure Run is begin declare Block_Local : Integer; begin null; end; Local_After : Integer; end Run; After_Run : Integer; end Generic_Anonymous_Block_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_anonymous_block_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Anonymous_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Block_Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Block_Local", Run_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Block_Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Block_Local_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package,
              "compact generic package should retain generic classification");
      Assert (Block_Local_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Block_Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Block_Local_Info.Parent_Symbol = Run_Id,
              "anonymous declare-block locals should remain callable-local inside generic package");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "anonymous block end must not close the compact generic package unit");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after nested callable end stay inside the generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id,
              "declarations after the generic package end resume outside");
   end Test_Language_Model_Generic_Package_Anonymous_Block_Tail;






   procedure Test_Language_Model_Generic_Package_Bare_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Bare_Block_Tail is procedure Run is begin begin null; end; Local_After : Integer; end Run; After_Run : Integer; end Generic_Bare_Block_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_bare_block_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Bare_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Package_Info.Flags.Is_Generic,
              "compact generic package should retain generic classification");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Package_Id,
              "nested callable should remain under the compact generic package");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "bare block end must not close the compact generic callable tail");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after nested callable end stay inside the generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id
              and then Outer_After_Info.Declaration_Column > After_Run_Info.Declaration_Column,
              "declarations after generic package end resume outside");
   end Test_Language_Model_Generic_Package_Bare_Block_Tail;






   procedure Test_Language_Model_Generic_Package_Anonymous_Block_Control_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Anonymous_Block_Control_Tail is procedure Run is begin declare Block_Local : Integer; begin if Ready then null; end if; end; Local_After : Integer; end Run; After_Run : Integer; end Generic_Anonymous_Block_Control_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_anonymous_block_control_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Anonymous_Block_Control_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package,
              "compact generic package should retain generic classification for anonymous-block control test");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "end if inside generic anonymous block must not close the compact callable/generic tail early");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after the callable end should remain inside the generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id,
              "declarations after the generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Anonymous_Block_Control_Tail;





   procedure Test_Language_Model_Generic_Package_Anonymous_Block_Local_Callable_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Anonymous_Block_Local_Callable_Tail is procedure Run is begin Local_Block : declare procedure Local_Run is begin null; end Local_Run; After_Local : Integer; begin null; end Local_Block; After_Declare : Integer; end Run; After_Run : Integer; end Generic_Anonymous_Block_Local_Callable_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_anonymous_block_local_callable_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "Generic_Anonymous_Block_Local_Callable_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Local_Run", Run_Id);
      After_Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "After_Local", Run_Id);
      After_Declare_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "After_Declare", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Local_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Run_Id);
      After_Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Local_Id);
      After_Declare_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Declare_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package,
              "compact generic package should retain generic classification");
      Assert (Local_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Local_Run_Info.Parent_Symbol = Run_Id,
              "local callable inside generic anonymous declare block should stay callable-local");
      Assert (After_Local_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Local_Info.Parent_Symbol = Run_Id,
              "local callable end must not consume the generic anonymous declare-block end");
      Assert (After_Declare_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Declare_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Declare_Info.Parent_Symbol = Run_Id,
              "named declare-block end should not close the compact generic callable tail");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should resume in the generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id,
              "declarations after the generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Anonymous_Block_Local_Callable_Tail;





   procedure Test_Language_Model_Generic_Package_Labelled_Begin_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Labelled_Begin_Block_Tail is procedure Run is begin Local_Block : begin null; end Local_Block; Local_After : Integer; end Run; After_Run : Integer; end Generic_Labelled_Begin_Block_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_labelled_begin_block_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Labelled_Begin_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package,
              "compact generic package should retain generic classification for labelled begin-block test");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "labelled bare begin-block end must not close compact generic callable tail early");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should remain inside the generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id,
              "declarations after generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Labelled_Begin_Block_Tail;





   procedure Test_Language_Model_Generic_Package_Accept_Without_Do_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Accept_Without_Do_Tail is procedure Run is begin accept Leave; Local_After : Integer; end Run; After_Run : Integer; end Generic_Accept_Without_Do_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_accept_without_do_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Accept_Without_Do_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package,
              "compact generic package should be emitted for accept-without-do tail test");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "accept without do must not keep generic anonymous nesting open");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after nested callable end should remain inside generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id,
              "declarations after generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Accept_Without_Do_Tail;





   procedure Test_Language_Model_Generic_Package_Callable_Control_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Control_Tail is procedure Run is begin if Ready then null; end if; end Run; After_Run : Integer; end Generic_Control_Tail; Outside_Generic : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_package_callable_control_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Control_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outside_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outside_Generic");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outside_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outside_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Package_Info.Flags.Is_Generic,
              "compact generic package should retain generic package classification");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Package_Id,
              "nested callable body should remain generic-package local");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "end if inside nested callable must not close the compact generic package tail");
      Assert (Outside_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outside_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outside_Info.Parent_Symbol = Editor.Ada_Language_Model.No_Symbol
              and then Outside_Info.Declaration_Column > After_Run_Info.Declaration_Column,
              "declarations after the compact generic package end should resume outside the generic package");
   end Test_Language_Model_Generic_Package_Callable_Control_Tail;





   procedure Test_Language_Model_Generic_Package_Protected_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Protected_Tail is protected type Lock_Box is procedure Enter; entry Leave; end Lock_Box; After_Lock : Integer; end Generic_Protected_Tail; Outside_Generic : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_package_protected_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Protected_Tail");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Lock_Box", Package_Id);
      Enter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enter", Lock_Id);
      Leave_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Leave", Lock_Id);
      After_Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Lock", Package_Id);
      Outside_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outside_Generic");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Enter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Enter_Id);
      Leave_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Leave_Id);
      After_Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Lock_Id);
      Outside_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outside_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package
              and then Package_Info.Flags.Is_Generic,
              "compact generic package should retain generic package classification with concurrent children");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected
              and then Lock_Info.Parent_Symbol = Package_Id,
              "compact protected type should remain under the compact generic package");
      Assert (Enter_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enter_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Enter_Info.Parent_Symbol = Lock_Id,
              "protected operation should remain protected-scope local in compact generic packages");
      Assert (Leave_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Leave_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Leave_Info.Parent_Symbol = Lock_Id,
              "protected entry should remain protected-scope local in compact generic packages");
      Assert (After_Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Lock_Info.Parent_Symbol = Package_Id,
              "declarations after compact protected scope should resume in the generic package");
      Assert (Outside_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outside_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outside_Info.Parent_Symbol = Editor.Ada_Language_Model.No_Symbol
              and then Outside_Info.Declaration_Column > After_Lock_Info.Declaration_Column,
              "declarations after compact generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Protected_Tail;





   procedure Test_Language_Model_Generic_Package_Anonymous_Block_Case_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Generic_Anonymous_Block_Case_Tail is procedure Run is begin declare Block_Local : Integer; begin case Block_Local is when others => null; end case; end; Local_After : Integer; end Run; After_Run : Integer; end Generic_Anonymous_Block_Case_Tail; Outer_After : Integer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_anonymous_block_case_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Anonymous_Block_Case_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Package,
              "compact generic package should retain generic classification for anonymous case-block test");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "end case inside generic anonymous block must not close compact callable/generic tails early");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should remain inside the generic package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol /= Package_Id,
              "declarations after generic package end should resume outside");
   end Test_Language_Model_Generic_Package_Anonymous_Block_Case_Tail;





   procedure Test_Language_Model_Generic_Tail_Rejects_Nameless_Package
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package is Hidden_Value : Integer; end; After_Generic : Integer;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "malformed_generic_package_tail.ads");
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "is");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Generic");
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "malformed compact generic package tail must not emit Ada keyword as a package name");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind in
                Editor.Ada_Language_Model.Symbol_Object |
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "declarations after malformed compact generic package text should remain visible and bounded");
   end Test_Language_Model_Generic_Tail_Rejects_Nameless_Package;





   procedure Test_Language_Model_Generic_Tail_Rejects_Nameless_Callable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; function return Integer is Local_Value : Integer; begin null; end; After_Generic : Integer;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "malformed_generic_callable_tail.ads");
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "return");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Generic");
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "malformed compact generic callable tail must not emit Ada keyword as a function name");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind in
                Editor.Ada_Language_Model.Symbol_Object |
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "declarations after malformed compact generic callable text should remain visible and bounded");
   end Test_Language_Model_Generic_Tail_Rejects_Nameless_Callable;





   procedure Test_Language_Model_Generic_Tail_Rejects_Reserved_Owner_Words
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package private is Hidden_Value : Integer; end; After_Generic : Integer;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_reserved_owner_tail.ads");
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "private");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Generic");
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "generic compact tail parser must not emit Ada reserved words as owner symbols");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind in
                Editor.Ada_Language_Model.Symbol_Object |
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "declarations after reserved-word generic owner text should remain visible and bounded");
   end Test_Language_Model_Generic_Tail_Rejects_Reserved_Owner_Words;





   procedure Test_Language_Model_Generic_Tail_Rejects_Invalid_Quoted_Operator_Owner
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; function ""bogus"" return Integer is Local_Value : Integer; begin null; end ""bogus""; After_Generic : Integer; function ""+"" return Integer is (1);";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_invalid_quoted_operator_tail.ads");
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """bogus""");
      Valid_Operator_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """+""");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Generic");
      Valid_Operator_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Valid_Operator_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "generic compact tail parser must not emit arbitrary quoted strings as operator-function owners");
      Assert (Valid_Operator_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Valid_Operator_Info.Kind = Editor.Ada_Language_Model.Symbol_Operator_Function,
              "valid quoted Ada operator functions should remain accepted after generic compact tails");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind in
                Editor.Ada_Language_Model.Symbol_Object |
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "declarations after invalid quoted generic owner text should remain visible and bounded");
   end Test_Language_Model_Generic_Tail_Rejects_Invalid_Quoted_Operator_Owner;





   procedure Test_Language_Model_Generic_Tail_Rejects_Invalid_Identifier_Owner
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic; package Bad_ is Hidden_Value : Integer; end Bad_; After_Generic : Integer; package Good_Name is Good_Local : Integer; end Good_Name;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "generic_invalid_identifier_owner_tail.ads");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_");
      Good_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Name");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Generic");
      Good_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Good_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Bad_Id = Editor.Ada_Language_Model.No_Symbol,
              "generic compact tail parser must not emit invalid Ada identifier owners");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind in
                Editor.Ada_Language_Model.Symbol_Object |
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "declarations after invalid generic owner text should remain visible and bounded");
      Assert (Good_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Good_Info.Kind in
                Editor.Ada_Language_Model.Symbol_Package |
                Editor.Ada_Language_Model.Symbol_Generic_Package,
              "valid generic compact owner identifiers should remain accepted");
   end Test_Language_Model_Generic_Tail_Rejects_Invalid_Identifier_Owner;


   overriding function Name (T : Generic_Tail_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Generic.Tail");
   end Name;

   overriding procedure Register_Tests (T : in out Generic_Tail_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Same_Line_Generic_Formal_Marker_Tail'Access, Name => "language model parser retains same-line generic marker formal tails");
      Add_Test (Routine => Test_Language_Model_Generic_One_Line_Package_Tail'Access, Name => "language model parser keeps compact generic package tails package-local");
      Add_Test (Routine => Test_Language_Model_Generic_Expression_Function_Tail'Access, Name => "language model parser keeps compact generic expression functions from capturing tails");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Callable_Named_End_Tail'Access, Name => "language model parser matches compact generic package ends exactly");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Anonymous_Block_Tail'Access, Name => "language model parser keeps anonymous block ends inside compact generic package tails");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Bare_Block_Tail'Access, Name => "language model parser keeps bare begin/end blocks inside compact generic tails");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Anonymous_Block_Control_Tail'Access, Name => "language model parser keeps control ends inside anonymous blocks in compact generic tails");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Anonymous_Block_Local_Callable_Tail'Access, Name => "language model parser keeps local callable ends inside generic anonymous compact declare blocks");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Labelled_Begin_Block_Tail'Access, Name => "language model parser keeps labelled begin/end blocks inside compact generic tails");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Accept_Without_Do_Tail'Access, Name => "language model parser does not treat generic accept without do as anonymous nesting");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Callable_Control_Tail'Access, Name => "language model parser keeps compact generic package callable control tails package-local");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Protected_Tail'Access, Name => "language model parser keeps compact generic package protected tails protected-scope local");
      Add_Test (Routine => Test_Language_Model_Generic_Package_Anonymous_Block_Case_Tail'Access, Name => "language model parser keeps end case inside generic anonymous compact blocks");
      Add_Test (Routine => Test_Language_Model_Generic_Tail_Rejects_Nameless_Package'Access, Name => "language model parser rejects nameless compact generic package tail owners");
      Add_Test (Routine => Test_Language_Model_Generic_Tail_Rejects_Nameless_Callable'Access, Name => "language model parser rejects nameless compact generic callable tail owners");
      Add_Test (Routine => Test_Language_Model_Generic_Tail_Rejects_Reserved_Owner_Words'Access, Name => "language model parser rejects reserved-word compact generic tail owners");
      Add_Test (Routine => Test_Language_Model_Generic_Tail_Rejects_Invalid_Quoted_Operator_Owner'Access, Name => "language model parser rejects invalid quoted compact generic operator owners");
      Add_Test (Routine => Test_Language_Model_Generic_Tail_Rejects_Invalid_Identifier_Owner'Access, Name => "language model parser rejects invalid compact generic owner identifiers");
   end Register_Tests;

end Editor.Syntax_Semantics.Generic_Tail_Tests;
