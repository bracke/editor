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

package body Editor.Syntax_Semantics.Token_Cursor_Missing_Recovery_Tests is





   procedure Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Case_Choice_Recovery (Kind : Integer) is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Kind is" & ASCII.LF &
        "      when 1 | => null;" & ASCII.LF &
        "      when others => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   After_Call;" & ASCII.LF &
        "end Case_Choice_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement),
              "case statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Choice_Separator),
              "case choice-list separators must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Choice_Missing_Choice_Recovery_Boundary),
              "case choices missing after a separator must retain case-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Choice_Arrow),
              "case choice recovery must leave the choice arrow visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "case choice recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery;





   procedure Test_Language_Model_Token_Cursor_Label_Missing_Close_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Label_Missing_Close_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   <<Broken" & ASCII.LF &
        "   null;" & ASCII.LF &
        "   <<Finished>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Label_Missing_Close_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label),
              "labels must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Open_Delimiter),
              "label open delimiters must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Missing_Close_Recovery_Boundary),
              "labels missing a close delimiter must retain label-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Close_Delimiter),
              "well-formed labels must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "label recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Label_Missing_Close_Recovery;





   procedure Test_Language_Model_Token_Cursor_Select_Guard_Missing_Arrow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Select_Guard_Recovery is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         when Ready accept Start;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         terminate;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      After : Integer;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Select_Guard_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard),
              "malformed select guards must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard_Condition),
              "select guard condition metadata must survive missing-arrow recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Guard_Missing_Arrow_Recovery_Boundary),
              "select guards missing => must retain guard-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Alternative_Recovery_Boundary),
              "select guard recovery must preserve the shared select-alternative recovery marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "select guard recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Select_Guard_Missing_Arrow;




   procedure Test_Language_Model_Token_Cursor_Case_Alternative_Missing_Arrow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Case_Alternative_Missing_Arrow is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Mode is" & ASCII.LF &
        "      when Ready" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      when others =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "end Case_Alternative_Missing_Arrow;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative),
              "case alternatives must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Choice_List),
              "case alternatives missing arrows must still retain their choice-list metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative_Missing_Arrow_Recovery_Boundary),
              "case alternatives missing => must retain case-specific missing-arrow recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative_Recovery_Boundary),
              "case alternatives missing => must still retain shared case-alternative recovery metadata");
   end Test_Language_Model_Token_Cursor_Case_Alternative_Missing_Arrow;




   procedure Test_Language_Model_Token_Cursor_If_Missing_Then_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body If_Missing_Then_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   elsif Enabled" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   else" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end If_Missing_Then_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement),
              "if statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Condition),
              "if statements missing then must still retain condition metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Missing_Then_Recovery_Boundary),
              "if statements missing then must retain if-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Elsif_Statement_Branch),
              "elsif branches must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Elsif_Statement_Missing_Then_Recovery_Boundary),
              "elsif branches missing then must retain elsif-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Recovery_Boundary),
              "missing-then branches must still retain shared if recovery metadata");
   end Test_Language_Model_Token_Cursor_If_Missing_Then_Recovery;





   procedure Test_Language_Model_Token_Cursor_Loop_Missing_Loop_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Loop_Missing_Loop_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   for I in 1 .. 3" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   for Item of Items when Is_Ready (Item)" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   while Ready" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Loop_Missing_Loop_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Scheme),
              "for loops missing loop must still retain iteration-scheme metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Missing_Loop_Recovery_Boundary),
              "for loops missing loop must retain for-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Iteration_Scheme),
              "iterator loops missing loop must still retain iteration-scheme metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Missing_Loop_Recovery_Boundary),
              "iterator loops missing loop must retain iterator-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Condition),
              "while loops missing loop must still retain condition metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Missing_Loop_Recovery_Boundary),
              "while loops missing loop must retain while-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "missing loop keyword recovery must still retain shared recovery-point metadata");
   end Test_Language_Model_Token_Cursor_Loop_Missing_Loop_Recovery;







   procedure Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Entry_Body_Missing_Barrier_Recovery is" & ASCII.LF &
        "   entry Missing_Barrier is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Missing_Barrier;" & ASCII.LF &
        "   entry Good when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Good;" & ASCII.LF &
        "end Entry_Body_Missing_Barrier_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body),
              "entry bodies must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Entry_Body_Missing_Barrier_Recovery_Boundary),
              "entry bodies missing a when barrier before is must expose entry-specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary),
              "protected entry bodies missing a barrier must expose protected-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Entry_Barrier_Condition),
              "barrier recovery must preserve valid following protected entry barriers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Begin_Keyword),
              "entry-body recovery must continue into following begin metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "entry-body barrier recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery;





   procedure Test_Language_Model_Token_Cursor_Access_Object_Missing_Subtype_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Object_Missing_Subtype_Recovery is" & ASCII.LF &
        "   Missing_Aspect_Boundary : access with Volatile;" & ASCII.LF &
        "   type Missing_Private_Boundary is access private;" & ASCII.LF &
        "   Missing_Close_Boundary : access);" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Access_Object_Missing_Subtype_Recovery;";
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
                (Editor.Ada_Token_Cursor.Production_Access_Object_Missing_Subtype_Recovery_Boundary) >= 3,
              "access-to-object definitions at reserved/declaration boundaries must expose missing-subtype recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Recovery_Boundary),
              "access-to-object missing subtype recovery should keep generic access recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "access-to-object missing subtype recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Access_Object_Missing_Subtype_Recovery;






   procedure Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Arrow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Exception_Handler_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Constraint_Error | Program_Error" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   when others =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Exception_Handler_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler),
              "exception handlers must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Separator),
              "exception handler choice lists must retain separator metadata before recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Missing_Arrow_Recovery_Boundary),
              "exception handlers missing => must retain handler-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Recovery_Boundary),
              "exception handler recovery must continue to emit the shared bounded recovery marker");
   end Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Arrow;






   procedure Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Exception_Handler_Missing_Choice is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Constraint_Error | =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   when others =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Exception_Handler_Missing_Choice;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler),
              "exception handlers must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Separator),
              "exception handler choice lists must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Missing_Choice_Recovery_Boundary),
              "exception handlers with a trailing choice separator must retain choice-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Recovery_Boundary),
              "exception handler choice recovery must continue to emit the shared bounded recovery marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Arrow),
              "choice-list recovery must leave the following arrow available for handler parsing");
   end Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice;






   procedure Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Quantified_Missing_Quantifier is" & ASCII.LF &
        "   Good   : Boolean := (for all I in 1 .. 10 => I > 0);" & ASCII.LF &
        "   Broken : Boolean := (for I in 1 .. 10 => I > 0);" & ASCII.LF &
        "   After  : Integer := 1;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Quantified_Missing_Quantifier;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Expression),
              "quantified expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantifier),
              "well-formed quantified expressions must retain quantifier metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Missing_Quantifier_Recovery_Boundary),
              "malformed quantified expressions must retain bounded missing-quantifier recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Domain),
              "recovered quantified expressions must still expose the domain");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Arrow),
              "recovered quantified expressions must still expose the predicate arrow");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "quantified-expression recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier;





   procedure Test_Language_Model_Token_Cursor_Selected_Name_Missing_Selector_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Selected_Name_Recovery is" & ASCII.LF &
        "   Good   : Integer := Root.Child.Value;" & ASCII.LF &
        "   Broken : Integer := Root.Child.;" & ASCII.LF &
        "   After  : Integer := 1;" & ASCII.LF &
        "end Selected_Name_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "selected names must retain selected-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name_Missing_Selector),
              "dangling selected-name dots must retain missing-selector metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name_Missing_Selector_Recovery_Boundary),
              "dangling selected-name dots must retain bounded missing-selector recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "selected-name missing-selector recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Selected_Name_Missing_Selector_Recovery;


   overriding function Name (T : Token_Cursor_Missing_Recovery_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Missing_Recovery");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Missing_Recovery_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery'Access, Name => "token-cursor grammar recovers case choices missing after separators");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Label_Missing_Close_Recovery'Access, Name => "token-cursor grammar records label missing-close recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Select_Guard_Missing_Arrow'Access, Name => "token-cursor grammar recovers select guards missing arrows");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Alternative_Missing_Arrow'Access, Name => "token-cursor grammar deepens case alternative missing-arrow recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_If_Missing_Then_Recovery'Access, Name => "token-cursor grammar deepens if and elsif missing-then recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Loop_Missing_Loop_Recovery'Access, Name => "token-cursor grammar deepens loop-scheme missing-loop recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery'Access, Name => "token-cursor grammar recovers protected entry bodies missing barriers");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Access_Object_Missing_Subtype_Recovery'Access, Name => "token-cursor grammar recovers access-object definitions missing designated subtypes at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Arrow'Access, Name => "token-cursor grammar recovers exception handlers missing arrows");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice'Access, Name => "token-cursor grammar recovers exception handler choice lists with missing choices");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier'Access, Name => "token-cursor grammar records quantified-expression missing-quantifier recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Selected_Name_Missing_Selector_Recovery'Access, Name => "token-cursor grammar records selected-name missing-selector recovery metadata");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Missing_Recovery_Tests;
