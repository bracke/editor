with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Ada_Syntax_Tree.Detail_Nodes;
with Editor.Ada_Syntax_Tree.Line_Classifier;
with Editor.Ada_Syntax_Tree.Statement_Details;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;

separate (Editor.Ada_Syntax_Tree)
   function Is_Transient_Statement_Part (Kind : Node_Kind) return Boolean is
   begin
      return Kind = Node_Begin_Block
        or else Kind = Node_Implicit_Begin
        or else Kind = Node_Exception_Section
        or else Kind = Node_Exception_Handler;
   end Is_Transient_Statement_Part;
