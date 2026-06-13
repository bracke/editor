with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Limited_View_Rules is

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

   function Status_For
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info)
      return Limited_View_Status is
      use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status;
   begin
      case Visibility.Status is
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Limited_View =>
            return Limited_View_Incomplete_View_Visible;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Visible
            | Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Private_View
            | Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Use_Package_Visible =>
            return Limited_View_Not_Limited;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Missing =>
            return Limited_View_Missing_Dependency;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous =>
            return Limited_View_Ambiguous_Dependency;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Overflow =>
            return Limited_View_Overflow_Dependency;
         when others =>
            return Limited_View_Not_Found;
      end case;
   end Status_For;

   function To_Info
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info)
      return Limited_View_Info is
      use type Limited_View_Status;
      Info : Limited_View_Info;
      FP   : Natural := 29;
   begin
      Info.Status := Status_For (Visibility);
      Info.Source_Unit_Name := Visibility.Source_Unit_Name;
      Info.Target_Unit_Name := Visibility.Target_Unit_Name;
      Info.Target_Path := Visibility.Target_Path;
      Info.Clause_Name := Visibility.Clause_Name;
      Info.Candidate_Count := Visibility.Candidate_Count;

      if Info.Status = Limited_View_Incomplete_View_Visible then
         Info.Incomplete_View_Visible := True;
         Info.Full_View_Visible := False;
         Info.Full_View_Hidden := True;
         Info.Use_Clause_Allowed := False;
      elsif Info.Status = Limited_View_Not_Limited then
         Info.Incomplete_View_Visible := False;
         Info.Full_View_Visible := True;
         Info.Full_View_Hidden := False;
         Info.Use_Clause_Allowed := Visibility.Is_Use;
      else
         Info.Incomplete_View_Visible := False;
         Info.Full_View_Visible := False;
         Info.Full_View_Hidden := False;
         Info.Use_Clause_Allowed := False;
      end if;

      Mix (FP, Limited_View_Status'Pos (Info.Status));
      Mix (FP, To_String (Info.Source_Unit_Name));
      Mix (FP, To_String (Info.Target_Unit_Name));
      Mix (FP, To_String (Info.Target_Path));
      Mix (FP, To_String (Info.Clause_Name));
      Mix (FP, Boolean'Pos (Info.Incomplete_View_Visible));
      Mix (FP, Boolean'Pos (Info.Full_View_Visible));
      Mix (FP, Boolean'Pos (Info.Full_View_Hidden));
      Mix (FP, Boolean'Pos (Info.Use_Clause_Allowed));
      Mix (FP, Info.Candidate_Count);
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Limited_View_Model is
      Model : Limited_View_Model;
      FP    : Natural := 31;
   begin
      Mix (FP, Editor.Ada_Cross_Unit_Visibility.Fingerprint (Visibility));

      for I in 1 .. Editor.Ada_Cross_Unit_Visibility.Visibility_Count (Visibility) loop
         declare
            Info : constant Limited_View_Info :=
              To_Info (Editor.Ada_Cross_Unit_Visibility.Visibility_At (Visibility, I));
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Rule_Count (Model : Limited_View_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Rule_Count;

   function Rule_At
     (Model : Limited_View_Model;
      Index : Positive) return Limited_View_Info is
   begin
      return Model.Items.Element (Index);
   end Rule_At;

   function Lookup_Limited_View
     (Model            : Limited_View_Model;
      Source_Unit_Name : String;
      Name             : String) return Limited_View_Info is
      Source : constant String := Normalize (Source_Unit_Name);
      Target : constant String := Normalize (Name);
      Found  : Limited_View_Info;
      Count  : Natural := 0;
   begin
      for Info of Model.Items loop
         if Normalize (To_String (Info.Source_Unit_Name)) = Source
           and then (Normalize (To_String (Info.Clause_Name)) = Target
                     or else Normalize (To_String (Info.Target_Unit_Name)) = Target)
         then
            Count := Count + 1;
            if Count = 1 then
               Found := Info;
            end if;
         end if;
      end loop;

      if Count = 0 then
         Found.Status := Limited_View_Not_Found;
         Found.Source_Unit_Name := To_Unbounded_String (Source_Unit_Name);
         Found.Clause_Name := To_Unbounded_String (Name);
         Found.Fingerprint := 0;
      elsif Count > 1 then
         Found.Status := Limited_View_Ambiguous_Dependency;
         Found.Candidate_Count := Count;
         Found.Incomplete_View_Visible := False;
         Found.Full_View_Visible := False;
         Found.Full_View_Hidden := False;
         Found.Use_Clause_Allowed := False;
         Found.Fingerprint := Found.Fingerprint + Count;
      end if;

      return Found;
   end Lookup_Limited_View;

   function Full_View_Visible
     (Model            : Limited_View_Model;
      Source_Unit_Name : String;
      Name             : String) return Boolean is
      Info : constant Limited_View_Info :=
        Lookup_Limited_View (Model, Source_Unit_Name, Name);
   begin
      return Info.Full_View_Visible;
   end Full_View_Visible;

   function Count_Status
     (Model  : Limited_View_Model;
      Status : Limited_View_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Incomplete_View_Count (Model : Limited_View_Model) return Natural is
   begin
      return Count_Status (Model, Limited_View_Incomplete_View_Visible);
   end Incomplete_View_Count;

   function Full_View_Hidden_Count (Model : Limited_View_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Full_View_Hidden then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Full_View_Hidden_Count;

   function Nonlimited_View_Count (Model : Limited_View_Model) return Natural is
   begin
      return Count_Status (Model, Limited_View_Not_Limited);
   end Nonlimited_View_Count;

   function Missing_Count (Model : Limited_View_Model) return Natural is
   begin
      return Count_Status (Model, Limited_View_Missing_Dependency);
   end Missing_Count;

   function Ambiguous_Count (Model : Limited_View_Model) return Natural is
   begin
      return Count_Status (Model, Limited_View_Ambiguous_Dependency);
   end Ambiguous_Count;

   function Overflow_Count (Model : Limited_View_Model) return Natural is
   begin
      return Count_Status (Model, Limited_View_Overflow_Dependency);
   end Overflow_Count;

   function Fingerprint (Model : Limited_View_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Limited_View_Rules;
