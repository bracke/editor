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

package body Editor.Syntax_Semantics.Representation_Unification_Tests is




   procedure Test_Ada_Representation_Aspect_Unification
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      use type Editor.Ada_Language_Model.Representation_Source_Form;
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aspect_Unification is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record with Pack, Bit_Order => High_Order_First;" & ASCII.LF &
        "   type Arr is array (1 .. 4) of Integer with Atomic_Components;" & ASCII.LF &
        "   Flag : Integer with Atomic;" & ASCII.LF &
        "   for Rec'Scalar_Storage_Order use Low_Order_First;" & ASCII.LF &
        "   for Flag'Volatile use True;" & ASCII.LF &
        "end Aspect_Unification;";
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
      Seen_Aspect_Pack : Boolean := False;
      Seen_Aspect_Components : Boolean := False;
      Seen_Aspect_Atomic : Boolean := False;
      Seen_Clause_Volatile : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Aspect
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Pack_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Aspect_Pack := True;
            elsif Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Aspect
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Atomic_Components_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Aspect_Components := True;
            elsif Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Aspect
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Atomic_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Aspect_Atomic := True;
            elsif Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Attribute_Definition
              and then Info.Clause_Kind = Editor.Ada_Language_Model.Representation_Volatile_Clause
              and then Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
            then
               Seen_Clause_Volatile := True;
            end if;
         end;
      end loop;

      Assert (Seen_Aspect_Pack,
              "aspect unification must classify Pack aspects through representation legality");
      Assert (Seen_Aspect_Components,
              "aspect unification must classify component aspects through representation legality");
      Assert (Seen_Aspect_Atomic,
              "aspect unification must classify object aspects through representation legality");
      Assert (Seen_Clause_Volatile,
              "attribute-definition clauses must remain in the unified representation model");
      Assert (Editor.Ada_Representation_Legality.Aspect_Source_Count (Legality) >= 3,
              "aspect unification must count aspect-sourced representation properties");
      Assert (Editor.Ada_Representation_Legality.Attribute_Definition_Source_Count (Legality) >= 2,
              "aspect unification must count attribute-definition representation properties");
      Assert (Editor.Ada_Representation_Legality.Unified_Property_Count (Legality) =
                Editor.Ada_Representation_Legality.Aspect_Source_Count (Legality) +
                Editor.Ada_Representation_Legality.Attribute_Definition_Source_Count (Legality),
              "unified property count must be source-stable and deterministic");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "aspect unification must contribute to deterministic fingerprints");
   end Test_Ada_Representation_Aspect_Unification;





   procedure Test_Language_Model_Aspect_Attribute_Definition_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ada.Streams;" & ASCII.LF &
        "package P is" & ASCII.LF &
        "   X : Integer with Alignment => 0;" & ASCII.LF &
        "   for X'Alignment use 4;" & ASCII.LF &
        "   type Plain is null record with Component_Size => 8, Pack;" & ASCII.LF &
        "   type T is range 0 .. 10 with Read => Missing_Read;" & ASCII.LF &
        "   Y : Integer with Link_Name => Dynamic_Link;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      X_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "X");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      T_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "T");
      Seen_Aspect_Alignment : Boolean := False;
      Seen_Clause_Alignment : Boolean := False;
      Seen_Component_Size : Boolean := False;
      Seen_Pack : Boolean := False;
      Seen_Stream_Read : Boolean := False;
      Seen_Duplicate : Boolean := False;
      Seen_Positive : Boolean := False;
      Seen_Component_Target : Boolean := False;
      Seen_Stream_Handler : Boolean := False;
      Seen_Link_String : Boolean := False;
      Seen_Link_Requires_Import : Boolean := False;
   begin
      Assert (X_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object with representation aspect should be retained");
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol,
              "type with representation aspects should be retained");
      Assert (T_Id /= Editor.Ada_Language_Model.No_Symbol,
              "type with stream aspect should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = X_Id
              and then A = "Alignment"
              and then To_String (Info.Item_Text) = "0"
            then
               Seen_Aspect_Alignment := True;
            elsif Info.Target_Symbol = X_Id
              and then A = "Alignment"
              and then To_String (Info.Item_Text) = "4"
            then
               Seen_Clause_Alignment := True;
            elsif Info.Target_Symbol = Plain_Id and then A = "Component_Size" then
               Seen_Component_Size := True;
            elsif Info.Target_Symbol = Plain_Id and then A = "Pack" then
               Seen_Pack := True;
            elsif Info.Target_Symbol = T_Id and then A = "Read" then
               Seen_Stream_Read := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause =>
                  Seen_Duplicate := True;
               when Editor.Ada_Language_Model.Legality_Representation_Positive_Value_Required =>
                  Seen_Positive := True;
               when Editor.Ada_Language_Model.Legality_Component_Size_Target_Not_Array =>
                  Seen_Component_Target := True;
               when Editor.Ada_Language_Model.Legality_Operational_Attribute_Handler_Not_Found =>
                  Seen_Stream_Handler := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_String_Value_Required =>
                  Seen_Link_String := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_Link_Name_Requires_Import_Export =>
                  Seen_Link_Requires_Import := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Aspect_Alignment,
              "Alignment aspect should lower into representation metadata");
      Assert (Seen_Clause_Alignment,
              "attribute-definition clause should share the same representation metadata");
      Assert (Seen_Component_Size,
              "Component_Size aspect should lower into the representation legality path");
      Assert (Seen_Pack,
              "boolean representation aspect without explicit value should default to True");
      Assert (Seen_Stream_Read,
              "stream operational aspect should lower into operational attribute metadata");
      Assert (Seen_Duplicate,
              "aspect and attribute-definition forms should share duplicate detection");
      Assert (Seen_Positive,
              "representation aspect values should use attribute-definition value legality");
      Assert (Seen_Component_Target,
              "representation aspect targets should use attribute-definition target legality");
      Assert (Seen_Stream_Handler,
              "stream aspects should use operational attribute handler legality");
      Assert (Seen_Link_String,
              "interfacing aspects should still use common string-value legality");
      Assert (Seen_Link_Requires_Import,
              "Link_Name aspect should use common import/export coupling legality");
   end Test_Language_Model_Aspect_Attribute_Definition_Unification_Pass;






   procedure Test_Language_Model_Representation_Operational_Property_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Display is tagged null record with Stream_Size => 8, External_Tag => ""display-v1"", Put_Image => Put_Display_Image, Read => Read_Display;" & ASCII.LF &
        "   for Display'Stream_Size use 0;" & ASCII.LF &
        "   for Display'External_Tag use Not_A_String;" & ASCII.LF &
        "   for Display'Read use Missing_Read;" & ASCII.LF &
        "   procedure Read_Display (S : access Ada.Streams.Root_Stream_Type'Class; V : out Display);" & ASCII.LF &
        "   procedure Put_Display_Image (S : in out Integer; V : Display);" & ASCII.LF &
        "   type Broken is range 0 .. 10 with Put_Image => Missing_Image;" & ASCII.LF &
        "   type Count is range 0 .. 10 with Default_Value => 1;" & ASCII.LF &
        "   for Count'Default_Value use 2;" & ASCII.LF &
        "   type Pixels is array (Positive range <>) of Integer with Default_Component_Value => 0;" & ASCII.LF &
        "   for Pixels'Default_Component_Value use 1;" & ASCII.LF &
        "   for Display'Default_Component_Value use 1;" & ASCII.LF &
        "   type Bag is tagged null record with Constant_Indexing => Element, Variable_Indexing => Ref, Implicit_Dereference => Data, Default_Iterator => Iterate, Iterator_Element => Item, Max_Entry_Queue_Length => 1;" & ASCII.LF &
        "   for Bag'Constant_Indexing use Element;" & ASCII.LF &
        "   for Bag'Max_Entry_Queue_Length use 0;" & ASCII.LF &
        "   type Controlled_Free is tagged null record with No_Controlled_Parts;" & ASCII.LF &
        "   for Controlled_Free'No_Controlled_Parts use False;" & ASCII.LF &
        "   type Preelab is null record with Preelaborable_Initialization;" & ASCII.LF &
        "   for Preelab'Preelaborable_Initialization use Maybe;" & ASCII.LF &
        "   type Names is (Red, Blue) with Discard_Names;" & ASCII.LF &
        "   for Names'Discard_Names use False;" & ASCII.LF &
        "   function Volatile_Read return Integer with Volatile_Function;" & ASCII.LF &
        "   for Volatile_Read'Volatile_Function use False;" & ASCII.LF &
        "   Flag : Integer with Async_Readers, Async_Writers => False, Effective_Reads => True, Effective_Writes => Maybe;" & ASCII.LF &
        "   for Flag'Async_Readers use False;" & ASCII.LF &
        "   Some_Interrupt : Integer;" & ASCII.LF &
        "   Other_Interrupt : Integer;" & ASCII.LF &
        "   procedure ISR with Interrupt_Handler;" & ASCII.LF &
        "   for ISR'Interrupt_Handler use False;" & ASCII.LF &
        "   procedure Hook with Attach_Handler => Some_Interrupt;" & ASCII.LF &
        "   for Hook'Attach_Handler use Other_Interrupt;" & ASCII.LF &
        "   Runtime_Domain : Integer;" & ASCII.LF &
        "   task type Worker with Priority => 5, CPU => 1, Dispatching_Domain => Runtime_Domain is" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   for Worker'Priority use 0;" & ASCII.LF &
        "   for Worker'CPU use 0;" & ASCII.LF &
        "   protected type Gate with Interrupt_Priority => 7 is" & ASCII.LF &
        "      procedure Touch;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   for Gate'Interrupt_Priority use 6;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Display_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Display");
      Broken_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Broken");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Pixels_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Pixels");
      Bag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bag");
      Controlled_Free_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Controlled_Free");
      Preelab_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Preelab");
      Names_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Names");
      Volatile_Read_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Volatile_Read");
      Flag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Flag");
      ISR_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "ISR");
      Hook_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hook");
      G_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "G");
      H_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "H");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Gate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Gate");
      Seen_Stream_Size_Aspect : Boolean := False;
      Seen_Stream_Size_Clause : Boolean := False;
      Seen_External_Tag_Aspect : Boolean := False;
      Seen_External_Tag_Clause : Boolean := False;
      Seen_Put_Image_Aspect : Boolean := False;
      Seen_Read_Aspect : Boolean := False;
      Seen_Read_Clause : Boolean := False;
      Seen_Read_Kind : Boolean := False;
      Seen_Duplicate : Boolean := False;
      Seen_Stream_Size_Positive : Boolean := False;
      Seen_External_Tag_String : Boolean := False;
      Seen_Put_Image_Handler : Boolean := False;
      Seen_Default_Value_Aspect : Boolean := False;
      Seen_Default_Value_Clause : Boolean := False;
      Seen_Default_Component_Value_Aspect : Boolean := False;
      Seen_Default_Component_Value_Clause : Boolean := False;
      Seen_Default_Component_Target : Boolean := False;
      Seen_Constant_Indexing_Aspect : Boolean := False;
      Seen_Constant_Indexing_Clause : Boolean := False;
      Seen_Variable_Indexing_Aspect : Boolean := False;
      Seen_Implicit_Dereference_Aspect : Boolean := False;
      Seen_Default_Iterator_Aspect : Boolean := False;
      Seen_Iterator_Element_Aspect : Boolean := False;
      Seen_Max_Entry_Queue_Length_Aspect : Boolean := False;
      Seen_Max_Entry_Queue_Length_Clause : Boolean := False;
      Seen_No_Controlled_Parts_Aspect : Boolean := False;
      Seen_No_Controlled_Parts_Clause : Boolean := False;
      Seen_Preelaborable_Initialization_Aspect : Boolean := False;
      Seen_Preelaborable_Initialization_Clause : Boolean := False;
      Seen_Discard_Names_Aspect : Boolean := False;
      Seen_Discard_Names_Clause : Boolean := False;
      Seen_Volatile_Function_Aspect : Boolean := False;
      Seen_Volatile_Function_Clause : Boolean := False;
      Seen_Async_Readers_Aspect : Boolean := False;
      Seen_Async_Readers_Clause : Boolean := False;
      Seen_Async_Writers_Aspect : Boolean := False;
      Seen_Effective_Reads_Aspect : Boolean := False;
      Seen_Effective_Writes_Aspect : Boolean := False;
      Seen_Interrupt_Handler_Aspect : Boolean := False;
      Seen_Interrupt_Handler_Clause : Boolean := False;
      Seen_Attach_Handler_Aspect : Boolean := False;
      Seen_Attach_Handler_Clause : Boolean := False;
      Seen_Priority_Aspect : Boolean := False;
      Seen_Priority_Clause : Boolean := False;
      Seen_CPU_Aspect : Boolean := False;
      Seen_CPU_Clause : Boolean := False;
      Seen_Dispatching_Domain_Aspect : Boolean := False;
      Seen_Interrupt_Priority_Aspect : Boolean := False;
      Seen_Interrupt_Priority_Clause : Boolean := False;
      Seen_Boolean_Property_Value : Boolean := False;
   begin
      Assert (Display_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Display type should be retained");
      Assert (Broken_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Broken type should be retained");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Count type should be retained");
      Assert (Pixels_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Pixels array type should be retained");
      Assert (Bag_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Bag type should be retained");
      Assert (Controlled_Free_Id /= Editor.Ada_Language_Model.No_Symbol,
              "No_Controlled_Parts type should be retained");
      Assert (Preelab_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Preelaborable_Initialization type should be retained");
      Assert (Names_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Discard_Names type should be retained");
      Assert (Volatile_Read_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Volatile_Function subprogram should be retained");
      Assert (Flag_Id /= Editor.Ada_Language_Model.No_Symbol,
              "concurrency property object should be retained");
      Assert (ISR_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Interrupt_Handler subprogram should be retained");
      Assert (Hook_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Attach_Handler subprogram should be retained");
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol,
              "task type with scheduling aspects should be retained");
      Assert (Gate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "protected type with interrupt priority should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Display_Id
              and then A = "Stream_Size"
              and then To_String (Info.Item_Text) = "8"
            then
               Seen_Stream_Size_Aspect := True;
            elsif Info.Target_Symbol = Display_Id
              and then A = "Stream_Size"
              and then To_String (Info.Item_Text) = "0"
            then
               Seen_Stream_Size_Clause := True;
            elsif Info.Target_Symbol = Display_Id
              and then A = "External_Tag"
              and then To_String (Info.Item_Text) = """display-v1"""
            then
               Seen_External_Tag_Aspect := True;
            elsif Info.Target_Symbol = Display_Id
              and then A = "External_Tag"
              and then To_String (Info.Item_Text) = "Not_A_String"
            then
               Seen_External_Tag_Clause := True;
            elsif Info.Target_Symbol = Display_Id
              and then A = "Put_Image"
            then
               Seen_Put_Image_Aspect := True;
            elsif Info.Target_Symbol = Display_Id
              and then A = "Read"
              and then To_String (Info.Item_Text) = "Read_Display"
            then
               Seen_Read_Aspect := True;
               Seen_Read_Kind :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Read_Clause;
            elsif Info.Target_Symbol = Display_Id
              and then A = "Read"
              and then To_String (Info.Item_Text) = "Missing_Read"
            then
               Seen_Read_Clause := True;
               Seen_Read_Kind := Seen_Read_Kind
                 and then Info.Kind = Editor.Ada_Language_Model.Representation_Read_Clause;
            elsif Info.Target_Symbol = Count_Id
              and then A = "Default_Value"
              and then To_String (Info.Item_Text) = "1"
            then
               Seen_Default_Value_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Value_Clause;
            elsif Info.Target_Symbol = Count_Id
              and then A = "Default_Value"
              and then To_String (Info.Item_Text) = "2"
            then
               Seen_Default_Value_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Value_Clause;
            elsif Info.Target_Symbol = Pixels_Id
              and then A = "Default_Component_Value"
              and then To_String (Info.Item_Text) = "0"
            then
               Seen_Default_Component_Value_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Component_Value_Clause;
            elsif Info.Target_Symbol = Pixels_Id
              and then A = "Default_Component_Value"
              and then To_String (Info.Item_Text) = "1"
            then
               Seen_Default_Component_Value_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Component_Value_Clause;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Constant_Indexing"
              and then To_String (Info.Item_Text) = "Element"
            then
               if Info.Kind = Editor.Ada_Language_Model.Representation_Constant_Indexing_Clause then
                  if Seen_Constant_Indexing_Aspect then
                     Seen_Constant_Indexing_Clause := True;
                  else
                     Seen_Constant_Indexing_Aspect := True;
                  end if;
               end if;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Variable_Indexing"
            then
               Seen_Variable_Indexing_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Variable_Indexing_Clause;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Implicit_Dereference"
            then
               Seen_Implicit_Dereference_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Implicit_Dereference_Clause;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Default_Iterator"
            then
               Seen_Default_Iterator_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Iterator_Clause;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Iterator_Element"
            then
               Seen_Iterator_Element_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Iterator_Element_Clause;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Max_Entry_Queue_Length"
              and then To_String (Info.Item_Text) = "1"
            then
               Seen_Max_Entry_Queue_Length_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Max_Entry_Queue_Length_Clause;
            elsif Info.Target_Symbol = Bag_Id
              and then A = "Max_Entry_Queue_Length"
              and then To_String (Info.Item_Text) = "0"
            then
               Seen_Max_Entry_Queue_Length_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Max_Entry_Queue_Length_Clause;
            elsif Info.Target_Symbol = Controlled_Free_Id
              and then A = "No_Controlled_Parts"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_No_Controlled_Parts_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_No_Controlled_Parts_Clause;
            elsif Info.Target_Symbol = Controlled_Free_Id
              and then A = "No_Controlled_Parts"
              and then To_String (Info.Item_Text) = "False"
            then
               Seen_No_Controlled_Parts_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_No_Controlled_Parts_Clause;
            elsif Info.Target_Symbol = Preelab_Id
              and then A = "Preelaborable_Initialization"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Preelaborable_Initialization_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Preelaborable_Initialization_Clause;
            elsif Info.Target_Symbol = Preelab_Id
              and then A = "Preelaborable_Initialization"
              and then To_String (Info.Item_Text) = "Maybe"
            then
               Seen_Preelaborable_Initialization_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Preelaborable_Initialization_Clause;
            elsif Info.Target_Symbol = Names_Id
              and then A = "Discard_Names"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Discard_Names_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Discard_Names_Clause;
            elsif Info.Target_Symbol = Names_Id
              and then A = "Discard_Names"
              and then To_String (Info.Item_Text) = "False"
            then
               Seen_Discard_Names_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Discard_Names_Clause;
            elsif Info.Target_Symbol = Volatile_Read_Id
              and then A = "Volatile_Function"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Volatile_Function_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Volatile_Function_Clause;
            elsif Info.Target_Symbol = Volatile_Read_Id
              and then A = "Volatile_Function"
              and then To_String (Info.Item_Text) = "False"
            then
               Seen_Volatile_Function_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Volatile_Function_Clause;
            elsif Info.Target_Symbol = Flag_Id
              and then A = "Async_Readers"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Async_Readers_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Async_Readers_Clause;
            elsif Info.Target_Symbol = Flag_Id
              and then A = "Async_Readers"
              and then To_String (Info.Item_Text) = "False"
            then
               Seen_Async_Readers_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Async_Readers_Clause;
            elsif Info.Target_Symbol = Flag_Id
              and then A = "Async_Writers"
            then
               Seen_Async_Writers_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Async_Writers_Clause;
            elsif Info.Target_Symbol = Flag_Id
              and then A = "Effective_Reads"
            then
               Seen_Effective_Reads_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Effective_Reads_Clause;
            elsif Info.Target_Symbol = Flag_Id
              and then A = "Effective_Writes"
            then
               Seen_Effective_Writes_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Effective_Writes_Clause;
            elsif Info.Target_Symbol = ISR_Id
              and then A = "Interrupt_Handler"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Interrupt_Handler_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Interrupt_Handler_Clause;
            elsif Info.Target_Symbol = ISR_Id
              and then A = "Interrupt_Handler"
              and then To_String (Info.Item_Text) = "False"
            then
               Seen_Interrupt_Handler_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Interrupt_Handler_Clause;
            elsif Info.Target_Symbol = Hook_Id
              and then A = "Attach_Handler"
              and then To_String (Info.Item_Text) = "Some_Interrupt"
            then
               Seen_Attach_Handler_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Attach_Handler_Clause;
            elsif Info.Target_Symbol = Hook_Id
              and then A = "Attach_Handler"
              and then To_String (Info.Item_Text) = "Other_Interrupt"
            then
               Seen_Attach_Handler_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Attach_Handler_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Priority"
              and then To_String (Info.Item_Text) = "5"
            then
               Seen_Priority_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Priority_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Priority"
              and then To_String (Info.Item_Text) = "0"
            then
               Seen_Priority_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Priority_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "CPU"
              and then To_String (Info.Item_Text) = "1"
            then
               Seen_CPU_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_CPU_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "CPU"
              and then To_String (Info.Item_Text) = "0"
            then
               Seen_CPU_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_CPU_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Dispatching_Domain"
            then
               Seen_Dispatching_Domain_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Dispatching_Domain_Clause;
            elsif Info.Target_Symbol = Gate_Id
              and then A = "Interrupt_Priority"
              and then To_String (Info.Item_Text) = "7"
            then
               Seen_Interrupt_Priority_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Interrupt_Priority_Clause;
            elsif Info.Target_Symbol = Gate_Id
              and then A = "Interrupt_Priority"
              and then To_String (Info.Item_Text) = "6"
            then
               Seen_Interrupt_Priority_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Interrupt_Priority_Clause;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause =>
                  Seen_Duplicate := True;
               when Editor.Ada_Language_Model.Legality_Representation_Positive_Value_Required =>
                  Seen_Stream_Size_Positive := True;
               when Editor.Ada_Language_Model.Legality_Interfacing_String_Value_Required =>
                  Seen_External_Tag_String := True;
               when Editor.Ada_Language_Model.Legality_Operational_Attribute_Handler_Not_Found =>
                  Seen_Put_Image_Handler := True;
               when Editor.Ada_Language_Model.Legality_Pack_Boolean_Value_Required =>
                  Seen_Boolean_Property_Value := True;
               when Editor.Ada_Language_Model.Legality_Representation_Target_Incompatible =>
                  if Ada.Strings.Fixed.Index
                    (To_String (Info.Message), "Default_Component_Value") /= 0
                  then
                     Seen_Default_Component_Target := True;
                  end if;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Stream_Size_Aspect,
              "Stream_Size aspect should lower into representation metadata");
      Assert (Seen_Stream_Size_Clause,
              "Stream_Size attribute-definition clause should share representation metadata");
      Assert (Seen_External_Tag_Aspect,
              "External_Tag aspect should lower into operational metadata");
      Assert (Seen_External_Tag_Clause,
              "External_Tag attribute-definition clause should share operational metadata");
      Assert (Seen_Put_Image_Aspect,
              "Put_Image aspect should lower into operational handler metadata");
      Assert (Seen_Read_Aspect,
              "Read aspect should lower into stream operational metadata");
      Assert (Seen_Read_Clause,
              "Read attribute-definition clause should share stream operational metadata");
      Assert (Seen_Read_Kind,
              "Read aspect and attribute-definition clause should use the explicit stream representation kind");
      Assert (Seen_Duplicate,
              "aspect and attribute-definition forms should share duplicate detection for added properties");
      Assert (Seen_Stream_Size_Positive,
              "Stream_Size should share static positive value legality");
      Assert (Seen_External_Tag_String,
              "External_Tag should share static string value legality");
      Assert (Seen_Put_Image_Handler,
              "Put_Image should share operational handler lookup legality");
      Assert (Seen_Default_Value_Aspect,
              "Default_Value aspect should lower into explicit representation metadata");
      Assert (Seen_Default_Value_Clause,
              "Default_Value attribute-definition clause should share explicit representation metadata");
      Assert (Seen_Default_Component_Value_Aspect,
              "Default_Component_Value aspect should lower into explicit representation metadata");
      Assert (Seen_Default_Component_Value_Clause,
              "Default_Component_Value attribute-definition clause should share explicit representation metadata");
      Assert (Seen_Default_Component_Target,
              "Default_Component_Value should share array-target legality across source forms");
      Assert (Seen_Constant_Indexing_Aspect,
              "Constant_Indexing aspect should lower into explicit operational metadata");
      Assert (Seen_Constant_Indexing_Clause,
              "Constant_Indexing attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Variable_Indexing_Aspect,
              "Variable_Indexing aspect should lower into explicit operational metadata");
      Assert (Seen_Implicit_Dereference_Aspect,
              "Implicit_Dereference aspect should lower into explicit operational metadata");
      Assert (Seen_Default_Iterator_Aspect,
              "Default_Iterator aspect should lower into explicit operational metadata");
      Assert (Seen_Iterator_Element_Aspect,
              "Iterator_Element aspect should lower into explicit operational metadata");
      Assert (Seen_Max_Entry_Queue_Length_Aspect,
              "Max_Entry_Queue_Length aspect should lower into explicit operational metadata");
      Assert (Seen_Max_Entry_Queue_Length_Clause,
              "Max_Entry_Queue_Length attribute-definition clause should share explicit operational metadata");
      Assert (Seen_No_Controlled_Parts_Aspect,
              "No_Controlled_Parts aspect should lower into explicit operational metadata");
      Assert (Seen_No_Controlled_Parts_Clause,
              "No_Controlled_Parts attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Preelaborable_Initialization_Aspect,
              "Preelaborable_Initialization aspect should lower into explicit representation metadata");
      Assert (Seen_Preelaborable_Initialization_Clause,
              "Preelaborable_Initialization attribute-definition clause should share explicit representation metadata");
      Assert (Seen_Discard_Names_Aspect,
              "Discard_Names aspect should lower into explicit representation metadata");
      Assert (Seen_Discard_Names_Clause,
              "Discard_Names attribute-definition clause should share explicit representation metadata");
      Assert (Seen_Volatile_Function_Aspect,
              "Volatile_Function aspect should lower into explicit operational metadata");
      Assert (Seen_Volatile_Function_Clause,
              "Volatile_Function attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Async_Readers_Aspect,
              "Async_Readers aspect should lower into explicit operational metadata");
      Assert (Seen_Async_Readers_Clause,
              "Async_Readers attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Async_Writers_Aspect,
              "Async_Writers aspect should lower into explicit operational metadata");
      Assert (Seen_Effective_Reads_Aspect,
              "Effective_Reads aspect should lower into explicit operational metadata");
      Assert (Seen_Effective_Writes_Aspect,
              "Effective_Writes aspect should lower into explicit operational metadata");
      Assert (Seen_Interrupt_Handler_Aspect,
              "Interrupt_Handler aspect should lower into explicit operational metadata");
      Assert (Seen_Interrupt_Handler_Clause,
              "Interrupt_Handler attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Attach_Handler_Aspect,
              "Attach_Handler aspect should lower into explicit operational metadata");
      Assert (Seen_Attach_Handler_Clause,
              "Attach_Handler attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Priority_Aspect,
              "Priority aspect should lower into explicit scheduling representation metadata");
      Assert (Seen_Priority_Clause,
              "Priority attribute-definition clause should share explicit scheduling representation metadata");
      Assert (Seen_CPU_Aspect,
              "CPU aspect should lower into explicit scheduling representation metadata");
      Assert (Seen_CPU_Clause,
              "CPU attribute-definition clause should share explicit scheduling representation metadata");
      Assert (Seen_Dispatching_Domain_Aspect,
              "Dispatching_Domain aspect should lower into explicit scheduling representation metadata");
      Assert (Seen_Interrupt_Priority_Aspect,
              "Interrupt_Priority aspect should lower into explicit scheduling representation metadata");
      Assert (Seen_Interrupt_Priority_Clause,
              "Interrupt_Priority attribute-definition clause should share explicit scheduling representation metadata");
      Assert (Seen_Boolean_Property_Value,
              "Boolean representation/operational properties should share static Boolean legality");
   end Test_Language_Model_Representation_Operational_Property_Unification_Pass;







   procedure Test_Language_Model_Literal_Storage_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Number is private with Integer_Literal => To_Number, Real_Literal => To_Real, String_Literal => To_String_Value;" & ASCII.LF &
        "   for Number'Integer_Literal use Other_Number;" & ASCII.LF &
        "   type Pool_Access is access Integer with Max_Size_In_Storage_Elements => 64, Storage_Model_Type => Model_T, Designated_Storage_Model => Model_Obj;" & ASCII.LF &
        "   for Pool_Access'Max_Size_In_Storage_Elements use 128;" & ASCII.LF &
        "   for Pool_Access'Designated_Storage_Model use Other_Model;" & ASCII.LF &
        "   Obj : Integer;" & ASCII.LF &
        "   for Obj'Integer_Literal use Bad_Handler;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Number_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Number");
      Pool_Access_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Pool_Access");
      Seen_Integer_Literal_Aspect : Boolean := False;
      Seen_Integer_Literal_Clause : Boolean := False;
      Seen_Real_Literal_Aspect : Boolean := False;
      Seen_String_Literal_Aspect : Boolean := False;
      Seen_Max_Size_Aspect : Boolean := False;
      Seen_Max_Size_Clause : Boolean := False;
      Seen_Storage_Model_Type_Aspect : Boolean := False;
      Seen_Designated_Storage_Model_Aspect : Boolean := False;
      Seen_Designated_Storage_Model_Clause : Boolean := False;
      Seen_Duplicate : Boolean := False;
      Seen_Target_Diagnostic : Boolean := False;
   begin
      Assert (Number_Id /= Editor.Ada_Language_Model.No_Symbol,
              "literal aspect target should be retained");
      Assert (Pool_Access_Id /= Editor.Ada_Language_Model.No_Symbol,
              "storage-model access target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Number_Id
              and then A = "Integer_Literal"
              and then To_String (Info.Item_Text) = "To_Number"
            then
               Seen_Integer_Literal_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Integer_Literal_Clause;
            elsif Info.Target_Symbol = Number_Id
              and then A = "Integer_Literal"
              and then To_String (Info.Item_Text) = "Other_Number"
            then
               Seen_Integer_Literal_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Integer_Literal_Clause;
            elsif Info.Target_Symbol = Number_Id
              and then A = "Real_Literal"
            then
               Seen_Real_Literal_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Real_Literal_Clause;
            elsif Info.Target_Symbol = Number_Id
              and then A = "String_Literal"
            then
               Seen_String_Literal_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_String_Literal_Clause;
            elsif Info.Target_Symbol = Pool_Access_Id
              and then A = "Max_Size_In_Storage_Elements"
              and then To_String (Info.Item_Text) = "64"
            then
               Seen_Max_Size_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Max_Size_In_Storage_Elements_Clause;
            elsif Info.Target_Symbol = Pool_Access_Id
              and then A = "Max_Size_In_Storage_Elements"
              and then To_String (Info.Item_Text) = "128"
            then
               Seen_Max_Size_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Max_Size_In_Storage_Elements_Clause;
            elsif Info.Target_Symbol = Pool_Access_Id
              and then A = "Storage_Model_Type"
            then
               Seen_Storage_Model_Type_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Storage_Model_Type_Clause;
            elsif Info.Target_Symbol = Pool_Access_Id
              and then A = "Designated_Storage_Model"
              and then To_String (Info.Item_Text) = "Model_Obj"
            then
               Seen_Designated_Storage_Model_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Designated_Storage_Model_Clause;
            elsif Info.Target_Symbol = Pool_Access_Id
              and then A = "Designated_Storage_Model"
              and then To_String (Info.Item_Text) = "Other_Model"
            then
               Seen_Designated_Storage_Model_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Designated_Storage_Model_Clause;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause =>
                  Seen_Duplicate := True;
               when Editor.Ada_Language_Model.Legality_Representation_Target_Incompatible =>
                  if Ada.Strings.Fixed.Index
                    (To_String (Info.Message), "literal operational property") /= 0
                  then
                     Seen_Target_Diagnostic := True;
                  end if;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Integer_Literal_Aspect,
              "Integer_Literal aspect should lower into explicit operational metadata");
      Assert (Seen_Integer_Literal_Clause,
              "Integer_Literal attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Real_Literal_Aspect,
              "Real_Literal aspect should lower into explicit operational metadata");
      Assert (Seen_String_Literal_Aspect,
              "String_Literal aspect should lower into explicit operational metadata");
      Assert (Seen_Max_Size_Aspect,
              "Max_Size_In_Storage_Elements aspect should lower into explicit operational metadata");
      Assert (Seen_Max_Size_Clause,
              "Max_Size_In_Storage_Elements attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Storage_Model_Type_Aspect,
              "Storage_Model_Type aspect should lower into explicit operational metadata");
      Assert (Seen_Designated_Storage_Model_Aspect,
              "Designated_Storage_Model aspect should lower into explicit operational metadata");
      Assert (Seen_Designated_Storage_Model_Clause,
              "Designated_Storage_Model attribute-definition clause should share explicit operational metadata");
      Assert (Seen_Duplicate,
              "new literal/storage properties should participate in mixed duplicate detection");
      Assert (Seen_Target_Diagnostic,
              "literal operational properties should reuse shared target legality");
   end Test_Language_Model_Literal_Storage_Operational_Unification_Pass;




   procedure Test_Language_Model_Predicate_Invariant_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with Initial_Condition => Ready is" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   for P'Initial_Condition use not Ready;" & ASCII.LF &
        "   type Meter is range 0 .. 100 with Static_Predicate => Meter in 0 .. 100, Predicate_Failure => ""bad meter"";" & ASCII.LF &
        "   for Meter'Static_Predicate use Meter /= 50;" & ASCII.LF &
        "   for Meter'Predicate_Failure use ""meter failed"";" & ASCII.LF &
        "   type Score is range 0 .. 100 with Dynamic_Predicate => Score <= 100;" & ASCII.LF &
        "   for Score'Dynamic_Predicate use Score >= 0;" & ASCII.LF &
        "   type Account is tagged null record with Type_Invariant => Is_Valid (Account), Type_Invariant'Class => Is_Class_Valid (Account);" & ASCII.LF &
        "   for Account'Type_Invariant use Is_Also_Valid (Account);" & ASCII.LF &
        "   for Account'Type_Invariant'Class use Is_Class_Also_Valid (Account);" & ASCII.LF &
        "   type Defaulted is tagged null record with Default_Initial_Condition => Ready;" & ASCII.LF &
        "   for Defaulted'Default_Initial_Condition use not Ready;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      P_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Meter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Meter");
      Score_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Score");
      Account_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Account");
      Defaulted_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Defaulted");
      Seen_Initial_Aspect : Boolean := False;
      Seen_Initial_Clause : Boolean := False;
      Seen_Static_Predicate_Aspect : Boolean := False;
      Seen_Static_Predicate_Clause : Boolean := False;
      Seen_Dynamic_Predicate_Aspect : Boolean := False;
      Seen_Dynamic_Predicate_Clause : Boolean := False;
      Seen_Predicate_Failure_Aspect : Boolean := False;
      Seen_Predicate_Failure_Clause : Boolean := False;
      Seen_Type_Invariant_Aspect : Boolean := False;
      Seen_Type_Invariant_Clause : Boolean := False;
      Seen_Type_Invariant_Class_Aspect : Boolean := False;
      Seen_Type_Invariant_Class_Clause : Boolean := False;
      Seen_Default_Initial_Aspect : Boolean := False;
      Seen_Default_Initial_Clause : Boolean := False;
   begin
      Assert (P_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target should be retained for Initial_Condition");
      Assert (Meter_Id /= Editor.Ada_Language_Model.No_Symbol,
              "predicate target should be retained");
      Assert (Score_Id /= Editor.Ada_Language_Model.No_Symbol,
              "dynamic predicate target should be retained");
      Assert (Account_Id /= Editor.Ada_Language_Model.No_Symbol,
              "invariant target should be retained");
      Assert (Defaulted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "default initial condition target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = P_Id
              and then A = "Initial_Condition"
              and then To_String (Info.Item_Text) = "Ready"
            then
               Seen_Initial_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Initial_Condition_Clause;
            elsif Info.Target_Symbol = P_Id
              and then A = "Initial_Condition"
              and then To_String (Info.Item_Text) = "not Ready"
            then
               Seen_Initial_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Initial_Condition_Clause;
            elsif Info.Target_Symbol = Meter_Id
              and then A = "Static_Predicate"
              and then To_String (Info.Item_Text) = "Meter in 0 .. 100"
            then
               Seen_Static_Predicate_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Static_Predicate_Clause;
            elsif Info.Target_Symbol = Meter_Id
              and then A = "Static_Predicate"
              and then To_String (Info.Item_Text) = "Meter /= 50"
            then
               Seen_Static_Predicate_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Static_Predicate_Clause;
            elsif Info.Target_Symbol = Meter_Id
              and then A = "Predicate_Failure"
              and then To_String (Info.Item_Text) = """bad meter"""
            then
               Seen_Predicate_Failure_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Predicate_Failure_Clause;
            elsif Info.Target_Symbol = Meter_Id
              and then A = "Predicate_Failure"
              and then To_String (Info.Item_Text) = """meter failed"""
            then
               Seen_Predicate_Failure_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Predicate_Failure_Clause;
            elsif Info.Target_Symbol = Score_Id
              and then A = "Dynamic_Predicate"
              and then To_String (Info.Item_Text) = "Score <= 100"
            then
               Seen_Dynamic_Predicate_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Dynamic_Predicate_Clause;
            elsif Info.Target_Symbol = Score_Id
              and then A = "Dynamic_Predicate"
              and then To_String (Info.Item_Text) = "Score >= 0"
            then
               Seen_Dynamic_Predicate_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Dynamic_Predicate_Clause;
            elsif Info.Target_Symbol = Account_Id
              and then A = "Type_Invariant"
              and then To_String (Info.Item_Text) = "Is_Valid (Account)"
            then
               Seen_Type_Invariant_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Type_Invariant_Clause;
            elsif Info.Target_Symbol = Account_Id
              and then A = "Type_Invariant"
              and then To_String (Info.Item_Text) = "Is_Also_Valid (Account)"
            then
               Seen_Type_Invariant_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Type_Invariant_Clause;
            elsif Info.Target_Symbol = Account_Id
              and then A = "Type_Invariant'Class"
              and then To_String (Info.Item_Text) = "Is_Class_Valid (Account)"
            then
               Seen_Type_Invariant_Class_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Type_Invariant_Class_Clause;
            elsif Info.Target_Symbol = Account_Id
              and then A = "Type_Invariant'Class"
              and then To_String (Info.Item_Text) = "Is_Class_Also_Valid (Account)"
            then
               Seen_Type_Invariant_Class_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Type_Invariant_Class_Clause;
            elsif Info.Target_Symbol = Defaulted_Id
              and then A = "Default_Initial_Condition"
              and then To_String (Info.Item_Text) = "Ready"
            then
               Seen_Default_Initial_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Initial_Condition_Clause;
            elsif Info.Target_Symbol = Defaulted_Id
              and then A = "Default_Initial_Condition"
              and then To_String (Info.Item_Text) = "not Ready"
            then
               Seen_Default_Initial_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Default_Initial_Condition_Clause;
            end if;
         end;
      end loop;


      Assert (Seen_Initial_Aspect and Seen_Initial_Clause,
              "Initial_Condition aspect and attribute-definition clause should share explicit metadata");
      Assert (Seen_Static_Predicate_Aspect and Seen_Static_Predicate_Clause,
              "Static_Predicate should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Dynamic_Predicate_Aspect and Seen_Dynamic_Predicate_Clause,
              "Dynamic_Predicate should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Predicate_Failure_Aspect and Seen_Predicate_Failure_Clause,
              "Predicate_Failure should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Type_Invariant_Aspect and Seen_Type_Invariant_Clause,
              "Type_Invariant should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Type_Invariant_Class_Aspect and Seen_Type_Invariant_Class_Clause,
              "Type_Invariant'Class should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Default_Initial_Aspect and Seen_Default_Initial_Clause,
              "Default_Initial_Condition should lower from both aspects and attribute-definition clauses");
   end Test_Language_Model_Predicate_Invariant_Operational_Unification_Pass;




   procedure Test_Language_Model_Contract_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   procedure Op (X : Integer)" & ASCII.LF &
        "     with Pre => X > 0," & ASCII.LF &
        "          Post => X >= 0," & ASCII.LF &
        "          Nonblocking;" & ASCII.LF &
        "   for Op'Pre use X /= 0;" & ASCII.LF &
        "   for Op'Post'Class use X >= -1;" & ASCII.LF &
        "   procedure Worker" & ASCII.LF &
        "     with Global => null," & ASCII.LF &
        "          Depends => null," & ASCII.LF &
        "          Always_Terminates;" & ASCII.LF &
        "   for Worker'Global use null;" & ASCII.LF &
        "   for Worker'Depends use null;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Op_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Op");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Seen_Pre_Aspect : Boolean := False;
      Seen_Pre_Clause : Boolean := False;
      Seen_Post_Aspect : Boolean := False;
      Seen_Post_Class_Clause : Boolean := False;
      Seen_Nonblocking : Boolean := False;
      Seen_Global_Aspect : Boolean := False;
      Seen_Global_Clause : Boolean := False;
      Seen_Depends_Aspect : Boolean := False;
      Seen_Depends_Clause : Boolean := False;
      Seen_Always_Terminates : Boolean := False;
   begin
      Assert (Op_Id /= Editor.Ada_Language_Model.No_Symbol,
              "contract subprogram target should be retained");
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol,
              "global/depends subprogram target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Op_Id
              and then A = "Pre"
              and then To_String (Info.Item_Text) = "X > 0"
            then
               Seen_Pre_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Pre_Clause;
            elsif Info.Target_Symbol = Op_Id
              and then A = "Pre"
              and then To_String (Info.Item_Text) = "X /= 0"
            then
               Seen_Pre_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Pre_Clause;
            elsif Info.Target_Symbol = Op_Id
              and then A = "Post"
              and then To_String (Info.Item_Text) = "X >= 0"
            then
               Seen_Post_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Post_Clause;
            elsif Info.Target_Symbol = Op_Id
              and then A = "Post'Class"
              and then To_String (Info.Item_Text) = "X >= -1"
            then
               Seen_Post_Class_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Post_Class_Clause;
            elsif Info.Target_Symbol = Op_Id
              and then A = "Nonblocking"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Nonblocking :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Nonblocking_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Global"
              and then To_String (Info.Item_Text) = "null"
            then
               if Info.Kind = Editor.Ada_Language_Model.Representation_Global_Clause then
                  if Seen_Global_Aspect then
                     Seen_Global_Clause := True;
                  else
                     Seen_Global_Aspect := True;
                  end if;
               end if;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Depends"
              and then To_String (Info.Item_Text) = "null"
            then
               if Info.Kind = Editor.Ada_Language_Model.Representation_Depends_Clause then
                  if Seen_Depends_Aspect then
                     Seen_Depends_Clause := True;
                  else
                     Seen_Depends_Aspect := True;
                  end if;
               end if;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Always_Terminates"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Always_Terminates :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Always_Terminates_Clause;
            end if;
         end;
      end loop;

      Assert (Seen_Pre_Aspect and Seen_Pre_Clause,
              "Pre should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Post_Aspect and Seen_Post_Class_Clause,
              "Post and Post'Class should use explicit contract representation kinds");
      Assert (Seen_Nonblocking and Seen_Always_Terminates,
              "Boolean contract aspects without values should default to True");
      Assert (Seen_Global_Aspect and Seen_Global_Clause,
              "Global should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Depends_Aspect and Seen_Depends_Clause,
              "Depends should lower from both aspects and attribute-definition clauses");
   end Test_Language_Model_Contract_Operational_Unification_Pass;



   procedure Test_Language_Model_Remaining_Operational_Property_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   Pool_Obj : Integer;" & ASCII.LF &
        "   type Ptr is access Integer" & ASCII.LF &
        "     with Default_Storage_Pool => Pool_Obj;" & ASCII.LF &
        "   for Ptr'Default_Storage_Pool use Pool_Obj;" & ASCII.LF &
        "   type Stable is tagged null record" & ASCII.LF &
        "     with Stable_Properties => Is_Stable;" & ASCII.LF &
        "   for Stable'Stable_Properties'Class use Is_Class_Stable;" & ASCII.LF &
        "   task Worker" & ASCII.LF &
        "     with Relative_Deadline => Milliseconds (10);" & ASCII.LF &
        "   for Worker'Relative_Deadline use Milliseconds (20);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Ptr_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ptr");
      Stable_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Stable");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Seen_Default_Storage_Pool_Aspect : Boolean := False;
      Seen_Default_Storage_Pool_Clause : Boolean := False;
      Seen_Stable_Properties_Aspect : Boolean := False;
      Seen_Stable_Properties_Class_Clause : Boolean := False;
      Seen_Relative_Deadline_Aspect : Boolean := False;
      Seen_Relative_Deadline_Clause : Boolean := False;
   begin
      Assert (Ptr_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access type target should be retained");
      Assert (Stable_Id /= Editor.Ada_Language_Model.No_Symbol,
              "stable property type target should be retained");
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol,
              "relative deadline task target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Ptr_Id
              and then A = "Default_Storage_Pool"
              and then To_String (Info.Item_Text) = "Pool_Obj"
            then
               if Info.Kind = Editor.Ada_Language_Model.Representation_Default_Storage_Pool_Clause then
                  if Seen_Default_Storage_Pool_Aspect then
                     Seen_Default_Storage_Pool_Clause := True;
                  else
                     Seen_Default_Storage_Pool_Aspect := True;
                  end if;
               end if;
            elsif Info.Target_Symbol = Stable_Id
              and then A = "Stable_Properties"
              and then To_String (Info.Item_Text) = "Is_Stable"
            then
               Seen_Stable_Properties_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Stable_Properties_Clause;
            elsif Info.Target_Symbol = Stable_Id
              and then A = "Stable_Properties'Class"
              and then To_String (Info.Item_Text) = "Is_Class_Stable"
            then
               Seen_Stable_Properties_Class_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Stable_Properties_Class_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Relative_Deadline"
              and then To_String (Info.Item_Text) = "Milliseconds (10)"
            then
               Seen_Relative_Deadline_Aspect :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Relative_Deadline_Clause;
            elsif Info.Target_Symbol = Worker_Id
              and then A = "Relative_Deadline"
              and then To_String (Info.Item_Text) = "Milliseconds (20)"
            then
               Seen_Relative_Deadline_Clause :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Relative_Deadline_Clause;
            end if;
         end;
      end loop;

      Assert (Seen_Default_Storage_Pool_Aspect and Seen_Default_Storage_Pool_Clause,
              "Default_Storage_Pool should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Stable_Properties_Aspect and Seen_Stable_Properties_Class_Clause,
              "Stable_Properties forms should use explicit operational property kinds");
      Assert (Seen_Relative_Deadline_Aspect and Seen_Relative_Deadline_Clause,
              "Relative_Deadline should lower from both aspects and attribute-definition clauses");
   end Test_Language_Model_Remaining_Operational_Property_Unification_Pass;




   procedure Test_Language_Model_State_Ownership_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with Abstract_State => State, Initializes => Obj is" & ASCII.LF &
        "   Obj : Integer with Part_Of => State;" & ASCII.LF &
        "   Ghost_Obj : Integer with Ghost;" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      X : Integer;" & ASCII.LF &
        "   end record with Relaxed_Initialization;" & ASCII.LF &
        "   for P'Abstract_State use State;" & ASCII.LF &
        "   for P'Initializes use Obj;" & ASCII.LF &
        "   for Obj'Part_Of use State;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Obj_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Obj");
      Ghost_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ghost_Obj");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Seen_Abstract_State_Aspect : Boolean := False;
      Seen_Abstract_State_Clause : Boolean := False;
      Seen_Initializes_Aspect : Boolean := False;
      Seen_Initializes_Clause : Boolean := False;
      Seen_Part_Of_Aspect : Boolean := False;
      Seen_Part_Of_Clause : Boolean := False;
      Seen_Ghost_Default : Boolean := False;
      Seen_Relaxed_Default : Boolean := False;
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target should be retained");
      Assert (Obj_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object target should be retained");
      Assert (Ghost_Id /= Editor.Ada_Language_Model.No_Symbol,
              "ghost object target should be retained");
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "relaxed initialization type target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Package_Id
              and then A = "Abstract_State"
              and then To_String (Info.Item_Text) = "State"
            then
               if Seen_Abstract_State_Aspect then
                  Seen_Abstract_State_Clause :=
                    Info.Kind = Editor.Ada_Language_Model.Representation_Abstract_State_Clause;
               else
                  Seen_Abstract_State_Aspect :=
                    Info.Kind = Editor.Ada_Language_Model.Representation_Abstract_State_Clause;
               end if;
            elsif Info.Target_Symbol = Package_Id
              and then A = "Initializes"
              and then To_String (Info.Item_Text) = "Obj"
            then
               if Seen_Initializes_Aspect then
                  Seen_Initializes_Clause :=
                    Info.Kind = Editor.Ada_Language_Model.Representation_Initializes_Clause;
               else
                  Seen_Initializes_Aspect :=
                    Info.Kind = Editor.Ada_Language_Model.Representation_Initializes_Clause;
               end if;
            elsif Info.Target_Symbol = Obj_Id
              and then A = "Part_Of"
              and then To_String (Info.Item_Text) = "State"
            then
               if Seen_Part_Of_Aspect then
                  Seen_Part_Of_Clause :=
                    Info.Kind = Editor.Ada_Language_Model.Representation_Part_Of_Clause;
               else
                  Seen_Part_Of_Aspect :=
                    Info.Kind = Editor.Ada_Language_Model.Representation_Part_Of_Clause;
               end if;
            elsif Info.Target_Symbol = Ghost_Id
              and then A = "Ghost"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Ghost_Default :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Ghost_Clause;
            elsif Info.Target_Symbol = Rec_Id
              and then A = "Relaxed_Initialization"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Relaxed_Default :=
                 Info.Kind = Editor.Ada_Language_Model.Representation_Relaxed_Initialization_Clause;
            end if;
         end;
      end loop;

      Assert (Seen_Abstract_State_Aspect and Seen_Abstract_State_Clause,
              "Abstract_State should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Initializes_Aspect and Seen_Initializes_Clause,
              "Initializes should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Part_Of_Aspect and Seen_Part_Of_Clause,
              "Part_Of should lower from both aspects and attribute-definition clauses");
      Assert (Seen_Ghost_Default and Seen_Relaxed_Default,
              "Boolean state/ownership aspects without values should default to True");
   end Test_Language_Model_State_Ownership_Operational_Unification_Pass;




   procedure Test_Language_Model_Subprogram_Library_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P with Pure, Preelaborate => True, Elaborate_Body is" & ASCII.LF &
        "   procedure Op (X : Integer) with Inline;" & ASCII.LF &
        "   procedure Fast (X : Integer) with Inline_Always => True;" & ASCII.LF &
        "   procedure Stop with No_Return;" & ASCII.LF &
        "   for Op'Inline use True;" & ASCII.LF &
        "   for Fast'Inline_Always use True;" & ASCII.LF &
        "   for Stop'No_Return use True;" & ASCII.LF &
        "   for P'Pure use True;" & ASCII.LF &
        "   for P'Preelaborate use True;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      P_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      Op_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Op");
      Fast_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Fast");
      Stop_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Stop");
      Seen_Inline_Aspect : Boolean := False;
      Seen_Inline_Clause : Boolean := False;
      Seen_Inline_Always_Aspect : Boolean := False;
      Seen_Inline_Always_Clause : Boolean := False;
      Seen_No_Return_Aspect : Boolean := False;
      Seen_No_Return_Clause : Boolean := False;
      Seen_Pure_Aspect : Boolean := False;
      Seen_Pure_Clause : Boolean := False;
      Seen_Preelaborate_Aspect : Boolean := False;
      Seen_Preelaborate_Clause : Boolean := False;
      Seen_Elaborate_Body_Default : Boolean := False;
   begin
      Assert (P_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target should be retained for library-unit operational aspects");
      Assert (Op_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Inline subprogram target should be retained");
      Assert (Fast_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Inline_Always subprogram target should be retained");
      Assert (Stop_Id /= Editor.Ada_Language_Model.No_Symbol,
              "No_Return subprogram target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
            V : constant String := To_String (Info.Item_Text);
         begin
            if Info.Target_Symbol = Op_Id
              and then A = "Inline"
              and then V = "True"
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Inline_Clause
            then
               if Seen_Inline_Aspect then
                  Seen_Inline_Clause := True;
               else
                  Seen_Inline_Aspect := True;
               end if;
            elsif Info.Target_Symbol = Fast_Id
              and then A = "Inline_Always"
              and then V = "True"
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Inline_Always_Clause
            then
               if Seen_Inline_Always_Aspect then
                  Seen_Inline_Always_Clause := True;
               else
                  Seen_Inline_Always_Aspect := True;
               end if;
            elsif Info.Target_Symbol = Stop_Id
              and then A = "No_Return"
              and then V = "True"
              and then Info.Kind = Editor.Ada_Language_Model.Representation_No_Return_Clause
            then
               if Seen_No_Return_Aspect then
                  Seen_No_Return_Clause := True;
               else
                  Seen_No_Return_Aspect := True;
               end if;
            elsif Info.Target_Symbol = P_Id
              and then A = "Pure"
              and then V = "True"
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Pure_Clause
            then
               if Seen_Pure_Aspect then
                  Seen_Pure_Clause := True;
               else
                  Seen_Pure_Aspect := True;
               end if;
            elsif Info.Target_Symbol = P_Id
              and then A = "Preelaborate"
              and then V = "True"
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Preelaborate_Clause
            then
               if Seen_Preelaborate_Aspect then
                  Seen_Preelaborate_Clause := True;
               else
                  Seen_Preelaborate_Aspect := True;
               end if;
            elsif Info.Target_Symbol = P_Id
              and then A = "Elaborate_Body"
              and then V = "True"
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Elaborate_Body_Clause
            then
               Seen_Elaborate_Body_Default := True;
            end if;
         end;
      end loop;

      Assert (Seen_Inline_Aspect and Seen_Inline_Clause,
              "Inline should lower from both aspect and attribute-definition forms");
      Assert (Seen_Inline_Always_Aspect and Seen_Inline_Always_Clause,
              "Inline_Always should lower from both aspect and attribute-definition forms");
      Assert (Seen_No_Return_Aspect and Seen_No_Return_Clause,
              "No_Return should lower from both aspect and attribute-definition forms");
      Assert (Seen_Pure_Aspect and Seen_Pure_Clause,
              "Pure should lower from both aspect and attribute-definition forms");
      Assert (Seen_Preelaborate_Aspect and Seen_Preelaborate_Clause,
              "Preelaborate should lower from both aspect and attribute-definition forms");
      Assert (Seen_Elaborate_Body_Default,
              "Boolean library-unit operational aspects without values should default to True");
   end Test_Language_Model_Subprogram_Library_Operational_Unification_Pass;






   procedure Test_Language_Model_Representation_Pragma_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      X : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   pragma Pack (Rec);" & ASCII.LF &
        "   for Rec'Pack use False;" & ASCII.LF &
        "   Obj : Integer;" & ASCII.LF &
        "   pragma Atomic (Obj);" & ASCII.LF &
        "   pragma Volatile (Obj);" & ASCII.LF &
        "   Package_Object : Integer;" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "   function F return Integer;" & ASCII.LF &
        "   Hook_Interrupt : Integer;" & ASCII.LF &
        "   procedure Hook;" & ASCII.LF &
        "   pragma Attach_Handler (Handler => Hook, Interrupt => Hook_Interrupt);" & ASCII.LF &
        "   pragma Suppress_Initialization (P);" & ASCII.LF &
        "   pragma Discard_Names (E);" & ASCII.LF &
        "   pragma Volatile_Function (F);" & ASCII.LF &
        "   pragma Linker_Section (Obj, "".fast"");" & ASCII.LF &
        "   pragma Machine_Attribute (F, ""naked"");" & ASCII.LF &
        "   Obj_Named : Integer;" & ASCII.LF &
        "   function F_Named return Integer;" & ASCII.LF &
        "   pragma Linker_Section (Section => "".named"", Entity => Obj_Named);" & ASCII.LF &
        "   pragma Machine_Attribute (Attribute_Name => ""interrupt"", Entity => F_Named);" & ASCII.LF &
        "   procedure G;" & ASCII.LF &
        "   procedure H;" & ASCII.LF &
        "   procedure J;" & ASCII.LF &
        "   pragma Inline (G, H);" & ASCII.LF &
        "   pragma Inline (Entity => J);" & ASCII.LF &
        "   procedure Imported_Named;" & ASCII.LF &
        "   pragma Import (Entity => Imported_Named, Convention => C, External_Name => ""imported_named"");" & ASCII.LF &
        "   procedure Imported_Nested;" & ASCII.LF &
        "   pragma Import (Convention => C, External_Name => Make_Name (Entity => ""nested""), Entity => Imported_Nested);" & ASCII.LF &
        "   procedure External_Named;" & ASCII.LF &
        "   pragma External (External_Name => ""external_named"", Entity => External_Named);" & ASCII.LF &
        "   type Op_Int is range 0 .. 10;" & ASCII.LF &
        "   function ""+"" (Left, Right : Op_Int) return Op_Int;" & ASCII.LF &
        "   pragma Import (C, ""+"");" & ASCII.LF &
        "   pragma SPARK_Mode (On);" & ASCII.LF &
        "   pragma Assertion_Policy (Check);" & ASCII.LF &
        "   pragma Annotate (GNATprove, Intentional, ""comma, kept"");" & ASCII.LF &
        "   pragma Annotate (GNATprove, Intentional, ""arrow => kept"");" & ASCII.LF &
        "   task type Scheduled is" & ASCII.LF &
        "      pragma Priority (10);" & ASCII.LF &
        "      pragma CPU (2);" & ASCII.LF &
        "      pragma Relative_Deadline (Milliseconds (10));" & ASCII.LF &
        "      pragma Relative_Deadline (Milliseconds (Value => 11));" & ASCII.LF &
        "      pragma Relative_Deadline (Char_Delay (')'));" & ASCII.LF &
        "   end Scheduled;" & ASCII.LF &
        "   protected type Guard is" & ASCII.LF &
        "      pragma Interrupt_Priority (7);" & ASCII.LF &
        "   end Guard;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Obj_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Obj");
      P_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "P");
      E_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "E");
      F_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "F");
      Obj_Named_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Obj_Named");
      F_Named_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "F_Named");
      Hook_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hook");
      G_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "G");
      H_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "H");
      J_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "J");
      Imported_Named_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Imported_Named");
      Imported_Nested_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Imported_Nested");
      External_Named_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "External_Named");
      Operator_Plus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """+""");
      Scheduled_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Scheduled");
      Guard_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Guard");
      Seen_Pragma_Pack : Boolean := False;
      Seen_Clause_Pack : Boolean := False;
      Seen_Pragma_Atomic : Boolean := False;
      Seen_Pragma_Volatile : Boolean := False;
      Seen_Suppress : Boolean := False;
      Seen_Discard_Names : Boolean := False;
      Seen_Volatile_Function : Boolean := False;
      Seen_Attach_Handler_Named_Value : Boolean := False;
      Seen_Linker_Section_Value : Boolean := False;
      Seen_Machine_Attribute_Value : Boolean := False;
      Seen_Named_Linker_Section_Value : Boolean := False;
      Seen_Named_Machine_Attribute_Value : Boolean := False;
      Seen_Multi_Inline_G : Boolean := False;
      Seen_Multi_Inline_H : Boolean := False;
      Seen_Named_Inline_J : Boolean := False;
      Seen_Named_Import_Target : Boolean := False;
      Seen_Nested_Named_Import_Target : Boolean := False;
      Seen_Named_External_Target : Boolean := False;
      Seen_Operator_Import_Target : Boolean := False;
      Seen_Current_Scope_SPARK_Mode : Boolean := False;
      Seen_Current_Scope_Assertion_Policy : Boolean := False;
      Seen_Current_Scope_Priority_Value : Boolean := False;
      Seen_Current_Scope_CPU_Value : Boolean := False;
      Seen_Current_Scope_Relative_Deadline_Nested_Value : Boolean := False;
      Seen_Current_Scope_Relative_Deadline_Nested_Association_Value : Boolean := False;
      Seen_Current_Scope_Relative_Deadline_Character_Value : Boolean := False;
      Seen_Current_Scope_Interrupt_Priority_Value : Boolean := False;
      Seen_Syntax_Tree_Pragma_Character_Argument : Boolean := False;
      Seen_Syntax_Tree_Pragma_String_Comma_Argument : Boolean := False;
      Seen_Syntax_Tree_Pragma_String_Arrow_Argument : Boolean := False;
      Seen_Syntax_Tree_Pragma_Operator_Target : Boolean := False;
      Seen_Duplicate : Boolean := False;
      Seen_Suppress_Target : Boolean := False;
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record target for pragma Pack should be retained");
      Assert (Obj_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object target for Atomic/Volatile pragmas should be retained");
      Assert (P_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package target for suppress-initialization pragma diagnostic should be retained");
      Assert (E_Id /= Editor.Ada_Language_Model.No_Symbol,
              "exception target for Discard_Names pragma should be retained");
      Assert (F_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram target for Volatile_Function pragma should be retained");
      Assert (Obj_Named_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named entity target for Linker_Section pragma should be retained");
      Assert (F_Named_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named entity target for Machine_Attribute pragma should be retained");
      Assert (Hook_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram target for named Attach_Handler pragma should be retained");
      Assert (G_Id /= Editor.Ada_Language_Model.No_Symbol,
              "first target for multi-entity Inline pragma should be retained");
      Assert (H_Id /= Editor.Ada_Language_Model.No_Symbol,
              "second target for multi-entity Inline pragma should be retained");
      Assert (J_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named target for entity-list Inline pragma should be retained");
      Assert (Imported_Named_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named Entity => target for Import pragma should be retained");
      Assert (Imported_Nested_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named Entity => target after nested expression associations should be retained");
      Assert (External_Named_Id /= Editor.Ada_Language_Model.No_Symbol,
              "named Entity => target for External pragma should be retained");
      Assert (Operator_Plus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "operator function target for quoted Import pragma should be retained");
      Assert (Scheduled_Id /= Editor.Ada_Language_Model.No_Symbol,
              "task target for current-scope scheduling pragmas should be retained");
      Assert (Guard_Id /= Editor.Ada_Language_Model.No_Symbol,
              "protected target for current-scope interrupt-priority pragma should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
         begin
            if Info.Target_Symbol = Rec_Id
              and then A = "Pack"
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Pragma_Pack := True;
            elsif Info.Target_Symbol = Rec_Id
              and then A = "Pack"
              and then To_String (Info.Item_Text) = "False"
            then
               Seen_Clause_Pack := True;
            elsif Info.Target_Symbol = Obj_Id and then A = "Atomic" then
               Seen_Pragma_Atomic := True;
            elsif Info.Target_Symbol = Obj_Id and then A = "Volatile" then
               Seen_Pragma_Volatile := True;
            elsif Info.Target_Symbol = P_Id and then A = "Suppress_Initialization" then
               Seen_Suppress := True;
            elsif Info.Target_Symbol = E_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Discard_Names_Clause
            then
               Seen_Discard_Names := True;
            elsif Info.Target_Symbol = F_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Volatile_Function_Clause
            then
               Seen_Volatile_Function := True;
            elsif Info.Target_Symbol = Hook_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Attach_Handler_Clause
              and then To_String (Info.Item_Text) = "Hook_Interrupt"
            then
               Seen_Attach_Handler_Named_Value := True;
            elsif Info.Target_Symbol = Obj_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Linker_Section_Clause
              and then To_String (Info.Item_Text) = """.fast"""
            then
               Seen_Linker_Section_Value := True;
            elsif Info.Target_Symbol = F_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Machine_Attribute_Clause
              and then To_String (Info.Item_Text) = """naked"""
            then
               Seen_Machine_Attribute_Value := True;
            elsif Info.Target_Symbol = Obj_Named_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Linker_Section_Clause
              and then To_String (Info.Item_Text) = """.named"""
            then
               Seen_Named_Linker_Section_Value := True;
            elsif Info.Target_Symbol = F_Named_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Machine_Attribute_Clause
              and then To_String (Info.Item_Text) = """interrupt"""
            then
               Seen_Named_Machine_Attribute_Value := True;
            elsif Info.Target_Symbol = G_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Inline_Clause
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Multi_Inline_G := True;
            elsif Info.Target_Symbol = H_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Inline_Clause
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Multi_Inline_H := True;
            elsif Info.Target_Symbol = J_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Inline_Clause
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Named_Inline_J := True;
            elsif Info.Target_Symbol = Imported_Named_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Import_Clause
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Named_Import_Target := True;
            elsif Info.Target_Symbol = Imported_Nested_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Import_Clause
              and then To_String (Info.Item_Text) = "True"
            then
               Seen_Nested_Named_Import_Target := True;
            elsif Info.Target_Symbol = External_Named_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_External_Name_Clause
              and then To_String (Info.Item_Text) = """external_named"""
            then
               Seen_Named_External_Target := True;
            elsif Info.Target_Symbol = Operator_Plus_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Import_Clause
            then
               Seen_Operator_Import_Target := True;
            elsif Info.Target_Symbol = P_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_SPARK_Mode_Clause
              and then To_String (Info.Item_Text) = "On"
            then
               Seen_Current_Scope_SPARK_Mode := True;
            elsif Info.Target_Symbol = P_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Assertion_Policy_Clause
              and then To_String (Info.Item_Text) = "Check"
            then
               Seen_Current_Scope_Assertion_Policy := True;
            elsif Info.Target_Symbol = Scheduled_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Priority_Clause
              and then To_String (Info.Item_Text) = "10"
            then
               Seen_Current_Scope_Priority_Value := True;
            elsif Info.Target_Symbol = Scheduled_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_CPU_Clause
              and then To_String (Info.Item_Text) = "2"
            then
               Seen_Current_Scope_CPU_Value := True;
            elsif Info.Target_Symbol = Scheduled_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Relative_Deadline_Clause
              and then To_String (Info.Item_Text) = "Milliseconds (10)"
            then
               Seen_Current_Scope_Relative_Deadline_Nested_Value := True;
            elsif Info.Target_Symbol = Scheduled_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Relative_Deadline_Clause
              and then To_String (Info.Item_Text) = "Milliseconds (Value => 11)"
            then
               Seen_Current_Scope_Relative_Deadline_Nested_Association_Value := True;
            elsif Info.Target_Symbol = Scheduled_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Relative_Deadline_Clause
              and then To_String (Info.Item_Text) = "Char_Delay (')')"
            then
               Seen_Current_Scope_Relative_Deadline_Character_Value := True;
            elsif Info.Target_Symbol = Guard_Id
              and then Info.Kind = Editor.Ada_Language_Model.Representation_Interrupt_Priority_Clause
              and then To_String (Info.Item_Text) = "7"
            then
               Seen_Current_Scope_Interrupt_Priority_Value := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, I);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Argument
              and then To_String (Info.Label) = "Char_Delay (')')"
            then
               Seen_Syntax_Tree_Pragma_Character_Argument := True;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Argument
              and then To_String (Info.Label) = """comma, kept"""
            then
               Seen_Syntax_Tree_Pragma_String_Comma_Argument := True;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Argument
              and then To_String (Info.Label) = """arrow => kept"""
            then
               Seen_Syntax_Tree_Pragma_String_Arrow_Argument := True;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Argument
              and then To_String (Info.Label) = """+"""
            then
               Seen_Syntax_Tree_Pragma_Operator_Target := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause =>
                  Seen_Duplicate := True;
               when Editor.Ada_Language_Model.Legality_Suppress_Initialization_Target_Incompatible =>
                  Seen_Suppress_Target := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Pragma_Pack,
              "pragma Pack should lower into Pack representation metadata with True value");
      Assert (Seen_Clause_Pack,
              "attribute-definition Pack clause should remain in the same metadata stream");
      Assert (Seen_Pragma_Atomic,
              "pragma Atomic should lower into Atomic representation metadata");
      Assert (Seen_Pragma_Volatile,
              "pragma Volatile should lower into Volatile representation metadata");
      Assert (Seen_Suppress,
              "pragma Suppress_Initialization should lower into common representation metadata");
      Assert (Seen_Discard_Names,
              "resolver-driven pragma lowering should cover Discard_Names without a parallel pragma kind table");
      Assert (Seen_Volatile_Function,
              "resolver-driven pragma lowering should cover Volatile_Function without a parallel pragma kind table");
      Assert (Seen_Attach_Handler_Named_Value,
              "named Attach_Handler pragma should retain the interrupt expression, not the handler entity, as the item value");
      Assert (Seen_Linker_Section_Value,
              "pragma Linker_Section should retain its section-name value rather than defaulting to True");
      Assert (Seen_Machine_Attribute_Value,
              "pragma Machine_Attribute should retain its machine attribute value rather than defaulting to True");
      Assert (Seen_Named_Linker_Section_Value,
              "named Linker_Section pragma should bind Entity => as target and Section => as value");
      Assert (Seen_Named_Machine_Attribute_Value,
              "named Machine_Attribute pragma should bind Entity => as target and Attribute_Name => as value");
      Assert (Seen_Multi_Inline_G and Seen_Multi_Inline_H,
              "multi-entity pragma Inline should lower representation metadata for every listed entity");
      Assert (Seen_Named_Inline_J,
              "named entity association in a Boolean entity pragma should lower to the named target");
      Assert (Seen_Named_Import_Target,
              "named Entity => Import pragma should bind the entity, not the convention argument, as the representation target");
      Assert (Seen_Nested_Named_Import_Target,
              "top-level Entity => Import target should ignore nested Entity => labels inside other argument expressions");
      Assert (Seen_Named_External_Target,
              "named Entity => External pragma should bind the entity even when External_Name appears first");
      Assert (Seen_Operator_Import_Target,
              "quoted operator targets in interfacing pragmas should bind to the operator declaration");
      Assert (Seen_Current_Scope_SPARK_Mode,
              "value-only SPARK_Mode pragma should bind to the current scope and retain its mode value");
      Assert (Seen_Current_Scope_Assertion_Policy,
              "value-only Assertion_Policy pragma should bind to the current scope and retain its policy value");
      Assert (Seen_Current_Scope_Priority_Value,
              "value-only Priority pragma should retain its first positional value on the enclosing task target");
      Assert (Seen_Current_Scope_CPU_Value,
              "value-only CPU pragma should retain its first positional value on the enclosing task target");
      Assert (Seen_Current_Scope_Relative_Deadline_Nested_Value,
              "value-only Relative_Deadline pragma should retain nested call expressions completely");
      Assert (Seen_Current_Scope_Relative_Deadline_Nested_Association_Value,
              "nested named associations inside a positional pragma value should not be mistaken for pragma argument associations");
      Assert (Seen_Current_Scope_Relative_Deadline_Character_Value,
              "character literals containing right parentheses should not truncate value-only pragma argument parsing");
      Assert (Seen_Syntax_Tree_Pragma_Character_Argument,
              "syntax-tree pragma argument retention should use the same string/character-literal-safe parenthesis matching");
      Assert (Seen_Syntax_Tree_Pragma_String_Comma_Argument,
              "syntax-tree pragma argument splitting should ignore commas inside string literals");
      Assert (Seen_Syntax_Tree_Pragma_String_Arrow_Argument,
              "syntax-tree pragma argument association detection should ignore arrows inside string literals");
      Assert (Seen_Syntax_Tree_Pragma_Operator_Target,
              "syntax-tree pragma argument retention should preserve quoted operator targets");
      Assert (Seen_Current_Scope_Interrupt_Priority_Value,
              "value-only Interrupt_Priority pragma should retain its first positional value on the enclosing protected target");
      Assert (Seen_Duplicate,
              "representation pragmas and attribute-definition clauses should share duplicate detection");
      Assert (Seen_Suppress_Target,
              "representation pragmas should share target-specific legality diagnostics");
   end Test_Language_Model_Representation_Pragma_Unification_Pass;






   procedure Test_Language_Model_Representation_Component_Pragma_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Vec is array (Positive range <>) of Integer;" & ASCII.LF &
        "   type Rec is null record;" & ASCII.LF &
        "   pragma Atomic_Components (Vec);" & ASCII.LF &
        "   type Aspect_Vec is array (1 .. 4) of Integer with Volatile_Components;" & ASCII.LF &
        "   for Vec'Atomic_Components use False;" & ASCII.LF &
        "   for Vec'Independent_Components use Maybe;" & ASCII.LF &
        "   for Rec'Volatile_Components use True;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Vec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Vec");
      Aspect_Vec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Aspect_Vec");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Seen_Pragma_Atomic_Components : Boolean := False;
      Seen_Clause_Atomic_Components : Boolean := False;
      Seen_Aspect_Volatile_Components : Boolean := False;
      Seen_Independent_Components : Boolean := False;
      Seen_Duplicate : Boolean := False;
      Seen_Array_Target : Boolean := False;
      Seen_Boolean_Value : Boolean := False;
   begin
      Assert (Vec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "array target for Atomic_Components should be retained");
      Assert (Aspect_Vec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "array target with Volatile_Components aspect should be retained");
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "non-array target should be retained for component pragma diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
            A : constant String := To_String (Info.Attribute_Name);
            V : constant String := To_String (Info.Item_Text);
         begin
            if Info.Target_Symbol = Vec_Id
              and then A = "Atomic_Components"
              and then V = "True"
            then
               Seen_Pragma_Atomic_Components := True;
            elsif Info.Target_Symbol = Vec_Id
              and then A = "Atomic_Components"
              and then V = "False"
            then
               Seen_Clause_Atomic_Components := True;
            elsif Info.Target_Symbol = Aspect_Vec_Id
              and then A = "Volatile_Components"
              and then V = "True"
            then
               Seen_Aspect_Volatile_Components := True;
            elsif Info.Target_Symbol = Vec_Id
              and then A = "Independent_Components"
              and then V = "Maybe"
            then
               Seen_Independent_Components := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause =>
                  Seen_Duplicate := True;
               when Editor.Ada_Language_Model.Legality_Atomic_Volatile_Target_Incompatible =>
                  Seen_Array_Target := True;
               when Editor.Ada_Language_Model.Legality_Atomic_Volatile_Boolean_Value_Required =>
                  Seen_Boolean_Value := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Pragma_Atomic_Components,
              "pragma Atomic_Components should lower into common representation metadata");
      Assert (Seen_Clause_Atomic_Components,
              "Atomic_Components attribute-definition clause should share the common metadata stream");
      Assert (Seen_Aspect_Volatile_Components,
              "Volatile_Components aspect should lower into common representation metadata");
      Assert (Seen_Independent_Components,
              "Independent_Components clause should be retained for common legality checking");
      Assert (Seen_Duplicate,
              "component pragmas and attribute-definition clauses should share duplicate detection");
      Assert (Seen_Array_Target,
              "component pragmas should require array type targets");
      Assert (Seen_Boolean_Value,
              "component pragmas/aspects should require static Boolean values");
   end Test_Language_Model_Representation_Component_Pragma_Unification_Pass;






   procedure Test_Language_Model_Synonym_Operational_Property_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Count is range 0 .. 10 with Predicate => Count > 0, Invariant => Count < 10;" & ASCII.LF &
        "   for Count'Predicate use Count /= 3;" & ASCII.LF &
        "   for Count'Invariant use Count /= 4;" & ASCII.LF &
        "   procedure Step (X : in out Count) with Precondition => X > 0, Postcondition => X > 1;" & ASCII.LF &
        "   for Step'Precondition use X < 8;" & ASCII.LF &
        "   for Step'Postcondition use X < 9;" & ASCII.LF &
        "   package Remote with All_Calls_Remote, No_Tagged_Streams, Extensions_Visible, Remote_Access_Type is" & ASCII.LF &
        "   end Remote;" & ASCII.LF &
        "   for Remote'All_Calls_Remote use False;" & ASCII.LF &
        "   for Remote'No_Tagged_Streams use False;" & ASCII.LF &
        "   for Remote'Extensions_Visible use False;" & ASCII.LF &
        "   for Remote'Remote_Access_Type use False;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Step_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Step");
      Remote_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Remote");
      Seen_Predicate_Aspect : Boolean := False;
      Seen_Predicate_Clause : Boolean := False;
      Seen_Invariant_Aspect : Boolean := False;
      Seen_Invariant_Clause : Boolean := False;
      Seen_Precondition_Aspect : Boolean := False;
      Seen_Precondition_Clause : Boolean := False;
      Seen_Postcondition_Aspect : Boolean := False;
      Seen_Postcondition_Clause : Boolean := False;
      Seen_All_Calls_Remote_Aspect : Boolean := False;
      Seen_All_Calls_Remote_Clause : Boolean := False;
      Seen_No_Tagged_Streams_Aspect : Boolean := False;
      Seen_No_Tagged_Streams_Clause : Boolean := False;
      Seen_Extensions_Visible_Aspect : Boolean := False;
      Seen_Extensions_Visible_Clause : Boolean := False;
      Seen_Remote_Access_Type_Aspect : Boolean := False;
      Seen_Remote_Access_Type_Clause : Boolean := False;
   begin
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Count type should be retained");
      Assert (Step_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Step procedure should be retained");
      Assert (Remote_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Remote nested package should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if R.Target_Symbol = Count_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Predicate_Clause
            then
               if To_String (R.Item_Text) = "Count > 0" then
                  Seen_Predicate_Aspect := True;
               elsif To_String (R.Item_Text) = "Count /= 3" then
                  Seen_Predicate_Clause := True;
               end if;
            elsif R.Target_Symbol = Count_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Invariant_Clause
            then
               if To_String (R.Item_Text) = "Count < 10" then
                  Seen_Invariant_Aspect := True;
               elsif To_String (R.Item_Text) = "Count /= 4" then
                  Seen_Invariant_Clause := True;
               end if;
            elsif R.Target_Symbol = Step_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Precondition_Clause
            then
               if To_String (R.Item_Text) = "X > 0" then
                  Seen_Precondition_Aspect := True;
               elsif To_String (R.Item_Text) = "X < 8" then
                  Seen_Precondition_Clause := True;
               end if;
            elsif R.Target_Symbol = Step_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Postcondition_Clause
            then
               if To_String (R.Item_Text) = "X > 1" then
                  Seen_Postcondition_Aspect := True;
               elsif To_String (R.Item_Text) = "X < 9" then
                  Seen_Postcondition_Clause := True;
               end if;
            elsif R.Target_Symbol = Remote_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_All_Calls_Remote_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_All_Calls_Remote_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_All_Calls_Remote_Clause := True;
               end if;
            elsif R.Target_Symbol = Remote_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Tagged_Streams_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_No_Tagged_Streams_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_No_Tagged_Streams_Clause := True;
               end if;
            elsif R.Target_Symbol = Remote_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Extensions_Visible_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_Extensions_Visible_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_Extensions_Visible_Clause := True;
               end if;
            elsif R.Target_Symbol = Remote_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Remote_Access_Type_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_Remote_Access_Type_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_Remote_Access_Type_Clause := True;
               end if;
            end if;
         end;
      end loop;

      Assert (Seen_Predicate_Aspect and then Seen_Predicate_Clause,
              "Predicate aspect and attribute clause should share the explicit kind");
      Assert (Seen_Invariant_Aspect and then Seen_Invariant_Clause,
              "Invariant aspect and attribute clause should share the explicit kind");
      Assert (Seen_Precondition_Aspect and then Seen_Precondition_Clause,
              "Precondition aspect and attribute clause should share the explicit kind");
      Assert (Seen_Postcondition_Aspect and then Seen_Postcondition_Clause,
              "Postcondition aspect and attribute clause should share the explicit kind");
      Assert (Seen_All_Calls_Remote_Aspect and then Seen_All_Calls_Remote_Clause,
              "All_Calls_Remote aspect and attribute clause should share the explicit kind");
      Assert (Seen_No_Tagged_Streams_Aspect and then Seen_No_Tagged_Streams_Clause,
              "No_Tagged_Streams aspect and attribute clause should share the explicit kind");
      Assert (Seen_Extensions_Visible_Aspect and then Seen_Extensions_Visible_Clause,
              "Extensions_Visible aspect and attribute clause should share the explicit kind");
      Assert (Seen_Remote_Access_Type_Aspect and then Seen_Remote_Access_Type_Clause,
              "Remote_Access_Type aspect and attribute clause should share the explicit kind");
   end Test_Language_Model_Synonym_Operational_Property_Unification_Pass;




   procedure Test_Language_Model_Task_Protected_Storage_Operational_Unification_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Worker_State is limited record" & ASCII.LF &
        "      Done : Boolean;" & ASCII.LF &
        "   end record with No_Task_Parts;" & ASCII.LF &
        "   for Worker_State'No_Task_Parts use False;" & ASCII.LF &
        "   protected type Lock with Exclusive_Functions is" & ASCII.LF &
        "      function Busy return Boolean;" & ASCII.LF &
        "   end Lock;" & ASCII.LF &
        "   for Lock'Exclusive_Functions use False;" & ASCII.LF &
        "   type Pool is tagged null record with Simple_Storage_Pool_Type;" & ASCII.LF &
        "   for Pool'Simple_Storage_Pool_Type use False;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker_State");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Lock");
      Pool_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Pool");
      Seen_No_Task_Aspect : Boolean := False;
      Seen_No_Task_Clause : Boolean := False;
      Seen_Exclusive_Aspect : Boolean := False;
      Seen_Exclusive_Clause : Boolean := False;
      Seen_Simple_Pool_Aspect : Boolean := False;
      Seen_Simple_Pool_Clause : Boolean := False;
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Worker_State type should be retained");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Lock protected type should be retained");
      Assert (Pool_Id /= Editor.Ada_Language_Model.No_Symbol,
              "Pool type should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if R.Target_Symbol = Worker_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_No_Task_Parts_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_No_Task_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_No_Task_Clause := True;
               end if;
            elsif R.Target_Symbol = Lock_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Exclusive_Functions_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_Exclusive_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_Exclusive_Clause := True;
               end if;
            elsif R.Target_Symbol = Pool_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Simple_Storage_Pool_Type_Clause
            then
               if To_String (R.Item_Text) = "True" then
                  Seen_Simple_Pool_Aspect := True;
               elsif To_String (R.Item_Text) = "False" then
                  Seen_Simple_Pool_Clause := True;
               end if;
            end if;
         end;
      end loop;

      Assert (Seen_No_Task_Aspect and then Seen_No_Task_Clause,
              "No_Task_Parts aspect and attribute clause should share the explicit kind");
      Assert (Seen_Exclusive_Aspect and then Seen_Exclusive_Clause,
              "Exclusive_Functions aspect and attribute clause should share the explicit kind");
      Assert (Seen_Simple_Pool_Aspect and then Seen_Simple_Pool_Clause,
              "Simple_Storage_Pool_Type aspect and attribute clause should share the explicit kind");
   end Test_Language_Model_Task_Protected_Storage_Operational_Unification_Pass;


   overriding function Name (T : Representation_Unification_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Representation.Unification");
   end Name;

   overriding procedure Register_Tests (T : in out Representation_Unification_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Representation_Aspect_Unification'Access, Name => "Ada representation legality unifies aspects and attribute definition clauses");
      Add_Test (Routine => Test_Language_Model_Aspect_Attribute_Definition_Unification_Pass'Access, Name => "language model unifies aspects and attribute definition clauses");
      Add_Test (Routine => Test_Language_Model_Representation_Operational_Property_Unification_Pass'Access, Name => "language model unifies representation and operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_Literal_Storage_Operational_Unification_Pass'Access, Name => "language model unifies literal and storage-model operational properties");
      Add_Test (Routine => Test_Language_Model_Predicate_Invariant_Operational_Unification_Pass'Access, Name => "language model unifies predicate and invariant operational properties");
      Add_Test (Routine => Test_Language_Model_Contract_Operational_Unification_Pass'Access, Name => "language model unifies contract operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_Remaining_Operational_Property_Unification_Pass'Access, Name => "language model unifies remaining operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_State_Ownership_Operational_Unification_Pass'Access, Name => "language model unifies state and ownership operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_Subprogram_Library_Operational_Unification_Pass'Access, Name => "language model unifies subprogram and library-unit operational properties");
      Add_Test (Routine => Test_Language_Model_Representation_Pragma_Unification_Pass'Access, Name => "language model unifies representation pragmas with attribute definition clauses");
      Add_Test (Routine => Test_Language_Model_Representation_Component_Pragma_Unification_Pass'Access, Name => "language model unifies component representation pragmas and aspects");
      Add_Test (Routine => Test_Language_Model_Synonym_Operational_Property_Unification_Pass'Access, Name => "language model unifies synonym operational properties across aspects and attribute clauses");
      Add_Test (Routine => Test_Language_Model_Task_Protected_Storage_Operational_Unification_Pass'Access, Name => "language model unifies task/protected/storage operational properties across aspects and attribute clauses");
   end Register_Tests;

end Editor.Syntax_Semantics.Representation_Unification_Tests;
