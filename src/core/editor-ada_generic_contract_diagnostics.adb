with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Contract_Diagnostics is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Generic_View_Compatibility.Generic_View_Status;
   use type Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status;
   use type Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status;



   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Kind_Code (Kind : Generic_Contract_Diagnostic_Kind) return Natural is
   begin
      return Generic_Contract_Diagnostic_Kind'Pos (Kind) + 1;
   end Kind_Code;

   function Severity_Code (Severity : Generic_Contract_Diagnostic_Severity) return Natural is
   begin
      return Generic_Contract_Diagnostic_Severity'Pos (Severity) + 1;
   end Severity_Code;

   function Make_Fingerprint
     (Kind : Generic_Contract_Diagnostic_Kind;
      Severity : Generic_Contract_Diagnostic_Severity;
      Start_Line : Positive;
      End_Line : Positive;
      Seed : Natural) return Natural
   is
   begin
      return Mix
        (Mix (Mix (Kind_Code (Kind), Severity_Code (Severity)), Start_Line),
         Mix (End_Line, Seed));
   end Make_Fingerprint;

   procedure Add
     (Model : in out Generic_Contract_Diagnostic_Model;
      Node : Editor.Ada_Syntax_Tree.Node_Id;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal : Editor.Ada_Generic_Contracts.Generic_Formal_Id;
      Kind : Generic_Contract_Diagnostic_Kind;
      Severity : Generic_Contract_Diagnostic_Severity;
      Message : String;
      Start_Line : Positive;
      End_Line : Positive;
      Seed : Natural)
   is
      Info : Generic_Contract_Diagnostic_Info;
   begin
      Info.Id := Generic_Contract_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Node := Node;
      Info.Instance := Instance;
      Info.Formal := Formal;
      Info.Kind := Kind;
      Info.Severity := Severity;
      Info.Message := To_Unbounded_String (Message);
      Info.Start_Line := Start_Line;
      Info.End_Line := End_Line;
      Info.Fingerprint := Make_Fingerprint (Kind, Severity, Start_Line, End_Line, Seed);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);

      case Severity is
         when Generic_Contract_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Generic_Contract_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Generic_Contract_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
   end Add;



   function View_Kind
     (Status : Editor.Ada_Generic_View_Compatibility.Generic_View_Status)
      return Generic_Contract_Diagnostic_Kind
   is
   begin
      case Status is
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Private_Barrier =>
            return Generic_Diagnostic_Generic_View_Private_Barrier;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Limited_Barrier =>
            return Generic_Diagnostic_Generic_View_Limited_Barrier;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Cross_Unit_Unresolved =>
            return Generic_Diagnostic_Generic_View_Cross_Unit_Unresolved;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Mismatch =>
            return Generic_Diagnostic_Generic_View_Object_Mismatch;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Unknown =>
            return Generic_Diagnostic_Generic_View_Unknown;
         when others =>
            return Generic_Diagnostic_Contract_Unknown;
      end case;
   end View_Kind;

   function View_Message
     (Status : Editor.Ada_Generic_View_Compatibility.Generic_View_Status) return String
   is
   begin
      case Status is
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Private_Barrier =>
            return "generic actual or default is blocked by a private-view visibility barrier";
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Limited_Barrier =>
            return "generic actual or default is blocked by a limited-view incomplete type barrier";
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Cross_Unit_Unresolved =>
            return "generic actual or default depends on an unresolved cross-unit view";
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Mismatch =>
            return "generic actual or default remains incompatible after view-aware checking";
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Unknown =>
            return "generic actual or default view-aware compatibility is unknown";
         when others =>
            return "generic view-aware compatibility produced no diagnostic";
      end case;
   end View_Message;

   function View_Detail
     (Info : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info)
      return String
   is
   begin
      return "formal " & To_String (Info.Formal_Name) &
        " subtype " & To_String (Info.Formal_Subtype) &
        " expression " & To_String (Info.Expression_Text) &
        " target " & To_String (Info.Cross_Unit_Target) &
        " selector " & To_String (Info.Cross_Unit_Selector);
   end View_Detail;

   procedure Add_Generic_View
     (Model : in out Generic_Contract_Diagnostic_Model;
      View  : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info)
   is
      Kind : constant Generic_Contract_Diagnostic_Kind := View_Kind (View.Status);
      Info : Generic_Contract_Diagnostic_Info;
   begin
      if Kind = Generic_Diagnostic_Contract_Unknown then
         return;
      end if;

      Info.Id := Generic_Contract_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Node := View.Instance_Node;
      Info.Instance := View.Instance;
      Info.Formal := View.Formal;
      Info.Kind := Kind;
      Info.Severity := Generic_Contract_Diagnostic_Error;
      if View.Status = Editor.Ada_Generic_View_Compatibility.Generic_View_Object_Unknown then
         Info.Severity := Generic_Contract_Diagnostic_Warning;
      end if;
      Info.Message := To_Unbounded_String (View_Message (View.Status));
      Info.Detail := To_Unbounded_String (View_Detail (View));
      Info.Start_Line := View.Start_Line;
      Info.End_Line := View.End_Line;
      Info.From_Generic_View := True;
      Info.Generic_View := View.Id;
      Info.Generic_View_Status := View.Status;
      Info.Generic_View_Fingerprint := View.Fingerprint;
      Info.Fingerprint := Make_Fingerprint
        (Kind, Info.Severity, View.Start_Line, View.End_Line, View.Fingerprint);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Model.Generic_View_Total := Model.Generic_View_Total + 1;

      case Info.Severity is
         when Generic_Contract_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Generic_Contract_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Generic_Contract_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      case View.Status is
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Private_Barrier =>
            Model.Private_View_Total := Model.Private_View_Total + 1;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Limited_Barrier =>
            Model.Limited_View_Total := Model.Limited_View_Total + 1;
         when Editor.Ada_Generic_View_Compatibility.Generic_View_Cross_Unit_Unresolved =>
            Model.View_Unresolved_Total := Model.View_Unresolved_Total + 1;
         when others =>
            null;
      end case;
   end Add_Generic_View;

   function Body_Kind
     (Status : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status)
      return Generic_Contract_Diagnostic_Kind
   is
   begin
      case Status is
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Private_View_Barrier =>
            return Generic_Diagnostic_Instantiated_Body_Private_Barrier;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Limited_View_Barrier =>
            return Generic_Diagnostic_Instantiated_Body_Limited_Barrier;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Cross_Unit_Unresolved =>
            return Generic_Diagnostic_Instantiated_Body_Cross_Unit_Unresolved;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Mismatch =>
            return Generic_Diagnostic_Instantiated_Body_Object_Mismatch;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Unknown |
              Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Unknown =>
            return Generic_Diagnostic_Instantiated_Body_Object_Unknown;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_No_Body_Contract =>
            return Generic_Diagnostic_Instantiated_Body_Missing_Body_Contract;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Contract_Mismatch =>
            return Generic_Diagnostic_Instantiated_Body_Contract_Mismatch;
         when others =>
            return Generic_Diagnostic_Contract_Unknown;
      end case;
   end Body_Kind;

   function Body_Message
     (Status : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status)
      return String
   is
   begin
      case Status is
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Private_View_Barrier =>
            return "generic instantiated body substitution is blocked by a private-view barrier";
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Limited_View_Barrier =>
            return "generic instantiated body substitution is blocked by a limited-view incomplete type";
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Cross_Unit_Unresolved =>
            return "generic instantiated body substitution depends on an unresolved cross-unit view";
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Mismatch =>
            return "generic instantiated body substitution does not satisfy the formal object contract";
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Unknown |
              Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Unknown =>
            return "generic instantiated body substitution could not be fully classified";
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_No_Body_Contract =>
            return "generic instantiated body contract is missing or not visible";
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Contract_Mismatch =>
            return "generic instantiated body actual contract does not match the generic formal contract";
         when others =>
            return "generic instantiated body substitution produced no diagnostic";
      end case;
   end Body_Message;

   function Body_Detail
     (Info : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Info)
      return String
   is
   begin
      return "formal " & To_String (Info.Formal_Name) &
        " subtype " & To_String (Info.Formal_Subtype) &
        " actual " & To_String (Info.Actual_Text) &
        " target " & To_String (Info.Cross_Unit_Target) &
        " selector " & To_String (Info.Cross_Unit_Selector);
   end Body_Detail;

   procedure Add_Instantiated_Body
     (Model : in out Generic_Contract_Diagnostic_Model;
      Body_Info  : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Info)
   is
      Kind : constant Generic_Contract_Diagnostic_Kind := Body_Kind (Body_Info.Status);
      Info : Generic_Contract_Diagnostic_Info;
   begin
      if Kind = Generic_Diagnostic_Contract_Unknown then
         return;
      end if;

      Info.Id := Generic_Contract_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Node := Body_Info.Instance_Node;
      Info.Instance := Body_Info.Instance;
      Info.Formal := Body_Info.Formal;
      Info.Kind := Kind;
      Info.Severity := Generic_Contract_Diagnostic_Error;
      if Body_Info.Status in
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Object_Unknown |
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Unknown |
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_No_Body_Contract
      then
         Info.Severity := Generic_Contract_Diagnostic_Warning;
      end if;
      Info.Message := To_Unbounded_String (Body_Message (Body_Info.Status));
      Info.Detail := To_Unbounded_String (Body_Detail (Body_Info));
      Info.Start_Line := Body_Info.Start_Line;
      Info.End_Line := Body_Info.End_Line;
      Info.From_Instantiated_Body := True;
      Info.Instantiated_Body := Body_Info.Id;
      Info.Instantiated_Body_Status := Body_Info.Status;
      Info.Instantiated_Body_Fingerprint := Body_Info.Fingerprint;
      if Body_Info.Status =
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_No_Body_Contract
      then
         Info.Body_Contract := Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility;
      else
         Info.Body_Contract := Body_Info.Body_Contract;
      end if;
      Info.Generic_View := Body_Info.Generic_View;
      Info.Generic_View_Status := Body_Info.Generic_View_Status;
      Info.Generic_View_Fingerprint := Body_Info.Fingerprint;
      Info.Fingerprint := Make_Fingerprint
        (Kind, Info.Severity, Body_Info.Start_Line, Body_Info.End_Line, Body_Info.Fingerprint);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Model.Instantiated_Body_Total := Model.Instantiated_Body_Total + 1;

      case Info.Severity is
         when Generic_Contract_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Generic_Contract_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Generic_Contract_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      case Body_Info.Status is
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Private_View_Barrier =>
            Model.Body_Private_Barrier_Total := Model.Body_Private_Barrier_Total + 1;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Limited_View_Barrier =>
            Model.Body_Limited_Barrier_Total := Model.Body_Limited_Barrier_Total + 1;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Cross_Unit_Unresolved =>
            Model.Body_Unresolved_Total := Model.Body_Unresolved_Total + 1;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_No_Body_Contract =>
            Model.Body_Missing_Contract_Total := Model.Body_Missing_Contract_Total + 1;
         when Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Contract_Mismatch =>
            Model.Body_Contract_Mismatch_Total := Model.Body_Contract_Mismatch_Total + 1;
         when others =>
            null;
      end case;
   end Add_Instantiated_Body;


   function Package_Substitution_Kind
     (Status : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status)
      return Generic_Contract_Diagnostic_Kind
   is
   begin
      case Status is
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Mismatch =>
            return Generic_Diagnostic_Formal_Package_Substitution_Mismatch;
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Missing =>
            return Generic_Diagnostic_Formal_Package_Substitution_Missing;
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Wrong_Generic =>
            return Generic_Diagnostic_Formal_Package_Substitution_Wrong_Generic;
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Unresolved =>
            return Generic_Diagnostic_Formal_Package_Substitution_Unresolved;
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Malformed |
              Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Unknown =>
            return Generic_Diagnostic_Formal_Package_Substitution_Unknown;
         when others =>
            return Generic_Diagnostic_Contract_Unknown;
      end case;
   end Package_Substitution_Kind;

   function Package_Substitution_Message
     (Status : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status)
      return String
   is
   begin
      case Status is
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Mismatch =>
            return "formal package nested actual does not match the actual package instance substitution";
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Missing =>
            return "formal package nested actual is missing from the actual package instance substitution";
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Wrong_Generic =>
            return "formal package actual is an instance of a different generic unit";
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Unresolved =>
            return "formal package actual instance could not be resolved for nested substitution";
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Malformed |
              Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Unknown =>
            return "formal package nested substitution could not be classified precisely";
         when others =>
            return "formal package nested substitution produced no diagnostic";
      end case;
   end Package_Substitution_Message;

   function Package_Substitution_Detail
     (Info : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Info)
      return String
   is
   begin
      return "formal " & To_String (Info.Formal_Name) &
        " position" & Positive'Image (Info.Nested_Position) &
        " expected " & To_String (Info.Formal_Actual_Text) &
        " actual " & To_String (Info.Actual_Actual_Text) &
        " generic " & To_String (Info.Expected_Generic);
   end Package_Substitution_Detail;

   procedure Add_Package_Substitution
     (Model : in out Generic_Contract_Diagnostic_Model;
      Item  : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Info)
   is
      Kind : constant Generic_Contract_Diagnostic_Kind :=
        Package_Substitution_Kind (Item.Status);
      Info : Generic_Contract_Diagnostic_Info;
   begin
      if Kind = Generic_Diagnostic_Contract_Unknown then
         return;
      end if;

      Info.Id := Generic_Contract_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Node := Item.Instance_Node;
      Info.Instance := Item.Instance;
      Info.Formal := Item.Formal;
      Info.Kind := Kind;
      Info.Severity := Generic_Contract_Diagnostic_Error;
      if Item.Status in
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Malformed |
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Unknown
      then
         Info.Severity := Generic_Contract_Diagnostic_Warning;
      end if;
      Info.Message := To_Unbounded_String (Package_Substitution_Message (Item.Status));
      Info.Detail := To_Unbounded_String (Package_Substitution_Detail (Item));
      Info.Start_Line := Item.Start_Line;
      Info.End_Line := Item.End_Line;
      Info.From_Formal_Package_Substitution := True;
      Info.Formal_Package_Substitution := Item.Id;
      Info.Formal_Package_Substitution_Status := Item.Status;
      Info.Formal_Package_Substitution_Fingerprint := Item.Fingerprint;
      Info.Nested_Position := Item.Nested_Position;
      Info.Fingerprint := Make_Fingerprint
        (Kind, Info.Severity, Item.Start_Line, Item.End_Line, Item.Fingerprint);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      Model.Formal_Package_Substitution_Total := Model.Formal_Package_Substitution_Total + 1;

      case Info.Severity is
         when Generic_Contract_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Generic_Contract_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Generic_Contract_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      case Item.Status is
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Mismatch |
              Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Wrong_Generic =>
            Model.Formal_Package_Substitution_Mismatch_Total :=
              Model.Formal_Package_Substitution_Mismatch_Total + 1;
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Missing =>
            Model.Formal_Package_Substitution_Missing_Total :=
              Model.Formal_Package_Substitution_Missing_Total + 1;
         when Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Unresolved =>
            Model.Formal_Package_Substitution_Unresolved_Total :=
              Model.Formal_Package_Substitution_Unresolved_Total + 1;
         when others =>
            null;
      end case;
   end Add_Package_Substitution;


   procedure Clear (Model : in out Generic_Contract_Diagnostic_Model) is
   begin
      Model.Diagnostics.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Generic_View_Total := 0;
      Model.Private_View_Total := 0;
      Model.Limited_View_Total := 0;
      Model.View_Unresolved_Total := 0;
      Model.Instantiated_Body_Total := 0;
      Model.Body_Private_Barrier_Total := 0;
      Model.Body_Limited_Barrier_Total := 0;
      Model.Body_Unresolved_Total := 0;
      Model.Body_Missing_Contract_Total := 0;
      Model.Body_Contract_Mismatch_Total := 0;
      Model.Formal_Package_Substitution_Total := 0;
      Model.Formal_Package_Substitution_Mismatch_Total := 0;
      Model.Formal_Package_Substitution_Missing_Total := 0;
      Model.Formal_Package_Substitution_Unresolved_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model)
      return Generic_Contract_Diagnostic_Model
   is
      Model : Generic_Contract_Diagnostic_Model;
      use type Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Status;
      use type Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Status;
      use type Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Status;
      use type Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Status;
      use type Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Status;
   begin
      for Index in 1 .. Editor.Ada_Generic_Formal_Type_Conformance.Check_Count (Formal_Types) loop
         declare
            Info : constant Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Info :=
              Editor.Ada_Generic_Formal_Type_Conformance.Check_At (Formal_Types, Index);
         begin
            if Info.Status in
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Category_Mismatch |
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Base_Mismatch
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Formal_Type_Mismatch,
                    Generic_Contract_Diagnostic_Error,
                    "generic actual type does not conform to formal type contract",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Actual_Missing |
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Actual_Unresolved |
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Private_View_Unknown |
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Access_Designated_Unknown |
              Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Unsupported
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Formal_Type_Unresolved,
                    Generic_Contract_Diagnostic_Warning,
                    "generic formal type conformance is unresolved or unsupported",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_Count (Nested_Packages) loop
         declare
            Info : constant Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Info :=
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Check_At (Nested_Packages, Index);
         begin
            if Info.Status in
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Mismatch |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Missing |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Wrong_Generic |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Not_Instance |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Malformed
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Formal_Package_Nested_Mismatch,
                    Generic_Contract_Diagnostic_Error,
                    "formal package nested actuals do not conform to the supplied package instance",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Actual_Unresolved |
              Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Unknown
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Formal_Package_Nested_Unresolved,
                    Generic_Contract_Diagnostic_Warning,
                    "formal package nested actual conformance is unresolved",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Renaming_Visibility.Renaming_Count (Renamings) loop
         declare
            Info : constant Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Info :=
              Editor.Ada_Generic_Renaming_Visibility.Renaming_At (Renamings, Index);
         begin
            if Info.Status /= Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Target_Resolved then
               Add (Model, Info.Node, Editor.Ada_Generic_Contracts.No_Generic_Instance,
                    Editor.Ada_Generic_Contracts.No_Generic_Formal,
                    Generic_Diagnostic_Generic_Renaming_Error,
                    Generic_Contract_Diagnostic_Error,
                    "generic renaming target is not a resolved generic declaration",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Renaming_Visibility.Nested_Instantiation_Count (Renamings) loop
         declare
            Info : constant Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Info :=
              Editor.Ada_Generic_Renaming_Visibility.Nested_Instantiation_At (Renamings, Index);
         begin
            if Info.Status not in
              Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Direct_Target |
              Editor.Ada_Generic_Renaming_Visibility.Nested_Generic_Instantiation_Renamed_Target
            then
               Add (Model, Info.Instance_Node, Info.Instance,
                    Editor.Ada_Generic_Contracts.No_Generic_Formal,
                    Generic_Diagnostic_Nested_Instantiation_Error,
                    Generic_Contract_Diagnostic_Error,
                    "nested generic instantiation target is not a resolved generic declaration",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Generic_Object_Default_Type_Conformance.Check_Count (Object_Defaults) loop
         declare
            Info : constant Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Info :=
              Editor.Ada_Generic_Object_Default_Type_Conformance.Check_At (Object_Defaults, Index);
         begin
            if Info.Status in
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Type_Mismatch |
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Type_Mismatch
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Object_Default_Type_Mismatch,
                    Generic_Contract_Diagnostic_Error,
                    "generic formal object default or actual has incompatible subtype",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            elsif Info.Status =
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Static_Range_Error
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Object_Default_Range_Error,
                    Generic_Contract_Diagnostic_Error,
                    "generic formal object default or actual is outside the formal subtype range",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Static_Value_Unknown |
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Formal_Subtype_Unknown |
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Actual_Missing |
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Default_Missing |
              Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Unsupported
            then
               Add (Model, Info.Instance_Node, Info.Instance, Info.Formal,
                    Generic_Diagnostic_Object_Default_Unknown,
                    Generic_Contract_Diagnostic_Warning,
                    "generic formal object default or actual type conformance is unresolved",
                    Info.Start_Line, Info.End_Line, Info.Fingerprint);
            end if;
         end;
      end loop;

      return Model;
   end Build;

   function Build_With_View_Compatibility
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model)
      return Generic_Contract_Diagnostic_Model
   is
      Model : Generic_Contract_Diagnostic_Model :=
        Build (Formal_Types, Nested_Packages, Renamings, Object_Defaults);
   begin
      for Index in 1 .. Editor.Ada_Generic_View_Compatibility.Entry_Count (Generic_Views) loop
         declare
            View : constant Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Info :=
              Editor.Ada_Generic_View_Compatibility.Entry_At (Generic_Views, Index);
         begin
            Add_Generic_View (Model, View);
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Mix (Model.Generic_View_Total,
                  Mix (Model.Private_View_Total,
                       Mix (Model.Limited_View_Total, Model.View_Unresolved_Total))));
      return Model;
   end Build_With_View_Compatibility;

   function Build_With_View_Compatibility_And_Body_Analysis
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
      Bodies : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model)
      return Generic_Contract_Diagnostic_Model
   is
      Model : Generic_Contract_Diagnostic_Model :=
        Build_With_View_Compatibility
          (Formal_Types, Nested_Packages, Renamings, Object_Defaults, Generic_Views);
   begin
      for Index in 1 .. Editor.Ada_Generic_Instantiated_Body_Analysis.Substitution_Count (Bodies) loop
         declare
            Body_Info : constant Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Info :=
              Editor.Ada_Generic_Instantiated_Body_Analysis.Substitution_At (Bodies, Index);
         begin
            Add_Instantiated_Body (Model, Body_Info);
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Mix (Editor.Ada_Generic_Instantiated_Body_Analysis.Fingerprint (Bodies),
                  Mix (Model.Instantiated_Body_Total,
                       Mix (Model.Body_Private_Barrier_Total,
                            Mix (Model.Body_Limited_Barrier_Total,
                                 Mix (Model.Body_Unresolved_Total,
                                      Mix (Model.Body_Missing_Contract_Total,
                                           Model.Body_Contract_Mismatch_Total)))))));
      return Model;
   end Build_With_View_Compatibility_And_Body_Analysis;

   function Build_With_Formal_Package_Substitutions
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
      Bodies : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model;
      Substitutions : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model)
      return Generic_Contract_Diagnostic_Model
   is
      Model : Generic_Contract_Diagnostic_Model :=
        Build_With_View_Compatibility_And_Body_Analysis
          (Formal_Types, Nested_Packages, Renamings, Object_Defaults, Generic_Views, Bodies);
   begin
      for Index in 1 .. Editor.Ada_Generic_Formal_Package_Substitutions.Substitution_Count (Substitutions) loop
         declare
            Item : constant Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Info :=
              Editor.Ada_Generic_Formal_Package_Substitutions.Substitution_At (Substitutions, Index);
         begin
            Add_Package_Substitution (Model, Item);
         end;
      end loop;

      Model.Result_Fingerprint :=
        Mix (Model.Result_Fingerprint,
             Mix (Editor.Ada_Generic_Formal_Package_Substitutions.Fingerprint (Substitutions),
                  Mix (Model.Formal_Package_Substitution_Total,
                       Mix (Model.Formal_Package_Substitution_Mismatch_Total,
                            Mix (Model.Formal_Package_Substitution_Missing_Total,
                                 Model.Formal_Package_Substitution_Unresolved_Total)))));
      return Model;
   end Build_With_Formal_Package_Substitutions;

   function Has_Diagnostics (Model : Generic_Contract_Diagnostic_Model) return Boolean is
   begin
      return not Model.Diagnostics.Is_Empty;
   end Has_Diagnostics;

   function Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (Model : Generic_Contract_Diagnostic_Model;
      Index : Natural) return Generic_Contract_Diagnostic_Info is
   begin
      if Index = 0 or else Index > Natural (Model.Diagnostics.Length) then
         return (others => <>);
      end if;

      return Model.Diagnostics.Element (Positive (Index));
   end Diagnostic_At;

   function Diagnostic_For_Node
     (Model : Generic_Contract_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Contract_Diagnostic_Info
   is
      use type Editor.Ada_Syntax_Tree.Node_Id;
   begin
      for Info of Model.Diagnostics loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return (others => <>);
   end Diagnostic_For_Node;

   function Error_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Count_Kind
     (Model : Generic_Contract_Diagnostic_Model;
      Kind  : Generic_Contract_Diagnostic_Kind) return Natural
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

   function Generic_View_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Generic_View_Total;
   end Generic_View_Diagnostic_Count;

   function Private_View_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Private_View_Total;
   end Private_View_Diagnostic_Count;

   function Limited_View_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Limited_View_Total;
   end Limited_View_Diagnostic_Count;

   function View_Unresolved_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.View_Unresolved_Total;
   end View_Unresolved_Diagnostic_Count;

   function Instantiated_Body_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Instantiated_Body_Total;
   end Instantiated_Body_Diagnostic_Count;

   function Body_Private_Barrier_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Body_Private_Barrier_Total;
   end Body_Private_Barrier_Diagnostic_Count;

   function Body_Limited_Barrier_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Body_Limited_Barrier_Total;
   end Body_Limited_Barrier_Diagnostic_Count;

   function Body_Unresolved_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Body_Unresolved_Total;
   end Body_Unresolved_Diagnostic_Count;

   function Body_Missing_Contract_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Body_Missing_Contract_Total;
   end Body_Missing_Contract_Diagnostic_Count;

   function Body_Contract_Mismatch_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Body_Contract_Mismatch_Total;
   end Body_Contract_Mismatch_Diagnostic_Count;

   function Formal_Package_Substitution_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Formal_Package_Substitution_Total;
   end Formal_Package_Substitution_Diagnostic_Count;

   function Formal_Package_Substitution_Mismatch_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Formal_Package_Substitution_Mismatch_Total;
   end Formal_Package_Substitution_Mismatch_Count;

   function Formal_Package_Substitution_Missing_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Formal_Package_Substitution_Missing_Total;
   end Formal_Package_Substitution_Missing_Count;

   function Formal_Package_Substitution_Unresolved_Count (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Formal_Package_Substitution_Unresolved_Total;
   end Formal_Package_Substitution_Unresolved_Count;

   function Fingerprint (Model : Generic_Contract_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Contract_Diagnostics;
