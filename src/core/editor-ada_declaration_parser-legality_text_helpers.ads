package Editor.Ada_Declaration_Parser.Legality_Text_Helpers is

   function Top_Level_Named_Actual_Count
     (Args : String; Formal_Name : String) return Natural;

   function Top_Level_Arrow_Position (Text : String) return Natural;

   function Has_Top_Level_Positional_After_Named (Args : String) return Boolean;

   function First_Top_Level_Named_Actual (Args : String) return String;

   function Normalized_Aspect_Mark (Association_Label : String) return String;

   function Normalized_Choice_Text (Raw : String) return String;

   function Choice_Count_In_List
     (Choice_List : String;
      Choice      : String) return Natural;

   function Looks_Like_Aggregate_Context (Expression_Text : String) return Boolean;

end Editor.Ada_Declaration_Parser.Legality_Text_Helpers;
