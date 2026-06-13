with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;

package body Editor.Ada_Generic_Formal_Package_Nested_Conformance is

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Trim (Text));
   end Normalize;

   function Contains_Box (Text : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Normalize (Text), "<>") /= 0;
   end Contains_Box;

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

   function Actual_Text_For_Formal
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Instance  : Editor.Ada_Generic_Contracts.Generic_Instance_Info;
      Formal    : Editor.Ada_Generic_Contracts.Generic_Formal_Info) return String
   is
      Position : Natural := 0;
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
         declare
            Candidate : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
              Editor.Ada_Generic_Contracts.Formal_At (Contracts, Index);
         begin
            if Candidate.Region = Formal.Region then
               Position := Position + 1;
               if Candidate.Id = Formal.Id then
                  if Position <= Instance.Positional_Actuals then
                     return Delimited_Text_At
                       (To_String (Instance.Positional_Actual_Texts),
                        Positive (Position));
                  else
                     return Named_Text_For
                       (To_String (Instance.Named_Actual_Texts),
                        To_String (Formal.Normalized_Name));
                  end if;
               end if;
            end if;
         end;
      end loop;

      return "";
   end Actual_Text_For_Formal;

   function Generic_Name_From_Label (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Normalize (T);
      Pos   : Natural := Ada.Strings.Fixed.Index (Lower, " is new ");
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

   function Inline_Generic_Name (Text : String) return String is
      T     : constant String := Trim (Text);
      Lower : constant String := Normalize (T);
      First : Natural;
      Last  : Natural;
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
   end Inline_Generic_Name;

   function Actual_List_From_Text (Text : String) return String is
      T      : constant String := Trim (Text);
      Open_P : Natural := 0;
      Close_P : Natural := 0;
      Depth  : Natural := 0;
      Result : Unbounded_String;
   begin
      for I in T'Range loop
         if T (I) = '(' then
            if Depth = 0 and then Open_P = 0 then
               Open_P := I;
            end if;
            Depth := Depth + 1;
         elsif T (I) = ')' then
            if Depth > 0 then
               Depth := Depth - 1;
               if Depth = 0 then
                  Close_P := I;
                  exit;
               end if;
            end if;
         end if;
      end loop;

      if Open_P = 0 or else Close_P = 0 or else Close_P <= Open_P + 1 then
         return "";
      end if;

      declare
         Inside : constant String := T (Open_P + 1 .. Close_P - 1);
         First : Natural := Inside'First;
         Local_Depth : Natural := 0;
      begin
         for I in Inside'Range loop
            if Inside (I) = '(' then
               Local_Depth := Local_Depth + 1;
            elsif Inside (I) = ')' and then Local_Depth > 0 then
               Local_Depth := Local_Depth - 1;
            elsif Inside (I) = ',' and then Local_Depth = 0 then
               if Length (Result) /= 0 then
                  Append (Result, "|");
               end if;
               Append (Result, Trim (Inside (First .. I - 1)));
               First := I + 1;
            end if;
         end loop;

         if First <= Inside'Last then
            if Length (Result) /= 0 then
               Append (Result, "|");
            end if;
            Append (Result, Trim (Inside (First .. Inside'Last)));
         end if;
      end;

      return To_String (Result);
   end Actual_List_From_Text;

   function Formal_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Formal : Editor.Ada_Generic_Contracts.Generic_Formal_Info) return String is
      use type Editor.Ada_Syntax_Tree.Node_Id;
   begin
      if Formal.Node = Editor.Ada_Syntax_Tree.No_Node then
         return "";
      else
         return To_String (Editor.Ada_Syntax_Tree.Node (Tree, Formal.Node).Label);
      end if;
   end Formal_Label;

   function Instance_By_Name
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Name      : String) return Editor.Ada_Generic_Contracts.Generic_Instance_Info
   is
      N : constant String := Normalize (Name);
   begin
      if N = "" then
         return (others => <>);
      end if;

      for Index in 1 .. Editor.Ada_Generic_Contracts.Instance_Count (Contracts) loop
         declare
            Candidate : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance_At (Contracts, Index);
         begin
            if To_String (Candidate.Normalized_Name) = N then
               return Candidate;
            end if;
         end;
      end loop;

      return (others => <>);
   end Instance_By_Name;

   procedure Compare_Nested_Actuals
     (Formal_List : String;
      Actual_List : String;
      Compared    : out Natural;
      Boxes       : out Natural;
      Mismatches  : out Natural;
      Missing     : out Natural)
   is
      Formal_Count : Natural := 0;
   begin
      Compared := 0;
      Boxes := 0;
      Mismatches := 0;
      Missing := 0;

      loop
         Formal_Count := Formal_Count + 1;
         declare
            Formal_Text : constant String := Delimited_Text_At (Formal_List, Formal_Count);
            Actual_Text : constant String := Delimited_Text_At (Actual_List, Formal_Count);
         begin
            exit when Formal_Text = "";
            Compared := Compared + 1;
            if Contains_Box (Formal_Text) then
               Boxes := Boxes + 1;
            elsif Actual_Text = "" then
               Missing := Missing + 1;
            elsif Normalize (Formal_Text) /= Normalize (Actual_Text) then
               Mismatches := Mismatches + 1;
            end if;
         end;
      end loop;
   end Compare_Nested_Actuals;

   procedure Add_Check
     (Model : in out Formal_Package_Nested_Model;
      Info  : in out Formal_Package_Nested_Info) is
   begin
      Info.Fingerprint :=
        Mix (Natural (Info.Instance),
             Mix (Natural (Info.Formal),
                  Mix (Natural (Info.Actual_Instance),
                       Mix (Natural (Info.Instance_Node),
                            Mix (Natural (Info.Formal_Node),
                                 Mix (Formal_Package_Nested_Status'Pos (Info.Status),
                                      Mix (Info.Compared_Count,
                                           Mix (Info.Box_Count,
                                                Mix (Info.Mismatch_Count,
                                                     Info.Missing_Count)))))))));

      case Info.Status is
         when Formal_Package_Nested_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
         when Formal_Package_Nested_Box_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
            Model.Box_Compatible_Total := Model.Box_Compatible_Total + 1;
         when Formal_Package_Nested_Actual_Mismatch =>
            Model.Mismatch_Total := Model.Mismatch_Total + 1;
         when Formal_Package_Nested_Actual_Missing =>
            Model.Missing_Total := Model.Missing_Total + 1;
         when Formal_Package_Nested_Wrong_Generic =>
            Model.Wrong_Generic_Total := Model.Wrong_Generic_Total + 1;
         when Formal_Package_Nested_Actual_Unresolved |
              Formal_Package_Nested_Actual_Not_Instance =>
            Model.Unresolved_Total := Model.Unresolved_Total + 1;
         when Formal_Package_Nested_Unknown |
              Formal_Package_Nested_Malformed =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
      end case;

      Model.Checks.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Add_Check;

   procedure Clear (Model : in out Formal_Package_Nested_Model) is
   begin
      Model.Checks.Clear;
      Model.Compatible_Total := 0;
      Model.Box_Compatible_Total := 0;
      Model.Mismatch_Total := 0;
      Model.Missing_Total := 0;
      Model.Wrong_Generic_Total := 0;
      Model.Unresolved_Total := 0;
      Model.Unknown_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Formal_Package_Nested_Model
   is
      use type Editor.Ada_Declarative_Regions.Region_Id;
      use type Editor.Ada_Generic_Contracts.Generic_Formal_Kind;
      use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
      use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Result : Formal_Package_Nested_Model;
   begin
      for Match_Index in 1 .. Editor.Ada_Generic_Contracts.Actual_Match_Count (Contracts) loop
         declare
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_At (Contracts, Match_Index);
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance (Contracts, Match.Instance);
         begin
            if Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid
              or else Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Package_Contract_Mismatch
              or else Match.Status = Editor.Ada_Generic_Contracts.Generic_Actual_Match_Formal_Package_Contract_Unknown
            then
               for Formal_Index in 1 .. Editor.Ada_Generic_Contracts.Formal_Count (Contracts) loop
                  declare
                     Formal : constant Editor.Ada_Generic_Contracts.Generic_Formal_Info :=
                       Editor.Ada_Generic_Contracts.Formal_At (Contracts, Formal_Index);
                  begin
                     if Formal.Region = Match.Generic_Formal_Region
                       and then Formal.Kind = Editor.Ada_Generic_Contracts.Generic_Formal_Package
                     then
                        declare
                           Actual_Text : constant String :=
                             Actual_Text_For_Formal (Contracts, Instance, Formal);
                           Formal_Label_Text : constant String := Formal_Label (Tree, Formal);
                           Formal_List : constant String := Actual_List_From_Text (Formal_Label_Text);
                           Expected_Generic : constant String :=
                             To_String (Formal.Formal_Package_Normalized_Generic);
                           Inline_Generic : constant String := Normalize (Inline_Generic_Name (Actual_Text));
                           Actual_Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
                             Instance_By_Name (Contracts, Actual_Text);
                           Actual_Generic : constant String :=
                             (if Inline_Generic /= "" then Inline_Generic
                              else To_String (Actual_Instance.Normalized_Generic));
                           Actual_List : constant String :=
                             (if Inline_Generic /= "" then Actual_List_From_Text (Actual_Text)
                              else To_String (Actual_Instance.Positional_Actual_Texts));
                           Info : Formal_Package_Nested_Info;
                        begin
                           Info.Instance := Instance.Id;
                           Info.Formal := Formal.Id;
                           Info.Actual_Instance := Actual_Instance.Id;
                           Info.Instance_Node := Instance.Node;
                           Info.Formal_Node := Formal.Node;
                           Info.Actual_Node := Actual_Instance.Node;
                           Info.Formal_Name := Formal.Name;
                           Info.Expected_Generic := Formal.Formal_Package_Normalized_Generic;
                           Info.Actual_Text := To_Unbounded_String (Actual_Text);
                           Info.Formal_Actuals := To_Unbounded_String (Formal_List);
                           Info.Actual_Actuals := To_Unbounded_String (Actual_List);
                           Info.Start_Line := Instance.Start_Line;
                           Info.End_Line := Instance.End_Line;

                           if Expected_Generic = "" or else Formal_List = "" then
                              Info.Status := Formal_Package_Nested_Unknown;
                           elsif Actual_Text = "" then
                              Info.Status := Formal_Package_Nested_Malformed;
                           elsif Inline_Generic = "" and then Actual_Instance.Id =
                             Editor.Ada_Generic_Contracts.No_Generic_Instance
                           then
                              Info.Status := Formal_Package_Nested_Actual_Unresolved;
                           elsif Actual_Generic /= Expected_Generic then
                              Info.Status := Formal_Package_Nested_Wrong_Generic;
                           else
                              Compare_Nested_Actuals
                                (Formal_List, Actual_List,
                                 Info.Compared_Count, Info.Box_Count,
                                 Info.Mismatch_Count, Info.Missing_Count);
                              if Info.Missing_Count /= 0 then
                                 Info.Status := Formal_Package_Nested_Actual_Missing;
                              elsif Info.Mismatch_Count /= 0 then
                                 Info.Status := Formal_Package_Nested_Actual_Mismatch;
                              elsif Info.Box_Count /= 0 then
                                 Info.Status := Formal_Package_Nested_Box_Compatible;
                              else
                                 Info.Status := Formal_Package_Nested_Compatible;
                              end if;
                           end if;

                           Add_Check (Result, Info);
                        end;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;

      return Result;
   end Build;

   function Check_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Formal_Package_Nested_Model;
      Index : Positive) return Formal_Package_Nested_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function Compatible_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Box_Compatible_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Box_Compatible_Total;
   end Box_Compatible_Count;

   function Mismatch_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Mismatch_Total;
   end Mismatch_Count;

   function Missing_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Missing_Total;
   end Missing_Count;

   function Wrong_Generic_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Wrong_Generic_Total;
   end Wrong_Generic_Count;

   function Unresolved_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Unknown_Count (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Fingerprint (Model : Formal_Package_Nested_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Formal_Package_Nested_Conformance;
