with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Context_Clause_Parsing is

   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;

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
      Label    : String)
     renames Editor.Ada_Token_Cursor.Selected_Name_Parsing.Parse_Selected_Name_Suffix;

   procedure Parse_Visibility_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Kind     : Production_Kind;
      Label    : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position)
        or else To_String (Current (Position).Text) = ";"
      then
         return;
      end if;

      if Current (Position).Kind /= Token_Identifier
        and then Current (Position).Kind /= Token_Keyword
      then
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected name in " & Label);
         Skip_Balanced_To (Position, ";", ",");
         return;
      end if;

      Add_Production (Result, Kind, Tok, Label);
      Add_Production (Result, Production_Name, Tok, To_String (Tok.Text));
      Advance (Position);

      loop
         exit when At_End (Position);
         if To_String (Current (Position).Text) = "." then
            Parse_Selected_Name_Suffix (Position, Result, Tok, Label);
         elsif To_String (Current (Position).Text) = "'" then
            Add_Production
              (Result, Production_Attribute_Reference, Tok, To_String (Tok.Text));
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected attribute in " & Label);
               exit;
            end if;
         else
            exit;
         end if;
      end loop;
   end Parse_Visibility_Name;

   procedure Parse_Visibility_Name_List
     (Position  : in out Cursor;
      Result    : in out Grammar_Result;
      List_Kind : Production_Kind;
      Item_Kind : Production_Kind;
      Label     : String) is
      Tok       : constant Token_Info := Current (Position);
      Saw_Name  : Boolean := False;
      Need_Name : Boolean := False;

      procedure Add_Use_Recovery_Boundary
        (Kind : Production_Kind;
         Text : String) is
      begin
         Add_Production (Result, Kind, Tok, Text);
      end Add_Use_Recovery_Boundary;

      function At_Use_Name_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
         T : constant String := To_String (Current (Position).Text);
      begin
         return At_End (Position)
           or else T = ")"
           or else L = "with"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "package"
           or else L = "procedure"
           or else L = "function"
           or else L = "generic"
           or else L = "task"
           or else L = "protected"
           or else L = "for"
           or else L = "pragma";
      end At_Use_Name_Reserved_Boundary;
   begin
      Add_Production (Result, List_Kind, Tok, Label & " list");
      loop
         exit when At_End (Position) or else To_String (Current (Position).Text) = ";";

         if At_Use_Name_Reserved_Boundary then
            Add_Use_Recovery_Boundary
              (Production_Use_Clause_Reserved_Name_Recovery_Boundary,
               "reserved boundary where name expected in " & Label & " list");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected name before reserved boundary in " & Label & " list");
            exit;
         end if;

         Parse_Visibility_Name (Position, Result, Item_Kind, Label);
         Saw_Name := True;
         Need_Name := False;
         exit when not Match_Symbol (Position, ",");
         Add_Production
           (Result, Production_Use_Clause_Separator, Current (Position),
            "use-clause name separator");
         Need_Name := True;
      end loop;

      if not Saw_Name then
         Add_Use_Recovery_Boundary
           (Production_Use_Clause_Missing_Name_Recovery_Boundary,
            "missing name in " & Label & " list");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected name in " & Label & " list");
      elsif Need_Name then
         Add_Use_Recovery_Boundary
           (Production_Use_Clause_Trailing_Separator_Recovery_Boundary,
            "trailing comma in " & Label & " list");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected name after comma in " & Label & " list");
      end if;
   end Parse_Visibility_Name_List;

   procedure Parse_Use_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      L1  : constant String := Lookahead_Lower (Position, 1);
      L2  : constant String := Lookahead_Lower (Position, 2);
   begin
      if L1 = "all" and then L2 = "type" then
         Add_Production (Result, Production_Use_All_Type_Clause, Tok, "use all type clause");
         Advance (Position);
         Advance (Position);
         Advance (Position);
         Add_Production (Result, Production_Use_All_Type_Prefix, Tok, "use all type prefix");
         Parse_Visibility_Name_List
           (Position, Result, Production_Use_Type_Subtype_Mark_List,
            Production_Use_Type_Subtype_Mark, "use all type subtype mark");
      elsif L1 = "all" then
         Add_Production (Result, Production_Use_All_Type_Clause, Tok, "malformed use all type clause");
         Advance (Position);
         Advance (Position);
         Add_Production
           (Result, Production_Use_All_Missing_Type_Recovery_Boundary,
            Tok, "missing type after all in use clause");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected type after all in use clause");
         Parse_Visibility_Name_List
           (Position, Result, Production_Use_Type_Subtype_Mark_List,
            Production_Use_Type_Subtype_Mark, "use all type subtype mark");
      elsif L1 = "type" then
         Add_Production (Result, Production_Use_Type_Clause, Tok, "use type clause");
         Advance (Position);
         Advance (Position);
         Parse_Visibility_Name_List
           (Position, Result, Production_Use_Type_Subtype_Mark_List,
            Production_Use_Type_Subtype_Mark, "use type subtype mark");
      else
         Add_Production (Result, Production_Use_Clause, Tok, "use clause");
         Advance (Position);
         Parse_Visibility_Name_List
           (Position, Result, Production_Use_Package_Name_List,
            Production_Use_Package_Name, "use package name");
      end if;

      if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Use_Clause_Missing_Terminator_Recovery_Boundary,
            Tok, "missing ; in use clause");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ; in use clause");
      end if;
   end Parse_Use_Clause;

   procedure Parse_Context_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      L0  : constant String := Current_Lower (Position);
   begin
      Add_Production (Result, Production_Context_Clause, Tok, To_String (Tok.Text));

      if L0 = "limited"
        or else L0 = "private"
        or else L0 = "with"
      then
         declare
            Saw_Limited : Boolean := False;
            Saw_Private : Boolean := False;
         begin
            if Current_Lower (Position) = "limited" then
               Saw_Limited := True;
               Add_Production (Result, Production_Limited_With_Clause, Current (Position), "limited with clause");
               Advance (Position);
            end if;

            if Current_Lower (Position) = "private" then
               Saw_Private := True;
               Add_Production (Result, Production_Private_With_Clause, Current (Position), "private with clause");
               Advance (Position);
            end if;

            if Match_Keyword (Position, "with") then
               Add_Production
                 (Result, Production_With_Clause, Tok,
                  (if Saw_Limited and then Saw_Private then "limited private with clause"
                   elsif Saw_Limited then "limited with clause"
                   elsif Saw_Private then "private with clause"
                   else "with clause"));
            else
               Add_Production (Result, Production_Recovery_Point, Tok, "expected with in context clause");
            end if;

            while not At_End (Position) and then To_String (Current (Position).Text) /= ";" loop
               if Current (Position).Kind = Token_Identifier then
                  Parse_Expression (Position, Result);
               else
                  Advance (Position);
               end if;
               exit when not Match_Symbol (Position, ",");
            end loop;

            if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
               Advance (Position);
            else
               Add_Production (Result, Production_Recovery_Point, Tok, "expected ; in context clause");
            end if;
         end;
      elsif L0 = "use" then
         Parse_Use_Clause (Position, Result);
      else
         Add_Production (Result, Production_Recovery_Point, Tok, "expected context clause");
         Skip_Balanced_To (Position, ";");
      end if;
   end Parse_Context_Clause;

end Editor.Ada_Token_Cursor.Context_Clause_Parsing;
