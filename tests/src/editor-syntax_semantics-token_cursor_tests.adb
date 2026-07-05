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

package body Editor.Syntax_Semantics.Token_Cursor_Tests is





   procedure Test_Language_Model_Token_Cursor_Ada_Grammar
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ada.Text_IO;" & ASCII.LF &
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "package Demo is" & ASCII.LF &
        "   type Vec is array (Positive range <>) of Element" & ASCII.LF &
        "     with Pack;" & ASCII.LF &
        "   procedure Run (X : in out Element);" & ASCII.LF &
        "private" & ASCII.LF &
        "   Hidden : constant Integer := 1 + 2 * 3;" & ASCII.LF &
        "end Demo;" & ASCII.LF &
        "package body Demo is" & ASCII.LF &
        "   procedure Run (X : in out Element) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if Hidden > 0 then" & ASCII.LF &
        "         X := X;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      function Count_Kind (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            if Editor.Ada_Syntax_Tree.Node_At (Tree, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Kind;
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Compilation_Unit),
              "token cursor grammar must expose compilation-unit production events");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Declaration),
              "token cursor grammar must parse generic declarations as grammar productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Package_Declaration),
              "token cursor grammar must parse package declarations as grammar productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subprogram_Body),
              "token cursor grammar must parse subprogram bodies as grammar productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Statement),
              "token cursor grammar must parse statement productions from tokens");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Expression),
              "token cursor grammar must parse expression precedence productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Simple_Expression),
              "token cursor grammar must retain simple-expression productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Term),
              "token cursor grammar must retain term-level expression productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Primary),
              "token cursor grammar must retain primary-level expression productions");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Token_Cursor_Grammar) = 1,
              "syntax tree must attach the token-cursor grammar pass exactly once");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Grammar_Production) >= 8,
              "syntax tree must retain token-cursor grammar production events");
   end Test_Language_Model_Token_Cursor_Ada_Grammar;




   procedure Test_Language_Model_Token_Cursor_Grammar_Completeness_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   with function Image (X : Element) return String;" & ASCII.LF &
        "package Grammar_Detail is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue, 'X');" & ASCII.LF &
        "   type Rec (D : Integer := 0) is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      case D is" & ASCII.LF &
        "         when 0 => B : Integer;" & ASCII.LF &
        "         when others => C : Integer;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   function F (X : Integer; Y : Integer := 0) return Integer;" & ASCII.LF &
        "   Value : Integer := (if Rec_Size > 0 then Pkg.Obj'Length else Arr (1));" & ASCII.LF &
        "   Other : Integer := Integer'(1);" & ASCII.LF &
        "end Grammar_Detail;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Formal_Declaration),
              "token-cursor grammar must retain generic formal declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile),
              "token-cursor grammar must parse subprogram parameter profiles");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Specification),
              "token-cursor grammar must parse parameter specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part),
              "token-cursor grammar must parse discriminant parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification),
              "token-cursor grammar must parse discriminant specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Type_Definition),
              "token-cursor grammar must parse enumeration type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Literal),
              "token-cursor grammar must parse enumeration literals including character literals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Definition),
              "token-cursor grammar must parse record definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Declaration),
              "token-cursor grammar must parse record component declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Part),
              "token-cursor grammar must parse variant parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant),
              "token-cursor grammar must parse variant alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Conditional_Expression),
              "token-cursor grammar must parse conditional expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "token-cursor grammar must parse selected names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Reference),
              "token-cursor grammar must parse attribute references");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Indexed_Component),
              "token-cursor grammar must parse indexed components/calls");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "token-cursor grammar must parse qualified expressions");
   end Test_Language_Model_Token_Cursor_Grammar_Completeness_Details;



   procedure Test_Language_Model_Token_Cursor_Assignment_Operand_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Assignment_Operand_Grammar is" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "   Arr   : Integer_Array (1 .. 4);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Value := T'(Source.Value);" & ASCII.LF &
        "   Arr (Index) := (case Mode is when 1 => 10, when others => raise Program_Error with ""bad"");" & ASCII.LF &
        "   Ptr.all := (if Ready then Value else 0);" & ASCII.LF &
        "   Value := Value + 1;" & ASCII.LF &
        "end Assignment_Operand_Grammar;";
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
                (Editor.Ada_Token_Cursor.Production_Assignment_Statement) >= 4,
              "assignment statements must continue to parse structurally");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Assignment_Target) >= 4,
              "assignment targets must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Assignment_Expression) >= 4,
              "assignment right-hand expressions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Indexed_Component),
              "assignment target parsing must preserve indexed-component suffixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Explicit_Dereference),
              "assignment target parsing must preserve explicit dereference suffixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "assignment expressions must parse nested qualified expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "assignment expressions must parse nested case expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Raise_Message_Expression),
              "assignment expressions must parse nested raise expressions with messages");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_If_Expression),
              "assignment expressions must parse nested conditional expressions");
   end Test_Language_Model_Token_Cursor_Assignment_Operand_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Metadata_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "pragma Assert (Check => Ready, Message => ""ready"");" & ASCII.LF &
        "package Metadata_Grammar is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "   end record with Size => 32, Object_Size => 32;" & ASCII.LF &
        "   for Rec use record" & ASCII.LF &
        "      A at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   package V is new Vectors (Index_Type => Positive, Element_Type => Integer);" & ASCII.LF &
        "   procedure Sort is new Generic_Sort (Element_Type => Integer);" & ASCII.LF &
        "end Metadata_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Pragma_Argument_Association),
              "token-cursor grammar must parse pragma argument associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Association),
              "token-cursor grammar must parse aspect associations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Representation_Clause),
              "token-cursor grammar must parse record representation clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Representation_Component_Clause),
              "token-cursor grammar must parse representation component clauses");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Part),
              "token-cursor grammar must parse generic actual parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Generic_Actual_Association),
              "token-cursor grammar must parse generic actual associations");
   end Test_Language_Model_Token_Cursor_Metadata_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Reduction_Argument_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Reduction_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Total := Items'Reduce (Combine, Neutral);" & ASCII.LF &
        "   Fast_Total := Items'Parallel_Reduce (Math.""+"", 0);" & ASCII.LF &
        "   Mapped := Items'Map_Reduce (Map_And_Add, Identity (0));" & ASCII.LF &
        "end Reduction_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Expression),
              "reduction attributes must be retained as reduction expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Reducer),
              "reduction argument parts must retain the reducer position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Reduction_Initial_Value),
              "reduction argument parts must retain the initial-value position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "parallel reduction reducers must preserve selected operator-name prefixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Argument_Part),
              "reduction argument lists must remain attached to the attribute reference");
   end Test_Language_Model_Token_Cursor_Reduction_Argument_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Discrete_Choice_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Choice_Grammar is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Kind is" & ASCII.LF &
        "      when A | B | C => null;" & ASCII.LF &
        "      when 1 .. 10 | others => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   Value := (case Kind is when A | B => 1, when others => 0);" & ASCII.LF &
        "end Choice_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "token-cursor grammar must parse Ada discrete choice lists before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice),
              "token-cursor grammar must retain individual discrete choices separated by |");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Expression),
              "token-cursor grammar must retain range choices in case alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Expression),
              "case expressions with choice lists must remain parsed as case expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative),
              "case statements with choice lists must remain parsed as alternatives");
   end Test_Language_Model_Token_Cursor_Discrete_Choice_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Derived_Tagged_Extension_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Derived_Extension_Depth is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Interface_A is interface;" & ASCII.LF &
        "   type Interface_B is interface;" & ASCII.LF &
        "   type Child is abstract limited new Root and Interface_A and Interface_B with record" & ASCII.LF &
        "      Field : Natural;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Private_Child is new Root and Interface_A with private;" & ASCII.LF &
        "   type Null_Child is new Root with null record;" & ASCII.LF &
        "   type Broken_Child is new Root with ;" & ASCII.LF &
        "   subtype After_Derived is Natural;" & ASCII.LF &
        "end Derived_Extension_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Type_Definition),
              "derived type definitions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Abstract_Type_Modifier),
              "abstract type modifiers must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Limited_Type_Modifier),
              "limited type modifiers must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Tagged_Type_Modifier),
              "tagged type modifiers must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Parent_Subtype),
              "derived parent subtype marks must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Interface_List),
              "derived interface parent lists must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Interface_Subtype),
              "derived interface subtype marks must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Record_Extension),
              "derived record extensions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Private_Extension),
              "derived private extensions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Null_Record_Extension),
              "derived null record extensions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Type_Recovery_Boundary),
              "malformed derived type extensions must expose recovery boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "parser must recover into following declarations after malformed derived types");
   end Test_Language_Model_Token_Cursor_Derived_Tagged_Extension_Depth_Grammar_Completeness;



   procedure Test_Language_Model_Token_Cursor_Call_Actual_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Call_Actual_Delimiters is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Do_It (A, B => C);" & ASCII.LF &
        "   Server.Entry_Name (Index, Item => Value);" & ASCII.LF &
        "   Broken (A, B => C;" & ASCII.LF &
        "   After_Call;" & ASCII.LF &
        "end Call_Actual_Delimiters;";
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
                (Editor.Ada_Token_Cursor.Production_Call_Actual_List_Open_Delimiter) >= 3,
              "call actual lists must retain opening delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Call_Actual_List_Close_Delimiter) >= 2,
              "well-formed call actual lists must retain closing delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Call_Actual_Association_Separator) >= 3,
              "call actual lists must retain comma separators between actuals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_List_Missing_Close_Recovery_Boundary),
              "in-progress call actual lists must record bounded missing-close recovery");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Entry_Call_Actual_List_Open_Delimiter) >= 3,
              "entry-call actual lists must retain opening delimiters");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Entry_Call_Actual_Association_Separator) >= 3,
              "entry-call actual lists must retain comma separators between actuals");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Entry_Call_Actual_List_Missing_Close_Recovery_Boundary),
              "in-progress entry-call actual lists must record bounded missing-close recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Statement),
              "call actual missing-close recovery must not consume the following call statement");
   end Test_Language_Model_Token_Cursor_Call_Actual_Delimiters;







   procedure Test_Language_Model_Token_Cursor_Constraint_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Constraint_Delimiters is" & ASCII.LF &
        "   type Vector is array (Positive range <>, Positive range <>) of Integer;" & ASCII.LF &
        "   subtype Slice is Vector (1 .. 10, 1 .. 20);" & ASCII.LF &
        "   type Rec (Low, High : Integer) is null record;" & ASCII.LF &
        "   subtype Named is Rec (Low => 1, High => 10);" & ASCII.LF &
        "   subtype Broken_Index is Vector (1 .. 10, 1 .. 20;" & ASCII.LF &
        "   subtype Broken_Discriminant is Rec (Low => 1, High => 10;" & ASCII.LF &
        "   subtype Next is Integer range 0 .. 10;" & ASCII.LF &
        "end Constraint_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint),
              "index constraints must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint_Open_Delimiter),
              "index constraints must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint_Close_Delimiter),
              "well-formed index constraints must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint_Item_Separator),
              "multi-dimensional index constraints must retain item separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint_Missing_Close_Recovery_Boundary),
              "malformed index constraints must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint),
              "discriminant constraints must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint_Open_Delimiter),
              "discriminant constraints must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint_Close_Delimiter),
              "well-formed discriminant constraints must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Association_Separator),
              "multi-association discriminant constraints must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint_Missing_Close_Recovery_Boundary),
              "malformed discriminant constraints must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration_Terminator),
              "constraint recovery must leave following subtype declaration terminators available");
   end Test_Language_Model_Token_Cursor_Constraint_Delimiters;




   procedure Test_Language_Model_Token_Cursor_Quantified_Domain_Deep_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Quantified_Domain_Deep is" & ASCII.LF &
        "   A : Boolean := (for all I in Low .. High => Data (I) /= 0);" & ASCII.LF &
        "   B : Boolean := (for some Item of reverse Items when Item.Valid => Item.Score > 0);" & ASCII.LF &
        "   C : Boolean := (for all K in Natural range 1 .. Limit => Seen (K));" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Quantified_Domain_Deep;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Parameter),
              "quantified expression parameters must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Domain),
              "quantified expression domains must be parsed instead of skipped to the arrow");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Iterator_Filter),
              "quantified iterator filters must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Quantified_Predicate),
              "quantified expression predicates must be distinct from loop schemes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Expression),
              "quantified discrete ranges must expose their range-expression structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Iterator_Specification),
              "generalized quantified iterators must remain distinct from discrete loop parameters");
   end Test_Language_Model_Token_Cursor_Quantified_Domain_Deep_Grammar_Completeness;

   procedure Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Discrete_Choice_List_Separators is" & ASCII.LF &
        "   type Mode is (A, B, C);" & ASCII.LF &
        "   function F (M : Mode) return Integer is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      case M is" & ASCII.LF &
        "         when A | B => return 1;" & ASCII.LF &
        "         when C | => return 2;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end F;" & ASCII.LF &
        "end Discrete_Choice_List_Separators;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "case alternatives must retain discrete choice-list metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_Separator),
              "discrete choice lists must retain separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_Missing_Choice_Recovery_Boundary),
              "malformed discrete choice lists must retain bounded missing-choice recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Case_Alternative_Arrow),
              "discrete choice recovery must leave the following case alternative arrow available");
   end Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators;





   procedure Test_Language_Model_Token_Cursor_Range_Constraint_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Range_Constraint_Bounds is" & ASCII.LF &
        "   type Index_Type is range 1 .. 10;" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 5;" & ASCII.LF &
        "   subtype Missing_Lower is Integer range ;" & ASCII.LF &
        "   subtype Missing_Upper is Integer range 1 .. ;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Range_Constraint_Bounds;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "range constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Lower_Bound),
              "range constraints must retain lower-bound metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint_Range_Separator),
              "range constraints must retain explicit .. separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Upper_Bound),
              "range constraints must retain upper-bound metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary),
              "missing range lower bounds must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary),
              "missing range upper bounds must retain bounded recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "range-constraint recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Range_Constraint_Bounds;




   procedure Test_Language_Model_Token_Cursor_Range_Constraint_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Range_Constraint_Depth is" & ASCII.LF &
        "   type Matrix is array (Positive range <>, Positive range <>) of Integer;" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 10;" & ASCII.LF &
        "   subtype Whole is Integer range Natural'Range;" & ASCII.LF &
        "   subtype Slice is Matrix (1 .. 10, 2 .. 20);" & ASCII.LF &
        "   subtype Bad_Range is Integer range 1 .. ;" & ASCII.LF &
        "   subtype Bad_Index is Matrix (1 .. 10, );" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Range_Constraint_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Range_Lower_Bound) >= 5,
              "range and index constraints must retain lower-bound positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Range_Upper_Bound) >= 3,
              "range and index constraints must retain upper-bound positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Attribute_Reference),
              "range attributes used as range constraints must be classified explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Attribute_Prefix),
              "range attribute prefixes must be retained for semantic-colouring consumers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Index_Constraint_Item) >= 2,
              "multi-dimensional index constraints must retain per-index items");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constraint_Recovery_Boundary),
              "malformed range/index constraints must expose bounded recovery boundaries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subtype_Declaration) >= 5,
              "constraint recovery must continue into following subtype declarations");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 1,
              "constraint recovery must continue into following object declarations");
   end Test_Language_Model_Token_Cursor_Range_Constraint_Depth_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Assignment_Call_Ambiguity is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Field : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Obj : Rec;" & ASCII.LF &
        "   Arr : array (1 .. 10) of Integer;" & ASCII.LF &
        "   Ptr : access Rec;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Obj.Field := Arr (1);" & ASCII.LF &
        "   Arr (2 .. 4) := (others => 0);" & ASCII.LF &
        "   Ptr.all.Field := 10;" & ASCII.LF &
        "   Pkg.Op (Name => Obj.Field);" & ASCII.LF &
        "   Ambiguous Target;" & ASCII.LF &
        "end Assignment_Call_Ambiguity;";
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
                (Editor.Ada_Token_Cursor.Production_Assignment_Statement) >= 3,
              "selected indexed and dereferenced assignment statements must remain assignments");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Selected_Target),
              "selected assignment targets must be retained separately from call targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Indexed_Target),
              "indexed assignment targets must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Slice_Target),
              "slice assignment targets must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Dereference_Target),
              "explicit dereference assignment targets must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Selected_Target),
              "selected procedure-call targets must not be coloured as assignment targets");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Indexed_Or_Actual_Target),
              "call actual parts must be retained as call-shaped suffixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Call_Actual_Association),
              "named actual associations in calls must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Assignment_Target_Recovery_Boundary),
              "malformed statement targets that look like missing := must expose a recovery boundary");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Statement_Name_Suffix) >= 4,
              "name suffixes must be retained before assignment/call classification");
   end Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness;


   overriding function Name (T : Token_Cursor_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Ada_Grammar'Access, Name => "syntax tree uses full token-cursor Ada grammar layer");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Grammar_Completeness_Details'Access, Name => "token-cursor grammar parses detailed Ada productions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Assignment_Operand_Grammar_Completeness'Access, Name => "token-cursor grammar retains assignment targets and expressions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Metadata_Grammar_Completeness'Access, Name => "token-cursor grammar parses metadata and representation productions");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Reduction_Argument_Grammar_Completeness'Access, Name => "token-cursor grammar parses reduction attribute argument parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discrete_Choice_Grammar_Completeness'Access, Name => "token-cursor grammar parses case and variant discrete choice lists structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Derived_Tagged_Extension_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses derived tagged type extensions deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Call_Actual_Delimiters'Access, Name => "token-cursor grammar deepens call and entry-call actual delimiters and missing-close recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Constraint_Delimiters'Access, Name => "token-cursor grammar records index and discriminant constraint delimiters separators and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Quantified_Domain_Deep_Grammar_Completeness'Access, Name => "token-cursor grammar parses quantified expression domains filters and predicates deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators'Access, Name => "token-cursor grammar records discrete-choice separators and missing-choice recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Range_Constraint_Bounds'Access, Name => "token-cursor grammar records range constraint bounds separator and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Range_Constraint_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar retains range index constraint bounds attributes and recovery structure");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness'Access, Name => "token-cursor grammar disambiguates assignment and call statement targets structurally");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Tests;
