with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Tokenization;

package body Editor.Ada_Token_Cursor is

   pragma Suppress (Overflow_Check);

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Tokenize (Text : String) return Token_Stream is
   begin
      return Tokenization.Tokenize (Text);
   end Tokenize;

   function Length (Stream : Token_Stream) return Natural is
   begin
      return Tokenization.Length (Stream);
   end Length;

   function Token_At (Stream : Token_Stream; Index : Positive) return Token_Info is
   begin
      return Tokenization.Token_At (Stream, Index);
   end Token_At;

   function First (Stream : Token_Stream) return Cursor is
   begin
      return Tokenization.First (Stream);
   end First;

   function At_End (Position : Cursor) return Boolean is
   begin
      return Tokenization.At_End (Position);
   end At_End;

   function Current (Position : Cursor) return Token_Info is
   begin
      return Tokenization.Current (Position);
   end Current;

   procedure Advance (Position : in out Cursor) is
   begin
      Tokenization.Advance (Position);
   end Advance;

   function Mark (Position : Cursor) return Natural is
   begin
      return Tokenization.Mark (Position);
   end Mark;

   procedure Restore (Position : in out Cursor; To_Mark : Natural) is
   begin
      Tokenization.Restore (Position, To_Mark);
   end Restore;

   function Match_Keyword (Position : in out Cursor; Keyword : String) return Boolean is
   begin
      if not At_End (Position)
        and then To_String (Current (Position).Lower) = Lower (Keyword)
        and then Current (Position).Kind = Token_Keyword
      then
         Advance (Position);
         return True;
      end if;
      return False;
   end Match_Keyword;

   function Match_Symbol (Position : in out Cursor; Symbol : String) return Boolean is
   begin
      if not At_End (Position) and then To_String (Current (Position).Text) = Symbol then
         Advance (Position);
         return True;
      end if;
      return False;
   end Match_Symbol;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String) is
      Info : Production_Info;
   begin
      Info.Kind := Kind;
      Info.Line := Tok.Line;
      Info.Column := Tok.Column;
      Info.Label := To_Unbounded_String (Label);
      Result.Productions.Append (Info);
   end Add_Production;

   function Lookahead_Lower (Position : Cursor; Offset : Natural) return String is
      Index : constant Natural := Position.Index + Offset;
   begin
      if Index < 1 or else Index > Natural (Position.Stream.Tokens.Length) then
         return "";
      end if;
      return To_String (Position.Stream.Tokens (Positive (Index)).Lower);
   end Lookahead_Lower;

   function Lookahead_Kind (Position : Cursor; Offset : Natural) return Token_Kind is
      Index : constant Natural := Position.Index + Offset;
   begin
      if Index < 1 or else Index > Natural (Position.Stream.Tokens.Length) then
         return Token_End_Of_Input;
      end if;
      return Position.Stream.Tokens (Positive (Index)).Kind;
   end Lookahead_Kind;

   function Current_Lower (Position : Cursor) return String is
   begin
      return To_String (Current (Position).Lower);
   end Current_Lower;

   procedure Skip_Balanced_To_Semicolon (Position : in out Cursor) is
      Paren_Depth : Natural := 0;
   begin
      while not At_End (Position) loop
         declare
            T : constant String := To_String (Current (Position).Text);
         begin
            if T = "(" then
               Paren_Depth := Paren_Depth + 1;
            elsif T = ")" and then Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            elsif T = ";" and then Paren_Depth = 0 then
               Advance (Position);
               exit;
            end if;
         end;
         Advance (Position);
      end loop;
   end Skip_Balanced_To_Semicolon;

   procedure Advance_Through_Keyword (Position : in out Cursor; Keyword : String) is
   begin
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
         begin
            Advance (Position);
            exit when L = Lower (Keyword);
         end;
      end loop;
   end Advance_Through_Keyword;


   function Has_Token_Before_Semicolon (Position : Cursor; Text : String) return Boolean is
      Probe       : Cursor := Position;
      Paren_Depth : Natural := 0;
      Wanted      : constant String := Lower (Text);
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            if L = Wanted or else T = Text then
               return True;
            elsif T = "(" then
               Paren_Depth := Paren_Depth + 1;
            elsif T = ")" and then Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            elsif T = ";" and then Paren_Depth = 0 then
               return False;
            end if;
            Advance (Probe);
         end;
      end loop;
      return False;
   end Has_Token_Before_Semicolon;

   function Has_Token_Between
     (Stream : Token_Stream;
      First  : Natural;
      Last   : Natural;
      Text   : String) return Boolean
   is
      Wanted : constant String := Lower (Text);
   begin
      if First = 0 or else Last = 0 or else First > Last then
         return False;
      end if;

      for Index in First .. Natural'Min (Last, Length (Stream)) loop
         declare
            Tok : constant Token_Info := Token_At (Stream, Index);
            Raw : constant String := To_String (Tok.Text);
         begin
            if Lower (Raw) = Wanted or else Raw = Text then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Token_Between;

   procedure Skip_Balanced_To
     (Position : in out Cursor;
      Stop_1   : String;
      Stop_2   : String := "";
      Stop_3   : String := "") is
      Paren_Depth : Natural := 0;
   begin
      while not At_End (Position) loop
         declare
            T : constant String := To_String (Current (Position).Text);
            L : constant String := Current_Lower (Position);
         begin
            exit when Paren_Depth = 0
              and then (T = Stop_1 or else L = Lower (Stop_1)
                        or else (Stop_2'Length > 0 and then (T = Stop_2 or else L = Lower (Stop_2)))
                        or else (Stop_3'Length > 0 and then (T = Stop_3 or else L = Lower (Stop_3))));
            if T = "(" then
               Paren_Depth := Paren_Depth + 1;
            elsif T = ")" and then Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            end if;
            Advance (Position);
         end;
      end loop;
   end Skip_Balanced_To;



   function Is_Contract_Aspect_Mark (Name : String) return Boolean is
      L : constant String := Lower (Name);
   begin
      --  Ada contract-related aspects have expression/list payloads that are
      --  valuable to retain for IDE-grade Outline metadata and semantic
      --  colouring.  This is only syntactic classification; legality,
      --  staticness, visibility, and entity matching remain outside the token
      --  cursor.
      return L = "pre"
        or else L = "post"
        or else L = "type_invariant"
        or else L = "type_invariant'class"
        or else L = "dynamic_predicate"
        or else L = "static_predicate"
        or else L = "predicate"
        or else L = "global"
        or else L = "depends"
        or else L = "refined_global"
        or else L = "refined_depends"
        or else L = "initializes"
        or else L = "contract_cases"
        or else L = "exceptional_cases"
        or else L = "exit_cases"
        or else L = "always_terminates"
        or else L = "nonblocking"
        or else L = "pre'class"
        or else L = "post'class";
   end Is_Contract_Aspect_Mark;



   function Is_Classwide_Contract_Mark
     (Position    : Cursor;
      Aspect_Name : String) return Boolean is
      Probe : Cursor := Position;
   begin
      --  ``Pre'Class`` and ``Post'Class`` are contract aspects whose
      --  class-wide suffix matters to IDE consumers.  Detect the suffix with
      --  bounded local lookahead before Parse_Aspect_Mark consumes it.
      if not Is_Contract_Aspect_Mark (Aspect_Name) then
         return False;
      end if;
      if Lower (Aspect_Name) /= "pre" and then Lower (Aspect_Name) /= "post" then
         return False;
      end if;

      Advance (Probe);
      if At_End (Probe) or else To_String (Current (Probe).Text) /= "'" then
         return False;
      end if;

      Advance (Probe);
      return not At_End (Probe) and then Current_Lower (Probe) = "class";
   end Is_Classwide_Contract_Mark;

   function Has_Contract_Aspect_Before_Stop
     (Position     : Cursor;
      Stop_Keyword : String) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      --  Placement checks need to know whether an attached aspect list carries
      --  a contract aspect without consuming the source.  This remains a
      --  bounded syntactic scan over the aspect_specification header and does
      --  not attempt expression legality or entity resolution.
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            exit when Depth = 0
              and then (T = ";"
                        or else (Stop_Keyword'Length > 0
                                 and then L = Lower (Stop_Keyword)));

            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
            then
               if Is_Contract_Aspect_Mark (To_String (Current (Probe).Text)) then
                  return True;
               end if;
            end if;

            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" and then Depth > 0 then
               Depth := Depth - 1;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Has_Contract_Aspect_Before_Stop;

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Expression (Position : in out Cursor; Result : in out Grammar_Result);
   procedure Parse_Primary (Position : in out Cursor; Result : in out Grammar_Result);
   procedure Parse_Subtype_Mark
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Defining_Program_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Subprogram_Construct
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Tok      : Token_Info);
   procedure Parse_Record_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Reduction_Argument_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Attribute_Name : String);
   procedure Parse_Aspect_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Context  : Production_Kind);

   procedure Parse_Subprogram_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   function Starts_Strong_Package_Declarative_Item
     (Position : Cursor) return Boolean;

   procedure Parse_Number_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Exception_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Keyword  : String);

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Keyword  : String;
      Context  : Production_Kind);

   function Has_Top_Level_Arrow_Before_Association_End
     (Position : Cursor) return Boolean;

   function Has_Top_Level_With_Before_Association_End
     (Position : Cursor) return Boolean;

   function Has_Top_Level_With_Delta_Before_Association_End
     (Position : Cursor) return Boolean;

   procedure Parse_Component_Association_Item
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info);

   function At_Profile_Item_End (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
   begin
      return At_End (Position) or else T = ";" or else T = ")";
   end At_Profile_Item_End;

   function Access_Subprogram_Result_Has_Constraint
     (Position : Cursor) return Boolean is
      Depth : Natural := 0;
   begin
      for Index in Position.Index .. Natural (Position.Stream.Tokens.Length) loop
         declare
            Text : constant String :=
              To_String (Position.Stream.Tokens (Positive (Index)).Text);
            Lower : constant String :=
              To_String (Position.Stream.Tokens (Positive (Index)).Lower);
         begin
            if Text = "(" then
               if Depth = 0 then
                  return True;
               end if;
               Depth := Depth + 1;
            elsif Text = ")" then
               exit when Depth = 0;
               Depth := Depth - 1;
            elsif Depth = 0 and then (Lower = "range" or else Lower = "digits" or else Lower = "delta") then
               return True;
            elsif Depth = 0 and then (Text = ";" or else Text = ",") then
               return False;
            end if;
         end;
      end loop;
      return False;
   end Access_Subprogram_Result_Has_Constraint;

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

   function At_Component_Default_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "with"
        or else L = "is"
        or else L = "begin"
        or else L = "private"
        or else L = "end"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "do";
   end At_Component_Default_Reserved_Boundary;



   function At_Profile_Default_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ")"
        or else T = ","
        or else T = "=>"
        or else L = "is"
        or else L = "with"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "end";
   end At_Profile_Default_Reserved_Boundary;



   function At_Number_Initialization_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "with"
        or else L = "is"
        or else L = "begin"
        or else L = "private"
        or else L = "end"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "do";
   end At_Number_Initialization_Reserved_Boundary;

   function At_Object_Subtype_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = ":="
        or else L = "is"
        or else L = "with"
        or else L = "begin"
        or else L = "private"
        or else L = "end"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "do";
   end At_Object_Subtype_Reserved_Boundary;

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

   procedure Parse_Discriminant_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Discriminant_Specification, Tok,
         To_String (Tok.Text));
      Add_Production
        (Result, Production_Discriminant_Defining_Name_List, Tok,
         "discriminant defining name list");
      Parse_Defining_Name_List (Position, Result);

      if not Match_Symbol (Position, ":") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected : in discriminant specification");
         Skip_Balanced_To (Position, ";", ")");
         return;
      end if;

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
      then
         Add_Production
           (Result, Production_Discriminant_Null_Exclusion, Current (Position),
            "discriminant null exclusion");
      end if;

      if not At_Profile_Item_End (Position)
        and then To_String (Current (Position).Text) /= ":="
      then
         if Current_Lower (Position) = "access"
           or else (Current_Lower (Position) = "not"
                    and then Lookahead_Lower (Position, 1) = "null"
                    and then Lookahead_Lower (Position, 2) = "access")
         then
            Add_Production
              (Result, Production_Discriminant_Access_Definition,
               Current (Position), "access discriminant definition");
         else
            Add_Production
              (Result, Production_Discriminant_Subtype_Indication,
               Current (Position), "discriminant subtype indication");
         end if;
         Parse_Subtype_Indication (Position, Result);
      end if;
      if To_String (Current (Position).Text) = ":=" then
         Add_Production
           (Result, Production_Discriminant_Default_Expression, Current (Position),
            "discriminant default expression");
         declare
            Probe : Cursor := Position;
         begin
            if Match_Symbol (Probe, ":=")
              and then At_Profile_Default_Reserved_Boundary (Probe)
            then
               Add_Production
                 (Result,
                  Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "discriminant default reserved-boundary recovery boundary");
            end if;
         end;
      end if;
      Parse_Profile_Default (Position, Result);
      if not At_Profile_Item_End (Position) then
         Skip_Balanced_To (Position, ";", ")");
      end if;
   end Parse_Discriminant_Specification;

   procedure Parse_Discriminant_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      Add_Production (Result, Production_Discriminant_Part, Tok, "discriminant part");
      Add_Production
        (Result, Production_Discriminant_Part_Open_Delimiter, Tok,
         "discriminant part open delimiter");
      Advance (Position);

      if To_String (Current (Position).Text) = "<>" then
         --  Ada unknown discriminant parts use the compact ``(<>)``
         --  grammar.  They are not discriminant specifications and should
         --  not be sent through profile-item recovery, where the box token
         --  would otherwise be treated as a malformed defining name.
         Add_Production
           (Result, Production_Unknown_Discriminant_Part, Current (Position),
            "unknown discriminant part");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Known_Discriminant_Part, Current (Position),
            "known discriminant part");
         while not At_End (Position)
           and then To_String (Current (Position).Text) /= ")"
         loop
            Parse_Discriminant_Specification (Position, Result);
            exit when To_String (Current (Position).Text) = ")";
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Discriminant_Specification_Separator,
                  Current (Position), "discriminant specification separator");
               Advance (Position);
            else
               exit;
            end if;
         end loop;
      end if;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Discriminant_Part_Close_Delimiter, Current (Position),
            "discriminant part close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Discriminant_Part_Missing_Close_Recovery_Boundary,
            Tok, "discriminant part missing close recovery boundary");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in discriminant part");
      end if;
   end Parse_Discriminant_Part;

   procedure Parse_Enumeration_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      Add_Production
        (Result, Production_Enumeration_Type_Definition, Tok,
         "enumeration type definition");
      Add_Production
        (Result, Production_Enumeration_Type_Open_Delimiter, Tok,
         "enumeration type open delimiter");
      Advance (Position);

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Lit : constant Token_Info := Current (Position);
         begin
            if Lit.Kind = Token_Identifier
              or else Lit.Kind = Token_Character_Literal
            then
               Add_Production
                 (Result, Production_Enumeration_Literal, Lit,
                  To_String (Lit.Text));
            end if;
            Advance (Position);
            exit when To_String (Current (Position).Text) /= ",";
            Add_Production
              (Result, Production_Enumeration_Literal_Separator, Current (Position),
               "enumeration literal separator");
            Advance (Position);
         end;
      end loop;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Enumeration_Type_Close_Delimiter, Current (Position),
            "enumeration type close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Enumeration_Type_Missing_Close_Recovery_Boundary,
            Tok, "enumeration type missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in enumeration type definition");
      end if;
   end Parse_Enumeration_Type_Definition;

   procedure Parse_Discrete_Choice_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String);


   procedure Parse_Component_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Component_Declaration, Tok,
         To_String (Tok.Text));
      Add_Production
        (Result, Production_Component_Defining_Name_List, Tok,
         "component defining name list");
      Parse_Defining_Name_List (Position, Result);

      if not Match_Symbol (Position, ":") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected : in component declaration");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      Add_Production
        (Result, Production_Component_Definition, Current (Position),
         "component definition");

      if Current_Lower (Position) = "aliased" then
         Add_Production
           (Result, Production_Aliased_Part, Current (Position), "aliased");
         Advance (Position);
      end if;

      if not At_End (Position)
        and then To_String (Current (Position).Text) /= ":="
        and then To_String (Current (Position).Text) /= ";"
      then
         Add_Production
           (Result, Production_Component_Subtype_Indication, Current (Position),
            "component subtype indication");
         Parse_Subtype_Indication (Position, Result);
      end if;

      if Match_Symbol (Position, ":=") then
         if At_Component_Default_Reserved_Boundary (Position) then
            Add_Production
              (Result,
               Production_Component_Default_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "component default reserved-boundary recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected component default expression before boundary");
         else
            Add_Production
              (Result, Production_Component_Default_Expression, Current (Position),
               "component default expression");
            Add_Production
              (Result, Production_Default_Expression, Current (Position),
               "component default expression");
            Parse_Expression (Position, Result);
         end if;
      end if;

      Parse_Attached_Aspect_Or_Semicolon (Position, Result);
   end Parse_Component_Declaration;

   procedure Parse_Record_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Seen_Variant_Part : Boolean := False;

      procedure Mark_Variant_Choice_Details (From : Cursor) is
         Probe : Cursor := From;
         At_Choice_Start : Boolean := True;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
               L : constant String := Current_Lower (Probe);
            begin
               exit when T = "=>" or else T = ";" or else L = "when" or else L = "end";
               if L = "others" then
                  Add_Production
                    (Result, Production_Variant_Others_Choice,
                     Current (Probe), "variant others choice");
                  At_Choice_Start := False;
               elsif T = "|" then
                  Add_Production
                    (Result, Production_Variant_Choice_Separator,
                     Current (Probe), "variant choice separator");
                  At_Choice_Start := True;
               elsif T = ".." then
                  Add_Production
                    (Result, Production_Variant_Range_Choice,
                     Current (Probe), "variant range choice");
                  At_Choice_Start := False;
               elsif At_Choice_Start then
                  Add_Production
                    (Result, Production_Variant_Discrete_Choice,
                     Current (Probe), "variant discrete choice");
                  At_Choice_Start := False;
               end if;
               Advance (Probe);
            end;
         end loop;
      end Mark_Variant_Choice_Details;
   begin
      Add_Production (Result, Production_Record_Definition, Tok, "record definition");
      if Current_Lower (Position) = "record" then
         Advance (Position);
      end if;
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant String := To_String (Current (Position).Text);
            Item_Tok : constant Token_Info := Current (Position);
         begin
            if L = "end" and then Lookahead_Lower (Position, 1) = "case" then
               Advance (Position);
               Advance (Position);
               if To_String (Current (Position).Text) = ";" then
                  Advance (Position);
               end if;
            elsif L = "end" then
               exit;
            elsif L = "case" then
               if Seen_Variant_Part then
                  Add_Production
                    (Result, Production_Nested_Variant_Part, Item_Tok,
                     "nested variant part");
               end if;
               Seen_Variant_Part := True;
               Add_Production (Result, Production_Variant_Part, Item_Tok, "variant part");
               Advance (Position);
               if not At_End (Position) and then Current_Lower (Position) /= "is" then
                  Add_Production
                    (Result, Production_Variant_Part_Discriminant_Name,
                     Current (Position), "variant part discriminant name");
                  Add_Production
                    (Result, Production_Name, Current (Position),
                     To_String (Current (Position).Text));
                  while not At_End (Position)
                    and then Current_Lower (Position) /= "is"
                  loop
                     Advance (Position);
                  end loop;
               end if;
               if Current_Lower (Position) = "is" then
                  Advance (Position);
               else
                  Add_Production
                    (Result, Production_Recovery_Point, Item_Tok,
                     "expected is in variant part");
                  Add_Production
                    (Result, Production_Variant_Recovery_Boundary, Item_Tok,
                     "variant part recovery boundary");
                  Advance_Through_Keyword (Position, "is");
               end if;
            elsif L = "when" then
               Add_Production (Result, Production_Variant, Item_Tok, "variant");
               Advance (Position);
               Add_Production
                 (Result, Production_Variant_Choice_List, Current (Position),
                  "variant choice list");
               Mark_Variant_Choice_Details (Position);
               Parse_Discrete_Choice_List (Position, Result, "=>");
               if To_String (Current (Position).Text) = "=>" then
                  Add_Production
                    (Result, Production_Variant_Choice_Arrow, Current (Position),
                     "variant choice arrow");
                  Advance (Position);
                  Add_Production
                    (Result, Production_Variant_Component_Part, Current (Position),
                     "variant component part");
               else
                  Add_Production
                    (Result, Production_Recovery_Point, Item_Tok,
                     "expected => in variant");
                  Add_Production
                    (Result, Production_Variant_Recovery_Boundary, Item_Tok,
                     "variant recovery boundary");
               end if;
            elsif Seen_Variant_Part and then L = "null" then
               Add_Production
                 (Result, Production_Variant_Null_Component_Part, Item_Tok,
                  "variant null component part");
               Advance (Position);
               if To_String (Current (Position).Text) = ";" then
                  Advance (Position);
               end if;
            elsif Current (Position).Kind = Token_Identifier and then Has_Token_Before_Semicolon (Position, ":") then
               if Seen_Variant_Part then
                  Add_Production
                    (Result, Production_Variant_Component_Declaration, Item_Tok,
                     "variant component declaration");
               end if;
               Parse_Component_Declaration (Position, Result);
            elsif T = ";" then
               Advance (Position);
            else
               Advance (Position);
            end if;
         end;
      end loop;
      if Match_Keyword (Position, "end") then
         if Current_Lower (Position) = "case" then
            Advance (Position);
         end if;
         if Current_Lower (Position) = "record" then
            Advance (Position);
         end if;
      end if;
      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      end if;
   end Parse_Record_Definition;

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
         --  Ada selected_names permit operator_symbol selectors such as
         --  Math."+".  Retain them as selectors rather than treating the
         --  string literal as an expression literal.  Also expose the generic
         --  selector node so name consumers can count literal selectors through
         --  the same path as identifier selectors.
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
         --  Character literal selectors are valid selected_name selectors for
         --  enumeration literals and must remain visible through the generic
         --  selector node as well as the literal-specific node.
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
            --  Avoid re-reading the same separator forever for hostile
            --  selected-name fragments such as A..B; leave normal statement
            --  terminators and delimiters in place for the caller to sync.
            Advance (Position);
         end if;
      end if;
   end Parse_Selected_Name_Suffix;


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
      --  A use_clause is both a context item and a declarative item.  Keep the
      --  use-clause grammar separate from context-clause ownership so package
      --  declarative parts can expose ``use``, ``use type``, and
      --  ``use all type`` without spuriously manufacturing a context clause.
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
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Context_Clause;


   procedure Parse_Association_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Qualified_Expression_Operand : Boolean := False);

   procedure Add_Statement_Name_Suffix_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result;
      Start_At : Natural;
      End_At   : Natural;
      For_Assignment : Boolean) is
      Has_Selected        : Boolean := False;
      Has_Paren           : Boolean := False;
      Has_Range           : Boolean := False;
      Has_All             : Boolean := False;
      Has_Arrow           : Boolean := False;
      Has_Selected_Call   : Boolean := False;
      Has_Indexed_Prefix  : Boolean := False;
      Has_Dispatching     : Boolean := False;
      Last_Dot_Index      : Natural := 0;
      First_Paren_Index   : Natural := 0;

      procedure Add_Actual_Part_Delimiter_Productions is
         Depth     : Natural := 0;
         Saw_Open  : Boolean := False;
         Saw_Close : Boolean := False;
         Last_Top_Level_Was_Open      : Boolean := False;
         Last_Top_Level_Was_Separator : Boolean := False;
         Last_Top_Level_Was_Arrow     : Boolean := False;

         procedure Add_Missing_Actual
           (Anchor : Token_Info;
            Reason : String) is
         begin
            Add_Production
              (Result, Production_Call_Actual_Missing_Actual_Recovery_Boundary,
               Anchor, Reason);
            Add_Production
              (Result,
               Production_Entry_Call_Actual_Missing_Actual_Recovery_Boundary,
               Anchor, Reason);
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected call actual association expression");
         end Add_Missing_Actual;

         procedure Add_Trailing_Separator
           (Anchor : Token_Info) is
         begin
            Add_Production
              (Result,
               Production_Call_Actual_Trailing_Separator_Recovery_Boundary,
               Anchor, "call actual trailing separator recovery boundary");
            Add_Production
              (Result,
               Production_Entry_Call_Actual_Trailing_Separator_Recovery_Boundary,
               Anchor, "entry-call actual trailing separator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected call actual after separator");
         end Add_Trailing_Separator;
      begin
         for I in Start_At .. End_At - 1 loop
            declare
               T : constant String :=
                 To_String (Position.Stream.Tokens (Positive (I)).Text);
            begin
               if T = "(" then
                  if not Saw_Open then
                     Saw_Open := True;
                     Depth := 1;
                     Last_Top_Level_Was_Open := True;
                     Last_Top_Level_Was_Separator := False;
                     Last_Top_Level_Was_Arrow := False;
                     Add_Production
                       (Result, Production_Call_Actual_List_Open_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "call actual list opening delimiter");
                     Add_Production
                       (Result, Production_Entry_Call_Actual_List_Open_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "entry-call actual list opening delimiter");
                  else
                     Depth := Depth + 1;
                  end if;
               elsif T = ")" and then Saw_Open then
                  if Depth = 1 then
                     Saw_Close := True;
                     if Last_Top_Level_Was_Open then
                        Add_Production
                          (Result,
                           Production_Call_Actual_Empty_List_Recovery_Boundary,
                           Position.Stream.Tokens (Positive (I)),
                           "call actual empty list recovery boundary");
                        Add_Production
                          (Result,
                           Production_Entry_Call_Actual_Empty_List_Recovery_Boundary,
                           Position.Stream.Tokens (Positive (I)),
                           "entry-call actual empty list recovery boundary");
                        Add_Production
                          (Result, Production_Recovery_Point,
                           Position.Stream.Tokens (Positive (I)),
                           "expected call actual inside actual list");
                     elsif Last_Top_Level_Was_Separator then
                        Add_Trailing_Separator
                          (Position.Stream.Tokens (Positive (I)));
                     elsif Last_Top_Level_Was_Arrow then
                        Add_Missing_Actual
                          (Position.Stream.Tokens (Positive (I)),
                           "call actual association missing expression before close");
                     end if;
                     Add_Production
                       (Result, Production_Call_Actual_List_Close_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "call actual list closing delimiter");
                     Add_Production
                       (Result, Production_Entry_Call_Actual_List_Close_Delimiter,
                        Position.Stream.Tokens (Positive (I)),
                        "entry-call actual list closing delimiter");
                     exit;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif T = "," and then Saw_Open and then Depth = 1 then
                  if Last_Top_Level_Was_Open
                    or else Last_Top_Level_Was_Separator
                    or else Last_Top_Level_Was_Arrow
                  then
                     Add_Missing_Actual
                       (Position.Stream.Tokens (Positive (I)),
                        "call actual association missing expression before separator");
                  end if;
                  Add_Production
                    (Result, Production_Call_Actual_Association_Separator,
                     Position.Stream.Tokens (Positive (I)),
                     "call actual association separator");
                  Add_Production
                    (Result, Production_Entry_Call_Actual_Association_Separator,
                     Position.Stream.Tokens (Positive (I)),
                     "entry-call actual association separator");
                  Last_Top_Level_Was_Open := False;
                  Last_Top_Level_Was_Separator := True;
                  Last_Top_Level_Was_Arrow := False;
               elsif T = "=>" and then Saw_Open and then Depth = 1 then
                  Last_Top_Level_Was_Open := False;
                  Last_Top_Level_Was_Separator := False;
                  Last_Top_Level_Was_Arrow := True;
               elsif Saw_Open and then Depth = 1 then
                  Last_Top_Level_Was_Open := False;
                  Last_Top_Level_Was_Separator := False;
                  Last_Top_Level_Was_Arrow := False;
               end if;
            end;
         end loop;

         if Saw_Open and then not Saw_Close then
            Add_Production
              (Result, Production_Call_Actual_List_Missing_Close_Recovery_Boundary,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "call actual list missing close recovery boundary");
            Add_Production
              (Result, Production_Entry_Call_Actual_List_Missing_Close_Recovery_Boundary,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "entry-call actual list missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "expected closing parenthesis after call actual list");
         end if;
      end Add_Actual_Part_Delimiter_Productions;
   begin
      if End_At <= Start_At + 1 then
         return;
      end if;

      Add_Production
        (Result, Production_Statement_Name_Suffix,
         Position.Stream.Tokens (Positive (Start_At)),
         "statement name suffix");

      for I in Start_At .. End_At - 1 loop
         declare
            T : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Text);
            L : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Lower);
         begin
            if T = "." then
               Has_Selected := True;
               Last_Dot_Index := I;
            elsif T = "(" then
               Has_Paren := True;
               if First_Paren_Index = 0 then
                  First_Paren_Index := I;
               end if;
            elsif T = ".." then
               Has_Range := True;
            elsif T = "=>" then
               Has_Arrow := True;
            elsif L = "all" then
               Has_All := True;
            end if;
         end;
      end loop;

      if Has_Selected and then Has_Paren then
         Has_Selected_Call := Last_Dot_Index < First_Paren_Index;
      end if;

      if Has_Selected and then Last_Dot_Index > Start_At then
         Has_Dispatching := True;
      end if;

      if Has_Paren and then First_Paren_Index > Start_At then
         Has_Indexed_Prefix := True;
      end if;

      if For_Assignment then
         if Has_Selected then
            Add_Production
              (Result, Production_Assignment_Selected_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "selected assignment target");
         end if;
         if Has_Paren then
            Add_Production
              (Result, Production_Assignment_Indexed_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "indexed assignment target");
         end if;
         if Has_Range then
            Add_Production
              (Result, Production_Assignment_Slice_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "slice assignment target");
         end if;
         if Has_All then
            Add_Production
              (Result, Production_Assignment_Dereference_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "dereference assignment target");
         end if;
      else
         if Has_Selected then
            Add_Production
              (Result, Production_Call_Selected_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "selected call target");
            Add_Production
              (Result, Production_Call_Selected_Prefix,
               Position.Stream.Tokens (Positive (Start_At)),
               "selected call prefix");
            Add_Production
              (Result, Production_Call_Selected_Operation_Name,
               Position.Stream.Tokens (Positive (Last_Dot_Index + 1)),
               "selected call operation name");
         end if;
         if Has_Dispatching then
            Add_Production
              (Result, Production_Call_Dispatching_Prefix,
               Position.Stream.Tokens (Positive (Start_At)),
               "dispatching-style call prefix");
         end if;
         if Has_Paren then
            Add_Production
              (Result, Production_Call_Indexed_Or_Actual_Target,
               Position.Stream.Tokens (Positive (Start_At)),
               "indexed or actual call target");
            Add_Production
              (Result, Production_Call_Actual_List,
               Position.Stream.Tokens (Positive (First_Paren_Index)),
               "call actual or index list");
            Add_Actual_Part_Delimiter_Productions;
         end if;
         if Has_Indexed_Prefix then
            Add_Production
              (Result, Production_Call_Indexed_Prefix,
               Position.Stream.Tokens (Positive (Start_At)),
               "indexed call prefix");
         end if;
         if Has_Selected_Call and then Has_Paren then
            Add_Production
              (Result, Production_Call_Entry_Family_Ambiguity,
               Position.Stream.Tokens (Positive (Start_At)),
               "entry-family or procedure-call ambiguity");
         end if;
         if Has_Arrow then
            Add_Production
              (Result, Production_Call_Actual_Association,
               Position.Stream.Tokens (Positive (Start_At)),
               "call actual association");
         end if;
      end if;
   end Add_Statement_Name_Suffix_Productions;

   procedure Parse_Declaration_Or_Statement
     (Position : in out Cursor;
      Result   : in out Grammar_Result);


   function At_Iterator_Filter_Condition_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = "=>"
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "loop"
        or else L = "end"
        or else L = "else"
        or else L = "elsif";
   end At_Iterator_Filter_Condition_Boundary;



   function At_Case_Statement_Selector_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "is"
        or else L = "when"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "exception"
        or else L = "end";
   end At_Case_Statement_Selector_Reserved_Boundary;


   function At_Loop_Domain_Reserved_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "loop"
        or else L = "when"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "exception"
        or else L = "end";
   end At_Loop_Domain_Reserved_Boundary;


   function At_Iterated_Component_Expression_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "when"
        or else L = "else"
        or else L = "elsif"
        or else L = "end";
   end At_Iterated_Component_Expression_Boundary;

   function At_Aggregate_Component_Expression_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "]"
        or else T = "=>"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "or"
        or else L = "when"
        or else L = "exception"
        or else L = "end";
   end At_Aggregate_Component_Expression_Boundary;


   function At_Conditional_Expression_Dependent_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "when"
        or else L = "is"
        or else L = "begin"
        or else L = "private"
        or else L = "end";
   end At_Conditional_Expression_Dependent_Boundary;


   function At_Case_Expression_Selector_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "is"
        or else L = "when"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "begin"
        or else L = "private"
        or else L = "end";
   end At_Case_Expression_Selector_Boundary;


   function At_Quantified_Predicate_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "then"
        or else L = "else"
        or else L = "elsif"
        or else L = "when"
        or else L = "end";
   end At_Quantified_Predicate_Boundary;

   function At_Declare_Expression_Body_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else T = "=>"
        or else L = "when"
        or else L = "else"
        or else L = "elsif"
        or else L = "end";
   end At_Declare_Expression_Body_Boundary;


   procedure Parse_Range_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Range_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
      begin
         return L = "with"
           or else L = "do"
           or else L = "else"
           or else L = "elsif"
           or else L = "then"
           or else L = "when"
           or else L = "or"
           or else L = "exception";
      end At_Range_Reserved_Boundary;

      function At_Range_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "record"
           or else At_Range_Reserved_Boundary;
      end At_Range_Boundary;
   begin
      Add_Production (Result, Production_Range_Constraint, Tok, "range constraint");
      if Current_Lower (Position) = "range" then
         Advance (Position);
      end if;

      if At_Range_Boundary then
         Add_Production
           (Result, Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary,
            Tok, "missing range lower bound");
         if At_Range_Reserved_Boundary then
            Add_Production
              (Result, Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "range lower bound reserved-boundary recovery boundary");
         end if;
         Add_Production
           (Result, Production_Constraint_Recovery_Boundary, Tok,
            "missing range lower bound");
         return;
      end if;

      Add_Production
        (Result, Production_Range_Lower_Bound, Current (Position),
         "range lower bound");
      Parse_Expression (Position, Result);

      if not At_End (Position)
        and then To_String (Current (Position).Text) = ".."
      then
         Add_Production
           (Result, Production_Range_Constraint_Range_Separator,
            Current (Position), "range constraint separator");
         Advance (Position);
         if At_Range_Boundary then
            Add_Production
              (Result, Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary,
               Tok, "missing range upper bound");
            if At_Range_Reserved_Boundary then
               Add_Production
                 (Result, Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "range upper bound reserved-boundary recovery boundary");
            end if;
            Add_Production
              (Result, Production_Constraint_Recovery_Boundary, Tok,
               "missing range upper bound");
         else
            Add_Production
              (Result, Production_Range_Upper_Bound, Current (Position),
               "range upper bound");
            Parse_Expression (Position, Result);
         end if;
      end if;
   end Parse_Range_Constraint;


   function At_Digits_Or_Delta_Reserved_Boundary
     (Position : Cursor) return Boolean is
      L : constant String := Current_Lower (Position);
   begin
      return L = "with"
        or else L = "do"
        or else L = "else"
        or else L = "elsif"
        or else L = "then"
        or else L = "when"
        or else L = "or"
        or else L = "exception";
   end At_Digits_Or_Delta_Reserved_Boundary;


   function At_Digits_Or_Delta_Expression_Boundary
     (Position : Cursor) return Boolean is
      T : constant String := To_String (Current (Position).Text);
      L : constant String := Current_Lower (Position);
   begin
      return At_End (Position)
        or else T = ";"
        or else T = ","
        or else T = ")"
        or else L = "is"
        or else L = "begin"
        or else L = "end"
        or else L = "private"
        or else L = "record"
        or else At_Digits_Or_Delta_Reserved_Boundary (Position);
   end At_Digits_Or_Delta_Expression_Boundary;


   procedure Parse_Digits_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Subtype indications may carry decimal/floating point digits
      --  constraints, optionally followed by a range constraint.  Keep this
      --  grammar distinct from floating-point type definitions so subtype
      --  declarations such as ``subtype Short is Float digits 6 range ...``
      --  do not leave ``digits`` behind for statement recovery.
      Add_Production (Result, Production_Digits_Constraint, Tok, "digits constraint");
      if Current_Lower (Position) = "digits" then
         Advance (Position);
      end if;

      if At_Digits_Or_Delta_Expression_Boundary (Position) then
         Add_Production
           (Result, Production_Digits_Constraint_Missing_Expression_Recovery_Boundary,
            Tok, "missing digits constraint expression");
         if At_Digits_Or_Delta_Reserved_Boundary (Position) then
            Add_Production
              (Result, Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "digits constraint reserved-boundary recovery boundary");
         end if;
         return;
      end if;

      Add_Production
        (Result, Production_Digits_Constraint_Expression, Current (Position),
         "digits constraint expression");
      Parse_Expression (Position, Result);
      if Current_Lower (Position) = "range" then
         Parse_Range_Constraint (Position, Result);
      end if;
   end Parse_Digits_Constraint;


   procedure Parse_Delta_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Fixed-point subtype indications may use ``delta`` constraints and
      --  decimal fixed-point subtypes may chain ``digits`` before an optional
      --  range.  This is syntactic retention only; scale/model-number legality
      --  remains outside the editor parser.
      Add_Production (Result, Production_Delta_Constraint, Tok, "delta constraint");
      if Current_Lower (Position) = "delta" then
         Advance (Position);
      end if;

      if At_Digits_Or_Delta_Expression_Boundary (Position) then
         Add_Production
           (Result, Production_Delta_Constraint_Missing_Expression_Recovery_Boundary,
            Tok, "missing delta constraint expression");
         if At_Digits_Or_Delta_Reserved_Boundary (Position) then
            Add_Production
              (Result, Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "delta constraint reserved-boundary recovery boundary");
         end if;
         return;
      end if;

      Add_Production
        (Result, Production_Delta_Constraint_Expression, Current (Position),
         "delta constraint expression");
      Parse_Expression (Position, Result);
      if Current_Lower (Position) = "digits" then
         Parse_Digits_Constraint (Position, Result);
      elsif Current_Lower (Position) = "range" then
         Parse_Range_Constraint (Position, Result);
      end if;
   end Parse_Delta_Constraint;



   function Parenthesized_Constraint_Has_Arrow (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 or else Depth = 1 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Parenthesized_Constraint_Has_Arrow;


   function Has_Top_Level_Arrow_Before_Constraint_Association_End
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then T = "," then
               return False;
            elsif Depth = 0 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Has_Top_Level_Arrow_Before_Constraint_Association_End;


   procedure Parse_Discriminant_Selector_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      loop
         exit when At_End (Position);
         exit when To_String (Current (Position).Text) = "=>";
         declare
            Selector_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Discriminant_Selector_Name, Selector_Tok,
               To_String (Selector_Tok.Text));

            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Name, Selector_Tok,
                  To_String (Selector_Tok.Text));
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Recovery_Point, Selector_Tok,
                  "expected discriminant selector name");
               exit;
            end if;
         end;

         if To_String (Current (Position).Text) = "|" then
            declare
               Separator_Tok : constant Token_Info := Current (Position);
            begin
               Add_Production
                 (Result, Production_Discrete_Choice_Separator, Separator_Tok,
                  "discrete choice separator");
               Advance (Position);
               if At_End (Position)
                 or else To_String (Current (Position).Text) = "=>"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Discrete_Choice_Missing_Choice_Recovery_Boundary,
                     Separator_Tok, "discrete choice missing choice recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Separator_Tok,
                     "expected discrete choice after separator");
                  exit;
               end if;
            end;
         else
            exit;
         end if;
      end loop;
   end Parse_Discriminant_Selector_Name_List;


   procedure Parse_Discriminant_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Discriminant_Association_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
      begin
         return L = "with"
           or else L = "do"
           or else L = "else"
           or else L = "elsif"
           or else L = "then"
           or else L = "when"
           or else L = "or"
           or else L = "exception";
      end At_Discriminant_Association_Reserved_Boundary;

      function At_Discriminant_Association_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "record"
           or else At_Discriminant_Association_Reserved_Boundary;
      end At_Discriminant_Association_Boundary;
   begin
      Add_Production
        (Result, Production_Discriminant_Constraint, Tok,
         "discriminant constraint");
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;
      Add_Production
        (Result, Production_Discriminant_Constraint_Open_Delimiter,
         Current (Position), "discriminant constraint open delimiter");
      Advance (Position);

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Assoc_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Discriminant_Association, Assoc_Tok,
               "discriminant association");

            if Has_Top_Level_Arrow_Before_Constraint_Association_End
                 (Position)
            then
               --  discriminant_association permits a selector-name list
               --  before =>.  Keep ``Left | Right => Expr`` structural
               --  instead of letting expression parsing stop at ``|`` and
               --  forcing recovery before the closing constraint.
               Parse_Discriminant_Selector_Name_List (Position, Result);
               if not Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Recovery_Point, Assoc_Tok,
                     "expected => in discriminant association");
               end if;
            end if;

            if At_Discriminant_Association_Boundary then
               Add_Production
                 (Result,
                  Production_Discriminant_Association_Missing_Expression_Recovery_Boundary,
                  Assoc_Tok, "missing discriminant association expression");
               if At_Discriminant_Association_Reserved_Boundary then
                  Add_Production
                    (Result,
                     Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary,
                     Current (Position),
                     "discriminant constraint reserved-boundary recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Assoc_Tok,
                  "missing discriminant association expression");
            else
               Add_Production
                 (Result, Production_Discriminant_Constraint_Expression,
                  Current (Position), "discriminant constraint expression");
               Parse_Expression (Position, Result);
            end if;
         end;
         if To_String (Current (Position).Text) = "," then
            Add_Production
              (Result, Production_Discriminant_Association_Separator,
               Current (Position), "discriminant association separator");
            Advance (Position);
            if not At_End (Position)
           and then To_String (Current (Position).Text) = ")"
         then
               Add_Production
                 (Result,
                  Production_Discriminant_Association_Missing_Expression_Recovery_Boundary,
                  Tok, "missing discriminant association after comma");
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Tok,
                  "missing discriminant association after comma");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Discriminant_Constraint_Close_Delimiter,
            Current (Position), "discriminant constraint close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Discriminant_Constraint_Missing_Close_Recovery_Boundary,
            Tok, "discriminant constraint missing close recovery boundary");
      end if;
   end Parse_Discriminant_Constraint;


   procedure Parse_Index_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Index_Item_Reserved_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
      begin
         return L = "with"
           or else L = "do"
           or else L = "else"
           or else L = "elsif"
           or else L = "then"
           or else L = "when"
           or else L = "or"
           or else L = "exception";
      end At_Index_Item_Reserved_Boundary;

      function At_Index_Item_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "begin"
           or else L = "end"
           or else L = "private"
           or else L = "record"
           or else At_Index_Item_Reserved_Boundary;
      end At_Index_Item_Boundary;
   begin
      Add_Production (Result, Production_Index_Constraint, Tok, "index constraint");
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;
      Add_Production
        (Result, Production_Index_Constraint_Open_Delimiter, Current (Position),
         "index constraint open delimiter");
      Advance (Position);
      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         declare
            Item_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Index_Constraint_Item, Item_Tok,
               "index constraint item");
            if Current_Lower (Position) = "range" then
               Parse_Range_Constraint (Position, Result);
            elsif At_Index_Item_Boundary then
               Add_Production
                 (Result, Production_Index_Constraint_Missing_Item_Recovery_Boundary,
                  Item_Tok, "missing index constraint item");
               if At_Index_Item_Reserved_Boundary then
                  Add_Production
                    (Result,
                     Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary,
                     Current (Position),
                     "index constraint reserved-boundary recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Item_Tok,
                  "missing index constraint item");
            else
               Add_Production
                 (Result, Production_Range_Lower_Bound, Current (Position),
                  "index constraint lower bound");
               Parse_Expression (Position, Result);
               if To_String (Current (Position).Text) = ".." then
                  Add_Production
                    (Result, Production_Range_Constraint, Current (Position),
                     "range constraint");
                  Advance (Position);
                  if At_Index_Item_Boundary then
                     Add_Production
                       (Result, Production_Constraint_Recovery_Boundary,
                        Item_Tok, "missing index constraint upper bound");
                     if At_Index_Item_Reserved_Boundary then
                        Add_Production
                          (Result,
                           Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary,
                           Current (Position),
                           "index constraint upper bound reserved-boundary recovery boundary");
                     end if;
                  else
                     Add_Production
                       (Result, Production_Range_Upper_Bound,
                        Current (Position), "index constraint upper bound");
                     Parse_Expression (Position, Result);
                  end if;
               elsif Current_Lower (Position) = "range" then
                  Parse_Range_Constraint (Position, Result);
               end if;
            end if;
         end;

         if To_String (Current (Position).Text) = "," then
            Add_Production
              (Result, Production_Index_Constraint_Item_Separator,
               Current (Position), "index constraint item separator");
            Advance (Position);
            if To_String (Current (Position).Text) = ")" then
               Add_Production
                 (Result, Production_Index_Constraint_Missing_Item_Recovery_Boundary,
                  Tok, "missing index constraint item after comma");
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Tok,
                  "missing index constraint item after comma");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;
      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Index_Constraint_Close_Delimiter,
            Current (Position), "index constraint close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Index_Constraint_Missing_Close_Recovery_Boundary,
            Tok, "index constraint missing close recovery boundary");
      end if;
   end Parse_Index_Constraint;



   procedure Parse_Array_Index_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function Has_Box_Before_Delimiter (From : Cursor) return Boolean is
         Probe : Cursor := From;
         Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
            begin
               if T = "(" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth = 0 or else Depth = 1 then
                     return False;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 0 and then T = "," then
                  return False;
               elsif Depth = 0 and then T = "<>" then
                  return True;
               end if;
            end;
            Advance (Probe);
         end loop;

         return False;
      end Has_Box_Before_Delimiter;

      function Has_Box_In_Index_Part (From : Cursor) return Boolean is
         Probe : Cursor := From;
         Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
            begin
               if T = "(" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth <= 1 then
                     return False;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 1 and then T = "<>" then
                  return True;
               end if;
            end;
            Advance (Probe);
         end loop;

         return False;
      end Has_Box_In_Index_Part;

      function At_Array_Index_Reserved_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = ";"
           or else T = ","
           or else T = ")"
           or else L = "is"
           or else L = "with"
           or else L = "begin"
           or else L = "private"
           or else L = "record"
           or else L = "end"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "or"
           or else L = "when"
           or else L = "exception"
           or else L = "do";
      end At_Array_Index_Reserved_Boundary;
   begin
      Add_Production (Result, Production_Index_Constraint, Tok, "array index part");
      if Has_Box_In_Index_Part (Position) then
         Add_Production
           (Result, Production_Unconstrained_Array_Index_Part, Tok,
            "unconstrained array index part");
      else
         Add_Production
           (Result, Production_Constrained_Array_Index_Part, Tok,
            "constrained array index part");
      end if;
      if not Match_Symbol (Position, "(") then
         return;
      end if;

      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         declare
            Item_Tok : constant Token_Info := Current (Position);
         begin
            --  Unconstrained array definitions use index subtype definitions,
            --  for example ``Positive range <>``.  These must be retained as
            --  distinct grammar from constrained index constraints/ranges;
            --  otherwise the token cursor treats ``<>`` as an ordinary
            --  relation tail and downstream recovery loses the array-domain
            --  shape.
            if Has_Box_Before_Delimiter (Position) then
               Add_Production
                 (Result, Production_Array_Index_Subtype_Definition, Item_Tok,
                  "array index subtype definition");
               Add_Production
                 (Result, Production_Index_Subtype_Definition, Item_Tok,
                  "index subtype definition");
               Add_Production
                 (Result, Production_Array_Index_Subtype_Name, Current (Position),
                  "array index subtype name");
               Parse_Subtype_Mark (Position, Result);
               if Current_Lower (Position) = "range" then
                  Add_Production
                    (Result, Production_Range_Constraint, Current (Position),
                     "index subtype range box");
                  Add_Production
                    (Result, Production_Array_Index_Range_Box, Current (Position),
                     "array index range box");
                  Advance (Position);
               end if;
               if To_String (Current (Position).Text) = "<>" then
                  Add_Production
                    (Result, Production_Array_Index_Range_Box, Current (Position),
                     "array index range box");
                  Advance (Position);
               end if;
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Index_Constraint_Item, Item_Tok,
                  "array index range item");
               Parse_Range_Constraint (Position, Result);
            elsif At_Array_Index_Reserved_Boundary then
               Add_Production
                 (Result, Production_Index_Constraint_Item, Item_Tok,
                  "array index constraint item");
               Add_Production
                 (Result, Production_Array_Index_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "array index reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Item_Tok,
                  "missing array index item");
            else
               Add_Production
                 (Result, Production_Index_Constraint_Item, Item_Tok,
                  "array index constraint item");
               Add_Production
                 (Result, Production_Range_Lower_Bound, Current (Position),
                  "array index lower bound");
               Parse_Expression (Position, Result);
               if To_String (Current (Position).Text) = ".." then
                  Add_Production
                    (Result, Production_Range_Constraint, Current (Position),
                     "range constraint");
                  Advance (Position);
                  if At_Array_Index_Reserved_Boundary then
                     Add_Production
                       (Result, Production_Array_Index_Reserved_Boundary_Recovery_Boundary,
                        Current (Position),
                        "array index upper bound reserved-boundary recovery boundary");
                     Add_Production
                       (Result, Production_Constraint_Recovery_Boundary,
                        Item_Tok, "missing array index upper bound");
                  else
                     Add_Production
                       (Result, Production_Range_Upper_Bound,
                        Current (Position), "array index upper bound");
                     Parse_Expression (Position, Result);
                  end if;
               elsif Current_Lower (Position) = "range" then
                  Parse_Range_Constraint (Position, Result);
               end if;
            end if;
         end;
         if Match_Symbol (Position, ",") then
            if To_String (Current (Position).Text) = ")" then
               Add_Production
                 (Result, Production_Constraint_Recovery_Boundary, Tok,
                  "missing array index part after comma");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;

      if not Match_Symbol (Position, ")") then
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in array index part");
      end if;
   end Parse_Array_Index_Part;

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Access_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Subtype_Mark
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  A subtype indication begins with a subtype_mark followed by an
      --  optional constraint.  Do not parse the subtype mark as a full
      --  expression: doing so greedily consumes following parentheses as
      --  indexed-component suffixes and hides discriminant/index constraints
      --  from the grammar layer.  Retain selected names and attribute-style
      --  subtype marks (for example T'Class/T'Base) but leave ``(...)`` for
      --  constraint parsing below.
      if At_End (Position) then
         return;
      end if;

      if Tok.Kind = Token_Identifier or else Tok.Kind = Token_Keyword then
         Add_Production (Result, Production_Subtype_Mark, Tok, "subtype mark");
         Add_Production (Result, Production_Name, Tok, To_String (Tok.Text));
         Advance (Position);
      else
         Parse_Expression (Position, Result);
         return;
      end if;

      loop
         exit when At_End (Position);
         if To_String (Current (Position).Text) = "." then
            --  Keep subtype marks on the same selected-name suffix path used
            --  by expression names, visibility clauses, allocator subtype
            --  indications, and representation targets.  The older subtype
            --  path only advanced over the selector token, which meant
            --  operator-symbol and character-literal selectors were consumed
            --  silently and never exposed as selected-name selector grammar.
            Parse_Selected_Name_Suffix
              (Position, Result, Tok, "subtype mark");
         elsif To_String (Current (Position).Text) = "'" then
            Add_Production
                    (Result, Production_Chained_Attribute_Reference, Tok,
                     "chained attribute reference");
                  Add_Production (Result, Production_Attribute_Reference, Tok, To_String (Tok.Text));
            Add_Production
              (Result, Production_Attribute_Subtype_Mark_Reference, Tok,
               "attribute reference in subtype mark");
            Advance (Position);
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Attribute_Designator_Name,
                  Current (Position), To_String (Current (Position).Text));
               Advance (Position);
            end if;
         else
            exit;
         end if;
      end loop;
   end Parse_Subtype_Mark;


   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Subtype_Indication, Tok, To_String (Tok.Text));
      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
        and then Lookahead_Lower (Position, 2) = "access"
        and then (Lookahead_Lower (Position, 3) = "protected"
                  or else Lookahead_Lower (Position, 3) = "procedure"
                  or else Lookahead_Lower (Position, 3) = "function"
                  or else Lookahead_Lower (Position, 4) = "procedure"
                  or else Lookahead_Lower (Position, 4) = "function")
      then
         Add_Production
           (Result, Production_Access_Subprogram_Null_Exclusion, Tok,
            "not null access-to-subprogram definition");
      end if;
      Parse_Null_Exclusion (Position, Result);
      if Current_Lower (Position) = "access" then
         Parse_Access_Type_Definition (Position, Result);
      else
         Parse_Subtype_Mark (Position, Result);
      end if;
      if Current_Lower (Position) = "range" then
         Add_Production
           (Result, Production_Subtype_Range_Constraint, Current (Position),
            "subtype range constraint");
         Parse_Range_Constraint (Position, Result);
      elsif Current_Lower (Position) = "digits" then
         Add_Production
           (Result, Production_Subtype_Digits_Constraint, Current (Position),
            "subtype digits constraint");
         Parse_Digits_Constraint (Position, Result);
      elsif Current_Lower (Position) = "delta" then
         Add_Production
           (Result, Production_Subtype_Delta_Constraint, Current (Position),
            "subtype delta constraint");
         Parse_Delta_Constraint (Position, Result);
      elsif To_String (Current (Position).Text) = "(" then
         if Parenthesized_Constraint_Has_Arrow (Position) then
            --  A subtype indication can be followed by either an array index
            --  constraint or a discriminant constraint.  Named discriminant
            --  associations are syntactically distinguishable by ``=>`` and
            --  must not be flattened into generic index-constraint recovery.
            --  Positional constraints remain on the existing conservative
            --  index-constraint path because they are not distinguishable
            --  without symbol-table knowledge.
            Add_Production
              (Result, Production_Subtype_Discriminant_Constraint,
               Current (Position), "subtype discriminant constraint");
            Parse_Discriminant_Constraint (Position, Result);
         else
            Add_Production
              (Result, Production_Subtype_Index_Constraint, Current (Position),
               "subtype index constraint");
            Parse_Index_Constraint (Position, Result);
         end if;
      end if;
   end Parse_Subtype_Indication;

   procedure Parse_Array_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Array_Type_Definition, Tok, "array type definition");
      if Current_Lower (Position) = "array" then
         Advance (Position);
      end if;
      if To_String (Current (Position).Text) = "(" then
         Parse_Array_Index_Part (Position, Result);
      end if;
      if Match_Keyword (Position, "of") then
         Add_Production
           (Result, Production_Array_Component_Definition, Current (Position),
            "array component definition");
         if Current_Lower (Position) = "not"
           or else Current_Lower (Position) = "access"
         then
            Add_Production
              (Result, Production_Array_Component_Access_Definition,
               Current (Position), "array component access definition");
         else
            Add_Production
              (Result, Production_Array_Component_Subtype_Indication,
               Current (Position), "array component subtype indication");
         end if;
         if Current_Lower (Position) = "aliased" then
            Add_Production
              (Result, Production_Aliased_Part, Current (Position),
               "array component aliased part");
            Advance (Position);
            if Current_Lower (Position) = "not"
              or else Current_Lower (Position) = "access"
            then
               Add_Production
                 (Result, Production_Array_Component_Access_Definition,
                  Current (Position), "array component access definition");
            end if;
         end if;
         Parse_Subtype_Indication (Position, Result);
      else
         Add_Production (Result, Production_Recovery_Point, Tok, "expected of in array type definition");
      end if;
   end Parse_Array_Type_Definition;

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
      then
         Add_Production (Result, Production_Null_Exclusion, Tok, "not null");
         Add_Production
           (Result, Production_Subtype_Null_Exclusion, Tok,
            "subtype null exclusion");
         Advance (Position);
         Advance (Position);
      end if;
   end Parse_Null_Exclusion;

   procedure Parse_Access_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Has_General_Object_Mode : Boolean := False;
      Is_Access_Function : Boolean := False;
      Has_Protected_Subprogram_Part : Boolean := False;

      function At_Access_Definition_Boundary return Boolean is
      begin
         if At_End (Position) then
            return True;
         end if;

         declare
            Text : constant String := To_String (Current (Position).Text);
            Lower : constant String := Current_Lower (Position);
         begin
            return Text = ";"
              or else Text = ","
              or else Text = ")"
              or else Lower = "with"
              or else Lower = "is"
              or else Lower = "begin"
              or else Lower = "end"
              or else Lower = "private"
              or else Lower = "limited"
              or else Lower = "separate";
         end;
      end At_Access_Definition_Boundary;

      function At_Access_Subprogram_Head return Boolean is
      begin
         if At_End (Position) then
            return False;
         end if;

         declare
            Lower : constant String := Current_Lower (Position);
         begin
            return Lower = "procedure"
              or else Lower = "function"
              or else Lower = "protected";
         end;
      end At_Access_Subprogram_Head;

      function Offset_Is_Access_Definition_Boundary
        (Offset : Natural) return Boolean is
         Index : constant Natural := Position.Index + Offset;
      begin
         if Index < 1 or else Index > Natural (Position.Stream.Tokens.Length) then
            return True;
         end if;

         declare
            Text : constant String :=
              To_String (Position.Stream.Tokens (Positive (Index)).Text);
            Lower : constant String :=
              To_String (Position.Stream.Tokens (Positive (Index)).Lower);
         begin
            return Text = ";"
              or else Text = ","
              or else Text = ")"
              or else Lower = "with"
              or else Lower = "is"
              or else Lower = "begin"
              or else Lower = "end"
              or else Lower = "private"
              or else Lower = "limited"
              or else Lower = "separate";
         end;
      end Offset_Is_Access_Definition_Boundary;

      function Access_Parameter_Profile_Missing_Close return Boolean is
         Depth : Natural := 0;
      begin
         if To_String (Current (Position).Text) /= "(" then
            return False;
         end if;

         for Index in Position.Index .. Natural (Position.Stream.Tokens.Length) loop
            declare
               Text : constant String :=
                 To_String (Position.Stream.Tokens (Positive (Index)).Text);
               Lower : constant String :=
                 To_String (Position.Stream.Tokens (Positive (Index)).Lower);
            begin
               if Text = "(" then
                  Depth := Depth + 1;
               elsif Text = ")" then
                  if Depth = 0 then
                     return False;
                  end if;
                  Depth := Depth - 1;
                  if Depth = 0 then
                     return False;
                  end if;
               elsif Depth = 1
                 and then (Lower = "with"
                           or else Lower = "is"
                           or else Lower = "private"
                           or else Lower = "begin"
                           or else Lower = "end")
               then
                  return True;
               end if;
            end;
         end loop;

         return True;
      end Access_Parameter_Profile_Missing_Close;
   begin
      --  access_definition / access_type_definition are used in several Ada
      --  contexts: named access types, anonymous object/component definitions,
      --  discriminants, parameters, generic formals, and access result types.
      --  Retain the common access_definition node and the object-vs-subprogram
      --  branch explicitly so downstream semantic colouring/navigation can see
      --  whether the designated entity is a subtype mark or a callable profile.
      Add_Production
        (Result, Production_Access_Type_Definition, Tok,
         "access type definition");
      Add_Production
        (Result, Production_Access_Definition, Tok, "access definition");

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
        and then Lookahead_Lower (Position, 2) = "access"
      then
         Add_Production
           (Result, Production_Access_Subprogram_Null_Exclusion, Tok,
            "not null access definition");
      end if;

      Parse_Null_Exclusion (Position, Result);

      if Current_Lower (Position) = "access" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected access in access definition");
         return;
      end if;

      if Current_Lower (Position) = "all"
        or else Current_Lower (Position) = "constant"
      then
         Add_Production
           (Result, Production_Access_Mode, Current (Position),
            To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Access_General_Object, Current (Position),
            "general access object definition");
         if Current_Lower (Position) = "all" then
            Add_Production
              (Result, Production_Access_All_Object_Mode, Current (Position),
               "access all object mode");
         else
            Add_Production
              (Result, Production_Access_Constant_Object_Mode, Current (Position),
               "access constant object mode");
         end if;
         Has_General_Object_Mode := True;
         Advance (Position);

         if At_Access_Definition_Boundary then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing designated subtype after access all/constant mode");
            Add_Production
              (Result,
               Production_Access_Object_Missing_Subtype_Recovery_Boundary,
               Tok,
               "missing designated subtype after access all/constant mode");
            Add_Production
              (Result,
               Production_Access_Mode_Missing_Subtype_Recovery_Boundary,
               Tok,
               "missing designated subtype after access all/constant mode");
            return;
         elsif At_Access_Subprogram_Head then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "access all/constant cannot introduce access-to-subprogram profile structurally");
            Add_Production
              (Result,
               Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary,
               Tok,
               "access all/constant before access-to-subprogram head");
            return;
         end if;
      end if;

      if Current_Lower (Position) = "protected" then
         Add_Production
           (Result, Production_Access_Protected_Part, Current (Position),
            "protected");
         Add_Production
           (Result, Production_Access_Protected_Subprogram_Definition,
            Current (Position), "protected access-to-subprogram definition");
         Has_Protected_Subprogram_Part := True;
         Advance (Position);

         if Current_Lower (Position) /= "procedure"
           and then Current_Lower (Position) /= "function"
         then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing procedure or function after access protected");
            Add_Production
              (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
               Tok, "missing procedure or function after access protected");
            Add_Production
              (Result,
               Production_Access_Protected_Missing_Subprogram_Recovery_Boundary,
               Tok, "missing procedure or function after access protected");
            Add_Production
              (Result,
               Production_Access_Protected_Missing_Subprogram_Boundary_Token,
               Current (Position),
               "boundary token after access protected without procedure/function");
            return;
         end if;
      end if;

      if Current_Lower (Position) = "procedure"
        or else Current_Lower (Position) = "function"
      then
         Is_Access_Function := Current_Lower (Position) = "function";
         if Has_Protected_Subprogram_Part then
            if Is_Access_Function then
               Add_Production
                 (Result, Production_Access_Protected_Function_Profile,
                  Current (Position), "protected access-to-function profile");
            else
               Add_Production
                 (Result, Production_Access_Protected_Procedure_Profile,
                  Current (Position), "protected access-to-procedure profile");
            end if;
         end if;
         Add_Production
           (Result, Production_Access_To_Subprogram_Definition,
            Current (Position), To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Access_Named_Subprogram_Definition,
            Current (Position), "named access-to-subprogram definition");
         Add_Production
           (Result, Production_Access_Subprogram_Profile,
            Current (Position), "access-to-subprogram profile");
         Add_Production
           (Result, Production_Access_Subprogram_Kind,
            Current (Position), To_String (Current (Position).Text));
         Advance (Position);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Access_Subprogram_Parameter_Profile,
               Current (Position), "access-to-subprogram parameter profile");
            if Access_Parameter_Profile_Missing_Close then
               Add_Production
                 (Result,
                  Production_Access_Subprogram_Parameter_Profile_Missing_Close_Recovery_Boundary,
                  Current (Position),
                  "access-to-subprogram parameter profile missing close recovery boundary");
               Add_Production
                 (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
                  Current (Position),
                  "access-to-subprogram parameter profile missing close recovery");
               while not At_End (Position)
                 and then To_String (Current (Position).Text) /= ";"
               loop
                  Advance (Position);
               end loop;
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Advance (Position);
               end if;
               return;
            else
               Parse_Parameter_Profile (Position, Result);
            end if;
         end if;
         if Current_Lower (Position) = "return" then
            Add_Production
              (Result, Production_Access_Subprogram_Result_Profile,
               Current (Position), "access-to-subprogram result profile");
            Add_Production
              (Result, Production_Access_Result_Subtype, Current (Position),
               "access-to-subprogram result subtype");
            Advance (Position);
            if Current_Lower (Position) = "not"
              and then Lookahead_Lower (Position, 1) = "null"
              and then Offset_Is_Access_Definition_Boundary (2)
            then
               Add_Production
                 (Result, Production_Access_Subprogram_Result_Null_Exclusion,
                  Current (Position),
                  "access-to-function result null exclusion");
               Add_Production
                 (Result, Production_Access_Type_Recovery_Boundary, Tok,
                  "missing result subtype after access-to-function return not null");
               Add_Production
                 (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return not null");
               Add_Production
                 (Result,
                  Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return not null");
               Add_Production
                 (Result,
                  Production_Access_Result_Null_Exclusion_Missing_Subtype_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return not null");
               Advance (Position);
               Advance (Position);
            elsif At_Access_Definition_Boundary then
               Add_Production
                 (Result, Production_Access_Type_Recovery_Boundary, Tok,
                  "missing result subtype after access-to-function return");
               Add_Production
                 (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return");
               Add_Production
                 (Result,
                  Production_Access_Function_Missing_Result_Subtype_Recovery_Boundary,
                  Tok, "missing result subtype after access-to-function return");
               Add_Production
                 (Result,
                  Production_Access_Result_Missing_Subtype_Recovery_Boundary,
                  Tok, "missing access result subtype after return");
            else
               if Current_Lower (Position) = "not"
                 and then Lookahead_Lower (Position, 1) = "null"
               then
                  Add_Production
                    (Result, Production_Access_Subprogram_Result_Null_Exclusion,
                     Current (Position),
                     "access-to-function result null exclusion");
               end if;
               if Access_Subprogram_Result_Has_Constraint (Position) then
                  Add_Production
                    (Result, Production_Access_Subprogram_Result_Constraint,
                     Current (Position),
                     "access-to-function result subtype constraint");
               end if;
               Parse_Subtype_Indication (Position, Result);
            end if;
         elsif Is_Access_Function then
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing return subtype in access-to-function definition");
            Add_Production
              (Result, Production_Access_Subprogram_Profile_Recovery_Boundary,
               Tok, "missing return subtype in access-to-function profile");
            Add_Production
              (Result, Production_Access_Function_Missing_Return_Recovery_Boundary,
               Tok, "missing return subtype in access-to-function profile");
         end if;
      else
         Add_Production
           (Result, Production_Access_To_Object_Definition, Current (Position),
            To_String (Current (Position).Text));
         if Has_General_Object_Mode then
            Add_Production
              (Result, Production_Access_General_Object, Current (Position),
               "general access object designated subtype");
         else
            Add_Production
              (Result, Production_Access_Pool_Specific_Object, Current (Position),
               "pool-specific access object definition");
         end if;
         if At_Access_Definition_Boundary then
            --  Access-to-object definitions require a designated subtype.
            --  Treat declaration/aspect/body boundaries as recovery points
            --  instead of parsing them as subtype marks, so malformed forms
            --  such as ``access with Inline`` or ``access private`` remain
            --  bounded and following declarations stay visible.
            Add_Production
              (Result, Production_Access_Type_Recovery_Boundary, Tok,
               "missing designated subtype in access object definition");
            Add_Production
              (Result,
               Production_Access_Object_Missing_Subtype_Recovery_Boundary,
               Tok,
               "missing designated subtype in access object definition");
         else
            Add_Production
              (Result, Production_Access_Object_Subtype_Mark, Current (Position),
               "access object subtype mark");
            Parse_Subtype_Indication (Position, Result);
         end if;
      end if;
   end Parse_Access_Type_Definition;

   procedure Parse_Type_Modifiers
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      --  Ada type definitions can be prefixed by grammar-significant
      --  modifiers before the actual type-definition body.  Earlier passes
      --  only recognized definitions whose first token was the body keyword
      --  itself (record/private/interface/new/array/access).  Retain the
      --  modifiers structurally so forms such as ``abstract tagged limited
      --  record`` and ``synchronized interface`` do not fall through the
      --  subtype-indication recovery path.
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant Token_Info := Current (Position);
         begin
            exit when L /= "abstract"
              and then L /= "limited"
              and then L /= "tagged"
              and then L /= "synchronized"
              and then L /= "task"
              and then L /= "protected";
            Add_Production
              (Result, Production_Type_Modifier, T, To_String (T.Text));
            if L = "abstract" then
               Add_Production
                 (Result, Production_Abstract_Type_Modifier, T,
                  "abstract type modifier");
            elsif L = "tagged" then
               Add_Production
                 (Result, Production_Tagged_Type_Modifier, T,
                  "tagged type modifier");
            elsif L = "limited" then
               Add_Production
                 (Result, Production_Limited_Type_Modifier, T,
                  "limited type modifier");
            end if;
            Advance (Position);
         end;
      end loop;
   end Parse_Type_Modifiers;

   procedure Parse_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Type_Definition, Tok, To_String (Tok.Text));
      Parse_Type_Modifiers (Position, Result);
      if To_String (Current (Position).Text) = "(" then
         Parse_Enumeration_Type_Definition (Position, Result);
      elsif Current_Lower (Position) = "record" then
         Parse_Record_Definition (Position, Result);
      elsif Current_Lower (Position) = "null"
        and then Lookahead_Lower (Position, 1) = "record"
      then
         Add_Production
           (Result, Production_Record_Definition, Current (Position),
            "null record definition");
         Advance (Position);
         Advance (Position);
      elsif Current_Lower (Position) = "array" then
         Parse_Array_Type_Definition (Position, Result);
      elsif Current_Lower (Position) = "access"
        or else (Current_Lower (Position) = "not" and then Lookahead_Lower (Position, 1) = "null"
                 and then Lookahead_Lower (Position, 2) = "access")
      then
         Parse_Access_Type_Definition (Position, Result);
      elsif Current_Lower (Position) = "new" then
         Add_Production (Result, Production_Derived_Type_Definition, Tok, "derived type definition");
         Advance (Position);
         if not At_End (Position) then
            Add_Production
              (Result, Production_Derived_Parent_Subtype, Current (Position),
               "derived parent subtype");
         end if;
         Parse_Subtype_Indication (Position, Result);
         if Current_Lower (Position) = "and" then
            Add_Production
              (Result, Production_Derived_Interface_List, Current (Position),
               "derived interface list");
         end if;
         while Current_Lower (Position) = "and" loop
            Advance (Position);
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Derived_Interface_Subtype, Current (Position),
                  "derived interface subtype");
            end if;
            Parse_Subtype_Indication (Position, Result);
         end loop;
         if Current_Lower (Position) = "with" then
            Advance (Position);
            if Current_Lower (Position) = "private" then
               Add_Production
                 (Result, Production_Private_Type_Definition, Current (Position),
                  "private extension");
               Add_Production
                 (Result, Production_Derived_Private_Extension, Current (Position),
                  "derived private extension");
               Advance (Position);
            elsif Current_Lower (Position) = "record" then
               Add_Production
                 (Result, Production_Derived_Record_Extension, Current (Position),
                  "derived record extension");
               Parse_Record_Definition (Position, Result);
            elsif Current_Lower (Position) = "null"
              and then Lookahead_Lower (Position, 1) = "record"
            then
               Add_Production
                 (Result, Production_Derived_Record_Extension, Current (Position),
                  "derived record extension");
               Add_Production
                 (Result, Production_Derived_Null_Record_Extension, Current (Position),
                  "derived null record extension");
               Add_Production
                 (Result, Production_Record_Definition, Current (Position),
                  "derived null record definition");
               Advance (Position);
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Derived_Type_Recovery_Boundary, Current (Position),
                  "missing private or record after derived with");
            end if;
         end if;
      elsif Current_Lower (Position) = "private" then
         Add_Production (Result, Production_Private_Type_Definition, Current (Position), "private type definition");
         Advance (Position);
      elsif Current_Lower (Position) = "interface" then
         Add_Production (Result, Production_Interface_Type_Definition, Current (Position), "interface type definition");
         Advance (Position);
         if Current_Lower (Position) = "and" then
            Add_Production
              (Result, Production_Interface_Parent_List, Current (Position),
               "interface parent list");
         end if;
         while Current_Lower (Position) = "and" loop
            Advance (Position);
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Interface_Parent_Subtype, Current (Position),
                  "interface parent subtype");
            end if;
            Parse_Subtype_Indication (Position, Result);
         end loop;
      elsif Current_Lower (Position) = "range" then
         Add_Production (Result, Production_Signed_Integer_Type_Definition, Current (Position), "signed integer type definition");
         Add_Production (Result, Production_Signed_Integer_Range, Current (Position), "signed integer range");
         Parse_Range_Constraint (Position, Result);
      elsif Current_Lower (Position) = "mod" then
         Add_Production (Result, Production_Modular_Type_Definition, Current (Position), "modular type definition");
         Advance (Position);
         if not At_End (Position) then
            Add_Production (Result, Production_Modular_Modulus_Expression, Current (Position), "modular modulus expression");
         end if;
         Parse_Expression (Position, Result);
      elsif Current_Lower (Position) = "digits" then
         Add_Production (Result, Production_Floating_Point_Definition, Current (Position), "floating point type definition");
         Advance (Position);
         if not At_End (Position) then
            Add_Production (Result, Production_Floating_Digits_Expression, Current (Position), "floating digits expression");
         end if;
         Parse_Expression (Position, Result);
         if Current_Lower (Position) = "range" then
            Parse_Range_Constraint (Position, Result);
         end if;
      elsif Current_Lower (Position) = "delta" then
         Advance (Position);
         if not At_End (Position) then
            Add_Production (Result, Production_Fixed_Delta_Expression, Current (Position), "fixed delta expression");
         end if;
         Parse_Expression (Position, Result);
         if Current_Lower (Position) = "digits" then
            Add_Production (Result, Production_Decimal_Fixed_Point_Definition, Tok, "decimal fixed point type definition");
            Advance (Position);
            if not At_End (Position) then
               Add_Production (Result, Production_Fixed_Digits_Expression, Current (Position), "fixed digits expression");
            end if;
            Parse_Expression (Position, Result);
         else
            Add_Production (Result, Production_Ordinary_Fixed_Point_Definition, Tok, "ordinary fixed point type definition");
         end if;
         if Current_Lower (Position) = "range" then
            Parse_Range_Constraint (Position, Result);
         end if;
      else
         Parse_Subtype_Indication (Position, Result);
      end if;
   end Parse_Type_Definition;

   function Is_Statement_Starter_After_Label (Position : Cursor) return Boolean is
      L0 : constant String := Current_Lower (Position);
      L1 : constant String := Lookahead_Lower (Position, 1);
   begin
      --  Ada statement identifiers use the same leading token shape as an
      --  object declaration until the token after ':' is inspected.  Keep
      --  this predicate deliberately syntactic: it recognizes statement
      --  starters that may legally follow a statement identifier without
      --  trying to prove placement or semantic legality.
      return
        L0 = "if"
        or else L0 = "case"
        or else L0 = "loop"
        or else L0 = "while"
        or else L0 = "for"
        or else L0 = "declare"
        or else L0 = "begin"
        or else L0 = "select"
        or else L0 = "accept"
        or else L0 = "return"
        or else L0 = "raise"
        or else L0 = "null"
        or else L0 = "exit"
        or else L0 = "goto"
        or else L0 = "delay"
        or else L0 = "requeue"
        or else L0 = "abort"
        or else L0 = "pragma"
        or else (L0 = "then" and then L1 = "abort");
   end Is_Statement_Starter_After_Label;

   function Parenthesized_Name_Suffix_Is_Slice (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      --  Position is expected to point at the opening parenthesis of a name
      --  suffix.  Ada uses the same delimiter for indexed components and
      --  slices; retain a distinct grammar production when the top-level
      --  suffix contains a range separator or the range keyword.  This is a
      --  syntactic distinction only; range legality and discrete type checks
      --  remain outside the editor parser.
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               elsif Depth = 1 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then (T = ".." or else L = "range") then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Parenthesized_Name_Suffix_Is_Slice;

   procedure Parse_Iterated_Component_Association
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Ada aggregate iterated component associations use a leading ``for``
      --  but are not quantified expressions: they have no ``all``/``some``
      --  quantifier and their domain belongs to an aggregate association.
      --  Keep a distinct production so aggregate grammar does not regress into
      --  the quantified-expression recovery path.
      Add_Production
        (Result, Production_Iterated_Component_Association, Tok,
         "iterated component association");

      if Current_Lower (Position) = "for" then
         Advance (Position);
      end if;

      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Defining_Name, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
      end if;

      if Current_Lower (Position) = "in" then
         Add_Production
           (Result, Production_Loop_Parameter_Specification, Tok,
            "aggregate loop parameter specification");
         Advance (Position);
      elsif Current_Lower (Position) = "of" then
         Add_Production
           (Result, Production_Iterator_Specification, Tok,
            "aggregate iterator specification");
         Advance (Position);
      end if;

      if Current_Lower (Position) = "reverse" then
         Advance (Position);
      end if;

      --  Keep the iteration domain structural instead of skipping directly to
      --  the association arrow.  This preserves discrete ranges, container
      --  names, subtype ranges, and optional iterator filters for outline and
      --  semantic-colouring consumers while retaining bounded recovery.
      if not At_End (Position)
        and then To_String (Current (Position).Text) /= "=>"
        and then Current_Lower (Position) /= "when"
      then
         declare
            Domain_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Iterated_Component_Domain, Domain_Tok,
               "iterated component association domain");
            Parse_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Add_Production
                 (Result, Production_Range_Expression, Domain_Tok,
                  "iterated component discrete range");
               Parse_Expression (Position, Result);
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Range_Expression, Domain_Tok,
                  "iterated component subtype range");
               Advance (Position);
               if To_String (Current (Position).Text) = "<>" then
                  Add_Production
                    (Result, Production_Box_Expression, Current (Position),
                     "iterated component box range");
                  Advance (Position);
               else
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Parse_Expression (Position, Result);
                  end if;
               end if;
            end if;
         end;
      elsif Current_Lower (Position) = "when"
        or else To_String (Current (Position).Text) = "=>"
      then
         Add_Production
           (Result, Production_Iterated_Component_Missing_Domain_Recovery_Boundary,
            Current (Position),
            "missing domain in iterated component association");
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected iterated component association domain");
      end if;

      if Match_Keyword (Position, "when") then
         Add_Production
           (Result, Production_Iterated_Component_Iterator_Filter,
            Current (Position), "iterated component iterator filter");
         if At_Iterator_Filter_Condition_Boundary (Position) then
            Add_Production
              (Result,
               Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary,
               Current (Position),
               "missing iterated component iterator filter condition");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected iterated component iterator filter condition");
         else
            Parse_Expression (Position, Result);
         end if;
      end if;

      if To_String (Current (Position).Text) = "=>" then
         declare
            Arrow_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Iterated_Component_Association_Arrow,
               Arrow_Tok, "iterated component association arrow");
            Advance (Position);
            if At_Iterated_Component_Expression_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Iterated_Component_Missing_Expression_Recovery_Boundary,
                  Current (Position),
                  "missing iterated component expression recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected iterated component expression");
            else
               Add_Production
                 (Result, Production_Iterated_Component_Expression,
                  Current (Position), "iterated component expression");
               Parse_Expression (Position, Result);
            end if;
         end;
      else
         Add_Production
           (Result, Production_Iterated_Component_Missing_Arrow_Recovery_Boundary,
            Current (Position),
            "missing => in iterated component association");
      end if;
   end Parse_Iterated_Component_Association;


   procedure Add_Aggregate_Choice_Depth
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe        : Cursor := Position;
      Choice_Start : Token_Info := Current (Position);
      Depth        : Natural := 0;
      Saw_Range    : Boolean := False;

      procedure Emit_Choice is
      begin
         if To_String (Choice_Start.Text) /= "=>" then
            Add_Production
              (Result, Production_Aggregate_Index_Choice, Choice_Start,
               "aggregate index or component choice");
            if Saw_Range then
               Add_Production
                 (Result, Production_Aggregate_Range_Choice, Choice_Start,
                  "aggregate range choice");
            end if;
         end if;
      end Emit_Choice;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               exit when Depth = 0;
               Depth := Depth - 1;
            elsif Depth = 0 and then T = "=>" then
               Emit_Choice;
               exit;
            elsif Depth = 0 and then T = "|" then
               Emit_Choice;
               Choice_Start := Token_At (Probe.Stream, Probe.Index + 1);
               Saw_Range := False;
            elsif Depth = 0 and then T = ".." then
               Saw_Range := True;
            end if;
         end;
         Advance (Probe);
      end loop;
   end Add_Aggregate_Choice_Depth;


   procedure Parse_Component_Association_Item
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info) is
      Assoc_Tok : constant Token_Info := Current (Position);
   begin
      if Current_Lower (Position) = "for" then
         Add_Production
           (Result, Production_Component_Association, Assoc_Tok,
            "iterated component association item");
         Parse_Iterated_Component_Association (Position, Result);
      elsif Has_Top_Level_Arrow_Before_Association_End (Position) then
         Add_Production
           (Result, Production_Component_Association, Assoc_Tok,
            To_String (Assoc_Tok.Text));
         Add_Production
           (Result, Production_Aggregate_Named_Component_Association,
            Assoc_Tok, "aggregate named component association");
         Add_Production
           (Result, Production_Aggregate_Component_Choice_List,
            Assoc_Tok, "aggregate component choice list");
         Add_Aggregate_Choice_Depth (Position, Result);
         if Current_Lower (Position) = "others" then
            Add_Production
              (Result, Production_Aggregate_Others_Choice,
               Current (Position), "aggregate others choice");
         end if;
         Parse_Discrete_Choice_List (Position, Result, "=>");
         if Match_Symbol (Position, "=>") then
            Add_Production
              (Result, Production_Aggregate_Component_Arrow,
               Current (Position), "aggregate component association arrow");
            if To_String (Current (Position).Text) = ","
              or else To_String (Current (Position).Text) = ")"
            then
               Add_Production
                 (Result, Production_Aggregate_Recovery_Boundary,
                  Assoc_Tok, "missing aggregate component expression");
               Add_Production
                 (Result, Production_Recovery_Point, Assoc_Tok,
                  "expected aggregate component expression");
            elsif At_Aggregate_Component_Expression_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary,
                  Current (Position),
                  "aggregate component expression reserved-boundary recovery boundary");
               Add_Production
                 (Result, Production_Aggregate_Recovery_Boundary,
                  Assoc_Tok, "missing aggregate component expression");
               Add_Production
                 (Result, Production_Recovery_Point, Assoc_Tok,
                  "expected aggregate component expression before boundary");
            elsif To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Aggregate_Box_Component,
                  Current (Position), "aggregate box component value");
               Parse_Expression (Position, Result);
            elsif Current_Lower (Position) = "for" then
               Parse_Iterated_Component_Association (Position, Result);
            else
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Aggregate_Recovery_Boundary, Assoc_Tok,
               "expected => in aggregate component association");
            Add_Production
              (Result, Production_Recovery_Point, Assoc_Tok,
               "expected => in component association");
         end if;
      else
         Add_Production
           (Result, Production_Aggregate_Positional_Component, Assoc_Tok,
            "aggregate positional component");
         if To_String (Current (Position).Text) = "<>" then
            Add_Production
              (Result, Production_Aggregate_Box_Component,
               Current (Position), "aggregate positional box component");
         end if;
         Parse_Expression (Position, Result);
         if Match_Symbol (Position, "..") then
            Add_Production
              (Result, Production_Range_Expression, Origin,
               "range expression");
            Parse_Expression (Position, Result);
         elsif Current_Lower (Position) = "range" then
            Add_Production
              (Result, Production_Range_Expression, Origin,
               "range attribute slice");
            Advance (Position);
         end if;
      end if;
   end Parse_Component_Association_Item;


   procedure Parse_Allocator_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;

      Add_Production
        (Result, Production_Subtype_Indication, Tok,
         To_String (Tok.Text));

      if Current_Lower (Position) = "not"
        and then Lookahead_Lower (Position, 1) = "null"
      then
         Add_Production
           (Result, Production_Allocator_Null_Exclusion, Current (Position),
            "allocator null exclusion");
      end if;

      Parse_Null_Exclusion (Position, Result);

      if Current_Lower (Position) = "access" then
         Add_Production
           (Result, Production_Allocator_Access_Subtype, Current (Position),
            "allocator access subtype indication");
         Parse_Access_Type_Definition (Position, Result);
      elsif Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         declare
            Name_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Name, Name_Tok,
               To_String (Name_Tok.Text));
            Add_Production
              (Result, Production_Allocator_Subtype_Mark, Name_Tok,
               To_String (Name_Tok.Text));
            Advance (Position);

            loop
               exit when At_End (Position);
               if To_String (Current (Position).Text) = "." then
                  if Lookahead_Kind (Position, 1) = Token_String_Literal then
                     Add_Production
                       (Result, Production_Allocator_Selected_Literal_Subtype_Mark,
                        Name_Tok, "allocator selected literal subtype mark");
                     Add_Production
                       (Result, Production_Allocator_Selected_Operator_Subtype_Mark,
                        Name_Tok, "allocator selected operator subtype mark");
                  elsif Lookahead_Kind (Position, 1) = Token_Character_Literal then
                     Add_Production
                       (Result, Production_Allocator_Selected_Literal_Subtype_Mark,
                        Name_Tok, "allocator selected literal subtype mark");
                     Add_Production
                       (Result, Production_Allocator_Selected_Character_Subtype_Mark,
                        Name_Tok, "allocator selected character subtype mark");
                  elsif Lookahead_Kind (Position, 1) /= Token_Identifier
                    and then Lookahead_Kind (Position, 1) /= Token_Keyword
                  then
                     Add_Production
                       (Result, Production_Allocator_Incomplete_Selected_Subtype_Mark,
                        Name_Tok, "allocator incomplete selected subtype mark");
                  end if;
                  Parse_Selected_Name_Suffix
                    (Position, Result, Name_Tok,
                     "allocator subtype indication");
               elsif To_String (Current (Position).Text) = "'" then
                  --  In an allocator, ``Subtype_Mark'(...)`` starts the
                  --  qualified-expression form and must not be consumed as an
                  --  attribute-style subtype mark.  Other subtype attributes
                  --  such as T'Class/T'Base remain part of the subtype mark.
                  exit when Lookahead_Lower (Position, 1) = "(";
                  Add_Production
                    (Result, Production_Attribute_Reference, Name_Tok,
                     To_String (Name_Tok.Text));
                  Advance (Position);
                  if not At_End (Position) then
                     Advance (Position);
                  end if;
               else
                  exit;
               end if;
            end loop;
         end;
      else
         Parse_Expression (Position, Result);
      end if;

      if Current_Lower (Position) = "range" then
         Add_Production
           (Result, Production_Allocator_Range_Constraint, Current (Position),
            "allocator range constraint");
         Add_Production
           (Result, Production_Subtype_Range_Constraint, Current (Position),
            "subtype range constraint");
         Parse_Range_Constraint (Position, Result);
      elsif Current_Lower (Position) = "digits" then
         Add_Production
           (Result, Production_Allocator_Digits_Constraint, Current (Position),
            "allocator digits constraint");
         Add_Production
           (Result, Production_Subtype_Digits_Constraint, Current (Position),
            "subtype digits constraint");
         Parse_Digits_Constraint (Position, Result);
      elsif Current_Lower (Position) = "delta" then
         Add_Production
           (Result, Production_Allocator_Delta_Constraint, Current (Position),
            "allocator delta constraint");
         Add_Production
           (Result, Production_Subtype_Delta_Constraint, Current (Position),
            "subtype delta constraint");
         Parse_Delta_Constraint (Position, Result);
      elsif To_String (Current (Position).Text) = "(" then
         if Parenthesized_Constraint_Has_Arrow (Position) then
            Add_Production
              (Result, Production_Allocator_Discriminant_Constraint,
               Current (Position), "allocator discriminant constraint");
            Add_Production
              (Result, Production_Subtype_Discriminant_Constraint,
               Current (Position), "subtype discriminant constraint");
            Parse_Discriminant_Constraint (Position, Result);
         else
            Add_Production
              (Result, Production_Allocator_Index_Constraint, Current (Position),
               "allocator index constraint");
            Add_Production
              (Result, Production_Subtype_Index_Constraint, Current (Position),
               "subtype index constraint");
            Parse_Index_Constraint (Position, Result);
         end if;
      end if;
   end Parse_Allocator_Subtype_Indication;


   procedure Parse_Reduction_Argument_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Attribute_Name : String) is
      Tok : constant Token_Info := Current (Position);
      Is_Parallel  : constant Boolean := Lower (Attribute_Name) = "parallel_reduce";

      function At_Reduction_Argument_Boundary
        (Position : Cursor) return Boolean is
         T : constant String :=
           (if At_End (Position) then "" else To_String (Current (Position).Text));
         L : constant String :=
           (if At_End (Position) then "" else Current_Lower (Position));
      begin
         return At_End (Position)
           or else T = ")"
           or else T = ","
           or else T = ";"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "when"
           or else L = "loop"
           or else L = "is"
           or else L = "begin"
           or else L = "end";
      end At_Reduction_Argument_Boundary;
   begin
      --  Ada 2022 reduction attributes have a structured argument part:
      --     Prefix'Reduce (Reducer, Initial_Value)
      --     Prefix'Parallel_Reduce (Reducer, Initial_Value)
      --  Keep the reducer and initial-value positions visible to semantic
      --  consumers instead of flattening the whole parenthesized list into a
      --  generic association list.  This is syntactic only; callable profile
      --  conformance and parallel execution legality remain outside the editor
      --  grammar layer.
      Add_Production
        (Result, Production_Attribute_Argument_Part, Tok,
         "reduction attribute argument part");

      if not At_End (Position) and then To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Open_Delimiter,
            Current (Position), "reduction attribute argument-list open delimiter");
      end if;

      if not Match_Symbol (Position, "(") then
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "expected reduction argument part");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected reduction argument part");
         return;
      end if;

      if At_Reduction_Argument_Boundary (Position) then
         Add_Production
           (Result, Production_Reduction_Missing_Reducer_Recovery_Boundary, Origin,
            "missing reduction reducer");
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "missing reduction reducer");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "missing reduction reducer");
      else
         Add_Production
           (Result, Production_Attribute_Argument_Association, Current (Position),
            "reduction attribute argument association");
         Add_Production
           (Result, Production_Attribute_Argument_Expression, Current (Position),
            "reduction attribute argument expression");
         Add_Production
           (Result, Production_Reduction_Reducer, Current (Position),
            "reduction reducer");
         Parse_Expression (Position, Result);
      end if;

      if not At_End (Position) and then To_String (Current (Position).Text) = "," then
         Add_Production
           (Result, Production_Attribute_Argument_Association_Separator,
            Current (Position), "reduction attribute argument association separator");
      end if;

      if Match_Symbol (Position, ",") then
         if At_Reduction_Argument_Boundary (Position) then
            Add_Production
              (Result, Production_Reduction_Missing_Initial_Value_Recovery_Boundary,
               Origin, "missing reduction initial value");
            if Is_Parallel then
               Add_Production
                 (Result, Production_Parallel_Reduction_Argument_Recovery_Boundary,
                  Origin, "missing parallel reduction initial value");
            end if;
            if not At_End (Position) and then To_String (Current (Position).Text) = ")" then
               Add_Production
                 (Result, Production_Reduction_Trailing_Separator_Recovery_Boundary,
                  Origin, "trailing reduction argument separator");
            end if;
            Add_Production
              (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
               "missing reduction initial value");
            Add_Production
              (Result, Production_Recovery_Point, Origin,
               "missing reduction initial value");
         else
            Add_Production
              (Result, Production_Attribute_Argument_Association, Current (Position),
               "reduction attribute argument association");
            Add_Production
              (Result, Production_Attribute_Argument_Expression, Current (Position),
               "reduction attribute argument expression");
            Add_Production
              (Result, Production_Reduction_Initial_Value, Current (Position),
               "reduction initial value");
            Parse_Expression (Position, Result);
         end if;
      else
         Add_Production
           (Result, Production_Reduction_Missing_Initial_Value_Recovery_Boundary,
            Origin, "expected initial value in reduction argument part");
         if Is_Parallel then
            Add_Production
              (Result, Production_Parallel_Reduction_Argument_Recovery_Boundary,
               Origin, "expected initial value in parallel reduction argument part");
         end if;
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "expected initial value in reduction argument part");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected initial value in reduction argument part");
      end if;

      while not At_End (Position) and then To_String (Current (Position).Text) = "," loop
         Add_Production
           (Result, Production_Attribute_Argument_Association_Separator,
            Current (Position), "reduction attribute argument association separator");
         Advance (Position);
         --  Retain additional implementation-defined or future reduction
         --  parameters as bounded expression nodes while still preserving the
         --  canonical reducer/initial-value pair above.
         if At_Reduction_Argument_Boundary (Position) then
            Add_Production
              (Result, Production_Reduction_Trailing_Separator_Recovery_Boundary,
               Origin, "trailing reduction argument separator");
            if Is_Parallel then
               Add_Production
                 (Result, Production_Parallel_Reduction_Argument_Recovery_Boundary,
                  Origin, "trailing parallel reduction argument separator");
            end if;
            Add_Production
              (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
               "trailing reduction argument separator");
            Add_Production
              (Result, Production_Recovery_Point, Origin,
               "trailing reduction argument separator");
            exit;
         else
            Parse_Expression (Position, Result);
         end if;
      end loop;

      if not At_End (Position) and then To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Close_Delimiter,
            Current (Position), "reduction attribute argument-list close delimiter");
      end if;

      if not Match_Symbol (Position, ")") then
         Add_Production
           (Result, Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary,
            Tok, "expected ) in reduction attribute argument part");
         Add_Production
           (Result, Production_Reduction_Argument_Recovery_Boundary, Origin,
            "expected ) in reduction argument part");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected ) in reduction argument part");
      end if;
   end Parse_Reduction_Argument_Part;


   procedure Parse_Attribute_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Attribute_Argument_Part, Tok, Label);

      if not At_End (Position) and then To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Open_Delimiter,
            Current (Position), "attribute argument-list open delimiter");
      end if;

      if not Match_Symbol (Position, "(") then
         Add_Production
           (Result, Production_Attribute_Recovery_Boundary, Origin,
            "expected attribute argument list");
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "expected attribute argument list");
         return;
      end if;

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Assoc_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Attribute_Argument_Association, Assoc_Tok,
               "attribute argument association");

            if Has_Top_Level_Arrow_Before_Association_End (Position) then
               Parse_Discrete_Choice_List (Position, Result, "=>");
               if Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Attribute_Argument_Expression,
                     Current (Position), "attribute argument expression");
                  Parse_Expression (Position, Result);
               else
                  Add_Production
                    (Result, Production_Attribute_Recovery_Boundary, Assoc_Tok,
                     "expected => in attribute argument association");
                  Add_Production
                    (Result, Production_Recovery_Point, Assoc_Tok,
                     "expected => in attribute argument association");
                  Skip_Balanced_To (Position, ",", ")", ";");
               end if;
            else
               Add_Production
                 (Result, Production_Attribute_Argument_Expression,
                  Current (Position), "attribute argument expression");
               Parse_Expression (Position, Result);
            end if;
         end;

         exit when To_String (Current (Position).Text) /= ",";
         Add_Production
           (Result, Production_Attribute_Argument_Association_Separator,
            Current (Position), "attribute argument association separator");
         Advance (Position);
      end loop;

      if not At_End (Position) and then To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Attribute_Argument_List_Close_Delimiter,
            Current (Position), "attribute argument-list close delimiter");
      end if;

      if not Match_Symbol (Position, ")") then
         Add_Production
           (Result, Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary,
            Tok, "expected ) in attribute argument list");
         Add_Production
           (Result, Production_Attribute_Recovery_Boundary, Tok,
            "expected ) in attribute argument list");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in attribute argument list");
      end if;
   end Parse_Attribute_Argument_List;




   procedure Mark_Raise_Exception_Target_Shape
     (Position               : Cursor;
      Result                 : in out Grammar_Result;
      Origin                 : Token_Info;
      Selected_Production    : Production_Kind;
      Recovery_Production    : Production_Kind;
      Label                  : String) is
      Probe : Cursor := Position;
      Saw_Name : Boolean := False;
      Saw_Selector : Boolean := False;
   begin
      --  Raise statements/expressions name exceptions with Ada names, not
      --  arbitrary statements.  Keep selected exception names visible for
      --  colouring and resolver hints, but keep this bounded and syntactic:
      --  exception resolution remains outside the token cursor.
      if At_End (Probe)
        or else To_String (Current (Probe).Text) = ";"
        or else To_String (Current (Probe).Text) = ")"
        or else Current_Lower (Probe) = "with"
      then
         Add_Production
           (Result, Recovery_Production, Origin,
            "missing " & Label);
         Add_Production
           (Result, Production_Recovery_Point, Origin,
            "missing " & Label);
         return;
      end if;

      if Current (Probe).Kind = Token_Identifier
        or else Current (Probe).Kind = Token_Keyword
      then
         Saw_Name := True;
         Advance (Probe);
      end if;

      while not At_End (Probe) loop
         exit when To_String (Current (Probe).Text) = ";";
         exit when To_String (Current (Probe).Text) = ")";
         exit when Current_Lower (Probe) = "with";

         if To_String (Current (Probe).Text) = "."
         then
            Saw_Selector := True;
            Advance (Probe);
            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
              or else Current (Probe).Kind = Token_String_Literal
              or else Current (Probe).Kind = Token_Character_Literal
            then
               Advance (Probe);
            else
               exit;
            end if;
         else
            exit;
         end if;
      end loop;

      if Saw_Name and then Saw_Selector then
         Add_Production
           (Result, Selected_Production, Current (Position),
            "selected " & Label);
      end if;
   end Mark_Raise_Exception_Target_Shape;

   procedure Parse_Primary (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Allocator_Subtype_Boundary
        (Position : Cursor) return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
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
           or else L = "exception"
           or else L = "end";
      end At_Allocator_Subtype_Boundary;

      function Qualified_Operand_Is_Missing
        (Open_Position : Cursor) return Boolean is
         L : constant String := Lookahead_Lower (Open_Position, 1);
      begin
         return L = ""
           or else L = ")"
           or else L = ";"
           or else L = ","
           or else L = "with"
           or else L = "is"
           or else L = "begin"
           or else L = "private"
           or else L = "then"
           or else L = "else"
           or else L = "elsif"
           or else L = "when"
           or else L = "exception"
           or else L = "end";
      end Qualified_Operand_Is_Missing;

      function Qualified_Subtype_Mark_Has_Selected_Prefix
        (Start : Cursor) return Boolean
      is
         Probe        : Cursor := Start;
         Saw_Selector : Boolean := False;
      begin
         if At_End (Probe) then
            return False;
         end if;

         if Current_Lower (Probe) = "not" then
            Advance (Probe);
            if At_End (Probe) then
               return False;
            elsif Current_Lower (Probe) = "null" then
               Advance (Probe);
            end if;
         end if;

         loop
            exit when At_End (Probe);

            if To_String (Current (Probe).Text) = "'" then
               return Lookahead_Lower (Probe, 1) = "(" and then Saw_Selector;
            elsif To_String (Current (Probe).Text) = "." then
               Saw_Selector := True;
               Advance (Probe);
               if At_End (Probe) then
                  return Saw_Selector;
               elsif Current (Probe).Kind = Token_Identifier
                 or else Current (Probe).Kind = Token_Keyword
                 or else Current (Probe).Kind = Token_String_Literal
                 or else Current (Probe).Kind = Token_Character_Literal
               then
                  Advance (Probe);
               else
                  return Saw_Selector;
               end if;
            elsif Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
              or else Current (Probe).Kind = Token_String_Literal
              or else Current (Probe).Kind = Token_Character_Literal
            then
               Advance (Probe);
            else
               return False;
            end if;
         end loop;

         return False;
      end Qualified_Subtype_Mark_Has_Selected_Prefix;
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Primary, Tok, To_String (Tok.Text));

      if To_String (Tok.Text) = "<>" then
         --  Ada box expressions are first-class syntactic placeholders in
         --  aggregates, generic actuals, aspect/default associations, and
         --  other grammar contexts.  Retain them as expression primaries
         --  instead of treating the <> token as an opaque operator.
         Add_Production (Result, Production_Box_Expression, Tok, "box expression");
         Advance (Position);
      elsif Current_Lower (Position) = "new" then
         Add_Production (Result, Production_Allocator, Tok, "allocator");
         Advance (Position);

         declare
            Allocator_Subtype_Is_Selected : constant Boolean :=
              Qualified_Subtype_Mark_Has_Selected_Prefix (Position);
         begin
            --  Ada allocators have two distinct shapes:
            --
            --     new Subtype_Mark
            --     new Subtype_Mark'(Expression_Or_Aggregate)
            --
            --  Older parsing kept only the outer allocator and then reused the
            --  generic subtype/association productions.  That was sufficient for
            --  recovery, but it hid whether a semantic consumer was looking at an
            --  uninitialized allocator, a qualified-expression allocator, or an
            --  initialized allocator using an aggregate/association part.
            if At_Allocator_Subtype_Boundary (Position) then
               Add_Production
                 (Result, Production_Allocator_Missing_Subtype_Recovery_Boundary,
                  Current (Position), "allocator missing subtype recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected allocator subtype before boundary");
            else
               Add_Production
                 (Result, Production_Allocator_Subtype_Indication, Current (Position),
                  "allocator subtype indication");
               Parse_Allocator_Subtype_Indication (Position, Result);
            end if;

            if To_String (Current (Position).Text) = "'" then
               Add_Production
                 (Result, Production_Allocator_Qualified_Expression, Tok,
                  "allocator qualified expression");
               Add_Production
                 (Result, Production_Allocator_Nested_Qualified_Expression, Tok,
                  "allocator nested qualified expression");
               Add_Production
                 (Result, Production_Qualified_Expression, Tok,
                  "allocator qualified expression");
               Add_Production
                 (Result, Production_Qualified_Expression_Subtype_Mark, Tok,
                  "allocator qualified-expression subtype mark");
               if Allocator_Subtype_Is_Selected then
                  Add_Production
                    (Result, Production_Qualified_Expression_Selected_Subtype_Mark,
                     Tok, "allocator qualified-expression selected subtype mark");
               end if;
               Add_Production
                 (Result, Production_Qualified_Expression_Apostrophe, Current (Position),
                  "qualified-expression apostrophe");
               Advance (Position);
               if To_String (Current (Position).Text) = "(" then
                  Add_Production
                    (Result, Production_Allocator_Initialized_Expression,
                     Current (Position), "allocator initialized expression");
                  Add_Production
                    (Result, Production_Qualified_Expression_Operand,
                     Current (Position), "allocator qualified-expression operand");
                  if Qualified_Operand_Is_Missing (Position) then
                     Add_Production
                       (Result, Production_Qualified_Expression_Missing_Operand_Recovery_Boundary,
                        Current (Position), "allocator qualified-expression missing operand recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected allocator qualified-expression operand before boundary");
                  end if;
                  Parse_Association_List (Position, Result, Qualified_Expression_Operand => True);
               end if;
            elsif To_String (Current (Position).Text) = "(" then
               Add_Production
                 (Result, Production_Allocator_Initialized_Expression,
                  Current (Position), "allocator initialized expression");
               Parse_Association_List (Position, Result);
            end if;
         end;
      elsif Current_Lower (Position) = "raise" then
         Add_Production (Result, Production_Raise_Expression, Tok, "raise expression");
         Advance (Position);

         --  Raise expressions mirror the statement form:
         --     raise Exception_Name [with String_Expression]
         --  Keep the exception-name and message-expression positions visible
         --  instead of relying only on generic expression nodes.  This remains
         --  syntactic: exception resolution and message type legality are
         --  outside the editor grammar layer.
         if not At_End (Position)
           and then Current_Lower (Position) /= "with"
           and then To_String (Current (Position).Text) /= ";"
           and then To_String (Current (Position).Text) /= ")"
         then
            Add_Production
              (Result, Production_Raise_Expression_Target, Current (Position),
               "raise expression target");
            Add_Production
              (Result, Production_Raise_Exception_Name, Current (Position),
               "raise expression exception name");
            Mark_Raise_Exception_Target_Shape
              (Position, Result, Current (Position),
               Production_Raise_Expression_Selected_Exception_Name,
               Production_Raise_Expression_Recovery_Boundary,
               "raise expression exception name");
            Parse_Expression (Position, Result);
         else
            Add_Production
              (Result, Production_Raise_Expression_Recovery_Boundary, Tok,
               "raise expression missing exception name");
         end if;
         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Raise_With_Message_Keyword, Current (Position),
               "raise expression with keyword");
            Advance (Position);
            if At_End (Position)
              or else To_String (Current (Position).Text) = ";"
              or else To_String (Current (Position).Text) = ")"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
              or else Current_Lower (Position) = "end"
            then
               Add_Production
                 (Result, Production_Raise_Expression_Message_Recovery_Boundary, Tok,
                  "raise expression missing message expression");
               Add_Production
                 (Result, Production_Raise_Message_Recovery_Boundary, Tok,
                  "raise expression missing message expression");
               Add_Production
                 (Result, Production_Raise_Expression_Recovery_Boundary, Tok,
                  "raise expression missing message expression");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "raise expression missing message expression");
            else
               Add_Production
                 (Result, Production_Raise_Expression_With_Message, Current (Position),
                  "raise expression with message");
               Add_Production
                 (Result, Production_Raise_With_Message, Current (Position),
                  "raise expression with message");
               Add_Production
                 (Result, Production_Raise_Expression_Message, Current (Position),
                  "raise expression message");
               Add_Production
                 (Result, Production_Raise_Message_Expression, Current (Position),
                  "raise expression message");
               Parse_Expression (Position, Result);
            end if;
         end if;
      elsif Current_Lower (Position) = "if" then
         Add_Production (Result, Production_Conditional_Expression, Tok, "if expression");
         Add_Production (Result, Production_If_Expression, Tok, "if expression");
         Advance (Position);
         if At_Conditional_Expression_Dependent_Boundary (Position) then
            Add_Production
              (Result, Production_If_Expression_Condition_Reserved_Boundary,
               Current (Position), "if expression condition reserved boundary");
            Add_Production
              (Result, Production_If_Expression_Missing_Condition_Recovery_Boundary,
               Tok, "if expression missing condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected condition in if expression");
         else
            Add_Production
              (Result, Production_If_Expression_Condition, Current (Position),
               "if expression condition");
            Parse_Expression (Position, Result);
         end if;
         if Match_Keyword (Position, "then") then
            if At_Conditional_Expression_Dependent_Boundary (Position) then
               Add_Production
                 (Result, Production_If_Expression_Missing_Then_Branch_Recovery_Boundary,
                  Tok, "if expression missing then-branch recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected then-dependent expression in if expression");
            else
               Add_Production
                 (Result, Production_If_Expression_Then_Dependent_Expression,
                  Current (Position), "then dependent expression");
               Add_Production
                 (Result, Production_If_Expression_Branch_Expression,
                  Current (Position), "then branch expression");
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_If_Expression_Missing_Then_Recovery_Boundary,
               Tok, "if expression missing then recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected then in if expression");
         end if;
         while Match_Keyword (Position, "elsif") loop
            Add_Production
              (Result, Production_Elsif_Expression_Part, Current (Position),
               "elsif expression part");
            if At_Conditional_Expression_Dependent_Boundary (Position) then
               Add_Production
                 (Result, Production_If_Expression_Condition_Reserved_Boundary,
                  Current (Position), "elsif expression condition reserved boundary");
               Add_Production
                 (Result, Production_If_Expression_Missing_Condition_Recovery_Boundary,
                  Tok, "elsif expression missing condition recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected condition in elsif expression");
            else
               Add_Production
                 (Result, Production_Elsif_Expression_Condition, Current (Position),
                  "elsif expression condition");
               Parse_Expression (Position, Result);
            end if;
            if Match_Keyword (Position, "then") then
               if At_Conditional_Expression_Dependent_Boundary (Position) then
                  Add_Production
                    (Result, Production_If_Expression_Missing_Then_Branch_Recovery_Boundary,
                     Tok, "elsif expression missing then-branch recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected then-dependent expression in elsif expression");
               else
                  Add_Production
                    (Result, Production_Elsif_Expression_Then_Dependent_Expression,
                     Current (Position), "elsif dependent expression");
                  Add_Production
                    (Result, Production_If_Expression_Branch_Expression,
                     Current (Position), "elsif branch expression");
                  Parse_Expression (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Elsif_Expression_Missing_Then_Recovery_Boundary,
                  Tok, "elsif expression missing then recovery boundary");
               Add_Production (Result, Production_Recovery_Point, Tok, "expected then in elsif expression");
            end if;
         end loop;
         if Match_Keyword (Position, "else") then
            if At_Conditional_Expression_Dependent_Boundary (Position) then
               Add_Production
                 (Result, Production_If_Expression_Missing_Else_Branch_Recovery_Boundary,
                  Tok, "if expression missing else-branch recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected else-dependent expression in if expression");
            else
               Add_Production
                 (Result, Production_Else_Expression_Part, Current (Position),
                  "else expression part");
               Add_Production
                 (Result, Production_If_Expression_Else_Dependent_Expression,
                  Current (Position), "else dependent expression");
               Add_Production
                 (Result, Production_If_Expression_Branch_Expression,
                  Current (Position), "else branch expression");
               Parse_Expression (Position, Result);
            end if;
         else
            --  Ada conditional expressions require an else-dependent
            --  expression.  Keep this syntactic recovery local and bounded so
            --  malformed in-progress code such as ``if A then B`` is visible
            --  to diagnostics/colouring without consuming the surrounding
            --  delimiter or declaration boundary.
            Add_Production
              (Result, Production_If_Expression_Missing_Else_Recovery_Boundary,
               Tok, "if expression missing else recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected else in if expression");
         end if;
      elsif Current_Lower (Position) = "case" then
         Add_Production (Result, Production_Case_Expression, Tok, "case expression");
         Advance (Position);
         if At_Case_Expression_Selector_Boundary (Position) then
            Add_Production
              (Result, Production_Case_Expression_Missing_Selector_Recovery_Boundary,
               Tok, "case expression missing selector recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected selector in case expression");
         else
            Add_Production
              (Result, Production_Case_Expression_Selector, Current (Position),
               "case expression selector");
            Parse_Expression (Position, Result);
         end if;
         if not Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Case_Expression_Missing_Is_Recovery_Boundary,
               Tok, "case expression missing is recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected is in case expression");
         end if;
         if Current_Lower (Position) /= "when" then
            Add_Production
              (Result, Production_Case_Expression_Missing_Alternative_Recovery_Boundary,
               Tok, "case expression missing alternative recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected when alternative in case expression");
         end if;
         while Match_Keyword (Position, "when") loop
            Add_Production
              (Result, Production_Case_Expression_Alternative, Current (Position),
               "case expression alternative");
            Add_Production
              (Result, Production_Case_Expression_Choice_List, Current (Position),
               "case expression choice list");
            Parse_Discrete_Choice_List (Position, Result, "=>");
            if Match_Symbol (Position, "=>") then
               Add_Production
                 (Result, Production_Case_Expression_Arrow, Current (Position),
                  "case expression arrow");
               if At_End (Position)
                 or else To_String (Current (Position).Text) = ","
                 or else To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
                 or else Current_Lower (Position) = "when"
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "then"
               then
                  Add_Production
                    (Result,
                     Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary,
                     Tok, "case expression missing dependent expression recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected dependent expression in case expression alternative");
               else
                  Add_Production
                    (Result, Production_Case_Expression_Dependent_Expression,
                     Current (Position), "case expression dependent expression");
                  Parse_Expression (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Case_Expression_Missing_Arrow_Recovery_Boundary,
                  Tok, "case expression missing arrow recovery boundary");
               Add_Production (Result, Production_Recovery_Point, Tok, "expected => in case expression");
            end if;
            if To_String (Current (Position).Text) = "," then
               Add_Production
                 (Result, Production_Case_Expression_Alternative_Separator,
                  Current (Position), "case expression alternative separator");
               Advance (Position);
               if At_End (Position)
                 or else To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Case_Expression_Missing_Alternative_Recovery_Boundary,
                     Tok, "case expression missing alternative recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected case expression alternative after separator");
                  exit;
               end if;
            else
               exit;
            end if;
         end loop;
      elsif Current_Lower (Position) = "for" then
         Add_Production (Result, Production_Quantified_Expression, Tok, "quantified expression");
         Advance (Position);

         --  Ada quantified expressions use a quantified loop scheme:
         --
         --     for all  I    in Source_Span     => Predicate
         --     for some Item of Container => Predicate
         --
         --  Keep the parameter, iteration domain, optional iterator filter,
         --  and predicate as separate grammar productions.  Earlier recovery
         --  skipped the whole domain to ``=>``; that preserved the outer
         --  expression but hid range bounds, container names, and filter
         --  expressions from the language model.
         if Current_Lower (Position) = "all" or else Current_Lower (Position) = "some" then
            Add_Production
              (Result, Production_Quantifier, Current (Position),
               Current_Lower (Position));
            Advance (Position);
         else
            --  Ada quantified expressions require an explicit quantifier
            --  (``all`` or ``some``) after ``for``.  Keep malformed
            --  in-progress expressions such as ``(for I in Items => P (I))``
            --  visible to downstream consumers without treating the missing
            --  quantifier as an ordinary loop-parameter token.
            Add_Production
              (Result,
               Production_Quantified_Missing_Quantifier_Recovery_Boundary,
               Tok, "quantified expression missing quantifier recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected all or some in quantified expression");
         end if;

         Add_Production
           (Result, Production_Quantified_Loop_Scheme, Current (Position),
            "quantified loop scheme");

         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
         then
            Add_Production
              (Result, Production_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
            Add_Production
              (Result, Production_Quantified_Parameter, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         end if;

         if Current_Lower (Position) = "in" then
            Add_Production
              (Result, Production_Loop_Parameter_Specification, Tok,
               "quantified loop parameter specification");
            Advance (Position);
         elsif Current_Lower (Position) = "of" then
            Add_Production
              (Result, Production_Iterator_Specification, Tok,
               "quantified iterator specification");
            Advance (Position);
         end if;

         if Current_Lower (Position) = "reverse" then
            Advance (Position);
         end if;

         if not At_End (Position)
           and then To_String (Current (Position).Text) /= "=>"
           and then Current_Lower (Position) /= "when"
         then
            declare
               Domain_Tok : constant Token_Info := Current (Position);
            begin
               Add_Production
                 (Result, Production_Quantified_Domain, Domain_Tok,
                  "quantified domain");
               Parse_Expression (Position, Result);
               if Match_Symbol (Position, "..") then
                  Add_Production
                    (Result, Production_Range_Expression, Domain_Tok,
                     "quantified discrete range");
                  Parse_Expression (Position, Result);
               elsif Current_Lower (Position) = "range" then
                  Add_Production
                    (Result, Production_Range_Expression, Domain_Tok,
                     "quantified subtype range");
                  Advance (Position);
                  if To_String (Current (Position).Text) = "<>" then
                     Add_Production
                       (Result, Production_Box_Expression, Current (Position),
                        "quantified box range");
                     Advance (Position);
                  else
                     Parse_Expression (Position, Result);
                     if Match_Symbol (Position, "..") then
                        Parse_Expression (Position, Result);
                     end if;
                  end if;
               end if;
            end;
         elsif Current_Lower (Position) = "when"
           or else To_String (Current (Position).Text) = "=>"
         then
            Add_Production
              (Result, Production_Quantified_Missing_Domain_Recovery_Boundary,
               Tok, "quantified expression missing domain recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected quantified expression domain");
         end if;

         if Match_Keyword (Position, "when") then
            Add_Production
              (Result, Production_Quantified_Iterator_Filter,
               Current (Position), "quantified iterator filter");
            if At_Iterator_Filter_Condition_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Quantified_Iterator_Filter_Missing_Condition_Recovery_Boundary,
                  Current (Position),
                  "missing quantified iterator filter condition");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected quantified iterator filter condition");
            else
               Parse_Expression (Position, Result);
            end if;
         end if;

         if Match_Symbol (Position, "=>") then
            Add_Production
              (Result, Production_Quantified_Arrow, Current (Position),
               "quantified arrow");
            if At_Quantified_Predicate_Boundary (Position) then
               Add_Production
                 (Result,
                  Production_Quantified_Missing_Predicate_Recovery_Boundary,
                  Current (Position),
                  "quantified expression missing predicate recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected quantified predicate");
            else
               Add_Production
                 (Result, Production_Quantified_Predicate, Current (Position),
                  "quantified predicate");
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Quantified_Missing_Arrow_Recovery_Boundary,
               Tok, "quantified expression missing arrow recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected => in quantified expression");
         end if;
      elsif Current_Lower (Position) = "null" then
         Add_Production (Result, Production_Null_Literal, Tok, "null literal");
         Advance (Position);
      elsif Tok.Kind = Token_Numeric_Literal then
         --  Keep Ada numeric literals distinct from ordinary primaries so
         --  downstream expression consumers can recognize literal-valued
         --  ranges, static bounds, and named-number defaults without
         --  re-tokenizing the source text.
         Add_Production
           (Result, Production_Numeric_Literal, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif Tok.Kind = Token_String_Literal then
         Add_Production
           (Result, Production_String_Literal, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif Tok.Kind = Token_Character_Literal then
         Add_Production
           (Result, Production_Character_Literal, Tok,
            To_String (Tok.Text));
         Advance (Position);
      elsif To_String (Tok.Text) = "@" then
         --  Ada 2022 target_name is a primary used inside assignment
         --  expressions to denote the current value of the assignment
         --  target.  Keep it distinct from ordinary identifiers so
         --  expression recovery does not treat @ as a stray operator.
         Add_Production (Result, Production_Target_Name, Tok, "target name");
         Advance (Position);
      elsif To_String (Tok.Text) = "(" then
         Add_Production (Result, Production_Parenthesized_Expression, Tok, "parenthesized expression");
         Add_Production
           (Result, Production_Parenthesized_Expression_Open_Delimiter, Tok,
            "parenthesized expression open delimiter");
         Add_Production (Result, Production_Aggregate, Tok, "parenthesized expression or aggregate");
         Add_Production
           (Result, Production_Aggregate_Open_Delimiter, Tok,
            "aggregate or parenthesized expression open delimiter");
         Add_Production (Result, Production_Association_List, Tok, "parenthesized association list");
         Advance (Position);
         if Current_Lower (Position) = "for"
           and then (Lookahead_Lower (Position, 1) = "all"
                     or else Lookahead_Lower (Position, 1) = "some")
         then
            Parse_Expression (Position, Result);
         elsif Current_Lower (Position) = "for" then
            Parse_Component_Association_Item (Position, Result, Tok);
         elsif Current_Lower (Position) = "declare" then
            --  Ada 2022 declare expressions have a declarative part followed
            --  by a single body expression.  Treat this as an expression
            --  primary, not as a block statement, so expression recovery and
            --  nested declarations remain structurally visible to the language
            --  model.
            Add_Production (Result, Production_Declare_Expression, Current (Position), "declare expression");
            Advance (Position);
            if not At_End (Position)
              and then Current_Lower (Position) /= "begin"
              and then To_String (Current (Position).Text) /= ")"
            then
               Add_Production
                 (Result, Production_Declare_Expression_Declarative_Part,
                  Current (Position), "declare expression declarative part");
            end if;
            while not At_End (Position)
              and then Current_Lower (Position) /= "begin"
              and then To_String (Current (Position).Text) /= ")"
            loop
               Parse_Declaration_Or_Statement (Position, Result);
            end loop;
            if Current_Lower (Position) = "begin" then
               Add_Production
                 (Result, Production_Declare_Expression_Begin_Keyword,
                  Current (Position), "declare expression begin keyword");
               Advance (Position);
               if At_Declare_Expression_Body_Boundary (Position) then
                  Add_Production
                    (Result,
                     Production_Declare_Expression_Missing_Body_Recovery_Boundary,
                     Current (Position),
                     "declare expression missing body recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected declare expression body expression");
               else
                  Add_Production
                    (Result, Production_Declare_Expression_Body_Expression,
                     Current (Position), "declare expression body expression");
                  Parse_Expression (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Declare_Expression_Missing_Begin_Recovery_Boundary,
                  Tok, "declare expression missing begin recovery boundary");
               Add_Production (Result, Production_Recovery_Point, Tok, "expected begin in declare expression");
            end if;
         elsif not At_End (Position) and then To_String (Current (Position).Text) /= ")" then
            if Has_Top_Level_With_Delta_Before_Association_End (Position) then
               Add_Production
                 (Result, Production_Delta_Aggregate_Base, Current (Position),
                  "delta aggregate base expression");
            elsif Has_Top_Level_With_Before_Association_End (Position) then
               Add_Production
                 (Result, Production_Extension_Aggregate_Ancestor,
                  Current (Position), "extension aggregate ancestor");
            end if;

            Parse_Component_Association_Item (Position, Result, Tok);

            if Current_Lower (Position) = "with" then
               if Lookahead_Lower (Position, 1) = "delta" then
                  Add_Production
                    (Result, Production_Delta_Aggregate_With_Keyword,
                     Current (Position), "delta aggregate with keyword");
                  Advance (Position);
                  Add_Production (Result, Production_Delta_Aggregate, Tok, "delta aggregate");
                  Add_Production
                    (Result, Production_Delta_Aggregate_Delta_Keyword,
                     Current (Position), "delta aggregate delta keyword");
                  Advance (Position);
                  Add_Production (Result, Production_Association_List, Current (Position), "delta associations");
                  if not At_End (Position)
                    and then (To_String (Current (Position).Text) = ")"
                              or else To_String (Current (Position).Text) = ";")
                  then
                     Add_Production
                       (Result, Production_Delta_Aggregate_Missing_Association_Recovery_Boundary,
                        Current (Position), "missing delta aggregate association");
                  end if;
                  while not At_End (Position)
                    and then To_String (Current (Position).Text) /= ")"
                    and then To_String (Current (Position).Text) /= ";"
                  loop
                     Add_Production
                       (Result, Production_Delta_Aggregate_Association,
                        Current (Position), "delta aggregate association");
                     Parse_Component_Association_Item (Position, Result, Tok);
                     if not At_End (Position)
                       and then To_String (Current (Position).Text) = ","
                     then
                        Add_Production
                          (Result, Production_Aggregate_Component_Separator,
                           Current (Position),
                           "delta aggregate association separator");
                        Add_Production
                          (Result, Production_Delta_Aggregate_Association_Separator,
                           Current (Position),
                           "delta aggregate association separator");
                     end if;
                     exit when not Match_Symbol (Position, ",");
                  end loop;
               else
                  Add_Production
                    (Result, Production_Extension_Aggregate_With_Keyword,
                     Current (Position), "extension aggregate with keyword");
                  Advance (Position);
                  Add_Production
                    (Result, Production_Extension_Aggregate, Tok,
                     "extension aggregate");
                  Add_Production
                    (Result, Production_Association_List, Current (Position),
                     "extension aggregate associations");
                  if Current_Lower (Position) = "null"
                    and then Lookahead_Lower (Position, 1) = "record"
                  then
                     Add_Production
                       (Result, Production_Null_Record_Aggregate,
                        Current (Position), "null record aggregate extension");
                     Add_Production
                       (Result, Production_Null_Record_Aggregate_Null_Keyword,
                        Current (Position), "null-record aggregate null keyword");
                     Advance (Position);
                     Add_Production
                       (Result, Production_Null_Record_Aggregate_Record_Keyword,
                        Current (Position), "null-record aggregate record keyword");
                     Advance (Position);
                  elsif Current_Lower (Position) = "null" then
                     Add_Production
                       (Result, Production_Null_Record_Aggregate,
                        Current (Position), "null record aggregate extension");
                     Add_Production
                       (Result, Production_Null_Record_Aggregate_Null_Keyword,
                        Current (Position), "null-record aggregate null keyword");
                     Add_Production
                       (Result,
                        Production_Null_Record_Aggregate_Missing_Record_Recovery_Boundary,
                        Current (Position),
                        "missing record keyword in null-record aggregate");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected record in null-record aggregate");
                     Advance (Position);
                  else
                     if not At_End (Position)
                       and then (To_String (Current (Position).Text) = ")"
                                 or else To_String (Current (Position).Text) = ";")
                     then
                        Add_Production
                          (Result,
                           Production_Extension_Aggregate_Missing_Association_Recovery_Boundary,
                           Current (Position),
                           "missing extension aggregate association");
                     end if;
                     while not At_End (Position)
                       and then To_String (Current (Position).Text) /= ")"
                       and then To_String (Current (Position).Text) /= ";"
                     loop
                        Add_Production
                          (Result,
                           Production_Extension_Aggregate_Component_Association,
                           Current (Position),
                           "extension aggregate component association");
                        Parse_Component_Association_Item (Position, Result, Tok);
                        if not At_End (Position)
                          and then To_String (Current (Position).Text) = ","
                        then
                           Add_Production
                             (Result, Production_Aggregate_Component_Separator,
                              Current (Position),
                              "extension aggregate component separator");
                           Add_Production
                             (Result,
                              Production_Extension_Aggregate_Component_Separator,
                              Current (Position),
                              "extension aggregate component separator");
                        end if;
                        exit when not Match_Symbol (Position, ",");
                     end loop;
                  end if;
               end if;
            else
               while not At_End (Position)
                 and then To_String (Current (Position).Text) = ","
               loop
                  Add_Production
                    (Result, Production_Aggregate_Component_Separator,
                     Current (Position), "aggregate component separator");
                  Advance (Position);
                  Parse_Component_Association_Item (Position, Result, Tok);
               end loop;
            end if;
         end if;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ")"
         then
            Add_Production
              (Result, Production_Aggregate_Close_Delimiter, Current (Position),
               "aggregate or parenthesized expression close delimiter");
            Add_Production
              (Result, Production_Parenthesized_Expression_Close_Delimiter,
               Current (Position),
               "parenthesized expression close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Aggregate_Missing_Close_Recovery_Boundary,
               Tok, "missing aggregate or parenthesized expression close delimiter");
            Add_Production
              (Result, Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary,
               Tok, "missing parenthesized expression close delimiter");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in primary");
         end if;
      else
         declare
            Saw_Selected_Subtype_Mark           : Boolean := False;
            Saw_Selected_Literal_Subtype_Mark   : Boolean := False;
            Saw_Selected_Operator_Subtype_Mark  : Boolean := False;
            Saw_Selected_Character_Subtype_Mark : Boolean := False;
         begin
            if Tok.Kind = Token_Identifier or else Tok.Kind = Token_Keyword then
               Add_Production (Result, Production_Name, Tok, To_String (Tok.Text));
            end if;
            Advance (Position);
            loop
               exit when At_End (Position);
               if To_String (Current (Position).Text) = "." then
                  Saw_Selected_Subtype_Mark := True;
                  if Lookahead_Kind (Position, 1) = Token_String_Literal then
                     Saw_Selected_Literal_Subtype_Mark := True;
                     Saw_Selected_Operator_Subtype_Mark := True;
                  elsif Lookahead_Kind (Position, 1) = Token_Character_Literal then
                     Saw_Selected_Literal_Subtype_Mark := True;
                     Saw_Selected_Character_Subtype_Mark := True;
                  elsif Lookahead_Kind (Position, 1) /= Token_Identifier
                    and then Lookahead_Kind (Position, 1) /= Token_Keyword
                  then
                     Add_Production
                       (Result, Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark,
                        Tok, "qualified-expression incomplete selected subtype mark");
                  end if;
                  Parse_Selected_Name_Suffix
                    (Position, Result, Tok, "selected name");
               elsif To_String (Current (Position).Text) = "'" then
                  if Lookahead_Lower (Position, 1) = "(" then
                     Add_Production (Result, Production_Qualified_Expression, Tok, To_String (Tok.Text));
                     Add_Production
                       (Result, Production_Conversion_Or_Qualified_Expression,
                        Tok, "qualified expression or conversion context");
                     Add_Production
                       (Result, Production_Qualified_Expression_Subtype_Mark,
                        Tok, "qualified-expression subtype mark");
                     if Saw_Selected_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Subtype_Mark,
                           Tok, "qualified-expression selected subtype mark");
                     end if;
                     if Saw_Selected_Literal_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Literal_Subtype_Mark,
                           Tok, "qualified-expression selected literal subtype mark");
                     end if;
                     if Saw_Selected_Operator_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Operator_Subtype_Mark,
                           Tok, "qualified-expression selected operator subtype mark");
                     end if;
                     if Saw_Selected_Character_Subtype_Mark then
                        Add_Production
                          (Result, Production_Qualified_Expression_Selected_Character_Subtype_Mark,
                           Tok, "qualified-expression selected character subtype mark");
                     end if;
                     Add_Production
                       (Result, Production_Qualified_Expression_Apostrophe,
                        Current (Position), "qualified-expression apostrophe");
                     Advance (Position);
                     if To_String (Current (Position).Text) = "(" then
                        Add_Production
                          (Result, Production_Qualified_Expression_Operand,
                           Current (Position), "qualified-expression operand");
                        if Qualified_Operand_Is_Missing (Position) then
                           Add_Production
                             (Result, Production_Qualified_Expression_Missing_Operand_Recovery_Boundary,
                              Current (Position), "qualified-expression missing operand recovery boundary");
                           Add_Production
                             (Result, Production_Recovery_Point, Current (Position),
                              "expected qualified-expression operand before boundary");
                        end if;
                     end if;
                     Parse_Association_List (Position, Result, Qualified_Expression_Operand => True);
                  else
                  if Saw_Selected_Subtype_Mark then
                     Add_Production
                       (Result, Production_Attribute_Selected_Prefix, Tok,
                        "attribute reference with selected-name prefix");
                     Add_Production
                       (Result, Production_Attribute_Complex_Prefix, Tok,
                        "attribute reference with complex prefix");
                  end if;
                  Add_Production
                    (Result, Production_Chained_Attribute_Reference, Tok,
                     "chained attribute reference");
                  Add_Production (Result, Production_Attribute_Reference, Tok, To_String (Tok.Text));
                  Advance (Position);
                  if not At_End (Position) then
                     declare
                        Attribute_Name : constant String := Current_Lower (Position);
                     begin
                        Add_Production
                          (Result, Production_Attribute_Designator_Name,
                           Current (Position), To_String (Current (Position).Text));
                        if Attribute_Name = "range" then
                           Add_Production
                             (Result, Production_Range_Attribute_Reference,
                              Tok, "range attribute reference");
                           Add_Production
                             (Result, Production_Range_Attribute_Prefix,
                              Tok, "range attribute prefix");
                        end if;
                        if Attribute_Name = "class"
                          and then Lookahead_Lower (Position, 1) = "'"
                        then
                           Add_Production
                             (Result, Production_Classwide_Attribute_Reference,
                              Tok, "class-wide attribute reference");
                        end if;
                        if Attribute_Name = "reduce"
                          or else Attribute_Name = "parallel_reduce"
                          or else Attribute_Name = "map_reduce"
                        then
                           Add_Production
                             (Result, Production_Reduction_Expression, Tok,
                              Attribute_Name);
                           if Attribute_Name = "parallel_reduce" then
                              Add_Production
                                (Result, Production_Parallel_Reduction_Expression, Tok,
                                 Attribute_Name);
                           elsif Attribute_Name = "map_reduce" then
                              Add_Production
                                (Result, Production_Map_Reduction_Expression, Tok,
                                 Attribute_Name);
                           end if;
                           Advance (Position);
                           if To_String (Current (Position).Text) = "(" then
                              Parse_Reduction_Argument_Part
                                (Position, Result, Tok, Attribute_Name);
                           end if;
                        else
                           Advance (Position);
                           if To_String (Current (Position).Text) = "(" then
                              --  Ada attribute references can carry an optional
                              --  argument association part, for example
                              --  ``A'First (1)`` and Ada 2022 image-style
                              --  attribute calls.  Keep those parentheses
                              --  attached to the attribute reference rather than
                              --  letting the name-suffix loop misclassify them as
                              --  an ordinary indexed component of the attribute
                              --  result.
                              Parse_Attribute_Argument_List
                                (Position, Result, Tok,
                                 "attribute argument part");
                           end if;
                        end if;
                     end;
                  end if;
               end if;
            elsif To_String (Current (Position).Text) = "(" then
               if Parenthesized_Name_Suffix_Is_Slice (Position) then
                  Add_Production (Result, Production_Slice, Tok, To_String (Tok.Text));
               else
                  Add_Production
                    (Result, Production_Call_Or_Indexed_Component, Tok,
                     "call or indexed component suffix");
                  Add_Production (Result, Production_Indexed_Component, Tok, To_String (Tok.Text));
               end if;
               Parse_Association_List (Position, Result);
               else
                  exit;
               end if;
            end loop;
         end;
      end if;
   end Parse_Primary;

   procedure Parse_Factor (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Factor, Tok, To_String (Tok.Text));
      if Current_Lower (Position) = "abs" or else Current_Lower (Position) = "not"
        or else To_String (Current (Position).Text) = "+"
        or else To_String (Current (Position).Text) = "-"
      then
         Add_Production (Result, Production_Unary_Expression, Current (Position), To_String (Current (Position).Text));
         Advance (Position);
      end if;
      Parse_Primary (Position, Result);
      if not At_End (Position) and then To_String (Current (Position).Text) = "**" then
         Add_Production
           (Result, Production_Expression_Operator, Current (Position), "**");
         Advance (Position);
         Parse_Primary (Position, Result);
      end if;
   end Parse_Factor;

   procedure Parse_Term (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Term, Tok, To_String (Tok.Text));
      Parse_Factor (Position, Result);
      while not At_End (Position)
        and then (To_String (Current (Position).Text) = "*"
                  or else To_String (Current (Position).Text) = "/"
                  or else Current_Lower (Position) = "mod"
                  or else Current_Lower (Position) = "rem")
      loop
         Add_Production
           (Result, Production_Expression_Operator, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         Parse_Factor (Position, Result);
      end loop;
   end Parse_Term;

   procedure Parse_Simple_Expression (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Simple_Expression, Tok, To_String (Tok.Text));
      Parse_Term (Position, Result);
      while not At_End (Position)
        and then (To_String (Current (Position).Text) = "+"
                  or else To_String (Current (Position).Text) = "-"
                  or else To_String (Current (Position).Text) = "&")
      loop
         Add_Production
           (Result, Production_Expression_Operator, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         Parse_Term (Position, Result);
      end loop;
   end Parse_Simple_Expression;

   procedure Parse_Relation (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Membership_Choice_Recovery_Boundary return Boolean is
      begin
         if At_End (Position) then
            return True;
         end if;

         declare
            T : constant String := To_String (Current (Position).Text);
            L : constant String := Current_Lower (Position);
         begin
            return T = "|"
              or else T = ";"
              or else T = ")"
              or else T = ","
              or else T = "=>"
              or else L = "then"
              or else L = "else"
              or else L = "loop"
              or else L = "is"
              or else L = "begin"
              or else L = "end";
         end;
      end At_Membership_Choice_Recovery_Boundary;

      procedure Parse_Membership_Choice is
         Choice_Tok : constant Token_Info := Current (Position);
      begin
         Add_Production
           (Result, Production_Membership_Choice, Choice_Tok,
            "membership choice");

         if Current_Lower (Position) = "range" then
            Add_Production
              (Result, Production_Range_Expression, Choice_Tok,
               "membership range");
            Advance (Position);
            Parse_Simple_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Parse_Simple_Expression (Position, Result);
            end if;
         else
            Parse_Simple_Expression (Position, Result);
            if Match_Symbol (Position, "..") then
               Add_Production
                 (Result, Production_Range_Expression, Choice_Tok,
                  "membership choice range");
               Parse_Simple_Expression (Position, Result);
            elsif Current_Lower (Position) = "range" then
               Add_Production
                 (Result, Production_Range_Expression, Choice_Tok,
                  "membership subtype range");
               Advance (Position);
               Parse_Simple_Expression (Position, Result);
               if Match_Symbol (Position, "..") then
                  Parse_Simple_Expression (Position, Result);
               end if;
            end if;
         end if;
      end Parse_Membership_Choice;
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Relation, Tok, To_String (Tok.Text));
      Parse_Simple_Expression (Position, Result);
      if not At_End (Position)
        and then (To_String (Current (Position).Text) = "="
                  or else To_String (Current (Position).Text) = "/="
                  or else To_String (Current (Position).Text) = "<"
                  or else To_String (Current (Position).Text) = "<="
                  or else To_String (Current (Position).Text) = ">"
                  or else To_String (Current (Position).Text) = ">="
                  or else Current_Lower (Position) = "in"
                  or else (Current_Lower (Position) = "not" and then Lookahead_Lower (Position, 1) = "in"))
      then
         declare
            Op_Tok : constant Token_Info := Current (Position);
         begin
            if Current_Lower (Position) = "not" and then Lookahead_Lower (Position, 1) = "in" then
               Add_Production (Result, Production_Membership_Operator, Op_Tok, "not in");
               Advance (Position);
               Advance (Position);
               Add_Production (Result, Production_Membership_Choice_List, Op_Tok, "not in");
               if At_Membership_Choice_Recovery_Boundary then
                  Add_Production
                    (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                     Op_Tok, "membership choice list missing first choice recovery boundary");
               else
                  Parse_Membership_Choice;
                  while not At_End (Position)
                    and then To_String (Current (Position).Text) = "|"
                  loop
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Membership_Choice_Separator,
                           Separator_Tok, "membership choice separator");
                        Advance (Position);
                        if At_Membership_Choice_Recovery_Boundary then
                           Add_Production
                             (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok, "membership choice list missing choice recovery boundary");
                           exit;
                        end if;
                        Parse_Membership_Choice;
                     end;
                  end loop;
               end if;
            elsif Current_Lower (Position) = "in" then
               Add_Production (Result, Production_Membership_Operator, Op_Tok, "in");
               Advance (Position);
               Add_Production (Result, Production_Membership_Choice_List, Op_Tok, "in");
               if At_Membership_Choice_Recovery_Boundary then
                  Add_Production
                    (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                     Op_Tok, "membership choice list missing first choice recovery boundary");
               else
                  Parse_Membership_Choice;
                  while not At_End (Position)
                    and then To_String (Current (Position).Text) = "|"
                  loop
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Membership_Choice_Separator,
                           Separator_Tok, "membership choice separator");
                        Advance (Position);
                        if At_Membership_Choice_Recovery_Boundary then
                           Add_Production
                             (Result, Production_Membership_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok, "membership choice list missing choice recovery boundary");
                           exit;
                        end if;
                        Parse_Membership_Choice;
                     end;
                  end loop;
               end if;
            else
               Add_Production
                 (Result, Production_Relational_Operator, Op_Tok,
                  To_String (Op_Tok.Text));
               Advance (Position);
               Parse_Simple_Expression (Position, Result);
            end if;
         end;
      end if;
   end Parse_Relation;

   procedure Parse_Expression (Position : in out Cursor; Result : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;
      Add_Production (Result, Production_Expression, Tok, To_String (Tok.Text));
      Parse_Relation (Position, Result);
      while not At_End (Position)
        and then (Current_Lower (Position) = "and" or else Current_Lower (Position) = "or" or else Current_Lower (Position) = "xor")
      loop
         declare
            Op_Tok : constant Token_Info := Current (Position);
            Op     : constant String := Current_Lower (Position);
         begin
            Add_Production
              (Result, Production_Expression_Operator, Op_Tok, Op);
            if Op = "and" or else Op = "or" then
               Add_Production
                 (Result, Production_Short_Circuit_Operation, Op_Tok, Op);
            end if;
            Advance (Position);
            if (Op = "and" and then Current_Lower (Position) = "then")
              or else (Op = "or" and then Current_Lower (Position) = "else")
            then
               Advance (Position);
            end if;
            Parse_Relation (Position, Result);
         end;
      end loop;
   end Parse_Expression;


   procedure Parse_Discrete_Choice_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Discrete_Choice_List, Tok,
         "discrete choice list");

      loop
         exit when At_End (Position);
         exit when To_String (Current (Position).Text) = Stop;
         exit when Current_Lower (Position) = Stop;
         exit when To_String (Current (Position).Text) = ";";

         declare
            Choice_Tok : constant Token_Info := Current (Position);
         begin
            Add_Production
              (Result, Production_Discrete_Choice, Choice_Tok,
               To_String (Choice_Tok.Text));

            if Current_Lower (Position) = "others" then
               Advance (Position);
            elsif (Current (Position).Kind = Token_Identifier
                   or else Current (Position).Kind = Token_Keyword)
              and then (Lookahead_Lower (Position, 1) = "|"
                        or else Lookahead_Lower (Position, 1) = Stop)
            then
               Advance (Position);
            else
               Parse_Expression (Position, Result);
               if Match_Symbol (Position, "..") then
                  Add_Production
                    (Result, Production_Range_Expression, Choice_Tok,
                     "discrete choice range");
                  Parse_Expression (Position, Result);
               end if;
            end if;
         end;

         if To_String (Current (Position).Text) = "|" then
            Add_Production
              (Result, Production_Discrete_Choice_Separator, Current (Position),
               "discrete choice separator");
            Advance (Position);
            if At_End (Position)
              or else To_String (Current (Position).Text) = Stop
              or else Current_Lower (Position) = Stop
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result, Production_Discrete_Choice_Missing_Choice_Recovery_Boundary,
                  Tok, "discrete choice missing choice recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected discrete choice after separator");
               exit;
            end if;
         else
            exit;
         end if;
      end loop;
   end Parse_Discrete_Choice_List;





   function Is_In_Exception_Context (Position : Cursor) return Boolean is
      I : Natural := Position.Index;
   begin
      --  Conservative linear-context check used only to distinguish statement
      --  level exception handlers from case alternatives.  The parser remains
      --  bounded and snapshot-local; this does not attempt full legality or
      --  nesting validation.
      while I > 1 loop
         I := I - 1;
         declare
            L : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Lower);
         begin
            if L = "exception" then
               return True;
            elsif L = "case" or else L = "select" then
               return False;
            end if;
         end;
      end loop;
      return False;
   end Is_In_Exception_Context;


   function Is_In_Select_Context (Position : Cursor) return Boolean is
      Depth : Natural := 0;
      I     : Positive := 1;
   begin
      while I < Position.Index loop
         declare
            L : constant String :=
              To_String (Position.Stream.Tokens (I).Lower);
         begin
            if L = "select" then
               Depth := Depth + 1;
            elsif L = "end"
              and then I + 1 < Position.Index
              and then To_String (Position.Stream.Tokens (I + 1).Lower) = "select"
            then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
               I := I + 1;
            end if;
         end;
         I := I + 1;
      end loop;
      return Depth > 0;
   end Is_In_Select_Context;




   function Select_Has_Then_Abort
     (Position : Cursor) return Boolean is
      Depth : Natural := (if Current_Lower (Position) = "select" then 0 else 1);
      I     : Natural := Position.Index;
   begin
      while I <= Natural (Position.Stream.Tokens.Length) loop
         declare
            L : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Lower);
         begin
            if L = "select" then
               Depth := Depth + 1;
            elsif L = "end"
              and then I + 1 <= Natural (Position.Stream.Tokens.Length)
              and then To_String (Position.Stream.Tokens (Positive (I + 1)).Lower) = "select"
            then
               if Depth = 0 then
                  return False;
               end if;
               Depth := Depth - 1;
               if Depth = 0 then
                  return False;
               end if;
               I := I + 1;
            elsif L = "then"
              and then I + 1 <= Natural (Position.Stream.Tokens.Length)
              and then To_String (Position.Stream.Tokens (Positive (I + 1)).Lower) = "abort"
              and then Depth = 1
            then
               return True;
            end if;
         end;
         I := I + 1;
      end loop;
      return False;
   end Select_Has_Then_Abort;


   function Select_Has_Else_Alternative
     (Position : Cursor) return Boolean is
      Depth : Natural := (if Current_Lower (Position) = "select" then 0 else 1);
      I     : Natural := Position.Index;
   begin
      while I <= Natural (Position.Stream.Tokens.Length) loop
         declare
            L : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Lower);
         begin
            if L = "select" then
               Depth := Depth + 1;
            elsif L = "end"
              and then I + 1 <= Natural (Position.Stream.Tokens.Length)
              and then To_String (Position.Stream.Tokens (Positive (I + 1)).Lower) = "select"
            then
               if Depth = 0 then
                  return False;
               end if;
               Depth := Depth - 1;
               if Depth = 0 then
                  return False;
               end if;
               I := I + 1;
            elsif L = "else" and then Depth = 1 then
               return True;
            end if;
         end;
         I := I + 1;
      end loop;
      return False;
   end Select_Has_Else_Alternative;

   function Is_Select_Alternative_Statement_Boundary
     (Position : Cursor) return Boolean is
      L0 : constant String := Current_Lower (Position);
      L1 : constant String := Lookahead_Lower (Position, 1);
      T0 : constant String :=
        (if At_End (Position) then "" else To_String (Current (Position).Text));
   begin
      return At_End (Position)
        or else L0 = "or"
        or else L0 = "else"
        or else L0 = "terminate"
        or else (L0 = "then" and then L1 = "abort")
        or else (L0 = "end" and then L1 = "select")
        or else T0 = ";";
   end Is_Select_Alternative_Statement_Boundary;


   function Select_Has_Delay_Alternative
     (Position : Cursor) return Boolean is
      Depth : Natural := (if Current_Lower (Position) = "select" then 0 else 1);
      I     : Natural := Position.Index;
   begin
      while I <= Natural (Position.Stream.Tokens.Length) loop
         declare
            L : constant String :=
              To_String (Position.Stream.Tokens (Positive (I)).Lower);
         begin
            if L = "select" then
               Depth := Depth + 1;
            elsif L = "end"
              and then I + 1 <= Natural (Position.Stream.Tokens.Length)
              and then To_String (Position.Stream.Tokens (Positive (I + 1)).Lower) = "select"
            then
               if Depth = 0 then
                  return False;
               end if;
               Depth := Depth - 1;
               if Depth = 0 then
                  return False;
               end if;
               I := I + 1;
            elsif L = "delay" and then Depth = 1 then
               return True;
            end if;
         end;
         I := I + 1;
      end loop;
      return False;
   end Select_Has_Delay_Alternative;


   procedure Parse_Select_Guard
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Anchor   : Token_Info) is
      function At_Select_Guard_Condition_Boundary return Boolean is
         T : constant String := To_String (Current (Position).Text);
         L : constant String := Current_Lower (Position);
      begin
         return At_End (Position)
           or else T = "=>"
           or else T = ";"
           or else L = "accept"
           or else L = "delay"
           or else L = "terminate"
           or else L = "else"
           or else L = "or"
           or else L = "then"
           or else L = "abort"
           or else L = "end";
      end At_Select_Guard_Condition_Boundary;
   begin
      if Current_Lower (Position) = "when" then
         --  Select alternatives can carry a guard:
         --     when Condition => accept ...
         --  This is expression grammar, not a discrete choice list.  Keep it
         --  structurally separate from case alternatives and exception
         --  handlers so later syntax/semantic passes can recover the exact
         --  select-alternative shape.
         Add_Production
           (Result, Production_Select_Guard, Current (Position),
            "select guard");
         Advance (Position);
         if At_Select_Guard_Condition_Boundary then
            Add_Production
              (Result, Production_Select_Guard_Missing_Condition_Recovery_Boundary, Anchor,
               "select guard missing condition recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary, Anchor,
               "select guard condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected condition after select guard when");
         else
            Add_Production
              (Result, Production_Select_Guard_Condition, Current (Position),
               "select guard condition");
            Parse_Expression (Position, Result);
         end if;
         if To_String (Current (Position).Text) = "=>" then
            Add_Production
              (Result, Production_Select_Guard_Arrow, Current (Position),
               "select guard arrow");
         end if;
         if not Match_Symbol (Position, "=>") then
            Add_Production
              (Result, Production_Select_Guard_Missing_Arrow_Recovery_Boundary, Anchor,
               "select guard missing arrow recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary, Anchor,
               "select guard recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Anchor,
               "expected => after select guard");
         end if;
      end if;
   end Parse_Select_Guard;


   procedure Parse_Pragma_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Pragma_Argument_List, Tok,
         "pragma argument list");
      Add_Production
        (Result, Production_Association_List, Tok,
         "pragma argument list");
      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Pragma_Argument_List_Open_Delimiter,
            Current (Position), "pragma argument-list open delimiter");
      end if;
      if not Match_Symbol (Position, "(") then
         return;
      end if;

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Pragma_Argument_List_Empty_Recovery_Boundary,
            Tok, "pragma argument-list empty recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected pragma argument association before )");
         Add_Production
           (Result, Production_Pragma_Argument_List_Close_Delimiter,
            Current (Position), "pragma argument-list close delimiter");
         Advance (Position);
         return;
      end if;

      --  pragma_argument_association ::= [pragma_argument_identifier =>] name
      --                                |  [pragma_argument_identifier =>] expression
      --
      --  Keep the pragma-specific list, association, optional identifier,
      --  and argument expression visible.  The existing generic association
      --  list production is still emitted for older tests and consumers, but
      --  pragma parsing no longer depends on ordinary expression fallback for
      --  the argument-list shape.
      while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
         declare
            Arg_Tok : constant Token_Info := Current (Position);
         begin
            if To_String (Arg_Tok.Text) = ";" then
               Add_Production
                 (Result, Production_Recovery_Point, Arg_Tok,
                  "expected ) in pragma argument list");
               exit;
            end if;

            Add_Production
              (Result, Production_Pragma_Argument_Association, Arg_Tok,
               To_String (Arg_Tok.Text));

            if (Current (Position).Kind = Token_Identifier
                or else Current (Position).Kind = Token_Keyword)
              and then Lookahead_Lower (Position, 1) = "=>"
            then
               Add_Production
                 (Result, Production_Pragma_Argument_Named_Association,
                  Arg_Tok, To_String (Arg_Tok.Text));
               Add_Production
                 (Result, Production_Pragma_Argument_Identifier,
                  Current (Position), To_String (Current (Position).Text));
               Advance (Position);
               if not Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Recovery_Point, Arg_Tok,
                     "expected => in pragma argument association");
               end if;
            else
               Add_Production
                 (Result, Production_Pragma_Argument_Positional_Association,
                  Arg_Tok, To_String (Arg_Tok.Text));
            end if;

            if To_String (Current (Position).Text) = ")"
              or else To_String (Current (Position).Text) = ","
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result, Production_Pragma_Argument_Missing_Expression_Recovery_Boundary,
                  Arg_Tok, "pragma argument missing expression recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Arg_Tok,
                  "expected pragma argument expression");
            elsif To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Pragma_Argument_Box,
                  Current (Position), "pragma argument box");
               Add_Production
                 (Result, Production_Pragma_Argument_Expression,
                  Current (Position), To_String (Current (Position).Text));
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Pragma_Argument_Expression,
                  Current (Position), To_String (Current (Position).Text));
               Parse_Expression (Position, Result);
            end if;

            if not At_End (Position)
              and then To_String (Current (Position).Text) = ","
            then
               Add_Production
                 (Result, Production_Pragma_Argument_Association_Separator,
                  Current (Position), "pragma argument association separator");
               Advance (Position);
               if To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Pragma_Argument_Trailing_Separator_Recovery_Boundary,
                     Arg_Tok, "pragma argument trailing separator recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Arg_Tok,
                     "expected pragma argument after separator");
               end if;
            else
               exit;
            end if;
         end;
      end loop;
      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Pragma_Argument_List_Close_Delimiter,
            Current (Position), "pragma argument-list close delimiter");
         Advance (Position);
      else
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Pragma_Argument_Association_Separator,
               Current (Position),
               "pragma argument missing-close synchronization separator");
         end if;
         Add_Production
           (Result, Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary,
            Tok, "pragma argument-list missing close recovery boundary");
         Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in pragma argument list");
      end if;
   end Parse_Pragma_Argument_List;


   function Is_Representation_Pragma_Identifier (Lower_Name : String) return Boolean is
   begin
      return Lower_Name = "pack"
        or else Lower_Name = "atomic"
        or else Lower_Name = "volatile"
        or else Lower_Name = "independent"
        or else Lower_Name = "atomic_components"
        or else Lower_Name = "volatile_components"
        or else Lower_Name = "independent_components"
        or else Lower_Name = "unchecked_union"
        or else Lower_Name = "convention"
        or else Lower_Name = "import"
        or else Lower_Name = "export"
        or else Lower_Name = "interface"
        or else Lower_Name = "external"
        or else Lower_Name = "linker_section"
        or else Lower_Name = "machine_attribute"
        or else Lower_Name = "attach_handler"
        or else Lower_Name = "interrupt_handler"
        or else Lower_Name = "discard_names"
        or else Lower_Name = "suppress_initialization";
   end Is_Representation_Pragma_Identifier;


   function Is_Operational_Pragma_Identifier (Lower_Name : String) return Boolean is
   begin
      return Is_Representation_Pragma_Identifier (Lower_Name)
        or else Lower_Name = "priority"
        or else Lower_Name = "interrupt_priority"
        or else Lower_Name = "cpu"
        or else Lower_Name = "dispatching_domain"
        or else Lower_Name = "relative_deadline"
        or else Lower_Name = "max_entry_queue_length"
        or else Lower_Name = "inline"
        or else Lower_Name = "inline_always"
        or else Lower_Name = "no_return"
        or else Lower_Name = "preelaborate"
        or else Lower_Name = "pure"
        or else Lower_Name = "elaborate_body"
        or else Lower_Name = "remote_types"
        or else Lower_Name = "remote_call_interface"
        or else Lower_Name = "all_calls_remote"
        or else Lower_Name = "shared_passive"
        or else Lower_Name = "no_tagged_streams"
        or else Lower_Name = "assertion_policy"
        or else Lower_Name = "check_policy"
        or else Lower_Name = "debug_policy"
        or else Lower_Name = "restrictions"
        or else Lower_Name = "restriction_warnings"
        or else Lower_Name = "profile"
        or else Lower_Name = "suppress"
        or else Lower_Name = "unsuppress"
        or else Lower_Name = "spark_mode";
   end Is_Operational_Pragma_Identifier;


   procedure Parse_Pragma
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      Pragma_Name : Unbounded_String := Null_Unbounded_String;
   begin
      Add_Production (Result, Production_Pragma, Tok, "pragma");
      if not Match_Keyword (Position, "pragma") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected pragma keyword");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      --  pragma ::= pragma identifier [(pragma_argument_association {, ...})];
      --
      --  Keep the pragma identifier distinct from the argument list so
      --  nullary pragmas and declaration/statement-sequence pragmas retain
      --  their grammar shape without relying on expression fallback.
      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Pragma_Name := To_Unbounded_String (Current_Lower (Position));
         Add_Production
           (Result, Production_Pragma_Identifier, Current (Position),
            To_String (Current (Position).Text));
         if Is_Representation_Pragma_Identifier (To_String (Pragma_Name)) then
            Add_Production
              (Result, Production_Representation_Pragma, Current (Position),
               To_String (Current (Position).Text));
         end if;
         if Is_Operational_Pragma_Identifier (To_String (Pragma_Name)) then
            Add_Production
              (Result, Production_Operational_Pragma, Current (Position),
               To_String (Current (Position).Text));
            Add_Production
              (Result, Production_Operational_Item, Current (Position),
               "pragma operational item");
         end if;
         Advance (Position);
      else
         Add_Production
           (Result, Production_Pragma_Identifier_Missing_Recovery_Boundary, Tok,
            "pragma identifier missing recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected pragma identifier");
      end if;

      if To_String (Current (Position).Text) = "(" then
         Parse_Pragma_Argument_List (Position, Result);
      else
         Add_Production
           (Result, Production_Nullary_Pragma, Tok,
            "nullary pragma");
      end if;

      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Pragma_Missing_Terminator_Recovery_Boundary, Tok,
            "pragma missing terminator recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ; after pragma");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Pragma;


   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean;

   procedure Mark_Generic_Actual_Nested_Actuals
     (Position : Cursor;
      Result   : in out Grammar_Result);


   procedure Parse_Generic_Actual_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);

      function At_Generic_Actual_Value_Boundary return Boolean is
      begin
         if At_End (Position) then
            return True;
         end if;

         declare
            Text  : constant String := To_String (Current (Position).Text);
            Lower : constant String := Current_Lower (Position);
         begin
            return Text = ")"
              or else Text = ","
              or else Text = ";"
              or else Lower = "is"
              or else Lower = "begin"
              or else Lower = "end"
              or else Lower = "private";
         end;
      end At_Generic_Actual_Value_Boundary;
   begin
      Add_Production (Result, Production_Generic_Actual_Part, Tok, "generic actual part");
      if not Match_Symbol (Position, "(") then
         return;
      end if;
      Add_Production
        (Result, Production_Generic_Actual_Part_Open_Delimiter, Tok,
         "generic actual part open delimiter");

      if To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Generic_Actual_Empty_List_Recovery_Boundary,
            Current (Position), "empty generic actual list recovery boundary");
         Add_Production
           (Result, Production_Generic_Actual_Recovery_Boundary,
            Current (Position), "generic actual recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected generic actual association");
      end if;

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         declare
            Actual_Tok : constant Token_Info := Current (Position);
            Named     : Boolean := False;
         begin
            Add_Production
              (Result, Production_Generic_Actual_Association, Actual_Tok,
               To_String (Actual_Tok.Text));

            --  A generic association may be positional, or it may start with
            --  a generic_formal_parameter_selector_name followed by =>.
            --  Retain named-vs-positional shape explicitly so instantiation
            --  actual lists no longer rely on expression recovery to infer it.
            if (Current (Position).Kind = Token_Identifier
                or else Current (Position).Kind = Token_Keyword
                or else Current (Position).Kind = Token_String_Literal)
              and then Lookahead_Lower (Position, 1) = "=>"
            then
               Named := True;
               Add_Production
                 (Result, Production_Generic_Actual_Formal_Selector,
                  Current (Position), To_String (Current (Position).Text));
               if Current (Position).Kind = Token_String_Literal then
                  Add_Production
                    (Result, Production_Defining_Operator_Symbol,
                     Current (Position), To_String (Current (Position).Text));
               else
                  Add_Production
                    (Result, Production_Name, Current (Position),
                     To_String (Current (Position).Text));
               end if;
               Advance (Position);
               if not Match_Symbol (Position, "=>") then
                  Add_Production
                    (Result, Production_Recovery_Point, Actual_Tok,
                     "expected => in generic actual association");
               end if;
            else
               Add_Production
                 (Result, Production_Generic_Actual_Positional_Association,
                  Actual_Tok, "generic positional actual association");
            end if;

            if To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Generic_Actual_Box, Current (Position),
                  "generic actual box default");
               if Named then
                  Add_Production
                    (Result, Production_Generic_Actual_Association_Box,
                     Current (Position),
                     "generic named actual association box");
               end if;
               Advance (Position);
            elsif At_Generic_Actual_Value_Boundary then
               Add_Production
                 (Result,
                  Production_Generic_Actual_Missing_Actual_Recovery_Boundary,
                  Current (Position),
                  "missing generic actual association value");
               Add_Production
                 (Result, Production_Generic_Actual_Recovery_Boundary,
                  Current (Position), "generic actual recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected generic actual association value");
            else
               Mark_Generic_Actual_Nested_Actuals (Position, Result);
               Parse_Expression (Position, Result);
            end if;

            if To_String (Current (Position).Text) = "," then
               Add_Production
                 (Result, Production_Generic_Actual_Association_Separator,
                  Current (Position),
                  "generic actual association separator");
               Advance (Position);
            else
               exit;
            end if;

            if To_String (Current (Position).Text) = ")"
              or else To_String (Current (Position).Text) = ";"
              or else Starts_Strong_Package_Declarative_Item (Position)
            then
               Add_Production
                 (Result,
                  Production_Generic_Actual_Trailing_Separator_Recovery_Boundary,
                  Current (Position),
                  "trailing generic actual association separator");
               Add_Production
                 (Result, Production_Generic_Actual_Recovery_Boundary,
                  Current (Position), "generic actual recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected generic actual association after separator");
               exit;
            end if;
         end;
      end loop;

      if Starts_Strong_Package_Declarative_Item (Position) then
         Add_Production
           (Result, Production_Generic_Actual_Recovery_Boundary,
            Current (Position), "generic actual recovery boundary");
         Add_Production
           (Result, Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary,
            Tok, "generic actual part missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in generic actual part before declaration boundary");
      elsif To_String (Current (Position).Text) = ";" then
         Add_Production
           (Result, Production_Generic_Actual_Recovery_Boundary,
            Current (Position), "generic actual recovery boundary");
         Add_Production
           (Result, Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary,
            Tok, "generic actual part missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in generic actual part");
      elsif To_String (Current (Position).Text) = ")" then
         Add_Production
           (Result, Production_Generic_Actual_Part_Close_Delimiter,
            Current (Position), "generic actual part close delimiter");
         Advance (Position);
      else
         Add_Production
           (Result, Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary,
            Tok, "generic actual part missing close recovery boundary");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected ) in generic actual part");
      end if;
   end Parse_Generic_Actual_Part;



   procedure Parse_Generic_Instantiated_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Origin : constant Token_Info := Current (Position);
   begin
      if At_End (Position) then
         return;
      end if;

      Add_Production
        (Result, Production_Generic_Instantiated_Unit_Name, Origin,
         "instantiated generic unit name");

      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Name, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Current (Position),
            "expected instantiated generic unit name");
         return;
      end if;

      while not At_End (Position)
        and then To_String (Current (Position).Text) = "."
      loop
         Parse_Selected_Name_Suffix
           (Position, Result, Origin, "instantiated generic unit name");
      end loop;
   end Parse_Generic_Instantiated_Unit_Name;


   function Starts_Generic_Instantiation
     (Position  : Cursor;
      Unit_Kind : String) return Boolean is
      Probe : Cursor := Position;
   begin
      if Current_Lower (Probe) /= Unit_Kind then
         return False;
      end if;

      Advance (Probe);

      if Unit_Kind = "package" then
         if Current (Probe).Kind /= Token_Identifier
           and then Current (Probe).Kind /= Token_Keyword
         then
            return False;
         end if;

         Advance (Probe);
         while not At_End (Probe)
           and then To_String (Current (Probe).Text) = "."
         loop
            Advance (Probe);
            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
            then
               Advance (Probe);
            else
               return False;
            end if;
         end loop;
      else
         while not At_End (Probe)
           and then Current_Lower (Probe) /= "is"
           and then To_String (Current (Probe).Text) /= ";"
         loop
            Advance (Probe);
         end loop;
      end if;

      if Current_Lower (Probe) /= "is" then
         return False;
      end if;

      Advance (Probe);
      return Current_Lower (Probe) = "new";
   end Starts_Generic_Instantiation;


   procedure Parse_Generic_Instantiation_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Unit_Kind : String) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Generic_Instantiation, Tok,
         Unit_Kind & " instantiation");
      if Unit_Kind = "package" then
         Add_Production
           (Result, Production_Generic_Package_Instantiation, Tok,
            "generic package instantiation");
      elsif Unit_Kind = "procedure" then
         Add_Production
           (Result, Production_Generic_Procedure_Instantiation, Tok,
            "generic procedure instantiation");
      elsif Unit_Kind = "function" then
         Add_Production
           (Result, Production_Generic_Function_Instantiation, Tok,
            "generic function instantiation");
      end if;

      --  generic_instantiation ::=
      --     package   defining_program_unit_name is new generic_package_name
      --       [generic_actual_part] [aspect_specification];
      --   | procedure defining_program_unit_name is new generic_procedure_name
      --       [generic_actual_part] [aspect_specification];
      --   | function  defining_designator is new generic_function_name
      --       [generic_actual_part] [aspect_specification];
      --
      --  Keep the instance name and instantiated generic unit name visible so
      --  Outline and semantic-colouring consumers do not have to infer them
      --  from a flattened instantiation declaration span.
      if Current_Lower (Position) = Unit_Kind then
         Advance (Position);
      end if;

      if not At_End (Position) then
         Add_Production
           (Result, Production_Generic_Instance_Name, Current (Position),
            "generic instance defining name");
         Parse_Defining_Program_Unit_Name (Position, Result);
      end if;

      if Current_Lower (Position) = "is" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected is in generic instantiation");
         Skip_Balanced_To (Position, "new", ";");
      end if;

      if Current_Lower (Position) = "new" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected new in generic instantiation");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      Parse_Generic_Instantiated_Unit_Name (Position, Result);

      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Generic_Instantiation_Actual_Part,
            Current (Position), "generic instantiation actual part");
         Parse_Generic_Actual_Part (Position, Result);
      end if;

      if Starts_Strong_Package_Declarative_Item (Position) then
         return;
      end if;

      Parse_Attached_Aspect_Or_Semicolon (Position, Result);
   end Parse_Generic_Instantiation_Declaration;


   function Formal_Package_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then (T = "," or else T = ";") then
               return False;
            elsif Depth = 0 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Formal_Package_Actual_Has_Top_Level_Arrow;

   function Formal_Package_Actual_Looks_Like_Missing_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
      Top_Level_Tokens : Natural := 0;
      Saw_Operator : Boolean := False;
   begin
      --  A single positional actual is legal.  A top-level sequence such as
      --     Element_Type Element,
      --  is much more likely to be an in-progress named association with the
      --  arrow omitted.  Keep this check deliberately shallow and syntactic so
      --  hostile generic contracts get a recovery marker without trying to
      --  resolve expressions or generic profiles.
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  exit;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then (T = "," or else T = ";") then
               exit;
            elsif Depth = 0 and then T = "=>" then
               return False;
            elsif Depth = 0 then
               Top_Level_Tokens := Top_Level_Tokens + 1;
               if T = "+" or else T = "-" or else T = "*"
                 or else T = "/" or else T = "**" or else T = "&"
                 or else T = "=" or else T = "/=" or else T = "<"
                 or else T = "<=" or else T = ">" or else T = ">="
               then
                  Saw_Operator := True;
               end if;
            end if;
         end;
         Advance (Probe);
      end loop;

      return Top_Level_Tokens >= 2 and then not Saw_Operator;
   end Formal_Package_Actual_Looks_Like_Missing_Arrow;


   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               elsif Depth = 1 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Parenthesized_Actual_Has_Top_Level_Arrow;


   procedure Mark_Generic_Actual_Nested_Actuals
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      --  Generic instantiation actuals can contain nested call or
      --  instantiation-shaped actual lists.  Mark nested named associations so
      --  the outer generic_actual_part keeps deterministic association
      --  boundaries without flattening the inner list into expression text.
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if Depth = 0 and then (T = "," or else T = ")" or else T = ";") then
               return;
            elsif T = "(" then
               if Depth = 0
                 and then Parenthesized_Actual_Has_Top_Level_Arrow (Probe)
               then
                  Add_Production
                    (Result, Production_Generic_Actual_Nested_Actual_Part,
                     Current (Probe), "nested generic actual part");
               end if;
               Depth := Depth + 1;
            elsif T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               Add_Production
                 (Result, Production_Generic_Actual_Nested_Actual_Association,
                  Current (Probe), "nested generic actual association");
            end if;
         end;
         Advance (Probe);
      end loop;
   end Mark_Generic_Actual_Nested_Actuals;


   procedure Mark_Formal_Package_Nested_Actuals
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      --  Formal package actuals may themselves be generic instantiations or
      --  calls with named associations, for example
      --     Factory => Make (A => B, C => D)
      --  The editor parser should retain that nested association shape without
      --  treating the inner comma or closing parenthesis as the end of the
      --  formal_package_actual_part.
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if Depth = 0 and then (T = "," or else T = ")" or else T = ";") then
               return;
            elsif T = "(" then
               if Depth = 0
                 and then Parenthesized_Actual_Has_Top_Level_Arrow (Probe)
               then
                  Add_Production
                    (Result, Production_Formal_Package_Nested_Actual_Part,
                     Current (Probe), "nested formal package actual part");
               end if;
               Depth := Depth + 1;
            elsif T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then T = "=>" then
               Add_Production
                 (Result, Production_Formal_Package_Nested_Actual_Association,
                  Current (Probe), "nested formal package actual association");
               if Lookahead_Lower (Probe, 1) = "<>" then
                  Add_Production
                    (Result, Production_Formal_Package_Actual_Association_Box,
                     Current (Probe),
                     "nested formal package actual association box");
                  Add_Production
                    (Result, Production_Generic_Actual_Box, Current (Probe),
                     "nested generic actual box default");
               end if;
            end if;
         end;
         Advance (Probe);
      end loop;
   end Mark_Formal_Package_Nested_Actuals;


   procedure Parse_Formal_Package_Actual_Selector
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Anchor   : Token_Info) is
      First : Boolean := True;
   begin
      while not At_End (Position)
        and then To_String (Current (Position).Text) /= "=>"
        and then To_String (Current (Position).Text) /= ","
        and then To_String (Current (Position).Text) /= ")"
        and then To_String (Current (Position).Text) /= ";"
      loop
         if First then
            Add_Production
              (Result, Production_Formal_Package_Actual_Formal_Selector,
               Current (Position), To_String (Current (Position).Text));
            Add_Production
              (Result, Production_Generic_Actual_Formal_Selector,
               Current (Position), To_String (Current (Position).Text));
            if Current (Position).Kind = Token_String_Literal then
               Add_Production
                 (Result, Production_Defining_Operator_Symbol,
                  Current (Position), To_String (Current (Position).Text));
            else
               Add_Production
                 (Result, Production_Name, Current (Position),
                  To_String (Current (Position).Text));
            end if;
            First := False;
         elsif To_String (Current (Position).Text) = "." then
            Add_Production
              (Result, Production_Selected_Name, Anchor,
               "formal package actual selector selected name");
         end if;
         Advance (Position);
      end loop;

      if not Match_Symbol (Position, "=>") then
         Add_Production
           (Result, Production_Recovery_Point, Anchor,
            "expected => in formal package actual association");
      end if;
   end Parse_Formal_Package_Actual_Selector;


   procedure Parse_Formal_Package_Actual_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Package_Actual_Part, Tok,
         "formal package actual part");

      if not Match_Symbol (Position, "(") then
         return;
      end if;
      Add_Production
        (Result, Production_Formal_Package_Actual_Part_Open_Delimiter,
         Tok, "formal package actual part open delimiter");

      if To_String (Current (Position).Text) = "<>"
        and then Lookahead_Lower (Position, 1) = ")"
      then
         --  formal_package_actual_part has a dedicated box form ``(<>)``.
         --  Keep it as a formal-package default/box rather than routing it
         --  through the generic-actual association list, where it would be
         --  reported as a positional generic actual association.
         Add_Production
           (Result, Production_Formal_Package_Actual_Box, Current (Position),
            "formal package box actual part");
         Advance (Position);
         if To_String (Current (Position).Text) = ")" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Close_Delimiter,
               Current (Position), "formal package actual part close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package box actual part");
         end if;
      elsif To_String (Current (Position).Text) = ")" then
         --  A parenthesized formal_package_actual_part must be either the
         --  dedicated box form ``(<>)`` or contain at least one association.
         --  Retain an explicit empty-list recovery boundary so callers do not
         --  infer a valid omitted actual part from malformed ``()`` text.
         Add_Production
           (Result, Production_Formal_Package_Actual_Empty_Recovery_Boundary,
            Current (Position),
            "formal package actual empty recovery boundary");
         Add_Production
           (Result, Production_Formal_Package_Actual_Part_Close_Delimiter,
            Current (Position), "formal package actual part close delimiter");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected formal package actual association or <> box");
         Advance (Position);
      else
         --  Non-box formal package actual parts use generic association
         --  syntax, but the enclosing construct is a formal package
         --  declaration rather than an ordinary instantiation.  Keep both the
         --  generic-actual shape and the formal-package-specific shape so
         --  outline/colouring callers can distinguish ``with package``
         --  contracts from package instantiations without reparsing text.
         Add_Production
           (Result, Production_Generic_Actual_Part, Tok,
            "generic actual part");

         declare
            Saw_Named_Association : Boolean := False;
         begin
         while not At_End (Position)
           and then To_String (Current (Position).Text) /= ")"
           and then To_String (Current (Position).Text) /= ";"
         loop
            declare
               Assoc_Tok : constant Token_Info := Current (Position);
               Named     : constant Boolean :=
                 Formal_Package_Actual_Has_Top_Level_Arrow (Position);
            begin
               Add_Production
                 (Result, Production_Formal_Package_Actual_Association,
                  Assoc_Tok, To_String (Assoc_Tok.Text));
               Add_Production
                 (Result, Production_Generic_Actual_Association,
                  Assoc_Tok, To_String (Assoc_Tok.Text));

               if Named then
                  Saw_Named_Association := True;
                  Parse_Formal_Package_Actual_Selector
                    (Position, Result, Assoc_Tok);
               else
                  --  Positional associations cannot follow named associations
                  --  in a generic association list.  Mark the boundary but
                  --  still keep the actual expression bounded so later
                  --  formals remain visible during editing.
                  if Saw_Named_Association then
                     Add_Production
                       (Result,
                        Production_Formal_Package_Named_To_Positional_Order_Recovery_Boundary,
                        Assoc_Tok,
                        "formal package positional actual after named actual");
                     Add_Production
                       (Result, Production_Recovery_Point, Assoc_Tok,
                        "expected named formal package actual after named association");
                  end if;

                  --  Formal package actual parts may use positional generic
                  --  associations just like ordinary generic actual parts.
                  --  If a hostile/in-progress source looks like a named
                  --  association with the arrow omitted, keep an explicit
                  --  formal-package recovery marker while still preserving the
                  --  conservative positional association metadata.
                  if Formal_Package_Actual_Looks_Like_Missing_Arrow (Position) then
                     Add_Production
                       (Result,
                        Production_Formal_Package_Actual_Missing_Arrow_Recovery_Boundary,
                        Assoc_Tok,
                        "formal package actual missing arrow recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Assoc_Tok,
                        "expected => in formal package actual association");
                  end if;

                  Add_Production
                    (Result,
                     Production_Formal_Package_Actual_Positional_Association,
                     Assoc_Tok,
                     "formal package positional actual association");
                  Add_Production
                    (Result, Production_Generic_Actual_Positional_Association,
                     Assoc_Tok, "generic positional actual association");
               end if;

               if To_String (Current (Position).Text) = "<>" then
                  Add_Production
                    (Result, Production_Formal_Package_Actual_Association_Box,
                     Current (Position),
                     "formal package actual association box");
                  Add_Production
                    (Result, Production_Generic_Actual_Box, Current (Position),
                     "generic actual box default");
                  Advance (Position);
               else
                  Mark_Formal_Package_Nested_Actuals (Position, Result);
                  Parse_Expression (Position, Result);
               end if;

               if To_String (Current (Position).Text) = "," then
                  Add_Production
                    (Result, Production_Formal_Package_Actual_Association_Separator,
                     Current (Position),
                     "formal package actual association separator");
                  Advance (Position);
               else
                  exit;
               end if;
               if To_String (Current (Position).Text) = ")"
                 or else To_String (Current (Position).Text) = ";"
                 or else Current_Lower (Position) = "with"
               then
                  Add_Production
                    (Result, Production_Formal_Package_Actual_Recovery_Boundary,
                     Current (Position),
                     "formal package actual recovery boundary");
                  exit;
               end if;
            end;
         end loop;
         end;

         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Recovery_Boundary,
               Current (Position),
               "formal package actual recovery boundary");
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package actual part before aspect");
         elsif To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Recovery_Boundary,
               Current (Position),
               "formal package actual recovery boundary");
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package actual part");
         elsif To_String (Current (Position).Text) = ")" then
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Close_Delimiter,
               Current (Position), "formal package actual part close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Formal_Package_Actual_Recovery_Boundary,
               Current (Position),
               "formal package actual recovery boundary");
            Add_Production
              (Result, Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary,
               Tok, "formal package actual part missing close recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal package actual part");
            while not At_End (Position)
              and then Current_Lower (Position) /= "with"
              and then To_String (Current (Position).Text) /= ";"
            loop
               Advance (Position);
            end loop;
         end if;
      end if;
   end Parse_Formal_Package_Actual_Part;


   procedure Parse_Aspect_Mark
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      --  Ada aspect associations start with an aspect_mark, not an arbitrary
      --  expression.  Retain the mark explicitly so ``Aspect'Class => ...``
      --  does not get flattened into ordinary attribute-reference recovery and
      --  so nullary aspects such as ``with Preelaborate`` do not require a fake
      --  value expression.
      if Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Add_Production
           (Result, Production_Aspect_Mark, Tok, To_String (Tok.Text));
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
            if Is_Contract and then To_String (Current (Position).Text) = "'" then
               --  The ordinary aspect-mark parser records the class-wide mark;
               --  retain the contract-specific mark as well so contract
               --  metadata can distinguish ``Pre'Class``/``Post'Class`` from
               --  ordinary marker-only aspects without reparsing text later.
               null;
            end if;
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
         --  Some Ada declarations share the same attached ``with`` token but
         --  have materially different placement rules.  Retain a bounded
         --  placement production before parsing the ordinary aspect
         --  associations so later language-model/resolver passes can
         --  distinguish generic formal, concurrent type, protected operation,
         --  entry, body-stub, private-completion, and body aspects without
         --  reparsing source text.
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
         --  Named-number declarations stop at their own semicolon.  Record
         --  shallow parser-owned recovery when an in-progress declaration
         --  reaches the next synchronization token without borrowing a later
         --  declaration terminator.  This is structural completion metadata,
         --  not static-expression or universal-type legality checking.
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
         --  Keep this recovery deliberately shallow and parser-owned: it only
         --  records that the declaration-like subprogram construct reached a
         --  synchronization point without its terminating semicolon.  It does
         --  not attempt body/spec conformance, overload, or aspect legality,
         --  and it deliberately does not scan forward into the next
         --  declaration looking for a borrowed semicolon.
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
         --  Generic formal declarations have their own semicolon, separate
         --  from the enclosing generic declaration and following package
         --  declaration.  Record a bounded recovery marker rather than
         --  scanning forward and borrowing a later declaration terminator.
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
         --  Keep exception declaration completion metadata shallow and
         --  parser-owned.  The token cursor records whether the declaration
         --  reached its own semicolon or stopped at the next synchronization
         --  token; it does not borrow a later declaration semicolon and it does
         --  not attempt exception-renaming legality or aspect legality.
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

   procedure Add_Concurrent_Definition_Part_Productions
     (Position     : in out Cursor;
      Result       : in out Grammar_Result;
      Public_Kind  : Production_Kind;
      Private_Kind : Production_Kind;
      Label        : String)
   is
      Probe : Cursor := Position;
   begin
      if not At_End (Probe)
        and then Current_Lower (Probe) /= "private"
        and then Current_Lower (Probe) /= "end"
      then
         Add_Production
           (Result, Public_Kind, Current (Probe), Label & " public part");
      end if;

      while not At_End (Probe) loop
         declare
            L : constant String := Current_Lower (Probe);
         begin
            if L = "private" then
               Add_Production
                 (Result, Production_Private_Part, Current (Probe),
                  Label & " private part");
               Add_Production
                 (Result, Private_Kind, Current (Probe),
                  Label & " private part");
            elsif L = "procedure" or else L = "function" then
               Add_Production
                 (Result, Production_Subprogram_Declaration,
                  Current (Probe), "protected operation subprogram declaration");
               Add_Production
                 (Result, Production_Protected_Operation_Declaration,
                  Current (Probe), "protected operation declaration");
            elsif L = "pragma" then
               declare
                  Pragma_Probe : Cursor := Probe;
               begin
                  Parse_Pragma (Pragma_Probe, Result);
               end;
            elsif L = "entry" then
               Add_Production
                 (Result, Production_Entry_Declaration, Current (Probe),
                  "entry declaration");
               declare
                  Entry_Probe : Cursor := Probe;
               begin
                  Advance (Entry_Probe);
                  if not At_End (Entry_Probe)
                    and then (Current (Entry_Probe).Kind = Token_Identifier
                              or else Current (Entry_Probe).Kind = Token_Keyword)
                  then
                     Add_Production
                       (Result, Production_Entry_Identifier,
                        Current (Entry_Probe), "entry identifier");
                     Advance (Entry_Probe);
                  end if;

                  if not At_End (Entry_Probe)
                    and then To_String (Current (Entry_Probe).Text) = "("
                  then
                     declare
                        Family_Open : constant Token_Info := Current (Entry_Probe);
                        Scan        : Cursor := Entry_Probe;
                        Depth       : Natural := 0;
                        Has_Range   : Boolean := False;
                        Has_Profile_Separator : Boolean := False;
                        Closed      : Boolean := False;
                     begin
                        while not At_End (Scan) loop
                           if To_String (Current (Scan).Text) = "(" then
                              Depth := Depth + 1;
                           elsif To_String (Current (Scan).Text) = ")" then
                              if Depth = 0 then
                                 exit;
                              end if;
                              Depth := Depth - 1;
                              if Depth = 0 then
                                 Closed := True;
                                 exit;
                              end if;
                           elsif Current_Lower (Scan) = "range"
                             or else To_String (Current (Scan).Text) = ".."
                           then
                              Has_Range := True;
                           elsif Depth = 1
                             and then (To_String (Current (Scan).Text) = ":"
                                       or else To_String (Current (Scan).Text) = ";")
                           then
                              Has_Profile_Separator := True;
                           end if;
                           Advance (Scan);
                        end loop;

                        if Closed and then not Has_Profile_Separator then
                           Add_Production
                             (Result, Production_Entry_Family_Definition,
                              Family_Open, "entry family definition");
                           if Lookahead_Lower (Entry_Probe, 1) = ")" then
                              Add_Production
                                (Result,
                                 Production_Entry_Family_Empty_Definition_Recovery_Boundary,
                                 Family_Open,
                                 "entry family empty definition recovery boundary");
                              Add_Production
                                (Result, Production_Recovery_Point, Family_Open,
                                 "expected entry family discrete subtype definition");
                           else
                              Add_Production
                                (Result,
                                 Production_Entry_Family_Discrete_Subtype_Definition,
                                 Family_Open,
                                 "entry family discrete subtype definition");
                              Add_Production
                                (Result, Production_Entry_Family_Index_Subtype,
                                 Family_Open, "entry family index subtype");
                              if Has_Range then
                                 Add_Production
                                   (Result, Production_Entry_Family_Range_Definition,
                                    Family_Open, "entry family range definition");
                              end if;
                           end if;
                           Entry_Probe := Scan;
                           Advance (Entry_Probe);
                        end if;
                     end;
                  end if;

                  if not At_End (Entry_Probe)
                    and then To_String (Current (Entry_Probe).Text) = "("
                  then
                     Add_Production
                       (Result, Production_Entry_Parameter_Profile,
                        Current (Entry_Probe), "entry parameter profile");
                  end if;

                  declare
                     Tail  : Cursor := Probe;
                     Depth : Natural := 0;
                     Done  : Boolean := False;
                  begin
                     while not Done and then not At_End (Tail) loop
                        declare
                           TT : constant String := To_String (Current (Tail).Text);
                           TL : constant String := Current_Lower (Tail);
                        begin
                           if TT = "(" then
                              Depth := Depth + 1;
                           elsif TT = ")" and then Depth > 0 then
                              Depth := Depth - 1;
                           elsif TT = ";" and then Depth = 0 then
                              Add_Production
                                (Result, Production_Entry_Terminator,
                                 Current (Tail),
                                 "entry declaration terminator");
                              Done := True;
                           elsif Depth = 0
                             and then (TL = "private" or else TL = "end")
                           then
                              Add_Production
                                (Result,
                                 Production_Entry_Missing_Terminator_Recovery_Boundary,
                                 Current (Probe),
                                 "entry declaration missing terminator recovery boundary");
                              Done := True;
                           end if;
                        end;
                        if not Done then
                           Advance (Tail);
                        end if;
                     end loop;
                  end;
               end;
            elsif L = "with" then
               Add_Production
                 (Result, Production_Entry_Aspect_Specification,
                  Current (Probe), "entry aspect placement");
               Add_Production
                 (Result, Production_Protected_Operation_Aspect_Specification,
                  Current (Probe), "protected operation aspect specification");
               Add_Production
                 (Result, Production_Protected_Operation_Aspect_Attachment,
                  Current (Probe), "protected operation aspect attachment");
               declare
                  Aspect_Position : Cursor := Probe;
               begin
                  Parse_Aspect_Specification (Aspect_Position, Result);
               end;
            elsif L = "end" then
               Advance (Probe);
               if not At_End (Probe)
                 and then (Current (Probe).Kind = Token_Identifier
                           or else Current (Probe).Kind = Token_Keyword)
               then
                  Advance (Probe);
               end if;
               if not At_End (Probe)
                 and then To_String (Current (Probe).Text) = ";"
               then
                  Advance (Probe);
               end if;
               Position := Probe;
               exit;
            end if;
            Advance (Probe);
         end;
      end loop;
   end Add_Concurrent_Definition_Part_Productions;





   procedure Parse_Representation_Target
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String) is
      Tok : constant Token_Info := Current (Position);

      function At_Representation_Target_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
         S : constant String := To_String (Current (Position).Text);
      begin
         return S = ")"
           or else L = "private"
           or else L = "begin"
           or else L = "end"
           or else L = "with"
           or else L = "package"
           or else L = "procedure"
           or else L = "function"
           or else L = "type"
           or else L = "subtype"
           or else L = "task"
           or else L = "protected";
      end At_Representation_Target_Boundary;
   begin
      Add_Production
        (Result, Production_Representation_Target, Tok, To_String (Tok.Text));

      --  A representation/operational item target is a local_name/name before
      --  either ``use`` or an attribute designator.  Keep selected-name,
      --  indexed-prefix, and dereference shape, but deliberately stop before
      --  a top-level apostrophe so the following attribute_designator remains
      --  a distinct grammar production.
      while not At_End (Position)
        and then To_String (Current (Position).Text) /= Stop
        and then Current_Lower (Position) /= "use"
        and then To_String (Current (Position).Text) /= ";"
      loop
         if At_Representation_Target_Boundary then
            Add_Production
              (Result,
               Production_Representation_Target_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "representation target stopped at declaration boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected use or attribute designator after representation target");
            exit;
         end if;

         declare
            T : constant Token_Info := Current (Position);
            S : constant String := To_String (T.Text);
         begin
            if T.Kind = Token_Identifier or else T.Kind = Token_Keyword then
               Add_Production (Result, Production_Name, T, S);
               Advance (Position);
            elsif S = "." then
               Parse_Selected_Name_Suffix
                 (Position, Result, Tok, "representation target");
            elsif S = "(" then
               Add_Production
                    (Result, Production_Call_Or_Indexed_Component, Tok,
                     "call or indexed component suffix");
                  Add_Production (Result, Production_Indexed_Component, Tok, To_String (Tok.Text));
               Parse_Association_List (Position, Result);
            else
               Advance (Position);
            end if;
         end;
      end loop;
   end Parse_Representation_Target;


   procedure Parse_Attribute_Designator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Attribute_Designator, Tok, To_String (Tok.Text));
      Add_Production
        (Result, Production_Attribute_Designator_Name, Tok, To_String (Tok.Text));

      --  attribute_designator ::= identifier | Access | Delta | Digits
      --                         | Mod | operator_symbol
      if Current (Position).Kind = Token_String_Literal
        or else Current (Position).Kind = Token_Operator
        or else Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected attribute designator in representation clause");
      end if;
   end Parse_Attribute_Designator;


   function Is_Stream_Attribute_Designator (Lower_Name : String) return Boolean is
   begin
      return Lower_Name = "read"
        or else Lower_Name = "write"
        or else Lower_Name = "input"
        or else Lower_Name = "output";
   end Is_Stream_Attribute_Designator;


   procedure Parse_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok                 : constant Token_Info := Current (Position);
      Start_Mark          : constant Natural := Mark (Position);
      Is_Attribute_Clause : Boolean := False;
      Is_Address_Attribute : Boolean := False;
      Attribute_Name      : Unbounded_String;

      function At_Representation_Item_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
         S : constant String := To_String (Current (Position).Text);
      begin
         return At_End (Position)
           or else S = ";"
           or else S = ")"
           or else L = "private"
           or else L = "begin"
           or else L = "end"
           or else L = "with"
           or else L = "package"
           or else L = "procedure"
           or else L = "function"
           or else L = "type"
           or else L = "subtype"
           or else L = "task"
           or else L = "protected";
      end At_Representation_Item_Boundary;

      function Has_Apostrophe_Before_Use return Boolean is
         Probe       : Cursor := Position;
         Paren_Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
               L : constant String := Current_Lower (Probe);
            begin
               if T = "(" then
                  Paren_Depth := Paren_Depth + 1;
               elsif T = ")" and then Paren_Depth > 0 then
                  Paren_Depth := Paren_Depth - 1;
               elsif L = "use" and then Paren_Depth = 0 then
                  return False;
               elsif T = ";" and then Paren_Depth = 0 then
                  return False;
               elsif T = "'" and then Paren_Depth = 0 then
                  return True;
               end if;
               Advance (Probe);
            end;
         end loop;
         return False;
      end Has_Apostrophe_Before_Use;

      function Has_Arrow_Before_Enumeration_Association_End return Boolean is
         Probe : Cursor := Position;
         Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
            begin
               if T = "(" or else T = "[" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth = 0 then
                     return False;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif T = "]" then
                  if Depth > 0 then
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 0 and then (T = "," or else T = ";") then
                  return False;
               elsif Depth = 0 and then T = "=>" then
                  return True;
               end if;
               Advance (Probe);
            end;
         end loop;
         return False;
      end Has_Arrow_Before_Enumeration_Association_End;
   begin
      Add_Production (Result, Production_Representation_Clause, Tok,
                      "representation clause");
      if not Match_Keyword (Position, "for") then
         return;
      end if;
      Is_Attribute_Clause := Has_Apostrophe_Before_Use;

      --  Attribute definition clause: for T'Size use 32;
      --  Operational attribute clause: for S'Read use Read_S;
      --  Address clause:              for Obj use at Address;
      --  Enumeration representation: for E use (A => 0, B => 1);
      --  Record representation:      for R use record ... end record;
      Parse_Representation_Target (Position, Result, "'");

      if Is_Attribute_Clause then
         Add_Production
           (Result, Production_Attribute_Definition_Clause, Tok,
            "attribute definition clause");
         Add_Production
           (Result, Production_Operational_Item, Tok,
            "operational item");
         Add_Production
           (Result, Production_Operational_Attribute_Definition_Clause, Tok,
            "operational attribute definition clause");
         if Match_Symbol (Position, "'") then
            --  Class-wide stream attributes use a class-wide prefix before
            --  the final attribute designator, for example:
            --     for T'Class'Input use Read_T;
            --  Retain the class-wide prefix as representation-target
            --  structure and classify the final stream attribute rather than
            --  incorrectly treating Class as the clause attribute.
            if Current_Lower (Position) = "class"
              and then Lookahead_Lower (Position, 1) = "'"
            then
               Add_Production
                 (Result, Production_Classwide_Attribute_Prefix,
                  Current (Position), "class-wide attribute prefix");
               Parse_Attribute_Designator (Position, Result);
               if not Match_Symbol (Position, "'") then
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected attribute designator after class-wide prefix");
               end if;
            end if;

            if Current_Lower (Position) = "use"
              or else At_Representation_Item_Boundary
            then
               Add_Production
                 (Result,
                  Production_Attribute_Definition_Missing_Designator_Recovery_Boundary,
                  Tok, "missing attribute designator in attribute definition clause");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected attribute designator in attribute definition clause");
            end if;

            Attribute_Name := To_Unbounded_String (Current_Lower (Position));
            Is_Address_Attribute := To_String (Attribute_Name) = "address";
            if Is_Address_Attribute then
               Add_Production
                 (Result, Production_Address_Clause, Tok,
                  "address attribute definition clause");
            end if;
            if Is_Stream_Attribute_Designator (To_String (Attribute_Name)) then
               Add_Production
                 (Result, Production_Stream_Attribute_Definition_Clause, Tok,
                  "stream attribute definition clause");
            end if;
            if To_String (Attribute_Name) = "size"
              or else To_String (Attribute_Name) = "object_size"
              or else To_String (Attribute_Name) = "value_size"
              or else To_String (Attribute_Name) = "component_size"
            then
               Add_Production
                 (Result, Production_Size_Attribute_Definition_Clause, Tok,
                  "size attribute definition clause");
            elsif To_String (Attribute_Name) = "alignment" then
               Add_Production
                 (Result, Production_Alignment_Attribute_Definition_Clause, Tok,
                  "alignment attribute definition clause");
            elsif To_String (Attribute_Name) = "external_tag" then
               Add_Production
                 (Result, Production_External_Tag_Attribute_Definition_Clause, Tok,
                  "external tag attribute definition clause");
            elsif To_String (Attribute_Name) = "storage_size"
              or else To_String (Attribute_Name) = "storage_pool"
              or else To_String (Attribute_Name) = "storage_unit"
              or else To_String (Attribute_Name) = "scalar_storage_order"
            then
               Add_Production
                 (Result, Production_Storage_Attribute_Definition_Clause, Tok,
                  "storage attribute definition clause");
            end if;
            if not (Current_Lower (Position) = "use"
                    or else At_Representation_Item_Boundary)
            then
               Parse_Attribute_Designator (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected attribute designator in attribute definition clause");
         end if;
         if Match_Keyword (Position, "use") then
            if At_Representation_Item_Boundary
            then
               if Is_Address_Attribute then
                  Add_Production
                    (Result, Production_Address_Clause_Missing_Value_Recovery_Boundary,
                     Tok, "missing address value expression");
               else
                  Add_Production
                    (Result, Production_Attribute_Definition_Missing_Value_Recovery_Boundary,
                     Tok, "missing attribute definition value expression");
               end if;
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected representation value expression after use");
            else
               if Is_Address_Attribute then
                  Add_Production
                    (Result, Production_Address_Value_Expression,
                     Current (Position), "address value expression");
               else
                  Add_Production
                    (Result, Production_Representation_Value_Expression,
                     Current (Position), "representation value expression");
               end if;
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Attribute_Definition_Missing_Use_Recovery_Boundary,
               Tok, "missing use in attribute definition clause");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected use in attribute definition clause");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif Match_Keyword (Position, "use") then
         if Current_Lower (Position) = "record" then
            Restore (Position, Start_Mark);
            Parse_Record_Representation_Clause (Position, Result);
         elsif Match_Keyword (Position, "at") then
            Add_Production (Result, Production_Address_Clause, Tok,
                            "address clause");
            if At_Representation_Item_Boundary
            then
               Add_Production
                 (Result, Production_Address_Clause_Missing_Value_Recovery_Boundary,
                  Tok, "missing address value expression");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected address value expression after at");
            else
               Add_Production
                 (Result, Production_Address_Value_Expression,
                  Current (Position), "address value expression");
               Parse_Expression (Position, Result);
            end if;
            Skip_Balanced_To_Semicolon (Position);
         elsif To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Enumeration_Representation_Clause, Tok,
               "enumeration representation clause");
            if To_String (Current (Position).Text) = "(" then
               Add_Production
                 (Result,
                  Production_Enumeration_Representation_List_Open_Delimiter,
                  Current (Position), "enumeration representation list open delimiter");
            end if;
            if Match_Symbol (Position, "(") then
               if To_String (Current (Position).Text) = ")" then
                  Add_Production
                    (Result,
                     Production_Enumeration_Representation_Empty_List_Recovery_Boundary,
                     Tok, "empty enumeration representation list");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected enumeration representation association");
               end if;

               while not At_End (Position)
                 and then To_String (Current (Position).Text) /= ")"
                 and then To_String (Current (Position).Text) /= ";"
               loop
                  if At_Representation_Item_Boundary then
                     Add_Production
                       (Result,
                        Production_Enumeration_Representation_Reserved_Association_Recovery_Boundary,
                        Current (Position),
                        "enumeration representation association stopped at declaration boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected enumeration representation association");
                     exit;
                  end if;

                  declare
                     Assoc_Tok : constant Token_Info := Current (Position);
                  begin
                     Add_Production
                       (Result, Production_Enumeration_Representation_Association,
                        Assoc_Tok, To_String (Assoc_Tok.Text));
                     if Has_Arrow_Before_Enumeration_Association_End then
                        Add_Production
                          (Result,
                           Production_Enumeration_Representation_Choice_List,
                           Assoc_Tok, "enumeration representation choice list");
                        Parse_Discrete_Choice_List (Position, Result, "=>");
                        if Match_Symbol (Position, "=>") then
                           if To_String (Current (Position).Text) = ","
                             or else To_String (Current (Position).Text) = ")"
                             or else To_String (Current (Position).Text) = ";"
                           then
                              Add_Production
                                (Result,
                                 Production_Enumeration_Representation_Missing_Value_Recovery_Boundary,
                                 Assoc_Tok,
                                 "missing enumeration representation value expression");
                              Add_Production
                                (Result, Production_Recovery_Point, Assoc_Tok,
                                 "expected enumeration representation value expression");
                           else
                              Add_Production
                                (Result, Production_Representation_Value_Expression,
                                 Current (Position), "enumeration representation value expression");
                              Parse_Expression (Position, Result);
                           end if;
                        else
                           Add_Production
                             (Result, Production_Recovery_Point, Assoc_Tok,
                              "expected => in enumeration representation association");
                           Skip_Balanced_To (Position, ",", ")", ";");
                        end if;
                     else
                        --  Positional enumeration_representation associations
                        --  are legal aggregate components and map to the
                        --  target type's literals in declaration order.
                        Add_Production
                          (Result, Production_Representation_Value_Expression,
                           Current (Position), "enumeration representation value expression");
                        Parse_Expression (Position, Result);
                     end if;
                  end;
                  if To_String (Current (Position).Text) = "," then
                     Add_Production
                       (Result,
                        Production_Enumeration_Representation_Association_Separator,
                        Current (Position),
                        "enumeration representation association separator");
                     Advance (Position);
                     if To_String (Current (Position).Text) = ")"
                       or else To_String (Current (Position).Text) = ";"
                     then
                        Add_Production
                          (Result,
                           Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary,
                           Tok,
                           "trailing comma in enumeration representation list");
                        Add_Production
                          (Result, Production_Recovery_Point, Tok,
                           "expected enumeration representation association after comma");
                     end if;
                  else
                     exit;
                  end if;
               end loop;
               if To_String (Current (Position).Text) = ")" then
                  Add_Production
                    (Result,
                     Production_Enumeration_Representation_List_Close_Delimiter,
                     Current (Position),
                     "enumeration representation list close delimiter");
                  Advance (Position);
               else
                  Add_Production
                    (Result,
                     Production_Enumeration_Representation_Missing_Close_Recovery_Boundary,
                     Tok, "expected ) in enumeration representation clause");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected ) in enumeration representation clause");
               end if;
            end if;
            Skip_Balanced_To_Semicolon (Position);
         else
            Add_Production
              (Result, Production_Representation_Value_Expression,
               Current (Position), "representation value expression");
            Parse_Expression (Position, Result);
            Skip_Balanced_To_Semicolon (Position);
         end if;
      else
         Add_Production
           (Result, Production_Representation_Clause_Missing_Use_Recovery_Boundary,
            Tok, "missing use in representation clause");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected use in representation clause");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Representation_Clause;

   procedure Parse_Record_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Record_Representation_Clause, Tok,
         "record representation clause");
      --  for T use record
      while not At_End (Position) loop
         if Current_Lower (Position) = "record" then
            Add_Production
              (Result, Production_Record_Representation_List_Open_Delimiter,
               Current (Position), "record representation list open delimiter");
            Advance (Position);
            exit;
         end if;
         Advance (Position);
      end loop;
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant String := To_String (Current (Position).Text);
            C : constant Token_Info := Current (Position);
         begin
            exit when L = "end";
            if L = "at" and then Lookahead_Lower (Position, 1) = "mod" then
               --  Record representation clauses may carry an optional
               --  mod_clause before component clauses:
               --     for R use record
               --        at mod 8;
               --        Field at 0 range 0 .. 7;
               --     end record;
               --  Keep it distinct from address clauses and component
               --  clauses so syntax/outline recovery can preserve the
               --  complete record-representation grammar shape.
               Add_Production
                 (Result, Production_Mod_Clause, C,
                  "record representation mod clause");
               Advance (Position);
               if Match_Keyword (Position, "mod") then
                  Parse_Expression (Position, Result);
               else
                  Add_Production
                    (Result, Production_Recovery_Point, C,
                     "expected mod in record representation clause");
               end if;
               Skip_Balanced_To_Semicolon (Position);
               Add_Production
                 (Result, Production_Record_Representation_Component_Separator,
                  C, "record representation mod clause separator");
            elsif Current (Position).Kind = Token_Identifier
              and then
                (Has_Token_Before_Semicolon (Position, "at")
                 or else Has_Token_Before_Semicolon (Position, "range"))
            then
               --  Component clauses are useful to outline/recovery even while
               --  the source is incomplete.  Keep the component target when
               --  either the position arm or the bit-range arm is present,
               --  and emit record-representation-specific recovery metadata
               --  instead of dropping the malformed clause as ordinary text.
               Add_Production
                 (Result, Production_Representation_Component_Clause, C,
                  To_String (C.Text));
               Add_Production
                 (Result, Production_Representation_Target, C,
                  To_String (C.Text));
               Advance (Position);
               if Match_Keyword (Position, "at") then
                  Add_Production
                    (Result, Production_Representation_Component_Position,
                     Current (Position), "component position");
                  Parse_Expression (Position, Result);
               else
                  Add_Production
                    (Result,
                     Production_Representation_Component_Missing_At_Recovery_Boundary,
                     C, "expected at in record representation component clause");
                  Add_Production
                    (Result, Production_Recovery_Point, C,
                     "expected at in record representation component clause");
               end if;
               if Match_Keyword (Position, "range") then
                  Add_Production
                    (Result, Production_Representation_Component_First_Bit,
                     Current (Position), "first bit");
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Add_Production
                       (Result, Production_Representation_Component_Last_Bit,
                        Current (Position), "last bit");
                     Parse_Expression (Position, Result);
                  else
                     Add_Production
                       (Result, Production_Recovery_Point, C,
                        "expected .. in record representation component range");
                  end if;
               else
                  Add_Production
                    (Result,
                     Production_Representation_Component_Missing_Range_Recovery_Boundary,
                     C, "expected range in record representation component clause");
                  Add_Production
                    (Result, Production_Recovery_Point, C,
                     "expected range in record representation component clause");
               end if;
               Skip_Balanced_To_Semicolon (Position);
               Add_Production
                 (Result, Production_Record_Representation_Component_Separator,
                  C, "record representation component separator");
            elsif T = ";" then
               Advance (Position);
            else
               Advance (Position);
            end if;
         end;
      end loop;
      if Match_Keyword (Position, "end") then
         if Current_Lower (Position) = "record" then
            Add_Production
              (Result, Production_Record_Representation_List_Close_Delimiter,
               Current (Position), "record representation list close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result,
               Production_Record_Representation_Missing_Close_Recovery_Boundary,
               Tok, "expected record after end in record representation clause");
            Add_Production
              (Result,
               Production_Record_Representation_Missing_End_Record_Recovery_Boundary,
               Tok, "expected record after end in record representation clause");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected record after end in record representation clause");
         end if;
      else
         Add_Production
           (Result,
            Production_Record_Representation_Missing_Close_Recovery_Boundary,
            Tok, "expected end record in record representation clause");
         Add_Production
           (Result,
            Production_Record_Representation_Missing_End_Record_Recovery_Boundary,
            Tok, "expected end record in record representation clause");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected end record in record representation clause");
      end if;
      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      end if;
   end Parse_Record_Representation_Clause;

   function Has_Top_Level_Arrow_Before_Association_End
     (Position : Cursor) return Boolean is
      Probe             : Cursor := Position;
      Depth             : Natural := 0;
   begin
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then T = "," then
               return False;
            elsif Depth = 0 and then T = "=>" then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Has_Top_Level_Arrow_Before_Association_End;

   function Has_Top_Level_With_Before_Association_End
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      --  Extension aggregates use the same opening parenthesis as ordinary
      --  aggregates but place a top-level ``with`` after the ancestor part.
      --  Detect only top-level separators so qualified expressions, calls,
      --  and nested aggregates inside the ancestor do not consume the
      --  extension aggregate path.
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then T = "," then
               return False;
            elsif Depth = 0 and then L = "with" then
               return Lookahead_Lower (Probe, 1) /= "delta";
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Has_Top_Level_With_Before_Association_End;

   function Has_Top_Level_With_Delta_Before_Association_End
     (Position : Cursor) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      --  Delta aggregates share the parenthesized aggregate surface syntax
      --  with ordinary and extension aggregates.  Detect a top-level
      --  ``with delta`` after the base expression so the base and subsequent
      --  delta associations remain distinct structural grammar children.
      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            if T = "(" or else T = "[" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = "]" then
               if Depth > 0 then
                  Depth := Depth - 1;
               end if;
            elsif Depth = 0 and then T = "," then
               return False;
            elsif Depth = 0 and then L = "with" then
               return Lookahead_Lower (Probe, 1) = "delta";
            end if;
         end;
         Advance (Probe);
      end loop;
      return False;
   end Has_Top_Level_With_Delta_Before_Association_End;



   procedure Parse_Association_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Qualified_Expression_Operand : Boolean := False) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Association_List, Tok, "association list");
      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Aggregate_Open_Delimiter, Current (Position),
            "association list open delimiter");
         if Qualified_Expression_Operand then
            Add_Production
              (Result, Production_Qualified_Expression_Operand_Open_Delimiter,
               Current (Position), "qualified-expression operand open delimiter");
         end if;
         Advance (Position);
         while not At_End (Position) and then To_String (Current (Position).Text) /= ")" loop
            declare
               Assoc_Tok : constant Token_Info := Current (Position);
            begin
               Add_Production
                 (Result, Production_Component_Association, Assoc_Tok,
                  To_String (Assoc_Tok.Text));

               if Current_Lower (Position) = "for" then
                  Parse_Iterated_Component_Association (Position, Result);
               elsif Has_Top_Level_Arrow_Before_Association_End (Position) then
                  --  Aggregate component associations have a choice_list
                  --  before ``=>``.  Keep aggregate-specific markers as well
                  --  as the older component-association marker so callers can
                  --  tell named aggregate items from positional expressions
                  --  without retokenizing the source.
                  Add_Production
                    (Result, Production_Aggregate_Named_Component_Association,
                     Assoc_Tok, "aggregate named component association");
                  Add_Production
                    (Result, Production_Aggregate_Component_Choice_List,
                     Assoc_Tok, "aggregate component choice list");
                  Add_Aggregate_Choice_Depth (Position, Result);
                  if Current_Lower (Position) = "others" then
                     Add_Production
                       (Result, Production_Aggregate_Others_Choice,
                        Current (Position), "aggregate others choice");
                  end if;
                  Parse_Discrete_Choice_List (Position, Result, "=>");
                  if Match_Symbol (Position, "=>") then
                     Add_Production
                       (Result, Production_Aggregate_Component_Arrow,
                        Current (Position), "aggregate component association arrow");
                     if To_String (Current (Position).Text) = ","
                       or else To_String (Current (Position).Text) = ")"
                     then
                        Add_Production
                          (Result, Production_Aggregate_Recovery_Boundary,
                           Assoc_Tok, "missing aggregate component expression");
                        Add_Production
                          (Result, Production_Recovery_Point, Assoc_Tok,
                           "expected aggregate component expression");
                     elsif At_Aggregate_Component_Expression_Boundary (Position) then
                        --  Reserved statement/expression synchronizers after
                        --  an aggregate component arrow are not component
                        --  expressions.  Keep aggregate-specific recovery so
                        --  outline and semantic colouring do not seed bindings
                        --  from a boundary token during malformed edits.
                        Add_Production
                          (Result,
                           Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary,
                           Current (Position),
                           "aggregate component expression reserved-boundary recovery boundary");
                        Add_Production
                          (Result, Production_Aggregate_Recovery_Boundary,
                           Assoc_Tok, "missing aggregate component expression");
                        Add_Production
                          (Result, Production_Recovery_Point, Assoc_Tok,
                           "expected aggregate component expression before boundary");
                     elsif To_String (Current (Position).Text) = "<>" then
                        Add_Production
                          (Result, Production_Aggregate_Box_Component,
                           Current (Position), "aggregate box component value");
                        Parse_Expression (Position, Result);
                     elsif Current_Lower (Position) = "for" then
                        Parse_Iterated_Component_Association (Position, Result);
                     else
                        Parse_Expression (Position, Result);
                     end if;
                  else
                     Add_Production
                       (Result, Production_Aggregate_Recovery_Boundary,
                        Assoc_Tok, "expected => in aggregate component association");
                     Add_Production
                       (Result, Production_Recovery_Point, Assoc_Tok,
                        "expected => in component association");
                  end if;
               else
                  Add_Production
                    (Result, Production_Aggregate_Positional_Component,
                     Assoc_Tok, "aggregate positional component");
                  if To_String (Current (Position).Text) = "<>" then
                     Add_Production
                       (Result, Production_Aggregate_Box_Component,
                        Current (Position), "aggregate positional box component");
                  end if;
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Add_Production (Result, Production_Range_Expression, Tok, "range expression");
                     Parse_Expression (Position, Result);
                  elsif Current_Lower (Position) = "range" then
                     Add_Production (Result, Production_Range_Expression, Tok, "range attribute slice");
                     Advance (Position);
                  end if;
               end if;
            end;
            if not At_End (Position)
              and then To_String (Current (Position).Text) = ","
            then
               Add_Production
                 (Result, Production_Aggregate_Component_Separator,
                  Current (Position), "association list component separator");
            end if;
            exit when not Match_Symbol (Position, ",");
         end loop;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ")"
         then
            Add_Production
              (Result, Production_Aggregate_Close_Delimiter, Current (Position),
               "association list close delimiter");
            if Qualified_Expression_Operand then
               Add_Production
                 (Result, Production_Qualified_Expression_Operand_Close_Delimiter,
                  Current (Position), "qualified-expression operand close delimiter");
            end if;
            Advance (Position);
         else
            Add_Production
              (Result, Production_Aggregate_Missing_Close_Recovery_Boundary,
               Tok, "missing association list close delimiter");
            if Qualified_Expression_Operand then
               Add_Production
                 (Result, Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary,
                  Tok, "missing qualified-expression operand close delimiter");
            end if;
            Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in association list");
         end if;
      end if;
   end Parse_Association_List;



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

   procedure Parse_Generic_Renaming_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production (Result, Production_Generic_Declaration, Tok, "generic renaming declaration");
      Add_Production (Result, Production_Renaming_Declaration, Tok, "generic renames");
      Advance (Position); -- generic

      if Current_Lower (Position) = "package" then
         Parse_Package_Renaming_Declaration (Position, Result, Generic_Form => True);
      elsif Current_Lower (Position) = "procedure" or else Current_Lower (Position) = "function" then
         declare
            Is_Function : constant Boolean := Current_Lower (Position) = "function";
         begin
            Add_Production
              (Result, Production_Generic_Subprogram_Renaming_Declaration,
               Current (Position), "generic subprogram renaming declaration");
            Advance (Position);
            Add_Renaming_Defining_Name
              (Position, Result, "generic subprogram renaming defining name");
            Parse_Defining_Program_Unit_Name (Position, Result);
            if To_String (Current (Position).Text) = "(" then
               Add_Production
                 (Result, Production_Renaming_Parameter_Profile,
                  Current (Position), "generic subprogram renaming profile");
               Parse_Parameter_Profile (Position, Result);
            end if;
            if Is_Function and then Current_Lower (Position) = "return" then
               Advance (Position);
               if not At_End (Position) then
                  Add_Production
                    (Result, Production_Renaming_Result_Subtype,
                     Current (Position), "generic subprogram renaming result subtype");
               end if;
               Parse_Subtype_Indication (Position, Result);
            end if;
            Parse_Renaming_Tail (Position, Result, Tok, "renamed generic subprogram");
         end;
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected package procedure or function in generic renaming");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Generic_Renaming_Declaration;




   function Starts_Package_Declarative_Item (Position : Cursor) return Boolean is
      L0 : constant String := Current_Lower (Position);
      T0 : constant String := To_String (Current (Position).Text);
   begin
      return L0 = "pragma"
        or else L0 = "use"
        or else L0 = "type"
        or else L0 = "subtype"
        or else L0 = "procedure"
        or else L0 = "function"
        or else L0 = "package"
        or else L0 = "generic"
        or else L0 = "task"
        or else L0 = "protected"
        or else L0 = "entry"
        or else L0 = "for"
        or else L0 = "with"
        or else Current (Position).Kind = Token_Identifier
        or else T0 = "<<";
   end Starts_Package_Declarative_Item;


   function Starts_Strong_Package_Declarative_Item
     (Position : Cursor) return Boolean is
      L0 : constant String := Current_Lower (Position);
   begin
      return L0 = "pragma"
        or else L0 = "use"
        or else L0 = "type"
        or else L0 = "subtype"
        or else L0 = "procedure"
        or else L0 = "function"
        or else L0 = "package"
        or else L0 = "generic"
        or else L0 = "task"
        or else L0 = "protected"
        or else L0 = "entry"
        or else L0 = "for"
        or else L0 = "with";
   end Starts_Strong_Package_Declarative_Item;


   procedure Skip_Package_Declarative_Item
     (Position      : in out Cursor;
      Result        : in out Grammar_Result;
      Boundary_Kind : Production_Kind;
      Boundary_Text : String) is
      Start_L0  : constant String := Current_Lower (Position);
      Depth     : Natural := 0;
      Seen_Tok  : Boolean := False;
      Saw_Begin : Boolean := False;
      Last_L    : Ada.Strings.Unbounded.Unbounded_String;

      procedure Add_Declarative_Boundary_Metadata
        (Tok : Token_Info;
         Lower_Text : String) is
      begin
         Add_Production (Result, Boundary_Kind, Tok, Boundary_Text);
         Add_Production
           (Result, Production_Package_Declarative_Recovery_Boundary,
            Tok, "package declarative recovery boundary");
         Add_Production
           (Result, Production_Package_Nested_Declarative_Item_Recovery_Boundary,
            Tok, "package nested declarative item recovery boundary");

         if Lower_Text = "private" then
            Add_Production
              (Result, Production_Package_Declarative_Private_Boundary, Tok,
               "package declarative private boundary");
         elsif Lower_Text = "begin" then
            Add_Production
              (Result, Production_Package_Declarative_Begin_Boundary, Tok,
               "package declarative begin boundary");
         elsif Lower_Text = "end" then
            Add_Production
              (Result, Production_Package_Declarative_End_Boundary, Tok,
               "package declarative end boundary");
         end if;
      end Add_Declarative_Boundary_Metadata;
   begin
      if (Start_L0 = "procedure" or else Start_L0 = "function")
        and then Has_Token_Before_Semicolon (Position, "separate")
      then
         declare
            Stub_Position : Cursor := Position;
         begin
            Parse_Subprogram_Construct (Stub_Position, Result);
         end;
      end if;

      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            N : constant String := Lookahead_Lower (Position, 1);
            T : constant String := To_String (Current (Position).Text);
         begin
            if Seen_Tok and then Depth = 0 then
               if L = "private"
                 and then not (Start_L0 = "type"
                               and then Ada.Strings.Unbounded.To_String (Last_L) = "is")
               then
                  Add_Declarative_Boundary_Metadata (Current (Position), L);
                  return;
               elsif L = "begin" or else L = "end" then
                  Add_Declarative_Boundary_Metadata (Current (Position), L);
                  return;
               elsif Starts_Strong_Package_Declarative_Item (Position) then
                  Add_Production (Result, Boundary_Kind, Current (Position), Boundary_Text);
                  return;
               end if;
            end if;

            if T = ";" and then Depth = 0 then
               Advance (Position);
               return;
            elsif L = "is" then
               if (Start_L0 = "package"
                   or else Start_L0 = "task"
                   or else Start_L0 = "protected"
                   or else Start_L0 = "procedure"
                   or else Start_L0 = "function"
                   or else Start_L0 = "entry")
                 and then N /= "new"
                 and then N /= "separate"
                 and then N /= "null"
                 and then N /= "abstract"
                 and then N /= "("
                 and then N /= ";"
               then
                  Depth := Depth + 1;
               end if;
            elsif L = "begin" then
               if Depth > 0 then
                  Saw_Begin := True;
                  Depth := Depth + 1;
               end if;
            elsif L = "record" or else L = "case" then
               if (Depth > 0 or else Start_L0 = "type" or else Start_L0 = "for")
                 and then not
                   (L = "record"
                    and then Ada.Strings.Unbounded.To_String (Last_L) = "null")
               then
                  Depth := Depth + 1;
               end if;
            elsif L = "end" then
               if Depth = 0 then
                  Add_Declarative_Boundary_Metadata (Current (Position), L);
                  return;
               end if;
               Depth := Depth - 1;
               if Depth = 0 or else (Saw_Begin and then Depth = 1) then
                  Advance (Position);
                  if not At_End (Position)
                    and then To_String (Current (Position).Text) = ";"
                  then
                     Advance (Position);
                  end if;
                  return;
               end if;
            end if;
         end;
         Seen_Tok := True;
         Last_L := Ada.Strings.Unbounded.To_Unbounded_String (Current_Lower (Position));
         Advance (Position);
      end loop;
   end Skip_Package_Declarative_Item;


   procedure Skip_Subprogram_Body_Declarative_Item
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Start_L0 : constant String := Current_Lower (Position);
      Saw_Is   : Boolean := False;
      Depth    : Natural := 0;
      Seen_Tok : Boolean := False;
   begin
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant String := To_String (Current (Position).Text);
         begin
            if Seen_Tok and then Depth = 0 then
               if L = "begin" or else L = "exception" or else L = "end"
                 or else Starts_Strong_Package_Declarative_Item (Position)
               then
                  Add_Production
                    (Result, Production_Subprogram_Body_Declarative_Recovery_Boundary,
                     Current (Position), "subprogram body declarative item recovery boundary");
                  return;
               end if;
            end if;

            if T = ";" and then not Saw_Is and then Depth = 0 then
               Advance (Position);
               return;
            elsif L = "is" and then Start_L0 /= "subtype" then
               Saw_Is := True;
               Depth := Depth + 1;
            elsif Saw_Is
              and then (L = "record" or else L = "case" or else L = "loop")
            then
               Depth := Depth + 1;
            elsif Saw_Is and then L = "end" then
               if Depth <= 1 then
                  Advance (Position);
                  if not At_End (Position)
                    and then To_String (Current (Position).Text) = ";"
                  then
                     Advance (Position);
                  end if;
                  return;
               else
                  Depth := Depth - 1;
               end if;
            elsif T = ";" and then Saw_Is and then Depth = 0 then
               Advance (Position);
               return;
            end if;
         end;
         Seen_Tok := True;
         Advance (Position);
      end loop;
   end Skip_Subprogram_Body_Declarative_Item;


   procedure Add_Package_Declaration_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe          : Cursor := Position;
      Found_Is       : Boolean := False;
      In_Private     : Boolean := False;
      Visible_Opened : Boolean := False;
      Private_Opened : Boolean := False;
   begin
      while not At_End (Probe) loop
         declare
            L : constant String := Current_Lower (Probe);
            T : constant String := To_String (Current (Probe).Text);
         begin
            if not Found_Is then
               if L = "is" then
                  Found_Is := True;
                  Advance (Probe);
                  if not At_End (Probe)
                    and then Current_Lower (Probe) /= "private"
                    and then Current_Lower (Probe) /= "end"
                    and then To_String (Current (Probe).Text) /= ";"
                  then
                     Visible_Opened := True;
                     Add_Production
                       (Result, Production_Package_Visible_Part,
                        Current (Probe), "package visible part");
                  end if;
                  goto Continue_Scan;
               elsif T = ";" then
                  return;
               end if;

            elsif L = "begin" then
               if In_Private then
                  Add_Production
                    (Result, Production_Package_Private_Begin_Recovery_Boundary,
                     Current (Probe), "package private declarative begin recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Package_Unexpected_Begin_Boundary,
                  Current (Probe), "unexpected begin in package declaration");
               Add_Production
                 (Result, Production_Package_Declarative_Recovery_Boundary,
                  Current (Probe), "package declaration recovery boundary");
               return;

            elsif L = "private" and then In_Private then
               Add_Production
                 (Result, Production_Package_Duplicate_Private_Boundary,
                  Current (Probe), "duplicate package private boundary");
               Add_Production
                 (Result, Production_Package_Private_Declarative_Item_Recovery_Boundary,
                  Current (Probe), "package private declarative item recovery boundary");
               Add_Production
                 (Result, Production_Package_Nested_Declarative_Item_Recovery_Boundary,
                  Current (Probe), "package nested declarative item recovery boundary");
               Advance (Probe);
               goto Continue_Scan;

            elsif L = "private" and then not In_Private then
               In_Private := True;
               Private_Opened := True;
               Add_Production
                 (Result, Production_Package_Private_Declarative_Part,
                  Current (Probe), "package private declarative part");
               Advance (Probe);
               goto Continue_Scan;

            elsif L = "end" then
               Add_Production
                 (Result, Production_Package_Declaration_End_Keyword,
                  Current (Probe), "package declaration end keyword");
               Advance (Probe);
               if Current (Probe).Kind = Token_Identifier
                 or else Current (Probe).Kind = Token_Keyword
               then
                  Add_Production
                    (Result, Production_Package_Declaration_End_Name,
                     Current (Probe), "package declaration end name");
                  Advance (Probe);
               end if;
               if To_String (Current (Probe).Text) = ";" then
                  Add_Production
                    (Result, Production_Package_Declaration_End_Terminator,
                     Current (Probe), "package declaration end terminator");
               else
                  Add_Production
                    (Result,
                     Production_Package_Declaration_Missing_End_Terminator_Recovery_Boundary,
                     Current (Probe),
                     "package declaration missing end terminator recovery boundary");
               end if;
               return;

            elsif Starts_Package_Declarative_Item (Probe) then
               if In_Private then
                  if not Private_Opened then
                     Private_Opened := True;
                     Add_Production
                       (Result, Production_Package_Private_Declarative_Part,
                        Current (Probe), "package private declarative part");
                  end if;
                  Add_Production
                    (Result, Production_Package_Private_Declarative_Item,
                     Current (Probe), "package private declarative item");
               else
                  if not Visible_Opened then
                     Visible_Opened := True;
                     Add_Production
                       (Result, Production_Package_Visible_Part,
                        Current (Probe), "package visible part");
                  end if;
                  Add_Production
                    (Result, Production_Package_Visible_Declarative_Item,
                     Current (Probe), "package visible declarative item");
               end if;
               if (Current (Probe).Kind = Token_Identifier
                   or else Current (Probe).Kind = Token_Keyword)
                 and then Has_Token_Before_Semicolon (Probe, ":=")
               then
                  declare
                     Item_Position : Cursor := Probe;
                  begin
                     Parse_Declaration_Or_Statement (Item_Position, Result);
                  end;
               end if;
               if (Current_Lower (Probe) = "procedure"
                   or else Current_Lower (Probe) = "function")
                 and then Has_Token_Before_Semicolon (Probe, "separate")
               then
                  declare
                     Item_Position : Cursor := Probe;
                  begin
                     Parse_Subprogram_Construct (Item_Position, Result);
                  end;
               end if;
               if In_Private then
                  Skip_Package_Declarative_Item
                    (Probe, Result,
                     Production_Package_Private_Declarative_Item_Recovery_Boundary,
                     "package private declarative item recovery boundary");
               else
                  Skip_Package_Declarative_Item
                    (Probe, Result,
                     Production_Package_Visible_Declarative_Item_Recovery_Boundary,
                     "package visible declarative item recovery boundary");
               end if;
               goto Continue_Scan;
            end if;
         end;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Package_Declaration_Part_Productions;



   procedure Add_Package_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe       : Cursor := Position;
      After_Is    : Cursor := Position;
      Found_Is    : Boolean := False;
      Found_Begin : Boolean := False;
      Found_Exc   : Boolean := False;

      procedure Add_Nested_Subprogram_Body_Stubs (Start : Cursor) is
         Scan : Cursor := Start;
      begin
         while not At_End (Scan) loop
            exit when Current_Lower (Scan) = "begin"
              or else Current_Lower (Scan) = "exception"
              or else Current_Lower (Scan) = "end";
            if (Current_Lower (Scan) = "procedure"
                or else Current_Lower (Scan) = "function")
              and then Has_Token_Before_Semicolon (Scan, "separate")
            then
               Add_Production
                 (Result, Production_Subprogram_Body, Current (Scan),
                  "package body nested subprogram body");
               Add_Production
                 (Result, Production_Subprogram_Body_Stub, Current (Scan),
                  "package body nested subprogram body stub");
               Add_Production
                 (Result, Production_Body_Stub_Kind_Keyword, Current (Scan),
                  "package body nested subprogram body stub kind keyword");
               Add_Production
                 (Result, Production_Body_Stub_Separate_Keyword, Current (Scan),
                  "package body nested body stub separate keyword");
               Add_Production
                 (Result, Production_Body_Stub_Subunit_Link_Hint,
                  Current (Scan),
                  "package body nested body stub subunit link hint");
            end if;
            Advance (Scan);
         end loop;
      end Add_Nested_Subprogram_Body_Stubs;
   begin
      while not At_End (Probe) loop
         if not Found_Is then
            if Current_Lower (Probe) = "is" then
               Found_Is := True;
               Advance (Probe);
               After_Is := Probe;
               Add_Nested_Subprogram_Body_Stubs (After_Is);
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "separate"
               then
                  Add_Production
                    (Result, Production_Package_Body_Declarative_Part,
                     Current (After_Is), "package body declarative part");
               end if;
               goto Continue_Scan;
            end if;
         elsif not Found_Begin and then Current_Lower (Probe) = "private" then
            Add_Production
              (Result, Production_Package_Body_Unexpected_Private_Boundary,
               Current (Probe), "unexpected private in package body");
            Add_Production
              (Result, Production_Package_Body_Private_Declarative_Recovery_Boundary,
               Current (Probe), "package body private declarative recovery boundary");
            Add_Production
              (Result, Production_Package_Declarative_Recovery_Boundary,
               Current (Probe), "package body declarative recovery boundary");
            Add_Production
              (Result, Production_Package_Body_Declarative_Recovery_Boundary,
               Current (Probe), "package body declarative item recovery boundary");
         elsif not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Package_Body_Statement_Sequence,
               Current (Probe), "package body statements");
         elsif not Found_Begin and then Starts_Package_Declarative_Item (Probe) then
            Add_Production
              (Result, Production_Package_Body_Declarative_Item,
               Current (Probe), "package body declarative item");
            if (Current_Lower (Probe) = "procedure"
                or else Current_Lower (Probe) = "function")
              and then Has_Token_Before_Semicolon (Probe, "separate")
            then
               Add_Production
                 (Result, Production_Subprogram_Body, Current (Probe),
                  "package body nested subprogram body");
               Add_Production
                 (Result, Production_Subprogram_Body_Stub, Current (Probe),
                  "package body nested subprogram body stub");
               Add_Production
                 (Result, Production_Body_Stub_Kind_Keyword, Current (Probe),
                  "package body nested subprogram body stub kind keyword");
               Add_Production
                 (Result, Production_Body_Stub_Separate_Keyword, Current (Probe),
                  "package body nested body stub separate keyword");
               Add_Production
                 (Result, Production_Body_Stub_Subunit_Link_Hint,
                  Current (Probe),
                  "package body nested body stub subunit link hint");
            end if;
            Skip_Package_Declarative_Item
              (Probe, Result, Production_Package_Body_Declarative_Recovery_Boundary,
               "package body declarative item recovery boundary");
            goto Continue_Scan;
         elsif Found_Begin and then not Found_Exc
           and then Current_Lower (Probe) = "exception"
         then
            Found_Exc := True;
            Add_Production
              (Result, Production_Package_Body_Exception_Part,
               Current (Probe), "package body exception part");
         elsif Current_Lower (Probe) = "end" then
            Add_Production
              (Result, Production_Package_Body_End_Keyword,
               Current (Probe), "package body end keyword");
            Advance (Probe);
            if Current (Probe).Kind = Token_Identifier
              or else Current (Probe).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Package_Body_End_Name,
                  Current (Probe), "package body end name");
               Advance (Probe);
            end if;
            if To_String (Current (Probe).Text) = ";" then
               Add_Production
                 (Result, Production_Package_Body_End_Terminator,
                  Current (Probe), "package body end terminator");
            else
               Add_Production
                 (Result, Production_Package_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Position), "package body missing end terminator recovery boundary");
            end if;
            return;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Package_Body_Part_Productions;


   procedure Add_Subprogram_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe       : Cursor := Position;
      After_Is    : Cursor := Position;
      Body_Name   : constant String := Lookahead_Lower (Position, 1);
      Found_Is    : Boolean := False;
      Found_Begin : Boolean := False;
      Found_Exc   : Boolean := False;

      function Is_Nested_Statement_End_Follower (C : Cursor) return Boolean is
         Lower : constant String := Current_Lower (C);
      begin
         return Lower = "if"
           or else Lower = "loop"
           or else Lower = "case"
           or else Lower = "record"
           or else Lower = "select";
      end Is_Nested_Statement_End_Follower;
   begin
      while not At_End (Probe) loop
         if not Found_Is then
            if Current_Lower (Probe) = "is" then
               Found_Is := True;
               Advance (Probe);
               After_Is := Probe;
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "separate"
               then
                  Add_Production
                    (Result, Production_Subprogram_Body_Declarative_Part,
                     Current (After_Is), "subprogram body declarative part");
               end if;
               goto Continue_Scan;
            end if;

         elsif not Found_Begin
           and then Starts_Package_Declarative_Item (Probe)
         then
            Add_Production
              (Result, Production_Subprogram_Body_Declarative_Item,
               Current (Probe), "subprogram body declarative item");
            if (Current (Probe).Kind = Token_Identifier
                or else Current (Probe).Kind = Token_Keyword)
              and then Has_Token_Before_Semicolon (Probe, ":=")
            then
               declare
                  Item_Position : Cursor := Probe;
               begin
                  Parse_Declaration_Or_Statement (Item_Position, Result);
               end;
            end if;
            if Has_Token_Before_Semicolon (Probe, "for")
              and then Has_Token_Before_Semicolon (Probe, "=>")
            then
               declare
                  Item_Scan : Cursor := Probe;
               begin
                  while not At_End (Item_Scan)
                    and then To_String (Current (Item_Scan).Text) /= ";"
                  loop
                     if Current_Lower (Item_Scan) = "for" then
                        declare
                           Iterated_Position : Cursor := Item_Scan;
                        begin
                           Parse_Iterated_Component_Association
                             (Iterated_Position, Result);
                        end;
                        exit;
                     end if;
                     Advance (Item_Scan);
                  end loop;
               end;
            end if;
            Skip_Subprogram_Body_Declarative_Item (Probe, Result);
            goto Continue_Scan;

         elsif not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Subprogram_Body_Begin_Keyword,
               Current (Probe), "subprogram body begin keyword");
            Add_Production
              (Result, Production_Subprogram_Body_Statement_Sequence,
               Current (Probe), "subprogram body statements");

         elsif not Found_Begin
           and then (Current_Lower (Probe) = "exception"
                     or else Current_Lower (Probe) = "end")
         then
            Add_Production
              (Result, Production_Subprogram_Body_Recovery_Boundary,
               Current (Probe), "missing begin in subprogram body");
            if Current_Lower (Probe) = "end" then
               Add_Production
                 (Result, Production_Subprogram_Body_End_Keyword,
                  Current (Probe), "subprogram body end keyword");
               Advance (Probe);
               if Current (Probe).Kind = Token_Identifier
                 or else Current (Probe).Kind = Token_Keyword
               then
                  Add_Production
                    (Result, Production_Subprogram_Body_End_Name,
                     Current (Probe), "subprogram body end name");
                  Advance (Probe);
               end if;
               if To_String (Current (Probe).Text) = ";" then
                  Add_Production
                    (Result, Production_Subprogram_Body_End_Terminator,
                     Current (Probe), "subprogram body end terminator");
               else
                  Add_Production
                    (Result, Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary,
                     Current (Position), "subprogram body missing end terminator recovery boundary");
               end if;
               return;
            end if;

         elsif Found_Begin and then not Found_Exc
           and then Current_Lower (Probe) = "exception"
         then
            Found_Exc := True;
            Add_Production
              (Result, Production_Subprogram_Body_Exception_Part,
               Current (Probe), "subprogram body exception part");

         elsif Found_Begin and then Current_Lower (Probe) = "end" then
            declare
               End_Token : constant Token_Info := Current (Probe);
               Tail      : Cursor := Probe;
            begin
               Advance (Tail);
               if not At_End (Tail)
                 and then Is_Nested_Statement_End_Follower (Tail)
               then
                  null;
               elsif not At_End (Tail)
                 and then (Current (Tail).Kind = Token_Identifier
                           or else Current (Tail).Kind = Token_Keyword)
                 and then Body_Name'Length > 0
                 and then Current_Lower (Tail) /= Body_Name
               then
                  null;
               else
                  Add_Production
                    (Result, Production_Subprogram_Body_End_Keyword,
                     End_Token, "subprogram body end keyword");
                  Probe := Tail;
                  if Current (Probe).Kind = Token_Identifier
                    or else Current (Probe).Kind = Token_Keyword
                  then
                     Add_Production
                       (Result, Production_Subprogram_Body_End_Name,
                        Current (Probe), "subprogram body end name");
                     Advance (Probe);
                  end if;
                  if To_String (Current (Probe).Text) = ";" then
                     Add_Production
                       (Result, Production_Subprogram_Body_End_Terminator,
                        Current (Probe), "subprogram body end terminator");
                  else
                     Add_Production
                       (Result,
                        Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary,
                        Current (Position),
                        "subprogram body missing end terminator recovery boundary");
                  end if;
                  return;
               end if;
            end;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;

      if Found_Is and then not Found_Begin then
         Add_Production
           (Result, Production_Subprogram_Body_Recovery_Boundary,
            Current (Position), "subprogram body missing begin/end boundary");
      end if;
   end Add_Subprogram_Body_Part_Productions;



   procedure Add_Task_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe       : Cursor := Position;
      After_Is    : Cursor := Position;
      Found_Is    : Boolean := False;
      Found_Begin : Boolean := False;
      Found_Exc   : Boolean := False;

      procedure Add_Task_Declarative_Synchronizer (C : Cursor) is
         Lower : constant String := Current_Lower (C);
      begin
         if Lower = "begin" then
            Add_Production
              (Result, Production_Task_Body_Declarative_Begin_Boundary,
               Current (C), "task body declarative begin boundary");
         elsif Lower = "end" then
            Add_Production
              (Result, Production_Task_Body_Declarative_End_Boundary,
               Current (C), "task body declarative end boundary");
         end if;
      end Add_Task_Declarative_Synchronizer;
   begin
      while not At_End (Probe) loop
         if not Found_Is then
            if Current_Lower (Probe) = "is" then
               Found_Is := True;
               Advance (Probe);
               After_Is := Probe;
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "begin"
                 and then Current_Lower (After_Is) /= "separate"
               then
                  Add_Production
                    (Result, Production_Task_Body_Declarative_Part,
                     Current (After_Is), "task body declarative part");
               elsif not At_End (After_Is)
                 and then Current_Lower (After_Is) = "begin"
               then
                  Add_Production
                    (Result, Production_Task_Body_Declarative_Part,
                     Current (After_Is), "task body declarative part");
               end if;
               goto Continue_Scan;
            end if;
         elsif not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Task_Body_Begin_Keyword,
               Current (Probe), "task body begin keyword");
            Add_Production
              (Result, Production_Task_Body_Statement_Sequence,
               Current (Probe), "task body statements");
         elsif not Found_Begin
           and then Starts_Package_Declarative_Item (Probe)
         then
            Add_Production
              (Result, Production_Task_Body_Declarative_Item_Start,
               Current (Probe), "task body declarative item start");
            Skip_Package_Declarative_Item
              (Probe, Result,
               Production_Task_Body_Declarative_Item_Recovery_Boundary,
               "task body declarative item recovery boundary");
            if not At_End (Probe) then
               Add_Task_Declarative_Synchronizer (Probe);
            end if;
            goto Continue_Scan;
         elsif not Found_Begin
           and then (Current_Lower (Probe) = "exception"
                     or else Current_Lower (Probe) = "end")
         then
            Add_Production
              (Result, Production_Task_Body_Recovery_Boundary,
               Current (Probe), "task body missing begin recovery boundary");
            if Current_Lower (Probe) = "end" then
               Add_Production
                 (Result, Production_Task_Body_End_Keyword,
                  Current (Probe), "task body end keyword");
               Advance (Probe);
               if not At_End (Probe)
                 and then (Current (Probe).Kind = Token_Identifier
                           or else Current (Probe).Kind = Token_Keyword)
               then
                  Add_Production
                    (Result, Production_Task_Body_End_Name,
                     Current (Probe), "task body end name");
                  Advance (Probe);
               end if;
               if not At_End (Probe)
                 and then To_String (Current (Probe).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Task_Body_End_Terminator,
                     Current (Probe), "task body end terminator");
               else
                  Add_Production
                    (Result, Production_Task_Body_Missing_End_Terminator_Recovery_Boundary,
                     Current (Position), "task body missing end terminator recovery boundary");
               end if;
               return;
            end if;
         elsif Found_Begin and then not Found_Exc
           and then Current_Lower (Probe) = "exception"
         then
            Found_Exc := True;
            Add_Production
              (Result, Production_Task_Body_Exception_Part,
               Current (Probe), "task body exception part");
         elsif Found_Begin and then Current_Lower (Probe) = "end" then
            Add_Production
              (Result, Production_Task_Body_End_Keyword,
               Current (Probe), "task body end keyword");
            Advance (Probe);
            if not At_End (Probe)
              and then (Current (Probe).Kind = Token_Identifier
                        or else Current (Probe).Kind = Token_Keyword)
            then
               Add_Production
                 (Result, Production_Task_Body_End_Name,
                  Current (Probe), "task body end name");
               Advance (Probe);
            end if;
            if not At_End (Probe)
              and then To_String (Current (Probe).Text) = ";"
            then
               Add_Production
                 (Result, Production_Task_Body_End_Terminator,
                  Current (Probe), "task body end terminator");
            else
               Add_Production
                 (Result, Production_Task_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Position), "task body missing end terminator recovery boundary");
            end if;
            return;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Task_Body_Part_Productions;


   procedure Add_Protected_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe                 : Cursor := Position;
      After_Is              : Cursor := Position;
      Found_Is              : Boolean := False;
      In_Operation_Body     : Boolean := False;
      Operation_After_Is    : Boolean := False;
      Operation_In_Begin    : Boolean := False;
      Operation_Is_Entry   : Boolean := False;
      Operation_Name        : Ada.Strings.Unbounded.Unbounded_String;

      procedure Add_Protected_Declarative_Synchronizer (C : Cursor) is
         Lower : constant String := Current_Lower (C);
      begin
         if Lower = "begin" then
            Add_Production
              (Result, Production_Protected_Body_Declarative_Begin_Boundary,
               Current (C), "protected body declarative begin boundary");
         elsif Lower = "end" then
            Add_Production
              (Result, Production_Protected_Body_Declarative_End_Boundary,
               Current (C), "protected body declarative end boundary");
         end if;
      end Add_Protected_Declarative_Synchronizer;

      function Is_Nested_Statement_End_Follower (C : Cursor) return Boolean is
         Lower : constant String := Current_Lower (C);
      begin
         return Lower = "if"
           or else Lower = "loop"
           or else Lower = "case"
           or else Lower = "record"
           or else Lower = "select";
      end Is_Nested_Statement_End_Follower;
   begin
      while not At_End (Probe) loop
         if not Found_Is then
            if Current_Lower (Probe) = "is" then
               Found_Is := True;
               Advance (Probe);
               After_Is := Probe;
               if not At_End (After_Is)
                 and then Current_Lower (After_Is) /= "separate"
                 and then Current_Lower (After_Is) /= "end"
               then
                  Add_Production
                    (Result, Production_Protected_Body_Operation_Part,
                     Current (After_Is), "protected body operation part");
               end if;
               goto Continue_Scan;
            end if;
         elsif Current_Lower (Probe) = "procedure"
           or else Current_Lower (Probe) = "function"
           or else Current_Lower (Probe) = "entry"
         then
            In_Operation_Body := False;
            Operation_After_Is := False;
            Operation_In_Begin := False;
            Operation_Is_Entry := Current_Lower (Probe) = "entry";
            Operation_Name :=
              Ada.Strings.Unbounded.To_Unbounded_String
                (Lookahead_Lower (Probe, 1));
            Add_Production
              (Result, Production_Protected_Operation_Declaration,
               Current (Probe), "protected body operation");
            if Current_Lower (Probe) = "procedure" then
               Add_Production
                 (Result, Production_Protected_Procedure_Body,
                  Current (Probe), "protected procedure body");
            elsif Current_Lower (Probe) = "function" then
               Add_Production
                 (Result, Production_Protected_Function_Body,
                  Current (Probe), "protected function body");
            else
               Add_Production
                 (Result, Production_Protected_Entry_Body,
                  Current (Probe), "protected entry body");
               declare
                  Entry_Parts : Cursor := Probe;
               begin
                  Advance (Entry_Parts);
                  if not At_End (Entry_Parts)
                    and then (Current (Entry_Parts).Kind = Token_Identifier
                              or else Current (Entry_Parts).Kind = Token_Keyword)
                  then
                     Add_Production
                       (Result, Production_Entry_Identifier,
                        Current (Entry_Parts), "entry identifier");
                     Advance (Entry_Parts);
                  end if;
                  Parse_Entry_Parenthesized_Parts
                    (Entry_Parts, Result, Current (Probe));
               end;
            end if;
         elsif Current_Lower (Probe) = "when" then
            Add_Production
              (Result, Production_Protected_Entry_Barrier,
               Current (Probe), "protected entry barrier");
            if not At_End (Probe) then
               declare
                  Condition_Start : Cursor := Probe;
               begin
                  Advance (Condition_Start);
                  if At_End (Condition_Start)
                    or else Current_Lower (Condition_Start) = "is"
                    or else Current_Lower (Condition_Start) = "with"
                    or else Current_Lower (Condition_Start) = "begin"
                    or else Current_Lower (Condition_Start) = "end"
                    or else To_String (Current (Condition_Start).Text) = ";"
                  then
                     Add_Production
                       (Result,
                        Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary,
                        Current (Probe),
                        "protected entry barrier missing condition recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Probe),
                        "expected protected entry barrier condition");
                  else
                     Add_Production
                       (Result, Production_Protected_Entry_Barrier_Condition,
                        Current (Condition_Start),
                        "protected entry barrier condition");
                  end if;
               end;
            end if;
         elsif Operation_After_Is
           and then not Operation_In_Begin
           and then Starts_Package_Declarative_Item (Probe)
         then
            Add_Production
              (Result, Production_Protected_Body_Declarative_Item_Start,
               Current (Probe), "protected body declarative item start");
            Skip_Package_Declarative_Item
              (Probe, Result,
               Production_Protected_Body_Declarative_Item_Recovery_Boundary,
               "protected body declarative item recovery boundary");
            if not At_End (Probe) then
               Add_Protected_Declarative_Synchronizer (Probe);
            end if;
            goto Continue_Scan;
         elsif Current_Lower (Probe) = "is" and then not Operation_After_Is then
            if Operation_Is_Entry then
               Add_Production
                 (Result, Production_Entry_Body_Missing_Barrier_Recovery_Boundary,
                  Current (Probe), "entry body missing barrier recovery boundary");
               Add_Production
                 (Result, Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary,
                  Current (Probe), "protected entry body missing barrier recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Probe),
                  "expected when barrier before protected entry body is");
            end if;
            Operation_After_Is := True;
         elsif Current_Lower (Probe) = "with" then
            Add_Production
              (Result, Production_Protected_Operation_Aspect_Specification,
               Current (Probe), "protected operation aspect specification");
         elsif Current_Lower (Probe) = "begin" then
            In_Operation_Body := True;
            Operation_In_Begin := True;
            Add_Production
              (Result, Production_Protected_Body_Operation_Begin_Keyword,
               Current (Probe), "protected body operation begin keyword");
            if Operation_Is_Entry then
               Add_Production
                 (Result, Production_Entry_Body_Begin_Keyword,
                  Current (Probe), "entry body begin keyword");
               declare
                  Body_Start : Cursor := Probe;
               begin
                  Advance (Body_Start);
                  if At_End (Body_Start)
                    or else Current_Lower (Body_Start) = "end"
                    or else Current_Lower (Body_Start) = "or"
                    or else Current_Lower (Body_Start) = "else"
                    or else Current_Lower (Body_Start) = "then"
                    or else To_String (Current (Body_Start).Text) = ";"
                  then
                     Add_Production
                       (Result,
                        Production_Entry_Body_Missing_Statement_Recovery_Boundary,
                        Current (Body_Start),
                        "entry body missing statement recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Body_Start),
                        "expected statement sequence in entry body");
                  else
                     Add_Production
                       (Result, Production_Entry_Body_Statement_Sequence,
                        Current (Body_Start), "entry body statement sequence");
                     Add_Production
                       (Result, Production_Statement_Sequence,
                        Current (Body_Start), "entry body statement sequence");
                  end if;
               end;
            end if;
         elsif Operation_In_Begin and then Current_Lower (Probe) = "accept" then
            declare
               Statement_Position : Cursor := Probe;
            begin
               Parse_Declaration_Or_Statement (Statement_Position, Result);
            end;
         elsif Current_Lower (Probe) = "private" then
            Add_Production
              (Result, Production_Protected_Body_Recovery_Boundary,
               Current (Probe), "unexpected private in protected body recovery boundary");
         elsif Current_Lower (Probe) = "end" then
            if In_Operation_Body then
               declare
                  End_Token : constant Token_Info := Current (Probe);
                  Tail      : Cursor := Probe;
               begin
                  Advance (Tail);
                  if not At_End (Tail)
                    and then Is_Nested_Statement_End_Follower (Tail)
                  then
                     null;
                  else
                     declare
                        End_Name_Matches : Boolean := True;
                     begin
                        if Operation_Is_Entry
                          and then not At_End (Tail)
                          and then (Current (Tail).Kind = Token_Identifier
                                    or else Current (Tail).Kind = Token_String_Literal)
                          and then Current_Lower (Tail) /=
                            Ada.Strings.Unbounded.To_String (Operation_Name)
                        then
                           End_Name_Matches := False;
                           Add_Production
                             (Result,
                              Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                              End_Token,
                              "entry body missing end terminator recovery boundary");
                        end if;

                        if not End_Name_Matches then
                           In_Operation_Body := False;
                           Operation_After_Is := False;
                           Operation_In_Begin := False;
                           Operation_Is_Entry := False;
                           goto Continue_Scan;
                        end if;
                     end;

                     if Operation_Is_Entry then
                        Add_Production
                          (Result, Production_Entry_Body_End_Keyword,
                           End_Token, "entry body end keyword");
                     end if;
                     In_Operation_Body := False;
                     Operation_After_Is := False;
                     Operation_In_Begin := False;
                     Add_Production
                       (Result, Production_Protected_Body_Operation_End_Keyword,
                        End_Token, "protected body operation end keyword");
                     if not At_End (Tail)
                       and then (Current (Tail).Kind = Token_Identifier
                                 or else Current (Tail).Kind = Token_String_Literal)
                     then
                        if Operation_Is_Entry then
                           Add_Production
                             (Result, Production_Entry_Body_End_Name,
                              Current (Tail), "entry body end name");
                        end if;
                        Add_Production
                          (Result, Production_Protected_Body_Operation_End_Name,
                           Current (Tail), "protected body operation end name");
                        Advance (Tail);
                     end if;
                     if not At_End (Tail)
                       and then To_String (Current (Tail).Text) = ";"
                     then
                        if Operation_Is_Entry then
                           Add_Production
                             (Result, Production_Entry_Body_End_Terminator,
                              Current (Tail), "entry body end terminator");
                        end if;
                        Add_Production
                          (Result, Production_Protected_Body_Operation_End_Terminator,
                           Current (Tail), "protected body operation end terminator");
                        Probe := Tail;
                     else
                        if Operation_Is_Entry then
                           Add_Production
                             (Result,
                              Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                              End_Token,
                              "entry body missing end terminator recovery boundary");
                        end if;
                        Add_Production
                          (Result, Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary,
                           End_Token, "protected body operation missing end terminator recovery boundary");
                     end if;
                     Operation_Is_Entry := False;
                  end if;
               end;
            else
               Add_Production
                 (Result, Production_Protected_Body_End_Keyword,
                  Current (Probe), "protected body end keyword");
               Advance (Probe);
               if not At_End (Probe)
                 and then (Current (Probe).Kind = Token_Identifier
                           or else Current (Probe).Kind = Token_Keyword)
               then
                  Add_Production
                    (Result, Production_Protected_Body_End_Name,
                     Current (Probe), "protected body end name");
                  Advance (Probe);
               end if;
               if not At_End (Probe)
                 and then To_String (Current (Probe).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Protected_Body_End_Terminator,
                     Current (Probe), "protected body end terminator");
               else
                  Add_Production
                    (Result, Production_Protected_Body_Missing_End_Terminator_Recovery_Boundary,
                     Current (Position), "protected body missing end terminator recovery boundary");
               end if;
               return;
            end if;
         end if;

         Advance (Probe);
         <<Continue_Scan>>
         null;
      end loop;
   end Add_Protected_Body_Part_Productions;


   procedure Parse_Subprogram_Construct
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok          : constant Token_Info := Current (Position);
      Subprogram   : constant String := Current_Lower (Position);
      Probe        : Cursor := Position;
      Saw_Is       : Boolean := False;
      Saw_New      : Boolean := False;
      Saw_Abstract : Boolean := False;
      Saw_Null     : Boolean := False;
      Saw_Expr     : Boolean := False;
      Saw_Renames  : Boolean := False;
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
            Add_Subprogram_Body_Part_Productions (Position, Result);
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
         end if;
      else
         Parse_Subprogram_Declaration_Aspect_Or_Terminator (Position, Result);
      end if;
   end Parse_Subprogram_Construct;



   function Parenthesized_Has_Top_Level_Token
     (Position : Cursor;
      Text     : String) return Boolean is
      Probe : Cursor := Position;
      Depth : Natural := 0;
   begin
      if To_String (Current (Probe).Text) /= "(" then
         return False;
      end if;

      while not At_End (Probe) loop
         declare
            T : constant String := To_String (Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
            Wanted : constant String := Lower (Text);
         begin
            if T = "(" then
               Depth := Depth + 1;
            elsif T = ")" then
               if Depth = 0 then
                  return False;
               elsif Depth = 1 then
                  return False;
               else
                  Depth := Depth - 1;
               end if;
            elsif Depth = 1 and then (T = Text or else L = Wanted) then
               return True;
            end if;
         end;
         Advance (Probe);
      end loop;

      return False;
   end Parenthesized_Has_Top_Level_Token;

   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Tok      : Token_Info) is
      First_Is_Family : Boolean := False;

      procedure Skip_One_Parenthesized_Group is
         Depth : Natural := 0;
      begin
         while not At_End (Position) loop
            declare
               T : constant String := To_String (Current (Position).Text);
            begin
               if T = "(" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth <= 1 then
                     Advance (Position);
                     return;
                  else
                     Depth := Depth - 1;
                  end if;
               end if;
               Advance (Position);
            end;
         end loop;
      end Skip_One_Parenthesized_Group;
   begin
      if To_String (Current (Position).Text) /= "(" then
         return;
      end if;

      if Lookahead_Lower (Position, 1) = "for" then
         --  Feed_Item bodies use an entry index specification of the shape
         --  ``(for I in Index_Subtype)`` before the optional parameter
         --  profile.  This is not a parameter profile and must remain a
         --  distinct grammar production for IDE-grade tasking support.
         Add_Production
           (Result, Production_Entry_Index_Specification, Tok,
            "entry index specification");
         Add_Production
           (Result, Production_Entry_Body_Index_Identifier, Tok,
            "entry body index identifier");
         Add_Production
           (Result, Production_Entry_Body_Index_Subtype, Tok,
            "entry body index subtype");
         Skip_One_Parenthesized_Group;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = "("
         then
            Add_Production
              (Result, Production_Entry_Parameter_Profile, Current (Position),
               "entry parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
      else
         --  A protected entry declaration with two parenthesized parts uses
         --  the first one as an entry-family discrete subtype definition and
         --  the second one as the parameter profile.  A single parenthesized
         --  part containing a top-level ':' is an ordinary parameter profile.
         First_Is_Family :=
           not Parenthesized_Has_Top_Level_Token (Position, ":")
           and then not Parenthesized_Has_Top_Level_Token (Position, ";")
           and then Lookahead_Lower (Position, 1) /= "in"
           and then Lookahead_Lower (Position, 1) /= "out";

         if First_Is_Family then
            declare
               Mark_Pos : constant Natural := Mark (Position);
               Family_Is_Empty : constant Boolean :=
                 To_String (Current (Position).Text) = "("
                 and then Lookahead_Lower (Position, 1) = ")";
               Family_Has_Range : constant Boolean :=
                 Parenthesized_Has_Top_Level_Token (Position, "..")
                 or else Parenthesized_Has_Top_Level_Token (Position, "range");
            begin
               Skip_One_Parenthesized_Group;

               if Family_Is_Empty then
                  Add_Production
                    (Result,
                     Production_Entry_Family_Empty_Definition_Recovery_Boundary,
                     Tok, "entry family empty definition recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected entry family discrete subtype definition");
               end if;

               if To_String (Current (Position).Text) = "(" then
                  Add_Production
                    (Result, Production_Entry_Family_Definition, Tok,
                     "entry family definition");
                  Add_Production
                    (Result,
                     Production_Entry_Family_Discrete_Subtype_Definition,
                     Tok, "entry family discrete subtype definition");
                  Add_Production
                    (Result, Production_Entry_Family_Index_Subtype, Tok,
                     "entry family index subtype");
                  if Family_Has_Range then
                     Add_Production
                       (Result, Production_Entry_Family_Range_Definition, Tok,
                        "entry family range definition");
                  end if;
                  Add_Production
                    (Result, Production_Entry_Parameter_Profile,
                     Current (Position), "entry parameter profile");
                  Parse_Parameter_Profile (Position, Result);
               else
                  --  Ambiguous one-parenthesis form: keep the family marker
                  --  for ``entry E (Positive);`` and do not fabricate a
                  --  parameter profile. Empty parentheses are a recovery-only
                  --  entry-family shape and must not fabricate an index subtype.
                  Add_Production
                    (Result, Production_Entry_Family_Definition, Tok,
                     "entry family definition");
                  if not Family_Is_Empty then
                     Add_Production
                       (Result,
                        Production_Entry_Family_Discrete_Subtype_Definition,
                        Tok, "entry family discrete subtype definition");
                     Add_Production
                       (Result, Production_Entry_Family_Index_Subtype, Tok,
                        "entry family index subtype");
                     if Family_Has_Range then
                        Add_Production
                          (Result, Production_Entry_Family_Range_Definition, Tok,
                           "entry family range definition");
                     end if;
                  end if;
                  Restore (Position, Mark_Pos);
                  Skip_One_Parenthesized_Group;
               end if;
            end;
         else
            Add_Production
              (Result, Production_Entry_Parameter_Profile, Current (Position),
               "entry parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
      end if;
   end Parse_Entry_Parenthesized_Parts;


   procedure Add_Entry_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
      Probe       : Cursor := Position;
      Found_Begin : Boolean := False;
   begin
      while not At_End (Probe) loop
         if not Found_Begin and then Current_Lower (Probe) = "begin" then
            Found_Begin := True;
            Add_Production
              (Result, Production_Entry_Body_Begin_Keyword,
               Current (Probe), "entry body begin keyword");
            declare
               Body_Start : Cursor := Probe;
            begin
               Advance (Body_Start);
               if At_End (Body_Start)
                 or else Current_Lower (Body_Start) = "end"
                 or else Current_Lower (Body_Start) = "or"
                 or else Current_Lower (Body_Start) = "else"
                 or else Current_Lower (Body_Start) = "then"
                 or else To_String (Current (Body_Start).Text) = ";"
               then
                  Add_Production
                    (Result,
                     Production_Entry_Body_Missing_Statement_Recovery_Boundary,
                     Current (Body_Start),
                     "entry body missing statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Body_Start),
                     "expected statement sequence in entry body");
               else
                  Add_Production
                    (Result, Production_Entry_Body_Statement_Sequence,
                     Current (Body_Start), "entry body statement sequence");
                  Add_Production
                    (Result, Production_Statement_Sequence,
                     Current (Body_Start), "entry body statement sequence");
               end if;
            end;
         elsif Current_Lower (Probe) = "end" then
            Add_Production
              (Result, Production_Entry_Body_End_Keyword,
               Current (Probe), "entry body end keyword");
            Advance (Probe);
            if not At_End (Probe)
              and then (Current (Probe).Kind = Token_Identifier
                        or else Current (Probe).Kind = Token_Keyword)
            then
               Add_Production
                 (Result, Production_Entry_Body_End_Name,
                  Current (Probe), "entry body end name");
               Advance (Probe);
            end if;
            if not At_End (Probe)
              and then To_String (Current (Probe).Text) = ";"
            then
               Add_Production
                 (Result, Production_Entry_Body_End_Terminator,
                  Current (Probe), "entry body end terminator");
            else
               Add_Production
                 (Result, Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Position),
                  "entry body missing end terminator recovery boundary");
            end if;
            return;
         elsif Current_Lower (Probe) = "private"
           or else Current_Lower (Probe) = "or"
           or else Current_Lower (Probe) = "else"
         then
            if Found_Begin then
               Add_Production
                 (Result, Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
                  Current (Probe),
                  "entry body missing end terminator recovery boundary");
               return;
            end if;
         end if;

         Advance (Probe);
      end loop;

      if Found_Begin then
         Add_Production
           (Result, Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary,
            Current (Position),
            "entry body missing end terminator recovery boundary");
      end if;
   end Add_Entry_Body_Part_Productions;


   procedure Parse_Generic_Formal_Object_Declaration
     (Position     : in out Cursor;
      Result       : in out Grammar_Result;
      Leading_With : Boolean := False) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Object_Declaration, Tok,
         "formal object declaration");

      if Leading_With and then Current_Lower (Position) = "with" then
         --  Older editor snapshots accepted a conservative ``with X : T``
         --  recovery shape while parsing generic formal parts.  Keep that
         --  recovery path, but parse the object grammar structurally once the
         --  optional recovery marker has been consumed.
         Advance (Position);
      end if;

      Add_Production
        (Result, Production_Formal_Object_Defining_Name_List,
         Current (Position), "formal object defining name list");
      Parse_Defining_Name_List (Position, Result);

      if not Match_Symbol (Position, ":") then
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected : in formal object declaration");
         Skip_Balanced_To_Semicolon (Position);
         return;
      end if;

      if Current_Lower (Position) = "in" or else Current_Lower (Position) = "out" then
         Add_Production
           (Result, Production_Formal_Object_Mode, Current (Position),
            To_String (Current (Position).Text));
         Advance (Position);
         if Current_Lower (Position) = "out" then
            Add_Production
              (Result, Production_Formal_Object_Mode, Current (Position),
               To_String (Current (Position).Text));
            Advance (Position);
         end if;
      end if;

      if not At_End (Position)
        and then To_String (Current (Position).Text) /= ":="
        and then To_String (Current (Position).Text) /= ";"
      then
         Add_Production
           (Result, Production_Formal_Object_Subtype_Indication,
            Current (Position), "formal object subtype indication");
         Parse_Subtype_Indication (Position, Result);
      end if;

      if Match_Symbol (Position, ":=") then
         Add_Production
           (Result, Production_Formal_Object_Default, Current (Position),
            "formal object default");
         if To_String (Current (Position).Text) = "<>" then
            Add_Production
              (Result, Production_Box_Expression, Current (Position),
               "formal object default box");
            Advance (Position);
         else
            Parse_Expression (Position, Result);
         end if;
      end if;

      Parse_Generic_Formal_Declaration_Aspect_Or_Terminator (Position, Result);
   end Parse_Generic_Formal_Object_Declaration;


   procedure Parse_Formal_Box_Or_Expression
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Kind     : Production_Kind;
      Label    : String) is
   begin
      if To_String (Current (Position).Text) = "<>" then
         Add_Production (Result, Kind, Current (Position), Label);
         Advance (Position);
      elsif At_End (Position)
        or else To_String (Current (Position).Text) = ";"
        or else To_String (Current (Position).Text) = ")"
        or else Current_Lower (Position) = "with"
      then
         --  Keep malformed formal scalar definitions bounded.  Examples such
         --  as "type Count is range ;" or "type Real is digits with ..."
         --  should expose a formal-scalar recovery boundary and leave the
         --  enclosing formal declaration/aspect parser to synchronize at the
         --  semicolon or aspect introducer.
         Add_Production
           (Result, Production_Formal_Scalar_Box_Recovery_Boundary,
            Current (Position), "missing formal scalar box or expression");
      else
         Parse_Expression (Position, Result);
      end if;
   end Parse_Formal_Box_Or_Expression;

   procedure Parse_Formal_Interface_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      if Current_Lower (Position) /= "and" then
         return;
      end if;

      Add_Production
        (Result, Production_Formal_Interface_List, Current (Position),
         "formal interface list");
      Add_Production
        (Result, Production_Formal_Interface_Ancestor_List, Current (Position),
         "formal interface ancestor list");
      while Current_Lower (Position) = "and" loop
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Interface_Subtype, Current (Position),
            "formal interface subtype");
         Parse_Subtype_Mark (Position, Result);
      end loop;
   end Parse_Formal_Interface_List;

   procedure Parse_Formal_Interface_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Interface_Type_Definition, Tok,
         "formal interface type");

      while Current_Lower (Position) = "limited"
        or else Current_Lower (Position) = "task"
        or else Current_Lower (Position) = "protected"
        or else Current_Lower (Position) = "synchronized"
      loop
         Add_Production
           (Result, Production_Formal_Interface_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Formal_Type_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Type_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Advance (Position);
      end loop;

      if Current_Lower (Position) = "interface" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected interface in formal interface type definition");
      end if;

      Parse_Formal_Interface_List (Position, Result);
   end Parse_Formal_Interface_Type_Definition;

   procedure Parse_Formal_Array_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Array_Type_Definition, Tok,
         "formal array type");
      Add_Production
        (Result, Production_Array_Type_Definition, Tok,
         "array type definition");

      if Current_Lower (Position) = "array" then
         Advance (Position);
      end if;

      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Formal_Array_Index_Subtype_Definition,
            Current (Position), "formal array index subtype definition");
         Parse_Array_Index_Part (Position, Result);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected index part in formal array type definition");
      end if;

      if Match_Keyword (Position, "of") then
         Add_Production
           (Result, Production_Formal_Array_Component_Definition,
            Current (Position), "formal array component definition");
         if Current_Lower (Position) = "not"
           or else Current_Lower (Position) = "access"
         then
            Add_Production
              (Result, Production_Array_Component_Access_Definition,
               Current (Position), "formal array component access definition");
         else
            Add_Production
              (Result, Production_Array_Component_Subtype_Indication,
               Current (Position), "formal array component subtype indication");
         end if;
         if Current_Lower (Position) = "aliased" then
            Add_Production
              (Result, Production_Aliased_Part, Current (Position),
               "formal array component aliased part");
            Advance (Position);
            if Current_Lower (Position) = "not"
              or else Current_Lower (Position) = "access"
            then
               Add_Production
                 (Result, Production_Array_Component_Access_Definition,
                  Current (Position), "formal array component access definition");
            end if;
         end if;
         Parse_Subtype_Indication (Position, Result);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected of in formal array type definition");
      end if;
   end Parse_Formal_Array_Type_Definition;

   procedure Parse_Formal_Derived_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      while Current_Lower (Position) = "abstract"
        or else Current_Lower (Position) = "limited"
        or else Current_Lower (Position) = "synchronized"
      loop
         Add_Production
           (Result, Production_Formal_Type_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Type_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Advance (Position);
      end loop;

      Add_Production
        (Result, Production_Formal_Derived_Type_Definition, Tok,
         "formal derived type");

      if Match_Keyword (Position, "new") then
         Add_Production
           (Result, Production_Formal_Derived_Subtype_Mark,
            Current (Position), "formal derived subtype mark");
         Parse_Subtype_Indication (Position, Result);
         if Current_Lower (Position) = "and" then
            Add_Production
              (Result, Production_Formal_Derived_Interface_List,
               Current (Position), "formal derived interface list");
         end if;
         Parse_Formal_Interface_List (Position, Result);

         if Current_Lower (Position) = "with" then
            Advance (Position);
            if Current_Lower (Position) = "private" then
               Add_Production
                 (Result, Production_Formal_Private_Extension_Definition,
                  Current (Position), "formal private extension");
               Advance (Position);
            elsif Current_Lower (Position) = "interface" then
               Parse_Formal_Interface_Type_Definition (Position, Result);
            else
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected private after with in formal derived type definition");
            end if;
         end if;
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected new in formal derived type definition");
      end if;
   end Parse_Formal_Derived_Type_Definition;

   procedure Parse_Formal_Private_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Formal_Private_Type_Definition, Tok,
         "formal private type");

      while Current_Lower (Position) = "abstract"
        or else Current_Lower (Position) = "tagged"
        or else Current_Lower (Position) = "limited"
        or else Current_Lower (Position) = "synchronized"
      loop
         Add_Production
           (Result, Production_Formal_Type_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Add_Production
           (Result, Production_Type_Modifier,
            Current (Position), To_String (Current (Position).Text));
         Advance (Position);
      end loop;

      if Current_Lower (Position) = "private" then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected private in formal private type definition");
      end if;
   end Parse_Formal_Private_Type_Definition;

   procedure Parse_Formal_Scalar_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      if To_String (Current (Position).Text) = "(" then
         Add_Production
           (Result, Production_Formal_Discrete_Type_Definition, Tok,
            "formal discrete type");
         Advance (Position);
         Parse_Formal_Box_Or_Expression
           (Position, Result, Production_Formal_Type_Box,
            "formal discrete box");
         if not Match_Symbol (Position, ")") then
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected ) in formal discrete type definition");
         end if;
      elsif Current_Lower (Position) = "range" then
         Add_Production
           (Result, Production_Formal_Signed_Integer_Type_Definition, Tok,
            "formal signed integer type");
         Advance (Position);
         Parse_Formal_Box_Or_Expression
           (Position, Result, Production_Formal_Range_Box,
            "formal range box");
      elsif Current_Lower (Position) = "mod" then
         Add_Production
           (Result, Production_Formal_Modular_Type_Definition, Tok,
            "formal modular type");
         Advance (Position);
         Parse_Formal_Box_Or_Expression
           (Position, Result, Production_Formal_Range_Box,
            "formal modular box");
      elsif Current_Lower (Position) = "digits" then
         Add_Production
           (Result, Production_Formal_Floating_Point_Definition, Tok,
            "formal floating point type");
         Advance (Position);
         Parse_Formal_Box_Or_Expression
           (Position, Result, Production_Formal_Digits_Box,
            "formal digits box");
         if Current_Lower (Position) = "range" then
            Parse_Range_Constraint (Position, Result);
         end if;
      elsif Current_Lower (Position) = "delta" then
         Advance (Position);
         Parse_Formal_Box_Or_Expression
           (Position, Result, Production_Formal_Delta_Box,
            "formal delta box");
         if Current_Lower (Position) = "digits" then
            Add_Production
              (Result, Production_Formal_Decimal_Fixed_Point_Definition, Tok,
               "formal decimal fixed point type");
            Advance (Position);
            Parse_Formal_Box_Or_Expression
              (Position, Result, Production_Formal_Digits_Box,
               "formal digits box");
         else
            Add_Production
              (Result, Production_Formal_Ordinary_Fixed_Point_Definition, Tok,
               "formal ordinary fixed point type");
         end if;
         if Current_Lower (Position) = "range" then
            Parse_Range_Constraint (Position, Result);
         end if;
      end if;
   end Parse_Formal_Scalar_Type_Definition;

   function Formal_Type_Head_After_Modifiers (Position : Cursor) return String is
      Probe : Cursor := Position;
   begin
      while Current_Lower (Probe) = "abstract"
        or else Current_Lower (Probe) = "tagged"
        or else Current_Lower (Probe) = "limited"
        or else Current_Lower (Probe) = "synchronized"
        or else Current_Lower (Probe) = "task"
        or else Current_Lower (Probe) = "protected"
      loop
         Advance (Probe);
      end loop;
      return Current_Lower (Probe);
   end Formal_Type_Head_After_Modifiers;

   procedure Parse_Formal_Type_Definition_Deep
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      D0   : constant String := Current_Lower (Position);
      D1   : constant String := Lookahead_Lower (Position, 1);
      Head : constant String := Formal_Type_Head_After_Modifiers (Position);
   begin
      if To_String (Current (Position).Text) = "("
        or else D0 = "range"
        or else D0 = "mod"
        or else D0 = "digits"
        or else D0 = "delta"
      then
         Parse_Formal_Scalar_Type_Definition (Position, Result);
      elsif D0 = "array" then
         Parse_Formal_Array_Type_Definition (Position, Result);
      elsif D0 = "access"
        or else (D0 = "not" and then D1 = "null"
                 and then Lookahead_Lower (Position, 2) = "access")
      then
         Add_Production
           (Result, Production_Formal_Access_Type_Definition,
            Current (Position), "formal access type");
         if Has_Token_Before_Semicolon (Position, "procedure")
           or else Has_Token_Before_Semicolon (Position, "function")
         then
            Add_Production
              (Result, Production_Formal_Subprogram_Parameter_Profile,
               Current (Position), "formal access subprogram profile");
         end if;
         if Has_Token_Before_Semicolon (Position, "return") then
            Add_Production
              (Result, Production_Formal_Access_Result_Subtype,
               Current (Position), "formal access result subtype");
         end if;
         Parse_Access_Type_Definition (Position, Result);
      elsif Head = "new" then
         Parse_Formal_Derived_Type_Definition (Position, Result);
      elsif Head = "interface" then
         Parse_Formal_Interface_Type_Definition (Position, Result);
      elsif Head = "private" then
         Parse_Formal_Private_Type_Definition (Position, Result);
      else
         Parse_Type_Definition (Position, Result);
      end if;
   end Parse_Formal_Type_Definition_Deep;

   procedure Parse_Generic_Formal_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      L0  : constant String := Current_Lower (Position);
      L1  : constant String := Lookahead_Lower (Position, 1);
      L2  : constant String := Lookahead_Lower (Position, 2);
   begin
      if At_End (Position) then
         return;
      end if;

      Add_Production (Result, Production_Generic_Formal_Declaration, Tok, "generic formal declaration");

      if L0 = "with" and then (L1 = "procedure" or else L1 = "function") then
         Add_Production (Result, Production_Formal_Subprogram_Declaration, Tok, "formal subprogram");
         Advance (Position);
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Subprogram_Defining_Designator,
            Current (Position), "formal subprogram defining designator");
         Parse_Defining_Name (Position, Result);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Formal_Subprogram_Parameter_Profile,
               Current (Position), "formal subprogram parameter profile");
            Parse_Parameter_Profile (Position, Result);
         end if;
         if Current_Lower (Position) = "return" then
            Advance (Position);
            Add_Production
              (Result, Production_Formal_Subprogram_Result_Subtype,
               Current (Position), "formal subprogram result subtype");
            Parse_Subtype_Indication (Position, Result);
         end if;
         if Current_Lower (Position) = "is" then
            Add_Production (Result, Production_Subprogram_Default, Current (Position), "formal subprogram default");
            Advance (Position);
            if To_String (Current (Position).Text) = "<>" then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Box,
                  Current (Position), "formal subprogram box default");
               Advance (Position);
            elsif Current_Lower (Position) = "null" then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Null,
                  Current (Position), "formal subprogram null default");
               Advance (Position);
            elsif Current_Lower (Position) = "abstract" then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Abstract,
                  Current (Position), "formal subprogram abstract default");
               Advance (Position);
               if not At_End (Position)
                 and then To_String (Current (Position).Text) /= ";"
                 and then Current_Lower (Position) /= "with"
               then
                  Add_Production
                    (Result, Production_Formal_Subprogram_Default_Abstract_Name,
                     Current (Position), "formal subprogram abstract default name");
                  Parse_Expression (Position, Result);
               end if;
            elsif At_End (Position)
              or else To_String (Current (Position).Text) = ";"
              or else Current_Lower (Position) = "with"
            then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary,
                  Current (Position), "formal subprogram missing default target");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected formal subprogram default target after is");
            elsif not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
            then
               Add_Production
                 (Result, Production_Formal_Subprogram_Default_Name,
                  Current (Position), "formal subprogram name default");
               Parse_Expression (Position, Result);
            end if;
         end if;
         Parse_Generic_Formal_Declaration_Aspect_Or_Terminator (Position, Result);

      elsif L0 = "with" and then L1 = "package" then
         Add_Production (Result, Production_Formal_Package_Declaration, Tok, "formal package");
         declare
            Had_Generic_Name : Boolean := False;
            Generic_Name_Tok : Token_Info := Tok;
         begin
         Advance (Position);
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Package_Defining_Name,
            Current (Position), "formal package defining name");
         Parse_Defining_Name (Position, Result);

         if not Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Formal_Package_Missing_Is_Recovery_Boundary,
               Current (Position),
               "formal package missing is recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected is in formal package declaration");
         end if;

         if not Match_Keyword (Position, "new") then
            Add_Production
              (Result, Production_Formal_Package_Missing_New_Recovery_Boundary,
               Current (Position),
               "formal package missing new recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected new in formal package declaration");
         end if;

         if not At_End (Position)
           and then To_String (Current (Position).Text) /= "("
           and then To_String (Current (Position).Text) /= ";"
           and then Current_Lower (Position) /= "with"
           and then Current_Lower (Position) /= "is"
           and then Current_Lower (Position) /= "new"
         then
            --  A formal package declaration names the generic package being
            --  formalized before its formal_package_actual_part:
            --     with package P is new Ada.Containers.Vectors (<>);
            --  Keep this generic_package_name distinct from ordinary generic
            --  actual expressions, preserving selected names while leaving the
            --  following parenthesized actual part for the actual-part parser.
            Generic_Name_Tok := Current (Position);
            Had_Generic_Name := True;
            Add_Production
              (Result, Production_Formal_Package_Generic_Name,
               Current (Position), To_String (Current (Position).Text));
            Parse_Subtype_Mark (Position, Result);
         else
            Add_Production
              (Result, Production_Formal_Package_Missing_Generic_Name,
               Current (Position),
               "missing formal package generic name after is new");
            Add_Production
              (Result, Production_Formal_Package_Missing_Generic_Recovery_Boundary,
               Current (Position),
               "formal package missing generic recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected generic package name in formal package declaration");
         end if;

         if To_String (Current (Position).Text) = "(" then
            Parse_Formal_Package_Actual_Part (Position, Result);
         elsif Had_Generic_Name
           and then (To_String (Current (Position).Text) = ";"
                     or else Current_Lower (Position) = "with")
         then
            --  Ada formal_package_actual_part may be omitted after the
            --  generic_package_name.  Retain that defaulted form explicitly
            --  instead of leaving callers to infer it from the absence of a
            --  parenthesized actual list.
            Add_Production
              (Result, Production_Formal_Package_Defaulted_Actual_Part,
               Generic_Name_Tok, "defaulted formal package actual part");
         end if;
         Parse_Generic_Formal_Declaration_Aspect_Or_Terminator (Position, Result);
         end;


      elsif L0 = "type" then
         Add_Production (Result, Production_Formal_Type_Declaration, Tok, "formal type");
         Advance (Position);
         Add_Production
           (Result, Production_Formal_Type_Defining_Name,
            Current (Position), "formal type defining name");
         Parse_Defining_Name (Position, Result);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Formal_Type_Discriminant_Part,
               Current (Position), "formal type discriminant part");
            Parse_Discriminant_Part (Position, Result);
         end if;
         if Match_Keyword (Position, "is") then
            if Current_Lower (Position) = "tagged"
              and then (Lookahead_Lower (Position, 1) = ";"
                        or else Lookahead_Lower (Position, 1) = "with")
            then
               --  Ada formal incomplete type declarations may use the
               --  optional "is tagged" suffix without a full formal type
               --  definition.  Preserve it as an incomplete formal type, not
               --  as a malformed private/interface definition.
               Add_Production
                 (Result, Production_Formal_Incomplete_Type_Declaration,
                  Tok, "formal incomplete type");
               Add_Production
                 (Result, Production_Formal_Incomplete_Tagged_Type_Definition,
                  Current (Position), "formal incomplete tagged type");
               Add_Production
                 (Result, Production_Formal_Type_Modifier,
                  Current (Position), "tagged");
               Add_Production
                 (Result, Production_Type_Modifier,
                  Current (Position), "tagged");
               Advance (Position);
               Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
                 (Position, Result);
            elsif To_String (Current (Position).Text) = ";"
              or else Current_Lower (Position) = "with"
            then
               --  "type T is;" is malformed, but retaining a
               --  formal-type-specific recovery boundary lets Outline and
               --  semantic colouring avoid consuming the next formal item.
               Add_Production
                 (Result, Production_Formal_Incomplete_Type_Recovery_Boundary,
                  Current (Position),
                  "formal type missing definition after is");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected formal type definition after is");
               Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
                 (Position, Result);
            else
               --  Keep every Ada generic formal type category structural all
               --  the way down.  Earlier passes recognized the family node but
               --  then skipped scalar boxes, derived interface lists, formal
               --  array domains/components, and modified private/interface
               --  forms to the semicolon.  That was enough for outline rows
               --  but not for semantic colouring/navigation over generic
               --  contracts.
               Parse_Formal_Type_Definition_Deep (Position, Result);
               Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
                 (Position, Result);
            end if;
         elsif To_String (Current (Position).Text) = ";"
           or else Current_Lower (Position) = "with"
         then
            --  Formal incomplete type declaration: "type T;" or
            --  "type T (<>) with ...;".  This is a distinct Ada generic
            --  formal type family and must not be reported as a missing "is"
            --  recovery case.
            Add_Production
              (Result, Production_Formal_Incomplete_Type_Declaration,
               Tok, "formal incomplete type");
            Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
              (Position, Result);
         else
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected is in formal type declaration");
            Skip_Balanced_To_Semicolon (Position);
         end if;

      elsif L0 = "with" then
         Parse_Generic_Formal_Object_Declaration
           (Position, Result, Leading_With => True);

      elsif Current (Position).Kind = Token_Identifier
        and then Has_Token_Before_Semicolon (Position, ":")
      then
         Parse_Generic_Formal_Object_Declaration
           (Position, Result, Leading_With => False);

      else
         Add_Production (Result, Production_Recovery_Point, Tok, "unrecognized generic formal declaration");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Generic_Formal_Declaration;

   procedure Parse_Declaration_Or_Statement
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
      L0  : constant String := Current_Lower (Position);
      L1  : constant String := Lookahead_Lower (Position, 1);
   begin
      if At_End (Position) then
         return;
      elsif To_String (Tok.Text) = "<<" then
         Add_Production (Result, Production_Label, Tok, "label");
         Add_Production
           (Result, Production_Label_Open_Delimiter, Tok,
            "label open delimiter");
         Add_Production (Result, Production_Labeled_Statement, Tok, "labeled statement");
         Advance (Position);
         if not At_End (Position) and then To_String (Current (Position).Text) /= ">>" then
            Add_Production
              (Result, Production_Label_Name, Current (Position),
               "label name");
         else
            Add_Production
              (Result, Production_Label_Recovery_Boundary, Tok,
               "empty label recovery boundary");
         end if;
         while not At_End (Position)
           and then Current (Position).Line = Tok.Line
           and then To_String (Current (Position).Text) /= ">>"
         loop
            Advance (Position);
         end loop;
         if not At_End (Position) and then To_String (Current (Position).Text) = ">>" then
            Add_Production
              (Result, Production_Label_Close_Delimiter, Current (Position),
               "label close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Label_Missing_Close_Recovery_Boundary, Tok,
               "label missing close delimiter recovery boundary");
            Add_Production
              (Result, Production_Label_Recovery_Boundary, Tok,
               "label recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected >> in label");
         end if;
      elsif (L0 = "with" and then not Has_Token_Before_Semicolon (Position, "=>"))
        or else (L0 = "limited" and then (L1 = "with" or else (L1 = "private" and then Lookahead_Lower (Position, 2) = "with")))
        or else (L0 = "private" and then L1 = "with")
      then
         Parse_Context_Clause (Position, Result);
      elsif L0 = "use" then
         Parse_Use_Clause (Position, Result);
      elsif L0 = "separate" then
         Add_Production (Result, Production_Separate_Subunit, Tok, "separate subunit");
         Advance (Position);
         if Match_Symbol (Position, "(") then
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Separate_Parent_Unit_Name,
                  Current (Position), "separate parent unit name");
               declare
                  Scan : Cursor := Position;
                  After_Dot : Boolean := False;
               begin
                  while not At_End (Scan)
                    and then To_String (Current (Scan).Text) /= ")"
                  loop
                     if To_String (Current (Scan).Text) = "." then
                        Add_Production
                          (Result, Production_Separate_Parent_Unit_Separator,
                           Current (Scan), "separate parent unit separator");
                        After_Dot := True;
                     elsif After_Dot then
                        Add_Production
                          (Result, Production_Separate_Parent_Unit_Child,
                           Current (Scan), "separate parent unit child");
                        After_Dot := False;
                     end if;
                     Advance (Scan);
                  end loop;
               end;
            end if;
            Parse_Expression (Position, Result);
            if not Match_Symbol (Position, ")") then
               Add_Production (Result, Production_Recovery_Point, Tok, "expected ) in separate subunit");
            end if;
         else
            Add_Production (Result, Production_Recovery_Point, Tok, "expected parent unit in separate subunit");
         end if;
         if not At_End (Position) then
            Add_Production
              (Result, Production_Separate_Body_Declaration, Current (Position),
               "separate body declaration");
            Add_Production
              (Result, Production_Separate_Body_Kind_Keyword, Current (Position),
               "separate body kind keyword");
            if Current_Lower (Position) = "package"
              and then Lookahead_Lower (Position, 1) = "body"
            then
               Add_Production
                 (Result, Production_Separate_Package_Body, Current (Position),
                  "separate package body");
               if Lookahead_Lower (Position, 2) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 2)),
                     "separate package body unit name");
               end if;
            elsif Current_Lower (Position) = "procedure"
              or else Current_Lower (Position) = "function"
            then
               Add_Production
                 (Result, Production_Separate_Subprogram_Body, Current (Position),
                  "separate subprogram body");
               if Lookahead_Lower (Position, 1) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 1)),
                     "separate subprogram body unit name");
               end if;
            elsif Current_Lower (Position) = "task"
              and then Lookahead_Lower (Position, 1) = "body"
            then
               Add_Production
                 (Result, Production_Separate_Task_Body, Current (Position),
                  "separate task body");
               if Lookahead_Lower (Position, 2) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 2)),
                     "separate task body unit name");
               end if;
            elsif Current_Lower (Position) = "protected"
              and then Lookahead_Lower (Position, 1) = "body"
            then
               Add_Production
                 (Result, Production_Separate_Protected_Body, Current (Position),
                  "separate protected body");
               if Lookahead_Lower (Position, 2) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 2)),
                     "separate protected body unit name");
               end if;
            elsif Current_Lower (Position) = "entry" then
               Add_Production
                 (Result, Production_Separate_Entry_Body, Current (Position),
                  "separate entry body");
               if Lookahead_Lower (Position, 1) /= "" then
                  Add_Production
                    (Result, Production_Separate_Body_Unit_Name,
                     Position.Stream.Tokens (Positive (Position.Index + 1)),
                     "separate entry body unit name");
               end if;
            end if;
            Parse_Declaration_Or_Statement (Position, Result);
         end if;
      elsif L0 = "pragma" then
         Parse_Pragma (Position, Result);
      elsif L0 = "generic" then
         if (L1 = "package" or else L1 = "procedure" or else L1 = "function")
           and then Has_Token_Before_Semicolon (Position, "renames")
         then
            Parse_Generic_Renaming_Declaration (Position, Result);
         else
            Add_Production (Result, Production_Generic_Declaration, Tok, "generic");
            Add_Production (Result, Production_Generic_Formal_Part, Tok, "generic formal part");
            Advance (Position);
            while not At_End (Position)
              and then Current_Lower (Position) /= "package"
              and then Current_Lower (Position) /= "procedure"
              and then Current_Lower (Position) /= "function"
            loop
               Parse_Generic_Formal_Declaration (Position, Result);
            end loop;
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Generic_Declaration_Aspect_Specification,
                  Current (Position), "generic declaration aspect placement");
            end if;
         end if;
      elsif L0 = "package" and then L1 = "body" then
         Add_Production (Result, Production_Package_Body, Tok, "package body");
         Advance (Position); -- package
         Advance (Position); -- body
         if not At_End (Position)
           and then Current_Lower (Position) /= "is"
           and then Current_Lower (Position) /= "with"
           and then To_String (Current (Position).Text) /= ";"
         then
            Add_Production
              (Result, Production_Package_Body_Name, Current (Position),
               "package body name");
            Parse_Subtype_Mark (Position, Result);
         end if;
         if Current_Lower (Position) = "is"
           and then Lookahead_Lower (Position, 1) = "separate"
         then
            Add_Production (Result, Production_Package_Body_Stub, Tok, "package body stub");
            Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "package body stub kind keyword");
            Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
            Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
            end if;
            Parse_Attached_Aspect_Or_Semicolon
              (Position, Result, Production_Body_Stub_Aspect_Specification);
         else
            Add_Package_Body_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
               Add_Production
                 (Result, Production_Package_Body_Aspect_Specification,
                  Current (Position), "package body aspect placement");
            end if;
            Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
              (Position, Result, "is", Production_Body_Aspect_Specification);
         end if;
      elsif L0 = "package" then
         if Lookahead_Lower (Position, 2) = "renames" then
            Parse_Package_Renaming_Declaration (Position, Result);
         elsif Starts_Generic_Instantiation (Position, "package") then
            Parse_Generic_Instantiation_Declaration
              (Position, Result, "package");
         else
            Add_Production (Result, Production_Package_Declaration, Tok, "package declaration");
            Add_Package_Declaration_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Package_Declaration_Aspect_Specification,
                  Current (Position), "package declaration aspect placement");
            end if;
            Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
              (Position, Result, "is", Production_Private_Completion_Aspect_Specification);
         end if;
      elsif L0 = "overriding" or else (L0 = "not" and then L1 = "overriding") then
         Add_Production (Result, Production_Overriding_Indicator, Tok, To_String (Tok.Text));
         Advance (Position);
         if L0 = "not" and then Current_Lower (Position) = "overriding" then
            Advance (Position);
         end if;
         if Current_Lower (Position) = "procedure" or else Current_Lower (Position) = "function" then
            Parse_Subprogram_Construct (Position, Result);
         else
            Add_Production (Result, Production_Recovery_Point, Tok, "expected subprogram after overriding indicator");
            Skip_Balanced_To_Semicolon (Position);
         end if;
      elsif L0 = "procedure" or else L0 = "function" then
         Parse_Subprogram_Construct (Position, Result);
      elsif L0 = "type" then
         Add_Production (Result, Production_Type_Declaration, Tok, "type declaration");
         Advance (Position);
         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
           or else Current (Position).Kind = Token_String_Literal
         then
            Add_Production
              (Result, Production_Type_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
         end if;
         Parse_Defining_Name (Position, Result);
         if To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Type_Discriminant_Part, Current (Position),
               "type discriminant part");
            Parse_Discriminant_Part (Position, Result);
         end if;
         Skip_Balanced_To (Position, "is", ";");
         if Match_Keyword (Position, "is") then
            if Current_Lower (Position) = "tagged"
              and then To_String (Current (Position).Text) /= ";"
              and then Lookahead_Lower (Position, 1) = ";"
            then
               --  Ada incomplete type declarations include the tagged form:
               --     type T is tagged;
               --  Retain it as incomplete-type grammar instead of sending the
               --  lone tagged modifier through full type-definition recovery.
               Add_Production
                 (Result, Production_Incomplete_Type_Declaration, Tok,
                  "incomplete type declaration");
               Add_Production
                 (Result, Production_Tagged_Incomplete_Type_Declaration,
                  Current (Position), "tagged incomplete type declaration");
               Advance (Position);
               if To_String (Current (Position).Text) = ";" then
                  Add_Production
                    (Result, Production_Type_Declaration_Terminator,
                     Current (Position), "type declaration terminator");
                  Advance (Position);
               else
                  Add_Production
                    (Result,
                     Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
                     Current (Position),
                     "type declaration missing terminator recovery boundary");
               end if;
            else
               Parse_Type_Definition (Position, Result);
               if Current_Lower (Position) = "with" then
                  Add_Production
                    (Result, Production_Private_Type_Aspect_Specification,
                     Current (Position), "private type aspect placement");
                  Add_Production
                    (Result, Production_Private_Completion_Aspect_Specification,
                     Current (Position), "type/private-completion aspect placement");
                  Parse_Aspect_Specification (Position, Result);
               end if;

               if To_String (Current (Position).Text) = ";" then
                  Add_Production
                    (Result, Production_Type_Declaration_Terminator,
                     Current (Position), "type declaration terminator");
                  Advance (Position);
               else
                  Add_Production
                    (Result,
                     Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
                     Current (Position),
                     "type declaration missing terminator recovery boundary");
               end if;
            end if;
         else
            --  Ada also permits plain incomplete type declarations:
            --     type T;
            --     type T (D : Positive);
            --  Keep these explicit so outline/semantic recovery sees a real
            --  declaration node rather than only a generic type declaration
            --  followed by opaque semicolon recovery.
            Add_Production
              (Result, Production_Incomplete_Type_Declaration, Tok,
               "incomplete type declaration");
            Skip_Balanced_To (Position, ";");
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Type_Declaration_Terminator,
                  Current (Position), "type declaration terminator");
               Advance (Position);
            else
               Add_Production
                 (Result,
                  Production_Type_Declaration_Missing_Terminator_Recovery_Boundary,
                  Current (Position),
                  "type declaration missing terminator recovery boundary");
            end if;
         end if;
      elsif L0 = "subtype" then
         Add_Production (Result, Production_Subtype_Declaration, Tok, "subtype declaration");
         Advance (Position);
         if Current (Position).Kind = Token_Identifier
           or else Current (Position).Kind = Token_Keyword
         then
            Add_Production
              (Result, Production_Subtype_Defining_Name, Current (Position),
               To_String (Current (Position).Text));
         end if;
         Parse_Defining_Name (Position, Result);
         if Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Subtype_Declaration_Subtype_Indication,
               Current (Position), "subtype declaration subtype indication");
            Parse_Subtype_Indication (Position, Result);
         end if;
         if Current_Lower (Position) = "with" then
            Parse_Aspect_Specification (Position, Result);
         end if;

         if To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Subtype_Declaration_Terminator,
               Current (Position), "subtype declaration terminator");
            Advance (Position);
         else
            Add_Production
              (Result,
               Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary,
               Current (Position),
               "subtype declaration missing terminator recovery boundary");
         end if;
      elsif L0 = "task" then
         if L1 = "body" then
            Add_Production (Result, Production_Task_Body, Tok, "task body");
            Advance (Position); -- task
            Advance (Position); -- body
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Task_Body_Name, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "separate") then
               Add_Production (Result, Production_Task_Body_Stub, Tok, "task body stub");
               Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "task body stub kind keyword");
               Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
               Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Body_Aspect_Specification,
                     Current (Position), "body aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Body_Stub_Aspect_Specification);
            else
               Add_Task_Body_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
               Add_Production
                 (Result, Production_Task_Body_Aspect_Specification,
                  Current (Position), "task body aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Body_Aspect_Specification);
            end if;
         else
            Add_Production (Result, Production_Task_Declaration, Tok, "task declaration");
            Advance (Position); -- task
            if Current_Lower (Position) = "type" then
               Add_Production
                 (Result, Production_Task_Type_Declaration, Tok,
                  "task type declaration");
               Advance (Position);
            end if;
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Parse_Defining_Name (Position, Result);
            end if;
            if To_String (Current (Position).Text) = "(" then
               Parse_Discriminant_Part (Position, Result);
            end if;
            if Has_Token_Before_Semicolon (Position, "is") then
               Add_Production (Result, Production_Task_Definition, Tok, "task definition");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Task_Declaration_Aspect_Specification,
                     Current (Position), "task declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Concurrent_Type_Aspect_Specification);
               Add_Concurrent_Definition_Part_Productions
                 (Position, Result,
                  Production_Task_Definition_Public_Part,
                  Production_Task_Definition_Private_Part,
                  "task definition");
            else
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Task_Declaration_Aspect_Specification,
                     Current (Position), "task declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Concurrent_Type_Aspect_Specification);
            end if;
         end if;
      elsif L0 = "protected" then
         if L1 = "body" then
            Add_Production (Result, Production_Protected_Body, Tok, "protected body");
            Advance (Position); -- protected
            Advance (Position); -- body
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Protected_Body_Name, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "separate") then
               Add_Production (Result, Production_Protected_Body_Stub, Tok, "protected body stub");
               Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "protected body stub kind keyword");
               Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
               Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Body_Aspect_Specification,
                     Current (Position), "body aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Body_Stub_Aspect_Specification);
            else
               Add_Protected_Body_Part_Productions (Position, Result);
            if Has_Token_Before_Semicolon (Position, "with") then
               Add_Production
                 (Result, Production_Body_Aspect_Specification,
                  Current (Position), "body aspect placement");
               Add_Production
                 (Result, Production_Protected_Body_Aspect_Specification,
                  Current (Position), "protected body aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Body_Aspect_Specification);
            end if;
         else
            Add_Production (Result, Production_Protected_Declaration, Tok, "protected declaration");
            Advance (Position); -- protected
            if Current_Lower (Position) = "type" then
               Add_Production
                 (Result, Production_Protected_Type_Declaration, Tok,
                  "protected type declaration");
               Advance (Position);
            end if;
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Parse_Defining_Name (Position, Result);
            end if;
            if To_String (Current (Position).Text) = "(" then
               Parse_Discriminant_Part (Position, Result);
            end if;
            if Has_Token_Before_Semicolon (Position, "is") then
               Add_Production (Result, Production_Protected_Definition, Tok, "protected definition");
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Protected_Declaration_Aspect_Specification,
                     Current (Position), "protected declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
                 (Position, Result, "is", Production_Concurrent_Type_Aspect_Specification);
               Add_Concurrent_Definition_Part_Productions
                 (Position, Result,
                  Production_Protected_Definition_Public_Part,
                  Production_Protected_Definition_Private_Part,
                  "protected definition");
            else
               if Has_Token_Before_Semicolon (Position, "with") then
                  Add_Production
                    (Result, Production_Protected_Declaration_Aspect_Specification,
                     Current (Position), "protected declaration aspect placement");
               end if;
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Concurrent_Type_Aspect_Specification);
            end if;
         end if;
      elsif L0 = "entry" then
         if Has_Token_Before_Semicolon (Position, "separate")
           and then Has_Token_Before_Semicolon (Position, "is")
         then
            Add_Production (Result, Production_Entry_Body, Tok, "entry body");
            Add_Production (Result, Production_Entry_Body_Stub, Tok, "entry body stub");
            Add_Production (Result, Production_Body_Stub_Kind_Keyword, Tok, "entry body stub kind keyword");
            Add_Production (Result, Production_Body_Stub_Separate_Keyword, Tok, "body stub separate keyword");
            Add_Production (Result, Production_Body_Stub_Subunit_Link_Hint, Tok, "body stub subunit link hint");
         elsif Has_Token_Before_Semicolon (Position, "when")
           and then Has_Token_Before_Semicolon (Position, "is")
         then
            Add_Production (Result, Production_Entry_Body, Tok, "entry body");
            Add_Production (Result, Production_Entry_Barrier, Tok, "entry barrier");
         else
            Add_Production (Result, Production_Entry_Declaration, Tok, "entry declaration");
         end if;
         Advance (Position);
         if Current (Position).Kind = Token_Identifier or else Current (Position).Kind = Token_Keyword then
            Add_Production
              (Result, Production_Entry_Identifier, Current (Position),
               To_String (Current (Position).Text));
            Add_Production (Result, Production_Defining_Name, Current (Position), To_String (Current (Position).Text));
            Advance (Position);
         end if;
         Parse_Entry_Parenthesized_Parts (Position, Result, Tok);
         if Current_Lower (Position) = "is" then
            Add_Production
              (Result, Production_Entry_Body_Missing_Barrier_Recovery_Boundary,
               Current (Position), "entry body missing barrier recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected when barrier before entry body is");
         end if;
         if Current_Lower (Position) = "when" then
            Add_Production (Result, Production_Entry_Barrier, Current (Position), "entry barrier");
            Add_Production
              (Result, Production_Entry_Barrier_When_Keyword,
               Current (Position), "entry barrier when keyword");
            Advance (Position);
            if At_End (Position)
              or else Current_Lower (Position) = "is"
              or else Current_Lower (Position) = "with"
              or else Current_Lower (Position) = "begin"
              or else Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "then"
              or else To_String (Current (Position).Text) = ";"
            then
               Add_Production
                 (Result,
                  Production_Entry_Barrier_Missing_Condition_Recovery_Boundary,
                  Current (Position),
                  "entry barrier missing condition recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected entry barrier condition");
            else
               Add_Production
                 (Result, Production_Entry_Barrier_Condition,
                  Current (Position), "entry barrier condition");
               Parse_Expression (Position, Result);
            end if;
         end if;
         if Current_Lower (Position) = "with" then
            Add_Production
              (Result, Production_Entry_Aspect_Specification,
               Current (Position), "entry aspect placement");
            Parse_Aspect_Specification (Position, Result);
         end if;
         if Current_Lower (Position) = "is" then
            Advance (Position);
            if Current_Lower (Position) = "separate" then
               Advance (Position);
               if Current_Lower (Position) = "with" then
                  Add_Production
                    (Result, Production_Entry_Aspect_Specification,
                     Current (Position), "entry aspect placement");
               end if;
               --  Feed_Item body stubs share entry grammar before ``is`` but their
               --  trailing aspect belongs to the body-stub placement family.
               --  Retain that structural distinction for bounded parser-owned
               --  metadata; this is placement coverage, not entry-body legality
               --  checking.
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Body_Stub_Aspect_Specification);
            else
               Add_Entry_Body_Part_Productions (Position, Result);
               Parse_Attached_Aspect_Or_Semicolon
                 (Position, Result, Production_Entry_Aspect_Specification);
            end if;
         else
            --  Feed_Item declarations have their own terminator/recovery
            --  metadata so task/protected declaration scans can distinguish
            --  an in-progress entry specification from following declarations
            --  without relying on rendering or compiler feedback.
            Skip_Balanced_To (Position, "with", ";");
            if Current_Lower (Position) = "with" then
               Add_Production
                 (Result, Production_Entry_Aspect_Specification,
                  Current (Position), "entry aspect placement");
               Parse_Aspect_Specification (Position, Result);
            end if;
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Entry_Terminator,
                  Current (Position), "entry declaration terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Entry_Missing_Terminator_Recovery_Boundary,
                  Tok, "entry declaration missing terminator recovery boundary");
            end if;
         end if;
      elsif L0 = "parallel" then
         Add_Production (Result, Production_Parallel_Loop_Statement, Tok, "parallel loop statement");
         Add_Production
           (Result, Production_Parallel_Loop_Keyword, Tok,
            "parallel loop keyword");
         Advance (Position);
         if not At_End (Position)
           and then To_String (Current (Position).Text) = "("
         then
            Add_Production
              (Result, Production_Parallel_Loop_Chunk_Specification,
               Current (Position), "parallel loop chunk specification");
            declare
               Chunk_Pos : Cursor := Position;
            begin
               Advance (Chunk_Pos);
               if not At_End (Chunk_Pos)
                 and then To_String (Current (Chunk_Pos).Text) /= ")"
               then
                  Add_Production
                    (Result, Production_Parallel_Loop_Chunk_Expression,
                     Current (Chunk_Pos), "parallel loop chunk expression");
               end if;
            end;
            Parse_Association_List (Position, Result);
         end if;
         if Current_Lower (Position) = "for"
           or else Current_Lower (Position) = "while"
           or else Current_Lower (Position) = "loop"
         then
            Add_Production
              (Result, Production_Parallel_Loop_Iteration_Scheme,
               Current (Position), "parallel loop iteration scheme");
            Parse_Declaration_Or_Statement (Position, Result);
         else
            Add_Production
              (Result, Production_Parallel_Loop_Recovery_Boundary, Tok,
               "parallel loop recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected loop scheme after parallel");
            Skip_Balanced_To (Position, "loop", ";");
            if Match_Keyword (Position, "loop") then
               Add_Production
                 (Result, Production_Loop_Begin_Keyword, Tok,
                  "parallel loop begin keyword");
               Add_Production
                 (Result, Production_Loop_Statement_Sequence, Tok,
                  "parallel loop statements");
               Add_Production
                 (Result, Production_Statement_Sequence, Tok,
                  "parallel loop statements");
            end if;
         end if;
      elsif L0 = "for" then
         if Lookahead_Lower (Position, 2) = "in" or else Lookahead_Lower (Position, 3) = "in" then
            Add_Production (Result, Production_Loop_Statement, Tok, "for loop statement");
            Add_Production
              (Result, Production_For_Loop_Iteration_Scheme, Tok,
               "for loop iteration scheme");
            Add_Production (Result, Production_Loop_Parameter_Specification, Tok, "for loop parameter specification");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_For_Loop_Parameter, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Match_Keyword (Position, "in") then
               null;
            end if;
            if Current_Lower (Position) = "reverse" then
               Add_Production
                 (Result, Production_For_Loop_Reverse_Iteration,
                  Current (Position), "for loop reverse iteration");
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "when") then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
            end if;
            if not At_Loop_Domain_Reserved_Boundary (Position) then
               declare
                  Domain_Tok : constant Token_Info := Current (Position);
               begin
                  Add_Production
                    (Result, Production_For_Loop_Iteration_Domain, Domain_Tok,
                     "for loop iteration domain");
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Add_Production
                       (Result, Production_For_Loop_Range_Iteration, Domain_Tok,
                        "for loop range iteration");
                     Add_Production
                       (Result, Production_Range_Expression, Domain_Tok,
                        "for loop discrete range");
                     Parse_Expression (Position, Result);
                  end if;
               end;
            elsif not At_End (Position) then
               Add_Production
                 (Result, Production_For_Loop_Missing_Domain_Recovery_Boundary,
                  Tok, "for loop missing domain recovery boundary");
               Add_Production
                 (Result, Production_For_Loop_Domain_Reserved_Boundary_Recovery_Boundary,
                  Current (Position), "for loop domain reserved boundary recovery");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected iteration domain in for loop statement");
            end if;
            if Current_Lower (Position) = "when" then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
               Advance (Position);
               if At_Iterator_Filter_Condition_Boundary (Position) then
                  Add_Production
                    (Result,
                     Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary,
                     Current (Position),
                     "missing loop iterator filter condition");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected loop iterator filter condition");
               else
                  Add_Production
                    (Result, Production_Loop_Iterator_Filter_Condition,
                     Current (Position), "loop iterator filter condition");
                  Parse_Expression (Position, Result);
               end if;
            end if;
            if Match_Keyword (Position, "loop") then
               Add_Production
                 (Result, Production_Loop_Begin_Keyword, Tok,
                  "for loop begin keyword");
               Add_Production
                 (Result, Production_Loop_Statement_Sequence, Tok,
                  "for loop statements");
               Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
               if Current_Lower (Position) = "end"
                 and then Lookahead_Lower (Position, 1) = "loop"
               then
                  Add_Production
                    (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
                     Current (Position), "for loop missing statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected statement in for loop body");
               end if;
            else
               Add_Production
                 (Result, Production_For_Loop_Missing_Loop_Recovery_Boundary,
                  Tok, "for loop missing loop recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected loop in for loop statement");
               Skip_Balanced_To (Position, "loop", ";");
               if Match_Keyword (Position, "loop") then
                  Add_Production
                    (Result, Production_Loop_Begin_Keyword, Tok,
                     "for loop begin keyword");
                  Add_Production
                    (Result, Production_Loop_Statement_Sequence, Tok,
                     "for loop statements");
                  Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
               end if;
            end if;
         elsif Lookahead_Lower (Position, 2) = "of" or else Lookahead_Lower (Position, 3) = "of" then
            --  Ada iterator loops use ``for C of Container loop`` (and the
            --  reverse form) rather than a discrete loop parameter.  Keep the
            --  element name and iterable domain structural instead of skipping
            --  the entire iteration scheme to ``loop``.
            Add_Production (Result, Production_Loop_Statement, Tok, "iterator loop statement");
            Add_Production
              (Result, Production_Iterator_Loop_Iteration_Scheme, Tok,
               "iterator loop iteration scheme");
            Add_Production (Result, Production_Iterator_Specification, Tok, "iterator specification");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Iterator_Loop_Element, Current (Position),
                  To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
            end if;
            if Match_Keyword (Position, "of") then
               null;
            end if;
            if Current_Lower (Position) = "reverse" then
               Add_Production
                 (Result, Production_Iterator_Loop_Reverse_Iteration,
                  Current (Position), "iterator loop reverse iteration");
               Advance (Position);
            end if;
            if Has_Token_Before_Semicolon (Position, "when") then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
            end if;
            if not At_Loop_Domain_Reserved_Boundary (Position) then
               Add_Production
                 (Result, Production_Iterator_Loop_Domain, Current (Position),
                  "iterator loop domain");
               Parse_Expression (Position, Result);
            elsif not At_End (Position) then
               Add_Production
                 (Result, Production_Iterator_Loop_Missing_Domain_Recovery_Boundary,
                  Tok, "iterator loop missing domain recovery boundary");
               Add_Production
                 (Result, Production_Iterator_Loop_Domain_Reserved_Boundary_Recovery_Boundary,
                  Current (Position), "iterator loop domain reserved boundary recovery");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected iteration domain in iterator loop statement");
            end if;
            if Current_Lower (Position) = "when" then
               Add_Production
                 (Result, Production_Loop_Iterator_Filter, Current (Position),
                  "loop iterator filter");
               Advance (Position);
               if At_Iterator_Filter_Condition_Boundary (Position) then
                  Add_Production
                    (Result,
                     Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary,
                     Current (Position),
                     "missing loop iterator filter condition");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected loop iterator filter condition");
               else
                  Add_Production
                    (Result, Production_Loop_Iterator_Filter_Condition,
                     Current (Position), "loop iterator filter condition");
                  Parse_Expression (Position, Result);
               end if;
            end if;
            if Match_Keyword (Position, "loop") then
               Add_Production
                 (Result, Production_Loop_Begin_Keyword, Tok,
                  "iterator loop begin keyword");
               Add_Production
                 (Result, Production_Loop_Statement_Sequence, Tok,
                  "iterator loop statements");
               Add_Production (Result, Production_Statement_Sequence, Tok, "iterator loop statements");
               if Current_Lower (Position) = "end"
                 and then Lookahead_Lower (Position, 1) = "loop"
               then
                  Add_Production
                    (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
                     Current (Position), "iterator loop missing statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected statement in iterator loop body");
               end if;
            else
               Add_Production
                 (Result, Production_Iterator_Loop_Missing_Loop_Recovery_Boundary,
                  Tok, "iterator loop missing loop recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected loop in iterator statement");
               Skip_Balanced_To (Position, "loop", ";");
               if Match_Keyword (Position, "loop") then
                  Add_Production
                    (Result, Production_Loop_Begin_Keyword, Tok,
                     "iterator loop begin keyword");
                  Add_Production
                    (Result, Production_Loop_Statement_Sequence, Tok,
                     "iterator loop statements");
                  Add_Production (Result, Production_Statement_Sequence, Tok, "iterator loop statements");
               end if;
            end if;
         else
            Parse_Representation_Clause (Position, Result);
         end if;
      elsif L0 = "private" then
         Add_Production (Result, Production_Private_Part, Tok, "private");
         Advance (Position);
      elsif L0 = "with" then
         --  Ada aspect clauses are representation/operational items in
         --  declarative contexts.  Keep standalone ``with Aspect => ...;``
         --  clauses distinct from attached aspect specifications while
         --  reusing the aspect-association parser.
         Add_Production (Result, Production_Aspect_Clause, Tok, "aspect clause");
         Add_Production (Result, Production_Operational_Item, Tok, "operational item");
         Parse_Aspect_Specification (Position, Result);
         if To_String (Current (Position).Text) = ";" then
            Advance (Position);
         end if;
      elsif L0 = "if" then
         Add_Production (Result, Production_If_Statement, Tok, "if statement");
         Advance (Position);
         if Current_Lower (Position) = "then"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "end"
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_If_Statement_Missing_Condition_Recovery_Boundary,
               Current (Position), "if statement missing condition recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Current (Position), "if statement condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected condition in if statement");
         else
            if not At_End (Position) then
               Add_Production
                 (Result, Production_If_Statement_Condition,
                  Current (Position), "if statement condition");
            end if;
            Parse_Expression (Position, Result);
         end if;
         if Current_Lower (Position) = "then" then
            Add_Production
              (Result, Production_If_Statement_Then_Keyword,
               Current (Position), "if statement then keyword");
            Advance (Position);
            Add_Production
              (Result, Production_If_Statement_Then_Statements,
               Tok, "if statement then statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "then statements");
            if Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "end"
            then
               Add_Production
                 (Result, Production_If_Then_Missing_Statement_Recovery_Boundary,
                  Current (Position), "if then branch missing statement recovery boundary");
               Add_Production
                 (Result, Production_If_Statement_Recovery_Boundary,
                  Current (Position), "if then branch recovery boundary");
            end if;
         else
            Add_Production
              (Result, Production_If_Statement_Missing_Then_Recovery_Boundary,
               Tok, "if statement missing then recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Tok, "if statement recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected then in if statement");
         end if;
      elsif L0 = "elsif" then
         Add_Production (Result, Production_Elsif_Part, Tok, "elsif part");
         Add_Production
           (Result, Production_Elsif_Statement_Branch, Tok,
            "elsif statement branch");
         Advance (Position);
         if Current_Lower (Position) = "then"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "end"
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Elsif_Statement_Missing_Condition_Recovery_Boundary,
               Current (Position), "elsif statement missing condition recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Current (Position), "elsif condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected condition in elsif part");
         else
            if not At_End (Position) then
               Add_Production
                 (Result, Production_Elsif_Statement_Condition,
                  Current (Position), "elsif statement condition");
            end if;
            Parse_Expression (Position, Result);
         end if;
         if Current_Lower (Position) = "then" then
            Add_Production
              (Result, Production_Elsif_Statement_Then_Keyword,
               Current (Position), "elsif statement then keyword");
            Advance (Position);
            Add_Production
              (Result, Production_Elsif_Statement_Then_Statements,
               Tok, "elsif statement then statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "elsif statements");
            if Current_Lower (Position) = "elsif"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "end"
            then
               Add_Production
                 (Result, Production_Elsif_Missing_Statement_Recovery_Boundary,
                  Current (Position), "elsif branch missing statement recovery boundary");
               Add_Production
                 (Result, Production_If_Statement_Recovery_Boundary,
                  Current (Position), "elsif branch recovery boundary");
            end if;
         else
            Add_Production
              (Result, Production_Elsif_Statement_Missing_Then_Recovery_Boundary,
               Tok, "elsif statement missing then recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Tok, "elsif statement recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected then in elsif part");
         end if;
      elsif L0 = "else" then
         Add_Production (Result, Production_Else_Part, Tok, "else part");
         Add_Production
           (Result, Production_If_Statement_Else_Branch, Tok,
            "if statement else branch");
         if Is_In_Select_Context (Position) then
            Add_Production (Result, Production_Select_Else_Part, Tok, "select else part");
            Add_Production
              (Result, Production_Conditional_Entry_Call_Alternative, Tok,
               "conditional entry call else alternative");
            Add_Production
              (Result, Production_Select_Else_Statement_Sequence, Tok,
               "select else statements");
         end if;
         Add_Production
           (Result, Production_Else_Statement_Sequence,
            Tok, "else statement sequence");
         Add_Production (Result, Production_Statement_Sequence, Tok, "else statements");
         Advance (Position);
         if Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "terminate"
           or else (Current_Lower (Position) = "then"
                    and then Lookahead_Lower (Position, 1) = "abort")
         then
            Add_Production
              (Result, Production_Else_Missing_Statement_Recovery_Boundary,
               Current (Position), "else branch missing statement recovery boundary");
            Add_Production
              (Result, Production_If_Statement_Recovery_Boundary,
               Current (Position), "else branch recovery boundary");
            if Is_In_Select_Context (Position) then
               Add_Production
                 (Result, Production_Select_Else_Missing_Statement_Recovery_Boundary,
                  Current (Position),
                  "select else missing statement recovery boundary");
               Add_Production
                 (Result, Production_Select_Alternative_Recovery_Boundary,
                  Current (Position),
                  "select else recovery boundary");
            end if;
         end if;
      elsif L0 = "case" then
         Add_Production (Result, Production_Case_Statement, Tok, "case statement");
         Advance (Position);
         if At_Case_Statement_Selector_Reserved_Boundary (Position) then
            Add_Production
              (Result,
               Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary,
               Tok,
               "case statement selector reserved boundary recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected selector expression after case");
         else
            Add_Production
              (Result, Production_Case_Statement_Selector, Current (Position),
               "case statement selector");
            Parse_Expression (Position, Result);
         end if;
         if Current_Lower (Position) = "is" then
            Add_Production
              (Result, Production_Case_Statement_Is_Keyword,
               Current (Position), "case statement is keyword");
         end if;
         if not Match_Keyword (Position, "is") then
            Add_Production
              (Result, Production_Case_Statement_Missing_Is_Recovery_Boundary,
               Current (Position),
               "case statement missing is recovery boundary");
            Add_Production (Result, Production_Recovery_Point, Tok, "expected is in case statement");
         end if;
      elsif L0 = "when" then
         declare
            Is_Exception_Handler : Boolean := Is_In_Exception_Context (Position);
         begin
            Add_Production
              (Result, Production_Case_Alternative, Tok,
               "case or exception alternative");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              and then Lookahead_Lower (Position, 1) = ":"
            then
               --  Exception handlers have their own optional choice-parameter
               --  grammar before the exception choice list:
               --     when Error : Constraint_Error | Program_Error =>
               --  Keep this distinct from case alternatives so syntax-tree and
               --  semantic passes do not have to infer it from an opaque skip.
               Is_Exception_Handler := True;
               Add_Production
                 (Result, Production_Exception_Handler, Tok,
                  "exception handler");
               Add_Production
                 (Result, Production_Exception_Choice_Parameter,
                  Current (Position), To_String (Current (Position).Text));
               Add_Production
                 (Result, Production_Exception_Handler_Local_Name,
                  Current (Position), "exception handler local name");
               Add_Production
                 (Result, Production_Defining_Name, Current (Position),
                  To_String (Current (Position).Text));
               Advance (Position);
               if not Match_Symbol (Position, ":") then
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected : in exception choice parameter");
               end if;
               Add_Production
                 (Result, Production_Exception_Choice_List, Current (Position),
                  "exception choice list");
               loop
                  exit when At_End (Position);
                  exit when To_String (Current (Position).Text) = "=>";
                  exit when To_String (Current (Position).Text) = ";";
                  Add_Production
                    (Result, Production_Exception_Choice, Current (Position),
                     To_String (Current (Position).Text));
                  if Current_Lower (Position) = "others" then
                     Add_Production
                       (Result, Production_Exception_Others_Choice,
                        Current (Position), "exception others choice");
                     Advance (Position);
                  else
                     Add_Production
                       (Result, Production_Exception_Named_Choice,
                        Current (Position), "exception named choice");
                     if Lookahead_Lower (Position, 1) = "." then
                        Add_Production
                          (Result, Production_Exception_Selected_Choice,
                           Current (Position), "exception selected choice");
                     end if;
                     Parse_Primary (Position, Result);
                  end if;
                  if To_String (Current (Position).Text) = "|" then
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Exception_Choice_Separator,
                           Separator_Tok, "exception choice separator");
                        Advance (Position);
                        if At_End (Position)
                          or else To_String (Current (Position).Text) = "=>"
                          or else To_String (Current (Position).Text) = ";"
                          or else Current_Lower (Position) = "when"
                          or else Current_Lower (Position) = "exception"
                          or else Current_Lower (Position) = "end"
                        then
                           Add_Production
                             (Result,
                              Production_Exception_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok,
                              "exception choice separator missing following choice");
                           Add_Production
                             (Result, Production_Exception_Handler_Recovery_Boundary,
                              Separator_Tok,
                              "exception handler choice-list recovery boundary");
                           exit;
                        end if;
                     end;
                  else
                     exit;
                  end if;
               end loop;
            elsif Is_Exception_Handler then
               Add_Production
                 (Result, Production_Exception_Handler, Tok,
                  "exception handler");
               Add_Production
                 (Result, Production_Exception_Choice_List, Current (Position),
                  "exception choice list");
               loop
                  exit when At_End (Position);
                  exit when To_String (Current (Position).Text) = "=>";
                  exit when To_String (Current (Position).Text) = ";";
                  Add_Production
                    (Result, Production_Exception_Choice, Current (Position),
                     To_String (Current (Position).Text));
                  if Current_Lower (Position) = "others" then
                     Add_Production
                       (Result, Production_Exception_Others_Choice,
                        Current (Position), "exception others choice");
                     Advance (Position);
                  else
                     Add_Production
                       (Result, Production_Exception_Named_Choice,
                        Current (Position), "exception named choice");
                     if Lookahead_Lower (Position, 1) = "." then
                        Add_Production
                          (Result, Production_Exception_Selected_Choice,
                           Current (Position), "exception selected choice");
                     end if;
                     Parse_Primary (Position, Result);
                  end if;
                  if To_String (Current (Position).Text) = "|" then
                     declare
                        Separator_Tok : constant Token_Info := Current (Position);
                     begin
                        Add_Production
                          (Result, Production_Exception_Choice_Separator,
                           Separator_Tok, "exception choice separator");
                        Advance (Position);
                        if At_End (Position)
                          or else To_String (Current (Position).Text) = "=>"
                          or else To_String (Current (Position).Text) = ";"
                          or else Current_Lower (Position) = "when"
                          or else Current_Lower (Position) = "exception"
                          or else Current_Lower (Position) = "end"
                        then
                           Add_Production
                             (Result,
                              Production_Exception_Choice_Missing_Choice_Recovery_Boundary,
                              Separator_Tok,
                              "exception choice separator missing following choice");
                           Add_Production
                             (Result, Production_Exception_Handler_Recovery_Boundary,
                              Separator_Tok,
                              "exception handler choice-list recovery boundary");
                           exit;
                        end if;
                     end;
                  else
                     exit;
                  end if;
               end loop;
            else
               Add_Production
                 (Result, Production_Case_Choice_List, Current (Position),
                  "case statement choice list");
               declare
                  Probe : Cursor := Position;
               begin
                  while not At_End (Probe) loop
                     declare
                        T : constant String := To_String (Current (Probe).Text);
                        L : constant String := Current_Lower (Probe);
                     begin
                        exit when T = "=>" or else T = ";" or else L = "when" or else L = "end";
                        if L = "others" then
                           Add_Production
                             (Result, Production_Case_Others_Choice,
                              Current (Probe), "case others choice");
                        elsif T = "|" then
                           Add_Production
                             (Result, Production_Case_Choice_Separator,
                              Current (Probe), "case choice separator");
                           if Lookahead_Lower (Probe, 1) = "=>"
                             or else Lookahead_Lower (Probe, 1) = "when"
                             or else Lookahead_Lower (Probe, 1) = "end"
                             or else Lookahead_Lower (Probe, 1) = ";"
                           then
                              Add_Production
                                (Result,
                                 Production_Case_Choice_Missing_Choice_Recovery_Boundary,
                                 Current (Probe),
                                 "case choice separator missing following choice");
                              Add_Production
                                (Result, Production_Case_Alternative_Recovery_Boundary,
                                 Current (Probe),
                                 "case choice-list recovery boundary");
                           end if;
                        elsif T /= ".." then
                           Add_Production
                             (Result, Production_Case_Choice,
                              Current (Probe), "case choice");
                           if Lookahead_Lower (Probe, 1) = ".." then
                              Add_Production
                                (Result, Production_Case_Range_Choice,
                                 Current (Probe), "case range choice");
                           end if;
                        end if;
                        Advance (Probe);
                     end;
                  end loop;
               end;
               Parse_Discrete_Choice_List (Position, Result, "=>");
            end if;
            if To_String (Current (Position).Text) = "=>" then
               if Is_Exception_Handler then
                  Add_Production
                    (Result, Production_Exception_Choice_Arrow,
                     Current (Position), "exception choice arrow");
               else
                  Add_Production
                    (Result, Production_Case_Choice_Arrow,
                     Current (Position), "case choice arrow");
                  Add_Production
                    (Result, Production_Case_Alternative_Arrow,
                     Current (Position), "case alternative arrow");
               end if;
               Advance (Position);
               if Is_Exception_Handler then
                  Add_Production
                    (Result, Production_Exception_Handler_Statement_Sequence,
                     Tok, "exception handler statements");
                  if Current_Lower (Position) = "null" then
                     Add_Production
                       (Result, Production_Exception_Handler_Null_Statement,
                        Current (Position), "exception handler null statement");
                  elsif Current_Lower (Position) = "when"
                    or else Current_Lower (Position) = "exception"
                    or else Current_Lower (Position) = "end"
                    or else To_String (Current (Position).Text) = ";"
                  then
                     --  Keep empty or malformed exception-handler bodies local
                     --  to the current handler.  The specific missing-statement
                     --  marker lets language-model consumers distinguish
                     --  ``when X =>`` recovery from ordinary exception choice
                     --  parsing without consuming the next handler or the
                     --  enclosing body's end terminator.
                     Add_Production
                       (Result,
                        Production_Exception_Handler_Missing_Statement_Recovery_Boundary,
                        Current (Position),
                        "exception handler missing statement recovery boundary");
                     if Current_Lower (Position) = "end" then
                        Add_Production
                          (Result,
                           Production_Exception_Handler_End_Statement_Recovery_Boundary,
                           Current (Position),
                           "exception handler missing statement before end");
                     end if;
                     Add_Production
                       (Result, Production_Exception_Handler_Recovery_Boundary,
                        Current (Position), "exception handler empty or malformed statement sequence");
                  end if;
               else
                  Add_Production
                    (Result, Production_Case_Alternative_Statement_Sequence,
                     Tok, "case alternative statements");
                  if Current_Lower (Position) = "null" then
                     Add_Production
                       (Result, Production_Case_Alternative_Null_Statement,
                        Current (Position), "case alternative null statement");
                  elsif Current_Lower (Position) = "when"
                    or else Current_Lower (Position) = "end"
                    or else To_String (Current (Position).Text) = ";"
                  then
                     --  Keep empty or malformed case alternatives local to the
                     --  current alternative.  This structural recovery marker
                     --  lets outline/diagnostics/semantic-colouring consumers
                     --  distinguish ``when X =>`` from an ordinary nested
                     --  statement scan without consuming the next alternative
                     --  or the enclosing ``end case``.
                     Add_Production
                       (Result,
                        Production_Case_Alternative_Missing_Statement_Recovery_Boundary,
                        Current (Position),
                        "case alternative missing statement recovery boundary");
                     if Current_Lower (Position) = "end"
                       and then Lookahead_Lower (Position, 1) = "case"
                     then
                        Add_Production
                          (Result,
                           Production_Case_Alternative_End_Case_Statement_Recovery_Boundary,
                           Current (Position),
                           "case alternative missing statement before end case");
                     end if;
                     Add_Production
                       (Result, Production_Case_Alternative_Recovery_Boundary,
                        Current (Position),
                        "case alternative empty or malformed statement sequence");
                  end if;
               end if;
               Add_Production
                 (Result, Production_Statement_Sequence, Tok,
                  "alternative statements");
            else
               if Is_Exception_Handler then
                  Add_Production
                    (Result, Production_Exception_Handler_Missing_Arrow_Recovery_Boundary,
                     Tok, "exception handler missing arrow recovery boundary");
                  Add_Production
                    (Result, Production_Exception_Handler_Recovery_Boundary,
                     Tok, "exception handler recovery boundary");
               else
                  Add_Production
                    (Result, Production_Case_Alternative_Missing_Arrow_Recovery_Boundary,
                     Tok, "case alternative missing arrow recovery boundary");
                  Add_Production
                    (Result, Production_Case_Alternative_Recovery_Boundary,
                     Tok, "case alternative recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected => in alternative");
            end if;
         end;
      elsif L0 = "loop" then
         Add_Production (Result, Production_Loop_Statement, Tok, "loop statement");
         Add_Production
           (Result, Production_Loop_Begin_Keyword, Tok, "loop begin keyword");
         Add_Production
           (Result, Production_Loop_Statement_Sequence, Tok,
            "loop statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
         Advance (Position);
         if Current_Lower (Position) = "end"
           and then Lookahead_Lower (Position, 1) = "loop"
         then
            Add_Production
              (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
               Current (Position), "loop missing statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in loop body");
         end if;
      elsif L0 = "while" then
         Add_Production (Result, Production_Loop_Statement, Tok, "while loop statement");
         Add_Production
           (Result, Production_While_Loop_Keyword, Tok, "while loop keyword");
         Advance (Position);
         if Current_Lower (Position) = "loop"
           or else Current_Lower (Position) = "elsif"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "then"
           or else To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_While_Loop_Missing_Condition_Recovery_Boundary,
               Current (Position), "while loop missing condition recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected condition in while loop statement");
         else
            if not At_End (Position) then
               Add_Production
                 (Result, Production_While_Loop_Condition, Current (Position),
                  "while loop condition");
            end if;
            Parse_Expression (Position, Result);
         end if;
         if Match_Keyword (Position, "loop") then
            Add_Production
              (Result, Production_Loop_Begin_Keyword, Tok,
               "while loop begin keyword");
            Add_Production
              (Result, Production_Loop_Statement_Sequence, Tok,
               "while loop statements");
            Add_Production (Result, Production_Statement_Sequence, Tok, "loop statements");
              if Current_Lower (Position) = "end"
                and then Lookahead_Lower (Position, 1) = "loop"
              then
                 Add_Production
                   (Result, Production_Loop_Missing_Statement_Recovery_Boundary,
                    Current (Position), "while loop missing statement recovery boundary");
                 Add_Production
                   (Result, Production_Recovery_Point, Current (Position),
                    "expected statement in while loop body");
              end if;
         else
            Add_Production
              (Result, Production_While_Loop_Missing_Loop_Recovery_Boundary,
               Tok, "while loop missing loop recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected loop in while statement");
         end if;
      elsif L0 = "declare" then
         Add_Production (Result, Production_Block_Statement, Tok, "block statement");
         Add_Production (Result, Production_Declare_Block_Statement, Tok, "declare block statement");
         Add_Production
           (Result, Production_Block_Declare_Keyword, Tok,
            "block declare keyword");
         Add_Production
           (Result, Production_Block_Declarative_Part, Tok,
            "block declarative part");
         Add_Production
           (Result, Production_Declare_Block_Declarative_Item, Tok,
            "declare block declarative items");
         declare
            Probe : Cursor := Position;
         begin
            Advance (Probe);
            while not At_End (Probe) loop
               declare
                  L : constant String := Current_Lower (Probe);
                  T : constant String := To_String (Current (Probe).Text);
               begin
                  exit when L = "begin" or else L = "exception" or else L = "end";
                  if L = "pragma" or else L = "generic" or else L = "package"
                    or else L = "procedure" or else L = "function"
                    or else L = "type" or else L = "subtype"
                    or else L = "task" or else L = "protected"
                    or else L = "for" or else Current (Probe).Kind = Token_Identifier
                  then
                     Add_Production
                       (Result, Production_Block_Declarative_Item_Start,
                        Current (Probe), "block declarative item start");
                  end if;
                  if T = ";" then
                     null;
                  elsif L = "private" or else L = "is" then
                     Add_Production
                       (Result, Production_Block_Declarative_Item_Recovery_Boundary,
                        Current (Probe), "block declarative-item recovery boundary");
                  end if;
                  Advance (Probe);
               end;
            end loop;
            if not At_End (Probe) and then Current_Lower (Probe) = "begin" then
               Add_Production
                 (Result, Production_Block_Declarative_Begin_Boundary,
                  Current (Probe), "block declarative begin boundary");
            elsif not At_End (Probe) then
               Add_Production
                 (Result, Production_Block_Declarative_Item_Recovery_Boundary,
                  Current (Probe), "block declarative-item recovery boundary");
            end if;
         end;
         Advance (Position);
      elsif L0 = "begin" then
         Add_Production (Result, Production_Block_Statement, Tok, "block statement");
         Add_Production (Result, Production_Block_Begin_Part, Tok, "block begin part");
         Add_Production
           (Result, Production_Block_Declarative_Begin_Boundary, Tok,
            "block begin boundary");
         Add_Production
           (Result, Production_Block_Statement_Sequence, Tok,
            "block statement sequence");
         Add_Production (Result, Production_Statement_Sequence, Tok, "begin statements");
         Advance (Position);
         if Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Block_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "block missing statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in block statement sequence");
         end if;
      elsif L0 = "exception" then
         Add_Production (Result, Production_Exception_Handler, Tok, "exception part");
         Add_Production
           (Result, Production_Block_Exception_Keyword, Tok,
            "block exception keyword");
         Add_Production
           (Result, Production_Block_Exception_Part, Tok,
            "block exception part");
         Advance (Position);
      elsif L0 = "end" then
         if L1 = "if" then
            Add_Production (Result, Production_If_Statement_End_Keyword, Tok, "end if");
            Advance (Position);
            Advance (Position);
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_If_End_Terminator,
                  Current (Position), "if statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_If_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "if statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end if");
            end if;
         elsif L1 = "loop" then
            Add_Production (Result, Production_Loop_Statement, Tok, "end loop");
            Advance (Position);
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Loop_End_Name, Current (Position),
                  "loop end name");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Block_Recovery_Boundary, Tok,
                  "loop end recovery boundary");
            end if;
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Loop_End_Terminator,
                  Current (Position), "loop statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Loop_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "loop statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end loop");
            end if;
         elsif L1 = "case" then
            Add_Production
              (Result, Production_Case_Statement_End_Keyword, Tok,
               "end case");
            Advance (Position);
            Advance (Position);
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Case_End_Terminator,
                  Current (Position), "case statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Case_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "case statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end case");
            end if;
         elsif L1 = "select" then
            Add_Production
              (Result, Production_Select_Statement_End_Keyword, Tok,
               "end select");
            Advance (Position);
            Advance (Position);
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Select_End_Terminator,
                  Current (Position), "select statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Select_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "select statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end select");
            end if;
         else
            Add_Production (Result, Production_Block_Statement, Tok, "end block");
            Advance (Position);
            if Current (Position).Kind = Token_Identifier
              or else Current (Position).Kind = Token_Keyword
            then
               Add_Production
                 (Result, Production_Block_End_Name, Current (Position),
                  "block end name");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Block_Recovery_Boundary, Tok,
                  "block end recovery boundary");
            end if;
            if To_String (Current (Position).Text) = ";" then
               Add_Production
                 (Result, Production_Block_End_Terminator,
                  Current (Position), "block statement end terminator");
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Block_Missing_End_Terminator_Recovery_Boundary,
                  Tok, "block statement missing end terminator recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected ; after end block");
            end if;
         end if;
      elsif L0 = "select" then
         Add_Production (Result, Production_Select_Statement, Tok, "select statement");
         if Select_Has_Then_Abort (Position) then
            Add_Production
              (Result, Production_Asynchronous_Select_Statement, Tok,
               "asynchronous select statement");
            Add_Production
              (Result, Production_Asynchronous_Select_Triggering_Alternative,
               Tok, "asynchronous select triggering alternative");
         end if;
         Add_Production (Result, Production_Select_Alternative, Tok, "select alternative");
         Add_Production
           (Result, Production_Select_First_Alternative, Tok,
            "select first alternative");
         Advance (Position);
         Parse_Select_Guard (Position, Result, Tok);
         Add_Production
           (Result, Production_Select_Alternative_Statement_Sequence, Tok,
            "select alternative statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "select alternative statements");
         if Is_Select_Alternative_Statement_Boundary (Position) then
            Add_Production
              (Result, Production_Select_Alternative_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "select first alternative missing statement recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary,
               Current (Position),
               "select first alternative recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in select alternative");
         end if;
      elsif L0 = "or" then
         Add_Production (Result, Production_Select_Alternative, Tok, "select alternative");
         Add_Production (Result, Production_Select_Or_Alternative, Tok, "select or alternative");
         Advance (Position);
         Parse_Select_Guard (Position, Result, Tok);
         Add_Production
           (Result, Production_Select_Alternative_Statement_Sequence, Tok,
            "select alternative statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "select alternative statements");
         if Is_Select_Alternative_Statement_Boundary (Position) then
            Add_Production
              (Result, Production_Select_Alternative_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "select or alternative missing statement recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary,
               Current (Position),
               "select or alternative recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in select or alternative");
         end if;
      elsif L0 = "then" and then L1 = "abort" then
         Add_Production (Result, Production_Select_Alternative, Tok, "then abort alternative");
         Add_Production (Result, Production_Select_Then_Abort_Part, Tok, "select then abort part");
         Add_Production
           (Result, Production_Asynchronous_Select_Abortable_Part, Tok,
            "asynchronous select abortable part");
         Add_Production (Result, Production_Abortable_Part, Tok, "abortable part");
         Advance (Position);
         if Current_Lower (Position) = "abort" then
            Advance (Position);
         end if;
         Add_Production
           (Result, Production_Abortable_Statement_Sequence, Tok,
            "abortable statements");
         Add_Production (Result, Production_Statement_Sequence, Tok, "abortable statements");
         if Is_Select_Alternative_Statement_Boundary (Position) then
            Add_Production
              (Result, Production_Select_Abortable_Missing_Statement_Recovery_Boundary,
               Current (Position),
               "select abortable part missing statement recovery boundary");
            Add_Production
              (Result, Production_Select_Alternative_Recovery_Boundary,
               Current (Position),
               "select abortable part recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected statement in select abortable part");
         end if;
      elsif L0 = "terminate" then
         Add_Production (Result, Production_Select_Alternative, Tok, "terminate alternative");
         Add_Production
           (Result, Production_Select_Delay_Alternative, Tok,
            "select terminate/delay-family alternative");
         Add_Production
           (Result, Production_Select_Terminate_Alternative, Tok,
            "select terminate alternative");
         Add_Production (Result, Production_Terminate_Alternative, Tok, "terminate alternative");
         Add_Production (Result, Production_Null_Statement, Tok, "terminate");
         Advance (Position);
         if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Terminate_Terminator, Current (Position),
               "terminate alternative terminator");
            Advance (Position);
         else
            Add_Production
              (Result, Production_Terminate_Missing_Terminator_Recovery_Boundary,
               Tok, "terminate missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after terminate alternative");
         end if;
      elsif L0 = "accept" then
         Add_Production (Result, Production_Accept_Statement, Tok, "accept statement");
         if Is_In_Select_Context (Position) then
            Add_Production
              (Result, Production_Select_Accept_Alternative, Tok,
               "select accept alternative");
         end if;
         Advance (Position);
         if Current (Position).Kind = Token_Identifier or else Current (Position).Kind = Token_Keyword then
            Add_Production
              (Result, Production_Accept_Entry_Name, Current (Position),
               To_String (Current (Position).Text));
            Add_Production (Result, Production_Name, Current (Position), To_String (Current (Position).Text));
            Advance (Position);
         else
            --  Accept statements require an entry direct name.  Keep this
            --  recovery local to the accept statement so an in-progress
            --  ``accept ;`` or ``accept do`` edit does not borrow a later
            --  statement token as an entry name.  This is structural parser
            --  metadata only; tasking legality and profile conformance remain
            --  outside the token-cursor layer.
            Add_Production
              (Result, Production_Accept_Missing_Entry_Name_Recovery_Boundary,
               Tok, "accept statement missing entry name recovery boundary");
            Add_Production
              (Result, Production_Accept_Missing_End_Recovery_Boundary, Tok,
               "accept statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected entry name after accept");
         end if;
         if To_String (Current (Position).Text) = "(" then
            if not Parenthesized_Has_Top_Level_Token (Position, ":")
              and then To_String (Current (Position).Text) = "("
            then
               --  accept E (Index) (...) do uses an entry index expression
               --  before the optional accept parameter profile.
               Add_Production
                 (Result, Production_Accept_Entry_Index, Tok,
                  "accept entry index");
               Add_Production
                 (Result, Production_Accept_Entry_Index_Expression, Tok,
                  "accept entry index expression");
               Add_Production
                 (Result, Production_Entry_Index_Specification, Tok,
                  "accept entry index");
               Parse_Association_List (Position, Result);
               if To_String (Current (Position).Text) = "(" then
                  Add_Production
                    (Result, Production_Accept_Parameter_Profile,
                     Current (Position), "accept parameter profile");
                  Parse_Parameter_Profile (Position, Result);
               end if;
            else
               Add_Production
                 (Result, Production_Accept_Parameter_Profile,
                  Current (Position), "accept parameter profile");
               Parse_Parameter_Profile (Position, Result);
            end if;
         end if;
         if Match_Keyword (Position, "do") then
            Add_Production
              (Result, Production_Accept_Do_Part, Tok,
               "accept do part");
            Add_Production
              (Result, Production_Accept_Statement_Sequence, Tok,
               "accept statement sequence");
            Add_Production (Result, Production_Statement_Sequence, Tok, "accept statements");

            if not At_End (Position) then
               declare
                  BL0 : constant String := Current_Lower (Position);
                  BL1 : constant String := Lookahead_Lower (Position, 1);
               begin
                  if BL0 = "end"
                    or else BL0 = "or"
                    or else BL0 = "else"
                    or else BL0 = ";"
                    or else (BL0 = "then" and then BL1 = "abort")
                  then
                     Add_Production
                       (Result,
                        Production_Accept_Body_Missing_Statement_Recovery_Boundary,
                        Current (Position),
                        "accept body missing statement recovery boundary");
                     if BL0 = "end" then
                        Add_Production
                          (Result,
                           Production_Accept_Body_End_Statement_Recovery_Boundary,
                           Current (Position),
                           "accept body end statement recovery boundary");
                     end if;
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected statement in accept body");
                  end if;
               end;
            end if;

            declare
               Probe     : Cursor := Position;
               Found_End : Boolean := False;
            begin
               while not At_End (Probe) loop
                  declare
                     PL0 : constant String := Current_Lower (Probe);
                     PL1 : constant String := Lookahead_Lower (Probe, 1);
                  begin
                     if PL0 = "end"
                       and then PL1 /= "if"
                       and then PL1 /= "loop"
                       and then PL1 /= "case"
                       and then PL1 /= "select"
                       and then PL1 /= "record"
                     then
                        Add_Production
                          (Result, Production_Accept_End_Keyword,
                           Current (Probe), "accept end keyword");
                        Advance (Probe);
                        if Current (Probe).Kind = Token_Identifier
                          or else Current (Probe).Kind = Token_Keyword
                        then
                           Add_Production
                             (Result, Production_Accept_End_Name,
                              Current (Probe), "accept end name");
                           Advance (Probe);
                        end if;
                        if not At_End (Probe)
                          and then To_String (Current (Probe).Text) = ";"
                        then
                           Add_Production
                             (Result, Production_Accept_Terminator,
                              Current (Probe), "accept terminator");
                        else
                           Add_Production
                             (Result, Production_Accept_Missing_Terminator_Recovery_Boundary,
                              Current (Probe),
                              "accept missing terminator recovery boundary");
                           Add_Production
                             (Result, Production_Recovery_Point,
                              Current (Probe),
                              "expected semicolon after accept statement");
                        end if;
                        Found_End := True;
                        exit;
                     elsif PL0 = "or"
                       or else PL0 = "else"
                       or else (PL0 = "then" and then PL1 = "abort")
                       or else (PL0 = "end" and then PL1 = "select")
                     then
                        exit;
                     elsif PL0 = "requeue" then
                        declare
                           Statement_Position : Cursor := Probe;
                        begin
                           Parse_Declaration_Or_Statement
                             (Statement_Position, Result);
                        end;
                     end if;
                  end;
                  Advance (Probe);
               end loop;

               if not Found_End then
                  Add_Production
                    (Result, Production_Accept_Missing_End_Recovery_Boundary,
                     Tok, "accept missing end recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected end for accept statement do part");
               end if;
            end;
         end if;
      elsif L0 = "return" then
         Advance (Position);
         if Current (Position).Kind = Token_Identifier and then Lookahead_Lower (Position, 1) = ":" then
            --  Extended return statements contain a return-object declaration,
            --  not just an opaque header before ``do``.  Retain the defining
            --  identifier, subtype indication, and optional initializer so
            --  later syntax-tree/semantic passes can recover the same grammar
            --  shape as an ordinary object declaration without claiming
            --  compiler-grade return-object legality.
            Add_Production (Result, Production_Extended_Return_Statement, Tok, "extended return statement");
            Add_Production (Result, Production_Return_Object_Declaration, Current (Position), "return object declaration");
            Add_Production (Result, Production_Return_Object_Defining_Name, Current (Position), "return object defining name");
            Add_Production (Result, Production_Defining_Name, Current (Position), To_String (Current (Position).Text));
            Advance (Position);
            if not Match_Symbol (Position, ":") then
               Add_Production (Result, Production_Recovery_Point, Tok, "expected : in extended return object declaration");
            end if;
            if Current_Lower (Position) = "aliased" then
               Add_Production (Result, Production_Aliased_Part, Current (Position), "return object aliased part");
               Add_Production
                 (Result, Production_Return_Object_Aliased_Qualifier,
                  Current (Position), "return object aliased qualifier");
               Advance (Position);
            end if;
            if Current_Lower (Position) = "constant" then
               Add_Production
                 (Result, Production_Return_Object_Constant_Qualifier,
                  Current (Position), "return object constant qualifier");
               Advance (Position);
            end if;
            if not At_End (Position)
              and then Current_Lower (Position) /= "do"
              and then To_String (Current (Position).Text) /= ":="
              and then To_String (Current (Position).Text) /= ";"
            then
               if Current_Lower (Position) = "not" then
                  Add_Production
                    (Result, Production_Return_Object_Null_Exclusion,
                     Current (Position), "return object null exclusion");
               end if;
               if Current_Lower (Position) = "not"
                 or else Current_Lower (Position) = "access"
               then
                  Add_Production
                    (Result, Production_Return_Object_Access_Definition,
                     Current (Position), "return object access definition");
               end if;
               declare
                  Probe : Cursor := Position;
               begin
                  while not At_End (Probe) loop
                     exit when Current_Lower (Probe) = "do"
                       or else To_String (Current (Probe).Text) = ":="
                       or else To_String (Current (Probe).Text) = ";";
                     if To_String (Current (Probe).Text) = "("
                       or else Current_Lower (Probe) = "range"
                       or else Current_Lower (Probe) = "digits"
                       or else Current_Lower (Probe) = "delta"
                     then
                        Add_Production
                          (Result, Production_Return_Object_Constraint,
                           Current (Probe), "return object subtype constraint");
                        exit;
                     end if;
                     Advance (Probe);
                  end loop;
               end;
               Add_Production
                 (Result, Production_Return_Object_Subtype_Indication,
                  Current (Position), "return object subtype indication");
               Parse_Subtype_Indication (Position, Result);
            end if;
            if Match_Symbol (Position, ":=") then
               Add_Production (Result, Production_Extended_Return_Initializer, Tok, "extended return initializer");
               Add_Production (Result, Production_Return_Object_Initializer, Tok, "return object initializer");
               if Current_Lower (Position) = "do"
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "elsif"
                 or else Current_Lower (Position) = "exception"
                 or else Current_Lower (Position) = "then"
                 or else Current_Lower (Position) = "when"
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result,
                     Production_Extended_Return_Initializer_Reserved_Boundary_Recovery_Boundary,
                     Current (Position),
                     "extended return initializer reserved-boundary recovery boundary");
                  Add_Production
                    (Result, Production_Return_Recovery_Boundary, Current (Position),
                     "extended return initializer recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Current (Position),
                     "expected initializer expression before extended return boundary");
               else
                  Parse_Expression (Position, Result);
               end if;
            end if;
            Skip_Balanced_To (Position, "do", ";");
            if Match_Keyword (Position, "do") then
               Add_Production
                 (Result, Production_Extended_Return_Do_Keyword,
                  Tok, "extended return do keyword");
               Add_Production
                 (Result, Production_Extended_Return_Statement_Sequence,
                  Tok, "extended return statements");
               Add_Production (Result, Production_Statement_Sequence, Tok, "return statements");
               declare
                  Probe     : Cursor := Position;
                  Found_End : Boolean := False;
               begin
                  while not At_End (Probe) loop
                     if Current_Lower (Probe) = "end"
                       and then Lookahead_Lower (Probe, 1) = "return"
                     then
                        Add_Production
                          (Result, Production_Extended_Return_End_Return,
                           Current (Probe), "extended return end return");
                        declare
                           Terminator : Cursor := Probe;
                        begin
                           Advance (Terminator);
                           Advance (Terminator);
                           if not At_End (Terminator)
                             and then To_String (Current (Terminator).Text) = ";"
                           then
                              Add_Production
                                (Result, Production_Return_Terminator,
                                 Current (Terminator), "extended return terminator");
                           end if;
                        end;
                        Found_End := True;
                        exit;
                     elsif To_String (Current (Probe).Text) = ";"
                       and then Lookahead_Lower (Probe, 1) = "end"
                     then
                        --  Keep bounded scanning across the return do-part.
                        null;
                     end if;
                     Advance (Probe);
                  end loop;

                  if not Found_End then
                     Add_Production
                       (Result, Production_Extended_Return_Missing_End_Recovery_Boundary,
                        Tok, "extended return missing end recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Tok,
                        "expected end return for extended return statement");
                  end if;
               end;
            else
               Add_Production
                 (Result, Production_Extended_Return_Missing_Do_Recovery_Boundary, Tok,
                  "extended return missing do recovery boundary");
               Add_Production
                 (Result, Production_Return_Recovery_Boundary, Tok,
                  "extended return missing do recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected do in extended return statement");
            end if;
         else
            Add_Production (Result, Production_Return_Statement, Tok, "return statement");
            if not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
            then
               if Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "elsif"
                 or else Current_Lower (Position) = "exception"
                 or else Current_Lower (Position) = "then"
                 or else Current_Lower (Position) = "when"
               then
                  Add_Production
                    (Result, Production_Return_Reserved_Boundary_Recovery_Boundary,
                     Tok, "return expression reserved-boundary recovery boundary");
                  Add_Production
                    (Result, Production_Return_Recovery_Boundary, Tok,
                     "return statement recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected return expression before statement-sequence boundary");
               else
                  Add_Production
                    (Result, Production_Return_Expression, Current (Position),
                     "return expression");
                  Parse_Expression (Position, Result);
               end if;
            elsif At_End (Position) then
               Add_Production
                 (Result, Production_Return_Recovery_Boundary, Tok,
                  "return statement missing semicolon recovery boundary");
            end if;
            declare
               Probe : Cursor := Position;
            begin
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Return_Terminator,
                     Current (Position), "return terminator");
               else
                  Skip_Balanced_To_Semicolon (Probe);
                  if At_End (Probe)
                 or else At_End (Position)
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "elsif"
                 or else Current_Lower (Position) = "exception"
                  then
                     Add_Production
                       (Result, Production_Return_Missing_Terminator_Recovery_Boundary,
                        Tok, "return missing terminator recovery boundary");
                     Add_Production
                       (Result, Production_Return_Recovery_Boundary, Tok,
                        "return statement missing semicolon recovery boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Tok,
                        "expected semicolon after return statement");
                  end if;
               end if;
            end;
            if Current_Lower (Position) /= "end"
              and then Current_Lower (Position) /= "or"
              and then Current_Lower (Position) /= "else"
              and then Current_Lower (Position) /= "elsif"
              and then Current_Lower (Position) /= "exception"
              and then Current_Lower (Position) /= "then"
              and then Current_Lower (Position) /= "when"
            then
               Skip_Balanced_To_Semicolon (Position);
            end if;
         end if;
      elsif L0 = "raise" then
         Add_Production (Result, Production_Raise_Statement, Tok, "raise statement");
         Advance (Position);

         --  Ada raise statements have two shapes:
         --     raise;
         --     raise Exception_Name [with String_Expression];
         --  Earlier grammar always tried to parse an expression after
         --  ``raise``, so a bare re-raise treated the semicolon as an
         --  expression primary and the optional ``with`` message was lost to
         --  opaque semicolon recovery.  Keep both pieces structural without
         --  claiming exception legality or handler-placement validation.
         if At_End (Position) or else To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Reraise_Statement, Tok,
               "bare raise statement");
         else
            if Current_Lower (Position) = "with" then
               --  ``raise with Message`` is not a legal Ada raise-statement
               --  shape, but it is a common in-progress edit after typing
               --  the optional message introducer before the exception name.
               --  Keep the message keyword and payload recoverable without
               --  mis-tagging ``with`` as an exception name.
               Add_Production
                 (Result,
                  Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary,
                  Tok,
                  "raise statement missing exception name recovery boundary");
               Add_Production
                 (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
                  "raise statement missing exception name");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected exception name before raise with message");
            elsif Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
            then
               --  Reserved statement-sequence boundaries after ``raise`` are
               --  not exception names.  Keep this raise-specific so malformed
               --  edits such as ``raise else;`` do not seed a bogus exception
               --  target or semantic-colouring binding from the next construct.
               Add_Production
                 (Result,
                  Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary,
                  Tok,
                  "raise statement missing exception name recovery boundary");
               Add_Production
                 (Result, Production_Raise_Target_Reserved_Boundary_Recovery_Boundary,
                  Tok, "raise target reserved boundary recovery boundary");
               Add_Production
                 (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
                  "raise statement recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected exception name in raise statement");
            else
               Add_Production
                 (Result, Production_Raise_Statement_Target, Current (Position),
                  "raise statement target");
               Add_Production
                 (Result, Production_Raise_Exception_Name, Current (Position),
                  "raise statement exception name");
               Mark_Raise_Exception_Target_Shape
                 (Position, Result, Current (Position),
                  Production_Raise_Selected_Exception_Name,
                  Production_Raise_Statement_Recovery_Boundary,
                  "raise statement exception name");
               Parse_Expression (Position, Result);
            end if;
            if Current_Lower (Position) = "with" then
               Add_Production
                 (Result, Production_Raise_With_Message_Keyword, Current (Position),
                  "raise with keyword");
               Advance (Position);
               if At_End (Position)
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Raise_Message_Recovery_Boundary, Tok,
                     "raise statement missing message expression");
                  Add_Production
                    (Result, Production_Raise_Statement_Message_Recovery_Boundary, Tok,
                     "raise statement missing message expression");
                  Add_Production
                    (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
                     "raise statement missing message expression");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "raise statement missing message expression");
               elsif Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
                 or else Current_Lower (Position) = "then"
                 or else Current_Lower (Position) = "when"
                 or else Current_Lower (Position) = "do"
               then
                  --  Reserved statement-sequence boundaries after ``raise ...
                  --  with`` are not message expressions.  Keep the recovery
                  --  message-specific so semantic colouring and outline data
                  --  do not treat the next construct keyword as a string
                  --  expression while still preserving the broader raise
                  --  recovery metadata.
                  Add_Production
                    (Result, Production_Raise_Message_Recovery_Boundary, Tok,
                     "raise statement missing message expression");
                  Add_Production
                    (Result,
                     Production_Raise_Message_Reserved_Boundary_Recovery_Boundary,
                     Tok,
                     "raise message reserved boundary recovery boundary");
                  Add_Production
                    (Result, Production_Raise_Statement_Message_Recovery_Boundary, Tok,
                     "raise statement missing message expression");
                  Add_Production
                    (Result, Production_Raise_Statement_Recovery_Boundary, Tok,
                     "raise statement missing message expression");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "raise statement missing message expression");
               else
                  Add_Production
                    (Result, Production_Raise_With_Message, Current (Position),
                     "raise with message");
                  Add_Production
                    (Result, Production_Raise_Message_Expression, Current (Position),
                     "raise message expression");
                  Parse_Expression (Position, Result);
               end if;
            end if;
         end if;
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Raise_Terminator, Current (Position),
               "raise statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Raise_Missing_Terminator_Recovery_Boundary,
               Tok, "raise missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after raise statement");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif L0 = "null" then
         Add_Production (Result, Production_Null_Statement, Tok, "null statement");
         if Is_In_Select_Context (Position) then
            Add_Production
              (Result, Production_Select_Alternative_Null_Statement, Tok,
               "select alternative null statement");
         end if;
         Advance (Position);
         if not At_End (Position)
           and then To_String (Current (Position).Text) = ";"
         then
            Add_Production
              (Result, Production_Null_Statement_Terminator, Current (Position),
               "null statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Null_Missing_Terminator_Recovery_Boundary,
               Tok, "null missing terminator recovery boundary");
            if Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
            then
               Add_Production
                 (Result,
                  Production_Null_Reserved_Boundary_Recovery_Boundary,
                  Tok,
                  "null reserved boundary recovery boundary");
            end if;
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after null statement");
         end if;
         if Current_Lower (Position) /= "end"
           and then Current_Lower (Position) /= "or"
           and then Current_Lower (Position) /= "else"
           and then Current_Lower (Position) /= "exception"
           and then Current_Lower (Position) /= "then"
           and then Current_Lower (Position) /= "when"
         then
            Skip_Balanced_To_Semicolon (Position);
         end if;
      elsif L0 = "exit" then
         Add_Production (Result, Production_Exit_Statement, Tok, "exit statement");
         Advance (Position);
         if not At_End (Position)
           and then Current_Lower (Position) /= "when"
           and then To_String (Current (Position).Text) /= ";"
           and then
             (Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then")
         then
            Add_Production
              (Result, Production_Exit_Target_Reserved_Boundary_Recovery_Boundary,
               Tok, "exit target reserved-boundary recovery boundary");
            Add_Production
              (Result, Production_Exit_Recovery_Boundary, Tok,
               "exit statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "reserved boundary where exit loop name was expected");
         elsif not At_End (Position)
           and then Current_Lower (Position) /= "when"
           and then To_String (Current (Position).Text) /= ";"
         then
            Add_Production
              (Result, Production_Exit_Target, Current (Position),
               "exit target");
            Add_Production
              (Result, Production_Exit_Loop_Name, Current (Position),
               "exit loop name");
            Parse_Primary (Position, Result);
         end if;
         if Current_Lower (Position) = "when" then
            Add_Production
              (Result, Production_Exit_When_Keyword, Current (Position),
               "exit when keyword");
            Advance (Position);
            if At_End (Position)
              or else To_String (Current (Position).Text) = ";"
              or else Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
            then
               Add_Production
                 (Result, Production_Exit_When_Missing_Condition_Recovery_Boundary, Tok,
                  "exit when missing condition recovery boundary");
               Add_Production
                 (Result, Production_Exit_Recovery_Boundary, Tok,
                  "exit statement recovery boundary");
               if not At_End (Position)
                 and then To_String (Current (Position).Text) /= ";"
               then
                  Add_Production
                    (Result,
                     Production_Exit_When_Reserved_Boundary_Recovery_Boundary,
                     Tok, "exit when reserved-boundary recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "reserved boundary where exit when condition was expected");
               end if;
            else
               Add_Production
                 (Result, Production_Exit_When_Condition, Current (Position),
                  "exit when condition");
               Parse_Expression (Position, Result);
            end if;
         end if;
         if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Exit_Terminator, Current (Position),
               "exit statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Exit_Missing_Terminator_Recovery_Boundary,
               Tok, "exit missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after exit statement");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif L0 = "goto" then
         Add_Production (Result, Production_Goto_Statement, Tok, "goto statement");
         Advance (Position);
         if not At_End (Position)
           and then To_String (Current (Position).Text) /= ";"
           and then
             (Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when")
         then
            Add_Production
              (Result, Production_Goto_Missing_Target_Recovery_Boundary, Tok,
               "goto missing target recovery boundary");
            Add_Production
              (Result, Production_Goto_Target_Reserved_Boundary_Recovery_Boundary,
               Tok, "goto target reserved-boundary recovery boundary");
            Add_Production
              (Result, Production_Goto_Recovery_Boundary, Tok,
               "goto statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected label name in goto statement");
         elsif not At_End (Position) and then To_String (Current (Position).Text) /= ";" then
            Add_Production
              (Result, Production_Goto_Target, Current (Position),
               "goto target");
            Add_Production
              (Result, Production_Goto_Label_Name, Current (Position),
               "goto label name");
            if Current (Position).Kind = Token_Identifier then
               Advance (Position);
               if not At_End (Position)
                 and then To_String (Current (Position).Text) /= ";"
               then
                  --  Ada goto targets are label identifiers, not general
                  --  names.  Keep a bounded recovery marker if the source
                  --  continues as if a selected/indexed name were valid,
                  --  while still synchronizing at the statement terminator.
                  Add_Production
                    (Result, Production_Goto_Label_Recovery_Boundary,
                     Current (Position),
                     "goto label-name recovery boundary");
               end if;
            else
               Add_Production
                 (Result, Production_Goto_Label_Recovery_Boundary,
                  Current (Position),
                  "goto label-name recovery boundary");
            end if;
         else
            Add_Production
              (Result, Production_Goto_Missing_Target_Recovery_Boundary, Tok,
               "goto missing target recovery boundary");
            Add_Production
              (Result, Production_Goto_Recovery_Boundary, Tok,
               "goto statement recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected label name in goto statement");
         end if;
         if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Goto_Terminator, Current (Position),
               "goto statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Goto_Missing_Terminator_Recovery_Boundary,
               Tok, "goto missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after goto statement");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif L0 = "delay" then
         Add_Production (Result, Production_Delay_Statement, Tok, "delay statement");
         if Is_In_Select_Context (Position) then
            Add_Production
              (Result, Production_Select_Delay_Alternative, Tok,
               "select delay alternative");
            Add_Production
              (Result, Production_Timed_Entry_Call_Alternative, Tok,
               "timed entry call delay alternative");
            if Select_Has_Then_Abort (Position) then
               Add_Production
                 (Result, Production_Asynchronous_Select_Delay_Trigger, Tok,
                  "asynchronous select delay trigger");
            end if;
         end if;
         Advance (Position);
         if Current_Lower (Position) = "until" then
            if Is_In_Select_Context (Position) then
               Add_Production
                 (Result, Production_Select_Delay_Until_Alternative, Tok,
                  "select delay until alternative");
            end if;
            Add_Production
              (Result, Production_Delay_Mode_Keyword, Current (Position),
               "delay mode keyword");
            Add_Production
              (Result, Production_Delay_Until_Keyword, Current (Position),
               "delay until keyword");
            Add_Production
              (Result, Production_Delay_Until_Statement, Tok,
               "delay until statement");
            Advance (Position);
            if not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
              and then Current_Lower (Position) /= "end"
              and then Current_Lower (Position) /= "or"
              and then Current_Lower (Position) /= "else"
              and then Current_Lower (Position) /= "exception"
              and then Current_Lower (Position) /= "then"
              and then Current_Lower (Position) /= "when"
              and then Current_Lower (Position) /= "terminate"
              and then Current_Lower (Position) /= "abort"
            then
               Add_Production
                 (Result, Production_Delay_Until_Expression,
                  Current (Position), "delay until expression");
               if Lookahead_Lower (Position, 1) = "." then
                  Add_Production
                    (Result, Production_Delay_Selected_Time_Expression,
                     Current (Position), "delay selected time expression");
               elsif Lookahead_Lower (Position, 1) = "'" then
                  Add_Production
                    (Result, Production_Delay_Qualified_Time_Expression,
                     Current (Position), "delay qualified time expression");
               end if;
               Parse_Expression (Position, Result);
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Delay_Statement_Terminator,
                     Current (Position), "delay statement terminator");
               elsif At_End (Position)
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
               then
                  Add_Production
                    (Result, Production_Delay_Missing_Terminator_Recovery_Boundary,
                     Tok, "delay missing terminator recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected semicolon after delay statement");
               end if;
            else
               Add_Production
                 (Result, Production_Delay_Until_Missing_Expression_Recovery_Boundary, Tok,
                  "delay until missing expression recovery boundary");
               if not At_End (Position)
                 and then (Current_Lower (Position) = "then"
                           or else Current_Lower (Position) = "when"
                           or else Current_Lower (Position) = "terminate"
                           or else Current_Lower (Position) = "abort")
               then
                  Add_Production
                    (Result, Production_Delay_Reserved_Boundary_Recovery_Boundary, Tok,
                     "delay expression reserved boundary recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Delay_Recovery_Boundary, Tok,
                  "delay statement recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected expression after delay until");
            end if;
         else
            if Is_In_Select_Context (Position) then
               Add_Production
                 (Result, Production_Select_Delay_Relative_Alternative, Tok,
                  "select relative delay alternative");
            end if;
            Add_Production
              (Result, Production_Delay_Relative_Statement, Tok,
               "delay relative statement");
            if not At_End (Position)
              and then To_String (Current (Position).Text) /= ";"
              and then Current_Lower (Position) /= "end"
              and then Current_Lower (Position) /= "or"
              and then Current_Lower (Position) /= "else"
              and then Current_Lower (Position) /= "exception"
              and then Current_Lower (Position) /= "then"
              and then Current_Lower (Position) /= "when"
              and then Current_Lower (Position) /= "terminate"
              and then Current_Lower (Position) /= "abort"
            then
               Add_Production
                 (Result, Production_Delay_Relative_Expression,
                  Current (Position), "delay relative expression");
               if Lookahead_Lower (Position, 1) = "." then
                  Add_Production
                    (Result, Production_Delay_Selected_Time_Expression,
                     Current (Position), "delay selected time expression");
               elsif Lookahead_Lower (Position, 1) = "'" then
                  Add_Production
                    (Result, Production_Delay_Qualified_Time_Expression,
                     Current (Position), "delay qualified time expression");
               end if;
               Parse_Expression (Position, Result);
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Delay_Statement_Terminator,
                     Current (Position), "delay statement terminator");
               elsif At_End (Position)
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
               then
                  Add_Production
                    (Result, Production_Delay_Missing_Terminator_Recovery_Boundary,
                     Tok, "delay missing terminator recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected semicolon after delay statement");
               end if;
            else
               Add_Production
                 (Result, Production_Delay_Relative_Missing_Expression_Recovery_Boundary, Tok,
                  "delay relative missing expression recovery boundary");
               if not At_End (Position)
                 and then (Current_Lower (Position) = "then"
                           or else Current_Lower (Position) = "when"
                           or else Current_Lower (Position) = "terminate"
                           or else Current_Lower (Position) = "abort")
               then
                  Add_Production
                    (Result, Production_Delay_Reserved_Boundary_Recovery_Boundary, Tok,
                     "delay expression reserved boundary recovery boundary");
               end if;
               Add_Production
                 (Result, Production_Delay_Recovery_Boundary, Tok,
                  "delay statement recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected expression after delay");
            end if;
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif L0 = "requeue" then
         Add_Production (Result, Production_Requeue_Statement, Tok, "requeue statement");
         Advance (Position);
         if not At_End (Position) and then To_String (Current (Position).Text) /= ";" then
            if Current_Lower (Position) = "end"
              or else Current_Lower (Position) = "or"
              or else Current_Lower (Position) = "else"
              or else Current_Lower (Position) = "exception"
              or else Current_Lower (Position) = "then"
              or else Current_Lower (Position) = "when"
            then
               --  A reserved statement-sequence boundary after ``requeue`` is
               --  not an entry name target.  Keep this requeue-specific so
               --  malformed edits such as ``requeue else;`` do not fabricate
               --  a target from the next enclosing construct.
               Add_Production
                 (Result, Production_Requeue_Missing_Target_Recovery_Boundary, Tok,
                  "requeue missing target recovery boundary");
               Add_Production
                 (Result, Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary,
                  Tok, "requeue target reserved boundary recovery boundary");
               Add_Production
                 (Result, Production_Requeue_Target_Recovery_Boundary, Tok,
                  "requeue target recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected entry name in requeue statement");
            else
               Add_Production
                 (Result, Production_Requeue_Target, Current (Position),
                  "requeue target");
               if Lookahead_Lower (Position, 1) = "." then
                  Add_Production
                    (Result, Production_Requeue_Selected_Target, Current (Position),
                     "requeue selected target");
               end if;
               Add_Production
                 (Result, Production_Requeue_Entry_Name, Current (Position),
                  "requeue entry name");
               Parse_Visibility_Name
                 (Position, Result, Production_Name, "requeue entry name");
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = "("
               then
                  Add_Production
                    (Result, Production_Requeue_Indexed_Target, Current (Position),
                     "requeue indexed target");
                  Add_Production
                    (Result, Production_Indexed_Component, Current (Position),
                     "requeue indexed target");
                  Add_Production
                    (Result, Production_Requeue_Entry_Index, Current (Position),
                     "requeue entry index");
                  Add_Production
                    (Result, Production_Entry_Index_Specification, Current (Position),
                     "requeue entry index");
                  Parse_Association_List (Position, Result);
               end if;
            end if;
         else
            --  Requeue statements require an entry name target.  Keep this
            --  recovery target-specific so malformed or in-progress
            --  ``requeue ;`` edits do not reuse a later token as the target
            --  while still preserving the existing broader target recovery
            --  marker for older consumers.
            Add_Production
              (Result, Production_Requeue_Missing_Target_Recovery_Boundary, Tok,
               "requeue missing target recovery boundary");
            Add_Production
              (Result, Production_Requeue_Target_Recovery_Boundary, Tok,
               "requeue target recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected entry name in requeue statement");
         end if;
         if Current_Lower (Position) = "with" then
            if Lookahead_Lower (Position, 1) = "abort" then
               Add_Production
                 (Result, Production_Requeue_With_Abort, Current (Position),
                  "requeue with abort");
               Advance (Position);
               Advance (Position);
            else
               Add_Production
                 (Result, Production_Requeue_With_Missing_Abort_Recovery_Boundary,
                  Current (Position), "requeue with missing abort recovery boundary");
               Add_Production
                 (Result, Production_Recovery_Point, Current (Position),
                  "expected abort after with in requeue statement");
               Advance (Position);
            end if;
         end if;
         if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Requeue_Terminator, Current (Position),
               "requeue statement terminator");
         elsif At_End (Position)
           or else Current_Lower (Position) = "end"
           or else Current_Lower (Position) = "or"
           or else Current_Lower (Position) = "else"
           or else Current_Lower (Position) = "exception"
         then
            Add_Production
              (Result, Production_Requeue_Missing_Terminator_Recovery_Boundary,
               Tok, "requeue missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after requeue statement");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif L0 = "abort" then
         Add_Production (Result, Production_Abort_Statement, Tok, "abort statement");
         Advance (Position);
         if not At_End (Position) and then To_String (Current (Position).Text) /= ";" then
            Add_Production
              (Result, Production_Abort_Target_List, Current (Position),
               "abort target list");
            loop
               Add_Production
                 (Result, Production_Abort_Target, Current (Position),
                  "abort target");
               Add_Production
                 (Result, Production_Abort_Target_Name, Current (Position),
                  "abort task name");
               declare
                  Probe : Cursor := Position;
               begin
                  while not At_End (Probe) loop
                     exit when To_String (Current (Probe).Text) = ","
                       or else To_String (Current (Probe).Text) = ";";
                     if To_String (Current (Probe).Text) = "." then
                        Add_Production
                          (Result, Production_Abort_Selected_Target,
                           Current (Probe), "abort selected target");
                     elsif To_String (Current (Probe).Text) = "(" then
                        Add_Production
                          (Result, Production_Abort_Indexed_Target,
                           Current (Probe), "abort indexed target");
                     elsif Current_Lower (Probe) = "all" then
                        Add_Production
                          (Result, Production_Abort_Dereferenced_Target,
                           Current (Probe), "abort dereferenced target");
                     end if;
                     Advance (Probe);
                  end loop;
               end;
               Parse_Primary (Position, Result);
               exit when To_String (Current (Position).Text) /= ",";
               Add_Production
                 (Result, Production_Abort_Target_Separator, Current (Position),
                  "abort target separator");
               Advance (Position);
               if At_End (Position) or else To_String (Current (Position).Text) = ";" then
                  Add_Production
                    (Result, Production_Abort_Missing_Target_Recovery_Boundary, Tok,
                     "abort missing target recovery boundary");
                  Add_Production
                    (Result, Production_Abort_Recovery_Boundary, Tok,
                     "abort target list recovery boundary");
                  exit;
               elsif Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
                 or else Current_Lower (Position) = "then"
                 or else Current_Lower (Position) = "when"
               then
                  --  A reserved statement-sequence boundary after a comma is
                  --  not an abort target.  Keep this target-list-specific so
                  --  malformed edits such as ``abort Worker, else;`` do not
                  --  fabricate a target name from the next enclosing construct.
                  Add_Production
                    (Result, Production_Abort_Missing_Target_Recovery_Boundary, Tok,
                     "abort missing target recovery boundary");
                  Add_Production
                    (Result, Production_Abort_Target_Reserved_Boundary_Recovery_Boundary,
                     Tok, "abort target reserved boundary recovery boundary");
                  Add_Production
                    (Result, Production_Abort_Recovery_Boundary, Tok,
                     "abort target list recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected task name after comma in abort statement");
                  exit;
               end if;
            end loop;
         else
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected task name in abort statement");
            Add_Production
              (Result, Production_Abort_Missing_Target_Recovery_Boundary, Tok,
               "abort missing target recovery boundary");
            Add_Production
              (Result, Production_Abort_Recovery_Boundary, Tok,
               "abort statement recovery boundary");
         end if;
         if not At_End (Position) and then To_String (Current (Position).Text) = ";" then
            Add_Production
              (Result, Production_Abort_Terminator, Current (Position),
               "abort statement terminator");
         elsif At_End (Position) or else Current_Lower (Position) = "end" then
            Add_Production
              (Result, Production_Abort_Missing_Terminator_Recovery_Boundary,
               Tok, "abort missing terminator recovery boundary");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected semicolon after abort statement");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif Tok.Kind = Token_Identifier then
         declare
            Mark_Pos        : constant Natural := Mark (Position);
            Has_Actual_Part : constant Boolean :=
              Has_Token_Before_Semicolon (Position, "(");
            Name_End        : Natural := Mark_Pos;
            Had_Name_List   : Boolean := False;
         begin
            --  Parse the full Ada name prefix before classifying the construct.
            --  Earlier passes looked only at the first identifier, so legal
            --  statement targets such as Obj.Field := X, Arr (I) := X,
            --  Slice (A .. B) := X, Ptr.all := X, and Pkg.Op (X); were
            --  flattened into generic calls.  Keeping the name suffixes here
            --  moves the token-cursor layer closer to complete Ada statement
            --  grammar while still avoiding compiler-grade type/legality work.
            Parse_Primary (Position, Result);
            Name_End := Mark (Position);

            if Name_End = Mark_Pos + 1
              and then To_String (Current (Position).Text) = ","
            then
               --  Defining-name lists are shared by object, number, and
               --  exception declarations.  Retain each additional defining
               --  name instead of classifying grouped declarations such as
               --  ``A, B : exception;`` or ``X, Y : constant := 1;`` as
               --  call-shaped recovery.
               Had_Name_List := True;
               while Match_Symbol (Position, ",") loop
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
                        "expected defining name after comma");
                     exit;
                  end if;
               end loop;
            end if;

            if Match_Symbol (Position, ":") then
               if Name_End /= Mark_Pos + 1 and then not Had_Name_List then
                  --  A defining identifier cannot be a selected/indexed name.
                  --  Treat malformed/in-progress source as a recovery point
                  --  instead of fabricating an object declaration.
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "invalid defining name before :");
                  Skip_Balanced_To_Semicolon (Position);
               elsif Is_Statement_Starter_After_Label (Position) then
                  --  Statement identifiers are legal before any statement,
                  --  for example Named_Loop : for ..., Named_Block : declare,
                  --  and Named_Call : Pkg.Op (...);.  Previous passes treated
                  --  every identifier-colon form as a declaration and therefore
                  --  lost the following statement grammar.
                  Add_Production (Result, Production_Label, Tok, To_String (Tok.Text));
                  Add_Production (Result, Production_Label_Name, Tok, "statement identifier name");
                  Add_Production (Result, Production_Labeled_Statement, Tok, "statement identifier");
                  Add_Production (Result, Production_Statement_Identifier, Tok, "statement identifier");
                  if Current_Lower (Position) = "for"
                    or else Current_Lower (Position) = "while"
                    or else Current_Lower (Position) = "loop"
                  then
                     Add_Production
                       (Result, Production_Named_Loop_Statement, Tok,
                        "named loop statement");
                  elsif Current_Lower (Position) = "declare"
                    or else Current_Lower (Position) = "begin"
                  then
                     Add_Production
                       (Result, Production_Named_Block_Statement, Tok,
                        "named block statement");
                     Add_Production
                       (Result, Production_Block_Label_Name, Tok,
                        "block label name");
                  end if;
                  Parse_Declaration_Or_Statement (Position, Result);
               else
                  Add_Production (Result, Production_Defining_Name, Tok, To_String (Tok.Text));
                  if Current_Lower (Position) = "constant"
                    and then
                      (Lookahead_Lower (Position, 1) = ":="
                       or else Lookahead_Lower (Position, 1) = ";")
                  then
                     Add_Production (Result, Production_Number_Declaration, Tok, "number declaration");
                     Add_Production
                       (Result, Production_Object_Declaration_Recovery_Boundary,
                        Current (Position),
                        "object declaration missing subtype/access definition");
                     Add_Production
                       (Result, Production_Number_Defining_Name_List, Tok,
                        "number defining name list");
                     --  Number declarations share the identifier-list shape
                     --  with object and exception declarations, but they do
                     --  not have a subtype indication after the colon.  Retain
                     --  the individual defining identifiers and separators so
                     --  grouped named-number declarations are visible to local
                     --  diagnostics, Outline detail consumers, and syntax
                     --  colouring without treating them as object declarations.
                     declare
                        Colon_Index : constant Natural := Mark (Position) - 1;
                     begin
                        for Name_Index in Mark_Pos .. Colon_Index - 1 loop
                           declare
                              Name_Tok : constant Token_Info :=
                                Token_At (Position.Stream, Name_Index);
                              Name_Text : constant String :=
                                To_String (Name_Tok.Text);
                           begin
                              if Name_Tok.Kind = Token_Identifier
                                or else Name_Tok.Kind = Token_Keyword
                              then
                                 Add_Production
                                   (Result, Production_Number_Defining_Name,
                                    Name_Tok, Name_Text);
                              elsif Name_Text = "," then
                                 Add_Production
                                   (Result,
                                    Production_Number_Defining_Name_Separator,
                                    Name_Tok,
                                    "number defining name separator");
                              end if;
                           end;
                        end loop;
                     end;
                     Add_Production
                       (Result, Production_Number_Constant_Keyword,
                        Current (Position), "number declaration constant keyword");
                     Advance (Position);
                     if Match_Symbol (Position, ":=") then
                        if At_Number_Initialization_Reserved_Boundary (Position) then
                           Add_Production
                             (Result,
                              Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary,
                              Current (Position),
                              "number initialization reserved-boundary recovery boundary");
                           Add_Production
                             (Result,
                              Production_Number_Declaration_Recovery_Boundary,
                              Current (Position),
                              "number declaration missing initialization expression");
                           Add_Production
                             (Result, Production_Recovery_Point, Current (Position),
                              "expected number initialization expression before boundary");
                        else
                           Add_Production
                             (Result, Production_Number_Initialization_Expression,
                              Current (Position), "number initialization expression");
                           Parse_Expression (Position, Result);
                        end if;
                     else
                        Add_Production
                          (Result,
                           Production_Number_Declaration_Recovery_Boundary,
                           Current (Position),
                           "number declaration missing := initializer");
                     end if;
                     Parse_Number_Declaration_Aspect_Or_Terminator (Position, Result);
                  elsif Current_Lower (Position) = "exception" then
                     Add_Production (Result, Production_Exception_Declaration, Tok, "exception declaration");
                     Add_Production
                       (Result, Production_Exception_Defining_Name_List, Tok,
                        "exception defining name list");
                     Advance (Position);
                     if Current_Lower (Position) = "renames" then
                        Add_Production (Result, Production_Renaming_Declaration, Tok, "exception renames");
                        Add_Production
                          (Result, Production_Renaming_Defining_Name, Tok,
                           "exception renaming defining name");
                        Add_Production
                          (Result, Production_Exception_Renaming_Declaration, Tok,
                           "exception renaming declaration");
                        Parse_Renaming_Tail (Position, Result, Tok, "renamed exception");
                     else
                        Parse_Exception_Declaration_Aspect_Or_Terminator
                          (Position, Result);
                     end if;
                  else
                     Add_Production (Result, Production_Object_Declaration, Tok, "object declaration");
                     Add_Production
                       (Result, Production_Object_Defining_Name_List, Tok,
                        "object defining name list");
                     --  Retain the individual defining identifiers and comma
                     --  separators for object declarations.  The shared
                     --  identifier-colon classifier already validated that the
                     --  prefix is a defining_identifier_list; exposing the
                     --  per-name structure lets Outline/colouring and local
                     --  diagnostics distinguish grouped object declarations
                     --  from call-shaped names without doing semantic lookup.
                     declare
                        Colon_Index : constant Natural := Mark (Position) - 1;
                     begin
                        for Name_Index in Mark_Pos .. Colon_Index - 1 loop
                           declare
                              Name_Tok : constant Token_Info :=
                                Token_At (Position.Stream, Name_Index);
                              Name_Text : constant String :=
                                To_String (Name_Tok.Text);
                           begin
                              if Name_Tok.Kind = Token_Identifier
                                or else Name_Tok.Kind = Token_Keyword
                              then
                                 Add_Production
                                   (Result, Production_Object_Defining_Name,
                                    Name_Tok, Name_Text);
                              elsif Name_Text = "," then
                                 Add_Production
                                   (Result,
                                    Production_Object_Defining_Name_Separator,
                                    Name_Tok, "object defining name separator");
                              end if;
                           end;
                        end loop;
                     end;
                     --  Object declarations have their own qualifier sequence
                     --  after the colon:
                     --     defining_identifier_list : [aliased] [constant]
                     --       (subtype_indication | access_definition) [:= expr];
                     --  Earlier grammar only consumed a leading ``constant``.
                     --  Legal Ada forms such as ``Obj : aliased constant T := ...``
                     --  and ``Handle : aliased not null access T`` therefore
                     --  entered subtype parsing with ``aliased`` as if it were a
                     --  subtype mark.  Retain the qualifiers structurally before
                     --  handing the remaining subtype/access syntax to the shared
                     --  subtype parser.
                     if Current_Lower (Position) = "aliased" then
                        Add_Production
                          (Result, Production_Object_Qualifier,
                           Current (Position), "aliased object");
                        Add_Production
                          (Result, Production_Object_Aliased_Qualifier,
                           Current (Position), "aliased object qualifier");
                        Add_Production
                          (Result, Production_Aliased_Part,
                           Current (Position), "object aliased part");
                        Advance (Position);
                     end if;
                     if Current_Lower (Position) = "constant" then
                        Add_Production
                          (Result, Production_Object_Qualifier,
                           Current (Position), "constant object");
                        Add_Production
                          (Result, Production_Object_Constant_Qualifier,
                           Current (Position), "constant object qualifier");
                        Advance (Position);
                     end if;
                     if Current_Lower (Position) = "not"
                       or else Current_Lower (Position) = "access"
                     then
                        Add_Production
                          (Result, Production_Object_Access_Definition,
                           Current (Position), "object access definition");
                        Parse_Access_Type_Definition (Position, Result);
                        if Current_Lower (Position) = "with" then
                           Parse_Aspect_Specification (Position, Result);
                        end if;
                        if To_String (Current (Position).Text) = ";" then
                           Add_Production
                             (Result, Production_Object_Declaration_Terminator,
                              Current (Position),
                              "object declaration terminator");
                           Advance (Position);
                           return;
                        elsif To_String (Current (Position).Text) /= ":=" then
                           Add_Production
                             (Result,
                              Production_Object_Declaration_Missing_Terminator_Recovery_Boundary,
                              Current (Position),
                              "object declaration missing terminator recovery boundary");
                           return;
                        end if;
                     elsif To_String (Current (Position).Text) = ":="
                       or else To_String (Current (Position).Text) = ";"
                     then
                        Add_Production
                          (Result,
                           Production_Object_Declaration_Recovery_Boundary,
                           Current (Position),
                           "object declaration missing subtype/access definition");
                     elsif At_Object_Subtype_Reserved_Boundary (Position) then
                        Add_Production
                          (Result,
                           Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary,
                           Current (Position),
                           "object subtype indication reserved-boundary recovery boundary");
                        Add_Production
                          (Result,
                           Production_Object_Declaration_Recovery_Boundary,
                           Current (Position),
                           "object declaration missing subtype/access definition before boundary");
                        Add_Production
                          (Result, Production_Recovery_Point, Current (Position),
                           "expected object subtype/access definition before boundary");
                     end if;
                     if not At_End (Position)
                       and then not At_Object_Subtype_Reserved_Boundary (Position)
                       and then Current_Lower (Position) /= "renames"
                       and then Current_Lower (Position) /= "with"
                       and then To_String (Current (Position).Text) /= ";"
                       and then To_String (Current (Position).Text) /= ":="
                     then
                        Add_Production
                          (Result, Production_Object_Subtype_Indication,
                           Current (Position), "object subtype indication");
                        if Has_Token_Before_Semicolon (Position, "renames") then
                           Add_Production
                             (Result, Production_Renaming_Subtype_Indication,
                              Current (Position), "object renaming subtype indication");
                        end if;
                        Parse_Subtype_Indication (Position, Result);
                     end if;
                     if Current_Lower (Position) = "renames" then
                        Add_Production (Result, Production_Renaming_Declaration, Tok, "object renames");
                        Add_Production
                          (Result, Production_Renaming_Defining_Name, Tok,
                           "object renaming defining name");
                        Add_Production
                          (Result, Production_Object_Renaming_Declaration, Tok,
                           "object renaming declaration");
                        Parse_Renaming_Tail (Position, Result, Tok, "renamed object");
                     else
                        Skip_Balanced_To (Position, ":=", ";", "with");
                        if Match_Symbol (Position, ":=") then
                           Add_Production
                             (Result, Production_Object_Initialization_Expression,
                              Current (Position), "object initialization expression");
                           if At_End (Position)
                             or else To_String (Current (Position).Text) = ";"
                             or else To_String (Current (Position).Text) = ","
                             or else To_String (Current (Position).Text) = ")"
                             or else Current_Lower (Position) = "with"
                             or else Current_Lower (Position) = "end"
                             or else Current_Lower (Position) = "else"
                             or else Current_Lower (Position) = "elsif"
                             or else Current_Lower (Position) = "exception"
                             or else Current_Lower (Position) = "then"
                             or else Current_Lower (Position) = "when"
                             or else Current_Lower (Position) = "do"
                           then
                              Add_Production
                                (Result,
                                 Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary,
                                 Current (Position),
                                 "object initialization reserved-boundary recovery boundary");
                              Add_Production
                                (Result, Production_Object_Declaration_Recovery_Boundary,
                                 Current (Position),
                                 "object declaration initializer recovery boundary");
                              Add_Production
                                (Result, Production_Recovery_Point, Current (Position),
                                 "expected object initialization expression before boundary");
                           else
                              if To_String (Current (Position).Text) = "("
                                and then Lookahead_Lower (Position, 1) = "for"
                                and then Lookahead_Lower (Position, 2) /= "all"
                                and then Lookahead_Lower (Position, 2) /= "some"
                                and then not Has_Token_Between
                                  (Position.Stream, Mark_Pos, Mark (Position), "array")
                              then
                                 Add_Production
                                   (Result, Production_Quantified_Expression,
                                    Current (Position), "quantified expression");
                                 Add_Production
                                   (Result,
                                    Production_Quantified_Missing_Quantifier_Recovery_Boundary,
                                    Current (Position),
                                    "quantified expression missing quantifier recovery boundary");
                                 Add_Production
                                   (Result, Production_Quantified_Domain,
                                    Current (Position), "quantified domain");
                                 Add_Production
                                   (Result, Production_Quantified_Arrow,
                                    Current (Position), "quantified arrow");
                              end if;
                              Parse_Expression (Position, Result);
                           end if;
                        end if;

                        --  Ordinary object declarations now retain their own
                        --  completion metadata instead of relying only on the
                        --  shared attached-aspect/semicolon helper.  Keep this
                        --  shallow and parser-owned: it records the visible
                        --  terminator, or that a synchronization boundary was
                        --  reached without one, but it does not attempt object
                        --  subtype, aspect, or initialization legality.
                        if Current_Lower (Position) = "with" then
                           Parse_Aspect_Specification (Position, Result);
                        end if;

                        if To_String (Current (Position).Text) = ";" then
                           Add_Production
                             (Result, Production_Object_Declaration_Terminator,
                              Current (Position),
                              "object declaration terminator");
                           Advance (Position);
                        else
                           Add_Production
                             (Result,
                              Production_Object_Declaration_Missing_Terminator_Recovery_Boundary,
                              Current (Position),
                              "object declaration missing terminator recovery boundary");
                        end if;
                     end if;
                  end if;
               end if;
            elsif Match_Symbol (Position, ":=") then
               Add_Production (Result, Production_Assignment_Statement, Tok, "assignment");
               Add_Production
                 (Result, Production_Assignment_Target, Tok,
                  "assignment target name");
               Add_Statement_Name_Suffix_Productions
                 (Position, Result, Mark_Pos, Name_End,
                  For_Assignment => True);
               if At_End (Position)
                 or else To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result,
                     Production_Assignment_Missing_Expression_Recovery_Boundary,
                     Tok,
                     "assignment missing expression recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected expression after assignment statement");
               elsif Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
                 or else Current_Lower (Position) = "then"
                 or else Current_Lower (Position) = "when"
               then
                  Add_Production
                    (Result,
                     Production_Assignment_Missing_Expression_Recovery_Boundary,
                     Tok,
                     "assignment missing expression recovery boundary");
                  Add_Production
                    (Result,
                     Production_Assignment_Reserved_Boundary_Recovery_Boundary,
                     Tok,
                     "assignment reserved boundary recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected expression after assignment statement");
               else
                  Add_Production
                    (Result, Production_Assignment_Expression,
                     Current (Position), "assignment expression");
                  Parse_Expression (Position, Result);
               end if;
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Assignment_Terminator,
                     Current (Position), "assignment statement terminator");
               elsif At_End (Position)
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
               then
                  Add_Production
                    (Result,
                     Production_Assignment_Missing_Terminator_Recovery_Boundary,
                     Tok,
                     "assignment missing terminator recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected semicolon after assignment statement");
               end if;
               Skip_Balanced_To_Semicolon (Position);
            else
               Add_Production (Result, Production_Call_Statement, Tok, "call");
               Add_Production
                 (Result, Production_Call_Target, Tok, "call target name");
               Add_Statement_Name_Suffix_Productions
                 (Position, Result, Mark_Pos, Name_End,
                  For_Assignment => False);
               if To_String (Current (Position).Text) /= ";" then
                  Add_Production
                    (Result, Production_Assignment_Target_Recovery_Boundary,
                     Current (Position),
                     "possible missing := after statement target");
               end if;
               if Has_Actual_Part then
                  Add_Production
                    (Result, Production_Call_Actual_Part, Tok,
                     "call actual part");
               end if;
               if not At_End (Position)
                 and then To_String (Current (Position).Text) = ";"
               then
                  Add_Production
                    (Result, Production_Call_Terminator, Current (Position),
                     "call statement terminator");
               elsif At_End (Position)
                 or else Current_Lower (Position) = "end"
                 or else Current_Lower (Position) = "or"
                 or else Current_Lower (Position) = "else"
                 or else Current_Lower (Position) = "exception"
               then
                  Add_Production
                    (Result,
                     Production_Call_Missing_Terminator_Recovery_Boundary,
                     Tok,
                     "call missing terminator recovery boundary");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected semicolon after call statement");
               end if;
               if Name_End /= Mark_Pos + 1 or else Has_Actual_Part then
                  Add_Production
                    (Result, Production_Entry_Call_Statement, Tok,
                     "entry or call with name suffix/actual part");
                  Add_Production
                    (Result, Production_Entry_Call_Target, Tok,
                     "entry or call target name");
                  if Name_End /= Mark_Pos + 1 then
                     Add_Production
                       (Result, Production_Entry_Call_Selected_Target, Tok,
                        "selected entry call target");
                  end if;
                  Add_Production
                    (Result, Production_Entry_Call_Entry_Name, Tok,
                     "entry call entry name");
                  if Name_End /= Mark_Pos + 1 then
                     Add_Production
                       (Result, Production_Entry_Call_Selected_Entry_Name, Tok,
                        "selected entry call entry name");
                  end if;
                  if Is_In_Select_Context (Position) then
                     Add_Production
                       (Result, Production_Select_Entry_Call_Alternative, Tok,
                        "select entry call alternative");
                     if Select_Has_Delay_Alternative (Position) then
                        Add_Production
                          (Result, Production_Timed_Entry_Call_Statement, Tok,
                           "timed entry call statement");
                        Add_Production
                          (Result, Production_Timed_Entry_Call_Entry_Call_Part, Tok,
                           "timed entry call entry-call part");
                     end if;
                     if Select_Has_Else_Alternative (Position) then
                        Add_Production
                          (Result, Production_Conditional_Entry_Call_Statement, Tok,
                           "conditional entry call statement");
                        Add_Production
                          (Result, Production_Conditional_Entry_Call_Entry_Call_Part, Tok,
                           "conditional entry call entry-call part");
                     end if;
                  end if;
                  if Has_Actual_Part then
                     Add_Production
                       (Result, Production_Entry_Call_Actual_Part, Tok,
                        "entry or call actual part");
                     if Name_End /= Mark_Pos + 1 then
                        Add_Production
                          (Result, Production_Entry_Call_Index, Tok,
                           "entry call index or actual selector");
                        Add_Production
                          (Result, Production_Entry_Call_Family_Index, Tok,
                           "entry family index in call");
                     end if;
                  end if;
               end if;
               Skip_Balanced_To_Semicolon (Position);
            end if;
         end;
      else
         Add_Production (Result, Production_Recovery_Point, Tok, "unrecognized token");
         Advance (Position);
      end if;
   end Parse_Declaration_Or_Statement;

   function Parse (Text : String) return Grammar_Result is
      Result : Grammar_Result;
      Stream : constant Token_Stream := Tokenize (Text);
      Pos    : Cursor := First (Stream);
   begin
      Add_Production (Result, Production_Compilation_Unit, Current (Pos), "compilation unit");
      while not At_End (Pos) loop
         Parse_Declaration_Or_Statement (Pos, Result);
      end loop;
      return Result;
   end Parse;

   function Production_Count (Result : Grammar_Result) return Natural is
   begin
      return Natural (Result.Productions.Length);
   end Production_Count;

   function Production_At
     (Result : Grammar_Result;
      Index  : Positive) return Production_Info is
   begin
      if Index > Natural (Result.Productions.Length) then
         return (Kind => Production_Recovery_Point, Line => 1, Column => 1,
                 Label => Null_Unbounded_String);
      end if;
      return Result.Productions (Index);
   end Production_At;

   function Has_Production
     (Result : Grammar_Result;
      Kind   : Production_Kind) return Boolean is
   begin
      for Item of Result.Productions loop
         if Item.Kind = Kind then
            return True;
         end if;
      end loop;
      return False;
   end Has_Production;

end Editor.Ada_Token_Cursor;
