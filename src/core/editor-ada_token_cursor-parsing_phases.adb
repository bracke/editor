with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor.Parsing_Phases_Engine;

package body Editor.Ada_Token_Cursor.Parsing_Phases is

   package Phases renames Editor.Ada_Token_Cursor.Parsing_Phases_Engine;

   function Tokenize (Text : String) return Token_Stream is
   begin
      return Phases.Tokenize (Text);
   end Tokenize;

   function Length (Stream : Token_Stream) return Natural is
   begin
      return Phases.Length (Stream);
   end Length;

   function Token_At (Stream : Token_Stream; Index : Positive) return Token_Info is
   begin
      return Phases.Token_At (Stream, Index);
   end Token_At;

   function First (Stream : Token_Stream) return Cursor is
   begin
      return Phases.First (Stream);
   end First;

   function At_End (Position : Cursor) return Boolean is
   begin
      return Phases.At_End (Position);
   end At_End;

   function Current (Position : Cursor) return Token_Info is
   begin
      return Phases.Current (Position);
   end Current;

   procedure Advance (Position : in out Cursor) is
   begin
      Phases.Advance (Position);
   end Advance;

   function Mark (Position : Cursor) return Natural is
   begin
      return Phases.Mark (Position);
   end Mark;

   procedure Restore (Position : in out Cursor; To_Mark : Natural) is
   begin
      Phases.Restore (Position, To_Mark);
   end Restore;

   function Match_Keyword (Position : in out Cursor; Keyword : String) return Boolean is
   begin
      return Phases.Match_Keyword (Position, Keyword);
   end Match_Keyword;

   function Match_Symbol (Position : in out Cursor; Symbol : String) return Boolean is
   begin
      return Phases.Match_Symbol (Position, Symbol);
   end Match_Symbol;

   function Parse (Text : String) return Grammar_Result is
   begin
      return Phases.Parse (Text);
   end Parse;

   function Production_Count (Result : Grammar_Result) return Natural is
   begin
      return Phases.Production_Count (Result);
   end Production_Count;

   function Production_At
     (Result : Grammar_Result;
      Index  : Positive) return Production_Info is
   begin
      return Phases.Production_At (Result, Index);
   end Production_At;

   function Has_Production
     (Result : Grammar_Result;
      Kind   : Production_Kind) return Boolean is
   begin
      return Phases.Has_Production (Result, Kind);
   end Has_Production;

   procedure Parse_Primary
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Primary (Position, Result);
   end Parse_Primary;

   procedure Parse_Type_Modifiers
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Type_Modifiers (Position, Result);
   end Parse_Type_Modifiers;

   procedure Parse_Enumeration_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Enumeration_Type_Definition (Position, Result);
   end Parse_Enumeration_Type_Definition;

   procedure Parse_Record_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Record_Definition (Position, Result);
   end Parse_Record_Definition;

   procedure Parse_Range_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Range_Constraint (Position, Result);
   end Parse_Range_Constraint;

   procedure Parse_Digits_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Digits_Constraint (Position, Result);
   end Parse_Digits_Constraint;

   procedure Parse_Delta_Constraint
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Delta_Constraint (Position, Result);
   end Parse_Delta_Constraint;

   procedure Parse_Null_Exclusion
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Null_Exclusion (Position, Result);
   end Parse_Null_Exclusion;

   procedure Parse_Access_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Access_Type_Definition (Position, Result);
   end Parse_Access_Type_Definition;

   procedure Parse_Array_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Array_Type_Definition (Position, Result);
   end Parse_Array_Type_Definition;

   procedure Parse_Type_Definition
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Type_Definition (Position, Result);
   end Parse_Type_Definition;

   procedure Parse_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Subtype_Indication (Position, Result);
   end Parse_Subtype_Indication;

   function Has_Top_Level_Arrow_Before_Association_End
     (Position : Cursor) return Boolean is
   begin
      return Editor.Ada_Token_Cursor.Range_Structure_Helpers.
        Has_Top_Level_Arrow_Before_Association_End (Position);
   end Has_Top_Level_Arrow_Before_Association_End;

   procedure Parse_Allocator_Subtype_Indication
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Parse_Allocator_Subtype_Indication (Position, Result);
   end Parse_Allocator_Subtype_Indication;

   procedure Parse_Reduction_Argument_Part
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Attribute_Name : String) is
   begin
      Phases.Parse_Reduction_Argument_Part
        (Position, Result, Origin, Attribute_Name);
   end Parse_Reduction_Argument_Part;

   procedure Parse_Attribute_Argument_List
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Origin   : Token_Info;
      Label    : String) is
   begin
      Phases.Parse_Attribute_Argument_List (Position, Result, Origin, Label);
   end Parse_Attribute_Argument_List;

   procedure Parse_Entry_Parenthesized_Parts
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Tok      : Token_Info) is
   begin
      Phases.Parse_Entry_Parenthesized_Parts (Position, Result, Tok);
   end Parse_Entry_Parenthesized_Parts;

   procedure Add_Statement_Name_Suffix_Productions
     (Position       : Cursor;
      Result         : in out Grammar_Result;
      Start_At       : Natural;
      End_At         : Natural;
      For_Assignment : Boolean) is
   begin
      Phases.Add_Statement_Name_Suffix_Productions
        (Position, Result, Start_At, End_At, For_Assignment);
   end Add_Statement_Name_Suffix_Productions;

   procedure Add_Entry_Body_Part_Productions
     (Position : Cursor;
      Result   : in out Grammar_Result) is
   begin
      Phases.Add_Entry_Body_Part_Productions (Position, Result);
   end Add_Entry_Body_Part_Productions;

   procedure Mark_Raise_Exception_Target_Shape
     (Position               : Cursor;
      Result                 : in out Grammar_Result;
      Origin                 : Token_Info;
      Selected_Production    : Production_Kind;
      Recovery_Production    : Production_Kind;
      Label                  : String) is
   begin
      Phases.Mark_Raise_Exception_Target_Shape
        (Position,
         Result,
         Origin,
         Selected_Production,
         Recovery_Production,
         Label);
   end Mark_Raise_Exception_Target_Shape;

end Editor.Ada_Token_Cursor.Parsing_Phases;
