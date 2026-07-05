with Editor.Ada_Declaration_Parser.Lexical_Helpers;
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

end Editor.Ada_Declaration_Parser.Declaration_Collectors;
