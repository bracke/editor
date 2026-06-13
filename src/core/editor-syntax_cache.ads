with Ada.Finalization;
with Editor.Syntax;

package Editor.Syntax_Cache is

   Max_Cached_Lines : constant Positive := 4096;
   Max_Tokens_Per_Line : constant Positive := 256;

   type Syntax_Cache is private;

   procedure Clear (Cache : in out Syntax_Cache);
   procedure Set_Line_Count (Cache : in out Syntax_Cache; Line_Count : Natural);

   procedure Mark_Line_Dirty
     (Cache       : in out Syntax_Cache;
      Line_Number : Positive);

   procedure Mark_Range_Dirty
     (Cache      : in out Syntax_Cache;
      First_Line : Positive;
      Last_Line  : Positive);

   --  Relex one dirty line.  The caller should continue with the next line
   --  while State_Changed is True; this keeps the policy explicit and avoids
   --  coupling the cache to the buffer text store.
   procedure Relex_Dirty_Line
     (Cache         : in out Syntax_Cache;
      Line_Number   : Positive;
      Line_Text     : String;
      State_Changed : out Boolean);

   function Tokens_For_Line
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Editor.Syntax.Token_Span_Array;

   --  Return the bounded line count currently owned by this cache.  A value
   --  below the document line count means later lines must degrade safely to
   --  plain text/overlay-only rendering rather than reusing stale spans.
   function Cached_Line_Count (Cache : Syntax_Cache) return Natural;

   function Line_Is_Cacheable
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Boolean;

   --  True when lexical classification produced more spans for a cached line
   --  than the fixed render/cache budget can retain.  Callers should treat
   --  missing tail tokens as plain text; spans must never spill into another
   --  line.
   function Token_Overflowed
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Boolean;

   function Is_Dirty
     (Cache       : Syntax_Cache;
      Line_Number : Positive) return Boolean;

private
   subtype Token_Index is Natural range 1 .. Max_Tokens_Per_Line;
   type Fixed_Tokens is array (Token_Index) of Editor.Syntax.Token_Span;

   type Line_Entry is record
      Start_State : Editor.Syntax.Lexical_State := Editor.Syntax.Normal_State;
      End_State   : Editor.Syntax.Lexical_State := Editor.Syntax.Normal_State;
      Dirty       : Boolean := True;
      Token_Count : Natural := 0;
      Token_Overflow : Boolean := False;
      Tokens      : Fixed_Tokens := (others => (0, 0, Editor.Syntax.Plain_Text));
   end record;

   type Line_Table is array (Positive range 1 .. Max_Cached_Lines) of Line_Entry;
   type Line_Table_Access is access Line_Table;

   type Syntax_Cache is new Ada.Finalization.Controlled with record
      Line_Count : Natural := 0;
      Lines      : Line_Table_Access := null;
   end record;

   overriding procedure Adjust (Cache : in out Syntax_Cache);
   overriding procedure Finalize (Cache : in out Syntax_Cache);

end Editor.Syntax_Cache;
