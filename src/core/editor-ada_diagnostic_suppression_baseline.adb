with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Suppression_Baseline is

   use type Feed_Source;
   use type Feed_Severity;
   use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 223) + B + 191) mod 1_000_000_007;
   end Mix;

   function Source_Slot (Source : Feed_Source) return Natural is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return 2;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return 3;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return 4;
      end case;
   end Source_Slot;

   function Severity_Slot (Severity : Feed_Severity) return Natural is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return 3;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return 2;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return 1;
      end case;
   end Severity_Slot;

   function Rule_Slot (Kind : Diagnostic_Suppression_Rule_Kind) return Natural is
   begin
      case Kind is
         when Diagnostic_Suppression_No_Rule =>
            return 0;
         when Diagnostic_Suppression_By_Index_Id =>
            return 1;
         when Diagnostic_Suppression_By_Source =>
            return 2;
         when Diagnostic_Suppression_By_Severity =>
            return 3;
         when Diagnostic_Baseline_By_Diagnostic_Fingerprint =>
            return 4;
         when Diagnostic_Baseline_By_Source_And_Severity =>
            return 5;
      end case;
   end Rule_Slot;

   function Status_Slot (Status : Diagnostic_Suppression_Entry_Status) return Natural is
   begin
      case Status is
         when Diagnostic_Suppression_Entry_Active =>
            return 1;
         when Diagnostic_Suppression_Entry_Suppressed =>
            return 2;
         when Diagnostic_Suppression_Entry_Baselined =>
            return 3;
         when Diagnostic_Suppression_Entry_Rejected_Stale =>
            return 4;
      end case;
   end Status_Slot;

   function Rule_Fingerprint (Rule : Diagnostic_Suppression_Rule) return Natural is
   begin
      return Mix
        (Natural (Rule.Id) + 1,
         Mix
           (Rule_Slot (Rule.Kind),
            Mix
              (Natural (Rule.Index_Id) + 1,
               Mix
                 (Severity_Slot (Rule.Severity),
                  Mix
                    (Source_Slot (Rule.Source),
                     Rule.Diagnostic_Fingerprint + Length (Rule.Reason) + 1)))));
   end Rule_Fingerprint;

   function Matches
     (Rule  : Diagnostic_Suppression_Rule;
      Feed_Item : Index_Entry) return Boolean is
   begin
      case Rule.Kind is
         when Diagnostic_Suppression_No_Rule =>
            return False;
         when Diagnostic_Suppression_By_Index_Id =>
            return Feed_Item.Id = Rule.Index_Id;
         when Diagnostic_Suppression_By_Source =>
            return Feed_Item.Diagnostic.Source = Rule.Source;
         when Diagnostic_Suppression_By_Severity =>
            return Feed_Item.Diagnostic.Severity = Rule.Severity;
         when Diagnostic_Baseline_By_Diagnostic_Fingerprint =>
            return Feed_Item.Diagnostic.Fingerprint = Rule.Diagnostic_Fingerprint;
         when Diagnostic_Baseline_By_Source_And_Severity =>
            return Feed_Item.Diagnostic.Source = Rule.Source
              and then Feed_Item.Diagnostic.Severity = Rule.Severity;
      end case;
   end Matches;

   function Applied_Status
     (Rule : Diagnostic_Suppression_Rule) return Diagnostic_Suppression_Entry_Status is
   begin
      case Rule.Kind is
         when Diagnostic_Baseline_By_Diagnostic_Fingerprint |
              Diagnostic_Baseline_By_Source_And_Severity =>
            return Diagnostic_Suppression_Entry_Baselined;
         when Diagnostic_Suppression_By_Index_Id |
              Diagnostic_Suppression_By_Source |
              Diagnostic_Suppression_By_Severity =>
            return Diagnostic_Suppression_Entry_Suppressed;
         when Diagnostic_Suppression_No_Rule =>
            return Diagnostic_Suppression_Entry_Active;
      end case;
   end Applied_Status;

   function First_Matching_Rule
     (Rules : Diagnostic_Suppression_Rule_Set;
      Feed_Item : Index_Entry) return Diagnostic_Suppression_Rule is
   begin
      for Position in 1 .. Natural (Rules.Rules.Length) loop
         declare
            Rule : constant Diagnostic_Suppression_Rule := Rules.Rules.Element (Position);
         begin
            if Matches (Rule, Feed_Item) then
               return Rule;
            end if;
         end;
      end loop;

      return (others => <>);
   end First_Matching_Rule;

   function Make_Entry
     (Feed_Item : Index_Entry;
      Id    : Diagnostic_Suppression_Entry_Id;
      Rule  : Diagnostic_Suppression_Rule) return Diagnostic_Suppression_Entry
   is
      Result : Diagnostic_Suppression_Entry;
   begin
      Result.Id := Id;
      Result.Index_Id := Feed_Item.Id;
      Result.Feed_Index := Feed_Item.Feed_Index;
      Result.Diagnostic := Feed_Item.Diagnostic;
      Result.Severity := Feed_Item.Diagnostic.Severity;
      Result.Source := Feed_Item.Diagnostic.Source;
      Result.Token := Feed_Item.Diagnostic.Token;
      Result.Node := Feed_Item.Diagnostic.Node;
      Result.Start_Line := Feed_Item.Diagnostic.Start_Line;
      Result.Start_Column := Feed_Item.Diagnostic.Start_Column;
      Result.End_Line := Feed_Item.Diagnostic.End_Line;
      Result.End_Column := Feed_Item.Diagnostic.End_Column;
      Result.Source_Fingerprint := Feed_Item.Diagnostic.Source_Fingerprint;
      Result.Diagnostic_Fingerprint := Feed_Item.Diagnostic.Fingerprint;

      if Rule.Id /= No_Diagnostic_Suppression_Rule then
         Result.Status := Applied_Status (Rule);
         Result.Applied_Rule := Rule.Id;
         Result.Applied_Rule_Kind := Rule.Kind;
         Result.Reason := Rule.Reason;
      end if;

      Result.Fingerprint := Mix
        (Natural (Result.Id) + 1,
         Mix
           (Natural (Result.Index_Id) + 1,
            Mix
              (Result.Feed_Index + 1,
               Mix
                 (Status_Slot (Result.Status),
                  Mix
                    (Rule_Slot (Result.Applied_Rule_Kind),
                     Mix
                       (Result.Diagnostic_Fingerprint + 1,
                        Mix
                          (Result.Source_Fingerprint + 1,
                           Mix (Severity_Slot (Result.Severity), Source_Slot (Result.Source)))))))));
      return Result;
   end Make_Entry;

   procedure Append_Entry
     (Model : in out Diagnostic_Suppression_Model;
      Feed_Item : Diagnostic_Suppression_Entry) is
   begin
      if Feed_Item.Id = No_Diagnostic_Suppression_Entry then
         return;
      end if;

      Model.Entries.Append (Feed_Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);

      case Feed_Item.Status is
         when Diagnostic_Suppression_Entry_Active =>
            Model.Active_Total := Model.Active_Total + 1;
         when Diagnostic_Suppression_Entry_Suppressed =>
            Model.Suppressed_Total := Model.Suppressed_Total + 1;
         when Diagnostic_Suppression_Entry_Baselined =>
            Model.Baselined_Total := Model.Baselined_Total + 1;
         when Diagnostic_Suppression_Entry_Rejected_Stale =>
            Model.Rejected_Total := Model.Rejected_Total + 1;
      end case;

      case Feed_Item.Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      case Feed_Item.Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            Model.Expression_Total := Model.Expression_Total + 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            Model.Representation_Total := Model.Representation_Total + 1;
      end case;
   end Append_Entry;

   procedure Clear_Rules (Rules : in out Diagnostic_Suppression_Rule_Set) is
   begin
      Rules.Rules.Clear;
      Rules.Next_Id := 1;
      Rules.Fingerprint := 0;
   end Clear_Rules;

   procedure Add_Rule
     (Rules : in out Diagnostic_Suppression_Rule_Set;
      Rule  : Diagnostic_Suppression_Rule)
   is
      Stored : Diagnostic_Suppression_Rule := Rule;
   begin
      if Stored.Kind = Diagnostic_Suppression_No_Rule then
         return;
      end if;

      if Stored.Id = No_Diagnostic_Suppression_Rule then
         Stored.Id := Rules.Next_Id;
         Rules.Next_Id := Rules.Next_Id + 1;
      elsif Stored.Id >= Rules.Next_Id then
         Rules.Next_Id := Stored.Id + 1;
      end if;

      Stored.Fingerprint := Rule_Fingerprint (Stored);
      Rules.Rules.Append (Stored);
      Rules.Fingerprint := Mix (Rules.Fingerprint, Stored.Fingerprint);
   end Add_Rule;

   function Make_Rule
     (Kind        : Diagnostic_Suppression_Rule_Kind;
      Reason      : String := "";
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Diagnostic_Fingerprint : Natural := 0) return Diagnostic_Suppression_Rule
   is
      Rule : Diagnostic_Suppression_Rule;
   begin
      Rule.Kind := Kind;
      Rule.Index_Id := Index_Id;
      Rule.Severity := Severity;
      Rule.Source := Source;
      Rule.Diagnostic_Fingerprint := Diagnostic_Fingerprint;
      Rule.Reason := To_Unbounded_String (Reason);
      Rule.Fingerprint := Rule_Fingerprint (Rule);
      return Rule;
   end Make_Rule;

   function Rule_Count (Rules : Diagnostic_Suppression_Rule_Set) return Natural is
   begin
      return Natural (Rules.Rules.Length);
   end Rule_Count;

   function Rule_At
     (Rules : Diagnostic_Suppression_Rule_Set;
      Index : Positive) return Diagnostic_Suppression_Rule is
   begin
      if Index > Natural (Rules.Rules.Length) then
         return (others => <>);
      end if;

      return Rules.Rules.Element (Index);
   end Rule_At;

   function Rule_Set_Fingerprint (Rules : Diagnostic_Suppression_Rule_Set) return Natural is
   begin
      return Rules.Fingerprint;
   end Rule_Set_Fingerprint;

   procedure Clear (Model : in out Diagnostic_Suppression_Model) is
   begin
      Model.Model_Status := Diagnostic_Suppression_Current;
      Model.Entries.Clear;
      Model.Active_Total := 0;
      Model.Suppressed_Total := 0;
      Model.Baselined_Total := 0;
      Model.Rejected_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Expression_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.Rule_Fingerprint := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Rules : Diagnostic_Suppression_Rule_Set) return Diagnostic_Suppression_Model
   is
      Model : Diagnostic_Suppression_Model;
      Next_Id : Diagnostic_Suppression_Entry_Id := 1;
   begin
      Model.Rule_Fingerprint := Rules.Fingerprint;

      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Model_Status := Diagnostic_Suppression_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Index);
         Model.Result_Fingerprint := Mix
           (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
            Mix (Rules.Fingerprint, Model.Rejected_Total + 1));
         return Model;
      end if;

      Model.Result_Fingerprint := Mix
        (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index), Rules.Fingerprint);

      for Position in 1 .. Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) loop
         declare
            Indexed : constant Index_Entry :=
              Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position);
            Rule : constant Diagnostic_Suppression_Rule :=
              First_Matching_Rule (Rules, Indexed);
         begin
            Append_Entry (Model, Make_Entry (Indexed, Next_Id, Rule));
            Next_Id := Next_Id + 1;
         end;
      end loop;

      return Model;
   end Build;

   function Status (Model : Diagnostic_Suppression_Model) return Diagnostic_Suppression_Model_Status is
   begin
      return Model.Model_Status;
   end Status;

   function Current (Model : Diagnostic_Suppression_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Suppression_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Suppression_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Suppression_Rejected_Stale;
   end Rejected_Stale;

   function Entry_Count (Model : Diagnostic_Suppression_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Diagnostic_Suppression_Model;
      Index : Positive) return Diagnostic_Suppression_Entry is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;

      return Model.Entries.Element (Index);
   end Entry_At;

   function Active_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural is
   begin
      return Model.Active_Total;
   end Active_Entry_Count;

   function Suppressed_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural is
   begin
      return Model.Suppressed_Total;
   end Suppressed_Entry_Count;

   function Baselined_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural is
   begin
      return Model.Baselined_Total;
   end Baselined_Entry_Count;

   function Rejected_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Entry_Count;

   function Count_Status
     (Model  : Diagnostic_Suppression_Model;
      Status : Diagnostic_Suppression_Entry_Status) return Natural is
   begin
      case Status is
         when Diagnostic_Suppression_Entry_Active =>
            return Model.Active_Total;
         when Diagnostic_Suppression_Entry_Suppressed =>
            return Model.Suppressed_Total;
         when Diagnostic_Suppression_Entry_Baselined =>
            return Model.Baselined_Total;
         when Diagnostic_Suppression_Entry_Rejected_Stale =>
            return Model.Rejected_Total;
      end case;
   end Count_Status;

   function Count_Source
     (Model  : Diagnostic_Suppression_Model;
      Source : Feed_Source) return Natural is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return Model.Expression_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return Model.Generic_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return Model.Cross_Unit_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return Model.Representation_Total;
      end case;
   end Count_Source;

   function Count_Severity
     (Model    : Diagnostic_Suppression_Model;
      Severity : Feed_Severity) return Natural is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return Model.Error_Total;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return Model.Warning_Total;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return Model.Info_Total;
      end case;
   end Count_Severity;

   function First_For_Diagnostic
     (Model    : Diagnostic_Suppression_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Suppression_Entry is
   begin
      for Position in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Diagnostic_Suppression_Entry := Model.Entries.Element (Position);
         begin
            if Feed_Item.Index_Id = Index_Id then
               return Feed_Item;
            end if;
         end;
      end loop;

      return (others => <>);
   end First_For_Diagnostic;

   function Entries_For_Status
     (Model  : Diagnostic_Suppression_Model;
      Status : Diagnostic_Suppression_Entry_Status) return Diagnostic_Suppression_Result_Set
   is
      Results : Diagnostic_Suppression_Result_Set;
   begin
      for Position in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Diagnostic_Suppression_Entry := Model.Entries.Element (Position);
         begin
            if Feed_Item.Status = Status then
               Results.Entries.Append (Feed_Item);
               Results.Fingerprint := Mix (Results.Fingerprint, Feed_Item.Fingerprint);
            end if;
         end;
      end loop;

      return Results;
   end Entries_For_Status;

   function Result_Count (Results : Diagnostic_Suppression_Result_Set) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Result_Count;

   function Result_At
     (Results : Diagnostic_Suppression_Result_Set;
      Index   : Positive) return Diagnostic_Suppression_Entry is
   begin
      if Index > Natural (Results.Entries.Length) then
         return (others => <>);
      end if;

      return Results.Entries.Element (Index);
   end Result_At;

   function Has_Entry (Feed_Item : Diagnostic_Suppression_Entry) return Boolean is
   begin
      return Feed_Item.Id /= No_Diagnostic_Suppression_Entry;
   end Has_Entry;

   function Fingerprint (Model : Diagnostic_Suppression_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Suppression_Baseline;
