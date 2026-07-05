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

package body Editor.Syntax_Semantics.Representation_Static_String_Tests is






   procedure Test_Language_Model_Representation_Static_Character_Alias_Literal_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   subtype Letter is Character;" & ASCII.LF &
        "   type Derived_Character is new Character;" & ASCII.LF &
        "   type From_Letter_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Letter_Pos'Size use Letter'Pos ('A');" & ASCII.LF &
        "   type From_Letter_Succ is range 0 .. 255;" & ASCII.LF &
        "   for From_Letter_Succ'Size use Letter'Succ ('A');" & ASCII.LF &
        "   type From_Letter_Base_Max is range 0 .. 255;" & ASCII.LF &
        "   for From_Letter_Base_Max'Size use Letter'Base'Max ('A', 'B');" & ASCII.LF &
        "   type From_Derived_Pos is range 0 .. 255;" & ASCII.LF &
        "   for From_Derived_Pos'Size use Derived_Character'Pos ('C');" & ASCII.LF &
        "   type Good_Small is delta 0.01 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Letter'Pos ('D') / 100.0;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Letter_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Letter_Pos");
      From_Letter_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Letter_Succ");
      From_Letter_Base_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Letter_Base_Max");
      From_Derived_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Derived_Pos");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Letter_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Letter_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Letter_Base_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Derived_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Small_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (From_Letter_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Character alias Pos target should be retained");
      Assert (From_Letter_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Character alias Succ target should be retained");
      Assert (From_Letter_Base_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Character alias Base Max target should be retained");
      Assert (From_Derived_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived Character Pos target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Small target should be retained");

      Letter_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Letter_Pos_Id, 1);
      Letter_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Letter_Succ_Id, 1);
      Letter_Base_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Letter_Base_Max_Id, 1);
      Derived_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Derived_Pos_Id, 1);
      Small_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Good_Small_Id, 1);

      Assert (Letter_Pos_Size.Has_Static_Value
              and then Letter_Pos_Size.Static_Value = Character'Pos ('A'),
              "Character subtype aliases should preserve literal Pos metadata");
      Assert (Letter_Succ_Size.Has_Static_Value
              and then Letter_Succ_Size.Static_Value = Character'Pos ('B'),
              "Character subtype aliases should support literal Succ metadata");
      Assert (Letter_Base_Max_Size.Has_Static_Value
              and then Letter_Base_Max_Size.Static_Value = Character'Pos ('B'),
              "Character aliases should support literal Base'Max metadata");
      Assert (Derived_Pos_Size.Has_Static_Value
              and then Derived_Pos_Size.Static_Value = Character'Pos ('C'),
              "derived Character types should preserve literal Pos metadata");
      Assert (Small_Clause.Kind = Editor.Ada_Language_Model.Representation_Small_Clause,
              "Small clause should be retained for Character alias arithmetic");
   end Test_Language_Model_Representation_Static_Character_Alias_Literal_Pass;





   procedure Test_Language_Model_Representation_Static_String_Concat_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Primary is Color range Red .. Green;" & ASCII.LF &
        "   Green_Name : constant String := ""Gr"" & ""een"";" & ASCII.LF &
        "   Blue_Image : constant String := Color'Image (Blue);" & ASCII.LF &
        "   Blue_Name : constant String := (""Bl"" & ""ue"");" & ASCII.LF &
        "   Blue_Suffix : constant String := ""ue"";" & ASCII.LF &
        "   Green_With_Char : constant String := ""Gr"" & 'e' & ""en"";" & ASCII.LF &
        "   From_Concat : constant Color := Color'Value (Green_Name);" & ASCII.LF &
        "   From_Direct_Concat : constant Color := Color'Value (""G"" & ""reen"");" & ASCII.LF &
        "   From_Image_Concat : constant Color := Color'Value (""Bl"" & ""ue"");" & ASCII.LF &
        "   From_Mixed_Concat : constant Color := Color'Value (""Bl"" & Blue_Suffix);" & ASCII.LF &
        "   From_Char_Concat : constant Color := Color'Value (Green_With_Char);" & ASCII.LF &
        "   From_Direct_Char_Concat : constant Color := Color'Value (""G"" & 'r' & ""een"");" & ASCII.LF &
        "   Bad_Primary : constant Primary := Color'Value (Blue_Name);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Concat) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (From_Direct_Concat) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Color'Pos (From_Image_Concat) * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Color'Pos (From_Mixed_Concat) * 8;" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Color'Pos (From_Char_Concat) * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use Color'Pos (From_Direct_Char_Concat) * 8;" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Primary'Pos (Bad_Primary) * 8;" & ASCII.LF &
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
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V4_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V5_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V6_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "string-concat Value target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct string-concat Value target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parenthesized concat Value target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "mixed named/literal concat Value target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named character-concat Value target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct character-concat Value target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad string-concat Value target should be retained");

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
              "named concatenated strings should feed scalar Value constants");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "direct concatenated strings should feed scalar Value constants");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 16,
              "parenthesized concatenated strings should feed scalar Value constants");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = 16,
              "literal plus named string concat should feed scalar Value constants");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 8,
              "named character concat should feed scalar Value constants");
      Assert (V6_Size.Has_Static_Value and then V6_Size.Static_Value = 8,
              "direct character concat should feed scalar Value constants");
      Assert (not Bad_Size.Has_Static_Value,
              "out-of-range concatenated Value constants should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range concatenated Value constants should produce a diagnostic");
   end Test_Language_Model_Representation_Static_String_Concat_Value_Pass;





   procedure Test_Language_Model_Representation_Static_String_Qualification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Small_Name is String (1 .. 5);" & ASCII.LF &
        "   subtype Offset_Name is String (2 .. 6);" & ASCII.LF &
        "   subtype Standard_Name is Standard.String (2 .. 6);" & ASCII.LF &
        "   subtype Ranged_Name is String (Positive range 2 .. 6);" & ASCII.LF &
        "   subtype Alias_Name is Offset_Name;" & ASCII.LF &
        "   subtype Derived_Name is String (Offset_Name'First .. Offset_Name'Last);" & ASCII.LF &
        "   subtype Range_Derived_Name is String (Offset_Name'Range);" & ASCII.LF &
        "   subtype Range_Dim_Derived_Name is String (Offset_Name'Range (1));" & ASCII.LF &
        "   subtype Range_Expr_Derived_Name is String (Offset_Name'Range (1 + 0));" & ASCII.LF &
        "   subtype Range_Char_Dim_Derived_Name is String (Offset_Name'Range (1 + Character'Pos (')') - Character'Pos (')')));" & ASCII.LF &
        "   subtype Inline_Char_Dim_Range_Name is String (String'(""Green"")'Range (1 + Character'Pos (')') - Character'Pos (')')));" & ASCII.LF &
        "   subtype Subtype_Indication_Range_Name is String (Positive range Offset_Name'Range);" & ASCII.LF &
        "   subtype Dim_Derived_Name is String (Offset_Name'First (1) .. Offset_Name'Last (1));" & ASCII.LF &
        "   Qualified_Name : constant String := String'(""Gr"" & ""een"");" & ASCII.LF &
        "   subtype Constant_Range_Name is String (Qualified_Name'Range);" & ASCII.LF &
        "   subtype Constant_Bounds_Name is String (Qualified_Name'First .. Qualified_Name'Last);" & ASCII.LF &
        "   subtype Inline_Range_Name is String (String'(""Green"")'Range);" & ASCII.LF &
        "   subtype Inline_Text_Range_Name is String (String'(""range"")'Range);" & ASCII.LF &
        "   subtype Inline_Dot_Text_Range_Name is String (String'("".."")'Range);" & ASCII.LF &
        "   subtype Inline_Range_Dot_Text_Range_Name is String (String'(""range .."")'Range);" & ASCII.LF &
        "   subtype Inline_Offset_Range_Name is String (Offset_Name'(""Green"")'Range);" & ASCII.LF &
        "   subtype Direct_Bounds_Name is String (String'(""Green"")'First .. String'(""Green"")'Last);" & ASCII.LF &
        "   subtype Direct_Text_Bounds_Name is String (String'(""range"")'First .. String'(""range"")'Last);" & ASCII.LF &
        "   subtype Direct_Dim_Bounds_Name is String (String'(""Green"")'First (1) .. String'(""Green"")'Last (1));" & ASCII.LF &
        "   Small_Qualified : constant Small_Name := Small_Name'(""Gr"" & ""een"");" & ASCII.LF &
        "   Offset_Object : constant Offset_Name := Offset_Name'(""Green"");" & ASCII.LF &
        "   subtype Object_Dim_Derived_Name is String (Offset_Object'First (1) .. Offset_Object'Last (1));" & ASCII.LF &
        "   subtype Object_Range_Dim_Derived_Name is String (Offset_Object'Range (1));" & ASCII.LF &
        "   Bad_Qualified : constant Small_Name := Small_Name'(""Purple"");" & ASCII.LF &
        "   From_Qualified : constant Color := Color'Value (Qualified_Name);" & ASCII.LF &
        "   From_Small : constant Color := Color'Value (Small_Qualified);" & ASCII.LF &
        "   From_Direct : constant Color := Color'Value (String'(""Gr"" & ""een""));" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Qualified) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (From_Small) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Color'Pos (From_Direct) * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Qualified_Name'Length * 8;" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Small_Qualified'Length * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use Small_Name'First * 8;" & ASCII.LF &
        "   type V7 is range 0 .. 255;" & ASCII.LF &
        "   for V7'Size use Offset_Name'First * 8;" & ASCII.LF &
        "   type V8 is range 0 .. 255;" & ASCII.LF &
        "   for V8'Size use Offset_Name'Last * 8;" & ASCII.LF &
        "   type V9 is range 0 .. 255;" & ASCII.LF &
        "   for V9'Size use Offset_Name'Length * 8;" & ASCII.LF &
        "   type V10 is range 0 .. 255;" & ASCII.LF &
        "   for V10'Size use Ranged_Name'Last * 8;" & ASCII.LF &
        "   type V11 is range 0 .. 255;" & ASCII.LF &
        "   for V11'Size use Alias_Name'First * Alias_Name'Length * 8;" & ASCII.LF &
        "   type V12 is range 0 .. 255;" & ASCII.LF &
        "   for V12'Size use Color'Pos (Color'Value (String' (""Gr"" & ""een""))) * 8;" & ASCII.LF &
        "   type V13 is range 0 .. 255;" & ASCII.LF &
        "   for V13'Size use Offset_Name' (""Green"")'Last * 8;" & ASCII.LF &
        "   type V14 is range 0 .. 255;" & ASCII.LF &
        "   for V14'Size use Color'Pos (Color'Value (String'" & ASCII.HT &
        "     (""Gr"" & ""een""))) * 8;" & ASCII.LF &
        "   type V15 is range 0 .. 255;" & ASCII.LF &
        "   for V15'Size use Derived_Name'First * Derived_Name'Length * 8;" & ASCII.LF &
        "   type V16 is range 0 .. 255;" & ASCII.LF &
        "   for V16'Size use Range_Derived_Name'First * Range_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V17 is range 0 .. 255;" & ASCII.LF &
        "   for V17'Size use Dim_Derived_Name'First * Dim_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V18 is range 0 .. 255;" & ASCII.LF &
        "   for V18'Size use Object_Dim_Derived_Name'First * Object_Dim_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V19 is range 0 .. 255;" & ASCII.LF &
        "   for V19'Size use Range_Dim_Derived_Name'First * Range_Dim_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V20 is range 0 .. 255;" & ASCII.LF &
        "   for V20'Size use Object_Range_Dim_Derived_Name'First * Object_Range_Dim_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V21 is range 0 .. 255;" & ASCII.LF &
        "   for V21'Size use Constant_Range_Name'First * Constant_Range_Name'Length * 8;" & ASCII.LF &
        "   type V22 is range 0 .. 255;" & ASCII.LF &
        "   for V22'Size use Inline_Range_Name'First * Inline_Range_Name'Length * 8;" & ASCII.LF &
        "   type V23 is range 0 .. 255;" & ASCII.LF &
        "   for V23'Size use Inline_Offset_Range_Name'First * Inline_Offset_Range_Name'Length * 8;" & ASCII.LF &
        "   type V24 is range 0 .. 255;" & ASCII.LF &
        "   for V24'Size use Direct_Bounds_Name'First * Direct_Bounds_Name'Length * 8;" & ASCII.LF &
        "   type V25 is range 0 .. 255;" & ASCII.LF &
        "   for V25'Size use Direct_Dim_Bounds_Name'First * Direct_Dim_Bounds_Name'Length * 8;" & ASCII.LF &
        "   type V26 is range 0 .. 255;" & ASCII.LF &
        "   for V26'Size use Constant_Bounds_Name'First * Constant_Bounds_Name'Length * 8;" & ASCII.LF &
        "   type V27 is range 0 .. 255;" & ASCII.LF &
        "   for V27'Size use Standard_Name'First * Standard_Name'Length * 8;" & ASCII.LF &
        "   type V28 is range 0 .. 255;" & ASCII.LF &
        "   for V28'Size use Subtype_Indication_Range_Name'First * Subtype_Indication_Range_Name'Length * 8;" & ASCII.LF &
        "   type V29 is range 0 .. 255;" & ASCII.LF &
        "   for V29'Size use Inline_Text_Range_Name'First * Inline_Text_Range_Name'Length * 8;" & ASCII.LF &
        "   type V30 is range 0 .. 255;" & ASCII.LF &
        "   for V30'Size use Direct_Text_Bounds_Name'First * Direct_Text_Bounds_Name'Length * 8;" & ASCII.LF &
        "   type V31 is range 0 .. 255;" & ASCII.LF &
        "   for V31'Size use Inline_Dot_Text_Range_Name'First * Inline_Dot_Text_Range_Name'Length * 8;" & ASCII.LF &
        "   type V32 is range 0 .. 255;" & ASCII.LF &
        "   for V32'Size use Range_Expr_Derived_Name'First * Range_Expr_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V33 is range 0 .. 255;" & ASCII.LF &
        "   for V33'Size use Range_Char_Dim_Derived_Name'First * Range_Char_Dim_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V34 is range 0 .. 255;" & ASCII.LF &
        "   for V34'Size use Inline_Char_Dim_Range_Name'First * Inline_Char_Dim_Range_Name'Length * 8;" & ASCII.LF &
        "   type V35 is range 0 .. 255;" & ASCII.LF &
        "   for V35'Size use Inline_Range_Dot_Text_Range_Name'First * Inline_Range_Dot_Text_Range_Name'Length * 8;" & ASCII.LF &
        "   type Bad_Q is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Q'Size use Bad_Qualified'Length * 8;" & ASCII.LF &
        "   type Bad_Direct_Q is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Direct_Q'Size use Small_Name'(""Purple"")'Length * 8;" & ASCII.LF &
        "   type Bad_Alias_Q is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Alias_Q'Size use Alias_Name'(""Purple"")'Length * 8;" & ASCII.LF &
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
      V14_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V14");
      V15_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V15");
      V16_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V16");
      V17_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V17");
      V18_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V18");
      V19_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V19");
      V20_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V20");
      V21_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V21");
      V22_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V22");
      V23_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V23");
      V24_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V24");
      V25_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V25");
      V26_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V26");
      V27_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V27");
      V28_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V28");
      V29_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V29");
      V30_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V30");
      V31_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V31");
      V32_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V32");
      V33_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V33");
      V34_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V34");
      V35_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V35");
      Bad_Q_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Q");
      Bad_Direct_Q_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Direct_Q");
      Bad_Alias_Q_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Alias_Q");
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
      V14_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V15_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V16_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V17_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V18_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V19_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V20_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V21_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V22_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V23_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V24_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V25_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V26_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V27_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V28_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V29_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V30_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V31_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V32_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V33_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V34_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V35_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Q_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Direct_Q_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Alias_Q_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Q_Error : Boolean := False;
      Seen_Bad_Direct_Q_Error : Boolean := False;
      Seen_Bad_Alias_Q_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified String constant Value target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified constrained String constant target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct qualified String Value target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified String Length target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified constrained String Length target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained String subtype First target should be retained");
      Assert (V7_Id /= Editor.Ada_Language_Model.No_Symbol,
              "offset constrained String subtype First target should be retained");
      Assert (V8_Id /= Editor.Ada_Language_Model.No_Symbol,
              "offset constrained String subtype Last target should be retained");
      Assert (V9_Id /= Editor.Ada_Language_Model.No_Symbol,
              "offset constrained String subtype Length target should be retained");
      Assert (V10_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subtype-indication constrained String bound target should be retained");
      Assert (V11_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained String alias bound target should be retained");
      Assert (V12_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced qualified String Value target should be retained");
      Assert (V13_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced qualified constrained String bound target should be retained");
      Assert (V14_Id /= Editor.Ada_Language_Model.No_Symbol,
              "tab-separated qualified String Value target should be retained");
      Assert (V15_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String subtype bound-attribute constraint target should be retained");
      Assert (V16_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String subtype range-attribute constraint target should be retained");
      Assert (V17_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String subtype dimensioned bound-attribute constraint target should be retained");
      Assert (V18_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String object dimensioned bound-attribute constraint target should be retained");
      Assert (V19_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String subtype dimensioned range-attribute constraint target should be retained");
      Assert (V20_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String object dimensioned range-attribute constraint target should be retained");
      Assert (V21_Id /= Editor.Ada_Language_Model.No_Symbol,
              "unconstrained String constant range-attribute constraint target should be retained");
      Assert (V22_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline qualified String range-attribute constraint target should be retained");
      Assert (V23_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline constrained qualified String range-attribute constraint target should be retained");
      Assert (V24_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct qualified String bound-attribute constraint target should be retained");
      Assert (V25_Id /= Editor.Ada_Language_Model.No_Symbol,
              "dimensioned direct qualified String bound-attribute constraint target should be retained");
      Assert (V26_Id /= Editor.Ada_Language_Model.No_Symbol,
              "unconstrained String constant bound-attribute constraint target should be retained");
      Assert (V27_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Standard.String constrained subtype bound target should be retained");
      Assert (V28_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subtype-indication copied String range target should be retained");
      Assert (V29_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline quoted range-word String range target should be retained");
      Assert (V30_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct quoted range-word String bound target should be retained");
      Assert (V31_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline quoted dots String range target should be retained");
      Assert (V32_Id /= Editor.Ada_Language_Model.No_Symbol,
              "static-expression dimensioned String range target should be retained");
      Assert (V33_Id /= Editor.Ada_Language_Model.No_Symbol,
              "character-literal dimensioned String range target should be retained");
      Assert (V34_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline character-literal dimensioned String range target should be retained");
      Assert (V35_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline String range/dots literal range target should be retained");
      Assert (Bad_Q_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad qualified constrained String constant target should be retained");
      Assert (Bad_Direct_Q_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad direct constrained String qualification target should be retained");
      Assert (Bad_Alias_Q_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad alias constrained String qualification target should be retained");

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
      V14_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V14_Id, 1);
      V15_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V15_Id, 1);
      V16_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V16_Id, 1);
      V17_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V17_Id, 1);
      V18_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V18_Id, 1);
      V19_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V19_Id, 1);
      V20_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V20_Id, 1);
      V21_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V21_Id, 1);
      V22_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V22_Id, 1);
      V23_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V23_Id, 1);
      V24_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V24_Id, 1);
      V25_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V25_Id, 1);
      V26_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V26_Id, 1);
      V27_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V27_Id, 1);
      V28_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V28_Id, 1);
      V29_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V29_Id, 1);
      V30_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V30_Id, 1);
      V31_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V31_Id, 1);
      V32_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V32_Id, 1);
      V33_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V33_Id, 1);
      V34_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V34_Id, 1);
      V35_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V35_Id, 1);
      Bad_Q_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Q_Id, 1);
      Bad_Direct_Q_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Direct_Q_Id, 1);
      Bad_Alias_Q_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Alias_Q_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Q"
            then
               Seen_Bad_Q_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Direct_Q"
            then
               Seen_Bad_Direct_Q_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Alias_Q"
            then
               Seen_Bad_Alias_Q_Error := True;
            end if;
         end;
      end loop;

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 8,
              "qualified String constants should feed scalar Value constants");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "qualified constrained String constants should feed scalar Value constants");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 8,
              "direct qualified String expressions should feed scalar Value constants");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = 40,
              "qualified String image should retain Length");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 40,
              "qualified constrained String image should retain Length");
      Assert (V6_Size.Has_Static_Value and then V6_Size.Static_Value = 8,
              "constrained String subtype First should be static");
      Assert (V7_Size.Has_Static_Value and then V7_Size.Static_Value = 16,
              "offset constrained String subtype First should be static");
      Assert (V8_Size.Has_Static_Value and then V8_Size.Static_Value = 48,
              "offset constrained String subtype Last should be static");
      Assert (V9_Size.Has_Static_Value and then V9_Size.Static_Value = 40,
              "offset constrained String subtype Length should be static");
      Assert (V10_Size.Has_Static_Value and then V10_Size.Static_Value = 48,
              "subtype-indication constrained String Last should be static");
      Assert (V11_Size.Has_Static_Value and then V11_Size.Static_Value = 80,
              "constrained String aliases should preserve First and Length");
      Assert (V12_Size.Has_Static_Value and then V12_Size.Static_Value = 8,
              "spaced qualified String expressions should feed scalar Value constants");
      Assert (V13_Size.Has_Static_Value and then V13_Size.Static_Value = 48,
              "spaced qualified constrained String expressions should preserve Last");
      Assert (V14_Size.Has_Static_Value and then V14_Size.Static_Value = 8,
              "tab-separated qualified String expressions should feed scalar Value constants");
      Assert (V15_Size.Has_Static_Value and then V15_Size.Static_Value = 80,
              "String subtype bound attributes should define later constrained String bounds");
      Assert (V16_Size.Has_Static_Value and then V16_Size.Static_Value = 80,
              "String subtype range attributes should define later constrained String bounds");
      Assert (V17_Size.Has_Static_Value and then V17_Size.Static_Value = 80,
              "dimensioned String subtype bound attributes should define later constrained String bounds");
      Assert (V18_Size.Has_Static_Value and then V18_Size.Static_Value = 80,
              "dimensioned String object bound attributes should define later constrained String bounds");
      Assert (V19_Size.Has_Static_Value and then V19_Size.Static_Value = 80,
              "dimensioned String subtype range attributes should define later constrained String bounds");
      Assert (V20_Size.Has_Static_Value and then V20_Size.Static_Value = 80,
              "dimensioned String object range attributes should define later constrained String bounds");
      Assert (V21_Size.Has_Static_Value and then V21_Size.Static_Value = 40,
              "unconstrained String constant range attributes should define later constrained String bounds");
      Assert (V22_Size.Has_Static_Value and then V22_Size.Static_Value = 40,
              "inline qualified String range attributes should define later constrained String bounds");
      Assert (V23_Size.Has_Static_Value and then V23_Size.Static_Value = 80,
              "inline constrained qualified String range attributes should preserve copied bounds");
      Assert (V24_Size.Has_Static_Value and then V24_Size.Static_Value = 40,
              "direct qualified String bound attributes should define later constrained String bounds");
      Assert (V25_Size.Has_Static_Value and then V25_Size.Static_Value = 40,
              "dimensioned direct qualified String bound attributes should define later constrained String bounds");
      Assert (V26_Size.Has_Static_Value and then V26_Size.Static_Value = 40,
              "unconstrained String constant bound attributes should define later constrained String bounds");
      Assert (V27_Size.Has_Static_Value and then V27_Size.Static_Value = 80,
              "Standard.String constrained subtypes should retain First and Length");
      Assert (V28_Size.Has_Static_Value and then V28_Size.Static_Value = 80,
              "subtype-indication copied String ranges should retain First and Length");
      Assert (V29_Size.Has_Static_Value and then V29_Size.Static_Value = 40,
              "inline String range copies should ignore range inside string literals");
      Assert (V30_Size.Has_Static_Value and then V30_Size.Static_Value = 40,
              "direct String bound constraints should ignore range inside string literals");
      Assert (V31_Size.Has_Static_Value and then V31_Size.Static_Value = 16,
              "inline String range copies should ignore dots inside string literals");
      Assert (V32_Size.Has_Static_Value and then V32_Size.Static_Value = 80,
              "dimensioned String range copies should accept static dimension expressions");
      Assert (V33_Size.Has_Static_Value and then V33_Size.Static_Value = 80,
              "dimensioned String range copies should skip character literals while matching parentheses");
      Assert (V34_Size.Has_Static_Value and then V34_Size.Static_Value = 40,
              "inline dimensioned String range copies should select the real Source_Span attribute");
      Assert (V35_Size.Has_Static_Value and then V35_Size.Static_Value = 64,
              "String copied ranges should not enter scalar range registration when literals contain range and dots");
      Assert (not Bad_Q_Size.Has_Static_Value,
              "length-mismatched constrained String constants should stay nonstatic");
      Assert (Seen_Bad_Q_Error,
              "length-mismatched constrained String constants should produce a diagnostic");
      Assert (not Bad_Direct_Q_Size.Has_Static_Value,
              "length-mismatched direct String qualification should stay nonstatic");
      Assert (Seen_Bad_Direct_Q_Error,
              "length-mismatched direct String qualification should produce a diagnostic");
      Assert (not Bad_Alias_Q_Size.Has_Static_Value,
              "length-mismatched alias String qualification should stay nonstatic");
      Assert (Seen_Bad_Alias_Q_Error,
              "length-mismatched alias String qualification should produce a diagnostic");
   end Test_Language_Model_Representation_Static_String_Qualification_Pass;





   procedure Test_Language_Model_Representation_Static_String_Index_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   Green_Name : constant String := ""Green"";" & ASCII.LF &
        "   From_Index : constant Color := Color'Value (Green_Name (1) & ""reen"");" & ASCII.LF &
        "   First_Letter : constant Character := Green_Name (1);" & ASCII.LF &
        "   Literal_First : constant Character := ""Green"" (1);" & ASCII.LF &
        "   Qualified_First : constant Character := String'(""Green"") (1);" & ASCII.LF &
        "   Tabbed_Qualified_First : constant Character := String'(""Green"")" & ASCII.HT &
        "     (1);" & ASCII.LF &
        "   Bad_Letter : constant Character := Green_Name (99);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Index) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Character'Pos (First_Letter);" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Character'Pos (Literal_First);" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Character'Pos (Qualified_First);" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Character'Pos (Tabbed_Qualified_First);" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Character'Pos (Bad_Letter);" & ASCII.LF &
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
              "indexed string Value target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "indexed string Character target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "literal indexed string Character target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified indexed string Character target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "tab-separated qualified indexed string Character target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad indexed string target should be retained");

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
              "indexed string characters should feed concatenated Value expressions");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = Character'Pos ('G'),
              "indexed string characters should feed Character constants");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = Character'Pos ('G'),
              "direct string literals should be valid static indexed prefixes");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = Character'Pos ('G'),
              "qualified strings should be valid static indexed prefixes");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = Character'Pos ('G'),
              "tab-separated qualified strings should be valid static indexed prefixes");
      Assert (not Bad_Size.Has_Static_Value,
              "out-of-range string indexing should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range string indexing should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_String_Index_Pass;





   procedure Test_Language_Model_Representation_Static_Named_Character_String_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Letter : constant Character := 'G';" & ASCII.LF &
        "   Alias_Letter : constant Character := Character'Val (Character'Pos (Letter));" & ASCII.LF &
        "   Name : constant String := Letter & ""reen"";" & ASCII.LF &
        "   Alias_Name : constant String := Alias_Letter & ""reen"";" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   From_Name : constant Color := Color'Value (Name);" & ASCII.LF &
        "   From_Alias_Name : constant Color := Color'Value (Alias_Name);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Name) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (From_Alias_Name) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Name'Length * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      V1_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V1");
      V2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V2");
      V3_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V3");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named Character concat Value target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived named Character concat Value target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named Character concat length target should be retained");

      V1_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V1_Id, 1);
      V2_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V2_Id, 1);
      V3_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V3_Id, 1);

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 8,
              "named Character constants should concatenate into static strings");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "attribute-initialized Character constants should concatenate into static strings");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 40,
              "named Character concatenation should retain the resulting string length");
   end Test_Language_Model_Representation_Static_Named_Character_String_Pass;





   procedure Test_Language_Model_Representation_Static_Character_Expression_String_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Direct_Name : constant String := Character'Val (71) & ""reen"";" & ASCII.LF &
        "   Succ_Name : constant String := Character'Succ ('F') & ""reen"";" & ASCII.LF &
        "   Qualified_Name : constant String := Character'(Character'Val (71)) & ""reen"";" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   From_Direct : constant Color := Color'Value (Direct_Name);" & ASCII.LF &
        "   From_Succ : constant Color := Color'Value (Succ_Name);" & ASCII.LF &
        "   From_Qualified : constant Color := Color'Value (Qualified_Name);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Direct) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (From_Succ) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Qualified_Name'Length * 8;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      V1_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V1");
      V2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V2");
      V3_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V3");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct Character'Val concat target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct Character'Succ concat target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified Character expression concat target should be retained");

      V1_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V1_Id, 1);
      V2_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V2_Id, 1);
      V3_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V3_Id, 1);

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 8,
              "Character'Val should concatenate into static strings");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "Character'Succ should concatenate into static strings");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 40,
              "qualified Character expression concatenation should retain string length");
   end Test_Language_Model_Representation_Static_Character_Expression_String_Pass;





   procedure Test_Language_Model_Representation_Static_Character_Apostrophe_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Apostrophe : constant Character := '''';" & ASCII.LF &
        "   From_Value : constant Character := Character'Value (""''''"");" & ASCII.LF &
        "   From_Image : constant String := Character'Image (Apostrophe);" & ASCII.LF &
        "   From_Roundtrip : constant Character := Character'Value (From_Image);" & ASCII.LF &
        "   From_Concat : constant String := """" & '''';" & ASCII.LF &
        "   From_Index : constant Character := From_Concat (1);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Character'Pos (Apostrophe);" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Character'Pos (From_Value);" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use From_Concat'Length * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Character'Pos (From_Index);" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use From_Image'Length * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use Character'Pos (From_Roundtrip);" & ASCII.LF &
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
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V4_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V5_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V6_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "apostrophe literal target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "apostrophe Value target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "apostrophe concat string target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "apostrophe indexed string target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "apostrophe image string target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "apostrophe image roundtrip target should be retained");

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

      Assert (V1_Size.Has_Static_Value
              and then V1_Size.Static_Value = Character'Pos (Character'Val (39)),
              "apostrophe character literal should feed Character'Pos");
      Assert (V2_Size.Has_Static_Value
              and then V2_Size.Static_Value = Character'Pos (Character'Val (39)),
              "Character'Value of apostrophe image should feed Character'Pos");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 8,
              "apostrophe character literal should concatenate as one static character");
      Assert (V4_Size.Has_Static_Value
              and then V4_Size.Static_Value = Character'Pos (Character'Val (39)),
              "apostrophe character from static string indexing should feed Character'Pos");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 32,
              "apostrophe Character'Image should retain the canonical four-apostrophe image");
      Assert (V6_Size.Has_Static_Value
              and then V6_Size.Static_Value = Character'Pos (Character'Val (39)),
              "Character'Value should round-trip Character'Image for apostrophe");
   end Test_Language_Model_Representation_Static_Character_Apostrophe_Pass;





   procedure Test_Language_Model_Representation_Static_String_Slice_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Offset_Name is String (2 .. 6);" & ASCII.LF &
        "   Green_Name : constant String := ""Green"";" & ASCII.LF &
        "   Prefix : constant String := Green_Name (1 .. 3);" & ASCII.LF &
        "   Empty : constant String := Green_Name (3 .. 2);" & ASCII.LF &
        "   From_Slice : constant Color := Color'Value (Prefix & ""en"");" & ASCII.LF &
        "   Direct_Slice : constant Color := Color'Value (Green_Name (1 .. 2) & ""een"");" & ASCII.LF &
        "   Literal_Slice : constant Color := Color'Value (""Green"" (1 .. 2) & ""een"");" & ASCII.LF &
        "   Qualified_Slice : constant Color := Color'Value (String'(""Green"") (1 .. 2) & ""een"");" & ASCII.LF &
        "   Offset_Qualified_Slice : constant Color := Color'Value (Offset_Name'(""Green"") (2 .. 3) & ""een"");" & ASCII.LF &
        "   Offset_Indexed : constant Character := Offset_Name'(""Green"") (2);" & ASCII.LF &
        "   Bad_Name : constant String := Green_Name (2 .. 99);" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Color'Pos (From_Slice) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Color'Pos (Direct_Slice) * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Prefix'Length * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Empty'Length + 1;" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Color'Pos (Literal_Slice) * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use Color'Pos (Qualified_Slice) * 8;" & ASCII.LF &
        "   type V7 is range 0 .. 255;" & ASCII.LF &
        "   for V7'Size use Color'Pos (Offset_Qualified_Slice) * 8;" & ASCII.LF &
        "   type V8 is range 0 .. 255;" & ASCII.LF &
        "   for V8'Size use Character'Pos (Offset_Indexed) - Character'Pos ('A');" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Bad_Name'Length;" & ASCII.LF &
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
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
      V1_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V2_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V3_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V4_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V5_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V6_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V7_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V8_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "slice-fed Value target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct slice-fed Value target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "slice-derived string target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "null-slice-derived string target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "literal slice-fed Value target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified slice-fed Value target should be retained");
      Assert (V7_Id /= Editor.Ada_Language_Model.No_Symbol,
              "offset-qualified slice-fed Value target should be retained");
      Assert (V8_Id /= Editor.Ada_Language_Model.No_Symbol,
              "offset-qualified indexed Character target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad slice target should be retained");

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
              "named string slices should feed scalar Value expressions");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 8,
              "direct string slices should feed scalar Value expressions");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 24,
              "slice-derived string constants should expose static Length");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = 1,
              "null string slices should remain static and expose zero Length");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 8,
              "direct string literals should be valid static slice prefixes");
      Assert (V6_Size.Has_Static_Value and then V6_Size.Static_Value = 8,
              "qualified strings should be valid static slice prefixes");
      Assert (V7_Size.Has_Static_Value and then V7_Size.Static_Value = 8,
              "offset-qualified strings should slice using retained lower bounds");
      Assert (V8_Size.Has_Static_Value and then V8_Size.Static_Value = 6,
              "offset-qualified strings should index using retained lower bounds");
      Assert (not Bad_Size.Has_Static_Value,
              "out-of-range string slices should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range string slices should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_String_Slice_Pass;





   procedure Test_Language_Model_Representation_Static_String_Length_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   subtype Text is String;" & ASCII.LF &
        "   subtype Offset_Name is String (2 .. 6);" & ASCII.LF &
        "   Offset_Object : constant Offset_Name := Offset_Name'(""Green"");" & ASCII.LF &
        "   subtype Object_Derived_Name is String (Offset_Object'First .. Offset_Object'Last);" & ASCII.LF &
        "   subtype Object_Range_Name is String (Offset_Object'Range);" & ASCII.LF &
        "   Green_Name : constant String := ""Gr"" & ""een"";" & ASCII.LF &
        "   Blue_Image : constant String := Color'Image (Blue);" & ASCII.LF &
        "   Alias_Name : constant Text := ""Red"";" & ASCII.LF &
        "   Integer_Image : constant String := Integer'Image (-12);" & ASCII.LF &
        "   Natural_Image : constant String := Natural'Image (Green_Name'Length);" & ASCII.LF &
        "   Low : constant := -Green_Name'Length;" & ASCII.LF &
        "   High : constant := Blue_Image'Last (1);" & ASCII.LF &
        "   type Offset is range Low .. Blue_Image'Length;" & ASCII.LF &
        "   type Indexed is range 1 .. High;" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Green_Name'Length * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Blue_Image'Length * 4;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use Offset'Last * 8;" & ASCII.LF &
        "   type V4 is range 0 .. 255;" & ASCII.LF &
        "   for V4'Size use Alias_Name'Length * 8;" & ASCII.LF &
        "   type V5 is range 0 .. 255;" & ASCII.LF &
        "   for V5'Size use Green_Name'First * 8;" & ASCII.LF &
        "   type V6 is range 0 .. 255;" & ASCII.LF &
        "   for V6'Size use (Blue_Image'Last + Alias_Name'First) * 4;" & ASCII.LF &
        "   type V7 is range 0 .. 255;" & ASCII.LF &
        "   for V7'Size use Green_Name'Length (1) * 8;" & ASCII.LF &
        "   type V8 is range 0 .. 255;" & ASCII.LF &
        "   for V8'Size use Indexed'Last * 4;" & ASCII.LF &
        "   type V9 is range 0 .. 255;" & ASCII.LF &
        "   for V9'Size use Integer_Image'Length * 8;" & ASCII.LF &
        "   type V10 is range 0 .. 255;" & ASCII.LF &
        "   for V10'Size use Natural_Image'Length * 8;" & ASCII.LF &
        "   type V11 is range 0 .. 255;" & ASCII.LF &
        "   for V11'Size use String' (""Gr"" & ""een"")'Length * 8;" & ASCII.LF &
        "   type V12 is range 0 .. 255;" & ASCII.LF &
        "   for V12'Size use (""Green"" (2 .. 4))'Last * 8;" & ASCII.LF &
        "   type V13 is range 0 .. 255;" & ASCII.LF &
        "   for V13'Size use Offset_Name'(""Green"")'First * 8;" & ASCII.LF &
        "   type V14 is range 0 .. 255;" & ASCII.LF &
        "   for V14'Size use Offset_Name'(""Green"")'Last * 8;" & ASCII.LF &
        "   type V15 is range 0 .. 255;" & ASCII.LF &
        "   for V15'Size use Offset_Name'(""Green"")'Length * 8;" & ASCII.LF &
        "   type V16 is range 0 .. 255;" & ASCII.LF &
        "   for V16'Size use Offset_Object'First * Offset_Object'Length * 8;" & ASCII.LF &
        "   type V17 is range 0 .. 255;" & ASCII.LF &
        "   for V17'Size use Object_Derived_Name'First * Object_Derived_Name'Length * 8;" & ASCII.LF &
        "   type V18 is range 0 .. 255;" & ASCII.LF &
        "   for V18'Size use Object_Range_Name'First * Object_Range_Name'Length * 8;" & ASCII.LF &
        "   type V19 is range 0 .. 255;" & ASCII.LF &
        "   for V19'Size use String' (""Gr"" & ""een"")' Length * 8;" & ASCII.LF &
        "   type V20 is range 0 .. 255;" & ASCII.LF &
        "   for V20'Size use Standard.String'(""Green"")'Length * 8;" & ASCII.LF &
        "   Bad_Positive_Image : constant String := Positive'Image (0);" & ASCII.LF &
        "   type Bad_Integer_Image is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Integer_Image'Size use Bad_Positive_Image'Length * 8;" & ASCII.LF &
        "   type Bad_Dim is range 0 .. 255;" & ASCII.LF &
        "   for Bad_Dim'Size use Green_Name'Length (2) * 8;" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Missing_Name'Length * 8;" & ASCII.LF &
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
      V14_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V14");
      V15_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V15");
      V16_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V16");
      V17_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V17");
      V18_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V18");
      V19_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V19");
      V20_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V20");
      Bad_Integer_Image_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Integer_Image");
      Bad_Dim_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Dim");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
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
      V14_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V15_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V16_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V17_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V18_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V19_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      V20_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Integer_Image_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Dim_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Integer_Image_Error : Boolean := False;
      Seen_Bad_Dim_Error : Boolean := False;
      Seen_Bad_Error : Boolean := False;
   begin
      Assert (V1_Id /= Editor.Ada_Language_Model.No_Symbol,
              "string Length target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Image string Length target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "signed range Length target should be retained");
      Assert (V4_Id /= Editor.Ada_Language_Model.No_Symbol,
              "string subtype Length target should be retained");
      Assert (V5_Id /= Editor.Ada_Language_Model.No_Symbol,
              "string First target should be retained");
      Assert (V6_Id /= Editor.Ada_Language_Model.No_Symbol,
              "string Last target should be retained");
      Assert (V7_Id /= Editor.Ada_Language_Model.No_Symbol,
              "dimensioned string Length target should be retained");
      Assert (V8_Id /= Editor.Ada_Language_Model.No_Symbol,
              "dimensioned string bound range target should be retained");
      Assert (V9_Id /= Editor.Ada_Language_Model.No_Symbol,
              "integer Image string Length target should be retained");
      Assert (V10_Id /= Editor.Ada_Language_Model.No_Symbol,
              "natural Image string Length target should be retained");
      Assert (V11_Id /= Editor.Ada_Language_Model.No_Symbol,
              "spaced direct qualified string Length target should be retained");
      Assert (V12_Id /= Editor.Ada_Language_Model.No_Symbol,
              "direct sliced string Last target should be retained");
      Assert (V13_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified constrained string First target should be retained");
      Assert (V14_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified constrained string Last target should be retained");
      Assert (V15_Id /= Editor.Ada_Language_Model.No_Symbol,
              "qualified constrained string Length target should be retained");
      Assert (V16_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constrained string object bounds target should be retained");
      Assert (V17_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String subtype bound from object attributes target should be retained");
      Assert (V18_Id /= Editor.Ada_Language_Model.No_Symbol,
              "String subtype range from object attribute target should be retained");
      Assert (V19_Id /= Editor.Ada_Language_Model.No_Symbol,
              "separator-spaced String bound attribute target should be retained");
      Assert (V20_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Standard.String qualified bound target should be retained");
      Assert (Bad_Integer_Image_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad integer Image target should be retained");
      Assert (Bad_Dim_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad string dimension target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "unknown Length target should be retained");

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
      V14_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V14_Id, 1);
      V15_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V15_Id, 1);
      V16_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V16_Id, 1);
      V17_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V17_Id, 1);
      V18_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V18_Id, 1);
      V19_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V19_Id, 1);
      V20_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, V20_Id, 1);
      Bad_Integer_Image_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Integer_Image_Id, 1);
      Bad_Dim_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Dim_Id, 1);
      Bad_Size := Editor.Ada_Language_Model.Representation_Clause_At
        (Analysis, Bad_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Integer_Image"
            then
               Seen_Bad_Integer_Image_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad_Dim"
            then
               Seen_Bad_Dim_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then To_String (Info.Target_Name) = "Bad"
            then
               Seen_Bad_Error := True;
            end if;
         end;
      end loop;

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 40,
              "named static string Length should feed Size arithmetic");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 16,
              "Image-fed static string Length should feed Size arithmetic");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 32,
              "String'Length should feed signed range metadata");
      Assert (V4_Size.Has_Static_Value and then V4_Size.Static_Value = 24,
              "string subtype constants should retain static Length");
      Assert (V5_Size.Has_Static_Value and then V5_Size.Static_Value = 8,
              "static string First should feed Size arithmetic");
      Assert (V6_Size.Has_Static_Value and then V6_Size.Static_Value = 20,
              "static string Last should feed Size arithmetic");
      Assert (V7_Size.Has_Static_Value and then V7_Size.Static_Value = 40,
              "dimensioned static string Length should feed Size arithmetic");
      Assert (V8_Size.Has_Static_Value and then V8_Size.Static_Value = 16,
              "dimensioned static string Last should feed signed range metadata");
      Assert (V9_Size.Has_Static_Value and then V9_Size.Static_Value = 24,
              "integer Image static string Length should feed Size arithmetic");
      Assert (V10_Size.Has_Static_Value and then V10_Size.Static_Value = 16,
              "natural Image static string Length should include the Image leading blank");
      Assert (V11_Size.Has_Static_Value and then V11_Size.Static_Value = 40,
              "direct qualified static string Length should feed Size arithmetic");
      Assert (V12_Size.Has_Static_Value and then V12_Size.Static_Value = 24,
              "direct sliced static string Last should feed Size arithmetic");
      Assert (V13_Size.Has_Static_Value and then V13_Size.Static_Value = 16,
              "qualified constrained static string First should preserve subtype lower bound");
      Assert (V14_Size.Has_Static_Value and then V14_Size.Static_Value = 48,
              "qualified constrained static string Last should preserve subtype upper bound");
      Assert (V15_Size.Has_Static_Value and then V15_Size.Static_Value = 40,
              "qualified constrained static string Length should preserve component count");
      Assert (V16_Size.Has_Static_Value and then V16_Size.Static_Value = 80,
              "constrained String constants should preserve declared lower bound");
      Assert (V17_Size.Has_Static_Value and then V17_Size.Static_Value = 80,
              "constrained String object bound attributes should define later constrained String bounds");
      Assert (V18_Size.Has_Static_Value and then V18_Size.Static_Value = 80,
              "constrained String object range attributes should define later constrained String bounds");
      Assert (V19_Size.Has_Static_Value and then V19_Size.Static_Value = 40,
              "separator-spaced static String bound attributes should feed Size arithmetic");
      Assert (V20_Size.Has_Static_Value and then V20_Size.Static_Value = 40,
              "Standard.String qualified static bound attributes should feed Size arithmetic");
      Assert (not Bad_Integer_Image_Size.Has_Static_Value,
              "out-of-range integer Image arguments should stay nonstatic");
      Assert (Seen_Bad_Integer_Image_Error,
              "out-of-range integer Image arguments should produce a diagnostic");
      Assert (not Bad_Dim_Size.Has_Static_Value,
              "non-1 string attribute dimensions should stay nonstatic");
      Assert (Seen_Bad_Dim_Error,
              "non-1 string attribute dimensions should produce a static-value diagnostic");
      Assert (not Bad_Size.Has_Static_Value,
              "unknown string Length source should stay nonstatic");
      Assert (Seen_Bad_Error,
              "unknown string Length source should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_String_Length_Pass;


   overriding function Name (T : Representation_Static_String_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Representation.Static_String");
   end Name;

   overriding procedure Register_Tests (T : in out Representation_Static_String_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Representation_Static_Character_Alias_Literal_Pass'Access, Name => "language model preserves Character literal metadata through aliases and scalar derivations");
      Add_Test (Routine => Test_Language_Model_Representation_Static_String_Concat_Value_Pass'Access, Name => "language model evaluates static string concatenation feeding scalar Value attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_String_Qualification_Pass'Access, Name => "language model evaluates qualified static string expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_String_Index_Pass'Access, Name => "language model evaluates static string indexing in Value and Character expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Named_Character_String_Pass'Access, Name => "language model evaluates named Character constants in static string concatenation");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Character_Expression_String_Pass'Access, Name => "language model evaluates Character-valued static expressions in string concatenation");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Character_Apostrophe_Pass'Access, Name => "language model evaluates apostrophe character literals in static representation expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_String_Slice_Pass'Access, Name => "language model evaluates static string slicing in Value expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_String_Length_Pass'Access, Name => "language model evaluates static String Length attributes in representation expressions");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Static_String_Tests;
