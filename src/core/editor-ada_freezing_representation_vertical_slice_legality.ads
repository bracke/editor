with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Freezing_Representation_Vertical_Slice_Legality is

   --  Pass1299 vertical-slice freezing and representation legality.  This
   --  package performs concrete RM-facing checks for representation and
   --  operational clauses against source-shaped type/freezing evidence.  It
   --  tracks real freezing points, rejects clauses that appear too late,
   --  checks private/full-view and generic-formal barriers, and validates
   --  discriminant/variant/finalization-sensitive layout constraints without
   --  adding another diagnostic/provenance/recheck wrapper.

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Clause_Id is new Natural;
   No_Clause : constant Clause_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Type_View is
     (View_Ordinary,
      View_Private_Partial,
      View_Private_Full,
      View_Limited_Private,
      View_Generic_Formal,
      View_Unknown);

   type Clause_Kind is
     (Clause_Record_Representation,
      Clause_Enumeration_Representation,
      Clause_At_Address,
      Clause_Size,
      Clause_Alignment,
      Clause_Bit_Order,
      Clause_Scalar_Storage_Order,
      Clause_Stream_Attribute,
      Clause_Convention,
      Clause_Operational_Attribute,
      Clause_Unknown);

   type Freezing_Status is
     (Freezing_Not_Checked,
      Freezing_Legal_Before_Point,
      Freezing_Legal_Full_View,
      Freezing_Legal_Generic_Pre_Freeze,
      Freezing_Legal_Operational_Inheritance,
      Freezing_Late_Representation_Clause,
      Freezing_Private_View_Barrier,
      Freezing_Generic_Formal_Barrier,
      Freezing_Inherited_Operational_Conflict,
      Freezing_Stream_Limited_View_Barrier,
      Freezing_Discriminant_Layout_Conflict,
      Freezing_Variant_Layout_Conflict,
      Freezing_Finalization_Layout_Conflict,
      Freezing_Address_Size_Alignment_Conflict,
      Freezing_Source_Fingerprint_Mismatch,
      Freezing_Missing_Target,
      Freezing_Multiple_Blockers,
      Freezing_Indeterminate);

   type Type_Info is record
      Id       : Type_Id := No_Type;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      View     : Type_View := View_Unknown;
      Declaration_Order : Natural := 0;
      Freezing_Order    : Natural := 0;
      Full_View_Available : Boolean := True;
      Generic_Formal      : Boolean := False;
      Generic_Actual_Frozen : Boolean := False;
      Has_Discriminants : Boolean := False;
      Has_Variants      : Boolean := False;
      Has_Controlled_Or_Finalized_Component : Boolean := False;
      Representation_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
   end record;

   type Clause_Info is record
      Id       : Clause_Id := No_Clause;
      Target   : Type_Id := No_Type;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Clause_Kind := Clause_Unknown;
      Clause_Order : Natural := 0;
      Requires_Full_View : Boolean := False;
      Applies_To_Full_View : Boolean := False;
      Uses_Limited_View : Boolean := False;
      In_Generic_Template : Boolean := False;
      Inherited_Operational : Boolean := False;
      Overrides_Inherited_Operational : Boolean := False;
      Discriminant_Dependent : Boolean := False;
      Variant_Dependent      : Boolean := False;
      Finalization_Sensitive : Boolean := False;
      Address_Size_Alignment_Sensitive : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Clause_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Clause   : Clause_Id := No_Clause;
      Target   : Type_Id := No_Type;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Freezing_Status := Freezing_Not_Checked;
      Late_Blockers : Natural := 0;
      View_Blockers : Natural := 0;
      Generic_Blockers : Natural := 0;
      Operational_Blockers : Natural := 0;
      Layout_Blockers : Natural := 0;
      Stream_Blockers : Natural := 0;
      Address_Size_Alignment_Blockers : Natural := 0;
      Fingerprint_Blockers : Natural := 0;
      Missing_Target_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Clause_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Type_Model is private;
   type Clause_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Type_Model);
   procedure Clear (Model : in out Clause_Model);

   procedure Add_Type (Model : in out Type_Model; Info : Type_Info);
   procedure Add_Clause (Model : in out Clause_Model; Info : Clause_Info);

   function Build
     (Types   : Type_Model;
      Clauses : Clause_Model) return Result_Model;

   function Type_Count (Model : Type_Model) return Natural;
   function Clause_Count (Model : Clause_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info;

   function Count_Status (Model : Result_Model; Status : Freezing_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Type_Info);
   package Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Clause_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Type_Model is record
      Items : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Clause_Model is record
      Items : Clause_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Freezing_Representation_Vertical_Slice_Legality;
