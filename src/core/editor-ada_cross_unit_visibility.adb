with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Visibility is

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
     (Link : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Info)
      return Cross_Unit_Visibility_Status is
      use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Kind;
      use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Status;
   begin
      case Link.Status is
         when Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Resolved =>
            if Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Use_Dependency then
               return Cross_Unit_Visibility_Use_Package_Visible;
            elsif Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Limited_With_Dependency then
               return Cross_Unit_Visibility_Limited_View;
            elsif Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Private_With_Dependency then
               return Cross_Unit_Visibility_Private_View;
            else
               return Cross_Unit_Visibility_Visible;
            end if;
         when Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Missing =>
            return Cross_Unit_Visibility_Missing;
         when Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Ambiguous =>
            return Cross_Unit_Visibility_Ambiguous;
         when Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Overflow =>
            return Cross_Unit_Visibility_Overflow;
         when others =>
            return Cross_Unit_Visibility_Not_Found;
      end case;
   end Status_For;

   function Is_Context_Link
     (Kind : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Kind) return Boolean is
      use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Kind;
   begin
      return Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_With_Dependency
        or else Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Limited_With_Dependency
        or else Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Private_With_Dependency
        or else Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Use_Dependency;
   end Is_Context_Link;

   function To_Info
     (Link : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Info)
      return Cross_Unit_Visibility_Info is
      use type Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Kind;
      Info : Cross_Unit_Visibility_Info;
      FP   : Natural := 17;
   begin
      Info.Status := Status_For (Link);
      Info.Source_Unit_Name := Link.Source_Unit_Name;
      Info.Target_Unit_Name := Link.Target_Unit_Name;
      Info.Target_Path := Link.Target_Path;
      Info.Clause_Name := Link.Clause_Name;
      Info.Is_Use := Link.Kind = Editor.Ada_Cross_Unit_Closure.Cross_Unit_Use_Dependency;
      Info.Is_With := not Info.Is_Use;
      Info.Is_Limited := Link.Is_Limited_With;
      Info.Is_Private := Link.Is_Private_With;
      Info.Candidate_Count := Link.Candidate_Count;

      Mix (FP, Cross_Unit_Visibility_Status'Pos (Info.Status));
      Mix (FP, To_String (Info.Source_Unit_Name));
      Mix (FP, To_String (Info.Target_Unit_Name));
      Mix (FP, To_String (Info.Target_Path));
      Mix (FP, To_String (Info.Clause_Name));
      Mix (FP, Boolean'Pos (Info.Is_With));
      Mix (FP, Boolean'Pos (Info.Is_Use));
      Mix (FP, Boolean'Pos (Info.Is_Limited));
      Mix (FP, Boolean'Pos (Info.Is_Private));
      Mix (FP, Info.Candidate_Count);
      Info.Fingerprint := FP;
      return Info;
   end To_Info;

   function Build
     (Index   : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Cross_Unit_Visibility_Model is
      Model : Cross_Unit_Visibility_Model;
      FP    : Natural := 23;
   begin
      Mix (FP, Editor.Ada_Project_Index.Fingerprint (Index));
      Mix (FP, Editor.Ada_Cross_Unit_Closure.Fingerprint (Closure));

      for I in 1 .. Editor.Ada_Cross_Unit_Closure.Link_Count (Closure) loop
         declare
            Link : constant Editor.Ada_Cross_Unit_Closure.Cross_Unit_Link_Info :=
              Editor.Ada_Cross_Unit_Closure.Link_At (Closure, I);
         begin
            if Is_Context_Link (Link.Kind) then
               declare
                  Info : constant Cross_Unit_Visibility_Info := To_Info (Link);
               begin
                  Model.Items.Append (Info);
                  Mix (FP, Info.Fingerprint);
               end;
            end if;
         end;
      end loop;

      Model.Model_Fingerprint := FP;
      return Model;
   end Build;

   function Visibility_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Visibility_Count;

   function Visibility_At
     (Model : Cross_Unit_Visibility_Model;
      Index : Positive) return Cross_Unit_Visibility_Info is
   begin
      return Model.Items.Element (Index);
   end Visibility_At;

   function Lookup_Visible_Unit
     (Model            : Cross_Unit_Visibility_Model;
      Source_Unit_Name : String;
      Name             : String) return Cross_Unit_Visibility_Info is
      Source : constant String := Normalize (Source_Unit_Name);
      Target : constant String := Normalize (Name);
      Found  : Cross_Unit_Visibility_Info;
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
         Found.Status := Cross_Unit_Visibility_Not_Found;
         Found.Source_Unit_Name := To_Unbounded_String (Source_Unit_Name);
         Found.Clause_Name := To_Unbounded_String (Name);
         Found.Fingerprint := 0;
      elsif Count > 1 then
         Found.Status := Cross_Unit_Visibility_Ambiguous;
         Found.Candidate_Count := Count;
         Found.Fingerprint := Found.Fingerprint + Count;
      end if;

      return Found;
   end Lookup_Visible_Unit;

   function Count_Status
     (Model  : Cross_Unit_Visibility_Model;
      Status : Cross_Unit_Visibility_Status) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function With_Visible_Count (Model : Cross_Unit_Visibility_Model) return Natural is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Is_With
           and then (Info.Status = Cross_Unit_Visibility_Visible
                     or else Info.Status = Cross_Unit_Visibility_Limited_View
                     or else Info.Status = Cross_Unit_Visibility_Private_View)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end With_Visible_Count;

   function Use_Visible_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Visibility_Use_Package_Visible);
   end Use_Visible_Count;

   function Limited_View_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Visibility_Limited_View);
   end Limited_View_Count;

   function Private_View_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Visibility_Private_View);
   end Private_View_Count;

   function Missing_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Visibility_Missing);
   end Missing_Count;

   function Ambiguous_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Visibility_Ambiguous);
   end Ambiguous_Count;

   function Overflow_Count (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Count_Status (Model, Cross_Unit_Visibility_Overflow);
   end Overflow_Count;

   function Fingerprint (Model : Cross_Unit_Visibility_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Visibility;
