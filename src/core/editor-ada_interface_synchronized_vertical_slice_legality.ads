with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality is

   --  Pass1332 vertical-slice interface/synchronized legality.
   --  This package models source-shaped Ada interface evidence: ordinary,
   --  limited, task, protected, and synchronized interfaces; primitive
   --  conformance; synchronized overriding; interface dispatching; and null
   --  procedures.  It is a deterministic legality engine, not a projection or
   --  diagnostic wrapper.

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Primitive_Id is new Natural;
   No_Primitive : constant Primitive_Id := 0;

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Type_Kind is
     (Type_Ordinary_Tagged,
      Type_Interface,
      Type_Limited_Interface,
      Type_Task_Interface,
      Type_Protected_Interface,
      Type_Synchronized_Interface,
      Type_Private_Extension,
      Type_Unknown);

   type Primitive_Kind is
     (Primitive_Procedure,
      Primitive_Function,
      Primitive_Entry,
      Primitive_Protected_Operation,
      Primitive_Task_Operation,
      Primitive_Null_Procedure,
      Primitive_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Check_Kind is
     (Check_Interface_Declaration,
      Check_Interface_Inheritance,
      Check_Primitive_Override,
      Check_Synchronized_Override,
      Check_Dispatching_Interface_Call,
      Check_Null_Procedure,
      Check_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Missing_Check,
      Legality_Missing_Interface_Type,
      Legality_Missing_Parent_Interface,
      Legality_Missing_Primitive,
      Legality_Missing_Parent_Primitive,
      Legality_Not_Interface_Type,
      Legality_Parent_Not_Interface,
      Legality_Interface_Kind_Mismatch,
      Legality_Limited_Interface_Mismatch,
      Legality_Synchronized_Interface_Mismatch,
      Legality_Inheritance_Incompatible,
      Legality_Primitive_Profile_Mismatch,
      Legality_Primitive_Mode_Mismatch,
      Legality_Primitive_Result_Mismatch,
      Legality_Overriding_Indicator_Mismatch,
      Legality_Abstract_Primitive_Not_Implemented,
      Legality_Synchronized_Override_Mismatch,
      Legality_Dispatching_Profile_Mismatch,
      Legality_Ambiguous_Dispatching_Call,
      Legality_Static_Call_To_Interface,
      Legality_Null_Procedure_Not_Allowed,
      Legality_Null_Procedure_Profile_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_Effect_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Interface_Type_Info is record
      Id : Type_Id := No_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Type_Kind := Type_Unknown;
      View : View_Kind := View_Full;
      Parent : Type_Id := No_Type;
      Is_Interface : Boolean := False;
      Is_Limited_Interface : Boolean := False;
      Is_Task_Interface : Boolean := False;
      Is_Protected_Interface : Boolean := False;
      Is_Synchronized_Interface : Boolean := False;
      Inheritance_Compatible : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Interface_Type_Info);

   type Type_Model is record
      Items : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Primitive_Info is record
      Id : Primitive_Id := No_Primitive;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Primitive_Kind := Primitive_Unknown;
      Owner : Type_Id := No_Type;
      Parent_Primitive : Primitive_Id := No_Primitive;
      Is_Abstract : Boolean := False;
      Is_Null_Procedure : Boolean := False;
      Is_Overriding : Boolean := False;
      Profile_Conformant : Boolean := True;
      Mode_Conformant : Boolean := True;
      Result_Conformant : Boolean := True;
      Synchronized_Override_OK : Boolean := True;
      Null_Procedure_Allowed : Boolean := True;
      View : View_Kind := View_Full;
      Source_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   package Primitive_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Primitive_Info);

   type Primitive_Model is record
      Items : Primitive_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Check_Id := No_Check;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Check_Kind := Check_Unknown;
      Interface_Type : Type_Id := No_Type;
      Parent_Interface : Type_Id := No_Type;
      Primitive : Primitive_Id := No_Primitive;
      Parent_Primitive : Primitive_Id := No_Primitive;
      Expected_Interface_Kind : Type_Kind := Type_Unknown;
      Requires_Limited_Interface : Boolean := False;
      Requires_Synchronized_Interface : Boolean := False;
      Inheritance_Compatible : Boolean := True;
      Profile_Conformant : Boolean := True;
      Mode_Conformant : Boolean := True;
      Result_Conformant : Boolean := True;
      Overriding_Indicator_OK : Boolean := True;
      Abstract_Primitive_Implemented : Boolean := True;
      Synchronized_Override_OK : Boolean := True;
      Dispatching_Profile_OK : Boolean := True;
      Dispatching_Ambiguous : Boolean := False;
      Static_Call_To_Interface_Primitive : Boolean := False;
      Null_Procedure_Allowed : Boolean := True;
      Null_Procedure_Profile_OK : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
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
      Missing_Interface_Type_Blockers : Natural := 0;
      Missing_Parent_Interface_Blockers : Natural := 0;
      Missing_Primitive_Blockers : Natural := 0;
      Missing_Parent_Primitive_Blockers : Natural := 0;
      Not_Interface_Type_Blockers : Natural := 0;
      Parent_Not_Interface_Blockers : Natural := 0;
      Interface_Kind_Blockers : Natural := 0;
      Limited_Interface_Blockers : Natural := 0;
      Synchronized_Interface_Blockers : Natural := 0;
      Inheritance_Blockers : Natural := 0;
      Profile_Blockers : Natural := 0;
      Mode_Blockers : Natural := 0;
      Result_Blockers : Natural := 0;
      Overriding_Indicator_Blockers : Natural := 0;
      Abstract_Implementation_Blockers : Natural := 0;
      Synchronized_Override_Blockers : Natural := 0;
      Dispatching_Profile_Blockers : Natural := 0;
      Dispatching_Ambiguity_Blockers : Natural := 0;
      Static_Interface_Call_Blockers : Natural := 0;
      Null_Procedure_Allowed_Blockers : Natural := 0;
      Null_Procedure_Profile_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Effect_Fingerprint_Blockers : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Result_Info);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Clear (Model : in out Type_Model);
   procedure Clear (Model : in out Primitive_Model);
   procedure Clear (Model : in out Check_Model);
   procedure Clear (Model : in out Result_Model);

   procedure Add_Type (Model : in out Type_Model; Item : Interface_Type_Info);
   procedure Add_Primitive (Model : in out Primitive_Model; Item : Primitive_Info);
   procedure Add_Check (Model : in out Check_Model; Item : Check_Info);

   function Build
     (Types : Type_Model;
      Primitives : Primitive_Model;
      Checks : Check_Model) return Result_Model;

   function Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;

end Editor.Ada_Interface_Synchronized_Vertical_Slice_Legality;
