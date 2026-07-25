with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Hashing is

   type Natural_Addend_Array is array (Positive range <>) of Natural;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural;

   function Hash_Mix
     (Seed       : Natural;
      Addends    : Natural_Addend_Array;
      Multiplier : Long_Long_Integer := 131) return Natural;

   function Hash_String (Seed : Natural; Text : String) return Natural;
   function Hash_Boolean (Seed : Natural; Value : Boolean) return Natural;
   function Hash_Flags
     (Seed  : Natural;
      Flags : Declaration_Flags) return Natural;

   function Normalize_Name (Name : String) return String;

end Editor.Ada_Language_Model.Hashing;
