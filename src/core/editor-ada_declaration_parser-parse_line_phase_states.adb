package body Editor.Ada_Declaration_Parser.Parse_Line_Phase_States is

   procedure Set_Bounded
     (Target : in out String;
      Length : in out Natural;
      Text   : String)
   is
   begin
      Target := (others => ' ');
      Length := Natural'Min (Text'Length, Target'Length);
      if Length > 0 then
         Target (Target'First .. Target'First + Length - 1) :=
           Text (Text'First .. Text'First + Length - 1);
      end if;
   end Set_Bounded;

   function Bounded_Text
     (Target : String;
      Length : Natural) return String
   is
   begin
      if Length = 0 then
         return "";
      end if;
      return Target (Target'First .. Target'First + Length - 1);
   end Bounded_Text;

   procedure Clear (State : out Parse_Line_Phase_State) is
   begin
      State := (others => <>);
   end Clear;

   procedure Set_Name
     (State : in out Parse_Line_Phase_State;
      Text  : String)
   is
   begin
      Set_Bounded (State.Name, State.Name_Len, Text);
   end Set_Name;

   procedure Set_Target
     (State : in out Parse_Line_Phase_State;
      Text  : String)
   is
   begin
      Set_Bounded (State.Target, State.Target_Len, Text);
   end Set_Target;

   procedure Set_Profile
     (State : in out Parse_Line_Phase_State;
      Text  : String)
   is
   begin
      Set_Bounded (State.Profile, State.Profile_Len, Text);
   end Set_Profile;

   function Name_Text (State : Parse_Line_Phase_State) return String is
   begin
      return Bounded_Text (State.Name, State.Name_Len);
   end Name_Text;

   function Target_Text (State : Parse_Line_Phase_State) return String is
   begin
      return Bounded_Text (State.Target, State.Target_Len);
   end Target_Text;

   function Profile_Text (State : Parse_Line_Phase_State) return String is
   begin
      return Bounded_Text (State.Profile, State.Profile_Len);
   end Profile_Text;

end Editor.Ada_Declaration_Parser.Parse_Line_Phase_States;
