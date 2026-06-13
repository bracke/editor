with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality is

   --  Pass1321 vertical-slice representation/aspect/operational-item legality.
   --  This package models concrete Ada representation and operational items as
   --  either aspects or attribute-definition clauses, including target lookup,
   --  freezing order, duplicate/conflicting items, convention/import/export
   --  rules, address/size/alignment/storage-size checks, stream attributes,
   --  volatile/atomic/full-access effects, and generic/private/limited view
   --  barriers.  It is a semantic rule engine, not a diagnostic wrapper.

   type Target_Id is new Natural;
   No_Target : constant Target_Id := 0;

   type Item_Id is new Natural;
   No_Item : constant Item_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Target_Kind is
     (Target_Type,
      Target_Object,
      Target_Subprogram,
      Target_Package,
      Target_Entry,
      Target_Task,
      Target_Protected,
      Target_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Item_Form is
     (Form_Aspect,
      Form_Attribute_Definition_Clause,
      Form_Pragma,
      Form_Unknown);

   type Representation_Item_Kind is
     (Item_Address,
      Item_Size,
      Item_Object_Size,
      Item_Value_Size,
      Item_Alignment,
      Item_Storage_Size,
      Item_Component_Size,
      Item_Bit_Order,
      Item_Scalar_Storage_Order,
      Item_Convention,
      Item_Import,
      Item_Export,
      Item_External_Name,
      Item_Link_Name,
      Item_Read,
      Item_Write,
      Item_Input,
      Item_Output,
      Item_Volatile,
      Item_Atomic,
      Item_Atomic_Components,
      Item_Volatile_Components,
      Item_Independent,
      Item_Independent_Components,
      Item_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_Runtime_Check,
      Legality_Missing_Target,
      Legality_Target_Kind_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_Barrier,
      Legality_Late_After_Freezing,
      Legality_Duplicate_Item,
      Legality_Conflicting_Item,
      Legality_Invalid_Static_Expression,
      Legality_Invalid_Address,
      Legality_Invalid_Size,
      Legality_Invalid_Alignment,
      Legality_Invalid_Storage_Size,
      Legality_Invalid_Convention,
      Legality_Import_Export_Profile_Mismatch,
      Legality_External_Link_Name_Mismatch,
      Legality_Stream_Profile_Mismatch,
      Legality_Stream_View_Barrier,
      Legality_Volatile_Atomic_Conflict,
      Legality_Operational_Attribute_Conflict,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Target_Fingerprint_Mismatch,
      Legality_Item_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Target_Info is record
      Id : Target_Id := No_Target;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind : Target_Kind := Target_Unknown;
      View : View_Kind := View_Full;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Frozen : Boolean := False;
      Freeze_Order : Natural := 0;
      Allows_Representation : Boolean := True;
      Allows_Operational : Boolean := True;
      Has_Address : Boolean := False;
      Has_Size : Boolean := False;
      Has_Alignment : Boolean := False;
      Has_Convention : Boolean := False;
      Convention_Name : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Target_Fingerprint : Natural := 0;
      Expected_Target_Fingerprint : Natural := 0;
   end record;

   type Item_Info is record
      Id : Item_Id := No_Item;
      Target : Target_Id := No_Target;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Form : Item_Form := Form_Unknown;
      Kind : Representation_Item_Kind := Item_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Expression_Text : Ada.Strings.Unbounded.Unbounded_String;
      Convention_Name : Ada.Strings.Unbounded.Unbounded_String;
      Required_Target_Kind : Target_Kind := Target_Unknown;
      Placement_Order : Natural := 0;
      Static_Expression : Boolean := True;
      Positive_Value : Boolean := True;
      Address_Expression_Valid : Boolean := True;
      Size_Expression_Valid : Boolean := True;
      Alignment_Expression_Valid : Boolean := True;
      Storage_Size_Expression_Valid : Boolean := True;
      Convention_Valid : Boolean := True;
      Import_Export_Profile_Valid : Boolean := True;
      External_Link_Name_Valid : Boolean := True;
      Stream_Profile_Valid : Boolean := True;
      Volatile_Atomic_Compatible : Boolean := True;
      Operational_Attribute_Compatible : Boolean := True;
      Requires_Runtime_Check : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Target_Fingerprint : Natural := 0;
      Expected_Target_Fingerprint : Natural := 0;
      Item_Fingerprint : Natural := 0;
      Expected_Item_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Item : Item_Id := No_Item;
      Target : Target_Id := No_Target;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Form : Item_Form := Form_Unknown;
      Kind : Representation_Item_Kind := Item_Unknown;
      Status : Legality_Status := Legality_Not_Checked;
      Missing_Target_Blockers : Natural := 0;
      Target_Kind_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_Blockers : Natural := 0;
      Late_Freezing_Blockers : Natural := 0;
      Duplicate_Blockers : Natural := 0;
      Conflict_Blockers : Natural := 0;
      Static_Expression_Blockers : Natural := 0;
      Address_Blockers : Natural := 0;
      Size_Blockers : Natural := 0;
      Alignment_Blockers : Natural := 0;
      Storage_Size_Blockers : Natural := 0;
      Convention_Blockers : Natural := 0;
      Import_Export_Blockers : Natural := 0;
      External_Link_Name_Blockers : Natural := 0;
      Stream_Profile_Blockers : Natural := 0;
      Stream_View_Blockers : Natural := 0;
      Volatile_Atomic_Blockers : Natural := 0;
      Operational_Attribute_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Target_Fingerprint_Blockers : Natural := 0;
      Item_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Target_Model is private;
   type Item_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Target_Model);
   procedure Clear (Model : in out Item_Model);
   procedure Add_Target (Model : in out Target_Model; Info : Target_Info);
   procedure Add_Item (Model : in out Item_Model; Info : Item_Info);

   function Build (Targets : Target_Model; Items : Item_Model) return Result_Model;

   function Target_Count (Model : Target_Model) return Natural;
   function Item_Count (Model : Item_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Target_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Target_Info);
   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Item_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Target_Model is record
      Items : Target_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Item_Model is record
      Items : Item_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality;
