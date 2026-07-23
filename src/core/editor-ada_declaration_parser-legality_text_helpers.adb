with Ada.Strings.Fixed;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;

package body Editor.Ada_Declaration_Parser.Legality_Text_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Range_Structure_Helpers;

   function Top_Level_Named_Actual_Count
     (Args : String; Formal_Name : String) return Natural
   is
      I     : Natural := Args'First;
      Depth : Natural := 0;
      Count : Natural := 0;
      Target : constant String := Lower (Formal_Name);
   begin
      if Target = "" then
         return 0;
      end if;

      while I <= Args'Last loop
         if Args (I) = '(' then
            Depth := Depth + 1;
            I := I + 1;
         elsif Args (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
            I := I + 1;
         elsif Depth = 0 and then Is_Local_Name_Start (Args (I)) then
            declare
               Start : constant Natural := I;
               Stop  : Natural := I;
               Arrow : Natural;
            begin
               while Stop <= Args'Last
                 and then (Is_Local_Name_Char (Args (Stop)) or else Args (Stop) = '.')
               loop
                  Stop := Stop + 1;
               end loop;

               Arrow := Stop;
               while Arrow <= Args'Last and then Args (Arrow) = ' ' loop
                  Arrow := Arrow + 1;
               end loop;

               if Arrow + 1 <= Args'Last
                 and then Args (Arrow) = '='
                 and then Args (Arrow + 1) = '>'
               then
                  declare
                     Candidate : constant String := Args (Start .. Stop - 1);
                  begin
                     if Lower (Candidate) = Target then
                        Count := Count + 1;
                     end if;
                  end;
               end if;

               I := Stop;
            end;
         else
            I := I + 1;
         end if;
      end loop;

      return Count;
   end Top_Level_Named_Actual_Count;

   function Top_Level_Arrow_Position (Text : String) return Natural is
      Depth : Natural := 0;
      I     : Natural := Text'First;
   begin
      while I <= Text'Last loop
         if Text (I) = '(' then
            Depth := Depth + 1;
         elsif Text (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Depth = 0
           and then I + 1 <= Text'Last
           and then Text (I) = '='
           and then Text (I + 1) = '>'
         then
            return I;
         end if;
         I := I + 1;
      end loop;
      return 0;
   end Top_Level_Arrow_Position;

   function Has_Top_Level_Positional_After_Named (Args : String) return Boolean is
      Depth : Natural := 0;
      Part_Start : Natural := Args'First;
      I : Natural := Args'First;
      Seen_Named : Boolean := False;

      procedure Check_Part
        (Part_First : Natural;
         Part_Last  : Natural;
         Stop       : in out Boolean)
      is
         Clean : constant String :=
           (if Part_First <= Part_Last
            then Trim (Args (Part_First .. Part_Last))
            else "");
      begin
         Stop := False;
         if Clean = "" then
            return;
         end if;

         if Top_Level_Arrow_Position (Clean) /= 0 then
            Seen_Named := True;
         elsif Seen_Named then
            Stop := True;
         end if;
      end Check_Part;
   begin
      while I <= Args'Last loop
         if Args (I) = '(' then
            Depth := Depth + 1;
         elsif Args (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Args (I) = ',' and then Depth = 0 then
            declare
               Stop : Boolean := False;
            begin
               Check_Part (Part_Start, I - 1, Stop);
               if Stop then
                  return True;
               end if;
            end;
            Part_Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      declare
         Stop : Boolean := False;
      begin
         Check_Part (Part_Start, Args'Last, Stop);
         return Stop;
      end;
   end Has_Top_Level_Positional_After_Named;

   function First_Top_Level_Named_Actual (Args : String) return String is
      Depth : Natural := 0;
      Part_Start : Natural := Args'First;
      I : Natural := Args'First;

      function Named_Mark
        (Part_First : Natural;
         Part_Last  : Natural) return String
      is
         Clean : constant String :=
           (if Part_First <= Part_Last
            then Trim (Args (Part_First .. Part_Last))
            else "");
         Arrow : constant Natural := Top_Level_Arrow_Position (Clean);
      begin
         if Clean = "" or else Arrow = 0 then
            return "";
         end if;

         return Lower (Trim (Clean (Clean'First .. Arrow - 1)));
      end Named_Mark;
   begin
      while I <= Args'Last loop
         if Args (I) = '(' then
            Depth := Depth + 1;
         elsif Args (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Args (I) = ',' and then Depth = 0 then
            declare
               Mark : constant String := Named_Mark (Part_Start, I - 1);
            begin
               if Mark /= "" then
                  return Mark;
               end if;
            end;
            Part_Start := I + 1;
         end if;
         I := I + 1;
      end loop;

      return Named_Mark (Part_Start, Args'Last);
   end First_Top_Level_Named_Actual;

   function Normalized_Aspect_Mark (Association_Label : String) return String is
      Clean : constant String := Trim (Association_Label);
      Arrow : constant Natural := Top_Level_Arrow_Position (Clean);
      Raw   : constant String :=
        (if Arrow /= 0 then Trim (Clean (Clean'First .. Arrow - 1)) else Clean);
      Stop  : Natural := Raw'First;
   begin
      if Raw = "" then
         return "";
      end if;

      while Stop <= Raw'Last
        and then (Is_Local_Name_Char (Raw (Stop))
                  or else Raw (Stop) = '.'
                  or else Raw (Stop) = Character'Val (39))
      loop
         Stop := Stop + 1;
      end loop;

      if Stop = Raw'First then
         return "";
      end if;

      return Lower (Raw (Raw'First .. Stop - 1));
   end Normalized_Aspect_Mark;

   function Normalized_Choice_Text (Raw : String) return String is
      Clean : constant String := Trim (Raw);
      Colon : constant Natural := Ada.Strings.Fixed.Index (Clean, ":");
      Start : Natural := Clean'First;
   begin
      if Clean = "" then
         return "";
      end if;

      if Colon /= 0 and then Colon < Clean'Last then
         Start := Colon + 1;
      end if;

      return Lower (Trim (Clean (Start .. Clean'Last)));
   end Normalized_Choice_Text;

   function Choice_Count_In_List
     (Choice_List : String;
      Choice      : String) return Natural
   is
      Target : constant String := Normalized_Choice_Text (Choice);
      Before_Arrow : constant String :=
        (if Ada.Strings.Fixed.Index (Choice_List, "=>") /= 0 then
           Segment_Before (Choice_List, "=>")
         else
           Choice_List);
      List_Text : constant String :=
        (if Ada.Strings.Fixed.Index (Lower (Before_Arrow), "when") /= 0 then
           Segment_After (Before_Arrow, "when")
         else
           Before_Arrow);
      Start  : Natural := List_Text'First;
      Count  : Natural := 0;
   begin
      if Target = "" then
         return 0;
      end if;

      for I in List_Text'Range loop
         if List_Text (I) = '|' then
            declare
               Candidate : constant String :=
                 Normalized_Choice_Text (List_Text (Start .. I - 1));
            begin
               if Candidate = Target then
                  Count := Count + 1;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;

      if Start <= List_Text'Last then
         declare
            Candidate : constant String :=
              Normalized_Choice_Text (List_Text (Start .. List_Text'Last));
         begin
            if Candidate = Target then
               Count := Count + 1;
            end if;
         end;
      end if;

      return Count;
   end Choice_Count_In_List;

   function Looks_Like_Aggregate_Context (Expression_Text : String) return Boolean is
      Clean : constant String := Trim (Expression_Text);
      L     : constant String := Lower (Clean);
   begin
      return Clean /= ""
        and then (Clean (Clean'First) = '('
                  or else Ada.Strings.Fixed.Index (Clean, "'(") /= 0
                  or else Ada.Strings.Fixed.Index (Clean, ":= (") /= 0
                  or else Ada.Strings.Fixed.Index (L, "with delta") /= 0);
   end Looks_Like_Aggregate_Context;

end Editor.Ada_Declaration_Parser.Legality_Text_Helpers;
