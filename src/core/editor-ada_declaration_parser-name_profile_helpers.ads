package Editor.Ada_Declaration_Parser.Name_Profile_Helpers is

   function Read_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String;

   function Read_Function_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String;

   function Declaration_Name_Position
     (Text          : String;
      Declared_Name : String) return Natural;

   function Read_Subtype_Mark
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean := True) return String;

   function Profile_From
     (Line          : String;
      Declared_Name : String) return String;

   function Profile_Continuation_From_Line (Line : String) return String;

   function Strip_Prefixes (Line : String) return String;

   function Target_After (Line, Marker : String) return String;

end Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
