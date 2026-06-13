with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Language_Model;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Stream_Attribute_Profile_Conformance is

   --  Compiler-grade stream attribute profile conformance layer.  This model
   --  consumes representation-legality stream clauses and callable-profile
   --  metadata, then classifies target-type stream attribute handlers without
   --  applying edits, reparsing, invoking a compiler, touching buffers, or
   --  performing rendering-side semantic work.

   type Stream_Profile_Conformance_Status is
     (Stream_Profile_Conformance_Compatible,
      Stream_Profile_Conformance_Target_Error,
      Stream_Profile_Conformance_Handler_Malformed,
      Stream_Profile_Conformance_Handler_Missing,
      Stream_Profile_Conformance_Handler_Ambiguous,
      Stream_Profile_Conformance_Arity_Mismatch,
      Stream_Profile_Conformance_Result_Mismatch,
      Stream_Profile_Conformance_Mode_Requires_Procedure,
      Stream_Profile_Conformance_Mode_Requires_Function,
      Stream_Profile_Conformance_Profile_Unknown,
      Stream_Profile_Conformance_Not_Stream_Attribute,
      Stream_Profile_Conformance_Unknown);

   type Stream_Profile_Conformance_Info is record
      Clause_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Kind    : Editor.Ada_Language_Model.Representation_Clause_Kind :=
        Editor.Ada_Language_Model.Representation_Other_Clause;
      Handler_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Handler : Ada.Strings.Unbounded.Unbounded_String;
      Callable_Profile  : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id :=
        Editor.Ada_Call_Profile_Shapes.No_Callable_Profile;
      Parameter_Count   : Natural := 0;
      Result_Subtype    : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count   : Natural := 0;
      Source_Line       : Positive := 1;
      Status            : Stream_Profile_Conformance_Status :=
        Stream_Profile_Conformance_Unknown;
      Source_Fingerprint : Natural := 0;
      Fingerprint       : Natural := 0;
   end record;

   type Stream_Profile_Conformance_Model is private;

   procedure Clear (Model : in out Stream_Profile_Conformance_Model);

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Profiles : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Stream_Profile_Conformance_Model;

   function Check_Count (Model : Stream_Profile_Conformance_Model) return Natural;

   function Check_At
     (Model : Stream_Profile_Conformance_Model;
      Index : Positive) return Stream_Profile_Conformance_Info;

   function First_For_Target
     (Model  : Stream_Profile_Conformance_Model;
      Target : String) return Stream_Profile_Conformance_Info;

   function First_For_Handler
     (Model   : Stream_Profile_Conformance_Model;
      Handler : String) return Stream_Profile_Conformance_Info;

   function Count_Status
     (Model  : Stream_Profile_Conformance_Model;
      Status : Stream_Profile_Conformance_Status) return Natural;

   function Compatible_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Target_Error_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Missing_Handler_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Ambiguous_Handler_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Arity_Mismatch_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Result_Mismatch_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Mode_Mismatch_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Unknown_Count (Model : Stream_Profile_Conformance_Model) return Natural;
   function Fingerprint (Model : Stream_Profile_Conformance_Model) return Natural;

private
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Stream_Profile_Conformance_Info);

   type Counter_Array is array (Stream_Profile_Conformance_Status) of Natural;

   type Stream_Profile_Conformance_Model is record
      Checks             : Info_Vectors.Vector;
      Status_Counts      : Counter_Array := (others => 0);
      Compatible_Total   : Natural := 0;
      Target_Error_Total : Natural := 0;
      Missing_Total      : Natural := 0;
      Ambiguous_Total    : Natural := 0;
      Arity_Mismatch_Total : Natural := 0;
      Result_Mismatch_Total : Natural := 0;
      Mode_Mismatch_Total : Natural := 0;
      Unknown_Total      : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Stream_Attribute_Profile_Conformance;
