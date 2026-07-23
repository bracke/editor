with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Contracts;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Aggregate_Parsing;
with Editor.Ada_Token_Cursor.Context_Clause_Parsing;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Pragma_Parsing;
with Editor.Ada_Token_Cursor.Primary_Parsing;
with Editor.Ada_Token_Cursor.Entry_Parsing;
with Editor.Ada_Token_Cursor.Aspect_Parsing;
with Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing;
with Editor.Ada_Token_Cursor.Generic_Formal_Parsing;
with Editor.Ada_Token_Cursor.Renaming_Parsing;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Constraint_Parsing;
with Editor.Ada_Token_Cursor.Type_Parsing;
with Editor.Ada_Token_Cursor.Representation_Parsing;
with Editor.Ada_Token_Cursor.Tokenization;

use Editor.Ada_Token_Cursor.Aspect_Parsing;

separate (Editor.Ada_Token_Cursor.Parsing_Phases_Engine)
   procedure Parse_Subprogram_Construct
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      pragma Suppress (Overflow_Check);
      Tok          : constant Token_Info := Current (Position);
      Subprogram   : constant String := Current_Lower (Position);
      Probe        : Cursor := Position;
      Saw_Is       : Boolean := False;
      Saw_New      : Boolean := False;
      Saw_Abstract : Boolean := False;
      Saw_Null     : Boolean := False;
      Saw_Expr     : Boolean := False;
      Saw_Renames  : Boolean := False;
      Body_Name    : Unbounded_String := Null_Unbounded_String;
   begin
      if At_End (Position) then
         return;
      end if;

      while not At_End (Probe) and then To_String (Current (Probe).Text) /= ";" loop
         if Current_Lower (Probe) = "renames" then
            Saw_Renames := True;
            exit;
         elsif Current_Lower (Probe) = "is" then
            Saw_Is := True;
            Advance (Probe);
            if Current_Lower (Probe) = "new" then
               Saw_New := True;
            elsif Current_Lower (Probe) = "abstract" then
               Saw_Abstract := True;
            elsif Current_Lower (Probe) = "null" then
               Saw_Null := True;
            elsif Subprogram = "function" and then To_String (Current (Probe).Text) = "(" then
               Saw_Expr := True;
            end if;
            exit;
         end if;
         Advance (Probe);
      end loop;

      if Saw_New then
         Parse_Generic_Instantiation_Declaration
           (Position, Result, Subprogram);
         return;
      elsif Saw_Abstract then
         Add_Production (Result, Production_Abstract_Subprogram_Declaration, Tok, Subprogram & " abstract declaration");
      elsif Saw_Null and then Subprogram = "procedure" then
         Add_Production (Result, Production_Null_Procedure_Declaration, Tok, "null procedure declaration");
      elsif Saw_Expr then
         Add_Production (Result, Production_Expression_Function_Declaration, Tok, "expression function declaration");
      elsif Saw_Is then
         Add_Production (Result, Production_Subprogram_Body, Tok, Subprogram & " body");
         if Has_Token_Before_Semicolon (Position, "separate") then
            Add_Production (Result, Production_Subprogram_Body_Stub, Tok, Subprogram & " body stub");
            Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "subprogram body stub kind keyword");
            Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
            Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
         elsif not Saw_Expr then
            null;
         end if;
      elsif Saw_Renames then
         Add_Production (Result, Production_Renaming_Declaration, Tok, Subprogram & " renames");
         Add_Production
           (Result, Production_Subprogram_Renaming_Declaration, Tok,
            Subprogram & " renaming declaration");
      else
         Add_Production (Result, Production_Subprogram_Declaration, Tok, Subprogram & " declaration");
      end if;

      Advance (Position);
      if not At_End (Position) then
         Add_Production
           (Result, Production_Subprogram_Defining_Designator,
            Current (Position), "subprogram defining designator");
         Body_Name := Current (Position).Lower;
         if Saw_Renames then
            Add_Production
              (Result, Production_Renaming_Defining_Name,
               Current (Position), "subprogram renaming defining name");
         end if;
      end if;
      Parse_Defining_Program_Unit_Name (Position, Result);
      if To_String (Current (Position).Text) = "(" then
         if Saw_Renames then
            Add_Production
              (Result, Production_Renaming_Parameter_Profile,
               Current (Position), "subprogram renaming profile");
         end if;
         Parse_Parameter_Profile (Position, Result);
      end if;
      if Current_Lower (Position) = "return" then
         Advance (Position);
         if not At_End (Position) then
            Add_Production
              (Result, Production_Function_Result_Subtype,
               Current (Position), "function result subtype");
            if Saw_Renames then
               Add_Production
                 (Result, Production_Renaming_Result_Subtype,
                  Current (Position), "subprogram renaming result subtype");
            end if;
         end if;
         Parse_Subtype_Indication (Position, Result);
      end if;

      if Saw_Renames then
         Parse_Renaming_Tail (Position, Result, Tok, "renamed subprogram");
      elsif Saw_Is then
         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Subprogram_Body_Aspect_Specification,
               Current (Position), "subprogram body aspect placement");
            if Has_Contract_Aspect_Before_Stop (Position, "is") then
               Add_Production
                 (Result, Production_Subprogram_Contract_Aspect_Placement,
                  Current (Position), "subprogram body contract aspect placement");
               Add_Production
                 (Result, Production_Subprogram_Body_Contract_Aspect_Placement,
                  Current (Position), "subprogram body contract aspect placement");
            end if;
            Parse_Aspect_Specification (Position, Result);
         end if;
         Advance_Through_Keyword (Position, "is");
         if Saw_Abstract then
            --  Abstract subprogram declarations use a completion keyword after
            --  ``is``.  Consume that keyword before looking for a trailing
            --  aspect specification so ``is abstract with ...;`` does not get
            --  flattened into semicolon recovery.
            if Current_Lower (Position) = "abstract" then
               Advance (Position);
            end if;
            if Current_Lower (Position) = "with"
              and then Has_Contract_Aspect_Before_Stop (Position, "")
            then
               Add_Production
                 (Result, Production_Abstract_Subprogram_Contract_Aspect_Placement,
                  Current (Position), "abstract subprogram contract aspect placement");
            end if;
            Parse_Subprogram_Declaration_Aspect_Or_Terminator (Position, Result);
         elsif Saw_Null then
            --  Null procedure declarations have the same completion/aspect
            --  shape: ``procedure P is null with ...;``.  Keep the attached
            --  aspects visible for semantic colouring and Outline metadata.
            if Current_Lower (Position) = "null" then
               Advance (Position);
            end if;
            if Current_Lower (Position) = "with"
              and then Has_Contract_Aspect_Before_Stop (Position, "")
            then
               Add_Production
                 (Result, Production_Null_Procedure_Contract_Aspect_Placement,
                  Current (Position), "null procedure contract aspect placement");
            end if;
            Parse_Subprogram_Declaration_Aspect_Or_Terminator (Position, Result);
         elsif Saw_Expr then
            Parse_Expression (Position, Result);
            if Current_Lower (Position) = "with"
              and then Has_Contract_Aspect_Before_Stop (Position, "")
            then
               Add_Production
                 (Result, Production_Expression_Function_Contract_Aspect_Placement,
                  Current (Position), "expression function contract aspect placement");
            end if;
            Parse_Subprogram_Declaration_Aspect_Or_Terminator (Position, Result);
         elsif Current_Lower (Position) = "separate" then
            Advance (Position);
            --  Subprogram body stubs have body-stub aspect placement, not
            --  ordinary subprogram-declaration aspect placement.  Keep the
            --  body-stub-specific marker so downstream Outline/colouring
            --  consumers can distinguish ``procedure P is separate with ...``
            --  from a normal subprogram declaration or body contract without
            --  reparsing the source text.
            Parse_Attached_Aspect_Or_Semicolon
              (Position, Result, Production_Body_Stub_Aspect_Specification);
         else
            Add_Subprogram_Body_Part_Productions
              (Position, Result, To_String (Body_Name));
         end if;
      else
         Parse_Subprogram_Declaration_Aspect_Or_Terminator (Position, Result);
      end if;
   end Parse_Subprogram_Construct;
