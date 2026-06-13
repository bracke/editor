with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality is

   --  Pass1319 vertical-slice generic formal type/family legality.  This
   --  package models concrete Ada generic formal type legality for source
   --  shaped formal declarations and actuals: private/limited/tagged,
   --  discrete/signed/modular/floating/fixed, array/access/interface formal
   --  types, discriminants, formal derived types, formal package contracts,
   --  formal subprogram defaults, and nested instance substitution freshness.
   --  It is a semantic rule engine, not a diagnostic/provenance wrapper.

   type Instance_Id is new Natural;
   No_Instance : constant Instance_Id := 0;

   type Formal_Id is new Natural;
   No_Formal : constant Formal_Id := 0;

   type Actual_Id is new Natural;
   No_Actual : constant Actual_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Formal_Type_Family is
     (Family_Private,
      Family_Limited_Private,
      Family_Tagged_Private,
      Family_Discrete,
      Family_Signed_Integer,
      Family_Modular,
      Family_Floating,
      Family_Ordinary_Fixed,
      Family_Decimal_Fixed,
      Family_Array,
      Family_Access_Object,
      Family_Access_Subprogram,
      Family_Interface,
      Family_Derived,
      Family_Unknown);

   type Actual_Type_Family is
     (Actual_Private,
      Actual_Limited_Private,
      Actual_Tagged,
      Actual_Enumeration,
      Actual_Signed_Integer,
      Actual_Modular,
      Actual_Floating,
      Actual_Ordinary_Fixed,
      Actual_Decimal_Fixed,
      Actual_Array,
      Actual_Access_Object,
      Actual_Access_Subprogram,
      Actual_Interface,
      Actual_Derived,
      Actual_Unknown);

   type Formal_Mode is
     (Mode_None,
      Mode_In,
      Mode_In_Out,
      Mode_Out,
      Mode_Access,
      Mode_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal_Exact,
      Legality_Legal_Class_Match,
      Legality_Legal_Defaulted_Formal,
      Legality_Legal_Formal_Package_Match,
      Legality_Legal_Nested_Substitution,
      Legality_Missing_Formal,
      Legality_Missing_Actual,
      Legality_Extra_Actual,
      Legality_Formal_Actual_Family_Mismatch,
      Legality_Limitedness_Mismatch,
      Legality_Taggedness_Mismatch,
      Legality_Discriminant_Mismatch,
      Legality_Array_Index_Mismatch,
      Legality_Array_Component_Mismatch,
      Legality_Access_Designated_Type_Mismatch,
      Legality_Access_Profile_Mismatch,
      Legality_Interface_Mismatch,
      Legality_Derived_Ancestor_Mismatch,
      Legality_Formal_Object_Mode_Mismatch,
      Legality_Formal_Subprogram_Profile_Mismatch,
      Legality_Formal_Package_Contract_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Body_Replay_Unavailable,
      Legality_Nested_Instance_Cycle,
      Legality_Source_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Formal_Info is record
      Id       : Formal_Id := No_Formal;
      Instance : Instance_Id := No_Instance;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Family   : Formal_Type_Family := Family_Unknown;
      Mode     : Formal_Mode := Mode_None;
      Requires_Limited : Boolean := False;
      Requires_Tagged : Boolean := False;
      Requires_Definite : Boolean := False;
      Allows_Private_View : Boolean := True;
      Allows_Limited_View : Boolean := True;
      Has_Discriminants : Boolean := False;
      Discriminant_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Array_Index_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Array_Component_Type : Ada.Strings.Unbounded.Unbounded_String;
      Access_Designated_Type : Ada.Strings.Unbounded.Unbounded_String;
      Access_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Ancestor_Type : Ada.Strings.Unbounded.Unbounded_String;
      Package_Contract : Ada.Strings.Unbounded.Unbounded_String;
      Subprogram_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Has_Default : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
   end record;

   type Actual_Info is record
      Id       : Actual_Id := No_Actual;
      Instance : Instance_Id := No_Instance;
      Formal   : Formal_Id := No_Formal;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Family   : Actual_Type_Family := Actual_Unknown;
      Mode     : Formal_Mode := Mode_None;
      View     : View_Kind := View_Full;
      Is_Limited : Boolean := False;
      Is_Tagged : Boolean := False;
      Is_Definite : Boolean := True;
      Has_Discriminants : Boolean := False;
      Discriminant_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Array_Index_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Array_Component_Type : Ada.Strings.Unbounded.Unbounded_String;
      Access_Designated_Type : Ada.Strings.Unbounded.Unbounded_String;
      Access_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Ancestor_Type : Ada.Strings.Unbounded.Unbounded_String;
      Package_Contract : Ada.Strings.Unbounded.Unbounded_String;
      Subprogram_Profile : Ada.Strings.Unbounded.Unbounded_String;
      Body_Replay_Available : Boolean := True;
      Nested_Instance : Boolean := False;
      Nested_Cycle : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Instance : Instance_Id := No_Instance;
      Formal   : Formal_Id := No_Formal;
      Actual   : Actual_Id := No_Actual;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Legality_Status := Legality_Not_Checked;
      Missing_Formal_Blockers : Natural := 0;
      Missing_Actual_Blockers : Natural := 0;
      Extra_Actual_Blockers : Natural := 0;
      Family_Blockers : Natural := 0;
      Limitedness_Blockers : Natural := 0;
      Taggedness_Blockers : Natural := 0;
      Discriminant_Blockers : Natural := 0;
      Array_Index_Blockers : Natural := 0;
      Array_Component_Blockers : Natural := 0;
      Access_Designated_Blockers : Natural := 0;
      Access_Profile_Blockers : Natural := 0;
      Interface_Blockers : Natural := 0;
      Derived_Ancestor_Blockers : Natural := 0;
      Object_Mode_Blockers : Natural := 0;
      Subprogram_Profile_Blockers : Natural := 0;
      Package_Contract_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Body_Replay_Blockers : Natural := 0;
      Nested_Cycle_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Formal_Model is private;
   type Actual_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Formal_Model);
   procedure Clear (Model : in out Actual_Model);
   procedure Add_Formal (Model : in out Formal_Model; Info : Formal_Info);
   procedure Add_Actual (Model : in out Actual_Model; Info : Actual_Info);

   function Build (Formals : Formal_Model; Actuals : Actual_Model) return Result_Model;

   function Formal_Count (Model : Formal_Model) return Natural;
   function Actual_Count (Model : Actual_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Formal_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Formal_Info);
   package Actual_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Actual_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Formal_Model is record
      Items : Formal_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Actual_Model is record
      Items : Actual_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality;
