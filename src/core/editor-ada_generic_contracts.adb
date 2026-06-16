with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Static_Expressions;
with Editor.Ada_Type_Graph;

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

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Pattern'Length = 0
        or else Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer;
      Modulus    : Long_Long_Integer := Long_Long_Integer (Natural'Last))
      return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Modulus);
   end Hash_Mix;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := Hash_Mix
           (H, Long_Long_Integer (Character'Pos (C)) + 1, 16_777_619);
      end loop;
      return H;
   end Hash_Text;

   procedure Mix (Model : in out Generic_Contract_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        Hash_Mix (Model.Result_Fingerprint, Long_Long_Integer (Value) + 197, 65_599);
   end Mix;

   function Empty_Formal return Generic_Formal_Info is
   begin
      return (Id => No_Generic_Formal,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Kind => Generic_Formal_Unknown,
              Has_Default => False,
              Default_Text => Null_Unbounded_String,
              Formal_Parameter_Count => 0,
              Formal_Parameter_Subtypes => Null_Unbounded_String,
              Formal_Parameter_Modes => Null_Unbounded_String,
              Formal_Parameter_Names => Null_Unbounded_String,
              Formal_Parameter_Defaults => Null_Unbounded_String,
              Formal_Subprogram_Convention => Null_Unbounded_String,
              Formal_Has_Result => False,
              Formal_Result_Subtype => Null_Unbounded_String,
              Formal_Package_Generic_Name => Null_Unbounded_String,
              Formal_Package_Normalized_Generic => Null_Unbounded_String,
              Formal_Package_Has_Box => False,
              Status => Generic_Formal_Unsupported,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Formal;

   function Empty_Instance return Generic_Instance_Info is
   begin
      return (Id => No_Generic_Instance,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Generic_Name => Null_Unbounded_String,
              Normalized_Generic => Null_Unbounded_String,
              Positional_Actuals => 0,
              Named_Actuals => 0,
              Total_Actuals => 0,
              Named_Actual_Names => Null_Unbounded_String,
              Positional_Actual_Kinds => Null_Unbounded_String,
              Named_Actual_Kinds => Null_Unbounded_String,
              Positional_Actual_Texts => Null_Unbounded_String,
              Named_Actual_Texts => Null_Unbounded_String,
              Status => Generic_Instance_Unsupported,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Instance;

   function Empty_Actual_Match return Generic_Actual_Match_Info is
   begin
      return (Id => No_Generic_Actual_Match,
              Instance => No_Generic_Instance,
              Instance_Node => Editor.Ada_Syntax_Tree.No_Node,
              Instance_Region => Editor.Ada_Declarative_Regions.No_Region,
              Generic_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Generic_Formal_Region => Editor.Ada_Declarative_Regions.No_Region,
              Formal_Count => 0,
              Required_Formals => 0,
              Positional_Actuals => 0,
              Named_Actuals => 0,
              Matched_Formals => 0,
              Defaulted_Formals => 0,
              Unknown_Named_Actuals => 0,
              Duplicate_Named_Actuals => 0,
              Missing_Required_Formals => 0,
              Kind_Compatible_Formals => 0,
              Kind_Mismatched_Formals => 0,
              Kind_Unknown_Formals => 0,
              Subprogram_Profile_Compatible_Formals => 0,
              Subprogram_Profile_Mismatched_Formals => 0,
              Subprogram_Profile_Unknown_Formals => 0,
              Subprogram_Profile_Mode_Mismatched_Formals => 0,
              Subprogram_Profile_Null_Exclusion_Mismatched_Formals => 0,
              Subprogram_Profile_Access_Profile_Mismatched_Formals => 0,
              Subprogram_Profile_Convention_Mismatched_Formals => 0,
              Subprogram_Profile_Default_Mismatched_Formals => 0,
              Subprogram_Profile_Class_Wide_Mismatched_Formals => 0,
              Subprogram_Profile_Name_Mismatched_Formals => 0,
              Subprogram_Profile_Result_Compatible_Formals => 0,
              Subprogram_Profile_Result_Mismatched_Formals => 0,
              Subprogram_Profile_Result_Unknown_Formals => 0,
              Subprogram_Profile_Type_Compatible_Formals => 0,
              Subprogram_Profile_Type_Mismatched_Formals => 0,
              Subprogram_Profile_Type_Unknown_Formals => 0,
              Subprogram_Profile_Overload_Candidates => 0,
              Subprogram_Profile_Overload_Selected_Formals => 0,
              Subprogram_Profile_Overload_Ambiguous_Formals => 0,
              Subprogram_Profile_Overload_Unresolved_Formals => 0,
              Formal_Package_Compatible_Formals => 0,
              Formal_Package_Mismatched_Formals => 0,
              Formal_Package_Unknown_Formals => 0,
              Formal_Package_Unresolved_Formals => 0,
              Formal_Package_Ambiguous_Formals => 0,
              Formal_Package_Not_Instance_Formals => 0,
              Formal_Package_Wrong_Generic_Formals => 0,
              Formal_Package_Contract_Unknown_Formals => 0,
              Formal_Package_Malformed_Formals => 0,
              Default_Expression_Checked_Formals => 0,
              Default_Expression_Static_Formals => 0,
              Default_Expression_Illegal_Formals => 0,
              Default_Expression_Unknown_Formals => 0,
              Default_Expression_Unresolved_Formals => 0,
              Default_Expression_Nonstatic_Formals => 0,
              Default_Expression_Malformed_Formals => 0,
              Default_Expression_Division_By_Zero_Formals => 0,
              Status => Generic_Actual_Match_Generic_Not_Found,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Actual_Match;

   function Empty_Body_Contract_Visibility
     return Generic_Body_Contract_Visibility_Info is
   begin
      return (Id => No_Generic_Body_Contract_Visibility,
              Generic_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Generic_Node => Editor.Ada_Syntax_Tree.No_Node,
              Generic_Formal_Region => Editor.Ada_Declarative_Regions.No_Region,
              Body_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Body_Node => Editor.Ada_Syntax_Tree.No_Node,
              Body_Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Formal_Count => 0,
              Visible_Formals => 0,
              Shadowed_Formals => 0,
              Shadowed_Formal_Names => Null_Unbounded_String,
              Status => Generic_Body_Contract_Unsupported,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Body_Contract_Visibility;

   function To_Formal_Kind
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind) return Generic_Formal_Kind is
   begin
      case Kind is
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Type =>
            return Generic_Formal_Type;
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Object =>
            return Generic_Formal_Object;
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram =>
            return Generic_Formal_Subprogram;
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Package =>
            return Generic_Formal_Package;
         when others =>
            return Generic_Formal_Unknown;
      end case;
   end To_Formal_Kind;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index));
         begin
            if Child.Kind = Kind then
               return To_String (Child.Label);
            end if;
         end;
      end loop;
      return "";
   end Child_Label;


   function Explicit_Convention_For_Declaration
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
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
      return Find_In_Subtree (Node);
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


   function Delimited_Text_At
     (List  : String;
      Index : Positive) return String
   is
      First : Natural := List'First;
      Pos   : Positive := 1;
   begin
      if List = "" then
         return "";
      end if;
      while First <= List'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index (List (First .. List'Last), "|");
            Last : Natural := List'Last;
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;
            if Pos = Index then
               return Trim (List (First .. Last));
            end if;
            exit when Sep = 0;
            First := Sep + 1;
            Pos := Pos + 1;
         end;
      end loop;
      return "";
   end Delimited_Text_At;

   function Named_Text_For
     (List : String;
      Name : String) return String
   is
      N     : constant String := Normalize (Name);
      First : Natural := List'First;
   begin
      if List = "" or else N = "" then
         return "";
      end if;
      while First <= List'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index (List (First .. List'Last), "|");
            Last : Natural := List'Last;
            Eq   : Natural;
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;
            Eq := Ada.Strings.Fixed.Index (List (First .. Last), "=");
            if Eq /= 0 and then Normalize (List (First .. Eq - 1)) = N then
               return Trim (List (Eq + 1 .. Last));
            end if;
            exit when Sep = 0;
            First := Sep + 1;
         end;
      end loop;
      return "";
   end Named_Text_For;

   function Strip_Default_And_Mode (Text : String) return String is
      T : constant String := Trim (Text);
      Cut : Natural := Ada.Strings.Fixed.Index (T, ":=");
      Lower : constant String := Ada.Characters.Handling.To_Lower (T);
      First : Natural := T'First;
   begin
      if T = "" then
         return "";
      end if;
      if Cut = 0 then
         Cut := T'Last + 1;
      end if;
      if Ada.Strings.Fixed.Index (Lower, "in out ") = Lower'First then
         First := T'First + 7;
      elsif Ada.Strings.Fixed.Index (Lower, "out ") = Lower'First then
         First := T'First + 4;
      elsif Ada.Strings.Fixed.Index (Lower, "in ") = Lower'First then
         First := T'First + 3;
      end if;
      if First > Cut - 1 then
         return "";
      end if;
      return Normalize (T (First .. Cut - 1));
   end Strip_Default_And_Mode;

   function Append_Repeated_Subtype
     (List  : Unbounded_String;
      Count : Natural;
      Text  : String) return Unbounded_String
   is
      Result : Unbounded_String := List;
      Subtype_Text : constant String := Strip_Default_And_Mode (Text);
   begin
      for I in 1 .. Count loop
         if Length (Result) = 0 then
            Result := To_Unbounded_String (Subtype_Text);
         else
            Result := Result & "|" & Subtype_Text;
         end if;
      end loop;
      return Result;
   end Append_Repeated_Subtype;


   function Mode_From_Parameter_Tail (Text : String) return String is
      T : constant String := Trim (Text);
      Lower : constant String := Ada.Characters.Handling.To_Lower (T);
   begin
      if Ada.Strings.Fixed.Index (Lower, "in out ") = Lower'First then
         return "in out";
      elsif Ada.Strings.Fixed.Index (Lower, "out ") = Lower'First then
         return "out";
      elsif Ada.Strings.Fixed.Index (Lower, "in ") = Lower'First then
         return "in";
      else
         return "in";
      end if;
   end Mode_From_Parameter_Tail;

   function Append_Repeated_Mode
     (List  : Unbounded_String;
      Count : Natural;
      Text  : String) return Unbounded_String
   is
      Result : Unbounded_String := List;
      Mode_Text : constant String := Mode_From_Parameter_Tail (Text);
   begin
      for I in 1 .. Count loop
         if Length (Result) = 0 then
            Result := To_Unbounded_String (Mode_Text);
         else
            Result := Result & "|" & Mode_Text;
         end if;
      end loop;
      return Result;
   end Append_Repeated_Mode;

   function Default_From_Parameter_Tail (Text : String) return String is
   begin
      if Ada.Strings.Fixed.Index (Text, ":=") /= 0 then
         return "default";
      else
         return "required";
      end if;
   end Default_From_Parameter_Tail;

   function Append_Repeated_Default
     (List  : Unbounded_String;
      Count : Natural;
      Text  : String) return Unbounded_String
   is
      Result : Unbounded_String := List;
      Default_Text : constant String := Default_From_Parameter_Tail (Text);
   begin
      for I in 1 .. Count loop
         if Length (Result) = 0 then
            Result := To_Unbounded_String (Default_Text);
         else
            Result := Result & "|" & Default_Text;
         end if;
      end loop;
      return Result;
   end Append_Repeated_Default;



   function Append_Parameter_Names
     (List  : Unbounded_String;
      Names : String) return Unbounded_String
   is
      Result : Unbounded_String := List;
      First  : Natural := Names'First;

      procedure Append_One (Text : String) is
         Name_Text : constant String := Normalize (Text);
      begin
         if Name_Text = "" then
            return;
         elsif Length (Result) = 0 then
            Result := To_Unbounded_String (Name_Text);
         else
            Result := Result & "|" & Name_Text;
         end if;
      end Append_One;
   begin
      if Names = "" then
         return Result;
      end if;

      for I in Names'Range loop
         if Names (I) = ',' then
            if I > First then
               Append_One (Names (First .. I - 1));
            end if;
            First := I + 1;
         end if;
      end loop;
      if First <= Names'Last then
         Append_One (Names (First .. Names'Last));
      end if;
      return Result;
   end Append_Parameter_Names;


   function Parameter_Defaults_Conform
     (Formal_Defaults : String;
      Actual_Defaults : String) return Boolean
   is
      First : Natural := Formal_Defaults'First;
      Index : Positive := 1;
   begin
      if Formal_Defaults = "" then
         return True;
      end if;
      while First <= Formal_Defaults'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index
              (Formal_Defaults (First .. Formal_Defaults'Last), "|");
            Last : Natural := Formal_Defaults'Last;
            Actual_Default : constant String := Delimited_Text_At (Actual_Defaults, Index);
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;
            if Trim (Formal_Defaults (First .. Last)) = "default"
              and then Actual_Default /= "default"
            then
               return False;
            end if;
            exit when Sep = 0;
            First := Sep + 1;
            Index := Index + 1;
         end;
      end loop;
      return True;
   end Parameter_Defaults_Conform;


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
   is
      Profile : constant String :=
        Child_Label (Tree, Node, Editor.Ada_Syntax_Tree.Node_Declaration_Profile);
      Result_Text : constant String :=
        Trim (Child_Label (Tree, Node, Editor.Ada_Syntax_Tree.Node_Declaration_Result));
      Segment_First : Natural := Profile'First;

      procedure Add_Segment (First : Natural; Last : Natural) is
         Segment : constant String := Trim (Profile (First .. Last));
         Colon   : constant Natural := Ada.Strings.Fixed.Index (Segment, ":");
         Names_Last : Natural := 0;
         Name_First : Natural := 0;
         Segment_Count : Natural := 0;
      begin
         if Segment = "" then
            return;
         end if;
         if Colon = 0 then
            Malformed := True;
            Parameters := Parameters + 1;
            return;
         end if;
         Names_Last := Colon - 1;
         Name_First := Segment'First;
         for I in Segment'First .. Names_Last loop
            if Segment (I) = ',' then
               if I > Name_First then
                  Parameters := Parameters + 1;
                  Segment_Count := Segment_Count + 1;
               else
                  Malformed := True;
               end if;
               Name_First := I + 1;
            end if;
         end loop;
         if Name_First <= Names_Last then
            Parameters := Parameters + 1;
            Segment_Count := Segment_Count + 1;
         end if;
         Subtypes := Append_Repeated_Subtype
           (Subtypes, Segment_Count, Segment (Colon + 1 .. Segment'Last));
         Modes := Append_Repeated_Mode
           (Modes, Segment_Count, Segment (Colon + 1 .. Segment'Last));
         Names := Append_Parameter_Names
           (Names, Segment (Segment'First .. Names_Last));
         Defaults := Append_Repeated_Default
           (Defaults, Segment_Count, Segment (Colon + 1 .. Segment'Last));
      end Add_Segment;
   begin
      Parameters := 0;
      Has_Result := Result_Text /= "";
      Subtypes := Null_Unbounded_String;
      Modes := Null_Unbounded_String;
      Names := Null_Unbounded_String;
      Defaults := Null_Unbounded_String;
      Result := To_Unbounded_String (Normalize (Result_Text));
      Malformed := False;

      if Profile /= "" then
         for I in Profile'Range loop
            if Profile (I) = ';' then
               if I > Segment_First then
                  Add_Segment (Segment_First, I - 1);
               else
                  Malformed := True;
               end if;
               Segment_First := I + 1;
            end if;
         end loop;
         if Segment_First <= Profile'Last then
            Add_Segment (Segment_First, Profile'Last);
         end if;
      end if;
   end Analyze_Subprogram_Profile;


   function Substitute_Generic_Formal_Subtypes
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Info;
      Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Subtypes : String) return String
   is
      First : Natural := Subtypes'First;
      Result : Unbounded_String;

      function Type_Actual_For (Formal_Name : String) return String is
         Position : Natural := 0;
         N : constant String := Normalize (Formal_Name);
      begin
         for F of Model.Formals loop
            if F.Region = Region then
               Position := Position + 1;
               if To_String (F.Normalized_Name) = N and then F.Kind = Generic_Formal_Type then
                  if Position <= Instance.Positional_Actuals then
                     return Normalize
                       (Delimited_Text_At
                          (To_String (Instance.Positional_Actual_Texts),
                           Positive (Position)));
                  elsif List_Contains_Name
                    (To_String (Instance.Named_Actual_Names), N)
                  then
                     return Normalize
                       (Named_Text_For (To_String (Instance.Named_Actual_Texts), N));
                  end if;
               end if;
            end if;
         end loop;
         return N;
      end Type_Actual_For;
   begin
      if Subtypes = "" then
         return "";
      end if;
      while First <= Subtypes'Last loop
         declare
            Sep  : Natural := Ada.Strings.Fixed.Index (Subtypes (First .. Subtypes'Last), "|");
            Last : Natural := Subtypes'Last;
            Replacement : Unbounded_String;
         begin
            if Sep /= 0 then
               Last := Sep - 1;
            end if;
            Replacement := To_Unbounded_String (Type_Actual_For (Subtypes (First .. Last)));
            if Length (Result) = 0 then
               Result := Replacement;
            else
               Result := Result & "|" & Replacement;
            end if;
            exit when Sep = 0;
            First := Sep + 1;
         end;
      end loop;
      return To_String (Result);
   end Substitute_Generic_Formal_Subtypes;

   function Subprogram_Profile_Compatible
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Formal     : Generic_Formal_Info;
      Actual_Text : String) return Generic_Formal_Actual_Kind_Match
   is
      Designator : constant String := Normalize (Actual_Text);
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Actual_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : Unbounded_String;
   begin
      if Formal.Kind /= Generic_Formal_Subprogram then
         return Generic_Formal_Actual_Kind_Unknown;
      elsif Designator = "" or else Ada.Strings.Fixed.Index (Designator, "'") /= 0 then
         return Generic_Formal_Actual_Kind_Unknown;
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, From_Region, Designator);
      if Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
         return Generic_Formal_Actual_Kind_Unknown;
      end if;

      Actual_Decl := Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
      if Declaration_To_Actual_Kind (Actual_Decl.Kind) /= Generic_Actual_Subprogram then
         return Generic_Formal_Actual_Kind_Mismatch;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Actual_Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      Expected_Subtypes := To_Unbounded_String
        (Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region,
            To_String (Formal.Formal_Parameter_Subtypes)));
      if Malformed then
         return Generic_Formal_Actual_Kind_Unknown;
      elsif Actual_Parameters = Formal.Formal_Parameter_Count
        and then To_String (Actual_Subtypes) = To_String (Expected_Subtypes)
        and then To_String (Actual_Modes) = To_String (Formal.Formal_Parameter_Modes)
        and then To_String (Actual_Names) = To_String (Formal.Formal_Parameter_Names)
        and then Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        and then Actual_Has_Result = Formal.Formal_Has_Result
        and then (not Formal.Formal_Has_Result
                  or else To_String (Actual_Result) = To_String (Formal.Formal_Result_Subtype))
      then
         return Generic_Formal_Actual_Kind_Matches;
      else
         return Generic_Formal_Actual_Kind_Mismatch;
      end if;
   end Subprogram_Profile_Compatible;


   type Subprogram_Profile_Selection_Status is
     (Subprogram_Profile_Selected,
      Subprogram_Profile_No_Candidates,
      Subprogram_Profile_No_Profile_Match,
      Subprogram_Profile_Mode_Mismatch,
      Subprogram_Profile_Null_Exclusion_Mismatch,
      Subprogram_Profile_Access_Profile_Mismatch,
      Subprogram_Profile_Convention_Mismatch,
      Subprogram_Profile_Default_Mismatch,
      Subprogram_Profile_Class_Wide_Mismatch,
      Subprogram_Profile_Name_Mismatch,
      Subprogram_Profile_Result_Mismatch,
      Subprogram_Profile_Ambiguous_Profile_Match,
      Subprogram_Profile_Unknown);

   type Subprogram_Profile_Selection_Info is record
      Status           : Subprogram_Profile_Selection_Status :=
        Subprogram_Profile_Unknown;
      Candidate_Count  : Natural := 0;
      Compatible_Count : Natural := 0;
      Mode_Mismatch_Count : Natural := 0;
      Null_Exclusion_Mismatch_Count : Natural := 0;
      Access_Profile_Mismatch_Count : Natural := 0;
      Convention_Mismatch_Count : Natural := 0;
      Default_Mismatch_Count : Natural := 0;
      Class_Wide_Mismatch_Count : Natural := 0;
      Name_Mismatch_Count : Natural := 0;
      Result_Compatible_Count : Natural := 0;
      Result_Mismatch_Count : Natural := 0;
      Result_Unknown_Count : Natural := 0;
      Type_Compatible_Count : Natural := 0;
      Type_Mismatch_Count : Natural := 0;
      Type_Unknown_Count : Natural := 0;
      Selected         : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
   end record;


   type Profile_Type_Conformance_Status is
     (Profile_Type_Conformance_Not_Checked,
      Profile_Type_Conformance_Compatible,
      Profile_Type_Conformance_Mismatch,
      Profile_Type_Conformance_Unknown);

   function Type_Id_For_Profile_Subtype
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Type_Graph.Type_Id
   is
      Wanted : constant String := Normalize (Name);
      Found  : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
   begin
      if Wanted = "" then
         return Editor.Ada_Type_Graph.No_Type;
      end if;

      Found := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Wanted);
      if Found /= Editor.Ada_Type_Graph.No_Type then
         return Found;
      end if;

      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if To_String (Info.Normalized_Name) = Wanted then
               if Found /= Editor.Ada_Type_Graph.No_Type then
                  return Editor.Ada_Type_Graph.No_Type;
               end if;
               Found := Info.Id;
            end if;
         end;
      end loop;

      return Found;
   end Type_Id_For_Profile_Subtype;

   function Type_Graph_Profile_Subtypes_Conform
     (Types           : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtypes : String;
      Actual_Subtypes   : String) return Profile_Type_Conformance_Status
   is
      Expected_First : Natural := Expected_Subtypes'First;
      Actual_First   : Natural := Actual_Subtypes'First;
      Saw_Type_Graph_Relation : Boolean := False;

      function Next_Field
        (Text  : String;
         First : in out Natural;
         Field : out Unbounded_String) return Boolean
      is
         Sep  : Natural;
         Last : Natural;
      begin
         Field := Null_Unbounded_String;
         if Text = "" or else First > Text'Last then
            return False;
         end if;
         Sep := Ada.Strings.Fixed.Index (Text (First .. Text'Last), "|");
         Last := Text'Last;
         if Sep /= 0 then
            Last := Sep - 1;
         end if;
         Field := To_Unbounded_String (Normalize (Text (First .. Last)));
         if Sep = 0 then
            First := Text'Last + 1;
         else
            First := Sep + 1;
         end if;
         return True;
      end Next_Field;
   begin
      if Expected_Subtypes = Actual_Subtypes then
         return Profile_Type_Conformance_Compatible;
      end if;

      loop
         declare
            Expected_Field : Unbounded_String;
            Actual_Field   : Unbounded_String;
            Has_Expected   : constant Boolean :=
              Next_Field (Expected_Subtypes, Expected_First, Expected_Field);
            Has_Actual     : constant Boolean :=
              Next_Field (Actual_Subtypes, Actual_First, Actual_Field);
         begin
            if Has_Expected /= Has_Actual then
               return Profile_Type_Conformance_Mismatch;
            elsif not Has_Expected then
               exit;
            elsif To_String (Expected_Field) = To_String (Actual_Field) then
               null;
            else
               declare
                  Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                    Type_Id_For_Profile_Subtype
                      (Types, Formal_Region, To_String (Expected_Field));
                  Actual_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                    Type_Id_For_Profile_Subtype
                      (Types, Actual_Region, To_String (Actual_Field));
               begin
                  if Expected_Type = Editor.Ada_Type_Graph.No_Type
                    or else Actual_Type = Editor.Ada_Type_Graph.No_Type
                  then
                     return Profile_Type_Conformance_Unknown;
                  end if;

                  case Editor.Ada_Type_Graph.Compatibility
                    (Types, Expected_Type, Actual_Type)
                  is
                     when Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type
                        | Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
                        Saw_Type_Graph_Relation := True;
                     when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
                        return Profile_Type_Conformance_Mismatch;
                     when others =>
                        return Profile_Type_Conformance_Unknown;
                  end case;
               end;
            end if;
         end;
      end loop;

      if Saw_Type_Graph_Relation then
         return Profile_Type_Conformance_Compatible;
      else
         return Profile_Type_Conformance_Unknown;
      end if;
   end Type_Graph_Profile_Subtypes_Conform;


   function Type_Graph_Result_Subtype_Conforms
     (Types         : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtype : String;
      Actual_Subtype   : String) return Profile_Type_Conformance_Status
   is
      Expected : constant String := Normalize (Expected_Subtype);
      Actual   : constant String := Normalize (Actual_Subtype);
      Expected_Type : Editor.Ada_Type_Graph.Type_Id;
      Actual_Type   : Editor.Ada_Type_Graph.Type_Id;

      function Has_Class (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
      begin
         return Ada.Strings.Fixed.Index (Lower, "'class") /= 0;
      end Has_Class;

      function Strip_Class (Text : String) return String is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
         Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, "'class");
      begin
         if Pos = 0 then
            return Lower;
         else
            return Trim (Lower (Lower'First .. Pos - 1));
         end if;
      end Strip_Class;
   begin
      if Expected = Actual then
         return Profile_Type_Conformance_Compatible;
      elsif Expected = "" or else Actual = "" then
         return Profile_Type_Conformance_Unknown;
      end if;

      if Has_Class (Actual) and then not Has_Class (Expected) then
         return Profile_Type_Conformance_Mismatch;
      end if;

      Expected_Type := Type_Id_For_Profile_Subtype (Types, Formal_Region, Strip_Class (Expected));
      Actual_Type := Type_Id_For_Profile_Subtype (Types, Actual_Region, Strip_Class (Actual));
      if Expected_Type = Editor.Ada_Type_Graph.No_Type
        or else Actual_Type = Editor.Ada_Type_Graph.No_Type
      then
         return Profile_Type_Conformance_Unknown;
      end if;

      if Has_Class (Expected) then
         case Editor.Ada_Type_Graph.Class_Wide_Compatibility
           (Types, Expected_Type, Actual_Type)
         is
            when Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide
               | Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type
               | Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
               return Profile_Type_Conformance_Compatible;
            when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
               return Profile_Type_Conformance_Mismatch;
            when others =>
               return Profile_Type_Conformance_Unknown;
         end case;
      end if;

      case Editor.Ada_Type_Graph.Compatibility (Types, Expected_Type, Actual_Type) is
         when Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type
            | Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
            return Profile_Type_Conformance_Compatible;
         when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
            return Profile_Type_Conformance_Mismatch;
         when others =>
            return Profile_Type_Conformance_Unknown;
      end case;
   end Type_Graph_Result_Subtype_Conforms;

   function Profile_Matches_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info;
      Type_Status : out Profile_Type_Conformance_Status;
      Result_Status : out Profile_Type_Conformance_Status) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : Unbounded_String;
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      Type_Status := Profile_Type_Conformance_Not_Checked;
      Result_Status := Profile_Type_Conformance_Not_Checked;
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed then
         return False;
      end if;

      Expected_Subtypes := To_Unbounded_String
        (Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region,
            To_String (Formal.Formal_Parameter_Subtypes)));

      if Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else To_String (Actual_Names) /= To_String (Formal.Formal_Parameter_Names)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
      then
         return False;
      end if;

      if To_String (Actual_Subtypes) = To_String (Expected_Subtypes) then
         Type_Status := Profile_Type_Conformance_Compatible;
      elsif Check_Type_Graph then
         Type_Status := Type_Graph_Profile_Subtypes_Conform
           (Types, Formal.Region, Decl.Region,
            To_String (Expected_Subtypes), To_String (Actual_Subtypes));
      else
         return False;
      end if;

      if Type_Status /= Profile_Type_Conformance_Compatible then
         return False;
      end if;

      if not Formal.Formal_Has_Result then
         Result_Status := Profile_Type_Conformance_Not_Checked;
         return True;
      end if;

      declare
         Expected_Result : constant String := Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region, To_String (Formal.Formal_Result_Subtype));
         Actual_Result_Text : constant String := To_String (Actual_Result);
      begin
         if Normalize (Actual_Result_Text) = Normalize (Expected_Result) then
            Result_Status := Profile_Type_Conformance_Compatible;
            return True;
         elsif Check_Type_Graph then
            Result_Status := Type_Graph_Result_Subtype_Conforms
              (Types, Formal.Region, Decl.Region, Expected_Result, Actual_Result_Text);
            return Result_Status = Profile_Type_Conformance_Compatible;
         else
            Result_Status := Profile_Type_Conformance_Mismatch;
            return False;
         end if;
      end;
   end Profile_Matches_Formal;


   function Profile_Mode_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : Unbounded_String;
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed then
         return False;
      end if;

      Expected_Subtypes := To_Unbounded_String
        (Substitute_Generic_Formal_Subtypes
           (Model, Instance, Formal.Region,
            To_String (Formal.Formal_Parameter_Subtypes)));

      return Actual_Parameters = Formal.Formal_Parameter_Count
        and then To_String (Actual_Subtypes) = To_String (Expected_Subtypes)
        and then To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        and then Actual_Has_Result = Formal.Formal_Has_Result
        and then (not Formal.Formal_Has_Result
                  or else To_String (Actual_Result) = To_String (Formal.Formal_Result_Subtype));
   end Profile_Mode_Mismatch_Formal;



   function Profile_Field_At (List : String; Index : Positive) return String is
   begin
      return Normalize (Delimited_Text_At (List, Index));
   end Profile_Field_At;

   function Has_Null_Exclusion (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
   begin
      return Ada.Strings.Fixed.Index (Lower, "not null") /= 0;
   end Has_Null_Exclusion;

   function Without_Null_Exclusion (Text : String) return String is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, "not null");
   begin
      if Pos = 0 then
         return Lower;
      elsif Pos = Lower'First then
         return Trim (Lower (Pos + 8 .. Lower'Last));
      elsif Pos + 7 >= Lower'Last then
         return Trim (Lower (Lower'First .. Pos - 1));
      else
         return Trim (Lower (Lower'First .. Pos - 1) & " " & Lower (Pos + 8 .. Lower'Last));
      end if;
   end Without_Null_Exclusion;

   function Is_Access_Subprogram_Profile (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
   begin
      return Ada.Strings.Fixed.Index (Lower, "access procedure") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "access function") /= 0;
   end Is_Access_Subprogram_Profile;



   function Has_Class_Wide_Marker (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
   begin
      return Ada.Strings.Fixed.Index (Lower, "'class") /= 0;
   end Has_Class_Wide_Marker;

   function Without_Class_Wide_Marker (Text : String) return String is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
      Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, "'class");
   begin
      if Pos = 0 then
         return Lower;
      elsif Pos = Lower'First then
         return Trim (Lower (Pos + 6 .. Lower'Last));
      elsif Pos + 5 >= Lower'Last then
         return Trim (Lower (Lower'First .. Pos - 1));
      else
         return Trim (Lower (Lower'First .. Pos - 1) & " " & Lower (Pos + 6 .. Lower'Last));
      end if;
   end Without_Class_Wide_Marker;

   function Profile_Class_Wide_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
      then
         return False;
      end if;

      for I in 1 .. Formal.Formal_Parameter_Count loop
         declare
            Expected : constant String := Profile_Field_At (Expected_Subtypes, Positive (I));
            Actual   : constant String := Profile_Field_At (To_String (Actual_Subtypes), Positive (I));
         begin
            if Has_Class_Wide_Marker (Expected) /= Has_Class_Wide_Marker (Actual)
              and then Without_Class_Wide_Marker (Expected) = Without_Class_Wide_Marker (Actual)
            then
               return True;
            end if;
         end;
      end loop;

      if Formal.Formal_Has_Result
        and then Has_Class_Wide_Marker (To_String (Formal.Formal_Result_Subtype)) /=
                 Has_Class_Wide_Marker (To_String (Actual_Result))
        and then Without_Class_Wide_Marker (To_String (Formal.Formal_Result_Subtype)) =
                 Without_Class_Wide_Marker (To_String (Actual_Result))
      then
         return True;
      end if;

      return False;
   end Profile_Class_Wide_Mismatch_Formal;

   function Profile_Null_Exclusion_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
      then
         return False;
      end if;

      for I in 1 .. Formal.Formal_Parameter_Count loop
         declare
            Expected : constant String := Profile_Field_At (Expected_Subtypes, Positive (I));
            Actual   : constant String := Profile_Field_At (To_String (Actual_Subtypes), Positive (I));
         begin
            if Has_Null_Exclusion (Expected) /= Has_Null_Exclusion (Actual)
              and then Without_Null_Exclusion (Expected) = Without_Null_Exclusion (Actual)
            then
               return True;
            end if;
         end;
      end loop;

      if Formal.Formal_Has_Result
        and then Has_Null_Exclusion (To_String (Formal.Formal_Result_Subtype)) /=
                 Has_Null_Exclusion (To_String (Actual_Result))
        and then Without_Null_Exclusion (To_String (Formal.Formal_Result_Subtype)) =
                 Without_Null_Exclusion (To_String (Actual_Result))
      then
         return True;
      end if;

      return False;
   end Profile_Null_Exclusion_Mismatch_Formal;

   function Profile_Access_Profile_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
      then
         return False;
      end if;

      for I in 1 .. Formal.Formal_Parameter_Count loop
         declare
            Expected : constant String := Profile_Field_At (Expected_Subtypes, Positive (I));
            Actual   : constant String := Profile_Field_At (To_String (Actual_Subtypes), Positive (I));
         begin
            if Is_Access_Subprogram_Profile (Expected)
              and then Is_Access_Subprogram_Profile (Actual)
              and then Without_Null_Exclusion (Expected) /= Without_Null_Exclusion (Actual)
            then
               return True;
            end if;
         end;
      end loop;

      if Formal.Formal_Has_Result
        and then Is_Access_Subprogram_Profile (To_String (Formal.Formal_Result_Subtype))
        and then Is_Access_Subprogram_Profile (To_String (Actual_Result))
        and then Without_Null_Exclusion (To_String (Formal.Formal_Result_Subtype)) /=
                 Without_Null_Exclusion (To_String (Actual_Result))
      then
         return True;
      end if;

      return False;
   end Profile_Access_Profile_Mismatch_Formal;


   function Profile_Default_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Subtypes) /= Expected_Subtypes
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
        or else (Formal.Formal_Has_Result
                 and then To_String (Actual_Result) /= To_String (Formal.Formal_Result_Subtype))
      then
         return False;
      end if;

      return not Parameter_Defaults_Conform
        (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults));
   end Profile_Default_Mismatch_Formal;


   function Profile_Name_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Subtypes) /= Expected_Subtypes
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else Formal_Convention /= Actual_Convention
        or else (Formal.Formal_Has_Result
                 and then To_String (Actual_Result) /= To_String (Formal.Formal_Result_Subtype))
      then
         return False;
      end if;

      return To_String (Actual_Names) /= To_String (Formal.Formal_Parameter_Names);
   end Profile_Name_Mismatch_Formal;


   function Profile_Convention_Mismatch_Formal
     (Model      : Generic_Contract_Model;
      Instance   : Generic_Instance_Info;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal     : Generic_Formal_Info;
      Decl       : Editor.Ada_Direct_Visibility.Declaration_Info) return Boolean
   is
      Actual_Parameters : Natural := 0;
      Actual_Subtypes   : Unbounded_String;
      Actual_Modes      : Unbounded_String;
      Actual_Names      : Unbounded_String;
      Actual_Defaults   : Unbounded_String;
      Actual_Has_Result : Boolean := False;
      Actual_Result     : Unbounded_String;
      Malformed         : Boolean := False;
      Expected_Subtypes : constant String :=
        Substitute_Generic_Formal_Subtypes
          (Model, Instance, Formal.Region,
           To_String (Formal.Formal_Parameter_Subtypes));
      Formal_Convention : constant String := To_String (Formal.Formal_Subprogram_Convention);
      Actual_Convention : constant String := Convention_For_Declaration (Tree, Decl.Node);
   begin
      if Declaration_To_Actual_Kind (Decl.Kind) /= Generic_Actual_Subprogram then
         return False;
      end if;

      Analyze_Subprogram_Profile
        (Tree, Decl.Node, Actual_Parameters, Actual_Subtypes,
         Actual_Modes, Actual_Names, Actual_Defaults, Actual_Has_Result, Actual_Result, Malformed);
      if Malformed
        or else Actual_Parameters /= Formal.Formal_Parameter_Count
        or else To_String (Actual_Subtypes) /= Expected_Subtypes
        or else To_String (Actual_Modes) /= To_String (Formal.Formal_Parameter_Modes)
        or else not Parameter_Defaults_Conform
          (To_String (Formal.Formal_Parameter_Defaults), To_String (Actual_Defaults))
        or else Actual_Has_Result /= Formal.Formal_Has_Result
        or else (Formal.Formal_Has_Result
                 and then To_String (Actual_Result) /= To_String (Formal.Formal_Result_Subtype))
      then
         return False;
      end if;

      return Formal_Convention /= Actual_Convention;
   end Profile_Convention_Mismatch_Formal;

   function Select_Subprogram_Actual_By_Profile
     (Model       : Generic_Contract_Model;
      Instance    : Generic_Instance_Info;
      Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      Types       : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Formal      : Generic_Formal_Info;
      Actual_Text : String) return Subprogram_Profile_Selection_Info
   is
      Designator : constant String := Normalize (Actual_Text);
      Current    : Editor.Ada_Declarative_Regions.Region_Id := From_Region;
      Info       : Subprogram_Profile_Selection_Info;
   begin
      if Formal.Kind /= Generic_Formal_Subprogram
        or else Designator = ""
        or else Ada.Strings.Fixed.Index (Designator, "'") /= 0
      then
         Info.Status := Subprogram_Profile_Unknown;
         return Info;
      end if;

      while Current /= Editor.Ada_Declarative_Regions.No_Region loop
         declare
            Direct_Matches : Natural := 0;
         begin
            for I in 1 .. Editor.Ada_Direct_Visibility.Direct_Declaration_Count
              (Visibility, Current)
            loop
               declare
                  Decl_Id : constant Editor.Ada_Direct_Visibility.Declaration_Id :=
                    Editor.Ada_Direct_Visibility.Direct_Declaration_At
                      (Visibility, Current, I);
                  Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl_Id);
               begin
                  if To_String (Decl.Normalized) = Designator then
                     Direct_Matches := Direct_Matches + 1;
                     if Declaration_To_Actual_Kind (Decl.Kind) = Generic_Actual_Subprogram then
                        Info.Candidate_Count := Info.Candidate_Count + 1;
                        declare
                           Type_Status : Profile_Type_Conformance_Status;
                           Result_Status : Profile_Type_Conformance_Status;
                        begin
                           if Profile_Matches_Formal
                             (Model, Instance, Tree, Types, Check_Type_Graph,
                              Formal, Decl, Type_Status, Result_Status)
                           then
                              Info.Compatible_Count := Info.Compatible_Count + 1;
                              if Type_Status = Profile_Type_Conformance_Compatible then
                                 Info.Type_Compatible_Count := Info.Type_Compatible_Count + 1;
                              end if;
                              if Result_Status = Profile_Type_Conformance_Compatible then
                                 Info.Result_Compatible_Count := Info.Result_Compatible_Count + 1;
                              end if;
                              if Info.Selected = Editor.Ada_Direct_Visibility.No_Declaration then
                                 Info.Selected := Decl.Id;
                              end if;
                           elsif Type_Status = Profile_Type_Conformance_Mismatch then
                              Info.Type_Mismatch_Count := Info.Type_Mismatch_Count + 1;
                           elsif Type_Status = Profile_Type_Conformance_Unknown then
                              Info.Type_Unknown_Count := Info.Type_Unknown_Count + 1;
                           end if;
                           if Result_Status = Profile_Type_Conformance_Mismatch then
                              Info.Result_Mismatch_Count := Info.Result_Mismatch_Count + 1;
                           elsif Result_Status = Profile_Type_Conformance_Unknown then
                              Info.Result_Unknown_Count := Info.Result_Unknown_Count + 1;
                           end if;
                        end;
                        if Info.Compatible_Count = 0 and then Profile_Mode_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Mode_Mismatch_Count := Info.Mode_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Null_Exclusion_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Null_Exclusion_Mismatch_Count :=
                             Info.Null_Exclusion_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Access_Profile_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Access_Profile_Mismatch_Count :=
                             Info.Access_Profile_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Convention_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Convention_Mismatch_Count :=
                             Info.Convention_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Default_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Default_Mismatch_Count :=
                             Info.Default_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0 and then Profile_Class_Wide_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Class_Wide_Mismatch_Count :=
                             Info.Class_Wide_Mismatch_Count + 1;
                        end if;
                        if Info.Compatible_Count = 0
                          and then Info.Result_Mismatch_Count = 0
                          and then Profile_Name_Mismatch_Formal
                          (Model, Instance, Tree, Formal, Decl)
                        then
                           Info.Name_Mismatch_Count :=
                             Info.Name_Mismatch_Count + 1;
                        end if;
                     end if;
                  end if;
               end;
            end loop;

            if Direct_Matches /= 0 then
               if Info.Candidate_Count = 0 then
                  Info.Status := Subprogram_Profile_No_Candidates;
               elsif Info.Compatible_Count = 0 and then Info.Mode_Mismatch_Count /= 0 then
                  Info.Status := Subprogram_Profile_Mode_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Null_Exclusion_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Null_Exclusion_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Access_Profile_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Access_Profile_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Convention_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Convention_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Default_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Default_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Class_Wide_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Class_Wide_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Name_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Name_Mismatch;
               elsif Info.Compatible_Count = 0
                 and then Info.Result_Mismatch_Count /= 0
               then
                  Info.Status := Subprogram_Profile_Result_Mismatch;
               elsif Info.Compatible_Count = 0 then
                  Info.Status := Subprogram_Profile_No_Profile_Match;
               elsif Info.Compatible_Count = 1 then
                  Info.Status := Subprogram_Profile_Selected;
               else
                  Info.Status := Subprogram_Profile_Ambiguous_Profile_Match;
                  Info.Selected := Editor.Ada_Direct_Visibility.No_Declaration;
               end if;
               return Info;
            end if;

            Current := Editor.Ada_Declarative_Regions.Region (Regions, Current).Parent;
         end;
      end loop;

      Info.Status := Subprogram_Profile_No_Candidates;
      return Info;
   end Select_Subprogram_Actual_By_Profile;


   type Formal_Package_Contract_Status is
     (Formal_Package_Contract_Compatible,
      Formal_Package_Contract_Actual_Unresolved,
      Formal_Package_Contract_Actual_Ambiguous,
      Formal_Package_Contract_Actual_Not_Instance,
      Formal_Package_Contract_Wrong_Generic,
      Formal_Package_Contract_Unknown,
      Formal_Package_Contract_Malformed);

   function Check_Formal_Package_Contract
     (Tree        : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility  : Editor.Ada_Direct_Visibility.Visibility_Model;
      Regions     : Editor.Ada_Declarative_Regions.Region_Model;
      From_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Formal      : Generic_Formal_Info;
      Actual_Text : String) return Formal_Package_Contract_Status
   is
      Expected : constant String :=
        To_String (Formal.Formal_Package_Normalized_Generic);
      Actual   : constant String := Trim (Actual_Text);
      Inline_Generic : constant String := Normalize (Inline_Instance_Generic_Name (Actual));
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
      Actual_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Actual_Label : Unbounded_String;
      Actual_Generic : Unbounded_String;
   begin
      if Formal.Kind /= Generic_Formal_Package then
         return Formal_Package_Contract_Unknown;
      elsif Expected = "" then
         return Formal_Package_Contract_Unknown;
      elsif Actual = "" then
         return Formal_Package_Contract_Malformed;
      end if;

      if Inline_Generic /= "" then
         return (if Inline_Generic = Expected then Formal_Package_Contract_Compatible
                 else Formal_Package_Contract_Wrong_Generic);
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, From_Region, Normalize (Actual));
      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         return Formal_Package_Contract_Actual_Unresolved;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
         return Formal_Package_Contract_Actual_Ambiguous;
      end if;

      Actual_Decl := Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Lookup.Declaration);
      if Actual_Decl.Kind /= Editor.Ada_Direct_Visibility.Declaration_Instantiation then
         return Formal_Package_Contract_Actual_Not_Instance;
      end if;

      Actual_Label := Editor.Ada_Syntax_Tree.Node (Tree, Actual_Decl.Node).Label;
      Actual_Generic := To_Unbounded_String
        (Normalize (Generic_Name_From_Label (To_String (Actual_Label))));
      if To_String (Actual_Generic) = "" then
         return Formal_Package_Contract_Unknown;
      elsif To_String (Actual_Generic) = Expected then
         return Formal_Package_Contract_Compatible;
      else
         return Formal_Package_Contract_Wrong_Generic;
      end if;
   end Check_Formal_Package_Contract;

   procedure Add_Formal
     (Model : in out Generic_Contract_Model;
      Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Decl  : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      Id      : constant Generic_Formal_Id :=
        Generic_Formal_Id (Natural (Model.Formals.Length) + 1);
      Node    : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
      Label   : constant String := Trim (To_String (Node.Label));
      Default : constant String :=
        Trim (Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Default));
      Effective_Default : constant String :=
        (if Default /= "" then Default else Default_Text_From_Label (Label));
      Info    : Generic_Formal_Info := Empty_Formal;
      Kind    : constant Generic_Formal_Kind := To_Formal_Kind (Decl.Kind);
      Name    : constant String := Trim (To_String (Decl.Name));
      Param_Count : Natural := 0;
      Param_Subtypes : Unbounded_String;
      Param_Modes : Unbounded_String;
      Param_Names : Unbounded_String;
      Param_Defaults : Unbounded_String;
      Has_Result  : Boolean := False;
      Result_Subtype : Unbounded_String;
      Profile_Malformed : Boolean := False;
      Package_Target : constant String := Generic_Name_From_Label (Label);
   begin
      Info.Id := Id;
      Info.Declaration := Decl.Id;
      Info.Node := Decl.Node;
      Info.Region := Decl.Region;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Info.Kind := Kind;
      Info.Has_Default := Default /= "" or else Contains (Label, ":=")
        or else Contains (Ada.Characters.Handling.To_Lower (Label), " is <>")
        or else Contains (Ada.Characters.Handling.To_Lower (Label), " is null")
        or else Contains (Ada.Characters.Handling.To_Lower (Label), " is abstract");
      Info.Default_Text := To_Unbounded_String (Effective_Default);
      if Kind = Generic_Formal_Subprogram then
         Analyze_Subprogram_Profile
           (Tree, Node.Id, Param_Count, Param_Subtypes, Param_Modes, Param_Names, Param_Defaults, Has_Result,
            Result_Subtype, Profile_Malformed);
         Info.Formal_Parameter_Count := Param_Count;
         Info.Formal_Parameter_Subtypes := Param_Subtypes;
         Info.Formal_Parameter_Modes := Param_Modes;
         Info.Formal_Parameter_Names := Param_Names;
         Info.Formal_Parameter_Defaults := Param_Defaults;
         Info.Formal_Subprogram_Convention :=
           To_Unbounded_String (Convention_For_Declaration (Tree, Node.Id));
         Info.Formal_Has_Result := Has_Result;
         Info.Formal_Result_Subtype := Result_Subtype;
      elsif Kind = Generic_Formal_Package then
         Info.Formal_Package_Generic_Name := To_Unbounded_String (Package_Target);
         Info.Formal_Package_Normalized_Generic :=
           To_Unbounded_String (Normalize (Package_Target));
         Info.Formal_Package_Has_Box := Formal_Package_Has_Box_Actuals (Label);
      end if;
      Info.Status := (if Name = "" then Generic_Formal_Missing_Name else Generic_Formal_Record_Valid);
      Info.Start_Line := Decl.Start_Line;
      Info.End_Line := Decl.End_Line;
      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Decl.Id) * 1009
         + Natural (Decl.Region) * 97
         + Generic_Formal_Kind'Pos (Kind) * 31
         + Param_Count * 29
         + (if Has_Result then 23 else 0)
         + (if Info.Has_Default then 17 else 0)
         + Hash_Text (Name)
         + Hash_Text (Label)
         + Hash_Text (Effective_Default)
         + Hash_Text (To_String (Param_Subtypes))
         + Hash_Text (To_String (Param_Defaults))
         + Hash_Text (To_String (Param_Modes))
         + Hash_Text (To_String (Param_Names))
         + Hash_Text (To_String (Info.Formal_Subprogram_Convention))
         + Hash_Text (To_String (Result_Subtype))
         + Hash_Text (Package_Target)
         + (if Info.Formal_Package_Has_Box then 41 else 0)) mod Natural'Last;
      Model.Formals.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Formal;

   procedure Add_Instance
     (Model : in out Generic_Contract_Model;
      Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Decl  : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      Id      : constant Generic_Instance_Id :=
        Generic_Instance_Id (Natural (Model.Instances.Length) + 1);
      Node    : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
      Label   : constant String := Trim (To_String (Node.Label));
      Positional : Natural := 0;
      Named      : Natural := 0;
      Named_Names : Unbounded_String;
      Positional_Kinds : Unbounded_String;
      Named_Kinds : Unbounded_String;
      Positional_Texts : Unbounded_String;
      Named_Texts : Unbounded_String;
      Malformed  : Boolean := False;
      Name       : constant String := Trim (To_String (Decl.Name));
      Gen        : constant String := Generic_Name_From_Label (Label);
      Info       : Generic_Instance_Info := Empty_Instance;
   begin
      Count_Actuals
        (Label, Positional, Named, Named_Names, Positional_Kinds, Named_Kinds,
         Positional_Texts, Named_Texts, Malformed);
      Info.Id := Id;
      Info.Declaration := Decl.Id;
      Info.Node := Decl.Node;
      Info.Region := Decl.Region;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Info.Generic_Name := To_Unbounded_String (Gen);
      Info.Normalized_Generic := To_Unbounded_String (Normalize (Gen));
      Info.Positional_Actuals := Positional;
      Info.Named_Actuals := Named;
      Info.Total_Actuals := Positional + Named;
      Info.Named_Actual_Names := Named_Names;
      Info.Positional_Actual_Kinds := Positional_Kinds;
      Info.Named_Actual_Kinds := Named_Kinds;
      Info.Positional_Actual_Texts := Positional_Texts;
      Info.Named_Actual_Texts := Named_Texts;
      Info.Status :=
        (if Name = "" or else Gen = "" then Generic_Instance_Missing_Name
         elsif Malformed then Generic_Instance_Malformed_Actuals
         else Generic_Instance_Record_Valid);
      Info.Start_Line := Decl.Start_Line;
      Info.End_Line := Decl.End_Line;
      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Decl.Id) * 1009
         + Natural (Decl.Region) * 97
         + Positional * 43
         + Named * 37
         + Hash_Text (Name)
         + Hash_Text (Gen)
         + Hash_Text (To_String (Named_Names))
         + Hash_Text (To_String (Positional_Kinds))
         + Hash_Text (To_String (Named_Kinds))
         + Hash_Text (To_String (Positional_Texts))
         + Hash_Text (To_String (Named_Texts))) mod Natural'Last;
      Model.Instances.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Instance;

   procedure Classify_Object_Expression
     (Info       : in out Generic_Actual_Match_Info;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expression : String) is
      Value : Editor.Ada_Static_Expressions.Static_Value_Info;
   begin
      Info.Default_Expression_Checked_Formals :=
        Info.Default_Expression_Checked_Formals + 1;
      if Trim (Expression) = "" then
         Info.Default_Expression_Unknown_Formals :=
           Info.Default_Expression_Unknown_Formals + 1;
         return;
      end if;

      Value := Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
        (Static, Region, Expression);
      if Editor.Ada_Static_Expressions.Is_Static_Numeric (Value)
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Static_Attribute
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Enumeration_Literal
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Modular_Integer
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Point
      then
         Info.Default_Expression_Static_Formals :=
           Info.Default_Expression_Static_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name then
         Info.Default_Expression_Unknown_Formals :=
           Info.Default_Expression_Unknown_Formals + 1;
         Info.Default_Expression_Unresolved_Formals :=
           Info.Default_Expression_Unresolved_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Non_Static then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
         Info.Default_Expression_Nonstatic_Formals :=
           Info.Default_Expression_Nonstatic_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Malformed then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
         Info.Default_Expression_Malformed_Formals :=
           Info.Default_Expression_Malformed_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Division_By_Zero then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
         Info.Default_Expression_Division_By_Zero_Formals :=
           Info.Default_Expression_Division_By_Zero_Formals + 1;
      elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Unsupported_Attribute
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Delta_Mismatch
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Fixed_Range_Error
        or else Value.Status = Editor.Ada_Static_Expressions.Static_Value_Modular_Overflow
      then
         Info.Default_Expression_Illegal_Formals :=
           Info.Default_Expression_Illegal_Formals + 1;
      else
         Info.Default_Expression_Unknown_Formals :=
           Info.Default_Expression_Unknown_Formals + 1;
      end if;
   end Classify_Object_Expression;

   procedure Add_Actual_Match
     (Model      : in out Generic_Contract_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Instance   : Generic_Instance_Info;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Check_Default_Expressions : Boolean;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Check_Type_Graph : Boolean)
   is
      Id       : constant Generic_Actual_Match_Id :=
        Generic_Actual_Match_Id (Natural (Model.Actual_Matches.Length) + 1);
      Lookup   : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible
          (Visibility, Regions, Instance.Region, To_String (Instance.Normalized_Generic));
      Info     : Generic_Actual_Match_Info := Empty_Actual_Match;
      Gen_Decl : Editor.Ada_Direct_Visibility.Declaration_Info;
      Formal_Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Formal_Names : Unbounded_String := Null_Unbounded_String;
   begin
      Info.Id := Id;
      Info.Instance := Instance.Id;
      Info.Instance_Node := Instance.Node;
      Info.Instance_Region := Instance.Region;
      Info.Positional_Actuals := Instance.Positional_Actuals;
      Info.Named_Actuals := Instance.Named_Actuals;
      Info.Start_Line := Instance.Start_Line;
      Info.End_Line := Instance.End_Line;

      if Instance.Status /= Generic_Instance_Record_Valid then
         Info.Status := Generic_Actual_Match_Instance_Malformed;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         Info.Status := Generic_Actual_Match_Generic_Not_Found;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
         Info.Status := Generic_Actual_Match_Generic_Ambiguous;
      else
         Gen_Decl := Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
         Info.Generic_Declaration := Gen_Decl.Id;

         if Gen_Decl.Kind /= Editor.Ada_Direct_Visibility.Declaration_Generic then
            Info.Status := Generic_Actual_Match_Target_Not_Generic;
         else
            Formal_Region := Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Gen_Decl.Node);
            Info.Generic_Formal_Region := Formal_Region;

            if Formal_Region = Editor.Ada_Declarative_Regions.No_Region then
               Info.Status := Generic_Actual_Match_No_Formal_Region;
            else
               for Formal_Info of Model.Formals loop
                  if Formal_Info.Region = Formal_Region then
                     Info.Formal_Count := Info.Formal_Count + 1;
                     Formal_Names := Append_Normalized_Name
                       (Formal_Names, To_String (Formal_Info.Normalized_Name));
                     if Formal_Info.Has_Default then
                        Info.Defaulted_Formals := Info.Defaulted_Formals + 1;
                     else
                        Info.Required_Formals := Info.Required_Formals + 1;
                     end if;
                  end if;
               end loop;

               Info.Unknown_Named_Actuals := Count_Unknown_Named_Actuals
                 (To_String (Instance.Named_Actual_Names), To_String (Formal_Names));
               Info.Duplicate_Named_Actuals := Count_Duplicate_Named_Actuals
                 (To_String (Instance.Named_Actual_Names));

               if Instance.Positional_Actuals > Info.Formal_Count then
                  Info.Status := Generic_Actual_Match_Too_Many_Positionals;
               elsif Info.Unknown_Named_Actuals /= 0 then
                  Info.Status := Generic_Actual_Match_Unknown_Named_Actual;
               elsif Info.Duplicate_Named_Actuals /= 0 then
                  Info.Status := Generic_Actual_Match_Duplicate_Named_Actual;
               else
                  declare
                     Position : Natural := 0;
                  begin
                     for Formal_Info of Model.Formals loop
                        if Formal_Info.Region = Formal_Region then
                           Position := Position + 1;
                           declare
                              Actual_Kind : Generic_Actual_Kind := Generic_Actual_Unknown;
                              Has_Actual  : Boolean := False;
                              Kind_Result : Generic_Formal_Actual_Kind_Match;
                              Actual_Text : Unbounded_String := Null_Unbounded_String;
                              Profile_Result : Generic_Formal_Actual_Kind_Match;
                              Package_Result : Formal_Package_Contract_Status;
                           begin
                              if Position <= Instance.Positional_Actuals then
                                 Has_Actual := True;
                                 Actual_Kind := Positional_Kind_At
                                   (To_String (Instance.Positional_Actual_Kinds), Positive (Position));
                                 Actual_Text := To_Unbounded_String
                                   (Delimited_Text_At
                                      (To_String (Instance.Positional_Actual_Texts),
                                       Positive (Position)));
                              elsif List_Contains_Name
                                (To_String (Instance.Named_Actual_Names),
                                 To_String (Formal_Info.Normalized_Name))
                              then
                                 Has_Actual := True;
                                 Actual_Kind := Named_Kind_For
                                   (To_String (Instance.Named_Actual_Kinds),
                                    To_String (Formal_Info.Normalized_Name));
                                 Actual_Text := To_Unbounded_String
                                   (Named_Text_For
                                      (To_String (Instance.Named_Actual_Texts),
                                       To_String (Formal_Info.Normalized_Name)));
                              end if;

                              if Has_Actual then
                                 Actual_Kind := Resolve_Actual_Kind
                                   (Visibility, Regions, Instance.Region,
                                    To_String (Actual_Text), Actual_Kind);
                                 Info.Matched_Formals := Info.Matched_Formals + 1;
                                 Kind_Result := Kind_Compatible (Formal_Info.Kind, Actual_Kind);
                                 case Kind_Result is
                                    when Generic_Formal_Actual_Kind_Matches =>
                                       Info.Kind_Compatible_Formals :=
                                         Info.Kind_Compatible_Formals + 1;
                                    when Generic_Formal_Actual_Kind_Mismatch =>
                                       if Formal_Info.Kind = Generic_Formal_Subprogram
                                         and then Actual_Kind = Generic_Actual_Subprogram
                                       then
                                          null;
                                       else
                                          Info.Kind_Mismatched_Formals :=
                                            Info.Kind_Mismatched_Formals + 1;
                                       end if;
                                    when Generic_Formal_Actual_Kind_Unknown =>
                                       Info.Kind_Unknown_Formals :=
                                         Info.Kind_Unknown_Formals + 1;
                                    when Generic_Formal_Actual_Kind_Missing =>
                                       null;
                                 end case;

                                 if Check_Default_Expressions
                                   and then Formal_Info.Kind = Generic_Formal_Object
                                   and then Kind_Result /= Generic_Formal_Actual_Kind_Mismatch
                                 then
                                    Classify_Object_Expression
                                      (Info, Static, Instance.Region,
                                       To_String (Actual_Text));
                                 end if;

                                 if Formal_Info.Kind = Generic_Formal_Subprogram
                                 then
                                    declare
                                       Selection : constant Subprogram_Profile_Selection_Info :=
                                         Select_Subprogram_Actual_By_Profile
                                           (Model, Instance, Tree, Visibility, Regions,
                                            Types, Check_Type_Graph,
                                            Instance.Region, Formal_Info,
                                            To_String (Actual_Text));
                                    begin
                                       Info.Subprogram_Profile_Overload_Candidates :=
                                         Info.Subprogram_Profile_Overload_Candidates
                                         + Selection.Candidate_Count;
                                       Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals :=
                                         Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals
                                         + Selection.Null_Exclusion_Mismatch_Count;
                                       Info.Subprogram_Profile_Access_Profile_Mismatched_Formals :=
                                         Info.Subprogram_Profile_Access_Profile_Mismatched_Formals
                                         + Selection.Access_Profile_Mismatch_Count;
                                       Info.Subprogram_Profile_Type_Compatible_Formals :=
                                         Info.Subprogram_Profile_Type_Compatible_Formals
                                         + Selection.Type_Compatible_Count;
                                       Info.Subprogram_Profile_Type_Mismatched_Formals :=
                                         Info.Subprogram_Profile_Type_Mismatched_Formals
                                         + Selection.Type_Mismatch_Count;
                                       Info.Subprogram_Profile_Type_Unknown_Formals :=
                                         Info.Subprogram_Profile_Type_Unknown_Formals
                                         + Selection.Type_Unknown_Count;
                                       Info.Subprogram_Profile_Result_Compatible_Formals :=
                                         Info.Subprogram_Profile_Result_Compatible_Formals
                                         + Selection.Result_Compatible_Count;
                                       Info.Subprogram_Profile_Result_Mismatched_Formals :=
                                         Info.Subprogram_Profile_Result_Mismatched_Formals
                                         + Selection.Result_Mismatch_Count;
                                       Info.Subprogram_Profile_Result_Unknown_Formals :=
                                         Info.Subprogram_Profile_Result_Unknown_Formals
                                         + Selection.Result_Unknown_Count;
                                       case Selection.Status is
                                          when Subprogram_Profile_Selected =>
                                             Info.Subprogram_Profile_Compatible_Formals :=
                                               Info.Subprogram_Profile_Compatible_Formals + 1;
                                             Info.Subprogram_Profile_Overload_Selected_Formals :=
                                               Info.Subprogram_Profile_Overload_Selected_Formals + 1;
                                          when Subprogram_Profile_No_Profile_Match =>
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Mode_Mismatch =>
                                             Info.Subprogram_Profile_Mode_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mode_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Null_Exclusion_Mismatch =>
                                             Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Access_Profile_Mismatch =>
                                             Info.Subprogram_Profile_Access_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Access_Profile_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Convention_Mismatch =>
                                             Info.Subprogram_Profile_Convention_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Convention_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Default_Mismatch =>
                                             Info.Subprogram_Profile_Default_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Default_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Class_Wide_Mismatch =>
                                             Info.Subprogram_Profile_Class_Wide_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Class_Wide_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Name_Mismatch =>
                                             Info.Subprogram_Profile_Name_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Name_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Result_Mismatch =>
                                             Info.Subprogram_Profile_Result_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Result_Mismatched_Formals + 1;
                                             Info.Subprogram_Profile_Mismatched_Formals :=
                                               Info.Subprogram_Profile_Mismatched_Formals + 1;
                                          when Subprogram_Profile_Ambiguous_Profile_Match =>
                                             Info.Subprogram_Profile_Overload_Ambiguous_Formals :=
                                               Info.Subprogram_Profile_Overload_Ambiguous_Formals + 1;
                                          when Subprogram_Profile_No_Candidates =>
                                             Info.Subprogram_Profile_Overload_Unresolved_Formals :=
                                               Info.Subprogram_Profile_Overload_Unresolved_Formals + 1;
                                             Info.Subprogram_Profile_Unknown_Formals :=
                                               Info.Subprogram_Profile_Unknown_Formals + 1;
                                          when Subprogram_Profile_Unknown =>
                                             Info.Subprogram_Profile_Unknown_Formals :=
                                               Info.Subprogram_Profile_Unknown_Formals + 1;
                                       end case;
                                    end;
                                 end if;

                                 if Formal_Info.Kind = Generic_Formal_Package
                                   and then Kind_Result = Generic_Formal_Actual_Kind_Matches
                                 then
                                    Package_Result := Check_Formal_Package_Contract
                                      (Tree, Visibility, Regions, Instance.Region,
                                       Formal_Info, To_String (Actual_Text));
                                    case Package_Result is
                                       when Formal_Package_Contract_Compatible =>
                                          Info.Formal_Package_Compatible_Formals :=
                                            Info.Formal_Package_Compatible_Formals + 1;
                                       when Formal_Package_Contract_Actual_Not_Instance =>
                                          Info.Formal_Package_Mismatched_Formals :=
                                            Info.Formal_Package_Mismatched_Formals + 1;
                                          Info.Formal_Package_Not_Instance_Formals :=
                                            Info.Formal_Package_Not_Instance_Formals + 1;
                                       when Formal_Package_Contract_Wrong_Generic =>
                                          Info.Formal_Package_Mismatched_Formals :=
                                            Info.Formal_Package_Mismatched_Formals + 1;
                                          Info.Formal_Package_Wrong_Generic_Formals :=
                                            Info.Formal_Package_Wrong_Generic_Formals + 1;
                                       when Formal_Package_Contract_Actual_Unresolved =>
                                          Info.Formal_Package_Unknown_Formals :=
                                            Info.Formal_Package_Unknown_Formals + 1;
                                          Info.Formal_Package_Unresolved_Formals :=
                                            Info.Formal_Package_Unresolved_Formals + 1;
                                       when Formal_Package_Contract_Actual_Ambiguous =>
                                          Info.Formal_Package_Unknown_Formals :=
                                            Info.Formal_Package_Unknown_Formals + 1;
                                          Info.Formal_Package_Ambiguous_Formals :=
                                            Info.Formal_Package_Ambiguous_Formals + 1;
                                       when Formal_Package_Contract_Unknown =>
                                          Info.Formal_Package_Unknown_Formals :=
                                            Info.Formal_Package_Unknown_Formals + 1;
                                          Info.Formal_Package_Contract_Unknown_Formals :=
                                            Info.Formal_Package_Contract_Unknown_Formals + 1;
                                       when Formal_Package_Contract_Malformed =>
                                          Info.Formal_Package_Mismatched_Formals :=
                                            Info.Formal_Package_Mismatched_Formals + 1;
                                          Info.Formal_Package_Malformed_Formals :=
                                            Info.Formal_Package_Malformed_Formals + 1;
                                    end case;
                                 end if;
                              elsif not Formal_Info.Has_Default then
                                 Info.Missing_Required_Formals :=
                                   Info.Missing_Required_Formals + 1;
                              elsif Check_Default_Expressions
                                and then Formal_Info.Kind = Generic_Formal_Object
                              then
                                 Classify_Object_Expression
                                   (Info, Static, Formal_Info.Region,
                                    To_String (Formal_Info.Default_Text));
                              end if;
                           end;
                        end if;
                     end loop;
                  end;

                  if Info.Missing_Required_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Missing_Required_Formal;
                  elsif Info.Kind_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Kind_Mismatch;
                  elsif Info.Subprogram_Profile_Overload_Ambiguous_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Profile_Ambiguous;
                  elsif Info.Subprogram_Profile_Mode_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Mode_Mismatch;
                  elsif Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Null_Exclusion_Mismatch;
                  elsif Info.Subprogram_Profile_Access_Profile_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Access_Profile_Mismatch;
                  elsif Info.Subprogram_Profile_Convention_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Convention_Mismatch;
                  elsif Info.Subprogram_Profile_Default_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Default_Mismatch;
                  elsif Info.Subprogram_Profile_Class_Wide_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch;
                  elsif Info.Subprogram_Profile_Name_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Name_Mismatch;
                  elsif Info.Subprogram_Profile_Result_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Result_Mismatch;
                  elsif Info.Subprogram_Profile_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Subprogram_Profile_Mismatch;
                  elsif Info.Formal_Package_Mismatched_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Package_Contract_Mismatch;
                  elsif Info.Formal_Package_Unknown_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Package_Contract_Unknown;
                  elsif Info.Default_Expression_Illegal_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Object_Default_Illegal;
                  elsif Info.Default_Expression_Unknown_Formals /= 0 then
                     Info.Status := Generic_Actual_Match_Formal_Object_Default_Unknown;
                  else
                     Info.Status := Generic_Actual_Match_Valid;
                  end if;
               end if;
            end if;
         end if;
      end if;

      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Info.Instance) * 1009
         + Natural (Info.Generic_Declaration) * 503
         + Natural (Info.Generic_Formal_Region) * 97
         + Generic_Actual_Match_Status'Pos (Info.Status) * 43
         + Info.Formal_Count * 37
         + Info.Required_Formals * 31
         + Info.Matched_Formals * 29
         + Info.Unknown_Named_Actuals * 23
         + Info.Duplicate_Named_Actuals * 19
         + Info.Missing_Required_Formals * 17
         + Info.Kind_Compatible_Formals * 13
         + Info.Kind_Mismatched_Formals * 11
         + Info.Kind_Unknown_Formals * 7
         + Info.Subprogram_Profile_Compatible_Formals * 5
         + Info.Subprogram_Profile_Mismatched_Formals * 3
         + Info.Subprogram_Profile_Unknown_Formals
         + Info.Subprogram_Profile_Null_Exclusion_Mismatched_Formals * 143
         + Info.Subprogram_Profile_Access_Profile_Mismatched_Formals * 147
         + Info.Subprogram_Profile_Convention_Mismatched_Formals * 148
         + Info.Subprogram_Profile_Default_Mismatched_Formals * 150
         + Info.Subprogram_Profile_Class_Wide_Mismatched_Formals * 152
         + Info.Subprogram_Profile_Name_Mismatched_Formals * 154
         + Info.Subprogram_Profile_Result_Compatible_Formals * 158
         + Info.Subprogram_Profile_Result_Mismatched_Formals * 160
         + Info.Subprogram_Profile_Result_Unknown_Formals * 162
         + Info.Subprogram_Profile_Type_Compatible_Formals * 149
         + Info.Subprogram_Profile_Type_Mismatched_Formals * 151
         + Info.Subprogram_Profile_Type_Unknown_Formals * 157
         + Info.Subprogram_Profile_Overload_Candidates * 41
         + Info.Subprogram_Profile_Overload_Selected_Formals * 47
         + Info.Subprogram_Profile_Overload_Ambiguous_Formals * 53
         + Info.Subprogram_Profile_Overload_Unresolved_Formals * 59
         + Info.Formal_Package_Compatible_Formals * 61
         + Info.Formal_Package_Mismatched_Formals * 67
         + Info.Formal_Package_Unknown_Formals * 71
         + Info.Formal_Package_Unresolved_Formals * 73
         + Info.Formal_Package_Ambiguous_Formals * 79
         + Info.Formal_Package_Not_Instance_Formals * 83
         + Info.Formal_Package_Wrong_Generic_Formals * 89
         + Info.Formal_Package_Contract_Unknown_Formals * 97
         + Info.Formal_Package_Malformed_Formals * 101
         + Info.Default_Expression_Checked_Formals * 103
         + Info.Default_Expression_Static_Formals * 107
         + Info.Default_Expression_Illegal_Formals * 109
         + Info.Default_Expression_Unknown_Formals * 113
         + Info.Default_Expression_Unresolved_Formals * 127
         + Info.Default_Expression_Nonstatic_Formals * 131
         + Info.Default_Expression_Malformed_Formals * 137
         + Info.Default_Expression_Division_By_Zero_Formals * 139) mod Natural'Last;
      Model.Actual_Matches.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Actual_Match;

   function Direct_Body_Shadow
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name : String) return Boolean
   is
      Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Direct
          (Visibility, Body_Region, Normalize (Name));
   begin
      return Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found
        or else Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous;
   end Direct_Body_Shadow;

   function Body_Declaration_For_Generic
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Name       : String) return Editor.Ada_Direct_Visibility.Declaration_Info
   is
      N : constant String := Normalize (Name);
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
         begin
            if To_String (Decl.Normalized) = N
              and then (Node.Kind = Editor.Ada_Syntax_Tree.Node_Package_Body
                        or else Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body)
            then
               return Decl;
            end if;
         end;
      end loop;
      return Editor.Ada_Direct_Visibility.Declaration
        (Visibility, Editor.Ada_Direct_Visibility.No_Declaration);
   end Body_Declaration_For_Generic;

   procedure Add_Body_Contract_Visibility
     (Model      : in out Generic_Contract_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Generic_Decl    : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      Id : constant Generic_Body_Contract_Visibility_Id :=
        Generic_Body_Contract_Visibility_Id
          (Natural (Model.Body_Contract_Visibility.Length) + 1);
      Generic_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Generic_Decl.Node);
      Formal_Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.Region_For_Node (Regions, Generic_Decl.Node);
      Body_Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
        Body_Declaration_For_Generic (Tree, Visibility, To_String (Generic_Decl.Normalized));
      Info : Generic_Body_Contract_Visibility_Info := Empty_Body_Contract_Visibility;
   begin
      Info.Id := Id;
      Info.Generic_Declaration := Generic_Decl.Id;
      Info.Generic_Node := Generic_Decl.Node;
      Info.Generic_Formal_Region := Formal_Region;
      Info.Name := Generic_Decl.Name;
      Info.Normalized_Name := Generic_Decl.Normalized;
      Info.Start_Line := Generic_Decl.Start_Line;
      Info.End_Line := Generic_Decl.End_Line;

      if Formal_Region = Editor.Ada_Declarative_Regions.No_Region then
         Info.Status := Generic_Body_Contract_No_Formal_Region;
      else
         for Formal_Info of Model.Formals loop
            if Formal_Info.Region = Formal_Region then
               Info.Formal_Count := Info.Formal_Count + 1;
            end if;
         end loop;

         if Body_Decl.Id = Editor.Ada_Direct_Visibility.No_Declaration then
            Info.Status := Generic_Body_Contract_Body_Not_Found;
         else
            Info.Body_Declaration := Body_Decl.Id;
            Info.Body_Node := Body_Decl.Node;
            Info.Body_Region := Editor.Ada_Declarative_Regions.Region_For_Node
              (Regions, Body_Decl.Node);
            Info.End_Line := Body_Decl.End_Line;
            for Formal_Info of Model.Formals loop
               if Formal_Info.Region = Formal_Region then
                  if Direct_Body_Shadow
                    (Visibility, Info.Body_Region,
                     To_String (Formal_Info.Normalized_Name))
                  then
                     Info.Shadowed_Formals := Info.Shadowed_Formals + 1;
                     Info.Shadowed_Formal_Names := Append_Normalized_Name
                       (Info.Shadowed_Formal_Names,
                        To_String (Formal_Info.Normalized_Name));
                  else
                     Info.Visible_Formals := Info.Visible_Formals + 1;
                  end if;
               end if;
            end loop;
            Info.Status := Generic_Body_Contract_Visible;
         end if;
      end if;

      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Info.Generic_Declaration) * 1009
         + Natural (Info.Generic_Formal_Region) * 503
         + Natural (Info.Body_Declaration) * 97
         + Natural (Info.Body_Region) * 89
         + Generic_Body_Contract_Visibility_Status'Pos (Info.Status) * 43
         + Info.Formal_Count * 37
         + Info.Visible_Formals * 31
         + Info.Shadowed_Formals * 29
         + Hash_Text (To_String (Info.Shadowed_Formal_Names))
         + Hash_Text (To_String (Info.Normalized_Name))
         + Hash_Text (To_String (Generic_Node.Label))) mod Natural'Last;
      Model.Body_Contract_Visibility.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Body_Contract_Visibility;

   procedure Add_Body_Contract_Visibility_All
     (Model      : in out Generic_Contract_Model;
      Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
   is
   begin
      for Index in 1 .. Editor.Ada_Direct_Visibility.Declaration_Count (Visibility) loop
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration_At (Visibility, Index);
         begin
            if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Generic then
               Add_Body_Contract_Visibility (Model, Tree, Regions, Visibility, Decl);
            end if;
         end;
      end loop;
   end Add_Body_Contract_Visibility_All;


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
                  Add_Formal (Model, Tree, Decl);
               when Editor.Ada_Direct_Visibility.Declaration_Instantiation =>
                  Add_Instance (Model, Tree, Decl);
               when others =>
                  null;
            end case;
         end;
      end loop;

      for Info of Model.Instances loop
         Add_Actual_Match
           (Model, Tree, Regions, Visibility, Info,
            Static, Check_Default_Expressions, Types, Check_Type_Graph);
      end loop;

      Add_Body_Contract_Visibility_All (Model, Tree, Regions, Visibility);

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
