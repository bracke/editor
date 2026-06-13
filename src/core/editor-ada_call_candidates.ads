with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Use_Visibility;

package Editor.Ada_Call_Candidates is

   --  Compiler-grade overload-resolution foundation.  This model classifies
   --  parser-owned call-shaped syntax nodes and records the callable
   --  declarations that are potentially denoted before expected-type and
   --  profile filtering.  It is deterministic and snapshot-owned; it performs
   --  no file IO, no compiler invocation, no renderer-side parsing, and no
   --  editor-state mutation.

   type Candidate_Source is
     (Candidate_Direct_Visible,
      Candidate_Use_Package_Visible,
      Candidate_Use_Type_Primitive);

   type Call_Candidate_Status is
     (Call_Candidate_Not_Resolved,
      Call_Candidate_No_Call_Name,
      Call_Candidate_No_Candidates,
      Call_Candidate_Found,
      Call_Candidate_Ambiguous);

   type Call_Candidate_Id is new Natural;
   No_Call_Candidate : constant Call_Candidate_Id := 0;

   type Call_Candidate_Info is record
      Id                     : Call_Candidate_Id := No_Call_Candidate;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region                 : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Source                 : Candidate_Source := Candidate_Direct_Visible;
      Declaration            : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Status                 : Call_Candidate_Status := Call_Candidate_Not_Resolved;
      Candidate_Count        : Natural := 0;
      Start_Line             : Positive := 1;
      End_Line               : Positive := 1;
      Fingerprint            : Natural := 0;
   end record;

   type Call_Candidate_Model is private;

   procedure Clear (Model : in out Call_Candidate_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model)
      return Call_Candidate_Model;

   function Has_Call_Candidates (Model : Call_Candidate_Model) return Boolean;
   function Call_Candidate_Count (Model : Call_Candidate_Model) return Natural;
   function Call_Candidate_At
     (Model : Call_Candidate_Model;
      Index : Positive) return Call_Candidate_Info;
   function Call_Candidate
     (Model : Call_Candidate_Model;
      Id    : Call_Candidate_Id) return Call_Candidate_Info;

   function Candidate_Count_For_Node
     (Model : Call_Candidate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural;

   function Candidate_At_For_Node
     (Model : Call_Candidate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id;
      Index : Positive) return Call_Candidate_Info;

   function Lookup_Call
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result;

   function Fingerprint (Model : Call_Candidate_Model) return Natural;

private
   package Call_Candidate_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Call_Candidate_Info);

   type Call_Candidate_Model is record
      Candidates         : Call_Candidate_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Call_Candidates;
