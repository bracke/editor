with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;
with Editor.Ada_Syntax_Core;
with Ada.Characters.Latin_1;

package body Editor.Ada_Declaration_Parser.Declaration_Collectors is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Has_Aliased_Metadata (Line : String) return Boolean
     renames Editor.Ada_Declaration_Parser.Metadata_Helpers.Has_Aliased_Metadata;

   function Access_Subprogram_Profile (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Target_Helpers.Access_Subprogram_Profile;

   function Object_Target_After_Colon (Line : String) return String
     renames Editor.Ada_Declaration_Parser.Target_Helpers.Object_Target_After_Colon;

   function Target_After (Line, Marker : String) return String
     renames Editor.Ada_Declaration_Parser.Name_Profile_Helpers.Target_After;

   procedure Add_Object_Names_Collecting
     (Analysis        : in out Analysis_Result;
      Raw_Line        : String;
      Line_Number     : Positive;
      Depth           : Natural;
      Parent          : Symbol_Id;
      Kind            : Symbol_Kind;
      Type_Target     : String;
      Collected       : in out Collected_Symbol_List;
      Collected_Count : in out Natural;
      Column_Base     : Natural := 0;
      Flags           : Declaration_Flags := (others => False))
   is
      Code_Colon : Natural := 0;
      Start      : Natural;
      Stop       : Natural;
   begin
      declare
         Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
         Nesting : Natural := 0;
      begin
         for I in Code'Range loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting > 0 then
                  Nesting := Nesting - 1;
               end if;
            elsif Code (I) = ';' and then Nesting = 0 then
               return;
            elsif Code (I) = ':' and then Nesting = 0 then
               if I < Code'Last and then Code (I + 1) = '=' then
                  null;
               else
                  Code_Colon := I;
                  exit;
               end if;
            end if;
         end loop;
      end;

      if Code_Colon = 0 then
         return;
      end if;

      Start := Raw_Line'First;
      while Start < Code_Colon loop
         while Start < Code_Colon
           and then not
             ((Raw_Line (Start) >= 'A' and then Raw_Line (Start) <= 'Z')
              or else
                (Raw_Line (Start) >= 'a' and then Raw_Line (Start) <= 'z'))
         loop
            Start := Start + 1;
         end loop;
         Stop := Start;
         while Stop < Code_Colon and then Is_Word_Char (Raw_Line (Stop)) loop
            Stop := Stop + 1;
         end loop;
         if Stop > Start then
            declare
               Name   : constant String := Raw_Line (Start .. Stop - 1);
               Col    : constant Positive :=
                 Positive (Column_Base + Start - Raw_Line'First + 1);
               Existing : Symbol_Id := No_Symbol;
            begin
               if Kind = Symbol_Record_Component then
                  for Existing_Index in 1 .. Symbol_Count (Analysis) loop
                     declare
                        Existing_Info : constant Symbol_Info :=
                          Symbol_At (Analysis, Existing_Index);
                     begin
                        if Existing_Info.Kind = Kind
                          and then Existing_Info.Parent_Symbol = Parent
                          and then Existing_Info.Declaration_Column = Col
                          and then Lower (To_String (Existing_Info.Name)) =
                            Lower (Name)
                        then
                           Existing := Existing_Info.Id;
                           exit;
                        end if;
                     end;
                  end loop;
               end if;

               declare
                  New_Id : constant Symbol_Id :=
                    (if Existing /= No_Symbol then Existing else
                       Add_Symbol
                         (Analysis, Name, Kind,
                          (Line_Number,
                           Col,
                           Line_Number,
                           Positive (Column_Base + Stop - Raw_Line'First)),
                          Col,
                          Enclosing_Scope => Scope_Id (Natural (Parent)),
                          Parent_Symbol   => Parent,
                          Depth           => Depth,
                          Flags           => Flags,
                          Target_Name     => Type_Target));
               begin
               if New_Id /= No_Symbol
                 and then Collected_Count < Max_Collected_Object_Names
               then
                  Collected_Count := Collected_Count + 1;
                  Collected (Collected_Count) := New_Id;
               end if;
               end;
            end;
         end if;
         Start := Stop + 1;
      end loop;
   end Add_Object_Names_Collecting;

   procedure Add_Object_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Type_Target : String;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False))
   is
      Ignored       : Collected_Symbol_List := (others => No_Symbol);
      Ignored_Count : Natural := 0;
   begin
      Add_Object_Names_Collecting
        (Analysis        => Analysis,
         Raw_Line        => Raw_Line,
         Line_Number     => Line_Number,
         Depth           => Depth,
         Parent          => Parent,
         Kind            => Kind,
         Type_Target     => Type_Target,
         Collected       => Ignored,
         Collected_Count => Ignored_Count,
         Column_Base     => Column_Base,
         Flags           => Flags);
   end Add_Object_Names;

   procedure Add_Object_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False))
   is
      Type_Target : constant String :=
        (if Kind = Symbol_Exception then ""
         else Target_Helpers.Object_Target_After_Colon (Raw_Line));
   begin
      Add_Object_Names
        (Analysis    => Analysis,
         Raw_Line    => Raw_Line,
         Line_Number => Line_Number,
         Depth       => Depth,
         Parent      => Parent,
         Kind        => Kind,
         Type_Target => Type_Target,
         Column_Base => Column_Base,
         Flags       => Flags);
   end Add_Object_Names;

   procedure Add_Object_Name_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Column_Base : Natural := 0;
      Flags       : Declaration_Flags := (others => False))
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
   begin
      declare
         Nesting : Natural := 0;
      begin
         for I in Code'Range loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting > 0 then
                  Nesting := Nesting - 1;
               else
                  exit;
               end if;
            elsif Code (I) = ';' and then Nesting = 0 then
               if I > Segment_Start then
                  Add_Object_Names
                    (Analysis, Raw_Line (Segment_Start .. I - 1), Line_Number,
                     Depth, Parent, Kind,
                     Column_Base => Column_Base + Segment_Start - Raw_Line'First,
                     Flags => Flags);
               end if;
               Segment_Start := I + 1;
            end if;
         end loop;
      end;

      if Segment_Start <= Raw_Line'Last then
         Add_Object_Names
           (Analysis, Raw_Line (Segment_Start .. Raw_Line'Last), Line_Number,
            Depth, Parent, Kind,
            Column_Base => Column_Base + Segment_Start - Raw_Line'First,
            Flags => Flags);
      end if;
   end Add_Object_Name_Groups;

   procedure Add_Discriminant_Names
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Open    : Natural := 0;
      Close   : Natural := 0;
      Nesting : Natural := 0;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Open := I;
            exit;
         elsif Code (I) = ';' then
            exit;
         end if;
      end loop;

      if Open /= 0 then
         Nesting := 1;
         for I in Open + 1 .. Code'Last loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting > 1 then
                  Nesting := Nesting - 1;
               else
                  Close := I;
                  exit;
               end if;
            end if;
         end loop;

         if Close /= 0 and then Close > Open + 1 then
            Add_Object_Name_Groups
              (Analysis, Raw_Line (Open + 1 .. Close - 1), Line_Number,
               Depth, Parent, Symbol_Discriminant,
               Column_Base => Open - Raw_Line'First + 1);
         elsif Open < Raw_Line'Last then
            Add_Object_Name_Groups
              (Analysis, Raw_Line (Open + 1 .. Raw_Line'Last), Line_Number,
               Depth, Parent, Symbol_Discriminant,
               Column_Base => Open - Raw_Line'First + 1);
         end if;
      else
         Add_Object_Name_Groups
           (Analysis, Raw_Line, Line_Number, Depth, Parent,
            Symbol_Discriminant);
      end if;
   end Add_Discriminant_Names;

   procedure Add_Record_Component_Names
     (Analysis      : in out Analysis_Result;
      Raw_Line      : String;
      Line_Number   : Positive;
      Depth         : Natural;
      Parent        : Symbol_Id;
      Mark_Metadata : not null access procedure
        (Flags : in out Declaration_Flags;
         Line  : String))
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;

      procedure Add_Component_Segment
        (First : Natural;
         Last  : Natural)
      is
         Colon      : Natural := 0;
         Arrow_Last : Natural := 0;
         Start_Pos  : Natural := First;
      begin
         if First > Last then
            return;
         end if;

         for I in First .. Last loop
            if Code (I) = ':' then
               Colon := I;
               exit;
            elsif I < Last and then Code (I) = '=' and then Code (I + 1) = '>' then
               Arrow_Last := I + 1;
            end if;
         end loop;

         if Colon = 0 then
            return;
         end if;

         if Arrow_Last /= 0 and then Arrow_Last < Colon then
            Start_Pos := Arrow_Last + 1;
            while Start_Pos <= Last
              and then (Raw_Line (Start_Pos) = ' '
                        or else Raw_Line (Start_Pos) = Ada.Characters.Latin_1.HT)
            loop
               Start_Pos := Start_Pos + 1;
            end loop;
         end if;

         if Start_Pos <= Last then
            declare
               Segment_Flags : Declaration_Flags := (others => False);
            begin
               Segment_Flags.Has_Null_Exclusion :=
                 Has_Null_Exclusion (Raw_Line (Start_Pos .. Last));
               Segment_Flags.Has_Aliased_Metadata :=
                 Has_Aliased_Metadata (Raw_Line (Start_Pos .. Last));
               Mark_Metadata.all
                 (Segment_Flags, Raw_Line (Start_Pos .. Last));
               Add_Object_Names
                 (Analysis, Raw_Line (Start_Pos .. Last), Line_Number,
                  Depth, Parent, Symbol_Record_Component,
                  Column_Base => Start_Pos - Raw_Line'First,
                  Flags => Segment_Flags);
            end;
         end if;
      end Add_Component_Segment;
   begin
      declare
         Nesting : Natural := 0;
      begin
         for I in Code'Range loop
            if Code (I) = '(' then
               Nesting := Nesting + 1;
            elsif Code (I) = ')' then
               if Nesting > 0 then
                  Nesting := Nesting - 1;
               end if;
            elsif Code (I) = ';' and then Nesting = 0 then
               Add_Component_Segment (Segment_Start, I - 1);
               Segment_Start := I + 1;
            end if;
         end loop;
      end;

      if Segment_Start <= Raw_Line'Last then
         Add_Component_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Record_Component_Names;

   procedure Add_Object_Rename_Declaration_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;

      procedure Add_Rename_Segment
        (First : Natural;
         Last  : Natural)
      is
         Segment_Lower : constant String := Lower (Code (First .. Last));
         Segment_Kind  : Symbol_Kind := Symbol_Object;
         Owners        : Collected_Symbol_List := (others => No_Symbol);
         Count         : Natural := 0;
         Rename_Target : constant String := Target_After (Raw_Line (First .. Last), "renames");
      begin
         if First > Last then
            return;
         end if;

         if Ada.Strings.Fixed.Index (Segment_Lower, ": exception") /= 0 then
            Segment_Kind := Symbol_Exception;
         elsif Has_Object_Constant_Qualifier (Raw_Line (First .. Last)) then
            Segment_Kind := Symbol_Constant;
         end if;

         declare
            Type_Target : constant String :=
              (if Segment_Kind = Symbol_Exception then ""
               else Object_Target_After_Colon (Raw_Line (First .. Last)));
         begin
            Add_Object_Names_Collecting
              (Analysis, Raw_Line (First .. Last), Line_Number,
               Depth, Parent, Segment_Kind, Type_Target,
               Column_Base => First - Raw_Line'First,
               Flags => (Is_Rename => True, others => False),
               Collected => Owners, Collected_Count => Count);
         end;

         for I in 1 .. Count loop
            Set_Symbol_Target (Analysis, Owners (I), Rename_Target);
         end loop;
      end Add_Rename_Segment;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            if I > Segment_Start then
               Add_Rename_Segment (Segment_Start, I - 1);
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Rename_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Object_Rename_Declaration_Groups;

   procedure Add_Object_Declaration_Groups
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id;
      Kind        : Symbol_Kind;
      Flags       : Declaration_Flags := (others => False))
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;

      procedure Add_Declaration_Segment
        (First : Natural;
         Last  : Natural)
      is
         Segment_Lower : constant String := Lower (Code (First .. Last));
         Segment_Kind  : Symbol_Kind := Kind;
      begin
         if First > Last then
            return;
         end if;

         if Kind /= Symbol_Generic_Formal_Object then
            if Ada.Strings.Fixed.Index (Segment_Lower, ": exception") /= 0 then
               Segment_Kind := Symbol_Exception;
            elsif Has_Object_Constant_Qualifier (Raw_Line (First .. Last)) then
               Segment_Kind := Symbol_Constant;
            else
               Segment_Kind := Symbol_Object;
            end if;
         end if;

         declare
            Owners  : Collected_Symbol_List := (others => No_Symbol);
            Count   : Natural := 0;
            Segment : constant String := Raw_Line (First .. Last);
            Profile : constant String := Access_Subprogram_Profile (Segment);
            Type_Target : constant String :=
              (if Segment_Kind = Symbol_Exception then "" else Object_Target_After_Colon (Segment));
         begin
            Add_Object_Names_Collecting
              (Analysis, Segment, Line_Number,
               Depth, Parent, Segment_Kind, Type_Target,
               Column_Base => First - Raw_Line'First,
               Flags => Flags,
               Collected => Owners, Collected_Count => Count);

            if Profile'Length /= 0 then
               for I in 1 .. Count loop
                  Set_Symbol_Profile (Analysis, Owners (I), Profile);
               end loop;
            end if;
         end;
      end Add_Declaration_Segment;
   begin
      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            if I > Segment_Start then
               Add_Declaration_Segment (Segment_Start, I - 1);
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last then
         Add_Declaration_Segment (Segment_Start, Raw_Line'Last);
      end if;
   end Add_Object_Declaration_Groups;

   procedure Add_Enumeration_Literals
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Open : Natural := 0;
      I    : Natural;
   begin
      for P in Code'Range loop
         if Code (P) = '(' then
            Open := P;
            exit;
         elsif Code (P) = ';' then
            return;
         end if;
      end loop;
      if Open = 0 then
         return;
      end if;
      I := Open + 1;
      while I <= Code'Last loop
         if Code (I) = ')' or else Code (I) = ';' then
            return;
         elsif (Raw_Line (I) >= 'A' and then Raw_Line (I) <= 'Z')
           or else (Raw_Line (I) >= 'a' and then Raw_Line (I) <= 'z')
         then
            declare
               J : Natural := I;
            begin
               while J <= Raw_Line'Last and then Is_Word_Char (Raw_Line (J)) loop
                  J := J + 1;
               end loop;
               declare
                  Ignored : constant Symbol_Id := Add_Symbol
                    (Analysis, Raw_Line (I .. J - 1), Symbol_Enumeration_Literal,
                     (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                      Positive (J - Raw_Line'First)),
                     Positive (I - Raw_Line'First + 1),
                     Enclosing_Scope => Scope_Id (Natural (Parent)),
                     Parent_Symbol => Parent, Depth => Depth);
               begin
                  null;
               end;
               I := J;
            end;
         elsif Raw_Line (I) = Character'Val (16#27#)
           and then Editor.Ada_Syntax_Core.Looks_Like_Simple_Character_Literal (Raw_Line, I)
         then
            declare
               Last : constant Natural := I + Editor.Ada_Syntax_Core.Simple_Character_Literal_Length (Raw_Line, I) - 1;
            begin
               if Last <= Raw_Line'Last then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Raw_Line (I .. Last), Symbol_Enumeration_Literal,
                        (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                         Positive (Last - Raw_Line'First + 1)),
                        Positive (I - Raw_Line'First + 1),
                        Enclosing_Scope => Scope_Id (Natural (Parent)),
                        Parent_Symbol => Parent, Depth => Depth);
                  begin
                     null;
                  end;
               end if;
               I := Last + 1;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Add_Enumeration_Literals;

   procedure Add_Enumeration_Literals_Continuation
     (Analysis    : in out Analysis_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Parent      : Symbol_Id)
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      I    : Natural := Code'First;
   begin
      while I <= Code'Last loop
         if Code (I) = ')' or else Code (I) = ';' then
            return;
         elsif (Raw_Line (I) >= 'A' and then Raw_Line (I) <= 'Z')
           or else (Raw_Line (I) >= 'a' and then Raw_Line (I) <= 'z')
         then
            declare
               J : Natural := I;
            begin
               while J <= Raw_Line'Last and then Is_Word_Char (Raw_Line (J)) loop
                  J := J + 1;
               end loop;
               declare
                  Ignored : constant Symbol_Id := Add_Symbol
                    (Analysis, Raw_Line (I .. J - 1), Symbol_Enumeration_Literal,
                     (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                      Positive (J - Raw_Line'First)),
                     Positive (I - Raw_Line'First + 1),
                     Enclosing_Scope => Scope_Id (Natural (Parent)),
                     Parent_Symbol => Parent, Depth => Depth);
               begin
                  null;
               end;
               I := J;
            end;
         elsif Raw_Line (I) = Character'Val (16#27#)
           and then Editor.Ada_Syntax_Core.Looks_Like_Simple_Character_Literal (Raw_Line, I)
         then
            declare
               Last : constant Natural := I + Editor.Ada_Syntax_Core.Simple_Character_Literal_Length (Raw_Line, I) - 1;
            begin
               if Last <= Raw_Line'Last then
                  declare
                     Ignored : constant Symbol_Id := Add_Symbol
                       (Analysis, Raw_Line (I .. Last), Symbol_Enumeration_Literal,
                        (Line_Number, Positive (I - Raw_Line'First + 1), Line_Number,
                         Positive (Last - Raw_Line'First + 1)),
                        Positive (I - Raw_Line'First + 1),
                        Enclosing_Scope => Scope_Id (Natural (Parent)),
                        Parent_Symbol => Parent, Depth => Depth);
                  begin
                     null;
                  end;
               end if;
               I := Last + 1;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Add_Enumeration_Literals_Continuation;

end Editor.Ada_Declaration_Parser.Declaration_Collectors;
