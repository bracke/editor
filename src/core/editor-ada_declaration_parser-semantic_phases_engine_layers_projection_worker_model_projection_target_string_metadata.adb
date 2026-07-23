with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Lexical_Helpers; use Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Language_Model;
with Editor.Text_Helpers; use Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Metadata is

   procedure Register_Static_String_Constant
     (Phase                       : in out Target_Derivation.Context;
      Name                        : String;
      Type_Name                   : String;
      Default_Text                : String;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query)
   is
      N           : constant String := Editor.Ada_Language_Model.Normalize_Name (Name);
      Image_Text  : Unbounded_String;
      Has_First   : Boolean := False;
      Has_Last    : Boolean := False;
      First_Bound : Natural := 1;
      Last_Bound  : Natural := 0;
   begin
      if N = "" then
         return;
      end if;

      if not Static_String_Default_Value (Default_Text, Image_Text) then
         return;
      end if;

      if not Target_Derivation.Static_String_Subtype_Length_Compatible
                  (Phase, Type_Name, Image_Text)
      then
         return;
      end if;

      Has_First := Target_Derivation.Static_String_Subtype_Bound_Value
        (Phase, Type_Name, "first", First_Bound);
      Has_Last := Target_Derivation.Static_String_Subtype_Bound_Value
        (Phase, Type_Name, "last", Last_Bound);
      if not (Has_First and then Has_Last) then
         Has_First := False;
         Has_Last := False;
      end if;

      Target_Derivation.Store_Static_String_Constant
        (Phase,
         N,
         Image_Text,
         Has_First,
         First_Bound,
         Has_Last,
         Last_Bound);
   end Register_Static_String_Constant;

   procedure Store_Static_String_Subtype_Bounds_From_Range_Attribute
     (Phase                                  : in out Target_Derivation.Context;
      Name                                   : String;
      Range_Text                             : String;
      Parse_Static_Integer                   : not null Target_Derivation.Static_Integer_Parser;
      Normalize_Character_Pos_Static_Operands : not null Target_Derivation.String_To_String;
      Static_String_Default_Value            : not null Target_Derivation.Static_String_Default_Query;
      Static_String_Bound_Value              : not null Target_Derivation.Static_String_Bound_Query)
   is
      T           : constant String := Trim (Range_Text);
      Quote_Index : Natural := 0;
      First_Value : Integer := 0;
      Last_Value  : Integer := 0;

      function Strip_Range_Subtype_Indication (Text : String) return String is
         S        : constant String := Trim (Text);
         L        : constant String := Lower (S);
         Range_At : Natural := 0;
      begin
         declare
            J : Natural := L'First;
         begin
            while J <= L'Last loop
               if L (J) = '"' then
                  J := J + 1;
                  while J <= L'Last loop
                     if L (J) = '"' then
                        if J < L'Last and then L (J + 1) = '"' then
                           J := J + 2;
                        else
                           J := J + 1;
                           exit;
                        end if;
                     else
                        J := J + 1;
                     end if;
                  end loop;
               elsif L (J) = Character'Val (39)
                 and then J + 2 <= L'Last
                 and then L (J + 2) = Character'Val (39)
               then
                  J := J + 3;
               elsif J + 4 <= L'Last
                 and then L (J .. J + 4) = "range"
                 and then (J = L'First or else not Is_Word_Char (L (J - 1)))
                 and then (J + 5 > L'Last or else not Is_Word_Char (L (J + 5)))
                 and then (J = L'First or else S (J - 1) /= Character'Val (39))
               then
                  Range_At := J;
                  exit;
               else
                  J := J + 1;
               end if;
            end loop;
         end;

         if Range_At /= 0 and then Range_At + 5 <= S'Last then
            return Trim (S (Range_At + 5 .. S'Last));
         elsif Range_At /= 0 then
            return "";
         else
            return S;
         end if;
      exception
         when Constraint_Error =>
            return S;
      end Strip_Range_Subtype_Indication;
   begin
      if T = "" then
         return;
      end if;

      declare
         Source_Text : constant String := Strip_Range_Subtype_Indication (T);
      begin
         if Source_Text = "" then
            return;
         end if;

         declare
            J     : Natural := Source_Text'First;
            Depth : Integer := 0;
         begin
            while J <= Source_Text'Last loop
               if Source_Text (J) = '"' then
                  J := J + 1;
                  while J <= Source_Text'Last loop
                     if Source_Text (J) = '"' then
                        if J < Source_Text'Last
                          and then Source_Text (J + 1) = '"'
                        then
                           J := J + 2;
                        else
                           J := J + 1;
                           exit;
                        end if;
                     else
                        J := J + 1;
                     end if;
                  end loop;
               elsif Source_Text (J) = Character'Val (39)
                 and then J + 2 <= Source_Text'Last
                 and then Source_Text (J + 2) = Character'Val (39)
               then
                  J := J + 3;
               elsif Source_Text (J) = '(' then
                  Depth := Depth + 1;
                  J := J + 1;
               elsif Source_Text (J) = ')' then
                  Depth := Depth - 1;
                  if Depth < 0 then
                     return;
                  end if;
                  J := J + 1;
               elsif Source_Text (J) = Character'Val (39) then
                  declare
                     Designator_Start : Natural := J + 1;
                     Designator_Stop  : Natural := 0;
                  begin
                     while Designator_Start <= Source_Text'Last
                       and then Is_Static_Space (Source_Text (Designator_Start))
                     loop
                        Designator_Start := Designator_Start + 1;
                     end loop;

                     if Designator_Start <= Source_Text'Last
                       and then Source_Text (Designator_Start) = '('
                     then
                        J := Designator_Start;
                     elsif Depth = 0
                       and then Designator_Start <= Source_Text'Last
                       and then (Source_Text (Designator_Start) in 'A' .. 'Z'
                                 or else Source_Text (Designator_Start) in 'a' .. 'z')
                     then
                        Designator_Stop := Designator_Start;
                        while Designator_Stop + 1 <= Source_Text'Last
                          and then (Source_Text (Designator_Stop + 1) in 'A' .. 'Z'
                                    or else Source_Text (Designator_Stop + 1) in 'a' .. 'z'
                                    or else Source_Text (Designator_Stop + 1) in '0' .. '9'
                                    or else Source_Text (Designator_Stop + 1) = '_')
                        loop
                           Designator_Stop := Designator_Stop + 1;
                        end loop;

                        if Lower (Source_Text (Designator_Start .. Designator_Stop))
                          = "range"
                        then
                           Quote_Index := J;
                           exit;
                        else
                           J := Designator_Stop + 1;
                        end if;
                     else
                        J := J + 1;
                     end if;
                  end;
               else
                  J := J + 1;
               end if;
            end loop;
         end;

         if Quote_Index = 0 or else Quote_Index = Source_Text'First then
            return;
         end if;

         declare
            Prefix_Text : constant String :=
              Trim (Source_Text (Source_Text'First .. Quote_Index - 1));
            Raw_Attr    : constant String :=
              Trim (Source_Text (Quote_Index + 1 .. Source_Text'Last));
            Attr_Name   : Unbounded_String;
            Dim_Text    : Unbounded_String;
         begin
            declare
               Open_Pos  : Natural := 0;
               Close_Pos : Natural := 0;
               Depth     : Integer := 0;
               Has_Dim   : Boolean := False;
            begin
               if Raw_Attr = "" then
                  return;
               end if;

               declare
                  J : Natural := Raw_Attr'First;
               begin
                  while J <= Raw_Attr'Last loop
                     if Raw_Attr (J) = '"' then
                        J := J + 1;
                        while J <= Raw_Attr'Last loop
                           if Raw_Attr (J) = '"' then
                              if J < Raw_Attr'Last
                                and then Raw_Attr (J + 1) = '"'
                              then
                                 J := J + 2;
                              else
                                 J := J + 1;
                                 exit;
                              end if;
                           else
                              J := J + 1;
                           end if;
                        end loop;
                     elsif Raw_Attr (J) = Character'Val (39)
                       and then J + 2 <= Raw_Attr'Last
                       and then Raw_Attr (J + 2) = Character'Val (39)
                     then
                        J := J + 3;
                     elsif Raw_Attr (J) = '(' then
                        if Depth = 0 and then Open_Pos = 0 then
                           Open_Pos := J;
                        end if;
                        Depth := Depth + 1;
                        J := J + 1;
                     elsif Raw_Attr (J) = ')' then
                        Depth := Depth - 1;
                        if Depth = 0 then
                           Close_Pos := J;
                        elsif Depth < 0 then
                           return;
                        end if;
                        J := J + 1;
                     else
                        J := J + 1;
                     end if;
                  end loop;
               end;

               if Open_Pos = 0 then
                  Attr_Name := To_Unbounded_String
                    (Lower (Editor.Ada_Language_Model.Normalize_Name (Raw_Attr)));
               else
                  if Close_Pos = 0
                    or else Close_Pos < Open_Pos
                    or else Trim (Raw_Attr (Close_Pos + 1 .. Raw_Attr'Last)) /= ""
                  then
                     return;
                  end if;

                  Attr_Name := To_Unbounded_String
                    (Lower
                       (Editor.Ada_Language_Model.Normalize_Name
                          (Trim (Raw_Attr (Raw_Attr'First .. Open_Pos - 1)))));
                  Dim_Text := To_Unbounded_String
                    (Trim (Raw_Attr (Open_Pos + 1 .. Close_Pos - 1)));
                  declare
                     Dim_Source : constant String := To_String (Dim_Text);
                     Normalized_Dim_Source : constant String :=
                       Normalize_Character_Pos_Static_Operands (Dim_Source);
                     Signed_Dim : Integer := 0;
                  begin
                     Parse_Static_Integer
                       (Normalized_Dim_Source, Has_Dim, Signed_Dim);
                     if not Has_Dim or else Signed_Dim /= 1 then
                        return;
                     end if;
                  end;
               end if;
            end;

            if To_String (Attr_Name) /= "range" then
               return;
            end if;

            declare
               Subtype_Name : constant String :=
                 Target_Derivation.Canonical_Static_Type_Name (Prefix_Text);
               Constant_Name : constant String :=
                 Editor.Ada_Language_Model.Normalize_Name (Prefix_Text);
            begin
               if Target_Derivation.Static_String_Subtype_Bounds
                    (Phase, Subtype_Name, First_Value, Last_Value)
               then
                  Target_Derivation.Store_Static_String_Subtype_Bounds_Values
                    (Phase, Name, First_Value, Last_Value);
                  return;
               end if;

               declare
                  Constant_First : Natural := 1;
                  Constant_Last  : Natural := 0;
               begin
                  if Target_Derivation.Static_String_Constant_Range
                       (Phase, Constant_Name, Constant_First, Constant_Last)
                  then
                     Target_Derivation.Store_Static_String_Subtype_Bounds_Values
                       (Phase,
                        Name,
                        Integer (Constant_First),
                        Integer (Constant_Last));
                     return;
                  end if;
               end;

               declare
                  Prefix_Image : Unbounded_String;
                  Prefix_First : Natural := 1;
                  Prefix_Last  : Natural := 0;
                  Has_First    : Boolean := False;
                  Has_Last     : Boolean := False;
               begin
                  if Static_String_Default_Value (Prefix_Text, Prefix_Image) then
                     Has_First := Static_String_Bound_Value
                       (Prefix_Text, "first", Prefix_First);
                     Has_Last := Static_String_Bound_Value
                       (Prefix_Text, "last", Prefix_Last);
                     if not (Has_First and then Has_Last) then
                        Prefix_First := 1;
                        Prefix_Last := To_String (Prefix_Image)'Length;
                     end if;

                     Target_Derivation.Store_Static_String_Subtype_Bounds_Values
                       (Phase,
                        Name,
                        Integer (Prefix_First),
                        Integer (Prefix_Last));
                     return;
                  end if;
               end;
            end;
         end;
      end;
   exception
      when Constraint_Error =>
         null;
   end Store_Static_String_Subtype_Bounds_From_Range_Attribute;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Metadata;
