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

package body Editor.Syntax_Semantics.Static_Expression_Foundation_Tests is

   procedure Test_Ada_Static_Enumeration_Position_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Static_Enumeration_Client is" & ASCII.LF &
        "   type Color is (Red, Green, Blue);" & ASCII.LF &
        "   Green_Pos : constant Integer := Color'Pos (Green);" & ASCII.LF &
        "   Blue_Val  : constant Color := Color'Val (2);" & ASCII.LF &
        "   Bad_Pos   : constant Integer := Color'Pos (Missing);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Static_Enumeration_Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Statics : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Seen_Red : Boolean := False;
      Seen_Green : Boolean := False;
      Seen_Blue : Boolean := False;
      Seen_Green_Pos : Boolean := False;
      Seen_Blue_Val : Boolean := False;
      Seen_Bad_Pos : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Enumeration_Literal_Count (Statics) loop
         declare
            Literal : constant Editor.Ada_Static_Expressions.Static_Enumeration_Literal_Info :=
              Editor.Ada_Static_Expressions.Static_Enumeration_Literal_At (Statics, Index);
            Name : constant String := To_String (Literal.Normalized_Literal_Name);
         begin
            if To_String (Literal.Normalized_Type_Name) = "color" and then Name = "red" then
               Seen_Red := Literal.Position = 0;
            elsif To_String (Literal.Normalized_Type_Name) = "color" and then Name = "green" then
               Seen_Green := Literal.Position = 1;
            elsif To_String (Literal.Normalized_Type_Name) = "color" and then Name = "blue" then
               Seen_Blue := Literal.Position = 2;
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Binding_Count (Statics) loop
         declare
            Info : constant Editor.Ada_Static_Expressions.Static_Binding_Info :=
              Editor.Ada_Static_Expressions.Static_Binding_At (Statics, Index);
            Name : constant String := To_String (Info.Normalized_Name);
         begin
            if Name = "green_pos" then
               Seen_Green_Pos :=
                 Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
                 and then Info.Value.Integer_Value = 1
                 and then To_String (Info.Value.Attribute_Name) = "pos"
                 and then To_String (Info.Value.Literal_Name) = "Green";
            elsif Name = "blue_val" then
               Seen_Blue_Val :=
                 Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Enumeration_Literal
                 and then Info.Value.Literal_Position = 2
                 and then To_String (Info.Value.Literal_Name) = "Blue"
                 and then To_String (Info.Value.Attribute_Name) = "val";
            elsif Name = "bad_pos" then
               Seen_Bad_Pos :=
                 Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name
                 and then To_String (Info.Value.Referenced_Name) = "Missing";
            end if;
         end;
      end loop;

      Assert (Seen_Red and then Seen_Green and then Seen_Blue,
              "static model must stage enumeration literal declaration positions");
      Assert (Seen_Green_Pos,
              "static evaluator must resolve enumeration Pos literal positions");
      Assert (Seen_Blue_Val,
              "static evaluator must resolve enumeration Val position metadata");
      Assert (Seen_Bad_Pos,
              "static evaluator must preserve unresolved enumeration Pos operands");
      Assert (Editor.Ada_Static_Expressions.Fingerprint (Statics) /= 0,
              "static enumeration-position model must retain deterministic fingerprints");
   end Test_Ada_Static_Enumeration_Position_Foundation;

   procedure Test_Ada_Static_Modular_Integer_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      use type Editor.Ada_Static_Expressions.Static_Modular_Type_Id;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Static_Modular_Client is" & ASCII.LF &
        "   Modulus : constant := 256;" & ASCII.LF &
        "   type Byte is mod Modulus;" & ASCII.LF &
        "   type Nibble is mod 16;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Static_Modular_Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Statics : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Root_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_At (Regions, 1).Id;
      Byte_Id : constant Editor.Ada_Static_Expressions.Static_Modular_Type_Id :=
        Editor.Ada_Static_Expressions.Lookup_Modular_Type (Statics, Root_Region, "Byte");
      Byte_Info : constant Editor.Ada_Static_Expressions.Static_Modular_Type_Info :=
        Editor.Ada_Static_Expressions.Static_Modular_Type (Statics, Byte_Id);
      Reduced_Byte : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Reduce_Modular_Integer
          (Statics, Root_Region, "Byte", "Modulus + 3");
      Reduced_Negative : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Reduce_Modular_Integer
          (Statics, Root_Region, "Nibble", "-1");
      Missing_Type : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Reduce_Modular_Integer
          (Statics, Root_Region, "Missing_Modular", "1");
   begin
      Assert (Editor.Ada_Static_Expressions.Static_Modular_Type_Count (Statics) >= 2,
              "static model must stage modular type declarations separately");
      Assert (Byte_Id /= Editor.Ada_Static_Expressions.No_Static_Modular_Type,
              "static modular lookup must find modular type declarations");
      Assert (Byte_Info.Modulus_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer
              and then Byte_Info.Modulus_Value.Integer_Value = 256,
              "static modular type metadata must evaluate named-number modulus expressions");
      Assert (Reduced_Byte.Status = Editor.Ada_Static_Expressions.Static_Value_Modular_Integer
              and then Reduced_Byte.Integer_Value = 3
              and then Reduced_Byte.Modulus_Value = 256
              and then To_String (Reduced_Byte.Modular_Type_Name) = "Byte",
              "static modular reduction must reduce positive static expressions by the known modulus");
      Assert (Reduced_Negative.Status = Editor.Ada_Static_Expressions.Static_Value_Modular_Integer
              and then Reduced_Negative.Integer_Value = 15
              and then Reduced_Negative.Modulus_Value = 16,
              "static modular reduction must preserve Ada mod semantics for negative static operands");
      Assert (Missing_Type.Status = Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name
              and then To_String (Missing_Type.Referenced_Name) = "Missing_Modular",
              "static modular reduction must retain unresolved modular type names for diagnostics");
      Assert (Editor.Ada_Static_Expressions.Fingerprint (Statics) /= 0,
              "static modular model must retain deterministic fingerprints");
   end Test_Ada_Static_Modular_Integer_Foundation;

   procedure Test_Ada_Static_Real_Numeric_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Static_Real_Client is" & ASCII.LF &
        "   Half : constant := 0.5;" & ASCII.LF &
        "   Scale : constant := 2.0E+1;" & ASCII.LF &
        "   Total : constant := Scale * Half + 1.25;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Static_Real_Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Statics : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Root_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_At (Regions, 1).Id;
      Expr : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Statics, Root_Region, "Scale / 4.0 + Half");
      Int_Only : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Integer_Expression
          (Statics, Root_Region, "1.5");
      Div_Zero : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
          (Statics, Root_Region, "1.0 / 0.0");
      Seen_Total : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Binding_Count (Statics) loop
         declare
            Info : constant Editor.Ada_Static_Expressions.Static_Binding_Info :=
              Editor.Ada_Static_Expressions.Static_Binding_At (Statics, Index);
            Name : constant String := To_String (Info.Normalized_Name);
         begin
            if Name = "total" then
               Seen_Total :=
                 Info.Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real
                 and then abs (Info.Value.Real_Value - 11.25) < 0.000_001;
            end if;
         end;
      end loop;

      Assert (Seen_Total,
              "static model must evaluate named-number real arithmetic through constants");
      Assert (Expr.Status = Editor.Ada_Static_Expressions.Static_Value_Real
              and then abs (Expr.Real_Value - 5.5) < 0.000_001,
              "numeric evaluator must support decimal/exponent real literals and named references");
      Assert (Int_Only.Status = Editor.Ada_Static_Expressions.Static_Value_Non_Static,
              "integer-only evaluator must reject real-valued static expressions explicitly");
      Assert (Div_Zero.Status = Editor.Ada_Static_Expressions.Static_Value_Division_By_Zero,
              "real static division by zero must remain explicit diagnostic metadata");
      Assert (Editor.Ada_Static_Expressions.Is_Static_Real (Expr)
              and then Editor.Ada_Static_Expressions.Is_Static_Numeric (Expr),
              "static expression predicates must classify real numeric values");
      Assert (Editor.Ada_Static_Expressions.Fingerprint (Statics) /= 0,
              "static real arithmetic model must retain deterministic fingerprints");
   end Test_Ada_Static_Real_Numeric_Foundation;

   procedure Test_Ada_Static_Fixed_Point_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use type Editor.Ada_Static_Expressions.Static_Value_Status;
      use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Id;
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Static_Fixed_Client is" & ASCII.LF &
        "   Step : constant := 0.125;" & ASCII.LF &
        "   Limit : constant := 1.0;" & ASCII.LF &
        "   type Small_Fixed is delta Step range -Limit .. Limit;" & ASCII.LF &
        "   type Money is delta 0.01 digits 10 range 0.00 .. 99.99;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Static_Fixed_Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Statics : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Root_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_At (Regions, 1).Id;
      Small_Id : constant Editor.Ada_Static_Expressions.Static_Fixed_Type_Id :=
        Editor.Ada_Static_Expressions.Lookup_Fixed_Type (Statics, Root_Region, "Small_Fixed");
      Small_Info : constant Editor.Ada_Static_Expressions.Static_Fixed_Type_Info :=
        Editor.Ada_Static_Expressions.Static_Fixed_Type (Statics, Small_Id);
      Quantized : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Quantize_Fixed_Value
          (Statics, Root_Region, "Small_Fixed", "Step * 4.0");
      Delta_Mismatch : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Quantize_Fixed_Value
          (Statics, Root_Region, "Small_Fixed", "0.10");
      Range_Error : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Quantize_Fixed_Value
          (Statics, Root_Region, "Money", "100.00");
   begin
      Assert (Editor.Ada_Static_Expressions.Static_Fixed_Type_Count (Statics) >= 2,
              "static model must stage ordinary and decimal fixed-point type declarations");
      Assert (Small_Id /= Editor.Ada_Static_Expressions.No_Static_Fixed_Type,
              "fixed-point type lookup must find declarations through the owning region");
      Assert (Small_Info.Delta_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real
              and then abs (Small_Info.Delta_Value.Real_Value - 0.125) < 0.000_001,
              "fixed-point delta expressions must evaluate through named real constants");
      Assert (Small_Info.First_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real
              and then abs (Small_Info.First_Value.Real_Value + 1.0) < 0.000_001
              and then Small_Info.Last_Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real
              and then abs (Small_Info.Last_Value.Real_Value - 1.0) < 0.000_001,
              "fixed-point range bounds must retain static real metadata");
      Assert (Quantized.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Point
              and then abs (Quantized.Real_Value - 0.5) < 0.000_001
              and then To_String (Quantized.Fixed_Type_Name) = "Small_Fixed"
              and then abs (Quantized.Delta_Value - 0.125) < 0.000_001,
              "fixed-point quantization must accept values that are multiples of delta within range");
      Assert (Delta_Mismatch.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Delta_Mismatch,
              "fixed-point quantization must reject static values not representable as a delta multiple");
      Assert (Range_Error.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Range_Error,
              "fixed-point quantization must reject static values outside the staged range");
      Assert (Editor.Ada_Static_Expressions.Is_Static_Real (Quantized)
              and then Editor.Ada_Static_Expressions.Is_Static_Numeric (Quantized),
              "fixed-point static values must participate in numeric static predicates");
      Assert (Editor.Ada_Static_Expressions.Fingerprint (Statics) /= 0,
              "static fixed-point model must retain deterministic fingerprints");
   end Test_Ada_Static_Fixed_Point_Foundation;

   overriding function Name (T : StaticExpressionFoundation_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Static-Expression-Foundation-Tests");
   end Name;

   overriding procedure Register_Tests (T : in out StaticExpressionFoundation_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Static_Enumeration_Position_Foundation'Access, Name => "Ada static expressions stage enumeration literal positions and Pos/Val metadata");
      Add_Test (Routine => Test_Ada_Static_Modular_Integer_Foundation'Access, Name => "Ada static expressions stage modular integer type modulus and reductions");
      Add_Test (Routine => Test_Ada_Static_Real_Numeric_Foundation'Access, Name => "Ada static expressions evaluate real and universal numeric constants");
      Add_Test (Routine => Test_Ada_Static_Fixed_Point_Foundation'Access, Name => "Ada static expressions stage fixed-point deltas ranges and quantization");
   end Register_Tests;

end Editor.Syntax_Semantics.Static_Expression_Foundation_Tests;
