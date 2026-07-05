with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Target_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Declaration_Collectors is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

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
               New_Id : constant Symbol_Id := Add_Symbol
                 (Analysis, Name, Kind,
                  (Line_Number,
                   Positive (Column_Base + Start - Raw_Line'First + 1),
                   Line_Number,
                   Positive (Column_Base + Stop - Raw_Line'First)),
                  Positive (Column_Base + Start - Raw_Line'First + 1),
                  Enclosing_Scope => Scope_Id (Natural (Parent)),
                  Parent_Symbol   => Parent,
                  Depth           => Depth,
                  Flags           => Flags,
                  Target_Name     => Type_Target);
            begin
               if New_Id /= No_Symbol
                 and then Collected_Count < Max_Collected_Object_Names
               then
                  Collected_Count := Collected_Count + 1;
                  Collected (Collected_Count) := New_Id;
               end if;
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

end Editor.Ada_Declaration_Parser.Declaration_Collectors;
