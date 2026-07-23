with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Path_Helpers;
with Editor.Text_Helpers;

package body Editor.Quick_Open_Text_Helpers is

   function Normalize_For_Compare (Text : String) return String is
   begin
      return Editor.Path_Helpers.Normalize_For_Compare (Text, Lowercase => True);
   end Normalize_For_Compare;

   function Base_Name (Path : String) return String is
      Last_Sep : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Last_Sep := I;
         end if;
      end loop;

      if Last_Sep = 0 then
         return Path;
      elsif Last_Sep >= Path'Last then
         return "";
      else
         return Path (Last_Sep + 1 .. Path'Last);
      end if;
   end Base_Name;

   function Extension_Of (Path : String) return String is
      Name : constant String := Normalize_For_Compare (Base_Name (Path));
   begin
      for I in reverse Name'Range loop
         if Name (I) = '.' then
            return Name (I .. Name'Last);
         end if;
      end loop;
      return "";
   end Extension_Of;

   function Is_Ada_File (Path : String) return Boolean is
      Ext : constant String := Extension_Of (Path);
   begin
      return Ext = ".adb" or else Ext = ".ads";
   end Is_Ada_File;

   function Is_Doc_File (Path : String) return Boolean is
      Ext : constant String := Extension_Of (Path);
   begin
      return Ext = ".md" or else Ext = ".txt" or else Ext = ".rst" or else Ext = ".adoc";
   end Is_Doc_File;

   function Is_Test_File (Path : String) return Boolean is
      P : constant String := Normalize_For_Compare (Path);
      B : constant String := Normalize_For_Compare (Base_Name (Path));
      Ext : constant String := Extension_Of (Path);
      Stem_Last : constant Natural := (if Ext'Length > 0 then B'Last - Ext'Length else B'Last);
      Stem : constant String := (if Stem_Last >= B'First then B (B'First .. Stem_Last) else "");
   begin
      return Editor.Text_Helpers.Contains (P, "/test/")
        or else Editor.Text_Helpers.Contains (P, "/tests/")
        or else Editor.Text_Helpers.Starts_With (P, "test/")
        or else Editor.Text_Helpers.Starts_With (P, "tests/")
        or else Editor.Text_Helpers.Starts_With (B, "test_")
        or else Editor.Text_Helpers.Ends_With (Stem, "_test");
   end Is_Test_File;

   function In_Path_Scope (Path, Scope : String) return Boolean is
      P : constant String := Normalize_For_Compare (Path);
      S : constant String := Normalize_For_Compare (Scope);
   begin
      return S'Length = 0 or else Editor.Text_Helpers.Starts_With (P, S);
   end In_Path_Scope;

   function Is_Term_Boundary (Ch : Character) return Boolean is
   begin
      return Ch = '/' or else Ch = '-' or else Ch = '_' or else Ch = '.' or else Ch = ' ';
   end Is_Term_Boundary;

   function Has_Whitespace (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = ' ' or else Ch = Character'Val (9) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Whitespace;

   function Ordered_Characters_Match
     (Pattern : String;
      Text    : String) return Boolean
   is
      P : constant String := Normalize_For_Compare (Editor.Text_Helpers.Trim (Pattern));
      T : constant String := Normalize_For_Compare (Text);
      Pos : Natural := T'First;
      Found : Boolean;
   begin
      if P'Length = 0 then
         return True;
      elsif T'Length = 0 then
         return False;
      end if;

      for Ch of P loop
         if Ch = ' ' or else Ch = '/' then
            null;
         else
            Found := False;
            while Pos <= T'Last loop
               if T (Pos) = Ch then
                  Found := True;
                  Pos := Pos + 1;
                  exit;
               end if;
               Pos := Pos + 1;
            end loop;
            if not Found then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Ordered_Characters_Match;

   function Ordered_Basename_Fuzzy_Match
     (Pattern : String;
      Text    : String) return Boolean
   is
      P : constant String := Normalize_For_Compare (Editor.Text_Helpers.Trim (Pattern));
      T : constant String := Normalize_For_Compare (Text);
   begin
      return P'Length > 0
        and then T'Length > 0
        and then T (T'First) = P (P'First)
        and then Ordered_Characters_Match (P, T);
   end Ordered_Basename_Fuzzy_Match;

   function Ordered_Terms_Match
     (Query       : String;
      Path        : String;
      Prefix_Only : Boolean) return Boolean
   is
      Q : constant String := Normalize_For_Compare (Editor.Text_Helpers.Trim (Query));
      P : constant String := Normalize_For_Compare (Path);
      Term : Unbounded_String := Null_Unbounded_String;
      Search_From : Natural := P'First;

      function Find_Term (Term_Text : String) return Boolean is
      begin
         if Term_Text'Length = 0 then
            return True;
         end if;

         if P'Length = 0 or else Search_From > P'Last then
            return False;
         end if;

         for I in Search_From .. P'Last loop
            if I + Term_Text'Length - 1 <= P'Last
              and then P (I .. I + Term_Text'Length - 1) = Term_Text
              and then ((not Prefix_Only)
                        or else I = P'First
                        or else Is_Term_Boundary (P (I - 1)))
            then
               Search_From := I + Term_Text'Length;
               return True;
            end if;
         end loop;
         return False;
      end Find_Term;

      procedure Flush_Term (Ok : in out Boolean) is
      begin
         if Length (Term) > 0 then
            Ok := Ok and then Find_Term (To_String (Term));
            Term := Null_Unbounded_String;
         end if;
      end Flush_Term;

      Ok : Boolean := True;
   begin
      if Q'Length = 0 then
         return True;
      end if;

      for Ch of Q loop
         if Ch = ' ' or else Ch = Character'Val (9) then
            Flush_Term (Ok);
            if not Ok then
               return False;
            end if;
         else
            Append (Term, Ch);
         end if;
      end loop;
      Flush_Term (Ok);
      return Ok;
   end Ordered_Terms_Match;

   function Segment_Contains
     (Path : String;
      Term : String;
      Prefix_Only : Boolean) return Boolean
   is
      P : constant String := Normalize_For_Compare (Path);
      T : constant String := Normalize_For_Compare (Term);
      Segment_Start : Natural := P'First;
   begin
      if T'Length = 0 then
         return True;
      end if;

      for I in P'Range loop
         if P (I) = '/' then
            if I > Segment_Start then
               declare
                  Segment : constant String := P (Segment_Start .. I - 1);
               begin
                  if (Prefix_Only and then Editor.Text_Helpers.Starts_With (Segment, T))
                    or else ((not Prefix_Only) and then Editor.Text_Helpers.Contains (Segment, T))
                  then
                     return True;
                  end if;
               end;
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= P'Last then
         declare
            Segment : constant String := P (Segment_Start .. P'Last);
         begin
            return (Prefix_Only and then Editor.Text_Helpers.Starts_With (Segment, T))
              or else ((not Prefix_Only) and then Editor.Text_Helpers.Contains (Segment, T));
         end;
      end if;
      return False;
   end Segment_Contains;

end Editor.Quick_Open_Text_Helpers;
