with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Selected_Representation_Targets is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Id;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Normalize;

   procedure Mix (Value : in out Natural; Text : String) is
   begin
      for Ch of Text loop
         Value := (Value * 131 + Character'Pos (Ch)) mod 1_000_000_007;
      end loop;
   end Mix;

   procedure Mix (Value : in out Natural; N : Natural) is
   begin
      Value := (Value * 131 + N) mod 1_000_000_007;
   end Mix;

   function Is_Selected_Target (Target : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Target, ".") /= 0;
   end Is_Selected_Target;

   function Match_Selected
     (Selected_Names : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Target_Name    : String) return Editor.Ada_Selected_Name_Resolution.Selected_Name_Info is
      Normalized : constant String := Normalize (Target_Name);
   begin
      for Index in 1 .. Editor.Ada_Selected_Name_Resolution.Selected_Name_Count (Selected_Names) loop
         declare
            Candidate : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
              Editor.Ada_Selected_Name_Resolution.Selected_Name_At (Selected_Names, Index);
            Candidate_Name : constant String :=
              Normalize (To_String (Candidate.Prefix) & "." & To_String (Candidate.Selector));
         begin
            if Candidate_Name = Normalized then
               return Candidate;
            end if;
         end;
      end loop;

      return (others => <>);
   end Match_Selected;

   function Status_For
     (Representation_Status :
        Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Status;
      Selected_Status       : Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
      Has_Selected          : Boolean) return Selected_Representation_Target_Status is
   begin
      if not Has_Selected then
         return Selected_Representation_Target_Not_Selected;
      end if;

      case Selected_Status is
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Found =>
            return Selected_Representation_Target_Local_Selected_Resolved;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Found =>
            return Selected_Representation_Target_Cross_Unit_Selected_Resolved;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Use_Prefix_Found =>
            return Selected_Representation_Target_Cross_Unit_Use_Selected_Resolved;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Limited_Prefix =>
            return Selected_Representation_Target_Limited_View;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Private_Prefix =>
            return Selected_Representation_Target_Private_View;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Missing
            | Editor.Ada_Selected_Name_Resolution.Selected_Name_Prefix_Not_Found =>
            return Selected_Representation_Target_Prefix_Missing;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Ambiguous
            | Editor.Ada_Selected_Name_Resolution.Selected_Name_Prefix_Ambiguous =>
            return Selected_Representation_Target_Prefix_Ambiguous;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Overflow =>
            return Selected_Representation_Target_Prefix_Overflow;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Selector_Not_Found =>
            return Selected_Representation_Target_Selector_Missing;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Selector_Ambiguous =>
            return Selected_Representation_Target_Selector_Ambiguous;
         when Editor.Ada_Selected_Name_Resolution.Selected_Name_Prefix_Has_No_Region
            | Editor.Ada_Selected_Name_Resolution.Selected_Name_Not_Resolved =>
            null;
      end case;

      case Representation_Status is
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Resolved =>
            return Selected_Representation_Target_Cross_Unit_Selected_Resolved;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Limited_View =>
            return Selected_Representation_Target_Limited_View;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Private_View =>
            return Selected_Representation_Target_Private_View;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Missing =>
            return Selected_Representation_Target_Prefix_Missing;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Ambiguous =>
            return Selected_Representation_Target_Prefix_Ambiguous;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Prefix_Overflow =>
            return Selected_Representation_Target_Prefix_Overflow;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Local_Resolved =>
            return Selected_Representation_Target_Local_Selected_Resolved;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_No_Cross_Unit_Prefix =>
            return Selected_Representation_Target_Not_Selected;
         when Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Unknown =>
            return Selected_Representation_Target_Unresolved;
      end case;
   end Status_For;

   function To_Info
     (Id           : Selected_Representation_Target_Id;
      Target       : Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Info;
      Selected     : Editor.Ada_Selected_Name_Resolution.Selected_Name_Info;
      Has_Selected : Boolean) return Selected_Representation_Target_Info is
      Info : Selected_Representation_Target_Info;
      FP   : Natural := 47;
   begin
      Info.Id := Id;
      Info.Representation_Target := Target;
      Info.Target_Name := Target.Target_Name;
      Info.Prefix_Name := Target.Prefix_Name;
      Info.Selector_Name := Target.Selector_Name;
      Info.Target_Unit_Name := Target.Target_Unit_Name;
      Info.Target_Path := Target.Target_Path;
      Info.Candidate_Count := Target.Candidate_Count;

      if Has_Selected then
         Info.Selected_Name := Selected.Id;
         Info.Selected_Status := Selected.Status;
         if Length (Info.Target_Unit_Name) = 0 then
            Info.Target_Unit_Name := Selected.Cross_Unit_Target;
         end if;
         if Length (Info.Target_Path) = 0 then
            Info.Target_Path := Selected.Cross_Unit_Path;
         end if;
      end if;

      Info.Status := Status_For
        (Target.Status,
         Info.Selected_Status,
         Is_Selected_Target (To_String (Target.Target_Name)));

      Mix (FP, Natural (Info.Id));
      Mix (FP, Selected_Representation_Target_Status'Pos (Info.Status));
      Mix (FP, To_String (Info.Target_Name));
      Mix (FP, To_String (Info.Prefix_Name));
      Mix (FP, To_String (Info.Selector_Name));
      Mix (FP, To_String (Info.Target_Unit_Name));
      Mix (FP, To_String (Info.Target_Path));
      Mix (FP, Natural (Info.Selected_Name));
      Mix (FP, Editor.Ada_Selected_Name_Resolution.Selected_Name_Status'Pos (Info.Selected_Status));
      Mix (FP, Info.Candidate_Count);
      Mix (FP, Target.Fingerprint);
      if Has_Selected then
         Mix (FP, Selected.Fingerprint);
      end if;
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Representation_Targets :
        Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model;
      Selected_Names : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Selected_Representation_Target_Model is
      Model : Selected_Representation_Target_Model;
      FP    : Natural := 53;
   begin
      Mix (FP, Editor.Ada_Cross_Unit_Representation_Targets.Fingerprint (Representation_Targets));
      Mix (FP, Editor.Ada_Selected_Name_Resolution.Fingerprint (Selected_Names));

      for Index in 1 .. Editor.Ada_Cross_Unit_Representation_Targets.Target_Count (Representation_Targets) loop
         declare
            Target : constant Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Info :=
              Editor.Ada_Cross_Unit_Representation_Targets.Target_At (Representation_Targets, Index);
            Selected : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
              Match_Selected (Selected_Names, To_String (Target.Target_Name));
            Info : constant Selected_Representation_Target_Info :=
              To_Info (Selected_Representation_Target_Id (Index), Target, Selected,
                       Selected.Id /= Editor.Ada_Selected_Name_Resolution.No_Selected_Name);
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Target_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Target_Count;

   function Target_At
     (Model : Selected_Representation_Target_Model;
      Index : Positive) return Selected_Representation_Target_Info is
   begin
      return Model.Items.Element (Index);
   end Target_At;

   function First_For_Target
     (Model : Selected_Representation_Target_Model;
      Target_Name : String) return Selected_Representation_Target_Info is
      Normalized : constant String := Normalize (Target_Name);
   begin
      for Info of Model.Items loop
         if Normalize (To_String (Info.Target_Name)) = Normalized then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end First_For_Target;

   function Count_Status
     (Model  : Selected_Representation_Target_Model;
      Status : Selected_Representation_Target_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Resolved_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Local_Selected_Resolved)
        + Count_Status (Model, Selected_Representation_Target_Cross_Unit_Selected_Resolved)
        + Count_Status (Model, Selected_Representation_Target_Cross_Unit_Use_Selected_Resolved);
   end Resolved_Count;

   function Local_Selected_Resolved_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Local_Selected_Resolved);
   end Local_Selected_Resolved_Count;

   function Cross_Unit_Selected_Resolved_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Cross_Unit_Selected_Resolved)
        + Count_Status (Model, Selected_Representation_Target_Cross_Unit_Use_Selected_Resolved);
   end Cross_Unit_Selected_Resolved_Count;

   function Limited_View_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Limited_View);
   end Limited_View_Count;

   function Private_View_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Private_View);
   end Private_View_Count;

   function Missing_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Prefix_Missing);
   end Missing_Count;

   function Ambiguous_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Prefix_Ambiguous);
   end Ambiguous_Count;

   function Selector_Error_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Selector_Missing)
        + Count_Status (Model, Selected_Representation_Target_Selector_Ambiguous);
   end Selector_Error_Count;

   function Not_Selected_Count
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Selected_Representation_Target_Not_Selected);
   end Not_Selected_Count;

   function Fingerprint
     (Model : Selected_Representation_Target_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Selected_Representation_Targets;
