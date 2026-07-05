with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality is

   --  Case 1298 vertical-slice generic contract and body legality.  This
   --  package performs concrete generic formal/actual matching and optional
   --  generic body replay gating over source-shaped rows: formal types,
   --  formal objects, formal subprograms, formal packages, nested
   --  instantiations, private-view barriers, defaults, and substitution
   --  fingerprints.  It is intentionally not another diagnostic/provenance
   --  layer; it decides whether an instantiation can be trusted under the
   --  generic contract visible at the instantiation point.

   type Instance_Id is new Natural;
   No_Instance : constant Instance_Id := 0;

   type Formal_Id is new Natural;
   No_Formal : constant Formal_Id := 0;

   type Actual_Id is new Natural;
   No_Actual : constant Actual_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Formal_Kind is
     (Formal_Type,
      Formal_Object,
      Formal_Subprogram,
      Formal_Package,
      Formal_Unknown);

   type Actual_Kind is
     (Actual_Type,
      Actual_Object,
      Actual_Subprogram,
      Actual_Package,
      Actual_Unknown);

   type Formal_Mode is
     (Mode_None,
      Mode_In,
      Mode_In_Out,
      Mode_Out,
      Mode_Access,
      Mode_Unknown);

   type Generic_Status is
     (Generic_Not_Checked,
      Generic_Legal_Exact,
      Generic_Legal_Defaulted_Formal_Object,
      Generic_Legal_Formal_Subprogram_Profile,
      Generic_Legal_Formal_Package_Contract,
      Generic_Legal_Nested_Instance,
      Generic_Missing_Actual,
      Generic_Extra_Actual,
      Generic_Formal_Actual_Kind_Mismatch,
      Generic_Type_Class_Mismatch,
      Generic_Object_Mode_Mismatch,
      Generic_Subprogram_Profile_Mismatch,
      Generic_Package_Contract_Mismatch,
      Generic_Private_View_Barrier,
      Generic_Body_Unavailable,
      Generic_Body_Replay_Failed,
      Generic_Nested_Instance_Cycle,
      Generic_Substitution_Fingerprint_Mismatch,
      Generic_Multiple_Blockers,
      Generic_Indeterminate);

   type Instance_Info is record
      Id       : Instance_Id := No_Instance;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Name : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name : Ada.Strings.Unbounded.Unbounded_String;
      Requires_Body_Replay : Boolean := False;
      Body_Available       : Boolean := True;
      Body_Replay_Accepted : Boolean := True;
      Nested_Instance      : Boolean := False;
      Nested_Cycle         : Boolean := False;
      Private_View_Allowed : Boolean := False;
      Formal_Fingerprint      : Natural := 0;
      Actual_Fingerprint      : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Source_Fingerprint      : Natural := 0;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
   end record;

   type Formal_Info is record
      Id       : Formal_Id := No_Formal;
      Instance : Instance_Id := No_Instance;
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Kind     : Formal_Kind := Formal_Unknown;
      Type_Class : Ada.Strings.Unbounded.Unbounded_String;
      Mode       : Formal_Mode := Mode_None;
      Profile    : Ada.Strings.Unbounded.Unbounded_String;
      Package_Contract : Ada.Strings.Unbounded.Unbounded_String;
      Required   : Boolean := True;
      Has_Default : Boolean := False;
      Requires_Private_View : Boolean := False;
      Formal_Fingerprint : Natural := 0;
   end record;

   type Actual_Info is record
      Id       : Actual_Id := No_Actual;
      Instance : Instance_Id := No_Instance;
      Formal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind     : Actual_Kind := Actual_Unknown;
      Type_Class : Ada.Strings.Unbounded.Unbounded_String;
      Mode       : Formal_Mode := Mode_None;
      Profile    : Ada.Strings.Unbounded.Unbounded_String;
      Package_Contract : Ada.Strings.Unbounded.Unbounded_String;
      Uses_Private_View : Boolean := False;
      Actual_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Instance : Instance_Id := No_Instance;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status   : Generic_Status := Generic_Not_Checked;
      Matched_Formals : Natural := 0;
      Defaulted_Formals : Natural := 0;
      Missing_Formals : Natural := 0;
      Extra_Actuals : Natural := 0;
      Kind_Mismatches : Natural := 0;
      Type_Class_Mismatches : Natural := 0;
      Mode_Mismatches : Natural := 0;
      Profile_Mismatches : Natural := 0;
      Package_Contract_Mismatches : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Body_Blockers : Natural := 0;
      Nested_Blockers : Natural := 0;
      Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Fingerprint : Natural := 0;
   end record;

   type Instance_Model is private;
   type Formal_Model is private;
   type Actual_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Instance_Model);
   procedure Clear (Model : in out Formal_Model);
   procedure Clear (Model : in out Actual_Model);

   procedure Add_Instance (Model : in out Instance_Model; Info : Instance_Info);
   procedure Add_Formal (Model : in out Formal_Model; Info : Formal_Info);
   procedure Add_Actual (Model : in out Actual_Model; Info : Actual_Info);

   function Build
     (Instances : Instance_Model;
      Formals   : Formal_Model;
      Actuals   : Actual_Model) return Result_Model;

   function Instance_Count (Model : Instance_Model) return Natural;
   function Formal_Count (Model : Formal_Model) return Natural;
   function Actual_Count (Model : Actual_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info;

   function Count_Status (Model : Result_Model; Status : Generic_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Instance_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Instance_Info);
   package Formal_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Formal_Info);
   package Actual_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Actual_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Instance_Model is record
      Items : Instance_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

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
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality;
