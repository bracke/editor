with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Aspect_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Renaming_Parsing is

   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Selected_Name_Parsing;
   use Editor.Ada_Token_Cursor.Aspect_Parsing;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Defining_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;

      if Tok.Kind = Token_String_Literal then
         Add_Production
           (Result, Production_Defining_Operator_Symbol, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif Tok.Kind = Token_Identifier or else Tok.Kind = Token_Keyword then
         Add_Production
           (Result, Production_Defining_Name, Tok, To_String (Tok.Text));
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected defining name");
      end if;
   end Parse_Defining_Name;

   procedure Parse_Defining_Program_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Origin : constant Token_Info := Current (Position);
   begin
      Parse_Defining_Name (Position, Result);
      while not At_End (Position)
        and then To_String (Current (Position).Text) = "."
      loop
         Add_Production
           (Result, Production_Selected_Name, Origin,
            "defining program unit selector");
         Advance (Position);
         Parse_Defining_Name (Position, Result);
      end loop;
   end Parse_Defining_Program_Unit_Name;

   procedure Parse_Renamed_Entity
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Label    : String := "renamed entity") is
      Tok : constant Token_Info := Current (Position);
      Probe : Cursor := Position;
      Saw_Selected : Boolean := False;
   begin
      if At_End (Position)
        or else To_String (Current (Position).Text) = ";"
      then
         return;
      end if;

      Add_Production (Result, Production_Renamed_Entity, Tok, Label);

      if Label = "renamed object" then
         Add_Production
           (Result, Production_Renamed_Object_Name, Tok,
            "renamed object name");
      elsif Label = "renamed package" then
         Add_Production
           (Result, Production_Renamed_Package_Name, Tok,
            "renamed package name");
      elsif Label = "renamed subprogram" then
         Add_Production
           (Result, Production_Renamed_Subprogram_Name, Tok,
            "renamed subprogram name");
      elsif Label = "renamed generic subprogram"
        or else Label = "renamed generic package"
      then
         Add_Production
           (Result, Production_Renamed_Generic_Unit_Name, Tok,
            "renamed generic unit name");
      end if;

      while not At_End (Probe)
        and then To_String (Current (Probe).Text) /= ";"
      loop
         if To_String (Current (Probe).Text) = "." then
            Saw_Selected := True;
         elsif Current (Probe).Kind = Token_String_Literal then
            Add_Production
              (Result, Production_Renamed_Operator_Target, Current (Probe),
               "renamed operator target");
         end if;
         Advance (Probe);
      end loop;

      if Saw_Selected then
         Add_Production
           (Result, Production_Renamed_Selected_Target, Tok,
            "renamed selected target");
      end if;

      Parse_Primary (Position, Result);
   end Parse_Renamed_Entity;

   procedure Add_Renaming_Defining_Name
     (Position : Cursor;
      Result   : in out Grammar_Result;
      Label    : String) is
   begin
      if not At_End (Position) then
         Add_Production
           (Result, Production_Renaming_Defining_Name,
            Current (Position), Label);
      end if;
   end Add_Renaming_Defining_Name;

   procedure Parse_Renaming_Tail
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String) is
   begin
      if Match_Keyword (Position, "renames") then
         if At_End (Position)
           or else To_String (Current (Position).Text) = ";"
           or else Current_Lower (Position) = "with"
         then
            Add_Production
              (Result, Production_Renaming_Recovery_Boundary, Origin,
               "missing renamed entity in " & Label);
            Add_Production
              (Result, Production_Renaming_Missing_Target_Recovery_Boundary, Origin,
               "missing renamed entity in " & Label);
            Add_Production
              (Result, Production_Recovery_Point, Origin,
               "missing renamed entity in " & Label);
         elsif Label = "renamed exception"
           and then not At_End (Position)
           and then To_String (Current (Position).Text) /= ";"
         then
            Add_Production
              (Result, Production_Exception_Renaming_Target,
               Current (Position), "renamed exception target");
            Parse_Renamed_Entity (Position, Result, Label);
         else
            Parse_Renamed_Entity (Position, Result, Label);
         end if;
      else
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected renames in " & Label);
         Add_Production
           (Result, Production_Renaming_Recovery_Boundary, Origin,
            "missing renames keyword in " & Label);
      end if;
      if Current_Lower (Position) = "with" then
         Add_Production
           (Result, Production_Renaming_Aspect_Specification,
            Current (Position), "renaming aspect placement");
         Parse_Aspect_Specification (Position, Result);
      end if;
      Skip_Balanced_To_Semicolon (Position);
   end Parse_Renaming_Tail;

   procedure Parse_Package_Renaming_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Generic_Form : Boolean := False) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Renaming_Declaration, Tok, "package renames");
      if Generic_Form then
         Add_Production
           (Result, Production_Generic_Package_Renaming_Declaration,
            Tok, "generic package renaming declaration");
      else
         Add_Production
           (Result, Production_Package_Renaming_Declaration,
            Tok, "package renaming declaration");
      end if;

      if Current_Lower (Position) = "package" then
         Advance (Position);
      end if;
      Add_Renaming_Defining_Name
        (Position, Result, "package renaming defining name");
      Parse_Defining_Program_Unit_Name (Position, Result);
      if Generic_Form then
         Parse_Renaming_Tail (Position, Result, Tok, "renamed generic package");
      else
         Parse_Renaming_Tail (Position, Result, Tok, "renamed package");
      end if;
   end Parse_Package_Renaming_Declaration;

end Editor.Ada_Token_Cursor.Renaming_Parsing;
