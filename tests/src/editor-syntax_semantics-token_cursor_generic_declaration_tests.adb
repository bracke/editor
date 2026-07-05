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

package body Editor.Syntax_Semantics.Token_Cursor_Generic_Declaration_Tests is





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Discrete is (<>);" & ASCII.LF &
        "   type Priv is private;" & ASCII.LF &
        "   type Derived is new Parent with private;" & ASCII.LF &
        "   type Int is range <>;" & ASCII.LF &
        "   type Mod_Type is mod <>;" & ASCII.LF &
        "   type Float_Type is digits <>;" & ASCII.LF &
        "   type Ord_Fixed is delta <>;" & ASCII.LF &
        "   type Dec_Fixed is delta <> digits <>;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Element;" & ASCII.LF &
        "   type Ref is access all Element;" & ASCII.LF &
        "   type Iface is interface;" & ASCII.LF &
        "   Item : in Element;" & ASCII.LF &
        "   Defaulted, Second : in out Element := <>;" & ASCII.LF &
        "   Named : Element := Make_Element (1);" & ASCII.LF &
        "   with procedure Visit (X : in Element);" & ASCII.LF &
        "   with function Image (X : Element) return String is <>;" & ASCII.LF &
        "   with package Nested is new Generic_Nested (Element => Element);" & ASCII.LF &
        "package G is" & ASCII.LF &
        "end G;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Declaration),
              "token-cursor grammar must parse formal object declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Defining_Name_List),
              "formal object declarations must retain their defining name list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Mode),
              "formal object declarations must retain their mode grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Subtype_Indication),
              "formal object declarations must retain their subtype indication position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Default),
              "formal object declarations must retain default expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Box_Expression),
              "formal object defaults must retain Ada box expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "token-cursor grammar must parse formal type declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Private_Type_Definition),
              "token-cursor grammar must parse formal private type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Derived_Type_Definition),
              "token-cursor grammar must parse formal derived type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Discrete_Type_Definition),
              "token-cursor grammar must parse formal discrete type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Signed_Integer_Type_Definition),
              "token-cursor grammar must parse formal signed integer type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Modular_Type_Definition),
              "token-cursor grammar must parse formal modular type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Floating_Point_Definition),
              "token-cursor grammar must parse formal floating point type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Ordinary_Fixed_Point_Definition),
              "token-cursor grammar must parse formal ordinary fixed point definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Decimal_Fixed_Point_Definition),
              "token-cursor grammar must parse formal decimal fixed point definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Array_Type_Definition),
              "token-cursor grammar must parse formal array type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Access_Type_Definition),
              "token-cursor grammar must parse formal access type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Interface_Type_Definition),
              "token-cursor grammar must parse formal interface type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Declaration),
              "token-cursor grammar must parse formal subprogram declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "token-cursor grammar must parse formal package declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Part),
              "formal packages must retain their generic actual part");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Object_Default_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   Left, Right : in out Element := <>;" & ASCII.LF &
        "   Seed : Element := Make_Element (1);" & ASCII.LF &
        "package Formal_Defaults is" & ASCII.LF &
        "end Formal_Defaults;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Declaration),
              "generic formal objects must remain explicit formal object declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Mode),
              "generic formal objects must retain in/out mode grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Default),
              "generic formal objects must retain default expression grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Box_Expression),
              "generic formal object defaults must retain box expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Association_List),
              "generic formal object default calls must retain association-list grammar");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Object_Default_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Object_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   Limit, Default_Limit : in out Counts.Natural_Count := Counts.Default;" & ASCII.LF &
        "   Factory : not null access function (Seed : Natural) return Element := Defaults.Make'Access;" & ASCII.LF &
        "package Formal_Object_Internals is" & ASCII.LF &
        "   Value : Element;" & ASCII.LF &
        "end Formal_Object_Internals;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Declaration),
              "generic formal object declarations must remain explicit grammar nodes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Defining_Name_List),
              "generic formal object declarations must retain the defining name-list position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Subtype_Indication),
              "generic formal object declarations must retain the subtype-indication position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Default),
              "generic formal object declarations must retain default-expression positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Subprogram_Parameter_Profile),
              "formal object subtype indications must continue into access-to-subprogram profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover from formal object declarations into the package declaration");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Object_Internal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Formal_Subprogram_Default_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with procedure Visit (Item : Element) is <>;" & ASCII.LF &
        "   with procedure No_Op is null;" & ASCII.LF &
        "   with function Make return Element is Defaults.Make;" & ASCII.LF &
        "   with function Image (Item : Element) return String is abstract;" & ASCII.LF &
        "package Formal_Subprogram_Defaults is" & ASCII.LF &
        "end Formal_Subprogram_Defaults;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Declaration),
              "generic formal subprograms must remain explicit formal declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Defining_Designator),
              "generic formal subprograms must retain their defining designators explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Parameter_Profile),
              "generic formal subprograms must retain parameter-profile positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Result_Subtype),
              "generic formal functions must retain result subtype positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Default),
              "formal subprogram defaults must retain the common is-default marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Box),
              "formal subprogram defaults must retain box defaults");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Null),
              "formal subprogram defaults must retain null defaults");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Name),
              "formal subprogram defaults must retain default-name expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Abstract),
              "formal subprogram defaults must retain abstract defaults");
   end Test_Language_Model_Token_Cursor_Formal_Subprogram_Default_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Generic_Instantiation_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Instantiation_Internals is" & ASCII.LF &
        "   package Child.Instance is new Ada.Containers.Vectors" & ASCII.LF &
        "     (Index_Type => Positive," & ASCII.LF &
        "      Element_Type => Model.Item);" & ASCII.LF &
        "   procedure Sort_Items is new Generic_Sort" & ASCII.LF &
        "     (Element_Type => Model.Item," & ASCII.LF &
        "      Before => Model.""<"");" & ASCII.LF &
        "   function Image_Of is new Generic_Image (Item_Type => Model.Item)" & ASCII.LF &
        "     with Inline;" & ASCII.LF &
        "   subtype After_Instantiation is Natural;" & ASCII.LF &
        "end Instantiation_Internals;";
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
                (Editor.Ada_Token_Cursor.Production_Generic_Instantiation) = 3,
              "package procedure and function instantiations must remain explicit");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Instance_Name) = 3,
              "generic instantiations must retain their instance defining names");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Instantiated_Unit_Name) = 3,
              "generic instantiations must retain instantiated generic unit names");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Instantiation_Actual_Part) = 3,
              "generic instantiations must retain instantiation-specific actual-part positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Part) = 3,
              "generic instantiation actual parts must still use generic actual grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Formal_Selector),
              "generic instantiation named actuals must retain formal selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "instantiated actual expressions must retain selected operator selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "parser must recover into declarations after generic instantiations");
   end Test_Language_Model_Token_Cursor_Generic_Instantiation_Internal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Generic_Instantiation_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Instantiation_Depth is" & ASCII.LF &
        "   package Maps is new Ada.Containers.Ordered_Maps" & ASCII.LF &
        "     (Key_Type => Key.Id," & ASCII.LF &
        "      Element_Type => Elements.Item," & ASCII.LF &
        "      ""<"" => Key.""<""," & ASCII.LF &
        "      Factory => Builders.Make (Seed => Initial, others => <>)," & ASCII.LF &
        "      Capacity);" & ASCII.LF &
        "   procedure Sort_Items is new Generic_Sort" & ASCII.LF &
        "     (Model.Item, Before => Comparers.Less (Left => A, Right => B));" & ASCII.LF &
        "   function Image_Of is new Generic_Image (Item_Type => Model.Item, Make => <>);" & ASCII.LF &
        "   package Broken is new Templates (Item => Model.Item," & ASCII.LF &
        "   subtype After_Instantiation is Natural;" & ASCII.LF &
        "end Generic_Instantiation_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Generic_Package_Instantiation) >= 2,
              "package instantiations must retain package-specific instantiation markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Procedure_Instantiation),
              "procedure instantiations must retain procedure-specific instantiation markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Function_Instantiation),
              "function instantiations must retain function-specific instantiation markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Positional_Association),
              "positional generic actuals must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Formal_Selector),
              "named generic actual selectors must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Association_Box),
              "named generic actual boxes must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Nested_Actual_Part),
              "nested generic actual parts must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Nested_Actual_Association),
              "nested named actual associations must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Recovery_Boundary),
              "malformed generic actual lists must expose recovery boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "parser must recover into following declarations after malformed instantiations");
   end Test_Language_Model_Token_Cursor_Generic_Instantiation_Depth_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Type_Deep_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Enum is (<>);" & ASCII.LF &
        "   type Signed is range <>;" & ASCII.LF &
        "   type Modular is mod <>;" & ASCII.LF &
        "   type Float_Form is digits <> range -1.0 .. 1.0;" & ASCII.LF &
        "   type Ordinary_Fixed is delta <> range -1.0 .. 1.0;" & ASCII.LF &
        "   type Decimal_Fixed is delta <> digits <>;" & ASCII.LF &
        "   type Private_Form is abstract tagged limited private;" & ASCII.LF &
        "   type Interface_Form is synchronized interface and Root_Interface;" & ASCII.LF &
        "   type Derived_Form is abstract new Parent and Printable with private;" & ASCII.LF &
        "   type Matrix is array (Positive range <>, Natural range <>) of Element;" & ASCII.LF &
        "   type Callback is access protected procedure (X : in Element);" & ASCII.LF &
        "   type Factory is not null access function (X : Element) return Result;" & ASCII.LF &
        "package Deep_Generic_Formals is" & ASCII.LF &
        "end Deep_Generic_Formals;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Box),
              "formal discrete types must retain the <> box structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Range_Box),
              "formal signed and modular scalar boxes must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Digits_Box),
              "formal floating and decimal digits boxes must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Delta_Box),
              "formal fixed point delta boxes must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Derived_Subtype_Mark),
              "formal derived types must retain their parent subtype mark");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Interface_List),
              "formal derived and interface types must retain interface lists");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Interface_Modifier),
              "formal interface types must retain limited/task/protected/synchronized modifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Array_Index_Subtype_Definition),
              "formal array type definitions must retain index subtype definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Array_Component_Definition),
              "formal array type definitions must retain component definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Access_Type_Definition),
              "formal access types must retain access type definition nodes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_To_Subprogram_Definition),
              "formal access-to-subprogram types must retain callable profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Parameter_Profile),
              "formal access-to-subprogram types must retain their parameter profiles as formal contract structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Protected_Part),
              "formal access protected subprogram types must retain the protected marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Access_Result_Subtype),
              "formal access function types must retain the result subtype marker");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Type_Deep_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Type_Modifier_And_Parent_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Private_Form is abstract tagged limited private;" & ASCII.LF &
        "   type Derived_Form is abstract new Parents.Root and Printable and Serializable with private;" & ASCII.LF &
        "   type Interface_Form is limited interface and Root_Interface and IO.Streams.Root_Stream_Type'Class;" & ASCII.LF &
        "   type Table is array (Positive range <>) of aliased Element;" & ASCII.LF &
        "package Deep_Formal_Modifiers is" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Deep_Formal_Modifiers;";
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
                (Editor.Ada_Token_Cursor.Production_Formal_Type_Modifier) >= 5,
              "formal private derived and interface type modifiers must be retained as formal-type modifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Private_Extension_Definition),
              "formal derived type definitions must retain the explicit with-private extension marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Interface_Subtype) >= 4,
              "formal derived and interface type definitions must retain each interface parent subtype");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "formal array component definitions must retain aliased component markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Reference),
              "formal interface parent subtype marks must retain attribute suffixes such as 'Class");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into the generic unit after deep formal type definitions");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Type_Modifier_And_Parent_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Type_Declaration_Head_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element (<>) is private with Preelaborable_Initialization;" & ASCII.LF &
        "   type Refined (Length : Natural := 0) is new Parent.Root with private;" & ASCII.LF &
        "   type Matrix is array (Positive range <>) of Element;" & ASCII.LF &
        "package Formal_Type_Heads is" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Formal_Type_Heads;";
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
                (Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration) = 3,
              "all generic formal type declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Type_Defining_Name) = 3,
              "formal type declarations must retain their defining names explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Type_Discriminant_Part) = 2,
              "known and unknown formal type discriminant parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Unknown_Discriminant_Part),
              "unknown discriminant formal types must still retain the unknown discriminant part");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification),
              "known discriminant formal types must still parse discriminant specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attached_Aspect_Specification),
              "formal type declaration heads must still allow attached aspects");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into package declarations after formal type heads");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Type_Declaration_Head_Grammar_Completeness;








   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Count is range ;" & ASCII.LF &
        "   type Mask is mod with Atomic;" & ASCII.LF &
        "   type Real is digits ;" & ASCII.LF &
        "   type Rate is delta with Volatile;" & ASCII.LF &
        "   type Root is abstract new Parents.Root and Printable and Serializable with private" & ASCII.LF &
        "      with Preelaborable_Initialization;" & ASCII.LF &
        "   type View is synchronized interface and Root_Interface and IO.Streams.Root_Stream_Type'Class;" & ASCII.LF &
        "package Formal_Type_Edges is" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Formal_Type_Edges;";
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
                (Editor.Ada_Token_Cursor.Production_Formal_Scalar_Box_Recovery_Boundary) >= 4,
              "malformed formal scalar ranges/mod/digits/delta definitions must expose bounded scalar recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Derived_Interface_List),
              "formal derived types must retain an explicit derived-interface-list marker before shared interface parsing");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Interface_Ancestor_List) >= 2,
              "formal derived and interface definitions must retain family-specific ancestor-list metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Interface_Subtype) >= 4,
              "formal interface ancestors must remain individually visible to model projection");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Aspect_Specification),
              "formal type edge parsing must leave trailing aspects attached to the formal declaration");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into the generic unit after hostile formal type edge cases");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth;





   procedure Test_Language_Model_Token_Cursor_Formal_Package_Actual_Part_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Defaults is new Generic_Defaults (<>);" & ASCII.LF &
        "   with package Maps is new Ada.Containers.Ordered_Maps" & ASCII.LF &
        "     (Key_Type => Key," & ASCII.LF &
        "      Element_Type => Element," & ASCII.LF &
        "      ""<"" => Less," & ASCII.LF &
        "      others => <>);" & ASCII.LF &
        "   with package Plain is new Generic_Plain;" & ASCII.LF &
        "package Formal_Packages is" & ASCII.LF &
        "end Formal_Packages;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "generic formal packages must remain explicit formal package declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Generic_Name),
              "formal package declarations must retain the generic package name structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Defining_Name),
              "formal package declarations must retain their defining name separately from the generic package name");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part) = 2,
              "formal package declarations must retain only explicit actual parts");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Association) >= 4,
              "formal package actual parts must retain each association in a formal-package-specific production");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Formal_Selector) >= 4,
              "formal package actual associations must retain named selectors including reserved-word and operator selectors");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Box) = 1,
              "formal package box actual parts must remain distinct from generic associations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Association_Box) = 1,
              "formal package actual associations must retain association-level => <> boxes distinctly from whole-part (<>) boxes");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Part) = 1,
              "only non-box formal package actual parts should enter generic actual grammar");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Association) >= 3,
              "named and others formal package actual associations must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Formal_Selector),
              "formal package generic actual parts must retain named selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Box),
              "formal package actual associations must retain => <> box defaults");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "formal package generic package names must retain selected-name grammar");
   end Test_Language_Model_Token_Cursor_Formal_Package_Actual_Part_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Formal_Package_Positional_Actuals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Pair is new Generic_Pair" & ASCII.LF &
        "     (Key," & ASCII.LF &
        "      Element," & ASCII.LF &
        "      ""<"" => Less," & ASCII.LF &
        "      others => <>);" & ASCII.LF &
        "package Formal_Package_Positional is" & ASCII.LF &
        "end Formal_Package_Positional;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "formal packages with positional actuals must retain formal package declaration grammar");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Positional_Association) = 2,
              "formal package positional actuals must be tagged distinctly from named actual associations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Positional_Association) >= 2,
              "formal package positional actuals must also remain compatible with generic actual grammar");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Formal_Selector) >= 2,
              "named formal package actual associations following positional actuals must retain selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Association_Box),
              "association-level boxes after positional actuals must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Defining_Operator_Symbol),
              "operator selectors after positional formal package actuals must remain operator-symbol metadata");
   end Test_Language_Model_Token_Cursor_Formal_Package_Positional_Actuals;





   procedure Test_Language_Model_Token_Cursor_Formal_Package_Defaulted_Actuals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Defaulted is new Generic_Defaulted;" & ASCII.LF &
        "   with package Aspect_Defaulted is new Generic_Aspect_Defaulted" & ASCII.LF &
        "     with Preelaborate, Pure;" & ASCII.LF &
        "   with package Boxed is new Generic_Boxed (<>);" & ASCII.LF &
        "package Formal_Package_Defaults is" & ASCII.LF &
        "end Formal_Package_Defaults;";
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
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration) >= 3,
              "formal package declarations with omitted actual parts must be retained");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Defaulted_Actual_Part) = 2,
              "omitted formal package actual parts must be tagged distinctly from box actual parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Box),
              "explicit (<>) formal package actual parts must keep the existing box marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Aspect_Specification),
              "aspect specifications after defaulted formal package declarations must still parse structurally");
   end Test_Language_Model_Token_Cursor_Formal_Package_Defaulted_Actuals;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Forward;" & ASCII.LF &
        "   type Tagged_Forward is tagged;" & ASCII.LF &
        "   type Discriminated (<>);" & ASCII.LF &
        "   type Missing is;" & ASCII.LF &
        "   type Real_Private is tagged private;" & ASCII.LF &
        "package Generic_Formal_Incomplete is" & ASCII.LF &
        "end Generic_Formal_Incomplete;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Incomplete_Type_Declaration),
              "formal incomplete type declarations must be parsed as a distinct formal type family");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Incomplete_Tagged_Type_Definition),
              "tagged formal incomplete types must retain the is-tagged suffix structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Discriminant_Part),
              "formal incomplete types with discriminant parts must preserve discriminant metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Incomplete_Type_Recovery_Boundary),
              "malformed formal type declarations missing a definition after is must retain a formal-type recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Private_Type_Definition),
              "tagged private formal types must continue to parse as private formal definitions, not incomplete types");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Declaration_Terminator),
              "formal incomplete recovery must preserve generic formal terminators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration),
              "formal incomplete type recovery must continue into the following package declaration");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type;





   procedure Test_Language_Model_Token_Cursor_Formal_Package_Actual_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Boxed is new Generic_Package (<>);" & ASCII.LF &
        "   with package Named is new Generic_Package" & ASCII.LF &
        "     (Element_Type => Integer," & ASCII.LF &
        "      Index_Type => Positive);" & ASCII.LF &
        "   with package Broken is new Generic_Package" & ASCII.LF &
        "     (Element_Type => Integer;" & ASCII.LF &
        "package Formal_Package_Actual_Delimiter_Depth is" & ASCII.LF &
        "end Formal_Package_Actual_Delimiter_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "formal package declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part),
              "formal package actual parts must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part_Open_Delimiter),
              "formal package actual parts must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part_Close_Delimiter),
              "formal package actual parts must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Association_Separator),
              "formal package actual lists must retain association separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary),
              "formal package actual parts missing close delimiters must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_Formal_Package_Actual_Delimiters;






   procedure Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Instantiation_Actual_Delimiters is" & ASCII.LF &
        "   package Ints is new Generic_Package " &
        "(Element_Type => Integer, Capacity => 10);" & ASCII.LF &
        "   procedure Convert is new Generic_Procedure (Integer, Float);" & ASCII.LF &
        "   package Defaults is new Generic_Defaults (<>);" & ASCII.LF &
        "   package Broken is new Generic_Package " &
        "(Element_Type => Integer, Capacity => 10;" & ASCII.LF &
        "   subtype After_Instantiation is Natural;" & ASCII.LF &
        "end Generic_Instantiation_Actual_Delimiters;";
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
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Part_Open_Delimiter) >= 4,
              "generic instantiation actual parts must retain opening delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Part_Close_Delimiter) >= 3,
              "well-formed generic instantiation actual parts must retain closing delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Generic_Actual_Association_Separator) >= 3,
              "generic instantiation actual parts must retain comma separators between actuals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary),
              "in-progress generic instantiation actual parts must record bounded missing-close recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "generic actual missing-close recovery must not consume the following declaration");
   end Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters;


   overriding function Name (T : Token_Cursor_Generic_Declaration_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Generic_Declaration");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Generic_Declaration_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Grammar_Completeness'Access, Name => "token-cursor grammar parses every generic formal declaration family");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Object_Default_Grammar_Completeness'Access, Name => "token-cursor grammar parses generic formal object modes and defaults structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Object_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar parses generic formal object internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Subprogram_Default_Grammar_Completeness'Access, Name => "token-cursor grammar parses formal subprogram defaults structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Instantiation_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar parses generic instantiation internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Instantiation_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses generic instantiation actuals and recovery deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Type_Deep_Grammar_Completeness'Access, Name => "token-cursor grammar parses generic formal type definitions deeply and structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Type_Modifier_And_Parent_Grammar_Completeness'Access, Name => "token-cursor grammar retains formal type modifiers parents private extensions and aliased components structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Type_Declaration_Head_Grammar_Completeness'Access, Name => "token-cursor grammar retains generic formal type declaration heads structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth'Access, Name => "token-cursor grammar deepens generic formal type edge recovery and interface metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Actual_Part_Grammar_Completeness'Access, Name => "token-cursor grammar parses formal package actual parts and box defaults structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Positional_Actuals'Access, Name => "token-cursor grammar tags formal package positional actual associations distinctly");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Defaulted_Actuals'Access, Name => "token-cursor grammar tags defaulted formal package actual parts");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type'Access, Name => "token-cursor grammar parses generic formal incomplete type declarations");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Actual_Delimiters'Access, Name => "token-cursor grammar deepens formal package actual delimiters");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters'Access, Name => "token-cursor grammar deepens generic instantiation actual delimiters and missing-close recovery");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Generic_Declaration_Tests;
