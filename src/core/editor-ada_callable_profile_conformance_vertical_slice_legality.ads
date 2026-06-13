with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality is

   --  Pass1325 vertical-slice callable profile/conformance legality.
   --  This package models concrete Ada callable profile conformance for
   --  subprogram declarations/bodies, renamings, overriding declarations,
   --  access-to-subprogram conversions, generic formal subprogram actuals,
   --  entries, operators, and dispatching primitive profiles.

   type Callable_Id is new Natural;
   No_Callable : constant Callable_Id := 0;

   type Profile_Id is new Natural;
   No_Profile : constant Profile_Id := 0;

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Callable_Kind is
     (Callable_Subprogram,
      Callable_Operator,
      Callable_Entry,
      Callable_Access_Subprogram,
      Callable_Generic_Formal_Subprogram,
      Callable_Primitive,
      Callable_Unknown);

   type Profile_Context_Kind is
     (Context_Declaration,
      Context_Body_Completion,
      Context_Renaming,
      Context_Overriding,
      Context_Access_Subprogram_Conversion,
      Context_Generic_Actual,
      Context_Dispatching_Call,
      Context_Entry_Family,
      Context_Unknown);

   type Profile_View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Profile_Status is
     (Profile_Not_Checked,
      Profile_Legal,
      Profile_Legal_Defaulted_Formals,
      Profile_Missing_Callable,
      Profile_Missing_Declared_Profile,
      Profile_Missing_Expected_Profile,
      Profile_Kind_Mismatch,
      Profile_Arity_Mismatch,
      Profile_Mode_Conformance_Mismatch,
      Profile_Type_Conformance_Mismatch,
      Profile_Default_Expression_Mismatch,
      Profile_Null_Exclusion_Mismatch,
      Profile_Convention_Mismatch,
      Profile_Result_Type_Mismatch,
      Profile_Access_Profile_Mismatch,
      Profile_Overriding_Profile_Mismatch,
      Profile_Renaming_Profile_Mismatch,
      Profile_Generic_Formal_Profile_Mismatch,
      Profile_Private_View_Barrier,
      Profile_Limited_View_Barrier,
      Profile_Incomplete_View_Barrier,
      Profile_Generic_Formal_View_Barrier,
      Profile_Source_Fingerprint_Mismatch,
      Profile_Profile_Fingerprint_Mismatch,
      Profile_Type_Fingerprint_Mismatch,
      Profile_Multiple_Blockers,
      Profile_Indeterminate);

   type Profile_Info is record
      Id : Profile_Id := No_Profile;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Callable : Callable_Id := No_Callable;
      Kind : Callable_Kind := Callable_Subprogram;
      View : Profile_View_Kind := View_Full;
      Formal_Count : Natural := 0;
      Required_Formal_Count : Natural := 0;
      Result_Type : Type_Id := No_Type;
      Convention : Ada.Strings.Unbounded.Unbounded_String;
      Modes_Conformant : Boolean := True;
      Types_Conformant : Boolean := True;
      Default_Expressions_Conformant : Boolean := True;
      Null_Exclusions_Conformant : Boolean := True;
      Result_Type_Conformant : Boolean := True;
      Access_Profile_Conformant : Boolean := True;
      Overriding_Profile_Conformant : Boolean := True;
      Renaming_Profile_Conformant : Boolean := True;
      Generic_Formal_Profile_Conformant : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Callable_Info is record
      Id : Callable_Id := No_Callable;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Callable_Kind := Callable_Subprogram;
      Declared_Profile : Profile_Id := No_Profile;
      Visible : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Result_Id := No_Result;
      Callable : Callable_Id := No_Callable;
      Declared_Profile : Profile_Id := No_Profile;
      Expected_Profile : Profile_Id := No_Profile;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Context : Profile_Context_Kind := Context_Unknown;
      Expected_Kind : Callable_Kind := Callable_Subprogram;
      Actual_Count : Natural := 0;
      Allow_Defaulted_Formals : Boolean := False;
      Require_Mode_Conformance : Boolean := True;
      Require_Type_Conformance : Boolean := True;
      Require_Default_Conformance : Boolean := False;
      Require_Null_Exclusion_Conformance : Boolean := True;
      Require_Result_Conformance : Boolean := False;
      Require_Access_Profile_Conformance : Boolean := False;
      Require_Overriding_Conformance : Boolean := False;
      Require_Renaming_Conformance : Boolean := False;
      Require_Generic_Formal_Conformance : Boolean := False;
      Expected_Convention : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Callable : Callable_Id := No_Callable;
      Declared_Profile : Profile_Id := No_Profile;
      Expected_Profile : Profile_Id := No_Profile;
      Status : Profile_Status := Profile_Not_Checked;
      Missing_Callable_Blockers : Natural := 0;
      Missing_Declared_Profile_Blockers : Natural := 0;
      Missing_Expected_Profile_Blockers : Natural := 0;
      Kind_Blockers : Natural := 0;
      Arity_Blockers : Natural := 0;
      Defaulted_Formal_Count : Natural := 0;
      Mode_Blockers : Natural := 0;
      Type_Blockers : Natural := 0;
      Default_Blockers : Natural := 0;
      Null_Exclusion_Blockers : Natural := 0;
      Convention_Blockers : Natural := 0;
      Result_Type_Blockers : Natural := 0;
      Access_Profile_Blockers : Natural := 0;
      Overriding_Blockers : Natural := 0;
      Renaming_Blockers : Natural := 0;
      Generic_Formal_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Callable_Model is private;
   type Profile_Model is private;
   type Check_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Callable_Model);
   procedure Clear (Model : in out Profile_Model);
   procedure Clear (Model : in out Check_Model);
   procedure Add_Callable (Model : in out Callable_Model; Info : Callable_Info);
   procedure Add_Profile (Model : in out Profile_Model; Info : Profile_Info);
   procedure Add_Check (Model : in out Check_Model; Info : Check_Info);

   function Build
     (Callables : Callable_Model;
      Profiles : Profile_Model;
      Checks : Check_Model) return Result_Model;

   function Callable_Count (Model : Callable_Model) return Natural;
   function Profile_Count (Model : Profile_Model) return Natural;
   function Check_Count (Model : Check_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Profile_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Callable_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Callable_Info);
   package Profile_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Profile_Info);
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Check_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Callable_Model is record
      Items : Callable_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Profile_Model is record
      Items : Profile_Vectors.Vector;
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

end Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality;
