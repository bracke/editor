with Editor.Syntax;
with Editor.Outline;
with Editor.Ada_Language_Model;

package Editor.Syntax_Semantics is

   Max_Local_Symbols : constant Positive := 512;

   type Semantic_Map is private;

   procedure Clear (Map : in out Semantic_Map);

   --  Conservative Ada declaration extraction.  This records names introduced
   --  by package/procedure/function/type/subtype/task/protected/entry/generic
   --  declarations and leaves uncertain text untouched.
   procedure Learn_Declarations_From_Line
     (Map  : in out Semantic_Map;
      Line : String);

   --  Preferred product seam when Outline extraction has already produced
   --  validated Ada declaration rows. This avoids maintaining a second
   --  declaration recognizer in callers and keeps semantic colouring
   --  conservative and local.
   procedure Build_Map_From_Outline
     (Map   : in out Semantic_Map;
      Items : Editor.Outline.Outline_Item_Array);

   procedure Build_Map_From_Outline_State
     (Map     : in out Semantic_Map;
      Outline : Editor.Outline.Outline_State);

   --  Scope-aware semantic source.  This is the preferred Ada semantic-colouring
   --  input when a parser-owned language-model analysis is available.  The map
   --  remains bounded and deterministic; overflowed analysis degrades unknown
   --  identifiers back to lexical Identifier.
   procedure Build_Map_From_Analysis
     (Map      : in out Semantic_Map;
      Analysis : Editor.Ada_Language_Model.Analysis_Result);

   function Kind_For_Identifier
     (Map  : Semantic_Map;
      Name : String) return Editor.Syntax.Token_Kind;

   --  Scope-aware classification path for callers that have parser-owned
   --  language-model analysis and a lexical owner symbol for the token being
   --  coloured.  This preserves shadowing better than the bounded flat map:
   --  the resolver walks the actual parent-symbol chain and only then maps
   --  the resolved symbol kind to a syntax token bucket.
   function Kind_For_Identifier_In_Scope
     (Analysis   : Editor.Ada_Language_Model.Analysis_Result;
      Name       : String;
      From_Scope : Editor.Ada_Language_Model.Symbol_Id)
      return Editor.Syntax.Token_Kind;

   --  Number of semantic symbols retained in the bounded local map.
   function Symbol_Count
     (Map : Semantic_Map) return Natural;

   --  True once declaration learning encountered more symbols than the fixed
   --  local semantic budget can retain.  Missing symbols must degrade to
   --  ordinary identifiers; the retained map must remain deterministic.
   function Symbol_Cap_Reached
     (Map : Semantic_Map) return Boolean;

private
   subtype Stored_Name is String (1 .. 64);

   type Symbol_Entry is record
      Used : Boolean := False;
      Len  : Natural := 0;
      Name : Stored_Name := (others => ' ');
      Kind : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
   end record;

   type Symbol_Array is array (Positive range 1 .. Max_Local_Symbols) of Symbol_Entry;

   type Semantic_Map is record
      Symbols : Symbol_Array;
      Symbol_Overflow : Boolean := False;
   end record;

end Editor.Syntax_Semantics;
