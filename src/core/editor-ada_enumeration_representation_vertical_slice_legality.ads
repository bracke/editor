with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality is

   --  Pass1323 vertical-slice enumeration representation legality.
   --  This package models concrete Ada enumeration representation clauses,
   --  literal coverage, duplicate representation values, staticness, ordering,
   --  size/stream/representation interactions, freezing, and view barriers.

   type Enum_Type_Id is new Natural;
   No_Enum_Type : constant Enum_Type_Id := 0;

   type Literal_Id is new Natural;
   No_Literal : constant Literal_Id := 0;

   type Clause_Id is new Natural;
   No_Clause : constant Clause_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Enum_View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Enum_Status is
     (Enum_Not_Checked,
      Enum_Legal,
      Enum_Missing_Type,
      Enum_Missing_Literal,
      Enum_Private_View_Barrier,
      Enum_Limited_View_Barrier,
      Enum_Incomplete_View_Barrier,
      Enum_Generic_Formal_Barrier,
      Enum_Late_After_Freezing,
      Enum_Incomplete_Clause,
      Enum_Extra_Literal,
      Enum_Duplicate_Literal,
      Enum_Duplicate_Code,
      Enum_Non_Static_Code,
      Enum_Negative_Code,
      Enum_Code_Out_Of_Size,
      Enum_Non_Monotonic_Code,
      Enum_Stream_Profile_Conflict,
      Enum_Representation_Conflict,
      Enum_Source_Fingerprint_Mismatch,
      Enum_Type_Fingerprint_Mismatch,
      Enum_Clause_Fingerprint_Mismatch,
      Enum_Multiple_Blockers,
      Enum_Indeterminate);

   type Enum_Type_Info is record
      Id : Enum_Type_Id := No_Enum_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      View : Enum_View_Kind := View_Full;
      Literal_Count : Natural := 0;
      Size_Bits : Natural := 0;
      Frozen : Boolean := False;
      Freeze_Order : Natural := 0;
      Has_Stream_Attributes : Boolean := False;
      Stream_Profile_Compatible : Boolean := True;
      Existing_Representation_Clause : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Literal_Info is record
      Id : Literal_Id := No_Literal;
      Enum_Type : Enum_Type_Id := No_Enum_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Declaration_Order : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
   end record;

   type Representation_Item_Info is record
      Id : Clause_Id := No_Clause;
      Enum_Type : Enum_Type_Id := No_Enum_Type;
      Literal : Literal_Id := No_Literal;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Code : Integer := 0;
      Code_Static : Boolean := True;
      Placement_Order : Natural := 0;
      Requires_Monotonic_Order : Boolean := True;
      Representation_Compatible : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Clause_Fingerprint : Natural := 0;
      Expected_Clause_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Clause : Clause_Id := No_Clause;
      Enum_Type : Enum_Type_Id := No_Enum_Type;
      Literal : Literal_Id := No_Literal;
      Status : Enum_Status := Enum_Not_Checked;
      Missing_Type_Blockers : Natural := 0;
      Missing_Literal_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_Blockers : Natural := 0;
      Late_Freezing_Blockers : Natural := 0;
      Incomplete_Clause_Blockers : Natural := 0;
      Extra_Literal_Blockers : Natural := 0;
      Duplicate_Literal_Blockers : Natural := 0;
      Duplicate_Code_Blockers : Natural := 0;
      Non_Static_Code_Blockers : Natural := 0;
      Negative_Code_Blockers : Natural := 0;
      Code_Size_Blockers : Natural := 0;
      Non_Monotonic_Blockers : Natural := 0;
      Stream_Profile_Blockers : Natural := 0;
      Representation_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Clause_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Enum_Type_Model is private;
   type Literal_Model is private;
   type Clause_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Enum_Type_Model);
   procedure Clear (Model : in out Literal_Model);
   procedure Clear (Model : in out Clause_Model);
   procedure Add_Type (Model : in out Enum_Type_Model; Info : Enum_Type_Info);
   procedure Add_Literal (Model : in out Literal_Model; Info : Literal_Info);
   procedure Add_Item (Model : in out Clause_Model; Info : Representation_Item_Info);

   function Build
     (Types : Enum_Type_Model;
      Literals : Literal_Model;
      Items : Clause_Model) return Result_Model;

   function Type_Count (Model : Enum_Type_Model) return Natural;
   function Literal_Count (Model : Literal_Model) return Natural;
   function Clause_Count (Model : Clause_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Enum_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Enum_Type_Info);
   package Literal_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Literal_Info);
   package Clause_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Representation_Item_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Enum_Type_Model is record
      Items : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Literal_Model is record
      Items : Literal_Vectors.Vector;
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

end Editor.Ada_Enumeration_Representation_Vertical_Slice_Legality;
