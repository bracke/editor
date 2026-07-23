with Editor.Text_Helpers;

package body Editor.Ada_Syntax_Tree.Statement_Details is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Trim (S : String) return String
     renames Editor.Text_Helpers.Trim;

   function Starts_With_Word (Text, Word : String) return Boolean
     renames Editor.Text_Helpers.Starts_With_Word;

   function Contains (Text, Fragment : String) return Boolean
     renames Editor.Text_Helpers.Contains;

   function Statement_Node_Kind (Text : String) return Node_Kind is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if Starts_With_Word (L, "if") then
         return Node_If_Statement;
      elsif Starts_With_Word (L, "elsif") then
         return Node_Elsif_Part;
      elsif Starts_With_Word (L, "else") then
         return Node_Else_Part;
      elsif Starts_With_Word (L, "case") then
         return Node_Case_Statement;
      elsif Starts_With_Word (L, "when") then
         return Node_When_Alternative;
      elsif Starts_With_Word (L, "or") then
         return Node_Select_Alternative;
      elsif Starts_With_Word (L, "loop")
        or else Starts_With_Word (L, "while")
        or else Starts_With_Word (L, "for")
      then
         return Node_Loop_Statement;
      elsif Starts_With_Word (L, "declare") then
         return Node_Declare_Block;
      elsif Starts_With_Word (L, "begin") then
         return Node_Begin_Block;
      elsif Starts_With_Word (L, "select") then
         return Node_Select_Statement;
      elsif Starts_With_Word (L, "then") and then Contains (L, "then abort") then
         return Node_Select_Alternative;
      elsif Starts_With_Word (L, "exception") then
         return Node_Exception_Section;
      elsif Starts_With_Word (L, "accept") then
         return Node_Accept_Statement;
      elsif Starts_With_Word (L, "pragma") then
         return Node_Pragma_Statement;
      elsif Starts_With_Word (L, "null") then
         return Node_Null_Statement;
      elsif Starts_With_Word (L, "return") then
         return Node_Return_Statement;
      elsif Starts_With_Word (L, "raise") then
         return Node_Raise_Statement;
      elsif Starts_With_Word (L, "exit") then
         return Node_Exit_Statement;
      elsif Starts_With_Word (L, "goto") then
         return Node_Goto_Statement;
      elsif Starts_With_Word (L, "delay") then
         return Node_Delay_Statement;
      elsif Starts_With_Word (L, "requeue") then
         return Node_Requeue_Statement;
      elsif Starts_With_Word (L, "abort") then
         return Node_Abort_Statement;
      elsif Starts_With_Word (L, "terminate") then
         return Node_Terminate_Statement;
      elsif Contains (T, ":=") then
         return Node_Assignment_Statement;
      elsif Contains (T, "(") or else Contains (T, ";") or else T /= "" then
         return Node_Call_Statement;
      else
         return Node_Unknown;
      end if;
   end Statement_Node_Kind;

end Editor.Ada_Syntax_Tree.Statement_Details;
