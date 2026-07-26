with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Token_Cursor.Contracts;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Aspect_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Contracts;
   use Editor.Ada_Token_Cursor.Expression_Parsing;
   use Editor.Ada_Token_Cursor.Navigation_Helpers;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Aspect_Mark
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production (Result, Production_Aspect_Mark, Tok, To_String (Tok.Text));
         Advance (Position);
         if Match_Symbol (Position, "'") then
            if Current_Lower (Position) = "class" then
               Add_Production
                 (Result, Production_Classwide_Aspect_Mark, Tok,
                  To_String (Tok.Text) & "'Class");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected Class after aspect mark apostrophe");
            end if;
         end if;
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected aspect mark");
         Parse_Expression (Position, Result);
      end if;
   end Parse_Aspect_Mark;

   procedure Parse_Aspect_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Aspect_Specification, Tok, "aspect specification");
      if Current_Lower (Position) = "with" then
         Advance (Position);
      end if;
      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ";"
        and then Current_Lower (Position) /= "is"
      loop
         declare
            Aspect_Tok : constant Token_Info := Current (Position);
            Aspect_Name : constant String := To_String (Aspect_Tok.Text);
            Is_Contract : constant Boolean := Is_Contract_Aspect_Mark (Aspect_Name);
            Is_Classwide_Contract : constant Boolean :=
              Is_Classwide_Contract_Mark (Position, Aspect_Name);
         begin
            Add_Production
              (Result, Production_Aspect_Association, Aspect_Tok,
               Aspect_Name);
            if Is_Contract then
               Add_Production
                 (Result, Production_Contract_Aspect_Association,
                  Aspect_Tok, Aspect_Name);
               Add_Production
                 (Result, Production_Contract_Aspect_Mark,
                  Aspect_Tok, Aspect_Name);
               if Is_Classwide_Contract then
                  Add_Production
                    (Result, Production_Classwide_Contract_Aspect_Mark,
                     Aspect_Tok, Aspect_Name & "'Class");
               end if;
            end if;
            Parse_Aspect_Mark (Position, Result);
            if Match_Symbol (Position, "=>") then
               if Is_Contract then
                  Add_Production
                    (Result, Production_Contract_Aspect_Value,
                     Current (Position), "contract aspect value");
                  if Lower (Aspect_Name) = "global"
                    or else Lower (Aspect_Name) = "refined_global"
                  then
                     Add_Production
                       (Result, Production_Global_Aspect_Expression,
                        Current (Position), "global aspect expression");
                  elsif Lower (Aspect_Name) = "depends"
                    or else Lower (Aspect_Name) = "refined_depends"
                    or else Ada.Strings.Fixed.Index
                      (Lower (Aspect_Name), "depends") > 0
                    or else Lower (Aspect_Name) = "initializes"
                  then
                     Add_Production
                       (Result, Production_Depends_Aspect_Expression,
                        Current (Position), "depends aspect expression");
                  elsif Lower (Aspect_Name) = "contract_cases" then
                     Add_Production
                       (Result, Production_Contract_Cases_Aspect_Expression,
                        Current (Position), "contract cases aspect expression");
                  elsif Lower (Aspect_Name) = "exceptional_cases"
                    or else Lower (Aspect_Name) = "exit_cases"
                  then
                     Add_Production
                       (Result, Production_Exceptional_Cases_Aspect_Expression,
                        Current (Position), "exceptional cases aspect expression");
                  elsif Lower (Aspect_Name) = "always_terminates" then
                     Add_Production
                       (Result, Production_Always_Terminates_Aspect_Expression,
                        Current (Position), "always terminates aspect expression");
                  elsif Lower (Aspect_Name) = "nonblocking" then
                     Add_Production
                       (Result, Production_Nonblocking_Aspect_Expression,
                        Current (Position), "nonblocking aspect expression");
                  end if;
                  declare
                     Scan  : Cursor := Position;
                     Depth : Natural := 0;
                  begin
                     while not At_End (Scan)
                       and then To_String (Current (Scan).Text) /= ";"
                       and then Current_Lower (Scan) /= "is"
                     loop
                        declare
                           ST : constant String := To_String (Current (Scan).Text);
                        begin
                           if ST = "(" then
                              Depth := Depth + 1;
                           elsif ST = ")" and then Depth > 0 then
                              Depth := Depth - 1;
                           elsif ST = "," and then Depth = 0 then
                              Advance (Scan);
                              if not At_End (Scan)
                                and then Ada.Strings.Fixed.Index
                                  (Lower (To_String (Current (Scan).Text)),
                                   "depends") > 0
                              then
                                 Add_Production
                                   (Result,
                                    Production_Depends_Aspect_Expression,
                                    Current (Scan),
                                    "depends aspect expression");
                              end if;
                           end if;
                        end;
                        Advance (Scan);
                     end loop;
                  end;
               end if;

               if To_String (Current (Position).Text) = ";"
                 or else To_String (Current (Position).Text) = ","
                 or else Current_Lower (Position) = "is"
               then
                  if Is_Contract then
                     Add_Production
                       (Result, Production_Contract_Aspect_Missing_Value_Recovery_Boundary,
                        Current (Position),
                        "contract aspect missing value recovery boundary");
                  end if;
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected aspect expression after =>");
               else
                  Parse_Expression (Position, Result);
               end if;
            end if;
            exit when not Match_Symbol (Position, ",");
         end;
      end loop;
   end Parse_Aspect_Specification;

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Parse_Attached_Aspect_Or_Semicolon
        (Position, Result, Production_Aspect_Specification);
   end Parse_Attached_Aspect_Or_Semicolon;

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Context  : Production_Kind) is
   begin
      Skip_Balanced_To (Position, "with", ";");
      if Current_Lower (Position) = "with" then
         if Context /= Production_Aspect_Specification then
            Add_Production (Result, Context, Current (Position), "aspect placement");
         end if;
         Parse_Aspect_Specification (Position, Result);
      end if;
      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      end if;
   end Parse_Attached_Aspect_Or_Semicolon;

   procedure Parse_Number_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      if Current_Lower (Position) = "with" then
         Parse_Aspect_Specification (Position, Result);
      end if;
      if To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Number_Declaration_Terminator,
            Current (Position), "number declaration terminator");
         Advance (Position);
      else
         Add_Production
           (Result,
            Production_Number_Declaration_Missing_Terminator_Recovery_Boundary,
            Current (Position),
            "number declaration missing terminator recovery boundary");
      end if;
   end Parse_Number_Declaration_Aspect_Or_Terminator;

   procedure Parse_Subprogram_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      if Current_Lower (Position) = "with" then
         Add_Production
           (Result, Production_Subprogram_Declaration_Aspect_Specification,
            Current (Position), "subprogram declaration aspect placement");
         if Has_Contract_Aspect_Before_Stop (Position, "") then
            Add_Production
              (Result, Production_Subprogram_Contract_Aspect_Placement,
               Current (Position), "subprogram declaration contract aspect placement");
         end if;
         Parse_Aspect_Specification (Position, Result);
      end if;
      if To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Subprogram_Declaration_Terminator,
            Current (Position), "subprogram declaration terminator");
         Advance (Position);
      else
         Add_Production
           (Result,
            Production_Subprogram_Declaration_Missing_Terminator_Recovery_Boundary,
            Current (Position),
            "subprogram declaration missing terminator recovery boundary");
      end if;
   end Parse_Subprogram_Declaration_Aspect_Or_Terminator;

   procedure Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      if Current_Lower (Position) = "with" then
         Add_Production
           (Result, Production_Attached_Aspect_Specification,
            Current (Position), "generic formal attached aspect");
         Add_Production
           (Result, Production_Generic_Formal_Aspect_Specification,
            Current (Position), "generic formal aspect placement");
         Parse_Aspect_Specification (Position, Result);
      end if;
      if To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Generic_Formal_Declaration_Terminator,
            Current (Position), "generic formal declaration terminator");
         Advance (Position);
      else
         Add_Production
           (Result,
            Production_Generic_Formal_Declaration_Missing_Terminator_Recovery_Boundary,
            Current (Position),
            "generic formal declaration missing terminator recovery boundary");
      end if;
   end Parse_Generic_Formal_Declaration_Aspect_Or_Terminator;

   procedure Parse_Exception_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      if Current_Lower (Position) = "with" then
         Parse_Aspect_Specification (Position, Result);
      end if;
      if To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Exception_Declaration_Terminator,
            Current (Position), "exception declaration terminator");
         Advance (Position);
      else
         Add_Production
           (Result,
            Production_Exception_Declaration_Missing_Terminator_Recovery_Boundary,
            Current (Position),
            "exception declaration missing terminator recovery boundary");
      end if;
   end Parse_Exception_Declaration_Aspect_Or_Terminator;

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Keyword  : String) is
   begin
      Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
        (Position, Result, Keyword, Production_Aspect_Specification);
   end Parse_Attached_Aspect_Before_Keyword_Or_Semicolon;

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Keyword  : String;
      Context  : Production_Kind) is
   begin
      Skip_Balanced_To (Position, "with", Keyword, ";");
      if Current_Lower (Position) = "with" then
         if Context /= Production_Aspect_Specification then
            Add_Production (Result, Context, Current (Position), "aspect placement");
         end if;
         Parse_Aspect_Specification (Position, Result);
      end if;
      if Current_Lower (Position) = Lower (Keyword) then
         Advance (Position);
      elsif To_String (Current (Position).Text) = ";" then
         Advance (Position);
      end if;
   end Parse_Attached_Aspect_Before_Keyword_Or_Semicolon;

end Editor.Ada_Token_Cursor.Aspect_Parsing;
