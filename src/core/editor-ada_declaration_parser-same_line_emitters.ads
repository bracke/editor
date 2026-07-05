with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Same_Line_Emitters is

   use Editor.Ada_Language_Model;

   procedure Add_Same_Line_Subtype_Groups
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Parent_Is_Private : Boolean);

end Editor.Ada_Declaration_Parser.Same_Line_Emitters;
