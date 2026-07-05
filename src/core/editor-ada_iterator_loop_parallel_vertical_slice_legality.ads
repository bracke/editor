with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality is

   --  Case 1328 vertical-slice iterator, loop, and parallelism legality.
   --  This package models source-shaped Ada discrete loops, generalized
   --  iterators, container iterators, loop-parameter declarations, parallel
   --  loops, reductions, tampering evidence, and shared-state restrictions.
   --  It is deterministic, bounded, and snapshot-owned.

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Type_Kind is
     (Type_Discrete,
      Type_Integer,
      Type_Enumeration,
      Type_Boolean,
      Type_Array,
      Type_Container,
      Type_Cursor,
      Type_Element,
      Type_Access,
      Type_Private,
      Type_Limited,
      Type_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Iteration_Kind is
     (Iteration_Discrete_Subtype,
      Iteration_Discrete_Range,
      Iteration_Array_Component,
      Iteration_Generalized_Iterator,
      Iteration_Container_Element,
      Iteration_Container_Cursor,
      Iteration_Parallel_Discrete,
      Iteration_Parallel_Iterator,
      Iteration_Reduction,
      Iteration_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_Check,
      Legality_Missing_Iterator,
      Legality_Missing_Container,
      Legality_Missing_Loop_Parameter,
      Legality_Missing_Discrete_Subtype,
      Legality_Missing_Element_Type,
      Legality_Missing_Reduction_Profile,
      Legality_Iterator_Kind_Mismatch,
      Legality_Discrete_Subtype_Required,
      Legality_Range_Bounds_Invalid,
      Legality_Loop_Parameter_Mode_Invalid,
      Legality_Element_Type_Mismatch,
      Legality_Cursor_Profile_Mismatch,
      Legality_Iterator_Profile_Mismatch,
      Legality_Reversible_Iterator_Required,
      Legality_Parallel_Not_Allowed,
      Legality_Shared_State_Blocker,
      Legality_Tampering_Blocker,
      Legality_Reduction_Profile_Blocker,
      Legality_Reduction_Seed_Blocker,
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

   type Entity_Info is record
      Id : Entity_Id := No_Entity;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Typ : Type_Id := No_Type;
      View : View_Kind := View_Full;
      Is_Loop_Parameter : Boolean := False;
      Is_Variable_View : Boolean := False;
      Is_Constant_View : Boolean := True;
      Has_Shared_State_Access : Boolean := False;
      Writes_Shared_State : Boolean := False;
      Reads_Shared_State : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Type_Info is record
      Id : Type_Id := No_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Type_Kind := Type_Unknown;
      View : View_Kind := View_Full;
      Element_Type : Type_Id := No_Type;
      Cursor_Type : Type_Id := No_Type;
      Index_Type : Type_Id := No_Type;
      Base_Type : Type_Id := No_Type;
      Is_Discrete : Boolean := False;
      Is_Container : Boolean := False;
      Is_Iterator : Boolean := False;
      Is_Reversible_Iterator : Boolean := False;
      Has_First_Next_Profile : Boolean := False;
      Has_Element_Profile : Boolean := False;
      Has_Has_Element_Profile : Boolean := False;
      Allows_Parallel_Iteration : Boolean := False;
      Tampering_Check_Required : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Check_Id := No_Check;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Iteration_Kind := Iteration_Unknown;
      Loop_Parameter : Entity_Id := No_Entity;
      Iterator_Entity : Entity_Id := No_Entity;
      Container_Entity : Entity_Id := No_Entity;
      Discrete_Subtype : Type_Id := No_Type;
      Expected_Element_Type : Type_Id := No_Type;
      Actual_Element_Type : Type_Id := No_Type;
      Cursor_Type : Type_Id := No_Type;
      Reduction_Result_Type : Type_Id := No_Type;
      Reduction_Seed_Type : Type_Id := No_Type;
      Is_Parallel : Boolean := False;
      Requires_Reversible_Iterator : Boolean := False;
      Range_Bounds_Static : Boolean := True;
      Range_Bounds_Compatible : Boolean := True;
      Loop_Parameter_Mode_OK : Boolean := True;
      Iterator_Profile_OK : Boolean := True;
      Cursor_Profile_OK : Boolean := True;
      Element_Type_OK : Boolean := True;
      Reduction_Profile_OK : Boolean := True;
      Reduction_Seed_OK : Boolean := True;
      Parallel_Allowed : Boolean := True;
      Shared_State_OK : Boolean := True;
      Tampering_OK : Boolean := True;
      Runtime_Bounds_Check_Required : Boolean := False;
      Runtime_Tampering_Check_Required : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Check : Check_Id := No_Check;
      Kind : Iteration_Kind := Iteration_Unknown;
      Status : Legality_Status := Legality_Not_Checked;
      Missing_Check_Blockers : Natural := 0;
      Missing_Iterator_Blockers : Natural := 0;
      Missing_Container_Blockers : Natural := 0;
      Missing_Loop_Parameter_Blockers : Natural := 0;
      Missing_Discrete_Subtype_Blockers : Natural := 0;
      Missing_Element_Type_Blockers : Natural := 0;
      Missing_Reduction_Profile_Blockers : Natural := 0;
      Iterator_Kind_Blockers : Natural := 0;
      Discrete_Subtype_Blockers : Natural := 0;
      Range_Blockers : Natural := 0;
      Loop_Parameter_Mode_Blockers : Natural := 0;
      Element_Type_Blockers : Natural := 0;
      Cursor_Profile_Blockers : Natural := 0;
      Iterator_Profile_Blockers : Natural := 0;
      Reversible_Iterator_Blockers : Natural := 0;
      Parallel_Blockers : Natural := 0;
      Shared_State_Blockers : Natural := 0;
      Tampering_Blockers : Natural := 0;
      Reduction_Profile_Blockers : Natural := 0;
      Reduction_Seed_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Effect_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Entity_Model is private;
   type Type_Model is private;
   type Check_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Entity_Model);
   procedure Clear (Model : in out Type_Model);
   procedure Clear (Model : in out Check_Model);
   procedure Add_Entity (Model : in out Entity_Model; Info : Entity_Info);
   procedure Add_Type (Model : in out Type_Model; Info : Type_Info);
   procedure Add_Check (Model : in out Check_Model; Info : Check_Info);

   function Build
     (Entities : Entity_Model;
      Types : Type_Model;
      Checks : Check_Model) return Result_Model;

   function Entity_Count (Model : Entity_Model) return Natural;
   function Type_Count (Model : Type_Model) return Natural;
   function Check_Count (Model : Check_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Entity_Info);
   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Type_Info);
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Check_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Entity_Model is record
      Items : Entity_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Type_Model is record
      Items : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Check_Model is record
      Items : Check_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality;
