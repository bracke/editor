with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Selected_Name_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Navigation_Helpers;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Selected_Name_Suffix
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String) is
      Dot      : Token_Info;
      Selector : Token_Info;

      function At_Selected_Selector_Reserved_Boundary
        (Tok : Token_Info) return Boolean is
         L : constant String := To_String (Tok.Lower);
         T : constant String := To_String (Tok.Text);
      begin
         return Tok.Kind = Token_End_Of_Input
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else T = "=>"
           or else L = "with"
           or else L = "is"
           or else L = "begin"
           or else L = "private"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "when"
           or else L = "loop"
           or else L = "exception"
           or else L = "end";
      end At_Selected_Selector_Reserved_Boundary;
   begin
      Add_Production
        (Result, Production_Selected_Name, Origin, To_String (Origin.Text));
      Add_Production
        (Result, Production_Selected_Name_Prefix, Origin,
         To_String (Origin.Text));

      if At_End (Position) or else To_String (Current (Position).Text) /= "." then
         return;
      end if;

      Dot := Current (Position);
      Add_Production
        (Result, Production_Selected_Name_Separator, Dot,
         "selected-name separator in " & Label);
      Advance (Position);

      if At_End (Position) then
         Add_Production
           (Result, Production_Selected_Name_Missing_Selector, Dot,
            "missing selector in " & Label);
         Add_Production
           (Result, Production_Selected_Name_Missing_Selector_Recovery_Boundary, Dot,
            "selected-name missing-selector recovery boundary in " & Label);
         Add_Production
           (Result, Production_Recovery_Point, Dot,
            "expected selector in " & Label);
         return;
      end if;

      Selector := Current (Position);
      if At_Selected_Selector_Reserved_Boundary (Selector) then
         Add_Production
           (Result, Production_Selected_Name_Missing_Selector, Selector,
            "missing selector in " & Label);
         Add_Production
           (Result, Production_Selected_Name_Missing_Selector_Recovery_Boundary, Selector,
            "selected-name missing-selector recovery boundary in " & Label);
         Add_Production
           (Result, Production_Selected_Name_Reserved_Selector_Recovery_Boundary, Selector,
            "selected-name reserved selector recovery boundary in " & Label);
         Add_Production
           (Result, Production_Recovery_Point, Selector,
            "expected selector before reserved boundary in " & Label);
      elsif Selector.Kind = Token_Identifier
        or else Selector.Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Selected_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Name_Chain_Component, Selector,
            To_String (Selector.Text));
         if To_String (Selector.Lower) = "all" then
            Add_Production
              (Result, Production_Explicit_Dereference, Origin,
               To_String (Origin.Text) & ".all");
         end if;
         Add_Production
           (Result, Production_Name, Selector, To_String (Selector.Text));
         Advance (Position);
      elsif Selector.Kind = Token_String_Literal then
         Add_Production
           (Result, Production_Selected_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Literal_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Operator_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Name_Chain_Component, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Name, Selector, To_String (Selector.Text));
         Advance (Position);
      elsif Selector.Kind = Token_Character_Literal then
         Add_Production
           (Result, Production_Selected_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Literal_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Character_Selector, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Selected_Name_Chain_Component, Selector,
            To_String (Selector.Text));
         Add_Production
           (Result, Production_Name, Selector, To_String (Selector.Text));
         Advance (Position);
      else
         Add_Production
           (Result, Production_Selected_Name_Missing_Selector, Selector,
            "missing selector in " & Label);
         Add_Production
           (Result, Production_Selected_Name_Missing_Selector_Recovery_Boundary, Selector,
            "selected-name missing-selector recovery boundary in " & Label);
         Add_Production
           (Result, Production_Recovery_Point, Selector,
            "expected selector in " & Label);
         if To_String (Selector.Text) = "." then
            Advance (Position);
         end if;
      end if;
   end Parse_Selected_Name_Suffix;

end Editor.Ada_Token_Cursor.Selected_Name_Parsing;
