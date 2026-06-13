with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Syntax;

package body Editor.Syntax.Tests is

   function Name (T : Syntax_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax.Tests");
   end Name;

   procedure Test_Ada_Lexical_Basics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Saw_Keyword : Boolean := False;
      Saw_String  : Boolean := False;
      Final       : Editor.Syntax.Lexical_State;

      procedure Visit (Start_Col, End_Col : Natural; Kind : Editor.Syntax.Token_Kind) is
         pragma Unreferenced (Start_Col, End_Col);
      begin
         if Kind = Editor.Syntax.Keyword then
            Saw_Keyword := True;
         elsif Kind = Editor.Syntax.String_Literal then
            Saw_String := True;
         end if;
      end Visit;
   begin
      Editor.Syntax.Classify_Line
        ("procedure Draw is S : String := ""hi""; end;",
         Editor.Syntax.Normal_State, Visit'Access, Final);
      Assert (Saw_Keyword, "Ada keyword should be tokenized");
      Assert (Saw_String, "Ada string literal should be tokenized");
      Assert (Final = Editor.Syntax.Normal_State, "complete line should recover to normal lexical state");
   end Test_Ada_Lexical_Basics;

   procedure Test_Unterminated_String_State (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Final : Editor.Syntax.Lexical_State;
      procedure Visit (Start_Col, End_Col : Natural; Kind : Editor.Syntax.Token_Kind) is
         pragma Unreferenced (Start_Col, End_Col, Kind);
      begin
         null;
      end Visit;
   begin
      Editor.Syntax.Classify_Line
        ("Name := ""unterminated", Editor.Syntax.Normal_State, Visit'Access, Final);
      Assert (Final = Editor.Syntax.In_Unterminated_String,
              "unterminated strings must propagate lexical state");
   end Test_Unterminated_String_State;

   procedure Register_Tests (T : in out Syntax_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Ada_Lexical_Basics'Access, "Ada lexical basics");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unterminated_String_State'Access, "unterminated string state");
   end Register_Tests;

end Editor.Syntax.Tests;
