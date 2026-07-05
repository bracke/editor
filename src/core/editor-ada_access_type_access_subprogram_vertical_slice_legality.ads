with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality is

   --  Case 1324 vertical-slice access type and access-to-subprogram legality.
   --  This package models concrete Ada access object, anonymous access,
   --  access-to-subprogram, null-exclusion, designated-view, storage-pool,
   --  storage-size, profile-conformance, and accessibility legality.

   type Access_Type_Id is new Natural;
   No_Access_Type : constant Access_Type_Id := 0;

   type Designated_Type_Id is new Natural;
   No_Designated_Type : constant Designated_Type_Id := 0;

   type Profile_Id is new Natural;
   No_Profile : constant Profile_Id := 0;

   type Pool_Id is new Natural;
   No_Pool : constant Pool_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Access_Kind is
     (Access_Object,
      Access_Subprogram,
      Access_Unknown);

   type Access_Context_Kind is
     (Context_Declaration,
      Context_Allocation,
      Context_Conversion,
      Context_Assignment,
      Context_Return,
      Context_Dereference,
      Context_Access_Attribute,
      Context_Subprogram_Access,
      Context_Unknown);

   type Designated_View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Access_Status is
     (Access_Not_Checked,
      Access_Legal,
      Access_Legal_Runtime_Accessibility_Check,
      Access_Missing_Access_Type,
      Access_Missing_Designated_Type,
      Access_Missing_Profile,
      Access_Kind_Mismatch,
      Access_Private_View_Barrier,
      Access_Limited_View_Barrier,
      Access_Incomplete_View_Barrier,
      Access_Generic_Formal_Barrier,
      Access_Null_Exclusion_Violation,
      Access_Accessibility_Escape,
      Access_Profile_Conformance_Mismatch,
      Access_Convention_Mismatch,
      Access_Storage_Pool_Missing,
      Access_Storage_Pool_Conflict,
      Access_Storage_Size_Non_Static,
      Access_Storage_Size_Conflict,
      Access_Source_Fingerprint_Mismatch,
      Access_Type_Fingerprint_Mismatch,
      Access_Profile_Fingerprint_Mismatch,
      Access_Pool_Fingerprint_Mismatch,
      Access_Multiple_Blockers,
      Access_Indeterminate);

   type Access_Type_Info is record
      Id : Access_Type_Id := No_Access_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Access_Kind := Access_Object;
      Designated : Designated_Type_Id := No_Designated_Type;
      Profile : Profile_Id := No_Profile;
      Null_Exclusion : Boolean := False;
      All_Access : Boolean := False;
      Constant_Access : Boolean := False;
      Anonymous_Access : Boolean := False;
      Storage_Pool : Pool_Id := No_Pool;
      Storage_Size_Static : Boolean := True;
      Storage_Size_Compatible : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Pool_Fingerprint : Natural := 0;
      Expected_Pool_Fingerprint : Natural := 0;
   end record;

   type Designated_Type_Info is record
      Id : Designated_Type_Id := No_Designated_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      View : Designated_View_Kind := View_Full;
      Is_Limited : Boolean := False;
      Is_Incomplete : Boolean := False;
      Master_Depth : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Profile_Info is record
      Id : Profile_Id := No_Profile;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Count : Natural := 0;
      Result_Type : Designated_Type_Id := No_Designated_Type;
      Convention : Ada.Strings.Unbounded.Unbounded_String;
      Parameter_Modes_Compatible : Boolean := True;
      Type_Profile_Compatible : Boolean := True;
      Null_Exclusions_Compatible : Boolean := True;
      Accessibility_Level : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
   end record;

   type Access_Use_Info is record
      Id : Result_Id := No_Result;
      Access_Type : Access_Type_Id := No_Access_Type;
      Designated : Designated_Type_Id := No_Designated_Type;
      Profile : Profile_Id := No_Profile;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Context : Access_Context_Kind := Context_Unknown;
      Expected_Kind : Access_Kind := Access_Object;
      Null_Exclusion_Required : Boolean := False;
      May_Be_Null : Boolean := False;
      Source_Master_Depth : Natural := 0;
      Target_Master_Depth : Natural := 0;
      Runtime_Accessibility_Check_Allowed : Boolean := False;
      Requires_Profile_Conformance : Boolean := False;
      Convention_Compatible : Boolean := True;
      Requires_Storage_Pool : Boolean := False;
      Requires_Static_Storage_Size : Boolean := False;
      Storage_Size_Static : Boolean := True;
      Storage_Size_Compatible : Boolean := True;
      Pool : Pool_Id := No_Pool;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Pool_Fingerprint : Natural := 0;
      Expected_Pool_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Access_Type : Access_Type_Id := No_Access_Type;
      Designated : Designated_Type_Id := No_Designated_Type;
      Profile : Profile_Id := No_Profile;
      Status : Access_Status := Access_Not_Checked;
      Missing_Access_Type_Blockers : Natural := 0;
      Missing_Designated_Type_Blockers : Natural := 0;
      Missing_Profile_Blockers : Natural := 0;
      Kind_Mismatch_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_Blockers : Natural := 0;
      Null_Exclusion_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Runtime_Accessibility_Checks : Natural := 0;
      Profile_Conformance_Blockers : Natural := 0;
      Convention_Blockers : Natural := 0;
      Storage_Pool_Missing_Blockers : Natural := 0;
      Storage_Pool_Conflict_Blockers : Natural := 0;
      Storage_Size_Non_Static_Blockers : Natural := 0;
      Storage_Size_Conflict_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Pool_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Access_Type_Model is private;
   type Designated_Type_Model is private;
   type Profile_Model is private;
   type Use_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Access_Type_Model);
   procedure Clear (Model : in out Designated_Type_Model);
   procedure Clear (Model : in out Profile_Model);
   procedure Clear (Model : in out Use_Model);
   procedure Add_Access_Type (Model : in out Access_Type_Model; Info : Access_Type_Info);
   procedure Add_Designated_Type (Model : in out Designated_Type_Model; Info : Designated_Type_Info);
   procedure Add_Profile (Model : in out Profile_Model; Info : Profile_Info);
   procedure Add_Use (Model : in out Use_Model; Info : Access_Use_Info);

   function Build
     (Access_Types : Access_Type_Model;
      Designated_Types : Designated_Type_Model;
      Profiles : Profile_Model;
      Uses : Use_Model) return Result_Model;

   function Access_Type_Count (Model : Access_Type_Model) return Natural;
   function Designated_Type_Count (Model : Designated_Type_Model) return Natural;
   function Profile_Count (Model : Profile_Model) return Natural;
   function Use_Count (Model : Use_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Access_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Access_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Access_Type_Info);
   package Designated_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Designated_Type_Info);
   package Profile_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Profile_Info);
   package Use_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Access_Use_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Access_Type_Model is record
      Items : Access_Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Designated_Type_Model is record
      Items : Designated_Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Profile_Model is record
      Items : Profile_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Use_Model is record
      Items : Use_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Access_Type_Access_Subprogram_Vertical_Slice_Legality;
