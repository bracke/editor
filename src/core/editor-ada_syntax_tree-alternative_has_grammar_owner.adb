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
   function Alternative_Has_Grammar_Owner
     (Alternative : Node_Kind;
      Owner       : Node_Kind) return Boolean
   is
   begin
      case Alternative is
         when Node_Elsif_Part | Node_Else_Part =>
            return Owner = Node_If_Statement
              or else Owner = Node_Elsif_Part
              or else Owner = Node_Else_Part;
         when Node_When_Alternative =>
            return Owner = Node_Case_Statement
              or else Owner = Node_When_Alternative;
         when Node_Select_Alternative =>
            return Owner = Node_Select_Statement
              or else Owner = Node_Select_Alternative;
         when Node_Exception_Section =>
            return Owner = Node_Begin_Block
              or else Owner = Node_Subprogram_Body
              or else Owner = Node_Package_Body
              or else Owner = Node_Task_Body
              or else Owner = Node_Protected_Body
              or else Owner = Node_Entry_Body
              or else Owner = Node_Accept_Statement;
         when Node_Exception_Handler =>
            return Owner = Node_Exception_Section
              or else Owner = Node_Exception_Handler;
         when Node_Variant =>
            return Owner = Node_Variant_Part
              or else Owner = Node_Variant;
         when others =>
            return True;
      end case;
   end Alternative_Has_Grammar_Owner;
