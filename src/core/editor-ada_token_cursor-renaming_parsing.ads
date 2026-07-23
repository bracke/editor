with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Renaming_Parsing is

   procedure Parse_Defining_Name
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Defining_Program_Unit_Name
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Renamed_Entity
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Label    : String := "renamed entity");

   procedure Add_Renaming_Defining_Name
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Label    : String);

   procedure Parse_Renaming_Tail
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Origin   : Editor.Ada_Token_Cursor.Token_Info;
      Label    : String);

   procedure Parse_Package_Renaming_Declaration
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Generic_Form : Boolean := False);

end Editor.Ada_Token_Cursor.Renaming_Parsing;
