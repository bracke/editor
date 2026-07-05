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

package body Editor.Syntax_Semantics.Token_Cursor_Type_Declaration_Tests is








   procedure Test_Language_Model_Token_Cursor_Type_Definition_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Type_Grammar is" & ASCII.LF &
        "   type Enum is (A, B);" & ASCII.LF &
        "   type Rec is record X : Integer; end record;" & ASCII.LF &
        "   type Arr is array (Positive range <>) of Integer;" & ASCII.LF &
        "   type Ptr is access all Rec;" & ASCII.LF &
        "   type Proc_Ptr is access protected procedure (X : Integer);" & ASCII.LF &
        "   type Child is new Rec with private;" & ASCII.LF &
        "   type I is limited interface;" & ASCII.LF &
        "   type Small is range 0 .. 10;" & ASCII.LF &
        "   type Word is mod 2 ** 16;" & ASCII.LF &
        "   type Real is digits 6 range -1.0 .. 1.0;" & ASCII.LF &
        "   type Fixed is delta 0.01 range -1.0 .. 1.0;" & ASCII.LF &
        "   type Money is delta 0.01 digits 12;" & ASCII.LF &
        "   subtype Small_Pos is Positive range 1 .. 10;" & ASCII.LF &
        "   V : Arr (1 .. 10);" & ASCII.LF &
        "end Type_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Type_Definition),
              "token-cursor grammar must retain type-definition productions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Type_Definition),
              "token-cursor grammar must parse array type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint),
              "token-cursor grammar must parse index constraints");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Definition),
              "token-cursor grammar must parse access type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Type_Definition),
              "token-cursor grammar must parse derived type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Type_Definition),
              "token-cursor grammar must parse private type definitions and private extensions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Interface_Type_Definition),
              "token-cursor grammar must parse interface type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Signed_Integer_Type_Definition),
              "token-cursor grammar must parse signed integer type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Modular_Type_Definition),
              "token-cursor grammar must parse modular type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Floating_Point_Definition),
              "token-cursor grammar must parse floating point type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Ordinary_Fixed_Point_Definition),
              "token-cursor grammar must parse ordinary fixed point type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Decimal_Fixed_Point_Definition),
              "token-cursor grammar must parse decimal fixed point type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Indication),
              "token-cursor grammar must parse subtype indications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "token-cursor grammar must parse range constraints");
   end Test_Language_Model_Token_Cursor_Type_Definition_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Scalar_Type_Definition_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Scalar_Type_Definition_Internals is" & ASCII.LF &
        "   type Small is range Low .. High;" & ASCII.LF &
        "   type Word is mod 2 ** 16;" & ASCII.LF &
        "   type Real is digits Precision range -Limit .. Limit;" & ASCII.LF &
        "   type Step is delta Model.Step range Model.Low .. Model.High;" & ASCII.LF &
        "   type Money is delta 0.01 digits Decimal_Digits;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Scalar_Type_Definition_Internals;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Signed_Integer_Type_Definition),
              "signed integer type definitions must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Signed_Integer_Range),
              "signed integer type definitions must retain the range side explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Modular_Type_Definition),
              "modular type definitions must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Modular_Modulus_Expression),
              "modular type definitions must retain the modulus expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Floating_Point_Definition),
              "floating point type definitions must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Floating_Digits_Expression),
              "floating point type definitions must retain the digits expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Ordinary_Fixed_Point_Definition),
              "ordinary fixed point type definitions must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Decimal_Fixed_Point_Definition),
              "decimal fixed point type definitions must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Fixed_Delta_Expression),
              "fixed point type definitions must retain the delta expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Fixed_Digits_Expression),
              "decimal fixed point type definitions must retain the digits expression position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "scalar range constraints must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after scalar type definitions");
   end Test_Language_Model_Token_Cursor_Scalar_Type_Definition_Internal_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Derived_Type_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Derived_Type_Internals is" & ASCII.LF &
        "   type Root is tagged record X : Integer; end record;" & ASCII.LF &
        "   type Iface is interface;" & ASCII.LF &
        "   type Controlled is interface;" & ASCII.LF &
        "   type Child is new Parent.Root with private;" & ASCII.LF &
        "   type Leaf is new Parent.Root and Iface and Controlled with record" & ASCII.LF &
        "      Y : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Derived_Type_Internals;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Type_Definition),
              "derived type definitions must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Derived_Parent_Subtype) >= 2,
              "derived type definitions must retain their parent subtype positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Interface_List),
              "derived type definitions must retain interface-list positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Derived_Interface_Subtype) >= 2,
              "derived type definitions must retain every interface subtype position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Type_Definition),
              "private extensions must remain structurally classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Definition),
              "record extensions must continue to parse their record definition");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after derived type definitions");
   end Test_Language_Model_Token_Cursor_Derived_Type_Internal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Interface_Type_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Interface_Type_Internals is" & ASCII.LF &
        "   type Base_IO is limited interface;" & ASCII.LF &
        "   type Controlled_IO is interface and Base_IO and Ada.Streams.Root_Stream_Type'Class;" & ASCII.LF &
        "   type Worker is synchronized interface and Controlled_IO;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Interface_Type_Internals;";
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
                (Editor.Ada_Token_Cursor.Production_Interface_Type_Definition) >= 3,
              "interface type definitions must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Type_Modifier) >= 2,
              "interface type modifiers must remain structurally visible");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Interface_Parent_List) >= 2,
              "interface type definitions must retain parent-list positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Interface_Parent_Subtype) >= 3,
              "interface type definitions must retain every parent subtype position");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Attribute_Reference),
              "interface parent subtype marks must preserve attribute suffixes");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after interface type definitions");
   end Test_Language_Model_Token_Cursor_Interface_Type_Internal_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Access_Definition_Gap_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Definition_Gaps is" & ASCII.LF &
        "   type Object_Access is access all Root.Child;" & ASCII.LF &
        "   type Constant_Access is access constant Root.Child;" & ASCII.LF &
        "   type Protected_Callback is not null access protected function" & ASCII.LF &
        "     (Left : not null access constant Root.Child;" & ASCII.LF &
        "      Right : access procedure (Value : Integer))" & ASCII.LF &
        "      return not null access Root.Child;" & ASCII.LF &
        "   type Holder (Item : not null access Root.Child) is record" & ASCII.LF &
        "      Hook : access protected procedure (Value : Integer);" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Install" & ASCII.LF &
        "     (Target : aliased in out not null access Root.Child;" & ASCII.LF &
        "      Factory : not null access function return access Root.Child);" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Formal_Object is access constant Root.Child;" & ASCII.LF &
        "      type Formal_Proc is not null access procedure (Value : Integer);" & ASCII.LF &
        "   package Formal_Accesses is end Formal_Accesses;" & ASCII.LF &
        "end Access_Definition_Gaps;";
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
                (Editor.Ada_Token_Cursor.Production_Access_Definition) >= 8,
              "access definitions in object, parameter, result, discriminant, component, and formal contexts must be retained");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_To_Object_Definition) >= 5,
              "anonymous and named access-to-object definitions must retain their designated subtype mark");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_To_Subprogram_Definition) >= 4,
              "access-to-subprogram definitions must retain procedure/function profile structure");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Mode) >= 3,
              "access all and access constant modes must not be flattened into subtype names");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Protected_Part),
              "access protected procedure/function forms must retain the protected marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Parameter_Profile) >= 3,
              "access-to-subprogram parameter profiles must be retained separately from ordinary parameter profiles");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Result_Subtype) >= 2,
              "access-to-function result subtype indications must be retained separately from object access definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Exclusion),
              "not null must remain attached before nested access definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Formal_Access_Type_Definition),
              "generic formal access type definitions must still be recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification),
              "access discriminants must keep discriminant specification structure");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Parameter_Profile),
              "access-to-subprogram definitions must keep parameter/result profile structure");
   end Test_Language_Model_Token_Cursor_Access_Definition_Gap_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Array_Index_Subtype_Grammar is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of Integer;" & ASCII.LF &
        "   type Matrix is array" & ASCII.LF &
        "     (Positive range <>, Natural range <>) of Integer;" & ASCII.LF &
        "   type Fixed is array (1 .. 10) of Integer;" & ASCII.LF &
        "   type Aliased_Table is array (Positive range <>) of aliased Integer;" & ASCII.LF &
        "end Array_Index_Subtype_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Type_Definition),
              "array type definitions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Index_Subtype_Definition),
              "array type definitions must retain array-specific index subtype definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Subtype_Definition),
              "unconstrained array index subtype definitions must be distinguished from index constraints");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "array index ranges and range boxes must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint),
              "constrained array index constraints must continue to parse");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Component_Definition),
              "array type definitions must retain component definitions after of");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "aliased array component definitions must retain the aliased marker");
   end Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Type_Modifier_Grammar is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Limited_Rec is abstract tagged limited record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Handle is tagged private;" & ASCII.LF &
        "   type Sync is synchronized interface;" & ASCII.LF &
        "   type Child is abstract new Root and Sync with private;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Handle is tagged record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Type_Modifier_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Type_Modifier),
              "type definition modifiers such as abstract/tagged/limited/synchronized must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Definition),
              "modified record definitions must not fall through subtype recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Type_Definition),
              "modified private types and private extensions must be recognized");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Interface_Type_Definition),
              "task/protected/synchronized interface forms must retain interface grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Derived_Type_Definition),
              "abstract/limited derived type definitions must still be parsed as derived types");
   end Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Incomplete_Type_Grammar is" & ASCII.LF &
        "   type Node;" & ASCII.LF &
        "   type Cursor (Kind : Natural);" & ASCII.LF &
        "   type Root is tagged;" & ASCII.LF &
        "   type Ref is access all Node;" & ASCII.LF &
        "end Incomplete_Type_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Incomplete_Type_Declaration),
              "plain incomplete type declarations must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Tagged_Incomplete_Type_Declaration),
              "tagged incomplete type declarations must not be parsed as malformed full type definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part),
              "incomplete declarations with discriminant parts must preserve discriminant grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Definition),
              "incomplete type parsing must not break subsequent access type declarations");
   end Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Unknown_Discriminant_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Unknown_Discriminant_Grammar is" & ASCII.LF &
        "   type Deferred (<>);" & ASCII.LF &
        "   type Visible (<>) is private;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Visible is null record;" & ASCII.LF &
        "end Unknown_Discriminant_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part),
              "unknown discriminant parts must still be represented as discriminant parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Unknown_Discriminant_Part),
              "Ada unknown discriminant parts (<>) must be parsed structurally instead of as malformed discriminant specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Private_Type_Definition),
              "private type definitions with unknown discriminants must keep their type-definition grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Incomplete_Type_Declaration),
              "incomplete type declarations with unknown discriminants must keep incomplete-type grammar");
   end Test_Language_Model_Token_Cursor_Unknown_Discriminant_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Component_Definition_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Component_Definition_Grammar is" & ASCII.LF &
        "   type Node;" & ASCII.LF &
        "   type Link is access all Node;" & ASCII.LF &
        "   type Node is record" & ASCII.LF &
        "      Left, Right : aliased not null access Node := Default_Node;" & ASCII.LF &
        "      Payload : Integer := 0;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Component_Definition_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Declaration),
              "record components must remain component declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Definition),
              "component definitions must be parsed structurally instead of opaque-skipped to semicolon");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "aliased component definitions must retain their aliased part");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Exclusion),
              "not-null access component definitions must retain null-exclusion grammar");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Default_Expression),
              "component default expressions must be retained structurally");
   end Test_Language_Model_Token_Cursor_Component_Definition_Grammar_Completeness;




   procedure Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Discriminant_Constraint_Grammar is" & ASCII.LF &
        "   type Bounds (Low, High : Integer) is null record;" & ASCII.LF &
        "   subtype Positive_Bounds is Bounds (Low | High => 1);" & ASCII.LF &
        "   type Table is array (1 .. 10) of Integer;" & ASCII.LF &
        "   subtype Small_Table is Table (1 .. 5);" & ASCII.LF &
        "end Discriminant_Constraint_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Constraint),
              "named discriminant constraints must be parsed structurally instead of as index constraints");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Association),
              "discriminant associations with selector names must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Selector_Name),
              "discriminant selector-name lists separated by | must be retained before =>");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Index_Constraint),
              "ordinary array index constraints must remain on the index-constraint grammar path");
   end Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Subtype_Constraint_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Subtype_Constraint_Grammar is" & ASCII.LF &
        "   type Ratio is digits 12 range -1.0 .. 1.0;" & ASCII.LF &
        "   type Money is delta 0.01 digits 12 range 0.00 .. 10_000.00;" & ASCII.LF &
        "   subtype Short_Ratio is Ratio digits 6 range -0.5 .. 0.5;" & ASCII.LF &
        "   subtype Small_Money is Money delta 0.01 digits 8 range 0.00 .. 99.99;" & ASCII.LF &
        "end Subtype_Constraint_Grammar;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "subtype declarations with numeric constraints must remain subtype declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Digits_Constraint),
              "digits constraints in subtype indications must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Delta_Constraint),
              "delta constraints in fixed-point subtype indications must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "numeric subtype constraints must continue into optional range constraints");
   end Test_Language_Model_Token_Cursor_Subtype_Constraint_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Array_Type_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Array_Type_Depth is" & ASCII.LF &
        "   type Vector is array (Positive range <>) of aliased Element;" & ASCII.LF &
        "   type Table is array (Positive range <>, Natural range <>) of not null access Node;" & ASCII.LF &
        "   type Grid is array (1 .. 10, 2 .. 20) of Cell;" & ASCII.LF &
        "   type Access_Grid is array (1 .. 4) of aliased not null access Cell;" & ASCII.LF &
        "   type Broken is array (1 .., 2 .. 3) of Cell;" & ASCII.LF &
        "   subtype After_Array is Natural;" & ASCII.LF &
        "end Array_Type_Depth;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Unconstrained_Array_Index_Part),
              "unconstrained array index parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constrained_Array_Index_Part),
              "constrained array index parts must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Array_Index_Subtype_Definition) >= 2,
              "multidimensional unconstrained array index subtype definitions must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Index_Subtype_Name),
              "array index subtype names must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Index_Range_Box),
              "array index range boxes must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Index_Constraint_Item) >= 3,
              "multidimensional constrained array index items must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Component_Subtype_Indication),
              "ordinary array component subtype indications must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Array_Component_Access_Definition),
              "anonymous access array components must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "aliased array components must retain the aliased marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constraint_Recovery_Boundary),
              "malformed array index constraints must expose recovery boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "parser must recover into following declarations after malformed array types");
   end Test_Language_Model_Token_Cursor_Array_Type_Depth_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Access_Type_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Type_Depth is" & ASCII.LF &
        "   type Pool_Object is access Item;" & ASCII.LF &
        "   type General_Object is access all Item;" & ASCII.LF &
        "   type Constant_Object is access constant Item;" & ASCII.LF &
        "   type Handler is access procedure (X : in Item);" & ASCII.LF &
        "   type Protected_Handler is access protected procedure (X : in Item);" & ASCII.LF &
        "   type Factory is not null access function (X : Item) return Result;" & ASCII.LF &
        "   type Broken is access all ;" & ASCII.LF &
        "   subtype After_Access is Natural;" & ASCII.LF &
        "end Access_Type_Depth;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Pool_Specific_Object),
              "pool-specific access object definitions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_General_Object),
              "general access object definitions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_All_Object_Mode),
              "access all object modes must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Constant_Object_Mode),
              "access constant object modes must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Object_Subtype_Mark),
              "access object designated subtype marks must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Named_Subprogram_Definition),
              "named access-to-subprogram definitions must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Subprogram_Profile),
              "access-to-subprogram profiles must be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Protected_Part),
              "protected access-to-subprogram forms must retain the protected marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Result_Subtype),
              "access-to-function result subtypes must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Null_Exclusion),
              "not-null access type definitions must retain null-exclusion markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Access_Type_Recovery_Boundary),
              "malformed access type definitions must expose recovery boundaries");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Declaration),
              "parser must recover into following declarations after malformed access types");
   end Test_Language_Model_Token_Cursor_Access_Type_Depth_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Type_Declaration_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Type_Declarations is" & ASCII.LF &
        "   type Plain;" & ASCII.LF &
        "   type Tagged_Plain is tagged;" & ASCII.LF &
        "   type Item (Length : Natural := 0) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type State is (Idle, Busy) with Size => 8;" & ASCII.LF &
        "   type Refined (<>) is private;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Type_Declarations;";
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
                (Editor.Ada_Token_Cursor.Production_Type_Declaration) >= 5,
              "type declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Type_Defining_Name) >= 5,
              "type declarations must retain their defining names explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Type_Discriminant_Part) >= 2,
              "known and unknown type discriminant parts must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Incomplete_Type_Declaration),
              "plain incomplete type declarations must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Tagged_Incomplete_Type_Declaration),
              "tagged incomplete type declarations must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification),
              "known type discriminant parts must still parse discriminant specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Unknown_Discriminant_Part),
              "unknown type discriminant parts must still be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Type_Definition),
              "full type definitions must still parse enumeration definitions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following object declarations after type declarations");
   end Test_Language_Model_Token_Cursor_Type_Declaration_Internal_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Discriminant_Specification_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Discriminant_Specifications is" & ASCII.LF &
        "   type Item (Low, High : Integer := 0;" & ASCII.LF &
        "              Name : Model.Name := Model.Default_Name) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Discriminant_Specifications;";
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
                (Editor.Ada_Token_Cursor.Production_Discriminant_Specification) >= 2,
              "known discriminant specifications must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Discriminant_Defining_Name_List) >= 2,
              "discriminant specifications must retain grouped defining-name lists");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Discriminant_Subtype_Indication) >= 2,
              "discriminant specifications must retain subtype-indication positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Discriminant_Default_Expression) >= 2,
              "discriminant specifications must retain default-expression positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Name),
              "selected subtype marks and selected default expressions must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after discriminant specifications");
   end Test_Language_Model_Token_Cursor_Discriminant_Specification_Internal_Grammar_Completeness;







   procedure Test_Language_Model_Token_Cursor_Discriminant_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Discriminant_Depth is" & ASCII.LF &
        "   type Forward (<>) is tagged;" & ASCII.LF &
        "   type Item (Ref : not null access Integer;" & ASCII.LF &
        "              Name : Model.Name := Model.Default_Name;" & ASCII.LF &
        "              Size : Positive := 1) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   subtype Small_Item is Item (Name => Model.Default_Name, Size => 2);" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Discriminant_Depth;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Unknown_Discriminant_Part),
              "unknown discriminant parts must remain structurally distinct");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Known_Discriminant_Part),
              "known discriminant parts must have their own structural marker");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Access_Definition),
              "access discriminants must be distinguished from ordinary subtype discriminants");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Null_Exclusion),
              "not-null access discriminants must retain the discriminant-specific null exclusion");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Discriminant_Default_Expression) >= 2,
              "default discriminant expressions must remain retained");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Discriminant_Constraint_Expression) >= 2,
              "discriminant constraint association expressions must be retained");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after discriminant depth forms");
   end Test_Language_Model_Token_Cursor_Discriminant_Depth_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Variant_Record_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Variant_Depth is" & ASCII.LF &
        "   type Kind is (Small, Medium, Large);" & ASCII.LF &
        "   type Nested is (No_Detail, With_Detail);" & ASCII.LF &
        "   type Item (K : Kind; N : Nested) is record" & ASCII.LF &
        "      Header : Integer;" & ASCII.LF &
        "      case K is" & ASCII.LF &
        "         when Small | Medium =>" & ASCII.LF &
        "            Count : Integer;" & ASCII.LF &
        "            case N is" & ASCII.LF &
        "               when With_Detail =>" & ASCII.LF &
        "                  Detail : Integer;" & ASCII.LF &
        "               when others =>" & ASCII.LF &
        "                  null;" & ASCII.LF &
        "            end case;" & ASCII.LF &
        "         when others =>" & ASCII.LF &
        "            Ready : Boolean;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Broken (K : Kind) is record" & ASCII.LF &
        "      case K is" & ASCII.LF &
        "         when Small" & ASCII.LF &
        "            Missing_Arrow : Integer;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Variant_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Variant_Part) >= 2,
              "outer and nested variant parts must remain structural");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Nested_Variant_Part),
              "nested variant parts must have a dedicated marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Choice_List) >= 4,
              "variant alternatives must retain choice-list markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Choice_Separator),
              "variant choice alternatives must retain separator markers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Choice_Arrow) >= 3,
              "variant alternatives must retain explicit arrow markers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Others_Choice) >= 2,
              "others choices must remain classified in variant alternatives");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Recovery_Boundary),
              "malformed variant alternatives must retain bounded recovery markers");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after variant records");
   end Test_Language_Model_Token_Cursor_Variant_Record_Depth_Grammar_Completeness;






   procedure Test_Language_Model_Token_Cursor_Subtype_Declaration_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Subtype_Declarations is" & ASCII.LF &
        "   subtype Small_Count is Numeric.Count range 1 .. 10 with Static_Predicate => Small_Count > 0;" & ASCII.LF &
        "   subtype Class_View is Model.Root'Class;" & ASCII.LF &
        "   subtype Operator_Selected is Operator_Types.""+"";" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Subtype_Declarations;";
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
                (Editor.Ada_Token_Cursor.Production_Subtype_Declaration) = 3,
              "all subtype declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subtype_Defining_Name) = 3,
              "subtype declarations must retain their defining names explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Subtype_Declaration_Subtype_Indication) = 3,
              "subtype declarations must retain their subtype-indication side explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Range_Constraint),
              "subtype declaration subtype indications must still parse range constraints");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "subtype declaration subtype indications must still parse selected operator subtype marks");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aspect_Specification),
              "subtype declarations must still allow attached aspect specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following declarations after subtype declarations");
   end Test_Language_Model_Token_Cursor_Subtype_Declaration_Internal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Component_Declaration_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Component_Declarations is" & ASCII.LF &
        "   type Callback is access procedure (X : Integer);" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A, B : aliased Integer := Integer'(0);" & ASCII.LF &
        "      Handler : Callback := Default_Handler;" & ASCII.LF &
        "      Op_Selected : Operator_Types.""+"" := Operator_Types.""+""'(Value);" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Component_Declarations;";
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
                (Editor.Ada_Token_Cursor.Production_Component_Declaration) >= 3,
              "component declarations must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Component_Defining_Name_List) >= 3,
              "component declarations must retain defining-name-list positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Component_Subtype_Indication) >= 3,
              "component declarations must retain subtype-indication positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Component_Default_Expression) >= 3,
              "component declarations with := must retain default-expression positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Aliased_Part),
              "component declarations must still retain aliased parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Selected_Operator_Selector),
              "component subtype indications and defaults must still parse selected operator selectors");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Qualified_Expression),
              "component default expressions must still parse qualified expressions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following object declarations after record components");
   end Test_Language_Model_Token_Cursor_Component_Declaration_Internal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Variant_Part_Internal_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Variant_Parts is" & ASCII.LF &
        "   type Kind is (Plain, With_Value);" & ASCII.LF &
        "   type Rec (K : Kind := Plain) is record" & ASCII.LF &
        "      Prefix : Integer;" & ASCII.LF &
        "      case K is" & ASCII.LF &
        "         when Plain =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "         when With_Value | others =>" & ASCII.LF &
        "            Value : Integer := Integer'(1);" & ASCII.LF &
        "            Extra : Model.Count;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Variant_Parts;";
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
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Part),
              "variant parts must remain classified");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Part_Discriminant_Name),
              "variant parts must retain the discriminant selector position");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant) >= 2,
              "variant alternatives must remain classified");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Choice_List) >= 2,
              "variant alternatives must retain choice-list positions");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Component_Part) >= 2,
              "variant alternatives must retain component-part positions");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discrete_Choice_List),
              "variant choice lists must still parse discrete choices");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Component_Declaration),
              "variant component parts must still parse component declarations");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser must recover into following object declarations after variants");
   end Test_Language_Model_Token_Cursor_Variant_Part_Internal_Grammar_Completeness;





   procedure Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refinement_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Anonymous_Access_Subprogram_Refinement_Depth is" & ASCII.LF &
        "   Missing_Protected_Profile_Close : access protected procedure (Item : Integer with Inline;" & ASCII.LF &
        "   Missing_Function_Profile_Close : access function (Seed : Integer with Pre => Ready;" & ASCII.LF &
        "   Missing_Result_After_Not_Null : access protected function return not null with Convention => Ada;" & ASCII.LF &
        "   Valid_Protected_Function : access protected function (Item : Integer) return not null access Root.Child;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Anonymous_Access_Subprogram_Refinement_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Parameter_Profile_Missing_Close_Recovery_Boundary) >= 2,
              "anonymous access-to-subprogram parameter profiles missing ')' must expose access-specific recovery");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar,
                 Editor.Ada_Token_Cursor.Production_Access_Result_Null_Exclusion_Missing_Subtype_Recovery_Boundary),
              "access-to-function return not null at a boundary must expose result-null-exclusion recovery");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Protected_Function_Profile) >= 2,
              "protected access-to-function profiles must remain classified through recovery and valid forms");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Result_Null_Exclusion) >= 1,
              "valid protected access-to-function result null exclusions must remain explicit");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "anonymous access-to-subprogram refinement recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refinement_Depth;





   procedure Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Anonymous_Access_Subprograms is" & ASCII.LF &
        "   type Protected_Proc is access protected procedure (X : in out Integer);" & ASCII.LF &
        "   type Protected_Func is not null access protected function (X : Integer) return Boolean;" & ASCII.LF &
        "   procedure Register" & ASCII.LF &
        "     (Hook : access protected procedure (Item : Integer);" & ASCII.LF &
        "      Filter : not null access function (Item : Integer) return Boolean);" & ASCII.LF &
        "   function Factory return not null access protected function (Item : Integer) return Boolean;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Anonymous_Access_Subprograms;";
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
                (Editor.Ada_Token_Cursor.Production_Access_To_Subprogram_Definition) >= 5,
              "anonymous access-to-subprogram definitions must be retained in type, parameter, and result contexts");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Profile) >= 5,
              "anonymous access-to-subprogram profiles must have a callable-profile marker");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Kind) >= 5,
              "anonymous access-to-subprogram procedure/function kind must be retained explicitly");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Protected_Part) >= 3,
              "protected anonymous access-to-subprogram forms must retain the protected prefix");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Parameter_Profile) >= 4,
              "anonymous access-to-subprogram parameter profiles must be marked before nested parameter parsing");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Subprogram_Result_Profile) >= 3,
              "anonymous access-to-function result profiles must be marked before result subtype parsing");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Access_Result_Subtype) >= 3,
              "anonymous access-to-function result subtype positions must remain explicit");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "parser recovery must continue into following declarations after anonymous access-to-subprogram profiles");
   end Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Grammar_Completeness;







   procedure Test_Language_Model_Token_Cursor_Variant_Record_Component_Depth
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Variant_Component_Depth is" & ASCII.LF &
        "   type Kind is (Small, Medium, Large, Special);" & ASCII.LF &
        "   type Inner (Mode : Kind) is record" & ASCII.LF &
        "      case Mode is" & ASCII.LF &
        "         when Small | Medium =>" & ASCII.LF &
        "            Count : Integer := 0;" & ASCII.LF &
        "         when Large .. Special =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "         when others =>" & ASCII.LF &
        "            Flag : Boolean;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Outer (Mode : Kind; Nested_Mode : Kind) is record" & ASCII.LF &
        "      Header : Integer;" & ASCII.LF &
        "      case Mode is" & ASCII.LF &
        "         when Small =>" & ASCII.LF &
        "            case Nested_Mode is" & ASCII.LF &
        "               when Medium | Large =>" & ASCII.LF &
        "                  Payload : Inner (Nested_Mode);" & ASCII.LF &
        "               when others =>" & ASCII.LF &
        "                  null;" & ASCII.LF &
        "            end case;" & ASCII.LF &
        "         when Medium | Large =>" & ASCII.LF &
        "            Value : Integer;" & ASCII.LF &
        "         when others =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Variant_Component_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Variant_Part) >= 2,
              "variant records must retain discriminant-dependent variant parts");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Nested_Variant_Part),
              "nested variant parts inside variant alternatives must remain explicit");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Discrete_Choice) >= 4,
              "individual variant choices must retain bounded discrete-choice metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Variant_Range_Choice),
              "variant alternatives using ranges must retain range-choice metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Choice_Separator) >= 2,
              "multi-choice variant alternatives must retain choice separator metadata");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Component_Declaration) >= 3,
              "component declarations inside variant alternatives must retain variant-specific markers");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Variant_Null_Component_Part) >= 2,
              "null component alternatives must retain explicit variant null-component metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Record_Definition),
              "parser recovery must continue through variant records into record completion");
   end Test_Language_Model_Token_Cursor_Variant_Record_Component_Depth;





   procedure Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Discriminant_Part_Delimiters is" & ASCII.LF &
        "   type Well_Formed (Capacity : Positive; Initial : Natural := 0) is private;" & ASCII.LF &
        "   type Unknown (<>) is private;" & ASCII.LF &
        "   type Broken (Size : Positive; Index : Natural is private;" & ASCII.LF &
        "   type Next is null record;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Well_Formed (Capacity : Positive; Initial : Natural := 0) is null record;" & ASCII.LF &
        "   type Unknown is null record;" & ASCII.LF &
        "end Discriminant_Part_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part),
              "discriminant parts must still be retained structurally");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part_Open_Delimiter),
              "discriminant parts must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part_Close_Delimiter),
              "well-formed and unknown discriminant parts must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Specification_Separator),
              "known discriminant parts must retain specification separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Unknown_Discriminant_Part),
              "unknown discriminant parts must remain distinct from known discriminant specifications");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Discriminant_Part_Missing_Close_Recovery_Boundary),
              "malformed discriminant parts must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Type_Declaration_Terminator),
              "discriminant-part recovery must leave surrounding type declaration terminators available");
   end Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters;








   procedure Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Enumeration_Type_Delimiters is" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   type Marker is ('A', 'B');" & ASCII.LF &
        "   type Broken is (One, Two;" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Enumeration_Type_Delimiters;";
      Grammar : constant Editor.Ada_Token_Cursor.Grammar_Result :=
        Editor.Ada_Token_Cursor.Parse (Source);
   begin
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Type_Definition),
              "enumeration type definitions must remain structurally visible");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Type_Open_Delimiter),
              "enumeration type definitions must retain open delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Type_Close_Delimiter),
              "well-formed enumeration type definitions must retain close delimiter metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Literal_Separator),
              "enumeration literal lists must retain comma separator metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Enumeration_Type_Missing_Close_Recovery_Boundary),
              "malformed enumeration type definitions must retain bounded missing-close recovery metadata");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Object_Declaration),
              "enumeration type recovery must leave following declarations visible");
   end Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters;







   procedure Test_Language_Model_Token_Cursor_Subtype_Indication_Depth_Grammar_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Subtype_Indication_Depth is" & ASCII.LF &
        "   type Matrix is array (Positive range <>, Positive range <>) of Integer;" & ASCII.LF &
        "   type Box (Low, High : Integer) is null record;" & ASCII.LF &
        "   subtype NN is not null access Integer;" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 10;" & ASCII.LF &
        "   subtype Precise is Float digits 6 range -1.0 .. 1.0;" & ASCII.LF &
        "   subtype Fixed_Step is Duration delta 0.01 range 0.0 .. 1.0;" & ASCII.LF &
        "   subtype Slice is Matrix (1 .. 10, 2 .. 20);" & ASCII.LF &
        "   subtype Constrained_Box is Box (Low => 1, High => 10);" & ASCII.LF &
        "   subtype Bad_Index is Matrix (1 .. 10, );" & ASCII.LF &
        "   After : Integer := 0;" & ASCII.LF &
        "end Subtype_Indication_Depth;";
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
                (Editor.Ada_Token_Cursor.Production_Subtype_Mark) >= 8,
              "subtype indications must expose their subtype marks explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Null_Exclusion),
              "null exclusions in subtype indications must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Range_Constraint),
              "range constraints after subtype marks must be classified by subtype context");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Digits_Constraint),
              "digits constraints after subtype marks must be classified by subtype context");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Delta_Constraint),
              "delta constraints after subtype marks must be classified by subtype context");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Index_Constraint),
              "index constraints after subtype marks must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Subtype_Discriminant_Constraint),
              "named discriminant constraints after subtype marks must be retained explicitly");
      Assert (Editor.Ada_Token_Cursor.Has_Production
                (Grammar, Editor.Ada_Token_Cursor.Production_Constraint_Recovery_Boundary),
              "malformed subtype constraints must still expose bounded recovery boundaries");
      Assert (Count_Production
                (Editor.Ada_Token_Cursor.Production_Object_Declaration) >= 1,
              "subtype-constraint recovery must continue into following declarations");
   end Test_Language_Model_Token_Cursor_Subtype_Indication_Depth_Grammar_Completeness;


   overriding function Name (T : Token_Cursor_Type_Declaration_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Token_Cursor.Type_Declaration");
   end Name;

   overriding procedure Register_Tests (T : in out Token_Cursor_Type_Declaration_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Type_Definition_Grammar_Completeness'Access, Name => "token-cursor grammar parses complete Ada type definitions and constraints");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Scalar_Type_Definition_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains scalar type definition operands structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Derived_Type_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains derived type parent and interface internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Interface_Type_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains interface type parent internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Access_Definition_Gap_Grammar_Completeness'Access, Name => "token-cursor grammar parses access definitions in all declaration/profile contexts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness'Access, Name => "token-cursor grammar parses unconstrained array index subtype definitions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness'Access, Name => "token-cursor grammar parses modified tagged/private/interface type definitions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Incomplete_Type_Grammar_Completeness'Access, Name => "token-cursor grammar parses plain and tagged incomplete type declarations structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Unknown_Discriminant_Grammar_Completeness'Access, Name => "token-cursor grammar parses unknown discriminant parts structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Component_Definition_Grammar_Completeness'Access, Name => "token-cursor grammar parses record component definitions structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness'Access, Name => "token-cursor grammar parses named discriminant constraints structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subtype_Constraint_Grammar_Completeness'Access, Name => "token-cursor grammar parses digits and delta subtype constraints structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Array_Type_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses array type definitions deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Access_Type_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar parses access type definitions deeply");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Type_Declaration_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains type declaration internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discriminant_Specification_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains discriminant specification internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discriminant_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens discriminant known unknown access default and constraint coverage");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Variant_Record_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens variant record choice nested others and recovery coverage");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subtype_Declaration_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains subtype declaration internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Component_Declaration_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains component declaration internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Variant_Part_Internal_Grammar_Completeness'Access, Name => "token-cursor grammar retains variant part internals structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refinement_Depth'Access, Name => "token-cursor grammar deepens anonymous access-to-subprogram recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Grammar_Completeness'Access, Name => "token-cursor grammar parses anonymous access-to-subprogram profiles structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Variant_Record_Component_Depth'Access, Name => "token-cursor grammar deepens variant record component alternatives structurally");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters'Access, Name => "token-cursor grammar records discriminant part delimiters separators and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters'Access, Name => "token-cursor grammar records enumeration-type delimiters separators and recovery");
      Add_Test (Routine => Test_Language_Model_Token_Cursor_Subtype_Indication_Depth_Grammar_Completeness'Access, Name => "token-cursor grammar deepens subtype indication marks and constraint classification");
   end Register_Tests;

end Editor.Syntax_Semantics.Token_Cursor_Type_Declaration_Tests;
