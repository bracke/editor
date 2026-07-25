with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Static_Expressions;
with Editor.Ada_Type_Graph;
with Editor.Ada_Generic_Contracts.Core_Utilities;
with Editor.Ada_Generic_Contracts.Profile_Text;
with Editor.Ada_Generic_Contracts.Type_Conformance;

package body Editor.Ada_Generic_Contracts is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Kind;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Compatibility_Status;
   use Editor.Ada_Generic_Contracts.Type_Conformance;

   function Trim (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Contains;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer;
      Modulus    : Long_Long_Integer := Long_Long_Integer (Natural'Last))
      return Natural
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Hash_Mix;

   function Hash_Text (Text : String) return Natural
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Hash_Text;

   procedure Mix (Model : in out Generic_Contract_Model; Value : Natural)
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Mix;

   function Empty_Formal return Generic_Formal_Info
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Empty_Formal;

   function Empty_Instance return Generic_Instance_Info
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Empty_Instance;

   function Empty_Actual_Match return Generic_Actual_Match_Info
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Empty_Actual_Match;

   function Empty_Body_Contract_Visibility
     return Generic_Body_Contract_Visibility_Info
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Empty_Body_Contract_Visibility;

   function To_Formal_Kind
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind) return Generic_Formal_Kind
     renames Editor.Ada_Generic_Contracts.Core_Utilities.To_Formal_Kind;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Child_Label;


   function Explicit_Convention_For_Declaration
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      function Convention_From_Label (Label : String) return String is
         Lower : constant String := Normalize (Label);
         Marker : constant String := "convention =>";
         Pos : constant Natural := Ada.Strings.Fixed.Index (Lower, Marker);
         First : Natural;
         Last  : Natural;
      begin
         if Pos = 0 then
            return "";
         end if;
         First := Pos + Marker'Length;
         while First <= Lower'Last and then Lower (First) = ' ' loop
            First := First + 1;
         end loop;
         if First > Lower'Last then
            return "";
         end if;
         Last := First;
         while Last <= Lower'Last
           and then Lower (Last) /= ','
           and then Lower (Last) /= ';'
           and then Lower (Last) /= ' '
         loop
            Last := Last + 1;
         end loop;
         return Trim (Lower (First .. Last - 1));
      end Convention_From_Label;

      function Find_In_Subtree
        (Current : Editor.Ada_Syntax_Tree.Node_Id) return String
      is
         Current_Info : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, Current);
      begin
         if Current_Info.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Association then
            declare
               Aspect_Name : constant String :=
                 Normalize
                   (Child_Label
                      (Tree, Current, Editor.Ada_Syntax_Tree.Node_Aspect_Name));
               Aspect_Value : constant String :=
                 Normalize
                   (Child_Label
                      (Tree, Current, Editor.Ada_Syntax_Tree.Node_Aspect_Value));
            begin
               if Aspect_Name = "convention" then
                  if Aspect_Value = "" then
                     return "ada";
                  else
                     return Aspect_Value;
                  end if;
               end if;
            end;
         end if;

         for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Current) loop
            declare
               Found : constant String :=
                 Find_In_Subtree
                   (Editor.Ada_Syntax_Tree.Child_At (Tree, Current, Index));
            begin
               if Found /= "" then
                  return Found;
               end if;
            end;
         end loop;
         return "";
      end Find_In_Subtree;
   begin
      if Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      end if;
      declare
         Found : constant String := Find_In_Subtree (Node);
      begin
         if Found /= "" then
            return Found;
         else
            return Convention_From_Label
              (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Node).Label));
         end if;
      end;
   end Explicit_Convention_For_Declaration;

   function Convention_For_Declaration
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
      Explicit : constant String := Explicit_Convention_For_Declaration (Tree, Node);
   begin
      if Explicit = "" then
         return "ada";
      else
         return Explicit;
      end if;
   end Convention_For_Declaration;

   function Append_Normalized_Name
     (List : Unbounded_String;
      Name : String) return Unbounded_String
   is
      N : constant String := Normalize (Name);
   begin
      if N = "" then
         return List;
      elsif Length (List) = 0 then
         return To_Unbounded_String (N);
      else
         return List & "," & N;
      end if;
   end Append_Normalized_Name;

   function Actual_Kind_Image (Kind : Generic_Actual_Kind) return String is
   begin
      case Kind is
         when Generic_Actual_Type => return "type";
         when Generic_Actual_Object => return "object";
         when Generic_Actual_Subprogram => return "subprogram";
         when Generic_Actual_Package => return "package";
         when Generic_Actual_Malformed => return "malformed";
         when Generic_Actual_Unknown => return "unknown";
      end case;
   end Actual_Kind_Image;

   function Actual_Kind_From_Image (Text : String) return Generic_Actual_Kind is
      N : constant String := Normalize (Text);
   begin
      if N = "type" then
         return Generic_Actual_Type;
      elsif N = "object" then
         return Generic_Actual_Object;
      elsif N = "subprogram" then
         return Generic_Actual_Subprogram;
      elsif N = "package" then
         return Generic_Actual_Package;
      elsif N = "malformed" then
         return Generic_Actual_Malformed;
      else
         return Generic_Actual_Unknown;
      end if;
   end Actual_Kind_From_Image;

   function Append_Kind
     (List : Unbounded_String;
      Kind : Generic_Actual_Kind) return Unbounded_String is
   begin
      if Length (List) = 0 then
         return To_Unbounded_String (Actual_Kind_Image (Kind));
      else
         return List & "," & Actual_Kind_Image (Kind);
      end if;
   end Append_Kind;

   function Append_Text
     (List : Unbounded_String;
      Text : String) return Unbounded_String
   is
      T : constant String := Trim (Text);
   begin
      if Length (List) = 0 then
         return To_Unbounded_String (T);
      else
         return List & "|" & T;
      end if;
   end Append_Text;

   function Append_Named_Text
     (List : Unbounded_String;
      Name : String;
      Text : String) return Unbounded_String
   is
      N : constant String := Normalize (Name);
      T : constant String := Trim (Text);
   begin
      if N = "" then
         return List;
      elsif Length (List) = 0 then
         return To_Unbounded_String (N & "=" & T);
      else
         return List & "|" & N & "=" & T;
      end if;
   end Append_Named_Text;

   function Append_Named_Kind
     (List : Unbounded_String;
      Name : String;
      Kind : Generic_Actual_Kind) return Unbounded_String
   is
      N : constant String := Normalize (Name);
   begin
      if N = "" then
         return List;
      elsif Length (List) = 0 then
         return To_Unbounded_String (N & "=" & Actual_Kind_Image (Kind));
      else
         return List & "," & N & "=" & Actual_Kind_Image (Kind);
      end if;
   end Append_Named_Kind;

   function Predefined_Type_Name (Name : String) return Boolean is
      N : constant String := Normalize (Name);
   begin
      return N = "integer" or else N = "natural" or else N = "positive"
        or else N = "float" or else N = "long_float" or else N = "short_float"
        or else N = "string" or else N = "character" or else N = "boolean"
        or else N = "duration" or else N = "wide_string"
        or else N = "wide_wide_string";
   end Predefined_Type_Name;

   function Is_Numeric_Literal (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      if T = "" then
         return False;
      end if;
      for C of T loop
         if C in '0' .. '9' then
            return True;
         elsif C /= '_' and then C /= '.' and then C /= '#' and then C /= 'e'
           and then C /= 'E' and then C /= '+' and then C /= '-'
         then
            return False;
         end if;
      end loop;
      return True;
   end Is_Numeric_Literal;

   function Declaration_To_Actual_Kind
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind) return Generic_Actual_Kind is
   begin
      case Kind is
         when Editor.Ada_Direct_Visibility.Declaration_Type
            | Editor.Ada_Direct_Visibility.Declaration_Subtype
            | Editor.Ada_Direct_Visibility.Declaration_Formal_Type =>
            return Generic_Actual_Type;
         when Editor.Ada_Direct_Visibility.Declaration_Object
            | Editor.Ada_Direct_Visibility.Declaration_Number
            | Editor.Ada_Direct_Visibility.Declaration_Formal_Object =>
            return Generic_Actual_Object;
         when Editor.Ada_Direct_Visibility.Declaration_Subprogram
            | Editor.Ada_Direct_Visibility.Declaration_Entry
            | Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram =>
            return Generic_Actual_Subprogram;
         when Editor.Ada_Direct_Visibility.Declaration_Package
            | Editor.Ada_Direct_Visibility.Declaration_Formal_Package
            | Editor.Ada_Direct_Visibility.Declaration_Instantiation =>
            return Generic_Actual_Package;
         when others =>
            return Generic_Actual_Unknown;
      end case;
   end Declaration_To_Actual_Kind;

   function Classify_Actual_Kind (Text : String) return Generic_Actual_Kind is
      Value : constant String := Trim (Text);
      Lower : constant String := Ada.Characters.Handling.To_Lower (Value);
   begin
      if Value = "" then
         return Generic_Actual_Malformed;
      elsif Ada.Strings.Fixed.Index (Lower, "'image") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "'value") /= 0
        or else Ada.Strings.Fixed.Index (Lower, """") /= 0
      then
         return Generic_Actual_Subprogram;
      elsif Ada.Strings.Fixed.Index (Lower, "new ") = Lower'First then
         return Generic_Actual_Package;
      elsif Is_Numeric_Literal (Value) then
         return Generic_Actual_Object;
      elsif Predefined_Type_Name (Value) then
         return Generic_Actual_Type;
      else
         return Generic_Actual_Unknown;
      end if;
   end Classify_Actual_Kind;


   function Resolve_Actual_Kind
     (Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text        : String;
      Fallback    : Generic_Actual_Kind) return Generic_Actual_Kind
   is
      N : constant String := Normalize (Text);
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
   begin
      if Fallback /= Generic_Actual_Unknown then
         return Fallback;
      elsif N = "" or else Ada.Strings.Fixed.Index (N, "'") /= 0 then
         return Fallback;
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, From_Region, N);
      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
         return Declaration_To_Actual_Kind
           (Editor.Ada_Direct_Visibility.Declaration
              (Visibility, Lookup.Declaration).Kind);
      end if;
      return Fallback;
   end Resolve_Actual_Kind;

   function Kind_Compatible
     (Formal : Generic_Formal_Kind;
      Actual : Generic_Actual_Kind) return Generic_Formal_Actual_Kind_Match is
   begin
      if Actual = Generic_Actual_Unknown then
         return Generic_Formal_Actual_Kind_Unknown;
      elsif Actual = Generic_Actual_Malformed then
         return Generic_Formal_Actual_Kind_Mismatch;
      end if;

      case Formal is
         when Generic_Formal_Type =>
            return (if Actual = Generic_Actual_Type then Generic_Formal_Actual_Kind_Matches
                    else Generic_Formal_Actual_Kind_Mismatch);
         when Generic_Formal_Object =>
            return (if Actual = Generic_Actual_Object then Generic_Formal_Actual_Kind_Matches
                    else Generic_Formal_Actual_Kind_Mismatch);
         when Generic_Formal_Subprogram =>
            return (if Actual = Generic_Actual_Subprogram then Generic_Formal_Actual_Kind_Matches
                    else Generic_Formal_Actual_Kind_Mismatch);
         when Generic_Formal_Package =>
            return (if Actual = Generic_Actual_Package then Generic_Formal_Actual_Kind_Matches
                    else Generic_Formal_Actual_Kind_Mismatch);
         when Generic_Formal_Unknown =>
            return Generic_Formal_Actual_Kind_Unknown;
      end case;
   end Kind_Compatible;

   function List_Contains_Name (List : String; Name : String) return Boolean is
      N     : constant String := Normalize (Name);
      First : Natural := List'First;
   begin
      if N = "" then
         return False;
      end if;

      while First <= List'Last loop
         declare
            Comma : Natural := Ada.Strings.Fixed.Index (List (First .. List'Last), ",");
            Last  : Natural := List'Last;
         begin
            if Comma /= 0 then
               Last := Comma - 1;
            end if;

            if Normalize (List (First .. Last)) = N then
               return True;
            end if;

            exit when Comma = 0;
            First := Comma + 1;
         end;
      end loop;
      return False;
   end List_Contains_Name;

   function Count_Unknown_Named_Actuals
     (Named_Names  : String;
      Formal_Names : String) return Natural
   is
      Count : Natural := 0;
      First : Natural := Named_Names'First;
   begin
      if Named_Names = "" then
         return 0;
      end if;

      while First <= Named_Names'Last loop
         declare
            Comma : Natural := Ada.Strings.Fixed.Index (Named_Names (First .. Named_Names'Last), ",");
            Last  : Natural := Named_Names'Last;
         begin
            if Comma /= 0 then
               Last := Comma - 1;
            end if;
            if not List_Contains_Name (Formal_Names, Named_Names (First .. Last)) then
               Count := Count + 1;
            end if;
            exit when Comma = 0;
            First := Comma + 1;
         end;
      end loop;
      return Count;
   end Count_Unknown_Named_Actuals;

   function Count_Duplicate_Named_Actuals (Named_Names : String) return Natural is
      Count : Natural := 0;
      First : Natural := Named_Names'First;
   begin
      if Named_Names = "" then
         return 0;
      end if;

      while First <= Named_Names'Last loop
         declare
            Comma : Natural := Ada.Strings.Fixed.Index (Named_Names (First .. Named_Names'Last), ",");
            Last  : Natural := Named_Names'Last;
            This  : Unbounded_String;
            Seen  : Boolean := False;
            Scan  : Natural := Named_Names'First;
         begin
            if Comma /= 0 then
               Last := Comma - 1;
            end if;
            This := To_Unbounded_String (Normalize (Named_Names (First .. Last)));

            while Scan < First loop
               declare
                  Next_Comma : Natural := Ada.Strings.Fixed.Index (Named_Names (Scan .. Named_Names'Last), ",");
                  Scan_Last  : Natural := Named_Names'Last;
               begin
                  if Next_Comma /= 0 then
                     Scan_Last := Next_Comma - 1;
                  end if;
                  if Normalize (Named_Names (Scan .. Scan_Last)) = To_String (This) then
                     Seen := True;
                     exit;
                  end if;
                  exit when Next_Comma = 0;
                  Scan := Next_Comma + 1;
               end;
            end loop;

            if Seen then
               Count := Count + 1;
            end if;

            exit when Comma = 0;
            First := Comma + 1;
         end;
      end loop;
      return Count;
   end Count_Duplicate_Named_Actuals;


   function Positional_Kind_At
     (Kinds : String;
      Index : Positive) return Generic_Actual_Kind
   is
      First : Natural := Kinds'First;
      Pos   : Positive := 1;
   begin
      if Kinds = "" then
         return Generic_Actual_Unknown;
      end if;
      while First <= Kinds'Last loop
         declare
            Comma : Natural := Ada.Strings.Fixed.Index (Kinds (First .. Kinds'Last), ",");
            Last  : Natural := Kinds'Last;
         begin
            if Comma /= 0 then
               Last := Comma - 1;
            end if;
            if Pos = Index then
               return Actual_Kind_From_Image (Kinds (First .. Last));
            end if;
            exit when Comma = 0;
            First := Comma + 1;
            Pos := Pos + 1;
         end;
      end loop;
      return Generic_Actual_Unknown;
   end Positional_Kind_At;

   function Named_Kind_For
     (Kinds : String;
      Name  : String) return Generic_Actual_Kind
   is
      N     : constant String := Normalize (Name);
      First : Natural := Kinds'First;
   begin
      if Kinds = "" or else N = "" then
         return Generic_Actual_Unknown;
      end if;
      while First <= Kinds'Last loop
         declare
            Comma : Natural := Ada.Strings.Fixed.Index (Kinds (First .. Kinds'Last), ",");
            Last  : Natural := Kinds'Last;
            Eq    : Natural;
         begin
            if Comma /= 0 then
               Last := Comma - 1;
            end if;
            Eq := Ada.Strings.Fixed.Index (Kinds (First .. Last), "=");
            if Eq /= 0 and then Normalize (Kinds (First .. Eq - 1)) = N then
               return Actual_Kind_From_Image (Kinds (Eq + 1 .. Last));
            end if;
            exit when Comma = 0;
            First := Comma + 1;
         end;
      end loop;
      return Generic_Actual_Unknown;
   end Named_Kind_For;

   procedure Count_Actuals
     (Text             : String;
      Positional       : out Natural;
      Named            : out Natural;
      Named_Names      : out Unbounded_String;
      Positional_Kinds : out Unbounded_String;
      Named_Kinds      : out Unbounded_String;
      Positional_Texts : out Unbounded_String;
      Named_Texts      : out Unbounded_String;
      Malformed        : out Boolean)
   is
      T     : constant String := Trim (Text);
      Open  : Natural := 0;
      Close : Natural := 0;
      Depth : Natural := 0;
      First : Natural := 0;

      procedure Add_Actual (Lo, Hi : Natural) is
         Segment : constant String := Trim (T (Lo .. Hi));
         Arrow   : constant Natural := Ada.Strings.Fixed.Index (Segment, "=>");
      begin
         if Segment = "" then
            Malformed := True;
         elsif Arrow /= 0 then
            Named := Named + 1;
            Named_Names := Append_Normalized_Name (Named_Names, Segment (Segment'First .. Arrow - 1));
            Named_Kinds := Append_Named_Kind
              (Named_Kinds, Segment (Segment'First .. Arrow - 1),
               Classify_Actual_Kind (Segment (Arrow + 2 .. Segment'Last)));
            Named_Texts := Append_Named_Text
              (Named_Texts, Segment (Segment'First .. Arrow - 1),
               Segment (Arrow + 2 .. Segment'Last));
         else
            Positional := Positional + 1;
            Positional_Kinds := Append_Kind (Positional_Kinds, Classify_Actual_Kind (Segment));
            Positional_Texts := Append_Text (Positional_Texts, Segment);
         end if;
      end Add_Actual;
   begin
      Positional := 0;
      Named := 0;
      Named_Names := Null_Unbounded_String;
      Positional_Kinds := Null_Unbounded_String;
      Named_Kinds := Null_Unbounded_String;
      Positional_Texts := Null_Unbounded_String;
      Named_Texts := Null_Unbounded_String;
      Malformed := False;

      for I in T'Range loop
         if T (I) = '(' then
            Open := I;
            exit;
         end if;
      end loop;

      if Open = 0 then
         return;
      end if;

      Depth := 1;
      for I in Open + 1 .. T'Last loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' then
            if Depth = 1 then
               Close := I;
               exit;
            else
               Depth := Depth - 1;
            end if;
         end if;
      end loop;

      if Close = 0 then
         Malformed := True;
         Close := T'Last + 1;
      end if;

      if Close = Open + 1 then
         return;
      end if;

      First := Open + 1;
      Depth := 0;
      for I in Open + 1 .. Close - 1 loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' then
            if Depth = 0 then
               Malformed := True;
            else
               Depth := Depth - 1;
            end if;
         elsif T (I) = ',' and then Depth = 0 then
            if I > First then
               Add_Actual (First, I - 1);
            else
               Malformed := True;
            end if;
            First := I + 1;
         end if;
      end loop;

      if First <= Close - 1 then
         Add_Actual (First, Close - 1);
      end if;

      if Depth /= 0 then
         Malformed := True;
      end if;
   end Count_Actuals;

   function Generic_Name_From_Label (Text : String) return String is
      T   : constant String := Trim (Text);
      Pos : Natural := Ada.Strings.Fixed.Index (Ada.Characters.Handling.To_Lower (T), " is new ");
      First : Natural;
      Last  : Natural;
   begin
      if Pos = 0 then
         return "";
      end if;
      First := Pos + 8;
      Last := T'Last;
      for I in First .. T'Last loop
         if T (I) = '(' or else T (I) = ';' then
            Last := I - 1;
            exit;
         end if;
      end loop;
      if Last < First then
         return "";
      end if;
      return Trim (T (First .. Last));
   end Generic_Name_From_Label;


   function Inline_Instance_Generic_Name (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Ada.Characters.Handling.To_Lower (T);
      First : Natural := 0;
      Last  : Natural := 0;
   begin
      if Ada.Strings.Fixed.Index (Lower, "new ") /= Lower'First then
         return "";
      end if;
      First := T'First + 4;
      Last := T'Last;
      for I in First .. T'Last loop
         if T (I) = '(' or else T (I) = ';' then
            Last := I - 1;
            exit;
         end if;
      end loop;
      if Last < First then
         return "";
      end if;
      return Trim (T (First .. Last));
   end Inline_Instance_Generic_Name;

   function Formal_Package_Has_Box_Actuals (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
   begin
      return Ada.Strings.Fixed.Index (Lower, "<>") /= 0;
   end Formal_Package_Has_Box_Actuals;

   function Default_Text_From_Label (Text : String) return String is
      T : constant String := Trim (Text);
      Pos : constant Natural := Ada.Strings.Fixed.Index (T, ":=");
      Last : Natural := T'Last;
   begin
      if Pos = 0 then
         return "";
      end if;
      for I in reverse Pos + 2 .. T'Last loop
         if T (I) = ';' then
            Last := I - 1;
            exit;
         end if;
      end loop;
      if Pos + 2 > Last then
         return "";
      end if;
      return Trim (T (Pos + 2 .. Last));
   end Default_Text_From_Label;

   function Result_Subtype_From_Label (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      R : constant Natural := Ada.Strings.Fixed.Index (N, " return ");
      Last : Natural := T'Last;
   begin
      if R = 0 then
         return "";
      end if;
      for I in R + 8 .. T'Last loop
         if T (I) = ';' then
            Last := I - 1;
            exit;
         elsif I + 3 <= T'Last and then Normalize (T (I .. I + 3)) = " is " then
            Last := I - 1;
            exit;
         end if;
      end loop;
      if R + 8 > Last then
         return "";
      end if;
      return Normalize (T (R + 8 .. Last));
   end Result_Subtype_From_Label;


   function Delimited_Text_At
     (List  : String;
      Index : Positive) return String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Delimited_Text_At;

   function Named_Text_For
     (List : String;
      Name : String) return String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Named_Text_For;

   function Strip_Default_And_Mode (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Strip_Default_And_Mode;

   function Append_Repeated_Subtype
     (List  : Unbounded_String;
      Count : Natural;
      Text  : String) return Unbounded_String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Append_Repeated_Subtype;

   function Mode_From_Parameter_Tail (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Mode_From_Parameter_Tail;

   function Append_Repeated_Mode
     (List  : Unbounded_String;
      Count : Natural;
      Text  : String) return Unbounded_String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Append_Repeated_Mode;

   function Default_From_Parameter_Tail (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Default_From_Parameter_Tail;

   function Append_Repeated_Default
     (List  : Unbounded_String;
      Count : Natural;
      Text  : String) return Unbounded_String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Append_Repeated_Default;

   function Append_Parameter_Names
     (List  : Unbounded_String;
      Names : String) return Unbounded_String
     renames Editor.Ada_Generic_Contracts.Profile_Text.Append_Parameter_Names;

   function Parameter_Defaults_Conform
     (Formal_Defaults : String;
      Actual_Defaults : String) return Boolean
     renames Editor.Ada_Generic_Contracts.Profile_Text.Parameter_Defaults_Conform;

   procedure Analyze_Subprogram_Profile
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Node       : Editor.Ada_Syntax_Tree.Node_Id;
      Parameters : out Natural;
      Subtypes   : out Unbounded_String;
      Modes      : out Unbounded_String;
      Names      : out Unbounded_String;
      Defaults   : out Unbounded_String;
      Has_Result : out Boolean;
      Result     : out Unbounded_String;
      Malformed  : out Boolean)
     renames Editor.Ada_Generic_Contracts.Profile_Text.Analyze_Subprogram_Profile;


   package Formal_Collection is
      procedure Add_Formal
        (Model : in out Generic_Contract_Model;
         Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
         Decl  : Editor.Ada_Direct_Visibility.Declaration_Info);
   end Formal_Collection;

   package body Formal_Collection is separate;

   package Default_Expression_Checks is
      procedure Classify_Object_Expression
        (Info       : in out Generic_Actual_Match_Info;
         Static     : Editor.Ada_Static_Expressions.Static_Model;
         Region     : Editor.Ada_Declarative_Regions.Region_Id;
         Expression : String);
   end Default_Expression_Checks;

   package body Default_Expression_Checks is separate;

   package Instance_Matching is
      procedure Add_Instance
        (Model : in out Generic_Contract_Model;
         Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
         Decl  : Editor.Ada_Direct_Visibility.Declaration_Info);

      procedure Add_Actual_Match
        (Model      : in out Generic_Contract_Model;
         Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
         Regions    : Editor.Ada_Declarative_Regions.Region_Model;
         Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
         Instance   : Generic_Instance_Info;
         Static     : Editor.Ada_Static_Expressions.Static_Model;
         Check_Default_Expressions : Boolean;
         Types      : Editor.Ada_Type_Graph.Type_Model;
         Check_Type_Graph : Boolean);
   end Instance_Matching;

   package body Instance_Matching is separate;

   package Body_Visibility is
      procedure Add_Body_Contract_Visibility_All
        (Model      : in out Generic_Contract_Model;
         Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
         Regions    : Editor.Ada_Declarative_Regions.Region_Model;
         Visibility : Editor.Ada_Direct_Visibility.Visibility_Model);
   end Body_Visibility;

   package body Body_Visibility is separate;

   procedure Clear (Model : in out Generic_Contract_Model) is
   begin
      Model.Formals.Clear;
      Model.Instances.Clear;
      Model.Actual_Matches.Clear;
      Model.Body_Contract_Visibility.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build_Internal
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Check_Default_Expressions : Boolean;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean)
      return Generic_Contract_Model
   is
      Model : Generic_Contract_Model;
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            case Decl.Kind is
               when Editor.Ada_Direct_Visibility.Declaration_Formal_Type
                  | Editor.Ada_Direct_Visibility.Declaration_Formal_Object
                  | Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram
                  | Editor.Ada_Direct_Visibility.Declaration_Formal_Package =>
                  Formal_Collection.Add_Formal (Model, Tree, Decl);
               when Editor.Ada_Direct_Visibility.Declaration_Instantiation =>
                  Instance_Matching.Add_Instance (Model, Tree, Decl);
               when others =>
                  null;
            end case;
         end;
      end loop;

      for Info of Model.Instances loop
         Instance_Matching.Add_Actual_Match
           (Model, Tree, Regions, Visibility, Info,
            Static, Check_Default_Expressions, Types, Check_Type_Graph);
      end loop;

      Body_Visibility.Add_Body_Contract_Visibility_All (Model, Tree, Regions, Visibility);

      return Model;
   end Build_Internal;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Generic_Contract_Model
   is
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Types  : Editor.Ada_Type_Graph.Type_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Static, False, Types, False);
   end Build;



   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model)
      return Generic_Contract_Model
   is
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
   begin
      return Build (Tree, Regions, Visibility);
   end Build;

   function Build_With_Static
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model)
      return Generic_Contract_Model
   is
      Types : Editor.Ada_Type_Graph.Type_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Static, True, Types, False);
   end Build_With_Static;

   function Build_With_Type_Graph
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model)
      return Generic_Contract_Model
   is
      Static : Editor.Ada_Static_Expressions.Static_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Static, False, Types, True);
   end Build_With_Type_Graph;

   function Build_With_Static_And_Type_Graph
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model)
      return Generic_Contract_Model
   is
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Static, True, Types, True);
   end Build_With_Static_And_Type_Graph;

   function Has_Formals (Model : Generic_Contract_Model) return Boolean is
   begin
      return not Model.Formals.Is_Empty;
   end Has_Formals;

   function Formal_Count (Model : Generic_Contract_Model) return Natural is
   begin
      return Natural (Model.Formals.Length);
   end Formal_Count;

   function Formal_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Formal_Info is
   begin
      if Index > Natural (Model.Formals.Length) then
         return Empty_Formal;
      end if;
      return Model.Formals.Element (Index);
   end Formal_At;

   function Formal
     (Model : Generic_Contract_Model;
      Id    : Generic_Formal_Id) return Generic_Formal_Info is
   begin
      if Id = No_Generic_Formal or else Natural (Id) > Natural (Model.Formals.Length) then
         return Empty_Formal;
      end if;
      return Model.Formals.Element (Positive (Id));
   end Formal;

   function Formal_Count_In_Region
     (Model  : Generic_Contract_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Formals loop
         if Info.Region = Region then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Formal_Count_In_Region;

   function Defaulted_Formal_Count_In_Region
     (Model  : Generic_Contract_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Formals loop
         if Info.Region = Region and then Info.Has_Default then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Defaulted_Formal_Count_In_Region;

   function Has_Instances (Model : Generic_Contract_Model) return Boolean is
   begin
      return not Model.Instances.Is_Empty;
   end Has_Instances;

   function Instance_Count (Model : Generic_Contract_Model) return Natural is
   begin
      return Natural (Model.Instances.Length);
   end Instance_Count;

   function Instance_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Instance_Info is
   begin
      if Index > Natural (Model.Instances.Length) then
         return Empty_Instance;
      end if;
      return Model.Instances.Element (Index);
   end Instance_At;

   function Instance
     (Model : Generic_Contract_Model;
      Id    : Generic_Instance_Id) return Generic_Instance_Info is
   begin
      if Id = No_Generic_Instance or else Natural (Id) > Natural (Model.Instances.Length) then
         return Empty_Instance;
      end if;
      return Model.Instances.Element (Positive (Id));
   end Instance;

   function Actual_Match_Count (Model : Generic_Contract_Model) return Natural is
   begin
      return Natural (Model.Actual_Matches.Length);
   end Actual_Match_Count;

   function Actual_Match_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Actual_Match_Info is
   begin
      if Index > Natural (Model.Actual_Matches.Length) then
         return Empty_Actual_Match;
      end if;
      return Model.Actual_Matches.Element (Index);
   end Actual_Match_At;

   function Actual_Match_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Generic_Actual_Match_Info is
   begin
      for Info of Model.Actual_Matches loop
         if Info.Instance = Instance then
            return Info;
         end if;
      end loop;
      return Empty_Actual_Match;
   end Actual_Match_For_Instance;

   function Kind_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Kind_Mismatched_Formals;
   end Kind_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Subprogram_Profile_Mismatched_Formals;
   end Subprogram_Profile_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Mode_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Mode_Mismatched_Formals;
   end Subprogram_Profile_Mode_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Null_Exclusion_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Null_Exclusion_Mismatched_Formals;
   end Subprogram_Profile_Null_Exclusion_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Access_Profile_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Access_Profile_Mismatched_Formals;
   end Subprogram_Profile_Access_Profile_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Convention_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Convention_Mismatched_Formals;
   end Subprogram_Profile_Convention_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Default_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Default_Mismatched_Formals;
   end Subprogram_Profile_Default_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Class_Wide_Mismatched_Formals;
   end Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Name_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Name_Mismatched_Formals;
   end Subprogram_Profile_Name_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Result_Compatible_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Result_Compatible_Formals;
   end Subprogram_Profile_Result_Compatible_Count_For_Instance;

   function Subprogram_Profile_Result_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Result_Mismatched_Formals;
   end Subprogram_Profile_Result_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Result_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Result_Unknown_Formals;
   end Subprogram_Profile_Result_Unknown_Count_For_Instance;

   function Subprogram_Profile_Type_Compatible_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Type_Compatible_Formals;
   end Subprogram_Profile_Type_Compatible_Count_For_Instance;

   function Subprogram_Profile_Type_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Type_Mismatched_Formals;
   end Subprogram_Profile_Type_Mismatch_Count_For_Instance;

   function Subprogram_Profile_Type_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Type_Unknown_Formals;
   end Subprogram_Profile_Type_Unknown_Count_For_Instance;

   function Subprogram_Profile_Overload_Selected_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Overload_Selected_Formals;
   end Subprogram_Profile_Overload_Selected_Count_For_Instance;

   function Subprogram_Profile_Overload_Ambiguous_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Overload_Ambiguous_Formals;
   end Subprogram_Profile_Overload_Ambiguous_Count_For_Instance;

   function Subprogram_Profile_Overload_Unresolved_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance
        (Model, Instance).Subprogram_Profile_Overload_Unresolved_Formals;
   end Subprogram_Profile_Overload_Unresolved_Count_For_Instance;

   function Formal_Package_Compatible_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Formal_Package_Compatible_Formals;
   end Formal_Package_Compatible_Count_For_Instance;

   function Formal_Package_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Formal_Package_Mismatched_Formals;
   end Formal_Package_Mismatch_Count_For_Instance;

   function Formal_Package_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Formal_Package_Unknown_Formals;
   end Formal_Package_Unknown_Count_For_Instance;


   function Default_Expression_Static_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Default_Expression_Static_Formals;
   end Default_Expression_Static_Count_For_Instance;

   function Default_Expression_Illegal_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Default_Expression_Illegal_Formals;
   end Default_Expression_Illegal_Count_For_Instance;

   function Default_Expression_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural is
   begin
      return Actual_Match_For_Instance (Model, Instance).Default_Expression_Unknown_Formals;
   end Default_Expression_Unknown_Count_For_Instance;

   function Body_Contract_Visibility_Count
     (Model : Generic_Contract_Model) return Natural is
   begin
      return Natural (Model.Body_Contract_Visibility.Length);
   end Body_Contract_Visibility_Count;

   function Body_Contract_Visibility_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Body_Contract_Visibility_Info is
   begin
      if Index > Natural (Model.Body_Contract_Visibility.Length) then
         return Empty_Body_Contract_Visibility;
      end if;
      return Model.Body_Contract_Visibility.Element (Index);
   end Body_Contract_Visibility_At;

   function Body_Contract_Visibility_For_Body
     (Model       : Generic_Contract_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id)
      return Generic_Body_Contract_Visibility_Info is
   begin
      for Info of Model.Body_Contract_Visibility loop
         if Info.Body_Region = Body_Region then
            return Info;
         end if;
      end loop;
      return Empty_Body_Contract_Visibility;
   end Body_Contract_Visibility_For_Body;

   function Body_Formal
     (Model       : Generic_Contract_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name        : String) return Generic_Formal_Info
   is
      Body_Info : constant Generic_Body_Contract_Visibility_Info :=
        Body_Contract_Visibility_For_Body (Model, Body_Region);
      N : constant String := Normalize (Name);
   begin
      if Body_Info.Status /= Generic_Body_Contract_Visible or else N = ""
        or else List_Contains_Name (To_String (Body_Info.Shadowed_Formal_Names), N)
      then
         return Empty_Formal;
      end if;
      for Formal_Info of Model.Formals loop
         if Formal_Info.Region = Body_Info.Generic_Formal_Region
           and then To_String (Formal_Info.Normalized_Name) = N
         then
            return Formal_Info;
         end if;
      end loop;
      return Empty_Formal;
   end Body_Formal;

   function Body_Formal_Visible
     (Model       : Generic_Contract_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name        : String) return Boolean is
   begin
      return Body_Formal (Model, Body_Region, Name).Id /= No_Generic_Formal;
   end Body_Formal_Visible;


   function Fingerprint (Model : Generic_Contract_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Contracts;
