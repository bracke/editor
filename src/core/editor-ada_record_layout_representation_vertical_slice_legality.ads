with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality is

   --  Pass1322 vertical-slice record representation/layout legality.
   --  This package models concrete record representation clauses, component
   --  clauses, bit ranges, storage order, alignment, discriminant/variant
   --  layout dependencies, and controlled/finalized component constraints.  It
   --  is a rule engine over parser/semantic evidence rather than a diagnostic
   --  projection layer.

   type Record_Id is new Natural;
   No_Record : constant Record_Id := 0;

   type Component_Id is new Natural;
   No_Component : constant Component_Id := 0;

   type Clause_Id is new Natural;
   No_Clause : constant Clause_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Record_View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Component_Kind is
     (Component_Data,
      Component_Discriminant,
      Component_Variant,
      Component_Controlled,
      Component_Finalized,
      Component_Unknown);

   type Storage_Order_Kind is
     (Storage_Default,
      Storage_High_Order_First,
      Storage_Low_Order_First,
      Storage_Unknown);

   type Layout_Status is
     (Layout_Not_Checked,
      Layout_Legal,
      Layout_Legal_Runtime_Check,
      Layout_Missing_Record,
      Layout_Missing_Component,
      Layout_Private_View_Barrier,
      Layout_Limited_View_Barrier,
      Layout_Incomplete_View_Barrier,
      Layout_Generic_Formal_Barrier,
      Layout_Late_After_Freezing,
      Layout_Non_Static_Position,
      Layout_Non_Static_Range,
      Layout_Invalid_Bit_Range,
      Layout_Invalid_Position,
      Layout_Overlap,
      Layout_Size_Overflow,
      Layout_Alignment_Conflict,
      Layout_Storage_Order_Conflict,
      Layout_Discriminant_Dependency_Conflict,
      Layout_Variant_Coverage_Conflict,
      Layout_Controlled_Finalized_Conflict,
      Layout_Duplicate_Component_Clause,
      Layout_Source_Fingerprint_Mismatch,
      Layout_Record_Fingerprint_Mismatch,
      Layout_Clause_Fingerprint_Mismatch,
      Layout_Multiple_Blockers,
      Layout_Indeterminate);

   type Record_Info is record
      Id : Record_Id := No_Record;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      View : Record_View_Kind := View_Full;
      Frozen : Boolean := False;
      Freeze_Order : Natural := 0;
      Size_Bits : Natural := 0;
      Alignment_Bits : Natural := 0;
      Storage_Order : Storage_Order_Kind := Storage_Default;
      Has_Discriminants : Boolean := False;
      Has_Variants : Boolean := False;
      Has_Controlled_Components : Boolean := False;
      Has_Finalized_Components : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Record_Fingerprint : Natural := 0;
      Expected_Record_Fingerprint : Natural := 0;
   end record;

   type Component_Info is record
      Id : Component_Id := No_Component;
      Record_Ref : Record_Id := No_Record;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind : Component_Kind := Component_Unknown;
      Size_Bits : Natural := 0;
      Alignment_Bits : Natural := 0;
      Requires_Discriminant_Value : Boolean := False;
      Active_In_All_Variants : Boolean := True;
      Controlled_Or_Finalized : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
   end record;

   type Component_Clause_Info is record
      Id : Clause_Id := No_Clause;
      Record_Ref : Record_Id := No_Record;
      Component : Component_Id := No_Component;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Position_Bits : Natural := 0;
      First_Bit : Natural := 0;
      Last_Bit : Natural := 0;
      Placement_Order : Natural := 0;
      Position_Static : Boolean := True;
      Range_Static : Boolean := True;
      Range_Valid : Boolean := True;
      Position_Valid : Boolean := True;
      Alignment_Compatible : Boolean := True;
      Storage_Order_Compatible : Boolean := True;
      Discriminant_Dependency_Compatible : Boolean := True;
      Variant_Coverage_Compatible : Boolean := True;
      Controlled_Finalized_Compatible : Boolean := True;
      Requires_Runtime_Check : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Record_Fingerprint : Natural := 0;
      Expected_Record_Fingerprint : Natural := 0;
      Clause_Fingerprint : Natural := 0;
      Expected_Clause_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Clause : Clause_Id := No_Clause;
      Record_Ref : Record_Id := No_Record;
      Component : Component_Id := No_Component;
      Status : Layout_Status := Layout_Not_Checked;
      Missing_Record_Blockers : Natural := 0;
      Missing_Component_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_Blockers : Natural := 0;
      Late_Freezing_Blockers : Natural := 0;
      Non_Static_Position_Blockers : Natural := 0;
      Non_Static_Range_Blockers : Natural := 0;
      Invalid_Range_Blockers : Natural := 0;
      Invalid_Position_Blockers : Natural := 0;
      Overlap_Blockers : Natural := 0;
      Size_Overflow_Blockers : Natural := 0;
      Alignment_Blockers : Natural := 0;
      Storage_Order_Blockers : Natural := 0;
      Discriminant_Blockers : Natural := 0;
      Variant_Blockers : Natural := 0;
      Controlled_Finalized_Blockers : Natural := 0;
      Duplicate_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Record_Fingerprint_Blockers : Natural := 0;
      Clause_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Record_Model is private;
   type Component_Model is private;
   type Clause_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Record_Model);
   procedure Clear (Model : in out Component_Model);
   procedure Clear (Model : in out Clause_Model);
   procedure Add_Record (Model : in out Record_Model; Info : Record_Info);
   procedure Add_Component (Model : in out Component_Model; Info : Component_Info);
   procedure Add_Clause (Model : in out Clause_Model; Info : Component_Clause_Info);

   function Build
     (Records : Record_Model;
      Components : Component_Model;
      Clauses : Clause_Model) return Result_Model;

   function Record_Count (Model : Record_Model) return Natural;
   function Component_Count (Model : Component_Model) return Natural;
   function Clause_Count (Model : Clause_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Layout_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Record_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Record_Info);
   package Component_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Component_Info);
   package Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Component_Clause_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Record_Model is record
      Items : Record_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Component_Model is record
      Items : Component_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Clause_Model is record
      Items : Clause_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Record_Layout_Representation_Vertical_Slice_Legality;
