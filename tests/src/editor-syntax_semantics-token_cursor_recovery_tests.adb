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

package body Editor.Syntax_Semantics.Token_Cursor_Recovery_Tests is





   procedure Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Use_Clause_Recovery is" & ASCII.LF &
        "   use ;" & ASCII.LF &
        "   use type ;" & ASCII.LF &
        "   use Ada.Text_IO, ;" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "end Use_Clause_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Package_Name_List),
              "malformed ordinary use clauses must still retain a package-name-list production");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark_List),
              "malformed use type clauses must still retain a subtype-mark-list production");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Clause_Separator),
              "trailing comma recovery must retain the use-clause separator");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "malformed use clauses must report recovery points");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "use-clause recovery must continue into the following declaration");
   end Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Use_Clause_Specific_Recovery is" & ASCII.LF &
        "   use ;" & ASCII.LF &
        "   use type Interfaces.Unsigned_32, ;" & ASCII.LF &
        "   use all type ;" & ASCII.LF &
        "   use Ada.Text_IO" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "end Use_Clause_Specific_Recovery;";
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
                (Editor.Ada_Token_Cursor.Production_Use_Clause_Missing_Name_Recovery_Boundary) >= 2,
              "empty ordinary and use all type clauses must expose use-specific missing-name recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Clause_Trailing_Separator_Recovery_Boundary),
              "use-clause trailing comma recovery must be distinguishable from generic recovery points");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Clause_Missing_Terminator_Recovery_Boundary),
              "use clauses without a semicolon must expose use-specific missing-terminator recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "use-clause specific recovery must preserve generic recovery metadata for existing consumers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "use-clause specific recovery must continue into the following declaration");
   end Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery;




   procedure Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Use_Clause_Recovery_Depth is" & ASCII.LF &
        "   use all Ada.Text_IO;" & ASCII.LF &
        "   use type private" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "end Use_Clause_Recovery_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Use_All_Missing_Type_Recovery_Boundary),
              "malformed use all clauses must expose a missing-type recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Use_Clause_Reserved_Name_Recovery_Boundary),
              "use-clause name lists must recover at declaration/private reserved boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Use_Type_Subtype_Mark_List),
              "recovered use all/use type clauses must retain subtype-mark list metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "use-clause recovery depth must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "use-clause recovery must continue into the following declaration");
   end Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth;




   procedure Test_Language_Model_Token_Cursor_Representation_Item_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Representation_Item_Recovery_Depth is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, private" & ASCII.LF &
        "   type Next_Colour is (Cyan, Magenta);" & ASCII.LF &
        "   Obj : Integer;" & ASCII.LF &
        "   for Obj use at private" & ASCII.LF &
        "   After_Address : Integer;" & ASCII.LF &
        "   for Obj' use 32;" & ASCII.LF &
        "   for Obj private" & ASCII.LF &
        "   After_Target : Integer;" & ASCII.LF &
        "end Representation_Item_Recovery_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Reserved_Association_Recovery_Boundary),
              "enumeration representation clauses must stop associations at declaration/private boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Address_Clause_Missing_Value_Recovery_Boundary),
              "address clauses must treat reserved declaration boundaries as missing address values");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Attribute_Definition_Missing_Designator_Recovery_Boundary),
              "attribute-definition clauses must expose missing-designator recovery after an apostrophe");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Representation_Target_Reserved_Boundary_Recovery_Boundary),
              "representation targets must stop before reserved declaration boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Representation_Clause_Missing_Use_Recovery_Boundary),
              "ordinary representation clauses must expose a specific missing-use boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "representation item recovery must continue into following declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "specific representation recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Representation_Item_Recovery_Depth;




   procedure Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Enum_Rep_Recovery is" & ASCII.LF &
        "   type Empty_Kind is (A, B);" & ASCII.LF &
        "   for Empty_Kind use ();" & ASCII.LF &
        "   type Trailing_Kind is (C, D);" & ASCII.LF &
        "   for Trailing_Kind use (C => 0,);" & ASCII.LF &
        "   type Missing_Value_Kind is (E, F);" & ASCII.LF &
        "   for Missing_Value_Kind use (E =>, F => 1);" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "end Enum_Rep_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Empty_List_Recovery_Boundary),
              "empty enumeration representation lists must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary),
              "trailing comma enumeration representation lists must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Enumeration_Representation_Missing_Value_Recovery_Boundary),
              "missing enumeration representation values must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Enumeration_Representation_List_Close_Delimiter),
              "enumeration representation recovery must preserve close-delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "enumeration representation recovery must continue into following declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "specific enumeration representation recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery;




   procedure Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Case_878
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer is" & ASCII.LF &
        "   Visible_Value : Integer :=" & ASCII.LF &
        "private" & ASCII.LF &
        "   Private_Value : Integer :=" & ASCII.LF &
        "end Outer;" & ASCII.LF &
        "package body Outer is" & ASCII.LF &
        "   Body_Value : Integer :=" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Outer;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Nested_Declarative_Item_Recovery_Boundary),
              "package declarative recovery must mark nested item boundaries specifically");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Declarative_Private_Boundary),
              "malformed visible nested package declarations must preserve private-boundary metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Declarative_Begin_Boundary),
              "malformed package-body declarative items must preserve begin-boundary metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Declarative_End_Boundary),
              "malformed package declarative items must preserve end-boundary metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Visible_Declarative_Item),
              "package declaration recovery must preserve visible declarative item metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Body_Declarative_Item),
              "package body recovery must preserve body declarative item metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Declarative_Recovery_Boundary),
              "specific package declarative recovery must preserve generic package recovery metadata");
   end Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Case_878;




   procedure Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Empty is new Generic_Template ();" & ASCII.LF &
        "   with package Next is new Generic_Template (<>);" & ASCII.LF &
        "package Formal_Package_Empty_Actual_Recovery is" & ASCII.LF &
        "end Formal_Package_Empty_Actual_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "formal package declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part),
              "formal package actual parts must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Empty_Recovery_Boundary),
              "empty formal package actual parts must retain a dedicated recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Part_Close_Delimiter),
              "empty formal package actual recovery must leave the close delimiter visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Box),
              "empty formal package actual recovery must resume at following formal packages");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "empty formal package actual recovery must expose conservative syntax recovery metadata");
   end Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with function Make return Element is abstract Defaults.Make;" & ASCII.LF &
        "   with procedure Broken is;" & ASCII.LF &
        "   with function After_Broken return Element is <>;" & ASCII.LF &
        "package Formal_Subprogram_Default_Recovery is" & ASCII.LF &
        "end Formal_Subprogram_Default_Recovery;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Abstract_Name),
              "formal subprogram defaults must retain abstract default designator names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary),
              "formal subprogram defaults missing their target must retain a bounded recovery marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Declaration) >= 3,
              "recovery after a malformed formal subprogram default must resume at following formals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Default_Box),
              "recovery after a malformed formal subprogram default must retain later box defaults");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery;




   procedure Test_Language_Model_Token_Cursor_Formal_Package_Actual_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Broken is new Ada.Containers.Vectors" & ASCII.LF &
        "     (Index_Type => Positive," & ASCII.LF &
        "      Element_Type => Element;" & ASCII.LF &
        "   type After is private;" & ASCII.LF &
        "package Formal_Package_Recovery is" & ASCII.LF &
        "end Formal_Package_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "malformed formal package declarations must still retain formal package grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Association),
              "malformed formal package actual lists must retain parsed associations before recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "malformed formal package actual lists must report a bounded recovery point");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "formal package actual-list recovery must resume at the following generic formal declaration");
   end Test_Language_Model_Token_Cursor_Formal_Package_Actual_Recovery;



   procedure Test_Language_Model_Token_Cursor_Formal_Package_Hostile_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Missing_Name is new (<>);" & ASCII.LF &
        "   with package Empty_Name is new;" & ASCII.LF &
        "   with package Broken_Actual is new Generic_Broken" & ASCII.LF &
        "     (Element_Type Element," & ASCII.LF &
        "      Key_Type => Key," & ASCII.LF &
        "      Make => Factory (Item Element, Count => N)," & ASCII.LF &
        "      others => <>" & ASCII.LF &
        "     with Preelaborate;" & ASCII.LF &
        "   type After is private;" & ASCII.LF &
        "package Formal_Package_Hostile is" & ASCII.LF &
        "end Formal_Package_Hostile;";
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
              "hostile formal package recovery must retain formal package declarations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Missing_Generic_Name) >= 2,
              "formal package declarations missing a generic name after is new must be tagged");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Missing_Generic_Recovery_Boundary),
              "missing formal package generic names must retain a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Missing_Arrow_Recovery_Boundary),
              "formal package actual associations with omitted arrows must be recoverable");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Recovery_Boundary),
              "incomplete formal package actual lists before aspects must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Aspect_Specification),
              "recovery must still leave trailing generic-formal aspects visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "formal package hostile recovery must resume at following generic formals");
   end Test_Language_Model_Token_Cursor_Formal_Package_Hostile_Recovery;






   procedure Test_Language_Model_Token_Cursor_Formal_Package_Header_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Missing_Is new Ada.Containers.Vectors (<>);" & ASCII.LF &
        "   with package Missing_New is Ada.Containers.Ordered_Maps (Key_Type => Key, Element_Type);" & ASCII.LF &
        "   with package Missing_Generic is new with Pure;" & ASCII.LF &
        "   type After is private;" & ASCII.LF &
        "package Formal_Package_Header_Recovery is" & ASCII.LF &
        "end Formal_Package_Header_Recovery;";
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
              "formal package header recovery must retain all formal package declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Missing_Is_Recovery_Boundary),
              "formal package declarations missing is must retain a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Missing_New_Recovery_Boundary),
              "formal package declarations missing new must retain a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Missing_Generic_Recovery_Boundary),
              "formal package declarations missing generic names must retain a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Box),
              "formal package (<>) actual parts must remain structural after header recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Named_To_Positional_Order_Recovery_Boundary),
              "formal package actuals must flag positional associations after named associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "formal package header recovery must resume at following generic formal declarations");
   end Test_Language_Model_Token_Cursor_Formal_Package_Header_Recovery;




   procedure Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer is" & ASCII.LF &
        "   Visible_Value : Integer;" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Nested_Hidden : Integer;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "   procedure Visible_Op;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Hidden_Value : Integer;" & ASCII.LF &
        "   pragma Inline (Visible_Op);" & ASCII.LF &
        "end Outer;" & ASCII.LF &
        "package body Outer is" & ASCII.LF &
        "   package Nested_Body is" & ASCII.LF &
        "      Local : Integer;" & ASCII.LF &
        "   end Nested_Body;" & ASCII.LF &
        "   Body_Value : Integer;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Outer;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Visible_Part),
              "package visible parts must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Package_Visible_Declarative_Item) >= 3,
              "visible package declarative items must be retained without losing nested specs");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Private_Declarative_Part),
              "package private declarative parts must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Package_Private_Declarative_Item) >= 2,
              "private package declarative items must be retained after the private boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Declarative_Item),
              "package body declarative items must be retained before begin");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Statement_Sequence),
              "package-body recovery must continue into the statement sequence after declarations");
   end Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Completeness;




   procedure Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Hostile is" & ASCII.LF &
        "   type Hidden_Handle is private" & ASCII.LF &
        "   procedure After_Missing_Semicolon;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   package Nested_Generic is" & ASCII.LF &
        "      for Element'Size use 32;" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Recovery_Value : Integer" & ASCII.LF &
        "      pragma Inline (After_Missing_Semicolon);" & ASCII.LF &
        "   end Nested_Generic;" & ASCII.LF &
        "private" & ASCII.LF &
        "   for Hidden_Handle'Size use 64" & ASCII.LF &
        "   procedure Private_After_Rep_Clause;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Hostile;" & ASCII.LF &
        "package body Hostile is" & ASCII.LF &
        "   Body_Value : Integer" & ASCII.LF &
        "   protected Local_Lock is" & ASCII.LF &
        "      procedure Touch;" & ASCII.LF &
        "   end Local_Lock;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Stray_Private_Value : Integer;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Hostile;";
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
                (Editor.Ada_Token_Cursor.Production_Package_Visible_Declarative_Item) >= 5,
              "hostile visible package recovery must continue across missing semicolons, nested generics, nested packages, and representation clauses");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Package_Private_Declarative_Item) >= 2,
              "hostile private package recovery must continue after malformed representation clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Unexpected_Begin_Boundary),
              "premature begin in a package spec must be recorded as a package recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Unexpected_Private_Boundary),
              "unexpected private in a package body must be retained as recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Statement_Sequence),
              "package body recovery must resume at begin after a stray private boundary");
   end Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery;



   procedure Test_Language_Model_Token_Cursor_Body_Declarative_Item_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Body_Declarative_Recovery is" & ASCII.LF &
        "   Broken_Value : Integer" & ASCII.LF &
        "   procedure Nested is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Nested;" & ASCII.LF &
        "end Body_Declarative_Recovery;" & ASCII.LF &
        "procedure Subprogram_Declarative_Recovery is" & ASCII.LF &
        "   Local_Value : Integer" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Subprogram_Declarative_Recovery;" & ASCII.LF &
        "After_Recovery : Integer;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Declarative_Recovery_Boundary),
              "package body declarative recovery must mark missing-semicolon synchronization before a nested declaration");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Declarative_Recovery_Boundary),
              "subprogram body declarative recovery must mark missing-semicolon synchronization before begin");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Statement_Sequence),
              "package body declarative recovery must resume at the handled statement sequence");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Begin_Keyword),
              "subprogram body declarative recovery must retain the real begin keyword");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "body declarative recovery must continue into following declarations after the body");
   end Test_Language_Model_Token_Cursor_Body_Declarative_Item_Recovery_Depth;




   procedure Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Broken_Contract_Aspects is" & ASCII.LF &
        "   procedure Broken (X : Integer)" & ASCII.LF &
        "     with Pre => , Post => X > 0;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Broken_Contract_Aspects;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Contract_Aspect_Association),
              "malformed contract aspects must still retain the contract association");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "missing contract aspect values must produce a bounded recovery point");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after malformed contract aspects");
   end Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Recovery;





   procedure Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Package_Section_Recovery is" & ASCII.LF &
        "   Visible_Item : constant Integer := 1" & ASCII.LF &
        "   private" & ASCII.LF &
        "   Hidden_Item : Integer;" & ASCII.LF &
        "   private" & ASCII.LF &
        "   Another_Hidden_Item : Integer;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Package_Section_Recovery;" & ASCII.LF &
        "package body Package_Section_Recovery is" & ASCII.LF &
        "   Body_Item : Integer;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Body_Private_Item : Integer;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Package_Section_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Declarative_Private_Boundary),
              "missing semicolon before private must still expose a private-section boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Duplicate_Private_Boundary),
              "duplicate private sections must be retained as explicit package recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Private_Begin_Recovery_Boundary),
              "begin inside a package private part must have private-section recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Body_Private_Declarative_Recovery_Boundary),
              "private inside a package body declarative part must have package-body-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Private_Declarative_Item_Recovery_Boundary),
              "private-part recovery must not consume the next private declarative item silently");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Package_Body_Statement_Sequence),
              "package-body recovery must still reach the body statement sequence");
   end Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth;



   procedure Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Anonymous_Access_Subprogram_Edges is" & ASCII.LF &
        "   type Protected_Default is access protected procedure" & ASCII.LF &
        "     (Handler : not null access procedure (Value : Integer) := Default_Hook);" & ASCII.LF &
        "   type Constrained_Factory is not null access function" & ASCII.LF &
        "     (Seed : Integer := 1) return not null access Root.Child (Kind => Active);" & ASCII.LF &
        "   Broken : access function (Left : Integer);" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Anonymous_Access_Subprogram_Edges;";
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
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Null_Exclusion) >= 1,
              "not-null anonymous access-to-subprogram forms must keep access-specific null exclusion metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Parameter_Default) >= 1,
              "defaults inside anonymous access-to-subprogram parameter profiles must be explicit metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Result_Null_Exclusion) >= 1,
              "not-null access-to-function result subtypes must remain explicit");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Result_Constraint) >= 1,
              "constrained access-to-function result subtypes must retain result-constraint metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Subprogram_Profile_Recovery_Boundary),
              "malformed anonymous access-to-function profiles must produce bounded profile recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into declarations after malformed anonymous access profiles");
   end Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery;







   procedure Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refined_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Anonymous_Access_Subprogram_Refined_Recovery is" & ASCII.LF &
        "   Missing_Protected_Kind : access protected;" & ASCII.LF &
        "   Missing_Return : access function (Item : Integer);" & ASCII.LF &
        "   Missing_Result : access protected function (Item : Integer) return;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Anonymous_Access_Subprogram_Refined_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Protected_Missing_Subprogram_Recovery_Boundary),
              "dangling access protected definitions must expose protected-subprogram-specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Function_Missing_Return_Recovery_Boundary),
              "access-to-function definitions without return must expose missing-return recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary),
              "access-to-function return clauses without result subtype must expose missing-result recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "specific anonymous access recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refined_Recovery;



   procedure Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Definition_Recovery_Depth is" & ASCII.LF &
        "   Missing_All_Subtype : access all;" & ASCII.LF &
        "   Missing_Constant_Subtype : access constant with Volatile;" & ASCII.LF &
        "   Mode_Subprogram_Conflict : access all procedure;" & ASCII.LF &
        "   Missing_Protected_Kind : access protected with Convention => Ada;" & ASCII.LF &
        "   Missing_Return_Result : access function return with Pre => Ready;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Access_Definition_Recovery_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Access_Mode_Missing_Subtype_Recovery_Boundary) >= 2,
              "access all/constant definitions missing a designated subtype must expose mode-specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary),
              "access all/constant followed by procedure/function/protected must expose mode/profile conflict recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Protected_Missing_Subprogram_Boundary_Token),
              "access protected recovery must retain the actual boundary token after the missing procedure/function keyword");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Result_Missing_Subtype_Recovery_Boundary),
              "access-to-function return clauses at aspect/declaration boundaries must expose result-subtype recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "access-definition recovery depth must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth;





   procedure Test_Language_Model_Token_Cursor_Record_Representation_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Representation_Recovery is" & ASCII.LF &
        "   type R is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "      C : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for R use record" & ASCII.LF &
        "      A at 0;" & ASCII.LF &
        "      B range 0 .. 7;" & ASCII.LF &
        "      C at 1 range 0;" & ASCII.LF &
        "   end;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Record_Representation_Recovery;";
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
                (Editor.Ada_Token_Cursor.Production_Representation_Component_Clause) >= 3,
              "malformed record representation component clauses must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Missing_Range_Recovery_Boundary),
              "component clauses missing range must retain record-representation-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Missing_At_Recovery_Boundary),
              "component clauses missing at must retain record-representation-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Representation_Missing_End_Record_Recovery_Boundary),
              "record representation clauses ending with bare end must retain missing-end-record recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "record representation recovery must continue to emit the shared bounded recovery marker");
   end Test_Language_Model_Token_Cursor_Record_Representation_Recovery;




   procedure Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Case_825
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Package_Declarative_Item_Recovery is" & ASCII.LF &
        "   Broken_Visible : constant := 1" & ASCII.LF &
        "   procedure Next_Visible;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Broken_Private : constant := 2" & ASCII.LF &
        "   type Private_Type is null record;" & ASCII.LF &
        "end Package_Declarative_Item_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Visible_Declarative_Item),
              "package visible declarative items must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Private_Declarative_Item),
              "package private declarative items must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Visible_Declarative_Item_Recovery_Boundary),
              "malformed visible declarative items must retain visible-part-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Private_Declarative_Item_Recovery_Boundary),
              "malformed private declarative items must retain private-part-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration_End_Terminator),
              "declarative item recovery must leave the package end terminator available");
   end Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Case_825;




   procedure Test_Language_Model_Token_Cursor_Pragma_Recovery_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Pragma_Recovery_Grammar is" & ASCII.LF &
        "   pragma Suppress (Check => );" & ASCII.LF &
        "   Next : Integer;" & ASCII.LF &
        "end Pragma_Recovery_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_List),
              "malformed pragmas must still retain their pragma-specific argument list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Identifier),
              "malformed named pragma arguments must keep their selector before recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "malformed pragma arguments must produce a bounded recovery point");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "pragma recovery must continue into the following declaration");
   end Test_Language_Model_Token_Cursor_Pragma_Recovery_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Pragma_Recovery_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Pragma_Recovery_Depth is" & ASCII.LF &
        "   pragma ();" & ASCII.LF &
        "   pragma Assert ();" & ASCII.LF &
        "   pragma Suppress (Range_Check,);" & ASCII.LF &
        "   pragma Import (Convention => );" & ASCII.LF &
        "   pragma Pure" & ASCII.LF &
        "   Next : Integer;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Pragma_Recovery_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Identifier_Missing_Recovery_Boundary),
              "pragma recovery must distinguish missing pragma identifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_List_Empty_Recovery_Boundary),
              "pragma recovery must distinguish empty argument lists");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Trailing_Separator_Recovery_Boundary),
              "pragma recovery must distinguish trailing argument separators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Missing_Expression_Recovery_Boundary),
              "pragma recovery must distinguish missing argument expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Missing_Terminator_Recovery_Boundary),
              "pragma recovery must distinguish missing pragma terminators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "pragma recovery must continue into the following declaration");
   end Test_Language_Model_Token_Cursor_Pragma_Recovery_Depth;




   procedure Test_Language_Model_Token_Cursor_Attribute_Address_Clause_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with System;" & ASCII.LF &
        "package Rep_Attribute_Address_Recovery is" & ASCII.LF &
        "   type Word is range 0 .. 255;" & ASCII.LF &
        "   for Word'Size 8;" & ASCII.LF &
        "   for Word'Alignment use;" & ASCII.LF &
        "   Obj : Word;" & ASCII.LF &
        "   for Obj'Address use;" & ASCII.LF &
        "   Other : Word;" & ASCII.LF &
        "   for Other use at;" & ASCII.LF &
        "   After : Word;" & ASCII.LF &
        "end Rep_Attribute_Address_Recovery;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Definition_Missing_Use_Recovery_Boundary),
              "attribute-definition clauses must distinguish missing use recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Definition_Missing_Value_Recovery_Boundary),
              "attribute-definition clauses must distinguish missing value recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Address_Clause_Missing_Value_Recovery_Boundary),
              "address clauses must distinguish missing address value recovery");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Address_Clause) >= 2,
              "address attribute and use-at address clauses must remain classified structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 3,
              "representation recovery must continue into following object declarations");
   end Test_Language_Model_Token_Cursor_Attribute_Address_Clause_Recovery;




   procedure Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Task_Protected_Declarative_Recovery is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "      Broken : Integer :=" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected body Guard is" & ASCII.LF &
        "      procedure Touch is" & ASCII.LF &
        "         Broken : Integer :=" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Touch;" & ASCII.LF &
        "   end Guard;" & ASCII.LF &
        "end Task_Protected_Declarative_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Declarative_Item_Start),
              "task bodies must retain declarative-item starts before begin");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Task_Body_Declarative_Item_Recovery_Boundary),
              "malformed task body declarative items must expose task-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Task_Body_Declarative_Begin_Boundary),
              "task body declarative recovery must preserve begin synchronizers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Begin_Keyword),
              "task body recovery must continue into the body begin keyword");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Declarative_Item_Start),
              "protected operation bodies must retain declarative-item starts before begin");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Protected_Body_Declarative_Item_Recovery_Boundary),
              "malformed protected operation declarative items must expose protected-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Protected_Body_Declarative_Begin_Boundary),
              "protected operation declarative recovery must preserve begin synchronizers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_Begin_Keyword),
              "protected body recovery must continue into the operation begin keyword");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_End_Terminator),
              "task/protected body declarative recovery must preserve enclosing package completion");
   end Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery;




   procedure Test_Language_Model_Token_Cursor_Generic_Actual_Association_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Generic_Actual_Association_Recovery is" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type T is private;" & ASCII.LF &
        "      Default : Integer;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "   package Empty_List is new G ();" & ASCII.LF &
        "   package Missing_Named is new G (T =>, Default => 1);" & ASCII.LF &
        "   package Trailing is new G (Integer,);" & ASCII.LF &
        "   After : constant Integer := 42;" & ASCII.LF &
        "end Generic_Actual_Association_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Part),
              "generic actual parts must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Association),
              "generic actual association recovery must preserve association metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Generic_Actual_Empty_List_Recovery_Boundary),
              "empty generic actual lists must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Generic_Actual_Missing_Actual_Recovery_Boundary),
              "named generic actuals missing values must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Generic_Actual_Trailing_Separator_Recovery_Boundary),
              "trailing generic actual separators must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "generic actual association recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "generic actual association recovery must preserve following declarations");
   end Test_Language_Model_Token_Cursor_Generic_Actual_Association_Recovery;




   procedure Test_Language_Model_Token_Cursor_Renaming_Target_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Renaming_Target_Recovery is" & ASCII.LF &
        "   package Missing_Target renames;" & ASCII.LF &
        "   package Aspect_Only renames with Preelaborate;" & ASCII.LF &
        "   package Good renames Ada.Text_IO;" & ASCII.LF &
        "   After : constant Integer := 42;" & ASCII.LF &
        "end Renaming_Target_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renaming_Declaration),
              "renaming declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Renaming_Declaration),
              "package renaming declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Renaming_Missing_Target_Recovery_Boundary),
              "renamings missing target entities must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renaming_Aspect_Specification),
              "renaming target recovery must preserve following aspect metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Renamed_Package_Name),
              "renaming target recovery must preserve valid following renamed package targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "renaming target recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "renaming target recovery must preserve following declarations");
   end Test_Language_Model_Token_Cursor_Renaming_Target_Recovery;





   procedure Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Entry_Barrier_Condition_Recovery is" & ASCII.LF &
        "   entry Missing_Condition when is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Missing_Condition;" & ASCII.LF &
        "   entry Missing_Protected when is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Missing_Protected;" & ASCII.LF &
        "   entry Normal when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Normal;" & ASCII.LF &
        "end Entry_Barrier_Condition_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier),
              "entry barriers must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier_When_Keyword),
              "entry barrier recovery must preserve when keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Entry_Barrier_Missing_Condition_Recovery_Boundary),
              "entry barriers missing conditions must expose entry-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary),
              "protected entry barrier scans must expose protected-entry-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Barrier_Condition),
              "valid following entry barriers must preserve condition metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Begin_Keyword),
              "barrier recovery must preserve following entry body metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "barrier recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Recovery;





   procedure Test_Language_Model_Token_Cursor_Entry_Family_Empty_Definition_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected type Entry_Family_Empty_Recovery is" & ASCII.LF &
        "   entry Empty ();" & ASCII.LF &
        "   entry Normal (Positive) (Item : Integer);" & ASCII.LF &
        "private" & ASCII.LF &
        "   entry Private_Empty ();" & ASCII.LF &
        "end Entry_Family_Empty_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Declaration),
              "entry declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Definition),
              "entry family definitions must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Entry_Family_Empty_Definition_Recovery_Boundary),
              "empty entry family definitions must expose entry-family-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Family_Index_Subtype),
              "valid following entry family index subtypes must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Parameter_Profile),
              "valid following entry parameter profiles must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "empty entry family recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Entry_Family_Empty_Definition_Recovery;




   procedure Test_Language_Model_Token_Cursor_Call_Actual_Association_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Call_Actual_Association_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Empty_List ();" & ASCII.LF &
        "   Missing_Named (Item =>, Other => 1);" & ASCII.LF &
        "   Trailing (1,);" & ASCII.LF &
        "   Valid (Item => 1);" & ASCII.LF &
        "end Call_Actual_Association_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_List),
              "call actual lists must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Call_Actual_Empty_List_Recovery_Boundary),
              "empty call actual lists must expose call-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Call_Actual_Missing_Actual_Recovery_Boundary),
              "named call actual associations missing expressions must expose recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Call_Actual_Trailing_Separator_Recovery_Boundary),
              "trailing call actual separators must expose recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_Association),
              "valid following call actual associations must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Terminator),
              "valid following call statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "call actual recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Call_Actual_Association_Recovery;






   procedure Test_Language_Model_Token_Cursor_If_Elsif_Condition_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure If_Elsif_Condition_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   elsif then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   else" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end If_Elsif_Condition_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement),
              "if statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_If_Statement_Missing_Condition_Recovery_Boundary),
              "if statements missing conditions before then must expose recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Elsif_Statement_Missing_Condition_Recovery_Boundary),
              "elsif parts missing conditions before then must expose recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Then_Keyword),
              "then keywords must remain visible after missing-condition recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Condition),
              "valid following if conditions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_End_Terminator),
              "if end terminators must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "if/elsif condition recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_If_Elsif_Condition_Recovery;






   procedure Test_Language_Model_Token_Cursor_While_Condition_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure While_Condition_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   while loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   while Ready loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end While_Condition_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Statement),
              "while loop statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_While_Loop_Missing_Condition_Recovery_Boundary),
              "while loops missing conditions before loop must expose recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Keyword),
              "while keywords must remain visible after missing-condition recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Begin_Keyword),
              "loop keywords must remain visible after missing-condition recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Condition),
              "valid following while conditions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_End_Terminator),
              "while loop end terminators must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "while condition recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_While_Condition_Recovery;



   procedure Test_Language_Model_Token_Cursor_Hostile_Source_Recovery_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Broken is new Ada.Containers.Vectors" & ASCII.LF &
        "     (Index_Type => Positive," & ASCII.LF &
        "      Element_Type => Element;" & ASCII.LF &
        "   type Formal_After is private;" & ASCII.LF &
        "package Hostile_Recovery is" & ASCII.LF &
        "   type Kind is (Small, Medium, Large, Special);" & ASCII.LF &
        "   type Rec (K : Kind) is record" & ASCII.LF &
        "      case K is" & ASCII.LF &
        "         when Small | Medium =>" & ASCII.LF &
        "            A : Integer;" & ASCII.LF &
        "         when Large .. Special" & ASCII.LF &
        "            B : Integer;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Bad_Aggregate : Vector := (1 => , 2 .. 4 => 0, others => <>);" & ASCII.LF &
        "   pragma Inline (Run" & ASCII.LF &
        "   for Rec'Size use 64" & ASCII.LF &
        "   procedure Run (V : in out Vector) with" & ASCII.LF &
        "      Pre => V'Length > 0," & ASCII.LF &
        "      Post => ;" & ASCII.LF &
        "end Hostile_Recovery;" & ASCII.LF &
        "package body Hostile_Recovery is" & ASCII.LF &
        "   procedure Run (V : in out Vector) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         when Ready" & ASCII.LF &
        "            accept E do null; end E;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay until Deadline;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   exception" & ASCII.LF &
        "      when Constraint_Error | Ada.IO_Exceptions.Name_Error" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      when others => null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Hostile_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);

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
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Recovery_Boundary),
              "hostile generic formal-package actual recovery must remain bounded");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "generic recovery must resume at following formal type declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Recovery_Boundary),
              "malformed variant alternatives must retain an explicit recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Recovery_Boundary),
              "broken aggregate associations must retain an explicit recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Alternative_Recovery_Boundary),
              "broken select guards must retain an explicit recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Recovery_Boundary),
              "broken exception handlers must retain an explicit recovery boundary");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Recovery_Point) >= 4,
              "hostile-source matrix must retain multiple bounded recovery points");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 1,
              "recovery must continue into declarations after malformed generic formals");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subprogram_Body) >= 1,
              "recovery must continue into following package-body subprograms");
      Assert (Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) >= 4,
              "hostile-source matrix must surface conservative recovery diagnostics from parser recovery markers");
   end Test_Language_Model_Token_Cursor_Hostile_Source_Recovery_Matrix;


   overriding function Name (T : Token_Cursor_Recovery_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Recovery");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Recovery_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Grammar_Completeness'Access, Name => "token-cursor grammar recovers from malformed use-clause lists");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery'Access, Name => "token-cursor grammar records use-clause specific recovery boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth'Access, Name => "token-cursor grammar records use-clause recovery depth for all/type boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Representation_Item_Recovery_Depth'Access, Name => "token-cursor grammar records representation item recovery depth at declaration boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery'Access, Name => "token-cursor grammar records enumeration representation specific recovery boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Case_878'Access, Name => "token-cursor grammar records package declarative item recovery boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery'Access, Name => "token-cursor grammar records empty formal package actual recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery'Access, Name => "token-cursor grammar recovers formal subprogram abstract and missing defaults structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Actual_Recovery'Access, Name => "token-cursor grammar recovers after malformed formal package actual parts");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Hostile_Recovery'Access, Name => "token-cursor grammar recovers hostile formal package declarations");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Header_Recovery'Access, Name => "token-cursor grammar recovers formal package headers and actual ordering");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Completeness'Access, Name => "token-cursor grammar parses package declarative item boundaries structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery'Access, Name => "token-cursor grammar recovers package declarative items in hostile nested/private cases");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Body_Declarative_Item_Recovery_Depth'Access, Name => "token-cursor grammar synchronizes malformed body declarative items");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Recovery'Access, Name => "token-cursor grammar recovers from malformed contract aspect values");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth'Access, Name => "token-cursor grammar deepens package declarative section recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery'Access, Name => "token-cursor grammar recovers anonymous access-to-subprogram edge profiles");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refined_Recovery'Access, Name => "token-cursor grammar refines anonymous access-to-subprogram recovery boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth'Access, Name => "token-cursor grammar deepens access all constant protected and result recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Record_Representation_Recovery'Access, Name => "token-cursor grammar recovers malformed record representation clauses");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Case_825'Access, Name => "token-cursor grammar distinguishes visible and private package declarative item recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Recovery_Grammar_Completeness'Access, Name => "token-cursor grammar recovers from malformed pragma arguments");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Pragma_Recovery_Depth'Access, Name => "token-cursor grammar deepens pragma recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Attribute_Address_Clause_Recovery'Access, Name => "token-cursor grammar recovers malformed attribute and address clauses");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery'Access, Name => "token-cursor grammar recovers task/protected body declarative items before begin");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Actual_Association_Recovery'Access, Name => "token-cursor grammar recovers malformed generic actual association lists");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Renaming_Target_Recovery'Access, Name => "token-cursor grammar recovers renamings missing renamed targets");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Recovery'Access, Name => "token-cursor grammar recovers entry barriers missing conditions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Family_Empty_Definition_Recovery'Access, Name => "token-cursor grammar recovers empty entry family definitions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Call_Actual_Association_Recovery'Access, Name => "token-cursor grammar recovers malformed call actual association lists");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_If_Elsif_Condition_Recovery'Access, Name => "token-cursor grammar recovers if/elsif conditions missing before then");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_While_Condition_Recovery'Access, Name => "token-cursor grammar recovers while conditions missing before loop");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Hostile_Source_Recovery_Matrix'Access, Name => "token-cursor grammar recovers across hostile mixed Ada source constructs");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Recovery_Tests;
