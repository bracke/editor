with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Syntax_Tree is

   --  Parser-owned Ada syntax tree foundation.  This package is deliberately
   --  UI-free and owns only immutable source-shape metadata derived from a
   --  caller-supplied snapshot.  It is the first grammar-tree layer under the
   --  declaration parser; later passes can replace line-level nodes with full
   --  production nodes without changing rendering, commands, or persistence.

   type Node_Kind is
     (Node_Compilation_Unit,
      Node_Token_Cursor_Grammar,
      Node_Grammar_Production,
      Node_Context_Clause,
      Node_With_Clause,
      Node_Use_Clause,
      Node_Pragma,
      Node_Pragma_Name,
      Node_Pragma_Argument,
      Node_Pragma_Argument_Association,
      Node_Aspect_Specification,
      Node_Aspect_Association,
      Node_Aspect_Name,
      Node_Aspect_Value,
      Node_Representation_Clause,
      Node_Representation_Target,
      Node_Representation_Item,
      Node_Representation_Component_Clause,
      Node_Representation_Mod_Clause,
      Node_Generic_Actual_Part,
      Node_Generic_Actual_Association,
      Node_Generic_Actual_Formal,
      Node_Generic_Actual_Value,
      Node_Package_Declaration,
      Node_Package_Body,
      Node_Subprogram_Declaration,
      Node_Abstract_Subprogram_Declaration,
      Node_Null_Procedure_Declaration,
      Node_Expression_Function_Declaration,
      Node_Subprogram_Body,
      Node_Type_Declaration,
      Node_Subtype_Declaration,
      Node_Object_Declaration,
      Node_Constant_Declaration,
      Node_Deferred_Constant_Declaration,
      Node_Number_Declaration,
      Node_Component_Declaration,
      Node_Discriminant_Specification,
      Node_Parameter_Specification,
      Node_Formal_Object_Declaration,
      Node_Formal_Type_Declaration,
      Node_Formal_Subprogram_Declaration,
      Node_Formal_Package_Declaration,
      Node_Exception_Declaration,
      Node_Generic_Declaration,
      Node_Rename_Declaration,
      Node_Instantiation,
      Node_Separate_Body,
      Node_Task_Declaration,
      Node_Task_Type_Declaration,
      Node_Single_Task_Declaration,
      Node_Task_Body,
      Node_Protected_Declaration,
      Node_Protected_Type_Declaration,
      Node_Single_Protected_Declaration,
      Node_Protected_Body,
      Node_Entry_Declaration,
      Node_Entry_Body,
      Node_Entry_Body_Stub,
      Node_Private_Part,
      Node_Incomplete_Type_Declaration,
      Node_Private_Extension_Declaration,
      Node_Body_Stub,
      Node_Choice_Parameter_Specification,
      Node_Enumeration_Literal_Declaration,
      Node_Variant_Part,
      Node_Variant,
      Node_Declaration_Name,
      Node_Declaration_Subtype,
      Node_Declaration_Default,
      Node_Declaration_Mode,
      Node_Declaration_Profile,
      Node_Declaration_Result,
      Node_Declaration_Target,
      Node_Begin_Block,
      Node_If_Statement,
      Node_Case_Statement,
      Node_Loop_Statement,
      Node_Declare_Block,
      Node_Select_Statement,
      Node_Accept_Statement,
      Node_Entry_Call_Statement,
      Node_Return_Statement,
      Node_Raise_Statement,
      Node_Assignment_Statement,
      Node_Call_Statement,
      Node_Null_Statement,
      Node_Exit_Statement,
      Node_Goto_Statement,
      Node_Requeue_Statement,
      Node_Delay_Statement,
      Node_Abort_Statement,
      Node_Terminate_Statement,
      Node_Label,
      Node_Statement_Sequence,
      Node_Statement_Action,
      Node_Statement_Alternative,
      Node_Statement_Target,
      Node_Statement_Condition,
      Node_Statement_Selector,
      Node_Statement_Profile,
      Node_Statement_Arguments,
      Node_Statement_Message,
      Node_Statement_Mode,
      Node_Expression,
      Node_Name,
      Node_Selected_Name,
      Node_Attribute_Reference,
      Node_Indexed_Component,
      Node_Slice,
      Node_Function_Call,
      Node_Operator_Expression,
      Node_Literal,
      Node_Qualified_Expression,
      Node_Aggregate,
      Node_Conditional_Expression,
      Node_Case_Expression,
      Node_Quantified_Expression,
      Node_Declare_Expression,
      Node_Delta_Aggregate,
      Node_Container_Aggregate,
      Node_Reduction_Expression,
      Node_Iterator_Specification,
      Node_Target_Name,
      Node_Range_Expression,
      Node_Membership_Expression,
      Node_Short_Circuit_Expression,
      Node_Unary_Expression,
      Node_Parenthesized_Expression,
      Node_Explicit_Dereference,
      Node_Allocator,
      Node_Association,
      Node_Named_Association,
      Node_Positional_Association,
      Node_Pragma_Statement,
      Node_Elsif_Part,
      Node_Else_Part,
      Node_When_Alternative,
      Node_Select_Alternative,
      Node_Exception_Handler,
      Node_Exception_Section,
      Node_End,
      Node_Recovery_Point,
      Node_Implicit_Begin,
      Node_Unexpected_Declaration,
      Node_Implicit_End,
      Node_Missing_End,
      Node_Unexpected_End,
      Node_Mismatched_End,
      Node_End_Target,
      Node_Expected_End_Target,
      Node_Expected_Token,
      Node_Unknown);

   type Node_Id is new Natural;
   No_Node : constant Node_Id := 0;

   type Source_Range is record
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
   end record;

   type Node_Info is record
      Id          : Node_Id := No_Node;
      Kind        : Node_Kind := Node_Unknown;
      Source_Span       : Source_Range;
      Parent      : Node_Id := No_Node;
      Depth       : Natural := 0;
      Label       : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Tree_Type is private;

   procedure Clear (Tree : in out Tree_Type);

   function Add_Node
     (Tree   : in out Tree_Type;
      Kind   : Node_Kind;
      Source_Span  : Source_Range;
      Parent : Node_Id := No_Node;
      Depth  : Natural := 0;
      Label  : String := "") return Node_Id;

   function Parse (Text : String) return Tree_Type;

   function Has_Nodes (Tree : Tree_Type) return Boolean;
   function Node_Count (Tree : Tree_Type) return Natural;
   function Root (Tree : Tree_Type) return Node_Id;
   function Node (Tree : Tree_Type; Id : Node_Id) return Node_Info;
   function Node_At (Tree : Tree_Type; Index : Positive) return Node_Info;

   function Child_Count (Tree : Tree_Type; Parent : Node_Id) return Natural;
   function Child_At
     (Tree   : Tree_Type;
      Parent : Node_Id;
      Index  : Positive) return Node_Id;

   function Fingerprint (Tree : Tree_Type) return Natural;

private
   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Node_Info);

   type Tree_Type is record
      Nodes              : Node_Vectors.Vector;
      Root_Node          : Node_Id := No_Node;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Syntax_Tree;
