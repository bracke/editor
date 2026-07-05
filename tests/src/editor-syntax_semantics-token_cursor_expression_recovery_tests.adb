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

package body Editor.Syntax_Semantics.Token_Cursor_Expression_Recovery_Tests is

   procedure Test_Language_Model_Token_Cursor_Raise_Expression_Message_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Raise_Expression_Message_Recovery is" & ASCII.LF &
        "   Flag : Boolean := (if Ready then raise Constraint_Error with else False);" & ASCII.LF &
        "   Good : Boolean := (if Ready then raise Program_Error with ""bad"" else True);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Raise_Expression_Message_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression),
              "raise expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_With_Message_Keyword),
              "raise expressions must retain the with-message keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression_Message_Recovery_Boundary),
              "raise expressions missing a with-message payload must retain expression-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression_Message),
              "well-formed raise-expression messages must retain expression-message metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "raise-expression recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Raise_Expression_Message_Recovery;

   procedure Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Declare_Expression_Begin_Recovery is" & ASCII.LF &
        "   Good : Integer := (declare Temp : constant Integer := 1; begin Temp + 1);" & ASCII.LF &
        "   Broken : Integer := (declare Temp : constant Integer := 2; Temp + 1);" & ASCII.LF &
        "   After : Integer := 3;" & ASCII.LF &
        "end Declare_Expression_Begin_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression),
              "declare expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression_Begin_Keyword),
              "well-formed declare expressions must retain begin keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression_Body_Expression),
              "declare expression body expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression_Missing_Begin_Recovery_Boundary),
              "malformed declare expressions must retain bounded missing-begin recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "declare-expression recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery;

   procedure Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Expression_Recovery_Refinement_Depth is" & ASCII.LF &
        "   Missing_If_Condition : Boolean := (if then True else False);" & ASCII.LF &
        "   Missing_Elsif_Condition : Boolean := (if Ready then True elsif then False else Ready);" & ASCII.LF &
        "   Missing_Case_Selector : Integer := (case is when others => 1);" & ASCII.LF &
        "   Missing_Case_Is : Integer := (case Mode when others => 2);" & ASCII.LF &
        "   Broken_Case_Branch : Integer := (case Mode is when 0 =>, when others => 3);" & ASCII.LF &
        "   Broken_Parallel_Reduce : Integer := Values'Parallel_Reduce (Plus, );" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Expression_Recovery_Refinement_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_If_Expression_Condition_Reserved_Boundary) >= 2,
              "conditional expressions missing if/elsif conditions must expose reserved-boundary recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Selector_Recovery_Boundary),
              "case expressions missing a selector before is/when must expose selector recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Is_Recovery_Boundary),
              "case expressions missing is must expose an explicit recovery marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary),
              "case expression alternatives with => followed by a boundary must retain dependent-expression recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Parallel_Reduction_Argument_Recovery_Boundary),
              "parallel reductions with malformed argument parts must be distinguishable from ordinary reduction recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "expression recovery refinements must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth;

   procedure Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Name_Grammar_Recovery_Depth is" & ASCII.LF &
        "   type Count is range 0 .. 100;" & ASCII.LF &
        "   type Count_Access is access Count;" & ASCII.LF &
        "   Broken_Selected : Count := Root.with;" & ASCII.LF &
        "   Broken_Allocator : Count_Access := new ;" & ASCII.LF &
        "   Broken_Qualified : Count := Count'(with);" & ASCII.LF &
        "   Broken_Allocator_Qualified : Count_Access := new Count'();" & ASCII.LF &
        "   Good_Selected_Operator : Count := Operators.""+""'(1);" & ASCII.LF &
        "   Good_Selected_Character : Character := Literals.'A';" & ASCII.LF &
        "   After : Count := Count'(4);" & ASCII.LF &
        "end Name_Grammar_Recovery_Depth;";
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
                 Editor.Ada_Token_Cursor.Production_Selected_Name_Reserved_Selector_Recovery_Boundary),
              "selected names ending at reserved boundaries must expose selector-specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Allocator_Missing_Subtype_Recovery_Boundary),
              "allocators missing a subtype before a boundary must expose allocator-specific recovery");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Qualified_Expression_Missing_Operand_Recovery_Boundary) >= 2,
              "qualified expressions and allocator qualified expressions missing operands must expose operand recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "selected operator-symbol selectors must remain visible through recovery depth additions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Character_Selector),
              "selected character-literal selectors must remain visible through recovery depth additions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 5,
              "name grammar recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth;

   procedure Test_Language_Model_Token_Cursor_Conditional_Expression_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Conditional_Expression_Recovery is" & ASCII.LF &
        "   Missing_Condition : Integer := (if then 1 else 2);" & ASCII.LF &
        "   Missing_Then_Branch : Integer := (if Ready then else 2);" & ASCII.LF &
        "   Missing_Else_Branch : Integer := (if Ready then 1 else);" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Conditional_Expression_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_If_Expression_Missing_Condition_Recovery_Boundary),
              "conditional expressions missing a condition must expose if-expression-specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_If_Expression_Missing_Then_Branch_Recovery_Boundary),
              "conditional expressions missing a then branch must expose then-branch recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_If_Expression_Missing_Else_Branch_Recovery_Boundary),
              "conditional expressions missing an else branch must expose else-branch recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Expression),
              "conditional expression metadata must be preserved around branch recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "conditional-expression recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Conditional_Expression_Recovery;

   procedure Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Expression_Name_Edges is" & ASCII.LF &
        "   type Root (Kind : Integer) is tagged null record;" & ASCII.LF &
        "   type Root_Access is access Root;" & ASCII.LF &
        "   function F (X : Integer) return Integer;" & ASCII.LF &
        "   A : Root_Access := new Root'(Kind => Integer'(F (1)));" & ASCII.LF &
        "   B : Integer := Tables.Operator_View.""+""'(F (1))'Image'Length;" & ASCII.LF &
        "   C : Integer := Values (1 .. F (2))'Length;" & ASCII.LF &
        "   D : Integer := Values'Reduce (Combine);" & ASCII.LF &
        "   E : Integer := Values'Parallel_Reduce (Combine, 0)'Image'Length;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Expression_Name_Edges;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Nested_Qualified_Expression),
              "allocators using qualified expressions must retain allocator-qualified metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conversion_Or_Qualified_Expression),
              "qualified-expression/conversion ambiguity must remain explicit for semantic consumers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "selected operator-literal selectors must remain visible in expression names");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Chained_Attribute_Reference) >= 2,
              "chained attributes after qualified expressions and reductions must remain explicit");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Slice),
              "parenthesized name suffixes containing ranges must be retained as slices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Or_Indexed_Component),
              "call/index/conversion-like suffix ambiguity must retain a bounded marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Argument_Recovery_Boundary),
              "malformed reduction argument parts must produce bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after expression/name edge cases");
   end Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery;

   procedure Test_Language_Model_Token_Cursor_If_Expression_Else_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package If_Expression_Recovery is" & ASCII.LF &
        "   Ready   : Boolean := True;" & ASCII.LF &
        "   Enabled : Boolean := False;" & ASCII.LF &
        "   Good    : Boolean := (if Ready then Enabled else False);" & ASCII.LF &
        "   Broken  : Boolean := (if Ready then Enabled);" & ASCII.LF &
        "end If_Expression_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Expression),
              "if expressions must retain conditional-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Condition),
              "if-expression conditions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Then_Dependent_Expression),
              "then-dependent expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Else_Dependent_Expression),
              "well-formed if expressions must retain else-dependent expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Missing_Else_Recovery_Boundary),
              "if expressions missing an else arm must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_If_Expression_Else_Recovery;

   procedure Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package If_Expression_Then_Recovery is" & ASCII.LF &
        "   Ready   : Boolean := True;" & ASCII.LF &
        "   Enabled : Boolean := False;" & ASCII.LF &
        "   Good    : Boolean := (if Ready then Enabled else False);" & ASCII.LF &
        "   Broken  : Boolean := (if Ready else False);" & ASCII.LF &
        "   Nested  : Boolean := (if Ready then True elsif Enabled else False);" & ASCII.LF &
        "end If_Expression_Then_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Expression),
              "if expressions must retain conditional-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Missing_Then_Recovery_Boundary),
              "if expressions missing then must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Elsif_Expression_Missing_Then_Recovery_Boundary),
              "elsif expressions missing then must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Else_Dependent_Expression),
              "else-dependent expressions must remain visible after missing-then recovery");
   end Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery;

   procedure Test_Language_Model_Token_Cursor_Case_Expression_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Case_Expression_Recovery is" & ASCII.LF &
        "   Good       : Integer := (case Mode is when 1 => 10, when others => 0);" & ASCII.LF &
        "   No_Arrow   : Integer := (case Mode is when 1 10, when others => 0);" & ASCII.LF &
        "   No_When    : Integer := (case Mode is);" & ASCII.LF &
        "end Case_Expression_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "case expressions must retain top-level expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Alternative),
              "case-expression alternatives must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Arrow),
              "well-formed case-expression alternatives must retain arrow metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Dependent_Expression),
              "well-formed alternatives must retain dependent-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Arrow_Recovery_Boundary),
              "case-expression alternatives missing => must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Alternative_Recovery_Boundary),
              "case expressions missing alternatives must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_Case_Expression_Recovery;

   procedure Test_Language_Model_Token_Cursor_Quantified_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Quantified_Recovery is" & ASCII.LF &
        "   Missing_Domain : Boolean := (for all I in => Ready);" & ASCII.LF &
        "   Missing_Arrow  : Boolean := (for some Item of Items when Item.Valid);" & ASCII.LF &
        "   After          : Integer := 1;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Quantified_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Missing_Domain_Recovery_Boundary),
              "quantified expressions with a missing domain must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Missing_Arrow_Recovery_Boundary),
              "quantified expressions with a missing arrow must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Iterator_Filter),
              "recovered quantified expressions must still retain iterator-filter structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "quantified-expression recovery must not consume the following declaration");
   end Test_Language_Model_Token_Cursor_Quantified_Recovery;

   procedure Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Case_Expression_Dependent_Recovery is" & ASCII.LF &
        "   Missing_First : Integer := (case Mode is when 1 =>, when others => 0);" & ASCII.LF &
        "   Missing_Last  : Integer := (case Mode is when 1 => 10, when others =>);" & ASCII.LF &
        "   After         : Integer := 1;" & ASCII.LF &
        "end Case_Expression_Dependent_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "case-expression metadata must be preserved around dependent-expression recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Arrow),
              "case-expression arrows must remain visible before missing dependent expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary),
              "case-expression alternatives missing a dependent expression must expose specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Dependent_Expression),
              "well-formed alternatives must still expose dependent-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "case-expression recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery;

   procedure Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Reduction_Argument_Recovery is" & ASCII.LF &
        "   Missing_Reducer : Integer := Values'Reduce (, 0);" & ASCII.LF &
        "   Missing_Initial : Integer := Values'Parallel_Reduce (""+"",);" & ASCII.LF &
        "   Missing_Close   : Integer := Values'Map_Reduce (""+"", 0;" & ASCII.LF &
        "   After           : Integer := 1;" & ASCII.LF &
        "end Reduction_Argument_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Expression),
              "reduction attributes must continue to expose reduction-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Reduction_Expression),
              "parallel reduction attributes must retain parallel-reduction metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Map_Reduction_Expression),
              "map reduction attributes must retain map-reduction metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Reduction_Missing_Reducer_Recovery_Boundary),
              "malformed reductions missing the reducer must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Reduction_Missing_Initial_Value_Recovery_Boundary),
              "malformed reductions missing the initial value must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Reduction_Trailing_Separator_Recovery_Boundary),
              "trailing reduction argument separators must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary),
              "reduction argument recovery must preserve missing-close metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "reduction argument recovery must preserve following declarations");
   end Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery;

   procedure Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Quantified_Predicate_Recovery is" & ASCII.LF &
        "   Missing_Close : constant Boolean := (for all I in 1 .. 3 =>);" & ASCII.LF &
        "   Missing_Comma : constant Boolean := (for some I in 1 .. 3 =>, True);" & ASCII.LF &
        "   Missing_When  : constant Boolean := (for all I in 1 .. 3 => when others => True);" & ASCII.LF &
        "   After         : constant Boolean := True;" & ASCII.LF &
        "end Quantified_Predicate_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Expression),
              "quantified expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Arrow),
              "quantified predicate recovery must preserve arrow metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Quantified_Missing_Predicate_Recovery_Boundary),
              "quantified expressions missing predicates must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "quantified predicate recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "quantified predicate recovery must preserve following declarations");
   end Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery;

   procedure Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Declare_Expression_Body_Recovery is" & ASCII.LF &
        "   Missing_Close : constant Integer := (declare X : Integer := 1; begin);" & ASCII.LF &
        "   Missing_Comma : constant Integer := (declare X : Integer := 1; begin, 2);" & ASCII.LF &
        "   Missing_When  : constant Integer := (declare X : Integer := 1; begin when others => 0);" & ASCII.LF &
        "   After         : constant Integer := 42;" & ASCII.LF &
        "end Declare_Expression_Body_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression),
              "declare expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression_Begin_Keyword),
              "declare expression body recovery must preserve begin metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Declare_Expression_Missing_Body_Recovery_Boundary),
              "declare expressions missing body expressions must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "declare expression body recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "declare expression body recovery must preserve following declarations");
   end Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery;

   procedure Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Iterated_Component_Expression_Recovery is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Missing_Close : constant Vector := (for I in 1 .. 3 =>);" & ASCII.LF &
        "   Missing_Comma : constant Vector := (for I in 1 .. 3 =>, 0);" & ASCII.LF &
        "   Missing_When  : constant Vector := (for I in 1 .. 3 => when others => 0);" & ASCII.LF &
        "   After         : constant Integer := 42;" & ASCII.LF &
        "end Iterated_Component_Expression_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association),
              "iterated component associations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association_Arrow),
              "iterated component expression recovery must preserve arrow metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Iterated_Component_Missing_Expression_Recovery_Boundary),
              "iterated component associations missing component expressions must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "iterated component expression recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "iterated component expression recovery must preserve following declarations");
   end Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery;

   procedure Test_Language_Model_Token_Cursor_Delta_Aggregate_Keyword_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Delta_Aggregate_Detail is" & ASCII.LF &
        "   type Point is record" & ASCII.LF &
        "      X, Y : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Base : Point := (X => 1, Y => 2);" & ASCII.LF &
        "   Good : Point := (Base with delta X => 3, Y => 4);" & ASCII.LF &
        "   Broken : Point := (Base with delta);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Delta_Aggregate_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate),
              "delta aggregates must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate_With_Keyword),
              "delta aggregates must retain the top-level with keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate_Delta_Keyword),
              "delta aggregates must retain the delta keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate_Association_Separator),
              "delta aggregate association lists must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate_Missing_Association_Recovery_Boundary),
              "empty/in-progress delta aggregate association lists must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "delta aggregate recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Delta_Aggregate_Keyword_Recovery;

   procedure Test_Language_Model_Token_Cursor_Extension_Aggregate_Keyword_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Extension_Aggregate_Detail is" & ASCII.LF &
        "   type Root is tagged record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Child is new Root with record" & ASCII.LF &
        "      B, C : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Good : Child := (Root'(A => 1) with B => 2, C => 3);" & ASCII.LF &
        "   Empty : Child := (Root'(A => 1) with);" & ASCII.LF &
        "   Null_Ext : Child := (Root'(A => 1) with null record);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Extension_Aggregate_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extension_Aggregate),
              "extension aggregates must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extension_Aggregate_With_Keyword),
              "extension aggregates must retain the top-level with keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extension_Aggregate_Component_Separator),
              "extension aggregate component lists must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extension_Aggregate_Missing_Association_Recovery_Boundary),
              "empty/in-progress extension aggregate component lists must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Record_Aggregate),
              "null-record extension aggregates must preserve their dedicated marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "extension aggregate recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Extension_Aggregate_Keyword_Recovery;

   procedure Test_Language_Model_Token_Cursor_Null_Record_Aggregate_Keyword_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Null_Record_Aggregate_Detail is" & ASCII.LF &
        "   type Root is tagged record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Child is new Root with null record;" & ASCII.LF &
        "   Good : Child := (Root'(A => 1) with null record);" & ASCII.LF &
        "   Broken : Child := (Root'(A => 1) with null);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Null_Record_Aggregate_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Record_Aggregate),
              "null-record extension aggregates must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Record_Aggregate_Null_Keyword),
              "null-record aggregates must retain the null keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Record_Aggregate_Record_Keyword),
              "null-record aggregates must retain the record keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Record_Aggregate_Missing_Record_Recovery_Boundary),
              "malformed null-record aggregates must retain bounded missing-record recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "null-record aggregate recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Null_Record_Aggregate_Keyword_Recovery;

   procedure Test_Language_Model_Token_Cursor_Iterated_Component_Arrow_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Iterated_Component_Arrow_Detail is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Good : Vector := (for I in 1 .. 3 => I);" & ASCII.LF &
        "   Filtered : Vector := (for I in 1 .. 3 when I > 1 => I);" & ASCII.LF &
        "   Broken : Vector := (for I in 1 .. 3);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Iterated_Component_Arrow_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association),
              "iterated component associations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Domain),
              "iterated component associations must retain their iteration domain");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Iterator_Filter),
              "iterated component associations must retain iterator filter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association_Arrow),
              "iterated component associations must retain explicit arrow metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Expression),
              "iterated component associations must retain component expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Missing_Arrow_Recovery_Boundary),
              "malformed iterated component associations must retain bounded missing-arrow recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "iterated component recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Iterated_Component_Arrow_Recovery;

   procedure Test_Language_Model_Token_Cursor_Iterated_Component_Domain_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Iterated_Component_Domain_Detail is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Good : Vector := (for I in 1 .. 3 => I);" & ASCII.LF &
        "   Filtered : Vector := (for I in 1 .. 3 when I > 1 => I);" & ASCII.LF &
        "   Broken_Arrow : Vector := (for I in 1 .. 3);" & ASCII.LF &
        "   Broken_Domain : Vector := (for I in => I);" & ASCII.LF &
        "   Broken_Filter_Domain : Vector := (for I in when I > 0 => I);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Iterated_Component_Domain_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association),
              "iterated component associations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Domain),
              "well-formed iterated component associations must retain domain metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Iterator_Filter),
              "iterated component association filters must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Missing_Domain_Recovery_Boundary),
              "missing iterated component domains must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association_Arrow),
              "domain recovery must leave the association arrow visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "iterated component domain recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Iterated_Component_Domain_Recovery;

   procedure Test_Language_Model_Token_Cursor_Loop_Iteration_Domain_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Loop_Domain_Detail is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   for I in 1 .. 3 loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for I in when I > 0 loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for E of Items loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for E of when Ready loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   After;" & ASCII.LF &
        "end Loop_Domain_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Domain),
              "well-formed for loops must retain iteration-domain metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Missing_Domain_Recovery_Boundary),
              "for loops with missing domains must retain bounded domain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Domain),
              "well-formed iterator loops must retain domain metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Missing_Domain_Recovery_Boundary),
              "iterator loops with missing domains must retain bounded domain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter),
              "domain recovery must leave loop iterator filters visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Begin_Keyword),
              "loop domain recovery must leave the loop keyword visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "loop domain recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Loop_Iteration_Domain_Recovery;

   procedure Test_Language_Model_Token_Cursor_Iterator_Filter_Condition_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Iterator_Filter_Condition_Detail is" & ASCII.LF &
        "   Quantified : constant Boolean := (for all I in 1 .. 3 when => I > 0);" & ASCII.LF &
        "   Components : constant Integer := (for I in 1 .. 3 when => I);" & ASCII.LF &
        "   After_Expr : constant Integer := 1;" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      for I in 1 .. 3 when loop" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      for E of Items when loop" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      After_Call;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Iterator_Filter_Condition_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Iterator_Filter),
              "quantified iterator filters must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Iterator_Filter_Missing_Condition_Recovery_Boundary),
              "quantified iterator filters with missing conditions must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Arrow),
              "quantified filter-condition recovery must leave the quantified arrow visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Iterator_Filter),
              "iterated component filters must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary),
              "iterated component filters with missing conditions must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association_Arrow),
              "iterated component filter-condition recovery must leave the association arrow visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter),
              "loop iterator filters must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary),
              "loop iterator filters with missing conditions must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Begin_Keyword),
              "loop filter-condition recovery must leave loop keywords visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "loop filter-condition recovery must leave following statements visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "filter-condition recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Iterator_Filter_Condition_Recovery;

   procedure Test_Language_Model_Token_Cursor_Exit_When_Condition_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Exit_When_Condition_Detail is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      loop" & ASCII.LF &
        "         exit when Ready;" & ASCII.LF &
        "         exit when;" & ASCII.LF &
        "         After_Call;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Exit_When_Condition_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "exit statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Keyword),
              "exit statements with when clauses must retain when-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "well-formed exit-when statements must retain condition metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Missing_Condition_Recovery_Boundary),
              "exit-when statements with missing conditions must retain bounded condition recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Terminator),
              "exit-when condition recovery must leave statement terminators visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "exit-when condition recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Exit_When_Condition_Recovery;

   overriding function Name (T : TokenCursorExpressionRecovery_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Token-Cursor-Expression-Recovery-Tests");
   end Name;

   overriding procedure Register_Tests (T : in out TokenCursorExpressionRecovery_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Raise_Expression_Message_Recovery'Access, Name => "token-cursor grammar records raise-expression missing-message recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery'Access, Name => "token-cursor grammar records declare-expression begin keyword and missing-begin recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth'Access, Name => "token-cursor grammar deepens expression recovery for conditionals cases and reductions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth'Access, Name => "token-cursor grammar deepens name grammar recovery for selected names allocators and qualified expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Conditional_Expression_Recovery'Access, Name => "token-cursor grammar recovers conditional expression missing operands structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery'Access, Name => "token-cursor grammar recovers expression and name edge cases structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_If_Expression_Else_Recovery'Access, Name => "token-cursor grammar retains if-expression else recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery'Access, Name => "token-cursor grammar records if-expression then recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Expression_Recovery'Access, Name => "token-cursor grammar retains case-expression recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Quantified_Recovery'Access, Name => "token-cursor grammar retains quantified-expression recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery'Access, Name => "token-cursor grammar recovers case-expression alternatives missing dependent expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery'Access, Name => "token-cursor grammar recovers malformed reduction attribute argument parts");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery'Access, Name => "token-cursor grammar recovers quantified expressions missing predicates");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery'Access, Name => "token-cursor grammar recovers declare expressions missing body expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery'Access, Name => "token-cursor grammar recovers iterated component associations missing component expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Delta_Aggregate_Keyword_Recovery'Access, Name => "token-cursor grammar records delta aggregate keyword and recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Extension_Aggregate_Keyword_Recovery'Access, Name => "token-cursor grammar records extension aggregate keyword and recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Null_Record_Aggregate_Keyword_Recovery'Access, Name => "token-cursor grammar records null-record aggregate keyword and recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Iterated_Component_Arrow_Recovery'Access, Name => "token-cursor grammar records iterated component association arrow and recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Iterated_Component_Domain_Recovery'Access, Name => "token-cursor grammar records iterated component association missing-domain recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Loop_Iteration_Domain_Recovery'Access, Name => "token-cursor grammar records loop iteration missing-domain recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Iterator_Filter_Condition_Recovery'Access, Name => "token-cursor grammar records iterator-filter missing-condition recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exit_When_Condition_Recovery'Access, Name => "token-cursor grammar records exit-when missing-condition recovery metadata");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Expression_Recovery_Tests;
