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

package body Editor.Syntax_Semantics.Legality_Pass_Tests is

   procedure Test_Ada_Address_Clause_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Address_Clause_Checks is" & ASCII.LF &
        "   type T is range 0 .. 10;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   Y : Integer;" & ASCII.LF &
        "   Z : Integer;" & ASCII.LF &
        "   Good : Integer;" & ASCII.LF &
        "   for T'Address use System'To_Address (16#1000#);" & ASCII.LF &
        "   for X'Address use null;" & ASCII.LF &
        "   for Y'Address use Dyn;" & ASCII.LF &
        "   for Z'Address use 16#2000#;" & ASCII.LF &
        "   for Good'Address use X'Address;" & ASCII.LF &
        "end Address_Clause_Checks;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Static : constant Editor.Ada_Static_Expressions.Static_Model :=
        Editor.Ada_Static_Expressions.Build (Tree, Regions);
      Freezing : constant Editor.Ada_Freezing_Points.Freezing_Model :=
        Editor.Ada_Freezing_Points.Build (Tree, Regions, Visibility, Types);
      Legality : constant Editor.Ada_Representation_Legality.Representation_Legality_Model :=
        Editor.Ada_Representation_Legality.Build
          (Tree, Regions, Types, Static, Freezing);
      Seen_Target_Error : Boolean := False;
      Seen_Null_Error : Boolean := False;
      Seen_Not_Static : Boolean := False;
      Seen_Incompatible_Value : Boolean := False;
      Seen_Static_Address : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
         begin
            if Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Address_Target_Incompatible then
               Seen_Target_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Null_Not_Allowed then
               Seen_Null_Error := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Not_Static_Address then
               Seen_Not_Static := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Incompatible then
               Seen_Incompatible_Value := True;
            elsif Info.Status = Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Info.Address_Status = Editor.Ada_Representation_Legality.Address_Value_Static_Address
            then
               Seen_Static_Address := True;
            end if;
         end;
      end loop;

      Assert (Seen_Target_Error,
              "address clause legality must reject type targets");
      Assert (Seen_Null_Error,
              "address clause legality must reject null address values");
      Assert (Seen_Not_Static,
              "address clause legality must reject arbitrary non-static address names");
      Assert (Seen_Incompatible_Value,
              "address clause legality must reject raw literal address values");
      Assert (Seen_Static_Address,
              "address clause legality must accept staged static address expressions");
      Assert (Editor.Ada_Representation_Legality.Address_Target_Error_Count (Legality) >= 1,
              "address clause legality must count target errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Address_Value_Error_Count (Legality) >= 3,
              "address clause legality must count value-shape errors deterministically");
      Assert (Editor.Ada_Representation_Legality.Address_Static_Value_Count (Legality) >= 1,
              "address clause legality must count static address values deterministically");
      Assert (Editor.Ada_Representation_Legality.Fingerprint (Legality) /= 0,
              "address clause legality must contribute to deterministic fingerprints");
   end Test_Ada_Address_Clause_Legality;

   procedure Test_Language_Model_Legality_Checking_First_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   X : Boolean;" & ASCII.LF &
        "   type Colour is (Red, Green, Blue);" & ASCII.LF &
        "   for Colour use (Red => 1, Green => 1, Blue => 2);" & ASCII.LF &
        "   type Pair is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Pair use record" & ASCII.LF &
        "      A at 0 range 7 .. 0;" & ASCII.LF &
        "      B at 0 range 4 .. 9;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Pair'Size use 32;" & ASCII.LF &
        "   for Pair'Size use 64;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Declaration : Boolean := False;
      Seen_Duplicate_Rep : Boolean := False;
      Seen_Duplicate_Enum : Boolean := False;
      Seen_Invalid_Bits : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "legality checking should expose retained Ada legality errors");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Declaration =>
                  Seen_Duplicate_Declaration := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Representation_Clause =>
                  Seen_Duplicate_Rep := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Enumeration_Representation_Value =>
                  Seen_Duplicate_Enum := True;
               when Editor.Ada_Language_Model.Legality_Record_Component_Invalid_Bit_Range =>
                  Seen_Invalid_Bits := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Duplicate_Declaration,
              "legality checking should flag duplicate same-scope declarations");
      Assert (Seen_Duplicate_Rep,
              "legality checking should flag duplicate representation clauses");
      Assert (Seen_Duplicate_Enum,
              "legality checking should flag duplicate enumeration representation values");
      Assert (Seen_Invalid_Bits,
              "legality checking should flag invalid record representation bit ranges");
   end Test_Language_Model_Legality_Checking_First_Pass;

   procedure Test_Language_Model_Legality_Full_Address_Clause_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type T is range 0 .. 10;" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   Y : Integer;" & ASCII.LF &
        "   Z : Integer;" & ASCII.LF &
        "   Good : Integer;" & ASCII.LF &
        "   for T'Address use System'To_Address (16#1000#);" & ASCII.LF &
        "   for X'Address use null;" & ASCII.LF &
        "   for Y'Address use Dyn;" & ASCII.LF &
        "   for Z'Address use 16#2000#;" & ASCII.LF &
        "   for Good'Address use X'Address;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Target : Boolean := False;
      Seen_Null : Boolean := False;
      Seen_Not_Static_Address : Boolean := False;
      Seen_Incompatible_Value : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "full Address clause legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Address_Target_Incompatible =>
                  Seen_Target := True;
               when Editor.Ada_Language_Model.Legality_Address_Value_Null_Not_Allowed =>
                  Seen_Null := True;
               when Editor.Ada_Language_Model.Legality_Address_Value_Not_Static_Address =>
                  Seen_Not_Static_Address := True;
               when Editor.Ada_Language_Model.Legality_Address_Value_Incompatible =>
                  Seen_Incompatible_Value := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Target,
              "Address clauses should reject non-addressable type targets");
      Assert (Seen_Null,
              "Address clauses should reject null literal values");
      Assert (Seen_Not_Static_Address,
              "Address clauses should reject arbitrary non-address names in the bounded model");
      Assert (Seen_Incompatible_Value,
              "Address clauses should reject raw literal values");
   end Test_Language_Model_Legality_Full_Address_Clause_Pass;

   procedure Test_Language_Model_Legality_Renaming_Target_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "   X_Alias : Integer renames X;" & ASCII.LF &
        "   Self_Alias : Integer renames Self_Alias;" & ASCII.LF &
        "   Missing_Alias : Integer renames ;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Missing_Target : Boolean := False;
      Seen_Self_Target : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "renaming target legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Renaming_Missing_Target =>
                  Seen_Missing_Target := True;
               when Editor.Ada_Language_Model.Legality_Renaming_Self_Target =>
                  Seen_Self_Target := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Missing_Target,
              "legality checking should flag renaming declarations without retained targets");
      Assert (Seen_Self_Target,
              "legality checking should flag declarations that rename themselves");
   end Test_Language_Model_Legality_Renaming_Target_Pass;

   procedure Test_Language_Model_Legality_Label_Goto_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure P is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   <<Again>>" & ASCII.LF &
        "   null;" & ASCII.LF &
        "   <<Again>>" & ASCII.LF &
        "   goto Missing_Label;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Label : Boolean := False;
      Seen_Missing_Goto : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "label/goto legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Label =>
                  Seen_Duplicate_Label := True;
               when Editor.Ada_Language_Model.Legality_Goto_Missing_Target =>
                  Seen_Missing_Goto := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Duplicate_Label,
              "legality checking should flag duplicate statement labels");
      Assert (Seen_Missing_Goto,
              "legality checking should flag goto statements without retained labels");
   end Test_Language_Model_Legality_Label_Goto_Pass;

   procedure Test_Language_Model_Legality_Block_Label_Exit_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure P is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Main : loop" & ASCII.LF &
        "      exit Missing_Loop;" & ASCII.LF &
        "   end loop Main;" & ASCII.LF &
        "   Main : loop" & ASCII.LF &
        "      exit Main;" & ASCII.LF &
        "   end loop Main;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Block_Label : Boolean := False;
      Seen_Missing_Exit_Target : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "block-label/exit legality should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Block_Label =>
                  Seen_Duplicate_Block_Label := True;
               when Editor.Ada_Language_Model.Legality_Exit_Missing_Target =>
                  Seen_Missing_Exit_Target := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Duplicate_Block_Label,
              "legality checking should flag duplicate block/loop labels");
      Assert (Seen_Missing_Exit_Target,
              "legality checking should flag named exits without retained loop/block labels");
   end Test_Language_Model_Legality_Block_Label_Exit_Pass;

   procedure Test_Language_Model_Legality_Pragma_Named_Argument_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure P is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   pragma Assert (Check => Ready, Message => Image (State), Check => Valid);" & ASCII.LF &
        "   pragma Assert (Check => Ready, Message => ""ok"");" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Duplicate_Pragma_Argument : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "duplicate pragma named arguments should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            if Info.Kind = Editor.Ada_Language_Model.Legality_Duplicate_Pragma_Named_Argument then
               Seen_Duplicate_Pragma_Argument := True;
            end if;
         end;
      end loop;

      Assert (Seen_Duplicate_Pragma_Argument,
              "legality checking should flag duplicate named arguments within one pragma");
   end Test_Language_Model_Legality_Pragma_Named_Argument_Pass;

   procedure Test_Language_Model_Legality_Local_Duplicate_Choice_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Demo is" & ASCII.LF &
        "   type Rec (Kind : Natural) is record" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when 1 | 1 =>" & ASCII.LF &
        "            A : Integer;" & ASCII.LF &
        "         when others => null;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   X : Rec := (Kind => 1, A => 1, A => 2);" & ASCII.LF &
        "   Y : Rec := (X with delta A => 1, A => 2);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case X.Kind is" & ASCII.LF &
        "      when 2 | 2 => null;" & ASCII.LF &
        "      when others => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Constraint_Error | Constraint_Error =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Demo;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Seen_Case      : Boolean := False;
      Seen_Variant   : Boolean := False;
      Seen_Exception : Boolean := False;
      Seen_Aggregate : Boolean := False;
      Seen_Delta     : Boolean := False;
   begin
      Assert (Editor.Ada_Language_Model.Has_Legality_Diagnostics (Analysis),
              "local duplicate choices should add diagnostics");

      for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
         declare
            Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
              Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
         begin
            case Info.Kind is
               when Editor.Ada_Language_Model.Legality_Duplicate_Case_Choice =>
                  Seen_Case := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Variant_Choice =>
                  Seen_Variant := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Exception_Choice =>
                  Seen_Exception := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Aggregate_Component_Choice =>
                  Seen_Aggregate := True;
               when Editor.Ada_Language_Model.Legality_Duplicate_Delta_Aggregate_Component =>
                  Seen_Delta := True;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Seen_Case,
              "duplicate case choices in one alternative should be diagnosed");
      Assert (Seen_Variant,
              "duplicate variant choices in one alternative should be diagnosed");
      Assert (Seen_Exception,
              "duplicate exception choices in one handler should be diagnosed");
      Assert (Seen_Aggregate,
              "duplicate aggregate component selectors should be diagnosed");
      Assert (Seen_Delta,
              "duplicate delta aggregate component selectors should be diagnosed");
   end Test_Language_Model_Legality_Local_Duplicate_Choice_Pass;

   procedure Test_Language_Model_Class_Wide_Property_Name_Canonicalization_Pass
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   type Root is tagged null record with Type_Invariant 'Class => True;" & ASCII.LF &
        "   for Root'Type_Invariant 'Class use True;" & ASCII.LF &
        "   procedure Op (X : Root) with Pre 'Class => True, Post 'Class => True, Nonblocking 'Class;" & ASCII.LF &
        "   for Op'Pre 'Class use True;" & ASCII.LF &
        "   for Op'Post 'Class use True;" & ASCII.LF &
        "   for Op'Nonblocking 'Class use True;" & ASCII.LF &
        "end P;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      use type Editor.Ada_Language_Model.Representation_Clause_Kind;
      Root_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Root");
      Op_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Op");
      Seen_Type_Invariant_Class : Natural := 0;
      Seen_Pre_Class : Natural := 0;
      Seen_Post_Class : Natural := 0;
      Seen_Nonblocking_Class : Natural := 0;
   begin
      Assert (Root_Id /= Editor.Ada_Language_Model.No_Symbol,
              "class-wide invariant type target should be retained");
      Assert (Op_Id /= Editor.Ada_Language_Model.No_Symbol,
              "class-wide contract subprogram target should be retained");

      for I in 1 .. Editor.Ada_Language_Model.Representation_Clause_Count (Analysis) loop
         declare
            R : constant Editor.Ada_Language_Model.Representation_Clause_Info :=
              Editor.Ada_Language_Model.Representation_Clause_At
                (Analysis, Editor.Ada_Language_Model.No_Symbol, I);
         begin
            if R.Target_Symbol = Root_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Type_Invariant_Class_Clause
            then
               Seen_Type_Invariant_Class := Seen_Type_Invariant_Class + 1;
            elsif R.Target_Symbol = Op_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Pre_Class_Clause
            then
               Seen_Pre_Class := Seen_Pre_Class + 1;
            elsif R.Target_Symbol = Op_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Post_Class_Clause
            then
               Seen_Post_Class := Seen_Post_Class + 1;
            elsif R.Target_Symbol = Op_Id
              and then R.Kind = Editor.Ada_Language_Model.Representation_Nonblocking_Class_Clause
            then
               Seen_Nonblocking_Class := Seen_Nonblocking_Class + 1;
            end if;
         end;
      end loop;

      Assert (Seen_Type_Invariant_Class = 2,
              "Type_Invariant 'Class aspect and attribute clause should share the class-wide kind");
      Assert (Seen_Pre_Class = 2,
              "Pre 'Class aspect and attribute clause should share the class-wide kind");
      Assert (Seen_Post_Class = 2,
              "Post 'Class aspect and attribute clause should share the class-wide kind");
      Assert (Seen_Nonblocking_Class = 2,
              "Nonblocking 'Class aspect and attribute clause should share the class-wide kind");
   end Test_Language_Model_Class_Wide_Property_Name_Canonicalization_Pass;

   procedure Test_Language_Model_Conservative_Syntax_Recovery_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      use type Editor.Ada_Language_Model.Legality_Diagnostic_Kind;
      Source : constant String :=
        "package P is" & Character'Val (10) &
        "   pragma Inline (Foo" & Character'Val (10) &
        "   type T is private" & Character'Val (10) &
        "   procedure Q;" & Character'Val (10) &
        "end P;" & Character'Val (10) &
        "procedure Body_Q is" & Character'Val (10) &
        "begin" & Character'Val (10) &
        "   case V is" & Character'Val (10) &
        "      when 1" & Character'Val (10) &
        "         null;" & Character'Val (10) &
        "      when others => null;" & Character'Val (10) &
        "   end case;" & Character'Val (10) &
        "exception" & Character'Val (10) &
        "   when Constraint_Error" & Character'Val (10) &
        "      null;" & Character'Val (10) &
        "end Body_Q;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);

      function Has_Diagnostic
        (Kind : Editor.Ada_Language_Model.Legality_Diagnostic_Kind) return Boolean
      is
      begin
         for I in 1 .. Editor.Ada_Language_Model.Legality_Diagnostic_Count (Analysis) loop
            declare
               Info : constant Editor.Ada_Language_Model.Legality_Diagnostic_Info :=
                 Editor.Ada_Language_Model.Legality_Diagnostic_At (Analysis, I);
            begin
               if Info.Kind = Kind then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Diagnostic;
   begin
      Assert
        (Has_Diagnostic (Editor.Ada_Language_Model.Legality_Malformed_Pragma_Syntax),
         "malformed pragma recovery should produce a conservative diagnostic");
      Assert
        (Has_Diagnostic (Editor.Ada_Language_Model.Legality_Missing_Declaration_Terminator),
         "missing declaration terminators should produce conservative diagnostics");
      Assert
        (Has_Diagnostic (Editor.Ada_Language_Model.Legality_Malformed_Case_Alternative),
         "case alternatives missing => should produce conservative diagnostics");
      Assert
        (Has_Diagnostic (Editor.Ada_Language_Model.Legality_Malformed_Handler_Alternative),
         "exception handlers missing => should produce conservative diagnostics");
   end Test_Language_Model_Conservative_Syntax_Recovery_Diagnostics;

   overriding function Name (T : LegalityPass_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Legality-Pass-Tests");
   end Name;

   overriding procedure Register_Tests (T : in out LegalityPass_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Ada_Address_Clause_Legality'Access, Name => "Ada representation legality checks Address clauses");
      Add_Test (Routine => Test_Language_Model_Legality_Checking_First_Pass'Access, Name => "language model performs first-pass Ada legality checking");
      Add_Test (Routine => Test_Language_Model_Legality_Full_Address_Clause_Pass'Access, Name => "language model checks full Address clause legality");
      Add_Test (Routine => Test_Language_Model_Legality_Renaming_Target_Pass'Access, Name => "language model checks renaming target legality");
      Add_Test (Routine => Test_Language_Model_Legality_Label_Goto_Pass'Access, Name => "language model checks label and goto target legality");
      Add_Test (Routine => Test_Language_Model_Legality_Block_Label_Exit_Pass'Access, Name => "language model checks block-label and named-exit legality");
      Add_Test (Routine => Test_Language_Model_Legality_Pragma_Named_Argument_Pass'Access, Name => "language model checks duplicate pragma named argument legality");
      Add_Test (Routine => Test_Language_Model_Legality_Local_Duplicate_Choice_Pass'Access, Name => "language model checks local duplicate case variant exception and aggregate choices");
      Add_Test (Routine => Test_Language_Model_Class_Wide_Property_Name_Canonicalization_Pass'Access, Name => "language model canonicalizes class-wide aspect and attribute property names");
      Add_Test (Routine => Test_Language_Model_Conservative_Syntax_Recovery_Diagnostics'Access, Name => "language model emits conservative syntax-recovery legality diagnostics");
   end Register_Tests;

end Editor.Syntax_Semantics.Legality_Pass_Tests;
