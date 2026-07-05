with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality is

   --  Case 1327 vertical-slice assignment and conversion legality.
   --  This package models source-shaped Ada assignment statements,
   --  qualified expressions, type conversions, view conversions,
   --  class-wide conversions, numeric conversions, and access conversions.
   --  It consumes semantic evidence rows and produces deterministic legality
   --  results without touching editor-visible state.

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Type_Kind is
     (Type_Scalar,
      Type_Integer,
      Type_Real,
      Type_Modular,
      Type_Fixed,
      Type_Access_Object,
      Type_Access_Subprogram,
      Type_Array,
      Type_Record,
      Type_Tagged,
      Type_Class_Wide,
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

   type Operation_Kind is
     (Operation_Assignment,
      Operation_Type_Conversion,
      Operation_Qualified_Expression,
      Operation_View_Conversion,
      Operation_Class_Wide_Conversion,
      Operation_Numeric_Conversion,
      Operation_Access_Conversion,
      Operation_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_Check,
      Legality_Missing_Target,
      Legality_Missing_Source,
      Legality_Missing_Target_Type,
      Legality_Missing_Source_Type,
      Legality_Assignment_Target_Not_Variable,
      Legality_Assignment_To_Limited_View,
      Legality_Type_Mismatch,
      Legality_Conversion_Not_Allowed,
      Legality_View_Conversion_Not_Allowed,
      Legality_Class_Wide_Conversion_Not_Allowed,
      Legality_Numeric_Conversion_Not_Allowed,
      Legality_Access_Conversion_Not_Allowed,
      Legality_Null_Exclusion_Violation,
      Legality_Accessibility_Blocker,
      Legality_Range_Blocker,
      Legality_Predicate_Blocker,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Controlled_Finalization_Blocker,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Entity_Info is record
      Id : Entity_Id := No_Entity;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Typ : Type_Id := No_Type;
      View : View_Kind := View_Full;
      Is_Variable_View : Boolean := True;
      Is_Limited_View : Boolean := False;
      Null_Exclusion : Boolean := False;
      Accessibility_Level : Natural := 0;
      Controlled_Or_Finalized : Boolean := False;
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
      Base_Type : Type_Id := No_Type;
      Root_Type : Type_Id := No_Type;
      Designated_Type : Type_Id := No_Type;
      Is_Tagged : Boolean := False;
      Is_Class_Wide : Boolean := False;
      Is_Numeric : Boolean := False;
      Is_Access : Boolean := False;
      Is_Limited : Boolean := False;
      Is_Private : Boolean := False;
      Conversion_Profile_Conformant : Boolean := True;
      Access_Profile_Conformant : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Check_Id := No_Check;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation : Operation_Kind := Operation_Unknown;
      Target : Entity_Id := No_Entity;
      Source : Entity_Id := No_Entity;
      Target_Type : Type_Id := No_Type;
      Source_Type : Type_Id := No_Type;
      Expected_Type : Type_Id := No_Type;
      Explicit_Conversion : Boolean := False;
      Source_Is_Null : Boolean := False;
      Target_Null_Excluding : Boolean := False;
      Static_Range_OK : Boolean := True;
      Predicate_OK : Boolean := True;
      Accessibility_OK : Boolean := True;
      Runtime_Range_Check_Required : Boolean := False;
      Runtime_Predicate_Check_Required : Boolean := False;
      Runtime_Accessibility_Check_Required : Boolean := False;
      Type_Compatibility_OK : Boolean := True;
      View_Conversion_OK : Boolean := True;
      Class_Wide_Conversion_OK : Boolean := True;
      Numeric_Conversion_OK : Boolean := True;
      Access_Conversion_OK : Boolean := True;
      Controlled_Finalization_OK : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Check : Check_Id := No_Check;
      Target : Entity_Id := No_Entity;
      Source : Entity_Id := No_Entity;
      Target_Type : Type_Id := No_Type;
      Source_Type : Type_Id := No_Type;
      Operation : Operation_Kind := Operation_Unknown;
      Status : Legality_Status := Legality_Not_Checked;
      Missing_Check_Blockers : Natural := 0;
      Missing_Target_Blockers : Natural := 0;
      Missing_Source_Blockers : Natural := 0;
      Missing_Target_Type_Blockers : Natural := 0;
      Missing_Source_Type_Blockers : Natural := 0;
      Target_Variable_Blockers : Natural := 0;
      Limited_Assignment_Blockers : Natural := 0;
      Type_Mismatch_Blockers : Natural := 0;
      Conversion_Blockers : Natural := 0;
      View_Conversion_Blockers : Natural := 0;
      Class_Wide_Conversion_Blockers : Natural := 0;
      Numeric_Conversion_Blockers : Natural := 0;
      Access_Conversion_Blockers : Natural := 0;
      Null_Exclusion_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Range_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Controlled_Finalization_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
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

end Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality;
