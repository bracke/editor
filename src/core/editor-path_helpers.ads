package Editor.Path_Helpers is

   function Strip_Trailing_Separators (Path : String) return String;
   function Normalize_For_Compare
     (Path : String;
      Strip_Trailing : Boolean := False;
      Lowercase      : Boolean := False) return String;
   function Path_Depth (Path : String) return Natural;

end Editor.Path_Helpers;
