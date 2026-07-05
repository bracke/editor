with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Declaration_Collectors;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Declaration_Collectors;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
   use Editor.Ada_Declaration_Parser.Target_Helpers;

   function Has_Code_Char (Line : String; C : Character) return Boolean is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
   begin
      for X of Code loop
         if X = C then
            return True;
         end if;
      end loop;
      return False;
   end Has_Code_Char;

   procedure Add_Profile_Parameter_Names
     (Analysis      : in out Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Parent        : Symbol_Id;
      Declared_Name : String;
      Pending_Profile_Access_Target_Owners : in out Collected_Symbol_List;
      Pending_Profile_Access_Target_Count  : in out Natural)
   is
      Code         : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Name_Pos     : constant Natural := Declaration_Name_Position (Raw_Line, Declared_Name);
      Search_Start : Natural := 0;
      Group_Index  : Natural := 0;

      function Word_At (Pos : Natural; Word : String) return Boolean is
      begin
         return Pos >= Code'First
           and then Pos + Word'Length - 1 <= Code'Last
           and then Lower (Code (Pos .. Pos + Word'Length - 1)) = Word
           and then (Pos = Code'First or else not Is_Word_Char (Code (Pos - 1)))
           and then (Pos + Word'Length > Code'Last
                     or else not Is_Word_Char (Code (Pos + Word'Length)));
      end Word_At;

      procedure Add_Group (Open : Natural; Close : Natural) is
         Nesting       : Natural := 0;
         Segment_Start : Natural := Open + 1;

         function First_Colon (First, Last : Natural) return Natural is
            Local_Nesting : Natural := 0;
         begin
            for P in First .. Last loop
               if Code (P) = '(' then
                  Local_Nesting := Local_Nesting + 1;
               elsif Code (P) = ')' then
                  if Local_Nesting > 0 then
                     Local_Nesting := Local_Nesting - 1;
                  end if;
               elsif Code (P) = ':' and then Local_Nesting = 0 then
                  return P;
               end if;
            end loop;
            return 0;
         end First_Colon;

         function Top_Level_Default (First, Last : Natural) return Natural is
            Local_Nesting : Natural := 0;
         begin
            if Last <= First then
               return 0;
            end if;

            for P in First .. Last - 1 loop
               if Code (P) = '(' then
                  Local_Nesting := Local_Nesting + 1;
               elsif Code (P) = ')' then
                  if Local_Nesting > 0 then
                     Local_Nesting := Local_Nesting - 1;
                  end if;
               elsif Code (P) = ':'
                 and then Code (P + 1) = '='
                 and then Local_Nesting = 0
               then
                  return P;
               end if;
            end loop;
            return 0;
         end Top_Level_Default;

         function Starts_With_Word
           (Text  : String;
            Start : Natural;
            Word  : String) return Boolean
         is
         begin
            return Start >= Text'First
              and then Start + Word'Length - 1 <= Text'Last
              and then Lower (Text (Start .. Start + Word'Length - 1)) = Word
              and then (Start = Text'First or else not Is_Word_Char (Text (Start - 1)))
              and then (Start + Word'Length > Text'Last
                        or else not Is_Word_Char (Text (Start + Word'Length)));
         end Starts_With_Word;

         procedure Skip_Blanks (Text : String; Pos : in out Natural) is
         begin
            while Pos <= Text'Last
              and then (Text (Pos) = ' ' or else Text (Pos) = Ada.Characters.Latin_1.HT)
            loop
               Pos := Pos + 1;
            end loop;
         end Skip_Blanks;

         procedure Skip_Word
           (Text : String;
            Pos  : in out Natural;
            Word : String)
         is
         begin
            Skip_Blanks (Text, Pos);
            if Starts_With_Word (Text, Pos, Word) then
               Pos := Pos + Word'Length;
            end if;
         end Skip_Word;

         function Parameter_Mode_For (Segment : String) return Profile_Parameter_Mode is
            Colon : constant Natural := First_Colon (Segment'First, Segment'Last);
            Pos   : Natural := (if Colon = 0 then Segment'Last + 1 else Colon + 1);
         begin
            if Colon = 0 then
               return Profile_Parameter_Default_In;
            end if;

            Skip_Word (Segment, Pos, "aliased");
            Skip_Blanks (Segment, Pos);
            if Starts_With_Word (Segment, Pos, "in") then
               Pos := Pos + 2;
               Skip_Blanks (Segment, Pos);
               if Starts_With_Word (Segment, Pos, "out") then
                  return Profile_Parameter_In_Out;
               end if;
               return Profile_Parameter_In;
            elsif Starts_With_Word (Segment, Pos, "out") then
               return Profile_Parameter_Out;
            end if;

            return Profile_Parameter_Default_In;
         end Parameter_Mode_For;

         function Default_Text_For (Segment : String) return String is
            Default_Pos : constant Natural := Top_Level_Default (Segment'First, Segment'Last);
         begin
            if Default_Pos = 0 or else Default_Pos + 2 > Segment'Last then
               return "";
            end if;
            return Trim (Segment (Default_Pos + 2 .. Segment'Last));
         end Default_Text_For;

         procedure Add_Segment (First, Last : Natural) is
         begin
            if Last >= First then
               declare
                  Owners  : Collected_Symbol_List := (others => No_Symbol);
                  Count   : Natural := 0;
                  Segment : constant String := Raw_Line (First .. Last);
                  Segment_Lower : constant String := Lower (Segment);
                  Profile : constant String :=
                    Access_Subprogram_Profile (Segment);
                  Mode : constant Profile_Parameter_Mode :=
                    Parameter_Mode_For (Segment);
                  Type_Target : constant String := Object_Target_After_Colon (Segment);
                  Default_Text : constant String := Default_Text_For (Segment);
                  Has_Access : constant Boolean := Has_Token (Segment_Lower, "access");
                  Has_Aliased : constant Boolean := Has_Token (Segment_Lower, "aliased");
                  Has_Default : constant Boolean := Default_Text'Length /= 0;
               begin
                  Add_Object_Names_Collecting
                    (Analysis, Segment, Line_Number, Depth,
                     Parent, Symbol_Object, Type_Target,
                     Column_Base => First - 1,
                     Collected => Owners, Collected_Count => Count);

                  if Count > 0 then
                     Group_Index := Group_Index + 1;
                     for I in 1 .. Count loop
                        declare
                           Info : constant Symbol_Info := Symbol (Analysis, Owners (I));
                           Flags : Declaration_Flags := (others => False);
                        begin
                           Flags.Has_Profile_Mode_Metadata :=
                             Mode /= Profile_Parameter_Default_In or else Has_Access;
                           Flags.Has_Access_Metadata := Has_Access;
                           Flags.Has_Access_Subprogram_Metadata := Profile'Length /= 0;
                           Flags.Has_Aliased_Metadata := Has_Aliased;
                           Flags.Has_Default_Expression_Metadata := Has_Default;
                           Merge_Symbol_Flags (Analysis, Owners (I), Flags);
                           Add_Profile_Parameter_Metadata
                             (Analysis,
                              Owner_Symbol => Parent,
                              Parameter_Symbol => Owners (I),
                              Name => To_String (Info.Name),
                              Mode => Mode,
                              Type_Text => Type_Target,
                              Has_Aliased => Has_Aliased,
                              Has_Access_Definition => Has_Access,
                              Has_Access_Subprogram_Profile => Profile'Length /= 0,
                              Has_Default_Expression => Has_Default,
                              Default_Text => Default_Text,
                              Group_Index => Group_Index,
                              Group_Position => I,
                              Group_Name_Count => Count,
                              Source_Span => Info.Source_Span);
                        end;
                     end loop;
                  end if;

                  if Profile'Length /= 0 then
                     for I in 1 .. Count loop
                        Set_Symbol_Profile (Analysis, Owners (I), Profile);
                     end loop;
                  elsif Count > 0
                    and then Has_Token (Lower (Raw_Line (First .. Last)), "access")
                    and then not Has_Token (Lower (Raw_Line (First .. Last)), "procedure")
                    and then not Has_Token (Lower (Raw_Line (First .. Last)), "function")
                    and then Access_Object_Target (Raw_Line (First .. Last)) = ""
                    and then Pending_Profile_Access_Target_Count = 0
                  then
                     --  A callable parameter can split an anonymous
                     --  access-to-object designated subtype onto the next
                     --  physical line:
                     --     procedure Use (Ref : access
                     --        all Root'Class);
                     --  Learn the parameter name from this line and stamp
                     --  Target_Name from the continuation line instead of
                     --  losing the parameter or using "access" as a target.
                     for I in 1 .. Count loop
                        if Pending_Profile_Access_Target_Count
                          < Max_Collected_Object_Names
                        then
                           Pending_Profile_Access_Target_Count :=
                             Pending_Profile_Access_Target_Count + 1;
                           Pending_Profile_Access_Target_Owners
                             (Pending_Profile_Access_Target_Count) := Owners (I);
                        end if;
                     end loop;
                  end if;
               end;
            end if;
         end Add_Segment;
      begin
         if Close <= Open + 1 then
            return;
         end if;

         --  Add_Object_Names is colon-gated, so entry-family index groups
         --  such as "(Positive)" do not create false symbols, while the
         --  following parameter group in "entry E (Positive) (Item : T);"
         --  is still learned under the entry symbol.
         for I in Open + 1 .. Close - 1 loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting > 0 then
                  Nesting := Nesting - 1;
               end if;
            elsif Code (I) = ';' and then Nesting = 0 then
               Add_Segment (Segment_Start, I - 1);
               Segment_Start := I + 1;
            end if;
         end loop;

         Add_Segment (Segment_Start, Close - 1);
      end Add_Group;

      function Matching_Close (Open : Natural) return Natural is
         Nesting : Natural := 0;
      begin
         if Open = 0 then
            return 0;
         end if;

         for I in Open + 1 .. Code'Last loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting = 0 then
                  return I;
               end if;
               Nesting := Nesting - 1;
            elsif Code (I) = ';' and then Nesting = 0 then
               return 0;
            end if;
         end loop;

         return 0;
      end Matching_Close;
   begin
      if Parent = No_Symbol or else Declared_Name'Length = 0 or else Name_Pos = 0 then
         return;
      end if;

      Search_Start := Name_Pos + Declared_Name'Length;
      while Search_Start <= Code'Last loop
         declare
            Open  : Natural := 0;
            Close : Natural := 0;
         begin
            for I in Search_Start .. Code'Last loop
               if Code (I) = ';' then
                  return;
               elsif Word_At (I, "is")
                 or else Word_At (I, "return")
                 or else Word_At (I, "renames")
                 or else Word_At (I, "with")
                 or else Word_At (I, "when")
               then
                  --  Do not treat expression-function/body-expression
                  --  parentheses or anonymous access-to-subprogram result
                  --  profiles as callable parameters of the declared
                  --  subprogram.  Once the real profile has ended, later
                  --  "return access procedure (...)" or aspect/rename/barrier
                  --  syntax is declaration metadata, not a second callable
                  --  parameter group.
                  return;
               elsif Code (I) = '(' then
                  Open := I;
                  exit;
               end if;
            end loop;

            if Open = 0 then
               return;
            end if;

            Close := Matching_Close (Open);
            if Close = 0 then
               --  The callable profile continues on later physical lines.
               --  Still learn an open-ended parameter segment such as
               --  "Ref : access" now so the continuation can stamp its
               --  designated subtype target.
               if Open < Code'Last then
                  declare
                     Nesting       : Natural := 0;
                     Segment_Start : Natural := Open + 1;
                  begin
                     for J in Open + 1 .. Code'Last loop
                        if Code (J) = '(' then
                           Nesting := Nesting + 1;
                        elsif Code (J) = ')' then
                           if Nesting > 0 then
                              Nesting := Nesting - 1;
                           end if;
                        elsif Code (J) = ';' and then Nesting = 0 then
                           Add_Group (Segment_Start - 1, J);
                           Segment_Start := J + 1;
                        end if;
                     end loop;

                     if Segment_Start <= Code'Last then
                        Add_Group (Segment_Start - 1, Code'Last + 1);
                     end if;
                  end;
               end if;
               return;
            end if;

            Add_Group (Open, Close);
            Search_Start := Close + 1;
         end;
      end loop;
   end Add_Profile_Parameter_Names;



   function Profile_Still_Open
     (Raw_Line      : String;
      Declared_Name : String) return Boolean
   is
      Code     : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Name_Pos : constant Natural := Declaration_Name_Position (Raw_Line, Declared_Name);
      Open     : Natural := 0;
      Nesting  : Natural := 0;
   begin
      if Declared_Name'Length = 0 then
         return False;
      end if;

      if Name_Pos = 0 then
         return not Has_Code_Char (Raw_Line, ';')
           and then not Has_Token (Lower (Code), "is");
      end if;

      for I in Name_Pos + Declared_Name'Length .. Code'Last loop
         if Code (I) = '(' then
            Open := I;
            exit;
         elsif Code (I) = ';' or else Has_Token (Code (I .. Code'Last), "is") then
            return False;
         end if;
      end loop;

      if Open = 0 then
         return not Has_Code_Char (Raw_Line, ';')
           and then not Has_Token (Lower (Code), "is");
      end if;

      for I in Open + 1 .. Code'Last loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting = 0 then
               return False;
            end if;
            Nesting := Nesting - 1;
         end if;
      end loop;

      return True;
   end Profile_Still_Open;

   procedure Add_Profile_Parameter_Names_Continuation
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Pending_Profile_Access_Target_Owners : in out Collected_Symbol_List;
      Pending_Profile_Access_Target_Count  : in out Natural;
      Closed      : out Boolean)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Nesting       : Natural := 0;
      Segment_Start : Natural := Raw_Line'First;
      Group_Index   : Natural := 0;

      function Only_Blanks_Before (Pos : Natural) return Boolean is
      begin
         if Pos <= Raw_Line'First then
            return True;
         end if;
         for J in Raw_Line'First .. Pos - 1 loop
            if Raw_Line (J) /= ' ' and then Raw_Line (J) /= Ada.Characters.Latin_1.HT then
               return False;
            end if;
         end loop;
         return True;
      end Only_Blanks_Before;

      procedure Add_Segment (First, Last : Natural) is
         function First_Colon (Segment : String) return Natural is
            Local_Nesting : Natural := 0;
         begin
            for P in Segment'Range loop
               if Segment (P) = '(' then
                  Local_Nesting := Local_Nesting + 1;
               elsif Segment (P) = ')' then
                  if Local_Nesting > 0 then
                     Local_Nesting := Local_Nesting - 1;
                  end if;
               elsif Segment (P) = ':' and then Local_Nesting = 0 then
                  return P;
               end if;
            end loop;
            return 0;
         end First_Colon;

         function Top_Level_Default (Segment : String) return Natural is
            Local_Nesting : Natural := 0;
         begin
            if Segment'Length < 2 then
               return 0;
            end if;

            for P in Segment'First .. Segment'Last - 1 loop
               if Segment (P) = '(' then
                  Local_Nesting := Local_Nesting + 1;
               elsif Segment (P) = ')' then
                  if Local_Nesting > 0 then
                     Local_Nesting := Local_Nesting - 1;
                  end if;
               elsif Segment (P) = ':'
                 and then Segment (P + 1) = '='
                 and then Local_Nesting = 0
               then
                  return P;
               end if;
            end loop;
            return 0;
         end Top_Level_Default;

         function Starts_With_Local_Word
           (Text  : String;
            Start : Natural;
            Word  : String) return Boolean
         is
         begin
            return Start >= Text'First
              and then Start + Word'Length - 1 <= Text'Last
              and then Lower (Text (Start .. Start + Word'Length - 1)) = Word
              and then (Start = Text'First or else not Is_Word_Char (Text (Start - 1)))
              and then (Start + Word'Length > Text'Last
                        or else not Is_Word_Char (Text (Start + Word'Length)));
         end Starts_With_Local_Word;

         procedure Skip_Blanks (Text : String; Pos : in out Natural) is
         begin
            while Pos <= Text'Last
              and then (Text (Pos) = ' ' or else Text (Pos) = Ada.Characters.Latin_1.HT)
            loop
               Pos := Pos + 1;
            end loop;
         end Skip_Blanks;

         procedure Skip_Word
           (Text : String;
            Pos  : in out Natural;
            Word : String)
         is
         begin
            Skip_Blanks (Text, Pos);
            if Starts_With_Local_Word (Text, Pos, Word) then
               Pos := Pos + Word'Length;
            end if;
         end Skip_Word;

         function Parameter_Mode_For (Segment : String) return Profile_Parameter_Mode is
            Colon : constant Natural := First_Colon (Segment);
            Pos   : Natural := (if Colon = 0 then Segment'Last + 1 else Colon + 1);
         begin
            if Colon = 0 then
               return Profile_Parameter_Default_In;
            end if;

            Skip_Word (Segment, Pos, "aliased");
            Skip_Blanks (Segment, Pos);
            if Starts_With_Local_Word (Segment, Pos, "in") then
               Pos := Pos + 2;
               Skip_Blanks (Segment, Pos);
               if Starts_With_Local_Word (Segment, Pos, "out") then
                  return Profile_Parameter_In_Out;
               end if;
               return Profile_Parameter_In;
            elsif Starts_With_Local_Word (Segment, Pos, "out") then
               return Profile_Parameter_Out;
            end if;

            return Profile_Parameter_Default_In;
         end Parameter_Mode_For;

         function Default_Text_For (Segment : String) return String is
            Default_Pos : constant Natural := Top_Level_Default (Segment);
         begin
            if Default_Pos = 0 or else Default_Pos + 2 > Segment'Last then
               return "";
            end if;
            return Trim (Segment (Default_Pos + 2 .. Segment'Last));
         end Default_Text_For;
      begin
         if Last >= First then
            declare
               Owners  : Collected_Symbol_List := (others => No_Symbol);
               Count   : Natural := 0;
               Segment : constant String := Raw_Line (First .. Last);
               Segment_Lower : constant String := Lower (Segment);
               Profile : constant String := Access_Subprogram_Profile (Segment);
               Mode : constant Profile_Parameter_Mode :=
                 Parameter_Mode_For (Segment);
               Type_Target : constant String := Object_Target_After_Colon (Segment);
               Default_Text : constant String := Default_Text_For (Segment);
               Has_Access : constant Boolean := Has_Token (Segment_Lower, "access");
               Has_Aliased : constant Boolean := Has_Token (Segment_Lower, "aliased");
               Has_Default : constant Boolean := Default_Text'Length /= 0;
            begin
               Add_Object_Names_Collecting
                 (Analysis, Segment, Line_Number, Depth,
                  Parent, Symbol_Object, Type_Target,
                  Column_Base => First - 1,
                  Collected => Owners, Collected_Count => Count);

               if Count > 0 then
                  Group_Index := Group_Index + 1;
                  for I in 1 .. Count loop
                     declare
                        Info : constant Symbol_Info := Symbol (Analysis, Owners (I));
                        Flags : Declaration_Flags := (others => False);
                     begin
                        Flags.Has_Profile_Mode_Metadata :=
                          Mode /= Profile_Parameter_Default_In or else Has_Access;
                        Flags.Has_Access_Metadata := Has_Access;
                        Flags.Has_Access_Subprogram_Metadata := Profile'Length /= 0;
                        Flags.Has_Aliased_Metadata := Has_Aliased;
                        Flags.Has_Default_Expression_Metadata := Has_Default;
                        Merge_Symbol_Flags (Analysis, Owners (I), Flags);
                        Add_Profile_Parameter_Metadata
                          (Analysis,
                           Owner_Symbol => Parent,
                           Parameter_Symbol => Owners (I),
                           Name => To_String (Info.Name),
                           Mode => Mode,
                           Type_Text => Type_Target,
                           Has_Aliased => Has_Aliased,
                           Has_Access_Definition => Has_Access,
                           Has_Access_Subprogram_Profile => Profile'Length /= 0,
                           Has_Default_Expression => Has_Default,
                           Default_Text => Default_Text,
                           Group_Index => Group_Index,
                           Group_Position => I,
                           Group_Name_Count => Count,
                           Source_Span => Info.Source_Span);
                     end;
                  end loop;
               end if;

               if Profile'Length /= 0 then
                  for I in 1 .. Count loop
                     Set_Symbol_Profile (Analysis, Owners (I), Profile);
                  end loop;
               elsif Count > 0
                 and then Has_Token (Segment_Lower, "access")
                 and then not Has_Token (Segment_Lower, "procedure")
                 and then not Has_Token (Segment_Lower, "function")
                 and then Access_Object_Target (Segment) = ""
                 and then Pending_Profile_Access_Target_Count = 0
               then
                  for I in 1 .. Count loop
                     if Pending_Profile_Access_Target_Count
                       < Max_Collected_Object_Names
                     then
                        Pending_Profile_Access_Target_Count :=
                          Pending_Profile_Access_Target_Count + 1;
                        Pending_Profile_Access_Target_Owners
                          (Pending_Profile_Access_Target_Count) := Owners (I);
                     end if;
                  end loop;
               end if;
            end;
         end if;
      end Add_Segment;
   begin
      Closed := False;
      if Parent = No_Symbol then
         Closed := True;
         return;
      end if;

      --  Continuation lines may either start with the opening delimiter
      --  or continue after a delimiter that was present on the declaration
      --  line.  Only learn names from top-level semicolon-separated profile
      --  segments, preserving the original source columns.
      for I in Code'Range loop
         if Code (I) = '(' then
            if Segment_Start = Raw_Line'First and then Only_Blanks_Before (I) then
               Segment_Start := I + 1;
            else
               Nesting := Nesting + 1;
            end if;
         elsif Code (I) = ')' then
            if Nesting = 0 then
               Add_Segment (Segment_Start, I - 1);
               Closed := True;
               return;
            else
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            Add_Segment (Segment_Start, I - 1);
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last
        and then Ada.Strings.Fixed.Index
          (Lower (Raw_Line (Segment_Start .. Raw_Line'Last)), ":") /= 0
      then
         Add_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Profile_Parameter_Names_Continuation;


end Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
