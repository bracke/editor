with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings; use Ada.Strings;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Same_Line_Declarations is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate
        (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Has_Same_Line_Subtype_Group
     (Raw_Line   : String;
      Decl_Lower : String) return Boolean
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
   begin
      if not Starts_With_Word (Decl_Lower, "subtype")
        or else Code'Length <= 8
      then
         return False;
      end if;

      for I in Code'First .. Code'Last - 8 loop
         if Code (I) = ';'
           and then Starts_With_Word (Lower (Trim (Code (I + 1 .. Code'Last))), "subtype")
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Same_Line_Subtype_Group;

   function Has_Same_Line_Type_Group
     (Raw_Line   : String;
      Decl_Lower : String) return Boolean
   is
      Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Nesting : Natural := 0;
   begin
      if not Starts_With_Word (Decl_Lower, "type")
        or else Code'Length <= 5
      then
         return False;
      end if;

      for I in Code'First .. Code'Last - 5 loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';'
           and then Nesting = 0
           and then Starts_With_Word (Lower (Trim (Code (I + 1 .. Code'Last))), "type")
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Same_Line_Type_Group;

   function Strip_Override_Prefix (Segment : String) return String is
      S : constant String := Trim (Segment);
      L : constant String := Lower (S);
   begin
      if Starts_With (L, "not overriding ") then
         return Trim (S (S'First + 15 .. S'Last));
      elsif Starts_With (L, "overriding ") then
         return Trim (S (S'First + 11 .. S'Last));
      end if;

      return S;
   end Strip_Override_Prefix;

   function Strip_Callable_Prefix (Segment : String) return String is
      S : constant String := Strip_Override_Prefix (Segment);
      L : constant String := Lower (S);
   begin
      if Starts_With_Word (L, "with") then
         return Trim (S (S'First + 4 .. S'Last));
      end if;

      return S;
   end Strip_Callable_Prefix;

   function Starts_With_Callable_Segment (Segment : String) return Boolean is
      S : constant String := Strip_Callable_Prefix (Segment);
      L : constant String := Lower (S);
   begin
      return Starts_With_Word (L, "procedure")
        or else Starts_With_Word (L, "function");
   end Starts_With_Callable_Segment;

   function Has_Same_Line_Callable_Group
     (Raw_Line : String) return Boolean
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;
      Seen_First    : Boolean := False;
   begin
      if Code'Length = 0 then
         return False;
      end if;

      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            declare
               Segment : constant String := Raw_Line (Segment_Start .. I - 1);
            begin
               if not Seen_First then
                  if not Starts_With_Callable_Segment (Segment) then
                     return False;
                  end if;
                  Seen_First := True;
               else
                  if Starts_With_Callable_Segment (Segment) then
                     return True;
                  end if;
               end if;
            end;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Seen_First and then Segment_Start <= Raw_Line'Last then
         return Starts_With_Callable_Segment
           (Raw_Line (Segment_Start .. Raw_Line'Last));
      end if;

      return False;
   end Has_Same_Line_Callable_Group;

   function Starts_With_Package_Segment
     (Segment         : String;
      In_Generic_List : Boolean) return Boolean
   is
      S : constant String := Lower (Trim (Strip_Prefixes (Segment)));
   begin
      return Starts_With (S, "package body ")
        or else Starts_With_Word (S, "package")
        or else (In_Generic_List and then Starts_With (S, "with package "));
   end Starts_With_Package_Segment;

   function Has_Same_Line_Package_Group
     (Raw_Line        : String;
      Decl_Lower      : String;
      Pending_Generic : Boolean) return Boolean
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;
      Seen_First    : Boolean := False;
   begin
      if not Starts_With_Package_Segment (Raw_Line, Pending_Generic) then
         return False;
      elsif Has_Token (Decl_Lower, "is")
        and then not Has_Token (Decl_Lower, "new")
        and then not Has_Token (Decl_Lower, "renames")
      then
         return False;
      end if;

      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            if Segment_Start <= I - 1
              and then Starts_With_Package_Segment
                (Raw_Line (Segment_Start .. I - 1), Pending_Generic)
            then
               if Seen_First then
                  return True;
               end if;
               Seen_First := True;
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last
        and then Starts_With_Package_Segment
          (Raw_Line (Segment_Start .. Raw_Line'Last), Pending_Generic)
        and then Seen_First
      then
         return True;
      end if;

      return False;
   end Has_Same_Line_Package_Group;

   function Starts_With_Concurrent_Segment (Segment : String) return Boolean is
      S : constant String := Lower (Trim (Segment));
   begin
      return Starts_With (S, "task type ")
        or else Starts_With_Word (S, "task")
        or else Starts_With (S, "protected type ")
        or else Starts_With_Word (S, "protected")
        or else Starts_With_Word (S, "entry");
   end Starts_With_Concurrent_Segment;

   function Has_Same_Line_Concurrent_Group
     (Raw_Line   : String;
      Decl       : String;
      Decl_Lower : String) return Boolean
   is
      Code          : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Segment_Start : Natural := Raw_Line'First;
      Nesting       : Natural := 0;
      Seen_First    : Boolean := False;
   begin
      if not Starts_With_Concurrent_Segment (Decl) then
         return False;
      elsif Has_Token (Decl_Lower, "is") then
         return False;
      end if;

      for I in Code'Range loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';' and then Nesting = 0 then
            if Segment_Start <= I - 1
              and then Starts_With_Concurrent_Segment
                (Raw_Line (Segment_Start .. I - 1))
            then
               if Seen_First then
                  return True;
               end if;
               Seen_First := True;
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= Raw_Line'Last
        and then Starts_With_Concurrent_Segment
          (Raw_Line (Segment_Start .. Raw_Line'Last))
        and then Seen_First
      then
         return True;
      end if;

      return False;
   end Has_Same_Line_Concurrent_Group;

end Editor.Ada_Declaration_Parser.Same_Line_Declarations;
