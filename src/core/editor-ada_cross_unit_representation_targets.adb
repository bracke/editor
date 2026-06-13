with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Freezing_Points;

package body Editor.Ada_Cross_Unit_Representation_Targets is

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

   function First_Prefix (Name : String) return String is
      Dot : constant Natural := Ada.Strings.Fixed.Index (Name, ".");
   begin
      if Dot = 0 then
         return "";
      else
         return Name (Name'First .. Dot - 1);
      end if;
   end First_Prefix;

   function First_Selector (Name : String) return String is
      Dot : constant Natural := Ada.Strings.Fixed.Index (Name, ".");
   begin
      if Dot = 0 or else Dot = Name'Last then
         return "";
      else
         return Name (Dot + 1 .. Name'Last);
      end if;
   end First_Selector;

   function Status_For
     (Visibility_Status : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status)
      return Cross_Unit_Representation_Target_Status is
   begin
      case Visibility_Status is
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Visible
            | Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Use_Package_Visible =>
            return Cross_Unit_Representation_Target_Prefix_Resolved;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Limited_View =>
            return Cross_Unit_Representation_Target_Prefix_Limited_View;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Private_View =>
            return Cross_Unit_Representation_Target_Prefix_Private_View;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Missing
            | Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Not_Found =>
            return Cross_Unit_Representation_Target_Prefix_Missing;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous =>
            return Cross_Unit_Representation_Target_Prefix_Ambiguous;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Overflow =>
            return Cross_Unit_Representation_Target_Prefix_Overflow;
      end case;
   end Status_For;

   function To_Info
     (Source_Unit_Name : String;
      Check            : Editor.Ada_Representation_Legality.Representation_Legality_Info;
      Visibility       : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Cross_Unit_Representation_Target_Info is
      use type Editor.Ada_Freezing_Points.Freezable_Id;
      Target_Text : constant String := To_String (Check.Target_Name);
      Prefix      : constant String := First_Prefix (Target_Text);
      Selector    : constant String := First_Selector (Target_Text);
      Info        : Cross_Unit_Representation_Target_Info;
      FP          : Natural := 41;
   begin
      Info.Clause_Node := Check;
      Info.Source_Unit_Name := To_Unbounded_String (Source_Unit_Name);
      Info.Target_Name := Check.Target_Name;
      Info.Normalized_Target := To_Unbounded_String (Normalize (Target_Text));
      Info.Prefix_Name := To_Unbounded_String (Prefix);
      Info.Selector_Name := To_Unbounded_String (Selector);

      if Check.Target /= Editor.Ada_Freezing_Points.No_Freezable then
         Info.Status := Cross_Unit_Representation_Target_Local_Resolved;
      elsif Prefix = "" then
         Info.Status := Cross_Unit_Representation_Target_No_Cross_Unit_Prefix;
      else
         declare
            Visible : constant Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info :=
              Editor.Ada_Cross_Unit_Visibility.Lookup_Visible_Unit
                (Visibility, Source_Unit_Name, Prefix);
         begin
            Info.Visibility_Status := Visible.Status;
            Info.Target_Unit_Name := Visible.Target_Unit_Name;
            Info.Target_Path := Visible.Target_Path;
            Info.Candidate_Count := Visible.Candidate_Count;
            Info.Status := Status_For (Visible.Status);
         end;
      end if;

      Mix (FP, Cross_Unit_Representation_Target_Status'Pos (Info.Status));
      Mix (FP, To_String (Info.Source_Unit_Name));
      Mix (FP, To_String (Info.Target_Name));
      Mix (FP, To_String (Info.Prefix_Name));
      Mix (FP, To_String (Info.Selector_Name));
      Mix (FP, To_String (Info.Target_Unit_Name));
      Mix (FP, To_String (Info.Target_Path));
      Mix (FP, Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status'Pos
             (Info.Visibility_Status));
      Mix (FP, Info.Candidate_Count);
      Mix (FP, Check.Fingerprint);
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Source_Unit_Name : String;
      Legality         : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Visibility       : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Cross_Unit_Representation_Target_Model is
      Model : Cross_Unit_Representation_Target_Model;
      FP    : Natural := 43;
   begin
      Mix (FP, Source_Unit_Name);
      Mix (FP, Editor.Ada_Representation_Legality.Fingerprint (Legality));
      Mix (FP, Editor.Ada_Cross_Unit_Visibility.Fingerprint (Visibility));

      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Check : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
            Info : constant Cross_Unit_Representation_Target_Info :=
              To_Info (Source_Unit_Name, Check, Visibility);
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Target_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Target_Count;

   function Target_At
     (Model : Cross_Unit_Representation_Target_Model;
      Index : Positive) return Cross_Unit_Representation_Target_Info is
   begin
      return Model.Items.Element (Index);
   end Target_At;

   function Count_Status
     (Model  : Cross_Unit_Representation_Target_Model;
      Status : Cross_Unit_Representation_Target_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Prefix_Resolved_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_Prefix_Resolved);
   end Prefix_Resolved_Count;

   function Local_Resolved_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_Local_Resolved);
   end Local_Resolved_Count;

   function Missing_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_Prefix_Missing);
   end Missing_Count;

   function Ambiguous_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_Prefix_Ambiguous);
   end Ambiguous_Count;

   function Limited_View_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_Prefix_Limited_View);
   end Limited_View_Count;

   function Private_View_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_Prefix_Private_View);
   end Private_View_Count;

   function No_Cross_Unit_Prefix_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Representation_Target_No_Cross_Unit_Prefix);
   end No_Cross_Unit_Prefix_Count;

   function Fingerprint
     (Model : Cross_Unit_Representation_Target_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Representation_Targets;
