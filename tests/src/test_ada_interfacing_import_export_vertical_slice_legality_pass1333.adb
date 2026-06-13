with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality;

package body Test_Ada_Interfacing_Import_Export_Vertical_Slice_Legality_Pass1333 is

   package IEL renames Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality;
   use type IEL.Entity_Id;
   use type IEL.Item_Id;
   use type IEL.Check_Id;
   use type IEL.Result_Id;
   use type IEL.Entity_Kind;
   use type IEL.Convention_Kind;
   use type IEL.Interfacing_Item_Kind;
   use type IEL.Check_Kind;
   use type IEL.View_Kind;
   use type IEL.Legality_Status;
   use type IEL.Entity_Info;
   use type IEL.Entity_Model;
   use type IEL.Item_Info;
   use type IEL.Item_Model;
   use type IEL.Check_Info;
   use type IEL.Check_Model;
   use type IEL.Result_Info;
   use type IEL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Interfacing_Import_Export_Vertical_Slice_Legality_Pass1333");
   end Name;

   procedure Add_Entity
     (Model : in out IEL.Entity_Model;
      Id : Natural;
      Name : String;
      Kind : IEL.Entity_Kind;
      View : IEL.View_Kind := IEL.View_Full;
      Convention : IEL.Convention_Kind := IEL.Convention_Ada;
      Has_Convention : Boolean := True;
      Imported : Boolean := False;
      Exported : Boolean := False;
      Has_External_Name : Boolean := False;
      External_Static : Boolean := True;
      Has_Link_Name : Boolean := False;
      Link_Static : Boolean := True;
      Address_Static : Boolean := True;
      Storage_Static : Boolean := True;
      Storage_OK : Boolean := True;
      C_Profile_OK : Boolean := True;
      Subprogram_Access_Profile_OK : Boolean := True;
      Subprogram_Access_Convention_OK : Boolean := True;
      Stream_Conflict : Boolean := False;
      Duplicate : Boolean := False;
      Source_FP : Natural := 133300;
      AST_FP : Natural := 233300;
      Entity_FP : Natural := 333300;
      Profile_FP : Natural := 433300;
      Representation_FP : Natural := 533300;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Entity_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Representation_FP : Natural := 0)
   is
      E : IEL.Entity_Info;
   begin
      E.Id := IEL.Entity_Id (Id);
      E.Name := To_Unbounded_String (Name);
      E.Node := Editor.Ada_Syntax_Tree.Node_Id (133300 + Id);
      E.Kind := Kind;
      E.View := View;
      E.Convention := Convention;
      E.Has_Convention := Has_Convention;
      E.Is_Imported := Imported;
      E.Is_Exported := Exported;
      E.Has_External_Name := Has_External_Name;
      E.External_Name_Static := External_Static;
      E.Has_Link_Name := Has_Link_Name;
      E.Link_Name_Static := Link_Static;
      E.Address_Static := Address_Static;
      E.Storage_Size_Static := Storage_Static;
      E.Storage_Size_Compatible := Storage_OK;
      E.Profile_C_Compatible := C_Profile_OK;
      E.Access_Profile_Compatible := Subprogram_Access_Profile_OK;
      E.Access_Convention_Compatible := Subprogram_Access_Convention_OK;
      E.Stream_External_Conflict := Stream_Conflict;
      E.Duplicate_Item := Duplicate;
      E.Source_Fingerprint := Source_FP + Id;
      E.AST_Fingerprint := AST_FP + Id;
      E.Entity_Fingerprint := Entity_FP + Id;
      E.Profile_Fingerprint := Profile_FP + Id;
      E.Representation_Fingerprint := Representation_FP + Id;
      E.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      E.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      E.Expected_Entity_Fingerprint :=
        (if Expected_Entity_FP = 0 then Entity_FP + Id else Expected_Entity_FP);
      E.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      E.Expected_Representation_Fingerprint :=
        (if Expected_Representation_FP = 0 then Representation_FP + Id else Expected_Representation_FP);
      IEL.Add_Entity (Model, E);
   end Add_Entity;

   procedure Add_Item
     (Model : in out IEL.Item_Model;
      Id : Natural;
      Name : String;
      Kind : IEL.Interfacing_Item_Kind;
      Target : Natural;
      Convention : IEL.Convention_Kind := IEL.Convention_Unknown;
      External_Name : Boolean := False;
      External_Static : Boolean := True;
      Link_Name : Boolean := False;
      Link_Static : Boolean := True;
      Address_Static : Boolean := True;
      Storage_Static : Boolean := True;
      Storage_OK : Boolean := True;
      Duplicate : Boolean := False;
      Source_FP : Natural := 633300;
      AST_FP : Natural := 733300;
      Representation_FP : Natural := 833300;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Representation_FP : Natural := 0)
   is
      I : IEL.Item_Info;
   begin
      I.Id := IEL.Item_Id (Id);
      I.Name := To_Unbounded_String (Name);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (233300 + Id);
      I.Kind := Kind;
      I.Target := IEL.Entity_Id (Target);
      I.Convention := Convention;
      I.External_Name_Present := External_Name;
      I.External_Name_Static := External_Static;
      I.Link_Name_Present := Link_Name;
      I.Link_Name_Static := Link_Static;
      I.Address_Static := Address_Static;
      I.Storage_Size_Static := Storage_Static;
      I.Storage_Size_Compatible := Storage_OK;
      I.Duplicate_Item := Duplicate;
      I.Source_Fingerprint := Source_FP + Id;
      I.AST_Fingerprint := AST_FP + Id;
      I.Representation_Fingerprint := Representation_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      I.Expected_Representation_Fingerprint :=
        (if Expected_Representation_FP = 0 then Representation_FP + Id else Expected_Representation_FP);
      IEL.Add_Item (Model, I);
   end Add_Item;

   procedure Add_Check
     (Model : in out IEL.Check_Model;
      Id : Natural;
      Name : String;
      Kind : IEL.Check_Kind;
      Target : Natural := 0;
      Item : Natural := 0;
      Expected_Kind : IEL.Entity_Kind := IEL.Entity_Unknown;
      Expected_Convention : IEL.Convention_Kind := IEL.Convention_Unknown;
      Convention_Allowed : Boolean := True;
      Requires_Import : Boolean := False;
      Requires_Export : Boolean := False;
      Requires_External : Boolean := False;
      Requires_Link : Boolean := False;
      Requires_Address_Static : Boolean := False;
      Requires_Storage_Static : Boolean := False;
      Requires_C_Profile : Boolean := False;
      Requires_Access_Profile : Boolean := False;
      Requires_Access_Convention : Boolean := False;
      Reject_Import_Export : Boolean := True;
      Reject_Stream_External : Boolean := True;
      Source_FP : Natural := 933300;
      AST_FP : Natural := 1_033_300;
      Entity_FP : Natural := 1_133_300;
      Profile_FP : Natural := 1_233_300;
      Representation_FP : Natural := 1_333_300;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Entity_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Representation_FP : Natural := 0)
   is
      C : IEL.Check_Info;
   begin
      C.Id := IEL.Check_Id (Id);
      C.Name := To_Unbounded_String (Name);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (333300 + Id);
      C.Kind := Kind;
      C.Target := IEL.Entity_Id (Target);
      C.Item := IEL.Item_Id (Item);
      C.Expected_Entity_Kind := Expected_Kind;
      C.Expected_Convention := Expected_Convention;
      C.Convention_Allowed := Convention_Allowed;
      C.Requires_Import_Target := Requires_Import;
      C.Requires_Export_Target := Requires_Export;
      C.Requires_External_Name := Requires_External;
      C.Requires_Link_Name := Requires_Link;
      C.Requires_Address_Static := Requires_Address_Static;
      C.Requires_Storage_Static := Requires_Storage_Static;
      C.Requires_C_Compatible_Profile := Requires_C_Profile;
      C.Requires_Access_Profile_Compatible := Requires_Access_Profile;
      C.Requires_Access_Convention_Compatible := Requires_Access_Convention;
      C.Reject_Import_Export_Conflict := Reject_Import_Export;
      C.Reject_Stream_External_Conflict := Reject_Stream_External;
      C.Source_Fingerprint := Source_FP + Id;
      C.AST_Fingerprint := AST_FP + Id;
      C.Entity_Fingerprint := Entity_FP + Id;
      C.Profile_Fingerprint := Profile_FP + Id;
      C.Representation_Fingerprint := Representation_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      C.Expected_Entity_Fingerprint :=
        (if Expected_Entity_FP = 0 then Entity_FP + Id else Expected_Entity_FP);
      C.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      C.Expected_Representation_Fingerprint :=
        (if Expected_Representation_FP = 0 then Representation_FP + Id else Expected_Representation_FP);
      IEL.Add_Check (Model, C);
   end Add_Check;

   procedure Expect_Status
     (Results : IEL.Result_Model;
      Index : Positive;
      Status : IEL.Legality_Status) is
   begin
      Assert
        (IEL.Result_At (Results, Index).Status = Status,
         "unexpected interfacing/import/export legality status");
   end Expect_Status;

   procedure Test_Convention_Import_And_Export_Legality

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : IEL.Entity_Model;
      Items : IEL.Item_Model;
      Checks : IEL.Check_Model;
      Results : IEL.Result_Model;
   begin
      Add_Entity
        (Entities, 1, "C_Puts", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C, Imported => True,
         Has_External_Name => True, C_Profile_OK => True);
      Add_Entity
        (Entities, 2, "Ada_Only", IEL.Entity_Subprogram,
         Convention => IEL.Convention_Ada, Imported => True,
         Has_External_Name => True);
      Add_Entity
        (Entities, 3, "Pkg", IEL.Entity_Package,
         Convention => IEL.Convention_C, Imported => True,
         Has_External_Name => True);
      Add_Entity
        (Entities, 4, "Exported_CB", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C, Exported => True,
         Has_Link_Name => True);
      Add_Item
        (Items, 1, "Import C_Puts", IEL.Item_Import, Target => 1,
         External_Name => True);
      Add_Item
        (Items, 2, "Export Callback", IEL.Item_Export, Target => 4,
         Link_Name => True);

      Add_Check
        (Checks, 1, "C convention accepted", IEL.Check_Convention,
         Target => 1, Expected_Convention => IEL.Convention_C);
      Add_Check
        (Checks, 2, "Ada convention mismatch", IEL.Check_Convention,
         Target => 2, Expected_Convention => IEL.Convention_C);
      Add_Check
        (Checks, 3, "import package rejected", IEL.Check_Import,
         Target => 3, Item => 1, Requires_Import => True,
         Requires_External => True);
      Add_Check
        (Checks, 4, "export callback accepted", IEL.Check_Export,
         Target => 4, Item => 2, Requires_Export => True,
         Requires_Link => True);

      Results := IEL.Build (Entities, Items, Checks);
      Assert (IEL.Count (Results) = 4, "expected four import/export checks");
      Expect_Status (Results, 1, IEL.Legality_Legal);
      Expect_Status (Results, 2, IEL.Legality_Convention_Mismatch);
      Expect_Status (Results, 3, IEL.Legality_Import_Target_Mismatch);
      Expect_Status (Results, 4, IEL.Legality_Legal);
   end Test_Convention_Import_And_Export_Legality;

   procedure Test_Names_Address_And_Storage_Attributes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : IEL.Entity_Model;
      Items : IEL.Item_Model;
      Checks : IEL.Check_Model;
      Results : IEL.Result_Model;
   begin
      Add_Entity
        (Entities, 1, "Imported", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C, Imported => True,
         Has_External_Name => False);
      Add_Entity
        (Entities, 2, "Exported", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C, Exported => True,
         Has_Link_Name => True, Link_Static => False);
      Add_Entity
        (Entities, 3, "Obj", IEL.Entity_Object,
         Address_Static => False);
      Add_Entity
        (Entities, 4, "Pool_Type", IEL.Entity_Type,
         Storage_Static => True, Storage_OK => False);
      Add_Item
        (Items, 1, "Dynamic external", IEL.Item_External_Name,
         Target => 1, External_Name => True, External_Static => False);
      Add_Item
        (Items, 2, "Dynamic link", IEL.Item_Link_Name,
         Target => 2, Link_Name => True, Link_Static => False);
      Add_Item
        (Items, 3, "Dynamic address", IEL.Item_Address,
         Target => 3, Address_Static => False);
      Add_Item
        (Items, 4, "Bad storage", IEL.Item_Storage_Size,
         Target => 4, Storage_Static => True, Storage_OK => False);

      Add_Check
        (Checks, 1, "external name must be static", IEL.Check_External_Name,
         Target => 1, Item => 1);
      Add_Check
        (Checks, 2, "link name must be static", IEL.Check_Link_Name,
         Target => 2, Item => 2);
      Add_Check
        (Checks, 3, "address must be static", IEL.Check_Address_Attribute,
         Target => 3, Item => 3, Requires_Address_Static => True);
      Add_Check
        (Checks, 4, "storage size fit", IEL.Check_Storage_Attribute,
         Target => 4, Item => 4, Requires_Storage_Static => True);

      Results := IEL.Build (Entities, Items, Checks);
      Expect_Status (Results, 1, IEL.Legality_External_Name_Not_Static);
      Expect_Status (Results, 2, IEL.Legality_Link_Name_Not_Static);
      Expect_Status (Results, 3, IEL.Legality_Address_Not_Static);
      Expect_Status (Results, 4, IEL.Legality_Storage_Size_Incompatible);
   end Test_Names_Address_And_Storage_Attributes;

   procedure Test_Access_Subprogram_And_C_Profile_Legality

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : IEL.Entity_Model;
      Items : IEL.Item_Model;
      Checks : IEL.Check_Model;
      Results : IEL.Result_Model;
   begin
      Add_Entity
        (Entities, 1, "C_Callback", IEL.Entity_Access_Subprogram,
         Convention => IEL.Convention_C,
         Subprogram_Access_Profile_OK => True,
         Subprogram_Access_Convention_OK => True,
         C_Profile_OK => True);
      Add_Entity
        (Entities, 2, "Bad_Callback", IEL.Entity_Access_Subprogram,
         Convention => IEL.Convention_Ada,
         Subprogram_Access_Profile_OK => False,
         Subprogram_Access_Convention_OK => False,
         C_Profile_OK => False);
      Add_Entity
        (Entities, 3, "Not_Access", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C);

      Add_Check
        (Checks, 1, "access-to-subprogram convention accepted",
         IEL.Check_Access_Subprogram_Convention, Target => 1,
         Requires_Access_Profile => True,
         Requires_Access_Convention => True);
      Add_Check
        (Checks, 2, "access-to-subprogram profile mismatch",
         IEL.Check_Access_Subprogram_Convention, Target => 2,
         Requires_Access_Profile => True,
         Requires_Access_Convention => False);
      Add_Check
        (Checks, 3, "not an access-to-subprogram type",
         IEL.Check_Access_Subprogram_Convention, Target => 3,
         Requires_Access_Profile => True);
      Add_Check
        (Checks, 4, "C profile rejected",
         IEL.Check_C_Compatible_Profile, Target => 2,
         Expected_Convention => IEL.Convention_C,
         Requires_C_Profile => True);

      Results := IEL.Build (Entities, Items, Checks);
      Expect_Status (Results, 1, IEL.Legality_Legal);
      Expect_Status (Results, 2, IEL.Legality_Access_Profile_Mismatch);
      Expect_Status (Results, 3, IEL.Legality_Entity_Kind_Mismatch);
      Expect_Status (Results, 4, IEL.Legality_Multiple_Blockers);
   end Test_Access_Subprogram_And_C_Profile_Legality;

   procedure Test_Conflicts_Views_And_Freshness

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : IEL.Entity_Model;
      Items : IEL.Item_Model;
      Checks : IEL.Check_Model;
      Results : IEL.Result_Model;
   begin
      Add_Entity
        (Entities, 1, "Both", IEL.Entity_Subprogram,
         Imported => True, Exported => True,
         Convention => IEL.Convention_C);
      Add_Entity
        (Entities, 2, "Streamed", IEL.Entity_Type,
         Stream_Conflict => True);
      Add_Entity
        (Entities, 3, "Private_Type", IEL.Entity_Type,
         View => IEL.View_Private);
      Add_Entity
        (Entities, 4, "Stale", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C,
         Expected_Entity_FP => 42);
      Add_Item
        (Items, 1, "Duplicate convention", IEL.Item_Convention,
         Target => 2, Duplicate => True);

      Add_Check
        (Checks, 1, "import/export conflict", IEL.Check_Import,
         Target => 1, Requires_Import => True,
         Reject_Import_Export => True);
      Add_Check
        (Checks, 2, "stream external conflict", IEL.Check_Representation_Conflict,
         Target => 2, Item => 1);
      Add_Check
        (Checks, 3, "private view barrier", IEL.Check_Storage_Attribute,
         Target => 3, Requires_Storage_Static => True);
      Add_Check
        (Checks, 4, "stale entity fingerprint", IEL.Check_Convention,
         Target => 4, Expected_Convention => IEL.Convention_C);

      Results := IEL.Build (Entities, Items, Checks);
      Expect_Status (Results, 1, IEL.Legality_Import_Export_Conflict);
      Expect_Status (Results, 2, IEL.Legality_Multiple_Blockers);
      Expect_Status (Results, 3, IEL.Legality_Private_View_Barrier);
      Expect_Status (Results, 4, IEL.Legality_Entity_Fingerprint_Mismatch);
   end Test_Conflicts_Views_And_Freshness;

   procedure Test_Missing_Evidence_And_Unknown_Check

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : IEL.Entity_Model;
      Items : IEL.Item_Model;
      Checks : IEL.Check_Model;
      Results : IEL.Result_Model;
   begin
      Add_Entity
        (Entities, 1, "Known", IEL.Entity_Subprogram,
         Convention => IEL.Convention_C);

      Add_Check
        (Checks, 1, "missing target", IEL.Check_Convention,
         Target => 99, Expected_Convention => IEL.Convention_C);
      Add_Check
        (Checks, 2, "missing item", IEL.Check_External_Name,
         Target => 1, Item => 77);
      Add_Check
        (Checks, 3, "unknown check", IEL.Check_Unknown,
         Target => 1);

      Results := IEL.Build (Entities, Items, Checks);
      Expect_Status (Results, 1, IEL.Legality_Missing_Entity);
      Expect_Status (Results, 2, IEL.Legality_Multiple_Blockers);
      Expect_Status (Results, 3, IEL.Legality_Missing_Check);
   end Test_Missing_Evidence_And_Unknown_Check;

   procedure Test_Empty_Check_Model_Reports_Missing_Check

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Entities : IEL.Entity_Model;
      Items : IEL.Item_Model;
      Checks : IEL.Check_Model;
      Results : IEL.Result_Model;
   begin
      Results := IEL.Build (Entities, Items, Checks);
      Assert (IEL.Count (Results) = 1, "empty check model should report one blocker");
      Expect_Status (Results, 1, IEL.Legality_Missing_Check);
   end Test_Empty_Check_Model_Reports_Missing_Check;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Convention_Import_And_Export_Legality'Access,
         "convention import export legality");
      Register_Routine
        (T, Test_Names_Address_And_Storage_Attributes'Access,
         "external/link names address and storage attributes");
      Register_Routine
        (T, Test_Access_Subprogram_And_C_Profile_Legality'Access,
         "access-to-subprogram and C profile legality");
      Register_Routine
        (T, Test_Conflicts_Views_And_Freshness'Access,
         "conflicts view barriers and stale fingerprints");
      Register_Routine
        (T, Test_Missing_Evidence_And_Unknown_Check'Access,
         "missing evidence and unknown check");
      Register_Routine
        (T, Test_Empty_Check_Model_Reports_Missing_Check'Access,
         "empty check model reports missing check");
   end Register_Tests;

end Test_Ada_Interfacing_Import_Export_Vertical_Slice_Legality_Pass1333;
