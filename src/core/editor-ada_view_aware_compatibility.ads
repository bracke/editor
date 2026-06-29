with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_View_Aware_Compatibility is

   --  Compiler-grade compatibility bridge for private and limited views.
   --  This package consumes already snapshot-owned expression/type metadata and
   --  classifies the view-related cases that must participate in later subtype,
   --  overload, generic-contract, and diagnostic consumers.  It performs no
   --  parsing, file IO, buffer mutation, command registration, workspace
   --  mutation, or rendering-side semantic work.

   type View_Compatibility_Status is
     (View_Compatibility_Not_Checked,
      View_Compatibility_Compatible,
      View_Compatibility_Private_Partial_View,
      View_Compatibility_Private_Full_View,
      View_Compatibility_Private_Full_View_Hidden,
      View_Compatibility_Limited_Incomplete_View,
      View_Compatibility_Limited_Full_View_Hidden,
      View_Compatibility_Cross_Unit_Private_View,
      View_Compatibility_Cross_Unit_Unresolved,
      View_Compatibility_Requires_Explicit_Conversion,
      View_Compatibility_Known_Incompatible,
      View_Compatibility_Indeterminate);

   type View_Compatibility_Id is new Natural;
   No_View_Compatibility : constant View_Compatibility_Id := 0;

   type View_Compatibility_Info is record
      Id                    : View_Compatibility_Id := No_View_Compatibility;
      Expression            : Editor.Ada_Expression_Types.Expression_Type_Id :=
        Editor.Ada_Expression_Types.No_Expression_Type;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Source_Status         : Editor.Ada_Expression_Types.Expression_Type_Status :=
        Editor.Ada_Expression_Types.Expression_Type_Not_Checked;
      Selected_Name         : Editor.Ada_Selected_Name_Resolution.Selected_Name_Id :=
        Editor.Ada_Selected_Name_Resolution.No_Selected_Name;
      Selected_Name_Status  : Editor.Ada_Selected_Name_Resolution.Selected_Name_Status :=
        Editor.Ada_Selected_Name_Resolution.Selected_Name_Not_Resolved;
      Expected_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Subtype        : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Target     : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Selector   : Ada.Strings.Unbounded.Unbounded_String;
      Status                : View_Compatibility_Status :=
        View_Compatibility_Not_Checked;
      Start_Line            : Positive := 1;
      End_Line              : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   package View_Compatibility_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => View_Compatibility_Info);

   type View_Compatibility_Model is private;

   function Classify_Subtype_Compatibility
     (Info : Editor.Ada_Subtype_Compatibility.Compatibility_Info)
      return View_Compatibility_Status;

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return View_Compatibility_Model;

   function Entry_Count (Model : View_Compatibility_Model) return Natural;

   function Entry_At
     (Model : View_Compatibility_Model;
      Index : Positive) return View_Compatibility_Info;

   function First_For_Expression
     (Model      : View_Compatibility_Model;
      Expression : Editor.Ada_Expression_Types.Expression_Type_Id)
      return View_Compatibility_Info;

   function Count_Status
     (Model  : View_Compatibility_Model;
      Status : View_Compatibility_Status) return Natural;

   function Compatible_Count (Model : View_Compatibility_Model) return Natural;
   function Private_View_Count (Model : View_Compatibility_Model) return Natural;
   function Limited_View_Count (Model : View_Compatibility_Model) return Natural;
   function Unresolved_Count (Model : View_Compatibility_Model) return Natural;
   function Incompatible_Count (Model : View_Compatibility_Model) return Natural;
   function Indeterminate_Count (Model : View_Compatibility_Model) return Natural;
   function Fingerprint (Model : View_Compatibility_Model) return Natural;

private
   type View_Compatibility_Model is record
      Entries             : View_Compatibility_Vectors.Vector;
      Compatible_Total    : Natural := 0;
      Private_Total       : Natural := 0;
      Limited_Total       : Natural := 0;
      Unresolved_Total    : Natural := 0;
      Explicit_Total      : Natural := 0;
      Incompatible_Total  : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Model_Fingerprint   : Natural := 0;
   end record;

end Editor.Ada_View_Aware_Compatibility;
