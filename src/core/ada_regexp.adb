with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNAT.Regpat;

package body Ada_Regexp is

   function Is_Word_Char (Ch : Character) return Boolean is
   begin
      return (Ch >= 'A' and then Ch <= 'Z')
        or else (Ch >= 'a' and then Ch <= 'z')
        or else (Ch >= '0' and then Ch <= '9')
        or else Ch = '_';
   end Is_Word_Char;

   function Whole_Word_Match
     (Text  : String;
      First : Natural;
      Last  : Natural) return Boolean
   is
   begin
      if First = 0 then
         return False;
      end if;

      return (First = Text'First or else not Is_Word_Char (Text (First - 1)))
        and then (Last >= Text'Last or else not Is_Word_Char (Text (Last + 1)));
   end Whole_Word_Match;

   function Flags_For (Case_Sensitive : Boolean) return GNAT.Regpat.Regexp_Flags is
   begin
      if Case_Sensitive then
         return GNAT.Regpat.No_Flags;
      else
         return GNAT.Regpat.Case_Insensitive;
      end if;
   end Flags_For;

   function Compile (Expression : String) return Compile_Result is
      Result : Compile_Result;
   begin
      declare
         Matcher : constant GNAT.Regpat.Pattern_Matcher :=
           GNAT.Regpat.Compile (Expression);
         pragma Unreferenced (Matcher);
      begin
         Result.Status := Compile_Ok;
         Result.Expression.Pattern := To_Unbounded_String (Expression);
         return Result;
      end;
   exception
      when GNAT.Regpat.Expression_Error | Storage_Error =>
         Result.Status := Compile_Error;
         Result.Expression.Pattern := To_Unbounded_String (Expression);
         return Result;
   end Compile;

   function Find_From
     (Expression : Regexp;
      Text       : String;
      From       : Positive;
      Options    : Match_Options) return Match_Result
   is
      Pattern : constant String := To_String (Expression.Pattern);
      Start   : Positive := From;
      Matches : GNAT.Regpat.Match_Array (0 .. 0);
   begin
      if Options.Max_Steps = 0 then
         return (Status => Match_Limit_Exceeded, First => 0, Last => 0);
      elsif Pattern'Length = 0 or else Text'Length = 0 or else From > Text'Last then
         return (Status => No_Match, First => 0, Last => 0);
      end if;

      while Start <= Text'Last loop
         declare
            Matcher : constant GNAT.Regpat.Pattern_Matcher :=
              GNAT.Regpat.Compile
                (Pattern, Flags => Flags_For (Options.Case_Sensitive));
         begin
            GNAT.Regpat.Match
              (Self       => Matcher,
               Data       => Text,
               Matches    => Matches,
               Data_First => Start,
               Data_Last  => Text'Last);
         end;

         if Matches (0).First = GNAT.Regpat.No_Match.First
           and then Matches (0).Last = GNAT.Regpat.No_Match.Last
         then
            return (Status => No_Match, First => 0, Last => 0);
         elsif not Options.Whole_Word
           or else Whole_Word_Match (Text, Matches (0).First, Matches (0).Last)
         then
            return
              (Status => Match_Ok,
               First  => Matches (0).First,
               Last   => Matches (0).Last);
         elsif Matches (0).Last < Start then
            Start := Start + 1;
         elsif Matches (0).Last >= Text'Last then
            return (Status => No_Match, First => 0, Last => 0);
         else
            Start := Matches (0).Last + 1;
         end if;
      end loop;

      return (Status => No_Match, First => 0, Last => 0);
   exception
      when GNAT.Regpat.Expression_Error | Storage_Error =>
         return (Status => Match_Error, First => 0, Last => 0);
   end Find_From;

   function Status_Image (Status : Regexp_Status) return String is
   begin
      case Status is
         when Compile_Ok => return "compile ok";
         when Compile_Error => return "invalid regular expression";
         when Match_Ok => return "match ok";
         when No_Match => return "no match";
         when Match_Limit_Exceeded => return "regular expression match limit exceeded";
         when Match_Error => return "regular expression match failed";
      end case;
   end Status_Image;

end Ada_Regexp;
