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

package body Editor.Syntax_Semantics.Token_Cursor_Declaration_Tests is




   procedure Test_Language_Model_Token_Cursor_Context_And_Label_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ada.Text_IO, Ada.Strings.Unbounded;" & ASCII.LF &
        "use Ada.Text_IO;" & ASCII.LF &
        "use type Ada.Strings.Unbounded.Unbounded_String;" & ASCII.LF &
        "use all type Ada.Strings.Unbounded.Unbounded_String;" & ASCII.LF &
        "procedure Context_Label_Demo is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   <<Again>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Context_Label_Demo;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_With_Clause),
              "token-cursor grammar must retain with-clause productions separately from coarse context clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Clause),
              "token-cursor grammar must retain ordinary use-clause productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Type_Clause),
              "token-cursor grammar must retain use type clause productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_All_Type_Clause),
              "token-cursor grammar must retain Ada 2012 use all type clause productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Package_Name_List),
              "ordinary use clauses must retain a structural package-name list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark_List),
              "use type clauses must retain a structural subtype-mark list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_All_Type_Prefix),
              "use all type clauses must retain the all type prefix explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "context-clause names must be parsed as selected-name grammar, not skipped as raw text");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label),
              "token-cursor grammar must retain label productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Name),
              "token-cursor grammar must retain label-name productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Labeled_Statement),
              "token-cursor grammar must retain labeled-statement productions");
   end Test_Language_Model_Token_Cursor_Context_And_Label_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Declarative_Use_Clause_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Declarative_Use_Clauses is" & ASCII.LF &
        "   use Ada.Text_IO, Ada.Strings.Unbounded;" & ASCII.LF &
        "   use type Interfaces.Unsigned_32, Interfaces.Unsigned_64;" & ASCII.LF &
        "   use all type Ada.Strings.Unbounded.Unbounded_String'Class;" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "end Declarative_Use_Clauses;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Clause),
              "declarative use clauses must be parsed as use clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Type_Clause),
              "declarative use type clauses must be parsed as use type clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_All_Type_Clause),
              "declarative use all type clauses must be parsed as use all type clauses");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Package_Name_List) >= 1,
              "declarative use clauses must retain an explicit package-name list");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark_List) >= 2,
              "declarative use type forms must retain subtype-mark list productions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Package_Name) >= 2,
              "declarative ordinary use clauses must retain comma-separated package names");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark) >= 3,
              "declarative use type clauses must retain each subtype mark");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Context_Clause) = 0,
              "declarative use clauses must not be reported as context clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue after declarative use clauses");
   end Test_Language_Model_Token_Cursor_Declarative_Use_Clause_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Spec_Contract (X : Integer) with Pre => X > 0, Global => null;" & ASCII.LF &
        "function Spec_Result return Integer with Post => Spec_Result'Result > 0;" & ASCII.LF &
        "procedure Body_Contract (X : Integer) with Pre => X > 0, Depends => (null => X) is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Body_Contract;" & ASCII.LF &
        "function Body_Result return Integer with Post => Body_Result'Result > 0 is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   return 1;" & ASCII.LF &
        "end Body_Result;";
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
                (Editor.Ada_Token_Cursor.Production_Subprogram_Declaration_Aspect_Specification) >= 2,
              "subprogram specs must expose subprogram-specific aspect placement");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Body_Aspect_Specification) >= 2,
              "subprogram bodies must expose subprogram-body-specific aspect placement before is");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Contract_Aspect_Placement) >= 4,
              "contract aspects on specs and bodies must expose subprogram contract placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Contract_Aspect_Association),
              "subprogram contract placement must preserve contract aspect associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Global_Aspect_Expression),
              "subprogram declaration contract placement must preserve Global aspect payload metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Depends_Aspect_Expression),
              "subprogram body contract placement must preserve Depends aspect payload metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body),
              "subprogram body contract placement must preserve body metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration_Terminator),
              "subprogram spec contract placement must preserve declaration terminators");
   end Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement;




   procedure Test_Language_Model_Token_Cursor_Separate_And_Body_Stub_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Parent.Child is separate;" & ASCII.LF &
        "procedure Work is separate;" & ASCII.LF &
        "task body Worker is separate;" & ASCII.LF &
        "protected body Lock is separate;" & ASCII.LF &
        "entry Start when Ready is separate;" & ASCII.LF &
        "separate (Parent.Child)" & ASCII.LF &
        "procedure Helper is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Helper;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Subunit),
              "token-cursor grammar must parse separate subunits as first-class productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Stub),
              "token-cursor grammar must parse package body stubs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Stub),
              "token-cursor grammar must parse subprogram body stubs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Stub),
              "token-cursor grammar must parse task body stubs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Stub),
              "token-cursor grammar must parse protected body stubs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Stub),
              "token-cursor grammar must parse entry body stubs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "separate parent unit names must be parsed as selected-name grammar");
   end Test_Language_Model_Token_Cursor_Separate_And_Body_Stub_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Body_Stub_Separate_Subunit_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Stubbed.Child is separate;" & ASCII.LF &
        "procedure Do_Work (X : Integer) is separate;" & ASCII.LF &
        "function Make return Integer is separate;" & ASCII.LF &
        "task body Worker is separate;" & ASCII.LF &
        "protected body Lock is separate;" & ASCII.LF &
        "entry Start (Index) when Ready is separate;" & ASCII.LF &
        "separate (Stubbed.Child)" & ASCII.LF &
        "package body Nested is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Nested;" & ASCII.LF &
        "separate (Stubbed.Child)" & ASCII.LF &
        "procedure Helper is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Helper;" & ASCII.LF &
        "separate (Stubbed.Child)" & ASCII.LF &
        "task body Nested_Worker is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Nested_Worker;" & ASCII.LF &
        "separate (Stubbed.Child)" & ASCII.LF &
        "protected body Nested_Lock is" & ASCII.LF &
        "   procedure Set is null;" & ASCII.LF &
        "end Nested_Lock;" & ASCII.LF &
        "separate (Stubbed.Child)" & ASCII.LF &
        "entry Nested_Entry when Ready is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Nested_Entry;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Body_Stub_Separate_Keyword),
              "body stubs must retain the separate completion keyword structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Parent_Unit_Name),
              "separate subunits must retain the parent unit name structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Body_Declaration),
              "separate subunits must retain the nested body declaration boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Package_Body),
              "separate package bodies must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Subprogram_Body),
              "separate subprogram bodies must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Task_Body),
              "separate task bodies must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Protected_Body),
              "separate protected bodies must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Entry_Body),
              "separate entry bodies must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Stub),
              "subprogram body stubs must remain classified as stubs, not full bodies only");
   end Test_Language_Model_Token_Cursor_Body_Stub_Separate_Subunit_Depth_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Subprogram_Body_Declarative_Part_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Body_Depth is" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 10;" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "      procedure Touch;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "   procedure Helper is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Helper;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Helper;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when others => null;" & ASCII.LF &
        "end Body_Depth;" & ASCII.LF &
        "procedure Broken_Body is" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "end Broken_Body;" & ASCII.LF &
        "procedure After is begin null; end After;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body),
              "subprogram bodies must remain classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Declarative_Part),
              "subprogram bodies must retain their declarative part boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Declarative_Item),
              "subprogram body declarative items must be marked explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Begin_Keyword),
              "subprogram body begin keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Statement_Sequence),
              "subprogram body handled statement sequences must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Exception_Part),
              "subprogram body exception parts must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_End_Keyword),
              "subprogram body end keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Recovery_Boundary),
              "malformed subprogram bodies missing begin must expose recovery boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration),
              "nested package specs inside subprogram bodies must remain visible to the language model");
   end Test_Language_Model_Token_Cursor_Subprogram_Body_Declarative_Part_Depth_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Profile_Item_Grammar is" & ASCII.LF &
        "   type Ref is access all Integer;" & ASCII.LF &
        "   type Rec (A, B : Natural := 1;" & ASCII.LF &
        "             Hook : not null access procedure := null) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Update" & ASCII.LF &
        "     (Left, Right : aliased in out Integer;" & ASCII.LF &
        "      View : not null access constant Integer;" & ASCII.LF &
        "      Callback : access protected procedure (Item : Integer) := null);" & ASCII.LF &
        "end Profile_Item_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Specification),
              "parameter specifications must be parsed structurally instead of skipped as opaque profile text");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification),
              "discriminant specifications must be parsed structurally instead of skipped as opaque profile text");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "aliased profile qualifiers must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Mode),
              "parameter modes must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Default_Expression),
              "parameter and discriminant default expressions must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Exclusion),
              "null exclusions inside profile items must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Definition),
              "anonymous access profile items must keep their access-definition grammar");
   end Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Qualifier_Grammar is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   type Item_Ptr is access all Item;" & ASCII.LF &
        "   Current : aliased constant Item := Default_Item;" & ASCII.LF &
        "   Handle  : aliased not null access Item;" & ASCII.LF &
        "   Counter : constant Integer := 1;" & ASCII.LF &
        "end Object_Qualifier_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "qualified object declarations must remain object declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Qualifier),
              "object declaration aliased/constant qualifiers must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "aliased object qualifiers must reuse the shared aliased grammar node");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Exclusion),
              "aliased not-null access object declarations must still expose null exclusion grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Definition),
              "anonymous access object declarations must keep access-definition grammar");
   end Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Aspect_Mark_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aspect_Mark_Grammar with Preelaborate is" & ASCII.LF &
        "   type Item is tagged record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record with" & ASCII.LF &
        "      Type_Invariant'Class => Is_Valid (Item)," & ASCII.LF &
        "      Default_Initial_Condition => Ready;" & ASCII.LF &
        "end Aspect_Mark_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Association),
              "aspect associations must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Mark),
              "aspect marks must be parsed as aspect grammar rather than arbitrary expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Classwide_Aspect_Mark),
              "class-wide aspect marks such as Type_Invariant'Class must be retained structurally");
   end Test_Language_Model_Token_Cursor_Aspect_Mark_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Pragma_Argument_Identifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Pragma_Argument_Grammar is" & ASCII.LF &
        "   pragma Suppress (Check => Range_Check, On => Table);" & ASCII.LF &
        "   pragma Assert (Condition => Is_Ready, Message => Image (State));" & ASCII.LF &
        "end Pragma_Argument_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma),
              "pragmas must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Association),
              "pragma argument associations must remain individual grammar nodes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Identifier),
              "named pragma arguments must retain their pragma_argument_identifier before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Association_List),
              "pragma arguments must still retain their enclosing association list");
   end Test_Language_Model_Token_Cursor_Pragma_Argument_Identifier_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Record_Representation_Mod_Clause_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Representation_Mod_Grammar is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      Lo, Hi : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      at mod 8;" & ASCII.LF &
        "      Lo at 0 range 0 .. 31;" & ASCII.LF &
        "      Hi at 4 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Record_Representation_Mod_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Representation_Clause),
              "record representation clauses must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Mod_Clause),
              "record representation mod clauses must be parsed structurally instead of skipped as generic tokens");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Clause),
              "component clauses after a mod clause must still be parsed structurally");
   end Test_Language_Model_Token_Cursor_Record_Representation_Mod_Clause_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Object_Declaration_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Declarations is" & ASCII.LF &
        "   Count : aliased constant Numeric.Count range 1 .. 10 := Numeric.Count'(1) with Volatile;" & ASCII.LF &
        "   Handle : not null access Worker;" & ASCII.LF &
        "   Op_Selected : Operator_Types.""+"" := Operator_Types.""+""'(Value);" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Object_Declarations;";
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
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 4,
              "object declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Defining_Name_List) >= 4,
              "object declarations must retain their defining-name-list side explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Subtype_Indication) >= 4,
              "object declarations must retain their subtype/access side explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Initialization_Expression) >= 2,
              "object declarations with := must retain initialization expressions explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Qualifier),
              "object declarations must still retain aliased/constant qualifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "object declaration subtype indications must still parse range constraints");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "object declaration subtype indications must still parse selected operator subtype marks");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Specification),
              "object declarations must still allow attached aspect specifications");
   end Test_Language_Model_Token_Cursor_Object_Declaration_Internal_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Aspect_Placement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   Formal_Obj : in Integer with Default_Value => 0;" & ASCII.LF &
        "   type Formal_T is private with Preelaborable_Initialization;" & ASCII.LF &
        "   with procedure Formal_Proc (X : Integer) with Convention => C;" & ASCII.LF &
        "   with package Formal_Pkg is new Generic_Pkg (<>) with Elaborate_Body;" & ASCII.LF &
        "package Aspect_Placement with Pure is" & ASCII.LF &
        "   type T is range 0 .. 10 with Size => 32;" & ASCII.LF &
        "   type Hidden is private with Preelaborable_Initialization;" & ASCII.LF &
        "   type Completion is new T with private with Type_Invariant => True;" & ASCII.LF &
        "   subtype S is T range 0 .. 5 with Static_Predicate => S >= 0;" & ASCII.LF &
        "   Obj : aliased constant T := 1 with Volatile, Address => System'To_Address (16#1000#);" & ASCII.LF &
        "   Flag : exception with Convention => C;" & ASCII.LF &
        "   procedure Deferred (X : T) is separate with Inline;" & ASCII.LF &
        "   procedure P (X : T) with Pre => X > 0;" & ASCII.LF &
        "   function F return T with Inline;" & ASCII.LF &
        "   task type Worker with Storage_Size => 4096 is" & ASCII.LF &
        "      entry Start with Pre => True;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected type Lock with Priority => 10 is" & ASCII.LF &
        "      procedure Take with Global => null;" & ASCII.LF &
        "   end Lock;" & ASCII.LF &
        "   package Inst is new Generic_Pkg (<>) with Elaborate_Body;" & ASCII.LF &
        "end Aspect_Placement;" & ASCII.LF &
        "package body Aspect_Placement with SPARK_Mode => On is" & ASCII.LF &
        "   task body Worker is separate with SPARK_Mode => Off;" & ASCII.LF &
        "   protected body Lock is separate with SPARK_Mode => Off;" & ASCII.LF &
        "   entry Start when True is separate with Pre => True;" & ASCII.LF &
        "   procedure P (X : T) with Pre => X > 0 is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end P;" & ASCII.LF &
        "end Aspect_Placement;";
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
                (Editor.Ada_Token_Cursor.Production_Aspect_Specification) >= 20,
              "aspect specifications must be retained at generic formals, package specs/bodies, types, subtypes, objects, exceptions, subprograms, task/protected declarations, entries, body stubs, private completions, and instantiations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aspect_Association) >= 20,
              "each attached aspect placement must retain aspect associations structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Classwide_Aspect_Mark)
              or else Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Mark),
              "aspect marks must remain structural instead of being flattened into recovery text");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Type_Declaration),
              "task type declarations with aspects must still retain task type grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Type_Declaration),
              "protected type declarations with aspects must still retain protected type grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "formal package declarations with aspects must still retain formal package grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Aspect_Specification),
              "generic formal declaration aspects must retain placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Concurrent_Type_Aspect_Specification),
              "task and protected declaration aspects must retain concurrent-type placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Aspect_Specification),
              "entry declaration and entry body aspects must retain entry placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Operation_Aspect_Attachment),
              "protected operation aspects must retain protected-operation placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Body_Stub_Aspect_Specification),
              "body-stub aspects must retain body-stub placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Completion_Aspect_Specification),
              "private/incomplete type completion aspects must retain placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Body_Aspect_Specification),
              "package/task/protected body aspects must retain body placement metadata");
   end Test_Language_Model_Token_Cursor_Aspect_Placement_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Body_Stub_Aspect_Placement_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Body_Stub_Aspects is" & ASCII.LF &
        "   procedure Deferred (X : Integer) is separate with Inline;" & ASCII.LF &
        "   function Later return Integer is separate with Convention => C;" & ASCII.LF &
        "   entry Start when Ready is separate with Pre => Ready;" & ASCII.LF &
        "end Body_Stub_Aspects;";
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
                (Editor.Ada_Token_Cursor.Production_Subprogram_Body_Stub) >= 2,
              "subprogram body stubs must remain classified while carrying aspects");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Stub),
              "entry body stubs must remain classified while carrying aspects");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Body_Stub_Aspect_Specification) >= 3,
              "subprogram and entry body-stub aspects must retain body-stub placement metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aspect_Association) >= 3,
              "body-stub aspects must keep their aspect associations structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Contract_Aspect_Association),
              "contract aspects on body stubs must still be recognized as contract aspect associations");
   end Test_Language_Model_Token_Cursor_Body_Stub_Aspect_Placement_Depth;




   procedure Test_Language_Model_Token_Cursor_Subprogram_Modifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Ops is" & ASCII.LF &
        "   overriding procedure Reset (Self : in out Obj) is null;" & ASCII.LF &
        "   not overriding function Image (Self : Obj) return String is (""Obj"");" & ASCII.LF &
        "   procedure Deferred (Self : in out Obj) is abstract;" & ASCII.LF &
        "   procedure Plain (Self : in out Obj);" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with function Make return Obj is <>;" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "end Ops;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Overriding_Indicator),
              "token-cursor grammar must retain overriding indicators before subprogram specs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Procedure_Declaration),
              "token-cursor grammar must distinguish null procedure declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Expression_Function_Declaration),
              "token-cursor grammar must distinguish expression function declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abstract_Subprogram_Declaration),
              "token-cursor grammar must distinguish abstract subprogram declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration),
              "ordinary subprogram declarations must remain parsed as declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Default),
              "formal subprogram defaults such as is <> must be retained structurally");
   end Test_Language_Model_Token_Cursor_Subprogram_Modifier_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Subprogram_Body_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Body_Internals is" & ASCII.LF &
        "   function Compute (Left, Right : Integer) return Integer is" & ASCII.LF &
        "      Total : Integer := Left + Right;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Integer'(Total);" & ASCII.LF &
        "   exception" & ASCII.LF &
        "      when Constraint_Error =>" & ASCII.LF &
        "         return 0;" & ASCII.LF &
        "   end Compute;" & ASCII.LF &
        "   procedure Touch (Value : in out Integer) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Value := Value + 1;" & ASCII.LF &
        "   end Touch;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Body_Internals;";
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
                (Editor.Ada_Token_Cursor.Production_Subprogram_Body) >= 2,
              "subprogram bodies must remain classified structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Defining_Designator) >= 2,
              "subprogram defining designators must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Function_Result_Subtype),
              "function result subtype positions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Declarative_Part),
              "subprogram body declarative parts must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Body_Statement_Sequence) >= 2,
              "subprogram body statement sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Exception_Part),
              "subprogram body exception parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after subprogram bodies");
   end Test_Language_Model_Token_Cursor_Subprogram_Body_Internal_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Package_Body_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Parent.Child is" & ASCII.LF &
        "   Local : Integer := 0;" & ASCII.LF &
        "   procedure Nested is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Local := Local + 1;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Nested;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Program_Error =>" & ASCII.LF &
        "      raise Program_Error with ""package body failure"";" & ASCII.LF &
        "end Parent.Child;" & ASCII.LF &
        "After : Integer;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body),
              "package bodies must remain classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Name),
              "package body names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "selected package body names must still retain selected-name structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Declarative_Part),
              "package body declarative parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Statement_Sequence),
              "package body statement sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Exception_Part),
              "package body exception parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "package body exception statements must retain nested raise-message expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after package bodies");
   end Test_Language_Model_Token_Cursor_Package_Body_Internal_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Subprogram_Completion_Aspect_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Completion_Aspects is" & ASCII.LF &
        "   procedure Reset (Self : in out Obj) is null" & ASCII.LF &
        "     with Pre => Self.Valid, Post => Self.Valid;" & ASCII.LF &
        "   function Ready (Self : Obj) return Boolean is abstract" & ASCII.LF &
        "     with Global => null;" & ASCII.LF &
        "   function Image (Self : Obj) return String is (Self.Name)" & ASCII.LF &
        "     with Post => Image'Result'Length > 0;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Completion_Aspects;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Procedure_Declaration),
              "null procedure completions must remain explicit subprogram declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abstract_Subprogram_Declaration),
              "abstract subprogram completions must remain explicit subprogram declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Expression_Function_Declaration),
              "expression functions must continue to parse with trailing aspects");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aspect_Specification) >= 3,
              "aspects after null, abstract, and expression-function completions must be retained structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aspect_Association) >= 4,
              "contract aspect associations after completion keywords must not be skipped by semicolon recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after completion aspects");
   end Test_Language_Model_Token_Cursor_Subprogram_Completion_Aspect_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Contract_Aspects is" & ASCII.LF &
        "   type Obj is tagged private" & ASCII.LF &
        "     with Type_Invariant'Class => Is_Valid (Obj);" & ASCII.LF &
        "   procedure Reset (Self : in out Obj)" & ASCII.LF &
        "     with Pre'Class => Self.Valid," & ASCII.LF &
        "          Post'Class => Self.Valid," & ASCII.LF &
        "          Global => (in out State)," & ASCII.LF &
        "          Depends => (State => Self);" & ASCII.LF &
        "   function Ready (Self : Obj) return Boolean" & ASCII.LF &
        "     with Global => null," & ASCII.LF &
        "          Refined_Global => null," & ASCII.LF &
        "          Refined_Depends => (Ready'Result => Self);" & ASCII.LF &
        "   protected type Gate is" & ASCII.LF &
        "      procedure Take" & ASCII.LF &
        "        with Pre => Is_Open," & ASCII.LF &
        "             Global => null;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Obj is tagged record" & ASCII.LF &
        "      Valid : Boolean := True;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Contract_Aspects;";
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
                (Editor.Ada_Token_Cursor.Production_Contract_Aspect_Association) >= 9,
              "contract aspects on types, subprogram specs, and protected operations must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Contract_Aspect_Mark) >= 9,
              "contract aspect marks must be distinct from generic aspect marks for semantic colouring");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Contract_Aspect_Value) >= 9,
              "contract aspect values must be marked before expression parsing");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Global_Aspect_Expression) >= 3,
              "Global and Refined_Global aspect payloads must have structural markers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Depends_Aspect_Expression) >= 2,
              "Depends and Refined_Depends aspect payloads must have structural markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Classwide_Aspect_Mark),
              "class-wide contract aspect marks must still retain the generic class-wide marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Type_Declaration),
              "protected operation contracts must not break protected type parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into declarations after contract-aspected declarations");
   end Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Grammar_Completeness;







   procedure Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Contract_Placement_Depth is" & ASCII.LF &
        "   type Obj is tagged null record;" & ASCII.LF &
        "   procedure Spec (Self : in out Obj)" & ASCII.LF &
        "     with Pre => Self'Valid, Global => null;" & ASCII.LF &
        "   procedure Reset (Self : in out Obj) is null" & ASCII.LF &
        "     with Pre => Self'Valid, Post => Self'Valid;" & ASCII.LF &
        "   function Ready return Boolean is abstract" & ASCII.LF &
        "     with Global => null;" & ASCII.LF &
        "   function Image return String is (""ok"")" & ASCII.LF &
        "     with Post => Image'Result'Length > 0;" & ASCII.LF &
        "   procedure Broken" & ASCII.LF &
        "     with Pre => ;" & ASCII.LF &
        "end Contract_Placement_Depth;" & ASCII.LF &
        "package body Contract_Placement_Depth is" & ASCII.LF &
        "   procedure Body_Info (Self : in out Obj)" & ASCII.LF &
        "     with Global => null" & ASCII.LF &
        "   is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Body_Info;" & ASCII.LF &
        "end Contract_Placement_Depth;";
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
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Null_Procedure_Contract_Aspect_Placement),
              "null procedure completion contracts must have a specific placement marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Abstract_Subprogram_Contract_Aspect_Placement),
              "abstract subprogram completion contracts must have a specific placement marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Expression_Function_Contract_Aspect_Placement),
              "expression-function contracts must have a specific placement marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Subprogram_Body_Contract_Aspect_Placement),
              "subprogram body contracts before is must have a specific placement marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Contract_Aspect_Missing_Value_Recovery_Boundary),
              "malformed contract aspect values must expose contract-specific missing-value recovery");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Contract_Aspect_Placement) >= 5,
              "existing generic subprogram contract placement markers must remain available");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Contract_Aspect_Association) >= 7,
              "Pre Post Global and body contract associations must remain visible structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body),
              "body contract aspects must not prevent later body parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "contract-specific recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Depth;





   procedure Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Value_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Contract_Value_Families is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   procedure Classwide (Self : in out Root)" & ASCII.LF &
        "     with Pre'Class => Self'Valid," & ASCII.LF &
        "          Post'Class => Self'Valid," & ASCII.LF &
        "          Contract_Cases => (Self'Valid => True)," & ASCII.LF &
        "          Exceptional_Cases => (Constraint_Error => False)," & ASCII.LF &
        "          Always_Terminates => True," & ASCII.LF &
        "          Nonblocking => True;" & ASCII.LF &
        "   procedure Dataflow (Self : in out Root)" & ASCII.LF &
        "     with Initializes => Self," & ASCII.LF &
        "          Depends => (Self => Self);" & ASCII.LF &
        "end Contract_Value_Families;";
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
                (Editor.Ada_Token_Cursor.Production_Classwide_Contract_Aspect_Mark) >= 2,
              "Pre'Class and Post'Class must expose contract-specific class-wide marks");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Contract_Cases_Aspect_Expression),
              "Contract_Cases must expose contract-case value metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Exceptional_Cases_Aspect_Expression),
              "Exceptional_Cases must expose exceptional-case value metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Always_Terminates_Aspect_Expression),
              "Always_Terminates must expose dedicated value metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Nonblocking_Aspect_Expression),
              "Nonblocking must expose dedicated value metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Depends_Aspect_Expression) >= 2,
              "Depends-style metadata must cover Depends and Initializes structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Contract_Aspect_Placement) >= 2,
              "subprogram contract placement metadata must remain present");
   end Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Value_Families;




   procedure Test_Language_Model_Token_Cursor_Context_Modifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "limited private with Ada.Text_IO, Project.Parent;" & ASCII.LF &
        "private with Ada.Strings.Unbounded;" & ASCII.LF &
        "limited with Interfaces;" & ASCII.LF &
        "use all type Project.Parent.Flag;" & ASCII.LF &
        "package Context_Modifiers is" & ASCII.LF &
        "end Context_Modifiers;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Context_Clause),
              "context clauses must remain grammar productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Limited_With_Clause),
              "limited with clauses must be retained as grammar modifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_With_Clause),
              "private with clauses must be retained as grammar modifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_With_Clause),
              "modified with clauses must still emit the base with-clause production");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "context clause unit names must retain selected-name grammar structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_All_Type_Clause),
              "use all type clauses must remain parsed after modified with clauses");
   end Test_Language_Model_Token_Cursor_Context_Modifier_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Representation_Clause_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rep_Clauses is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 2, Blue => 4);" & ASCII.LF &
        "   type Word is range 0 .. 255;" & ASCII.LF &
        "   for Word'Size use 8;" & ASCII.LF &
        "   Object : Word;" & ASCII.LF &
        "   for Object use at System'To_Address (16#1000#);" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      A : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      A at 0 range 0 .. 0;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Rep_Clauses;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Clause),
              "representation clauses must retain the common representation production");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Clause),
              "enumeration representation clauses must be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Definition_Clause),
              "attribute definition clauses must be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Address_Clause),
              "address clauses must be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Representation_Clause),
              "record representation clauses must continue to be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Clause),
              "record representation component clauses must remain parsed structurally");
   end Test_Language_Model_Token_Cursor_Representation_Clause_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Representation_Operational_Item_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rep_Operational_Items is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 2, Blue => 4);" & ASCII.LF &
        "   type Word is range 0 .. 255;" & ASCII.LF &
        "   for Word'Size use 8;" & ASCII.LF &
        "   for Word'Alignment use 4;" & ASCII.LF &
        "   for Word'Class'Input use Read_Word;" & ASCII.LF &
        "   procedure Read_Word (Stream : access Root_Stream_Type'Class; Item : out Word);" & ASCII.LF &
        "   for Word'Read use Read_Word;" & ASCII.LF &
        "   Object : Word;" & ASCII.LF &
        "   for Object'Address use System'To_Address (16#1000#);" & ASCII.LF &
        "   type State is (Idle, Busy, Done);" & ASCII.LF &
        "   for State use (0, 1, 2);" & ASCII.LF &
        "   type Packed is record" & ASCII.LF &
        "      A : Boolean;" & ASCII.LF &
        "      B : Word;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Packed use record" & ASCII.LF &
        "      at mod 8;" & ASCII.LF &
        "      A at 0 range 0 .. 0;" & ASCII.LF &
        "      B at 1 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   with Volatile, Convention => C;" & ASCII.LF &
        "end Rep_Operational_Items;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
      use type Editor.Ada_Token_Cursor.Production_Kind;

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
                (Editor.Ada_Token_Cursor.Production_Representation_Target) >= 6,
              "representation and operational items must retain their targets structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Attribute_Designator) >= 4,
              "attribute definition clauses must retain attribute designators separately from targets");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Association) >= 3,
              "enumeration representation clauses must retain each literal association");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Operational_Attribute_Definition_Clause),
              "operational attribute definition clauses such as Read must be recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Classwide_Attribute_Prefix),
              "class-wide stream attribute clauses must retain the Class prefix before the final attribute designator");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Stream_Attribute_Definition_Clause),
              "stream attributes such as Read and Input must be classified distinctly from generic operational attributes");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Representation_Value_Expression) >= 6,
              "representation and operational item values must be retained as value-expression children");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Address_Value_Expression),
              "address clauses must retain the address expression separately from ordinary representation values");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Choice_List),
              "named enumeration representation clauses must retain explicit choice-list structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Position),
              "component clauses must retain the position expression structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_First_Bit),
              "component clauses must retain first-bit expressions structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Last_Bit),
              "component clauses must retain last-bit expressions structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Clause),
              "standalone aspect clauses must be parsed as representation/operational items");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Association),
              "standalone aspect clauses must reuse aspect association grammar");
   end Test_Language_Model_Token_Cursor_Representation_Operational_Item_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Enum_Representation_Delimiters is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 2, Blue => 4);" & ASCII.LF &
        "   type State is (Idle, Busy, Done);" & ASCII.LF &
        "   for State use (0, 1, 2;" & ASCII.LF &
        "   type Next_State is (Start, Stop);" & ASCII.LF &
        "end Enum_Representation_Delimiters;";
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
                (Editor.Ada_Token_Cursor.Production_Enumeration_Representation_List_Open_Delimiter) >= 2,
              "enumeration representation clauses must retain opening delimiters");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Representation_List_Close_Delimiter),
              "well-formed enumeration representation clauses must retain closing delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Association_Separator) >= 4,
              "enumeration representation clauses must retain comma separators between associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Missing_Close_Recovery_Boundary),
              "in-progress enumeration representation clauses must record bounded missing-close recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Type_Declaration),
              "missing enumeration representation close recovery must not consume the next declaration");
   end Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters;





   procedure Test_Language_Model_Token_Cursor_Record_Representation_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Representation_Delimiters is" & ASCII.LF &
        "   type R is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for R use record" & ASCII.LF &
        "      at mod 8;" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 1 range 0 .. 7;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Broken is record" & ASCII.LF &
        "      C : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Broken use record" & ASCII.LF &
        "      C at 0 range 0 .. 7;" & ASCII.LF &
        "   end;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Record_Representation_Delimiters;";
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
                (Editor.Ada_Token_Cursor.Production_Record_Representation_List_Open_Delimiter) >= 2,
              "record representation clauses must retain record-block opening delimiters");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Representation_List_Close_Delimiter),
              "well-formed record representation clauses must retain closing record delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Record_Representation_Component_Separator) >= 4,
              "record representation clauses must retain component and mod clause separators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Representation_Missing_Close_Recovery_Boundary),
              "record representation clauses with bare end must retain bounded missing-close recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "record representation missing-close recovery must not consume the following declaration");
   end Test_Language_Model_Token_Cursor_Record_Representation_Delimiters;




   procedure Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Pragma_Argument_Delimiters is" & ASCII.LF &
        "   pragma Pack (R);" & ASCII.LF &
        "   pragma Convention (C, Entity => R);" & ASCII.LF &
        "   pragma Import (Convention => C, Entity => External_Name;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Pragma_Argument_Delimiters;";
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
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_List_Open_Delimiter) >= 3,
              "pragma argument lists must retain opening delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_List_Close_Delimiter) >= 2,
              "well-formed pragma argument lists must retain closing delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Association_Separator) >= 3,
              "pragma argument lists must retain comma separators between associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary),
              "in-progress pragma argument lists must record bounded missing-close recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "pragma argument missing-close recovery must not consume the following declaration");
   end Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters;




   procedure Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Parameter_Profile_Delimiters is" & ASCII.LF &
        "   procedure Well_Formed (A : Integer; B : in out String);" & ASCII.LF &
        "   procedure Broken (A : Integer; B : Integer;" & ASCII.LF &
        "   procedure Next;" & ASCII.LF &
        "end Parameter_Profile_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile),
              "parameter profiles must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile_Open_Delimiter),
              "parameter profiles must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile_Close_Delimiter),
              "well-formed parameter profiles must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile_Separator),
              "multi-parameter profiles must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile_Missing_Close_Recovery_Boundary),
              "malformed parameter profiles must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration_Terminator),
              "parameter-profile recovery must leave surrounding declaration terminators available");
   end Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters;



   procedure Test_Language_Model_Token_Cursor_Representation_Pragma_Item_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rep_Pragma_Items is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Flag : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   pragma Pack (Rec);" & ASCII.LF &
        "   Obj : aliased Integer;" & ASCII.LF &
        "   pragma Atomic (Obj);" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "   pragma Import (Convention => C, Entity => Run, External_Name => ""run"");" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      pragma Priority (10);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Rep_Pragma_Items;";
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
                (Editor.Ada_Token_Cursor.Production_Pragma) >= 4,
              "representation and operational pragmas must remain ordinary pragma nodes");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Representation_Pragma) >= 3,
              "Pack Atomic and Import pragmas must be classified as representation pragmas");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Operational_Pragma) >= 4,
              "representation pragmas and Priority must also be retained as operational pragma items");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Operational_Item) >= 4,
              "pragma aliases for representation and operational properties must feed the shared operational item grammar path");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_List) >= 4,
              "classified representation pragmas must keep their pragma argument lists");
   end Test_Language_Model_Token_Cursor_Representation_Pragma_Item_Depth;





   procedure Test_Language_Model_Token_Cursor_Renaming_Declaration_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rename_Forms is" & ASCII.LF &
        "   Source : Integer;" & ASCII.LF &
        "   Alias : Integer renames Source;" & ASCII.LF &
        "   Failure : exception renames Constraint_Error;" & ASCII.LF &
        "   package IO renames Ada.Text_IO;" & ASCII.LF &
        "   procedure Put (S : String) renames Ada.Text_IO.Put_Line;" & ASCII.LF &
        "   function ""+"" (Left, Right : Integer) return Integer renames Math.""+"";" & ASCII.LF &
        "   generic package Generic_IO renames Ada.Text_IO;" & ASCII.LF &
        "   generic procedure Generic_Run renames Root.Generic_Run;" & ASCII.LF &
        "end Rename_Forms;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
      use type Editor.Ada_Token_Cursor.Production_Kind;

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
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Renaming_Declaration),
              "package renaming declarations must be structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Renaming_Declaration),
              "procedure/function renaming declarations must be structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Renaming_Declaration),
              "object renaming declarations must be structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Renaming_Declaration),
              "exception renaming declarations must be structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Package_Renaming_Declaration),
              "generic package renaming declarations must be structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Subprogram_Renaming_Declaration),
              "generic subprogram renaming declarations must be structural");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Renamed_Entity) >= 7,
              "every renaming declaration must retain the renamed entity target");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Renaming_Defining_Name) >= 7,
              "renaming declarations must retain their defining names explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renaming_Subtype_Indication),
              "object renamings must retain subtype-indication positions explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Renaming_Parameter_Profile) >= 2,
              "subprogram renamings must retain parameter-profile positions explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renaming_Result_Subtype),
              "function renamings must retain result subtype positions explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Defining_Operator_Symbol),
              "renamed operator functions must retain their defining operator symbol");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "renamed targets such as Ada.Text_IO.Put_Line and Math.""+"" must retain selected-name shape");
   end Test_Language_Model_Token_Cursor_Renaming_Declaration_Grammar_Completeness;












   procedure Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rename_Aspect_Placement is" & ASCII.LF &
        "   Source : aliased Integer;" & ASCII.LF &
        "   package Inner is" & ASCII.LF &
        "      procedure Run;" & ASCII.LF &
        "   end Inner;" & ASCII.LF &
        "   Alias : Integer renames Source with Volatile;" & ASCII.LF &
        "   package Inner_Alias renames Inner with Preelaborate;" & ASCII.LF &
        "   procedure Run_Alias renames Inner.Run with Inline;" & ASCII.LF &
        "   function Image (Value : Integer) return String" & ASCII.LF &
        "     renames Integer'Image with Post => Image'Result'Length > 0;" & ASCII.LF &
        "end Rename_Aspect_Placement;";
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
                (Editor.Ada_Token_Cursor.Production_Renaming_Aspect_Specification) >= 4,
              "object package procedure and function renamings must retain renaming-specific aspect placement");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aspect_Specification) >= 4,
              "renaming aspect placements must still preserve ordinary aspect associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Contract_Aspect_Association),
              "contract aspects on renaming declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renamed_Selected_Target),
              "renaming aspect parsing must not consume selected renamed targets");
   end Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement;





   procedure Test_Language_Model_Token_Cursor_Renaming_Target_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Rename_Targets is" & ASCII.LF &
        "   Source : aliased Integer;" & ASCII.LF &
        "   Alias : Integer renames Root.Table (Index).Field;" & ASCII.LF &
        "   package Vec renames Ada.Containers.Vectors;" & ASCII.LF &
        "   procedure Put renames Ada.Text_IO.Put_Line;" & ASCII.LF &
        "   function ""*"" (L, R : Integer) return Integer renames Math.""*"";" & ASCII.LF &
        "   generic package GP renames Root.Generic_Packages.Factory;" & ASCII.LF &
        "   generic function GF return Integer renames Root.Generic_Functions.""+"";" & ASCII.LF &
        "   Broken : Integer renames ;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Rename_Targets;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
      use type Editor.Ada_Token_Cursor.Production_Kind;

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
                (Grammar, Editor.Ada_Token_Cursor.Production_Renamed_Object_Name),
              "object renaming targets must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renamed_Package_Name),
              "package renaming targets must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renamed_Subprogram_Name),
              "subprogram renaming targets must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renamed_Generic_Unit_Name),
              "generic renaming targets must be classified explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Renamed_Selected_Target) >= 5,
              "selected renamed targets must retain selected-target classification");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Renamed_Operator_Target) >= 2,
              "operator-symbol renamed targets must retain operator-target classification");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renaming_Recovery_Boundary),
              "malformed renamings must retain a bounded recovery marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "renaming recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Renaming_Target_Depth_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Pragma_Identifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Pragma_Grammar is" & ASCII.LF &
        "   pragma Elaborate_Body;" & ASCII.LF &
        "   pragma Suppress (Check => Range_Check);" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      pragma Assert (Check => Ready, Message => ""not ready"");" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Pragma_Grammar;";
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
                (Editor.Ada_Token_Cursor.Production_Pragma) = 3,
              "declaration and statement-sequence pragmas must remain structural");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Identifier) = 3,
              "pragma identifiers must be retained separately from arguments");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Association_List) >= 2,
              "pragma argument lists must be retained when present");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Identifier) >= 3,
              "named pragma argument identifiers must remain structural");
   end Test_Language_Model_Token_Cursor_Pragma_Identifier_Grammar_Completeness;








   procedure Test_Language_Model_Token_Cursor_Pragma_Argument_List_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "pragma Pure;" & ASCII.LF &
        "package body Pragma_Argument_List_Grammar is" & ASCII.LF &
        "   pragma Suppress (Range_Check);" & ASCII.LF &
        "   pragma Annotate (GNATprove, Terminating, Run);" & ASCII.LF &
        "   pragma Import (Convention => C, Entity => Run, External_Name => ""run"");" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      pragma Assert (Ready, Message => ""not ready"");" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Pragma_Argument_List_Grammar;";
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
                (Editor.Ada_Token_Cursor.Production_Pragma) = 5,
              "declaration and statement-sequence pragmas must remain structural");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Nullary_Pragma) = 1,
              "nullary pragmas must be classified separately from argument-bearing pragmas");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_List) = 4,
              "argument-bearing pragmas must retain pragma-specific argument-list productions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Association) >= 8,
              "pragma argument associations must be retained for positional and named arguments");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Identifier) >= 4,
              "named pragma argument selectors must remain structural before =>");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Expression) >= 8,
              "pragma argument values must remain structural before expression parsing");
   end Test_Language_Model_Token_Cursor_Pragma_Argument_List_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Pragma_Association_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Pragma_Association_Depth is" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "   pragma Import (C, Run, External_Name => ""run"");" & ASCII.LF &
        "   pragma Annotate (GNATprove, Intentional, Entity => Run);" & ASCII.LF &
        "   pragma Debug (<>);" & ASCII.LF &
        "   pragma Pure;" & ASCII.LF &
        "end Pragma_Association_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Positional_Association) >= 5,
              "positional pragma arguments must be retained distinctly from named associations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Named_Association) >= 2,
              "named pragma arguments must retain pragma-specific association nodes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Box),
              "box pragma arguments must be retained without falling through malformed expression recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Nullary_Pragma),
              "nullary pragma coverage must be preserved beside argument-bearing pragma associations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Pragma_Argument_Expression) >= 7,
              "pragma argument expressions must remain structural for positional named and box arguments");
   end Test_Language_Model_Token_Cursor_Pragma_Association_Depth;



   procedure Test_Language_Model_Token_Cursor_Aspect_Placement_Breadth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "package Generic_Pkg with Pure is" & ASCII.LF &
        "end Generic_Pkg;" & ASCII.LF &
        "package Aspect_Placement_Breadth with Preelaborate is" & ASCII.LF &
        "   type Private_Item is private with Default_Initial_Condition => True;" & ASCII.LF &
        "   task type Worker with Storage_Size => 4096;" & ASCII.LF &
        "   protected type Lock with Priority => 10 is" & ASCII.LF &
        "      procedure Enter;" & ASCII.LF &
        "   end Lock;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Private_Item is null record;" & ASCII.LF &
        "end Aspect_Placement_Breadth;" & ASCII.LF &
        "package body Aspect_Placement_Breadth with SPARK_Mode => Off is" & ASCII.LF &
        "   task body Worker with SPARK_Mode => Off is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected body Lock with SPARK_Mode => Off is" & ASCII.LF &
        "      procedure Enter is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Enter;" & ASCII.LF &
        "   end Lock;" & ASCII.LF &
        "end Aspect_Placement_Breadth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Declaration_Aspect_Specification),
              "generic declarations must retain generic-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration_Aspect_Specification),
              "package declarations must retain package-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Aspect_Specification),
              "package bodies must retain package-body-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Declaration_Aspect_Specification),
              "task declarations must retain task-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Aspect_Specification),
              "task bodies must retain task-body-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Declaration_Aspect_Specification),
              "protected declarations must retain protected-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Aspect_Specification),
              "protected bodies must retain protected-body-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Type_Aspect_Specification),
              "private type declarations must retain private-type-specific aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Association),
              "new placement metadata must preserve ordinary aspect associations");
   end Test_Language_Model_Token_Cursor_Aspect_Placement_Breadth;





   procedure Test_Language_Model_Token_Cursor_Number_Declaration_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Number_Declaration_Depth is" & ASCII.LF &
        "   Alpha, Beta, Gamma : constant := 1 + 2;" & ASCII.LF &
        "   Missing_Value : constant := ;" & ASCII.LF &
        "   Missing_Assignment : constant;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Number_Declaration_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Number_Defining_Name) >= 5,
              "number declarations must retain each defining identifier explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Number_Defining_Name_Separator) >= 2,
              "grouped number declarations must retain defining-name separators");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Number_Constant_Keyword) >= 3,
              "number declarations must retain their constant keyword distinctly from object constants");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Number_Initialization_Expression) >= 1,
              "named-number initializers must remain expression-owned grammar payloads");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Number_Declaration_Recovery_Boundary) >= 2,
              "malformed number declarations must expose bounded recovery boundaries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 1,
              "number declaration recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Number_Declaration_Depth_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Object_Declaration_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Declaration_Depth is" & ASCII.LF &
        "   A, B, C : aliased constant Integer := 1;" & ASCII.LF &
        "   Handle : not null access Integer := null;" & ASCII.LF &
        "   Pool_Item : aliased access Integer;" & ASCII.LF &
        "   Bad : constant := 1;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Object_Declaration_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Object_Defining_Name) >= 7,
              "object declarations must retain each defining identifier explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Defining_Name_Separator) >= 2,
              "grouped object declarations must retain defining-name separators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Aliased_Qualifier),
              "aliased object qualifiers must be retained separately from generic qualifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Constant_Qualifier),
              "constant object qualifiers must be retained separately from number declarations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Access_Definition) >= 2,
              "anonymous access object definitions must be classified by object context");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Recovery_Boundary),
              "malformed object declarations must expose bounded recovery boundaries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 5,
              "object declaration recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Object_Declaration_Depth_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Separate_Subunit_Body_Stub_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Root.Child is" & ASCII.LF &
        "   procedure P is separate;" & ASCII.LF &
        "   package body Nested is separate;" & ASCII.LF &
        "end Root.Child;" & ASCII.LF &
        "separate (Root.Child)" & ASCII.LF &
        "procedure P is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end P;" & ASCII.LF &
        "separate (Root.Child)" & ASCII.LF &
        "package body Nested is" & ASCII.LF &
        "end Nested;" & ASCII.LF &
        "separate (Root.Child.Workers)" & ASCII.LF &
        "task body Runner is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Runner;" & ASCII.LF &
        "separate (Root.Child.Guards)" & ASCII.LF &
        "protected body Lock is" & ASCII.LF &
        "end Lock;";
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
                (Editor.Ada_Token_Cursor.Production_Separate_Subunit) >= 4,
              "separate subunits must retain explicit subunit markers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Separate_Parent_Unit_Separator) >= 4,
              "dotted separate parent-unit names must retain separators");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Separate_Parent_Unit_Child) >= 4,
              "dotted separate parent-unit names must retain child-name metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Separate_Body_Kind_Keyword) >= 4,
              "separate subunits must retain package/subprogram/task/protected body kind keywords");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Separate_Body_Unit_Name) >= 4,
              "separate subunits must retain local body unit names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Subprogram_Body),
              "separate subprogram bodies must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Package_Body),
              "separate package bodies must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Task_Body),
              "separate task bodies must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Separate_Protected_Body),
              "separate protected bodies must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Body_Stub_Kind_Keyword) >= 2,
              "body stubs must retain the stub kind keyword for subunit relation hints");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Body_Stub_Subunit_Link_Hint) >= 2,
              "body stubs must retain conservative subunit-link hint metadata");
   end Test_Language_Model_Token_Cursor_Separate_Subunit_Body_Stub_Depth;


   overriding function Name (T : Token_Cursor_Declaration_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Declaration");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Declaration_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Context_And_Label_Grammar_Completeness'Access, Name => "token-cursor grammar parses context clauses and labels structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Declarative_Use_Clause_Grammar_Completeness'Access, Name => "token-cursor grammar parses declarative use clauses without context ownership");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement'Access, Name => "token-cursor grammar records subprogram contract aspect placement on specs and bodies");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Separate_And_Body_Stub_Grammar_Completeness'Access, Name => "token-cursor grammar parses separate subunits and body stubs structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Body_Stub_Separate_Subunit_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens body stub and separate subunit structure");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Body_Declarative_Part_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses subprogram body declarative parts deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness'Access, Name => "token-cursor grammar parses parameter and discriminant profile items structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses object declaration qualifiers structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aspect_Mark_Grammar_Completeness'Access, Name => "token-cursor grammar parses aspect marks and class-wide aspect marks structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Argument_Identifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses named pragma argument identifiers structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Record_Representation_Mod_Clause_Grammar_Completeness'Access, Name => "token-cursor grammar parses record representation mod clauses structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Object_Declaration_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains object declaration internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aspect_Placement_Grammar_Completeness'Access, Name => "token-cursor grammar retains aspect specifications at every legal declaration placement");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Body_Stub_Aspect_Placement_Depth'Access, Name => "token-cursor grammar retains subprogram and entry body-stub aspect placement");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Modifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses overriding null abstract expression and defaulted subprogram forms");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Body_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar parses subprogram body internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Body_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar parses package body internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Completion_Aspect_Grammar_Completeness'Access, Name => "token-cursor grammar retains aspects after null abstract and expression-function completions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Grammar_Completeness'Access, Name => "token-cursor grammar parses subprogram contract aspects structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Depth'Access, Name => "token-cursor grammar deepens subprogram contract aspect placement for specs completions and bodies");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Value_Families'Access, Name => "token-cursor grammar deepens subprogram contract aspect value families and class-wide marks");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Context_Modifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses limited and private with clauses");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Representation_Clause_Grammar_Completeness'Access, Name => "token-cursor grammar parses attribute enumeration address and record representation clauses");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Representation_Operational_Item_Grammar_Completeness'Access, Name => "token-cursor grammar parses complete representation and operational items structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters'Access, Name => "token-cursor grammar deepens enumeration representation delimiters and missing-close recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Record_Representation_Delimiters'Access, Name => "token-cursor grammar deepens record representation delimiters and missing-close recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters'Access, Name => "token-cursor grammar deepens pragma argument delimiters and missing-close recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters'Access, Name => "token-cursor grammar records parameter profile delimiters separators and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Representation_Pragma_Item_Depth'Access, Name => "token-cursor grammar classifies representation and operational pragmas structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Renaming_Declaration_Grammar_Completeness'Access, Name => "token-cursor grammar parses renaming declarations structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement'Access, Name => "token-cursor grammar retains renaming-specific aspect placement");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Renaming_Target_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens renaming target structure and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Identifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses pragma identifiers and named argument associations structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Argument_List_Grammar_Completeness'Access, Name => "token-cursor grammar parses pragma argument lists structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Association_Depth'Access, Name => "token-cursor grammar distinguishes named positional and box pragma arguments");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aspect_Placement_Breadth'Access, Name => "token-cursor grammar records broader aspect placement families");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Number_Declaration_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens number declaration names constants initializers and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Object_Declaration_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens object declaration names qualifiers and access definitions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Separate_Subunit_Body_Stub_Depth'Access, Name => "token-cursor grammar retains separate subunit and body-stub relation metadata");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Declaration_Tests;
