with Editor.Ada_Token_Cursor;

package Editor.Ada_Token_Cursor.Aggregate_Parsing is

   procedure Parse_Iterated_Component_Association
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Add_Aggregate_Choice_Depth
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result);

   procedure Parse_Component_Association_Item
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Origin   : Editor.Ada_Token_Cursor.Token_Info);

   procedure Parse_Association_List
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Result   : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Qualified_Expression_Operand : Boolean := False);

end Editor.Ada_Token_Cursor.Aggregate_Parsing;
