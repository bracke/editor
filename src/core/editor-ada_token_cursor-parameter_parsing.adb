with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Contracts;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Type_Parsing;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Parameter_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   function At_Profile_Item_End
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Profile_Item_End;

   function At_Profile_Default_Reserved_Boundary
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Profile_Default_Reserved_Boundary;

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Subtype_Indication;

   procedure Parse_Defining_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      loop
         exit when At_End (Position);
         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
         then
            Add_Production
              (Result, Production_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         else
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected defining name in profile");
            exit;
         end if;
         exit when not Match_Symbol (Position, ",");
      end loop;
   end Parse_Defining_Name_List;

   procedure Parse_Profile_Default
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if Match_Symbol (Position, ":=") then
         Add_Production
           (Result, Production_Default_Expression, Tok,
            "profile default expression");
         if At_Profile_Default_Reserved_Boundary (Position) then
            Add_Production
              (Result,
               Production_Profile_Default_Reserved_Boundary_Recovery_Boundary,
               Tok,
               "profile default expression reserved boundary recovery");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected profile default expression before reserved boundary");
         else
            Parse_Expression (Position, Result);
         end if;
         Skip_Balanced_To (Position, ";", ")");
      end if;
   end Parse_Profile_Default;

   procedure Parse_Parameter_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Is_Access_Subprogram_Parameter : Boolean := False;
   begin
      Add_Production
        (Result, Production_Parameter_Specification, Tok,
         To_String (Tok.Text));
      Parse_Defining_Name_List (Position, Result);

      if not Match_Symbol (Position, ":") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected : in parameter specification");
         Skip_Balanced_To (Position, ";", ")");
         return;
      end if;

      if Current_Lower (Position) = "aliased" then
         Add_Production
           (Result, Production_Aliased_Part, Current (Position), "aliased");
         Advance (Position);
      end if;

      if Current_Lower (Position) = "in" or else Current_Lower (Position) = "out" then
         Add_Production
           (Result, Production_Parameter_Mode, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         if Current_Lower (Position) = "out" then
            Add_Production
              (Result, Production_Parameter_Mode, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         end if;
      end if;

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
        and then Lookahead_Lower (Position, 2) = "access"
      then
         Is_Access_Subprogram_Parameter :=
           Lookahead_Lower (Position, 3) = "protected"
           or else Lookahead_Lower (Position, 3) = "procedure"
           or else Lookahead_Lower (Position, 3) = "function"
           or else Lookahead_Lower (Position, 4) = "procedure"
           or else Lookahead_Lower (Position, 4) = "function";
         Parse_Subtype_Indication (Position, Result);
      elsif Current_Lower (Position) = "access" then
         Is_Access_Subprogram_Parameter :=
           Lookahead_Lower (Position, 1) = "protected"
           or else Lookahead_Lower (Position, 1) = "procedure"
           or else Lookahead_Lower (Position, 1) = "function"
           or else Lookahead_Lower (Position, 2) = "procedure"
           or else Lookahead_Lower (Position, 2) = "function";
         Parse_Subtype_Indication (Position, Result);
      elsif not At_Profile_Item_End (Position)
        and then To_String (Current (Position).Text) /= ":="
      then
         Parse_Subtype_Indication (Position, Result);
      end if;

      if Is_Access_Subprogram_Parameter
        and then To_String (Current (Position).Text) = ":="
      then
         Add_Production
           (Result, Production_Access_Subprogram_Parameter_Default,
            Current (Position),
            "access-to-subprogram parameter default");
      end if;

      Parse_Profile_Default (Position, Result);
      if not At_Profile_Item_End (Position) then
         Skip_Balanced_To (Position, ";", ")");
      end if;
   end Parse_Parameter_Specification;

   procedure Parse_Parameter_Profile
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      Add_Production (Result, Production_Parameter_Profile, Tok, "parameter profile");
      Add_Production
        (Result, Production_Parameter_Profile_Open_Delimiter, Tok,
         "parameter profile open delimiter");
      Advance (Position);

      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         Parse_Parameter_Specification (Position, Result);
         exit when To_String (Current (Position).Text) = ")";
         if To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Parameter_Profile_Separator, Current (Position),
               "parameter profile separator");
            Advance (Position);
         else
            exit;
         end if;
      end loop;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Parameter_Profile_Close_Delimiter, Current (Position),
            "parameter profile close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Parameter_Profile_Missing_Close_Recovery_Boundary, Tok,
            "parameter profile missing close recovery boundary");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in parameter profile");
      end if;
   end Parse_Parameter_Profile;

end Editor.Ada_Token_Cursor.Parameter_Parsing;
