with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Aggregate_Legality_Vertical_Slice is

   --  Pass1326 vertical-slice aggregate legality.
   --  This package models source-shaped Ada aggregate legality across array,
   --  record, extension, delta, container, and null aggregate forms.  The
   --  checker intentionally consumes concrete semantic evidence rows rather
   --  than diagnostic projection state, so it can compose with array,
   --  discriminant/variant, initialization, predicate, accessibility, and
   --  static-choice slices without mutating editor-visible state.

   type Aggregate_Id is new Natural;
   No_Aggregate : constant Aggregate_Id := 0;

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Aggregate_Kind is
     (Aggregate_Array,
      Aggregate_Record,
      Aggregate_Extension,
      Aggregate_Delta,
      Aggregate_Container,
      Aggregate_Null,
      Aggregate_Unknown);

   type Expected_Type_Kind is
     (Expected_Array,
      Expected_Record,
      Expected_Tagged_Record,
      Expected_Container,
      Expected_Null_Record,
      Expected_Unknown);

   type Aggregate_View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Association_Form is
     (Associations_None,
      Associations_Positional,
      Associations_Named,
      Associations_Mixed,
      Associations_Unknown);

   type Aggregate_Status is
     (Aggregate_Not_Checked,
      Aggregate_Legal,
      Aggregate_Legal_With_Defaulted_Components,
      Aggregate_Legal_With_Runtime_Check,
      Aggregate_Missing_Aggregate,
      Aggregate_Missing_Expected_Type,
      Aggregate_Kind_Mismatch,
      Aggregate_Association_Form_Mismatch,
      Aggregate_Missing_Component_Association,
      Aggregate_Extra_Component_Association,
      Aggregate_Duplicate_Component_Association,
      Aggregate_Component_Type_Mismatch,
      Aggregate_Static_Choice_Required,
      Aggregate_Choice_Overlap,
      Aggregate_Discriminant_Mismatch,
      Aggregate_Variant_Mismatch,
      Aggregate_Extension_Ancestor_Mismatch,
      Aggregate_Delta_Target_Mismatch,
      Aggregate_Container_Profile_Mismatch,
      Aggregate_Null_Not_Allowed,
      Aggregate_Controlled_Finalized_Component_Blocker,
      Aggregate_Accessibility_Blocker,
      Aggregate_Predicate_Blocker,
      Aggregate_Private_View_Barrier,
      Aggregate_Limited_View_Barrier,
      Aggregate_Incomplete_View_Barrier,
      Aggregate_Generic_Formal_View_Barrier,
      Aggregate_Source_Fingerprint_Mismatch,
      Aggregate_AST_Fingerprint_Mismatch,
      Aggregate_Type_Fingerprint_Mismatch,
      Aggregate_Static_Fingerprint_Mismatch,
      Aggregate_Multiple_Blockers,
      Aggregate_Indeterminate);

   type Expected_Type_Info is record
      Id : Type_Id := No_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind : Expected_Type_Kind := Expected_Unknown;
      View : Aggregate_View_Kind := View_Full;
      Required_Component_Count : Natural := 0;
      Allows_Defaulted_Components : Boolean := False;
      Allows_Null_Aggregate : Boolean := False;
      Discriminants_Conformant : Boolean := True;
      Variants_Conformant : Boolean := True;
      Component_Types_Conformant : Boolean := True;
      Container_Profile_Conformant : Boolean := True;
      Controlled_Or_Finalized_Component : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Aggregate_Info is record
      Id : Aggregate_Id := No_Aggregate;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Aggregate_Kind := Aggregate_Unknown;
      Expected_Type : Type_Id := No_Type;
      View : Aggregate_View_Kind := View_Full;
      Associations : Association_Form := Associations_Unknown;
      Association_Count : Natural := 0;
      Named_Association_Count : Natural := 0;
      Positional_Association_Count : Natural := 0;
      Duplicate_Associations : Natural := 0;
      Extra_Associations : Natural := 0;
      Missing_Associations : Natural := 0;
      Component_Type_Mismatches : Natural := 0;
      Static_Choices_Required : Boolean := False;
      Static_Choices_Present : Boolean := True;
      Choice_Overlaps : Natural := 0;
      Discriminants_OK : Boolean := True;
      Variants_OK : Boolean := True;
      Extension_Ancestor_OK : Boolean := True;
      Delta_Target_OK : Boolean := True;
      Container_Profile_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Runtime_Check_Required : Boolean := False;
      Defaulted_Component_Count : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Static_Fingerprint : Natural := 0;
      Expected_Static_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Aggregate : Aggregate_Id := No_Aggregate;
      Expected_Type : Type_Id := No_Type;
      Status : Aggregate_Status := Aggregate_Not_Checked;
      Missing_Aggregate_Blockers : Natural := 0;
      Missing_Expected_Type_Blockers : Natural := 0;
      Kind_Blockers : Natural := 0;
      Association_Form_Blockers : Natural := 0;
      Missing_Association_Blockers : Natural := 0;
      Extra_Association_Blockers : Natural := 0;
      Duplicate_Association_Blockers : Natural := 0;
      Component_Type_Blockers : Natural := 0;
      Static_Choice_Blockers : Natural := 0;
      Choice_Overlap_Blockers : Natural := 0;
      Discriminant_Blockers : Natural := 0;
      Variant_Blockers : Natural := 0;
      Extension_Ancestor_Blockers : Natural := 0;
      Delta_Target_Blockers : Natural := 0;
      Container_Profile_Blockers : Natural := 0;
      Null_Aggregate_Blockers : Natural := 0;
      Controlled_Finalized_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Static_Fingerprint_Blockers : Natural := 0;
      Defaulted_Component_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Aggregate_Model is private;
   type Expected_Type_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Aggregate_Model);
   procedure Clear (Model : in out Expected_Type_Model);
   procedure Add_Aggregate (Model : in out Aggregate_Model; Info : Aggregate_Info);
   procedure Add_Expected_Type (Model : in out Expected_Type_Model; Info : Expected_Type_Info);

   function Build
     (Aggregates : Aggregate_Model;
      Expected_Types : Expected_Type_Model) return Result_Model;

   function Aggregate_Count (Model : Aggregate_Model) return Natural;
   function Expected_Type_Count (Model : Expected_Type_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Aggregate_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Aggregate_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Aggregate_Info);
   package Expected_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Expected_Type_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Aggregate_Model is record
      Items : Aggregate_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Expected_Type_Model is record
      Items : Expected_Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Aggregate_Legality_Vertical_Slice;
