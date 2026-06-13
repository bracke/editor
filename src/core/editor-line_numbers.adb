package body Editor.Line_Numbers is

   State : Line_Number_Config := (Mode => Absolute_Line_Numbers);

   function Current return Line_Number_Config is
   begin
      return State;
   end Current;

   procedure Set_Current (Config : Line_Number_Config) is
   begin
      State := Config;
   end Set_Current;

   procedure Reset is
   begin
      State := (Mode => Absolute_Line_Numbers);
   end Reset;

   function Line_Number_Mode_Name (Mode : Line_Number_Mode) return String is
   begin
      case Mode is
         when Absolute_Line_Numbers =>
            return "absolute";
         when Relative_Line_Numbers =>
            return "relative";
         when Hybrid_Line_Numbers =>
            return "hybrid";
      end case;
   end Line_Number_Mode_Name;

   function Line_Number_Mode_From_Name
     (Name  : String;
      Found : out Boolean) return Line_Number_Mode
   is
   begin
      if Name = "absolute" then
         Found := True;
         return Absolute_Line_Numbers;
      elsif Name = "relative" then
         Found := True;
         return Relative_Line_Numbers;
      elsif Name = "hybrid" then
         Found := True;
         return Hybrid_Line_Numbers;
      else
         Found := False;
         return Absolute_Line_Numbers;
      end if;
   end Line_Number_Mode_From_Name;

   procedure Toggle_Mode is
   begin
      case State.Mode is
         when Absolute_Line_Numbers =>
            State.Mode := Relative_Line_Numbers;
         when Relative_Line_Numbers =>
            State.Mode := Hybrid_Line_Numbers;
         when Hybrid_Line_Numbers =>
            State.Mode := Absolute_Line_Numbers;
      end case;
   end Toggle_Mode;

   function Trimmed_Image (Value : Natural) return String is
      Image : constant String := Natural'Image (Value);
   begin
      return Image (Image'First + 1 .. Image'Last);
   end Trimmed_Image;

   function Distance
     (Left  : Natural;
      Right : Natural) return Natural
   is
   begin
      if Left >= Right then
         return Left - Right;
      else
         return Right - Left;
      end if;
   end Distance;

   function Display_Text
     (Config       : Line_Number_Config;
      Document_Row : Natural;
      Current_Row  : Natural) return String
   is
   begin
      case Config.Mode is
         when Absolute_Line_Numbers =>
            return Trimmed_Image (Document_Row + 1);

         when Relative_Line_Numbers =>
            if Document_Row = Current_Row then
               return "0";
            else
               return Trimmed_Image (Distance (Document_Row, Current_Row));
            end if;

         when Hybrid_Line_Numbers =>
            if Document_Row = Current_Row then
               return Trimmed_Image (Document_Row + 1);
            else
               return Trimmed_Image (Distance (Document_Row, Current_Row));
            end if;
      end case;
   end Display_Text;

end Editor.Line_Numbers;
