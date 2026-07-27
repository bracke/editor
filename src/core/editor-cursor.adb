package body Editor.Cursor is

   Current_Config : Cursor_Config :=
     (Style       => Bar_Cursor,
      Bar_Width   => 1,
      Underline_H => 2);

   Current_Blink_Config : Blink_Config :=
     (Blink_Enabled       => True,
      Blink_Period_Sec    => 1.0,
      Blink_Duty_Cycle    => 0.5,
      Last_Input_Time_Sec => 0.0);

   function Positive_Mod
     (Value : Float;
      Modulus : Float) return Float
   is
      Result : Float := 0.0;
   begin
      if Modulus <= 0.0 then
         return 0.0;
      end if;

      Result :=
        Value - Float (Float'Floor (Value / Modulus)) * Modulus;

      if Result >= Modulus then
         return 0.0;
      elsif Result < 0.0 then
         return Result + Modulus;
      else
         return Result;
      end if;
   end Positive_Mod;

   function Current return Cursor_Config is
   begin
      return Current_Config;
   end Current;

   procedure Set_Current
     (Config : Cursor_Config) is
   begin
      Current_Config := Config;
   end Set_Current;

   function Current_Blink return Blink_Config is
   begin
      return Current_Blink_Config;
   end Current_Blink;

   procedure Set_Blink
     (Config : Blink_Config) is
   begin
      Current_Blink_Config := Config;
   end Set_Blink;

   procedure Set_Blink_Enabled
     (Enabled : Boolean) is
   begin
      Current_Blink_Config.Blink_Enabled := Enabled;
   end Set_Blink_Enabled;

   procedure Notify_Input
     (Now_Sec : Float) is
   begin
      Current_Blink_Config.Last_Input_Time_Sec := Now_Sec;
   end Notify_Input;

   function Visible
     (Now_Sec : Float) return Boolean
   is
      Period : constant Float := Current_Blink_Config.Blink_Period_Sec;
      Duty   : constant Float := Current_Blink_Config.Blink_Duty_Cycle;
      Phase  : Float := 0.0;
   begin
      if not Current_Blink_Config.Blink_Enabled then
         return True;
      end if;

      if Period <= 0.0 then
         return True;
      end if;

      if Duty <= 0.0 then
         return False;
      elsif Duty >= 1.0 then
         return True;
      end if;

      --  If the supplied clock value is equal to or older than the most
      --  recent input timestamp, treat the cursor as freshly reset.  This
      --  keeps tests and runtime startup deterministic even if a caller resets
      --  the view clock after input has been recorded.
      if Now_Sec <= Current_Blink_Config.Last_Input_Time_Sec then
         return True;
      end if;

      Phase :=
        Positive_Mod
          (Now_Sec - Current_Blink_Config.Last_Input_Time_Sec,
           Period);

      return Phase < Period * Duty;
   end Visible;

   function Seconds_To_Next_Change
     (Now_Sec : Float) return Float
   is
      --  A caret that never toggles: any value large enough that the caller
      --  clamps it to its own maximum idle wait.
      Never  : constant Float := 3600.0;
      Period : constant Float := Current_Blink_Config.Blink_Period_Sec;
      Duty   : constant Float := Current_Blink_Config.Blink_Duty_Cycle;
      On_End : constant Float := Period * Duty;
      Phase  : Float;
   begin
      if not Current_Blink_Config.Blink_Enabled
        or else Period <= 0.0
        or else Duty <= 0.0
        or else Duty >= 1.0
      then
         return Never;
      end if;

      --  Freshly reset (clock at or before the last input): visible now, the
      --  first toggle is one on-phase away.
      if Now_Sec <= Current_Blink_Config.Last_Input_Time_Sec then
         return On_End;
      end if;

      Phase :=
        Positive_Mod
          (Now_Sec - Current_Blink_Config.Last_Input_Time_Sec,
           Period);

      --  Toggles happen at Phase = On_End (visible -> hidden) and Phase = Period
      --  (hidden -> visible); return the distance to whichever comes next.
      if Phase < On_End then
         return On_End - Phase;
      else
         return Period - Phase;
      end if;
   end Seconds_To_Next_Change;

end Editor.Cursor;
