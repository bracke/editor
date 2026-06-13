with Ada.Finalization;
with Ada.Strings.Unbounded;
with Editor.Unicode;

package Text_Backend.Rope_Impl is

   type Buffer_Type is new Ada.Finalization.Controlled with private;

   overriding procedure Adjust   (B : in out Buffer_Type);
   overriding procedure Finalize (B : in out Buffer_Type);

   --  Indexing conventions preserved from the original Text_Buffer API:
   --
   --  * Cursor/edit positions are zero-based insertion points in 0 .. Length.
   --  * Insert uses a zero-based cursor position. Values past Length append.
   --  * Delete uses a zero-based character position. Values past the final
   --    character delete the final character, matching the historical backend.
   --  * Element uses one-based character indexing in 1 .. Length and returns
   --    Character'Val (0) outside that range.
   --  * For_Each_Char_Range visits the half-open zero-based range
   --    [Start, Stop), clamped by the available text. It descends through the
   --    rope and does not perform a full-buffer traversal for subranges.

   procedure Clear (B : in out Buffer_Type);

   procedure Set_Text
     (B    : in out Buffer_Type;
      Text : String);

   procedure Insert
     (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character);

   --  Phase 24 Unicode API. Public Index values are scalar/code-point
   --  indexes; storage remains UTF-8 internally.
   procedure Insert
     (B     : in out Buffer_Type;
      Index : Natural;
      Code  : Editor.Unicode.Code_Point);

   procedure Insert_Range
     (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character;
      Count : Natural);

   procedure Delete
     (B     : in out Buffer_Type;
      Index : Natural);

   procedure Delete_Range
     (B     : in out Buffer_Type;
      Start : Natural;
      Span  : Natural);

   procedure Replace_Range
     (B     : in out Buffer_Type;
      Start : Natural;
      Span  : Natural;
      Ch    : Character);

   procedure Replace_Range
     (B           : in out Buffer_Type;
      First       : Natural;
      Last        : Natural;
      Replacement : String);

   function Length (B : Buffer_Type) return Natural;
   function UTF8_Code_Point_Count (Text : String) return Natural;

   --  Scalable logical line helpers. Rows are zero-based. Cursor indexes are
   --  zero-based insertion points in 0 .. Length. Line_End_Index returns an
   --  exclusive end index excluding ASCII.LF.
   function Line_Count (B : Buffer_Type) return Natural;

   function Row_For_Index
     (B     : Buffer_Type;
      Index : Natural) return Natural;

   function Line_Start_Index
     (B   : Buffer_Type;
      Row : Natural) return Natural;

   function Line_End_Index
     (B   : Buffer_Type;
      Row : Natural) return Natural;

   procedure Row_Col_For_Index
     (B     : Buffer_Type;
      Index : Natural;
      Row   : out Natural;
      Col   : out Natural);

   function Validate_Line_Counts (B : Buffer_Type) return Boolean;

   procedure For_Each_Char
     (B  : Buffer_Type;
      Fn : not null access procedure (Ch : Character));

   procedure For_Each_Char_Range
     (B     : Buffer_Type;
      Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure (Ch : Character));

   function Character_At
     (B     : Buffer_Type;
      Index : Natural) return Character;

   function Code_Point_At
     (B     : Buffer_Type;
      Index : Natural) return Editor.Unicode.Code_Point;

   procedure For_Each_Code_Point_Range
     (B     : Buffer_Type;
      First : Natural;
      Last  : Natural;
      Visit : not null access procedure
        (Index : Natural;
         Code  : Editor.Unicode.Code_Point));

   function UTF8_Text (B : Buffer_Type) return String;

   function Element
     (B     : Buffer_Type;
      Index : Natural) return Character;

   --  Debug/invariant helpers for storage tests only. Editor logic must not
   --  depend on tree shape.
   function Tree_Height (B : Buffer_Type) return Natural;
   function Leaf_Count  (B : Buffer_Type) return Natural;
   function Validate    (B : Buffer_Type) return Boolean;

private

   use Ada.Strings.Unbounded;

   Min_Leaf_Size : constant Natural := 512;
   Max_Leaf_Size : constant Natural := 4_096;

   --  Conservative height cap. If adversarial edits create a tall tree, the
   --  buffer is rebuilt from its leaves into a balanced tree.
   Max_Allowed_Height : constant Natural := 64;

   type Node_Kind is (Leaf_Node, Branch_Node);

   type Rope_Node;
   type Rope_Node_Access is access Rope_Node;

   type Rope_Node (Kind : Node_Kind := Leaf_Node) is record
      Length      : Natural := 0;
      Line_Breaks : Natural := 0;

      case Kind is
         when Leaf_Node =>
            Text : Unbounded_String;

         when Branch_Node =>
            Left   : Rope_Node_Access := null;
            Right  : Rope_Node_Access := null;
            Weight : Natural := 0;
      end case;
   end record;

   type Buffer_Type is new Ada.Finalization.Controlled with record
      Root        : Rope_Node_Access := null;
      Last        : Natural := 0;
      Line_Breaks : Natural := 0;
   end record;

end Text_Backend.Rope_Impl;
