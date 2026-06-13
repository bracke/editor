with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Status_Line is

   --  Deterministic IDE-facing status-line summary over the snapshot-guarded
   --  Ada semantic diagnostic index.  This package performs no parsing, file
   --  IO, buffer mutation, command registration, workspace mutation, or
   --  rendering work.  It only summarizes already-indexed diagnostics for a
   --  compact status-line consumer.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   subtype Index_Entry is
     Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;

   type Diagnostic_Status_Line_Status is
     (Diagnostic_Status_Line_Current,
      Diagnostic_Status_Line_Rejected_Stale);

   type Diagnostic_Status_Line_Kind is
     (Diagnostic_Status_Line_Clean,
      Diagnostic_Status_Line_Info,
      Diagnostic_Status_Line_Warning,
      Diagnostic_Status_Line_Error,
      Diagnostic_Status_Line_Stale);

   type Diagnostic_Status_Line_Target is record
      Has_Target   : Boolean := False;
      Index_Id     : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index   : Natural := 0;
      Diagnostic   : Feed_Entry;
      Source       : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Severity     : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Token        : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Diagnostic_Status_Line_Model is private;

   procedure Clear (Model : in out Diagnostic_Status_Line_Model);

   function Build
     (Index  : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Line   : Positive := 1;
      Column : Positive := 1) return Diagnostic_Status_Line_Model;

   function Status
     (Model : Diagnostic_Status_Line_Model) return Diagnostic_Status_Line_Status;
   function Current (Model : Diagnostic_Status_Line_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Status_Line_Model) return Boolean;

   function Summary_Kind
     (Model : Diagnostic_Status_Line_Model) return Diagnostic_Status_Line_Kind;
   function Summary_Text (Model : Diagnostic_Status_Line_Model) return String;

   function Diagnostic_Count (Model : Diagnostic_Status_Line_Model) return Natural;
   function Error_Count (Model : Diagnostic_Status_Line_Model) return Natural;
   function Warning_Count (Model : Diagnostic_Status_Line_Model) return Natural;
   function Info_Count (Model : Diagnostic_Status_Line_Model) return Natural;
   function Rejected_Diagnostic_Count
     (Model : Diagnostic_Status_Line_Model) return Natural;

   function Current_Line_Count
     (Model : Diagnostic_Status_Line_Model) return Natural;
   function Current_Position_Count
     (Model : Diagnostic_Status_Line_Model) return Natural;

   function Count_Source
     (Model  : Diagnostic_Status_Line_Model;
      Source : Feed_Source) return Natural;

   function Has_Diagnostics (Model : Diagnostic_Status_Line_Model) return Boolean;
   function Has_Errors (Model : Diagnostic_Status_Line_Model) return Boolean;
   function Has_Warnings (Model : Diagnostic_Status_Line_Model) return Boolean;
   function Has_Infos (Model : Diagnostic_Status_Line_Model) return Boolean;

   function Nearest_Diagnostic
     (Model : Diagnostic_Status_Line_Model) return Diagnostic_Status_Line_Target;
   function Has_Target (Target : Diagnostic_Status_Line_Target) return Boolean;

   function Fingerprint (Model : Diagnostic_Status_Line_Model) return Natural;

private
   type Diagnostic_Status_Line_Model is record
      Line_Status          : Diagnostic_Status_Line_Status := Diagnostic_Status_Line_Current;
      Kind                 : Diagnostic_Status_Line_Kind := Diagnostic_Status_Line_Clean;
      Summary              : Ada.Strings.Unbounded.Unbounded_String;
      Total                : Natural := 0;
      Error_Total          : Natural := 0;
      Warning_Total        : Natural := 0;
      Info_Total           : Natural := 0;
      Rejected_Total       : Natural := 0;
      Current_Line_Total   : Natural := 0;
      Current_Point_Total  : Natural := 0;
      Expression_Total     : Natural := 0;
      Generic_Total        : Natural := 0;
      Cross_Unit_Total     : Natural := 0;
      Representation_Total : Natural := 0;
      Nearest              : Diagnostic_Status_Line_Target;
      Result_Fingerprint   : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Status_Line;
