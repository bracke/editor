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

package body Editor.Syntax_Semantics.Executable_Bindings_Tests is

   procedure Test_Language_Model_Statement_Awareness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      LF : constant Character := Character'Val (10);
      Source : constant String :=
        "procedure Run is" & LF &
        "begin" & LF &
        "   if Ready then" & LF &
        "      <<Start>> Work;" & LF &
        "   elsif Almost_Ready then" & LF &
        "      Prepare;" & LF &
        "   else" & LF &
        "      Idle;" & LF &
        "   end if;" & LF &
        "   case Mode is" & LF &
        "      when A => null;" & LF &
        "      when others => raise Program_Error;" & LF &
        "   end case;" & LF &
        "   while Ready loop" & LF &
        "      exit when Done;" & LF &
        "   end loop;" & LF &
        "   for I in 1 .. 3 loop" & LF &
        "      <<Again>> Value := I;" & LF &
        "   end loop;" & LF &
        "   select" & LF &
        "      accept Stop;" & LF &
        "   or" & LF &
        "      terminate;" & LF &
        "   end select;" & LF &
        "   declare" & LF &
        "      Local : Natural := 0;" & LF &
        "   begin" & LF &
        "      return;" & LF &
        "   exception" & LF &
        "      when Constraint_Error => null;" & LF &
        "   end;" & LF &
        "end Run;";
      Record_Source : constant String :=
        "type T (K : Kind) is record" & LF &
        "   case K is" & LF &
        "      when A => X : Integer;" & LF &
        "      when others => null;" & LF &
        "   end case;" & LF &
        "end record;";
      Async_Source : constant String :=
        "procedure Async is" & LF &
        "begin" & LF &
        "   select" & LF &
        "      Start_Work;" & LF &
        "   then abort" & LF &
        "      null;" & LF &
        "   end select;" & LF &
        "end Async;";
      Async_Same_Line_Source : constant String :=
        "procedure Async_Same_Line is" & LF &
        "begin" & LF &
        "   select" & LF &
        "      Start_Work;" & LF &
        "   then abort Cleanup (Reason => Timeout);" & LF &
        "   end select;" & LF &
        "end Async_Same_Line;";
      Extended_Return_Source : constant String :=
        "function Make return Item is" & LF &
        "begin" & LF &
        "   return Result : Item do" & LF &
        "      Initialize (Result);" & LF &
        "   end return;" & LF &
        "end Make;";
      Initialized_Return_Source : constant String :=
        "function Make return Item is" & LF &
        "begin" & LF &
        "   return Result : Item := Default_Item;" & LF &
        "end Make;";
      Return_Expression_Source : constant String :=
        "function Count return Natural is" & LF &
        "begin" & LF &
        "   return Current + 1;" & LF &
        "end Count;";
      Delay_Source : constant String :=
        "procedure Waits is" & LF &
        "begin" & LF &
        "   delay 1.0;" & LF &
        "   delay until Deadline;" & LF &
        "end Waits;";
      Delay_Alternative_Source : constant String :=
        "procedure Selective is" & LF &
        "begin" & LF &
        "   select" & LF &
        "      accept Stop;" & LF &
        "   or delay 1.0;" & LF &
        "   or delay until Deadline;" & LF &
        "      null;" & LF &
        "   end select;" & LF &
        "end Selective;";
      Accept_Alternative_Source : constant String :=
        "task body Selective_Worker is" & LF &
        "begin" & LF &
        "   select" & LF &
        "      accept First;" & LF &
        "   or accept Second (Item : Natural) do" & LF &
        "      null;" & LF &
        "   end Second;" & LF &
        "   or accept Family (Index) (Item : Payload);" & LF &
        "   or" & LF &
        "      terminate;" & LF &
        "   end select;" & LF &
        "end Selective_Worker;";
      Conditional_Entry_Call_Source : constant String :=
        "procedure Conditional_Entry_Call is" & LF &
        "begin" & LF &
        "   select Server.Request (Item => Payload);" & LF &
        "   else" & LF &
        "      null;" & LF &
        "   end select;" & LF &
        "end Conditional_Entry_Call;";
      Conditional_Entry_Call_Else_Source : constant String :=
        "procedure Conditional_Entry_Call_Else is" & LF &
        "begin" & LF &
        "   select Server.Request (Item => Payload); else Recover (Reason => Timeout); end select;" & LF &
        "   select Server.Request; else null; end select;" & LF &
        "   select Server.Request; else Status := Timeout; end select;" & LF &
        "   select Server.Request; else return; end select;" & LF &
        "   select Server.Request; else raise Program_Error with ""timeout""; end select;" & LF &
        "   select Server.Request; else Instruction'(Opcode => 16#90#); end select;" & LF &
        "   select Server.Request; else exit Outer when Done; end select;" & LF &
        "   select Server.Request; else goto Retry; end select;" & LF &
        "   select Server.Request; else delay until Deadline; end select;" & LF &
        "   select Server.Request; else delay 1.0; end select;" & LF &
        "   select Server.Request; else requeue Target with abort; end select;" & LF &
        "   select Server.Request; else abort Workers; end select;" & LF &
        "   select Server.Request; else pragma Assert (Ready); end select;" & LF &
        "end Conditional_Entry_Call_Else;";
      Timed_Entry_Call_Source : constant String :=
        "procedure Timed_Entry_Call is" & LF &
        "begin" & LF &
        "   select Server.Request (Item => Payload); or delay until Deadline; null; end select;" & LF &
        "   select Server.Other; or delay 1.0; Recover (Reason => Timeout); end select;" & LF &
        "   select Server.Third; or delay 1.0; Status := Timeout; end select;" & LF &
        "   select Server.Fourth; or delay until Deadline; return Value; end select;" & LF &
        "   select Server.Fifth; or delay until Deadline; raise Program_Error with ""timeout""; end select;" & LF &
        "   select Server.Sixth; or delay 1.0; Instruction'(Opcode => 16#90#); end select;" & LF &
        "   select Server.Seventh; or delay 1.0; exit Outer when Done; end select;" & LF &
        "   select Server.Eighth; or delay until Deadline; goto Retry; end select;" & LF &
        "   select Server.Ninth; or delay 1.0; delay until Later; end select;" & LF &
        "   select Server.Tenth; or delay until Deadline; requeue Target with abort; end select;" & LF &
        "   select Server.Eleventh; or delay 1.0; abort Workers; end select;" & LF &
        "   select Server.Twelfth; or delay until Deadline; pragma Assert (Ready); end select;" & LF &
        "   select Server.Thirteenth; or delay 1.0; Router.Target (Slot) (Name => Payload); end select;" & LF &
        "end Timed_Entry_Call;";
      Compact_Async_Select_Source : constant String :=
        "procedure Compact_Async_Select is" & LF &
        "begin" & LF &
        "   select Start_Work; then abort Cleanup (Reason => Timeout); end select;" & LF &
        "end Compact_Async_Select;";
      Compact_Terminate_Select_Source : constant String :=
        "task body Compact_Terminate_Select is" & LF &
        "begin" & LF &
        "   select accept Stop; or terminate; end select;" & LF &
        "end Compact_Terminate_Select;";
      Accept_Body_Source : constant String :=
        "task body Worker is" & LF &
        "begin" & LF &
        "   accept Stop do" & LF &
        "      null;" & LF &
        "   end Stop;" & LF &
        "   accept Flush (Count : Natural) do" & LF &
        "      null;" & LF &
        "   end Flush;" & LF &
        "   accept Family (Index) do" & LF &
        "      null;" & LF &
        "   end Family;" & LF &
        "   accept Update (Slot) (Item : Payload) do" & LF &
        "      null;" & LF &
        "   end Update;" & LF &
        "end Worker;";
      Qualified_Simple_Source : constant String :=
        "procedure Qualified is" & LF &
        "begin" & LF &
        "   raise Program_Error with ""bad state"";" & LF &
        "   requeue Target with abort;" & LF &
        "end Qualified;";
      Raise_Form_Source : constant String :=
        "procedure Raises is" & LF &
        "begin" & LF &
        "   raise;" & LF &
        "   raise Constraint_Error;" & LF &
        "   raise Program_Error with ""bad state"";" & LF &
        "exception" & LF &
        "   when others => raise;" & LF &
        "end Raises;";
      Goto_Target_Source : constant String :=
        "procedure Jumps is" & LF &
        "begin" & LF &
        "   goto Retry;" & LF &
        "   <<Retry>> null;" & LF &
        "   case Mode is" & LF &
        "      when A => goto Done;" & LF &
        "   end case;" & LF &
        "   <<Done>> null;" & LF &
        "end Jumps;";
      Requeue_Target_Source : constant String :=
        "procedure Requeues is" & LF &
        "begin" & LF &
        "   requeue Server.Request;" & LF &
        "   requeue Queue.Entry_Family (Index) with abort;" & LF &
        "   case Mode is" & LF &
        "      when A => requeue Router.Target (Slot) with abort;" & LF &
        "   end case;" & LF &
        "end Requeues;";
      Code_Statement_Source : constant String :=
        "procedure Machine is" & LF &
        "begin" & LF &
        "   Instruction'(Opcode => 16#90#);" & LF &
        "end Machine;";
      Pragma_Statement_Source : constant String :=
        "procedure Pragmas is" & LF &
        "begin" & LF &
        "   pragma Assert (Ready);" & LF &
        "   pragma Inspection_Point;" & LF &
        "   case Mode is" & LF &
        "      when A => pragma Assert (Ready);" & LF &
        "   end case;" & LF &
        "end Pragmas;";
      Call_Association_Source : constant String :=
        "procedure Calls is" & LF &
        "begin" & LF &
        "   Configure (Name => Default_Name, Count => 2);" & LF &
        "   Flush (Buffer);" & LF &
        "end Calls;";
      Selected_Call_Source : constant String :=
        "procedure Selected_Calls is" & LF &
        "begin" & LF &
        "   Console.Flush;" & LF &
        "   Worker.Start (Priority => High);" & LF &
        "   Callback.all;" & LF &
        "   Handler.all (Item);" & LF &
        "   Buffer_Type'Write (Stream, Buffer);" & LF &
        "   Buffer_Type'Read (Stream, Buffer);" & LF &
        "end Selected_Calls;";
      Entry_Family_Call_Source : constant String :=
        "procedure Entry_Family_Calls is" & LF &
        "begin" & LF &
        "   Server.Family (Index) (Item);" & LF &
        "   case Mode is" & LF &
        "      when A => Router.Target (Slot) (Payload);" & LF &
        "   end case;" & LF &
        "end Entry_Family_Calls;";
      Assignment_Target_Source : constant String :=
        "procedure Assignments is" & LF &
        "begin" & LF &
        "   Obj.Field := 1;" & LF &
        "   Items (Index) := Value;" & LF &
        "   Buffer (First .. Last) := Source;" & LF &
        "   Access_Obj.all := Value;" & LF &
        "   case Mode is" & LF &
        "      when A => Obj.Other := 2;" & LF &
        "      when B => Data (Slot) := Item;" & LF &
        "      when C => Window (Low .. High) := Slice;" & LF &
        "      when D => Access_Array (Index).all := Value;" & LF &
        "   end case;" & LF &
        "end Assignments;";
      Compact_Source : constant String :=
        "procedure Compact is" & LF &
        "begin" & LF &
        "   if Ready then null; end if;" & LF &
        "   while Ready loop null; end loop;" & LF &
        "   select accept Stop; else null; end select;" & LF &
        "end Compact;";
      Compact_Then_Action_Source : constant String :=
        "procedure Compact_Then is" & LF &
        "begin" & LF &
        "   if Ready then Worker.Deliver (Name => Item); end if;" & LF &
        "   if Failed then Status := Error; end if;" & LF &
        "   if Done then return Value; end if;" & LF &
        "   if Bad then raise Program_Error with ""bad""; end if;" & LF &
        "end Compact_Then;";
      Compact_Elsif_Action_Source : constant String :=
        "procedure Compact_Elsif is" & LF &
        "begin" & LF &
        "   if Ready then null; elsif Retry then Worker.Deliver (Name => Item); end if;" & LF &
        "   if Failed then null; elsif Recovering then Status := Error; end if;" & LF &
        "   if Done then null; elsif More then return Value; end if;" & LF &
        "   if Bad then null; elsif Worse then raise Program_Error with ""bad""; end if;" & LF &
        "end Compact_Elsif;";
      Compact_Else_Action_Source : constant String :=
        "procedure Compact_Else is" & LF &
        "begin" & LF &
        "   if Ready then null; else Worker.Deliver (Name => Item); end if;" & LF &
        "   if Failed then null; else Status := Error; end if;" & LF &
        "   if Done then null; else return Value; end if;" & LF &
        "   if Bad then null; else raise Program_Error with ""bad""; end if;" & LF &
        "end Compact_Else;";
      Compact_Loop_Action_Source : constant String :=
        "procedure Compact_Loops is" & LF &
        "begin" & LF &
        "   while Ready loop Worker.Deliver (Name => Item); end loop;" & LF &
        "   for I in 1 .. 10 loop Status := I; end loop;" & LF &
        "   loop return Value; end loop;" & LF &
        "   while Bad loop raise Program_Error with ""bad""; end loop;" & LF &
        "end Compact_Loops;";
      Compact_Case_Action_Source : constant String :=
        "procedure Compact_Case is" & LF &
        "begin" & LF &
        "   case Mode is when A => Worker.Deliver (Name => Item);" &
        " when B => Status := Error;" &
        " when C => return Value;" &
        " when others => null; end case;" & LF &
        "end Compact_Case;";
      Compact_Exception_Action_Source : constant String :=
        "procedure Compact_Exception is" & LF &
        "begin" & LF &
        "   Work;" & LF &
        "exception when Constraint_Error => null;" &
        " when Program_Error => Recover (Reason => Bad);" &
        " when others => raise;" & LF &
        "end Compact_Exception;";
      Compact_Begin_Action_Source : constant String :=
        "procedure Compact_Begin is" & LF &
        "begin Worker.Deliver (Name => Item); end Compact_Begin;" & LF &
        "procedure Compact_Begin_Assign is" & LF &
        "begin Status := Ready; end Compact_Begin_Assign;" & LF &
        "procedure Compact_Begin_Return is" & LF &
        "begin return Value; end Compact_Begin_Return;" & LF &
        "procedure Compact_Begin_Raise is" & LF &
        "begin raise Program_Error with ""bad""; end Compact_Begin_Raise;";
      Compact_Declare_Action_Source : constant String :=
        "procedure Compact_Declare is" & LF &
        "begin" & LF &
        "   declare Local : Natural := 0; begin Worker.Deliver (Name => Item); end;" & LF &
        "   declare Local : Natural := 0; begin Status := Ready; end;" & LF &
        "   declare Local : Natural := 0; begin return Value; end;" & LF &
        "   declare Local : Natural := 0; begin raise Program_Error with ""bad""; end;" & LF &
        "end Compact_Declare;";
      Alternative_Action_Source : constant String :=
        "procedure Alternative_Actions is" & LF &
        "begin" & LF &
        "   case Mode is" & LF &
        "      when A => Value := 1;" & LF &
        "      when B => Deliver (Item);" & LF &
        "      when B2 => Worker.Deliver (Name => Item);" & LF &
        "      when B3 => Instruction'(Opcode => 16#90#);" & LF &
        "      when B4 => Callback.all (Item);" & LF &
        "      when C => return;" & LF &
        "      when C2 => return Value + 1;" & LF &
        "      when D => exit Outer when Done;" & LF &
        "      when E => goto Retry;" & LF &
        "      when F => delay until Deadline;" & LF &
        "      when G => requeue Target with abort;" & LF &
        "      when H => abort Workers;" & LF &
        "      when others => raise Program_Error with ""bad"";" & LF &
        "   end case;" & LF &
        "end Alternative_Actions;";
      Abort_Target_Source : constant String :=
        "procedure Aborts is" & LF &
        "begin" & LF &
        "   abort Worker;" & LF &
        "   abort Manager.Worker;" & LF &
        "   abort A, B, Group.Worker;" & LF &
        "   case Mode is" & LF &
        "      when A => abort Pool.First, Pool.Second;" & LF &
        "   end case;" & LF &
        "end Aborts;";
      Multiple_Label_Source : constant String :=
        "procedure Labels is" & LF &
        "begin" & LF &
        "   <<Outer>>" & LF &
        "   <<Retry>> <<Again>> Work;" & LF &
        "end Labels;";
      Named_Source : constant String :=
        "procedure Named is" & LF &
        "begin" & LF &
        "   Outer : for J in 1 .. 2 loop" & LF &
        "      null;" & LF &
        "   end loop Outer;" & LF &
        "   Plain : loop" & LF &
        "      exit Plain;" & LF &
        "   end loop Plain;" & LF &
        "   Blocker : declare" & LF &
        "      Local : Natural := 0;" & LF &
        "   begin" & LF &
        "      null;" & LF &
        "   end Blocker;" & LF &
        "end Named;";
      For_Form_Source : constant String :=
        "procedure For_Forms is" & LF &
        "begin" & LF &
        "   for I in 1 .. 10 loop" & LF &
        "      null;" & LF &
        "   end loop;" & LF &
        "   for J in reverse 1 .. 10 loop" & LF &
        "      null;" & LF &
        "   end loop;" & LF &
        "   for Element of Items loop" & LF &
        "      Visit (Element);" & LF &
        "   end loop;" & LF &
        "end For_Forms;";
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "statements.adb");
      Record_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Record_Source, "record.ads");
      Async_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Async_Source, "async.adb");
      Async_Same_Line_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Async_Same_Line_Source, "async_same_line.adb");
      Extended_Return_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Extended_Return_Source, "extended_return.adb");
      Initialized_Return_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Initialized_Return_Source, "initialized_return.adb");
      Return_Expression_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Return_Expression_Source, "return_expression.adb");
      Delay_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Delay_Source, "delays.adb");
      Delay_Alternative_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Delay_Alternative_Source, "delay_alternatives.adb");
      Accept_Alternative_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Accept_Alternative_Source, "accept_alternatives.adb");
      Conditional_Entry_Call_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Conditional_Entry_Call_Source, "conditional_entry_call.adb");
      Conditional_Entry_Call_Else_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Conditional_Entry_Call_Else_Source, "conditional_entry_call_else.adb");
      Timed_Entry_Call_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Timed_Entry_Call_Source, "timed_entry_call.adb");
      Compact_Async_Select_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Async_Select_Source, "compact_async_select.adb");
      Compact_Terminate_Select_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Terminate_Select_Source, "compact_terminate_select.adb");
      Accept_Body_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Accept_Body_Source, "accept_body.adb");
      Qualified_Simple_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Qualified_Simple_Source, "qualified_simple.adb");
      Raise_Form_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Raise_Form_Source, "raise_forms.adb");
      Goto_Target_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Goto_Target_Source, "goto_targets.adb");
      Requeue_Target_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Requeue_Target_Source, "requeue_targets.adb");
      Code_Statement_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Code_Statement_Source, "machine_code_statement.adb");
      Pragma_Statement_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Pragma_Statement_Source, "pragma_statements.adb");
      Call_Association_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Call_Association_Source, "call_associations.adb");
      Selected_Call_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Selected_Call_Source, "selected_calls.adb");
      Entry_Family_Call_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Entry_Family_Call_Source, "entry_family_calls.adb");
      Assignment_Target_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Assignment_Target_Source, "assignment_targets.adb");
      Compact_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Source, "compact_statements.adb");
      Compact_Then_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Then_Action_Source, "compact_then_actions.adb");
      Compact_Elsif_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Elsif_Action_Source, "compact_elsif_actions.adb");
      Compact_Else_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Else_Action_Source, "compact_else_actions.adb");
      Compact_Loop_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Loop_Action_Source, "compact_loop_actions.adb");
      Compact_Case_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Case_Action_Source, "compact_case_actions.adb");
      Compact_Exception_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Exception_Action_Source, "compact_exception_actions.adb");
      Compact_Begin_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Begin_Action_Source, "compact_begin_actions.adb");
      Compact_Declare_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Compact_Declare_Action_Source, "compact_declare_actions.adb");
      Alternative_Action_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Alternative_Action_Source, "alternative_actions.adb");
      Abort_Target_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Abort_Target_Source, "abort_targets.adb");
      Multiple_Label_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Multiple_Label_Source, "multiple_labels.adb");
      Named_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Named_Source, "named.adb");
      For_Form_Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (For_Form_Source, "for_forms.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Has_Statement_Awareness (Analysis),
         "parser must expose executable statement awareness in the language model");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_If) = 1,
         "if statements are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Elsif) = 1,
         "elsif alternatives are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Else) = 1,
         "else alternatives are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Case) = 1,
         "case statements are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_End_If) = 1,
         "end if terminators are retained as structured statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_End_Case) = 1,
         "end case terminators are retained as structured statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_While_Loop) = 1,
         "while loop statements are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_End_Loop) = 2,
         "loop terminators are retained as structured statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Exit_When) = 1,
         "conditional exit statements are retained as explicit exit-when metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Exit_Named_Loop) = 0,
         "unnamed conditional exits do not pretend to be named-loop exits");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_For_Loop) = 1,
         "for loop statements are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_For_In_Loop) = 1,
         "discrete for-in loop statements retain explicit iteration-scheme metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Declare_Block) = 1,
         "declare blocks are retained as parser-owned statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_End_Block) = 1,
         "anonymous declare-block terminators are retained as end-block statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Label) = 2,
         "statement labels are retained and stripped before classifying the labelled statement");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Multiple_Label_Analysis, Editor.Ada_Language_Model.Statement_Label) = 3,
         "multiple leading statement labels are counted individually instead of collapsed");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Multiple_Label_Analysis, Editor.Ada_Language_Model.Statement_Call) = 1,
         "stacked labels are stripped before classifying the labelled call statement");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "assignment statements are retained without treating object declarations as assignments");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Call) = 3,
         "procedure-call statements in branch bodies are retained as statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Return) = 1,
         "return statements are retained as statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Extended_Return_Analysis, Editor.Ada_Language_Model.Statement_Return) = 1,
         "extended return statements are retained as return statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Extended_Return_Analysis, Editor.Ada_Language_Model.Statement_Extended_Return) = 1,
         "extended return statements are retained as explicit statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Extended_Return_Analysis, Editor.Ada_Language_Model.Statement_End_Return) = 1,
         "end return terminators are retained as structured statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Initialized_Return_Analysis, Editor.Ada_Language_Model.Statement_Extended_Return) = 1,
         "initialized extended returns are retained as explicit statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Return_Expression_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "ordinary return statements with expressions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Initialized_Return_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 0,
         "extended return objects are not flattened into ordinary return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Select) = 1,
         "select statements are retained as tasking statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Accept) = 1,
         "accept statements are retained as tasking statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Or_Alternative) = 1,
         "or alternatives are retained as select-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Terminate_Alternative) = 1,
         "terminate alternatives are retained as select-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_End_Select) = 1,
         "end select terminators are retained as structured statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Async_Analysis, Editor.Ada_Language_Model.Statement_Then_Abort_Alternative) = 1,
         "then abort alternatives are retained as asynchronous-select metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Async_Same_Line_Analysis, Editor.Ada_Language_Model.Statement_Then_Abort_Alternative) = 1,
         "same-line then-abort alternatives retain asynchronous-select metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Async_Same_Line_Analysis, Editor.Ada_Language_Model.Statement_Then_Abort_Action) = 1,
         "same-line then-abort actions retain explicit abort-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Async_Same_Line_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Call) = 1,
         "same-line then-abort call actions retain alternative call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Async_Same_Line_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line then-abort call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Analysis, Editor.Ada_Language_Model.Statement_Delay) = 2,
         "delay statements are retained as tasking statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Analysis, Editor.Ada_Language_Model.Statement_Delay_Relative) = 1,
         "relative delay statements are retained as explicit delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Analysis, Editor.Ada_Language_Model.Statement_Delay_Until) = 1,
         "delay-until statements are retained as explicit delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Or_Alternative) = 2,
         "delay alternatives retain selective-accept or-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Delay_Alternative) = 2,
         "selective-accept delay alternatives retain explicit delay-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Delay_Alternative_Relative) = 1,
         "relative delay alternatives retain explicit relative-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Delay_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Delay_Alternative_Until) = 1,
         "delay-until alternatives retain explicit until-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Or_Alternative) = 3,
         "same-line accept alternatives retain select-or metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Accept) = 3,
         "same-line accept alternatives retain embedded accept statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Accept_Alternative) = 2,
         "same-line selective accept alternatives retain explicit accept-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Accept_Body) = 1,
         "same-line accept alternatives with do parts retain accept-body metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Accept_With_Profile) = 2,
         "same-line accept alternatives retain profile metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Alternative_Analysis, Editor.Ada_Language_Model.Statement_Accept_Entry_Family_Index) = 1,
         "same-line accept alternatives retain entry-family metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select) = 1,
         "conditional entry-call statements retain base select metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Entry_Call) = 1,
         "conditional entry-call statements retain explicit select-entry-call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Call) = 1,
         "conditional entry-call statements retain embedded call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "conditional entry-call statements retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_Selected_Name) = 1,
         "conditional entry-call statements retain selected-name call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Accept) = 0,
         "conditional entry-call statements are not misclassified as accept statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Action) = 13,
         "compact conditional entry-call else fallbacks retain select-else action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Call) = 1,
         "compact conditional entry-call else fallbacks retain embedded call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Call) = 1,
         "compact conditional entry-call else call fallbacks retain select-specific call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Null) = 1,
         "compact conditional entry-call else null fallbacks retain select-specific null metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Assignment) = 1,
         "compact conditional entry-call else assignment fallbacks retain select-specific assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Return) = 1,
         "compact conditional entry-call else return fallbacks retain select-specific return metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Raise) = 1,
         "compact conditional entry-call else raise fallbacks retain select-specific raise metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Code) = 1,
         "compact conditional entry-call else code fallbacks retain select-specific code metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Exit) = 1,
         "compact conditional entry-call else exit fallbacks retain select-specific exit metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Goto) = 1,
         "compact conditional entry-call else goto fallbacks retain select-specific goto metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Delay) = 2,
         "compact conditional entry-call else delay fallbacks retain select-specific delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Delay_Until) = 1,
         "compact conditional entry-call else delay-until fallbacks retain select-specific until metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Delay_Relative) = 1,
         "compact conditional entry-call else relative delay fallbacks retain select-specific relative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Requeue) = 1,
         "compact conditional entry-call else requeue fallbacks retain select-specific requeue metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Requeue_With_Abort) = 1,
         "compact conditional entry-call else requeue-with-abort fallbacks retain select-specific abort metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Abort) = 1,
         "compact conditional entry-call else abort fallbacks retain select-specific abort metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Pragma) = 1,
         "compact conditional entry-call else pragma fallbacks retain select-specific pragma metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Select_Else_Pragma_With_Arguments) = 1,
         "compact conditional entry-call else pragma-argument fallbacks retain select-specific argument metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Conditional_Entry_Call_Else_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 2,
         "compact conditional entry-call and else fallback retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback) = 13,
         "compact timed entry-call delay fallbacks retain explicit select-delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Until) = 6,
         "compact timed entry-call delay-until fallbacks retain until metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Relative) = 7,
         "compact timed entry-call relative delay fallbacks retain relative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Delay) = 14,
         "compact timed entry-call delay fallbacks retain base delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Action) = 13,
         "compact timed entry-call delay fallback bodies retain action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Null) = 1,
         "compact timed entry-call delay fallback null actions retain select-specific null metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Call) = 2,
         "compact timed entry-call delay fallback call actions retain select-specific call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Call_With_Arguments) = 2,
         "compact timed entry-call delay fallback call actions retain argument metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Call_With_Named_Association) = 2,
         "compact timed entry-call delay fallback call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Call_Selected_Name) = 1,
         "compact timed entry-call delay fallback call actions retain selected-name metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Call_Entry_Family_Index) = 1,
         "compact timed entry-call delay fallback call actions retain entry-family index metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Call_Access_Dereference) = 0,
         "compact timed entry-call delay fallback call actions do not invent access-dereference metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Assignment) = 1,
         "compact timed entry-call delay fallback assignment actions retain select-specific assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Return) = 1,
         "compact timed entry-call delay fallback return actions retain select-specific return metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Raise) = 1,
         "compact timed entry-call delay fallback raise actions retain select-specific raise metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Code) = 1,
         "compact timed entry-call delay fallback code actions retain select-specific code metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Exit) = 1,
         "compact timed entry-call delay fallback exit actions retain select-specific exit metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Goto) = 1,
         "compact timed entry-call delay fallback goto actions retain select-specific goto metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Delay) = 1,
         "compact timed entry-call delay fallback delay actions retain select-specific delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Delay_Until) = 1,
         "compact timed entry-call delay fallback nested delay-until actions retain select-specific delay-until metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Delay_Relative) = 0,
         "compact timed entry-call delay fallback nested delay-until actions are not also relative delay actions");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Requeue) = 1,
         "compact timed entry-call delay fallback requeue actions retain select-specific requeue metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Requeue_With_Abort) = 1,
         "compact timed entry-call delay fallback requeue-with-abort actions retain select-specific with-abort metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Abort) = 1,
         "compact timed entry-call delay fallback abort actions retain select-specific abort metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Pragma) = 1,
         "compact timed entry-call delay fallback pragma actions retain select-specific pragma metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Timed_Entry_Call_Analysis, Editor.Ada_Language_Model.Statement_Select_Delay_Fallback_Pragma_With_Arguments) = 1,
         "compact timed entry-call delay fallback pragma arguments retain select-specific pragma-argument metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Async_Select_Analysis, Editor.Ada_Language_Model.Statement_Select_Then_Abort_Fallback) = 1,
         "compact asynchronous select statements retain select then-abort fallback metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Async_Select_Analysis, Editor.Ada_Language_Model.Statement_Select_Abortable_Call) = 1,
         "compact asynchronous select statements retain abortable triggering call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Async_Select_Analysis, Editor.Ada_Language_Model.Statement_Then_Abort_Alternative) = 1,
         "compact asynchronous select statements retain then-abort alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Async_Select_Analysis, Editor.Ada_Language_Model.Statement_Then_Abort_Action) = 1,
         "compact asynchronous select statements retain embedded abortable action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Async_Select_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "compact asynchronous select abortable actions retain named-association call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Terminate_Select_Analysis, Editor.Ada_Language_Model.Statement_Select_Terminate_Fallback) = 1,
         "compact selective accept terminate fallbacks retain select-level terminate metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Terminate_Select_Analysis, Editor.Ada_Language_Model.Statement_Terminate_Alternative) = 1,
         "compact selective accept terminate fallbacks retain terminate alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Body_Analysis, Editor.Ada_Language_Model.Statement_Accept) = 4,
         "accept statements with handled bodies are retained as accept statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Body_Analysis, Editor.Ada_Language_Model.Statement_Accept_Body) = 4,
         "accept statements with do parts are retained as explicit accept-body metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Body_Analysis, Editor.Ada_Language_Model.Statement_Accept_With_Profile) = 2,
         "accept statements with parameter profiles retain explicit accept-profile metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Accept_Body_Analysis, Editor.Ada_Language_Model.Statement_Accept_Entry_Family_Index) = 2,
         "accept statements with entry-family indexes retain explicit accept-family metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Qualified_Simple_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "raise statements with message expressions are retained as explicit metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Raise_Form_Analysis, Editor.Ada_Language_Model.Statement_Raise) = 4,
         "raise statements retain base raise metadata across reraise and named forms");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Raise_Form_Analysis, Editor.Ada_Language_Model.Statement_Raise_Reraise) = 2,
         "bare raise statements retain explicit reraise statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Raise_Form_Analysis, Editor.Ada_Language_Model.Statement_Raise_Exception_Name) = 2,
         "raise statements with exception names retain explicit exception-name metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Raise_Form_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "raise statements with message expressions remain distinct from bare reraises");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Raise_Form_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Raise) = 1,
         "raise actions after executable alternatives retain raise-form details");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Qualified_Simple_Analysis, Editor.Ada_Language_Model.Statement_Requeue_With_Abort) = 1,
         "requeue-with-abort statements are retained as explicit tasking metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Requeue_Target_Analysis, Editor.Ada_Language_Model.Statement_Requeue) = 3,
         "requeue statements and alternative actions retain base requeue metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Requeue_Target_Analysis, Editor.Ada_Language_Model.Statement_Requeue_Selected_Target) = 3,
         "requeue statements retain selected-name target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Requeue_Target_Analysis, Editor.Ada_Language_Model.Statement_Requeue_With_Arguments) = 2,
         "requeue statements retain entry-family or argument-list target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Requeue_Target_Analysis, Editor.Ada_Language_Model.Statement_Requeue_With_Abort) = 2,
         "requeue target-shape metadata coexists with with-abort metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Code_Statement_Analysis, Editor.Ada_Language_Model.Statement_Code) = 1,
         "Ada code statements are retained as explicit statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Code_Statement_Analysis, Editor.Ada_Language_Model.Statement_Call) = 0,
         "code statements must not be flattened into procedure-call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Pragma_Statement_Analysis, Editor.Ada_Language_Model.Statement_Pragma) = 3,
         "pragma statements in executable sequences and alternatives are retained as parser-owned metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Pragma_Statement_Analysis, Editor.Ada_Language_Model.Statement_Pragma_With_Arguments) = 2,
         "pragma statements with argument lists retain explicit argument metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Pragma_Statement_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Pragma) = 1,
         "pragma actions after executable alternatives retain explicit alternative-pragma metadata");
      Assert
        (Editor.Ada_Symbol_Resolver.First_Match (Pragma_Statement_Analysis, "Assert") =
           Editor.Ada_Language_Model.No_Symbol,
         "pragma names are not learned as declaration symbols");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Call_Association_Analysis, Editor.Ada_Language_Model.Statement_Call) = 2,
         "procedure-call statements with positional or named arguments are retained as calls");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Call_Association_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Arguments) = 2,
         "procedure-call statements with explicit argument lists retain argument metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Call_Association_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "procedure-call statements with named associations are not discarded because they contain arrows");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Call_Association_Analysis, Editor.Ada_Language_Model.Statement_Code) = 0,
         "ordinary procedure calls with named associations are not code statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Selected_Call_Analysis, Editor.Ada_Language_Model.Statement_Call) = 6,
         "selected-name, attribute, and access-dereference calls are still retained as ordinary call statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Selected_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_Selected_Name) = 4,
         "selected-name and access-dereference calls retain explicit selected-call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Selected_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_Access_Dereference) = 2,
         "explicit access-dereference calls retain access-dereference metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Selected_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "selected-name calls with named associations retain both selected and association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Selected_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_Attribute_Name) = 2,
         "attribute-reference call statements retain explicit attribute-name metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Entry_Family_Call_Analysis, Editor.Ada_Language_Model.Statement_Call_Entry_Family_Index) = 2,
         "entry-family shaped calls retain explicit indexed-entry call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Entry_Family_Call_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Call) = 1,
         "entry-family shaped calls after alternatives retain alternative-call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Assignment_Target_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 8,
         "assignment statements with selected, indexed, slice, and access-dereference targets retain base assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Assignment_Target_Analysis, Editor.Ada_Language_Model.Statement_Assignment_Selected_Target) = 4,
         "selected-component and access-dereference assignment targets retain explicit assignment-target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Assignment_Target_Analysis, Editor.Ada_Language_Model.Statement_Assignment_Access_Dereference) = 2,
         "explicit access-dereference assignment targets retain access-dereference metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Assignment_Target_Analysis, Editor.Ada_Language_Model.Statement_Assignment_Indexed_Target) = 5,
         "indexed and slice assignment targets retain explicit assignment-target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Assignment_Target_Analysis, Editor.Ada_Language_Model.Statement_Assignment_Slice_Target) = 2,
         "slice assignment targets retain explicit assignment-target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Assignment_Target_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Assignment) = 4,
         "assignment actions after executable alternatives retain assignment-target details");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Analysis, Editor.Ada_Language_Model.Statement_Compact_Sequence) = 3,
         "compact same-line statement sequences are retained as parser-owned metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Analysis, Editor.Ada_Language_Model.Statement_Null) = 3,
         "inline null actions in compact same-line statement sequences are retained");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Analysis, Editor.Ada_Language_Model.Statement_End_If) = 1,
         "inline end-if terminators in compact same-line statement sequences are retained");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Analysis, Editor.Ada_Language_Model.Statement_End_Loop) = 1,
         "inline end-loop terminators in compact same-line statement sequences are retained");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Analysis, Editor.Ada_Language_Model.Statement_End_Select) = 1,
         "inline end-select terminators in compact same-line statement sequences are retained");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Then_Action_Analysis, Editor.Ada_Language_Model.Statement_Then_Action) = 4,
         "same-line if-then actions are retained as explicit compact action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Then_Action_Analysis, Editor.Ada_Language_Model.Statement_Call) = 1,
         "same-line if-then call actions retain call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Then_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line if-then call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Then_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line if-then assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Then_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line if-then return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Then_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "same-line if-then raise actions retain raise-with-message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Elsif_Action_Analysis, Editor.Ada_Language_Model.Statement_Elsif_Action) = 4,
         "same-line if-elsif actions are retained as explicit compact action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Elsif_Action_Analysis, Editor.Ada_Language_Model.Statement_Call) = 1,
         "same-line if-elsif call actions retain call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Elsif_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line if-elsif call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Elsif_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line if-elsif assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Elsif_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line if-elsif return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Elsif_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "same-line if-elsif raise actions retain raise-with-message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Else_Action_Analysis, Editor.Ada_Language_Model.Statement_Else_Action) = 4,
         "same-line if-else actions are retained as explicit compact action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Else_Action_Analysis, Editor.Ada_Language_Model.Statement_Call) = 1,
         "same-line if-else call actions retain call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Else_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line if-else call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Else_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line if-else assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Else_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line if-else return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Else_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "same-line if-else raise actions retain raise-with-message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Loop_Action_Analysis, Editor.Ada_Language_Model.Statement_Loop_Action) = 4,
         "same-line loop-body actions are retained as explicit compact action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Loop_Action_Analysis, Editor.Ada_Language_Model.Statement_Call) = 1,
         "same-line loop call actions retain call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Loop_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line loop call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Loop_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line loop assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Loop_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line loop return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Loop_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "same-line loop raise actions retain raise-with-message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Case_Action_Analysis, Editor.Ada_Language_Model.Statement_Case_Alternative_Action) = 4,
         "same-line case alternatives retain explicit compact action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Case_Action_Analysis, Editor.Ada_Language_Model.Statement_When_Alternative) = 4,
         "same-line case alternatives retain executable when metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Case_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line case call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Case_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line case assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Case_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line case return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Case_Action_Analysis, Editor.Ada_Language_Model.Statement_Null_Alternative) = 1,
         "same-line case null actions retain null-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Exception_Action_Analysis, Editor.Ada_Language_Model.Statement_Exception_Handler_Action) = 3,
         "same-line exception handlers retain explicit compact handler-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Exception_Action_Analysis, Editor.Ada_Language_Model.Statement_When_Alternative) = 3,
         "same-line exception handlers retain executable when metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Exception_Action_Analysis, Editor.Ada_Language_Model.Statement_Null_Alternative) = 1,
         "same-line exception null handlers retain null-alternative metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Exception_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line exception call handlers retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Exception_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_Reraise) = 1,
         "same-line exception reraise handlers retain raise-form metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Begin_Action_Analysis, Editor.Ada_Language_Model.Statement_Begin_Action) = 4,
         "same-line begin handled-sequence actions retain explicit compact begin-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Begin_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line begin call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Begin_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line begin assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Begin_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line begin return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Begin_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "same-line begin raise actions retain raise-with-message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_Declare_Action) = 4,
         "same-line declare-block actions retain explicit compact declare-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_Begin_Action) = 4,
         "same-line declare-block actions retain embedded begin-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_End_Block) = 4,
         "same-line declare blocks retain anonymous end-block terminator metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "same-line declare call actions retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_Assignment) = 1,
         "same-line declare assignment actions retain assignment metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "same-line declare return actions retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Compact_Declare_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "same-line declare raise actions retain raise-with-message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Exception_Handler) = 1,
         "exception sections are retained as statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_When_Alternative) = 3,
         "case and exception when alternatives are retained as statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Null_Alternative) = 2,
         "null alternatives in case/exception alternatives are retained as explicit statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Analysis, Editor.Ada_Language_Model.Statement_Alternative_Raise) = 1,
         "raise actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Assignment) = 1,
         "assignment actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Call) = 3,
         "call actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Arguments) = 3,
         "call actions after alternatives retain argument-list metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_With_Named_Association) = 1,
         "call actions after alternatives retain named-association metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_Selected_Name) = 2,
         "selected-name and access-dereference call actions after alternatives retain selected-call metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_Access_Dereference) = 1,
         "access-dereference call actions after alternatives retain access-dereference metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Call_Entry_Family_Index) = 0,
         "ordinary call actions are not misclassified as entry-family calls");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Code) = 1,
         "qualified-expression code actions after alternatives are retained separately from calls");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Return) = 2,
         "return actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Return_With_Expression) = 1,
         "return-expression actions after alternatives retain return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Return_With_Expression) = 1,
         "return-expression actions after alternatives retain alternative return-expression metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Raise) = 1,
         "raise actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Raise_With_Message) = 1,
         "raise-with-message actions after alternatives retain message metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Exit) = 1,
         "exit actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Exit_When) = 1,
         "conditional exit actions after alternatives retain exit-when metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Exit_Named_Loop) = 1,
         "named-loop exit actions after alternatives retain named-exit metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Goto) = 1,
         "goto actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Goto_Label_Target) = 1,
         "goto actions after alternatives retain visible label-target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Goto_Target_Analysis, Editor.Ada_Language_Model.Statement_Goto) = 2,
         "ordinary and alternative goto statements retain base goto metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Goto_Target_Analysis, Editor.Ada_Language_Model.Statement_Goto_Label_Target) = 2,
         "goto statements retain visible label-target metadata without learning labels as declarations");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Delay) = 1,
         "delay actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Delay_Until) = 1,
         "delay-until actions after alternatives retain delay metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Requeue) = 1,
         "requeue actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Requeue_With_Abort) = 1,
         "requeue-with-abort actions after alternatives retain tasking metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Requeue_Target_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Requeue) = 1,
         "requeue alternative actions retain alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Alternative_Action_Analysis, Editor.Ada_Language_Model.Statement_Alternative_Abort) = 1,
         "abort actions after executable alternatives are retained as alternative-action metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Abort_Target_Analysis, Editor.Ada_Language_Model.Statement_Abort) = 4,
         "abort statements and abort alternative actions retain base abort metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Abort_Target_Analysis, Editor.Ada_Language_Model.Statement_Abort_Selected_Target) = 3,
         "abort statements retain selected-name target metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Abort_Target_Analysis, Editor.Ada_Language_Model.Statement_Abort_Multiple_Targets) = 2,
         "abort statements retain comma-separated target-list metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Record_Analysis, Editor.Ada_Language_Model.Statement_Case) = 0,
         "record variant parts must not be misclassified as executable case statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Record_Analysis, Editor.Ada_Language_Model.Statement_When_Alternative) = 0,
         "record variant choices must not be misclassified as executable when alternatives");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Record_Analysis, Editor.Ada_Language_Model.Statement_Null_Alternative) = 0,
         "record variant null alternatives must not be misclassified as executable null alternatives");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Record_Analysis, Editor.Ada_Language_Model.Statement_End_Case) = 0,
         "record variant terminators must not be misclassified as executable end-case statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_Named_Loop) = 2,
         "named for/plain loops are retained as named-loop statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_Named_Block) = 1,
         "named declare blocks are retained as named-block statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_For_Loop) = 1,
         "named for loops are still classified as their underlying loop kind");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_Loop) = 1,
         "named plain loops are still classified as their underlying loop kind");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_End_Named_Loop) = 2,
         "named loop terminators are retained as explicit end-loop metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_Exit_Named_Loop) = 1,
         "named exits retain explicit named-loop exit metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (Named_Analysis, Editor.Ada_Language_Model.Statement_Declare_Block) = 1,
         "named declare blocks are still classified as declare-block statements");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (For_Form_Analysis, Editor.Ada_Language_Model.Statement_For_Loop) = 3,
         "all explicit for-loop forms retain base for-loop statement metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (For_Form_Analysis, Editor.Ada_Language_Model.Statement_For_In_Loop) = 2,
         "discrete for-in loops retain explicit iteration-scheme metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (For_Form_Analysis, Editor.Ada_Language_Model.Statement_For_Of_Loop) = 1,
         "container for-of iterator loops retain explicit iteration-scheme metadata");
      Assert
        (Editor.Ada_Language_Model.Statement_Count
           (For_Form_Analysis, Editor.Ada_Language_Model.Statement_For_Reverse_Loop) = 1,
         "reverse discrete for loops retain explicit reverse-iteration metadata");
   end Test_Language_Model_Statement_Awareness;

   procedure Test_Language_Model_Executable_Statement_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Counter : Integer := 0;" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   <<Again>>" & ASCII.LF &
        "   for I in 1 .. 10 loop" & ASCII.LF &
        "      Counter := Counter + I;" & ASCII.LF &
        "      Put_Line (Integer'Image (Counter));" & ASCII.LF &
        "      goto Again;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when E | Constraint_Error => null;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Has_Executable_Bindings (Analysis),
         "parser should retain executable statement semantic bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Loop_Parameter) = 1,
         "for-loop parameter should be retained as a statement-local binding");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Assignment_Target) >= 1,
         "assignment target should be retained as executable binding metadata");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Call_Target) >= 1,
         "call target should be retained for navigation/semantic colouring");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Label_Declaration) = 1,
         "statement label declaration should be retained");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Goto_Target) = 1,
         "goto target should be retained");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Exception_Handler_Choice) = 2,
         "exception handler choices should be retained independently");
   end Test_Language_Model_Executable_Statement_Bindings;

   procedure Test_Language_Model_Executable_Selected_Component_Uses
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type State is record" & ASCII.LF &
        "      Value : Integer;" & ASCII.LF &
        "      Flag  : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Holder : State;" & ASCII.LF &
        "   function Next (Value : Integer) return Integer is (Value + 1);" & ASCII.LF &
        "   procedure Sink (Value : Integer) is null;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Holder.Flag then" & ASCII.LF &
        "      Sink (Holder.Value);" & ASCII.LF &
        "      Holder.Value := Next (Holder.Value);" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_selected_components.adb");
      Selected_Count : constant Natural :=
        Editor.Ada_Language_Model.Executable_Binding_Count
          (Analysis, Editor.Ada_Language_Model.Binding_Selected_Component);
      Value_Uses : Natural := 0;
      Flag_Uses  : Natural := 0;
   begin
      for Index in 1 .. Editor.Ada_Language_Model.Executable_Binding_Count (Analysis) loop
         declare
            B : constant Editor.Ada_Language_Model.Executable_Binding_Info :=
              Editor.Ada_Language_Model.Executable_Binding_At (Analysis, Index);
            N : constant String :=
              Editor.Ada_Language_Model.Normalize_Name
                (Ada.Strings.Unbounded.To_String (B.Name));
         begin
            if B.Kind = Editor.Ada_Language_Model.Binding_Selected_Component then
               if N = "value" then
                  Value_Uses := Value_Uses + 1;
               elsif N = "flag" then
                  Flag_Uses := Flag_Uses + 1;
               end if;
            end if;
         end;
      end loop;

      Assert (Selected_Count >= 4,
              "selected component uses in executable expressions should be retained");
      Assert (Value_Uses >= 3,
              "RHS, actual, and assignment-target selected components should retain Value");
      Assert (Flag_Uses = 1,
              "if-condition selected component should retain Flag exactly once");
   end Test_Language_Model_Executable_Selected_Component_Uses;

   procedure Test_Language_Model_Executable_Entry_Family_Index_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   protected type Gate is" & ASCII.LF &
        "      entry Take (Positive);" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   protected body Gate is" & ASCII.LF &
        "      entry Take (Index : Positive) when Ready is" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Take;" & ASCII.LF &
        "   end Gate;" & ASCII.LF &
        "   G : Gate;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   G.Take (1);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_entry_family_index_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Entry_Family_Index) = 1,
         "entry-family indexes should be retained separately from array indexing");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Array_Index) = 0,
         "entry-family calls should not be misclassified as array indexing");
   end Test_Language_Model_Executable_Entry_Family_Index_Bindings;

   procedure Test_Language_Model_Executable_Delta_Aggregate_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Rec is record" & ASCII.LF &
        "      Count : Integer;" & ASCII.LF &
        "      Ready : Boolean;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   Current : Rec := (Count => 0, Ready => False);" & ASCII.LF &
        "   Next : Rec;" & ASCII.LF &
        "   Value : Integer := 1;" & ASCII.LF &
        "   Flag : Boolean := True;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Next := (Current with delta Count => Value, Ready => Flag);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_delta_aggregate_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Delta_Aggregate_Base) = 1,
         "delta aggregate base names should be retained as executable expression bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Delta_Aggregate_Component) = 2,
         "delta aggregate component associations should be retained separately");
      declare
         Found_Base : Boolean := False;
      begin
         for I in 1 .. Editor.Ada_Language_Model.Executable_Binding_Count (Analysis) loop
            declare
               B : constant Editor.Ada_Language_Model.Executable_Binding_Info :=
                 Editor.Ada_Language_Model.Executable_Binding_At (Analysis, I);
            begin
               if B.Kind = Editor.Ada_Language_Model.Binding_Delta_Aggregate_Base
                 and then To_String (B.Name) = "Current"
               then
                  Found_Base := True;
               end if;
            end;
         end loop;

         Assert
           (Found_Base,
            "delta aggregate base binding should identify the aggregate base, not the assignment target");
      end;
   end Test_Language_Model_Executable_Delta_Aggregate_Bindings;

   procedure Test_Language_Model_Executable_Named_Actual_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Count : Integer := 0;" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   procedure Sink (Value : Integer; Flag : Boolean);" & ASCII.LF &
        "   procedure Sink (Value : Integer; Flag : Boolean) is null;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean is (Value > 0);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Sink (Value => Count, Flag => Ready);" & ASCII.LF &
        "   Ready := Check (Value => Count);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_named_actual_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Named_Actual) = 3,
         "named call actual associations should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Call_Target) >= 2,
         "named actual extraction should preserve executable call-target bindings");
   end Test_Language_Model_Executable_Named_Actual_Bindings;

   procedure Test_Language_Model_Executable_Range_Bound_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Index is range 1 .. 10;" & ASCII.LF &
        "   type Vector is array (Index) of Integer;" & ASCII.LF &
        "   Values : Vector;" & ASCII.LF &
        "   First : Index := 1;" & ASCII.LF &
        "   Last : Index := 10;" & ASCII.LF &
        "   X : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   for I in First .. Last loop" & ASCII.LF &
        "      X := Values (I);" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   X := Values (First .. Last)'Length;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_range_bound_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Range_Bound) >= 4,
         "range bounds in loops and slices should be retained as executable name bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Array_Slice) >= 1,
         "range-bound extraction should preserve array-slice binding metadata");
   end Test_Language_Model_Executable_Range_Bound_Bindings;

   procedure Test_Language_Model_Executable_Pragma_Argument_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   Count : Integer := 0;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean;" & ASCII.LF &
        "   function Check (Value : Integer) return Boolean is (Value > 0);" & ASCII.LF &
        "begin" & ASCII.LF &
        "   pragma Assert (Ready and Check (Count));" & ASCII.LF &
        "   pragma Loop_Invariant (Ready);" & ASCII.LF &
        "   pragma Import (C, Check);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_pragma_argument_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Pragma_Argument) = 2,
         "executable assertion pragmas should retain argument expression names");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Call_Target) >= 1,
         "pragma argument expressions should still expose nested call targets");
   end Test_Language_Model_Executable_Pragma_Argument_Bindings;

   procedure Test_Language_Model_Executable_Attribute_Prefix_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   S : String := ""abc"";" & ASCII.LF &
        "   X : Integer := 0;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   X := S'Length;" & ASCII.LF &
        "   X := X'Size;" & ASCII.LF &
        "   S := Integer'Image (X);" & ASCII.LF &
        "   X := Integer'(2);" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_attribute_prefix_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Attribute_Prefix) >= 3,
         "attribute prefixes should be retained as executable name bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Qualified_Expression_Target) = 1,
         "qualified expressions should remain distinct from attribute prefixes");
   end Test_Language_Model_Executable_Attribute_Prefix_Bindings;

   procedure Test_Language_Model_Executable_Case_Choices_Are_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   type Mode is (Idle, Busy, Done);" & ASCII.LF &
        "   Current : Mode := Idle;" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   case Current is" & ASCII.LF &
        "      when Idle | Busy => null;" & ASCII.LF &
        "      when Done => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when E => null;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_case_choices.adb");
      Case_Choices : constant Natural :=
        Editor.Ada_Language_Model.Executable_Binding_Count
          (Analysis, Editor.Ada_Language_Model.Binding_Case_Choice);
      Exception_Choices : constant Natural :=
        Editor.Ada_Language_Model.Executable_Binding_Count
          (Analysis, Editor.Ada_Language_Model.Binding_Exception_Handler_Choice);
   begin
      Assert (Case_Choices = 3,
              "case alternatives should be retained as case-choice executable bindings");
      Assert (Exception_Choices = 1,
              "exception choices should remain distinct from case alternatives");
   end Test_Language_Model_Executable_Case_Choices_Are_Distinct;

   procedure Test_Language_Model_Executable_Block_And_Exit_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "begin" & ASCII.LF &
        "   Main_Loop : loop" & ASCII.LF &
        "      exit Main_Loop when Done;" & ASCII.LF &
        "      Helper_Block : declare" & ASCII.LF &
        "         Value : Integer := 1;" & ASCII.LF &
        "      begin" & ASCII.LF &
        "         null;" & ASCII.LF &
        "      end Helper_Block;" & ASCII.LF &
        "   end loop Main_Loop;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_block_exit_targets.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Block_Label) = 2,
         "loop and declare block labels should be retained as executable block labels");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Exit_Target) = 1,
         "exit loop targets should be retained as executable control-flow bindings");
   end Test_Language_Model_Executable_Block_And_Exit_Targets;

   procedure Test_Language_Model_Executable_Delay_And_Abort_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Next_Time : Time;" & ASCII.LF &
        "   Period : Duration;" & ASCII.LF &
        "   task type Worker;" & ASCII.LF &
        "   A : Worker;" & ASCII.LF &
        "   B : Worker;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   delay until Next_Time;" & ASCII.LF &
        "   delay Period;" & ASCII.LF &
        "   abort A, B;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_delay_abort_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Delay_Target) = 2,
         "delay expression targets should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Abort_Target) = 2,
         "abort statement targets should retain each listed task name");
   end Test_Language_Model_Executable_Delay_And_Abort_Bindings;

   procedure Test_Language_Model_Executable_Condition_And_Iteration_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Ready : Boolean;" & ASCII.LF &
        "   Done : Boolean;" & ASCII.LF &
        "   State : Integer;" & ASCII.LF &
        "   Items : Integer;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   if Ready then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   elsif Done then" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end if;" & ASCII.LF &
        "   while Ready loop" & ASCII.LF &
        "      exit;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   case State is" & ASCII.LF &
        "      when 1 => null;" & ASCII.LF &
        "      when others => null;" & ASCII.LF &
        "   end case;" & ASCII.LF &
        "   for Item of Items loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_condition_iteration_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Condition_Target) = 4,
         "if elsif while and case selector names should be retained as executable condition bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Iteration_Source) = 1,
         "for-loop iteration source names should be retained separately from loop parameters");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Loop_Parameter) = 1,
         "for-loop parameters should still be retained as local executable bindings");
   end Test_Language_Model_Executable_Condition_And_Iteration_Bindings;

   procedure Test_Language_Model_Executable_Select_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Ready : Boolean;" & ASCII.LF &
        "   task type Worker is" & ASCII.LF &
        "      entry Start (Value : in Integer; Flag, Other : Boolean);" & ASCII.LF &
        "   end Worker;" & ASCII.LF &
        "   W : Worker;" & ASCII.LF &
        "   Deadline : Duration;" & ASCII.LF &
        "   Next_Time : Duration;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   select" & ASCII.LF &
        "      when Ready =>" & ASCII.LF &
        "         accept Start;" & ASCII.LF &
        "   or W.Start;" & ASCII.LF &
        "   or delay until Next_Time;" & ASCII.LF &
        "   else" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   select W.Start;" & ASCII.LF &
        "   then abort" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   select delay Deadline;" & ASCII.LF &
        "   then abort" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "   select" & ASCII.LF &
        "      accept Start;" & ASCII.LF &
        "   or" & ASCII.LF &
        "      terminate;" & ASCII.LF &
        "   end select;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "run_select_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Select_Guard) = 1,
         "select guards should be retained separately from case alternatives and exception choices");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Select_Entry_Call) = 2,
         "select entry-call alternatives should be retained as executable navigation bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Select_Delay_Target) = 2,
         "select delay alternatives should retain their delay expression targets separately from entry calls");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Select_Terminate) = 1,
         "select terminate alternatives should be retained separately from guards, entry calls, and delay alternatives");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Select_Abort) = 2,
         "asynchronous select then-abort alternatives should be retained separately from entry/delay alternatives");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Case_Choice) = 0,
         "select guards should not be misclassified as ordinary case choices");
   end Test_Language_Model_Executable_Select_Bindings;

   procedure Test_Language_Model_Executable_Entry_Barrier_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "protected body Gate is" & ASCII.LF &
        "   Ready : Boolean := False;" & ASCII.LF &
        "   entry Start when Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Start;" & ASCII.LF &
        "   entry Stop when not Ready is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end Stop;" & ASCII.LF &
        "end Gate;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, "gate_entry_barriers.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Entry_Barrier) = 2,
         "protected entry barrier expression names should be retained as executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Select_Guard) = 0,
         "entry barriers should not be misclassified as select guards");
   end Test_Language_Model_Executable_Entry_Barrier_Bindings;

   procedure Test_Language_Model_Executable_Exception_Occurrence_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   E : exception;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   raise E;" & ASCII.LF &
        "exception" & ASCII.LF &
        "   when Occ : Constraint_Error | Program_Error =>" & ASCII.LF &
        "      Log (Occ);" & ASCII.LF &
        "   when E =>" & ASCII.LF &
        "      null;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "run_exception_occurrence_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Exception_Occurrence) = 1,
         "exception occurrence identifiers should be retained as local executable bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Exception_Handler_Choice) = 3,
         "exception choices should remain distinct from occurrence identifiers");
   end Test_Language_Model_Executable_Exception_Occurrence_Bindings;

   procedure Test_Language_Model_Executable_Iterator_Filter_Bindings
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Source : constant String :=
        "procedure Run is" & ASCII.LF &
        "   Items : Integer := 0;" & ASCII.LF &
        "   Ready : Boolean := True;" & ASCII.LF &
        "   First : Integer := 1;" & ASCII.LF &
        "   Last  : Integer := 10;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   for Item of Items when Ready loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "   for I in First .. Last when Ready loop" & ASCII.LF &
        "      null;" & ASCII.LF &
        "   end loop;" & ASCII.LF &
        "end Run;" & ASCII.LF;
      Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse
          (Source, "run_iterator_filter_bindings.adb");
   begin
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Iteration_Filter) = 2,
         "iterator filters should be retained as executable expression bindings");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Iteration_Source) = 2,
         "iterator sources should remain distinct from iterator filters");
      Assert
        (Editor.Ada_Language_Model.Executable_Binding_Count
           (Analysis, Editor.Ada_Language_Model.Binding_Range_Bound) = 2,
         "range bounds should still be retained from filtered discrete ranges");
   end Test_Language_Model_Executable_Iterator_Filter_Bindings;

   overriding function Name (T : ExecutableBindings_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Executable-Bindings-Tests");
   end Name;

   overriding procedure Register_Tests (T : in out ExecutableBindings_Test_Case) is
      procedure Add_Test
        (Routine : AUnit.Test_Cases.Test_Routine; Name : String) is
      begin
         AUnit.Test_Cases.Registration.Register_Routine (T, Routine, Name);
      end Add_Test;
   begin
      Add_Test (Routine => Test_Language_Model_Statement_Awareness'Access, Name => "language model retains parser-owned statement awareness");
      Add_Test (Routine => Test_Language_Model_Executable_Statement_Bindings'Access, Name => "language model retains executable statement semantic bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Selected_Component_Uses'Access, Name => "language model retains executable selected component uses");
      Add_Test (Routine => Test_Language_Model_Executable_Entry_Family_Index_Bindings'Access, Name => "language model retains executable entry-family index bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Delta_Aggregate_Bindings'Access, Name => "language model retains executable delta aggregate bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Named_Actual_Bindings'Access, Name => "language model retains executable named actual bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Range_Bound_Bindings'Access, Name => "language model retains executable range bound bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Pragma_Argument_Bindings'Access, Name => "language model retains executable pragma argument bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Attribute_Prefix_Bindings'Access, Name => "language model retains executable attribute prefix bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Case_Choices_Are_Distinct'Access, Name => "language model distinguishes case alternatives from exception choices");
      Add_Test (Routine => Test_Language_Model_Executable_Block_And_Exit_Targets'Access, Name => "language model retains executable block and exit targets");
      Add_Test (Routine => Test_Language_Model_Executable_Delay_And_Abort_Bindings'Access, Name => "language model retains executable delay and abort bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Condition_And_Iteration_Bindings'Access, Name => "language model retains executable condition and iteration bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Select_Bindings'Access, Name => "language model retains executable select statement bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Entry_Barrier_Bindings'Access, Name => "language model retains executable entry barrier bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Exception_Occurrence_Bindings'Access, Name => "language model retains executable exception occurrence bindings");
      Add_Test (Routine => Test_Language_Model_Executable_Iterator_Filter_Bindings'Access, Name => "language model retains executable iterator filter bindings");
   end Register_Tests;

end Editor.Syntax_Semantics.Executable_Bindings_Tests;
