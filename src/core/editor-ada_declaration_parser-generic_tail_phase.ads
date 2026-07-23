package Editor.Ada_Declaration_Parser.Generic_Tail_Phase is

   generic
      with function Parse_Segment
        (First : Natural;
         Last  : Natural) return Boolean;
   procedure Parse_Same_Line_Generic_Tail
     (Raw_Line : String);

end Editor.Ada_Declaration_Parser.Generic_Tail_Phase;
