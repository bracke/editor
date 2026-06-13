with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Generic_Object_Default_Type_Conformance;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_View_Aware_Compatibility;

package Editor.Ada_Generic_View_Compatibility is

   --  Compiler-grade generic-contract bridge for private and limited views.
   --  This package consumes already snapshot-owned generic object/default
   --  conformance metadata and view-aware expression compatibility metadata,
   --  then classifies whether a generic actual/default failure is caused by an
   --  ordinary type/static mismatch or by a private/limited/cross-unit view
   --  barrier.  It performs no parsing, file IO, buffer mutation, command
   --  registration, workspace mutation, or rendering-side semantic work.

   type Generic_View_Status is
     (Generic_View_Not_Checked,
      Generic_View_Compatible,
      Generic_View_Private_Barrier,
      Generic_View_Limited_Barrier,
      Generic_View_Cross_Unit_Unresolved,
      Generic_View_Object_Mismatch,
      Generic_View_Object_Unknown,
      Generic_View_No_View_Metadata);

   type Generic_View_Compatibility_Id is new Natural;
   No_Generic_View_Compatibility : constant Generic_View_Compatibility_Id := 0;

   type Generic_View_Compatibility_Info is record
      Id              : Generic_View_Compatibility_Id := No_Generic_View_Compatibility;
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal          : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Instance_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Expression_Text : Ada.Strings.Unbounded.Unbounded_String;
      Is_Default      : Boolean := False;
      Object_Status   : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Status :=
        Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Unsupported;
      View             : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Id :=
        Editor.Ada_View_Aware_Compatibility.No_View_Compatibility;
      View_Status      : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status :=
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked;
      Cross_Unit_Target   : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Selector : Ada.Strings.Unbounded.Unbounded_String;
      Status          : Generic_View_Status := Generic_View_Not_Checked;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   package Generic_View_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_View_Compatibility_Info);

   type Generic_View_Compatibility_Model is private;

   function Build
     (Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Views           : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Generic_View_Compatibility_Model;

   function Entry_Count (Model : Generic_View_Compatibility_Model) return Natural;

   function Entry_At
     (Model : Generic_View_Compatibility_Model;
      Index : Positive) return Generic_View_Compatibility_Info;

   function First_For_Formal
     (Model    : Generic_View_Compatibility_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Generic_View_Compatibility_Info;

   function Count_Status
     (Model  : Generic_View_Compatibility_Model;
      Status : Generic_View_Status) return Natural;

   function Compatible_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function Private_Barrier_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function Limited_Barrier_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function Unresolved_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function Object_Mismatch_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function Unknown_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function No_View_Metadata_Count (Model : Generic_View_Compatibility_Model) return Natural;
   function Fingerprint (Model : Generic_View_Compatibility_Model) return Natural;

private
   type Generic_View_Compatibility_Model is record
      Entries                : Generic_View_Vectors.Vector;
      Compatible_Total       : Natural := 0;
      Private_Barrier_Total  : Natural := 0;
      Limited_Barrier_Total  : Natural := 0;
      Unresolved_Total       : Natural := 0;
      Object_Mismatch_Total  : Natural := 0;
      Unknown_Total          : Natural := 0;
      No_View_Metadata_Total : Natural := 0;
      Model_Fingerprint      : Natural := 0;
   end record;

end Editor.Ada_Generic_View_Compatibility;
