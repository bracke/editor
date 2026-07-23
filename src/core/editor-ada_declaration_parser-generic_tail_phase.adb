with Ada.Strings;

with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Source_Awareness;
with Editor.Ada_Declaration_Parser.Tail_Analysis_Helpers;
with Editor.Ada_Syntax_Core;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Generic_Tail_Phase is

   use Editor.Text_Helpers;

   Max_Compact_Generic_Unit_Nesting : constant Natural := 16;
   Max_Compact_Generic_Unit_Name_Length : constant Natural := 80;

   type Compact_Generic_Unit_Name_Array is
     array (Positive range 1 .. Max_Compact_Generic_Unit_Nesting) of
       String (1 .. Max_Compact_Generic_Unit_Name_Length);
   type Compact_Generic_Unit_Name_Length_Array is
     array (Positive range 1 .. Max_Compact_Generic_Unit_Nesting) of Natural;
   type Compact_Generic_Unit_Begin_Array is
     array (Positive range 1 .. Max_Compact_Generic_Unit_Nesting) of Boolean;

   procedure Parse_Same_Line_Generic_Tail
     (Raw_Line : String)
   is
      Code        : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Generic_End : Natural := 0;
   begin
      for I in Code'Range loop
         if Code (I) = ';' then
            Generic_End := I;
            exit;
         end if;
      end loop;

      if Generic_End = 0 or else Generic_End >= Raw_Line'Last then
         return;
      end if;

      declare
         Tail_Line     : String := Raw_Line;
         Tail_Code     : constant String :=
           Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Segment_Start : Natural := Generic_End + 1;
         Nesting       : Natural := 0;
         Compact_Unit_Nesting : Natural := 0;
         Generic_Anonymous_Block_Nesting : Natural := 0;
         Compact_Unit_Names : Compact_Generic_Unit_Name_Array :=
           (others => (others => ' '));
         Compact_Unit_Name_Lengths : Compact_Generic_Unit_Name_Length_Array :=
           (others => 0);
         Compact_Unit_Begin_Seen : Compact_Generic_Unit_Begin_Array :=
           (others => False);
         Generic_Anonymous_Block_Names : Compact_Generic_Unit_Name_Array :=
           (others => (others => ' '));
         Generic_Anonymous_Block_Name_Lengths :
           Compact_Generic_Unit_Name_Length_Array :=
           (others => 0);
         Saw_Segment   : Boolean := False;
         Tail_Lower    : constant String (Tail_Code'Range) := Lower (Tail_Code);

         function Tail_Token_At
           (Pos   : Natural;
            Token : String) return Boolean
         is
         begin
            return Tail_Analysis_Helpers.Tail_Token_At (Tail_Lower, Pos, Token);
         end Tail_Token_At;

         function Is_Selected_Name_Blank (C : Character) return Boolean
           renames Tail_Analysis_Helpers.Is_Selected_Name_Blank;

         function Generic_Anonymous_Declare_Name_At
           (Pos : Natural) return String
         is
         begin
            return Tail_Analysis_Helpers.Generic_Anonymous_Declare_Name_At
              (Tail_Lower, Pos);
         end Generic_Anonymous_Declare_Name_At;

         function Generic_Anonymous_Accept_Name_At
           (Pos : Natural) return String
         is
            J : Natural := Pos + 6;
         begin
            while J <= Tail_Lower'Last
              and then Is_Selected_Name_Blank (Tail_Lower (J))
            loop
               J := J + 1;
            end loop;

            if J <= Tail_Lower'Last and then Is_Word_Char (Tail_Lower (J)) then
               return Tail_Analysis_Helpers.Compact_Selected_Name_At
                 (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
            else
               return "";
            end if;
         end Generic_Anonymous_Accept_Name_At;

         function Generic_Anonymous_Begin_Name_At
           (Pos : Natural) return String
         is
            J : Natural := Pos;
         begin
            if Pos <= Tail_Lower'First then
               return "";
            end if;

            J := Pos - 1;
            while J >= Tail_Lower'First
              and then Is_Selected_Name_Blank (Tail_Lower (J))
            loop
               exit when J = Tail_Lower'First;
               J := J - 1;
            end loop;

            if J >= Tail_Lower'First and then Tail_Lower (J) = ':' then
               return Tail_Analysis_Helpers.Previous_Selected_Name_Before
                 (Tail_Lower, J);
            else
               return "";
            end if;
         end Generic_Anonymous_Begin_Name_At;

         procedure Push_Generic_Anonymous_Block_Name (Name : String) is
            Store_Len : constant Natural :=
              Natural'Min (Name'Length, Max_Compact_Generic_Unit_Name_Length);
         begin
            Generic_Anonymous_Block_Nesting :=
              Generic_Anonymous_Block_Nesting + 1;
            if Generic_Anonymous_Block_Nesting in 1 .. Max_Compact_Generic_Unit_Nesting then
               Generic_Anonymous_Block_Name_Lengths
                 (Generic_Anonymous_Block_Nesting) := Store_Len;
               Generic_Anonymous_Block_Names
                 (Generic_Anonymous_Block_Nesting) := (others => ' ');
               if Store_Len > 0 then
                  Generic_Anonymous_Block_Names
                    (Generic_Anonymous_Block_Nesting) (1 .. Store_Len) :=
                      Name (Name'First .. Name'First + Store_Len - 1);
               end if;
            end if;
         end Push_Generic_Anonymous_Block_Name;

         function Generic_End_Matches_Anonymous_Block
           (Pos : Natural) return Boolean
         is
            J : Natural := Pos + 3;
            Expected_Len : Natural;
         begin
            if Generic_Anonymous_Block_Nesting = 0
              or else Generic_Anonymous_Block_Nesting > Max_Compact_Generic_Unit_Nesting
            then
               return True;
            end if;

            Expected_Len :=
              Generic_Anonymous_Block_Name_Lengths
                (Generic_Anonymous_Block_Nesting);
            while J <= Tail_Lower'Last
              and then Is_Selected_Name_Blank (Tail_Lower (J))
            loop
               J := J + 1;
            end loop;

            if Expected_Len = 0 then
               return J > Tail_Lower'Last or else Tail_Lower (J) = ';';
            elsif J <= Tail_Lower'Last and then Is_Word_Char (Tail_Lower (J)) then
               declare
                  Found : constant String :=
                    Tail_Analysis_Helpers.Compact_Selected_Name_At
                      (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
               begin
                  return Found'Length = Expected_Len
                    and then Found =
                      Generic_Anonymous_Block_Names
                        (Generic_Anonymous_Block_Nesting) (1 .. Expected_Len);
               end;
            else
               return False;
            end if;
         end Generic_End_Matches_Anonymous_Block;

         procedure Pop_Generic_Anonymous_Block_Name is
         begin
            if Generic_Anonymous_Block_Nesting in 1 .. Max_Compact_Generic_Unit_Nesting then
               Generic_Anonymous_Block_Name_Lengths
                 (Generic_Anonymous_Block_Nesting) := 0;
               Generic_Anonymous_Block_Names
                 (Generic_Anonymous_Block_Nesting) := (others => ' ');
            end if;
            Generic_Anonymous_Block_Nesting :=
              Generic_Anonymous_Block_Nesting - 1;
         end Pop_Generic_Anonymous_Block_Name;

         function Compact_Generic_Unit_Name_At (Pos : Natural) return String is
            J : Natural := Pos;
            K : Natural;
         begin
            if Tail_Token_At (Pos, "package") then
               J := Pos + 7;
               while J <= Tail_Lower'Last
                 and then Is_Selected_Name_Blank (Tail_Lower (J))
               loop
                  J := J + 1;
               end loop;

               if Tail_Token_At (J, "body") then
                  J := J + 4;
                  while J <= Tail_Lower'Last
                    and then Is_Selected_Name_Blank (Tail_Lower (J))
                  loop
                     J := J + 1;
                  end loop;
               end if;

               return Tail_Analysis_Helpers.Compact_Selected_Name_At
                 (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
            elsif Tail_Token_At (Pos, "protected") then
               J := Pos + 9;
               while J <= Tail_Lower'Last
                 and then Is_Selected_Name_Blank (Tail_Lower (J))
               loop
                  J := J + 1;
               end loop;

               if Tail_Token_At (J, "body") then
                  J := J + 4;
                  while J <= Tail_Lower'Last
                    and then Is_Selected_Name_Blank (Tail_Lower (J))
                  loop
                     J := J + 1;
                  end loop;
               end if;

               if Tail_Token_At (J, "type") then
                  J := J + 4;
                  while J <= Tail_Lower'Last
                    and then Is_Selected_Name_Blank (Tail_Lower (J))
                  loop
                     J := J + 1;
                  end loop;
               end if;

               return Tail_Analysis_Helpers.Compact_Selected_Name_At
                 (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
            elsif Tail_Token_At (Pos, "task") then
               J := Pos + 4;
               while J <= Tail_Lower'Last
                 and then Is_Selected_Name_Blank (Tail_Lower (J))
               loop
                  J := J + 1;
               end loop;

               if Tail_Token_At (J, "body") then
                  J := J + 4;
                  while J <= Tail_Lower'Last
                    and then Is_Selected_Name_Blank (Tail_Lower (J))
                  loop
                     J := J + 1;
                  end loop;
               end if;

               if Tail_Token_At (J, "type") then
                  J := J + 4;
                  while J <= Tail_Lower'Last
                    and then Is_Selected_Name_Blank (Tail_Lower (J))
                  loop
                     J := J + 1;
                  end loop;
               end if;

               return Tail_Analysis_Helpers.Compact_Selected_Name_At
                 (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
            elsif Tail_Token_At (Pos, "procedure") then
               J := Pos + 9;
            elsif Tail_Token_At (Pos, "function") then
               J := Pos + 8;
            else
               return "";
            end if;

            while J <= Tail_Lower'Last
              and then Is_Selected_Name_Blank (Tail_Lower (J))
            loop
               J := J + 1;
            end loop;

            if J > Tail_Lower'Last then
               return "";
            elsif Tail_Lower (J) = '"' then
               K := J + 1;
               while K <= Tail_Lower'Last and then Tail_Lower (K) /= '"' loop
                  K := K + 1;
               end loop;
               if K <= Tail_Lower'Last then
                  return Tail_Lower (J .. K);
               else
                  return "";
               end if;
            else
               return Tail_Analysis_Helpers.Compact_Selected_Name_At
                 (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
            end if;
         end Compact_Generic_Unit_Name_At;

         procedure Push_Compact_Generic_Unit_Name (Name : String) is
            Store_Len : constant Natural :=
              Natural'Min (Name'Length, Max_Compact_Generic_Unit_Name_Length);
         begin
            if Compact_Unit_Nesting in 1 .. Max_Compact_Generic_Unit_Nesting then
               Compact_Unit_Name_Lengths (Compact_Unit_Nesting) := Store_Len;
               Compact_Unit_Names (Compact_Unit_Nesting) := (others => ' ');
               if Store_Len > 0 then
                  Compact_Unit_Names (Compact_Unit_Nesting) (1 .. Store_Len) :=
                    Name (Name'First .. Name'First + Store_Len - 1);
               end if;
            end if;
         end Push_Compact_Generic_Unit_Name;

         function Generic_End_Is_Metadata_Or_Control
           (Pos : Natural) return Boolean
         is
         begin
            return Tail_Analysis_Helpers.Generic_End_Is_Metadata_Or_Control
              (Tail_Lower, Pos);
         end Generic_End_Is_Metadata_Or_Control;

         function End_Matches_Compact_Generic_Unit (Pos : Natural) return Boolean is
            J : Natural := Pos + 3;
            Expected_Len : Natural;
         begin
            if Compact_Unit_Nesting = 0
              or else Compact_Unit_Nesting > Max_Compact_Generic_Unit_Nesting
            then
               return True;
            end if;

            Expected_Len := Compact_Unit_Name_Lengths (Compact_Unit_Nesting);
            if Expected_Len = 0 then
               return True;
            end if;

            while J <= Tail_Lower'Last
              and then Is_Selected_Name_Blank (Tail_Lower (J))
            loop
               J := J + 1;
            end loop;

            if J > Tail_Lower'Last or else Tail_Lower (J) = ';' then
               return True;
            elsif Tail_Lower (J) = '"' then
               declare
                  K : Natural := J + 1;
               begin
                  while K <= Tail_Lower'Last and then Tail_Lower (K) /= '"' loop
                     K := K + 1;
                  end loop;

                  return K <= Tail_Lower'Last
                    and then K - J + 1 = Expected_Len
                    and then Tail_Lower (J .. K) =
                      Compact_Unit_Names (Compact_Unit_Nesting) (1 .. Expected_Len);
               end;
            elsif Is_Word_Char (Tail_Lower (J)) then
               declare
                  Found : constant String :=
                    Tail_Analysis_Helpers.Compact_Selected_Name_At
                      (Tail_Lower, J, Max_Compact_Generic_Unit_Name_Length);
               begin
                  return Found'Length = Expected_Len
                    and then Found =
                      Compact_Unit_Names (Compact_Unit_Nesting) (1 .. Expected_Len);
               end;
            else
               return True;
            end if;
         end End_Matches_Compact_Generic_Unit;

         function Has_Compact_Generic_Unit_Opener
           (Pos : Natural) return Boolean
         is
            J              : Natural := Pos;
            Saw_Is         : Boolean := False;
            Header_Nesting : Natural := 0;
         begin
            if not (Tail_Token_At (Pos, "package")
                    or else Tail_Token_At (Pos, "procedure")
                    or else Tail_Token_At (Pos, "function")
                    or else Tail_Token_At (Pos, "protected")
                    or else Tail_Token_At (Pos, "task"))
            then
               return False;
            end if;

            if (Tail_Token_At (Pos, "procedure")
                or else Tail_Token_At (Pos, "function"))
              and then Pos > Tail_Lower'First + 4
              and then Tail_Lower (Pos - 5 .. Pos - 1) = "with "
            then
               return False;
            end if;

            declare
               Candidate_Name : constant String :=
                 Compact_Generic_Unit_Name_At (Pos);
            begin
               if Source_Awareness.Is_Invalid_Compact_Owner_Name (Candidate_Name) then
                  return False;
               end if;
            end;

            while J <= Tail_Lower'Last loop
               if Tail_Lower (J) = '(' then
                  Header_Nesting := Header_Nesting + 1;
               elsif Tail_Lower (J) = ')' then
                  if Header_Nesting > 0 then
                     Header_Nesting := Header_Nesting - 1;
                  end if;
               elsif Tail_Lower (J) = ';' and then Header_Nesting = 0 then
                  exit;
               end if;

               if Header_Nesting = 0 then
                  if Tail_Token_At (J, "renames")
                    or else Tail_Token_At (J, "new")
                  then
                     return False;
                  elsif Tail_Token_At (J, "is") then
                     declare
                        After_Is : constant Natural :=
                          Lexical_Helpers.Next_Non_Blank (Tail_Lower, J + 2);
                     begin
                        Saw_Is := True;
                        if (Tail_Token_At (Pos, "procedure")
                            or else Tail_Token_At (Pos, "function"))
                          and then After_Is <= Tail_Lower'Last
                        then
                           if Tail_Lower (After_Is) = '('
                             or else Tail_Token_At (After_Is, "null")
                             or else Tail_Token_At (After_Is, "separate")
                           then
                              return False;
                           end if;
                        end if;
                     end;
                  end if;
               end if;

               J := J + 1;
            end loop;

            return Saw_Is;
         end Has_Compact_Generic_Unit_Opener;

         function Has_Generic_Accept_Do_Body (Pos : Natural) return Boolean is
            J       : Natural := Pos;
            Nesting : Natural := 0;
         begin
            if not Tail_Token_At (Pos, "accept") then
               return False;
            end if;

            while J <= Tail_Lower'Last loop
               if Tail_Lower (J) = '(' then
                  Nesting := Nesting + 1;
               elsif Tail_Lower (J) = ')' then
                  if Nesting > 0 then
                     Nesting := Nesting - 1;
                  end if;
               elsif Tail_Lower (J) = ';' and then Nesting = 0 then
                  return False;
               elsif Nesting = 0 and then Tail_Token_At (J, "do") then
                  return True;
               end if;

               J := J + 1;
            end loop;

            return False;
         end Has_Generic_Accept_Do_Body;
      begin
         for I in Tail_Line'First .. Generic_End loop
            Tail_Line (I) := ' ';
         end loop;

         for I in Tail_Code'First .. Tail_Code'Last loop
            if I <= Generic_End then
               null;
            elsif Tail_Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Tail_Code (I) = ')' then
               if Nesting > 0 then
                  Nesting := Nesting - 1;
               end if;
            elsif Nesting = 0
              and then Generic_Anonymous_Block_Nesting > 0
              and then Tail_Token_At (I, "end")
              and then (Generic_End_Is_Metadata_Or_Control (I)
                        or else Generic_End_Matches_Anonymous_Block (I))
            then
               if not Generic_End_Is_Metadata_Or_Control (I) then
                  Pop_Generic_Anonymous_Block_Name;
               end if;
            elsif Nesting = 0
              and then Compact_Unit_Nesting > 0
              and then Tail_Token_At (I, "end")
              and then (Generic_End_Is_Metadata_Or_Control (I)
                        or else End_Matches_Compact_Generic_Unit (I))
            then
               if not Generic_End_Is_Metadata_Or_Control (I) then
                  if Compact_Unit_Nesting <= Max_Compact_Generic_Unit_Nesting then
                     Compact_Unit_Name_Lengths (Compact_Unit_Nesting) := 0;
                     Compact_Unit_Begin_Seen (Compact_Unit_Nesting) := False;
                  end if;
                  Compact_Unit_Nesting := Compact_Unit_Nesting - 1;
               end if;
            elsif Nesting = 0
              and then Compact_Unit_Nesting > 0
              and then Generic_Anonymous_Block_Nesting = 0
              and then Tail_Token_At (I, "begin")
            then
               if Compact_Unit_Nesting <= Max_Compact_Generic_Unit_Nesting then
                  if Compact_Unit_Begin_Seen (Compact_Unit_Nesting) then
                     Push_Generic_Anonymous_Block_Name
                       (Generic_Anonymous_Begin_Name_At (I));
                  else
                     Compact_Unit_Begin_Seen (Compact_Unit_Nesting) := True;
                  end if;
               end if;
            elsif Nesting = 0
              and then Compact_Unit_Nesting > 0
              and then (Tail_Token_At (I, "declare")
                        or else (Tail_Token_At (I, "accept")
                                 and then Has_Generic_Accept_Do_Body (I)))
            then
               if Tail_Token_At (I, "declare") then
                  Push_Generic_Anonymous_Block_Name
                    (Generic_Anonymous_Declare_Name_At (I));
               else
                  Push_Generic_Anonymous_Block_Name
                    (Generic_Anonymous_Accept_Name_At (I));
               end if;
            elsif Nesting = 0
              and then Has_Compact_Generic_Unit_Opener (I)
            then
               Compact_Unit_Nesting := Compact_Unit_Nesting + 1;
               if Compact_Unit_Nesting <= Max_Compact_Generic_Unit_Nesting then
                  Compact_Unit_Begin_Seen (Compact_Unit_Nesting) := False;
               end if;
               Push_Compact_Generic_Unit_Name (Compact_Generic_Unit_Name_At (I));
            elsif Tail_Code (I) = ';'
              and then Nesting = 0
              and then Compact_Unit_Nesting = 0
            then
               if Parse_Segment (Segment_Start, I) then
                  Saw_Segment := True;
               end if;
               Segment_Start := I + 1;
            end if;
         end loop;

         if Segment_Start <= Raw_Line'Last then
            if Parse_Segment (Segment_Start, Raw_Line'Last) then
               Saw_Segment := True;
            end if;
         end if;

         if not Saw_Segment
           and then Trim (Editor.Ada_Syntax_Core.Sanitize_Line (Tail_Line))'Length /= 0
         then
            Saw_Segment := Parse_Segment (Generic_End + 1, Raw_Line'Last);
         end if;
      end;
   end Parse_Same_Line_Generic_Tail;

end Editor.Ada_Declaration_Parser.Generic_Tail_Phase;
