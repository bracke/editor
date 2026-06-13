package Editor.Syntax is

   type Syntax_Kind is
     (Plain_Text,
      Keyword,
      Identifier,
      Type_Identifier,
      Subprogram_Identifier,
      Package_Identifier,
      Parameter_Identifier,
      Number_Literal,
      String_Literal,
      Character_Literal,
      Comment,
      Operator,
      Punctuation,
      Attribute,
      Aspect_Name,
      Pragma_Name,
      Generic_Formal,
      Diagnostic_Error,
      Diagnostic_Warning,
      Search_Match,
      Selection_Overlay);

   --  Token_Kind remains the public spelling consumed by theme/render code.
   subtype Token_Kind is Syntax_Kind;

   type Lexical_State is
     (Normal_State,
      In_Unterminated_String,
      In_Unterminated_Character,
      In_Invalid_Number);

   type Token_Span is record
      Start_Col : Natural;
      End_Col   : Natural;
      Kind      : Token_Kind;
   end record;

   type Token_Span_Array is array (Natural range <>) of Token_Span;

   --  Return True when Word is an Ada reserved word. Matching is
   --  case-insensitive and preserves the caller's original spelling.
   function Is_Keyword (Word : String) return Boolean;

   --  Return the syntax kind for a zero-based column in a single line.
   function Kind_At
     (Line   : String;
      Column : Natural) return Syntax_Kind;

   function Classify
     (Line : String;
      Col  : Natural) return Token_Kind;

   --  Tokenize one line and expose half-open zero-based column spans.
   --  Final_State lets callers build incremental caches that propagate only
   --  while line-start state changes.
   procedure Classify_Line
     (Line          : String;
      Initial_State : Lexical_State;
      Visit         : not null access procedure
        (Start_Col : Natural;
         End_Col   : Natural;
         Kind      : Token_Kind);
      Final_State   : out Lexical_State);

   --  Render-path token query API.  The requested absolute
   --  half-open range [Start_Index, Stop_Index) is clipped against tokens found
   --  inside Line, whose first character has absolute index Line_Start_Index.
   procedure Classify_Range
     (Line             : String;
      Line_Start_Index : Natural;
      Start_Index      : Natural;
      Stop_Index       : Natural;
      Visit            : not null access procedure
        (Start_Index : Natural;
         Stop_Index  : Natural;
         Kind        : Syntax_Kind));

end Editor.Syntax;
