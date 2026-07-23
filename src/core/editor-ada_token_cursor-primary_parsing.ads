with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Primary_Parsing is

   function Has_Top_Level_Arrow_Before_Association_End
     (Position : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   function Qualified_Subtype_Mark_Has_Selected_Prefix
     (Start : Editor.Ada_Token_Cursor.Cursor) return Boolean;

   procedure Parse_Allocator_Subtype_Indication
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Reduction_Argument_Part
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Origin   : Editor.Ada_Token_Cursor.Token_Info;
      Attribute_Name : String);

   procedure Parse_Attribute_Argument_List
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Origin   : Editor.Ada_Token_Cursor.Token_Info;
      Label    : String);

   procedure Mark_Raise_Exception_Target_Shape
     (Position               : Editor.Ada_Token_Cursor.Cursor;
      Result                 : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Origin                 : Editor.Ada_Token_Cursor.Token_Info;
      Selected_Production    : Editor.Ada_Token_Cursor.Production_Kind;
      Recovery_Production    : Editor.Ada_Token_Cursor.Production_Kind;
      Label                  : String);

end Editor.Ada_Token_Cursor.Primary_Parsing;
