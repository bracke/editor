package body Editor.Unicode is
   function Is_Valid_Scalar (C : Code_Point) return Boolean is
      V : constant Natural := Wide_Wide_Character'Pos (C);
   begin
      return V <= 16#10FFFF# and then not (V in 16#D800# .. 16#DFFF#);
   end Is_Valid_Scalar;

   function Is_Newline (C : Code_Point) return Boolean is
   begin
      return C = Wide_Wide_Character'Val (10);
   end Is_Newline;
end Editor.Unicode;
