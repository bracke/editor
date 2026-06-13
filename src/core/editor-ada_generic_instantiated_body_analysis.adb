with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Instantiated_Body_Analysis is

   use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
   use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
   use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id;
   use type Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status;
   use type Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Status;
   use type Editor.Ada_Generic_View_Compatibility.Generic_View_Status;

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

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Status_Fingerprint (Status : Instantiated_Body_Status) return Natural is
   begin
      return Instantiated_Body_Status'Pos (Status) * 1_000_003;
   end Status_Fingerprint;

   function Body_For_Instance
     (Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Instance  : Editor.Ada_Generic_Contracts.Generic_Instance_Info)
      return Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info
   is
      Generic_Name : constant String := To_String (Instance.Normalized_Generic);
   begin
      for Index in 1 .. Editor.Ada_Generic_Contracts.Body_Contract_Visibility_Count (Contracts) loop
         declare
            Body_Info : constant Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info :=
              Editor.Ada_Generic_Contracts.Body_Contract_Visibility_At (Contracts, Index);
         begin
            if To_String (Body_Info.Normalized_Name) = Generic_Name then
               return Body_Info;
            end if;
         end;
      end loop;
      return (others => <>);
   end Body_For_Instance;

   function Classify
     (View  : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info;
      Match : Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info;
      Body_Info  : Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info)
      return Instantiated_Body_Status
   is
   begin
      if Body_Info.Id = Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility
        or else Body_Info.Status /= Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visible
      then
         return Instantiated_Body_No_Body_Contract;
      end if;

      if Match.Status /= Editor.Ada_Generic_Contracts.Generic_Actual_Match_Valid then
         return Instantiated_Body_Contract_Mismatch;
      end if;

      case View.Status is
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Compatible |
              Editor.Ada_Generic_View_Compatibility.Generic_View_No_View_Metadata =>
            if View.Is_Default then
               return Instantiated_Body_Default_Substituted;
            else
               return Instantiated_Body_Substituted;
            end if;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Private_Barrier =>
            return Instantiated_Body_Private_View_Barrier;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Limited_Barrier =>
            return Instantiated_Body_Limited_View_Barrier;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Cross_Unit_Unresolved =>
            return Instantiated_Body_Cross_Unit_Unresolved;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Mismatch =>
            return Instantiated_Body_Object_Mismatch;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Unknown =>
            return Instantiated_Body_Object_Unknown;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Not_Checked =>
            return Instantiated_Body_Unknown;
      end case;
   end Classify;

   procedure Add_Entry
     (Model : in out Instantiated_Body_Model;
      Item  : Instantiated_Body_Substitution_Info) is
   begin
      Model.Entries.Append (Item);
      case Item.Status is
         when Instantiated_Body_Substituted =>
            Model.Substituted_Total := Model.Substituted_Total + 1;
         when Instantiated_Body_Default_Substituted =>
            Model.Default_Substituted_Total := Model.Default_Substituted_Total + 1;
         when Instantiated_Body_Private_View_Barrier =>
            Model.Private_Barrier_Total := Model.Private_Barrier_Total + 1;
         when Instantiated_Body_Limited_View_Barrier =>
            Model.Limited_Barrier_Total := Model.Limited_Barrier_Total + 1;
         when Instantiated_Body_Cross_Unit_Unresolved =>
            Model.Unresolved_Total := Model.Unresolved_Total + 1;
         when Instantiated_Body_Object_Mismatch =>
            Model.Object_Mismatch_Total := Model.Object_Mismatch_Total + 1;
         when Instantiated_Body_Object_Unknown |
              Instantiated_Body_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when Instantiated_Body_No_Body_Contract =>
            Model.Missing_Body_Total := Model.Missing_Body_Total + 1;
         when Instantiated_Body_Contract_Mismatch =>
            Model.Contract_Mismatch_Total := Model.Contract_Mismatch_Total + 1;
         when Instantiated_Body_Not_Checked =>
            null;
      end case;

      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Item.Fingerprint,
                  Mix (Natural (Item.Instance),
                       Mix (Natural (Item.Formal), Status_Fingerprint (Item.Status)))));
   end Add_Entry;

   function Build
     (Contracts     : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model)
      return Instantiated_Body_Model
   is
      Model : Instantiated_Body_Model;
   begin
      for Index in 1 .. Editor.Ada_Generic_View_Compatibility.Entry_Count (Generic_Views) loop
         declare
            View : constant Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info :=
              Editor.Ada_Generic_View_Compatibility.Entry_At (Generic_Views, Index);
            Instance : constant Editor.Ada_Generic_Contracts.Generic_Instance_Info :=
              Editor.Ada_Generic_Contracts.Instance (Contracts, View.Instance);
            Match : constant Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info :=
              Editor.Ada_Generic_Contracts.Actual_Match_For_Instance (Contracts, View.Instance);
            Body_Info : constant Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info :=
              Body_For_Instance (Contracts, Instance);
            Item : Instantiated_Body_Substitution_Info;
         begin
            Item.Id := Instantiated_Body_Substitution_Id (Natural (Model.Entries.Length) + 1);
            Item.Instance := View.Instance;
            Item.Formal := View.Formal;
            Item.Body_Contract := Body_Info.Id;
            Item.Instance_Node := View.Instance_Node;
            Item.Formal_Node := View.Formal_Node;
            Item.Body_Node := Body_Info.Body_Node;
            Item.Body_Region := Body_Info.Body_Region;
            Item.Formal_Name := View.Formal_Name;
            Item.Formal_Subtype := View.Formal_Subtype;
            Item.Actual_Text := View.Expression_Text;
            Item.Is_Default := View.Is_Default;
            Item.Actual_Match_Status := Match.Status;
            Item.Generic_View := View.Id;
            Item.Generic_View_Status := View.Status;
            Item.Cross_Unit_Target := View.Cross_Unit_Target;
            Item.Cross_Unit_Selector := View.Cross_Unit_Selector;
            Item.Status := Classify (View, Match, Body_Info);
            Item.Start_Line := View.Start_Line;
            Item.End_Line := View.End_Line;
            Item.Fingerprint :=
              Mix (View.Fingerprint,
                   Mix (Body_Info.Fingerprint,
                        Mix (Match.Fingerprint,
                             Mix (Hash_Text (To_String (View.Formal_Name)),
                                  Mix (Hash_Text (To_String (View.Expression_Text)),
                                       Status_Fingerprint (Item.Status))))));
            Add_Entry (Model, Item);
         end;
      end loop;

      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Editor.Ada_Generic_Contracts.Fingerprint (Contracts),
                  Mix (Editor.Ada_Generic_View_Compatibility.Fingerprint (Generic_Views),
                       Mix (Model.Substituted_Total,
                            Mix (Model.Default_Substituted_Total,
                                 Mix (Model.Private_Barrier_Total,
                                      Mix (Model.Limited_Barrier_Total,
                                           Mix (Model.Unresolved_Total,
                                                Mix (Model.Object_Mismatch_Total,
                                                     Mix (Model.Unknown_Total,
                                                          Mix (Model.Missing_Body_Total,
                                                               Model.Contract_Mismatch_Total)))))))))));
      return Model;
   end Build;

   function Substitution_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Substitution_Count;

   function Substitution_At
     (Model : Instantiated_Body_Model;
      Index : Positive) return Instantiated_Body_Substitution_Info is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Substitution_At;

   function First_For_Formal
     (Model    : Instantiated_Body_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Instantiated_Body_Substitution_Info is
   begin
      for Item of Model.Entries loop
         if Item.Instance = Instance and then Item.Formal = Formal then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Formal;

   function Count_Status
     (Model  : Instantiated_Body_Model;
      Status : Instantiated_Body_Status) return Natural
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

   function Substituted_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Substituted_Total;
   end Substituted_Count;

   function Default_Substituted_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Default_Substituted_Total;
   end Default_Substituted_Count;

   function Private_Barrier_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Private_Barrier_Total;
   end Private_Barrier_Count;

   function Limited_Barrier_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Limited_Barrier_Total;
   end Limited_Barrier_Count;

   function Unresolved_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Object_Mismatch_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Object_Mismatch_Total;
   end Object_Mismatch_Count;

   function Unknown_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function Missing_Body_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Missing_Body_Total;
   end Missing_Body_Count;

   function Contract_Mismatch_Count (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Contract_Mismatch_Total;
   end Contract_Mismatch_Count;

   function Fingerprint (Model : Instantiated_Body_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Instantiated_Body_Analysis;
