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

package body Editor.Syntax_Semantics.Token_Cursor_Statement_Tests is





   procedure Test_Language_Model_Token_Cursor_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Statement_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   elsif Done then" & ASCII.LF &
        "      exit Main when Done;" & ASCII.LF &
        "   else" & ASCII.LF &
        "      goto Finished;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   case Mode is" & ASCII.LF &
        "      when 1 => delay 1.0;" & ASCII.LF &
        "      when others => raise Program_Error;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   for I in 1 .. 10 loop" & ASCII.LF &
        "      Call (I);" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   select" & ASCII.LF &
        "      accept Start do" & ASCII.LF &
        "         requeue Other;" & ASCII.LF &
        "         requeue Worker.Entry_Family (Index) with abort;" & ASCII.LF &
        "      end Start;" & ASCII.LF &
        "   or" & ASCII.LF &
        "      terminate;" & ASCII.LF &
        "   then abort" & ASCII.LF &
        "      abort Worker;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   return Result : Integer do" & ASCII.LF &
        "      Result := 0;" & ASCII.LF &
        "   end return;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Constraint_Error => null;" & ASCII.LF &
        "end Statement_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Statement_Sequence),
              "token-cursor grammar must retain handled statement sequences");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Elsif_Part),
              "token-cursor grammar must retain elsif parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Else_Part),
              "token-cursor grammar must retain else parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative),
              "token-cursor grammar must retain case alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Alternative),
              "token-cursor grammar must retain select alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Parameter_Specification),
              "token-cursor grammar must retain for-loop parameter specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Statement),
              "token-cursor grammar must retain extended return statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "token-cursor grammar must retain null statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "token-cursor grammar must retain exit statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Loop_Name),
              "token-cursor grammar must retain exit loop-name positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Statement),
              "token-cursor grammar must retain goto statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Label_Name),
              "token-cursor grammar must retain goto label-name positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement),
              "token-cursor grammar must retain delay statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Statement),
              "token-cursor grammar must retain requeue statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Entry_Name),
              "token-cursor grammar must retain requeue entry names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Entry_Index),
              "token-cursor grammar must retain requeue entry family indexes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_With_Abort),
              "token-cursor grammar must retain requeue with abort modifiers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Statement),
              "token-cursor grammar must retain abort statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_List),
              "token-cursor grammar must retain abort target lists");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_Name),
              "token-cursor grammar must retain abort target-name positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Statement),
              "token-cursor grammar must retain call actual parts as entry/call productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Target),
              "token-cursor grammar must retain call target positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_Part),
              "token-cursor grammar must retain call actual-part positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Target),
              "token-cursor grammar must retain entry-call target positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Actual_Part),
              "token-cursor grammar must retain entry-call actual-part positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler),
              "token-cursor grammar must retain exception handler sections");
   end Test_Language_Model_Token_Cursor_Statement_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Iterator_Loop_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Iterator_Loop_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   for Item of Container loop" & ASCII.LF &
        "      Use_Item (Item);" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for Element of reverse Sequence loop" & ASCII.LF &
        "      Use_Element (Element);" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for I in reverse 1 .. 10 loop" & ASCII.LF &
        "      Use_Index (I);" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Iterator_Loop_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Specification),
              "token-cursor grammar must retain Ada iterator loop specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Parameter_Specification),
              "token-cursor grammar must still retain ordinary discrete for-loop parameters");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "iterator-loop parsing must keep recovering statements inside loop bodies");
   end Test_Language_Model_Token_Cursor_Iterator_Loop_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Goto_And_Exit_Target_Grammar
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Goto_Exit_Targets is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Outer : loop" & ASCII.LF &
        "      exit Outer when Done;" & ASCII.LF &
        "      goto Finished;" & ASCII.LF &
        "   end loop Outer;" & ASCII.LF &
        "   <<Finished>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Goto_Exit_Targets;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "exit statements must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Target),
              "exit statements with loop names must retain existing target markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Loop_Name),
              "exit statements with loop names must retain explicit loop-name positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "exit statements must continue to retain when conditions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Statement),
              "goto statements must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Target),
              "goto statements must retain existing target markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Label_Name),
              "goto statements must retain explicit label-name positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Name),
              "parser recovery must keep the following explicit label structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "parser recovery must continue into the statement after the label");
   end Test_Language_Model_Token_Cursor_Goto_And_Exit_Target_Grammar;




   procedure Test_Language_Model_Token_Cursor_Delay_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Delay_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   delay 0.125;" & ASCII.LF &
        "   delay until Clock + Milliseconds (10);" & ASCII.LF &
        "   delay Duration'(0.250);" & ASCII.LF &
        "   delay until Calendar.Clock + Timeout;" & ASCII.LF &
        "   Ready := True;" & ASCII.LF &
        "end Delay_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement),
              "delay statements must be retained as statement productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Relative_Statement),
              "delay relative statements must be distinguished from delay until statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Until_Statement),
              "delay until statements must be retained with their time expression");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Relative_Expression),
              "delay relative statements must retain their relative-duration expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Until_Expression),
              "delay until statements must retain their absolute-time expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Until_Keyword),
              "standalone delay until statements must retain the until keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Selected_Time_Expression),
              "standalone delay statements must retain selected time-expression prefixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Qualified_Time_Expression),
              "standalone delay statements must retain qualified duration expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement_Terminator),
              "standalone delay statements must retain the statement terminator boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "delay expressions must retain nested qualified expressions structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "delay expressions must retain selected-name time prefixes structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "delay statement parsing must recover into following statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Expression),
              "delay relative/until statements must retain their time expressions structurally");
   end Test_Language_Model_Token_Cursor_Delay_Statement_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Extended_Return_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "function Build return Item is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   return Result : aliased constant Item := Make_Item (1) do" & ASCII.LF &
        "      Result.Touch;" & ASCII.LF &
        "   end return;" & ASCII.LF &
        "end Build;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Statement),
              "extended return statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Declaration),
              "extended return must retain the return-object declaration");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "extended return object declarations must retain aliased parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Indication),
              "extended return object declarations must retain subtype indications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Initializer),
              "extended return object declarations must retain optional initializers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Statement_Sequence),
              "extended return do parts must retain their dedicated statement sequence");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Statement_Sequence),
              "extended return do parts must retain their generic statement sequence");
   end Test_Language_Model_Token_Cursor_Extended_Return_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Return_Statement_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "function Return_Depth (Ready : Boolean) return Item is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      return;" & ASCII.LF &
        "   elsif Check then" & ASCII.LF &
        "      return Item'(Build (1));" & ASCII.LF &
        "   else" & ASCII.LF &
        "      return Result : aliased constant Item := Make_Item (1) do" & ASCII.LF &
        "         Result.Touch;" & ASCII.LF &
        "      end return;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   return Broken : Item;" & ASCII.LF &
        "   Done := True;" & ASCII.LF &
        "end Return_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Statement),
              "simple return statements must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Expression),
              "expression return statements must retain the returned expression boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Statement),
              "extended return statements must be classified separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Defining_Name),
              "extended return object defining names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Subtype_Indication),
              "extended return object subtype indications must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Initializer),
              "extended return object initializers must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Do_Keyword),
              "extended return do-parts must retain the do boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_End_Return),
              "extended return statements must retain the end return boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Recovery_Boundary),
              "malformed extended returns must expose a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "return recovery must continue into following statements");
   end Test_Language_Model_Token_Cursor_Return_Statement_Depth_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Call_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Call_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Do_Work;" & ASCII.LF &
        "   Controller.Queue (Index).Start (Arg => Value, Flag => True);" & ASCII.LF &
        "   Worker.Entry_Family (Slot) (Payload);" & ASCII.LF &
        "   Done := True;" & ASCII.LF &
        "end Call_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "call statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Target),
              "call statements must retain their target-name position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_Part),
              "call statements with actual parts must retain the actual-part position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Statement),
              "entry-call-shaped statements must remain distinguished from simple bare calls");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Target),
              "entry-call-shaped statements must retain their target-name position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Actual_Part),
              "entry-call-shaped statements must retain their actual-part position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "call targets must preserve selected-name prefixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Indexed_Component),
              "entry-call-shaped targets must preserve entry-family or indexed components");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "call statement parsing must recover into following statements");
   end Test_Language_Model_Token_Cursor_Call_Statement_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "task body Worker is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   accept Start do" & ASCII.LF &
        "      requeue Server.Queue (Index) with abort;" & ASCII.LF &
        "      requeue Pool.Current with abort;" & ASCII.LF &
        "      requeue Pool.Entries (Select_Index);" & ASCII.LF &
        "      requeue;" & ASCII.LF &
        "   end Start;" & ASCII.LF &
        "end Worker;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Statement),
              "requeue statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Target),
              "requeue statements must retain their entry-name target");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Selected_Target),
              "selected requeue targets must retain a dedicated selected-target marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "requeue targets must preserve selected-name entry prefixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Indexed_Target),
              "indexed requeue targets must retain a dedicated entry-family target marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Indexed_Component),
              "requeue targets must preserve entry-family indexes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_With_Abort),
              "requeue with abort must be distinguished from plain requeue");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Target_Recovery_Boundary),
              "malformed requeue statements must retain a bounded target recovery marker");
   end Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Abort_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   abort Worker, Pool.Tasks (Index), Controller.Current.all;" & ASCII.LF &
        "   abort;" & ASCII.LF &
        "end Abort_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Statement),
              "abort statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_List),
              "abort statements must retain the target-list position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target),
              "abort statements must retain each task-name target");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_Name),
              "abort statements must retain each task-name position distinctly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "abort targets must preserve selected task-name prefixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Indexed_Component),
              "abort targets must preserve indexed task-name components");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Explicit_Dereference),
              "abort targets must preserve explicit dereference suffixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Selected_Target),
              "abort targets must retain selected-name target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Indexed_Target),
              "abort targets must retain indexed target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Dereferenced_Target),
              "abort targets must retain explicit-dereference target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_Separator),
              "abort target lists must retain comma separators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Recovery_Boundary),
              "malformed abort statements must retain recovery boundaries");
   end Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Exception_Handler_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Handle_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Risky_Call;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Failure : Constraint_Error | Program_Error =>" & ASCII.LF &
        "      Log (Failure);" & ASCII.LF &
        "   when others =>" & ASCII.LF &
        "      raise Program_Error with ""fallback"";" & ASCII.LF &
        "end Handle_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler),
              "exception handlers must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Parameter),
              "exception handlers must retain optional choice parameters");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_List),
              "exception handlers must retain exception choice lists");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice),
              "exception handlers must retain each exception choice");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Defining_Name),
              "exception choice parameters must be retained as defining names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Statement_Sequence),
              "exception handler arrows must retain handler statement sequences distinctly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "exception handler statement sequences must parse nested raise statements structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Statement_Sequence),
              "exception handler arrows must lead into statement sequences");
   end Test_Language_Model_Token_Cursor_Exception_Handler_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Exception_Handler_Choice_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Handler_Choice_Depth is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Risky_Call;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Failure : Ada.IO_Exceptions.Name_Error | Local_Error =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   when Constraint_Error | Program_Error =>" & ASCII.LF &
        "      Recover;" & ASCII.LF &
        "   when others =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Handler_Choice_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler),
              "exception handlers must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Parameter),
              "choice parameters must remain distinct from exception choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Named_Choice),
              "named exception choices must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Selected_Choice),
              "selected exception choices must be distinguished for colouring/resolver hints");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Separator),
              "multiple exception choices must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Others_Choice),
              "others handlers must remain distinct from named choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Null_Statement),
              "null handler bodies must be retained as handler-local statement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Arrow),
              "exception choices must retain their arrow boundary");
   end Test_Language_Model_Token_Cursor_Exception_Handler_Choice_Depth;




   procedure Test_Language_Model_Token_Cursor_Raise_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Raise_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise;" & ASCII.LF &
        "   raise Constraint_Error with ""bad value"";" & ASCII.LF &
        "   raise Ada.IO_Exceptions.Name_Error with Compose_Message;" & ASCII.LF &
        "   Flag := (if Bad then raise Ada.IO_Exceptions.Use_Error with Build_Message else True);" & ASCII.LF &
        "   Flag := (if Broken then raise Constraint_Error with else False);" & ASCII.LF &
        "end Raise_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement),
              "raise statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reraise_Statement),
              "bare raise statements must be retained as re-raise grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Exception_Name),
              "raise statements must retain their exception-name position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Selected_Exception_Name),
              "raise statements must classify selected exception names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_With_Message),
              "raise statements must retain optional with-message expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_With_Message_Keyword),
              "raise statements must retain the with-message keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "raise statements must retain their message-expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression),
              "raise expressions must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression_Selected_Exception_Name),
              "raise expressions must classify selected exception names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression_Recovery_Boundary),
              "malformed raise expressions must expose bounded recovery markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Recovery_Boundary),
              "malformed raise with-message clauses must expose bounded recovery markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Name),
              "raise exception names must be parsed structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Expression),
              "raise with-message expressions must be parsed structurally");
   end Test_Language_Model_Token_Cursor_Raise_Statement_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Exit_Goto_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Exit_Goto_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Main : loop" & ASCII.LF &
        "      exit Main when Done;" & ASCII.LF &
        "      exit when Should_Stop;" & ASCII.LF &
        "      goto Finished;" & ASCII.LF &
        "   end loop Main;" & ASCII.LF &
        "   <<Finished>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Exit_Goto_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "exit statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Target),
              "exit statements must retain optional loop-name targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "exit statements must retain optional when conditions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Statement),
              "goto statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Target),
              "goto statements must retain target label names structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label),
              "label declarations must still be retained around goto targets");
   end Test_Language_Model_Token_Cursor_Exit_Goto_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Exit_Goto_Null_Delay_Statement_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Statement_Depth is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Worker : loop" & ASCII.LF &
        "      exit Worker when Done;" & ASCII.LF &
        "      exit when;" & ASCII.LF &
        "      delay until Deadline;" & ASCII.LF &
        "      delay;" & ASCII.LF &
        "      goto;" & ASCII.LF &
        "   end loop Worker;" & ASCII.LF &
        "   <<Finished>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "   Done := True;" & ASCII.LF &
        "end Statement_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "null statements must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement_Terminator),
              "null statements must retain their semicolon terminator boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Loop_Name),
              "exit statements must retain optional loop-name targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Keyword),
              "exit statements must retain the when keyword boundary separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "exit statements must retain the when-condition expression boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Recovery_Boundary),
              "malformed exit-when statements must expose bounded recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Recovery_Boundary),
              "malformed goto statements must expose bounded recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Mode_Keyword),
              "delay until statements must retain their mode keyword");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Recovery_Boundary),
              "malformed delay statements must expose bounded recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "statement recovery must continue into following statements");
   end Test_Language_Model_Token_Cursor_Exit_Goto_Null_Delay_Statement_Depth_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Null_Exclusion_Access_Grammar is" & ASCII.LF &
        "   type Object_Ptr is not null access all Integer;" & ASCII.LF &
        "   type Callback is not null access protected procedure (Value : Integer);" & ASCII.LF &
        "   Current : not null access constant Integer;" & ASCII.LF &
        "   procedure Use_Callback (Hook : not null access procedure);" & ASCII.LF &
        "end Null_Exclusion_Access_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Exclusion),
              "null exclusions must be retained before access definitions and anonymous access subtypes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Definition),
              "not-null access declarations must still parse as access type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "anonymous not-null access object declarations must remain object declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile),
              "not-null access-to-subprogram profiles must remain structurally visible");
   end Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Statement_Identifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Labelled_Statements is" & ASCII.LF &
        "   X : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Named_Loop : for I in 1 .. 3 loop" & ASCII.LF &
        "      X := X + I;" & ASCII.LF &
        "   end loop Named_Loop;" & ASCII.LF &
        "   Named_Block : declare" & ASCII.LF &
        "      Y : Integer := X;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Named_Block;" & ASCII.LF &
        "   Named_If : if X > 0 then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if Named_If;" & ASCII.LF &
        "end Labelled_Statements;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Labeled_Statement),
              "token-cursor grammar must parse Ada statement identifiers before compound statements");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Name),
              "statement identifiers must retain their explicit label-name positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Statement),
              "statement identifiers before for loops must not hide the loop grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Statement),
              "statement identifiers before declare blocks must not hide the block grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement),
              "statement identifiers before if statements must not hide the if grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "ordinary object declarations with identifier subtypes must remain declarations, not labels");
   end Test_Language_Model_Token_Cursor_Statement_Identifier_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Number_Exception_Declaration_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Number_Exception_Declarations is" & ASCII.LF &
        "   A, B : constant := 1 + 2;" & ASCII.LF &
        "   C : constant := Integer'(3);" & ASCII.LF &
        "   Failure, Retry : exception with Convention => Ada;" & ASCII.LF &
        "   Missing : exception renames Constraint_Error;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Number_Exception_Declarations;";
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
                (Editor.Ada_Token_Cursor.Production_Number_Declaration) >= 2,
              "named-number declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Number_Defining_Name_List) >= 2,
              "named-number declarations must retain defining-name-list positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Number_Initialization_Expression) >= 2,
              "named-number declarations must retain initialization expressions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Exception_Declaration) >= 2,
              "exception declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Exception_Defining_Name_List) >= 2,
              "exception declarations must retain defining-name-list positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Renaming_Declaration),
              "exception renaming declarations must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Specification),
              "exception declarations must still allow attached aspect specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following object declarations");
   end Test_Language_Model_Token_Cursor_Number_Exception_Declaration_Internal_Grammar_Completeness;


   procedure Test_Language_Model_Token_Cursor_Formal_Package_Contract_Edge_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Defaults is new Generic_Defaults (<>);" & ASCII.LF &
        "   with package Nested is new Generic_Nested" & ASCII.LF &
        "     (Factory => Builder.Instantiate" & ASCII.LF &
        "        (Item => Element," & ASCII.LF &
        "         others => <>)," & ASCII.LF &
        "      Comparator => Comparators.Make (Left => Key, Right => Value)," & ASCII.LF &
        "      others => <>);" & ASCII.LF &
        "   with package Trailing is new Generic_Trailing" & ASCII.LF &
        "     (Element_Type => Element,);" & ASCII.LF &
        "   with package Broken is new Generic_Broken" & ASCII.LF &
        "     (Factory => Make (A => B, C => D);" & ASCII.LF &
        "   type After is private;" & ASCII.LF &
        "package Formal_Package_Edges is" & ASCII.LF &
        "end Formal_Package_Edges;";
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
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration) >= 4,
              "formal package edge-case tests must retain every formal package declaration");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Box),
              "formal package (<>) defaults must remain distinct from ordinary actual associations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Association_Box) >= 2,
              "association-level => <> boxes inside formal package actuals must remain structural");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Nested_Actual_Part) >= 3,
              "nested actual/call association parts inside formal package actual expressions must be retained");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Formal_Package_Nested_Actual_Association) >= 5,
              "nested named associations must not terminate the enclosing formal package actual list");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Actual_Recovery_Boundary),
              "trailing comma and missing close-paren cases must leave an explicit recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "formal package actual recovery must resume at following generic formal declarations");
   end Test_Language_Model_Token_Cursor_Formal_Package_Contract_Edge_Cases;




   procedure Test_Language_Model_Token_Cursor_Loop_Block_Declare_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Loop_Block_Depth is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Outer : for I in 1 .. 10 when Ready (I) loop" & ASCII.LF &
        "      Inner : declare" & ASCII.LF &
        "         V : Integer := I;" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         while V > 0 loop" & ASCII.LF &
        "            V := V - 1;" & ASCII.LF &
        "         end loop;" & ASCII.LF &
        "      exception" & ASCII.LF &
        "         when others => null;" & ASCII.LF &
        "      end Inner;" & ASCII.LF &
        "   end loop Outer;" & ASCII.LF &
        "   for Element of Items when Is_Valid (Element) loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   Broken : declare" & ASCII.LF &
        "      X : Integer;" & ASCII.LF &
        "   end;" & ASCII.LF &
        "end Loop_Block_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Statement_Identifier),
              "statement identifiers before loop/block statements must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Named_Loop_Statement),
              "named loop statements must be classified separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Named_Block_Statement),
              "named block statements must be classified separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter),
              "loop iterator filters must retain a structural marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Block_Statement),
              "declare block statements must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Block_Declarative_Item),
              "declare block declarative parts must retain a bounded item marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Begin_Part),
              "block begin parts must be retained separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Exception_Part),
              "declare block exception parts must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_End_Name),
              "named end loop suffixes must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_End_Name),
              "named block end suffixes must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Recovery_Boundary),
              "unnamed end boundaries must expose bounded block/loop recovery markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "loop/block/declare recovery must continue into nested declarations");
   end Test_Language_Model_Token_Cursor_Loop_Block_Declare_Depth_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Exception_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Exception_Depth is" & ASCII.LF &
        "   Local_Error, Other_Error : exception;" & ASCII.LF &
        "   Alias_Error : exception renames Constraint_Error;" & ASCII.LF &
        "   Value : Integer := (if Failed then raise Constraint_Error with ""bad"" else 0);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise Local_Error with ""bad"";" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when E : Constraint_Error | Program_Error =>" & ASCII.LF &
        "      raise Local_Error with Exception_Message (E);" & ASCII.LF &
        "   when others =>" & ASCII.LF &
        "      raise;" & ASCII.LF &
        "   when Broken" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Exception_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Declaration),
              "exception declarations must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Renaming_Declaration),
              "exception renamings must remain structurally retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Renaming_Target),
              "renamed exception targets must be marked separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Local_Name),
              "exception choice parameters must retain their local handler name");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Separator),
              "multiple exception choices must retain choice separators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Choice_Arrow),
              "exception handler arrows must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Others_Choice),
              "others exception handlers must be classified separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement_Target),
              "raise-statement exception names must retain statement-target markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reraise_Statement),
              "bare raise statements must remain classified as re-raises");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression_Target),
              "raise-expression exception names must retain expression-target markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Expression_Message),
              "raise-expression message payloads must retain expression-message markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Recovery_Boundary),
              "malformed exception handlers must expose bounded recovery markers");
   end Test_Language_Model_Token_Cursor_Exception_Depth_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Loop_Iteration_Scheme_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Loop_Iteration_Depth is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "      Values : Integer := 0;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      while Values < 10 loop" & ASCII.LF &
        "         Values := Values + 1;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      for I in reverse 1 .. 10 loop" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      for Item of reverse Items when Item.Ready loop" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      After : declare" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end After;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Loop_Iteration_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Keyword),
              "while loops must retain their iteration-scheme keyword");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Condition),
              "while loops must retain their condition expression boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Scheme),
              "discrete for loops must retain an iteration-scheme marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Reverse_Iteration),
              "discrete for loops must retain reverse iteration metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Range_Iteration),
              "discrete for loops must retain range iteration metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Iteration_Scheme),
              "iterator loops must retain an iterator iteration-scheme marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Reverse_Iteration),
              "iterator loops must retain reverse iteration metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter),
              "Ada 2012/2022 iterator filters must retain the when marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter_Condition),
              "iterator filters must retain their filter condition boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Begin_Keyword),
              "all loop forms must retain the loop begin keyword boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Named_Block_Statement),
              "parser recovery must continue into following named blocks after loop schemes");
   end Test_Language_Model_Token_Cursor_Loop_Iteration_Scheme_Metadata;




   procedure Test_Language_Model_Token_Cursor_Case_Statement_Alternative_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Case_Statement_Depth is" & ASCII.LF &
        "   procedure Run (Value : Integer) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      case Value is" & ASCII.LF &
        "         when 1 | 2 .. 4 =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "         when others =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "      After : declare" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end After;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Case_Statement_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement_Is_Keyword),
              "case statements must retain the is keyword boundary explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Choice),
              "case alternatives must retain individual non-others choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Range_Choice),
              "case alternatives must retain discrete range choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Choice_Separator),
              "case alternatives must retain choice separators");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Others_Choice),
              "case alternatives must retain others choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative_Null_Statement),
              "case alternatives ending in null statements must retain a bounded statement marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Named_Block_Statement),
              "parser recovery must continue into following named blocks after case alternatives");
   end Test_Language_Model_Token_Cursor_Case_Statement_Alternative_Depth;



   procedure Test_Language_Model_Token_Cursor_Subtype_Mark_Selected_Selector_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Subtype_Mark_Selected_Selectors is" & ASCII.LF &
        "   subtype Positive_Count is Numeric.Count range 1 .. 10;" & ASCII.LF &
        "   subtype Class_View is Model.Root'Class;" & ASCII.LF &
        "   D : Count := Operator_Types.""+""'(5);" & ASCII.LF &
        "   subtype Character_View is Character_Types.'A';" & ASCII.LF &
        "   Next : Positive_Count;" & ASCII.LF &
        "end Subtype_Mark_Selected_Selectors;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "subtype declarations must remain visible after selected subtype-mark parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Indication),
              "selected subtype marks must remain subtype indications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "selected subtype marks must retain selected-name grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "operator-symbol selectors in selected subtype marks must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Character_Selector),
              "character-literal selectors in selected subtype marks must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "selected subtype marks must still leave following constraints for subtype-indication parsing");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following object declarations");
   end Test_Language_Model_Token_Cursor_Subtype_Mark_Selected_Selector_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Parallel_Loop_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Parallel_Loops is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   parallel (4) for I in 1 .. 10 loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   parallel for Item of Items when Ready (Item) loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Parallel_Loops;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Loop_Statement),
              "parallel loop statements must retain parallel-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Loop_Keyword),
              "parallel loop keyword must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Loop_Chunk_Specification),
              "parallel loop chunk specifications must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Loop_Chunk_Expression),
              "parallel loop chunk expressions must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parallel_Loop_Iteration_Scheme),
              "parallel loops must retain the nested iteration scheme start");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Scheme),
              "parallel discrete loops must still retain ordinary for-loop metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Iteration_Scheme),
              "parallel iterator loops must still retain iterator-loop metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Iterator_Filter),
              "parallel iterator loops must preserve iterator filters");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Begin_Keyword),
              "parallel loops must still expose loop begin metadata");
   end Test_Language_Model_Token_Cursor_Parallel_Loop_Depth;





   procedure Test_Language_Model_Token_Cursor_Label_Goto_Metadata_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Label_Goto_Metadata is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   <<Ready>>" & ASCII.LF &
        "   goto Ready;" & ASCII.LF &
        "   goto Worker.Done;" & ASCII.LF &
        "   <<>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Label_Goto_Metadata;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Executable_Binding_Kind;
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Label : Boolean := False;
      Seen_Goto  : Boolean := False;
      Seen_Missing_Selected_Goto : Boolean := False;
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Open_Delimiter),
              "label declarations must retain the opening delimiter separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Close_Delimiter),
              "label declarations must retain the closing delimiter separately");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Label_Recovery_Boundary),
              "malformed labels must retain a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Terminator),
              "goto statements must retain their statement terminator boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Label_Recovery_Boundary),
              "goto statements with non-label-name tails must retain recovery metadata");

      for I in 1 .. Editor.Ada_Language_Model.Executable_Binding_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Executable_Binding_Info :=
              Editor.Ada_Language_Model.Executable_Binding_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Binding_Label_Declaration
              and then Ada.Strings.Unbounded.To_String (Info.Name) = "Ready"
            then
               Seen_Label := True;
            elsif Info.Kind = Editor.Ada_Language_Model.Binding_Goto_Target
              and then Ada.Strings.Unbounded.To_String (Info.Name) = "Ready"
            then
               Seen_Goto := True;
            end if;
         end;
      end loop;

      Assert (Seen_Label,
              "language model must retain label declaration metadata for navigation");
      Assert (Seen_Goto,
              "language model must retain goto label-reference metadata for navigation");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Goto_Missing_Target
              and then Ada.Strings.Unbounded.To_String (Info.Message)'Length > 0
            then
               Seen_Missing_Selected_Goto := True;
            end if;
         end;
      end loop;

      Assert (Seen_Missing_Selected_Goto,
              "conservative same-scope goto diagnostics must remain available for missing labels");
   end Test_Language_Model_Token_Cursor_Label_Goto_Metadata_Depth;





   procedure Test_Language_Model_Token_Cursor_Selected_Literal_Selector_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ops;" & ASCII.LF &
        "package body Selected_Literal_Selectors is" & ASCII.LF &
        "   Value : Integer := Ops.Math.""+"" (1, 2);" & ASCII.LF &
        "   Ch    : Character := Ops.Symbols.'A';" & ASCII.LF &
        "   for Ops.Math.""+""'Address use System'To_Address (16#1000#);" & ASCII.LF &
        "end Selected_Literal_Selectors;";
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
                (Editor.Ada_Token_Cursor.Production_Selected_Name) >= 5,
              "selected names with literal selectors must retain selected-name structure");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Selected_Selector) >= 3,
              "ordinary selected-name selectors must remain structural");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector) >= 2,
              "operator-symbol selectors must not be flattened into expression string literals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Character_Selector),
              "character-literal selectors must be retained for selected enumeration literals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Target),
              "representation targets must retain selected operator-symbol names before attribute designators");
   end Test_Language_Model_Token_Cursor_Selected_Literal_Selector_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Case_Statement_Choice_Depth is" & ASCII.LF &
        "   procedure Run (Kind : Integer) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when 1 | 2 =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "         when 3 .. 5 =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "         when others =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when 6 | 7" & ASCII.LF &
        "            null;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "      After : declare" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end After;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Case_Statement_Choice_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Case_Choice_List) >= 4,
              "case statement alternatives must retain explicit case choice-list markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Others_Choice),
              "case statement others choices must be classified separately from exception others choices");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Case_Choice_Separator) >= 2,
              "case statement choice separators must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Case_Choice_Arrow) >= 3,
              "case statement choice arrows must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative_Recovery_Boundary),
              "malformed case alternatives must expose bounded recovery boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Declare_Block_Statement),
              "case alternative recovery must continue into following statements");
   end Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness;








   procedure Test_Language_Model_Token_Cursor_If_Statement_Branch_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body If_Statement_Branches is" & ASCII.LF &
        "   procedure Run (A, B, C : Boolean) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if A and then B then" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      elsif B or else C then" & ASCII.LF &
        "         raise Program_Error with ""bad branch"";" & ASCII.LF &
        "      elsif C then" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "      if A" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end If_Statement_Branches;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement),
              "if statements must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Condition),
              "if statement conditions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Then_Keyword),
              "if statement then keywords must be retained as branch boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Then_Statements),
              "if statement then statement sequences must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Elsif_Statement_Branch) >= 2,
              "elsif branches must be retained separately from the initial if branch");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Elsif_Statement_Condition) >= 2,
              "elsif statement conditions must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Elsif_Statement_Then_Keyword) >= 2,
              "elsif then keywords must be retained as branch boundaries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Elsif_Statement_Then_Statements) >= 2,
              "elsif statement then sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Else_Branch),
              "else branches must be retained separately from select else alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Else_Statement_Sequence),
              "else statement sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_End_Keyword),
              "end if must no longer be flattened into a generic block end marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement_Recovery_Boundary),
              "malformed if statements must expose a bounded recovery boundary");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "raise statements with messages inside branches must continue to parse structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Null_Statement) >= 4,
              "if statement branch parsing must recover into following statements");
   end Test_Language_Model_Token_Cursor_If_Statement_Branch_Grammar_Completeness;







   procedure Test_Language_Model_Token_Cursor_Case_Statement_Branch_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Case_Statement_Branches is" & ASCII.LF &
        "   Mode  : Integer := 0;" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Mode + 1 is" & ASCII.LF &
        "      when 1 | 2 =>" & ASCII.LF &
        "         Value := (if Value = 0 then 10 else Value);" & ASCII.LF &
        "      when 3 .. 5 =>" & ASCII.LF &
        "         raise Program_Error with ""bad mode"";" & ASCII.LF &
        "      when others =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   Value := Value + 1;" & ASCII.LF &
        "end Case_Statement_Branches;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement),
              "case statements must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement_Selector),
              "case-statement selectors must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Case_Alternative) >= 3,
              "case-statement alternatives must continue to be retained");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Case_Alternative_Statement_Sequence) >= 3,
              "each case alternative must retain its statement-sequence position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "case alternatives must keep discrete choice lists before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression),
              "case alternative statement sequences must parse nested expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement),
              "case alternative statement sequences must parse nested raise statements");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Assignment_Statement) >= 2,
              "case-statement parsing must recover into following statements");
   end Test_Language_Model_Token_Cursor_Case_Statement_Branch_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Loop_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Loop_Statement_Structure is" & ASCII.LF &
        "   procedure Run (Items : Item_Array; Ready : Boolean) is" & ASCII.LF &
        "      Sum : Integer := 0;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      for I in reverse 1 .. 4 loop" & ASCII.LF &
        "         Sum := Sum + I;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      for Element of reverse Items loop" & ASCII.LF &
        "         Sum := Sum + Element.Value;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      while Ready and then Sum < 10 loop" & ASCII.LF &
        "         exit when Sum = 9;" & ASCII.LF &
        "      end loop;" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Loop_Statement_Structure;";
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
                (Editor.Ada_Token_Cursor.Production_Loop_Statement) >= 3,
              "for iterator and while loops must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Scheme),
              "for-loop iteration schemes must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Parameter),
              "for-loop parameter names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_For_Loop_Iteration_Domain),
              "for-loop discrete domains must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Iteration_Scheme),
              "iterator-loop iteration schemes must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Element),
              "iterator-loop element names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Loop_Domain),
              "iterator-loop iterable domains must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_While_Loop_Condition),
              "while-loop conditions must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Loop_Statement_Sequence) >= 3,
              "each loop form must retain its statement-sequence position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "loop parsing must recover into nested exit-when statements");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Null_Statement) >= 1,
              "loop parsing must recover into following statements");
   end Test_Language_Model_Token_Cursor_Loop_Statement_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Block_Statement_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Block_Statement_Structure is" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Named_Block : declare" & ASCII.LF &
        "      Local : Integer := Value + 1;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Value := Local;" & ASCII.LF &
        "   exception" & ASCII.LF &
        "      when Constraint_Error =>" & ASCII.LF &
        "         raise Program_Error with ""bad block"";" & ASCII.LF &
        "   end Named_Block;" & ASCII.LF &
        "   Value := Value + 1;" & ASCII.LF &
        "end Block_Statement_Structure;";
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
                (Editor.Ada_Token_Cursor.Production_Block_Statement) >= 2,
              "procedure bodies and nested block statements must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Label_Name),
              "named block labels must be retained separately from generic labels");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Declare_Keyword),
              "declare-block declare keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Declarative_Part),
              "block declarative parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Declarative_Item_Start),
              "block declarative-item starts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Declarative_Begin_Boundary),
              "block declarative begin boundaries must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Statement_Sequence),
              "block handled statement sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Exception_Keyword),
              "block exception keywords must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Exception_Part),
              "block exception parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler),
              "block exception handlers must continue to parse structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Handler_Statement_Sequence),
              "block exception handler statement sequences must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "block exception statements must parse nested raise messages structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Assignment_Statement) >= 2,
              "block parsing must recover into following statements");
   end Test_Language_Model_Token_Cursor_Block_Statement_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Extended_Return_Object_Qualifier_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Return_Object_Qualifiers is" & ASCII.LF &
        "   function Make return access Integer is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Result : aliased constant not null access Integer := null do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end return;" & ASCII.LF &
        "   end Make;" & ASCII.LF &
        "   function Slice return String is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return Text : String (1 .. 4) := ""test"" do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end return;" & ASCII.LF &
        "   end Slice;" & ASCII.LF &
        "end Return_Object_Qualifiers;";
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
                (Editor.Ada_Token_Cursor.Production_Extended_Return_Statement) >= 2,
              "extended return statements must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Aliased_Qualifier),
              "extended return object aliased qualifier must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Constant_Qualifier),
              "extended return object constant qualifier must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Access_Definition),
              "extended return object access definitions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Null_Exclusion),
              "extended return object null exclusions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Object_Constraint),
              "extended return object constrained subtype indications must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Return_Object_Initializer) >= 2,
              "extended return object initializers must remain structural after qualifier parsing");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Extended_Return_End_Return) >= 2,
              "extended return do-parts must still synchronize to end return");
   end Test_Language_Model_Token_Cursor_Extended_Return_Object_Qualifier_Depth;


   overriding function Name (T : Token_Cursor_Statement_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Statement");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Statement_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses complete Ada statement productions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Iterator_Loop_Grammar_Completeness'Access, Name => "token-cursor grammar parses Ada iterator loop productions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Goto_And_Exit_Target_Grammar'Access, Name => "token-cursor grammar parses goto label names and exit loop names structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Delay_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses delay relative and delay until statements structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Extended_Return_Grammar_Completeness'Access, Name => "token-cursor grammar parses extended return object declarations structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Return_Statement_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses return statement families deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Call_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses call and entry-call target actual parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness'Access, Name => "token-cursor grammar parses requeue targets and with-abort structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses abort task-name lists structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exception_Handler_Grammar_Completeness'Access, Name => "token-cursor grammar parses exception choice parameters and choices structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exception_Handler_Choice_Depth'Access, Name => "token-cursor grammar deepens exception handler choices structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Raise_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses raise and bare re-raise statements structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exit_Goto_Grammar_Completeness'Access, Name => "token-cursor grammar parses exit targets conditions and goto targets structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exit_Goto_Null_Delay_Statement_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses exit goto null and delay statement refinements");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness'Access, Name => "token-cursor grammar parses null-exclusion access definitions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Statement_Identifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses labelled compound statements without misclassifying object declarations");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Number_Exception_Declaration_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains number and exception declaration internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Formal_Package_Contract_Edge_Cases'Access, Name => "token-cursor grammar retains formal package contract edge cases");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Loop_Block_Declare_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens loop block and declare statement structure");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exception_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens exception declarations handlers and raise forms");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Loop_Iteration_Scheme_Metadata'Access, Name => "token-cursor grammar deepens loop iteration scheme metadata structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Statement_Alternative_Depth'Access, Name => "token-cursor grammar deepens case statement alternatives structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subtype_Mark_Selected_Selector_Grammar_Completeness'Access, Name => "token-cursor grammar parses selected subtype-mark selectors structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Parallel_Loop_Depth'Access, Name => "token-cursor grammar classifies parallel loop statements structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Label_Goto_Metadata_Depth'Access, Name => "token-cursor grammar deepens label and goto metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Selected_Literal_Selector_Grammar_Completeness'Access, Name => "token-cursor grammar parses selected names with operator and character literal selectors");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens case statement choices arrows and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_If_Statement_Branch_Grammar_Completeness'Access, Name => "token-cursor grammar parses if-statement branch structure explicitly");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_Statement_Branch_Grammar_Completeness'Access, Name => "token-cursor grammar parses case-statement selectors and alternative statements structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Loop_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses loop iteration schemes and loop statement sequences structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Block_Statement_Grammar_Completeness'Access, Name => "token-cursor grammar parses block declarative handled and exception parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Extended_Return_Object_Qualifier_Depth'Access, Name => "token-cursor grammar deepens extended return object qualifiers and constraints");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Statement_Tests;
