with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase is

   procedure Parse_Compact_Record_Tail
     (Analysis      : in out Editor.Ada_Language_Model.Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Owner         : Editor.Ada_Language_Model.Symbol_Id;
      Mark_Metadata : not null access procedure
        (Flags : in out Editor.Ada_Language_Model.Declaration_Flags;
         Line  : String));

end Editor.Ada_Declaration_Parser.Compact_Record_Tail_Phase;
