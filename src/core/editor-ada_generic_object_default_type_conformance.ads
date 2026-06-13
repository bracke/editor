with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Generic_Object_Default_Type_Conformance is

   --  Compiler-grade generic formal-object expression type conformance
   --  foundation.  Earlier generic-contract passes classified formal-object
   --  defaults and explicit object actuals by static legality.  This projection
   --  adds the next semantic layer: the default/actual expression is compared
   --  with the formal object's expected subtype, using staged static-expression
   --  metadata and the declaration-derived type graph where available.

   type Object_Default_Type_Status is
     (Object_Default_Type_Default_Compatible,
      Object_Default_Type_Actual_Compatible,
      Object_Default_Type_Default_Type_Mismatch,
      Object_Default_Type_Actual_Type_Mismatch,
      Object_Default_Type_Static_Range_Error,
      Object_Default_Type_Static_Value_Unknown,
      Object_Default_Type_Formal_Subtype_Unknown,
      Object_Default_Type_Actual_Missing,
      Object_Default_Type_Default_Missing,
      Object_Default_Type_Unsupported);

   type Object_Default_Type_Info is record
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal          : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Instance_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Type     : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Expression_Text : Ada.Strings.Unbounded.Unbounded_String;
      Is_Default      : Boolean := False;
      Static_Status   : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Status          : Object_Default_Type_Status :=
        Object_Default_Type_Unsupported;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Object_Default_Type_Model is private;

   procedure Clear (Model : in out Object_Default_Type_Model);

   function Build
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Static    : Editor.Ada_Static_Expressions.Static_Model;
      Types     : Editor.Ada_Type_Graph.Type_Model)
      return Object_Default_Type_Model;

   function Check_Count (Model : Object_Default_Type_Model) return Natural;

   function Check_At
     (Model : Object_Default_Type_Model;
      Index : Positive) return Object_Default_Type_Info;

   function Compatible_Count (Model : Object_Default_Type_Model) return Natural;
   function Mismatch_Count (Model : Object_Default_Type_Model) return Natural;
   function Range_Error_Count (Model : Object_Default_Type_Model) return Natural;
   function Unknown_Count (Model : Object_Default_Type_Model) return Natural;
   function Default_Checked_Count (Model : Object_Default_Type_Model) return Natural;
   function Actual_Checked_Count (Model : Object_Default_Type_Model) return Natural;
   function Fingerprint (Model : Object_Default_Type_Model) return Natural;

private
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Object_Default_Type_Info);

   type Object_Default_Type_Model is record
      Checks              : Check_Vectors.Vector;
      Compatible_Total    : Natural := 0;
      Mismatch_Total      : Natural := 0;
      Range_Error_Total   : Natural := 0;
      Unknown_Total       : Natural := 0;
      Default_Checked_Total : Natural := 0;
      Actual_Checked_Total  : Natural := 0;
      Result_Fingerprint  : Natural := 0;
   end record;

end Editor.Ada_Generic_Object_Default_Type_Conformance;
