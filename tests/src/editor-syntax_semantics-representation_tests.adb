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

package body Editor.Syntax_Semantics.Representation_Tests is



   procedure Test_Language_Model_Aspect_Clauses_Do_Not_Pollute_Profiles
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aspected_Profiles with Preelaborate is" & ASCII.LF &
        "   type Count_Type is range 0 .. 10 with Size => 8;" & ASCII.LF &
        "   procedure Imported (Count : Natural) with Import, Convention => C;" & ASCII.LF &
        "   function Compute (Value : Integer) return Boolean with Inline;" & ASCII.LF &
        "end Aspected_Profiles;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "aspected_profiles.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Aspected_Profiles");
      Count_Type_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count_Type");
      Imported_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Imported");
      Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compute");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Count_Type_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Type_Id);
      Imported_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Imported_Id);
      Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compute_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Value_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aspected package declaration should parse");
      Assert (Count_Type_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aspected scalar type declaration should parse");
      Assert (Imported_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aspected procedure declaration should parse");
      Assert (Compute_Id /= Editor.Ada_Language_Model.No_Symbol,
              "aspected function declaration should parse");
      Assert (Package_Info.Flags.Has_Aspect_Specification,
              "package aspect specification should be retained as declaration metadata");
      Assert (Count_Type_Info.Flags.Has_Aspect_Specification,
              "type aspect specification should be retained as declaration metadata");
      Assert (Imported_Info.Flags.Has_Aspect_Specification,
              "procedure aspect specification should be retained as declaration metadata");
      Assert (Compute_Info.Flags.Has_Aspect_Specification,
              "function aspect specification should be retained as declaration metadata");
      Assert (To_String (Imported_Info.Profile_Summary) = "(Count : Natural)",
              "procedure profile summary should stop before aspect clause");
      Assert (To_String (Compute_Info.Profile_Summary) =
                "(Value : Integer) return Boolean",
              "function profile summary should stop before aspect clause");
      Assert (Count_Info.Parent_Symbol = Imported_Id,
              "procedure parameter should still be parented under aspected declaration");
      Assert (Value_Info.Parent_Symbol = Compute_Id,
              "function parameter should still be parented under aspected declaration");
   end Test_Language_Model_Aspect_Clauses_Do_Not_Pollute_Profiles;


   procedure Test_Language_Model_Representation_Record_Does_Not_Close_Package
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type R is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for R use record" & ASCII.LF &
        "      A at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After_Representation : Integer;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Demo_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Demo");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Representation");
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Demo_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package should be parsed before representation clause");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol,
              "declaration after representation clause should still be parsed");
      Assert (After_Info.Parent_Symbol = Demo_Id,
              "end record from representation clause must not close the enclosing package scope");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "post-representation declaration remains an object symbol");
   end Test_Language_Model_Representation_Record_Does_Not_Close_Package;



   procedure Test_Language_Model_Representation_Clauses_Are_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type R is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for R use record" & ASCII.LF &
        "      A at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Public_State : Integer;" & ASCII.LF &
        "   for Public_State'Address use System'To_Address (0);" & ASCII.LF &
        "   After_Representation : Integer;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      R_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "R");
      Public_State_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Public_State");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Representation");
      R_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, R_Id);
      Public_State_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Public_State_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (R_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Public_State_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain type, object, and post-representation object symbols");
      Assert (R_Info.Flags.Has_Representation_Clause,
              "record representation clause should be retained as type metadata");
      Assert (Public_State_Info.Flags.Has_Representation_Clause,
              "address representation clause should be retained as object metadata");
      Assert (not After_Info.Flags.Has_Representation_Clause,
              "unrelated declarations must not inherit representation metadata");
      Assert (Editor.Ada_Language_Model.Symbol_Count (Analysis) = 5,
              "representation clauses remain metadata rather than standalone symbols");
   end Test_Language_Model_Representation_Clauses_Are_Metadata;





   procedure Test_Language_Model_Split_Aspect_Clause_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Contracts is" & ASCII.LF &
           "   procedure Step (X : Natural)" & ASCII.LF &
           "     with Pre => X > 0," & ASCII.LF &
           "          Post => X > 0;" & ASCII.LF &
           "end Contracts;" & ASCII.LF);
      Step_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Step");
      Step_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Step_Id);
   begin
      Assert (Step_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split-aspect owner must be retained");
      Assert (Step_Info.Flags.Has_Aspect_Specification,
              "split aspect continuation must stamp the owning declaration");
      Assert (not Editor.Ada_Language_Model.Has_With_Clause_Awareness (Analysis),
              "split aspect introducer must not be retained as a context with clause");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Pre") =
              Editor.Ada_Language_Model.No_Symbol,
              "aspect names must not be learned as declarations");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Post") =
              Editor.Ada_Language_Model.No_Symbol,
              "aspect continuation names must not be learned as declarations");
   end Test_Language_Model_Split_Aspect_Clause_Metadata;


   procedure Test_Language_Model_Syntax_Tree_Aspects_Pragmas_Representation_And_Generic_Actuals_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   pragma Elaborate_Body (Demo);" & ASCII.LF &
        "   type Mode is (Fast, Slow)" & ASCII.LF &
        "     with Size => 8, Object_Size => 8;" & ASCII.LF &
        "   for Mode use (Fast => 1, Slow => 2);" & ASCII.LF &
        "   package Vectors is new Ada.Containers.Vectors (Index_Type => Natural, Element_Type => Mode);" & ASCII.LF &
        "end Demo;";
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

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Aspect_Specification) >= 1,
              "aspect specifications must be represented as first-class syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Aspect_Association) >= 2,
              "aspect associations must be split into structured child nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Pragma_Argument) >= 1,
              "pragma argument lists must have structured argument nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Representation_Clause) >= 1,
              "representation clauses must be first-class syntax-tree nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Representation_Target, "Mode"),
              "representation clauses must retain their target name");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Generic_Actual_Part) >= 1,
              "generic instantiations must retain their actual part node");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Generic_Actual_Association) >= 2,
              "generic actual associations must be parsed structurally");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Statement_Target, "Index_Type"),
              "named generic actual associations must retain formal names");
   end Test_Language_Model_Syntax_Tree_Aspects_Pragmas_Representation_And_Generic_Actuals_Are_Structured;



   procedure Test_Language_Model_Syntax_Tree_Record_Representation_Component_Clauses_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      A : Boolean;" & ASCII.LF &
        "      B : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      A at 0 range 0 .. 0;" & ASCII.LF &
        "      B at 0 range 1 .. 1;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Demo;";
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

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Representation_Clause) >= 1,
              "record representation clauses must remain first-class syntax-tree nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Representation_Component_Clause) = 2,
              "record representation component clauses must be parsed as structured nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Representation_Target, "A"),
              "component clauses must retain component names as representation targets");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Range_Expression, "1 .. 1"),
              "component clauses must retain bit ranges structurally");
   end Test_Language_Model_Syntax_Tree_Record_Representation_Component_Clauses_Are_Structured;



   procedure Test_Ada_Cross_Unit_Representation_Target_Resolution
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Status;
      Lib_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Lib is" & ASCII.LF &
           "   type Remote is range 0 .. 255;" & ASCII.LF &
           "end Lib;" & ASCII.LF,
           "lib.ads");
      Limited_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Lim is" & ASCII.LF &
           "   type Hidden is range 0 .. 10;" & ASCII.LF &
           "end Lim;" & ASCII.LF,
           "lim.ads");
      Client_Source : constant String :=
        "with Lib;" & ASCII.LF &
        "limited with Lim;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   for Lib.Remote'Size use 32;" & ASCII.LF &
        "   for Lim.Hidden'Size use 16;" & ASCII.LF &
        "   for Missing.Remote'Size use 8;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.ads");
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Client_Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility_Local : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility_Local);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility_Local, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Targets : Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model;
      Seen_Lib : Boolean := False;
      Seen_Limited : Boolean := False;
      Seen_Missing : Boolean := False;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/lib.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Lib_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/lim.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Limited_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Targets := Editor.Ada_Cross_Unit_Representation_Targets.Build
        ("Client", Legality, Cross_Visibility);

      for Index in 1 .. Editor.Ada_Cross_Unit_Representation_Targets.Target_Count (Targets) loop
         declare
            Info : constant Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Info :=
              Editor.Ada_Cross_Unit_Representation_Targets.Target_At (Targets, Index);
         begin
            if To_String (Info.Prefix_Name) = "Lib"
              and then Info.Status = Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Resolved
            then
               Seen_Lib := True;
            elsif To_String (Info.Prefix_Name) = "Lim"
              and then Info.Status = Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Limited_View
            then
               Seen_Limited := True;
            elsif To_String (Info.Prefix_Name) = "Missing"
              and then Info.Status = Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Missing
            then
               Seen_Missing := True;
            end if;
         end;
      end loop;

      Assert
        (Editor.Ada_Cross_Unit_Representation_Targets.Target_Count (Targets) >= 3,
         "cross-unit representation target model must stage representation clauses for cross-unit lookup");
      Assert
        (Seen_Lib and then Editor.Ada_Cross_Unit_Representation_Targets.Prefix_Resolved_Count (Targets) >= 1,
         "representation targets with visible with-clause prefixes should be classified as cross-unit resolved");
      Assert
        (Seen_Limited and then Editor.Ada_Cross_Unit_Representation_Targets.Limited_View_Count (Targets) >= 1,
         "representation targets through limited with should preserve incomplete-view status");
      Assert
        (Seen_Missing and then Editor.Ada_Cross_Unit_Representation_Targets.Missing_Count (Targets) >= 1,
         "missing cross-unit representation target prefixes should remain explicit");
      Assert
        (Editor.Ada_Cross_Unit_Representation_Targets.Fingerprint (Targets) /= 0,
         "cross-unit representation target resolution should be fingerprinted deterministically");
   end Test_Ada_Cross_Unit_Representation_Target_Resolution;




   procedure Test_Ada_Record_Layout_Overlap_Size_Alignment
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Record_Layout_Validation.Record_Layout_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Layout_Overlap is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      Lo : Integer;" & ASCII.LF &
        "      Hi : Integer;" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      Lo at 0 range 0 .. 31;" & ASCII.LF &
        "      Hi at 2 range 0 .. 31;" & ASCII.LF &
        "      Flag at 8 range 0 .. 0;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      Lo at 0 range 31 .. 0;" & ASCII.LF &
        "      Missing at 4 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Record_Layout_Overlap;";
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
      Saw_Overlap : Boolean := False;
   begin
      Assert (Editor.Ada_Record_Layout_Validation.Check_Count (Layout) >= 5,
              "record layout validation must stage every component-clause layout span");

      for Index in 1 .. Editor.Ada_Record_Layout_Validation.Check_Count (Layout) loop
         declare
            Info : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Info :=
              Editor.Ada_Record_Layout_Validation.Check_At (Layout, Index);
         begin
            if Info.Status = Editor.Ada_Record_Layout_Validation.Record_Layout_Overlap then
               Saw_Overlap := True;
            end if;
         end;
      end loop;

      Assert (Saw_Overlap,
              "record layout validation must detect overlapping bit spans in one record representation clause");
      Assert (Editor.Ada_Record_Layout_Validation.Valid_Span_Count (Layout) >= 2,
              "record layout validation must retain valid non-overlapping spans");
      Assert (Editor.Ada_Record_Layout_Validation.Static_Error_Count (Layout) >= 1,
              "record layout validation must preserve static layout errors from component legality");
      Assert (Editor.Ada_Record_Layout_Validation.Component_Error_Count (Layout) >= 1,
              "record layout validation must preserve unresolved component errors from component legality");
      Assert (Editor.Ada_Record_Layout_Validation.Overlap_Count (Layout) >= 1,
              "record layout validation must expose deterministic overlap counters");
      Assert (Editor.Ada_Record_Layout_Validation.Fingerprint (Layout) /= 0,
              "record layout validation must retain deterministic fingerprints");
   end Test_Ada_Record_Layout_Overlap_Size_Alignment;




   procedure Test_Ada_Record_Layout_Exact_Size_Alignment
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Layout_Exact is" & ASCII.LF &
        "   type Tight is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Tight use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 1 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Tight'Size use 16;" & ASCII.LF &
        "   for Tight'Alignment use 4;" & ASCII.LF &
        "   type Too_Small is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Too_Small use record" & ASCII.LF &
        "      A at 0 range 0 .. 15;" & ASCII.LF &
        "      B at 2 range 0 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Too_Small'Size use 24;" & ASCII.LF &
        "   for Too_Small'Alignment use 3;" & ASCII.LF &
        "   type Padded is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Padded use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Padded'Size use 32;" & ASCII.LF &
        "end Record_Layout_Exact;";
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
      Exact : constant Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model :=
        Editor.Ada_Record_Layout_Exact_Validation.Build (Legality, Layout);
      Saw_Exact : Boolean := False;
      Saw_Exceeded : Boolean := False;
      Saw_Padded : Boolean := False;
      Saw_Bad_Alignment : Boolean := False;
   begin
      Assert (Editor.Ada_Record_Layout_Exact_Validation.Check_Count (Exact) >= 6,
              "exact record layout validation must stage target summaries and representation-clause checks");

      for Index in 1 .. Editor.Ada_Record_Layout_Exact_Validation.Check_Count (Exact) loop
         declare
            Info : constant Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Info :=
              Editor.Ada_Record_Layout_Exact_Validation.Check_At (Exact, Index);
         begin
            if Info.Status = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Exact then
               Saw_Exact := True;
            elsif Info.Status = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Exceeded then
               Saw_Exceeded := True;
            elsif Info.Status = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Padded then
               Saw_Padded := True;
            elsif Info.Status = Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Not_Power_Of_Two then
               Saw_Bad_Alignment := True;
            end if;
         end;
      end loop;

      Assert (Saw_Exact,
              "exact record layout validation must classify exact Size clauses");
      Assert (Saw_Exceeded,
              "exact record layout validation must reject Size clauses smaller than the occupied bit span");
      Assert (Saw_Padded,
              "exact record layout validation must distinguish padded Size clauses from exact clauses");
      Assert (Saw_Bad_Alignment,
              "exact record layout validation must reject non-power-of-two Alignment clauses");
      Assert (Editor.Ada_Record_Layout_Exact_Validation.Size_Exact_Count (Exact) >= 1,
              "exact record layout validation must count exact Size clauses");
      Assert (Editor.Ada_Record_Layout_Exact_Validation.Size_Exceeded_Count (Exact) >= 1,
              "exact record layout validation must count exceeded Size clauses");
      Assert (Editor.Ada_Record_Layout_Exact_Validation.Alignment_Error_Count (Exact) >= 1,
              "exact record layout validation must count exact alignment errors");
      Assert (Editor.Ada_Record_Layout_Exact_Validation.Fingerprint (Exact) /= 0,
              "exact record layout validation must retain deterministic fingerprints");
   end Test_Ada_Record_Layout_Exact_Size_Alignment;



   procedure Test_Ada_Representation_Diagnostics_Exact_Record_Layout
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Layout_Exact_Diagnostics is" & ASCII.LF &
        "   type Too_Small is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Too_Small use record" & ASCII.LF &
        "      A at 0 range 0 .. 15;" & ASCII.LF &
        "      B at 2 range 0 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Too_Small'Size use 24;" & ASCII.LF &
        "   for Too_Small'Alignment use 3;" & ASCII.LF &
        "   type Padded is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Padded use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Padded'Size use 32;" & ASCII.LF &
        "end Record_Layout_Exact_Diagnostics;";
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
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generics : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing_Points);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Exact : constant Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model :=
        Editor.Ada_Record_Layout_Exact_Validation.Build (Legality, Layout);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Freezing : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing_Points, Types, Private_Views, Generics);
      Diagnostics : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build_With_Exact_Layout
          (Legality, Layout, Storage, Operational, Inheritance, Freezing, Exact);
      Saw_Size : Boolean := False;
      Saw_Alignment : Boolean := False;
      Saw_Padded : Boolean := False;
   begin
      Assert (Editor.Ada_Representation_Diagnostics.Exact_Record_Layout_Diagnostic_Count (Diagnostics) >= 3,
              "representation diagnostics must project exact record-layout results");

      for Index in 1 .. Editor.Ada_Representation_Diagnostics.Diagnostic_Count (Diagnostics) loop
         declare
            Info : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Info :=
              Editor.Ada_Representation_Diagnostics.Diagnostic_At (Diagnostics, Index);
         begin
            if Info.Kind = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Record_Layout_Size_Exceeded then
               Saw_Size := True;
            elsif Info.Kind = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Record_Layout_Alignment_Error then
               Saw_Alignment := True;
            elsif Info.Kind = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Record_Layout_Size_Padded then
               Saw_Padded := True;
            end if;
         end;
      end loop;

      Assert (Saw_Size,
              "representation diagnostics must flag Size clauses smaller than occupied bits");
      Assert (Saw_Alignment,
              "representation diagnostics must flag exact Alignment clause errors");
      Assert (Saw_Padded,
              "representation diagnostics must preserve padded Size clauses as informational diagnostics");
      Assert (Editor.Ada_Representation_Diagnostics.Exact_Record_Layout_Size_Error_Count (Diagnostics) >= 1,
              "representation diagnostics must count exact record Size errors");
      Assert (Editor.Ada_Representation_Diagnostics.Exact_Record_Layout_Alignment_Error_Count (Diagnostics) >= 1,
              "representation diagnostics must count exact record Alignment errors");
      Assert (Editor.Ada_Representation_Diagnostics.Fingerprint (Diagnostics) /= 0,
              "representation diagnostics with exact record layout must retain deterministic fingerprints");
   end Test_Ada_Representation_Diagnostics_Exact_Record_Layout;





   procedure Test_Ada_Representation_Diagnostics_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Severity;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Representation_Diagnostics_Checks is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word'Bit_Order use Low_Order_First;" & ASCII.LF &
        "   for Word'Scalar_Storage_Order use High_Order_First;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word'Atomic use True;" & ASCII.LF &
        "   for Word'Atomic use False;" & ASCII.LF &
        "   type Root is range 0 .. 255;" & ASCII.LF &
        "   for Root'Volatile use True;" & ASCII.LF &
        "   type Child is new Root;" & ASCII.LF &
        "   for Child'Volatile use False;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "   package G is" & ASCII.LF &
        "   end G;" & ASCII.LF &
        "   package I is new G;" & ASCII.LF &
        "end Representation_Diagnostics_Checks;";
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
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Generics : constant Editor.Ada_Generic_Contracts.Generic_Contract_Model :=
        Editor.Ada_Generic_Contracts.Build_With_Type_Graph
          (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Interactions : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model :=
        Editor.Ada_Freezing_Interactions.Build
          (Tree, Regions, Freezing, Types, Private_Views, Generics);
      Diags : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model :=
        Editor.Ada_Representation_Diagnostics.Build
          (Legality, Layout, Storage, Operational, Inheritance, Interactions);
      First : constant Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Info :=
        Editor.Ada_Representation_Diagnostics.Diagnostic_At (Diags, 1);
   begin
      Assert
        (Editor.Ada_Representation_Diagnostics.Has_Diagnostics (Diags)
         and then Editor.Ada_Representation_Diagnostics.Error_Count (Diags) >= 1,
         "representation diagnostics must project legality, layout, and freezing errors into diagnostics");
      Assert
        (Editor.Ada_Representation_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Record_Layout_Overlap) >= 1,
         "representation diagnostics must expose record-layout overlap errors");
      Assert
        (Editor.Ada_Representation_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Storage_Order_Conflict) >= 1,
         "representation diagnostics must expose Bit_Order and Scalar_Storage_Order conflicts");
      Assert
        (Editor.Ada_Representation_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Operational_Conflict) >= 1,
         "representation diagnostics must expose operational property conflicts");
      Assert
        (Editor.Ada_Representation_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Aspect_Inheritance_Conflict) >= 1,
         "representation diagnostics must expose inherited aspect override conflicts");
      Assert
        (First.Severity = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Error
         or else First.Severity = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Warning
         or else First.Severity = Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Severity_Info,
         "representation diagnostics must retain severity metadata");
      Assert
        (Editor.Ada_Representation_Diagnostics.Fingerprint (Diags) /= 0,
         "representation diagnostics must retain deterministic fingerprints");
   end Test_Ada_Representation_Diagnostics_Projection;



   procedure Test_Language_Model_Record_Representation_Layout_Is_Interpreted
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      A : Boolean;" & ASCII.LF &
        "      B : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      A at 0 range 0 .. 0;" & ASCII.LF &
        "      B at 0 range 1 .. 1;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Packed_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Packed");
      A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "A");
      First_Component : Editor.Ada_Language_Model.Representation_Component_Info;
      Second_Component : Editor.Ada_Language_Model.Representation_Component_Info;
   begin
      Assert (Packed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be retained for representation-layout metadata");
      Assert (Editor.Ada_Language_Model.Representation_Component_Count
                (Analysis, Packed_Id) = 2,
              "record representation component clauses should be interpreted into bounded layout entries");

      First_Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 1);
      Second_Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 2);

      Assert (To_String (First_Component.Component_Name) = "A",
              "first layout entry should retain the component name");
      Assert (First_Component.Component_Symbol = A_Id,
              "layout entry should link back to the record-component symbol when resolvable");
      Assert (First_Component.Has_Static_Storage_Unit
              and then First_Component.Static_Storage_Unit = 0,
              "simple decimal storage-unit positions should be parsed");
      Assert (First_Component.Has_Static_First_Bit
              and then First_Component.Static_First_Bit = 0,
              "simple decimal first-bit positions should be parsed");
      Assert (First_Component.Has_Static_Last_Bit
              and then First_Component.Static_Last_Bit = 0,
              "simple decimal last-bit positions should be parsed");
      Assert (To_String (Second_Component.Component_Name) = "B"
              and then Second_Component.Has_Static_First_Bit
              and then Second_Component.Static_First_Bit = 1
              and then Second_Component.Has_Static_Last_Bit
              and then Second_Component.Static_Last_Bit = 1,
              "subsequent component clauses should retain their parsed bit ranges");
   end Test_Language_Model_Record_Representation_Layout_Is_Interpreted;





   procedure Test_Language_Model_Representation_Clauses_Beyond_Record_Layout
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 16#10#, Blue => 2#1_000#);" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index'Size use 16#20#;" & ASCII.LF &
        "   for Index'Alignment use 4;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Colour_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Colour");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Enum_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Size_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Align_Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Green_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
   begin
      Assert (Colour_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for enum representation metadata");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "integer type should be retained for attribute representation metadata");
      Assert (Editor.Ada_Language_Model.Representation_Clause_Count
                (Analysis, Colour_Id) = 1,
              "enumeration representation clause should be retained as interpreted metadata");
      Assert (Editor.Ada_Language_Model.Enumeration_Representation_Literal_Count
                (Analysis, Colour_Id) = 3,
              "enumeration representation associations should be interpreted as literal values");
      Assert (Editor.Ada_Language_Model.Representation_Clause_Count
                (Analysis, Index_Id) = 2,
              "size and alignment clauses should be retained as target-owned metadata");

      Enum_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Colour_Id, 1);
      Size_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 1);
      Align_Clause :=
        Editor.Ada_Language_Model.Representation_Clause_At
          (Analysis, Index_Id, 2);
      Green_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, Colour_Id, 2);

      Assert (Enum_Clause.Kind = Editor.Ada_Language_Model.Representation_Enumeration_Clause,
              "enum aggregate representation should be classified explicitly");
      Assert (Size_Clause.Kind = Editor.Ada_Language_Model.Representation_Size_Clause
              and then To_String (Size_Clause.Attribute_Name) = "Size"
              and then Size_Clause.Has_Static_Value
              and then Size_Clause.Static_Value = 32,
              "size clauses should retain attribute names and parsed static values");
      Assert (Align_Clause.Kind = Editor.Ada_Language_Model.Representation_Alignment_Clause
              and then Align_Clause.Has_Static_Value
              and then Align_Clause.Static_Value = 4,
              "alignment clauses should retain parsed static values");
      Assert (To_String (Green_Literal.Literal_Name) = "Green"
              and then Green_Literal.Has_Static_Value
              and then Green_Literal.Static_Value = 16,
              "based enum representation literal values should be parsed");
   end Test_Language_Model_Representation_Clauses_Beyond_Record_Layout;



   procedure Test_Language_Model_Enumeration_Representation_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type State is (Idle, Busy, Done);" & ASCII.LF &
        "   for State use (0, 4, 8);" & ASCII.LF &
        "   type Bad_Order is (Low, High);" & ASCII.LF &
        "   for Bad_Order use (Low => 2, High => 1);" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index use (Zero => 0);" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      State_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "State");
      Idle_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Busy_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Done_Literal : Editor.Ada_Language_Model.Enumeration_Representation_Literal_Info;
      Seen_Order_Mismatch : Boolean := False;
      Seen_Non_Enum_Target : Boolean := False;
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   begin
      Assert (State_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for positional representation coverage");
      Assert (Editor.Ada_Language_Model.Enumeration_Representation_Literal_Count
                (Analysis, State_Id) = 3,
              "positional enumeration representation aggregates should retain one value per literal");

      Idle_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, State_Id, 1);
      Busy_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, State_Id, 2);
      Done_Literal :=
        Editor.Ada_Language_Model.Enumeration_Representation_Literal_At
          (Analysis, State_Id, 3);

      Assert (To_String (Idle_Literal.Literal_Name) = "Idle"
              and then Idle_Literal.Has_Static_Value
              and then Idle_Literal.Static_Value = 0,
              "first positional enum representation value should map to first literal");
      Assert (To_String (Busy_Literal.Literal_Name) = "Busy"
              and then Busy_Literal.Has_Static_Value
              and then Busy_Literal.Static_Value = 4,
              "second positional enum representation value should map to second literal");
      Assert (To_String (Done_Literal.Literal_Name) = "Done"
              and then Done_Literal.Has_Static_Value
              and then Done_Literal.Static_Value = 8,
              "third positional enum representation value should map to third literal");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Enumeration_Representation_Order_Mismatch =>
                  Seen_Order_Mismatch := True;
               when Editor.Ada_Language_Model.Legality_Enumeration_Representation_Target_Not_Enumeration =>
                  Seen_Non_Enum_Target := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Order_Mismatch,
              "enum representation values should preserve declaration order");
      Assert (Seen_Non_Enum_Target,
              "enum representation clauses should require enumeration targets");
   end Test_Language_Model_Enumeration_Representation_Completeness;


   procedure Test_Language_Model_Representation_Based_Exponent_Expressions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 2#10#E3, Green => 16#2#E2, Blue => 2E3);" & ASCII.LF &
        "   type Index is range 0 .. 10;" & ASCII.LF &
        "   for Index'Size use 16#1#E2;" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      Flag at 2#11#E2 range 0 .. 16#1#E1 - 1;" & ASCII.LF &
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
      Component : Editor.Ada_Language_Model.Representation_Component_Info;
   begin
      Assert (Colour_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be retained for based-exponent representation metadata");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "scalar type should be retained for based-exponent attribute metadata");
      Assert (Packed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be retained for based-exponent component metadata");

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
      Component :=
        Editor.Ada_Language_Model.Representation_Component_At
          (Analysis, Packed_Id, 1);

      Assert (Red_Literal.Has_Static_Value
              and then Red_Literal.Static_Value = 16,
              "based literal exponents should scale by the literal base, not decimal ten");
      Assert (Green_Literal.Has_Static_Value
              and then Green_Literal.Static_Value = 512,
              "hex based literal exponents should use base sixteen scaling");
      Assert (Blue_Literal.Has_Static_Value
              and then Blue_Literal.Static_Value = 2000,
              "ordinary decimal literal exponents should still use decimal scaling");
      Assert (Size_Clause.Has_Static_Value
              and then Size_Clause.Static_Value = 256,
              "attribute representation based exponents should be evaluated");
      Assert (Component.Has_Static_Storage_Unit
              and then Component.Static_Storage_Unit = 12,
              "record component storage-unit based exponents should be evaluated");
      Assert (Component.Has_Static_Last_Bit
              and then Component.Static_Last_Bit = 15,
              "record component bit-range based exponents should be evaluated in expressions");
   end Test_Language_Model_Representation_Based_Exponent_Expressions;





   procedure Test_Ada_Selected_Representation_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Status;
      use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Id;
      Lib_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Lib is" & ASCII.LF &
           "   type Remote is range 0 .. 255;" & ASCII.LF &
           "end Lib;" & ASCII.LF,
           "lib.ads");
      Client_Source : constant String :=
        "with Lib;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   for Lib.Remote'Size use 32;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.ads");
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Client_Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility_Local : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility_Local);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility_Local);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility_Local, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Cross_Targets : Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Model : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
      Info : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/lib.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Lib_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Cross_Lookup := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Cross_Visibility, Source_Unit_Name => "Client");
      Cross_Targets := Editor.Ada_Cross_Unit_Representation_Targets.Build
        ("Client", Legality, Cross_Visibility);
      Selected := Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
        (Tree, Regions, Visibility_Local, Uses, Cross_Lookup);
      Model := Editor.Ada_Selected_Representation_Targets.Build
        (Cross_Targets, Selected);
      Info := Editor.Ada_Selected_Representation_Targets.First_For_Target
        (Model, "Lib.Remote");

      Assert
        (Editor.Ada_Selected_Representation_Targets.Target_Count (Model) >= 1,
         "selected representation targets must consume cross-unit representation target metadata");
      Assert
        (Info.Status = Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Cross_Unit_Selected_Resolved
         or else Info.Status = Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Local_Selected_Resolved,
         "selected-name representation targets must resolve visible selected targets deterministically");
      Assert
        (Editor.Ada_Selected_Representation_Targets.Resolved_Count (Model) >= 1
         and then Info.Selected_Name /= Editor.Ada_Selected_Name_Resolution.No_Selected_Name,
         "selected representation target model must preserve selected-name identity for resolved targets");
      Assert
        (Length (Info.Prefix_Name) > 0
         and then Length (Info.Selector_Name) > 0
         and then Info.Fingerprint /= 0
         and then Editor.Ada_Selected_Representation_Targets.Fingerprint (Model) /= 0,
         "selected representation targets must preserve selected target text and deterministic fingerprints");
   end Test_Ada_Selected_Representation_Targets;



   procedure Test_Ada_Representation_Diagnostics_Selected_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Kind;
      Lib_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Lib is" & ASCII.LF &
           "   type Remote is range 0 .. 255;" & ASCII.LF &
           "end Lib;" & ASCII.LF,
           "lib.ads");
      Client_Source : constant String :=
        "with Lib;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   for Lib.Missing'Size use 32;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, "client.ads");
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Client_Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility_Local : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility_Local);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility_Local);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility_Local, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Layout : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Model :=
        Editor.Ada_Record_Layout_Validation.Build (Legality);
      Storage : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model :=
        Editor.Ada_Record_Storage_Order_Rules.Build (Legality, Layout);
      Operational : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model :=
        Editor.Ada_Operational_Attribute_Rules.Build (Legality);
      Inheritance : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model :=
        Editor.Ada_Aspect_Inheritance_Rules.Build (Legality, Types);
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Cross_Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Cross_Lookup : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Cross_Targets : Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model;
      Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
      Diags : Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Model;
      First : Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/lib.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Lib_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Cross_Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Cross_Lookup := Editor.Ada_Cross_Unit_Lookup_Integration.Build
        (Cross_Visibility, Source_Unit_Name => "Client");
      Cross_Targets := Editor.Ada_Cross_Unit_Representation_Targets.Build
        ("Client", Legality, Cross_Visibility);
      Selected := Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit
        (Tree, Regions, Visibility_Local, Uses, Cross_Lookup);
      Selected_Targets := Editor.Ada_Selected_Representation_Targets.Build
        (Cross_Targets, Selected);
      Diags := Editor.Ada_Representation_Diagnostics.Build_With_Selected_Targets
        (Legality, Layout, Storage, Operational, Inheritance, Freezing, Selected_Targets);
      First := Editor.Ada_Representation_Diagnostics.Diagnostic_At (Diags, 1);

      Assert
        (Editor.Ada_Representation_Diagnostics.Selected_Target_Diagnostic_Count (Diags) >= 1,
         "representation diagnostics must project selected-name target resolution failures");
      Assert
        (Editor.Ada_Representation_Diagnostics.Selected_Target_Selector_Error_Count (Diags) >= 1
         or else Editor.Ada_Representation_Diagnostics.Count_Kind
           (Diags, Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Selected_Target_Selector_Missing) >= 1,
         "representation diagnostics must expose selected-name selector failures");
      Assert
        (First.Kind /= Editor.Ada_Representation_Diagnostics.Representation_Diagnostic_Unknown
         and then Length (First.Target_Name) > 0
         and then Length (First.Message) > 0
         and then First.Fingerprint /= 0,
         "selected representation diagnostics must preserve target text, message, and fingerprint");
      Assert
        (Editor.Ada_Representation_Diagnostics.Fingerprint (Diags) /= 0,
         "selected representation diagnostics must contribute to deterministic representation fingerprints");
   end Test_Ada_Representation_Diagnostics_Selected_Targets;


   overriding function Name (T : Representation_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Representation");
   end Name;

   overriding procedure Register_Tests (T : in out Representation_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Aspect_Clauses_Do_Not_Pollute_Profiles'Access, Name => "language model parser keeps aspect clauses out of profile summaries");
      Add_Test (Routine => Test_Language_Model_Representation_Record_Does_Not_Close_Package'Access, Name => "language model parser skips representation end record without closing package scope");
      Add_Test (Routine => Test_Language_Model_Representation_Clauses_Are_Metadata'Access, Name => "language model parser retains representation clauses as declaration metadata");
      Add_Test (Routine => Test_Language_Model_Split_Aspect_Clause_Metadata'Access, Name => "language model retains split aspect clause metadata");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Aspects_Pragmas_Representation_And_Generic_Actuals_Are_Structured'Access, Name => "syntax tree parses aspects pragmas representation clauses and generic actuals structurally");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Record_Representation_Component_Clauses_Are_Structured'Access, Name => "syntax tree parses record representation component clauses structurally");
      Add_Test (Routine => Test_Ada_Cross_Unit_Representation_Target_Resolution'Access, Name => "Ada cross-unit representation targets resolve through with visibility metadata");
      Add_Test (Routine => Test_Ada_Record_Layout_Overlap_Size_Alignment'Access, Name => "Ada record layout validation detects component overlap and staged layout errors");
      Add_Test (Routine => Test_Ada_Record_Layout_Exact_Size_Alignment'Access, Name => "Ada exact record layout validation checks Size and Alignment clauses");
      Add_Test (Routine => Test_Ada_Representation_Diagnostics_Exact_Record_Layout'Access, Name => "Ada representation diagnostics project exact record layout checks");
      Add_Test (Routine => Test_Ada_Representation_Diagnostics_Projection'Access, Name => "Ada representation diagnostics project legality layout freezing and aspect metadata into stable diagnostics");
      Add_Test (Routine => Test_Language_Model_Record_Representation_Layout_Is_Interpreted'Access, Name => "language model interprets record representation component layout metadata");
      Add_Test (Routine => Test_Language_Model_Representation_Clauses_Beyond_Record_Layout'Access, Name => "language model interprets non-record representation clause metadata");
      Add_Test (Routine => Test_Language_Model_Enumeration_Representation_Completeness'Access, Name => "language model completes enumeration representation clause coverage");
      Add_Test (Routine => Test_Language_Model_Representation_Based_Exponent_Expressions'Access, Name => "language model evaluates based literal exponent representation expressions");
      Add_Test (Routine => Test_Ada_Selected_Representation_Targets'Access, Name => "Ada selected representation targets resolve selected names across visible units");
      Add_Test (Routine => Test_Ada_Representation_Diagnostics_Selected_Targets'Access, Name => "Ada representation diagnostics project selected target resolution failures");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Tests;
