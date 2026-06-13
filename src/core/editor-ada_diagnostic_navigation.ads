with Ada.Containers.Vectors;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Navigation is

   --  Deterministic IDE-facing navigation over the snapshot-guarded Ada
   --  semantic diagnostic index.  This package performs no parsing, file IO,
   --  buffer mutation, command registration, workspace mutation, or rendering
   --  work.  It only projects already-indexed diagnostics into stable
   --  next/previous/first/last navigation targets.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   subtype Index_Entry is
     Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;

   type Diagnostic_Navigation_Target_Id is new Natural;
   No_Diagnostic_Navigation_Target : constant Diagnostic_Navigation_Target_Id := 0;

   type Diagnostic_Navigation_Status is
     (Diagnostic_Navigation_Current,
      Diagnostic_Navigation_Rejected_Stale);

   type Diagnostic_Navigation_Target is record
      Id          : Diagnostic_Navigation_Target_Id := No_Diagnostic_Navigation_Target;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index  : Natural := 0;
      Diagnostic  : Feed_Entry;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Token       : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Diagnostic_Navigation_Model is private;

   procedure Clear (Model : in out Diagnostic_Navigation_Model);

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model)
      return Diagnostic_Navigation_Model;

   function Status (Model : Diagnostic_Navigation_Model) return Diagnostic_Navigation_Status;
   function Current (Model : Diagnostic_Navigation_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Navigation_Model) return Boolean;

   function Navigation_Target_Count (Model : Diagnostic_Navigation_Model) return Natural;
   function Target_At
     (Model : Diagnostic_Navigation_Model;
      Index : Positive) return Diagnostic_Navigation_Target;

   function Error_Target_Count (Model : Diagnostic_Navigation_Model) return Natural;
   function Warning_Target_Count (Model : Diagnostic_Navigation_Model) return Natural;
   function Info_Target_Count (Model : Diagnostic_Navigation_Model) return Natural;
   function Rejected_Target_Count (Model : Diagnostic_Navigation_Model) return Natural;
   function Fingerprint (Model : Diagnostic_Navigation_Model) return Natural;

   function First_Diagnostic
     (Model : Diagnostic_Navigation_Model) return Diagnostic_Navigation_Target;
   function Last_Diagnostic
     (Model : Diagnostic_Navigation_Model) return Diagnostic_Navigation_Target;

   function First_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target;
   function Last_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target;

   function Next_Diagnostic
     (Model  : Diagnostic_Navigation_Model;
      Line   : Positive;
      Column : Positive) return Diagnostic_Navigation_Target;

   function Previous_Diagnostic
     (Model  : Diagnostic_Navigation_Model;
      Line   : Positive;
      Column : Positive) return Diagnostic_Navigation_Target;

   function Next_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Line     : Positive;
      Column   : Positive;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target;

   function Previous_Diagnostic
     (Model    : Diagnostic_Navigation_Model;
      Line     : Positive;
      Column   : Positive;
      Severity : Feed_Severity) return Diagnostic_Navigation_Target;

   function Has_Target (Target : Diagnostic_Navigation_Target) return Boolean;

private
   package Target_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Navigation_Target);

   type Diagnostic_Navigation_Model is record
      Navigation_Status  : Diagnostic_Navigation_Status := Diagnostic_Navigation_Current;
      Targets            : Target_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Rejected_Total     : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Navigation;
