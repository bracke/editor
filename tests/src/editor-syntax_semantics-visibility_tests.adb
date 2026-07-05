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

package body Editor.Syntax_Semantics.Visibility_Tests is




   procedure Test_Language_Model_Private_Section_Flags
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Visibility is" & ASCII.LF &
        "   Public_Value : Integer;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Hidden_Value : Integer;" & ASCII.LF &
        "end Visibility;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "visibility.ads");
      Public_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Public_Value", From_Depth => 1);
      Hidden_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hidden_Value", From_Depth => 1);
      Public_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Public_Id);
      Hidden_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Id);
   begin
      Assert (Public_Id /= Editor.Ada_Language_Model.No_Symbol,
              "public declaration before private section should be parsed");
      Assert (Hidden_Id /= Editor.Ada_Language_Model.No_Symbol,
              "declaration after private section should be parsed");
      Assert (not Public_Info.Flags.Is_Private,
              "declarations before private section must not be flagged private");
      Assert (Hidden_Info.Flags.Is_Private,
              "declarations after private section should carry private-section metadata");
   end Test_Language_Model_Private_Section_Flags;



   procedure Test_Ada_Limited_With_Incomplete_View_Rules
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Full_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Full_Dep is" & ASCII.LF &
           "   type Full_Type is null record;" & ASCII.LF &
           "end Full_Dep;" & ASCII.LF,
           "full_dep.ads");
      Limited_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("package Limited_Dep is" & ASCII.LF &
           "   type Hidden is null record;" & ASCII.LF &
           "end Limited_Dep;" & ASCII.LF,
           "limited_dep.ads");
      Client_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("with Full_Dep;" & ASCII.LF &
           "limited with Limited_Dep;" & ASCII.LF &
           "package Client is" & ASCII.LF &
           "   type Ref is access Limited_Dep.Hidden;" & ASCII.LF &
           "end Client;" & ASCII.LF,
           "client.ads");
      Missing_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          ("limited with Missing_Limited;" & ASCII.LF &
           "package Missing_Client is" & ASCII.LF &
           "end Missing_Client;" & ASCII.LF,
           "missing_client.ads");
      Index : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model;
      Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Rules : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Limited_Info : Editor.Ada_Limited_View_Rules.Limited_View_Info;
      Full_Info : Editor.Ada_Limited_View_Rules.Limited_View_Info;
      Missing_Info : Editor.Ada_Limited_View_Rules.Limited_View_Info;
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/full_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Full_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/limited_dep.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Limited_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Client_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (Index, "src/missing_client.ads", Buffer_Token => 0, Buffer_Revision => 0,
         Lifecycle_Generation => 0, Analysis => Missing_Analysis);

      Closure := Editor.Ada_Cross_Unit_Closure.Build (Index);
      Visibility := Editor.Ada_Cross_Unit_Visibility.Build (Index, Closure);
      Rules := Editor.Ada_Limited_View_Rules.Build (Visibility);

      Limited_Info := Editor.Ada_Limited_View_Rules.Lookup_Limited_View
        (Rules, "Client", "Limited_Dep");
      Full_Info := Editor.Ada_Limited_View_Rules.Lookup_Limited_View
        (Rules, "Client", "Full_Dep");
      Missing_Info := Editor.Ada_Limited_View_Rules.Lookup_Limited_View
        (Rules, "Missing_Client", "Missing_Limited");

      Assert
        (Editor.Ada_Limited_View_Rules.Rule_Count (Rules) >= 3,
         "limited-view rules should project context visibility into a lookup-facing model");
      Assert
        (Limited_Info.Status = Editor.Ada_Limited_View_Rules.Limited_View_Incomplete_View_Visible
         and then Limited_Info.Incomplete_View_Visible
         and then Limited_Info.Full_View_Hidden
         and then not Limited_Info.Full_View_Visible,
         "limited with dependencies should expose only the incomplete view and hide the full view");
      Assert
        (not Editor.Ada_Limited_View_Rules.Full_View_Visible
           (Rules, "Client", "Limited_Dep")
         and then Editor.Ada_Limited_View_Rules.Full_View_Hidden_Count (Rules) >= 1,
         "limited-view lookup should reject full-view assumptions deterministically");
      Assert
        (Full_Info.Status = Editor.Ada_Limited_View_Rules.Limited_View_Not_Limited
         and then Full_Info.Full_View_Visible
         and then not Full_Info.Full_View_Hidden,
         "ordinary with dependencies should retain full-view visibility");
      Assert
        (Missing_Info.Status = Editor.Ada_Limited_View_Rules.Limited_View_Missing_Dependency
         and then Editor.Ada_Limited_View_Rules.Missing_Count (Rules) >= 1,
         "missing limited-with dependencies should remain explicit metadata for diagnostics");
      Assert
        (Editor.Ada_Limited_View_Rules.Incomplete_View_Count (Rules) >= 1
         and then Editor.Ada_Limited_View_Rules.Nonlimited_View_Count (Rules) >= 1
         and then Editor.Ada_Limited_View_Rules.Fingerprint (Rules) /= 0,
         "limited-view rules should retain deterministic counters and fingerprints");
   end Test_Ada_Limited_With_Incomplete_View_Rules;


   procedure Test_Resolver_Selected_Name_Uses_Prefix_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Root is" & ASCII.LF &
        "   type Local_T is private;" & ASCII.LF &
        "   package Nested is" & ASCII.LF &
        "      type Local_T is private;" & ASCII.LF &
        "      procedure Make;" & ASCII.LF &
        "   end Nested;" & ASCII.LF &
        "end Root;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "root.ads");
      Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root");
      Nested_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Nested", Root_Id);
      Selected_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Nested.Local_T", Root_Id);
      Unselected_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Local_T", Nested_Id);
      Selected_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Selected_Id);
   begin
      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol,
              "selected-name resolver test should have a root scope");
      Assert (Nested_Id /= Editor.Ada_Language_Model.No_Symbol,
              "selected-name resolver test should have a nested package scope");
      Assert (Selected_Id /= Editor.Ada_Language_Model.No_Symbol,
              "resolver should support selected names by resolving the prefix scope first");
      Assert (Selected_Id = Unselected_Id,
              "Pkg.Name should resolve to the same declaration as Name inside Pkg scope");
      Assert (Selected_Info.Parent_Symbol = Nested_Id,
              "selected-name lookup should bind to the declaration owned by the selected package");
   end Test_Resolver_Selected_Name_Uses_Prefix_Scope;



   procedure Test_Resolver_Selected_Name_Rejects_Dotted_Child_Leaf
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Pkg_Id : Editor.Ada_Language_Model.Symbol_Id;
      Direct_Id : Editor.Ada_Language_Model.Symbol_Id;
      Nested_Dotted_Id : Editor.Ada_Language_Model.Symbol_Id;
      Selected_Direct : Editor.Ada_Language_Model.Symbol_Id;
      Selected_Missing : Editor.Ada_Language_Model.Symbol_Id;
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      Pkg_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Pkg", Editor.Ada_Language_Model.Symbol_Package, R);
      Direct_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Widget", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol   => Pkg_Id,
         Depth           => 1);
      Nested_Dotted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Inner.Widget", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol   => Pkg_Id,
         Depth           => 1);

      Selected_Direct := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Pkg.Widget", Editor.Ada_Language_Model.No_Symbol);
      Selected_Missing := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Pkg.Missing_Widget", Editor.Ada_Language_Model.No_Symbol);

      Assert (Pkg_Id /= Editor.Ada_Language_Model.No_Symbol,
              "manual selected-name regression should create package scope");
      Assert (Direct_Id /= Editor.Ada_Language_Model.No_Symbol,
              "manual selected-name regression should create direct child");
      Assert (Nested_Dotted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "manual selected-name regression should create dotted child");
      Assert (Selected_Direct = Direct_Id,
              "selected lookup should still resolve direct declarations in the selected scope");
      Assert (Selected_Direct /= Nested_Dotted_Id,
              "selected lookup must not bind to a dotted child by same leaf");
      Assert (Selected_Missing = Editor.Ada_Language_Model.No_Symbol,
              "selected lookup should degrade to no symbol when the selected scope lacks the direct leaf");
   end Test_Resolver_Selected_Name_Rejects_Dotted_Child_Leaf;



   procedure Test_Resolver_Selected_Name_Requires_Matching_Parent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Package_A : Editor.Ada_Language_Model.Symbol_Id;
      Package_B : Editor.Ada_Language_Model.Symbol_Id;
      Mismatched_Widget : Editor.Ada_Language_Model.Symbol_Id;
      Valid_Widget : Editor.Ada_Language_Model.Symbol_Id;
      Selected_Widget : Editor.Ada_Language_Model.Symbol_Id;
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      Package_A := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "A", Editor.Ada_Language_Model.Symbol_Package, R);
      Package_B := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "B", Editor.Ada_Language_Model.Symbol_Package, R);

      Mismatched_Widget := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Widget", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Package_A)),
         Parent_Symbol   => Package_B,
         Depth           => 1);
      Valid_Widget := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Widget", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Package_A)),
         Parent_Symbol   => Package_A,
         Depth           => 1);

      Selected_Widget := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "A.Widget", Editor.Ada_Language_Model.No_Symbol);

      Assert (Package_A /= Editor.Ada_Language_Model.No_Symbol
              and then Package_B /= Editor.Ada_Language_Model.No_Symbol
              and then Mismatched_Widget /= Editor.Ada_Language_Model.No_Symbol
              and then Valid_Widget /= Editor.Ada_Language_Model.No_Symbol,
              "selected-name parent-boundary regression should create scoped rows");
      Assert (Selected_Widget = Valid_Widget,
              "selected-prefix lookup must reject rows whose scope and parent stamps disagree");
      Assert (Selected_Widget /= Mismatched_Widget,
              "mismatched selected child must not be exposed before the valid direct child");
   end Test_Resolver_Selected_Name_Requires_Matching_Parent;



   procedure Test_Resolver_Exact_Selected_Name_Respects_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Outer_Id : Editor.Ada_Language_Model.Symbol_Id;
      Other_Id : Editor.Ada_Language_Model.Symbol_Id;
      Dotted_Id : Editor.Ada_Language_Model.Symbol_Id;
      From_Outer : Editor.Ada_Language_Model.Symbol_Id;
      From_Other : Editor.Ada_Language_Model.Symbol_Id;
      From_Root  : Editor.Ada_Language_Model.Symbol_Id;
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      Outer_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Outer", Editor.Ada_Language_Model.Symbol_Package, R);
      Other_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Other", Editor.Ada_Language_Model.Symbol_Package, R);
      Dotted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Nested.Widget", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Outer_Id)),
         Parent_Symbol   => Outer_Id,
         Depth           => 1);

      From_Outer := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Nested.Widget", Outer_Id);
      From_Other := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Nested.Widget", Other_Id);
      From_Root := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Nested.Widget", Editor.Ada_Language_Model.No_Symbol);

      Assert (Outer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Other_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Dotted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "exact selected-name visibility regression should create symbols");
      Assert (From_Outer = Dotted_Id,
              "exact selected lookup should still resolve declarations visible from the caller scope");
      Assert (From_Other = Editor.Ada_Language_Model.No_Symbol,
              "exact selected lookup must not leak declarations from unrelated lexical scopes");
      Assert (From_Root = Editor.Ada_Language_Model.No_Symbol,
              "non-root exact dotted declarations should not be visible from root lookup");
   end Test_Resolver_Exact_Selected_Name_Respects_Scope;



   procedure Test_Resolver_Unselected_Lookup_Rejects_Dotted_Leaf
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Owner_Id : Editor.Ada_Language_Model.Symbol_Id;
      Dotted_Id : Editor.Ada_Language_Model.Symbol_Id;
      Unselected : Editor.Ada_Language_Model.Symbol_Id;
      Selected : Editor.Ada_Language_Model.Symbol_Id;
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      Owner_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Owner", Editor.Ada_Language_Model.Symbol_Package, R);
      Dotted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Inner.Widget", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Owner_Id)),
         Parent_Symbol   => Owner_Id,
         Depth           => 1);

      Unselected := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Widget", Owner_Id);
      Selected := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Inner.Widget", Owner_Id);

      Assert (Owner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Dotted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "dotted-leaf resolver regression should create scoped symbols");
      Assert (Unselected = Editor.Ada_Language_Model.No_Symbol,
              "unselected scoped lookup must not bind to the leaf of a selected/dotted declaration");
      Assert (Selected = Dotted_Id,
              "exact selected scoped lookup should still resolve the dotted declaration");
   end Test_Resolver_Unselected_Lookup_Rejects_Dotted_Leaf;



   procedure Test_Resolver_Invalid_Scope_Does_Not_Fall_Back_To_Root
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Root_Id : Editor.Ada_Language_Model.Symbol_Id;
      Invalid_Scope : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Language_Model.Symbol_Id (99);
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
      From_Invalid : Editor.Ada_Language_Model.Symbol_Id;
      From_Root : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Root_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Root", Editor.Ada_Language_Model.Symbol_Package, R);

      From_Root := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Root", Editor.Ada_Language_Model.No_Symbol);
      From_Invalid := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Root", Invalid_Scope);

      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol,
              "invalid-scope regression should create a root declaration");
      Assert (From_Root = Root_Id,
              "ordinary root-scope lookup should still resolve root declarations");
      Assert (From_Invalid = Editor.Ada_Language_Model.No_Symbol,
              "invalid scope ids must not fall back to root-scope declarations");
   end Test_Resolver_Invalid_Scope_Does_Not_Fall_Back_To_Root;




   procedure Test_Resolver_Cyclic_Parent_Chain_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      A_Id : Editor.Ada_Language_Model.Symbol_Id;
      B_Id : Editor.Ada_Language_Model.Symbol_Id;
      Missing : Editor.Ada_Language_Model.Symbol_Id;
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      A_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "A", Editor.Ada_Language_Model.Symbol_Package, R,
         Parent_Symbol => Editor.Ada_Language_Model.Symbol_Id (2));
      B_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "B", Editor.Ada_Language_Model.Symbol_Package, R,
         Parent_Symbol => A_Id);

      Missing := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Definitely_Missing", A_Id);

      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol,
              "cyclic parent-chain regression should create the first scope");
      Assert (B_Id /= Editor.Ada_Language_Model.No_Symbol,
              "cyclic parent-chain regression should create the second scope");
      Assert (Missing = Editor.Ada_Language_Model.No_Symbol,
              "cyclic lexical parent chains must degrade to no match instead of looping");
   end Test_Resolver_Cyclic_Parent_Chain_Degrades;



   procedure Test_Resolver_Invalid_Parent_Scope_Does_Not_Expose_Orphans
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Owner_Id : Editor.Ada_Language_Model.Symbol_Id;
      Orphan_Id : Editor.Ada_Language_Model.Symbol_Id;
      Found : Editor.Ada_Language_Model.Symbol_Id;
      Invalid_Parent : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Language_Model.Symbol_Id (99);
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      Owner_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Owner", Editor.Ada_Language_Model.Symbol_Package, R,
         Parent_Symbol => Invalid_Parent);
      Orphan_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Ghost", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Invalid_Parent)),
         Parent_Symbol   => Invalid_Parent,
         Depth           => 2);

      Found := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Ghost", Owner_Id);

      Assert (Owner_Id /= Editor.Ada_Language_Model.No_Symbol,
              "invalid-parent resolver regression should create the starting scope");
      Assert (Orphan_Id /= Editor.Ada_Language_Model.No_Symbol,
              "invalid-parent resolver regression should create the orphan row");
      Assert (Found = Editor.Ada_Language_Model.No_Symbol,
              "resolver must not expose orphan rows through impossible parent-scope ids");
   end Test_Resolver_Invalid_Parent_Scope_Does_Not_Expose_Orphans;



   procedure Test_Resolver_Non_Owner_Start_Scope_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Root_Id : Editor.Ada_Language_Model.Symbol_Id;
      Object_Id : Editor.Ada_Language_Model.Symbol_Id;
      Orphan_Id : Editor.Ada_Language_Model.Symbol_Id;
      Found_From_Object : Editor.Ada_Language_Model.Symbol_Id;
      Found_From_Root : Editor.Ada_Language_Model.Symbol_Id;
      R : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
   begin
      Root_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Root", Editor.Ada_Language_Model.Symbol_Package, R);
      Object_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Obj", Editor.Ada_Language_Model.Symbol_Object, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Root_Id)),
         Parent_Symbol   => Root_Id,
         Depth           => 1);
      Orphan_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Ghost", Editor.Ada_Language_Model.Symbol_Type, R,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Object_Id)),
         Parent_Symbol   => Object_Id,
         Depth           => 2);

      Found_From_Object := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Ghost", Object_Id);
      Found_From_Root := Editor.Ada_Symbol_Resolver.First_Match_In_Scope
        (Analysis, "Root", Editor.Ada_Language_Model.No_Symbol);

      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Object_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Orphan_Id /= Editor.Ada_Language_Model.No_Symbol,
              "non-owner resolver regression should create malformed scoped rows");
      Assert (Found_From_Object = Editor.Ada_Language_Model.No_Symbol,
              "resolver must not accept value-like symbols as lexical starting scopes");
      Assert (Found_From_Root = Root_Id,
              "root-scope lookup should still resolve ordinary root declarations");
   end Test_Resolver_Non_Owner_Start_Scope_Degrades;



   procedure Test_Resolver_Selected_Name_Does_Not_Leaf_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Shared.Widget is" & ASCII.LF &
        "end Shared.Widget;" & ASCII.LF &
        "package Other is" & ASCII.LF &
        "   Widget : Integer;" & ASCII.LF &
        "end Other;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "selected_lookup.ads");
      Shared_Widget : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Shared.Widget");
      Missing_Widget : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Missing.Widget");
      Bare_Widget : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Widget");
   begin
      Assert (Shared_Widget /= Editor.Ada_Language_Model.No_Symbol,
              "resolver should still find parser-preserved exact selected names");
      Assert (Bare_Widget /= Editor.Ada_Language_Model.No_Symbol,
              "bare leaf lookup remains available for ordinary unselected names");
      Assert (Missing_Widget = Editor.Ada_Language_Model.No_Symbol,
              "selected-name resolver queries must not fall back to unrelated leaf symbols");
   end Test_Resolver_Selected_Name_Does_Not_Leaf_Fallback;



   procedure Test_Resolver_Scoped_Selected_Name_Does_Not_Leaf_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Shared.Widget is" & ASCII.LF &
        "end Shared.Widget;" & ASCII.LF &
        "package Other is" & ASCII.LF &
        "   Widget : Integer;" & ASCII.LF &
        "end Other;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "scoped_selected_lookup.ads");
      Other_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Other");
      Shared_Widget : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Shared.Widget", Other_Id);
      Missing_Widget : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Missing.Widget", Other_Id);
      Bare_Widget : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Widget", Other_Id);
   begin
      Assert (Other_Id /= Editor.Ada_Language_Model.No_Symbol,
              "scoped selected-name regression should have a caller scope");
      Assert (Shared_Widget /= Editor.Ada_Language_Model.No_Symbol,
              "scoped resolver should still support exact selected declarations");
      Assert (Bare_Widget /= Editor.Ada_Language_Model.No_Symbol,
              "ordinary unselected lookup should still bind direct declarations in the caller scope");
      Assert (Missing_Widget = Editor.Ada_Language_Model.No_Symbol,
              "scoped selected-name lookup must not fall back to a caller-scope leaf symbol");
   end Test_Resolver_Scoped_Selected_Name_Does_Not_Leaf_Fallback;



   procedure Test_Resolver_Use_Package_Clause_Exposes_Package_Children
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Shared is" & ASCII.LF &
        "   type Widget is private;" & ASCII.LF &
        "end Shared;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   use Shared;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "use_visibility.ads");
      Client_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Client");
      Widget_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Widget", Client_Id);
      Widget_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Widget_Id);
   begin
      Assert (Editor.Ada_Language_Model.Visibility_Clause_Count (Analysis) = 1,
              "parser should retain concrete use-clause metadata, not only an awareness flag");
      Assert (Client_Id /= Editor.Ada_Language_Model.No_Symbol,
              "use-clause resolver regression should have a client scope");
      Assert (Widget_Id /= Editor.Ada_Language_Model.No_Symbol,
              "use package should make package children visible after local lexical lookup fails");
      Assert (To_String (Widget_Info.Name) = "Widget"
              and then Widget_Info.Parent_Symbol /= Editor.Ada_Language_Model.No_Symbol,
              "use package lookup should bind the child declaration owned by the used package");
   end Test_Resolver_Use_Package_Clause_Exposes_Package_Children;



   procedure Test_Resolver_Use_Selected_Nested_Package_Clause
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Parent is" & ASCII.LF &
        "   package Child is" & ASCII.LF &
        "      type Widget is private;" & ASCII.LF &
        "   end Child;" & ASCII.LF &
        "end Parent;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   use Parent.Child;" & ASCII.LF &
        "end Client;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "use_selected_nested_package.ads");
      Client_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Client");
      Widget_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Widget", Client_Id);
      Missing_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Missing_Widget", Client_Id);
      Widget_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Widget_Id);
   begin
      Assert (Client_Id /= Editor.Ada_Language_Model.No_Symbol,
              "selected use-clause regression should have a client scope");
      Assert (Widget_Id /= Editor.Ada_Language_Model.No_Symbol,
              "use Parent.Child should expose direct declarations of the selected nested package");
      Assert (Widget_Info.Parent_Symbol /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Widget_Info.Name) = "Widget",
              "selected nested use-clause lookup should bind the child-owned declaration");
      Assert (Missing_Id = Editor.Ada_Language_Model.No_Symbol,
              "selected nested use-clause lookup must not invent unrelated children");
   end Test_Resolver_Use_Selected_Nested_Package_Clause;



   procedure Test_Language_Model_Private_Child_Package_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "private package Demo.Hidden is" & ASCII.LF &
        "   Value : Integer;" & ASCII.LF &
        "end Demo.Hidden;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo-hidden.ads");
      Hidden_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Demo.Hidden");
      Hidden_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Id);
   begin
      Assert (Hidden_Id /= Editor.Ada_Language_Model.No_Symbol,
              "private child package should be parsed under its real qualified name");
      Assert (To_String (Hidden_Info.Name) = "Demo.Hidden",
              "private child package parser must not duplicate the package keyword");
      Assert (Hidden_Info.Kind = Editor.Ada_Language_Model.Symbol_Package,
              "private child package remains a package symbol");
      Assert (Hidden_Info.Flags.Is_Private,
              "private child package carries private metadata");
   end Test_Language_Model_Private_Child_Package_Name;





   procedure Test_Language_Model_Use_Clauses_Project_Individual_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Shared, Interfaces;" & ASCII.LF &
        "package Use_Metadata is" & ASCII.LF &
        "   use Shared.Helpers, Shared.More;" & ASCII.LF &
        "   use type Shared.Count, Interfaces.Unsigned_32;" & ASCII.LF &
        "   use all type Shared.Count'Class, Interfaces.Integer_32;" & ASCII.LF &
        "   Value : Integer;" & ASCII.LF &
        "end Use_Metadata;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "use_metadata.ads");
      use type Editor.Ada_Language_Model.Visibility_Clause_Kind;

      function Use_Name (Index : Positive) return String is
      begin
         return To_String
           (Editor.Ada_Language_Model.Use_Clause_At
              (Analysis, Editor.Ada_Language_Model.Scope_Id'Last, Index).Name);
      end Use_Name;

      function Use_Kind
        (Index : Positive) return Editor.Ada_Language_Model.Visibility_Clause_Kind
      is
      begin
         return Editor.Ada_Language_Model.Use_Clause_At
           (Analysis, Editor.Ada_Language_Model.Scope_Id'Last, Index).Kind;
      end Use_Kind;
   begin
      Assert (Editor.Ada_Language_Model.Has_Use_Clause_Awareness (Analysis),
              "use clauses should still set bounded use-clause awareness");
      Assert (Editor.Ada_Language_Model.Use_Clause_Count (Analysis) = 6,
              "language model must retain every comma-separated use-clause name separately");
      Assert (Use_Kind (1) = Editor.Ada_Language_Model.Visibility_Use_Package_Clause,
              "ordinary use-clause package names must keep their clause kind");
      Assert (Use_Name (1) = "Shared.Helpers",
              "ordinary use clause must retain the first selected package name");
      Assert (Use_Name (2) = "Shared.More",
              "ordinary use clause must retain the second selected package name");
      Assert (Use_Kind (3) = Editor.Ada_Language_Model.Visibility_Use_Type_Clause,
              "use type names must keep their clause kind");
      Assert (Use_Name (3) = "Shared.Count",
              "use type must retain the first selected subtype mark");
      Assert (Use_Name (4) = "Interfaces.Unsigned_32",
              "use type must retain the second selected subtype mark");
      Assert (Use_Kind (5) = Editor.Ada_Language_Model.Visibility_Use_All_Type_Clause,
              "use all type names must keep their distinct clause kind");
      Assert (Use_Name (5) = "Shared.Count'Class",
              "use all type must retain class-wide subtype marks without degrading to the leaf name");
      Assert (Use_Name (6) = "Interfaces.Integer_32",
              "use all type must retain subsequent subtype marks separately");
   end Test_Language_Model_Use_Clauses_Project_Individual_Metadata;



   procedure Test_Scope_Aware_Semantic_Classification_Uses_Resolver
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Scoped_Semantics is" & ASCII.LF &
        "   type X is private;" & ASCII.LF &
        "   procedure Draw (X : Integer);" & ASCII.LF &
        "end Scoped_Semantics;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "scoped_semantics.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Scoped_Semantics");
      Draw_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Draw", Package_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Draw_Id /= Editor.Ada_Language_Model.No_Symbol,
              "parser should expose package and procedure scopes for semantic classification");

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, "X", Package_Id) = Editor.Syntax.Type_Identifier,
         "scope-aware semantic classification should see the package-level type");

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, "X", Draw_Id) = Editor.Syntax.Parameter_Identifier,
         "scope-aware semantic classification should prefer the procedure parameter over the outer type");

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, "Missing", Draw_Id) = Editor.Syntax.Identifier,
         "unresolved scoped identifiers should degrade to ordinary identifiers");
   end Test_Scope_Aware_Semantic_Classification_Uses_Resolver;


   procedure Test_Language_Model_Same_Line_Private_Section_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Private_Tail is" & ASCII.LF &
        "   Public_Value : Integer;" & ASCII.LF &
        "   private; Hidden_Value : Integer; type Hidden_Type is private;" & ASCII.LF &
        "end Same_Line_Private_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_private_tail.ads");
      Public_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Public_Value");
      Hidden_Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hidden_Value");
      Hidden_Type_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hidden_Type");
      Public_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Public_Id);
      Hidden_Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Value_Id);
      Hidden_Type_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Type_Id);
   begin
      Assert (Public_Id /= Editor.Ada_Language_Model.No_Symbol
              and then not Public_Info.Flags.Is_Private,
              "declarations before a compact private marker must remain public");
      Assert (Hidden_Value_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Value_Info.Flags.Is_Private
              and then Hidden_Value_Info.Declaration_Column > 12,
              "same-line private marker should make following object declaration private and preserve tail column");
      Assert (Hidden_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Type_Info.Kind = Editor.Ada_Language_Model.Symbol_Type
              and then Hidden_Type_Info.Flags.Is_Private
              and then Hidden_Type_Info.Declaration_Column > Hidden_Value_Info.Declaration_Column,
              "same-line private marker should keep later same-line declarations private");
   end Test_Language_Model_Same_Line_Private_Section_Tail;



   procedure Test_Language_Model_One_Line_Selected_Name_With_Spaced_Dots_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Selected_Spaced_Dots is procedure Parent_Unit . Child_Run is Parent_Unit : declare Block_Local : Integer; begin null; end Parent_Unit; Child_After : Integer; end Parent_Unit . Child_Run; Outer_After : Integer; end One_Line_Selected_Spaced_Dots;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_selected_spaced_dots_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Selected_Spaced_Dots");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Parent_Unit.Child_Run");
      Child_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Child_After", Run_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Outer_After", Package_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      Child_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_After_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Package_Id,
              "selected callable with layout around dots should remain package-body local");
      Assert (Child_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Child_After_Info.Parent_Symbol = Run_Id,
              "inner same-prefix end must not close a spaced selected callable body");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Package_Id,
              "declarations after the exact spaced selected end should resume in package-body scope");
   end Test_Language_Model_One_Line_Selected_Name_With_Spaced_Dots_Tail;









   procedure Test_Language_Model_Invalid_Parent_Child_Lookup_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Owner_Id : Editor.Ada_Language_Model.Symbol_Id;
      Orphan_Id : Editor.Ada_Language_Model.Symbol_Id;
      Invalid_Parent : constant Editor.Ada_Language_Model.Symbol_Id := 99;
   begin
      Owner_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Owner",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 5));
      Orphan_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Orphan",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 10),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Invalid_Parent)),
         Parent_Symbol => Invalid_Parent);

      Assert (Owner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Orphan_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert both the valid owner and malformed child row");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Owner_Id) = 0,
              "valid owner with no direct children should report zero children");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Invalid_Parent) = 0,
              "invalid parent ids must not expose malformed child rows");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Invalid_Parent, 1)
              = Editor.Ada_Language_Model.No_Symbol,
              "invalid parent child lookup should degrade to No_Symbol");
   end Test_Language_Model_Invalid_Parent_Child_Lookup_Degrades;





   procedure Test_Language_Model_Self_Parent_Child_Lookup_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Self_Id  : Editor.Ada_Language_Model.Symbol_Id;
      Child_Id : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Self_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Loop",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 4),
         Parent_Symbol => Editor.Ada_Language_Model.Symbol_Id (1));
      Child_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Real_Child",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 13),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Self_Id)),
         Parent_Symbol => Self_Id);

      Assert (Self_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert a self-parented owner plus a real child");
      Assert (Editor.Ada_Language_Model.Symbol (Analysis, Self_Id).Parent_Symbol = Self_Id,
              "test setup should retain the malformed self-parent edge");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Self_Id) = 1,
              "self-parent edge must not be exposed as a child row");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Self_Id, 1) = Child_Id,
              "first exposed child should be the real nested symbol");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Self_Id, 2)
              = Editor.Ada_Language_Model.No_Symbol,
              "self-parent edge should not consume a child position");
   end Test_Language_Model_Self_Parent_Child_Lookup_Degrades;


   procedure Test_Language_Model_Non_Owner_Parent_Child_Lookup_Degrades
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Pkg_Id   : Editor.Ada_Language_Model.Symbol_Id;
      Obj_Id   : Editor.Ada_Language_Model.Symbol_Id;
      Bad_Id   : Editor.Ada_Language_Model.Symbol_Id;
      Good_Id  : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Pkg_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Pkg",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 3));
      Obj_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Obj",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 6),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id);
      Bad_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Bad_Child",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 3, Start_Column => 7, End_Line => 3, End_Column => 15),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Obj_Id)),
         Parent_Symbol => Obj_Id);
      Good_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Good_Child",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 14),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Pkg_Id)),
         Parent_Symbol => Pkg_Id);

      Assert (Pkg_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Obj_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Bad_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Good_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain owner, value-like parent, and child rows");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Obj_Id) = 0,
              "value-like parent symbols must not expose child rows");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Obj_Id, 1)
              = Editor.Ada_Language_Model.No_Symbol,
              "value-like parent child lookup should degrade to No_Symbol");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Pkg_Id) = 2,
              "declaration-owning package parent should still expose direct children");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Pkg_Id, 1) = Obj_Id
              and then Editor.Ada_Language_Model.Child_At (Analysis, Pkg_Id, 2) = Good_Id,
              "valid package child traversal should preserve deterministic order");
   end Test_Language_Model_Non_Owner_Parent_Child_Lookup_Degrades;



   procedure Test_Language_Model_Child_Lookup_Requires_Matching_Scope
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Package_A : Editor.Ada_Language_Model.Symbol_Id;
      Package_B : Editor.Ada_Language_Model.Symbol_Id;
      Mismatched_Child : Editor.Ada_Language_Model.Symbol_Id;
      Valid_Child : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Package_A := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "A",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      Package_B := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "B",
         Editor.Ada_Language_Model.Symbol_Package,
         (Start_Line => 2, Start_Column => 1, End_Line => 2, End_Column => 1));

      Mismatched_Child := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Wrong_Scope",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 14),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Package_B),
         Parent_Symbol   => Package_A,
         Depth           => 1);
      Valid_Child := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Right_Scope",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 14),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Package_A),
         Parent_Symbol   => Package_A,
         Depth           => 1);

      Assert (Package_A /= Editor.Ada_Language_Model.No_Symbol
                and then Package_B /= Editor.Ada_Language_Model.No_Symbol
                and then Mismatched_Child /= Editor.Ada_Language_Model.No_Symbol
                and then Valid_Child /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert package parents and child rows");
      Assert (Editor.Ada_Language_Model.Child_Count (Analysis, Package_A) = 1,
              "child traversal must reject rows whose parent and scope stamps disagree");
      Assert (Editor.Ada_Language_Model.Child_At (Analysis, Package_A, 1) = Valid_Child,
              "valid direct child remains visible after rejecting mismatched ownership");
      Assert (Editor.Ada_Language_Model.Child_At
                (Analysis, Package_A, 2) = Editor.Ada_Language_Model.No_Symbol,
              "mismatched ownership row is not exposed at a later child index");
   end Test_Language_Model_Child_Lookup_Requires_Matching_Scope;



   procedure Test_Resolver_Compatibility_Unselected_Lookup_Rejects_Dotted_Leaf
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Dotted_Id : Editor.Ada_Language_Model.Symbol_Id;
      Direct_Id : Editor.Ada_Language_Model.Symbol_Id;
      Exact_Id  : Editor.Ada_Language_Model.Symbol_Id;
      Leaf_Id   : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Dotted_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Inner.Widget",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 12));

      Assert (Dotted_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert a preserved selected declaration name");

      Exact_Id := Editor.Ada_Symbol_Resolver.First_Match
        (Analysis, "Inner.Widget");
      Leaf_Id := Editor.Ada_Symbol_Resolver.First_Match
        (Analysis, "Widget");

      Assert (Exact_Id = Dotted_Id,
              "compatibility resolver should still resolve exact selected names");
      Assert (Leaf_Id = Editor.Ada_Language_Model.No_Symbol,
              "compatibility resolver must not bind unselected lookup to dotted declaration leaves");

      Direct_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Widget",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 2, Start_Column => 1, End_Line => 2, End_Column => 6));

      Assert (Direct_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert a direct declaration after the dotted one");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Widget") = Direct_Id,
              "direct unselected declarations should remain resolvable");
   end Test_Resolver_Compatibility_Unselected_Lookup_Rejects_Dotted_Leaf;




   procedure Test_Semantic_Scope_For_Position_Uses_Parser_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   type Value is null record;" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.adb");
      Scope : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Language_Model.Scope_For_Position (Analysis, 5, 7);
   begin
      Assert
        (Scope /= Editor.Ada_Language_Model.No_Symbol,
         "scope bridge must retain the procedure body owner for tokens inside its body");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, "Value", Scope) = Editor.Syntax.Parameter_Identifier,
         "scope-aware semantic lookup must prefer the local object over the enclosing type");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
           (Analysis, "Run", Scope) = Editor.Syntax.Subprogram_Identifier,
         "scope-aware semantic lookup still walks out to enclosing callable declarations");
   end Test_Semantic_Scope_For_Position_Uses_Parser_Ownership;



   procedure Test_Semantic_Scope_For_Position_Respects_Source_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Package_Id : Editor.Ada_Language_Model.Symbol_Id;
      Run_Id     : Editor.Ada_Language_Model.Symbol_Id;
   begin
      --  pass 189: the scope bridge must not keep using the
      --  deepest owner that merely started before the token after that
      --  owner's parser-retained source range has ended.
      Package_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Demo",
         Editor.Ada_Language_Model.Symbol_Package_Body,
         (Start_Line => 1, Start_Column => 1, End_Line => 6, End_Column => 9),
         Declaration_Column => 1,
         Depth => 1,
         Flags => (Is_Body => True, others => False));

      Run_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Run",
         Editor.Ada_Language_Model.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 4, End_Column => 11),
         Declaration_Column => 4,
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Package_Id),
         Parent_Symbol => Package_Id,
         Depth => 2,
         Flags => (Is_Body => True, others => False));

      Assert
        (Editor.Ada_Language_Model.Scope_For_Position (Analysis, 3, 7) = Run_Id,
         "scope bridge should use the inner owner while the token is inside its retained range");
      Assert
        (Editor.Ada_Language_Model.Scope_For_Position (Analysis, 5, 7) = Package_Id,
         "scope bridge must fall back to the enclosing package after the inner body range ends");
      Assert
        (Editor.Ada_Language_Model.Scope_For_Position (Analysis, 7, 1) =
           Editor.Ada_Language_Model.No_Symbol,
         "scope bridge must degrade to root after all retained owner ranges end");
   end Test_Semantic_Scope_For_Position_Respects_Source_Ranges;





   procedure Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Generic_Id : Editor.Ada_Language_Model.Symbol_Id;
      Formal_Type_Id : Editor.Ada_Language_Model.Symbol_Id;
      Template_Get_Id : Editor.Ada_Language_Model.Symbol_Id;
      Owner_Id : Editor.Ada_Language_Model.Symbol_Id;
      Actual_Type_Id : Editor.Ada_Language_Model.Symbol_Id;
      Formal_Package_Id : Editor.Ada_Language_Model.Symbol_Id;
      Result : Editor.Ada_Symbol_Resolver.Resolution_Result;
      Inferred : Unbounded_String;
   begin
      Generic_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Generic_Maps",
         Editor.Ada_Language_Model.Symbol_Generic_Package,
         (Start_Line => 1, Start_Column => 9, End_Line => 1, End_Column => 20));
      Formal_Type_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Element",
         Editor.Ada_Language_Model.Symbol_Generic_Formal_Type,
         (Start_Line => 2, Start_Column => 9, End_Line => 2, End_Column => 15),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Generic_Id)),
         Parent_Symbol => Generic_Id,
         Depth => 1);
      Template_Get_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Get",
         Editor.Ada_Language_Model.Symbol_Function,
         (Start_Line => 3, Start_Column => 13, End_Line => 3, End_Column => 15),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Generic_Id)),
         Parent_Symbol => Generic_Id,
         Depth => 1,
         Profile_Summary => "function Get return Element");
      Owner_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Consumer",
         Editor.Ada_Language_Model.Symbol_Generic_Package,
         (Start_Line => 4, Start_Column => 9, End_Line => 4, End_Column => 16));
      Actual_Type_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Actual_Element",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 5, Start_Column => 9, End_Line => 5, End_Column => 22),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Owner_Id)),
         Parent_Symbol => Owner_Id,
         Depth => 1);
      Formal_Package_Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Maps",
         Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
         (Start_Line => 6, Start_Column => 17, End_Line => 6, End_Column => 20),
         Enclosing_Scope => Editor.Ada_Language_Model.Scope_Id (Natural (Owner_Id)),
         Parent_Symbol => Owner_Id,
         Depth => 1,
         Target_Name => "Generic_Maps");
      Editor.Ada_Language_Model.Add_Generic_Actual
        (Analysis,
         Formal_Package_Id,
         Formal_Name => "Element",
         Actual_Name => "Actual_Element",
         Position => 1,
         Source_Span => (Start_Line => 6, Start_Column => 43,
                   End_Line => 6, End_Column => 68));

      Assert (Generic_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Template_Get_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Owner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Actual_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should retain generic template, actual type, and formal package rows");

      Result := Editor.Ada_Symbol_Resolver.Resolve_In_Scope
        (Analysis, "Maps.Get", Owner_Id);
      Assert (Natural (Result.Matches.Length) = 1
              and then Result.Matches.First_Element = Template_Get_Id,
              "selected lookup through a formal package should expose the generic template child");

      Inferred := To_Unbounded_String
        (Editor.Ada_Symbol_Resolver.Infer_Expression_Type_In_Scope
           (Analysis, "Maps.Get", Owner_Id));
      Assert (To_String (Inferred) = "Actual_Element",
              "formal package named actuals should substitute generic formal result types in resolver inference");
   end Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View;




   procedure Test_Ada_Direct_Visibility_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      use type Editor.Ada_Direct_Visibility.Declaration_Id;
      use type Editor.Ada_Direct_Visibility.Declaration_Kind;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Visibility_Root is" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   Shared : Element;" & ASCII.LF &
        "   procedure Worker;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Hidden : Element;" & ASCII.LF &
        "end Visibility_Root;" & ASCII.LF &
        "package body Visibility_Root is" & ASCII.LF &
        "   Shared : Integer;" & ASCII.LF &
        "   procedure Worker is" & ASCII.LF &
        "      Local : Integer;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Visibility_Root;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);

      function First_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
            begin
               if Info.Kind = Kind then
                  return Info.Id;
               end if;
            end;
         end loop;
         return Editor.Ada_Declarative_Regions.No_Region;
      end First_Region;

      function Last_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
         Result : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
            begin
               if Info.Kind = Kind then
                  Result := Info.Id;
               end if;
            end;
         end loop;
         return Result;
      end Last_Region;

      Compilation : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Compilation);
      Package_Spec : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Package_Spec);
      Package_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Package_Body);
      Worker_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Last_Region (Editor.Ada_Declarative_Regions.Region_Subprogram_Body);

      Package_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Direct
          (Visibility, Compilation, "visibility_root");
      Element_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Direct
          (Visibility, Package_Spec, "ELEMENT");
      Body_Shared_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Direct
          (Visibility, Package_Body, "shared");
      Visible_Local_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible
          (Visibility, Regions, Worker_Body, "local");
      Visible_Shared_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible
          (Visibility, Regions, Worker_Body, "shared");
   begin
      Assert (Editor.Ada_Direct_Visibility.Has_Declarations (Visibility),
              "direct-visibility model must retain declarations from the syntax tree");
      Assert (Package_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "compilation region must directly contain the package declaration");
      Assert (Editor.Ada_Direct_Visibility.Declaration
                (Visibility, Package_Lookup.Declaration).Kind =
              Editor.Ada_Direct_Visibility.Declaration_Package,
              "package lookup must classify package declarations");
      Assert (Element_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "package spec direct lookup must find visible type declarations case-insensitively");
      Assert (Editor.Ada_Direct_Visibility.Declaration
                (Visibility, Element_Lookup.Declaration).Kind =
              Editor.Ada_Direct_Visibility.Declaration_Type,
              "type declarations must be classified for later type resolution");
      Assert (Body_Shared_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "package body direct lookup must find body-local declarations");
      Assert (Visible_Local_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "visible lookup must search the current subprogram body region first");
      Assert (Visible_Local_Lookup.Region = Worker_Body,
              "local declaration lookup must resolve in the innermost region");
      Assert (Visible_Shared_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "visible lookup must continue through enclosing regions");
      Assert (Visible_Shared_Lookup.Region = Package_Body,
              "enclosing package-body declaration must shadow outer homographs for the current pass");
      Assert (Editor.Ada_Direct_Visibility.Fingerprint (Visibility) /= 0,
              "direct-visibility model must expose deterministic non-zero fingerprints");
   end Test_Ada_Direct_Visibility_Foundation;





   procedure Test_Ada_Use_Visibility_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Use_Visibility.Use_Clause_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Library is" & ASCII.LF &
        "   Exported : Integer;" & ASCII.LF &
        "   Collide : Integer;" & ASCII.LF &
        "end Library;" & ASCII.LF &
        "package Other is" & ASCII.LF &
        "   Collide : Integer;" & ASCII.LF &
        "end Other;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   use Library, Other;" & ASCII.LF &
        "   use type Library.Exported;" & ASCII.LF &
        "   use all type Library.Exported;" & ASCII.LF &
        "   procedure Worker is" & ASCII.LF &
        "      Direct : Integer;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);

      function Last_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
         Result : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
            begin
               if Info.Kind = Kind then
                  Result := Info.Id;
               end if;
            end;
         end loop;
         return Result;
      end Last_Region;

      function Count_Kind
        (Kind : Editor.Ada_Use_Visibility.Use_Clause_Kind) return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Use_Visibility.Use_Clause_Count (Uses) loop
            if Editor.Ada_Use_Visibility.Use_Clause_At (Uses, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Kind;

      Package_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Last_Region (Editor.Ada_Declarative_Regions.Region_Package_Body);
      Worker_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Last_Region (Editor.Ada_Declarative_Regions.Region_Subprogram_Body);
      Exported_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Use_Visibility.Lookup_Visible
          (Visibility, Uses, Regions, Package_Body, "Exported");
      Collide_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Use_Visibility.Lookup_Visible
          (Visibility, Uses, Regions, Package_Body, "Collide");
      Direct_Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Use_Visibility.Lookup_Visible
          (Visibility, Uses, Regions, Worker_Body, "Direct");
   begin
      Assert (Editor.Ada_Use_Visibility.Has_Use_Clauses (Uses),
              "use-visibility model must extract use clauses from the syntax tree");
      Assert (Package_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "package body region must exist for use-clause ownership");
      Assert (Editor.Ada_Use_Visibility.Direct_Use_Clause_Count (Uses, Package_Body) >= 4,
              "package-body region must own package, use-type, and use-all-type clauses");
      Assert (Count_Kind (Editor.Ada_Use_Visibility.Use_Package_Clause) >= 2,
              "ordinary use clauses must be split into one package-use clause per name");
      Assert (Count_Kind (Editor.Ada_Use_Visibility.Use_Type_Clause) >= 1,
              "use type clauses must retain distinct clause metadata");
      Assert (Count_Kind (Editor.Ada_Use_Visibility.Use_All_Type_Clause) >= 1,
              "use all type clauses must retain distinct clause metadata");
      Assert (Exported_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "package use visibility must make directly declared package members visible");
      Assert (Collide_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous,
              "multiple package use clauses exposing the same name must report deterministic ambiguity");
      Assert (Direct_Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found,
              "direct declarations in the current region must still shadow use-clause lookup");
      Assert (Editor.Ada_Use_Visibility.Fingerprint (Uses) /= 0,
              "use-visibility model must expose deterministic non-zero fingerprints");
   end Test_Ada_Use_Visibility_Foundation;




   procedure Test_Ada_Selected_Name_Resolution_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Library is" & ASCII.LF &
        "   Exported : Integer;" & ASCII.LF &
        "   Hidden : Integer;" & ASCII.LF &
        "end Library;" & ASCII.LF &
        "package body Client is" & ASCII.LF &
        "   use Library;" & ASCII.LF &
        "   Value : Integer := Library.Exported;" & ASCII.LF &
        "   Missing_Value : Integer := Library.Absent;" & ASCII.LF &
        "   Missing_Prefix : Integer := Unknown.Member;" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Uses : constant Editor.Ada_Use_Visibility.Use_Visibility_Model :=
        Editor.Ada_Use_Visibility.Build (Tree, Regions, Visibility);
      Selected : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Model :=
        Editor.Ada_Selected_Name_Resolution.Build (Tree, Regions, Visibility, Uses);

      function Last_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
         Result : Editor.Ada_Declarative_Regions.Region_Id :=
           Editor.Ada_Declarative_Regions.No_Region;
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
            begin
               if Info.Kind = Kind then
                  Result := Info.Id;
               end if;
            end;
         end loop;
         return Result;
      end Last_Region;

      function Count_Status
        (Status : Editor.Ada_Selected_Name_Resolution.Selected_Name_Status)
         return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Selected_Name_Resolution.Selected_Name_Count (Selected) loop
            if Editor.Ada_Selected_Name_Resolution.Selected_Name_At (Selected, Index).Status = Status then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Status;

      Package_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Last_Region (Editor.Ada_Declarative_Regions.Region_Package_Body);
      Found : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
        Editor.Ada_Selected_Name_Resolution.Resolve_Selected
          (Tree, Regions, Visibility, Uses, Package_Body, "Library.Exported");
      Missing_Selector : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
        Editor.Ada_Selected_Name_Resolution.Resolve_Selected
          (Tree, Regions, Visibility, Uses, Package_Body, "Library.Absent");
      Missing_Prefix : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
        Editor.Ada_Selected_Name_Resolution.Resolve_Selected
          (Tree, Regions, Visibility, Uses, Package_Body, "Unknown.Member");
   begin
      Assert (Editor.Ada_Selected_Name_Resolution.Has_Selected_Names (Selected),
              "selected-name resolution model must retain selected-name syntax-tree nodes");
      Assert (Package_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "package body region must exist for selected-name resolution context");
      Assert (Found.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Found,
              "selected-name resolution must resolve package prefix and direct selector declaration");
      Assert (Found.Prefix_Declaration /= Editor.Ada_Direct_Visibility.No_Declaration,
              "resolved selected name must retain prefix declaration id");
      Assert (Found.Prefix_Region /= Editor.Ada_Declarative_Regions.No_Region,
              "resolved package prefix must expose its nested declarative region");
      Assert (Found.Selector_Declaration /= Editor.Ada_Direct_Visibility.No_Declaration,
              "resolved selected name must retain selector declaration id");
      Assert (Missing_Selector.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Selector_Not_Found,
              "selected-name resolution must distinguish missing selectors from missing prefixes");
      Assert (Missing_Prefix.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Prefix_Not_Found,
              "selected-name resolution must report unresolved prefixes deterministically");
      Assert (Count_Status (Editor.Ada_Selected_Name_Resolution.Selected_Name_Found) >= 1,
              "built selected-name model must include at least one resolved selected name");
      Assert (Editor.Ada_Selected_Name_Resolution.Fingerprint (Selected) /= 0,
              "selected-name model must expose deterministic non-zero fingerprints");
   end Test_Ada_Selected_Name_Resolution_Foundation;



   procedure Test_Ada_Private_View_Visibility_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_View_Status;
      use type Editor.Ada_Private_View_Visibility.Private_View_Status;
      use type Editor.Ada_Private_View_Visibility.Private_View_Context_Status;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "package Secret_Box is" & ASCII.LF &
        "   type Handle is private;" & ASCII.LF &
        "   procedure Public_Use (X : Handle);" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Handle is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Private_Use (X : Handle);" & ASCII.LF &
        "end Secret_Box;" & ASCII.LF &
        "package body Secret_Box is" & ASCII.LF &
        "   procedure Public_Use (X : Handle) is null;" & ASCII.LF &
        "   procedure Private_Use (X : Handle) is null;" & ASCII.LF &
        "end Secret_Box;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Private_Views : constant Editor.Ada_Private_View_Visibility.Private_View_Model :=
        Editor.Ada_Private_View_Visibility.Build (Tree, Regions, Types);
      Partial : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Package_Spec : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Package_Body : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
   begin
      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if To_String (Info.Normalized_Name) = "handle"
              and then Info.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Partial
            then
               Partial := Info.Id;
               Package_Spec := Info.Region;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, Index);
         begin
            if Info.Kind = Editor.Ada_Declarative_Regions.Region_Package_Body
              and then To_String (Info.Label) = "Secret_Box"
            then
               Package_Body := Info.Id;
            end if;
         end;
      end loop;

      Assert (Partial /= Editor.Ada_Type_Graph.No_Type,
              "private-view visibility test must find the partial Handle type");
      Assert (Editor.Ada_Private_View_Visibility.Private_View_Count (Private_Views) >= 1,
              "private-view visibility must stage private partial/full view entries");

      declare
         View : constant Editor.Ada_Private_View_Visibility.Private_View_Info :=
           Editor.Ada_Private_View_Visibility.Private_View_Node
             (Private_Views,
              Editor.Ada_Private_View_Visibility.Private_View_For_Partial
                (Private_Views, Partial));
      begin
         Assert (View.Status = Editor.Ada_Private_View_Visibility.Private_View_Full_View_Linked,
                 "private-view visibility must link partial and full views with the private part");
         Assert (View.Full_Type /= Editor.Ada_Type_Graph.No_Type,
                 "private-view visibility must retain the full view type id");
         Assert (View.Package_Spec_Region = Package_Spec,
                 "private-view visibility must retain the package spec region");
         Assert (View.Package_Body_Region = Package_Body,
                 "private-view visibility must retain the matching package body region");
         Assert (View.Private_Part_Line = 4,
                 "private-view visibility must retain the private part boundary line");
      end;

      Assert
        (Editor.Ada_Private_View_Visibility.View_Status_At_Line
           (Private_Views, Regions, Partial, Package_Spec, 2) =
         Editor.Ada_Private_View_Visibility.Private_View_Context_Partial_Only,
         "visible part of a package spec must expose only the partial private view");
      Assert
        (Editor.Ada_Private_View_Visibility.View_Status_At_Line
           (Private_Views, Regions, Partial, Package_Spec, 5) =
         Editor.Ada_Private_View_Visibility.Private_View_Context_Full_View,
         "private part of a package spec must expose the full private view");
      Assert
        (Editor.Ada_Private_View_Visibility.Full_View_Visible_At_Line
           (Private_Views, Regions, Partial, Package_Body, 11),
         "package body must expose the full private view");
      Assert (Editor.Ada_Private_View_Visibility.Fingerprint (Private_Views) /= 0,
              "private-view visibility model must preserve deterministic fingerprints");
   end Test_Ada_Private_View_Visibility_Foundation;



   procedure Test_Language_Model_Legality_Visibility_Clause_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ada.Text_IO;" & ASCII.LF &
        "with Ada.Text_IO;" & ASCII.LF &
        "package P is" & ASCII.LF &
        "   use Ada.Strings.Unbounded, Ada.Strings.Unbounded;" & ASCII.LF &
        "   use type Interfaces.C.int;" & ASCII.LF &
        "   use type Interfaces.C.int;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Duplicate_Visibility_Count : Natural := 0;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "duplicate visibility clauses should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Duplicate_Visibility_Clause then
               Duplicate_Visibility_Count := Duplicate_Visibility_Count + 1;
            end if;
         end;
      end loop;

      Assert (Duplicate_Visibility_Count >= 3,
              "legality checking should flag duplicate with/use/use type clauses");
   end Test_Language_Model_Legality_Visibility_Clause_Pass;


   overriding function Name (T : Visibility_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Visibility");
   end Name;

   overriding procedure Register_Tests (T : in out Visibility_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Private_Section_Flags'Access, Name => "language model parser flags private section declarations");
      Add_Test (Routine => Test_Ada_Limited_With_Incomplete_View_Rules'Access, Name => "Ada limited-with visibility projects incomplete-view rules into semantic lookup");
      Add_Test (Routine => Test_Resolver_Selected_Name_Uses_Prefix_Scope'Access, Name => "Ada resolver selected names use the selected prefix scope");
      Add_Test (Routine => Test_Resolver_Selected_Name_Rejects_Dotted_Child_Leaf'Access, Name => "Ada resolver selected names reject dotted child leaf fallback");
      Add_Test (Routine => Test_Resolver_Selected_Name_Requires_Matching_Parent'Access, Name => "Ada resolver selected names require matching parent ownership");
      Add_Test (Routine => Test_Resolver_Exact_Selected_Name_Respects_Scope'Access, Name => "selected-name resolver exact dotted lookup respects lexical scope visibility");
      Add_Test (Routine => Test_Resolver_Unselected_Lookup_Rejects_Dotted_Leaf'Access, Name => "symbol resolver unselected scoped lookup rejects dotted declaration leaves");
      Add_Test (Routine => Test_Resolver_Invalid_Scope_Does_Not_Fall_Back_To_Root'Access, Name => "resolver rejects invalid lexical scope ids instead of falling back to root");
      Add_Test (Routine => Test_Resolver_Cyclic_Parent_Chain_Degrades'Access, Name => "resolver bounds cyclic lexical parent chains");
      Add_Test (Routine => Test_Resolver_Invalid_Parent_Scope_Does_Not_Expose_Orphans'Access, Name => "resolver rejects impossible parent-scope orphan rows");
      Add_Test (Routine => Test_Resolver_Non_Owner_Start_Scope_Degrades'Access, Name => "resolver rejects value-like symbols as lexical starting scopes");
      Add_Test (Routine => Test_Resolver_Selected_Name_Does_Not_Leaf_Fallback'Access, Name => "selected-name resolver lookup does not fall back to leaf-only matches");
      Add_Test (Routine => Test_Resolver_Scoped_Selected_Name_Does_Not_Leaf_Fallback'Access, Name => "scoped selected-name resolver lookup does not fall back to leaf-only matches");
      Add_Test (Routine => Test_Resolver_Use_Package_Clause_Exposes_Package_Children'Access, Name => "resolver uses retained use package clauses for scoped child visibility");
      Add_Test (Routine => Test_Resolver_Use_Selected_Nested_Package_Clause'Access, Name => "resolver use selected nested package clause exposes child visibility");
      Add_Test (Routine => Test_Language_Model_Private_Child_Package_Name'Access, Name => "language model parser keeps private child package names canonical");
      Add_Test (Routine => Test_Language_Model_Use_Clauses_Project_Individual_Metadata'Access, Name => "language model parser projects individual use-clause names as visibility metadata");
      Add_Test (Routine => Test_Scope_Aware_Semantic_Classification_Uses_Resolver'Access, Name => "semantic colouring classifies identifiers through scoped resolver lookup");
      Add_Test (Routine => Test_Language_Model_Same_Line_Private_Section_Tail'Access, Name => "language model parser retains same-line private-section declaration tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Selected_Name_With_Spaced_Dots_Tail'Access, Name => "language model parser matches compact selected names with spaced dots");
      Add_Test (Routine => Test_Language_Model_Invalid_Parent_Child_Lookup_Degrades'Access, Name => "language model child lookup rejects invalid parent ids");
      Add_Test (Routine => Test_Language_Model_Self_Parent_Child_Lookup_Degrades'Access, Name => "language model child lookup rejects self-parent edges");
      Add_Test (Routine => Test_Language_Model_Non_Owner_Parent_Child_Lookup_Degrades'Access, Name => "language model child lookup rejects value-like parent ids");
      Add_Test (Routine => Test_Language_Model_Child_Lookup_Requires_Matching_Scope'Access, Name => "language model child lookup requires matching parent and scope stamps");
      Add_Test (Routine => Test_Resolver_Compatibility_Unselected_Lookup_Rejects_Dotted_Leaf'Access, Name => "compatibility resolver unselected lookup rejects dotted declaration leaves");
      Add_Test (Routine => Test_Semantic_Scope_For_Position_Uses_Parser_Ownership'Access, Name => "semantic colouring uses parser-owned scope for token position");
      Add_Test (Routine => Test_Semantic_Scope_For_Position_Respects_Source_Ranges'Access, Name => "semantic scope bridge respects retained source ranges");
      Add_Test (Routine => Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View'Access, Name => "formal package actuals feed selected resolver and type inference metadata");
      Add_Test (Routine => Test_Ada_Direct_Visibility_Foundation'Access, Name => "Ada direct-visibility model performs deterministic enclosing-region lookup");
      Add_Test (Routine => Test_Ada_Use_Visibility_Foundation'Access, Name => "Ada use-visibility model layers package use clauses over direct visibility");
      Add_Test (Routine => Test_Ada_Selected_Name_Resolution_Foundation'Access, Name => "Ada selected-name resolution resolves package prefixes and selectors");
      Add_Test (Routine => Test_Ada_Private_View_Visibility_Foundation'Access, Name => "Ada private-view visibility distinguishes visible, private, and body contexts");
      Add_Test (Routine => Test_Language_Model_Legality_Visibility_Clause_Pass'Access, Name => "language model checks duplicate visibility clause legality");
   end Register_Tests;

end Editor.Syntax_Semantics.Visibility_Tests;
