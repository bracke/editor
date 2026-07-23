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

package body Editor.Ada_Token_Cursor.Parsing_Phases_Engine is

   pragma Suppress (Overflow_Check);
   use Editor.Ada_Token_Cursor.Aspect_Parsing;
   use Editor.Ada_Token_Cursor.Range_Structure_Helpers;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

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

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   function Match_Keyword
     (Position : in out Cursor; Keyword : String) return Boolean
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Match_Keyword;

   function Match_Symbol
     (Position : in out Cursor; Symbol : String) return Boolean
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Match_Symbol;

   function Lookahead_Lower
     (Position : Cursor; Offset : Natural) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Lower;

   function Lookahead_Kind
     (Position : Cursor; Offset : Natural) return Token_Kind
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Lookahead_Kind;

   function Current_Lower
     (Position : Cursor) return String
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Current_Lower;

   function Is_Statement_Tail_Boundary
     (Position : Cursor) return Boolean is
      L : constant String := Current_Lower (Position);
   begin
      return L = "end"
        or else L = "or"
        or else L = "else"
        or else L = "exception";
   end Is_Statement_Tail_Boundary;

   function Is_Statement_Control_Boundary
     (Position : Cursor) return Boolean is
      L : constant String := Current_Lower (Position);
   begin
      return Is_Statement_Tail_Boundary (Position)
        or else L = "then"
        or else L = "when";
   end Is_Statement_Control_Boundary;

   function Is_Statement_Transfer_Boundary
     (Position : Cursor) return Boolean is
      L : constant String := Current_Lower (Position);
   begin
      return Is_Statement_Control_Boundary (Position)
        or else L = "do"
        or else L = "terminate"
        or else L = "abort";
   end Is_Statement_Transfer_Boundary;

   function Is_Statement_Delay_Reserved_Boundary
     (Position : Cursor) return Boolean is
      L : constant String := Current_Lower (Position);
   begin
      return L = "then"
        or else L = "when"
        or else L = "terminate"
        or else L = "abort";
   end Is_Statement_Delay_Reserved_Boundary;

   procedure Skip_Balanced_To_Semicolon
     (Position : in out Cursor)
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Skip_Balanced_To_Semicolon;

   procedure Advance_Through_Keyword
     (Position : in out Cursor; Keyword : String)
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Advance_Through_Keyword;

   function Has_Token_Before_Semicolon
     (Position : Cursor; Text : String) return Boolean
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Has_Token_Before_Semicolon;

   function Has_Token_Between
     (Stream : Token_Stream;
      First  : Natural;
      Last   : Natural;
      Text   : String) return Boolean
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Has_Token_Between;

   procedure Skip_Balanced_To
     (Position : in out Cursor;
      Stop_1   : String;
      Stop_2   : String := "";
      Stop_3   : String := "")
     renames Editor.Ada_Token_Cursor.Navigation_Helpers.Skip_Balanced_To;

   function Is_Contract_Aspect_Mark
     (Name : String) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.Is_Contract_Aspect_Mark;

   function Is_Classwide_Contract_Mark
     (Position    : Cursor;
      Aspect_Name : String) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.Is_Classwide_Contract_Mark;

   function Has_Contract_Aspect_Before_Stop
     (Position     : Cursor;
      Stop_Keyword : String) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.Has_Contract_Aspect_Before_Stop;

   function At_Profile_Item_End
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Profile_Item_End;

   function Access_Subprogram_Result_Has_Constraint
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.Access_Subprogram_Result_Has_Constraint;

   function At_Component_Default_Reserved_Boundary
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Component_Default_Reserved_Boundary;

   function At_Profile_Default_Reserved_Boundary
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Profile_Default_Reserved_Boundary;

   function At_Number_Initialization_Reserved_Boundary
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Number_Initialization_Reserved_Boundary;

   function At_Object_Subtype_Reserved_Boundary
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Contracts.At_Object_Subtype_Reserved_Boundary;



   procedure Parse_Factor
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Factor;

   procedure Parse_Term
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Term;

   procedure Parse_Simple_Expression
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Simple_Expression;

   procedure Parse_Relation
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Relation;

   procedure Parse_Expression
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Expression;

   procedure Parse_Discrete_Choice_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Discrete_Choice_List;

   procedure Parse_Select_Guard
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Anchor   : Token_Info)
     renames Editor.Ada_Token_Cursor.Expression_Parsing.Parse_Select_Guard;

   procedure Parse_Subtype_Mark
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Subtype_Mark;
   procedure Parse_Defining_Program_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Subprogram_Construct
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Record_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Representation_Parsing.Parse_Record_Representation_Clause;
   procedure Parse_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Representation_Parsing.Parse_Representation_Clause;
   procedure Parse_Subprogram_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Subprogram_Declaration_Aspect_Or_Terminator;

   procedure Parse_Generic_Formal_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Generic_Formal_Parsing.Parse_Generic_Formal_Declaration_Aspect_Or_Terminator;

   procedure Parse_Generic_Formal_Object_Declaration
     (Position     : in out Cursor;
      Result       : in out Grammar_Result;
      Leading_With : Boolean := False)
     renames Editor.Ada_Token_Cursor.Generic_Formal_Parsing.Parse_Generic_Formal_Object_Declaration;

   procedure Parse_Formal_Package_Actual_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Generic_Formal_Parsing.Parse_Formal_Package_Actual_Part;

   function Starts_Strong_Package_Declarative_Item
     (Position : Cursor) return Boolean;

   procedure Parse_Attached_Aspect_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Context  : Production_Kind)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Attached_Aspect_Or_Semicolon;

   procedure Parse_Number_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Number_Declaration_Aspect_Or_Terminator;

   procedure Parse_Exception_Declaration_Aspect_Or_Terminator
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Exception_Declaration_Aspect_Or_Terminator;

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Keyword  : String)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Attached_Aspect_Before_Keyword_Or_Semicolon;

   procedure Parse_Attached_Aspect_Before_Keyword_Or_Semicolon
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Keyword  : String;
      Context  : Production_Kind)
     renames Editor.Ada_Token_Cursor.Aspect_Parsing.Parse_Attached_Aspect_Before_Keyword_Or_Semicolon;

   function Has_Top_Level_With_Before_Association_End
     (Position : Cursor) return Boolean;

   function Has_Top_Level_With_Delta_Before_Association_End
     (Position : Cursor) return Boolean;

   procedure Parse_Component_Association_Item
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info);

   procedure Parse_Defining_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Defining_Name_List;

   procedure Parse_Profile_Default
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Profile_Default;

   procedure Parse_Parameter_Specification
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Parameter_Specification;

   procedure Parse_Parameter_Profile
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Parameter_Profile;


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
      Result   : in out Grammar_Result) is separate;
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
      Result   : in out Grammar_Result) is separate;
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
      Label    : String)
     renames Editor.Ada_Token_Cursor.Context_Clause_Parsing.Parse_Visibility_Name;

   procedure Parse_Visibility_Name_List
     (Position  : in out Cursor;
      Result    : in out Grammar_Result;
      List_Kind : Production_Kind;
      Item_Kind : Production_Kind;
      Label     : String)
     renames Editor.Ada_Token_Cursor.Context_Clause_Parsing.Parse_Visibility_Name_List;

   procedure Parse_Use_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Context_Clause_Parsing.Parse_Use_Clause;

   procedure Parse_Context_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Context_Clause_Parsing.Parse_Context_Clause;

   procedure Parse_Association_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Qualified_Expression_Operand : Boolean := False)
     renames Editor.Ada_Token_Cursor.Aggregate_Parsing.Parse_Association_List;

   procedure Add_Statement_Name_Suffix_Productions
     (Position       : Cursor;
      Result         : in out Grammar_Result;
      Start_At       : Natural;
      End_At         : Natural;
      For_Assignment : Boolean)
     renames Editor.Ada_Token_Cursor.Entry_Parsing.Add_Statement_Name_Suffix_Productions;

   procedure Parse_Statement_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result);
   procedure Parse_Accept_Return_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Conditional_Statement_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Declaration_Or_Statement
     (Position : in out Cursor;
      Result   : in out Grammar_Result);


   function At_Iterator_Filter_Condition_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Iterator_Filter_Condition_Boundary (Position);
   end At_Iterator_Filter_Condition_Boundary;



   function At_Case_Statement_Selector_Reserved_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Case_Statement_Selector_Reserved_Boundary (Position);
   end At_Case_Statement_Selector_Reserved_Boundary;


   function At_Loop_Domain_Reserved_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Loop_Domain_Reserved_Boundary (Position);
   end At_Loop_Domain_Reserved_Boundary;


   function At_Iterated_Component_Expression_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Iterated_Component_Expression_Boundary (Position);
   end At_Iterated_Component_Expression_Boundary;

   function At_Aggregate_Component_Expression_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Aggregate_Component_Expression_Boundary (Position);
   end At_Aggregate_Component_Expression_Boundary;


   function At_Conditional_Expression_Dependent_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Conditional_Expression_Dependent_Boundary
        (Position);
   end At_Conditional_Expression_Dependent_Boundary;


   function At_Case_Expression_Selector_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Case_Expression_Selector_Boundary (Position);
   end At_Case_Expression_Selector_Boundary;


   function At_Quantified_Predicate_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Quantified_Predicate_Boundary (Position);
   end At_Quantified_Predicate_Boundary;

   function At_Declare_Expression_Body_Boundary
     (Position : Cursor) return Boolean is
   begin
      return Range_Structure_Helpers.At_Declare_Expression_Body_Boundary (Position);
   end At_Declare_Expression_Body_Boundary;

   procedure Parse_Range_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Range_Constraint;

   procedure Parse_Digits_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Digits_Constraint;

   procedure Parse_Delta_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Delta_Constraint;

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Constraint_Parsing.Parse_Null_Exclusion;




   procedure Parse_Discriminant_Selector_Name_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Discriminant_Selector_Name_List;

   procedure Parse_Discriminant_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Discriminant_Constraint;

   procedure Parse_Index_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Index_Constraint;

   procedure Parse_Array_Index_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Array_Index_Part;

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Subtype_Indication;

   procedure Parse_Array_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Array_Type_Definition;

   procedure Parse_Access_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Access_Type_Definition;

   procedure Parse_Type_Modifiers
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Type_Modifiers;

   procedure Parse_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Type_Parsing.Parse_Type_Definition;

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
   begin
      return Range_Structure_Helpers.Parenthesized_Name_Suffix_Is_Slice (Position);
   end Parenthesized_Name_Suffix_Is_Slice;

   procedure Parse_Iterated_Component_Association
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
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
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Primary_Parsing.Parse_Allocator_Subtype_Indication;


   procedure Parse_Reduction_Argument_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Attribute_Name : String)
     renames Editor.Ada_Token_Cursor.Primary_Parsing.Parse_Reduction_Argument_Part;


   procedure Parse_Attribute_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String)
     renames Editor.Ada_Token_Cursor.Primary_Parsing.Parse_Attribute_Argument_List;




   procedure Mark_Raise_Exception_Target_Shape
     (Position               : Cursor;
      Result                 : in out Grammar_Result;
      Origin                 : Token_Info;
      Selected_Production    : Production_Kind;
      Recovery_Production    : Production_Kind;
      Label                  : String)
     renames Editor.Ada_Token_Cursor.Primary_Parsing.Mark_Raise_Exception_Target_Shape;

   procedure Parse_Primary (Position : in out Cursor; Result : in out Grammar_Result) is separate;
   procedure Parse_Identifier_Statement_Declaration_Phase
     (Position   : in out Cursor;
      Result     : in out Grammar_Result;
      Tok        : Token_Info;
      Mark_Pos   : Natural;
      Name_End   : Natural;
      Had_Names  : Boolean) is separate;
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


   procedure Parse_Pragma_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Pragma_Parsing.Parse_Pragma_Argument_List;

   procedure Parse_Pragma
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Pragma_Parsing.Parse_Pragma;


   function Parenthesized_Actual_Has_Top_Level_Arrow
     (Position : Cursor) return Boolean
     renames Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing.Parenthesized_Actual_Has_Top_Level_Arrow;

   procedure Mark_Generic_Actual_Nested_Actuals
     (Position : Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing.Mark_Generic_Actual_Nested_Actuals;

   procedure Parse_Generic_Actual_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing.Parse_Generic_Actual_Part;

   procedure Parse_Generic_Instantiated_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing.Parse_Generic_Instantiated_Unit_Name;

   procedure Parse_Generic_Instantiation_Declaration
     (Position  : in out Cursor;
      Result    : in out Grammar_Result;
      Unit_Kind : String)
     renames Editor.Ada_Token_Cursor.Generic_Instantiation_Parsing.Parse_Generic_Instantiation_Declaration;


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




   procedure Add_Concurrent_Definition_Part_Productions
     (Position     : in out Cursor;
      Result       : in out Grammar_Result;
      Public_Kind  : Production_Kind;
      Private_Kind : Production_Kind;
      Label        : String)
   is separate;
   procedure Parse_Representation_Target
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String) is separate;
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

   procedure Parse_Defining_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Defining_Name;

   procedure Parse_Defining_Program_Unit_Name
     (Position : in out Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Defining_Program_Unit_Name;

   procedure Parse_Renamed_Entity
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Label    : String := "renamed entity")
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Renamed_Entity;

   procedure Add_Renaming_Defining_Name
     (Position : Cursor;
      Result   : in out Grammar_Result;
      Label    : String)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Add_Renaming_Defining_Name;

   procedure Parse_Renaming_Tail
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Renaming_Tail;

   procedure Parse_Package_Renaming_Declaration
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Generic_Form : Boolean := False)
     renames Editor.Ada_Token_Cursor.Renaming_Parsing.Parse_Package_Renaming_Declaration;

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
      Boundary_Text : String) is separate;
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
      Result   : in out Grammar_Result) is separate;
   procedure Add_Package_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Add_Subprogram_Body_Part_Productions
     (Position  : Cursor;
      Result    : in out Grammar_Result;
      Body_Name : String) is separate;
   procedure Add_Task_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Add_Protected_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Subprogram_Construct
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   function Parenthesized_Has_Top_Level_Token
     (Position : Cursor;
      Text     : String) return Boolean is
   begin
      return Range_Structure_Helpers.Parenthesized_Has_Top_Level_Token (Position, Text);
   end Parenthesized_Has_Top_Level_Token;

   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Tok      : Token_Info)
     renames Editor.Ada_Token_Cursor.Entry_Parsing.Parse_Entry_Parenthesized_Parts;


   procedure Add_Entry_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result)
     renames Editor.Ada_Token_Cursor.Entry_Parsing.Add_Entry_Body_Part_Productions;


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
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Conditional_Statement_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Accept_Return_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Raise_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Delay_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Exit_Goto_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Tasking_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Identifier_Statement_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Statement_Phase
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
   procedure Parse_Declaration_Or_Statement
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is separate;
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

end Editor.Ada_Token_Cursor.Parsing_Phases_Engine;
