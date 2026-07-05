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

package body Editor.Syntax_Semantics.Token_Cursor_Concurrent_Statement_Tests is

   procedure Test_Language_Model_Token_Cursor_Concurrent_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "task type Worker is" & ASCII.LF &
        "   entry Start;" & ASCII.LF &
        "   entry Work (Index range 1 .. 10) (Value : Integer);" & ASCII.LF &
        "end Worker;" & ASCII.LF &
        "protected type Lock is" & ASCII.LF &
        "   procedure Set (Value : Integer);" & ASCII.LF &
        "   function Get return Integer;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Stored : Integer;" & ASCII.LF &
        "end Lock;" & ASCII.LF &
        "entry Work (I : Integer) when Ready is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Work;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Definition),
              "token-cursor grammar must retain task definitions instead of skipping task entries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Definition),
              "token-cursor grammar must retain protected definitions instead of skipping protected operations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Declaration),
              "token-cursor grammar must parse entries inside task/protected definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Identifier),
              "entry declarations and bodies must retain the entry identifier position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Definition),
              "token-cursor grammar must parse entry-family definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Discrete_Subtype_Definition),
              "entry-family declarations must retain their discrete subtype definition position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Parameter_Profile),
              "entry declarations and bodies must retain their parameter profile position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier),
              "token-cursor grammar must parse entry-body barriers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration),
              "token-cursor grammar must continue parsing protected operation declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Part),
              "token-cursor grammar must continue parsing protected private parts");
   end Test_Language_Model_Token_Cursor_Concurrent_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "entry Wait when Ready and Count < Limit is separate;" & ASCII.LF &
        "After : Integer;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body),
              "entry bodies with barriers must remain entry bodies");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier),
              "entry body barriers must retain the barrier production");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier_Condition),
              "entry body barriers must retain the barrier condition position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Short_Circuit_Operation),
              "barrier conditions must continue through normal expression parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue after entry body stubs with barriers");
   end Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Entry_Index_And_Accept_Grammar
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Queue is" & ASCII.LF &
        "   entry Take (for Slot in Positive) (Value : out Integer) when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Nested (Slot) (Value : out Integer) do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Nested;" & ASCII.LF &
        "   end Take;" & ASCII.LF &
        "end Queue;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body),
              "entry bodies with index specifications must remain entry bodies");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Index_Specification),
              "entry body and accept entry-index grammar must be retained separately from parameter profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile),
              "entry body parameter profiles after entry indexes must still be parsed");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Statement),
              "accept statements with entry indexes must be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Statement_Sequence),
              "accept do-parts must retain their nested statement sequence marker");
   end Test_Language_Model_Token_Cursor_Entry_Index_And_Accept_Grammar;

   procedure Test_Language_Model_Token_Cursor_Task_Protected_Type_Header_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Concurrent_Type_Header_Grammar is" & ASCII.LF &
        "   task type Worker (Id : Positive) is" & ASCII.LF &
        "      entry Start;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected type Gate (Limit : Natural) is" & ASCII.LF &
        "      entry Wait;" & ASCII.LF &
        "      procedure Open;" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Count : Natural := 0;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "end Concurrent_Type_Header_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Type_Declaration),
              "task type headers must be retained separately from single task declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Type_Declaration),
              "protected type headers must be retained separately from single protected declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part),
              "task/protected type discriminant parts must be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Declaration),
              "entries nested in concurrent type definitions must remain visible to the grammar layer");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Part),
              "protected private parts must still be retained after protected type header parsing");
   end Test_Language_Model_Token_Cursor_Task_Protected_Type_Header_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Select_Alternative_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Select_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   select" & ASCII.LF &
        "      when Ready =>" & ASCII.LF &
        "         accept Take;" & ASCII.LF &
        "   or" & ASCII.LF &
        "      accept Family (Index) (Value : in Integer) do" & ASCII.LF &
        "         Value := Value + 1;" & ASCII.LF &
        "      end Family;" & ASCII.LF &
        "   or" & ASCII.LF &
        "      delay until Deadline;" & ASCII.LF &
        "   else" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   select" & ASCII.LF &
        "      terminate;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   select" & ASCII.LF &
        "      Trigger;" & ASCII.LF &
        "   then abort" & ASCII.LF &
        "      Work;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "end Select_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Statement),
              "select statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Alternative),
              "select alternatives must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard),
              "select guards must be parsed as condition expressions, not case choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard_Condition),
              "select guards must retain the condition expression position explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Alternative_Statement_Sequence),
              "select alternatives must retain their statement-sequence position explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Else_Part),
              "conditional select else parts must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Else_Statement_Sequence),
              "conditional select else parts must retain their statement-sequence position explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Terminate_Alternative),
              "terminate alternatives must not be flattened to null statements only");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abortable_Part),
              "asynchronous select then-abort parts must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abortable_Statement_Sequence),
              "asynchronous select abortable parts must retain their statement-sequence position explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Until_Statement),
              "timed select alternatives must retain their delay-until statement grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Entry_Name),
              "accept statements must retain the accepted entry name explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Entry_Index),
              "accept statements for entry families must retain entry index expressions explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Parameter_Profile),
              "accept statements must retain optional accept parameter profiles explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Statement_Sequence),
              "accept statements with do parts must retain handled statement sequences explicitly");
   end Test_Language_Model_Token_Cursor_Select_Alternative_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Task_Protected_Body_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Concurrent_Internals is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "      procedure Local_Hook;" & ASCII.LF &
        "      Local : Integer := 0;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Local := Local + 1;" & ASCII.LF &
        "   exception" & ASCII.LF &
        "      when Program_Error =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected body Gate is" & ASCII.LF &
        "      procedure Open is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Open;" & ASCII.LF &
        "      entry Wait when True is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Wait;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   protected body Broken_Gate is" & ASCII.LF &
        "   private" & ASCII.LF &
        "      procedure Close is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Close;" & ASCII.LF &
        "   end Broken_Gate;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Concurrent_Internals;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);

      function Count_Production
        (Kind : Editor.Ada_Token_Cursor.Production_Kind) return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Token_Cursor.Production_Count (Grammar) loop
            if Editor.Ada_Token_Cursor.Production_At (Grammar, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Production;
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body),
              "task bodies must remain classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Name),
              "task body names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Declarative_Part),
              "task body declarative parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Declarative_Item_Start),
              "task body declarative-item starts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Begin_Keyword),
              "task body begin keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Statement_Sequence),
              "task body statement sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Exception_Part),
              "task body exception parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_End_Keyword),
              "task body end keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body),
              "protected bodies must remain classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Name),
              "protected body names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_Part),
              "protected body operation parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_Begin_Keyword),
              "protected operation body begin keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_End_Keyword),
              "protected operation body end keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Recovery_Boundary),
              "misplaced protected-body private sections must retain a recovery boundary");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Body) >= 1,
              "protected operation bodies must continue to parse inside protected bodies");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier_Condition),
              "entry bodies inside protected bodies must retain barrier conditions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after concurrent bodies");
   end Test_Language_Model_Token_Cursor_Task_Protected_Body_Internal_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Task_Protected_Definition_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Concurrent_Specs is" & ASCII.LF &
        "   task type Worker (Priority : Integer) is" & ASCII.LF &
        "      entry Start (Value : Integer);" & ASCII.LF &
        "   private" & ASCII.LF &
        "      entry Stop;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected type Gate is" & ASCII.LF &
        "      procedure Open;" & ASCII.LF &
        "      entry Wait (Value : Integer);" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Closed : Boolean := True;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Concurrent_Specs;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Definition),
              "task definitions must remain classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Definition_Public_Part),
              "task definition public parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Definition_Private_Part),
              "task definition private parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Definition),
              "protected definitions must remain classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Definition_Public_Part),
              "protected definition public parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Definition_Private_Part),
              "protected definition private parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part),
              "task and protected type discriminant parts must still parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Parameter_Profile),
              "entry declarations inside concurrent definitions must retain parameter profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after concurrent specs");
   end Test_Language_Model_Token_Cursor_Task_Protected_Definition_Internal_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Task_Protected_Deep_Grammar_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Concurrent_Deep is" & ASCII.LF &
        "   protected body Gate is" & ASCII.LF &
        "      procedure Open with Pre => True is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Open;" & ASCII.LF &
        "      entry Wait (Positive) (Value : Integer) when Value > 0 is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Wait;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         accept Start (Value : Integer) do" & ASCII.LF &
        "            null;" & ASCII.LF &
        "         end Start;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay 1.0;" & ASCII.LF &
        "      then abort" & ASCII.LF &
        "         requeue Gate.Wait (1) with abort;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Concurrent_Deep;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Operation_Declaration),
              "protected body operations must be retained as protected operation declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Operation_Aspect_Specification),
              "protected operation aspects must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Index_Subtype),
              "entry family index subtype markers must be retained separately from profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Entry_Barrier),
              "protected entry barriers must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Do_Part),
              "accept statements with bodies must retain the do-part marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Or_Alternative),
              "select-or alternatives must be distinguished structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Then_Abort_Part),
              "then-abort alternatives must retain their own structural marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_With_Abort),
              "requeue-with-abort inside tasking alternatives must still parse");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "task/protected grammar recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Task_Protected_Deep_Grammar_Pass;

   procedure Test_Language_Model_Token_Cursor_Entry_Select_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Entry_Select_Depth is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Gate.Wait (Index => 1);" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay until Deadline;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Gate.Read (1) (Value);" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         when Ready => accept Start;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         terminate;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Entry_Select_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Entry_Call_Alternative),
              "select alternatives containing entry calls must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Timed_Entry_Call_Alternative),
              "timed entry call delay alternatives must be distinguished structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Entry_Call_Alternative),
              "conditional entry call else alternatives must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Delay_Alternative),
              "delay and terminate alternatives in select statements must retain tasking-alternative markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Entry_Name),
              "entry-call target names must be retained separately from generic call targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Index),
              "entry-family indexes or indexed entry-call prefixes must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard),
              "select guards must continue to parse with entry/terminate alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "entry/select grammar recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Entry_Select_Depth_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Select_Alternative_Depth is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         when Ready =>" & ASCII.LF &
        "            accept Start do" & ASCII.LF &
        "               null;" & ASCII.LF &
        "            end Start;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay until Deadline;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay 0.25;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         terminate;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Gate.Wait;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Gate.Stop;" & ASCII.LF &
        "      then abort" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Select_Alternative_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_First_Alternative),
              "select statements must retain a distinct first alternative marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Accept_Alternative),
              "accept alternatives inside select statements must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard_Arrow),
              "guard arrows in select alternatives must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Delay_Until_Alternative),
              "delay-until select alternatives must be distinguished structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Delay_Relative_Alternative),
              "relative-delay select alternatives must be distinguished structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Terminate_Alternative),
              "terminate alternatives must be retained as select alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Else_Part),
              "conditional select else parts must remain explicit");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Then_Abort_Part),
              "asynchronous select then-abort parts must remain explicit");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Alternative_Null_Statement),
              "null statements inside select alternatives must be marked for recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "select-statement recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth;

   procedure Test_Language_Model_Token_Cursor_Anonymous_Access_Protected_Profile_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Anonymous_Access_Protected_Profile_Depth is" & ASCII.LF &
        "   type Protected_Handler is access protected procedure" & ASCII.LF &
        "     (Value : in out Integer;" & ASCII.LF &
        "      Next : not null access protected function (Item : Integer) return Boolean := Default_Filter);" & ASCII.LF &
        "   type Protected_Factory is access protected function" & ASCII.LF &
        "     (Seed : Integer := 1) return not null access protected procedure (Item : Integer);" & ASCII.LF &
        "   Broken : access protected;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Anonymous_Access_Protected_Profile_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);

      function Count_Production
        (Kind : Editor.Ada_Token_Cursor.Production_Kind) return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Token_Cursor.Production_Count (Grammar) loop
            if Editor.Ada_Token_Cursor.Production_At (Grammar, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Production;
   begin
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Protected_Subprogram_Definition) >= 4,
              "protected anonymous access-to-subprogram forms must retain a protected-subprogram marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Protected_Procedure_Profile) >= 2,
              "protected anonymous access-to-procedure profiles must be classified distinctly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Protected_Function_Profile) >= 2,
              "protected anonymous access-to-function profiles must be classified distinctly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Result_Profile) >= 2,
              "protected access-to-function result profiles must remain explicit");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Subprogram_Profile_Recovery_Boundary),
              "dangling access protected forms must produce bounded protected-profile recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after protected anonymous access profiles");
   end Test_Language_Model_Token_Cursor_Anonymous_Access_Protected_Profile_Depth;

   procedure Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Entry_Family_Depth is" & ASCII.LF &
        "   protected type Gate is" & ASCII.LF &
        "      entry Start (1 .. 4) (Value : in Integer);" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Ready : Boolean := True;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   protected body Gate is" & ASCII.LF &
        "      entry Start (for Index in 1 .. 4) (Value : in Integer) when Ready is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Start;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   procedure Run (Obj : in out Gate) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Start (2) (Value : in Integer) do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Start;" & ASCII.LF &
        "      Obj.Start (3) (Value => 10);" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Obj.Start (4) (11);" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Entry_Family_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Definition),
              "entry family declarations must retain the family definition marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Range_Definition),
              "entry family declarations using ranges must retain range metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Index_Specification),
              "entry bodies and accept statements must retain entry index specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Index_Identifier),
              "entry bodies must retain their entry index identifier marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Index_Subtype),
              "entry bodies must retain their entry index subtype marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier_When_Keyword),
              "entry barriers must retain their when-keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Entry_Index_Expression),
              "accept statements must retain the entry index expression separately from parameter profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Selected_Target),
              "selected entry calls must retain selected target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Selected_Entry_Name),
              "selected entry calls must retain selected entry-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Family_Index),
              "entry family calls must retain index metadata distinct from actual parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Entry_Call_Alternative),
              "parser recovery must continue into selected entry calls inside select alternatives");
   end Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth;

   procedure Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Operation_End_Detail is" & ASCII.LF &
        "   procedure Set is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if Ready then" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "   end Set;" & ASCII.LF &
        "   function Is_Ready return Boolean is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Ready;" & ASCII.LF &
        "   end Is_Ready;" & ASCII.LF &
        "   entry Wait when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Wait" & ASCII.LF &
        "end Operation_End_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);

      function Count_Production
        (Kind : Editor.Ada_Token_Cursor.Production_Kind) return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Token_Cursor.Production_Count (Grammar) loop
            if Editor.Ada_Token_Cursor.Production_At (Grammar, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Production;
   begin
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_End_Keyword) >= 3,
              "protected operation bodies must retain operation end-keyword metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_End_Name) >= 3,
              "protected operation bodies must retain optional end-name metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_End_Terminator) >= 2,
              "well-formed protected operation bodies must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary),
              "in-progress protected operation bodies must retain missing end-terminator recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_End_Keyword),
              "operation end recovery must not consume the enclosing protected body end");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_End_Terminator),
              "operation end recovery must leave the protected body terminator visible");
   end Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail;

   procedure Test_Language_Model_Token_Cursor_Protected_Body_Operation_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Guarded is" & ASCII.LF &
        "   procedure Set is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Ready := True;" & ASCII.LF &
        "   end Set;" & ASCII.LF &
        "   function Is_Ready return Boolean is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Ready;" & ASCII.LF &
        "   end Is_Ready;" & ASCII.LF &
        "   entry Wait when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Wait;" & ASCII.LF &
        "end Guarded;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body),
              "protected bodies must retain their existing structural metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_Part),
              "protected bodies with operations must retain an operation part");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Procedure_Body),
              "protected procedure bodies must be classified separately from declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Function_Body),
              "protected function bodies must be classified separately from declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Entry_Body),
              "protected entry bodies must be classified separately from declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Entry_Barrier),
              "protected entry bodies must retain barrier metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Entry_Barrier_Condition),
              "protected entry barriers must retain their condition start structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_Begin_Keyword),
              "protected operation bodies must retain begin-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_End_Keyword),
              "protected operation bodies must retain end-keyword metadata");
   end Test_Language_Model_Token_Cursor_Protected_Body_Operation_Depth;

   procedure Test_Language_Model_Token_Cursor_Asynchronous_Select_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Async_Selects is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   select" & ASCII.LF &
        "      delay until Deadline;" & ASCII.LF &
        "   then abort" & ASCII.LF &
        "      Work;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "end Async_Selects;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Asynchronous_Select_Statement),
              "asynchronous select statements must retain a family-specific marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Asynchronous_Select_Triggering_Alternative),
              "asynchronous select triggering alternatives must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Asynchronous_Select_Delay_Trigger),
              "delay triggering statements inside asynchronous selects must be distinguished");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Asynchronous_Select_Abortable_Part),
              "asynchronous select abortable parts must retain a family-specific marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Then_Abort_Part),
              "asynchronous selects must preserve shared then-abort metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Until_Statement),
              "triggering delay statements must retain ordinary delay metadata");
   end Test_Language_Model_Token_Cursor_Asynchronous_Select_Depth;

   procedure Test_Language_Model_Token_Cursor_Entry_Procedure_Call_Ambiguity_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Entry_Procedure_Call_Ambiguity is" & ASCII.LF &
        "   type Table is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Store : Table (1 .. 10);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Worker.Start (Priority => 1);" & ASCII.LF &
        "   Pool.Worker (Slot) (Payload);" & ASCII.LF &
        "   Obj.Op (Arg);" & ASCII.LF &
        "   Store (Index);" & ASCII.LF &
        "end Entry_Procedure_Call_Ambiguity;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);

      function Count_Production
        (Kind : Editor.Ada_Token_Cursor.Production_Kind) return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Token_Cursor.Production_Count (Grammar) loop
            if Editor.Ada_Token_Cursor.Production_At (Grammar, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Production;
   begin
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Call_Statement) >= 4,
              "procedure-call and entry-call shaped statements must remain calls");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Selected_Prefix),
              "selected call prefixes must be retained separately from operation names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Selected_Operation_Name),
              "selected call operation names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Dispatching_Prefix),
              "dispatching-style call prefixes must be retained without semantic lookup");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Indexed_Prefix),
              "indexed call prefixes must be retained for call/index ambiguity metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_List),
              "call actual/index lists must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Entry_Family_Ambiguity),
              "entry-family versus procedure-call ambiguity must be exposed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_Association),
              "named call actual associations must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Family_Index),
              "entry-family call index metadata from earlier passes must remain intact");
   end Test_Language_Model_Token_Cursor_Entry_Procedure_Call_Ambiguity_Metadata;

   overriding function Name (T : TokenCursorConcurrentStatement_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Token-Cursor-Concurrent-Statement");
   end Name;

   overriding procedure Register_Tests (T : in out TokenCursorConcurrentStatement_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Concurrent_Grammar_Completeness'Access, Name => "token-cursor grammar parses task protected and entry-family definitions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Grammar_Completeness'Access, Name => "token-cursor grammar parses entry barrier conditions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Index_And_Accept_Grammar'Access, Name => "token-cursor grammar parses entry indexes and accept statements structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Task_Protected_Type_Header_Grammar_Completeness'Access, Name => "token-cursor grammar parses task/protected type headers with discriminants structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Select_Alternative_Grammar_Completeness'Access, Name => "token-cursor grammar parses select guards else terminate and abortable alternatives structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Task_Protected_Body_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar parses task and protected body internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Task_Protected_Definition_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar parses task and protected definition parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Task_Protected_Deep_Grammar_Pass'Access, Name => "token-cursor grammar deepens task/protected operation, entry, accept, and select alternatives");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Select_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens entry calls and timed conditional select alternatives");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth'Access, Name => "token-cursor grammar deepens select statement alternatives structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Anonymous_Access_Protected_Profile_Depth'Access, Name => "token-cursor grammar deepens protected anonymous access-to-subprogram profiles");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth'Access, Name => "token-cursor grammar deepens entry family index and selected entry-call metadata structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail'Access, Name => "token-cursor grammar deepens protected operation body end-name and terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Protected_Body_Operation_Depth'Access, Name => "token-cursor grammar classifies protected body operation bodies structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Asynchronous_Select_Depth'Access, Name => "token-cursor grammar classifies asynchronous select statements structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Procedure_Call_Ambiguity_Metadata'Access, Name => "token-cursor grammar retains entry/procedure call ambiguity metadata");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Concurrent_Statement_Tests;
