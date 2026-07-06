package Editor.Ada_Declaration_Parser.Representation_Static_Values is

   procedure Parse_Static_Natural
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural);

   function Natural_In_Integer_Range
     (Value    : Natural;
      Has_Low  : Boolean;
      Low      : Integer;
      Has_High : Boolean;
      High     : Integer) return Boolean;

end Editor.Ada_Declaration_Parser.Representation_Static_Values;
