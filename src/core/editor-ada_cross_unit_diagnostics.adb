with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Diagnostics is

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Kind_Code (Kind : Cross_Unit_Diagnostic_Kind) return Natural is
   begin
      return Cross_Unit_Diagnostic_Kind'Pos (Kind) + 1;
   end Kind_Code;

   function Severity_Code (Severity : Cross_Unit_Diagnostic_Severity) return Natural is
   begin
      return Cross_Unit_Diagnostic_Severity'Pos (Severity) + 1;
   end Severity_Code;

   function Make_Fingerprint
     (Kind : Cross_Unit_Diagnostic_Kind;
      Severity : Cross_Unit_Diagnostic_Severity;
      Seed : Natural) return Natural
   is
   begin
      return Mix (Mix (Kind_Code (Kind), Severity_Code (Severity)), Seed);
   end Make_Fingerprint;

   procedure Add
     (Model : in out Cross_Unit_Diagnostic_Model;
      Kind : Cross_Unit_Diagnostic_Kind;
      Severity : Cross_Unit_Diagnostic_Severity;
      Source_Unit_Name : Unbounded_String;
      Target_Unit_Name : Unbounded_String;
      Message : String;
      Seed : Natural)
   is
      Info : Cross_Unit_Diagnostic_Info;
   begin
      Info.Id := Cross_Unit_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Kind := Kind;
      Info.Severity := Severity;
      Info.Source_Unit_Name := Source_Unit_Name;
      Info.Target_Unit_Name := Target_Unit_Name;
      Info.Message := To_Unbounded_String (Message);
      Info.Fingerprint := Make_Fingerprint (Kind, Severity, Seed);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);

      case Severity is
         when Cross_Unit_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Cross_Unit_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Cross_Unit_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
   end Add;


   function Nested_Kind
     (Status : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Status)
      return Cross_Unit_Diagnostic_Kind is
   begin
      case Status is
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Missing_Body_Declaration =>
            return Cross_Unit_Diagnostic_Nested_Body_Spec_Missing;
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Extra_Body_Declaration =>
            return Cross_Unit_Diagnostic_Nested_Body_Spec_Extra;
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Ambiguous_Body_Declaration =>
            return Cross_Unit_Diagnostic_Nested_Body_Spec_Ambiguous;
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Kind_Mismatch |
              Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Mismatch =>
            return Cross_Unit_Diagnostic_Nested_Body_Spec_Mismatch;
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Unknown |
              Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Nonconforming_Unit_Pair =>
            return Cross_Unit_Diagnostic_Nested_Body_Spec_Unknown;
         when others =>
            return Cross_Unit_Diagnostic_Cross_Unit_Unknown;
      end case;
   end Nested_Kind;

   function Nested_Message
     (Status : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Status)
      return String is
   begin
      case Status is
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Missing_Body_Declaration =>
            return "nested spec declaration has no matching body declaration";
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Extra_Body_Declaration =>
            return "nested body declaration has no matching spec declaration";
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Ambiguous_Body_Declaration =>
            return "nested body declaration match is ambiguous";
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Kind_Mismatch =>
            return "nested body declaration kind does not conform to its spec declaration";
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Mismatch =>
            return "nested body declaration profile does not conform to its spec declaration";
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Unknown =>
            return "nested body/spec declaration profile conformance is unknown";
         when Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Nonconforming_Unit_Pair =>
            return "nested body/spec declarations cannot be checked because the enclosing unit pair is nonconforming";
         when others =>
            return "nested body/spec declaration is conforming";
      end case;
   end Nested_Message;

   procedure Add_Nested
     (Model : in out Cross_Unit_Diagnostic_Model;
      Nested : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Info)
   is
      use type Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Status;
      Kind : constant Cross_Unit_Diagnostic_Kind := Nested_Kind (Nested.Status);
      Info : Cross_Unit_Diagnostic_Info;
      Use_Spec_Range : constant Boolean :=
        Nested.Status /= Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Extra_Body_Declaration;
   begin
      if Kind = Cross_Unit_Diagnostic_Cross_Unit_Unknown then
         return;
      end if;

      Info.Id := Cross_Unit_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Kind := Kind;
      if Nested.Status = Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Profile_Unknown
        or else Nested.Status = Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Nonconforming_Unit_Pair
      then
         Info.Severity := Cross_Unit_Diagnostic_Warning;
      else
         Info.Severity := Cross_Unit_Diagnostic_Error;
      end if;
      Info.Source_Unit_Name := Nested.Spec_Unit_Name;
      Info.Target_Unit_Name := Nested.Body_Unit_Name;
      Info.Message := To_Unbounded_String (Nested_Message (Nested.Status));
      if Use_Spec_Range then
         Info.Start_Line := Nested.Spec_Range.Start_Line;
         Info.Start_Column := Nested.Spec_Range.Start_Column;
         Info.End_Line := Nested.Spec_Range.End_Line;
         Info.End_Column := Nested.Spec_Range.End_Column;
      else
         Info.Start_Line := Nested.Body_Range.Start_Line;
         Info.Start_Column := Nested.Body_Range.Start_Column;
         Info.End_Line := Nested.Body_Range.End_Line;
         Info.End_Column := Nested.Body_Range.End_Column;
      end if;
      Info.Nested_Conformance := Nested.Id;
      Info.Nested_Status := Nested.Status;
      Info.Declaration_Name := Nested.Declaration_Name;
      Info.Fingerprint := Make_Fingerprint (Kind, Info.Severity, Nested.Fingerprint);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);

      case Info.Severity is
         when Cross_Unit_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Cross_Unit_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Cross_Unit_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
   end Add_Nested;

   procedure Clear (Model : in out Cross_Unit_Diagnostic_Model) is
   begin
      Model.Diagnostics.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Limited_View    : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Private_W  : Editor.Ada_Private_With_Rules.Private_With_Model;
      Body_Spec  : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Children   : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Separates  : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model)
      return Cross_Unit_Diagnostic_Model
   is
      Model : Cross_Unit_Diagnostic_Model;
      use type Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status;
      use type Editor.Ada_Limited_View_Rules.Limited_View_Status;
      use type Editor.Ada_Private_With_Rules.Private_With_Status;
      use type Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Status;
      use type Editor.Ada_Child_Unit_Visibility.Child_Visibility_Status;
      use type Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Status;
   begin
      for Index in 1 .. Editor.Ada_Cross_Unit_Visibility.Visibility_Count (Visibility) loop
         declare
            Info : constant Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Info :=
              Editor.Ada_Cross_Unit_Visibility.Visibility_At (Visibility, Index);
         begin
            if Info.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Missing then
               Add (Model, Cross_Unit_Diagnostic_Missing_Dependency,
                    Cross_Unit_Diagnostic_Error,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "cross-unit dependency is missing", Info.Fingerprint);
            elsif Info.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Ambiguous
              or else Info.Status = Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Overflow
            then
               Add (Model, Cross_Unit_Diagnostic_Ambiguous_Dependency,
                    Cross_Unit_Diagnostic_Error,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "cross-unit dependency is ambiguous or overflowed", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Limited_View_Rules.Rule_Count (Limited_View) loop
         declare
            Info : constant Editor.Ada_Limited_View_Rules.Limited_View_Info :=
              Editor.Ada_Limited_View_Rules.Rule_At (Limited_View, Index);
         begin
            if Info.Status in
              Editor.Ada_Limited_View_Rules.Limited_View_Full_View_Hidden |
              Editor.Ada_Limited_View_Rules.Limited_View_Incomplete_View_Visible
            then
               Add (Model, Cross_Unit_Diagnostic_Limited_View_Full_View_Hidden,
                    Cross_Unit_Diagnostic_Warning,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "limited with exposes only an incomplete view", Info.Fingerprint);
            elsif Info.Status = Editor.Ada_Limited_View_Rules.Limited_View_Missing_Dependency then
               Add (Model, Cross_Unit_Diagnostic_Missing_Dependency,
                    Cross_Unit_Diagnostic_Error,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "limited-with dependency is missing", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Limited_View_Rules.Limited_View_Ambiguous_Dependency |
              Editor.Ada_Limited_View_Rules.Limited_View_Overflow_Dependency
            then
               Add (Model, Cross_Unit_Diagnostic_Ambiguous_Dependency,
                    Cross_Unit_Diagnostic_Error,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "limited-with dependency is ambiguous or overflowed", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Private_With_Rules.Rule_Count (Private_W) loop
         declare
            Info : constant Editor.Ada_Private_With_Rules.Private_With_Info :=
              Editor.Ada_Private_With_Rules.Rule_At (Private_W, Index);
         begin
            if Info.Status = Editor.Ada_Private_With_Rules.Private_With_Hidden_From_Visible_Part then
               Add (Model, Cross_Unit_Diagnostic_Private_With_Hidden,
                    Cross_Unit_Diagnostic_Warning,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "private-with dependency is hidden from visible-part lookup", Info.Fingerprint);
            elsif Info.Status = Editor.Ada_Private_With_Rules.Private_With_Missing_Dependency then
               Add (Model, Cross_Unit_Diagnostic_Missing_Dependency,
                    Cross_Unit_Diagnostic_Error,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "private-with dependency is missing", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Private_With_Rules.Private_With_Ambiguous_Dependency |
              Editor.Ada_Private_With_Rules.Private_With_Overflow_Dependency
            then
               Add (Model, Cross_Unit_Diagnostic_Ambiguous_Dependency,
                    Cross_Unit_Diagnostic_Error,
                    Info.Source_Unit_Name, Info.Clause_Name,
                    "private-with dependency is ambiguous or overflowed", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Body_Spec_Conformance.Conformance_Count (Body_Spec) loop
         declare
            Info : constant Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Info :=
              Editor.Ada_Body_Spec_Conformance.Conformance_At (Body_Spec, Index);
         begin
            if Info.Status = Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Missing_Counterpart then
               Add (Model, Cross_Unit_Diagnostic_Body_Spec_Missing,
                    Cross_Unit_Diagnostic_Error,
                    Info.Spec_Unit_Name, Info.Body_Unit_Name,
                    "library unit spec/body counterpart is missing", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Ambiguous_Counterpart |
              Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Overflow
            then
               Add (Model, Cross_Unit_Diagnostic_Body_Spec_Ambiguous,
                    Cross_Unit_Diagnostic_Error,
                    Info.Spec_Unit_Name, Info.Body_Unit_Name,
                    "library unit spec/body counterpart is ambiguous or overflowed", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Role_Mismatch |
              Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Name_Mismatch |
              Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Profile_Mismatch |
              Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Profile_Unknown
            then
               Add (Model, Cross_Unit_Diagnostic_Body_Spec_Mismatch,
                    Cross_Unit_Diagnostic_Error,
                    Info.Spec_Unit_Name, Info.Body_Unit_Name,
                    "library unit body does not conform to its specification", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Child_Unit_Visibility.Visibility_Count (Children) loop
         declare
            Info : constant Editor.Ada_Child_Unit_Visibility.Child_Visibility_Info :=
              Editor.Ada_Child_Unit_Visibility.Visibility_At (Children, Index);
         begin
            if Info.Status = Editor.Ada_Child_Unit_Visibility.Child_Visibility_Private_Child_Hidden then
               Add (Model, Cross_Unit_Diagnostic_Private_Child_Hidden,
                    Cross_Unit_Diagnostic_Warning,
                    Info.Parent_Unit_Name, Info.Child_Unit_Name,
                    "private child unit is hidden from this lookup context", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Missing_Parent |
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Ambiguous_Parent |
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Overflow |
              Editor.Ada_Child_Unit_Visibility.Child_Visibility_Parent_Role_Mismatch
            then
               Add (Model, Cross_Unit_Diagnostic_Child_Parent_Error,
                    Cross_Unit_Diagnostic_Error,
                    Info.Parent_Unit_Name, Info.Child_Unit_Name,
                    "child unit parent is missing, ambiguous, overflowed, or invalid", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Separate_Body_Stub_Rules.Stub_Check_Count (Separates) loop
         declare
            Info : constant Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Info :=
              Editor.Ada_Separate_Body_Stub_Rules.Stub_Check_At (Separates, Index);
         begin
            if Info.Status in
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Missing |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Ambiguous |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Kind_Mismatch |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Profile_Mismatch |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Profile_Unknown
            then
               Add (Model, Cross_Unit_Diagnostic_Separate_Stub_Missing,
                    Cross_Unit_Diagnostic_Error,
                    Info.Parent_Unit_Name, Info.Separate_Unit_Name,
                    "separate body does not match a unique parent body stub", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Missing_Parent |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Ambiguous_Parent |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Overflow |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Parent_Role_Mismatch |
              Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Target_Name_Missing
            then
               Add (Model, Cross_Unit_Diagnostic_Separate_Parent_Error,
                    Cross_Unit_Diagnostic_Error,
                    Info.Parent_Unit_Name, Info.Separate_Unit_Name,
                    "separate body parent is missing, ambiguous, overflowed, or invalid", Info.Fingerprint);
            end if;
         end;
      end loop;

      return Model;
   end Build;


   function Build_With_Nested
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Limited_View    : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Private_W  : Editor.Ada_Private_With_Rules.Private_With_Model;
      Body_Spec  : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Children   : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Separates  : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model;
      Nested     : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Model)
      return Cross_Unit_Diagnostic_Model
   is
      Model : Cross_Unit_Diagnostic_Model :=
        Build (Visibility, Limited_View, Private_W, Body_Spec, Children, Separates);
   begin
      for Index in 1 .. Editor.Ada_Nested_Body_Spec_Conformance.Conformance_Count (Nested) loop
         declare
            Info : constant Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Info :=
              Editor.Ada_Nested_Body_Spec_Conformance.Conformance_At (Nested, Index);
         begin
            Add_Nested (Model, Info);
         end;
      end loop;
      return Model;
   end Build_With_Nested;

   function Has_Diagnostics (Model : Cross_Unit_Diagnostic_Model) return Boolean is
   begin
      return not Model.Diagnostics.Is_Empty;
   end Has_Diagnostics;

   function Diagnostic_Count (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (Model : Cross_Unit_Diagnostic_Model;
      Index : Positive) return Cross_Unit_Diagnostic_Info is
   begin
      if Index > Natural (Model.Diagnostics.Length) then
         return (others => <>);
      end if;
      return Model.Diagnostics.Element (Index);
   end Diagnostic_At;

   function Error_Count (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Count_Kind
     (Model : Cross_Unit_Diagnostic_Model;
      Kind  : Cross_Unit_Diagnostic_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for Info of Model.Diagnostics loop
         if Info.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;


   function Nested_Body_Spec_Diagnostic_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Missing)
        + Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Extra)
        + Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Ambiguous)
        + Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Mismatch)
        + Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Unknown);
   end Nested_Body_Spec_Diagnostic_Count;

   function Nested_Missing_Declaration_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Missing);
   end Nested_Missing_Declaration_Count;

   function Nested_Extra_Declaration_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Extra);
   end Nested_Extra_Declaration_Count;

   function Nested_Mismatch_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Ambiguous)
        + Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Mismatch)
        + Count_Kind (Model, Cross_Unit_Diagnostic_Nested_Body_Spec_Unknown);
   end Nested_Mismatch_Count;

   function Fingerprint (Model : Cross_Unit_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Diagnostics;
