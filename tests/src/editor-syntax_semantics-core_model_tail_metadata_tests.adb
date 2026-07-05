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

package body Editor.Syntax_Semantics.Core_Model_Tail_Metadata_Tests is

   procedure Test_Language_Model_Private_Extension_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "type Child is new Root with private;" & Character'Val (10) &
        "type Formal is new Root with private;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
         begin
            if S.Flags.Has_Private_Extension_Metadata then
               Seen := True;
            end if;
         end;
      end loop;
      Assert (Seen, "private extension metadata must be retained on owning type declarations");
   end Test_Language_Model_Private_Extension_Metadata;

   procedure Test_Language_Model_Named_Number_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "Max_Size : constant := 1024;" & Character'Val (10) &
        "Scale : constant Float := 1.0;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Named_Number : Boolean := False;
      Typed_Constant_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "max_size" and then S.Flags.Has_Named_Number_Metadata then
               Seen_Named_Number := True;
            elsif N = "scale" and then S.Flags.Has_Named_Number_Metadata then
               Typed_Constant_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Named_Number, "named-number constants must retain declaration-form metadata");
      Assert (not Typed_Constant_Marked, "typed constants must not be marked as named numbers");
   end Test_Language_Model_Named_Number_Metadata;

   procedure Test_Language_Model_Deferred_Constant_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "Deferred : constant Element;" & Character'Val (10) &
        "Initialized : constant Element := Make_Element;" & Character'Val (10) &
        "Named : constant := 10;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Deferred : Boolean := False;
      Initialized_Marked : Boolean := False;
      Named_Number_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "deferred" and then S.Flags.Has_Deferred_Constant_Metadata then
               Seen_Deferred := True;
            elsif N = "initialized" and then S.Flags.Has_Deferred_Constant_Metadata then
               Initialized_Marked := True;
            elsif N = "named" and then S.Flags.Has_Deferred_Constant_Metadata then
               Named_Number_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Deferred, "deferred constants must retain declaration-form metadata");
      Assert (not Initialized_Marked, "initialized typed constants must not be marked as deferred constants");
      Assert (not Named_Number_Marked, "named numbers must not be marked as deferred constants");
   end Test_Language_Model_Deferred_Constant_Metadata;

   procedure Test_Language_Model_Constraint_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "subtype Small_String is String (1 .. 10);" & Character'Val (10) &
        "Table : Matrix (1 .. 10, 1 .. 20);" & Character'Val (10) &
        "type Fixed_Table is array (1 .. 10) of Integer;" & Character'Val (10) &
        "procedure Call (Item : Integer);" & Character'Val (10) &
        "package Inst is new Generic_Package (Integer);" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Subtype : Boolean := False;
      Seen_Object : Boolean := False;
      Seen_Array_Type : Boolean := False;
      Callable_Marked : Boolean := False;
      Instantiation_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "small_string" and then S.Flags.Has_Constraint_Metadata then
               Seen_Subtype := True;
            elsif N = "table" and then S.Flags.Has_Constraint_Metadata then
               Seen_Object := True;
            elsif N = "fixed_table" and then S.Flags.Has_Constraint_Metadata then
               Seen_Array_Type := True;
            elsif N = "call" and then S.Flags.Has_Constraint_Metadata then
               Callable_Marked := True;
            elsif N = "inst" and then S.Flags.Has_Constraint_Metadata then
               Instantiation_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Subtype, "constrained subtypes must retain constraint metadata");
      Assert (Seen_Object, "constrained object subtype indications must retain constraint metadata");
      Assert (Seen_Array_Type, "array index constraints must retain constraint metadata");
      Assert (not Callable_Marked, "callable profiles must not be marked as constraints");
      Assert (not Instantiation_Marked, "generic actual lists must not be marked as constraints");
   end Test_Language_Model_Constraint_Metadata;

   procedure Test_Language_Model_Null_Record_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "type Empty is null record;" & Character'Val (10) &
        "type Child is new Root with null record;" & Character'Val (10) &
        "type Full is record" & Character'Val (10) &
        "   Value : Integer;" & Character'Val (10) &
        "end record;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Empty : Boolean := False;
      Seen_Extension : Boolean := False;
      Full_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "empty" and then S.Flags.Has_Null_Record_Metadata then
               Seen_Empty := True;
            elsif N = "child" and then S.Flags.Has_Null_Record_Metadata then
               Seen_Extension := True;
            elsif N = "full" and then S.Flags.Has_Null_Record_Metadata then
               Full_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Empty, "null record metadata must be retained on compact null records");
      Assert (Seen_Extension, "null record metadata must be retained on null record extensions");
      Assert (not Full_Marked, "ordinary records must not be marked as null records");
   end Test_Language_Model_Null_Record_Metadata;

   procedure Test_Language_Model_Discriminant_Part_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "type Node (Kind : Node_Kind := Leaf) is record" & Character'Val (10) &
        "   Value : Integer;" & Character'Val (10) &
        "end record;" & Character'Val (10) &
        "type Plain is record" & Character'Val (10) &
        "   Value : Integer;" & Character'Val (10) &
        "end record;" & Character'Val (10) &
        "type Accessor is access function (Item : Integer) return Boolean;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Node : Boolean := False;
      Plain_Marked : Boolean := False;
      Accessor_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "node" and then S.Flags.Has_Discriminant_Part_Metadata then
               Seen_Node := True;
            elsif N = "plain" and then S.Flags.Has_Discriminant_Part_Metadata then
               Plain_Marked := True;
            elsif N = "accessor" and then S.Flags.Has_Discriminant_Part_Metadata then
               Accessor_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Node, "discriminant parts must be retained as parent type metadata");
      Assert (not Plain_Marked, "ordinary records must not be marked as discriminated");
      Assert (not Accessor_Marked, "callable profiles must not be treated as discriminant parts");
   end Test_Language_Model_Discriminant_Part_Metadata;

   procedure Test_Language_Model_Body_Stub_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Deferred is separate;" & Character'Val (10) &
        "function Later return Boolean is separate;" & Character'Val (10) &
        "separate (Pkg)" & Character'Val (10) &
        "procedure Deferred is" & Character'Val (10) &
        "begin" & Character'Val (10) &
        "   null;" & Character'Val (10) &
        "end Deferred;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Procedure_Stub : Boolean := False;
      Seen_Function_Stub : Boolean := False;
      Separate_Unit_Marked : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "deferred"
              and then S.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then S.Flags.Has_Body_Stub_Metadata
            then
               Seen_Procedure_Stub := True;
            elsif N = "later"
              and then S.Kind = Editor.Ada_Language_Model.Symbol_Function
              and then S.Flags.Has_Body_Stub_Metadata
            then
               Seen_Function_Stub := True;
            elsif S.Kind = Editor.Ada_Language_Model.Symbol_Separate_Body
              and then S.Flags.Has_Body_Stub_Metadata
            then
               Separate_Unit_Marked := True;
            end if;
         end;
      end loop;

      Assert (Seen_Procedure_Stub, "procedure body stubs must retain body-stub metadata");
      Assert (Seen_Function_Stub, "function body stubs must retain body-stub metadata");
      Assert (not Separate_Unit_Marked, "separate subunits must not be treated as body stubs");
   end Test_Language_Model_Body_Stub_Metadata;

   procedure Test_Language_Model_Overriding_Indicator_Metadata (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & Character'Val (10) &
        "   overriding procedure Reset;" & Character'Val (10) &
        "   not overriding function Ready return Boolean;" & Character'Val (10) &
        "end Demo;" & Character'Val (10);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Seen_Overriding : Boolean := False;
      Seen_Not_Overriding : Boolean := False;
   begin
      Analysis := Editor.Ada_Declaration_Parser.Parse (Source);
      for I in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
         declare
            S : constant Editor.Ada_Language_Model.Symbol_Info :=
              Editor.Ada_Language_Model.Symbol_At (Analysis, I);
            N : constant String := To_String (S.Normalized_Name);
         begin
            if N = "reset"
              and then S.Kind = Editor.Ada_Language_Model.Symbol_Procedure
              and then S.Flags.Is_Overriding
              and then not S.Flags.Is_Not_Overriding
            then
               Seen_Overriding := True;
            elsif N = "ready"
              and then S.Kind = Editor.Ada_Language_Model.Symbol_Function
              and then S.Flags.Is_Not_Overriding
              and then not S.Flags.Is_Overriding
            then
               Seen_Not_Overriding := True;
            end if;
         end;
      end loop;

      Assert (Seen_Overriding, "overriding indicators must be retained on callable symbols");
      Assert (Seen_Not_Overriding, "not overriding indicators must be retained on callable symbols");
   end Test_Language_Model_Overriding_Indicator_Metadata;

   procedure Test_Syntax_Semantics_Recovered_Metadata_Suppressed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Map : Editor.Syntax_Semantics.Semantic_Map;
      Source_Span : constant Editor.Ada_Language_Model.Source_Range :=
        (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 1);
      Real_Type : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Real_Type := Editor.Ada_Language_Model.Add_Symbol
        (Analysis,
         Name => "Real_Type",
         Kind => Editor.Ada_Language_Model.Symbol_Type,
         Source_Span => Source_Span);

      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis,
         Kind => Editor.Ada_Language_Model.Binding_Qualified_Expression_Target,
         Name => "Broken",
         Expression_Text => "Broken.'(1)",
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis,
         Kind => Editor.Ada_Language_Model.Binding_Allocator,
         Name => "Broken_Allocator",
         Expression_Text => "new Broken_Allocator.",
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Visibility_Clause
        (Analysis,
         Kind => Editor.Ada_Language_Model.Visibility_Use_Package_Clause,
         Name => "Broken.Package.",
         Source_Span => Source_Span);
      Editor.Ada_Language_Model.Add_Executable_Binding
        (Analysis,
         Kind => Editor.Ada_Language_Model.Binding_Qualified_Expression_Target,
         Name => "Real_Type",
         Expression_Text => "Real_Type'(1)",
         Target_Symbol => Real_Type,
         Source_Span => Source_Span);

      Editor.Syntax_Semantics.Build_Map_From_Analysis (Map, Analysis);

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Broken") =
           Editor.Syntax.Identifier,
         "recovered incomplete qualified-expression prefixes must not seed type colouring");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Broken_Allocator") =
           Editor.Syntax.Identifier,
         "recovered incomplete allocator subtype marks must not seed type colouring");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Package") =
           Editor.Syntax.Identifier,
         "partial recovered visibility names must not contribute package leaf colouring");
      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier (Map, "Real_Type") =
           Editor.Syntax.Type_Identifier,
         "resolved executable bindings must still retain concrete semantic colouring");
   end Test_Syntax_Semantics_Recovered_Metadata_Suppressed;

   overriding function Name (T : CoreModelTailMetadata_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Core-Model-Tail-Metadata");
   end Name;

   overriding procedure Register_Tests (T : in out CoreModelTailMetadata_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Private_Extension_Metadata'Access, Name => "language model retains private extension metadata");
      Add_Test (Routine => Test_Language_Model_Named_Number_Metadata'Access, Name => "language model retains named number metadata");
      Add_Test (Routine => Test_Language_Model_Deferred_Constant_Metadata'Access, Name => "language model retains deferred constant metadata");
      Add_Test (Routine => Test_Language_Model_Constraint_Metadata'Access, Name => "language model retains constraint metadata");
      Add_Test (Routine => Test_Language_Model_Null_Record_Metadata'Access, Name => "language model retains null record metadata");
      Add_Test (Routine => Test_Language_Model_Discriminant_Part_Metadata'Access, Name => "language model retains discriminant part metadata");
      Add_Test (Routine => Test_Language_Model_Body_Stub_Metadata'Access, Name => "language model retains body stub metadata");
      Add_Test (Routine => Test_Language_Model_Overriding_Indicator_Metadata'Access, Name => "language model retains overriding indicator metadata");
      Add_Test (Routine => Test_Syntax_Semantics_Recovered_Metadata_Suppressed'Access, Name => "semantic colouring suppresses recovered partial metadata names");
   end Register_Tests;

end Editor.Syntax_Semantics.Core_Model_Tail_Metadata_Tests;
