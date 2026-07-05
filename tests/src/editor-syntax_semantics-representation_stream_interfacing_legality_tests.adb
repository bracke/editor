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

package body Editor.Syntax_Semantics.Representation_Stream_Interfacing_Legality_Tests is

   procedure Test_Ada_Interfacing_Representation_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Interfacing_Value_Status;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Interfacing_Representation_Checks is" & ASCII.LF &
        "   type Plain is null record;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   procedure C_Run;" & ASCII.LF &
        "   procedure Imported_Only;" & ASCII.LF &
        "   procedure Exported;" & ASCII.LF &
        "   procedure Bad_Convention;" & ASCII.LF &
        "   for C_Run'Convention use C;" & ASCII.LF &
        "   for C_Run'Import use True;" & ASCII.LF &
        "   for C_Run'Export use True;" & ASCII.LF &
        "   for C_Run'Link_Name use ""c_run"";" & ASCII.LF &
        "   for Imported_Only'Import use True;" & ASCII.LF &
        "   for Exported'Link_Name use ""standalone"";" & ASCII.LF &
        "   for Bad_Convention'Convention use 123;" & ASCII.LF &
        "   for Exported'Import use Maybe;" & ASCII.LF &
        "   for Plain'Import use True;" & ASCII.LF &
        "   for X'External_Name use Dynamic_Name;" & ASCII.LF &
        "end Interfacing_Representation_Checks;";
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
      Seen_Convention_Ok : Boolean := False;
      Seen_Import_Ok : Boolean := False;
      Seen_Conflict : Boolean := False;
      Seen_Link_Requires : Boolean := False;
      Seen_Convention_Value_Error : Boolean := False;
      Seen_Boolean_Value_Error : Boolean := False;
      Seen_String_Value_Error : Boolean := False;
      Seen_Target_Error : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Convention_Clause
              and then Info.Interfacing_Status =
                Editor.Ada_Representation_Legality.Interfacing_Value_Convention_Identifier
            then
               Seen_Convention_Ok := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Import_Clause
              and then Info.Interfacing_Status =
                Editor.Ada_Representation_Legality.Interfacing_Value_Static_Boolean_True
            then
               Seen_Import_Ok := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Import_Export_Conflict then
               Seen_Conflict := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Link_Name_Requires_Import_Export then
               Seen_Link_Requires := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Convention_Identifier_Required then
               Seen_Convention_Value_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Import_Export_Boolean_Value_Required then
               Seen_Boolean_Value_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Link_Name_String_Value_Required then
               Seen_String_Value_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Interfacing_Target_Incompatible then
               Seen_Target_Error := True;
            end if;
         end;
      end loop;

      Assert (Seen_Convention_Ok,
              "interfacing legality must accept known Convention identifiers");
      Assert (Seen_Import_Ok,
              "interfacing legality must accept static Boolean Import clauses");
      Assert (Seen_Conflict,
              "interfacing legality must reject enabled Import and Export on the same target");
      Assert (Seen_Link_Requires,
              "interfacing legality must require Link_Name/External_Name to accompany enabled Import or Export");
      Assert (Seen_Convention_Value_Error,
              "interfacing legality must reject non-identifier Convention values");
      Assert (Seen_Boolean_Value_Error,
              "interfacing legality must reject non-Boolean Import/Export values");
      Assert (Seen_String_Value_Error,
              "interfacing legality must reject non-string Link_Name/External_Name values");
      Assert (Seen_Target_Error,
              "interfacing legality must reject Import/Export on incompatible representation targets");
      Assert (Editor.Ada_Representation_Legality.Interfacing_Error_Count (Legality) >= 5,
              "interfacing legality must count all interfacing errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Interfacing_Target_Error_Count (Legality) >= 1,
              "interfacing legality must count target errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Interfacing_Value_Error_Count (Legality) >= 3,
              "interfacing legality must count value errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Import_Export_Conflict_Count (Legality) >= 1,
              "interfacing legality must count Import/Export conflicts deterministically");
      Assert (Editor.Ada_Representation_Legality.Link_Name_Requires_Import_Export_Count (Legality) >= 1,
              "interfacing legality must count standalone link-name clauses deterministically");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "interfacing legality must contribute to deterministic fingerprints");
   end Test_Ada_Interfacing_Representation_Legality;

   procedure Test_Ada_Stream_Attribute_Representation_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Stream_Subprogram_Status;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Stream_Attribute_Checks is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   procedure Read_Item (Stream : access Integer; Value : out Item);" & ASCII.LF &
        "   procedure Write_Item (Stream : access Integer; Value : Item);" & ASCII.LF &
        "   procedure Bad_Target;" & ASCII.LF &
        "   for Item'Read use Read_Item;" & ASCII.LF &
        "   for Item'Write use Write_Item;" & ASCII.LF &
        "   for Item'Input use 123;" & ASCII.LF &
        "   for Bad_Target'Read use Read_Item;" & ASCII.LF &
        "end Stream_Attribute_Checks;";
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
      Seen_Read_Profile_Unknown : Boolean := False;
      Seen_Write_Profile_Unknown : Boolean := False;
      Seen_Malformed : Boolean := False;
      Seen_Target_Error : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Read_Clause
              and then Info.Stream_Status =
                Editor.Ada_Representation_Legality.Stream_Subprogram_Profile_Unknown
            then
               Seen_Read_Profile_Unknown := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Write_Clause
              and then Info.Stream_Status =
                Editor.Ada_Representation_Legality.Stream_Subprogram_Profile_Unknown
            then
               Seen_Write_Profile_Unknown := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Malformed then
               Seen_Malformed := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Stream_Target_Incompatible then
               Seen_Target_Error := True;
            end if;
         end;
      end loop;

      Assert (Seen_Read_Profile_Unknown,
              "stream legality must stage Read subprogram designators for profile checking");
      Assert (Seen_Write_Profile_Unknown,
              "stream legality must stage Write subprogram designators for profile checking");
      Assert (Seen_Malformed,
              "stream legality must reject malformed stream attribute subprogram items");
      Assert (Seen_Target_Error,
              "stream legality must reject stream attributes on incompatible targets");
      Assert (Editor.Ada_Representation_Legality.Stream_Error_Count (Legality) >= 4,
              "stream legality must count stream errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Stream_Target_Error_Count (Legality) >= 1,
              "stream legality must count stream target errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Stream_Profile_Unknown_Count (Legality) >= 2,
              "stream legality must preserve profile-unknown stream designators deterministically");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "stream legality must contribute to deterministic fingerprints");
   end Test_Ada_Stream_Attribute_Representation_Legality;

   procedure Test_Ada_Stream_Attribute_Profile_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Representation_Legality.Stream_Subprogram_Status;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Stream_Profile_Checks is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   procedure Read_Item (Stream : access Integer; Value : out Item);" & ASCII.LF &
        "   procedure Write_Item (Stream : access Integer; Value : Item);" & ASCII.LF &
        "   function Input_Item (Stream : access Integer) return Item;" & ASCII.LF &
        "   procedure Bad_Read (Stream : access Integer);" & ASCII.LF &
        "   function Bad_Write (Stream : access Integer) return Item;" & ASCII.LF &
        "   for Item'Read use Read_Item;" & ASCII.LF &
        "   for Item'Write use Write_Item;" & ASCII.LF &
        "   for Item'Input use Input_Item;" & ASCII.LF &
        "   for Item'Output use Bad_Read;" & ASCII.LF &
        "   for Item'Put_Image use Bad_Write;" & ASCII.LF &
        "end Stream_Profile_Checks;";
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
      Profiles : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build_With_Stream_Profiles
          (Tree, Regions, Visibility, Types, Static, Freezing, Profiles);
      Seen_Read_Compatible : Boolean := False;
      Seen_Write_Compatible : Boolean := False;
      Seen_Input_Compatible : Boolean := False;
      Seen_Output_Mismatch : Boolean := False;
      Seen_Put_Image_Mismatch : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Read_Clause
              and then Info.Stream_Status =
                Editor.Ada_Representation_Legality.Stream_Subprogram_Profile_Known_Compatible
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Read_Compatible := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Write_Clause
              and then Info.Stream_Status =
                Editor.Ada_Representation_Legality.Stream_Subprogram_Profile_Known_Compatible
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Write_Compatible := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Input_Clause
              and then Info.Stream_Status =
                Editor.Ada_Representation_Legality.Stream_Subprogram_Profile_Known_Compatible
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Input_Compatible := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Output_Clause
              and then Info.Status =
                Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Profile_Mismatch
            then
               Seen_Output_Mismatch := True;
            elsif Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Put_Image_Clause
              and then Info.Status =
                Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Profile_Mismatch
            then
               Seen_Put_Image_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Seen_Read_Compatible,
              "stream profile conformance must accept two-parameter Read procedures");
      Assert (Seen_Write_Compatible,
              "stream profile conformance must accept two-parameter Write procedures");
      Assert (Seen_Input_Compatible,
              "stream profile conformance must accept one-parameter Input functions");
      Assert (Seen_Output_Mismatch,
              "stream profile conformance must reject malformed Output procedures");
      Assert (Seen_Put_Image_Mismatch,
              "stream profile conformance must reject malformed Put_Image designators");
      Assert (Editor.Ada_Representation_Legality.Stream_Profile_Error_Count (Legality) >= 2,
              "stream profile conformance must count mismatched stream profiles deterministically");
      Assert (Editor.Ada_Representation_Legality.Stream_Profile_Unknown_Count (Legality) = 0,
              "resolved stream designators must not remain profile-unknown");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "stream profile conformance must contribute to deterministic fingerprints");
   end Test_Ada_Stream_Attribute_Profile_Conformance;

   procedure Test_Ada_Stream_Attribute_Target_Profile_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Stream_Target_Profile_Conformance is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   type Other is null record;" & ASCII.LF &
        "   type Mismatch is null record;" & ASCII.LF &
        "   procedure Read_Item (Stream : access Integer; Value : out Item);" & ASCII.LF &
        "   procedure Write_Item (Stream : access Integer; Value : Item);" & ASCII.LF &
        "   function Input_Item (Stream : access Integer) return Item;" & ASCII.LF &
        "   function Bad_Input (Stream : access Integer) return Other;" & ASCII.LF &
        "   procedure Bad_Output (Stream : access Integer);" & ASCII.LF &
        "   for Item'Read use Read_Item;" & ASCII.LF &
        "   for Item'Write use Write_Item;" & ASCII.LF &
        "   for Item'Input use Input_Item;" & ASCII.LF &
        "   for Item'Output use Bad_Output;" & ASCII.LF &
        "   for Mismatch'Input use Bad_Input;" & ASCII.LF &
        "end Stream_Target_Profile_Conformance;";
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
      Profiles : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build_With_Stream_Profiles
          (Tree, Regions, Visibility, Types, Static, Freezing, Profiles);
      Stream_Profiles : constant Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model :=
        Editor.Ada_Stream_Attribute_Profile_Conformance.Build (Legality, Profiles);
      Saw_Compatible : Boolean := False;
      Saw_Arity : Boolean := False;
      Saw_Result : Boolean := False;
   begin
      Assert (Editor.Ada_Stream_Attribute_Profile_Conformance.Check_Count (Stream_Profiles) >= 5,
              "stream target-profile conformance must stage stream attribute clauses");

      for Index in 1 .. Editor.Ada_Stream_Attribute_Profile_Conformance.Check_Count (Stream_Profiles) loop
         declare
            Info : constant Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Info :=
              Editor.Ada_Stream_Attribute_Profile_Conformance.Check_At (Stream_Profiles, Index);
         begin
            if Info.Status = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Compatible then
               Saw_Compatible := True;
            elsif Info.Status = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Arity_Mismatch then
               Saw_Arity := True;
            elsif Info.Status = Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Result_Mismatch then
               Saw_Result := True;
            end if;
         end;
      end loop;

      Assert (Saw_Compatible,
              "stream target-profile conformance must accept compatible handlers");
      Assert (Saw_Arity,
              "stream target-profile conformance must reject wrong handler arity");
      Assert (Saw_Result,
              "stream target-profile conformance must reject Input result subtype mismatches");
      Assert (Editor.Ada_Stream_Attribute_Profile_Conformance.Compatible_Count (Stream_Profiles) >= 3,
              "stream target-profile conformance must count compatible handlers");
      Assert (Editor.Ada_Stream_Attribute_Profile_Conformance.Arity_Mismatch_Count (Stream_Profiles) >= 1,
              "stream target-profile conformance must count arity mismatches");
      Assert (Editor.Ada_Stream_Attribute_Profile_Conformance.Result_Mismatch_Count (Stream_Profiles) >= 1,
              "stream target-profile conformance must count result mismatches");
      Assert (Editor.Ada_Stream_Attribute_Profile_Conformance.Fingerprint (Stream_Profiles) /= 0,
              "stream target-profile conformance must retain deterministic fingerprints");
   end Test_Ada_Stream_Attribute_Target_Profile_Conformance;

   procedure Test_Ada_Representation_Diagnostics_Stream_Profile_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Stream_Target_Profile_Diagnostics is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   type Other is null record;" & ASCII.LF &
        "   function Bad_Input (Stream : access Integer) return Other;" & ASCII.LF &
        "   procedure Bad_Output (Stream : access Integer);" & ASCII.LF &
        "   for Item'Input use Bad_Input;" & ASCII.LF &
        "   for Item'Output use Bad_Output;" & ASCII.LF &
        "end Stream_Target_Profile_Diagnostics;";
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
      Freezing_Points : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Profiles : constant Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model :=
        Editor.Ada_Call_Profile_Shapes.Build (Tree, Regions);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generics : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build_With_Stream_Profiles
          (Tree, Regions, Visibility, Types, Static, Freezing_Points, Profiles);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Freezing : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing_Points, Types, Private_Views, Generics);
      Stream_Profiles : constant Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model :=
        Editor.Ada_Stream_Attribute_Profile_Conformance.Build (Legality, Profiles);
      Diagnostics : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build_With_Stream_Profile_Conformance
          (Legality, Layout, Storage, Operational, Inheritance, Freezing, Stream_Profiles);
      Saw_Result : Boolean := False;
      Saw_Arity : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Diagnostics.Diagnostic_Count (Diagnostics) loop
         declare
            Info : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Info :=
              Editor.Ada_Representation_Diagnostics.Diagnostic_At (Diagnostics, Index);
         begin
            if Info.Kind = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Stream_Handler_Result_Mismatch then
               Saw_Result := True;
            elsif Info.Kind = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Stream_Handler_Arity_Mismatch then
               Saw_Arity := True;
            end if;
         end;
      end loop;

      Assert (Saw_Result,
              "representation diagnostics must project stream Input result mismatches");
      Assert (Saw_Arity,
              "representation diagnostics must project stream handler arity mismatches");
      Assert (Editor.Ada_Representation_Diagnostics.Stream_Profile_Conformance_Diagnostic_Count (Diagnostics) >= 2,
              "representation diagnostics must count stream profile conformance diagnostics");
      Assert (Editor.Ada_Representation_Diagnostics.Stream_Profile_Handler_Error_Count (Diagnostics) >= 2,
              "representation diagnostics must count stream handler errors");
      Assert (Editor.Ada_Representation_Diagnostics.Fingerprint (Diagnostics) /= 0,
              "representation diagnostics with stream profile conformance must retain deterministic fingerprints");
   end Test_Ada_Representation_Diagnostics_Stream_Profile_Conformance;

   procedure Test_Language_Model_Legality_Interfacing_Pragma_Aspect_Completeness_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   procedure Imported;" & ASCII.LF &
        "   pragma Import (Convention => C, Entity => Imported, External_Name => ""imported_c"", Link_Name => ""imported_link"");" & ASCII.LF &
        "   procedure Legacy;" & ASCII.LF &
        "   pragma Interface (C, Legacy);" & ASCII.LF &
        "   pragma External (Legacy, ""legacy_link"");" & ASCII.LF &
        "   procedure Bad;" & ASCII.LF &
        "   pragma Import (Convention => 123, Entity => Bad);" & ASCII.LF &
        "   type Plain is null record with Import;" & ASCII.LF &
        "   procedure Aspect_Bad with Export => True, Link_Name => Dynamic_Name;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Imported_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Imported");
      Legacy_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Legacy");
      Seen_Pragma_Import : Boolean := False;
      Seen_Pragma_Convention : Boolean := False;
      Seen_Pragma_External : Boolean := False;
      Seen_Pragma_Link_Name : Boolean := False;
      Seen_Bad_Pragma_Convention : Boolean := False;
      Seen_Aspect_Target : Boolean := False;
      Seen_Aspect_String : Boolean := False;
   begin
      Assert (Imported_Id /= Editor.Ada_Language_Model.No_Symbol,
              "import pragma target should resolve to the imported procedure");
      Assert (Legacy_Id /= Editor.Ada_Language_Model.No_Symbol,
              "interface/external pragma target should resolve to the legacy procedure");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Imported_Id and then A = "Import" then
               Seen_Pragma_Import :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Import_Clause;
            elsif Info.Target_Symbol = Imported_Id and then A = "Convention" then
               Seen_Pragma_Convention :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Convention_Clause;
            elsif Info.Target_Symbol = Imported_Id and then A = "Link_Name" then
               Seen_Pragma_Link_Name :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Link_Name_Clause;
            elsif Info.Target_Symbol = Legacy_Id and then A = "External_Name" then
               Seen_Pragma_External :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_External_Name_Clause;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Convention_Identifier_Required =>
                  Seen_Bad_Pragma_Convention := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_Attribute_Target_Incompatible =>
                  Seen_Aspect_Target := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_String_Value_Required =>
                  Seen_Aspect_String := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Pragma_Import,
              "pragma Import should be lowered into Import representation metadata");
      Assert (Seen_Pragma_Convention,
              "pragma Import should preserve its convention argument for legality checking");
      Assert (Seen_Pragma_External,
              "pragma External should use its first argument as the target and retain the external name kind");
      Assert (Seen_Pragma_Link_Name,
              "pragma Import Link_Name should use the explicit link-name representation kind");
      Assert (Seen_Bad_Pragma_Convention,
              "interfacing pragmas should validate convention identifiers through the common legality path");
      Assert (Seen_Aspect_Target,
              "interfacing aspects should validate target compatibility through the common legality path");
      Assert (Seen_Aspect_String,
              "interfacing aspects should validate External_Name/Link_Name string values");
   end Test_Language_Model_Legality_Interfacing_Pragma_Aspect_Completeness_Pass;

   procedure Test_Language_Model_Legality_Interfacing_Attribute_Target_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Plain is null record;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   procedure Exported;" & ASCII.LF &
        "   for Plain'Import use True;" & ASCII.LF &
        "   for Plain'Link_Name use Dynamic_Name;" & ASCII.LF &
        "   for X'Link_Name use ""x_symbol"";" & ASCII.LF &
        "   for Exported'Export use True;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Target : Boolean := False;
      Seen_Link_Target : Boolean := False;
      Seen_String_Value : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "interfacing attribute legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Interfacing_Attribute_Target_Incompatible =>
                  Seen_Target := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_Link_Name_Target_Incompatible =>
                  Seen_Link_Target := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_String_Value_Required =>
                  Seen_String_Value := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Target,
              "legality checking should reject Import/Export attributes on incompatible targets");
      Assert (Seen_Link_Target,
              "legality checking should reject Link_Name/External_Name on incompatible targets");
      Assert (Seen_String_Value,
              "legality checking should require static string link-name values");
   end Test_Language_Model_Legality_Interfacing_Attribute_Target_Pass;

   procedure Test_Language_Model_Legality_Interfacing_Attribute_Value_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   procedure Imported;" & ASCII.LF &
        "   for X'Convention use 123;" & ASCII.LF &
        "   for Imported'Import use Maybe;" & ASCII.LF &
        "   for Imported'Export use Standard.True;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Convention_Value : Boolean := False;
      Seen_Boolean_Value : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "interfacing attribute value legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Convention_Identifier_Required =>
                  Seen_Convention_Value := True;
               when Editor.Ada_Language_Model.Legality_Import_Export_Boolean_Value_Required =>
                  Seen_Boolean_Value := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Convention_Value,
              "legality checking should require Convention to name an identifier");
      Assert (Seen_Boolean_Value,
              "legality checking should require Import/Export to use a static Boolean value");
   end Test_Language_Model_Legality_Interfacing_Attribute_Value_Pass;

   procedure Test_Language_Model_Legality_Interfacing_Conflict_Representation_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   procedure C_Run;" & ASCII.LF &
        "   procedure Standalone;" & ASCII.LF &
        "   procedure Odd;" & ASCII.LF &
        "   for C_Run'Import use True;" & ASCII.LF &
        "   for C_Run'Export use True;" & ASCII.LF &
        "   for Standalone'Link_Name use ""standalone"";" & ASCII.LF &
        "   for Odd'Convention use Strange_ABI;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Import_Export_Conflict : Boolean := False;
      Seen_Link_Requires_Import_Export : Boolean := False;
      Seen_Unknown_Convention : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "interfacing representation conflict legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Interfacing_Import_Export_Conflict =>
                  Seen_Import_Export_Conflict := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_Link_Name_Requires_Import_Export =>
                  Seen_Link_Requires_Import_Export := True;
               when Editor.Ada_Language_Model.Legality_Convention_Identifier_Unknown =>
                  Seen_Unknown_Convention := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Import_Export_Conflict,
              "legality checking should reject targets with both Import and Export enabled");
      Assert (Seen_Link_Requires_Import_Export,
              "legality checking should require Link_Name/External_Name to accompany enabled Import or Export");
      Assert (Seen_Unknown_Convention,
              "legality checking should flag unknown convention identifiers in the bounded model");
   end Test_Language_Model_Legality_Interfacing_Conflict_Representation_Pass;

   procedure Test_Language_Model_Legality_Stream_Attribute_Profile_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Item is private;" & ASCII.LF &
        "   procedure Bad_Read (S : access Ada.Streams.Root_Stream_Type'Class; X : in Item);" & ASCII.LF &
        "   function Bad_Input (S : access Ada.Streams.Root_Stream_Type'Class) return Integer;" & ASCII.LF &
        "   for Item'Read use Bad_Read;" & ASCII.LF &
        "   for Item'Input use Bad_Input;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Profile : Boolean := False;
      Seen_Mode    : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "stream operational attribute profile legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Stream_Attribute_Profile_Incompatible =>
                  Seen_Profile := True;
               when Editor.Ada_Language_Model.Legality_Stream_Attribute_Mode_Incompatible =>
                  Seen_Mode := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Profile,
              "legality checking should flag stream handler profiles returning the wrong type");
      Assert (Seen_Mode,
              "legality checking should flag Read handlers whose item parameter is not out-mode");
   end Test_Language_Model_Legality_Stream_Attribute_Profile_Pass;

   procedure Test_Language_Model_Legality_Stream_Attribute_Profile_Completeness_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Item is private;" & ASCII.LF &
        "   procedure Good_Read (S : not null access Ada.Streams.Root_Stream_Type'Class; X : out Item);" & ASCII.LF &
        "   procedure Good_Write (S : not null access Ada.Streams.Root_Stream_Type'Class; X : in Item);" & ASCII.LF &
        "   function Good_Input (S : not null access Ada.Streams.Root_Stream_Type'Class) return Item;" & ASCII.LF &
        "   procedure Good_Output (S : not null access Ada.Streams.Root_Stream_Type'Class; X : Item);" & ASCII.LF &
        "   procedure Bad_Extra (S : not null access Ada.Streams.Root_Stream_Type'Class; X : out Item; Extra : Integer);" & ASCII.LF &
        "   procedure Bad_Stream (S : access Integer; X : out Item);" & ASCII.LF &
        "   procedure Bad_Item (S : not null access Ada.Streams.Root_Stream_Type'Class; X : out Integer);" & ASCII.LF &
        "   for Item'Read use Good_Read;" & ASCII.LF &
        "   for Item'Write use Good_Write;" & ASCII.LF &
        "   for Item'Input use Good_Input;" & ASCII.LF &
        "   for Item'Output use Good_Output;" & ASCII.LF &
        "   type Extra_Target is private;" & ASCII.LF &
        "   for Extra_Target'Read use Bad_Extra;" & ASCII.LF &
        "   type Stream_Target is private;" & ASCII.LF &
        "   for Stream_Target'Read use Bad_Stream;" & ASCII.LF &
        "   type Item_Target is private;" & ASCII.LF &
        "   for Item_Target'Read use Bad_Item;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   type Extra_Target is null record;" & ASCII.LF &
        "   type Stream_Target is null record;" & ASCII.LF &
        "   type Item_Target is null record;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Saw_Profile : Boolean := False;
      Saw_Good_Profile_Diagnostic : Boolean := False;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
            Msg : constant String := To_String (Info.Message);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Stream_Attribute_Profile_Incompatible then
               Saw_Profile := True;
               if Ada.Strings.Fixed.Index (Msg, "Good_") /= 0 then
                  Saw_Good_Profile_Diagnostic := True;
               end if;
            end if;
         end;
      end loop;

      Assert (Saw_Profile,
              "stream attribute profile conformance should reject bad stream, arity, and item profiles");
      Assert (not Saw_Good_Profile_Diagnostic,
              "complete stream attribute profiles should not be rejected");
   end Test_Language_Model_Legality_Stream_Attribute_Profile_Completeness_Pass;

   overriding function Name (T : RepresentationStreamInterfacingLegality_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Representation-Stream-Interfacing-Legality");
   end Name;

   overriding procedure Register_Tests (T : in out RepresentationStreamInterfacingLegality_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Interfacing_Representation_Legality'Access, Name => "Ada representation legality checks Convention, Import, Export, and link-name clauses");
      Add_Test (Routine => Test_Ada_Stream_Attribute_Representation_Legality'Access, Name => "Ada representation legality checks stream attribute clauses");
      Add_Test (Routine => Test_Ada_Stream_Attribute_Profile_Conformance'Access, Name => "Ada representation legality checks stream attribute profile conformance");
      Add_Test (Routine => Test_Ada_Stream_Attribute_Target_Profile_Conformance'Access, Name => "Ada stream attribute target-profile conformance validates handlers");
      Add_Test (Routine => Test_Ada_Representation_Diagnostics_Stream_Profile_Conformance'Access, Name => "Ada representation diagnostics project stream profile conformance");
      Add_Test (Routine => Test_Language_Model_Legality_Interfacing_Pragma_Aspect_Completeness_Pass'Access, Name => "language model checks interfacing pragma and aspect legality completeness");
      Add_Test (Routine => Test_Language_Model_Legality_Interfacing_Attribute_Target_Pass'Access, Name => "language model checks interfacing representation attribute legality");
      Add_Test (Routine => Test_Language_Model_Legality_Interfacing_Attribute_Value_Pass'Access, Name => "language model checks interfacing representation attribute value legality");
      Add_Test (Routine => Test_Language_Model_Legality_Interfacing_Conflict_Representation_Pass'Access, Name => "language model checks interfacing representation conflict legality");
      Add_Test (Routine => Test_Language_Model_Legality_Stream_Attribute_Profile_Pass'Access, Name => "language model checks stream operational attribute profile legality");
      Add_Test (Routine => Test_Language_Model_Legality_Stream_Attribute_Profile_Completeness_Pass'Access, Name => "language model checks complete stream attribute profile conformance");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Stream_Interfacing_Legality_Tests;
