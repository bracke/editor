with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Ada_Syntax_Tree.Detail_Nodes;
with Editor.Ada_Syntax_Tree.Line_Classifier;
with Editor.Ada_Syntax_Tree.Statement_Details;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;

package body Editor.Ada_Syntax_Tree is

   pragma Suppress (Overflow_Check);

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Trim (S : String) return String
     renames Editor.Text_Helpers.Trim;

   function Is_Word_Char (C : Character) return Boolean
     renames Editor.Text_Helpers.Is_Word_Char;

   function Starts_With (Text, Prefix : String) return Boolean
     renames Editor.Text_Helpers.Starts_With;

   function Starts_With_Word (Text, Word : String) return Boolean
     renames Editor.Text_Helpers.Starts_With_Word;

   function Contains (Text, Fragment : String) return Boolean
     renames Editor.Text_Helpers.Contains;

   procedure Clear (Tree : in out Tree_Type) is
   begin
      Builder.Clear (Tree);
   end Clear;

   function Add_Node
     (Tree   : in out Tree_Type;
      Kind   : Node_Kind;
      Source_Span  : Source_Range;
      Parent : Node_Id := No_Node;
      Depth  : Natural := 0;
      Label  : String := "") return Node_Id
   is
   begin
      return Builder.Add_Node (Tree, Kind, Source_Span, Parent, Depth, Label);
   end Add_Node;

   function Classify_Line (Line : String) return Node_Kind is
   begin
      return Line_Classifier.Classify_Line (Line);
   end Classify_Line;

   function Opens_Scope (Kind : Node_Kind; Code : String) return Boolean is
   begin
      return Line_Classifier.Opens_Scope (Kind, Code);
   end Opens_Scope;

   function Is_End_Node (Kind : Node_Kind) return Boolean is
   begin
      return Line_Classifier.Is_End_Node (Kind);
   end Is_End_Node;

   function Is_Alternative_Node (Kind : Node_Kind) return Boolean is
   begin
      return Line_Classifier.Is_Alternative_Node (Kind);
   end Is_Alternative_Node;

   function Expected_End_Label (Kind : Node_Kind) return String is
   begin
      return Line_Classifier.Expected_End_Label (Kind);
   end Expected_End_Label;


   function Strip_Terminator (Text : String) return String;
   function Segment_Before (Text, Marker : String) return String;
   function Segment_After (Text, Marker : String) return String;

   procedure Add_Declaration_Detail_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String;
      Kind   : Node_Kind);

   function End_Target_Text (Code : String) return String is separate;


   function Opening_Target_Text (Kind : Node_Kind; Label : String) return String is separate;


   function Same_Ada_Name (Left : String; Right : String) return Boolean is separate;


   function End_Matches_Kind (Opener : Node_Kind; End_Code : String) return Boolean is separate;


   function Alternative_Has_Grammar_Owner
     (Alternative : Node_Kind;
      Owner       : Node_Kind) return Boolean
   is separate;



   function Is_Transient_Statement_Part (Kind : Node_Kind) return Boolean is separate;


   function End_Implicitly_Closes_Statement_Part
     (Transient : Node_Kind;
      Owner     : Node_Kind;
      End_Code  : String) return Boolean
   is separate;



   function Strip_Terminator (Text : String) return String is separate;


   function Segment_Before (Text, Marker : String) return String is separate;


   function Segment_After (Text, Marker : String) return String is separate;


   function If_Condition_Text (Code, Prefix : String) return String is separate;


   function If_Action_Text (Code : String) return String is separate;


   function Is_Character_Literal_At
     (Text : String; Pos : Natural; Last : Natural) return Boolean
   is separate;




   function Code_Preserving_Literals_For_Retention (Line : String) return String is separate;


   function Segment_Between_First_Parens (Text : String) return String is separate;


   function Segment_Between_First_Parens_After
     (Text   : String;
      Marker : String) return String
   is separate;


   function Strip_Leading_With (Text : String) return String is separate;


   function Top_Level_Arrow_Position (Text : String) return Natural is separate;


   function Has_Top_Level_Arrow (Text : String) return Boolean is separate;


   function Split_Before_Top_Level_Arrow (Text : String) return String is separate;


   function Split_After_Top_Level_Arrow (Text : String) return String is separate;


   procedure Add_Name_Tokens
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;


   procedure Add_Expression_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;



   function Last_Column_For (Text : String) return Positive is separate;


   procedure Add_Detail_Node
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Label  : String)
   is separate;


   procedure Add_Association_List_Nodes
     (Tree             : in out Tree_Type;
      Parent           : Node_Id;
      Depth            : Natural;
      Line             : Positive;
      Text             : String;
      Association_Kind : Node_Kind)
   is separate;


   function Declaration_Name_Text (Code : String; Lead_Word : String := "") return String is separate;


   function Subprogram_Name_Text (Code : String) return String is separate;


   function Subprogram_Profile_Text (Code : String) return String is separate;


   function Subprogram_Result_Text (Code : String) return String is separate;


   procedure Add_Declaration_Detail_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String;
      Kind   : Node_Kind)
   is separate;


   procedure Add_Discriminant_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String)
   is separate;




   procedure Add_Enumeration_Literal_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Code   : String)
   is separate;


   procedure Add_Aspect_Specification_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;


   procedure Add_Generic_Actual_Part_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;


   procedure Add_Representation_Clause_Detail_Nodes
     (Tree   : in out Tree_Type;
      Clause : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;


   procedure Add_Representation_Component_Clause_Detail_Nodes
     (Tree   : in out Tree_Type;
      Clause : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;


   procedure Add_Representation_Clause_Nodes
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Text   : String)
   is separate;


   function First_Semicolon (Text : String) return Natural is separate;


   function Statement_Node_Kind (Text : String) return Node_Kind is separate;


   procedure Attach_Statement_Details
     (Tree           : in out Tree_Type;
      Stmt           : Node_Id;
      Kind           : Node_Kind;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is separate;


   procedure Attach_Syntax_Details
     (Tree   : in out Tree_Type;
      Id     : Node_Id;
      Kind   : Node_Kind;
      Code   : String;
      Line   : Positive;
      Depth  : Natural);

   procedure Add_Structured_Statement_Node
     (Tree           : in out Tree_Type;
      Parent         : Node_Id;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is separate;


   procedure Add_Action_Sequence
     (Tree           : in out Tree_Type;
      Parent         : Node_Id;
      Depth          : Natural;
      Line           : Positive;
      Text           : String;
      Is_Alternative : Boolean := False)
   is separate;



   procedure Add_Header_Recovery_Details
     (Tree   : in out Tree_Type;
      Parent : Node_Id;
      Depth  : Natural;
      Line   : Positive;
      Kind   : Node_Kind;
      Code   : String)
   is separate;


   procedure Attach_Syntax_Details
     (Tree   : in out Tree_Type;
      Id     : Node_Id;
      Kind   : Node_Kind;
      Code   : String;
      Line   : Positive;
      Depth  : Natural)
   is separate;


   function Parse (Text : String) return Tree_Type is separate;

   function Has_Nodes (Tree : Tree_Type) return Boolean is
   begin
      return not Tree.Nodes.Is_Empty;
   end Has_Nodes;

   function Node_Count (Tree : Tree_Type) return Natural is
   begin
      return Natural (Tree.Nodes.Length);
   end Node_Count;

   function Root (Tree : Tree_Type) return Node_Id is
   begin
      return Tree.Root_Node;
   end Root;

   function Node (Tree : Tree_Type; Id : Node_Id) return Node_Info is
   begin
      if Id = No_Node or else Natural (Id) > Natural (Tree.Nodes.Length) then
         return (Id => No_Node, Kind => Node_Unknown, Source_Span => (1, 1, 1, 1),
                 Parent => No_Node, Depth => 0, Label => Null_Unbounded_String,
                 Fingerprint => 0);
      end if;
      return Tree.Nodes (Positive (Id));
   end Node;

   function Node_At (Tree : Tree_Type; Index : Positive) return Node_Info is
   begin
      if Index > Natural (Tree.Nodes.Length) then
         return (Id => No_Node, Kind => Node_Unknown, Source_Span => (1, 1, 1, 1),
                 Parent => No_Node, Depth => 0, Label => Null_Unbounded_String,
                 Fingerprint => 0);
      end if;
      return Tree.Nodes (Index);
   end Node_At;

   function Child_Count (Tree : Tree_Type; Parent : Node_Id) return Natural is
      Count : Natural := 0;
   begin
      for Info of Tree.Nodes loop
         if Info.Parent = Parent then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Child_Count;

   function Child_At
     (Tree   : Tree_Type;
      Parent : Node_Id;
      Index  : Positive) return Node_Id
   is
      Count : Natural := 0;
   begin
      for Info of Tree.Nodes loop
         if Info.Parent = Parent then
            Count := Count + 1;
            if Count = Index then
               return Info.Id;
            end if;
         end if;
      end loop;
      return No_Node;
   end Child_At;

   function Fingerprint (Tree : Tree_Type) return Natural is
   begin
      return Tree.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Syntax_Tree;
