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

package body Editor.Syntax_Semantics.Representation_Static_Tests is





   procedure Test_Ada_Representation_Legality_Static_Freezing
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Representation_Value_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Layouts is" & ASCII.LF &
        "   type Small is range 0 .. 10;" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Field : Small;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Small'Size use 8;" & ASCII.LF &
        "   X : Small;" & ASCII.LF &
        "   for Small'Alignment use 4;" & ASCII.LF &
        "   for Small'Component_Size use 8;" & ASCII.LF &
        "   for Rec use record" & ASCII.LF &
        "      Field at 0 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Layouts;";
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
      Seen_Static_Ok : Boolean := False;
      Seen_After_Freeze : Boolean := False;
      Seen_Kind_Mismatch : Boolean := False;
   begin
      Assert (Editor.Ada_Representation_Legality.Check_Count (Legality) >= 4,
              "representation legality must stage representation clauses from the syntax tree");

      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Value_Status = Editor.Ada_Representation_Legality.Representation_Value_Static_Integer
              and then Info.Static_Integer = 8
            then
               Seen_Static_Ok := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_After_Freezing then
               Seen_After_Freeze := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Target_Kind_Mismatch then
               Seen_Kind_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Seen_Static_Ok,
              "representation legality must accept static integer representation values before freezing");
      Assert (Seen_After_Freeze,
              "representation legality must reject clauses placed after the target freeze point");
      Assert (Seen_Kind_Mismatch,
              "representation legality must reject representation items whose target kind is incompatible");
      Assert (Editor.Ada_Representation_Legality.Static_Error_Count (Legality) = 0,
              "representation legality must not report static errors for literal static values");
      Assert (Editor.Ada_Representation_Legality.Target_Kind_Mismatch_Count (Legality) >= 1,
              "representation legality must count target-kind mismatches deterministically");
      Assert (Editor.Ada_Representation_Legality.After_Freezing_Count (Legality) >= 1,
              "representation legality must count freezing-order errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "representation legality must retain deterministic fingerprints");
   end Test_Ada_Representation_Legality_Static_Freezing;




   procedure Test_Language_Model_Record_Representation_Static_Literals_Are_Parsed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      Flag at 16#10# range 2#0001# .. 2#1_111#;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Packed_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Packed");
      Component : Editor.Ada_Language_Model.Representation_Component_Info;
   begin
      Assert (Packed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be retained for based-literal representation metadata");
      Assert (Editor.Ada_Language_Model.Representation_Component_Count
                (Analysis, Packed_Id) = 1,
              "based-literal component clause should still be interpreted");

      Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 1);
      Assert (Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 16,
              "based storage-unit literals should be parsed as static values");
      Assert (Component.Has_Static_First_Bit
              and then Component.Static_First_Bit = 1,
              "based first-bit literals should be parsed as static values");
      Assert (Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 15,
              "based literals with underscores should be parsed as static values");
   end Test_Language_Model_Record_Representation_Static_Literals_Are_Parsed;




   procedure Test_Language_Model_Representation_Static_Expressions_Are_Evaluated
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1 + 2 * 3, Green => (16#10# + 2) / 2, Blue => 2 ** 4);" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index'Size use 8 * (2 + 2);" & ASCII.LF &
        "   for Index'Alignment use 2 ** 2;" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      Flag at 1 + 1 range 2 * 2 .. 2#1_000# + 1;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Colour_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Colour");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Packed_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Packed");
      Red_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Green_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Blue_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Align_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Component : Editor.Ada_Language_Model.Representation_Component_Info;
   begin
      Assert (Colour_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for static-expression representation metadata");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "scalar type should be retained for static-expression attribute metadata");
      Assert (Packed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be retained for static-expression component metadata");

      Red_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 1);
      Green_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 2);
      Blue_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 3);
      Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 1);
      Align_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 2);
      Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 1);

      Assert (Red_Literal.Has_Static_Value
              and then Red_Literal.Static_Value = 7,
              "enum representation expressions should observe arithmetic precedence");
      Assert (Green_Literal.Has_Static_Value
              and then Green_Literal.Static_Value = 9,
              "enum representation expressions should support parentheses and division");
      Assert (Blue_Literal.Has_Static_Value
              and then Blue_Literal.Static_Value = 16,
              "enum representation expressions should support exponentiation");
      Assert (Size_Clause.Has_Static_Value
              and then Size_Clause.Static_Value = 32,
              "attribute representation expressions should be evaluated when statically numeric");
      Assert (Align_Clause.Has_Static_Value
              and then Align_Clause.Static_Value = 4,
              "attribute representation exponentiation should be evaluated");
      Assert (Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 2,
              "record representation component storage expressions should be evaluated");
      Assert (Component.Has_Static_First_Bit
              and then Component.Static_First_Bit = 4,
              "record representation first-bit expressions should be evaluated");
      Assert (Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 9,
              "record representation last-bit expressions should be evaluated");
   end Test_Language_Model_Representation_Static_Expressions_Are_Evaluated;




   procedure Test_Language_Model_Representation_Named_Static_Numbers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Word_Bits : constant := 8 * 4;" & ASCII.LF &
        "   Byte_Two  : constant := 2;" & ASCII.LF &
        "   type Colour is (Red, Green);" & ASCII.LF &
        "   for Colour use (Red => Byte_Two, Green => Word_Bits + Byte_Two);" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index'Size use Word_Bits;" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      Flag at Byte_Two range 0 .. Word_Bits - 1;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Colour_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Colour");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Packed_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Packed");
      Red_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Green_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Component : Editor.Ada_Language_Model.Representation_Component_Info;
   begin
      Assert (Colour_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for named-number representation metadata");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "scalar type should be retained for named-number attribute metadata");
      Assert (Packed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be retained for named-number component metadata");

      Red_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 1);
      Green_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 2);
      Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 1);
      Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 1);

      Assert (Red_Literal.Has_Static_Value
              and then Red_Literal.Static_Value = 2,
              "enum representation values should resolve prior named-number constants");
      Assert (Green_Literal.Has_Static_Value
              and then Green_Literal.Static_Value = 34,
              "enum representation expressions should combine named numbers with arithmetic");
      Assert (Size_Clause.Has_Static_Value
              and then Size_Clause.Static_Value = 32,
              "attribute representation values should resolve prior named-number constants");
      Assert (Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 2,
              "record component storage-unit values should resolve prior named-number constants");
      Assert (Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 31,
              "record component bit-range expressions should resolve prior named-number constants");
   end Test_Language_Model_Representation_Named_Static_Numbers;




   procedure Test_Language_Model_Representation_Precise_Static_Evaluation_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Byte_Index is range 0 .. 63;" & ASCII.LF &
        "   type Nibble is mod 16;" & ASCII.LF &
        "   Word_Bits : constant Natural := 8 * 4;" & ASCII.LF &
        "   Last_Bit  : constant Byte_Index := Byte_Index'(Word_Bits - 1);" & ASCII.LF &
        "   Small_Val : constant := 0.125;" & ASCII.LF &
        "   type Fixed is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Fixed'Small use Small_Val;" & ASCII.LF &
        "   type Colour is (Red, Green);" & ASCII.LF &
        "   for Colour use (Red => Nibble'(2#1111#), Green => Byte_Index'Last);" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      Flag at Natural'(2) range Byte_Index'First .. Last_Bit;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index'Size use Natural'(Word_Bits);" & ASCII.LF &
        "   type Bad is range 0 .. 1;" & ASCII.LF &
        "   for Bad'Size use Nibble'(16);" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Colour_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Colour");
      Packed_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Packed");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad");
      Red_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Green_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Component : Editor.Ada_Language_Model.Representation_Component_Info;
      Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Static_Required : Boolean := False;
      Seen_Small_Static_Error : Boolean := False;
   begin
      Assert (Colour_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for qualified static values");
      Assert (Packed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be retained for attribute static values");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "integer type should be retained for qualified size values");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad integer type should be retained for out-of-range qualified values");

      Red_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 1);
      Green_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 2);
      Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 1);
      Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 1);
      Bad_Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Id
            then
               Seen_Static_Required := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required then
               Seen_Small_Static_Error := True;
            end if;
         end;
      end loop;

      Assert (Red_Literal.Has_Static_Value
              and then Red_Literal.Static_Value = 15,
              "modular qualified static expressions should resolve and range-check");
      Assert (Green_Literal.Has_Static_Value
              and then Green_Literal.Static_Value = 63,
              "static type attributes should resolve to retained range bounds");
      Assert (Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 2,
              "qualified static component positions should resolve");
      Assert (Component.Has_Static_First_Bit
              and then Component.Static_First_Bit = 0,
              "First attributes should be accepted for nonnegative integer ranges");
      Assert (Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 31,
              "typed static constants should participate in later static expressions");
      Assert (Size_Clause.Has_Static_Value
              and then Size_Clause.Static_Value = 32,
              "qualified static constants should resolve in attribute clauses");
      Assert (not Bad_Size_Clause.Has_Static_Value,
              "out-of-range modular qualified expressions should not resolve as integer static values");
      Assert (Seen_Static_Required,
              "out-of-range qualified representation values should produce a static-value diagnostic");
      Assert (not Seen_Small_Static_Error,
              "universal-real named constants should resolve for numeric-only Small clauses");
   end Test_Language_Model_Representation_Precise_Static_Evaluation_Pass;




   procedure Test_Language_Model_Representation_Static_Real_Arithmetic_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Small_One : constant := 0.125;" & ASCII.LF &
        "   Small_Two : constant := 2.0;" & ASCII.LF &
        "   Small_Half : constant := Small_One / Small_Two;" & ASCII.LF &
        "   type Fixed_OK is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Fixed_OK'Small use Small_Half;" & ASCII.LF &
        "   type Fixed_Bad is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Fixed_Bad'Small use Runtime_Value / 2.0;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      OK_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Fixed_OK");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Fixed_Bad");
      Seen_OK_Small_Error : Boolean := False;
      Seen_Bad_Small_Error : Boolean := False;
   begin
      Assert (OK_Id /= Editor.Ada_Language_Model.No_Symbol,
              "static-real arithmetic target should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "nonstatic real arithmetic target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = OK_Id
            then
               Seen_OK_Small_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Id
            then
               Seen_Bad_Small_Error := True;
            end if;
         end;
      end loop;

      Assert (not Seen_OK_Small_Error,
              "Small should accept derived universal-real static constants over retained named numbers");
      Assert (Seen_Bad_Small_Error,
              "Small should reject arithmetic containing an unknown nonstatic name");
   end Test_Language_Model_Representation_Static_Real_Arithmetic_Pass;




   procedure Test_Language_Model_Representation_Signed_Static_Range_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Low_Bound  : constant := -16;" & ASCII.LF &
        "   High_Bound : constant := Low_Bound + 31;" & ASCII.LF &
        "   type Offset is range Low_Bound .. High_Bound;" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => Offset'(15), Green => Offset'Last, Blue => Offset'(16));" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index'Size use Offset'Last + 1;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Colour_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Colour");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Red_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Green_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Blue_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Blue_Static_Error : Boolean := False;
      Seen_Index_Static_Error : Boolean := False;
   begin
      Assert (Colour_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for signed static range coverage");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "integer type should be retained for signed static attribute coverage");

      Red_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 1);
      Green_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 2);
      Blue_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 3);
      Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Enumeration_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Colour_Id
            then
               Seen_Blue_Static_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Index_Id
            then
               Seen_Index_Static_Error := True;
            end if;
         end;
      end loop;

      Assert (Red_Literal.Has_Static_Value and then Red_Literal.Static_Value = 15,
              "signed integer range qualification should accept values inside the retained range");
      Assert (Green_Literal.Has_Static_Value and then Green_Literal.Static_Value = 15,
              "signed integer range upper attribute should feed natural representation values");
      Assert (not Blue_Literal.Has_Static_Value,
              "signed integer range qualification should reject values outside the retained range");
      Assert (Seen_Blue_Static_Error,
              "out-of-range signed qualification should produce an enum static-value diagnostic");
      Assert (Size_Clause.Has_Static_Value and then Size_Clause.Static_Value = 16,
              "signed range attributes should participate in natural static arithmetic when nonnegative");
      Assert (not Seen_Index_Static_Error,
              "nonnegative signed range attributes should not produce size static-value diagnostics");
   end Test_Language_Model_Representation_Signed_Static_Range_Pass;




   procedure Test_Language_Model_Representation_Typed_Static_Constants_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   subtype Byte is Integer range 0 .. 255;" & ASCII.LF &
        "   subtype Octet is Byte;" & ASCII.LF &
        "   type Derived_Byte is new Byte;" & ASCII.LF &
        "   OK : constant Octet := 255;" & ASCII.LF &
        "   Bad : constant Octet := 256;" & ASCII.LF &
        "   Derived_OK : constant Derived_Byte := 4;" & ASCII.LF &
        "   type T_Size is range 0 .. 1;" & ASCII.LF &
        "   for T_Size'Size use OK;" & ASCII.LF &
        "   type U_Size is range 0 .. 1;" & ASCII.LF &
        "   for U_Size'Size use Bad;" & ASCII.LF &
        "   type V_Size is range 0 .. 1;" & ASCII.LF &
        "   for V_Size'Size use Derived_OK * 2;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      T_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "T_Size");
      U_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "U_Size");
      V_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "V_Size");
      T_Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      U_Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      V_Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_T_Static_Error : Boolean := False;
      Seen_U_Static_Error : Boolean := False;
      Seen_V_Static_Error : Boolean := False;
   begin
      Assert (T_Id /= Editor.Ada_Language_Model.No_Symbol,
              "first size target should be retained");
      Assert (U_Id /= Editor.Ada_Language_Model.No_Symbol,
              "second size target should be retained");
      Assert (V_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived-size target should be retained");

      T_Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, T_Id, 1);
      U_Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, U_Id, 1);
      V_Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, V_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = T_Id
            then
               Seen_T_Static_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = U_Id
            then
               Seen_U_Static_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = V_Id
            then
               Seen_V_Static_Error := True;
            end if;
         end;
      end loop;

      Assert (T_Size_Clause.Has_Static_Value and then T_Size_Clause.Static_Value = 255,
              "typed static constants inside an aliased subtype range should feed representation expressions");
      Assert (not Seen_T_Static_Error,
              "in-range typed static constant should not produce a static-value diagnostic");
      Assert (not U_Size_Clause.Has_Static_Value,
              "out-of-range typed static constant should not be retained as a later static value");
      Assert (Seen_U_Static_Error,
              "out-of-range typed static constant should make the later representation expression nonstatic");
      Assert (V_Size_Clause.Has_Static_Value and then V_Size_Clause.Static_Value = 8,
              "derived integer types should inherit retained base ranges for typed static constants");
      Assert (not Seen_V_Static_Error,
              "derived-type compatible static constant should not produce a diagnostic");
   end Test_Language_Model_Representation_Typed_Static_Constants_Pass;




   procedure Test_Language_Model_Representation_Static_Numeric_Type_Kind_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Fixed is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   Real_One : constant := 1.0;" & ASCII.LF &
        "   Real_Two : constant := 2.0;" & ASCII.LF &
        "   Int_One : constant := 1;" & ASCII.LF &
        "   Int_Two : constant := 2;" & ASCII.LF &
        "   type Good is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good'Small use Real_One / Real_Two;" & ASCII.LF &
        "   type Bad_Mod is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Bad_Mod'Small use Real_One mod Real_Two;" & ASCII.LF &
        "   type Bad_Rem is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Bad_Rem'Small use 1.0 rem 2.0;" & ASCII.LF &
        "   type Good_Int_Mod is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Int_Mod'Small use Int_Two mod Int_One;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Good_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good");
      Bad_Mod_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Mod");
      Bad_Rem_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Rem");
      Good_Int_Mod_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Int_Mod");
      Seen_Good_Error : Boolean := False;
      Seen_Bad_Mod_Error : Boolean := False;
      Seen_Bad_Rem_Error : Boolean := False;
      Seen_Good_Int_Mod_Error : Boolean := False;
   begin
      Assert (Good_Id /= Editor.Ada_Language_Model.No_Symbol,
              "real-division Small target should be retained");
      Assert (Bad_Mod_Id /= Editor.Ada_Language_Model.No_Symbol,
              "real-mod Small target should be retained");
      Assert (Bad_Rem_Id /= Editor.Ada_Language_Model.No_Symbol,
              "real-rem Small target should be retained");
      Assert (Good_Int_Mod_Id /= Editor.Ada_Language_Model.No_Symbol,
              "integer-mod Small target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Id
            then
               Seen_Good_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Mod_Id
            then
               Seen_Bad_Mod_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Rem_Id
            then
               Seen_Bad_Rem_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Int_Mod_Id
            then
               Seen_Good_Int_Mod_Error := True;
            end if;
         end;
      end loop;

      Assert (not Seen_Good_Error,
              "Small should accept universal-real static division over retained constants");
      Assert (Seen_Bad_Mod_Error,
              "Small should reject mod with universal-real operands");
      Assert (Seen_Bad_Rem_Error,
              "Small should reject rem with universal-real operands");
      Assert (not Seen_Good_Int_Mod_Error,
              "Small should still accept integer-only mod static expressions");
   end Test_Language_Model_Representation_Static_Numeric_Type_Kind_Pass;





   procedure Test_Language_Model_Representation_Static_Attribute_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Base is range 0 .. 1;" & ASCII.LF &
        "   for Base'Size use 16;" & ASCII.LF &
        "   type Mirror is range 0 .. 1;" & ASCII.LF &
        "   for Mirror'Size use Base'Size * 2;" & ASCII.LF &
        "   type Aspect_Base is range 0 .. 1 with Size => 8;" & ASCII.LF &
        "   type Aspect_Mirror is range 0 .. 1;" & ASCII.LF &
        "   for Aspect_Mirror'Size use Aspect_Base'Size + 8;" & ASCII.LF &
        "   type Aligned is range 0 .. 1;" & ASCII.LF &
        "   for Aligned'Alignment use 4;" & ASCII.LF &
        "   type Alignment_Mirror is range 0 .. 1;" & ASCII.LF &
        "   for Alignment_Mirror'Size use Aligned'Alignment * 8;" & ASCII.LF &
        "   type Unknown_Mirror is range 0 .. 1;" & ASCII.LF &
        "   for Unknown_Mirror'Size use Missing'Size;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Mirror_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Mirror");
      Aspect_Mirror_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Aspect_Mirror");
      Alignment_Mirror_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alignment_Mirror");
      Unknown_Mirror_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Unknown_Mirror");
      Mirror_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Aspect_Mirror_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Alignment_Mirror_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Unknown_Mirror_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Unknown_Error : Boolean := False;
   begin
      Assert (Mirror_Id /= Editor.Ada_Language_Model.No_Symbol,
              "mirror target should be retained");
      Assert (Aspect_Mirror_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aspect mirror target should be retained");
      Assert (Alignment_Mirror_Id /= Editor.Ada_Language_Model.No_Symbol,
              "alignment mirror target should be retained");
      Assert (Unknown_Mirror_Id /= Editor.Ada_Language_Model.No_Symbol,
              "unknown static-attribute target should be retained");

      Mirror_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Mirror_Id, 1);
      Aspect_Mirror_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Aspect_Mirror_Id, 1);
      Alignment_Mirror_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Alignment_Mirror_Id, 1);
      Unknown_Mirror_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Unknown_Mirror_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Unknown_Mirror_Id
            then
               Seen_Unknown_Error := True;
            end if;
         end;
      end loop;

      Assert (Mirror_Size.Has_Static_Value and then Mirror_Size.Static_Value = 32,
              "retained Size clauses should feed later static attribute references");
      Assert (Aspect_Mirror_Size.Has_Static_Value
              and then Aspect_Mirror_Size.Static_Value = 16,
              "static Size aspects should feed later static attribute references");
      Assert (Alignment_Mirror_Size.Has_Static_Value
              and then Alignment_Mirror_Size.Static_Value = 32,
              "retained Alignment clauses should feed later static arithmetic");
      Assert (not Unknown_Mirror_Size.Has_Static_Value,
              "unknown attribute prefixes should not be treated as static values");
      Assert (Seen_Unknown_Error,
              "unknown static attribute references should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Attribute_Value_Pass;




   procedure Test_Language_Model_Representation_Static_Base_Attribute_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Count is range 0 .. 15;" & ASCII.LF &
        "   type Offset is range -8 .. 7;" & ASCII.LF &
        "   type From_Base_Last is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Last'Size use Count'Base'Last + 1;" & ASCII.LF &
        "   type From_Base_Qualified is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Qualified'Size use Count'Base'(8) * 2;" & ASCII.LF &
        "   type Signed_Base_Last is range 0 .. 1;" & ASCII.LF &
        "   for Signed_Base_Last'Size use Offset'Base'Last + 1;" & ASCII.LF &
        "   type Bad_Base_Qualified is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Base_Qualified'Size use Count'Base'(16);" & ASCII.LF &
        "   type Good_Small is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Count'Base'Last / 2.0;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Base_Last_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Last");
      From_Base_Qualified_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "From_Base_Qualified");
      Signed_Base_Last_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Signed_Base_Last");
      Bad_Base_Qualified_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "Bad_Base_Qualified");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      From_Base_Last_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Base_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Signed_Base_Last_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Base_Qualified_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
      Seen_Good_Small_Error : Boolean := False;
   begin
      Assert (From_Base_Last_Id /= Editor.Ada_Language_Model.No_Symbol,
              "base-last target should be retained");
      Assert (From_Base_Qualified_Id /= Editor.Ada_Language_Model.No_Symbol,
              "base-qualified target should be retained");
      Assert (Signed_Base_Last_Id /= Editor.Ada_Language_Model.No_Symbol,
              "signed base-last target should be retained");
      Assert (Bad_Base_Qualified_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad base-qualified target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "small target should be retained");

      From_Base_Last_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Last_Id, 1);
      From_Base_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Qualified_Id, 1);
      Signed_Base_Last_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Signed_Base_Last_Id, 1);
      Bad_Base_Qualified_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Base_Qualified_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Base_Qualified_Id
            then
               Seen_Bad_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Base_Last_Size.Has_Static_Value
              and then From_Base_Last_Size.Static_Value = 16,
              "T'Base'Last should be a retained static integer attribute");
      Assert (From_Base_Qualified_Size.Has_Static_Value
              and then From_Base_Qualified_Size.Static_Value = 16,
              "T'Base'(Expr) should be a retained range-checked qualified expression");
      Assert (Signed_Base_Last_Size.Has_Static_Value
              and then Signed_Base_Last_Size.Static_Value = 8,
              "signed T'Base'Last should flow into nonnegative size arithmetic");
      Assert (not Bad_Base_Qualified_Size.Has_Static_Value,
              "out-of-range T'Base'(Expr) should not become a static size value");
      Assert (Seen_Bad_Error,
              "out-of-range T'Base'(Expr) should produce a static-value diagnostic");
      Assert (not Seen_Good_Small_Error,
              "numeric-only clauses should accept T'Base'Last in static real arithmetic");
   end Test_Language_Model_Representation_Static_Base_Attribute_Pass;



   procedure Test_Language_Model_Representation_Static_Modulus_Attribute_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Byte is mod 256;" & ASCII.LF &
        "   type Count is range 0 .. 15;" & ASCII.LF &
        "   type From_Modulus is range 0 .. 1;" & ASCII.LF &
        "   for From_Modulus'Size use Byte'Modulus / 8;" & ASCII.LF &
        "   type From_Base_Modulus is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Modulus'Size use Byte'Base'Modulus / 16;" & ASCII.LF &
        "   subtype Alias_Byte is Byte;" & ASCII.LF &
        "   type From_Alias_Modulus is range 0 .. 1;" & ASCII.LF &
        "   for From_Alias_Modulus'Size use Alias_Byte'Modulus / 32;" & ASCII.LF &
        "   type Derived_Byte is new Byte;" & ASCII.LF &
        "   type From_Derived_Modulus is range 0 .. 1;" & ASCII.LF &
        "   for From_Derived_Modulus'Size use Derived_Byte'Base'Modulus / 64;" & ASCII.LF &
        "   type Bad_Integer_Modulus is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Integer_Modulus'Size use Count'Modulus;" & ASCII.LF &
        "   type Good_Small is delta 0.125 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Byte'Modulus / 2.0;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Modulus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Modulus");
      From_Base_Modulus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "From_Base_Modulus");
      From_Alias_Modulus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "From_Alias_Modulus");
      From_Derived_Modulus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "From_Derived_Modulus");
      Bad_Integer_Modulus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "Bad_Integer_Modulus");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      From_Modulus_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Base_Modulus_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Alias_Modulus_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Derived_Modulus_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Integer_Modulus_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Error : Boolean := False;
      Seen_Good_Small_Error : Boolean := False;
   begin
      Assert (From_Modulus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "modulus target should be retained");
      Assert (From_Base_Modulus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "base modulus target should be retained");
      Assert (From_Alias_Modulus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "alias modulus target should be retained");
      Assert (From_Derived_Modulus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived modulus target should be retained");
      Assert (Bad_Integer_Modulus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad integer modulus target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "small target should be retained");

      From_Modulus_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Modulus_Id, 1);
      From_Base_Modulus_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Modulus_Id, 1);
      From_Alias_Modulus_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Alias_Modulus_Id, 1);
      From_Derived_Modulus_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Derived_Modulus_Id, 1);
      Bad_Integer_Modulus_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Integer_Modulus_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Integer_Modulus_Id
            then
               Seen_Bad_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Modulus_Size.Has_Static_Value
              and then From_Modulus_Size.Static_Value = 32,
              "modular T'Modulus should be a retained static integer attribute");
      Assert (From_Base_Modulus_Size.Has_Static_Value
              and then From_Base_Modulus_Size.Static_Value = 16,
              "modular T'Base'Modulus should be retained for static arithmetic");
      Assert (From_Alias_Modulus_Size.Has_Static_Value
              and then From_Alias_Modulus_Size.Static_Value = 8,
              "modular subtype aliases should preserve 'Modulus static metadata");
      Assert (From_Derived_Modulus_Size.Has_Static_Value
              and then From_Derived_Modulus_Size.Static_Value = 4,
              "derived modular scalar types should preserve 'Base'Modulus static metadata");
      Assert (not Bad_Integer_Modulus_Size.Has_Static_Value,
              "nonmodular T'Modulus should not become a static size value");
      Assert (Seen_Bad_Error,
              "nonmodular T'Modulus should produce a static-value diagnostic");
      Assert (not Seen_Good_Small_Error,
              "numeric-only clauses should accept modular T'Modulus in real arithmetic");
   end Test_Language_Model_Representation_Static_Modulus_Attribute_Pass;





   procedure Test_Language_Model_Representation_Static_Min_Max_Attribute_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Byte is range 0 .. 255;" & ASCII.LF &
        "   type Offset is range -8 .. 7;" & ASCII.LF &
        "   type From_Min is range 0 .. 1;" & ASCII.LF &
        "   for From_Min'Size use Byte'Min(8 * 4, 16);" & ASCII.LF &
        "   type From_Max is range 0 .. 1;" & ASCII.LF &
        "   for From_Max'Size use Byte'Max(8, 24);" & ASCII.LF &
        "   type From_Base_Max is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Max'Size use Byte'Base'Max(2, 6) * 4;" & ASCII.LF &
        "   type Narrow is range Offset'Min(-4, 2) .. Offset'Base'Max(4, 7);" & ASCII.LF &
        "   type From_Signed_Max is range 0 .. 1;" & ASCII.LF &
        "   for From_Signed_Max'Size use Narrow'Last + 1;" & ASCII.LF &
        "   type Bad_Max is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Max'Size use Byte'Max(16, 512);" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Min_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Min");
      From_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Max");
      From_Base_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Max");
      From_Signed_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Signed_Max");
      Bad_Max_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Max");
      From_Min_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Base_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Signed_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Max_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Max_Error : Boolean := False;
   begin
      Assert (From_Min_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Min target should be retained");
      Assert (From_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Max target should be retained");
      Assert (From_Base_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Max target should be retained");
      Assert (From_Signed_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "signed Max target should be retained");
      Assert (Bad_Max_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Max target should be retained");

      From_Min_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Min_Id, 1);
      From_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Max_Id, 1);
      From_Base_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Max_Id, 1);
      From_Signed_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Signed_Max_Id, 1);
      Bad_Max_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Max_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Max_Id
            then
               Seen_Bad_Max_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Min_Size.Has_Static_Value
              and then From_Min_Size.Static_Value = 16,
              "T'Min should be evaluated as a static scalar attribute");
      Assert (From_Max_Size.Has_Static_Value
              and then From_Max_Size.Static_Value = 24,
              "T'Max should be evaluated as a static scalar attribute");
      Assert (From_Base_Max_Size.Has_Static_Value
              and then From_Base_Max_Size.Static_Value = 24,
              "T'Base'Max should be evaluated as a static scalar attribute");
      Assert (From_Signed_Max_Size.Has_Static_Value
              and then From_Signed_Max_Size.Static_Value = 8,
              "signed T'Min/T'Base'Max bounds should feed later static attributes");
      Assert (not Bad_Max_Size.Has_Static_Value,
              "out-of-range T'Max operands should not become static");
      Assert (Seen_Bad_Max_Error,
              "out-of-range T'Max operands should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Min_Max_Attribute_Pass;





   procedure Test_Language_Model_Representation_Static_Succ_Pred_Attribute_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Byte is range 0 .. 15;" & ASCII.LF &
        "   type Offset is range -4 .. 4;" & ASCII.LF &
        "   type From_Succ is range 0 .. 1;" & ASCII.LF &
        "   for From_Succ'Size use Byte'Succ(7) * 2;" & ASCII.LF &
        "   type From_Pred is range 0 .. 1;" & ASCII.LF &
        "   for From_Pred'Size use Byte'Pred(Byte'Succ(3));" & ASCII.LF &
        "   type From_Base_Succ is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Succ'Size use Byte'Base'Succ(5) * 4;" & ASCII.LF &
        "   type Signed_Narrow is range Offset'Pred(0) .. Offset'Base'Succ(2);" & ASCII.LF &
        "   type From_Signed_Succ is range 0 .. 1;" & ASCII.LF &
        "   for From_Signed_Succ'Size use Signed_Narrow'Last + 1;" & ASCII.LF &
        "   type Good_Small is delta 0.1 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Byte'Succ(3) / 2.0;" & ASCII.LF &
        "   type Bad_Succ is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Succ'Size use Byte'Succ(15);" & ASCII.LF &
        "   type Bad_Pred is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Pred'Size use Byte'Pred(0);" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Succ");
      From_Pred_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Pred");
      From_Base_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Succ");
      From_Signed_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Signed_Succ");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Bad_Succ_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Succ");
      Bad_Pred_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Pred");
      From_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Pred_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Base_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Signed_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Succ_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Pred_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Succ_Error : Boolean := False;
      Seen_Bad_Pred_Error : Boolean := False;
      Seen_Good_Small_Error : Boolean := False;
   begin
      Assert (From_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Succ target should be retained");
      Assert (From_Pred_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Pred target should be retained");
      Assert (From_Base_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Succ target should be retained");
      Assert (From_Signed_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "signed Succ target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "numeric Succ Small target should be retained");
      Assert (Bad_Succ_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Succ target should be retained");
      Assert (Bad_Pred_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Pred target should be retained");

      From_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Succ_Id, 1);
      From_Pred_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Pred_Id, 1);
      From_Base_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Succ_Id, 1);
      From_Signed_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Signed_Succ_Id, 1);
      Bad_Succ_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Succ_Id, 1);
      Bad_Pred_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Pred_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Succ_Id
            then
               Seen_Bad_Succ_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Pred_Id
            then
               Seen_Bad_Pred_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Succ_Size.Has_Static_Value
              and then From_Succ_Size.Static_Value = 16,
              "T'Succ should be evaluated in natural static representation expressions");
      Assert (From_Pred_Size.Has_Static_Value
              and then From_Pred_Size.Static_Value = 3,
              "T'Pred should compose with nested T'Succ static expressions");
      Assert (From_Base_Succ_Size.Has_Static_Value
              and then From_Base_Succ_Size.Static_Value = 24,
              "T'Base'Succ should be evaluated in static representation expressions");
      Assert (From_Signed_Succ_Size.Has_Static_Value
              and then From_Signed_Succ_Size.Static_Value = 4,
              "signed Succ/Pred bounds should feed later static attributes");
      Assert (not Seen_Good_Small_Error,
              "numeric-only clauses should accept discrete Succ in real arithmetic");
      Assert (not Bad_Succ_Size.Has_Static_Value,
              "out-of-range Succ result should not become static");
      Assert (not Bad_Pred_Size.Has_Static_Value,
              "out-of-range Pred result should not become static");
      Assert (Seen_Bad_Succ_Error,
              "out-of-range Succ should produce a static-value diagnostic");
      Assert (Seen_Bad_Pred_Error,
              "out-of-range Pred should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Succ_Pred_Attribute_Pass;





   procedure Test_Language_Model_Representation_Static_Pos_Val_Attribute_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Byte is range 0 .. 15;" & ASCII.LF &
        "   type Offset is range -4 .. 4;" & ASCII.LF &
        "   type From_Pos is range 0 .. 1;" & ASCII.LF &
        "   for From_Pos'Size use Byte'Pos(7) * 2;" & ASCII.LF &
        "   type From_Val is range 0 .. 1;" & ASCII.LF &
        "   for From_Val'Size use Byte'Val(Byte'Pos(6));" & ASCII.LF &
        "   type From_Base_Val is range 0 .. 1;" & ASCII.LF &
        "   for From_Base_Val'Size use Byte'Base'Val(5) * 4;" & ASCII.LF &
        "   type Signed_Narrow is range Offset'Pos(-1) .. Offset'Base'Val(2);" & ASCII.LF &
        "   type From_Signed_Val is range 0 .. 1;" & ASCII.LF &
        "   for From_Signed_Val'Size use Signed_Narrow'Last + 2;" & ASCII.LF &
        "   type Good_Small is delta 0.1 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use Byte'Pos(3) / 2.0;" & ASCII.LF &
        "   type Bad_Pos is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Pos'Size use Byte'Pos(16);" & ASCII.LF &
        "   type Bad_Val is range 0 .. 1;" & ASCII.LF &
        "   for Bad_Val'Size use Byte'Val(16);" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Pos");
      From_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Val");
      From_Base_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Base_Val");
      From_Signed_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Signed_Val");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Bad_Pos_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Pos");
      Bad_Val_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Val");
      From_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Base_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Signed_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Pos_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Bad_Val_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Bad_Pos_Error : Boolean := False;
      Seen_Bad_Val_Error : Boolean := False;
      Seen_Good_Small_Error : Boolean := False;
   begin
      Assert (From_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Pos target should be retained");
      Assert (From_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Val target should be retained");
      Assert (From_Base_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Base Val target should be retained");
      Assert (From_Signed_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "signed Val target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "numeric Pos Small target should be retained");
      Assert (Bad_Pos_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Pos target should be retained");
      Assert (Bad_Val_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Val target should be retained");

      From_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Pos_Id, 1);
      From_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Val_Id, 1);
      From_Base_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Base_Val_Id, 1);
      From_Signed_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Signed_Val_Id, 1);
      Bad_Pos_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Pos_Id, 1);
      Bad_Val_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Bad_Val_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Pos_Id
            then
               Seen_Bad_Pos_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Representation_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Val_Id
            then
               Seen_Bad_Val_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Pos_Size.Has_Static_Value
              and then From_Pos_Size.Static_Value = 14,
              "T'Pos should be evaluated in natural static representation expressions");
      Assert (From_Val_Size.Has_Static_Value
              and then From_Val_Size.Static_Value = 6,
              "T'Val should compose with nested T'Pos static expressions");
      Assert (From_Base_Val_Size.Has_Static_Value
              and then From_Base_Val_Size.Static_Value = 20,
              "T'Base'Val should be evaluated in static representation expressions");
      Assert (From_Signed_Val_Size.Has_Static_Value
              and then From_Signed_Val_Size.Static_Value = 4,
              "signed Pos/Val bounds should feed later static attributes");
      Assert (not Seen_Good_Small_Error,
              "numeric-only clauses should accept discrete Pos in real arithmetic");
      Assert (not Bad_Pos_Size.Has_Static_Value,
              "out-of-range Pos operand should not become static");
      Assert (not Bad_Val_Size.Has_Static_Value,
              "out-of-range Val operand should not become static");
      Assert (Seen_Bad_Pos_Error,
              "out-of-range Pos should produce a static-value diagnostic");
      Assert (Seen_Bad_Val_Error,
              "out-of-range Val should produce a static-value diagnostic");
   end Test_Language_Model_Representation_Static_Pos_Val_Attribute_Pass;





   procedure Test_Language_Model_Representation_Static_Abs_Operator_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type From_Abs_Natural is range 0 .. 1;" & ASCII.LF &
        "   for From_Abs_Natural'Size use abs (-8) * 2;" & ASCII.LF &
        "   type Narrow is range -abs (4) .. abs (-3);" & ASCII.LF &
        "   type From_Signed_Abs is range 0 .. 1;" & ASCII.LF &
        "   for From_Signed_Abs'Size use Narrow'Last + abs (Narrow'First);" & ASCII.LF &
        "   type Good_Small is delta 0.1 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Good_Small'Small use abs (-1.0) / 2.0;" & ASCII.LF &
        "   type Bad_Small is delta 0.1 range 0.0 .. 1.0;" & ASCII.LF &
        "   for Bad_Small'Small use abs (-1.0) mod 2;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      From_Abs_Natural_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Abs_Natural");
      From_Signed_Abs_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "From_Signed_Abs");
      Good_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Good_Small");
      Bad_Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad_Small");
      From_Abs_Natural_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      From_Signed_Abs_Size : Editor.Ada_Language_Model.Representation_Clause_Info;
      Seen_Good_Small_Error : Boolean := False;
      Seen_Bad_Small_Error : Boolean := False;
   begin
      Assert (From_Abs_Natural_Id /= Editor.Ada_Language_Model.No_Symbol,
              "abs natural target should be retained");
      Assert (From_Signed_Abs_Id /= Editor.Ada_Language_Model.No_Symbol,
              "signed abs target should be retained");
      Assert (Good_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "good Small abs target should be retained");
      Assert (Bad_Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Small abs target should be retained");

      From_Abs_Natural_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Abs_Natural_Id, 1);
      From_Signed_Abs_Size :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, From_Signed_Abs_Id, 1);

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Good_Small_Id
            then
               Seen_Good_Small_Error := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Legality_Small_Static_Value_Required
              and then Info.Primary_Symbol = Bad_Small_Id
            then
               Seen_Bad_Small_Error := True;
            end if;
         end;
      end loop;

      Assert (From_Abs_Natural_Size.Has_Static_Value
              and then From_Abs_Natural_Size.Static_Value = 16,
              "unary abs should feed Natural-valued representation arithmetic");
      Assert (From_Signed_Abs_Size.Has_Static_Value
              and then From_Signed_Abs_Size.Static_Value = 7,
              "unary abs should feed signed ranges and later representation values");
      Assert (not Seen_Good_Small_Error,
              "numeric-only Small clauses should accept real-valued abs arithmetic");
      Assert (Seen_Bad_Small_Error,
              "real-valued abs operands should still reject integer-only mod");
   end Test_Language_Model_Representation_Static_Abs_Operator_Pass;




   procedure Test_Language_Model_Representation_Static_Integer_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   Decimal_Text : constant String := ""12"";" & ASCII.LF &
        "   Joined_Text : constant String := ""1"" & ""6"";" & ASCII.LF &
        "   Bad_Natural_Text : constant String := ""-1"";" & ASCII.LF &
        "   Low : constant := Integer'Value (""-4"");" & ASCII.LF &
        "   High : constant := Integer'Value ("" 4"");" & ASCII.LF &
        "   N : constant Natural := Natural'Value (Joined_Text);" & ASCII.LF &
        "   type Offset is range Low .. High;" & ASCII.LF &
        "   type V1 is range 0 .. 255;" & ASCII.LF &
        "   for V1'Size use Natural'Value (Decimal_Text) * 8;" & ASCII.LF &
        "   type V2 is range 0 .. 255;" & ASCII.LF &
        "   for V2'Size use Offset'Last * 8;" & ASCII.LF &
        "   type V3 is range 0 .. 255;" & ASCII.LF &
        "   for V3'Size use N * 8;" & ASCII.LF &
        "   type Bad is range 0 .. 255;" & ASCII.LF &
        "   for Bad'Size use Natural'Value (Bad_Natural_Text) * 8;" & ASCII.LF &
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
              "Natural'Value target should be retained");
      Assert (V2_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Integer'Value range target should be retained");
      Assert (V3_Id /= Editor.Ada_Language_Model.No_Symbol,
              "typed constant initialized by Value should be retained");
      Assert (Bad_Id /= Editor.Ada_Language_Model.No_Symbol,
              "bad Natural'Value target should be retained");

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

      Assert (V1_Size.Has_Static_Value and then V1_Size.Static_Value = 96,
              "Natural'Value over retained static strings should feed Size");
      Assert (V2_Size.Has_Static_Value and then V2_Size.Static_Value = 32,
              "Integer'Value should feed signed range metadata");
      Assert (V3_Size.Has_Static_Value and then V3_Size.Static_Value = 128,
              "typed Natural constants initialized by Value should feed Size");
      Assert (not Bad_Size.Has_Static_Value,
              "out-of-range Natural'Value strings should stay nonstatic");
      Assert (Seen_Bad_Error,
              "out-of-range Natural'Value strings should produce a diagnostic");
   end Test_Language_Model_Representation_Static_Integer_Value_Pass;



   procedure Test_Language_Model_Executable_Aspect_Expression_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Contracts is" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   Count : Integer := 0;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean;" & ASCII.LF &
        "   procedure Run" & ASCII.LF &
        "     with Pre => Ready and Check (Count)," & ASCII.LF &
        "          Post => Ready;" & ASCII.LF &
        "end Contracts;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "contracts.ads");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Aspect_Expression) = 2,
         "contract aspect expressions should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Call_Target) >= 1,
         "nested calls inside contract aspects should be retained by expression scanners");
   end Test_Language_Model_Executable_Aspect_Expression_Bindings;






   procedure Test_Language_Model_Legality_Representation_Static_Component_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Colour is (Red, Green);" & ASCII.LF &
        "   Dynamic_Value : constant Integer := 1;" & ASCII.LF &
        "   for Colour use (Red => Dynamic_Value, Green => 2);" & ASCII.LF &
        "   type Pair is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Position : constant Integer := 0;" & ASCII.LF &
        "   First_Bit : constant Integer := 0;" & ASCII.LF &
        "   for Pair use record" & ASCII.LF &
        "      A at Position range 0 .. 7;" & ASCII.LF &
        "      B at 1 range First_Bit .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Enum_Static : Boolean := False;
      Seen_Static_Position : Boolean := False;
      Seen_Static_Bit_Range : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "representation static legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Enumeration_Representation_Static_Value_Required =>
                  Seen_Enum_Static := True;
               when Editor.Ada_Language_Model.Legality_Record_Component_Static_Position_Required =>
                  Seen_Static_Position := True;
               when Editor.Ada_Language_Model.Legality_Record_Component_Static_Bit_Range_Required =>
                  Seen_Static_Bit_Range := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Enum_Static,
              "legality checking should require static enumeration representation values");
      Assert (Seen_Static_Position,
              "legality checking should require static record representation positions");
      Assert (Seen_Static_Bit_Range,
              "legality checking should require static record representation bit ranges");
   end Test_Language_Model_Legality_Representation_Static_Component_Pass;


   overriding function Name (T : Representation_Static_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Representation.Static");
   end Name;

   overriding procedure Register_Tests (T : in out Representation_Static_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Representation_Legality_Static_Freezing'Access, Name => "Ada representation legality uses freezing, target kinds, and static values");
      Add_Test (Routine => Test_Language_Model_Record_Representation_Static_Literals_Are_Parsed'Access, Name => "language model parses static record representation literal values");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Expressions_Are_Evaluated'Access, Name => "language model evaluates bounded static representation expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Named_Static_Numbers'Access, Name => "language model evaluates named-number representation expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Precise_Static_Evaluation_Pass'Access, Name => "language model evaluates type-compatible static representation expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Real_Arithmetic_Pass'Access, Name => "language model accepts static real arithmetic for Small representation clauses");
      Add_Test (Routine => Test_Language_Model_Representation_Signed_Static_Range_Pass'Access, Name => "language model evaluates signed static ranges and attributes for representation clauses");
      Add_Test (Routine => Test_Language_Model_Representation_Typed_Static_Constants_Pass'Access, Name => "language model validates typed static constants before reusing them in representation clauses");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Numeric_Type_Kind_Pass'Access, Name => "language model distinguishes universal-integer and universal-real static numeric operators");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Attribute_Value_Pass'Access, Name => "language model evaluates retained static representation attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Base_Attribute_Pass'Access, Name => "language model evaluates chained Base static attributes and qualifications");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Modulus_Attribute_Pass'Access, Name => "language model evaluates modular Modulus static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Min_Max_Attribute_Pass'Access, Name => "language model evaluates scalar Min and Max static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Succ_Pred_Attribute_Pass'Access, Name => "language model evaluates scalar Succ and Pred static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Pos_Val_Attribute_Pass'Access, Name => "language model evaluates scalar Pos and Val static attributes");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Abs_Operator_Pass'Access, Name => "language model evaluates unary abs static expressions");
      Add_Test (Routine => Test_Language_Model_Representation_Static_Integer_Value_Pass'Access, Name => "language model evaluates integer Value attributes from static strings");
      Add_Test (Routine => Test_Language_Model_Executable_Aspect_Expression_Bindings'Access, Name => "language model retains executable aspect expression bindings");
      Add_Test (Routine => Test_Language_Model_Legality_Representation_Static_Component_Pass'Access, Name => "language model checks static representation component legality");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Static_Tests;
