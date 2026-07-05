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

package body Editor.Syntax_Semantics.Representation_Gnat_Unification_Tests is

   procedure Test_Language_Model_GNAT_SPARK_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with SPARK_Mode => On, Annotate => (GNATprove, Intentional), Warnings => True is" & ASCII.LF &
        "   procedure Run with Test_Case => (Name => ""Smoke"", Mode => Nominal), Side_Effects, No_Caching;" & ASCII.LF &
        "   for P'SPARK_Mode use Off;" & ASCII.LF &
        "   for P'Annotate use (GNATprove, Intentional);" & ASCII.LF &
        "   for P'Warnings use False;" & ASCII.LF &
        "   for Run'Test_Case use (Name => ""Again"", Mode => Nominal);" & ASCII.LF &
        "   for Run'Side_Effects use False;" & ASCII.LF &
        "   for Run'No_Caching use False;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      Seen_SPARK_Aspect : Boolean := False;
      Seen_SPARK_Clause : Boolean := False;
      Seen_Annotate_Aspect : Boolean := False;
      Seen_Annotate_Clause : Boolean := False;
      Seen_Warnings_Aspect : Boolean := False;
      Seen_Warnings_Clause : Boolean := False;
      Seen_Test_Case_Aspect : Boolean := False;
      Seen_Test_Case_Clause : Boolean := False;
      Seen_Side_Effects_Aspect : Boolean := False;
      Seen_Side_Effects_Clause : Boolean := False;
      Seen_No_Caching_Aspect : Boolean := False;
      Seen_No_Caching_Clause : Boolean := False;
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target should be retained");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Item : constant String := To_String (R.Item_Text);
         begin
            if R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_SPARK_Mode_Clause
            then
               if Item = "On" then
                  Seen_SPARK_Aspect := True;
               elsif Item = "Off" then
                  Seen_SPARK_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Annotate_Clause
            then
               if Item = "(GNATprove, Intentional)" then
                  if not Seen_Annotate_Aspect then
                     Seen_Annotate_Aspect := True;
                  else
                     Seen_Annotate_Clause := True;
                  end if;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Warnings_Clause
            then
               if Item = "True" then
                  Seen_Warnings_Aspect := True;
               elsif Item = "False" then
                  Seen_Warnings_Clause := True;
               end if;
            elsif R.Target_Symbol = Run_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Test_Case_Clause
            then
               if Item = "(Name => ""Smoke"", Mode => Nominal)" then
                  Seen_Test_Case_Aspect := True;
               elsif Item = "(Name => ""Again"", Mode => Nominal)" then
                  Seen_Test_Case_Clause := True;
               end if;
            elsif R.Target_Symbol = Run_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Side_Effects_Clause
            then
               if Item = "True" then
                  Seen_Side_Effects_Aspect := True;
               elsif Item = "False" then
                  Seen_Side_Effects_Clause := True;
               end if;
            elsif R.Target_Symbol = Run_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Caching_Clause
            then
               if Item = "True" then
                  Seen_No_Caching_Aspect := True;
               elsif Item = "False" then
                  Seen_No_Caching_Clause := True;
               end if;
            end if;
         end;
      end loop;

      Assert (Seen_SPARK_Aspect and then Seen_SPARK_Clause,
              "SPARK_Mode aspect and attribute clause should share the explicit kind");
      Assert (Seen_Annotate_Aspect and then Seen_Annotate_Clause,
              "Annotate aspect and attribute clause should share the explicit kind");
      Assert (Seen_Warnings_Aspect and then Seen_Warnings_Clause,
              "Warnings aspect and attribute clause should share the explicit kind");
      Assert (Seen_Test_Case_Aspect and then Seen_Test_Case_Clause,
              "Test_Case aspect and attribute clause should share the explicit kind");
      Assert (Seen_Side_Effects_Aspect and then Seen_Side_Effects_Clause,
              "Side_Effects aspect and attribute clause should share the explicit kind");
      Assert (Seen_No_Caching_Aspect and then Seen_No_Caching_Clause,
              "No_Caching aspect and attribute clause should share the explicit kind");
   end Test_Language_Model_GNAT_SPARK_Operational_Unification_Pass;

   procedure Test_Language_Model_GNAT_SPARK_Entity_Pragma_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "   pragma Side_Effects (Run);" & ASCII.LF &
        "   pragma No_Caching (Run);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      Seen_Side_Effects_Pragma : Boolean := False;
      Seen_No_Caching_Pragma : Boolean := False;
   begin
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Item : constant String := To_String (R.Item_Text);
         begin
            if R.Target_Symbol = Run_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Side_Effects_Clause
              and then Item = "True"
            then
               Seen_Side_Effects_Pragma := True;
            elsif R.Target_Symbol = Run_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Caching_Clause
              and then Item = "True"
            then
               Seen_No_Caching_Pragma := True;
            end if;
         end;
      end loop;

      Assert (Seen_Side_Effects_Pragma,
              "pragma Side_Effects should lower through the shared operational property path");
      Assert (Seen_No_Caching_Pragma,
              "pragma No_Caching should lower through the shared operational property path");
   end Test_Language_Model_GNAT_SPARK_Entity_Pragma_Unification_Pass;

   procedure Test_Language_Model_GNAT_Codegen_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with No_Elaboration_Code is" & ASCII.LF &
        "   type Bytes is array (Positive range <>) of aliased Integer" & ASCII.LF &
        "     with Universal_Aliasing;" & ASCII.LF &
        "   X : aliased Integer" & ASCII.LF &
        "     with Linker_Section => "".fast"", Persistent_BSS, Unreferenced;" & ASCII.LF &
        "   Y : aliased Integer" & ASCII.LF &
        "     with Volatile_Full_Access, Atomic_Always_Lock_Free;" & ASCII.LF &
        "   procedure Hook" & ASCII.LF &
        "     with Machine_Attribute => ""naked"", Weak_External, Unmodified, No_Inline;" & ASCII.LF &
        "   for X'Linker_Section use "".slow"";" & ASCII.LF &
        "   for X'Persistent_BSS use False;" & ASCII.LF &
        "   for X'Unreferenced use False;" & ASCII.LF &
        "   for Hook'Machine_Attribute use ""interrupt"";" & ASCII.LF &
        "   for Hook'Weak_External use False;" & ASCII.LF &
        "   for Hook'Unmodified use False;" & ASCII.LF &
        "   for Hook'No_Inline use False;" & ASCII.LF &
        "   for Y'Volatile_Full_Access use False;" & ASCII.LF &
        "   for Y'Atomic_Always_Lock_Free use False;" & ASCII.LF &
        "   for P'No_Elaboration_Code use False;" & ASCII.LF &
        "   for Bytes'Universal_Aliasing use False;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Bytes_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bytes");
      X_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "X");
      Hook_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hook");
      G_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "G");
      H_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "H");
      Y_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Y");
      Seen_Linker_Aspect : Boolean := False;
      Seen_Linker_Clause : Boolean := False;
      Seen_Machine_Aspect : Boolean := False;
      Seen_Machine_Clause : Boolean := False;
      Seen_Weak_Aspect : Boolean := False;
      Seen_Weak_Clause : Boolean := False;
      Seen_Unreferenced_Aspect : Boolean := False;
      Seen_Unreferenced_Clause : Boolean := False;
      Seen_Unmodified_Aspect : Boolean := False;
      Seen_Unmodified_Clause : Boolean := False;
      Seen_No_Elab_Aspect : Boolean := False;
      Seen_No_Elab_Clause : Boolean := False;
      Seen_Persistent_Aspect : Boolean := False;
      Seen_Persistent_Clause : Boolean := False;
      Seen_Aliasing_Aspect : Boolean := False;
      Seen_Aliasing_Clause : Boolean := False;
      Seen_Volatile_Full_Access_Aspect : Boolean := False;
      Seen_Volatile_Full_Access_Clause : Boolean := False;
      Seen_Atomic_Lock_Free_Aspect : Boolean := False;
      Seen_Atomic_Lock_Free_Clause : Boolean := False;
      Seen_No_Inline_Aspect : Boolean := False;
      Seen_No_Inline_Clause : Boolean := False;
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target should be retained");
      Assert (Bytes_Id /= Editor.Ada_Language_Model.No_Symbol,
              "type target should be retained");
      Assert (X_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object target should be retained");
      Assert (Hook_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram target should be retained");
      Assert (Y_Id /= Editor.Ada_Language_Model.No_Symbol,
              "secondary object target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Item : constant String := To_String (R.Item_Text);
         begin
            if R.Target_Symbol = X_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Linker_Section_Clause
            then
               if Item = """.fast""" then
                  Seen_Linker_Aspect := True;
               elsif Item = """.slow""" then
                  Seen_Linker_Clause := True;
               end if;
            elsif R.Target_Symbol = Hook_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Machine_Attribute_Clause
            then
               if Item = """naked""" then
                  Seen_Machine_Aspect := True;
               elsif Item = """interrupt""" then
                  Seen_Machine_Clause := True;
               end if;
            elsif R.Target_Symbol = Hook_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Weak_External_Clause
            then
               if Item = "True" then
                  Seen_Weak_Aspect := True;
               elsif Item = "False" then
                  Seen_Weak_Clause := True;
               end if;
            elsif R.Target_Symbol = X_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Unreferenced_Clause
            then
               if Item = "True" then
                  Seen_Unreferenced_Aspect := True;
               elsif Item = "False" then
                  Seen_Unreferenced_Clause := True;
               end if;
            elsif R.Target_Symbol = Hook_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Unmodified_Clause
            then
               if Item = "True" then
                  Seen_Unmodified_Aspect := True;
               elsif Item = "False" then
                  Seen_Unmodified_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Elaboration_Code_Clause
            then
               if Item = "True" then
                  Seen_No_Elab_Aspect := True;
               elsif Item = "False" then
                  Seen_No_Elab_Clause := True;
               end if;
            elsif R.Target_Symbol = X_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Persistent_BSS_Clause
            then
               if Item = "True" then
                  Seen_Persistent_Aspect := True;
               elsif Item = "False" then
                  Seen_Persistent_Clause := True;
               end if;
            elsif R.Target_Symbol = Bytes_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Universal_Aliasing_Clause
            then
               if Item = "True" then
                  Seen_Aliasing_Aspect := True;
               elsif Item = "False" then
                  Seen_Aliasing_Clause := True;
               end if;
            elsif R.Target_Symbol = Y_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Volatile_Full_Access_Clause
            then
               if Item = "True" then
                  Seen_Volatile_Full_Access_Aspect := True;
               elsif Item = "False" then
                  Seen_Volatile_Full_Access_Clause := True;
               end if;
            elsif R.Target_Symbol = Y_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Atomic_Always_Lock_Free_Clause
            then
               if Item = "True" then
                  Seen_Atomic_Lock_Free_Aspect := True;
               elsif Item = "False" then
                  Seen_Atomic_Lock_Free_Clause := True;
               end if;
            elsif R.Target_Symbol = Hook_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Inline_Clause
            then
               if Item = "True" then
                  Seen_No_Inline_Aspect := True;
               elsif Item = "False" then
                  Seen_No_Inline_Clause := True;
               end if;
            end if;
         end;
      end loop;

      Assert (Seen_Linker_Aspect and then Seen_Linker_Clause,
              "Linker_Section aspect and attribute clause should share the explicit kind");
      Assert (Seen_Machine_Aspect and then Seen_Machine_Clause,
              "Machine_Attribute aspect and attribute clause should share the explicit kind");
      Assert (Seen_Weak_Aspect and then Seen_Weak_Clause,
              "Weak_External aspect and attribute clause should share the explicit kind");
      Assert (Seen_Unreferenced_Aspect and then Seen_Unreferenced_Clause,
              "Unreferenced aspect and attribute clause should share the explicit kind");
      Assert (Seen_Unmodified_Aspect and then Seen_Unmodified_Clause,
              "Unmodified aspect and attribute clause should share the explicit kind");
      Assert (Seen_No_Elab_Aspect and then Seen_No_Elab_Clause,
              "No_Elaboration_Code aspect and attribute clause should share the explicit kind");
      Assert (Seen_Persistent_Aspect and then Seen_Persistent_Clause,
              "Persistent_BSS aspect and attribute clause should share the explicit kind");
      Assert (Seen_Aliasing_Aspect and then Seen_Aliasing_Clause,
              "Universal_Aliasing aspect and attribute clause should share the explicit kind");
      Assert (Seen_Volatile_Full_Access_Aspect and then Seen_Volatile_Full_Access_Clause,
              "Volatile_Full_Access aspect and attribute clause should share the explicit kind");
      Assert (Seen_Atomic_Lock_Free_Aspect and then Seen_Atomic_Lock_Free_Clause,
              "Atomic_Always_Lock_Free aspect and attribute clause should share the explicit kind");
      Assert (Seen_No_Inline_Aspect and then Seen_No_Inline_Clause,
              "No_Inline aspect and attribute clause should share the explicit kind");
   end Test_Language_Model_GNAT_Codegen_Operational_Unification_Pass;

   procedure Test_Language_Model_GNAT_Restriction_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with Reviewable is" & ASCII.LF &
        "   type Ref is access all Integer" & ASCII.LF &
        "     with No_Strict_Aliasing;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   procedure Old" & ASCII.LF &
        "     with Obsolescent, Optimize => Time;" & ASCII.LF &
        "   pragma Suppress (Range_Check, On => X);" & ASCII.LF &
        "   pragma Unsuppress (Overflow_Check, On => X);" & ASCII.LF &
        "   for Ref'No_Strict_Aliasing use False;" & ASCII.LF &
        "   for Old'Obsolescent use False;" & ASCII.LF &
        "   for Old'Optimize use Space;" & ASCII.LF &
        "   for P'Reviewable use False;" & ASCII.LF &
        "   for X'Suppress use Range_Check;" & ASCII.LF &
        "   for X'Unsuppress use Overflow_Check;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ref");
      X_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "X");
      Old_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Old");
      Seen_No_Strict_Aspect : Boolean := False;
      Seen_No_Strict_Clause : Boolean := False;
      Seen_Obsolescent_Aspect : Boolean := False;
      Seen_Obsolescent_Clause : Boolean := False;
      Seen_Optimize_Aspect : Boolean := False;
      Seen_Optimize_Clause : Boolean := False;
      Seen_Reviewable_Aspect : Boolean := False;
      Seen_Reviewable_Clause : Boolean := False;
      Seen_Suppress_Pragma : Boolean := False;
      Seen_Suppress_Clause : Boolean := False;
      Seen_Unsuppress_Pragma : Boolean := False;
      Seen_Unsuppress_Clause : Boolean := False;
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target should be retained");
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access type target should be retained");
      Assert (X_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object target should be retained");
      Assert (Old_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Item : constant String := To_String (R.Item_Text);
         begin
            if R.Target_Symbol = Ref_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Strict_Aliasing_Clause
            then
               if Item = "True" then
                  Seen_No_Strict_Aspect := True;
               elsif Item = "False" then
                  Seen_No_Strict_Clause := True;
               end if;
            elsif R.Target_Symbol = Old_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Obsolescent_Clause
            then
               if Item = "True" then
                  Seen_Obsolescent_Aspect := True;
               elsif Item = "False" then
                  Seen_Obsolescent_Clause := True;
               end if;
            elsif R.Target_Symbol = Old_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Optimize_Clause
            then
               if Item = "Time" then
                  Seen_Optimize_Aspect := True;
               elsif Item = "Space" then
                  Seen_Optimize_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Reviewable_Clause
            then
               if Item = "True" then
                  Seen_Reviewable_Aspect := True;
               elsif Item = "False" then
                  Seen_Reviewable_Clause := True;
               end if;
            elsif R.Target_Symbol = X_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Suppress_Clause
            then
               if Item = "Range_Check" then
                  if Seen_Suppress_Pragma then
                     Seen_Suppress_Clause := True;
                  else
                     Seen_Suppress_Pragma := True;
                  end if;
               end if;
            elsif R.Target_Symbol = X_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Unsuppress_Clause
            then
               if Item = "Overflow_Check" then
                  if Seen_Unsuppress_Pragma then
                     Seen_Unsuppress_Clause := True;
                  else
                     Seen_Unsuppress_Pragma := True;
                  end if;
               end if;
            end if;
         end;
      end loop;

      Assert (Seen_No_Strict_Aspect and then Seen_No_Strict_Clause,
              "No_Strict_Aliasing aspect and attribute clause should share the explicit kind");
      Assert (Seen_Obsolescent_Aspect and then Seen_Obsolescent_Clause,
              "Obsolescent aspect and attribute clause should share the explicit kind");
      Assert (Seen_Optimize_Aspect and then Seen_Optimize_Clause,
              "Optimize aspect and attribute clause should share the explicit kind");
      Assert (Seen_Reviewable_Aspect and then Seen_Reviewable_Clause,
              "Reviewable aspect and attribute clause should share the explicit kind");
      Assert (Seen_Suppress_Pragma and then Seen_Suppress_Clause,
              "Suppress pragma and attribute clause should share the explicit kind");
      Assert (Seen_Unsuppress_Pragma and then Seen_Unsuppress_Clause,
              "Unsuppress pragma and attribute clause should share the explicit kind");
   end Test_Language_Model_GNAT_Restriction_Operational_Unification_Pass;

   procedure Test_Language_Model_GNAT_Policy_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with No_Heap_Finalization, Suppress_Debug_Info," & ASCII.LF &
        "  Assertion_Policy => Check, Check_Policy => Check," & ASCII.LF &
        "  Debug_Policy => Check, Restrictions => No_Tasking," & ASCII.LF &
        "  Restriction_Warnings => No_Recursion, Profile => Ravenscar is" & ASCII.LF &
        "   for P'No_Heap_Finalization use False;" & ASCII.LF &
        "   for P'Suppress_Debug_Info use False;" & ASCII.LF &
        "   for P'Assertion_Policy use Ignore;" & ASCII.LF &
        "   for P'Check_Policy use Disable;" & ASCII.LF &
        "   for P'Debug_Policy use Ignore;" & ASCII.LF &
        "   for P'Restrictions use No_Allocators;" & ASCII.LF &
        "   for P'Restriction_Warnings use No_Recursion;" & ASCII.LF &
        "   for P'Profile use Restricted;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Seen_No_Heap_Aspect : Boolean := False;
      Seen_No_Heap_Clause : Boolean := False;
      Seen_Debug_Info_Aspect : Boolean := False;
      Seen_Debug_Info_Clause : Boolean := False;
      Seen_Assertion_Aspect : Boolean := False;
      Seen_Assertion_Clause : Boolean := False;
      Seen_Check_Aspect : Boolean := False;
      Seen_Check_Clause : Boolean := False;
      Seen_Debug_Policy_Aspect : Boolean := False;
      Seen_Debug_Policy_Clause : Boolean := False;
      Seen_Restrictions_Aspect : Boolean := False;
      Seen_Restrictions_Clause : Boolean := False;
      Seen_Restriction_Warnings_Aspect : Boolean := False;
      Seen_Restriction_Warnings_Clause : Boolean := False;
      Seen_Profile_Aspect : Boolean := False;
      Seen_Profile_Clause : Boolean := False;
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package policy target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Item : constant String := To_String (R.Item_Text);
         begin
            if R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Heap_Finalization_Clause
            then
               if Item = "True" then
                  Seen_No_Heap_Aspect := True;
               elsif Item = "False" then
                  Seen_No_Heap_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Suppress_Debug_Info_Clause
            then
               if Item = "True" then
                  Seen_Debug_Info_Aspect := True;
               elsif Item = "False" then
                  Seen_Debug_Info_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Assertion_Policy_Clause
            then
               if Item = "Check" then
                  Seen_Assertion_Aspect := True;
               elsif Item = "Ignore" then
                  Seen_Assertion_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Check_Policy_Clause
            then
               if Item = "Check" then
                  Seen_Check_Aspect := True;
               elsif Item = "Disable" then
                  Seen_Check_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Debug_Policy_Clause
            then
               if Item = "Check" then
                  Seen_Debug_Policy_Aspect := True;
               elsif Item = "Ignore" then
                  Seen_Debug_Policy_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Restrictions_Clause
            then
               if Item = "No_Tasking" then
                  Seen_Restrictions_Aspect := True;
               elsif Item = "No_Allocators" then
                  Seen_Restrictions_Clause := True;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Restriction_Warnings_Clause
            then
               if Item = "No_Recursion" then
                  if Seen_Restriction_Warnings_Aspect then
                     Seen_Restriction_Warnings_Clause := True;
                  else
                     Seen_Restriction_Warnings_Aspect := True;
                  end if;
               end if;
            elsif R.Target_Symbol = Package_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Profile_Clause
            then
               if Item = "Ravenscar" then
                  Seen_Profile_Aspect := True;
               elsif Item = "Restricted" then
                  Seen_Profile_Clause := True;
               end if;
            end if;
         end;
      end loop;

      Assert (Seen_No_Heap_Aspect and then Seen_No_Heap_Clause,
              "No_Heap_Finalization aspect and attribute clause should share the explicit kind");
      Assert (Seen_Debug_Info_Aspect and then Seen_Debug_Info_Clause,
              "Suppress_Debug_Info aspect and attribute clause should share the explicit kind");
      Assert (Seen_Assertion_Aspect and then Seen_Assertion_Clause,
              "Assertion_Policy aspect and attribute clause should share the explicit kind");
      Assert (Seen_Check_Aspect and then Seen_Check_Clause,
              "Check_Policy aspect and attribute clause should share the explicit kind");
      Assert (Seen_Debug_Policy_Aspect and then Seen_Debug_Policy_Clause,
              "Debug_Policy aspect and attribute clause should share the explicit kind");
      Assert (Seen_Restrictions_Aspect and then Seen_Restrictions_Clause,
              "Restrictions aspect and attribute clause should share the explicit kind");
      Assert (Seen_Restriction_Warnings_Aspect and then Seen_Restriction_Warnings_Clause,
              "Restriction_Warnings aspect and attribute clause should share the explicit kind");
      Assert (Seen_Profile_Aspect and then Seen_Profile_Clause,
              "Profile aspect and attribute clause should share the explicit kind");
   end Test_Language_Model_GNAT_Policy_Operational_Unification_Pass;

   overriding function Name (T : RepresentationGnatUnification_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Representation-Gnat-Unification");
   end Name;

   overriding procedure Register_Tests (T : in out RepresentationGnatUnification_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_GNAT_SPARK_Operational_Unification_Pass'Access, Name => "language model unifies GNAT and SPARK operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_GNAT_SPARK_Entity_Pragma_Unification_Pass'Access, Name => "language model unifies GNAT SPARK entity pragmas with operational properties");
      Add_Test (Routine => Test_Language_Model_GNAT_Codegen_Operational_Unification_Pass'Access, Name => "language model unifies GNAT code-generation operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_GNAT_Restriction_Operational_Unification_Pass'Access, Name => "language model unifies GNAT restriction and review operational properties across aspects pragmas and attribute clauses");
      Add_Test (Routine => Test_Language_Model_GNAT_Policy_Operational_Unification_Pass'Access, Name => "language model unifies GNAT policy operational properties across aspects and attribute clauses");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Gnat_Unification_Tests;
