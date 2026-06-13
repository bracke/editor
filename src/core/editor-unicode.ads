package Editor.Unicode is
   subtype Code_Point is Wide_Wide_Character;

   Replacement_Character : constant Code_Point := Wide_Wide_Character'Val (16#FFFD#);

   function Is_Valid_Scalar (C : Code_Point) return Boolean;
   function Is_Newline (C : Code_Point) return Boolean;
end Editor.Unicode;
