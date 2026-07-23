with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Lexical_Helpers; use Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Language_Model;
with Editor.Text_Helpers; use Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation is

   function Static_String_Bound_Value
     (Phase                       : Target_Derivation.Context;
      Name                        : String;
      Attr_Name                   : String;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Bound                       : out Natural) return Boolean
   is
      Image_Text : Unbounded_String;
      A          : constant String :=
        Lower (Editor.Ada_Language_Model.Normalize_Name (Attr_Name));

      function Static_Qualified_String_Bound_Value
        (Qualified_Text : String;
         Attribute_Name : String;
         Value          : out Natural) return Boolean
      is
         Q           : constant String := Trim_Static_Space (Qualified_Text);
         Quote_Index : Natural := 0;
         J           : Natural;
      begin
         Value := 0;

         if Q'Length < 4 or else Q (Q'Last) /= ')' then
            return False;
         end if;

         J := Q'First;
         while J <= Q'Last loop
            if Q (J) = '"' then
               J := J + 1;
               while J <= Q'Last loop
                  if Q (J) = '"' then
                     if J < Q'Last and then Q (J + 1) = '"' then
                        J := J + 2;
                     else
                        J := J + 1;
                        exit;
                     end if;
                  else
                     J := J + 1;
                  end if;
               end loop;
            elsif Q (J) = Character'Val (39)
              and then J + 2 <= Q'Last
              and then Q (J + 2) = Character'Val (39)
            then
               J := J + 3;
            elsif Q (J) = Character'Val (39) then
               declare
                  Open_Pos : Natural := J + 1;
               begin
                  while Open_Pos <= Q'Last and then Is_Static_Space (Q (Open_Pos)) loop
                     Open_Pos := Open_Pos + 1;
                  end loop;

                  if Open_Pos <= Q'Last and then Q (Open_Pos) = '(' then
                     Quote_Index := J;
                     exit;
                  end if;
               end;
               J := J + 1;
            else
               J := J + 1;
            end if;
         end loop;

         if Quote_Index = 0 or else Quote_Index = Q'First then
            return False;
         end if;

         declare
            Prefix_Text : constant String := Trim (Q (Q'First .. Quote_Index - 1));
            Open_Pos    : Natural := Quote_Index + 1;
            Qualified_Image : Unbounded_String;
         begin
            while Open_Pos <= Q'Last and then Is_Static_Space (Q (Open_Pos)) loop
               Open_Pos := Open_Pos + 1;
            end loop;

            if Open_Pos > Q'Last or else Q (Open_Pos) /= '(' then
               return False;
            end if;

            declare
               Inner_Text : constant String :=
                 Trim (Q (Open_Pos + 1 .. Q'Last - 1));
               Root_Text  : constant String :=
                 Target_Derivation.Static_Subtype_Root (Phase, Prefix_Text);
            begin
               if not Target_Derivation.Static_Type_Is_Character (Phase, Prefix_Text)
                 and then Root_Text /= "string"
               then
                  declare
                     T : constant String := Trim (Prefix_Text);
                  begin
                     if T = ""
                       or else not (T (T'First) in 'A' .. 'Z'
                                    or else T (T'First) in 'a' .. 'z')
                     then
                        return False;
                     end if;

                     for C of T loop
                        if not (C in 'A' .. 'Z'
                                or else C in 'a' .. 'z'
                                or else C in '0' .. '9'
                                or else C = '_')
                        then
                           return False;
                        end if;
                     end loop;
                  end;
               end if;

               if Root_Text /= "string" then
                  return False;
               end if;

               if not Static_String_Default_Value (Inner_Text, Qualified_Image) then
                  return False;
               end if;

               if not Target_Derivation.Static_String_Subtype_Length_Compatible
                        (Phase, Prefix_Text, Qualified_Image)
               then
                  return False;
               end if;

               if Target_Derivation.Static_String_Subtype_Bound_Value
                    (Phase, Prefix_Text, Attribute_Name, Value)
               then
                  return True;
               elsif Attribute_Name = "first" then
                  Value := 1;
                  return True;
               elsif Attribute_Name = "last" then
                  Value := To_String (Qualified_Image)'Length;
                  return True;
               elsif Attribute_Name = "length" then
                  Value := To_String (Qualified_Image)'Length;
                  return True;
               else
                  return False;
               end if;
            end;
         end;
      exception
         when Constraint_Error =>
            return False;
      end Static_Qualified_String_Bound_Value;
   begin
      Bound := 0;

      if Target_Derivation.Static_String_Subtype_Bound_Value
           (Phase, Name, A, Bound)
      then
         return True;
      end if;

      if Static_Qualified_String_Bound_Value (Name, A, Bound) then
         return True;
      end if;

      if Target_Derivation.Static_String_Constant_Bound_Value
           (Phase, Name, A, Bound)
      then
         return True;
      end if;

      if not Target_Derivation.Static_String_Constant_Value
               (Phase, Name, Image_Text)
      then
         if not Static_String_Default_Value (Name, Image_Text) then
            return False;
         end if;
      end if;

      if A = "first" then
         Bound := 1;
         return True;
      elsif A = "last" then
         Bound := To_String (Image_Text)'Length;
         return True;
      elsif A = "length" then
         Bound := To_String (Image_Text)'Length;
         return True;
      else
         return False;
      end if;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Bound_Value;

   function Static_String_Element_Position
     (Phase                       : Target_Derivation.Context;
      Indexed_Text                : String;
      Parse_Static_Integer        : not null Target_Derivation.Static_Integer_Parser;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Static_String_Bound_Value   : not null Target_Derivation.Static_String_Bound_Query;
      Position                    : out Natural) return Boolean
   is
      T           : constant String := Trim_Static_Space (Indexed_Text);
      Open_Paren  : Natural := 0;
      Int_Valid   : Boolean := False;
      Int_Index   : Integer := 0;
      First_Index : Natural := 1;
      Last_Index  : Natural := 0;
      Offset      : Natural := 0;
      Image_Text  : Unbounded_String;

      procedure Locate_Top_Level_Index_Open is
         Depth : Integer := 0;
         J     : Natural := T'First;
      begin
         while J <= T'Last loop
            if T (J) = '"' then
               J := J + 1;
               while J <= T'Last loop
                  if T (J) = '"' then
                     if J < T'Last and then T (J + 1) = '"' then
                        J := J + 2;
                     else
                        J := J + 1;
                        exit;
                     end if;
                  else
                     J := J + 1;
                  end if;
               end loop;
            elsif T (J) = Character'Val (39)
              and then J + 2 <= T'Last
              and then T (J + 2) = Character'Val (39)
            then
               J := J + 3;
            elsif T (J) = '(' then
               if Depth = 0 then
                  Open_Paren := J;
               end if;
               Depth := Depth + 1;
               J := J + 1;
            elsif T (J) = ')' then
               Depth := Depth - 1;
               if Depth < 0 then
                  Open_Paren := 0;
                  return;
               end if;
               J := J + 1;
            else
               J := J + 1;
            end if;
         end loop;

         if Depth /= 0 then
            Open_Paren := 0;
         end if;
      end Locate_Top_Level_Index_Open;
   begin
      Position := 0;
      if T = "" or else T (T'Last) /= ')' then
         return False;
      end if;

      Locate_Top_Level_Index_Open;

      if Open_Paren = 0 or else Open_Paren = T'First then
         return False;
      end if;

      declare
         Name_Text  : constant String :=
           Trim_Static_Space (T (T'First .. Open_Paren - 1));
         Index_Text : constant String :=
           Trim_Static_Space (T (Open_Paren + 1 .. T'Last - 1));
      begin
         if Name_Text = "" or else Index_Text = "" then
            return False;
         end if;

         Parse_Static_Integer (Index_Text, Int_Valid, Int_Index);
         if not Int_Valid or else Int_Index < 0 then
            return False;
         end if;

         if not Target_Derivation.Static_String_Constant_Value
                  (Phase, Name_Text, Image_Text)
         then
            if not Static_String_Default_Value (Name_Text, Image_Text) then
               return False;
            end if;
         end if;

         declare
            S : constant String := To_String (Image_Text);
         begin
            if not Static_String_Bound_Value
                     (Name_Text, "first", First_Index)
            then
               First_Index := 1;
            end if;

            if not Static_String_Bound_Value
                     (Name_Text, "last", Last_Index)
            then
               Last_Index := S'Length;
            end if;

            if Int_Index < Integer (First_Index)
              or else Int_Index > Integer (Last_Index)
            then
               return False;
            end if;

            Offset := Natural (Int_Index - Integer (First_Index) + 1);
            if Offset = 0 or else Offset > S'Length then
               return False;
            end if;

            Position := Character'Pos (S (S'First + Offset - 1));
            return True;
         end;
      end;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Element_Position;

   function Static_String_Slice_Value
     (Phase                       : Target_Derivation.Context;
      Slice_Text                  : String;
      Parse_Static_Integer        : not null Target_Derivation.Static_Integer_Parser;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Static_String_Bound_Value   : not null Target_Derivation.Static_String_Bound_Query;
      Image_Text                  : out Unbounded_String) return Boolean
   is
      T           : constant String := Trim_Static_Space (Slice_Text);
      Open_Paren  : Natural := 0;
      Dot_Dot     : Natural := 0;
      Depth       : Integer := 0;
      J           : Natural;
      Low_Valid   : Boolean := False;
      High_Valid  : Boolean := False;
      Low_Index   : Integer := 0;
      High_Index  : Integer := 0;
      First_Index : Natural := 1;
      Last_Index  : Natural := 0;
      Low_Offset  : Natural := 0;
      High_Offset : Natural := 0;
      Source_Text : Unbounded_String;

      procedure Locate_Top_Level_Slice_Open is
         Scan_Depth : Integer := 0;
         K          : Natural := T'First;
      begin
         while K <= T'Last loop
            if T (K) = '"' then
               K := K + 1;
               while K <= T'Last loop
                  if T (K) = '"' then
                     if K < T'Last and then T (K + 1) = '"' then
                        K := K + 2;
                     else
                        K := K + 1;
                        exit;
                     end if;
                  else
                     K := K + 1;
                  end if;
               end loop;
            elsif T (K) = Character'Val (39)
              and then K + 2 <= T'Last
              and then T (K + 2) = Character'Val (39)
            then
               K := K + 3;
            elsif T (K) = '(' then
               if Scan_Depth = 0 then
                  Open_Paren := K;
               end if;
               Scan_Depth := Scan_Depth + 1;
               K := K + 1;
            elsif T (K) = ')' then
               Scan_Depth := Scan_Depth - 1;
               if Scan_Depth < 0 then
                  Open_Paren := 0;
                  return;
               end if;
               K := K + 1;
            else
               K := K + 1;
            end if;
         end loop;

         if Scan_Depth /= 0 then
            Open_Paren := 0;
         end if;
      end Locate_Top_Level_Slice_Open;
   begin
      Image_Text := Null_Unbounded_String;

      if T = "" or else T (T'Last) /= ')' then
         return False;
      end if;

      Locate_Top_Level_Slice_Open;

      if Open_Paren = 0 or else Open_Paren = T'First then
         return False;
      end if;

      J := Open_Paren + 1;
      while J < T'Last loop
         if T (J) = '(' then
            Depth := Depth + 1;
            J := J + 1;
         elsif T (J) = ')' then
            Depth := Depth - 1;
            if Depth < 0 then
               return False;
            end if;
            J := J + 1;
         elsif T (J) = '.'
           and then J < T'Last - 1
           and then T (J + 1) = '.'
           and then Depth = 0
         then
            Dot_Dot := J;
            exit;
         else
            J := J + 1;
         end if;
      end loop;

      if Dot_Dot = 0 then
         return False;
      end if;

      declare
         Name_Text : constant String :=
           Trim_Static_Space (T (T'First .. Open_Paren - 1));
         Low_Text  : constant String :=
           Trim_Static_Space (T (Open_Paren + 1 .. Dot_Dot - 1));
         High_Text : constant String :=
           Trim_Static_Space (T (Dot_Dot + 2 .. T'Last - 1));
      begin
         if Name_Text = "" or else Low_Text = "" or else High_Text = "" then
            return False;
         end if;

         Parse_Static_Integer (Low_Text, Low_Valid, Low_Index);
         Parse_Static_Integer (High_Text, High_Valid, High_Index);
         if not Low_Valid
           or else not High_Valid
           or else Low_Index < 0
         then
            return False;
         end if;

         if not Target_Derivation.Static_String_Constant_Value
                  (Phase, Name_Text, Source_Text)
         then
            if not Static_String_Default_Value (Name_Text, Source_Text) then
               return False;
            end if;
         end if;

         declare
            S : constant String := To_String (Source_Text);
         begin
            if not Static_String_Bound_Value (Name_Text, "first", First_Index) then
               First_Index := 1;
            end if;

            if not Static_String_Bound_Value (Name_Text, "last", Last_Index) then
               Last_Index := S'Length;
            end if;

            if High_Index < Low_Index then
               if High_Index = Low_Index - 1
                 and then Low_Index >= Integer (First_Index)
                 and then Low_Index <= Integer (Last_Index) + 1
               then
                  Image_Text := Null_Unbounded_String;
                  return True;
               else
                  return False;
               end if;
            end if;

            if Low_Index < Integer (First_Index)
              or else High_Index > Integer (Last_Index)
            then
               return False;
            end if;

            Low_Offset := Natural (Low_Index - Integer (First_Index) + 1);
            High_Offset := Natural (High_Index - Integer (First_Index) + 1);
            if Low_Offset = 0
              or else High_Offset = 0
              or else Low_Offset > S'Length
              or else High_Offset > S'Length
            then
               return False;
            end if;

            Image_Text := To_Unbounded_String
              (S (S'First + Low_Offset - 1 ..
                  S'First + High_Offset - 1));
            return True;
         end;
      end;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Slice_Value;

   function Static_String_Default_Value
     (Phase                            : Target_Derivation.Context;
      Default_Text                     : String;
      Parse_Static_Integer             : not null Target_Derivation.Static_Integer_Parser;
      Static_Discrete_Default_Position : not null Target_Derivation.Static_Discrete_Position_Query;
      Static_Discrete_Position_Image   : not null Static_Discrete_Image_Query;
      Image_Text                       : out Unbounded_String) return Boolean
   is
      D      : constant String := Trim_Static_Space (Default_Text);
      Buffer : String (1 .. Natural'Max (D'Length, 1));
      Last   : Natural := 0;
      I      : Natural;

      function Recurse_Default
        (Text      : String;
         Image_Out : out Unbounded_String) return Boolean;

      function Recurse_Bound
        (Name      : String;
         Attr_Name : String;
         Bound     : out Natural) return Boolean;

      function Static_Character_Literal_Position
        (Literal_Text : String;
         Position     : out Natural) return Boolean
      is
         L : constant String := Trim (Literal_Text);
      begin
         Position := 0;

         if L'Length = 3
           and then L (L'First) = Character'Val (39)
           and then L (L'Last) = Character'Val (39)
         then
            Position := Character'Pos (L (L'First + 1));
            return True;
         elsif L'Length = 4
           and then L (L'First) = Character'Val (39)
           and then L (L'First + 1) = Character'Val (39)
           and then L (L'First + 2) = Character'Val (39)
           and then L (L'First + 3) = Character'Val (39)
         then
            Position := Character'Pos (Character'Val (39));
            return True;
         else
            return False;
         end if;
      exception
         when Constraint_Error =>
            return False;
      end Static_Character_Literal_Position;

      function Is_Simple_Static_Type_Name (Text : String) return Boolean is
         T : constant String := Trim (Text);
      begin
         if T = ""
           or else not (T (T'First) in 'A' .. 'Z'
                        or else T (T'First) in 'a' .. 'z')
         then
            return False;
         end if;

         for C of T loop
            if not (C in 'A' .. 'Z'
                    or else C in 'a' .. 'z'
                    or else C in '0' .. '9'
                    or else C = '_')
            then
               return False;
            end if;
         end loop;

         return True;
      end Is_Simple_Static_Type_Name;

      function Is_Whole_Parenthesized_String_Expression
        (Text : String) return Boolean
      is
         Depth : Integer := 0;
         J     : Natural := Text'First;
      begin
         if Text'Length < 2
           or else Text (Text'First) /= '('
           or else Text (Text'Last) /= ')'
         then
            return False;
         end if;

         while J <= Text'Last loop
            if Text (J) = '"' then
               J := J + 1;
               while J <= Text'Last loop
                  if Text (J) = '"' then
                     if J < Text'Last and then Text (J + 1) = '"' then
                        J := J + 2;
                     else
                        J := J + 1;
                        exit;
                     end if;
                  else
                     J := J + 1;
                  end if;
               end loop;
            elsif Text (J) = Character'Val (39)
              and then J + 2 <= Text'Last
              and then Text (J + 2) = Character'Val (39)
            then
               J := J + 3;
            elsif Text (J) = '(' then
               Depth := Depth + 1;
               J := J + 1;
            elsif Text (J) = ')' then
               Depth := Depth - 1;
               if Depth = 0 and then J < Text'Last then
                  return False;
               elsif Depth < 0 then
                  return False;
               end if;
               J := J + 1;
            else
               J := J + 1;
            end if;
         end loop;

         return Depth = 0;
      end Is_Whole_Parenthesized_String_Expression;

      function Top_Level_Concat_Index (Text : String) return Natural is
         Depth : Integer := 0;
         J     : Natural := Text'First;
      begin
         while J <= Text'Last loop
            if Text (J) = '"' then
               J := J + 1;
               while J <= Text'Last loop
                  if Text (J) = '"' then
                     if J < Text'Last and then Text (J + 1) = '"' then
                        J := J + 2;
                     else
                        J := J + 1;
                        exit;
                     end if;
                  else
                     J := J + 1;
                  end if;
               end loop;
            elsif Text (J) = Character'Val (39)
              and then J + 2 <= Text'Last
              and then Text (J + 2) = Character'Val (39)
            then
               J := J + 3;
            elsif Text (J) = '(' then
               Depth := Depth + 1;
               J := J + 1;
            elsif Text (J) = ')' then
               Depth := Depth - 1;
               if Depth < 0 then
                  return 0;
               end if;
               J := J + 1;
            elsif Text (J) = '&' and then Depth = 0 then
               return J;
            else
               J := J + 1;
            end if;
         end loop;
         return 0;
      end Top_Level_Concat_Index;

      function Static_String_Qualified_Value
        (Text       : String;
         Image_Out  : out Unbounded_String) return Boolean
      is
         Q : constant String := Trim_Static_Space (Text);
         Quote_Index : Natural := 0;
         Open_Pos    : Natural := 0;
      begin
         Image_Out := Null_Unbounded_String;

         if Q'Length < 4 or else Q (Q'Last) /= ')' then
            return False;
         end if;

         for J in Q'Range loop
            if Q (J) = Character'Val (39) then
               Quote_Index := J;
               exit;
            end if;
         end loop;

         if Quote_Index = 0 or else Quote_Index = Q'First then
            return False;
         end if;

         Open_Pos := Quote_Index + 1;
         while Open_Pos <= Q'Last and then Is_Static_Space (Q (Open_Pos)) loop
            Open_Pos := Open_Pos + 1;
         end loop;

         if Open_Pos > Q'Last or else Q (Open_Pos) /= '(' then
            return False;
         end if;

         declare
            Prefix_Text : constant String :=
              Trim (Q (Q'First .. Quote_Index - 1));
            Inner_Text  : constant String :=
              Trim (Q (Open_Pos + 1 .. Q'Last - 1));
            Root_Text   : constant String :=
              Target_Derivation.Static_Subtype_Root (Phase, Prefix_Text);
         begin
            if not Is_Simple_Static_Type_Name (Prefix_Text) then
               return False;
            end if;

            if Root_Text = "string" or else Root_Text = "standard.string" then
               if Recurse_Default (Inner_Text, Image_Out) then
                  return Target_Derivation.Static_String_Subtype_Length_Compatible
                    (Phase, Prefix_Text, Image_Out);
               else
                  return False;
               end if;
            else
               return False;
            end if;
         end;
      exception
         when Constraint_Error =>
            return False;
      end Static_String_Qualified_Value;

      function Recurse_Default
        (Text      : String;
         Image_Out : out Unbounded_String) return Boolean
      is
      begin
         return Static_String_Default_Value
           (Phase,
            Text,
            Parse_Static_Integer,
            Static_Discrete_Default_Position,
            Static_Discrete_Position_Image,
            Image_Out);
      end Recurse_Default;

      function Recurse_Bound
        (Name      : String;
         Attr_Name : String;
         Bound     : out Natural) return Boolean
      is
      begin
         return Static_String_Bound_Value
           (Phase,
            Name,
            Attr_Name,
            Recurse_Default'Unrestricted_Access,
            Bound);
      end Recurse_Bound;
   begin
      Image_Text := Null_Unbounded_String;

      if Is_Whole_Parenthesized_String_Expression (D) then
         return Recurse_Default
           (Trim (D (D'First + 1 .. D'Last - 1)), Image_Text);
      end if;

      declare
         Qualified_Image : Unbounded_String;
      begin
         if Static_String_Qualified_Value (D, Qualified_Image) then
            Image_Text := Qualified_Image;
            return True;
         end if;
      end;

      declare
         Existing_Image : Unbounded_String;
      begin
         if Target_Derivation.Static_String_Constant_Value
              (Phase, D, Existing_Image)
         then
            Image_Text := Existing_Image;
            return True;
         end if;
      end;

      declare
         Amp : constant Natural := Top_Level_Concat_Index (D);
      begin
         if Amp /= 0 then
            declare
               Left_Image  : Unbounded_String;
               Right_Image : Unbounded_String;
            begin
               if Amp = D'First or else Amp = D'Last then
                  return False;
               end if;

               if Recurse_Default
                    (Trim (D (D'First .. Amp - 1)), Left_Image)
                 and then Recurse_Default
                    (Trim (D (Amp + 1 .. D'Last)), Right_Image)
               then
                  Image_Text := Left_Image & Right_Image;
                  return True;
               else
                  return False;
               end if;
            end;
         end if;
      end;

      declare
         Slice_Image : Unbounded_String;
      begin
         if Static_String_Slice_Value
              (Phase,
               D,
               Parse_Static_Integer,
               Recurse_Default'Unrestricted_Access,
               Recurse_Bound'Unrestricted_Access,
               Slice_Image)
         then
            Image_Text := Slice_Image;
            return True;
         end if;
      end;

      declare
         Element_Position : Natural := 0;
      begin
         if Static_String_Element_Position
              (Phase,
               D,
               Parse_Static_Integer,
               Recurse_Default'Unrestricted_Access,
               Recurse_Bound'Unrestricted_Access,
               Element_Position)
           and then Element_Position <= Character'Pos (Character'Last)
         then
            Image_Text := To_Unbounded_String
              ("" & Character'Val (Element_Position));
            return True;
         end if;
      end;

      declare
         Char_Position : Natural := 0;
      begin
         if Static_Character_Literal_Position (D, Char_Position)
           and then Char_Position <= Character'Pos (Character'Last)
         then
            Image_Text := To_Unbounded_String
              ("" & Character'Val (Char_Position));
            return True;
         end if;
      end;

      declare
         Char_Position : Natural := 0;
      begin
         if Target_Derivation.Static_Character_Constant_Position
              (Phase, D, Char_Position)
           and then Char_Position <= Character'Pos (Character'Last)
         then
            Image_Text := To_Unbounded_String
              ("" & Character'Val (Char_Position));
            return True;
         end if;
      end;

      declare
         Char_Position : Natural := 0;
      begin
         if Static_Discrete_Default_Position ("Character", D, Char_Position)
           and then Char_Position <= Character'Pos (Character'Last)
         then
            Image_Text := To_Unbounded_String
              ("" & Character'Val (Char_Position));
            return True;
         end if;
      end;

      if D'Length >= 2
        and then D (D'First) = '"'
        and then D (D'Last) = '"'
      then
         I := D'First + 1;
         while I <= D'Last - 1 loop
            if D (I) = '"' then
               if I < D'Last - 1 and then D (I + 1) = '"' then
                  Last := Last + 1;
                  Buffer (Last) := '"';
                  I := I + 2;
               else
                  return False;
               end if;
            else
               Last := Last + 1;
               Buffer (Last) := D (I);
               I := I + 1;
            end if;
         end loop;

         Image_Text := To_Unbounded_String (Buffer (Buffer'First .. Last));
         return True;
      end if;

      declare
         Open_Paren : Natural := 0;
         Last_Quote : Natural := 0;
      begin
         for J in D'Range loop
            if D (J) = '(' then
               Open_Paren := J;
               exit;
            end if;
         end loop;

         if Open_Paren /= 0 and then D (D'Last) = ')' then
            declare
               Head : constant String := Trim (D (D'First .. Open_Paren - 1));
               Args : constant String := Trim (D (Open_Paren + 1 .. D'Last - 1));
            begin
               for J in Head'Range loop
                  if Head (J) = Character'Val (39) then
                     Last_Quote := J;
                  end if;
               end loop;

               if Last_Quote /= 0 and then Last_Quote < Head'Last then
                  declare
                     Prefix_Text : constant String :=
                       Trim (Head (Head'First .. Last_Quote - 1));
                     Attr_Name : constant String :=
                       Lower (Editor.Ada_Language_Model.Normalize_Name
                         (Trim (Head (Last_Quote + 1 .. Head'Last))));
                     Prefix_Norm : constant String :=
                       Normalize_Static_Attribute_Spacing
                         (Editor.Ada_Language_Model.Normalize_Name (Prefix_Text));
                     Base_Suffix : constant String := "'base";
                     Prefix_Base : Unbounded_String :=
                       To_Unbounded_String (Prefix_Norm);
                     Arg_Pos : Natural := 0;
                  begin
                     if Prefix_Norm'Length > Base_Suffix'Length
                       and then Prefix_Norm
                         (Prefix_Norm'Last - Base_Suffix'Length + 1 ..
                          Prefix_Norm'Last) = Base_Suffix
                     then
                        Prefix_Base :=
                          To_Unbounded_String
                            (Prefix_Norm
                               (Prefix_Norm'First ..
                                Prefix_Norm'Last - Base_Suffix'Length));
                     end if;

                     if Attr_Name = "image"
                       and then Static_Discrete_Default_Position
                         (To_String (Prefix_Base), Args, Arg_Pos)
                       and then Target_Derivation.Static_Value_In_Type_Range
                         (Phase, To_String (Prefix_Base), Arg_Pos)
                     then
                        return Static_Discrete_Position_Image
                          (To_String (Prefix_Base), Arg_Pos, Image_Text);
                     elsif Attr_Name = "image" then
                        declare
                           Int_Value : Integer := 0;
                           Has_Low   : Boolean := False;
                           Low       : Integer := 0;
                           Has_High  : Boolean := False;
                           High      : Integer := 0;
                           In_Range  : Boolean := True;
                        begin
                           Parse_Static_Integer (Args, In_Range, Int_Value);
                           if In_Range then
                              if Target_Derivation.Static_Type_Range
                                   (Phase,
                                    To_String (Prefix_Base),
                                    Has_Low, Low, Has_High, High)
                              then
                                 if Has_Low and then Int_Value < Low then
                                    In_Range := False;
                                 elsif Has_High and then Int_Value > High then
                                    In_Range := False;
                                 end if;
                              else
                                 In_Range := False;
                              end if;

                              if In_Range then
                                 Image_Text :=
                                   To_Unbounded_String
                                     (Integer'Image (Int_Value));
                                 return True;
                              end if;
                           end if;
                        end;
                     end if;
                  end;
               end if;
            end;
         end if;
      exception
         when Constraint_Error =>
            null;
      end;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_String_Default_Value;

   function Static_Discrete_Value_String_Position
     (Phase                            : Target_Derivation.Context;
      Type_Name                        : String;
      String_Text                      : String;
      Static_String_Default_Value      : not null Target_Derivation.Static_String_Default_Query;
      Static_Discrete_Literal_Position : not null Static_Discrete_Literal_Query;
      Static_Discrete_Default_Position : not null Target_Derivation.Static_Discrete_Position_Query;
      Position                         : out Natural) return Boolean
   is
      T : constant String := Trim (String_Text);
      Buffer : String (1 .. Natural'Max (T'Length, 1));
      Last   : Natural := 0;
      I      : Natural;
   begin
      Position := 0;

      declare
         Image_Text : Unbounded_String;
      begin
         if Static_String_Default_Value (T, Image_Text) then
            return Static_Discrete_Literal_Position
              (Type_Name, Trim (To_String (Image_Text)), Position);
         end if;
      end;

      if T'Length >= 2
        and then T (T'First) = '"'
        and then T (T'Last) = '"'
      then
         I := T'First + 1;
         while I <= T'Last - 1 loop
            if T (I) = '"' then
               if I < T'Last - 1 and then T (I + 1) = '"' then
                  Last := Last + 1;
                  Buffer (Last) := '"';
                  I := I + 2;
               else
                  return False;
               end if;
            else
               Last := Last + 1;
               Buffer (Last) := T (I);
               I := I + 1;
            end if;
         end loop;

         if Last = 0 then
            return False;
         end if;

         return Static_Discrete_Literal_Position
           (Type_Name, Trim (Buffer (Buffer'First .. Last)), Position);
      end if;

      declare
         String_Image : Unbounded_String;
      begin
         if Target_Derivation.Static_String_Constant_Value
              (Phase, T, String_Image)
         then
            return Static_Discrete_Literal_Position
              (Type_Name, Trim (To_String (String_Image)), Position);
         end if;
      end;

      declare
         Open_Paren : Natural := 0;
         Last_Quote : Natural := 0;
      begin
         for J in T'Range loop
            if T (J) = '(' then
               Open_Paren := J;
               exit;
            end if;
         end loop;

         if Open_Paren /= 0 and then T (T'Last) = ')' then
            declare
               Head : constant String := Trim (T (T'First .. Open_Paren - 1));
               Args : constant String := Trim (T (Open_Paren + 1 .. T'Last - 1));
            begin
               for J in Head'Range loop
                  if Head (J) = Character'Val (39) then
                     Last_Quote := J;
                  end if;
               end loop;

               if Last_Quote /= 0 and then Last_Quote < Head'Last then
                  declare
                     Prefix_Text : constant String :=
                       Trim (Head (Head'First .. Last_Quote - 1));
                     Attr_Name : constant String :=
                       Lower (Editor.Ada_Language_Model.Normalize_Name
                         (Trim (Head (Last_Quote + 1 .. Head'Last))));
                     Prefix_Norm : constant String :=
                       Normalize_Static_Attribute_Spacing
                         (Editor.Ada_Language_Model.Normalize_Name (Prefix_Text));
                     Base_Suffix : constant String := "'base";
                     Prefix_Base : Unbounded_String :=
                       To_Unbounded_String (Prefix_Norm);
                     Arg_Pos : Natural := 0;
                  begin
                     if Prefix_Norm'Length > Base_Suffix'Length
                       and then Prefix_Norm
                         (Prefix_Norm'Last - Base_Suffix'Length + 1 ..
                          Prefix_Norm'Last) = Base_Suffix
                     then
                        Prefix_Base :=
                          To_Unbounded_String
                            (Prefix_Norm
                               (Prefix_Norm'First ..
                                Prefix_Norm'Last - Base_Suffix'Length));
                     end if;

                     if Attr_Name = "image"
                       and then Target_Derivation.Static_Subtype_Root
                         (Phase, To_String (Prefix_Base)) =
                           Target_Derivation.Static_Subtype_Root
                             (Phase, Type_Name)
                       and then Static_Discrete_Default_Position
                         (To_String (Prefix_Base), Args, Arg_Pos)
                       and then Target_Derivation.Static_Value_In_Type_Range
                         (Phase, Type_Name, Arg_Pos)
                     then
                        Position := Arg_Pos;
                        return True;
                     end if;
                  end;
               end if;
            end;
         end if;
      exception
         when Constraint_Error =>
            null;
      end;

      return False;
   exception
      when Constraint_Error =>
         return False;
   end Static_Discrete_Value_String_Position;

   function Static_Integer_Value_String_Value
     (Phase                       : Target_Derivation.Context;
      Type_Name                   : String;
      String_Text                 : String;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Parse_Static_Integer        : not null Target_Derivation.Static_Integer_Parser;
      Value                       : out Integer) return Boolean
   is
      T : constant String := Trim (String_Text);
      Image_Text : Unbounded_String;
      Parsed     : Integer := 0;
      Valid      : Boolean := False;
      Has_Low    : Boolean := False;
      Low        : Integer := 0;
      Has_High   : Boolean := False;
      High       : Integer := 0;
   begin
      Value := 0;

      if not Static_String_Default_Value (T, Image_Text) then
         return False;
      end if;

      Parse_Static_Integer (Trim (To_String (Image_Text)), Valid, Parsed);
      if not Valid then
         return False;
      end if;

      if Target_Derivation.Static_Type_Range
           (Phase, Type_Name, Has_Low, Low, Has_High, High)
      then
         if Has_Low and then Parsed < Low then
            return False;
         elsif Has_High and then Parsed > High then
            return False;
         end if;
      else
         return False;
      end if;

      Value := Parsed;
      return True;
   exception
      when Constraint_Error =>
         return False;
   end Static_Integer_Value_String_Value;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation;
