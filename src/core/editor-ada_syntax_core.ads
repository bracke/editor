package Editor.Ada_Syntax_Core is

   --  Return a transient code-only Ada line view. Ada comments, string
   --  literals, doubled quotes inside strings, simple character literals, and
   --  physical line separators are replaced with spaces while preserving line
   --  length and original columns. This package is the neutral shared lexical
   --  front-end for syntax colouring, semantic colouring, and Outline; it owns
   --  Ada lexical safety so presentation and navigation features do not drift.
   function Sanitize_Line (Line : String) return String;

   --  Return whether a 1-based source column is code according to the same
   --  lightweight Ada lexical safety pass used by Sanitize_Line.
   function Is_Code_Column
     (Line   : String;
      Column : Positive) return Boolean;

   --  Strip comments/string-only tail text through the shared lexical safety
   --  pass while preserving code characters. The returned slice may be empty.
   function Strip_Comment_Safely (Line : String) return String;

   --  Return True when Label identifies an Ada source file extension supported
   --  by the lightweight front-end.
   function Is_Ada_Source_Label (Label : String) return Boolean;


   --  Return True when Line(Start ..) begins a bounded simple Ada character
   --  literal handled by the shared lexical pass. Start is an absolute source
   --  index in Line'Range, not a 1-based column.
   function Looks_Like_Simple_Character_Literal
     (Line  : String;
      Start : Natural) return Boolean;

   --  Return the length of a simple Ada character literal at Start, or zero
   --  when no supported literal begins there.
   function Simple_Character_Literal_Length
     (Line  : String;
      Start : Natural) return Natural;

   --  Return True for a conservative declaration-leading Ada line after shared
   --  lexical sanitization. This is intentionally not a full Ada parser; it is
   --  the common source of truth used to decide whether Outline/Semantics should
   --  attempt lightweight construct recognition.
   function Looks_Like_Ada_Declaration_Line (Line : String) return Boolean;

   --  Return a declaration line with a leading separate(...) prefix removed
   --  when present. Non-separate lines are returned unchanged.
   function Strip_Separate_Prefix (Line : String) return String;

end Editor.Ada_Syntax_Core;
