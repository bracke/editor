with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Formal_Package_Substitutions is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
   use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
   use type Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Status;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result :=
           (Result * 131 + Character'Pos (Ada.Characters.Handling.To_Lower (C)) + 1)
           mod Natural'Last;
      end loop;
      return Result;
   end Hash_Text;

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

   function Entry_Status
     (Check       : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Info;
      Formal_Text : String;
      Actual_Text : String) return Formal_Package_Substitution_Status
   is
   begin
      case Check.Status is
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Compatible |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Box_Compatible =>
            if Contains_Box (Formal_Text) then
               return Formal_Package_Substitution_Boxed;
            elsif Actual_Text = "" then
               return Formal_Package_Substitution_Missing;
            elsif Normalize (Formal_Text) = Normalize (Actual_Text) then
               return Formal_Package_Substitution_Substituted;
            else
               return Formal_Package_Substitution_Mismatch;
            end if;
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Mismatch =>
            if Actual_Text = "" then
               return Formal_Package_Substitution_Missing;
            elsif Contains_Box (Formal_Text) then
               return Formal_Package_Substitution_Boxed;
            elsif Normalize (Formal_Text) /= Normalize (Actual_Text) then
               return Formal_Package_Substitution_Mismatch;
            else
               return Formal_Package_Substitution_Substituted;
            end if;
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Missing =>
            if Actual_Text = "" then
               return Formal_Package_Substitution_Missing;
            else
               return Formal_Package_Substitution_Substituted;
            end if;
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Wrong_Generic =>
            return Formal_Package_Substitution_Wrong_Generic;
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Unresolved |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Not_Instance =>
            return Formal_Package_Substitution_Unresolved;
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Malformed =>
            return Formal_Package_Substitution_Malformed;
         when Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Unknown =>
            return Formal_Package_Substitution_Unknown;
      end case;
   end Entry_Status;

   procedure Add_Entry
     (Model : in out Formal_Package_Substitution_Model;
      Item  : Formal_Package_Substitution_Info) is
   begin
      Model.Entries.Append (Item);
      case Item.Status is
         when Formal_Package_Substitution_Substituted =>
            Model.Substituted_Total := Model.Substituted_Total + 1;
         when Formal_Package_Substitution_Boxed =>
            Model.Boxed_Total := Model.Boxed_Total + 1;
         when Formal_Package_Substitution_Mismatch =>
            Model.Mismatch_Total := Model.Mismatch_Total + 1;
         when Formal_Package_Substitution_Missing =>
            Model.Missing_Total := Model.Missing_Total + 1;
         when Formal_Package_Substitution_Wrong_Generic =>
            Model.Wrong_Generic_Total := Model.Wrong_Generic_Total + 1;
         when Formal_Package_Substitution_Unresolved =>
            Model.Unresolved_Total := Model.Unresolved_Total + 1;
         when Formal_Package_Substitution_Malformed |
              Formal_Package_Substitution_Unknown |
              Formal_Package_Substitution_Not_Checked =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
      end case;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Mix (Item.Fingerprint,
                  Mix (Natural (Item.Instance), Natural (Item.Formal))));
   end Add_Entry;

   function Build
     (Nested : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model)
      return Formal_Package_Substitution_Model
   is
      Result : Formal_Package_Substitution_Model;
   begin
      for Check_Index in 1 .. Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_Count (Nested) loop
         declare
            Check : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Info :=
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_At (Nested, Check_Index);
            Position : Positive := 1;
         begin
            loop
               declare
                  Formal_Text : constant String :=
                    Delimited_Text_At (To_String (Check.Formal_Actuals), Position);
                  Actual_Text : constant String :=
                    Delimited_Text_At (To_String (Check.Actual_Actuals), Position);
                  Item : Formal_Package_Substitution_Info;
               begin
                  exit when Formal_Text = "";
                  Item.Id := Formal_Package_Substitution_Id (Natural (Result.Entries.Length) + 1);
                  Item.Check_Index := Check_Index;
                  Item.Instance := Check.Instance;
                  Item.Formal := Check.Formal;
                  Item.Actual_Instance := Check.Actual_Instance;
                  Item.Instance_Node := Check.Instance_Node;
                  Item.Formal_Node := Check.Formal_Node;
                  Item.Actual_Node := Check.Actual_Node;
                  Item.Formal_Name := Check.Formal_Name;
                  Item.Expected_Generic := Check.Expected_Generic;
                  Item.Nested_Position := Position;
                  Item.Formal_Actual_Text := To_Unbounded_String (Formal_Text);
                  Item.Actual_Actual_Text := To_Unbounded_String (Actual_Text);
                  Item.Status := Entry_Status (Check, Formal_Text, Actual_Text);
                  Item.Start_Line := Check.Start_Line;
                  Item.End_Line := Check.End_Line;
                  Item.Source_Fingerprint := Check.Fingerprint;
                  Item.Fingerprint :=
                    Mix (Check.Fingerprint,
                         Mix (Position,
                              Mix (Formal_Package_Substitution_Status'Pos (Item.Status),
                                   Mix (Hash_Text (Formal_Text), Hash_Text (Actual_Text)))));
                  Add_Entry (Result, Item);
                  Position := Position + 1;
               end;
            end loop;

            if Check.Status in
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Wrong_Generic |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Unresolved |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Not_Instance |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Malformed |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Unknown
              and then To_String (Check.Formal_Actuals) = ""
            then
               declare
                  Item : Formal_Package_Substitution_Info;
               begin
                  Item.Id := Formal_Package_Substitution_Id (Natural (Result.Entries.Length) + 1);
                  Item.Check_Index := Check_Index;
                  Item.Instance := Check.Instance;
                  Item.Formal := Check.Formal;
                  Item.Actual_Instance := Check.Actual_Instance;
                  Item.Instance_Node := Check.Instance_Node;
                  Item.Formal_Node := Check.Formal_Node;
                  Item.Actual_Node := Check.Actual_Node;
                  Item.Formal_Name := Check.Formal_Name;
                  Item.Expected_Generic := Check.Expected_Generic;
                  Item.Status := Entry_Status (Check, "", "");
                  Item.Start_Line := Check.Start_Line;
                  Item.End_Line := Check.End_Line;
                  Item.Source_Fingerprint := Check.Fingerprint;
                  Item.Fingerprint := Mix (Check.Fingerprint, Formal_Package_Substitution_Status'Pos (Item.Status));
                  Add_Entry (Result, Item);
               end;
            end if;
         end;
      end loop;

      Result.Result_Fingerprint :=
        Mix (Result.Result_Fingerprint,
             Mix (Result.Substituted_Total,
                  Mix (Result.Boxed_Total,
                       Mix (Result.Mismatch_Total,
                            Mix (Result.Missing_Total,
                                 Mix (Result.Wrong_Generic_Total,
                                      Mix (Result.Unresolved_Total,
                                           Result.Unknown_Total)))))));
      return Result;
   end Build;

   function Substitution_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Substitution_Count;

   function Substitution_At
     (Model : Formal_Package_Substitution_Model;
      Index : Natural) return Formal_Package_Substitution_Info is
   begin
      if Index = 0 or else Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;

      return Model.Entries.Element (Positive (Index));
   end Substitution_At;

   function First_For_Formal
     (Model    : Formal_Package_Substitution_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Formal_Package_Substitution_Info is
   begin
      for Item of Model.Entries loop
         if Item.Instance = Instance and then Item.Formal = Formal then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Formal;

   function Count_Status
     (Model  : Formal_Package_Substitution_Model;
      Status : Formal_Package_Substitution_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Item of Model.Entries loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Substituted_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Substituted_Total;
   end Substituted_Count;

   function Boxed_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Boxed_Total;
   end Boxed_Count;

   function Mismatch_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Mismatch_Total;
   end Mismatch_Count;

   function Missing_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Missing_Total;
   end Missing_Count;

   function Wrong_Generic_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Wrong_Generic_Total;
   end Wrong_Generic_Count;

   function Unresolved_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Unknown_Count (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Fingerprint (Model : Formal_Package_Substitution_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Formal_Package_Substitutions;
