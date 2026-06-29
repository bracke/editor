with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Lookup_Integration is

   pragma Suppress (Overflow_Check);

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Normalize;

   function Mix (A, B : Natural) return Natural is
   begin
      return Natural
        ((Long_Long_Integer (A) * 191 + Long_Long_Integer (B) + 127)
         mod 1_000_000_007);
   end Mix;

   procedure Mix_Text (Value : in out Natural; Text : String) is
   begin
      for Ch of Text loop
         Value := Mix (Value, Character'Pos (Ch));
      end loop;
   end Mix_Text;

   function Status_For
     (Info : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info)
      return Cross_Unit_Lookup_Status is
   begin
      case Info.Status is
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Visible =>
            return Cross_Unit_Lookup_With_Visible;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Use_Package_Visible =>
            return Cross_Unit_Lookup_Use_Visible;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Limited_View =>
            return Cross_Unit_Lookup_Limited_Incomplete_View;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Private_View =>
            return Cross_Unit_Lookup_Private_View;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Missing =>
            return Cross_Unit_Lookup_Missing;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous =>
            return Cross_Unit_Lookup_Ambiguous;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Overflow =>
            return Cross_Unit_Lookup_Overflow;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Not_Found =>
            return Cross_Unit_Lookup_Not_Found;
      end case;
   end Status_For;

   function Is_Visible (Status : Cross_Unit_Lookup_Status) return Boolean is
   begin
      return Status = Cross_Unit_Lookup_With_Visible
        or else Status = Cross_Unit_Lookup_Use_Visible
        or else Status = Cross_Unit_Lookup_Limited_Incomplete_View
        or else Status = Cross_Unit_Lookup_Private_View;
   end Is_Visible;

   function Make_Entry
     (Id   : Cross_Unit_Lookup_Id;
      Info : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info)
      return Cross_Unit_Lookup_Entry
   is
      Feed_Item : Cross_Unit_Lookup_Entry;
      FP    : Natural := 31;
      Name  : constant String := To_String (Info.Clause_Name);
   begin
      Feed_Item.Id := Id;
      Feed_Item.Status := Status_For (Info);
      Feed_Item.Source_Unit_Name := Info.Source_Unit_Name;
      Feed_Item.Lookup_Name := Info.Clause_Name;
      Feed_Item.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Feed_Item.Target_Unit_Name := Info.Target_Unit_Name;
      Feed_Item.Target_Path := Info.Target_Path;
      Feed_Item.Is_With := Info.Is_With;
      Feed_Item.Is_Use := Info.Is_Use;
      Feed_Item.Is_Limited := Info.Is_Limited;
      Feed_Item.Is_Private := Info.Is_Private;
      Feed_Item.Candidate_Count := Info.Candidate_Count;
      Feed_Item.Source_Fingerprint := Info.Fingerprint;

      FP := Mix (FP, Cross_Unit_Lookup_Status'Pos (Feed_Item.Status));
      Mix_Text (FP, To_String (Feed_Item.Source_Unit_Name));
      Mix_Text (FP, To_String (Feed_Item.Lookup_Name));
      Mix_Text (FP, To_String (Feed_Item.Target_Unit_Name));
      Mix_Text (FP, To_String (Feed_Item.Target_Path));
      FP := Mix (FP, Boolean'Pos (Feed_Item.Is_With));
      FP := Mix (FP, Boolean'Pos (Feed_Item.Is_Use));
      FP := Mix (FP, Boolean'Pos (Feed_Item.Is_Limited));
      FP := Mix (FP, Boolean'Pos (Feed_Item.Is_Private));
      FP := Mix (FP, Feed_Item.Candidate_Count);
      FP := Mix (FP, Feed_Item.Source_Fingerprint);
      Feed_Item.Fingerprint := FP;
      return Feed_Item;
   end Make_Entry;

   function Status_For_Child
     (Info : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info)
      return Cross_Unit_Lookup_Status is
   begin
      case Info.Status is
         when Editor.Ada_Child_Unit_Visibility.Child_Visibility_Public_Child_Visible |
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Visible_In_Private_Context |
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Visible_In_Body_Context =>
            return Cross_Unit_Lookup_With_Visible;
         when Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Hidden =>
            return Cross_Unit_Lookup_Private_View;
         when Editor.Ada_Child_Unit_Visibility.Child_Visibility_Missing_Parent |
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Parent_Role_Mismatch =>
            return Cross_Unit_Lookup_Missing;
         when Editor.Ada_Child_Unit_Visibility.Child_Visibility_Ambiguous_Parent =>
            return Cross_Unit_Lookup_Ambiguous;
         when Editor.Ada_Child_Unit_Visibility.Child_Visibility_Overflow =>
            return Cross_Unit_Lookup_Overflow;
         when Editor.Ada_Child_Unit_Visibility.Child_Visibility_Not_Found =>
            return Cross_Unit_Lookup_Not_Found;
      end case;
   end Status_For_Child;

   function Make_Child_Entry
     (Id      : Cross_Unit_Lookup_Id;
      Info    : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info;
      Context : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context)
      return Cross_Unit_Lookup_Entry
   is
      Feed_Item : Cross_Unit_Lookup_Entry;
      FP        : Natural := 37;
   begin
      Feed_Item.Id := Id;
      Feed_Item.Status := Status_For_Child (Info);
      Feed_Item.Source_Unit_Name := Info.Parent_Unit_Name;
      Feed_Item.Lookup_Name := Info.Child_Unit_Name;
      Feed_Item.Normalized_Name :=
        To_Unbounded_String (Normalize (To_String (Info.Child_Unit_Name)));
      Feed_Item.Target_Unit_Name := Info.Child_Unit_Name;
      Feed_Item.Target_Path := Info.Child_Path;
      Feed_Item.Is_With := True;
      Feed_Item.Is_Private := Info.Is_Private_Child;
      Feed_Item.Candidate_Count := Info.Candidate_Count;
      Feed_Item.Source_Fingerprint := Info.Fingerprint;

      FP := Mix (FP, Cross_Unit_Lookup_Status'Pos (Feed_Item.Status));
      FP := Mix
        (FP, Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context'Pos (Context));
      Mix_Text (FP, To_String (Feed_Item.Source_Unit_Name));
      Mix_Text (FP, To_String (Feed_Item.Lookup_Name));
      Mix_Text (FP, To_String (Feed_Item.Target_Unit_Name));
      Mix_Text (FP, To_String (Feed_Item.Target_Path));
      FP := Mix (FP, Boolean'Pos (Feed_Item.Is_With));
      FP := Mix (FP, Boolean'Pos (Feed_Item.Is_Private));
      FP := Mix (FP, Feed_Item.Candidate_Count);
      FP := Mix (FP, Feed_Item.Source_Fingerprint);
      Feed_Item.Fingerprint := FP;
      return Feed_Item;
   end Make_Child_Entry;

   function Same_Candidate
     (Left  : Cross_Unit_Lookup_Entry;
      Right : Cross_Unit_Lookup_Entry) return Boolean is
   begin
      return Left.Status = Right.Status
        and then Normalize (To_String (Left.Target_Unit_Name)) =
          Normalize (To_String (Right.Target_Unit_Name))
        and then Normalize (To_String (Left.Target_Path)) =
          Normalize (To_String (Right.Target_Path));
   end Same_Candidate;

   procedure Add_Entry
     (Model : in out Cross_Unit_Lookup_Model;
      Feed_Item : Cross_Unit_Lookup_Entry) is
   begin
      if Feed_Item.Status = Cross_Unit_Lookup_Not_Found then
         return;
      end if;

      for Existing of Model.Entries loop
         if Same_Candidate (Existing, Feed_Item) then
            return;
         end if;
      end loop;

      Model.Entries.Append (Feed_Item);
      if Is_Visible (Feed_Item.Status) then
         Model.Visible_Total := Model.Visible_Total + 1;
      end if;

      case Feed_Item.Status is
         when Cross_Unit_Lookup_With_Visible =>
            Model.With_Total := Model.With_Total + 1;
         when Cross_Unit_Lookup_Use_Visible =>
            Model.Use_Total := Model.Use_Total + 1;
         when Cross_Unit_Lookup_Limited_Incomplete_View =>
            Model.Limited_Total := Model.Limited_Total + 1;
         when Cross_Unit_Lookup_Private_View =>
            Model.Private_Total := Model.Private_Total + 1;
         when Cross_Unit_Lookup_Missing =>
            Model.Missing_Total := Model.Missing_Total + 1;
         when Cross_Unit_Lookup_Ambiguous =>
            Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
         when Cross_Unit_Lookup_Overflow =>
            Model.Overflow_Total := Model.Overflow_Total + 1;
         when others =>
            null;
      end case;

      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
   end Add_Entry;

   function Empty_Result
     (Model  : Cross_Unit_Lookup_Model;
      Name   : String;
      Status : Cross_Unit_Lookup_Status := Cross_Unit_Lookup_Not_Found)
      return Cross_Unit_Lookup_Entry
   is
      Feed_Item : Cross_Unit_Lookup_Entry;
      FP    : Natural := 43;
   begin
      Feed_Item.Status := Status;
      Feed_Item.Source_Unit_Name := Model.Source_Name;
      Feed_Item.Lookup_Name := To_Unbounded_String (Name);
      Feed_Item.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Mix_Text (FP, To_String (Feed_Item.Source_Unit_Name));
      Mix_Text (FP, Name);
      FP := Mix (FP, Cross_Unit_Lookup_Status'Pos (Status));
      Feed_Item.Fingerprint := FP;
      return Feed_Item;
   end Empty_Result;

   procedure Clear (Model : in out Cross_Unit_Lookup_Model) is
   begin
      Model.Source_Name := Null_Unbounded_String;
      Model.Entries.Clear;
      Model.Visible_Total := 0;
      Model.With_Total := 0;
      Model.Use_Total := 0;
      Model.Limited_Total := 0;
      Model.Private_Total := 0;
      Model.Missing_Total := 0;
      Model.Ambiguous_Total := 0;
      Model.Overflow_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Visibility       : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Source_Unit_Name : String) return Cross_Unit_Lookup_Model
   is
      Model : Cross_Unit_Lookup_Model;
      Source : constant String := Normalize (Source_Unit_Name);
   begin
      Model.Source_Name := To_Unbounded_String (Source_Unit_Name);
      Model.Result_Fingerprint := Mix
        (Editor.Ada_Cross_Unit_Visibility.Fingerprint (Visibility), Source'Length + 1);
      Mix_Text (Model.Result_Fingerprint, Source);

      for I in 1 .. Editor.Ada_Cross_Unit_Visibility.Visibility_Count (Visibility) loop
         declare
            Info : constant Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info :=
              Editor.Ada_Cross_Unit_Visibility.Visibility_At (Visibility, I);
         begin
            if Normalize (To_String (Info.Source_Unit_Name)) = Source then
               Add_Entry (Model, Make_Entry (Cross_Unit_Lookup_Id (Natural (Model.Entries.Length) + 1), Info));
            end if;
         end;
      end loop;

      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Lookup_Count (Model) + 1);
      return Model;
   end Build;

   function Build_With_Children
     (Visibility       : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Children         : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Source_Unit_Name : String;
      Child_Context    : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context :=
        Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context_External_Client)
      return Cross_Unit_Lookup_Model
   is
      Model  : Cross_Unit_Lookup_Model := Build (Visibility, Source_Unit_Name);
      Source : constant String := Normalize (Source_Unit_Name);
   begin
      for I in 1 .. Editor.Ada_Child_Unit_Visibility.Visibility_Count (Children) loop
         declare
            Raw : constant Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info :=
              Editor.Ada_Child_Unit_Visibility.Visibility_At (Children, I);
            Info : constant Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info :=
              Editor.Ada_Child_Unit_Visibility.Lookup_Child
                (Children,
                 To_String (Raw.Parent_Unit_Name),
                 To_String (Raw.Child_Unit_Name),
                 Child_Context);
         begin
            if Normalize (To_String (Info.Parent_Unit_Name)) = Source then
               Add_Entry
                 (Model,
                  Make_Child_Entry
                    (Cross_Unit_Lookup_Id (Natural (Model.Entries.Length) + 1),
                     Info,
                     Child_Context));
            end if;
         end;
      end loop;

      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Editor.Ada_Child_Unit_Visibility.Fingerprint (Children));
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Editor.Ada_Child_Unit_Visibility.Child_Visibility_Context'Pos (Child_Context) + 1);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Lookup_Count (Model) + 1);
      return Model;
   end Build_With_Children;

   function Lookup_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Lookup_Count;

   function Lookup_At
     (Model : Cross_Unit_Lookup_Model;
      Index : Positive) return Cross_Unit_Lookup_Entry is
   begin
      return Model.Entries.Element (Index);
   end Lookup_At;

   function Lookup_Name
     (Model : Cross_Unit_Lookup_Model;
      Name  : String) return Cross_Unit_Lookup_Entry
   is
      Target : constant String := Normalize (Name);
      Found  : Cross_Unit_Lookup_Entry;
      Count  : Natural := 0;
   begin
      for Feed_Item of Model.Entries loop
         if To_String (Feed_Item.Normalized_Name) = Target
           or else Normalize (To_String (Feed_Item.Target_Unit_Name)) = Target
         then
            if Count = 0 then
               Count := 1;
               Found := Feed_Item;
            elsif not Same_Candidate (Found, Feed_Item) then
               Count := Count + 1;
            end if;
         end if;
      end loop;

      if Count = 0 then
         return Empty_Result (Model, Name);
      elsif Count > 1 then
         Found.Status := Cross_Unit_Lookup_Ambiguous;
         Found.Candidate_Count := Count;
         Found.Fingerprint := Mix (Found.Fingerprint, Count);
      end if;

      return Found;
   end Lookup_Name;

   function Resolve_With_Local
     (Model : Cross_Unit_Lookup_Model;
      Local : Editor.Ada_Direct_Visibility.Lookup_Result;
      Name  : String) return Cross_Unit_Lookup_Entry
   is
      Result : Cross_Unit_Lookup_Entry;
   begin
      case Local.Status is
         when Editor.Ada_Direct_Visibility.Lookup_Found =>
            Result := Empty_Result (Model, Name, Cross_Unit_Lookup_Local_Found);
            Result.Candidate_Count := Local.Match_Count;
            return Result;
         when Editor.Ada_Direct_Visibility.Lookup_Ambiguous =>
            Result := Empty_Result (Model, Name, Cross_Unit_Lookup_Local_Ambiguous);
            Result.Candidate_Count := Local.Match_Count;
            return Result;
         when Editor.Ada_Direct_Visibility.Lookup_Not_Found =>
            return Lookup_Name (Model, Name);
      end case;
   end Resolve_With_Local;

   function Visible_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Visible_Total;
   end Visible_Count;

   function With_Visible_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.With_Total;
   end With_Visible_Count;

   function Use_Visible_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Use_Total;
   end Use_Visible_Count;

   function Limited_View_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Limited_Total;
   end Limited_View_Count;

   function Private_View_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Private_Total;
   end Private_View_Count;

   function Missing_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Missing_Total;
   end Missing_Count;

   function Ambiguous_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Overflow_Count (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Overflow_Total;
   end Overflow_Count;

   function Fingerprint (Model : Cross_Unit_Lookup_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Lookup_Integration;
