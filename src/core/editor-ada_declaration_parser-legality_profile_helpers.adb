with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

package body Editor.Ada_Declaration_Parser.Legality_Profile_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

   function First_Paren_Segment (Text : String) return String is
      Open_Pos : Natural := 0;
      Depth    : Natural := 0;
   begin
      for I in Text'Range loop
         if Text (I) = '(' then
            if Open_Pos = 0 then
               Open_Pos := I;
            else
               Depth := Depth + 1;
            end if;
         elsif Text (I) = ')' and then Open_Pos /= 0 then
            if Depth = 0 then
               if I <= Open_Pos + 1 then
                  return "";
               end if;
               return Text (Open_Pos + 1 .. I - 1);
            else
               Depth := Depth - 1;
            end if;
         end if;
      end loop;

      return "";
   end First_Paren_Segment;

   function Last_Selected_Name_Part (Name : String) return String is
      Dot : Natural := 0;
   begin
      for I in Name'Range loop
         if Name (I) = '.' then
            Dot := I;
         end if;
      end loop;

      if Dot = 0 or else Dot = Name'Last then
         return Name;
      else
         return Name (Dot + 1 .. Name'Last);
      end if;
   end Last_Selected_Name_Part;

   function Formal_Count (Profile : String) return Natural is
      Params  : constant String := Trim (First_Paren_Segment (Profile));
      Count   : Natural := 1;
      Depth   : Natural := 0;
   begin
      if Params = "" then
         return 0;
      end if;

      for I in Params'Range loop
         if Params (I) = '(' then
            Depth := Depth + 1;
         elsif Params (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Params (I) = ';' and then Depth = 0 then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Formal_Count;

   function Formal_Text
     (Profile : String;
      Index   : Positive) return String
   is
      Params  : constant String := First_Paren_Segment (Profile);
      Depth   : Natural := 0;
      Current : Positive := 1;
      Start   : Natural := Params'First;
   begin
      if Params = "" then
         return "";
      end if;

      for I in Params'Range loop
         if Params (I) = '(' then
            Depth := Depth + 1;
         elsif Params (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Params (I) = ';' and then Depth = 0 then
            if Current = Index then
               return Trim (Params (Start .. I - 1));
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
      end loop;

      if Current = Index and then Start <= Params'Last then
         return Trim (Params (Start .. Params'Last));
      end if;

      return "";
   end Formal_Text;

   function Second_Formal_Text (Profile : String) return String is
   begin
      return Formal_Text (Profile, 2);
   end Second_Formal_Text;

   function Formal_Declaration_After_Colon (Formal : String) return String is
      Depth : Natural := 0;
   begin
      for I in Formal'Range loop
         if Formal (I) = '(' then
            Depth := Depth + 1;
         elsif Formal (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Formal (I) = ':' and then Depth = 0 then
            if I < Formal'Last then
               return Trim (Formal (I + 1 .. Formal'Last));
            else
               return "";
            end if;
         end if;
      end loop;

      return "";
   end Formal_Declaration_After_Colon;

   function Strip_Default_Expression (Text : String) return String is
      Depth : Natural := 0;
   begin
      if Text = "" then
         return "";
      end if;

      for I in Text'Range loop
         if Text (I) = '(' then
            Depth := Depth + 1;
         elsif Text (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
            end if;
         elsif Text (I) = ':'
           and then I < Text'Last
           and then Text (I + 1) = '='
           and then Depth = 0
         then
            if I = Text'First then
               return "";
            else
               return Trim (Text (Text'First .. I - 1));
            end if;
         end if;
      end loop;

      return Trim (Text);
   end Strip_Default_Expression;

   function Strip_Leading_Formal_Keyword
     (Text    : String;
      Keyword : String) return String
   is
      T : constant String := Trim (Text);
      L : constant String := Lower (T);
   begin
      if Starts_With_Word (L, Keyword) and then T'Length > Keyword'Length then
         return Trim (T (T'First + Keyword'Length .. T'Last));
      else
         return T;
      end if;
   end Strip_Leading_Formal_Keyword;

   function Formal_Subtype_Mark (Formal : String) return String is
      Work : constant String := Strip_Default_Expression
        (Formal_Declaration_After_Colon (Formal));
      T    : String (1 .. 512) := (others => ' ');
      Len  : Natural := Natural'Min (Work'Length, T'Length);
   begin
      if Len = 0 then
         return "";
      end if;

      T (1 .. Len) := Work (Work'First .. Work'First + Len - 1);

      loop
         declare
            Current : constant String := T (1 .. Len);
            Next    : constant String :=
              Strip_Leading_Formal_Keyword
                (Strip_Leading_Formal_Keyword
                   (Strip_Leading_Formal_Keyword
                      (Strip_Leading_Formal_Keyword
                         (Strip_Leading_Formal_Keyword
                            (Strip_Leading_Formal_Keyword
                               (Current, "aliased"),
                             "constant"),
                          "in out"),
                       "in"),
                    "out"),
                 "not null");
         begin
            exit when Next = Current;
            Len := Natural'Min (Next'Length, T'Length);
            if Len = 0 then
               return "";
            end if;
            T (1 .. Len) := Next (Next'First .. Next'First + Len - 1);
         end;
      end loop;

      return Trim (T (1 .. Len));
   end Formal_Subtype_Mark;

   function Is_Stream_Formal (Formal : String) return Boolean is
      D : constant String := Lower (Strip_Default_Expression
        (Formal_Declaration_After_Colon (Formal)));
   begin
      return Ada.Strings.Fixed.Index (D, "access") /= 0
        and then Ada.Strings.Fixed.Index (D, "root_stream_type'class") /= 0;
   end Is_Stream_Formal;

   function Has_Stream_Formal (Profile : String) return Boolean is
   begin
      return Is_Stream_Formal (Formal_Text (Profile, 1));
   end Has_Stream_Formal;

   function Has_Return_Profile (Profile : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Lower (Profile), " return ") /= 0;
   end Has_Return_Profile;

   function Local_Ends_With (Text, Suffix : String) return Boolean is
   begin
      return Suffix'Length <= Text'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Local_Ends_With;

   function Return_Profile_Matches_Target
     (Profile     : String;
      Target_Name : String) return Boolean
   is
      P      : constant String := Lower (Profile);
      T      : constant String := Lower (Last_Selected_Name_Part (Target_Name));
      Return_Pos : constant Natural := Ada.Strings.Fixed.Index (P, " return " );
   begin
      if Return_Pos = 0 or else T = "" then
         return False;
      end if;

      declare
         R : constant String := Trim (P (Return_Pos + 8 .. P'Last));
      begin
         return R = T
           or else Local_Ends_With (R, "." & T)
           or else R = T & "'class"
           or else Local_Ends_With (R, "." & T & "'class");
      end;
   end Return_Profile_Matches_Target;

   function Subtype_Mark_Matches_Target
     (Subtype_Mark : String;
      Target_Name  : String) return Boolean
   is
      S : constant String := Lower (Trim (Subtype_Mark));
      T : constant String := Lower (Last_Selected_Name_Part (Target_Name));
   begin
      if S = "" or else T = "" then
         return False;
      end if;

      return S = T
        or else Local_Ends_With (S, "." & T)
        or else S = T & "'class"
        or else Local_Ends_With (S, "." & T & "'class");
   end Subtype_Mark_Matches_Target;

   function Stream_Handler_Profile_Is_Compatible
     (Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name    : String;
      Profile        : String) return Boolean
   is
      A : constant String := Lower (To_String (Attribute_Name));
      N : constant Natural := Formal_Count (Profile);
   begin
      if Profile = "" or else not Has_Stream_Formal (Profile) then
         return False;
      end if;

      if A = "input" then
         return N = 1 and then Has_Return_Profile (Profile)
           and then Return_Profile_Matches_Target (Profile, Target_Name);
      else
         return N = 2
           and then Subtype_Mark_Matches_Target
             (Formal_Subtype_Mark (Formal_Text (Profile, 2)), Target_Name);
      end if;
   end Stream_Handler_Profile_Is_Compatible;

   function Stream_Handler_Mode_Is_Compatible
     (Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Profile        : String) return Boolean
   is
      A      : constant String := Lower (To_String (Attribute_Name));
      Second : constant String := Lower (Second_Formal_Text (Profile));
   begin
      if A = "input" then
         return True;
      elsif Second = "" then
         return False;
      elsif A = "read" then
         return Ada.Strings.Fixed.Index (Second, ": out ") /= 0
           or else Ada.Strings.Fixed.Index (Second, ":out ") /= 0;
      else
         return Ada.Strings.Fixed.Index (Second, ": out ") = 0
           and then Ada.Strings.Fixed.Index (Second, ":out ") = 0
           and then Ada.Strings.Fixed.Index (Second, " in out ") = 0
           and then Ada.Strings.Fixed.Index (Second, ":in out ") = 0;
      end if;
   end Stream_Handler_Mode_Is_Compatible;

end Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
