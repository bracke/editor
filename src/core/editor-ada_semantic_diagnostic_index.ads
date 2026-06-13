with Ada.Containers.Vectors;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Semantic_Diagnostic_Index is

   --  Deterministic IDE-facing index over the unified Ada semantic diagnostic
   --  feed.  This package performs no parsing, file IO, buffer mutation,
   --  command registration, workspace mutation, or rendering work.  It only
   --  indexes already snapshot-guarded feed entries for bounded lookup by
   --  source span, severity, source family, token kind, and syntax node.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;

   type Semantic_Diagnostic_Index_Id is new Natural;
   No_Semantic_Diagnostic_Index_Entry : constant Semantic_Diagnostic_Index_Id := 0;

   type Semantic_Diagnostic_Index_Status is
     (Semantic_Diagnostic_Index_Current,
      Semantic_Diagnostic_Index_Rejected_Stale);

   type Semantic_Diagnostic_Index_Entry is record
      Id         : Semantic_Diagnostic_Index_Id := No_Semantic_Diagnostic_Index_Entry;
      Feed_Index : Natural := 0;
      Diagnostic : Feed_Entry;
      Fingerprint : Natural := 0;
   end record;

   type Semantic_Diagnostic_Query_Result is record
      Feed_Index : Natural := 0;
      Diagnostic : Feed_Entry;
   end record;

   type Semantic_Diagnostic_Query_Set is private;
   type Semantic_Diagnostic_Index_Model is private;

   procedure Clear (Model : in out Semantic_Diagnostic_Index_Model);

   function Build
     (Feed : Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model)
      return Semantic_Diagnostic_Index_Model;

   function Status (Model : Semantic_Diagnostic_Index_Model) return Semantic_Diagnostic_Index_Status;
   function Current (Model : Semantic_Diagnostic_Index_Model) return Boolean;
   function Rejected_Stale (Model : Semantic_Diagnostic_Index_Model) return Boolean;

   function Entry_Count (Model : Semantic_Diagnostic_Index_Model) return Natural;
   function Entry_At
     (Model : Semantic_Diagnostic_Index_Model;
      Index : Positive) return Semantic_Diagnostic_Index_Entry;

   function Error_Count (Model : Semantic_Diagnostic_Index_Model) return Natural;
   function Warning_Count (Model : Semantic_Diagnostic_Index_Model) return Natural;
   function Info_Count (Model : Semantic_Diagnostic_Index_Model) return Natural;
   function Rejected_Entry_Count (Model : Semantic_Diagnostic_Index_Model) return Natural;
   function Fingerprint (Model : Semantic_Diagnostic_Index_Model) return Natural;

   function Query_Count (Results : Semantic_Diagnostic_Query_Set) return Natural;
   function Query_At
     (Results : Semantic_Diagnostic_Query_Set;
      Index   : Positive) return Semantic_Diagnostic_Query_Result;

   function Query_Range
     (Model      : Semantic_Diagnostic_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return Semantic_Diagnostic_Query_Set;

   function Query_Position
     (Model  : Semantic_Diagnostic_Index_Model;
      Line   : Positive;
      Column : Positive) return Semantic_Diagnostic_Query_Set;

   function Query_Severity
     (Model    : Semantic_Diagnostic_Index_Model;
      Severity : Feed_Severity) return Semantic_Diagnostic_Query_Set;

   function Query_Source
     (Model  : Semantic_Diagnostic_Index_Model;
      Source : Feed_Source) return Semantic_Diagnostic_Query_Set;

   function Query_Token
     (Model : Semantic_Diagnostic_Index_Model;
      Token : Editor.Syntax.Token_Kind) return Semantic_Diagnostic_Query_Set;

   function Query_Node
     (Model : Semantic_Diagnostic_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Semantic_Diagnostic_Query_Set;

   function Has_Diagnostic_At
     (Model  : Semantic_Diagnostic_Index_Model;
      Line   : Positive;
      Column : Positive) return Boolean;

private
   package Index_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Diagnostic_Index_Entry);

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Diagnostic_Query_Result);

   type Semantic_Diagnostic_Query_Set is record
      Results     : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Semantic_Diagnostic_Index_Model is record
      Index_Status       : Semantic_Diagnostic_Index_Status := Semantic_Diagnostic_Index_Current;
      Entries            : Index_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Rejected_Total     : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Semantic_Diagnostic_Index;
