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

package body Editor.Syntax_Semantics.Tests is

   function Name (T : Syntax_Semantics_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Tests");
   end Name;


   procedure Test_Outline_Labels_Contribute_Symbol_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Items : constant Editor.Outline.Outline_Item_Array (1 .. 3) :=
        (1 => (Kind        => Editor.Outline.Outline_Procedure,
               Label       => To_Unbounded_String ("procedure body Draw"),
               Detail      => To_Unbounded_String ("line 1 body"),
               Depth       => 0,
               Target_Kind => Editor.Outline.Buffer_Position_Target,
               Buffer_Token => 1,
               Line        => 1,
               Column      => 1),
         2 => (Kind        => Editor.Outline.Outline_Type,
               Label       => To_Unbounded_String ("record type Color"),
               Detail      => To_Unbounded_String ("line 2 record"),
               Depth       => 0,
               Target_Kind => Editor.Outline.Buffer_Position_Target,
               Buffer_Token => 1,
               Line        => 2,
               Column      => 1),
         3 => (Kind        => Editor.Outline.Outline_Package,
               Label       => To_Unbounded_String ("package Renderer renames"),
               Detail      => To_Unbounded_String ("line 3 renames"),
               Depth       => 0,
               Target_Kind => Editor.Outline.Buffer_Position_Target,
               Buffer_Token => 1,
               Line        => 3,
               Column      => 1));
   begin
      Editor.Syntax_Semantics.Build_Map_From_Outline (Map, Items);

      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Draw") =
              Editor.Syntax.Subprogram_Identifier,
              "outline display labels must contribute the declared subprogram name");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Color") =
              Editor.Syntax.Type_Identifier,
              "outline display labels must contribute the declared type name");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Renderer") =
              Editor.Syntax.Package_Identifier,
              "outline renames labels must strip display suffixes");
   end Test_Outline_Labels_Contribute_Symbol_Names;


   procedure Test_Symbol_Cap_Degrades_To_Identifiers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      for I in 1 .. Editor.Syntax_Semantics.Max_Local_Symbols + 1 loop
         declare
            Img : constant String := Natural'Image (I);
            Suffix : constant String := Img (Img'First + 1 .. Img'Last);
         begin
            Editor.Syntax_Semantics.Learn_Declarations_From_Line
              (Map, "type T" & Suffix & " is null record;");
         end;
      end loop;

      Assert
        (Editor.Syntax_Semantics.Symbol_Count (Map) =
           Editor.Syntax_Semantics.Max_Local_Symbols,
         "semantic map must retain only its bounded symbol budget");
      Assert
        (Editor.Syntax_Semantics.Symbol_Cap_Reached (Map),
         "semantic map must expose symbol-cap degradation explicitly");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "T1") =
           Editor.Syntax.Type_Identifier,
         "retained symbols remain deterministic after overflow");
      declare
         Img : constant String :=
           Natural'Image (Editor.Syntax_Semantics.Max_Local_Symbols + 1);
         Overflow_Name : constant String :=
           "T" & Img (Img'First + 1 .. Img'Last);
      begin
         Assert
           (Editor.Syntax_Semantics.Kind_For_Identifier (Map, Overflow_Name) =
              Editor.Syntax.Identifier,
            "overflowed symbols degrade to ordinary identifiers");
      end;
   end Test_Symbol_Cap_Degrades_To_Identifiers;


   procedure Test_Overlong_Semantic_Names_Degrade_To_Identifiers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Long_Name : constant String := "T" & String'(1 .. 70 => 'A');
      Shared_Prefix : constant String := Long_Name (Long_Name'First .. Long_Name'First + 63);
   begin
      Editor.Syntax_Semantics.Learn_Declarations_From_Line
        (Map, "type " & Long_Name & " is null record;");

      Assert
        (Editor.Syntax_Semantics.Symbol_Count (Map) = 0,
         "overlong semantic names must not be stored under a truncated key");
      Assert
        (Editor.Syntax_Semantics.Symbol_Cap_Reached (Map),
         "overlong semantic names should report bounded semantic degradation");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, Long_Name) =
           Editor.Syntax.Identifier,
         "overlong declarations degrade to ordinary identifiers");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, Shared_Prefix) =
           Editor.Syntax.Identifier,
         "truncated prefixes must not become false semantic symbols");
   end Test_Overlong_Semantic_Names_Degrade_To_Identifiers;


   procedure Test_Overlong_Semantic_Lookup_Does_Not_Match_Stored_Prefix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Prefix_Name : constant String := "T" & String'(1 .. 63 => 'A');
      Overlong_Token : constant String := Prefix_Name & "B";
   begin
      --  Pass 181 completeness: Add rejects overlong declarations, but lookup
      --  must also reject overlong tokens.  Otherwise an overlong identifier
      --  whose first 64 characters match a retained 64-character declaration
      --  could be falsely coloured as that declaration.
      Editor.Syntax_Semantics.Learn_Declarations_From_Line
        (Map, "type " & Prefix_Name & " is null record;");

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, Prefix_Name) =
           Editor.Syntax.Type_Identifier,
         "the exactly retained 64-character declaration remains classified");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, Overlong_Token) =
           Editor.Syntax.Identifier,
         "overlong lookup tokens must not match retained fixed-width prefixes");
   end Test_Overlong_Semantic_Lookup_Does_Not_Match_Stored_Prefix;



   procedure Test_Outline_Constructs_Drive_Semantic_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
      O   : Editor.Outline.Outline_State;
      Snapshot : constant Editor.Outline_Extractor.Buffer_Text_Snapshot :=
        Editor.Outline_Extractor.Make_Snapshot
          ("generic" & ASCII.LF &
           "   type Element is private;" & ASCII.LF &
           "package A.B.C is" & ASCII.LF &
           "   function ""+"" (Left, Right : Element) return Element;" & ASCII.LF &
           "end A.B.C;" & ASCII.LF,
           "a-b-c.ads");
      Result : constant Editor.Outline_Extractor.Extraction_Result :=
        Editor.Outline_Extractor.Extract (Snapshot);
   begin
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);
      Editor.Syntax_Semantics.Build_Map_From_Outline_State (Map, O);

      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "A.B.C") =
              Editor.Syntax.Package_Identifier,
              "qualified child package label contributes the full package symbol");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "C") =
              Editor.Syntax.Package_Identifier,
              "qualified child package label also contributes its leaf symbol");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Element") =
              Editor.Syntax.Generic_Formal,
              "generic formal rows from Outline contribute semantic generic-formal symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, """+""") =
              Editor.Syntax.Subprogram_Identifier,
              "operator function rows from Outline contribute semantic subprogram symbols");
   end Test_Outline_Constructs_Drive_Semantic_Symbols;

   procedure Test_Semantic_Learning_Uses_Shared_Ada_Syntax_Core
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Editor.Syntax_Semantics.Learn_Declarations_From_Line
        (Map, "Text : constant String := ""package Hidden is""; -- procedure Commented;");
      Editor.Syntax_Semantics.Learn_Declarations_From_Line
        (Map, "package A.B.C is");
      Editor.Syntax_Semantics.Learn_Declarations_From_Line
        (Map, "function ""+"" (Left, Right : Natural) return Natural;");

      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Hidden") =
              Editor.Syntax.Identifier,
              "semantic learning must ignore declaration-looking text inside strings");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Commented") =
              Editor.Syntax.Identifier,
              "semantic learning must ignore declaration-looking text inside comments");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "A.B.C") =
              Editor.Syntax.Package_Identifier,
              "local semantic learning retains qualified package names");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "C") =
              Editor.Syntax.Package_Identifier,
              "local semantic learning retains qualified package leaf names");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, """+""") =
              Editor.Syntax.Subprogram_Identifier,
              "local semantic learning recognizes quoted operator functions");
   end Test_Semantic_Learning_Uses_Shared_Ada_Syntax_Core;


   procedure Test_Shared_Ada_Syntax_Core_Drives_Semantic_Learning
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Line : constant String :=
        "S : String := ""package Hidden is""; package Visible is -- procedure Commented";
      Sanitized : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
   begin
      Assert (Editor.Ada_Syntax_Core.Looks_Like_Ada_Declaration_Line
                ("separate (Parent) procedure Child is"),
              "shared Ada syntax core recognizes declaration-leading separate bodies");
      Assert (Editor.Ada_Syntax_Core.Is_Ada_Source_Label ("editor-syntax.ads"),
              "shared Ada syntax core owns Ada source-label recognition");
      Assert (Sanitized'Length = Line'Length,
              "shared Ada syntax core preserves columns for syntax consumers");
      Assert (Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Ada.Strings.Fixed.Index (Line, "Visible"))),
              "shared Ada syntax core marks real declarations as code");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Ada.Strings.Fixed.Index (Line, "Hidden"))),
              "shared Ada syntax core masks declaration-like strings");
      Assert (not Editor.Ada_Syntax_Core.Is_Code_Column
                (Line, Positive (Ada.Strings.Fixed.Index (Line, "Commented"))),
              "shared Ada syntax core masks declaration-like comments");

      Editor.Syntax_Semantics.Learn_Declarations_From_Line (Map, Line);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Visible") =
              Editor.Syntax.Package_Identifier,
              "semantic learning consumes the shared Ada syntax core code view");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Hidden") =
              Editor.Syntax.Identifier,
              "semantic learning must not re-parse masked string content");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Commented") =
              Editor.Syntax.Identifier,
              "semantic learning must not re-parse masked comment content");
   end Test_Shared_Ada_Syntax_Core_Drives_Semantic_Learning;


   procedure Test_Language_Model_Parser_Drives_Semantics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "PaCkAgE Demo IS" & ASCII.LF &
        "   type Color is (Red, Green, 'X');" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      type Element is private;" & ASCII.LF &
        "   procedure Sort (X : Element);" & ASCII.LF &
        "   function ""+"" (Left, Right : Color) return Color;" & ASCII.LF &
        "   Item : constant Natural := 1;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "demo.ads");
      Map : Editor.Syntax_Semantics.Semantic_Map;
      R : Editor.Ada_Symbol_Resolver.Resolution_Result;
   begin
      Assert (Editor.Ada_Language_Model.Symbol_Count (Analysis) >= 6,
              "parser should produce language-model symbols for packages, types, literals, generics, operators, and constants");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "demo") =
              Editor.Syntax.Package_Identifier,
              "semantic map consumes package symbols from language model case-insensitively");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Color") =
              Editor.Syntax.Type_Identifier,
              "semantic map consumes type symbols from language model");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Sort") =
              Editor.Syntax.Subprogram_Identifier,
              "semantic map consumes generic subprogram symbols from language model");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Element") =
              Editor.Syntax.Generic_Formal,
              "semantic map consumes generic formal symbols from language model");

      R := Editor.Ada_Symbol_Resolver.Resolve (Analysis, "Demo");
      Assert (Natural (R.Matches.Length) = 1,
              "resolver keeps case-insensitive package lookup in the shared analysis");
   end Test_Language_Model_Parser_Drives_Semantics;


   procedure Test_Language_Model_Derived_Types_Are_Not_Instantiations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Derivations is" & ASCII.LF &
        "   type Parent is tagged null record;" & ASCII.LF &
        "   type Child is new Parent;" & ASCII.LF &
        "   type Record_Child is new Parent with record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   package Vecs is new Ada.Containers.Vectors (Natural, Integer);" & ASCII.LF &
        "end Derivations;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "derivations.ads");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Child");
      Record_Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Record_Child");
      Vecs_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Vecs");
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Record_Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Record_Child_Id);
      Vecs_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Vecs_Id);
   begin
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived ordinary type should be parsed");
      Assert (Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "derived ordinary type should remain a type symbol");
      Assert (not Child_Info.Flags.Is_Instantiation,
              "derived ordinary type must not inherit generic-instantiation metadata from Ada keyword new");
      Assert (To_String (Child_Info.Target_Name) = "Parent",
              "derived ordinary type should retain parent type target metadata");
      Assert (Record_Child_Id /= Editor.Ada_Language_Model.No_Symbol,
              "derived record extension should be parsed");
      Assert (Record_Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type,
              "derived record extension should be a record-type symbol");
      Assert (not Record_Child_Info.Flags.Is_Instantiation,
              "record extension with new must not be marked as an instantiation");
      Assert (To_String (Record_Child_Info.Target_Name) = "Parent",
              "record extension should retain parent type target metadata");
      Assert (Vecs_Info.Kind = Editor.Ada_Language_Model.Symbol_Instantiation,
              "real package instantiation should still use instantiation symbol kind");
      Assert (Vecs_Info.Flags.Is_Instantiation,
              "real package instantiation should still retain instantiation metadata");
   end Test_Language_Model_Derived_Types_Are_Not_Instantiations;



   procedure Test_Language_Model_Access_Subprogram_Objects_Do_Not_Use_Procedure_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Access_Subprogram_Objects is" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "   Callback : access procedure (Item : Root'Class);" & ASCII.LF &
        "   Predicate : not null access function (Value : Root'Class) return Boolean;" & ASCII.LF &
        "   Protected_Callback : access protected procedure (Protected_Item : Root'Class);" & ASCII.LF &
        "   Inline_Protected_Predicate : access protected function (Protected_Value : Root'Class) return Boolean;" & ASCII.LF &
        "end Access_Subprogram_Objects;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "access_subprogram_objects.ads");
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
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Value");
      Protected_Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Protected_Item");
      Protected_Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Protected_Value");
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Protected_Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Protected_Callback_Id);
      Protected_Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inline_Protected_Predicate_Id);
   begin
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "access-to-procedure object should remain an object declaration");
      Assert (To_String (Callback_Info.Target_Name) = "",
              "access-to-procedure object should not record procedure as a subtype target");
      Assert (Callback_Info.Flags.Has_Access_Subprogram_Metadata,
              "access-to-procedure object should retain access-subprogram metadata");
      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "access-to-function object should remain an object declaration");
      Assert (To_String (Predicate_Info.Target_Name) = "",
              "access-to-function object should not record function as a subtype target");
      Assert (Predicate_Info.Flags.Has_Access_Subprogram_Metadata,
              "access-to-function object should retain access-subprogram metadata");
      Assert (Item_Id = Editor.Ada_Language_Model.No_Symbol,
              "access-to-procedure object profile names should not be learned as symbols");
      Assert (Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "access-to-function object profile names should not be learned as symbols");
      Assert (Protected_Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Protected_Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "protected access-to-procedure object should remain an object declaration");
      Assert (Inline_Protected_Predicate_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Protected_Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "protected access-to-function object should remain an object declaration");
      Assert (To_String (Protected_Callback_Info.Target_Name) = ""
              and then To_String (Protected_Predicate_Info.Target_Name) = "",
              "protected access-to-subprogram objects should not record protected as a subtype target");
      Assert (Protected_Callback_Info.Flags.Has_Access_Subprogram_Metadata
              and then Protected_Predicate_Info.Flags.Has_Access_Subprogram_Metadata,
              "protected access-to-subprogram objects should retain access-subprogram metadata");
      Assert (Protected_Item_Id = Editor.Ada_Language_Model.No_Symbol
              and then Protected_Value_Id = Editor.Ada_Language_Model.No_Symbol,
              "protected access-to-subprogram object profile names should not be learned as symbols");
   end Test_Language_Model_Access_Subprogram_Objects_Do_Not_Use_Procedure_Target;


   procedure Test_Language_Model_Object_Renames_Keep_Value_Kinds
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Renamed_Values is" & ASCII.LF &
        "   Source_Value : Integer;" & ASCII.LF &
        "   Alias_Value : Integer renames Source_Value;" & ASCII.LF &
        "   Base_Count : constant Integer := 1;" & ASCII.LF &
        "   Alias_Count : constant Integer renames Base_Count;" & ASCII.LF &
        "   Base_Error : exception;" & ASCII.LF &
        "   Alias_Error : exception renames Base_Error;" & ASCII.LF &
        "end Renamed_Values;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "renamed_values.ads");
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Alias_Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_Value");
      Alias_Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_Count");
      Alias_Error_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_Error");
      Alias_Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Alias_Value_Id);
      Alias_Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Alias_Count_Id);
      Alias_Error_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Alias_Error_Id);
   begin
      Assert (Alias_Value_Id /= Editor.Ada_Language_Model.No_Symbol,
              "object rename should be parsed as a declaration");
      Assert (Alias_Value_Info.Kind = Editor.Ada_Language_Model.Symbol_Object,
              "object rename should keep object kind rather than generic rename kind");
      Assert (Alias_Value_Info.Flags.Is_Rename,
              "object rename should retain rename flag metadata");
      Assert (To_String (Alias_Value_Info.Target_Name) = "Source_Value",
              "object rename should retain target object metadata");

      Assert (Alias_Count_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant,
              "constant object rename should keep constant semantic kind");
      Assert (To_String (Alias_Count_Info.Target_Name) = "Base_Count",
              "constant object rename should retain target metadata");
      Assert (Alias_Error_Info.Kind = Editor.Ada_Language_Model.Symbol_Exception,
              "exception rename should keep exception semantic kind");
      Assert (To_String (Alias_Error_Info.Target_Name) = "Base_Error",
              "exception rename should retain target metadata");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Alias_Value") =
              Editor.Syntax.Parameter_Identifier,
              "object rename should classify through value-like language-model semantics");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Alias_Count") =
              Editor.Syntax.Parameter_Identifier,
              "constant rename should classify through value-like language-model semantics");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Alias_Error") =
              Editor.Syntax.Parameter_Identifier,
              "exception rename should classify through value-like language-model semantics");
   end Test_Language_Model_Object_Renames_Keep_Value_Kinds;

   procedure Test_Language_Model_Callable_And_Package_Renames_Keep_Kinds
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Renamed_Callables is" & ASCII.LF &
        "   package Alias_IO renames Ada.Text_IO;" & ASCII.LF &
        "   procedure Alias_Run (Count : Natural) renames Run;" & ASCII.LF &
        "   function Alias_Check (Value : Integer) return Boolean renames Check;" & ASCII.LF &
        "   function " & """" & "+" & """" & " (Left, Right : Integer) return Integer renames Add;" & ASCII.LF &
        "end Renamed_Callables;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "renamed_callables.ads");
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_IO");
      Procedure_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_Run");
      Function_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_Check");
      Operator_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """" & "+" & """");
      Package_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Package_Id);
      Procedure_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Procedure_Id);
      Function_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Function_Id);
      Operator_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Operator_Id);
   begin
      Assert (Package_Info.Kind = Editor.Ada_Language_Model.Symbol_Package,
              "package rename should keep package semantic kind");
      Assert (Package_Info.Flags.Is_Rename,
              "package rename should retain rename flag");
      Assert (To_String (Package_Info.Target_Name) = "Ada.Text_IO",
              "package rename should retain renamed package target");

      Assert (Procedure_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure,
              "procedure rename should keep callable semantic kind");
      Assert (Procedure_Info.Flags.Is_Rename,
              "procedure rename should retain rename flag");
      Assert (To_String (Procedure_Info.Target_Name) = "Run",
              "procedure rename should retain target metadata");

      Assert (Function_Info.Kind = Editor.Ada_Language_Model.Symbol_Function,
              "function rename should keep callable semantic kind");
      Assert (Function_Info.Flags.Is_Rename,
              "function rename should retain rename flag");
      Assert (To_String (Function_Info.Target_Name) = "Check",
              "function rename should retain target metadata");

      Assert (Operator_Info.Kind = Editor.Ada_Language_Model.Symbol_Operator_Function,
              "operator function rename should keep operator callable kind");
      Assert (Operator_Info.Flags.Is_Rename,
              "operator function rename should retain rename flag");
      Assert (To_String (Operator_Info.Target_Name) = "Add",
              "operator function rename should retain target metadata");

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Alias_IO") =
              Editor.Syntax.Package_Identifier,
              "package rename should classify as package through language-model semantics");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Alias_Run") =
              Editor.Syntax.Subprogram_Identifier,
              "procedure rename should classify as subprogram through language-model semantics");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Alias_Check") =
              Editor.Syntax.Subprogram_Identifier,
              "function rename should classify as subprogram through language-model semantics");
   end Test_Language_Model_Callable_And_Package_Renames_Keep_Kinds;


   procedure Test_Language_Model_Fingerprint_Includes_Overflow_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Id       : Editor.Ada_Language_Model.Symbol_Id;
      Before_Overflow       : Natural;
      After_First_Overflow  : Natural;
      After_Second_Overflow : Natural;
   begin
      for I in 1 .. Editor.Ada_Language_Model.Max_Analysis_Symbols loop
         Id := Editor.Ada_Language_Model.Add_Symbol
           (Analysis,
            "Overflow_State_" &
              Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left),
            Editor.Ada_Language_Model.Symbol_Object,
            (Start_Line => I, Start_Column => 1, End_Line => I, End_Column => 1));
         Assert (Id /= Editor.Ada_Language_Model.No_Symbol,
                 "test setup should fill the analysis symbol budget exactly");
      end loop;

      Assert (not Editor.Ada_Language_Model.Overflowed (Analysis),
              "an exactly full analysis is still not overflowed before rejected insertion");
      Before_Overflow := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Overflow_State_Extra",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      After_First_Overflow := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Assert (Id = Editor.Ada_Language_Model.No_Symbol,
              "over-budget insertion must not append a symbol");
      Assert (Editor.Ada_Language_Model.Symbol_Count (Analysis) =
              Editor.Ada_Language_Model.Max_Analysis_Symbols,
              "analysis symbol count must remain bounded after overflow");
      Assert (Editor.Ada_Language_Model.Overflowed (Analysis),
              "over-budget insertion should mark the analysis overflowed");
      Assert (Before_Overflow /= After_First_Overflow,
              "analysis fingerprint must change when overflow state first becomes true");

      Id := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         "Overflow_State_Extra_Second",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1));
      After_Second_Overflow := Editor.Ada_Language_Model.Fingerprint (Analysis);

      Assert (Id = Editor.Ada_Language_Model.No_Symbol,
              "repeat over-budget insertion must still reject the symbol");
      Assert (After_First_Overflow = After_Second_Overflow,
              "repeat overflow attempts should not churn the analysis fingerprint");
   end Test_Language_Model_Fingerprint_Includes_Overflow_State;


   procedure Test_Language_Model_Enumeration_Literals_Parent_Type
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Enums is" & ASCII.LF &
        "   type Color is (Red, Green, 'X');" & ASCII.LF &
        "end Enums;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "enums.ads");
      Color_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Color");
      Red_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Red", Color_Id);
      Char_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "'X'", Color_Id);
      Red_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Red_Id);
      Char_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Char_Id);
   begin
      Assert (Color_Id /= Editor.Ada_Language_Model.No_Symbol,
              "enumeration type should be present in the language model");
      Assert (Red_Info.Kind = Editor.Ada_Language_Model.Symbol_Enumeration_Literal,
              "identifier enumeration literals should be parsed as enumeration symbols");
      Assert (Red_Info.Parent_Symbol = Color_Id,
              "enumeration literals should attach to their type, not the enclosing package");
      Assert (Char_Info.Kind = Editor.Ada_Language_Model.Symbol_Enumeration_Literal,
              "character enumeration literals should also be retained");
      Assert (Char_Info.Parent_Symbol = Color_Id,
              "character enumeration literals should attach to the enumeration type");
   end Test_Language_Model_Enumeration_Literals_Parent_Type;


   procedure Test_Language_Model_Generated_And_Conditional_Source_Awareness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "--  @generated by table tool; do not edit" & ASCII.LF &
        "#if Debug" & ASCII.LF &
        "package Demo is" & ASCII.LF &
        "   Value : Integer;" & ASCII.LF &
        "end Demo;" & ASCII.LF &
        "#end if" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "generated_demo.ads");
   begin
      Assert (Editor.Ada_Language_Model.Has_Generated_Source_Awareness (Analysis),
              "generated-source markers should be retained as bounded analysis metadata");
      Assert (Editor.Ada_Language_Model.Has_Conditional_Source_Awareness (Analysis),
              "conditional-source markers should be retained as bounded analysis metadata");
      Assert (Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Demo") /=
                Editor.Ada_Language_Model.No_Symbol,
              "source awareness markers must not prevent ordinary Ada parsing");
   end Test_Language_Model_Generated_And_Conditional_Source_Awareness;


   procedure Test_Language_Model_Multiline_Enumeration_Literals_Parent_Type
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Enums is" & ASCII.LF &
        "   type State is (" & ASCII.LF &
        "      Idle," & ASCII.LF &
        "      Busy," & ASCII.LF &
        "      'Z'" & ASCII.LF &
        "   );" & ASCII.LF &
        "   After_Enum : Integer;" & ASCII.LF &
        "end Enums;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "enums.ads");
      Enums_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Enums");
      State_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "State", Enums_Id);
      Idle_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Idle", State_Id);
      Busy_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Busy", State_Id);
      Z_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "'Z'", State_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Enum", Enums_Id);
      Idle_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Idle_Id);
      Z_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Z_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (State_Id /= Editor.Ada_Language_Model.No_Symbol,
              "multi-line enumeration type should be parsed");
      Assert (Idle_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Busy_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Z_Id /= Editor.Ada_Language_Model.No_Symbol,
              "multi-line enumeration literals should be retained");
      Assert (Idle_Info.Kind = Editor.Ada_Language_Model.Symbol_Enumeration_Literal,
              "multi-line enumeration identifiers should be enumeration literal symbols");
      Assert (Idle_Info.Parent_Symbol = State_Id,
              "multi-line enumeration identifiers should be parented to the enum type");
      Assert (Z_Info.Parent_Symbol = State_Id,
              "multi-line character enumeration literals should be parented to the enum type");
      Assert (After_Info.Parent_Symbol = Enums_Id,
              "closing a multi-line enumeration must not corrupt the enclosing package scope");
   end Test_Language_Model_Multiline_Enumeration_Literals_Parent_Type;


   procedure Test_Language_Model_Value_Like_Semantic_Kinds
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Values is" & ASCII.LF &
        "   type Mode is (Idle, Busy);" & ASCII.LF &
        "   type Rec (Id : Natural) is record" & ASCII.LF &
        "      Count : Natural;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Limit : constant Natural := 10;" & ASCII.LF &
        "   Current : Rec;" & ASCII.LF &
        "   Boom : exception;" & ASCII.LF &
        "end Values;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "values.ads");
      Map : Editor.Syntax_Semantics.Semantic_Map;
   begin
      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);

      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Values") =
              Editor.Syntax.Package_Identifier,
              "package symbols should still use the package semantic token");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Mode") =
              Editor.Syntax.Type_Identifier,
              "type symbols should still use the type semantic token");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Idle") =
              Editor.Syntax.Parameter_Identifier,
              "enumeration literals should no longer degrade to ordinary identifiers");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Id") =
              Editor.Syntax.Parameter_Identifier,
              "record discriminants should be retained as value-like semantic symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Count") =
              Editor.Syntax.Parameter_Identifier,
              "record components should be retained as value-like semantic symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Limit") =
              Editor.Syntax.Parameter_Identifier,
              "constants should be retained as value-like semantic symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Current") =
              Editor.Syntax.Parameter_Identifier,
              "objects should be retained as value-like semantic symbols");
      Assert (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Boom") =
              Editor.Syntax.Parameter_Identifier,
              "exceptions should be retained as semantic symbols instead of being dropped");
   end Test_Language_Model_Value_Like_Semantic_Kinds;


   procedure Test_Language_Model_Split_Type_Header_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Split_Record is" & ASCII.LF &
        "   type Rec" & ASCII.LF &
        "     (Id : Natural;" & ASCII.LF &
        "      Enabled : Boolean)" & ASCII.LF &
        "   is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Split_Record;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "split_record.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Id", Rec_Id);
      Enabled_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Enabled", Rec_Id);
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope
          (Analysis, "Value", Rec_Id);
      Rec_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Rec_Id);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Id);
      Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Value_Id);
   begin
      Assert (Rec_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type,
              "split type headers that later open a record should upgrade to record type symbols");
      Assert (Id_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Enabled_Id /= Editor.Ada_Language_Model.No_Symbol,
              "split type-header discriminants should be retained under the record type");
      Assert (Id_Info.Parent_Symbol = Rec_Id,
              "split type-header discriminants should be parented to the pending type owner");
      Assert (Value_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Value_Info.Parent_Symbol = Rec_Id,
              "record components after split headers should remain in the record scope");
   end Test_Language_Model_Split_Type_Header_Record;


   procedure Test_Language_Model_Fingerprint_Includes_Source_Spelling
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Upper_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Lower_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Upper_Target_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Lower_Target_Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Upper_Id : Editor.Ada_Language_Model.Symbol_Id;
      Lower_Id : Editor.Ada_Language_Model.Symbol_Id;
      Upper_Target_Id : Editor.Ada_Language_Model.Symbol_Id;
      Lower_Target_Id : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Upper_Id := Editor.Ada_Language_Model.Add_Symbol
        (Upper_Analysis,
         "Demo_Name",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 9));
      Lower_Id := Editor.Ada_Language_Model.Add_Symbol
        (Lower_Analysis,
         "demo_name",
         Editor.Ada_Language_Model.Symbol_Type,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 9));

      Assert (Upper_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lower_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert both differently-spelled declarations");
      Assert (To_String (Editor.Ada_Language_Model.Symbol
                (Upper_Analysis, Upper_Id).Normalized_Name)
              = To_String (Editor.Ada_Language_Model.Symbol
                (Lower_Analysis, Lower_Id).Normalized_Name),
              "Ada lookup normalization should remain case-insensitive");
      Assert (Editor.Ada_Language_Model.Fingerprint (Upper_Analysis)
              /= Editor.Ada_Language_Model.Fingerprint (Lower_Analysis),
              "analysis fingerprints should include preserved source spelling");

      Upper_Target_Id := Editor.Ada_Language_Model.Add_Symbol
        (Upper_Target_Analysis,
         "Alias",
         Editor.Ada_Language_Model.Symbol_Rename,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 5),
         Target_Name => "Target_Name");
      Lower_Target_Id := Editor.Ada_Language_Model.Add_Symbol
        (Lower_Target_Analysis,
         "Alias",
         Editor.Ada_Language_Model.Symbol_Rename,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 5),
         Target_Name => "target_name");

      Assert (Upper_Target_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lower_Target_Id /= Editor.Ada_Language_Model.No_Symbol,
              "test setup should insert both differently-spelled rename targets");
      Assert (Editor.Ada_Language_Model.Fingerprint (Upper_Target_Analysis)
              /= Editor.Ada_Language_Model.Fingerprint (Lower_Target_Analysis),
              "target metadata fingerprints should include preserved target spelling");
   end Test_Language_Model_Fingerprint_Includes_Source_Spelling;


   procedure Test_Language_Model_Predicates_Include_Callable_And_Formal_Type
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Ada_Language_Model.Is_Subprogram
                (Editor.Ada_Language_Model.Symbol_Separate_Body),
              "separate body rows should be classified as callable symbols");
      Assert (Editor.Ada_Language_Model.Kind_To_Syntax_Kind
                (Editor.Ada_Language_Model.Symbol_Separate_Body) =
              Editor.Syntax.Subprogram_Identifier,
              "separate body predicate should match semantic token mapping");
      Assert (Editor.Ada_Language_Model.Is_Type_Like
                (Editor.Ada_Language_Model.Symbol_Generic_Formal_Type),
              "generic formal type rows should be type-like for model consumers");
      Assert (Editor.Ada_Language_Model.Kind_To_Syntax_Kind
                (Editor.Ada_Language_Model.Symbol_Generic_Formal_Type) =
              Editor.Syntax.Generic_Formal,
              "generic formal type keeps its dedicated semantic token bucket");
   end Test_Language_Model_Predicates_Include_Callable_And_Formal_Type;


   procedure Test_Language_Model_Formal_Package_Actuals_Project_Into_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   with package Maps is new Ada.Containers.Ordered_Maps" &
        " (Key_Type => Key, Element_Type => Element, others => <>);" & ASCII.LF &
        "   with package Defaults is new Generic_Defaults (<>);" & ASCII.LF &
        "package G is" & ASCII.LF &
        "end G;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "formal_package.ads");
      Maps_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Maps");
      Defaults_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Defaults");
      First_Actual : constant Editor.Ada_Language_Model.Generic_Actual_Info :=
        Editor.Ada_Language_Model.Generic_Actual_At (Analysis, Maps_Id, 1);
      Third_Actual : constant Editor.Ada_Language_Model.Generic_Actual_Info :=
        Editor.Ada_Language_Model.Generic_Actual_At (Analysis, Maps_Id, 3);
      Maps_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Maps_Id);
      Defaults_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Defaults_Id);
   begin
      Assert (Maps_Id /= Editor.Ada_Language_Model.No_Symbol,
              "formal package with named actual part should be retained");
      Assert (Defaults_Id /= Editor.Ada_Language_Model.No_Symbol,
              "formal package whole-box actual part should be retained");
      Assert (Maps_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Package,
              "named formal package actuals should remain owned by the formal package symbol");
      Assert (Maps_Info.Flags.Has_Generic_Actual_Part_Metadata,
              "formal package named actual parts should stamp generic-actual metadata");
      Assert (Defaults_Info.Flags.Has_Box_Metadata,
              "formal package whole-box actual part should remain bounded box metadata");
      Assert (Editor.Ada_Language_Model.Generic_Actual_Count (Analysis, Maps_Id) = 3,
              "formal package named actual part should project each association into the language model");
      Assert (To_String (First_Actual.Formal_Name) = "Key_Type"
              and then To_String (First_Actual.Actual_Name) = "Key",
              "formal package named actual selectors should retain formal and actual text");
      Assert (To_String (Third_Actual.Formal_Name) = "others"
              and then To_String (Third_Actual.Actual_Name) = "<>",
              "formal package others box association should remain explicit actual metadata");
      Assert (Editor.Ada_Language_Model.Generic_Actual_Count (Analysis, Defaults_Id) = 0,
              "formal package whole-box (<>) should not become a positional generic actual");
   end Test_Language_Model_Formal_Package_Actuals_Project_Into_Model;



   procedure Test_Ada_Declarative_Region_Model_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Declarative_Regions.Region_Kind;
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "package Region_Root is" & ASCII.LF &
        "   Visible : Element;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Hidden : Element;" & ASCII.LF &
        "end Region_Root;" & ASCII.LF &
        "package body Region_Root is" & ASCII.LF &
        "   procedure Worker is" & ASCII.LF &
        "      Local : Element;" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   protected body Guard is" & ASCII.LF &
        "      entry Take when Ready is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Take;" & ASCII.LF &
        "   end Guard;" & ASCII.LF &
        "end Region_Root;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Model : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);

      function Count_Kind
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind) return Natural
      is
         Count : Natural := 0;
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Model) loop
            if Editor.Ada_Declarative_Regions.Region_At (Model, Index).Kind = Kind then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Count_Kind;

      function First_Region
        (Kind : Editor.Ada_Declarative_Regions.Region_Kind)
         return Editor.Ada_Declarative_Regions.Region_Id
      is
      begin
         for Index in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Model) loop
            declare
               Info : constant Editor.Ada_Declarative_Regions.Region_Info :=
                 Editor.Ada_Declarative_Regions.Region_At (Model, Index);
            begin
               if Info.Kind = Kind then
                  return Info.Id;
               end if;
            end;
         end loop;
         return Editor.Ada_Declarative_Regions.No_Region;
      end First_Region;

      Package_Spec : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Package_Spec);
      Package_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Package_Body);
      Subprogram   : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Subprogram_Body);
      Protected_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Protected_Body);
      Entry_Body : constant Editor.Ada_Declarative_Regions.Region_Id :=
        First_Region (Editor.Ada_Declarative_Regions.Region_Entry_Body);
   begin
      Assert (Editor.Ada_Declarative_Regions.Has_Regions (Model),
              "declarative-region model must be populated from the syntax tree");
      Assert (Count_Kind (Editor.Ada_Declarative_Regions.Region_Compilation) = 1,
              "exactly one compilation region must anchor the model");
      Assert (Count_Kind (Editor.Ada_Declarative_Regions.Region_Generic_Formal_Part) >= 1,
              "generic formal parts must open distinct declarative regions");
      Assert (Package_Spec /= Editor.Ada_Declarative_Regions.No_Region,
              "package specs must open declarative regions");
      Assert (Package_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "package bodies must open declarative regions");
      Assert (Subprogram /= Editor.Ada_Declarative_Regions.No_Region,
              "subprogram bodies must open declarative regions");
      Assert (Protected_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "protected bodies must open declarative regions");
      Assert (Entry_Body /= Editor.Ada_Declarative_Regions.No_Region,
              "entry bodies must open declarative regions");
      Assert (Editor.Ada_Declarative_Regions.Region (Model, Subprogram).Parent = Package_Body,
              "nested subprogram body region must be parented by its package body region");
      Assert (Editor.Ada_Declarative_Regions.Region (Model, Entry_Body).Parent = Protected_Body,
              "protected entry body region must be parented by its protected-body region");
      Assert (Editor.Ada_Declarative_Regions.Direct_Child_Count (Model, Package_Body) >= 2,
              "package body region must retain direct nested declarative regions");
      Assert (Editor.Ada_Declarative_Regions.Fingerprint (Model) /= 0,
              "region model must expose a deterministic non-zero fingerprint");
   end Test_Ada_Declarative_Region_Model_Foundation;


   procedure Test_Language_Model_Context_Clause_Detail_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "limited private with Ada.Text_IO, Project.Parent;" & ASCII.LF &
        "private with Ada.Strings.Unbounded;" & ASCII.LF &
        "limited with Interfaces;" & ASCII.LF &
        "use Ada.Text_IO;" & ASCII.LF &
        "package Context_Detail is" & ASCII.LF &
        "   use type Project.Parent.Flag;" & ASCII.LF &
        "end Context_Detail;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "context_detail.ads");
      First : constant Editor.Ada_Language_Model.Visibility_Clause_Info :=
        Editor.Ada_Language_Model.Context_Clause_At (Analysis, 1);
      Second : constant Editor.Ada_Language_Model.Visibility_Clause_Info :=
        Editor.Ada_Language_Model.Context_Clause_At (Analysis, 2);
      Third : constant Editor.Ada_Language_Model.Visibility_Clause_Info :=
        Editor.Ada_Language_Model.Context_Clause_At (Analysis, 3);
      Fourth : constant Editor.Ada_Language_Model.Visibility_Clause_Info :=
        Editor.Ada_Language_Model.Context_Clause_At (Analysis, 4);
   begin
      Assert (Editor.Ada_Language_Model.Context_Clause_Count (Analysis) = 5,
              "context-clause projection must retain each root with/use name separately");
      Assert (Editor.Ada_Language_Model.Use_Clause_Count (Analysis) = 2,
              "use-clause count must still include context and declarative use clauses");
      Assert (First.Is_Context_Clause,
              "context with-clause metadata must be marked as context-owned");
      Assert (First.Has_Limited_Modifier and then First.Has_Private_Modifier,
              "limited private with clauses must retain both modifiers");
      Assert (To_String (First.Name) = "Ada.Text_IO",
              "first context with name must be retained exactly");
      Assert (To_String (Second.Name) = "Project.Parent",
              "comma-separated context with names must project as separate metadata rows");
      Assert (Third.Has_Private_Modifier and then not Third.Has_Limited_Modifier,
              "private with clauses must retain private-only modifier metadata");
      Assert (Fourth.Has_Limited_Modifier and then not Fourth.Has_Private_Modifier,
              "limited with clauses must retain limited-only modifier metadata");
      Assert (Editor.Ada_Language_Model.Context_Clause_At (Analysis, 5).Kind =
                Editor.Ada_Language_Model.Visibility_Use_Package_Clause,
              "root use clauses must be distinguishable as context visibility clauses");
   end Test_Language_Model_Context_Clause_Detail_Projection;

   procedure Register_Tests (T : in out Syntax_Semantics_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outline_Labels_Contribute_Symbol_Names'Access,
         "outline labels contribute symbol names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Outline_Constructs_Drive_Semantic_Symbols'Access,
         "outline Ada constructs drive semantic symbols");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Learning_Uses_Shared_Ada_Syntax_Core'Access,
         "semantic learning uses shared Ada syntax core");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Shared_Ada_Syntax_Core_Drives_Semantic_Learning'Access,
         "shared Ada syntax core drives semantic learning");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Symbol_Cap_Degrades_To_Identifiers'Access,
         "semantic symbol cap degrades to identifiers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Overlong_Semantic_Names_Degrade_To_Identifiers'Access,
         "overlong semantic names degrade to identifiers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Overlong_Semantic_Lookup_Does_Not_Match_Stored_Prefix'Access,
         "overlong semantic lookup does not match stored prefixes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Parser_Drives_Semantics'Access,
         "language model parser drives scope-aware semantic symbols");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Derived_Types_Are_Not_Instantiations'Access,
         "language model parser keeps derived type parent targets without instantiation flags");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Object_Renames_Keep_Value_Kinds'Access,
         "language model keeps value kinds for object renames");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Fingerprint_Includes_Overflow_State'Access,
         "language model fingerprints include bounded overflow state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Enumeration_Literals_Parent_Type'Access,
         "language model parser parents enumeration literals to their type");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Generated_And_Conditional_Source_Awareness'Access,
         "language model parser retains generated and conditional source awareness metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Multiline_Enumeration_Literals_Parent_Type'Access,
         "language model parser retains multi-line enumeration literals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Value_Like_Semantic_Kinds'Access,
         "language model semantic map retains value-like symbols");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Split_Type_Header_Record'Access,
         "language model parser retains split type-header record scopes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Access_Subprogram_Objects_Do_Not_Use_Procedure_Target'Access,
         "language model parser suppresses access-to-subprogram object target metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Callable_And_Package_Renames_Keep_Kinds'Access,
         "language model parser keeps package/subprogram rename semantic kinds");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Fingerprint_Includes_Source_Spelling'Access,
         "language model fingerprint includes source spelling");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Model_Predicates_Include_Callable_And_Formal_Type'Access,
         "language model predicates include separate bodies and generic formal types");
      Add_Test (Routine => Test_Language_Model_Formal_Package_Actuals_Project_Into_Model'Access, Name => "language model projects formal package actual parts without treating whole-box defaults as positional actuals");
      Add_Test (Routine => Test_Ada_Declarative_Region_Model_Foundation'Access, Name => "Ada declarative-region model retains compiler-grade region parentage foundation");
      Add_Test (Routine => Test_Language_Model_Context_Clause_Detail_Projection'Access, Name => "language model projects context clause modifiers names and context/declarative separation");

   end Register_Tests;

end Editor.Syntax_Semantics.Tests;
