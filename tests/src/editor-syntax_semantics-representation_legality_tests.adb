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

package body Editor.Syntax_Semantics.Representation_Legality_Tests is




   procedure Test_Language_Model_Representation_Operational_Projection_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rep_Projection is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 2, Blue => 4);" & ASCII.LF &
        "   type Header is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "      Code : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Header use record" & ASCII.LF &
        "      Flag at 0 range 0 .. 0;" & ASCII.LF &
        "      Code at 0 range 1 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Obj : Integer;" & ASCII.LF &
        "   for Obj use at System'To_Address (16#1000#);" & ASCII.LF &
        "   for Obj'Alignment use 4;" & ASCII.LF &
        "   type Streamed is tagged null record;" & ASCII.LF &
        "   procedure Read_Stream;" & ASCII.LF &
        "   for Streamed'Read use Read_Stream;" & ASCII.LF &
        "   pragma Volatile (Obj);" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      X : Integer;" & ASCII.LF &
        "   end record with Pack, Size => 32;" & ASCII.LF &
        "end Rep_Projection;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "rep_projection.ads");
      Saw_Enumeration : Boolean := False;
      Saw_Record      : Boolean := False;
      Saw_Address     : Boolean := False;
      Saw_Attribute   : Boolean := False;
      Saw_Stream      : Boolean := False;
      Saw_Pragma      : Boolean := False;
      Saw_Aspect      : Boolean := False;
      Saw_Flag_Component : Boolean := False;
      Saw_Code_Component : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) >= 7,
              "representation projection should retain attribute address enumeration record stream pragma and aspect clauses");
      Assert (Editor.Ada_Language_Model.Enumeration_Representation_Literal_Count (Analysis) = 3,
              "enumeration representation associations should project individual literal metadata");
      Assert (Editor.Ada_Language_Model.Representation_Component_Count (Analysis) = 2,
              "record representation component clauses should project individual component metadata");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Target : constant String := To_String (Info.Normalized_Target_Name);
            Attr   : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Representation_Enumeration_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Enumeration_Clause
              and then Target = "colour"
            then
               Saw_Enumeration := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Representation_Record_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Record_Clause
              and then Target = "header"
            then
               Saw_Record := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Representation_Address_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Address_Clause
              and then Target = "obj"
            then
               Saw_Address := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Representation_Alignment_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Attribute_Definition
              and then Target = "obj"
              and then Info.Has_Static_Value
              and then Info.Static_Value = 4
            then
               Saw_Attribute := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Representation_Read_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Attribute_Definition
              and then Target = "streamed"
              and then Attr = "Read"
            then
               Saw_Stream := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Representation_Volatile_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Pragma
              and then Target = "obj"
            then
               Saw_Pragma := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Representation_Size_Clause
              and then Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Aspect
              and then Target = "packed"
              and then Info.Has_Static_Value
              and then Info.Static_Value = 32
            then
               Saw_Aspect := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Representation_Component_Count (Analysis) loop
         declare
            Component : constant Editor.Ada_Language_Model.Representation_Component_Info :=
              Editor.Ada_Language_Model.Representation_Component_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            Name : constant String := To_String (Component.Component_Name);
         begin
            if Component.Source_Form =
                 Editor.Ada_Language_Model.Representation_Source_Record_Component_Clause
              and then Name = "Flag"
              and then Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 0
              and then Component.Has_Static_First_Bit
              and then Component.Static_First_Bit = 0
              and then Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 0
            then
               Saw_Flag_Component := True;
            elsif Component.Source_Form =
                    Editor.Ada_Language_Model.Representation_Source_Record_Component_Clause
              and then Name = "Code"
              and then Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 0
              and then Component.Has_Static_First_Bit
              and then Component.Static_First_Bit = 1
              and then Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 31
            then
               Saw_Code_Component := True;
            end if;
         end;
      end loop;

      Assert (Saw_Enumeration, "enumeration representation clause source form should be explicit");
      Assert (Saw_Record, "record representation clause source form should be explicit");
      Assert (Saw_Address, "address clause source form should be explicit");
      Assert (Saw_Attribute, "attribute-definition clause source form and static value should be retained");
      Assert (Saw_Stream, "stream operational attribute should use the unified representation projection");
      Assert (Saw_Pragma, "representation pragma should use the same representation projection with pragma source form");
      Assert (Saw_Aspect, "representation aspect should use the same representation projection with aspect source form");
      Assert (Saw_Flag_Component and then Saw_Code_Component,
              "record component clauses should retain component source form and static bit metadata");
   end Test_Language_Model_Representation_Operational_Projection_Metadata;








   procedure Test_Ada_Freezing_Generic_Private_Body_Interactions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Freezing_Interactions.Freezing_Interaction_Status;
      Source : constant String :=
        "generic" & ASCII.LF &
        "package G is" & ASCII.LF &
        "end G;" & ASCII.LF &
        "package P is" & ASCII.LF &
        "   type Hidden is private;" & ASCII.LF &
        "   package I is new G;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Hidden is record" & ASCII.LF &
        "      X : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end P;" & ASCII.LF &
        "package body P is" & ASCII.LF &
        "end P;";
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
      Generics : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build (Tree, Regions, Visibility);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generics);
      Seen_Generic : Boolean := False;
      Seen_Private : Boolean := False;
      Seen_Body    : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Freezing_Interactions.Interaction_Count (Interactions) loop
         declare
            Info : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Info :=
              Editor.Ada_Freezing_Interactions.Interaction_At (Interactions, Index);
         begin
            if Info.Status =
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Generic_Instance_Freezes_Target
            then
               Seen_Generic := True;
            elsif Info.Status =
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Private_Partial_View
            then
               Seen_Private := True;
            elsif Info.Status =
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Body_Context
            then
               Seen_Body := True;
            end if;
         end;
      end loop;

      Assert
        (Seen_Generic
         and then Editor.Ada_Freezing_Interactions.Generic_Instance_Freeze_Count (Interactions) >= 1,
         "freezing interactions should retain generic-instance freezing metadata");
      Assert
        (Seen_Private
         and then Editor.Ada_Freezing_Interactions.Private_Partial_View_Count (Interactions) >= 1,
         "freezing interactions should retain private partial-view metadata");
      Assert
        (Seen_Body
         and then Editor.Ada_Freezing_Interactions.Body_Context_Count (Interactions) >= 1,
         "freezing interactions should retain package-body freezing context metadata");
      Assert
        (Editor.Ada_Freezing_Interactions.Fingerprint (Interactions) /= 0,
         "freezing interaction metadata should have a deterministic fingerprint");
   end Test_Ada_Freezing_Generic_Private_Body_Interactions;




   procedure Test_Ada_Freezing_Point_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Freezing_Points.Freezing_Status;
      use type Editor.Ada_Freezing_Points.Freezing_Cause;
      use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
      use type Editor.Ada_Freezing_Points.Freezable_Id;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Layouts is" & ASCII.LF &
        "   type Small is range 0 .. 10;" & ASCII.LF &
        "   for Small'Size use 8;" & ASCII.LF &
        "   X : Small;" & ASCII.LF &
        "   for Small'Alignment use 4;" & ASCII.LF &
        "end Layouts;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Small : Editor.Ada_Freezing_Points.Freezable_Id :=
        Editor.Ada_Freezing_Points.No_Freezable;
      Before_Count : Natural := 0;
      After_Count  : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Freezing_Points.Freezable_Count (Freezing) loop
         declare
            Info : constant Editor.Ada_Freezing_Points.Freezable_Info :=
              Editor.Ada_Freezing_Points.Freezable_At (Freezing, Index);
         begin
            if To_String (Info.Normalized_Name) = "small" then
               Small := Info.Id;
               Assert (Info.Status = Editor.Ada_Freezing_Points.Freezing_Frozen,
                       "freezing model must mark Small frozen by its first object declaration");
               Assert (Info.First_Freeze_Line = 4,
                       "freezing model must retain the first freezing source line");
               Assert (Info.Cause = Editor.Ada_Freezing_Points.Freezing_Cause_Object_Declaration,
                       "freezing model must classify object declarations as freezing causes");
            end if;
         end;
      end loop;

      Assert (Small /= Editor.Ada_Freezing_Points.No_Freezable,
              "freezing model must stage the declared scalar type as freezable");
      Assert (Editor.Ada_Freezing_Points.Representation_Check_Count (Freezing) = 2,
              "freezing model must stage representation clauses for freeze ordering checks");

      for Index in 1 .. Editor.Ada_Freezing_Points.Representation_Check_Count (Freezing) loop
         declare
            Check : constant Editor.Ada_Freezing_Points.Representation_Freeze_Info :=
              Editor.Ada_Freezing_Points.Representation_Check_At (Freezing, Index);
         begin
            if Check.Status = Editor.Ada_Freezing_Points.Representation_Before_Freezing then
               Before_Count := Before_Count + 1;
               Assert (Check.Clause_Line = 3,
                       "representation clause before first freeze must preserve its source line");
            elsif Check.Status = Editor.Ada_Freezing_Points.Representation_After_Freezing then
               After_Count := After_Count + 1;
               Assert (Check.Clause_Line = 5,
                       "representation clause after first freeze must preserve its source line");
            end if;
         end;
      end loop;

      Assert (Before_Count = 1,
              "freezing model must classify representation clauses before the freeze point");
      Assert (After_Count = 1,
              "freezing model must classify representation clauses after the freeze point");
      Assert (Editor.Ada_Freezing_Points.Fingerprint (Freezing) /= 0,
              "freezing model must retain deterministic fingerprints");
   end Test_Ada_Freezing_Point_Foundation;




   procedure Test_Ada_Record_Representation_Component_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Layout_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      Lo : Integer;" & ASCII.LF &
        "      Hi : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      Lo at 0 range 0 .. 31;" & ASCII.LF &
        "      Hi at 4 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      Lo at 0 range 31 .. 0;" & ASCII.LF &
        "      Missing at 8 range 0 .. 7;" & ASCII.LF &
        "      Hi at 4 range 0 .. 31;" & ASCII.LF &
        "      Hi at 8 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Record_Layout_Checks;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Seen_Ok : Natural := 0;
      Seen_Unresolved : Boolean := False;
      Seen_Duplicate : Boolean := False;
      Seen_Reversed : Boolean := False;
   begin
      Assert (Editor.Ada_Representation_Legality.Record_Component_Check_Count (Legality) >= 6,
              "record representation legality must stage each component clause separately");

      for Index in 1 .. Editor.Ada_Representation_Legality.Record_Component_Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Record_Component_Legality_Info :=
              Editor.Ada_Representation_Legality.Record_Component_Check_At (Legality, Index);
         begin
            if Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok then
               Seen_Ok := Seen_Ok + 1;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Unresolved then
               Seen_Unresolved := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Duplicate then
               Seen_Duplicate := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Bit_Range_Reversed then
               Seen_Reversed := True;
            end if;
         end;
      end loop;

      Assert (Seen_Ok >= 2,
              "record representation component legality must accept valid static component clauses");
      Assert (Seen_Unresolved,
              "record representation component legality must reject clauses for undeclared components");
      Assert (Seen_Duplicate,
              "record representation component legality must reject duplicate component clauses per record representation clause");
      Assert (Seen_Reversed,
              "record representation component legality must reject reversed bit ranges");
      Assert (Editor.Ada_Representation_Legality.Record_Component_Error_Count (Legality) >= 3,
              "record representation component legality must expose deterministic error counters");
      Assert (Editor.Ada_Representation_Legality.Record_Component_Duplicate_Count (Legality) >= 1,
              "record representation component legality must count duplicate component clauses");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "record representation component legality must contribute to deterministic fingerprints");
   end Test_Ada_Record_Representation_Component_Legality;




   procedure Test_Ada_Record_Storage_Order_Interaction
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Order_Interactions is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      Lo : Integer;" & ASCII.LF &
        "      Hi : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word'Bit_Order use Low_Order_First;" & ASCII.LF &
        "   for Word'Scalar_Storage_Order use High_Order_First;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      Lo at 0 range 0 .. 31;" & ASCII.LF &
        "      Hi at 4 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Clean is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Clean'Bit_Order use High_Order_First;" & ASCII.LF &
        "   for Clean use record" & ASCII.LF &
        "      A at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Record_Order_Interactions;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Orders : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Saw_Conflict : Boolean := False;
      Saw_Bit_Order : Boolean := False;
   begin
      Assert (Editor.Ada_Record_Storage_Order_Rules.Rule_Count (Orders) >= 3,
              "storage-order rules must stage component clauses for order interaction checks");

      for Index in 1 .. Editor.Ada_Record_Storage_Order_Rules.Rule_Count (Orders) loop
         declare
            Info : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Info :=
              Editor.Ada_Record_Storage_Order_Rules.Rule_At (Orders, Index);
         begin
            if Info.Status = Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Order_Conflict then
               Saw_Conflict := True;
            elsif Info.Status = Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Bit_Order_Applied then
               Saw_Bit_Order := True;
            end if;
         end;
      end loop;

      Assert (Saw_Conflict,
              "record storage-order rules must flag conflicting Bit_Order and Scalar_Storage_Order metadata");
      Assert (Saw_Bit_Order,
              "record storage-order rules must retain component clauses affected by explicit Bit_Order");
      Assert (Editor.Ada_Record_Storage_Order_Rules.Explicit_Order_Component_Count (Orders) >= 3,
              "storage-order rules must count component clauses with explicit order metadata");
      Assert (Editor.Ada_Record_Storage_Order_Rules.Bit_Order_Component_Count (Orders) >= 3,
              "storage-order rules must count Bit_Order-affected component clauses deterministically");
      Assert (Editor.Ada_Record_Storage_Order_Rules.Scalar_Storage_Order_Component_Count (Orders) >= 2,
              "storage-order rules must count Scalar_Storage_Order-affected component clauses deterministically");
      Assert (Editor.Ada_Record_Storage_Order_Rules.Order_Conflict_Count (Orders) >= 2,
              "storage-order rules must expose deterministic order-conflict counters");
      Assert (Editor.Ada_Record_Storage_Order_Rules.Fingerprint (Orders) /= 0,
              "storage-order rules must retain deterministic fingerprints");
   end Test_Ada_Record_Storage_Order_Interaction;





   procedure Test_Ada_Operational_Attribute_Duplicate_Conflict
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Operational_Duplicate_Conflicts is" & ASCII.LF &
        "   type Word is range 0 .. 255;" & ASCII.LF &
        "   for Word'Atomic use True;" & ASCII.LF &
        "   for Word'Atomic use False;" & ASCII.LF &
        "   for Word'Volatile use True;" & ASCII.LF &
        "   for Word'Volatile use True;" & ASCII.LF &
        "   type Bytes is array (Positive range <>) of Word;" & ASCII.LF &
        "   for Bytes'Atomic_Components use True;" & ASCII.LF &
        "   for Bytes'Atomic_Components use True;" & ASCII.LF &
        "end Operational_Duplicate_Conflicts;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Rules : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Saw_Duplicate : Boolean := False;
      Saw_Conflict : Boolean := False;
   begin
      Assert (Editor.Ada_Operational_Attribute_Rules.Rule_Count (Rules) >= 6,
              "operational attribute rules must stage unified operational properties");

      for Index in 1 .. Editor.Ada_Operational_Attribute_Rules.Rule_Count (Rules) loop
         declare
            Info : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Info :=
              Editor.Ada_Operational_Attribute_Rules.Rule_At (Rules, Index);
         begin
            if Info.Status = Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Duplicate_Property then
               Saw_Duplicate := True;
            elsif Info.Status = Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Conflicting_Boolean_Value then
               Saw_Conflict := True;
            end if;
         end;
      end loop;

      Assert (Saw_Duplicate,
              "operational attribute rules must retain duplicate property metadata");
      Assert (Saw_Conflict,
              "operational attribute rules must flag contradictory Boolean values for one property target");
      Assert (Editor.Ada_Operational_Attribute_Rules.Duplicate_Count (Rules) >= 2,
              "operational attribute rules must expose deterministic duplicate counters");
      Assert (Editor.Ada_Operational_Attribute_Rules.Conflict_Count (Rules) >= 1,
              "operational attribute rules must expose deterministic conflict counters");
      Assert (Editor.Ada_Operational_Attribute_Rules.Fingerprint (Rules) /= 0,
              "operational attribute rules must retain deterministic fingerprints");
   end Test_Ada_Operational_Attribute_Duplicate_Conflict;





   procedure Test_Ada_Aspect_Inheritance_Override_Rules
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aspect_Inheritance_Checks is" & ASCII.LF &
        "   type Root is range 0 .. 255;" & ASCII.LF &
        "   for Root'Atomic use True;" & ASCII.LF &
        "   for Root'Volatile use True;" & ASCII.LF &
        "   type Child is new Root;" & ASCII.LF &
        "   for Child'Atomic use False;" & ASCII.LF &
        "   type Grandchild is new Child;" & ASCII.LF &
        "end Aspect_Inheritance_Checks;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Saw_Inherited : Boolean := False;
      Saw_Conflict  : Boolean := False;
   begin
      Assert (Editor.Ada_Aspect_Inheritance_Rules.Rule_Count (Inheritance) >= 2,
              "aspect inheritance rules must stage inherited representation properties");

      for Index in 1 .. Editor.Ada_Aspect_Inheritance_Rules.Rule_Count (Inheritance) loop
         declare
            Info : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Info :=
              Editor.Ada_Aspect_Inheritance_Rules.Rule_At (Inheritance, Index);
         begin
            if Info.Status = Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Inherited then
               Saw_Inherited := True;
            elsif Info.Status = Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Explicit_Conflict then
               Saw_Conflict := True;
            end if;
         end;
      end loop;

      Assert (Saw_Inherited,
              "derived types must retain inherited representation/aspect metadata");
      Assert (Saw_Conflict,
              "explicit derived-type representation clauses must be classified as overrides/conflicts");
      Assert (Editor.Ada_Aspect_Inheritance_Rules.Inherited_Count (Inheritance) >= 1,
              "aspect inheritance rules must expose deterministic inherited counters");
      Assert (Editor.Ada_Aspect_Inheritance_Rules.Conflict_Count (Inheritance) >= 1,
              "aspect inheritance rules must expose deterministic override conflict counters");
      Assert (Editor.Ada_Aspect_Inheritance_Rules.Fingerprint (Inheritance) /= 0,
              "aspect inheritance rules must retain deterministic fingerprints");
   end Test_Ada_Aspect_Inheritance_Override_Rules;



   procedure Test_Ada_Enumeration_Representation_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Enum_Layout_Checks is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   for Color use (Red => 1, Green => 2, Blue => 4);" & ASCII.LF &
        "   for Color use (Red => 1, Red => 2, Blue => 2);" & ASCII.LF &
        "   for Color use (Red => 1, Green => Missing_Value, Blue => 3);" & ASCII.LF &
        "   for Color use (Red => 1, Green => 1, Blue => 3);" & ASCII.LF &
        "   for Color use (Red => 1, Blue => 3);" & ASCII.LF &
        "   type Not_Enum is range 0 .. 10;" & ASCII.LF &
        "   for Not_Enum use (Low => 0);" & ASCII.LF &
        "end Enum_Layout_Checks;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Seen_Ok : Natural := 0;
      Seen_Duplicate_Literal : Boolean := False;
      Seen_Duplicate_Value : Boolean := False;
      Seen_Static_Error : Boolean := False;
      Seen_Incomplete : Boolean := False;
      Seen_Target_Error : Boolean := False;
   begin
      Assert
        (Editor.Ada_Representation_Legality.Enumeration_Representation_Check_Count
           (Legality) >= 10,
         "enumeration representation legality must stage literal associations and missing literals");

      for Index in 1 .. Editor.Ada_Representation_Legality.Enumeration_Representation_Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Enumeration_Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Enumeration_Representation_Check_At (Legality, Index);
         begin
            if Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok then
               Seen_Ok := Seen_Ok + 1;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Literal_Duplicate then
               Seen_Duplicate_Literal := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Value_Duplicate then
               Seen_Duplicate_Value := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Value_Static_Required then
               Seen_Static_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Incomplete then
               Seen_Incomplete := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Target_Not_Enumeration then
               Seen_Target_Error := True;
            end if;
         end;
      end loop;

      Assert (Seen_Ok >= 3,
              "enumeration representation legality must accept complete static literal mappings");
      Assert (Seen_Duplicate_Literal,
              "enumeration representation legality must reject duplicate literal associations");
      Assert (Seen_Duplicate_Value,
              "enumeration representation legality must reject duplicate representation values");
      Assert (Seen_Static_Error,
              "enumeration representation legality must require static literal values");
      Assert (Seen_Incomplete,
              "enumeration representation legality must report missing enumeration literals");
      Assert (Seen_Target_Error,
              "enumeration representation legality must reject non-enumeration targets");
      Assert
        (Editor.Ada_Representation_Legality.Enumeration_Representation_Error_Count
           (Legality) >= 5,
         "enumeration representation legality must expose deterministic error counters");
      Assert
        (Editor.Ada_Representation_Legality.Enumeration_Representation_Duplicate_Literal_Count
           (Legality) >= 1,
         "enumeration representation legality must count duplicate literal associations");
      Assert
        (Editor.Ada_Representation_Legality.Enumeration_Representation_Duplicate_Value_Count
           (Legality) >= 1,
         "enumeration representation legality must count duplicate representation values");
      Assert
        (Editor.Ada_Representation_Legality.Enumeration_Representation_Static_Error_Count
           (Legality) >= 1,
         "enumeration representation legality must count non-static representation values");
      Assert
        (Editor.Ada_Representation_Legality.Enumeration_Representation_Incomplete_Count
           (Legality) >= 1,
         "enumeration representation legality must count incomplete literal coverage");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "enumeration representation legality must contribute to deterministic fingerprints");
   end Test_Ada_Enumeration_Representation_Legality;





   procedure Test_Ada_Size_Alignment_Storage_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Size_Alignment_Storage_Checks is" & ASCII.LF &
        "   type T is range 0 .. 10;" & ASCII.LF &
        "   type Access_Int is access Integer;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   procedure P;" & ASCII.LF &
        "   for T'Size use 16;" & ASCII.LF &
        "   for X'Alignment use 4;" & ASCII.LF &
        "   for Access_Int'Storage_Size use 128;" & ASCII.LF &
        "   for P'Size use 8;" & ASCII.LF &
        "   for T'Storage_Size use 128;" & ASCII.LF &
        "   for Access_Int'Storage_Size use 1.5;" & ASCII.LF &
        "   for X'Alignment use 0;" & ASCII.LF &
        "end Size_Alignment_Storage_Checks;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Seen_Size_Ok : Boolean := False;
      Seen_Alignment_Ok : Boolean := False;
      Seen_Storage_Ok : Boolean := False;
      Seen_Size_Target_Error : Boolean := False;
      Seen_Storage_Target_Error : Boolean := False;
      Seen_Not_Integer : Boolean := False;
      Seen_Not_Positive : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Size_Clause
            then
               Seen_Size_Ok := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Alignment_Clause
            then
               Seen_Alignment_Ok := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Storage_Size_Clause
            then
               Seen_Storage_Ok := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Size_Target_Incompatible then
               Seen_Size_Target_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Storage_Size_Target_Incompatible then
               Seen_Storage_Target_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Integer then
               Seen_Not_Integer := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Positive then
               Seen_Not_Positive := True;
            end if;
         end;
      end loop;

      Assert (Seen_Size_Ok,
              "size/alignment/storage legality must accept static Size clauses on types");
      Assert (Seen_Alignment_Ok,
              "size/alignment/storage legality must accept positive static Alignment clauses on objects");
      Assert (Seen_Storage_Ok,
              "size/alignment/storage legality must accept positive static Storage_Size clauses on access types");
      Assert (Seen_Size_Target_Error,
              "size/alignment/storage legality must reject Size clauses on subprogram targets");
      Assert (Seen_Storage_Target_Error,
              "size/alignment/storage legality must reject Storage_Size clauses on non-access targets");
      Assert (Seen_Not_Integer,
              "size/alignment/storage legality must reject real values for integer-valued representation clauses");
      Assert (Seen_Not_Positive,
              "size/alignment/storage legality must reject non-positive representation values");
      Assert
        (Editor.Ada_Representation_Legality.Size_Alignment_Storage_Error_Count
           (Legality) >= 2,
         "size/alignment/storage legality must count target-shape errors deterministically");
      Assert
        (Editor.Ada_Representation_Legality.Size_Alignment_Storage_Static_Error_Count
           (Legality) >= 2,
         "size/alignment/storage legality must count static value errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "size/alignment/storage legality must contribute to deterministic fingerprints");
   end Test_Ada_Size_Alignment_Storage_Legality;




   procedure Test_Ada_Operational_Attribute_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Operational_Value_Status;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Operational_Checks is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Packed_Array is array (1 .. 4) of Integer;" & ASCII.LF &
        "   type Scalar is range 0 .. 10;" & ASCII.LF &
        "   Flag : Integer;" & ASCII.LF &
        "   for Rec'Pack use True;" & ASCII.LF &
        "   for Flag'Atomic use True;" & ASCII.LF &
        "   for Packed_Array'Atomic_Components use True;" & ASCII.LF &
        "   for Rec'Bit_Order use High_Order_First;" & ASCII.LF &
        "   for Rec'Scalar_Storage_Order use Low_Order_First;" & ASCII.LF &
        "   for Scalar'Pack use True;" & ASCII.LF &
        "   for Scalar'Atomic_Components use True;" & ASCII.LF &
        "   for Rec'Volatile use Maybe;" & ASCII.LF &
        "   for Rec'Bit_Order use Middle_Order_First;" & ASCII.LF &
        "end Operational_Checks;";
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
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Seen_Pack_Ok : Boolean := False;
      Seen_Atomic_Ok : Boolean := False;
      Seen_Components_Ok : Boolean := False;
      Seen_Order_Ok : Boolean := False;
      Seen_Target_Error : Boolean := False;
      Seen_Boolean_Error : Boolean := False;
      Seen_Order_Error : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Pack_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Operational_Status =
                Editor.Ada_Representation_Legality.Operational_Value_Static_Boolean_True
            then
               Seen_Pack_Ok := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Atomic_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Atomic_Ok := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Atomic_Components_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Components_Ok := True;
            elsif Info.Clause_Kind in Editor.Ada_Language_Model.Representation_Bit_Order_Clause |
                                      Editor.Ada_Language_Model.Representation_Scalar_Storage_Order_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Operational_Status in
                Editor.Ada_Representation_Legality.Operational_Value_Order_High_Order_First |
                Editor.Ada_Representation_Legality.Operational_Value_Order_Low_Order_First
            then
               Seen_Order_Ok := True;
            elsif Info.Status =
              Editor.Ada_Representation_Legality.Representation_Legality_Operational_Target_Incompatible
            then
               Seen_Target_Error := True;
            elsif Info.Status =
              Editor.Ada_Representation_Legality.Representation_Legality_Operational_Boolean_Value_Required
            then
               Seen_Boolean_Error := True;
            elsif Info.Status =
              Editor.Ada_Representation_Legality.Representation_Legality_Operational_Order_Value_Required
            then
               Seen_Order_Error := True;
            end if;
         end;
      end loop;

      Assert (Seen_Pack_Ok,
              "operational legality must accept Pack on composite type targets");
      Assert (Seen_Atomic_Ok,
              "operational legality must accept Atomic on object targets");
      Assert (Seen_Components_Ok,
              "operational legality must accept Atomic_Components on array targets");
      Assert (Seen_Order_Ok,
              "operational legality must accept storage-order representation values");
      Assert (Seen_Target_Error,
              "operational legality must reject incompatible operational targets");
      Assert (Seen_Boolean_Error,
              "operational legality must reject malformed Boolean operational values");
      Assert (Seen_Order_Error,
              "operational legality must reject malformed order operational values");
      Assert (Editor.Ada_Representation_Legality.Operational_Error_Count (Legality) >= 3,
              "operational legality must count operational errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Operational_Target_Error_Count (Legality) >= 2,
              "operational legality must count operational target errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Operational_Value_Error_Count (Legality) >= 2,
              "operational legality must count operational value errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Operational_Static_Boolean_Count (Legality) >= 3,
              "operational legality must count static Boolean operational values deterministically");
      Assert (Editor.Ada_Representation_Legality.Operational_Order_Value_Count (Legality) >= 2,
              "operational legality must count storage-order operational values deterministically");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "operational legality must contribute to deterministic fingerprints");
   end Test_Ada_Operational_Attribute_Legality;




   procedure Test_Language_Model_Legality_Representation_Freezing_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type T is range 0 .. 255;" & ASCII.LF &
        "   X : T;" & ASCII.LF &
        "   for T'Size use 8;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type F is private;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   type U is range 0 .. 15;" & ASCII.LF &
        "   package I is new G (U);" & ASCII.LF &
        "   for U'Size use 4;" & ASCII.LF &
        "   type Hidden is private;" & ASCII.LF &
        "   for Hidden'Size use 16;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Hidden is null record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Late : Boolean := False;
      Seen_Premature : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_After_Freezing then
               Seen_Late := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Before_Completion then
               Seen_Premature := True;
            end if;
         end;
      end loop;

      Assert (Seen_Late,
              "late representation clauses should be diagnosed after freezing points");
      Assert (Seen_Premature,
              "premature representation clauses before full-type completion should be diagnosed");
      Assert (Editor.Ada_Language_Model.Freezing_Point_Count (Analysis) >= 1,
              "freezing point tracking should retain the trigger for diagnostics");
   end Test_Language_Model_Legality_Representation_Freezing_Pass;






   procedure Test_Language_Model_Freezing_Index_Retention_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type T is range 0 .. 255;" & ASCII.LF &
        "   for T'Size use 8;" & ASCII.LF &
        "   X : T;" & ASCII.LF &
        "   type U is range 0 .. 255;" & ASCII.LF &
        "   package Q is end Q;" & ASCII.LF &
        "   package body Q is end Q;" & ASCII.LF &
        "   for U'Size use 8;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Late : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_After_Freezing then
               Seen_Late := True;
            end if;
         end;
      end loop;

      Assert (Editor.Ada_Language_Model.Freezing_Point_Count (Analysis) >= 1,
              "freezing points should be retained even when representation clauses are legal");
      Assert (not Seen_Late,
              "unrelated body completions after a type must not make a later representation clause illegal");
   end Test_Language_Model_Freezing_Index_Retention_Pass;




   procedure Test_Language_Model_Freezing_Name_Boundary_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type T is range 0 .. 255;" & ASCII.LF &
        "   N : Integer;" & ASCII.LF &
        "   for T'Size use 8;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Late : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_After_Freezing then
               Seen_Late := True;
            end if;
         end;
      end loop;

      Assert (not Seen_Late,
              "freezing matcher must not treat a type name as a substring of Integer");
   end Test_Language_Model_Freezing_Name_Boundary_Pass;




   procedure Test_Language_Model_Generic_Formal_Freezing_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type T is range 0 .. 255;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      X : T;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   for T'Size use 8;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Freezing_Point_Kind;
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Late : Boolean := False;
      Seen_Formal_Point : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_After_Freezing then
               Seen_Late := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Freezing_Point_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Freezing_Point_Info :=
              Editor.Ada_Language_Model.Freezing_Point_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Freezing_Generic_Formal_Use then
               Seen_Formal_Point := True;
            end if;
         end;
      end loop;

      Assert (Seen_Late,
              "generic formal declarations that mention a type should freeze it before later representation clauses");
      Assert (Seen_Formal_Point,
              "freezing point index should identify generic formal declaration triggers");
   end Test_Language_Model_Generic_Formal_Freezing_Pass;





   procedure Test_Language_Model_Legality_Representation_Item_Identity_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Red => 2, Green => 3, Blue => 4);" & ASCII.LF &
        "   type Pair is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Pair use record" & ASCII.LF &
        "      A at 0 range 0 .. 3;" & ASCII.LF &
        "      A at 1 range 0 .. 3;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Literal : Boolean := False;
      Seen_Duplicate_Component : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "representation item identity legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Enumeration_Representation_Literal =>
                  Seen_Duplicate_Literal := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Record_Component_Representation =>
                  Seen_Duplicate_Component := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Duplicate_Literal,
              "legality checking should flag duplicate enumeration representation literal associations");
      Assert (Seen_Duplicate_Component,
              "legality checking should flag duplicate record representation component clauses");
   end Test_Language_Model_Legality_Representation_Item_Identity_Pass;






   procedure Test_Language_Model_Legality_Representation_Operational_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 2, Yellow => 3);" & ASCII.LF &
        "   type Pair is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Pair'Bit_Order use Middle_Order_First;" & ASCII.LF &
        "   for Pair use record" & ASCII.LF &
        "      Missing at 0 range 0 .. 3;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   for X'Bit_Order use Low_Order_First;" & ASCII.LF &
        "   for Missing'Size use 8;" & ASCII.LF &
        "   for Pair'Size use Dynamic_Size;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Target_Not_Found : Boolean := False;
      Seen_Incompatible_Target : Boolean := False;
      Seen_Static_Value_Required : Boolean := False;
      Seen_Invalid_Bit_Order : Boolean := False;
      Seen_Missing_Literal : Boolean := False;
      Seen_Missing_Component : Boolean := False;
      Seen_Unknown_Literal : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "representation operational legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Representation_Target_Not_Found =>
                  Seen_Target_Not_Found := True;
               when Editor.Ada_Language_Model.Legality_Representation_Target_Incompatible =>
                  Seen_Incompatible_Target := True;
               when Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required =>
                  Seen_Static_Value_Required := True;
               when Editor.Ada_Language_Model.Legality_Bit_Order_Invalid_Value =>
                  Seen_Invalid_Bit_Order := True;
               when Editor.Ada_Language_Model.Legality_Enumeration_Representation_Missing_Literal =>
                  Seen_Missing_Literal := True;
               when Editor.Ada_Language_Model.Legality_Enumeration_Representation_Literal_Not_Found =>
                  Seen_Unknown_Literal := True;
               when Editor.Ada_Language_Model.Legality_Record_Component_Not_Found =>
                  Seen_Missing_Component := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Target_Not_Found,
              "legality checking should flag representation clauses with unresolved targets");
      Assert (Seen_Incompatible_Target,
              "legality checking should flag representation clauses on incompatible target classes");
      Assert (Seen_Static_Value_Required,
              "legality checking should flag nonstatic numeric representation values");
      Assert (Seen_Invalid_Bit_Order,
              "legality checking should flag invalid Bit_Order values");
      Assert (Seen_Missing_Literal,
              "legality checking should flag incomplete enumeration representation clauses");
      Assert (Seen_Unknown_Literal,
              "legality checking should flag representation associations for unknown enumeration literals");
      Assert (Seen_Missing_Component,
              "legality checking should flag record representation clauses for missing components");
   end Test_Language_Model_Legality_Representation_Operational_Value_Pass;






   procedure Test_Language_Model_Legality_Operational_Attribute_Handler_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   procedure Wrong_Input" & ASCII.LF &
        "     (Stream : access Integer; Value : out Item);" & ASCII.LF &
        "   function Good_Input" & ASCII.LF &
        "     (Stream : access Integer) return Item;" & ASCII.LF &
        "   for Item'Read use Missing_Read;" & ASCII.LF &
        "   for Item'Input use Wrong_Input;" & ASCII.LF &
        "   for Item'Output use Good_Input;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Not_Found : Boolean := False;
      Seen_Incompatible : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "operational attribute handler legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Operational_Attribute_Handler_Not_Found =>
                  Seen_Not_Found := True;
               when Editor.Ada_Language_Model.Legality_Operational_Attribute_Handler_Incompatible =>
                  Seen_Incompatible := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Not_Found,
              "legality checking should flag stream attributes that name no retained handler");
      Assert (Seen_Incompatible,
              "legality checking should flag stream attributes whose handler kind is incompatible");
   end Test_Language_Model_Legality_Operational_Attribute_Handler_Pass;






   procedure Test_Language_Model_Legality_Storage_Attribute_Target_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Access_Item is access Integer;" & ASCII.LF &
        "   type Plain is null record;" & ASCII.LF &
        "   for Plain'Storage_Pool use Pool;" & ASCII.LF &
        "   for Plain'Storage_Size use 1024;" & ASCII.LF &
        "   for Access_Item'Storage_Size use 2048;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Storage_Pool_Target : Boolean := False;
      Seen_Storage_Size_Target : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "storage representation target legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Storage_Pool_Target_Not_Access =>
                  Seen_Storage_Pool_Target := True;
               when Editor.Ada_Language_Model.Legality_Storage_Size_Target_Incompatible =>
                  Seen_Storage_Size_Target := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Storage_Pool_Target,
              "legality checking should require Storage_Pool targets to be access types");
      Assert (Seen_Storage_Size_Target,
              "legality checking should reject Storage_Size on non-access/non-task targets");
   end Test_Language_Model_Legality_Storage_Attribute_Target_Pass;





   procedure Test_Language_Model_Legality_Scalar_Storage_Representation_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Plain is null record;" & ASCII.LF &
        "   type Int_Array is array (Positive range <>) of Integer;" & ASCII.LF &
        "   type Fixed is delta 0.01 range 0.0 .. 10.0;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   for Plain'Component_Size use 8;" & ASCII.LF &
        "   for Int_Array'Component_Size use Dynamic_Size;" & ASCII.LF &
        "   for Plain'Scalar_Storage_Order use Middle_Order_First;" & ASCII.LF &
        "   for X'Scalar_Storage_Order use Low_Order_First;" & ASCII.LF &
        "   for Plain'Small use 1;" & ASCII.LF &
        "   for Plain'Pack use Dynamic_Flag;" & ASCII.LF &
        "   for Plain'Object_Size use Dynamic_Size;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Component_Target : Boolean := False;
      Seen_Static_Natural : Boolean := False;
      Seen_Scalar_Target : Boolean := False;
      Seen_Scalar_Value : Boolean := False;
      Seen_Small_Target : Boolean := False;
      Seen_Pack_Value : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "scalar/storage representation legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Component_Size_Target_Not_Array =>
                  Seen_Component_Target := True;
               when Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required =>
                  Seen_Static_Natural := True;
               when Editor.Ada_Language_Model.Legality_Scalar_Storage_Order_Target_Incompatible =>
                  Seen_Scalar_Target := True;
               when Editor.Ada_Language_Model.Legality_Scalar_Storage_Order_Invalid_Value =>
                  Seen_Scalar_Value := True;
               when Editor.Ada_Language_Model.Legality_Small_Target_Not_Fixed_Point =>
                  Seen_Small_Target := True;
               when Editor.Ada_Language_Model.Legality_Pack_Boolean_Value_Required =>
                  Seen_Pack_Value := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Component_Target,
              "legality checking should require Component_Size targets to be array types");
      Assert (Seen_Static_Natural,
              "legality checking should require static natural values for size-like representation attributes");
      Assert (Seen_Scalar_Target,
              "legality checking should require Scalar_Storage_Order targets to be type-like");
      Assert (Seen_Scalar_Value,
              "legality checking should validate Scalar_Storage_Order values");
      Assert (Seen_Small_Target,
              "legality checking should require Small targets to be fixed-point types");
      Assert (Seen_Pack_Value,
              "legality checking should require Pack values to be static Boolean values");
   end Test_Language_Model_Legality_Scalar_Storage_Representation_Pass;








   procedure Test_Language_Model_Unchecked_Union_Representation_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Rec (Kind : Boolean := False) is record" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when False => I : Integer;" & ASCII.LF &
        "         when True => C : Character;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   pragma Unchecked_Union (Rec);" & ASCII.LF &
        "   type Aspect_Rec (Kind : Boolean := False) is record" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when False => I : Integer;" & ASCII.LF &
        "         when True => C : Character;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record with Unchecked_Union;" & ASCII.LF &
        "   type Plain is range 0 .. 10 with Unchecked_Union;" & ASCII.LF &
        "   type Bad (Kind : Boolean := False) is record" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when False => I : Integer;" & ASCII.LF &
        "         when True => C : Character;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record with Unchecked_Union => Maybe;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Aspect_Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Aspect_Rec");
      Seen_Pragma : Boolean := False;
      Seen_Aspect : Boolean := False;
      Seen_Target : Boolean := False;
      Seen_Boolean : Boolean := False;
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Unchecked_Union pragma target should be retained");
      Assert (Aspect_Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Unchecked_Union aspect target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if Info.Target_Symbol = Rec_Id
              and then To_String (Info.Attribute_Name) = "Unchecked_Union"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Pragma := True;
            elsif Info.Target_Symbol = Aspect_Rec_Id
              and then To_String (Info.Attribute_Name) = "Unchecked_Union"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Aspect := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Unchecked_Union_Target_Incompatible =>
                  Seen_Target := True;
               when Editor.Ada_Language_Model.Legality_Unchecked_Union_Boolean_Value_Required =>
                  Seen_Boolean := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Pragma,
              "pragma Unchecked_Union should lower into common representation metadata");
      Assert (Seen_Aspect,
              "Unchecked_Union aspect should lower into common representation metadata");
      Assert (Seen_Target,
              "Unchecked_Union should require a record type target");
      Assert (Seen_Boolean,
              "Unchecked_Union should require a static Boolean value");
   end Test_Language_Model_Unchecked_Union_Representation_Pass;




   procedure Test_Language_Model_Legality_Address_Representation_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with System;" & ASCII.LF &
        "package P is" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   Y : Integer;" & ASCII.LF &
        "   Z : Integer;" & ASCII.LF &
        "   for X'Address use 16#1000#;" & ASCII.LF &
        "   for Y'Address use ""not_an_address"";" & ASCII.LF &
        "   for Z'Address use System'To_Address (16#2000#);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Address_Value : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "address representation value legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Address_Value_Incompatible then
               Seen_Address_Value := True;
            end if;
         end;
      end loop;

      Assert (Seen_Address_Value,
              "legality checking should reject raw literal Address representation values");
   end Test_Language_Model_Legality_Address_Representation_Value_Pass;





   procedure Test_Language_Model_Legality_Attribute_Specific_Representation_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Plain is range 0 .. 10;" & ASCII.LF &
        "   type Floaty is digits 6;" & ASCII.LF &
        "   type Money is delta 0.01 digits 10;" & ASCII.LF &
        "   type Pool_Access is access Integer;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   for Plain'Machine_Radix use 2;" & ASCII.LF &
        "   for Floaty'Machine_Radix use 0;" & ASCII.LF &
        "   for Plain'Aft use 2;" & ASCII.LF &
        "   for Money'Small use Dynamic_Small;" & ASCII.LF &
        "   for X'Atomic use Maybe;" & ASCII.LF &
        "   for P'Suppress_Initialization use True;" & ASCII.LF &
        "   for Pool_Access'Storage_Pool use 42;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Machine_Target : Boolean := False;
      Seen_Aft_Target : Boolean := False;
      Seen_Small_Value : Boolean := False;
      Seen_Positive_Value : Boolean := False;
      Seen_Atomic_Value : Boolean := False;
      Seen_Suppress_Target : Boolean := False;
      Seen_Storage_Pool_Value : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "attribute-specific representation legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Machine_Radix_Target_Not_Floating_Point =>
                  Seen_Machine_Target := True;
               when Editor.Ada_Language_Model.Legality_Aft_Target_Not_Fixed_Point =>
                  Seen_Aft_Target := True;
               when Editor.Ada_Language_Model.Legality_Small_Static_Value_Required =>
                  Seen_Small_Value := True;
               when Editor.Ada_Language_Model.Legality_Representation_Positive_Value_Required =>
                  Seen_Positive_Value := True;
               when Editor.Ada_Language_Model.Legality_Atomic_Volatile_Boolean_Value_Required =>
                  Seen_Atomic_Value := True;
               when Editor.Ada_Language_Model.Legality_Suppress_Initialization_Target_Incompatible =>
                  Seen_Suppress_Target := True;
               when Editor.Ada_Language_Model.Legality_Storage_Pool_Value_Incompatible =>
                  Seen_Storage_Pool_Value := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Machine_Target,
              "legality checking should require Machine_Radix targets to be floating-point types");
      Assert (Seen_Aft_Target,
              "legality checking should require Aft targets to be fixed-point types");
      Assert (Seen_Small_Value,
              "legality checking should require Small values to be static numeric expressions");
      Assert (Seen_Positive_Value,
              "legality checking should require positive values for positive-valued representation attributes");
      Assert (Seen_Atomic_Value,
              "legality checking should require Atomic/Volatile/Independent values to be static Boolean expressions");
      Assert (Seen_Suppress_Target,
              "legality checking should validate Suppress_Initialization targets");
      Assert (Seen_Storage_Pool_Value,
              "legality checking should reject literal Storage_Pool representation values");
   end Test_Language_Model_Legality_Attribute_Specific_Representation_Pass;





   procedure Test_Language_Model_Legality_Local_Duplicate_Representation_Clause_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type T is range 0 .. 10;" & ASCII.LF &
        "   for T'Size use 32;" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "      type T is range 0 .. 10;" & ASCII.LF &
        "      for T'Size use 16;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "   for T'Size use 64;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Duplicate_Count : Natural := 0;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause then
               Duplicate_Count := Duplicate_Count + 1;
            end if;
         end;
      end loop;

      Assert (Duplicate_Count = 1,
              "duplicate representation diagnostics should be local to the resolved target symbol");
   end Test_Language_Model_Legality_Local_Duplicate_Representation_Clause_Pass;




   procedure Test_Language_Model_Legality_Aspect_Association_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Flag is new Boolean with Size => 8, Volatile, Size => 16;" & ASCII.LF &
        "   X : Integer with Atomic, Volatile;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Aspect : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "duplicate aspect associations should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Duplicate_Aspect_Association then
               Seen_Duplicate_Aspect := True;
            end if;
         end;
      end loop;

      Assert (Seen_Duplicate_Aspect,
              "legality checking should flag duplicate aspect marks within one aspect specification");
   end Test_Language_Model_Legality_Aspect_Association_Pass;





   procedure Test_Language_Model_Legality_Representation_Full_Target_Resolution_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Root is" & ASCII.LF &
        "   package Internal is" & ASCII.LF &
        "      type Rec is record" & ASCII.LF &
        "         A : Integer;" & ASCII.LF &
        "      end record;" & ASCII.LF &
        "      type Colour is (Red, Green);" & ASCII.LF &
        "   end Internal;" & ASCII.LF &
        "   package Public renames Internal;" & ASCII.LF &
        "   for Public.Rec'Size use 64;" & ASCII.LF &
        "   for Public.Colour use (Red => 1, Green => 2);" & ASCII.LF &
        "   for Public.Rec use record" & ASCII.LF &
        "      A at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Root;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      use type Editor.Ada_Language_Model.Symbol_Id;
      Saw_Unresolved_Target : Boolean := False;
      Saw_Resolved_Selected_Representation : Boolean := False;
      Saw_Resolved_Record_Component : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Target_Not_Found then
               Saw_Unresolved_Target := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Clause : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if Clause.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Clause.Target_Name) = "Public.Rec"
            then
               Saw_Resolved_Selected_Representation := True;
            elsif Clause.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Clause.Target_Name) = "Public.Colour"
            then
               Saw_Resolved_Selected_Representation := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Representation_Component_Count (Analysis) loop
         declare
            Component : constant Editor.Ada_Language_Model.Representation_Component_Info :=
              Editor.Ada_Language_Model.Representation_Component_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if Component.Target_Symbol /= Editor.Ada_Language_Model.No_Symbol
              and then Component.Component_Symbol /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Component.Component_Name) = "A"
            then
               Saw_Resolved_Record_Component := True;
            end if;
         end;
      end loop;

      Assert (not Saw_Unresolved_Target,
              "representation target resolution should follow selected package renames");
      Assert (Saw_Resolved_Selected_Representation,
              "selected representation clauses should resolve through renamed package prefixes");
      Assert (Saw_Resolved_Record_Component,
              "record representation component clauses should resolve through renamed package prefixes");
   end Test_Language_Model_Legality_Representation_Full_Target_Resolution_Pass;




   procedure Test_Language_Model_Legality_Record_Representation_Completeness_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Byte is range 0 .. 255;" & ASCII.LF &
        "   for Byte'Size use 8;" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A : Byte;" & ASCII.LF &
        "      B : Byte;" & ASCII.LF &
        "      C : Byte;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Rec use record" & ASCII.LF &
        "      A at 0 range 0 .. 15;" & ASCII.LF &
        "      B at 1 range 0 .. 3;" & ASCII.LF &
        "      C at 2 range 0 .. 3;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Saw_Bit_Out_Of_Storage : Boolean := False;
      Saw_Cross_Overlap      : Boolean := False;
      Saw_Size_Too_Small     : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "record representation completeness checks should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Record_Component_Bit_Out_Of_Storage_Unit =>
                  Saw_Bit_Out_Of_Storage := True;
               when Editor.Ada_Language_Model.Legality_Record_Component_Cross_Storage_Overlap =>
                  Saw_Cross_Overlap := True;
               when Editor.Ada_Language_Model.Legality_Record_Component_Size_Too_Small =>
                  Saw_Size_Too_Small := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Saw_Bit_Out_Of_Storage,
              "record representation legality should flag bit numbers outside the retained storage-unit model");
      Assert (Saw_Cross_Overlap,
              "record representation legality should catch overlaps across adjacent storage units");
      Assert (Saw_Size_Too_Small,
              "record representation legality should use retained component subtype sizes when available");
   end Test_Language_Model_Legality_Record_Representation_Completeness_Pass;




   procedure Test_Language_Model_Legality_Record_Representation_Mod_Clause_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type R is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for R use record" & ASCII.LF &
        "      at mod 0;" & ASCII.LF &
        "      A at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type S is record" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for S use record" & ASCII.LF &
        "      at mod Non_Static;" & ASCII.LF &
        "      B at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      use type Editor.Ada_Syntax_Tree.Node_Kind;
      Saw_Positive : Boolean := False;
      Saw_Static   : Boolean := False;
      Saw_Mod_Node : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree)
      loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Node_Id (I));
         begin
            if N.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Mod_Clause then
               Saw_Mod_Node := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Record_Mod_Positive_Value_Required =>
                  Saw_Positive := True;
               when Editor.Ada_Language_Model.Legality_Record_Mod_Static_Value_Required =>
                  Saw_Static := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Saw_Mod_Node,
              "record representation mod clauses should be retained as syntax-tree nodes");
      Assert (Saw_Positive,
              "record representation mod clauses should reject zero modulus values");
      Assert (Saw_Static,
              "record representation mod clauses should require static natural values");
   end Test_Language_Model_Legality_Record_Representation_Mod_Clause_Pass;


   overriding function Name (T : Representation_Legality_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Representation.Legality");
   end Name;

   overriding procedure Register_Tests (T : in out Representation_Legality_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Representation_Operational_Projection_Metadata'Access, Name => "language model retains consistent representation and operational clause projection metadata");
      Add_Test (Routine => Test_Ada_Freezing_Generic_Private_Body_Interactions'Access, Name => "Ada freezing interactions stage generic instances private views and body contexts");
      Add_Test (Routine => Test_Ada_Freezing_Point_Foundation'Access, Name => "Ada freezing-point model classifies representation clauses before and after freezing");
      Add_Test (Routine => Test_Ada_Record_Representation_Component_Legality'Access, Name => "Ada representation legality checks record representation component clauses");
      Add_Test (Routine => Test_Ada_Record_Storage_Order_Interaction'Access, Name => "Ada record storage-order rules classify bit-order and scalar-storage-order interactions");
      Add_Test (Routine => Test_Ada_Operational_Attribute_Duplicate_Conflict'Access, Name => "Ada operational attribute rules classify duplicates and conflicts");
      Add_Test (Routine => Test_Ada_Aspect_Inheritance_Override_Rules'Access, Name => "Ada aspect inheritance rules classify inherited and explicit override properties");
      Add_Test (Routine => Test_Ada_Enumeration_Representation_Legality'Access, Name => "Ada representation legality checks enumeration representation clauses");
      Add_Test (Routine => Test_Ada_Size_Alignment_Storage_Legality'Access, Name => "Ada representation legality checks Size, Alignment, and Storage_Size clauses");
      Add_Test (Routine => Test_Ada_Operational_Attribute_Legality'Access, Name => "Ada representation legality checks operational attributes and storage-order clauses");
      Add_Test (Routine => Test_Language_Model_Legality_Representation_Freezing_Pass'Access, Name => "language model diagnoses representation clauses after freezing points");
      Add_Test (Routine => Test_Language_Model_Freezing_Index_Retention_Pass'Access, Name => "language model retains freezing points independently of late representation diagnostics");
      Add_Test (Routine => Test_Language_Model_Freezing_Name_Boundary_Pass'Access, Name => "language model freezing matching uses identifier boundaries");
      Add_Test (Routine => Test_Language_Model_Generic_Formal_Freezing_Pass'Access, Name => "language model diagnoses generic formal freezing before representation clauses");
      Add_Test (Routine => Test_Language_Model_Legality_Representation_Item_Identity_Pass'Access, Name => "language model checks representation item identity legality");
      Add_Test (Routine => Test_Language_Model_Legality_Representation_Operational_Value_Pass'Access, Name => "language model checks representation and operational clause value legality");
      Add_Test (Routine => Test_Language_Model_Legality_Operational_Attribute_Handler_Pass'Access, Name => "language model checks operational attribute handler legality");
      Add_Test (Routine => Test_Language_Model_Legality_Storage_Attribute_Target_Pass'Access, Name => "language model checks storage representation target legality");
      Add_Test (Routine => Test_Language_Model_Legality_Scalar_Storage_Representation_Pass'Access, Name => "language model checks scalar and storage representation attribute legality");
      Add_Test (Routine => Test_Language_Model_Unchecked_Union_Representation_Pass'Access, Name => "language model lowers and checks Unchecked_Union representation forms");
      Add_Test (Routine => Test_Language_Model_Legality_Address_Representation_Value_Pass'Access, Name => "language model checks address representation value legality");
      Add_Test (Routine => Test_Language_Model_Legality_Attribute_Specific_Representation_Pass'Access, Name => "language model completes attribute-specific representation legality");
      Add_Test (Routine => Test_Language_Model_Legality_Local_Duplicate_Representation_Clause_Pass'Access, Name => "language model checks local duplicate representation clause legality");
      Add_Test (Routine => Test_Language_Model_Legality_Aspect_Association_Pass'Access, Name => "language model checks duplicate aspect association legality");
      Add_Test (Routine => Test_Language_Model_Legality_Representation_Full_Target_Resolution_Pass'Access, Name => "language model resolves full representation targets through selected names and renames");
      Add_Test (Routine => Test_Language_Model_Legality_Record_Representation_Completeness_Pass'Access, Name => "language model checks record representation clause completeness legality");
      Add_Test (Routine => Test_Language_Model_Legality_Record_Representation_Mod_Clause_Pass'Access, Name => "language model retains and checks record representation mod clauses");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Legality_Tests;
