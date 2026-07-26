with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Type_Parsing is

   procedure Parse_Subtype_Mark
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Defining_Name_List
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Profile_Default
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Parameter_Specification
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Parameter_Profile
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Discriminant_Selector_Name_List
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Discriminant_Constraint
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Index_Constraint
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Array_Index_Part
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Subtype_Indication
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Array_Type_Definition
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Access_Type_Definition
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Type_Modifiers
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Enumeration_Type_Definition
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Record_Definition
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Type_Definition
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

end Editor.Ada_Token_Cursor.Type_Parsing;
