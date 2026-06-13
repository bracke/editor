with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Panel_Projection is

   --  Deterministic IDE-facing diagnostics panel projection over the
   --  snapshot-guarded Ada semantic diagnostic index.  This package performs
   --  no parsing, file IO, buffer mutation, command registration, workspace
   --  mutation, or rendering work.  It only converts already-indexed
   --  diagnostics into stable panel rows with grouping and selection metadata.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   subtype Index_Entry is
     Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;

   type Diagnostic_Panel_Row_Id is new Natural;
   No_Diagnostic_Panel_Row : constant Diagnostic_Panel_Row_Id := 0;

   type Diagnostic_Panel_Status is
     (Diagnostic_Panel_Current,
      Diagnostic_Panel_Rejected_Stale);

   type Diagnostic_Panel_Group_Kind is
     (Diagnostic_Panel_Group_Error,
      Diagnostic_Panel_Group_Warning,
      Diagnostic_Panel_Group_Info,
      Diagnostic_Panel_Group_Source_Family,
      Diagnostic_Panel_Group_File,
      Diagnostic_Panel_Group_Unit);

   type Diagnostic_Panel_Row is record
      Id          : Diagnostic_Panel_Row_Id := No_Diagnostic_Panel_Row;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index  : Natural := 0;
      Diagnostic  : Feed_Entry;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Token       : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      File_Label  : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Group_Kind  : Diagnostic_Panel_Group_Kind := Diagnostic_Panel_Group_Info;
      Group_Key   : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Diagnostic_Panel_Model is private;

   procedure Clear (Model : in out Diagnostic_Panel_Model);

   function Build
     (Index      : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      File_Label : String := "";
      Unit_Name  : String := "") return Diagnostic_Panel_Model;

   function Status (Model : Diagnostic_Panel_Model) return Diagnostic_Panel_Status;
   function Current (Model : Diagnostic_Panel_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Panel_Model) return Boolean;

   function Row_Count (Model : Diagnostic_Panel_Model) return Natural;
   function Row_At
     (Model : Diagnostic_Panel_Model;
      Index : Positive) return Diagnostic_Panel_Row;

   function Error_Row_Count (Model : Diagnostic_Panel_Model) return Natural;
   function Warning_Row_Count (Model : Diagnostic_Panel_Model) return Natural;
   function Info_Row_Count (Model : Diagnostic_Panel_Model) return Natural;
   function Rejected_Row_Count (Model : Diagnostic_Panel_Model) return Natural;

   function Count_Source
     (Model  : Diagnostic_Panel_Model;
      Source : Feed_Source) return Natural;

   function Source_Group_Count (Model : Diagnostic_Panel_Model) return Natural;
   function File_Group_Count (Model : Diagnostic_Panel_Model) return Natural;
   function Unit_Group_Count (Model : Diagnostic_Panel_Model) return Natural;

   function Selected_Row (Model : Diagnostic_Panel_Model) return Diagnostic_Panel_Row;
   function Select_Row
     (Model : Diagnostic_Panel_Model;
      Row   : Diagnostic_Panel_Row_Id) return Diagnostic_Panel_Model;

   function Select_Nearest
     (Model  : Diagnostic_Panel_Model;
      Line   : Positive;
      Column : Positive) return Diagnostic_Panel_Model;

   function First_Row_For_Severity
     (Model    : Diagnostic_Panel_Model;
      Severity : Feed_Severity) return Diagnostic_Panel_Row;

   function Has_Row (Row : Diagnostic_Panel_Row) return Boolean;
   function Fingerprint (Model : Diagnostic_Panel_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Panel_Row);

   type Diagnostic_Panel_Model is record
      Panel_Status       : Diagnostic_Panel_Status := Diagnostic_Panel_Current;
      Rows               : Row_Vectors.Vector;
      Selected           : Diagnostic_Panel_Row_Id := No_Diagnostic_Panel_Row;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Rejected_Total     : Natural := 0;
      Expression_Total   : Natural := 0;
      Generic_Total      : Natural := 0;
      Cross_Unit_Total   : Natural := 0;
      Representation_Total : Natural := 0;
      Source_Group_Total : Natural := 0;
      File_Group_Total   : Natural := 0;
      Unit_Group_Total   : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Panel_Projection;
