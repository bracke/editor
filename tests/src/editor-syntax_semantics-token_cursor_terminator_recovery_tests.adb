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

package body Editor.Syntax_Semantics.Token_Cursor_Terminator_Recovery_Tests is






   procedure Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Case_856
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "function Return_Terminator_Recovery (Ready : Boolean) return Integer is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      return 1" & ASCII.LF &
        "   else" & ASCII.LF &
        "      return 2;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Return_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Statement),
              "return statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Expression),
              "return expressions must remain structurally visible before recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Missing_Terminator_Recovery_Boundary),
              "return statements missing a semicolon must retain return-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Terminator),
              "well-formed return statements must retain return terminator metadata");
   end Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Case_856;




   procedure Test_Language_Model_Token_Cursor_Accept_End_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Accept_End_Recovery is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Start (Value : Integer) do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Start;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         accept Stop do" & ASCII.LF &
        "            null;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         terminate;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      After : Integer;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Accept_End_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Do_Part),
              "accept statements with do-parts must retain explicit do-part metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_End_Keyword),
              "accept do-parts must retain accept-specific end keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_End_Name),
              "named accept ends must retain the accept end name structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Terminator),
              "accept endings must retain an accept-specific terminator marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Missing_End_Recovery_Boundary),
              "accept do-parts missing an end must retain accept-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "accept end recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Accept_End_Recovery;




   procedure Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Abort_Recovery is" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      abort Server.Task_One, Server.Task_Two;" & ASCII.LF &
        "      abort Broken" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Abort_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Statement),
              "abort statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_List),
              "abort statements must retain target-list metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Selected_Target),
              "abort selected task targets must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Target_Separator),
              "abort target separators must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Terminator),
              "well-formed abort statements must retain an abort-specific terminator marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abort_Missing_Terminator_Recovery_Boundary),
              "abort statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Delay_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   delay until Clock.Now;" & ASCII.LF &
        "   delay 1.0" & ASCII.LF &
        "end Delay_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement),
              "delay statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Until_Statement),
              "delay until statements must retain mode-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Relative_Statement),
              "relative delay statements must retain mode-specific metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Statement_Terminator),
              "well-formed delay statements must retain delay-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delay_Missing_Terminator_Recovery_Boundary),
              "delay statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery;





   procedure Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Case_794
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "function Return_Terminator_Recovery (Ready : Boolean) return Item is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      return Item'(Build (1));" & ASCII.LF &
        "   else" & ASCII.LF &
        "      return Result : Item := Build (2) do" & ASCII.LF &
        "         Result.Touch;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Return_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Statement),
              "return statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Expression),
              "simple return statements must retain expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Return_Terminator),
              "well-formed return statements must retain return-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Statement),
              "extended return statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Do_Keyword),
              "extended return do parts must retain do metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Extended_Return_Missing_End_Recovery_Boundary),
              "extended returns missing end return must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Case_794;




   procedure Test_Language_Model_Token_Cursor_Raise_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Raise_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise;" & ASCII.LF &
        "   raise Constraint_Error with ""bad"";" & ASCII.LF &
        "   raise Program_Error" & ASCII.LF &
        "end Raise_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Statement),
              "raise statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reraise_Statement),
              "bare raise statements must retain reraise metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_With_Message),
              "raise statements with messages must retain message metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Terminator),
              "well-formed raise statements must retain raise-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Missing_Terminator_Recovery_Boundary),
              "raise statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Raise_Terminator_Recovery;






   procedure Test_Language_Model_Token_Cursor_Exit_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Exit_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Outer : loop" & ASCII.LF &
        "      exit Outer when Ready;" & ASCII.LF &
        "      exit Outer when Done" & ASCII.LF &
        "   end loop Outer;" & ASCII.LF &
        "end Exit_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Statement),
              "exit statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Target),
              "exit statements with loop names must retain target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_When_Condition),
              "exit statements with when clauses must retain condition metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Terminator),
              "well-formed exit statements must retain exit-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exit_Missing_Terminator_Recovery_Boundary),
              "exit statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Exit_Terminator_Recovery;






   procedure Test_Language_Model_Token_Cursor_Goto_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Goto_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   <<Ready>>" & ASCII.LF &
        "   goto Ready;" & ASCII.LF &
        "   goto Missing" & ASCII.LF &
        "end Goto_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Statement),
              "goto statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Target),
              "goto statements with labels must retain target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Label_Name),
              "goto statements must retain label-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Terminator),
              "well-formed goto statements must retain goto-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Goto_Missing_Terminator_Recovery_Boundary),
              "goto statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Goto_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Null_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Null_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "   null" & ASCII.LF &
        "end Null_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement),
              "null statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Statement_Terminator),
              "well-formed null statements must retain null-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Missing_Terminator_Recovery_Boundary),
              "null statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Null_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Assignment_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Assignment_Terminator_Recovery is" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Value := Value + 1;" & ASCII.LF &
        "   Value := Value + 2" & ASCII.LF &
        "end Assignment_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Statement),
              "assignment statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Target),
              "assignment statements must retain target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Expression),
              "assignment statements must retain expression metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Terminator),
              "well-formed assignment statements must retain assignment-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Missing_Terminator_Recovery_Boundary),
              "assignment statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Assignment_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Call_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Call_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Run (1);" & ASCII.LF &
        "   Worker.Start (2)" & ASCII.LF &
        "end Call_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "call statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Target),
              "call statements must retain target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_Part),
              "calls with actuals must retain call actual-part metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Terminator),
              "well-formed call statements must retain call-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Missing_Terminator_Recovery_Boundary),
              "call statements missing a semicolon must retain recovery metadata");
   end Test_Language_Model_Token_Cursor_Call_Terminator_Recovery;






   procedure Test_Language_Model_Token_Cursor_Compound_End_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Compound_End_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   declare" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end;" & ASCII.LF &
        "   if Broken then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if" & ASCII.LF &
        "   loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop" & ASCII.LF &
        "   declare" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end" & ASCII.LF &
        "end Compound_End_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_End_Terminator),
              "well-formed end if statements must retain if-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Missing_End_Terminator_Recovery_Boundary),
              "end if statements missing a semicolon must retain if-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_End_Terminator),
              "well-formed end loop statements must retain loop-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Loop_Missing_End_Terminator_Recovery_Boundary),
              "end loop statements missing a semicolon must retain loop-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_End_Terminator),
              "well-formed block ends must retain block-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Block_Missing_End_Terminator_Recovery_Boundary),
              "block ends missing a semicolon must retain block-specific recovery metadata");
   end Test_Language_Model_Token_Cursor_Compound_End_Terminator_Recovery;





   procedure Test_Language_Model_Token_Cursor_Case_End_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Case_End_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Mode is" & ASCII.LF &
        "      when Ready =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      when others =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   case Broken is" & ASCII.LF &
        "      when others =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end case" & ASCII.LF &
        "end Case_End_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement),
              "case statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Statement_End_Keyword),
              "end case statements must retain case-specific end metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_End_Terminator),
              "well-formed end case statements must retain case-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Missing_End_Terminator_Recovery_Boundary),
              "end case statements missing a semicolon must retain case-specific recovery metadata");
   end Test_Language_Model_Token_Cursor_Case_End_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Select_End_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Select_End_Terminator_Recovery is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   select" & ASCII.LF &
        "      accept Start;" & ASCII.LF &
        "   or" & ASCII.LF &
        "      delay 1.0;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   select" & ASCII.LF &
        "      terminate;" & ASCII.LF &
        "   end select" & ASCII.LF &
        "end Select_End_Terminator_Recovery;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Statement),
              "select statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Statement_End_Keyword),
              "end select statements must retain select-specific end metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_End_Terminator),
              "well-formed end select statements must retain select-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Select_Missing_End_Terminator_Recovery_Boundary),
              "end select statements missing a semicolon must retain select-specific recovery metadata");
   end Test_Language_Model_Token_Cursor_Select_End_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Body_End_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Package_Source : constant String :=
        "package body Body_End_Terminator is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Body_End_Terminator;" & ASCII.LF &
        "package body Body_End_Missing is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Body_End_Missing";
      Subprogram_Source : constant String :=
        "procedure Body_End_Subprogram is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Body_End_Subprogram;" & ASCII.LF &
        "procedure Body_End_Subprogram_Missing is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Body_End_Subprogram_Missing";
      Package_Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Package_Source);
      Subprogram_Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Subprogram_Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Package_Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_End_Keyword),
              "package bodies must retain end-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Package_Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_End_Name),
              "package bodies must retain optional end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Package_Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_End_Terminator),
              "package bodies must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Package_Grammar, Editor.Ada_Token_Cursor.Production_Package_Body_Missing_End_Terminator_Recovery_Boundary),
              "package bodies missing end semicolons must retain family-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subprogram_Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_End_Keyword),
              "subprogram bodies must retain end-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subprogram_Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_End_Name),
              "subprogram bodies must retain optional end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subprogram_Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_End_Terminator),
              "subprogram bodies must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subprogram_Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary),
              "subprogram bodies missing end semicolons must retain family-specific recovery metadata");
   end Test_Language_Model_Token_Cursor_Body_End_Terminator_Recovery;




   procedure Test_Language_Model_Token_Cursor_Concurrent_Body_End_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Task_Source : constant String :=
        "task body Worker is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Worker;" & ASCII.LF &
        "task body Worker_Missing is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Worker_Missing";
      Protected_Source : constant String :=
        "protected body Gate is" & ASCII.LF &
        "   procedure Open is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Open;" & ASCII.LF &
        "end Gate;" & ASCII.LF &
        "protected body Gate_Missing is" & ASCII.LF &
        "end Gate_Missing";
      Task_Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Task_Source);
      Protected_Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Protected_Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Task_Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_End_Keyword),
              "task bodies must retain end-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Task_Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_End_Name),
              "task bodies must retain optional end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Task_Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_End_Terminator),
              "task bodies must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Task_Grammar, Editor.Ada_Token_Cursor.Production_Task_Body_Missing_End_Terminator_Recovery_Boundary),
              "task bodies missing end semicolons must retain family-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Protected_Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_End_Keyword),
              "protected bodies must retain end-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Protected_Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_End_Name),
              "protected bodies must retain optional end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Protected_Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_End_Terminator),
              "protected bodies must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Protected_Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Missing_End_Terminator_Recovery_Boundary),
              "protected bodies missing end semicolons must retain family-specific recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Protected_Grammar, Editor.Ada_Token_Cursor.Production_Protected_Body_Operation_End_Keyword),
              "protected operation body end metadata must remain present");
   end Test_Language_Model_Token_Cursor_Concurrent_Body_End_Terminator_Recovery;





   procedure Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected Gate is" & ASCII.LF &
        "   entry Start (Value : Integer) with Pre => Value > 0;" & ASCII.LF &
        "   entry Missing (Value : Integer)" & ASCII.LF &
        "private" & ASCII.LF &
        "   Ready : Boolean := False;" & ASCII.LF &
        "end Gate;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Declaration),
              "entry declarations must remain recognized inside protected definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Parameter_Profile),
              "entry declaration parameter profiles must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Aspect_Specification),
              "entry declaration aspect placement must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Terminator),
              "well-formed entry declarations must retain entry-specific terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Missing_Terminator_Recovery_Boundary),
              "entry declarations missing semicolons must retain entry-specific recovery metadata");
   end Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery;





   procedure Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Gate is" & ASCII.LF &
        "   entry Start (Value : Integer) when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Start;" & ASCII.LF &
        "   entry Missing when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Gate;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body),
              "entry bodies must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Begin_Keyword),
              "entry bodies must retain begin-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_End_Keyword),
              "entry bodies must retain end-keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_End_Name),
              "entry bodies must retain optional end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_End_Terminator),
              "entry bodies must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary),
              "entry bodies missing end terminators must retain family-specific recovery metadata");
   end Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery;






   procedure Test_Language_Model_Token_Cursor_Subprogram_Declaration_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Subprogram_Terminator_Depth is" & ASCII.LF &
        "   procedure Run (Value : Integer) with Inline;" & ASCII.LF &
        "   function Build return Integer;" & ASCII.LF &
        "   procedure Broken (Value : Integer)";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration),
              "subprogram declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Defining_Designator),
              "subprogram defining designators must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Specification),
              "subprogram declarations with trailing aspects must retain aspect metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration_Terminator),
              "well-formed subprogram declarations must retain declaration terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Declaration_Missing_Terminator_Recovery_Boundary),
              "subprogram declarations missing semicolons must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_Subprogram_Declaration_Terminator;






   procedure Test_Language_Model_Token_Cursor_Object_Declaration_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Terminator_Depth is" & ASCII.LF &
        "   Value : Integer := 1;" & ASCII.LF &
        "   Shared : aliased constant Integer with Volatile;" & ASCII.LF &
        "   Broken : Integer";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "object declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Defining_Name),
              "object defining names must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Initialization_Expression),
              "object initialization expressions must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Specification),
              "object declarations with trailing aspects must retain aspect metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Terminator),
              "well-formed object declarations must retain declaration terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration_Missing_Terminator_Recovery_Boundary),
              "object declarations missing semicolons must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_Object_Declaration_Terminator;





   procedure Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Type_Source : constant String :=
        "package Type_Terminator_Depth is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   type Handle is private with Preelaborable_Initialization;" & ASCII.LF &
        "   type Forward;" & ASCII.LF &
        "   type Broken is range 1 .. 10";
      Subtype_Source : constant String :=
        "package Subtype_Terminator_Depth is" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 10;" & ASCII.LF &
        "   subtype Also_Broken is Integer range 1 .. 3";
      Type_Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Type_Source);
      Subtype_Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Subtype_Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Type_Grammar, Editor.Ada_Token_Cursor.Production_Type_Declaration),
              "type declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Type_Grammar, Editor.Ada_Token_Cursor.Production_Incomplete_Type_Declaration),
              "incomplete type declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subtype_Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "subtype declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Type_Grammar, Editor.Ada_Token_Cursor.Production_Type_Declaration_Terminator),
              "well-formed type declarations must retain declaration terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Type_Grammar, Editor.Ada_Token_Cursor.Production_Type_Declaration_Missing_Terminator_Recovery_Boundary),
              "type declarations missing semicolons must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subtype_Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration_Terminator),
              "well-formed subtype declarations must retain declaration terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Subtype_Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary),
              "subtype declarations missing semicolons must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator;






   procedure Test_Language_Model_Token_Cursor_Exception_Declaration_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Exception_Declaration_Terminator_Depth is" & ASCII.LF &
        "   First, Second : exception;" & ASCII.LF &
        "   Third : exception with Convention => Ada;" & ASCII.LF &
        "   Broken : exception" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Exception_Declaration_Terminator_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Declaration),
              "exception declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Defining_Name_List),
              "exception declarations must retain defining-name-list metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Declaration_Terminator),
              "well-formed exception declarations must retain declaration terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Exception_Declaration_Missing_Terminator_Recovery_Boundary),
              "exception declarations missing semicolons must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Specification),
              "exception declarations must still allow attached aspect specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "exception declaration recovery must leave following object declarations visible");
   end Test_Language_Model_Token_Cursor_Exception_Declaration_Terminator;





   procedure Test_Language_Model_Token_Cursor_Number_Declaration_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Number_Declaration_Terminator_Depth is" & ASCII.LF &
        "   Limit, Default_Limit : constant := 10;" & ASCII.LF &
        "   Broken_Value : constant := ;" & ASCII.LF &
        "   Broken_Terminator : constant := 42" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Number_Declaration_Terminator_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Declaration),
              "number declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Declaration_Terminator),
              "well-formed number declarations must retain declaration terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Declaration_Missing_Terminator_Recovery_Boundary),
              "number declarations missing semicolons must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Number_Declaration_Recovery_Boundary),
              "malformed number declarations must retain initializer recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "number declaration terminator recovery must leave following object declarations visible");
   end Test_Language_Model_Token_Cursor_Number_Declaration_Terminator;





   procedure Test_Language_Model_Token_Cursor_Generic_Formal_Declaration_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with Limit : Integer := 1;" & ASCII.LF &
        "   type Item is private with Preelaborable_Initialization;" & ASCII.LF &
        "   with procedure Do_It (X : Item) is <>;" & ASCII.LF &
        "   with package Nested is new Generic_Package (<>);" & ASCII.LF &
        "   type Broken is private" & ASCII.LF &
        "package Generic_Formal_Terminator_Depth is" & ASCII.LF &
        "end Generic_Formal_Terminator_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Declaration),
              "generic formal declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Object_Declaration),
              "formal object declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Type_Declaration),
              "formal type declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Subprogram_Declaration),
              "formal subprogram declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Package_Declaration),
              "formal package declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Declaration_Terminator),
              "well-formed generic formal declarations must retain terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Declaration_Missing_Terminator_Recovery_Boundary),
              "generic formal declarations missing semicolons must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Aspect_Specification),
              "generic formal declarations must retain formal-aspect placement metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration),
              "generic formal recovery must leave the following package declaration visible");
   end Test_Language_Model_Token_Cursor_Generic_Formal_Declaration_Terminator;




   procedure Test_Language_Model_Token_Cursor_Package_Declaration_End_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Package_End_Terminator_Depth is" & ASCII.LF &
        "   Value : Integer := 1;" & ASCII.LF &
        "end Package_End_Terminator_Depth;" & ASCII.LF &
        "package Package_End_Terminator_Broken is" & ASCII.LF &
        "end Package_End_Terminator_Broken";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration),
              "package declarations must remain recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Visible_Part),
              "package visible parts must remain retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration_End_Keyword),
              "package declarations must retain end keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration_End_Name),
              "package declarations must retain optional end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration_End_Terminator),
              "well-formed package declarations must retain end terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration_Missing_End_Terminator_Recovery_Boundary),
              "package declarations missing end semicolons must retain bounded recovery metadata");
   end Test_Language_Model_Token_Cursor_Package_Declaration_End_Terminator;





   procedure Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Requeue_Terminator_Detail is" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      entry Step;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Step do" & ASCII.LF &
        "         requeue Step with abort;" & ASCII.LF &
        "         requeue Step with abort" & ASCII.LF &
        "      end Step;" & ASCII.LF &
        "      After_Call;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Requeue_Terminator_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Statement),
              "requeue statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Target),
              "requeue statements must retain target metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_With_Abort),
              "requeue with-abort clauses must remain visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Terminator),
              "well-formed requeue statements must retain terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Requeue_Missing_Terminator_Recovery_Boundary),
              "requeue statements with missing terminators must retain bounded terminator recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_End_Keyword),
              "requeue terminator recovery must not consume the enclosing accept end");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "requeue terminator recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery;





   procedure Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Accept_Terminator_Detail is" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      entry Step;" & ASCII.LF &
        "      entry Broken;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task body Worker is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      accept Step do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Step;" & ASCII.LF &
        "      accept Broken do" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Broken" & ASCII.LF &
        "      After_Call;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Accept_Terminator_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Statement),
              "accept statements must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_End_Keyword),
              "accept statement do-parts must retain end keyword metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_End_Name),
              "accept statement do-parts must retain end-name metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Terminator),
              "well-formed accept statements must retain terminator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Accept_Missing_Terminator_Recovery_Boundary),
              "accept statements with missing terminators must retain bounded terminator recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "accept terminator recovery must leave following statements visible");
   end Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery;


   overriding function Name (T : Token_Cursor_Terminator_Recovery_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Terminator_Recovery");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Terminator_Recovery_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Case_856'Access, Name => "token-cursor grammar records return missing-terminator recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Accept_End_Recovery'Access, Name => "token-cursor grammar deepens accept end and missing-end recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery'Access, Name => "token-cursor grammar deepens abort terminator and missing-terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery'Access, Name => "token-cursor grammar deepens delay terminator and missing-terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Case_794'Access, Name => "token-cursor grammar deepens return terminator and extended-return missing-end recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Raise_Terminator_Recovery'Access, Name => "token-cursor grammar deepens raise terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exit_Terminator_Recovery'Access, Name => "token-cursor grammar deepens exit terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Goto_Terminator_Recovery'Access, Name => "token-cursor grammar deepens goto terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Null_Terminator_Recovery'Access, Name => "token-cursor grammar deepens null terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Assignment_Terminator_Recovery'Access, Name => "token-cursor grammar deepens assignment terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Call_Terminator_Recovery'Access, Name => "token-cursor grammar deepens call terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Compound_End_Terminator_Recovery'Access, Name => "token-cursor grammar deepens compound end terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Case_End_Terminator_Recovery'Access, Name => "token-cursor grammar deepens case end terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Select_End_Terminator_Recovery'Access, Name => "token-cursor grammar deepens select end terminator and missing-semicolon recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Body_End_Terminator_Recovery'Access, Name => "token-cursor grammar deepens package and subprogram body end terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Concurrent_Body_End_Terminator_Recovery'Access, Name => "token-cursor grammar deepens task and protected body end terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery'Access, Name => "token-cursor grammar deepens entry declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery'Access, Name => "token-cursor grammar deepens entry body end recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subprogram_Declaration_Terminator'Access, Name => "token-cursor grammar deepens subprogram declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Object_Declaration_Terminator'Access, Name => "token-cursor grammar deepens object declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator'Access, Name => "token-cursor grammar deepens type and subtype declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Exception_Declaration_Terminator'Access, Name => "token-cursor grammar deepens exception declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Number_Declaration_Terminator'Access, Name => "token-cursor grammar deepens number declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Generic_Formal_Declaration_Terminator'Access, Name => "token-cursor grammar deepens generic formal declaration terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Package_Declaration_End_Terminator'Access, Name => "token-cursor grammar deepens package declaration end terminator recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery'Access, Name => "token-cursor grammar records requeue missing-terminator recovery metadata");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery'Access, Name => "token-cursor grammar records accept missing-terminator recovery metadata");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Terminator_Recovery_Tests;
