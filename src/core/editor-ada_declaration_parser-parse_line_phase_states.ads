with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Parse_Line_Phase_States is

   type Parse_Line_Phase_State is record
      Name       : String (1 .. 256) := (others => ' ');
      Name_Len   : Natural := 0;
      Kind       : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Flags      : Editor.Ada_Language_Model.Declaration_Flags :=
        (others => False);
      Target     : String (1 .. 256) := (others => ' ');
      Target_Len : Natural := 0;
      Profile     : String (1 .. 512) := (others => ' ');
      Profile_Len : Natural := 0;
   end record;

   procedure Clear (State : out Parse_Line_Phase_State);

   procedure Set_Name
     (State : in out Parse_Line_Phase_State;
      Text  : String);

   procedure Set_Target
     (State : in out Parse_Line_Phase_State;
      Text  : String);

   procedure Set_Profile
     (State : in out Parse_Line_Phase_State;
      Text  : String);

   function Name_Text (State : Parse_Line_Phase_State) return String;
   function Target_Text (State : Parse_Line_Phase_State) return String;
   function Profile_Text (State : Parse_Line_Phase_State) return String;

end Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
