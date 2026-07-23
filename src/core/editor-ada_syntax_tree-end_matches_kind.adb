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
   function End_Matches_Kind (Opener : Node_Kind; End_Code : String) return Boolean is
      L : constant String := Lower (End_Code);
   begin
      if Starts_With_Word (L, "end if") then
         return Opener = Node_If_Statement
           or else Opener = Node_Elsif_Part
           or else Opener = Node_Else_Part;
      elsif Starts_With_Word (L, "end case") then
         return Opener = Node_Case_Statement
           or else Opener = Node_When_Alternative
           or else Opener = Node_Variant_Part
           or else Opener = Node_Variant;
      elsif Starts_With_Word (L, "end loop") then
         return Opener = Node_Loop_Statement;
      elsif Starts_With_Word (L, "end select") then
         return Opener = Node_Select_Statement
           or else Opener = Node_Select_Alternative;
      elsif Starts_With_Word (L, "end record") then
         return Opener = Node_Type_Declaration
           or else Opener = Node_Private_Extension_Declaration
           or else Opener = Node_Representation_Clause;
      elsif Starts_With_Word (L, "end task") then
         return Opener = Node_Task_Type_Declaration
           or else Opener = Node_Single_Task_Declaration
           or else Opener = Node_Task_Body;
      elsif Starts_With_Word (L, "end protected") then
         return Opener = Node_Protected_Type_Declaration
           or else Opener = Node_Single_Protected_Declaration
           or else Opener = Node_Protected_Body;
      elsif Starts_With_Word (L, "end") then
         --  Ada permits a plain `end Name;` for packages, subprograms,
         --  accept statements, declare blocks, and bodies.  Treat it as a
         --  grammar boundary for any non-special opener; the named target is
         --  retained in the end node label, while mismatch recovery above
         --  handles the special compound endings.
         return Opener = Node_Package_Declaration
           or else Opener = Node_Package_Body
           or else Opener = Node_Subprogram_Body
           or else Opener = Node_Task_Body
           or else Opener = Node_Protected_Body
           or else Opener = Node_Entry_Body
           or else Opener = Node_Accept_Statement
           or else Opener = Node_Declare_Block
           or else Opener = Node_Begin_Block
           or else Opener = Node_Implicit_Begin
           or else Opener = Node_Exception_Section
           or else Opener = Node_Exception_Handler;
      end if;
      return False;
   end End_Matches_Kind;
