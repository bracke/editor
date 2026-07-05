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

package body Editor.Syntax_Semantics.Representation_Static_Discrete_Tests is







   procedure Test_Language_Model_Representation_Static_Enumeration_Pos_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   type From_Pos is range 0 .. 1;" & ASCII.LF &
        "   for From_Pos'Size use Color'Pos (Blue) * 8;" & ASCII.LF &
        "   type From_Val is range 0 .. 1;" & ASCII.LF &
        "   for From_Val'Size use Color'Val (2) * 4;" & ASCII.LF &
        "   type Good_Small is delta 0.1 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Color'Pos (Green) / 2.0;" & ASCII.LF &
        "   type Bad_Val is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Val'Size use Color'Val (3) * 4;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Pos");
      From_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Val");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Bad_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Val");
      From_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Good_Small_Error : Boolean := False;
      Seen_Bad_Val_Error : Boolean := False;
   begin
      Assert (From_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration Pos target should be retained");
      Assert (From_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration Val target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Small target using enumeration Pos should be retained");
      Assert (Bad_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad enumeration Val target should be retained");

      From_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Pos_Id, 1);
      From_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Val_Id, 1);
      Bad_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Val_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Val_Id
            then
               Seen_Bad_Val_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Pos_Size.Has_Static_Value
              and then From_Pos_Size.Static_Value = 16,
              "enumeration literal Pos should feed Natural representation arithmetic");
      Assert (From_Val_Size.Has_Static_Value
              and then From_Val_Size.Static_Value = 8,
              "enumeration Val should range-check and feed representation arithmetic");
      Assert (not Seen_Good_Small_Error,
              "numeric-only Small clauses should accept enumeration Pos arithmetic");
      Assert (not Bad_Val_Size.Has_Static_Value,
              "out-of-range enumeration Val should not become static");
      Assert (Seen_Bad_Val_Error,
              "out-of-range enumeration Val should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Enumeration_Pos_Pass;






   procedure Test_Language_Model_Representation_Static_Predefined_Discrete_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type From_Boolean_Pos is range 0 .. 1;" & ASCII.LF &
        "   for From_Boolean_Pos'Size use Boolean'Pos (True) * 8;" & ASCII.LF &
        "   type From_Boolean_Val is range 0 .. 1;" & ASCII.LF &
        "   for From_Boolean_Val'Size use Boolean'Val (1) * 4;" & ASCII.LF &
        "   type From_Character_Pos is range 0 .. 1;" & ASCII.LF &
        "   for From_Character_Pos'Size use Character'Pos ('A');" & ASCII.LF &
        "   type Good_Small is delta 0.1 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Boolean'Pos (False) + Character'Pos ('B') / 2.0;" & ASCII.LF &
        "   type Bad_Boolean_Val is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Boolean_Val'Size use Boolean'Val (2) * 4;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Boolean_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Boolean_Pos");
      From_Boolean_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Boolean_Val");
      From_Character_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Character_Pos");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Bad_Boolean_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Boolean_Val");
      Boolean_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Boolean_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Character_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Boolean_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Good_Small_Error : Boolean := False;
      Seen_Bad_Boolean_Error : Boolean := False;
   begin
      Assert (From_Boolean_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Boolean Pos target should be retained");
      Assert (From_Boolean_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Boolean Val target should be retained");
      Assert (From_Character_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Character Pos target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Small target using predefined Pos should be retained");
      Assert (Bad_Boolean_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Boolean Val target should be retained");

      Boolean_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Boolean_Pos_Id, 1);
      Boolean_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Boolean_Val_Id, 1);
      Character_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Character_Pos_Id, 1);
      Bad_Boolean_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Boolean_Val_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Boolean_Val_Id
            then
               Seen_Bad_Boolean_Error := True;
            end if;
         end;
      end loop;

      Assert (Boolean_Pos_Size.Has_Static_Value
              and then Boolean_Pos_Size.Static_Value = 8,
              "Boolean'Pos(True) should feed representation arithmetic");
      Assert (Boolean_Val_Size.Has_Static_Value
              and then Boolean_Val_Size.Static_Value = 4,
              "Boolean'Val(1) should range-check and feed representation arithmetic");
      Assert (Character_Pos_Size.Has_Static_Value
              and then Character_Pos_Size.Static_Value = 65,
              "Character'Pos('A') should feed representation arithmetic");
      Assert (not Seen_Good_Small_Error,
              "numeric-only Small clauses should accept predefined discrete Pos values");
      Assert (not Bad_Boolean_Val_Size.Has_Static_Value,
              "out-of-range Boolean'Val should not become static");
      Assert (Seen_Bad_Boolean_Error,
              "out-of-range Boolean'Val should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Predefined_Discrete_Pass;





   procedure Test_Language_Model_Representation_Static_Discrete_Function_Literal_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   type From_Succ is range 0 .. 1;" & ASCII.LF &
        "   for From_Succ'Size use Color'Succ (Green) * 8;" & ASCII.LF &
        "   type From_Pred is range 0 .. 1;" & ASCII.LF &
        "   for From_Pred'Size use Color'Pred (Blue) * 8;" & ASCII.LF &
        "   type From_Min is range 0 .. 1;" & ASCII.LF &
        "   for From_Min'Size use Color'Min (Green, Blue) * 4;" & ASCII.LF &
        "   type From_Base_Max is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Max'Size use Color'Base'Max (Red, Green) * 4;" & ASCII.LF &
        "   type Bad_Succ is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Succ'Size use Color'Succ (Blue) * 4;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Succ");
      From_Pred_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Pred");
      From_Min_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Min");
      From_Base_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Max");
      Bad_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Succ");
      From_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Pred_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Min_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Base_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Succ_Error : Boolean := False;
   begin
      Assert (From_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Succ literal target should be retained");
      Assert (From_Pred_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Pred literal target should be retained");
      Assert (From_Min_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Min literal target should be retained");
      Assert (From_Base_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Max literal target should be retained");
      Assert (Bad_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Succ literal target should be retained");

      From_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Succ_Id, 1);
      From_Pred_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Pred_Id, 1);
      From_Min_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Min_Id, 1);
      From_Base_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Max_Id, 1);
      Bad_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Succ_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Succ_Id
            then
               Seen_Bad_Succ_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Succ_Size.Has_Static_Value
              and then From_Succ_Size.Static_Value = 16,
              "Succ over enumeration literal should feed static Size arithmetic");
      Assert (From_Pred_Size.Has_Static_Value
              and then From_Pred_Size.Static_Value = 8,
              "Pred over enumeration literal should feed static Size arithmetic");
      Assert (From_Min_Size.Has_Static_Value
              and then From_Min_Size.Static_Value = 4,
              "Min over enumeration literals should feed static Size arithmetic");
      Assert (From_Base_Max_Size.Has_Static_Value
              and then From_Base_Max_Size.Static_Value = 4,
              "Base'Max over enumeration literals should feed static Size arithmetic");
      Assert (not Bad_Succ_Size.Has_Static_Value,
              "out-of-range Succ over the last literal should not become static");
      Assert (Seen_Bad_Succ_Error,
              "out-of-range Succ over a literal should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Discrete_Function_Literal_Pass;




   procedure Test_Language_Model_Representation_Static_Discrete_Alias_Literal_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color;" & ASCII.LF &
        "   type Derived_Color is new Color;" & ASCII.LF &
        "   subtype Truth is Boolean;" & ASCII.LF &
        "   type From_Alias_Pos is range 0 .. 1;" & ASCII.LF &
        "   for From_Alias_Pos'Size use Primary'Pos (Blue) * 4;" & ASCII.LF &
        "   type From_Alias_Succ is range 0 .. 1;" & ASCII.LF &
        "   for From_Alias_Succ'Size use Primary'Succ (Green) * 8;" & ASCII.LF &
        "   type From_Alias_Base_Max is range 0 .. 1;" & ASCII.LF &
        "   for From_Alias_Base_Max'Size use Primary'Base'Max (Red, Green) * 4;" & ASCII.LF &
        "   type From_Derived_Pos is range 0 .. 1;" & ASCII.LF &
        "   for From_Derived_Pos'Size use Derived_Color'Pos (Green) * 8;" & ASCII.LF &
        "   type From_Boolean_Alias is range 0 .. 1;" & ASCII.LF &
        "   for From_Boolean_Alias'Size use Truth'Succ (False) * 16;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Alias_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Alias_Pos");
      From_Alias_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Alias_Succ");
      From_Alias_Base_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Alias_Base_Max");
      From_Derived_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Derived_Pos");
      From_Boolean_Alias_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Boolean_Alias");
      Alias_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Alias_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Alias_Base_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Derived_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Boolean_Alias_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (From_Alias_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "alias Pos target should be retained");
      Assert (From_Alias_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "alias Succ target should be retained");
      Assert (From_Alias_Base_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "alias Base Max target should be retained");
      Assert (From_Derived_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived Pos target should be retained");
      Assert (From_Boolean_Alias_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Boolean alias target should be retained");

      Alias_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Alias_Pos_Id, 1);
      Alias_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Alias_Succ_Id, 1);
      Alias_Base_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Alias_Base_Max_Id, 1);
      Derived_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Derived_Pos_Id, 1);
      Boolean_Alias_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Boolean_Alias_Id, 1);

      Assert (Alias_Pos_Size.Has_Static_Value
              and then Alias_Pos_Size.Static_Value = 8,
              "subtype aliases should preserve enumeration literal Pos metadata");
      Assert (Alias_Succ_Size.Has_Static_Value
              and then Alias_Succ_Size.Static_Value = 16,
              "subtype aliases should preserve enumeration literal Succ metadata");
      Assert (Alias_Base_Max_Size.Has_Static_Value
              and then Alias_Base_Max_Size.Static_Value = 4,
              "Base scalar functions should see aliased enumeration literals");
      Assert (Derived_Pos_Size.Has_Static_Value
              and then Derived_Pos_Size.Static_Value = 8,
              "derived scalar types should preserve bounded literal metadata");
      Assert (Boolean_Alias_Size.Has_Static_Value
              and then Boolean_Alias_Size.Static_Value = 16,
              "Boolean aliases should preserve predefined literal metadata");
   end Test_Language_Model_Representation_Static_Discrete_Alias_Literal_Pass;







   procedure Test_Language_Model_Representation_Static_Discrete_Width_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color;" & ASCII.LF &
        "   subtype Letter is Character;" & ASCII.LF &
        "   type From_Enum_Width is range 0 .. 255;" & ASCII.LF &
        "   for From_Enum_Width'Size use Color'Width * 4;" & ASCII.LF &
        "   type From_Alias_Width is range 0 .. 255;" & ASCII.LF &
        "   for From_Alias_Width'Size use Primary'Base'Width * 2;" & ASCII.LF &
        "   type From_Boolean_Width is range 0 .. 255;" & ASCII.LF &
        "   for From_Boolean_Width'Size use Boolean'Width + 3;" & ASCII.LF &
        "   type From_Character_Width is range 0 .. 255;" & ASCII.LF &
        "   for From_Character_Width'Size use Letter'Width * 8;" & ASCII.LF &
        "   type Good_Small is delta 0.01 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Primary'Width / 100.0;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Enum_Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Enum_Width");
      From_Alias_Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Alias_Width");
      From_Boolean_Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Boolean_Width");
      From_Character_Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Character_Width");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Enum_Width_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Alias_Width_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Boolean_Width_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Character_Width_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Small_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (From_Enum_Width_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration Width target should be retained");
      Assert (From_Alias_Width_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aliased enumeration Width target should be retained");
      Assert (From_Boolean_Width_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Boolean Width target should be retained");
      Assert (From_Character_Width_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Character Width target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Small target should be retained");

      Enum_Width_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Enum_Width_Id, 1);
      Alias_Width_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Alias_Width_Id, 1);
      Boolean_Width_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Boolean_Width_Id, 1);
      Character_Width_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Character_Width_Id, 1);
      Small_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Good_Small_Id, 1);

      Assert (Enum_Width_Size.Has_Static_Value
              and then Enum_Width_Size.Static_Value = 20,
              "enumeration Width should be the longest literal image length");
      Assert (Alias_Width_Size.Has_Static_Value
              and then Alias_Width_Size.Static_Value = 10,
              "Base'Width should use aliased enumeration literal metadata");
      Assert (Boolean_Width_Size.Has_Static_Value
              and then Boolean_Width_Size.Static_Value = 8,
              "Boolean Width should be static");
      Assert (Character_Width_Size.Has_Static_Value
              and then Character_Width_Size.Static_Value = 24,
              "Character alias Width should be static");
      Assert (Small_Clause.Kind = Editor.Ada_Language_Model.Representation_Small_Clause,
              "Width should be accepted by numeric-only Small recognition");
   end Test_Language_Model_Representation_Static_Discrete_Width_Pass;





   procedure Test_Language_Model_Representation_Static_Constrained_Discrete_Subtype_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color range Red .. Green;" & ASCII.LF &
        "   type Byte is mod 256;" & ASCII.LF &
        "   subtype Nibble is Byte range 0 .. 15;" & ASCII.LF &
        "   type From_Primary_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Primary_Pos'Size use Primary'Pos (Green) * 8;" & ASCII.LF &
        "   type From_Primary_Succ is range 0 .. 255;" & ASCII.LF &
        "   for From_Primary_Succ'Size use Primary'Succ (Red) * 16;" & ASCII.LF &
        "   type From_Primary_Width is range 0 .. 255;" & ASCII.LF &
        "   for From_Primary_Width'Size use Primary'Width * 4;" & ASCII.LF &
        "   type From_Nibble_Modulus is range 0 .. 255;" & ASCII.LF &
        "   for From_Nibble_Modulus'Size use Nibble'Modulus / 16;" & ASCII.LF &
        "   type Bad_Primary_Succ is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Primary_Succ'Size use Primary'Succ (Green) * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Primary_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Primary_Pos");
      From_Primary_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Primary_Succ");
      From_Primary_Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Primary_Width");
      From_Nibble_Modulus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Nibble_Modulus");
      Bad_Primary_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Primary_Succ");
      Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Width_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Modulus_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Succ_Error : Boolean := False;
   begin
      Assert (From_Primary_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained enumeration subtype Pos target should be retained");
      Assert (From_Primary_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained enumeration subtype Succ target should be retained");
      Assert (From_Primary_Width_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained enumeration subtype Width target should be retained");
      Assert (From_Nibble_Modulus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained modular subtype Modulus target should be retained");
      Assert (Bad_Primary_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad constrained enumeration subtype Succ target should be retained");

      Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Primary_Pos_Id, 1);
      Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Primary_Succ_Id, 1);
      Width_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Primary_Width_Id, 1);
      Modulus_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Nibble_Modulus_Id, 1);
      Bad_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Primary_Succ_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Primary_Succ"
            then
               Seen_Bad_Succ_Error := True;
            end if;
         end;
      end loop;

      Assert (Pos_Size.Has_Static_Value and then Pos_Size.Static_Value = 8,
              "constrained enumeration subtype should preserve literal Pos metadata");
      Assert (Succ_Size.Has_Static_Value and then Succ_Size.Static_Value = 16,
              "constrained enumeration subtype should allow in-range Succ");
      Assert (Width_Size.Has_Static_Value and then Width_Size.Static_Value = 20,
              "constrained enumeration subtype should preserve Width metadata");
      Assert (Modulus_Size.Has_Static_Value and then Modulus_Size.Static_Value = 16,
              "constrained modular subtype should preserve modular category metadata");
      Assert (not Bad_Succ_Size.Has_Static_Value,
              "Succ beyond a constrained enumeration subtype high bound should stay nonstatic");
      Assert (Seen_Bad_Succ_Error,
              "out-of-range constrained enumeration Succ should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Constrained_Discrete_Subtype_Pass;




   procedure Test_Language_Model_Representation_Static_Discrete_Constant_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   Default_Color : constant Color := Green;" & ASCII.LF &
        "   Next_Color : constant Color := Default_Color;" & ASCII.LF &
        "   Bad_Color : constant Color := Not_A_Color;" & ASCII.LF &
        "   type From_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Pos'Size use Color'Pos (Default_Color) * 8;" & ASCII.LF &
        "   type From_Succ is range 0 .. 255;" & ASCII.LF &
        "   for From_Succ'Size use Color'Succ (Default_Color) * 8;" & ASCII.LF &
        "   type From_Chained is range 0 .. 255;" & ASCII.LF &
        "   for From_Chained'Size use Color'Pos (Next_Color) * 8;" & ASCII.LF &
        "   type Bad_From_Pos is range 0 .. 255;" & ASCII.LF &
        "   for Bad_From_Pos'Size use Color'Pos (Bad_Color) * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Pos");
      From_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Succ");
      From_Chained_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Chained");
      Bad_From_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_From_Pos");
      Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Chained_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (From_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "discrete constant Pos target should be retained");
      Assert (From_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "discrete constant Succ target should be retained");
      Assert (From_Chained_Id /= Editor.Ada_Language_Model.No_Symbol,
              "chained discrete constant target should be retained");
      Assert (Bad_From_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad discrete constant target should be retained");

      Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Pos_Id, 1);
      Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Succ_Id, 1);
      Chained_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Chained_Id, 1);
      Bad_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_From_Pos_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_From_Pos"
            then
               Seen_Bad_Error := True;
            end if;
         end;
      end loop;

      Assert (Pos_Size.Has_Static_Value and then Pos_Size.Static_Value = 8,
              "typed enumeration constants should feed T'Pos");
      Assert (Succ_Size.Has_Static_Value and then Succ_Size.Static_Value = 16,
              "typed enumeration constants should feed T'Succ");
      Assert (Chained_Size.Has_Static_Value and then Chained_Size.Static_Value = 8,
              "static discrete constants should be reusable through another constant");
      Assert (not Bad_Pos_Size.Has_Static_Value,
              "unknown discrete constants should not be retained as static operands");
      Assert (Seen_Bad_Error,
              "unknown discrete constants should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Discrete_Constant_Pass;




   procedure Test_Language_Model_Representation_Static_Qualified_Discrete_Constant_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary_Color is Color range Red .. Green;" & ASCII.LF &
        "   Default_Color : constant Color := Color'(Green);" & ASCII.LF &
        "   Primary_Qualified_Color : constant Color := Primary_Color'(Green);" & ASCII.LF &
        "   Bad_Primary_Qualified_Color : constant Color := Primary_Color'(Blue);" & ASCII.LF &
        "   Base_Color : constant Color := Color'Base'(Blue);" & ASCII.LF &
        "   Subtype_Base_Color : constant Color := Primary_Color'Base'(Blue);" & ASCII.LF &
        "   Spaced_Base_Color : constant Color := Color' Base'(Blue);" & ASCII.LF &
        "   Spaced_Subtype_Base_Color : constant Color := Primary_Color' Base'(Blue);" & ASCII.LF &
        "   Bad_Spaced_Subtype_Base_Primary : constant Primary_Color := Primary_Color' Base'(Blue);" & ASCII.LF &
        "   Bad_Subtype_Base_Primary : constant Primary_Color := Primary_Color'Base'(Blue);" & ASCII.LF &
        "   Truth : constant Boolean := Boolean'(True);" & ASCII.LF &
        "   Letter : constant Character := Character'('A');" & ASCII.LF &
        "   Spaced_Letter : constant Character := Character' ('B');" & ASCII.LF &
        "   Spaced_Succ_Letter : constant Character := Character' Succ (Spaced_Letter);" & ASCII.LF &
        "   subtype Uppercase is Character range 'A' .. 'Z';" & ASCII.LF &
        "   First_Uppercase : constant Character := Uppercase' First;" & ASCII.LF &
        "   Nested_Color : constant Color := Color'Max (Color'Min (Red, Green), Blue);" & ASCII.LF &
        "   Val_Expr_Color : constant Color := Color'Val (1 + 0);" & ASCII.LF &
        "   Val_Char_Expr_Color : constant Color := Color'Val (Character'Pos ('(') - Character'Pos ('(') + 1);" & ASCII.LF &
        "   type From_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Qualified_Pos'Size use Color'Pos (Default_Color) * 8;" & ASCII.LF &
        "   type From_Primary_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Primary_Qualified_Pos'Size use Color'Pos (Primary_Qualified_Color) * 8;" & ASCII.LF &
        "   type From_Bad_Primary_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Bad_Primary_Qualified_Pos'Size use Color'Pos (Bad_Primary_Qualified_Color) * 8;" & ASCII.LF &
        "   type From_Base_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Base_Qualified_Pos'Size use Color'Pos (Base_Color) * 8;" & ASCII.LF &
        "   type From_Subtype_Base_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Subtype_Base_Qualified_Pos'Size use Color'Pos (Subtype_Base_Color) * 8;" & ASCII.LF &
        "   type From_Spaced_Base_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Spaced_Base_Qualified_Pos'Size use Color'Pos (Spaced_Base_Color) * 8;" & ASCII.LF &
        "   type From_Spaced_Subtype_Base_Qualified_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Spaced_Subtype_Base_Qualified_Pos'Size use Color'Pos (Spaced_Subtype_Base_Color) * 8;" & ASCII.LF &
        "   type From_Bad_Spaced_Subtype_Base_Primary_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Bad_Spaced_Subtype_Base_Primary_Pos'Size use Color'Pos (Bad_Spaced_Subtype_Base_Primary) * 8;" & ASCII.LF &
        "   type From_Bad_Subtype_Base_Primary_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Bad_Subtype_Base_Primary_Pos'Size use Color'Pos (Bad_Subtype_Base_Primary) * 8;" & ASCII.LF &
        "   type From_Boolean is range 0 .. 255;" & ASCII.LF &
        "   for From_Boolean'Size use Boolean'Pos (Truth) * 8;" & ASCII.LF &
        "   type From_Character is range 0 .. 1024;" & ASCII.LF &
        "   for From_Character'Size use Character'Pos (Letter);" & ASCII.LF &
        "   type From_Spaced_Character is range 0 .. 1024;" & ASCII.LF &
        "   for From_Spaced_Character'Size use Character'Pos (Spaced_Letter);" & ASCII.LF &
        "   type From_Spaced_Succ_Character is range 0 .. 1024;" & ASCII.LF &
        "   for From_Spaced_Succ_Character'Size use Character'Pos (Spaced_Succ_Letter);" & ASCII.LF &
        "   type From_Spaced_First_Character is range 0 .. 1024;" & ASCII.LF &
        "   for From_Spaced_First_Character'Size use Character'Pos (First_Uppercase);" & ASCII.LF &
        "   type From_Nested_Min_Max is range 0 .. 255;" & ASCII.LF &
        "   for From_Nested_Min_Max'Size use Color'Pos (Nested_Color) * 8;" & ASCII.LF &
        "   type From_Val_Expr is range 0 .. 255;" & ASCII.LF &
        "   for From_Val_Expr'Size use Color'Pos (Val_Expr_Color) * 8;" & ASCII.LF &
        "   type From_Val_Char_Expr is range 0 .. 255;" & ASCII.LF &
        "   for From_Val_Char_Expr'Size use Color'Pos (Val_Char_Expr_Color) * 8;" & ASCII.LF &
        "   type From_Direct_Min_Max_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Direct_Min_Max_Pos'Size use Color'Pos (Color'Max (Color'Min (Red, Green), Blue)) * 8;" & ASCII.LF &
        "   type From_Direct_Min_Max is range 0 .. 255;" & ASCII.LF &
        "   for From_Direct_Min_Max'Size use Color'Max (Color'Min (Red, Green), Blue) * 8;" & ASCII.LF &
        "   type From_Direct_Qualified_Succ is range 0 .. 255;" & ASCII.LF &
        "   for From_Direct_Qualified_Succ'Size use Color'Succ (Color'(Green)) * 8;" & ASCII.LF &
        "   type From_Direct_Subtype_Base_Val is range 0 .. 255;" & ASCII.LF &
        "   for From_Direct_Subtype_Base_Val'Size use Primary_Color'Base'Val (2) * 8;" & ASCII.LF &
        "   type From_Direct_Subtype_Base_Succ is range 0 .. 255;" & ASCII.LF &
        "   for From_Direct_Subtype_Base_Succ'Size use Primary_Color'Base'Succ (Green) * 8;" & ASCII.LF &
        "   type From_Direct_Subtype_Base_Last is range 0 .. 255;" & ASCII.LF &
        "   for From_Direct_Subtype_Base_Last'Size use Primary_Color'Base'Last * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Qualified_Pos");
      From_Primary_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Primary_Qualified_Pos");
      From_Bad_Primary_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Bad_Primary_Qualified_Pos");
      From_Base_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Qualified_Pos");
      From_Subtype_Base_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Subtype_Base_Qualified_Pos");
      From_Spaced_Base_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Spaced_Base_Qualified_Pos");
      From_Spaced_Subtype_Base_Qualified_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Spaced_Subtype_Base_Qualified_Pos");
      From_Bad_Spaced_Subtype_Base_Primary_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Bad_Spaced_Subtype_Base_Primary_Pos");
      From_Bad_Subtype_Base_Primary_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Bad_Subtype_Base_Primary_Pos");
      From_Boolean_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Boolean");
      From_Character_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Character");
      From_Spaced_Character_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Spaced_Character");
      From_Spaced_Succ_Character_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Spaced_Succ_Character");
      From_Spaced_First_Character_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Spaced_First_Character");
      From_Nested_Min_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Nested_Min_Max");
      From_Val_Expr_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Val_Expr");
      From_Val_Char_Expr_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Val_Char_Expr");
      From_Direct_Min_Max_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Direct_Min_Max_Pos");
      From_Direct_Min_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Direct_Min_Max");
      From_Direct_Qualified_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Direct_Qualified_Succ");
      From_Direct_Subtype_Base_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Direct_Subtype_Base_Val");
      From_Direct_Subtype_Base_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Direct_Subtype_Base_Succ");
      From_Direct_Subtype_Base_Last_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Direct_Subtype_Base_Last");
      Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Primary_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Primary_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Base_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Subtype_Base_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Spaced_Base_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Spaced_Subtype_Base_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Spaced_Subtype_Base_Primary_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Subtype_Base_Primary_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Boolean_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Character_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Spaced_Character_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Spaced_Succ_Character_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Spaced_First_Character_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Nested_Min_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Val_Expr_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Val_Char_Expr_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Direct_Min_Max_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Direct_Min_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Direct_Qualified_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Direct_Subtype_Base_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Direct_Subtype_Base_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Direct_Subtype_Base_Last_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (From_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified discrete constant Pos target should be retained");
      Assert (From_Primary_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subtype-qualified discrete constant Pos target should be retained");
      Assert (From_Bad_Primary_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad subtype-qualified discrete constant Pos target should be retained");
      Assert (From_Base_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base-qualified discrete constant Pos target should be retained");
      Assert (From_Subtype_Base_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subtype Base-qualified discrete constant Pos target should be retained");
      Assert (From_Spaced_Base_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced Base-qualified discrete constant Pos target should be retained");
      Assert (From_Spaced_Subtype_Base_Qualified_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced subtype Base-qualified discrete constant Pos target should be retained");
      Assert (From_Bad_Spaced_Subtype_Base_Primary_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad spaced subtype Base-qualified discrete constant Pos target should be retained");
      Assert (From_Bad_Subtype_Base_Primary_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad subtype Base-qualified discrete constant Pos target should be retained");
      Assert (From_Boolean_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified Boolean constant target should be retained");
      Assert (From_Character_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified Character constant target should be retained");
      Assert (From_Spaced_Character_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced qualified Character constant target should be retained");
      Assert (From_Spaced_Succ_Character_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced attribute-function Character constant target should be retained");
      Assert (From_Spaced_First_Character_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced attribute-bound Character constant target should be retained");
      Assert (From_Nested_Min_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "nested Min/Max discrete constant target should be retained");
      Assert (From_Val_Expr_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Val expression target should be retained");
      Assert (From_Val_Char_Expr_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Val character-expression target should be retained");
      Assert (From_Direct_Min_Max_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct nested Min/Max Pos target should be retained");
      Assert (From_Direct_Min_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct nested Min/Max arithmetic target should be retained");
      Assert (From_Direct_Qualified_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct qualified Succ arithmetic target should be retained");
      Assert (From_Direct_Subtype_Base_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct subtype Base Val arithmetic target should be retained");
      Assert (From_Direct_Subtype_Base_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct subtype Base Succ arithmetic target should be retained");
      Assert (From_Direct_Subtype_Base_Last_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct subtype Base Last arithmetic target should be retained");

      Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Qualified_Pos_Id, 1);
      Primary_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Primary_Qualified_Pos_Id, 1);
      Bad_Primary_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Bad_Primary_Qualified_Pos_Id, 1);
      Base_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Qualified_Pos_Id, 1);
      Subtype_Base_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Subtype_Base_Qualified_Pos_Id, 1);
      Spaced_Base_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Spaced_Base_Qualified_Pos_Id, 1);
      Spaced_Subtype_Base_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Spaced_Subtype_Base_Qualified_Pos_Id, 1);
      Bad_Spaced_Subtype_Base_Primary_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Bad_Spaced_Subtype_Base_Primary_Pos_Id, 1);
      Bad_Subtype_Base_Primary_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Bad_Subtype_Base_Primary_Pos_Id, 1);
      Boolean_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Boolean_Id, 1);
      Character_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Character_Id, 1);
      Spaced_Character_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Spaced_Character_Id, 1);
      Spaced_Succ_Character_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Spaced_Succ_Character_Id, 1);
      Spaced_First_Character_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Spaced_First_Character_Id, 1);
      Nested_Min_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Nested_Min_Max_Id, 1);
      Val_Expr_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Val_Expr_Id, 1);
      Val_Char_Expr_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Val_Char_Expr_Id, 1);
      Direct_Min_Max_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Direct_Min_Max_Pos_Id, 1);
      Direct_Min_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Direct_Min_Max_Id, 1);
      Direct_Qualified_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Direct_Qualified_Succ_Id, 1);
      Direct_Subtype_Base_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Direct_Subtype_Base_Val_Id, 1);
      Direct_Subtype_Base_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Direct_Subtype_Base_Succ_Id, 1);
      Direct_Subtype_Base_Last_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Direct_Subtype_Base_Last_Id, 1);

      Assert (Qualified_Size.Has_Static_Value and then Qualified_Size.Static_Value = 8,
              "qualified enumeration constants should feed T'Pos");
      Assert (Primary_Qualified_Size.Has_Static_Value
              and then Primary_Qualified_Size.Static_Value = 8,
              "subtype-qualified enumeration constants should feed T'Pos");
      Assert (not Bad_Primary_Qualified_Size.Has_Static_Value,
              "out-of-range subtype-qualified enumeration constants should not be retained");
      Assert (Base_Qualified_Size.Has_Static_Value and then Base_Qualified_Size.Static_Value = 16,
              "Base-qualified enumeration constants should feed T'Pos");
      Assert (Subtype_Base_Qualified_Size.Has_Static_Value
              and then Subtype_Base_Qualified_Size.Static_Value = 16,
              "subtype Base-qualified enumeration constants should feed base T'Pos");
      Assert (Spaced_Base_Qualified_Size.Has_Static_Value
              and then Spaced_Base_Qualified_Size.Static_Value = 16,
              "spaced Base-qualified enumeration constants should feed T'Pos");
      Assert (Spaced_Subtype_Base_Qualified_Size.Has_Static_Value
              and then Spaced_Subtype_Base_Qualified_Size.Static_Value = 16,
              "spaced subtype Base-qualified enumeration constants should feed base T'Pos");
      Assert (not Bad_Spaced_Subtype_Base_Primary_Size.Has_Static_Value,
              "spaced subtype Base-qualified values outside the declared object subtype should stay nonstatic");
      Assert (not Bad_Subtype_Base_Primary_Size.Has_Static_Value,
              "subtype Base-qualified values outside the declared object subtype should stay nonstatic");
      Assert (Boolean_Size.Has_Static_Value and then Boolean_Size.Static_Value = 8,
              "qualified Boolean constants should feed Boolean'Pos");
      Assert (Character_Size.Has_Static_Value and then Character_Size.Static_Value = 65,
              "qualified Character constants should feed Character'Pos");
      Assert (Spaced_Character_Size.Has_Static_Value
              and then Spaced_Character_Size.Static_Value = 66,
              "spaced qualified Character constants should feed Character'Pos");
      Assert (Spaced_Succ_Character_Size.Has_Static_Value
              and then Spaced_Succ_Character_Size.Static_Value = 67,
              "spaced attribute-function Character constants should feed Character'Pos");
      Assert (Spaced_First_Character_Size.Has_Static_Value
              and then Spaced_First_Character_Size.Static_Value = 65,
              "spaced attribute-bound Character constants should feed Character'Pos");
      Assert (Nested_Min_Max_Size.Has_Static_Value
              and then Nested_Min_Max_Size.Static_Value = 16,
              "nested Min/Max discrete constants should feed Color'Pos");
      Assert (Val_Expr_Size.Has_Static_Value
              and then Val_Expr_Size.Static_Value = 8,
              "T'Val natural static-expression constants should feed Color'Pos");
      Assert (Val_Char_Expr_Size.Has_Static_Value
              and then Val_Char_Expr_Size.Static_Value = 8,
              "T'Val character-derived static expressions should feed Color'Pos");
      Assert (Direct_Min_Max_Pos_Size.Has_Static_Value
              and then Direct_Min_Max_Pos_Size.Static_Value = 16,
              "direct nested Min/Max operands should feed Color'Pos");
      Assert (Direct_Min_Max_Size.Has_Static_Value
              and then Direct_Min_Max_Size.Static_Value = 16,
              "direct nested Min/Max operands should feed Size arithmetic");
      Assert (Direct_Qualified_Succ_Size.Has_Static_Value
              and then Direct_Qualified_Succ_Size.Static_Value = 16,
              "direct qualified Succ operands should feed Size arithmetic");
      Assert (Direct_Subtype_Base_Val_Size.Has_Static_Value
              and then Direct_Subtype_Base_Val_Size.Static_Value = 16,
              "subtype Base Val should use root scalar range in Size arithmetic");
      Assert (Direct_Subtype_Base_Succ_Size.Has_Static_Value
              and then Direct_Subtype_Base_Succ_Size.Static_Value = 16,
              "subtype Base Succ should use root scalar range in Size arithmetic");
      Assert (Direct_Subtype_Base_Last_Size.Has_Static_Value
              and then Direct_Subtype_Base_Last_Size.Static_Value = 16,
              "subtype Base Last should use root scalar range in Size arithmetic");
   end Test_Language_Model_Representation_Static_Qualified_Discrete_Constant_Pass;




   procedure Test_Language_Model_Representation_Static_Discrete_Subtype_Constant_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color range Red .. Green;" & ASCII.LF &
        "   Default_Primary : constant Primary := Green;" & ASCII.LF &
        "   Default_Color : constant Color := Green;" & ASCII.LF &
        "   Bad_Color : constant Color := Blue;" & ASCII.LF &
        "   type From_Base_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Base_Pos'Size use Color'Pos (Default_Primary) * 8;" & ASCII.LF &
        "   type From_Subtype_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Subtype_Pos'Size use Primary'Pos (Default_Color) * 8;" & ASCII.LF &
        "   type Bad_Subtype_Pos is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Subtype_Pos'Size use Primary'Pos (Bad_Color) * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Base_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Pos");
      From_Subtype_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Subtype_Pos");
      Bad_Subtype_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Subtype_Pos");
      Base_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Subtype_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (From_Base_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "base Pos target using subtype constant should be retained");
      Assert (From_Subtype_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subtype Pos target using base constant should be retained");
      Assert (Bad_Subtype_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad subtype Pos target should be retained");

      Base_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Pos_Id, 1);
      Subtype_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Subtype_Pos_Id, 1);
      Bad_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Subtype_Pos_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Diagnostic_Info :=
              Editor.Ada_Language_Model.Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Subtype_Pos"
            then
               Seen_Bad_Error := True;
            end if;
         end;
      end loop;

      Assert (Base_Size.Has_Static_Value and then Base_Size.Static_Value = 8,
              "subtype discrete constants should feed base T'Pos");
      Assert (Subtype_Size.Has_Static_Value and then Subtype_Size.Static_Value = 8,
              "base discrete constants should feed subtype T'Pos when in range");
      Assert (not Bad_Size.Has_Static_Value,
              "base discrete constants outside a constrained subtype should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range subtype discrete constants should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Discrete_Subtype_Constant_Pass;





   procedure Test_Language_Model_Representation_Static_Discrete_Attribute_Constant_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color range Red .. Green;" & ASCII.LF &
        "   From_Val : constant Color := Color'Val (1);" & ASCII.LF &
        "   From_Base_Val : constant Color := Color'Base'Val (2);" & ASCII.LF &
        "   From_Succ : constant Color := Color'Succ (From_Val);" & ASCII.LF &
        "   From_Pred : constant Color := Color'Pred (From_Base_Val);" & ASCII.LF &
        "   From_Min : constant Color := Color'Min (Green, Blue);" & ASCII.LF &
        "   From_Max : constant Primary := Color'Max (Red, Green);" & ASCII.LF &
        "   From_First : constant Color := Color'First;" & ASCII.LF &
        "   From_Last : constant Color := Color'Last;" & ASCII.LF &
        "   From_Base_Last : constant Color := Color'Base'Last;" & ASCII.LF &
        "   Bad_Primary : constant Primary := Color'Val (2);" & ASCII.LF &
        "   Bad_Last : constant Primary := Color'Last;" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Val) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (From_Base_Val) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Color'Pos (From_Succ) * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Color'Pos (From_Pred) * 8;" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Color'Pos (From_Min) * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use Primary'Pos (From_Max) * 8;" & ASCII.LF &
        "   type V7 is range 0 .. 255;" & ASCII.LF &
        "   for V7'Size use Color'Pos (From_First) * 8;" & ASCII.LF &
        "   type V8 is range 0 .. 255;" & ASCII.LF &
        "   for V8'Size use Color'Pos (From_Last) * 8;" & ASCII.LF &
        "   type V9 is range 0 .. 255;" & ASCII.LF &
        "   for V9'Size use Color'Pos (From_Base_Last) * 8;" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Primary'Pos (Bad_Primary) * 8;" & ASCII.LF &
        "   type Bad2 is range 0 .. 255;" & ASCII.LF &
        "   for Bad2'Size use Primary'Pos (Bad_Last) * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      V1_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V1");
      V2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V2");
      V3_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V3");
      V4_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V4");
      V5_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V5");
      V6_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V6");
      V7_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V7");
      V8_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V8");
      V9_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V9");
      V10_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V10");
      V11_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V11");
      Bad_String_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_String");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
      Bad2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad2");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V4_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V5_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V6_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V7_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V8_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V9_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V10_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V11_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_String_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
      Seen_Bad2_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Val constant target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Val constant target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Succ constant target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Pred constant target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Min constant target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Max constant target should be retained");
      Assert (V7_Id /= Editor.Ada_Language_Model.No_Symbol,
              "First constant target should be retained");
      Assert (V8_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Last constant target should be retained");
      Assert (V9_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Last constant target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad attribute constant target should be retained");
      Assert (Bad2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Last attribute constant target should be retained");

      V1_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V1_Id, 1);
      V2_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V2_Id, 1);
      V3_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V3_Id, 1);
      V4_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V4_Id, 1);
      V5_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V5_Id, 1);
      V6_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V6_Id, 1);
      V7_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V7_Id, 1);
      V8_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V8_Id, 1);
      V9_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V9_Id, 1);
      V10_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V10_Id, 1);
      V11_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V11_Id, 1);
      Bad_String_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_String_Id, 1);
      V3_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V3_Id, 1);
      V5_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V5_Id, 1);
      Bad_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Id, 1);
      Bad2_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad2_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad"
            then
               Seen_Bad_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad2"
            then
               Seen_Bad2_Error := True;
            end if;
         end;
      end loop;

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 8,
              "discrete constants initialized by T'Val should feed T'Pos");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 16,
              "discrete constants initialized by T'Base'Val should feed T'Pos");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 16,
              "discrete constants initialized by T'Succ should feed T'Pos");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = 8,
              "discrete constants initialized by T'Pred should feed T'Pos");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 8,
              "discrete constants initialized by T'Min should feed T'Pos");
      Assert (V6_Size.Has_Static_Value and then V6_Size.Static_Value = 8,
              "subtype constants initialized by compatible T'Max should feed subtype T'Pos");
      Assert (V7_Size.Has_Static_Value and then V7_Size.Static_Value = 0,
              "discrete constants initialized by T'First should feed T'Pos");
      Assert (V8_Size.Has_Static_Value and then V8_Size.Static_Value = 16,
              "discrete constants initialized by T'Last should feed T'Pos");
      Assert (V9_Size.Has_Static_Value and then V9_Size.Static_Value = 16,
              "discrete constants initialized by T'Base'Last should feed T'Pos");
      Assert (not Bad_Size.Has_Static_Value,
              "out-of-range attribute-initialized subtype constants should stay nonstatic");
      Assert (not Bad2_Size.Has_Static_Value,
              "out-of-range Last-initialized subtype constants should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range attribute-initialized subtype constants should produce a static-value diagnostic");
      Assert (Seen_Bad2_Error,
              "out-of-range Last-initialized subtype constants should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Discrete_Attribute_Constant_Pass;




   procedure Test_Language_Model_Representation_Static_Discrete_Parenthesized_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   Default_Color : constant Color := (Green);" & ASCII.LF &
        "   Nested_Color : constant Color := ((Default_Color));" & ASCII.LF &
        "   From_Succ : constant Color := Color'Succ ((Default_Color));" & ASCII.LF &
        "   From_Qualified : constant Color := Color'((Blue));" & ASCII.LF &
        "   RParen : constant Character := (')');" & ASCII.LF &
        "   Bad_Color : constant Color := (Unknown_Color);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (Default_Color) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (Nested_Color) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Color'Pos (From_Succ) * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Color'Pos (From_Qualified) * 8;" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Character'Pos (RParen);" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Color'Pos (Bad_Color) * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      V1_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V1");
      V2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V2");
      V3_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V3");
      V4_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V4");
      V5_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V5");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V4_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V5_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parenthesized literal constant target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "nested parenthesized constant target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parenthesized attribute operand target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parenthesized qualified expression target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parenthesized right-paren character target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad parenthesized discrete target should be retained");

      V1_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V1_Id, 1);
      V2_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V2_Id, 1);
      V3_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V3_Id, 1);
      V4_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V4_Id, 1);
      V5_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V5_Id, 1);
      Bad_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad"
            then
               Seen_Bad_Error := True;
            end if;
         end;
      end loop;

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 8,
              "parenthesized discrete literal constants should feed T'Pos");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "nested parenthesized discrete constants should feed T'Pos");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 16,
              "parenthesized discrete operands should feed T'Succ constants");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = 16,
              "parenthesized qualified discrete defaults should feed T'Pos");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = Character'Pos (')'),
              "parenthesized character literals containing a parenthesis should feed Character'Pos");
      Assert (not Bad_Size.Has_Static_Value,
              "unknown parenthesized discrete constants should stay nonstatic");
      Assert (Seen_Bad_Error,
              "unknown parenthesized discrete constants should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Discrete_Parenthesized_Pass;







   procedure Test_Language_Model_Representation_Static_Discrete_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color range Red .. Green;" & ASCII.LF &
        "   From_Value : constant Color := Color'Value (""Blue"");" & ASCII.LF &
        "   From_Primary : constant Primary := Color'Value (""Green"");" & ASCII.LF &
        "   From_Boolean : constant Boolean := Boolean'Value (""True"");" & ASCII.LF &
        "   From_Character : constant Character := Character'Value (""'A'"");" & ASCII.LF &
        "   From_Direct : constant Color := Color'Succ (Color'Value (""Red""));" & ASCII.LF &
        "   From_Image : constant Color := Color'Value (Color'Image (Green));" & ASCII.LF &
        "   From_Image_Base : constant Color := Color'Value (Color'Base'Image (Blue));" & ASCII.LF &
        "   From_Boolean_Image : constant Boolean := Boolean'Value (Boolean'Image (True));" & ASCII.LF &
        "   Named_Green : constant String := ""Green"";" & ASCII.LF &
        "   Named_Image : constant String := Color'Image (Blue);" & ASCII.LF &
        "   From_Named_String : constant Color := Color'Value (Named_Green);" & ASCII.LF &
        "   From_Named_Image : constant Color := Color'Value (Named_Image);" & ASCII.LF &
        "   Bad_Named_Blue : constant String := ""Blue"";" & ASCII.LF &
        "   Bad_Primary_From_String : constant Primary := Color'Value (Bad_Named_Blue);" & ASCII.LF &
        "   Bad_Primary : constant Primary := Color'Value (""Blue"");" & ASCII.LF &
        "   Bad_Image_Primary : constant Primary := Color'Value (Color'Image (Blue));" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Value) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Primary'Pos (From_Primary) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Boolean'Pos (From_Boolean) * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Character'Pos (From_Character);" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Color'Pos (From_Direct) * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use Color'Pos (Color'Value (""Green"")) * 8;" & ASCII.LF &
        "   type V7 is range 0 .. 255;" & ASCII.LF &
        "   for V7'Size use Color'Pos (From_Image) * 8;" & ASCII.LF &
        "   type V8 is range 0 .. 255;" & ASCII.LF &
        "   for V8'Size use Color'Pos (From_Image_Base) * 8;" & ASCII.LF &
        "   type V9 is range 0 .. 255;" & ASCII.LF &
        "   for V9'Size use Boolean'Pos (From_Boolean_Image) * 8;" & ASCII.LF &
        "   type V10 is range 0 .. 255;" & ASCII.LF &
        "   for V10'Size use Color'Pos (From_Named_String) * 8;" & ASCII.LF &
        "   type V11 is range 0 .. 255;" & ASCII.LF &
        "   for V11'Size use Color'Pos (From_Named_Image) * 8;" & ASCII.LF &
        "   type V12 is range 0 .. 255;" & ASCII.LF &
        "   for V12'Size use Color'Pos (Color'Value (Color'Image (Green))) * 8;" & ASCII.LF &
        "   type V13 is range 0 .. 255;" & ASCII.LF &
        "   for V13'Size use Color'Base'Pos (Color'Base'Value (Color'Base'Image (Blue))) * 8;" & ASCII.LF &
        "   type Bad_String is range 0 .. 255;" & ASCII.LF &
        "   for Bad_String'Size use Primary'Pos (Bad_Primary_From_String) * 8;" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Primary'Pos (Bad_Primary) * 8;" & ASCII.LF &
        "   type Bad_Image is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Image'Size use Primary'Pos (Bad_Image_Primary) * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      V1_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V1");
      V2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V2");
      V3_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V3");
      V4_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V4");
      V5_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V5");
      V6_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V6");
      V7_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V7");
      V8_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V8");
      V9_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V9");
      V10_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V10");
      V11_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V11");
      V12_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V12");
      V13_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V13");
      Bad_String_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_String");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
      Bad_Image_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Image");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V4_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V5_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V6_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V7_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V8_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V9_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V10_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V11_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V12_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V13_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_String_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Image_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Value constant target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Value constrained subtype target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Boolean Value target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Character Value target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Value nested in Succ target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct Value operand target should be retained");
      Assert (V7_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Image-fed Value target should be retained");
      Assert (V8_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Image-fed Value target should be retained");
      Assert (V9_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Boolean Image-fed Value target should be retained");
      Assert (V10_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named string-fed Value target should be retained");
      Assert (V11_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named Image-fed Value target should be retained");
      Assert (V12_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct Image-fed Value target should be retained");
      Assert (V13_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct Base Image-fed Value target should be retained");
      Assert (Bad_String_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad named string-fed Value target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Value target should be retained");
      Assert (Bad_Image_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Image-fed Value target should be retained");

      V1_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V1_Id, 1);
      V2_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V2_Id, 1);
      V3_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V3_Id, 1);
      V4_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V4_Id, 1);
      V5_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V5_Id, 1);
      V6_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V6_Id, 1);
      V7_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V7_Id, 1);
      V8_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V8_Id, 1);
      V9_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V9_Id, 1);
      V10_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V10_Id, 1);
      V11_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V11_Id, 1);
      V12_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V12_Id, 1);
      V13_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V13_Id, 1);
      Bad_String_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_String_Id, 1);
      Bad_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Id, 1);
      Bad_Image_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Image_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then (To_String (Info.Target_Name) = "Bad"
                        or else To_String (Info.Target_Name) = "Bad_Image"
                        or else To_String (Info.Target_Name) = "Bad_String")
            then
               Seen_Bad_Error := True;
            end if;
         end;
      end loop;

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 16,
              "Color'Value string constants should feed Color'Pos");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "compatible constrained subtype Value constants should feed Pos");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 8,
              "Boolean'Value string constants should feed Boolean'Pos");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = Character'Pos ('A'),
              "Character'Value string constants should feed Character'Pos");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 8,
              "Value results nested in discrete attributes should stay static");
      Assert (V6_Size.Has_Static_Value and then V6_Size.Static_Value = 8,
              "direct Value attribute operands should feed Pos");
      Assert (V7_Size.Has_Static_Value and then V7_Size.Static_Value = 8,
              "Image-fed Value constants should feed Color'Pos");
      Assert (V8_Size.Has_Static_Value and then V8_Size.Static_Value = 16,
              "Base Image-fed Value constants should feed Color'Pos");
      Assert (V9_Size.Has_Static_Value and then V9_Size.Static_Value = 8,
              "Boolean Image-fed Value constants should feed Boolean'Pos");
      Assert (V10_Size.Has_Static_Value and then V10_Size.Static_Value = 8,
              "named string constants should feed scalar Value constants");
      Assert (V11_Size.Has_Static_Value and then V11_Size.Static_Value = 16,
              "named Image constants should feed scalar Value constants");
      Assert (V12_Size.Has_Static_Value and then V12_Size.Static_Value = 8,
              "direct Image-fed Value operands should feed Color'Pos");
      Assert (V13_Size.Has_Static_Value and then V13_Size.Static_Value = 16,
              "direct Base Image-fed Value operands should feed Color'Pos");
      Assert (not Bad_String_Size.Has_Static_Value,
              "named out-of-range Value constants should stay nonstatic");
      Assert (not Bad_Size.Has_Static_Value,
              "out-of-range Value-initialized subtype constants should stay nonstatic");
      Assert (not Bad_Image_Size.Has_Static_Value,
              "out-of-range Image-fed Value subtype constants should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range Value constants should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Discrete_Value_Pass;


   overriding function Name (T : Representation_Static_Discrete_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Representation.Static_Discrete");
   end Name;

   overriding procedure Register_Tests (T : in out Representation_Static_Discrete_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Representation_Static_Enumeration_Pos_Pass'Access, Name => "language model evaluates enumeration Pos and Val static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Predefined_Discrete_Pass'Access, Name => "language model evaluates predefined discrete Pos and Val static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Function_Literal_Pass'Access, Name => "language model evaluates discrete function literal operands in static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Alias_Literal_Pass'Access, Name => "language model preserves discrete literal metadata through subtype aliases and scalar derivations");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Width_Pass'Access, Name => "language model evaluates discrete Width attributes statically");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Constrained_Discrete_Subtype_Pass'Access, Name => "language model evaluates constrained discrete subtype static metadata");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Constant_Pass'Access, Name => "language model evaluates typed discrete static constants");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Qualified_Discrete_Constant_Pass'Access, Name => "language model evaluates qualified discrete static constants");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Subtype_Constant_Pass'Access, Name => "language model evaluates subtype-compatible discrete static constants");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Attribute_Constant_Pass'Access, Name => "language model evaluates attribute-initialized discrete static constants");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Parenthesized_Pass'Access, Name => "language model evaluates parenthesized discrete static expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Discrete_Value_Pass'Access, Name => "language model evaluates scalar Value attributes in discrete static expressions");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Static_Discrete_Tests;
