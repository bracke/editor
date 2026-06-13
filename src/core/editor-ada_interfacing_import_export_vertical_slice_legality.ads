with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality is

   --  Pass1333 vertical-slice legality for interfacing, import, export,
   --  convention, external names, link names, address/storage attributes,
   --  access-to-subprogram conventions, C-compatible profiles, and conflicts
   --  with stream/external representation evidence.  This package consumes
   --  source-shaped semantic evidence and returns deterministic blocker
   --  families; it is not a diagnostic or projection wrapper.

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type Item_Id is new Natural;
   No_Item : constant Item_Id := 0;

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Entity_Kind is
     (Entity_Subprogram,
      Entity_Access_Subprogram,
      Entity_Object,
      Entity_Type,
      Entity_Package,
      Entity_Entry,
      Entity_Unknown);

   type Convention_Kind is
     (Convention_Ada,
      Convention_C,
      Convention_CPP,
      Convention_Intrinsic,
      Convention_Stdcall,
      Convention_Unknown);

   type Interfacing_Item_Kind is
     (Item_Convention,
      Item_Import,
      Item_Export,
      Item_External_Name,
      Item_Link_Name,
      Item_Address,
      Item_Storage_Size,
      Item_Stream_Attribute,
      Item_External_Representation,
      Item_Unknown);

   type Check_Kind is
     (Check_Convention,
      Check_Import,
      Check_Export,
      Check_External_Name,
      Check_Link_Name,
      Check_Address_Attribute,
      Check_Storage_Attribute,
      Check_Access_Subprogram_Convention,
      Check_C_Compatible_Profile,
      Check_Representation_Conflict,
      Check_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Missing_Check,
      Legality_Missing_Entity,
      Legality_Missing_Item,
      Legality_Entity_Kind_Mismatch,
      Legality_Convention_Missing,
      Legality_Convention_Mismatch,
      Legality_Convention_Not_Allowed,
      Legality_Import_Target_Mismatch,
      Legality_Export_Target_Mismatch,
      Legality_External_Name_Missing,
      Legality_External_Name_Not_Static,
      Legality_Link_Name_Missing,
      Legality_Link_Name_Not_Static,
      Legality_Address_Target_Mismatch,
      Legality_Address_Not_Static,
      Legality_Storage_Target_Mismatch,
      Legality_Storage_Size_Not_Static,
      Legality_Storage_Size_Incompatible,
      Legality_Profile_Not_C_Compatible,
      Legality_Access_Profile_Mismatch,
      Legality_Access_Convention_Mismatch,
      Legality_Import_Export_Conflict,
      Legality_Stream_External_Conflict,
      Legality_Duplicate_Interfacing_Item,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Entity_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_Representation_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Entity_Info is record
      Id : Entity_Id := No_Entity;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Entity_Kind := Entity_Unknown;
      View : View_Kind := View_Full;
      Convention : Convention_Kind := Convention_Ada;
      Has_Convention : Boolean := False;
      Is_Imported : Boolean := False;
      Is_Exported : Boolean := False;
      Has_External_Name : Boolean := False;
      External_Name_Static : Boolean := True;
      Has_Link_Name : Boolean := False;
      Link_Name_Static : Boolean := True;
      Address_Static : Boolean := True;
      Storage_Size_Static : Boolean := True;
      Storage_Size_Compatible : Boolean := True;
      Profile_C_Compatible : Boolean := True;
      Access_Profile_Compatible : Boolean := True;
      Access_Convention_Compatible : Boolean := True;
      Stream_External_Conflict : Boolean := False;
      Duplicate_Item : Boolean := False;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Entity_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Entity_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
   end record;

   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Entity_Info);

   type Entity_Model is record
      Items : Entity_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Item_Info is record
      Id : Item_Id := No_Item;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Interfacing_Item_Kind := Item_Unknown;
      Target : Entity_Id := No_Entity;
      Convention : Convention_Kind := Convention_Unknown;
      External_Name_Present : Boolean := False;
      External_Name_Static : Boolean := True;
      Link_Name_Present : Boolean := False;
      Link_Name_Static : Boolean := True;
      Address_Static : Boolean := True;
      Storage_Size_Static : Boolean := True;
      Storage_Size_Compatible : Boolean := True;
      Duplicate_Item : Boolean := False;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
   end record;

   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Item_Info);

   type Item_Model is record
      Items : Item_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Check_Id := No_Check;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Check_Kind := Check_Unknown;
      Target : Entity_Id := No_Entity;
      Item : Item_Id := No_Item;
      Expected_Entity_Kind : Entity_Kind := Entity_Unknown;
      Expected_Convention : Convention_Kind := Convention_Unknown;
      Convention_Allowed : Boolean := True;
      Requires_Import_Target : Boolean := False;
      Requires_Export_Target : Boolean := False;
      Requires_External_Name : Boolean := False;
      Requires_Link_Name : Boolean := False;
      Requires_Address_Static : Boolean := False;
      Requires_Storage_Static : Boolean := False;
      Requires_C_Compatible_Profile : Boolean := False;
      Requires_Access_Profile_Compatible : Boolean := False;
      Requires_Access_Convention_Compatible : Boolean := False;
      Reject_Import_Export_Conflict : Boolean := True;
      Reject_Stream_External_Conflict : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Entity_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Representation_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Entity_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Representation_Fingerprint : Natural := 0;
   end record;

   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Check_Info);

   type Check_Model is record
      Items : Check_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Check : Check_Id := No_Check;
      Status : Legality_Status := Legality_Not_Checked;
      Source_Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Fingerprint : Natural := 0;
      Missing_Check_Blockers : Natural := 0;
      Missing_Entity_Blockers : Natural := 0;
      Missing_Item_Blockers : Natural := 0;
      Entity_Kind_Blockers : Natural := 0;
      Convention_Missing_Blockers : Natural := 0;
      Convention_Mismatch_Blockers : Natural := 0;
      Convention_Not_Allowed_Blockers : Natural := 0;
      Import_Target_Blockers : Natural := 0;
      Export_Target_Blockers : Natural := 0;
      External_Name_Missing_Blockers : Natural := 0;
      External_Name_Static_Blockers : Natural := 0;
      Link_Name_Missing_Blockers : Natural := 0;
      Link_Name_Static_Blockers : Natural := 0;
      Address_Target_Blockers : Natural := 0;
      Address_Static_Blockers : Natural := 0;
      Storage_Target_Blockers : Natural := 0;
      Storage_Static_Blockers : Natural := 0;
      Storage_Size_Blockers : Natural := 0;
      C_Profile_Blockers : Natural := 0;
      Access_Profile_Blockers : Natural := 0;
      Access_Convention_Blockers : Natural := 0;
      Import_Export_Conflict_Blockers : Natural := 0;
      Stream_External_Conflict_Blockers : Natural := 0;
      Duplicate_Item_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Entity_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Representation_Fingerprint_Blockers : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Result_Info);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Clear (Model : in out Entity_Model);
   procedure Clear (Model : in out Item_Model);
   procedure Clear (Model : in out Check_Model);
   procedure Clear (Model : in out Result_Model);

   procedure Add_Entity (Model : in out Entity_Model; Item : Entity_Info);
   procedure Add_Item (Model : in out Item_Model; Item : Item_Info);
   procedure Add_Check (Model : in out Check_Model; Item : Check_Info);

   function Build
     (Entities : Entity_Model;
      Items : Item_Model;
      Checks : Check_Model) return Result_Model;

   function Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;

end Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality;
