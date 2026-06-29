with Ada.Command_Line;
with Ada.Directories;
with Ada.Characters.Handling;
with Ada.Text_IO;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Ada_Keyword_Identifier_Check is
   use type Ada.Directories.File_Kind;

   Tool : constant String := "ada_keyword_identifier_check";

   Tool_Failed : Boolean := False;

   procedure Fail (Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   function Lower (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Lower;

   function Is_Ident_Start (C : Character) return Boolean is
   begin
      return C in 'A' .. 'Z' or else C in 'a' .. 'z';
   end Is_Ident_Start;

   function Is_Ident_Char (C : Character) return Boolean is
   begin
      return Is_Ident_Start (C) or else C in '0' .. '9' or else C = '_';
   end Is_Ident_Char;

   function Has_Ada_Source_Extension (Path : String) return Boolean is
   begin
      return (Path'Length >= 4 and then Lower (Path (Path'Last - 3 .. Path'Last)) = ".adb")
        or else (Path'Length >= 4 and then Lower (Path (Path'Last - 3 .. Path'Last)) = ".ads")
        or else (Path'Length >= 4 and then Lower (Path (Path'Last - 3 .. Path'Last)) = ".gpr");
   end Has_Ada_Source_Extension;

   function Is_Ada_Keyword (Word : String) return Boolean is
      W : constant String := Lower (Word);
   begin
      return W = "abort"
        or else W = "abs"
        or else W = "abstract"
        or else W = "accept"
        or else W = "access"
        or else W = "aliased"
        or else W = "all"
        or else W = "and"
        or else W = "array"
        or else W = "at"
        or else W = "begin"
        or else W = "body"
        or else W = "case"
        or else W = "constant"
        or else W = "declare"
        or else W = "delay"
        or else W = "delta"
        or else W = "digits"
        or else W = "do"
        or else W = "else"
        or else W = "elsif"
        or else W = "end"
        or else W = "entry"
        or else W = "exception"
        or else W = "exit"
        or else W = "for"
        or else W = "function"
        or else W = "generic"
        or else W = "goto"
        or else W = "if"
        or else W = "in"
        or else W = "interface"
        or else W = "is"
        or else W = "limited"
        or else W = "loop"
        or else W = "mod"
        or else W = "new"
        or else W = "not"
        or else W = "null"
        or else W = "of"
        or else W = "or"
        or else W = "others"
        or else W = "out"
        or else W = "overriding"
        or else W = "package"
        or else W = "parallel"
        or else W = "pragma"
        or else W = "private"
        or else W = "procedure"
        or else W = "protected"
        or else W = "raise"
        or else W = "range"
        or else W = "record"
        or else W = "rem"
        or else W = "renames"
        or else W = "requeue"
        or else W = "return"
        or else W = "reverse"
        or else W = "select"
        or else W = "separate"
        or else W = "some"
        or else W = "subtype"
        or else W = "synchronized"
        or else W = "tagged"
        or else W = "task"
        or else W = "terminate"
        or else W = "then"
        or else W = "type"
        or else W = "until"
        or else W = "use"
        or else W = "when"
        or else W = "while"
        or else W = "with"
        or else W = "xor";
   end Is_Ada_Keyword;

   function Source_Line (Line : String) return String is
      Result    : String := Line;
      In_String : Boolean := False;
      I         : Natural := Result'First;
   begin
      while I <= Result'Last loop
         if In_String then
            if Result (I) = '"' then
               if I < Result'Last and then Result (I + 1) = '"' then
                  Result (I) := ' ';
                  Result (I + 1) := ' ';
                  I := I + 2;
               else
                  In_String := False;
                  Result (I) := ' ';
                  I := I + 1;
               end if;
            else
               Result (I) := ' ';
               I := I + 1;
            end if;
         elsif Result (I) = '"' then
            In_String := True;
            Result (I) := ' ';
            I := I + 1;
         elsif I < Result'Last and then Result (I) = '-' and then Result (I + 1) = '-' then
            for J in I .. Result'Last loop
               Result (J) := ' ';
            end loop;
            return Result;
         else
            I := I + 1;
         end if;
      end loop;
      return Result;
   end Source_Line;

   procedure Report (Path : String; Line_No : Positive; Identifier : String; Context : String) is
   begin
      Fail
        (Path & ":" & Positive'Image (Line_No)
         & ": Ada keyword used as " & Context & " identifier: " & Identifier);
   end Report;

   procedure Check_Colon_Declaration (Path : String; Line_No : Positive; Line : String; Colon : Positive) is
      Left  : Natural := Colon - 1;
      First : Positive;
      Last  : Natural;
   begin
      if Colon < Line'Last and then Line (Colon + 1) = '=' then
         return;
      end if;
      if Colon > Line'First and then Line (Colon - 1) = ':' then
         return;
      end if;

      while Left >= Line'First and then Line (Left) = ' ' loop
         exit when Left = Line'First;
         Left := Left - 1;
      end loop;

      loop
         while Left >= Line'First and then Line (Left) = ' ' loop
            exit when Left = Line'First;
            Left := Left - 1;
         end loop;

         exit when Left < Line'First or else not Is_Ident_Char (Line (Left));
         Last := Left;
         while Left >= Line'First and then Is_Ident_Char (Line (Left)) loop
            exit when Left = Line'First;
            Left := Left - 1;
         end loop;

         if Left = Line'First and then Is_Ident_Char (Line (Left)) then
            First := Line'First;
         else
            First := Left + 1;
         end if;

         if Is_Ada_Keyword (Line (First .. Last)) then
            Report (Path, Line_No, Line (First .. Last), "object/field/parameter");
         end if;

         while Left >= Line'First and then Line (Left) = ' ' loop
            exit when Left = Line'First;
            Left := Left - 1;
         end loop;

         exit when Left < Line'First or else Line (Left) /= ',';
         if Left = Line'First then
            exit;
         end if;
         Left := Left - 1;
      end loop;
   end Check_Colon_Declaration;

   procedure Check_Header_Identifiers (Path : String; Line_No : Positive; Line : String) is
      Prev      : String (1 .. 32) := (others => ' ');
      Prev_Len  : Natural := 0;
      Prev2     : String (1 .. 32) := (others => ' ');
      Prev2_Len : Natural := 0;
      I         : Natural := Line'First;

      procedure Remember (Word : String) is
         W : constant String := Lower (Word);
      begin
         if Prev_Len > 0 then
            Prev2 (1 .. Prev_Len) := Prev (1 .. Prev_Len);
            Prev2_Len := Prev_Len;
         else
            Prev2_Len := 0;
         end if;

         if W'Length <= Prev'Length then
            Prev (1 .. W'Length) := W;
            Prev_Len := W'Length;
         else
            Prev_Len := 0;
         end if;
      end Remember;

      function Prev_Is (Word : String) return Boolean is
      begin
         return Prev_Len = Word'Length and then Prev (1 .. Prev_Len) = Word;
      end Prev_Is;

      function Prev2_Is (Word : String) return Boolean is
      begin
         return Prev2_Len = Word'Length and then Prev2 (1 .. Prev2_Len) = Word;
      end Prev2_Is;
   begin
      while I <= Line'Last loop
         if Is_Ident_Start (Line (I)) then
            declare
               First : constant Positive := I;
            begin
               while I <= Line'Last and then Is_Ident_Char (Line (I)) loop
                  I := I + 1;
               end loop;

               declare
                  Word : constant String := Line (First .. I - 1);
                  W    : constant String := Lower (Word);
               begin
                  if Is_Ada_Keyword (Word) then
                     if Prev_Is ("procedure")
                       or else Prev_Is ("function")
                       or else Prev_Is ("entry")
                       or else (Prev_Is ("package") and then W /= "body")
                       or else (Prev_Is ("body") and then Prev2_Is ("package"))
                       or else Prev_Is ("type")
                       or else Prev_Is ("subtype")
                       or else (Prev_Is ("type") and then Prev2_Is ("task"))
                       or else (Prev_Is ("type") and then Prev2_Is ("protected"))
                     then
                        Report (Path, Line_No, Word, "subprogram/type");
                     end if;
                  end if;
                  Remember (W);
               end;
            end;
         else
            I := I + 1;
         end if;
      end loop;
   end Check_Header_Identifiers;

   procedure Check_File (Path : String) is
      F       : Ada.Text_IO.File_Type;
      Buffer  : String (1 .. 4096);
      Last    : Natural;
      Line_No : Natural := 0;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Ada.Text_IO.Get_Line (F, Buffer, Last);
         Line_No := Line_No + 1;
         if Last > 0 then
            declare
               Clean : constant String := Source_Line (Buffer (1 .. Last));
            begin
               Check_Header_Identifiers (Path, Positive (Line_No), Clean);
               for I in Clean'Range loop
                  if Clean (I) = ':' then
                     Check_Colon_Declaration (Path, Positive (Line_No), Clean, I);
                  end if;
               end loop;
            end;
         end if;
      end loop;
      Ada.Text_IO.Close (F);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (F) then
            Ada.Text_IO.Close (F);
         end if;
         Fail ("unable to scan Ada identifiers in " & Path);
   end Check_File;

   procedure Check_Tree (Dir : String) is
      Search         : Ada.Directories.Search_Type;
      Search_Started : Boolean := False;
      Ent            : Ada.Directories.Directory_Entry_Type;
   begin
      if not Ada.Directories.Exists (Dir) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search,
         Dir,
         "*",
         (Ada.Directories.Ordinary_File => True,
          Ada.Directories.Directory      => True,
          others                         => False));
      Search_Started := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Ent);
         declare
            Full : constant String := Ada.Directories.Full_Name (Ent);
            Base : constant String := Ada.Directories.Simple_Name (Ent);
         begin
            if Base = "." or else Base = ".." then
               null;
            elsif Ada.Directories.Kind (Ent) = Ada.Directories.Directory then
               if Base /= "obj" and then Base /= "bin" and then Base /= "build" then
                  Check_Tree (Full);
               end if;
            elsif Has_Ada_Source_Extension (Full) then
               Check_File (Full);
            end if;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
   exception
      when Program_Error =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
      when others =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         Fail ("unable to complete Ada keyword identifier scan under " & Dir);
   end Check_Tree;

begin
   Check_Tree (".");
   Info (Tool, "completed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Ada_Keyword_Identifier_Check;
