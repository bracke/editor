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

package body Editor.Syntax_Semantics.Syntax_Tree_Tests is




   procedure Test_Language_Model_Syntax_Tree_Foundation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "with Ada.Text_IO;" & ASCII.LF &
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Ada.Text_IO.Put_Line (Value);" & ASCII.LF &
        "      return;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);
      Root : constant Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.Root (Tree);
      Package_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subprogram_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Begin_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      Assert (Editor.Ada_Language_Model.Has_Syntax_Tree (Analysis),
              "parser must attach a syntax tree to the language analysis");
      Assert (Editor.Ada_Language_Model.Syntax_Tree_Root_Kind (Analysis) =
              Editor.Ada_Syntax_Tree.Node_Compilation_Unit,
              "syntax tree root must be the compilation unit node");
      Assert (Editor.Ada_Language_Model.Syntax_Tree_Node_Count (Analysis) >= 8,
              "syntax tree must retain source-shape nodes beyond the root");

      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Package_Body then
               Package_Node := Info.Id;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body then
               Subprogram_Node := Info.Id;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Begin_Block then
               Begin_Node := Info.Id;
            end if;
         end;
      end loop;

      Assert (Package_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain the package body node");
      Assert (Subprogram_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain the nested subprogram body node");
      Assert (Begin_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain the handled-sequence begin node");
      Assert (Editor.Ada_Syntax_Tree.Node (Tree, Package_Node).Parent = Root,
              "package body must be owned by the compilation-unit root");
      Assert (Editor.Ada_Syntax_Tree.Node (Tree, Subprogram_Node).Parent = Package_Node,
              "subprogram body must be owned by its enclosing package body");
      Assert (Editor.Ada_Syntax_Tree.Node (Tree, Begin_Node).Parent = Subprogram_Node,
              "begin node must be owned by its enclosing subprogram body");
      Assert (Editor.Ada_Syntax_Tree.Child_Count (Tree, Subprogram_Node) >= 3,
              "subprogram body must own begin, statements, and terminator nodes");
      Assert (Editor.Ada_Language_Model.Syntax_Tree_Fingerprint (Analysis) /= 0,
              "syntax tree fingerprint must be deterministic and non-empty");
   end Test_Language_Model_Syntax_Tree_Foundation;




   procedure Test_Language_Model_Syntax_Tree_Alternative_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if Ready then" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      elsif Retry then" & ASCII.LF &
        "         return;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         raise Program_Error;" & ASCII.LF &
        "      end if;" & ASCII.LF &
        "   exception" & ASCII.LF &
        "      when others =>" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);
      If_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Elsif_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Else_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Exception_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Handler_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            case Info.Kind is
               when Editor.Ada_Syntax_Tree.Node_If_Statement =>
                  If_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Elsif_Part =>
                  Elsif_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Else_Part =>
                  Else_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Exception_Section =>
                  Exception_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Exception_Handler =>
                  Handler_Node := Info.Id;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (If_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain if statement nodes");
      Assert (Elsif_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain elsif part nodes");
      Assert (Else_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain else part nodes");
      Assert (Exception_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain exception section nodes");
      Assert (Handler_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain first-class exception handler nodes");
      Assert (Editor.Ada_Syntax_Tree.Node (Tree, Elsif_Node).Parent = If_Node,
              "elsif parts must be owned by the enclosing if statement");
      Assert (Editor.Ada_Syntax_Tree.Node (Tree, Else_Node).Parent = If_Node,
              "else parts must be owned by the enclosing if statement");
      Assert (Editor.Ada_Syntax_Tree.Node (Tree, Handler_Node).Parent = Exception_Node,
              "exception handlers must be owned by the exception section");
      Assert (Editor.Ada_Syntax_Tree.Child_Count (Tree, Else_Node) >= 1,
              "else part must own its nested statement nodes");
   end Test_Language_Model_Syntax_Tree_Alternative_Ownership;




   procedure Test_Language_Model_Syntax_Tree_Control_Statement_Nodes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      <<Again>>" & ASCII.LF &
        "      delay until Next_Tick;" & ASCII.LF &
        "      exit Outer when Done;" & ASCII.LF &
        "      requeue Target with abort;" & ASCII.LF &
        "      goto Again;" & ASCII.LF &
        "      raise Program_Error with Message;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);
      Label_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Delay_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Exit_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Requeue_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Goto_Node    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Raise_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            case Info.Kind is
               when Editor.Ada_Syntax_Tree.Node_Label =>
                  Label_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Delay_Statement =>
                  Delay_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Exit_Statement =>
                  Exit_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Requeue_Statement =>
                  Requeue_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Goto_Statement =>
                  Goto_Node := Info.Id;
               when Editor.Ada_Syntax_Tree.Node_Raise_Statement =>
                  Raise_Node := Info.Id;
               when others =>
                  null;
            end case;
         end;
      end loop;

      Assert (Label_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain statement label nodes");
      Assert (Delay_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain delay statement nodes");
      Assert (Exit_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain exit statement nodes");
      Assert (Requeue_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain requeue statement nodes");
      Assert (Goto_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain goto statement nodes");
      Assert (Raise_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "syntax tree must retain raise statement nodes");
      Assert (Editor.Ada_Syntax_Tree.Child_Count (Tree, Delay_Node) >= 1,
              "delay statements must own their time expression metadata");
      Assert (Editor.Ada_Syntax_Tree.Child_Count (Tree, Exit_Node) >= 2,
              "exit statements must own loop-name and condition metadata");
      Assert (Editor.Ada_Syntax_Tree.Child_Count (Tree, Raise_Node) >= 2,
              "raise-with statements must own exception and message metadata");
   end Test_Language_Model_Syntax_Tree_Control_Statement_Nodes;



   procedure Test_Language_Model_Syntax_Tree_Statement_Details_Are_Direct_Children
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Result := Compute (A => B);" & ASCII.LF &
        "      delay until Next_Tick;" & ASCII.LF &
        "      exit Outer when Done;" & ASCII.LF &
        "      requeue Target with abort;" & ASCII.LF &
        "      goto Done;" & ASCII.LF &
        "      raise Program_Error with Message;" & ASCII.LF &
        "      return Result;" & ASCII.LF &
        "      <<Done>>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      function Is_Executable_Statement
        (Kind : Editor.Ada_Syntax_Tree.Node_Kind) return Boolean is
      begin
         case Kind is
            when Editor.Ada_Syntax_Tree.Node_Return_Statement
               | Editor.Ada_Syntax_Tree.Node_Raise_Statement
               | Editor.Ada_Syntax_Tree.Node_Exit_Statement
               | Editor.Ada_Syntax_Tree.Node_Goto_Statement
               | Editor.Ada_Syntax_Tree.Node_Requeue_Statement
               | Editor.Ada_Syntax_Tree.Node_Delay_Statement
               | Editor.Ada_Syntax_Tree.Node_Abort_Statement
               | Editor.Ada_Syntax_Tree.Node_Terminate_Statement
               | Editor.Ada_Syntax_Tree.Node_Assignment_Statement
               | Editor.Ada_Syntax_Tree.Node_Call_Statement
               | Editor.Ada_Syntax_Tree.Node_Null_Statement =>
               return True;
            when others =>
               return False;
         end case;
      end Is_Executable_Statement;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Is_Executable_Statement (Info.Kind) then
               for Child_Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Info.Id) loop
                  declare
                     Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                       Editor.Ada_Syntax_Tree.Node
                         (Tree,
                          Editor.Ada_Syntax_Tree.Child_At
                            (Tree, Info.Id, Child_Index));
                  begin
                     Assert (Child.Kind /= Info.Kind,
                             "statement detail conversion must not insert duplicate same-kind child statements");
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Test_Language_Model_Syntax_Tree_Statement_Details_Are_Direct_Children;



   procedure Test_Language_Model_Syntax_Tree_Structured_Statement_Detail_Nodes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if Ready then Result := Compute (A => B); goto Done; end if;" & ASCII.LF &
        "      case Mode is when Fast => delay 1.0; when others => requeue Next with abort; end case;" & ASCII.LF &
        "      <<Done>>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Statement_Sequence) >= 2,
              "compact statement actions must be represented as statement-sequence nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Statement_Action) >= 1,
              "assignment/return action detail must be represented as structured nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Statement_Alternative) >= 2,
              "case/alternative actions must be represented as alternative nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Statement_Target) >= 3,
              "goto/requeue/assignment/call targets must be structured target nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Statement_Condition) >= 2,
              "if and delay details must be structured condition nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Assignment_Statement) >= 1,
              "compact assignment actions must become assignment statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Goto_Statement) >= 1,
              "compact goto actions must become goto statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Delay_Statement) >= 1,
              "compact delay alternatives must become delay statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Requeue_Statement) >= 1,
              "compact requeue alternatives must become requeue statement nodes");
   end Test_Language_Model_Syntax_Tree_Structured_Statement_Detail_Nodes;



   procedure Test_Language_Model_Syntax_Tree_Compact_Control_Actions_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin if Ready then return Result; end if; case Mode is when Fast => delay 1.0; end case; while More loop exit when Done; end loop; select accept E; then abort abort Job; end select;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_If_Statement) >= 1,
              "compact embedded if actions must become if statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Case_Statement) >= 1,
              "compact embedded case actions must become case statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Loop_Statement) >= 1,
              "compact embedded loop actions must become loop statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Select_Statement) >= 1,
              "compact embedded select actions must become select statement nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Return_Statement) >= 1,
              "compact embedded if tails must retain return statement actions");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Delay_Statement) >= 1,
              "compact embedded case alternatives must retain delay statement actions");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Exit_Statement) >= 1,
              "compact embedded loop tails must retain exit statement actions");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Abort_Statement) >= 1,
              "compact embedded select tails must retain abort statement actions");
   end Test_Language_Model_Syntax_Tree_Compact_Control_Actions_Are_Structured;



   procedure Test_Language_Model_Syntax_Tree_Select_Then_Abort_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select accept E; then abort abort Job; end select;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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

      function Saw_Mode (Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Statement_Mode
                 and then To_String (Info.Label) = Label
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Mode;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Select_Statement) >= 1,
              "select statement must be retained as a structured node");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Accept_Statement) >= 1,
              "select triggering statement must be retained as a structured accept node");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Abort_Statement) >= 1,
              "select abortable part must be retained as a structured abort node");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Statement_Sequence) >= 2,
              "select triggering and abortable parts must have separate statement sequences");
      Assert (Saw_Mode ("triggering"),
              "select triggering part must be explicitly marked");
      Assert (Saw_Mode ("then abort"),
              "select abortable part must be explicitly marked");
   end Test_Language_Model_Syntax_Tree_Select_Then_Abort_Details;



   procedure Test_Language_Model_Syntax_Tree_Select_Alternatives_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         accept E;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         delay 1.0;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select accept F; or delay 2.0; else null; end select;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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

      function Has_Select_Alternative_Child return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Select_Alternative
                 and then Info.Parent /= Editor.Ada_Syntax_Tree.No_Node
                 and then Editor.Ada_Syntax_Tree.Node (Tree, Info.Parent).Kind
                          = Editor.Ada_Syntax_Tree.Node_Select_Statement
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Has_Select_Alternative_Child;

      function End_Run_Still_Belongs_To_Subprogram return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_End
                 and then To_String (Info.Label) = "end Run;"
                 and then Info.Parent /= Editor.Ada_Syntax_Tree.No_Node
                 and then Editor.Ada_Syntax_Tree.Node (Tree, Info.Parent).Kind
                          = Editor.Ada_Syntax_Tree.Node_Subprogram_Body
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end End_Run_Still_Belongs_To_Subprogram;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Select_Alternative) >= 2,
              "line-level and compact select or-parts must become select-alternative nodes");
      Assert (Has_Select_Alternative_Child,
              "line-level select or alternative must be owned by the enclosing select statement");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Delay_Statement) >= 2,
              "select delay alternatives must retain structured delay statements");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Select_Alternative) >= 3,
              "select else alternatives must be represented as structured select alternatives");
      Assert (End_Run_Still_Belongs_To_Subprogram,
              "same-line compact select alternatives must not leave a stale open select scope");
   end Test_Language_Model_Syntax_Tree_Select_Alternatives_Are_Structured;



   procedure Test_Language_Model_Syntax_Tree_Line_Level_Select_Parts_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         accept E;" & ASCII.LF &
        "      then abort" & ASCII.LF &
        "         abort Job;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         accept F;" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "      select" & ASCII.LF &
        "         accept G;" & ASCII.LF &
        "      or" & ASCII.LF &
        "         terminate;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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

      function Saw_Detail
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Detail;

      function Select_Alternative_Parented_To_Select return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Select_Alternative
                 and then Info.Parent /= Editor.Ada_Syntax_Tree.No_Node
                 and then Editor.Ada_Syntax_Tree.Node (Tree, Info.Parent).Kind
                          = Editor.Ada_Syntax_Tree.Node_Select_Statement
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Select_Alternative_Parented_To_Select;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Select_Alternative) >= 3,
              "line-level then-abort, else, and terminate select parts must be alternatives");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Abort_Statement) >= 1,
              "line-level then-abort body must retain its abort statement");
      Assert (Saw_Detail (Editor.Ada_Syntax_Tree.Node_Statement_Mode, "then abort"),
              "line-level asynchronous select abortable part must be marked");
      Assert (Saw_Detail (Editor.Ada_Syntax_Tree.Node_Statement_Alternative, "else"),
              "line-level selective accept else part must be marked");
      Assert (Saw_Detail (Editor.Ada_Syntax_Tree.Node_Statement_Mode, "terminate"),
              "line-level terminate alternative must be marked");
      Assert (Select_Alternative_Parented_To_Select,
              "line-level select alternatives must be owned by the select statement");
   end Test_Language_Model_Syntax_Tree_Line_Level_Select_Parts_Are_Structured;



   procedure Test_Language_Model_Syntax_Tree_Exception_Handlers_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   exception" & ASCII.LF &
        "      when Constraint_Error | Program_Error =>" & ASCII.LF &
        "         return;" & ASCII.LF &
        "      when others =>" & ASCII.LF &
        "         raise;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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

      function Handler_Parented_To_Exception_Section return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Exception_Handler
                 and then Info.Parent /= Editor.Ada_Syntax_Tree.No_Node
                 and then Editor.Ada_Syntax_Tree.Node (Tree, Info.Parent).Kind
                          = Editor.Ada_Syntax_Tree.Node_Exception_Section
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Handler_Parented_To_Exception_Section;

      function Saw_Handler_Choice (Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Statement_Alternative
                 and then To_String (Info.Label) = Label
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Handler_Choice;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Exception_Handler) = 2,
              "line-level exception choices must become first-class handler nodes");
      Assert (Handler_Parented_To_Exception_Section,
              "exception handlers must be owned by the enclosing exception section");
      Assert (Saw_Handler_Choice ("Constraint_Error | Program_Error"),
              "multi-choice exception handler alternatives must retain their choice list");
      Assert (Saw_Handler_Choice ("others"),
              "others exception handler alternative must retain its choice label");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_When_Alternative) = 0,
              "exception handlers must not be collapsed into case when-alternative nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Return_Statement) >= 1,
              "exception handler bodies must retain structured statements");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Raise_Statement) >= 1,
              "exception handler raise statements must remain structured");
   end Test_Language_Model_Syntax_Tree_Exception_Handlers_Are_Structured;



   procedure Test_Language_Model_Syntax_Tree_Select_Entry_Calls_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      select" & ASCII.LF &
        "         Server.Read (Item);" & ASCII.LF &
        "      else" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end select;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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

      function Entry_Call_Parented_To_Select return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Entry_Call_Statement
                 and then Info.Parent /= Editor.Ada_Syntax_Tree.No_Node
                 and then Editor.Ada_Syntax_Tree.Node (Tree, Info.Parent).Kind
                          = Editor.Ada_Syntax_Tree.Node_Select_Statement
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Entry_Call_Parented_To_Select;

      function Saw_Entry_Call_Mode return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Editor.Ada_Syntax_Tree.Node_Statement_Mode
                 and then To_String (Info.Label) = "entry call"
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Entry_Call_Mode;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Entry_Call_Statement) = 1,
              "select entry-call alternatives must be first-class statement nodes");
      Assert (Entry_Call_Parented_To_Select,
              "select entry-call statements must remain owned by the select statement");
      Assert (Saw_Entry_Call_Mode,
              "entry-call statement nodes must retain explicit mode metadata");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Select_Alternative) = 1,
              "select else part must remain a structured select alternative");
   end Test_Language_Model_Syntax_Tree_Select_Entry_Calls_Are_Structured;



   procedure Test_Language_Model_Syntax_Tree_Metadata_Associations_Have_Named_Value_Children
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Demo is" & ASCII.LF &
        "   pragma Assert (Check => Ready, Message => ""not ready"");" & ASCII.LF &
        "   type Mode is (Fast, Slow)" & ASCII.LF &
        "     with Size => 8, Default_Value => Fast;" & ASCII.LF &
        "   package Vectors is new Ada.Containers.Vectors" & ASCII.LF &
        "     (Index_Type => Natural, Element_Type => Mode);" & ASCII.LF &
        "end Demo;";
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

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Pragma_Name) >= 1,
              "pragma nodes must retain a structured pragma-name child");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Pragma_Argument_Association) >= 1,
              "named pragma arguments must be explicit association nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Aspect_Name, "Size"),
              "aspect associations must retain the aspect name separately");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Aspect_Value, "8"),
              "aspect associations must retain the aspect value separately");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Generic_Actual_Formal, "Index_Type"),
              "generic actual associations must retain the formal name separately");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Generic_Actual_Value, "Natural"),
              "generic actual associations must retain the actual value separately");
   end Test_Language_Model_Syntax_Tree_Metadata_Associations_Have_Named_Value_Children;




   procedure Test_Language_Model_Syntax_Tree_All_Ada_Declaration_Forms_Are_Structured
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "generic" & ASCII.LF &
        "   type Element is private;" & ASCII.LF &
        "   with procedure Visit (X : in out Element);" & ASCII.LF &
        "   Count : Natural := 0;" & ASCII.LF &
        "package Demo is" & ASCII.LF &
        "   type Forward;" & ASCII.LF &
        "   type Root is tagged private;" & ASCII.LF &
        "   type Child is new Root with private;" & ASCII.LF &
        "   subtype Small is Integer range 1 .. 10;" & ASCII.LF &
        "   type Colour is (Red, Green, Blue, 'X');" & ASCII.LF &
        "   Named : constant := 16;" & ASCII.LF &
        "   Deferred : constant Integer;" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "   Alias : Integer renames Named;" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      entry Start (N : Natural);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   task Single_Worker is" & ASCII.LF &
        "      entry Start;" & ASCII.LF &
        "   end Single_Worker;" & ASCII.LF &
        "   protected type Lock is" & ASCII.LF &
        "      procedure Take;" & ASCII.LF &
        "   private" & ASCII.LF &
        "      Busy : Boolean := False;" & ASCII.LF &
        "   end Lock;" & ASCII.LF &
        "   protected Single_Lock is" & ASCII.LF &
        "      procedure Take;" & ASCII.LF &
        "   end Single_Lock;" & ASCII.LF &
        "   type Rec (D : Natural := 1) is record" & ASCII.LF &
        "      Field : Integer;" & ASCII.LF &
        "      case D is" & ASCII.LF &
        "         when 1 => One : Integer;" & ASCII.LF &
        "         when others => Other : Boolean;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   procedure Abstract_Op (X : Integer) is abstract;" & ASCII.LF &
        "   procedure No_Op is null;" & ASCII.LF &
        "   function Inc (X : Integer) return Integer is (X + 1);" & ASCII.LF &
        "   procedure Stub is separate;" & ASCII.LF &
        "   entry Body_Stub is separate;" & ASCII.LF &
        "private" & ASCII.LF &
        "   type Root is tagged null record;" & ASCII.LF &
        "end Demo;" & ASCII.LF &
        "package body Demo is" & ASCII.LF &
        "   entry Serve (Item : Integer) when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Serve;" & ASCII.LF &
        "end Demo;";
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

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Formal_Type_Declaration) >= 1,
              "generic formal type declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration) >= 1,
              "generic formal subprogram declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration) >= 1,
              "generic formal object declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Incomplete_Type_Declaration) >= 1,
              "incomplete type declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Private_Extension_Declaration) >= 1,
              "private extension declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Number_Declaration) >= 1,
              "named-number declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Task_Type_Declaration) >= 1,
              "task type declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration) >= 1,
              "single task declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration) >= 1,
              "protected type declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Single_Protected_Declaration) >= 1,
              "single protected declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Entry_Declaration) >= 1,
              "entry declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Component_Declaration) >= 1,
              "record/protected component declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Discriminant_Specification) >= 1,
              "record discriminant specifications must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Abstract_Subprogram_Declaration) >= 1,
              "abstract subprogram declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Null_Procedure_Declaration) >= 1,
              "null procedure declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Expression_Function_Declaration) >= 1,
              "expression function declarations must be first-class nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Enumeration_Literal_Declaration) >= 4,
              "enumeration literal declarations must be first-class child nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Variant_Part) >= 1,
              "record variant parts must be first-class declaration-grammar nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Variant) >= 2,
              "record variants must be first-class declaration-grammar nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Entry_Body) >= 1,
              "entry bodies must be first-class declaration/body nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Entry_Body_Stub) >= 1,
              "entry body stubs must be first-class body-stub nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Body_Stub) >= 1,
              "body stubs must be first-class declaration nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Private_Part) >= 1,
              "private parts must be retained as declaration-section nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Name, "Named"),
              "declaration forms must retain declaration-name child nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Default, "16"),
              "declaration forms must retain default/value child nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Profile, "X : Integer"),
              "subprogram declarations must retain structured profile child nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Result, "Integer"),
              "function declarations must retain structured result-subtype child nodes");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "abstract"),
              "abstract subprogram declarations must retain mode metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "null procedure"),
              "null procedure declarations must retain mode metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "expression function"),
              "expression function declarations must retain mode metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "task type"),
              "task type declarations must retain a task-type declaration mode");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "single task"),
              "single task declarations must retain a single-task declaration mode");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "protected type"),
              "protected type declarations must retain a protected-type declaration mode");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Mode, "single protected"),
              "single protected declarations must retain a single-protected declaration mode");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Target, "Named"),
              "renaming declarations must retain renamed target metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Statement_Selector, "D"),
              "variant parts must retain selector metadata");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Name, "One"),
              "component declarations inside variants must remain structured declarations");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Declaration_Name, "Other"),
              "component declarations inside others variants must remain structured declarations");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Statement_Condition, "Ready"),
              "entry bodies must retain barrier condition metadata");
   end Test_Language_Model_Syntax_Tree_All_Ada_Declaration_Forms_Are_Structured;


   procedure Test_Language_Model_Syntax_Tree_Grammar_Aware_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      if Ready then" & ASCII.LF &
        "         null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;" & ASCII.LF &
        "else";
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

      function Saw_Label_Fragment
        (Kind     : Editor.Ada_Syntax_Tree.Node_Kind;
         Fragment : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
               Label : constant String := To_String (Info.Label);
            begin
               if Info.Kind = Kind
                 and then Ada.Strings.Fixed.Index (Label, Fragment) /= 0
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label_Fragment;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Missing_End) >= 1,
              "grammar recovery must insert a missing-end recovery node before a mismatched end boundary");
      Assert (Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Missing_End, "end if"),
              "missing if endings must be diagnosed with the expected Ada grammar boundary");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Recovery_Point) >= 1,
              "mismatched end synchronization must leave an explicit recovery point");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Mismatched_End) >= 1,
              "orphan alternatives must be represented as grammar mismatches");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_End) >= 2,
              "recovery must preserve subsequent structured end nodes instead of dropping the rest of the file");
   end Test_Language_Model_Syntax_Tree_Grammar_Aware_Recovery;



   procedure Test_Language_Model_Syntax_Tree_Named_End_Target_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Wrong_Run;" & ASCII.LF &
        "end Demo;";
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

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;

      function Saw_Label_Fragment
        (Kind     : Editor.Ada_Syntax_Tree.Node_Kind;
         Fragment : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
               Label : constant String := To_String (Info.Label);
            begin
               if Info.Kind = Kind
                 and then Ada.Strings.Fixed.Index (Label, Fragment) /= 0
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label_Fragment;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_End) >= 2,
              "named-end recovery must preserve end nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Mismatched_End) >= 1,
              "wrong named end targets must be explicit grammar-recovery diagnostics");
      Assert (Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Mismatched_End, "Wrong_Run"),
              "mismatched-end diagnostic must retain the actual named end target");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Expected_End_Target, "Run"),
              "mismatched-end recovery must retain the expected declaration/body name");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_End_Target, "Wrong_Run"),
              "end nodes and recovery diagnostics must retain the actual named end target");
   end Test_Language_Model_Syntax_Tree_Named_End_Target_Recovery;


   procedure Test_Language_Model_Syntax_Tree_Implicit_Statement_Part_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Demo is" & ASCII.LF &
        "   procedure Run is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Run;" & ASCII.LF &
        "end Demo;";
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

      function Saw_Label_Fragment
        (Kind     : Editor.Ada_Syntax_Tree.Node_Kind;
         Fragment : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
               Label : constant String := To_String (Info.Label);
            begin
               if Info.Kind = Kind
                 and then Ada.Strings.Fixed.Index (Label, Fragment) /= 0
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label_Fragment;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Implicit_End) >= 1,
              "closing a subprogram body must implicitly close its handled statement part");
      Assert (Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Implicit_End, "end Run"),
              "implicit statement-part recovery must retain the enclosing named end boundary");
      Assert (not Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Missing_End, "end block before end Run"),
              "well-formed handled statement parts must not be reported as missing explicit end block nodes");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_End) >= 2,
              "implicit statement-part closure must preserve structured end nodes");
   end Test_Language_Model_Syntax_Tree_Implicit_Statement_Part_Recovery;




   procedure Test_Language_Model_Syntax_Tree_Malformed_Header_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   case Choice" & ASCII.LF &
        "      when A => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   for I in 1 .. 10" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Run;";
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

      function Saw_Label
        (Kind  : Editor.Ada_Syntax_Tree.Node_Kind;
         Label : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            begin
               if Info.Kind = Kind and then To_String (Info.Label) = Label then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label;

      function Saw_Label_Fragment
        (Kind     : Editor.Ada_Syntax_Tree.Node_Kind;
         Fragment : String) return Boolean is
      begin
         for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               Info  : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
               Label : constant String := To_String (Info.Label);
            begin
               if Info.Kind = Kind
                 and then Ada.Strings.Fixed.Index (Label, Fragment) /= 0
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Saw_Label_Fragment;
   begin
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_Recovery_Point) >= 3,
              "malformed Ada headers must produce grammar-aware recovery points");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Expected_Token, "then"),
              "if headers missing then must retain an expected-token diagnostic");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Expected_Token, "is"),
              "case headers missing is must retain an expected-token diagnostic");
      Assert (Saw_Label (Editor.Ada_Syntax_Tree.Node_Expected_Token, "loop"),
              "loop headers missing loop must retain an expected-token diagnostic");
      Assert (Saw_Label_Fragment (Editor.Ada_Syntax_Tree.Node_Recovery_Point, "malformed header"),
              "header recovery diagnostics must be represented structurally rather than as free text only");
      Assert (Count_Kind (Editor.Ada_Syntax_Tree.Node_End) >= 4,
              "header recovery must preserve following structured end nodes");
   end Test_Language_Model_Syntax_Tree_Malformed_Header_Recovery;



   procedure Test_Language_Model_Syntax_Tree_Malformed_Alternative_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Choice is (A, B);" & ASCII.LF &
        "   type Rec (Kind : Choice) is record" & ASCII.LF &
        "      case Kind is" & ASCII.LF &
        "         when A X : Integer;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Kind is" & ASCII.LF &
        "      when A null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Constraint_Error null;" & ASCII.LF &
        "end Run;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Expected_Arrow_Count : Natural := 0;
      Recovery_Count       : Natural := 0;
      Variant_Count        : Natural := 0;
      Case_When_Count      : Natural := 0;
      Handler_Count        : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = "=>"
            then
               Expected_Arrow_Count := Expected_Arrow_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Recovery_Point
              and then Ada.Strings.Fixed.Index (Text, "expected =>") /= 0
            then
               Recovery_Count := Recovery_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Variant then
               Variant_Count := Variant_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_When_Alternative then
               Case_When_Count := Case_When_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Exception_Handler then
               Handler_Count := Handler_Count + 1;
            end if;
         end;
      end loop;

      Assert (Expected_Arrow_Count >= 3,
              "malformed variant, case, and exception alternatives must record expected => tokens");
      Assert (Recovery_Count >= 3,
              "missing-alternative-arrow recovery must be represented by recovery-point nodes");
      Assert (Variant_Count >= 1,
              "variant alternatives must remain structured after missing => recovery");
      Assert (Case_When_Count >= 1,
              "case alternatives must remain structured after missing => recovery");
      Assert (Handler_Count >= 1,
              "exception handlers must remain structured after missing => recovery");
   end Test_Language_Model_Syntax_Tree_Malformed_Alternative_Recovery;



   procedure Test_Language_Model_Syntax_Tree_Malformed_Declaration_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Broken" & ASCII.LF &
        "   type Flags (Kind : Boolean) record" & ASCII.LF &
        "      Limit : constant Integer := 10" & ASCII.LF &
        "      Count : Natural := 0" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Global : Integer := 0" & ASCII.LF &
        "   subtype Small range 1 .. 10" & ASCII.LF &
        "end Broken;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Expected_Is_Count    : Natural := 0;
      Expected_Semi_Count  : Natural := 0;
      Declaration_Recovery : Natural := 0;
      Constant_Count       : Natural := 0;
      Object_Count         : Natural := 0;
      Type_Count           : Natural := 0;
      Subtype_Count        : Natural := 0;
      Assignment_Count     : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = "is"
            then
               Expected_Is_Count := Expected_Is_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = ";"
            then
               Expected_Semi_Count := Expected_Semi_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Recovery_Point
              and then Ada.Strings.Fixed.Index (Text, "malformed declaration") /= 0
            then
               Declaration_Recovery := Declaration_Recovery + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration then
               Constant_Count := Constant_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration then
               Object_Count := Object_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Type_Declaration then
               Type_Count := Type_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Subtype_Declaration then
               Subtype_Count := Subtype_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Assignment_Statement then
               Assignment_Count := Assignment_Count + 1;
            end if;
         end;
      end loop;

      Assert (Expected_Is_Count >= 2,
              "malformed package/type declarations must record missing is tokens");
      Assert (Expected_Semi_Count >= 3,
              "malformed object, constant, component, and subtype declarations must record missing semicolons");
      Assert (Declaration_Recovery >= 4,
              "declaration recovery must use structured recovery-point nodes");
      Assert (Constant_Count >= 1,
              "constant declarations missing semicolons must remain constant declarations");
      Assert (Object_Count >= 1,
              "object declarations missing semicolons must remain object declarations");
      Assert (Type_Count >= 1,
              "type declarations missing is must remain type declarations");
      Assert (Subtype_Count >= 1,
              "subtype declarations missing is/semicolon must remain subtype declarations");
      Assert (Assignment_Count = 0,
              "declarations with colon and := must not degrade into assignment statements during recovery");
   end Test_Language_Model_Syntax_Tree_Malformed_Declaration_Recovery;



   procedure Test_Language_Model_Syntax_Tree_Delimited_List_And_End_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Broken is" & ASCII.LF &
        "   pragma Assert (Ready" & ASCII.LF &
        "   X : Integer;" & ASCII.LF &
        "      with Volatile => True" & ASCII.LF &
        "   for X'Address use To_Address (16#1000#" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Broken";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Expected_Close_Paren : Natural := 0;
      Expected_Semi        : Natural := 0;
      End_Boundary_Recover : Natural := 0;
      Metadata_Recover     : Natural := 0;
      Pragma_Recover       : Natural := 0;
      Pragma_Count         : Natural := 0;
      Aspect_Count         : Natural := 0;
      Representation_Count : Natural := 0;
      End_Count            : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = ")"
            then
               Expected_Close_Paren := Expected_Close_Paren + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = ";"
            then
               Expected_Semi := Expected_Semi + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Recovery_Point
              and then Ada.Strings.Fixed.Index (Text, "malformed end boundary") /= 0
            then
               End_Boundary_Recover := End_Boundary_Recover + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Recovery_Point
              and then Ada.Strings.Fixed.Index (Text, "malformed metadata clause") /= 0
            then
               Metadata_Recover := Metadata_Recover + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Recovery_Point
              and then Ada.Strings.Fixed.Index (Text, "malformed pragma") /= 0
            then
               Pragma_Recover := Pragma_Recover + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Pragma
              or else Info.Kind = Editor.Ada_Syntax_Tree.Node_Pragma_Statement
            then
               Pragma_Count := Pragma_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Specification then
               Aspect_Count := Aspect_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Clause then
               Representation_Count := Representation_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_End then
               End_Count := End_Count + 1;
            end if;
         end;
      end loop;

      Assert (Expected_Close_Paren >= 2,
              "unterminated pragma and representation lists must record missing close parens");
      Assert (Expected_Semi >= 4,
              "unterminated pragmas, metadata clauses, and end boundaries must record missing semicolons");
      Assert (Pragma_Recover >= 1,
              "pragma recovery must be represented as a grammar-aware recovery point");
      Assert (Metadata_Recover >= 2,
              "aspect and representation recovery must be represented as metadata recovery points");
      Assert (End_Boundary_Recover >= 1,
              "end boundary recovery must be represented explicitly");
      Assert (Pragma_Count >= 1,
              "malformed pragmas must keep pragma node structure");
      Assert (Aspect_Count >= 1,
              "malformed aspect clauses must keep aspect node structure");
      Assert (Representation_Count >= 1,
              "malformed representation clauses must keep representation node structure");
      Assert (End_Count >= 1,
              "malformed end boundaries must keep end-node structure");
   end Test_Language_Model_Syntax_Tree_Delimited_List_And_End_Recovery;





   procedure Test_Language_Model_Syntax_Tree_Implicit_Begin_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Value : Integer := 0;" & ASCII.LF &
        "   Value := Value + 1;" & ASCII.LF &
        "end Run;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Implicit_Begin_Count : Natural := 0;
      Expected_Begin_Count : Natural := 0;
      Assignment_Count     : Natural := 0;
      Implicit_End_Count   : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Implicit_Begin then
               Implicit_Begin_Count := Implicit_Begin_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = "begin"
            then
               Expected_Begin_Count := Expected_Begin_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Assignment_Statement then
               Assignment_Count := Assignment_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Implicit_End
              and then Ada.Strings.Fixed.Index (Text, "implicit close of end block") /= 0
            then
               Implicit_End_Count := Implicit_End_Count + 1;
            end if;
         end;
      end loop;

      Assert (Implicit_Begin_Count >= 1,
              "missing begin before handled statements must create an implicit-begin recovery node");
      Assert (Expected_Begin_Count >= 1,
              "implicit-begin recovery must retain an expected begin token detail");
      Assert (Assignment_Count >= 1,
              "statements after recovered begin must retain their structured statement node");
      Assert (Implicit_End_Count >= 1,
              "implicit begin must close implicitly before the enclosing subprogram end");
   end Test_Language_Model_Syntax_Tree_Implicit_Begin_Recovery;



   procedure Test_Language_Model_Syntax_Tree_Subprogram_And_Concurrent_Declaration_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Missing_Semi" & ASCII.LF &
        "procedure Missing_Body_Is begin" & ASCII.LF &
        "task Worker" & ASCII.LF &
        "protected type Lock" & ASCII.LF &
        "task body Runner" & ASCII.LF &
        "protected body Guard";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Expected_Is_Count   : Natural := 0;
      Expected_Semi_Count : Natural := 0;
      Subprogram_Count    : Natural := 0;
      Task_Count          : Natural := 0;
      Protected_Count     : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = "is"
            then
               Expected_Is_Count := Expected_Is_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = ";"
            then
               Expected_Semi_Count := Expected_Semi_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration
              or else Info.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body
            then
               Subprogram_Count := Subprogram_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Single_Task_Declaration
              or else Info.Kind = Editor.Ada_Syntax_Tree.Node_Task_Body
            then
               Task_Count := Task_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Protected_Type_Declaration
              or else Info.Kind = Editor.Ada_Syntax_Tree.Node_Protected_Body
            then
               Protected_Count := Protected_Count + 1;
            end if;
         end;
      end loop;

      Assert (Expected_Is_Count >= 2,
              "malformed subprogram/concurrent bodies must record expected is tokens");
      Assert (Expected_Semi_Count >= 3,
              "malformed subprogram/task/protected declarations must record expected semicolons");
      Assert (Subprogram_Count >= 2,
              "malformed subprogram declarations/bodies must keep their declaration node shapes");
      Assert (Task_Count >= 2,
              "malformed task declarations/bodies must keep their declaration node shapes");
      Assert (Protected_Count >= 2,
              "malformed protected declarations/bodies must keep their declaration node shapes");
   end Test_Language_Model_Syntax_Tree_Subprogram_And_Concurrent_Declaration_Recovery;



   procedure Test_Language_Model_Syntax_Tree_Declaration_After_Begin_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Late : Integer := 0;" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Run;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Unexpected_Declaration_Count : Natural := 0;
      Expected_Declare_Count       : Natural := 0;
      Object_Declaration_Count     : Natural := 0;
      Null_Statement_Count         : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Unexpected_Declaration then
               Unexpected_Declaration_Count := Unexpected_Declaration_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Expected_Token
              and then Text = "declare"
            then
               Expected_Declare_Count := Expected_Declare_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration then
               Object_Declaration_Count := Object_Declaration_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Null_Statement then
               Null_Statement_Count := Null_Statement_Count + 1;
            end if;
         end;
      end loop;

      Assert (Unexpected_Declaration_Count >= 1,
              "declarations after begin must be represented as grammar-aware unexpected-declaration recovery");
      Assert (Expected_Declare_Count >= 1,
              "unexpected declarations in handled statements must suggest a nested declare block");
      Assert (Object_Declaration_Count >= 1,
              "late declarations must retain their structured declaration node");
      Assert (Null_Statement_Count >= 1,
              "statement parsing must continue after late-declaration recovery");
   end Test_Language_Model_Syntax_Tree_Declaration_After_Begin_Recovery;



   procedure Test_Language_Model_Syntax_Tree_EOF_Statement_Part_Recovery
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Implicit_End_Count : Natural := 0;
      Missing_Subprogram_End_Count : Natural := 0;
      Null_Statement_Count : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Implicit_End
              and then Ada.Strings.Fixed.Index (Text, "at end of file") /= 0
            then
               Implicit_End_Count := Implicit_End_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Missing_End
              and then Ada.Strings.Fixed.Index (Text, "end subprogram") /= 0
            then
               Missing_Subprogram_End_Count := Missing_Subprogram_End_Count + 1;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Null_Statement then
               Null_Statement_Count := Null_Statement_Count + 1;
            end if;
         end;
      end loop;

      Assert (Implicit_End_Count >= 1,
              "EOF recovery must implicitly close handled statement parts before diagnosing the owner");
      Assert (Missing_Subprogram_End_Count >= 1,
              "EOF recovery must still report the missing enclosing subprogram end");
      Assert (Null_Statement_Count >= 1,
              "EOF recovery must preserve structured statements before the missing end");
   end Test_Language_Model_Syntax_Tree_EOF_Statement_Part_Recovery;




   procedure Test_Language_Model_Syntax_Tree_Private_Parts_Own_Declarations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package P is" & ASCII.LF &
        "   Public_Value : Integer;" & ASCII.LF &
        "private" & ASCII.LF &
        "   Hidden_Value : Integer;" & ASCII.LF &
        "end P;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source);
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Language_Model.Syntax_Tree (Analysis);

      Private_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Hidden_Under_Private : Boolean := False;
      Public_Under_Private : Boolean := False;
      Saw_Private_Implicit_End : Boolean := False;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
            Text : constant String := To_String (Info.Label);
         begin
            if Info.Kind = Editor.Ada_Syntax_Tree.Node_Private_Part then
               Private_Node := Info.Id;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Implicit_End
              and then Ada.Strings.Fixed.Index (Text, "private part") /= 0
            then
               Saw_Private_Implicit_End := True;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration
              and then Ada.Strings.Fixed.Index (Text, "Hidden_Value") /= 0
            then
               Hidden_Under_Private := Info.Parent = Private_Node;
            elsif Info.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration
              and then Ada.Strings.Fixed.Index (Text, "Public_Value") /= 0
            then
               Public_Under_Private := Info.Parent = Private_Node;
            end if;
         end;
      end loop;

      Assert (Private_Node /= Editor.Ada_Syntax_Tree.No_Node,
              "private section must be retained as a syntax-tree node");
      Assert (Hidden_Under_Private,
              "declarations after private must be owned by the private-part scope");
      Assert (not Public_Under_Private,
              "declarations before private must remain in the visible package part");
      Assert (Saw_Private_Implicit_End,
              "private-part scope must close structurally at the enclosing end");
   end Test_Language_Model_Syntax_Tree_Private_Parts_Own_Declarations;


   procedure Test_Language_Model_Syntax_Tree_Projection_Feeds_Symbols
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Model is" & ASCII.LF &
        "   type Colour is (Red, Green);" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      case Tag is" & ASCII.LF &
        "         when 1 => Field : Integer;" & ASCII.LF &
        "      end case;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Rec use record" & ASCII.LF &
        "      Field at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   package Inst is new Generic_Pkg (Element => Rec);" & ASCII.LF &
        "end Model;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "model.ads");
      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Rec");
      Field_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Field");
      Inst_Id : constant Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Symbol_Resolver.First_Match (Analysis, "Inst");
      Rec_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Rec_Id);
      Field_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Field_Id);
      Inst_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Inst_Id);
   begin
      Assert (Editor.Ada_Language_Model.Has_Syntax_Tree (Analysis),
              "analysis should retain the parser-owned syntax tree");
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "syntax-tree projection should keep the record type visible in the language model");
      Assert (Rec_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type,
              "syntax-tree projection should upgrade record declarations to record-type symbols");
      Assert (Rec_Info.Flags.Has_Representation_Clause,
              "record representation syntax-tree clauses should mark the target symbol");
      Assert (Rec_Info.Flags.Has_Variant_Record_Metadata,
              "variant-part syntax-tree nodes should mark the owning record symbol");
      Assert (Field_Id /= Editor.Ada_Language_Model.No_Symbol,
              "variant component syntax-tree nodes should project into record-component symbols");
      Assert (Field_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Component,
              "variant fields should not remain only syntax-tree metadata");
      Assert (Inst_Id /= Editor.Ada_Language_Model.No_Symbol,
              "instantiation syntax-tree nodes should project into semantic symbols");
      Assert (Inst_Info.Flags.Is_Instantiation
              and then Inst_Info.Flags.Has_Generic_Actual_Part_Metadata,
              "generic actual syntax-tree nodes should mark the instantiation symbol");
   end Test_Language_Model_Syntax_Tree_Projection_Feeds_Symbols;



   procedure Test_Language_Model_Syntax_Tree_Selected_Metadata_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "package Model is" & ASCII.LF &
        "   package Inner is" & ASCII.LF &
        "      type Rec is record" & ASCII.LF &
        "         Field : Integer;" & ASCII.LF &
        "      end record;" & ASCII.LF &
        "   end Inner;" & ASCII.LF &
        "   for Inner.Rec use record" & ASCII.LF &
        "      Field at 0 range 0 .. 31;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Model;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "model.ads");

      function Nested_Rec return Editor.Ada_Language_Model.Symbol_Id is
      begin
         for Index in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
            declare
               Info : constant Editor.Ada_Language_Model.Symbol_Info :=
                 Editor.Ada_Language_Model.Symbol_At (Analysis, Index);
            begin
               if To_String (Info.Name) = "Rec"
                 and then Info.Parent_Symbol /= Editor.Ada_Language_Model.No_Symbol
                 and then To_String
                   (Editor.Ada_Language_Model.Symbol
                      (Analysis, Info.Parent_Symbol).Name) = "Inner"
               then
                  return Info.Id;
               end if;
            end;
         end loop;
         return Editor.Ada_Language_Model.No_Symbol;
      end Nested_Rec;

      Rec_Id : constant Editor.Ada_Language_Model.Symbol_Id := Nested_Rec;
      Rec_Info : constant Editor.Ada_Language_Model.Symbol_Info :=
        Editor.Ada_Language_Model.Symbol (Analysis, Rec_Id);
   begin
      Assert (Rec_Id /= Editor.Ada_Language_Model.No_Symbol,
              "nested record should be retained under the Inner package parent");
      Assert (Rec_Info.Kind = Editor.Ada_Language_Model.Symbol_Record_Type,
              "nested record should remain a record-type symbol");
      Assert (Rec_Info.Flags.Has_Representation_Clause,
              "syntax-tree projection should apply selected representation targets to the nested declaration");
   end Test_Language_Model_Syntax_Tree_Selected_Metadata_Targets;


   overriding function Name (T : Syntax_Tree_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Semantics.Syntax_Tree");
   end Name;

   overriding procedure Register_Tests (T : in out Syntax_Tree_Test_Case) is
      use AUnit.Test_Cases;
      procedure Add_Test
        (Routine : Test_Routine;
         Name    : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine
           (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Foundation'Access, Name => "language model retains parser-owned syntax tree foundation");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Alternative_Ownership'Access, Name => "syntax tree owns if and exception alternatives");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Control_Statement_Nodes'Access, Name => "syntax tree retains control statement nodes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Statement_Details_Are_Direct_Children'Access, Name => "syntax tree attaches statement detail nodes directly");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Structured_Statement_Detail_Nodes'Access, Name => "syntax tree converts statement metadata into structured statement nodes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Compact_Control_Actions_Are_Structured'Access, Name => "syntax tree converts compact embedded control actions into structured nodes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Select_Then_Abort_Details'Access, Name => "syntax tree retains select then-abort triggering and abortable parts");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Select_Alternatives_Are_Structured'Access, Name => "syntax tree retains select or and else alternatives");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Line_Level_Select_Parts_Are_Structured'Access, Name => "syntax tree retains line-level select then-abort else and terminate parts");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Exception_Handlers_Are_Structured'Access, Name => "syntax tree retains first-class exception handler nodes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Select_Entry_Calls_Are_Structured'Access, Name => "syntax tree retains first-class select entry-call statement nodes");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Metadata_Associations_Have_Named_Value_Children'Access, Name => "syntax tree gives metadata associations named value children");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_All_Ada_Declaration_Forms_Are_Structured'Access, Name => "syntax tree expands declaration grammar to all Ada declaration families");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Grammar_Aware_Recovery'Access, Name => "syntax tree performs grammar-aware recovery for malformed Ada units");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Named_End_Target_Recovery'Access, Name => "syntax tree recovers from mismatched named end targets");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Implicit_Statement_Part_Recovery'Access, Name => "syntax tree implicitly closes handled statement parts at enclosing end boundaries");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Malformed_Header_Recovery'Access, Name => "syntax tree records expected tokens for malformed Ada headers");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Malformed_Alternative_Recovery'Access, Name => "syntax tree records expected arrows for malformed Ada alternatives");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Malformed_Declaration_Recovery'Access, Name => "syntax tree records expected tokens for malformed Ada declarations");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Delimited_List_And_End_Recovery'Access, Name => "syntax tree records expected tokens for malformed metadata lists and end boundaries");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Implicit_Begin_Recovery'Access, Name => "syntax tree inserts implicit begin recovery before handled statements");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Subprogram_And_Concurrent_Declaration_Recovery'Access, Name => "syntax tree recovers malformed subprogram and concurrent declaration headers");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Declaration_After_Begin_Recovery'Access, Name => "syntax tree recovers declarations that appear after begin");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_EOF_Statement_Part_Recovery'Access, Name => "syntax tree implicitly closes statement parts at end of file");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Private_Parts_Own_Declarations'Access, Name => "syntax tree private parts own following declarations");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Projection_Feeds_Symbols'Access, Name => "language model projects expanded syntax-tree declarations and metadata into symbols");
      Add_Test (Routine => Test_Language_Model_Syntax_Tree_Selected_Metadata_Targets'Access, Name => "language model projects selected-name metadata targets into nested symbols");
   end Register_Tests;

end Editor.Syntax_Semantics.Syntax_Tree_Tests;
