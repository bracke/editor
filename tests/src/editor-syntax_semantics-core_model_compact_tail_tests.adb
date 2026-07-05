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

package body Editor.Syntax_Semantics.Core_Model_Compact_Tail_Tests is



   procedure Test_Language_Model_Same_Line_Record_Discriminant_Parent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Records is" & ASCII.LF &
        "   type Rec (Id : Natural) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Records;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "records.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Id", Rec_Id);
      Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Value", Rec_Id);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Id);
      Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Value_Id);
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be present in the language model");
      Assert (Id_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant,
              "same-line record discriminants should be parsed as discriminants");
      Assert (Id_Info.Parent_Symbol = Rec_Id,
              "same-line record discriminants should attach to the record type, not the enclosing package");
      Assert (Value_Info.Parent_Symbol = Rec_Id,
              "record components should attach to the same record parent as discriminants");
   end Test_Language_Model_Same_Line_Record_Discriminant_Parent;





   procedure Test_Language_Model_Same_Line_Discriminants_Do_Not_Learn_Header
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Records is" & ASCII.LF &
        "   type Rec (Id : Natural; Flag : Boolean) is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Records;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "records.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Discriminant_Count : Natural := 0;
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "record type should be present before checking discriminants");

      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Name);
         begin
            if S.Parent_Symbol = Rec_Id
              and then S.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
            then
               Discriminant_Count := Discriminant_Count + 1;
               Assert (N = "Id" or else N = "Flag",
                       "same-line discriminant extraction must not learn type header identifiers as discriminants");
            end if;
         end;
      end loop;

      Assert (Discriminant_Count = 2,
              "same-line record header should contribute only the actual discriminant names");
      Assert (Editor.Ada_Symbol_Resolver.First_Match_In_Scope
                (Analysis, "type", Rec_Id) = Editor.Ada_Language_Model.No_Symbol,
              "Ada keyword from record header must not be learned as a discriminant");
   end Test_Language_Model_Same_Line_Discriminants_Do_Not_Learn_Header;




   procedure Test_Language_Model_Same_Line_Record_Component_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Record_Components is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      A : Natural; B, C : Boolean;" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when Small => Count : Natural; Ready : Boolean;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Same_Line_Record_Components;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_record_components.ads");
      A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "A");
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "B");
      C_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "C");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Ready_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ready");
      When_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "when");
      Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Small");
      B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, B_Id);
      C_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, C_Id);
      Ready_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ready_Id);
   begin
      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol,
              "first same-line component group should be parsed");
      Assert (B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then To_String (B_Info.Target_Name) = "Boolean",
              "second same-line component group should retain component kind and target");
      Assert (C_Id /= Editor.Ada_Language_Model.No_Symbol
              and then C_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then To_String (C_Info.Target_Name) = "Boolean",
              "multi-name same-line component group should retain all names");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol,
              "variant component after choice arrow should still parse");
      Assert (Ready_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Ready_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then To_String (Ready_Info.Target_Name) = "Boolean",
              "second variant component on the same line should parse");
      Assert (When_Id = Editor.Ada_Language_Model.No_Symbol
              and then Small_Id = Editor.Ada_Language_Model.No_Symbol,
              "variant choice words must remain metadata, not record components");
   end Test_Language_Model_Same_Line_Record_Component_Groups;



   procedure Test_Language_Model_One_Line_Record_Scope_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package One_Line_Record is" & ASCII.LF &
        "   type Rec is record Left : Integer; Right, Flag : Boolean; case Kind is when Small => Count : Natural; Ready : Boolean; end case; end record;" & ASCII.LF &
        "end One_Line_Record;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_record.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Left");
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right");
      Flag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Flag");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Ready_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ready");
      Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Small");
      Left_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Left_Id);
      Right_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Right_Id);
      Flag_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Flag_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Ready_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ready_Id);
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "one-line record should still emit the record type symbol");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Left_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Left_Info.Parent_Symbol = Rec_Id
              and then To_String (Left_Info.Target_Name) = "Integer",
              "component after same-line record opener should be parented to record");
      Assert (Right_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Right_Info.Parent_Symbol = Rec_Id
              and then To_String (Right_Info.Target_Name) = "Boolean",
              "second one-line record component group should retain target metadata");
      Assert (Flag_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Flag_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Flag_Info.Parent_Symbol = Rec_Id
              and then Flag_Info.Declaration_Column > Right_Info.Declaration_Column,
              "multi-name one-line record component group should retain all names and columns");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Count_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Count_Info.Parent_Symbol = Rec_Id,
              "variant component inside one-line record should parse after choice arrow");
      Assert (Ready_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Ready_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Ready_Info.Parent_Symbol = Rec_Id
              and then To_String (Ready_Info.Target_Name) = "Boolean",
              "second variant component inside one-line record should parse");
      Assert (Small_Id = Editor.Ada_Language_Model.No_Symbol,
              "one-line variant choice must remain metadata, not a component");
   end Test_Language_Model_One_Line_Record_Scope_Declarations;



   procedure Test_Language_Model_Same_Line_Object_Declaration_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Objects is" & ASCII.LF &
        "   A : Natural; B, C : constant Boolean := True;" & ASCII.LF &
        "   E1 : exception; E2 : exception;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      X : in Natural; Y, Z : in Boolean;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "end Same_Line_Objects;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_objects.ads");
      A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "A");
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "B");
      C_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "C");
      E1_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "E1");
      E2_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "E2");
      X_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "X");
      Y_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Y");
      Z_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Z");
      A_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, A_Id);
      B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, B_Id);
      C_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, C_Id);
      E2_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, E2_Id);
      Y_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Y_Id);
      Z_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Z_Id);
   begin
      Assert (A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then A_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then To_String (A_Info.Target_Name) = "Natural",
              "first same-line object declaration group should parse");
      Assert (B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then C_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then C_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then To_String (B_Info.Target_Name) = "Boolean"
              and then To_String (C_Info.Target_Name) = "Boolean",
              "later same-line constant declaration group should parse all declared names");
      Assert (E1_Id /= Editor.Ada_Language_Model.No_Symbol
              and then E2_Id /= Editor.Ada_Language_Model.No_Symbol
              and then E2_Info.Kind = Editor.Ada_Language_Model.Symbol_Exception,
              "same-line exception declaration groups should not hide declarations after the first semicolon");
      Assert (X_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Y_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Z_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Y_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then Z_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Object
              and then To_String (Y_Info.Target_Name) = "Boolean"
              and then To_String (Z_Info.Target_Name) = "Boolean",
              "generic formal object groups on one line should parse scope-aware symbols");
   end Test_Language_Model_Same_Line_Object_Declaration_Groups;




   procedure Test_Language_Model_Same_Line_Subtype_Declaration_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Subtypes is" & ASCII.LF &
        "   subtype Count is Natural; subtype Index is Positive range 1 .. 10;" & ASCII.LF &
        "   private" & ASCII.LF &
        "   subtype Hidden is Boolean; subtype Flag is Boolean;" & ASCII.LF &
        "end Same_Line_Subtypes;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_subtypes.ads");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Hidden_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hidden");
      Flag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Flag");
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      Hidden_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Id);
      Flag_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Flag_Id);
   begin
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Count_Info.Kind = Editor.Ada_Language_Model.Symbol_Subtype
              and then To_String (Count_Info.Target_Name) = "Natural",
              "first same-line subtype declaration should parse");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Index_Info.Kind = Editor.Ada_Language_Model.Symbol_Subtype
              and then To_String (Index_Info.Target_Name) = "Positive",
              "later same-line subtype declaration should not be hidden by the first subtype");
      Assert (Hidden_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Flag_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Info.Flags.Is_Private
              and then Flag_Info.Flags.Is_Private,
              "same-line subtype declarations in private sections should retain private metadata");
   end Test_Language_Model_Same_Line_Subtype_Declaration_Groups;



   procedure Test_Language_Model_Same_Line_Type_Declaration_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Types is" & ASCII.LF &
        "   type Color is (Red, Green); type Mode is ('A', Named);" & ASCII.LF &
        "   type Count is range 0 .. 10; type Index is new Count;" & ASCII.LF &
        "   type Name_Array is array (Positive range <>) of Character; type Ref is access Count;" & ASCII.LF &
        "end Same_Line_Types;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_types.ads");
      Color_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Color");
      Mode_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Mode");
      Green_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Green");
      Named_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Named");
      Char_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "'A'");
      Index_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Index");
      Name_Array_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Name_Array");
      Ref_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ref");
      Mode_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Mode_Id);
      Green_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Green_Id);
      Named_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Named_Id);
      Char_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Char_Id);
      Index_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Index_Id);
      Name_Array_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Name_Array_Id);
      Ref_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ref_Id);
   begin
      Assert (Color_Id /= Editor.Ada_Language_Model.No_Symbol,
              "first same-line type declaration should parse");
      Assert (Mode_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Mode_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "later same-line type declaration should not be hidden by the first type");
      Assert (Green_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Green_Info.Kind = Editor.Ada_Language_Model.Symbol_Enumeration_Literal
              and then Green_Info.Parent_Symbol = Color_Id,
              "first type segment should retain enumeration literals");
      Assert (Named_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Named_Info.Kind = Editor.Ada_Language_Model.Symbol_Enumeration_Literal
              and then Named_Info.Parent_Symbol = Mode_Id,
              "later type segment should retain enumeration literals");
      Assert (Char_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Char_Info.Kind = Editor.Ada_Language_Model.Symbol_Enumeration_Literal
              and then Char_Info.Parent_Symbol = Mode_Id,
              "character enumeration literals should survive same-line type splitting");
      Assert (Index_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Index_Info.Target_Name) = "Count",
              "same-line derived type should retain parent target metadata");
      Assert (Name_Array_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Name_Array_Info.Target_Name) = "Character",
              "same-line array type should retain component target metadata");
      Assert (Ref_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Ref_Info.Target_Name) = "Count",
              "same-line access type should retain designated target metadata");
   end Test_Language_Model_Same_Line_Type_Declaration_Groups;



   procedure Test_Language_Model_Same_Line_Type_Profile_Semicolons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Type_Profile_Semicolons is" & ASCII.LF &
        "   type Callback_Access is access procedure (Left_Param : Integer; Right_Param : Integer); type Next_Count is range 0 .. 10;" & ASCII.LF &
        "   type Predicate_Access is access function (Left_Filter : Integer; Right_Filter : Integer) return Boolean; type Final_Index is new Next_Count;" & ASCII.LF &
        "end Same_Line_Type_Profile_Semicolons;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_type_profile_semicolons.ads");
      Callback_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callback_Access");
      Next_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Next_Count");
      Predicate_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Predicate_Access");
      Final_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Final_Index");
      Left_Param_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Left_Param");
      Right_Param_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right_Param");
      Callback_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Callback_Id);
      Next_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Next_Id);
      Predicate_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Predicate_Id);
      Final_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Final_Id);
   begin
      Assert (Callback_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Callback_Info.Kind = Editor.Ada_Language_Model.Symbol_Type,
              "access-to-procedure type before a profile semicolon should parse");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Callback_Info.Profile_Summary), "Right_Param") /= 0,
              "same-line type splitter should keep profile semicolons inside the access profile");
      Assert (Next_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Next_Info.Kind = Editor.Ada_Language_Model.Symbol_Type
              and then Next_Info.Declaration_Column > Callback_Info.Declaration_Column,
              "type declaration after access profile semicolon should still parse");
      Assert (Predicate_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Predicate_Info.Kind = Editor.Ada_Language_Model.Symbol_Type
              and then Ada.Strings.Fixed.Index
                (To_String (Predicate_Info.Profile_Summary), "Right_Filter") /= 0,
              "access-to-function type profile should retain second profile parameter text");
      Assert (Final_Id /= Editor.Ada_Language_Model.No_Symbol
              and then To_String (Final_Info.Target_Name) = "Next_Count",
              "following derived type should retain parent target after profile-safe splitting");
      Assert (Left_Param_Id = Editor.Ada_Language_Model.No_Symbol
              and then Right_Param_Id = Editor.Ada_Language_Model.No_Symbol,
              "access type profile parameters should remain metadata-only symbols");
   end Test_Language_Model_Same_Line_Type_Profile_Semicolons;



   procedure Test_Language_Model_Same_Line_Callable_Declaration_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Callables is" & ASCII.LF &
        "   procedure First (A : Natural; B : Boolean); procedure Second; function Make return Integer; function ""+"" (L, R : Integer) return Integer;" & ASCII.LF &
        "   procedure Old renames New_Name; procedure Proc_Inst is new Generic_Proc;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with procedure Visit (Item : Element); with function Make_Default return Element is Default_Element;" & ASCII.LF &
        "   package G is end G;" & ASCII.LF &
        "end Same_Line_Callables;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_callables.ads");
      First_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "First");
      B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "B");
      Second_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Second");
      Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make");
      Plus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """+""");
      Old_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Old");
      Proc_Inst_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Proc_Inst");
      Visit_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Visit");
      Item_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Item");
      Make_Default_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make_Default");
      B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, B_Id);
      Second_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Second_Id);
      Make_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Id);
      Plus_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Plus_Id);
      Old_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Old_Id);
      Proc_Inst_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Proc_Inst_Id);
      Visit_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Visit_Id);
      Item_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Item_Id);
      Make_Default_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Default_Id);
   begin
      Assert (First_Id /= Editor.Ada_Language_Model.No_Symbol,
              "first same-line callable declaration should parse");
      Assert (B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then B_Info.Parent_Symbol = First_Id
              and then To_String (B_Info.Target_Name) = "Boolean",
              "parameter-list semicolons must stay inside the first callable profile");
      Assert (Second_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Second_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure,
              "later same-line procedure declaration should parse");
      Assert (Make_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Info.Kind = Editor.Ada_Language_Model.Symbol_Function
              and then To_String (Make_Info.Target_Name) = "Integer",
              "later same-line function declaration should retain return target");
      Assert (Plus_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Plus_Info.Kind = Editor.Ada_Language_Model.Symbol_Operator_Function,
              "same-line operator function declaration should retain operator kind");
      Assert (Old_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Old_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Old_Info.Flags.Is_Rename
              and then To_String (Old_Info.Target_Name) = "New_Name",
              "same-line procedure rename should retain callable kind and rename target");
      Assert (Proc_Inst_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Proc_Inst_Info.Kind = Editor.Ada_Language_Model.Symbol_Instantiation
              and then Proc_Inst_Info.Flags.Is_Instantiation
              and then To_String (Proc_Inst_Info.Target_Name) = "Generic_Proc",
              "same-line procedure instantiation should retain instantiation metadata");
      Assert (Visit_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Visit_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then Visit_Info.Flags.Is_Generic,
              "same-line generic formal procedure should parse as a formal subprogram");
      Assert (Item_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Item_Info.Parent_Symbol = Visit_Id
              and then To_String (Item_Info.Target_Name) = "Element",
              "same-line generic formal procedure should retain profile parameters");
      Assert (Make_Default_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Default_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Subprogram
              and then To_String (Make_Default_Info.Target_Name) = "Element",
              "same-line generic formal function should retain return target metadata");
   end Test_Language_Model_Same_Line_Callable_Declaration_Groups;



   procedure Test_Language_Model_Same_Line_Object_Rename_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Renames is" & ASCII.LF &
        "   Source_A : Integer; Source_B : Integer;" & ASCII.LF &
        "   Alias_A : Integer renames Source_A; Alias_B : constant Integer renames Source_B;" & ASCII.LF &
        "   First_Error : exception; Second_Error : exception;" & ASCII.LF &
        "   Error_A : exception renames First_Error; Error_B : exception renames Second_Error;" & ASCII.LF &
        "end Same_Line_Renames;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_renames.ads");
      Alias_A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_A");
      Alias_B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_B");
      Error_B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Error_B");
      Alias_A_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Alias_A_Id);
      Alias_B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Alias_B_Id);
      Error_B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Error_B_Id);
   begin
      Assert (Alias_A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Alias_A_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Alias_A_Info.Flags.Is_Rename
              and then To_String (Alias_A_Info.Target_Name) = "Source_A",
              "first same-line object rename should preserve the renamed target");
      Assert (Alias_B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Alias_B_Info.Kind = Editor.Ada_Language_Model.Symbol_Constant
              and then Alias_B_Info.Flags.Is_Rename
              and then To_String (Alias_B_Info.Target_Name) = "Source_B",
              "later same-line constant rename should not be hidden by the first rename");
      Assert (Error_B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Error_B_Info.Kind = Editor.Ada_Language_Model.Symbol_Exception
              and then Error_B_Info.Flags.Is_Rename
              and then To_String (Error_B_Info.Target_Name) = "Second_Error",
              "same-line exception rename groups should retain per-segment targets");
   end Test_Language_Model_Same_Line_Object_Rename_Groups;





   procedure Test_Language_Model_Same_Line_Package_Declaration_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Packages is" & ASCII.LF &
        "   package Alias_A renames Root.A; package Inst_B is new Generic_B (Integer);" & ASCII.LF &
        "   private package Hidden.Child is end Hidden.Child; package body Body_P is end Body_P;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      with package Formal_A is new Generic_Formal (<>); with package Formal_B is new Generic_Formal (<>);" & ASCII.LF &
        "   package Holder is end Holder;" & ASCII.LF &
        "end Same_Line_Packages;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_packages.ads");
      Alias_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Alias_A");
      Inst_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inst_B");
      Hidden_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Hidden.Child");
      Body_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Body_P");
      Formal_A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_A");
      Formal_B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Formal_B");
      Alias_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Alias_Id);
      Inst_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inst_Id);
      Hidden_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Hidden_Id);
      Body_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Body_Id);
      Formal_A_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_A_Id);
      Formal_B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Formal_B_Id);
   begin
      Assert (Alias_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Alias_Info.Kind = Editor.Ada_Language_Model.Symbol_Package
              and then Alias_Info.Flags.Is_Rename
              and then To_String (Alias_Info.Target_Name) = "Root.A",
              "same-line package rename should retain package kind and target");
      Assert (Inst_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inst_Info.Kind = Editor.Ada_Language_Model.Symbol_Instantiation
              and then Inst_Info.Flags.Is_Instantiation
              and then To_String (Inst_Info.Target_Name) = "Generic_B",
              "same-line package instantiation after a semicolon should parse with target metadata");
      Assert (Hidden_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Info.Kind = Editor.Ada_Language_Model.Symbol_Package
              and then Hidden_Info.Flags.Is_Private,
              "same-line private package declaration should preserve private metadata");
      Assert (Body_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Body_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body,
              "same-line package body declaration should retain body kind");
      Assert (Formal_A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Formal_A_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Package
              and then Formal_B_Info.Kind = Editor.Ada_Language_Model.Symbol_Generic_Formal_Package
              and then Formal_A_Info.Flags.Is_Generic
              and then Formal_B_Info.Flags.Is_Generic
              and then To_String (Formal_A_Info.Target_Name) = "Generic_Formal"
              and then To_String (Formal_B_Info.Target_Name) = "Generic_Formal",
              "same-line generic formal package declarations should retain both formals and targets");
   end Test_Language_Model_Same_Line_Package_Declaration_Groups;



   procedure Test_Language_Model_Same_Line_Concurrent_Declaration_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Same_Line_Concurrent is" & ASCII.LF &
        "   task Worker; task type Pool (Id : Positive); protected Lock; protected type Guard (Size : Natural);" & ASCII.LF &
        "   task type Server is" & ASCII.LF &
        "      entry Start; entry Stop (Code : Natural);" & ASCII.LF &
        "   end Server;" & ASCII.LF &
        "end Same_Line_Concurrent;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "same_line_concurrent.ads");
      Worker_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Worker");
      Pool_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Pool");
      Id_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Id");
      Lock_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Lock");
      Guard_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Guard");
      Size_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Size");
      Server_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Server");
      Start_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Start");
      Stop_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Stop");
      Code_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Code");
      Worker_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Worker_Id);
      Pool_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Pool_Id);
      Id_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Id_Id);
      Lock_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Lock_Id);
      Guard_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Guard_Id);
      Size_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Size_Id);
      Server_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Server_Id);
      Start_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Start_Id);
      Stop_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Stop_Id);
      Code_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Code_Id);
   begin
      Assert (Worker_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Worker_Info.Kind = Editor.Ada_Language_Model.Symbol_Task,
              "first same-line task declaration should parse");
      Assert (Pool_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Pool_Info.Kind = Editor.Ada_Language_Model.Symbol_Task,
              "later same-line task type declaration should parse");
      Assert (Id_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Id_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Id_Info.Parent_Symbol = Pool_Id,
              "same-line task type discriminants should be owned by the task type");
      Assert (Lock_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Lock_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected,
              "same-line protected object declaration should parse");
      Assert (Guard_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Guard_Info.Kind = Editor.Ada_Language_Model.Symbol_Protected,
              "same-line protected type declaration should parse");
      Assert (Size_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Size_Info.Kind = Editor.Ada_Language_Model.Symbol_Discriminant
              and then Size_Info.Parent_Symbol = Guard_Id,
              "same-line protected type discriminants should be owned by the protected type");
      Assert (Server_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Server_Info.Kind = Editor.Ada_Language_Model.Symbol_Task,
              "task type scope opener should still parse normally");
      Assert (Start_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Start_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Start_Info.Parent_Symbol = Server_Id,
              "first same-line entry declaration should stay inside the task type");
      Assert (Stop_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Stop_Info.Kind = Editor.Ada_Language_Model.Symbol_Entry
              and then Stop_Info.Parent_Symbol = Server_Id,
              "later same-line entry declaration should stay inside the task type");
      Assert (Code_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Code_Info.Parent_Symbol = Stop_Id
              and then To_String (Code_Info.Target_Name) = "Natural",
              "same-line entry profile parameters should be owned by the entry");
   end Test_Language_Model_Same_Line_Concurrent_Declaration_Groups;



   procedure Test_Language_Model_One_Line_Package_Scope_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package One_Line_Scope is First_Value : Integer; Second_Value : Boolean; end One_Line_Scope;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_scope.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Scope");
      First_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "First_Value");
      Second_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Second_Value");
      First_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, First_Id);
      Second_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Second_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "one-line package scope should still emit the package symbol");
      Assert (First_Id /= Editor.Ada_Language_Model.No_Symbol
              and then First_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then First_Info.Parent_Symbol = Package_Id
              and then To_String (First_Info.Target_Name) = "Integer",
              "declaration after same-line scope-opening is should be parented to package");
      Assert (Second_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Second_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Second_Info.Parent_Symbol = Package_Id
              and then Second_Info.Declaration_Column > First_Info.Declaration_Column
              and then To_String (Second_Info.Target_Name) = "Boolean",
              "second declaration in one-line package scope should retain column and target metadata");
   end Test_Language_Model_One_Line_Package_Scope_Declarations;



   procedure Test_Language_Model_One_Line_Package_Private_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package One_Line_Private is Public_Value : Integer; private; Hidden_Value : Boolean; Hidden_Type : Integer; end One_Line_Private;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_private.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Private");
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
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "one-line package private tail should still emit the package symbol");
      Assert (Public_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Public_Info.Parent_Symbol = Package_Id
              and then not Public_Info.Flags.Is_Private,
              "declarations before compact mid-tail private marker should remain public");
      Assert (Hidden_Value_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Value_Info.Parent_Symbol = Package_Id
              and then Hidden_Value_Info.Flags.Is_Private
              and then Hidden_Value_Info.Declaration_Column > Public_Info.Declaration_Column,
              "declaration after compact mid-tail private marker should be private");
      Assert (Hidden_Type_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Hidden_Type_Info.Parent_Symbol = Package_Id
              and then Hidden_Type_Info.Flags.Is_Private
              and then Hidden_Type_Info.Declaration_Column > Hidden_Value_Info.Declaration_Column,
              "later compact scope-tail declarations should stay private until the same-line end");
   end Test_Language_Model_One_Line_Package_Private_Tail;


   procedure Test_Language_Model_One_Line_Package_Record_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package One_Line_Record_Tail is type Compact_Record is record Left_Field : Integer; Right_Field, Flag_Field : Boolean; end record; After_Record : Integer; end One_Line_Record_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_record_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Record_Tail");
      Record_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Record");
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Left_Field");
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right_Field");
      Flag_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Flag_Field");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Record");
      Record_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Record_Id);
      Left_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Left_Id);
      Right_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Right_Id);
      Flag_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Flag_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "one-line package should still emit the package symbol");
      Assert (Record_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Record_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type
              and then Record_Info.Parent_Symbol = Package_Id,
              "compact record declaration inside one-line package should be package-parented");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Left_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Left_Info.Parent_Symbol = Record_Id,
              "first compact record component should be parented to the record, not the package");
      Assert (Right_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Right_Info.Parent_Symbol = Record_Id
              and then To_String (Right_Info.Target_Name) = "Boolean",
              "second compact record component after an internal semicolon should remain record-local");
      Assert (Flag_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Flag_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Flag_Info.Parent_Symbol = Record_Id
              and then Flag_Info.Declaration_Column > Right_Info.Declaration_Column,
              "grouped compact record components should retain record parentage and columns");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id
              and then After_Info.Declaration_Column > Flag_Info.Declaration_Column,
              "declarations after compact end record should resume in the enclosing package scope");
   end Test_Language_Model_One_Line_Package_Record_Tail;



   procedure Test_Language_Model_Compact_Record_Variant_End_Case_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Compact_Record_Variant_Tail is type Rec is record case Kind is when Small => Count : Integer; end case; Ready : Boolean; end record; After_Record : Integer; end Compact_Record_Variant_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "compact_record_variant_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Compact_Record_Variant_Tail");
      Record_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Ready_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Ready");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Record");
      Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Small");
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Ready_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Ready_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Record_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact record variant test should emit package and record symbols");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Count_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Count_Info.Parent_Symbol = Record_Id,
              "variant component before compact end case should be record-local");
      Assert (Ready_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Ready_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Ready_Info.Parent_Symbol = Record_Id
              and then Ready_Info.Declaration_Column > Count_Info.Declaration_Column,
              "component after compact end case should still be parsed before end record");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id
              and then After_Info.Declaration_Column > Ready_Info.Declaration_Column,
              "declaration after compact end record should resume in package scope");
      Assert (Small_Id = Editor.Ada_Language_Model.No_Symbol,
              "variant choice before end case must remain metadata");
   end Test_Language_Model_Compact_Record_Variant_End_Case_Tail;



   procedure Test_Language_Model_One_Line_Package_Record_Variant_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Package_Record_Variant_Tail is type Rec is record Header : Integer; case Kind is when Small => Count : Integer; end case; Trailer : Boolean; end record; After_Record : Integer; end Package_Record_Variant_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "package_record_variant_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Package_Record_Variant_Tail");
      Record_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Header_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Header");
      Count_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Count");
      Trailer_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Trailer");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Record");
      Small_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Small");
      Header_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Header_Id);
      Count_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Count_Id);
      Trailer_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Trailer_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Record_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package record-variant tail test should emit package and record symbols");
      Assert (Header_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Header_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Header_Info.Parent_Symbol = Record_Id,
              "component before compact variant should be record-local");
      Assert (Count_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Count_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Count_Info.Parent_Symbol = Record_Id,
              "variant component inside compact package record should remain record-local");
      Assert (Trailer_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Trailer_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Trailer_Info.Parent_Symbol = Record_Id
              and then Trailer_Info.Declaration_Column > Count_Info.Declaration_Column,
              "component after compact end case should not leak into the enclosing package");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id
              and then After_Info.Declaration_Column > Trailer_Info.Declaration_Column,
              "declaration after compact end record should resume in the package scope");
      Assert (Small_Id = Editor.Ada_Language_Model.No_Symbol,
              "variant choice inside compact package record must remain metadata");
   end Test_Language_Model_One_Line_Package_Record_Variant_Tail;




   procedure Test_Language_Model_One_Line_Package_Callable_Record_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Callable_Record_Tail is procedure Run is type Local_Rec is record Left_Field : Integer; Right_Field : Boolean; end record; Local_After_Record : Integer; begin null; end Run; After_Run : Integer; end Callable_Record_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "callable_record_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callable_Record_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      Record_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Local_Rec");
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Left_Field");
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Right_Field");
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Local_After_Record");
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Run");
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      Record_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Record_Id);
      Left_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Left_Id);
      Right_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Right_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact callable-record tail test should emit package body and callable symbols");
      Assert (Run_Info.Parent_Symbol = Package_Id,
              "compact callable body should be parented to the package body");
      Assert (Record_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Record_Info.Parent_Symbol = Run_Id,
              "compact record declared inside callable body should remain callable-local");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Left_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Left_Info.Parent_Symbol = Record_Id,
              "first compact record component inside callable body should remain record-local");
      Assert (Right_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component
              and then Right_Info.Parent_Symbol = Record_Id,
              "second compact record component inside callable body should not leak into package scope");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id
              and then Local_After_Info.Declaration_Column > Right_Info.Declaration_Column,
              "callable-local declaration after compact end record should stay inside callable body");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id
              and then After_Run_Info.Declaration_Column > Local_After_Info.Declaration_Column,
              "declaration after compact callable end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Record_Tail;




   procedure Test_Language_Model_One_Line_Package_Callable_Control_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Callable_Control_Tail is procedure Run is begin if Flag then null; end if; Block_Name : declare Local_Block : Integer; begin null; end Block_Name; end Run; After_Run : Integer; end Callable_Control_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "callable_control_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callable_Control_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      Local_Block_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Local_Block");
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Run");
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact callable-control tail test should emit package body and callable symbols");
      Assert (Run_Info.Parent_Symbol = Package_Id,
              "compact callable body with an inner end if should remain package-body local");
      Assert (Local_Block_Id = Editor.Ada_Language_Model.No_Symbol,
              "declarations inside compact statement blocks after end if must not leak as package-level symbols");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declaration after compact callable end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Control_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Named_End_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Callable_Named_End_Tail is function Make return Integer is begin return Result : Integer do null; end return; end Make; After_Make : Integer; procedure Run is begin Block_Name : declare Local_Block : Integer; begin null; end Block_Name; end Run; After_Run : Integer; end Callable_Named_End_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "callable_named_end_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Callable_Named_End_Tail");
      Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Make");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Run");
      Result_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Result");
      Local_Block_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Local_Block");
      After_Make_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Make");
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "After_Run");
      Make_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Make_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      After_Make_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Make_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Make_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact callable named-end test should emit package, function, and procedure symbols");
      Assert (Make_Info.Parent_Symbol = Package_Id
              and then Run_Info.Parent_Symbol = Package_Id,
              "compact callables with inner named ends should remain package-body local");
      Assert (Result_Id = Editor.Ada_Language_Model.No_Symbol
              and then Local_Block_Id = Editor.Ada_Language_Model.No_Symbol,
              "extended-return and named-block locals must not leak as package-level symbols");
      Assert (After_Make_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Make_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Make_Info.Parent_Symbol = Package_Id,
              "declaration after compact function end should resume in package-body scope");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declaration after compact procedure end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Named_End_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Callable_Anonymous_Block_Tail is procedure Run is begin declare Block_Local : Integer; begin null; end; Local_After : Integer; end Run; After_Run : Integer; end One_Line_Callable_Anonymous_Block_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_callable_anonymous_block_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Callable_Anonymous_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Block_Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Block_Local", Run_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      Block_Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Block_Local_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Package_Id,
              "compact callable body should remain package-body local");
      Assert (Block_Local_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Block_Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Block_Local_Info.Parent_Symbol = Run_Id,
              "anonymous declare-block locals should remain callable-local");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "anonymous block end must not resume package scope before callable end");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Local_Callable_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Callable_Anonymous_Block_Local_Callable_Tail is procedure Run is begin declare procedure Local_Run is begin null; end Local_Run; After_Local : Integer; begin null; end; After_Declare : Integer; end Run; After_Run : Integer; end One_Line_Callable_Anonymous_Block_Local_Callable_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_callable_anonymous_block_local_callable_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match
          (Analysis, "One_Line_Callable_Anonymous_Block_Local_Callable_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_Run", Run_Id);
      After_Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Local", Run_Id);
      After_Declare_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Declare", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Run_Id);
      After_Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Local_Id);
      After_Declare_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Declare_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact local-callable anonymous-block test should emit package and callable symbols");
      Assert (Local_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Local_Run_Info.Parent_Symbol = Run_Id,
              "local callable in a compact declare block should remain callable-local");
      Assert (After_Local_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Local_Info.Parent_Symbol = Run_Id,
              "local callable end must not consume the surrounding anonymous declare-block end");
      Assert (After_Declare_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Declare_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Declare_Info.Parent_Symbol = Run_Id,
              "anonymous declare-block end must not close the compact callable body");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after the compact callable body should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Local_Callable_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Control_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Callable_Anonymous_Block_Control_Tail is procedure Run is begin declare Block_Local : Integer; begin if Ready then null; end if; end; Local_After : Integer; end Run; After_Run : Integer; end One_Line_Callable_Anonymous_Block_Control_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_callable_anonymous_block_control_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Callable_Anonymous_Block_Control_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Block_Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Block_Local", Run_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact anonymous-block control test should emit package and callable symbols");
      Assert (Block_Local_Id /= Editor.Ada_Language_Model.No_Symbol,
              "anonymous declare block local should remain visible inside the callable analysis scope");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "end if inside anonymous block must not make the following anonymous end close the callable");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after the callable end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Control_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Bare_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Callable_Bare_Block_Tail is procedure Run is begin begin null; end; Local_After : Integer; end Run; After_Run : Integer; end One_Line_Callable_Bare_Block_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_callable_bare_block_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Callable_Bare_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact bare-block test should emit package and callable symbols");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "anonymous begin/end block inside compact callable must not close the callable body");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after the callable's real end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Bare_Block_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Accept_Without_Do_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Callable_Accept_Without_Do_Tail is procedure Run is begin accept Leave; Local_After : Integer; end Run; After_Run : Integer; end One_Line_Callable_Accept_Without_Do_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_callable_accept_without_do_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Callable_Accept_Without_Do_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted for accept-without-do tail test");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Package_Id,
              "compact callable body should remain package-body local");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "accept without do must not hold anonymous nesting open past its semicolon");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should resume in package-body scope");
   end Test_Language_Model_One_Line_Package_Callable_Accept_Without_Do_Tail;



   procedure Test_Language_Model_One_Line_Nested_Package_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer_Compact is package Inner_Compact is Inner_A : Integer; Inner_B : Boolean; end Inner_Compact; Outer_After : Natural; end Outer_Compact;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_nested_package_tail.ads");
      Outer_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_Compact");
      Inner_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_Compact");
      Inner_A_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_A");
      Inner_B_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_B");
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_After");
      Inner_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_Id);
      Inner_A_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_A_Id);
      Inner_B_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_B_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Outer_Id /= Editor.Ada_Language_Model.No_Symbol,
              "outer compact package should be emitted");
      Assert (Inner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_Info.Kind = Editor.Ada_Language_Model.Symbol_Package
              and then Inner_Info.Parent_Symbol = Outer_Id,
              "nested compact package should be parented to the outer package");
      Assert (Inner_A_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_A_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Inner_A_Info.Parent_Symbol = Inner_Id,
              "first nested compact package declaration should remain inner-package local");
      Assert (Inner_B_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_B_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Inner_B_Info.Parent_Symbol = Inner_Id
              and then Inner_B_Info.Declaration_Column > Inner_A_Info.Declaration_Column,
              "second nested compact package declaration should not be split into the outer scope");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Outer_Id
              and then Outer_After_Info.Declaration_Column > Inner_B_Info.Declaration_Column,
              "declarations after nested compact end should resume in the outer package scope");
   end Test_Language_Model_One_Line_Nested_Package_Tail;



   procedure Test_Language_Model_One_Line_Nested_Package_Callable_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer_Nested_Callable is package body Inner_Nested_Callable is procedure Run is Local_Value : Integer; begin null; end Run; Inner_After : Integer; end Inner_Nested_Callable; Outer_After : Integer; end Outer_Nested_Callable;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_nested_package_callable_tail.adb");
      Outer_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_Nested_Callable");
      Inner_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_Nested_Callable");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Inner_Id);
      Local_Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_Value", Run_Id);
      Inner_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Inner_After", Inner_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Outer_After", Outer_Id);
      Inner_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_Id);
      Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Run_Id);
      Local_Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Value_Id);
      Inner_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_After_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Outer_Id /= Editor.Ada_Language_Model.No_Symbol,
              "outer compact package should be emitted");
      Assert (Inner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
              and then Inner_Info.Parent_Symbol = Outer_Id,
              "compact nested package body should remain outer-package local");
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Run_Info.Parent_Symbol = Inner_Id,
              "callable body inside compact nested package should remain inner-package local");
      Assert (Local_Value_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_Value_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_Value_Info.Parent_Symbol = Run_Id,
              "callable locals should not leak into the nested package or outer package");
      Assert (Inner_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Inner_After_Info.Parent_Symbol = Inner_Id,
              "declarations after the callable end should resume inside the nested package");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Outer_Id,
              "declarations after the nested package end should resume in the outer package");
   end Test_Language_Model_One_Line_Nested_Package_Callable_Tail;



   procedure Test_Language_Model_One_Line_Nested_Package_Bare_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer_Nested_Bare_Block is package body Inner_Nested_Bare_Block is begin begin null; end; Inner_After : Integer; end Inner_Nested_Bare_Block; Outer_After : Integer; end Outer_Nested_Bare_Block;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_nested_package_bare_block_tail.adb");
      Outer_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_Nested_Bare_Block");
      Inner_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inner_Nested_Bare_Block");
      Inner_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Inner_After", Inner_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Outer_After", Outer_Id);
      Inner_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_Id);
      Inner_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inner_After_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Outer_Id /= Editor.Ada_Language_Model.No_Symbol,
              "outer compact package should be emitted");
      Assert (Inner_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
              and then Inner_Info.Parent_Symbol = Outer_Id,
              "compact nested package body should remain outer-package local");
      Assert (Inner_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Inner_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Inner_After_Info.Parent_Symbol = Inner_Id,
              "bare block end inside compact nested package body must not resume outer scope");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Outer_Id,
              "declarations after nested package body end should resume in outer package scope");
   end Test_Language_Model_One_Line_Nested_Package_Bare_Block_Tail;



   procedure Test_Language_Model_One_Line_Selected_Nested_Package_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Outer_Selected_Nested is package body Parent_Unit.Child_Unit is Parent_Unit : declare Block_Local : Integer; begin null; end Parent_Unit; Child_After : Integer; end Parent_Unit.Child_Unit; Outer_After : Integer; end Outer_Selected_Nested;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_selected_nested_package_tail.adb");
      Outer_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Outer_Selected_Nested");
      Child_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Parent_Unit.Child_Unit");
      Child_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Child_After", Child_Id);
      Outer_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Outer_After", Outer_Id);
      Child_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_Id);
      Child_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Child_After_Id);
      Outer_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Outer_After_Id);
   begin
      Assert (Outer_Id /= Editor.Ada_Language_Model.No_Symbol,
              "outer compact package should be emitted");
      Assert (Child_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
              and then Child_Info.Parent_Symbol = Outer_Id,
              "selected compact nested package body should remain outer-package local");
      Assert (Child_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Child_After_Info.Parent_Symbol = Child_Id,
              "matching a selected nested package end must not stop at a same-prefix block end");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Outer_Id,
              "declarations after the selected nested package end should resume in the outer package");
   end Test_Language_Model_One_Line_Selected_Nested_Package_Tail;



   procedure Test_Language_Model_One_Line_Selected_Callable_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Selected_Callable is procedure Parent_Unit.Child_Run is Parent_Unit : declare Block_Local : Integer; begin null; end Parent_Unit; Child_After : Integer; end Parent_Unit.Child_Run; Outer_After : Integer; end One_Line_Selected_Callable;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_selected_callable_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Selected_Callable");
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
              "selected compact callable body should remain package-body local");
      Assert (Child_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Child_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Child_After_Info.Parent_Symbol = Run_Id,
              "inner same-prefix end must not close a selected compact callable body");
      Assert (Outer_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Outer_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Outer_After_Info.Parent_Symbol = Package_Id,
              "declarations after the selected callable end should resume in package-body scope");
   end Test_Language_Model_One_Line_Selected_Callable_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Profile_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body One_Line_Callable_Profile_Tail is procedure Local_Run (Left : Integer; Right : Integer) is Local_Value : Integer; begin null; end Local_Run; After_Run : Integer; end One_Line_Callable_Profile_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "one_line_package_callable_profile_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "One_Line_Callable_Profile_Tail");
      Local_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_Run", Package_Id);
      Left_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Left", Local_Run_Id);
      Right_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Right", Local_Run_Id);
      Local_Value_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_Value", Local_Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Run_Id);
      Local_Value_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Value_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact package body should be emitted");
      Assert (Local_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then Local_Run_Info.Parent_Symbol = Package_Id,
              "compact nested procedure body should be package-body local");
      Assert (Left_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Right_Id /= Editor.Ada_Language_Model.No_Symbol,
              "semicolon-separated profile parameters should remain callable-local");
      Assert (Local_Value_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_Value_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_Value_Info.Parent_Symbol = Local_Run_Id,
              "local declarations after the profiled compact body opener should remain callable-local");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id
              and then After_Run_Info.Declaration_Column > Local_Value_Info.Declaration_Column,
              "declarations after compact callable end should resume in the package body scope");
   end Test_Language_Model_One_Line_Package_Callable_Profile_Tail;




   procedure Test_Language_Model_One_Line_Package_Callable_Labelled_Begin_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Labelled_Begin_Block_Tail is procedure Run is begin Local_Block : begin null; end Local_Block; Local_After : Integer; end Run; After_Run : Integer; end Labelled_Begin_Block_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "labelled_begin_block_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Labelled_Begin_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact callable should parse before labelled begin-block test");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "labelled bare begin-block end must not close compact callable tail early");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should resume in package body scope");
   end Test_Language_Model_One_Line_Package_Callable_Labelled_Begin_Block_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Local_Package_Bare_Block_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Local_Package_Bare_Block_Tail is procedure Run is package body Local_Pkg is begin begin null; end; Local_After : Integer; end Local_Pkg; After_Local : Integer; begin null; end Run; After_Run : Integer; end Local_Package_Bare_Block_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "local_package_bare_block_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Local_Package_Bare_Block_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_Pkg_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_Pkg", Run_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Local_Pkg_Id);
      After_Local_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Local", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_Pkg_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_Pkg_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Local_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Local_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact callable should parse before local package bare-block test");
      Assert (Local_Pkg_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_Pkg_Info.Kind = Editor.Ada_Language_Model.Symbol_Package_Body
              and then Local_Pkg_Info.Parent_Symbol = Run_Id,
              "local compact package body should stay callable-local");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Local_Pkg_Id,
              "bare block inside local package body must not close the enclosing callable tail");
      Assert (After_Local_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Local_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Local_Info.Parent_Symbol = Run_Id,
              "declarations after local package body should resume in callable scope");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should resume in package body scope");
   end Test_Language_Model_One_Line_Package_Callable_Local_Package_Bare_Block_Tail;



   procedure Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Case_Tail
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Anonymous_Block_Case_Tail is procedure Run is begin declare Block_Local : Integer; begin case Block_Local is when others => null; end case; end; Local_After : Integer; end Run; After_Run : Integer; end Anonymous_Block_Case_Tail;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "anonymous_block_case_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Anonymous_Block_Case_Tail");
      Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Run", Package_Id);
      Local_After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Local_After", Run_Id);
      After_Run_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Run", Package_Id);
      Local_After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Local_After_Id);
      After_Run_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Run_Id);
   begin
      Assert (Run_Id /= Editor.Ada_Language_Model.No_Symbol,
              "compact callable should parse before anonymous case-block test");
      Assert (Local_After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Local_After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then Local_After_Info.Parent_Symbol = Run_Id,
              "end case inside anonymous block must not close the compact callable tail early");
      Assert (After_Run_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Run_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Run_Info.Parent_Symbol = Package_Id,
              "declarations after callable end should resume in package body scope");
   end Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Case_Tail;



   procedure Test_Language_Model_Compact_Tail_Rejects_Nameless_Callable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Malformed_Callable_Tail is procedure is Local_Value : Integer; begin null; end; After_Callable : Integer; end Malformed_Callable_Tail;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "malformed_callable_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Malformed_Callable_Tail");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Callable", Package_Id);
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "is");
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package body should still parse around malformed compact callable text");
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "malformed nameless compact callable must not emit Ada keyword as a callable name");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after malformed nameless compact callable text should remain bounded to the package body");
   end Test_Language_Model_Compact_Tail_Rejects_Nameless_Callable;



   procedure Test_Language_Model_Compact_Tail_Rejects_Nameless_Concurrent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Malformed_Concurrent_Tail is protected is procedure Enter; end; After_Concurrent : Integer; end Malformed_Concurrent_Tail;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "malformed_concurrent_tail.ads");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Malformed_Concurrent_Tail");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Concurrent", Package_Id);
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "is");
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package should still parse around malformed compact protected text");
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "malformed nameless compact protected/task text must not emit Ada keyword as a concurrent name");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after malformed nameless compact protected/task text should remain bounded to the package");
   end Test_Language_Model_Compact_Tail_Rejects_Nameless_Concurrent;



   procedure Test_Language_Model_Compact_Tail_Rejects_Reserved_Owner_Words
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Reserved_Owner_Tail is procedure private is Local_Value : Integer; begin null; end; After_Keyword : Integer; end Reserved_Owner_Tail;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "reserved_owner_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Reserved_Owner_Tail");
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "private");
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Keyword", Package_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package body should still parse around reserved-word compact owner text");
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "compact tail parser must not emit Ada reserved words as owner symbols");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after reserved-word compact owner text should remain package-body local");
   end Test_Language_Model_Compact_Tail_Rejects_Reserved_Owner_Words;



   procedure Test_Language_Model_Compact_Tail_Rejects_Invalid_Quoted_Operator_Owner
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Invalid_Quoted_Operator_Tail is function ""bogus"" return Integer is Local_Value : Integer; begin null; end ""bogus""; After_Quoted : Integer; function ""+"" return Integer is (1); end Invalid_Quoted_Operator_Tail;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "invalid_quoted_operator_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Invalid_Quoted_Operator_Tail");
      Bogus_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, """bogus""");
      Valid_Operator_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, """+""", Package_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Quoted", Package_Id);
      Valid_Operator_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Valid_Operator_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package body should parse around invalid quoted compact owner text");
      Assert (Bogus_Id = Editor.Ada_Language_Model.No_Symbol,
              "compact tail parser must not emit arbitrary quoted strings as operator-function owners");
      Assert (Valid_Operator_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Valid_Operator_Info.Kind = Editor.Ada_Language_Model.Symbol_Operator_Function,
              "valid quoted Ada operator functions should remain accepted as compact owners");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after invalid quoted compact owner text should remain package-body local");
   end Test_Language_Model_Compact_Tail_Rejects_Invalid_Quoted_Operator_Owner;



   procedure Test_Language_Model_Compact_Tail_Rejects_Invalid_Identifier_Owner
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Invalid_Identifier_Owner_Tail is procedure Bad__Name is Local_Value : Integer; begin null; end Bad__Name; After_Bad : Integer; package Good_Name is Good_Local : Integer; end Good_Name; end Invalid_Identifier_Owner_Tail;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "invalid_identifier_owner_tail.adb");
      Package_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Invalid_Identifier_Owner_Tail");
      Bad_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Bad__Name");
      Good_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "Good_Name", Package_Id);
      After_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match_In_Scope (Analysis, "After_Bad", Package_Id);
      Good_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Good_Id);
      After_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, After_Id);
   begin
      Assert (Package_Id /= Editor.Ada_Language_Model.No_Symbol,
              "package body should parse around invalid identifier compact owner text");
      Assert (Bad_Id = Editor.Ada_Language_Model.No_Symbol,
              "compact tail parser must not emit invalid Ada identifier owners");
      Assert (After_Id /= Editor.Ada_Language_Model.No_Symbol
              and then After_Info.Kind = Editor.Ada_Language_Model.Symbol_Object
              and then After_Info.Parent_Symbol = Package_Id,
              "declarations after invalid identifier owner text should remain package-body local");
      Assert (Good_Id /= Editor.Ada_Language_Model.No_Symbol
              and then Good_Info.Kind = Editor.Ada_Language_Model.Symbol_Package
              and then Good_Info.Parent_Symbol = Package_Id,
              "valid compact owner identifiers should remain accepted");
   end Test_Language_Model_Compact_Tail_Rejects_Invalid_Identifier_Owner;


   overriding function Name (T : Core_Model_Compact_Tail_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Core_Model.Compact_Tail");
   end Name;

   overriding procedure Register_Tests (T : in out Core_Model_Compact_Tail_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Same_Line_Record_Discriminant_Parent'Access, Name => "language model parser parents same-line record discriminants");
      Add_Test (Routine => Test_Language_Model_Same_Line_Discriminants_Do_Not_Learn_Header'Access, Name => "language model parser does not learn record header identifiers as discriminants");
      Add_Test (Routine => Test_Language_Model_Same_Line_Record_Component_Groups'Access, Name => "language model parser retains multiple same-line record component groups");
      Add_Test (Routine => Test_Language_Model_One_Line_Record_Scope_Declarations'Access, Name => "language model parser retains one-line record scope declarations");
      Add_Test (Routine => Test_Language_Model_Same_Line_Object_Declaration_Groups'Access, Name => "language model parser retains multiple same-line object declaration groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Subtype_Declaration_Groups'Access, Name => "language model parser retains multiple same-line subtype declaration groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Type_Declaration_Groups'Access, Name => "language model parser retains multiple same-line type declaration groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Type_Profile_Semicolons'Access, Name => "language model parser keeps type profile semicolons inside same-line type groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Callable_Declaration_Groups'Access, Name => "language model parser retains multiple same-line callable declaration groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Object_Rename_Groups'Access, Name => "language model parser retains multiple same-line object rename groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Package_Declaration_Groups'Access, Name => "language model parser retains multiple same-line package declaration groups");
      Add_Test (Routine => Test_Language_Model_Same_Line_Concurrent_Declaration_Groups'Access, Name => "language model parser retains multiple same-line concurrent declaration groups");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Scope_Declarations'Access, Name => "language model parser retains one-line package scope declarations");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Private_Tail'Access, Name => "language model parser retains one-line package private tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Record_Tail'Access, Name => "language model parser keeps compact package record tails record-local");
      Add_Test (Routine => Test_Language_Model_Compact_Record_Variant_End_Case_Tail'Access, Name => "language model keeps compact record components after end case");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Record_Variant_Tail'Access, Name => "language model keeps compact package record variants record-local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Record_Tail'Access, Name => "language model parser keeps compact callable-body record tails callable-local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Control_Tail'Access, Name => "language model parser keeps compact callable-body control tails callable-local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Named_End_Tail'Access, Name => "language model parser keeps compact callable named ends callable-local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Tail'Access, Name => "language model parser keeps anonymous block ends callable-local");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Local_Callable_Tail'Access, Name => "language model parser keeps local callable ends inside anonymous compact declare blocks");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Control_Tail'Access, Name => "language model parser keeps control ends inside anonymous blocks in compact callable tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Bare_Block_Tail'Access, Name => "language model parser keeps bare begin/end blocks inside compact callable tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Accept_Without_Do_Tail'Access, Name => "language model parser does not treat accept without do as anonymous nesting");
      Add_Test (Routine => Test_Language_Model_One_Line_Nested_Package_Tail'Access, Name => "language model parser keeps compact nested package tails inner-scope local");
      Add_Test (Routine => Test_Language_Model_One_Line_Nested_Package_Callable_Tail'Access, Name => "language model parser keeps compact nested package callable tails inner-scope local");
      Add_Test (Routine => Test_Language_Model_One_Line_Nested_Package_Bare_Block_Tail'Access, Name => "language model parser keeps bare begin/end blocks inside compact nested package tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Selected_Nested_Package_Tail'Access, Name => "language model parser matches selected compact nested package ends exactly");
      Add_Test (Routine => Test_Language_Model_One_Line_Selected_Callable_Tail'Access, Name => "language model parser matches selected compact callable ends exactly");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Profile_Tail'Access, Name => "language model parser keeps compact profiled callable bodies nested under package scopes");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Labelled_Begin_Block_Tail'Access, Name => "language model parser keeps labelled begin/end blocks inside compact callable tails");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Local_Package_Bare_Block_Tail'Access, Name => "language model parser keeps local compact package bare blocks inside compact callables");
      Add_Test (Routine => Test_Language_Model_One_Line_Package_Callable_Anonymous_Block_Case_Tail'Access, Name => "language model parser keeps end case inside package anonymous compact blocks");
      Add_Test (Routine => Test_Language_Model_Compact_Tail_Rejects_Nameless_Callable'Access, Name => "language model parser rejects nameless compact callable tail owners");
      Add_Test (Routine => Test_Language_Model_Compact_Tail_Rejects_Nameless_Concurrent'Access, Name => "language model parser rejects nameless compact concurrent tail owners");
      Add_Test (Routine => Test_Language_Model_Compact_Tail_Rejects_Reserved_Owner_Words'Access, Name => "language model parser rejects reserved-word compact tail owners");
      Add_Test (Routine => Test_Language_Model_Compact_Tail_Rejects_Invalid_Quoted_Operator_Owner'Access, Name => "language model parser rejects invalid quoted compact operator owners");
      Add_Test (Routine => Test_Language_Model_Compact_Tail_Rejects_Invalid_Identifier_Owner'Access, Name => "language model parser rejects invalid compact owner identifiers");
   end Register_Tests;

end Editor.Syntax_Semantics.Core_Model_Compact_Tail_Tests;
