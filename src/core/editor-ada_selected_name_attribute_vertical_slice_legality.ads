with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality is

   --  Case 1316 vertical-slice selected-name/attribute/reference legality.
   --  This package models concrete Ada selected-name resolution, attribute
   --  reference legality, dereference/index/component reference checks, and
   --  private/limited-view barriers that feed overload resolution, static
   --  expression evaluation, representation legality, accessibility, and
   --  membership/case-choice consumers.  It is rule-oriented and avoids the
   --  older diagnostic/provenance/recheck wrapper pattern.

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Reference_Kind is
     (Reference_Selected_Name,
      Reference_Expanded_Name,
      Reference_Attribute,
      Reference_Discriminant,
      Reference_Record_Component,
      Reference_Array_Component,
      Reference_Generalized_Indexing,
      Reference_Explicit_Dereference,
      Reference_Implicit_Dereference,
      Reference_Access_Attribute,
      Reference_Address_Attribute,
      Reference_Size_Attribute,
      Reference_First_Last_Range_Attribute,
      Reference_Image_Value_Attribute,
      Reference_Callable_Entity,
      Reference_Unknown);

   type Entity_Kind is
     (Entity_Unknown,
      Entity_Package,
      Entity_Type,
      Entity_Subtype,
      Entity_Object,
      Entity_Component,
      Entity_Discriminant,
      Entity_Subprogram,
      Entity_Entry,
      Entity_Exception,
      Entity_Generic,
      Entity_Attribute,
      Entity_Access_Value,
      Entity_Literal,
      Entity_Not_Entity);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Attribute_Class is
     (Attribute_None,
      Attribute_Scalar_Static,
      Attribute_Array_Bounds,
      Attribute_Image_Value,
      Attribute_Access,
      Attribute_Address,
      Attribute_Size_Alignment,
      Attribute_Stream,
      Attribute_Callable,
      Attribute_Representation,
      Attribute_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Resolution_Evidence,
      Legality_Prefix_Not_Visible,
      Legality_Selected_Entity_Not_Visible,
      Legality_Prefix_Not_Composite,
      Legality_No_Such_Selector,
      Legality_Ambiguous_Selector,
      Legality_Wrong_Entity_Kind,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Attribute_Not_Defined,
      Legality_Attribute_Prefix_Not_Allowed,
      Legality_Attribute_Result_Type_Mismatch,
      Legality_Attribute_Not_Static,
      Legality_Dereference_Non_Access,
      Legality_Null_Access_Runtime_Check,
      Legality_Index_Profile_Mismatch,
      Legality_Index_Count_Mismatch,
      Legality_Component_Type_Mismatch,
      Legality_Accessibility_Blocker,
      Legality_Representation_Blocker,
      Legality_Overload_Blocker,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Resolution_Fingerprint_Mismatch,
      Legality_View_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Reference_Info is record
      Id       : Check_Id := No_Check;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Reference_Kind := Reference_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Prefix_Entity : Entity_Kind := Entity_Unknown;
      Selected_Entity : Entity_Kind := Entity_Unknown;
      Expected_Entity : Entity_Kind := Entity_Unknown;
      Prefix_View : View_Kind := View_Full;
      Attribute : Attribute_Class := Attribute_None;

      Has_AST_Coverage : Boolean := True;
      Has_Resolution_Evidence : Boolean := True;
      Prefix_Visible : Boolean := True;
      Selected_Visible : Boolean := True;
      Prefix_Is_Composite : Boolean := True;
      Selector_Exists : Boolean := True;
      Selector_Ambiguous : Boolean := False;
      Entity_Kind_Compatible : Boolean := True;
      Private_View_Allows_Selection : Boolean := True;
      Limited_View_Allows_Selection : Boolean := True;
      Incomplete_View_Allows_Selection : Boolean := True;
      Generic_Formal_View_Allows_Selection : Boolean := True;

      Attribute_Defined : Boolean := True;
      Attribute_Prefix_Allowed : Boolean := True;
      Attribute_Result_Type_Compatible : Boolean := True;
      Attribute_Static_Required : Boolean := False;
      Attribute_Is_Static : Boolean := True;

      Prefix_Is_Access : Boolean := True;
      Access_Value_May_Be_Null : Boolean := False;
      Null_Check_Allowed : Boolean := True;
      Index_Profile_Compatible : Boolean := True;
      Index_Count_Compatible : Boolean := True;
      Component_Type_Compatible : Boolean := True;
      Accessibility_OK : Boolean := True;
      Representation_OK : Boolean := True;
      Overload_OK : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Resolution_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Resolution_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Check    : Check_Id := No_Check;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Reference_Kind := Reference_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Resolution_Blockers : Natural := 0;
      Prefix_Visibility_Blockers : Natural := 0;
      Selected_Visibility_Blockers : Natural := 0;
      Prefix_Composite_Blockers : Natural := 0;
      Missing_Selector_Blockers : Natural := 0;
      Ambiguous_Selector_Blockers : Natural := 0;
      Entity_Kind_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Attribute_Defined_Blockers : Natural := 0;
      Attribute_Prefix_Blockers : Natural := 0;
      Attribute_Result_Blockers : Natural := 0;
      Attribute_Static_Blockers : Natural := 0;
      Dereference_Blockers : Natural := 0;
      Null_Runtime_Check_Required : Boolean := False;
      Index_Profile_Blockers : Natural := 0;
      Index_Count_Blockers : Natural := 0;
      Component_Type_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Representation_Blockers : Natural := 0;
      Overload_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Resolution_Fingerprint_Blockers : Natural := 0;
      View_Fingerprint_Blockers : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Reference_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Reference_Model);
   procedure Add_Reference (Model : in out Reference_Model; Info : Reference_Info);

   function Build (References : Reference_Model) return Result_Model;

   function Reference_Count (Model : Reference_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Reference_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Reference_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Reference_Model is record
      Items : Reference_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality;
