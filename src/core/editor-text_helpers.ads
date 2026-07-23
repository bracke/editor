package Editor.Text_Helpers is

   function Lower (S : String) return String;
   function Trim (S : String) return String;
   function Normalize (S : String) return String;
   function Normalized_Line (Line : String) return String;
   function Trim_Static_Space (Text : String) return String;
   function Is_Word_Char (C : Character) return Boolean;
   function Clean_Name (Raw : String) return String;
   function Starts_With (Text, Prefix : String) return Boolean;
   function Starts_With_Word (Text, Word : String) return Boolean;
   function Contains (Text, Fragment : String) return Boolean;
   function Ends_With (Text, Suffix : String) return Boolean;

end Editor.Text_Helpers;
