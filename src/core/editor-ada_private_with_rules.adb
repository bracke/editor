with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Private_With_Rules is

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
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
      Context    : Private_With_Context) return Private_With_Status is
      use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status;
   begin
      case Visibility.Status is
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Private_View =>
            case Context is
               when Private_With_Context_Visible_Part =>
                  return Private_With_Hidden_From_Visible_Part;
               when Private_With_Context_Private_Part =>
                  return Private_With_Visible_In_Private_Context;
               when Private_With_Context_Body =>
                  return Private_With_Visible_In_Body_Context;
            end case;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Visible
            | Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Limited_View
            | Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Use_Package_Visible =>
            return Private_With_Not_Private;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Missing =>
            return Private_With_Missing_Dependency;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous =>
            return Private_With_Ambiguous_Dependency;
         when Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Overflow =>
            return Private_With_Overflow_Dependency;
         when others =>
            return Private_With_Not_Found;
      end case;
   end Status_For;

   function To_Info
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info;
      Context    : Private_With_Context) return Private_With_Info is
      use type Private_With_Status;
      Info : Private_With_Info;
      FP   : Natural := 37;
   begin
      Info.Status := Status_For (Visibility, Context);
      Info.Source_Unit_Name := Visibility.Source_Unit_Name;
      Info.Target_Unit_Name := Visibility.Target_Unit_Name;
      Info.Target_Path := Visibility.Target_Path;
      Info.Clause_Name := Visibility.Clause_Name;
      Info.Candidate_Count := Visibility.Candidate_Count;

      Info.Is_Private_Dependency := Visibility.Is_Private;

      if Info.Status = Private_With_Hidden_From_Visible_Part
        or else Info.Status = Private_With_Visible_In_Private_Context
        or else Info.Status = Private_With_Visible_In_Body_Context
      then
         Info.Visible_Part_Visible := False;
         Info.Private_Part_Visible := True;
         Info.Body_Visible := True;
         Info.Hidden_From_Visible_Part := True;
         Info.Use_Clause_Allowed := False;
      elsif Info.Status = Private_With_Not_Private then
         Info.Visible_Part_Visible := True;
         Info.Private_Part_Visible := True;
         Info.Body_Visible := True;
         Info.Hidden_From_Visible_Part := False;
         Info.Use_Clause_Allowed := Visibility.Is_Use;
      else
         Info.Visible_Part_Visible := False;
         Info.Private_Part_Visible := False;
         Info.Body_Visible := False;
         Info.Hidden_From_Visible_Part := False;
         Info.Use_Clause_Allowed := False;
      end if;

      Mix (FP, Private_With_Status'Pos (Info.Status));
      Mix (FP, Private_With_Context'Pos (Context));
      Mix (FP, To_String (Info.Source_Unit_Name));
      Mix (FP, To_String (Info.Target_Unit_Name));
      Mix (FP, To_String (Info.Target_Path));
      Mix (FP, To_String (Info.Clause_Name));
      Mix (FP, Boolean'Pos (Info.Is_Private_Dependency));
      Mix (FP, Boolean'Pos (Info.Visible_Part_Visible));
      Mix (FP, Boolean'Pos (Info.Private_Part_Visible));
      Mix (FP, Boolean'Pos (Info.Body_Visible));
      Mix (FP, Boolean'Pos (Info.Hidden_From_Visible_Part));
      Mix (FP, Boolean'Pos (Info.Use_Clause_Allowed));
      Mix (FP, Info.Candidate_Count);
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Private_With_Model is
      Model : Private_With_Model;
      FP    : Natural := 41;
   begin
      Mix (FP, Editor.Ada_Cross_Unit_Visibility.Fingerprint (Visibility));

      for I in 1 .. Editor.Ada_Cross_Unit_Visibility.Visibility_Count (Visibility) loop
         declare
            Base : constant Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info :=
              Editor.Ada_Cross_Unit_Visibility.Visibility_At (Visibility, I);
            Info : constant Private_With_Info :=
              To_Info (Base, Private_With_Context_Visible_Part);
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Rule_Count (Model : Private_With_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Rule_Count;

   function Rule_At
     (Model : Private_With_Model;
      Index : Positive) return Private_With_Info is
   begin
      return Model.Items.Element (Index);
   end Rule_At;

   function Lookup_Base
     (Model            : Private_With_Model;
      Source_Unit_Name : String;
      Name             : String) return Private_With_Info is
      Source : constant String := Normalize (Source_Unit_Name);
      Target : constant String := Normalize (Name);
      Found  : Private_With_Info;
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
         Found.Status := Private_With_Not_Found;
         Found.Source_Unit_Name := To_Unbounded_String (Source_Unit_Name);
         Found.Clause_Name := To_Unbounded_String (Name);
         Found.Fingerprint := 0;
      elsif Count > 1 then
         Found.Status := Private_With_Ambiguous_Dependency;
         Found.Candidate_Count := Count;
         Found.Visible_Part_Visible := False;
         Found.Private_Part_Visible := False;
         Found.Body_Visible := False;
         Found.Hidden_From_Visible_Part := False;
         Found.Use_Clause_Allowed := False;
         Found.Fingerprint := Found.Fingerprint + Count;
      end if;

      return Found;
   end Lookup_Base;

   function Lookup_Private_With
     (Model            : Private_With_Model;
      Source_Unit_Name : String;
      Name             : String;
      Context          : Private_With_Context) return Private_With_Info is
      Base : constant Private_With_Info := Lookup_Base (Model, Source_Unit_Name, Name);
      Info : Private_With_Info := Base;
      FP   : Natural := Base.Fingerprint;
   begin
      if Base.Status = Private_With_Not_Found
        or else Base.Status = Private_With_Missing_Dependency
        or else Base.Status = Private_With_Ambiguous_Dependency
        or else Base.Status = Private_With_Overflow_Dependency
      then
         return Base;
      end if;

      if Base.Is_Private_Dependency then
         case Context is
            when Private_With_Context_Visible_Part =>
               Info.Status := Private_With_Hidden_From_Visible_Part;
            when Private_With_Context_Private_Part =>
               Info.Status := Private_With_Visible_In_Private_Context;
            when Private_With_Context_Body =>
               Info.Status := Private_With_Visible_In_Body_Context;
         end case;
      else
         Info.Status := Private_With_Not_Private;
      end if;

      Mix (FP, Private_With_Context'Pos (Context));
      Mix (FP, Private_With_Status'Pos (Info.Status));
      Info.Fingerprint := FP;
      return Info;
   end Lookup_Private_With;

   function Visible_In_Context
     (Model            : Private_With_Model;
      Source_Unit_Name : String;
      Name             : String;
      Context          : Private_With_Context) return Boolean is
      Info : constant Private_With_Info :=
        Lookup_Private_With (Model, Source_Unit_Name, Name, Context);
   begin
      case Context is
         when Private_With_Context_Visible_Part =>
            return Info.Visible_Part_Visible;
         when Private_With_Context_Private_Part =>
            return Info.Private_Part_Visible;
         when Private_With_Context_Body =>
            return Info.Body_Visible;
      end case;
   end Visible_In_Context;

   function Count_Status
     (Model  : Private_With_Model;
      Status : Private_With_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Private_Dependency_Count (Model : Private_With_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Is_Private_Dependency then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Private_Dependency_Count;

   function Hidden_From_Visible_Part_Count (Model : Private_With_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Hidden_From_Visible_Part then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Hidden_From_Visible_Part_Count;

   function Private_Context_Visible_Count (Model : Private_With_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Private_Part_Visible then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Private_Context_Visible_Count;

   function Body_Context_Visible_Count (Model : Private_With_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Body_Visible then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Body_Context_Visible_Count;

   function Nonprivate_Dependency_Count (Model : Private_With_Model) return Natural is
   begin
      return Count_Status (Model, Private_With_Not_Private);
   end Nonprivate_Dependency_Count;

   function Missing_Count (Model : Private_With_Model) return Natural is
   begin
      return Count_Status (Model, Private_With_Missing_Dependency);
   end Missing_Count;

   function Ambiguous_Count (Model : Private_With_Model) return Natural is
   begin
      return Count_Status (Model, Private_With_Ambiguous_Dependency);
   end Ambiguous_Count;

   function Overflow_Count (Model : Private_With_Model) return Natural is
   begin
      return Count_Status (Model, Private_With_Overflow_Dependency);
   end Overflow_Count;

   function Fingerprint (Model : Private_With_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Private_With_Rules;
