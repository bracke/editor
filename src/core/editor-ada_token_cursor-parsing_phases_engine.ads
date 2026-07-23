with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Token_Cursor.Parsing_Phases_Engine is

   --  UI-free token-cursor grammar layer for Ada source.  This package is the
   --  grammar-facing parser substrate used by the syntax tree and tests; it is
   --  intentionally bounded/conservative, but it parses by tokens and grammar
   --  synchronization points rather than by rendering or line ownership.

   subtype Token_Kind is Editor.Ada_Token_Cursor.Token_Kind;
   subtype Token_Info is Editor.Ada_Token_Cursor.Token_Info;

   subtype Production_Kind is Editor.Ada_Token_Cursor.Production_Kind;
   subtype Production_Info is Editor.Ada_Token_Cursor.Production_Info;
   subtype Token_Stream is Editor.Ada_Token_Cursor.Token_Stream;
   subtype Cursor is Editor.Ada_Token_Cursor.Cursor;
   subtype Grammar_Result is Editor.Ada_Token_Cursor.Grammar_Result;

   function Tokenize (Text : String) return Token_Stream;
   function Length (Stream : Token_Stream) return Natural;
   function Token_At (Stream : Token_Stream; Index : Positive) return Token_Info;

   function First (Stream : Token_Stream) return Cursor;
   function At_End (Position : Cursor) return Boolean;
   function Current (Position : Cursor) return Token_Info;
   procedure Advance (Position : in out Cursor);
   function Mark (Position : Cursor) return Natural;
   procedure Restore (Position : in out Cursor; To_Mark : Natural);
   function Match_Keyword (Position : in out Cursor; Keyword : String) return Boolean;
   function Match_Symbol (Position : in out Cursor; Symbol : String) return Boolean;

   function Parse (Text : String) return Grammar_Result;
   function Production_Count (Result : Grammar_Result) return Natural;
   function Production_At
     (Result : Grammar_Result;
      Index  : Positive) return Production_Info;
   function Has_Production
     (Result : Grammar_Result;
      Kind   : Production_Kind) return Boolean;

   procedure Parse_Primary
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Type_Modifiers
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Enumeration_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Record_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Range_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Digits_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Delta_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Access_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Array_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Allocator_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result);

   procedure Parse_Reduction_Argument_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Attribute_Name : String);

   procedure Parse_Attribute_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String);

   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Tok      : Token_Info);

   procedure Add_Statement_Name_Suffix_Productions
     (Position       : Cursor;
      Result         : in out Grammar_Result;
      Start_At       : Natural;
      End_At         : Natural;
      For_Assignment : Boolean);

   procedure Add_Entry_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result);

   procedure Mark_Raise_Exception_Target_Shape
     (Position               : Cursor;
      Result                 : in out Grammar_Result;
      Origin                 : Token_Info;
      Selected_Production    : Production_Kind;
      Recovery_Production    : Production_Kind;
      Label                  : String);

end Editor.Ada_Token_Cursor.Parsing_Phases_Engine;
