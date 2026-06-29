with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_View_Compatibility is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Generic_Contracts.Generic_Formal_Id;
   use type Editor.Ada_Generic_Contracts.Generic_Instance_Id;
   use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id;
   use type Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status;
   use type Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Status;

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

   function Status_Fingerprint (Status : Generic_View_Status) return Natural is
   begin
      return Generic_View_Status'Pos (Status) * 1_000_003;
   end Status_Fingerprint;

   function Is_View_Barrier
     (Status : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status) return Boolean is
   begin
      case Status is
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Partial_View |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View_Hidden |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Incomplete_View |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Full_View_Hidden |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Private_View |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Unresolved =>
            return True;
         when others =>
            return False;
      end case;
   end Is_View_Barrier;

   function Lines_Overlap
     (Left_First  : Positive;
      Left_Last   : Positive;
      Right_First : Positive;
      Right_Last  : Positive) return Boolean is
   begin
      return Left_First <= Right_Last and then Right_First <= Left_Last;
   end Lines_Overlap;

   function Matching_View
     (Check : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Info;
      Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info
   is
      Best : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info := (others => <>);
   begin
      for Index in 1 .. Editor.Ada_View_Aware_Compatibility.Entry_Count (Views) loop
         declare
            Candidate : constant Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info :=
              Editor.Ada_View_Aware_Compatibility.Entry_At (Views, Index);
         begin
            if Lines_Overlap
              (Check.Start_Line, Check.End_Line,
               Candidate.Start_Line, Candidate.End_Line)
            then
               if Is_View_Barrier (Candidate.Status) then
                  return Candidate;
               elsif Best.Id = Editor.Ada_View_Aware_Compatibility.No_View_Compatibility then
                  Best := Candidate;
               end if;
            end if;
         end;
      end loop;
      return Best;
   end Matching_View;

   function Classify
     (Check : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Info;
      View  : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info)
      return Generic_View_Status
   is
   begin
      case View.Status is
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Partial_View |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View_Hidden |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Private_View =>
            return Generic_View_Private_Barrier;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Incomplete_View |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Limited_Full_View_Hidden =>
            return Generic_View_Limited_Barrier;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Cross_Unit_Unresolved =>
            return Generic_View_Cross_Unit_Unresolved;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Compatible |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Private_Full_View =>
            case Check.Status is
               when Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Compatible |
                    Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Compatible =>
                  return Generic_View_Compatible;
               when Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Type_Mismatch |
                    Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Type_Mismatch |
                    Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Static_Range_Error =>
                  return Generic_View_Object_Mismatch;
               when others =>
                  return Generic_View_Object_Unknown;
            end case;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked =>
            case Check.Status is
               when Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Type_Mismatch |
                    Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Type_Mismatch |
                    Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Static_Range_Error =>
                  return Generic_View_Object_Mismatch;
               when Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Compatible |
                    Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Compatible =>
                  return Generic_View_No_View_Metadata;
               when others =>
                  return Generic_View_Object_Unknown;
            end case;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Requires_Explicit_Conversion |
              Editor.Ada_View_Aware_Compatibility.View_Compatibility_Known_Incompatible =>
            return Generic_View_Object_Mismatch;
         when Editor.Ada_View_Aware_Compatibility.View_Compatibility_Indeterminate =>
            return Generic_View_Object_Unknown;
      end case;
   end Classify;

   procedure Add_Entry
     (Model : in out Generic_View_Compatibility_Model;
      Item  : Generic_View_Compatibility_Info) is
   begin
      Model.Entries.Append (Item);
      case Item.Status is
         when Generic_View_Compatible =>
            Model.Compatible_Total := Model.Compatible_Total + 1;
         when Generic_View_Private_Barrier =>
            Model.Private_Barrier_Total := Model.Private_Barrier_Total + 1;
         when Generic_View_Limited_Barrier =>
            Model.Limited_Barrier_Total := Model.Limited_Barrier_Total + 1;
         when Generic_View_Cross_Unit_Unresolved =>
            Model.Unresolved_Total := Model.Unresolved_Total + 1;
         when Generic_View_Object_Mismatch =>
            Model.Object_Mismatch_Total := Model.Object_Mismatch_Total + 1;
         when Generic_View_Object_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when Generic_View_No_View_Metadata =>
            Model.No_View_Metadata_Total := Model.No_View_Metadata_Total + 1;
         when Generic_View_Not_Checked =>
            null;
      end case;

      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Item.Fingerprint,
                  Mix (Natural (Item.Instance),
                       Mix (Natural (Item.Formal), Status_Fingerprint (Item.Status)))));
   end Add_Entry;

   function Build
     (Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Views           : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Generic_View_Compatibility_Model
   is
      Model : Generic_View_Compatibility_Model;
   begin
      for Index in 1 .. Editor.Ada_Generic_Object_Default_Type_Conformance.Check_Count (Object_Defaults) loop
         declare
            Check : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Info :=
              Editor.Ada_Generic_Object_Default_Type_Conformance.Check_At (Object_Defaults, Index);
            View : constant Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info :=
              Matching_View (Check, Views);
            Item : Generic_View_Compatibility_Info;
         begin
            Item.Id := Generic_View_Compatibility_Id (Natural (Model.Entries.Length) + 1);
            Item.Instance := Check.Instance;
            Item.Formal := Check.Formal;
            Item.Instance_Node := Check.Instance_Node;
            Item.Formal_Node := Check.Formal_Node;
            Item.Formal_Name := Check.Formal_Name;
            Item.Formal_Subtype := Check.Formal_Subtype;
            Item.Expression_Text := Check.Expression_Text;
            Item.Is_Default := Check.Is_Default;
            Item.Object_Status := Check.Status;
            Item.View := View.Id;
            Item.View_Status := View.Status;
            Item.Cross_Unit_Target := View.Cross_Unit_Target;
            Item.Cross_Unit_Selector := View.Cross_Unit_Selector;
            Item.Status := Classify (Check, View);
            Item.Start_Line := Check.Start_Line;
            Item.End_Line := Check.End_Line;
            Item.Fingerprint :=
              Mix (Check.Fingerprint,
                   Mix (View.Fingerprint,
                        Mix (Natural (Check.Instance_Node),
                             Mix (Natural (Check.Formal_Node),
                                  Mix (Hash_Text (To_String (Check.Expression_Text)),
                                       Status_Fingerprint (Item.Status))))));
            Add_Entry (Model, Item);
         end;
      end loop;

      if Natural (Model.Entries.Length) = 0 then
         for Index in 1 .. Editor.Ada_View_Aware_Compatibility.Entry_Count (Views) loop
            declare
               View : constant Editor.Ada_View_Aware_Compatibility.View_Compatibility_Info :=
                 Editor.Ada_View_Aware_Compatibility.Entry_At (Views, Index);
               Item : Generic_View_Compatibility_Info;
            begin
               if Is_View_Barrier (View.Status) then
                  Item.Id := Generic_View_Compatibility_Id (Natural (Model.Entries.Length) + 1);
                  Item.View := View.Id;
                  Item.View_Status := View.Status;
                  Item.Cross_Unit_Target := View.Cross_Unit_Target;
                  Item.Cross_Unit_Selector := View.Cross_Unit_Selector;
                  if Length (View.Cross_Unit_Target) /= 0 and then Length (View.Cross_Unit_Selector) /= 0 then
                     Item.Expression_Text := View.Cross_Unit_Target & "." & View.Cross_Unit_Selector;
                  end if;
                  Item.Status := Classify ((others => <>), View);
                  Item.Start_Line := View.Start_Line;
                  Item.End_Line := View.End_Line;
                  Item.Fingerprint :=
                    Mix (View.Fingerprint,
                         Mix (Hash_Text (To_String (Item.Expression_Text)),
                              Status_Fingerprint (Item.Status)));
                  Add_Entry (Model, Item);
               end if;
            end;
         end loop;
      end if;

      Model.Model_Fingerprint :=
        Mix (Model.Model_Fingerprint,
             Mix (Model.Compatible_Total,
                  Mix (Model.Private_Barrier_Total,
                       Mix (Model.Limited_Barrier_Total,
                            Mix (Model.Unresolved_Total,
                                 Mix (Model.Object_Mismatch_Total,
                                      Mix (Model.Unknown_Total,
                                           Model.No_View_Metadata_Total)))))));
      return Model;
   end Build;

   function Entry_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Generic_View_Compatibility_Model;
      Index : Positive) return Generic_View_Compatibility_Info is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function First_For_Formal
     (Model    : Generic_View_Compatibility_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Generic_View_Compatibility_Info is
   begin
      for Item of Model.Entries loop
         if Item.Instance = Instance and then Item.Formal = Formal then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Formal;

   function Count_Status
     (Model  : Generic_View_Compatibility_Model;
      Status : Generic_View_Status) return Natural
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

   function Compatible_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Compatible_Total;
   end Compatible_Count;

   function Private_Barrier_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Private_Barrier_Total;
   end Private_Barrier_Count;

   function Limited_Barrier_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Limited_Barrier_Total;
   end Limited_Barrier_Count;

   function Unresolved_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Unresolved_Total;
   end Unresolved_Count;

   function Object_Mismatch_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Object_Mismatch_Total;
   end Object_Mismatch_Count;

   function Unknown_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Count;

   function No_View_Metadata_Count (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.No_View_Metadata_Total;
   end No_View_Metadata_Count;

   function Fingerprint (Model : Generic_View_Compatibility_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_View_Compatibility;
