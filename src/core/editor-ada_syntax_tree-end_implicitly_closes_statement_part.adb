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
   function End_Implicitly_Closes_Statement_Part
     (Transient : Node_Kind;
      Owner     : Node_Kind;
      End_Code  : String) return Boolean
   is
      L : constant String := Lower (End_Code);
   begin
      if Transient = Node_Private_Part then
         return Owner = Node_Package_Declaration
           or else Owner = Node_Task_Type_Declaration
           or else Owner = Node_Single_Task_Declaration
           or else Owner = Node_Protected_Type_Declaration
           or else Owner = Node_Single_Protected_Declaration;
      elsif not Is_Transient_Statement_Part (Transient) then
         return False;
      end if;

      if Starts_With_Word (L, "end if")
        or else Starts_With_Word (L, "end case")
        or else Starts_With_Word (L, "end loop")
        or else Starts_With_Word (L, "end select")
        or else Starts_With_Word (L, "end record")
      then
         return False;
      end if;

      return Owner = Node_Package_Body
        or else Owner = Node_Subprogram_Body
        or else Owner = Node_Task_Body
        or else Owner = Node_Protected_Body
        or else Owner = Node_Entry_Body
        or else Owner = Node_Accept_Statement
        or else Owner = Node_Declare_Block;
   end End_Implicitly_Closes_Statement_Part;
