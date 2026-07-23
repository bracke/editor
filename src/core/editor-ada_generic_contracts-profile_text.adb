with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Generic_Contracts.Core_Utilities;

package body Editor.Ada_Generic_Contracts.Profile_Text is

   pragma Suppress (Overflow_Check);

   function Trim (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Normalize;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Child_Label;

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
      Mode_Text : constant String :=
        Normalize (Child_Label (Tree, Node, Editor.Ada_Syntax_Tree.Node_Declaration_Mode));
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

      if Profile /= ""
        and then not
          (Mode_Text = "expression function"
           and then Ada.Strings.Fixed.Index (Profile, ":") = 0)
      then
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

end Editor.Ada_Generic_Contracts.Profile_Text;
