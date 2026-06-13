with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Syntax_Tree;
with Editor.Syntax;

package Editor.Ada_Diagnostic_Suppression_Baseline is

   --  Projection-only suppression and baseline metadata model over the
   --  snapshot-guarded Ada semantic diagnostic index.  This package records
   --  suppression intent and baseline matches without mutating source buffers,
   --  hiding stale-state failures, parsing, file IO, command registration,
   --  workspace mutation, edit application, or rendering work.

   subtype Feed_Entry is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Entry;
   subtype Feed_Severity is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Severity;
   subtype Feed_Source is
     Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   subtype Index_Entry is
     Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Entry;

   type Diagnostic_Suppression_Rule_Id is new Natural;
   No_Diagnostic_Suppression_Rule : constant Diagnostic_Suppression_Rule_Id := 0;

   type Diagnostic_Suppression_Entry_Id is new Natural;
   No_Diagnostic_Suppression_Entry : constant Diagnostic_Suppression_Entry_Id := 0;

   type Diagnostic_Suppression_Model_Status is
     (Diagnostic_Suppression_Current,
      Diagnostic_Suppression_Rejected_Stale);

   type Diagnostic_Suppression_Rule_Kind is
     (Diagnostic_Suppression_No_Rule,
      Diagnostic_Suppression_By_Index_Id,
      Diagnostic_Suppression_By_Source,
      Diagnostic_Suppression_By_Severity,
      Diagnostic_Baseline_By_Diagnostic_Fingerprint,
      Diagnostic_Baseline_By_Source_And_Severity);

   type Diagnostic_Suppression_Entry_Status is
     (Diagnostic_Suppression_Entry_Active,
      Diagnostic_Suppression_Entry_Suppressed,
      Diagnostic_Suppression_Entry_Baselined,
      Diagnostic_Suppression_Entry_Rejected_Stale);

   type Diagnostic_Suppression_Rule is record
      Id          : Diagnostic_Suppression_Rule_Id := No_Diagnostic_Suppression_Rule;
      Kind        : Diagnostic_Suppression_Rule_Kind := Diagnostic_Suppression_No_Rule;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Diagnostic_Fingerprint : Natural := 0;
      Reason      : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Suppression_Entry is record
      Id          : Diagnostic_Suppression_Entry_Id := No_Diagnostic_Suppression_Entry;
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Feed_Index  : Natural := 0;
      Diagnostic  : Feed_Entry;
      Status      : Diagnostic_Suppression_Entry_Status := Diagnostic_Suppression_Entry_Active;
      Applied_Rule : Diagnostic_Suppression_Rule_Id := No_Diagnostic_Suppression_Rule;
      Applied_Rule_Kind : Diagnostic_Suppression_Rule_Kind := Diagnostic_Suppression_No_Rule;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Token       : Editor.Syntax.Token_Kind := Editor.Syntax.Identifier;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Reason      : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Fingerprint  : Natural := 0;
   end record;

   type Diagnostic_Suppression_Rule_Set is private;
   type Diagnostic_Suppression_Result_Set is private;
   type Diagnostic_Suppression_Model is private;

   procedure Clear_Rules (Rules : in out Diagnostic_Suppression_Rule_Set);

   procedure Add_Rule
     (Rules : in out Diagnostic_Suppression_Rule_Set;
      Rule  : Diagnostic_Suppression_Rule);

   function Make_Rule
     (Kind        : Diagnostic_Suppression_Rule_Kind;
      Reason      : String := "";
      Index_Id    : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id :=
        Editor.Ada_Semantic_Diagnostic_Index.No_Semantic_Diagnostic_Index_Entry;
      Severity    : Feed_Severity :=
        Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info;
      Source      : Feed_Source :=
        Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression;
      Diagnostic_Fingerprint : Natural := 0) return Diagnostic_Suppression_Rule;

   function Rule_Count (Rules : Diagnostic_Suppression_Rule_Set) return Natural;
   function Rule_At
     (Rules : Diagnostic_Suppression_Rule_Set;
      Index : Positive) return Diagnostic_Suppression_Rule;
   function Rule_Set_Fingerprint (Rules : Diagnostic_Suppression_Rule_Set) return Natural;

   procedure Clear (Model : in out Diagnostic_Suppression_Model);

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Rules : Diagnostic_Suppression_Rule_Set) return Diagnostic_Suppression_Model;

   function Status (Model : Diagnostic_Suppression_Model) return Diagnostic_Suppression_Model_Status;
   function Current (Model : Diagnostic_Suppression_Model) return Boolean;
   function Rejected_Stale (Model : Diagnostic_Suppression_Model) return Boolean;

   function Entry_Count (Model : Diagnostic_Suppression_Model) return Natural;
   function Entry_At
     (Model : Diagnostic_Suppression_Model;
      Index : Positive) return Diagnostic_Suppression_Entry;

   function Active_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural;
   function Suppressed_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural;
   function Baselined_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural;
   function Rejected_Entry_Count (Model : Diagnostic_Suppression_Model) return Natural;

   function Count_Status
     (Model  : Diagnostic_Suppression_Model;
      Status : Diagnostic_Suppression_Entry_Status) return Natural;

   function Count_Source
     (Model  : Diagnostic_Suppression_Model;
      Source : Feed_Source) return Natural;

   function Count_Severity
     (Model    : Diagnostic_Suppression_Model;
      Severity : Feed_Severity) return Natural;

   function First_For_Diagnostic
     (Model    : Diagnostic_Suppression_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Suppression_Entry;

   function Entries_For_Status
     (Model  : Diagnostic_Suppression_Model;
      Status : Diagnostic_Suppression_Entry_Status) return Diagnostic_Suppression_Result_Set;

   function Result_Count (Results : Diagnostic_Suppression_Result_Set) return Natural;
   function Result_At
     (Results : Diagnostic_Suppression_Result_Set;
      Index   : Positive) return Diagnostic_Suppression_Entry;

   function Has_Entry (Feed_Item : Diagnostic_Suppression_Entry) return Boolean;
   function Fingerprint (Model : Diagnostic_Suppression_Model) return Natural;

private
   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Suppression_Rule);

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Diagnostic_Suppression_Entry);

   type Diagnostic_Suppression_Rule_Set is record
      Rules       : Rule_Vectors.Vector;
      Next_Id     : Diagnostic_Suppression_Rule_Id := 1;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Suppression_Result_Set is record
      Entries     : Entry_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Diagnostic_Suppression_Model is record
      Model_Status        : Diagnostic_Suppression_Model_Status := Diagnostic_Suppression_Current;
      Entries             : Entry_Vectors.Vector;
      Active_Total        : Natural := 0;
      Suppressed_Total    : Natural := 0;
      Baselined_Total     : Natural := 0;
      Rejected_Total      : Natural := 0;
      Error_Total         : Natural := 0;
      Warning_Total       : Natural := 0;
      Info_Total          : Natural := 0;
      Expression_Total    : Natural := 0;
      Generic_Total       : Natural := 0;
      Cross_Unit_Total    : Natural := 0;
      Representation_Total : Natural := 0;
      Rule_Fingerprint    : Natural := 0;
      Result_Fingerprint  : Natural := 0;
   end record;

end Editor.Ada_Diagnostic_Suppression_Baseline;
