with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package body Editor.Ada_Body_Spec_Conformance is

   pragma Suppress (Overflow_Check);

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Normalize;

   procedure Mix (Value : in out Natural; Text : String) is
   begin
      for Ch of Text loop
         Value := Natural
           ((Long_Long_Integer (Value) * 131
             + Long_Long_Integer (Character'Pos (Ch)))
            mod 1_000_000_007);
      end loop;
   end Mix;

   procedure Mix (Value : in out Natural; N : Natural) is
   begin
      Value := Natural
        ((Long_Long_Integer (Value) * 131 + Long_Long_Integer (N))
         mod 1_000_000_007);
   end Mix;

   function Is_Package_Pair
     (Spec_Role : Editor.Ada_Project_Index.Indexed_Unit_Role;
      Body_Role : Editor.Ada_Project_Index.Indexed_Unit_Role) return Boolean is
      use type Editor.Ada_Project_Index.Indexed_Unit_Role;
   begin
      return (Spec_Role = Editor.Ada_Project_Index.Unit_Package_Spec
              or else Spec_Role = Editor.Ada_Project_Index.Unit_Private_Package_Spec)
        and then Body_Role = Editor.Ada_Project_Index.Unit_Package_Body;
   end Is_Package_Pair;

   function Is_Subprogram_Pair
     (Spec_Role : Editor.Ada_Project_Index.Indexed_Unit_Role;
      Body_Role : Editor.Ada_Project_Index.Indexed_Unit_Role) return Boolean is
      use type Editor.Ada_Project_Index.Indexed_Unit_Role;
   begin
      return Spec_Role = Editor.Ada_Project_Index.Unit_Subprogram_Spec
        and then Body_Role = Editor.Ada_Project_Index.Unit_Subprogram_Body;
   end Is_Subprogram_Pair;

   function Find_Unit
     (Index : Editor.Ada_Project_Index.Index_State;
      Name  : String;
      Path  : String;
      Role  : Editor.Ada_Project_Index.Indexed_Unit_Role)
      return Editor.Ada_Project_Index.Indexed_Unit is
      use type Editor.Ada_Project_Index.Indexed_Unit_Role;
      Wanted_Name : constant String := Normalize (Name);
      Wanted_Path : constant String := Path;
   begin
      for I in 1 .. Editor.Ada_Project_Index.Unit_Count (Index) loop
         declare
            Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Editor.Ada_Project_Index.Unit_At (Index, I);
         begin
            if Normalize (To_String (Unit.Unit_Name)) = Wanted_Name
              and then (Wanted_Path = "" or else To_String (Unit.Path) = Wanted_Path)
              and then (Role = Editor.Ada_Project_Index.Unit_Any
                         or else Unit.Role = Role)
            then
               return Unit;
            end if;
         end;
      end loop;

      return (others => <>);
   end Find_Unit;

   function Status_From_Closure
     (Status : Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Status)
      return Body_Spec_Conformance_Status is
      use type Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Status;
   begin
      case Status is
         when Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Missing_Counterpart =>
            return Body_Spec_Conformance_Missing_Counterpart;
         when Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Ambiguous_Counterpart =>
            return Body_Spec_Conformance_Ambiguous_Counterpart;
         when Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Overflow =>
            return Body_Spec_Conformance_Overflow;
         when Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Role_Mismatch =>
            return Body_Spec_Conformance_Role_Mismatch;
         when Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Name_Mismatch =>
            return Body_Spec_Conformance_Name_Mismatch;
         when Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Confirmed =>
            return Body_Spec_Conformance_Confirmed;
         when others =>
            return Body_Spec_Conformance_Not_Applicable;
      end case;
   end Status_From_Closure;

   function To_Info
     (Index       : Editor.Ada_Project_Index.Index_State;
      Consistency : Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Info)
      return Body_Spec_Conformance_Info is
      use type Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Status;
      Info : Body_Spec_Conformance_Info;
      FP   : Natural := 29;
   begin
      Info.Status := Status_From_Closure (Consistency.Status);
      Info.Spec_Unit_Name := Consistency.Spec_Unit_Name;
      Info.Spec_Path := Consistency.Spec_Path;
      Info.Spec_Role := Consistency.Spec_Role;
      Info.Body_Unit_Name := Consistency.Body_Unit_Name;
      Info.Body_Path := Consistency.Body_Path;
      Info.Body_Role := Consistency.Body_Role;
      Info.Candidate_Count := Consistency.Candidate_Count;

      if Consistency.Status = Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Confirmed then
         declare
            Spec_Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Find_Unit
                (Index,
                 To_String (Consistency.Spec_Unit_Name),
                 To_String (Consistency.Spec_Path),
                 Consistency.Spec_Role);
            Body_Unit : constant Editor.Ada_Project_Index.Indexed_Unit :=
              Find_Unit
                (Index,
                 To_String (Consistency.Body_Unit_Name),
                 To_String (Consistency.Body_Path),
                 Consistency.Body_Role);
            Spec_Name : constant String := Normalize (To_String (Spec_Unit.Unit_Name));
            Body_Name : constant String := Normalize (To_String (Body_Unit.Unit_Name));
         begin
            Info.Spec_Profile := Spec_Unit.Symbol.Profile_Summary;
            Info.Body_Profile := Body_Unit.Symbol.Profile_Summary;

            if Spec_Name = "" or else Body_Name = "" then
               Info.Status := Body_Spec_Conformance_Profile_Unknown;
            elsif Spec_Name /= Body_Name then
               Info.Status := Body_Spec_Conformance_Name_Mismatch;
            elsif Is_Package_Pair (Spec_Unit.Role, Body_Unit.Role) then
               Info.Status := Body_Spec_Conformance_Package_Confirmed;
            elsif Is_Subprogram_Pair (Spec_Unit.Role, Body_Unit.Role) then
               declare
                  Spec_Profile : constant String := Normalize (To_String (Spec_Unit.Symbol.Profile_Summary));
                  Body_Profile : constant String := Normalize (To_String (Body_Unit.Symbol.Profile_Summary));
               begin
                  if Spec_Profile = "" or else Body_Profile = "" then
                     Info.Status := Body_Spec_Conformance_Profile_Unknown;
                  elsif Spec_Profile = Body_Profile then
                     Info.Status := Body_Spec_Conformance_Subprogram_Profile_Confirmed;
                  else
                     Info.Status := Body_Spec_Conformance_Profile_Mismatch;
                  end if;
               end;
            else
               Info.Status := Body_Spec_Conformance_Role_Mismatch;
            end if;
         end;
      end if;

      Mix (FP, Body_Spec_Conformance_Status'Pos (Info.Status));
      Mix (FP, To_String (Info.Spec_Unit_Name));
      Mix (FP, To_String (Info.Spec_Path));
      Mix (FP, Editor.Ada_Project_Index.Indexed_Unit_Role'Pos (Info.Spec_Role));
      Mix (FP, To_String (Info.Body_Unit_Name));
      Mix (FP, To_String (Info.Body_Path));
      Mix (FP, Editor.Ada_Project_Index.Indexed_Unit_Role'Pos (Info.Body_Role));
      Mix (FP, To_String (Info.Spec_Profile));
      Mix (FP, To_String (Info.Body_Profile));
      Mix (FP, Info.Candidate_Count);
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Index   : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Body_Spec_Conformance_Model is
      Model : Body_Spec_Conformance_Model;
      FP    : Natural := 31;
   begin
      Mix (FP, Editor.Ada_Project_Index.Fingerprint (Index));
      Mix (FP, Editor.Ada_Cross_Unit_Closure.Fingerprint (Closure));

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_Count (Closure) loop
         declare
            Info : constant Body_Spec_Conformance_Info :=
              To_Info (Index, Editor.Ada_Cross_Unit_Closure.Spec_Body_Consistency_At (Closure, I));
         begin
            Model.Items.Append (Info);
            Mix (FP, Info.Fingerprint);
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Conformance_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Conformance_Count;

   function Conformance_At
     (Model : Body_Spec_Conformance_Model;
      Index : Positive) return Body_Spec_Conformance_Info is
   begin
      if Model.Items.Is_Empty
        or else Index < Model.Items.First_Index
        or else Index > Model.Items.Last_Index
      then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Conformance_At;

   function Count_Status
     (Model  : Body_Spec_Conformance_Model;
      Status : Body_Spec_Conformance_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Confirmed_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Package_Confirmed_Count (Model)
        + Subprogram_Profile_Confirmed_Count (Model)
        + Count_Status (Model, Body_Spec_Conformance_Confirmed);
   end Confirmed_Count;

   function Package_Confirmed_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Package_Confirmed);
   end Package_Confirmed_Count;

   function Subprogram_Profile_Confirmed_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Subprogram_Profile_Confirmed);
   end Subprogram_Profile_Confirmed_Count;

   function Missing_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Missing_Counterpart);
   end Missing_Count;

   function Ambiguous_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Ambiguous_Counterpart);
   end Ambiguous_Count;

   function Overflow_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Overflow);
   end Overflow_Count;

   function Role_Mismatch_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Role_Mismatch);
   end Role_Mismatch_Count;

   function Name_Mismatch_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Name_Mismatch);
   end Name_Mismatch_Count;

   function Profile_Mismatch_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Profile_Mismatch);
   end Profile_Mismatch_Count;

   function Profile_Unknown_Count
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Count_Status (Model, Body_Spec_Conformance_Profile_Unknown);
   end Profile_Unknown_Count;

   function Fingerprint
     (Model : Body_Spec_Conformance_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Body_Spec_Conformance;
