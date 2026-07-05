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

package body Editor.Syntax_Semantics.Token_Cursor_Expression_Tests is





   procedure Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Quantified_Expression_Grammar is" & ASCII.LF &
        "   Ok_1 : constant Boolean := (for all I in 1 .. 10 => I > 0);" & ASCII.LF &
        "   Ok_2 : constant Boolean := (for some Element of reverse Items => Element.Valid);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Quantified_Expression_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Expression),
              "token-cursor grammar must retain quantified expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Parameter_Specification),
              "quantified expressions with in must retain loop-parameter specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Specification),
              "quantified expressions with of must retain iterator specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "quantified-expression parsing must recover following statements");
   end Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Name_Target_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Name_Target_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Obj.Field := Source.Value;" & ASCII.LF &
        "   Arr (Index) := Obj.Field;" & ASCII.LF &
        "   Arr (First .. Last) := Other (1 .. 2);" & ASCII.LF &
        "   Ptr.all := Obj.Field;" & ASCII.LF &
        "   Pkg.Op (Named => Arr (Index));" & ASCII.LF &
        "end Name_Target_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "token-cursor grammar must classify selected/indexed/dereference name targets as assignments");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "token-cursor grammar must retain selected-name suffixes in statement targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Indexed_Component),
              "token-cursor grammar must retain indexed-component suffixes in statement targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Slice),
              "token-cursor grammar must distinguish slice suffixes from ordinary indexed components");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Explicit_Dereference),
              "token-cursor grammar must retain explicit dereference suffixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Statement),
              "token-cursor grammar must retain selected calls with actual parts as call/entry-call forms");
   end Test_Language_Model_Token_Cursor_Name_Target_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Use_Clause_Name_List_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ada.Text_IO, Ada.Strings.Unbounded, Interfaces.C;" & ASCII.LF &
        "use Ada.Text_IO, Ada.Strings.Unbounded;" & ASCII.LF &
        "use type Ada.Strings.Unbounded.Unbounded_String, Interfaces.C.int;" & ASCII.LF &
        "use all type Ada.Strings.Unbounded.Unbounded_String'Class, Interfaces.C.long;" & ASCII.LF &
        "procedure Use_Clause_Name_List_Demo is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Use_Clause_Name_List_Demo;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Clause),
              "token-cursor grammar must retain ordinary use clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Type_Clause),
              "token-cursor grammar must retain use type clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_All_Type_Clause),
              "token-cursor grammar must retain use all type clauses");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Package_Name_List) >= 1,
              "ordinary use clauses must retain an explicit name-list production");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark_List) >= 2,
              "use type and use all type clauses must retain explicit subtype-mark list productions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Clause_Separator) >= 3,
              "comma separators in use-clause lists must be retained structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Package_Name) >= 2,
              "ordinary use clauses must retain every package name in the comma-separated list");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark) >= 4,
              "use type and use all type clauses must retain each subtype mark in the comma-separated list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "use-clause names must retain selected-name structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Reference),
              "use all type subtype marks must retain class-wide attribute suffixes");
   end Test_Language_Model_Token_Cursor_Use_Clause_Name_List_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Expression_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Obj : access Integer := new Integer'(42);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Value in 1 | 2 | 3 and then Flag or else raise Program_Error with ""bad"" then" & ASCII.LF &
        "      Obj.all := (Obj.all with delta 1 => 2);" & ASCII.LF &
        "      Total := Items'Reduce (""+"", 0);" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Run;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator),
              "token-cursor grammar must parse allocator expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "token-cursor grammar must parse allocator qualified expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice_List),
              "token-cursor grammar must parse membership choice lists");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice),
              "token-cursor grammar must parse individual membership choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Short_Circuit_Operation),
              "token-cursor grammar must retain and then/or else short-circuit operators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression),
              "token-cursor grammar must parse raise expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Exception_Name),
              "raise expressions must retain their exception-name position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "raise expressions must retain their message-expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate),
              "token-cursor grammar must parse delta aggregates");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Expression),
              "token-cursor grammar must detect reduction attribute expressions");
   end Test_Language_Model_Token_Cursor_Expression_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Return_Expression_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "function Choose (Ready : Boolean) return Item is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      return Item'(Build (1));" & ASCII.LF &
        "   else" & ASCII.LF &
        "      return (case Mode is" & ASCII.LF &
        "                when Fast => Make_Fast," & ASCII.LF &
        "                when others => raise Program_Error with ""bad mode"");" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   Done := True;" & ASCII.LF &
        "end Choose;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Statement),
              "return statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Expression),
              "simple return statements must retain their returned expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "return expressions must retain nested qualified expressions structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "return expressions must retain nested case expressions structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression),
              "return expressions must retain nested raise expressions structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "return expression parsing must recover into following statements");
   end Test_Language_Model_Token_Cursor_Return_Expression_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Target_Name_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Target_Name_Grammar is" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "   Next  : Integer := 1;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Value := @ + Next;" & ASCII.LF &
        "   Value := Integer'(@);" & ASCII.LF &
        "end Target_Name_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "target-name expressions must remain inside assignment statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Target_Name),
              "Ada 2022 target_name @ must be retained as a primary production");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "target-name parsing must not break qualified/attribute-style expression recovery");
   end Test_Language_Model_Token_Cursor_Target_Name_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "package Box_Expression_Grammar is" & ASCII.LF &
        "   type Vec is array (Positive range <>) of Element;" & ASCII.LF &
        "   Defaults : Vec (1 .. 3) := (others => <>);" & ASCII.LF &
        "end Box_Expression_Grammar;" & ASCII.LF &
        "with Box_Expression_Grammar;" & ASCII.LF &
        "package Box_Expression_Instance is new Box_Expression_Grammar" & ASCII.LF &
        "  (Element => <>);";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Box_Expression),
              "Ada box expressions <> must be retained as expression primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate),
              "box expressions inside aggregate associations must not break aggregate parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Instantiation),
              "box expressions inside generic actual associations must preserve instantiation parsing");
   end Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Attribute_Argument_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Attribute_Argument_Grammar is" & ASCII.LF &
        "   type Vec is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Values : Vec (1 .. 4) := (1, 2, 3, 4);" & ASCII.LF &
        "   First_Index : Positive := 1;" & ASCII.LF &
        "   Image : String := Integer'Image (Values (First_Index));" & ASCII.LF &
        "begin" & ASCII.LF &
        "   First_Index := Values'First (1);" & ASCII.LF &
        "   First_Index := Values'Reduce (""+"", 0);" & ASCII.LF &
        "end Attribute_Argument_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Reference),
              "attribute references must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_Part),
              "attribute references with arguments must not be flattened to indexed components");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Expression),
              "reduction attributes must still retain reduction-expression metadata");
   end Test_Language_Model_Token_Cursor_Attribute_Argument_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Membership_Range_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Value in 1 .. 10 | Natural range 20 .. 30 | Other then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   elsif Value not in range 100 .. 200 | 300 .. 400 then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Membership_Range_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice_List),
              "membership relations must retain choice-list grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice),
              "membership relations must retain individual choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Expression),
              "membership choices must retain explicit and subtype range grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "membership range parsing must consume ranges without breaking statement recovery");
   end Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Conditional_Expression_Branch_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Conditional_Branch_Grammar is" & ASCII.LF &
        "   Value : Integer :=" & ASCII.LF &
        "     (if Flag then 1" & ASCII.LF &
        "      elsif Other then Integer'(2)" & ASCII.LF &
        "      else (case Mode is when 0 => 3, when others => raise Program_Error with ""bad""));" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Value := (if Value > 0 then Value else 0);" & ASCII.LF &
        "end Conditional_Branch_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Expression),
              "conditional expressions must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Condition),
              "conditional expressions must retain condition positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Then_Dependent_Expression),
              "conditional expressions must retain then and elsif dependent expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Else_Dependent_Expression),
              "conditional expressions must retain else dependent expressions explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "else dependent expressions may contain nested case expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression),
              "else dependent expressions may contain nested raise expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "conditional expression parsing must recover into the following declaration");
   end Test_Language_Model_Token_Cursor_Conditional_Expression_Branch_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Expression_Refinement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Expression_Refinement_Grammar is" & ASCII.LF &
        "   Value : Integer :=" & ASCII.LF &
        "     (if Flag then" & ASCII.LF &
        "        (case Mode is when 0 | 1 => Integer'(1), when others => 2)" & ASCII.LF &
        "      elsif Other then" & ASCII.LF &
        "        (for all I in 1 .. 10 when I > 0 => I < 11)" & ASCII.LF &
        "      else new Integer'(3));" & ASCII.LF &
        "   Sum : Integer := Values'Parallel_Reduce (Plus, 0);" & ASCII.LF &
        "   Mapped : Integer := Values'Map_Reduce (Image, Combine, Initial);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Expression_Refinement_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Branch_Expression),
              "if expressions must retain branch-expression markers for nested expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Choice_List),
              "case expressions must retain explicit choice-list markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Arrow),
              "case expression alternatives must retain arrow positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Arrow),
              "quantified expressions must retain the predicate arrow position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Reduction_Expression),
              "parallel reductions must be distinguishable from ordinary reductions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Map_Reduction_Expression),
              "map reductions must be distinguishable from ordinary reductions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Qualified_Expression),
              "allocator qualified expressions must remain visible inside expression branches");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "nested expression parsing must recover into following declarations");
   end Test_Language_Model_Token_Cursor_Expression_Refinement_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Declare_Expression_Grammar is" & ASCII.LF &
        "   Total : Integer :=" & ASCII.LF &
        "     (declare" & ASCII.LF &
        "        Left  : constant Integer := 1;" & ASCII.LF &
        "        Right : constant Integer := 2;" & ASCII.LF &
        "      begin" & ASCII.LF &
        "        Left + Right);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Total := (declare Temp : constant Integer := Total; begin Temp + 1);" & ASCII.LF &
        "end Declare_Expression_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression),
              "token-cursor grammar must parse Ada 2022 declare expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression_Declarative_Part),
              "declare expressions must retain their declarative part explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Expression_Body_Expression),
              "declare expressions must retain their body expression explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "declare-expression declarative parts must retain nested object declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "declare expressions used in assignments must not break statement parsing");
   end Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Aggregate_Iterator_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Aggregate_Iterator_Grammar is" & ASCII.LF &
        "   Squares : constant array (1 .. 4) of Integer :=" & ASCII.LF &
        "     (for I in 1 .. 4 => I * I);" & ASCII.LF &
        "   Evens : constant array (1 .. 2) of Integer :=" & ASCII.LF &
        "     (for I in 1 .. 4 when I mod 2 = 0 => I);" & ASCII.LF &
        "   Copied : constant array (1 .. 4) of Integer :=" & ASCII.LF &
        "     (for Element of reverse Squares when Element > 0 => Element);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Values := (1 => 0, for I in 2 .. 4 => I);" & ASCII.LF &
        "   Copied := (for Element of reverse Squares => Element);" & ASCII.LF &
        "end Aggregate_Iterator_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Association),
              "aggregate iterated component associations must not be parsed as quantified expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Parameter_Specification),
              "aggregate for-in associations must retain their loop parameter specification");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Specification),
              "aggregate for-of associations must retain their iterator specification");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Domain),
              "aggregate iterator associations must retain their domain expression or range");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Iterator_Filter),
              "aggregate iterator associations must retain optional iterator filters");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterated_Component_Expression),
              "aggregate iterator associations must retain the component expression after =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Expression),
              "aggregate iterator domains must retain discrete ranges structurally");
      Assert (not Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Expression),
              "aggregate iterator associations must stay separate from quantified expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Association_List),
              "aggregate association lists must remain structurally visible");
   end Test_Language_Model_Token_Cursor_Aggregate_Iterator_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Delta_Aggregate_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Delta_Aggregate_Grammar is" & ASCII.LF &
        "   type Pair is record A, B : Integer; end record;" & ASCII.LF &
        "   Base : Pair := (A => 1, B => 2);" & ASCII.LF &
        "   Next : Pair := (Base with delta A => 3, B => 4);" & ASCII.LF &
        "   More : Pair := (Pair'(A => 1, B => 2) with delta" & ASCII.LF &
        "      A | B => 5);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Next := (Next with delta A => @ + 1);" & ASCII.LF &
        "end Delta_Aggregate_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate),
              "delta aggregates must remain distinct from ordinary aggregates");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate_Base),
              "delta aggregates must retain their base expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate_Association),
              "delta aggregate associations after with delta must be structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "delta aggregate associations must retain choice lists before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Target_Name),
              "delta aggregate expressions must still parse Ada 2022 target-name primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "delta aggregate parsing must recover into the following object declaration");
   end Test_Language_Model_Token_Cursor_Delta_Aggregate_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Aggregate_Component_Association_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Aggregate_Component_Association is" & ASCII.LF &
        "   Value : Table := (A | B => 1, 1 .. 10 => 2, others => <>);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Aggregate_Component_Association;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Association),
              "aggregate component associations must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "aggregate choices before => must use the discrete choice-list grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice),
              "aggregate associations must retain individual choices separated by |");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Expression),
              "aggregate associations must retain range choices before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Box_Expression),
              "aggregate associations must preserve others => <> box values");
   end Test_Language_Model_Token_Cursor_Aggregate_Component_Association_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Parenthesized_Aggregate_Association_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Parenthesized_Aggregate_Associations is" & ASCII.LF &
        "   Base  : Table := (others => 0);" & ASCII.LF &
        "   Value : Table := (A | B => 1, 1 .. 10 => 2, others => <>);" & ASCII.LF &
        "   Next  : Table := (Base with delta A | B => 3, others => <>);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Parenthesized_Aggregate_Associations;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate),
              "ordinary parenthesized aggregates must remain aggregate primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Aggregate),
              "delta aggregates must remain explicit delta aggregate grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Association),
              "first aggregate association items must not bypass component-association grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "parenthesized aggregate associations must retain choice lists before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Box_Expression),
              "parenthesized aggregate associations must retain box expression values");
   end Test_Language_Model_Token_Cursor_Parenthesized_Aggregate_Association_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Generic_Actual_Box_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Actuals is" & ASCII.LF &
        "   package Defaults is new Templates" & ASCII.LF &
        "     (Element_Type => Items.Element," & ASCII.LF &
        "      Make => <>," & ASCII.LF &
        "      ""="" => Items.Equal," & ASCII.LF &
        "      Capacity);" & ASCII.LF &
        "end Actuals;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Instantiation),
              "package instantiations must remain explicit generic instantiations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Part),
              "generic instantiations must retain actual-part grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Association),
              "generic actuals must retain individual association nodes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Formal_Selector),
              "named generic actual associations must retain formal selector names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Box),
              "generic actual associations must retain => <> box defaults structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "generic actual expressions must still retain selected-name actuals");
   end Test_Language_Model_Token_Cursor_Generic_Actual_Box_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Entry_Call_Select_Depth is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Server.Start (42);" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay 1.0;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Server.Stop;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      After : Integer;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Entry_Call_Select_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Entry_Call_Alternative),
              "select entry-call alternatives must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Timed_Entry_Call_Statement),
              "entry calls in select statements with delay alternatives must retain timed-entry-call metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Timed_Entry_Call_Entry_Call_Part),
              "timed entry calls must retain entry-call-part metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Entry_Call_Statement),
              "entry calls in select statements with else parts must retain conditional-entry-call metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Entry_Call_Entry_Call_Part),
              "conditional entry calls must retain entry-call-part metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "timed/conditional entry-call parsing must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call;




   procedure Test_Language_Model_Token_Cursor_Selected_Literal_Name_Refinement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Selected_Literal_Name_Refinement is" & ASCII.LF &
        "   Value : Integer := Operator_Types.""+""'(5);" & ASCII.LF &
        "   Ptr   : access Integer := new Operator_Types.""+""'(5);" & ASCII.LF &
        "   Ch    : Character := Enum_Types.'A''(Value);" & ASCII.LF &
        "   Plain : Character := Enum_Types.'A';" & ASCII.LF &
        "end Selected_Literal_Name_Refinement;";
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
                (Editor.Ada_Token_Cursor.Production_Selected_Selector) >= 4,
              "literal selected-name selectors must also be visible as generic selected selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Qualified_Expression_Selected_Literal_Subtype_Mark),
              "qualified expressions with selected literal subtype marks must retain literal-subtype metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Qualified_Expression_Selected_Operator_Subtype_Mark),
              "qualified expressions with selected operator subtype marks must retain operator-subtype metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Qualified_Expression_Selected_Character_Subtype_Mark),
              "qualified expressions with selected character subtype marks must retain character-subtype metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Allocator_Selected_Operator_Subtype_Mark),
              "allocator subtype indications with selected operator suffixes must retain allocator-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "selected literal name parsing must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Selected_Literal_Name_Refinement;




   procedure Test_Language_Model_Token_Cursor_Defining_Name_And_Operator_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with function ""+"" (Left, Right : Obj) return Obj is <>;" & ASCII.LF &
        "package Operators is" & ASCII.LF &
        "   type Obj is private;" & ASCII.LF &
        "   subtype Obj_Subtype is Obj;" & ASCII.LF &
        "   function ""="" (Left, Right : Obj) return Boolean;" & ASCII.LF &
        "   procedure Reset (Self : in out Obj);" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Obj is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Operators;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Defining_Name),
              "token-cursor grammar must retain ordinary defining names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Defining_Operator_Symbol),
              "token-cursor grammar must retain quoted operator defining symbols");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Declaration),
              "generic formal operator subprograms must remain parsed as formal subprogram declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Type_Declaration),
              "type defining names must remain attached to type declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "subtype defining names must remain attached to subtype declarations");
   end Test_Language_Model_Token_Cursor_Defining_Name_And_Operator_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Aggregate_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aggregate_Delimiters is" & ASCII.LF &
        "   type Point is record" & ASCII.LF &
        "      X, Y : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Positional : Vector := (1, 2, 3);" & ASCII.LF &
        "   Named : Point := (X => 1, Y => 2);" & ASCII.LF &
        "   Boxed : Vector := (1 => <>, others => 0);" & ASCII.LF &
        "   Broken : Point := (X => 1, Y => 2;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Aggregate_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate),
              "aggregates must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Open_Delimiter),
              "aggregates must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Close_Delimiter),
              "well-formed aggregates must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Component_Separator),
              "multi-component aggregates must retain comma separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Missing_Close_Recovery_Boundary),
              "malformed aggregates must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Named_Component_Association),
              "named aggregate component associations must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Box_Component),
              "box components must remain visible inside aggregate delimiter parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Terminator),
              "aggregate recovery must leave following object declaration terminators available");
   end Test_Language_Model_Token_Cursor_Aggregate_Delimiters;



   procedure Test_Language_Model_Token_Cursor_Attribute_Definition_Detail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Attribute_Definition_Detail is" & ASCII.LF &
        "   type Word is range 0 .. 255;" & ASCII.LF &
        "   for Word'Size use 8;" & ASCII.LF &
        "   for Word'Alignment use 4;" & ASCII.LF &
        "   type Table is array (Positive range <>) of Word;" & ASCII.LF &
        "   for Table'Component_Size use 8;" & ASCII.LF &
        "   type Tagged_Item is tagged null record;" & ASCII.LF &
        "   for Tagged_Item'External_Tag use ""tagged-item"";" & ASCII.LF &
        "   Task_Object : Integer;" & ASCII.LF &
        "   for Task_Object'Storage_Size use 4096;" & ASCII.LF &
        "   procedure Read_Word (Stream : access Root_Stream_Type'Class; Item : out Word);" & ASCII.LF &
        "   for Word'Read use Read_Word;" & ASCII.LF &
        "end Attribute_Definition_Detail;";
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
                (Editor.Ada_Token_Cursor.Production_Size_Attribute_Definition_Clause) >= 2,
              "Size and Component_Size attribute-definition clauses must have family-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Alignment_Attribute_Definition_Clause),
              "Alignment attribute-definition clauses must be classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_External_Tag_Attribute_Definition_Clause),
              "External_Tag attribute-definition clauses must be classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Storage_Attribute_Definition_Clause),
              "storage-related attribute-definition clauses must be classified structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Stream_Attribute_Definition_Clause),
              "stream attribute-definition clauses must retain their existing classification");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Attribute_Definition_Clause) >= 6,
              "attribute-definition clauses must still use the shared attribute-definition production");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Representation_Value_Expression) >= 5,
              "attribute-definition clause values must still retain value-expression metadata");
   end Test_Language_Model_Token_Cursor_Attribute_Definition_Detail;



   procedure Test_Language_Model_Token_Cursor_Attribute_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Attribute_Depth is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Child is new Root with null record;" & ASCII.LF &
        "   type Root_Class_Access is access all Root'Class;" & ASCII.LF &
        "   type Index is range 1 .. 10;" & ASCII.LF &
        "   type Vector is array (Index) of Integer;" & ASCII.LF &
        "   V : Vector := (others => 0);" & ASCII.LF &
        "   First : constant Index := V'First (1);" & ASCII.LF &
        "   Img : constant String := Integer'Image (V'Length (1));" & ASCII.LF &
        "   Size : constant Natural := Root'Class'Object_Size;" & ASCII.LF &
        "   Broken : constant Integer := V'Value (Index => );" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Attribute_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Attribute_Reference) >= 5,
              "attribute references must remain visible across expressions and subtype marks");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Attribute_Designator_Name) >= 5,
              "attribute references and definition clauses must retain explicit designator names");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Attribute_Argument_Part) >= 3,
              "attribute calls must retain their argument parts as attribute syntax");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Attribute_Argument_Association) >= 3,
              "attribute argument parts must retain association entries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Attribute_Argument_Expression) >= 2,
              "attribute argument associations must retain expression payload positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Classwide_Attribute_Reference),
              "class-wide attribute chains such as T'Class'Object_Size must be marked");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Subtype_Mark_Reference),
              "attribute references in subtype marks such as T'Class must be classified separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Recovery_Boundary),
              "malformed attribute argument lists must retain a bounded recovery marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 2,
              "attribute argument recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Attribute_Depth_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Expression_Literal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Expr_Literals is" & ASCII.LF &
        "   N : constant := 16#FF#;" & ASCII.LF &
        "   S : String := ""Hello"";" & ASCII.LF &
        "   C : Character := 'A';" & ASCII.LF &
        "   B : Boolean := C in 'A' | 'B' and then S /= """";" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Expr_Literals;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Numeric_Literal),
              "numeric literals must be retained as expression primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_String_Literal),
              "string literals must be retained as expression primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Character_Literal),
              "character literals must be retained as expression primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice),
              "literal membership choices must remain structurally visible");
   end Test_Language_Model_Token_Cursor_Expression_Literal_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Compiler_Complete_Expression_Grammar
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Expr_Complete is" & ASCII.LF &
        "   A : Boolean := (if X not in 1 | 2 | 3 then Y = null elsif Z then F (1 + 2 * 3 ** 4) else raise Constraint_Error);" & ASCII.LF &
        "   B : Integer := (case Kind is when One | Two => 1, when others => Integer'(0));" & ASCII.LF &
        "   C : Boolean := (for all I in 1 .. 10 => Data (I) /= 0);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Expr_Complete;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parenthesized_Expression),
              "parenthesized expressions must be retained separately from aggregate association lists");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Condition),
              "if expression conditions must be explicit grammar children");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Then_Dependent_Expression),
              "if expression dependent expressions must be explicit grammar children");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Elsif_Expression_Part),
              "elsif expression parts must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Else_Expression_Part),
              "else expression parts must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Selector),
              "case expression selectors must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Alternative),
              "case expression alternatives must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Dependent_Expression),
              "case expression dependent expressions must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantifier),
              "quantified expression quantifiers must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Loop_Scheme),
              "quantified loop schemes must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Operator),
              "membership operators must be retained separately from the choice list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Relational_Operator),
              "relational operators must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Expression_Operator),
              "arithmetic logical and exponentiation operators must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Literal),
              "null literals must be retained as primaries");
   end Test_Language_Model_Token_Cursor_Compiler_Complete_Expression_Grammar;



   procedure Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Case_Expression_Dependent is" & ASCII.LF &
        "   A : Integer := (case Mode is" & ASCII.LF &
        "      when One | Two => (if Ready then 1 else 2)," & ASCII.LF &
        "      when Three => Integer'(3)," & ASCII.LF &
        "      when others => raise Program_Error with ""bad mode"");" & ASCII.LF &
        "   B : Integer := 4;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Case_Expression_Dependent;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "case expressions must remain visible as primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Dependent_Expression),
              "case alternatives must retain dependent-expression positions after =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression_Then_Dependent_Expression),
              "nested dependent expressions inside case alternatives must still be parsed");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression_Operand),
              "qualified dependent expressions inside alternatives must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "raise dependent expressions inside alternatives must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "case expression recovery must continue into the following declaration");
   end Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Allocator_Deep_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Allocator_Deep is" & ASCII.LF &
        "   type Item is record Value : Integer; end record;" & ASCII.LF &
        "   type Item_Access is access Item;" & ASCII.LF &
        "   A : Item_Access := new Item;" & ASCII.LF &
        "   B : Item_Access := new Item'(Value => 1);" & ASCII.LF &
        "   C : Item_Access := new Item'(others => <>);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Allocator_Deep;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator),
              "allocators must remain visible as expression primaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Subtype_Indication),
              "allocator subtype indications must be retained separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Qualified_Expression),
              "qualified-expression allocators must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Initialized_Expression),
              "initialized allocators must expose their aggregate/expression part");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Association),
              "allocator aggregate associations must remain visible to semantic consumers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Box_Expression),
              "allocator aggregate box defaults must retain box-expression structure");
   end Test_Language_Model_Token_Cursor_Allocator_Deep_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Allocator_Constraint_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Allocator_Constraints is" & ASCII.LF &
        "   type Index is range 1 .. 10;" & ASCII.LF &
        "   type Vector is array (Index range <>) of Integer;" & ASCII.LF &
        "   type Discriminated (Size : Natural) is record" & ASCII.LF &
        "      Data : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Vector_Access is access Vector;" & ASCII.LF &
        "   type Item_Access is access all Discriminated;" & ASCII.LF &
        "   type Class_Access is access all Discriminated'Class;" & ASCII.LF &
        "   A : Vector_Access := new Vector (1 .. 4);" & ASCII.LF &
        "   B : Item_Access := new Discriminated (Size => 4);" & ASCII.LF &
        "   C : Class_Access := new not null Discriminated'Class;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Allocator_Constraints;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Null_Exclusion),
              "allocator null exclusions must be retained as allocator-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Index_Constraint),
              "allocator index constraints must be retained separately from initialized expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Discriminant_Constraint),
              "allocator discriminant constraints must be retained separately from aggregate associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Subtype_Mark),
              "allocator constrained subtype marks must remain visible to semantic consumers");
   end Test_Language_Model_Token_Cursor_Allocator_Constraint_Depth;





   procedure Test_Language_Model_Token_Cursor_Address_Attribute_Clause_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with System;" & ASCII.LF &
        "package Address_Attribute_Clauses is" & ASCII.LF &
        "   Obj  : aliased Integer;" & ASCII.LF &
        "   for Obj'Address use System'To_Address (16#1000#);" & ASCII.LF &
        "   Next : Integer := 1;" & ASCII.LF &
        "end Address_Attribute_Clauses;";
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
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Definition_Clause),
              "Address attribute clauses must remain attribute-definition clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Address_Clause),
              "for X'Address use ... must also be classified as an address clause");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Designator),
              "Address must remain visible as the attribute designator");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 2,
              "address-clause parsing must recover into the following declaration");
   end Test_Language_Model_Token_Cursor_Address_Attribute_Clause_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Name_Attribute_Refinement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Name_Attribute_Refinement is" & ASCII.LF &
        "   Selected_Attr : Integer := Root.Child'Length;" & ASCII.LF &
        "   Complex_Attr  : Integer := Root.Child'Range (1);" & ASCII.LF &
        "   Broken_Q     : Integer := Broken.'(1);" & ASCII.LF &
        "   Broken_A     : access Integer := new Broken.;" & ASCII.LF &
        "   After        : Integer := 0;" & ASCII.LF &
        "end Name_Attribute_Refinement;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Selected_Prefix),
              "attribute references with selected-name prefixes must retain selected-prefix metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Complex_Prefix),
              "attribute references with complex prefixes must retain complex-prefix metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark),
              "qualified-expression contexts with dangling selected subtype marks must retain specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Allocator_Incomplete_Selected_Subtype_Mark),
              "allocator subtype indications with dangling selected subtype marks must retain allocator-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name_Missing_Selector),
              "incomplete selected names must preserve generic missing-selector recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "name/attribute recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Name_Attribute_Refinement;


   procedure Test_Language_Model_Token_Cursor_Qualified_Expression_Part_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Qualified_Expression_Parts is" & ASCII.LF &
        "   type Count is range 0 .. 100;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Count;" & ASCII.LF &
        "   A : Count := Math.Count'(1);" & ASCII.LF &
        "   B : Vector := Vector'(1 => Count'(2), 2 => Count'(3));" & ASCII.LF &
        "   C : access Count := new Count'(4);" & ASCII.LF &
        "   D : Count := Operator_Types.""+""'(5);" & ASCII.LF &
        "   E : access Count := new Math.Count'(6);" & ASCII.LF &
        "end Qualified_Expression_Parts;";
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
                (Editor.Ada_Token_Cursor.Production_Qualified_Expression) >= 5,
              "qualified expressions must remain visible in ordinary nested and allocator contexts");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Qualified_Expression_Subtype_Mark) >= 5,
              "qualified-expression subtype marks must be retained separately from operands");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Qualified_Expression_Operand) >= 5,
              "qualified-expression operands must be retained separately from subtype marks");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Qualified_Expression),
              "allocator qualified expressions must share the qualified-expression part structure");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Qualified_Expression_Selected_Subtype_Mark) >= 3,
              "selected subtype marks must be retained distinctly for qualified-expression consumers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "selected operator subtype marks must remain visible before the qualification apostrophe");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 5,
              "qualified-expression parsing must recover into following object declarations");
   end Test_Language_Model_Token_Cursor_Qualified_Expression_Part_Grammar_Completeness;











   procedure Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Qualified_Expression_Delimiters is" & ASCII.LF &
        "   type Count is range 0 .. 100;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Count;" & ASCII.LF &
        "   A : Count := Count'(1);" & ASCII.LF &
        "   B : Vector := Vector'(1 => Count'(2), 2 => Count'(3));" & ASCII.LF &
        "   C : access Count := new Count'(4);" & ASCII.LF &
        "   Broken : Count := Count'(5;" & ASCII.LF &
        "   After : Count := Count'(6);" & ASCII.LF &
        "end Qualified_Expression_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "qualified expressions must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression_Operand_Open_Delimiter),
              "qualified-expression operands must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression_Operand_Close_Delimiter),
              "well-formed qualified-expression operands must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary),
              "malformed qualified-expression operands must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Qualified_Expression),
              "allocator qualified expressions must preserve allocator-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Terminator),
              "qualified-expression recovery must leave following object declaration terminators available");
   end Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters;












   procedure Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Parenthesized_Expression_Delimiters is" & ASCII.LF &
        "   A : Integer := (1 + 2);" & ASCII.LF &
        "   B : Boolean := ((A > 0) and then (A < 10));" & ASCII.LF &
        "   C : Integer := (if A > 0 then A else 0);" & ASCII.LF &
        "   Broken : Integer := (A + 1;" & ASCII.LF &
        "   After : Integer := (3);" & ASCII.LF &
        "end Parenthesized_Expression_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parenthesized_Expression),
              "parenthesized expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parenthesized_Expression_Open_Delimiter),
              "parenthesized expressions must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parenthesized_Expression_Close_Delimiter),
              "well-formed parenthesized expressions must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary),
              "malformed parenthesized expressions must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Expression),
              "parenthesized conditional expressions must preserve nested expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Terminator),
              "parenthesized-expression recovery must leave following declaration terminators available");
   end Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters;





   procedure Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Digits_Delta_Constraint_Expressions is" & ASCII.LF &
        "   type Real is digits 10;" & ASCII.LF &
        "   subtype Short_Real is Real digits 6 range -1.0 .. 1.0;" & ASCII.LF &
        "   type Fixed is delta 0.01 range -10.0 .. 10.0;" & ASCII.LF &
        "   subtype Short_Fixed is Fixed delta 0.1 digits 4;" & ASCII.LF &
        "   subtype Broken_Digits is Real digits ;" & ASCII.LF &
        "   subtype Broken_Delta is Fixed delta ;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Digits_Delta_Constraint_Expressions;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Digits_Constraint),
              "digits constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Digits_Constraint_Expression),
              "digits constraints must retain expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Digits_Constraint_Missing_Expression_Recovery_Boundary),
              "malformed digits constraints must retain bounded missing-expression recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Constraint),
              "delta constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Constraint_Expression),
              "delta constraints must retain expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Constraint_Missing_Expression_Recovery_Boundary),
              "malformed delta constraints must retain bounded missing-expression recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "digits/delta constraint recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions;





   procedure Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Attribute_Argument_Delimiters is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   First_Index : Integer := Vector'First (1, 2);" & ASCII.LF &
        "   Size_Text : String := Integer'Image (10);" & ASCII.LF &
        "   Sum : Integer := Vector'(1, 2)'Reduce (""+"", 0);" & ASCII.LF &
        "   Broken : Integer := Vector'First (1;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Attribute_Argument_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_Part),
              "attribute argument parts must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_List_Open_Delimiter),
              "attribute argument parts must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_List_Close_Delimiter),
              "attribute argument parts must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_Association_Separator),
              "attribute argument parts must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_Expression),
              "attribute argument expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary),
              "malformed attribute argument parts must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "attribute-argument recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters;






   procedure Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Membership_Choice_List_Separators is" & ASCII.LF &
        "   type Flag is (A, B, C);" & ASCII.LF &
        "   Has_Value : Boolean := A in A | B;" & ASCII.LF &
        "   Not_Value : Boolean := C not in A | B;" & ASCII.LF &
        "   Broken : Boolean := A in A | ;" & ASCII.LF &
        "   After : Boolean := True;" & ASCII.LF &
        "end Membership_Choice_List_Separators;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice_List),
              "membership choice lists must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice),
              "membership choices must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice_Separator),
              "membership choice lists must retain | separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Membership_Choice_Missing_Choice_Recovery_Boundary),
              "malformed membership choice lists must retain bounded missing-choice recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "membership-choice recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators;




   procedure Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Case_Expression_Alternative_Separators is" & ASCII.LF &
        "   type Flag is (A, B, C);" & ASCII.LF &
        "   Value : Integer := (case A is when A => 1, when B | C => 2);" & ASCII.LF &
        "   Broken : Integer := (case A is when A => 1, );" & ASCII.LF &
        "   After : Integer := 3;" & ASCII.LF &
        "end Case_Expression_Alternative_Separators;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "case expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Alternative),
              "case expression alternatives must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Alternative_Separator),
              "case expression alternatives must retain comma separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression_Missing_Alternative_Recovery_Boundary),
              "malformed case expressions must retain bounded missing-alternative recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "case-expression recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators;




   procedure Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Name_Grammar_Refinements is" & ASCII.LF &
        "   type Count is range 0 .. 100;" & ASCII.LF &
        "   type Count_Access is access Count;" & ASCII.LF &
        "   use Name_Grammar_Refinements.Math.;" & ASCII.LF &
        "   A : Count := Math.Count'(1);" & ASCII.LF &
        "   B : Count := Operator_Types.""+""'(2);" & ASCII.LF &
        "   C : Character := Tokens.Symbols.'A';" & ASCII.LF &
        "   D : Count_Access := new Count'(3);" & ASCII.LF &
        "   E : access Count_Access := new access Count_Access;" & ASCII.LF &
        "   F : Count := Name_Grammar_Refinements.Math.""+"" (A, B);" & ASCII.LF &
        "   After : Count := Count'(4);" & ASCII.LF &
        "end Name_Grammar_Refinements;";
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
                (Editor.Ada_Token_Cursor.Production_Selected_Name_Prefix) >= 5,
              "selected names must retain explicit prefix markers for resolver/colouring consumers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Selected_Name_Separator) >= 5,
              "selected names must retain dot separators as explicit name grammar boundaries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Selected_Name_Chain_Component) >= 5,
              "selected-name chains must retain each selector as a chain component");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Selected_Literal_Selector) >= 2,
              "operator and character literal selectors must share a literal-selector marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector) >= 2,
              "selected operator-symbol selectors must stay distinct from string literals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Character_Selector),
              "selected character-literal selectors must remain visible as name selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name_Missing_Selector),
              "dangling selected-name dots must recover with selected-name-specific missing-selector metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Qualified_Expression_Apostrophe) >= 4,
              "qualified expressions must retain the qualification apostrophe boundary");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Allocator_Subtype_Mark) >= 1,
              "allocator subtype marks must be visible separately from allocator initializers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Allocator_Access_Subtype),
              "access-subtype allocators must be classified separately from named subtype allocators");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 6,
              "name grammar refinement parsing must recover into following declarations");
   end Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness;




   procedure Test_Language_Model_Token_Cursor_Extension_Aggregate_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Extension_Aggregate_Parts is" & ASCII.LF &
        "   type Root is tagged record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Child is new Root with record" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Default_Root : Root := (A => 1);" & ASCII.LF &
        "   X : Child := (Default_Root with B => 2);" & ASCII.LF &
        "   Y : Child := (Default_Root with null record);" & ASCII.LF &
        "   Z : Child := (Root'(A => 3) with A => 4, B => 5);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Extension_Aggregate_Parts;";
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
                (Editor.Ada_Token_Cursor.Production_Extension_Aggregate) >= 3,
              "extension aggregates must remain distinct from ordinary aggregate recovery");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Extension_Aggregate_Ancestor) >= 3,
              "extension aggregate ancestor parts must remain structurally visible");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Component_Association) >= 5,
              "extension aggregate component associations must remain structural after with");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "qualified-expression ancestors must continue to parse before extension aggregate with");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 5,
              "extension aggregate parsing must recover into following object declarations");
   end Test_Language_Model_Token_Cursor_Extension_Aggregate_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aggregate_Association_Depth is" & ASCII.LF &
        "   type Point is record" & ASCII.LF &
        "      X, Y : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Child is new Root with record" & ASCII.LF &
        "      V : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   A : Point := (1, 2);" & ASCII.LF &
        "   B : Point := (X | Y => 3);" & ASCII.LF &
        "   C : Point := (others => 4);" & ASCII.LF &
        "   D : Child := (Root with null record);" & ASCII.LF &
        "   E : Child := (Root with V => 6);" & ASCII.LF &
        "   F : Vector := (1 | 3 => 10, 4 .. 6 => 20, others => <>);" & ASCII.LF &
        "   G : Vector := (<>);" & ASCII.LF &
        "   Bad : Point := (X => , Y => 5);" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Aggregate_Association_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Aggregate_Positional_Component) >= 2,
              "positional aggregate components must remain distinct from named component associations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aggregate_Named_Component_Association) >= 3,
              "named aggregate component associations must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aggregate_Component_Choice_List) >= 3,
              "aggregate choice lists must be retained before component arrows");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aggregate_Component_Arrow) >= 3,
              "aggregate component association arrows must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Aggregate_Index_Choice) >= 6,
              "aggregate associations must retain individual index/component choices before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Range_Choice),
              "aggregate associations must classify range choices before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Box_Component),
              "aggregate associations must retain box component values distinctly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Others_Choice),
              "others choices inside aggregates must be classified separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Record_Aggregate),
              "null record extension aggregates must retain their null-record marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extension_Aggregate_Component_Association),
              "extension aggregate component associations must retain their own marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Recovery_Boundary),
              "malformed aggregate associations must expose a bounded recovery boundary");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 8,
              "aggregate recovery must continue into following object declarations");
   end Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Conditional_Elsif_Branch_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Conditional_Elsif_Branches is" & ASCII.LF &
        "   A : Integer := 1;" & ASCII.LF &
        "   B : Integer := 2;" & ASCII.LF &
        "   C : Integer := 3;" & ASCII.LF &
        "   X : Integer :=" & ASCII.LF &
        "     (if A = 1 then B" & ASCII.LF &
        "      elsif B = 2 then Integer'(C)" & ASCII.LF &
        "      elsif C = 3 then (case A is when 1 => B, when others => C)" & ASCII.LF &
        "      else raise Program_Error with ""bad branch"");" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Conditional_Elsif_Branches;";
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
                (Editor.Ada_Token_Cursor.Production_Elsif_Expression_Part) >= 2,
              "elsif expression parts must remain visible");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Elsif_Expression_Condition) >= 2,
              "elsif branch conditions must be retained separately from the initial if condition");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Elsif_Expression_Then_Dependent_Expression) >= 2,
              "elsif branch dependent expressions must be retained separately from ordinary then branches");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_If_Expression_Condition) >= 1,
              "the initial if-expression condition must continue to be retained");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Case_Expression_Dependent_Expression) >= 2,
              "nested case expressions inside elsif branches must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "else-branch raise expressions with messages must continue to parse structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 5,
              "conditional-expression parsing must recover into following object declarations");
   end Test_Language_Model_Token_Cursor_Conditional_Elsif_Branch_Grammar_Completeness;


   overriding function Name (T : Token_Cursor_Expression_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Expression");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Expression_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness'Access, Name => "token-cursor grammar parses Ada quantified expression loop schemes");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Name_Target_Grammar_Completeness'Access, Name => "token-cursor grammar parses selected indexed slice and dereference statement targets");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Use_Clause_Name_List_Grammar_Completeness'Access, Name => "token-cursor grammar parses use-clause name lists structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Expression_Grammar_Completeness'Access, Name => "token-cursor grammar parses allocator membership delta reduction and short-circuit expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Return_Expression_Grammar_Completeness'Access, Name => "token-cursor grammar parses simple return expressions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Target_Name_Grammar_Completeness'Access, Name => "token-cursor grammar parses Ada 2022 target-name expressions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Box_Expression_Grammar_Completeness'Access, Name => "token-cursor grammar parses Ada box expressions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Attribute_Argument_Grammar_Completeness'Access, Name => "token-cursor grammar parses attribute references with argument parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness'Access, Name => "token-cursor grammar parses membership choices with ranges structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Conditional_Expression_Branch_Grammar_Completeness'Access, Name => "token-cursor grammar retains conditional-expression else dependent expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Expression_Refinement_Grammar_Completeness'Access, Name => "token-cursor grammar retains refined expression family markers");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness'Access, Name => "token-cursor grammar parses Ada 2022 declare expressions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aggregate_Iterator_Grammar_Completeness'Access, Name => "token-cursor grammar parses aggregate iterated component associations separately from quantified expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Delta_Aggregate_Grammar_Completeness'Access, Name => "token-cursor grammar parses delta aggregate bases and associations structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aggregate_Component_Association_Grammar_Completeness'Access, Name => "token-cursor grammar parses aggregate component associations and choice lists structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Parenthesized_Aggregate_Association_Grammar_Completeness'Access, Name => "token-cursor grammar parses first and delta aggregate component associations structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Actual_Box_Grammar_Completeness'Access, Name => "token-cursor grammar parses named generic actual selectors and box defaults structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call'Access, Name => "token-cursor grammar deepens timed and conditional entry-call select statements");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Selected_Literal_Name_Refinement'Access, Name => "token-cursor grammar refines selected literal names in qualified expressions and allocators");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Defining_Name_And_Operator_Grammar_Completeness'Access, Name => "token-cursor grammar parses defining names and quoted operator symbols");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aggregate_Delimiters'Access, Name => "token-cursor grammar records aggregate delimiters separators and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Attribute_Definition_Detail'Access, Name => "token-cursor grammar classifies attribute-definition clause detail structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Attribute_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens attribute references arguments and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Expression_Literal_Grammar_Completeness'Access, Name => "token-cursor grammar retains expression literal structure");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Compiler_Complete_Expression_Grammar'Access, Name => "token-cursor grammar retains compiler-complete expression structure");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Grammar_Completeness'Access, Name => "token-cursor grammar retains case-expression dependent expression positions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Allocator_Deep_Grammar_Completeness'Access, Name => "token-cursor grammar parses allocator subtype and initialization parts deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Allocator_Constraint_Depth'Access, Name => "token-cursor grammar deepens allocator constraint metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Address_Attribute_Clause_Grammar_Completeness'Access, Name => "token-cursor grammar classifies Address attribute clauses structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Name_Attribute_Refinement'Access, Name => "token-cursor grammar refines attribute-prefix and incomplete selected-name contexts");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Qualified_Expression_Part_Grammar_Completeness'Access, Name => "token-cursor grammar parses qualified-expression subtype marks and operands structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters'Access, Name => "token-cursor grammar records qualified-expression operand delimiters and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters'Access, Name => "token-cursor grammar records parenthesized-expression delimiters and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions'Access, Name => "token-cursor grammar records digits and delta constraint expressions and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters'Access, Name => "token-cursor grammar records attribute argument delimiters separators and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators'Access, Name => "token-cursor grammar records membership-choice separators and missing-choice recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators'Access, Name => "token-cursor grammar records case-expression alternative separators and missing-alternative recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness'Access, Name => "token-cursor grammar parses selected literal names qualified expressions and allocators structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Extension_Aggregate_Grammar_Completeness'Access, Name => "token-cursor grammar parses extension aggregate ancestor and component parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar retains aggregate choices ranges boxes extension components and recovery structure");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Conditional_Elsif_Branch_Grammar_Completeness'Access, Name => "token-cursor grammar parses conditional-expression elsif branches structurally");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Expression_Tests;
