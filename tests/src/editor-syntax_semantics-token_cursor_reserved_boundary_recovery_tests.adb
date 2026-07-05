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

package body Editor.Syntax_Semantics.Token_Cursor_Reserved_Boundary_Recovery_Tests is

   procedure Test_Language_Model_Token_Cursor_Abort_Target_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Abort_Target_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   abort Worker, else;" & ASCII.LF &
        "   abort Other;" & ASCII.LF &
        "end Abort_Target_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Statement),
              "abort statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_List),
              "abort target lists must remain visible before recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_Name),
              "valid abort targets before the malformed separator must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Missing_Target_Recovery_Boundary),
              "abort target lists missing a target after comma must retain target-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Abort_Target_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after comma must not be fabricated as abort targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Terminator),
              "valid following abort statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "abort target reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Abort_Target_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Requeue_Target_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Requeue_Target_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      entry Step;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Step do" & ASCII.LF &
        "         requeue else;" & ASCII.LF &
        "         requeue Step;" & ASCII.LF &
        "      end Step;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Requeue_Target_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Statement),
              "requeue statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Requeue_Missing_Target_Recovery_Boundary),
              "reserved statement-sequence boundaries after requeue must retain missing-target recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after requeue must not be fabricated as entry names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Target_Recovery_Boundary),
              "reserved-boundary recovery must preserve broader requeue target recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Entry_Name),
              "valid following requeue targets must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Terminator),
              "valid following requeue statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "requeue reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Requeue_Target_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Delay_Expression_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Delay_Expression_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   delay then;" & ASCII.LF &
        "   delay until when;" & ASCII.LF &
        "   delay 1.0;" & ASCII.LF &
        "end Delay_Expression_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement),
              "delay statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Delay_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries must not be fabricated as delay expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Delay_Relative_Missing_Expression_Recovery_Boundary),
              "relative delay statements with reserved boundaries must retain missing-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Delay_Until_Missing_Expression_Recovery_Boundary),
              "delay-until statements with reserved boundaries must retain missing-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Relative_Expression),
              "valid following relative delay expressions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement_Terminator),
              "valid following delay statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "delay reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Delay_Expression_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Goto_Target_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Goto_Target_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   goto else;" & ASCII.LF &
        "   goto Valid_Label;" & ASCII.LF &
        "   <<Valid_Label>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Goto_Target_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Statement),
              "goto statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Goto_Missing_Target_Recovery_Boundary),
              "reserved statement-sequence boundaries after goto must retain missing-target recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Goto_Target_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after goto must not be fabricated as label names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Recovery_Boundary),
              "reserved-boundary recovery must preserve broader goto recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Label_Name),
              "valid following goto labels must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Terminator),
              "valid following goto statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "goto reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Goto_Target_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Return_Expression_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "function Return_Expression_Reserved_Boundary_Recovery return Integer is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   return else;" & ASCII.LF &
        "   return 42;" & ASCII.LF &
        "end Return_Expression_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Statement),
              "return statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Return_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after return must not be fabricated as return expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Recovery_Boundary),
              "reserved-boundary recovery must preserve broader return recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Expression),
              "valid following return expressions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Terminator),
              "valid following return statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "return reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Return_Expression_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Raise_Target_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Raise_Target_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise else;" & ASCII.LF &
        "   raise Constraint_Error;" & ASCII.LF &
        "end Raise_Target_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement),
              "raise statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary),
              "reserved statement-sequence boundaries after raise must retain missing-exception recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Raise_Target_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after raise must not be fabricated as exception names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement_Recovery_Boundary),
              "reserved-boundary recovery must preserve broader raise recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Exception_Name),
              "valid following raise exception names must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Terminator),
              "valid following raise statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "raise reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Raise_Target_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Exit_Target_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Exit_Target_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   loop" & ASCII.LF &
        "      exit else;" & ASCII.LF &
        "      exit Worker when Done;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Exit_Target_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "exit statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Exit_Target_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after exit must not be fabricated as loop names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Recovery_Boundary),
              "reserved-boundary recovery must preserve broader exit recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Loop_Name),
              "valid following exit loop names must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "valid following exit when conditions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Terminator),
              "valid following exit statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "exit reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Exit_Target_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Assignment_Expression_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Assignment_Expression_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Value := else;" & ASCII.LF &
        "   Value := 1;" & ASCII.LF &
        "end Assignment_Expression_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "assignment statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Assignment_Reserved_Boundary_Recovery_Boundary),
              "reserved statement-sequence boundaries after := must not be fabricated as assignment expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Assignment_Missing_Expression_Recovery_Boundary),
              "reserved-boundary assignment recovery must preserve missing-expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Expression),
              "valid following assignment expressions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Terminator),
              "valid following assignment statements must preserve terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "assignment reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Assignment_Expression_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_For_Iterator_Domain_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure For_Iterator_Domain_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   for I in else loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for C of else loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for J in 1 .. 3 loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for D of Items loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end For_Iterator_Domain_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Scheme),
              "for loop iteration schemes must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_For_Loop_Domain_Reserved_Boundary_Recovery_Boundary),
              "for loop domains at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Iteration_Scheme),
              "iterator loop iteration schemes must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Iterator_Loop_Domain_Reserved_Boundary_Recovery_Boundary),
              "iterator loop domains at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Domain),
              "valid following for loop domains must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Domain),
              "valid following iterator loop domains must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_End_Terminator),
              "loop end terminators must remain visible after domain recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "for/iterator domain recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_For_Iterator_Domain_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Case_Selector_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Case_Selector_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case is" & ASCII.LF &
        "      when others => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   case Mode is" & ASCII.LF &
        "      when others => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "end Case_Selector_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement),
              "case statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary),
              "case selectors at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement_Selector),
              "valid following case selectors must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement_Is_Keyword),
              "case is keywords must remain visible after selector recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_End_Terminator),
              "case end terminators must remain visible after selector recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "case selector recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Case_Selector_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Extended_Return_Initializer_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Extended_Return_Initializer_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   function Make return Integer is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Result : Integer := do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end return;" & ASCII.LF &
        "   end Make;" & ASCII.LF &
        "   function Valid return Integer is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Value : Integer := 1 do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end return;" & ASCII.LF &
        "   end Valid;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Extended_Return_Initializer_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Statement),
              "extended return statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Initializer),
              "extended return initializers must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Extended_Return_Initializer_Reserved_Boundary_Recovery_Boundary),
              "extended return initializers at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Do_Keyword),
              "extended return do keywords must remain visible after initializer recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_End_Return),
              "extended return end-return terminators must remain visible after initializer recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "extended return initializer recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Extended_Return_Initializer_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Raise_Message_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Raise_Message_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise Program_Error with else;" & ASCII.LF &
        "   raise Constraint_Error with ""bad"";" & ASCII.LF &
        "end Raise_Message_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement),
              "raise statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_With_Message_Keyword),
              "raise-with message keywords must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Recovery_Boundary),
              "raise missing-message recovery must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Raise_Message_Reserved_Boundary_Recovery_Boundary),
              "raise messages at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "valid raise message expressions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Terminator),
              "raise statement terminators must remain visible after message recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "raise message reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Raise_Message_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Exit_When_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Exit_When_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   Done : Boolean := False;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   loop" & ASCII.LF &
        "      exit when else;" & ASCII.LF &
        "      exit when Done;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Exit_When_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "exit statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Keyword),
              "exit-when keywords must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Exit_When_Missing_Condition_Recovery_Boundary),
              "missing exit-when condition recovery must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Exit_When_Reserved_Boundary_Recovery_Boundary),
              "exit-when conditions at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "valid exit-when conditions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Terminator),
              "exit terminators must remain visible after condition recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "exit-when reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Exit_When_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Null_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Null_Reserved_Boundary_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      null else" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Null_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "null statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Null_Missing_Terminator_Recovery_Boundary),
              "null statements missing semicolons must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Null_Reserved_Boundary_Recovery_Boundary),
              "null statements at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement_Terminator),
              "valid following null terminators must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "null reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Null_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Aggregate_Component_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aggregate_Component_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   type Arr is array (Positive range <>) of Integer;" & ASCII.LF &
        "   Broken : Arr := (1 => else, 2 => 10);" & ASCII.LF &
        "   Valid  : Arr := (1 => 1, 2 => 2);" & ASCII.LF &
        "end Aggregate_Component_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Named_Component_Association),
              "named aggregate component associations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Component_Arrow),
              "aggregate component arrows must remain visible during recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary),
              "aggregate component expressions at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aggregate_Recovery_Boundary),
              "aggregate-specific recovery metadata must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "aggregate component reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Aggregate_Component_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Object_Initialization_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Initialization_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   Broken_With : Integer := with Volatile;" & ASCII.LF &
        "   Valid       : Integer := 1;" & ASCII.LF &
        "end Object_Initialization_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "object declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Initialization_Expression),
              "object initialization expressions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary),
              "object initializers at reserved/aspect boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Recovery_Boundary),
              "object declaration recovery metadata must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "object initializer reserved-boundary recovery must preserve generic recovery metadata");
   end Test_Language_Model_Token_Cursor_Object_Initialization_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Range_Constraint_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Range_Constraint_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   subtype Missing_Lower is Integer range else;" & ASCII.LF &
        "   subtype Missing_Upper is Integer range 1 .. else;" & ASCII.LF &
        "   subtype Valid_Range is Integer range 1 .. 10;" & ASCII.LF &
        "end Range_Constraint_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "range constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary),
              "range constraints missing lower bounds must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary),
              "range constraints missing upper bounds must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary),
              "range constraints at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Upper_Bound),
              "valid following range upper bounds must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constraint_Recovery_Boundary),
              "range reserved-boundary recovery must preserve constraint recovery metadata");
   end Test_Language_Model_Token_Cursor_Range_Constraint_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Digits_Delta_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Digits_Delta_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   subtype Missing_Digits is Float digits else;" & ASCII.LF &
        "   subtype Missing_Delta is Fixed delta else;" & ASCII.LF &
        "   subtype Valid_Digits is Float digits 6;" & ASCII.LF &
        "end Digits_Delta_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Digits_Constraint),
              "digits constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Constraint),
              "delta constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Digits_Constraint_Missing_Expression_Recovery_Boundary),
              "digits constraints missing expressions must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Delta_Constraint_Missing_Expression_Recovery_Boundary),
              "delta constraints missing expressions must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary),
              "digits constraints at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary),
              "delta constraints at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Digits_Constraint_Expression),
              "valid following digits constraint expressions must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Digits_Delta_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Index_Discriminant_Constraint_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Index_Discriminant_Constraint_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   subtype Missing_Index_Item is Vector (else);" & ASCII.LF &
        "   subtype Missing_Index_Upper is Vector (1 .. else);" & ASCII.LF &
        "   type Rec (D : Integer) is null record;" & ASCII.LF &
        "   subtype Missing_Discriminant is Rec (D => else);" & ASCII.LF &
        "   subtype Valid_Index is Vector (1 .. 10);" & ASCII.LF &
        "   subtype Valid_Discriminant is Rec (D => 1);" & ASCII.LF &
        "end Index_Discriminant_Constraint_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint),
              "index constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Index_Constraint_Missing_Item_Recovery_Boundary),
              "index constraints missing items must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary),
              "index constraints at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint),
              "discriminant constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Discriminant_Association_Missing_Expression_Recovery_Boundary),
              "discriminant associations missing expressions must retain recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary),
              "discriminant constraints at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Upper_Bound),
              "valid following index upper bounds must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint_Expression),
              "valid following discriminant expressions must remain visible after recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constraint_Recovery_Boundary),
              "index/discriminant reserved-boundary recovery must preserve constraint recovery metadata");
   end Test_Language_Model_Token_Cursor_Index_Discriminant_Constraint_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Profile_Default_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Profile_Default_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   procedure Missing_Close (Item : Integer := );" & ASCII.LF &
        "   procedure Missing_Separator (Item : Integer := ; Other : Integer);" & ASCII.LF &
        "   procedure Missing_With (Item : Integer := with Inline);" & ASCII.LF &
        "   procedure Valid_Default (Item : Integer := 1);" & ASCII.LF &
        "end Profile_Default_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile),
              "parameter profiles must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Default_Expression),
              "profile defaults must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Profile_Default_Reserved_Boundary_Recovery_Boundary),
              "profile defaults at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "profile default reserved-boundary recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration_Terminator),
              "following subprogram declaration terminators must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Profile_Default_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Object_Subtype_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Subtype_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   Missing_With : with Volatile;" & ASCII.LF &
        "   Missing_Then : then;" & ASCII.LF &
        "   Valid_Following : Integer := 1;" & ASCII.LF &
        "end Object_Subtype_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "object declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary),
              "object subtype indications at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Recovery_Boundary),
              "object subtype reserved-boundary recovery must preserve object declaration recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "object subtype reserved-boundary recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Initialization_Expression),
              "valid following object initializers must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Object_Subtype_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Number_Initialization_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Number_Initialization_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   Missing_With : constant := with Volatile;" & ASCII.LF &
        "   Missing_Then : constant := then;" & ASCII.LF &
        "   Valid_Following : constant := 42;" & ASCII.LF &
        "end Number_Initialization_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Declaration),
              "number declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary),
              "number initialization expressions at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Declaration_Recovery_Boundary),
              "number initialization reserved-boundary recovery must preserve number declaration recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "number initialization reserved-boundary recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Initialization_Expression),
              "valid following number initialization expressions must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Number_Initialization_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Component_Default_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Component_Default_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   type R is record" & ASCII.LF &
        "      Missing_With : Integer := with Volatile;" & ASCII.LF &
        "      Missing_Then : Integer := then;" & ASCII.LF &
        "      Valid_Following : Integer := 42;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Component_Default_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Declaration),
              "component declarations must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Component_Default_Reserved_Boundary_Recovery_Boundary),
              "component default expressions at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "component default reserved-boundary recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Default_Expression),
              "valid following component default expressions must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Component_Default_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Discriminant_Default_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Discriminant_Default_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   type Missing_With (D : Integer := with Volatile) is null record;" & ASCII.LF &
        "   type Missing_Then (D : Integer := then) is null record;" & ASCII.LF &
        "   type Valid_Following (D : Integer := 42) is null record;" & ASCII.LF &
        "end Discriminant_Default_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification),
              "discriminant specifications must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary),
              "discriminant default expressions at reserved boundaries must expose specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Profile_Default_Reserved_Boundary_Recovery_Boundary),
              "discriminant default recovery must preserve shared profile-default boundary metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Recovery_Point),
              "discriminant default reserved-boundary recovery must preserve generic recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Default_Expression),
              "valid following discriminant default expressions must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Discriminant_Default_Reserved_Boundary_Recovery;

   procedure Test_Language_Model_Token_Cursor_Array_Index_Reserved_Boundary_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Array_Index_Reserved_Boundary_Recovery is" & ASCII.LF &
        "   type Missing_Item is array (else) of Integer;" & ASCII.LF &
        "   type Missing_Upper is array (1 .. else) of Integer;" & ASCII.LF &
        "   type Valid_Following is array (1 .. 2) of Integer;" & ASCII.LF &
        "end Array_Index_Reserved_Boundary_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Type_Definition),
              "array type definitions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Array_Index_Reserved_Boundary_Recovery_Boundary),
              "array index parts at reserved boundaries must expose array-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constraint_Recovery_Boundary),
              "array index reserved-boundary recovery must preserve generic constraint recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Upper_Bound),
              "valid following array index upper bounds must remain visible after recovery");
   end Test_Language_Model_Token_Cursor_Array_Index_Reserved_Boundary_Recovery;

   overriding function Name (T : TokenCursorReservedBoundaryRecovery_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Token-Cursor-Reserved-Boundary-Recovery-Tests");
   end Name;

   overriding procedure Register_Tests (T : in out TokenCursorReservedBoundaryRecovery_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Abort_Target_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers abort target lists at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Requeue_Target_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers requeue targets at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Delay_Expression_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers delay expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Goto_Target_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers goto targets at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Return_Expression_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers return expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Raise_Target_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers raise targets at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exit_Target_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers exit targets at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Assignment_Expression_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers assignment expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_For_Iterator_Domain_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers for and iterator domains at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Selector_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers case selectors at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Extended_Return_Initializer_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers extended return initializers at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Raise_Message_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers raise message expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exit_When_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers exit-when conditions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Null_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers null statements at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Aggregate_Component_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers aggregate component expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Object_Initialization_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers object initialization expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Range_Constraint_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers range constraints at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Digits_Delta_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers digits and delta constraints at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Index_Discriminant_Constraint_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers index and discriminant constraints at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Profile_Default_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers profile default expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Object_Subtype_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers object subtype indications at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Number_Initialization_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers number initialization expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Component_Default_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers component default expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discriminant_Default_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers discriminant default expressions at reserved boundaries");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Array_Index_Reserved_Boundary_Recovery'Access, Name => "token-cursor grammar recovers array index parts at reserved boundaries");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Reserved_Boundary_Recovery_Tests;
