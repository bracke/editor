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
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Limited_View_Rules;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Freezing_Interactions;
with Editor.Ada_Representation_Diagnostics;
with Editor.Ada_Expression_Diagnostics;
with Editor.Ada_Generic_Contract_Diagnostics;
with Editor.Ada_Cross_Unit_Diagnostics;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
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
use type Editor.Ada_Limited_View_Rules.Limited_View_Status;
use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
use type Editor.Ada_Representation_Legality.Address_Value_Status;
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

package body Editor.Syntax_Semantics.Core_Model_Metadata_Tests is




   procedure Test_Language_Model_Subtype_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Subtypes is" & ASCII.LF &
        "   type Index is range 1 .. 100;" & ASCII.LF &
        "   type Ref is access all Integer;" & ASCII.LF &
        "   subtype Small_Index is Index range 1 .. 10;" & ASCII.LF &
        "   subtype Ref_View is not null Ref;" & ASCII.LF &
        "end Subtypes;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "subtypes.ads");
      Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Small_Index");
      Ref_View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ref_View");
      Small_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Small_Id);
      Ref_View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_View_Id);
   begin
      Assert (Small_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subtype declaration should be parsed");
      Assert (Small_Info.Kind = Editor.Ada_Language_Model.Symbol_Subtype,
              "subtype declaration should keep subtype symbol kind");
      Assert (To_String (Small_Info.Target_Name) = "Index",
              "subtype declaration should retain its subtype mark as target metadata");
      Assert (Ref_View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "not-null access subtype declaration should be parsed");
      Assert (To_String (Ref_View_Info.Target_Name) = "Ref",
              "not-null subtype target metadata should skip the null-exclusion keywords");
   end Test_Language_Model_Subtype_Target_Metadata;


   procedure Test_Language_Model_Array_And_Access_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Composite_Targets is" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   type Table is array (Positive range <>) of Element;" & ASCII.LF &
        "   type Ref is access all Element;" & ASCII.LF &
        "   type Const_Ref is access constant Element;" & ASCII.LF &
        "   type Callback is access procedure (Item : Element);" & ASCII.LF &
        "end Composite_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "composite_targets.ads");
      Table_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Table");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ref");
      Const_Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Const_Ref");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback");
      Table_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Table_Id);
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
      Const_Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Const_Ref_Id);
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
   begin
      Assert (Table_Id /= Editor.Ada_Language_Model.No_Symbol,
              "array type declaration should be parsed");
      Assert (Table_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "array declaration should remain a type symbol");
      Assert (To_String (Table_Info.Target_Name) = "Element",
              "array type should retain component subtype target metadata");
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access-object type declaration should be parsed");
      Assert (To_String (Ref_Info.Target_Name) = "Element",
              "access all target metadata should skip the access qualifier");
      Assert (Const_Ref_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access constant type declaration should be parsed");
      Assert (To_String (Const_Ref_Info.Target_Name) = "Element",
              "access constant target metadata should skip the constant qualifier");
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access-to-subprogram type should still be parsed as a type");
      Assert (Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "access-to-subprogram declaration should remain a type symbol");
      Assert (To_String (Callback_Info.Target_Name) = "",
              "access-to-subprogram type should not invent a designated object target");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol,
              "access-to-subprogram profile names should remain suppressed");
   end Test_Language_Model_Array_And_Access_Type_Target_Metadata;



   procedure Test_Language_Model_Class_Wide_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Class_Wide_Targets is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   subtype Root_View is Root'Class;" & ASCII.LF &
        "   type Root_Array is array (Positive range <>) of Root'Class;" & ASCII.LF &
        "   type Root_Ref is access all Root'Class;" & ASCII.LF &
        "end Class_Wide_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "class_wide_targets.ads");
      View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_View");
      Array_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_Array");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_Ref");
      View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, View_Id);
      Array_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Array_Id);
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
   begin
      Assert (View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "class-wide subtype declaration should be parsed");
      Assert (To_String (View_Info.Target_Name) = "Root'Class",
              "subtype target metadata should retain the class-wide attribute");
      Assert (Array_Id /= Editor.Ada_Language_Model.No_Symbol,
              "class-wide array declaration should be parsed");
      Assert (To_String (Array_Info.Target_Name) = "Root'Class",
              "array component target metadata should retain the class-wide attribute");
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol,
              "class-wide access type declaration should be parsed");
      Assert (To_String (Ref_Info.Target_Name) = "Root'Class",
              "access object target metadata should retain the class-wide attribute");
   end Test_Language_Model_Class_Wide_Target_Metadata;




   procedure Test_Language_Model_Interface_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Interface_Targets is" & ASCII.LF &
        "   type Root is interface;" & ASCII.LF &
        "   type Limited_Root is limited interface;" & ASCII.LF &
        "   type Child is interface and Root;" & ASCII.LF &
        "   type Limited_Child is limited interface and Limited_Root;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Interface_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "interface_targets.ads");
      Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root");
      Limited_Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Limited_Root");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Limited_Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Limited_Child");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Root_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_Id);
      Limited_Root_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Limited_Root_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Limited_Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Limited_Child_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Root_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "plain interface declarations should parse as type symbols");
      Assert (To_String (Root_Info.Target_Name) = "",
              "root interface declarations should not invent parent target metadata");
      Assert (Limited_Root_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Limited_Root_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "limited interface declarations should parse as type symbols");
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Child_Info.Target_Name) = "Root",
              "interface derivation should retain parent interface target metadata");
      Assert (Limited_Child_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Limited_Child_Info.Target_Name) = "Limited_Root",
              "limited interface derivation should retain parent interface target metadata");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Parent_Symbol =
                Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Interface_Targets"),
              "interface declarations must not open parser scopes that capture following declarations");
   end Test_Language_Model_Interface_Type_Target_Metadata;



   procedure Test_Language_Model_Object_And_Component_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Targets is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Ref is access all Root'Class;" & ASCII.LF &
        "   Name, Label : String;" & ASCII.LF &
        "   Count : constant Natural := 1;" & ASCII.LF &
        "   View : not null access Root'Class;" & ASCII.LF &
        "   Boom : exception;" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Child : Root'Class;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Visit (Item : in out Root'Class);" & ASCII.LF &
        "end Object_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "object_targets.ads");
      Name_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Name");
      Label_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Label");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "View");
      Boom_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Boom");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Name_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Name_Id);
      Label_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Label_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, View_Id);
      Boom_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Boom_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Item_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Item_Id);
   begin
      Assert (Name_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object declaration should be parsed");
      Assert (To_String (Name_Info.Target_Name) = "String",
              "object target metadata should retain the declared subtype");
      Assert (Label_Id /= Editor.Ada_Language_Model.No_Symbol,
              "multi-name object declaration should parse all names");
      Assert (To_String (Label_Info.Target_Name) = "String",
              "multi-name object target metadata should be applied to each name");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol,
              "constant declaration should be parsed");
      Assert (To_String (Count_Info.Target_Name) = "Natural",
              "constant target metadata should skip the constant keyword");
      Assert (View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access object declaration should be parsed");
      Assert (To_String (View_Info.Target_Name) = "Root'Class",
              "object target metadata should skip null/access qualifiers and preserve class-wide attributes");
      Assert (Boom_Id /= Editor.Ada_Language_Model.No_Symbol,
              "exception declaration should be parsed");
      Assert (To_String (Boom_Info.Target_Name) = "",
              "exception declarations should not invent exception target metadata");
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record component should be parsed");
      Assert (To_String (Child_Info.Target_Name) = "Root'Class",
              "record component target metadata should preserve its component subtype");
      Assert (Item_Id /= Editor.Ada_Language_Model.No_Symbol,
              "subprogram parameter should be parsed");
      Assert (To_String (Item_Info.Target_Name) = "Root'Class",
              "profile parameter target metadata should preserve mode-stripped subtype metadata");
   end Test_Language_Model_Object_And_Component_Target_Metadata;



   procedure Test_Language_Model_Split_Object_And_Component_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Object_Targets is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   Name : String" & ASCII.LF &
        "      := ""demo"";" & ASCII.LF &
        "   Count : constant Natural" & ASCII.LF &
        "      := 1;" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Child : Root'Class" & ASCII.LF &
        "         := Root'(null record);" & ASCII.LF &
        "      Label : String" & ASCII.LF &
        "         with Volatile;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Split_Object_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_object_targets.ads");
      Name_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Name");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Label_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Label");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Name_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Name_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Label_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Label_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Name_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split object declaration should be parsed from the subtype header line");
      Assert (Name_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then To_String (Name_Info.Target_Name) = "String",
              "split object declaration should retain subtype target metadata");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split constant declaration should be parsed from the subtype header line");
      Assert (Count_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then To_String (Count_Info.Target_Name) = "Natural",
              "split constant declaration should retain subtype target metadata");
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split record component declaration should be parsed from the subtype header line");
      Assert (Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Child_Info.Parent_Symbol = Rec_Id
              and then To_String (Child_Info.Target_Name) = "Root'Class",
              "split record component should retain owner and component subtype metadata");
      Assert (Label_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split record component with aspect continuation should be parsed");
      Assert (Label_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Label_Info.Parent_Symbol = Rec_Id
              and then To_String (Label_Info.Target_Name) = "String",
              "split record component with aspect continuation should retain subtype metadata");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split object/component continuation lines must not corrupt following declarations");
   end Test_Language_Model_Split_Object_And_Component_Target_Metadata;



   procedure Test_Language_Model_Split_Subtype_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Subtypes is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   subtype Root_View is" & ASCII.LF &
        "      Root'Class;" & ASCII.LF &
        "   subtype Index is" & ASCII.LF &
        "      Positive range 1 .. 10;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Subtypes;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_subtypes.ads");
      Root_View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_View");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Root_View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_View_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Root_View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split subtype declaration should be parsed from the header line");
      Assert (Root_View_Info.Kind = Editor.Ada_Language_Model.Symbol_Subtype
              and then To_String (Root_View_Info.Target_Name) = "Root'Class",
              "split subtype declaration should retain class-wide subtype target metadata");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split range subtype declaration should be parsed from the header line");
      Assert (Index_Info.Kind = Editor.Ada_Language_Model.Symbol_Subtype
              and then To_String (Index_Info.Target_Name) = "Positive",
              "split subtype declaration should retain the base subtype before range metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split subtype continuation should still parse normally");
      Assert (After_Info.Parent_Symbol /= Root_View_Id
              and then After_Info.Parent_Symbol /= Index_Id,
              "split subtype continuation must not open a false subtype scope");
   end Test_Language_Model_Split_Subtype_Target_Metadata;



   procedure Test_Language_Model_Anonymous_Array_Object_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Anonymous_Array_Targets is" & ASCII.LF &
        "   Object_List : array (Positive range 1 .. 3) of Root'Class;" & ASCII.LF &
        "   Count_List : constant array (Natural range 1 .. 2) of Integer := (1, 2);" & ASCII.LF &
        "end Anonymous_Array_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "anonymous_array_targets.ads");
      Object_List_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Object_List");
      Count_List_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count_List");
      Object_List_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Object_List_Id);
      Count_List_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_List_Id);
   begin
      Assert (Object_List_Id /= Editor.Ada_Language_Model.No_Symbol,
              "anonymous array object should be parsed");
      Assert (Object_List_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "anonymous array declaration should remain an object symbol");
      Assert (To_String (Object_List_Info.Target_Name) = "Root'Class",
              "anonymous array object target metadata should retain the element subtype mark");
      Assert (Count_List_Id /= Editor.Ada_Language_Model.No_Symbol,
              "anonymous array constant object should be parsed");
      Assert (Count_List_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant,
              "anonymous array constant declaration should remain a constant symbol");
      Assert (To_String (Count_List_Info.Target_Name) = "Integer",
              "anonymous array constant target metadata should retain the element subtype mark");
   end Test_Language_Model_Anonymous_Array_Object_Target_Metadata;


   procedure Test_Language_Model_Pragma_Metadata_Does_Not_Pollute_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Pragma_Metadata is" & ASCII.LF &
        "   procedure Imported (X : Integer);" & ASCII.LF &
        "   pragma Import (C, Imported, ""imported"");" & ASCII.LF &
        "   function Compute return Integer;" & ASCII.LF &
        "   pragma Inline (Compute);" & ASCII.LF &
        "   Counter : Integer;" & ASCII.LF &
        "   pragma Atomic (Counter);" & ASCII.LF &
        "end Pragma_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "pragma_metadata.ads");
      Imported_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Imported");
      Compute_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compute");
      Counter_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Counter");
      Imported_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Imported_Id);
      Compute_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Compute_Id);
      Counter_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Counter_Id);
   begin
      Assert (Imported_Id /= Editor.Ada_Language_Model.No_Symbol,
              "pragma target procedure should parse");
      Assert (Compute_Id /= Editor.Ada_Language_Model.No_Symbol,
              "pragma target function should parse");
      Assert (Counter_Id /= Editor.Ada_Language_Model.No_Symbol,
              "pragma target object should parse");
      Assert (Imported_Info.Flags.Has_Pragma_Metadata,
              "Import pragma should be retained as metadata on the target declaration");
      Assert (Compute_Info.Flags.Has_Pragma_Metadata,
              "Inline pragma should be retained as metadata on the target declaration");
      Assert (Counter_Info.Flags.Has_Pragma_Metadata,
              "Atomic pragma should be retained as metadata on the target declaration");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Import") =
                Editor.Ada_Language_Model.No_Symbol,
              "pragma names must not become language-model symbols");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inline") =
                Editor.Ada_Language_Model.No_Symbol,
              "pragma identifiers must not pollute declaration lookup");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Atomic") =
                Editor.Ada_Language_Model.No_Symbol,
              "pragma names must not be classified as declarations");
   end Test_Language_Model_Pragma_Metadata_Does_Not_Pollute_Symbols;


   procedure Test_Language_Model_Pragma_Placement_And_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "pragma Restrictions (No_Tasking);" & ASCII.LF &
        "package body Pragma_Placement is" & ASCII.LF &
        "   procedure P is" & ASCII.LF &
        "      Ready : Boolean := True;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      pragma Assert (Check => Ready, Message => ""ready"");" & ASCII.LF &
        "      case 1 is" & ASCII.LF &
        "         when 1 =>" & ASCII.LF &
        "            pragma Assert (Check => Ready);" & ASCII.LF &
        "         when others =>" & ASCII.LF &
        "            null;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end P;" & ASCII.LF &
        "   pragma Inline (P);" & ASCII.LF &
        "end Pragma_Placement;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "pragma_placement.adb");
      Saw_Configuration : Boolean := False;
      Saw_Declaration   : Boolean := False;
      Saw_Statement     : Boolean := False;
      Saw_Alternative   : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Pragma_Metadata_Count (Analysis) = 4,
              "language model should retain each pragma occurrence as bounded metadata");

      for I in 1 .. Editor.Ada_Language_Model.Pragma_Metadata_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Pragma_Info :=
              Editor.Ada_Language_Model.Pragma_Metadata_At (Analysis, I);
            Name : constant String := To_String (Info.Normalized_Name);
            Target : constant String := To_String (Info.Normalized_Target_Name);
         begin
            if Info.Placement = Editor.Ada_Language_Model.Pragma_Placement_Configuration
              and then Name = "restrictions"
              and then Info.Argument_Count = 1
              and then Target = "no_tasking"
            then
               Saw_Configuration := True;
            elsif Info.Placement = Editor.Ada_Language_Model.Pragma_Placement_Declaration
              and then Name = "inline"
              and then Info.Argument_Count = 1
              and then Target = "p"
            then
               Saw_Declaration := True;
            elsif Info.Placement = Editor.Ada_Language_Model.Pragma_Placement_Statement
              and then Name = "assert"
              and then Info.Argument_Count = 2
              and then Info.Named_Argument_Count = 2
            then
               Saw_Statement := True;
            elsif Info.Placement = Editor.Ada_Language_Model.Pragma_Placement_Alternative
              and then Name = "assert"
              and then Info.Argument_Count = 1
              and then Info.Named_Argument_Count = 1
            then
               Saw_Alternative := True;
            end if;
         end;
      end loop;

      Assert (Saw_Configuration,
              "configuration pragma placement and first argument target should be retained");
      Assert (Saw_Declaration,
              "declarative pragma placement and entity target should be retained");
      Assert (Saw_Statement,
              "statement pragma placement and named argument count should be retained");
      Assert (Saw_Alternative,
              "pragma in an alternative sequence should retain alternative placement");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Assert") =
                Editor.Ada_Language_Model.No_Symbol,
              "pragma metadata must not introduce pragma-name declarations");
   end Test_Language_Model_Pragma_Placement_And_Target_Metadata;


   procedure Test_Language_Model_Function_Access_Subprogram_Result_Profile_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Function_Access_Results is" & ASCII.LF &
        "   function Make_Ref return access all Root'Class;" & ASCII.LF &
        "   function Make_Callback return access procedure (Item : Root'Class);" & ASCII.LF &
        "   function Make_Predicate return not null access function (Value : Root'Class) return Boolean;" & ASCII.LF &
        "   function Make_Protected_Callback return access protected procedure (Item : Root'Class);" & ASCII.LF &
        "   function Make_Protected_Predicate return access protected function (Value : Root'Class) return Boolean;" & ASCII.LF &
        "end Function_Access_Results;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "function_access_results.ads");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Ref");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Callback");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Predicate");
      Protected_Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Protected_Callback");
      Protected_Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Protected_Predicate");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Protected_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Protected_Callback_Id);
      Protected_Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Protected_Predicate_Id);
   begin
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Predicate_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Protected_Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Protected_Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "functions with anonymous access results should parse as functions");
      Assert (To_String (Ref_Info.Target_Name) = "Root'Class",
              "access-to-object function results should retain their designated subtype target");
      Assert (To_String (Callback_Info.Target_Name) = "",
              "access-to-procedure function results should not record procedure as a target subtype");
      Assert (To_String (Predicate_Info.Target_Name) = "",
              "access-to-function function results should not record function as a target subtype");
      Assert (To_String (Protected_Callback_Info.Target_Name) = "",
              "protected access-to-procedure function results should not record protected as a target subtype");
      Assert (To_String (Protected_Predicate_Info.Target_Name) = "",
              "protected access-to-function function results should not record protected as a target subtype");
      Assert (To_String (Callback_Info.Profile_Summary) =
                "procedure (Item : Root'Class)",
              "access-to-procedure function results should retain result callable profile metadata");
      Assert (To_String (Predicate_Info.Profile_Summary) =
                "function (Value : Root'Class) return Boolean",
              "access-to-function function results should retain result callable profile metadata");
      Assert (To_String (Protected_Callback_Info.Profile_Summary) =
                "protected procedure (Item : Root'Class)",
              "protected access-to-procedure function results should retain protected result callable profile metadata");
      Assert (To_String (Protected_Predicate_Info.Profile_Summary) =
                "protected function (Value : Root'Class) return Boolean",
              "protected access-to-function function results should retain protected result callable profile metadata");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "anonymous access-to-subprogram result profile parameters should remain metadata-only");
   end Test_Language_Model_Function_Access_Subprogram_Result_Profile_Metadata;



   procedure Test_Language_Model_Split_Access_Function_Result_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Access_Returns is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   function Make_Ref return access" & ASCII.LF &
        "      all Root'Class;" & ASCII.LF &
        "   function Convert" & ASCII.LF &
        "     (Item : Root'Class)" & ASCII.LF &
        "      return access" & ASCII.LF &
        "         constant Root;" & ASCII.LF &
        "   function Make_Callback return access" & ASCII.LF &
        "      procedure (Callback_Item : Root'Class);" & ASCII.LF &
        "   function Make_Predicate return access" & ASCII.LF &
        "      function (Predicate_Item : Root'Class) return Boolean;" & ASCII.LF &
        "   function Make_Protected_Callback return access" & ASCII.LF &
        "      protected procedure (Protected_Callback_Item : Root'Class);" & ASCII.LF &
        "   function Make_Protected_Predicate return access" & ASCII.LF &
        "      protected function (Protected_Predicate_Item : Root'Class) return Boolean;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Access_Returns;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "split_access_returns.ads");
      Make_Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Ref");
      Convert_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Convert");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Callback");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Predicate");
      Protected_Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Protected_Callback");
      Inline_Protected_Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Protected_Predicate");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Callback_Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback_Item");
      Predicate_Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate_Item");
      Protected_Callback_Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Protected_Callback_Item");
      Protected_Predicate_Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Protected_Predicate_Item");
      Make_Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Ref_Id);
      Convert_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Convert_Id);
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Protected_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Protected_Callback_Id);
      Inline_Protected_Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inline_Protected_Predicate_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
      Item_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Item_Id);
   begin
      Assert (Make_Ref_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split anonymous access-to-object result should parse from the function header");
      Assert (To_String (Make_Ref_Info.Target_Name) = "Root'Class",
              "split access result should retain designated class-wide subtype target metadata");
      Assert (Convert_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split profiled access-result function should parse");
      Assert (To_String (Convert_Info.Target_Name) = "Root",
              "split access result should skip constant/all/null qualifiers before the target subtype");
      Assert (Item_Info.Parent_Symbol = Convert_Id,
              "split access-result function parameters should remain parented to the function");
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Predicate_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Protected_Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inline_Protected_Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split anonymous access-to-subprogram results should parse");
      Assert (To_String (Callback_Info.Profile_Summary) =
                "procedure (Callback_Item : Root'Class)",
              "split access-to-procedure result should retain callable profile metadata");
      Assert (To_String (Predicate_Info.Profile_Summary) =
                "function (Predicate_Item : Root'Class) return Boolean",
              "split access-to-function result should retain callable profile metadata");
      Assert (To_String (Protected_Callback_Info.Target_Name) = ""
              and then To_String (Inline_Protected_Predicate_Info.Target_Name) = "",
              "split protected access-to-subprogram results should not record protected as a target subtype");
      Assert (To_String (Protected_Callback_Info.Profile_Summary) =
                "protected procedure (Protected_Callback_Item : Root'Class)",
              "split protected access-to-procedure result should retain protected callable profile metadata");
      Assert (To_String (Inline_Protected_Predicate_Info.Profile_Summary) =
                "protected function (Protected_Predicate_Item : Root'Class) return Boolean",
              "split protected access-to-function result should retain protected callable profile metadata");
      Assert (Callback_Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Predicate_Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Protected_Callback_Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Protected_Predicate_Item_Id = Editor.Ada_Language_Model.No_Symbol,
              "split access-to-subprogram result profile parameters should remain metadata-only");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split access-result continuation lines must not corrupt following declarations");
   end Test_Language_Model_Split_Access_Function_Result_Target_Metadata;


   procedure Test_Language_Model_Separate_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "separate (Parent.Child)" & ASCII.LF &
        "procedure Worker is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Worker;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "worker.adb");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Worker_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Worker_Id);
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol,
              "separate subprogram body should parse the body declaration");
      Assert (Worker_Info.Flags.Is_Separate,
              "separate subprogram body should carry the separate flag");
      Assert (To_String (Worker_Info.Target_Name) = "Parent.Child",
              "separate subprogram body should preserve parent unit metadata for later index linking");
   end Test_Language_Model_Separate_Target_Metadata;


   procedure Test_Language_Model_Add_Symbol_Fingerprint_Includes_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      function Fingerprint_For
        (Src_Range       : Editor.Ada_Language_Model.Source_Range;
         Declaration_Column : Positive := 1;
         Profile         : String := "";
         Target          : String := "";
         Flags           : Editor.Ada_Language_Model.Declaration_Flags := (others => False))
         return Natural
      is
         Analysis : Editor.Ada_Language_Model.Analysis_Result;
         Id       : Editor.Ada_Language_Model.Symbol_Id;
      begin
         Id := Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            "Render",
            Editor.Ada_Language_Model.Symbol_Procedure,
            Src_Range,
            Declaration_Column => Declaration_Column,
            Profile_Summary => Profile,
            Flags => Flags,
            Target_Name => Target);
         Assert (Id /= Editor.Ada_Language_Model.No_Symbol,
                 "test setup should insert one symbol");
         return Editor.Ada_Language_Model.Fingerprint (Analysis);
      end Fingerprint_For;

      Base_Range : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 10, Start_Column => 4, End_Line => 10, End_Column => 10);
      Base : constant Natural := Fingerprint_For (Base_Range);
      Private_Flags : constant Editor.Ada_Language_Model.Declaration_Flags :=
        (Is_Private => True, others => False);
   begin
      Assert
        (Base /= Fingerprint_For
           ((Start_Line => 10, Start_Column => 4, End_Line => 10, End_Column => 20)),
         "initial add-symbol fingerprint should include full source range");
      Assert
        (Base /= Fingerprint_For (Base_Range, Declaration_Column => 8),
         "initial add-symbol fingerprint should include declaration column");
      Assert
        (Base /= Fingerprint_For (Base_Range, Profile => "(Canvas : Surface)"),
         "initial add-symbol fingerprint should include profile summary");
      Assert
        (Base /= Fingerprint_For (Base_Range, Target => "Parent.Render"),
         "initial add-symbol fingerprint should include target metadata");
      Assert
        (Base /= Fingerprint_For (Base_Range, Flags => Private_Flags),
         "initial add-symbol fingerprint should include declaration flags");
   end Test_Language_Model_Add_Symbol_Fingerprint_Includes_Metadata;



   procedure Test_Language_Model_Fingerprint_Includes_Ownership_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      function Fingerprint_For
        (Child_Scope  : Editor.Ada_Language_Model.Scope_Id;
         Child_Parent : Editor.Ada_Language_Model.Symbol_Id) return Natural
      is
         Analysis : Editor.Ada_Language_Model.Analysis_Result;
         Owner_Id : Editor.Ada_Language_Model.Symbol_Id;
         Child_Id : Editor.Ada_Language_Model.Symbol_Id;
      begin
         Owner_Id := Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            "Owner",
            Editor.Ada_Language_Model.Symbol_Package,
            (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 5));
         Child_Id := Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            "Render",
            Editor.Ada_Language_Model.Symbol_Procedure,
            (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 10),
            Enclosing_Scope => Child_Scope,
            Parent_Symbol => Child_Parent);
         Assert (Owner_Id /= Editor.Ada_Language_Model.No_Symbol
                 and then Child_Id /= Editor.Ada_Language_Model.No_Symbol,
                 "test setup should insert owner and child symbols");
         return Editor.Ada_Language_Model.Fingerprint (Analysis);
      end Fingerprint_For;

      Owner_Scope : constant Editor.Ada_Language_Model.Scope_Id := 1;
      Owner_Parent : constant Editor.Ada_Language_Model.Symbol_Id := 1;
      Root_Owned : constant Natural :=
        Fingerprint_For
          (Editor.Ada_Language_Model.Root_Scope,
           Editor.Ada_Language_Model.No_Symbol);
      Scope_Owned : constant Natural :=
        Fingerprint_For
          (Owner_Scope,
           Editor.Ada_Language_Model.No_Symbol);
      Parent_Owned : constant Natural :=
        Fingerprint_For
          (Editor.Ada_Language_Model.Root_Scope,
           Owner_Parent);
      Fully_Owned : constant Natural :=
        Fingerprint_For (Owner_Scope, Owner_Parent);
   begin
      Assert (Root_Owned /= Scope_Owned,
              "language-model fingerprints should include enclosing scope metadata");
      Assert (Root_Owned /= Parent_Owned,
              "language-model fingerprints should include parent-symbol metadata");
      Assert (Scope_Owned /= Fully_Owned,
              "parent metadata should remain distinct even when enclosing scope already differs");
      Assert (Parent_Owned /= Fully_Owned,
              "scope metadata should remain distinct even when parent metadata already differs");
   end Test_Language_Model_Fingerprint_Includes_Ownership_Metadata;





   procedure Test_Language_Model_Context_Clauses_Are_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "limited private with Ada.Text_IO;" & ASCII.LF &
        "with Ada.Strings.Unbounded;" & ASCII.LF &
        "use type Ada.Strings.Unbounded.Unbounded_String;" & ASCII.LF &
        "package Context_Metadata is" & ASCII.LF &
        "   Item : Integer;" & ASCII.LF &
        "end Context_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "context_metadata.ads");
   begin
      Assert (Editor.Ada_Language_Model.Has_With_Clause_Awareness (Analysis),
              "with-context clauses should be retained as bounded analysis metadata");
      Assert (Editor.Ada_Language_Model.Has_Use_Clause_Awareness (Analysis),
              "use clauses should be retained as bounded analysis metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Context_Metadata") /=
                Editor.Ada_Language_Model.No_Symbol,
              "context/use clauses must not prevent ordinary Ada declaration parsing");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ada") =
                Editor.Ada_Language_Model.No_Symbol,
              "context clause package names must not become ordinary declaration symbols");
   end Test_Language_Model_Context_Clauses_Are_Metadata;





   procedure Test_Language_Model_Null_Exclusions_Are_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Null_Metadata is" & ASCII.LF &
        "   type Item is tagged null record;" & ASCII.LF &
        "   type Item_Access is not null access all Item;" & ASCII.LF &
        "   subtype Item_View is not null Item_Access;" & ASCII.LF &
        "   Current : not null Item_Access;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Formal : not null Item_Access;" & ASCII.LF &
        "   procedure Apply;" & ASCII.LF &
        "end Null_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "null_metadata.ads");
      Access_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item_Access");
      View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item_View");
      Current_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Current");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Access_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Access_Id);
      View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, View_Id);
      Current_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Current_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Access_Id /= Editor.Ada_Language_Model.No_Symbol,
              "not-null access type declaration should be parsed");
      Assert (Access_Info.Flags.Has_Null_Exclusion,
              "not-null access type should retain null-exclusion metadata");
      Assert (View_Id /= Editor.Ada_Language_Model.No_Symbol
              and then View_Info.Flags.Has_Null_Exclusion,
              "not-null subtype should retain null-exclusion metadata");
      Assert (Current_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Current_Info.Flags.Has_Null_Exclusion,
              "not-null object should retain null-exclusion metadata");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Flags.Has_Null_Exclusion,
              "not-null generic formal object should retain null-exclusion metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "null") =
                Editor.Ada_Language_Model.No_Symbol,
              "null-exclusion keywords must not become declaration symbols");
   end Test_Language_Model_Null_Exclusions_Are_Metadata;



   procedure Test_Language_Model_Aliased_Metadata_Does_Not_Pollute_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Aliased_Metadata is" & ASCII.LF &
        "   type Item is tagged null record;" & ASCII.LF &
        "   type Item_Access is access all Item;" & ASCII.LF &
        "   Current : aliased Item;" & ASCII.LF &
        "   Slot : aliased not null Item_Access;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Formal : aliased Item;" & ASCII.LF &
        "   procedure Apply;" & ASCII.LF &
        "end Aliased_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "aliased_metadata.ads");
      Current_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Current");
      Slot_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Slot");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Current_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Current_Id);
      Slot_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Slot_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Current_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Current_Info.Flags.Has_Aliased_Metadata,
              "aliased object declaration should retain aliased metadata");
      Assert (Slot_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Slot_Info.Flags.Has_Aliased_Metadata
              and then Slot_Info.Flags.Has_Null_Exclusion,
              "aliased not-null object should retain both declaration metadata flags");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Flags.Has_Aliased_Metadata,
              "aliased generic formal object should retain aliased metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "aliased") =
                Editor.Ada_Language_Model.No_Symbol,
              "aliased keyword must not become a declaration symbol");
   end Test_Language_Model_Aliased_Metadata_Does_Not_Pollute_Symbols;





   procedure Test_Language_Model_Type_Qualifier_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Type_Qualifier_Metadata is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Hidden is limited private;" & ASCII.LF &
        "   type Iface is limited interface;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Formal is tagged private;" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Type_Qualifier_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "type_qualifier_metadata.ads");
      Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root");
      Hidden_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hidden");
      Iface_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Iface");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Root_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_Id);
      Hidden_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Id);
      Iface_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Iface_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Root_Info.Flags.Has_Tagged_Metadata,
              "tagged type declaration should retain tagged metadata");
      Assert (Hidden_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Info.Flags.Has_Limited_Metadata,
              "limited private type declaration should retain limited metadata");
      Assert (Iface_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Iface_Info.Flags.Has_Limited_Metadata
              and then Iface_Info.Flags.Has_Interface_Metadata,
              "limited interface declaration should retain both qualifier flags");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Formal_Info.Flags.Has_Tagged_Metadata,
              "generic formal tagged type should retain qualifier metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "tagged") =
                Editor.Ada_Language_Model.No_Symbol,
              "tagged keyword must not become a declaration symbol");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "interface") =
                Editor.Ada_Language_Model.No_Symbol,
              "interface keyword must not become a declaration symbol");
   end Test_Language_Model_Type_Qualifier_Metadata;



   procedure Test_Language_Model_Synchronized_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Synchronized_Metadata is" & ASCII.LF &
        "   type Sync_Iface is synchronized interface;" & ASCII.LF &
        "   type Limited_Sync is limited synchronized interface;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Formal is synchronized interface;" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Synchronized_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "synchronized_metadata.ads");
      Sync_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Sync_Iface");
      Limited_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Limited_Sync");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Sync_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Sync_Id);
      Limited_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Limited_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Sync_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Sync_Info.Flags.Has_Interface_Metadata
              and then Sync_Info.Flags.Has_Synchronized_Metadata,
              "synchronized interface should retain synchronized metadata");
      Assert (Limited_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Limited_Info.Flags.Has_Limited_Metadata
              and then Limited_Info.Flags.Has_Interface_Metadata
              and then Limited_Info.Flags.Has_Synchronized_Metadata,
              "limited synchronized interface should retain all qualifier metadata");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Formal_Info.Flags.Has_Synchronized_Metadata,
              "generic formal synchronized interface should retain synchronized metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "synchronized") =
                Editor.Ada_Language_Model.No_Symbol,
              "synchronized keyword must not become a declaration symbol");
   end Test_Language_Model_Synchronized_Metadata;



   procedure Test_Language_Model_Access_And_Array_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Array_Metadata is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   type Item_Access is access all Item;" & ASCII.LF &
        "   type Item_Table is array (Positive range <>) of Item;" & ASCII.LF &
        "   Values : array (Positive range <>) of Item;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Formal : access Item;" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Access_Array_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "access_array_metadata.ads");
      Access_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item_Access");
      Array_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item_Table");
      Values_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Values");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Access_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Access_Id);
      Array_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Array_Id);
      Values_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Values_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Access_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Access_Info.Flags.Has_Access_Metadata,
              "access type declaration should retain access metadata");
      Assert (Array_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Array_Info.Flags.Has_Array_Metadata,
              "array type declaration should retain array metadata");
      Assert (Values_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Values_Info.Flags.Has_Array_Metadata,
              "anonymous array object declaration should retain array metadata");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Formal_Info.Flags.Has_Access_Metadata,
              "generic formal access object should retain access metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "access") =
                Editor.Ada_Language_Model.No_Symbol,
              "access keyword must not become a declaration symbol");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "array") =
                Editor.Ada_Language_Model.No_Symbol,
              "array keyword must not become a declaration symbol");
   end Test_Language_Model_Access_And_Array_Metadata;



   procedure Test_Language_Model_Derived_Type_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Derived_Metadata is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Child is new Root with null record;" & ASCII.LF &
        "   type Private_Child is new Root with private;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Formal is new Root with private;" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Derived_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "derived_metadata.ads");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Private_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Private_Child");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Private_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Private_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_Info.Flags.Has_Derived_Metadata,
              "derived record extension should retain derived metadata");
      Assert (Private_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Private_Info.Flags.Has_Derived_Metadata
              and then Private_Info.Flags.Is_Private,
              "private derived type should retain derived and private metadata");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Formal_Info.Flags.Has_Derived_Metadata,
              "generic formal derived type should retain derived metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "new") =
                Editor.Ada_Language_Model.No_Symbol,
              "new keyword must not become a declaration symbol");
   end Test_Language_Model_Derived_Type_Metadata;



   procedure Test_Language_Model_Scalar_Type_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Scalar_Metadata is" & ASCII.LF &
        "   type Small is range 0 .. 10;" & ASCII.LF &
        "   type Word is mod 2 ** 32;" & ASCII.LF &
        "   type Real is digits 10;" & ASCII.LF &
        "   type Money is delta 0.01 digits 18;" & ASCII.LF &
        "   subtype Index is Integer range 1 .. 100;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Formal is range <>;" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Scalar_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "scalar_metadata.ads");
      Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Small");
      Word_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Word");
      Real_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Real");
      Money_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Money");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal");
      Small_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Small_Id);
      Word_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Word_Id);
      Real_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Real_Id);
      Money_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Money_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
   begin
      Assert (Small_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Small_Info.Flags.Has_Range_Metadata,
              "signed integer type should retain range metadata");
      Assert (Word_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Word_Info.Flags.Has_Modular_Metadata,
              "modular type should retain mod metadata");
      Assert (Real_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Real_Info.Flags.Has_Digits_Metadata,
              "floating point type should retain digits metadata");
      Assert (Money_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Money_Info.Flags.Has_Delta_Metadata
              and then Money_Info.Flags.Has_Digits_Metadata,
              "fixed point type should retain delta and digits metadata");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Index_Info.Flags.Has_Range_Metadata,
              "range-constrained subtype should retain range metadata");
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Type
              and then Formal_Info.Flags.Has_Range_Metadata,
              "generic formal scalar type should retain range metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "range") =
                Editor.Ada_Language_Model.No_Symbol,
              "range keyword must not become a declaration symbol");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "digits") =
                Editor.Ada_Language_Model.No_Symbol,
              "digits keyword must not become a declaration symbol");
   end Test_Language_Model_Scalar_Type_Metadata;



   procedure Test_Language_Model_Variant_Record_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Variant_Metadata is" & ASCII.LF &
        "   type Kind is (By_Count, By_Name);" & ASCII.LF &
        "   type Shape (K : Kind) is record" & ASCII.LF &
        "      case K is" & ASCII.LF &
        "         when By_Count => Count : Integer;" & ASCII.LF &
        "         when By_Name  => Name  : Integer;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Plain is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Inline (K : Kind) is record case K is when others => null; end case; end record;" & ASCII.LF &
        "end Variant_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "variant_record_metadata.ads");
      Shape_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Shape");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Inline_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inline");
      Shape_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Shape_Id);
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
      Inline_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inline_Id);
   begin
      Assert (Shape_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Shape_Info.Flags.Has_Variant_Record_Metadata,
              "multi-line variant record should retain variant-record metadata");
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Plain_Info.Flags.Has_Variant_Record_Metadata,
              "plain record should not be marked as a variant record");
      Assert (Inline_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inline_Info.Flags.Has_Variant_Record_Metadata,
              "same-line variant record should retain variant-record metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "case") =
                Editor.Ada_Language_Model.No_Symbol,
              "variant case keyword must not become a declaration symbol");
   end Test_Language_Model_Variant_Record_Metadata;



   procedure Test_Language_Model_Entry_Family_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Entries is" & ASCII.LF &
        "   protected type Queue is" & ASCII.LF &
        "      entry Plain (Item : Integer);" & ASCII.LF &
        "      entry Family (Positive) (Item : Integer);" & ASCII.LF &
        "      entry Ranged (Positive range <>) (Item : Integer);" & ASCII.LF &
        "   end Queue;" & ASCII.LF &
        "end Entries;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "entry_family_metadata.ads");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Family_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Family");
      Ranged_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ranged");
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
      Family_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Family_Id);
      Ranged_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ranged_Id);
   begin
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Plain_Info.Flags.Has_Entry_Family_Metadata,
              "ordinary entry parameter profiles should not be marked as entry families");
      Assert (Family_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Family_Info.Flags.Has_Entry_Family_Metadata,
              "entry family index groups should remain declaration metadata");
      Assert (Ranged_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Ranged_Info.Flags.Has_Entry_Family_Metadata,
              "ranged entry family index groups should remain declaration metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Positive") =
                Editor.Ada_Language_Model.No_Symbol,
              "entry-family index subtype must not become a declaration symbol");
   end Test_Language_Model_Entry_Family_Metadata;





   procedure Test_Language_Model_Incomplete_Type_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Incomplete_Types is" & ASCII.LF &
        "   type Node;" & ASCII.LF &
        "   type Root is tagged;" & ASCII.LF &
        "   type Complete is tagged null record;" & ASCII.LF &
        "   type Node_Access is access Node;" & ASCII.LF &
        "end Incomplete_Types;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "incomplete_type_metadata.ads");
      Node_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Node");
      Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root");
      Complete_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Complete");
      Node_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Node_Id);
      Root_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_Id);
      Complete_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Complete_Id);
   begin
      Assert (Node_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Node_Info.Flags.Has_Incomplete_Type_Metadata,
              "ordinary incomplete type declarations should remain metadata");
      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Root_Info.Flags.Has_Incomplete_Type_Metadata
              and then Root_Info.Flags.Has_Tagged_Metadata,
              "tagged incomplete type declarations should retain both metadata flags");
      Assert (Complete_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Complete_Info.Flags.Has_Incomplete_Type_Metadata,
              "complete tagged record declarations must not be marked incomplete");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "tagged") =
                Editor.Ada_Language_Model.No_Symbol,
              "incomplete type syntax must not pollute symbol lookup");
   end Test_Language_Model_Incomplete_Type_Metadata;



   procedure Test_Language_Model_Profile_Mode_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Profile_Modes is" & ASCII.LF &
        "   procedure Update (Item : in out Integer; Sink : out Integer);" & ASCII.LF &
        "   function Visit (Handle : access Integer) return Boolean;" & ASCII.LF &
        "   procedure Plain (Item : Integer);" & ASCII.LF &
        "end Profile_Modes;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "profile_mode_metadata.ads");
      Update_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Update");
      Visit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Visit");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Update_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Update_Id);
      Visit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Visit_Id);
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
   begin
      Assert (Update_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Update_Info.Flags.Has_Profile_Mode_Metadata,
              "explicit in-out/out parameter modes should remain declaration metadata");
      Assert (Visit_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Visit_Info.Flags.Has_Profile_Mode_Metadata,
              "anonymous access parameters should remain profile-mode metadata");
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Plain_Info.Flags.Has_Profile_Mode_Metadata,
              "plain default-in parameters should not be marked as explicit profile modes");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "out") =
                Editor.Ada_Language_Model.No_Symbol,
              "parameter-mode keywords must not pollute symbol lookup");
   end Test_Language_Model_Profile_Mode_Metadata;



   procedure Test_Language_Model_Entry_Barrier_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Guarded is" & ASCII.LF &
        "   entry Wait (Item : Integer) when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Wait;" & ASCII.LF &
        "   entry Plain (Item : Integer) is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Plain;" & ASCII.LF &
        "end Guarded;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "entry_barrier_metadata.adb");
      Wait_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Wait");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Wait_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Wait_Id);
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
   begin
      Assert (Wait_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Wait_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Wait_Info.Flags.Has_Entry_Barrier_Metadata,
              "entry bodies with when barriers should retain bounded barrier metadata");
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Plain_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then not Plain_Info.Flags.Has_Entry_Barrier_Metadata,
              "entry bodies without when barriers must not be marked as barrier entries");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ready") =
                Editor.Ada_Language_Model.No_Symbol,
              "entry barrier expressions must not pollute declaration lookup");
   end Test_Language_Model_Entry_Barrier_Metadata;



   procedure Test_Language_Model_Access_Mode_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Modes is" & ASCII.LF &
        "   type Variable_Ref is access all Item;" & ASCII.LF &
        "   type Constant_Ref is access constant Item;" & ASCII.LF &
        "   Holder : access all Item;" & ASCII.LF &
        "   Reader : access constant Item;" & ASCII.LF &
        "   Plain : access Item;" & ASCII.LF &
        "end Access_Modes;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "access_modes.ads");
      Variable_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Variable_Ref");
      Constant_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Constant_Ref");
      Holder_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Holder");
      Reader_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Reader");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Variable_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Variable_Id);
      Constant_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Constant_Id);
      Holder_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Holder_Id);
      Reader_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Reader_Id);
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
   begin
      Assert (Variable_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Variable_Info.Flags.Has_Access_Metadata
              and then Variable_Info.Flags.Has_Access_All_Metadata
              and then not Variable_Info.Flags.Has_Access_Constant_Metadata,
              "access all type declarations should retain access-all metadata");
      Assert (Constant_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Constant_Info.Flags.Has_Access_Metadata
              and then Constant_Info.Flags.Has_Access_Constant_Metadata
              and then not Constant_Info.Flags.Has_Access_All_Metadata,
              "access constant type declarations should retain access-constant metadata");
      Assert (Holder_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Holder_Info.Flags.Has_Access_All_Metadata,
              "anonymous access-all object declarations should retain access mode metadata");
      Assert (Reader_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Reader_Info.Flags.Has_Access_Constant_Metadata,
              "anonymous access-constant object declarations should retain access mode metadata");
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Plain_Info.Flags.Has_Access_Metadata
              and then not Plain_Info.Flags.Has_Access_All_Metadata
              and then not Plain_Info.Flags.Has_Access_Constant_Metadata,
              "plain access declarations should not be marked as access-all or access-constant");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "all") =
                Editor.Ada_Language_Model.No_Symbol,
              "access mode keywords must not pollute symbol lookup");
   end Test_Language_Model_Access_Mode_Metadata;



   procedure Test_Language_Model_Class_Wide_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Class_Wide_Metadata is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Root_Access is access all Root'Class;" & ASCII.LF &
        "   View : Root'Class;" & ASCII.LF &
        "   procedure Visit (Item : in out Root'Class);" & ASCII.LF &
        "   Plain : Root;" & ASCII.LF &
        "end Class_Wide_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "class_wide_metadata.ads");
      Access_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_Access");
      View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "View");
      Visit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Visit");
      Plain_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Plain");
      Access_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Access_Id);
      View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, View_Id);
      Visit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Visit_Id);
      Plain_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plain_Id);
   begin
      Assert (Access_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Access_Info.Flags.Has_Access_Metadata
              and then Access_Info.Flags.Has_Class_Wide_Metadata,
              "access-to-class-wide type declarations should retain class-wide metadata");
      Assert (View_Id /= Editor.Ada_Language_Model.No_Symbol
              and then View_Info.Flags.Has_Class_Wide_Metadata,
              "class-wide object declarations should retain bounded metadata");
      Assert (Visit_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Visit_Info.Flags.Has_Class_Wide_Metadata,
              "class-wide profile subtype marks should retain bounded metadata on the callable declaration");
      Assert (Plain_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Plain_Info.Flags.Has_Class_Wide_Metadata,
              "ordinary specific-type declarations must not be marked class-wide");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Class") =
                Editor.Ada_Language_Model.No_Symbol,
              "class-wide attribute designators must not pollute declaration lookup");
   end Test_Language_Model_Class_Wide_Metadata;



   procedure Test_Language_Model_Box_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Index is range <>;" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   Defaulted : in Integer := <>;" & ASCII.LF &
        "   with package Vectors is new Generic_Vectors (<>);" & ASCII.LF &
        "package Boxed_Formals is" & ASCII.LF &
        "   type Table is array (Index range <>) of Element;" & ASCII.LF &
        "end Boxed_Formals;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "box_metadata.ads");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Vectors_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Vectors");
      Table_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Table");
      Defaulted_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Defaulted");
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      Vectors_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Vectors_Id);
      Table_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Table_Id);
      Defaulted_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Defaulted_Id);
   begin
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Index_Info.Flags.Has_Box_Metadata,
              "generic formal scalar boxes should remain bounded metadata");
      Assert (Vectors_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Vectors_Info.Flags.Has_Box_Metadata,
              "generic formal package actual boxes should remain bounded metadata");
      Assert (Table_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Table_Info.Flags.Has_Box_Metadata
              and then Table_Info.Flags.Has_Array_Metadata,
              "unconstrained array boxes should compose with array metadata");
      Assert (Defaulted_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Defaulted_Info.Flags.Has_Box_Metadata
              and then Defaulted_Info.Flags.Has_Default_Expression_Metadata,
              "default-expression boxes should compose with initializer metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Generic_Vectors") =
                Editor.Ada_Language_Model.No_Symbol,
              "box syntax and generic actual expressions must not pollute declaration lookup");
   end Test_Language_Model_Box_Metadata;



   procedure Test_Language_Model_Split_Access_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   type Element_Ref is access" & ASCII.LF &
        "      all Element;" & ASCII.LF &
        "package Split_Access is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Root_Ref is access" & ASCII.LF &
        "      all Root'Class;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Split_Access;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_access.ads");
      Element_Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element_Ref");
      Root_Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_Ref");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Element_Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Ref_Id);
      Root_Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_Ref_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Element_Ref_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "split generic formal access type should remain a formal type symbol");
      Assert (Element_Ref_Info.Flags.Is_Generic,
              "split generic formal access type should retain generic metadata");
      Assert (To_String (Element_Ref_Info.Target_Name) = "Element",
              "split generic formal access type should retain designated subtype target metadata");
      Assert (Root_Ref_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "split ordinary access type should remain a type symbol");
      Assert (To_String (Root_Ref_Info.Target_Name) = "Root'Class",
              "split ordinary access type should retain class-wide designated subtype target metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split access target continuation should still be parsed normally");
      Assert (After_Info.Parent_Symbol /= Root_Ref_Id,
              "split access target continuation must not open a false type scope");
   end Test_Language_Model_Split_Access_Type_Target_Metadata;





   procedure Test_Language_Model_Split_Access_Subprogram_Type_Profile_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Formal_Callback is access" & ASCII.LF &
        "      procedure (Item : Element);" & ASCII.LF &
        "package Split_Access_Subprograms is" & ASCII.LF &
        "   type Callback is access" & ASCII.LF &
        "      procedure (Item : Integer; Count : Natural);" & ASCII.LF &
        "   type Predicate is access" & ASCII.LF &
        "      function (Value : Integer) return Boolean;" & ASCII.LF &
        "   type Protected_Callback is access" & ASCII.LF &
        "      protected procedure (Item : Element);" & ASCII.LF &
        "   type Inline_Protected_Predicate is access protected function (Value : Element) return Boolean;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Split_Access_Subprograms;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "split_access_subprograms.ads");
      Formal_Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Callback");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate");
      Protected_Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Protected_Callback");
      Inline_Protected_Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inline_Protected_Predicate");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Formal_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Callback_Id);
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Protected_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Protected_Callback_Id);
      Inline_Protected_Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inline_Protected_Predicate_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Formal_Callback_Info.Kind =
                Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "split generic formal access-to-subprogram type should remain a formal type");
      Assert (Formal_Callback_Info.Flags.Is_Generic,
              "split generic formal access-to-subprogram type should retain generic metadata");
      Assert (To_String (Formal_Callback_Info.Profile_Summary) =
                "procedure (Item : Element)",
              "split generic formal access-to-subprogram type should retain its profile summary");
      Assert (Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Type
              and then Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "split access-to-subprogram declarations should remain type symbols");
      Assert (To_String (Callback_Info.Profile_Summary) =
                "procedure (Item : Integer; Count : Natural)",
              "split access-to-procedure type should retain callable profile metadata");
      Assert (To_String (Predicate_Info.Profile_Summary) =
                "function (Value : Integer) return Boolean",
              "split access-to-function type should retain callable profile metadata");
      Assert (To_String (Protected_Callback_Info.Profile_Summary) =
                "protected procedure (Item : Element)",
              "split protected access-to-procedure type should retain protected callable profile metadata");
      Assert (To_String (Inline_Protected_Predicate_Info.Profile_Summary) =
                "protected function (Value : Element) return Boolean",
              "same-line protected access-to-function type should retain protected callable profile metadata");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Count_Id = Editor.Ada_Language_Model.No_Symbol
              and then Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "split access-to-subprogram profiles must not create child parameter symbols");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split access-to-subprogram profile metadata must not corrupt following declarations");
   end Test_Language_Model_Split_Access_Subprogram_Type_Profile_Metadata;


   procedure Test_Language_Model_Split_Array_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   type Element_Array is array" & ASCII.LF &
        "      (Positive range <>) of Element;" & ASCII.LF &
        "package Split_Array is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Root_Array is array" & ASCII.LF &
        "      (Positive range <>) of Root'Class;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Split_Array;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_array.ads");
      Element_Array_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element_Array");
      Root_Array_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root_Array");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Element_Array_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Array_Id);
      Root_Array_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Root_Array_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Element_Array_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "split generic formal array type should remain a formal type symbol");
      Assert (Element_Array_Info.Flags.Is_Generic,
              "split generic formal array type should retain generic metadata");
      Assert (To_String (Element_Array_Info.Target_Name) = "Element",
              "split generic formal array type should retain element subtype target metadata");
      Assert (Root_Array_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "split ordinary array type should remain a type symbol");
      Assert (To_String (Root_Array_Info.Target_Name) = "Root'Class",
              "split ordinary array type should retain class-wide element target metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split array target continuation should still be parsed normally");
      Assert (After_Info.Parent_Symbol /= Root_Array_Id,
              "split array target continuation must not open a false type scope");
   end Test_Language_Model_Split_Array_Type_Target_Metadata;



   procedure Test_Language_Model_Split_Anonymous_Array_Object_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Anon_Array is" & ASCII.LF &
        "   Object_List : array" & ASCII.LF &
        "      (Positive range <>) of Root'Class;" & ASCII.LF &
        "   Count_List : constant array" & ASCII.LF &
        "      (Natural range <>) of Integer;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Anon_Array;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_anon_array.ads");
      Object_List_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Object_List");
      Count_List_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count_List");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Object_List_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Object_List_Id);
      Count_List_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_List_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Object_List_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split anonymous array object should remain an object symbol");
      Assert (To_String (Object_List_Info.Target_Name) = "Root'Class",
              "split anonymous array object should retain element subtype target metadata");
      Assert (Count_List_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant,
              "split anonymous array constant should remain a constant symbol");
      Assert (To_String (Count_List_Info.Target_Name) = "Integer",
              "split anonymous array constant should retain element subtype target metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split anonymous array continuation should still parse normally");
      Assert (After_Info.Parent_Symbol /= Object_List_Id
              and then After_Info.Parent_Symbol /= Count_List_Id,
              "split anonymous array object continuation must not open a false object scope");
   end Test_Language_Model_Split_Anonymous_Array_Object_Target_Metadata;



   procedure Test_Language_Model_Split_Anonymous_Access_Object_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Anon_Access is" & ASCII.LF &
        "   View : access" & ASCII.LF &
        "      all Root'Class;" & ASCII.LF &
        "   Shared_View : constant access" & ASCII.LF &
        "      constant Shared_Root;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Anon_Access;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_anon_access.ads");
      View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "View");
      Shared_View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Shared_View");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, View_Id);
      Shared_View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Shared_View_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split anonymous access object should be parsed");
      Assert (View_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split anonymous access declaration should remain an object symbol");
      Assert (To_String (View_Info.Target_Name) = "Root'Class",
              "split anonymous access object should retain designated subtype target metadata");
      Assert (Shared_View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split anonymous access constant should be parsed");
      Assert (Shared_View_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant,
              "split anonymous access constant declaration should remain a constant symbol");
      Assert (To_String (Shared_View_Info.Target_Name) = "Shared_Root",
              "split anonymous access constant should retain constant designated subtype metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split anonymous access continuation should still parse normally");
      Assert (After_Info.Parent_Symbol /= View_Id
              and then After_Info.Parent_Symbol /= Shared_View_Id,
              "split anonymous access object continuation must not open a false object scope");
   end Test_Language_Model_Split_Anonymous_Access_Object_Target_Metadata;



   procedure Test_Language_Model_Split_Rename_And_Instantiation_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Targets is" & ASCII.LF &
        "   package Integer_IO is new" & ASCII.LF &
        "      Ada.Text_IO.Integer_IO;" & ASCII.LF &
        "   package Old_IO renames" & ASCII.LF &
        "      Integer_IO;" & ASCII.LF &
        "   procedure Old_Put renames" & ASCII.LF &
        "      Integer_IO.Put;" & ASCII.LF &
        "   Base : aliased Natural;" & ASCII.LF &
        "   Object_Alias : Natural renames" & ASCII.LF &
        "      Base;" & ASCII.LF &
        "   Failure : exception renames" & ASCII.LF &
        "      Constraint_Error;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Targets;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_targets.ads");
      Integer_IO_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Integer_IO");
      Old_IO_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Old_IO");
      Old_Put_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Old_Put");
      Object_Alias_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Object_Alias");
      Failure_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Failure");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Integer_IO_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Integer_IO_Id);
      Old_IO_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Old_IO_Id);
      Old_Put_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Old_Put_Id);
      Object_Alias_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Object_Alias_Id);
      Failure_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Failure_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Integer_IO_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split package instantiation should be parsed");
      Assert (Integer_IO_Info.Kind = Editor.Ada_Language_Model.Symbol_Instantiation,
              "split package instantiation should keep instantiation kind");
      Assert (To_String (Integer_IO_Info.Target_Name) = "Ada.Text_IO.Integer_IO",
              "split package instantiation should retain generic unit target metadata");

      Assert (Old_IO_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split package rename should be parsed");
      Assert (Old_IO_Info.Kind = Editor.Ada_Language_Model.Symbol_Package,
              "split package rename should keep package semantic kind");
      Assert (Old_IO_Info.Flags.Is_Rename,
              "split package rename should retain rename flag");
      Assert (To_String (Old_IO_Info.Target_Name) = "Integer_IO",
              "split package rename should retain renamed unit target metadata");

      Assert (Old_Put_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split procedure rename should be parsed");
      Assert (Old_Put_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure,
              "split procedure rename should keep procedure semantic kind");
      Assert (Old_Put_Info.Flags.Is_Rename,
              "split procedure rename should retain rename flag");
      Assert (To_String (Old_Put_Info.Target_Name) = "Integer_IO.Put",
              "split procedure rename should retain selected target metadata");

      Assert (Object_Alias_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split object rename should be parsed");
      Assert (Object_Alias_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split object rename should keep object semantic kind");
      Assert (Object_Alias_Info.Flags.Is_Rename,
              "split object rename should retain rename flag");
      Assert (To_String (Object_Alias_Info.Target_Name) = "Base",
              "split object rename should retain renamed object target metadata");

      Assert (Failure_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split exception rename should be parsed");
      Assert (Failure_Info.Kind = Editor.Ada_Language_Model.Symbol_Exception,
              "split exception rename should keep exception semantic kind");
      Assert (Failure_Info.Flags.Is_Rename,
              "split exception rename should retain rename flag");
      Assert (To_String (Failure_Info.Target_Name) = "Constraint_Error",
              "split exception rename should retain renamed exception target metadata");

      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split rename/instantiation targets should still parse normally");
      Assert (After_Info.Parent_Symbol /= Integer_IO_Id
              and then After_Info.Parent_Symbol /= Old_IO_Id
              and then After_Info.Parent_Symbol /= Old_Put_Id
              and then After_Info.Parent_Symbol /= Object_Alias_Id
              and then After_Info.Parent_Symbol /= Failure_Id,
              "split rename/instantiation target continuation must not open a false scope");
   end Test_Language_Model_Split_Rename_And_Instantiation_Target_Metadata;



   procedure Test_Language_Model_Split_Derived_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is new" & ASCII.LF &
        "      Root with private;" & ASCII.LF &
        "package Split_Derived is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   type Child is new" & ASCII.LF &
        "      Root with record" & ASCII.LF &
        "         Value : Integer;" & ASCII.LF &
        "      end record;" & ASCII.LF &
        "   type View is new" & ASCII.LF &
        "      Root with private;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Derived;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_derived.ads");
      Element_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      View_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "View");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Value", Child_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Element_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      View_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, View_Id);
      Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Value_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Element_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal derived type should be parsed");
      Assert (Element_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "split generic formal derived type should remain a formal type symbol");
      Assert (Element_Info.Flags.Is_Generic,
              "split generic formal derived type should retain generic metadata");
      Assert (To_String (Element_Info.Target_Name) = "Root",
              "split generic formal derived type should retain parent target metadata");

      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split derived record extension should be parsed");
      Assert (Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type,
              "split derived record extension should upgrade to record type when continuation opens record");
      Assert (To_String (Child_Info.Target_Name) = "Root",
              "split derived record extension should retain parent target metadata");
      Assert (Value_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Value_Info.Parent_Symbol = Child_Id,
              "record components after split derived extension should be parented to the derived record type");

      Assert (View_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split derived private extension should be parsed");
      Assert (View_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "split derived private extension should remain a type symbol");
      Assert (To_String (View_Info.Target_Name) = "Root",
              "split derived private extension should retain parent target metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split derived type metadata should still parse normally");
      Assert (After_Info.Parent_Symbol /= Element_Id
              and then After_Info.Parent_Symbol /= Child_Id
              and then After_Info.Parent_Symbol /= View_Id,
              "split derived type metadata must not open false scopes except the real record extension scope");
   end Test_Language_Model_Split_Derived_Type_Target_Metadata;



   procedure Test_Language_Model_Split_Access_Subprogram_Object_Profile_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Subprogram_Objects is" & ASCII.LF &
        "   Handler : access" & ASCII.LF &
        "      procedure (Item : Element; Count : Natural);" & ASCII.LF &
        "   Predicate : constant access" & ASCII.LF &
        "      function (Value : Element) return Boolean;" & ASCII.LF &
        "   Inline_Handler : access procedure (Item : Element);" & ASCII.LF &
        "   Protected_Handler : access" & ASCII.LF &
        "      protected procedure (Item : Element);" & ASCII.LF &
        "   Inline_Protected_Predicate : access protected function (Value : Element) return Boolean;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Access_Subprogram_Objects;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "access_subprogram_objects.ads");
      Handler_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Handler");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate");
      Inline_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inline_Handler");
      Protected_Handler_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Protected_Handler");
      Inline_Protected_Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inline_Protected_Predicate");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Handler_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Handler_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Inline_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inline_Id);
      Protected_Handler_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Protected_Handler_Id);
      Inline_Protected_Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inline_Protected_Predicate_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Handler_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split access-to-subprogram object should be parsed");
      Assert (Handler_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "split access-to-subprogram object should remain an object symbol");
      Assert (To_String (Handler_Info.Profile_Summary) =
                "procedure (Item : Element; Count : Natural)",
              "split access-to-subprogram object should retain procedure profile metadata");

      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split constant access-to-subprogram object should be parsed");
      Assert (Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant,
              "split constant access-to-subprogram object should remain a constant symbol");
      Assert (To_String (Predicate_Info.Profile_Summary) =
                "function (Value : Element) return Boolean",
              "split access-to-subprogram object should retain function profile metadata");

      Assert (Inline_Id /= Editor.Ada_Language_Model.No_Symbol,
              "same-line access-to-subprogram object should be parsed");
      Assert (To_String (Inline_Info.Profile_Summary) =
                "procedure (Item : Element)",
              "same-line access-to-subprogram object should retain profile metadata");
      Assert (To_String (Protected_Handler_Info.Profile_Summary) =
                "protected procedure (Item : Element)",
              "split protected access-to-subprogram object should retain protected profile metadata");
      Assert (To_String (Inline_Protected_Predicate_Info.Profile_Summary) =
                "protected function (Value : Element) return Boolean",
              "same-line protected access-to-subprogram object should retain protected profile metadata");

      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "access-to-subprogram object profile parameters must remain metadata-only");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split access-to-subprogram object metadata should still parse normally");
      Assert (After_Info.Parent_Symbol /= Handler_Id
              and then After_Info.Parent_Symbol /= Predicate_Id
              and then After_Info.Parent_Symbol /= Inline_Id
              and then After_Info.Parent_Symbol /= Protected_Handler_Id
              and then After_Info.Parent_Symbol /= Inline_Protected_Predicate_Id,
              "access-to-subprogram object metadata must not open false scopes");
   end Test_Language_Model_Split_Access_Subprogram_Object_Profile_Metadata;



   procedure Test_Language_Model_Split_Interface_Type_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Formal_Interface is limited interface and" & ASCII.LF &
        "      Root_Interface;" & ASCII.LF &
        "package Split_Interface is" & ASCII.LF &
        "   type Root_Interface is limited interface;" & ASCII.LF &
        "   type Child_Interface is synchronized interface and" & ASCII.LF &
        "      Root_Interface;" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Split_Interface;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_interface.ads");
      Formal_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Interface");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child_Interface");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Formal_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Formal_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split generic formal interface type should be parsed");
      Assert (Formal_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "split generic formal interface should remain a formal type symbol");
      Assert (Formal_Info.Flags.Is_Generic,
              "split generic formal interface should retain generic metadata");
      Assert (To_String (Formal_Info.Target_Name) = "Root_Interface",
              "split generic formal interface should retain parent interface target metadata");

      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split interface extension should be parsed");
      Assert (Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "split interface extension should remain a type symbol");
      Assert (To_String (Child_Info.Target_Name) = "Root_Interface",
              "split interface extension should retain parent interface target metadata");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split interface metadata should still parse normally");
      Assert (After_Info.Parent_Symbol /= Formal_Id
              and then After_Info.Parent_Symbol /= Child_Id,
              "split interface metadata must not open false scopes");
   end Test_Language_Model_Split_Interface_Type_Target_Metadata;



   procedure Test_Language_Model_Profile_Access_Subprogram_Parameter_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Callback_Parameters is" & ASCII.LF &
        "   type Element is tagged null record;" & ASCII.LF &
        "   procedure Execute" & ASCII.LF &
        "     (Handler : access procedure (Item : Element);" & ASCII.LF &
        "      Predicate : access protected function (Value : Element) return Boolean);" & ASCII.LF &
        "   procedure Inline (Hook : access protected procedure (Item : Element));" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Callback_Parameters;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "callback_parameters.ads");
      Handler_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Handler");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate");
      Hook_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hook");
      G_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "G");
      H_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "H");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Handler_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Handler_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Hook_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hook_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Handler_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access-to-subprogram parameter should be parsed");
      Assert (Handler_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then To_String (Handler_Info.Target_Name) = ""
              and then To_String (Handler_Info.Profile_Summary) =
                "procedure (Item : Element)",
              "access-to-subprogram parameter should retain procedure profile metadata without subtype target");

      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "protected access-to-subprogram parameter should be parsed");
      Assert (Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then To_String (Predicate_Info.Target_Name) = ""
              and then To_String (Predicate_Info.Profile_Summary) =
                "protected function (Value : Element) return Boolean",
              "protected access-to-subprogram parameter should retain protected function profile metadata");

      Assert (Hook_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Hook_Info.Profile_Summary) =
                "protected procedure (Item : Element)",
              "inline protected access-to-subprogram parameter should retain protected procedure profile metadata");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "anonymous callback-profile parameters should remain metadata-only");
      Assert (After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after callback-parameter profiles should still parse normally");
   end Test_Language_Model_Profile_Access_Subprogram_Parameter_Metadata;



   procedure Test_Language_Model_Split_Access_Object_Parameter_Target_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Object_Parameters is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   procedure Use_Ref" & ASCII.LF &
        "     (Ref : access" & ASCII.LF &
        "        all Root'Class);" & ASCII.LF &
        "   After : Boolean;" & ASCII.LF &
        "end Access_Object_Parameters;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "access_object_parameters.ads");
      Use_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Use_Ref");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ref");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Use_Id /= Editor.Ada_Language_Model.No_Symbol,
              "callable owner should be parsed before split access-object parameter");
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split access-to-object parameter should be parsed");
      Assert (Ref_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Ref_Info.Parent_Symbol = Use_Id
              and then To_String (Ref_Info.Target_Name) = "Root'Class"
              and then To_String (Ref_Info.Profile_Summary) = "",
              "split access-to-object parameter should retain designated subtype target as parameter metadata");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "declaration after split access-object parameter should still parse normally");
   end Test_Language_Model_Split_Access_Object_Parameter_Target_Metadata;



   procedure Test_Language_Model_Subprogram_Profile_Parameter_Mode_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Profile_Parameter_Metadata is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   procedure Mixed" & ASCII.LF &
        "     (A, B : in out Integer := 0;" & ASCII.LF &
        "      Hook : access protected function (X : Root) return Boolean;" & ASCII.LF &
        "      Ref : aliased access all Root'Class);" & ASCII.LF &
        "   function Make (Seed : in Integer; Sink : out Root) return Root;" & ASCII.LF &
        "end Profile_Parameter_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "profile_parameter_metadata.ads");
      Mixed_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Mixed");
      Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make");
      A_Info : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
        Editor.Ada_Language_Model.Profile_Parameter_At (Analysis, Mixed_Id, 1);
      B_Info : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
        Editor.Ada_Language_Model.Profile_Parameter_At (Analysis, Mixed_Id, 2);
      Hook_Info : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
        Editor.Ada_Language_Model.Profile_Parameter_At (Analysis, Mixed_Id, 3);
      Ref_Info : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
        Editor.Ada_Language_Model.Profile_Parameter_At (Analysis, Mixed_Id, 4);
      Seed_Info : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
        Editor.Ada_Language_Model.Profile_Parameter_At (Analysis, Make_Id, 1);
      Sink_Info : constant Editor.Ada_Language_Model.Profile_Parameter_Info :=
        Editor.Ada_Language_Model.Profile_Parameter_At (Analysis, Make_Id, 2);
   begin
      Assert (Mixed_Id /= Editor.Ada_Language_Model.No_Symbol,
              "procedure with grouped profile parameters should be parsed");
      Assert (Make_Id /= Editor.Ada_Language_Model.No_Symbol,
              "function with profile parameters should be parsed");
      Assert (Editor.Ada_Language_Model.Profile_Parameter_Count
                (Analysis, Mixed_Id) = 4,
              "mixed profile should project each grouped and access parameter individually");
      Assert (Editor.Ada_Language_Model.Profile_Parameter_Count
                (Analysis, Make_Id) = 2,
              "function profile should project each parameter individually");

      Assert (To_String (A_Info.Name) = "A"
              and then A_Info.Mode = Editor.Ada_Language_Model.Profile_Parameter_In_Out
              and then A_Info.Group_Index = 1
              and then A_Info.Group_Position = 1
              and then A_Info.Group_Name_Count = 2
              and then A_Info.Has_Default_Expression
              and then To_String (A_Info.Default_Text) = "0",
              "first grouped in out parameter should retain mode/default/group metadata");
      Assert (To_String (B_Info.Name) = "B"
              and then B_Info.Mode = Editor.Ada_Language_Model.Profile_Parameter_In_Out
              and then B_Info.Group_Index = 1
              and then B_Info.Group_Position = 2
              and then B_Info.Group_Name_Count = 2
              and then B_Info.Has_Default_Expression,
              "second grouped in out parameter should retain independent group position metadata");
      Assert (To_String (Hook_Info.Name) = "Hook"
              and then Hook_Info.Has_Access_Definition
              and then Hook_Info.Has_Access_Subprogram_Profile
              and then Hook_Info.Mode = Editor.Ada_Language_Model.Profile_Parameter_Default_In,
              "access-to-subprogram parameter should retain access/profile metadata without becoming a nested parameter symbol");
      Assert (To_String (Ref_Info.Name) = "Ref"
              and then Ref_Info.Has_Aliased
              and then Ref_Info.Has_Access_Definition
              and then not Ref_Info.Has_Access_Subprogram_Profile
              and then To_String (Ref_Info.Type_Text) = "Root'Class",
              "aliased access-to-object parameter should retain access and designated-subtype metadata");
      Assert (To_String (Seed_Info.Name) = "Seed"
              and then Seed_Info.Mode = Editor.Ada_Language_Model.Profile_Parameter_In,
              "explicit in parameter should retain mode metadata");
      Assert (To_String (Sink_Info.Name) = "Sink"
              and then Sink_Info.Mode = Editor.Ada_Language_Model.Profile_Parameter_Out,
              "out parameter should retain mode metadata");
   end Test_Language_Model_Subprogram_Profile_Parameter_Mode_Metadata;


   overriding function Name (T : Core_Model_Metadata_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Core_Model.Metadata");
   end Name;

   overriding procedure Register_Tests (T : in out Core_Model_Metadata_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Subtype_Target_Metadata'Access, Name => "language model parser records subtype target metadata");
      Add_Test (Routine => Test_Language_Model_Array_And_Access_Type_Target_Metadata'Access, Name => "language model parser records array/access-object target metadata");
      Add_Test (Routine => Test_Language_Model_Class_Wide_Target_Metadata'Access, Name => "language model preserves class-wide target metadata");
      Add_Test (Routine => Test_Language_Model_Interface_Type_Target_Metadata'Access, Name => "language model parser retains interface parent target metadata");
      Add_Test (Routine => Test_Language_Model_Object_And_Component_Target_Metadata'Access, Name => "language model parser retains object/component subtype target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Object_And_Component_Target_Metadata'Access, Name => "language model parser retains split object/component subtype target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Subtype_Target_Metadata'Access, Name => "language model parser retains split subtype target metadata");
      Add_Test (Routine => Test_Language_Model_Anonymous_Array_Object_Target_Metadata'Access, Name => "language model parser retains anonymous array object element target metadata");
      Add_Test (Routine => Test_Language_Model_Pragma_Metadata_Does_Not_Pollute_Symbols'Access, Name => "language model parser retains entity pragmas as declaration metadata");
      Add_Test (Routine => Test_Language_Model_Pragma_Placement_And_Target_Metadata'Access, Name => "language model retains pragma placement target and argument metadata");
      Add_Test (Routine => Test_Language_Model_Function_Access_Subprogram_Result_Profile_Metadata'Access, Name => "language model parser retains anonymous access-subprogram result profile metadata");
      Add_Test (Routine => Test_Language_Model_Split_Access_Function_Result_Target_Metadata'Access, Name => "language model parser retains split anonymous access-to-object function result metadata");
      Add_Test (Routine => Test_Language_Model_Separate_Target_Metadata'Access, Name => "language model parser records separate parent targets");
      Add_Test (Routine => Test_Language_Model_Add_Symbol_Fingerprint_Includes_Metadata'Access, Name => "language model initial symbol fingerprints include metadata");
      Add_Test (Routine => Test_Language_Model_Fingerprint_Includes_Ownership_Metadata'Access, Name => "language model fingerprints include ownership metadata");
      Add_Test (Routine => Test_Language_Model_Context_Clauses_Are_Metadata'Access, Name => "language model parser retains context and use clause awareness metadata");
      Add_Test (Routine => Test_Language_Model_Null_Exclusions_Are_Metadata'Access, Name => "language model parser keeps null exclusions as declaration metadata");
      Add_Test (Routine => Test_Language_Model_Aliased_Metadata_Does_Not_Pollute_Symbols'Access, Name => "language model parser keeps aliased declarations as metadata");
      Add_Test (Routine => Test_Language_Model_Type_Qualifier_Metadata'Access, Name => "language model parser keeps type qualifiers as metadata");
      Add_Test (Routine => Test_Language_Model_Synchronized_Metadata'Access, Name => "language model parser keeps synchronized interface qualifiers as metadata");
      Add_Test (Routine => Test_Language_Model_Access_And_Array_Metadata'Access, Name => "language model parser keeps access and array declaration forms as metadata");
      Add_Test (Routine => Test_Language_Model_Derived_Type_Metadata'Access, Name => "language model parser keeps derived type declarations as metadata");
      Add_Test (Routine => Test_Language_Model_Scalar_Type_Metadata'Access, Name => "language model parser keeps scalar type forms as metadata");
      Add_Test (Routine => Test_Language_Model_Variant_Record_Metadata'Access, Name => "language model parser keeps variant records as metadata");
      Add_Test (Routine => Test_Language_Model_Entry_Family_Metadata'Access, Name => "language model parser keeps entry-family index groups as metadata");
      Add_Test (Routine => Test_Language_Model_Incomplete_Type_Metadata'Access, Name => "language model parser keeps incomplete type declarations as metadata");
      Add_Test (Routine => Test_Language_Model_Profile_Mode_Metadata'Access, Name => "language model parser keeps explicit parameter modes as metadata");
      Add_Test (Routine => Test_Language_Model_Entry_Barrier_Metadata'Access, Name => "language model parser keeps entry barrier conditions as metadata");
      Add_Test (Routine => Test_Language_Model_Access_Mode_Metadata'Access, Name => "language model keeps access-all/access-constant metadata");
      Add_Test (Routine => Test_Language_Model_Class_Wide_Metadata'Access, Name => "language model parser keeps class-wide subtype marks as metadata");
      Add_Test (Routine => Test_Language_Model_Box_Metadata'Access, Name => "language model parser keeps Ada box syntax as metadata");
      Add_Test (Routine => Test_Language_Model_Split_Access_Type_Target_Metadata'Access, Name => "language model parser retains split access type target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Access_Subprogram_Type_Profile_Metadata'Access, Name => "language model parser retains split access-to-subprogram type profile metadata");
      Add_Test (Routine => Test_Language_Model_Split_Array_Type_Target_Metadata'Access, Name => "language model parser retains split array type target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Anonymous_Array_Object_Target_Metadata'Access, Name => "language model parser retains split anonymous array object target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Anonymous_Access_Object_Target_Metadata'Access, Name => "language model parser retains split anonymous access object target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Rename_And_Instantiation_Target_Metadata'Access, Name => "language model parser retains split rename and instantiation target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Derived_Type_Target_Metadata'Access, Name => "language model parser retains split derived type target metadata");
      Add_Test (Routine => Test_Language_Model_Split_Access_Subprogram_Object_Profile_Metadata'Access, Name => "language model parser records split access-to-subprogram object profiles");
      Add_Test (Routine => Test_Language_Model_Split_Interface_Type_Target_Metadata'Access, Name => "language model parser retains split interface type target metadata");
      Add_Test (Routine => Test_Language_Model_Profile_Access_Subprogram_Parameter_Metadata'Access, Name => "language model parser retains access-subprogram parameter profile metadata");
      Add_Test (Routine => Test_Language_Model_Split_Access_Object_Parameter_Target_Metadata'Access, Name => "language model parser retains split access-object parameter target metadata");
      Add_Test (Routine => Test_Language_Model_Subprogram_Profile_Parameter_Mode_Metadata'Access, Name => "language model parser projects subprogram profile parameter mode metadata");
   end Register_Tests;

end Editor.Syntax_Semantics.Core_Model_Metadata_Tests;
