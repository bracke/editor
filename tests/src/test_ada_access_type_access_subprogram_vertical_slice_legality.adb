with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality;

package body Test_Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality is

   package AL renames Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality;
   use type AL.Access_Type_Id;
   use type AL.Designated_Type_Id;
   use type AL.Profile_Id;
   use type AL.Pool_Id;
   use type AL.Result_Id;
   use type AL.Access_Kind;
   use type AL.Access_Context_Kind;
   use type AL.Designated_View_Kind;
   use type AL.Access_Status;
   use type AL.Access_Type_Info;
   use type AL.Designated_Type_Info;
   use type AL.Profile_Info;
   use type AL.Access_Use_Info;
   use type AL.Result_Info;
   use type AL.Access_Type_Model;
   use type AL.Designated_Type_Model;
   use type AL.Profile_Model;
   use type AL.Use_Model;
   use type AL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality");
   end Name;

   procedure Add_Designated
     (Model : in out AL.Designated_Type_Model;
      Id : Natural;
      Name : String;
      View : AL.Designated_View_Kind := AL.View_Full;
      Limited_View : Boolean := False;
      Incomplete : Boolean := False;
      Master : Natural := 0;
      Source_FP : Natural := 132400;
      Type_FP : Natural := 232400;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      D : AL.Designated_Type_Info;
   begin
      D.Id := AL.Designated_Type_Id (Id);
      D.Name := To_Unbounded_String (Name);
      D.Node := Editor.Ada_Syntax_Tree.Node_Id (132400 + Id);
      D.View := View;
      D.Is_Limited := Limited_View;
      D.Is_Incomplete := Incomplete;
      D.Master_Depth := Master;
      D.Source_Fingerprint := Source_FP + Id;
      D.Type_Fingerprint := Type_FP + Id;
      D.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      D.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      AL.Add_Designated_Type (Model, D);
   end Add_Designated;

   procedure Add_Access
     (Model : in out AL.Access_Type_Model;
      Id : Natural;
      Name : String;
      Kind : AL.Access_Kind;
      Designated : Natural := 0;
      Profile : Natural := 0;
      Null_Exclusion : Boolean := False;
      Pool : Natural := 0;
      Storage_Static : Boolean := True;
      Storage_OK : Boolean := True;
      Source_FP : Natural := 332400;
      Type_FP : Natural := 432400;
      Pool_FP : Natural := 532400;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Pool_FP : Natural := 0)
   is
      A : AL.Access_Type_Info;
   begin
      A.Id := AL.Access_Type_Id (Id);
      A.Name := To_Unbounded_String (Name);
      A.Node := Editor.Ada_Syntax_Tree.Node_Id (232400 + Id);
      A.Kind := Kind;
      A.Designated := AL.Designated_Type_Id (Designated);
      A.Profile := AL.Profile_Id (Profile);
      A.Null_Exclusion := Null_Exclusion;
      A.Storage_Pool := AL.Pool_Id (Pool);
      A.Storage_Size_Static := Storage_Static;
      A.Storage_Size_Compatible := Storage_OK;
      A.Source_Fingerprint := Source_FP + Id;
      A.Type_Fingerprint := Type_FP + Id;
      A.Pool_Fingerprint := Pool_FP + Id;
      A.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      A.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      A.Expected_Pool_Fingerprint :=
        (if Expected_Pool_FP = 0 then Pool_FP + Id else Expected_Pool_FP);
      AL.Add_Access_Type (Model, A);
   end Add_Access;

   procedure Add_Profile
     (Model : in out AL.Profile_Model;
      Id : Natural;
      Name : String;
      Formal_Count : Natural := 1;
      Modes_OK : Boolean := True;
      Types_OK : Boolean := True;
      Nulls_OK : Boolean := True;
      Source_FP : Natural := 632400;
      Profile_FP : Natural := 732400;
      Expected_Source_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0)
   is
      P : AL.Profile_Info;
   begin
      P.Id := AL.Profile_Id (Id);
      P.Name := To_Unbounded_String (Name);
      P.Node := Editor.Ada_Syntax_Tree.Node_Id (332400 + Id);
      P.Formal_Count := Formal_Count;
      P.Convention := To_Unbounded_String ("Ada");
      P.Parameter_Modes_Compatible := Modes_OK;
      P.Type_Profile_Compatible := Types_OK;
      P.Null_Exclusions_Compatible := Nulls_OK;
      P.Source_Fingerprint := Source_FP + Id;
      P.Profile_Fingerprint := Profile_FP + Id;
      P.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      P.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      AL.Add_Profile (Model, P);
   end Add_Profile;

   procedure Add_Use
     (Model : in out AL.Use_Model;
      Id : Natural;
      Access_Type : Natural;
      Expected_Kind : AL.Access_Kind;
      Designated : Natural := 0;
      Profile : Natural := 0;
      Context : AL.Access_Context_Kind := AL.Context_Declaration;
      Null_Required : Boolean := False;
      May_Be_Null : Boolean := False;
      Source_Master : Natural := 0;
      Target_Master : Natural := 0;
      Runtime_Check : Boolean := False;
      Require_Profile : Boolean := False;
      Convention_OK : Boolean := True;
      Require_Pool : Boolean := False;
      Pool : Natural := 0;
      Require_Static_Storage : Boolean := False;
      Storage_Static : Boolean := True;
      Storage_OK : Boolean := True;
      Source_FP : Natural := 832400;
      Type_FP : Natural := 932400;
      Profile_FP : Natural := 1032400;
      Pool_FP : Natural := 1132400;
      Expected_Source_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Pool_FP : Natural := 0)
   is
      U : AL.Access_Use_Info;
   begin
      U.Id := AL.Result_Id (Id);
      U.Access_Type := AL.Access_Type_Id (Access_Type);
      U.Designated := AL.Designated_Type_Id (Designated);
      U.Profile := AL.Profile_Id (Profile);
      U.Node := Editor.Ada_Syntax_Tree.Node_Id (432400 + Id);
      U.Context := Context;
      U.Expected_Kind := Expected_Kind;
      U.Null_Exclusion_Required := Null_Required;
      U.May_Be_Null := May_Be_Null;
      U.Source_Master_Depth := Source_Master;
      U.Target_Master_Depth := Target_Master;
      U.Runtime_Accessibility_Check_Allowed := Runtime_Check;
      U.Requires_Profile_Conformance := Require_Profile;
      U.Convention_Compatible := Convention_OK;
      U.Requires_Storage_Pool := Require_Pool;
      U.Pool := AL.Pool_Id (Pool);
      U.Requires_Static_Storage_Size := Require_Static_Storage;
      U.Storage_Size_Static := Storage_Static;
      U.Storage_Size_Compatible := Storage_OK;
      U.Source_Fingerprint := Source_FP + Id;
      U.Type_Fingerprint := Type_FP + Id;
      U.Profile_Fingerprint := Profile_FP + Id;
      U.Pool_Fingerprint := Pool_FP + Id;
      U.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      U.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      U.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      U.Expected_Pool_Fingerprint :=
        (if Expected_Pool_FP = 0 then Pool_FP + Id else Expected_Pool_FP);
      AL.Add_Use (Model, U);
   end Add_Use;

   procedure Accepts_Source_Shaped_Access_Object_And_Runtime_Check
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Access_Types : AL.Access_Type_Model;
      Designated : AL.Designated_Type_Model;
      Profiles : AL.Profile_Model;
      Uses : AL.Use_Model;
      Results : AL.Result_Model;
   begin
      Add_Designated (Designated, 1, "Node", Master => 1);
      Add_Access (Access_Types, 1, "Node_Access", AL.Access_Object, Designated => 1);
      Add_Use (Uses, 1, 1, AL.Access_Object, Designated => 1, Source_Master => 1, Target_Master => 2);
      Add_Use (Uses, 2, 1, AL.Access_Object, Designated => 1, Source_Master => 3,
               Target_Master => 1, Runtime_Check => True, Context => AL.Context_Conversion);

      Results := AL.Build (Access_Types, Designated, Profiles, Uses);
      Assert (AL.Result_Count (Results) = 2, "two access-object uses are analysed");
      Assert (AL.Count_Status (Results, AL.Access_Legal) = 1, "safe master conversion is legal");
      Assert (AL.Count_Status (Results, AL.Access_Legal_Runtime_Accessibility_Check) = 1,
              "runtime accessibility check contexts remain legal with check evidence");
      Assert (AL.Legal_Count (Results) = 2, "both accepted rows count as legal evidence");
   end Accepts_Source_Shaped_Access_Object_And_Runtime_Check;

   procedure Rejects_Null_Exclusion_And_Accessibility_Escape
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Access_Types : AL.Access_Type_Model;
      Designated : AL.Designated_Type_Model;
      Profiles : AL.Profile_Model;
      Uses : AL.Use_Model;
      Results : AL.Result_Model;
   begin
      Add_Designated (Designated, 1, "Item", Master => 1);
      Add_Access (Access_Types, 1, "Not_Null_Item_Access", AL.Access_Object,
                  Designated => 1, Null_Exclusion => True);
      Add_Use (Uses, 1, 1, AL.Access_Object, Designated => 1,
               May_Be_Null => True, Source_Master => 3, Target_Master => 1);

      Results := AL.Build (Access_Types, Designated, Profiles, Uses);
      Assert (AL.Count_Status (Results, AL.Access_Multiple_Blockers) = 1,
              "null exclusion and static accessibility escape are both preserved");
      Assert (AL.Result_At (Results, 1).Null_Exclusion_Blockers = 1,
              "null value is rejected for not-null access type");
      Assert (AL.Result_At (Results, 1).Accessibility_Blockers = 1,
              "access value cannot escape to a longer-lived master without runtime check");
   end Rejects_Null_Exclusion_And_Accessibility_Escape;

   procedure Checks_Access_To_Subprogram_Profile_Conformance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Access_Types : AL.Access_Type_Model;
      Designated : AL.Designated_Type_Model;
      Profiles : AL.Profile_Model;
      Uses : AL.Use_Model;
      Results : AL.Result_Model;
   begin
      Add_Profile (Profiles, 1, "Callback", Modes_OK => False, Types_OK => True, Nulls_OK => False);
      Add_Access (Access_Types, 1, "Callback_Access", AL.Access_Subprogram, Profile => 1);
      Add_Use (Uses, 1, 1, AL.Access_Subprogram, Profile => 1,
               Context => AL.Context_Subprogram_Access, Require_Profile => True,
               Convention_OK => False);

      Results := AL.Build (Access_Types, Designated, Profiles, Uses);
      Assert (AL.Count_Status (Results, AL.Access_Multiple_Blockers) = 1,
              "profile and convention blockers combine without losing family identity");
      Assert (AL.Result_At (Results, 1).Profile_Conformance_Blockers = 1,
              "access-to-subprogram profile conformance is checked");
      Assert (AL.Result_At (Results, 1).Convention_Blockers = 1,
              "access-to-subprogram convention compatibility is checked");
   end Checks_Access_To_Subprogram_Profile_Conformance;

   procedure Rejects_View_Storage_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Access_Types : AL.Access_Type_Model;
      Designated : AL.Designated_Type_Model;
      Profiles : AL.Profile_Model;
      Uses : AL.Use_Model;
      Results : AL.Result_Model;
   begin
      Add_Designated (Designated, 1, "Hidden", View => AL.View_Private);
      Add_Access (Access_Types, 1, "Hidden_Access", AL.Access_Object,
                  Designated => 1, Pool => 1, Storage_Static => False,
                  Expected_Source_FP => 999999);
      Add_Use (Uses, 1, 1, AL.Access_Object, Designated => 1,
               Require_Pool => True, Pool => 2,
               Require_Static_Storage => True, Storage_Static => False,
               Expected_Type_FP => 999999, Expected_Pool_FP => 999999);

      Results := AL.Build (Access_Types, Designated, Profiles, Uses);
      Assert (AL.Count_Status (Results, AL.Access_Multiple_Blockers) = 1,
              "view, storage, and stale evidence blockers are retained");
      Assert (AL.Result_At (Results, 1).Private_View_Blockers = 1,
              "private designated view blocks access legality");
      Assert (AL.Result_At (Results, 1).Storage_Pool_Conflict_Blockers = 1,
              "conflicting storage pool evidence is rejected");
      Assert (AL.Result_At (Results, 1).Storage_Size_Non_Static_Blockers = 1,
              "static storage-size requirement is enforced");
      Assert (AL.Result_At (Results, 1).Source_Fingerprint_Blockers = 1,
              "stale access-type source evidence is rejected");
      Assert (AL.Result_At (Results, 1).Type_Fingerprint_Blockers = 1,
              "stale use/type evidence is rejected");
      Assert (AL.Result_At (Results, 1).Pool_Fingerprint_Blockers = 1,
              "stale pool evidence is rejected");
   end Rejects_View_Storage_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Access_Object_And_Runtime_Check'Access,
         "accepts access object uses and runtime accessibility checks");
      Register_Routine
        (T, Rejects_Null_Exclusion_And_Accessibility_Escape'Access,
         "rejects null exclusion and accessibility escape blockers");
      Register_Routine
        (T, Checks_Access_To_Subprogram_Profile_Conformance'Access,
         "checks access-to-subprogram profile conformance");
      Register_Routine
        (T, Rejects_View_Storage_And_Fingerprint_Blockers'Access,
         "rejects view storage and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality;
