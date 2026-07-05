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

package body Editor.Syntax_Semantics.Core_Model_Scope_Tests is



   procedure Test_Local_Declarations (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, "package Renderer is");
      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, "type Color is private;");
      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, "procedure Draw (C : Color);");

      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "renderer") = Editor.Syntax.Package_Identifier,
              "package declarations are case-insensitive semantic symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "COLOR") = Editor.Syntax.Type_Identifier,
              "type declarations are semantic type symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Draw") = Editor.Syntax.Subprogram_Identifier,
              "procedure declarations are semantic subprogram symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Unknown") = Editor.Syntax.Identifier,
              "unknown identifiers must remain lexical identifiers");
   end Test_Local_Declarations;



   procedure Test_Overlong_Scoped_Semantic_Lookup_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Scope    : Editor.Ada_Language_Model.Symbol_Id;
      Exact_Name : constant String := "T" & String'(1 .. 63 => 'A');
      Overlong_Name : constant String := Exact_Name & "B";
   begin
      Scope := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Demo",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 4, End_Column => 9),
         Declaration_Column => 1,
         Depth => 1);

      Assert (Scope /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert the package scope");

      Assert
        (Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            Exact_Name,
            Editor.Ada_Language_Model.Symbol_Type,
            (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 70),
            Declaration_Column => 4,
            Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Scope),
            Parent_Symbol => Scope,
            Depth => 2) /= Editor.Ada_Language_Model.No_Symbol,
         "test setup should insert the bounded type declaration");

      Assert
        (Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            Overlong_Name,
            Editor.Ada_Language_Model.Symbol_Type,
            (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 71),
            Declaration_Column => 4,
            Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Scope),
            Parent_Symbol => Scope,
            Depth => 2) /= Editor.Ada_Language_Model.No_Symbol,
         "test setup should retain parser-owned overlong declarations");

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, Exact_Name, Scope) = Editor.Syntax.Type_Identifier,
         "scoped semantic lookup still classifies bounded retained names");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, Overlong_Name, Scope) = Editor.Syntax.Identifier,
         "scoped semantic lookup must degrade overlong tokens like the flat map");
   end Test_Overlong_Scoped_Semantic_Lookup_Degrades;



   procedure Test_Language_Model_Scopes_Shadowing_And_Parents
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer is" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   package Inner is" & ASCII.LF &
        "      X : Natural;" & ASCII.LF &
        "      procedure Use_X;" & ASCII.LF &
        "   end Inner;" & ASCII.LF &
        "end Outer;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "outer.ads");
      Inner_X : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "X", From_Depth => 2);
      Outer_X : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "X", From_Depth => 1);
      Inner_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_X);
      Outer_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_X);
   begin
      Assert (Inner_X /= Editor.Ada_Language_Model.No_Symbol,
              "nested scope lookup should resolve the inner declaration");
      Assert (Outer_X /= Editor.Ada_Language_Model.No_Symbol,
              "outer scope lookup should still resolve the outer declaration");
      Assert (Inner_X /= Outer_X,
              "inner declarations should shadow outer declarations instead of flattening them");
      Assert (Inner_Info.Depth = 2 and then Outer_Info.Depth = 1,
              "parser should stamp lexical depths on declarations");
      Assert (Inner_Info.Parent_Symbol /= Editor.Ada_Language_Model.No_Symbol,
              "nested declaration should have a parent symbol for outline/navigation use");
   end Test_Language_Model_Scopes_Shadowing_And_Parents;


   procedure Test_Language_Model_Multiline_Record_Discriminants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Model is" & ASCII.LF &
        "   type Rec (" & ASCII.LF &
        "      Id : Natural;" & ASCII.LF &
        "      Enabled : Boolean) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Model;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "model.ads");
      Id_Symbol : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Id", From_Depth => 2);
      Value_Symbol : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value", From_Depth => 2);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Symbol);
      Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Value_Symbol);
   begin
      Assert (Id_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant,
              "multi-line discriminant parts should produce discriminant symbols");
      Assert (Value_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component,
              "record fields following a multi-line discriminant should remain record components");
      Assert (Id_Info.Parent_Symbol = Value_Info.Parent_Symbol,
              "discriminants and components should attach to the same record parent");
   end Test_Language_Model_Multiline_Record_Discriminants;



   procedure Test_Language_Model_End_If_Does_Not_Pop_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Body_Scope is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if True then" & ASCII.LF &
        "         Inner_Local : Integer;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "      After_If : Integer;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "   Package_Level : Integer;" & ASCII.LF &
        "end Body_Scope;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "body_scope.ads");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      After_If_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_If", Run_Id);
      Package_Level_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Package_Level", From_Depth => 1);
      After_If_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_If_Id);
      Package_Level_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Level_Id);
   begin
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parser should find the procedure scope used by scope-aware resolution");
      Assert (After_If_Info.Parent_Symbol = Run_Id,
              "end if must not pop the procedure lexical scope before following declarations");
      Assert (Package_Level_Info.Parent_Symbol /= Run_Id,
              "end Run must still pop the procedure scope before package-level declarations");
   end Test_Language_Model_End_If_Does_Not_Pop_Scope;



   procedure Test_Language_Model_Discriminant_Profile_Semicolons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Records is" & ASCII.LF &
        "   type Rec (Callback : access procedure (Profile_Left : Integer; Profile_Right : Integer); Next : Integer) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Records;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "discriminant_profile_semicolons.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Callback", Rec_Id);
      Next_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Next", Rec_Id);
      Profile_Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Profile_Left", Rec_Id);
      Profile_Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Profile_Right", Rec_Id);
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Next_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Next_Id);
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be present before checking profiled discriminants");
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Callback_Info.Parent_Symbol = Rec_Id,
              "access-to-subprogram discriminant should be retained as one discriminant");
      Assert (Next_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Next_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Next_Info.Parent_Symbol = Rec_Id,
              "discriminant after profiled access discriminant should still parse");
      Assert (Profile_Left_Id = Editor.Ada_Language_Model.No_Symbol
              and then Profile_Right_Id = Editor.Ada_Language_Model.No_Symbol,
              "profile parameter names inside access discriminant metadata must not become discriminants");
   end Test_Language_Model_Discriminant_Profile_Semicolons;



   procedure Test_Language_Model_Private_Type_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "package Visibility is" & ASCII.LF &
        "   type Handle is limited private;" & ASCII.LF &
        "   type Count is range 0 .. 10;" & ASCII.LF &
        "end Visibility;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "visibility.ads");
      Element_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Element");
      Handle_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Handle");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Element_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Element_Id);
      Handle_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Handle_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
   begin
      Assert (Element_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
              "generic private formal type should keep formal-type kind");
      Assert (Element_Info.Flags.Is_Generic,
              "generic private formal type should keep generic metadata");
      Assert (Element_Info.Flags.Is_Private,
              "generic private formal type should carry private-type metadata");
      Assert (Handle_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "limited private completion should still be a type symbol");
      Assert (Handle_Info.Flags.Is_Private,
              "limited private type declaration should carry private metadata");
      Assert (not Count_Info.Flags.Is_Private,
              "ordinary non-private type declarations must not inherit private-type metadata");
   end Test_Language_Model_Private_Type_Declarations;


   procedure Test_Language_Model_Profile_Update_Is_Idempotent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Id       : Editor.Ada_Language_Model.Symbol_Id;
      After_Add           : Natural;
      After_First_Profile : Natural;
      After_Same_Profile  : Natural;
      After_New_Profile   : Natural;
   begin
      Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Render",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 4, End_Line => 1, End_Column => 10));

      Assert (Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert the callable symbol");
      After_Add := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Editor.Ada_Language_Model.Set_Symbol_Profile
        (Analysis, Id, "(Canvas : Surface)");
      After_First_Profile := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Editor.Ada_Language_Model.Set_Symbol_Profile
        (Analysis, Id, "(Canvas : Surface)");
      After_Same_Profile := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Editor.Ada_Language_Model.Set_Symbol_Profile
        (Analysis, Id, "(Canvas : Surface; Dirty : Boolean)");
      After_New_Profile := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Assert (After_Add /= After_First_Profile,
              "first profile update must change the language-model fingerprint");
      Assert (After_First_Profile = After_Same_Profile,
              "re-applying the same profile must be fingerprint-idempotent");
      Assert (After_New_Profile /= After_Same_Profile,
              "a different profile must still change the language-model fingerprint");
   end Test_Language_Model_Profile_Update_Is_Idempotent;



   procedure Test_Language_Model_Discriminant_Ranges_Use_Source_Columns
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Header : constant String :=
        "   type Rec (Id : Natural; Flag : Boolean) is record";
      Source : constant String :=
        "package Ranges is" & ASCII.LF &
        Header & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Ranges;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "ranges.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Id", Rec_Id);
      Flag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Flag", Rec_Id);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Id);
      Flag_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Flag_Id);
      Expected_Id_Column : constant Natural := Ada.Strings.Fixed.Index (Header, "Id");
      Expected_Flag_Column : constant Natural := Ada.Strings.Fixed.Index (Header, "Flag");
   begin
      Assert (Id_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Flag_Id /= Editor.Ada_Language_Model.No_Symbol,
              "same-line discriminants should be available under the record type");
      Assert (Natural (Id_Info.Source_Span.Start_Column) = Expected_Id_Column,
              "same-line discriminant source range should use the original source column");
      Assert (Natural (Flag_Info.Source_Span.Start_Column) = Expected_Flag_Column,
              "later same-line discriminants should also preserve original source columns");
      Assert (Id_Info.Declaration_Column = Id_Info.Source_Span.Start_Column
              and then Flag_Info.Declaration_Column = Flag_Info.Source_Span.Start_Column,
              "declaration columns should match the source range starts for discriminants");
   end Test_Language_Model_Discriminant_Ranges_Use_Source_Columns;



   procedure Test_Language_Model_Subprogram_Profile_Parameters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Params is" & ASCII.LF &
        "   procedure Draw (X, Y : Integer; Name : String);" & ASCII.LF &
        "   function ""+"" (Left, Right : Count) return Count;" & ASCII.LF &
        "end Params;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "params.ads");
      Draw_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Draw");
      Plus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """+""");
      X_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "X", Draw_Id);
      Y_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Y", Draw_Id);
      Name_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Name", Draw_Id);
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Left", Plus_Id);
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Right", Plus_Id);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Assert (Draw_Id /= Editor.Ada_Language_Model.No_Symbol,
              "procedure should be parsed");
      Assert (Plus_Id /= Editor.Ada_Language_Model.No_Symbol,
              "operator function should be parsed");
      Assert (X_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Y_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Name_Id /= Editor.Ada_Language_Model.No_Symbol,
              "procedure profile parameters should be parented to the procedure symbol");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Id /= Editor.Ada_Language_Model.No_Symbol,
              "operator function profile parameters should be parented to the operator symbol");
      Assert (Editor.Ada_Language_Model.Symbol_At (Analysis, Positive (Natural (X_Id))).Kind =
              Editor.Ada_Language_Model.Symbol_Object,
              "profile parameters are retained as object-like local symbols");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Left") =
              Editor.Syntax.Parameter_Identifier,
              "semantic map should retain subprogram parameter names from the language model");
   end Test_Language_Model_Subprogram_Profile_Parameters;


   procedure Test_Language_Model_Multiline_Profile_Parameters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Multi_Params is" & ASCII.LF &
        "   procedure Configure" & ASCII.LF &
        "     (Width  : Positive;" & ASCII.LF &
        "      Height : Positive;" & ASCII.LF &
        "      Title, Class_Name : String);" & ASCII.LF &
        "end Multi_Params;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "multi_params.ads");
      Configure_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Configure");
      Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Width", Configure_Id);
      Height_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Height", Configure_Id);
      Title_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Title", Configure_Id);
      Class_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Class_Name", Configure_Id);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Assert (Configure_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split-profile procedure should be parsed");
      Assert (Width_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Height_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Title_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Class_Id /= Editor.Ada_Language_Model.No_Symbol,
              "multi-line profile parameters should be parented to the callable symbol");
      Assert (Editor.Ada_Language_Model.Symbol_At
                (Analysis, Positive (Natural (Class_Id))).Source_Span.Start_Line = 5,
              "continuation profile parameter ranges should preserve source lines");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Class_Name") =
              Editor.Syntax.Parameter_Identifier,
              "semantic map should retain multi-line profile parameters from the language model");
   end Test_Language_Model_Multiline_Profile_Parameters;





   procedure Test_Language_Model_Split_Is_Record_Opens_Record_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Is_Record is" & ASCII.LF &
        "   type Rec is" & ASCII.LF &
        "      record" & ASCII.LF &
        "         Value : Integer;" & ASCII.LF &
        "      end record;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Split_Is_Record;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_is_record.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Split_Is_Record");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Rec", Package_Id);
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Value", Rec_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "After", Package_Id);
      Rec_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Rec_Id);
      Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Value_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split is/record declarations should retain package and type symbols");
      Assert (Rec_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type,
              "type headers split as type T is / record should upgrade to record type symbols");
      Assert (Value_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Value_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Value_Info.Parent_Symbol = Rec_Id,
              "record components after a split is/record opener should be parented to the record type");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "end record after a split is/record opener should restore the package scope");
   end Test_Language_Model_Split_Is_Record_Opens_Record_Scope;




   procedure Test_Language_Model_Split_Profile_Body_Opens_Callable_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Profile_Body is" & ASCII.LF &
        "   procedure Configure" & ASCII.LF &
        "     (Width : Positive;" & ASCII.LF &
        "      Height : Positive)" & ASCII.LF &
        "   is" & ASCII.LF &
        "      Local : constant Integer := 0;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Configure;" & ASCII.LF &
        "end Split_Profile_Body;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "split_profile_body.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "Split_Profile_Body");
      Configure_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Configure", Package_Id);
      Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Width", Configure_Id);
      Height_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Height", Configure_Id);
      Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Local", Configure_Id);
      Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Configure_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split-profile body test should have package and procedure symbols");
      Assert (Width_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Height_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split-profile parameters should remain parented to the callable");
      Assert (Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then Local_Info.Parent_Symbol = Configure_Id,
              "the pending-profile 'is' line should open the callable scope for local declarations");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, "Local", Configure_Id) = Editor.Syntax.Parameter_Identifier,
         "scope-aware semantic classification should see locals inside split-profile bodies");
   end Test_Language_Model_Split_Profile_Body_Opens_Callable_Scope;



   procedure Test_Language_Model_Variant_Record_Components_Strip_Choices
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Variants is" & ASCII.LF &
        "   type Shape (Kind : Boolean) is record" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when True => Radius : Natural;" & ASCII.LF &
        "         when others => Width, Height : Natural;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Variants;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "variants.ads");
      Shape_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Shape");
      Radius_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Radius");
      Width_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Width");
      Height_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Height");
      When_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "when");
      Others_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "others");
      True_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "True");
      Radius_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Radius_Id);
      Width_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Width_Id);
      Height_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Height_Id);
   begin
      Assert (Shape_Id /= Editor.Ada_Language_Model.No_Symbol,
              "variant record type should be parsed");
      Assert (Radius_Id /= Editor.Ada_Language_Model.No_Symbol,
              "variant component after choice arrow should be parsed");
      Assert (Width_Id /= Editor.Ada_Language_Model.No_Symbol,
              "first component after others choice arrow should be parsed");
      Assert (Height_Id /= Editor.Ada_Language_Model.No_Symbol,
              "second component after others choice arrow should be parsed");
      Assert (Radius_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component,
              "variant component should retain record-component kind");
      Assert (Radius_Info.Parent_Symbol = Shape_Id,
              "variant component should be parented to the record type");
      Assert (Width_Info.Parent_Symbol = Shape_Id
              and then Height_Info.Parent_Symbol = Shape_Id,
              "all variant components should be parented to the record type");
      Assert (When_Id = Editor.Ada_Language_Model.No_Symbol,
              "variant component extraction must not learn the Ada keyword when");
      Assert (Others_Id = Editor.Ada_Language_Model.No_Symbol,
              "variant component extraction must not learn the Ada choice others");
      Assert (True_Id = Editor.Ada_Language_Model.No_Symbol,
              "variant component extraction must not learn choice expressions as components");
   end Test_Language_Model_Variant_Record_Components_Strip_Choices;




   procedure Test_Language_Model_Entry_Family_Profile_Parameters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Queues is" & ASCII.LF &
        "   protected type Gate is" & ASCII.LF &
        "      entry Serve (Positive) (Item : out Integer; Priority : Natural);" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "end Queues;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "queues.ads");
      Serve_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Serve");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Item", Serve_Id);
      Priority_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Priority", Serve_Id);
      Positive_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Positive", Serve_Id);
   begin
      Assert (Serve_Id /= Editor.Ada_Language_Model.No_Symbol,
              "entry family declaration should be parsed as an entry symbol");
      Assert (Item_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parameter group after an entry-family index group should be learned");
      Assert (Priority_Id /= Editor.Ada_Language_Model.No_Symbol,
              "all parameters in the second entry profile should be learned");
      Assert (Positive_Id = Editor.Ada_Language_Model.No_Symbol,
              "entry-family index subtype must not be learned as a parameter symbol");
      Assert (Editor.Ada_Language_Model.Symbol (Analysis, Item_Id).Parent_Symbol = Serve_Id,
              "entry parameters should be parented to the entry symbol");
   end Test_Language_Model_Entry_Family_Profile_Parameters;




   procedure Test_Language_Model_Entry_Body_Barrier_Profile_And_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Barriers is" & ASCII.LF &
        "   protected body Gate is" & ASCII.LF &
        "      Ready : Boolean := False;" & ASCII.LF &
        "      entry Serve (Item : out Integer) when Ready is" & ASCII.LF &
        "         Local : constant Boolean := True;" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Serve;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "end Barriers;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "barriers.ads");
      Serve_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Serve");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Item", Serve_Id);
      Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local", Serve_Id);
      Serve_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Serve_Id);
      Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Id);
   begin
      Assert (Serve_Id /= Editor.Ada_Language_Model.No_Symbol,
              "entry body with barrier should be parsed as an entry symbol");
      Assert (Item_Id /= Editor.Ada_Language_Model.No_Symbol,
              "entry body parameters before the barrier should be learned");
      Assert (To_String (Serve_Info.Profile_Summary) = "(Item : out Integer)",
              "entry barriers must not pollute callable profile summaries");
      Assert (Local_Id /= Editor.Ada_Language_Model.No_Symbol,
              "local declarations inside an entry body should be visible in the entry scope");
      Assert (Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then Local_Info.Parent_Symbol = Serve_Id,
              "entry barrier bodies should open the entry scope before local declarations");
   end Test_Language_Model_Entry_Body_Barrier_Profile_And_Scope;


   procedure Test_Language_Model_Concurrent_Type_Discriminants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Concurrent_Discriminants is" & ASCII.LF &
        "   task type Worker (Id : Positive; Enabled : Boolean) is" & ASCII.LF &
        "      entry Start (Value : in Integer; Flag, Other : Boolean);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected type Cache (Size : Positive) is" & ASCII.LF &
        "      procedure Clear;" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Count : Natural;" & ASCII.LF &
        "   end Cache;" & ASCII.LF &
        "end Concurrent_Discriminants;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "concurrent_discriminants.ads");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Cache_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Cache");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Id", Worker_Id);
      Enabled_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enabled", Worker_Id);
      Size_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Size", Cache_Id);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Id);
      Size_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Size_Id);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol,
              "task type with discriminants should be parsed");
      Assert (Cache_Id /= Editor.Ada_Language_Model.No_Symbol,
              "protected type with discriminants should be parsed");
      Assert (Id_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enabled_Id /= Editor.Ada_Language_Model.No_Symbol,
              "task type discriminants should be owned by the task type");
      Assert (Size_Id /= Editor.Ada_Language_Model.No_Symbol,
              "protected type discriminants should be owned by the protected type");
      Assert (Id_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Id_Info.Parent_Symbol = Worker_Id,
              "task discriminants should use Symbol_Discriminant and task parent metadata");
      Assert (Size_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Size_Info.Parent_Symbol = Cache_Id,
              "protected discriminants should use Symbol_Discriminant and protected parent metadata");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Id") =
              Editor.Syntax.Parameter_Identifier,
              "task discriminants should reach semantic colouring through the language model");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Size") =
              Editor.Syntax.Parameter_Identifier,
              "protected discriminants should reach semantic colouring through the language model");
   end Test_Language_Model_Concurrent_Type_Discriminants;



   procedure Test_Language_Model_Split_Concurrent_Type_Discriminants_And_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Concurrent is" & ASCII.LF &
        "   task type Worker" & ASCII.LF &
        "      (Id : Positive;" & ASCII.LF &
        "       Enabled : Boolean)" & ASCII.LF &
        "   is" & ASCII.LF &
        "      entry Start (Value : in Integer; Flag, Other : Boolean);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected type Cache" & ASCII.LF &
        "      (Size : Positive)" & ASCII.LF &
        "   is" & ASCII.LF &
        "      procedure Clear;" & ASCII.LF &
        "   end Cache;" & ASCII.LF &
        "end Split_Concurrent;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_concurrent.ads");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Cache_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Cache");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Id", Worker_Id);
      Enabled_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Enabled", Worker_Id);
      Start_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Start", Worker_Id);
      Size_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Size", Cache_Id);
      Clear_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Clear", Cache_Id);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Id);
      Start_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Start_Id);
      Clear_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Clear_Id);
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Cache_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split task/protected type headers should retain their owner symbols");
      Assert (Id_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enabled_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split task type discriminants should be owned by the task type");
      Assert (Size_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split protected type discriminants should be owned by the protected type");
      Assert (Start_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Clear_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split concurrent type body declarations should stay in the concurrent type scope");
      Assert (Id_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Id_Info.Parent_Symbol = Worker_Id,
              "split task discriminants should retain Symbol_Discriminant metadata");
      Assert (Start_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Start_Info.Parent_Symbol = Worker_Id,
              "entry declarations after split task headers should be parented to the task type");
      Assert (Clear_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Clear_Info.Parent_Symbol = Cache_Id,
              "protected operations after split protected headers should be parented to the protected type");
   end Test_Language_Model_Split_Concurrent_Type_Discriminants_And_Scope;


   procedure Test_Language_Model_Concurrent_Header_Discriminants_Before_Later_Is
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Concurrent_Inline_Discriminants is" & ASCII.LF &
        "   task type Worker (Id : Positive)" & ASCII.LF &
        "   is" & ASCII.LF &
        "      entry Start (Value : in Integer; Flag, Other : Boolean);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected type Cache (Size : Positive)" & ASCII.LF &
        "   is" & ASCII.LF &
        "      procedure Clear;" & ASCII.LF &
        "   end Cache;" & ASCII.LF &
        "end Concurrent_Inline_Discriminants;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "concurrent_inline_discriminants.ads");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Cache_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Cache");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Id", Worker_Id);
      Start_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Start", Worker_Id);
      Size_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Size", Cache_Id);
      Clear_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Clear", Cache_Id);
      Start_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Start_Id);
      Clear_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Clear_Id);
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Cache_Id /= Editor.Ada_Language_Model.No_Symbol,
              "concurrent type headers with inline discriminants before later is should parse owners");
      Assert (Id_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Size_Id /= Editor.Ada_Language_Model.No_Symbol,
              "inline discriminants before later is should be parented to concurrent type owners");
      Assert (Start_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Clear_Id /= Editor.Ada_Language_Model.No_Symbol,
              "later is should open task/protected scopes after inline discriminant headers");
      Assert (Start_Info.Parent_Symbol = Worker_Id
              and then Clear_Info.Parent_Symbol = Cache_Id,
              "entries/protected operations should stay under their concurrent type owners");
   end Test_Language_Model_Concurrent_Header_Discriminants_Before_Later_Is;


   procedure Test_Language_Model_Access_Subprogram_Types_Do_Not_Learn_Profile_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Profiles is" & ASCII.LF &
        "   type Callback is access procedure (Item : Integer; Count : Natural);" & ASCII.LF &
        "   type Predicate is access function (Value : Integer) return Boolean;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Access_Profiles;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "access_profiles.ads");
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
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access-to-procedure type should be retained as a type symbol");
      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol,
              "access-to-function type should be retained as a type symbol");
      Assert (Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Type
              and then Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "access-to-subprogram declarations are types, not callable symbols");
      Assert (To_String (Callback_Info.Profile_Summary) =
                "procedure (Item : Integer; Count : Natural)",
              "access-to-procedure type should retain its callable profile summary");
      Assert (Callback_Info.Flags.Has_Access_Subprogram_Metadata,
              "access-to-procedure type should retain access-subprogram metadata");
      Assert (To_String (Predicate_Info.Profile_Summary) =
                "function (Value : Integer) return Boolean",
              "access-to-function type should retain its callable profile summary");
      Assert (Predicate_Info.Flags.Has_Access_Subprogram_Metadata,
              "access-to-function type should retain access-subprogram metadata");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Count_Id = Editor.Ada_Language_Model.No_Symbol
              and then Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "access-to-subprogram profile names must not be learned as discriminants or parameters");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "access profile parsing must not corrupt following package-level declarations");
   end Test_Language_Model_Access_Subprogram_Types_Do_Not_Learn_Profile_Names;



   procedure Test_Language_Model_Body_Stubs_Are_Separate_Without_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Body_Stubs is" & ASCII.LF &
        "   procedure Work is separate;" & ASCII.LF &
        "   package body Inner is separate;" & ASCII.LF &
        "   After : Integer;" & ASCII.LF &
        "end Body_Stubs;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "body_stubs.adb");
      Body_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Body_Stubs");
      Work_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Work");
      Inner_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After");
      Body_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Body_Id);
      Work_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Work_Id);
      Inner_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Body_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Body_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body,
              "package body should be retained as the enclosing body scope");
      Assert (Work_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Work_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Work_Info.Flags.Is_Separate,
              "procedure body stub must retain procedure kind and separate metadata");
      Assert (Inner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
              and then Inner_Info.Flags.Is_Separate,
              "package body stub must retain package-body kind and separate metadata");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Parent_Symbol = Body_Id,
              "body stubs with semicolons must not open scopes that capture following declarations");
   end Test_Language_Model_Body_Stubs_Are_Separate_Without_Scope;



   procedure Test_Language_Model_Record_Component_Profile_Semicolons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Record_Profile_Semicolons is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Callback : access procedure (A : Integer; B : Integer); Next : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Record_Profile_Semicolons;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "record_profile_semicolons.ads");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback");
      Next_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Next");
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "B");
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Next_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Next_Id);
   begin
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component,
              "record access-to-subprogram component should parse as one component");
      Assert (B_Id = Editor.Ada_Language_Model.No_Symbol,
              "semicolon inside record component profile must not create bogus component names");
      Assert (Next_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Next_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then To_String (Next_Info.Target_Name) = "Integer"
              and then Next_Info.Declaration_Column > Callback_Info.Declaration_Column,
              "top-level semicolon after profile should still split the next component");
   end Test_Language_Model_Record_Component_Profile_Semicolons;



   procedure Test_Language_Model_Object_Profile_Semicolons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Object_Profile_Semicolons is" & ASCII.LF &
        "   Callback : access procedure (A : Integer; B : Integer); Next : Integer;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Formal_Callback : access procedure (Left : Integer; Right : Integer); Formal_Next : in Integer;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "end Object_Profile_Semicolons;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "object_profile_semicolons.ads");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback");
      Next_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Next");
      Formal_Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Callback");
      Formal_Next_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_Next");
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "B");
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right");
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Next_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Next_Id);
      Formal_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Callback_Id);
      Formal_Next_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_Next_Id);
   begin
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "object access-to-subprogram profile should remain one object declaration");
      Assert (Next_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Next_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Next_Info.Declaration_Column > Callback_Info.Declaration_Column,
              "top-level semicolon after object profile should still split next object");
      Assert (Formal_Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object,
              "generic formal object profile should remain one formal declaration");
      Assert (Formal_Next_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Next_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Formal_Next_Info.Declaration_Column > Formal_Callback_Info.Declaration_Column,
              "top-level semicolon after formal profile should still split next formal object");
      Assert (B_Id = Editor.Ada_Language_Model.No_Symbol
              and then Right_Id = Editor.Ada_Language_Model.No_Symbol,
              "profile parameter names after internal semicolons must stay metadata-only");
   end Test_Language_Model_Object_Profile_Semicolons;



   procedure Test_Language_Model_Exposes_Parent_Child_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   type Rec is record A : Integer; B : Boolean; end record;" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "      procedure Run;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "children.ads");
      Demo_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Demo");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Rec", Demo_Id);
      Nested_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Nested", Demo_Id);
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Nested_Id);
      A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "A", Rec_Id);
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "B", Rec_Id);

      function Has_Child
        (Parent : Editor.Ada_Language_Model.Symbol_Id;
         Child  : Editor.Ada_Language_Model.Symbol_Id) return Boolean
      is
      begin
         for I in 1 .. Editor.Ada_Language_Model.Child_Count (Analysis, Parent) loop
            if Editor.Ada_Language_Model.Child_At (Analysis, Parent, Positive (I)) = Child then
               return True;
            end if;
         end loop;
         return False;
      end Has_Child;
   begin
      Assert (Demo_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Rec_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Nested_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should parse package/type/nested package/subprogram symbols");
      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should parse same-line record components as child symbols");

      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Demo_Id) >= 2,
              "package symbol should expose nested type/package children");
      Assert (Has_Child (Demo_Id, Rec_Id),
              "package child list should include the record type");
      Assert (Has_Child (Demo_Id, Nested_Id),
              "package child list should include the nested package");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Rec_Id) >= 2,
              "record type should expose component children");
      Assert (Has_Child (Rec_Id, A_Id) and then Has_Child (Rec_Id, B_Id),
              "record child list should include both same-line components");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Nested_Id) = 1
              and then Editor.Ada_Language_Model.Child_At (Analysis, Nested_Id, 1) = Run_Id,
              "nested package child list should preserve deterministic declaration order");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Nested_Id, 2)
              = Editor.Ada_Language_Model.No_Symbol,
              "out-of-range child lookup should degrade to No_Symbol");
      Assert (Editor.Ada_Language_Model.Child_Count
                (Analysis, Editor.Ada_Language_Model.No_Symbol) = 0,
              "No_Symbol must not expose synthetic children");
   end Test_Language_Model_Exposes_Parent_Child_Symbols;



   procedure Test_Language_Model_Declaration_Owner_Predicate_Is_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Package_Id : Editor.Ada_Language_Model.Symbol_Id;
      Formal_Package_Id : Editor.Ada_Language_Model.Symbol_Id;
      Object_Id : Editor.Ada_Language_Model.Symbol_Id;
      Child_Id  : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Assert (Editor.Ada_Language_Model.Is_Declaration_Owner
                (Editor.Ada_Language_Model.Symbol_Package),
              "packages are declaration-owning scopes");
      Assert (Editor.Ada_Language_Model.Is_Declaration_Owner
                (Editor.Ada_Language_Model.Symbol_Generic_Formal_Package),
              "generic formal packages are declaration-owning scopes");
      Assert (not Editor.Ada_Language_Model.Is_Declaration_Owner
                (Editor.Ada_Language_Model.Symbol_Object),
              "objects must not be declaration-owning scopes");
      Assert (not Editor.Ada_Language_Model.Is_Declaration_Owner
                (Editor.Ada_Language_Model.Symbol_Record_Component),
              "record components must not be declaration-owning scopes");

      Package_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Pkg",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 3));
      Formal_Package_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Formal_Pkg",
         Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
         (Start_Line => 2, Start_Column => 1, End_Line => 2, End_Column => 10));
      Object_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Obj",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 3, Start_Column => 1, End_Line => 3, End_Column => 3));

      Child_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Child",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 8),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Package_Id),
         Parent_Symbol   => Package_Id,
         Depth           => 1);

      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert a valid package child");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Package_Id) = 1,
              "child traversal consumes the shared declaration-owner predicate");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Editor.Ada_Language_Model.Scope_Id (Package_Id), "Child") = 1,
              "overload traversal consumes the same declaration-owner predicate");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Editor.Ada_Language_Model.Scope_Id (Formal_Package_Id), "Child") = 0,
              "empty declaration-owning formal package scope is valid and deterministic");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Object_Id) = 0,
              "non-owner child traversal degrades through the same predicate");
      Assert (Editor.Ada_Language_Model.Overload_Count
                (Analysis, Editor.Ada_Language_Model.Scope_Id (Object_Id), "Child") = 0,
              "non-owner overload traversal degrades through the same predicate");
   end Test_Language_Model_Declaration_Owner_Predicate_Is_Canonical;







   procedure Test_Language_Model_Legality_Profile_Parameter_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   procedure Bad (Item : Integer; Item : Natural);" & ASCII.LF &
        "   function Also_Bad (Left, Right : Integer; Left : Natural) return Boolean;" & ASCII.LF &
        "   procedure Good (Left, Right : Integer; Other : Natural);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Profile_Duplicate : Natural := 0;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "duplicate profile parameter names should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Duplicate_Profile_Parameter then
               Seen_Profile_Duplicate := Seen_Profile_Duplicate + 1;
            end if;
         end;
      end loop;

      Assert (Seen_Profile_Duplicate = 2,
              "legality checking should flag duplicate parameter names per retained profile");
   end Test_Language_Model_Legality_Profile_Parameter_Pass;




   procedure Test_Language_Model_Legality_Local_Duplicate_Declarations_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Item is private;" & ASCII.LF &
        "   with procedure Item (X : Integer);" & ASCII.LF &
        "package P is" & ASCII.LF &
        "   type Rec (Key : Natural; Key : Positive) is record" & ASCII.LF &
        "      Field : Integer;" & ASCII.LF &
        "      Field : Natural;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   type Colour is (Red, Green, Red);" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Record_Component : Boolean := False;
      Seen_Discriminant    : Boolean := False;
      Seen_Enumeration     : Boolean := False;
      Seen_Generic_Formal  : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "local duplicate declaration families should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Record_Component_Name =>
                  Seen_Record_Component := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Discriminant_Name =>
                  Seen_Discriminant := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Enumeration_Literal_Name =>
                  Seen_Enumeration := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Generic_Formal_Name =>
                  Seen_Generic_Formal := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Record_Component,
              "duplicate record component names should be diagnosed locally");
      Assert (Seen_Discriminant,
              "duplicate discriminant names should be diagnosed locally");
      Assert (Seen_Enumeration,
              "duplicate enumeration literals should be diagnosed locally");
      Assert (Seen_Generic_Formal,
              "duplicate generic formal names should be diagnosed locally");
   end Test_Language_Model_Legality_Local_Duplicate_Declarations_Pass;


   overriding function Name (T : Core_Model_Scope_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Core_Model.Scope");
   end Name;

   overriding procedure Register_Tests (T : in out Core_Model_Scope_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Local_Declarations'Access, Name => "conservative local declaration classification");
      Add_Test (Routine => Test_Overlong_Scoped_Semantic_Lookup_Degrades'Access, Name => "overlong scoped semantic lookup degrades conservatively");
      Add_Test (Routine => Test_Language_Model_Scopes_Shadowing_And_Parents'Access, Name => "language model parser stamps lexical scopes and shadowing");
      Add_Test (Routine => Test_Language_Model_Multiline_Record_Discriminants'Access, Name => "language model parser handles multi-line record discriminants");
      Add_Test (Routine => Test_Language_Model_End_If_Does_Not_Pop_Scope'Access, Name => "language model parser ignores non-scope end statements");
      Add_Test (Routine => Test_Language_Model_Discriminant_Profile_Semicolons'Access, Name => "language model parser keeps access-profile semicolons inside discriminant metadata");
      Add_Test (Routine => Test_Language_Model_Private_Type_Declarations'Access, Name => "language model parser flags private type declarations");
      Add_Test (Routine => Test_Language_Model_Profile_Update_Is_Idempotent'Access, Name => "language model profile updates are fingerprint-idempotent");
      Add_Test (Routine => Test_Language_Model_Discriminant_Ranges_Use_Source_Columns'Access, Name => "language model parser preserves discriminant source columns");
      Add_Test (Routine => Test_Language_Model_Subprogram_Profile_Parameters'Access, Name => "language model parser retains subprogram profile parameters");
      Add_Test (Routine => Test_Language_Model_Multiline_Profile_Parameters'Access, Name => "language model parser retains multi-line profile parameters");
      Add_Test (Routine => Test_Language_Model_Split_Is_Record_Opens_Record_Scope'Access, Name => "language model parser opens record scope for split is/record declarations");
      Add_Test (Routine => Test_Language_Model_Split_Profile_Body_Opens_Callable_Scope'Access, Name => "language model parser opens callable scope after split profile body is");
      Add_Test (Routine => Test_Language_Model_Variant_Record_Components_Strip_Choices'Access, Name => "language model parser strips variant choices before record components");
      Add_Test (Routine => Test_Language_Model_Entry_Family_Profile_Parameters'Access, Name => "language model parser retains entry-family second-profile parameters");
      Add_Test (Routine => Test_Language_Model_Entry_Body_Barrier_Profile_And_Scope'Access, Name => "language model parser keeps entry barrier metadata out of profiles and opens entry body scopes");
      Add_Test (Routine => Test_Language_Model_Concurrent_Type_Discriminants'Access, Name => "language model parser retains task/protected type discriminants");
      Add_Test (Routine => Test_Language_Model_Split_Concurrent_Type_Discriminants_And_Scope'Access, Name => "language model parser retains split task/protected discriminants and scopes");
      Add_Test (Routine => Test_Language_Model_Concurrent_Header_Discriminants_Before_Later_Is'Access, Name => "language model parser opens concurrent scopes after inline discriminant headers before later is");
      Add_Test (Routine => Test_Language_Model_Access_Subprogram_Types_Do_Not_Learn_Profile_Names'Access, Name => "language model parser does not learn access-to-subprogram profile names");
      Add_Test (Routine => Test_Language_Model_Body_Stubs_Are_Separate_Without_Scope'Access, Name => "body stubs retain separate metadata without opening scopes");
      Add_Test (Routine => Test_Language_Model_Record_Component_Profile_Semicolons'Access, Name => "language model ignores semicolons inside record component profiles");
      Add_Test (Routine => Test_Language_Model_Object_Profile_Semicolons'Access, Name => "language model ignores semicolons inside object/formal profiles");
      Add_Test (Routine => Test_Language_Model_Exposes_Parent_Child_Symbols'Access, Name => "language model exposes deterministic parent-child symbol ownership");
      Add_Test (Routine => Test_Language_Model_Declaration_Owner_Predicate_Is_Canonical'Access, Name => "language model declaration-owner predicate is canonical");
      Add_Test (Routine => Test_Language_Model_Legality_Profile_Parameter_Pass'Access, Name => "language model checks duplicate callable profile parameter legality");
      Add_Test (Routine => Test_Language_Model_Legality_Local_Duplicate_Declarations_Pass'Access, Name => "language model checks local duplicate declaration-family legality");
   end Register_Tests;

end Editor.Syntax_Semantics.Core_Model_Scope_Tests;
